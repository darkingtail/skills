# 移除指定前缀的调试日志 (PowerShell)
# 用法: .\scripts\remove-debug-logs.ps1 <PREFIX>
# 示例: .\scripts\remove-debug-logs.ps1 DEBUG-LOGIN

param(
    [Parameter(Position=0)]
    [string]$Prefix
)

if (-not $Prefix) {
    Write-Host "❌ 必须指定要清理的前缀" -ForegroundColor Red
    Write-Host ""
    Write-Host "用法: .\scripts\remove-debug-logs.ps1 <PREFIX>"
    Write-Host "示例: .\scripts\remove-debug-logs.ps1 DEBUG-LOGIN"
    Write-Host ""
    Write-Host "💡 使用 .\scripts\find-debug-logs.ps1 查看所有前缀" -ForegroundColor Yellow
    exit 1
}

Write-Host "🗑️  移除 [$Prefix] 调试日志" -ForegroundColor Cyan
Write-Host "================================"
Write-Host ""

# 搜索目录
$commonDirs = @("src", "lib", "app", "components", "pages")
$searchDirs = $commonDirs | Where-Object { Test-Path $_ }

if ($searchDirs.Count -eq 0) {
    $searchDirs = @(".")
}

Write-Host "搜索目录: $($searchDirs -join ', ')"
Write-Host "目标前缀: [$Prefix]"
Write-Host ""

# 查找包含该前缀的文件
$affectedFiles = @()
$escapedPrefix = [regex]::Escape("[$Prefix]")

foreach ($dir in $searchDirs) {
    if (Test-Path $dir) {
        Get-ChildItem -Path $dir -Recurse -Include *.js,*.jsx,*.ts,*.tsx,*.vue,*.py,*.java,*.go,*.rs -File -ErrorAction SilentlyContinue |
            Where-Object { $_.FullName -notmatch 'node_modules|\.git' } |
            ForEach-Object {
                $content = Get-Content $_.FullName -Raw -ErrorAction SilentlyContinue
                if ($content -and $content -match $escapedPrefix) {
                    if ($affectedFiles -notcontains $_.FullName) {
                        $affectedFiles += $_.FullName
                    }
                }
            }
    }
}

if ($affectedFiles.Count -eq 0) {
    Write-Host "✅ 未找到任何 [$Prefix] 调试日志" -ForegroundColor Green
    exit 0
}

# 统计
$totalLogs = 0
$fileStats = @()

foreach ($file in $affectedFiles) {
    $count = (Select-String -Path $file -Pattern $escapedPrefix).Count
    $totalLogs += $count
    $relativePath = $file.Replace((Get-Location).Path + "\", "").Replace("\", "/")
    $fileStats += @{ Path = $relativePath; Count = $count }
}

Write-Host "📋 将要处理的文件 ($($affectedFiles.Count) 个, 共 $totalLogs 条日志):" -ForegroundColor Cyan
foreach ($stat in $fileStats) {
    Write-Host "  $($stat.Path) ($($stat.Count) 条)"
}
Write-Host ""

# 确认
$confirm = Read-Host "⚠️  确认删除 [$Prefix] 日志吗？(y/N)"
if ($confirm -ne 'y' -and $confirm -ne 'Y') {
    Write-Host "❌ 已取消" -ForegroundColor Red
    exit 0
}

# 创建备份
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$backupDir = ".debug-logs-backup-$timestamp"
New-Item -ItemType Directory -Path $backupDir -Force | Out-Null

Write-Host ""
Write-Host "📦 创建备份到: $backupDir" -ForegroundColor Cyan

foreach ($file in $affectedFiles) {
    $relativePath = $file.Replace((Get-Location).Path + "\", "")
    $backupPath = Join-Path $backupDir $relativePath
    $backupParent = Split-Path $backupPath -Parent

    if (-not (Test-Path $backupParent)) {
        New-Item -ItemType Directory -Path $backupParent -Force | Out-Null
    }

    Copy-Item $file $backupPath -Force
}

Write-Host "✅ 备份完成" -ForegroundColor Green
Write-Host ""

# 删除指定前缀的日志
Write-Host "🔧 正在移除 [$Prefix] 日志..." -ForegroundColor Cyan

$removedCount = 0

foreach ($file in $affectedFiles) {
    $lines = Get-Content $file
    $newLines = $lines | Where-Object { $_ -notmatch $escapedPrefix }

    $newLines | Set-Content $file -Encoding UTF8

    $relativePath = $file.Replace((Get-Location).Path + "\", "").Replace("\", "/")
    Write-Host "  ✓ $relativePath" -ForegroundColor Green
    $removedCount++
}

Write-Host ""
Write-Host "================================"
Write-Host "✅ 清理完成！" -ForegroundColor Green
Write-Host ""
Write-Host "📊 统计：" -ForegroundColor Cyan
Write-Host "  - 前缀: [$Prefix]"
Write-Host "  - 处理文件: $removedCount 个"
Write-Host "  - 移除日志: $totalLogs 条"
Write-Host "  - 备份位置: $backupDir"
Write-Host ""
Write-Host "💡 如需恢复，可以从备份目录复制文件" -ForegroundColor Yellow
Write-Host ""

# 询问是否删除备份
$keepBackup = Read-Host "是否保留备份文件？(Y/n)"
if ($keepBackup -eq 'n' -or $keepBackup -eq 'N') {
    Remove-Item -Path $backupDir -Recurse -Force
    Write-Host "🗑️  已删除备份" -ForegroundColor Yellow
} else {
    Write-Host "📦 备份已保留在: $backupDir" -ForegroundColor Green
}
