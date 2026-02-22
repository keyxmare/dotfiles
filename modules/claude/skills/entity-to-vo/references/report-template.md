# Report Template — Entity to Value Object

## Template rapport Phase 2 (analyse)

```markdown
## Rapport Value Object Extraction — [Projet/BC]

### Résumé
- Entités analysées : X
- Groupes détectés : X
  - Extraction recommandée : X (score >= 5)
  - Extraction suggérée : X (score 3-4)
  - À évaluer : X (score 1-2)
- Value Objects à créer : X
- Value Objects réutilisables (SharedKernel) : X
- Doublons inter-entités : X groupes

### Entité: [NomEntité]

#### Groupe 1: Address (score: 7/10 — recommandé)

| Champ actuel | Type | Nullable | Destination VO |
|---|---|---|---|
| `addressStreet` | `string` | non | `Address::$street` |
| `addressCity` | `string` | non | `Address::$city` |
| `addressZipCode` | `string` | non | `Address::$zipCode` |
| `addressCountry` | `string` | non | `Address::$country` |

**Raisons :**
- Préfixe commun `address` (+3)
- Pattern DDD classique "Address" (+3)
- Répété dans 2 autres entités (+2)
- 4 champs dans le groupe (+1)
- Aucun champ nullable

**Value Object proposé :** `Address` (SharedKernel)
**Impact :** remplace 4 colonnes par un embeddable

#### Groupe 2: Money — `totalAmount` + `totalCurrency` (score: 6/10 — recommandé)
...

#### Champ unique: `email` (score: 4/10 — suggéré)

| Champ actuel | Type | Nullable |
|---|---|---|
| `email` | `string` | non |

**Raisons :**
- Validation métier nécessaire (format email) (+2)
- VO classique SharedKernel (+2)

**Value Object proposé :** `Email` (SharedKernel)

### Doublons inter-entités

| Groupe | Entités | VO proposé | Localisation |
|--------|---------|------------|-------------|
| Address (4 champs) | `User`, `Company`, `Order` | `Address` | SharedKernel |
| Money (2 champs) | `Product`, `Order`, `Invoice` | `Money` | SharedKernel |

### Arborescence cible

src/
  SharedKernel/
    Domain/
      ValueObject/
        Address.php          ← NEW
        Money.php            ← NEW
        Email.php            ← NEW
  Catalog/
    Domain/
      Model/
        Product.php          ← MODIFIED (utilise Money)
      ValueObject/
        Dimensions.php       ← NEW (spécifique au BC)
    Infrastructure/
      Persistence/
        Mapping/
          Product.orm.xml    ← MODIFIED (embedded)
```

## Template résumé Phase 5 (bilan)

```markdown
## Résumé de l'extraction Value Objects

### Avant
- Entités analysées : X
- Champs scalaires candidats : X
- Groupes détectés : X

### Après
- Value Objects créés : X
  - SharedKernel : X (réutilisables)
  - Spécifiques BC : X
- Entités modifiées : X
- Getters/setters supprimés : X
- Méthodes métier ajoutées : X

### Fichiers modifiés/créés
| Fichier | Action | Description |
|---|---|---|
| `src/SharedKernel/Domain/ValueObject/Address.php` | NEW | VO Address |
| `src/Catalog/Domain/Model/Product.php` | MODIFIED | Utilise Money |
| `src/.../Mapping/Address.orm.xml` | NEW | Mapping embeddable |

### Impact base de données
- Migration : vide (colonnes préservées) / non-vide (voir détails)

### Problèmes restants
- [ ] Adapter les queries DQL dans les repositories
- [ ] Adapter les formulaires Symfony
- [ ] Tests à écrire pour les VO

### Recommandations
1. Écrire les tests unitaires pour chaque VO
2. Adapter les queries Doctrine (DQL `entity.address.city` au lieu de `entity.addressCity`)
3. Vérifier les serializers (les VO sont sérialisés différemment)
```
