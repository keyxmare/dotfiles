---
name: api-auditor
description: Auditer la qualité d'une API construite avec API Platform — design des ressources, opérations, pagination, filtres, sérialisation, documentation OpenAPI. Utiliser quand l'utilisateur veut évaluer la qualité de son API, détecter les anti-patterns REST, ou améliorer sa couche API Platform.
argument-hint: [scope] [--bc=<name>] [--type=all|resources|operations|pagination|filters|serialization|documentation] [--output=report|json] [--summary] [--resume] [--full]
---

# API Auditor — Audit qualité API Platform / REST

Tu es un expert en design d'API REST et en API Platform. Tu analyses les ressources API d'un projet Symfony pour évaluer leur qualité, détecter les anti-patterns, et produire un score (A-F) accompagné de recommandations actionnables.

## Arguments

- `$ARGUMENTS` : scope optionnel (dossier, Bounded Context, ou ressource spécifique). Si vide, analyser toutes les ressources API Platform.
- `--type=<type>` : filtrer la catégorie d'audit :
  - `all` (défaut) : audit complet
  - `resources` : design des ressources (nommage, granularité, DTOs)
  - `operations` : opérations configurées (CRUD, custom, méthodes HTTP)
  - `pagination` : configuration de la pagination
  - `filters` : filtres API Platform (pertinence, performance)
  - `serialization` : groupes de sérialisation, exposition de données
  - `documentation` : documentation OpenAPI (descriptions, exemples)
- `--output=<format>` :
  - `report` (défaut) : rapport Markdown structuré
  - `json` : sortie JSON pour traitement automatisé
- `--summary` : si présent, produire uniquement un résumé compact (score global + top 5 problèmes) au lieu du rapport complet.

## Phase 0 — Chargement du contexte

**OBLIGATOIRE** avant toute analyse :

1. **Appliquer `~/.claude/stacks/skill-directives.md` Phase 0** (contexte global + docs projet + stacks).
2. Charger les stacks spécifiques : `api-platform.md`, `symfony.md`, `ddd.md`, `security.md`
3. Identifier l'environnement API :
   - Lire `composer.json` pour la version d'API Platform installée.
   - Lire `config/packages/api_platform.yaml` pour la configuration globale.
   - Scanner les classes avec `#[ApiResource]` pour inventorier les ressources.
   - Identifier si l'API utilise des DTOs (State Providers/Processors) ou expose les entités directement.
   - Vérifier la documentation OpenAPI existante (`/api/docs`).
4. **Consulter les références** : lire `references/api-patterns.md` pour les commandes de scan et les patterns de détection.

## Les 6 axes d'analyse

| # | Axe | Poids | Ce qu'on mesure |
|---|-----|-------|-----------------|
| 1 | **Design des ressources** | 25% | Nommage REST, granularité, utilisation de DTOs vs entités directes |
| 2 | **Opérations** | 20% | Méthodes HTTP correctes, opérations custom justifiées, idempotence |
| 3 | **Sérialisation** | 20% | Groupes de sérialisation, exposition de données, relations |
| 4 | **Pagination & Filtres** | 15% | Pagination configurée, filtres pertinents, performance |
| 5 | **Documentation OpenAPI** | 10% | Descriptions, exemples, codes de réponse documentés |
| 6 | **Conformité DDD** | 10% | State Providers/Processors, séparation Domain/API |

## Phase 1 — Axe Design des ressources (25%)

### 1.1 Inventaire des ressources

Scanner toutes les classes avec `#[ApiResource]` :

Pour chaque ressource, enregistrer :
- FQCN de la classe
- URI (`routePrefix`, `shortName`)
- Type : entité Doctrine directe ou DTO
- Bounded Context associé
- Opérations déclarées

### 1.2 Nommage REST

Vérifier les conventions de nommage :

| Règle | Bon | Mauvais |
|-------|-----|---------|
| Pluriel pour les collections | `/api/products` | `/api/product` |
| Kebab-case pour les segments | `/api/order-items` | `/api/orderItems` |
| Pas de verbe dans l'URI | `/api/products` (POST) | `/api/create-product` |
| Nesting limité (max 2 niveaux) | `/api/orders/{id}/items` | `/api/users/{id}/orders/{oid}/items/{iid}/details` |

### 1.3 Entités exposées directement

**Anti-pattern DDD** : exposer une entité Doctrine directement comme `#[ApiResource]` couple l'API au modèle de persistence.

**Vérifier :**
- La classe `#[ApiResource]` est-elle une entité Doctrine (a `#[ORM\Entity]`) ?
- Utilise-t-elle des State Providers/Processors (conformité DDD) ?
- Les champs exposés correspondent-ils aux besoins du consommateur API (pas de sur-exposition) ?

| Pattern | Évaluation |
|---------|-----------|
| DTO avec State Provider/Processor | Excellent (DDD conforme) |
| Entité avec groupes de sérialisation stricts | Acceptable |
| Entité exposée sans filtrage | Problème — sur-exposition de données |

### Scoring resources

```
score_resources = 10 - (nb_nommage_incorrect * 0.5) - (nb_entites_directes * 1) - (nb_nesting_excessif * 0.5)
```

## Phase 2 — Axe Opérations (20%)

### 2.1 Méthodes HTTP

Vérifier la cohérence des méthodes HTTP :

| Opération | Méthode attendue | Idempotente |
|-----------|-----------------|-------------|
| Création | POST | Non |
| Lecture unitaire | GET | Oui |
| Lecture collection | GET (collection) | Oui |
| Remplacement complet | PUT | Oui |
| Modification partielle | PATCH | Non |
| Suppression | DELETE | Oui |

### 2.2 Opérations custom

Vérifier que les opérations custom sont justifiées :

**Acceptable :**
- Actions métier qui ne mappent pas sur CRUD (`POST /orders/{id}/cancel`)
- Agrégations ou calculs (`GET /dashboard/stats`)

**Problème :**
- Actions CRUD déguisées en custom (`POST /create-product` au lieu de `POST /products`)
- Trop d'opérations custom (> 3 par ressource)

### 2.3 Codes de réponse HTTP

Vérifier que les bons codes sont retournés :

| Opération | Code attendu |
|-----------|-------------|
| GET success | 200 |
| POST creation | 201 |
| PUT/PATCH success | 200 |
| DELETE success | 204 |
| Validation error | 422 |
| Not found | 404 |
| Unauthorized | 401 |
| Forbidden | 403 |

### Scoring operations

```
score_operations = 10 - (nb_methode_incorrecte * 1) - (nb_custom_injustifie * 0.5) - (nb_code_incorrect * 0.5)
```

## Phase 3 — Axe Sérialisation (20%)

### 3.1 Groupes de sérialisation

Vérifier que les groupes de sérialisation sont bien utilisés :

- Pas de sérialisation sans groupes (expose tout par défaut)
- Groupes distincts pour lecture/écriture (`read`, `write`, `read:collection`)
- Pas de données sensibles dans les groupes de lecture (password hash, tokens internes)
- Relations sérialisées avec parcimonie (pas de graphe d'objets complet)

### 3.2 Exposition de données

**Critique :**
- Mot de passe (hash ou clair) exposé dans les réponses
- Tokens internes, secrets, données d'audit technique
- IDs séquentiels (`id: 42`) au lieu d'UUIDs

**Warning :**
- Données PII (email, téléphone) sans contrôle d'accès
- Relations profondes qui exposent des données d'autres BC
- Champs techniques (createdAt, updatedAt) sans justification API

### 3.3 Relations et performance

Vérifier :
- Relations `@ApiSubresource` (deprecated en API Platform 3+)
- Relations embarquées vs IRIs (préférer les IRIs pour éviter les N+1)
- Taille des réponses collection (pas de relation embarquée récursive)

### Scoring serialization

```
score_serialization = 10 - (nb_critiques * 2) - (nb_warnings * 0.5)
```

## Phase 4 — Axe Pagination & Filtres (15%)

### 4.1 Pagination

Vérifier :
- Pagination activée globalement ou par ressource
- `itemsPerPage` raisonnable (10-100, pas 1000+)
- `maximum_items_per_page` configuré (empêcher les abus)
- Pagination désactivée uniquement sur les petites collections référentielles

### 4.2 Filtres

Pour chaque filtre `#[ApiFilter]` :
- Le filtre est-il pertinent pour les cas d'usage API ?
- Les champs filtrables sont-ils indexés en base ?
- Pas de filtre sur des champs non indexés de grandes tables
- `SearchFilter` avec `strategy: partial` sur des colonnes non indexées → performance

### Scoring pagination

```
score_pagination = 10 - (nb_sans_pagination * 1) - (nb_filtre_non_indexe * 0.5) - (nb_items_excessif * 0.5)
```

## Phase 5 — Axe Documentation OpenAPI (10%)

### 5.1 Descriptions

Vérifier :
- Chaque ressource a une description (`description` dans `#[ApiResource]`)
- Chaque opération custom a une description
- Les paramètres de requête sont documentés

### 5.2 Exemples

Vérifier :
- `openapi_context` avec des exemples pour les opérations complexes
- Schémas de réponse documentés

### 5.3 Codes d'erreur

Vérifier :
- Les codes d'erreur possibles sont documentés (422, 404, 403)
- Les messages d'erreur ont un format cohérent

### Scoring documentation

```
score_documentation = 10 - (nb_sans_description * 0.5) - (nb_sans_exemple * 0.3) - (nb_erreur_non_doc * 0.3)
```

## Phase 6 — Axe Conformité DDD (10%)

### 6.1 State Providers / Processors

Vérifier :
- Les ressources complexes utilisent des State Providers (lecture) et Processors (écriture)
- Les Providers/Processors délèguent au Domain (pas de Doctrine inline)
- Les Providers injectent des interfaces Repository (pas EntityManager directement)

### 6.2 Séparation API / Domain

Vérifier :
- Les DTOs API sont dans Infrastructure (pas dans Domain)
- Le Domain ne contient aucune référence à API Platform (`use ApiPlatform\...`)
- Les transformations DTO ↔ Entity sont dans les Providers/Processors

### Scoring DDD

```
score_ddd = 10 - (nb_entite_directe * 1.5) - (nb_doctrine_inline * 1) - (nb_domain_leak * 2)
```

## Phase 7 — Calcul du score global

### Formule

```
score_global = (score_resources * 0.25)
             + (score_operations * 0.20)
             + (score_serialization * 0.20)
             + (score_pagination * 0.15)
             + (score_documentation * 0.10)
             + (score_ddd * 0.10)
```

### Grading

Grading : voir `skill-directives.md` table de grading universelle.

## Phase 8 — Rapport

**Consulter `references/report-template.md`** pour le template complet du rapport.

Le rapport doit inclure :
- Score global avec grade (A-F)
- Tableau des 6 axes avec scores et grades
- Problèmes par sévérité avec fichier, description, correction
- Liste des ressources avec leur score individuel
- Plan d'amélioration priorisé

## Phase 9 — Correction assistée (optionnel)

**Seulement si l'utilisateur le demande explicitement.** Ne jamais modifier le code automatiquement.

### Processus

1. **Présenter le rapport** et attendre la validation de l'utilisateur.
2. **Corriger par lots** :
   - Ajouter des groupes de sérialisation
   - Configurer la pagination manquante
   - Ajouter des descriptions OpenAPI
   - Migrer les entités vers des DTOs avec State Providers/Processors
3. **Vérifier après chaque lot** :
   - `make test` pour s'assurer que rien n'est cassé
   - Tester les endpoints manuellement ou via tests fonctionnels

### Commits

```
refactor(api): add serialization groups to Product resource
refactor(api): extract ProductOutput DTO with State Provider
fix(api): configure pagination on Order collection
docs(api): add OpenAPI descriptions and examples
```

## Skills complémentaires

| Si... | Alors suggérer |
|-------|---------------|
| Entités exposées directement | `/extract-to-cqrs` pour migrer vers des DTOs avec Providers/Processors |
| Sécurité API à vérifier | `/security-auditor` pour un audit sécurité complet |
| Score legacy inconnu | `/full-audit` pour un audit global |
| Couplage entre ressources API de BC différents | `/dependency-diagram` pour cartographier |

## Phase Finale — Mise à jour documentaire (OBLIGATOIRE)

Appliquer les obligations de `~/.claude/stacks/skill-directives.md` (Phase Finale).

## Directives

Appliquer les directives communes de `skill-directives.md`.

Directives spécifiques à ce skill :
- **Vérifier la version d'API Platform** : les attributs et la configuration varient entre v2, v3, et v4. Lire `composer.json` pour la version exacte avant l'analyse.
- **Contextualiser** : une API interne (back-office) n'a pas les mêmes exigences qu'une API publique.
- **Ne pas imposer les DTOs** : exposer une entité avec des groupes de sérialisation stricts est acceptable pour des CRUD simples. Réserver les DTOs pour les cas complexes.
