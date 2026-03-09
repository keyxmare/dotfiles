---
name: test-gen
description: Generates targeted tests (unit, integration, e2e) for existing code
allowed-tools: Bash(git *), Bash(make *), Bash(docker compose *), Read, Write, Edit, Glob, Grep, Agent, mcp__context7__resolve-library-id, mcp__context7__query-docs
---

# Skill — Test Generation

Tu génères des tests ciblés pour du code existant.

## Input

`$ARGUMENTS` peut être :
- Un chemin de fichier (ex: `src/Catalog/Application/Command/CreateProductHandler.php`)
- Un chemin de dossier (ex: `src/Order/Domain/`)
- Un type de test en suffixe : `unit`, `integration`, `e2e` (ex: `src/Catalog/ unit`)
- Rien → analyser la couverture et cibler les zones non couvertes

## Process

### 1. Analyse

Lire le code cible et identifier :
- La couche DDD (Domain, Application, Infrastructure, Presentation)
- Les comportements à tester (cas nominaux, erreurs, limites)
- Les dépendances à mocker
- Les tests existants pour éviter la duplication

Déterminer le type de test approprié selon la couche :
| Couche | Type par défaut | Framework |
|--------|----------------|-----------|
| Domain (entités, VO) | Unit | Pest |
| Application (handlers) | Unit | Pest |
| Infrastructure (repos) | Integration | Pest |
| Presentation (controllers) | Integration | Pest |
| Frontend (composables, stores) | Unit | Vitest |
| Frontend (pages) | E2E | Playwright |

### 2. Génération

Pour chaque classe/fonction ciblée, générer :

**Cas nominaux** — Le happy path avec des données valides
**Cas d'erreur** — Inputs invalides, exceptions attendues, états limites
**Cas limites** — Valeurs vides, nulls, collections vides, bornes numériques

Conventions :
- Pest : `it('should <comportement>', function () { ... })`
- Vitest : `it('should <comportement>', () => { ... })`
- Un fichier de test par classe source
- Nommage : `<Classe>Test.php` ou `<fichier>.spec.ts`
- Structure : Arrange / Act / Assert (pas de commentaires AAA)

### 3. Vérification

```bash
make test
```

- Tous les tests générés passent
- Les tests existants ne sont pas cassés
- Pas de tests fragiles (pas de sleep, pas de dépendance à l'ordre)

### 4. Couverture

Si disponible, vérifier que la couverture atteint le seuil (80%) sur les fichiers ciblés.

Résumer : nombre de tests ajoutés, cas couverts, couverture atteinte.
