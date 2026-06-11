# .darkingtail Global Data Directory

## Context

Several skills need to store user data that persists across sessions and projects:

- `time-context`: temporal continuation ledger
- `gh-star-list`: optional local review ledger (planned follow-up)
- Other future skills may need similar cross-session storage

Using `~/.codex/` or `~/.claude/` ties data to a specific agent platform. This repo supports both Claude Code and Codex, and the data should be agent-agnostic.

## Design Goal

Define a unified, agent-agnostic global data directory for darkingtail skills. Skills read and write data here without caring which agent is running.

## Directory Location

```text
~/.darkingtail/
```

- Hidden directory (dot prefix) to avoid visual clutter
- Lives in user home, parallel to `~/.claude/` and `~/.codex/`
- Agent-agnostic: works with Claude Code, Codex, or any compatible agent

## Directory Structure

```text
~/.darkingtail/
├── time-context/
│   └── ledger.md           # Temporal continuation entries
├── gh-star-list/
│   └── review-ledger.md    # Local review history (optional, future)
└── README.md               # Explain what this directory is for
```

Each skill owns a subdirectory. Skill-specific data stays isolated.

## Initialization

Skills should create the directory structure on first use if it does not exist:

1. Check if `~/.darkingtail/` exists
2. If not, create it with a README.md explaining its purpose
3. Create skill-specific subdirectory if needed

Example README.md content:

```markdown
# darkingtail Data Directory

This directory stores persistent data for darkingtail skills.

- `time-context/`: temporal continuation ledger
- `gh-star-list/`: local review history

Do not edit files here manually unless you know what you are doing.
Each skill's SKILL.md documents its data format.
```

## Skill Integration

### time-context

- Ledger path: `~/.darkingtail/time-context/ledger.md`
- Update SKILL.md to use this path instead of `~/.codex/time-context.md`
- Create directory on first write

### gh-star-list (future)

- Review ledger path: `~/.darkingtail/gh-star-list/review-ledger.md`
- Stores "reviewed at" timestamps and "why kept" notes
- Optional: GitHub Lists remain the primary storage

## Cross-Platform Considerations

| Platform | Home path | Example |
| --- | --- | --- |
| Windows | `$HOME` or `$USERPROFILE` | `C:\Users\wangxu02\.darkingtail\` |
| macOS | `$HOME` | `/Users/darkingtail/.darkingtail/` |
| Linux | `$HOME` | `/home/darkingtail/.darkingtail/` |

Skills should resolve `~` using the environment, not hardcode paths.

## Boundaries

- This directory is for **data**, not configuration. Config stays in agent-specific directories (`~/.claude/`, `~/.codex/`).
- This directory is **not** synced or backed up automatically. Users who want backup should symlink or use their own backup solution.
- This directory is **private**. Do not commit its contents to git.

## Migration

If `~/.codex/time-context.md` exists from the old design:

1. Read the old file
2. Write to `~/.darkingtail/time-context/ledger.md`
3. Optionally delete the old file after confirmation

## Follow-Ups

- Add a cleanup skill that can archive old entries across all ledgers
- Consider a `darkingtail config` command to show/inspect this directory
