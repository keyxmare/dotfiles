# Checklist d'analyse — Commandes de détection

## Détection rapide par pattern

### Fuites de dépendances Domain
```bash
# Imports Symfony/Doctrine/ApiPlatform dans le Domain
grep -rn "use Symfony\\\|use Doctrine\\\|use ApiPlatform" src/*/Domain/ 2>/dev/null
```

### Strict types manquants
```bash
# Fichiers PHP sans declare(strict_types=1)
find src/ -name "*.php" -exec grep -L "declare(strict_types=1)" {} \;
```

### Debug oubliés
```bash
# dump, dd, var_dump, die, print_r
grep -rn "dump(\|dd(\|var_dump(\|die(\|print_r(" src/ 2>/dev/null
```

### Setters publics
```bash
# Setters dans les entités Domain
grep -rn "public function set[A-Z]" src/*/Domain/Model/ 2>/dev/null
```

### Catch génériques
```bash
# catch(\Exception) ou catch(Exception)
grep -rn "catch\s*(\s*\\?Exception" src/ 2>/dev/null
```

### Concaténation SQL
```bash
# Requêtes SQL concaténées
grep -rn '"\s*SELECT\|"\s*INSERT\|"\s*UPDATE\|"\s*DELETE' src/ 2>/dev/null | grep '\$\|\..*\.'
```

### Raw Twig
```bash
grep -rn "|raw" templates/ 2>/dev/null
```

### Exec/Shell_exec
```bash
grep -rn "exec(\|shell_exec(\|system(\|passthru(" src/ 2>/dev/null
```

### Code mort potentiel (classes jamais utilisées)
```bash
# Lister les classes et vérifier les imports
grep -rn "^class \|^abstract class \|^final class \|^readonly class " src/ 2>/dev/null
```

### God Classes (> 300 lignes)
```bash
find src/ -name "*.php" -exec awk 'END{if(NR>300) print FILENAME": "NR" lines"}' {} \;
```

### Méthodes longues (> 30 lignes)
```bash
# Approximation via comptage d'accolades — vérification manuelle recommandée
```

## Vérifications structurelles

### Structure DDD attendue
```
src/
  <BoundedContext>/
    Domain/
      Model/          → Entities, Value Objects, Collections
      Event/          → Domain Events
      Exception/      → Domain Exceptions
      Repository/     → Interfaces uniquement
      Service/        → Domain Services
      Specification/  → Business rules
    Application/
      Command/        → Commands + Handlers
      Query/          → Queries + Handlers
      DTO/            → Response DTOs
      Port/           → Secondary port interfaces
      EventHandler/   → Domain event handlers
    Infrastructure/
      Persistence/    → Doctrine repositories + mappings
      Symfony/        → Controllers, Forms
      Adapter/        → External service adapters
```

### Vérifications par couche

#### Domain
- Aucun namespace `Symfony`, `Doctrine`, `ApiPlatform`
- Uniquement des interfaces pour les repositories
- Value Objects avec `readonly class`
- Pas de setters, uniquement des méthodes métier
- Exceptions héritant d'une `DomainException` de base

#### Application
- Commands/Queries en `readonly class`
- Un handler par Command/Query
- Pas d'accès direct à Doctrine (via interfaces)
- Pas de logique métier (orchestration uniquement)

#### Infrastructure
- Controllers minimalistes (dispatch command/query)
- Repositories implémentant les interfaces Domain
- Mapping Doctrine en XML de préférence
- Adapters pour les services externes
