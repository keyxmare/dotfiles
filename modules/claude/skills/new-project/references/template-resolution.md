# Référence — Résolution des templates et règles de génération frontend

## Principe fondamental

**JAMAIS de données hardcodées.** Tout le contenu affiché provient de l'API via le store Pinia. Les pages affichent les données du store, les formulaires modifient les données via le store, les actions déclenchent des appels API via le store.

Si une page affiche `"Mon produit"` ou `19.99` en dur dans le template, c'est un bug.

---

## Sélection des templates par framework

| Opération | Nuxt | Vue.js |
|---|---|---|
| Page liste | `list-page-nuxt.vue.tpl` | `list-page-vue.vue.tpl` |
| Page détail | `detail-page-nuxt.vue.tpl` | `detail-page-vue.vue.tpl` |
| Page formulaire | `form-page-nuxt.vue.tpl` | `form-page-vue.vue.tpl` |
| Service API | `service-nuxt.ts.tpl` | `service-vue.ts.tpl` |
| Modale suppression | `delete-modal.vue.tpl` | `delete-modal.vue.tpl` |
| Store Pinia | `store.ts.tpl` | `store.ts.tpl` |
| Types TypeScript | `entity-type.ts.tpl` | `entity-type.ts.tpl` |
| Test store | `store-test.ts.tpl` | `store-test.ts.tpl` |
| Test E2E | `e2e-crud.spec.ts.tpl` | `e2e-crud.spec.ts.tpl` |

**Anciens templates dépréciés** — ne plus utiliser :

| Ancien | Remplacé par |
|---|---|
| `page.vue.tpl` | `list-page-nuxt.vue.tpl` / `list-page-vue.vue.tpl` |
| `form-page.vue.tpl` | `form-page-nuxt.vue.tpl` / `form-page-vue.vue.tpl` |
| `service.ts.tpl` | `service-nuxt.ts.tpl` / `service-vue.ts.tpl` |

---

## Conventions de routage

### Mapping URL → Fichier → Composant

#### Mode advanced (bounded contexts) — Nuxt directories

| Page | URL | Fichier |
|---|---|---|
| Liste | `/{context-kebab}/{entities-kebab}` | `app/{context-kebab}/pages/{entities-kebab}/index.vue` |
| Détail | `/{context-kebab}/{entities-kebab}/{id}` | `app/{context-kebab}/pages/{entities-kebab}/[id].vue` |
| Création | `/{context-kebab}/{entities-kebab}/new` | `app/{context-kebab}/pages/{entities-kebab}/new.vue` |
| Édition | `/{context-kebab}/{entities-kebab}/{id}/edit` | `app/{context-kebab}/pages/{entities-kebab}/[id]/edit.vue` |

#### Mode advanced — Nuxt layers

| Page | URL | Fichier |
|---|---|---|
| Liste | `/{context-kebab}/{entities-kebab}` | `layers/{context-kebab}/pages/{context-kebab}/{entities-kebab}/index.vue` |
| Détail | `/{context-kebab}/{entities-kebab}/{id}` | `layers/{context-kebab}/pages/{context-kebab}/{entities-kebab}/[id].vue` |
| Création | `/{context-kebab}/{entities-kebab}/new` | `layers/{context-kebab}/pages/{context-kebab}/{entities-kebab}/new.vue` |
| Édition | `/{context-kebab}/{entities-kebab}/{id}/edit` | `layers/{context-kebab}/pages/{context-kebab}/{entities-kebab}/[id]/edit.vue` |

#### Mode advanced — Vue.js

| Page | URL (définie dans routes.ts) | Fichier |
|---|---|---|
| Liste | `/{context-kebab}/{entities-kebab}` | `src/{context-kebab}/pages/{Entity}List.vue` |
| Détail | `/{context-kebab}/{entities-kebab}/:id` | `src/{context-kebab}/pages/{Entity}Detail.vue` |
| Création | `/{context-kebab}/{entities-kebab}/new` | `src/{context-kebab}/pages/{Entity}Form.vue` |
| Édition | `/{context-kebab}/{entities-kebab}/:id/edit` | `src/{context-kebab}/pages/{Entity}Form.vue` |

#### Mode simple (pas de bounded contexts)

| Page | URL | Fichier Nuxt | Fichier Vue.js |
|---|---|---|---|
| Liste | `/{entities-kebab}` | `app/pages/{entities-kebab}/index.vue` | `src/pages/{Entity}List.vue` |
| Détail | `/{entities-kebab}/{id}` | `app/pages/{entities-kebab}/[id].vue` | `src/pages/{Entity}Detail.vue` |
| Création | `/{entities-kebab}/new` | `app/pages/{entities-kebab}/new.vue` | `src/pages/{Entity}Form.vue` |
| Édition | `/{entities-kebab}/{id}/edit` | `app/pages/{entities-kebab}/[id]/edit.vue` | `src/pages/{Entity}Form.vue` |

### Exemple concret

Entity `Product` dans context `Catalog` :

| Page | URL | Fichier Nuxt (directories) |
|---|---|---|
| Liste | `/catalog/products` | `app/catalog/pages/products/index.vue` |
| Détail | `/catalog/products/abc-123` | `app/catalog/pages/products/[id].vue` |
| Création | `/catalog/products/new` | `app/catalog/pages/products/new.vue` |
| Édition | `/catalog/products/abc-123/edit` | `app/catalog/pages/products/[id]/edit.vue` |

---

## Différences Nuxt vs Vue.js

### Imports

| Élément | Nuxt | Vue.js |
|---|---|---|
| `ref`, `computed`, `watch`, `onMounted` | Auto-importés — **NE PAS importer** | `import { ref, computed, watch, onMounted } from 'vue'` |
| `useRoute()` | Auto-importé | `import { useRoute, useRouter } from 'vue-router'` |
| `navigateTo()` | Auto-importé | Non disponible — utiliser `router.push()` |
| `definePageMeta()` | Auto-importé | Non disponible — utiliser route meta |
| `useHead()` | Auto-importé | Non disponible (ou via `@unhead/vue`) |
| Store Pinia | Import explicite requis | Import explicite requis |

### Navigation

| Action | Nuxt | Vue.js |
|---|---|---|
| Lien interne | `<NuxtLink to="/path">` | `<RouterLink :to="{ name: 'route-name' }">` |
| Lien dynamique | `<NuxtLink :to="` `/path/${id}` `">` | `<RouterLink :to="{ name: 'entity-detail', params: { id } }">` |
| Nav programmatique | `navigateTo('/path')` | `router.push('/path')` |
| Retour | `navigateTo(listPath)` | `router.push(listPath)` |

### Récupération de données

| Pattern | Nuxt | Vue.js |
|---|---|---|
| Au chargement de page | Store action dans `onMounted()` | Store action dans `onMounted()` |
| Client HTTP dans service | `$fetch` (oFetch) | `fetch` natif |
| Erreurs HTTP | oFetch throw auto | Vérifier `response.ok` manuellement |

### Métadonnées de page (Nuxt uniquement)

```vue
definePageMeta({
  layout: 'dashboard',
  middleware: 'auth',
})

useHead({
  title: 'Produits — Mon App',
})
```

---

## Attributs data-testid

Chaque élément interactif ou structurel reçoit un `data-testid` pour les tests E2E Playwright :

| Élément | data-testid |
|---|---|
| Titre de page | `page-title` |
| Bouton créer | `create-btn` |
| Tableau de liste | `list-table` |
| Ligne de liste | `list-item` |
| Bouton voir | `view-btn` |
| Bouton modifier | `edit-btn` |
| Bouton supprimer | `delete-btn` |
| État chargement | `loading` |
| État erreur | `error` |
| État vide | `empty-state` |
| Formulaire | `entity-form` |
| Champ de formulaire | `field-{propertyName}` |
| Bouton soumettre | `submit-btn` |
| Pagination | `pagination` |
| Modale suppression | `delete-modal` |
| Confirmer suppression | `confirm-delete-btn` |
| Annuler suppression | `cancel-delete-btn` |
| Page détail (conteneur) | `entity-detail` |
| Bouton retour | `back-btn` |

---

## Mapping propriété → rendu UI

### Table (page liste)

Pour chaque propriété de l'entité, générer une colonne. Exclure : `id` (implicite), `password`, `json`, `text` très long.

| Type propriété | Rendu colonne |
|---|---|
| `string` | `{{ item.{prop} }}` |
| `text` | `{{ item.{prop}?.slice(0, 50) }}...` (tronqué) |
| `int` | `{{ item.{prop} }}` |
| `float` | `{{ item.{prop}.toFixed(2) }}` |
| `bool` | `{{ item.{prop} ? 'Oui' : 'Non' }}` |
| `datetime` | `{{ new Date(item.{prop}).toLocaleDateString() }}` |
| `enum(...)` | `{{ item.{prop} }}` (badge si UI framework) |
| Relation `ManyToOne` | `{{ item.{relation}?.name }}` (ou label) |
| Relation `OneToMany` | `{{ item.{relation}?.length ?? 0 }}` (compteur) |

### Formulaire (page create/edit)

Pour chaque propriété **modifiable** (exclure `id`, `createdAt`, `updatedAt`), générer un champ avec label, input, `v-model` et `data-testid` :

| Type propriété | Composant | `v-model` | Attributs |
|---|---|---|---|
| `string` | `<input type="text">` | `v-model="form.{prop}"` | `required`, `maxlength="255"` |
| `text` | `<textarea>` | `v-model="form.{prop}"` | `rows="4"` |
| `int` | `<input type="number">` | `v-model.number="form.{prop}"` | `step="1"` |
| `float` | `<input type="number">` | `v-model.number="form.{prop}"` | `step="0.01"` |
| `bool` | `<input type="checkbox">` | `v-model="form.{prop}"` | — |
| `datetime` | `<input type="datetime-local">` | `v-model="form.{prop}"` | — |
| `uuid` | Non affiché (généré côté serveur) | — | — |
| `json` | `<textarea>` | `v-model="form.{prop}"` | JSON.parse validation |
| `enum(a,b,c)` | `<select>` avec `<option>` | `v-model="form.{prop}"` | — |
| Relation `ManyToOne` | `<select>` + fetch des options | `v-model="form.{prop}Id"` | `required` si non nullable |
| Relation `ManyToMany` | Checkboxes ou multi-select | `v-model="form.{prop}Ids"` | — |

#### Exemple concret de champ string

```vue
<div>
  <label for="field-name">Nom</label>
  <input id="field-name" v-model="form.name" type="text" required maxlength="255" data-testid="field-name" />
</div>
```

#### Exemple concret de champ enum

```vue
<div>
  <label for="field-status">Statut</label>
  <select id="field-status" v-model="form.status" data-testid="field-status">
    <option value="draft">Draft</option>
    <option value="published">Published</option>
    <option value="archived">Archived</option>
  </select>
</div>
```

#### Exemple concret de relation ManyToOne

```vue
<div>
  <label for="field-categoryId">Catégorie</label>
  <select id="field-categoryId" v-model="form.categoryId" required data-testid="field-categoryId">
    <option value="" disabled>Sélectionner...</option>
    <option v-for="cat in categories" :key="cat.id" :value="cat.id">
      {{ cat.name }}
    </option>
  </select>
</div>
```

Les entités liées (ici `categories`) sont fetchées au montage du composant via leur propre store ou service.

### Détail (page show)

Pour chaque propriété, une paire `<dt>/<dd>` dans une `<dl>` :

| Type propriété | Rendu |
|---|---|
| `string` | `<dd>{{ entity.{prop} }}</dd>` |
| `text` | `<dd class="whitespace-pre-wrap">{{ entity.{prop} }}</dd>` |
| `int`, `float` | `<dd>{{ entity.{prop} }}</dd>` |
| `bool` | `<dd>{{ entity.{prop} ? 'Oui' : 'Non' }}</dd>` |
| `datetime` | `<dd>{{ new Date(entity.{prop}).toLocaleString() }}</dd>` |
| `json` | `<dd><pre>{{ JSON.stringify(entity.{prop}, null, 2) }}</pre></dd>` |
| `enum(...)` | `<dd>{{ entity.{prop} }}</dd>` |
| Relation `ManyToOne` | Lien vers l'entité liée |
| Relation `OneToMany` | Liste de liens vers les entités liées |

---

## Valeurs par défaut du formulaire (FORM_DEFAULTS)

Pour chaque propriété, la valeur initiale dans le `ref<FormType>({...})` :

| Type | Valeur par défaut |
|---|---|
| `string` | `''` |
| `text` | `''` |
| `int` | `0` |
| `float` | `0` |
| `bool` | `false` |
| `datetime` | `''` |
| `enum(a,b,c)` | `'a'` (première valeur) |
| `json` | `{}` |
| Relation `ManyToOne` | `''` (ID vide) |
| Relation `ManyToMany` | `[]` (tableau vide) |

---

## Résolution des placeholders

### Placeholders communs (tous templates)

| Placeholder | Résolution | Exemple (Entity: Product, Context: Catalog) |
|---|---|---|
| `{{ENTITY}}` | PascalCase singulier | `Product` |
| `{{ENTITY_CAMEL}}` | camelCase singulier | `product` |
| `{{ENTITY_KEBAB}}` | kebab-case singulier | `product` |
| `{{ENTITY_LOWER}}` | lowercase singulier | `product` |
| `{{ENTITY_PLURAL}}` | PascalCase pluriel | `Products` |
| `{{ENTITY_PLURAL_KEBAB}}` | kebab-case pluriel | `products` |
| `{{ENTITY_PLURAL_LOWER}}` | lowercase pluriel | `products` |
| `{{CONTEXT}}` | PascalCase | `Catalog` |
| `{{CONTEXT_KEBAB}}` | kebab-case | `catalog` |
| `{{STORE}}` | PascalCase (= ENTITY) | `Product` |
| `{{STORE_KEBAB}}` | kebab-case (= ENTITY_KEBAB) | `product` |

### Placeholders des pages

| Placeholder | Résolution | Exemple |
|---|---|---|
| `{{PAGE_TITLE}}` | Pluriel FR de l'entité | `Produits` |
| `{{CREATE_PATH}}` | URL de la page création | `/catalog/products/new` |
| `{{DETAIL_PATH_PREFIX}}` | Préfixe URL détail (sans ID) | `/catalog/products` |
| `{{LIST_PATH}}` | URL de la page liste | `/catalog/products` |
| `{{CREATE_TITLE}}` | Titre page création | `Créer un produit` |
| `{{EDIT_TITLE}}` | Titre page édition | `Modifier le produit` |
| `{{TABLE_HEADERS}}` | `<th>` par propriété affichable | Voir section mapping |
| `{{TABLE_CELLS}}` | `<td>` avec `item.prop` dynamique | Voir section mapping |
| `{{FORM_FIELDS}}` | Champs de formulaire (voir mapping) | Voir section mapping |
| `{{FORM_DEFAULTS}}` | Objet de valeurs par défaut | `name: '', price: 0` |
| `{{FORM_TYPE}}` | Type TS du formulaire | `Omit<Product, 'id'>` |
| `{{DETAIL_FIELDS}}` | Paires `<dt>/<dd>` | Voir section mapping |
| `{{LAYOUT}}` | Nom du layout | `dashboard` |

### Placeholders des stores et services

| Placeholder | Résolution | Exemple |
|---|---|---|
| `{{STORE_IMPORT}}` | Import du store | `import { useProductStore } from '../stores/product'` |
| `{{TYPE_IMPORT_PATH}}` | Chemin du type | `../types/product` |
| `{{SERVICE_IMPORT_PATH}}` | Chemin du service | `../services/product.service` |
| `{{STORE_IMPORT_PATH}}` | Chemin du store | `../stores/product` |
| `{{BASE_URL}}` | URL de base de l'API | `/api/catalog/products` |

---

## Intégration navigation

Après génération des pages d'une entité, mettre à jour le layout pour inclure un lien vers la liste :

### Nuxt (layout dashboard)

Dans `app/layouts/dashboard.vue` (ou `shared/layouts/dashboard.vue`), ajouter dans la sidebar :

```vue
<NuxtLink to="/catalog/products" active-class="active">Produits</NuxtLink>
```

### Vue.js (layout dashboard)

Dans `src/shared/layouts/DashboardLayout.vue`, ajouter dans la sidebar :

```vue
<RouterLink :to="{ name: 'catalog-products-list' }" active-class="active">Produits</RouterLink>
```

### Vue.js (router)

Dans `src/{context}/routes.ts`, ajouter les routes de l'entité :

```typescript
export const catalogRoutes = [
  { path: '/catalog/products', name: 'catalog-products-list', component: () => import('./pages/ProductList.vue') },
  { path: '/catalog/products/new', name: 'catalog-products-create', component: () => import('./pages/ProductForm.vue') },
  { path: '/catalog/products/:id', name: 'catalog-products-detail', component: () => import('./pages/ProductDetail.vue') },
  { path: '/catalog/products/:id/edit', name: 'catalog-products-edit', component: () => import('./pages/ProductForm.vue') },
]
```

---

## Relations dans les formulaires

### ManyToOne — Fetcher les options

Au montage du formulaire, charger les entités liées pour peupler le `<select>` :

```vue
// Nuxt
const { data: categories } = await useFetch('/api/catalog/categories')

// Vue.js
const categories = ref([])
onMounted(async () => {
  const res = await categoryService.list()
  categories.value = res.items
})
```

### ManyToMany — Multi-select ou checkboxes

```vue
<div v-for="tag in allTags" :key="tag.id">
  <label>
    <input type="checkbox" :value="tag.id" v-model="form.tagIds" />
    {{ tag.name }}
  </label>
</div>
```

---

## Vérification post-génération

Après avoir généré toutes les pages d'une feature, vérifier :

1. **Liens fonctionnels** — chaque `NuxtLink`/`RouterLink` pointe vers une page qui existe (fichier créé)
2. **Pas de données hardcodées** — chercher des chaînes littérales dans les templates (ex: `"Mon produit"`, `19.99`, `"Lorem"`)
3. **Store connecté** — chaque page utilise le store et appelle les bonnes actions (`fetchAll`, `fetchOne`, `create`, `update`, `remove`)
4. **API URLs cohérentes** — les URLs dans le service frontend (`/api/{context}/{entities}`) matchent les routes du backend
5. **Types cohérents** — le type TS du formulaire correspond aux propriétés de l'entité
6. **data-testid présents** — tous les éléments listés dans la section "Attributs data-testid"
7. **Navigation mise à jour** — le layout sidebar inclut un lien vers la nouvelle entité
8. **Routes Vue.js** — si Vue.js, les routes sont ajoutées dans `routes.ts`

### Checklist rapide par page

| Page | Vérifie |
|---|---|
| Liste | Store.fetchAll appelé, table dynamique, liens vers détail/create/edit, pagination, delete modal |
| Détail | Route param `[id]`, store.fetchOne appelé, liens edit/retour, données dynamiques |
| Formulaire | Mode create/edit détecté via route, form defaults corrects, store.create/update appelé, redirect après success |
