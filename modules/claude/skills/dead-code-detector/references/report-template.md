# Template de rapport — Dead Code Detector

## Format Markdown

```markdown
## Dead Code Report — [Nom du projet]

### Résumé
- Fichiers analysés : X
- Éléments inventoriés : X
- Code mort détecté : X éléments
  - Certain : X
  - Probable : X
  - Suspect : X
- Estimation de code supprimable : ~X lignes
- Bounded Contexts concernés : [liste]

### Services morts (X trouvés)

#### Certains
| # | Service | BC | Fichier | Lignes | Confiance | Impact |
|---|---------|-----|---------|--------|-----------|--------|
| 1 | `App\Catalog\Application\Service\PriceCalculator` | Catalog | `src/Catalog/Application/Service/PriceCalculator.php` | 85 | certain | safe |

**Pourquoi mort :** Aucun `use`, aucune injection, aucun tag, aucune config.
**Action :** Supprimer `PriceCalculator.php`

#### Probables
...

#### Suspects
...

### Routes mortes (X trouvées)
...

### Event Listeners morts (X trouvés)
...

### Handlers Messenger morts (X trouvés)
...

### DTOs morts (X trouvés)
...

### Repositories morts (X trouvés)
...

### Interfaces mortes (X trouvées)
...

### Commandes console mortes (X trouvées)
...

### Templates Twig morts (X trouvés)
...

### Clés de traduction mortes (X trouvées)
...

### FormTypes morts (X trouvés)
...

### Voters morts (X trouvés)
...

### Enums mortes (X trouvées)

| # | FQCN | Type | Cases | Confiance | Impact | Action |
|---|------|------|-------|-----------|--------|--------|
| 1 | `App\Catalog\Domain\Enum\ProductStatus` | string-backed | Active, Inactive, Draft | certain | safe | Supprimer |

**Pourquoi morte :** Aucun `use`, aucun accès aux cases, aucun type-hint, aucun mapping Doctrine.

### Exceptions mortes (X trouvées)

| # | FQCN | Classe parente | Couche | Catégorie | Confiance | Action |
|---|------|---------------|--------|-----------|-----------|--------|
| 1 | `App\Catalog\Domain\Exception\ProductNotFoundException` | DomainException | Domain | orpheline | certain | Supprimer |
| 2 | `App\Order\Application\Exception\PaymentFailedException` | RuntimeException | Application | jamais throw | probable | Vérifier — catch sans throw |

**Pourquoi morte :** Aucun `throw new`, aucun `catch`, aucun `instanceof`, aucun `expectException()` dans les tests.

### Migrations mortes (X trouvées)

| # | Fichier | Timestamp | Tables référencées | Pertinence | Action |
|---|---------|-----------|-------------------|------------|--------|
| 1 | `Version20240115120000.php` | 2024-01-15 | product_legacy, product_legacy_tag | Tables supprimées depuis | Supprimer (info) |

**Note :** Les migrations sont un historique de schéma. Signalées comme **info**, pas comme code mort critique.

### Cascades de suppression

Si un élément mort entraîne d'autres suppressions :

```
PriceCalculator (service)
  └── PriceCalculatorInterface (interface orpheline après suppression)
      └── PriceCalculatorTest (test du service mort)
```

### Métriques par Bounded Context

| BC | Services morts | Listeners morts | Handlers morts | Total | % du BC |
|----|---------------|-----------------|----------------|-------|---------|
| Catalog | 3 | 1 | 0 | 4 | 12% |
| Order | 0 | 0 | 2 | 2 | 5% |

### Plan de nettoyage recommandé

> Ordre de suppression pour éviter les erreurs :

1. **Supprimer les fichiers sans dépendance** (confiance: certain, impact: safe)
   - Liste des fichiers à supprimer
2. **Supprimer les cascades** (en commençant par les feuilles)
   - Liste groupée
3. **Investiguer les suspects**
   - Éléments à vérifier manuellement avec contexte
4. **Nettoyer la configuration**
   - Entrées `services.yaml` à retirer
   - Routes YAML à retirer
   - Bindings devenus inutiles
```

## Template resume (`--summary`)

```markdown
## Dead Code Summary — [Nom du projet]

**Date :** YYYY-MM-DD | **Scope :** src/ | **Fichiers analyses :** X

### Recapitulatif par type

| Type | Certains | Probables | Suspects | Total |
|------|----------|-----------|----------|-------|
| Services | 0 | 0 | 0 | 0 |
| Routes | 0 | 0 | 0 | 0 |
| Event Listeners | 0 | 0 | 0 | 0 |
| Handlers Messenger | 0 | 0 | 0 | 0 |
| DTOs | 0 | 0 | 0 | 0 |
| Repositories | 0 | 0 | 0 | 0 |
| Interfaces | 0 | 0 | 0 | 0 |
| Commandes console | 0 | 0 | 0 | 0 |
| Templates Twig | 0 | 0 | 0 | 0 |
| Traductions | 0 | 0 | 0 | 0 |
| FormTypes | 0 | 0 | 0 | 0 |
| Voters | 0 | 0 | 0 | 0 |
| Enums | 0 | 0 | 0 | 0 |
| Exceptions | 0 | 0 | 0 | 0 |
| Migrations | 0 | 0 | 0 | 0 |
| **Total** | **0** | **0** | **0** | **0** |

### Top 5 fichiers/services les plus impactes

| # | Element | Type | Lignes supprimables | BC |
|---|---------|------|--------------------|----|
| 1 | `App\...` | service | ~X lignes | BC |
| 2 | ... | ... | ... | ... |

### Score global de proprete

| Metrique | Valeur |
|----------|--------|
| Code mort / code total | X% |
| Lignes supprimables | ~X |
| Bounded Contexts touches | X / Y |
| Confiance moyenne | certain / probable / suspect |

> **Verdict :** [Propre / Acceptable / Nettoyage recommande / Nettoyage urgent]
```

## Format JSON (si `--output=json`)

```json
{
  "project": "nom-du-projet",
  "scan_date": "2026-02-21",
  "scope": "src/",
  "summary": {
    "files_scanned": 0,
    "items_inventoried": 0,
    "dead_code_found": 0,
    "removable_lines": 0
  },
  "dead_code": [
    {
      "type": "service",
      "fqcn": "App\\Catalog\\Application\\Service\\PriceCalculator",
      "file": "src/Catalog/Application/Service/PriceCalculator.php",
      "line_count": 85,
      "bounded_context": "Catalog",
      "confidence": "certain",
      "impact": "safe",
      "reason": "No use statement, no injection, no tag, no config reference",
      "cascade": ["PriceCalculatorInterface", "PriceCalculatorTest"]
    },
    {
      "type": "enum",
      "fqcn": "App\\Catalog\\Domain\\Enum\\ProductStatus",
      "file": "src/Catalog/Domain/Enum/ProductStatus.php",
      "enum_type": "string-backed",
      "cases": ["Active", "Inactive", "Draft"],
      "bounded_context": "Catalog",
      "confidence": "certain",
      "impact": "safe",
      "reason": "No use statement, no case access, no type-hint, no Doctrine mapping"
    },
    {
      "type": "exception",
      "fqcn": "App\\Catalog\\Domain\\Exception\\ProductNotFoundException",
      "file": "src/Catalog/Domain/Exception/ProductNotFoundException.php",
      "parent_class": "DomainException",
      "layer": "Domain",
      "category": "orphan",
      "bounded_context": "Catalog",
      "confidence": "certain",
      "impact": "safe",
      "reason": "No throw, no catch, no instanceof, no expectException"
    },
    {
      "type": "migration",
      "file": "migrations/Version20240115120000.php",
      "timestamp": "2024-01-15",
      "tables_referenced": ["product_legacy", "product_legacy_tag"],
      "relevance": "Tables dropped since migration was executed",
      "confidence": "info",
      "impact": "safe",
      "reason": "Migration executed, referenced tables no longer exist in current schema"
    }
  ]
}
```
