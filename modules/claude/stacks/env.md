# Conventions .env

## Structure Symfony

### Fichiers
- `.env` : valeurs par défaut, committées dans git. Pas de secrets.
- `.env.local` : surcharges locales, **JAMAIS committées** (dans .gitignore).
- `.env.test` : surcharges pour l'environnement de test, committées.
- `.env.prod` : non utilisé. En production, utiliser les variables d'environnement système ou Symfony Secrets.

### Nommage des variables
- UPPER_SNAKE_CASE.
- Préfixer par le service ou le contexte : `DATABASE_URL`, `MAILER_DSN`, `REDIS_URL`.
- Variables custom préfixées par `APP_` : `APP_LOCALE`, `APP_DEFAULT_CURRENCY`.

### Règles
- **JAMAIS** de secrets en clair dans `.env` : mots de passe, tokens, clés API.
- Utiliser Symfony Secrets (`secrets:set`) pour les valeurs sensibles en production.
- Documenter chaque variable dans `.env` avec un commentaire.
- Fournir des valeurs par défaut fonctionnelles pour le développement dans `.env`.
- Le fichier `.env` sert de documentation : il liste TOUTES les variables nécessaires.

### Exemple
```dotenv
###> app ###
APP_ENV=dev
APP_SECRET=change-me-in-local
APP_LOCALE=fr
###< app ###

###> doctrine ###
DATABASE_URL="mysql://app:!ChangeMe!@database:3306/app?charset=utf8mb4"
###< doctrine ###

###> redis ###
REDIS_URL=redis://redis:6379
###< redis ###
```

### Docker Compose
- Les variables d'environnement Docker sont définies dans `compose.yaml`, pas dans un fichier `.env` Docker séparé.
- Utiliser `${VARIABLE:-default}` pour les valeurs par défaut dans compose.yaml.
