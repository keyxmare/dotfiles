# Référence — Modules optionnels

Chaque module est une unité autonome qui injecte code + config + tests + doc dans la structure existante.

## Tableau récapitulatif

| Module | Backend | Frontend | Docker | Tests |
|---|---|---|---|---|
| **auth** | SecurityBundle, User entity, JWT/session, firewall | Pages login/register/profil | — | Test auth flow |
| **messenger** | Config Messenger, transport AMQP/Doctrine, buses | — | Service RabbitMQ | Test des handlers |
| **mailer** | Config Mailer, transport DSN, templates Twig | — | Service Mailpit (dev) | Test d'envoi |
| **mercure** | MercureBundle, publisher service | Composable `useMercure()`, EventSource | Service Mercure | Test publication/réception |
| **file-upload** | Flysystem (local adapter), UploadController, validation | Composant upload drag & drop | Volume local | Test upload/validation |
| **i18n** | Symfony Translation, fichiers YAML | Nuxt: `@nuxtjs/i18n` / Vue: `vue-i18n` | — | Test des traductions |
| **monitoring** | HealthController (`GET /health`), Monolog JSON formatter | Page `/status` | Healthchecks renforcés | Test health endpoint |
| **scheduler** | Symfony Scheduler, RecurringMessage, schedules | — | Worker schedule dans compose | Test des schedules |
| **cache** | Symfony Cache, Redis adapter | — | Service Redis | Test cache hit/miss |
| **search** | Meilisearch PHP SDK, indexer service | Composant recherche, composable `useSearch()` | Service Meilisearch | Test indexation/recherche |
| **admin** | EasyAdmin, DashboardController, CRUD controllers | — | — | Test accès admin |

## Auto-activation par les features

Certaines features activent automatiquement un module. Le skill signale les activations à l'utilisateur.

| Feature détectée | Module activé |
|---|---|
| Authentification, login, register, OAuth | `auth` |
| Envoi d'email, notification email, email de bienvenue | `mailer` |
| Notification temps réel, live update, SSE | `mercure` |
| Upload de fichier, image, avatar, pièce jointe | `file-upload` |
| Multilingue, traduction, i18n | `i18n` |
| Recherche, search, filtrage avancé, full-text | `search` |
| Tâche planifiée, cron, relance, nettoyage automatique | `scheduler` |
| Administration, backoffice, gestion contenu | `admin` (nécessite `auth`) |

---

## Détail par module

Chaque module est documenté dans un fichier individuel. Ne charger que le module concerné :

| Module | Fichier |
|---|---|
| auth | `references/modules/auth.md` |
| messenger | `references/modules/messenger.md` |
| mailer | `references/modules/mailer.md` |
| mercure | `references/modules/mercure.md` |
| file-upload | `references/modules/file-upload.md` |
| i18n | `references/modules/i18n.md` |
| monitoring | `references/modules/monitoring.md` |
| scheduler | `references/modules/scheduler.md` |
| cache | `references/modules/cache.md` |
| search | `references/modules/search.md` |
| admin | `references/modules/admin.md` |

---

## Synergies inter-modules

Quand plusieurs modules sont activés ensemble, des intégrations supplémentaires doivent être générées :

| Modules combinés | Synergie | Fichiers impactés |
|---|---|---|
| `auth` + `mailer` | Email de bienvenue à l'inscription | `RegisterHandler` dispatch un event `UserRegistered` → listener envoie l'email via le service mailer |
| `auth` + `mercure` | Publication SSE des événements auth (login, logout) | `LoginController` publie sur le topic `auth/events` |
| `auth` + `file-upload` | Upload d'avatar sur le profil | `ProfileController` accepte multipart, `User` a un champ `avatarPath` |
| `auth` + `admin` | Accès admin protégé | Firewall `/admin` avec `ROLE_ADMIN`, champ `roles` sur `User` |
| `messenger` + `mailer` | Envoi d'emails asynchrone | Le mailer dispatch via `event.bus`, le consumer traite l'envoi |
| `messenger` + `mercure` | Publication SSE asynchrone | Les events publient sur Mercure via un listener Messenger |
| `messenger` + `search` | Indexation asynchrone | Les events d'entité (Created/Updated/Deleted) déclenchent la ré-indexation via un listener Messenger |
| `messenger` + `scheduler` | Tâches planifiées via Messenger | Le scheduler utilise le transport Messenger pour dispatcher les `RecurringMessage` |
| `cache` + `search` | Cache des résultats de recherche | Le `SearchIndexer` cache les résultats fréquents via le pool Redis |
| `monitoring` + tout module Docker | Healthcheck étendu | `HealthController` vérifie chaque service Docker activé (RabbitMQ, Mercure, Mailpit, Redis, Meilisearch, BDD) |

### Comportement attendu

Quand une synergie est détectée (les deux modules sont activés) :
1. Signaler la synergie à l'utilisateur : `"auth + mailer détectés → email de bienvenue sera généré"`.
2. Générer le code d'intégration en plus des fichiers individuels de chaque module.
3. Ajouter les tests de l'intégration (ex: test que `UserRegistered` déclenche l'envoi d'email).
