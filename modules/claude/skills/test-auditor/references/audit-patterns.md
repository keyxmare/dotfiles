# Test Auditor — Commandes de scan et patterns de détection

## Inventaire des tests

### Lister les fichiers de test
```bash
# Tous les fichiers de test (PHPUnit)
find tests/ -name "*Test.php" -type f

# Par type
find tests/Unit/ -name "*Test.php" -type f 2>/dev/null
find tests/Integration/ -name "*Test.php" -type f 2>/dev/null
find tests/Functional/ -name "*Test.php" -type f 2>/dev/null

# Fichiers Pest (closures it/test au lieu de classes)
grep -rln "^it(\|^test(\|->it(\|->test(" tests/ --include="*.php" 2>/dev/null
```

### Détecter le framework de test
```bash
# PHPUnit
grep -q "phpunit/phpunit" composer.json && echo "PHPUnit detecte"

# Pest
grep -q "pestphp/pest" composer.json && echo "Pest detecte"

# Pest plugins
grep "pestphp/" composer.json
```

### Compter les méthodes/closures de test
```bash
# PHPUnit : méthodes test_ dans un fichier
grep -c "public function test_\|@test" tests/**/*Test.php

# Pest : closures it() et test()
grep -c "^it(\|^test(" tests/**/*Test.php 2>/dev/null
grep -c "^it(\|^test(" tests/**/*.php 2>/dev/null
```

## Détection des problèmes

### Tests sans assertions (fantomes)
```bash
# PHPUnit : chercher les méthodes de test
grep -n "public function test_" tests/ -r --include="*.php"

# Pest : chercher les closures de test
grep -n "^it(\|^test(" tests/ -r --include="*.php"

# Vérifier la présence d'assertions dans le corps
# PHPUnit : assert*, expect*
grep -n "assert\|expect" tests/ -r --include="*.php"

# Pest : expect()->toBe(), ->toEqual(), ->toBeTrue(), ->toThrow(), etc.
grep -n "expect(" tests/ -r --include="*.php" | grep -v "expectException\|expectExceptionMessage"
```

### Tests avec mocks excessifs
```bash
# Compter les createMock par fichier
grep -c "createMock\|getMockBuilder\|prophesize\|Mockery::mock" tests/**/*Test.php

# Identifier les fichiers avec > 5 mocks
grep -l "createMock" tests/ -r --include="*.php" | while read f; do
    count=$(grep -c "createMock\|getMockBuilder" "$f")
    if [ "$count" -gt 5 ]; then echo "$f: $count mocks"; fi
done
```

### Nommage non conforme
```bash
# PHPUnit : méthodes qui ne suivent pas la convention test_it_*
grep -n "public function test" tests/ -r --include="*.php" | grep -v "test_it_\|test_.*_when_\|test_.*_should_"

# PHPUnit : tests nommés testX, testSuccess, testFail
grep -n "public function test[A-Z]" tests/ -r --include="*.php"

# Pest : descriptions vagues
grep -n "^it(\|^test(" tests/ -r --include="*.php" | grep -i "'it works'\|'test 1'\|'success'\|'fail'\|'basic'"
```

### Données hardcodées vs factories
```bash
# Chercher Foundry factories
grep -rn "factory()\|Factory::create\|Factory::new" tests/ --include="*.php"

# Chercher donnees hardcodees
grep -rn "new.*Entity\|new.*DTO" tests/ --include="*.php" | grep -v "Factory\|Mock"
```

### DataProviders
```bash
# Chercher les DataProviders
grep -rn "@dataProvider\|#\[DataProvider\]" tests/ --include="*.php"

# Compter les méthodes provider
grep -rn "public.*Provider\|public static.*provider" tests/ --include="*.php"
```

## Couverture par couche DDD

### Mapper les fichiers source aux tests
```bash
# Fichiers source par couche
find src/*/Domain/ -name "*.php" -type f | wc -l
find src/*/Application/ -name "*.php" -type f | wc -l
find src/*/Infrastructure/ -name "*.php" -type f | wc -l

# Tests correspondants
find tests/*/Domain/ -name "*Test.php" -type f 2>/dev/null | wc -l
find tests/*/Application/ -name "*Test.php" -type f 2>/dev/null | wc -l
find tests/*/Infrastructure/ -name "*Test.php" -type f 2>/dev/null | wc -l
```

## Tests d'integration sans verification de contenu

```bash
# Tests qui assertent uniquement le status code
grep -n "assertResponseIsSuccessful\|assertResponseStatusCodeSame" tests/ -r --include="*.php" | while read line; do
    file=$(echo "$line" | cut -d: -f1)
    # Vérifier si le même test a aussi des assertions de contenu
    grep -l "assertJsonContains\|assertJsonCount\|assertJson\|getContent" "$file" > /dev/null || echo "WARN: $file — status-only assertions"
done
```

## Ratio assertions/test

```bash
# Compter assertions par fichier
for f in $(find tests/ -name "*Test.php" -type f); do
    tests=$(grep -c "public function test_" "$f")
    asserts=$(grep -c "assert\|expect" "$f")
    if [ "$tests" -gt 0 ]; then
        ratio=$(echo "scale=1; $asserts / $tests" | bc)
        echo "$f: $ratio assertions/test"
    fi
done
```

## WebTestCase vs KernelTestCase

```bash
# Identifier le type de TestCase parent
grep -rn "extends.*TestCase\|extends.*WebTestCase\|extends.*KernelTestCase\|extends.*ApiTestCase" tests/ --include="*.php"

# Pest : identifier les uses()
grep -rn "uses(" tests/ --include="*.php" | grep "TestCase\|RefreshDatabase\|LazilyRefreshDatabase"
```

## Isolation des tests

```bash
# Tests d'integration sans reset de la base
# Chercher les tests qui utilisent le kernel/container sans reset
grep -rln "extends KernelTestCase\|extends WebTestCase\|extends ApiTestCase" tests/ --include="*.php" | while read f; do
    grep -l "ResetDatabaseTrait\|@resetDatabase\|DatabaseTransactions\|RefreshDatabase" "$f" > /dev/null || echo "WARN: $f — pas de reset DB"
done

# Tests sans tearDown qui modifient le filesystem
grep -rln "file_put_contents\|mkdir\|touch\|fwrite" tests/ --include="*.php" | while read f; do
    grep -l "tearDown\|afterEach\|unlink\|rmdir" "$f" > /dev/null || echo "WARN: $f — ecrit dans le filesystem sans nettoyage"
done

# Variables statiques modifiees dans les tests
grep -rn "static \$\|self::\$" tests/ --include="*.php" | grep -v "self::\$.*=.*null\|private static"

# Tests sans createClient() isolé (WebTestCase)
grep -rln "extends WebTestCase\|extends ApiTestCase" tests/ --include="*.php" | while read f; do
    count=$(grep -c "createClient\|static::createClient" "$f")
    tests=$(grep -c "public function test_" "$f")
    if [ "$count" -lt "$tests" ] && [ "$tests" -gt 1 ]; then echo "WARN: $f — client potentiellement partagé entre tests"; fi
done

# Pest : vérifier beforeEach/afterEach
grep -rln "beforeEach\|afterEach" tests/ --include="*.php"
```

## Tests lents / mal classifiés

```bash
# KernelTestCase/WebTestCase qui n'utilisent pas le container
for f in $(grep -rln "extends KernelTestCase\|extends WebTestCase" tests/ --include="*.php" 2>/dev/null); do
    uses_container=$(grep -c "getContainer\|self::\$kernel\|static::createClient\|self::bootKernel\|\$this->client" "$f" 2>/dev/null)
    if [ "$uses_container" -eq 0 ]; then
        echo "SLOW: $f — extends KernelTestCase mais n'utilise pas le container"
    fi
done

# Tests unitaires dans le mauvais dossier (utilisent le Kernel)
for f in $(find tests/Unit/ -name "*Test.php" -type f 2>/dev/null); do
    if grep -q "extends KernelTestCase\|extends WebTestCase\|extends ApiTestCase\|self::bootKernel\|self::getContainer" "$f" 2>/dev/null; then
        echo "MISPLACED: $f — test d'intégration dans tests/Unit/"
    fi
done

# Tests d'intégration dans le mauvais dossier (n'utilisent pas le Kernel)
for f in $(find tests/Integration/ tests/Functional/ -name "*Test.php" -type f 2>/dev/null); do
    if grep -q "extends TestCase" "$f" && ! grep -q "extends.*KernelTestCase\|extends.*WebTestCase\|extends.*ApiTestCase" "$f" 2>/dev/null; then
        echo "MISPLACED: $f — test unitaire dans tests/Integration/ ou Functional/"
    fi
done
```

## Pest : patterns specifiques

```bash
# Pest : higher-order tests
grep -rn "->expect(" tests/ --include="*.php"

# Pest : datasets (equivalent DataProvider)
grep -rn "->with(\|dataset(" tests/ --include="*.php"

# Pest : groupes/describes
grep -rn "describe(" tests/ --include="*.php"

# Pest : hooks
grep -rn "beforeEach\|afterEach\|beforeAll\|afterAll" tests/ --include="*.php"
```

## Mutation Testing (Infection)

### Détection de la configuration
```bash
# Vérifier si Infection est installé
grep -r "infection/infection" composer.json 2>/dev/null

# Chercher le fichier de configuration
ls infection.json5 infection.json 2>/dev/null
```

### Analyse du rapport Infection
```bash
# Chercher les rapports générés
ls infection-log.json infection.log 2>/dev/null

# Extraire le MSI (Mutation Score Indicator) depuis le log
grep -i "Mutation Score Indicator\|MSI" infection.log 2>/dev/null

# Extraire les mutants survivants
grep -i "Escaped\|Survived" infection-log.json 2>/dev/null
```

### Évaluation
- **Si configuré** : lire le rapport (`infection-log.json`, `infection.log`), extraire le MSI, identifier les mutants survivants dans les couches Domain/ et Application/ (priorité haute)
- **Si non configuré** : signaler comme recommandation — le mutation testing est un excellent complément aux tests unitaires pour les Value Objects et la logique métier

### Scoring bonus
| MSI | Bonus |
|-----|-------|
| >= 80% | +1.0 |
| 60-79% | +0.5 |
| < 60% ou non configuré | 0 |

## Architecture Tests (pest-arch / deptrac)

### Détection de la configuration
```bash
# Vérifier si pest-plugin-arch ou deptrac est installé
grep -r "pestphp/pest-plugin-arch\|qossmic/deptrac" composer.json 2>/dev/null

# Chercher les fichiers de config deptrac
ls deptrac.yaml depfile.yaml 2>/dev/null
```

### Analyse des règles Pest Arch
```bash
# Chercher les tests d'architecture Pest
grep -rn "->expect(" tests/ --include="*.php" | grep -i "not->toUse\|toOnlyUse\|toImplement\|toExtend\|toBeReadonly\|toHaveSuffix\|toHavePrefix\|toBeFinal"

# Exemples de règles DDD courantes :
# ->expect('App\\Domain')->not->toUse('Doctrine\\')
# ->expect('App\\Domain')->not->toUse('Symfony\\')
# ->expect('App\\Application')->not->toUse('App\\Infrastructure')
```

### Analyse des règles deptrac
```bash
# Lire la configuration deptrac
# cat deptrac.yaml

# Vérifier les layers déclarées
grep -rn "layers:" deptrac.yaml depfile.yaml 2>/dev/null

# Vérifier les rulesets (quelles couches peuvent dépendre de quelles couches)
grep -rn "ruleset:" deptrac.yaml depfile.yaml 2>/dev/null
```

### Évaluation
- **Si configuré** : lister les règles de couche vérifiées, vérifier si elles couvrent tous les Bounded Contexts, identifier les violations autorisées (skipped violations)
- **Si non configuré** : signaler comme recommandation — les tests d'architecture garantissent le respect des couches DDD et préviennent les régressions de dépendances

### Scoring bonus
| Configuration | Bonus |
|---------------|-------|
| Configuré + règles DDD (Domain n'importe pas Infrastructure) | +1.0 |
| Configuré partiel (quelques règles ou pas tous les BC) | +0.5 |
| Non configuré | 0 |

## Enums non testes

### Detection des enums PHP
```bash
# Find all PHP enums
grep -rn "^enum \|^final enum \|^readonly enum " src/ --include="*.php" -l

# Check if enum has corresponding test
# For each enum file, check if a test file exists
```

### Evaluation
- Verifier : les backed enums ont-ils des tests pour `from()` et `tryFrom()` ?
- Les enums avec des methodes custom (logique metier) doivent etre testes
- **Faux positif** : les enums simples sans logique (liste de valeurs) ne necessitent pas de test

## Exceptions non testees

### Detection des exceptions custom
```bash
# Find custom exceptions
grep -rn "class \w\+Exception extends" src/ --include="*.php" -l

# Find throw statements and check if covered
grep -rn "throw new \w\+Exception" src/ --include="*.php"
```

### Evaluation
- Verifier : chaque exception custom avec de la logique (message dynamique, code custom) a-t-elle un test ?
- Les exceptions qui encapsulent une logique de construction (factory method, context enrichment) meritent un test
- Les exceptions simples (juste un message statique) ne necessitent pas de test dedie

## Migrations non testees

### Detection des migrations Doctrine
```bash
# Find Doctrine migrations
find src/Migrations/ migrations/ -name "*.php" 2>/dev/null

# Check for migration tests
find tests/ -path "*Migration*" -name "*.php" 2>/dev/null
```

### Evaluation
- Les migrations critiques (**data migrations**, pas schema-only) devraient avoir des tests
- Les migrations qui transforment des donnees (calculs, conversions, aggregations) sont prioritaires
- Les migrations de schema pur (ajout de colonne, index) ne necessitent generalement pas de test
