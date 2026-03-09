# Module — mailer

- `config/packages/mailer.yaml` — transport DSN (`MAILER_DSN` dans `.env`).
- `src/Shared/Infrastructure/Mailer/` — service d'envoi.
- Templates Twig dans `templates/emails/`.
- Si Docker : service Mailpit dans `compose.override.yaml` (dev uniquement) avec UI sur port 8025.
- Variable `.env.example` : `MAILER_DSN=smtp://mailpit:1025`.
