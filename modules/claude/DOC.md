# Documentation — Méthodologie globale

## Principes

- Toujours documenter, sauf si la configuration du projet l'interdit explicitement. ← `doc.enabled`
- Maintenir la documentation à jour à chaque modification de code.
- Rédiger en français, en markdown. Exception : les spécifications OpenAPI, les ADR et les diagrammes C4 sont rédigés en anglais (standard international, facilite l'interopérabilité et l'outillage).
- Un DOC.md local au projet peut surcharger ces instructions. En cas de contradiction, le local prime.

## Contenu

La documentation couvre les domaines suivants selon la pertinence du projet :

- **API** — Spécification OpenAPI (YAML/JSON), générée ou maintenue manuellement. ← `doc.openapi`
- **Architecture** — Structure du projet, choix techniques, patterns utilisés.
- **Setup** — Installation, prérequis, configuration, variables d'environnement.
- **Features** — Fonctionnalités découpées par bounded context, un fichier par contexte.
- **Modèle C4** — Diagrammes en Mermaid. ← `doc.c4`

## Architecture de la documentation

```
docs/
├── README.md                      ← Vue d'ensemble du projet, quickstart, liens vers les autres docs
├── SETUP.md                       ← Prérequis, installation, configuration, variables d'environnement
├── ARCHITECTURE.md                ← Stack, choix techniques, patterns, structure des dossiers
│
├── features/
│   ├── README.md                  ← Index des bounded contexts avec description courte de chacun
│   ├── [context-a].md             ← Fonctionnalités du bounded context A (ex: authentication.md)
│   ├── [context-b].md             ← Fonctionnalités du bounded context B (ex: billing.md)
│   └── ...
│
├── api/
│   ├── openapi.yaml               ← Spécification OpenAPI complète
│   └── README.md                  ← Notes complémentaires, conventions, versioning
│
├── c4/
│   ├── README.md                  ← Index des diagrammes C4
│   ├── context.md                 ← Diagramme de contexte global : système, utilisateurs, systèmes externes
│   ├── [context-a]/
│   │   ├── container.md           ← Containers du bounded context A
│   │   ├── component.md           ← Composants du bounded context A
│   │   └── code.md                ← Classes et fonctions clés du bounded context A
│   ├── [context-b]/
│   │   ├── container.md
│   │   ├── component.md
│   │   └── code.md
│   └── ...
│
└── adr/
    ├── README.md                  ← Explication du format ADR et index des décisions
    └── 0001-description-courte.md  ← Architecture Decision Records
```

## Cohérence avec le code

- **La documentation ne doit jamais décrire quelque chose qui n'existe pas dans le code.** Pas d'endpoints fictifs dans l'OpenAPI, pas de features inventées, pas de diagrammes C4 qui montrent des composants non implémentés.
- L'OpenAPI ne contient que les endpoints réellement implémentés dans le code. Pour un nouveau projet sans features scaffoldées, c'est un squelette vide (`info`, `servers`, `paths: {}`). Si des features ont été créées (via `/new-project` ou manuellement), les endpoints correspondants doivent y figurer.
- Les fichiers de features (`docs/features/*.md`) décrivent le périmètre prévu du bounded context (titre, responsabilités, concepts clés) mais ne listent pas de fonctionnalités comme si elles étaient implémentées. Utiliser une section "Périmètre" plutôt que des détails d'API ou de modèle.
- Les diagrammes C4 de niveau container/component/code ne sont créés que quand le code correspondant existe. Seul le diagramme de contexte (niveau 1) peut être créé dès le début car il décrit le système dans son ensemble.

## Règles de structure

- Le dossier `docs/` est toujours à la racine du projet.
- Chaque sous-dossier contient un `README.md` qui sert d'index et de point d'entrée.
- Les features sont découpées un fichier par bounded context, jamais un fichier fourre-tout unique.
- La spécification API utilise le format OpenAPI 3.x en YAML (ou JSON si le projet l'impose).
- Les diagrammes C4 utilisent Mermaid. Toujours vérifier la syntaxe via context7 (`resolve-library-id` → `query-docs` pour Mermaid) avant génération. ← `research.before_impl`
- Le diagramme de contexte (niveau 1) reste global. Les niveaux container, component et code sont découpés par bounded context.
- **Niveaux C4 obligatoires selon le type de projet** :
  - **C1 (Context)** — Toujours créé, quel que soit le projet.
  - **C2 (Container)** — Obligatoire pour les applications web (frontend, backend, BDD, cache, etc.). Créé dès la création du projet.
  - **C3 (Component)** — Obligatoire pour les projets en mode `advanced` (DDD, bounded contexts). Créé pour chaque bounded context implémenté.
  - **C4 (Code)** — Optionnel, uniquement si la complexité le justifie.
- **La documentation doit refléter l'état réel du code.** Si un diagramme C4 montre un composant, ce composant doit exister dans le code. Inversement, si du code existe, il doit apparaître dans les diagrammes du niveau approprié.
- Les ADR sont optionnels mais recommandés pour tracer les décisions techniques importantes. ← `doc.adr`
- **Format ADR** — Nommage : `0001-description-courte.md` (numéro incrémental, padé sur 4 chiffres). Sections obligatoires : Context, Decision, Consequences, Status (`proposed`, `accepted`, `deprecated`, `superseded`). Rédigés en anglais. Rester concis — un ADR = une décision.
- Adapter la structure au projet : un petit projet n'a pas besoin de tous les dossiers. Ne créer que ce qui est pertinent.
- Cette structure est le standard. Tout projet doit la suivre sauf surcharge via un DOC.md local.
