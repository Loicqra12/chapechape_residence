# ChapeChape Residence - Site de Présentation

Ce projet est le site web de présentation de ChapeChape Residence, une plateforme innovante de gestion et de location de résidences.

## Technologies utilisées

- React 18
- TypeScript
- Vite
- Tailwind CSS
- Framer Motion
- React Router
- Heroicons
- Headless UI

## Prérequis

- Node.js 18 ou supérieur
- npm 9 ou supérieur

## Installation

1. Clonez le dépôt :

```bash
git clone https://github.com/votre-username/chapechape_sitepresentation.git
cd chapechape_sitepresentation
```

2. Installez les dépendances :

```bash
npm install
```

3. Lancez le serveur de développement :

```bash
npm run dev
```

Le site sera accessible à l'adresse [http://localhost:3000](http://localhost:3000).

## Structure du projet

```
chapechape_sitepresentation/
├── src/
│   ├── components/     # Composants réutilisables
│   │   ├── layout/    # Composants de mise en page
│   │   ├── home/      # Composants de la page d'accueil
│   │   ├── about/     # Composants de la page À propos
│   │   ├── apps/      # Composants de la page Applications
│   │   └── team/      # Composants de la page Équipe
│   ├── pages/         # Pages principales
│   ├── assets/        # Images et autres ressources
│   └── styles/        # Styles globaux
├── public/            # Fichiers statiques
└── index.html         # Point d'entrée HTML
```

## Scripts disponibles

- `npm run dev` : Lance le serveur de développement
- `npm run build` : Compile le projet pour la production
- `npm run preview` : Prévisualise la version de production
- `npm run lint` : Vérifie le code avec ESLint

## Déploiement

Pour déployer le site en production :

1. Construisez le projet :

```bash
npm run build
```

2. Les fichiers de production seront générés dans le dossier `dist/`

## Contribution

1. Forkez le projet
2. Créez une branche pour votre fonctionnalité (`git checkout -b feature/AmazingFeature`)
3. Committez vos changements (`git commit -m 'Add some AmazingFeature'`)
4. Poussez vers la branche (`git push origin feature/AmazingFeature`)
5. Ouvrez une Pull Request

## Licence

Ce projet est sous licence MIT. Voir le fichier `LICENSE` pour plus de détails.
