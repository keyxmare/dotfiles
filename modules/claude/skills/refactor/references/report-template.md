# Report Template — Refactor

## Template rapport Phase 2 (audit)

```markdown
## Rapport de refactorisation — [Nom du projet]

### Résumé
- Fichiers analysés : X
- Problèmes trouvés : X (critiques: X, majeurs: X, mineurs: X)
- Score de conformité estimé : X/100

### Problèmes critiques 🔴
> Violations qui cassent l'architecture ou créent des risques sécurité.
1. [Fichier:ligne] Description — Pourquoi c'est critique — Correction proposée

### Problèmes majeurs 🟠
> Violations des conventions qui dégradent la maintenabilité.
1. [Fichier:ligne] Description — Impact — Correction proposée

### Problèmes mineurs 🟡
> Améliorations recommandées pour la cohérence et la qualité.
1. [Fichier:ligne] Description — Suggestion

### Points positifs ✅
> Ce qui est déjà bien fait et conforme aux standards.

### Plan de refactorisation proposé
> Ordre de priorité pour les corrections, groupées par type.
1. Corrections critiques (sécurité, fuites de dépendances)
2. Corrections architecturales (DDD, séparation des couches)
3. Améliorations de qualité (typage, nommage, PHP moderne)
4. Ajout de tests manquants
```

## Template résumé final Phase 4 (bilan)

```markdown
## Bilan de refactorisation — [Nom du projet]

### Modifications effectuées
- Fichiers modifiés : X
- Fichiers créés : X
- Fichiers supprimés : X

### Corrections par catégorie
| Catégorie | Nombre | Exemples |
|---|---|---|
| Sécurité | X | [descriptions courtes] |
| Architecture DDD | X | [descriptions courtes] |
| Qualité PHP | X | [descriptions courtes] |
| Tests ajoutés | X | [descriptions courtes] |
| Code mort supprimé | X | [descriptions courtes] |

### Problèmes restants non traités
1. [Problème] — Raison : [hors scope / trop risqué / besoin de confirmation]

### Recommandations pour la suite
1. [Recommandation prioritaire]
2. [Recommandation secondaire]
```

## Template résumé (--summary)

**Refactor — Résumé**

**Score de conformité : X/100**

| Catégorie | Problèmes | Dont critiques |
|-----------|-----------|----------------|
| Architecture DDD | X | X |
| Qualité PHP | X | X |
| Sécurité | X | X |
| Error Handling | X | X |
| Database | X | X |
| Code smells | X | X |

**Top 5 problèmes :**
1. ...

## Template JSON (--output=json)

```json
{
  "skill": "refactor",
  "date": "YYYY-MM-DD",
  "scope": "src/",
  "score": 72,
  "problems": {
    "critical": [{"file": "...", "line": 0, "category": "...", "description": "...", "correction": "..."}],
    "major": [],
    "minor": []
  },
  "positives": ["..."],
  "plan": [{"phase": "A", "step": 1, "description": "...", "files": ["..."]}]
}
```
