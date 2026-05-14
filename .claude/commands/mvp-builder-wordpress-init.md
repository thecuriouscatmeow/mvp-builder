# mvp-builder-wordpress-init

Initialize a new WordPress project workspace with scaffold structure.

## When to invoke

In an empty or new directory you want to set up as a WordPress project. Runs once per project. Refuses if workspace already initialized.

## Arguments

- `--name <name>` — Project name (defaults to basename of current directory)
- `--theme <slug>` — Theme directory slug (defaults to sanitized, lowercase version of name)
- `--yes` — Skip confirmation prompt

## Execution

1. Locate script at `~/mvp-builder/scripts/init-project.sh`
2. Pass current working directory and arguments to script
3. Script creates:
   - `docs/` with 00-requirements.md, 01-sitemap.md, 04-design.md, brand-voice.md, coding-standards.md, image-guidelines.md, 99-known-issues.md
   - `docs/02-wireframes/`, `docs/03-content/`, `docs/06-images/`, `docs/checkpoints/` subdirectories
   - `src/wp-content/themes/<theme>/` with stub `style.css`, `functions.php`, `index.php`
   - `.claude/` directory
   - `.git/` repository (if not present)
   - Stubs: `docs/05-image-prompts.md`, `docs/CHANGELOG.md`
4. On success, prints summary of created structure
5. Suggests next step: `/mvp-builder-wordpress-plan`

## Failure modes

- **`docs/` already exists**: Workspace is already initialized. Refuses to overwrite. Direct user to check if they meant to use `/mvp-builder-wordpress-plan` or another stage command.
- **Script not found**: Check `~/mvp-builder/scripts/init-project.sh` exists and is executable.
- **Insufficient permissions**: Ensure you have write access to the target directory.

## Constraints

Inherits constraints from CLAUDE.md: no API keys, no secrets, no sudo. macOS Darwin + bash. Scripts are idempotent where sensible (this one is one-shot per project).
