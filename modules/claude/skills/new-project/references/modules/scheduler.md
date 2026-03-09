# Module — scheduler

- `symfony/scheduler` dans `composer.json`.
- `config/packages/scheduler.yaml` — configuration du transport scheduler.
- `src/Shared/Infrastructure/Scheduler/DefaultScheduleProvider.php` (advanced) ou `src/Scheduler/DefaultScheduleProvider.php` (simple) — implémente `ScheduleProviderInterface`.
- Chaque tâche planifiée : une `RecurringMessage` dans le provider, pointant vers un handler Messenger existant.
- Worker schedule dans `compose.yaml` : `php bin/console messenger:consume scheduler_default -vv`.
- **Tests** : vérifier que le schedule provider retourne les messages attendus.
- Variables `.env.example` : aucune variable spécifique.
