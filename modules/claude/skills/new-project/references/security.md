# Référence — Sécurité

Éléments de sécurité générés par le scaffold selon la configuration.

---

## Security Headers (si `security.headers` = `true`)

Générer un listener/middleware qui ajoute les headers de sécurité sur toutes les réponses.

### Mode advanced

`src/Shared/Infrastructure/EventListener/SecurityHeadersListener.php` :

```php
<?php

declare(strict_types=1);

namespace App\Shared\Infrastructure\EventListener;

use Symfony\Component\EventDispatcher\Attribute\AsEventListener;
use Symfony\Component\HttpKernel\Event\ResponseEvent;

#[AsEventListener(event: 'kernel.response', priority: -256)]
final class SecurityHeadersListener
{
    public function __invoke(ResponseEvent $event): void
    {
        if (!$event->isMainRequest()) {
            return;
        }

        $response = $event->getResponse();
        $response->headers->set('X-Content-Type-Options', 'nosniff');
        $response->headers->set('X-Frame-Options', 'DENY');
        $response->headers->set('X-XSS-Protection', '0');
        $response->headers->set('Referrer-Policy', 'strict-origin-when-cross-origin');
        $response->headers->set('Permissions-Policy', 'camera=(), microphone=(), geolocation=()');
        $response->headers->set(
            'Content-Security-Policy',
            "default-src 'self'; script-src 'self'; style-src 'self' 'unsafe-inline'; img-src 'self' data:; font-src 'self'; connect-src 'self'; frame-ancestors 'none'"
        );

        if ($event->getRequest()->isSecure()) {
            $response->headers->set('Strict-Transport-Security', 'max-age=31536000; includeSubDomains');
        }
    }
}
```

### Adaptation du CSP

Le CSP par défaut est restrictif. L'adapter selon la stack frontend :

| Framework UI | Ajustements CSP nécessaires |
|---|---|
| Tailwind CSS | Aucun (styles inline via `'unsafe-inline'` déjà inclus) |
| PrimeVue | Ajouter le CDN icons si utilisé : `font-src 'self' https://fonts.googleapis.com` |
| Vuetify | Ajouter `font-src 'self' https://fonts.googleapis.com https://cdn.jsdelivr.net` |

Si Mercure est activé, ajouter `connect-src 'self' https://mercure.mon-domaine.com` pour autoriser les connexions SSE.

### Mode simple

Même fichier dans `src/EventListener/SecurityHeadersListener.php`.

### Enregistrement

Aucune config supplémentaire nécessaire — l'attribut `#[AsEventListener]` suffit avec l'autowiring Symfony.

---

## Rate Limiting (si `security.rate_limiting` = `true`)

Configurer `symfony/rate-limiter` sur les endpoints d'authentification.

### Configuration

`config/packages/rate_limiter.yaml` :

```yaml
framework:
    rate_limiter:
        auth_login:
            policy: sliding_window
            limit: 5
            interval: '1 minute'
        auth_register:
            policy: sliding_window
            limit: 3
            interval: '5 minutes'
```

### Application

Dans les controllers d'auth, injecter le rate limiter :

```php
use Symfony\Component\RateLimiter\RateLimiterFactory;

public function __invoke(
    Request $request,
    #[Autowire(service: 'limiter.auth_login')]
    RateLimiterFactory $limiter,
): JsonResponse {
    $limit = $limiter->create($request->getClientIp())->consume();

    if (!$limit->isAccepted()) {
        return new JsonResponse(
            ['error' => 'Too many attempts. Please try again later.'],
            Response::HTTP_TOO_MANY_REQUESTS,
            ['Retry-After' => $limit->getRetryAfter()->getTimestamp() - time()]
        );
    }

    // ... login logic
}
```

### Dépendance

`symfony/rate-limiter` dans `composer.json`.

---

## CSRF (si sessions, pas JWT)

Si le module `auth` utilise des sessions (frontend présent), configurer la protection CSRF :

- `config/packages/framework.yaml` : `csrf_protection: true`
- Les formulaires Symfony incluent automatiquement le token CSRF.
- Pour l'API avec sessions : ajouter un header `X-CSRF-Token` vérifié par un listener.

---

## Audit de dépendances (si `security.audit` = `true`)

### CI

```yaml
# Dans ci.yml
security:
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v4
    - name: Backend security audit
      run: docker compose exec -T backend composer audit --format=json
    - name: Frontend security audit
      run: docker compose exec -T frontend pnpm audit --audit-level=high
```

### Makefile

```makefile
.PHONY: audit
audit: ## Audit des vulnérabilités des dépendances
	$(DC_EXEC_BACKEND) composer audit
	$(DC_EXEC_FRONTEND) pnpm audit
```

---

## Fichiers sensibles

### .gitignore (ajouts sécurité)

```gitignore
# Secrets
.env.local
.env.*.local
docker/.env
*.key
*.pem

# IDE
.idea/
.vscode/
*.swp
```

### .env.example

Toujours fournir un `.env.example` avec :
- Chaque variable documentée par un commentaire
- Des placeholders explicites pour les secrets : `changeme`, `your-secret-here`, `generate-with-openssl`
- Les variables obligatoires marquées : `# REQUIRED`
- Les variables optionnelles avec leur valeur par défaut

```bash
# REQUIRED — Application
APP_ENV=dev
APP_SECRET=changeme

# REQUIRED — Database
DATABASE_URL="postgresql://app:changeme@database:5432/app?serverVersion=17&charset=utf8"

# Optional — CORS (default: localhost)
CORS_ALLOW_ORIGIN='^https?://(localhost|127\.0\.0\.1)(:[0-9]+)?$'
```

---

## Accessibilité (si `a11y.enabled` = `true`)

### ESLint plugin

Ajouter `eslint-plugin-vuejs-accessibility` aux devDependencies frontend et l'activer dans `eslint.config.js`.

### Structure sémantique

Les layouts et pages générés doivent utiliser :
- `<header>`, `<main>`, `<nav>`, `<footer>` au lieu de `<div>` génériques
- `aria-label` sur les zones de navigation
- `role="navigation"`, `role="main"` si les éléments HTML5 ne suffisent pas
- Labels associés aux inputs de formulaire (`<label for="...">`)
- Focus management sur les modals (trap focus, retour au trigger à la fermeture)

### Test Playwright a11y

Générer un test E2E basique de navigation clavier sur la page d'accueil :

```typescript
test('homepage is keyboard navigable', async ({ page }) => {
  await page.goto('/')
  await page.keyboard.press('Tab')
  const focused = page.locator(':focus')
  await expect(focused).toBeVisible()
})
```
