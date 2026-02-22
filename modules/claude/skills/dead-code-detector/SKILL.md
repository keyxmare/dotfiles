---
name: dead-code-detector
description: Détecter le code mort dans un projet Symfony/DDD — routes, services, event listeners, commands, handlers, DTOs, repositories et interfaces inutilisés. Utiliser quand l'utilisateur demande un nettoyage, une détection de code mort, un audit des services inutilisés, ou veut identifier ce qui peut être supprimé.
argument-hint: [scope] [--bc=<name>] [--type=all|routes|services|listeners|commands|handlers|dtos|repositories|interfaces|templates|translations|forms|voters|normalizers|types|filters|scheduler|enums|exceptions|migrations] [--output=report|json] [--summary] [--resume] [--full]
---

# Dead Code Detector — Symfony / DDD

Tu es un expert en analyse statique de projets Symfony. Tu scannes le code source pour identifier le code mort : tout ce qui est déclaré mais jamais utilisé. Tu produis un rapport actionnable avec des recommandations de suppression.

## Arguments

- `$ARGUMENTS` : scope optionnel (dossier, Bounded Context, ou fichier). Si vide, analyser tout `src/` et `config/`.
- `--type=<type>` : filtrer la catégorie de code mort à détecter :
  - `all` (défaut) : toutes les catégories
  - `routes` : routes non utilisées
  - `services` : services jamais injectés
  - `listeners` : event listeners/subscribers inutiles
  - `commands` : commandes console mortes
  - `handlers` : handlers Messenger sans message dispatché
  - `dtos` : DTOs jamais référencés
  - `repositories` : repositories jamais injectés
  - `interfaces` : interfaces sans implémentation ou jamais utilisées
  - `templates` : templates Twig non référencés
  - `translations` : clés de traduction non utilisées
  - `forms` : FormTypes jamais référencés
  - `voters` : Voters dont les attributs ne sont jamais vérifiés
  - `normalizers` : normalizers/denormalizers jamais utilisés
  - `types` : Doctrine custom types non référencés
  - `filters` : API Platform filters non associés à une ressource
  - `scheduler` : tâches planifiées avec messages non dispatchés
  - `enums` : enums PHP jamais référencées
  - `exceptions` : classes d'exception jamais throw ni catch
  - `migrations` : migrations Doctrine référençant des tables/colonnes supprimées
- `--output=<format>` :
  - `report` (défaut) : rapport Markdown structuré
  - `json` : sortie JSON pour traitement automatisé
- `--summary` : si présent, produire uniquement un résumé compact (métriques clés + top 5 problèmes) au lieu du rapport complet. Utile pour un aperçu rapide ou un suivi régulier.

## Phase 0 — Chargement du contexte

1. **Appliquer `skill-directives.md` Phase 0** (contexte global + docs projet + stacks).
2. Stacks spécifiques : `ddd.md`, `symfony.md`
3. Identifier la structure du projet :
   - Lister `src/` pour détecter les Bounded Contexts.
   - Lister `config/` pour les fichiers de configuration de services et routing.
   - Identifier le framework de test utilisé (PHPUnit, Pest, etc.).
   - Vérifier `composer.json` pour les dépendances clés (Messenger, API Platform, etc.).
4. **Consulter les références** : lire `references/detection-patterns.md` pour les commandes de scan et les patterns de détection.

## Phase 1 — Inventaire exhaustif

> **Scope** : ce skill analyse le **code PHP mort** (classes/methodes jamais referencees). Pour la **configuration morte** (declarations YAML orphelines), voir `/config-archeologist`. Les services orphelins sont a la frontiere : config-archeologist detecte les services declares en YAML dont la classe n'existe pas, dead-code-detector detecte les classes PHP qui ne sont injectees nulle part.

Avant de détecter le code mort, construire un **inventaire complet** de tout ce qui est déclaré dans le projet. L'inventaire est la base de l'analyse : on ne peut détecter du code mort que si on sait d'abord tout ce qui existe.

### 1.1 Inventaire des routes

Scanner toutes les sources de déclaration de routes :

**Attributs PHP (méthode principale en Symfony moderne) :**
- `#[Route(...)]` sur les méthodes de controllers
- `#[Route(...)]` au niveau classe (préfixe)

**Fichiers YAML/XML :**
- `config/routes.yaml` et `config/routes/*.yaml`
- `config/routes.xml` et `config/routes/*.xml`

**API Platform :**
- `#[ApiResource(...)]` sur les entités/DTOs (génère des routes automatiques)
- `#[Get]`, `#[GetCollection]`, `#[Post]`, `#[Put]`, `#[Patch]`, `#[Delete]`
- Custom operations avec `routeName`

Pour chaque route, enregistrer :
- Nom de la route
- Méthode HTTP
- Path
- Controller et action (classe::méthode)
- Fichier source et ligne

### 1.2 Inventaire des services

Scanner toutes les sources de déclaration de services :

**Autodiscovery (services.yaml) :**
- Blocs `App\` avec `resource` et `exclude`
- Services explicitement déclarés avec leur classe

**Attributs Symfony :**
- `#[AsService]` (Symfony 7+)
- `#[AutoconfigureTag]`
- `#[AsTaggedItem]`
- `#[Autoconfigure]`

**CompilerPass :**
- Scanner les `CompilerPass` dans les bundles pour les services enregistrés dynamiquement.

Pour chaque service, enregistrer :
- ID du service (FQCN ou alias)
- Classe d'implémentation
- Tags associés
- Public/private
- Fichier source

### 1.3 Inventaire des Event Listeners / Subscribers

**Event Subscribers :**
- Classes implémentant `EventSubscriberInterface`
- Méthode `getSubscribedEvents()` → liste des événements écoutés

**Event Listeners (attributs) :**
- `#[AsEventListener(event: '...')]`

**Event Listeners (YAML/XML) :**
- Tags `kernel.event_listener` dans `services.yaml`

**Doctrine Event Listeners :**
- `#[AsDoctrineListener(event: '...')]`
- Tags `doctrine.event_listener`

Pour chaque listener, enregistrer :
- Classe du listener
- Événements écoutés (noms)
- Méthode handler
- Type (Symfony, Doctrine, custom)
- Fichier source et ligne

### 1.4 Inventaire des commandes console

- Classes étendant `Symfony\Component\Console\Command\Command`
- Attribut `#[AsCommand(name: '...')]`
- Propriété `$defaultName` (legacy)
- Méthode `configure()` avec `setName()`

Pour chaque commande :
- Nom de la commande (ex: `app:import:products`)
- Classe
- Description
- Fichier source

### 1.5 Inventaire des Messenger Handlers

- Classes avec `#[AsMessageHandler]`
- Classes implémentant `MessageHandlerInterface` (legacy)
- Méthode `__invoke(MessageType $message)`

Pour chaque handler :
- Classe du handler
- Type du message traité (paramètre de `__invoke`)
- Bus associé si spécifié
- Fichier source

### 1.6 Inventaire des DTOs

- Classes dans `**/DTO/`, `**/Dto/`, `**/DataTransferObject/`
- Classes avec suffixe `Dto`, `DTO`, `Request`, `Response`, `Input`, `Output`, `Payload`
- Classes utilisées comme `input`/`output` dans `#[ApiResource]`

Pour chaque DTO :
- Classe FQCN
- Type (Request, Response, Input, Output, generic)
- Fichier source

### 1.7 Inventaire des Repositories

- Classes dans `**/Repository/`
- Classes implémentant `*RepositoryInterface`
- Classes étendant `ServiceEntityRepository` ou `EntityRepository`

Pour chaque repository :
- Classe FQCN
- Interface implémentée
- Entité associée
- Fichier source

### 1.8 Inventaire des interfaces

- Toutes les interfaces PHP (`interface ...`)
- Focus sur celles dans `Domain/` (ports)

Pour chaque interface :
- FQCN
- Couche (Domain, Application, Infrastructure)
- Fichier source

### 1.9 Inventaire des templates Twig

Scanner les fichiers de templates :

- Fichiers `*.html.twig` dans `templates/`
- Pour chaque template : chemin, taille, inclusions (`{% include %}`, `{% extends %}`, `{% embed %}`)

Pour chaque template, enregistrer :
- Chemin relatif
- Taille (lignes)
- Templates parents (via `{% extends %}`)
- Templates inclus (via `{% include %}`, `{% embed %}`)
- Blocs définis
- Fichier source

### 1.10 Inventaire des clés de traduction

Scanner les fichiers de traduction :

- Fichiers dans `translations/*.yaml` / `translations/*.xlf`
- Pour chaque clé : domaine, locale, fichier source

Pour chaque clé, enregistrer :
- Nom de la clé
- Domaine (messages, validators, etc.)
- Locale
- Fichier source

### 1.11 Inventaire des FormTypes

Scanner les classes de formulaires :

- Classes étendant `AbstractType` ou implémentant `FormTypeInterface`
- Pour chaque FormType : FQCN, `data_class`, fichier source

Pour chaque FormType, enregistrer :
- FQCN
- `data_class` configuré (si défini dans `configureOptions()`)
- Champs ajoutés (dans `buildForm()`)
- Fichier source

### 1.12 Inventaire des Voters

Scanner les classes de vote d'autorisation :

- Classes étendant `Voter` ou implémentant `VoterInterface`
- Pour chaque Voter : FQCN, attributs supportés (`supports()`), fichier source

Pour chaque Voter, enregistrer :
- FQCN
- Attributs/permissions supportés (dans `supports()` ou `ATTRIBUTES`)
- Subject type supporté
- Fichier source

### 1.13 Inventaire des Normalizers / Denormalizers

Scanner les classes de sérialisation :

- Classes implémentant `NormalizerInterface`, `DenormalizerInterface`
- Classes étendant `ObjectNormalizer`, `AbstractNormalizer`, `AbstractObjectNormalizer`

Pour chaque normalizer, enregistrer :
- FQCN
- Interface(s) implémentée(s)
- Type supporté (dans `supportsNormalization()` / `supportsDenormalization()`)
- Fichier source

### 1.14 Inventaire des Doctrine Custom Types

Scanner les types Doctrine personnalisés :

- Classes étendant `Doctrine\DBAL\Types\Type`
- Déclarations dans `config/packages/doctrine.yaml` sous `dbal.types`

Pour chaque type, enregistrer :
- FQCN
- Nom du type déclaré (ex: `uuid`, `money_amount`)
- Fichier source
- Déclaré dans la config (oui/non)

### 1.15 Inventaire des API Platform Filters

Scanner les filtres API Platform :

- Classes implémentant `FilterInterface` (API Platform)
- Attributs `#[ApiFilter(...)]` sur les entités/DTOs
- Déclarations dans `config/packages/api_platform.yaml`

Pour chaque filtre, enregistrer :
- FQCN
- Ressources associées (entité/DTO)
- Fichier source

### 1.16 Inventaire des Scheduler Tasks

Scanner les tâches planifiées (Symfony Scheduler, Symfony 7+) :

- Classes implémentant `ScheduleProviderInterface`
- Attributs `#[AsSchedule]`
- Messages référencés dans les `RecurringMessage::every()` ou `RecurringMessage::cron()`

Pour chaque tâche planifiée, enregistrer :
- Classe du provider
- Messages planifiés
- Cron/intervalle
- Fichier source

### 1.17 Inventaire des Enums PHP

Scanner les enums PHP :

- Enums déclarées avec `enum ... {`
- Enums backed (`enum ... : string`, `enum ... : int`)

Pour chaque enum, enregistrer :
- FQCN
- Type (unit, string-backed, int-backed)
- Cases déclarées
- Fichier source

### 1.18 Inventaire des classes d'Exception

Scanner les classes d'exception :

- Classes étendant `\Exception`, `\RuntimeException`, `\DomainException`, `\InvalidArgumentException`, etc.
- Classes dans `**/Exception/`

Pour chaque exception, enregistrer :
- FQCN
- Classe parente
- Couche (Domain, Application, Infrastructure)
- Fichier source

### 1.19 Inventaire des Migrations Doctrine

Scanner les migrations :

- Classes dans `migrations/` ou le namespace configuré dans `doctrine_migrations.yaml`
- Classes étendant `AbstractMigration`

Pour chaque migration, enregistrer :
- FQCN
- Nom de fichier (contient le timestamp)
- Tables/colonnes référencées dans `up()` et `down()`
- Fichier source

## Phase 2 — Analyse de l'utilisation

Pour chaque élément inventorié, vérifier s'il est **réellement utilisé** quelque part dans le code.

### 2.1 Routes mortes

Une route est considérée morte si son controller/action n'est **jamais appelée** :

**Vérifier :**
- La méthode du controller existe dans la classe référencée.
- La route n'est pas générée dynamiquement via `$router->generate('route_name')` ou `path('route_name')` dans Twig.
- La route n'est pas utilisée dans les tests (`$client->request('GET', '/...')`).
- La route n'est pas référencée dans du JavaScript (fetch, axios, etc.).

**Faux positifs à exclure :**
- Routes API Platform auto-générées (toujours considérées comme utilisées sauf preuve contraire).
- Routes de health check, debug, profiler (`_wdt`, `_profiler`).
- Routes de webhooks ou callbacks externes (documenter comme "usage externe").
- Routes avec annotation `@internal` ou commentaire explicite.

### 2.2 Services morts

Un service est considéré mort si :

**Vérifier dans toute la codebase :**
- Le FQCN n'apparaît dans **aucun** `use` statement d'un autre fichier.
- Le FQCN n'apparaît dans **aucun** type-hint de constructeur (injection).
- Le FQCN n'apparaît dans **aucune** config YAML/XML (`arguments`, `calls`, `factory`, `bind`).
- Le FQCN n'est pas utilisé comme `class` dans un service déclaré en YAML.
- Le service n'est pas taggé (`kernel.event_listener`, `messenger.message_handler`, etc.) — les services taggés sont utilisés implicitement par le framework.
- Le service n'est pas un controller (les controllers sont utilisés via routing).
- Le service n'est pas un CompilerPass ou un Bundle extension.
- Le service n'est pas injecté via `#[Target]` ou `#[Autowire]` attributs.

**Faux positifs à exclure :**
- Services autoconfigurés par tags (listeners, handlers, voters, etc.).
- Services utilisés comme factories.
- Services avec `public: true` exposés via le container.
- Entity Listeners Doctrine.
- Twig Extensions.
- Normalizers/Denormalizers.
- API Platform State Providers/Processors.
- PHPUnit DataProviders et fixtures.
- Services référencés dans les tests.

### 2.3 Event Listeners morts

Un listener est mort si l'événement qu'il écoute **n'est jamais dispatché** :

**Vérifier :**
- L'événement est dispatché via `$eventDispatcher->dispatch(new EventClass())`.
- L'événement est un événement Symfony natif (toujours dispatché par le framework : `kernel.request`, `kernel.response`, etc.) → **jamais mort**.
- L'événement est un événement Doctrine lifecycle (`prePersist`, `postUpdate`, etc.) → **jamais mort** si des entités de ce type existent.
- L'événement est un Domain Event dispatché via Messenger ou un event dispatcher custom.

**Cas spécial — Domain Events :**
- Scanner les entités/aggregates pour les `record()` ou `raise()` de domain events.
- Si un événement est enregistré (`raise(new OrderPlaced(...))`) mais son listener est dans un BC dont le subscriber n'est pas wired → listener potentiellement mort.

### 2.4 Commandes console mortes

Une commande est morte si :

**Vérifier :**
- La commande n'est pas référencée dans des crontabs, schedulers, ou scripts de déploiement.
- La commande n'est pas appelée dans d'autres commandes (`$this->getApplication()->find('...')` ou `new ArrayInput`).
- La commande n'est pas utilisée dans les tests.
- La commande n'est pas documentée dans le README ou un Makefile.
- La commande n'est pas dans le `config/packages/scheduler.yaml` (Symfony Scheduler).

**Prudence :** les commandes sont souvent utilisées en dehors du code PHP (scripts bash, CI, crontab). Signaler comme **suspicion** plutôt que **certitude**.

### 2.5 Handlers Messenger morts

Un handler est mort si le **message qu'il traite n'est jamais dispatché** :

**Vérifier :**
- Le message (Command/Query/Event) n'est instancié nulle part (`new MessageClass(...)`).
- Le message n'est pas dispatché via un bus (`$commandBus->dispatch(new ...)`, `$messageBus->dispatch(new ...)`).
- Le message n'est pas produit par un autre système (vérifier les transports : `config/packages/messenger.yaml` pour les transports externes AMQP, Redis, etc.).

**Attention :** si un transport externe est configuré (RabbitMQ, SQS, etc.), le message peut venir de l'extérieur. Signaler comme **usage externe possible**.

### 2.6 DTOs morts

Un DTO est mort si :

**Vérifier :**
- Le FQCN n'est jamais `use` dans un autre fichier.
- Le FQCN n'est pas utilisé comme `input`/`output` dans `#[ApiResource]`.
- Le FQCN n'est pas type-hinté dans un controller, handler, ou service.
- Le FQCN n'est pas utilisé dans un Serializer Normalizer/Denormalizer.
- Le FQCN n'est pas référencé dans un formulaire Symfony (FormType `data_class`).

### 2.7 Repositories morts

Un repository est mort si :

**Vérifier :**
- L'interface du repository n'est type-hintée dans aucun constructeur.
- L'implémentation concrète n'est injectée nulle part.
- Le repository n'est pas utilisé via le `EntityManager` (`$em->getRepository(Entity::class)`).
- Le repository n'est pas bindé dans `services.yaml`.
- Le repository n'est pas utilisé dans les tests ou les fixtures.

### 2.8 Interfaces mortes

Une interface est morte si :

**Vérifier :**
- Aucune classe ne l'implémente (`implements InterfaceName`).
- Ou elle est implémentée mais **jamais utilisée comme type-hint** (injection, paramètre, retour).
- L'interface n'est pas bindée dans `services.yaml` (`bind`, `alias`).

**Catégoriser :**
- Interface **orpheline** : aucune implémentation → à supprimer.
- Interface **fantôme** : implémentée mais jamais type-hintée → l'implémentation est probablement injectée directement (violation DDD si c'est un port Domain).

### 2.9 Templates Twig morts

Un template est mort si :

**Vérifier :**
- Le template n'est jamais référencé dans un appel `render()`, `renderView()`, ou `renderBlock()` dans les controllers.
- Le template n'est jamais inclus via `{% include %}`, `{% embed %}` dans un autre template.
- Le template n'est pas étendu via `{% extends %}` par un autre template.
- Le template n'est pas référencé dans la configuration Twig (`twig.yaml` → `paths`, form themes).
- Le template n'est pas utilisé dans un service (emails, PDF, etc.) via `$twig->render()`.

**Faux positifs à exclure :**
- Templates de base/layout (`base.html.twig`, `layout.html.twig`) — souvent étendus dynamiquement.
- Templates de formulaire (form themes).
- Templates d'email référencés dans des services.

### 2.10 Clés de traduction mortes

Une clé de traduction est morte si :

**Vérifier :**
- La clé n'est jamais utilisée via `trans()` dans le code PHP.
- La clé n'est jamais utilisée via `|trans` dans les templates Twig.
- La clé n'est jamais utilisée via `t()` (TranslatableMessage).
- La clé n'est pas référencée dans les contraintes de validation (`message` des `#[Assert\...]`).
- La clé n'est pas utilisée dans les FormTypes (`label`, `help`, `placeholder`).

**Prudence :** les clés peuvent être construites dynamiquement (`'status.' . $status`). Signaler comme **suspect** plutôt que **certain** si le domaine contient des clés avec des patterns similaires.

### 2.11 FormTypes morts

Un FormType est mort si :

**Vérifier :**
- Le FQCN n'est jamais référencé dans un appel `createForm()` ou `createFormBuilder()`.
- Le FQCN n'est jamais utilisé dans `$builder->add('field', FormTypeClass::class)`.
- Le FQCN n'est pas utilisé comme `entry_type` dans un `CollectionType`.
- Le FQCN n'est pas référencé dans la configuration ou d'autres FormTypes.

**Faux positifs à exclure :**
- FormTypes utilisés comme sous-types dans d'autres formulaires.
- FormTypes référencés dans les tests.

### 2.12 Voters morts

Un Voter est mort si :

**Vérifier :**
- Les attributs du Voter ne sont jamais utilisés dans `#[IsGranted('ATTRIBUTE')]`.
- Les attributs ne sont jamais vérifiés via `denyAccessUnlessGranted('ATTRIBUTE')`.
- Les attributs ne sont jamais testés via `is_granted('ATTRIBUTE')` dans Twig.
- Les attributs ne sont pas référencés dans `security.yaml` (access_control).
- Les attributs ne sont pas utilisés via `$security->isGranted('ATTRIBUTE')`.

**Attention :** les attributs peuvent être des constantes de classe. Scanner les constantes et leurs usages.

### 2.13 Enums mortes

Un enum est mort si :

**Vérifier :**
- Le FQCN n'est jamais `use` dans un autre fichier.
- Aucun accès à ses cases (`EnumClass::CaseName`, `EnumClass::from()`, `EnumClass::tryFrom()`, `EnumClass::cases()`).
- L'enum n'est pas utilisée comme type-hint (paramètre, retour, propriété).
- L'enum n'est pas référencée dans un mapping Doctrine (`type`, `enumType`).
- L'enum n'est pas utilisée dans des templates Twig.

**Faux positifs à exclure :**
- Enums utilisées dans des attributs PHP (`#[...]`).
- Enums utilisées dans des constantes de configuration.
- Enums référencées dans des tests.

### 2.14 Exceptions mortes

Une exception est morte si :

**Vérifier :**
- La classe n'est jamais `throw` dans le code (`throw new ExceptionClass`).
- La classe n'est jamais `catch` (`catch (ExceptionClass)`).
- La classe n'est pas référencée dans un `instanceof` check.
- La classe n'est pas utilisée dans les tests (`expectException(ExceptionClass::class)`).
- La classe n'est pas référencée dans un mapping d'erreur (error handler, exception listener).

**Catégoriser :**
- Exception **orpheline** : jamais throw ni catch → à supprimer.
- Exception **jamais throw** mais catch : incohérence — le catch ne sera jamais atteint.

### 2.15 Migrations mortes

Une migration est considérée morte si :

**Vérifier :**
- La migration référence des tables ou colonnes qui n'existent plus dans le schéma actuel.
- La migration a déjà été exécutée (présente dans `doctrine_migration_versions`).
- La migration est très ancienne et ne sert plus qu'à l'historique.

**Prudence :** les migrations sont un historique de schéma. Ne recommander la suppression que pour les migrations exécutées dont les tables référencées ont été supprimées depuis. Signaler comme **info** plutôt que comme code mort critique.

**Faux positifs à exclure :**
- Migrations non encore exécutées (en attente de déploiement).
- Migrations contenant des données de seed (inserts) encore pertinentes.

## Phase 3 — Classification et scoring

### 3.1 Niveaux de confiance

Chaque élément détecté comme mort reçoit un **niveau de confiance** :

| Niveau | Description | Action recommandée |
|--------|-------------|-------------------|
| `certain` (95%+) | Aucune référence trouvée nulle part | Supprimer |
| `probable` (75-95%) | Pas de référence directe mais usage indirect possible | Vérifier puis supprimer |
| `suspect` (50-75%) | Quelques indices d'inutilisation, mais usage externe possible | Investiguer |
| `faible` (<50%) | Usage possible via réflexion, config dynamique ou externe | Documenter uniquement |

### 3.2 Impact de la suppression

Évaluer l'impact de chaque suppression :

| Impact | Critère |
|--------|---------|
| `safe` | Aucune dépendance, suppression isolée |
| `cascade` | La suppression entraîne d'autres fichiers à supprimer (ex: service + interface + test) |
| `risky` | Dépendances incertaines, configuration dynamique |

### 3.3 Catégorie de code mort

| Catégorie | Gravité | Raison |
|-----------|---------|--------|
| Service jamais injecté | Haute | Charge le container inutilement |
| Handler sans message | Haute | Code métier orphelin, confusion |
| Route sans controller valide | Haute | Erreur 500 potentielle |
| Listener sur événement jamais dispatché | Moyenne | Code dormant, dette technique |
| DTO jamais référencé | Moyenne | Pollution du namespace |
| Commande console inutilisée | Basse | Impact faible, peut servir de script ponctuel |
| Interface sans implémentation | Moyenne | Abstraction prématurée |
| Repository inutilisé | Moyenne | Indique une entité potentiellement morte aussi |

## Phase 4 — Rapport

### Format du rapport

**Consulter `references/report-template.md`** pour le template complet du rapport Markdown et JSON.

Le rapport doit inclure :
- Résumé (fichiers analysés, éléments inventoriés, code mort détecté par niveau de confiance)
- Section par catégorie de code mort (services, routes, listeners, handlers, DTOs, repositories, interfaces, commandes, templates, traductions, FormTypes, Voters, Enums, Exceptions, Migrations)
- Chaque élément avec : confiance, impact, raison, action recommandée
- Cascades de suppression
- Métriques par Bounded Context
- Plan de nettoyage recommandé ordonné

## Phase 5 — Nettoyage assisté (optionnel)

**Seulement si l'utilisateur le demande explicitement.** Ne jamais supprimer de code automatiquement.

### Processus de nettoyage

1. **Présenter le rapport** et attendre la validation de l'utilisateur.
2. **Demander confirmation** pour chaque lot de suppression (certain/safe d'abord).
3. **Supprimer par lots** :
   - Supprimer le fichier PHP
   - Supprimer le test associé s'il existe
   - Retirer les entrées de configuration (`services.yaml`, routes, etc.)
   - Retirer les `use` statements orphelins dans d'autres fichiers
4. **Vérifier après chaque lot** :
   - Exécuter `make phpstan` pour détecter les erreurs de référence.
   - Exécuter `make test` pour s'assurer que rien n'est cassé.
   - Exécuter `make cs-fix` pour nettoyer les imports.
5. **Mettre à jour le container** : vider le cache (`make cache`).

### Commit

Proposer un commit par catégorie de nettoyage :
```
chore: remove unused services in Catalog context
chore: remove dead event listeners
chore: remove orphan interfaces and DTOs
```

## Skills complémentaires

Selon les résultats de l'analyse, suggérer à l'utilisateur :

| Si... | Alors suggérer |
|-------|---------------|
| Code mort identifié en volume | `/refactor` pour nettoyer le projet |
| Config morte détectée | `/config-archeologist` pour auditer la configuration |
| Services morts liés à du couplage | `/service-decoupler` pour restructurer |
| Score legacy inconnu | `/full-audit` pour un audit global |

## Phase Finale — Mise à jour documentaire (OBLIGATOIRE)

Appliquer les obligations de `~/.claude/stacks/skill-directives.md` (Phase Finale).

## Directives

Appliquer les directives communes de `skill-directives.md`.

Directives spécifiques à dead-code-detector :
- **Penser aux usages externes** : crontabs, scripts de déploiement, autres applications, API consommées par des clients.
- **Vérifier les tests** : un service utilisé uniquement dans les tests n'est pas forcément mort -- il peut tester une intégration. Mais un test qui teste un service mort est lui-même mort.
- **Attention à l'autowiring** : en Symfony, l'autodiscovery enregistre beaucoup de services automatiquement. Ce n'est pas parce qu'un service est dans le container qu'il est utilisé.
