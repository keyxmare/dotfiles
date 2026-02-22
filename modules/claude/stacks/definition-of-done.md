# Definition of Done

## Checklist avant de considérer une tâche terminée

### Code
- [ ] Le code respecte l'architecture DDD (bonne couche, pas de fuite de dépendances).
- [ ] Les entités du Domain n'ont aucune dépendance framework.
- [ ] Les Value Objects sont immutables et valident leurs invariants.
- [ ] Pas de setters publics sur les entités.
- [ ] `declare(strict_types=1)` sur tous les fichiers PHP.
- [ ] Nommage ubiquitaire respecté (langage métier).

### Qualité
- [ ] `make cs-fix` exécuté — pas d'erreurs de style.
- [ ] `make phpstan` passe sans erreur au niveau configuré.
- [ ] Pas de code mort, pas de `dump()`, `dd()`, `var_dump()` oubliés.

### Tests
- [ ] Tests unitaires pour la logique Domain (entités, VO, domain services).
- [ ] Tests d'intégration pour les repositories Doctrine si nouveau repository.
- [ ] Tests fonctionnels pour les nouveaux endpoints API.
- [ ] `make test` passe — aucune régression.

### Sécurité
- [ ] Validation sur tous les inputs utilisateur.
- [ ] Voters en place si nouvelle ressource protégée.
- [ ] Pas de données sensibles exposées dans les réponses API.
- [ ] Pas de concaténation SQL ou de `|raw` Twig.

### Documentation projet
- [ ] `FEATURES.md` mis à jour si nouvelle feature ou changement fonctionnel.
- [ ] `TASKS.md` mis à jour (tâche marquée terminée).
- [ ] `MEMORY.md` mis à jour si décision architecturale ou contexte important.

### Git
- [ ] Commit en conventional commits.
- [ ] Un commit = un changement logique cohérent.
- [ ] Message clair avec le "pourquoi".

## Quand ne pas tout appliquer
- Hotfix critique : tests + sécurité obligatoires, le reste peut suivre.
- Prototype / spike : signaler clairement que ce n'est pas production-ready.
