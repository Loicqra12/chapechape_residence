const { Message, Conversation } = require('../models/message.model');
const asyncHandler = require('../middlewares/async.middleware');
const multer = require('multer');
const path = require('path');
const fs = require('fs').promises;
const Reservation = require('../models/reservation.model');
const notificationService = require('../services/notification.service');
const socketService = require('../services/socket.service');
const User = require('../models/user.model');
const { COMMON } = require('../utils/notification-types');
const { scheduleUnreadMessageReminder } = require('../services/agenda.service');
const { canAccessConversation, idOf } = require('../security/resource-access');
const { isStaff } = require('../security/roles');
const Residence = require('../models/residence.model');

// Création du dossier uploads/messages s'il n'existe pas
const ensureUploadDirExists = async () => {
    const dir = 'uploads/messages';
    try {
        await fs.access(dir);
    } catch (error) {
        // Si le dossier n'existe pas, le créer
        await fs.mkdir(dir, { recursive: true });
        console.log(`Dossier ${dir} créé avec succès`);
    }
};

// Appel de la fonction pour s'assurer que le dossier existe
ensureUploadDirExists();

// Fonction utilitaire pour déterminer le type de fichier à partir d'une URL
function _getFileTypeFromUrl(url) {
    // Extraire l'extension du fichier de l'URL
    const extension = url.split('?')[0].split('.').pop().toLowerCase();

    // Mapping des extensions vers les types de fichiers
    const typeMap = {
        'jpg': 'image',
        'jpeg': 'image',
        'png': 'image',
        'gif': 'image',
        'webp': 'image',
        'pdf': 'pdf',
        'doc': 'document',
        'docx': 'document',
        'mp4': 'video',
        'mov': 'video',
        'avi': 'video',
        'mp3': 'audio',
        'wav': 'audio',
        'ogg': 'audio'
    };

    // Si l'URL contient des paramètres spécifiques de Cloudinary, les analyser
    if (url.includes('cloudinary.com')) {
        if (url.includes('/image/')) return 'image';
        if (url.includes('/video/')) return 'video';
        if (url.includes('/raw/')) {
            // Pour les fichiers bruts, vérifier l'extension
            return typeMap[extension] || 'file';
        }
    }

    // Retourner le type basé sur l'extension ou 'file' par défaut
    return typeMap[extension] || 'file';
}

// Configuration de multer pour le stockage des fichiers
const storage = multer.diskStorage({
    destination: (req, file, cb) => {
        cb(null, 'uploads/messages');
    },
    filename: (req, file, cb) => {
        const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
        cb(null, uniqueSuffix + path.extname(file.originalname));
    }
});

const upload = multer({
    storage,
    limits: {
        fileSize: 5 * 1024 * 1024 // 5MB max
    },
    fileFilter: (req, file, cb) => {
        const allowedTypes = ['image/jpeg', 'image/png', 'image/gif', 'application/pdf'];
        if (allowedTypes.includes(file.mimetype)) {
            cb(null, true);
        } else {
            cb(new Error('Type de fichier non supporté'));
        }
    }
}).single('file');

// @desc    Get all conversations for a user
// @route   GET /api/messages/conversations
// @access  Private
exports.getConversations = asyncHandler(async (req, res) => {
    const conversations = await Conversation.find({
        participants: req.user.id
    })
        .populate('participants', 'name avatar')
        .populate('lastMessage')
        .populate('reservationId', 'status')
        .populate('residenceId', 'name')
        .sort('-updatedAt');

    // Ajouter le compte des messages non lus pour chaque conversation
    const conversationsWithUnread = await Promise.all(conversations.map(async (conv) => {
        const unreadCount = await Message.countDocuments({
            conversation: conv._id,
            read: false,
            sender: { $ne: req.user.id }
        });
        return {
            ...conv.toJSON(),
            unreadCount
        };
    }));

    res.json({ success: true, data: conversationsWithUnread });
});

// @desc    Get a specific conversation
// @route   GET /api/messages/conversations/:id
// @access  Private
exports.getConversation = asyncHandler(async (req, res) => {
    const conversation = await Conversation.findById(req.params.id)
        .populate('participants', 'name avatar')
        .populate('lastMessage')
        .populate('reservationId', 'status')
        .populate('residenceId', 'name');

    if (!conversation) {
        return res.status(404).json({ success: false, error: 'Conversation non trouvée' });
    }

    if (!canAccessConversation(conversation, req.user)) {
        return res.status(403).json({ success: false, error: 'Accès non autorisé à cette conversation' });
    }

    res.json({ success: true, data: conversation });
});

// @desc    Get messages for a conversation
// @route   GET /api/messages/conversations/:id/messages
// @access  Private
exports.getMessages = asyncHandler(async (req, res) => {
    const { page = 1, limit = 20 } = req.query;
    const skip = (page - 1) * limit;

    const conversation = await Conversation.findById(req.params.id);
    if (!conversation) {
        return res.status(404).json({ success: false, error: 'Conversation non trouvée' });
    }
    if (!canAccessConversation(conversation, req.user)) {
        return res.status(403).json({ success: false, error: 'Accès non autorisé à cette conversation' });
    }

    const messages = await Message.find({ conversation: req.params.id })
        .populate('sender', 'name avatar')
        .sort('-createdAt')
        .skip(skip)
        .limit(parseInt(limit));

    const total = await Message.countDocuments({ conversation: req.params.id });

    res.json({
        success: true,
        data: {
            messages,
            pagination: {
                page: parseInt(page),
                limit: parseInt(limit),
                total
            }
        }
    });
});

// @desc    Send a message in a conversation
// @route   POST /api/messages/conversations/:id/messages
// @access  Private
exports.sendMessage = asyncHandler(async (req, res) => {
    const { content, attachments, reservationId } = req.body;
    const conversationId = req.params.id;

    const conversation = await Conversation.findById(conversationId);
    if (!conversation) {
        return res.status(404).json({ success: false, error: 'Conversation non trouvée' });
    }

    if (!canAccessConversation(conversation, req.user)) {
        return res.status(403).json({ success: false, error: 'Non autorisé à envoyer des messages dans cette conversation' });
    }

    // Vérifier si la messagerie est activée pour cette réservation
    if (conversation.reservationId) {
        const reservation = await Reservation.findById(conversation.reservationId);

        // Compter les messages déjà envoyés par cet utilisateur dans cette conversation
        const userMessageCount = await Message.countDocuments({
            conversation: conversationId,
            sender: req.user.id
        });

        // Limite de messages gratuits
        const FREE_MESSAGE_LIMIT = 2;

        // Bloquer seulement si la messagerie n'est pas activée ET la limite est atteinte
        if (!reservation || (!reservation.messagingEnabled && userMessageCount >= FREE_MESSAGE_LIMIT)) {
            return res.status(403).json({
                success: false,
                error: userMessageCount >= FREE_MESSAGE_LIMIT
                    ? `Vous avez atteint la limite de ${FREE_MESSAGE_LIMIT} messages gratuits. Effectuez le paiement de votre réservation pour continuer à échanger.`
                    : 'La messagerie n\'est pas encore activée pour cette réservation. Le paiement doit être effectué pour débloquer cette fonctionnalité.'
            });
        }
    }

    const message = await Message.create({
        conversation: conversationId,
        sender: req.user.id,
        content,
        attachments: attachments || [],
        reservationId
    });

    conversation.lastMessage = message._id;
    conversation.updatedAt = Date.now();
    await conversation.save();

    await message.populate('sender', 'name avatar');

    // 1. Notifications WebSocket en temps réel
    try {
        await socketService.notifyNewMessage(message, conversation);
    } catch (socketError) {
        console.error('Erreur lors de la notification WebSocket:', socketError);
        // On continue même en cas d'erreur
    }

    // 2. Notifications push pour les participants qui ne sont pas l'expéditeur
    try {
        // Récupérer le sender pour avoir son nom
        const sender = await User.findById(req.user.id, 'name');
        const senderName = sender ? sender.name : 'Utilisateur';

        // Préparer le message et les données pour la notification
        const notificationMessage = `${senderName}: ${content.substring(0, 50)}${content.length > 50 ? '...' : ''}`;
        const notificationData = {
            type: 'NEW_MESSAGE',
            conversationId: conversationId,
            messageId: message._id.toString(),
            senderId: req.user.id
        };

        // Pour chaque participant (sauf l'expéditeur)
        for (const participantId of conversation.participants) {
            const participantIdStr = participantId.toString();
            if (participantIdStr !== req.user.id) {
                // Vérifier si l'utilisateur est en ligne avant d'envoyer une notification push
                const isOnline = await socketService.isUserOnline(participantIdStr);
                if (!isOnline) {
                    // Envoyer notification push via le service de notification
                    // COMMON.NEW_MESSAGE = 'new_message' — type valide défini dans notification-types.js
                    await notificationService.createNotification(
                        participantIdStr,
                        COMMON.NEW_MESSAGE,
                        notificationMessage,
                        notificationData
                    );
                }

                // Phase 2 : rappel si toujours non lu (Partner 20 min, Client 60 min)
                try {
                    const recipient = await User.findById(participantIdStr).select('role');
                    const isPartner =
                        recipient?.role === 'partner' || recipient?.role === 'partner_pending';
                    const delayMinutes = isPartner ? 20 : 60;
                    const deepLink = isPartner ? '/messages/support' : '/chat';
                    await scheduleUnreadMessageReminder(
                        message._id.toString(),
                        participantIdStr,
                        delayMinutes,
                        deepLink
                    );
                } catch (scheduleErr) {
                    console.error('Erreur programmation rappel message:', scheduleErr);
                }
            }
        }
    } catch (notifError) {
        console.error('Erreur lors de l\'envoi des notifications push:', notifError);
        // On continue même en cas d'erreur
    }

    res.status(201).json({ success: true, data: message });
});

// @desc    Upload an attachment
// @route   POST /api/messages/conversations/:id/attachments
// @access  Private
exports.uploadAttachment = asyncHandler(async (req, res) => {
    const conversationId = req.params.id;

    const conversation = await Conversation.findById(conversationId);
    if (!conversation) {
        return res.status(404).json({
            success: false,
            error: 'Conversation non trouvée'
        });
    }

    if (!canAccessConversation(conversation, req.user)) {
        return res.status(403).json({
            success: false,
            error: 'Vous n\'êtes pas autorisé à envoyer des fichiers dans cette conversation'
        });
    }

    // Vérifier si la messagerie est activée pour cette réservation
    if (conversation.reservationId) {
        const reservation = await Reservation.findById(conversation.reservationId);

        // Compter les messages déjà envoyés par cet utilisateur dans cette conversation
        const userMessageCount = await Message.countDocuments({
            conversation: conversationId,
            sender: req.user.id
        });

        // Limite de messages gratuits
        const FREE_MESSAGE_LIMIT = 2;

        // Bloquer seulement si la messagerie n'est pas activée ET la limite est atteinte
        if (!reservation || (!reservation.messagingEnabled && userMessageCount >= FREE_MESSAGE_LIMIT)) {
            return res.status(403).json({
                success: false,
                error: userMessageCount >= FREE_MESSAGE_LIMIT
                    ? `Vous avez atteint la limite de ${FREE_MESSAGE_LIMIT} messages gratuits. Effectuez le paiement de votre réservation pour continuer à échanger.`
                    : 'La messagerie n\'est pas encore activée pour cette réservation. Le paiement doit être effectué pour débloquer cette fonctionnalité.'
            });
        }
    }

    // Vérifier d'abord si un lien Cloudinary a été fourni directement via JSON
    if (req.headers['content-type'] && req.headers['content-type'].includes('application/json')) {
        try {
            const { fileUrl, fileName, fileType, fileSize } = req.body;

            if (fileUrl && typeof fileUrl === 'string' &&
                (fileUrl.startsWith('http://') || fileUrl.startsWith('https://'))) {

                console.log('URL Cloudinary détectée:', fileUrl);

                // Créer un attachement à partir de l'URL
                const attachment = {
                    url: fileUrl,
                    type: fileType || _getFileTypeFromUrl(fileUrl) || 'file',
                    name: fileName || 'Pièce jointe',
                    size: fileSize || 0,
                    source: 'cloudinary'
                };

                // Créer le message avec l'attachement
                const message = await Message.create({
                    conversation: conversationId,
                    sender: req.user.id,
                    content: `A envoyé un ${attachment.type}`,
                    attachments: [attachment]
                });

                conversation.lastMessage = message._id;
                conversation.updatedAt = Date.now();
                await conversation.save();

                await message.populate('sender', 'name avatar');

                return res.status(201).json({ success: true, data: { message, attachments: [attachment] } });
            }
        } catch (error) {
            console.error('Erreur lors du traitement de l\'URL Cloudinary:', error);
            return res.status(400).json({
                success: false,
                error: 'Format JSON invalide ou URL manquante',
                details: error.message
            });
        }
    }

    // Si pas d'URL Cloudinary, continuer avec l'upload traditionnel
    console.log('Headers:', req.headers);
    console.log('Content-Type:', req.headers['content-type']);

    // Utilisons une version plus simple de multer
    const uploadSingle = multer({
        storage,
        limits: { fileSize: 5 * 1024 * 1024 },
        fileFilter: (req, file, cb) => {
            console.log('File received:', file.originalname, file.mimetype);
            const allowedTypes = ['image/jpeg', 'image/png', 'image/gif', 'application/pdf'];
            if (allowedTypes.includes(file.mimetype)) {
                cb(null, true);
            } else {
                cb(new Error(`Type de fichier non supporté: ${file.mimetype}`));
            }
        }
    }).single('image'); // Changé de 'file' à 'image' pour correspondre à votre formulaire

    uploadSingle(req, res, async (err) => {
        if (err) {
            console.error('Upload error:', err);
            return res.status(400).json({
                success: false,
                error: err.message,
                details: 'Assurez-vous que le champ est nommé "image" et que le Content-Type est multipart/form-data'
            });
        }

        if (!req.file) {
            return res.status(400).json({
                success: false,
                error: 'Aucun fichier fourni',
                details: 'Assurez-vous que le champ est nommé "image" et que vous avez sélectionné un fichier'
            });
        }

        console.log('File uploaded successfully:', req.file);

        const attachment = {
            url: `/uploads/messages/${req.file.filename}`,
            type: req.file.mimetype.startsWith('image/') ? 'image' : 'document',
            name: req.body.name || req.file.originalname,
            size: req.file.size
        };

        const message = await Message.create({
            conversation: conversationId,
            sender: req.user.id,
            content: `A envoyé un ${attachment.type}`,
            attachments: [attachment]
        });

        conversation.lastMessage = message._id;
        conversation.updatedAt = Date.now();
        await conversation.save();

        await message.populate('sender', 'name avatar');

        res.status(201).json({ success: true, data: message });
    });
});

// @desc    Create a new conversation
// @route   POST /api/messages/conversations
// @access  Private
exports.createConversation = asyncHandler(async (req, res) => {
    const { title, participants, reservationId, residenceId, initialMessage } = req.body;

    let allParticipants = [req.user.id];

    if (reservationId) {
        const reservation = await Reservation.findById(reservationId).select('user partner residence');
        if (!reservation) {
            return res.status(404).json({
                success: false,
                error: 'Réservation non trouvée'
            });
        }
        const { canAccessReservation } = require('../security/resource-access');
        if (!canAccessReservation(reservation, req.user)) {
            return res.status(403).json({
                success: false,
                error: 'Non autorisé à ouvrir une conversation sur cette réservation'
            });
        }
        allParticipants = [idOf(reservation.user), idOf(reservation.partner)].filter(Boolean);
    } else if (residenceId) {
        const residence = await Residence.findById(residenceId).select('partner');
        if (!residence) {
            return res.status(404).json({ success: false, error: 'Résidence non trouvée' });
        }
        const partnerId = idOf(residence.partner);
        if (idOf(req.user) === partnerId || isStaff(req.user.role)) {
            const extra = Array.isArray(participants) ? participants.map(idOf) : [];
            allParticipants = [...new Set([req.user.id, partnerId, ...extra])];
            if (!isStaff(req.user.role)) {
                allParticipants = [req.user.id];
            }
        } else {
            allParticipants = [req.user.id, partnerId];
        }
    } else {
        allParticipants = [req.user.id];
    }

    const conversation = await Conversation.create({
        title,
        participants: allParticipants,
        reservationId,
        residenceId,
        createdAt: Date.now(),
        updatedAt: Date.now()
    });

    // Si un message initial est fourni, le créer
    if (initialMessage) {
        const message = await Message.create({
            conversation: conversation._id,
            sender: req.user.id,
            content: initialMessage
        });

        // Mettre à jour la conversation avec le dernier message
        conversation.lastMessage = message._id;
        await conversation.save();
    }

    await conversation.populate('participants', 'name avatar');
    if (reservationId) {
        await conversation.populate('reservationId', 'status');
    }
    if (residenceId) {
        await conversation.populate('residenceId', 'name');
    }

    res.status(201).json({
        success: true,
        data: conversation
    });
});

// @desc    Mark a conversation as read
// @route   PATCH /api/messages/conversations/:id/read
// @access  Private
exports.markAsRead = asyncHandler(async (req, res) => {
    const conversation = await Conversation.findById(req.params.id);
    if (!conversation) {
        return res.status(404).json({ success: false, error: 'Conversation non trouvée' });
    }

    if (!canAccessConversation(conversation, req.user)) {
        return res.status(403).json({ success: false, error: 'Accès non autorisé à cette conversation' });
    }

    await Message.updateMany(
        {
            conversation: req.params.id,
            sender: { $ne: req.user.id },
            read: false
        },
        {
            read: true,
            readAt: Date.now()
        }
    );

    res.json({ success: true, data: { message: 'Conversation marquée comme lue' } });
});

// ===== WHATSAPP BUSINESS CONTROLLERS =====

// @desc    Test WhatsApp send (development)
// @route   POST /api/messages/whatsapp/test
// @access  Private
exports.testWhatsAppSend = asyncHandler(async (req, res) => {
    if (!isStaff(req.user.role) || process.env.NODE_ENV === 'production') {
        return res.status(403).json({
            success: false,
            error: 'Endpoint de test WhatsApp non autorisé'
        });
    }
    const { phoneNumber, message } = req.body;

    if (!phoneNumber || !message) {
        return res.status(400).json({
            success: false,
            error: 'phoneNumber et message sont requis'
        });
    }

    try {
        const twilioService = require('../services/twilio.service');
        const result = await twilioService.sendWhatsAppMessage(phoneNumber, message);

        res.status(200).json({
            success: true,
            data: {
                sid: result.sid,
                status: result.status,
                to: result.to,
                message: 'WhatsApp envoyé avec succès'
            }
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

// @desc    Send WhatsApp message in a conversation
// @route   POST /api/messages/conversations/:id/whatsapp
// @access  Private
exports.sendWhatsAppMessage = asyncHandler(async (req, res) => {
    const { content } = req.body;
    const conversationId = req.params.id;

    if (!content) {
        return res.status(400).json({
            success: false,
            error: 'Le contenu du message est requis'
        });
    }

    // Vérifier que la conversation existe
    const conversation = await Conversation.findById(conversationId);
    if (!conversation) {
        return res.status(404).json({
            success: false,
            error: 'Conversation non trouvée'
        });
    }

    // Vérifier que l'utilisateur est participant à cette conversation
    if (!canAccessConversation(conversation, req.user)) {
        return res.status(403).json({
            success: false,
            error: 'Non autorisé à envoyer des messages dans cette conversation'
        });
    }

    try {
        // 1. Envoyer le WhatsApp via Twilio
        const twilioService = require('../services/twilio.service');
        await conversation.populate('participants', 'phoneNumber name');
        const otherParticipant = conversation.participants.find(
            (p) => idOf(p) !== idOf(req.user)
        );
        const targetPhoneNumber = otherParticipant && otherParticipant.phoneNumber
            ? otherParticipant.phoneNumber
            : null;

        if (!targetPhoneNumber) {
            return res.status(400).json({
                success: false,
                error: 'Numéro de téléphone non trouvé pour cette conversation'
            });
        }

        const twilioResult = await twilioService.sendWhatsAppMessage(
            targetPhoneNumber,
            content
        );

        // 2. Enregistrer le message dans la base de données
        const message = await Message.create({
            conversation: conversationId,
            sender: req.user.id,
            content,
            platform: 'whatsapp',
            twilioSid: twilioResult.sid,
            phoneNumber: targetPhoneNumber
        });

        // 3. Mettre à jour la conversation
        conversation.lastMessage = message._id;
        conversation.updatedAt = Date.now();
        await conversation.save();

        // 4. Populate les données pour la réponse
        await message.populate('sender', 'name avatar');

        // 5. Notifications WebSocket temps réel (optionnel)
        try {
            const socketService = require('../services/socket.service');
            await socketService.notifyNewMessage(message, conversation);
        } catch (socketError) {
            console.error('Erreur lors de la notification WebSocket:', socketError);
            // Continue même en cas d'erreur
        }

        res.status(201).json({
            success: true,
            data: {
                message,
                whatsappSid: twilioResult.sid,
                sentTo: targetPhoneNumber
            }
        });

    } catch (error) {
        console.error('Erreur lors de l\'envoi WhatsApp:', error);
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

// ===== FIN WHATSAPP CONTROLLERS =====
