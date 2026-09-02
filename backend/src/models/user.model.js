const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
const crypto = require('crypto');
const validator = require('validator');

const userSchema = new mongoose.Schema({
    email: {
        type: String,
        required: [true, 'Veuillez fournir un email'],
        unique: true,
        lowercase: true,  // Normalisation automatique
        trim: true,       // Suppression espaces
        validate: {
            validator: function (email) {
                // ✅ Validation robuste avec validator.js
                // Supporte TLDs modernes (.technology, .info, etc.)
                return validator.isEmail(email, {
                    allow_display_name: false,
                    allow_utf8_local_part: true,  // Support caractères internationaux
                    require_tld: true
                });
            },
            message: 'Veuillez fournir un email valide'
        }
    },
    // Identifiants pour l'authentification sociale
    googleId: {
        type: String,
        sparse: true
    },
    facebookId: {
        type: String,
        sparse: true
    },
    password: {
        type: String,
        required: [true, 'Veuillez fournir un mot de passe'],
        minlength: 6,
        select: false
    },
    firstName: {
        type: String,
        required: [true, 'Veuillez fournir un prénom']
    },
    lastName: {
        type: String,
        required: [true, 'Veuillez fournir un nom']
    },
    phoneNumber: {
        type: String,
        required: false
    },
    isPhoneVerified: {
        type: Boolean,
        default: false
    },
    /**
     * Overlay de vérification progressive (optionnel).
     * Source de vérité téléphone = isPhoneVerified.
     * identity / payout / property : demandés seulement si le risque l’exige.
     */
    verification: {
        identity: {
            type: String,
            enum: ['not_requested', 'pending', 'verified', 'rejected'],
            default: 'not_requested',
        },
        payout: {
            type: String,
            enum: ['not_configured', 'pending', 'verified'],
            default: 'not_configured',
        },
        property: {
            type: String,
            enum: ['not_required', 'requested', 'verified'],
            default: 'not_required',
        },
    },
    role: {
        type: String,
        enum: ['client', 'partner_pending', 'partner', 'admin', 'superadmin', 'owner'],
        default: 'client'
    },
    isVerified: {
        type: Boolean,
        default: false
    },
    /** Désactivation administrative du compte (JWT rejeté si false) */
    isActive: {
        type: Boolean,
        default: true
    },
    verificationToken: String,
    verificationTokenExpire: Date,
    resetPasswordToken: String,
    resetPasswordExpire: Date,
    passwordChangedAt: {
        type: Date,
        select: false
    },
    createdAt: {
        type: Date,
        default: Date.now
    },
    profileImage: {
        type: String,
        default: 'default.jpg'
    },
    profilePicture: {
        type: String
    },
    lastLogin: Date,
    // Dernière activité app (heartbeat via register device)
    lastAppActivity: Date,
    // Champs pour OneSignal
    deviceTokens: {
        type: [String],
        default: []
    },
    notificationSettings: {
        pushEnabled: {
            type: Boolean,
            default: true
        },
        emailEnabled: {
            type: Boolean,
            default: true
        },
        categories: {
            bookings: {
                type: Boolean,
                default: true
            },
            messages: {
                type: Boolean,
                default: true
            },
            payments: {
                type: Boolean,
                default: true
            },
            promotions: {
                type: Boolean,
                default: true
            },
            system: {
                type: Boolean,
                default: true
            }
        }
    }
}, {
    timestamps: true
});

// P2-06C — un subscription ID OneSignal → maximum 1 User (multikey unique, cross-process)
userSchema.index(
    { deviceTokens: 1 },
    {
        unique: true,
        name: 'deviceTokens_subscription_unique',
        partialFilterExpression: { 'deviceTokens.0': { $exists: true } },
    }
);

// Encrypt password using bcrypt
userSchema.pre('save', async function (next) {
    if (!this.isModified('password')) {
        return next();
    }

    // Permet d'invalider les JWT émis avant un changement de mot de passe
    if (!this.isNew) {
        this.passwordChangedAt = Date.now() - 1000;
    }

    const salt = await bcrypt.genSalt(10);
    this.password = await bcrypt.hash(this.password, salt);
    next();
});

// Match user entered password to hashed password in database
userSchema.methods.matchPassword = async function (enteredPassword) {
    return await bcrypt.compare(enteredPassword, this.password);
};

// Vérifie si le mot de passe a changé après l'émission du JWT
userSchema.methods.hasPasswordChangedAfter = function (jwtIssuedAt) {
    if (this.passwordChangedAt) {
        const changedTimestamp = parseInt(this.passwordChangedAt.getTime() / 1000, 10);
        return jwtIssuedAt < changedTimestamp;
    }
    return false;
};

// Generate and hash password token
userSchema.methods.getResetPasswordToken = function () {
    // Generate token
    const resetToken = crypto.randomBytes(20).toString('hex');

    // Hash token and set to resetPasswordToken field
    this.resetPasswordToken = crypto
        .createHash('sha256')
        .update(resetToken)
        .digest('hex');

    // Set expire
    this.resetPasswordExpire = Date.now() + 10 * 60 * 1000;

    return resetToken;
};

const User = mongoose.model('User', userSchema);

module.exports = User;
