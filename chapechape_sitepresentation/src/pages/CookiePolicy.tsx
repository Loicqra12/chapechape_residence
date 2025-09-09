import { motion } from 'framer-motion'

export default function CookiePolicy() {
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
            Politique de Cookies
          </h1>
          
          <div className="prose prose-lg max-w-none">
            <p className="text-gray-600 mb-6">
              <strong>Dernière mise à jour :</strong> 2 septembre 2025
            </p>

            <section className="mb-8">
              <h2 className="text-2xl font-semibold text-gray-900 mb-4">Qu'est-ce qu'un Cookie ?</h2>
              <p className="text-gray-700 leading-relaxed mb-4">
                Un cookie est un petit fichier texte stocké sur votre appareil (ordinateur, tablette, smartphone) 
                lorsque vous visitez notre site web <strong>presentation.chapechaperesidence.com</strong>. 
                Les cookies nous aident à améliorer votre expérience de navigation.
              </p>
              <div className="bg-blue-50 p-4 rounded-lg">
                <p className="text-gray-700">
                  <strong>Note :</strong> Nos applications mobiles ChapeChape Client et Partner n'utilisent pas 
                  de cookies traditionnels, mais peuvent stocker des données localement pour leur fonctionnement.
                </p>
              </div>
            </section>

            <section className="mb-8">
              <h2 className="text-2xl font-semibold text-gray-900 mb-4">Types de Cookies Utilisés</h2>
              
              <div className="space-y-6">
                <div className="border-l-4 border-green-400 pl-4">
                  <h3 className="text-xl font-medium text-gray-800 mb-2">🔧 Cookies Essentiels</h3>
                  <p className="text-gray-700 mb-2">
                    <strong>Nécessaires au fonctionnement du site</strong> - Ne peuvent pas être désactivés
                  </p>
                  <ul className="list-disc list-inside text-gray-700 space-y-1 text-sm">
                    <li>Gestion des sessions utilisateur</li>
                    <li>Sécurité et prévention des attaques</li>
                    <li>Préférences de langue</li>
                    <li>Fonctionnalités de base du site</li>
                  </ul>
                </div>

                <div className="border-l-4 border-blue-400 pl-4">
                  <h3 className="text-xl font-medium text-gray-800 mb-2">📊 Cookies Analytiques</h3>
                  <p className="text-gray-700 mb-2">
                    <strong>Google Analytics</strong> - Nous aident à comprendre l'utilisation du site
                  </p>
                  <ul className="list-disc list-inside text-gray-700 space-y-1 text-sm">
                    <li>Nombre de visiteurs et pages vues</li>
                    <li>Durée des sessions</li>
                    <li>Sources de trafic</li>
                    <li>Comportement de navigation (anonymisé)</li>
                  </ul>
                  <p className="text-xs text-gray-600 mt-2 italic">
                    Ces données sont anonymisées et ne permettent pas de vous identifier personnellement.
                  </p>
                </div>

                <div className="border-l-4 border-purple-400 pl-4">
                  <h3 className="text-xl font-medium text-gray-800 mb-2">⚙️ Cookies Fonctionnels</h3>
                  <p className="text-gray-700 mb-2">
                    <strong>Amélioration de l'expérience utilisateur</strong>
                  </p>
                  <ul className="list-disc list-inside text-gray-700 space-y-1 text-sm">
                    <li>Mémorisation de vos préférences</li>
                    <li>Personnalisation de l'interface</li>
                    <li>Géolocalisation approximative (avec votre accord)</li>
                  </ul>
                </div>

                <div className="border-l-4 border-red-400 pl-4">
                  <h3 className="text-xl font-medium text-gray-800 mb-2">🚫 Cookies que Nous N'utilisons PAS</h3>
                  <ul className="list-disc list-inside text-gray-700 space-y-1 text-sm">
                    <li><strong>Cookies publicitaires :</strong> Aucun tracking publicitaire</li>
                    <li><strong>Cookies de réseaux sociaux :</strong> Pas de boutons de partage avec tracking</li>
                    <li><strong>Cookies de profilage :</strong> Aucun profil comportemental créé</li>
                  </ul>
                </div>
              </div>
            </section>

            <section className="mb-8">
              <h2 className="text-2xl font-semibold text-gray-900 mb-4">Gestion de Vos Cookies</h2>
              
              <div className="space-y-6">
                <div>
                  <h3 className="text-xl font-medium text-gray-800 mb-3">🎛️ Panneau de Contrôle des Cookies</h3>
                  <div className="bg-gray-50 p-4 rounded-lg">
                    <p className="text-gray-700 mb-3">
                      Lors de votre première visite, une bannière vous permet de choisir :
                    </p>
                    <div className="grid md:grid-cols-2 gap-4">
                      <button className="bg-green-600 text-white px-4 py-2 rounded text-sm font-medium">
                        ✅ Accepter tous les cookies
                      </button>
                      <button className="bg-gray-600 text-white px-4 py-2 rounded text-sm font-medium">
                        ⚙️ Personnaliser mes choix
                      </button>
                    </div>
                    <p className="text-xs text-gray-600 mt-3">
                      Vous pouvez modifier vos préférences à tout moment en cliquant sur "Gérer les cookies" 
                      en bas de page.
                    </p>
                  </div>
                </div>

                <div>
                  <h3 className="text-xl font-medium text-gray-800 mb-3">🌐 Paramètres du Navigateur</h3>
                  <div className="space-y-3">
                    <div className="bg-gray-50 p-3 rounded">
                      <strong className="text-gray-800">Chrome :</strong>
                      <span className="text-gray-700 text-sm ml-2">
                        Paramètres → Confidentialité et sécurité → Cookies
                      </span>
                    </div>
                    <div className="bg-gray-50 p-3 rounded">
                      <strong className="text-gray-800">Firefox :</strong>
                      <span className="text-gray-700 text-sm ml-2">
                        Paramètres → Vie privée et sécurité → Cookies
                      </span>
                    </div>
                    <div className="bg-gray-50 p-3 rounded">
                      <strong className="text-gray-800">Safari :</strong>
                      <span className="text-gray-700 text-sm ml-2">
                        Préférences → Confidentialité → Cookies
                      </span>
                    </div>
                  </div>
                </div>
              </div>
            </section>

            <section className="mb-8">
              <h2 className="text-2xl font-semibold text-gray-900 mb-4">Cookies Tiers</h2>
              
              <div className="space-y-4">
                <div>
                  <h3 className="text-xl font-medium text-gray-800 mb-2">Google Analytics</h3>
                  <div className="bg-blue-50 p-4 rounded-lg">
                    <p className="text-gray-700 mb-2">
                      <strong>Finalité :</strong> Analyse du trafic et amélioration du site
                    </p>
                    <p className="text-gray-700 mb-2">
                      <strong>Durée :</strong> 24 mois maximum
                    </p>
                    <p className="text-gray-700 mb-2">
                      <strong>Données :</strong> Pages visitées, durée, appareil (anonymisé)
                    </p>
                    <p className="text-gray-700 text-sm">
                      <strong>Opt-out :</strong> 
                      <a href="https://tools.google.com/dlpage/gaoptout" target="_blank" rel="noopener noreferrer" className="text-blue-600 hover:underline ml-1">
                        Extension Google Analytics Opt-out
                      </a>
                    </p>
                  </div>
                </div>

                <div>
                  <h3 className="text-xl font-medium text-gray-800 mb-2">Hébergement et CDN</h3>
                  <div className="bg-gray-50 p-4 rounded-lg">
                    <p className="text-gray-700 mb-2">
                      <strong>Finalité :</strong> Performance et sécurité du site
                    </p>
                    <p className="text-gray-700 mb-2">
                      <strong>Données :</strong> Adresse IP, géolocalisation approximative
                    </p>
                    <p className="text-gray-700 text-sm">
                      Ces cookies sont essentiels au fonctionnement du site et ne peuvent pas être désactivés.
                    </p>
                  </div>
                </div>
              </div>
            </section>

            <section className="mb-8">
              <h2 className="text-2xl font-semibold text-gray-900 mb-4">Durée de Conservation</h2>
              
              <div className="overflow-x-auto">
                <table className="min-w-full bg-white border border-gray-200 rounded-lg">
                  <thead className="bg-gray-50">
                    <tr>
                      <th className="px-4 py-3 text-left text-sm font-medium text-gray-900">Type de Cookie</th>
                      <th className="px-4 py-3 text-left text-sm font-medium text-gray-900">Durée</th>
                      <th className="px-4 py-3 text-left text-sm font-medium text-gray-900">Suppression</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-gray-200">
                    <tr>
                      <td className="px-4 py-3 text-sm text-gray-700">Cookies de session</td>
                      <td className="px-4 py-3 text-sm text-gray-700">Fin de session</td>
                      <td className="px-4 py-3 text-sm text-gray-700">Automatique</td>
                    </tr>
                    <tr>
                      <td className="px-4 py-3 text-sm text-gray-700">Cookies fonctionnels</td>
                      <td className="px-4 py-3 text-sm text-gray-700">12 mois</td>
                      <td className="px-4 py-3 text-sm text-gray-700">Automatique ou manuelle</td>
                    </tr>
                    <tr>
                      <td className="px-4 py-3 text-sm text-gray-700">Google Analytics</td>
                      <td className="px-4 py-3 text-sm text-gray-700">24 mois</td>
                      <td className="px-4 py-3 text-sm text-gray-700">Paramètres navigateur</td>
                    </tr>
                  </tbody>
                </table>
              </div>
            </section>

            <section className="mb-8">
              <h2 className="text-2xl font-semibold text-gray-900 mb-4">Vos Droits</h2>
              
              <div className="bg-green-50 p-6 rounded-lg">
                <h3 className="text-lg font-medium text-green-800 mb-3">✅ Vous avez le droit de :</h3>
                <ul className="list-disc list-inside text-green-700 space-y-2">
                  <li>Accepter ou refuser les cookies non essentiels</li>
                  <li>Modifier vos préférences à tout moment</li>
                  <li>Supprimer les cookies existants</li>
                  <li>Être informé de l'utilisation des cookies</li>
                  <li>Accéder aux données collectées via les cookies</li>
                </ul>
              </div>
            </section>

            <section className="mb-8">
              <h2 className="text-2xl font-semibold text-gray-900 mb-4">Impact du Refus des Cookies</h2>
              
              <div className="grid md:grid-cols-2 gap-6">
                <div className="bg-red-50 p-4 rounded-lg">
                  <h3 className="text-lg font-medium text-red-800 mb-2">❌ Cookies Refusés</h3>
                  <ul className="text-red-700 text-sm space-y-1">
                    <li>• Pas de statistiques de visite</li>
                    <li>• Préférences non mémorisées</li>
                    <li>• Expérience moins personnalisée</li>
                  </ul>
                </div>
                <div className="bg-green-50 p-4 rounded-lg">
                  <h3 className="text-lg font-medium text-green-800 mb-2">✅ Fonctionnalités Préservées</h3>
                  <ul className="text-green-700 text-sm space-y-1">
                    <li>• Navigation normale du site</li>
                    <li>• Accès à toutes les informations</li>
                    <li>• Téléchargement des applications</li>
                  </ul>
                </div>
              </div>
            </section>

            <section className="mb-8">
              <h2 className="text-2xl font-semibold text-gray-900 mb-4">Modifications de cette Politique</h2>
              <p className="text-gray-700 mb-4">
                Nous pouvons mettre à jour cette Politique de Cookies pour refléter les changements 
                dans nos pratiques ou pour des raisons légales. Les modifications importantes seront 
                notifiées via une bannière sur le site.
              </p>
              <p className="text-gray-700">
                Nous vous encourageons à consulter régulièrement cette page pour rester informé 
                de nos pratiques en matière de cookies.
              </p>
            </section>

            <section className="mb-8">
              <h2 className="text-2xl font-semibold text-gray-900 mb-4">Contact et Questions</h2>
              <div className="bg-blue-50 p-6 rounded-lg">
                <p className="text-gray-700 mb-4">
                  <strong>Des questions sur notre utilisation des cookies ?</strong>
                </p>
                <div className="space-y-2">
                  <p className="text-gray-700">
                    <strong>Email :</strong> <a href="mailto:contact@chapechaperesidence.com" className="text-blue-600 hover:underline">contact@chapechaperesidence.com</a>
                  </p>
                  <p className="text-gray-700">
                    <strong>Support :</strong> <a href="mailto:support@chapechaperesidence.com" className="text-blue-600 hover:underline">support@chapechaperesidence.com</a>
                  </p>
                  <p className="text-gray-700">
                    <strong>Site web :</strong> <a href="https://presentation.chapechaperesidence.com" className="text-blue-600 hover:underline">presentation.chapechaperesidence.com</a>
                  </p>
                </div>
              </div>
            </section>

            {/* Bouton de gestion des cookies */}
            <div className="text-center mt-12">
              <button 
                className="bg-primary-600 hover:bg-primary-700 text-white font-medium py-3 px-6 rounded-lg transition-colors duration-200"
                onClick={() => {
                  // Cette fonction devra être implémentée côté frontend
                  console.log('Ouvrir le panneau de gestion des cookies');
                }}
              >
                🍪 Gérer mes Préférences de Cookies
              </button>
            </div>
          </div>
        </motion.div>
      </div>
    </div>
  )
}
