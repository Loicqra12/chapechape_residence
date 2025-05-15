// Script de test pour vérifier la configuration de Brevo
require('dotenv').config();

const Brevo = require('@getbrevo/brevo');

// Afficher la version de la bibliothèque
console.log('Version de la bibliothèque Brevo:', Brevo.VERSION);
console.log('Structure de la bibliothèque Brevo:', Object.keys(Brevo));

// Tenter d'initialiser le client Brevo selon différentes méthodes
try {
  console.log('\n--- Test d\'initialisation ---');
  
  if (Brevo.ApiClient) {
    console.log('ApiClient disponible');
    if (Brevo.ApiClient.instance) {
      console.log('ApiClient.instance disponible');
    } else {
      console.log('ApiClient.instance non disponible');
    }
  } else {
    console.log('ApiClient non disponible');
  }

  if (Brevo.TransactionalEmailsApi) {
    console.log('TransactionalEmailsApi disponible');
    
    try {
      const apiInstance = new Brevo.TransactionalEmailsApi();
      console.log('Instance créée');
      
      // Explorer l'objet pour comprendre sa structure
      console.log('Structure de l\'instance:', Object.keys(apiInstance));
      
      if (apiInstance.authentications) {
        console.log('Authentications disponible:', Object.keys(apiInstance.authentications));
      } else {
        console.log('Authentications non disponible');
      }
    } catch (err) {
      console.error('Erreur lors de la création de l\'instance:', err);
    }
  } else {
    console.log('TransactionalEmailsApi non disponible');
  }
} catch (error) {
  console.error('Erreur lors du test:', error);
}
