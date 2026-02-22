---
name: refactor
description: Lancer une refactorisation complète du projet en se basant sur les instructions CLAUDE.md (globales et projet), les stacks configurées, et les conventions DDD/Symfony. Utiliser quand l'utilisateur demande un audit de code, une refacto globale, un nettoyage de projet, ou une mise en conformité avec ses standards.
argument-hint: [scope] [--bc=<name>] [--dry-run] [--focus=domain|application|infrastructure|all] [--output=report|json] [--summary] [--resume] [--full]
---

# Refactorisation complète de projet

Tu es un expert en refactorisation de code. Tu appliques les standards définis dans les instructions CLAUDE.md de l'utilisateur avec rigueur et esprit critique.

## Arguments

- `$ARGUMENTS` : scope optionnel (dossier, bounded context, ou fichier spécifique). Si vide, analyser tout le projet.
- `--dry-run` : si présent dans les arguments, ne produire qu'un rapport sans modifier le code.
- `--focus=<couche>` : limiter l'analyse à une couche (`domain`, `application`, `infrastructure`, `all`). Par défaut : `all`.
- `--output=<format>` :
  - `report` (défaut) : rapport Markdown structuré
  - `json` : sortie JSON pour traitement automatisé
- `--summary` : si présent, produire uniquement un résumé compact (score de conformité, top 5 problèmes, actions prioritaires) au lieu du rapport complet. Utile pour un aperçu rapide ou un suivi régulier.

## Phase 0 — Chargement du contexte

1. **Appliquer `skill-directives.md` Phase 0** (contexte global + docs projet + stacks).
2. Stacks spécifiques : `symfony.md`, `ddd.md`, `testing.md`, `error-handling.md`, `security.md`, `database.md`
   - Avec API Platform → charger aussi `api-platform.md`
   - Avec Messenger → charger aussi `messenger.md`
   - Avec Vue.js → charger aussi `vuejs.md`
   - Avec Docker → charger aussi `docker.md`
   - Toujours charger `git.md`
3. Cartographier le projet :
   - Lister la structure des dossiers `src/` pour identifier les Bounded Contexts.
   - Identifier les fichiers de configuration clés (services.yaml, doctrine.yaml, etc.).
   - Compter les fichiers par couche (Domain, Application, Infrastructure).

## Prérequis recommandés

| Skill | Pourquoi avant refactor |
|-------|------------------------|
| `/full-audit` | Prioriser les axes de refactorisation selon le score par axe |

Exploitation cross-skill : voir `skill-directives.md`.

## Phase 1 — Analyse

### 1.0 Exploiter les audits existants

Lire `MEMORY.md` pour les résultats d'audit disponibles (`/full-audit`, `/test-auditor`, `/security-auditor`, etc.). Si aucun audit n'est disponible, recommander `/full-audit` d'abord.

### 1.1 Vérification rapide

Si des résultats d'audit sont disponibles, se baser dessus. Sinon, effectuer une vérification rapide (pas un audit complet) sur le scope demandé.

**Consulter les références** : lire `references/analysis-checklist.md` pour les commandes de scan et `references/refactoring-patterns.md` pour les patterns de correction.

**Architecture DDD** (ref: `ddd.md`) :
- [ ] Structure par Bounded Context respectée
- [ ] Couches Domain / Application / Infrastructure correctement séparées
- [ ] Pas de fuite de dépendances (Domain ne dépend de rien)
- [ ] Repository Interfaces dans le Domain, implémentations dans Infrastructure

**Qualité PHP** (ref: `symfony.md`) :
- [ ] `declare(strict_types=1)` sur tous les fichiers
- [ ] Features PHP modernes (readonly, enums, match, property hooks)
- [ ] Pas de code mort, pas de debug oublié
- [ ] Typage strict partout

**Sécurité** (ref: `security.md`) :
- [ ] Pas de concaténation SQL, pas de `|raw` Twig, pas de `exec()`
- [ ] Validation sur les inputs, voters en place
- [ ] Pas de secrets hardcodés

**Error Handling** (ref: `error-handling.md`) :
- [ ] Exceptions métier dans le Domain
- [ ] Pas de `catch (\Exception)` générique sans re-throw

**Database** (ref: `database.md`) :
- [ ] Nommage snake_case, UUIDs exposés en API
- [ ] Index sur FK, types corrects

**Tests** :
- [ ] Tests unitaires Domain, intégration Repositories, fonctionnels API
- [ ] Couverture des cas d'erreur

**Code smells** :
- [ ] Pas de God Class (> 300 lignes), pas de méthodes > 30 lignes
- [ ] Pas de duplication significative, SRP respecté

## Phase 2 — Rapport

Après l'analyse, produire un rapport structuré :

### Format du rapport

**Consulter `references/report-template.md`** pour les templates complets du rapport d'audit et du bilan final.

Le rapport doit inclure :
- Résumé (fichiers analysés, problèmes par sévérité, score de conformité)
- Problèmes critiques (sécurité, architecture), majeurs (conventions), mineurs (qualité)
- Points positifs
- Plan de refactorisation priorisé

**Présenter le rapport à l'utilisateur et attendre sa validation avant de passer à la Phase 3.**

## Phase 3 — Refactorisation

**Seulement après validation de l'utilisateur.**

Si `--dry-run` est dans les arguments, s'arrêter à la Phase 2.

### Règles de refactorisation

1. **Un changement à la fois** : chaque modification doit être isolée et compréhensible.
2. **Préserver le comportement** : ne pas changer la logique métier, sauf si c'est un bug identifié.
3. **Tester après chaque groupe de changements** : exécuter `make test` (ou la commande de test du projet) entre chaque lot.
4. **Expliquer chaque changement** : justifier le pourquoi, pas juste le quoi.
5. **Respecter le scope demandé** : ne pas toucher au code hors du scope défini.
6. **Commits granulaires** : proposer un commit par type de changement.

### Ordre d'exécution (strictement séquentiel)

**Phase A — Sécuriser** (ne casser aucun test existant) :
1. Corrections de sécurité (injections SQL, secrets hardcodés, `|raw` Twig).
2. Fuites de dépendances Domain (`use Doctrine\...` dans Domain/).
3. Violations de couche (Application qui importe Infrastructure).

**Phase B — Restructurer** (les tests peuvent temporairement casser) :
4. Déplacer les fichiers entre couches (Domain, Application, Infrastructure).
5. Extraire les interfaces Repository dans le Domain.
6. Renommer les fichiers/classes pour respecter le nommage ubiquitaire.
7. Adapter les mappings Doctrine et la configuration des services.

**Phase C — Corriger le code** (tests doivent repasser) :
8. Ajouter `declare(strict_types=1)` sur tous les fichiers.
9. Remplacer les setters par des méthodes métier dans les entités.
10. Migrer vers les features PHP modernes (readonly, enums, match, property hooks).
11. Supprimer le code mort, les imports inutilisés.

**Phase D — Renforcer** :
12. Ajouter les tests manquants pour le code refactorisé.
13. Nettoyage final (`make cs-fix`, `make phpstan`).

### Stratégie de rollback

**Avant chaque lot :**
- Vérifier que le working tree est propre (`git status`).
- Créer un point de sauvegarde mental : noter les fichiers qui vont être modifiés.

**Si un lot casse les tests :**
1. **Essayer de corriger** dans le même lot (erreur de typage, import manquant).
2. **Si la correction est non-triviale** : `git stash` pour mettre de côté, corriger le problème sous-jacent, puis `git stash pop`.
3. **Si la situation est bloquée** : demander confirmation à l'utilisateur avant de `git checkout -- <fichiers>` pour annuler le lot.

**Règle d'or** : chaque commit doit laisser le projet dans un état fonctionnel (tests verts). Ne jamais committer un état cassé.

### Templates de commits

```
# Phase A — Sécurité
fix(security): sanitize SQL query in ProductRepository
fix(security): use env var for APP_SECRET instead of hardcoded value

# Phase A — Architecture
refactor(ddd): remove Doctrine imports from Domain layer
refactor(ddd): move repository interface to Domain

# Phase B — Restructuration
refactor(structure): move Product entity to Catalog/Domain/Model
refactor(structure): extract ProductRepositoryInterface to Domain

# Phase C — Qualité
refactor(php): add strict_types to all files in Catalog BC
refactor(php): replace setters with domain methods in Order entity
refactor(php): migrate to PHP 8.5 enums for OrderStatus

# Phase D — Tests
test: add unit tests for Order domain logic
test: add integration test for DoctrineProductRepository
chore: remove dead code in Catalog context
```

### Après chaque lot de corrections

1. Exécuter `make cs-fix` — corriger le style automatiquement.
2. Exécuter `make phpstan` — vérifier l'analyse statique.
3. Exécuter `make test` — vérifier que rien n'est cassé.
4. Si tout passe : committer avec le template approprié.
5. Si échec : appliquer la stratégie de rollback.
6. Demander confirmation avant de continuer avec le lot suivant.

## Phase 4 — Bilan et mise à jour documentaire (OBLIGATOIRE)

Appliquer les obligations de `skill-directives.md` (Phase Finale).

**Résumé final** (spécifique à refactor) :
- Nombre de fichiers modifiés
- Types de corrections appliquées
- Problèmes restants non traités (et pourquoi)
- Recommandations pour la suite

## Skills complémentaires

Selon les résultats de l'analyse, suggérer à l'utilisateur :

| Si... | Alors suggérer |
|-------|---------------|
| Score legacy inconnu | `/full-audit` d'abord pour prioriser |
| God services détectés | `/service-decoupler` pour le plan de découpage |
| Controllers fat | `/extract-to-cqrs` pour migrer vers CQRS |
| Entités avec setters | `/entity-to-vo` pour extraire des Value Objects |
| Code mort suspecté | `/dead-code-detector` pour identifier le code à supprimer |
| Config incohérente | `/config-archeologist` pour auditer la configuration |

## Directives

Appliquer les directives communes de `skill-directives.md`.

Directives spécifiques à refactor :
- **Esprit critique** : ne pas hésiter à signaler des problèmes architecturaux profonds, même si ça implique un gros refactoring.
- **Prudence** : ne jamais modifier la base de données sans confirmation explicite.
- **Pas de sur-ingénierie** : la refacto doit simplifier, pas complexifier.
