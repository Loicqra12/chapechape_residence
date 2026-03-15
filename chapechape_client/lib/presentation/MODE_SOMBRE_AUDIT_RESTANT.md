# Audit mode sombre – couleurs en dur restantes

Vérification stricte après corrections. Fichiers listés par priorité (impact sur la lisibilité en mode sombre).

---

## 1. Erreur corrigée

- **around_me_widget.dart** : `const Column` avec `Theme.of(context)` dans un enfant → `const` retiré du `Column`.

---

## 2. Fichiers corrigés dans cette session

- **main_screen.dart** : titre ville, flèche, iconTheme AppBar, icône menu, icône profil, poignée drawer, langue/localisation (icônes + textes) → `colorScheme.onSurface` / `outline`.
- **residence_card_skeleton.dart**, **residence_details_skeleton.dart**, **notification_item_skeleton.dart** : baseColor/highlightColor/containerColor/bgColor → `colorScheme.surface*`.

---

## 3. À traiter en priorité (surfaces / textes secondaires)

**Corrigés :** blog_and_tips_widget, help_support_screen, storage_screen, payment_methods_screen, booking_status_screen, location_selector_widget, location_selector_screen, payment_timer_widget, payment_webview_screen, price_range_slider_widget, multilevel_location_selector, multi_level_location_selector, animated_search_field, date_range_picker_widget, qr_code_screen, qr_code_display_widget, advanced_search_widget.

| Fichier | Occurrences |
| **residence/availability_checker_widget.dart** | grey[300/400/600], border, Colors.white (badge) |
| **residence_card.dart** | black54, grey[600], Colors.white (overlays) |
| **payment_screen.dart** | isDisabled ? grey[600] : white |
| **offline_screen.dart** | fillColor grey.shade50, color grey.shade600 |
| **wallet_screen.dart** | unselectedLabelColor black54, color black54 |
| **booking_history_screen.dart** | unselectedLabelColor black54, grey[400] |
| **search_destination_screen.dart** | backgroundColor white, grey[100] |
| **full_map_screen.dart** | foregroundColor black54 |
| **reservation/reservation_timer_widget.dart** | Color(0xFF...) pour thèmes d’urgence, grey[300/100/400/500/600/700] |
| **testimonials_widget.dart** | grey[600] |
| **common/empty_state_widget.dart** | Color(0xFF2C3E50), grey[400/600] |
| **country_flag_widget.dart** | Colors.grey (fallback) |
| **chat/message_bubble.dart** | white70, black54, grey.shade300 (contenu bulle) |
| **categories_menu_widget.dart** | black87, Color(0xFF...), grey.shade50/200/800 |
| **common/watermark_widget.dart** | black54 |
| **bottom_nav_bar.dart** | black12 |
| **storage_cache_screen.dart** | grey[600] |

---

## 4. Shimmer / placeholders (à harmoniser avec le thème)

- **featured_listings.dart** : baseColor/highlightColor grey[300/100], grey[200/400/600], Containers white
- **shimmer_residence_card.dart** : baseColor/highlightColor grey[300/100], Containers white
- **recommended_residences_widget.dart** : idem + Containers white
- **tendances_widget.dart** : Containers white (skeleton)

---

## 5. Couleurs volontaires (à garder ou adapter au thème)

- **footer_widget.dart** : `Color(0xFFD4AF37)` (or) – cohérent avec la charte.
- **booking_details_screen.dart** : `Color(0xFFD69E2E)`, `Color(0xFFE53E3E)` pour statuts – sémantique.
- **residence_details_screen.dart** : `Color(0xFFF0F0F0)` placeholder, `Color(0xFF...)` pour badges (vert/rouge/etc.) – à remplacer par `colorScheme.surface*` pour les fonds si souhaité.
- **stats_bar.dart** : `Color(0xFFFFD93D)`, `Color(0xFFFF8C42)` – couleurs de données.
- **categories_menu_widget.dart** : palettes `Color(0xFFFF6B6B)` etc. – couleurs de catégories.
- **common/premium_card.dart** : `Color(0xFF2C2C2C)` / white selon isDarkMode – déjà adapté au mode sombre.

---

## 6. Texte / icônes blancs sur overlay (souvent volontaires)

Ces usages sont en général corrects (contraste sur image/dégradé) ; à ne changer que si le fond n’est plus sombre en thème clair/sombre :

- **residence_details_screen.dart** : texte/icônes blancs sur AppBar / gradient.
- **home_compact_sections.dart**, **residence_card.dart**, **featured_listings.dart**, **tendances_widget.dart**, **popular_categories_widget.dart** : texte blanc sur dégradé ou badge.
- **hero_widget.dart**, **main_screen.dart** (overlay accueil) : texte blanc sur fond sombre.
- **faq_screen.dart** : icône + titre blancs (bannière).
- **booking_confirmation_screen.dart**, **password_change_screen.dart**, **notifications_screen.dart** : icônes blanches sur bouton/badge.

---

## 7. Recommandations

1. Traiter en priorité la section **3** (surfaces, bordures, textes secondaires) pour une bonne lisibilité en mode sombre.
2. Remplacer les **shimmer / placeholders** (section 4) par `Theme.of(context).colorScheme.surfaceContainerHighest` / `surface` (ou équivalent).
3. Laisser les couleurs sémantiques (section 5) telles quelles, sauf si tu veux tout basculer sur le thème.
4. Ne pas toucher aux textes/icônes blancs sur overlay (section 6) sauf si le design change.

---

*Généré après vérification stricte des `Colors.grey`, `Colors.black*`, `Color(0xFF...)`, `fillColor`/`backgroundColor` dans `lib/presentation`.*
