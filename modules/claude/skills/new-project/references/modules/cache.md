# Module — cache

- `symfony/cache` dans `composer.json` (déjà inclus par défaut dans Symfony, mais configurer le pool Redis).
- Service Redis dans `compose.yaml` : `redis:7-alpine`, port 6379, healthcheck `redis-cli ping`.
- `config/packages/cache.yaml` :

```yaml
framework:
    cache:
        app: cache.adapter.redis
        default_redis_provider: '%env(REDIS_URL)%'
```

- Variables `.env.example` : `REDIS_URL=redis://redis:6379`.
- Si le module `messenger` est actif : configurer le transport `doctrine` ou `redis` pour Messenger.
- **Tests** : test d'intégration vérifiant cache set/get/delete avec le pool Redis.
