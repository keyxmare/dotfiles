# Module — admin

- `easycorp/easyadmin-bundle` dans `composer.json`.
- `src/Shared/Infrastructure/Admin/DashboardController.php` (advanced) ou `src/Admin/DashboardController.php` (simple) — dashboard EasyAdmin.
- Un `CrudController` par entité existante dans le projet (auto-détection depuis `scaffold.config.json.features`).
- Route : `/admin` (protégée par firewall, rôle `ROLE_ADMIN` — nécessite le module `auth`).
- Configuration `security.yaml` : access control pour `/admin`.
- **Tests** : test d'accès au dashboard (authentifié vs non-authentifié).
- Ne génère **pas** de frontend additionnel — EasyAdmin fournit sa propre UI.
