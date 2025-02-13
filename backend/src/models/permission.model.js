const mongoose = require('mongoose');

const permissionSchema = new mongoose.Schema({
    name: {
        type: String,
        required: [true, 'Le nom de la permission est requis'],
        unique: true
    },
    description: {
        type: String,
        required: [true, 'La description de la permission est requise']
    },
    module: {
        type: String,
        required: [true, 'Le module est requis']
    },
    action: {
        type: String,
        required: [true, 'L\'action est requise'],
        enum: ['create', 'read', 'update', 'delete', 'manage']
    },
    isSystem: {
        type: Boolean,
        default: false
    },
    createdAt: {
        type: Date,
        default: Date.now
    }
});

module.exports = mongoose.model('Permission', permissionSchema);
