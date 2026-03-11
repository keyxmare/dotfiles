---
name: new-project
description: Scaffolds a new project with configurable stack, architecture, CI/CD and documentation
allowed-tools: Bash(*), Write, Edit, Read, Glob, Grep, Agent, WebSearch, EnterPlanMode, ExitPlanMode, mcp__context7__resolve-library-id, mcp__context7__query-docs
---

# Skill — Création d'un nouveau projet

Tu es un assistant qui crée des projets from scratch en respectant la configuration Claude Code de l'utilisateur. Le processus est **rapide** : déduire le maximum, minimiser les questions, permettre de tout valider en un mot.

---

## Détection d'environnement

Avant de poser la moindre question, exécuter silencieusement :

```bash
docker --version 2>/dev/null || echo "DOCKER_NOT_FOUND"
docker compose version 2>/dev/null || echo "COMPOSE_NOT_FOUND"
make --version 2>/dev/null | head -1 || echo "MAKE_NOT_FOUND"
task --version 2>/dev/null || echo "TASK_NOT_FOUND"
git --version 2>/dev/null || echo "GIT_NOT_FOUND"
ls -A "$PWD" 2>/dev/null
```

Ne **jamais** vérifier php, node, npm, composer ou d'autres runtimes en local — tout passe par Docker (`containers.runtime_only`). Si Docker n'est pas installé, prévenir l'utilisateur et proposer une installation sans Docker.

### Détection monorepo

Si le répertoire courant contient `pnpm-workspace.yaml`, `turbo.json`, ou `nx.json`, on est dans un monorepo. Proposer :

```
Monorepo détecté (<type>). Où créer le projet ?

  [1] apps/<nom>/        — application dans le workspace
  [2] packages/<nom>/    — package partagé dans le workspace
  [3] <nom>/             — dossier indépendant (défaut hors monorepo)
```

Le choix s'applique au `path` du projet. Le reste du workflow est identique.

### Vérification des stacks

Après la détection d'environnement, vérifier silencieusement que les fichiers de stack nécessaires existent selon le type de projet :

| Type | Stacks requises |
|---|---|
| App web (Symfony) | `~/.claude/stacks/symfony.md`, `~/.claude/stacks/docker.md`, `~/.claude/stacks/makefile.md` |
| App web (Nuxt) | `~/.claude/stacks/nuxt.md` |
| App web (Vue.js) | `~/.claude/stacks/vue.md` |
| Script Shell | `~/.claude/stacks/shell.md` |
| Tous | `~/.claude/stacks/git.md`, `~/.claude/stacks/project-structure.md` |

Si un fichier de stack est manquant : signaler à l'utilisateur et proposer de continuer sans (les conventions internes seront utilisées comme fallback).

---

## Chargement des références

Ne pas charger les fichiers de référence en avance. Les lire **uniquement au moment où ils sont nécessaires** :

| Étape | Fichiers à lire | Section |
|-------|----------------|---------|
| 6-10 — Exécution scaffold | `references/scaffold-execution.md` | Toutes les étapes d'exécution |
| 6.3 — Config backend | `references/web-app/backend.md` | Symfony structure + config |
| 6.3 — Config frontend | `references/web-app/frontend.md` | Nuxt/Vue structure + config |
| 6.3 — Config infra | `references/web-app/infrastructure.md` | Docker, DevContainer, CORS, env, Makefile |
| 6.4 — Code structurel | `references/web-app/backend.md` | Validation & Error Handling |
| 6.5 — Modules | `references/modules.md` + `references/modules/<module>.md` | Index + fichier du module concerné |
| 6.6 — Thème | `references/web-app/frontend.md` | Section "Thème frontend" |
| 6.7 — Fixtures | `references/web-app/backend.md` | Section "Fixtures" |
| 6.8 — Éléments communs | `references/common.md` | Intégralité |
| 6.8 — Sécurité | `references/security.md` | Sections selon config |
| 6.11 — Archi tests | `references/architecture-tests.md` | Intégralité (si `tests.architecture` = `true`) |
| 8 — Features | `references/ddd-features.md` + `references/template-resolution.md` | Intégralité des deux |
| 8 — CLI/lib | `references/project-types.md` | Section du type concerné |
| Toutes les étapes | `references/rules-common.md` | Règles communes |

### Sélection des templates frontend

Les templates frontend sont **spécifiques au framework**. Ne pas mélanger les patterns Nuxt et Vue.js.

| Framework | Templates pages | Template service |
|---|---|---|
| **Nuxt** | `list-page-nuxt.vue.tpl`, `detail-page-nuxt.vue.tpl`, `form-page-nuxt.vue.tpl` | `service-nuxt.ts.tpl` |
| **Vue.js** | `list-page-vue.vue.tpl`, `detail-page-vue.vue.tpl`, `form-page-vue.vue.tpl` | `service-vue.ts.tpl` |
| **Communs** | `store.ts.tpl`, `entity-type.ts.tpl`, `e2e-crud.spec.ts.tpl`, `store-test.ts.tpl` | — |

Templates Pest (`*-pest.php.tpl`) : utilisés si `tests.php_framework` = `pest`. Templates standards (`*.php.tpl`) : utilisés si `tests.php_framework` = `phpunit`.

`assets/versions.json` est lu une fois à l'étape 6 pour résoudre les versions des dépendances.

---

## Mode rapide (one-liner)

```
/new-project                                          → mode interactif
/new-project saas                                     → preset SaaS
/new-project api                                      → preset API REST
/new-project backoffice                               → preset Backoffice
/new-project landing                                  → preset Landing page
/new-project marketplace                              → preset Marketplace
/new-project blog                                     → preset Blog
/new-project headless                                 → preset Headless API
/new-project microservice                             → preset Microservice
/new-project pwa                                      → preset PWA
/new-project ai-app                                   → preset AI App
/new-project web                                      → app web, déduit le reste
/new-project web symfony nuxt                         → app web Symfony + Nuxt
/new-project cli php|ts|shell                         → script CLI
/new-project lib php|ts                               → librairie
/new-project web "Description du projet"              → app web avec description
/new-project --dry-run saas "Mon SaaS"                → plan complet sans générer de fichiers
/new-project --yes saas "Mon SaaS"                    → tout accepter sans confirmation
```

Si des arguments sont fournis : appliquer les choix, déduire le reste, sauter à l'étape 2.

### Mode dry-run

Si `--dry-run` est passé : exécuter les étapes 1 à 5 normalement, puis s'arrêter après l'affichage de l'arborescence (étape 5). Aucun fichier n'est créé. Afficher le résumé complet + la liste de **tous** les fichiers qui seraient générés (profondeur complète, pas de compteurs). Utile pour prévisualiser un projet avant de le lancer.

Informations supplémentaires en dry-run :

```
Estimation dry-run :
  Fichiers code        : ~X
  Fichiers tests       : ~X
  Fichiers config      : ~X
  Fichiers docs        : ~X
  Ratio tests/code     : ~X%
  Services Docker      : postgres, redis, mailpit, ...
  Ports exposés        : 8080 (backend), 3000 (frontend), 5432 (postgres), ...
  Modules activés      : auth, messenger, mailer (→ 3 services Docker additionnels)
```

### Mode --yes

Si `--yes` est passé : accepter tous les défauts sans demander confirmation. Utile pour le prototypage rapide. L'utilisateur peut toujours surcharger via les arguments en ligne.

---

## Presets

| Preset | Type | Backend | Frontend | BDD | Profil | Layout | Modules auto |
|---|---|---|---|---|---|---|---|
| **saas** | App web | Symfony | Nuxt | PostgreSQL | advanced | Dashboard | auth, messenger, mailer |
| **api** | App web | Symfony | Aucun | PostgreSQL | advanced | — | auth, messenger |
| **backoffice** | App web | Symfony | Vue.js | PostgreSQL | advanced | Dashboard | auth |
| **landing** | App web | Aucun | Nuxt | Aucune | simple | Landing | — |
| **marketplace** | App web | Symfony | Nuxt | PostgreSQL | advanced | Dashboard | auth, messenger, mailer, search, file-upload |
| **blog** | App web | Symfony | Nuxt | PostgreSQL | advanced | Minimal | auth, search |
| **headless** | App web | Symfony | Aucun | PostgreSQL | advanced | — | auth, cache |
| **microservice** | App web | Symfony | Aucun | PostgreSQL | advanced | — | auth, messenger, monitoring, cache |
| **pwa** | App web | Aucun | Nuxt | Aucune | standard | Minimal | i18n |
| **ai-app** | App web | Symfony | Nuxt | PostgreSQL | advanced | Dashboard | auth, messenger, cache |

Si un preset est choisi : appliquer toute la config, demander la description (sauf si fournie), sauter à l'étape 2.

---

## Étape 1 — Type et stack

Demander le **nom**, le **path** et la **description** du projet, puis proposer deux chemins :

```
Nom : ___
Path : ___ (défaut : $PWD/<nom>)
Description (une phrase) : ___

Comment démarrer ?

  [p] Preset     — config pré-faite (saas, api, backoffice, landing, marketplace, blog, headless, microservice, pwa, ai-app)
  [c] Custom     — tu choisis chaque brique
```

### Chemin Preset

Si `p` (ou nom de preset directement) : afficher la liste des presets avec un résumé d'une ligne.

```
  Preset              Stack                               Modules auto
  ─────────────────   ─────────────────────────────────   ─────────────────────────
  s. SaaS             Symfony + Nuxt + PostgreSQL          auth, messenger, mailer
  a. API REST         Symfony + PostgreSQL                 auth, messenger
  b. Backoffice       Symfony + Vue.js + PostgreSQL        auth
  l. Landing page     Nuxt seul                            —
  m. Marketplace      Symfony + Nuxt + PostgreSQL          auth, messenger, mailer, search, file-upload
  g. Blog             Symfony + Nuxt + PostgreSQL          auth, search
  h. Headless API     Symfony + PostgreSQL                 auth, cache
  µ. Microservice     Symfony + PostgreSQL                 auth, messenger, monitoring, cache
  p. PWA              Nuxt seul                            i18n
  i. AI App           Symfony + Nuxt + PostgreSQL          auth, messenger, cache
```

> Choisis un preset (`s`, `a`, `b`, `l`, `m`, `g`, `h`, `µ`, `p`, `i`)

Appliquer toute la config du preset et sauter à l'étape 2.

### Chemin Custom

Si `c` : poser les questions **une par une** (pas de tableau) :

```
1. Type : [1] App web [d]  [2] Script / CLI  [3] Librairie
2. Backend : [1] Symfony [d]  [2] Aucun           ← si App web
3. Frontend : [1] Nuxt [d]  [2] Vue.js  [3] Aucun  ← si App web
4. Base de données : [1] PostgreSQL [d]  [2] MySQL  [3] SQLite  [4] Aucune  ← si backend
5. Task runner : [1] Make [d]  [2] Taskfile (go-task)
```

> Réponses enchaînées : `1 1 1 1` ou `web symfony nuxt postgresql`

### Questions conditionnelles

- **Script / CLI** → Langage : PHP [d] | TypeScript | Shell
- **Librairie** → Écosystème : PHP [d] | TypeScript / JS
- **App web avec frontend** → Package manager : pnpm [d] | bun | npm
- **App web avec Nuxt** → SSR : oui [d] | non (mode SPA)
- **SQLite sélectionné** → pas de service Docker BDD, fichier `var/data.db`

Le marqueur `[d]` = valeur par défaut si omis. La valeur de `frontend.package_manager` et `task_runner` dans `~/.claude/CONFIG.md` remplace le défaut.

### Recherche en parallèle

Dès que la description et la stack sont connues, **lancer la recherche en tâche de fond** (si `research.before_impl` = `true`) via context7 et/ou WebSearch. Les résultats seront prêts pour l'étape 4 sans temps d'attente.

---

## Étape 2 — Profil et complexité

Choisir un profil de qualité et la complexité en une seule étape. Les profils et leurs deltas sont définis dans `~/.claude/CONFIG.md`.

```
Profil :     [1] simple  [2] standard  [3] advanced [d]
Complexité : [1] simple  [2] advanced (DDD, bounded contexts) [d = selon profil]
```

> `ok` ou `3` → advanced (tout au maximum)

Si un preset a été choisi en étape 1, le profil et la complexité sont pré-sélectionnés (saas/api/backoffice/marketplace/blog/headless/microservice/ai-app → advanced, pwa → standard, landing → simple). L'utilisateur peut les changer.

La complexité s'aligne par défaut sur le profil :
- Profil `advanced` → complexité `advanced`
- Profil `standard` / `simple` → complexité `simple`

Scripts/CLI et librairies → toujours complexité `simple` (pas de ligne complexité affichée).

Si advanced : `messenger` est activé automatiquement (CQRS buses).

### Framework de test PHP

Le framework de test PHP est déterminé par `tests.php_framework` dans `~/.claude/CONFIG.md` (défaut : `pest`). Pas de question posée — hérité de la config globale, surchargeable comme tout autre paramètre dans l'affichage du delta ou les surcharges.

### Affichage du delta

Afficher uniquement les valeurs qui **diffèrent** du profil `advanced` (base). Si `advanced`, rien à afficher — confirmer directement.

```
Profil <choisi> — ce qui change vs advanced :

  Clé                  Valeur
  ──────────────────   ──────
  tests.mutation       false
  doc.adr              false
  ...

ok ? (ou modifie : `tests.mutation true`, `ci.provider gitlab`)
```

### Surcharges

Après validation du profil, l'utilisateur peut surcharger n'importe quel paramètre individuel. Seules les surcharges seront enregistrées dans le CLAUDE.md du projet et le `scaffold.config.json`.

> `show all` → afficher tous les paramètres pour revue complète

Les paramètres globaux (`containers.runtime_only`, `research.*`) sont hérités de `~/.claude/CONFIG.md` et ne sont pas affichés — ils ne varient pas par projet.

---

## Étape 3 — Architecture (si advanced)

### Bounded contexts

Proposer des contexts basés sur la description, le nom et le type.

```
Bounded contexts proposés pour "<nom>" :

  Context             Responsabilité
  ─────────────────   ──────────────────────────────────────────
  Identity            Utilisateurs, authentification, autorisation
  <ContextB>          <description courte>

ok ? (ou modifie : ajoute/retire/renomme)
```

Règles : toujours `Identity`, 2-5 contexts max, déduire de la description en priorité.

### Structure DDD frontend (si Nuxt + advanced)

```
Structure DDD frontend :
  [1] Dossiers dans app/ [d]   — app/identity/, app/catalog/
  [2] Nuxt Layers              — layers/identity/, layers/catalog/ (auto-registered)
```

Le choix est stocké dans `scaffold.config.json` : `nuxt_ddd_strategy: "directories" | "layers"`. Voir `references/web-app/frontend.md` pour les détails de chaque approche.

---

## Étape 4 — Features, modules et thème

Utiliser les résultats de la recherche lancée en parallèle à l'étape 1. Si la recherche n'est pas terminée, attendre.

Proposer des **features fonctionnelles** (haut niveau), pas des entités brutes. Déduire les entités et leurs propriétés de chaque feature — l'utilisateur valide le tout en un bloc.

### Mode simple

```
Recherche effectuée — X sources consultées

Features proposées pour "<nom>" :

  ├── Authentification (register, login, logout)
  ├── Gestion des recettes (CRUD)
  ├── Catégories (CRUD)
  └── Recherche de recettes (par titre, par catégorie)

Entités déduites :

  Entité       Propriétés                                          Relations
  ───────────  ──────────────────────────────────                  ──────────────────────────
  User         email: string, password: string, name: string       —
  Recipe       title: string, description: text, prep_time: int    → Category (ManyToOne)
  Category     name: string, slug: string                          ← Recipe[] (OneToMany)

ok ? (ou modifie)
```

### Mode advanced

```
Recherche effectuée — X sources consultées

Features proposées :

  Identity
  ├── Authentification (register, login, logout)
  └── Gestion du profil (CRUD)

  Recipe
  ├── Gestion des recettes (CRUD)
  ├── Catégories (CRUD)
  └── Recherche de recettes (par titre, par catégorie)

Entités déduites :

  Context      Entité       Propriétés                               Relations
  ───────────  ───────────  ──────────────────────────────────       ──────────────────────────
  Identity     User         email: string, password: string          —
  Recipe       Recipe       title: string, description: text         → Category (ManyToOne)
  Recipe       Category     name: string, slug: string               ← Recipe[] (OneToMany)

ok ? (ou modifie)
```

### Règles

- **Toujours rechercher avant de proposer.** Ne pas se baser uniquement sur les connaissances internes.
- S'appuyer sur la **description** et les **résultats de recherche** pour proposer des features métier concrètes, pas seulement des CRUD génériques.
- Les propriétés sont **déduites** de la description, du nom de l'entité et des résultats de recherche. L'utilisateur peut les modifier, en ajouter ou en retirer.
- Types de propriétés supportés : `string`, `text`, `int`, `float`, `bool`, `datetime`, `uuid`, `json`, `enum(val1,val2,...)`.
- **Relations** : déduites automatiquement entre entités. Types supportés : `ManyToOne`, `OneToMany`, `ManyToMany`, `OneToOne`. L'utilisateur peut les modifier. Voir la section "Relations entre entités" dans `references/ddd-features.md`.
- Les relations cross-context utilisent un ID (`string`) au lieu d'un import direct.
- 3-5 features par contexte max (advanced) ou 3-8 features total (simple).

### Modules

Si des features impliquent un module, l'activer automatiquement et le signaler. Lire `references/modules.md` pour les correspondances feature → module et les détails de génération.

Apps web uniquement. N'afficher que les modules **non-auto** pertinents selon la stack. Les modules auto (messenger si advanced, + ceux activés par les features) sont déjà activés silencieusement.

```
Modules auto-activés : auth ← Authentification, mailer ← Email de bienvenue

Modules additionnels disponibles : (numéros pour ajouter, ok pour passer)

  Infra                                         Fonctionnel
  ─────────────────────────────────────────     ─────────────────────────────────────────
  1. monitoring   Health + logs [rec]            4. file-upload  Upload + stockage
  2. cache        Redis cache layer              5. i18n         Internationalisation
  3. scheduler    Tâches planifiées              6. search       Meilisearch
                                                 7. admin        EasyAdmin backoffice

  Temps réel
  ─────────────────────────────────────────
  8. mercure      SSE temps réel
```

> `ok` → aucun | `1 2` → ajouter monitoring et cache | `all` → tout

N'afficher que les modules qui ne sont **pas déjà activés** et qui sont pertinents pour la stack. Si tous les modules pertinents sont déjà activés, ne pas afficher cette sous-section.

Affichage conditionnel : `mailer`, `file-upload`, `cache`, `scheduler`, `search`, `admin` → si backend. `mercure` → si backend + frontend. `i18n` → si frontend. `monitoring` → toujours si app web.

### Thème frontend (si frontend présent)

Apps web avec frontend uniquement. Lire `references/web-app.md` (section "Thème frontend") pour les détails d'installation et les éléments à créer.

```
Framework UI : [1] Tailwind CSS [d]  [2] Shadcn-vue  [3] Nuxt UI  [4] PrimeVue  [5] Vuetify  [6] Aucun
Layout :       [1] Dashboard [d si saas/backoffice]  [2] Landing [d si landing]  [3] Minimal [d sinon]
```

Shadcn-vue et Nuxt UI sont headless/composable et basés sur Tailwind — choix recommandé pour les projets 2026+. Nuxt UI uniquement si frontend = Nuxt.

> `ok` → défauts | `2 1` → PrimeVue + Dashboard

---

## Étape 5 — Plan et validation

### Résumé structuré

```
Résumé du projet — <nom>

  Clé            Valeur
  ─────────────  ──────────────────────────
  Type           App web
  Backend        Symfony 8.x
  Frontend       Nuxt 4.x
  BDD            PostgreSQL 17
  Profil         advanced
  Complexité     advanced (DDD/CQRS)
  Tests PHP      Pest
  Archi tests    deptrac + eslint-boundaries
  Pkg manager    pnpm
  Task runner    Make
  Layout         Dashboard (Tailwind)
  Modules        auth, messenger (auto), mailer, monitoring
  Contexts       Identity, Catalog, Order
  Features       12 features, 8 entités, 5 relations
  CI             GitHub Actions
  Sécurité       headers, rate-limiting, audit
  SSR            oui (Nuxt) / — (Vue.js)
  DDD frontend   directories / layers (Nuxt)
  Skill version  2.3.0
  Surcharges     ci.auto_deploy_prod: true
```

### Arborescence

Profondeur 2 max. Compteur de fichiers par section. Ne pas lister chaque handler/controller/test individuellement.

```
<project>/                                    ~X fichiers au total
├── backend/
│   ├── config/                               (6 fichiers)
│   ├── src/
│   │   ├── Identity/                         (Y fichiers)
│   │   ├── Catalog/                          (Z fichiers)
│   │   └── Order/                            (W fichiers)
│   └── tests/                                (N fichiers)
├── frontend/
│   ├── app/                                  (M fichiers)
│   └── tests/                                (P fichiers)
├── docker/                                   (6 fichiers)
├── docs/                                     (K fichiers)
├── .github/                                  (3 fichiers)
└── Makefile, README.md, CONTRIBUTING.md, scaffold.config.json, ...
```

```
Ce plan te convient ? (ok / dis-moi ce que tu veux changer)
```

### Validation pré-scaffold

Avant de passer à l'étape 6, valider automatiquement :

- **Dépendances inter-modules** : `admin` nécessite `auth`, `mercure` nécessite backend + frontend, etc.
- **Cohérence stack** : si frontend sans backend, pas de modules backend-only.
- **Templates existants** : vérifier que les fichiers de templates référencés dans `<skill-path>/assets/templates/` existent.
- **Stacks requises** : vérifier que les fichiers `~/.claude/stacks/*.md` nécessaires sont présents (voir "Vérification des stacks").

Si un problème est détecté, le signaler et proposer une correction avant de continuer.

### Persistance de l'état (CONTINUITY)

Après validation du plan par l'utilisateur, écrire `.claude/task-state.local.md` dans le **projet cible** :

```markdown
---
status: in_progress
step: 5
skill: new-project
---

# Scaffold — <nom>

## Choix validés

- Type: <type>
- Backend: <backend>
- Frontend: <frontend>
- BDD: <database>
- Profil: <profil>
- Complexité: <complexité>
- Tests PHP: <pest|phpunit>
- Package manager: <pnpm|bun|npm>
- SSR: <true|false|null>
- DDD frontend: <directories|layers|null>
- Layout: <layout>
- UI Framework: <ui_framework>
- Modules: <modules>
- Contexts: <contexts>

## Features

<copie du bloc features validé à l'étape 4>

## Config overrides

<surcharges par rapport au profil>

## Progression

- [x] Étape 1 — Type et stack
- [x] Étape 2 — Profil et complexité
- [x] Étape 3 — Architecture
- [x] Étape 4 — Features, modules et thème
- [x] Étape 5 — Plan validé
- [ ] Étape 6 — Scaffold (structure + config + modules + thème + sécurité + a11y + communs)
- [ ] Étape 7 — Vérification scaffold
- [ ] Étape 8 — Features (0/N)
- [ ] Étape 9 — Vérification finale
- [ ] Étape 10 — Récapitulatif + métriques
```

Mettre à jour `step` et la checklist après chaque étape. À l'étape 8, indiquer le nombre de features implémentées (`3/12`).

Si le contexte est compacté et que `.claude/task-state.local.md` existe avec `status: in_progress`, relire ce fichier et `scaffold.config.json`, puis reprendre à l'étape indiquée sans demander confirmation.

À l'étape 10 (fin), supprimer `task-state.local.md`.

---

## Étapes 6-10 — Exécution du scaffold

Lire `references/scaffold-execution.md` au moment de passer à l'étape 6. Ce fichier contient :
- **Étape 6** — Scaffold du projet vide (arborescence, config, code structurel, modules, thème, fixtures, sécurité, a11y, communs)
- **Étape 7** — Vérification scaffold (make doctor/install/up/quality/migration/seed)
- **Étape 8** — Implémentation des features (une par une, avec commits intermédiaires et parallélisation)
- **Étape 9** — Vérification finale
- **Étape 10** — Récapitulatif + métriques + cleanup

---

## Règles du skill

### Workflow

- **Max 2 questions par étape.** Regrouper au maximum.
- **Toujours proposer `ok`** pour accepter les défauts.
- **Si `--yes`** : ne poser aucune question, tout accepter avec les défauts.
- **Scaffold vérifié avant les features** (étape 7) — ne jamais coder sur une base cassée.
- **`make quality` après chaque feature** (étape 8) — ne pas passer à la suivante si c'est rouge.
- **Commit après chaque feature** — rollback possible.
- **Lire les fichiers de stack** (`~/.claude/stacks/*.md`) avant d'implémenter chaque composant.
- **Recherche avant implémentation** si `research.before_impl` = `true`.
- **Lazy loading des références** — ne lire les fichiers `references/` qu'au moment où ils sont nécessaires (voir "Chargement des références").
- **Versions dynamiques** — résoudre via context7 puis fallback sur `assets/versions.json`.
- **Validation pré-scaffold** — vérifier les dépendances inter-modules et la cohérence avant de générer.
- **`skill_version`** — toujours inclure dans `scaffold.config.json` pour la traçabilité.
- **Métriques** — persister dans `scaffold.config.json` à l'étape 10 comme baseline.
- **Relations** — déduire automatiquement entre entités, stocker dans `scaffold.config.json`.
- **Tests d'architecture** — générer `deptrac.yaml` et `eslint-boundaries` si `tests.architecture` = `true`.
- **SQLite** — si sélectionné, pas de service Docker BDD, config Doctrine adaptée.
- **Taskfile** — si `task_runner` = `taskfile`, générer `Taskfile.yml` au lieu de `Makefile`.
- **Monorepo** — détecter et adapter le path si dans un workspace existant.

### Code

Voir `references/rules-common.md` pour les règles communes (strict_types, final/readonly, Edit vs Write, Docker, tests, Pest, conflits).

Les conventions de code spécifiques (typage, PSR-12, Composition API, nommage, etc.) sont définies dans les fichiers de stack (`~/.claude/stacks/*.md`) et `~/.claude/CONFIG.md`.

### Quality gates — frontend

**Règles critiques** à respecter pour chaque page frontend générée :

1. **Zéro données hardcodées** — tout contenu affiché provient du store Pinia (connecté au service API). Si du texte statique d'exemple apparaît dans un `.vue` (ex: `"Mon produit"`, `"Lorem"`, `42`, `19.99`), c'est un bug.
2. **Liens fonctionnels** — chaque `NuxtLink`/`RouterLink` pointe vers une page/route qui existe. Après chaque feature, vérifier que les cibles existent.
3. **Navigation à jour** — après chaque entité, le layout (sidebar/nav) est mis à jour avec un lien vers la page liste.
4. **data-testid** — chaque élément interactif a un `data-testid` (convention dans `references/template-resolution.md`).
5. **Templates framework-spécifiques** — utiliser les templates `-nuxt` ou `-vue` selon le framework choisi. Ne jamais importer `useRoute` depuis `vue-router` dans du code Nuxt.
6. **Routes Vue.js** — si Vue.js, ajouter les routes dans `routes.ts` et les importer dans le router principal.

### Vérification post-feature (étape 8)

Après génération de chaque feature, **avant** `make quality` :

```
Checklist feature :
  [ ] Liens — NuxtLink/RouterLink pointent vers des pages existantes
  [ ] API URLs — BASE_URL service = routes backend
  [ ] Données dynamiques — pas de chaînes d'exemple hardcodées dans les .vue
  [ ] Store connecté — pages utilisent le store, pas de fetch inline
  [ ] Types cohérents — types TS = propriétés backend
  [ ] Navigation — sidebar mise à jour
  [ ] data-testid — éléments interactifs identifiés
```

Voir `references/template-resolution.md` pour les détails complets.

### Doctrine — PHP attributes (Symfony 8)

Les entités utilisent les **PHP attributes Doctrine** directement sur le domain model (plus de mapping XML — supprimé en Symfony 8). Le template `entity.php.tpl` inclut les imports `Doctrine\ORM\Mapping as ORM` et les attributs de classe/propriétés. En mode advanced, le constructeur est privé avec une méthode statique `create()`.

Les relations entre entités génèrent les attributs Doctrine appropriés (`#[ORM\ManyToOne]`, `#[ORM\OneToMany]`, etc.). Voir la section "Relations entre entités" dans `references/ddd-features.md`.

### ObjectMapper (Symfony 8)

En mode advanced, les handlers CQRS utilisent `Symfony\Component\ObjectMapper\ObjectMapper` pour le mapping Entity↔DTO au lieu du mapping inline. Le template `object-mapper.php.tpl` génère le service dans `Shared/Infrastructure/Mapper/`. Les entités et DTOs utilisent les attributs `#[Map]` pour configurer le mapping déclarativement. Ajouter `symfony/object-mapper` dans `composer.json`.

### Invokable Commands (Symfony 8)

Les commandes console utilisent le pattern **invokable** avec `#[AsCommand]` et `#[MapInput]` au lieu d'hériter de `Command`. Voir `references/project-types.md` pour les détails et exemples.

---

## Presets custom

En plus des 7 presets intégrés, l'utilisateur peut sauvegarder ses propres presets :

```
/new-project --save-preset my-stack    → sauvegarde le scaffold.config.json courant comme preset
/new-project my-stack "Mon projet"     → utilise le preset custom
```

Les presets custom sont stockés dans `~/.claude/skills/new-project/presets/<name>.json`. Le format est un sous-ensemble de `scaffold.config.json` (sans `name`, `description`, `created_at`, `features`).

Si un preset custom a le même nom qu'un preset intégré, le custom prime.

---

## Micro-generators

Pour ajouter, modifier ou maintenir un projet existant sans tout re-générer :

| Commande | Usage |
|---|---|
| `/new-project:bounded-context` | Ajouter un bounded context (backend + frontend + tests) |
| `/new-project:entity` | Ajouter une entité avec CRUD complet (ou `--light` pour un CRUD minimal) |
| `/new-project:feature` | Ajouter une feature custom (command, query, event, page) |
| `/new-project:module` | Ajouter un module (auth, mailer, cache, scheduler, etc.) |
| `/new-project:upgrade` | Vérifier et mettre à jour les dépendances du projet |
| `/new-project:remove` | Retirer une entité, un module ou un bounded context |
| `/new-project:sync` | Synchroniser avec les templates/conventions actuels du skill (idempotent) |
| `/new-project:evolve` | Migrer vers un profil/complexité supérieur (simple→standard→advanced) |
| `/new-project:doctor` | Vérifier la santé du skill (`--skill`) ou d'un projet (`--project`) |

Ces commandes lisent `scaffold.config.json` pour connaître le contexte du projet.

`/new-project:sync` compare la `skill_version` du projet avec la version actuelle et propose les mises à jour structurelles (fichiers de config, CI, Docker). Ne touche jamais au code métier.

`/new-project:evolve` gère les migrations de complexité : déplacement de fichiers, création de bounded contexts, extraction de Commands/Queries depuis les Services, etc. Crée un commit de rollback avant chaque migration.

`/new-project:doctor` sans arguments dans un projet scaffoldé vérifie la cohérence entre `scaffold.config.json` et les fichiers réels. Avec `--skill`, vérifie l'intégrité de l'installation du skill (templates, stacks, références).

---

## Erreurs courantes du scaffold

Voir `references/troubleshooting.md` pour le tableau complet de diagnostic et la démarche de résolution.

## Vérification du skill

Pour vérifier l'intégrité de l'installation du skill : `bash <skill-path>/scripts/check-skill.sh`

Le script vérifie que tous les templates, références, stacks et commandes sont présents et valides. Voir aussi `/new-project:doctor --skill`.
