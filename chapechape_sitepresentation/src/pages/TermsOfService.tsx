import { motion } from 'framer-motion'
import SEOHead from '../components/seo/SEOHead'

const siteUrl = (import.meta as any).env?.VITE_SITE_URL || 'https://presentation.chapechaperesidence.com'

export default function TermsOfService() {
  return (
    <div className="min-h-screen bg-gradient-to-br from-primary-50 to-secondary-50 py-16">
      <SEOHead
        title="Conditions d'utilisation"
        description="Conditions d'utilisation des applications ChapeChape Client et ChapeChape Partner."
        url={`${siteUrl}/conditions`}
      />
      <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8">
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.8 }}
          className="bg-white rounded-2xl shadow-xl p-8 md:p-12"
        >
          <h1 className="text-4xl font-bold text-secondary-900 dark:text-white mb-8 text-center font-display">
            Conditions d'Utilisation
          </h1>
          
          <div className="prose prose-lg max-w-none">
            <p className="text-gray-600 mb-6">
              <strong>Dernière mise à jour :</strong> 2 septembre 2025
            </p>

            <section className="mb-8">
              <h2 className="text-2xl font-semibold text-secondary-900 dark:text-white mb-4 font-display">1. Acceptation des Conditions</h2>
              <p className="text-secondary-700 dark:text-secondary-300 leading-relaxed">
                En téléchargeant, installant ou utilisant les applications mobiles <strong>ChapeChape Client</strong> 
                et <strong>ChapeChape Partner</strong> (les "Applications"), vous acceptez d'être lié par ces 
                Conditions d'Utilisation. Si vous n'acceptez pas ces conditions, veuillez ne pas utiliser nos Applications.
              </p>
            </section>

            <section className="mb-8">
              <h2 className="text-2xl font-semibold text-secondary-900 dark:text-white mb-4 font-display">2. Description du Service</h2>
              <div className="space-y-4">
                <div>
                  <h3 className="text-xl font-medium text-secondary-800 dark:text-secondary-200 mb-2 font-display">ChapeChape Client</h3>
                  <p className="text-secondary-700 dark:text-secondary-300">
                    Application permettant à tous de rechercher, réserver et payer des séjours 
                    dans des résidences hôtelières partenaires.
                  </p>
                </div>
                <div>
                  <h3 className="text-xl font-medium text-secondary-800 dark:text-secondary-200 mb-2 font-display">ChapeChape Partner</h3>
                  <p className="text-secondary-700 dark:text-secondary-300">
                    Application permettant aux gestionnaires de résidences de gérer leurs propriétés, 
                    réservations et communications avec les clients.
                  </p>
                </div>
              </div>
            </section>

            <section className="mb-8">
              <h2 className="text-2xl font-semibold text-secondary-900 dark:text-white mb-4 font-display">3. Conditions d'Utilisation</h2>
              <div className="space-y-4">
                <div>
                  <h3 className="text-xl font-medium text-secondary-800 dark:text-secondary-200 mb-2">Âge minimum</h3>
                  <p className="text-secondary-700 dark:text-secondary-300">
                    Vous devez avoir au moins 18 ans pour utiliser nos Applications ou avoir l'autorisation 
                    de vos parents/tuteurs légaux.
                  </p>
                </div>
                <div>
                  <h3 className="text-xl font-medium text-secondary-800 dark:text-secondary-200 mb-2 font-display">Compte utilisateur</h3>
                  <ul className="list-disc list-inside text-secondary-700 dark:text-secondary-300 space-y-1">
                    <li>Vous êtes responsable de la confidentialité de vos identifiants</li>
                    <li>Vous devez fournir des informations exactes et à jour</li>
                    <li>Un seul compte par personne est autorisé</li>
                    <li>Vous êtes responsable de toutes les activités sur votre compte</li>
                  </ul>
                </div>
              </div>
            </section>

            <section className="mb-8">
              <h2 className="text-2xl font-semibold text-secondary-900 dark:text-white mb-4 font-display">4. Réservations et Paiements</h2>
              <div className="space-y-4">
                <div>
                  <h3 className="text-xl font-medium text-secondary-800 dark:text-secondary-200 mb-2 font-display">Processus de réservation</h3>
                  <ul className="list-disc list-inside text-secondary-700 dark:text-secondary-300 space-y-1">
                    <li>Les réservations sont confirmées après paiement complet</li>
                    <li>Les prix affichés incluent toutes les taxes applicables</li>
                    <li>La disponibilité est mise à jour en temps réel mais non garantie jusqu'à confirmation</li>
                  </ul>
                </div>
                <div>
                  <h3 className="text-xl font-medium text-secondary-800 dark:text-secondary-200 mb-2 font-display">Méthodes de paiement</h3>
                  <p className="text-secondary-700 dark:text-secondary-300">
                    Nous acceptons les paiements via CinetPay, Wave, Orange Money et MTN Mobile Money. 
                    Tous les paiements sont sécurisés et traités par nos prestataires certifiés.
                  </p>
                </div>
                <div>
                  <h3 className="text-xl font-medium text-secondary-800 dark:text-secondary-200 mb-2 font-display">Politique d'annulation</h3>
                  <p className="text-secondary-700 dark:text-secondary-300">
                    Les conditions d'annulation varient selon la résidence et sont clairement indiquées 
                    lors de la réservation. Les remboursements sont traités selon ces conditions.
                  </p>
                </div>
              </div>
            </section>

            <section className="mb-8">
              <h2 className="text-2xl font-semibold text-secondary-900 dark:text-white mb-4">5. Comportement Interdit</h2>
              <p className="text-secondary-700 dark:text-secondary-300 mb-4">Il est strictement interdit de :</p>
              <ul className="list-disc list-inside text-secondary-700 dark:text-secondary-300 space-y-2">
                <li>Utiliser les Applications à des fins illégales ou non autorisées</li>
                <li>Tenter de contourner les mesures de sécurité</li>
                <li>Publier du contenu offensant, diffamatoire ou inapproprié</li>
                <li>Usurper l'identité d'une autre personne</li>
                <li>Interférer avec le fonctionnement des Applications</li>
                <li>Extraire ou copier des données sans autorisation</li>
                <li>Créer de faux comptes ou réservations</li>
              </ul>
            </section>

            <section className="mb-8">
              <h2 className="text-2xl font-semibold text-secondary-900 dark:text-white mb-4 font-display">6. Propriété Intellectuelle</h2>
              <p className="text-secondary-700 dark:text-secondary-300 mb-4">
                Tous les contenus des Applications (textes, images, logos, design) sont protégés par 
                les droits de propriété intellectuelle de ChapeChape Residence ou de ses partenaires.
              </p>
              <p className="text-secondary-700 dark:text-secondary-300">
                Vous ne pouvez pas reproduire, distribuer ou modifier ces contenus sans autorisation écrite.
              </p>
            </section>

            <section className="mb-8">
              <h2 className="text-2xl font-semibold text-secondary-900 dark:text-white mb-4 font-display">7. Limitation de Responsabilité</h2>
              <div className="space-y-4">
                <p className="text-secondary-700 dark:text-secondary-300">
                  ChapeChape Residence agit en tant qu'intermédiaire entre les clients et les résidences partenaires. 
                  Notre responsabilité est limitée au service de réservation.
                </p>
                <div className="bg-yellow-50 p-4 rounded-lg">
                  <p className="text-secondary-700 dark:text-secondary-300">
                    <strong>Important :</strong> Nous ne sommes pas responsables des dommages indirects, 
                    de la perte de données, ou des problèmes liés aux séjours dans les résidences partenaires.
                  </p>
                </div>
              </div>
            </section>

            <section className="mb-8">
              <h2 className="text-2xl font-semibold text-secondary-900 dark:text-white mb-4 font-display">8. Suspension et Résiliation</h2>
              <p className="text-secondary-700 dark:text-secondary-300 mb-4">
                Nous nous réservons le droit de suspendre ou résilier votre accès aux Applications en cas de :
              </p>
              <ul className="list-disc list-inside text-secondary-700 dark:text-secondary-300 space-y-1">
                <li>Violation de ces Conditions d'Utilisation</li>
                <li>Activité frauduleuse ou suspecte</li>
                <li>Non-paiement des services</li>
                <li>Comportement inapproprié envers notre équipe ou nos partenaires</li>
              </ul>
            </section>

            <section className="mb-8">
              <h2 className="text-2xl font-semibold text-secondary-900 dark:text-white mb-4 font-display">9. Modifications des Conditions</h2>
              <p className="text-secondary-700 dark:text-secondary-300">
                Nous pouvons modifier ces Conditions d'Utilisation à tout moment. Les modifications 
                importantes seront notifiées via l'Application ou par email. L'utilisation continue 
                des Applications après modification constitue votre acceptation des nouvelles conditions.
              </p>
            </section>

            <section className="mb-8">
              <h2 className="text-2xl font-semibold text-secondary-900 dark:text-white mb-4 font-display">10. Droit Applicable et Juridiction</h2>
              <p className="text-secondary-700 dark:text-secondary-300">
                Ces Conditions d'Utilisation sont régies par le droit ivoirien. Tout litige sera 
                soumis à la juridiction exclusive des tribunaux de Côte d'Ivoire.
              </p>
            </section>

            <section className="mb-8">
              <h2 className="text-2xl font-semibold text-secondary-900 dark:text-white mb-4 font-display">11. Contact</h2>
              <div className="bg-blue-50 p-6 rounded-lg">
                <p className="text-secondary-700 dark:text-secondary-300 mb-2">
                  <strong>ChapeChape Residence</strong>
                </p>
                <p className="text-secondary-700 dark:text-secondary-300 mb-2">
                  <strong>Email :</strong> <a href="mailto:contact@chapechaperesidence.com" className="text-primary-600 hover:underline">contact@chapechaperesidence.com</a>
                </p>
                <p className="text-secondary-700 dark:text-secondary-300 mb-2">
                  Support : <a href="mailto:support@chapechaperesidence.com" className="text-primary-600 hover:underline">support@chapechaperesidence.com</a>
                </p>
                <p className="text-secondary-700 dark:text-secondary-300">
                  Site web : <a href="https://presentation.chapechaperesidence.com" className="text-primary-600 hover:underline">presentation.chapechaperesidence.com</a>
                </p>
              </div>
            </section>
          </div>
        </motion.div>
      </div>
    </div>
  )
}
