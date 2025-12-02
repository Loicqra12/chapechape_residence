# Architecture Decision Records (ADRs)

Ce dossier contient les décisions architecturales importantes prises pour le projet ChapeChape Residence Backend.

## Format

Chaque ADR suit le format standard :
- **Statut** : Accepté / Proposé / Dépublié
- **Date** : Date de la décision
- **Décideurs** : Personnes ayant pris la décision
- **Tags** : Mots-clés pour recherche

## Liste des ADRs

### ADR-001: Architecture Monolithique Modulaire
Décision d'utiliser une architecture monolithique modulaire avec organisation par domaines métier.

### ADR-002: Authentification JWT avec Refresh Tokens
Implémentation d'un système d'authentification JWT avec refresh tokens et rotation des clés.

### ADR-003: Gestion des Paiements Multi-Providers
Architecture de paiements supportant plusieurs providers (CinetPay, Wave, Stripe).

### ADR-004: Système de Réservations avec Timers
Implémentation d'un système de réservations avec timers automatiques pour paiement et approbation.

### ADR-005: Architecture de Services Modulaires
Séparation en couches : Contrôleurs → Services → Modèles.

## Comment créer un nouvel ADR

1. Créer un fichier `XXX-titre-en-kebab-case.md`
2. Suivre le format des ADRs existants
3. Numéroter séquentiellement
4. Ajouter une entrée dans ce README

## Références

- [ADR Template](https://adr.github.io/)
- [Documenting Architecture Decisions](https://cognitect.com/blog/2011/11/15/documenting-architecture-decisions)






