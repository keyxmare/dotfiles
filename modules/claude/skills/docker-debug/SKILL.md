---
name: docker-debug
description: Diagnoses Docker container issues with logs, health, and network analysis
allowed-tools: Bash(docker compose *), Bash(docker exec *), Bash(docker ps *), Bash(docker logs *), Bash(docker inspect *), Bash(docker network *), Bash(make *), Read, Glob, Grep
---

# Skill — Docker Debug

Tu diagnostiques les problèmes de containers Docker.

## Input

`$ARGUMENTS` peut être :
- Un nom de service (ex: `php`, `node`, `postgres`, `redis`)
- Un symptôme (ex: `502`, `connection refused`, `out of memory`)
- Rien → analyser tous les services

## Process

### 1. État des services

```bash
docker compose ps -a
```

Identifier :
- Services qui ne tournent pas (exit code)
- Services en restart loop
- Services sans health check

### 2. Logs

Pour chaque service problématique :
```bash
docker compose logs --tail=100 <service>
```

Chercher :
- Erreurs fatales, exceptions, panics
- Connection refused (dépendance pas prête)
- Permission denied (problème de volumes/user)
- Out of memory (OOM killed)

### 3. Health checks

```bash
docker inspect --format='{{json .State.Health}}' $(docker compose ps -q <service>)
```

- Health check défini ? Si non, recommander
- Status : healthy / unhealthy / starting
- Derniers résultats des checks

### 4. Réseau

Si problème de connectivité entre services :
```bash
docker compose exec <service> sh -c "ping -c 1 <autre_service> 2>/dev/null || echo 'unreachable'"
```

Vérifier :
- Les services sont sur le même réseau Docker
- Les ports exposés correspondent à la config
- Les noms de host dans la config app matchent les noms de services

### 5. Ressources

```bash
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}"
```

- Consommation mémoire excessive
- CPU à 100% (process bloqué)

### 6. Configuration

Comparer `docker-compose.yml` avec l'état réel :
- Volumes montés correctement
- Variables d'environnement passées
- Dépendances `depends_on` avec condition `service_healthy`

### 7. Diagnostic

Résumer :
- **Cause identifiée** — explication claire du problème
- **Fix** — commande ou modification à appliquer
- **Prévention** — ce qu'on peut ajouter pour éviter la récidive (health check, depends_on, restart policy)

Si le problème nécessite une modification de `docker-compose.yml`, proposer le diff.
