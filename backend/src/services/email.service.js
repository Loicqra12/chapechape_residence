const SibApiV3Sdk = require('sib-api-v3-sdk');
const nodemailer = require('nodemailer');

class EmailService {
    constructor() {
        // Configuration selon la documentation officielle de Brevo/Sendinblue
        const defaultClient = SibApiV3Sdk.ApiClient.instance;
        
        // Configuration de l'authentification
        const apiKey = defaultClient.authentications['api-key'];
        apiKey.apiKey = process.env.BREVO_API_KEY;
        
        // Création de l'instance API pour les emails transactionnels
        this.apiInstance = new SibApiV3Sdk.TransactionalEmailsApi();
        
        console.log('Service email initialisé avec Brevo/Sendinblue SDK');
        
        // Garder le transporteur Nodemailer en backup
        this.transporter = nodemailer.createTransport({
            host: process.env.EMAIL_HOST,
            port: parseInt(process.env.EMAIL_PORT),
            secure: false, // true pour 465, false pour les autres ports
            auth: {
                user: process.env.EMAIL_USERNAME,
                pass: process.env.EMAIL_PASSWORD
            }
        });
    }

    // Envoyer un email avec Brevo API
    async sendEmail(options) {
        try {
            // Définir un expéditeur vérifié dans Brevo
            const sender = {
                name: "ChapeChape Residences",
                // Utiliser l'adresse email vérifiée configurée dans les variables d'environnement
                email: process.env.EMAIL_USERNAME || process.env.SMTP_USER || "noreply@chapechaperesidence.com"
            };
            
            // Support pour les champs 'to' et 'email'
            const recipientEmail = options.to || options.email;
            if (!recipientEmail) {
                throw new Error('Aucun destinataire spécifié (champ to ou email requis)');
            }
            
            const receivers = [{
                email: recipientEmail
            }];
            
            // Création de l'objet de requête d'email
            const sendSmtpEmail = new SibApiV3Sdk.SendSmtpEmail();
            sendSmtpEmail.sender = sender;
            sendSmtpEmail.to = receivers;
            sendSmtpEmail.subject = options.subject;
            sendSmtpEmail.htmlContent = options.html;
            
            // Configurer l'adresse de réponse
            if (options.replyTo || process.env.EMAIL_REPLY_TO) {
                sendSmtpEmail.replyTo = {
                    email: options.replyTo || process.env.EMAIL_REPLY_TO || "support@chapechaperesidence.com",
                    name: "Support ChapeChape Residences"
                };
            }
            
            console.log('Envoi d\'email via API Brevo à:', recipientEmail);
            const data = await this.apiInstance.sendTransacEmail(sendSmtpEmail);
            console.log('Email envoyé avec succès. ID:', data.messageId);
            return data;
        } catch (error) {
            console.error('Erreur lors de l\'envoi via API Brevo:', error);
            console.log('Tentative d\'envoi via SMTP en fallback...');
            
            // Fallback à nodemailer en cas d'erreur avec l'API
            return this.sendEmailWithNodemailer(options);
        }
    }
    
    // Méthode de fallback utilisant Nodemailer
    async sendEmailWithNodemailer(options) {
        const mailOptions = {
            from: process.env.EMAIL_FROM || "ChapeChape Residences <noreply@chapechaperesidence.com>",
            replyTo: process.env.EMAIL_REPLY_TO || "support@chapechaperesidence.com",
            to: options.email,
            subject: options.subject,
            html: options.html
        };

        try {
            const info = await this.transporter.sendMail(mailOptions);
            console.log('Email de fallback envoyé avec succès. ID:', info.messageId);
            return info;
        } catch (error) {
            console.error('Erreur critique lors de l\'envoi d\'email:', error);
            throw error;
        }
    }

    // Envoyer un email en utilisant un template Brevo
    async sendTemplateEmail(options) {
        try {
            const sender = {
                name: "ChapeChape Residences",
                email: process.env.EMAIL_USERNAME || process.env.SMTP_USER || "noreply@chapechaperesidence.com"
            };
            
            const receivers = [{
                email: options.email
            }];
            
            // Création de l'objet de requête d'email
            const sendSmtpEmail = new SibApiV3Sdk.SendSmtpEmail();
            sendSmtpEmail.sender = sender;
            sendSmtpEmail.to = receivers;
            sendSmtpEmail.templateId = options.templateId;
            
            // Ajout des variables dynamiques si nécessaire
            if (options.params) {
                sendSmtpEmail.params = options.params;
            }
            
            console.log(`Envoi d'email avec template ${options.templateId} via API Brevo à:`, options.email);
            const data = await this.apiInstance.sendTransacEmail(sendSmtpEmail);
            console.log('Email avec template envoyé avec succès. ID:', data.messageId);
            return data;
        } catch (error) {
            console.error('Erreur lors de l\'envoi d\'email avec template via API Brevo:', error);
            throw error;
        }
    }

    // Email de notification
    async sendNotificationEmail(user, notification) {
        let subject = 'Nouvelle notification de ChapeChape Residences';
        let content = notification.message;

        // Configurer les bons emails selon le type de notification
        const replyTo = process.env.EMAIL_SUPPORT;
        
        // Si un template spécifique n'est pas défini, utilisez le template de notification général
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
        
        // Utiliser un template si l'ID est configuré
        if (process.env.BREVO_NOTIFICATION_TEMPLATE_ID) {
            return this.sendTemplateEmail({
                email: user.email,
                templateId: parseInt(process.env.BREVO_NOTIFICATION_TEMPLATE_ID),
                replyTo: process.env.EMAIL_SUPPORT,
                params: {
                    firstName: user.firstName,
                    notificationType: notification.type,
                    notificationMessage: content
                }
            });
        }

        // Sinon utiliser le HTML standard
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
        // Utiliser un template si l'ID est configuré
        if (process.env.BREVO_WELCOME_TEMPLATE_ID) {
            return this.sendTemplateEmail({
                email: user.email,
                templateId: parseInt(process.env.BREVO_WELCOME_TEMPLATE_ID),
                replyTo: process.env.EMAIL_CONTACT,
                params: {
                    firstName: user.firstName,
                    lastName: user.lastName
                }
            });
        }
        
        // Sinon utiliser le HTML standard
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
        // Utiliser un template si l'ID est configuré
        if (process.env.BREVO_BOOKING_TEMPLATE_ID) {
            return this.sendTemplateEmail({
                email: email,
                templateId: parseInt(process.env.BREVO_BOOKING_TEMPLATE_ID),
                replyTo: process.env.EMAIL_SUPPORT,
                params: {
                    checkIn: new Date(booking.checkIn).toLocaleDateString(),
                    checkOut: new Date(booking.checkOut).toLocaleDateString(),
                    numberOfGuests: booking.numberOfGuests,
                    totalPrice: booking.totalPrice
                }
            });
        }
        
        // Sinon utiliser le HTML standard
        await this.sendEmail({
            email,
            subject: 'Confirmation de votre réservation',
            html: `
                <h1>Réservation confirmée!</h1>
                <p>Votre réservation a été confirmée avec succès.</p>
                <h2>Détails de la réservation:</h2>
                <ul>
                    <li>Check-in: ${new Date(booking.checkIn).toLocaleDateString()}</li>
                    <li>Check-out: ${new Date(booking.checkOut).toLocaleDateString()}</li>
                    <li>Nombre de personnes: ${booking.numberOfGuests}</li>
                    <li>Prix total: ${booking.totalPrice} FCFA</li>
                </ul>
            `
        });
    }

    // Email de réinitialisation de mot de passe
    async sendPasswordReset(email, resetToken) {
        const resetURL = `${process.env.FRONTEND_URL || 'https://chapechaperesidence.com'}/reset-password/${resetToken}`;

        // Utiliser un template si l'ID est configuré
        if (process.env.BREVO_RESET_PASSWORD_TEMPLATE_ID) {
            return this.sendTemplateEmail({
                email: email,
                templateId: parseInt(process.env.BREVO_RESET_PASSWORD_TEMPLATE_ID),
                replyTo: process.env.EMAIL_SUPPORT,
                params: {
                    resetURL: resetURL
                }
            });
        }

        // Sinon utiliser le HTML standard
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
        // Utiliser un template si l'ID est configuré
        if (process.env.BREVO_CANCELLATION_TEMPLATE_ID) {
            return this.sendTemplateEmail({
                email: email,
                templateId: parseInt(process.env.BREVO_CANCELLATION_TEMPLATE_ID),
                replyTo: process.env.EMAIL_SUPPORT,
                params: {
                    checkIn: new Date(booking.checkIn).toLocaleDateString(),
                    checkOut: new Date(booking.checkOut).toLocaleDateString()
                }
            });
        }

        // Sinon utiliser le HTML standard
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
        let subject, templateId, html;

        switch (type) {
            case 'new_booking':
                subject = 'Nouvelle réservation!';
                templateId = process.env.BREVO_PARTNER_NEW_BOOKING_TEMPLATE_ID;
                html = `
                    <h1>Nouvelle réservation pour votre résidence</h1>
                    <p>Une nouvelle réservation a été effectuée.</p>
                    <h2>Détails:</h2>
                    <ul>
                        <li>Check-in: ${new Date(data.checkIn).toLocaleDateString()}</li>
                        <li>Check-out: ${new Date(data.checkOut).toLocaleDateString()}</li>
                        <li>Nombre de personnes: ${data.guests}</li>
                    </ul>
                `;
                break;

            case 'booking_cancelled':
                subject = 'Annulation de réservation';
                templateId = process.env.BREVO_PARTNER_CANCELLATION_TEMPLATE_ID;
                html = `
                    <h1>Une réservation a été annulée</h1>
                    <p>Une réservation pour votre résidence a été annulée.</p>
                    <h2>Détails:</h2>
                    <ul>
                        <li>Check-in: ${new Date(data.checkIn).toLocaleDateString()}</li>
                        <li>Check-out: ${new Date(data.checkOut).toLocaleDateString()}</li>
                    </ul>
                `;
                break;
        }

        // Utiliser un template si l'ID est configuré
        if (templateId) {
            return this.sendTemplateEmail({
                email: partnerEmail,
                templateId: parseInt(templateId),
                replyTo: process.env.EMAIL_ADMIN,
                params: {
                    partnerName: partner.firstName,
                    ...data,
                    checkIn: new Date(data.checkIn).toLocaleDateString(),
                    checkOut: new Date(data.checkOut).toLocaleDateString()
                }
            });
        }

        // Sinon utiliser le HTML standard
        await this.sendEmail({
            email: partner.email,
            subject,
            html
        });
    }
}

// Exporter l'instance unique du service
module.exports = new EmailService();
