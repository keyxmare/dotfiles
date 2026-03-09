# Module — monitoring

## Base (toujours inclus avec le module)

- `HealthController` — `GET /health` vérifiant :
  - Connexion BDD (si configurée).
  - Services critiques (Mercure, RabbitMQ, Redis, Meilisearch si présents).
  - Retourne `200 OK` avec JSON `{ "status": "ok", "checks": { ... } }` ou `503` si un check échoue.
- `config/packages/monolog.yaml` — JSON formatter pour les logs structurés en prod.
- Page frontend `/status` affichant l'état des APIs backend (appel au health endpoint).
- Healthchecks Docker renforcés pour chaque service dans `compose.yaml`.

**Note :** Les endpoints `/healthz` et `/readyz` sont générés dans le scaffold de base (templates `health-controller.php.tpl` et `readiness-controller.php.tpl`), indépendamment du module monitoring. Le module monitoring les enrichit avec des checks supplémentaires sur les services dépendants.

## OpenTelemetry (inclus par défaut avec le module)

Traces distribuées automatiques — aucune instrumentation manuelle requise :

- `open-telemetry/sdk` + `open-telemetry/exporter-otlp` + `open-telemetry/contrib-auto-symfony` dans `composer.json`.
- `config/packages/open_telemetry.yaml` — configuration de l'exporter OTLP.
- Instrumentation automatique sur HTTP (requests/responses), Doctrine (queries), Messenger (messages).
- Variables `.env.example` :
  - `OTEL_EXPORTER_OTLP_ENDPOINT=http://jaeger:4318`
  - `OTEL_SERVICE_NAME={{PROJECT_NAME}}`
- Service **Jaeger** dans `compose.override.yaml` (dev uniquement) :
  ```yaml
  jaeger:
    image: jaegertracing/all-in-one:latest
    ports:
      - "16686:16686"
      - "4318:4318"
  ```
- Target Makefile : `make traces` → ouvre `http://localhost:16686` (Jaeger UI).

## Prometheus (optionnel)

Activer seulement si l'utilisateur mentionne "métriques", "prometheus" ou "APM" :

- `promphp/prometheus_client_php` dans `composer.json`.
- `PrometheusController` — `GET /metrics` exposant les métriques au format Prometheus.
- Compteurs par défaut : requêtes HTTP, durée, erreurs.
- Service Prometheus dans `compose.yaml` si demandé.
