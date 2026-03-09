# Stack — Vue.js

## Version

- Vue 3.x
- TypeScript strict

## Conventions de code

- `<script setup lang="ts">` obligatoire sur tous les composants.
- Composition API uniquement, jamais Options API.
- `defineProps<T>()` avec typage TypeScript (pas de runtime declaration).
- `defineEmits<T>()` avec typage TypeScript.
- Composables préfixés par `use` (useAuth, useCart, etc.).
- Typage strict partout (`strict: true` dans tsconfig).
- Nommage des composants et fichiers en PascalCase.
- `provide` / `inject` avec des `InjectionKey<T>` typées pour le passage de dépendances.

## Outils

| Outil | Usage |
|---|---|
| pnpm | Package manager |
| Vite | Build tool |
| Vitest | Tests unitaires et intégration |
| Playwright | Tests E2E |
| ESLint (eslint-plugin-vue) | Linter |
| Prettier | Formatage |
| Pinia | State management |
| Vue Router | Routing |
| VueUse | Collection de composables utilitaires (recommandé, pas obligatoire) |

## Configuration qualité

### eslint.config.js

```js
import pluginVue from 'eslint-plugin-vue'
import vueTsEslintConfig from '@vue/eslint-config-typescript'
import pluginVueA11y from 'eslint-plugin-vuejs-accessibility' // si a11y.enabled

export default [
  ...pluginVue.configs['flat/recommended'],
  ...vueTsEslintConfig(),
  ...pluginVueA11y.configs['flat/recommended'], // si a11y.enabled
  {
    rules: {
      'vue/multi-word-component-names': 'off',
    },
  },
]
```

### prettier.config.js

```js
export default {
  semi: false,
  singleQuote: true,
  trailingComma: 'all',
  printWidth: 100,
}
```

### Vitest, Stryker & conventions de test

→ Voir [vue-testing.md](./vue-testing.md) pour les configurations Vitest, Stryker et les conventions de test (stores, composables, composants, mocks, fixtures).

## Structure standard

Quand `vue.ddd` = `false`, suivre la structure Vite + Vue classique :

```
frontend/
├── public/
├── src/
│   ├── assets/
│   ├── components/
│   ├── composables/
│   ├── layouts/
│   ├── pages/                  ← ou views/
│   ├── plugins/
│   ├── router/
│   │   └── index.ts
│   ├── stores/
│   ├── types/
│   ├── utils/
│   ├── App.vue
│   └── main.ts
├── tests/
│   ├── unit/
│   ├── integration/
│   └── e2e/
├── index.html
├── vite.config.ts
├── tsconfig.json
├── eslint.config.js
├── prettier.config.js
├── vitest.config.ts
├── package.json
├── pnpm-lock.yaml
└── Makefile
```

## Structure DDD

Quand `vue.ddd` = `true`, le code est organisé par bounded context. ← `vue.ddd`

```
frontend/
├── public/
├── src/
│   ├── app/                                 ← Bootstrap de l'application
│   │   ├── App.vue
│   │   ├── main.ts
│   │   ├── router.ts                        ← Router racine, importe les routes des contextes
│   │   └── plugins/
│   │
│   ├── shared/                              ← Code partagé entre bounded contexts
│   │   ├── components/                      ← Design system, composants génériques
│   │   ├── composables/                     ← Composables transverses (useApi, useAuth, etc.)
│   │   ├── layouts/
│   │   ├── types/
│   │   └── utils/
│   │
│   ├── [bounded-context-a]/                 ← Ex: identity, catalog, billing…
│   │   ├── components/                      ← Composants UI du contexte
│   │   ├── composables/                     ← Logique réutilisable du contexte
│   │   ├── pages/                           ← Pages / vues du contexte
│   │   ├── routes.ts                        ← Routes du contexte (importées par le router racine)
│   │   ├── stores/                          ← Stores Pinia du contexte
│   │   │   └── use[Context]Store.ts
│   │   ├── types/                           ← Types et interfaces du contexte
│   │   │   ├── models.ts                    ← Modèles domain
│   │   │   └── dto.ts                       ← DTOs (réponses API)
│   │   └── services/                        ← Services (appels API, logique métier)
│   │       └── [context].api.ts
│   │
│   └── [bounded-context-b]/
│       ├── components/
│       ├── composables/
│       ├── pages/
│       ├── routes.ts
│       ├── stores/
│       ├── types/
│       └── services/
│
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
├── index.html
├── vite.config.ts
├── tsconfig.json
├── eslint.config.js
├── prettier.config.js
├── vitest.config.ts
├── package.json
├── pnpm-lock.yaml
└── Makefile
```

### Règles DDD strictes

Les patterns DDD transverses sont définis dans [stacks/patterns.md](./patterns.md). Ci-dessous, leur application côté Vue.js.

- **Types/Models** — Modèles domain en TypeScript pur. Pas de dépendance framework.
- **Services** — Encapsulent les appels API et la logique métier. Un service par bounded context.
- **Stores** — Pinia stores isolés par contexte. Un store gère l'état d'un seul bounded context.
- **Composables** — Logique réutilisable propre au contexte. Consomment les stores et services du contexte.
- **Components** — Composants UI propres au contexte. Consomment les composables du contexte.
- **Routes** — Chaque contexte exporte ses routes. Le router racine les importe et les assemble.
- **Shared** — Uniquement les éléments réellement transverses (design system, auth composable, utils HTTP). Ne pas en abuser.
- Les bounded contexts ne s'importent pas entre eux directement. La communication passe par les stores ou des events (mitt, provide/inject).
- Les tests suivent la même structure de bounded contexts.

### Router avec DDD

Le router racine assemble les routes de chaque bounded context :

```typescript
import { createRouter, createWebHistory } from 'vue-router'
import { routes as identityRoutes } from '@/identity/routes'
import { routes as catalogRoutes } from '@/catalog/routes'

const router = createRouter({
  history: createWebHistory(),
  routes: [
    ...identityRoutes,
    ...catalogRoutes,
  ],
})

export default router
```

Chaque contexte expose ses routes :

```typescript
import type { RouteRecordRaw } from 'vue-router'

export const routes: RouteRecordRaw[] = [
  {
    path: '/catalog',
    component: () => import('./pages/CatalogPage.vue'),
    children: [
      {
        path: ':id',
        component: () => import('./pages/ProductPage.vue'),
      },
    ],
  },
]
```

## Accessibilité (a11y)

- Utiliser des éléments HTML sémantiques (`<button>`, `<nav>`, `<main>`, `<article>`) plutôt que des `<div>` cliquables.
- Chaque `<img>` doit avoir un attribut `alt` (vide `alt=""` si purement décoratif).
- Les formulaires doivent utiliser `<label>` associé à chaque champ (via `for`/`id` ou imbrication).
- Les éléments interactifs custom doivent avoir les rôles ARIA appropriés (`role`, `aria-label`, `aria-expanded`, etc.).
- Tester la navigation au clavier (Tab, Enter, Escape) sur les composants interactifs.
- Maintenir un contraste suffisant (ratio WCAG AA minimum : 4.5:1 pour le texte, 3:1 pour les éléments UI).
- Activer `eslint-plugin-vuejs-accessibility` (ou `@nuxt/eslint` qui l'inclut) pour détecter les problèmes à la compilation.

## Gestion des erreurs

### Erreurs globales

Configurer un handler global au bootstrap de l'application :

```typescript
// app/main.ts (ou plugin Nuxt)
app.config.errorHandler = (err, instance, info) => {
  logger.error('Unhandled error', { err, info })
  // Afficher une notification utilisateur si pertinent
}

window.addEventListener('unhandledrejection', (event) => {
  logger.error('Unhandled promise rejection', { reason: event.reason })
})
```

### Erreurs de composants

- Utiliser `onErrorCaptured` dans les composants layout pour capturer les erreurs des enfants et afficher un fallback.
- Ne pas laisser une erreur d'un composant enfant casser toute la page — afficher un état d'erreur localisé.

```vue
<script setup lang="ts">
import { onErrorCaptured, ref } from 'vue'

const hasError = ref(false)

onErrorCaptured((err) => {
  hasError.value = true
  logger.error('Component error', { err })
  return false // stopper la propagation
})
</script>
```

### Erreurs API

- Centraliser la gestion des erreurs API dans le service HTTP partagé (voir section API Client ci-dessous).
- Les erreurs réseau (timeout, offline) doivent afficher un message utilisateur explicite, pas un message technique.
- Les erreurs 401 déclenchent un refresh token automatique ou une redirection vers le login.
- Les erreurs 5xx affichent un message générique ("Service temporairement indisponible").
- Les erreurs 4xx (validation) sont remontées au composant appelant pour affichage contextuel.

## API Client

### Instance centralisée

Chaque projet frontend doit avoir un client API partagé dans `shared/services/http.ts` :

```typescript
// shared/services/http.ts
const api = ofetch.create({
  baseURL: '/api/v1',
  headers: { 'Content-Type': 'application/json' },

  async onResponseError({ response }) {
    if (response.status === 401) {
      // refresh token ou redirection login
    }
  },
})

export { api }
```

- **Nuxt** : utiliser `$fetch` / `useFetch` (basés sur `ofetch`, intégrés). Configurer les defaults via un composable partagé.
- **Vue standalone** : utiliser `ofetch` (léger, typé) ou `axios`. Créer une instance centralisée avec interceptors.

### Services par bounded context

Chaque contexte encapsule ses appels API dans un service dédié :

```typescript
// catalog/services/catalog.api.ts
import { api } from '@/shared/services/http'
import type { Product, ProductDto } from '../types'

export const catalogApi = {
  list: (params?: { page?: number }) =>
    api<{ data: ProductDto[]; meta: PaginationMeta }>('/products', { params }),

  getById: (id: string) =>
    api<ProductDto>(`/products/${id}`),

  create: (payload: CreateProductPayload) =>
    api<ProductDto>('/products', { method: 'POST', body: payload }),
}
```

- Un service par bounded context, un export nommé.
- Les types de retour sont explicitement typés (pas de `any`).
- Les stores consomment les services, les composants consomment les stores.

## UX / UI — Conventions frontend

- Les formulaires doivent :
  - Utiliser `novalidate` + validation JavaScript custom (pas la validation HTML5 native dont les messages varient selon le navigateur/la locale).
  - Afficher les erreurs de validation **sous chaque champ concerné**, pas uniquement dans un bandeau global.
  - Indiquer visuellement les champs en erreur (bordure rouge).
  - Empêcher la soumission tant que la validation client échoue.
  - Gérer les erreurs serveur avec des messages traduits et contextuels.
- Les réponses API en erreur doivent être interceptées et traduites en messages user-friendly (via un helper partagé type `handleResponse`).

## Vite — configuration obligatoire

### Proxy API

Quand le frontend communique avec un backend (API), **toujours** configurer le proxy Vite dans `vite.config.ts` pour éviter les erreurs 404 en développement. Sans proxy, les requêtes `/api/*` arrivent sur le serveur Vite au lieu du backend.

```typescript
export default defineConfig({
  server: {
    host: '0.0.0.0',
    proxy: {
      '/api': {
        target: 'http://backend:8000', // adapter le host/port selon l'infra (Docker service name ou localhost)
        changeOrigin: true,
      },
    },
  },
})
```

- **Docker** : utiliser le nom du service Docker comme target (`http://backend:8000`).
- **Sans Docker** : utiliser `http://localhost:<port>`.
- Le préfixe proxy (`/api`) doit correspondre au préfixe des routes backend.

## Makefile frontend

Suit les conventions de [makefile.md](./makefile.md) (couleurs, help, `.DEFAULT_GOAL`, `.PHONY`). Variable d'exécution : `EXEC = $(DC) exec frontend`.

| Target | Commande | Description |
|---|---|---|
| `install` | `$(EXEC) pnpm install` | Installe les dépendances |
| `dev` | `$(EXEC) pnpm dev` | Lance le serveur de développement |
| `build` | `$(EXEC) pnpm build` | Build l'application |
| `test` | `$(EXEC) pnpm vitest run` | Lance les tests Vitest |
| `test-e2e` | `$(EXEC) pnpm playwright test` | Lance les tests E2E Playwright |
| `lint` | `$(EXEC) pnpm eslint .` | Lance ESLint |
| `lint-fix` | `$(EXEC) pnpm eslint . --fix` | Corrige avec ESLint |
| `format` | `$(EXEC) pnpm prettier --write .` | Formate avec Prettier |
| `test-mutation` | `$(EXEC) pnpm stryker run` | Mutation testing (Stryker) |
| `type-check` | `$(EXEC) pnpm vue-tsc --noEmit` | Vérifie le typage TypeScript |
| `audit` | `$(EXEC) pnpm audit` | Audite les dépendances |
| `format-check` | `$(EXEC) pnpm prettier --check .` | Vérifie le formatage (dry-run) |
| `quality` | `lint format-check type-check test test-mutation audit` | Tous les checks qualité |
