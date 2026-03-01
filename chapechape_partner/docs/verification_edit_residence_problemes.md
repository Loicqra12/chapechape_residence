# Vérification des Problèmes dans Edit Residence Screen

## Date: 2026-02-17

### Problème 1: Client App - Recherche par "Dates" inadaptée aux résidences horaires

**Statut**: ✅ **CONFIRMÉ**

**Localisation**: 
- `chapechape_client/lib/presentation/widgets/advanced_search_widget.dart` (lignes 295-325)
- `chapechape_client/lib/presentation/widgets/date_range_picker_widget.dart`

**Problème identifié**:
- Le widget `DateRangePickerWidget` utilise un calendrier avec sélection de dates de début/fin (`DateTimeRange`)
- Ce système est adapté pour les réservations journalières/semaines/mois
- **MAIS** pour les résidences horaires (`pricePeriod: 'hour'`), il faudrait plutôt :
  - Une sélection de date + heure de début
  - Une sélection de durée (1h, 2h, 3h+) ou heure de fin
  - Comme dans `FlexibleBookingDateSelector` (lignes 111-124)

**Impact**:
- Les utilisateurs ne peuvent pas rechercher efficacement des résidences horaires
- La recherche envoie des `checkIn`/`checkOut` complets, mais l'interface ne permet pas de sélectionner des heures précises
- Les résidences horaires sont mal filtrées dans les résultats

**Solution recommandée**:
- Adapter `DateRangePickerWidget` pour détecter si on recherche des résidences horaires
- Ou créer un widget conditionnel qui affiche soit le calendrier (dates) soit le sélecteur horaire selon le contexte

---

### Problème 2: Partner App - Types de résidences manquants dans le mapping tarifaire

**Statut**: ✅ **CONFIRMÉ - 17 types manquants**

**Localisation**: 
- `chapechape_partner/lib/presentation/screens/residences/edit_residence_screen.dart`
- Méthode `_getExpectedPricePeriodForType()` (lignes 2655-2685)

**Types définis dans `_residenceCategories`** (29 types au total):

#### Catégorie "residence_meublee" (6 types):
1. ✅ `studio_meuble` → 'day' (présent ligne 2663)
2. ❌ `appartement_meuble` → **MANQUANT** (devrait être 'day' ou 'month')
3. ❌ `villa_meublee` → **MANQUANT** (devrait être 'day' ou 'month')
4. ❌ `penthouse` → **MANQUANT** (devrait être 'day' ou 'month')
5. ❌ `loft` → **MANQUANT** (devrait être 'day' ou 'month')
6. ❌ `grenier` → **MANQUANT** (devrait être 'day' ou 'month')

#### Catégorie "hotel" (6 types):
7. ✅ `hotel_passage` → 'hour' (présent ligne 2657)
8. ✅ `motel` → 'hour' (présent ligne 2657)
9. ❌ `boutique_hotel` → **MANQUANT** (présent ligne 2669 mais avec nom incorrect 'boutiqueHotel')
10. ❌ `hotel_luxe` → **MANQUANT** (devrait être 'day')
11. ✅ `guest_house` → 'day' (présent ligne 2664)
12. ❌ `residence_hoteliere` → **MANQUANT** (devrait être 'day' ou 'month')

#### Catégorie "hebergement_insolite" (5 types):
13. ❌ `bungalow` → **MANQUANT** (devrait être 'day')
14. ✅ `lodge` → 'day' (présent ligne 2665)
15. ✅ `case_traditionnelle` → 'day' (présent ligne 2666)
16. ✅ `maison_flottante` → 'day' (présent ligne 2668)
17. ✅ `campement_touristique` → 'day' (présent ligne 2667)

#### Catégorie "colocation" (5 types):
18. ❌ `chambre_colocation` → **MANQUANT** (devrait être 'month')
19. ❌ `coliving` → **MANQUANT** (devrait être 'month')
20. ❌ `maison_hotes` → **MANQUANT** (présent ligne 2670 mais avec nom incorrect 'aubergeEtMaisonDHotes')
21. ❌ `residence_universitaire` → **MANQUANT** (devrait être 'month')
22. ❌ `cite_dortoir` → **MANQUANT** (devrait être 'month')

#### Catégorie "residence_longue_duree" (4 types):
23. ❌ `appartement_vide` → **MANQUANT** (devrait être 'month')
24. ❌ `villa_vide` → **MANQUANT** (devrait être 'month')
25. ❌ `immeuble` → **MANQUANT** (devrait être 'month')
26. ❌ `cour_commune` → **MANQUANT** (devrait être 'month')

#### Catégorie "hebergement_economique" (3 types):
27. ✅ `maison_hotes_economique` → 'week' (présent ligne 2677)
28. ✅ `residence_familiale` → 'week' (présent ligne 2678)
29. ✅ `chambres_passage` → 'hour' (présent ligne 2657)

**Résumé**:
- ✅ Types couverts: 12 types (studio_meuble, hotel_passage, motel, guest_house, lodge, case_traditionnelle, campement_touristique, maison_flottante, maison_hotes_economique, residence_familiale, chambres_passage, + 2 avec noms incorrects)
- ❌ Types manquants: **17 types** (confirmé)
- ⚠️ Noms incorrects: 'boutiqueHotel' au lieu de 'boutique_hotel', 'aubergeEtMaisonDHotes' au lieu de 'maison_hotes'

**Impact**:
- Les types manquants utilisent tous la période par défaut ('month')
- Cela peut être incorrect pour certains types qui devraient être facturés à l'heure ou à la journée
- Les partenaires doivent manuellement ajuster la période de facturation au lieu d'avoir une suggestion automatique

**Solution recommandée**:
- Compléter `_getExpectedPricePeriodForType()` avec tous les 29 types
- Corriger les noms incorrects ('boutiqueHotel' → 'boutique_hotel', 'aubergeEtMaisonDHotes' → 'maison_hotes')
- Ajouter les mappings manquants selon la logique métier appropriée
