---
name: project
description: Manage the global projects registry (~/.claude/projects.json) and local DB credentials (~/.config/claude/db.json)
allowed-tools: Read, Write, Edit, Bash(ls:*), Bash(git remote:*)
---

# Skill — Project

Gestion du registre global de projets utilisé par `/analyze-ticket`.

## Input

`$ARGUMENTS` :
- `list` — liste les projets configurés
- `show <name>` — détails d'un projet
- `add` — assistant interactif pour ajouter un projet
- `add-db <project-name>` — ajouter des credentials BDD (stockés localement, non trackés)
- `remove <name>` — supprimer un projet

---

## Config files

| Fichier | Contenu | Tracké git |
|---|---|---|
| `~/.claude/projects.json` | Projets, paths, URLs, stack, keywords | ✅ oui |
| `~/.config/claude/db.json` | Credentials BDD (host, user, password) | ❌ non |

---

## Schéma `projects.json`

```json
{
  "version": "1",
  "projects": [
    {
      "name": "mon-projet",
      "path": "~/Projects/mon-projet",
      "description": "Description courte du projet",
      "stack": ["symfony", "php", "mysql"],
      "url": {
        "prod": "https://www.exemple.com",
        "local": "http://localhost:8080"
      },
      "redmine_keywords": ["mot-clé", "autre-mot"],
      "commands": {
        "test": "make test",
        "lint": "make lint",
        "static": "make phpstan",
        "start": "make up"
      }
    }
  ]
}
```

## Schéma `db.json`

```json
{
  "connections": [
    {
      "name": "mon-projet-local",
      "project": "mon-projet",
      "env": "local",
      "driver": "mysql",
      "host": "127.0.0.1",
      "port": 3306,
      "database": "ma_base",
      "user": "root",
      "password": "secret"
    }
  ]
}
```

---

## Process

### `list`

```
Read ~/.claude/projects.json
```

Afficher un tableau :
```
| Nom | Path | Stack | URLs |
```
Si vide : proposer `/project add`.

### `show <name>`

Lire `projects.json`, trouver le projet, afficher tous ses champs.
Lire `~/.config/claude/db.json` si existant, afficher les connexions du projet (masquer les passwords).

### `add`

1. Lire `~/.claude/projects.json`
2. Demander interactivement :
   - **name** — identifiant unique snake_case
   - **path** — chemin absolu ou `~/...` (utiliser `ls` pour valider)
   - **description** — une ligne
   - **stack** — liste séparée par virgules (ex: `symfony, php, mysql`)
   - **url.prod** — URL de production (optionnel)
   - **url.local** — URL locale (optionnel)
   - **redmine_keywords** — mots-clés du ticket Redmine pour auto-détecter ce projet (ex: `paiement, hipay, commande`)
   - **commands.test / lint / static / start** — commandes dispo (optionnel, détecter depuis Makefile si présent)
3. Auto-détecter les commandes disponibles :
   ```
   Read <path>/Makefile  (si existant)
   Read <path>/package.json (si existant)
   ```
4. Afficher le résumé et demander confirmation
5. Écrire dans `~/.claude/projects.json` (Edit ou Write)

### `add-db <project-name>`

1. Vérifier que le projet existe dans `projects.json`
2. Créer `~/.config/claude/db.json` si inexistant
3. Demander :
   - **env** — `local` ou `prod`
   - **driver** — `mysql`, `postgresql`, `redis`, etc.
   - **host**, **port**, **database**, **user**, **password**
4. Écrire dans `~/.config/claude/db.json`
5. ⚠️ Rappeler que ce fichier n'est PAS tracké dans git

### `remove <name>`

Lire `projects.json`, supprimer l'entrée, confirmer avant d'écrire.
