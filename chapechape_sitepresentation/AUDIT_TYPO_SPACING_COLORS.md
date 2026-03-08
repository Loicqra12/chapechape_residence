# Audit : Typographie, espacement et code couleur – Site de présentation

## Référence (design system)

- **Tailwind** : `tailwind.config.js` + `src/index.css`
- **Couleurs** : `primary` (or 50–950), `secondary` (gris 25–950), `accent` (blue, purple, green, orange, red)
- **Typographie** : `font-display` (Cabinet Grotesk), `font-body` (Plus Jakarta Sans)
- **Composants** : `.section-heading`, `.btn-primary`, `.btn-secondary`, `.feature-card`

---

## 1. Typographie

### Ce qui est cohérent
- Les **titres** (h1, h2, h3) utilisent en grande majorité **`font-display`** (Cabinet Grotesk) sur les pages principales et composants home (About, Apps, Blog, Contact, FAQ, Partners, Residences, Services, Team, Testimonials, Home, etc.).

### Problèmes
- **`font-body` n’est jamais utilisé** dans le projet. La police « corps de texte » (Plus Jakarta Sans) est chargée dans `index.html` mais aucune classe ne l’applique.
- Le **`<body>`** dans `index.html` n’a que `class="h-full"` : pas de police par défaut. Le texte qui n’a pas `font-display` utilise donc la police par défaut du navigateur (souvent une sans-serif système), pas Plus Jakarta Sans.
- **Pages légales** (PrivacyPolicy, TermsOfService, CookiePolicy, AccountDeletion) : titres en `text-4xl font-bold text-gray-900` sans `font-display`, donc typo titres différente du reste du site.

**Recommandation** : Appliquer `font-body` sur le conteneur global (ex. dans `Layout` ou sur `body` dans un fichier CSS) pour que tout le texte utilise Plus Jakarta Sans par défaut, et ajouter `font-display` aux titres des pages légales.

---

## 2. Espacement

### Ce qui est cohérent
- **Hero** : la plupart des pages utilisent `py-32` pour la section hero (About, Apps, Blog, Contact, FAQ, Partners, Residences, Services, Testimonials, Careers, Resources).
- **Sections de contenu** : beaucoup utilisent `py-16 sm:py-24` ou `py-24` pour les blocs principaux.

### Incohérences
- **Team** : hero en **`py-24`** au lieu de `py-32` comme les autres pages.
- **PrivacyPolicy** : conteneur en **`py-12`** ; les autres pages légales sont en **`py-16`** (TermsOfService, CookiePolicy, AccountDeletion).
- **Careers / Resources** : section sous le hero en **`py-16 px-4`** au lieu du pattern `py-16 sm:py-24` + container comme sur FAQ/Blog/Partners/Testimonials.
- **Services** : une section utilise **`bg-gray-50`** au lieu de `bg-secondary-50` (et donc en dehors du code couleur).

**Recommandation** : Unifier hero à `py-32`, pages légales à `py-16`, et remplacer `bg-gray-50` par `bg-secondary-50` (voir couleurs).

---

## 3. Code couleur

### Ce qui est cohérent
- La plupart des pages principales utilisent **primary** et **secondary** (titres, boutons, fonds, bordures).
- Composants réutilisables (Navbar, Footer, Layout, CTA, etc.) s’appuient sur la palette du thème.

### Problèmes (hors design system)

#### Pages légales (PrivacyPolicy, TermsOfService, CookiePolicy, AccountDeletion)
- Utilisation massive de **`text-gray-*`**, **`bg-gray-*`**, **`border-gray-*`** au lieu de **`secondary-*`**.
- **PrivacyPolicy** : fond **`from-blue-50 to-indigo-100`** au lieu de primary/secondary.
- Liens et accents en **`text-blue-600`**, **`bg-blue-50`** au lieu de **primary** (ex. `text-primary-600`, `bg-primary-50`).

#### Autres pages / composants
- **About** : sous-titre hero **`text-gray-300`** (à préférer en `text-secondary-200` ou `text-primary-200` selon le fond). Cartes avec **`from-blue-400 to-blue-600`**, **`from-blue-50`**, etc. au lieu de dérivés de **primary**.
- **Contact** : **`text-gray-300`**, **`border-gray-100`** → à remplacer par **secondary** (ou primary pour les accents).
- **Apps** : **`border-gray-100`** sur des cartes → **`border-secondary-100`**.
- **FAQ** (composant home) : champs de recherche, états vide, cartes avec **`gray-*`** (bg, border, text) → à aligner sur **secondary** (et primary pour les focus).
- **Partners** : **`from-gray-50 to-gray-100`** pour une zone de logo → **`from-secondary-50 to-secondary-100`**.
- **AboutSection** : **`from-slate-50 to-slate-100`**, **`to-gray-50`**, **`from-blue-500`** → à baser sur **secondary** et **primary**.
- **Services** : **`bg-gray-50`** → **`bg-secondary-50`**.

**Recommandation** : Remplacer systématiquement gray/blue/indigo/slate par la palette **primary** / **secondary** (et **accent** seulement si voulu pour des cas très précis), et harmoniser les pages légales avec le reste du site (fond, texte, liens).

---

## 4. Synthèse

| Critère        | Statut        | Commentaire |
|----------------|---------------|-------------|
| Typographie    | Partiel       | Titres en `font-display` OK ; corps de texte sans `font-body` ; pages légales sans `font-display` sur les titres. |
| Espacement     | Partiel       | Hero et sections globalement cohérents ; Team (hero py-24), PrivacyPolicy (py-12), et quelques sections à aligner. |
| Code couleur   | Non respecté  | Gray/blue/indigo/slate utilisés à la place de primary/secondary sur pages légales, About, Contact, FAQ, Partners, Services, AboutSection. |

En l’état, **le site n’utilise pas partout la même typographie** (corps de texte non appliqué), **l’espacement est globalement respecté avec quelques écarts**, et **le code couleur n’est pas respecté** sur plusieurs pages et composants (gray/blue/indigo au lieu de la palette définie).

---

## 5. Corrections appliquées (post-audit)

- **Typographie** : `font-body` appliqué sur le conteneur principal dans `Layout.tsx`. Titres des pages légales (PrivacyPolicy, TermsOfService, CookiePolicy, AccountDeletion) : `font-display` + couleurs secondary/primary.
- **Espacement** : Hero Team `py-24` → `py-32`. PrivacyPolicy `py-12` → `py-16`. Services : `bg-gray-50` → `bg-secondary-50`.
- **Couleurs** : Pages légales : gray/blue remplacés par secondary/primary (texte, fonds, liens). About : `text-gray-300` → `text-secondary-200`, cartes bleues → primary. Contact, Apps : gray → secondary (bordures, texte). FAQ (composant) : gray → secondary. Partners : gray-50/100 → secondary. AboutSection : slate/gray → secondary, bâtiments/avatar bleu → primary.
