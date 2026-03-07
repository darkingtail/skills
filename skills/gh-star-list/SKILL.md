---
name: gh-star-list
description: "Categorize GitHub stars into Lists with AI, detect stale repos and recommend active alternatives. Supports batch/selective categorization and progressive freeze detection. Triggers: 'organize stars', '整理 stars', 'stars 分类', 'gh-star-list'."
metadata:
  version: "2.0.0"
---

# GitHub Star List

Organize GitHub starred repos into GitHub Lists automatically.

## Prerequisites

Verify environment before starting. Run these checks and guide user through any failures:

```bash
# 1. Check gh CLI installed
gh --version || echo "MISSING"

# 2. Check gh authenticated with 'user' scope
gh auth status  # must show 'user' in scopes

# 3. Check jq installed
jq --version || echo "MISSING"
```

**Troubleshooting:**

| Problem              | Solution                                                                 |
| -------------------- | ------------------------------------------------------------------------ |
| `gh` not installed   | macOS: `brew install gh`. Others: <https://cli.github.com>               |
| `gh` not logged in   | `gh auth login -h github.com -p https -w` (opens browser)                |
| `user` scope missing | `gh auth refresh -s user -h github.com`                                  |
| `jq` not installed   | macOS: `brew install jq`. Others: <https://jqlang.github.io/jq/download> |

All checks must pass before proceeding. The `user` scope is required for GitHub Lists API access.

## Scripts

All scripts are in `scripts/` relative to this skill's directory.

| Script            | Purpose                                                            |
| ----------------- | ------------------------------------------------------------------ |
| `fetch_stars.sh`  | Fetch starred repos (paginated). Outputs one JSON object per line. |
| `manage_lists.sh` | CRUD for GitHub Lists: `get`, `create`, `delete`, `add`            |

## Modes

### Mode 1: Full Batch (default)

Categorize all starred repos at once. Trigger: "整理所有 stars", "organize all my stars".

### Mode 2: Selective

Categorize specific repos or the latest N stars. Trigger: "整理最近 10 个 star", "把 xxx/yyy 加到合适的 list".

When no specific repos are mentioned and user says "整理一下" without "所有/全部/all", default to **latest 10 stars**.

## Workflow

### Step 1: Fetch Data

**Full batch mode:**

```bash
bash scripts/fetch_stars.sh > /tmp/stars.jsonl
bash scripts/manage_lists.sh get > /tmp/lists.json
```

**Selective mode (latest N):**

```bash
bash scripts/fetch_stars.sh --limit N > /tmp/stars.jsonl
bash scripts/manage_lists.sh get > /tmp/lists.json
```

For specific repos, use `gh api` to fetch individual repo info:

```bash
gh api repos/{owner}/{repo} --jq '{id: .node_id, full_name: .full_name, description: (.description // ""), topics: (.topics // []), language: (.language // ""), url: .html_url, pushed_at: .pushed_at, archived: .archived, open_issues_count: .open_issues_count}'
```

Tell user how many stars to process and how many existing lists found.

### Step 2: Analyze and Propose Categories

Read `/tmp/stars.jsonl` and `/tmp/lists.json`.

Analyze all repos and existing lists. Propose a categorization plan.

#### Classification Principles (IMPORTANT)

1. **Classify by PURPOSE, not language** (unless the user explicitly requests language-based grouping): A Rust-written JS bundler belongs in "Build & DX", not "Rust". A Swift-written clipboard tool belongs in "CLI & Tools", not "iOS". Language is metadata, not category.
2. **Description > Topics > Name > Language**: Prioritize description to understand what the repo DOES. Language is the weakest signal and should only be used as a tiebreaker.
3. **Ask "what does this repo help the user DO?"**: A framework for building mobile apps → Mobile. A linter for Python → Build & DX. A deepfake tool → AI or Misc.
4. **Avoid over-broad categories**: If a list exceeds 40 items, consider splitting by sub-purpose.
5. **Framework vs Library vs Tool**: Web frameworks (Express, Hono, Koa) → Backend. UI component libraries (Ant Design, shadcn) → UI & Design. Build tools (Vite, Rspack) → Build & DX.

#### Recommended Categories

Use these as a starting template for full batch mode. Adjust based on user's actual star composition — skip empty categories, merge small ones, split large ones (>40 repos).

| Category           | Description                                          | Typical repos                       |
| ------------------ | ---------------------------------------------------- | ----------------------------------- |
| AI                 | LLMs, ML frameworks, AI apps, agents                 | langchain, ollama, stable-diffusion |
| React              | React ecosystem: frameworks, hooks, state management | next.js, react, zustand             |
| React Native       | React Native core, navigation, UI libs               | react-navigation, expo              |
| Vue                | Vue ecosystem: frameworks, plugins, tools            | nuxt, vueuse, element-plus          |
| Flutter            | Flutter/Dart packages and apps                       | flutter, riverpod                   |
| Mobile Native      | iOS/Android native development                       | Kotlin/Swift libs, Jetpack          |
| WeChat             | Mini programs, WeChat SDK, WePY                      | wepy, vant-weapp                    |
| Backend            | Server frameworks, databases, APIs                   | express, fastapi, prisma            |
| Build & DX         | Bundlers, linters, dev tools, monorepo               | vite, eslint, turborepo             |
| CLI & Tools        | Desktop apps, CLI utilities, productivity            | homebrew, raycast, warp             |
| UI & Design        | Component libraries, CSS, animation                  | tailwindcss, shadcn, framer-motion  |
| Network & Proxy    | HTTP clients, proxies, VPN, network tools            | clash, axios, nginx                 |
| DevOps & Docker    | CI/CD, containers, infra, monitoring                 | docker, k8s, terraform              |
| Low-Code & Admin   | Admin panels, low-code platforms, CMS                | strapi, appsmith, refine            |
| Awesome & Learning | Curated lists, tutorials, books, courses             | awesome-xxx, free-programming-books |
| Misc               | Repos that don't fit elsewhere                       |                                     |

#### Category Guidelines

- **Respect existing lists**: Keep lists that already have items. Prefer assigning to existing lists when they match.
- **Generate new categories**: Only for repos that don't fit any existing list.
- **Total lists cap**: Stay within GitHub's 32-list limit.
- **Full batch**: Target 15-25 total lists.
- **Selective**: Prefer assigning to existing lists; only propose new lists if truly needed.

Present the plan as a table. Wait for user confirmation or adjustments.

### Step 3: Execute

After user confirms:

1. Create new lists: `bash scripts/manage_lists.sh create "<name>" "<description>"`
2. Collect all list IDs (existing + new)
3. Add repos to lists: `bash scripts/manage_lists.sh add <repo_node_id> <list_id>`

**Critical**: The `add` command calls `updateUserListsForItem` which **replaces** all list memberships for a repo. The `listIds` param is the **complete** set of lists the repo should belong to. To preserve existing membership, include ALL list IDs (old + new) in a single call.

Full batch: process in batches, report progress every 50 repos.
Selective: process all at once.

### Step 4: Summary

Run `bash scripts/manage_lists.sh get` and present a summary table showing list name, repo count, and whether each list is new or existing.

### Step 5: Freeze Detection (Progressive)

**This step is optional.** After Step 4, scan the `pushed_at`, `archived`, and `open_issues_count` fields from `/tmp/stars.jsonl` to detect potentially stale repos.

If stale candidates are found, prompt the user:

> "检测到 N 个疑似休眠项目，要进入冷冻检测吗？"

If the user declines, stop here. If the user agrees, proceed with analysis.

#### Multi-Signal Stale Detection

Do NOT judge solely by time. Use a layered approach:

| Layer                | Condition                                            | Verdict                                |
| -------------------- | ---------------------------------------------------- | -------------------------------------- |
| **Confirmed stale**  | `archived = true`                                    | Mark directly                          |
| **Likely abandoned** | No push for 1+ year **AND** `open_issues_count > 20` | Mark — bugs filed, nobody fixing       |
| **AI judgment**      | No push for 1+ year **BUT** few or zero open issues  | AI decides based on description/topics |

##### AI Judgment Rules for Layer 3

Repos with low issue counts and no recent pushes may be **mature/complete**, not abandoned. Exempt these types:

- **Fonts**: e.g., FiraCode, Inter — fonts don't need updates once complete
- **Books/Tutorials**: e.g., CS-Notes, free-programming-books — content is reference material
- **Specifications/Standards**: e.g., JSON Schema, OpenAPI specs
- **Curated lists**: e.g., awesome-xxx — may have slow but steady community PRs
- **Finished tools**: e.g., a CLI utility that does one thing well with no open bugs

For all others in Layer 3, mark as stale.

Present results as a table with columns: repo name, last push date, open issues, verdict (confirmed/abandoned/AI-judged), reason. Let the user select which repos to freeze. **Never auto-freeze — user must confirm.**

### Step 6: Freeze and Recommend Alternatives

For each repo the user confirms to freeze:

#### 6a: Move to 🧊 冷冻库

1. Check if `🧊 冷冻库` list exists; if not, create it:

   ```bash
   bash scripts/manage_lists.sh create "🧊 冷冻库" "休眠或疑似弃坑的项目，暂不取消 star"
   ```

2. Move the repo to the freeze list:

   ```bash
   bash scripts/manage_lists.sh add <repo_node_id> <freeze_list_id>
   ```

   This replaces the repo's previous list memberships. The repo is now only in 🧊 冷冻库.

#### 6b: Recommend Active Alternatives

For each frozen repo, search for active alternatives:

```bash
gh search repos "<keywords from repo description/topics>" --sort stars --limit 5 \
  --json fullName,description,pushedAt,stargazersCount
```

Filter candidates by:

- Pushed within the last 6 months
- More stars than the frozen repo (or comparable star count with active maintenance)
- Similar purpose (not just similar keywords)

Present recommendations as a table per frozen repo:

| Alternative | Stars | Last Push | Description |
| ----------- | ----- | --------- | ----------- |

If no good alternative exists, say so explicitly. The user decides whether to star any alternatives. **Do not auto-star.**

### Step 7: Final Report

Present a combined summary:

- **Categorization stats**: N repos categorized into M lists
- **Freeze stats**: N repos moved to 🧊 冷冻库 (if any)
- **New alternatives starred**: N repos (if any)
- **Total stars**: current count
