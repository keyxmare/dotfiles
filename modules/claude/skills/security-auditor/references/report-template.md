# Template de rapport — Security Auditor

## Format Markdown (défaut)

```markdown
# Audit de sécurité — [Nom du projet]

**Date** : YYYY-MM-DD
**Scope** : [scope analysé]
**Version Symfony** : X.Y
**Score global** : [SCORE/10] — Grade [A-F] [BARRE_VISUELLE]

## Tableau des axes

| # | Axe | Score | Grade |
|---|-----|-------|-------|
| 1 | Injection | X/10 | [GRADE] |
| 2 | Auth & Authz | X/10 | [GRADE] |
| 3 | Secrets & Données | X/10 | [GRADE] |
| 4 | Headers & Transport | X/10 | [GRADE] |
| 5 | Dépendances | X/10 | [GRADE] |
| 6 | Configuration | X/10 | [GRADE] |

## Vulnérabilités critiques

| # | Catégorie | Fichier | Ligne | Description | Impact | Correction |
|---|-----------|---------|-------|-------------|--------|-----------|
| 1 | Injection SQL | src/... | L42 | Concaténation de $id dans une requête DQL | Exfiltration de données | Utiliser setParameter() |

## Vulnérabilités hautes

| # | Catégorie | Fichier | Ligne | Description | Correction |
|---|-----------|---------|-------|-------------|-----------|

## Vulnérabilités moyennes

| # | Catégorie | Fichier | Ligne | Description | Correction |
|---|-----------|---------|-------|-------------|-----------|

## Informations

| # | Catégorie | Description | Recommandation |
|---|-----------|-------------|---------------|

## Plan de remédiation

### Priorité haute (corriger immédiatement)
1. [ ] [Description] — Fichier: `src/...` — Effort: faible

### Priorité moyenne (corriger rapidement)
1. [ ] [Description] — Effort: moyen

### Priorité basse (amélioration continue)
1. [ ] [Description] — Effort: faible
```

## Template résumé (si `--summary`)

```markdown
# Sécurité — Résumé

**Score** : [SCORE/10] — Grade [GRADE]

| Axe | Score |
|-----|-------|
| Injection | X/10 |
| Auth & Authz | X/10 |
| Secrets | X/10 |
| Headers | X/10 |
| Dépendances | X/10 |
| Configuration | X/10 |

**Top 5 vulnérabilités** :
1. [Critique] description — `fichier:ligne`
2. ...

**Actions prioritaires** : X critiques, Y hautes à corriger.
```

## Template JSON (--output=json)

```json
{
  "skill": "security-auditor",
  "date": "YYYY-MM-DD",
  "scope": "src/",
  "score": {"global": 7.2, "grade": "B"},
  "axes": {
    "injection": {"score": 9.0},
    "auth": {"score": 7.0},
    "secrets": {"score": 6.0},
    "headers": {"score": 8.0},
    "dependencies": {"score": 7.0},
    "config": {"score": 6.0}
  },
  "vulnerabilities": {
    "critical": [],
    "high": [],
    "medium": [],
    "info": []
  }
}
```
