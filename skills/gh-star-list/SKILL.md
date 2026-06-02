---
name: darkingtail:gh-star-list
description: "Use when the user wants to review, triage, categorize, prune, or rediscover GitHub starred repositories. Triggers: '整理 stars', 'stars 分类', 'star 复盘', '看看我收藏的项目', 'gh-star-list'."
metadata:
  version: "3.0.0"
---

# GitHub Star List

Turn a large GitHub star collection into an intentional review system. The goal is not just categorization: help the user find what is still useful, what deserves a deeper look, what can stay as reference, and what should be frozen or unstarred.

## Operating Model

Treat starred repos as a personal backlog with four states:

| State | Meaning | GitHub List |
| --- | --- | --- |
| Inbox | Recently starred or never reviewed | `Inbox` or uncategorized |
| Keep | Known useful repo worth keeping visible | Purpose-based lists |
| Trial | Interesting repo to inspect, try, or compare later | `To Try` |
| Freeze | Stale, replaced, irrelevant, or weak signal | `Cold Storage` |

Do not bulk-move, freeze, or unstar without explicit confirmation.

## Prerequisites

Verify the environment before making GitHub changes:

```bash
gh --version
gh auth status
```

The authenticated GitHub account needs the `user` scope for GitHub Lists API access:

```bash
gh auth refresh -s user -h github.com
```

On macOS/Linux, the bundled bash scripts also need `jq`. On Windows, use the PowerShell scripts.

## Scripts

Scripts are in `scripts/` relative to this skill directory.

| Bash | PowerShell | Purpose |
| --- | --- | --- |
| `fetch_stars.sh` | `fetch_stars.ps1` | Fetch starred repos as JSONL |
| `manage_lists.sh` | `manage_lists.ps1` | Get/create/delete/update GitHub Lists |

Use PowerShell on Windows:

```powershell
powershell -File scripts/fetch_stars.ps1 -Limit 50 | Out-File -Encoding utf8 $env:TEMP\stars.jsonl
powershell -File scripts/manage_lists.ps1 get | Out-File -Encoding utf8 $env:TEMP\lists.json
```

Use bash on macOS/Linux:

```bash
bash scripts/fetch_stars.sh --limit 50 > /tmp/stars.jsonl
bash scripts/manage_lists.sh get > /tmp/lists.json
```

## Modes

Choose the smallest useful mode from the user's wording.

| Mode | When to use | Default batch |
| --- | --- | --- |
| Inbox review | User says "整理一下", "看看最近 star", or has no clear scope | Latest 20 |
| Full audit | User says "全部", "所有", or wants a one-time cleanup | All stars, processed in batches |
| Focused review | User names a topic, language, repo, or use case | Matching repos only |
| Stale review | User asks about outdated, abandoned, or replaceable repos | Stale candidates |

If the user is vague, default to Inbox review. Avoid starting with a full audit unless the user explicitly asks.

## Review Workflow

### Step 1: Fetch Working Set

Fetch stars and existing lists. Tell the user the exact scope before analysis: for example, "I found 20 latest stars and 7 existing lists."

For specific repos, fetch details directly:

```bash
gh api repos/{owner}/{repo} --jq '{id: .node_id, full_name: .full_name, description: (.description // ""), topics: (.topics // []), language: (.language // ""), url: .html_url, pushed_at: .pushed_at, archived: .archived, open_issues_count: .open_issues_count, stargazers_count: .stargazers_count}'
```

### Step 2: Score Each Repo

Classify each repo with a short, practical judgment. The key question is: "Why should this stay in the user's attention?"

Use these signals:

| Signal | What to inspect |
| --- | --- |
| Purpose | Description, README summary, topics, name |
| Personal relevance | Does it match the user's current work, learning, tools, or recurring interests? |
| Actionability | Can the user install, read, try, compare, or reuse it soon? |
| Quality | Stars, recent activity, docs, issue health, ecosystem reputation |
| Freshness | `pushed_at`, archived state, open issues |
| Redundancy | Is it superseded by another starred repo or mainstream tool? |

Never classify primarily by programming language unless the user asks for language-based lists. Language is metadata, not purpose.

### Step 3: Present Triage Table

Present a compact table with an explicit recommendation:

| Repo | What it is | Recommendation | Reason |
| --- | --- | --- | --- |
| owner/name | Short purpose | Keep / Trial / Freeze / Unstar candidate | One sentence |

Default recommendations:

- **Keep**: known useful, active, strong reference, or core ecosystem project.
- **Trial**: impressive but not yet understood; worth reading or trying once.
- **Freeze**: stale, niche, replaced, or low current relevance, but not safe to unstar yet.
- **Unstar candidate**: clearly irrelevant, duplicate, archived with better alternatives, or low-signal collection noise.

Ask for confirmation only after showing a complete batch proposal. Do not ask repo-by-repo unless the user requests it.

### Step 4: Map To Lists

Prefer stable, purpose-based lists:

| List | Use for |
| --- | --- |
| AI | LLMs, ML, agents, AI apps |
| Frontend | React, Vue, UI, CSS, design systems |
| Backend | APIs, servers, databases, auth, queues |
| Build & DX | Bundlers, linters, monorepos, dev workflows |
| CLI & Desktop | Terminal tools, desktop apps, productivity |
| Mobile | React Native, Flutter, iOS, Android |
| DevOps | Docker, Kubernetes, CI/CD, infra, observability |
| Learning | books, tutorials, awesome lists, examples |
| To Try | repos worth a future hands-on test |
| Cold Storage | stale, replaced, or low-priority repos kept for memory |

Respect existing lists when they are close enough. Keep the total under GitHub's 32-list limit.

### Step 5: Execute Approved Changes

Create missing lists only after approval:

```powershell
powershell -File scripts/manage_lists.ps1 create "To Try" "Interesting starred repos to inspect or test later"
powershell -File scripts/manage_lists.ps1 create "Cold Storage" "Stale, replaced, or low-priority starred repos kept for memory"
```

Add a repo to lists:

```powershell
powershell -File scripts/manage_lists.ps1 add <repo_node_id> <list_id> [<list_id>...]
```

Important: `updateUserListsForItem` replaces all list memberships for a repo. When preserving existing memberships, pass the full final list ID set in one call.

### Step 6: Optional Alternatives

For Freeze or Unstar candidates, look for better maintained alternatives:

```bash
gh search repos "<keywords from purpose/topics>" --sort stars --limit 5 --json fullName,description,pushedAt,stargazersCount,url
```

Recommend alternatives only when they serve the same purpose and have recent activity. Do not auto-star alternatives.

## Stale Detection

Do not judge only by age.

| Condition | Default verdict |
| --- | --- |
| Archived | Freeze or Unstar candidate |
| No push for 1+ year and many open issues | Freeze |
| No push for 1+ year but few issues | Inspect purpose before judging |
| Font, spec, book, tutorial, or awesome list | Can be mature rather than stale |
| Active but redundant | Freeze or Unstar candidate depending on relevance |

## Final Report

End with:

- Repos reviewed
- Lists created or changed
- Keep / Trial / Freeze / Unstar candidate counts
- Any alternatives worth inspecting
- Suggested next batch, usually latest 20 or one focused topic
