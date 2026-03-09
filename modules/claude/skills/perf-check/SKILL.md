---
name: perf-check
description: Analyzes performance issues in backend queries, frontend rendering, and bundle size
allowed-tools: Bash(git *), Bash(make *), Bash(docker compose *), Read, Glob, Grep, Agent, mcp__context7__resolve-library-id, mcp__context7__query-docs
---

# Skill — Performance Check

Tu analyses les problèmes de performance et proposes des optimisations concrètes.

## Input

`$ARGUMENTS` peut être :
- Un chemin (ex: `src/Catalog/`, `app/pages/products.vue`)
- Un domaine : `queries`, `frontend`, `bundle`, `api`
- Rien → analyse globale des hotspots

## Process

### 1. Backend — Requêtes & ORM

Chercher dans le code :

**N+1 Queries**
- Boucles contenant des appels repository ou relations lazy-loaded
- Entités Doctrine avec relations sans `fetch: EAGER` ni `JOIN` explicite dans les queries
- Handlers qui appellent le repository dans une boucle

**Requêtes non optimisées**
- `findAll()` sans pagination sur des tables potentiellement volumineuses
- `SELECT *` implicite (pas de `select()` partiel dans le QueryBuilder)
- Absence d'index sur les colonnes filtrées/triées (vérifier les attributs `#[ORM\Index]`)
- Requêtes COUNT sans cache sur des données peu volatiles

**Serialization**
- Entités sérialisées directement (au lieu de DTOs légers)
- Champs inutiles dans les réponses API (relations chargées mais non utilisées)

### 2. Frontend — Rendering

**Re-renders inutiles**
- `ref()` sur des objets complexes quand `shallowRef()` suffit
- `computed()` avec des dépendances instables (objets recréés à chaque render)
- Watchers sans `{ flush: 'post' }` quand approprié
- Composants sans `defineAsyncComponent` pour le code splitting

**Data fetching**
- `useFetch`/`useAsyncData` sans clé de cache stable
- Appels API dupliqués (même endpoint dans plusieurs composants sans cache partagé)
- Absence de `lazy` sur les fetches non critiques

**Listes**
- `v-for` sans `:key` stable
- Listes longues sans virtualisation (`vue-virtual-scroller`)
- Filtrage/tri côté client sur de gros datasets

### 3. Bundle

Si applicable :
```bash
docker compose exec node pnpm run build --analyze
```

Chercher :
- Imports non tree-shakés (import de la lib entière vs import nommé)
- Dépendances lourdes avec alternatives légères
- Assets non optimisés (images sans compression, fonts non subsetées)
- Code dupliqué entre chunks

### 4. Rapport

Pour chaque issue trouvée :
- `fichier:ligne` — localisation
- **Impact** — estimé (élevé/moyen/faible) avec explication
- **Fix** — snippet de code correctif
- **Effort** — petit/moyen/grand

Trier par impact décroissant.

Résumer : nombre d'issues par catégorie, top 3 quick wins.
