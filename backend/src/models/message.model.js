const mongoose = require('mongoose');

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
    createdAt: {
        type: Date,
        default: Date.now
    }
});

// Index pour améliorer les performances
messageSchema.index({ conversation: 1, createdAt: -1 });
messageSchema.index({ sender: 1, createdAt: -1 });

// Méthodes statiques
messageSchema.statics.getConversationMessages = async function(conversationId, page = 1, limit = 20) {
    const skip = (page - 1) * limit;
    
    return this.find({ conversation: conversationId })
        .sort('-createdAt')
        .skip(skip)
        .limit(limit)
        .populate('sender', 'firstName lastName avatar');
};

messageSchema.statics.markAsRead = async function(messageId, userId) {
    return this.findOneAndUpdate(
        { _id: messageId, sender: { $ne: userId } },
        { read: true, readAt: new Date() },
        { new: true }
    );
};

// Méthodes d'instance
messageSchema.methods.isReadable = function(userId) {
    return this.sender.toString() !== userId.toString();
};

// Middleware pre-save
messageSchema.pre('save', function(next) {
    // Si le message est marqué comme lu, définir readAt
    if (this.read && !this.readAt) {
        this.readAt = new Date();
    }
    next();
});

// Middleware post-save
messageSchema.post('save', async function(doc) {
    // Mettre à jour la dernière activité de la conversation
    await mongoose.model('Conversation').findByIdAndUpdate(
        doc.conversation,
        {
            lastMessage: doc._id,
            lastActivity: doc.createdAt
        }
    );
});

const conversationSchema = new mongoose.Schema({
    participants: [{
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User'
    }],
    lastMessage: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Message'
    },
    lastActivity: {
        type: Date,
        default: Date.now
    },
    type: {
        type: String,
        enum: ['direct', 'group'],
        default: 'direct'
    },
    name: {
        type: String,
        trim: true
    },
    createdBy: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User'
    },
    createdAt: {
        type: Date,
        default: Date.now
    }
});

// Index pour améliorer les performances
conversationSchema.index({ participants: 1 });
conversationSchema.index({ lastActivity: -1 });

// Méthodes statiques
conversationSchema.statics.getUserConversations = async function(userId) {
    return this.find({ participants: userId })
        .populate('participants', 'firstName lastName avatar')
        .populate('lastMessage')
        .sort('-lastActivity');
};

conversationSchema.statics.findOrCreateDirectConversation = async function(user1Id, user2Id) {
    let conversation = await this.findOne({
        type: 'direct',
        participants: { $all: [user1Id, user2Id], $size: 2 }
    });

    if (!conversation) {
        conversation = await this.create({
            participants: [user1Id, user2Id],
            type: 'direct',
            createdBy: user1Id
        });
    }

    return conversation;
};

module.exports = {
    Message: mongoose.model('Message', messageSchema),
    Conversation: mongoose.model('Conversation', conversationSchema)
};
