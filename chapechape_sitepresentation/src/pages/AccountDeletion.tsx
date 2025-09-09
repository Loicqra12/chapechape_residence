import { motion } from 'framer-motion'

export default function AccountDeletion() {
  return (
    <div className="min-h-screen bg-gradient-to-br from-primary-50 to-secondary-50 py-16">
      <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8">
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.8 }}
          className="bg-white rounded-2xl shadow-xl p-8 md:p-12"
        >
          <h1 className="text-4xl font-bold text-gray-900 mb-8 text-center">
            Suppression du Compte ChapeChape
          </h1>
          
          <div className="prose prose-lg max-w-none">
            <p className="text-gray-600 mb-6">
              <strong>Dernière mise à jour :</strong> 2 septembre 2025
            </p>

            <section className="mb-8">
              <h2 className="text-2xl font-semibold text-gray-900 mb-4">Votre Droit à la Suppression</h2>
              <p className="text-gray-700 leading-relaxed mb-4">
                Conformément au RGPD et à notre engagement pour la protection de vos données, 
                vous avez le droit de demander la suppression complète de votre compte <strong>ChapeChape Client</strong> 
                ou <strong>ChapeChape Partner</strong> et de toutes vos données personnelles de nos systèmes.
              </p>
              <div className="bg-blue-50 p-4 rounded-lg">
                <p className="text-gray-700">
                  <strong>Important :</strong> Cette action est irréversible. Une fois votre compte supprimé, 
                  vous ne pourrez plus accéder à vos réservations passées ni récupérer vos données.
                </p>
              </div>
            </section>

            <section className="mb-8">
              <h2 className="text-2xl font-semibold text-gray-900 mb-4">Données Concernées par la Suppression</h2>
              <div className="space-y-4">
                <div>
                  <h3 className="text-xl font-medium text-gray-800 mb-2">Données supprimées définitivement</h3>
                  <ul className="list-disc list-inside text-gray-700 space-y-1">
                    <li>Informations de profil (nom, email, téléphone)</li>
                    <li>Préférences et paramètres de l'application</li>
                    <li>Historique de navigation et d'utilisation</li>
                    <li>Photos de profil et documents uploadés</li>
                    <li>Identifiants de notification push</li>
                    <li>Données de géolocalisation</li>
                  </ul>
                </div>
                
                <div>
                  <h3 className="text-xl font-medium text-gray-800 mb-2">Données conservées temporairement</h3>
                  <ul className="list-disc list-inside text-gray-700 space-y-1">
                    <li><strong>Réservations :</strong> 3 ans (obligations légales et comptables)</li>
                    <li><strong>Transactions :</strong> 5 ans (obligations fiscales)</li>
                    <li><strong>Logs de sécurité :</strong> 12 mois maximum</li>
                  </ul>
                  <p className="text-sm text-gray-600 mt-2 italic">
                    Ces données sont anonymisées (votre identité est supprimée) et conservées 
                    uniquement pour respecter nos obligations légales.
                  </p>
                </div>
              </div>
            </section>

            <section className="mb-8">
              <h2 className="text-2xl font-semibold text-gray-900 mb-4">Comment Supprimer Votre Compte</h2>
              
              <div className="space-y-6">
                <div>
                  <h3 className="text-xl font-medium text-gray-800 mb-3">Méthode 1 : Depuis l'Application</h3>
                  <div className="bg-gray-50 p-4 rounded-lg">
                    <ol className="list-decimal list-inside text-gray-700 space-y-2">
                      <li>Ouvrez l'application ChapeChape Client ou Partner</li>
                      <li>Allez dans <strong>Paramètres</strong> → <strong>Mon Compte</strong></li>
                      <li>Sélectionnez <strong>"Supprimer mon compte"</strong></li>
                      <li>Confirmez votre identité (mot de passe ou biométrie)</li>
                      <li>Lisez les informations et confirmez la suppression</li>
                    </ol>
                  </div>
                </div>

                <div>
                  <h3 className="text-xl font-medium text-gray-800 mb-3">Méthode 2 : Par Email</h3>
                  <div className="bg-gray-50 p-4 rounded-lg">
                    <p className="text-gray-700 mb-3">
                      Envoyez un email à <strong>contact@chapechaperesidence.com</strong> avec :
                    </p>
                    <ul className="list-disc list-inside text-gray-700 space-y-1">
                      <li>Objet : "Demande de suppression de compte"</li>
                      <li>Votre nom complet</li>
                      <li>Adresse email associée au compte</li>
                      <li>Numéro de téléphone (si applicable)</li>
                      <li>Confirmation : "Je demande la suppression définitive de mon compte"</li>
                    </ul>
                  </div>
                </div>
              </div>
            </section>

            <section className="mb-8">
              <h2 className="text-2xl font-semibold text-gray-900 mb-4">Délais de Traitement</h2>
              <div className="grid md:grid-cols-2 gap-6">
                <div className="bg-green-50 p-4 rounded-lg">
                  <h3 className="text-lg font-medium text-green-800 mb-2">Suppression Immédiate</h3>
                  <ul className="text-green-700 text-sm space-y-1">
                    <li>• Accès à l'application bloqué</li>
                    <li>• Profil et préférences supprimés</li>
                    <li>• Notifications désactivées</li>
                  </ul>
                </div>
                <div className="bg-blue-50 p-4 rounded-lg">
                  <h3 className="text-lg font-medium text-blue-800 mb-2">Suppression Complète</h3>
                  <ul className="text-blue-700 text-sm space-y-1">
                    <li>• Toutes les données : 30 jours maximum</li>
                    <li>• Sauvegardes système : 90 jours</li>
                    <li>• Confirmation par email</li>
                  </ul>
                </div>
              </div>
            </section>

            <section className="mb-8">
              <h2 className="text-2xl font-semibold text-gray-900 mb-4">Conséquences de la Suppression</h2>
              <div className="bg-red-50 p-6 rounded-lg border-l-4 border-red-400">
                <h3 className="text-lg font-medium text-red-800 mb-3">⚠️ Attention : Actions Irréversibles</h3>
                <ul className="text-red-700 space-y-2">
                  <li>• <strong>Perte d'accès :</strong> Impossible de vous connecter aux applications</li>
                  <li>• <strong>Réservations futures :</strong> Annulées automatiquement</li>
                  <li>• <strong>Historique :</strong> Plus d'accès à vos réservations passées</li>
                  <li>• <strong>Points/Récompenses :</strong> Perdus définitivement</li>
                  <li>• <strong>Nouveau compte :</strong> Devra être recréé depuis zéro</li>
                </ul>
              </div>
            </section>

            <section className="mb-8">
              <h2 className="text-2xl font-semibold text-gray-900 mb-4">Alternatives à la Suppression</h2>
              <div className="space-y-4">
                <div>
                  <h3 className="text-xl font-medium text-gray-800 mb-2">Désactivation temporaire</h3>
                  <p className="text-gray-700">
                    Vous pouvez désactiver votre compte temporairement tout en conservant vos données 
                    pour une réactivation future.
                  </p>
                </div>
                <div>
                  <h3 className="text-xl font-medium text-gray-800 mb-2">Modification des données</h3>
                  <p className="text-gray-700">
                    Si vous souhaitez corriger ou mettre à jour vos informations, contactez notre support 
                    avant de supprimer votre compte.
                  </p>
                </div>
                <div>
                  <h3 className="text-xl font-medium text-gray-800 mb-2">Gestion de la confidentialité</h3>
                  <p className="text-gray-700">
                    Vous pouvez ajuster vos paramètres de confidentialité et notifications sans supprimer 
                    votre compte.
                  </p>
                </div>
              </div>
            </section>

            <section className="mb-8">
              <h2 className="text-2xl font-semibold text-gray-900 mb-4">Support et Assistance</h2>
              <div className="bg-blue-50 p-6 rounded-lg">
                <p className="text-gray-700 mb-4">
                  <strong>Besoin d'aide ?</strong> Notre équipe est disponible pour vous accompagner :
                </p>
                <div className="space-y-2">
                  <p className="text-gray-700">
                    <strong>Email :</strong> <a href="mailto:contact@chapechaperesidence.com" className="text-blue-600 hover:underline">contact@chapechaperesidence.com</a>
                  </p>
                  <p className="text-gray-700">
                    <strong>Support :</strong> <a href="mailto:support@chapechaperesidence.com" className="text-blue-600 hover:underline">support@chapechaperesidence.com</a>
                  </p>
                  <p className="text-gray-700">
                    <strong>Délai de réponse :</strong> 48h maximum
                  </p>
                </div>
              </div>
            </section>

            <section className="mb-8">
              <h2 className="text-2xl font-semibold text-gray-900 mb-4">Vos Droits RGPD</h2>
              <p className="text-gray-700 mb-4">
                En plus du droit à la suppression, vous disposez également de :
              </p>
              <ul className="list-disc list-inside text-gray-700 space-y-1">
                <li>Droit d'accès à vos données</li>
                <li>Droit de rectification</li>
                <li>Droit à la portabilité</li>
                <li>Droit d'opposition au traitement</li>
                <li>Droit de limitation du traitement</li>
              </ul>
              <p className="text-gray-700 mt-4">
                Pour exercer ces droits, contactez-nous à <strong>contact@chapechaperesidence.com</strong>
              </p>
            </section>
          </div>
        </motion.div>
      </div>
    </div>
  )
}
