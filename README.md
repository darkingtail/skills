# Skills

Personal AI coding agent skills by darkingtail.

## Supported Agents

- Claude Code
- Codex CLI / Codex Desktop
- Compatible AI coding agents that support `SKILL.md`-based skills

## Claude Code Installation

```bash
# 1. Add marketplace
claude plugin marketplace add darkingtail/skills

# 2. Install plugin
claude plugin install darkingtail
```

Or inside Claude Code:

```text
/plugin marketplace add darkingtail/skills
/plugin install darkingtail
```

## Codex Installation

This repository includes a Codex plugin manifest at `.codex-plugin/plugin.json`.

For local testing, copy the skills into the Codex global skills directory:

```powershell
New-Item -ItemType Directory -Force $HOME\.codex\skills | Out-Null
Copy-Item -Recurse -Force .\skills\* $HOME\.codex\skills\
```

Then restart Codex and invoke the skill explicitly:

```text
Use $darkingtail:folder-git-identity to explain what this skill is for. Do not edit files.
```

## Skills

| Skill | Trigger | Description |
|-------|---------|-------------|
| system-cleanup | 瘦身, 清理磁盘, disk cleanup | Scan and clean junk files, caches, leftovers |
| clean-sessions | 清理对话, 清理 session | Remove meaningless Claude Code session files |
| gh-star-list | 整理 stars, stars 分类, star 复盘 | Review, triage, categorize, and prune GitHub stars |
| daily-til | TIL, 今天学到, 记录知识点 | Today I Learned knowledge base |
| folder-git-identity | Git 身份, 目录级 Git 配置, includeIf | Manage directory-scoped Git user.name/user.email |
| time-context | 明天再做, 下次继续, 提醒我 | Remember time-relative continuation context locally |
| smart-debug-logger | 加日志, console.log, 清理日志 | Context-aware debug logging with cleanup |
| update-skills | 更新 skills, 更新插件, 一键更新 | One-click update all plugins and skills |

## Design Docs

Design notes for skill and plugin changes live in [docs/design](docs/design/README.md).

## Setup

Some skills reference paths from `~/.claude/CLAUDE.md`. Add a `# Paths` section:

```markdown
# Paths

- **Obsidian workspace**: `~/workspace`
- **Daily TIL**: `~/workspace/daily-til`
- **Claude projects**: `~/.claude/projects`
```
