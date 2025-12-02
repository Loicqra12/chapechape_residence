const mongoose = require('mongoose');
const Role = require('../models/role.model');
const Permission = require('../models/permission.model');
require('dotenv').config();

/**
 * Seed script pour créer les rôles et permissions de base
 * Option A: Données pour interface admin sans migration du système de rôles actuel
 */

// Définition des permissions par module
const PERMISSIONS_DATA = {
  users: [
    { action: 'create', description: 'Créer des utilisateurs' },
    { action: 'read', description: 'Consulter les utilisateurs' },
    { action: 'update', description: 'Modifier les utilisateurs' },
    { action: 'delete', description: 'Supprimer les utilisateurs' },
    { action: 'manage', description: 'Gestion complète des utilisateurs' }
  ],
  partners: [
    { action: 'create', description: 'Créer des partenaires' },
    { action: 'read', description: 'Consulter les partenaires' },
    { action: 'update', description: 'Modifier les partenaires' },
    { action: 'delete', description: 'Supprimer les partenaires' },
    { action: 'manage', description: 'Gestion complète des partenaires' }
  ],
  residences: [
    { action: 'create', description: 'Créer des résidences' },
    { action: 'read', description: 'Consulter les résidences' },
    { action: 'update', description: 'Modifier les résidences' },
    { action: 'delete', description: 'Supprimer les résidences' },
    { action: 'manage', description: 'Gestion complète des résidences' }
  ],
  bookings: [
    { action: 'create', description: 'Créer des réservations' },
    { action: 'read', description: 'Consulter les réservations' },
    { action: 'update', description: 'Modifier les réservations' },
    { action: 'delete', description: 'Supprimer les réservations' },
    { action: 'manage', description: 'Gestion complète des réservations' }
  ],
  payments: [
    { action: 'create', description: 'Créer des paiements' },
    { action: 'read', description: 'Consulter les paiements' },
    { action: 'update', description: 'Modifier les paiements' },
    { action: 'delete', description: 'Supprimer les paiements' },
    { action: 'manage', description: 'Gestion complète des paiements' }
  ],
  reviews: [
    { action: 'create', description: 'Créer des avis' },
    { action: 'read', description: 'Consulter les avis' },
    { action: 'update', description: 'Modifier les avis' },
    { action: 'delete', description: 'Supprimer les avis' }
  ],
  analytics: [
    { action: 'read', description: 'Consulter les statistiques et rapports' }
  ],
  settings: [
    { action: 'manage', description: 'Gérer les paramètres système' }
  ],
  security: [
    { action: 'read', description: 'Consulter les logs de sécurité' },
    { action: 'manage', description: 'Gérer la sécurité du système' }
  ],
  maintenance: [
    { action: 'read', description: 'Consulter l\'état de maintenance' },
    { action: 'manage', description: 'Gérer la maintenance système' }
  ]
};

// Définition des rôles avec leurs permissions
const ROLES_DATA = {
  superadmin: {
    name: 'SuperAdmin',
    description: 'Administrateur suprême avec tous les droits',
    isSystem: true,
    permissionModules: ['users', 'partners', 'residences', 'bookings', 'payments', 'reviews', 'analytics', 'settings', 'security', 'maintenance']
  },
  admin: {
    name: 'Admin',
    description: 'Administrateur avec droits de gestion',
    isSystem: true,
    permissionModules: ['users', 'partners', 'residences', 'bookings', 'payments', 'reviews', 'analytics'],
    excludePermissions: ['settings.manage', 'security.manage', 'maintenance.manage']
  },
  partner: {
    name: 'Partner',
    description: 'Partenaire gérant ses résidences',
    isSystem: true,
    specificPermissions: [
      'residences.manage',
      'bookings.read',
      'bookings.update',
      'payments.read',
      'reviews.read',
      'analytics.read'
    ]
  },
  client: {
    name: 'Client',
    description: 'Client utilisant la plateforme',
    isSystem: true,
    specificPermissions: [
      'bookings.create',
      'bookings.read',
      'bookings.update',
      'payments.read',
      'reviews.create',
      'reviews.read'
    ]
  }
};

const seedRolesAndPermissions = async () => {
  try {
    console.log('🌱 Démarrage du seed des rôles et permissions...\n');

    // Connexion à la base de données
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('✅ Connecté à MongoDB\n');

    // Etape 1: Supprimer les données existantes
    console.log('🗑️  Suppression des rôles et permissions existants...');
    await Role.deleteMany({ isSystem: true });
    await Permission.deleteMany({ isSystem: true });
    console.log('✅ Données existantes supprimées\n');

    // Etape 2: Créer toutes les permissions
    console.log('📝 Création des permissions...');
    const createdPermissions = {};
    let permissionCount = 0;

    for (const [module, permissions] of Object.entries(PERMISSIONS_DATA)) {
      createdPermissions[module] = {};

      for (const permData of permissions) {
        const permission = await Permission.create({
          name: `${module}.${permData.action}`,
          description: permData.description,
          module: module,
          action: permData.action,
          isSystem: true
        });

        createdPermissions[module][permData.action] = permission._id;
        permissionCount++;
        console.log(`  ✓ ${permission.name}`);
      }
    }
    console.log(`✅ ${permissionCount} permissions créées\n`);

    // Etape 3: Créer les rôles avec leurs permissions
    console.log('👥 Création des rôles...');

    for (const [roleKey, roleData] of Object.entries(ROLES_DATA)) {
      const permissionIds = [];

      if (roleData.permissionModules) {
        // Ajouter toutes les permissions des modules spécifiés
        for (const module of roleData.permissionModules) {
          if (createdPermissions[module]) {
            Object.values(createdPermissions[module]).forEach(id => {
              const permName = `${module}.${Object.keys(createdPermissions[module]).find(key => createdPermissions[module][key] === id)}`;
              if (!roleData.excludePermissions || !roleData.excludePermissions.includes(permName)) {
                permissionIds.push(id);
              }
            });
          }
        }
      } else if (roleData.specificPermissions) {
        // Ajouter uniquement les permissions spécifiques
        for (const permName of roleData.specificPermissions) {
          const [module, action] = permName.split('.');
          if (createdPermissions[module] && createdPermissions[module][action]) {
            permissionIds.push(createdPermissions[module][action]);
          }
        }
      }

      const role = await Role.create({
        name: roleData.name,
        description: roleData.description,
        permissions: permissionIds,
        isSystem: roleData.isSystem
      });

      console.log(`  ✓ ${role.name} (${permissionIds.length} permissions)`);
    }
    console.log('✅ 4 rôles créés\n');

    // Résumé
    console.log('═══════════════════════════════════════');
    console.log('🎉 Seed terminé avec succès !');
    console.log('═══════════════════════════════════════');
    console.log(`📊 Résumé:`);
    console.log(`   • ${permissionCount} permissions créées`);
    console.log(`   • 4 rôles système créés`);
    console.log(`   • 10 modules configurés`);
    console.log('═══════════════════════════════════════\n');
    console.log('ℹ️  Note: Ce seed utilise l\'Option A');
    console.log('   Les rôles/permissions sont pour l\'interface admin');
    console.log('   Le système actuel (user.role String) reste inchangé\n');

    process.exit(0);
  } catch (error) {
    console.error('❌ Erreur lors du seed:', error);
    process.exit(1);
  }
};

// Exécuter le seed
seedRolesAndPermissions();
