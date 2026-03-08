import { motion } from 'framer-motion'
import SEOHead from '../components/seo/SEOHead'

const siteUrl = (import.meta as any).env?.VITE_SITE_URL || 'https://presentation.chapechaperesidence.com'

const PrivacyPolicy = () => {
  return (
    <div className="min-h-screen bg-gradient-to-br from-primary-50 to-secondary-50 py-16">
      <SEOHead
        title="Politique de confidentialité"
        description="Politique de confidentialité et protection des données. ChapeChape Residence."
        url={`${siteUrl}/politique-de-confidentialite`}
      />
      <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8">
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.8 }}
          className="bg-white rounded-2xl shadow-xl p-8 md:p-12"
        >
          <h1 className="text-4xl font-bold text-secondary-900 dark:text-white mb-8 text-center font-display">
            Politique de Confidentialité
          </h1>
          
          <div className="prose prose-lg max-w-none">
            <p className="text-secondary-600 mb-6">
              <strong>Dernière mise à jour :</strong> 2 septembre 2025
            </p>

            <section className="mb-8">
              <h2 className="text-2xl font-semibold text-secondary-900 dark:text-white mb-4 font-display">1. Qui nous sommes</h2>
              <p className="text-secondary-700 dark:text-secondary-300 leading-relaxed mb-4">
                <strong>ChapeChape Residence</strong> ("nous", "notre", "nos") est une plateforme de réservation 
                de résidences hôtelières. Nous nous engageons à protéger et respecter votre vie privée.
              </p>
              <p className="text-secondary-700 dark:text-secondary-300 leading-relaxed">
                Cette politique explique comment nous collectons, utilisons et protégeons vos informations personnelles 
                lorsque vous utilisez nos applications mobiles <strong>ChapeChape Client</strong> (pour tous) 
                et <strong>ChapeChape Partner</strong> (pour les gestionnaires de résidences).
              </p>
              <div className="bg-primary-50 dark:bg-primary-900/20 p-4 rounded-lg mt-4">
                <p className="text-secondary-700 dark:text-secondary-300">
                  <strong>Contact :</strong> <a href="mailto:contact@chapechaperesidence.com" className="text-primary-600 hover:underline">contact@chapechaperesidence.com</a>
                </p>
              </div>
            </section>

            <section className="mb-8">
              <h2 className="text-2xl font-semibold text-secondary-900 dark:text-white mb-4 font-display">2. Données Collectées</h2>
              <div className="space-y-4">
                <div>
                  <h3 className="text-xl font-medium text-secondary-800 dark:text-secondary-200 font-display mb-2">Informations d'identification</h3>
                  <ul className="list-disc list-inside text-secondary-700 dark:text-secondary-300 space-y-1">
                    <li>Nom complet</li>
                    <li>Adresse email</li>
                    <li>Numéro de téléphone</li>
                    <li>Photo de profil (optionnelle)</li>
                  </ul>
                </div>
                
                <div>
                  <h3 className="text-xl font-medium text-secondary-800 dark:text-secondary-200 font-display mb-2">Données de localisation</h3>
                  <ul className="list-disc list-inside text-secondary-700 dark:text-secondary-300 space-y-1">
                    <li>Position géographique pour la recherche de résidences</li>
                    <li>Adresses de réservation</li>
                  </ul>
                </div>

                <div>
                  <h3 className="text-xl font-medium text-secondary-800 dark:text-secondary-200 font-display mb-2">Informations de réservation</h3>
                  <ul className="list-disc list-inside text-secondary-700 dark:text-secondary-300 space-y-1">
                    <li>Historique des réservations</li>
                    <li>Préférences de logement</li>
                    <li>Évaluations et commentaires</li>
                  </ul>
                </div>

                <div>
                  <h3 className="text-xl font-medium text-secondary-800 dark:text-secondary-200 font-display mb-2">Données de paiement</h3>
                  <ul className="list-disc list-inside text-secondary-700 dark:text-secondary-300 space-y-1">
                    <li>Montants des transactions</li>
                    <li>Méthodes de paiement utilisées (CinetPay, Wave, OM, MTN)</li>
                    <li>Historique des paiements</li>
                  </ul>
                  <p className="text-sm text-secondary-600 mt-2 italic">
                    <strong>Important :</strong> Nous ne stockons pas les informations de carte bancaire ; 
                    le traitement sécurisé est assuré par nos prestataires de paiement.
                  </p>
                </div>

                <div>
                  <h3 className="text-xl font-medium text-secondary-800 dark:text-secondary-200 font-display mb-2">Données techniques</h3>
                  <ul className="list-disc list-inside text-secondary-700 dark:text-secondary-300 space-y-1">
                    <li>Journaux d'erreurs et de performance (logs de crash)</li>
                    <li>Données d'utilisation de l'application</li>
                    <li>Identifiants d'appareil pour les notifications push (OneSignal)</li>
                    <li>Informations de l'appareil (modèle, version OS)</li>
                  </ul>
                </div>

                <div>
                  <h3 className="text-xl font-medium text-secondary-800 dark:text-secondary-200 font-display mb-2">Données spécifiques à l'app Partner</h3>
                  <ul className="list-disc list-inside text-secondary-700 dark:text-secondary-300 space-y-1">
                    <li>Informations de contact professionnel</li>
                    <li>Statistiques de performance des résidences</li>
                    <li>Communications avec les clients (chat intégré)</li>
                    <li>Données de gestion des réservations</li>
                  </ul>
                </div>
              </div>
            </section>

            <section className="mb-8">
              <h2 className="text-2xl font-semibold text-secondary-900 dark:text-white mb-4 font-display">3. Utilisation des Données</h2>
              <p className="text-secondary-700 dark:text-secondary-300 mb-4">Nous utilisons vos données pour :</p>
              <ul className="list-disc list-inside text-secondary-700 dark:text-secondary-300 space-y-2">
                <li>Fournir nos services de réservation de résidences</li>
                <li>Traiter vos paiements de manière sécurisée via CinetPay, Wave, Orange Money, MTN Mobile Money</li>
                <li>Prévenir les doublons de réservation et gérer la disponibilité</li>
                <li>Vous envoyer des notifications importantes (confirmations, rappels)</li>
                <li>Faciliter la communication entre clients et partenaires (chat intégré)</li>
                <li>Améliorer nos services et votre expérience utilisateur</li>
                <li>Assurer la sécurité et prévenir la fraude</li>
                <li>Respecter nos obligations légales et réglementaires</li>
                <li>Gérer les réclamations et le support client</li>
              </ul>
            </section>

            <section className="mb-8">
              <h2 className="text-2xl font-semibold text-secondary-900 dark:text-white mb-4 font-display">4. Partage des Données</h2>
              <p className="text-secondary-700 dark:text-secondary-300 mb-4">Nous partageons vos données uniquement avec :</p>
              <ul className="list-disc list-inside text-secondary-700 dark:text-secondary-300 space-y-2">
                <li><strong>Prestataires de paiement :</strong> CinetPay, Wave, Orange Money, MTN Mobile Money</li>
                <li><strong>Services de notification :</strong> OneSignal pour les notifications push</li>
                <li><strong>Services Google :</strong> Firebase (authentification, base de données), Google Maps pour la localisation</li>
                <li><strong>Partenaires hôteliers :</strong> Pour confirmer vos réservations</li>
              </ul>
              <p className="text-secondary-700 dark:text-secondary-300 mt-4">
                Nous ne vendons jamais vos données personnelles à des tiers.
              </p>
            </section>

            <section className="mb-8">
              <h2 className="text-2xl font-semibold text-secondary-900 dark:text-white mb-4 font-display">5. Sécurité des Données</h2>
              <ul className="list-disc list-inside text-secondary-700 dark:text-secondary-300 space-y-2">
                <li>Chiffrement de toutes les données sensibles</li>
                <li>Authentification sécurisée via Firebase</li>
                <li>Stockage sécurisé des données de paiement</li>
                <li>Accès restreint aux données personnelles</li>
                <li>Surveillance continue de la sécurité</li>
              </ul>
            </section>

            <section className="mb-8">
              <h2 className="text-2xl font-semibold text-secondary-900 dark:text-white mb-4 font-display">6. Vos Droits</h2>
              <p className="text-secondary-700 dark:text-secondary-300 mb-4">Vous avez le droit de :</p>
              <ul className="list-disc list-inside text-secondary-700 dark:text-secondary-300 space-y-2">
                <li>Accéder à vos données personnelles</li>
                <li>Corriger des informations inexactes</li>
                <li>Demander la suppression de vos données</li>
                <li>Vous opposer au traitement de vos données</li>
                <li>Demander la portabilité de vos données</li>
                <li>Retirer votre consentement à tout moment</li>
              </ul>
              <p className="text-secondary-700 dark:text-secondary-300 mt-4">
                Pour exercer ces droits, contactez-nous à <strong>contact@chapechaperesidence.com</strong>
              </p>
            </section>

            <section className="mb-8">
              <h2 className="text-2xl font-semibold text-secondary-900 dark:text-white mb-4 font-display">7. Conservation et Protection des Données</h2>
              <div className="space-y-4">
                <div>
                  <h3 className="text-xl font-medium text-secondary-800 dark:text-secondary-200 font-display mb-2">Durée de conservation</h3>
                  <ul className="list-disc list-inside text-secondary-700 dark:text-secondary-300 space-y-1">
                    <li>Données de compte : jusqu'à suppression du compte + 1 an</li>
                    <li>Données de réservation : 3 ans après la dernière transaction</li>
                    <li>Données de paiement : 5 ans (obligations légales)</li>
                    <li>Logs techniques : 12 mois maximum</li>
                  </ul>
                </div>
                
                <div>
                  <h3 className="text-xl font-medium text-secondary-800 dark:text-secondary-200 font-display mb-2">Protection des données</h3>
                  <ul className="list-disc list-inside text-secondary-700 dark:text-secondary-300 space-y-1">
                    <li><strong>Chiffrement :</strong> Toutes les données sont chiffrées en transit (HTTPS/TLS)</li>
                    <li><strong>Stockage sécurisé :</strong> Firebase avec chiffrement au repos</li>
                    <li><strong>Accès restreint :</strong> Authentification obligatoire et contrôle d'accès</li>
                    <li><strong>Surveillance :</strong> Monitoring continu de la sécurité</li>
                    <li><strong>Sauvegardes :</strong> Sauvegardes chiffrées régulières</li>
                  </ul>
                </div>
              </div>
            </section>

            <section className="mb-8">
              <h2 className="text-2xl font-semibold text-secondary-900 dark:text-white mb-4 font-display">8. Publicité</h2>
              <p className="text-secondary-700 dark:text-secondary-300">
                Nos applications n'utilisent pas l'identifiant publicitaire (AD_ID) et ne diffusent 
                pas de publicité ciblée. Nous ne collectons pas de données à des fins publicitaires.
              </p>
            </section>

            <section className="mb-8">
              <h2 className="text-2xl font-semibold text-secondary-900 dark:text-white mb-4 font-display">9. Modifications</h2>
              <p className="text-secondary-700 dark:text-secondary-300">
                Cette politique peut être mise à jour périodiquement. Nous vous informerons 
                de tout changement significatif via l'application ou par email.
              </p>
            </section>

            <section className="mb-8">
              <h2 className="text-2xl font-semibold text-secondary-900 dark:text-white mb-4 font-display">10. Contact</h2>
              <div className="bg-primary-50 dark:bg-primary-900/20 p-6 rounded-lg">
                <p className="text-secondary-700 dark:text-secondary-300 mb-2">
                  <strong>ChapeChape Residence</strong>
                </p>
                <p className="text-secondary-700 dark:text-secondary-300 mb-2">
                  Email : <a href="mailto:contact@chapechaperesidence.com" className="text-primary-600 hover:underline">contact@chapechaperesidence.com</a>
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

export default PrivacyPolicy
