# Tests — Méthodologie globale

## Principes

- Toujours tester. Chaque feature, chaque fix doit être couvert par des tests. ← `tests.enabled`
- Toujours vérifier que les tests passent avant de push. ← `tests.before_push`
- Ne pas hésiter à proposer des améliorations sur la stratégie de tests existante.
- Un TEST.md local au projet peut surcharger ces instructions. En cas de contradiction, le local prime.

## Isolation des tests

- Les tests ne doivent jamais dépendre de l'ordre d'exécution.
- Chaque test part d'un état propre (`setUp`/`beforeEach`) et ne laisse aucun effet de bord.
- Pas d'état mutable partagé entre tests (fichiers, base de données, variables globales/statiques).
- Un test qui passe seul mais échoue en batch (ou inversement) est un signe de couplage — le corriger immédiatement.

## Pyramide de tests

Viser la pyramide de tests classique, du plus nombreux au moins nombreux :

1. **Unitaires** — Tester les fonctions et modules en isolation. Constituant la base de la pyramide, ils doivent être rapides et nombreux.
2. **Intégration** — Tester les interactions entre modules, services, base de données. Moins nombreux que les unitaires.
3. **E2E** — Tester les parcours utilisateur complets. Réservés aux scénarios critiques, les plus coûteux à maintenir.

## Couverture des cas

- Ne pas se limiter au cas trivial. Couvrir les cas possibles : cas nominal, cas limites, cas d'erreur, cas aux bornes.
- Pour un fix : écrire un ou plusieurs tests qui reproduisent le bug avant de le corriger (non-régression), en incluant les variantes du problème.
- Pour une feature : tester le comportement attendu mais aussi les cas d'erreur, les entrées invalides et les edge cases.

## Coverage

- **Nouveau projet** — Minimum 80% de couverture par défaut. ← `tests.min_coverage`
- **Projet legacy peu testé** — Ne jamais faire baisser le coverage existant. Chaque modification doit au minimum maintenir le taux actuel, idéalement l'améliorer.

## Mutation testing

- Quand la stack le supporte, appliquer le mutation testing avec un MSI (Mutation Score Indicator) minimum de 80%. ← `tests.mutation`
- Cela garantit que les tests vérifient réellement le comportement et pas juste la couverture de lignes.
- Pour Infection (PHP) : `--min-msi=80`. Pour Stryker (JS/TS) : `thresholds.break: 80`.

## Outils par stack

| Stack | Unitaires / Intégration | E2E | Mutation testing |
|---|---|---|---|
| PHP / Symfony | Pest (défaut) ou PHPUnit | Behat | Infection |
| Nuxt | Vitest | Playwright | Stryker |
| Vue.js | Vitest | Playwright | Stryker |
| Shell (Bash / Sh / Zsh) | Bats (bats-assert, bats-file) | — | — |

Un projet peut surcharger les outils via son TEST.md local. Cette table sera complétée au fur et à mesure des stacks définies.

## Vérification fonctionnelle

Au-delà des tests automatisés, toujours vérifier que le projet **fonctionne réellement** avant de commit :

- **Build** — Si le projet est dockerisé, vérifier que `docker compose build` réussit.
- **Démarrage** — Vérifier que tous les services démarrent (containers `Up`, pas `Exited` ni `Restarting`).
- **Réponse** — Si des services exposent des endpoints HTTP, vérifier qu'ils répondent (code 200 ou 404 Symfony/framework attendu).
- **Connexions** — Vérifier les connexions entre services (backend → BDD, etc.).
- **Dépendances** — Vérifier que l'installation des dépendances réussit (`composer install`, `pnpm install`, etc.).

Cette vérification s'applique particulièrement lors de :
- La création d'un nouveau projet (scaffold).
- L'ajout ou la mise à jour de dépendances.
- La modification de la configuration Docker ou des fichiers de config framework.

## Règles de co-création (tests + code)

- **Ne jamais créer un handler sans son test.** Le test est créé dans la même étape que le handler.
- **Ne jamais créer un store sans son test.** Chaque store Pinia/Vuex doit avoir un test qui couvre ses actions et getters.
- **Ne jamais créer un service sans son test.** Chaque service (backend ou frontend) doit avoir un test unitaire.
- **Lors de la création d'une feature, créer les tests correspondants dans la même étape.** Ne pas reporter les tests à une étape ultérieure.
- **Les formulaires frontend doivent avoir des submit handlers fonctionnels.** Un formulaire sans logique de soumission connectée à un store ou une API est considéré comme incomplet. Le test du formulaire doit vérifier que la soumission déclenche l'action attendue (appel API, mutation store, navigation, etc.).

## Vérification qualité obligatoire

Avant de considérer une tâche comme terminée, exécuter les outils de qualité définis dans le fichier de stack correspondant (linter, analyse statique). Si des erreurs sont détectées, les corriger avant de commit. Les tests sont exécutés avant push (`tests.before_push`). Ne jamais ignorer les résultats de ces outils.

## Quand tester

- À chaque ajout de feature : écrire les tests couvrant tous les cas identifiés.
- À chaque fix : écrire les tests de non-régression avant de corriger.
- Avant chaque push : s'assurer que l'ensemble des tests passent.

## Conventions par stack

Les conventions de test spécifiques à chaque stack (structure des fichiers, patterns de mock, exemples) sont dans les fichiers de stack correspondants :

- **PHP / Symfony** → [stacks/symfony-testing.md](./stacks/symfony-testing.md)
- **Vue.js / Nuxt** → [stacks/vue-testing.md](./stacks/vue-testing.md)
- **Shell** → [stacks/shell.md#tests-avec-bats](./stacks/shell.md#tests-avec-bats)

## Conventions de nommage

### Vitest / JS/TS

- Utiliser des descriptions **comportementales** dans les blocs `describe`/`it` : décrire ce que fait le code, pas comment il le fait.
- Format : `it('should <action> when <condition>')` — ex : `it('should throw when email is invalid')`.
- Regrouper les tests par méthode ou comportement dans des blocs `describe` imbriqués.

### PHPUnit

- Utilisé uniquement si `tests.php_framework` = `phpunit` (Pest est le défaut).
- Noms de méthodes descriptifs préfixés par `test` en snake_case : `test_it_should_create_order_when_valid_data()`.
- Un seul style par projet. Le snake_case est le défaut recommandé (plus lisible). Surchargeable dans le TEST.md du projet.
- Regrouper les tests dans des classes dédiées (un fichier par classe testée).

### Pest (PHP)

Pest est le framework de test par défaut pour PHP (`tests.php_framework: pest`). Syntaxe fonctionnelle au lieu des classes.

- Utiliser `describe()` pour grouper et `it()` / `test()` pour chaque cas.
- Format : `it('should create order when valid data')` — descriptions comportementales en anglais.
- Utiliser les expectations chaînées : `expect($result)->toBe(true)->not->toBeNull()`.
- Helpers Pest : `beforeEach()`, `afterEach()`, `dataset()` pour les data providers.
- Architecture de fichiers identique à PHPUnit (même arborescence `tests/`).

#### Mocking avec Pest

Pest supporte deux stratégies de mock :

- **Mockery** (recommandé) — Syntaxe fluide, s'intègre naturellement avec Pest. `Mockery::mock()`.
- **PHPUnit mocks** — `$this->createMock()` fonctionne aussi car Pest étend TestCase.

Choisir une stratégie par projet et s'y tenir. Si Mockery est utilisé, ajouter `mockery/mockery` aux devDependencies.

#### Exemple — Test de handler (Pest)

```php
<?php

declare(strict_types=1);

use App\Catalog\Application\CommandHandler\CreateProductHandler;
use App\Catalog\Application\Command\CreateProductCommand;
use App\Catalog\Domain\Repository\ProductRepositoryInterface;

beforeEach(function () {
    $this->repository = Mockery::mock(ProductRepositoryInterface::class);
    $this->handler = new CreateProductHandler($this->repository);
});

describe('CreateProductHandler', function () {
    it('should create a product with valid data', function () {
        $command = new CreateProductCommand(name: 'Widget', price: 9.99);
        $this->repository->shouldReceive('save')->once();

        ($this->handler)($command);

        $this->repository->shouldHaveReceived('save');
    });

    it('should throw when name is empty', function () {
        $command = new CreateProductCommand(name: '', price: 9.99);

        expect(fn () => ($this->handler)($command))
            ->toThrow(InvalidArgumentException::class);
    });
});
```

#### Adaptation PHPUnit -> Pest

Quand `tests.php_framework` = `pest`, adapter les templates PHPUnit existants :

| PHPUnit | Pest |
|---|---|
| `class FooTest extends TestCase` | `describe('Foo', function () { ... })` |
| `protected function setUp(): void` | `beforeEach(function () { ... })` |
| `public function test_it_should_do_x()` | `it('should do x', function () { ... })` |
| `$this->assertEquals($a, $b)` | `expect($b)->toBe($a)` |
| `$this->assertTrue($x)` | `expect($x)->toBeTrue()` |
| `$this->assertCount(3, $arr)` | `expect($arr)->toHaveCount(3)` |
| `$this->expectException(E::class)` | `expect(fn () => ...)->toThrow(E::class)` |
| `@dataProvider` | `dataset('name', [...])` + `it('...', function ($val) { ... })->with('name')` |

### Commun

- Les noms de fixtures et données de test doivent être explicites : `validUser`, `expiredToken`, pas `data1`, `input`.

## Fixtures et factories

- Les fixtures doivent représenter des cas réalistes, pas des données aléatoires ou minimales qui masquent des bugs.
- Centraliser les fixtures réutilisées. Usage unique → dans le fichier de test.
- Les conventions spécifiques (Foundry, helpers TS, etc.) sont dans les fichiers de stack.

## Snapshot testing

- **Interdit** pour la logique métier — les snapshots ne vérifient pas le comportement, seulement la forme.
- **Autorisé** uniquement pour les composants UI purement visuels (layouts, wrappers) quand le rendu HTML est le contrat à vérifier.
- Si un snapshot casse, ne jamais `--update` sans comprendre pourquoi. Analyser le diff d'abord.
