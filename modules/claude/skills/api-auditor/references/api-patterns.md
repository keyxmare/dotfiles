# Patterns de détection — API Auditor

## Commandes de scan rapide

### Inventaire des ressources
```bash
# Toutes les classes avec #[ApiResource]
grep -rn "#\[ApiResource" src/ --include="*.php"
# Opérations custom
grep -rn "#\[Get\]\|#\[Post\]\|#\[Put\]\|#\[Patch\]\|#\[Delete\]\|#\[GetCollection\]" src/ --include="*.php"
# State Providers
grep -rn "implements ProviderInterface\|provider:" src/ --include="*.php"
# State Processors
grep -rn "implements ProcessorInterface\|processor:" src/ --include="*.php"
```

### Sérialisation
```bash
# Groupes de sérialisation
grep -rn "normalizationContext\|denormalizationContext\|#\[Groups\]" src/ --include="*.php"
# Ressources sans groupes
grep -rn "#\[ApiResource" src/ --include="*.php" -l | xargs grep -L "normalizationContext\|Groups"
```

### Pagination
```bash
# Configuration pagination
grep -rn "paginationEnabled\|itemsPerPage\|maximumItemsPerPage" src/ config/ --include="*.php" --include="*.yaml"
```

### Filtres
```bash
# Tous les filtres
grep -rn "#\[ApiFilter\]" src/ --include="*.php"
# SearchFilter avec partial
grep -rn "SearchFilter.*partial" src/ --include="*.php"
```

### Documentation
```bash
# Descriptions dans les ressources
grep -rn "description:" src/ --include="*.php" | grep -i "ApiResource\|ApiProperty"
# OpenAPI context
grep -rn "openapi_context\|openapiContext" src/ --include="*.php"
```

### Conformité DDD
```bash
# Doctrine entities with ApiResource (anti-pattern)
grep -rn "#\[ORM\\\\Entity\]" src/ --include="*.php" -l | xargs grep -l "#\[ApiResource\]"
# Import API Platform dans Domain
grep -rn "use ApiPlatform" src/*/Domain/ --include="*.php"
```

### DDD boundary violations
```bash
# Detect EntityManager directly injected in State Providers/Processors (anti-pattern)
grep -rn "EntityManagerInterface" src/ --include="*Provider.php" --include="*Processor.php"

# Detect Domain layer importing API Platform (boundary violation)
grep -rn "use ApiPlatform" src/Domain/ src/*/Domain/ --include="*.php"
```

## Anti-patterns courants

| Anti-pattern | Détection | Correction |
|-------------|-----------|-----------|
| Entité exposée directement | `#[ORM\Entity]` + `#[ApiResource]` sur la même classe | Extraire un DTO avec State Provider/Processor |
| Pas de groupes de sérialisation | `#[ApiResource]` sans `normalizationContext` | Ajouter des groupes `read`, `write`, `read:collection` |
| IDs séquentiels exposés | Propriété `id` de type `int` exposée | Utiliser des UUIDs (`Uuid::v7()`) |
| Pagination désactivée sur grande collection | `paginationEnabled: false` sur une collection > 100 items | Activer la pagination |
| Filtre sur colonne non indexée | `#[ApiFilter(SearchFilter::class)]` sur un champ sans index | Ajouter l'index ou retirer le filtre |
| Nesting profond | 3+ niveaux d'URI (`/a/{id}/b/{id}/c`) | Aplatir avec des filtres ou des sub-resources |
| Verbe dans l'URI | `POST /create-product` | `POST /products` |

## Faux positifs

| Pattern | Pourquoi ce n'est PAS un problème |
|---------|----------------------------------|
| Entité simple CRUD exposée directement | Acceptable si groupes de sérialisation stricts et pas de logique métier |
| Pagination désactivée sur un enum/référentiel | Collections petites et stables |
| Pas de description sur les opérations CRUD standard | Les opérations standard sont auto-documentées |
| Custom operation sur une action métier (`/cancel`, `/publish`) | Légitime si l'action ne mappe pas sur un CRUD |
