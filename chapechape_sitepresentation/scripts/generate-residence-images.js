/**
 * Script pour générer les instructions de création d'images de résidences
 * Ce script utilise les instructions du fichier ../src/utils/generatePlaceholderImages.js
 * pour générer des prompts détaillés pour la création d'images.
 * 
 * Comment utiliser:
 * 1. Exécutez ce script avec Node.js: node generate-residence-images.js
 * 2. Le script imprimera des instructions détaillées pour chaque type de résidence
 * 3. Utilisez ces instructions pour créer des images avec un outil comme DALL-E, Midjourney, Stable Diffusion
 * 4. Enregistrez les images générées dans le dossier /public/assets/residences/ avec les noms appropriés
 */

const { residenceImageInstructions, generalInstructions } = require('../src/utils/generatePlaceholderImages');

console.log('='.repeat(80));
console.log('INSTRUCTIONS POUR LA GÉNÉRATION D\'IMAGES DE RÉSIDENCES');
console.log('='.repeat(80));
console.log('\n');
console.log('INSTRUCTIONS GÉNÉRALES:');
console.log(generalInstructions);
console.log('\n');

Object.entries(residenceImageInstructions).forEach(([key, residence]) => {
  console.log('='.repeat(80));
  console.log(`RÉSIDENCE: ${residence.title.toUpperCase()} (${key}.jpg)`);
  console.log('='.repeat(80));
  console.log(`Description: ${residence.description}`);
  console.log(`Dimensions: ${residence.dimensions}`);
  console.log(`Format: ${residence.format}`);
  
  // Générer un prompt pour les outils d'IA
  console.log('\nPrompt pour IA de génération d\'images:');
  const aiPrompt = `Photographie professionnelle intérieure d'${residence.title.toLowerCase()} en Afrique de l'Ouest, 
style architectural contemporain avec influences africaines, lumière naturelle abondante, 
décoration élégante avec accents dorés, matériaux nobles, 
ambiance luxueuse et chaleureuse, haute résolution, photographie architecturale.
${residence.description.replace(/\n/g, ' ').replace(/\s+/g, ' ').trim()}`;
  
  console.log(aiPrompt);
  console.log('\n');
  
  // Instructions pour l'enregistrement
  console.log('IMPORTANT: Enregistrez l\'image sous:');
  console.log(`/public/assets/residences/${key}.jpg`);
  console.log('\n');
});

console.log('='.repeat(80));
console.log('RAPPEL:');
console.log('1. Les images doivent être cohérentes entre elles (style, éclairage, couleurs)');
console.log('2. Privilégiez une résolution de 1920x1080 pixels minimum');
console.log('3. Utilisez le format JPG avec une qualité élevée (80-90%)');
console.log('4. Optimisez les images pour le web (taille raisonnable)');
console.log('='.repeat(80)); 