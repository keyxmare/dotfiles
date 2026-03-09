---
name: redmine
description: Fetch and display Redmine tickets from redmine.motoblouz.com — single ticket, tour de contrôle, or squad quotidienne
allowed-tools: Read, WebFetch, mcp__redmine__redmine_get_ticket, mcp__redmine__redmine_tour_de_controle, mcp__redmine__redmine_squad_quotidienne, mcp__redmine__redmine_rapport, mcp__redmine__redmine_search_tickets, mcp__redmine__redmine_list_my_tickets
---

# Skill — Redmine

Récupère et affiche des tickets Redmine depuis `redmine.motoblouz.com`.

## Input

`$ARGUMENTS` peut être :
- Un **ID de ticket** (ex: `1234`) → affiche le ticket détaillé
- `tour` → liste la Tour de contrôle (query 420)
- `quotidienne` → liste la squad quotidienne : DDS + incidents séparément (query 365)
- `rapport` → rapport journalier markdown
- `rapport slack` → même rapport au format Slack (copy/paste ready)

## Process

> **Priorité d'exécution** : utiliser les outils MCP `mcp__redmine__*` en priorité — ils gèrent l'auth et le filtrage. Fallback sur Read + WebFetch uniquement si le MCP n'est pas disponible.

### Avec MCP (prioritaire)

| Argument | Outil MCP | Paramètres |
|---|---|---|
| `<id>` | `mcp__redmine__redmine_get_ticket` | `id: "<id>"` |
| `tour` | `mcp__redmine__redmine_tour_de_controle` | — |
| `quotidienne` | `mcp__redmine__redmine_squad_quotidienne` | — |
| `rapport` | `mcp__redmine__redmine_rapport` | — |
| `rapport slack` | `mcp__redmine__redmine_rapport` | `format: "slack"` |

Afficher le résultat directement — le MCP formate déjà la sortie.

---

### Fallback WebFetch (si MCP indisponible)

#### 1. Récupérer la clé API

```
Read ~/.config/redmine/api_key
```

### 2a. Ticket unique (`$ARGUMENTS` = nombre)

```
WebFetch https://redmine.motoblouz.com/issues/<ID>.json?key=<API_KEY>&include=journals,watchers
```

Afficher :
```
# [<id>] <subject>

**Projet:**    <project.name>
**Statut:**    <status.name>
**Priorité:**  <priority.name>
**Auteur:**    <author.name>
**Assigné à:** <assigned_to.name> (ou « Non assigné »)
**Créé le:**   <created_on>
**Mis à jour:** <updated_on>

## Description
<description>

## Dernières notes
Pour chaque journal avec notes non vide (5 derniers) :
**<created_on>** par **<user.name>** : <notes>
```

### 2b. Tour de contrôle (`$ARGUMENTS` = `tour`)

```
WebFetch https://redmine.motoblouz.com/projects/digital/issues.json?key=<API_KEY>&query_id=420&limit=50
```

Afficher sous forme de tableau :
```
## Tour de contrôle (<total_count> tickets)

| # | Sujet | Statut | Assigné | Màj |
|---|-------|--------|---------|-----|
| [id] | subject | status.name | assigned_to.name | updated_on (date only) |
...
```

### 2c. Squad quotidienne (`$ARGUMENTS` = `quotidienne`)

Un seul appel, filtre côté client sur le champ custom **"Type de Ticket" (id=68)** :

```
WebFetch https://redmine.motoblouz.com/projects/digital/issues.json?key=<API_KEY>&query_id=365&limit=100
```

> ⚠️ `tracker_id` est ignoré par Redmine quand `query_id` est présent — filtrer sur `custom_fields[id=68].value`.

Séparer les résultats en deux sections :
- **DDS** : `custom_fields[id=68].value == "DDS"`
- **Incidents** : `custom_fields[id=68].value == "Incident"`

Afficher :
```
## DDS — Demandes de services (<n> tickets)

| # | Sujet | Statut | Assigné | Màj |
|---|-------|--------|---------|-----|
...

## Incidents (<n> tickets)

| # | Sujet | Statut | Assigné | Màj |
|---|-------|--------|---------|-----|
...
```

Si une section est vide : afficher « Aucun ticket. »

### 2d. Rapport (`$ARGUMENTS` = `rapport`)

Deux appels en parallèle :
```
WebFetch https://redmine.motoblouz.com/projects/digital/issues.json?key=<API_KEY>&query_id=420&limit=100
WebFetch https://redmine.motoblouz.com/projects/digital/issues.json?key=<API_KEY>&query_id=365&limit=100
```

Filtrer la query 365 sur `custom_fields[id=68].value` : `DDS` et `Incident`.

Afficher trois sections :

**1. Tour de contrôle — À trier**
Tableau : `# | Sujet | Priorité | Créé le`

**2. DDS avec échéance**
Uniquement les tickets avec `due_date` non nul, triés par date croissante.
Marquer ⚠️ les échéances dépassées (due_date < aujourd'hui).
Tableau : `# | Sujet | Statut | Assigné | Échéance`

**3. Incidents par statut**
Décompte par `status.name`, trié par count décroissant.
Tableau : `Statut | Nb`

Si `$ARGUMENTS` = `rapport slack`, même logique mais format Slack :
- Pas de tableaux — listes à puces
- Gras : `*texte*`, italique : `_texte_`
- Liens cliquables : `<https://redmine.motoblouz.com/issues/<id>|#<id>>`
- Priorité non-normale en italique après le sujet
- Échéances dépassées marquées ⚠️
