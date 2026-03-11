---
name: clean-sessions
description: 清理 Claude Code 中无意义的对话记录。当用户说"清理对话"、"删除无用会话"、"清理 session"等表达时使用此技能。
---

# Clean Sessions

扫描并删除 Claude Code 中无意义的对话记录文件。

## 触发条件

当用户满足以下任一条件时使用：

1. "清理对话"、"清理 session"、"删除无用会话"
2. "清理一下 claude 的记录"
3. "删掉没用的对话"

## 执行步骤

### 1. 扫描所有项目目录

```bash
# 列出所有项目目录
ls {Claude projects}\
```

### 2. 识别无意义文件

以下类型的 .jsonl 文件视为无意义：

**自动删除（无需确认）：**
- `agent-*.jsonl` — 子 Agent 自动生成的文件（prompt_suggestion、warmup、compact）
- 行数 <= 5 的 .jsonl 文件 — 空会话或仅有初始化记录

**需要确认后删除：**
- 行数 6-20 且首条用户消息为 "hi"、"hello"、"你好"、"test"、"测试" 等无意义内容

### 3. 扫描脚本

```bash
# 统计每个目录下的 agent 文件数量
find "{Claude projects}" -name "agent-*.jsonl" | wc -l

# 找出行数 <= 5 的文件
find "{Claude projects}" -name "*.jsonl" ! -name "agent-*" -exec sh -c 'lines=$(wc -l < "$1"); if [ "$lines" -le 5 ]; then echo "$lines $1"; fi' _ {} \;

# 找出疑似无意义的短对话（6-20行，检查首条用户消息）
find "{Claude projects}" -name "*.jsonl" ! -name "agent-*" -exec sh -c 'lines=$(wc -l < "$1"); if [ "$lines" -ge 6 ] && [ "$lines" -le 20 ]; then echo "$lines $1"; fi' _ {} \;
```

### 4. 执行删除

```bash
# 删除 agent 文件
find "{Claude projects}" -name "agent-*.jsonl" -delete

# 删除行数 <= 5 的文件
find "{Claude projects}" -name "*.jsonl" ! -name "agent-*" -exec sh -c 'lines=$(wc -l < "$1"); if [ "$lines" -le 5 ]; then rm "$1"; echo "deleted: $1"; fi' _ {} \;
```

### 5. 汇报结果

删除完成后，汇报：
- 删除的 agent 文件数量
- 删除的空会话数量
- 删除的无意义短对话数量
- 保留的有效会话数量

## 安全规则

1. **永远不删除当前会话** — 通过检查文件锁或最近修改时间识别
2. **不删除行数 > 20 的文件** — 除非用户明确指定
3. **有疑问先列出来让用户确认** — 宁可多保留，不误删
4. **删除前先统计数量** — 让用户确认后再批量删除
