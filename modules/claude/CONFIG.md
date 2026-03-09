# Configuration — Référence complète

> Les paramètres actifs sont résumés dans `~/.claude/CLAUDE.md` (section "Paramètres actifs"). Ce fichier est la référence complète avec descriptions, profils et règles détaillées.

## Utilisation

Ce fichier définit les paramètres par défaut. Un CONFIG.md local au projet peut surcharger ces valeurs. En cas de contradiction, le local prime.

## Paramètres

| Clé | Valeur | Référence | Description |
|---|---|---|---|
| `profile` | `advanced` | [CONFIG.md#profils](./CONFIG.md) | Profil actif : `simple`, `standard`, `advanced`, `ask` (demander en début de projet). Surchargeable dans le CLAUDE.md du projet. |
| `tests.enabled` | `true` | [TEST.md#principes](./TEST.md) | Activer les tests sur chaque feature et fix |
| `tests.mutation` | `true` | [TEST.md#mutation-testing](./TEST.md) | Activer le mutation testing |
| `tests.min_coverage` | `80` | [TEST.md#coverage](./TEST.md) | Coverage minimum (%) pour les nouveaux projets |
| `tests.before_push` | `true` | [TEST.md#quand-tester](./TEST.md) | Vérifier que les tests passent avant chaque push (hook pre-push) |
| `tests.e2e` | `true` | [TEST.md#pyramide-de-tests](./TEST.md) | Activer les tests E2E |
| `doc.enabled` | `true` | [DOC.md#principes](./DOC.md) | Maintenir la documentation à jour |
| `doc.c4` | `true` | [DOC.md#contenu](./DOC.md) | Générer et maintenir les diagrammes C4 |
| `doc.adr` | `true` | [DOC.md#architecture-de-la-documentation](./DOC.md) | Maintenir les Architecture Decision Records |
| `doc.openapi` | `true` | [DOC.md#contenu](./DOC.md) | Maintenir la spécification OpenAPI |
| `code.comments` | `false` | [CONFIG.md#paramètres](./CONFIG.md) | Autoriser les commentaires dans le code |
| `code.max_file_length` | `300` | [CONFIG.md#qualité-du-code](./CONFIG.md) | Seuil de lignes pour signaler qu'un fichier est trop long et proposer un split |
| `security.audit` | `true` | [CONFIG.md#sécurité](./CONFIG.md) | Scanner les vulnérabilités des dépendances avant push ou en CI |
| `ci.provider` | `github` | [stacks/project-structure.md#cicd](./stacks/project-structure.md) | Provider CI/CD : `github`, `gitlab` |
| `patterns.outbox` | `true` | [stacks/patterns-async.md#outbox-pattern](./stacks/patterns-async.md) | Utiliser l'outbox pattern pour la messagerie asynchrone |
| `symfony.ddd` | `true` | [stacks/symfony.md#structure-ddd](./stacks/symfony.md) | Activer la structure DDD stricte (Symfony) |
| `nuxt.ddd` | `true` | [stacks/nuxt.md#structure-ddd](./stacks/nuxt.md) | Activer la structure DDD stricte (Nuxt) |
| `vue.ddd` | `true` | [stacks/vue.md#structure-ddd](./stacks/vue.md) | Activer la structure DDD stricte (Vue.js) |
| `git.strategy` | `trunk` | [stacks/git.md#branching-strategy](./stacks/git.md) | `trunk` : une seule branche main, features sur branches courtes. `gitflow` : branches main, develop, release, hotfix séparées. |
| `git.merge_strategy` | `squash` | [stacks/git.md#pull-requests](./stacks/git.md) | `squash` : tous les commits d'une PR fusionnés en un seul. `merge` : merge commit classique. `rebase` : réécriture linéaire sans merge commit. |
| `git.auto_branch` | `true` | [stacks/git.md#branching-strategy](./stacks/git.md) | Créer automatiquement une branche feature avant de modifier du code |
| `api.versioning` | `path` | [stacks/api.md#principes](./stacks/api.md) | `path` : version dans l'URL (/api/v1/users). `header` : version dans un header HTTP (Accept: application/vnd.api.v1+json). |
| `ci.auto_deploy_prod` | `false` | [stacks/ci.md#sur-merge-main-push](./stacks/ci.md) | Déploiement automatique en production après merge sur main |
| `continuity.enabled` | `true` | [CONTINUITY.md#1-reprise-après-compaction](./CONTINUITY.md) | Persister l'état des tâches complexes pour reprise automatique après compaction |
| `continuity.auto_plan` | `true` | [CONTINUITY.md#2-exécution-autonome-de-grosses-features](./CONTINUITY.md) | Planifier automatiquement les features de plus de 10 fichiers avant exécution |
| `continuity.parallel` | `true` | [CONTINUITY.md#parallélisation-avec-subagents](./CONTINUITY.md) | Utiliser les subagents worktree pour paralléliser les tâches indépendantes |
| `containers.runtime_only` | `true` | [CONFIG.md#contraintes-dexécution](./CONFIG.md) | Interdire l'exécution directe des commandes runtime (npm, bun, composer, php, symfony) — toujours via docker/make |
| `research.before_impl` | `true` | [PROCESS.md#recherche-avant-implémentation](./PROCESS.md) | Rechercher la doc à jour (context7, web) avant d'implémenter une feature ou un correctif |
| `research.context7` | `true` | [PROCESS.md#recherche-avant-implémentation](./PROCESS.md) | Autoriser l'utilisation de context7 pour récupérer la doc des libs/frameworks |
| `research.web` | `true` | [PROCESS.md#recherche-avant-implémentation](./PROCESS.md) | Autoriser la recherche web (WebSearch/WebFetch) pour compléter la doc |
| `tests.php_framework` | `pest` | [TEST.md#outils-par-stack](./TEST.md) | Framework de test PHP : `phpunit`, `pest` |
| `tests.architecture` | `true` | [CONFIG.md#tests-darchitecture](./CONFIG.md) | Générer des tests d'architecture (deptrac/phpat backend, eslint-plugin-boundaries frontend) pour protéger les règles de dépendances entre couches |
| `tests.testcontainers` | `false` | [CONFIG.md#testcontainers](./CONFIG.md) | Utiliser Testcontainers pour les tests d'intégration (BDD éphémère par test suite) au lieu de docker compose |
| `frontend.package_manager` | `pnpm` | [CONFIG.md#paramètres](./CONFIG.md) | Package manager frontend : `pnpm`, `bun`, `npm` |
| `task_runner` | `make` | [CONFIG.md#task-runner](./CONFIG.md) | Task runner : `make` (défaut) ou `taskfile` (go-task). Détermine si un Makefile ou un Taskfile.yml est généré |
| `security.headers` | `true` | [stacks/security.md#headers](./stacks/security.md) | Générer le middleware de security headers (X-Content-Type-Options, CSP, HSTS, etc.) |
| `security.rate_limiting` | `true` | [stacks/security.md#rate-limiting](./stacks/security.md) | Activer le rate limiting sur les endpoints d'authentification |
| `security.sast` | `true` | [stacks/security.md#sast](./stacks/security.md) | Activer l'analyse statique de sécurité (semgrep) |
| `security.secret_scanning` | `true` | [stacks/security.md#secret-scanning](./stacks/security.md) | Scanner les secrets dans le code (gitleaks) |
| `ci.dependabot` | `true` | [stacks/ci.md#dependabot](./stacks/ci.md) | Générer la configuration Dependabot / Renovate |
| `ci.matrix_testing` | `true` | [stacks/ci.md#matrix](./stacks/ci.md) | Tester sur plusieurs versions de PHP / Node en CI |
| `a11y.enabled` | `true` | [stacks/vue.md#accessibilité-a11y](./stacks/vue.md) | Appliquer les conventions d'accessibilité sur le frontend |

## Profils

Les profils sont des presets qui ajustent les paramètres selon le type de projet. Le tableau ci-dessous montre uniquement les valeurs qui **diffèrent** du profil `advanced` (= valeurs par défaut actuelles).

| Clé | `simple` | `standard` | `advanced` |
|---|---|---|---|
| `tests.mutation` | `false` | `false` | *(défaut)* |
| `tests.min_coverage` | `60` | `80` | *(défaut)* |
| `tests.e2e` | `false` | `true` | *(défaut)* |
| `doc.c4` | `false` | `true` (C1+C2 only) | *(défaut)* |
| `doc.adr` | `false` | `false` | *(défaut)* |
| `doc.openapi` | `false` | `true` | *(défaut)* |
| `code.max_file_length` | `500` | `300` | *(défaut)* |
| `security.audit` | `false` | `true` | *(défaut)* |
| `patterns.outbox` | `false` | `false` | *(défaut)* |
| `symfony.ddd` | `false` | `true` | *(défaut)* |
| `nuxt.ddd` | `false` | `true` | *(défaut)* |
| `vue.ddd` | `false` | `true` | *(défaut)* |
| `git.auto_branch` | `false` | `true` | *(défaut)* |
| `continuity.auto_plan` | `false` | `true` | *(défaut)* |
| `continuity.parallel` | `false` | `true` | *(défaut)* |
| `a11y.enabled` | `false` | `true` | *(défaut)* |
| `containers.runtime_only` | `false` | *(défaut)* | *(défaut)* |
| `research.before_impl` | `false` | *(défaut)* | *(défaut)* |
| `tests.php_framework` | *(défaut)* | *(défaut)* | *(défaut)* |
| `frontend.package_manager` | *(défaut)* | *(défaut)* | *(défaut)* |
| `security.headers` | `false` | `true` | *(défaut)* |
| `security.rate_limiting` | `false` | `true` | *(défaut)* |
| `ci.dependabot` | `false` | `true` | *(défaut)* |
| `ci.matrix_testing` | `false` | `false` | *(défaut)* |
| `tests.architecture` | `false` | `true` | *(défaut)* |
| `tests.testcontainers` | `false` | `false` | `false` |
| `security.sast` | `false` | `true` | *(défaut)* |
| `security.secret_scanning` | `false` | `true` | *(défaut)* |

### simple

Petits projets, MVPs, scripts, outils. Overhead minimal.

### standard

Applications web classiques. Bon équilibre qualité/vélocité.

### advanced

Domaines complexes, applications enterprise. Rigueur maximale. Profil par défaut actuel — toutes les valeurs restent à leur défaut.

### ask

En début de conversation sur un nouveau projet vide, demander à l'utilisateur quel profil appliquer (`simple`, `standard`, `advanced`) et enregistrer le choix dans le CLAUDE.md du projet.

### Utilisation des profils

- Définir `profile: simple|standard|advanced|ask` dans le CLAUDE.md du projet.
- **Ordre de résolution** : valeurs `advanced` (base) → delta du profil sélectionné → surcharges individuelles dans le CLAUDE.md du projet. Les surcharges individuelles ont toujours la priorité sur le profil.
- Si aucun profil n'est défini, `advanced` s'applique (rétrocompatible).
- Si `profile: ask`, demander à l'utilisateur en début de conversation sur un nouveau projet.

## Qualité du code

Quand `code.max_file_length` est défini :

- Si un fichier dépasse le seuil lors d'une modification, signaler à l'utilisateur et proposer un split.
- Ne pas splitter automatiquement — attendre la validation.
- Les fichiers de test bénéficient d'une tolérance de +50% (ex: 450 lignes si le seuil est 300). Les tests nécessitent naturellement plus de lignes (setup, multiples cas, fixtures).

## Sécurité

Quand `security.audit` = `true` :

- Exécuter `composer audit` et/ou `pnpm audit` (via Docker/make) avant chaque push ou en CI.
- Si des vulnérabilités critiques ou hautes sont détectées, les signaler à l'utilisateur avant de continuer.
- Ne pas bloquer le commit pour les vulnérabilités basses/modérées, mais les mentionner.

## Contraintes d'exécution

Quand `containers.runtime_only` = `true` :

- Les commandes applicatives (npm, npx, pnpm, bun, composer, php, symfony) sont **interdites en exécution directe** sur la machine hôte.
- Toujours passer par `docker compose exec <service>` ou une cible `make`.
- Cette règle est appliquée via des deny rules dans `settings.json`. Si `containers.runtime_only` est désactivé (ex: profil `simple`), retirer manuellement les deny rules suivantes de `settings.json` :
  ```json
  "deny": ["npm", "npx", "pnpm", "yarn", "bun", "node", "composer", "php", "symfony"]
  ```

## Package manager frontend

Quand `frontend.package_manager` est défini :

- Le lockfile, les commandes install/add, les scripts CI et les Dockerfiles utilisent le package manager choisi.
- Correspondances :

| Manager | Lockfile | Install | Add | Run |
|---|---|---|---|---|
| `pnpm` | `pnpm-lock.yaml` | `pnpm install` | `pnpm add` | `pnpm run` |
| `bun` | `bun.lock` | `bun install` | `bun add` | `bun run` |
| `npm` | `package-lock.json` | `npm install` | `npm install` | `npm run` |

## Tests d'architecture

Quand `tests.architecture` = `true` :

- **Backend (PHP)** : Ajouter `qossmic/deptrac` aux devDependencies. Générer `deptrac.yaml` avec les règles :
  - `Domain` ne dépend de rien (sauf PHP natif et Doctrine attributes)
  - `Application` dépend de `Domain` uniquement
  - `Infrastructure` peut dépendre de tout
  - Pas d'imports cross-bounded-context (sauf via `Shared`)
- **Frontend (TS)** : Ajouter `eslint-plugin-boundaries` aux devDependencies. Configurer les zones par bounded context dans `eslint.config.js`.
- Intégrer dans la target `quality` du Makefile/Taskfile et dans la CI.

## Testcontainers

Quand `tests.testcontainers` = `true` :

- Les tests d'intégration backend utilisent des containers éphémères au lieu de `docker compose` partagé.
- Ajouter `testcontainers/testcontainers` aux devDependencies Composer.
- Le `setUp()` des tests d'intégration lance un container PostgreSQL/MySQL/SQLite éphémère par classe de test.
- Avantage : isolation complète, parallélisation native des tests.

## Task runner

Quand `task_runner` est défini :

| Runner | Fichier | Documentation |
|---|---|---|
| `make` | `Makefile` | Standard, aucune dépendance supplémentaire |
| `taskfile` | `Taskfile.yml` | [Task](https://taskfile.dev) — nécessite `go-task` installé |

Les targets sont les mêmes dans les deux cas (`install`, `test`, `quality`, `up`, `down`, `doctor`, etc.). Le Taskfile utilise la syntaxe YAML avec dépendances de tâches et variables.
