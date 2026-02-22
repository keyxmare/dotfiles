# Stack Error Handling

## Exceptions par couche DDD

### Domain — Exceptions métier
- Héritent d'une `DomainException` abstraite propre au projet.
- Représentent une violation de règle métier.
- Nommage explicite en langage métier : `InsufficientStockException`, `OrderAlreadyCancelledException`.
- Portent le contexte nécessaire (IDs, valeurs attendues vs reçues).
- Aucune dépendance framework.

```php
final class InsufficientStockException extends DomainException
{
    public function __construct(
        public readonly ProductId $productId,
        public readonly int $requested,
        public readonly int $available,
    ) {
        parent::__construct(sprintf(
            'Insufficient stock for product %s: requested %d, available %d',
            $productId,
            $requested,
            $available,
        ));
    }
}
```

### Application — Exceptions applicatives
- `EntityNotFoundException` : ressource introuvable (traduite en 404).
- `AccessDeniedException` : permission refusée (traduite en 403).
- `ValidationException` : input invalide (traduite en 422).
- Lancées dans les Command/Query Handlers.

### Infrastructure — Exceptions techniques
- Erreurs de connexion BDD, timeouts API externe, erreurs filesystem.
- Catchées et wrappées dans des exceptions applicatives quand possible.
- Loggées avec le contexte complet (stack trace, payload).

## Mapping HTTP

Le Controller ou un EventListener mappe les exceptions en réponses HTTP :

| Exception | HTTP Status |
|-----------|-------------|
| `DomainException` | `400 Bad Request` ou `409 Conflict` |
| `EntityNotFoundException` | `404 Not Found` |
| `AccessDeniedException` | `403 Forbidden` |
| `ValidationException` | `422 Unprocessable Entity` |
| `\RuntimeException` (technique) | `500 Internal Server Error` |

## Règles

### Ne pas faire
- `catch (\Exception $e)` générique sans re-throw. Attraper uniquement ce qu'on sait gérer.
- Avaler les exceptions silencieusement (`catch { // ignore }`).
- Utiliser les exceptions pour le contrôle de flux (if/else déguisé).
- Exposer des détails techniques dans les réponses API (stack traces, SQL).
- Lancer des exceptions dans le constructeur des entités pour de la simple validation de format (utiliser les Value Objects).

### Faire
- Fail fast : valider au plus tôt (VO constructors, guard clauses).
- Un type d'exception par cas métier distinct.
- Logger les exceptions techniques en `error`/`critical`.
- Retourner des messages d'erreur utiles en API : code d'erreur machine + message humain.
- Tester les cas d'erreur dans les tests unitaires.

## Format de réponse d'erreur API
```json
{
    "type": "insufficient_stock",
    "message": "Stock insuffisant pour le produit.",
    "details": {
        "productId": "550e8400-e29b-41d4-a716-446655440000",
        "requested": 5,
        "available": 2
    }
}
```
