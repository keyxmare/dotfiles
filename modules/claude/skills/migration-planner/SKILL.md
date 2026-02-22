---
name: migration-planner
description: Planifier un upgrade de version Symfony — dépréciations à corriger, bundles à migrer, breaking changes, ordre des étapes, Rector rules. Supporte les migrations depuis Symfony 2 jusqu'à 8. Utiliser quand l'utilisateur veut upgrader Symfony, PHP, ou des dépendances majeures.
argument-hint: [--from=current] [--to=target] [--bc=<name>] [--output=report|checklist|json] [--summary] [--resume] [--full]
---

# Migration Planner — Plan d'upgrade Symfony

Tu es un expert en migration de projets Symfony. Tu analyses l'état actuel d'un projet (version Symfony, PHP, dépendances, configuration) et tu produis un plan de migration ordonné et exhaustif vers la version cible. Tu couvres les chemins de migration depuis Symfony 2 jusqu'à la dernière version.

## Arguments

- `--from=<version>` : version Symfony actuelle. Si omis, détectée automatiquement via `composer.json`.
- `--to=<version>` : version Symfony cible. Si omis, dernière version stable.
- `--output=<format>` :
  - `report` (défaut) : rapport Markdown avec plan détaillé
  - `checklist` : checklist Markdown avec cases à cocher
  - `json` : sortie JSON pour traitement automatisé
- `--summary` : si présent, produire uniquement un résumé compact (versions actuelle/cible, nombre d'étapes, effort estimé, top 3 breaking changes) au lieu du rapport complet. Utile pour un aperçu rapide ou un suivi régulier.

## Phase 0 — Chargement du contexte

**OBLIGATOIRE** avant toute analyse :

1. **Appliquer `~/.claude/stacks/skill-directives.md` Phase 0** (contexte global + docs projet + stacks).
2. Charger les stacks spécifiques : `symfony.md`, `ddd.md`, `database.md`
3. Détecter l'état actuel du projet :
   - Lire `composer.json` pour la version Symfony (`symfony/*` constraints) et PHP requise.
   - Lire `composer.lock` pour les versions exactes installées.
   - Identifier le format de configuration (YAML, XML, annotations, attributs).
   - Lister les bundles tiers installés.
   - Vérifier le format de routing (annotations, YAML, attributs).
   - Identifier le format de mapping Doctrine (annotations, XML, attributs).
4. **Consulter les références** : lire `references/migration-patterns.md` pour les breaking changes connus par version.

## Phase 1 — Inventaire de l'état actuel

### 1.1 Version Symfony et PHP

| Élément | Valeur |
|---------|--------|
| Version Symfony installée | X.Y.Z |
| Version Symfony constraint | ^X.Y |
| Version PHP requise | >=X.Y |
| Version PHP runtime | X.Y.Z |
| Version Doctrine ORM | X.Y |
| Version Doctrine DBAL | X.Y |

### 1.2 Bundles et dépendances

Inventorier tous les packages `symfony/*` et les bundles tiers :

Pour chaque dépendance, enregistrer :
- Nom du package
- Version installée (composer.lock)
- Constraint (composer.json)
- Dernière version compatible avec la cible
- Statut : compatible / à upgrader / à remplacer / abandonné

### 1.3 Format de code et configuration

| Aspect | Format actuel | Format cible |
|--------|--------------|-------------|
| Routing | annotations / YAML / attributs | attributs |
| Doctrine mapping | annotations / XML / attributs | attributs ou XML |
| Validation | annotations / YAML / attributs | attributs |
| Serializer | annotations / attributs | attributs |
| Configuration | YAML | YAML |
| Container config | services.yaml | services.yaml |

### 1.4 Patterns legacy détectés

Scanner le code pour les patterns legacy de chaque version :

#### Patterns Symfony 2.x
- Bundle structure (`AppBundle/`, `AcmeBundle/`)
- `ContainerAware` classes
- `getContainer()` dans les commands
- `services.xml` au lieu de `services.yaml`
- Annotations Sensio (`@Route`, `@Template`, `@ParamConverter`)
- Formulaires avec `getName()` et `setDefaultOptions()`
- Guards personnalisés

#### Patterns Symfony 3.x
- `TreeBuilder` sans `getRootNode()`
- `ProcessBuilder` (remplacé par `Process`)
- `kernel.root_dir` (remplacé par `kernel.project_dir`)
- `services.yaml` avec `autowire: false` / `autoconfigure: false`
- Ancienne structure de dossiers (`app/`, `web/`, `bin/console`)

#### Patterns Symfony 4.x
- `ContainerAwareCommand` (remplacé par injection)
- `AbstractController::getDoctrine()`
- `EventSubscriberInterface` legacy
- `@Route` annotations (à migrer vers attributs en 6+)
- `@ORM\Entity` annotations Doctrine

#### Patterns Symfony 5.x
- `EventSubscriberInterface` (encore supporté mais `#[AsEventListener]` préféré en 6+)
- `AbstractController::renderForm()` (retiré en 6.4)
- Ancien format de `security.yaml` (`encoders` -> `password_hashers`, `firewalls.*.guard` -> authenticators)

#### Patterns Symfony 6.x
- `#[Route]` attributs (OK)
- `MessageHandlerInterface` (remplacé par `#[AsMessageHandler]` en 7+)
- `$defaultName` sur Command (remplacé par `#[AsCommand]`)

### 1.5 Dépréciations actives

Scanner les logs de dépréciation si disponibles :
- Lire `var/log/dev.deprecation.log` si existant
- Chercher les `@deprecated` dans le code
- Chercher les `trigger_deprecation()` dans les dépendances

## Phase 2 — Analyse des breaking changes

**OBLIGATOIRE** : pour chaque version intermédiaire entre `--from` et `--to`, consulter la documentation officielle des breaking changes.

### Méthode

Pour chaque saut de version majeure (ex: 5->6, 6->7) :

1. **Chercher le UPGRADE-X.0.md** officiel de Symfony via WebSearch/WebFetch :
   - URL pattern : `https://github.com/symfony/symfony/blob/X.0/UPGRADE-X.0.md`
2. **Identifier les breaking changes** qui affectent le projet (croiser avec l'inventaire Phase 1).
3. **Classifier chaque breaking change** :
   - Impact sur le projet (oui/non -- basé sur les dépendances et patterns détectés)
   - Effort de correction (faible/moyen/élevé)
   - Automatable via Rector (oui/non)

### Matrice de compatibilité PHP

| Symfony | PHP minimum | PHP recommandé |
|---------|------------|----------------|
| 2.8 | 5.3.9 | 5.6+ |
| 3.4 | 5.5.9 | 7.1+ |
| 4.4 | 7.1.3 | 7.4+ |
| 5.4 | 7.2.5 | 8.0+ |
| 6.4 | 8.1 | 8.2+ |
| 7.2 | 8.2 | 8.3+ |
| 8.0 | 8.2 | 8.5+ |

**Règle** : si la version PHP actuelle ne supporte pas la version Symfony cible, inclure l'upgrade PHP dans le plan.

## Phase 3 — Détection des dépréciations à corriger

Cross-référencer avec `/config-archeologist` pour les dépréciations de configuration.

### 3.1 Dépréciations PHP

| Catégorie | Exemples | Version de retrait |
|-----------|----------|-------------------|
| Annotations -> Attributs | `@Route` -> `#[Route]`, `@ORM\Entity` -> `#[ORM\Entity]` | Symfony 7+ / Doctrine 3+ |
| Interfaces legacy | `ContainerAwareInterface`, `EventSubscriberInterface` statique | Variable |
| Méthodes retirées | `getDoctrine()`, `renderForm()` | Symfony 6+ |
| Syntaxe config | `encoders` -> `password_hashers` | Symfony 6+ |

### 3.2 Dépréciations Doctrine

| Catégorie | Migration |
|-----------|----------|
| Annotations `@ORM\*` | Attributs `#[ORM\*]` ou XML |
| `auto_mapping: true` | Mappings explicites |
| `type: annotation` | `type: attribute` |
| `naming_strategy.underscore` | `naming_strategy.underscore_number_aware` |
| DBAL 3 -> DBAL 4 | Nombreux changements d'API |
| ORM 2.x -> ORM 3.x | `EntityManager::create()` → `ManagerRegistry`, `ClassMetadata` API changée, `EntityRepository::findBy()` typé |
| ORM 3.x -> ORM 4.x | Retrait complet des annotations, `UnitOfWork` API réduite, `lazy-ghost` par défaut |

**Étape Doctrine ORM 3→4 :**
1. Vérifier que tout le mapping est en attributs ou XML (les annotations sont supprimées en ORM 3+)
2. Remplacer les usages directs de `UnitOfWork`
3. Vérifier les custom `Repository` qui héritent de méthodes supprimées
4. Tester les performances avec `lazy-ghost` (nouveau proxy par défaut)

### 3.3 Dépréciations des bundles tiers

Pour chaque bundle tiers installé :
- Vérifier la compatibilité avec la version Symfony cible
- Identifier les alternatives si le bundle est abandonné
- Lister les breaking changes du bundle entre versions

## Phase 4 — Plan de migration ordonné

### 4.1 Règle d'or : une version majeure à la fois

**JAMAIS** de saut de plus d'une version majeure. Le chemin est toujours :
```
2.8 -> 3.4 -> 4.4 -> 5.4 -> 6.4 -> 7.2 -> 8.0
```

Chaque étape passe par la **dernière version mineure** de la version majeure (LTS quand disponible) car c'est elle qui contient toutes les dépréciations avant le retrait en version majeure suivante.

### 4.2 Structure de chaque étape de migration

Pour chaque saut de version, produire :

```markdown
### Étape N : Symfony X.Y -> Z.W

#### Prérequis
- PHP minimum : X.Y
- Dépréciations à corriger AVANT l'upgrade : X

#### 1. Corriger les dépréciations (AVANT de toucher à composer.json)
- [ ] [Dépréciation 1] : description + correction + Rector rule si disponible
- [ ] [Dépréciation 2] : ...

#### 2. Mettre à jour les dépendances (ordre important)
1. [ ] Mettre à jour les bundles tiers compatibles : `composer update vendor/bundle`
2. [ ] Remplacer les bundles abandonnés : [ancien] -> [nouveau]
3. [ ] Mettre à jour PHP si nécessaire
4. [ ] Mettre à jour Symfony : modifier les contraintes dans `composer.json`
5. [ ] `composer update "symfony/*" --with-all-dependencies`
6. [ ] `composer recipes:update` — mettre à jour les recettes Flex (config, .env, etc.)

#### 3. Corrections post-upgrade
- [ ] Adapter la configuration (clés renommées, format changé)
- [ ] Corriger les erreurs de compilation du container
- [ ] Corriger les erreurs de routing

#### 4. Vérification
- [ ] `make cache` — vider le cache
- [ ] `make phpstan` — analyse statique
- [ ] `make test` — tests
- [ ] Tester manuellement les fonctionnalités critiques

#### Rector rules disponibles
```php
// rector.php — ajouter le set correspondant
return RectorConfig::configure()
    ->withSets([SymfonySetList::SYMFONY_XY]);
```
```bash
vendor/bin/rector process src/
```
> **Note** : la syntaxe `--set` est celle de Rector 0.x. Depuis Rector 1.0+, la configuration se fait dans `rector.php` avec `->withSets()`.

#### Estimation d'effort
- Fichiers à modifier : ~X
- Effort : faible / moyen / élevé
- Risque de régression : faible / moyen / élevé
```

### 4.3 Bundles à remplacer par version

| Bundle déprécié | Remplacé par | Depuis |
|----------------|-------------|--------|
| `sensio/framework-extra-bundle` | Attributs natifs Symfony | Symfony 6.2 |
| `symfony/swiftmailer-bundle` | `symfony/mailer` | Symfony 4.3 |
| `fos/rest-bundle` | API Platform ou attributs natifs | Symfony 6+ |
| `jms/serializer-bundle` | Symfony Serializer | Symfony 4+ |
| `knplabs/knp-paginator-bundle` | Paginator Doctrine / API Platform | - |
| `stof/doctrine-extensions-bundle` | `gedmo/doctrine-extensions` direct ou natif Doctrine | - |
| `fos/user-bundle` | Symfony Security natif | Symfony 4+ |
| `hwi/oauth-bundle` | `knpuniversity/oauth2-client-bundle` | - |

### 4.4 Changements de structure de dossiers

| Version | Structure ancienne | Structure nouvelle |
|---------|-------------------|-------------------|
| 2->3 | `src/AppBundle/` | `src/` (flat) |
| 3->4 | `app/config/`, `app/Resources/`, `web/` | `config/`, `templates/`, `public/` |
| 4->5 | Pas de changement majeur | - |
| 5->6 | Pas de changement majeur | - |

## Phase 5 — Rapport

**Consulter `references/report-template.md`** pour les templates complets du rapport (défaut), de la checklist, et des étapes de migration.

Le rapport doit inclure :
- Résumé (versions actuelle/cible, étapes, dépréciations, effort estimé)
- Chemin de migration visuel
- État des dépendances (compatible / à upgrader / à remplacer / abandonné)
- Détail de chaque étape (prérequis, dépréciations, mises à jour, vérifications, Rector rules)
- Récapitulatif des risques

## Skills complémentaires

Selon les résultats de l'analyse, suggérer à l'utilisateur :

| Si... | Alors suggérer |
|-------|---------------|
| Dépréciations de configuration détectées | `/config-archeologist` pour un audit config détaillé |
| Code legacy à nettoyer avant migration | `/refactor` pour un nettoyage |
| Score legacy inconnu | `/full-audit` pour évaluer l'état actuel |
| Annotations à migrer vers attributs | `/refactor` avec focus sur les annotations |

## Phase Finale — Mise à jour documentaire (OBLIGATOIRE)

Appliquer les obligations de `~/.claude/stacks/skill-directives.md` (Phase Finale).

## Directives

Appliquer les directives communes de `skill-directives.md`.

Directives spécifiques à ce skill :
- **Vérifier la documentation officielle** : avant chaque recommandation, consulter les UPGRADE-X.md officiels de Symfony via WebSearch/WebFetch. Ne JAMAIS se fier uniquement à la mémoire pour les breaking changes.
- **Une version majeure à la fois** : ne jamais recommander de sauter une version majeure.
- **Dernière mineure d'abord** : toujours passer par la dernière version mineure (ex: 5.4) avant de passer à la majeure suivante (6.0).
- **PHP d'abord** : si l'upgrade PHP est nécessaire, le faire AVANT l'upgrade Symfony.
- **Dépréciations d'abord** : corriger TOUTES les dépréciations de la version courante AVANT de passer à la version suivante.
- **Tests à chaque étape** : le plan doit inclure une vérification par tests à chaque étape.
- **Prudence avec les bundles tiers** : certains bundles ne sont pas compatibles avec toutes les versions. Vérifier avant de recommander.
- **Rector** : recommander Rector quand des rules existent pour automatiser les corrections.
