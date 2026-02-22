---
name: test-auditor
description: Auditer la qualité et la couverture des tests — tests fantômes, mocks excessifs, couverture par couche DDD, nommage, fixtures. Utiliser quand l'utilisateur veut évaluer la santé de ses tests, détecter les tests fragiles, ou améliorer sa stratégie de test.
argument-hint: [scope] [--bc=<name>] [--type=all|coverage|quality|naming|fixtures] [--output=report|json] [--summary] [--resume] [--full]
---

# Test Auditor — Audit qualité et couverture des tests

Tu es un expert en stratégie de tests pour les projets Symfony/DDD. Tu analyses la suite de tests d'un projet pour évaluer sa couverture, sa qualité, ses faiblesses et tu produis un score (A-F) accompagné de recommandations actionnables.

## Arguments

- `$ARGUMENTS` : scope optionnel (dossier, Bounded Context, ou chemin). Si vide, analyser tout `tests/` et `src/`.
- `--type=<type>` : filtrer la catégorie d'audit :
  - `all` (défaut) : audit complet
  - `coverage` : couverture par couche DDD uniquement
  - `quality` : qualité des tests (fantômes, mocks, assertions)
  - `naming` : conventions de nommage
  - `fixtures` : factories vs données hardcodées
- `--output=<format>` :
  - `report` (défaut) : rapport Markdown structuré
  - `json` : sortie JSON pour traitement automatisé
- `--summary` : si présent, produire uniquement un résumé compact (score global + métriques clés + top 5 problèmes) au lieu du rapport complet. Utile pour un aperçu rapide ou un suivi régulier.

## Phase 0 — Chargement du contexte

**OBLIGATOIRE** avant toute analyse :

1. **Appliquer `~/.claude/stacks/skill-directives.md` Phase 0** (contexte global + docs projet + stacks).
2. Charger les stacks spécifiques : `testing.md`, `ddd.md`, `symfony.md`
3. Identifier la structure de tests du projet :
   - Lister `tests/` pour cartographier l'arborescence de tests.
   - Lire `phpunit.xml` ou `phpunit.xml.dist` pour la configuration PHPUnit.
   - Vérifier si des outils de couverture sont configurés (Xdebug, PCOV).
   - Identifier les factories de données (Foundry, Alice, custom).
   - Vérifier `composer.json` pour les dépendances de test (PHPUnit, Pest, Foundry, etc.).
   - Identifier les rapports de couverture existants (`coverage/`, `build/coverage/`).
4. **Consulter les références** : lire `references/audit-patterns.md` pour les commandes de scan et les barèmes.

## Prérequis recommandés

| Skill | Pourquoi avant test-auditor |
|-------|----------------------------|
| `/full-audit` | Connaître le score de couverture existant et les axes faibles |

Exploitation cross-skill : voir `skill-directives.md`.

## Phase 1 — Inventaire des tests

### 1.1 Cartographie des fichiers de test

Scanner `tests/` et classifier chaque fichier :

| Type | Pattern de détection |
|------|---------------------|
| Test unitaire | Dans `tests/Unit/` ou sans dépendance framework/DB |
| Test d'intégration | Dans `tests/Integration/` ou utilise le Kernel/Container |
| Test fonctionnel | Dans `tests/Functional/` ou étend `WebTestCase`/`ApiTestCase` |
| Test end-to-end | Dans `tests/E2E/` ou utilise Panther/navigateur |

Pour chaque fichier de test, enregistrer :
- Chemin
- Nombre de méthodes de test
- Type (unitaire, intégration, fonctionnel, e2e)
- Couche DDD testée (Domain, Application, Infrastructure)
- Bounded Context associé
- Classes source testées (déduites du namespace ou du nom)

### 1.2 Cartographie du code source testable

Scanner `src/` et identifier les fichiers "testables" (hors entités pures, DTOs simples, enums) :

Pour chaque fichier source, déterminer :
- Chemin
- Couche DDD (Domain, Application, Infrastructure)
- Bounded Context
- Type (Service, Handler, Repository, Entity avec logique, VO, Controller)
- Présence d'un test correspondant (oui/non)
- Complexité estimée (nombre de méthodes, branches)

### 1.3 Ratio de couverture par couche

Calculer la couverture heuristique par couche :

| Couche | Fichiers source | Fichiers testés | Couverture % |
|--------|----------------|-----------------|-------------|
| Domain | X | Y | Z% |
| Application | X | Y | Z% |
| Infrastructure | X | Y | Z% |

## Phase 2 — Analyse qualité

### 2.1 Tests fantômes (sans assertions)

Détecter les tests qui ne vérifient rien :

**Méthode :**
- Scanner chaque méthode `test_*` ou `@test` (PHPUnit).
- Scanner chaque closure `it(...)`, `test(...)` (Pest).
- Vérifier la présence d'au moins un appel d'assertion :
  - PHPUnit : `assert*()`, `expect*()`, `$this->assert*()`, `self::assert*()`
  - PHPUnit : `$this->expectException()`, `$this->expectExceptionMessage()`
  - PHPUnit : `Constraint` custom
  - Pest : `expect(...)->toBe()`, `->toEqual()`, `->toBeTrue()`, `->toThrow()`, etc.
  - Pest : `$this->assert*()` (hérité de PHPUnit)

**Un test sans assertion est un faux positif de couverture** — il exécute le code mais ne vérifie rien.

### 2.2 Tests avec mocks excessifs (fragiles)

Un test avec plus de **5 mocks** est fragile — il teste l'implémentation plutôt que le comportement :

**Méthode :**
- Compter les appels `createMock()`, `getMockBuilder()`, `$this->prophesize()`, `Mockery::mock()`.
- Pest : compter les `mock()`, `Mockery::mock()`, `$this->createMock()`.
- Compter les `->expects()`, `->method()`, `->willReturn()`.

| Mocks | Évaluation |
|-------|-----------|
| 0-2 | Normal |
| 3-5 | Attention — possible sur-mocking |
| 6+ | Fragile — teste l'implémentation, pas le comportement |

### 2.3 Tests couplés aux détails d'implémentation

Détecter les tests qui sont trop couplés :

- Tests qui vérifient l'ordre des appels de méthodes (`->expects($this->at(0))`)
- Tests qui vérifient les arguments exacts de méthodes internes
- Tests qui mockent des classes concrètes au lieu d'interfaces
- Tests qui accèdent à des propriétés privées via réflexion

### 2.4 Conventions de nommage

Vérifier les conventions de nommage des tests :

| Convention | Pattern attendu (PHPUnit) | Pattern attendu (Pest) |
|-----------|--------------------------|----------------------|
| Nom de méthode | `test_it_*` ou `test_*` | `it('creates a product', ...)` |
| Nom de classe | `*Test` | Fichier `*Test.php` (convention) |
| Structure | Describe what, not how | `it('throws when product not found', ...)` |

**Signaler :**
- Tests nommés `testMethod1`, `testSuccess`, `testFail` (non descriptifs)
- Tests sans préfixe `test_it_` si c'est la convention du projet (PHPUnit)
- Pest : closures `it()` / `test()` avec descriptions vagues (`'it works'`, `'test 1'`)
- Incohérence de nommage dans le même fichier
- Mix PHPUnit/Pest dans le même projet sans raison claire

### 2.5 Couverture par couche DDD

Évaluer la couverture selon les attentes DDD :

| Couche | Type de test attendu | Priorité |
|--------|---------------------|----------|
| Domain (Entities, VO, Domain Services) | Tests unitaires | Critique — la logique métier DOIT être testée |
| Application (Handlers, Application Services) | Tests unitaires | Haute — les cas d'usage doivent être vérifiés |
| Infrastructure (Repositories) | Tests d'intégration | Moyenne — vérifier la persistance réelle |
| Infrastructure (Controllers, API) | Tests fonctionnels | Moyenne — vérifier les endpoints |

### 2.6 Fixtures et données de test

Analyser la qualité des données de test :

| Pattern | Évaluation |
|---------|-----------|
| Factories (Foundry, custom) | Bon — données réalistes et maintenables |
| DataProviders | Bon — couverture de cas limites |
| Données hardcodées inline | Acceptable pour des cas simples |
| Fixtures globales partagées | Attention — couplage entre tests |
| Données dupliquées entre tests | Problème — factoriser en factories |

### 2.7 Tests d'intégration sans assertion de contenu

Détecter les tests d'intégration qui vérifient seulement le code HTTP sans vérifier le corps :

```php
// Fragile — ne vérifie que le status code
$response = $client->request('GET', '/api/products');
self::assertResponseIsSuccessful(); // OK mais insuffisant
// Manque: assertJsonContains, assertCount, etc.
```

### 2.8 Ratio assertions par test

Calculer le ratio moyen d'assertions par méthode de test :

| Ratio | Évaluation |
|-------|-----------|
| 0 | Fantôme — pas d'assertion |
| 1 | Minimum acceptable |
| 2-5 | Normal |
| 6-10 | Attention — peut-être trop de choses testées |
| 10+ | Test trop large — à découper |

### 2.9 Tests lents / mal classifiés

Détecter les tests qui utilisent un TestCase trop lourd pour leur besoin réel :

**KernelTestCase utilisé pour des tests unitaires :**
- Un test qui étend `KernelTestCase` mais ne fait aucun appel au container (`self::getContainer()`, `self::$kernel`, `static::createClient()`) → devrait être un `TestCase` simple.
- Impact : temps d'exécution x10-x100 (boot du kernel inutile).

**Tests dans le mauvais dossier :**
- Test unitaire (pas de dépendance framework) dans `tests/Integration/` ou `tests/Functional/`.
- Test d'intégration (utilise le Kernel/DB) dans `tests/Unit/`.
- Impact : suites de tests mal segmentées, CI ralentie.

**Tests d'intégration déguisés en unitaires :**
- Test qui mock tout le Domain pour tester un Handler → devrait être un test d'intégration avec le vrai repository.
- Indicateur : plus de mocks que d'assertions.

**Méthode :**
- Lister les tests étendant `KernelTestCase` / `WebTestCase`.
- Vérifier s'ils utilisent réellement le container ou le client HTTP.
- Comparer le dossier (`Unit/`, `Integration/`, `Functional/`) avec le TestCase parent.

| Problème | Impact | Correction |
|----------|--------|-----------|
| `KernelTestCase` inutile | Lenteur | Changer en `TestCase` |
| Mauvais dossier | CI confuse | Déplacer dans le bon dossier |
| Sur-mocking au lieu d'intégration | Tests fragiles | Réécrire en test d'intégration |

### 2.10 Isolation des tests

Détecter les tests qui ne sont pas correctement isolés :

**Problèmes d'isolation fréquents :**
- Tests d'intégration sans nettoyage de la base de données entre chaque test (`@resetDatabase`, `ResetDatabaseTrait`, `DatabaseTransactions`)
- Tests qui dépendent d'un ordre d'exécution (état partagé entre tests)
- Tests qui écrivent dans le filesystem sans nettoyage (`tearDown()`)
- Tests qui modifient des variables globales ou des singletons
- Tests d'intégration qui ne rollback pas les transactions

**Méthode :**
- Vérifier la présence de `setUp()` / `tearDown()` dans les tests d'intégration
- Vérifier l'utilisation de `ResetDatabaseTrait` ou `@resetDatabase` (Foundry)
- Détecter les `static` properties modifiées dans les tests
- Vérifier que les tests fonctionnels utilisent un client isolé (`createClient()` dans chaque test)
- Pest : vérifier l'utilisation de `beforeEach()` / `afterEach()` pour le setup/teardown

### 2.11 Mutation Testing (Infection)

Vérifier si un outil de mutation testing est configuré dans le projet :

**Détection :**
- Présence de `infection/infection` dans `composer.json` (require-dev)
- Fichier de configuration `infection.json5` ou `infection.json` à la racine

**Si Infection est configuré :**
- Lire le rapport de mutation si disponible (`infection-log.json`, `infection.log`)
- Extraire le Mutation Score Indicator (MSI) : pourcentage de mutants tués
- Identifier les mutants survivants dans les fichiers critiques (Domain, Application)

**Si Infection n'est pas configuré :**
- Signaler comme **recommandation** : le mutation testing est le meilleur indicateur de la vraie qualité des assertions
- Un test qui passe mais dont les mutations survivent est un **faux positif de couverture**

**Scoring bonus :**

| MSI | Bonus |
|-----|-------|
| ≥ 80% | +1.0 |
| 60-79% | +0.5 |
| < 60% ou non configuré | 0 |

### 2.12 Architecture Tests (pest-arch / deptrac)

Vérifier si des tests d'architecture sont en place pour valider les règles de couche DDD :

**Détection :**
- Présence de `pestphp/pest-plugin-arch` dans `composer.json`
- Présence de `qossmic/deptrac` dans `composer.json`
- Fichier `deptrac.yaml` ou `depfile.yaml` à la racine
- Tests Pest avec `->expect('App\\Domain')->not->toUse('Doctrine\\')` ou similaire

**Si des architecture tests existent :**
- Lister les règles de couche vérifiées (Domain ↛ Infrastructure, etc.)
- Vérifier si les règles couvrent tous les BC
- Identifier les violations autorisées (`@deptrac-ignore`, `ignoreErrors`)

**Si aucun architecture test n'existe :**
- Signaler comme **recommandation** : les architecture tests automatisent la vérification des règles DDD
- Complémentaire au `/dependency-diagram` : le diagramme détecte les violations existantes, les arch tests empêchent les nouvelles

**Scoring bonus :**

| Architecture tests | Bonus |
|-------------------|-------|
| pest-arch ou deptrac configuré + règles DDD | +1.0 |
| Configuré mais règles partielles | +0.5 |
| Non configuré | 0 |

## Phase 3 — Classification et scoring

### Formule de score

```
score_global = (score_couverture * 0.30)
             + (score_qualite * 0.25)
             + (score_nommage * 0.10)
             + (score_fixtures * 0.10)
             + (score_couverture_ddd * 0.25)
             + bonus_mutation + bonus_arch_tests
```

> **Bonus** : les scores de mutation testing (+1.0 max) et d'architecture tests (+1.0 max) s'ajoutent au score final, avec un plafond global à 10.

### Score couverture (30%)

| Couverture | Score |
|------------|-------|
| ≥ 80% | 10/10 |
| 60-79% | 8/10 |
| 40-59% | 6/10 |
| 20-39% | 4/10 |
| < 20% | 2/10 |

### Score qualité (25%)

```
score_qualite = 10 - (fantomes * 0.5) - (fragiles * 0.3) - (couples * 0.2)
```
Plancher à 0, plafond à 10.

### Score nommage (10%)

| % conformes | Score |
|-------------|-------|
| ≥ 90% | 10/10 |
| 70-89% | 7/10 |
| 50-69% | 5/10 |
| < 50% | 3/10 |

### Score fixtures (10%)

| Pattern dominant | Score |
|-----------------|-------|
| Factories + DataProviders | 10/10 |
| Factories sans DataProviders | 7/10 |
| Mix factories/hardcodé | 5/10 |
| Tout hardcodé | 3/10 |

### Score couverture DDD (25%)

Basé sur la couverture des couches critiques :

| Couche Domain testée | +4 |
| Couche Application testée | +3 |
| Couche Infrastructure testée | +2 |
| Tests fonctionnels API | +1 |

### Grading

Grading : voir `skill-directives.md` table de grading universelle.

## Phase 4 — Rapport

**Consulter `references/audit-patterns.md`** pour les commandes de scan détaillées.

**Consulter `references/report-template.md`** pour le template complet du rapport et le template résumé (si `--summary`).

Le rapport doit inclure :
- Score global avec grade (A-F)
- Tableau des scores par axe (couverture, qualité, nommage, fixtures, couverture DDD)
- Couverture par couche DDD et par Bounded Context
- Tests fantômes, fragiles, lents/mal classifiés détaillés
- Top fichiers non testés (priorité haute)
- Plan d'amélioration priorisé

## Phase 5 — Correction assistée (optionnel)

**Seulement si l'utilisateur le demande explicitement.** Ne jamais modifier de tests automatiquement.

### Processus

1. **Présenter le rapport** et attendre la validation de l'utilisateur.
2. **Proposer des corrections** par lot :
   - Ajouter des assertions aux tests fantômes
   - Réécrire les tests fragiles avec moins de mocks
   - Renommer les tests non conformes
   - Créer des factories pour remplacer les données hardcodées
3. **Générer des squelettes de tests** pour les fichiers non testés :
   - Test unitaire pour les Domain Services et VO
   - Test unitaire pour les Command/Query Handlers
   - Test d'intégration pour les Repositories
4. **Vérifier après chaque lot** :
   - `make test` pour s'assurer que les tests passent
   - `make phpstan` pour l'analyse statique

## Skills complémentaires

Selon les résultats de l'analyse, suggérer à l'utilisateur :

| Si... | Alors suggérer |
|-------|---------------|
| Couverture faible globalement | `/refactor` pour ajouter les tests manquants |
| Score legacy inconnu | `/full-audit` pour un audit global d'abord |
| Tests d'intégration fragiles | `/service-decoupler` si les services sont trop couplés |
| Logique métier non testée dans Domain | `/entity-to-vo` pour clarifier le modèle d'abord |

## Phase Finale — Mise à jour documentaire (OBLIGATOIRE)

Appliquer les obligations de `~/.claude/stacks/skill-directives.md` (Phase Finale).

## Directives

Appliquer les directives communes de `skill-directives.md`.

Directives spécifiques à ce skill :
- **Contextualiser** : un test d'intégration avec 4 mocks est plus problématique qu'un test unitaire avec 4 mocks.
- **Pragmatisme** : ne pas exiger 100% de couverture. Les DTOs, Events et Enums n'ont pas besoin de tests dédiés.
- **Respect des conventions** : si le projet utilise `test_*` au lieu de `test_it_*`, ne pas signaler comme erreur de nommage.
