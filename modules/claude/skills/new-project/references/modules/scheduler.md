# Module — scheduler

- `symfony/scheduler` dans `composer.json`.
- `config/packages/scheduler.yaml` — configuration minimale : `framework: scheduler: { enabled: true }`. Ne pas configurer de `transport` (le scheduler utilise le transport Messenger sous-jacent).
- `src/Schedule.php` — classe implémentant `#[AsSchedule]` avec les `RecurringMessage` de l'application. Chaque message pointe vers un handler Messenger existant.
- `src/Shared/Infrastructure/Scheduler/DefaultScheduleProvider.php` (advanced) ou `src/Scheduler/DefaultScheduleProvider.php` (simple) — implémente `ScheduleProviderInterface`.
- Chaque tâche planifiée : une `RecurringMessage` dans le provider, pointant vers un handler Messenger existant.
- Worker schedule dans `compose.yaml` : `php bin/console messenger:consume scheduler_default -vv`.
- **Tests** : vérifier que le schedule provider retourne les messages attendus.
- Variables `.env.example` : aucune variable spécifique.
