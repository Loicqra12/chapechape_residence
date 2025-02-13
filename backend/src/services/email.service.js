const nodemailer = require('nodemailer');

class EmailService {
    constructor() {
        this.transporter = nodemailer.createTransport({
            host: process.env.EMAIL_HOST,
            port: process.env.EMAIL_PORT,
            auth: {
                user: process.env.EMAIL_USERNAME,
                pass: process.env.EMAIL_PASSWORD
            }
        });
    }

    // Envoyer un email
    async sendEmail(options) {
        const mailOptions = {
            from: process.env.EMAIL_FROM,
            to: options.email,
            subject: options.subject,
            html: options.html
        };

        await this.transporter.sendMail(mailOptions);
    }

    // Email de notification
    async sendNotificationEmail(user, notification) {
        let subject = 'Nouvelle notification de ChapeChape Residences';
        let content = notification.message;

        // Personnalisation du sujet selon le type de notification
        switch (notification.type) {
            case 'favorite_added':
                subject = 'Nouveau favori ajouté';
                break;
            case 'favorite_removed':
                subject = 'Favori supprimé';
                break;
            case 'favorite_price_changed':
                subject = 'Le prix d\'une de vos résidences favorites a changé';
                break;
            case 'favorite_status_changed':
                subject = 'Le statut d\'une de vos résidences favorites a changé';
                break;
        }

        await this.sendEmail({
            email: user.email,
            subject: subject,
            html: `
                <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
                    <h2 style="color: #333;">${subject}</h2>
                    <p style="color: #666; font-size: 16px;">${content}</p>
                    <div style="margin-top: 20px; padding: 15px; background-color: #f5f5f5; border-radius: 5px;">
                        <p style="margin: 0; color: #888; font-size: 14px;">
                            Pour plus de détails, connectez-vous à votre compte ChapeChape Residences.
                        </p>
                    </div>
                </div>
            `
        });
    }

    // Email de bienvenue
    async sendWelcome(user) {
        await this.sendEmail({
            email: user.email,
            subject: 'Bienvenue sur ChapeChape Residences!',
            html: `
                <h1>Bienvenue ${user.firstName}!</h1>
                <p>Nous sommes ravis de vous accueillir sur ChapeChape Residences.</p>
                <p>Commencez à explorer nos résidences dès maintenant!</p>
            `
        });
    }

    // Email de confirmation de réservation
    async sendBookingConfirmation(email, booking) {
        await this.sendEmail({
            email,
            subject: 'Confirmation de votre réservation',
            html: `
                <h1>Réservation confirmée!</h1>
                <p>Votre réservation a été confirmée avec succès.</p>
                <h2>Détails de la réservation:</h2>
                <ul>
                    <li>Check-in: ${booking.checkIn}</li>
                    <li>Check-out: ${booking.checkOut}</li>
                    <li>Nombre de personnes: ${booking.numberOfGuests}</li>
                    <li>Prix total: ${booking.totalPrice} €</li>
                </ul>
            `
        });
    }

    // Email de réinitialisation de mot de passe
    async sendPasswordReset(email, resetToken) {
        const resetURL = `${process.env.FRONTEND_URL}/reset-password/${resetToken}`;

        await this.sendEmail({
            email,
            subject: 'Réinitialisation de votre mot de passe',
            html: `
                <h1>Réinitialisation de mot de passe</h1>
                <p>Vous avez demandé à réinitialiser votre mot de passe.</p>
                <p>Cliquez sur le lien ci-dessous pour définir un nouveau mot de passe:</p>
                <a href="${resetURL}" style="display: inline-block; background: #007bff; color: white; padding: 10px 20px; text-decoration: none; border-radius: 5px;">
                    Réinitialiser mon mot de passe
                </a>
                <p>Si vous n'avez pas demandé cette réinitialisation, ignorez cet email.</p>
                <p>Ce lien expirera dans 10 minutes.</p>
            `
        });
    }

    // Email d'annulation de réservation
    async sendBookingCancellation(email, booking) {
        await this.sendEmail({
            email,
            subject: 'Annulation de votre réservation',
            html: `
                <h1>Réservation annulée</h1>
                <p>Votre réservation a été annulée avec succès.</p>
                <p>Si vous avez effectué un paiement, il sera remboursé sous 5-10 jours ouvrés.</p>
            `
        });
    }

    // Email de notification au partenaire
    async sendPartnerNotification(partner, type, data) {
        let subject, html;

        switch (type) {
            case 'new_booking':
                subject = 'Nouvelle réservation!';
                html = `
                    <h1>Nouvelle réservation pour votre résidence</h1>
                    <p>Une nouvelle réservation a été effectuée.</p>
                    <h2>Détails:</h2>
                    <ul>
                        <li>Check-in: ${data.checkIn}</li>
                        <li>Check-out: ${data.checkOut}</li>
                        <li>Nombre de personnes: ${data.guests}</li>
                    </ul>
                `;
                break;

            case 'booking_cancelled':
                subject = 'Annulation de réservation';
                html = `
                    <h1>Une réservation a été annulée</h1>
                    <p>Une réservation pour votre résidence a été annulée.</p>
                    <h2>Détails:</h2>
                    <ul>
                        <li>Check-in: ${data.checkIn}</li>
                        <li>Check-out: ${data.checkOut}</li>
                    </ul>
                `;
                break;
        }

        await this.sendEmail({
            email: partner.email,
            subject,
            html
        });
    }
}

module.exports = new EmailService();
