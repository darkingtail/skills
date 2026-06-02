---
name: darkingtail:update-skills
description: "Use when the user wants to update personal skills, Claude Code plugins, Codex skills, marketplaces, or this darkingtail skills repo. Triggers: 'update skills', '更新 skills', '更新插件', '一键更新'."
---

# Update Skills

Update personal skills across Claude Code and Codex without pretending both runtimes have the same plugin model.

## Important

Claude Code has plugin marketplace commands. Codex currently uses local skills and interactive installation; there is no equivalent `codex plugin update` command to script.

Also, `claude` CLI commands should be run from a separate terminal, not from inside a running Claude Code session.

## Decide Target

| User intent | Action |
| --- | --- |
| Claude Code plugins / marketplaces | Generate and hand off a Claude update script |
| Codex local skills | Pull or copy the repo into the Codex skills directory |
| Both CC and Codex | Do Claude update first, then sync Codex local skills |
| This repo only | `git pull` the repo, then copy/install as needed |

When unclear, ask which target they mean: Claude Code, Codex, or both.

## Claude Code Update

Generate a temporary script and tell the user to run it in a separate terminal.

### Windows

```powershell
$scriptContent = @'
Write-Host "=== Updating Claude Code marketplaces ===" -ForegroundColor Cyan
claude plugin marketplace update

Write-Host ""
Write-Host "=== Updating Claude Code plugins ===" -ForegroundColor Cyan
$plugins = claude plugin list --json 2>$null | ConvertFrom-Json
if ($plugins) {
    foreach ($p in $plugins) {
        Write-Host "Updating $($p.name)..." -ForegroundColor Yellow
        claude plugin update $p.name
    }
} else {
    Write-Host "Could not parse plugin list. Marketplace index was still refreshed."
}

Write-Host ""
Write-Host "=== Done ===" -ForegroundColor Green
Write-Host "Restart Claude Code to apply updates."
'@
$scriptPath = "$env:TEMP\claude_update_skills.ps1"
Set-Content -Path $scriptPath -Value $scriptContent -Encoding UTF8
Write-Host "Script saved to: $scriptPath"
```

Run command:

```powershell
powershell -ExecutionPolicy Bypass -File "$env:TEMP\claude_update_skills.ps1"
```

### macOS/Linux

```bash
cat > /tmp/claude_update_skills.sh << 'SCRIPT'
#!/usr/bin/env bash
set -euo pipefail

echo "=== Updating Claude Code marketplaces ==="
claude plugin marketplace update

echo ""
echo "=== Updating Claude Code plugins ==="
if command -v jq >/dev/null 2>&1; then
  claude plugin list --json 2>/dev/null | jq -r '.[].name' | while read -r name; do
    [ -n "$name" ] || continue
    echo "Updating $name..."
    claude plugin update "$name"
  done
else
  echo "jq missing; marketplace index was refreshed but plugin list was not parsed."
fi

echo ""
echo "=== Done ==="
echo "Restart Claude Code to apply updates."
SCRIPT
chmod +x /tmp/claude_update_skills.sh
echo "Script saved to: /tmp/claude_update_skills.sh"
```

Run command:

```bash
bash /tmp/claude_update_skills.sh
```

## Codex Skills Sync

Codex skills are local folders. Update by refreshing the source repo and copying `skills/*` into the Codex skills directory.

### Windows

```powershell
$repo = "$env:USERPROFILE\workspace\darkingtail-skills"
$target = "$env:USERPROFILE\.codex\skills"

if (-not (Test-Path $repo)) {
    git clone https://github.com/darkingtail/skills.git $repo
} else {
    git -C $repo pull --ff-only
}

New-Item -ItemType Directory -Force -Path $target | Out-Null
Copy-Item -Path "$repo\skills\*" -Destination $target -Recurse -Force
Write-Host "Codex skills synced to $target"
Write-Host "Restart Codex or start a new session if skill metadata does not refresh."
```

### macOS/Linux

```bash
repo="$HOME/workspace/darkingtail-skills"
target="$HOME/.codex/skills"

if [ ! -d "$repo/.git" ]; then
  git clone https://github.com/darkingtail/skills.git "$repo"
else
  git -C "$repo" pull --ff-only
fi

mkdir -p "$target"
cp -R "$repo"/skills/* "$target"/
echo "Codex skills synced to $target"
echo "Restart Codex or start a new session if skill metadata does not refresh."
```

## Final Message

Always state:

- Which target was updated or prepared: Claude Code, Codex, or both
- The script path or commands
- Whether a restart/new session is needed
