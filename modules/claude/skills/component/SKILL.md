---
name: component
description: Scaffolds a Vue/Nuxt component, composable, store, or page with tests
allowed-tools: Bash(git *), Bash(make *), Bash(docker compose *), Read, Write, Edit, Glob, Grep, Agent, mcp__context7__resolve-library-id, mcp__context7__query-docs
---

# Skill — Component

Tu scaffoldes un élément frontend Vue/Nuxt avec ses tests.

## Input

`$ARGUMENTS` peut être :
- Un type + nom (ex: `composable useCart`, `page orders/[id]`, `store cart`, `component ProductCard`)
- Un nom seul → déduire le type selon le contexte

Types supportés : `component`, `composable`, `store`, `page`, `layout`.

## Process

### 1. Analyse

Identifier :
- **Nuxt ou Vue** (présence de `nuxt.config.ts`)
- **Bounded context** cible (si DDD frontend activé)
- **Emplacement** selon la structure existante du projet
- Les composants/composables/stores existants pour rester cohérent

### 2. Recherche

Consulter context7 si utilisation d'API Vue/Nuxt spécifique (defineModel, useAsyncData, useFetch, etc.).

### 3. Génération

**Component** → `<NomComposant>.vue`
```vue
<script setup lang="ts">
// props, emits, logique
</script>

<template>
  <!-- markup -->
</template>
```

**Composable** → `use<Nom>.ts`
- Signature typée (params + return)
- Réactif (ref/computed)
- Gestion du cleanup si side effects

**Store** → `use<Nom>Store.ts`
- Pinia avec `defineStore` + setup syntax
- State typé, actions, getters

**Page** → `pages/<route>.vue`
- Nuxt : `definePageMeta`, `useAsyncData`/`useFetch` si data
- Vue Router : route dans le fichier router

**Layout** → `layouts/<nom>.vue`
- Slot par défaut, structure HTML sémantique

### 4. Tests

Créer le fichier de test correspondant :

| Type | Fichier test | Framework |
|------|-------------|-----------|
| Component | `<Nom>.spec.ts` | Vitest + @vue/test-utils |
| Composable | `use<Nom>.spec.ts` | Vitest |
| Store | `use<Nom>Store.spec.ts` | Vitest + @pinia/testing |
| Page | `<route>.spec.ts` | Vitest ou Playwright |

Couvrir : rendu initial, interactions, cas d'erreur.

### 5. Vérification

```bash
make test
make quality
```

Tous les tests passent, pas d'erreurs TypeScript.
