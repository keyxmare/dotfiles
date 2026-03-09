# Stack — Nuxt

Nuxt hérite des conventions de [vue.md](./vue.md) (code, DDD, Makefile) et [vue-testing.md](./vue-testing.md) (tests, Vitest, Stryker).
Ci-dessous uniquement les spécificités et différences Nuxt.

## Version

- Nuxt 4.x
- Vue 3.x
- TypeScript strict

## Différences avec Vue.js standalone

### Conventions supplémentaires

- Auto-imports Nuxt activés (composables, utils, components).
- Nommage des pages et layouts en kebab-case.

### Outils

| Outil | Différence avec Vue.js |
|---|---|
| ESLint | `@nuxt/eslint` au lieu de `eslint-plugin-vue` |
| Vite | Intégré dans Nuxt, pas de `vite.config.ts` |
| Vue Router | Intégré, routing par filesystem — pas de router manuel |

### Proxy API

Via `routeRules` dans `nuxt.config.ts` (au lieu de `vite.server.proxy`) :

```typescript
export default defineNuxtConfig({
  routeRules: {
    '/api/**': { proxy: 'http://backend:8000/api/**' },
  },
})
```

- **Docker** : utiliser le nom du service Docker comme target (`http://backend:8000`).
- **Sans Docker** : utiliser `http://localhost:<port>`.
- Sans proxy, les requêtes `/api/*` arrivent sur le serveur Nuxt et retournent 404.

## Structure standard

Quand `nuxt.ddd` = `false`, suivre la structure Nuxt 4 par défaut :

```
frontend/
├── app/
│   ├── assets/
│   ├── components/
│   ├── composables/
│   ├── layouts/
│   ├── middleware/
│   ├── pages/
│   ├── plugins/
│   ├── utils/
│   ├── app.config.ts
│   ├── app.vue
│   └── router.options.ts
├── server/
│   ├── api/
│   ├── middleware/
│   ├── plugins/
│   ├── routes/
│   └── utils/
├── shared/
├── public/
├── tests/
│   ├── unit/
│   ├── integration/
│   └── e2e/
├── nuxt.config.ts
├── tsconfig.json
├── eslint.config.js
├── prettier.config.js
├── vitest.config.ts
├── package.json
├── pnpm-lock.yaml
└── Makefile
```

## Structure DDD

Quand `nuxt.ddd` = `true`, le code est organisé par bounded context. ← `nuxt.ddd`

```
frontend/
├── app/
│   ├── assets/
│   ├── layouts/
│   ├── plugins/
│   ├── app.config.ts
│   ├── app.vue
│   ├── router.options.ts
│   │
│   ├── shared/                              ← Composants et logique partagés
│   │   ├── components/
│   │   ├── composables/
│   │   ├── utils/
│   │   └── types/
│   │
│   ├── [bounded-context-a]/                 ← Ex: identity, catalog, billing…
│   │   ├── components/
│   │   ├── composables/
│   │   ├── pages/
│   │   ├── middleware/
│   │   ├── stores/
│   │   │   └── use[Context]Store.ts
│   │   ├── types/
│   │   │   ├── models.ts
│   │   │   └── dto.ts
│   │   └── services/
│   │       └── [context].api.ts
│   │
│   └── [bounded-context-b]/
│       └── ...
│
├── server/
│   ├── api/
│   │   ├── [bounded-context-a]/
│   │   └── [bounded-context-b]/
│   ├── middleware/
│   ├── plugins/
│   └── utils/
├── public/
├── tests/
│   ├── unit/
│   │   ├── [bounded-context-a]/
│   │   └── [bounded-context-b]/
│   ├── integration/
│   │   ├── [bounded-context-a]/
│   │   └── [bounded-context-b]/
│   └── e2e/
│       ├── [bounded-context-a]/
│       └── [bounded-context-b]/
├── nuxt.config.ts
├── tsconfig.json
├── eslint.config.js
├── prettier.config.js
├── vitest.config.ts
├── package.json
├── pnpm-lock.yaml
└── Makefile
```

### Règles DDD

Les règles DDD strictes de [vue.md](./vue.md#règles-ddd-strictes) s'appliquent intégralement, avec ces ajouts Nuxt :

- Les pages sont dans le bounded context correspondant. Nuxt doit être configuré pour scanner les pages dans les sous-dossiers de contexte.
- Pas de fichier `routes.ts` par contexte — le routing est géré par filesystem.

### Configuration Nuxt pour DDD

```typescript
export default defineNuxtConfig({
  imports: {
    dirs: [
      'app/shared/composables',
      'app/*/composables',
      'app/shared/utils',
      'app/*/utils',
    ],
  },
  components: [
    { path: '~/shared/components', prefix: '' },
    { path: '~/*/components', prefix: '' },
  ],
})
```

> Le glob `~/*/components` scanne automatiquement les composants de tous les bounded contexts. Pas besoin d'ajouter une entrée à chaque nouveau context.

**Attention** : Nuxt scanne uniquement `app/pages/` par défaut. Pour les pages dans les bounded contexts, trois approches :

1. **Pages dans `app/pages/{context}/`** (recommandé) — Garder les pages dans le dossier `app/pages/` standard, organisées en sous-dossiers par contexte (`app/pages/identity/`, `app/pages/catalog/`). Le file-based routing fonctionne nativement. Les stores, services et composables restent co-localisés dans `app/{context}/`.
2. **Hook `pages:extend`** — Scanner manuellement les dossiers `app/*/pages/` via un module Nuxt custom et ajouter les routes. Plus complexe mais garde les pages co-localisées avec le reste du contexte.
3. **Symlinks** — Créer des symlinks dans `app/pages/` pointant vers les pages des contextes.

L'approche 1 est recommandée car elle fonctionne sans configuration et s'appuie sur les conventions Nuxt.

## Data fetching

### Quand utiliser quoi

| API | Cas d'usage | SSR-safe |
|---|---|---|
| `useFetch` | Appels API simples dans un composant/page | Oui |
| `useAsyncData` | Logique de fetch custom ou données non-HTTP | Oui |
| `$fetch` | Appels côté client uniquement (handlers, stores) | Non |

- `useFetch` est un raccourci pour `useAsyncData` + `$fetch`. Le privilégier pour les appels REST classiques.
- `useAsyncData` quand le fetch nécessite une logique custom (combinaison de sources, transformation, données non-HTTP).
- `$fetch` uniquement dans les event handlers, actions de store ou code explicitement client-side. **Jamais dans `setup()`** — provoque un double fetch (serveur + client) sans déduplication.

### Convention : encapsuler dans des composables

Chaque appel API est wrappé dans un composable dédié :

```typescript
// composables/useApiUsers.ts
export function useApiUsers() {
  return useFetch('/api/users', {
    key: 'users',
  })
}
```

```typescript
// composables/useApiUser.ts
export function useApiUser(id: MaybeRef<string>) {
  return useFetch(() => `/api/users/${toValue(id)}`, {
    key: `user-${toValue(id)}`,
  })
}
```

### Options importantes

- **`lazy: true`** — fetch non-bloquant, la page s'affiche immédiatement sans attendre la réponse. Utile pour les données secondaires.
- **`watch`** — re-fetch automatique quand une valeur réactive change.

```typescript
const page = ref(1)

const { data } = useFetch('/api/users', {
  query: { page },
  watch: [page],
})
```

### Nommage des clés (`key`)

- Obligatoire pour `useAsyncData`, fortement recommandé pour `useFetch`.
- Format : `{resource}` pour une liste, `{resource}-{id}` pour un élément.
- La clé doit être unique dans toute l'application — elle sert à la déduplication et au cache payload SSR.

## Stratégie de rendu

### Mode par défaut

SSR universel (`ssr: true`). Ne pas changer sauf besoin explicite.

### Code client-only

**Interdit dans `setup()` :** accès direct à `window`, `document`, `localStorage` ou toute API navigateur.

| Besoin | Solution |
|---|---|
| Logique client-only | `onMounted(() => { ... })` |
| Composant client-only | `<ClientOnly><MyComponent /></ClientOnly>` |
| Guard dans du code partagé | `if (import.meta.client) { ... }` |
| Guard côté serveur | `if (import.meta.server) { ... }` |

```typescript
onMounted(() => {
  const token = localStorage.getItem('auth_token')
})
```

```vue
<template>
  <ClientOnly>
    <LeafletMap :coords="coords" />
    <template #fallback>
      <div>Chargement de la carte…</div>
    </template>
  </ClientOnly>
</template>
```

### Désactiver le SSR par route

Pour les pages entièrement client-side (dashboards lourds, éditeurs WYSIWYG) :

```typescript
export default defineNuxtConfig({
  routeRules: {
    '/dashboard/**': { ssr: false },
    '/admin/editor': { ssr: false },
  },
})
```

### Pièges d'hydratation

Un mismatch d'hydratation survient quand le HTML serveur diffère du rendu client initial. Causes fréquentes :

- **Dates dynamiques** — `new Date()` diffère entre serveur et client. Utiliser `useNow()` de VueUse ou rendre dans `onMounted`.
- **Valeurs aléatoires** — `Math.random()`, `crypto.randomUUID()` côté setup. Générer dans `onMounted` ou passer via payload serveur.
- **APIs navigateur** — `window.innerWidth`, `navigator.userAgent` dans le template. Protéger avec `<ClientOnly>` ou `import.meta.client`.
- **Extensions navigateur** — certaines injectent du DOM. Pas de solution côté app, ignorer ces warnings en dev.

## Gestion des erreurs (spécificités Nuxt)

Les conventions de [vue.md](./vue.md#gestion-des-erreurs) s'appliquent, avec ces ajouts Nuxt :

- Utiliser `error.vue` dans `app/` pour la page d'erreur globale (404, 500). Le composant reçoit `error` en prop.
- Utiliser `useError()` pour accéder à l'erreur courante dans n'importe quel composant.
- Utiliser `showError({ statusCode, message })` pour déclencher la page d'erreur programmatiquement.
- Utiliser `clearError({ redirect })` pour effacer l'erreur et rediriger.
- **Pas de `app.config.errorHandler` manuel** — Nuxt le gère via `error.vue` et les hooks de lifecycle.

## API Client (spécificités Nuxt)

Les conventions de [vue.md](./vue.md#api-client) s'appliquent avec ces différences :

- Utiliser `$fetch` / `useFetch` / `useAsyncData` (basés sur `ofetch`, intégrés à Nuxt) plutôt qu'une instance custom.
- Pas besoin de créer un client API partagé — configurer les defaults via un composable :

```typescript
// shared/composables/useApi.ts
export function useApi<T>(url: string, options?: Parameters<typeof useFetch>[1]) {
  return useFetch<T>(url, {
    ...options,
    onResponseError({ response }) {
      if (response.status === 401) {
        navigateTo('/login')
      }
    },
  })
}
```

## Makefile frontend

Identique à [vue.md](./vue.md#makefile-frontend), avec cette différence :

| Target | Commande |
|---|---|
| `type-check` | `$(EXEC) pnpm nuxi typecheck` (au lieu de `vue-tsc --noEmit`) |
