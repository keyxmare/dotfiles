# Stack Database Design

## Conventions de nommage

### Tables
- snake_case, pluriel : `orders`, `order_items`, `user_addresses`.
- Préfixer par le Bounded Context si la BDD est partagée : `billing_invoices`, `catalog_products`.
- Tables de jointure : `<table1>_<table2>` par ordre alphabétique : `order_product`.

### Colonnes
- snake_case : `created_at`, `first_name`, `total_amount`.
- Clé primaire : `id` (UUID préféré, jamais auto-increment exposé en API).
- Clés étrangères : `<entity_singulier>_id` → `order_id`, `user_id`.
- Booleans : préfixer par `is_` ou `has_` → `is_active`, `has_paid`.
- Timestamps : suffixer par `_at` → `created_at`, `updated_at`, `deleted_at`.

### Index
- Nommage : `idx_<table>_<colonnes>` → `idx_orders_user_id`, `idx_orders_status_created_at`.
- Unique : `uniq_<table>_<colonnes>` → `uniq_users_email`.
- Foreign key : `fk_<table>_<colonne>` → `fk_orders_user_id`.

## Stratégie d'indexation
- Index sur toutes les clés étrangères.
- Index sur les colonnes de filtre fréquent (status, dates, flags).
- Index composites : colonne la plus sélective en premier.
- Pas d'index sur les colonnes à faible cardinalité seules (boolean).
- Valider avec `EXPLAIN` sur les queries critiques.

## Migrations sécurisées

### Règles non-destructives
- **JAMAIS** de `DROP TABLE` ou `DROP COLUMN` directement en production.
- Processus de suppression de colonne en 3 étapes :
  1. Déployer le code qui n'utilise plus la colonne.
  2. Migration : rendre la colonne nullable (si elle ne l'est pas déjà).
  3. Migration ultérieure : supprimer la colonne.
- Renommage de colonne = ajout nouvelle + copie + suppression ancienne (en 3 déploiements).

### Bonnes pratiques
- Une migration = un changement logique. Pas de migration fourre-tout.
- Toujours réversible : implémenter `down()`.
- Tester les migrations sur un dump de production avant de déployer.
- Les migrations ne contiennent PAS de logique métier (pas de data transformation complexe).
- Pour les data migrations : utiliser des commandes Symfony dédiées, pas des migrations Doctrine.

## Types recommandés

| Donnée | Type MySQL |
|--------|-----------|
| UUID | `CHAR(36)` ou `BINARY(16)` |
| Money | `DECIMAL(10,2)` — jamais `FLOAT` |
| Email | `VARCHAR(254)` |
| Enum/Status | `VARCHAR(32)` — pas d'ENUM MySQL |
| Timestamps | `DATETIME(6)` avec microsecondes |
| Texte long | `TEXT` — pas de `VARCHAR(4000)` |
| JSON | `JSON` natif |
