# Analyse stricte – Erreurs release Production (Play Console)

## Contexte

**Écran :** Créer une release de production → Étape 2 « Prévisualiser et confirmer »  
**Version concernée :** versionCode **15**  
**Blocage :** « Pour enregistrer, corrigez les erreurs » → le bouton **Enregistrer** reste inactif tant que l’erreur n’est pas corrigée.

---

## 1. Erreur bloquante (1 erreur)

### Message exact

> **1 MESSAGE POUR LE CODE DE LA VERSION 15 – Erreur**  
> Votre appli ne prend pas en charge les tailles de page de mémoire de 16 ko. [En savoir plus]

### Signification technique

- À partir de **novembre 2025**, Google Play exige que les apps (et mises à jour) ciblant **Android 15 (API 35)** supportent les **pages mémoire 16 Ko**.
- Ton app a `targetSdk = 35` → elle est soumise à cette règle.
- Les binaires natifs (`.so` dans l’AAB) doivent avoir les segments ELF alignés sur **16 Ko** (0x4000). Avec l’ancien outillage (AGP &lt; 8.5.1, NDK &lt; r28), les libs Flutter/NDK sont souvent alignées sur 4 Ko uniquement → refus par la Play Console.

### Cause dans ton projet

| Fichier / élément | Valeur actuelle | Exigence Google |
|-------------------|-----------------|------------------|
| **Android Gradle Plugin** | `8.1.4` (`android/build.gradle`) | **≥ 8.5.1** (alignement ELF 16 Ko) |
| **NDK** | `25.1.8937393` (`android/app/build.gradle`) | **r28** (alignement 16 Ko par défaut) |
| **Gradle** | `7.6.1` (wrapper) | **≥ 8.5** (recommandé 8.7 pour AGP 8.5+) |
| **Java** | 11 (compileOptions / Kotlin) | **17** requis pour AGP 8.5+ |

L’erreur ne partira **pas** en cliquant sur « Continuer quand même » pour l’enregistrement : la console refuse l’enregistrement tant que l’erreur est présente.

### Correction obligatoire

1. **AGP** : passer à **8.5.1** (ou 8.7.x) dans `android/build.gradle`.
2. **Gradle** : passer le wrapper à **8.7** dans `gradle-wrapper.properties`.
3. **NDK** : passer à **r28** dans `android/app/build.gradle` (ex. `28.0.12433518` ou version installée via SDK Manager).
4. **Java** : passer à **Java 17** (sourceCompatibility / targetCompatibility et jvmTarget).
5. **Reconstruire** : `flutter clean && flutter pub get && flutter build appbundle --release`.
6. **Ré-uploader** le nouvel AAB dans la même version (versionCode 15) ou une nouvelle version.

Sans ces changements, la release **ne peut pas** être enregistrée ni envoyée en examen.

---

## 2. Avertissement (1 avertissement)

### Message exact

> **1 MESSAGE POUR LE CODE DE LA VERSION 15 – Avertissement**  
> Cet App Bundle contient du code natif, et vous n'avez pas importé de symboles de débogage. Nous vous recommandons d'importer un fichier de symboles afin de faciliter l'analyse et le débogage des plantages et des erreurs ANR. [En savoir plus]

### Signification technique

- L’AAB contient du **code natif** (moteur Flutter, plugins avec .so).
- Les **symboles de débogage** (natif : fichiers de symboles ; Dart : symboles ProGuard/mapping) permettent de désobuscater les stack traces dans la Play Console (plantages, ANR).
- **Non bloquant** : tu peux enregistrer et publier sans les importer. En revanche, en cas de crash/ANR en prod, les rapports seront plus difficiles à analyser.

### Action recommandée (après avoir corrigé l’erreur)

- **Natif :** lors de la création de la release, dans la section prévue par la Play Console, importer les **fichiers de symboles natifs** (générés dans `build/app/intermediates/...` ou équivalent selon la structure Flutter/AGP).
- **Optionnel pour une première publication :** tu peux publier sans, puis importer les symboles sur une prochaine version si tu actives les rapports de crash.

---

## 3. Synthèse

| Élément | Sévérité | Bloque enregistrement ? | Action |
|--------|----------|--------------------------|--------|
| Support 16 Ko | **Erreur** | **Oui** | Mettre à jour AGP, Gradle, NDK, Java 17, rebuild, ré-uploader l’AAB. |
| Symboles de débogage | Avertissement | Non | Recommandé : importer les symboles pour faciliter le débogage des crashes/ANR. |

---

## 4. Ordre des opérations recommandé

1. Appliquer les modifications Gradle/AGP/NDK/Java dans le repo (voir correctifs dans les fichiers concernés).
2. Installer NDK r28 via Android Studio → SDK Manager si nécessaire.
3. `flutter clean && flutter pub get && flutter build appbundle --release`.
4. Dans la Play Console : supprimer ou modifier la version brouillon actuelle, puis créer une nouvelle release avec le **nouvel AAB** (même versionCode 15 ou incrémenté).
5. Vérifier que l’erreur 16 Ko disparaît à l’étape « Prévisualiser et confirmer ».
6. Enregistrer, envoyer à l’examen, puis publier.
7. (Optionnel) Importer les symboles de débogage pour la version publiée.

---

*Document généré pour la release Production – chapechape_partner.*
