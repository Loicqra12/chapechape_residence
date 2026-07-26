const mongoose = require('mongoose');
const { faker } = require('@faker-js/faker');
const bcrypt = require('bcryptjs');
const User = require('../src/models/user.model');
const Residence = require('../src/models/residence.model');
const Review = require('../src/models/review.model');

require('dotenv').config();

// Configuration
const NUM_USERS = 100;
const NUM_RESIDENCES = 50;
const NUM_REVIEWS = 300;

// Connexion à MongoDB
mongoose.connect(process.env.MONGODB_URI_TEST, {
    useNewUrlParser: true,
    useUnifiedTopology: true
});

// Fonction pour générer un mot de passe hashé
const hashPassword = async (password) => {
    const salt = await bcrypt.genSalt(10);
    return bcrypt.hash(password, salt);
};

// Fonction pour générer des utilisateurs
const generateUsers = async () => {
    console.log('Génération des utilisateurs...');
    const users = [];
    const defaultPassword = await hashPassword('Password123!');

    // Créer un admin
    users.push({
        email: 'admin@test.com',
        password: defaultPassword,
        firstName: 'Admin',
        lastName: 'User',
        role: 'admin',
        phoneNumber: faker.phone.number(),
        isVerified: true
    });

    // Créer des utilisateurs normaux
    for (let i = 0; i < NUM_USERS; i++) {
        users.push({
            email: faker.internet.email(),
            password: defaultPassword,
            firstName: faker.person.firstName(),
            lastName: faker.person.lastName(),
            role: 'user',
            phoneNumber: faker.phone.number(),
            isVerified: true
        });
    }

    await User.insertMany(users);
    console.log(`${users.length} utilisateurs créés`);
    return users;
};

// Fonction pour générer des résidences
const generateResidences = async (users) => {
    console.log('Génération des résidences...');
    const residences = [];
    const cities = ['Paris', 'Lyon', 'Marseille', 'Bordeaux', 'Lille', 'Toulouse', 'Nice', 'Nantes'];
    const amenities = ['WiFi', 'Parking', 'Piscine', 'Climatisation', 'Cuisine équipée', 'Terrasse', 'Vue mer', 'Jardin'];

    for (let i = 0; i < NUM_RESIDENCES; i++) {
        const city = cities[Math.floor(Math.random() * cities.length)];
        residences.push({
            name: `${faker.word.adjective()} ${faker.word.noun()} ${city}`,
            description: faker.lorem.paragraphs(2),
            address: {
                street: faker.location.streetAddress(),
                city: city,
                state: faker.location.state(),
                zipCode: faker.location.zipCode(),
                country: 'France',
                coordinates: {
                    latitude: faker.location.latitude(),
                    longitude: faker.location.longitude()
                }
            },
            price: faker.number.int({ min: 50, max: 500 }),
            capacity: faker.number.int({ min: 1, max: 10 }),
            amenities: faker.helpers.arrayElements(amenities, faker.number.int({ min: 3, max: 8 })),
            images: Array(faker.number.int({ min: 3, max: 6 })).fill().map(() => faker.image.url()),
            owner: users[faker.number.int({ min: 0, max: users.length - 1 })]._id,
            status: 'available',
            rating: faker.number.float({ min: 3.5, max: 5, precision: 0.1 })
        });
    }

    await Residence.insertMany(residences);
    console.log(`${residences.length} résidences créées`);
    return residences;
};

// Fonction pour générer des avis
const generateReviews = async (users, residences) => {
    console.log('Génération des avis...');
    const reviews = [];

    for (let i = 0; i < NUM_REVIEWS; i++) {
        reviews.push({
            residence: residences[faker.number.int({ min: 0, max: residences.length - 1 })]._id,
            user: users[faker.number.int({ min: 0, max: users.length - 1 })]._id,
            rating: faker.number.int({ min: 3, max: 5 }),
            comment: faker.lorem.paragraph(),
            images: Array(faker.number.int({ min: 0, max: 3 })).fill().map(() => faker.image.url())
        });
    }

    await Review.insertMany(reviews);
    console.log(`${reviews.length} avis créés`);
};

// Fonction principale
const generateTestData = async () => {
    try {
        // Nettoyer la base de données
        console.log('Nettoyage de la base de données...');
        await Promise.all([
            User.deleteMany({}),
            Residence.deleteMany({}),
            Review.deleteMany({})
        ]);

        // Générer les données
        // Note: legacy Booking retiré — utiliser Reservation via l'API pour des jeux de données métier
        const users = await generateUsers();
        const residences = await generateResidences(users);
        await generateReviews(users, residences);

        console.log('Génération des données de test terminée avec succès!');
        process.exit(0);
    } catch (error) {
        console.error('Erreur lors de la génération des données:', error);
        process.exit(1);
    }
};

// Exécuter le script
generateTestData();
