# Vérification stricte de l’analyse expert – Site de présentation ChapeChape

Chaque affirmation de l’analyse a été confrontée au code (fichiers et numéros de lignes).  
Légende : **VRAI** = confirmé | **FAUX** = infirmé | **PARTIEL** = partiellement exact | **NV** = non vérifiable ici.

---

## 1. Typographie

| Affirmation | Verdict | Détail |
|-------------|----------|--------|
| Police chargée depuis Fontshare (CDN externe) | **VRAI** | `index.html` L77 : `https://api.fontshare.com/v2/css?f[]=cabinet-grotesk@...` |
| font-display: swap **absent** dans l’import Google Fonts | **FAUX** | L76 : `...&display=swap` est bien présent dans l’URL Google Fonts. Fontshare L77 a aussi `&display=swap`. |
| H2 utilisé en sous-label (Apps.tsx L161, text-base font-semibold) | **VRAI** | L139-143 : `<motion.h2 className="text-base font-semibold...">Pour les Locataires</motion.h2>`. Hiérarchie sémantique discutable. |
| Contenu des articles Blog = "Lorem ipsum..." | **PARTIEL** | **pages/Blog.tsx** : `content: "Lorem ipsum dolor sit amet..."` pour chaque article (L13, 27, 41, 55, 69…). **components/home/Blog.tsx** utilise des excerpts réels (pas de Lorem). Donc vrai pour la **page** Blog et le contenu article, pas pour la section blog de la home. |

---

## 2. SEO & Référencement

| Affirmation | Verdict | Détail |
|-------------|----------|--------|
| About, Team, Services, Blog, FAQ, Apps, Partners, Testimonials sans SEOHead | **VRAI** | Seule **Home.tsx** importe et utilise `SEOHead`. Aucune de ces pages n’utilise SEOHead. |
| Home : url en dur (https://presentation...) | **VRAI** | `Home.tsx` L79 : `url="https://presentation.chapechaperesidence.com/"` en dur. |
| Residences : aucun SEO + SPA sans SSR → Google ne voit que `<div id="root"></div>` | **VRAI** | `Residences.tsx` n’utilise pas SEOHead ; données chargées côté client via `apiService.getResidences()`. |
| Blog : 6 articles avec dates 2024, contenu Lorem | **VRAI** | **pages/Blog.tsx** : dates "15 avril 2024", "28 mars 2024", etc. ; `content: "Lorem ipsum dolor sit amet..."` pour chaque article. |
| index.html L66 : GA_MEASUREMENT_ID non remplacé → script avec placeholder → 404 | **VRAI** | L64-70 : `id=GA_MEASUREMENT_ID` et `gtag('config', 'GA_MEASUREMENT_ID')` en chaîne littérale. Aucune variable d’env. |
| SEOHead : url par défaut = racine pour toutes les pages sans URL explicite | **VRAI** | `SEOHead.tsx` : `url = 'https://presentation.chapechaperesidence.com'` par défaut. |
| index.html L47-49 : sameAs = LinkedIn des fondateurs, pas la page entreprise | **VRAI** | L45-47 : `sameAs` pointe vers les profils LinkedIn des deux fondateurs, pas vers la page entreprise ChapeChape. |

---

## 3. Responsivité

| Affirmation | Verdict | Détail |
|-------------|----------|--------|
| Hero Home : style {{ y, opacity }} + useScroll — parallax saccadé sur mobile | **PARTIEL** | Home utilise `useScroll` + `useTransform` pour y/opacity. Impact “saccadé” sur mobile non mesuré ici, mais risque plausible. |
| Images Team : min-h-[300px] sans breakpoint mobile | **VRAI** | **Team.tsx** L198 : `min-h-[300px]` sur le conteneur d’image des membres (coreTeam), sans variante `sm:` ou `md:` — même hauteur sur mobile. |
| Navbar desktop : items avec submenu = bouton sans href, hover obligatoire | **VRAI** | L101-116 : `<button ... aria-expanded="false">` pour les items avec submenu ; pas de lien direct, dropdown au survol. |
| FAQ : grid-cols-2 md:grid-cols-5 → dernier bouton centré seul sur mobile | **FAUX** | **FAQ.tsx** L212 : 1 bouton « Toutes » + 5 catégories = 6 boutons ; `grid-cols-2` → 3 lignes de 2. Pas de bouton orphelin centré seul. |

---

## 4. UX/UI Design & Couleurs

| Affirmation | Verdict | Détail |
|-------------|----------|--------|
| Hero identique sur toutes les pages internes (secondary-900, particules, pattern-luxury) | **VRAI** | Même structure (hero + particules dorées + pattern) sur About, Apps, Contact, Services, Team, Blog, FAQ, Partners, Testimonials, Residences. |
| Boutons App Store / Google Play → href="#" | **VRAI** | **Apps.tsx** L211, 222, 297, 310 : `<a href="#">` pour les 4 boutons. |
| Footer : Carrières → /careers, route inexistante | **VRAI** | **Footer.tsx** L7 : `{ name: 'Carrières', href: '/careers' }`. **App.tsx** ne définit pas de route `/careers` → 404. |
| Footer : sélecteur langue EN non fonctionnel (opacity-50 permanent) | **VRAI** | L200-205 : `<span>🇫🇷 FR</span>`, `<span className="opacity-50">|</span>`, `<span className="opacity-50">🇬🇧 EN</span>` — pas de lien ni d’état, EN non cliquable. |
| About H1 gradient : texte invisible en dark mode | **PARTIEL** | L121 : `className="... bg-gradient-to-r from-secondary-900 via-primary-600 to-secondary-900 dark:from-white dark:via-primary-300 dark:to-white ..."`. En dark, from-white / via-primary-300 / to-white sont prévus ; visibilité réelle dépend du fond (contraste). Affirmation “invisible” trop forte sans test visuel. |
| Blog : "Lire la suite" non cliquable / blog décoratif | **PARTIEL** | **components/home/Blog.tsx** L279-281 : `<Link to="/blog">` avec texte "Lire plus" — cliquable, mais renvoie vers la page blog, pas vers un article précis. **pages/Blog.tsx** : pas de page détail par article. Donc “non cliquable” est faux ; “pas de lien vers article complet” est vrai. |
| Services : images owners.jpg, tenants.jpg, concierge.jpg probablement absentes | **PARTIEL** | **Services.tsx** L12, 29, 47 : chemins vers owners.jpg, tenants.jpg, concierge.jpg. **Un fallback existe** : L160-162 `onError` → `target.src = '/assets/images/placeholder-luxury.jpg'`. Présence réelle des 3 images non vérifiée. |
| Team : équipe élargie + conseillers = team-placeholder.jpg | **VRAI** | **Team.tsx** : `extendedTeam` et `advisors` utilisent `image: "/assets/team/team-placeholder.jpg"` (L36, 42, 46, 52, 63, 68). |

---

## 5. Performances

| Affirmation | Verdict | Détail |
|-------------|----------|--------|
| sourcemap: true en prod | **VRAI** | **vite.config.ts** L11 : `sourcemap: true` dans `build`. |
| Math.random() dans 9 sections hero à chaque render | **VRAI** | Math.random utilisé dans les heroes/particules de : About, Apps, Contact, Services, Team, Blog, FAQ, Partners, Testimonials, Residences, + AboutSection, Process, Coverage, Stats, Testimonials (home), FAQ (home), ResidenceTypes. Ré-renders et “sauts” des particules plausibles. |
| 2 appels GA4 (index.html + GoogleAnalytics.tsx) | **VRAI** | index.html charge gtag avec `GA_MEASUREMENT_ID` littéral ; **GoogleAnalytics.tsx** appelle `initGA()` (injecte un autre script si `VITE_GA_MEASUREMENT_ID` est défini). Double source GA. |
| Home : Ken Burns (scale 1 → 1.1, 20s, Infinity) sur fond | **VRAI** | **Home.tsx** L87-99 : `motion.div` avec `animate={{ scale: 1.1 }}`, `duration: 20`, `repeat: Infinity`, `repeatType: "reverse"`. |
| Blog : images Unsplash sans loading="lazy" ni srcset | **PARTIEL** | **pages/Blog.tsx** : images via `post.image` (URLs Unsplash avec `w=1000&q=80`). Pas de `loading="lazy"` ni `srcset` vu dans l’extrait. **components/home/Blog.tsx** : `motion.img` sans loading ni srcset. |
| 2 polices, 2 CDN (Google + Fontshare) | **VRAI** | index.html L74-77 : Google Fonts (Plus Jakarta Sans) + Fontshare (Cabinet Grotesk). |
| Contact : useScroll() + useTransform() actif sur toutes les sections | **VRAI** | **components/home/Contact.tsx** L26-32 : `useScroll` et `useTransform` (y, opacity) ; utilisé aussi L600. Le composant Contact est utilisé dans la page Contact, donc scroll listener actif sur cette page. |

---

## 6. Connexion Backend

| Affirmation | Verdict | Détail |
|-------------|----------|--------|
| VITE_API_BASE_URL fallback = localhost → si absent en prod, appels cassés | **VRAI** | **api.service.ts** L2 : `import.meta.env.VITE_API_BASE_URL || 'http://localhost:4000/api'`. |
| getResidences → double /api si VITE_API_BASE_URL inclut déjà /api | **FAUX** | makeRequest utilise `${API_BASE_URL}${endpoint}` avec endpoint `/residences?…`. Si API_BASE_URL = `https://x.com/api`, on obtient `https://x.com/api/residences` — un seul segment `/api`. Pas de double /api dans le code front. |
| getPopularResidences → /residences/popular n’existe pas (backend) | **NV** | **api.service.ts** L125 : `makeRequest<Residence[]>('/residences/popular')`. Existence de la route côté backend non vérifiable dans ce repo. |
| Contact : pas de CSRF, pas de rate-limit frontend | **VRAI** | Aucun token CSRF ni limitation de soumission côté front dans le code vu. |
| Newsletter : pas de vérification email confirmé | **VRAI** | Soumission directe sans double saisie ou email de confirmation côté front. |
| Articles blog entièrement hardcodés, pas de CMS / API | **VRAI** | **pages/Blog.tsx** : tableau `blogPosts` en dur, pas d’appel API pour les articles. |

---

## 7. Accessibilité (WCAG 2.1 AA)

| Affirmation | Verdict | Détail |
|-------------|----------|--------|
| aria-expanded="false" statique, jamais mis à jour | **VRAI** | **Navbar.tsx** L115 : `aria-expanded="false"` en dur ; `openSubMenus` n’est pas utilisé pour ce bouton desktop (dropdown au survol, pas au clic). |
| Boutons submenu desktop sans rôle navigation clair | **VRAI** | Parent du submenu = `<button>`, pas de rôle `navigation` sur le dropdown. |
| Iframe Google Maps sans title | **FAUX** | **pages/Contact.tsx** L178 (composant Contact) : iframe avec `title="Emplacement des bureaux de ChapeChape Residence"`. |
| `<a href="/faq">` au lieu de `<Link to="/faq">` (rechargement complet) | **VRAI** | **Contact.tsx** L141 : `<a href="/faq">`. **FAQ.tsx** L308 : `<a href="/contact">`. Rechargement full page au lieu de SPA. |
| Focus management absent après ouverture menu mobile | **NV** | Non vérifié en détail. |

---

## 8. Synthèse des corrections à apporter à l’analyse

- **Typo** : indiquer que **font-display: swap est présent** pour Google Fonts et Fontshare (pas “absent”).
- **Blog** : distinguer **pages/Blog.tsx** (Lorem + dates 2024) et **components/home/Blog.tsx** (excerpts réels, pas de Lorem).
- **Backend** : retirer ou nuancer l’affirmation “double /api” pour getResidences ; le code ne double pas le segment `/api`.
- **Accessibilité** : corriger “iframe Maps sans title” → l’iframe a bien un attribut `title`.
- **Blog “Lire la suite”** : préciser que le lien est cliquable (vers /blog) mais qu’il n’y a pas de page détail par article.

---

## 9. Verdict global

- **Majorité des points** : confirmés (SEO, GA, routes, href="#", Footer, Math.random, sourcemap, Ken Burns, useScroll dans Contact, API fallback, Blog Lorem/dates 2024, Navbar aria-expanded, etc.).
- **Quelques affirmations** : à corriger (font-display, double /api, iframe sans title, nuance sur “Lire la suite” et gradient About).
- **Analyse** : globalement fiable et bien ancrée dans le code ; les corrections ci-dessus la rendraient strictement exacte.

---

## 10. Points supplémentaires (non mentionnés dans l’analyse initiale)

Points repérés en vérifiant le code, en complément de l’analyse.

| Point | Fichier(s) | Détail |
|-------|------------|--------|
| **Route /resources manquante** | **Navbar.tsx** L42, **App.tsx** | Navbar contient `{ name: 'Ressources', href: '/resources', submenu: [Blog, Témoignages, FAQ] }`. Aucune route `/resources` dans **App.tsx**. Clic sur « Ressources » (lien parent) → navigation vers `/resources` → pas de route → contenu vide ou comportement indéfini. Les sous-liens (/blog, /testimonials, /faq) existent. |
| **Console.log / debug en production** | **Navbar.tsx** L57, 90 ; **ResidenceTypes.tsx** L8, 42, 69, 311 ; **CookiePolicy.tsx** L296 ; **generatePlaceholderImages.js** L118-123 | Plusieurs `console.log` laissés (Navbar : état menu mobile ; ResidenceTypes : type sélectionné, clic ; CookiePolicy : panneau cookies ; generatePlaceholderImages : instructions au chargement du module). À retirer ou conditionner à `import.meta.env.DEV` pour les bonnes pratiques prod. |
| **Pages légales sans SEOHead** | **PrivacyPolicy**, **TermsOfService**, **CookiePolicy**, **AccountDeletion** | Aucune de ces pages n’utilise `SEOHead`. Pour des pages obligatoires (RGPD, stores), des meta title/description dédiés amélioreraient le SEO et le partage. |
| **Contact iframe a bien loading="lazy"** | **pages/Contact.tsx** L176 | L’iframe Google Maps a `loading="lazy"`. À noter en positif (l’analyse ne le mentionnait pas). |
| **SmartImage avec srcSet** | **components/ui/SmartImage.tsx** L71-72 | Le composant utilise `srcSet` (avif, webp). Les pages qui l’utilisent bénéficient d’images responsives ; le Blog n’utilise pas SmartImage pour les images d’articles. |
