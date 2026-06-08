# time-context Skill

## Context

The user wants future conversations to understand phrases like "明天再做吧" or "下次继续" with real temporal context. A normal chat recap is not enough because it may lose the relative date, and a skill cannot provide true background notifications.

## Design Goal

Provide lightweight time-aware continuation across conversations by turning relative time into an absolute date and storing the continuation context locally.

## Storage

Use a local Markdown ledger:

```text
~/.codex/time-context.md
```

The ledger is intentionally simple and inspectable:

```markdown
## YYYY-MM-DD HH:mm Z

- Due: YYYY-MM-DD
- Source: "user's original wording"
- Context: short description of the task or topic
- Status: open | done | cancelled
```

## Workflow

When the user defers work:

1. Read the current date, time, and timezone from the runtime context or OS.
2. Convert relative wording into an absolute date.
3. Append a short open entry to the ledger.
4. Tell the user the absolute date that was recorded.

When the user says "继续" or similar:

1. Read the ledger if it exists.
2. Prefer open entries due today or earlier.
3. If nothing is due, use the latest open entry.
4. Briefly mention the matched date and context, then continue the work.

## Important Decisions

- Use a Markdown file instead of JSON so the user can inspect and fix entries manually.
- Store only time-sensitive continuation context, not a general todo list.
- Do not promise automatic reminders or notifications.
- Ask clarification only when ambiguous timing would materially change the result.

## Boundaries

- This is not a calendar integration.
- This is not durable global memory unless future agents actually load the skill and read the ledger.
- This does not replace project-specific todo tracking.

## Follow-Ups

- Add a cleanup command that marks old completed entries as archived.
- Add optional grouping by repo or workspace.
- Consider installing this skill globally if "继续" should reliably trigger it in new sessions.

