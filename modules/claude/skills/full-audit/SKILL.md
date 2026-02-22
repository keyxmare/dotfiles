---
name: full-audit
description: Lancer un audit complet du projet en analysant 9 axes (legacy, tests, securite, API, architecture, code mort, configuration, couplage, complexite) et produire un dashboard consolide en Markdown ou HTML. Utiliser quand l'utilisateur veut un audit global, un etat des lieux complet, un rapport de sante du projet, ou un dashboard de qualite.
argument-hint: [scope] [--bc=<name>] [--axes=all|legacy|tests|security|api|architecture|dead-code|config|coupling|complexity] [--output=markdown|html] [--summary] [--resume] [--full]
---

# Full Audit — Dashboard consolide multi-axes

Tu es un expert en audit global de projets Symfony/DDD. Tu orchestres une analyse rapide sur 9 axes complementaires (legacy, tests, securite, API, architecture, code mort, configuration, couplage, complexite) et tu produis un **dashboard consolide** avec un score global (A-F), des scores par axe, et des recommandations actionnables. Ce skill privilegie la **largeur** (breadth over depth) : chaque axe est scanne rapidement pour donner une vision d'ensemble. Pour un audit approfondi sur un axe specifique, utiliser le skill dedie.

## Arguments

- `$ARGUMENTS` : scope optionnel (dossier, Bounded Context, ou chemin). Si vide, analyser tout le projet (`src/`, `config/`, `templates/`, `tests/`).
- `--axes=<axes>` : liste d'axes a auditer, separes par des virgules. Defaut : `all`. Valeurs possibles :
  - `legacy` — dette technique, versions, deprecations
  - `tests` — couverture, qualite, repartition
  - `security` — vulnerabilites OWASP, secrets, config securite
  - `api` — qualite API Platform (conditionnel)
  - `architecture` — DDD, bounded contexts, couplage inter-BC
  - `dead-code` — code mort, services orphelins
  - `config` — doublons, config morte, variables orphelines
  - `coupling` — SRP, god services, dependances excessives
  - `complexity` — complexite cyclomatique, classes longues, nesting profond
  - `all` — tous les axes
- `--output=<format>` :
  - `markdown` (defaut) : dashboard Markdown dans la console
  - `html` : ecrire un fichier `docs/full-audit.html` autonome (CSS inline, SVG gauges, pas de dependances externes)
- `--summary` : resume compact (score global + scores par axe + top 5 actions). Utile pour un suivi regulier ou un apercu rapide.

## Phase 0 — Chargement du contexte

1. **Appliquer `skill-directives.md` Phase 0** (contexte global + docs projet + stacks).
2. Stacks specifiques : `symfony.md`, `ddd.md`, `testing.md`, `security.md`, `database.md`, `env.md`
   - Avec API Platform → charger aussi `api-platform.md`
   - Avec Messenger → charger aussi `messenger.md`
3. Identifier l'environnement du projet :
   - Lire `composer.json` pour les versions PHP, Symfony, et les packages installes
   - Lire `composer.lock` pour les versions exactes
   - Lister `src/` pour detecter les Bounded Contexts
   - Verifier les outils installes : PHPStan, Infection, deptrac, PHP-CS-Fixer
   - Lire `config/packages/` pour les bundles configures
   - Verifier si `phpunit.xml(.dist)` existe
   - Verifier si un `Makefile` existe (l'utiliser pour les commandes)
4. **Consulter les references** : lire `references/scoring-derivation.md` pour les baremes detailles et `references/report-template.md` pour les templates de rapport.

## Phase 1 — Analyse multi-axes

9 axes, chacun avec une methode d'analyse **simplifiee** (breadth over depth). Scanner rapidement pour identifier les problemes, pas pour les diagnostiquer en profondeur.

### 1.1 Axe Legacy (poids 12%)

Metriques rapides :

| # | Metrique | Methode de detection |
|---|---------|---------------------|
| 1 | Version PHP | Lire `require.php` dans `composer.json`, comparer avec 8.5 |
| 2 | Version Symfony | Lire `symfony/framework-bundle` dans `composer.lock`, comparer avec 8.x |
| 3 | Deprecations code | Scanner `src/` pour les patterns deprecies : `getDoctrine()`, annotations `@Route`/`@ORM\*`, `ContainerAware`, `EventSubscriberInterface`, `$defaultName` |
| 4 | Packages outdated | Comparer les versions majeures dans `composer.lock` vs les dernieres stables connues |

**Scoring** : 0-10 base sur le nombre de problemes ponderes par severite. Consulter `references/scoring-derivation.md` section "Axe Legacy" pour le bareme detaille.

### 1.2 Axe Tests (poids 13%)

Metriques rapides inspirees de `/test-auditor` :

| # | Metrique | Methode de detection |
|---|---------|---------------------|
| 1 | Ratio fichiers testes / testables | Compter `src/**/*.php` (hors entites, DTOs, events) vs `tests/**/*Test.php` |
| 2 | Couverture par couche DDD | Verifier la presence de tests dans Domain, Application, Infrastructure |
| 3 | Tests fantomes | Scanner les classes `*Test.php` pour les methodes sans `$this->assert*`, `self::assert*`, `$this->expect*` |
| 4 | Mutation testing | Verifier si Infection est installe (`infection/infection` dans `composer.json`) et configure (`infection.json` ou `infection.json.dist`) |

**Scoring** : 0-10. Consulter `references/scoring-derivation.md` section "Axe Tests" pour le bareme detaille.

### 1.3 Axe Securite (poids 13%)

Metriques rapides inspirees de `/security-auditor` :

| # | Metrique | Methode de detection |
|---|---------|---------------------|
| 1 | Injections SQL | Scanner les concatenations dans les requetes DQL/SQL (`createQuery`, `executeQuery` avec variables) |
| 2 | XSS | Scanner `templates/` pour `\|raw` et `autoescape false` |
| 3 | Secrets hardcodes | Scanner `src/` et `config/` pour les patterns de secrets (cles API, mots de passe, tokens) |
| 4 | Config security.yaml | Verifier firewalls, password hashers, access control |
| 5 | CORS permissif | Verifier `allow_origin: ['*']` dans la config CORS |

**Scoring** : 0-10 — chaque vulnerabilite critique = -2, warning = -0.5 (partant de 10). Consulter `references/scoring-derivation.md` section "Axe Securite".

### 1.4 Axe API (poids 8%, conditionnel)

**Active SEULEMENT si `api-platform/core` est detecte dans `composer.json`.** Si absent, le poids de 8% est redistribue proportionnellement aux 8 autres axes.

Metriques rapides inspirees de `/api-auditor` :

| # | Metrique | Methode de detection |
|---|---------|---------------------|
| 1 | Entites exposees vs DTOs | Compter les `#[ApiResource]` sur des entites Doctrine vs sur des DTOs dedies |
| 2 | Groupes de serialisation | Verifier la presence de `normalizationContext`/`denormalizationContext` avec `Groups` |
| 3 | Pagination | Verifier si la pagination est activee globalement ou par ressource |
| 4 | Descriptions OpenAPI | Verifier la presence de `description` dans les attributs `#[ApiResource]`, `#[ApiProperty]`, `#[ApiFilter]` |

**Scoring** : 0-10. Consulter `references/scoring-derivation.md` section "Axe API".

### 1.5 Axe Architecture (poids 14%)

Metriques rapides inspirees de `/dependency-diagram` :

| # | Metrique | Methode de detection |
|---|---------|---------------------|
| 1 | Nombre de BCs | Compter les dossiers de premier niveau dans `src/` qui representent des bounded contexts |
| 2 | Imports cross-BC | Scanner les `use` statements qui traversent les frontieres de BC (ratio cross-BC / total) |
| 3 | Cycles de dependances | Detecter les dependances circulaires entre BCs (A -> B -> A) |
| 4 | Violations DDD | Detecter les imports Domain -> Infrastructure et Domain -> Application |
| 5 | Taille du Shared Kernel | Ratio de fichiers dans `Shared/`/`Common/` vs total `src/` |

**Scoring** : 0-10. Consulter `references/scoring-derivation.md` section "Axe Architecture".

**Sous-metriques conformite DDD** (integrees dans le score Architecture) :

| # | Sous-metrique | Methode de detection |
|---|--------------|---------------------|
| 6 | Presence de Value Objects | Ratio VO / entites dans `src/*/Domain/` (rechercher `ValueObject/`, `Model/` hors entites) |
| 7 | Purete du Domain | % de fichiers `src/*/Domain/**/*.php` sans import framework (`Symfony\`, `Doctrine\`, `ApiPlatform\`) |
| 8 | Domain Events | Presence de classes `*Event.php` dans `src/*/Domain/Event/` et handlers cross-BC |
| 9 | Repository Interfaces | Ratio d'interfaces `*RepositoryInterface.php` dans Domain / implementations dans Infrastructure |

### 1.6 Axe Code mort (poids 10%)

Metriques rapides inspirees de `/dead-code-detector` :

| # | Metrique | Methode de detection |
|---|---------|---------------------|
| 1 | Services orphelins | Scanner les classes de services dans `src/` et verifier si elles sont injectees quelque part (via `use` statements) |
| 2 | Interfaces sans implementation | Trouver les interfaces et verifier qu'au moins une classe les implemente |
| 3 | Routes mortes | Verifier que les controllers references dans les routes existent |
| 4 | Commandes non referencees | Lister les commandes console et verifier qu'elles sont enregistrees |

**Scoring** : 0-10 base sur le pourcentage de code mort vs code total. Consulter `references/scoring-derivation.md` section "Axe Code mort".

### 1.7 Axe Configuration (poids 10%)

Metriques rapides inspirees de `/config-archeologist` :

| # | Metrique | Methode de detection |
|---|---------|---------------------|
| 1 | Doublons autodiscovery | Services declares explicitement dans `services.yaml` ET couverts par le `resource` autodiscovery |
| 2 | Bundles non configures | Packages Symfony installes (`composer.json`) sans fichier de config dans `config/packages/` |
| 3 | Variables d'environnement orphelines | Variables dans `.env` non referencees dans le code ou la config |
| 4 | Config morte | Fichiers de config dans `config/packages/` pour des bundles non installes |

**Scoring** : 0-10. Consulter `references/scoring-derivation.md` section "Axe Configuration".

### 1.8 Axe Couplage services (poids 10%)

Metriques rapides inspirees de `/service-decoupler` :

| # | Metrique | Methode de detection |
|---|---------|---------------------|
| 1 | God services | Compter les services avec > 7 dependances dans le constructeur |
| 2 | Dependance max | Identifier le service avec le plus de dependances (nombre) |
| 3 | Ratio SRP | Proportion de services OK (≤ 4 deps) vs services en violation (> 7 deps) |

**Scoring** : 0-10. Consulter `references/scoring-derivation.md` section "Axe Couplage".

### 1.9 Axe Complexite (poids 10%)

Metriques :

| # | Metrique | Methode de detection |
|---|---------|---------------------|
| 1 | Complexite cyclomatique | Compter les branches par methode (`if`, `elseif`, `case`, `for`, `foreach`, `while`, `catch`, `&&`, `\|\|`, `?:`, `??`) |
| 2 | Classes trop longues | Fichiers PHP > 300 lignes dans `src/` |
| 3 | Nesting profond | Methodes avec indentation > 3 niveaux |

**Scoring** : 0-10 base sur le pourcentage de methodes simples (CC ≤ 10). Consulter `references/scoring-derivation.md` section "Axe Complexite".

## Phase 2 — Scoring consolide

### Formule (avec axe API actif)

```
score_global = (legacy * 0.12)
             + (tests * 0.13)
             + (security * 0.13)
             + (api * 0.08)
             + (architecture * 0.14)
             + (dead_code * 0.10)
             + (config * 0.10)
             + (coupling * 0.10)
             + (complexity * 0.10)
```

### Redistribution si axe API desactive

Si `api-platform/core` n'est pas installe, les 8% de l'axe API sont redistribues proportionnellement aux 8 autres axes. Chaque axe recoit `poids_original / 0.92`.

```
poids_redistribue = poids_original / 0.92
```

Ce qui donne :

| Axe | Poids normal | Poids sans API |
|-----|-------------|----------------|
| Legacy | 12% | 13.04% |
| Tests | 13% | 14.13% |
| Securite | 13% | 14.13% |
| Architecture | 14% | 15.22% |
| Code mort | 10% | 10.87% |
| Configuration | 10% | 10.87% |
| Couplage | 10% | 10.87% |
| Complexite | 10% | 10.87% |

> **Plafond** : le score de chaque axe est plafonne a 10.0 avant application de la ponderation. Le score global est egalement plafonne a 10.0.

### Grading

Grading : voir `skill-directives.md` table de grading universelle.

## Phase 3 — Dashboard

**Consulter `references/report-template.md`** pour les templates Markdown et HTML complets.

Le dashboard inclut :

1. **Score global** avec grade et barre visuelle ASCII ou SVG
2. **Tableau des 9 axes** : Axe | Score | Grade | Tendance | Problemes critiques
3. **Radar chart** : ASCII (Markdown) ou SVG (HTML) representant les 9 axes
4. **Top 10 problemes critiques** : tableau avec rang, axe, fichier, description, correction, skill recommande
5. **Matrice effort/impact** : tableau avec action, impact (haut/moyen/bas), effort (haut/moyen/bas)
6. **Section "Prochaines etapes"** : skills detailles a lancer selon les axes les plus faibles

### Format Markdown (defaut)

Generer le dashboard dans la console en suivant le template `references/report-template.md` section 1.

### Format HTML (--output=html)

Ecrire un fichier `docs/full-audit.html` autonome en suivant le template `references/report-template.md` section 2. Le fichier doit etre :
- 100% autonome (CSS inline, SVG inline, zero dependance externe)
- Responsive (CSS Grid, media queries)
- Imprimable (media queries pour l'impression)
- Avec des jauges SVG circulaires par axe

### Format resume (--summary)

Generer un resume compact en suivant le template `references/report-template.md` section 3.

## Phase 4 — Comparaison historique

Si un audit precedent est trouve dans `MEMORY.md` :

1. **Afficher la tendance par axe** :
   - Fleche haut si le score s'est ameliore de ≥ 0.5 point
   - Fleche bas si le score s'est degrade de ≥ 0.5 point
   - Stable si la variation est < 0.5 point
2. **Calculer le delta de score global** : afficher la difference numerique et le changement de grade eventuel
3. **Identifier les axes ameliores/degrades** : lister les axes avec le plus grand delta (positif et negatif)

Si aucun audit precedent n'existe, afficher "Premier audit — pas de comparaison disponible" et la tendance "—" pour chaque axe.

## Phase Finale — Mise a jour documentaire (OBLIGATOIRE)

Appliquer les obligations de `~/.claude/stacks/skill-directives.md` (Phase Finale).

Resume a persister dans `MEMORY.md` :
- Score global obtenu, grade, et date du scan
- Scores par axe (9 valeurs)
- Top 3 actions prioritaires identifiees
- Evolution par rapport au scan precedent (si disponible)

### Format standard pour MEMORY.md

Utiliser exactement ce format pour permettre la comparaison historique entre audits :

```
## full-audit (YYYY-MM-DD)
Score global : X.X/10 (Grade)
Legacy: X.X | Tests: X.X | Securite: X.X | API: X.X | Architecture: X.X | Code mort: X.X | Config: X.X | Couplage: X.X | Complexite: X.X
Top 3 actions : 1) ... 2) ... 3) ...
```

> Si l'axe API est desactive, indiquer `API: N/A` dans la ligne des scores.

## Prerequis recommandes

Aucun — ce skill **EST** le point d'entree recommande pour tout audit de projet.

Exploitation cross-skill : voir `skill-directives.md`.

## Skills complementaires

Apres le full-audit, suggerer les skills detailles selon les axes les plus faibles :

| Axe faible | Skill recommande |
|-----------|-----------------|
| Legacy ≤ 5 | `/migration-planner` |
| Tests ≤ 5 | `/test-auditor` |
| Securite ≤ 5 | `/security-auditor` |
| API ≤ 5 | `/api-auditor` |
| Architecture ≤ 5 | `/dependency-diagram` puis `/refactor` |
| Code mort ≤ 5 | `/dead-code-detector` |
| Configuration ≤ 5 | `/config-archeologist` |
| Couplage ≤ 5 | `/service-decoupler` |
| Complexite ≤ 5 | `/refactor` |

## Directives

Appliquer les directives communes de `skill-directives.md`.

Directives specifiques a full-audit :
- **Breadth over depth** : ce skill scanne rapidement tous les axes. Pour un audit detaille, utiliser le skill specialise. Ne pas passer plus de 2-3 minutes par axe.
- **Historique** : si un score precedent existe dans `MEMORY.md`, afficher la tendance pour chaque axe.
- **Consulter les references** : lire `references/scoring-derivation.md` pour les baremes detailles et `references/report-template.md` pour les templates.
