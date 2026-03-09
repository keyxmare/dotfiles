# Référence — Diagnostic et résolution d'erreurs

## Erreurs courantes du scaffold

Si `make quality` échoue, vérifier en priorité :

| Erreur | Cause probable | Correction |
|---|---|---|
| Doctrine mapping not found | Attributs ORM manquants sur l'entité | Vérifier les attributs `#[ORM\Entity]`, `#[ORM\Column]` sur le domain model |
| Class not found (autowiring) | Namespace manquant dans `services.yaml` | Ajouter le resource pour le bounded context |
| Route not found | Fichier routes non importé | Vérifier `config/routes/*.yaml` importe le controller |
| TypeScript: Module not found | Alias `@` mal configuré ou path manquant dans `tsconfig.json` | Vérifier `compilerOptions.paths` et `vite.config.ts` alias |
| Vitest: Cannot find module | Import path incohérent avec la structure DDD | Vérifier `vitest.config.ts` alias et les paths d'import |
| PHPStan: Undefined method | Interface repository non implémentée | Vérifier que `Infrastructure/Persistence/Doctrine/*Repository.php` implémente l'interface |
| Docker: Service unhealthy | Healthcheck trop agressif ou service pas prêt | Augmenter `start_period` dans le healthcheck |
| Messenger: No handler found | Handler non taggé ou mauvais bus | Vérifier `#[AsMessageHandler(bus: '...')]` et le routing dans `messenger.yaml` |
| Pest: Class not found | `pest.php` ne charge pas les bons répertoires | Vérifier les `uses()->in()` dans `pest.php` |
| Pest: beforeEach not defined | Fichier de test sans `uses()` pour les test cases | Ajouter `uses(TestCase::class)` si nécessaire |
| Rate limiter: service not found | `symfony/rate-limiter` non installé | Ajouter au `composer.json` + `make install` |
| PATCH 405 Method Not Allowed | Route PATCH non déclarée | Vérifier l'attribut `#[Route(methods: ['PATCH'])]` sur le controller |
| CSP violation en console | Content-Security-Policy trop restrictif | Adapter le CSP dans `SecurityHeadersListener` selon la stack frontend |
| Factory: class not found | Autoload test non configuré | Vérifier `autoload-dev.psr-4` dans `composer.json` inclut `Tests\\Factory\\` |
| Rector: rule conflict | Rector et PHP-CS-Fixer modifient le même fichier | Exécuter Rector avant PHP-CS-Fixer (`make rector && make lint-fix`) |
| Deptrac: layer violation | Import cross-couche interdit | Vérifier les dépendances dans le code incriminé, déplacer dans la bonne couche ou passer par une interface |
| eslint-plugin-boundaries: disallowed | Import cross-context frontend | Déplacer le code partagé dans `shared/` ou créer un service dédié |
| SQLite: SQLSTATE[HY000] | Fichier BDD SQLite manquant ou permissions | Vérifier `var/data.db` existe, permissions en écriture sur `var/` |
| Testcontainers: Docker not available | Docker daemon pas démarré pour les tests | Vérifier que Docker tourne : `docker info` |
| Taskfile: task not found | Target manquante dans Taskfile.yml | Vérifier le nom de la tâche dans `Taskfile.yml` |
| skill_version mismatch | Projet généré avec une ancienne version du skill | Exécuter `/new-project:sync` pour mettre à jour les conventions |
| ObjectMapper: Cannot map | Attributs `#[Map]` manquants ou incompatibles sur DTO/Entity | Vérifier les attributs `#[Map(target: ...)]` sur les propriétés source et la correspondance des types |
| Shadcn-vue: component not found | Composant non ajouté via CLI | Lancer `npx shadcn-vue@latest add <component>` dans le container frontend |
| Nuxt UI: module not found | Module `@nuxt/ui` non installé | Vérifier `package.json` et `nuxt.config.ts` modules |
| OpenTelemetry: exporter error | OTLP endpoint non accessible | Vérifier que Jaeger est démarré : `docker compose ps jaeger` |
| /healthz returns 503 | Service dépendant down | Vérifier les healthchecks Docker : `docker compose ps` |
| versions.json stale | `last_verified` > 90 jours | Mettre à jour `versions.json` et vérifier les versions via context7/packagist/npm |

## Rollback automatique

Si `make quality` échoue après 3 tentatives de correction, proposer :

```
Le scaffold ne passe pas les checks après 3 corrections.
Options :
  1. Continuer le diagnostic
  2. Rollback (git reset --hard) et ajuster le plan
  3. Demander de l'aide
```

## Démarche de diagnostic

1. Lire le message d'erreur complet (pas seulement la première ligne).
2. Identifier le fichier et la ligne concernés.
3. Vérifier le tableau ci-dessus pour une correspondance.
4. Si l'erreur n'est pas dans le tableau, chercher dans la documentation de la lib concernée (context7 / web).
5. Corriger et relancer `make quality` — ne corriger qu'une erreur à la fois.
6. Si le problème persiste après 3 tentatives, proposer le rollback.
