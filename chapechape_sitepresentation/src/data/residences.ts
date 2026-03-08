/**
 * Catégories d'hébergement alignées sur l'app ChapeChape Residence.
 * 6 catégories, 28 types au total — du économique au confort, court ou longue durée.
 */
export interface ResidenceType {
  id: string;
  name: string;
  description: string;
  features: string[];
  imageUrl: string;
}

export const residenceTypes: ResidenceType[] = [
  {
    id: 'meuble',
    name: 'Résidences meublées',
    description: 'Studios, appartements et villas meublés, penthouse, loft ou grenier aménagé : des espaces prêts à vivre pour courts ou longs séjours.',
    features: [
      'Studio, appartement ou villa meublé',
      'Penthouse, loft, grenier aménagé',
      'Idéal court ou longue durée',
      'Équipements inclus'
    ],
    imageUrl: '/assets/residences/meuble.png'
  },
  {
    id: 'hotel',
    name: 'Hôtels & hébergements classiques',
    description: 'Hôtels de passage, motels, boutique-hôtels, hôtels de luxe, auberges et résidences hôtelières pour tous les besoins en hébergement.',
    features: [
      'Hôtel de passage, motel, boutique-hôtel',
      'Hôtel de luxe, auberge, résidence hôtelière',
      'Services adaptés à chaque formule',
      'Réservation à l\'heure, au jour ou au mois'
    ],
    imageUrl: '/assets/residences/hotel.png'
  },
  {
    id: 'insolite',
    name: 'Hébergements insolites & nature',
    description: 'Bungalows, lodges, cases traditionnelles, maisons flottantes ou campements : pour des séjours hors du commun en pleine nature.',
    features: [
      'Bungalow, lodge & écolodge',
      'Case traditionnelle, maison flottante',
      'Campement touristique',
      'Expérience nature et authenticité'
    ],
    imageUrl: '/assets/residences/insolite.png'
  },
  {
    id: 'colocation',
    name: 'Colocation & résidences partagées',
    description: 'Chambres en colocation, coliving, maisons d\'hôtes, résidences universitaires et cités dortoir : pour vivre à plusieurs ou en communauté.',
    features: [
      'Chambre en colocation, coliving',
      'Maison d\'hôtes, résidence universitaire',
      'Cité & dortoir',
      'Idéal étudiants et travailleurs'
    ],
    imageUrl: '/assets/residences/colocation.png'
  },
  {
    id: 'longue_duree',
    name: 'Résidences longue durée',
    description: 'Appartements et villas non meublés, immeubles et cours communes : pour des locations longue durée et une installation durable.',
    features: [
      'Appartement ou villa non meublé',
      'Immeuble, cour commune',
      'Location longue durée',
      'Adapté aux familles et professionnels'
    ],
    imageUrl: '/assets/residences/longue_duree.png'
  },
  {
    id: 'economique',
    name: 'Hébergements économiques',
    description: 'Maisons d\'hôtes économiques, résidences familiales et chambres de passage : des options accessibles pour petits budgets et séjours courts.',
    features: [
      'Maison d\'hôtes économique',
      'Résidence familiale, chambres de passage',
      'Tarifs accessibles',
      'Confort simple et pratique'
    ],
    imageUrl: '/assets/residences/economique.png'
  }
];
