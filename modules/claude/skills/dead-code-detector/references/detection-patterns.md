# Patterns de détection de code mort — Symfony

## Commandes de scan rapide

### Inventaire des routes

```bash
# Routes déclarées par attributs PHP
grep -rn "#\[Route" src/ --include="*.php" 2>/dev/null

# Routes API Platform
grep -rn "#\[ApiResource\|#\[Get\|#\[GetCollection\|#\[Post\|#\[Put\|#\[Patch\|#\[Delete" src/ --include="*.php" 2>/dev/null

# Routes YAML
find config/routes* -name "*.yaml" -o -name "*.yml" 2>/dev/null | xargs cat 2>/dev/null

# Lister les routes compilées (nécessite le container Symfony)
# php bin/console debug:router --format=json
```

### Inventaire des services

```bash
# Services déclarés dans services.yaml
grep -rn "class:" config/services.yaml config/services/ --include="*.yaml" 2>/dev/null

# Services avec attribut #[AsService]
grep -rn "#\[AsService" src/ --include="*.php" 2>/dev/null

# Blocs autodiscovery
grep -rn "resource:" config/services.yaml config/services/ --include="*.yaml" 2>/dev/null

# Lister les services compilés (nécessite le container Symfony)
# php bin/console debug:container --format=json
```

### Inventaire des Event Listeners

```bash
# Event Subscribers
grep -rn "implements EventSubscriberInterface" src/ --include="*.php" 2>/dev/null

# Event Listeners par attribut
grep -rn "#\[AsEventListener" src/ --include="*.php" 2>/dev/null

# Event Listeners Doctrine
grep -rn "#\[AsDoctrineListener" src/ --include="*.php" 2>/dev/null

# Event Listeners par tag YAML
grep -rn "kernel.event_listener\|doctrine.event_listener" config/services.yaml config/services/ --include="*.yaml" 2>/dev/null

# Extraire les événements écoutés
grep -rn "getSubscribedEvents" src/ --include="*.php" -A 20 2>/dev/null
```

### Inventaire des commandes console

```bash
# Commandes par attribut
grep -rn "#\[AsCommand" src/ --include="*.php" 2>/dev/null

# Commandes par héritage
grep -rn "extends Command" src/ --include="*.php" 2>/dev/null

# Commandes legacy avec $defaultName
grep -rn "defaultName" src/ --include="*.php" 2>/dev/null
```

### Inventaire des Messenger Handlers

```bash
# Handlers par attribut
grep -rn "#\[AsMessageHandler" src/ --include="*.php" 2>/dev/null

# Handlers par interface (legacy)
grep -rn "implements MessageHandlerInterface" src/ --include="*.php" 2>/dev/null

# Type du message traité (paramètre de __invoke)
grep -rn "public function __invoke" src/ --include="*.php" 2>/dev/null
```

### Inventaire des DTOs

```bash
# Classes dans les dossiers DTO
find src/ -path "*/DTO/*" -o -path "*/Dto/*" -o -path "*/DataTransferObject/*" -name "*.php" 2>/dev/null

# Classes avec suffixes DTO communs
grep -rln "class.*\(Dto\|DTO\|Request\|Response\|Input\|Output\|Payload\)" src/ --include="*.php" 2>/dev/null
```

### Inventaire des Repositories

```bash
# Repositories par dossier
find src/ -path "*/Repository/*" -name "*.php" 2>/dev/null

# Repositories par héritage
grep -rn "extends ServiceEntityRepository\|extends EntityRepository" src/ --include="*.php" 2>/dev/null

# Interfaces de repository
grep -rn "interface.*RepositoryInterface\|interface.*Repository" src/ --include="*.php" 2>/dev/null
```

### Inventaire des interfaces

```bash
# Toutes les interfaces
grep -rn "^interface \|^readonly interface " src/ --include="*.php" 2>/dev/null

# Interfaces dans le Domain (ports)
find src/ -path "*/Domain/*" -name "*Interface.php" 2>/dev/null
```

### Inventaire des Normalizers / Denormalizers

```bash
# Normalizers par interface
grep -rn "implements NormalizerInterface\|implements DenormalizerInterface" src/ --include="*.php" 2>/dev/null

# Normalizers par héritage
grep -rn "extends ObjectNormalizer\|extends AbstractNormalizer\|extends AbstractObjectNormalizer" src/ --include="*.php" 2>/dev/null
```

### Inventaire des Doctrine Custom Types

```bash
# Types par héritage
grep -rn "extends Type" src/ --include="*.php" 2>/dev/null | grep -i "doctrine\|dbal"

# Types déclarés en config
grep -rn "types:" config/packages/doctrine* --include="*.yaml" -A 10 2>/dev/null
```

### Inventaire des API Platform Filters

```bash
# Filtres custom
grep -rn "implements FilterInterface" src/ --include="*.php" 2>/dev/null

# Attributs #[ApiFilter]
grep -rn "#\[ApiFilter" src/ --include="*.php" 2>/dev/null

# Filtres déclarés en config
grep -rn "filters:" config/packages/api_platform* --include="*.yaml" 2>/dev/null
```

### Inventaire des Scheduler Tasks

```bash
# Schedule providers
grep -rn "implements ScheduleProviderInterface\|#\[AsSchedule" src/ --include="*.php" 2>/dev/null

# Messages planifiés
grep -rn "RecurringMessage::every\|RecurringMessage::cron" src/ --include="*.php" 2>/dev/null
```

## Vérification d'usage

### Vérifier si un FQCN est utilisé

```bash
# Remplacer FQCN par le nom complet de la classe
FQCN="App\\Catalog\\Application\\Service\\PriceCalculator"
SHORT_NAME="PriceCalculator"

# Chercher les use statements
grep -rn "use ${FQCN}" src/ --include="*.php" 2>/dev/null

# Chercher les injections par type-hint (nom court)
grep -rn "${SHORT_NAME}" src/ --include="*.php" 2>/dev/null | grep -v "class ${SHORT_NAME}" | grep -v "^Binary"

# Chercher dans la configuration
grep -rn "${FQCN}" config/ --include="*.yaml" --include="*.xml" 2>/dev/null

# Chercher dans les tests
grep -rn "${SHORT_NAME}" tests/ --include="*.php" 2>/dev/null
```

### Vérifier si un événement est dispatché

```bash
EVENT_CLASS="OrderPlacedEvent"

# Dispatch direct
grep -rn "dispatch(new ${EVENT_CLASS}" src/ --include="*.php" 2>/dev/null

# Dispatch via variable
grep -rn "new ${EVENT_CLASS}" src/ --include="*.php" 2>/dev/null

# Domain Event raise/record
grep -rn "raise(new ${EVENT_CLASS}\|record(new ${EVENT_CLASS}\|recordEvent(new ${EVENT_CLASS}" src/ --include="*.php" 2>/dev/null
```

### Vérifier si une route est référencée

```bash
ROUTE_NAME="app_catalog_product_show"

# Dans les controllers/services (génération d'URL)
grep -rn "'${ROUTE_NAME}'\|\"${ROUTE_NAME}\"" src/ --include="*.php" 2>/dev/null

# Dans Twig (path/url)
grep -rn "'${ROUTE_NAME}'\|\"${ROUTE_NAME}\"" templates/ --include="*.twig" 2>/dev/null

# Dans JavaScript
grep -rn "'${ROUTE_NAME}'\|\"${ROUTE_NAME}\"" assets/ --include="*.js" --include="*.ts" --include="*.vue" 2>/dev/null

# Dans les tests
grep -rn "'${ROUTE_NAME}'\|\"${ROUTE_NAME}\"" tests/ --include="*.php" 2>/dev/null
```

### Vérifier si une commande est utilisée en dehors du code

```bash
COMMAND_NAME="app:import:products"

# Dans le Makefile
grep -rn "${COMMAND_NAME}" Makefile 2>/dev/null

# Dans les scripts
grep -rn "${COMMAND_NAME}" scripts/ bin/ 2>/dev/null

# Dans Docker / CI
grep -rn "${COMMAND_NAME}" docker-compose.yml .github/ .gitlab-ci.yml Dockerfile 2>/dev/null

# Dans le Scheduler
grep -rn "${COMMAND_NAME}" config/packages/scheduler* 2>/dev/null

# Dans le crontab du container
grep -rn "${COMMAND_NAME}" docker/ infrastructure/ 2>/dev/null
```

### Vérifier si un message Messenger est dispatché

```bash
MESSAGE_CLASS="SendOrderConfirmation"

# Instanciation et dispatch
grep -rn "new ${MESSAGE_CLASS}" src/ --include="*.php" 2>/dev/null

# Import du message
grep -rn "use.*${MESSAGE_CLASS}" src/ --include="*.php" 2>/dev/null

# Transports externes (le message peut venir de dehors)
grep -rn "${MESSAGE_CLASS}" config/packages/messenger* 2>/dev/null
```

## Patterns de faux positifs

### Services qui semblent morts mais ne le sont pas

| Pattern | Raison |
|---------|--------|
| Classes avec tag `controller.service_arguments` | Controllers — utilisés par le routing |
| Classes avec tag `kernel.event_subscriber` | Subscribers — autoconfigurés |
| Classes avec tag `messenger.message_handler` | Handlers Messenger — autoconfigurés |
| Classes avec tag `security.voter` | Voters — autoconfigurés |
| Classes avec tag `twig.extension` | Extensions Twig — autoconfigurées |
| Classes avec tag `serializer.normalizer` | Normalizers — autoconfigurés |
| Classes avec tag `serializer.denormalizer` | Denormalizers — autoconfigurés |
| Classes avec tag `doctrine.type` | Custom Doctrine Types — déclarés en config |
| Classes avec `#[AsSchedule]` | Schedule Providers — autoconfigurés |
| Classes dans `DataFixtures/` | Fixtures — utilisées par `doctrine:fixtures:load` |
| Classes dans `Migrations/` | Migrations — utilisées par `doctrine:migrations:migrate` |
| Classes `*CompilerPass` | CompilerPass — chargées par le bundle |
| Classes `*Extension` dans `DependencyInjection/` | Extension de bundle — chargées automatiquement |
| Classes `*Bundle` | Bundle — déclaré dans `config/bundles.php` |
| Classes avec `#[ApiResource]` | Ressources API Platform — auto-routées |
| State Providers/Processors API Platform | Autoconfigurés via tag |
| API Platform Filters avec `#[ApiFilter]` | Autoconfigurés via attribut |
| Kernel.php | Bootstrap Symfony |

### Événements natifs Symfony (jamais morts)

```
kernel.request
kernel.controller
kernel.controller_arguments
kernel.view
kernel.response
kernel.finish_request
kernel.terminate
kernel.exception
security.interactive_login
security.authentication.success
security.authentication.failure
console.command
console.terminate
console.error
```

### Événements natifs Doctrine (jamais morts si entité active)

```
prePersist
postPersist
preUpdate
postUpdate
preRemove
postRemove
preFlush
onFlush
postFlush
loadClassMetadata
onClear
```

## Heuristiques de classification

### Confiance "certain" (95%+)

- Aucun `use` du FQCN dans tout `src/`, `tests/`, `config/`
- Aucune mention du nom court de la classe
- Pas de tag Symfony autoconfigurable
- Pas dans une couche framework (Migrations, Fixtures, Kernel)

### Confiance "probable" (75-95%)

- Le FQCN n'est référencé que dans son propre fichier et son test
- Le test est le seul consommateur
- Pas de tag mais autodiscovery actif (le service existe dans le container mais n'est jamais injecté)

### Confiance "suspect" (50-75%)

- Le FQCN est mentionné dans un commentaire ou un fichier de config non standard
- Service avec `public: true` (pourrait être fetch via le container)
- Commande console (usage externe possible)

### Confiance "faible" (<50%)

- Classe utilisée via réflexion (`ReflectionClass`)
- Classe chargée dynamiquement (`$container->get('service_id')`)
- Handler Messenger avec transport externe (messages venant d'autres systèmes)
- Route de webhook (appelée par des systèmes externes)

## Détection de cascades

### Quand un service est mort

```
ServiceMort
  └── Si ServiceMortInterface existe et n'a qu'une implémentation → interface morte aussi
      └── Si ServiceMortTest existe → test mort aussi
          └── Si ServiceMortFactory existe et ne produit que ServiceMort → factory morte aussi
```

### Quand un handler est mort

```
HandlerMort
  └── Si le Message traité n'est dispatché nulle part → Message mort aussi
      └── Si MessageTest existe → test mort aussi
```

### Quand une entité est potentiellement morte

Si **tous** les éléments suivants sont morts :
- Repository de l'entité
- DTOs associés
- Handlers CRUD associés

Alors l'entité elle-même est **suspecte** (mais ne pas la déclarer morte — impact trop important).

## Templates Twig morts

### Inventaire
```bash
# Lister tous les templates Twig
find templates/ -name "*.html.twig" -type f
```

### Détection d'utilisation
```bash
# Chercher les appels render() avec le nom du template
grep -r "render(" src/ --include="*.php" | grep "template_name"

# Chercher les includes/extends/embeds Twig
grep -r "{% include\|{% extends\|{% embed" templates/ --include="*.twig"

# Chercher les références dans la config Twig
grep -r "twig" config/ --include="*.yaml" | grep "template\|path\|form_theme"
```

## Clés de traduction mortes

### Inventaire
```bash
# Lister toutes les clés de traduction YAML
grep -r "^[a-zA-Z]" translations/ --include="*.yaml"

# Lister les clés XLF
grep -r "<source>" translations/ --include="*.xlf"
```

### Détection d'utilisation
```bash
# Chercher trans() dans le code PHP
grep -rn "->trans(" src/ --include="*.php"
grep -rn "t(" src/ --include="*.php"

# Chercher |trans dans Twig
grep -rn "|trans" templates/ --include="*.twig"

# Chercher dans les contraintes de validation
grep -rn "message:" src/ --include="*.php"
```

## FormTypes morts

### Inventaire
```bash
# Trouver les classes FormType
grep -rn "extends AbstractType\|implements FormTypeInterface" src/ --include="*.php"
```

### Détection d'utilisation
```bash
# Chercher createForm()
grep -rn "createForm(" src/ --include="*.php"

# Chercher les types dans $builder->add()
grep -rn "\->add(" src/ --include="*.php" | grep "Type::class"

# Chercher les entry_type dans CollectionType
grep -rn "entry_type" src/ --include="*.php"
```

## Voters morts

### Inventaire
```bash
# Trouver les classes Voter
grep -rn "extends Voter\|extends AbstractVoter\|implements VoterInterface" src/ --include="*.php"

# Extraire les attributs supportés
grep -rn "supports\|ATTRIBUTES\|protected const" src/ --include="*.php" | grep -i "voter"
```

### Détection d'utilisation
```bash
# Chercher IsGranted
grep -rn "IsGranted\|isGranted\|is_granted\|denyAccessUnlessGranted" src/ templates/ --include="*.php" --include="*.twig"

# Chercher dans security.yaml
grep -rn "access_control" config/ --include="*.yaml"
```

## Enums PHP mortes

### Inventaire
```bash
# Toutes les enums PHP
grep -rn "^enum " src/ --include="*.php" 2>/dev/null

# Enums backed (string ou int)
grep -rn "^enum.*: string\|^enum.*: int" src/ --include="*.php" 2>/dev/null
```

### Détection d'utilisation
```bash
ENUM_FQCN="App\\Catalog\\Domain\\Enum\\ProductStatus"
ENUM_SHORT="ProductStatus"

# Chercher les use statements
grep -rn "use ${ENUM_FQCN}" src/ tests/ --include="*.php" 2>/dev/null

# Chercher les accès aux cases (EnumClass::CaseName)
grep -rn "${ENUM_SHORT}::" src/ tests/ --include="*.php" 2>/dev/null | grep -v "^.*enum ${ENUM_SHORT}"

# Chercher les appels ::from(), ::tryFrom(), ::cases()
grep -rn "${ENUM_SHORT}::from\|${ENUM_SHORT}::tryFrom\|${ENUM_SHORT}::cases" src/ tests/ --include="*.php" 2>/dev/null

# Chercher l'usage comme type-hint
grep -rn "${ENUM_SHORT} \$\|: ${ENUM_SHORT}\|<${ENUM_SHORT}>" src/ --include="*.php" 2>/dev/null | grep -v "^.*enum ${ENUM_SHORT}"

# Chercher dans le mapping Doctrine (enumType)
grep -rn "enumType.*${ENUM_SHORT}\|type.*${ENUM_SHORT}" src/ --include="*.php" 2>/dev/null

# Chercher dans les templates Twig
grep -rn "${ENUM_SHORT}" templates/ --include="*.twig" 2>/dev/null

# Chercher dans la configuration
grep -rn "${ENUM_SHORT}\|${ENUM_FQCN}" config/ --include="*.yaml" --include="*.xml" 2>/dev/null
```

### Faux positifs
- Enums utilisees dans des attributs PHP (`#[...]`) — scanner les attributs PHP8 qui referencent l'enum
- Enums utilisees dans des constantes de configuration ou des paramètres de container
- Enums referencees uniquement dans des tests — le test peut etre valide meme si l'enum n'est pas utilisee dans src/

## Exceptions mortes

### Inventaire
```bash
# Classes étendant Exception ou ses sous-classes courantes
grep -rn "class.*extends.*Exception\|class.*extends.*RuntimeException\|class.*extends.*DomainException\|class.*extends.*InvalidArgumentException" src/ --include="*.php" 2>/dev/null

# Classes dans les dossiers Exception/
find src/ -path "*/Exception/*" -name "*.php" -type f 2>/dev/null
```

### Détection d'utilisation
```bash
EXCEPTION_SHORT="ProductNotFoundException"

# Chercher throw new
grep -rn "throw new ${EXCEPTION_SHORT}" src/ --include="*.php" 2>/dev/null

# Chercher catch
grep -rn "catch (${EXCEPTION_SHORT}\|catch (.*|${EXCEPTION_SHORT}" src/ --include="*.php" 2>/dev/null

# Chercher instanceof
grep -rn "instanceof ${EXCEPTION_SHORT}" src/ --include="*.php" 2>/dev/null

# Chercher dans les tests (expectException)
grep -rn "expectException(${EXCEPTION_SHORT}::class)\|expectException(.*\\\\${EXCEPTION_SHORT}" tests/ --include="*.php" 2>/dev/null

# Chercher dans les error handlers / exception listeners
grep -rn "${EXCEPTION_SHORT}" src/ --include="*.php" 2>/dev/null | grep -i "handler\|listener\|mapper\|normalizer"
```

### Catégorisation
| Catégorie | Critère | Action |
|-----------|---------|--------|
| Orpheline | Jamais `throw` ni `catch` nulle part | Supprimer |
| Jamais throw mais catch | `catch` present mais aucun `throw new` correspondant | Incohérence — le catch est du code mort, vérifier si le throw a été supprimé par erreur |

## Migrations Doctrine mortes

### Inventaire
```bash
# Fichiers de migration
find migrations/ -name "*.php" -type f 2>/dev/null

# Ou dans le namespace configure (doctrine_migrations.yaml)
grep -rn "dir_name\|migrations_paths" config/packages/doctrine_migrations* --include="*.yaml" 2>/dev/null

# Classes étendant AbstractMigration
grep -rn "extends AbstractMigration" migrations/ --include="*.php" 2>/dev/null
```

### Tables et colonnes référencées
```bash
# Extraire les tables référencées dans up() et down()
grep -rn "createTable\|dropTable\|addColumn\|dropColumn\|renameTable\|renameColumn\|addIndex\|dropIndex\|addForeignKey\|dropForeignKey" migrations/ --include="*.php" 2>/dev/null

# Extraire les noms de table dans les appels SQL bruts
grep -rn "->addSql(" migrations/ --include="*.php" 2>/dev/null
```

### Vérification de pertinence
```bash
# Comparer avec le schema actuel via le mapping Doctrine
# (necessite le container Symfony)
# php bin/console doctrine:schema:validate
# php bin/console doctrine:mapping:info

# Identifier les migrations deja executees
# php bin/console doctrine:migrations:status
# php bin/console doctrine:migrations:list
```

### Prudence
Les migrations sont un **historique de schema**. Elles ne sont pas du code mort au sens classique.

- Signaler comme **info** et non comme code mort critique
- Ne recommander la suppression que pour les migrations **deja executees** ET dont les tables referencees ont ete **supprimees depuis**
- **Exclure** les migrations non encore executees (en attente de deploiement)
- **Exclure** les migrations contenant des seeds (INSERT) encore pertinents
