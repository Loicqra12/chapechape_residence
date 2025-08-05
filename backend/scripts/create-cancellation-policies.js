const mongoose = require('mongoose');
const CancellationPolicy = require('../src/models/cancellationPolicy.model');
require('dotenv').config();

async function createCancellationPolicies() {
  try {
    // Détecter l'environnement
    const environment = process.env.NODE_ENV || 'development';
    const isProduction = environment === 'production';
    
    console.log(`🔌 Connexion à MongoDB (${environment})...`);
    await mongoose.connect(process.env.MONGODB_URI || process.env.MONGO_URI);
    console.log('✅ Connecté à MongoDB');

    // Vérifier si des politiques existent déjà
    const existingPolicies = await CancellationPolicy.countDocuments();
    
    if (existingPolicies > 0) {
      console.log(`ℹ️  ${existingPolicies} politique(s) déjà existante(s)`);
      console.log('📋 Politiques actuelles:');
      const policies = await CancellationPolicy.find().select('name isDefault');
      policies.forEach(p => console.log(`   - ${p.name} ${p.isDefault ? '(défaut)' : ''}`));
      
      // Demander confirmation en production
      if (isProduction) {
        console.log('⚠️  PRODUCTION: Création annulée pour éviter les doublons');
        console.log('💡 Supprimez manuellement les politiques existantes si besoin');
        await mongoose.disconnect();
        return;
      }
    }

    // Créer un admin ID temporaire (sera remplacé par le vrai admin)
    const tempAdminId = new mongoose.Types.ObjectId();
    
    console.log('📝 Création des politiques d\'annulation...');
    await CancellationPolicy.createDefaultPolicies(tempAdminId);
    
    console.log('✅ Politiques créées avec succès !');
    
    // Afficher les politiques créées
    const newPolicies = await CancellationPolicy.find().select('name isDefault rules');
    console.log(`📋 ${newPolicies.length} politique(s) disponible(s):`);
    
    newPolicies.forEach(policy => {
      console.log(`   📄 ${policy.name} ${policy.isDefault ? '(défaut)' : ''}`);
      console.log(`      └─ ${policy.rules.length} règle(s) d'annulation`);
    });
    
    await mongoose.disconnect();
    console.log('🔌 Déconnecté de MongoDB');
    console.log(`🎉 Script terminé avec succès en mode ${environment}`);
    
  } catch (error) {
    console.error('❌ Erreur:', error.message);
    console.error('🔍 Vérifiez votre configuration MONGO_URI dans .env');
    process.exit(1);
  }
}

// Gestion des arguments de ligne de commande
const args = process.argv.slice(2);
const forceCreate = args.includes('--force');

if (forceCreate) {
  console.log('⚠️  Mode --force activé: création forcée même si des politiques existent');
}

createCancellationPolicies();
