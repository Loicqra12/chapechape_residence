const password = (value, helpers) => {
    if (value.length < 8) {
        return helpers.message('Le mot de passe doit contenir au moins 8 caractères');
    }
    if (!value.match(/\d/)) {
        return helpers.message('Le mot de passe doit contenir au moins un chiffre');
    }
    if (!value.match(/[a-zA-Z]/)) {
        return helpers.message('Le mot de passe doit contenir au moins une lettre');
    }
    if (!value.match(/[A-Z]/)) {
        return helpers.message('Le mot de passe doit contenir au moins une majuscule');
    }
    if (!value.match(/[!@#$%^&*(),.?":{}|<>]/)) {
        return helpers.message('Le mot de passe doit contenir au moins un caractère spécial');
    }
    return value;
};

const objectId = (value, helpers) => {
    if (!value.match(/^[0-9a-fA-F]{24}$/)) {
        return helpers.message('ID invalide');
    }
    return value;
};

const phoneNumber = (value, helpers) => {
    if (!value.match(/^\+?[1-9]\d{1,14}$/)) {
        return helpers.message('Numéro de téléphone invalide');
    }
    return value;
};

module.exports = {
    password,
    objectId,
    phoneNumber
};
