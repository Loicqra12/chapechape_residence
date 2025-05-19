# Génération des Images de Résidences pour ChapeChape Residence

Ce document explique comment générer des images de haute qualité pour les différents types de résidences affichés sur le site ChapeChape Residence.

## Types de Résidences

Nous avons besoin d'images pour les types de résidences suivants :

1. **Appartements** (`apartment.jpg`)
2. **Villas Luxueuses** (`villa.jpg`)
3. **Studios** (`studio.jpg`)
4. **Duplex & Lofts** (`duplex.jpg`)
5. **Résidences Traditionnelles** (`traditional.jpg`)

## Méthodes de Génération des Images

Plusieurs approches sont possibles pour obtenir ces images :

### 1. Utilisation d'outils de génération d'images par IA

Vous pouvez utiliser des outils comme DALL-E, Midjourney ou Stable Diffusion pour générer des images réalistes de ces résidences.

Pour vous aider, nous avons créé un script qui génère des prompts détaillés pour chaque type de résidence :

```bash
# Depuis la racine du projet
node scripts/generate-residence-images.js
```

Ce script vous fournira :

- Des descriptions détaillées pour chaque type de résidence
- Des prompts optimisés pour les outils d'IA
- Des conseils pour la cohérence visuelle entre les images

### 2. Achat d'images stock

Vous pouvez également acheter des images sur des sites comme :

- Shutterstock
- Adobe Stock
- iStock
- Getty Images

Recherchez des images qui correspondent aux descriptions fournies dans le script de génération.

### 3. Photographie professionnelle

Si vous avez accès à des propriétés similaires, engager un photographe immobilier professionnel pour réaliser les prises de vue peut donner les meilleurs résultats.

## Spécifications Techniques

Pour une intégration optimale dans le site, vos images doivent respecter ces spécifications :

- **Résolution** : 1920x1080px minimum (ratio 16:9)
- **Format** : JPG ou PNG
- **Qualité** : Haute résolution (300 DPI pour l'impression)
- **Taille de fichier** : Optimisée pour le web (< 500 Ko si possible)

## Placement des Images

Une fois que vous avez obtenu les images, placez-les dans le dossier :

```
/public/assets/residences/
```

Assurez-vous que les noms des fichiers correspondent exactement à ceux spécifiés :

- apartment.jpg
- villa.jpg
- studio.jpg
- duplex.jpg
- traditional.jpg

## Cohérence Visuelle

Pour assurer une expérience utilisateur harmonieuse, veillez à ce que toutes les images partagent :

- Une palette de couleurs similaire (tons neutres avec accents dorés)
- Un style d'éclairage cohérent (préférez la lumière naturelle)
- Une qualité et une résolution uniformes
- Un style architectural qui reflète l'Afrique de l'Ouest contemporaine

## Solution Temporaire

En attendant que les images finales soient générées, nous avons implémenté un système de placeholders visuels qui s'afficheront automatiquement. Ces placeholders seront remplacés par les vraies images dès qu'elles seront disponibles dans le dossier approprié.

## Besoin d'aide ?

Si vous avez des questions sur la génération d'images ou si vous rencontrez des problèmes techniques, n'hésitez pas à contacter notre équipe de développement.
