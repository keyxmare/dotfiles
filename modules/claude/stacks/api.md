# Stack — Conventions API REST

## Principes

- RESTful, orienté ressources.
- JSON uniquement (Content-Type: application/json). Retourner `415 Unsupported Media Type` si le client envoie un autre Content-Type.
- Versionné selon `api.versioning` :
  - `path` (défaut) : `/api/v1/...`
  - `header` : `Accept: application/vnd.api.v1+json`
- Stateless : pas de session côté serveur, authentification via token (JWT, OAuth2).

## Nommage

- Les endpoints utilisent des noms au pluriel, en kebab-case : `/api/v1/users`, `/api/v1/order-items`.
- Les ressources imbriquées se lisent naturellement : `/api/v1/users/{id}/orders`.
- Maximum 2 niveaux d'imbrication. Au-delà, utiliser des filtres ou des query params.
- Pas de verbes dans les URLs. L'action est portée par la méthode HTTP.

## Méthodes HTTP

| Méthode | Usage | Idempotent | Body |
|---|---|---|---|
| `GET` | Lire une ressource ou une collection | Oui | Non |
| `POST` | Créer une ressource | Non | Oui |
| `PUT` | Remplacer une ressource complète | Oui | Oui |
| `PATCH` | Modifier partiellement une ressource | Non | Oui |
| `DELETE` | Supprimer une ressource | Oui | Non |

### Quand utiliser PUT vs PATCH

- **PATCH** est le choix par défaut pour les mises à jour. Il envoie uniquement les champs à modifier.
- **PUT** uniquement quand le client remplace intégralement la ressource (tous les champs envoyés, les absents remis à leur valeur par défaut).
- En pratique, 90% des cas d'usage sont couverts par PATCH.

## Status codes

### Succès

| Code | Usage |
|---|---|
| `200 OK` | Requête réussie (GET, PUT, PATCH) |
| `201 Created` | Ressource créée (POST). Header `Location` avec l'URL de la ressource. |
| `204 No Content` | Succès sans contenu (DELETE) |

### Erreurs client

| Code | Usage |
|---|---|
| `400 Bad Request` | Données invalides, validation échouée |
| `401 Unauthorized` | Non authentifié |
| `403 Forbidden` | Authentifié mais pas autorisé |
| `404 Not Found` | Ressource inexistante |
| `409 Conflict` | Conflit (doublon, état incohérent) |
| `422 Unprocessable Entity` | Données valides syntaxiquement mais sémantiquement incorrectes |
| `415 Unsupported Media Type` | Content-Type non supporté |
| `429 Too Many Requests` | Rate limiting |

### Erreurs serveur

| Code | Usage |
|---|---|
| `500 Internal Server Error` | Erreur inattendue côté serveur |
| `502 Bad Gateway` | Service en amont indisponible |
| `503 Service Unavailable` | Service temporairement indisponible |

## Format d'erreur

Toutes les erreurs retournent un format cohérent :

```json
{
  "type": "https://api.example.com/errors/validation",
  "title": "Validation Failed",
  "status": 422,
  "detail": "One or more fields are invalid.",
  "errors": [
    {
      "field": "email",
      "message": "Invalid email format."
    }
  ]
}
```

Basé sur [RFC 9457 (Problem Details)](https://www.rfc-editor.org/rfc/rfc9457). Le champ `type` doit être un URI (absolue ou URN). Utiliser `"about:blank"` si aucun type spécifique n'est défini. Le champ `errors` (array de détails par champ) est une extension projet — non défini par la RFC mais utile pour les erreurs de validation.

## Pagination

Pour les collections, pagination obligatoire avec des query params :

```
GET /api/v1/users?page=2&limit=20
```

Réponse avec métadonnées de pagination :

```json
{
  "data": [...],
  "meta": {
    "current_page": 2,
    "per_page": 20,
    "total": 150,
    "total_pages": 8
  }
}
```

- `limit` par défaut : 20. Maximum : 100.
- Toujours retourner les métadonnées de pagination.

## Filtrage et tri

```
GET /api/v1/products?category=electronics&sort=-created_at,name
```

- Filtres via query params nommés par champ.
- Tri via `sort` : préfixe `-` pour descendant, pas de préfixe pour ascendant.
- Plusieurs champs de tri séparés par virgule.

## Relations et inclusion

```
GET /api/v1/orders?include=items,customer
```

- Utiliser `include` pour charger des relations (éviter le N+1 côté client).
- Ne pas inclure par défaut : le client demande explicitement ce dont il a besoin.

## Authentification

- JWT Bearer token dans le header `Authorization: Bearer <token>`.
- Les tokens ont une durée de vie limitée.
- Refresh token pour renouveler les access tokens.
- Ne jamais passer de token dans l'URL.

## Rate limiting

- Headers de réponse : `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`.
- Retourner `429 Too Many Requests` quand la limite est atteinte.

## HATEOAS

Optionnel mais recommandé pour les API publiques. Inclure des liens de navigation :

```json
{
  "data": { "id": 1, "name": "..." },
  "links": {
    "self": "/api/v1/users/1",
    "orders": "/api/v1/users/1/orders"
  }
}
```

## Opérations bulk

Pour les opérations portant sur plusieurs ressources à la fois :

- **Suppression multiple** — `DELETE /api/v1/users` avec un body `{ "ids": ["uuid1", "uuid2"] }`. Retourne `204` si tout est supprimé, `207 Multi-Status` si résultats partiels.
- **Création multiple** — `POST /api/v1/users/bulk` avec un body `{ "items": [{...}, {...}] }`. Retourne `201` avec le détail de chaque résultat.
- **Mise à jour multiple** — `PATCH /api/v1/users/bulk` avec un body `{ "items": [{ "id": "uuid1", "name": "..." }, ...] }`.
- Toujours retourner le détail par élément en cas de succès partiel (`207 Multi-Status`).
- Limiter le nombre d'éléments par requête bulk (max 100 par défaut).
- Les opérations bulk sont idempotentes quand c'est possible.

## Endpoints de santé (observabilité)

Tout service exposant une API doit fournir des endpoints de santé standardisés :

| Endpoint | Usage | Code succès |
|---|---|---|
| `GET /healthz` | Liveness — le service est démarré et répond | `200` |
| `GET /readyz` | Readiness — le service est prêt à recevoir du trafic (BDD connectée, cache, etc.) | `200` |

- `/healthz` retourne `200` tant que le process tourne. Pas de vérification de dépendances.
- `/readyz` vérifie les dépendances critiques (BDD, cache, broker). Retourne `503` si une dépendance est indisponible.
- Ces endpoints ne nécessitent pas d'authentification.
- Format de réponse : `{ "status": "ok" }` ou `{ "status": "degraded", "checks": { "database": "ok", "redis": "fail" } }`.
- Utilisés par Docker healthcheck, Kubernetes probes, et load balancers.
