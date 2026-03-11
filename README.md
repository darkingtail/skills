# Skills

Personal Claude Code skills by darkingtail.

## Installation

```bash
# 1. Add marketplace
claude plugin marketplace add darkingtail/skills

# 2. Install plugin
claude plugin install darkingtail
```

## Skills

| Skill | Trigger | Description |
|-------|---------|-------------|
| system-cleanup | 瘦身, 清理磁盘, disk cleanup | Scan and clean junk files, caches, leftovers |
| clean-sessions | 清理对话, 清理 session | Remove meaningless Claude Code session files |
| gh-star-list | 整理 stars, stars 分类 | Categorize GitHub stars into Lists with AI |
| daily-til | TIL, 今天学到, 记录知识点 | Today I Learned knowledge base |
| interview-notes | 面试笔记, 面试记录, 复习完了 | Frontend interview revision notes |
| life-reminders | 提醒, 记住, 踩坑了, 以后注意 | Life lessons and reminders |
| update-skills | 更新 skills, 更新插件, 一键更新 | One-click update all plugins and marketplaces |

## Setup

Some skills reference paths from `~/.claude/CLAUDE.md`. Add a `# Paths` section:

```markdown
# Paths

- **Obsidian workspace**: `~/workspace`
- **Daily TIL**: `~/workspace/daily-til`
- **Claude projects**: `~/.claude/projects`
```
