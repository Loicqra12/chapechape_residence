const cron = require('node-cron');
const AutomaticPayoutService = require('../services/automatic-payout.service');
const logger = require('../utils/logger');

/**
 * Job Scheduler pour les Payouts Automatiques
 * Traite les payouts programmés toutes les 5 minutes
 */
class PayoutSchedulerJob {
    
    static init() {
        // Exécuter toutes les 5 minutes
        cron.schedule('*/5 * * * *', async () => {
            try {
                logger.info('Démarrage du job de traitement des payouts programmés');
                await AutomaticPayoutService.processScheduledPayouts();
                logger.info('Job de traitement des payouts terminé avec succès');
            } catch (error) {
                logger.error('Erreur lors du job de traitement des payouts:', error);
            }
        }, {
            scheduled: true,
            timezone: "Africa/Abidjan"
        });
        
        logger.info('Job scheduler des payouts automatiques initialisé (toutes les 5 minutes)');
    }
    
    // Méthode pour exécuter manuellement le job (utile pour les tests)
    static async runManually() {
        try {
            logger.info('Exécution manuelle du job de traitement des payouts');
            await AutomaticPayoutService.processScheduledPayouts();
            logger.info('Exécution manuelle terminée avec succès');
        } catch (error) {
            logger.error('Erreur lors de l\'exécution manuelle:', error);
            throw error;
        }
    }
}

module.exports = PayoutSchedulerJob;
