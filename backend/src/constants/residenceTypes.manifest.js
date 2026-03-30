/**
 * Types de biens canoniques (alignés sur residence.model.js → type.enum).
 * Utilisé par admin.controller (filtre getAllResidences) pour normaliser ?type=...
 */

const CANONICAL_TYPES = new Set([
  'apartment',
  'house',
  'villa',
  'studio',
  'room',
  'appartement_meuble',
  'studio_meuble',
  'villa_meublee',
  'penthouse',
  'loft',
  'grenier',
  'hotel',
  'hotel_passage',
  'motel',
  'boutique_hotel',
  'hotel_luxe',
  'guest_house',
  'residence_hoteliere',
  'bungalow',
  'lodge',
  'case_traditionnelle',
  'maison_flottante',
  'campement_touristique',
  'chambre_colocation',
  'coliving',
  'maison_hotes',
  'residence_universitaire',
  'cite_dortoir',
  'appartement_vide',
  'villa_vide',
  'immeuble',
  'cour_commune',
  'maison_hotes_economique',
  'residence_familiale',
  'chambres_passage',
  'other',
]);

/** Alias courants → clé canonique */
const ALIASES = {
  appartement: 'apartment',
  maison: 'house',
  chambre: 'room',
};

/**
 * @param {string} raw
 * @returns {string|null} valeur canonique ou null si inconnu
 */
function normalizeResidenceType(raw) {
  if (raw == null || typeof raw !== 'string') return null;
  const s = raw.trim().toLowerCase();
  if (!s) return null;
  if (ALIASES[s]) return ALIASES[s];
  if (CANONICAL_TYPES.has(s)) return s;
  return null;
}

module.exports = {
  normalizeResidenceType,
  CANONICAL_TYPES,
};
