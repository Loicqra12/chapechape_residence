/**
 * Utilitaire pour générer des instructions d'images de résidences
 * 
 * Ce script fournit des instructions détaillées pour créer des images de haute qualité
 * pour les différents types de résidences. Vous pouvez utiliser ces instructions avec
 * des services de génération d'images basés sur l'IA ou avec un photographe/designer.
 */

// Instructions détaillées pour chaque type de résidence
const residenceImageInstructions = {
  apartment: {
    title: "Appartement moderne",
    description: `
      Un appartement spacieux et lumineux avec :
      - Grandes baies vitrées donnant sur une vue urbaine
      - Salon moderne avec canapé élégant et décoration minimaliste
      - Cuisine ouverte avec îlot central et équipements haut de gamme
      - Palette de couleurs neutres avec des accents dorés
      - Éclairage ambiant et plantes d'intérieur
      - Style contemporain africain avec quelques touches traditionnelles
    `,
    dimensions: "1920x1080px",
    format: "JPG ou PNG, haute résolution (300 DPI)"
  },
  villa: {
    title: "Villa luxueuse",
    description: `
      Une villa élégante avec :
      - Façade imposante avec architecture contemporaine africaine
      - Grande piscine à débordement entourée de palmiers et végétation tropicale
      - Terrasse spacieuse avec mobilier d'extérieur haut de gamme
      - Vue sur l'océan ou un paysage naturel
      - Éclairage extérieur mettant en valeur l'architecture
      - Ambiance luxueuse et tropicale
    `,
    dimensions: "1920x1080px",
    format: "JPG ou PNG, haute résolution (300 DPI)"
  },
  studio: {
    title: "Studio fonctionnel",
    description: `
      Un studio compact et bien agencé avec :
      - Espace optimisé avec zone de couchage et espace de vie séparés visuellement
      - Bureau intégré avec chaise ergonomique
      - Kitchenette moderne avec équipements compacts et fonctionnels
      - Grande fenêtre laissant entrer la lumière naturelle
      - Palette de couleurs claires pour agrandir l'espace
      - Rangements astucieux et solutions multifonctionnelles
    `,
    dimensions: "1920x1080px",
    format: "JPG ou PNG, haute résolution (300 DPI)"
  },
  duplex: {
    title: "Duplex & Loft",
    description: `
      Un espace à double hauteur avec :
      - Escalier design menant à la mezzanine
      - Grande hauteur sous plafond avec poutres apparentes ou plafond contemporain
      - Grandes baies vitrées sur toute la hauteur
      - Espace ouvert et aéré avec zones distinctes
      - Mobilier contemporain et œuvres d'art africaines
      - Mélange de matériaux: bois, béton, métal, tissus
    `,
    dimensions: "1920x1080px",
    format: "JPG ou PNG, haute résolution (300 DPI)"
  },
  traditional: {
    title: "Résidence Traditionnelle",
    description: `
      Une résidence authentique avec :
      - Architecture inspirée des constructions traditionnelles ouest-africaines
      - Cour intérieure avec végétation locale et espace de repos
      - Détails artisanaux: sculptures, poteries, tissus traditionnels
      - Matériaux naturels locaux: terre cuite, bois, paille, pierre
      - Fusion harmonieuse entre confort moderne et traditions locales
      - Ambiance chaleureuse et authentique
    `,
    dimensions: "1920x1080px",
    format: "JPG ou PNG, haute résolution (300 DPI)"
  }
};

/**
 * Instructions pour créer un ensemble cohérent d'images
 */
const generalInstructions = `
  Pour assurer une cohérence visuelle entre les images :
  
  1. Utilisez une palette de couleurs similaire pour toutes les images, en privilégiant :
     - Des tons neutres (blanc, crème, gris clair)
     - Des accents dorés (#D4AF37)
     - Touches de couleurs naturelles (vert des plantes, bleu de l'eau)
  
  2. L'éclairage doit être cohérent :
     - Lumière naturelle abondante
     - Ambiance chaude et accueillante
     - Jeux d'ombres subtils
  
  3. Style photographique :
     - Photos bien composées, respectant la règle des tiers
     - Angle légèrement en plongée pour montrer l'espace
     - Profondeur de champ adaptée pour montrer les détails
     - Netteté et clarté optimales
  
  4. Post-traitement :
     - Tons chauds et légèrement désaturés
     - Contraste modéré pour un rendu élégant
     - Légère vignette pour attirer l'œil vers le centre
     - Look cohérent entre toutes les images
`;

// Export des instructions
module.exports = {
  residenceImageInstructions,
  generalInstructions
};

console.log("Pour générer des images de résidences de haute qualité, vous pouvez :");
console.log("1. Utiliser ces instructions avec un outil de génération d'images IA comme DALL-E, Midjourney ou Stable Diffusion");
console.log("2. Engager un photographe immobilier professionnel avec ces spécifications");
console.log("3. Acheter des images de stock respectant ces critères (Shutterstock, Adobe Stock, etc.)");
console.log("\nPensez à nommer vos images selon la convention : type-residence.jpg (ex: apartment.jpg, villa.jpg)");
console.log("Et à les placer dans le répertoire : /public/assets/residences/"); 