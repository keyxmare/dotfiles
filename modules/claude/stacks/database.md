# Stack — Base de données

## Moteur recommandé

- **PostgreSQL** — Choix par défaut pour les nouveaux projets (JSONB, full-text search, performance, écosystème).
- **MySQL / MariaDB** — Acceptable si le projet l'impose ou si l'hébergement le contraint.
- **SQLite** — Uniquement pour les tests d'intégration en mémoire ou les petits projets mono-utilisateur.

## Conventions de nommage

### Tables

- Noms au pluriel, en snake_case : `users`, `order_items`, `product_categories`.
- Tables de jointure : concaténation des deux tables au singulier, ordre alphabétique : `product_tag`, `role_user`.

### Colonnes

- snake_case : `first_name`, `created_at`, `is_active`.
- Clé primaire : `id` (UUIDv7 recommandé — triable chronologiquement, performant sur les index B-tree. Auto-increment acceptable pour les projets simples). Génération : Symfony Uid (`Uuid::v7()`). Voir [symfony.md#identifiants](./symfony.md#identifiants) pour les conventions.
- Clés étrangères : `<table_singulier>_id` → `user_id`, `order_id`.
- Booléens : préfixés par `is_` ou `has_` → `is_active`, `has_verified_email`.
- Timestamps : suffixés par `_at` → `created_at`, `updated_at`, `deleted_at`.
- Toujours inclure `created_at` et `updated_at` sur chaque table.

### Index

- Nommage explicite : `idx_<table>_<colonnes>` → `idx_users_email`, `idx_orders_user_id_status`.
- Index unique : `uniq_<table>_<colonnes>` → `uniq_users_email`.
- Indexer systématiquement : clés étrangères, colonnes de filtrage fréquent, colonnes de tri.

### Contraintes

- Clé primaire : `pk_<table>` → `pk_users`.
- Clé étrangère : `fk_<table>_<table_cible>` → `fk_orders_users`.
- Check : `chk_<table>_<description>` → `chk_products_price_positive`.

## Migrations

### Principes

- Une migration = un changement atomique.
- Les migrations sont versionnées et séquentielles.
- Jamais de modification d'une migration déjà exécutée en production.
- Toujours écrire la migration `up` ET la migration `down` (rollback).
- Tester le rollback avant de merger.

### Bonnes pratiques

- Séparer les migrations de structure (DDL) et les migrations de données (DML).
- Les migrations de données sont exceptionnelles et doivent être idempotentes.
- Ne jamais utiliser de modèle ORM dans une migration (le modèle peut évoluer, la migration doit rester stable).
- Nommer les migrations de manière descriptive : `create_users_table`, `add_email_to_orders`, `drop_legacy_columns`.

## Seeding / Fixtures

- Les fixtures sont séparées des migrations.
- Distinguer les données de référence (seeds) des données de test (fixtures).
- Seeds : données nécessaires au fonctionnement (rôles, pays, statuts). Idempotentes, exécutables en production.
- Fixtures : données de développement/test uniquement. Jamais en production.

## Soft delete

- Utiliser `deleted_at` (nullable timestamp) plutôt qu'un booléen `is_deleted`.
- Appliquer un filtre global pour exclure les enregistrements supprimés par défaut.
- Permettre de requêter les enregistrements supprimés explicitement quand nécessaire.

## Performance

- Ne pas faire de `SELECT *`. Sélectionner uniquement les colonnes nécessaires.
- Utiliser la pagination sur toutes les requêtes de listing.
- Surveiller les requêtes N+1 (utiliser le profiler Doctrine, les relations eager/lazy).
- Utiliser des index composites pour les requêtes multi-colonnes fréquentes.
- Analyser les requêtes lentes avec `EXPLAIN`.

## Sécurité

- Voir [security.md](./security.md) pour les règles de protection contre l'injection SQL.
- Utiliser un utilisateur de base de données avec des droits limités (pas de root en production).
- Chiffrer les données sensibles au repos si nécessaire.
- Logs d'accès aux données sensibles.
