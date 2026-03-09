# Continuity — Reprise automatique et exécution autonome

## 1. Reprise après compaction

### Principe

Lors d'une compaction de contexte, les messages précédents sont compressés. Ce mécanisme garantit une reprise sans interruption via un fichier d'état persisté sur disque. `continuity.enabled`

### Fichier d'état

- Chemin : `.claude/task-state.local.md` (relatif au projet courant)
- Temporaire — supprimé une fois la tâche terminée.
- Le suffixe `.local.md` garantit qu'il est ignoré par git.

### Quand écrire l'état

- **Avant de commencer** une tâche comportant plus de 3 étapes ou susceptible de consommer beaucoup de contexte.
- **Après chaque étape complétée**, mettre à jour le fichier.
- **À la fin de la tâche**, supprimer le fichier.

### Format du fichier d'état

```markdown
---
version: 1
task: "<description courte>"
status: "in_progress"
started_at: "<timestamp ISO 8601>"
current_step: <numéro>
total_steps: <numéro>
---

## Objectif

<description complète de la demande utilisateur>

## Plan

- [x] Étape 1 — <description>
- [x] Étape 2 — <description>
- [ ] Étape 3 — <description> <- en cours
- [ ] Étape 4 — <description>

## Contexte critique

<fichiers modifiés, décisions prises, chemins, variables, erreurs>

## Prochaine action

<action immédiate à effectuer pour reprendre>
```

### Après compaction — Comportement attendu

1. Lire `.claude/task-state.local.md` s'il existe.
2. Si `status` est `in_progress` : informer brièvement et reprendre sans demander confirmation.
3. Si le fichier n'existe pas ou `status` est `completed`, ne rien faire.

### Sauvegarde de l'état

La sauvegarde se fait de manière proactive pendant l'exécution : écrire ou mettre à jour le fichier d'état à chaque étape complétée (voir "Quand écrire l'état" ci-dessus). Pas de hook automatique à l'arrêt.

### Hooks associés

| Hook | Type | Rôle |
|---|---|---|
| `PreCompact` | `command` | Log la compaction pour traçabilité |

Configuration dans `~/.claude/settings.json` :

```json
{
  "hooks": {
    "PreCompact": [
      {
        "matcher": "*",
        "hooks": [
          {
            "type": "command",
            "command": "mkdir -p ~/.claude/logs && echo \"[$(date -Iseconds)] Context compacted\" >> ~/.claude/logs/compactions.log",
            "timeout": 5
          }
        ]
      }
    ]
  }
}
```

### Règles

- Ne jamais demander à l'utilisateur s'il veut reprendre — reprendre automatiquement.
- Fichier éphémère, lié à la session. Pas une mémoire persistante.
- Garder le fichier concis : uniquement les infos nécessaires à la reprise.
- En cas de fichier corrompu ou incohérent, demander à l'utilisateur.

### Gestion des cas limites

- **Fichiers supprimés** — Si un fichier référencé dans le contexte critique n'existe plus, le signaler à l'utilisateur et adapter le plan en conséquence.
- **Expiration** — Si `started_at` date de plus de 24h, demander confirmation avant de reprendre. Le contexte peut être obsolète.
- **Version** — Si `version` est absente ou supérieure à la version connue, demander à l'utilisateur. Ne pas tenter d'interpréter un format inconnu.
- **Tâches concurrentes** — Si une nouvelle tâche longue est demandée alors qu'un `task-state.local.md` existe déjà, renommer le fichier existant en `task-state.local.<slug-tâche>.md` et créer le nouveau. À la fin de chaque tâche, vérifier s'il reste des fichiers d'état en attente et proposer à l'utilisateur de les reprendre ou de les supprimer.

---

## 2. Exécution autonome de grosses features

### Décomposition obligatoire

Pour toute feature touchant plus de 10 fichiers ou nécessitant plus de 5 étapes :

1. **Planifier d'abord** — Produire un plan détaillé avant toute modification :
   - Liste exhaustive des fichiers à créer / modifier / supprimer.
   - Ordre d'exécution avec dépendances.
   - Points de vérification intermédiaires.
2. **Présenter le plan à l'utilisateur** pour validation avant exécution.
3. **Exécuter étape par étape** en mettant à jour le fichier d'état (section 1).

### Parallélisation avec subagents

Quand des sous-tâches sont indépendantes (pas de dépendance entre elles) :

- Utiliser le tool `Agent` avec `isolation: "worktree"` pour que chaque agent travaille dans un worktree git isolé.
- Les agents parallèles ne doivent pas modifier les mêmes fichiers.
- Exemples de tâches parallélisables : tests, lint, fichiers dans des bounded contexts différents, migrations indépendantes.

### Stratégies par taille de feature

| Taille | Fichiers | Stratégie |
|---|---|---|
| Petite | 1-10 | Exécution directe, fichier d'état si > 3 étapes |
| Moyenne | 10-50 | Plan + validation + fichier d'état + subagents si possible |
| Grande | 50+ | Plan + validation + découpage en sous-features + subagents worktree |

### Règles d'exécution autonome

- **Ne jamais s'arrêter en milieu de plan** sans mettre à jour le fichier d'état.
- **Vérifier après chaque étape** que le code compile / les tests passent (si applicable).
- **En cas d'erreur bloquante**, documenter dans le fichier d'état et tenter de résoudre avec une approche différente. Si impossible après 2 approches distinctes (pas le même retry), informer l'utilisateur avec le contexte de l'erreur et les approches tentées.
- **Les commandes runtime** (npm, bun, composer, php, symfony) ne s'exécutent **jamais en direct** — toujours via `docker compose exec` ou `make`. `containers.runtime_only`
- **Checkpoint toutes les 10 étapes** — demander une validation utilisateur pour confirmer la direction. Ne pas enchaîner plus de 10 étapes sans feedback.
- **Timeout** — si un plan dépasse 30 étapes, découper obligatoirement en sous-features indépendantes.
