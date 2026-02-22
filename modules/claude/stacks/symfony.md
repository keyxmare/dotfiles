# Stack Symfony

## PHP 8.5 / Symfony 8
- Toujours utiliser les dernières versions : **PHP 8.5** et **Symfony 8**.
- `declare(strict_types=1)` obligatoire.
- Suivre les standards PSR-12 et les conventions Symfony.
- Utiliser les fonctionnalités modernes de PHP 8.5 : match, named arguments, enums, readonly classes/properties, fibers, property hooks, asymmetric visibility, pipe operator.
- Utiliser les attributs (`#[Route]`, `#[ORM\Entity]`, `#[AsCommand]`, etc.) plutôt que les annotations.
- Doctrine ORM pour la persistence.
- Utiliser l'injection de dépendances via le constructeur (autowiring).
- Symfony Messenger pour le bus de commandes/queries (CQRS).
- Twig pour le templating côté serveur.
- Voir `~/.claude/stacks/ddd.md` pour l'architecture applicative (DDD strict, hexagonal, CQRS).

## Politique de versions — JAMAIS de downgrade

**INTERDIT** : downgrader une version de PHP, Symfony, ou de toute dépendance en dessous de ce que cette stack ou le `composer.json` du projet définit. Cette règle s'applique quelle que soit la version cible — si la stack dit PHP 8.5 et Symfony 8, c'est le plancher. Si un futur projet cible PHP 9 et Symfony 9, même règle.

Si un `composer require` échoue à cause d'une contrainte de version :

### Stratégie de résolution (dans l'ordre)

1. **Chercher une version compatible** : vérifier via WebSearch ou Packagist si une version plus récente du package supporte déjà les versions cibles du projet (branche `main`, release candidate, version dev).
2. **Utiliser la branche dev** : `composer require vendor/package:dev-main` avec `"minimum-stability": "dev"` limité au package concerné via `"prefer-stable": true`.
3. **Chercher un fork ou une alternative** : un fork communautaire compatible, ou un package alternatif qui fait la même chose.
4. **Ignorer la contrainte PHP si le code est compatible** : `composer require vendor/package --ignore-platform-req=php` quand le code fonctionne de fait avec la version PHP cible mais que le `composer.json` du package ne l'a pas encore déclaré.
5. **Patcher via composer-patches** : si le problème est juste une contrainte `composer.json` trop stricte dans le package, proposer un patch Composer (`cweagans/composer-patches`) qui relâche la contrainte.
6. **Demander à l'utilisateur** : expliquer le conflit, les options tentées, et laisser l'utilisateur décider. Ne JAMAIS downgrader silencieusement.

### Ce qui est INTERDIT
- Baisser la version de `php` dans le `composer.json` du projet.
- Baisser la version d'un composant Symfony ou de toute dépendance majeure en dessous de la version cible du projet.
- Ajouter un package qui force un downgrade transitif.
- Exécuter `composer update` avec des flags qui permettent un downgrade (`--prefer-lowest`).

### Signaux d'alerte
Si tu te retrouves à écrire une version **inférieure** à celle déjà définie dans le projet ou la stack, **STOP** et applique la stratégie ci-dessus. Exemples :
- Baisser `"php": ">=X.Y"` d'un cran
- Passer `"symfony/*": "^X.0"` à une majeure inférieure
- `composer require --with-all-dependencies` suivi d'un downgrade dans le output

## Makefile — Commandes attendues pour un projet Symfony

- `make install` : installer les dépendances (composer install, npm install)
- `make start` / `make stop` : démarrer/arrêter Docker Compose
- `make sh` : ouvrir un shell dans le container PHP
- `make test` : lancer les tests
- `make phpstan` : lancer l'analyse statique
- `make cs` / `make cs-fix` : vérifier/corriger le code style
- `make migration` : générer une migration Doctrine
- `make migrate` : exécuter les migrations
- `make cache` : vider le cache Symfony

## Base de données (MySQL/MariaDB)
- **IMPORTANT** : Ne JAMAIS exécuter de commandes qui modifient la base de données (migrations, seeds, requêtes INSERT/UPDATE/DELETE) sans demander confirmation explicite.
- Les commandes de lecture (SELECT, SHOW, DESCRIBE) sont autorisées.
- Utiliser les migrations Doctrine pour les changements de schéma.

## Tests
- PHPUnit / Pest pour les tests PHP.
- Toujours vérifier que les tests existants passent avant de proposer des modifications.
- Écrire des tests pour les nouvelles fonctionnalités quand c'est pertinent.

## Qualité
- PHPStan pour l'analyse statique. **Niveau 10** (max).
- Vérifier que le code passe PHPStan avant de considérer une tâche terminée.
