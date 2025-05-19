export interface ResidenceType {
  id: string;
  name: string;
  description: string;
  features: string[];
  imageUrl: string;
}

export const residenceTypes: ResidenceType[] = [
  {
    id: 'apartment',
    name: 'Appartements',
    description: 'Des appartements modernes et élégants, parfaitement équipés pour vous offrir un maximum de confort pendant votre séjour.',
    features: [
      'Cuisine entièrement équipée',
      'Salon spacieux',
      'WiFi haut débit',
      'Climatisation',
      'Balcon avec vue'
    ],
    imageUrl: '/assets/residences/apartment.jpg'
  },
  {
    id: 'villa',
    name: 'Villas Luxueuses',
    description: 'Des villas de standing avec piscine privée, idéales pour les familles ou les groupes en quête d\'intimité et de confort.',
    features: [
      'Piscine privée',
      'Jardin tropical',
      'Plusieurs chambres',
      'Espace de vie ouvert',
      'Sécurité 24/7'
    ],
    imageUrl: '/assets/residences/villa.jpg'
  },
  {
    id: 'studio',
    name: 'Studios',
    description: 'Des studios fonctionnels et bien aménagés, parfaits pour les voyageurs d\'affaires ou les courts séjours.',
    features: [
      'Espace optimisé',
      'Coin bureau',
      'Kitchenette équipée',
      'Douche moderne',
      'Localisation centrale'
    ],
    imageUrl: '/assets/residences/studio.jpg'
  },
  {
    id: 'duplex',
    name: 'Duplex & Lofts',
    description: 'Des espaces sur deux niveaux offrant une expérience de vie unique avec des volumes généreux et un aménagement contemporain.',
    features: [
      'Double hauteur sous plafond',
      'Escalier design',
      'Grandes baies vitrées',
      'Espace de vie modulable',
      'Finitions premium'
    ],
    imageUrl: '/assets/residences/duplex.jpg'
  },
  {
    id: 'traditional',
    name: 'Résidences Traditionnelles',
    description: 'Des logements authentiques qui célèbrent l\'architecture locale et vous permettent de vivre une expérience culturelle immersive.',
    features: [
      'Architecture traditionnelle',
      'Matériaux locaux',
      'Décoration artisanale',
      'Cour intérieure',
      'Expérience authentique'
    ],
    imageUrl: '/assets/residences/traditional.jpg'
  }
]; 