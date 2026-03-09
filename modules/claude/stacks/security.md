# Stack — Sécurité

## Principes

- La sécurité est une préoccupation transverse, pas une feature optionnelle.
- Defense in depth : plusieurs couches de protection.
- Principle of least privilege : accorder le minimum de droits nécessaires.
- Ne jamais faire confiance aux entrées utilisateur.

## Validation des entrées

- Valider toutes les entrées aux frontières du système (controllers, API, formulaires).
- Utiliser une liste blanche (ce qui est autorisé) plutôt qu'une liste noire (ce qui est interdit).
- Typer et contraindre les entrées : longueur max, format, plage de valeurs.
- Valider côté serveur systématiquement, même si une validation côté client existe.
- Encoder les sorties en fonction du contexte (HTML, JSON, SQL, URL).

## Injection

### SQL Injection

- Toujours utiliser des requêtes paramétrées / prepared statements.
- Ne jamais concaténer des entrées utilisateur dans une requête SQL.
- Utiliser l'ORM (Doctrine, Prisma, etc.) pour les requêtes standards.

### XSS (Cross-Site Scripting)

- Encoder les sorties HTML systématiquement (les frameworks le font par défaut : Twig, Vue.js).
- Ne jamais utiliser `v-html` ou équivalent avec des données utilisateur.
- Configurer une Content Security Policy (CSP) stricte.

### Command Injection

- Ne jamais passer d'entrées utilisateur directement à un shell.
- Utiliser les API natives du langage plutôt que des commandes système.

### SSRF (Server-Side Request Forgery)

- Ne jamais faire de requête HTTP côté serveur vers une URL fournie par l'utilisateur sans validation.
- Valider et restreindre les URLs cibles : bloquer les adresses privées (127.0.0.0/8, 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16, 169.254.0.0/16), les schémas non-HTTP (`file://`, `gopher://`, etc.).
- Utiliser une liste blanche de domaines autorisés quand c'est possible (webhooks, imports).
- Limiter les redirections suivies automatiquement.
- Pertinent dès qu'un backend traite des URLs utilisateur : webhooks, import de fichier distant, aperçu d'URL, proxy d'images.

## Authentification

- Hasher les mots de passe avec bcrypt, argon2 ou scrypt. Jamais MD5/SHA1.
- Imposer une politique de mots de passe robuste (longueur min 12, complexité).
- Implémenter le rate limiting sur les endpoints d'authentification (Symfony : composant `RateLimiter` via `RateLimiterFactory` injecté dans les controllers, ou config `login_throttling` du firewall).
- Verrouiller le compte après X tentatives échouées.
- Utiliser des tokens JWT avec expiration courte + refresh token.

## Autorisation

- Vérifier les permissions à chaque requête, jamais côté client uniquement.
- Utiliser RBAC (Role-Based Access Control) ou ABAC (Attribute-Based Access Control).
- Vérifier que l'utilisateur a accès à la ressource spécifique (IDOR protection).

## CSRF (Cross-Site Request Forgery)

- Activer la protection CSRF sur toutes les routes qui modifient l'état.
- Utiliser le pattern double-submit cookie ou synchronizer token.
- Les API stateless avec JWT Bearer sont naturellement protégées.

## CORS (Cross-Origin Resource Sharing)

- Configurer une liste blanche stricte des origines autorisées.
- Ne jamais utiliser `Access-Control-Allow-Origin: *` en production.
- Limiter les méthodes et headers autorisés au strict nécessaire.

## Headers de sécurité

Headers à configurer systématiquement :

| Header | Valeur | Objectif |
|---|---|---|
| `Strict-Transport-Security` | `max-age=31536000; includeSubDomains` | Forcer HTTPS |
| `X-Content-Type-Options` | `nosniff` | Empêcher le MIME sniffing |
| `X-Frame-Options` | `DENY` | Empêcher le clickjacking |
| `Content-Security-Policy` | Voir exemple ci-dessous | Contrôler les sources autorisées |
| `Referrer-Policy` | `strict-origin-when-cross-origin` | Limiter les infos du referrer |
| `Permissions-Policy` | Selon le projet | Restreindre les API navigateur |

### CSP de base (à adapter par projet)

```
default-src 'self'; script-src 'self'; style-src 'self' 'unsafe-inline'; img-src 'self' data:; font-src 'self'; connect-src 'self'; frame-ancestors 'none'; base-uri 'self'; form-action 'self'
```

- `'unsafe-inline'` pour les styles est souvent nécessaire avec les frameworks CSS. Le supprimer si possible.
- Ajouter les domaines tiers nécessaires (CDN, APIs externes, analytics).
- En dev, la CSP peut être assouplie (hot-reload, WebSocket). Ne pas reproduire ces assouplissements en prod.

## Gestion des secrets {#secrets}

- Ne jamais committer de secrets dans le code (clés API, mots de passe, tokens, credentials, `.env`).
- Utiliser des variables d'environnement ou un gestionnaire de secrets (Vault, AWS Secrets Manager, etc.).
- Versionner un `.env.example` avec des valeurs factices, jamais le `.env` réel.
- Ne jamais versionner les fichiers `.env` contenant de vraies valeurs. Seuls les `.env.example` et les fichiers `.env` de valeurs par défaut de framework (ex: Symfony `backend/.env`) sont versionnés.
- En Docker, utiliser `--mount=type=secret` pour le build et `secrets` dans compose pour le runtime.
- Toujours inclure un `.dockerignore` pour exclure les fichiers sensibles (.env, .git, etc.).
- Configurer `.gitignore` rigoureusement pour exclure tout fichier contenant des secrets.
- Faire tourner les secrets régulièrement (rotation).

## Dépendances

- Mettre à jour les dépendances de sécurité rapidement.
- Épingler les versions des dépendances (lock files).
- Utiliser Dependabot ou Renovate pour automatiser les mises à jour.
- L'audit des dépendances (`composer audit`, `pnpm audit`) est exécuté dans le pipeline CI. → Voir [ci.md](./ci.md) pour la configuration du job Security Audit.

## SAST — Analyse statique de sécurité {#sast}

← `security.sast`

Quand `security.sast` = `true`, scanner le code source pour détecter des vulnérabilités (injection, XSS, auth bypass, etc.) au-delà de ce que couvrent les linters classiques.

### Outils recommandés

| Stack | Outil | Usage |
|---|---|---|
| Multi-stack | [Semgrep](https://semgrep.dev) | Règles communautaires + custom, rapide, CI-friendly |
| PHP | [Psalm (taint analysis)](https://psalm.dev/docs/security_analysis/) | Détection de flux de données non sûrs |
| Node/TS | ESLint security plugins | `eslint-plugin-security`, `eslint-plugin-no-unsanitized` |

### Intégration

- Ajouter au job `security` du pipeline CI (parallèle avec `audit`).
- Target Makefile : `sast` → `$(EXEC) vendor/bin/semgrep --config auto` ou équivalent.
- En local, exécuter avant chaque PR. Ne pas bloquer le dev pour les findings `info`/`low`.
- Bloquer la CI pour les findings `high`/`critical`.

## Secret scanning {#secret-scanning}

← `security.secret_scanning`

Quand `security.secret_scanning` = `true`, scanner le repo pour détecter les secrets commités accidentellement (clés API, tokens, mots de passe).

### Outils recommandés

| Outil | Usage |
|---|---|
| [gitleaks](https://github.com/gitleaks/gitleaks) | Scanner le repo et les commits. Léger, CI-friendly. |
| [trufflehog](https://github.com/trufflesecurity/trufflehog) | Détection de secrets avec vérification active (teste si le secret est valide). |
| GitHub Secret Scanning | Intégré à GitHub, détection automatique sur push. |

### Intégration

- **Pre-commit hook** (Lefthook) : scanner les fichiers stagés avant chaque commit.
- **CI** : scanner l'historique complet sur chaque PR.
- Si un secret est détecté : **révoquer immédiatement** le secret, puis nettoyer l'historique git si nécessaire.
- Configuration `.gitleaks.toml` à la racine du projet pour les règles custom et les exceptions.

### Template Lefthook

```yaml
pre-commit:
  commands:
    secret-scan:
      run: gitleaks protect --staged --no-banner
      fail_text: "Secret détecté dans les fichiers stagés"
```

## Logging et monitoring

- Ne jamais logger de données sensibles (mots de passe, tokens, données personnelles).
- Logger les tentatives d'authentification échouées.
- Logger les accès aux ressources sensibles.
- Utiliser du structured logging (JSON) pour faciliter l'analyse.
- Mettre en place des alertes sur les comportements anormaux.
