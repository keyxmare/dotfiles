# Patterns de scoring — Legacy Score Card

## Commandes de scan rapide

### Identifier la structure du projet

```bash
# Bounded Contexts (dossiers avec Domain/ ou Application/)
for dir in src/*/; do
  bc=$(basename "$dir")
  if [ -d "$dir/Domain" ] || [ -d "$dir/Application" ]; then
    echo "BC: $bc"
  elif [[ "$bc" == *Bundle ]]; then
    echo "Bundle: $bc"
  fi
done

# Nombre total de fichiers PHP
find src/ -name "*.php" -type f 2>/dev/null | wc -l

# Nombre de fichiers de test
find tests/ -name "*Test.php" -type f 2>/dev/null | wc -l

# Version PHP requise
grep -o '"php":\s*"[^"]*"' composer.json 2>/dev/null

# Version Symfony installée
grep -o '"symfony/framework-bundle":\s*"[^"]*"' composer.json 2>/dev/null
```

---

## Axe 1 — Couplage

### Scan des imports cross-BC

```bash
# Pour chaque BC, compter les use statements cross-BC
for bc_dir in src/*/; do
  bc=$(basename "$bc_dir")
  total=$(grep -rn "^use App\\\\" "$bc_dir" --include="*.php" 2>/dev/null | wc -l)
  cross=$(grep -rn "^use App\\\\" "$bc_dir" --include="*.php" 2>/dev/null \
    | grep -v "use App\\\\${bc}\\\\" \
    | grep -v "use App\\\\Shared\\\\" \
    | grep -v "use App\\\\Common\\\\" \
    | wc -l)
  echo "$bc: $cross cross-BC / $total total"
done
```

### Scan des dépendances par constructeur

```bash
# Compter les paramètres typés dans chaque constructeur
grep -rn "public function __construct" src/ --include="*.php" -A 30 2>/dev/null \
  | grep -E "private|protected.*readonly" \
  | grep -v "string\|int\|float\|bool\|array\|null" \
  | awk -F: '{print $1}' | sort | uniq -c | sort -rn | head -20
```

### Violations de couches DDD

```bash
# Domain qui importe Infrastructure
for bc_dir in src/*/Domain/; do
  [ -d "$bc_dir" ] || continue
  bc=$(basename "$(dirname "$bc_dir")")
  grep -rn "use App\\\\.*\\\\Infrastructure\\\\" "$bc_dir" --include="*.php" 2>/dev/null
done

# Domain qui importe Application
for bc_dir in src/*/Domain/; do
  [ -d "$bc_dir" ] || continue
  bc=$(basename "$(dirname "$bc_dir")")
  grep -rn "use App\\\\.*\\\\Application\\\\" "$bc_dir" --include="*.php" 2>/dev/null
done

# Application qui importe Infrastructure
for bc_dir in src/*/Application/; do
  [ -d "$bc_dir" ] || continue
  bc=$(basename "$(dirname "$bc_dir")")
  grep -rn "use App\\\\.*\\\\Infrastructure\\\\" "$bc_dir" --include="*.php" 2>/dev/null
done
```

### Scan de la conformité DDD

```bash
# Présence de Value Objects
find src/ -path "*/ValueObject/*" -name "*.php" -type f 2>/dev/null | wc -l
find src/ -path "*/Domain/Model/*" -name "*.php" -type f 2>/dev/null | wc -l

# Pureté du Domain (imports framework interdits)
total_domain=$(find src/*/Domain/ -name "*.php" -type f 2>/dev/null | wc -l)
impure_domain=$(grep -rln "use Symfony\\\|use Doctrine\\\|use ApiPlatform" src/*/Domain/ --include="*.php" 2>/dev/null | wc -l)
echo "Domain purity: $(( (total_domain - impure_domain) * 100 / total_domain ))%"

# Domain Events
find src/ -path "*/Domain/Event/*" -name "*Event.php" -type f 2>/dev/null | wc -l
# Handlers cross-BC pour ces events
for event_file in $(find src/ -path "*/Domain/Event/*Event.php" -type f 2>/dev/null); do
  event_class=$(grep -m1 "^class " "$event_file" | awk '{print $2}')
  event_bc=$(echo "$event_file" | sed 's|src/||' | cut -d'/' -f1)
  grep -rln "use.*$event_class" src/ --include="*.php" 2>/dev/null | grep -v "src/${event_bc}/" | head -1
done

# Repository Interfaces dans Domain vs implémentations
find src/*/Domain/ -name "*RepositoryInterface.php" -type f 2>/dev/null | wc -l
find src/*/Infrastructure/ -name "*Repository.php" -type f 2>/dev/null | wc -l
```

### Barème couplage

| Métrique | A (9-10) | B (7-8) | C (5-6) | D (3-4) | F (0-2) |
|----------|----------|---------|---------|---------|---------|
| Cross-BC ratio | < 5% | 5-10% | 10-20% | 20-35% | > 35% |
| God services (>7 deps) | 0 | 1-2 | 3-5 | 6-10 | > 10 |
| Violations DDD | 0 | 1-2 | 3-5 | 6-10 | > 10 |
| Cycles | 0 | 0 | 1 | 2-3 | > 3 |

### Barème conformité DDD

| Sous-métrique | Max | A | B | C | D | F |
|---|---|---|---|---|---|---|
| Value Objects (ratio VO/entités) | 3 | > 0.5 (au moins 1 VO pour 2 entités) | > 0.3 | > 0.1 | 1-3 VO | 0 VO |
| Pureté Domain (% sans framework) | 3 | 100% | > 90% | > 70% | > 50% | < 50% |
| Domain Events | 2 | Events + handlers cross-BC | Events utilisés | Events déclarés | — | Aucun |
| Repository Interfaces | 2 | 100% interfaces | > 50% | > 25% | Quelques-uns | 0 |

---

## Axe 2 — Couverture de tests

### Scan des fichiers testables vs testés

```bash
# Fichiers PHP dans src/ (hors entités pures, events, DTOs simples)
find src/ -name "*.php" -type f \
  -not -path "*/Entity/*" \
  -not -path "*/Migrations/*" \
  -not -path "*/DataFixtures/*" \
  -not -path "*/Kernel.php" \
  2>/dev/null | wc -l

# Fichiers de test correspondants
find tests/ -name "*Test.php" -type f 2>/dev/null | wc -l

# Tests unitaires vs fonctionnels
find tests/ -path "*/Unit/*" -name "*Test.php" 2>/dev/null | wc -l
find tests/ -path "*/Functional/*" -o -path "*/Integration/*" -name "*Test.php" 2>/dev/null | wc -l
```

### Couverture par couche DDD

```bash
# Tests pour la couche Domain
find tests/ -path "*Domain*" -name "*Test.php" 2>/dev/null | wc -l
find src/ -path "*/Domain/*" -name "*.php" -not -name "*Interface.php" 2>/dev/null | wc -l

# Tests pour la couche Application
find tests/ -path "*Application*" -name "*Test.php" 2>/dev/null | wc -l
find src/ -path "*/Application/*" -name "*.php" 2>/dev/null | wc -l

# Tests pour la couche Infrastructure
find tests/ -path "*Infrastructure*" -name "*Test.php" 2>/dev/null | wc -l
find src/ -path "*/Infrastructure/*" -name "*.php" 2>/dev/null | wc -l
```

### Tests sans assertions (tests fantômes)

```bash
# Tests qui n'appellent aucune méthode assert*
for test_file in $(find tests/ -name "*Test.php" -type f 2>/dev/null); do
  # Extraire les méthodes de test
  methods=$(grep -c "public function test\|@test" "$test_file" 2>/dev/null)
  asserts=$(grep -c "assert\|expect\|should" "$test_file" 2>/dev/null)
  if [ "$methods" -gt 0 ] && [ "$asserts" -eq 0 ]; then
    echo "FANTOME: $test_file ($methods tests, 0 assertions)"
  fi
done
```

### Barème couverture

| Métrique | A (9-10) | B (7-8) | C (5-6) | D (3-4) | F (0-2) |
|----------|----------|---------|---------|---------|---------|
| Ratio global | ≥ 80% | 60-79% | 40-59% | 20-39% | < 20% |
| Domain couvert | > 90% | 70-90% | 50-70% | 30-50% | < 30% |
| Tests fantômes | 0 | 1-2 | 3-5 | 6-10 | > 10 |

---

## Axe 3 — Complexité cyclomatique

### Estimation de la complexité par méthode

```bash
# Compter les branches par fichier PHP
for file in $(find src/ -name "*.php" -type f 2>/dev/null); do
  branches=$(grep -cE "\bif\b|\belseif\b|\belse\b|\bcase\b|\bfor\b|\bforeach\b|\bwhile\b|\bdo\b|\bcatch\b|\?\?" "$file" 2>/dev/null)
  lines=$(wc -l < "$file")
  if [ "$branches" -gt 20 ]; then
    echo "COMPLEX: $file (branches: $branches, lines: $lines)"
  fi
done
```

### Classes trop longues

```bash
# Fichiers PHP de plus de 400 lignes
find src/ -name "*.php" -type f 2>/dev/null -exec sh -c '
  lines=$(wc -l < "$1")
  if [ "$lines" -gt 400 ]; then
    echo "$lines $1"
  fi
' _ {} \; | sort -rn
```

### Nesting profond

```bash
# Détecter les fichiers avec indentation > 4 niveaux (16+ espaces ou 4+ tabs)
grep -rn "^                    " src/ --include="*.php" 2>/dev/null \
  | awk -F: '{print $1}' | sort | uniq -c | sort -rn | head -20
```

### Barème complexité

| Métrique | A (9-10) | B (7-8) | C (5-6) | D (3-4) | F (0-2) |
|----------|----------|---------|---------|---------|---------|
| Méthodes simples (CC ≤ 10) | > 95% | 85-95% | 70-85% | 50-70% | < 50% |
| Classes > 400 lignes | 0 | 1-2 | 3-5 | 6-10 | > 10 |
| Méthodes CC > 20 | 0 | 1-3 | 4-8 | 9-15 | > 15 |
| Nesting > 3 niveaux | 0 | 1-5 | 6-15 | 16-30 | > 30 |

---

## Axe 4 — Dépréciations Symfony

### Scan des dépréciations dans le code

```bash
# ContainerAware (déprécié depuis Symfony 4.2)
grep -rn "ContainerAwareInterface\|ContainerAwareTrait\|extends ContainerAwareCommand" src/ --include="*.php" 2>/dev/null

# getDoctrine() (déprécié depuis Symfony 5.4)
grep -rn "getDoctrine()\|->getDoctrine()" src/ --include="*.php" 2>/dev/null

# $this->container->get() (service locator pattern, déprécié)
grep -rn '$this->container->get\|$container->get(' src/ --include="*.php" 2>/dev/null

# Annotations @Route (déprécié en faveur des attributs depuis Symfony 5.2)
grep -rn "@Route\b" src/ --include="*.php" 2>/dev/null

# Annotations Doctrine @ORM (déprécié en faveur des attributs)
grep -rn "@ORM\\\\" src/ --include="*.php" 2>/dev/null

# $defaultName sur Command (déprécié depuis Symfony 6.1)
grep -rn 'protected static \$defaultName' src/ --include="*.php" 2>/dev/null

# MessageHandlerInterface (déprécié depuis Symfony 6.2)
grep -rn "implements MessageHandlerInterface" src/ --include="*.php" 2>/dev/null

# EventSubscriberInterface (à remplacer par #[AsEventListener] depuis Symfony 7.0)
grep -rn "implements EventSubscriberInterface" src/ --include="*.php" 2>/dev/null

# getSubscribedEvents() statique
grep -rn "public static function getSubscribedEvents" src/ --include="*.php" 2>/dev/null

# TreeBuilder sans getRootNode() (déprécié depuis Symfony 4.2)
grep -rn "->root(" src/ --include="*.php" 2>/dev/null

# Security: isGranted avec des strings non-enum (Symfony 7+)
grep -rn "isGranted('ROLE_" src/ --include="*.php" 2>/dev/null

# AbstractController::getUser() déprécié pattern
grep -rn "->getUser()" src/ --include="*.php" 2>/dev/null | grep -v "Security" | grep -v "TokenInterface"
```

### Scan des dépréciations dans la configuration

```bash
# Config YAML avec format legacy
grep -rn "autowire: false" config/ --include="*.yaml" 2>/dev/null
grep -rn "autoconfigure: false" config/ --include="*.yaml" 2>/dev/null

# Config Doctrine en XML (migration vers attributs recommandée)
find config/ -name "*.xml" -path "*doctrine*" 2>/dev/null

# Bundles retirés du core Symfony
grep -rn "SwiftmailerBundle\|WebProfilerBundle\|WebServerBundle\|AssetsBundle" config/bundles.php 2>/dev/null

# security.yaml avec format legacy (access_control au lieu de access_rules est OK,
# mais firewalls.main.anonymous est legacy)
grep -rn "anonymous:" config/packages/security* --include="*.yaml" 2>/dev/null
grep -rn "guard:" config/packages/security* --include="*.yaml" 2>/dev/null
```

### Dépréciations connues par version Symfony

| Version | Pattern déprécié | Sévérité | Alternative |
|---------|-----------------|----------|-------------|
| 4.2 | `ContainerAwareInterface` | Critique | Injection |
| 4.2 | `TreeBuilder->root()` | Critique | `getRootNode()` |
| 5.2 | Annotations `@Route` | Warning | Attributs `#[Route]` |
| 5.4 | `getDoctrine()` | Critique | Inject `EntityManagerInterface` |
| 5.4 | `AbstractController::getUser()` sans type | Warning | Inject `Security` |
| 6.1 | `$defaultName` sur Command | Warning | `#[AsCommand]` |
| 6.2 | `MessageHandlerInterface` | Warning | `#[AsMessageHandler]` |
| 6.4 | Annotations `@ORM\*` | Warning | Attributs `#[ORM\*]` |
| 7.0 | `EventSubscriberInterface` | Info | `#[AsEventListener]` |
| 7.0 | `guard` authenticator | Critique | Nouveau système security |
| 7.0 | `anonymous: true` en security | Critique | `lazy: true` |
| 7.0+ | `symfony/webpack-encore-bundle` | Info | Symfony AssetMapper |
| 8.0 | Configuration XML (DI, routing) | Critique | YAML, PHP ou attributs |
| 8.0 | `Request::get()` | Critique | `$request->query->get()` / `$request->request->get()` |
| 8.0 | `#[TaggedIterator]` / `#[TaggedLocator]` | Warning | `#[AutowireIterator]` / `#[AutowireLocator]` |

### Barème dépréciations

| Métrique | A (9-10) | B (7-8) | C (5-6) | D (3-4) | F (0-2) |
|----------|----------|---------|---------|---------|---------|
| Dépréciations critiques | 0 | 1-2 | 3-5 | 6-10 | > 10 |
| Annotations (vs attributs) | 0 | < 10 fichiers | 10-30 | 30-60 | > 60 |
| Patterns legacy | 0 | 1-3 | 4-8 | 9-15 | > 15 |

---

## Axe 5 — Fraîcheur des dépendances

### Versions Symfony

```bash
# Version installée de Symfony
grep '"symfony/framework-bundle"' composer.lock 2>/dev/null | head -1

# Version contrainte dans composer.json
grep '"symfony/framework-bundle"' composer.json 2>/dev/null
```

### Version PHP

```bash
# Version requise
grep '"php"' composer.json 2>/dev/null

# Versions PHP et leur statut (à date de février 2026)
# 8.5 → Active (courante)
# 8.4 → Active
# 8.3 → Security fixes only
# 8.2 → EOL
# 8.1 → EOL
# 8.0 → EOL
# 7.x → EOL
```

### Versions Symfony et leur statut (à date de février 2026)

```
# 8.x → Active (courante)
# 7.2 → LTS / Maintenu
# 7.1 → Security fixes only
# 7.0 → EOL
# 6.4 → LTS / Security fixes
# 6.x (< 6.4) → EOL
# 5.x → EOL
# 4.x → EOL
```

### Packages outdated

```bash
# Lister les packages outdated (nécessite composer)
# composer outdated --direct --format=json 2>/dev/null

# Heuristique sans exécuter composer : comparer les contraintes
# Identifier les contraintes très larges (risque de vulnérabilité)
grep -E '"[*]"|">=|">=' composer.json 2>/dev/null
```

### Packages abandonnés connus

| Package | Remplacé par |
|---------|-------------|
| `swiftmailer/swiftmailer` | `symfony/mailer` |
| `sensio/framework-extra-bundle` | Attributs natifs Symfony |
| `doctrine/doctrine-fixtures-bundle` (anciennes versions) | Versions récentes OK |
| `nelmio/alice` (v2) | `nelmio/alice` v3+ |
| `fzaninotto/faker` | `fakerphp/faker` |
| `phpunit/phpunit` < 10 | `phpunit/phpunit` 10+ |
| `symfony/webpack-encore-bundle` | Symfony AssetMapper (Symfony 7+) |
| `twig/extensions` | Extensions intégrées à Twig |

### Barème fraîcheur

| Métrique | A (9-10) | B (7-8) | C (5-6) | D (3-4) | F (0-2) |
|----------|----------|---------|---------|---------|---------|
| Symfony version | N | N-1 | N-2 | N-3 | N-4+ |
| PHP version | 8.5+ | 8.4 | 8.3 | 8.2 | ≤ 8.1 |
| Vulnérabilités | 0 | 0 | 1 | 2-3 | > 3 |
| Packages abandonnés | 0 | 1 | 2 | 3-4 | > 4 |

---

## Score global — Table de conversion

| Score numérique | Grade | Label | Icône | Couleur HTML |
|-----------------|-------|-------|-------|-------------|
| 9.0 - 10.0 | A | Excellent | green | `#27ae60` |
| 7.0 - 8.9 | B | Bon | blue | `#2980b9` |
| 5.0 - 6.9 | C | Acceptable | yellow | `#f39c12` |
| 3.0 - 4.9 | D | Préoccupant | orange | `#e67e22` |
| 0.0 - 2.9 | F | Critique | red | `#e74c3c` |

## Barre visuelle ASCII

Format pour le dashboard Markdown :

```
Score : 7.2/10 [B]
[████████████████████░░░░░░░░░░] 72%
```

Construction :
- 30 caractères de large
- `█` pour la partie remplie
- `░` pour la partie vide
- Nombre de `█` = arrondi(score * 3)

## Template HTML — Jauge circulaire SVG

```svg
<svg viewBox="0 0 36 36" width="120" height="120">
    <path d="M18 2.0845
        a 15.9155 15.9155 0 0 1 0 31.831
        a 15.9155 15.9155 0 0 1 0 -31.831"
        fill="none" stroke="#eee" stroke-width="2.5" stroke-linecap="round"/>
    <path d="M18 2.0845
        a 15.9155 15.9155 0 0 1 0 31.831
        a 15.9155 15.9155 0 0 1 0 -31.831"
        fill="none" stroke="COULEUR" stroke-width="2.5" stroke-linecap="round"
        stroke-dasharray="SCORE_PCT, 100"/>
    <text x="18" y="18" text-anchor="middle" font-size="8" font-weight="bold" fill="#333">GRADE</text>
    <text x="18" y="24" text-anchor="middle" font-size="4" fill="#999">SCORE/10</text>
</svg>
```

Remplacer :
- `COULEUR` → couleur HTML du grade
- `SCORE_PCT` → score * 10 (ex: 7.2 → 72)
- `GRADE` → lettre du grade
- `SCORE` → score numérique
