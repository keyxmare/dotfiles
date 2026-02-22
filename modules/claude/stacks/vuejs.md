# Stack Vue.js

## Vue 3.5+ / TypeScript / Vite 6
- Vue 3.5+ avec la Composition API (`<script setup lang="ts">`). **Jamais** d'Options API.
- TypeScript **obligatoire** dans tous les fichiers `.ts` et `.vue`.
- Vite 6 comme build tool. Config dans `frontend/vite.config.ts`.
- Alias `@` → `src/` configuré dans `vite.config.ts` et `tsconfig.json`.
- `vue-tsc` pour le type-checking (`npm run lint`).

## Structure de fichiers

```
frontend/src/
├── api/              # Client HTTP et modules par ressource
│   ├── client.ts     # Client fetch configuré (baseURL, interceptors)
│   ├── types.ts      # Interfaces TypeScript des DTOs API
│   ├── projects.ts   # Fonctions CRUD pour /projects
│   └── ...
├── stores/           # Pinia stores (un par ressource)
├── composables/      # Composables réutilisables (useXxx)
├── router/           # Vue Router (index.ts)
├── views/            # Pages (lazy-loaded)
│   ├── public/       # Pages publiques (HomePage, ProjectsPage, ...)
│   └── admin/        # Pages admin groupées par ressource
│       ├── projects/
│       ├── skills/
│       └── ...
├── components/       # Composants réutilisables
│   ├── layout/       # AppHeader, AppFooter, PublicLayout, AdminLayout
│   ├── ui/           # Badge, LoadingSpinner, ErrorMessage (génériques)
│   ├── projects/     # ProjectCard (spécifiques au domaine)
│   └── admin/        # DataTable, FormField, ConfirmModal (admin)
├── assets/           # CSS, images, fonts
├── App.vue
└── main.ts
```

## Conventions de nommage

| Élément | Convention | Exemple |
|---------|-----------|---------|
| Composant | PascalCase, fichier = nom du composant | `ProjectCard.vue` |
| Page | Suffixe `*Page.vue` | `ProjectsPage.vue`, `ProjectFormPage.vue` |
| Layout | Suffixe `*Layout.vue` | `PublicLayout.vue`, `AdminLayout.vue` |
| Store | `use*Store` (fonction, setup syntax) | `useProjectsStore` |
| Composable | `use*` (fonction, fichier camelCase) | `useScrollReveal.ts` → `useScrollReveal()` |
| Module API | Nom de la ressource en minuscules | `projects.ts` → `projectsApi` |
| Interface TS | PascalCase, dans `api/types.ts` | `Project`, `ApiCollection<T>` |
| Props/events | camelCase en TS, kebab-case dans le template | `:project-url` → `projectUrl` |

## Pinia — State management

- **Setup stores** exclusivement (pas d'option stores) : `defineStore('name', () => { ... })`.
- Un store par ressource/domaine : `useProjectsStore`, `useAuthStore`, etc.
- Pattern standard dans chaque store :
  - `ref<T[]>()` pour la collection, `ref<T | null>()` pour l'élément courant
  - `ref(false)` pour `loading`, `ref<string | null>(null)` pour `error`
  - Fonctions async `fetchAll()`, `fetchOne(id)`, `create()`, `update()`, `remove()`
  - Getters comme fonctions retournées : `publishedProjects()`, `featuredProjects()`
- Ne pas accéder à un store depuis un autre store sauf `useAuthStore` (token).

## API — fetch natif

- **Pas d'Axios.** Utiliser `fetch()` natif avec un wrapper typé dans `api/client.ts`.
- Client centralisé qui encapsule :
  - Base URL : `/api/v1`
  - Headers JSON-LD : `Content-Type: application/ld+json`, `Accept: application/ld+json`
  - Injection du token JWT depuis `useAuthStore` sur chaque requête
  - Refresh token automatique sur 401, redirect `/admin/login` si refresh échoue
  - Parsing JSON et gestion des erreurs HTTP (throw sur status >= 400)
- Un module API par ressource (`api/projects.ts`, `api/skills.ts`, ...) qui expose un objet `xxxApi` avec les méthodes CRUD.
- Les types de retour sont définis dans `api/types.ts`. Typer les réponses avec les interfaces.
- Collection API Platform : `ApiCollection<T>` avec `member: T[]` et `totalItems: number`.

## Vue Router 4

- Routes lazy-loaded : `component: () => import('@/views/...')`.
- Routes publiques à la racine (`/`, `/projects`, `/blog/:id`).
- Routes admin imbriquées sous `/admin` avec `meta: { requiresAuth: true }`.
- Auth guard global via `router.beforeEach` : vérifier `useAuthStore().isAuthenticated`.
- `scrollBehavior` : restaurer la position sauvegardée, ou scroll to hash avec offset, ou top.
- Routes admin CRUD : `resource/`, `resource/new`, `resource/:id/edit`.

## Composants

- `<script setup lang="ts">` obligatoire. Pas de `<script>` classique.
- Props typées avec `defineProps<{ ... }>()`. Pas de runtime validation sauf aux frontières.
- Events typés avec `defineEmits<{ ... }>()`.
- Template d'abord, script ensuite dans le SFC (`<template>` puis `<script setup>`).
- Composants layout : wrappent le contenu via `<slot>`.
- Composants UI (`ui/`) : génériques, sans logique métier, props simples.
- Composants domaine (`projects/`, `skills/`) : reçoivent un objet typé en prop.

## Composables

- Préfixe `use` obligatoire.
- Un fichier par composable dans `composables/`.
- Retourner des `ref` ou des objets réactifs, jamais des valeurs brutes.
- Lifecycle hooks (`onMounted`, `onUnmounted`) encapsulés dans le composable.
- VueUse (`@vueuse/core`) disponible pour les utilitaires courants.

## Styling — Tailwind CSS 4

- Tailwind CSS 4 via le plugin Vite (`@tailwindcss/vite`).
- Classes utilitaires directement dans le template. Pas de CSS scoped sauf cas exceptionnel.
- Palette : `slate` pour les textes/fonds sombres, `emerald` pour les accents.
- Responsive : mobile-first avec les breakpoints Tailwind (`sm:`, `md:`, `lg:`).
- Pas de CSS-in-JS, pas de SCSS.

## Intégration Symfony

- Le frontend est un projet **séparé** dans `frontend/` (pas AssetMapper, pas Webpack Encore).
- Proxy Vite dev server : `/api` → backend PHP (`http://php:80`).
- Build de production : `vue-tsc && vite build`, output dans `frontend/dist/`.
- Communication backend exclusivement via l'API REST (JSON-LD).

## Tests frontend (à mettre en place)

- Vitest pour les tests unitaires (composables, stores, utilitaires).
- Vue Test Utils pour les tests de composants.
- Pas de tests E2E frontend pour le moment (couverts côté API par les tests fonctionnels PHP).

## Politique de versions — JAMAIS de downgrade

Même règle que pour le backend (voir `symfony.md`). Ne jamais baisser les versions de Vue, Vite, Pinia, Vue Router, Tailwind ou TypeScript en dessous de ce que `package.json` définit.
