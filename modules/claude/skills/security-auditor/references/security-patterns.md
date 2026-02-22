# Patterns de detection — Security Auditor

## Commandes de scan rapide

### Injection SQL
```bash
# Concatenation dans les requetes
grep -rn "createQuery\|executeQuery\|executeStatement\|execute(" src/ | grep -v "setParameter"
grep -rn '"\s*\.\s*\$\|'\''\s*\.\s*\$' src/ --include="*.php" | grep -i "select\|insert\|update\|delete\|where"
```

### XSS
```bash
# Raw filter dans Twig
grep -rn '|raw' templates/
grep -rn 'autoescape false' templates/
# JavaScript inline
grep -rn '<script>' templates/
```

### Command Injection
```bash
grep -rn 'exec(\|shell_exec(\|system(\|passthru(\|popen(\|proc_open(' src/
```

### Secrets hardcodes
```bash
# Patterns de secrets
grep -rn "password\s*=\s*['\"]" src/ config/ --include="*.php" --include="*.yaml"
grep -rn "api_key\|apiKey\|secret_key\|secretKey\|token\s*=\s*['\"]" src/ config/
grep -rn "sk_live_\|pk_live_\|AKIA\|ghp_\|glpat-" src/ config/
# Framework secret hardcode
grep -rn "secret:" config/packages/framework.yaml | grep -v "%env"
```

### Configuration securite
```bash
# Debug en prod
grep -rn "APP_DEBUG=1\|APP_ENV=dev" .env
# Firewall security: false
grep -rn "security: false" config/packages/security.yaml
# CORS permissif
grep -rn "allow_origin.*\*" config/
# Cookies non securises
grep -rn "cookie_secure: false" config/
```

### Dependances
```bash
# Advisories (si symfony CLI disponible)
symfony check:security
# Ou avec local-php-security-checker
local-php-security-checker --path=composer.lock
```

### Voters et autorisation
```bash
# Actions sans controle d'acces
grep -rn "#\[Route" src/ -l | xargs grep -L "IsGranted\|denyAccessUnlessGranted\|security\|isGranted"
# IDOR potentiel (acces par ID sans verification)
grep -rn '\$request->get.*id\|{id}' src/ --include="*.php"
```

## Severite par pattern

| Pattern | Severite |
|---------|---------|
| Concatenation SQL avec donnees utilisateur | Critique |
| `\|raw` sur contenu utilisateur | Critique |
| Secret hardcode (cle API, mot de passe) | Critique |
| `exec()` / `shell_exec()` avec variable | Critique |
| `APP_DEBUG=1` en .env (sans .env.local) | Haute |
| Firewall `security: false` hors test | Haute |
| CORS `allow_origin: *` | Haute |
| Pas de Voter sur une ressource protegee | Haute |
| Cookie `secure: false` | Moyenne |
| Headers de securite manquants | Moyenne |
| Session lifetime trop long (> 3600s) | Info |
| Package avec advisory non critique | Info |

## Faux positifs courants

| Pattern | Pourquoi ce n'est PAS un probleme |
|---------|----------------------------------|
| `\|raw` sur un contenu HTML genere cote serveur (pas d'input utilisateur) | Le contenu est truste |
| `exec()` dans une commande CLI avec arguments hardcodes | Pas d'input utilisateur |
| `security: false` sur le firewall `dev` (when@dev) | Contexte de developpement uniquement |
| Secret dans `.env` comme valeur par defaut (`APP_SECRET=change_me_in_env_local`) | Pas un vrai secret si `.env.local` le surcharge |
| CORS `*` dans `when@dev` | Contexte de developpement uniquement |

## CSRF

### Detection
```bash
# Config CSRF framework
grep -rn "csrf_protection" config/
# Utilisation de tokens CSRF dans le code
grep -rn "isCsrfTokenValid\|CsrfToken" src/
# Formulaires Symfony sans CSRF
grep -rn "csrf_protection.*false" src/ config/
# Champ _token manquant dans les templates de formulaire custom
grep -rn "<form" templates/ | grep -vl "_token"
```

### Patterns dangereux
- Formulaire Symfony avec `'csrf_protection' => false` sans justification
- Formulaire HTML custom sans champ `_token`
- Action POST/PUT/DELETE sans verification CSRF

### Exceptions (ne pas signaler)
- API stateless avec authentification JWT/token : CSRF non necessaire car pas de cookie de session
- Endpoints proteges uniquement par `Authorization: Bearer` header

## Mass Assignment

### Detection
```bash
# Ressources API Platform
grep -rn "#\[ApiResource" src/ --include="*.php"
# Verifier si normalizationContext/denormalizationContext est defini
grep -rn "normalizationContext\|denormalizationContext" src/ --include="*.php"
# Groupes de serialisation sur les proprietes
grep -rn "#\[Groups" src/ --include="*.php"
```

### Patterns dangereux
- `#[ApiResource]` sur une entite sans `normalizationContext` ni `denormalizationContext` → toutes les proprietes sont exposees/modifiables
- DTO sans groupes `#[Groups]` sur les proprietes → pas de controle de l'exposition
- Proprietes sensibles (role, isAdmin, balance) sans restriction d'ecriture

### Severite
| Pattern | Severite |
|---------|---------|
| Entite API sans groupes de serialisation | Haute |
| DTO sans separation read/write | Moyenne |
| Propriete sensible modifiable via API | Critique |

## Path Traversal

### Detection
```bash
# Uploads de fichiers
grep -rn "files->get\|move_uploaded_file\|getPathname\|getClientOriginalName" src/ --include="*.php"
# Lecture de fichier avec input utilisateur
grep -rn "file_get_contents.*\\\$\|readfile.*\\\$\|file_put_contents.*\\\$" src/ --include="*.php"
# Utilisation de chemins utilisateur
grep -rn "realpath\|basename\|dirname" src/ --include="*.php"
```

### Patterns dangereux
- `file_get_contents($request->get('path'))` — lecture arbitraire de fichier
- `readfile($userInput)` — lecture arbitraire
- Upload sans sanitisation du nom de fichier (`../` dans le nom)
- `move()` vers un repertoire construit avec un input utilisateur

### Verification
- Le nom de fichier est-il sanitise (suppression de `../`, caracteres speciaux) ?
- Le repertoire de destination est-il hardcode ou valide ?
- `basename()` est-il utilise pour extraire uniquement le nom de fichier ?

## Open Redirect

### Detection
```bash
# Redirections dans les controllers
grep -rn "redirect\|RedirectResponse" src/ --include="*.php"
# URL provenant du request
grep -rn "request->get.*url\|request->get.*redirect\|request->query->get" src/ --include="*.php"
```

### Patterns dangereux
- `return $this->redirect($request->get('url'))` — redirection non validee
- `new RedirectResponse($request->get('redirect_to'))` — URL non verifiee
- URL de retour apres login non validee contre une whitelist

### Verification
- L'URL de redirection est-elle validee contre une liste de domaines autorises ?
- Utilise-t-on `parse_url()` + verification du host ?
- Les redirections internes utilisent-elles des routes Symfony (pas des URLs brutes) ?

## Rate Limiting

### Detection
```bash
# Config rate limiter Symfony
grep -rn "rate_limiter" config/
# Attributs de rate limiting sur les routes
grep -rn "RateLimit\|Throttle" src/ --include="*.php"
# Routes sensibles (login, register, reset)
grep -rn "#\[Route.*login\|#\[Route.*register\|#\[Route.*reset\|#\[Route.*forgot" src/ --include="*.php"
```

### Routes sensibles sans rate limiting
- `/login`, `/api/login` — brute force de mot de passe
- `/register`, `/api/register` — creation massive de comptes
- `/reset-password`, `/forgot-password` — enumeration d'emails
- Endpoints API publics sans authentification — abus / DoS

### Verification
- `framework.rate_limiter` est-il configure dans `config/packages/framework.yaml` ?
- Les routes sensibles referent-elles un rate limiter ?
- Le rate limiter est-il base sur IP, user, ou les deux ?

## Headers HTTP de securite

### Detection
```bash
# Headers dans le code
grep -rn "X-Content-Type-Options\|X-Frame-Options\|Strict-Transport-Security\|Content-Security-Policy\|Referrer-Policy" src/ config/
# EventListener/Subscriber qui modifient les headers
grep -rn "headers->set\|ResponseEvent\|KernelEvents::RESPONSE" src/ --include="*.php"
# NelmioSecurityBundle
grep -rn "nelmio_security" config/
```

### Checklist des headers attendus

| Header | Valeur attendue | Impact si absent |
|--------|----------------|------------------|
| `X-Content-Type-Options` | `nosniff` | MIME sniffing attack |
| `X-Frame-Options` | `DENY` ou `SAMEORIGIN` | Clickjacking |
| `Strict-Transport-Security` | `max-age=31536000; includeSubDomains` | Downgrade HTTPS → HTTP |
| `Content-Security-Policy` | Politique restrictive adaptee | XSS, injection de scripts |
| `Referrer-Policy` | `strict-origin-when-cross-origin` | Fuite d'informations via referrer |

### Verification
- Les headers sont-ils configures via un EventListener/EventSubscriber sur `kernel.response` ?
- NelmioSecurityBundle est-il installe et configure ?
- La configuration serveur (nginx/apache) ajoute-t-elle ces headers ?

## Secrets patterns additionnels

En complement de la section "Secrets hardcodes" existante, scanner egalement :

```bash
# Bearer token hardcode
grep -rn "Bearer [a-zA-Z0-9_\-\.]\{20,\}" src/ --include="*.php"
# Cles SSH dans le code
grep -rn "ssh-rsa" src/ config/
# Cles privees
grep -rn "BEGIN PRIVATE KEY\|BEGIN RSA PRIVATE KEY" src/ config/
# Certificats
grep -rn "BEGIN CERTIFICATE" src/ config/
```

### Patterns additionnels

| Pattern | Severite |
|---------|---------|
| `Bearer ` suivi d'un token hardcode | Critique |
| `ssh-rsa` dans le code source | Critique |
| `-----BEGIN PRIVATE KEY-----` ou `-----BEGIN RSA PRIVATE KEY-----` | Critique |
| `-----BEGIN CERTIFICATE-----` | Haute |
