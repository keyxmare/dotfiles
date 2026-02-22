# Baremes de scoring — Full Audit

Ce fichier documente les baremes de scoring detailles pour chacun des 9 axes du full audit. Chaque axe est note sur 10, puis pondere dans le score global.

---

## Axe Legacy (12%)

### Metriques

| # | Metrique | Commande de scan | Poids |
|---|---------|-----------------|-------|
| 1 | Version PHP | `grep '"php"' composer.json` puis comparer la contrainte avec la version courante (8.5) | 25% |
| 2 | Version Symfony | `grep 'symfony/framework-bundle' composer.lock` puis extraire la version installee | 25% |
| 3 | Deprecations code | `grep -rn 'getDoctrine\|ContainerAware\|@Route\|@ORM\\\|EventSubscriberInterface\|\$defaultName\|MessageHandlerInterface' src/ --include='*.php'` | 30% |
| 4 | Packages outdated | Comparer les versions majeures dans `composer.lock` vs les dernieres stables connues pour les packages critiques (Symfony, Doctrine, PHPUnit, PHPStan) | 20% |

### Formule

```
score_legacy = (score_php * 0.25) + (score_symfony * 0.25) + (score_deprecations * 0.30) + (score_packages * 0.20)
```

### Bareme version PHP

| Version requise | Score |
|----------------|-------|
| ≥ 8.5 | 10 |
| 8.4 | 8 |
| 8.3 | 6 |
| 8.2 | 4 |
| 8.1 | 2 |
| < 8.1 | 0 |

### Bareme version Symfony

| Version installee | Score |
|------------------|-------|
| 8.x (courante) | 10 |
| 7.x (N-1) | 7 |
| 6.x (N-2) | 4 |
| 5.x (N-3) | 2 |
| < 5.x | 0 |

### Bareme deprecations code

| Nombre de deprecations | Score |
|----------------------|-------|
| 0 | 10 |
| 1-5 | 8 |
| 6-15 | 6 |
| 16-30 | 4 |
| 31-50 | 2 |
| > 50 | 0 |

### Bareme packages outdated

| Packages en retard majeur (> 2 versions) | Score |
|----------------------------------------|-------|
| 0 | 10 |
| 1-2 | 8 |
| 3-5 | 6 |
| 6-10 | 4 |
| > 10 | 2 |

---

## Axe Tests (13%)

### Metriques

| # | Metrique | Commande de scan | Poids |
|---|---------|-----------------|-------|
| 1 | Ratio couverture | Compter `src/**/*.php` (hors Entity, DTO, Event purs) vs `tests/**/*Test.php`. Si un rapport de couverture existe (`coverage/`), utiliser la valeur reelle. | 40% |
| 2 | Couverture par couche DDD | Verifier la presence de fichiers test dans `tests/Unit/Domain/`, `tests/Unit/Application/`, `tests/Integration/Infrastructure/` | 25% |
| 3 | Tests fantomes | `grep -rL 'assert\|expect\|should' tests/ --include='*Test.php'` pour trouver les fichiers de test sans assertions | 20% |
| 4 | Mutation testing | `grep -q 'infection/infection' composer.json && ls infection.json* 2>/dev/null` | 15% |

### Formule

```
score_tests = (score_ratio * 0.40) + (score_couches * 0.25) + (score_fantomes * 0.20) + (score_infection * 0.15)
```

### Bareme ratio couverture

| Couverture estimee | Score |
|-------------------|-------|
| ≥ 80% | 10 |
| 60-79% | 8 |
| 40-59% | 6 |
| 20-39% | 4 |
| < 20% | 2 |
| 0% (aucun test) | 0 |

### Bareme couverture par couche

| Couches testees | Score |
|----------------|-------|
| Domain + Application + Infrastructure | 10 |
| Domain + Application | 8 |
| Domain seul | 6 |
| Application ou Infrastructure seul | 4 |
| Aucune couche identifiable | 2 |

### Bareme tests fantomes

| % de tests sans assertion | Score |
|--------------------------|-------|
| 0% | 10 |
| 1-5% | 8 |
| 6-15% | 6 |
| 16-30% | 4 |
| > 30% | 2 |

### Bareme mutation testing

| Statut Infection | Score |
|-----------------|-------|
| Installe + configure + MSI ≥ 70% | 10 |
| Installe + configure | 7 |
| Installe mais pas configure | 4 |
| Non installe | 0 |

---

## Axe Securite (13%)

### Metriques

| # | Metrique | Commande de scan | Poids |
|---|---------|-----------------|-------|
| 1 | Injections SQL | `grep -rn "createQuery\|executeQuery" src/ --include='*.php'` puis verifier si les resultats contiennent des concatenations de variables vs `setParameter()` | 30% |
| 2 | XSS (raw Twig) | `grep -rn '\|raw' templates/` et `grep -rn 'autoescape false' templates/` | 20% |
| 3 | Secrets hardcodes | `grep -rn "password\s*=\s*['\"]\\|api_key\\|apiKey\\|secret_key\\|sk_live_\\|AKIA" src/ config/ --include='*.php' --include='*.yaml'` | 25% |
| 4 | Config security.yaml | Lire `config/packages/security.yaml` : verifier firewalls, password hashers, access control | 15% |
| 5 | CORS permissif | `grep -rn "allow_origin.*\\*" config/` | 10% |

### Formule

```
score_securite = 10 - (nb_critiques * 2) - (nb_warnings * 0.5)
```

Plancher a 0.

### Classification des severites

| Pattern | Severite | Impact score |
|---------|---------|-------------|
| Concatenation SQL avec variable | Critique | -2 |
| `\|raw` sur contenu utilisateur | Critique | -2 |
| Secret hardcode (cle API, mot de passe) | Critique | -2 |
| `allow_origin: ['*']` en production | Critique | -2 |
| Firewall `security: false` hors dev | Warning | -0.5 |
| Password hasher faible (md5, sha1) | Critique | -2 |
| Password hasher `auto` | OK | 0 |
| Pas d'access_control | Warning | -0.5 |
| `APP_DEBUG=1` dans `.env` sans `.env.local` | Warning | -0.5 |

### Bareme global securite

| Score | Signification |
|-------|--------------|
| 10 | Aucune vulnerabilite detectee |
| 8-9 | Quelques warnings mineurs |
| 6-7 | 1-2 vulnerabilites a corriger |
| 4-5 | Plusieurs vulnerabilites, dont des critiques |
| 2-3 | Nombreuses vulnerabilites critiques |
| 0-1 | Posture securite gravement deficiente |

---

## Axe API (8%, conditionnel)

> **Note** : cet axe est active SEULEMENT si `api-platform/core` est present dans `composer.json`. Si absent, son poids de 8% est redistribue proportionnellement aux 8 autres axes.

### Metriques

| # | Metrique | Commande de scan | Poids |
|---|---------|-----------------|-------|
| 1 | Entites exposees vs DTOs | `grep -rn '#\[ApiResource' src/ --include='*.php' -l` puis verifier si les fichiers sont des entites Doctrine (`#[ORM\Entity]`) ou des DTOs dedies | 30% |
| 2 | Groupes de serialisation | `grep -rn 'normalizationContext\|denormalizationContext' src/ --include='*.php'` vs nombre total de `#[ApiResource]` | 25% |
| 3 | Pagination | `grep -rn 'paginationEnabled\|pagination_enabled' src/ config/` et verifier la config globale dans `config/packages/api_platform.yaml` | 20% |
| 4 | Descriptions OpenAPI | `grep -rn 'description.*=.*["\x27]' src/ --include='*.php'` dans les fichiers contenant `#[ApiResource]` ou `#[ApiProperty]` | 25% |

### Formule

```
score_api = (score_dto * 0.30) + (score_groups * 0.25) + (score_pagination * 0.20) + (score_openapi * 0.25)
```

### Bareme entites vs DTOs

| % de ressources utilisant des DTOs | Score |
|----------------------------------|-------|
| 100% (toutes les ressources sont des DTOs) | 10 |
| 75-99% | 8 |
| 50-74% | 6 |
| 25-49% | 4 |
| < 25% (la plupart exposent l'entite directement) | 2 |

### Bareme groupes de serialisation

| % de ressources avec groupes configures | Score |
|----------------------------------------|-------|
| 100% | 10 |
| 75-99% | 8 |
| 50-74% | 6 |
| 25-49% | 4 |
| < 25% | 2 |

### Bareme pagination

| Configuration | Score |
|--------------|-------|
| Activee globalement + par ressource si necessaire | 10 |
| Activee globalement | 8 |
| Activee sur certaines ressources seulement | 5 |
| Desactivee partout | 2 |

### Bareme descriptions OpenAPI

| % de ressources/proprietes documentees | Score |
|---------------------------------------|-------|
| ≥ 80% | 10 |
| 60-79% | 8 |
| 40-59% | 6 |
| 20-39% | 4 |
| < 20% | 2 |

---

## Axe Architecture (14%)

### Metriques

| # | Metrique | Commande de scan | Poids |
|---|---------|-----------------|-------|
| 1 | Nombre de BCs | `ls -d src/*/` pour lister les dossiers de premier niveau (hors `Shared/`, `Common/`, `Kernel/`) | 5% (informatif) |
| 2 | Imports cross-BC | Pour chaque BC, `grep -rn '^use App\\' src/[BC]/ --include='*.php'` puis compter les imports venant d'autres BCs (hors `Shared`) | 25% |
| 3 | Cycles de dependances | Construire le graphe d'imports inter-BC et detecter les cycles (A → B → A, ou A → B → C → A) | 20% |
| 4 | Violations DDD | `grep -rn '^use App\\.*\\Infrastructure\\' src/*/Domain/ --include='*.php'` et `grep -rn '^use App\\.*\\Application\\' src/*/Domain/ --include='*.php'` | 20% |
| 5 | Taille Shared Kernel | Compter les fichiers dans `src/Shared/` (ou `src/Common/`) vs total `src/`. Ratio > 30% = Shared Kernel trop gros | 10% |
| 6 | Conformite DDD (VO) | `find src/ -path "*/ValueObject/*" -name "*.php"` et `find src/ -path "*/Domain/Model/*" -name "*.php"` puis calculer le ratio VO/entites | 10% |
| 7 | Purete Domain | `grep -rln 'use Symfony\|use Doctrine\|use ApiPlatform' src/*/Domain/ --include='*.php'` vs total fichiers Domain | 10% |
| 8 | Domain Events | `find src/ -path "*/Domain/Event/*Event.php"` et verifier l'existence de handlers cross-BC | 5% |
| 9 | Repository Interfaces | `find src/*/Domain/ -name "*RepositoryInterface.php"` vs `find src/*/Infrastructure/ -name "*Repository.php"` | 5% |

### Formule

```
score_architecture = (score_cross_bc * 0.25) + (score_cycles * 0.20) + (score_violations * 0.20) + (score_shared * 0.10) + (score_vo * 0.10) + (score_purete * 0.10) + (score_events * 0.05) + (score_repo_interfaces * 0.05) + bonus_bc
```

Note : `bonus_bc` = +0.5 si ≥ 3 BCs identifies (architecture modulaire). Ce bonus est informatif et ne penalise pas les petits projets.

### Bareme imports cross-BC

| Ratio cross-BC / total | Score |
|----------------------|-------|
| < 5% | 10 |
| 5-10% | 8 |
| 10-20% | 6 |
| 20-35% | 4 |
| > 35% | 2 |

### Bareme cycles de dependances

| Nombre de cycles | Score |
|-----------------|-------|
| 0 | 10 |
| 1 | 6 |
| 2 | 4 |
| 3+ | 2 |

### Bareme violations DDD

| Nombre de violations | Score |
|--------------------|-------|
| 0 | 10 |
| 1-3 | 7 |
| 4-8 | 5 |
| 9-15 | 3 |
| > 15 | 1 |

### Bareme taille Shared Kernel

| % de fichiers dans Shared | Score |
|--------------------------|-------|
| < 10% | 10 |
| 10-20% | 8 |
| 20-30% | 6 |
| 30-40% | 4 |
| > 40% | 2 |

### Bareme conformite DDD — Value Objects

| Ratio VO / entites | Score |
|-------------------|-------|
| > 0.5 | 10 |
| 0.3-0.5 | 8 |
| 0.1-0.3 | 6 |
| 1-3 VO (ratio < 0.1) | 4 |
| 0 VO | 0 |

### Bareme conformite DDD — Purete Domain

| % fichiers Domain sans import framework | Score |
|----------------------------------------|-------|
| 100% | 10 |
| > 90% | 8 |
| > 70% | 6 |
| > 50% | 4 |
| < 50% | 2 |

### Bareme conformite DDD — Domain Events

| Statut | Score |
|--------|-------|
| Events + handlers cross-BC | 10 |
| Events utilises (meme BC) | 7 |
| Events declares mais non utilises | 4 |
| Aucun Domain Event | 0 |

### Bareme conformite DDD — Repository Interfaces

| % de repos avec interface dans Domain | Score |
|--------------------------------------|-------|
| 100% | 10 |
| > 50% | 7 |
| > 25% | 4 |
| < 25% | 2 |

### Adaptation sans DDD

Si le projet n'a pas de structure DDD identifiable (pas de dossiers Domain/Application/Infrastructure, un seul namespace racine), adapter :
- Ignorer les violations DDD (score = 10 par defaut)
- Evaluer le couplage au niveau des namespaces/modules
- Les sous-metriques de conformite DDD sont scorees a 5/10 par defaut (neutre)
- Signaler dans le rapport que l'axe a ete adapte

---

## Axe Code mort (10%)

### Metriques

| # | Metrique | Commande de scan | Poids |
|---|---------|-----------------|-------|
| 1 | Services orphelins | Pour chaque classe dans `src/` qui n'est ni une entite, ni un DTO, ni une interface : verifier si son FQCN apparait dans un `use` statement ailleurs. `grep -rn 'use App\\...\ClassName' src/ --include='*.php'` | 35% |
| 2 | Interfaces sans implementation | Lister les fichiers `*Interface.php` dans `src/`, puis pour chacun verifier `grep -rn 'implements.*InterfaceName' src/ --include='*.php'` | 25% |
| 3 | Routes mortes | Lister les routes via `grep -rn '#\[Route' src/ --include='*.php'`, verifier que les classes de controllers existent et ne sont pas vides | 20% |
| 4 | Commandes orphelines | Lister les classes qui etendent `Command` via `grep -rn 'extends Command' src/ --include='*.php'`, verifier qu'elles ont un attribut `#[AsCommand]` ou `$defaultName` | 20% |

### Formule

```
score_code_mort = 10 - (pct_code_mort * 10)
```

Ou `pct_code_mort` est le ratio de fichiers identifies comme morts vs fichiers totaux scannes. Plancher a 0.

### Bareme

| % de code mort | Score |
|---------------|-------|
| 0% | 10 |
| 1-3% | 8 |
| 4-8% | 6 |
| 9-15% | 4 |
| 16-25% | 2 |
| > 25% | 0 |

### Exclusions

Ne pas compter comme code mort :
- Les entites Doctrine (utilisees par le mapping, pas par des `use` explicites)
- Les DTOs de serialisation (utilises par API Platform via les groupes)
- Les Event classes (dispatchees dynamiquement)
- Les Voter classes (enregistrees via autoconfigure)
- Les interfaces de Repository dans le Domain (injectees via alias)
- Les Fixtures et les DataProviders de test

---

## Axe Configuration (10%)

### Metriques

| # | Metrique | Commande de scan | Poids |
|---|---------|-----------------|-------|
| 1 | Doublons autodiscovery | Lire `config/services.yaml` : extraire les declarations de services explicites, puis verifier si elles sont couvertes par le bloc `resource: '../src/'` autodiscovery | 30% |
| 2 | Bundles non configures | Lire `composer.json` pour les packages Symfony (`symfony/*-bundle`, `*/*-bundle`), puis verifier si un fichier de config existe dans `config/packages/` pour chaque bundle | 25% |
| 3 | Variables env orphelines | Lire `.env` pour les variables definies, puis `grep -rn 'ENV_VAR_NAME' config/ src/ --include='*.yaml' --include='*.php'` pour verifier qu'elles sont utilisees | 25% |
| 4 | Config morte | Lister les fichiers dans `config/packages/`, verifier que le bundle correspondant est installe dans `composer.json` | 20% |

### Formule

```
score_config = 10 - (doublons * 0.3) - (bundles_non_configures * 0.5) - (vars_orphelines * 0.3) - (config_morte * 0.5)
```

Plancher a 0.

### Bareme doublons autodiscovery

| Nombre de doublons | Impact |
|-------------------|--------|
| 0 | 0 (pas de malus) |
| 1-3 | -0.3 par doublon |
| 4-8 | -0.2 par doublon supplementaire |
| > 8 | Plafonner le malus a -3 |

### Bareme bundles non configures

| Nombre de bundles non configures | Impact |
|--------------------------------|--------|
| 0 | 0 |
| 1-2 | -0.5 par bundle |
| 3+ | -0.3 par bundle supplementaire |
| Max malus | -3 |

### Bareme variables env orphelines

| Nombre de variables orphelines | Impact |
|------------------------------|--------|
| 0 | 0 |
| 1-3 | -0.3 par variable |
| 4+ | -0.2 par variable supplementaire |
| Max malus | -2 |

### Bareme config morte

| Nombre de fichiers config morts | Impact |
|-------------------------------|--------|
| 0 | 0 |
| 1-2 | -0.5 par fichier |
| 3+ | -0.3 par fichier supplementaire |
| Max malus | -2 |

---

## Axe Couplage services (10%)

### Metriques

| # | Metrique | Commande de scan | Poids |
|---|---------|-----------------|-------|
| 1 | God services (> 7 deps) | Scanner les constructeurs : `grep -A 20 '__construct(' src/ --include='*.php'` puis compter les parametres types | 40% |
| 2 | Dependance max | Parmi tous les constructeurs, identifier celui avec le plus de parametres | 20% |
| 3 | Ratio SRP | Proportion de services avec ≤ 4 deps (OK) vs total de services | 40% |

### Formule

```
score_couplage = (score_god * 0.40) + (score_max * 0.20) + (score_ratio * 0.40)
```

### Bareme god services

| % de god services (> 7 deps) | Score |
|-----------------------------|-------|
| 0% | 10 |
| 1-5% | 8 |
| 6-10% | 6 |
| 11-20% | 4 |
| > 20% | 2 |

### Bareme dependance max

| Dependances du plus gros service | Score |
|--------------------------------|-------|
| ≤ 5 | 10 |
| 6-7 | 8 |
| 8-10 | 6 |
| 11-15 | 4 |
| > 15 | 2 |

### Bareme ratio SRP

| % de services avec ≤ 4 deps | Score |
|----------------------------|-------|
| ≥ 90% | 10 |
| 75-89% | 8 |
| 60-74% | 6 |
| 40-59% | 4 |
| < 40% | 2 |

### Categories de services

| Dependances constructeur | Categorie | Verdict |
|------------------------|-----------|---------|
| ≤ 4 | Lean | OK |
| 5-7 | Charge | Warning |
| 8-10 | Surcharge | Probleme |
| > 10 | God service | Critique |

---

## Axe Complexite (10%)

### Metriques

| # | Metrique | Commande de scan | Poids |
|---|---------|-----------------|-------|
| 1 | Methodes simples | Compter les branches par methode (`if`, `elseif`, `case`, `for`, `foreach`, `while`, `catch`, `&&`, `\|\|`, `?:`, `??`) — methode simple si CC ≤ 10 | 50% |
| 2 | Classes trop longues | `find src/ -name "*.php" -exec wc -l {} \;` puis filtrer > 300 lignes | 25% |
| 3 | Nesting profond | Detecter les methodes avec indentation > 3 niveaux (16+ espaces) | 25% |

### Formule

```
score_complexite = (score_methodes_simples * 0.50) + (score_classes_longues * 0.25) + (score_nesting * 0.25)
```

### Bareme methodes simples (CC)

| % de methodes avec CC ≤ 10 | Score |
|---------------------------|-------|
| > 95% | 10 |
| 85-95% | 8 |
| 70-85% | 6 |
| 50-70% | 4 |
| < 50% | 2 |

### Bareme classes trop longues

| Nombre de classes > 300 lignes | Score |
|-------------------------------|-------|
| 0 | 10 |
| 1-3 | 8 |
| 4-8 | 6 |
| 9-15 | 4 |
| > 15 | 2 |

### Bareme nesting profond

| Nombre de methodes avec nesting > 3 | Score |
|-------------------------------------|-------|
| 0 | 10 |
| 1-5 | 8 |
| 6-15 | 6 |
| 16-30 | 4 |
| > 30 | 2 |

---

## Score global

### Formule avec API Platform

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

### Formule sans API Platform

Redistribuer les 8% de l'axe API proportionnellement :

```
factor = 1 / 0.92

score_global = (legacy * 0.12 * factor)
             + (tests * 0.13 * factor)
             + (security * 0.13 * factor)
             + (architecture * 0.14 * factor)
             + (dead_code * 0.10 * factor)
             + (config * 0.10 * factor)
             + (coupling * 0.10 * factor)
             + (complexity * 0.10 * factor)
```

### Grading

Voir `skill-directives.md` table de grading universelle.

### Tendances (comparaison historique)

| Delta | Symbole | Signification |
|-------|---------|--------------|
| ≥ +0.5 | haut | Amelioration significative |
| -0.5 a +0.5 | stable | Pas de changement notable |
| ≤ -0.5 | bas | Degradation significative |

### Priorite des actions correctives

| Impact \ Effort | Bas | Moyen | Haut |
|----------------|-----|-------|------|
| **Haut** | Priorite 1 (quick win) | Priorite 2 | Priorite 3 |
| **Moyen** | Priorite 2 | Priorite 3 | Priorite 4 |
| **Bas** | Priorite 3 | Priorite 4 | Priorite 5 (optionnel) |
