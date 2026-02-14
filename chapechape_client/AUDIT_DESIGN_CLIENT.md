# Audit design — Application Client ChapeChape

**Date :** 10 février 2025  
**Périmètre :** Tous les écrans et widgets de `chapechape_client/lib/presentation/`  
**Critères :** Font Size, Font Weight, White Space, Line-height, Padding

---

## 1. Fondations du design system

| Élément | Fichier | Statut | Détail |
|--------|---------|--------|--------|
| **Thème** | `core/theme/app_theme.dart` | ✅ Conforme | Poppins, tailles 12–28px, **height (line-height)** défini sur tous les styles (1.2 à 1.5). |
| **Espacements** | `core/theme/spacing.dart` | ✅ Conforme | Grille 4px (xs=4, sm=8, smd=12, md=16, lg=24, xl=32, xxl=48), presets `pagePadding`, `cardPadding`, `vertical*`, `horizontal*`. |
| **Text styles** | `core/theme/text_styles.dart` | ✅ Conforme | caption, body, bodyLarge, subtitle, title, headline, display avec **height** défini. |

**Verdict :** La base est solide. Les écrans doivent **uniquement** s’appuyer sur ces tokens (Theme / AppTextStyles / AppSpacing) et ne plus utiliser de valeurs en dur.

---

## 2. Conformité par critère

### 2.1 Font Size (taille de police)

**Règle :** Aucun `fontSize: 12`, `fontSize: 16`, etc. en dur. Utiliser `Theme.of(context).textTheme.*` ou `AppTextStyles.*`.

**Écrans avec `fontSize` hardcodé (non conforme) :**

| Écran | Occurrences | Sévérité |
|-------|-------------|----------|
| full_map_screen.dart | 10 | 🔴 |
| promotion_detail_screen.dart | 6 | 🟡 |
| storage_cache_screen.dart | 6 | 🟡 |
| help_support_screen.dart | 6 | 🟡 |
| favorites_screen.dart | 5 | 🟡 |
| faq_screen.dart | 5 | 🟡 |
| onboarding_screen.dart | 4 | 🟡 |
| payment_waiting_screen.dart | 4 | 🟡 |
| payment_failed_screen.dart | 3 | 🟡 |
| payment_pending_screen.dart | 4 | 🟡 |
| register_screen.dart | 3 | 🟡 |
| server_config_screen.dart | 3 | 🟡 |
| main_screen.dart | 3 | 🟡 |
| payment_redirect_screen.dart | 3 | 🟡 |
| booking_history_screen (dossier booking/) | 3 | 🟡 |
| display_screen.dart | 2 | 🟢 |
| payment_success_screen.dart | 2 | 🟢 |
| payment_methods_screen.dart | 2 | 🟢 |
| language_screen.dart | 1 | 🟢 |
| residence_details_screen.dart | 1 | 🟢 |
| reviews_screen.dart | 1 | 🟢 |
| booking_confirmation_screen.dart | 1 | 🟢 |
| nearby_residences_screen.dart | 1 | 🟢 |
| splash_screen.dart | 1 | 🟢 |
| forgot_password_screen.dart | 4 | 🟡 |
| password_change_screen.dart | 1 | 🟢 |

**Écrans conformes (0 fontSize en dur) :**  
login_screen, home_screen, search_screen, profile_screen, wallet_screen, booking_screen, booking_history_screen (racine), notifications_screen, settings_screen, chat_screen, chat_conversation_screen, residence_details_screen (quasi), settings/* (about, storage, temperature, notification_settings), qr_code_screen, promotion_detail_screen (partiel).

---

### 2.2 Font Weight (épaisseur)

**Règle :** Pas de `fontWeight: FontWeight.bold` (ou w500, w600) dans un `TextStyle()` local. Utiliser le thème ou `AppTextStyles` qui portent déjà la graisse.

**Constat :** Plusieurs écrans définissent encore `fontWeight` dans des `TextStyle` inline (souvent avec `fontSize`). Dès qu’on remplace par `Theme.of(context).textTheme.*` ou `AppTextStyles.*`, le poids vient du design system.

**Foyers restants (nombre d’occurrences) :**  
residence_details_screen (23), payment_waiting_screen (16), help_support_screen (11), full_map_screen (6), promotion_detail_screen (8), storage_cache_screen (3), server_config_screen (3), booking (confirmation, details, history), payment_*, register_screen, forgot_password_screen, faq_screen, location_selector_screen, etc.

---

### 2.3 White Space (espace blanc — icônes / texte)

**Règle :** Pas de `SizedBox(height: 8)`, `SizedBox(width: 12)`, etc. Utiliser `AppSpacing.verticalSm`, `AppSpacing.horizontalSmd`, etc., pour cohérence et réglage centralisé.

**Écrans avec le plus de `SizedBox` hardcodés :**

| Écran | const SizedBox( | Sévérité |
|-------|------------------|----------|
| payment_waiting_screen.dart | 21 | 🔴 |
| booking_confirmation_screen.dart | 20 | 🔴 |
| register_screen.dart | 15 | 🔴 |
| payment_success_screen.dart | 16 | 🔴 |
| help_support_screen.dart | 21 | 🔴 |
| payment_pending_screen.dart | 12 | 🟡 |
| password_change_screen.dart | 9 | 🟡 |
| payment_methods_screen.dart | 9 | 🟡 |
| faq_screen.dart | 9 | 🟡 |
| full_map_screen.dart | 4 | 🟢 |
| booking_details_screen.dart | 7 | 🟡 |
| booking_history_screen (dossier) | 6 | 🟡 |
| location_selector_screen.dart | 5 | 🟡 |
| payment_failed_screen.dart | 7 | 🟡 |
| payment_redirect_screen.dart | 3 | 🟢 |
| … (autres) | 1–6 | variable |

Les écrans déjà migrés (login, home, search, profile, wallet, booking_screen, booking_history racine, notifications, settings, chat, residence_details, promotion_detail, reviews, qr_code, about_screen, settings/*) utilisent en grande partie `AppSpacing.*`.

---

### 2.4 Line-height (hauteur de ligne)

**Règle :** Tout texte multi-ligne doit avoir un `height` (line-height) défini, pour éviter un rendu “tassé”. Idéalement via le thème / AppTextStyles (déjà définis avec `height`).

**Constat :**
- `app_theme.dart` et `text_styles.dart` définissent bien `height: 1.2` à `1.5` sur tous les styles.
- Là où l’on utilise encore `TextStyle(fontSize: 14)` ou similaire **sans** `height`, le line-height par défaut Flutter (1.0) s’applique → risque de texte serré.

**Écrans/widgets avec `TextStyle` sans `height` (à migrer vers thème/AppTextStyles) :**  
Tous les fichiers listés en 2.1 et 2.2 qui construisent encore des `TextStyle` à la main. Dès qu’on passe à `Theme.of(context).textTheme.bodyMedium` (ou équivalent), le `height` du thème s’applique.

---

### 2.5 Padding

**Règle :** Pas de `EdgeInsets.all(16)`, `EdgeInsets.symmetric(horizontal: 24)`, etc. en dur. Utiliser `AppSpacing.pagePadding`, `AppSpacing.cardPadding`, ou `EdgeInsets.*` avec `AppSpacing.md`, `AppSpacing.lg`, etc.

**Écrans avec `EdgeInsets` numériques en dur :**  
storage_cache_screen, booking_history_screen, booking_screen, residence_details_screen, login_screen, register_screen, main_screen, favorites_screen, booking_status_screen, booking_modify_screen, booking_details_screen, booking_confirmation_screen, faq_screen, offline_screen, location_selector_screen, payment_redirect_screen, payment_waiting_screen, payment_webview_screen, payment_failed_screen, payment_pending_screen, full_map_screen, payment_success_screen, help_support_screen, payment_methods_screen, password_change_screen, forgot_password_screen.

Les écrans déjà refactorés utilisent `AppSpacing.*` pour la majorité des paddings.

---

## 3. Écrans sans import du design system

Les écrans suivants **n’importent pas** `spacing.dart` ni `text_styles.dart` → a priori non alignés sur le système d’espacement et de typo :

| Écran | Action recommandée |
|-------|--------------------|
| auth/register_screen.dart | Ajouter imports + remplacer fontSize/SizedBox/EdgeInsets |
| auth/forgot_password_screen.dart | Idem |
| main_screen.dart | Idem |
| splash_screen.dart | Idem |
| favorites_screen.dart | Idem |
| onboarding_screen.dart | Idem |
| booking/booking_status_screen.dart | Idem |
| booking/booking_modify_screen.dart | Idem |
| booking/booking_history_screen.dart | Idem |
| booking/booking_details_screen.dart | Idem |
| booking/booking_confirmation_screen.dart | Idem |
| faq_screen.dart | Idem |
| offline_screen.dart | Idem |
| nearby_residences/nearby_residences_screen.dart | Idem |
| location_selector_screen.dart | Idem |
| payment/payment_redirect_screen.dart | Idem |
| payment/payment_waiting_screen.dart | Idem |
| payment/payment_webview_screen.dart | Idem |
| payment/payment_failed_screen.dart | Idem |
| payment/payment_pending_screen.dart | Idem |
| payment/payment_success_screen.dart | Idem |
| full_map_screen.dart | Idem |
| help_support_screen.dart | Idem |
| payment_methods_screen.dart | Idem |
| password_change_screen.dart | Idem |

---

## 4. Couche widgets

De nombreux widgets réutilisables utilisent encore `fontSize`, `SizedBox(height: …)`, `EdgeInsets.*` en dur. Tant qu’ils ne passent pas par le thème / AppSpacing, ils propagent des incohérences sur tous les écrans qui les utilisent.

**Exemples à fort impact (nombre d’occurrences) :**
- around_me_widget.dart (57)
- featured_listings.dart (34)
- exclusive_promotions_widget.dart (33)
- special_residences_widget.dart (32)
- multilevel_location_selector.dart (31)
- popular_categories_widget.dart (30)
- blog_and_tips_widget.dart (27)
- advanced_search_widget.dart (23)
- location_selector_widget.dart (24)
- footer_widget.dart (21)
- cancellation_policy_details_widget.dart (19)
- qr_code_display_widget.dart (18)
- etc.

**Recommandation :** Après alignement des écrans, traiter les widgets les plus utilisés (home, search, residence details, booking) en priorité.

---

## 5. Synthèse par écran (top problèmes)

| Rang | Écran | fontSize | SizedBox | EdgeInsets | Design system import | Sévérité |
|------|--------|----------|----------|-----------|----------------------|----------|
| 1 | help_support_screen.dart | 6 | 21 | 6 | Non | 🔴 Critique |
| 2 | payment_waiting_screen.dart | 4 | 21 | 13 | Non | 🔴 Critique |
| 3 | booking_confirmation_screen.dart | 1 | 20 | 8 | Non | 🔴 Critique |
| 4 | register_screen.dart | 3 | 15 | 1 | Non | 🔴 Critique |
| 5 | payment_success_screen.dart | 2 | 17 | 5 | Non | 🔴 Critique |
| 6 | full_map_screen.dart | 10 | 4 | 2 | Non | 🔴 Critique |
| 7 | payment_pending_screen.dart | 4 | 12 | 6 | Non | 🟡 Important |
| 8 | password_change_screen.dart | 1 | 12 | 3 | Non | 🟡 Important |
| 9 | faq_screen.dart | 5 | 10 | 3 | Non | 🟡 Important |
| 10 | payment_methods_screen.dart | 2 | 10 | 2 | Non | 🟡 Important |
| 11 | forgot_password_screen.dart | 4 | 10 | 2 | Non | 🟡 Important |
| 12 | location_selector_screen.dart | - | 6 | 3 | Non | 🟡 Important |
| 13 | booking_details_screen.dart | - | 7 | 2 | Non | 🟡 Important |
| 14 | residence_details_screen.dart | 1 | 4 | 1 | Oui | 🟢 Partiel |
| 15 | promotion_detail_screen.dart | 6 | 5 | - | Oui | 🟢 Partiel |

*(Les comptages sont issus des recherches grep; quelques écrans déjà corrigés peuvent afficher des résidus ou des copyWith(fontSize: …) volontaires.)*

---

## 6. Checklist de conformité (par écran)

Pour chaque écran, un expert design vérifierait :

- [ ] **Font Size** : Aucun `fontSize: …` en dur ; usage de `Theme.of(context).textTheme.*` ou `AppTextStyles.*`.
- [ ] **Font Weight** : Aucun `fontWeight: …` dans un `TextStyle` local ; graisse portée par le thème / AppTextStyles.
- [ ] **White Space** : Aucun `SizedBox(height: n)` / `SizedBox(width: n)` ; usage de `AppSpacing.vertical*` / `AppSpacing.horizontal*` (ou équivalents).
- [ ] **Line-height** : Tous les textes passent par des styles qui définissent `height` (via thème / AppTextStyles).
- [ ] **Padding** : Aucun `EdgeInsets.all(16)` etc. ; usage de `AppSpacing.pagePadding`, `cardPadding`, ou constantes `AppSpacing.*`.
- [ ] **Icônes / texte** : Espacement entre icônes et texte via `SizedBox(width: AppSpacing.sm)` (ou équivalent), pas de valeurs en dur.

---

## 7. Plan d’action recommandé

1. **Priorité 1 (critique)**  
   - help_support_screen  
   - payment_waiting_screen  
   - booking_confirmation_screen  
   - register_screen  
   - payment_success_screen  
   - full_map_screen  

2. **Priorité 2 (important)**  
   - payment_pending_screen  
   - password_change_screen  
   - faq_screen  
   - payment_methods_screen  
   - forgot_password_screen  
   - location_selector_screen  
   - booking_details_screen  
   - onboarding_screen  
   - offline_screen  
   - splash_screen  
   - main_screen  
   - favorites_screen  

3. **Priorité 3 (reste des écrans)**  
   - Tous les écrans listés en section 3 sans import du design system, puis reprise des écrans partiellement conformes (residence_details, promotion_detail, etc.) pour éliminer les derniers résidus.

4. **Priorité 4 (widgets)**  
   - around_me_widget, featured_listings, exclusive_promotions_widget, special_residences_widget, popular_categories_widget, blog_and_tips_widget, advanced_search_widget, location_selector_widget, footer_widget, puis le reste.

---

## 8. Verdict global

- **Fondations (thème, spacing, text_styles) :** conformes et prêtes à l’usage.
- **Écrans déjà alignés (en tout ou partie) :** login, home, search, profile, wallet, booking_screen, booking_history racine, notifications_screen, settings_screen, chat_screen, chat_conversation_screen, residence_details_screen, promotion_detail_screen, reviews_screen, qr_code_screen, about_screen, storage_screen, display_screen, temperature_screen, language_screen, notification_settings_screen, server_config_screen, storage_cache_screen.
- **Écrans à traiter en priorité :** help_support, payment_waiting, booking_confirmation, register_screen, payment_success, full_map, puis la liste Priorité 2.
- **Line-height :** Correct partout où le thème / AppTextStyles est utilisé ; à corriger partout où un `TextStyle` manuel est encore utilisé.
- **Widgets :** À migrer progressivement après les écrans pour une cohérence complète.

En appliquant ce plan, **tous les écrans** peuvent être rendus conformes aux critères : Font Size, Font Weight, White Space, Line-height et Padding via le design system unique.
