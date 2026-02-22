# Template de rapport — API Auditor

## Format Markdown (défaut)

```markdown
# Audit API — [Nom du projet]

**Date** : YYYY-MM-DD
**Scope** : [scope analysé]
**Version API Platform** : X.Y
**Ressources analysées** : X
**Score global** : [SCORE/10] — Grade [A-F] [BARRE_VISUELLE]

## Tableau des axes

| # | Axe | Score | Grade |
|---|-----|-------|-------|
| 1 | Design des ressources | X/10 | [GRADE] |
| 2 | Opérations | X/10 | [GRADE] |
| 3 | Sérialisation | X/10 | [GRADE] |
| 4 | Pagination & Filtres | X/10 | [GRADE] |
| 5 | Documentation OpenAPI | X/10 | [GRADE] |
| 6 | Conformité DDD | X/10 | [GRADE] |

## Ressources analysées

| Ressource | URI | Type | Score | Problèmes |
|-----------|-----|------|-------|-----------|
| Product | /api/products | DTO + Provider | 8/10 | Docs manquantes |
| Order | /api/orders | Entité directe | 5/10 | Pas de DTO, IDs séquentiels |

## Problèmes par sévérité

### Critiques
| # | Catégorie | Ressource | Description | Correction |
|---|-----------|-----------|-------------|-----------|

### Hauts
| # | Catégorie | Ressource | Description | Correction |
|---|-----------|-----------|-------------|-----------|

### Moyens
| # | Catégorie | Ressource | Description | Correction |
|---|-----------|-----------|-------------|-----------|

## Plan d'amélioration

### Priorité haute
1. [ ] [Description] — Ressource: [X] — Effort: [faible/moyen/élevé]

### Priorité moyenne
1. [ ] [Description] — Effort: [moyen]

### Priorité basse
1. [ ] [Description] — Effort: [faible]
```

## Template résumé (si `--summary`)

```markdown
# API — Résumé

**Score** : [SCORE/10] — Grade [GRADE]
**Ressources** : X analysées

| Axe | Score |
|-----|-------|
| Ressources | X/10 |
| Opérations | X/10 |
| Sérialisation | X/10 |
| Pagination | X/10 |
| Documentation | X/10 |
| Conformité DDD | X/10 |

**Top 5 problèmes** :
1. [Sévérité] description — Ressource: X
2. ...

**Actions prioritaires** : X critiques, Y hauts à corriger.
```

## Template JSON (--output=json)

```json
{
  "skill": "api-auditor",
  "date": "YYYY-MM-DD",
  "scope": "src/",
  "api_platform_version": "4.x",
  "score": {"global": 6.8, "grade": "C"},
  "axes": {
    "resources": {"score": 7.0},
    "operations": {"score": 8.0},
    "serialization": {"score": 5.0},
    "pagination": {"score": 7.0},
    "documentation": {"score": 6.0},
    "ddd": {"score": 7.0}
  },
  "resources": [
    {"fqcn": "...", "uri": "/api/products", "type": "entity", "score": 6.5, "problems": []}
  ]
}
```
