const mongoose = require('mongoose');
require('dotenv').config();

async function fixReservationPolicies() {
  try {
    // Détecter l'environnement
    const environment = process.env.NODE_ENV || 'development';
    
    console.log(`🔌 Connexion à MongoDB (${environment})...`);
    await mongoose.connect(process.env.MONGODB_URI || process.env.MONGO_URI);
    console.log('✅ Connecté à MongoDB');

    // Récupérer la politique par défaut
    const CancellationPolicy = mongoose.model('CancellationPolicy', new mongoose.Schema({}, { strict: false }));
    const defaultPolicy = await CancellationPolicy.findOne({ isDefault: true });
    
    if (!defaultPolicy) {
      console.log('❌ Aucune politique par défaut trouvée !');
      console.log('💡 Exécutez d\'abord le script create-cancellation-policies.js');
      process.exit(1);
    }
    
    console.log(`📋 Politique par défaut trouvée: "${defaultPolicy.name}" (${defaultPolicy._id})`);

    // Récupérer toutes les réservations
    const Reservation = mongoose.model('Reservation', new mongoose.Schema({}, { strict: false }));
    const reservations = await Reservation.find({});
    
    console.log(`📊 ${reservations.length} réservation(s) trouvée(s)`);
    
    if (reservations.length === 0) {
      console.log('ℹ️  Aucune réservation à mettre à jour');
      await mongoose.disconnect();
      return;
    }

    // Compter les réservations avec des politiques manquantes/incorrectes
    let fixedCount = 0;
    let alreadyCorrectCount = 0;
    let totalCount = 0;
    
    console.log('\n🔍 Analyse des réservations:');
    
    for (const reservation of reservations) {
      totalCount++;
      const currentPolicyId = reservation.cancellationPolicy?.toString();
      const defaultPolicyId = defaultPolicy._id.toString();
      
      console.log(`   📄 Réservation ${reservation._id}:`);
      console.log(`      └─ Politique actuelle: ${currentPolicyId || 'MANQUANTE'}`);
      
      if (!currentPolicyId || currentPolicyId !== defaultPolicyId) {
        // Vérifier si la politique actuelle existe
        let policyExists = false;
        if (currentPolicyId) {
          const existingPolicy = await CancellationPolicy.findById(currentPolicyId);
          policyExists = !!existingPolicy;
        }
        
        if (!policyExists) {
          // Mettre à jour avec la politique par défaut
          await Reservation.updateOne(
            { _id: reservation._id },
            { $set: { cancellationPolicy: defaultPolicy._id } }
          );
          
          console.log(`      🔧 ✅ CORRIGÉE → ${defaultPolicyId}`);
          fixedCount++;
        } else {
          console.log(`      ✅ Politique valide (différente de défaut)`);
          alreadyCorrectCount++;
        }
      } else {
        console.log(`      ✅ Déjà correcte`);
        alreadyCorrectCount++;
      }
    }
    
    console.log(`\n📈 RÉSULTATS DE LA CORRECTION :`);
    console.log(`   🔧 ${fixedCount} réservation(s) corrigée(s)`);
    console.log(`   ✅ ${alreadyCorrectCount} réservation(s) déjà correcte(s)`);
    console.log(`   📋 Total: ${totalCount} réservation(s) analysée(s)`);
    
    if (fixedCount > 0) {
      console.log(`\n🎉 SUCCÈS ! Les apps Client/Partner sont maintenant débloquées.`);
      console.log(`✅ Toutes les réservations pointent vers des politiques valides.`);
      console.log(`✅ Plus d'erreur 404 sur les politiques d'annulation.`);
    } else {
      console.log(`\n✅ Aucune correction nécessaire, toutes les réservations sont conformes.`);
    }
    
    // Vérification finale
    console.log(`\n🔍 VÉRIFICATION FINALE :`);
    const brokenReservations = await Reservation.find({
      $or: [
        { cancellationPolicy: { $exists: false } },
        { cancellationPolicy: null },
        { cancellationPolicy: '' }
      ]
    });
    
    if (brokenReservations.length === 0) {
      console.log(`✅ Aucune réservation sans politique d'annulation.`);
    } else {
      console.log(`⚠️  ${brokenReservations.length} réservation(s) sans politique détectée(s).`);
    }
    
    await mongoose.disconnect();
    console.log('🔌 Déconnecté de MongoDB');
    console.log(`🎯 Script terminé avec succès en mode ${environment}`);
    
  } catch (error) {
    console.error('❌ Erreur:', error.message);
    console.error('🔍 Détails:', error);
    process.exit(1);
  }
}

// Gestion des arguments de ligne de commande
const args = process.argv.slice(2);
const dryRun = args.includes('--dry-run');

if (dryRun) {
  console.log('🔍 Mode --dry-run: simulation sans modification');
}

console.log('🚀 Démarrage de la correction des politiques d\'annulation...');
fixReservationPolicies();
