# Stack Performance

## Caching

### Stratégie par couche
- **HTTP Cache** : utiliser les headers Cache-Control, ETag, Last-Modified via Symfony HttpCache ou Varnish.
- **Application Cache** : Symfony Cache component (`CacheInterface`) pour les résultats de queries coûteuses.
- **Doctrine** : activer le Second Level Cache pour les entités fréquemment lues et rarement modifiées.
- **Redis** : pour le cache partagé, les sessions, et le rate limiting.

### Règles
- Cacher au niveau le plus haut possible (HTTP > Application > Doctrine).
- Toujours définir une stratégie d'invalidation AVANT de cacher.
- Nommer les clés de cache avec le pattern : `<bounded_context>.<entity>.<id>.<version>`.
- TTL raisonnable : pas de cache infini sauf données statiques.

## Optimisation Doctrine / BDD

### Queries
- Éviter les N+1 : utiliser `JOIN FETCH` ou `addSelect` dans le QueryBuilder.
- Utiliser `toIterable()` pour les gros datasets (évite de charger tout en mémoire).
- Paginer les résultats. Ne jamais `findAll()` sans limite.
- Utiliser des projections (DTO via `NEW`) pour les lectures plutôt que de charger des entités complètes.

### Indexes
- Index sur toutes les colonnes de WHERE, ORDER BY et JOIN.
- Index composites dans l'ordre des colonnes les plus sélectives.
- Utiliser `EXPLAIN` pour valider les queries critiques.

### Lazy loading
- Désactiver le lazy loading en production (Doctrine proxy).
- Charger explicitement les relations nécessaires via les repositories.

## Profiling
- Utiliser la Symfony Profiler Toolbar en développement.
- Blackfire pour le profiling avancé en staging/production.
- Surveiller : nombre de queries par requête, temps de réponse, consommation mémoire.
- Objectif : < 10 queries par requête, < 200ms temps de réponse.
