# Template de rapport — PR Description

## Template complet (défaut)

```markdown
## <emoji> <titre>

<!-- Metadata -->
| | |
|---|---|
| **Branche** | `<branch>` → `<base>` |
| **Taille** | <badge_taille> · <N> commits · <fichiers_modifiés> fichiers |
| **Diff** | `+<ajouts>` `−<suppressions>` |

> <résumé en 2-3 phrases : ce que fait la PR, pourquoi, et le bénéfice attendu>

---

### 📋 Changements

#### Fonctionnalités
- **<composant/scope>** — <description orientée "quoi + pourquoi"> (`fichier.php`)

#### Corrections
- **<composant/scope>** — <description du bug corrigé et de la solution> (`fichier.php`)

#### Refactoring
- **<composant/scope>** — <description de la restructuration et du bénéfice> (`fichier.php`)

#### Infrastructure / Configuration
- **<composant/scope>** — <changements de config, dépendances, env>

---

### 🗂️ Fichiers modifiés

<details>
<summary><b><N> fichiers</b> — cliquer pour voir le détail</summary>

| Statut | Fichier | Lignes |
|:------:|---------|-------:|
| M | `src/Order/Domain/Entity/Order.php` | +12 −3 |
| A | `src/Order/Application/Command/CancelOrder.php` | +45 |
| D | `src/Order/Infrastructure/Legacy/OldService.php` | −120 |
| R | `src/Catalog/Product.php` → `src/Catalog/Domain/Entity/Product.php` | +2 −2 |

> **Légende** : A = ajouté · M = modifié · D = supprimé · R = renommé

</details>

---

### ⚡ Impact

| Zone | Détail |
|------|--------|
| **Bounded Contexts** | `Order`, `Catalog` |
| **Couches** | Domain, Application |
| **API** | Aucun changement / Endpoints modifiés : `POST /api/orders/{id}/cancel` |
| **Base de données** | Aucune migration / Migration à jouer |
| **Dépendances** | Aucun changement / `composer.json` modifié |

---

### ⚠️ Points d'attention

> Supprimer cette section si aucun point d'attention.

- 🗄️ **Migration DB** — `php bin/console doctrine:migrations:migrate` à exécuter
- 🔑 **Variables d'environnement** — `APP_NEW_VAR` ajoutée (voir `.env.example`)
- 📦 **Dépendances** — `composer install` requis
- 💥 **Breaking change** — <décrire l'impact et la migration>
- 🔒 **Sécurité** — <décrire le changement de sécurité>

---

### 🧪 Tests

- [x] Tests unitaires ajoutés / mis à jour
- [ ] Tests fonctionnels ajoutés / mis à jour
- [ ] Testé manuellement

<details>
<summary>Détail des tests</summary>

| Fichier de test | Couvre |
|----------------|-------|
| `tests/Unit/Order/CancelOrderHandlerTest.php` | `CancelOrderHandler` |

</details>

---

### 🚀 Déploiement

> Supprimer cette section s'il n'y a aucun prérequis de déploiement.

1. Exécuter les migrations : `php bin/console doctrine:migrations:migrate`
2. Ajouter la variable `APP_NEW_VAR` dans le `.env` de production
3. Vider le cache : `php bin/console cache:clear`

---

### ✅ Checklist

- [ ] Code lisible, changements justifiés
- [ ] Pas de `var_dump`, `dd()`, `console.log` oubliés
- [ ] Cas d'erreur gérés
- [ ] Nommage cohérent avec les conventions du projet

---

<details>
<summary>📊 Commits inclus (<N>)</summary>

| SHA | Type | Message |
|-----|------|---------|
| `abc1234` | feat | add order cancellation |
| `def5678` | fix | correct tax calculation |
| `ghi9012` | refactor | extract price service |

</details>
```

---

## Badges de taille

| Taille | Critère | Badge |
|--------|---------|-------|
| XS | < 10 lignes modifiées | 🟢 **XS** |
| S | 10–49 lignes | 🟡 **S** |
| M | 50–199 lignes | 🟠 **M** |
| L | 200–499 lignes | 🔴 **L** |
| XL | ≥ 500 lignes | 🟣 **XL** |

> Les lignes de tests ne comptent pas dans le calcul de la taille.

---

## Statut des fichiers

Utiliser les codes git standard dans la colonne "Statut" du tableau des fichiers :

| Code | Signification | Affichage |
|------|--------------|-----------|
| A | Added | A |
| M | Modified | M |
| D | Deleted | D |
| R | Renamed | R |
| C | Copied | C |

---

## Variantes de sections selon le contenu

### Section "Changements" — si un seul type dominant

Si tous les commits sont du même type (ex: 100% fix), fusionner en une seule section sans les sous-titres :

```markdown
### 📋 Corrections

- **<scope>** — <description> (`fichier.php`)
- **<scope>** — <description> (`fichier.php`)
```

### Section "Breaking changes" — si détecté

Insérer juste avant "Points d'attention" :

```markdown
### 💥 Breaking Changes

| Élément | Avant | Après | Migration |
|---------|-------|-------|-----------|
| Route `GET /api/products` | Retourne `[]` si vide | Retourne `{"items": [], "total": 0}` | Adapter les clients |
| `PriceCalculator::compute()` | `compute(int $id): float` | Supprimée | Utiliser `PriceService::calculate()` |
```

### Section "Captures d'écran" — si changements frontend détectés

Si des fichiers `.vue`, `.tsx`, `.css`, `.scss` ou `templates/` sont modifiés, ajouter après "Changements" :

```markdown
### 🖼️ Captures d'écran

> Ajouter des captures avant/après si les changements sont visuels.

| Avant | Après |
|-------|-------|
| <screenshot> | <screenshot> |
```

---

## Emojis de section (toujours utilisés)

| Section | Emoji |
|---------|-------|
| Changements | 📋 |
| Fichiers modifiés | 🗂️ |
| Impact | ⚡ |
| Points d'attention | ⚠️ |
| Tests | 🧪 |
| Déploiement | 🚀 |
| Checklist | ✅ |
| Commits | 📊 |
| Breaking changes | 💥 |
| Captures d'écran | 🖼️ |

## Emojis de titre (selon le type dominant de la PR)

| Type | Emoji |
|------|-------|
| Feature | ✨ |
| Fix | 🐛 |
| Refactor | ♻️ |
| Performance | ⚡ |
| Tests | 🧪 |
| Docs | 📝 |
| Chore | 🔧 |
| Breaking | 💥 |
| Security | 🔒 |
| Migration | 🗄️ |

---

## Template court (≤ 3 commits ET < 50 lignes modifiées)

```markdown
## <emoji> <titre>

| | |
|---|---|
| **Branche** | `<branch>` → `<base>` |
| **Taille** | <badge_taille> · <N> commits · <fichiers_modifiés> fichiers |

> <résumé en 1-2 phrases>

### 📋 Changements

- **<scope>** — <description> (`fichier.php`)
- **<scope>** — <description> (`fichier.php`)

### ✅ Checklist

- [ ] Code lisible, changements justifiés
- [ ] Pas de debug oublié
```

---

## Règles de mise en page

1. **Sections vides** — Supprimer toute section qui n'a pas de contenu. Ne jamais laisser de section avec un placeholder ou "Aucun".
2. **Collapsible** — Utiliser `<details>` pour les sections verbeuses (fichiers modifiés, commits, détail des tests). Toujours fermer le tag `</details>`.
3. **Gras pour les scopes** — Chaque puce de changement commence par le scope en gras : `- **<scope>** — <description>`.
4. **Fichiers entre backticks** — Tous les noms de fichiers, classes et commandes sont entre backticks.
5. **Tableaux alignés** — Aligner les colonnes des tableaux pour la lisibilité du Markdown source.
6. **Ligne vide avant/après** — Toujours une ligne vide avant et après les blocs `<details>`, les tableaux et les horizontal rules.
7. **Pas de sections "Aucun"** — Si une zone d'impact est "Aucun changement", la supprimer du tableau plutôt que d'afficher "Aucun".
8. **Checkboxes cochées** — Dans la section Tests, cocher les cases qui correspondent à des tests réellement présents dans le diff. Ne cocher que ce qui est vérifié.
