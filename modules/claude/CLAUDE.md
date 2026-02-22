# Instructions globales

## Personnalité
- Lire `~/.claude/SOUL.md` pour le comportement, le ton et l'esprit critique attendus.

## Langue
- Toujours répondre en français.
- Les noms de variables, fonctions et commentaires dans le code restent en anglais.

## Stacks disponibles
Les fichiers de stack sont dans `~/.claude/stacks/`.
- **Ne PAS charger toutes les stacks en début de session.**
- Charger une stack UNIQUEMENT quand la tâche en cours touche son domaine.
- Exemples : toucher un controller API → charger `api-platform.md`. Écrire un test → charger `testing.md`. Modifier docker-compose → charger `docker.md`.
- Les skills chargent leurs propres stacks via leur Phase 0 (voir `skill-directives.md`).

### Index des stacks
- `symfony.md` — PHP 8.5, Symfony 8, Doctrine, PHPStan, PHPUnit
- `ddd.md` — DDD strict, architecture hexagonale, CQRS, Bounded Contexts
- `vuejs.md` — Vue 3, Composition API, TypeScript
- `docker.md` — Docker, Docker Compose
- `git.md` — Conventional commits, branches, PRs
- `testing.md` — Stratégie de tests par couche DDD
- `security.md` — OWASP, bonnes pratiques sécurité Symfony
- `api-platform.md` — API Platform, REST, DTOs, State Providers/Processors
- `logging.md` — Monolog, logs structurés, niveaux par couche DDD
- `performance.md` — Caching (Redis, HTTP, Doctrine), optimisation queries, profiling
- `env.md` — Conventions .env Symfony, secrets, Docker
- `messenger.md` — Messenger, CQRS async, Domain Events, retries, dead letter
- `database.md` — Nommage tables/colonnes, indexation, migrations non-destructives
- `error-handling.md` — Exceptions par couche DDD, mapping HTTP, format d'erreur API
- `definition-of-done.md` — Checklist qualité avant de clore une tâche
- `project-template.md` — Template d'initialisation de projet
- `project-docs.md` — Gestion documentaire (MEMORY, FEATURES, TASKS, Makefile)

## Gestion documentaire des projets
- Charger `~/.claude/stacks/project-docs.md` pour les obligations MEMORY, FEATURES, TASKS et Makefile.
- **Relire MEMORY.md, FEATURES.md, TASKS.md en début de chaque session.**
- **Mettre à jour MEMORY.md avant chaque fin de réponse.** Si rien n'a changé, ne pas mettre à jour.

## Vérification documentaire
- **OBLIGATOIRE** : Avant d'écrire du code qui utilise une API, un framework ou une librairie, **vérifier la documentation officielle** via WebSearch ou WebFetch pour s'assurer que la syntaxe est celle de la version en cours.
- Ne JAMAIS se fier uniquement à sa mémoire pour les APIs de frameworks.
- En cas de doute sur la compatibilité d'une API, **chercher d'abord, coder ensuite**.

## Skills
- Les skills (`~/.claude/skills/`) sont gérés par `~/.claude/stacks/skill-directives.md` — source de vérité pour les obligations communes, le grading, le workflow inter-skills, et le budget de contexte.
- **Tout skill DOIT** lire et appliquer `skill-directives.md` en Phase 0.

## Analyse d'impact
- **OBLIGATOIRE** : Avant chaque ajout, modification ou suppression, identifier **tous les endroits impactés** par le changement et les mettre à jour dans le même lot.
- Un changement n'est pas terminé tant que ses effets de bord ne sont pas propagés. Exemples concrets :
  - Ajouter une option CLI → mettre à jour l'argument-hint, la description, la doc, les exemples.
  - Ajouter/supprimer une section numérotée → renuméroter les sections suivantes.
  - Renommer une méthode/classe → mettre à jour les imports, les tests, la doc, la config.
  - Ajouter un champ à un DTO/entité → mettre à jour le mapping, les factories de test, la sérialisation.
  - Supprimer une route/endpoint → mettre à jour les tests fonctionnels, la doc API, le frontend.
  - Modifier une signature de fonction → mettre à jour tous les appelants.
- **Méthode** : avant d'éditer, se demander « quels fichiers référencent ce que je change ? ». Utiliser Grep si nécessaire.

## Conventions
- Garder les réponses concises et directes.
- Privilégier la simplicité : pas de sur-ingénierie.
- Lire le code existant avant de proposer des modifications.
- Respecter les conventions déjà en place dans chaque projet.
- **JAMAIS de downgrade** : ne jamais baisser la version d'une dépendance en dessous de ce que le projet ou la stack cible. Chercher un fix (version dev, fork, patch, alternative) et demander à l'utilisateur si aucune solution ne fonctionne. Voir `~/.claude/stacks/symfony.md` pour la stratégie de résolution détaillée.
