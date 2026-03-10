# Référence — App web : Frontend

## Frontend Nuxt / Vue.js

Lire et suivre `~/.claude/stacks/nuxt.md` ou `~/.claude/stacks/vue.md` selon le framework choisi.

### Nuxt simple

```
frontend/
├── app/ (assets/, components/, composables/, layouts/, middleware/, pages/, plugins/, utils/, app.config.ts, app.vue, router.options.ts)
├── server/ (api/, middleware/, plugins/, routes/, utils/)
├── shared/
├── public/
├── tests/ (unit/, integration/)
├── nuxt.config.ts, tsconfig.json, eslint.config.js, prettier.config.js, vitest.config.ts, package.json, Makefile
```

### Nuxt advanced (DDD)

```
frontend/
├── app/
│   ├── assets/, layouts/, plugins/, app.config.ts, app.vue, router.options.ts
│   ├── shared/ (components/, composables/, utils/, types/)
│   └── [context]/ (components/, composables/, pages/, middleware/, stores/, types/, services/)
├── server/ (api/[context]/)
├── tests/ (unit/[context]/, integration/[context]/)
├── nuxt.config.ts (avec imports DDD), tsconfig.json, ...
```

### Alternative DDD avec Nuxt Layers

Nuxt 4 supporte les **Layers** comme alternative aux dossiers de bounded contexts. Depuis Nuxt 4, les layers dans `~/layers/` sont **auto-enregistrées** (pas besoin de `extends` dans `nuxt.config.ts`). Chaque layer est un module autonome avec ses propres `components/`, `composables/`, `pages/`, `stores/`, auto-importés.

```
frontend/
├── app/
│   ├── app.vue
│   ├── app.config.ts
│   ├── layouts/
│   └── shared/ (components/, composables/, utils/, types/)
├── layers/
│   ├── identity/
│   │   ├── nuxt.config.ts       ← { }  (layer config, même vide)
│   │   ├── components/
│   │   ├── composables/
│   │   ├── pages/
│   │   ├── stores/
│   │   ├── types/
│   │   └── services/
│   └── catalog/
│       └── ...
├── nuxt.config.ts               ← layers/ auto-détecté par Nuxt 4
```

Avantages : isolation complète, auto-import par layer, testabilité indépendante, auto-registration.
Inconvénient : un `nuxt.config.ts` par layer (même vide).

Cette structure est proposée comme alternative. Le choix entre dossiers dans `app/` et layers est présenté à l'utilisateur à l'étape 3 (architecture). Stocké dans `scaffold.config.json` : `nuxt_ddd_strategy: "directories" | "layers"`.

### Dossier `shared/` (Nuxt 4)

Nuxt 4 introduit un dossier `shared/` au même niveau que `app/` et `server/`, pour le code isomorphe (partagé entre client et serveur). Utiliser ce dossier pour :

- **Types TypeScript** partagés entre `app/` et `server/` (entités, DTOs, enums).
- **Constantes métier** (statuts, rôles, limites).
- **Fonctions utilitaires** pures et isomorphes (formatters, validators).

```
frontend/
├── app/           ← code client
├── server/        ← code serveur (API, middleware)
├── shared/        ← code partagé (types, constantes, utils)
│   ├── types/
│   ├── constants/
│   └── utils/
```

En mode advanced (DDD), les types d'entités générés par `entity-type.ts.tpl` vont dans `shared/types/[context]/` pour être accessibles depuis `app/` et `server/`.

Les fichiers dans `shared/` sont auto-importés par Nuxt 4 dans les deux contextes. Le `tsconfig.shared.json` est auto-généré.

### Vue.js simple

```
frontend/
├── public/
├── src/ (assets/, components/, composables/, layouts/, pages/, plugins/, router/, stores/, types/, utils/, App.vue, main.ts)
├── tests/ (unit/, integration/)
├── index.html, vite.config.ts, tsconfig.json, eslint.config.js, prettier.config.js, vitest.config.ts, package.json, Makefile
```

### Vue.js advanced (DDD)

```
frontend/
├── src/
│   ├── app/ (App.vue, main.ts, router.ts, plugins/)
│   ├── shared/ (components/, composables/, layouts/, types/, utils/)
│   └── [context]/ (components/, composables/, pages/, routes.ts, stores/, types/, services/)
├── tests/ (unit/[context]/, ...)
├── index.html, vite.config.ts, ...
```

### Configuration frontend

- **package.json** — pnpm. Nuxt : `nuxt` 4.x, `vue` 3.x, `pinia`, `@pinia/nuxt`. Vue.js : `vue` 3.x, `vue-router`, `pinia`, `vite`. Dev : `vitest`, `@vue/test-utils`, `eslint`, `prettier`, `typescript`.
- **nuxt.config.ts** (Nuxt) — TypeScript strict. Si advanced : imports DDD (voir stack).
- **vite.config.ts** (Vue.js) — Plugin Vue, alias `@` → `src/`. **Proxy API obligatoire** si backend : `server.proxy` pour `/api` → backend.
- **tsconfig.json** — `strict: true`, paths et aliases adaptés.
- **eslint.config.js** — Nuxt : `@nuxt/eslint`. Vue.js : `eslint-plugin-vue`.
- **vitest.config.ts** — Alias cohérents avec tsconfig, environnement `jsdom` ou `happy-dom`.
- **Makefile** — Targets : install, dev, build, test, lint, lint-fix, format, outdated, quality, help.

Si Vue.js + advanced : router racine `src/app/router.ts` important les routes de chaque bounded context via `routes.ts`.

### Mode SSR / SPA (Nuxt uniquement)

Par défaut, Nuxt fonctionne en SSR. Si `ssr: false` dans `scaffold.config.json`, configurer le mode SPA :

```typescript
// nuxt.config.ts
export default defineNuxtConfig({
  ssr: false,
})
```

Le mode SPA désactive le rendu serveur — l'app est une SPA classique servie par un fichier HTML statique. Utile pour les dashboards internes ou les apps derrière authentification qui n'ont pas besoin de SEO.

Si SPA : les dossiers `server/` ne sont pas créés (pas de server routes/middleware Nitro).

### Configuration TypeScript Nuxt 4

Nuxt 4 génère des TypeScript projects séparés. La structure des tsconfig :

```
frontend/
├── tsconfig.json          ← racine (references app + server + shared)
├── tsconfig.app.json      ← app code (auto-généré par Nuxt)
├── tsconfig.server.json   ← server/api code (auto-généré par Nuxt)
└── tsconfig.shared.json   ← shared/ code (auto-généré par Nuxt)
```

Seul `tsconfig.json` est versionné. Les autres sont auto-générés par Nuxt. Pour customiser, utiliser `nuxt.config.ts` :

```typescript
export default defineNuxtConfig({
  typescript: {
    tsConfig: { /* tsconfig.app.json overrides */ },
    sharedTsConfig: { /* tsconfig.shared.json overrides */ },
    nodeTsConfig: { /* tsconfig.node.json overrides */ },
  },
  nitro: {
    typescript: {
      tsConfig: { /* tsconfig.server.json overrides */ },
    },
  },
})
```

Ajouter `tsconfig.*.json` (sauf `tsconfig.json`) au `.gitignore` frontend.

### Templates frontend par framework

Depuis la v2.2, le skill utilise des **templates spécifiques par framework** pour garantir que le code généré utilise les bons patterns (auto-imports Nuxt, `NuxtLink` vs `RouterLink`, `$fetch` vs `fetch`, etc.).

#### Sélection des templates

| Fichier | Nuxt | Vue.js |
|---|---|---|
| Page liste | `list-page-nuxt.vue.tpl` | `list-page-vue.vue.tpl` |
| Page détail | `detail-page-nuxt.vue.tpl` | `detail-page-vue.vue.tpl` |
| Page formulaire | `form-page-nuxt.vue.tpl` | `form-page-vue.vue.tpl` |
| Service API | `service-nuxt.ts.tpl` | `service-vue.ts.tpl` |
| Store Pinia | `store.ts.tpl` | `store.ts.tpl` |
| Types | `entity-type.ts.tpl` | `entity-type.ts.tpl` |
| Test store | `store-test.ts.tpl` | `store-test.ts.tpl` |
| Test E2E | `e2e-crud.spec.ts.tpl` | `e2e-crud.spec.ts.tpl` |

**Templates dépréciés** — ne plus utiliser : `page.vue.tpl`, `form-page.vue.tpl`, `service.ts.tpl`.

#### Différences clés Nuxt vs Vue.js

| Aspect | Nuxt | Vue.js |
|---|---|---|
| Imports Vue | Auto-importés (ne pas importer `ref`, `computed`, etc.) | Import explicite depuis `'vue'` |
| Route/Router | Auto-importés | Import depuis `'vue-router'` |
| Liens | `<NuxtLink to="...">` | `<RouterLink :to="{ name: '...' }">` |
| Navigation | `navigateTo('/path')` | `router.push('/path')` |
| Client HTTP | `$fetch` (oFetch) | `fetch` natif |
| Routing | File-based (pages/) | Routes manuelles (routes.ts) |
| Page meta | `definePageMeta({ layout: '...' })` | Route meta |

#### Résolution des placeholders

Voir `references/template-resolution.md` pour :
- Le mapping propriété → composant UI (table, formulaire, détail)
- Les conventions de routage (URL → fichier → route)
- Les attributs `data-testid`
- Les valeurs par défaut de formulaire
- L'intégration navigation (sidebar)
- La vérification post-génération

#### Import paths

Le template `store-test.ts.tpl` utilise `{{STORE_IMPORT_PATH}}` et `{{SERVICE_IMPORT_PATH}}` :
- **Nuxt** : `../../../app/{context}/stores/{entity}` et `../../../app/{context}/services/{entity}.service`
- **Vue.js** : `../../../src/{context}/stores/{entity}` et `../../../src/{context}/services/{entity}.service`

---

## Thème frontend

Installer le framework UI et créer le layout + la page d'accueil. Fait partie intégrante du scaffolding.

### Choix du framework UI (demander si non déduit)

```
Framework UI :
  1. Tailwind CSS [d]     — Utility-first, flexible
  2. Shadcn-vue           — Composants headless/composable basés sur Radix Vue + Tailwind
  3. Nuxt UI              — Composants officiels Nuxt, basés sur Tailwind (Nuxt uniquement)
  4. PrimeVue             — Composants riches, dashboard-ready
  5. Vuetify              — Material Design
  6. Aucun (CSS custom)
```

### Type de layout

```
Layout :
  1. Dashboard [d si "dashboard"/"admin"/"backoffice" dans le nom ou preset]
  2. Landing
  3. Minimal [d sinon]
```

### Installation

| Framework UI | Nuxt | Vue.js |
|---|---|---|
| Tailwind | Module `@nuxtjs/tailwindcss` dans `nuxt.config.ts` | `tailwindcss` + `@tailwindcss/vite` dans `vite.config.ts` |
| Shadcn-vue | `shadcn-vue` + Tailwind. CLI `npx shadcn-vue@latest init` puis ajouter composants. Requiert Tailwind. | Idem Nuxt, adapté au setup Vite |
| Nuxt UI | Module `@nuxt/ui` dans `nuxt.config.ts`. Inclut Tailwind, icônes, et composants. | Non supporté (Nuxt uniquement) |
| PrimeVue | Module `@primevue/nuxt-module` | Plugin `primevue` + `@primeuix/themes` dans `main.ts` |
| Vuetify | Module `vuetify-nuxt-module` | Plugin `vuetify` + `@mdi/font` dans `main.ts` |

### Éléments à créer

- **Layout** dans `shared/layouts/` (ou structure DDD appropriée) :
  - Dashboard : sidebar collapsible + topbar + zone contenu. Sidebar responsive (drawer mobile).
  - Landing : header + hero + contenu + footer.
  - Minimal : header simple + contenu.
- **Page d'accueil** fonctionnelle et stylée (pas un placeholder) :
  - Dashboard : grille de cards métriques.
  - Landing : hero + features + CTA.
  - Minimal : titre + contenu.
- **Router** — Route `/` → page d'accueil avec le layout.

Thème cohérent, professionnel, responsive (mobile-first). Couleurs personnalisables (variables CSS ou config). Support dark mode préparé.
