---
name: darkingtail:life-reminders
description: Use when the user wants to record a life lesson, reminder, or something to remember for next time. Triggers on "提醒", "reminder", "记住", "下次别忘了", "别忘了", "以后不能再犯", "以后注意", "踩坑了", "吃亏了", "长个记性".
---

# Life Reminders

Add entries to `{Obsidian workspace}/生活提醒.md` — a categorized list of things that happened so they don't repeat.

## Steps

1. Read `{Obsidian workspace}/生活提醒.md` to see existing categories.
2. Determine the entry content from the user's message.
3. Determine the category:
   - If the user specifies one, use it.
   - If it fits an existing category, use that.
   - Otherwise, ask which category (offer existing ones + option to create new).
4. Append the entry under the category as `- {entry} ({date})`.
   - If the category doesn't exist yet, add a new `## Category / 中文` section at the end.
5. Confirm what was added.

## Rules

- Each entry is one line: `- Description (YYYY-MM-DD)`
- Keep entries concise — capture the lesson, not the story.
- Write entries in Chinese. If input is English, translate to Chinese.
- Category headings use `## 中文` format.
- Path placeholder resolved from CLAUDE.md `# Paths` section.
