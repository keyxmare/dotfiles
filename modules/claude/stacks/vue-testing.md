# Stack — Vue.js / Tests & Qualité

## Configuration

### vitest.config.ts

```ts
import { defineConfig } from 'vitest/config'
import vue from '@vitejs/plugin-vue'
import { resolve } from 'node:path'

export default defineConfig({
  plugins: [vue()],
  resolve: {
    alias: {
      '@': resolve(__dirname, 'src'),
    },
  },
  test: {
    environment: 'jsdom',
    globals: true,
    coverage: {
      provider: 'v8',
      reporter: ['text', 'lcov'],
    },
  },
})
```

### stryker.config.js

```js
/** @type {import('@stryker-mutator/api/core').PartialStrykerOptions} */
export default {
  mutate: ['src/**/*.ts', 'src/**/*.vue', '!src/**/*.spec.ts', '!src/**/*.d.ts'],
  testRunner: 'vitest',
  reporters: ['clear-text', 'html'],
  thresholds: {
    break: 80,
    high: 90,
    low: 70,
  },
  vitest: {
    configFile: 'vitest.config.ts',
  },
}
```

## Conventions de test

### Outils

- **Vitest** pour les tests unitaires et d'intégration.
- **@vue/test-utils** pour le montage et la manipulation de composants Vue.
- **@pinia/testing** pour l'isolation et le mock de stores Pinia.
- **testing-library** (`@testing-library/vue`) en complément optionnel si installé dans le projet — privilégier alors ses sélecteurs orientés accessibilité.

### Structure des tests

- Extension des fichiers de test : `*.spec.ts` (convention Vitest).
- Emplacement : miroir de la structure source dans `tests/unit/`. Exemples : `tests/unit/{context}/stores/`, `tests/unit/{context}/composables/`, `tests/unit/{context}/components/`.
- Un fichier de test par fichier source. Le nom du fichier de test reprend celui du fichier source (ex : `useSync.ts` → `useSync.spec.ts`).

### Tests de stores (Pinia)

- Toujours utiliser `createTestingPinia()` pour isoler le store du reste de l'application.
- Tester chaque **action** (appel, effets de bord, mutations d'état résultantes) et chaque **getter** (valeur calculée selon différents états).
- Mocker les appels API avec `vi.mock` sur le module du service, ou avec **msw** si le projet l'utilise.
- Vérifier les mutations d'état après chaque action — ne pas se contenter de vérifier que l'action ne lève pas d'erreur.

### Tests de composables

- Tester les composables **en isolation**, sans monter de composant, en appelant directement la fonction.
- Si le composable dépend d'un contexte Vue (`provide`/`inject`, `useRouter`, etc.), utiliser un wrapper minimal via `withSetup` ou un composant hôte dédié.
- Vérifier les **valeurs réactives retournées** (`ref`, `computed`) après chaque action ou changement d'état.

### Tests de composants

- Préférer `mount` pour les tests d'intégration afin de vérifier les interactions réelles entre composants parent-enfant.
- Utiliser `shallowMount` uniquement pour isoler un composant de ses enfants lourds ou complexes (ex : composants tiers volumineux).
- Tester le **comportement utilisateur** (clics, saisie, navigation) plutôt que l'implémentation interne (appels de méthodes privées, structure du DOM).
- Toujours couvrir : rendu conditionnel (`v-if`/`v-show`), émission d'événements (`emits`), passage de `props`, et rendu des `slots`.
- Mocker les stores avec `createTestingPinia()` injecté via `global.plugins`, et les services externes avec `vi.mock`.

```ts
const wrapper = mount(MyComponent, {
  global: {
    plugins: [createTestingPinia({ createSpy: vi.fn })],
  },
})
```

### Conventions de mock

- `vi.mock('module')` pour remplacer un module entier (services API, utilitaires).
- `vi.spyOn(obj, 'method')` pour espionner un appel sans remplacer l'implémentation.
- Réinitialiser systématiquement les mocks dans `beforeEach` (`vi.clearAllMocks()`) ou `afterEach` pour éviter les effets de bord entre tests.

### Fixtures

- Créer des helpers de fixtures dans `tests/fixtures/` ou directement dans le fichier de test si usage unique. Centraliser les fixtures réutilisées.
- Les fixtures doivent représenter des cas réalistes, pas des données aléatoires ou minimales qui masquent des bugs.
