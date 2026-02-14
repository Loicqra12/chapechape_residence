# Audit des sections du Dashboard (chapechape_partner)

Analyse de chaque section du dashboard : connexion backend, données statiques, utilité.

---

## Résumé

| Section | Connexion backend | Données | Utilité |
|--------|--------------------|---------|--------|
| Sélecteur de période | ✅ Oui | state.period / API | ✅ Utile |
| Bouton Analytics Avancées | ✅ Oui (via Bloc) | state.dashboardData | ✅ Utile |
| **Performance** | ✅ Oui | `partners/dashboard/overview` | ✅ Utile |
| **À faire** | ❌ Non | Statique, onTap vides | ⚠️ Décoratif uniquement |
| **Revenus** | ✅ Oui | overview + finances + trends | ✅ Utile |
| **Mes Reversements (Payouts)** | ✅ Oui | `GET /api/payouts/stats/:partnerId` | ✅ Utile |
| **Tendances** | ✅ Oui | `partners/stats/trends` | ✅ Utile |
| **Réservations à venir** | ❌ Non | Jamais de données API | ⚠️ Vide / CTA seulement |
| **Analyse par localisation** | ❌ Non | Données en dur (Abidjan 1, etc.) | ❌ Inutile en l’état |
| **Pricing Dynamique** | ❌ Non | Texte statique, lien vers écran | ⚠️ Décoratif |
| **Performance des résidences** | ✅ Oui | `getResidenceStats()` | ✅ Utile (si stats non vides) |
| **Avis clients** | ✅ Oui | rating dans overview | ✅ Utile |

---

## 1. Sections connectées au backend (qui marchent)

### 1.1 Sélecteur de période
- **Source :** `state.period`, `state.startDate`, `state.endDate` (DashboardBloc).
- **Effet :** Change la période ; le bloc recharge les données (trends, etc.) selon la période.
- **API :** `getTrends(period)` et autres appels lors de `ChangePeriod`.

### 1.2 Bouton « Analytics Avancées »
- **Source :** Ouvre un écran qui utilise `BlocBuilder<DashboardBloc, DashboardState>` et `state.dashboardData`.
- **Données :** Mêmes que le dashboard (overview, finances, revenue, stats).
- **Utilité :** Graphiques et comparaisons basés sur les vraies données du backend.

### 1.3 Section Performance
- **Source :** `state.dashboardData.performance` (PerformanceStats).
- **API :** `GET partners/dashboard/overview` → totalResidences, totalReservations, occupancyRate, pendingReviews, newMessages.
- **Affichage :** Résidences, Réservations, Messages, Avis, taux d’occupation.

### 1.4 Section Revenus
- **Source :** `state.dashboardData.revenue` (RevenueStats) + `state.period`.
- **APIs :**
  - `GET partners/dashboard/overview`
  - `GET partners/dashboard/finances` (dailyRevenue, weeklyRevenue, monthlyRevenue, revenueGrowth, bestResidences).
  - `getTrends(period)` pour l’historique (revenueHistory).
- **Affichage :** Cartes Aujourd’hui / Cette semaine / Ce mois, graphique historique, meilleures résidences.

### 1.5 Section Mes Reversements (Payouts)
- **Source :** `FutureBuilder` → `PaymentService.getPayoutStats()`.
- **API :** `GET /api/payouts/stats/:partnerId` (payment_service.dart).
- **Affichage :** Cartes statistiques payouts (montants, statuts, etc.) si l’endpoint existe côté backend.

### 1.6 Section Tendances
- **Source :** `state.trendData` (TrendData).
- **API :** `GET partners/stats/trends?period=...`.
- **Affichage :** Graphique des tendances, croissance (%).

### 1.7 Section Performance des résidences
- **Source :** `state.residenceStats` (List<ResidenceStats>).
- **API :** `DashboardService.getResidenceStats()` (avec fallback ResidenceService si besoin).
- **Affichage :** Liste des résidences avec stats (revenus, réservations, etc.) — **affichée seulement si `state.residenceStats.isNotEmpty`**.

### 1.8 Section Avis clients
- **Source :** `state.dashboardData.stats.rating` (GeneralStats.rating).
- **API :** `partners/dashboard/overview` → `performance['averageRating']`.
- **Affichage :** Note /5, libellé (Aucune note, Bon, etc.), liste d’avis (vide si pas d’avis).

---

## 2. Sections statiques (données en dur ou vides)

### 2.1 Section « À faire »
- **Données :** Aucune donnée API. Textes et icônes fixes.
- **Actions :** Tous les `onTap` sont vides (`onTap: () {}`).
- **Contenu :** « Ajouter votre première résidence », « Configurer vos disponibilités », « Activer les paiements », « Attirer plus de clients ».
- **Verdict :** Purement décoratif. Aucune navigation ni logique métier.

### 2.2 Section Réservations à venir
- **Données :** Aucune. Aucun passage de liste de réservations depuis le Bloc ou l’API.
- **Affichage :** Toujours le même état vide : « Aucune réservation à venir » + CTA « Voir toutes les réservations » (vers l’onglet Réservations).
- **Verdict :** Section jamais alimentée par le backend. Soit la connecter à un endpoint « réservations à venir », soit la considérer comme simple CTA.

### 2.3 Section Analyse par localisation
- **Données :** 100 % en dur.
  - Région « Côte d’Ivoire » en dur.
  - Cartes : Abidjan `'1'`, Yamoussoukro `'0'`, San-Pédro `'0'` (pas de données API).
- **Verdict :** Ne reflète pas les vraies résidences par région. Inutile tant qu’il n’y a pas d’API « résidences par région / ville ».

### 2.4 Section Pricing Dynamique
- **Données :** Texte statique uniquement (« Optimisez vos revenus… », « Économies clients », « Méthodes optimisées », etc.).
- **Action :** Le lien « Détails » ouvre `PricingStatsScreen()` (écran dédié).
- **Verdict :** Bloc décoratif sur le dashboard ; la valeur vient de l’écran Pricing s’il est branché à une API.

---

## 3. Sections qui ne servent à rien (ou peu) en l’état

1. **À faire** : Aucune action, aucun état dynamique. Peut être supprimée ou transformée en vrais CTAs (navigation vers Résidences, Calendrier, Paiements).
2. **Analyse par localisation** : Chiffres faux (1, 0, 0). Trompe l’utilisateur. À supprimer ou à remplacer par des données réelles (API résidences par région/ville).
3. **Réservations à venir** : Jamais de données. Utile seulement comme CTA « Voir toutes les réservations ». À connecter à une API « prochaines réservations » si on veut afficher une vraie liste.

---

## 4. APIs backend utilisées par le dashboard

| API (DashboardService / autres) | Utilisation |
|----------------------------------|-------------|
| `GET partners/dashboard/overview` | Performance, stats (rating, bookings), overview |
| `GET partners/dashboard/finances` | Revenus (daily, weekly, monthly), bestResidences |
| `GET partners/dashboard/realtime` | Stocké dans dashboardData.realtime (usage à vérifier dans l’UI) |
| `GET partners/stats` | PartnerStats (fallback / complément) |
| `GET partners/stats/trends?period=...` | Tendances + courbe revenus |
| `getResidenceStats()` | Performance par résidence (liste) |
| `GET …/earnings` (getEarnings) | Données dans state.earningsData (usage à vérifier dans l’UI) |
| `GET /api/payouts/stats/:partnerId` (PaymentService) | Section Mes Reversements |

---

## 5. Recommandations

1. **Connecter « Réservations à venir »** : Appeler un endpoint du type `reservations?status=confirmed&from=now` (ou équivalent) et afficher les prochaines réservations au lieu d’un état vide fixe.
2. **Rendre « À faire » utile** : Raccorder les boutons (résidences, calendrier, paiements) à la navigation réelle ; éventuellement afficher/masquer selon l’état du partenaire (ex. « première résidence » si 0 résidence).
3. **Localisation** : Soit alimenter par une API (résidences par région/ville), soit retirer la section pour éviter des chiffres faux.
4. **Pricing Dynamique** : Si l’écran Pricing est branché à l’API, garder le bloc comme entrée ; sinon traiter comme décoratif ou le retirer.

---

*Document généré par analyse du code (dashboard_screen.dart, dashboard_bloc.dart, dashboard_service.dart, payment_service.dart).*
