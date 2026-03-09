# Stack — Structure de projet

## Principe

Tout projet suit une structure monorepo. Le code source est organisé par application (backend et/ou frontend).

## Structure de base

```
project/
├── README.md              ← Présentation du projet, quickstart
├── .gitignore
├── .editorconfig          ← Cohérence de formatage entre éditeurs (indentation, line endings, charset)
├── .env.example           ← Template des variables d'environnement (voir security.md#secrets)
├── Makefile               ← Orchestrateur des sous-projets et commandes globales
├── backend/               ← Code source backend (si applicable)
│   ├── Makefile           ← Commandes spécifiques au backend
│   └── ...
├── frontend/              ← Code source frontend (si applicable)
│   ├── Makefile           ← Commandes spécifiques au frontend
│   └── ...
├── docker/                ← Configuration Docker (si dockerisé, voir stacks/docker.md)
│   └── ...
├── docs/                  ← Documentation (si `doc.enabled` = true, voir DOC.md)
│   └── ...
└── .github/               ← CI/CD GitHub Actions par défaut ← `ci.provider`
    └── workflows/
        └── ...
```

## Template `.editorconfig`

```editorconfig
root = true

[*]
charset = utf-8
end_of_line = lf
indent_style = space
indent_size = 4
insert_final_newline = true
trim_trailing_whitespace = true

[*.{js,ts,vue,json,yaml,yml,css,scss}]
indent_size = 2

[*.md]
trim_trailing_whitespace = false

[Makefile]
indent_style = tab

[*.{sh,bash,zsh}]
indent_size = 4
shell_variant = bash
binary_next_line = true
switch_case_indent = true
```

> Le bloc `*.{sh,bash,zsh}` est aussi lu par shfmt (voir [shell.md](./shell.md#shfmt)).

## Règles

- Toujours un monorepo, même si le projet ne contient qu'un backend ou qu'un frontend.
- `README.md`, `.gitignore`, `.editorconfig`, `.env.example` et `Makefile` sont obligatoires à la racine.
- Chaque application (backend, frontend) contient son propre `Makefile`.
- `docs/` est créé uniquement si la documentation est activée. ← `doc.enabled`
- `docs/` suit la structure définie dans [DOC.md](../DOC.md).
- `docker/` est créé uniquement si le projet est dockerisé. Voir [stacks/docker.md](./docker.md) pour la structure interne.
- La structure interne de `backend/` et `frontend/` est définie par la stack technologique utilisée.

## Makefile

Voir [stacks/makefile.md](./makefile.md) pour les conventions, la structure et les exemples.

## CI/CD

- Le provider est défini dans la configuration. ← `ci.provider`
- Ne pas écraser une configuration CI/CD déjà existante.
