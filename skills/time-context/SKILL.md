---
name: darkingtail:time-context
description: "Use when the user mentions relative time, deferred work, next-time continuation, reminders, or temporal context. Triggers: '明天再做', '下次继续', '过几天', '提醒我', '到时候', '继续上次', 'time context'."
metadata:
  version: "1.0.0"
---

# Time Context

Keep lightweight time awareness across conversations. Use this when the user defers work, makes a time-relative plan, or asks to continue something from a previous time.

## Storage

Use a local Markdown ledger:

```text
~/.codex/time-context.md
```

Create it if missing. Keep entries short and append-only unless the user explicitly asks to clean them up.

Entry format:

```markdown
## YYYY-MM-DD HH:mm Z

- Due: YYYY-MM-DD
- Source: "user's original wording"
- Context: short description of the task or topic
- Status: open | done | cancelled
```

## When User Mentions Future Time

If the user says something like "明天再做吧", "周末继续", "下次提醒我", or "过两天再看":

1. Read the current date, time, and timezone from the runtime context or OS.
2. Convert relative wording into an absolute date.
3. Append a ledger entry with the original wording and current task context.
4. Tell the user the absolute date you recorded.

Examples:

- On 2026-05-24, "明天再做" means 2026-05-25.
- "下周一继续" means the next Monday after the current date.
- "过两天" means current date plus two calendar days.

If the date is ambiguous, make a conservative interpretation and state it. Ask only when the ambiguity would materially change the outcome.

## When User Says Continue

If the user says "继续", "继续上次", "上次那个", "明天那个", or similar:

1. Read `~/.codex/time-context.md` if it exists.
2. Find open entries whose due date is today or earlier first.
3. If none are due, use the most recent open entry.
4. Briefly mention the date and context before continuing.

Example response shape:

```text
我看到上次记录的是 2026-05-25 继续 gh-star-list 重设计。现在接着处理这个。
```

Do not over-explain the ledger unless the user asks.

## Completion

When the deferred task is finished, mark the matching entry as `done` by editing only its `Status` line. If the user cancels it, mark `cancelled`.

## Boundaries

- This is not a calendar. Do not create external calendar events unless the user explicitly asks.
- This is not a full todo system. Store only time-sensitive continuation context.
- Do not promise automatic notifications. The skill helps future agents remember when the user asks again.
