// Fonction pour formater les dates
const formatDate = (date) => {
    return new Date(date).toLocaleDateString('fr-FR', {
        year: 'numeric',
        month: 'long',
        day: 'numeric'
    });
};

// Fonction pour calculer le nombre de jours entre deux dates
const calculateDays = (startDate, endDate) => {
    const start = new Date(startDate);
    const end = new Date(endDate);
    const diffTime = Math.abs(end - start);
    return Math.ceil(diffTime / (1000 * 60 * 60 * 24));
};

// Fonction pour calculer le prix total
const calculateTotalPrice = (pricePerNight, startDate, endDate) => {
    const days = calculateDays(startDate, endDate);
    return days * pricePerNight;
};

// Fonction pour générer un numéro de référence unique
const generateReference = (prefix = 'REF') => {
    const timestamp = Date.now().toString();
    const random = Math.random().toString(36).substring(2, 8).toUpperCase();
    return `${prefix}-${timestamp.slice(-6)}${random}`;
};

// Fonction pour paginer les résultats
const paginate = (query, page = 1, limit = 10) => {
    const skip = (page - 1) * limit;
    return query.skip(skip).limit(limit);
};

// Fonction pour filtrer les champs sensibles
const filterSensitiveData = (obj, fieldsToRemove = ['password', '__v']) => {
    const filtered = { ...obj };
    fieldsToRemove.forEach(field => delete filtered[field]);
    return filtered;
};

// Fonction pour formater les erreurs
const formatError = (error) => {
    if (error.name === 'ValidationError') {
        return Object.values(error.errors).map(err => err.message);
    }
    return [error.message];
};

// Fonction pour vérifier si une date est dans le futur
const isFutureDate = (date) => {
    return new Date(date) > new Date();
};

// Fonction pour formater le prix
const formatPrice = (price, currency = 'FCFA') => {
    const locale = currency === 'USD' ? 'en-US' : 'fr-FR';
    
    // Ajuster les décimales selon la devise
    let decimalPlaces = 0;
    if (currency !== 'FCFA') {
        decimalPlaces = 2;
    }
    
    return new Intl.NumberFormat(locale, {
        style: 'currency',
        currency,
        minimumFractionDigits: decimalPlaces,
        maximumFractionDigits: decimalPlaces
    }).format(price);
};

// Conversion de prix entre différentes devises
const convertPrice = (amount, fromCurrency, toCurrency) => {
    // Table de conversion (devrait idéalement venir d'une API)
    const rates = {
        'EUR': 1.0,      // Base: Euro
        'FCFA': 655.957, // 1 EUR = 655.957 FCFA (taux fixe)
        'USD': 1.09,     // Exemple: 1 EUR = 1.09 USD
        'GBP': 0.85,     // Exemple: 1 EUR = 0.85 GBP
    };
    
    // Si les devises sont identiques ou non supportées
    if (fromCurrency === toCurrency ||
        !rates[fromCurrency] ||
        !rates[toCurrency]) {
        return amount;
    }
    
    // Convertir par rapport à l'euro
    const amountInEUR = amount / rates[fromCurrency];
    return amountInEUR * rates[toCurrency];
};

// Fonction pour générer un slug
const generateSlug = (text) => {
    return text
        .toString()
        .toLowerCase()
        .replace(/\s+/g, '-')
        .replace(/[^\w\-]+/g, '')
        .replace(/\-\-+/g, '-')
        .replace(/^-+/, '')
        .replace(/-+$/, '');
};

// Fonction pour tronquer un texte
const truncateText = (text, length = 100) => {
    if (text.length <= length) return text;
    return text.substring(0, length) + '...';
};

// Fonction pour valider un numéro de téléphone
const isValidPhoneNumber = (phone) => {
    const phoneRegex = /^[0-9+\s-]{8,}$/;
    return phoneRegex.test(phone);
};

// Fonction pour valider une adresse email
const isValidEmail = (email) => {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return emailRegex.test(email);
};

// Fonction pour générer un mot de passe aléatoire
const generateRandomPassword = (length = 12) => {
    const charset = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*';
    let password = '';
    for (let i = 0; i < length; i++) {
        password += charset.charAt(Math.floor(Math.random() * charset.length));
    }
    return password;
};

// Fonction pour calculer la moyenne des notes
const calculateAverageRating = (ratings) => {
    if (!ratings.length) return 0;
    const sum = ratings.reduce((acc, rating) => acc + rating, 0);
    return (sum / ratings.length).toFixed(1);
};

module.exports = {
    formatDate,
    calculateDays,
    calculateTotalPrice,
    generateReference,
    paginate,
    filterSensitiveData,
    formatError,
    isFutureDate,
    formatPrice,
    convertPrice,
    generateSlug,
    truncateText,
    isValidPhoneNumber,
    isValidEmail,
    generateRandomPassword,
    calculateAverageRating
};
