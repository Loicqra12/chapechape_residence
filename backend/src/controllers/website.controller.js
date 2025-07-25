const asyncHandler = require('../middlewares/async.middleware');
const User = require('../models/user.model');
const emailService = require('../services/email.service');

// @desc    Handle contact form submission from website
// @route   POST /api/website/contact
// @access  Public
exports.submitContactForm = asyncHandler(async (req, res) => {
    const { firstName, lastName, email, phone, subject, message, company } = req.body;

    // Validation des champs requis
    if (!firstName || !lastName || !email || !message) {
        return res.status(400).json({
            success: false,
            error: 'Tous les champs obligatoires doivent être remplis'
        });
    }

    // Validation de l'email
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
        return res.status(400).json({
            success: false,
            error: 'Format d\'email invalide'
        });
    }

    try {
        // Envoyer l'email de notification à l'équipe
        const emailData = {
            to: process.env.CONTACT_EMAIL || 'contact@chapechaperesidence.com',
            subject: `Nouveau message de contact: ${subject || 'Sans sujet'}`,
            html: `
                <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
                    <div style="background: linear-gradient(135deg, #1a1a2e 0%, #16213e 100%); color: white; padding: 30px; text-align: center;">
                        <h1 style="margin: 0; font-size: 24px;">Nouveau message de contact</h1>
                        <p style="margin: 10px 0 0 0; opacity: 0.9;">Site ChapeChape Residence</p>
                    </div>
                    
                    <div style="padding: 30px; background: #f8f9fa;">
                        <div style="background: white; padding: 25px; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1);">
                            <h2 style="color: #1a1a2e; margin-top: 0;">Informations du contact</h2>
                            
                            <div style="margin-bottom: 15px;">
                                <strong style="color: #d4af37;">Nom complet:</strong> ${firstName} ${lastName}
                            </div>
                            
                            <div style="margin-bottom: 15px;">
                                <strong style="color: #d4af37;">Email:</strong> 
                                <a href="mailto:${email}" style="color: #1a1a2e;">${email}</a>
                            </div>
                            
                            ${phone ? `
                            <div style="margin-bottom: 15px;">
                                <strong style="color: #d4af37;">Téléphone:</strong> ${phone}
                            </div>
                            ` : ''}
                            
                            ${company ? `
                            <div style="margin-bottom: 15px;">
                                <strong style="color: #d4af37;">Entreprise:</strong> ${company}
                            </div>
                            ` : ''}
                            
                            <div style="margin-bottom: 15px;">
                                <strong style="color: #d4af37;">Sujet:</strong> ${subject || 'Non spécifié'}
                            </div>
                            
                            <div style="margin-bottom: 15px;">
                                <strong style="color: #d4af37;">Message:</strong>
                                <div style="background: #f8f9fa; padding: 15px; border-radius: 5px; margin-top: 10px; border-left: 4px solid #d4af37;">
                                    ${message.replace(/\n/g, '<br>')}
                                </div>
                            </div>
                            
                            <div style="margin-top: 25px; padding-top: 20px; border-top: 1px solid #eee; color: #666; font-size: 14px;">
                                <strong>Date:</strong> ${new Date().toLocaleString('fr-FR', { 
                                    timeZone: 'Africa/Abidjan',
                                    year: 'numeric',
                                    month: 'long',
                                    day: 'numeric',
                                    hour: '2-digit',
                                    minute: '2-digit'
                                })}
                            </div>
                        </div>
                    </div>
                    
                    <div style="background: #1a1a2e; color: white; padding: 20px; text-align: center; font-size: 14px;">
                        <p style="margin: 0;">ChapeChape Residence - Plateforme de location immobilière</p>
                        <p style="margin: 5px 0 0 0; opacity: 0.8;">Ce message a été envoyé depuis le formulaire de contact du site web</p>
                    </div>
                </div>
            `
        };

        await emailService.sendEmail(emailData);

        // Envoyer un email de confirmation à l'utilisateur
        const confirmationEmailData = {
            to: email,
            subject: 'Confirmation de réception - ChapeChape Residence',
            html: `
                <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
                    <div style="background: linear-gradient(135deg, #1a1a2e 0%, #16213e 100%); color: white; padding: 30px; text-align: center;">
                        <h1 style="margin: 0; font-size: 24px;">Merci pour votre message !</h1>
                        <p style="margin: 10px 0 0 0; opacity: 0.9;">ChapeChape Residence</p>
                    </div>
                    
                    <div style="padding: 30px; background: #f8f9fa;">
                        <div style="background: white; padding: 25px; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1);">
                            <p style="color: #1a1a2e; font-size: 16px; line-height: 1.6;">
                                Bonjour <strong>${firstName}</strong>,
                            </p>
                            
                            <p style="color: #1a1a2e; font-size: 16px; line-height: 1.6;">
                                Nous avons bien reçu votre message et nous vous remercions de votre intérêt pour ChapeChape Residence.
                            </p>
                            
                            <p style="color: #1a1a2e; font-size: 16px; line-height: 1.6;">
                                Notre équipe va examiner votre demande et vous répondra dans les plus brefs délais, généralement sous 24 heures.
                            </p>
                            
                            <div style="background: #f8f9fa; padding: 20px; border-radius: 8px; margin: 20px 0; border-left: 4px solid #d4af37;">
                                <h3 style="color: #1a1a2e; margin-top: 0;">Récapitulatif de votre message :</h3>
                                <p style="margin: 5px 0;"><strong>Sujet:</strong> ${subject || 'Non spécifié'}</p>
                                <p style="margin: 5px 0;"><strong>Message:</strong> ${message.substring(0, 200)}${message.length > 200 ? '...' : ''}</p>
                            </div>
                            
                            <p style="color: #1a1a2e; font-size: 16px; line-height: 1.6;">
                                En attendant, n'hésitez pas à explorer notre plateforme et découvrir nos services de location immobilière en Afrique de l'Ouest.
                            </p>
                            
                            <div style="text-align: center; margin: 30px 0;">
                                <a href="https://presentation.chapechaperesidence.com" 
                                   style="background: linear-gradient(135deg, #d4af37 0%, #f4d03f 100%); 
                                          color: #1a1a2e; 
                                          padding: 12px 30px; 
                                          text-decoration: none; 
                                          border-radius: 25px; 
                                          font-weight: bold;
                                          display: inline-block;">
                                    Visiter notre site
                                </a>
                            </div>
                        </div>
                    </div>
                    
                    <div style="background: #1a1a2e; color: white; padding: 20px; text-align: center; font-size: 14px;">
                        <p style="margin: 0;">ChapeChape Residence</p>
                        <p style="margin: 5px 0 0 0; opacity: 0.8;">
                            📧 contact@chapechaperesidence.com | 📱 +225 XX XX XX XX XX
                        </p>
                        <p style="margin: 5px 0 0 0; opacity: 0.8;">
                            📍 Abidjan, Côte d'Ivoire
                        </p>
                    </div>
                </div>
            `
        };

        await emailService.sendEmail(confirmationEmailData);

        res.status(200).json({
            success: true,
            message: 'Votre message a été envoyé avec succès. Nous vous répondrons bientôt !'
        });

    } catch (error) {
        console.error('Erreur lors de l\'envoi de l\'email de contact:', error);
        res.status(500).json({
            success: false,
            error: 'Erreur lors de l\'envoi du message. Veuillez réessayer plus tard.'
        });
    }
});

// @desc    Handle newsletter subscription from website
// @route   POST /api/website/newsletter
// @access  Public
exports.subscribeNewsletter = asyncHandler(async (req, res) => {
    const { email, firstName, lastName } = req.body;

    // Validation de l'email
    if (!email) {
        return res.status(400).json({
            success: false,
            error: 'L\'adresse email est requise'
        });
    }

    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
        return res.status(400).json({
            success: false,
            error: 'Format d\'email invalide'
        });
    }

    try {
        // Vérifier si l'utilisateur existe déjà
        let user = await User.findOne({ email });
        
        if (user) {
            // Mettre à jour les préférences de newsletter
            user.newsletterSubscribed = true;
            user.newsletterSubscribedAt = new Date();
            await user.save();
        } else {
            // Créer un nouvel utilisateur pour la newsletter
            user = await User.create({
                email,
                firstName: firstName || 'Abonné',
                lastName: lastName || 'Newsletter',
                password: 'newsletter-temp-' + Date.now(), // Mot de passe temporaire
                newsletterSubscribed: true,
                newsletterSubscribedAt: new Date(),
                isNewsletterOnly: true, // Flag pour identifier les utilisateurs newsletter uniquement
                role: 'client' // Rôle valide selon l'enum du modèle
            });
        }

        // Envoyer un email de bienvenue
        const welcomeEmailData = {
            to: email,
            subject: 'Bienvenue dans la newsletter ChapeChape Residence !',
            html: `
                <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
                    <div style="background: linear-gradient(135deg, #1a1a2e 0%, #16213e 100%); color: white; padding: 30px; text-align: center;">
                        <h1 style="margin: 0; font-size: 24px;">Bienvenue dans notre newsletter !</h1>
                        <p style="margin: 10px 0 0 0; opacity: 0.9;">ChapeChape Residence</p>
                    </div>
                    
                    <div style="padding: 30px; background: #f8f9fa;">
                        <div style="background: white; padding: 25px; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1);">
                            <p style="color: #1a1a2e; font-size: 16px; line-height: 1.6;">
                                ${firstName ? `Bonjour <strong>${firstName}</strong>,` : 'Bonjour,'}
                            </p>
                            
                            <p style="color: #1a1a2e; font-size: 16px; line-height: 1.6;">
                                Merci de vous être inscrit(e) à notre newsletter ! Vous recevrez désormais nos dernières actualités, conseils immobiliers et opportunités d'investissement en Afrique de l'Ouest.
                            </p>
                            
                            <div style="background: #f8f9fa; padding: 20px; border-radius: 8px; margin: 20px 0; border-left: 4px solid #d4af37;">
                                <h3 style="color: #1a1a2e; margin-top: 0;">Ce que vous recevrez :</h3>
                                <ul style="color: #1a1a2e; margin: 0; padding-left: 20px;">
                                    <li>Actualités du marché immobilier</li>
                                    <li>Conseils d'experts pour investisseurs</li>
                                    <li>Nouvelles propriétés disponibles</li>
                                    <li>Tendances du secteur immobilier</li>
                                    <li>Offres exclusives et promotions</li>
                                </ul>
                            </div>
                            
                            <p style="color: #1a1a2e; font-size: 16px; line-height: 1.6;">
                                En attendant, découvrez dès maintenant notre plateforme et explorez nos services de location immobilière premium.
                            </p>
                            
                            <div style="text-align: center; margin: 30px 0;">
                                <a href="https://presentation.chapechaperesidence.com" 
                                   style="background: linear-gradient(135deg, #d4af37 0%, #f4d03f 100%); 
                                          color: #1a1a2e; 
                                          padding: 12px 30px; 
                                          text-decoration: none; 
                                          border-radius: 25px; 
                                          font-weight: bold;
                                          display: inline-block;
                                          margin-right: 15px;">
                                    Découvrir nos services
                                </a>
                                
                                <a href="https://presentation.chapechaperesidence.com/blog" 
                                   style="background: transparent; 
                                          color: #1a1a2e; 
                                          padding: 12px 30px; 
                                          text-decoration: none; 
                                          border-radius: 25px; 
                                          font-weight: bold;
                                          display: inline-block;
                                          border: 2px solid #d4af37;">
                                    Lire notre blog
                                </a>
                            </div>
                            
                            <p style="color: #666; font-size: 14px; line-height: 1.6; margin-top: 30px; padding-top: 20px; border-top: 1px solid #eee;">
                                Vous pouvez vous désinscrire à tout moment en cliquant sur le lien de désinscription présent dans nos emails.
                            </p>
                        </div>
                    </div>
                    
                    <div style="background: #1a1a2e; color: white; padding: 20px; text-align: center; font-size: 14px;">
                        <p style="margin: 0;">ChapeChape Residence</p>
                        <p style="margin: 5px 0 0 0; opacity: 0.8;">
                            📧 newsletter@chapechaperesidence.com | 🌐 chapechaperesidence.com
                        </p>
                        <p style="margin: 5px 0 0 0; opacity: 0.8;">
                            📍 Abidjan, Côte d'Ivoire
                        </p>
                    </div>
                </div>
            `
        };

        await emailService.sendEmail(welcomeEmailData);

        res.status(200).json({
            success: true,
            message: 'Inscription à la newsletter réussie ! Vérifiez votre email de bienvenue.'
        });

    } catch (error) {
        console.error('Erreur lors de l\'inscription à la newsletter:', error);
        
        // Si l'erreur est due à un email déjà existant
        if (error.code === 11000) {
            return res.status(400).json({
                success: false,
                error: 'Cette adresse email est déjà inscrite à notre newsletter.'
            });
        }
        
        res.status(500).json({
            success: false,
            error: 'Erreur lors de l\'inscription. Veuillez réessayer plus tard.'
        });
    }
});

// @desc    Get website statistics (for admin dashboard)
// @route   GET /api/website/stats
// @access  Private (Admin only)
exports.getWebsiteStats = asyncHandler(async (req, res) => {
    try {
        const stats = {
            totalNewsletterSubscribers: await User.countDocuments({ newsletterSubscribed: true }),
            newSubscribersThisMonth: await User.countDocuments({
                newsletterSubscribed: true,
                newsletterSubscribedAt: {
                    $gte: new Date(new Date().getFullYear(), new Date().getMonth(), 1)
                }
            }),
            totalUsers: await User.countDocuments({ isNewsletterOnly: { $ne: true } }),
            lastUpdated: new Date()
        };

        res.status(200).json({
            success: true,
            data: stats
        });

    } catch (error) {
        console.error('Erreur lors de la récupération des statistiques:', error);
        res.status(500).json({
            success: false,
            error: 'Erreur lors de la récupération des statistiques'
        });
    }
});
