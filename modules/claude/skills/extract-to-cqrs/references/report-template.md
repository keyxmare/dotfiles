# Report Template — Extract to CQRS

## Template rapport Phase 2 (dissection)

```markdown
## Rapport de dissection — [NomController]

### Résumé
- Actions analysées : X
- Commands à créer : X
- Queries à créer : X
- Code smells détectés : X
- Complexité estimée : faible / moyenne / haute

### Action: [nomAction] (POST /api/path)

#### Classification : Command

#### Dissection du code actuel

| Ligne(s) | Catégorie | Code | Destination |
|---|---|---|---|
| 12-15 | Input | `$data = json_decode(...)` | Controller |
| 16-20 | Validation | `if (!$data['name'])` | Command (constructor) |
| 21-30 | Business logic | `$price = $base * $tax` | Domain (Entity/Service) |
| 31-35 | Persistence | `$em->persist(); $em->flush()` | Handler (Repository) |
| 36-38 | Side effect | `$mailer->send(...)` | Event Handler (async) |
| 39-42 | Output | `return new JsonResponse(...)` | Controller |

#### Code smells
- `doctrine-inline` : ligne 31 — EntityManager injecté directement
- `business-logic` : ligne 21-30 — calcul de prix dans le controller
- `setter-abuse` : ligne 25 — `$product->setPrice($price)`

#### Migration proposée

**Command** : `CreateProductCommand` (readonly class)
- Propriétés : `name: string`, `price: float`, `categoryId: string`
- Validation : `#[Assert\NotBlank]` sur `name`, `#[Assert\Positive]` sur `price`

**Handler** : `CreateProductCommandHandler`
- Injecté : `ProductRepositoryInterface`, `CategoryRepositoryInterface`
- Logique : créer l'entité via méthode factory/constructeur, sauvegarder via repository
- Domain Event : `ProductCreated` émis par l'entité

**Domain** :
- Méthode `Product::create(name, price, category)` au lieu des setters
- Value Object `ProductPrice` si logique de calcul complexe

**Event Handler** (async) :
- `SendNotificationOnProductCreated` → déplacé l'envoi d'email

### Arborescence cible

src/<BoundedContext>/
  Application/
    Command/
      CreateProductCommand.php          ← NEW
      CreateProductCommandHandler.php   ← NEW
    Query/
      GetProductQuery.php               ← NEW
      GetProductQueryHandler.php        ← NEW
    DTO/
      ProductResponse.php               ← NEW (si besoin)
    EventHandler/
      SendNotificationOnProductCreated.php  ← NEW (side effect déplacé)
  Domain/
    Model/
      Product.php                       ← MODIFIED (ajout méthodes métier)
    Event/
      ProductCreated.php                ← NEW
    Exception/
      ProductNotFoundException.php      ← NEW
  Infrastructure/
    Symfony/
      Controller/
        ProductController.php           ← MODIFIED (simplifié)
```

## Template résumé Phase 5 (bilan)

```markdown
## Résumé de la migration CQRS

### Avant
- Controller(s) : X actions, Y lignes
- Code smells : Z détectés
- Doctrine inline : X occurrences
- Logique métier dans controllers : X blocs

### Après
- Commands créées : X
- Queries créées : X
- Handlers créés : X
- Event Handlers créés : X
- Domain Events créés : X
- Entités modifiées : X (ajout méthodes métier)
- Controller(s) réduit(s) à : X lignes

### Fichiers modifiés/créés
| Fichier | Action | Description |
|---|---|---|
| `src/.../CreateProductCommand.php` | NEW | Command de création |
| `src/.../ProductController.php` | MODIFIED | Simplifié → dispatch |

### Problèmes restants
- [ ] Tests à écrire pour les handlers
- [ ] Migration des autres controllers du même BC

### Recommandations
1. Configurer les bus Messenger si pas déjà fait
2. Ajouter le middleware `doctrine_transaction` au `command.bus`
3. Migrer les autres controllers du projet progressivement
```

## Template résumé (--summary)

**Extract to CQRS — Résumé**

| Métrique | Valeur |
|----------|--------|
| Actions analysées | X |
| Commands à créer | X |
| Queries à créer | X |
| Code smells détectés | X |
| Fichiers à créer | X |

**Top 5 code smells :**

| # | Action | Smell | Gravité |
|---|--------|-------|---------|
| 1 | Controller::create | doctrine-inline | Haute |

## Template JSON (--output=json)

```json
{
  "skill": "extract-to-cqrs",
  "date": "YYYY-MM-DD",
  "scope": "src/Controller/ProductController.php",
  "actions": [
    {
      "name": "create",
      "type": "command",
      "smells": ["doctrine-inline", "business-logic"],
      "migration": {
        "command": "CreateProductCommand",
        "handler": "CreateProductCommandHandler",
        "events": ["ProductCreated"]
      }
    }
  ],
  "summary": {
    "commands": 3,
    "queries": 2,
    "smells": 8,
    "files_to_create": 12
  }
}
```
