# Patterns de détection des dépendances

## Commandes de scan rapide

### Identifier les Bounded Contexts

```bash
# Dossiers de premier niveau dans src/ contenant Domain/ ou Application/
for dir in src/*/; do
  bc=$(basename "$dir")
  if [ -d "$dir/Domain" ] || [ -d "$dir/Application" ]; then
    echo "BC: $bc"
  elif [[ "$bc" == *Bundle ]]; then
    echo "Bundle: $bc"
  fi
done
```

### Dépendances par `use` statements inter-BC

```bash
# Pour chaque BC, trouver les use statements qui importent d'un autre BC
for bc_dir in src/*/; do
  bc=$(basename "$bc_dir")
  echo "=== $bc ==="
  grep -rn "^use App\\\\" "$bc_dir" --include="*.php" 2>/dev/null \
    | grep -v "use App\\\\${bc}\\\\" \
    | grep -v "use App\\\\Shared\\\\" \
    | grep -v "use App\\\\Common\\\\" \
    | sort -u
done
```

### Injections cross-BC via constructeur

```bash
# Trouver les constructeurs et les types injectés
grep -rn "public function __construct" src/ --include="*.php" -A 20 2>/dev/null \
  | grep -E "private|public|protected.*readonly" \
  | grep -v "string\|int\|float\|bool\|array\|null\|self\|static"
```

### Domain Events et leurs handlers

```bash
# Producteurs : Domain Events
find src/ -path "*/Domain/Event/*Event.php" -type f 2>/dev/null

# Consommateurs : handlers qui importent des events d'autres BC
for event_file in $(find src/ -path "*/Domain/Event/*Event.php" -type f 2>/dev/null); do
  event_class=$(grep -m1 "^class " "$event_file" | awk '{print $2}')
  event_bc=$(echo "$event_file" | sed 's|src/||' | cut -d'/' -f1)
  echo "--- Event: $event_class (BC: $event_bc) ---"
  grep -rn "use.*$event_class" src/ --include="*.php" 2>/dev/null \
    | grep -v "src/${event_bc}/"
done
```

### Commands/Queries dispatched cross-BC

```bash
# Trouver les `new <Command/Query>` dans des BC différents
for cmd_dir in src/*/Application/Command/ src/*/Application/Query/; do
  [ -d "$cmd_dir" ] || continue
  bc=$(echo "$cmd_dir" | sed 's|src/||' | cut -d'/' -f1)
  for cmd_file in "$cmd_dir"*.php; do
    [ -f "$cmd_file" ] || continue
    cmd_class=$(grep -m1 "^class \|^readonly class \|^final class \|^final readonly class " "$cmd_file" | awk '{print $NF}' | sed 's/{//')
    # Chercher les instanciations dans d'autres BC
    grep -rn "new ${cmd_class}" src/ --include="*.php" 2>/dev/null \
      | grep -v "src/${bc}/"
  done
done
```

### Relations Doctrine cross-BC (XML mappings)

```bash
# target-entity qui référence un autre namespace BC
grep -rn "target-entity\|targetEntity" src/ --include="*.xml" --include="*.php" 2>/dev/null \
  | grep -v "target-entity=\"App\\\\Shared"
```

### Relations Doctrine cross-BC (attributs PHP)

```bash
grep -rn "targetEntity:" src/ --include="*.php" 2>/dev/null
grep -rn "#\[ORM\\\\ManyToOne\|#\[ORM\\\\OneToMany\|#\[ORM\\\\ManyToMany\|#\[ORM\\\\OneToOne" src/ --include="*.php" 2>/dev/null
```

### Relations bidirectionnelles cross-BC (mappedBy / inversedBy)

```bash
# Attributs PHP — détecter mappedBy et inversedBy cross-BC
grep -rn "mappedBy:\|inversedBy:" src/ --include="*.php" 2>/dev/null

# XML — détecter mapped-by et inversed-by cross-BC
grep -rn "mapped-by\|inversed-by" src/ --include="*.xml" 2>/dev/null

# Croiser les résultats avec les BC pour identifier les couplages bidirectionnels
for bc_dir in src/*/; do
  bc=$(basename "$bc_dir")
  echo "=== $bc ==="
  grep -rn "mappedBy:\|inversedBy:" "$bc_dir" --include="*.php" 2>/dev/null \
    | grep -v "App\\\\${bc}\\\\"
  grep -rn "mapped-by\|inversed-by" "$bc_dir" --include="*.xml" 2>/dev/null
done
```

### Configuration services.yaml cross-BC

```bash
# Bindings d'interfaces d'un BC vers une implémentation d'un autre
grep -rn "App\\\\" config/services.yaml config/services/ 2>/dev/null
```

## Patterns de classification

### Couche du fichier source

| Pattern de chemin | Couche |
|---|---|
| `src/<BC>/Domain/` | Domain |
| `src/<BC>/Application/` | Application |
| `src/<BC>/Infrastructure/` | Infrastructure |
| `src/<BC>Bundle/` | Bundle (Infrastructure) |
| `src/Shared/` | Shared Kernel |

### Sévérité des dépendances

| Source → Cible | Sévérité | Raison |
|---|---|---|
| Domain → Domain (autre BC) | `warning` | Couplage inter-BC |
| Domain → Application | `critical` | Violation DDD : Domain doit être indépendant |
| Domain → Infrastructure | `critical` | Violation DDD : Domain doit être indépendant |
| Application → Domain (même BC) | `normal` | Attendu |
| Application → Domain (autre BC) | `warning` | Devrait passer par un port/interface |
| Application → Infrastructure | `critical` | Violation architecture hexagonale |
| Infrastructure → Domain | `normal` | Attendu (implémentation ports) |
| Infrastructure → Application | `normal` | Attendu (controllers dispatching) |
| Infrastructure → Infrastructure (autre BC) | `warning` | Couplage technique |
| Event async cross-BC | `normal` | Pattern recommandé |
| Doctrine relation cross-BC | `critical` | Anti-pattern DDD (utiliser un ID) |

## Détection des cycles

### Algorithme simplifié

1. Construire un graphe dirigé `G` où chaque noeud est un BC.
2. Pour chaque noeud `N` du graphe :
   a. Faire un DFS depuis `N`.
   b. Si on atteint `N` à nouveau → cycle détecté.
3. Reporter le chemin du cycle : `A → B → C → A`.

### Cycles acceptables vs problématiques

| Type de cycle | Acceptable ? |
|---|---|
| Via Domain Events (async) | Acceptable si intentionnel |
| Via `use` statements directs | Problématique — couplage circulaire |
| Via Doctrine relations | Critique — dépendance bidirectionnelle en base |
| Via Messenger commands | Warning — considérer un Saga pattern |

## Métriques

### Instabilité (Robert C. Martin)

```
I = Ce / (Ca + Ce)

Ca = couplage afférent (nombre de BC qui dépendent de ce BC)
Ce = couplage efférent (nombre de BC dont ce BC dépend)
```

- I = 0 → Stable (beaucoup de dépendants, peu de dépendances)
- I = 1 → Instable (peu de dépendants, beaucoup de dépendances)
- Les BC Domain devraient être stables (I < 0.5)
- Les BC Infrastructure peuvent être instables (I > 0.5)

### Abstractness

```
A = Na / Nc

Na = nombre d'interfaces/classes abstraites
Nc = nombre total de classes
```

### Distance from Main Sequence

```
D = |A + I - 1|
```

- D = 0 → Sur la séquence principale (bon équilibre)
- D > 0.5 → Soit trop abstrait et instable, soit trop concret et stable

## Metrique de taille du Shared Kernel

Un Shared Kernel surdimensionne est un signe de mauvaise separation des Bounded Contexts. Quand trop de classes finissent dans `Shared/`, `Common/` ou `SharedKernel/`, cela signifie que les frontieres entre BC sont floues et que le noyau partage est devenu un fourre-tout.

### Commande de scan

```bash
# Compter les classes dans le Shared Kernel
# Paths a adapter selon le projet : ajouter/retirer des dossiers selon la convention utilisee
shared_count=$(find src/Shared/ src/Core/ src/Kernel/ src/Common/ src/Common/Kernel/ src/SharedKernel/ -name "*.php" 2>/dev/null | wc -l | tr -d ' ')

# Compter toutes les classes du projet
total_count=$(find src/ -name "*.php" | wc -l | tr -d ' ')

# Calculer le ratio
echo "Shared Kernel: ${shared_count} / ${total_count} classes"
echo "scale=1; ${shared_count} * 100 / ${total_count}" | bc
```

### Formule

```
Shared Kernel classes / Total classes = X%
```

### Bareme

| Ratio | Evaluation |
|-------|-----------|
| < 5% | Excellent -- SharedKernel minimal et focalise |
| 5-10% | Acceptable -- surveiller la croissance |
| 10-20% | Warning -- le SharedKernel grossit trop, certains elements devraient migrer dans leur BC |
| > 20% | Critique -- le SharedKernel est devenu un fourre-tout, refactoring necessaire |

### Interpretation

- **< 5%** : le Shared Kernel ne contient que l'essentiel (Value Objects partages, interfaces de base, events cross-BC). C'est l'objectif.
- **5-10%** : zone de vigilance. Verifier que chaque classe dans le Shared Kernel a une vraie raison d'etre partagee.
- **10-20%** : trop de logique metier est partagee. Identifier les classes qui appartiennent a un seul BC et les y deplacer.
- **> 20%** : le projet n'a pas de vraie separation en Bounded Contexts. Le `Shared/` est devenu le namespace par defaut. Un refactoring structurel est necessaire.
