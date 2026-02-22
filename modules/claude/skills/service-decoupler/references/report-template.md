## Service Decoupler Report — [Nom du projet]

### Résumé
- Services analysés : X
- Violations détectées : X
  - Critiques : X (9+ deps)
  - Hautes : X (7-8 deps)
  - Warnings : X (5-6 deps)
- God classes : X (> 300 lignes)
- Dépendance constructeur moyenne : X.X
- Dépendance constructeur max : X ([ServiceName])
- Services propres (< 5 deps) : X (Y%)
- Bounded Contexts concernés : [liste]

### Classement par sévérité

#### Critiques (9+ dépendances)

| # | Service | BC | Deps | Méthodes | Lignes | Clusters | Score |
|---|---------|-----|------|----------|--------|----------|-------|
| 1 | `OrderService` | Order | 9 | 8 | 350 | 5 | 9/10 |

→ Voir plan de découpage détaillé ci-dessous.

#### Hautes (7-8 dépendances)
...

#### Warnings (5-6 dépendances)
...

### Plans de découpage détaillés

#### 1. OrderService — Score: 9/10
[Plan détaillé selon le format de la Phase 3.2]

#### 2. ProductManager — Score: 7/10
[Plan détaillé]

### Distribution des dépendances

#### Histogramme
```
1 dep  : ████████████████████ 42 services
2 deps : ████████████████ 33 services
3 deps : ████████████ 25 services
4 deps : ████████ 18 services
5 deps : █████ 12 services  ← seuil warning
6 deps : ███ 7 services
7 deps : ██ 4 services       ← seuil high
8 deps : █ 2 services
9+ deps: █ 1 service          ← seuil critical
```

#### Top 10 des dépendances les plus injectées
| # | Dépendance | Nombre d'injections | Type |
|---|-----------|---------------------|------|
| 1 | `LoggerInterface` | 42 | Framework |
| 2 | `EntityManagerInterface` | 18 | Persistence |
| 3 | `EventDispatcherInterface` | 12 | Framework |

> Si `EntityManagerInterface` est fortement injecté, c'est un signe que les repositories ne sont pas utilisés correctement (les services devraient injecter les interfaces de repository, pas l'EM directement).

### Métriques par Bounded Context

| BC | Services | Moy. deps | Max deps | Violations | % propres |
|----|----------|-----------|----------|------------|-----------|
| Order | 15 | 3.2 | 9 | 3 | 80% |
| Catalog | 12 | 2.8 | 6 | 1 | 92% |
| Shared | 8 | 1.5 | 3 | 0 | 100% |

### Anti-patterns globaux détectés

| Anti-pattern | Occurrences | Impact | Recommandation |
|-------------|-------------|--------|----------------|
| EntityManager direct (au lieu de Repository) | X | Couplage Doctrine | Injecter les interfaces Repository |
| Service orchestrateur procédural | X | SRP violation | Extraire vers Command Handlers + Events |
| Side effects synchrones | X | Performance, SRP | Déplacer vers Event Handlers async |
| Caching inline | X | Lisibilité, testabilité | Extraire vers Decorator |
| Cross-BC injection directe | X | Couplage inter-BC | Utiliser des Events ou ports anti-corruption |

### Plan de refactorisation global

> Ordre de priorité pour le découpage.

1. **Services critiques** (score >= 8)
   - [ ] `OrderService` → CQRS + Events (impact: 7 fichiers)
   - [ ] `UserManager` → extraction notification (impact: 4 fichiers)

2. **Services hauts** (score 6-7)
   - [ ] `ProductService` → CQRS simple (impact: 5 fichiers)

3. **God classes** (> 300 lignes, indépendamment des deps)
   - [ ] `LegacyImportService` → extraction par étape (impact: 3 fichiers)

4. **Anti-patterns globaux**
   - [ ] Remplacer `EntityManager` par des Repository Interfaces (X occurrences)
   - [ ] Déplacer les side effects vers des Event Handlers async

### Justification du scoring

Le score de severite de chaque service est calcule sur 10 points selon la formule suivante (cf. `references/decoupling-patterns.md`) :

**Dependances constructeur (poids 40%)** :
- 9+ deps = 4 pts, 7-8 deps = 3 pts, 5-6 deps = 2 pts, 4 deps = 1 pt

**Methodes publiques (poids 20%)** :
- 10+ = 2 pts, 7-9 = 1.5 pts, 5-6 = 1 pt

**Lignes de code (poids 20%)** :
- 400+ = 2 pts, 300-399 = 1.5 pts, 200-299 = 1 pt

**Clusters de preoccupations (poids 20%)** :
- 5+ = 2 pts, 4 = 1.5 pts, 3 = 1 pt

**Bonus aggravants** :
- 3+ deps cross-BC = +1, EntityManager direct = +0.5, Handler avec trop de deps = +1

Le score est plafonne a 10.

**Exemple concret** : `OrderService` avec 9 deps constructeur (4 pts) + 8 methodes publiques (1.5 pts) + 350 lignes (1.5 pts) + 5 clusters (2 pts) + 2 deps cross-BC (pas de bonus) = **9/10** (critical).

### Estimation d'effort

| Lot | Services | Fichiers à créer | Fichiers à modifier | Complexité |
|-----|----------|-----------------|---------------------|------------|
| 1 - Critiques | 2 | 14 | 8 | Haute |
| 2 - Hauts | 3 | 12 | 6 | Moyenne |
| 3 - Anti-patterns | - | 5 | 15 | Moyenne |

### Format JSON (si `--output=json`)

```json
{
  "project": "nom-du-projet",
  "scan_date": "2026-02-21",
  "scope": "src/",
  "threshold": 5,
  "summary": {
    "services_analyzed": 0,
    "violations_total": 0,
    "violations_critical": 0,
    "violations_high": 0,
    "violations_warning": 0,
    "avg_dependencies": 0.0,
    "max_dependencies": 0,
    "god_classes": 0,
    "clean_services_pct": 0
  },
  "violations": [
    {
      "service": "App\\Order\\Application\\Service\\OrderService",
      "file": "src/Order/Application/Service/OrderService.php",
      "bounded_context": "Order",
      "layer": "Application",
      "metrics": {
        "constructor_dependencies": 9,
        "public_methods": 8,
        "lines_of_code": 350,
        "concern_clusters": 5,
        "cross_bc_count": 2
      },
      "severity": "critical",
      "score": 9,
      "dependencies": [
        {
          "name": "$productRepository",
          "type": "App\\Order\\Domain\\Repository\\ProductRepositoryInterface",
          "category": "persistence",
          "cluster": "CRUD",
          "used_by": ["create", "update", "delete"]
        }
      ],
      "clusters": [
        {"name": "CRUD Persistence", "dependencies": ["$productRepository", "$categoryRepository"]},
        {"name": "Notification", "dependencies": ["$mailer", "$translator"]}
      ],
      "recommended_strategy": "concern_extraction_with_events",
      "split_plan": {
        "files_to_create": 7,
        "files_to_modify": 2,
        "files_to_delete": 1,
        "max_deps_after": 3
      }
    }
  ],
  "global_antipatterns": [
    {
      "pattern": "entity_manager_direct",
      "occurrences": 18,
      "recommendation": "Inject repository interfaces instead of EntityManager"
    }
  ],
  "dependency_distribution": {
    "1": 42,
    "2": 33,
    "3": 25,
    "4": 18,
    "5": 12,
    "6": 7,
    "7": 4,
    "8": 2,
    "9+": 1
  }
}
```

## Template résumé (--summary)

**Service Decoupler — Résumé**

| Métrique | Valeur |
|----------|--------|
| Services analysés | X |
| God services (critique) | X |
| Services warning | X |
| Dépendances max | X (ServiceName) |
| Score SRP moyen | X.X/10 |

**Top 5 god services :**

| # | Service | Deps | Méthodes | Lignes | Sévérité |
|---|---------|------|----------|--------|----------|
| 1 | ... | X | X | X | critique |
