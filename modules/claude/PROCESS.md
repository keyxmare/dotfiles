# Process — Méthodologie de travail

## UX / UI

- Toujours se mettre à la place de l'utilisateur final lors du développement d'une feature.
- Les messages d'erreur doivent être **compréhensibles par un non-développeur** — jamais de messages techniques bruts.
- Les états de chargement (`loading`) et les états vides doivent être gérés.

## Recherche avant implémentation

- Avant d'implémenter une feature ou un correctif, **toujours vérifier la documentation à jour** des libs/frameworks concernés. ← `research.before_impl`
- Utiliser **context7** (`resolve-library-id` puis `query-docs`) pour récupérer la doc officielle et les exemples de code actuels. ← `research.context7`
- Si context7 ne couvre pas le sujet ou si un doute persiste, compléter avec une **recherche web** (`WebSearch` / `WebFetch`). ← `research.web`
- L'objectif : éviter d'implémenter avec des API obsolètes ou des patterns dépréciés.
- Ce comportement peut être désactivé globalement (`research.before_impl` = `false`) ou partiellement (`research.context7` / `research.web` = `false`) dans le CONFIG.md local du projet.
- Si `research.before_impl` = `false`, les deux sous-clés sont ignorées (pas de recherche du tout).

## Approche technique

- Proposer plusieurs approches possibles avec une recommandation argumentée **quand il y a un vrai choix architectural ou technique**. Pour les tâches évidentes, agir directement. Le choix final revient toujours à l'utilisateur.
- En début de conversation sur un nouveau projet vide, demander le profil souhaité (`simple` = MVP/scripts, `standard` = apps classiques, `advanced` = DDD/enterprise) et enregistrer ce choix dans le CLAUDE.md du projet. ← `profile: ask`
- Sur un projet existant, respecter la structure et les conventions déjà en place.
- L'utilisateur peut toujours spécifier ou changer le niveau à tout moment.
- **Ne jamais downgrader une version** de framework ou de dépendance sans l'accord explicite de l'utilisateur, sauf en cas de vulnérabilité de sécurité critique dans la version actuelle. Si un package est incompatible, chercher d'abord une version compatible de ce package. Informer l'utilisateur du problème et proposer des solutions avant d'agir.

## Checklist de livraison

Avant de considérer une tâche comme terminée, vérifier **chaque point** de cette checklist. Ne pas répondre "c'est fini" tant qu'un point est manquant. Cocher mentalement chaque étape dans l'ordre.

### 1. Recherche → Skip si `research.before_impl` = `false`
- [ ] Documentation à jour consultée (context7, web) pour les libs/APIs utilisées

### 2. Code
- [ ] Code implémenté en suivant les patterns existants du projet
- [ ] Pas de commentaires dans le code (si `code.comments: false`)
- [ ] Pas de fichiers inutiles créés

### 3. Tests → Skip si `tests.enabled` = `false`
- [ ] Chaque module créé ou modifié a son test unitaire (handler, store, service, composable, fonction…)
- [ ] Cas couverts : nominal, erreur, limites
- [ ] Tests exécutés et passants (via Docker/make si `containers.runtime_only`)

### 4. Documentation → Skip si `doc.enabled` = `false`
- [ ] OpenAPI mis à jour avec les nouveaux endpoints (`doc.openapi`)
- [ ] Diagrammes C4 mis à jour si nouveau composant (`doc.c4`)
- [ ] Features docs mis à jour (`docs/features/*.md`)

### 5. Qualité
- [ ] Linter de la stack exécuté et passant (voir le fichier de stack pour les outils concrets)
- [ ] Analyse statique exécutée et passante (si applicable à la stack)
- [ ] Compilation/transpilation sans erreur (TypeScript, etc.)
- [ ] Audit de sécurité exécuté → Skip si `security.audit` = `false`

### 6. Accessibilité → Skip si `a11y.enabled` = `false` — frontend uniquement
- [ ] Éléments HTML sémantiques utilisés
- [ ] Labels associés aux champs de formulaire
- [ ] Attributs alt sur les images

### 7. Vérification fonctionnelle (si applicable)

→ Voir [TEST.md#vérification-fonctionnelle](./TEST.md) pour le détail des vérifications.

Cette checklist s'applique à chaque feature, fix ou refactoring. Si un point ne s'applique pas (ex: pas de nouveau handler), l'ignorer. Si un point est bloqué (ex: Docker non disponible), le signaler à l'utilisateur.
