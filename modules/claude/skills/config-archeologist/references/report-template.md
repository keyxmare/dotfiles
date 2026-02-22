# Template de rapport — Config Archeologist

## Format Markdown

```markdown
## Config Archeologist Report — [Nom du projet]

### Vue d'ensemble
- Fichiers de configuration analysés : X
- Version Symfony : X.Y
- Bundles installés : X (actifs : X, inactifs : X)
- Anomalies détectées : X
  - Critiques : X
  - Majeures : X
  - Mineures : X
  - Info : X

### Cartographie de la configuration

#### Fichiers de config
| # | Fichier | Type | Lignes | Env | Anomalies |
|---|---------|------|--------|-----|-----------|
| 1 | `config/services.yaml` | services | 85 | all | 3 |
| 2 | `config/packages/doctrine.yaml` | bundle | 42 | all | 1 |

#### Autodiscovery
| # | Namespace | Resource | Exclude | Classes couvertes |
|---|-----------|----------|---------|-------------------|
| 1 | `App\` | `../src/` | `{Entity,Event,DTO}` | ~120 |

#### Services explicites
| # | Service ID | Classe | Tags | Public | Anomalie |
|---|-----------|--------|------|--------|----------|
| 1 | `app.mailer` | `App\Infra\Mailer\SmtpMailer` | - | no | - |

#### Paramètres
| # | Paramètre | Valeur | Source | Utilisé | Anomalie |
|---|-----------|--------|--------|---------|----------|
| 1 | `app.default_locale` | `fr` | services.yaml | oui | - |
| 2 | `app.legacy_flag` | `true` | services.yaml | non | DEAD |

#### Variables d'environnement
| # | Variable | .env | Config | Code | Anomalie |
|---|----------|------|--------|------|----------|
| 1 | `DATABASE_URL` | oui | oui | non | - |
| 2 | `OLD_API_KEY` | oui | non | non | DEAD |

### Anomalies critiques

#### [SEC] Secret hardcodé dans framework.yaml
- **Fichier** : `config/packages/framework.yaml:3`
- **Problème** : `secret: 'my-hardcoded-secret'` au lieu de `'%env(APP_SECRET)%'`
- **Risque** : Le secret est exposé dans le VCS
- **Correction** : `secret: '%env(APP_SECRET)%'`

### Anomalies majeures

#### [DEP] Bundle déprécié : sensio/framework-extra-bundle
- **Fichier** : `composer.json`, `config/bundles.php`
- **Problème** : Ce bundle est déprécié depuis Symfony 6.2 en faveur des attributs natifs
- **Impact** : Ne sera plus maintenu, incompatibilité future
- **Migration** : Remplacer `@ParamConverter` par `#[MapEntity]`, `@IsGranted` par `#[IsGranted]`

#### [INC] Service configuré mais classe inexistante
- **Fichier** : `config/services.yaml:42`
- **Service** : `App\Legacy\OldService`
- **Problème** : La classe n'existe pas dans `src/`
- **Risque** : Erreur au build du container
- **Correction** : Supprimer la déclaration

### Anomalies mineures

#### [DUP] Service déclaré explicitement ET couvert par autodiscovery
- **Fichier** : `config/services.yaml:28`
- **Service** : `App\Catalog\Application\Service\ProductFinder`
- **Problème** : Cette classe est dans `src/Catalog/Application/Service/` qui est couvert par l'autodiscovery `App\` → `../src/`
- **Impact** : La déclaration explicite override silencieusement l'autodiscovery
- **Correction** : Supprimer la déclaration explicite si aucun argument custom n'est nécessaire

#### [DEAD] Paramètre orphelin
- **Fichier** : `config/services.yaml:5`
- **Paramètre** : `app.legacy_flag`
- **Problème** : Jamais référencé par `%app.legacy_flag%` dans aucun fichier
- **Correction** : Supprimer le paramètre

### Bundles : état de santé

| # | Bundle | Installé | Enregistré | Configuré | Statut |
|---|--------|----------|------------|-----------|--------|
| 1 | doctrine/orm | oui | oui | oui | OK |
| 2 | nelmio/cors-bundle | oui | oui | non | Defaults |
| 3 | league/flysystem-bundle | oui | non | non | Inactif |
| 4 | -- | -- | -- | `old_bundle.yaml` | Config orpheline |

### Matrice de cohérence environnements

| Configuration | .env | .env.local | .env.test | Config YAML | Docker |
|---------------|------|------------|-----------|-------------|--------|
| DATABASE_URL | oui | - | oui | oui | oui |
| MAILER_DSN | oui | - | non | oui | non |
| REDIS_URL | non | - | non | oui | oui |

> `REDIS_URL` est utilisé dans la config mais absent du `.env` → crash au runtime si non défini par l'environnement.

### Chronologie archéologique

> Couches de configuration accumulées dans le temps, de la plus ancienne à la plus récente.

| Couche | Indices | Recommandation |
|--------|---------|----------------|
| Legacy | Paramètres `app.legacy_*`, services avec `public: true` | Nettoyer |
| Migration Symfony 4→5 | `sensio/framework-extra-bundle` encore présent | Migrer |
| Actuel | Autodiscovery, attributs PHP 8 | OK |

### Plan de nettoyage recommandé

> Ordre de priorité pour les corrections.

1. **Corriger les critiques** (sécurité, erreurs build)
   - [ ] Utiliser `%env(APP_SECRET)%` pour le secret framework
   - [ ] Ajouter `REDIS_URL` dans `.env`

2. **Résoudre les dépréciations** (avant upgrade Symfony)
   - [ ] Migrer `sensio/framework-extra-bundle` → attributs natifs
   - [ ] Passer les mappings Doctrine de `annotation` à `attribute`

3. **Supprimer les doublons**
   - [ ] Retirer les services explicites couverts par autodiscovery
   - [ ] Fusionner les configs identiques dev/test

4. **Nettoyer la config morte**
   - [ ] Supprimer les paramètres orphelins
   - [ ] Supprimer les variables `.env` inutilisées
   - [ ] Retirer les configs de bundles non installés

5. **Optimiser la performance**
   - [ ] Configurer un cache pool Redis en prod
   - [ ] Vérifier que le profiling Doctrine est désactivé en prod
```

## Format JSON (si `--output=json`)

```json
{
  "project": "nom-du-projet",
  "scan_date": "2026-02-21",
  "symfony_version": "7.2",
  "scope": "config/",
  "summary": {
    "config_files": 0,
    "bundles_installed": 0,
    "bundles_active": 0,
    "anomalies_total": 0,
    "anomalies_critical": 0,
    "anomalies_major": 0,
    "anomalies_minor": 0,
    "anomalies_info": 0
  },
  "anomalies": [
    {
      "id": 1,
      "category": "SEC",
      "severity": "critique",
      "file": "config/packages/framework.yaml",
      "line": 3,
      "title": "Secret hardcodé",
      "description": "framework.secret contient une valeur en dur au lieu de %env(APP_SECRET)%",
      "fix": "Remplacer par '%env(APP_SECRET)%'"
    }
  ],
  "config_map": {
    "services": [],
    "routes": [],
    "parameters": [],
    "env_vars": [],
    "bundles": []
  }
}
```

## Template résumé (--summary)

**Config Archeologist — Résumé**

| Métrique | Valeur |
|----------|--------|
| Fichiers analysés | X |
| Version Symfony | X.Y |
| Anomalies critiques | X |
| Anomalies majeures | X |
| Anomalies mineures | X |
| Config morte | X entrées |

**Top 5 anomalies :**

| # | Sévérité | Catégorie | Description | Fichier |
|---|----------|-----------|-------------|---------|
| 1 | critique | SEC | ... | ... |
| 2 | majeur | DEP | ... | ... |
| 3 | majeur | INC | ... | ... |
| 4 | mineur | DUP | ... | ... |
| 5 | mineur | DEAD | ... | ... |
