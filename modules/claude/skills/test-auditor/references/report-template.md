# Report Template — Test Auditor

## Template rapport Phase 4

```markdown
## Test Auditor Report — [Nom du projet]

### Score Global : [GRADE] ([score]/10)

### Résumé
- Tests trouvés : X (unitaires: X, intégration: X, fonctionnels: X)
- Couverture estimée : X%
- Tests fantômes : X
- Tests fragiles (>5 mocks) : X
- Tests lents (mauvais TestCase) : X
- Ratio moyen assertions/test : X.X

### Scores par axe

| Axe | Score | Grade |
|-----|-------|-------|
| Couverture globale | X.X/10 | [GRADE] |
| Qualité des tests | X.X/10 | [GRADE] |
| Nommage | X.X/10 | [GRADE] |
| Fixtures | X.X/10 | [GRADE] |
| Couverture DDD | X.X/10 | [GRADE] |
| Bonus Mutation Testing | +X.X | — |
| Bonus Architecture Tests | +X.X | — |
| **Score final** | **X.X/10** (plafond 10) | **[GRADE]** |

> Score final = moyenne des 5 axes + bonus_mutation + bonus_arch_tests (plafond global : 10)

### Couverture par couche DDD

| Couche | Fichiers testables | Testés | Couverture | Attendu |
|--------|-------------------|--------|------------|---------|
| Domain | X | Y | Z% | ≥80% |
| Application | X | Y | Z% | ≥70% |
| Infrastructure | X | Y | Z% | ≥50% |

### Couverture par Bounded Context

| BC | Tests | Couverture | Fantômes | Fragiles |
|----|-------|------------|----------|----------|
| Catalog | X | X% | X | X |
| Order | X | X% | X | X |

### Tests fantômes (X trouvés)

| # | Test | Fichier | Raison |
|---|------|---------|--------|
| 1 | `test_it_does_something()` | `tests/...` | Aucune assertion |

### Tests fragiles (X trouvés)

| # | Test | Fichier | Mocks | Raison |
|---|------|---------|-------|--------|
| 1 | `test_it_creates_product()` | `tests/...` | 7 | Sur-mocking |

### Tests lents / mal classifiés (X trouvés)

| # | Test | Fichier | Problème | Correction |
|---|------|---------|----------|-----------|
| 1 | `ProductServiceTest` | `tests/Unit/...` | `KernelTestCase` inutile | Changer en `TestCase` |
| 2 | `OrderHandlerTest` | `tests/Integration/...` | Test unitaire mal placé | Déplacer dans `tests/Unit/` |

### Enums non testes (X trouves)

| # | Enum | Fichier | Type | Test existant | Probleme |
|---|------|---------|------|---------------|----------|
| 1 | `StatusEnum` | `src/...` | Backed (string) | Non | `from()`/`tryFrom()` non testes |

### Exceptions non testees (X trouvees)

| # | Exception | Fichier | Logique custom | Test existant |
|---|-----------|---------|----------------|---------------|
| 1 | `OrderNotFoundException` | `src/...` | Message dynamique | Non |

### Migrations non testees (X critiques)

| # | Migration | Type | Test existant | Risque |
|---|-----------|------|---------------|--------|
| 1 | `Version20260101_MigrateUserData` | Data migration | Non | Haut — transformation de donnees |

> Note : seules les data migrations (pas schema-only) sont listees ici.

### Top fichiers non testés (priorité haute)

| # | Fichier | Couche | BC | Complexité | Raison critique |
|---|---------|--------|-----|-----------|----------------|
| 1 | `src/.../OrderService.php` | Application | Order | Haute | Logique métier non testée |

### Mutation Testing

| Métrique | Valeur |
|----------|--------|
| Outil | Infection X.X |
| MSI (Mutation Score Indicator) | X% |
| Mutants générés | X |
| Mutants tués | X |
| Mutants survivants | X |
| Bonus scoring | +X.X |

**Mutants survivants dans fichiers critiques :**

| # | Fichier | Couche | BC | Mutant | Ligne |
|---|---------|--------|-----|--------|-------|
| 1 | `src/.../PriceCalculator.php` | Domain | Catalog | Boundary condition | 42 |

**Recommandation :** [Si configuré : améliorer les tests sur les fichiers critiques. Si non configuré : installer `infection/infection` et viser un MSI >= 80% sur Domain/Application.]

### Architecture Tests

| Métrique | Valeur |
|----------|--------|
| Outil | [pest-plugin-arch / deptrac / non configuré] |
| Règles vérifiées | X |
| BC couverts | X / Y |
| Violations autorisées | X |
| Bonus scoring | +X.X |

**Règles de couche vérifiées :**

| # | Règle | Couverture |
|---|-------|-----------|
| 1 | Domain n'importe pas Infrastructure | Tous les BC |
| 2 | Domain n'importe pas Symfony | Tous les BC |
| 3 | Application n'importe pas Infrastructure | Partiel (X/Y BC) |

**Recommandation :** [Si configuré : étendre aux BC non couverts. Si non configuré : installer pest-plugin-arch ou deptrac pour vérifier les dépendances inter-couches.]

### Plan d'amélioration

1. **Priorité haute** : écrire les tests pour la couche Domain non testée
   - [ ] [Liste des fichiers critiques]
2. **Priorité moyenne** : corriger les tests fantômes et lents
   - [ ] [Liste des tests à corriger]
3. **Priorité basse** : améliorer le nommage et les fixtures
   - [ ] [Suggestions]
```

## Template résumé (si --summary)

```markdown
## Test Audit Summary — [Nom du projet]

**Score : [X.X]/10 [GRADE]**

| Axe | Score |
|-----|-------|
| Couverture | X.X |
| Qualité | X.X |
| DDD | X.X |

**Top 5 problèmes :**
1. [Problème 1]
2. [Problème 2]
3. [Problème 3]
4. [Problème 4]
5. [Problème 5]
```

## Template JSON (--output=json)

```json
{
  "skill": "test-auditor",
  "date": "YYYY-MM-DD",
  "scope": "tests/",
  "score": {"global": 6.5, "grade": "C"},
  "axes": {
    "coverage": {"score": 7.0, "ratio": 0.65},
    "quality": {"score": 6.0, "ghosts": 3, "fragile": 5},
    "naming": {"score": 8.0, "conformity": 0.85},
    "fixtures": {"score": 5.0, "pattern": "mixed"},
    "coverage_ddd": {"score": 7.0, "domain": true, "application": true, "infrastructure": false}
  },
  "bonus": {
    "mutation_testing": {"configured": false, "msi": null, "bonus": 0},
    "architecture_tests": {"configured": false, "tool": null, "bonus": 0}
  },
  "problems": [
    {"type": "ghost", "file": "...", "method": "...", "severity": "high"},
    {"type": "enum_untested", "file": "src/.../StatusEnum.php", "enum": "StatusEnum", "backed": true, "severity": "medium"},
    {"type": "exception_untested", "file": "src/.../OrderNotFoundException.php", "exception": "OrderNotFoundException", "has_logic": true, "severity": "medium"},
    {"type": "migration_untested", "file": "migrations/Version20260101.php", "migration_type": "data", "severity": "high"}
  ]
}
```
