# Stack API Platform

> **Version cible** : API Platform 4.x (compatible Symfony 8). Les attributs et la configuration varient significativement entre v2, v3 et v4. Toujours vérifier la version installée dans `composer.json` avant d'appliquer ces conventions.

## Conventions REST
- Utiliser API Platform comme couche de présentation API.
- Les ressources API sont des DTOs, pas des entités du domaine.
- Nommage des endpoints : pluriel, kebab-case (`/api/order-items`).

## Architecture avec DDD
- **ApiResource** sur des DTOs (Input/Output), jamais sur les entités du Domain.
- **State Providers** : lisent les données via les Query Handlers (CQRS).
- **State Processors** : dispatchent des Commands via le bus.
- Le domaine ne connaît pas API Platform.

```
Infrastructure/
└── ApiPlatform/
    ├── Resource/
    │   └── OrderResource.php       ← #[ApiResource] sur un DTO
    ├── State/
    │   ├── OrderProvider.php       ← State Provider → Query Bus
    │   └── OrderProcessor.php      ← State Processor → Command Bus
    └── Filter/
        └── OrderDateFilter.php
```

## Serialization
- Utiliser les groupes de sérialisation pour contrôler l'exposition des données.
- Séparer les groupes `read` et `write`.
- Ne jamais exposer les données internes (IDs techniques, timestamps système).

## Validation
- Valider via les constraints Symfony sur les DTOs Input.
- La validation métier reste dans le domaine (entités, value objects).
- Double validation : constraints Symfony (format) + domaine (règles métier).

## Pagination & Filtres
- Pagination activée par défaut. Configurer une limite max raisonnable.
- Utiliser les filtres API Platform (SearchFilter, DateFilter, OrderFilter).
- Filtres custom via des State Providers si la logique est complexe.

## Versioning
- Préfixer les routes : `/api/v1/...`.
- Gérer les breaking changes via de nouvelles ressources, pas en modifiant les existantes.
