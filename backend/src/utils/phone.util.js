/**
 * Utilitaire de normalisation des numéros de téléphone vers le format E.164
 * Supporte les principaux pays africains et formats locaux
 */

// Mapping des codes pays vers leurs indicatifs téléphoniques
const COUNTRY_CALLING_CODES = {
  // Afrique de l'Ouest
  'CI': '225', // Côte d'Ivoire
  'SN': '221', // Sénégal
  'ML': '223', // Mali
  'BF': '226', // Burkina Faso
  'NE': '227', // Niger
  'GN': '224', // Guinée
  'GH': '233', // Ghana
  'TG': '228', // Togo
  'BJ': '229', // Bénin
  'NG': '234', // Nigeria
  
  // Afrique Centrale
  'CM': '237', // Cameroun
  'GA': '241', // Gabon
  'CG': '242', // Congo
  'CD': '243', // RD Congo
  'CF': '236', // Centrafrique
  'TD': '235', // Tchad
  
  // Afrique du Nord
  'MA': '212', // Maroc
  'DZ': '213', // Algérie
  'TN': '216', // Tunisie
  'EG': '20',  // Égypte
  
  // Afrique de l'Est
  'KE': '254', // Kenya
  'TZ': '255', // Tanzanie
  'UG': '256', // Ouganda
  'ET': '251', // Éthiopie
  
  // Afrique Australe
  'ZA': '27',  // Afrique du Sud
  'ZW': '263', // Zimbabwe
  'BW': '267', // Botswana
  'ZM': '260', // Zambie
  
  // Autres
  'FR': '33',  // France
  'US': '1',   // États-Unis
  'CA': '1',   // Canada
};

// Patterns de nettoyage pour différents formats locaux
const PHONE_PATTERNS = {
  // Supprimer espaces, tirets, points, parenthèses
  cleanup: /[\s\-\.\(\)]/g,
  // Détecter si déjà en format international
  international: /^\+/,
  // Détecter les formats avec indicatif pays sans +
  withCountryCode: /^(225|221|223|226|227|224|233|228|229|234|237|241|242|243|236|235|212|213|216|20|254|255|256|251|27|263|267|260|33|1)/,
  // Formats locaux commençant par 0
  localWithZero: /^0/,
};

/**
 * Normalise un numéro de téléphone vers le format E.164
 * @param {string} phoneNumber - Numéro à normaliser
 * @param {string} countryCode - Code pays ISO (ex: 'CI', 'SN', 'FR')
 * @returns {string} Numéro normalisé en E.164 ou le numéro original si impossible
 */
function normalizePhoneToE164(phoneNumber, countryCode = 'CI') {
  if (!phoneNumber || typeof phoneNumber !== 'string') {
    return phoneNumber;
  }

  // Nettoyer le numéro (supprimer espaces, tirets, etc.)
  let cleaned = phoneNumber.replace(PHONE_PATTERNS.cleanup, '');

  // Si déjà en format international (+...), vérifier et retourner
  if (PHONE_PATTERNS.international.test(cleaned)) {
    // Vérifier que c'est un format valide (+ suivi de chiffres)
    const international = cleaned.replace(/^\+/, '');
    if (/^\d{7,15}$/.test(international)) {
      return cleaned; // Déjà correct
    }
    return phoneNumber; // Format invalide, retourner original
  }

  // Si commence par un indicatif pays sans +, ajouter le +
  if (PHONE_PATTERNS.withCountryCode.test(cleaned)) {
    return `+${cleaned}`;
  }

  // Obtenir l'indicatif du pays
  const callingCode = COUNTRY_CALLING_CODES[countryCode.toUpperCase()];
  if (!callingCode) {
    // Pays non supporté, essayer avec CI par défaut
    return normalizePhoneToE164(phoneNumber, 'CI');
  }

  // Traiter les formats locaux
  if (PHONE_PATTERNS.localWithZero.test(cleaned)) {
    // Format local avec 0 initial (ex: 07 75 75 75 75)
    const withoutZero = cleaned.substring(1);
    if (/^\d{7,10}$/.test(withoutZero)) {
      return `+${callingCode}${withoutZero}`;
    }
  } else if (/^\d{7,10}$/.test(cleaned)) {
    // Format local sans 0 initial (ex: 77 75 75 75)
    return `+${callingCode}${cleaned}`;
  }

  // Si aucun pattern ne correspond, retourner le numéro original
  return phoneNumber;
}

/**
 * Valide qu'un numéro est en format E.164 valide
 * @param {string} phoneNumber - Numéro à valider
 * @returns {boolean} true si valide
 */
function isValidE164(phoneNumber) {
  if (!phoneNumber || typeof phoneNumber !== 'string') {
    return false;
  }
  // Format E.164: + suivi de 7 à 15 chiffres
  return /^\+[1-9]\d{6,14}$/.test(phoneNumber);
}

/**
 * Extrait le code pays d'un numéro E.164
 * @param {string} phoneNumber - Numéro en E.164
 * @returns {string|null} Code pays ou null si non trouvé
 */
function extractCountryFromE164(phoneNumber) {
  if (!isValidE164(phoneNumber)) {
    return null;
  }

  const number = phoneNumber.substring(1); // Enlever le +
  
  // Chercher le code pays le plus long qui correspond
  for (const [country, code] of Object.entries(COUNTRY_CALLING_CODES)) {
    if (number.startsWith(code)) {
      return country;
    }
  }
  
  return null;
}

/**
 * Exemples d'utilisation et tests
 */
function getExamples() {
  return {
    'CI': {
      local: ['07 75 75 75 75', '0775757575', '77 75 75 75', '77757575'],
      expected: '+2250775757575'
    },
    'SN': {
      local: ['07 75 75 75 75', '0775757575', '77 75 75 75', '77757575'],
      expected: '+2210775757575'
    },
    'FR': {
      local: ['06 12 34 56 78', '0612345678', '6 12 34 56 78', '612345678'],
      expected: '+33612345678'
    }
  };
}

module.exports = {
  normalizePhoneToE164,
  isValidE164,
  extractCountryFromE164,
  COUNTRY_CALLING_CODES,
  getExamples
};
