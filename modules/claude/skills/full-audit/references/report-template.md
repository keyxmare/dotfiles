# Templates de rapport — Full Audit

## Section 1 : Template Markdown (--output=markdown)

```markdown
# Full Audit — [Nom du projet]

> Scan du [date] · Scope : [scope] · PHP [version_php] · Symfony [version_symfony] · [X] fichiers analyses

---

## Score Global : [GRADE] ([score]/10)

[██████████░░░░░░░░░░] 7.8/10 — B

---

## Tableau des axes

| # | Axe | Score | Grade | Tendance | Problemes critiques |
|---|-----|-------|-------|----------|---------------------|
| 1 | Legacy | X.X/10 | [GRADE] | [tendance] | X |
| 2 | Tests | X.X/10 | [GRADE] | [tendance] | X |
| 3 | Securite | X.X/10 | [GRADE] | [tendance] | X |
| 4 | API | X.X/10 | [GRADE] | [tendance] | X |
| 5 | Architecture | X.X/10 | [GRADE] | [tendance] | X |
| 6 | Code mort | X.X/10 | [GRADE] | [tendance] | X |
| 7 | Configuration | X.X/10 | [GRADE] | [tendance] | X |
| 8 | Couplage | X.X/10 | [GRADE] | [tendance] | X |
| 9 | Complexite | X.X/10 | [GRADE] | [tendance] | X |

> Tendance : amelioration (+X.X) / degradation (-X.X) / stable (=) / premier audit (—)

---

## Radar Chart

```
                  Legacy (X.X)
                     *
                  *     *
   Couplage    *           *    Tests
    (X.X)   *                 *  (X.X)
            *                 *
   Config   *                 *   Securite
    (X.X)    *               *     (X.X)
               *           *
   Code mort    *         *   API
    (X.X)       *       *      (X.X)
             *     *  *
  Complexite    *  *      Architecture
    (X.X)                    (X.X)
```

> Note : les extremites de chaque branche representent 10/10. Plus le point est proche du centre, plus le score est faible.

---

## Legacy (X.X/10 — [GRADE])

| Metrique | Valeur | Score |
|---------|--------|-------|
| Version PHP | X.X | X/10 |
| Version Symfony | X.X | X/10 |
| Deprecations detectees | X | X/10 |
| Packages outdated | X | X/10 |

**Problemes identifies :**
- [description du probleme + fichier(s) concerne(s)]

---

## Tests (X.X/10 — [GRADE])

| Metrique | Valeur | Score |
|---------|--------|-------|
| Ratio fichiers testes | X/X (X%) | X/10 |
| Domain teste | oui/non | +X |
| Application teste | oui/non | +X |
| Infrastructure teste | oui/non | +X |
| Tests fantomes | X | -X |
| Infection configure | oui/non | +X |

**Problemes identifies :**
- [description du probleme]

---

## Securite (X.X/10 — [GRADE])

| Metrique | Valeur | Impact |
|---------|--------|--------|
| Injections SQL | X | -X |
| XSS (raw Twig) | X | -X |
| Secrets hardcodes | X | -X |
| Config security.yaml | OK/KO | -X |
| CORS permissif | oui/non | -X |

**Problemes identifies :**
- [description + fichier:ligne]

---

## API (X.X/10 — [GRADE])

> Axe conditionnel : actif si API Platform est installe.

| Metrique | Valeur | Score |
|---------|--------|-------|
| Entites exposees directement | X/X | X/10 |
| Groupes de serialisation | X% configures | X/10 |
| Pagination | activee/desactivee | X/10 |
| Descriptions OpenAPI | X% presentes | X/10 |

**Problemes identifies :**
- [description]

---

## Architecture (X.X/10 — [GRADE])

| Metrique | Valeur | Score |
|---------|--------|-------|
| Bounded Contexts | X | — |
| Imports cross-BC | X (X%) | X/10 |
| Cycles de dependances | X | -X |
| Violations DDD | X | -X |
| Shared Kernel | X% | X/10 |

**Problemes identifies :**
- [description + fichiers]

---

## Code mort (X.X/10 — [GRADE])

| Metrique | Valeur | Score |
|---------|--------|-------|
| Services orphelins | X | -X |
| Interfaces sans implementation | X | -X |
| Routes mortes | X | -X |
| Commandes non referencees | X | -X |

**Problemes identifies :**
- [description + fichiers]

---

## Configuration (X.X/10 — [GRADE])

| Metrique | Valeur | Score |
|---------|--------|-------|
| Doublons autodiscovery | X | -X |
| Bundles non configures | X | -X |
| Variables env orphelines | X | -X |
| Config morte | X | -X |

**Problemes identifies :**
- [description + fichiers]

---

## Couplage services (X.X/10 — [GRADE])

| Metrique | Valeur | Score |
|---------|--------|-------|
| God services (> 7 deps) | X | X/10 |
| Dependance max | X deps (NomDuService) | — |
| Ratio services OK | X% | X/10 |

**Top 5 — Services les plus couples :**

| # | Service | Dependances | BC |
|---|---------|-------------|-----|
| 1 | `App\...` | X | ... |

---

## Complexite (X.X/10 — [GRADE])

| Metrique | Valeur | Score |
|---------|--------|-------|
| Methodes simples (CC ≤ 10) | X% | X/10 |
| Classes > 300 lignes | X | X/10 |
| Methodes nesting > 3 | X | X/10 |

**Top 5 — Methodes les plus complexes :**

| # | Methode | CC | Lignes | Fichier |
|---|---------|-----|--------|---------|
| 1 | `Class::method()` | 35 | 120 | `src/...` |

**Classes les plus longues :**

| # | Classe | Lignes | BC |
|---|--------|--------|-----|
| 1 | `App\...` | 850 | ... |

---

## Top 10 problemes critiques

| # | Axe | Fichier | Description | Correction suggeree | Skill |
|---|-----|---------|-------------|---------------------|-------|
| 1 | Securite | `src/...` | Injection SQL par concatenation | Utiliser setParameter() | `/security-auditor` |
| 2 | Tests | — | Couche Domain non testee | Ajouter des tests unitaires Domain | `/test-auditor` |
| 3 | Legacy | `composer.json` | PHP 8.1 (EOL) | Upgrader vers PHP 8.5 | `/migration-planner` |
| 4 | ... | ... | ... | ... | ... |

---

## Matrice effort/impact

| # | Action | Impact | Effort | Priorite |
|---|--------|--------|--------|----------|
| 1 | Corriger les injections SQL | Haut | Bas | Haute |
| 2 | Ajouter les tests Domain | Haut | Moyen | Haute |
| 3 | Upgrader PHP | Haut | Haut | Moyenne |
| 4 | Supprimer le code mort | Moyen | Bas | Moyenne |
| 5 | Configurer les headers de securite | Moyen | Bas | Moyenne |
| 6 | Refactorer les god services | Haut | Haut | Moyenne |
| 7 | ... | ... | ... | ... |

---

## Prochaines etapes

Les axes suivants meritent un audit approfondi avec le skill dedie :

1. **[Axe le plus faible]** (X.X/10) → Lancer `/[skill]` pour un diagnostic detaille
2. **[Deuxieme axe]** (X.X/10) → Lancer `/[skill]`
3. **[Troisieme axe]** (X.X/10) → Lancer `/[skill]`

---

> Genere par `/full-audit` — Claude Code
```

---

## Section 2 : Template HTML (--output=html)

### Specification du template HTML

Le skill doit generer un fichier `docs/full-audit.html` en remplacant les placeholders par les valeurs calculees. Le mecanisme est un simple **search-and-replace** de chaines de caracteres, sans moteur de templates externe.

**Syntaxe des placeholders :**

- **Variables simples** : `{{VARIABLE_NAME}}` — remplacees par la valeur correspondante (texte, nombre, HTML).
- **Blocs conditionnels** : `{{#IF_CONDITION}}...{{/IF_CONDITION}}` — le bloc entier (balises incluses) est conserve si la condition est vraie, ou supprime integralement si elle est fausse.

**Variables obligatoires** (le template ne fonctionne pas sans elles) :

| Variable | Type | Description |
|----------|------|-------------|
| `{{PROJECT_NAME}}` | string | Nom du projet |
| `{{DATE}}` | string | Date du scan (YYYY-MM-DD) |
| `{{SCOPE}}` | string | Scope analyse |
| `{{PHP_VERSION}}` | string | Version PHP detectee |
| `{{SYMFONY_VERSION}}` | string | Version Symfony detectee |
| `{{FILES_COUNT}}` | number | Nombre total de fichiers analyses |
| `{{GLOBAL_SCORE}}` | number | Score global (X.X) |
| `{{GLOBAL_SCORE_PCT}}` | number | Score global en pourcentage (score * 10) |
| `{{GRADE}}` | string | Grade global (A-F) |
| `{{AXE_*_SCORE}}` | number | Score de chaque axe (remplacer * par LEGACY, TESTS, SECURITY, API, ARCH, DEAD, CONFIG, COUPLING, COMPLEXITY) |
| `{{AXE_*_GRADE}}` | string | Grade de chaque axe (A-F) |
| `{{TOP_10_ROWS}}` | HTML | Lignes `<tr>` du tableau top 10 problemes |
| `{{MATRIX_ROWS}}` | HTML | Lignes `<tr>` de la matrice effort/impact |
| `{{NEXT_STEPS}}` | HTML | Contenu HTML des prochaines etapes |

**Variables optionnelles** (le template fonctionne avec des valeurs vides) :

| Variable | Type | Description |
|----------|------|-------------|
| `{{TREND_SECTION}}` | HTML | Section tendance (vide si premier audit) |
| `{{AXE_*_TREND}}` | HTML | Tendance par axe (`<span class="up">+1.2</span>` ou vide) |
| `{{AXE_*_DETAILS}}` | HTML | Contenu detaille de chaque axe (tableaux, listes) |
| Metriques specifiques (`{{LEGACY_PHP_VERSION}}`, `{{TESTS_COVERAGE}}`, etc.) | string/number | Metriques affichees dans les cartes |

**Bloc conditionnel :**

| Condition | Semantique |
|-----------|-----------|
| `{{#IF_API_ENABLED}}...{{/IF_API_ENABLED}}` | Inclure le bloc seulement si API Platform est installe dans le projet |

```html
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Full Audit — {{PROJECT_NAME}}</title>
    <style>
        /* ===== Reset & Base ===== */
        *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, sans-serif;
            background: #f5f7fa;
            color: #1a1a2e;
            line-height: 1.6;
            padding: 2rem;
        }

        /* ===== Colors by grade ===== */
        .grade-A { --grade-color: #22c55e; --grade-bg: #f0fdf4; }
        .grade-B { --grade-color: #3b82f6; --grade-bg: #eff6ff; }
        .grade-C { --grade-color: #eab308; --grade-bg: #fefce8; }
        .grade-D { --grade-color: #f97316; --grade-bg: #fff7ed; }
        .grade-F { --grade-color: #ef4444; --grade-bg: #fef2f2; }

        /* ===== Layout ===== */
        .container { max-width: 1200px; margin: 0 auto; }

        /* ===== Header ===== */
        .header {
            background: white;
            border-radius: 16px;
            padding: 2rem;
            margin-bottom: 2rem;
            box-shadow: 0 1px 3px rgba(0,0,0,0.08);
            display: flex;
            align-items: center;
            gap: 2rem;
            flex-wrap: wrap;
        }
        .header-info { flex: 1; min-width: 250px; }
        .header-info h1 { font-size: 1.5rem; margin-bottom: 0.25rem; }
        .header-info .meta { color: #6b7280; font-size: 0.9rem; }
        .header-gauge { flex-shrink: 0; }

        /* ===== SVG Gauge ===== */
        .gauge-svg { width: 140px; height: 140px; }
        .gauge-bg { fill: none; stroke: #e5e7eb; stroke-width: 3; }
        .gauge-fill { fill: none; stroke-width: 3; stroke-linecap: round; transition: stroke-dasharray 0.6s ease; }
        .gauge-text { font-size: 8px; font-weight: 700; text-anchor: middle; dominant-baseline: central; }
        .gauge-label { font-size: 3.5px; font-weight: 400; fill: #6b7280; text-anchor: middle; }
        .gauge-score { font-size: 4px; fill: #6b7280; text-anchor: middle; }

        /* ===== Cards Grid ===== */
        .axes-grid {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(260px, 1fr));
            gap: 1rem;
            margin-bottom: 2rem;
        }
        .card {
            background: white;
            border-radius: 12px;
            padding: 1.5rem;
            box-shadow: 0 1px 3px rgba(0,0,0,0.08);
            border-left: 4px solid var(--grade-color, #e5e7eb);
        }
        .card-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 1rem;
        }
        .card-title { font-size: 1rem; font-weight: 600; }
        .card-grade {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            width: 36px; height: 36px;
            border-radius: 50%;
            font-weight: 700;
            font-size: 1rem;
            color: white;
            background: var(--grade-color);
        }
        .card-score { font-size: 1.5rem; font-weight: 700; color: var(--grade-color); margin-bottom: 0.5rem; }
        .card-trend { font-size: 0.85rem; color: #6b7280; margin-bottom: 0.75rem; }
        .card-trend .up { color: #22c55e; }
        .card-trend .down { color: #ef4444; }
        .card-trend .stable { color: #6b7280; }
        .card-metrics { list-style: none; font-size: 0.85rem; }
        .card-metrics li { padding: 0.2rem 0; border-bottom: 1px solid #f3f4f6; }
        .card-metrics li:last-child { border-bottom: none; }

        .mini-gauge { width: 60px; height: 60px; }

        /* ===== Details sections ===== */
        .details-section {
            background: white;
            border-radius: 12px;
            margin-bottom: 1rem;
            box-shadow: 0 1px 3px rgba(0,0,0,0.08);
            overflow: hidden;
        }
        .details-section summary {
            padding: 1rem 1.5rem;
            font-weight: 600;
            cursor: pointer;
            display: flex;
            align-items: center;
            gap: 0.75rem;
            border-left: 4px solid var(--grade-color, #e5e7eb);
        }
        .details-section summary:hover { background: #f9fafb; }
        .details-section[open] summary { border-bottom: 1px solid #e5e7eb; }
        .details-content { padding: 1.5rem; }
        .details-section .badge {
            display: inline-block;
            padding: 0.15rem 0.5rem;
            border-radius: 99px;
            font-size: 0.75rem;
            font-weight: 600;
            color: white;
            background: var(--grade-color);
        }

        /* ===== Tables ===== */
        table { width: 100%; border-collapse: collapse; font-size: 0.9rem; margin: 1rem 0; }
        th { text-align: left; padding: 0.6rem 0.75rem; background: #f9fafb; border-bottom: 2px solid #e5e7eb; font-weight: 600; }
        td { padding: 0.6rem 0.75rem; border-bottom: 1px solid #f3f4f6; }
        tr:hover td { background: #f9fafb; }
        .severity-critical { color: #ef4444; font-weight: 600; }
        .severity-high { color: #f97316; font-weight: 600; }
        .severity-medium { color: #eab308; }
        .severity-info { color: #6b7280; }

        /* ===== Impact matrix ===== */
        .matrix-high { color: #ef4444; font-weight: 600; }
        .matrix-medium { color: #f97316; }
        .matrix-low { color: #22c55e; }

        /* ===== Actions section ===== */
        .actions-section {
            background: white;
            border-radius: 12px;
            padding: 1.5rem;
            margin-bottom: 2rem;
            box-shadow: 0 1px 3px rgba(0,0,0,0.08);
        }
        .actions-section h2 { font-size: 1.25rem; margin-bottom: 1rem; }
        .action-item {
            display: flex;
            align-items: flex-start;
            gap: 0.75rem;
            padding: 0.75rem 0;
            border-bottom: 1px solid #f3f4f6;
        }
        .action-item:last-child { border-bottom: none; }
        .action-number {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            width: 28px; height: 28px;
            border-radius: 50%;
            background: #f3f4f6;
            font-weight: 600;
            font-size: 0.85rem;
            flex-shrink: 0;
        }
        .action-text { flex: 1; }
        .action-skill { font-size: 0.8rem; color: #6b7280; }

        /* ===== Footer ===== */
        .footer {
            text-align: center;
            padding: 1.5rem;
            color: #9ca3af;
            font-size: 0.8rem;
        }

        /* ===== Print ===== */
        @media print {
            body { background: white; padding: 0; }
            .header, .card, .details-section, .actions-section { box-shadow: none; break-inside: avoid; }
            .details-section { border: 1px solid #e5e7eb; }
            .details-section[open] { break-inside: auto; }
        }

        /* ===== Responsive ===== */
        @media (max-width: 640px) {
            body { padding: 1rem; }
            .header { flex-direction: column; text-align: center; }
            .axes-grid { grid-template-columns: 1fr; }
        }
    </style>
</head>
<body>
<div class="container">

    <!-- ===== HEADER ===== -->
    <header class="header grade-{{GRADE}}">
        <div class="header-gauge">
            <svg class="gauge-svg" viewBox="0 0 36 36">
                <path class="gauge-bg"
                      d="M18 2.0845 a 15.9155 15.9155 0 0 1 0 31.831 a 15.9155 15.9155 0 0 1 0 -31.831"/>
                <path class="gauge-fill"
                      d="M18 2.0845 a 15.9155 15.9155 0 0 1 0 31.831 a 15.9155 15.9155 0 0 1 0 -31.831"
                      stroke="var(--grade-color)"
                      stroke-dasharray="{{GLOBAL_SCORE_PCT}}, 100"/>
                <text x="18" y="17" class="gauge-text" fill="var(--grade-color)">{{GRADE}}</text>
                <text x="18" y="22" class="gauge-score">{{GLOBAL_SCORE}}/10</text>
                <text x="18" y="26" class="gauge-label">Score global</text>
            </svg>
        </div>
        <div class="header-info">
            <h1>Full Audit — {{PROJECT_NAME}}</h1>
            <p class="meta">
                {{DATE}} · Scope : {{SCOPE}} · PHP {{PHP_VERSION}} · Symfony {{SYMFONY_VERSION}} · {{FILES_COUNT}} fichiers
            </p>
            {{TREND_SECTION}}
        </div>
    </header>

    <!-- ===== AXES GRID ===== -->
    <section class="axes-grid">

        <!-- Card Legacy -->
        <div class="card grade-{{AXE_LEGACY_GRADE}}">
            <div class="card-header">
                <span class="card-title">Legacy</span>
                <span class="card-grade">{{AXE_LEGACY_GRADE}}</span>
            </div>
            <div class="card-score">{{AXE_LEGACY_SCORE}}/10</div>
            <div class="card-trend">{{AXE_LEGACY_TREND}}</div>
            <ul class="card-metrics">
                <li>PHP : {{LEGACY_PHP_VERSION}}</li>
                <li>Symfony : {{LEGACY_SF_VERSION}}</li>
                <li>Deprecations : {{LEGACY_DEPRECATIONS_COUNT}}</li>
            </ul>
        </div>

        <!-- Card Tests -->
        <div class="card grade-{{AXE_TESTS_GRADE}}">
            <div class="card-header">
                <span class="card-title">Tests</span>
                <span class="card-grade">{{AXE_TESTS_GRADE}}</span>
            </div>
            <div class="card-score">{{AXE_TESTS_SCORE}}/10</div>
            <div class="card-trend">{{AXE_TESTS_TREND}}</div>
            <ul class="card-metrics">
                <li>Couverture estimee : {{TESTS_COVERAGE}}%</li>
                <li>Tests fantomes : {{TESTS_GHOST_COUNT}}</li>
                <li>Infection : {{TESTS_INFECTION}}</li>
            </ul>
        </div>

        <!-- Card Securite -->
        <div class="card grade-{{AXE_SECURITY_GRADE}}">
            <div class="card-header">
                <span class="card-title">Securite</span>
                <span class="card-grade">{{AXE_SECURITY_GRADE}}</span>
            </div>
            <div class="card-score">{{AXE_SECURITY_SCORE}}/10</div>
            <div class="card-trend">{{AXE_SECURITY_TREND}}</div>
            <ul class="card-metrics">
                <li>Vulnerabilites critiques : {{SECURITY_CRITICAL_COUNT}}</li>
                <li>Warnings : {{SECURITY_WARNING_COUNT}}</li>
                <li>Secrets hardcodes : {{SECURITY_SECRETS_COUNT}}</li>
            </ul>
        </div>

        <!-- Card API (conditionnel) -->
        {{#IF_API_ENABLED}}
        <div class="card grade-{{AXE_API_GRADE}}">
            <div class="card-header">
                <span class="card-title">API</span>
                <span class="card-grade">{{AXE_API_GRADE}}</span>
            </div>
            <div class="card-score">{{AXE_API_SCORE}}/10</div>
            <div class="card-trend">{{AXE_API_TREND}}</div>
            <ul class="card-metrics">
                <li>Entites exposees : {{API_ENTITIES_EXPOSED}}</li>
                <li>Groupes serialisation : {{API_GROUPS_PCT}}%</li>
                <li>Descriptions OpenAPI : {{API_OPENAPI_PCT}}%</li>
            </ul>
        </div>
        {{/IF_API_ENABLED}}

        <!-- Card Architecture -->
        <div class="card grade-{{AXE_ARCH_GRADE}}">
            <div class="card-header">
                <span class="card-title">Architecture</span>
                <span class="card-grade">{{AXE_ARCH_GRADE}}</span>
            </div>
            <div class="card-score">{{AXE_ARCH_SCORE}}/10</div>
            <div class="card-trend">{{AXE_ARCH_TREND}}</div>
            <ul class="card-metrics">
                <li>Bounded Contexts : {{ARCH_BC_COUNT}}</li>
                <li>Imports cross-BC : {{ARCH_CROSS_BC_PCT}}%</li>
                <li>Violations DDD : {{ARCH_VIOLATIONS_COUNT}}</li>
            </ul>
        </div>

        <!-- Card Code mort -->
        <div class="card grade-{{AXE_DEAD_GRADE}}">
            <div class="card-header">
                <span class="card-title">Code mort</span>
                <span class="card-grade">{{AXE_DEAD_GRADE}}</span>
            </div>
            <div class="card-score">{{AXE_DEAD_SCORE}}/10</div>
            <div class="card-trend">{{AXE_DEAD_TREND}}</div>
            <ul class="card-metrics">
                <li>Services orphelins : {{DEAD_ORPHAN_SERVICES}}</li>
                <li>Interfaces mortes : {{DEAD_INTERFACES}}</li>
                <li>Routes mortes : {{DEAD_ROUTES}}</li>
            </ul>
        </div>

        <!-- Card Configuration -->
        <div class="card grade-{{AXE_CONFIG_GRADE}}">
            <div class="card-header">
                <span class="card-title">Configuration</span>
                <span class="card-grade">{{AXE_CONFIG_GRADE}}</span>
            </div>
            <div class="card-score">{{AXE_CONFIG_SCORE}}/10</div>
            <div class="card-trend">{{AXE_CONFIG_TREND}}</div>
            <ul class="card-metrics">
                <li>Doublons autodiscovery : {{CONFIG_DUPLICATES}}</li>
                <li>Variables orphelines : {{CONFIG_ORPHAN_VARS}}</li>
                <li>Config morte : {{CONFIG_DEAD}}</li>
            </ul>
        </div>

        <!-- Card Couplage -->
        <div class="card grade-{{AXE_COUPLING_GRADE}}">
            <div class="card-header">
                <span class="card-title">Couplage</span>
                <span class="card-grade">{{AXE_COUPLING_GRADE}}</span>
            </div>
            <div class="card-score">{{AXE_COUPLING_SCORE}}/10</div>
            <div class="card-trend">{{AXE_COUPLING_TREND}}</div>
            <ul class="card-metrics">
                <li>God services : {{COUPLING_GOD_COUNT}}</li>
                <li>Dep. max : {{COUPLING_MAX_DEPS}} ({{COUPLING_MAX_SERVICE}})</li>
                <li>Ratio OK : {{COUPLING_OK_RATIO}}%</li>
            </ul>
        </div>

        <!-- Card Complexite -->
        <div class="card grade-{{AXE_COMPLEXITY_GRADE}}">
            <div class="card-header">
                <span class="card-title">Complexite</span>
                <span class="card-grade">{{AXE_COMPLEXITY_GRADE}}</span>
            </div>
            <div class="card-score">{{AXE_COMPLEXITY_SCORE}}/10</div>
            <div class="card-trend">{{AXE_COMPLEXITY_TREND}}</div>
            <ul class="card-metrics">
                <li>Methodes simples : {{COMPLEXITY_SIMPLE_PCT}}%</li>
                <li>Classes > 300 lignes : {{COMPLEXITY_LONG_CLASSES}}</li>
                <li>Nesting > 3 : {{COMPLEXITY_DEEP_NESTING}}</li>
            </ul>
        </div>

    </section>

    <!-- ===== DETAILS PAR AXE ===== -->

    <details class="details-section grade-{{AXE_LEGACY_GRADE}}">
        <summary>Legacy <span class="badge">{{AXE_LEGACY_SCORE}}/10</span></summary>
        <div class="details-content">
            {{AXE_LEGACY_DETAILS}}
        </div>
    </details>

    <details class="details-section grade-{{AXE_TESTS_GRADE}}">
        <summary>Tests <span class="badge">{{AXE_TESTS_SCORE}}/10</span></summary>
        <div class="details-content">
            {{AXE_TESTS_DETAILS}}
        </div>
    </details>

    <details class="details-section grade-{{AXE_SECURITY_GRADE}}">
        <summary>Securite <span class="badge">{{AXE_SECURITY_SCORE}}/10</span></summary>
        <div class="details-content">
            {{AXE_SECURITY_DETAILS}}
        </div>
    </details>

    {{#IF_API_ENABLED}}
    <details class="details-section grade-{{AXE_API_GRADE}}">
        <summary>API <span class="badge">{{AXE_API_SCORE}}/10</span></summary>
        <div class="details-content">
            {{AXE_API_DETAILS}}
        </div>
    </details>
    {{/IF_API_ENABLED}}

    <details class="details-section grade-{{AXE_ARCH_GRADE}}">
        <summary>Architecture <span class="badge">{{AXE_ARCH_SCORE}}/10</span></summary>
        <div class="details-content">
            {{AXE_ARCH_DETAILS}}
        </div>
    </details>

    <details class="details-section grade-{{AXE_DEAD_GRADE}}">
        <summary>Code mort <span class="badge">{{AXE_DEAD_SCORE}}/10</span></summary>
        <div class="details-content">
            {{AXE_DEAD_DETAILS}}
        </div>
    </details>

    <details class="details-section grade-{{AXE_CONFIG_GRADE}}">
        <summary>Configuration <span class="badge">{{AXE_CONFIG_SCORE}}/10</span></summary>
        <div class="details-content">
            {{AXE_CONFIG_DETAILS}}
        </div>
    </details>

    <details class="details-section grade-{{AXE_COUPLING_GRADE}}">
        <summary>Couplage <span class="badge">{{AXE_COUPLING_SCORE}}/10</span></summary>
        <div class="details-content">
            {{AXE_COUPLING_DETAILS}}
        </div>
    </details>

    <details class="details-section grade-{{AXE_COMPLEXITY_GRADE}}">
        <summary>Complexite <span class="badge">{{AXE_COMPLEXITY_SCORE}}/10</span></summary>
        <div class="details-content">
            {{AXE_COMPLEXITY_DETAILS}}
        </div>
    </details>

    <!-- ===== TOP 10 PROBLEMES ===== -->
    <div class="actions-section">
        <h2>Top 10 problemes critiques</h2>
        <table>
            <thead>
                <tr>
                    <th>#</th>
                    <th>Axe</th>
                    <th>Fichier</th>
                    <th>Description</th>
                    <th>Correction</th>
                    <th>Skill</th>
                </tr>
            </thead>
            <tbody>
                {{TOP_10_ROWS}}
            </tbody>
        </table>
    </div>

    <!-- ===== MATRICE EFFORT/IMPACT ===== -->
    <div class="actions-section">
        <h2>Matrice effort / impact</h2>
        <table>
            <thead>
                <tr>
                    <th>#</th>
                    <th>Action</th>
                    <th>Impact</th>
                    <th>Effort</th>
                    <th>Priorite</th>
                </tr>
            </thead>
            <tbody>
                {{MATRIX_ROWS}}
            </tbody>
        </table>
    </div>

    <!-- ===== PROCHAINES ETAPES ===== -->
    <div class="actions-section">
        <h2>Prochaines etapes</h2>
        {{NEXT_STEPS}}
    </div>

    <!-- ===== FOOTER ===== -->
    <footer class="footer">
        Genere par <code>/full-audit</code> — Claude Code · {{DATE}}
    </footer>

</div>
</body>
</html>
```

### Variables du template HTML

| Variable | Description | Exemple |
|----------|------------|---------|
| `{{PROJECT_NAME}}` | Nom du projet (depuis `composer.json` ou dossier racine) | `mon-projet` |
| `{{DATE}}` | Date du scan (YYYY-MM-DD) | `2026-02-21` |
| `{{SCOPE}}` | Scope analyse | `src/` |
| `{{PHP_VERSION}}` | Version PHP detectee | `8.5` |
| `{{SYMFONY_VERSION}}` | Version Symfony detectee | `8.0` |
| `{{FILES_COUNT}}` | Nombre total de fichiers analyses | `342` |
| `{{GLOBAL_SCORE}}` | Score global (X.X) | `7.8` |
| `{{GLOBAL_SCORE_PCT}}` | Score global en pourcentage (score * 10) | `78` |
| `{{GRADE}}` | Grade global (A-F) | `B` |
| `{{TREND_SECTION}}` | HTML de la section tendance (ou vide si premier audit) | `<p>+0.5 vs precedent</p>` |
| `{{AXE_*_SCORE}}` | Score de chaque axe (X.X) | `8.2` |
| `{{AXE_*_GRADE}}` | Grade de chaque axe (A-F) | `B` |
| `{{AXE_*_TREND}}` | Tendance de chaque axe (HTML) | `<span class="up">+1.2</span>` |
| `{{AXE_*_DETAILS}}` | Contenu HTML detaille de chaque axe | (tableaux, listes) |
| `{{#IF_API_ENABLED}}...{{/IF_API_ENABLED}}` | Bloc conditionnel : inclus seulement si API Platform est installe | — |
| `{{TOP_10_ROWS}}` | Lignes `<tr>` du tableau top 10 | — |
| `{{MATRIX_ROWS}}` | Lignes `<tr>` de la matrice effort/impact | — |
| `{{NEXT_STEPS}}` | HTML des prochaines etapes | — |
| `{{AXE_COMPLEXITY_SCORE}}` | Score de l'axe Complexite | `6.5` |
| `{{AXE_COMPLEXITY_GRADE}}` | Grade de l'axe Complexite | `C` |
| `{{AXE_COMPLEXITY_TREND}}` | Tendance axe Complexite | `<span class="up">+0.8</span>` |
| `{{AXE_COMPLEXITY_DETAILS}}` | Contenu detaille axe Complexite | (tableaux, listes) |
| `{{COMPLEXITY_SIMPLE_PCT}}` | % de methodes simples | `82` |
| `{{COMPLEXITY_LONG_CLASSES}}` | Nombre de classes > 300 lignes | `5` |
| `{{COMPLEXITY_DEEP_NESTING}}` | Nombre de methodes avec nesting > 3 | `12` |

---

## Section 3 : Template resume (--summary)

```markdown
**Full Audit — Resume**

**Score global : {{GLOBAL_SCORE}}/10 — {{GRADE}}**

| Axe | Score | Grade |
|-----|-------|-------|
| Legacy | {{AXE_LEGACY_SCORE}} | {{AXE_LEGACY_GRADE}} |
| Tests | {{AXE_TESTS_SCORE}} | {{AXE_TESTS_GRADE}} |
| Securite | {{AXE_SECURITY_SCORE}} | {{AXE_SECURITY_GRADE}} |
| API | {{AXE_API_SCORE}} | {{AXE_API_GRADE}} |
| Architecture | {{AXE_ARCH_SCORE}} | {{AXE_ARCH_GRADE}} |
| Code mort | {{AXE_DEAD_SCORE}} | {{AXE_DEAD_GRADE}} |
| Configuration | {{AXE_CONFIG_SCORE}} | {{AXE_CONFIG_GRADE}} |
| Couplage | {{AXE_COUPLING_SCORE}} | {{AXE_COUPLING_GRADE}} |
| Complexite | {{AXE_COMPLEXITY_SCORE}} | {{AXE_COMPLEXITY_GRADE}} |

**Top 5 actions prioritaires :**
1. {{ACTION_1}}
2. {{ACTION_2}}
3. {{ACTION_3}}
4. {{ACTION_4}}
5. {{ACTION_5}}
```

> Si l'axe API est desactive, la ligne API affiche "N/A" dans les colonnes Score et Grade.
