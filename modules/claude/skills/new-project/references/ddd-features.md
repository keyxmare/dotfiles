# Référence — Génération de features DDD/CQRS

## Backend — mode advanced (DDD/CQRS)

| Opération | Fichiers générés |
|---|---|
| CREATE | `Domain/Model/{Entity}.php`, `Domain/Repository/{Entity}RepositoryInterface.php`, `Domain/Event/{Entity}Created.php`, `Application/Command/Create{Entity}Command.php`, `Application/CommandHandler/Create{Entity}Handler.php`, `Application/DTO/Create{Entity}Input.php`, `Infrastructure/Controller/Create{Entity}Controller.php` (`POST /api/{context}/{entities}`), `Infrastructure/Persistence/Doctrine/{Entity}Repository.php` |
| READ | `Application/Query/Get{Entity}Query.php`, `Application/QueryHandler/Get{Entity}Handler.php`, `Application/DTO/{Entity}Output.php`, `Infrastructure/Controller/Get{Entity}Controller.php` (`GET .../{id}`) |
| LIST | `Application/Query/List{Entities}Query.php` (pagination), `Application/QueryHandler/List{Entities}Handler.php`, `Application/DTO/{Entity}ListOutput.php`, `Infrastructure/Controller/List{Entities}Controller.php` (`GET ...`) |
| UPDATE | `Domain/Event/{Entity}Updated.php`, `Application/Command/Update{Entity}Command.php`, `Application/CommandHandler/Update{Entity}Handler.php`, `Application/DTO/Update{Entity}Input.php`, `Infrastructure/Controller/Update{Entity}Controller.php` (`PUT .../{id}`) |
| DELETE | `Domain/Event/{Entity}Deleted.php`, `Application/Command/Delete{Entity}Command.php`, `Application/CommandHandler/Delete{Entity}Handler.php`, `Infrastructure/Controller/Delete{Entity}Controller.php` (`DELETE .../{id}`) |
| PATCH | `Application/Command/Patch{Entity}Command.php`, `Application/CommandHandler/Patch{Entity}Handler.php`, `Application/DTO/Patch{Entity}Input.php`, `Infrastructure/Controller/Patch{Entity}Controller.php` (`PATCH .../{id}`) |

## Backend — mode simple

| Opération | Fichiers générés |
|---|---|
| CREATE | `Entity/{Entity}.php` (si première opération), `Repository/{Entity}Repository.php` (si première), `Service/{Entity}Service.php` (méthode `create()`), `Controller/{Entity}Controller.php` (méthode `create()`, `POST /api/{entities}`) |
| READ | `Service/{Entity}Service.php` (méthode `get()`), `Controller/{Entity}Controller.php` (méthode `show()`, `GET /api/{entities}/{id}`) |
| LIST | `Service/{Entity}Service.php` (méthode `list()`), `Controller/{Entity}Controller.php` (méthode `index()`, `GET /api/{entities}`) |
| UPDATE | `Service/{Entity}Service.php` (méthode `update()`), `Controller/{Entity}Controller.php` (méthode `update()`, `PUT /api/{entities}/{id}`) |
| DELETE | `Service/{Entity}Service.php` (méthode `delete()`), `Controller/{Entity}Controller.php` (méthode `destroy()`, `DELETE /api/{entities}/{id}`) |
| PATCH | `Service/{Entity}Service.php` (méthode `patch()`), `Controller/{Entity}Controller.php` (méthode `patch()`, `PATCH /api/{entities}/{id}`) |

En mode simple, un seul Controller et un seul Service regroupent toutes les opérations CRUD d'une entité. L'Entity inclut les annotations/attributs Doctrine directement (pas de mapping XML séparé).

### Templates mode simple

| Fichier généré | Template |
|---|---|
| `Entity/{Entity}.php` | `entity-simple.php.tpl` |
| `Service/{Entity}Service.php` | `service-crud.php.tpl` |
| `Controller/{Entity}Controller.php` | `controller-crud.php.tpl` |
| `Tests/Functional/Controller/{Entity}ControllerTest.php` | `controller-crud-test.php.tpl` |

### Conventions mode simple

| Élément | Convention | Exemple |
|---|---|---|
| Entity | PascalCase singulier | `Product` |
| Repository | `{Entity}Repository` | `ProductRepository` |
| Service | `{Entity}Service` | `ProductService` |
| Controller | `{Entity}Controller` | `ProductController` |
| Test Service | `{Entity}ServiceTest` | `ProductServiceTest` |
| Test Controller | `{Entity}ControllerTest` | `ProductControllerTest` |

## Frontend — par opération CRUD

**Règle fondamentale : JAMAIS de données hardcodées. Tout contenu provient de l'API via le store Pinia.**

Lire `references/template-resolution.md` pour les règles complètes de résolution des placeholders, le mapping propriété → composant UI, et les conventions de routage.

### Templates par framework

Utiliser les templates spécifiques au framework frontend :

| Fichier | Nuxt | Vue.js |
|---|---|---|
| Page liste | `list-page-nuxt.vue.tpl` | `list-page-vue.vue.tpl` |
| Page détail | `detail-page-nuxt.vue.tpl` | `detail-page-vue.vue.tpl` |
| Page formulaire | `form-page-nuxt.vue.tpl` | `form-page-vue.vue.tpl` |
| Service API | `service-nuxt.ts.tpl` | `service-vue.ts.tpl` |
| Store Pinia | `store.ts.tpl` | `store.ts.tpl` |

**Ne plus utiliser** `page.vue.tpl`, `form-page.vue.tpl`, `service.ts.tpl` (dépréciés).

### Fichiers générés par opération CRUD

| Opération | Fichiers générés |
|---|---|
| CREATE | Page formulaire (`form-page-{fw}.vue.tpl`), store action `create()`, service `post()` |
| READ | Page détail (`detail-page-{fw}.vue.tpl`), store action `fetchOne()`, service `get()` |
| LIST | Page liste (`list-page-{fw}.vue.tpl`), store state + action `fetchAll()`, service `list()` |
| UPDATE | Réutilise la page formulaire (mode edit via route param `id`), store `update()`, service `put()` |
| DELETE | Modale inline dans la page liste (data-testid `delete-modal`), store `remove()`, service `delete()` |
| PATCH | Réutilise le formulaire UPDATE (champs optionnels), store `patch()`, service `patch()` |

### Convention de routage frontend

#### Nuxt (file-based routing)

| Page | URL | Fichier (directories DDD) | Fichier (simple) |
|---|---|---|---|
| Liste | `/{context}/{entities}` | `app/{context}/pages/{entities}/index.vue` | `app/pages/{entities}/index.vue` |
| Détail | `/{context}/{entities}/{id}` | `app/{context}/pages/{entities}/[id].vue` | `app/pages/{entities}/[id].vue` |
| Création | `/{context}/{entities}/new` | `app/{context}/pages/{entities}/new.vue` | `app/pages/{entities}/new.vue` |
| Édition | `/{context}/{entities}/{id}/edit` | `app/{context}/pages/{entities}/[id]/edit.vue` | `app/pages/{entities}/[id]/edit.vue` |

#### Vue.js (route manuelle dans routes.ts)

| Page | URL | Fichier (DDD) | Fichier (simple) |
|---|---|---|---|
| Liste | `/{context}/{entities}` | `src/{context}/pages/{Entity}List.vue` | `src/pages/{Entity}List.vue` |
| Détail | `/{context}/{entities}/:id` | `src/{context}/pages/{Entity}Detail.vue` | `src/pages/{Entity}Detail.vue` |
| Création | `/{context}/{entities}/new` | `src/{context}/pages/{Entity}Form.vue` | `src/pages/{Entity}Form.vue` |
| Édition | `/{context}/{entities}/:id/edit` | `src/{context}/pages/{Entity}Form.vue` | `src/pages/{Entity}Form.vue` |

### Intégration navigation

Après génération des pages, **mettre à jour le layout** (sidebar/nav) pour ajouter un lien vers la page liste de chaque entité. Voir `references/template-resolution.md` section "Intégration navigation".

### Vue.js — Routes

Après génération des pages Vue.js, ajouter les routes dans `src/{context}/routes.ts` et les importer dans `src/app/router.ts`.

### Attributs data-testid

Chaque élément interactif reçoit un `data-testid` pour les tests E2E. Convention complète dans `references/template-resolution.md` section "Attributs data-testid".

## Frontend — types

Pour chaque entité, générer un fichier de type TypeScript :

| Fichier | Template |
|---|---|
| `types/{entity-kebab}.ts` | `entity-type.ts.tpl` |

Ce fichier est généré une seule fois par entité (lors de la première opération CRUD).

## Code structurel — généré à l'étape 6.4

Ces fichiers sont générés une seule fois pendant le scaffold initial (pas par feature) :

| Fichier | Template | Emplacement (advanced) | Emplacement (simple) |
|---|---|---|---|
| `ApiResponse` | `api-response.php.tpl` | `Shared/Application/DTO/ApiResponse.php` | `src/DTO/ApiResponse.php` |
| `PaginatedOutput` | `paginated-output.php.tpl` | `Shared/Application/DTO/PaginatedOutput.php` | `src/DTO/PaginatedOutput.php` |
| `DomainException` | `domain-exception.php.tpl` | `Shared/Domain/Exception/DomainException.php` | `src/Exception/DomainException.php` |
| `NotFoundException` | `not-found-exception.php.tpl` | `Shared/Domain/Exception/NotFoundException.php` | `src/Exception/NotFoundException.php` |
| `ErrorOutput` | `error-output.php.tpl` | `Shared/Application/DTO/ErrorOutput.php` | `src/DTO/ErrorOutput.php` |
| `ExceptionListener` | `exception-listener.php.tpl` | `Shared/Infrastructure/EventListener/ExceptionListener.php` | `src/EventListener/ExceptionListener.php` |

## Tests — pyramide complète après chaque feature

### Unitaires (toujours)

- Backend : `tests/Unit/{Context}/Application/CommandHandler/Create{Entity}HandlerTest.php`, etc. Handlers testés avec mocks des repositories. Template : `handler-test.php.tpl`, `query-handler-test.php.tpl`.
- Frontend : `tests/unit/{context}/stores/{entity}.test.ts`. Test du store par feature. Template : `store-test.ts.tpl`.

### Intégration (toujours)

- Backend repository : `tests/Integration/{Context}/Infrastructure/Persistence/Doctrine/{Entity}RepositoryTest.php`. Test avec vraie BDD (transaction rollback). Template : `integration-repository-test.php.tpl`.
- Backend controller : `tests/Functional/{Context}/Infrastructure/Controller/{Action}{Entity}ControllerTest.php`. Test HTTP request/response via `WebTestCase`. Template : `integration-controller-test.php.tpl`. Au minimum un test par opération CRUD (status code + format réponse).

### E2E (si `tests.e2e: true`)

- `tests/e2e/{context}/{entity}.spec.ts` — Parcours CRUD complet via Playwright. Template : `e2e-crud.spec.ts.tpl`. Un seul fichier par entité couvrant le parcours list → create → read → update → delete.
- Généré uniquement si le frontend est présent et que `tests.e2e` = `true`.

### Résumé par opération

| Opération | Test unitaire | Test intégration | Test E2E |
|---|---|---|---|
| CREATE | `CreateHandlerTest` | `CreateControllerTest` (201) + `RepositoryTest` (save) | Create flow |
| READ | `GetHandlerTest` | `GetControllerTest` (200, 404) | Detail page |
| LIST | `ListHandlerTest` | `ListControllerTest` (200, pagination) | List page |
| UPDATE | `UpdateHandlerTest` | `UpdateControllerTest` (200, 404) | Update flow |
| DELETE | `DeleteHandlerTest` | `DeleteControllerTest` (204, 404) | Delete confirmation |
| PATCH | `PatchHandlerTest` | `PatchControllerTest` (200, 404, 422) | Update flow (partial) |

## Tests Pest (si `tests.php_framework` = `pest`)

Quand Pest est actif, les tests backend suivent la syntaxe fonctionnelle. L'arborescence des fichiers reste identique.

### Adaptation des templates

Les templates PHPUnit (`handler-test.php.tpl`, `query-handler-test.php.tpl`, etc.) doivent être adaptés en syntaxe Pest. Voir `~/.claude/TEST.md` (section "Pest") pour la table de correspondance PHPUnit → Pest.

### Templates Pest

Les templates Pest sont dans `assets/templates/` avec le suffixe `-pest.php.tpl`. Ils suivent les mêmes conventions que les templates PHPUnit mais en syntaxe fonctionnelle Pest (`describe`, `it`, `beforeEach`, `expect`).

| Template PHPUnit | Template Pest |
|---|---|
| `handler-test.php.tpl` | `handler-test-pest.php.tpl` |
| `query-handler-test.php.tpl` | `query-handler-test-pest.php.tpl` |
| `integration-controller-test.php.tpl` | `integration-controller-test-pest.php.tpl` |
| `integration-repository-test.php.tpl` | `integration-repository-test-pest.php.tpl` |
| `controller-crud-test.php.tpl` | `controller-crud-test-pest.php.tpl` |
| `event-listener-test.php.tpl` | `event-listener-test-pest.php.tpl` |
| `service-php-test.php.tpl` | `service-php-test-pest.php.tpl` |

### Configuration Pest

Le scaffold génère `pest.php` à la racine du backend avec les groupes `unit`, `integration`, `functional`. Le fichier `phpunit.xml.dist` reste nécessaire (Pest l'utilise en interne pour les testsuites).

## Documentation — au fur et à mesure

- `docs/api/openapi.yaml` → ajouter les endpoints créés (si `doc.openapi`).
- `docs/features/{context}.md` → périmètre du context, entités, features (si advanced).
- `docs/c4/context.md` → mettre à jour le diagramme C2 (container) si un nouveau bounded context ou module est ajouté (si `doc.c4`). Ne pas modifier le C1 sauf si un acteur externe est ajouté.
- `docs/ARCHITECTURE.md` → mettre à jour si un nouveau module est activé ou un pattern architectural ajouté.

## Migration

Créer la migration initiale avec les tables correspondant aux entités.

## Factories de test

Chaque entité génère une factory dans `tests/Factory/{Context}/` (template `entity-factory.php.tpl`). Les factories sont utilisées dans les tests unitaires et d'intégration pour créer des instances d'entité avec des valeurs par défaut réalistes.

Fichier généré : `tests/Factory/{Context}/{Entity}Factory.php`

---

## Conventions de nommage

| Élément | Convention | Exemple |
|---|---|---|
| Entity | PascalCase singulier | `Product` |
| Table BDD | snake_case pluriel | `products` |
| Endpoint | kebab-case pluriel | `/api/catalog/products` |
| Command | `{Action}{Entity}Command` | `CreateProductCommand` |
| Handler | `{Action}{Entity}Handler` | `CreateProductHandler` |
| Controller | `{Action}{Entity}Controller` | `CreateProductController` |
| DTO Input | `{Action}{Entity}Input` | `CreateProductInput` |
| DTO Output | `{Entity}Output` | `ProductOutput` |
| Event | `{Entity}{Action}` (passé composé) | `ProductCreated` |
| Test | `{ClassTestée}Test` | `CreateProductHandlerTest` |
| Filter DTO | `List{Entities}Query` (avec filters + sortBy) | `ListProductsQuery` |
| Soft delete trait | `SoftDeletable` | `$deletedAt`, `softDelete()`, `restore()`, `isDeleted()` |

---

## Mapping de types (pour /new-project:entity)

| Type argument | PHP | Doctrine | TypeScript |
|---|---|---|---|
| `string` | `string` | `type: 'string', length: 255` | `string` |
| `text` | `string` | `type: 'text'` | `string` |
| `int` | `int` | `type: 'integer'` | `number` |
| `float` | `float` | `type: 'float'` | `number` |
| `bool` | `bool` | `type: 'boolean'` | `boolean` |
| `datetime` | `\DateTimeImmutable` | `type: 'datetime_immutable'` | `string` (ISO 8601) |
| `uuid` | `Uuid` | `type: 'uuid'` | `string` |
| `json` | `array` | `type: 'json'` | `Record<string, unknown>` |
| `enum(...)` | PHP enum | `type: 'string', enumType: ...` | `union type` |
| `softdelete` | `?\DateTimeImmutable` | `type: 'datetime_immutable', nullable: true` | `string \| null` (ISO 8601) |

---

## Relations entre entités

Les entités peuvent déclarer des relations avec d'autres entités. Les relations sont stockées dans `scaffold.config.json` et génèrent les attributs Doctrine + types TypeScript appropriés.

### Types de relations

| Type | Doctrine | PHP (propriétaire) | PHP (inverse) | TypeScript |
|---|---|---|---|---|
| `ManyToOne` | `#[ORM\ManyToOne]` | `?Category $category` | `Collection<Product> $products` | `category: Category \| null` |
| `OneToMany` | `#[ORM\OneToMany]` | `Collection<Product> $products` | — | `products: Product[]` |
| `ManyToMany` | `#[ORM\ManyToMany]` | `Collection<Tag> $tags` | `Collection<Product> $products` | `tags: Tag[]` |
| `OneToOne` | `#[ORM\OneToOne]` | `?Profile $profile` | — | `profile: Profile \| null` |

### Génération PHP

Pour une relation `ManyToOne` (Product → Category) :

```php
// Sur Product (propriétaire)
#[ORM\ManyToOne(targetEntity: Category::class, inversedBy: 'products')]
#[ORM\JoinColumn(nullable: false)]
private Category $category;

// Sur Category (inverse) — généré si inversedBy est déclaré
#[ORM\OneToMany(targetEntity: Product::class, mappedBy: 'category')]
private Collection $products;
```

Le constructeur initialise les collections :

```php
private function __construct(/* ... */)
{
    $this->products = new ArrayCollection();
}
```

### Génération TypeScript

```typescript
// types/product.ts
import type { Category } from './category'

export interface Product {
  id: string
  name: string
  price: number
  category: Category  // ManyToOne → objet imbriqué
}

// types/category.ts
import type { Product } from './product'

export interface Category {
  id: string
  name: string
  products?: Product[]  // OneToMany → tableau optionnel (pas toujours chargé)
}
```

### Génération frontend (formulaires)

- `ManyToOne` → Select ou Autocomplete pour choisir l'entité liée (fetch de la liste via le service API)
- `ManyToMany` → Multi-select ou Checkbox group
- `OneToOne` → Formulaire inline ou Select

### Impact sur les DTOs

Les DTOs Input (Create/Update) acceptent l'**ID** de l'entité liée, pas l'objet complet :

```php
final readonly class CreateProductInput
{
    public function __construct(
        #[Assert\NotBlank]
        public string $name,
        #[Assert\Positive]
        public float $price,
        #[Assert\NotBlank]
        #[Assert\Uuid]
        public string $categoryId,  // ← ID, pas l'objet
    ) {
    }
}
```

Le handler résout l'entité liée via le repository :

```php
$category = $this->categoryRepository->get($command->input->categoryId);
$product = Product::create(name: $command->input->name, price: $command->input->price, category: $category);
```

### Impact sur les DTOs Output

Les DTOs Output incluent l'**objet imbriqué** (au moins l'id et le label) :

```php
final readonly class ProductOutput
{
    public function __construct(
        public string $id,
        public string $name,
        public float $price,
        public CategorySummaryOutput $category,  // ← objet résumé
    ) {
    }
}
```

### scaffold.config.json

```json
{
  "name": "Product",
  "properties": { "name": "string", "price": "float" },
  "relations": [
    { "target": "Category", "type": "ManyToOne", "nullable": false, "inversedBy": "products" },
    { "target": "Tag", "type": "ManyToMany" }
  ],
  "crud": ["CREATE", "READ", "LIST", "UPDATE", "DELETE"]
}
```

### Cross-context relations

Si une relation cible une entité d'un autre bounded context :
- Utiliser l'**ID** comme référence (pas d'import direct cross-context)
- Le type PHP est `string` (UUID), pas l'entité
- La résolution se fait via un service applicatif ou un query cross-context
- Le type TypeScript reste `string` pour l'ID

Exemple : `Order` (context Order) référence `User` (context Identity) :

```json
{ "target": "User", "type": "ManyToOne", "nullable": false }
```

→ Génère `private string $userId` (pas `private User $user`)
