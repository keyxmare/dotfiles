# Stack Sécurité

## Principes généraux
- Appliquer le principe du moindre privilège partout.
- Ne jamais faire confiance aux données utilisateur. Toujours valider et sanitizer.
- Fail secure : en cas de doute, refuser l'accès.

## OWASP Top 10 — Règles Symfony

### Injection (SQL, Command, LDAP)
- Toujours utiliser le QueryBuilder Doctrine ou les paramètres préparés. JAMAIS de concaténation SQL.
- Utiliser le composant Process de Symfony pour les commandes système. JAMAIS de `exec()` / `shell_exec()`.

### Broken Authentication
- Utiliser le composant Security de Symfony pour l'authentification.
- Hasher les mots de passe avec `PasswordHasherInterface` (bcrypt/argon2).
- Implémenter le rate limiting sur les endpoints d'authentification.

### XSS (Cross-Site Scripting)
- Twig échappe par défaut (`{{ }}`). Ne JAMAIS utiliser `|raw` sauf nécessité absolue validée.
- Valider et sanitizer les entrées côté serveur avec les constraints Symfony.

### CSRF
- Activer la protection CSRF sur tous les formulaires Symfony.
- Utiliser `CsrfTokenManagerInterface` pour les actions sensibles hors formulaire.

### Broken Access Control
- Utiliser les Voters Symfony pour toute logique d'autorisation.
- Vérifier les permissions au niveau du Controller ET du domaine quand c'est critique.
- Ne jamais exposer les IDs internes séquentiels en API : préférer les UUID.

### Security Misconfiguration
- Ne jamais commit de secrets (.env.local, clés API, certificats).
- Utiliser les Symfony Secrets (vault) pour les données sensibles en production.
- Vérifier les headers de sécurité (CSP, HSTS, X-Frame-Options).

### Mass Assignment
- Utiliser des DTOs / Commands explicites. Ne jamais hydrater une entité directement depuis la requête.
- Définir explicitement les champs autorisés dans les formulaires et les sérialiseurs.

## Règles pour Claude
- Alerter immédiatement si du code introduit une vulnérabilité.
- Ne jamais écrire de code qui contourne une protection de sécurité.
- Proposer des Voters pour chaque nouvelle ressource protégée.
- Vérifier la présence de validation sur chaque input utilisateur.
