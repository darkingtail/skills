# Codex Plugin and folder-git-identity Design

## Context

The repo now supports Codex through `.codex-plugin/plugin.json` and includes a new `folder-git-identity` skill. The new skill manages directory-scoped Git identity with `includeIf.gitdir`, which is useful when the same machine has personal, company, client, and open-source workspaces.

## Design Goal

Expose the skills repository cleanly to Codex and provide a safe workflow for folder-level Git identity management.

## Codex Plugin Manifest

The `.codex-plugin/plugin.json` manifest declares:

- plugin name and version
- skill root at `./skills/`
- user-facing metadata for Codex
- broad capabilities around productivity, Git helpers, and knowledge capture

This keeps the repo usable by both Claude Code and Codex without moving the skill folders.

## folder-git-identity Model

The skill manages two pieces:

1. A global Git `includeIf.gitdir` rule for a workspace folder.
2. A referenced identity file containing `[user] name` and `[user] email`.

Example:

```ini
[includeIf "gitdir:D:/dev/darkingtail/"]
    path = ~/.gitconfig-darkingtail
```

## Safety Rules

- Configure folders, not vague categories like "personal" or "company."
- Require explicit confirmation before writing, overwriting, deleting, or purging Git config.
- Preserve unrelated Git configuration.
- Add managed markers to generated content.
- Delete only managed content by default.
- Show impact before removal or purge.

## Script Design

The skill includes PowerShell and Bash scripts so the fragile Git config edits are not reimplemented ad hoc in chat:

| Platform | Script |
| --- | --- |
| Windows | `scripts/folder-git-identity.ps1` |
| macOS/Linux | `scripts/folder-git-identity.sh` |

Both scripts support plan-first flows:

- `list`
- `plan-create`
- `create`
- `plan-remove`
- `remove`
- `purge`

## Important Decisions

- Recommend the workspace parent folder when the current directory is inside a Git repo.
- Normalize paths to absolute, forward-slash, trailing-slash form before writing config.
- Generate config filenames from the target folder to avoid subjective identity names.
- Use `-Yes` or `--yes` only after the user has confirmed the shown plan.

## Follow-Ups

- Add tests or dry-run fixtures for config parsing edge cases.
- Add README examples for common personal/company workspace layouts.
- Add an install verification prompt for Codex after copying skills into `~/.codex/skills`.

