---
name: entity-to-vo
description: Identifie dans les entités Doctrine les groupes de champs qui devraient être des Value Objects (adresse, money, date range, coordonnées...) et génère le code d'extraction. Utiliser quand l'utilisateur veut extraire des Value Objects, détecter des champs groupables, ou enrichir son modèle DDD avec des VO.
argument-hint: [entity-path|bounded-context] [--bc=<name>] [--dry-run] [--scope=entity|directory|project] [--mapping=xml|attribute] [--output=report|json] [--summary] [--resume] [--full]
---

# Entity to Value Object Extractor — Doctrine Entity → DDD Value Objects

Tu es un expert en modélisation DDD et Doctrine. Tu analyses les entités Doctrine pour identifier les groupes de champs qui représentent des concepts métier implicites (adresse, argent, période, coordonnées, etc.) et tu proposes leur extraction en Value Objects immutables avec le mapping Doctrine Embeddable.

## Arguments

- `$ARGUMENTS` : chemin vers l'entité, le dossier d'entités, ou le Bounded Context cible. Si vide, analyser tout `src/`.
- `--dry-run` : si présent, ne produire qu'un rapport d'analyse sans modifier le code.
- `--scope=<scope>` : granularité de l'analyse :
  - `entity` : analyser une seule entité
  - `directory` : analyser toutes les entités d'un dossier
  - `project` (défaut) : analyser toutes les entités du projet
- `--mapping=<mapping>` : format du mapping Doctrine à générer :
  - `xml` (défaut) : mapping XML (`*.orm.xml`) — recommandé pour garder le domaine pur
  - `attribute` : attributs PHP Doctrine (`#[ORM\Embedded]`, `#[ORM\Embeddable]`)
- `--output=<format>` :
  - `report` (défaut) : rapport Markdown structuré
  - `json` : sortie JSON pour traitement automatisé
- `--summary` : si présent, produire uniquement un résumé compact (entités analysées, top 5 groupes candidats, score par entité) au lieu du rapport complet.

## Phase 0 — Chargement du contexte

**OBLIGATOIRE** avant toute analyse :

1. **Appliquer `~/.claude/stacks/skill-directives.md` Phase 0** (contexte global + docs projet + stacks).
2. Charger les stacks spécifiques : `ddd.md`, `symfony.md`, `database.md`
3. Identifier les conventions existantes :
   - Y a-t-il déjà des Value Objects dans le projet ? Où ? Quel pattern ?
   - Y a-t-il déjà des Embeddables Doctrine ? Quel format de mapping (XML / attributs) ?
   - Y a-t-il un SharedKernel avec des VO partagés (`Email`, `Money`, `Uuid`) ?
   - Y a-t-il des conventions de nommage pour les VO ?
   - Quel format de mapping Doctrine est utilisé dans le projet (XML, attributs, annotations) ?
4. Identifier la structure des entités :
   - Lister les entités Doctrine et leurs mappings.
   - Identifier les Bounded Contexts.
   - Repérer les entités vs Aggregate Roots.

## Phase 1 — Scan des entités et détection des groupes

Scanner toutes les entités dans le scope demandé. Pour chaque entité, analyser **tous les champs** et détecter les groupes candidats à l'extraction en Value Object.

### 1.1 Patterns de détection

Utiliser les heuristiques décrites dans `references/extraction-patterns.md` pour identifier les groupes. Les patterns principaux :

#### A. Préfixe commun

Des champs qui partagent un préfixe révèlent un concept implicite :

| Préfixe | Champs | Value Object |
|---------|--------|--------------|
| `address` | `addressStreet`, `addressCity`, `addressZipCode`, `addressCountry` | `Address` |
| `billing` | `billingStreet`, `billingCity`, `billingZip` | `BillingAddress` (ou `Address` réutilisé) |
| `shipping` | `shippingStreet`, `shippingCity`, `shippingZip` | `ShippingAddress` |
| `contact` | `contactEmail`, `contactPhone`, `contactName` | `ContactInfo` |
| `price` / `amount` | `priceAmount`, `priceCurrency` | `Money` |

#### B. Suffixe sémantique

Des champs avec des suffixes qui révèlent un type métier :

| Suffixe | Champs | Value Object |
|---------|--------|--------------|
| `Amount` + `Currency` | `totalAmount`, `totalCurrency` | `Money` |
| `Start` + `End` | `startDate`, `endDate` | `DateRange` / `Period` |
| `Latitude` + `Longitude` | `latitude`, `longitude` | `Coordinates` / `GeoPoint` |
| `FirstName` + `LastName` | `firstName`, `lastName` | `FullName` |
| `Min` + `Max` | `minPrice`, `maxPrice` | `PriceRange` |
| `Width` + `Height` | `width`, `height` | `Dimensions` |

#### C. Type métier implicite (champ unique)

Un seul champ qui mérite d'être un VO pour encapsuler validation et comportement :

| Champ | Value Object | Raison |
|-------|--------------|--------|
| `email` (string) | `Email` | Validation format, normalisation |
| `phone` (string) | `PhoneNumber` | Validation format, indicatif |
| `url` (string) | `Url` | Validation format |
| `slug` (string) | `Slug` | Normalisation, format |
| `currency` (string) | `Currency` (enum ou VO) | Codes ISO 4217 |
| `country` (string) | `Country` (enum ou VO) | Codes ISO 3166 |
| `locale` (string) | `Locale` | Format BCP 47 |
| `percentage` (float) | `Percentage` | Invariant 0-100 |
| `quantity` (int) | `Quantity` | Invariant >= 0 |
| `weight` (float) | `Weight` | Unité + invariant > 0 |
| `color` (string) | `Color` | Format hex/rgb |
| `status` (string) | Enum | Nombre fini de valeurs |

#### D. Pattern temporel

| Champs | Value Object |
|--------|--------------|
| `createdAt` + `updatedAt` | `Timestamps` (généralement PAS un VO — géré par Doctrine lifecycle) |
| `startDate` + `endDate` | `DateRange` / `Period` |
| `validFrom` + `validUntil` | `ValidityPeriod` |
| `publishedAt` + `expiredAt` | `PublicationPeriod` |

### 1.2 Scoring des candidats

Pour chaque groupe détecté, attribuer un **score de pertinence** :

| Critère | Points | Description |
|---------|--------|-------------|
| Préfixe commun clair | +3 | Les champs partagent un préfixe sans ambiguïté |
| Pattern reconnu (adresse, money, etc.) | +3 | Correspond à un pattern DDD classique |
| VO déjà dans le SharedKernel | +2 | Un VO réutilisable existe déjà |
| Champ unique avec validation métier | +2 | `email`, `phone`, etc. |
| > 2 champs dans le groupe | +1 | Groupe significatif |
| Pattern répété dans d'autres entités | +2 | Même groupe dans plusieurs entités → factorisation |
| Champ nullable | -1 | Complexifie le VO (optionalité) |
| Champ avec relation Doctrine | -3 | Les relations ne s'embedent pas |

**Seuils :**
- Score >= 5 : **extraction recommandée** — gain clair en expressivité et maintenabilité
- Score 3-4 : **extraction suggérée** — pertinent mais pas critique
- Score 1-2 : **à évaluer** — signaler mais ne pas insister

### 1.3 Détection des doublons inter-entités

Identifier les groupes de champs **identiques** dans plusieurs entités :

```
User:     addressStreet, addressCity, addressZipCode, addressCountry
Company:  addressStreet, addressCity, addressZipCode, addressCountry
Order:    shippingStreet, shippingCity, shippingZipCode, shippingCountry
```

→ Un seul VO `Address` réutilisable dans le SharedKernel ou le BC concerné.

## Phase 2 — Rapport d'analyse

Présenter le rapport avant toute modification.

### 2.1 Format du rapport

**Consulter `references/report-template.md`** pour le template complet du rapport d'analyse.

Le rapport doit inclure :
- Résumé (entités analysées, groupes détectés par niveau de recommandation, doublons inter-entités)
- Section par entité avec chaque groupe candidat (champs, score, raisons, VO proposé)
- Doublons inter-entités (groupes identiques dans plusieurs entités)
- Arborescence cible (fichiers à créer/modifier)

**Présenter le rapport à l'utilisateur et attendre sa validation avant de passer à la Phase 3.**

## Phase 3 — Génération du code

**Seulement après validation de l'utilisateur.** Si `--dry-run`, s'arrêter à la Phase 2.

### 3.1 Règles de génération des Value Objects

**Consulter `references/extraction-patterns.md`** pour les templates complets de chaque type de VO (Address, Money, Email, DateRange, Coordinates, FullName, Dimensions, Percentage, EntityId) avec leur mapping XML et attributs.

#### Principes de génération (résumé)

**VO avec mapping XML (recommandé)** : la classe VO est un POPO pur (`readonly class`) sans attribut Doctrine. Le mapping est dans un fichier `.orm.xml` séparé en Infrastructure.

**VO avec attributs Doctrine (alternative)** : la classe VO porte les attributs `#[ORM\Embeddable]` et `#[ORM\Column]`. Plus simple mais couple le Domain au framework.

**Chaque VO doit** :
- Être `readonly class` avec `declare(strict_types=1)`
- Valider ses invariants dans le constructeur
- Avoir une méthode `equals(self $other): bool`
- Avoir `__toString()` quand pertinent

### 3.2 Patterns de VO courants

Consulter `references/extraction-patterns.md` pour les templates de chaque type de VO (Money, DateRange, Email, Coordinates, etc.).

### 3.2bis Custom Doctrine Types (alternative aux Embeddables)

Pour les Value Objects **mono-champ**, un Custom Doctrine Type est souvent préférable à un Embeddable.

#### Table de décision

| Critère | Embeddable | Custom Type |
|---------|-----------|-------------|
| Multi-champs (Address, DateRange) | Oui | Non |
| Mono-champ (Email, Slug) | Possible mais lourd | Préféré |
| Column prefix | Automatique | Pas de prefix |
| Réutilisabilité cross-entity | Bonne | Excellente |
| Nombre de colonnes en base | N colonnes | 1 colonne |
| Complexité mapping | Moyenne | Faible |

#### Quand préférer un Custom Type

- Le VO n'a qu'**un seul champ** (Email, Slug, Currency, PhoneNumber)
- On veut garder **une seule colonne** en base (pas de column prefix)
- Le VO est réutilisé dans **beaucoup d'entités** (un type suffit, pas besoin de mapping embedded partout)

#### Template de Custom Doctrine Type

```php
<?php

declare(strict_types=1);

namespace App\SharedKernel\Infrastructure\Persistence\Doctrine\Type;

use App\SharedKernel\Domain\ValueObject\Email;
use Doctrine\DBAL\Platforms\AbstractPlatform;
use Doctrine\DBAL\Types\StringType;

final class EmailType extends StringType
{
    public function convertToPHPValue(mixed $value, AbstractPlatform $platform): ?Email
    {
        if ($value === null) {
            return null;
        }

        return new Email((string) $value);
    }

    public function convertToDatabaseValue(mixed $value, AbstractPlatform $platform): ?string
    {
        if ($value === null) {
            return null;
        }

        if ($value instanceof Email) {
            return (string) $value;
        }

        return (string) $value;
    }
}
```

> **Compatibilité Doctrine** : `getName()` est supprimé en DBAL 4+. Le nom du type est défini uniquement dans la configuration YAML (`doctrine.dbal.types`). Vérifier la version de Doctrine DBAL installée (`composer show doctrine/dbal`) avant d'utiliser ce template — l'API des types de base (`StringType`, etc.) peut varier entre DBAL 3 et DBAL 4.

#### Enregistrement dans la configuration Doctrine

```yaml
# config/packages/doctrine.yaml
doctrine:
    dbal:
        types:
            email_vo: App\SharedKernel\Infrastructure\Persistence\Doctrine\Type\EmailType
```

#### Utilisation dans l'entité (avec attributs)

```php
#[ORM\Column(type: 'email_vo', length: 255)]
private Email $email;
```

#### Utilisation dans l'entité (avec XML)

```xml
<field name="email" type="email_vo" length="255"/>
```

### 3.3 Règles pour la modification des entités

#### Avant (champs scalaires) :

```php
class User
{
    private string $addressStreet;
    private string $addressCity;
    private string $addressZipCode;
    private string $addressCountry;
    private string $email;

    public function getAddressStreet(): string { return $this->addressStreet; }
    public function setAddressStreet(string $street): void { $this->addressStreet = $street; }
    // ... 6 autres getters/setters
}
```

#### Après (Value Objects) :

```php
class User
{
    private Address $address;
    private Email $email;

    public function address(): Address
    {
        return $this->address;
    }

    public function relocate(Address $newAddress): void
    {
        $this->address = $newAddress;
        // Optionnel: $this->recordEvent(new UserRelocated(...));
    }

    public function changeEmail(Email $newEmail): void
    {
        $this->email = $newEmail;
    }
}
```

**Règles de transformation :**

1. **Supprimer les champs scalaires individuels** — les remplacer par le VO.
2. **Supprimer les getters/setters individuels** — les remplacer par :
   - Un getter qui retourne le VO entier : `address(): Address`
   - Une méthode métier pour la modification : `relocate(Address)`, `changeEmail(Email)`
3. **Pas de setter pour le VO** — les VO sont immutables. Pour modifier, on crée une nouvelle instance.
4. **Adapter le constructeur de l'entité** — accepter les VO au lieu des scalaires.
5. **Adapter les factories / méthodes de création** si elles existent.

### 3.4 Gestion des champs nullables

Si un groupe contient des champs nullables, deux stratégies :

**Option A — VO nullable (simple) :**
```php
class Order
{
    private ?Address $shippingAddress = null;

    public function assignShippingAddress(Address $address): void
    {
        $this->shippingAddress = $address;
    }
}
```

**Option B — Null Object Pattern (avancé) :**
```php
class Address
{
    public static function empty(): self
    {
        return new self(street: '', city: '', zipCode: '', country: '');
    }

    public function isEmpty(): bool
    {
        return $this->street === '' && $this->city === '';
    }
}
```

Demander à l'utilisateur sa préférence si des champs nullables sont détectés.

### 3.5 Ordre de génération

1. **Value Objects d'abord** :
   - VO SharedKernel (réutilisables : `Address`, `Money`, `Email`)
   - VO spécifiques au BC (`Dimensions`, `PriceRange`)
   - Validation des invariants dans le constructeur
   - Méthode `equals()` sur chaque VO
   - Méthode `__toString()` quand pertinent

2. **Mapping Doctrine ensuite** :
   - Mapping XML ou attributs pour chaque VO (Embeddable)
   - Modification du mapping de l'entité parente (Embedded)
   - Column prefix cohérent avec les noms de colonnes existants

3. **Entités en dernier** :
   - Remplacement des champs scalaires par les VO
   - Suppression des getters/setters individuels
   - Ajout de méthodes métier
   - Adaptation du constructeur

### 3.6 Compatibilité avec les colonnes existantes

**CRITIQUE** : les colonnes en base ne doivent PAS changer de nom après l'extraction.

Si avant : `address_street`, `address_city`, `address_zip_code`, `address_country`

Alors le mapping doit utiliser `column-prefix="address_"` et les noms de champs VO doivent correspondre :
- `Address::$street` → colonne `address_street`
- `Address::$city` → colonne `address_city`

Si les colonnes originales n'ont pas de préfixe commun (ex: `street`, `city`, `zip`, `country` sans préfixe), utiliser `column-prefix=""` et nommer les champs du VO exactement comme les colonnes, ou utiliser des mappings `column` explicites.

**Ne jamais générer de migration qui renomme des colonnes sans avertir l'utilisateur.**

## Phase 4 — Vérification

### 4.1 Checklist de vérification

- [ ] Chaque VO est `readonly class`
- [ ] Chaque VO valide ses invariants dans le constructeur
- [ ] Chaque VO a une méthode `equals(self $other): bool`
- [ ] `declare(strict_types=1)` sur tous les fichiers
- [ ] Le VO ne contient aucune logique de persistence
- [ ] Si mapping XML : le VO ne contient aucun attribut Doctrine
- [ ] Le mapping Embeddable est cohérent avec les colonnes existantes
- [ ] Le `column-prefix` préserve les noms de colonnes actuels
- [ ] Les getters/setters individuels sont supprimés de l'entité
- [ ] Les méthodes métier remplacent les setters (`relocate()`, `changeEmail()`)
- [ ] Les VO SharedKernel sont dans `src/SharedKernel/Domain/ValueObject/`
- [ ] Les VO spécifiques sont dans `src/<BC>/Domain/ValueObject/`
- [ ] Le Bounded Context est respecté (pas d'import cross-BC sauf SharedKernel)

### 4.2 Vérification technique

Exécuter :
- `make phpstan` — analyse statique (vérifier les types)
- `make cs-fix` — code style
- `make test` — tests existants

**Vérifier spécifiquement :**
- Que les repositories compilent (ils utilisent peut-être les anciens champs scalaires dans leurs queries DQL/QueryBuilder)
- Que les formulaires Symfony référençant les anciens champs sont adaptés
- Que les serializers / normalizers gèrent les VO

Signaler les échecs et proposer des corrections.

### 4.3 Migration Doctrine

Générer une migration pour vérifier que le schéma est inchangé :

```bash
make migration
```

**La migration devrait être vide** si le mapping est correct (mêmes colonnes, mêmes types). Si la migration contient des changements de colonnes, c'est un signe que le mapping est incorrect — corriger avant de continuer.

### 4.4 Tests des Value Objects

Pour chaque VO généré, proposer un test :

```php
final class AddressTest extends TestCase
{
    public function test_it_creates_valid_address(): void
    {
        $address = new Address(
            street: '42 rue du Code',
            city: 'Paris',
            zipCode: '75001',
            country: 'FR',
        );

        self::assertSame('42 rue du Code', $address->street);
        self::assertSame('Paris', $address->city);
    }

    public function test_it_rejects_empty_street(): void
    {
        $this->expectException(\InvalidArgumentException::class);
        new Address(street: '', city: 'Paris', zipCode: '75001', country: 'FR');
    }

    public function test_equality(): void
    {
        $a = new Address('42 rue du Code', 'Paris', '75001', 'FR');
        $b = new Address('42 rue du Code', 'Paris', '75001', 'FR');
        $c = new Address('1 avenue Foch', 'Paris', '75116', 'FR');

        self::assertTrue($a->equals($b));
        self::assertFalse($a->equals($c));
    }
}
```

## Phase 5 — Bilan et mise à jour documentaire (OBLIGATOIRE)

Appliquer les obligations de `~/.claude/stacks/skill-directives.md` (Phase Finale), puis :

1. **Produire un résumé final** selon le template dans `references/report-template.md` (section "Template résumé Phase 5").

## Skills complémentaires

Selon les résultats de l'analyse, suggérer à l'utilisateur :

| Si... | Alors suggérer |
|-------|---------------|
| Code smells dans les entités (god class, logique complexe) | `/refactor` pour nettoyer |
| Entités avec setters et logique mêlée | `/extract-to-cqrs` si des controllers sont couplés |
| Score legacy inconnu | `/full-audit` pour un audit global |
| Couplage entre entités de BC différents | `/dependency-diagram` pour cartographier |

## Directives

Appliquer les directives communes de `skill-directives.md`.

Directives spécifiques à ce skill :
- **Préserver les colonnes** : ne jamais proposer de renommer des colonnes en base. Le refactoring est côté PHP uniquement, le schéma SQL reste identique.
- **Pas de sur-ingénierie VO** : si un champ `status` a 3 valeurs, un enum PHP suffit. Si un champ `email` n'a aucune validation métier, le garder en `string` est acceptable.
- **SharedKernel vs BC-specific** : les VO génériques (`Email`, `Money`, `Address`) vont dans le SharedKernel. Les VO spécifiques (`ProductDimensions`, `OrderPriority`) restent dans leur BC.
- **Champs uniques** : ne pas forcer l'extraction d'un champ unique en VO si le gain est faible. Signaler mais laisser l'utilisateur décider.
