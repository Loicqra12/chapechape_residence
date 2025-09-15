const twilioService = require('./twilio.service');
const emailService = require('./email.service');
const oneSignalService = require('./onesignal.service');
const User = require('../models/user.model');
const phoneLogger = require('../utils/phoneLogger');

class PhoneChangeNotificationService {
    constructor() {
        this.notificationChannels = {
            sms: this.sendSMSNotification.bind(this),
            email: this.sendEmailNotification.bind(this),
            push: this.sendPushNotification.bind(this),
            admin: this.sendAdminNotification.bind(this),
            slack: this.sendSlackNotification.bind(this)
        };
        
        // Configuration des actions automatiques
        this.autoActions = {
            suspend_payouts_24h: this.suspendPayouts.bind(this),
            require_reverification: this.requireReverification.bind(this),
            update_payment_channels: this.updatePaymentChannels.bind(this)
        };
    }

    /**
     * Déclencher les notifications lors d'un changement de numéro partner
     * @param {Object} changeData - Données du changement
     */
    async notifyPhoneChange(changeData) {
        const {
            partnerId,
            oldNumber,
            newNumber,
            reason = 'profile_update',
            triggeredBy = 'partner'
        } = changeData;

        try {
            // Récupérer les informations du partner
            const partner = await User.findById(partnerId);
            if (!partner) {
                throw new Error('Partner non trouvé');
            }

            // Logger l'événement
            phoneLogger.log({
                action: 'phone_change_detected',
                partnerId: partnerId,
                oldNumber: oldNumber,
                newNumber: newNumber,
                reason: reason,
                triggeredBy: triggeredBy,
                timestamp: new Date()
            });

            // Préparer le contexte des notifications
            const context = {
                partner: {
                    id: partner._id,
                    name: `${partner.firstName} ${partner.lastName}`,
                    email: partner.email,
                    role: partner.role
                },
                phoneChange: {
                    oldNumber: oldNumber,
                    newNumber: newNumber,
                    reason: reason,
                    timestamp: new Date(),
                    triggeredBy: triggeredBy
                }
            };

            // Définir les cibles de notification
            const notificationTargets = this.defineNotificationTargets(context);

            // Exécuter les notifications en parallèle
            const notificationPromises = notificationTargets.map(target => 
                this.executeNotification(target, context)
            );

            // Exécuter les actions automatiques de sécurité
            const securityActions = this.defineSecurityActions(context);
            const actionPromises = securityActions.map(action => 
                this.executeSecurityAction(action, context)
            );

            // Attendre toutes les notifications et actions
            const [notificationResults, actionResults] = await Promise.allSettled([
                Promise.allSettled(notificationPromises),
                Promise.allSettled(actionPromises)
            ]);

            // Logger les résultats
            phoneLogger.log({
                action: 'phone_change_notifications_sent',
                partnerId: partnerId,
                notificationsSent: notificationResults[0].value?.filter(r => r.status === 'fulfilled').length || 0,
                actionsExecuted: actionResults[0].value?.filter(r => r.status === 'fulfilled').length || 0,
                errors: this.extractErrors(notificationResults, actionResults),
                timestamp: new Date()
            });

            return {
                success: true,
                notificationsSent: notificationResults[0].value?.length || 0,
                actionsExecuted: actionResults[0].value?.length || 0
            };

        } catch (error) {
            phoneLogger.log({
                action: 'phone_change_notification_failed',
                partnerId: partnerId,
                error: error.message,
                timestamp: new Date()
            });
            
            console.error('Erreur notifications changement téléphone:', error);
            throw error;
        }
    }

    /**
     * Définir les cibles de notification
     */
    defineNotificationTargets(context) {
        const targets = [];
        
        // Notification au partner (ancien numéro)
        if (context.phoneChange.oldNumber) {
            targets.push({
                type: 'partner',
                channel: 'sms',
                recipient: context.phoneChange.oldNumber,
                template: 'phone_change_old_number'
            });
        }

        // Notification au partner (nouveau numéro)
        if (context.phoneChange.newNumber) {
            targets.push({
                type: 'partner',
                channel: 'sms',
                recipient: context.phoneChange.newNumber,
                template: 'phone_change_new_number'
            });
        }

        // Notification push au partner
        targets.push({
            type: 'partner',
            channel: 'push',
            recipient: context.partner.id,
            template: 'phone_change_security_alert'
        });

        // Notification email au partner
        targets.push({
            type: 'partner',
            channel: 'email',
            recipient: context.partner.email,
            template: 'phone_change_confirmation'
        });

        // Notification aux admins
        targets.push({
            type: 'admin',
            channel: 'email',
            recipient: 'admin@chapechape.com',
            template: 'partner_phone_change_alert'
        });

        // Notification Slack pour l'équipe
        targets.push({
            type: 'team',
            channel: 'slack',
            recipient: '#partner-alerts',
            template: 'phone_change_slack'
        });

        return targets;
    }

    /**
     * Définir les actions de sécurité automatiques
     */
    defineSecurityActions(context) {
        return [
            {
                type: 'suspend_payouts_24h',
                priority: 'high',
                reason: 'Sécurité lors du changement de numéro'
            },
            {
                type: 'require_reverification',
                priority: 'high',
                reason: 'Nouveau numéro doit être vérifié'
            },
            {
                type: 'update_payment_channels',
                priority: 'medium',
                reason: 'Reconfigurer les canaux avec nouveau numéro'
            }
        ];
    }

    /**
     * Exécuter une notification
     */
    async executeNotification(target, context) {
        const { channel, recipient, template } = target;
        
        if (!this.notificationChannels[channel]) {
            throw new Error(`Canal de notification non supporté: ${channel}`);
        }

        const message = this.generateMessage(template, context);
        return await this.notificationChannels[channel](recipient, message, context);
    }

    /**
     * Exécuter une action de sécurité
     */
    async executeSecurityAction(action, context) {
        const { type } = action;
        
        if (!this.autoActions[type]) {
            throw new Error(`Action automatique non supportée: ${type}`);
        }

        return await this.autoActions[type](context, action);
    }

    /**
     * Générer le contenu du message selon le template
     */
    generateMessage(template, context) {
        const { partner, phoneChange } = context;
        
        const templates = {
            phone_change_old_number: `🔔 ALERTE SÉCURITÉ ChapeChape

Votre numéro de téléphone partenaire a été modifié.

Ancien: ${phoneChange.oldNumber}
Nouveau: ${phoneChange.newNumber}
Date: ${phoneChange.timestamp.toLocaleString('fr-FR')}

Si ce n'est pas vous, contactez immédiatement le support.

Sécurisé par ChapeChape`,

            phone_change_new_number: `✅ CONFIRMATION ChapeChape

Votre nouveau numéro a été enregistré avec succès.

Compte: ${partner.name}
Nouveau numéro: ${phoneChange.newNumber}
Date: ${phoneChange.timestamp.toLocaleString('fr-FR')}

Vos virements seront temporairement suspendus 24h pour sécurité.

Vérifiez ce numéro pour réactiver: [LIEN]

ChapeChape Partner`,

            phone_change_security_alert: {
                title: 'Numéro de téléphone modifié',
                body: `Votre numéro partenaire a été mis à jour. Vérifiez le nouveau numéro pour réactiver vos virements.`,
                data: {
                    type: 'phone_change',
                    partnerId: partner.id,
                    action: 'verify_new_phone'
                }
            },

            phone_change_confirmation: {
                subject: 'Confirmation - Numéro de téléphone modifié',
                html: this.generateEmailTemplate(context)
            },

            partner_phone_change_alert: {
                subject: `[ALERTE] Partner ${partner.name} - Changement téléphone`,
                html: this.generateAdminEmailTemplate(context)
            },

            phone_change_slack: {
                text: `🔔 Changement téléphone partner`,
                blocks: this.generateSlackBlocks(context)
            }
        };

        return templates[template] || `Notification: ${template}`;
    }

    /**
     * Générer le template email pour le partner
     */
    generateEmailTemplate(context) {
        const { partner, phoneChange } = context;
        
        return `
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="utf-8">
            <title>Changement de numéro - ChapeChape</title>
        </head>
        <body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333;">
            <div style="max-width: 600px; margin: 0 auto; padding: 20px;">
                <div style="background: #f8f9fa; padding: 20px; border-radius: 8px; margin-bottom: 20px;">
                    <h2 style="color: #007bff; margin: 0;">🔔 Numéro de téléphone modifié</h2>
                </div>
                
                <p>Bonjour <strong>${partner.name}</strong>,</p>
                
                <p>Votre numéro de téléphone partenaire a été modifié avec succès.</p>
                
                <div style="background: #e9ecef; padding: 15px; border-radius: 5px; margin: 20px 0;">
                    <p><strong>Détails du changement :</strong></p>
                    <ul>
                        <li>Ancien numéro : ${phoneChange.oldNumber}</li>
                        <li>Nouveau numéro : ${phoneChange.newNumber}</li>
                        <li>Date : ${phoneChange.timestamp.toLocaleString('fr-FR')}</li>
                        <li>Raison : ${phoneChange.reason}</li>
                    </ul>
                </div>
                
                <div style="background: #fff3cd; border: 1px solid #ffeaa7; padding: 15px; border-radius: 5px; margin: 20px 0;">
                    <h4 style="color: #856404; margin: 0 0 10px 0;">⚠️ Mesures de sécurité activées</h4>
                    <ul style="margin: 0;">
                        <li>Vos virements sont temporairement suspendus (24h)</li>
                        <li>Vérification du nouveau numéro requise</li>
                        <li>Canaux de paiement à reconfigurer</li>
                    </ul>
                </div>
                
                <div style="text-align: center; margin: 30px 0;">
                    <a href="${process.env.PARTNER_APP_URL}/verify-phone" 
                       style="background: #007bff; color: white; padding: 12px 24px; text-decoration: none; border-radius: 5px; display: inline-block;">
                        Vérifier le nouveau numéro
                    </a>
                </div>
                
                <div style="background: #f8d7da; border: 1px solid #f5c6cb; padding: 15px; border-radius: 5px; margin: 20px 0;">
                    <p style="margin: 0; color: #721c24;">
                        <strong>🔒 Si ce changement n'est pas de vous :</strong><br>
                        Contactez immédiatement notre support au +225 XX XX XX XX
                    </p>
                </div>
                
                <hr style="margin: 30px 0; border: none; border-top: 1px solid #eee;">
                
                <p style="font-size: 12px; color: #666;">
                    Cet email a été envoyé automatiquement par le système de sécurité ChapeChape.<br>
                    ChapeChape Residences - Votre partenaire immobilier de confiance
                </p>
            </div>
        </body>
        </html>`;
    }

    /**
     * Générer le template email pour les admins
     */
    generateAdminEmailTemplate(context) {
        const { partner, phoneChange } = context;
        
        return `
        <h2>🚨 Alerte Partner - Changement téléphone</h2>
        
        <table border="1" cellpadding="10" cellspacing="0" style="border-collapse: collapse;">
            <tr><th>Partner ID</th><td>${partner.id}</td></tr>
            <tr><th>Nom</th><td>${partner.name}</td></tr>
            <tr><th>Email</th><td>${partner.email}</td></tr>
            <tr><th>Ancien numéro</th><td>${phoneChange.oldNumber}</td></tr>
            <tr><th>Nouveau numéro</th><td>${phoneChange.newNumber}</td></tr>
            <tr><th>Date changement</th><td>${phoneChange.timestamp.toLocaleString('fr-FR')}</td></tr>
            <tr><th>Déclenché par</th><td>${phoneChange.triggeredBy}</td></tr>
            <tr><th>Raison</th><td>${phoneChange.reason}</td></tr>
        </table>
        
        <h3>Actions automatiques exécutées :</h3>
        <ul>
            <li>✅ Virements suspendus 24h</li>
            <li>✅ Vérification requise</li>
            <li>✅ Canaux paiement à reconfigurer</li>
        </ul>
        
        <p><a href="${process.env.ADMIN_PANEL_URL}/partners/${partner.id}">Voir le profil partner</a></p>`;
    }

    /**
     * Générer les blocs Slack
     */
    generateSlackBlocks(context) {
        const { partner, phoneChange } = context;
        
        return [
            {
                type: "header",
                text: {
                    type: "plain_text",
                    text: "🔔 Changement téléphone partner"
                }
            },
            {
                type: "section",
                fields: [
                    {
                        type: "mrkdwn",
                        text: `*Partner:* ${partner.name}`
                    },
                    {
                        type: "mrkdwn",
                        text: `*ID:* ${partner.id}`
                    },
                    {
                        type: "mrkdwn",
                        text: `*Ancien:* ${phoneChange.oldNumber}`
                    },
                    {
                        type: "mrkdwn",
                        text: `*Nouveau:* ${phoneChange.newNumber}`
                    }
                ]
            },
            {
                type: "context",
                elements: [
                    {
                        type: "mrkdwn",
                        text: `Date: ${phoneChange.timestamp.toLocaleString('fr-FR')} | Raison: ${phoneChange.reason}`
                    }
                ]
            },
            {
                type: "actions",
                elements: [
                    {
                        type: "button",
                        text: {
                            type: "plain_text",
                            text: "Voir profil"
                        },
                        url: `${process.env.ADMIN_PANEL_URL}/partners/${partner.id}`
                    }
                ]
            }
        ];
    }

    /**
     * Envoyer notification SMS
     */
    async sendSMSNotification(phoneNumber, message, context) {
        return await twilioService.sendSMS(phoneNumber, message);
    }

    /**
     * Envoyer notification email
     */
    async sendEmailNotification(email, messageData, context) {
        return await emailService.sendEmail({
            to: email,
            subject: messageData.subject,
            html: messageData.html
        });
    }

    /**
     * Envoyer notification push
     */
    async sendPushNotification(userId, messageData, context) {
        return await oneSignalService.sendToUser(userId, {
            title: messageData.title,
            body: messageData.body,
            data: messageData.data
        });
    }

    /**
     * Envoyer notification admin
     */
    async sendAdminNotification(adminEmail, messageData, context) {
        return await this.sendEmailNotification(adminEmail, messageData, context);
    }

    /**
     * Envoyer notification Slack
     */
    async sendSlackNotification(channel, messageData, context) {
        // Implémentation webhook Slack
        // À adapter selon votre configuration Slack
        console.log(`Slack notification to ${channel}:`, messageData);
        return { success: true, channel: channel };
    }

    /**
     * Action : Suspendre les virements 24h
     */
    async suspendPayouts(context, action) {
        const partnerId = context.partner.id;
        const suspendUntil = new Date(Date.now() + 24 * 60 * 60 * 1000); // 24h
        
        await User.findByIdAndUpdate(partnerId, {
            'payoutSuspension.suspended': true,
            'payoutSuspension.suspendedUntil': suspendUntil,
            'payoutSuspension.reason': 'phone_change_security',
            'payoutSuspension.suspendedAt': new Date()
        });
        
        return { action: 'suspend_payouts_24h', success: true, suspendUntil };
    }

    /**
     * Action : Requérir une re-vérification
     */
    async requireReverification(context, action) {
        const partnerId = context.partner.id;
        
        await User.findByIdAndUpdate(partnerId, {
            'isPhoneVerified': false,
            'phoneVerificationRequired': true,
            'phoneVerificationReason': 'phone_changed'
        });
        
        return { action: 'require_reverification', success: true };
    }

    /**
     * Action : Mettre à jour les canaux de paiement
     */
    async updatePaymentChannels(context, action) {
        const partnerId = context.partner.id;
        const newNumber = context.phoneChange.newNumber;
        
        // Réinitialiser les canaux de paiement
        await User.findByIdAndUpdate(partnerId, {
            'payoutPreferences.phoneNumber': newNumber,
            'payoutPreferences.supportedChannels': [],
            'payoutPreferences.preferredChannel': null,
            'payoutPreferences.needsReconfiguration': true,
            'payoutPreferences.lastUpdated': new Date()
        });
        
        return { action: 'update_payment_channels', success: true };
    }

    /**
     * Extraire les erreurs des résultats
     */
    extractErrors(notificationResults, actionResults) {
        const errors = [];
        
        if (notificationResults && notificationResults[0] && notificationResults[0].value) {
            notificationResults[0].value.forEach((result, index) => {
                if (result.status === 'rejected') {
                    errors.push(`Notification ${index}: ${result.reason}`);
                }
            });
        }
        
        if (actionResults && actionResults[0] && actionResults[0].value) {
            actionResults[0].value.forEach((result, index) => {
                if (result.status === 'rejected') {
                    errors.push(`Action ${index}: ${result.reason}`);
                }
            });
        }
        
        return errors;
    }
}

module.exports = new PhoneChangeNotificationService();
