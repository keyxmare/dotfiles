# Template de rapport — PR Description

## Template complet (défaut)

```markdown
## <emoji> <titre>

> <résumé en 1-2 phrases : ce que fait la PR et pourquoi>

---

### Type de changement

- [ ] Feature
- [ ] Fix
- [ ] Refactor
- [ ] Performance
- [ ] Tests
- [ ] Chore / Config
- [ ] Breaking change

---

### Changements

#### Fonctionnalités
- <description orientée "quoi + pourquoi">

#### Corrections
- <description du bug corrigé et de la solution>

#### Refactoring
- <description de la restructuration et du bénéfice>

#### Infrastructure / Configuration
- <changements de config, dépendances, env>

---

### Impact technique

| Métrique | Valeur |
|----------|--------|
| Fichiers modifiés | X |
| Lignes ajoutées | +X |
| Lignes supprimées | -X |
| Commits | X |
| Zones impactées | Controller, Repository, ... |

---

### Points d'attention

- [ ] Aucun
- [ ] Migration DB à jouer (`php bin/console doctrine:migrations:migrate`)
- [ ] Variables d'environnement ajoutées/modifiées (voir `.env.example`)
- [ ] Dépendances mises à jour (`composer install` / `npm install`)
- [ ] Breaking change — impact sur les consommateurs de l'API
- [ ] Impact sécurité à évaluer

---

### Tests

- [ ] Tests unitaires ajoutés / mis à jour
- [ ] Tests fonctionnels ajoutés / mis à jour
- [ ] Testé manuellement — procédure : <décrire si non trivial>
- [ ] Aucun test requis (chore / doc)

---

### Notes de déploiement

> <Laisser vide si aucun prérequis de déploiement particulier, sinon décrire les étapes dans l'ordre>

---

### Checklist reviewer

- [ ] Le code est lisible et les changements sont justifiés
- [ ] Pas de `var_dump`, `console.log`, `dd()` oubliés
- [ ] Les cas d'erreur sont gérés
- [ ] La PR est de taille raisonnable (< 400 lignes hors tests)
```

---

## Variantes de sections selon le contenu

### Section "Changements" — si un seul type dominant

Si tous les commits sont du même type (ex: 100% fix), fusionner en une seule section :

```markdown
### Corrections

- Fix X : <description>
- Fix Y : <description>
```

### Section "Commits inclus" — si --last ou --from spécifié

Ajouter en bas pour traçabilité :

```markdown
### Commits inclus

| SHA | Message |
|-----|---------|
| `abc1234` | feat(catalog): add product filtering |
| `def5678` | fix(order): correct tax calculation |
```

### Section "Breaking changes" — si détecté

```markdown
### ⚠️ Breaking Changes

| Quoi | Avant | Après | Migration |
|------|-------|-------|-----------|
| Route `/api/products` | `GET /api/products` retourne `[]` si vide | retourne `{"items": [], "total": 0}` | Adapter les clients |
| Classe `PriceCalculator` | méthode `compute(int $id)` | supprimée | Utiliser `PriceService::calculate()` |
```

---

## Emojis par type (optionnel, si le projet les utilise)

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

> N'utiliser les emojis que si le projet en utilise déjà dans ses commits ou PRs existantes.

---

## Template court (si peu de commits ou changements mineurs)

```markdown
## <titre>

<résumé en 1-2 phrases>

### Changements
- <puce 1>
- <puce 2>

### Points d'attention
- [ ] <point si pertinent, sinon supprimer la section>

### Tests
- [ ] <état des tests>
```
