const emailService = require('../../services/email.service');
const ApiError = require('../../utils/apiError');

/**
 * Envoyer un email de test
 * @param {Object} req
 * @param {Object} res
 * @param {Function} next
 * @returns {Promise<void>}
 */
const sendTestEmail = async (req, res, next) => {
  try {
    const { email, subject, content } = req.body;
    
    if (!email) {
      throw new ApiError('L\'adresse email est requise', 400);
    }
    
    console.log(`Envoi d'un email de test à : ${email}`);
    
    // Utiliser le service d'email avec API Brevo
    const result = await emailService.sendEmail({
      email,
      subject: subject || 'Test de l\'intégration Brevo',
      html: content || `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
          <h1 style="color: #4A6BD8;">Test d'email ChapeChape</h1>
          <p style="font-size: 16px; line-height: 1.5;">
            Ceci est un email de test envoyé via l'API Brevo.
          </p>
          <p style="font-size: 16px; line-height: 1.5;">
            Si vous recevez cet email, l'intégration entre ChapeChape et Brevo fonctionne correctement!
          </p>
          <div style="background-color: #f5f5f5; padding: 15px; border-radius: 5px; margin-top: 20px;">
            <p style="margin: 0; color: #666;">
              Date et heure d'envoi: ${new Date().toLocaleString()}
            </p>
          </div>
        </div>
      `
    });
    
    res.status(200).json({
      success: true,
      message: 'Email de test envoyé avec succès',
      result
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Tester l'envoi avec un template
 * @param {Object} req
 * @param {Object} res
 * @param {Function} next
 * @returns {Promise<void>}
 */
const sendTemplateTest = async (req, res, next) => {
  try {
    const { email, templateId, params } = req.body;
    
    if (!email) {
      throw new ApiError('L\'adresse email est requise', 400);
    }
    
    if (!templateId) {
      throw new ApiError('L\'ID du template est requis', 400);
    }
    
    console.log(`Envoi d'un email avec template ID ${templateId} à : ${email}`);
    
    // Utiliser la méthode sendWithTemplate
    const result = await emailService.sendWithTemplate({
      email,
      templateId: parseInt(templateId),
      params: params || {
        firstName: 'Utilisateur',
        lastName: 'Test',
        date: new Date().toLocaleDateString()
      },
      fallbackSubject: 'Test de template Brevo',
      fallbackHtml: `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
          <h1 style="color: #4A6BD8;">Test de template ChapeChape</h1>
          <p style="font-size: 16px; line-height: 1.5;">
            Le template ID ${templateId} n'a pas pu être utilisé. Ceci est un message de secours.
          </p>
        </div>
      `
    });
    
    res.status(200).json({
      success: true,
      message: 'Email avec template envoyé avec succès',
      result
    });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  sendTestEmail,
  sendTemplateTest
};
