const mongoose = require('mongoose');

const conversationSchema = new mongoose.Schema({
    participants: [{
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true
    }],
    lastMessage: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Message'
    },
    unreadCount: {
        type: Number,
        default: 0
    },
    reservationId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Reservation'
    },
    residenceId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Residence'
    },
    createdAt: {
        type: Date,
        default: Date.now
    },
    updatedAt: {
        type: Date,
        default: Date.now
    }
});

const messageSchema = new mongoose.Schema({
    conversation: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Conversation',
        required: true
    },
    sender: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },
    content: {
        type: String,
        required: true,
        trim: true
    },
    read: {
        type: Boolean,
        default: false
    },
    readAt: {
        type: Date
    },
    attachments: [{
        type: {
            type: String,
            enum: ['image', 'document'],
            required: true
        },
        url: {
            type: String,
            required: true
        },
        name: String,
        size: Number
    }],
    reservationId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Reservation'
    },
    createdAt: {
        type: Date,
        default: Date.now
    }
});

// Méthodes statiques pour Conversation
conversationSchema.statics.getUserConversations = async function(userId) {
    const conversations = await this.find({ participants: userId })
        .populate('participants', 'name avatar')
        .populate('lastMessage')
        .populate('reservationId', 'status')
        .populate('residenceId', 'name')
        .sort('-updatedAt');

    return conversations.map(conversation => {
        const otherParticipant = conversation.participants.find(p => p._id.toString() !== userId);
        return {
            id: conversation._id,
            clientId: otherParticipant._id,
            clientName: otherParticipant.name,
            clientAvatar: otherParticipant.avatar,
            lastMessage: conversation.lastMessage ? conversation.lastMessage.content : '',
            timestamp: conversation.updatedAt,
            hasUnread: conversation.unreadCount > 0,
            unreadCount: conversation.unreadCount,
            residenceId: conversation.residenceId ? conversation.residenceId._id : null,
            residenceName: conversation.residenceId ? conversation.residenceId.name : null,
            reservationId: conversation.reservationId ? conversation.reservationId._id : null,
            reservationStatus: conversation.reservationId ? conversation.reservationId.status : null
        };
    });
};

// Méthodes statiques pour Message
messageSchema.statics.getConversationMessages = async function(conversationId, page = 1, limit = 20) {
    const skip = (page - 1) * limit;
    const messages = await this.find({ conversation: conversationId })
        .populate('sender', 'name avatar')
        .sort('-createdAt')
        .skip(skip)
        .limit(limit);

    return messages.map(message => ({
        id: message._id,
        senderId: message.sender._id,
        senderName: message.sender.name,
        senderAvatar: message.sender.avatar,
        content: message.content,
        timestamp: message.createdAt,
        read: message.read,
        readAt: message.readAt,
        attachments: message.attachments,
        reservationId: message.reservationId
    }));
};

// Middleware pre-save pour Message
messageSchema.pre('save', async function(next) {
    if (this.isNew) {
        // Incrémenter le compteur de messages non lus dans la conversation
        await mongoose.model('Conversation').updateOne(
            { _id: this.conversation },
            { $inc: { unreadCount: 1 }, updatedAt: Date.now() }
        );
    }
    next();
});

// Middleware pre-update pour Message
messageSchema.pre('updateMany', async function(next) {
    const update = this.getUpdate();
    if (update.read === true) {
        // Réinitialiser le compteur de messages non lus dans la conversation
        await mongoose.model('Conversation').updateOne(
            { _id: this._conditions.conversation },
            { $set: { unreadCount: 0 } }
        );
    }
    next();
});

// Middleware de validation pour la création de conversation
conversationSchema.pre('save', async function(next) {
    if (this.isNew && this.reservationId) {
        try {
            // Vérifier si la conversation est liée à une réservation
            const Reservation = mongoose.model('Reservation');
            const reservation = await Reservation.findById(this.reservationId);
            
            // Si la réservation existe mais n'a pas la messagerie activée
            if (reservation && !reservation.messagingEnabled) {
                const error = new Error('La conversation ne peut pas être créée car la messagerie n\'est pas activée pour cette réservation');
                return next(error);
            }
        } catch (error) {
            return next(error);
        }
    }
    next();
});

module.exports = {
    Message: mongoose.model('Message', messageSchema),
    Conversation: mongoose.model('Conversation', conversationSchema)
};
