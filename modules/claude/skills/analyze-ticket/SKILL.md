---
name: analyze-ticket
description: Analyse un ticket Redmine, identifie le projet concerné, propose et implémente un correctif, teste, documente avec le numéro de ticket
allowed-tools: Read, Write, Edit, Glob, Grep, Agent, Bash(git *), Bash(ls:*), Bash(make:*), Bash(docker compose:*), Bash(docker exec:*), mcp__redmine__redmine_get_ticket, mcp__redmine__redmine_add_note, mcp__context7__resolve-library-id, mcp__context7__query-docs
---

# Skill — Analyze Ticket

Workflow complet : ticket Redmine → analyse → correctif → tests → documentation.

## Input

`$ARGUMENTS` = ID ou URL du ticket Redmine (ex: `53824`, `https://redmine.motoblouz.com/issues/53824`)

---

## Phase 1 — Récupérer le ticket

```
mcp__redmine__redmine_get_ticket { id: "<id>" }
```

Extraire :
- **subject** — titre du problème
- **description** — détails
- **notes** — derniers commentaires (contexte, précisions)
- **tracker** — Incident / DDS / Anomalie
- **priority** — pour calibrer l'urgence
- **custom_fields[id=68]** — Type de Ticket

Résumer en une phrase : _"Ce ticket concerne X dans le contexte Y."_

---

## Phase 2 — Identifier le(s) projet(s) concerné(s)

```
Read ~/.claude/projects.json
```

**Détection automatique** : pour chaque projet, comparer ses `redmine_keywords` avec les mots du subject + description.
Scorer par nombre de matches.

**Résultat :**
- 1 projet clair → confirmer avec l'utilisateur avant de continuer
- Plusieurs candidats → afficher le score et demander lequel (ou plusieurs)
- Aucun match → demander à l'utilisateur de préciser (ou lancer `/project add`)

---

## Phase 3 — Charger le contexte projet

Pour chaque projet retenu :

1. Vérifier que le path existe : `ls <path>`
2. Lire la config projet si présente :
   ```
   Read <path>/.claude/CLAUDE.md   (conventions, stack, règles)
   Read <path>/README.md           (si pas de CLAUDE.md)
   ```
3. Détecter la stack réelle :
   ```
   Glob <path>/composer.json       → PHP/Symfony
   Glob <path>/package.json        → Node/Nuxt/Vue
   Glob <path>/Makefile            → commandes dispo
   ```
4. Charger les credentials BDD si pertinents (ticket data / requête BDD) :
   ```
   Read ~/.config/claude/db.json
   ```
   → Utiliser uniquement l'env `local` pour l'analyse. Jamais `prod` sauf si explicitement demandé.

---

## Phase 4 — Analyse du problème

**Recherche dans le code** — utiliser les mots-clés du ticket :

```
Grep "<mot-clé-1>" <path>/src --type=php (ou ts, js...)
Grep "<mot-clé-2>" <path>/src
Glob <path>/src/**/*<mot-clé>*
```

**Historique git récent** :
```bash
git -C <path> log --oneline -20
git -C <path> log --oneline --all -- <fichier-suspect>
```

**Analyse statique si disponible** :
```bash
# PHP
make -C <path> phpstan 2>&1 | head -50
# TS
make -C <path> typecheck 2>&1 | head -50
```

**Consulter la doc** si le problème touche une lib externe :
```
mcp__context7__resolve-library-id { libraryName: "<lib>" }
mcp__context7__query-docs { ... }
```

**Synthèse** : décrire la cause probable en 2-3 phrases, citer les fichiers/lignes suspects.

---

## Phase 5 — Proposer des approches

Proposer **1 à 3 approches** selon la complexité :

```
### Approche A — <nom> [Complexité: S/M/L]
**Principe :** ...
**Fichiers impactés :** ...
**Avantages :** ...
**Inconvénients / risques :** ...

### Approche B — <nom> [Complexité: S/M/L]
...
```

Recommander une approche (celle qui équilibre sécurité + simplicité).

**Demander confirmation avant d'implémenter.**

---

## Phase 6 — Implémenter le correctif

1. **Créer une branche** (si `git.auto_branch` actif) :
   ```bash
   git -C <path> switch -c fix/ticket-<id>-<slug>
   ```
   `<slug>` = subject du ticket en kebab-case, max 40 chars.

2. **Implémenter** selon les conventions du projet (CLAUDE.md) :
   - Respecter les patterns existants
   - Pas de commentaires sauf si `code.comments: true`
   - Taille fichiers < 300 lignes

3. **Écrire un test de non-régression** avant/pendant le fix (si framework de test dispo) :
   - Le test doit échouer AVANT le fix, passer APRÈS
   - Nommer le test avec le numéro de ticket : `test_ticket_<id>_<description>`

---

## Phase 7 — Vérification

Dans l'ordre, lancer les commandes disponibles (depuis `projects.json > commands` ou Makefile détecté) :

```bash
# Tests
make -C <path> test    (ou: docker compose exec app make test)

# Lint
make -C <path> lint

# Analyse statique
make -C <path> phpstan / typecheck / analyse
```

Si erreurs : corriger avant de continuer. Ne pas passer à la suite si les tests échouent.

---

## Phase 8 — Documenter

### Commit

Message de commit suivant les conventions du projet, avec référence ticket :
```
fix: <description courte du correctif>

<détails si nécessaire>

Refs #<ticket_id>
Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
```

### Note Redmine (optionnel — demander à l'utilisateur)

**Format : Textile** (syntaxe Redmine, PAS Markdown).

Aide-mémoire Textile vs Markdown :
| Élément | Markdown | Textile (Redmine) |
|---|---|---|
| Titre | `## Titre` | `h2. Titre` |
| Gras | `**gras**` | `*gras*` |
| Italique | `*italique*` | `_italique_` |
| Code inline | `` `code` `` | `@code@` |
| Bloc de code | ` ```lang ` | `<pre><code class="lang">` |
| Liste | `- item` | `* item` |
| Lien | `[texte](url)` | `"texte":url` |

Si le MCP Redmine est disponible :
```
mcp__redmine__redmine_add_note {
  id: "<ticket_id>",
  note: "<contenu en Textile>"
}
```

Si le MCP Redmine n'est pas connecté, utiliser le fallback Python :
```python
Bash: python3 -c "
import json, urllib.request
from pathlib import Path
api_key = Path.home().joinpath('.config/redmine/api_key').read_text().strip()
data = json.dumps({'issue': {'notes': '''<contenu en Textile>'''}}).encode()
req = urllib.request.Request(
    f'https://redmine.motoblouz.com/issues/<ticket_id>.json?key={api_key}',
    data=data, headers={'Content-Type': 'application/json'}, method='PUT')
urllib.request.urlopen(req, timeout=10)
print('Note ajoutée au ticket #<ticket_id>')
"
```

### Résumé final

Afficher :
```
## ✅ Ticket #<id> — Correctif implémenté

**Branche :** fix/ticket-<id>-<slug>
**Approche :** <nom>
**Fichiers modifiés :** <liste>
**Tests :** ✅ / ⚠️ <détail>
**Prochaine étape :** PR → review → merge → déploiement
```

---

## Comportement si contexte insuffisant

- Pas de `projects.json` → proposer `/project add`
- Path inexistant → avertir, continuer avec analyse Redmine seule
- Pas de credentials BDD → analyser le code uniquement
- Pas de commandes test/lint → mentionner dans le résumé final
