# Module — mercure

- `symfony/mercure-bundle` dans `composer.json`.
- `config/packages/mercure.yaml` — hub URL et JWT secret.
- Publisher service dans `Shared/Infrastructure/Mercure/MercurePublisher.php`.
- Composable `useMercure()` côté frontend — connexion EventSource, gestion reconnexion.
- Service Mercure dans `compose.yaml` (image `dunglas/mercure`).
- Variables `.env.example` : `MERCURE_URL`, `MERCURE_PUBLIC_URL`, `MERCURE_JWT_SECRET`.
