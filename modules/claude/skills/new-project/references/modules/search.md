# Module — search

- `meilisearch/meilisearch-php` dans `composer.json`.
- Service Meilisearch dans `compose.yaml` : `getmeili/meilisearch:latest`, port 7700, volume pour les données, healthcheck `curl -f http://localhost:7700/health`.
- `src/Shared/Infrastructure/Search/MeilisearchClient.php` (advanced) ou `src/Search/MeilisearchClient.php` (simple) — client wrapper, inject `MEILISEARCH_URL` et `MEILISEARCH_API_KEY`.
- `src/Shared/Infrastructure/Search/SearchIndexer.php` — service d'indexation. Méthodes : `index(string $indexName, array $documents)`, `search(string $indexName, string $query, array $options)`, `delete(string $indexName, string $id)`.
- Si `messenger` actif : l'indexation est asynchrone via un event listener Messenger.
- **Frontend** (si présent) :
  - Composable `useSearch(indexName)` — debounced search, résultats réactifs.
  - Composant `SearchInput` avec auto-complétion.
- Variables `.env.example` : `MEILISEARCH_URL=http://meilisearch:7700`, `MEILISEARCH_API_KEY=masterKey`.
- **Tests** : test d'intégration indexation + recherche.
