# 查找所有调试日志脚本 (PowerShell)

Write-Host "🔍 查找项目中的所有调试日志..." -ForegroundColor Cyan
Write-Host "================================"
Write-Host ""

# 检查是否在项目目录中
$commonDirs = @("src", "lib", "app", "components", "pages")
$foundDirs = $commonDirs | Where-Object { Test-Path $_ }

if ($foundDirs.Count -eq 0) {
    Write-Host "⚠️  警告: 未找到常见的源代码目录 (src/lib/app)" -ForegroundColor Yellow
    Write-Host "当前目录: $(Get-Location)"
    Write-Host ""
    $continue = Read-Host "是否继续在当前目录搜索？(y/N)"
    if ($continue -ne 'y' -and $continue -ne 'Y') {
        exit 0
    }
    $searchDirs = @(".")
} else {
    $searchDirs = $foundDirs
}

Write-Host "搜索目录: $($searchDirs -join ', ')"
Write-Host ""

# 统计变量
$totalLogs = 0
$totalFiles = 0
$prefixStats = @{}

# JavaScript/TypeScript 日志
Write-Host "📝 JavaScript/TypeScript 日志:" -ForegroundColor Green
Write-Host "--------------------------------"

$jsPattern = "console\.(log|debug|info|warn|error)\([`"'][[]"

$jsFiles = @()
foreach ($dir in $searchDirs) {
    if (Test-Path $dir) {
        Get-ChildItem -Path $dir -Recurse -Include *.js,*.jsx,*.ts,*.tsx,*.vue -File -ErrorAction SilentlyContinue |
            Where-Object { $_.FullName -notmatch 'node_modules|\.git' } |
            ForEach-Object {
                $file = $_
                $lineNum = 0
                Get-Content $file.FullName | ForEach-Object {
                    $lineNum++
                    if ($_ -match $jsPattern -and $_ -match '\[[A-Z]+-[A-Z]+\]') {
                        $relativePath = $file.FullName.Replace((Get-Location).Path + "\", "").Replace("\", "/")
                        Write-Host "  ${relativePath}:${lineNum}:  $_" -ForegroundColor White
                        $totalLogs++

                        # 提取前缀
                        if ($_ -match '\[([A-Z]+-[A-Z]+)\]') {
                            $prefix = $matches[1]
                            if ($prefixStats.ContainsKey($prefix)) {
                                $prefixStats[$prefix]++
                            } else {
                                $prefixStats[$prefix] = 1
                            }
                        }

                        if ($jsFiles -notcontains $file.FullName) {
                            $jsFiles += $file.FullName
                        }
                    }
                }
            }
    }
}

$totalFiles += $jsFiles.Count
Write-Host ""

# Python 日志
$pyPattern = "print.*\[.*-.*\]"
$pyFiles = @()

foreach ($dir in $searchDirs) {
    if (Test-Path $dir) {
        $hasPyLogs = Get-ChildItem -Path $dir -Recurse -Include *.py -File -ErrorAction SilentlyContinue |
            Where-Object { $_.FullName -notmatch '\.git' } |
            Select-Object -First 1 |
            ForEach-Object { (Get-Content $_.FullName -Raw) -match $pyPattern }

        if ($hasPyLogs) {
            Write-Host "🐍 Python 日志:" -ForegroundColor Green
            Write-Host "--------------------------------"

            Get-ChildItem -Path $dir -Recurse -Include *.py -File -ErrorAction SilentlyContinue |
                Where-Object { $_.FullName -notmatch '\.git' } |
                ForEach-Object {
                    $file = $_
                    $lineNum = 0
                    Get-Content $file.FullName | ForEach-Object {
                        $lineNum++
                        if ($_ -match $pyPattern -and $_ -match '\[[A-Z]+-[A-Z]+\]') {
                            $relativePath = $file.FullName.Replace((Get-Location).Path + "\", "").Replace("\", "/")
                            Write-Host "  ${relativePath}:${lineNum}:  $_" -ForegroundColor White
                            $totalLogs++

                            if ($_ -match '\[([A-Z]+-[A-Z]+)\]') {
                                $prefix = $matches[1]
                                if ($prefixStats.ContainsKey($prefix)) {
                                    $prefixStats[$prefix]++
                                } else {
                                    $prefixStats[$prefix] = 1
                                }
                            }

                            if ($pyFiles -notcontains $file.FullName) {
                                $pyFiles += $file.FullName
                            }
                        }
                    }
                }

            $totalFiles += $pyFiles.Count
            Write-Host ""
        }
    }
}

# Java 日志
$javaPattern = "System\.out\.println.*\[.*-.*\]"
$javaFiles = @()

foreach ($dir in $searchDirs) {
    if (Test-Path $dir) {
        $hasJavaLogs = Get-ChildItem -Path $dir -Recurse -Include *.java -File -ErrorAction SilentlyContinue |
            Where-Object { $_.FullName -notmatch '\.git' } |
            Select-Object -First 1 |
            ForEach-Object { (Get-Content $_.FullName -Raw) -match $javaPattern }

        if ($hasJavaLogs) {
            Write-Host "☕ Java 日志:" -ForegroundColor Green
            Write-Host "--------------------------------"

            Get-ChildItem -Path $dir -Recurse -Include *.java -File -ErrorAction SilentlyContinue |
                Where-Object { $_.FullName -notmatch '\.git' } |
                ForEach-Object {
                    $file = $_
                    $lineNum = 0
                    Get-Content $file.FullName | ForEach-Object {
                        $lineNum++
                        if ($_ -match $javaPattern -and $_ -match '\[[A-Z]+-[A-Z]+\]') {
                            $relativePath = $file.FullName.Replace((Get-Location).Path + "\", "").Replace("\", "/")
                            Write-Host "  ${relativePath}:${lineNum}:  $_" -ForegroundColor White
                            $totalLogs++

                            if ($_ -match '\[([A-Z]+-[A-Z]+)\]') {
                                $prefix = $matches[1]
                                if ($prefixStats.ContainsKey($prefix)) {
                                    $prefixStats[$prefix]++
                                } else {
                                    $prefixStats[$prefix] = 1
                                }
                            }

                            if ($javaFiles -notcontains $file.FullName) {
                                $javaFiles += $file.FullName
                            }
                        }
                    }
                }

            $totalFiles += $javaFiles.Count
            Write-Host ""
        }
    }
}

# 汇总
Write-Host "================================"
Write-Host "📊 汇总统计:" -ForegroundColor Cyan
Write-Host "  共找到 $totalLogs 条调试日志"
Write-Host "  涉及 $totalFiles 个文件"
Write-Host ""

# 按前缀分类统计
if ($prefixStats.Count -gt 0) {
    Write-Host "🏷️  前缀分类:" -ForegroundColor Cyan
    Write-Host "--------------------------------"

    $prefixStats.GetEnumerator() | Sort-Object -Property Value -Descending | ForEach-Object {
        $prefix = "[$($_.Key)]"
        $count = $_.Value
        Write-Host ("  {0,-20} {1,3} 次" -f $prefix, $count)
    }

    Write-Host ""
}

Write-Host "💡 提示：" -ForegroundColor Yellow
Write-Host "  - 使用 .\scripts\remove-debug-logs.ps1 清理所有调试日志"
Write-Host "  - 或告诉 Claude: '请清理所有调试日志'"
