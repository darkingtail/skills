---
name: darkingtail:system-cleanup
description: Use when the user wants to clean up disk space, slim down their system, remove junk files, clear caches, or find large unused files. Triggers on keywords like "瘦身", "清理磁盘", "disk cleanup", "free space", "clean junk".
---

# System Cleanup

自动检测操作系统，扫描无用文件、缓存、遗留数据，询问用户后执行清理。

## Phase 1: OS Detection & Disk Overview

Run a single command to detect OS and show disk usage:

```bash
# The shell environment reveals the OS. Check:
uname -s 2>/dev/null || echo "Windows"
```

Identify:
- **Windows**: `win32` platform, PowerShell available
- **macOS**: `Darwin` from uname
- **Linux**: `Linux` from uname

Show current disk usage (used / free / total) for the main drive.

## Phase 2: Scan (Write a temp script, execute, then delete it)

Write a platform-specific scan script to a temp file, execute it, then remove the script. This avoids shell escaping issues.

### Scan Targets by OS

#### Windows
| Category | Paths |
|----------|-------|
| User Temp | `$env:LOCALAPPDATA\Temp` |
| npm cache | `$env:LOCALAPPDATA\npm-cache` |
| pnpm store | `$env:LOCALAPPDATA\pnpm\store` |
| yarn cache | `$env:LOCALAPPDATA\Yarn\Cache` |
| pip cache | `$env:LOCALAPPDATA\pip\Cache` |
| nuget packages | `$env:USERPROFILE\.nuget\packages` |
| gradle cache | `$env:USERPROFILE\.gradle` |
| maven cache | `$env:USERPROFILE\.m2\repository` |
| cargo cache | `$env:USERPROFILE\.cargo\registry` |
| go modules | `$env:USERPROFILE\go\pkg` |
| Docker data | `$env:LOCALAPPDATA\Docker` |
| Chrome cache | `$env:LOCALAPPDATA\Google\Chrome\User Data` |
| Edge cache | `$env:LOCALAPPDATA\Microsoft\Edge\User Data` |
| VS Code extensions | `$env:USERPROFILE\.vscode\extensions` |
| WinSxS | `C:\Windows\WinSxS` |
| Windows Installer | `C:\Windows\Installer` |
| Orphaned AppData | Scan `$env:APPDATA` and `$env:LOCALAPPDATA` for folders from uninstalled software |
| Large files | Scan for files > 500MB across C:\ |
| Recycle Bin | `$env:SYSTEMDRIVE\$Recycle.Bin` |

#### macOS
| Category | Paths |
|----------|-------|
| User caches | `~/Library/Caches` |
| Homebrew cache | `~/Library/Caches/Homebrew`, `$(brew --cache)` |
| npm cache | `~/.npm/_cacache` |
| pip cache | `~/Library/Caches/pip` |
| Xcode derived | `~/Library/Developer/Xcode/DerivedData` |
| iOS simulators | `~/Library/Developer/CoreSimulator` |
| CocoaPods cache | `~/Library/Caches/CocoaPods` |
| Docker data | `~/Library/Containers/com.docker.docker` |
| Trash | `~/.Trash` |
| Application Support | Scan for orphaned app folders |
| Log files | `~/Library/Logs`, `/var/log` |
| Large files | Scan for files > 500MB across ~ |

#### Linux
| Category | Paths |
|----------|-------|
| User cache | `~/.cache` |
| apt cache | `/var/cache/apt/archives` |
| yum/dnf cache | `/var/cache/yum`, `/var/cache/dnf` |
| snap cache | `/var/lib/snapd/cache` |
| journal logs | `journalctl --disk-usage` |
| npm cache | `~/.npm/_cacache` |
| pip cache | `~/.cache/pip` |
| Docker data | `/var/lib/docker` |
| Trash | `~/.local/share/Trash` |
| tmp files | `/tmp`, `/var/tmp` |
| Old kernels | `dpkg -l 'linux-image-*'` |
| Large files | Scan for files > 500MB across ~ |

### Scan Script Pattern (Windows example)

```powershell
# Write to temp file, execute, delete
# For each path: check existence, calculate size, output if > 50MB
# Format: "SIZE_MB|CATEGORY|PATH"
# Sort by size descending
```

**IMPORTANT**: Always use a temp .ps1/.sh script file instead of inline commands to avoid shell escaping issues with `$` variables in PowerShell through bash.

## Phase 3: Present Results & Ask User

After scanning, present results in a clear table grouped by category, and **for每个项目标注清理建议**：

### 分类展示（必须包含建议列）

1. **强烈推荐清理** — 缓存类，删除后可自动重建，对日常使用无影响（浏览器缓存、临时文件、npm/pnpm 缓存等）
2. **可以清理** — 包管理器缓存，删除后安全但下次构建/安装会变慢（Cargo、Bun、Maven、pip 等）
3. **谨慎清理** — 大体积项目，需用户判断是否还在使用（Docker 数据、WSL 虚拟磁盘等）
4. **不建议清理** — 正在使用的工具数据（VS Code 扩展、编辑器配置、应用运行时文件等）

每个表格必须包含以下列：**大小 | 类别 | 建议 | 原因**

示例：
| 大小 | 类别 | 建议 | 原因 |
|------|------|------|------|
| 345 MB | Chrome 缓存 | 强烈推荐 | 浏览器会自动重建 |
| 597 MB | Cargo 缓存 | 可以清理 | 不常用 Rust 则无影响 |
| 2.31 GB | VS Code 扩展 | 不建议 | 正在使用的扩展，删了要重装 |

Use `AskUserQuestion` to let the user choose which categories to clean. Always include a "skip" option. **Never delete without asking first.**

## Phase 4: Execute Cleanup

For each approved category, use the appropriate safe cleanup method:

| Type | Method |
|------|--------|
| Package cache | Use native commands: `npm cache clean --force`, `pip cache purge`, `brew cleanup` |
| Temp files | Only delete files older than 7 days |
| Orphaned folders | `Remove-Item -Recurse -Force` / `rm -rf` |
| Docker | `docker system prune` (ask about volumes separately) |
| Browser cache | Only clear Cache subfolder, never user data/passwords |
| System components | Suggest running `cleanmgr` or `DISM` (Windows), `apt autoremove` (Linux) |

**Safety rules:**
- Never delete files currently in use (locked files)
- Skip items that fail with access denied — report them
- Log every deletion with size freed
- Show running total of freed space
- Delete the temp scan/cleanup scripts after execution

## Phase 5: Summary

Show final report:
- Total space freed
- Items that failed (permission issues, locked files)
- Remaining large space consumers
- Suggestions for further cleanup (e.g., "Docker images could free X GB")

## Common Mistakes

- Running PowerShell `$variable` commands through bash without a script file — always use temp `.ps1` files
- Deleting browser User Data instead of just Cache subfolder
- Removing `.nuget/packages` when projects depend on local restore
- Cleaning Docker data without checking running containers
- Not checking if software is actually uninstalled before removing AppData
