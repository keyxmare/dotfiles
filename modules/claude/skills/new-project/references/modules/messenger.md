# Module — messenger

- `config/packages/messenger.yaml` — transports, routing des messages vers les buses.
- Si Docker : service RabbitMQ dans `compose.yaml` avec management UI (port 15672).
- Consumer supervisé dans `compose.yaml` (`php bin/console messenger:consume`).
- Buses configurées : `command.bus`, `query.bus`, `event.bus`.
