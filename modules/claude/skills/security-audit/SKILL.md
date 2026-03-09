---
name: security-audit
description: Performs a targeted security audit with actionable findings
allowed-tools: Bash(git *), Bash(make *), Bash(docker compose *), Read, Glob, Grep, Agent, mcp__context7__resolve-library-id, mcp__context7__query-docs
---

# Skill — Security Audit

Tu réalises un audit de sécurité ciblé et actionnable.

## Input

`$ARGUMENTS` peut être :
- Un chemin (ex: `src/Auth/`)
- Un numéro de PR (ex: `42`) → audit du diff uniquement
- Un domaine spécifique : `deps`, `headers`, `auth`, `injection`, `secrets`
- Rien → audit complet du projet

## Process

### 1. Périmètre

Déterminer les fichiers à auditer selon l'input. Si audit complet, prioriser :
1. Controllers / routes (surface d'attaque)
2. Auth / authorization
3. Requêtes DB / ORM
4. Inputs utilisateur (formulaires, API)
5. Configuration (env, CORS, CSP)
6. Dépendances

### 2. Analyse

Vérifier chaque catégorie applicable :

**Injection**
- SQL : requêtes construites par concaténation, DQL/QueryBuilder non paramétré
- XSS : `innerHTML`, `v-html`, données non échappées dans les templates
- Command injection : `exec()`, `shell_exec()`, `proc_open()` avec inputs dynamiques
- LDAP, XPATH, template injection

**Authentification & Autorisation**
- Endpoints sans `#[IsGranted]` ou `security` attribute
- Tokens sans expiration/rotation
- Mots de passe : algorithme (bcrypt/argon2), longueur minimale
- Sessions : configuration (cookie flags, lifetime)

**Headers & Configuration**
- Security headers manquants : CSP, X-Frame-Options, X-Content-Type-Options, Strict-Transport-Security
- CORS trop permissif (`allow_origin: '*'`)
- Rate limiting absent sur les endpoints sensibles (login, register, reset-password)
- Debug mode en production

**Secrets**
- Credentials hardcodés dans le code
- Clés API, tokens, mots de passe dans les fichiers versionnés
- `.env` avec des valeurs de production

**Dépendances**
```bash
docker compose exec php composer audit
```

Si frontend :
```bash
docker compose exec node pnpm audit
```

**Données sensibles**
- Logs contenant des données personnelles
- Réponses API exposant des champs internes (id technique, hash, timestamps serveur)
- Serialization d'entités complètes (au lieu de DTOs)

### 3. Rapport

Structurer les findings :

- **CRITIQUE** — Exploitable immédiatement (injection, auth bypass, secrets exposés)
- **ÉLEVÉ** — Risque significatif (headers manquants, CORS permissif, deps vulnérables)
- **MOYEN** — Bonnes pratiques non respectées (rate limiting absent, logs verbeux)
- **INFO** — Recommandations d'amélioration

Pour chaque finding :
- `fichier:ligne` — localisation exacte
- **Risque** — ce qu'un attaquant pourrait faire
- **Fix** — correction concrète (snippet de code)

### 4. Résumé

Terminer par :
- Nombre de findings par sévérité
- Top 3 des actions prioritaires
- Score global : SECURE / ACCEPTABLE / AT RISK / CRITICAL
