# update-skills Cross-Agent Design

## Context

The original `update-skills` skill assumed Claude Code plugin commands were the only update path. The repository now targets Claude Code and Codex, but the two runtimes do not share a single plugin update model.

## Design Goal

Make skill updates work across Claude Code and Codex while being honest about each runtime's capabilities.

## Runtime Differences

| Runtime | Update model | Scriptability |
| --- | --- | --- |
| Claude Code | plugin marketplaces and installed plugins | `claude plugin marketplace update`, `claude plugin update` |
| Codex | local skill folders and plugin manifest | copy or sync files under `~/.codex/skills` |

The key design decision is to avoid inventing a fake `codex plugin update` flow.

## Workflow

1. Determine target: Claude Code, Codex, both, or this repo only.
2. For Claude Code, generate a temporary update script and tell the user to run it outside the active Claude Code session.
3. For Codex, pull or clone this repo and copy `skills/*` into `~/.codex/skills`.
4. Tell the user whether a restart or new session is needed.

## Important Decisions

- Keep Claude Code commands in generated scripts because running them from inside the active session is unreliable.
- Use `Set-Content -Encoding UTF8` on Windows to avoid encoding drift.
- Use `git pull --ff-only` for the source repo to avoid silently creating merge commits during an update.
- Explicitly state the target runtime in the final message.

## Non-Goals

- Do not manage remote marketplace publishing.
- Do not mutate Codex configuration beyond copying local skill folders.
- Do not hide missing dependencies such as `jq`; report the limitation and continue where possible.

## Follow-Ups

- Add a deterministic sync script if the manual instructions are repeated often.
- Add manifest validation for `.codex-plugin/plugin.json`.
- Add a dry-run mode that reports which local Codex skill folders would change.

