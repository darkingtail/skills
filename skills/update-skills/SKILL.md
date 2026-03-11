---
name: update-skills
description: "One-click update all Claude Code plugins and marketplaces. Triggers: 'update skills', '更新 skills', '更新插件', '一键更新'."
---

# Update Skills

Update all installed Claude Code marketplaces and plugins in one go.

## Important

`claude` CLI cannot be invoked from within a running Claude Code session. This skill generates a ready-to-run script for the user.

## Workflow

### Step 1: Generate Update Script

Write a temporary script that:

1. Updates all marketplace indexes
2. Lists installed plugins
3. Updates each installed plugin

**Windows (PowerShell):**

```powershell
$scriptContent = @'
Write-Host "=== Updating marketplaces ===" -ForegroundColor Cyan
claude plugin marketplace update

Write-Host ""
Write-Host "=== Updating plugins ===" -ForegroundColor Cyan
$plugins = claude plugin list --json 2>$null | ConvertFrom-Json
if ($plugins) {
    foreach ($p in $plugins) {
        Write-Host "Updating $($p.name)..." -ForegroundColor Yellow
        claude plugin update $p.name
    }
} else {
    Write-Host "Could not parse plugin list, updating all known plugins..."
    claude plugin marketplace update
}

Write-Host ""
Write-Host "=== Done ===" -ForegroundColor Green
Write-Host "Restart Claude Code to apply updates."
'@
$scriptPath = "$env:TEMP\claude_update_skills.ps1"
Set-Content -Path $scriptPath -Value $scriptContent
Write-Host "Script saved to: $scriptPath"
```

**macOS/Linux (Bash):**

```bash
cat > /tmp/claude_update_skills.sh << 'SCRIPT'
#!/usr/bin/env bash
set -euo pipefail

echo "=== Updating marketplaces ==="
claude plugin marketplace update

echo ""
echo "=== Updating plugins ==="
claude plugin list --json 2>/dev/null | jq -r '.[].name' | while read -r name; do
    echo "Updating $name..."
    claude plugin update "$name"
done

echo ""
echo "=== Done ==="
echo "Restart Claude Code to apply updates."
SCRIPT
chmod +x /tmp/claude_update_skills.sh
echo "Script saved to: /tmp/claude_update_skills.sh"
```

### Step 2: Present to User

Tell the user:

1. The script has been saved
2. They need to run it **in a separate terminal** (not inside Claude Code)
3. Provide the exact run command:
   - Windows: `powershell -ExecutionPolicy Bypass -File "$env:TEMP\claude_update_skills.ps1"`
   - macOS/Linux: `bash /tmp/claude_update_skills.sh`
4. Restart Claude Code after the script completes

### Platform Detection

- `win32` platform → generate PowerShell script
- `darwin` / `linux` → generate Bash script
