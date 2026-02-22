# Report Template — Migration Planner

## Template rapport (défaut)

```markdown
## Migration Planner Report — [Nom du projet]

### Résumé
- Version actuelle : Symfony X.Y / PHP X.Y
- Version cible : Symfony X.Y / PHP X.Y
- Étapes de migration : X
- Dépréciations à corriger : X
- Bundles à remplacer : X
- Effort total estimé : X (faible/moyen/élevé)

### Chemin de migration

[X.Y] --> [X.Y] --> [X.Y] --> [X.Y (cible)]
  |          |          |          |
  -- PHP X.Y -- PHP X.Y -- PHP X.Y -- PHP X.Y

### État des dépendances

| Package | Installée | Cible | Action |
|---------|-----------|-------|--------|
| `symfony/framework-bundle` | X.Y | X.Y | Upgrade |
| `sensio/framework-extra-bundle` | X.Y | - | Supprimer |

### Étape 1 : [Détails]
...

### Étape N : [Détails]
...

### Récapitulatif des risques

| Risque | Probabilité | Impact | Mitigation |
|--------|------------|--------|-----------|
| Bundles tiers incompatibles | Moyenne | Élevé | Vérifier avant l'upgrade |
| Régression fonctionnelle | Faible | Élevé | Tests automatisés |
```

## Template checklist (si --output=checklist)

```markdown
## Checklist de migration — Symfony X.Y -> X.Y

### Étape 1 : X.Y -> X.Y
- [ ] Corriger dépréciation : [description]
- [ ] Corriger dépréciation : [description]
- [ ] Mettre à jour dépendances tiers
- [ ] Mettre à jour Symfony
- [ ] Vider le cache
- [ ] Lancer les tests
- [ ] Vérification manuelle

### Étape 2 : X.Y -> X.Y
...
```

## Template étape de migration

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
6. [ ] `composer recipes:update` — mettre à jour les recettes Flex

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
    ->withPaths(['src/'])
    ->withSets([SymfonySetList::SYMFONY_XY]);
```
```bash
vendor/bin/rector process
```
> **Note** : la syntaxe `--set` est celle de Rector 0.x (depreciee). Depuis Rector 1.0+, la configuration se fait dans `rector.php` avec `->withSets()`.

#### Estimation d'effort
- Fichiers à modifier : ~X
- Effort : faible / moyen / élevé
- Risque de régression : faible / moyen / élevé
```

## Template JSON (`--output=json`)

```json
{
  "project": "nom-du-projet",
  "current_versions": {
    "symfony": "7.2",
    "php": "8.3",
    "doctrine_orm": "2.19",
    "doctrine_dbal": "3.8"
  },
  "target_versions": {
    "symfony": "8.0",
    "php": "8.5",
    "doctrine_orm": "3.0",
    "doctrine_dbal": "4.0"
  },
  "migration_path": ["7.2 -> 8.0"],
  "deprecations": [
    {
      "pattern": "Description du pattern deprecie",
      "severity": "critical|high|medium|low",
      "files_affected": 0,
      "rector_rule": "Symfony\\Set\\SYMFONY_80 ou null si aucune",
      "fix_description": "Description de la correction a appliquer"
    }
  ],
  "breaking_changes": [
    {
      "description": "Description du breaking change",
      "impact": "high|medium|low",
      "fix_strategy": "Description de la strategie de correction",
      "files_affected": 0
    }
  ],
  "migration_steps": [
    {
      "order": 1,
      "description": "Description de l'etape",
      "estimated_effort": "low|medium|high",
      "deprecations_to_fix": 0,
      "prerequisites": ["PHP 8.4+"]
    }
  ],
  "dependencies": [
    {
      "package": "symfony/framework-bundle",
      "current_version": "7.2",
      "target_version": "8.0",
      "action": "upgrade|replace|remove",
      "replacement": null
    }
  ],
  "risks": [
    {
      "description": "Description du risque",
      "probability": "high|medium|low",
      "impact": "high|medium|low",
      "mitigation": "Strategie de mitigation"
    }
  ],
  "summary": {
    "total_deprecations": 0,
    "total_breaking_changes": 0,
    "total_migration_steps": 0,
    "estimated_total_effort": "low|medium|high",
    "estimated_files_to_modify": 0,
    "overall_risk": "low|medium|high"
  }
}
```
