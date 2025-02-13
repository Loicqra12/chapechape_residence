const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const User = require('../models/user.model');
const Partner = require('../models/partner.model');

class AuthService {
    // Générer un token JWT
    generateToken(id) {
        return jwt.sign({ id }, process.env.JWT_SECRET, {
            expiresIn: process.env.JWT_EXPIRES_IN
        });
    }

    // Vérifier le mot de passe
    async comparePassword(candidatePassword, userPassword) {
        return await bcrypt.compare(candidatePassword, userPassword);
    }

    // Hasher le mot de passe
    async hashPassword(password) {
        return await bcrypt.hash(password, 12);
    }

    // Créer et envoyer le token
    createSendToken(user, statusCode, res) {
        const token = this.generateToken(user._id);

        // Options du cookie
        const cookieOptions = {
            expires: new Date(
                Date.now() + process.env.JWT_COOKIE_EXPIRES_IN * 24 * 60 * 60 * 1000
            ),
            httpOnly: true
        };

        if (process.env.NODE_ENV === 'production') cookieOptions.secure = true;

        // Enlever le mot de passe de la sortie
        user.password = undefined;

        res.status(statusCode)
            .cookie('jwt', token, cookieOptions)
            .json({
                success: true,
                token,
                data: user
            });
    }

    // Vérifier si l'utilisateur existe
    async userExists(email) {
        return await User.findOne({ email });
    }

    // Vérifier si le partenaire existe
    async partnerExists(email) {
        return await Partner.findOne({ email });
    }

    // Générer un token de réinitialisation de mot de passe
    async createPasswordResetToken(user) {
        const resetToken = crypto.randomBytes(32).toString('hex');

        user.passwordResetToken = crypto
            .createHash('sha256')
            .update(resetToken)
            .digest('hex');

        user.passwordResetExpires = Date.now() + 10 * 60 * 1000; // 10 minutes

        await user.save({ validateBeforeSave: false });

        return resetToken;
    }

    // Vérifier le token de réinitialisation de mot de passe
    async verifyPasswordResetToken(token, Model) {
        const hashedToken = crypto
            .createHash('sha256')
            .update(token)
            .digest('hex');

        const user = await Model.findOne({
            passwordResetToken: hashedToken,
            passwordResetExpires: { $gt: Date.now() }
        });

        return user;
    }
}

module.exports = new AuthService();
