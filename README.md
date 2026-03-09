# dotfiles

Personal dotfiles managed with a custom CLI tool.

## Structure

```
bin/               # CLI tools (dotfiles)
modules/           # Dotfile modules (each synced with a source directory)
  claude/          # Claude Code configuration (~/.claude/)
    skills/        # 17 custom skills (scaffold, review, security-audit, etc.)
    stacks/        # 17 stack references (Symfony, Vue, Docker, etc.)
    commands/      # Slash command definitions
    hooks/         # Git/format hooks
    settings.json  # Claude Code settings
    projects.json  # Projects registry
  mcp/             # MCP servers (~/.local/share/mcp/)
    redmine/       # Redmine MCP server
```

## Usage

```bash
# List available modules
dotfiles list

# Check differences between host config and repo
dotfiles status claude

# Save host config → dotfiles repo
dotfiles save claude

# Install dotfiles repo → host config
dotfiles install claude

# Apply to all modules
dotfiles save --all
dotfiles install --all --force
```

## Features

- **Module-based sync** between host config and dotfiles repo
- **Post-install hooks** for modules requiring setup (MCP server registration, etc.)
- **Interactive confirmation** with yes/no/all for each changed file

## Setup

Add the CLI to your PATH:

```bash
export PATH="$HOME/Projects/github.com/keyxmare/dotfiles/bin:$PATH"
```

## License

[MIT](LICENSE)
