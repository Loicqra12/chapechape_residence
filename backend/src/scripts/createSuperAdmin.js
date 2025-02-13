const mongoose = require('mongoose');
const User = require('../models/user.model');
require('dotenv').config();

const createSuperAdmin = async () => {
    try {
        // Connexion à la base de données
        await mongoose.connect(process.env.MONGODB_URI);

        // Vérifier si un super admin existe déjà
        const existingSuperAdmin = await User.findOne({ role: 'superadmin' });
        if (existingSuperAdmin) {
            console.log('Un super admin existe déjà :', existingSuperAdmin.email);
            process.exit(0);
        }

        // Créer un nouveau super admin
        const superAdmin = await User.create({
            firstName: 'Super',
            lastName: 'Admin',
            email: 'superadmin@chapechape.com',
            password: 'SuperAdmin@2024',
            phoneNumber: '+22500000000',
            role: 'superadmin',
            isVerified: true
        });

        console.log('Super admin créé avec succès :', superAdmin.email);
        process.exit(0);
    } catch (error) {
        console.error('Erreur lors de la création du super admin :', error);
        process.exit(1);
    }
};

createSuperAdmin();
