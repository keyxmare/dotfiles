# Stack Logging

## Monolog / Symfony

### Principes
- Utiliser Monolog via l'injection de `LoggerInterface`.
- Logs structurés : toujours passer un contexte en second argument.
- Ne jamais concaténer des données dans le message. Utiliser les placeholders.

```php
// BON
$this->logger->info('Order created', ['orderId' => $order->id()->toString(), 'userId' => $userId]);

// MAUVAIS
$this->logger->info('Order ' . $order->id() . ' created by ' . $userId);
```

### Niveaux de log par couche DDD

| Couche | Niveaux | Usage |
|--------|---------|-------|
| Domain | — | Le domaine ne logge PAS. Il émet des Domain Events. |
| Application | `info`, `warning` | Résultat des commandes/queries, cas métier inattendus. |
| Infrastructure | `debug`, `info`, `error`, `critical` | Appels externes, erreurs techniques, performance. |

### Règles
- **Le domaine ne logge jamais.** Si un fait métier doit être tracé, émettre un Domain Event.
- Log `error` : erreur récupérable qui nécessite une attention.
- Log `critical` : erreur qui empêche le fonctionnement d'une feature.
- Log `warning` : situation anormale mais gérée (retry, fallback).
- Log `info` : événements métier significatifs (commande traitée, utilisateur créé).
- Log `debug` : détails techniques pour le debugging (désactivé en prod).
- Toujours inclure un identifiant de corrélation (request ID, order ID) dans le contexte.
- Ne jamais logger de données sensibles (mots de passe, tokens, données personnelles).

### Channels
- Utiliser des channels Monolog séparés par Bounded Context ou module.
- Configurer les handlers par environnement (dev: stream, prod: rotating file ou service externe).
