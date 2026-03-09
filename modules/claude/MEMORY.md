# Memory — Gestion de la mémoire persistante

> Les règles de base de l'auto-memory (organiser par thème, vérifier les doublons, mettre à jour les mémoires obsolètes, réagir aux corrections utilisateur) sont gérées par le système intégré de Claude Code. Ce fichier ajoute uniquement les règles spécifiques.

## Leçons transversales (cross-projets)

- **Toujours vérifier le projet avant commit** : build Docker, démarrage containers, réponse HTTP, connexion BDD.
- **Ne jamais downgrader une version** sans accord explicite — chercher d'abord un package compatible.
- **doctrine-bundle 3.x** : `auto_generate_proxy_classes` et `enable_lazy_ghost_objects` supprimées de `doctrine.yaml`.
- **backend/.env** obligatoire pour Symfony (Dotenv charge ce fichier au boot). Le `.gitignore` ne doit PAS ignorer `backend/.env`, seulement `.env.local`.

## Où écrire

- Par défaut, la mémoire s'écrit dans le projet en cours (CLAUDE.md du projet ou répertoire mémoire du projet).
- Seuls les sujets globaux (préférences utilisateur, conventions transversales) vont dans la mémoire globale.

## Arbre de décision — Projet vs Global

```
Cette info est spécifique à un projet ?
  → Oui → mémoire projet (~/.claude/projects/.../memory/)
  → Non → C'est une préférence utilisateur ou convention transversale ?
    → Oui → mémoire globale (~/.claude/MEMORY.md ou sous-fichiers)
    → Non → ne pas sauvegarder
```

## Patterns qui marchent

- **Monorepo + Makefile racine** : orchestration propre, chaque app autonome.
- **CQRS + Messenger 3 buses** : séparation claire read/write/events, scalable.
- **Stacks lazy-loaded** : charger uniquement la stack nécessaire via la matrice STACK.md.
- **Multi-stage Docker** : stage dev avec bind mounts, stage prod minimal.
- **Rules path-scoped** : conventions chargées automatiquement selon les fichiers touchés.

## Patterns qui cassent

- **`docker compose exec` en CI sans `up -d` préalable** → utiliser `run --rm`.
- **`latest` tag sur les images Docker** → builds non reproductibles.
- **Mapper XML Doctrine supprimé dans doctrine-bundle 3.x** → attributs PHP obligatoires.

## Mémoires par projet

Les mémoires projet sont stockées automatiquement dans `~/.claude/projects/<path>/memory/`. Pas besoin de maintenir un index manuel — Claude Code résout le bon répertoire mémoire à partir du projet courant.
