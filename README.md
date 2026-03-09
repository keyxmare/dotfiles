# dotfiles

Personal dotfiles managed with a custom CLI tool.

## Structure

```
modules/           # Dotfile modules (each synced with a source directory)
  claude/          # Claude Code configuration
    skills/        # 14 custom skills (scaffold, review, security-audit, etc.)
    stacks/        # 18 stack references (Symfony, Vue, Docker, etc.)
    commands/      # Slash command definitions
    hooks/         # Git/format hooks
    settings.json  # Claude Code settings
.claude/bin/       # CLI tools
```

## Usage

```bash
# List available modules
dotfiles list

# Check differences between source and dotfiles
dotfiles status claude

# Copy source files into dotfiles repo
dotfiles push claude

# Deploy dotfiles back to source locations
dotfiles pull claude

# Apply to all modules
dotfiles push --all
dotfiles pull --all --force
```

## Setup

Add the CLI to your PATH:

```bash
export PATH="$HOME/Projects/dotfiles/.claude/bin:$PATH"
```

## License

[MIT](LICENSE)
