# Stratégie de tests

## Pyramide de tests par couche DDD

### Unit Tests — Couche Domain
- Tester **toute** la logique métier : entités, value objects, domain services, specifications.
- Pas de mock de framework. Le domaine n'a aucune dépendance externe.
- Rapides, isolés, déterministes.
- Couvrir : invariants, règles métier, edge cases, domain events émis.
- Nommage : `test<Action>_<Scenario>_<ExpectedResult>` ou `it_should_<behavior>`.

### Integration Tests — Couche Infrastructure
- Tester les adapters : repositories Doctrine, services externes, bus de messages.
- Utiliser une vraie base de données (SQLite en mémoire ou MySQL de test via Docker).
- Vérifier que le mapping Doctrine est correct.
- Vérifier que les queries complexes retournent les bons résultats.

### Functional Tests — Couche Application / API
- Tester les endpoints HTTP de bout en bout (WebTestCase Symfony).
- Vérifier : status codes, structure de réponse, validation, authentification.
- Tester le flux complet : requête → command/query → réponse.
- Utiliser des fixtures pour l'état initial.

## Règles
- Les tests du Domain sont la priorité absolue. C'est là que vit la logique métier.
- Pas de test qui dépend de l'ordre d'exécution.
- Chaque test arrange son propre état (pas de données partagées entre tests).
- Les tests doivent documenter le comportement attendu : lire un test = comprendre la règle métier.
- Pas de `@depends` entre tests.
- Utiliser des Object Mothers ou Builders pour construire les entités de test.
