param(
    [Parameter(Position = 0)]
    [ValidateSet('list', 'plan-create', 'create', 'plan-remove', 'remove', 'purge', 'self-test')]
    [string]$Action = 'list',

    [string]$TargetPath,
    [string]$Name,
    [string]$Email,
    [switch]$Yes,
    [switch]$DeleteConfig,
    [string]$GlobalConfig = (Join-Path $HOME '.gitconfig')
)

$ErrorActionPreference = 'Stop'

$SkillMarker = 'managed-by: folder-git-identity'
$EndMarker = 'end-managed-by: folder-git-identity'
$UserStartMarker = 'folder-git-identity: managed user section'
$UserEndMarker = 'folder-git-identity: end managed user section'

function Resolve-GitPath {
    param([Parameter(Mandatory)][string]$Path)
    $expanded = $Path
    if ($expanded.StartsWith('~')) {
        $expanded = Join-Path $HOME $expanded.Substring(1)
    }
    if (Test-Path -LiteralPath $expanded) {
        $full = (Resolve-Path -LiteralPath $expanded).Path
    } else {
        $full = [System.IO.Path]::GetFullPath($expanded)
    }
    $full = $full -replace '\\', '/'
    if (-not $full.EndsWith('/')) { $full += '/' }
    return $full
}

function ConvertTo-HomePath {
    param([Parameter(Mandatory)][string]$Path)
    if ($Path.StartsWith('~/')) {
        return Join-Path $HOME ($Path.Substring(2))
    }
    if ($Path.StartsWith('~\')) {
        return Join-Path $HOME ($Path.Substring(2))
    }
    return $Path
}

function Get-IncludeRules {
    param([string]$ConfigPath = $GlobalConfig)
    if (-not (Test-Path -LiteralPath $ConfigPath)) { return @() }
    $lines = @(Get-Content -LiteralPath $ConfigPath)
    $rules = @()
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match '^\s*\[includeIf\s+"gitdir:(.+)"\]\s*$') {
            $gitdir = $Matches[1]
            $path = ''
            $managed = $false
            for ($j = [Math]::Max(0, $i - 3); $j -lt $i; $j++) {
                if ($lines[$j] -like "*$SkillMarker*") { $managed = $true }
            }
            for ($j = $i + 1; $j -lt $lines.Count; $j++) {
                if ($lines[$j] -match '^\s*\[') { break }
                if ($lines[$j] -match '^\s*path\s*=\s*(.+?)\s*$') {
                    $path = $Matches[1]
                    break
                }
            }
            $rules += [pscustomobject]@{
                GitDir = $gitdir
                Path = $path
                Managed = $managed
                Line = $i
            }
        }
    }
    return $rules
}

function Get-ConfigFileName {
    param([Parameter(Mandatory)][string]$GitDir)
    $rules = @(Get-IncludeRules)
    $clean = $GitDir.TrimEnd('/')
    $parts = @($clean -split '/' | Where-Object { $_ -ne '' })
    if ($parts.Count -eq 0) { throw "Cannot derive config name from '$GitDir'" }

    for ($count = 1; $count -le $parts.Count; $count++) {
        $slice = $parts[($parts.Count - $count)..($parts.Count - 1)]
        $name = ($slice -join '-') -replace ':', ''
        $candidate = "~/.gitconfig-$name"
        $usedByOther = @($rules | Where-Object { $_.Path -eq $candidate -and $_.GitDir -ne $GitDir })
        if ($usedByOther.Count -eq 0) { return $candidate }
    }

    $fallback = ($parts -join '-') -replace ':', ''
    return "~/.gitconfig-$fallback"
}

function Get-UserValues {
    param([Parameter(Mandatory)][string]$ConfigPath)
    $actual = ConvertTo-HomePath $ConfigPath
    if (-not (Test-Path -LiteralPath $actual)) {
        return [pscustomobject]@{ Exists = $false; Name = ''; Email = '' }
    }
    $currentName = (& git config --file $actual user.name 2>$null)
    $currentEmail = (& git config --file $actual user.email 2>$null)
    return [pscustomobject]@{ Exists = $true; Name = "$currentName"; Email = "$currentEmail" }
}

function Set-ManagedUserSection {
    param(
        [Parameter(Mandatory)][string]$ConfigPath,
        [Parameter(Mandatory)][string]$UserName,
        [Parameter(Mandatory)][string]$UserEmail
    )
    $actual = ConvertTo-HomePath $ConfigPath
    $block = @(
        "# $UserStartMarker",
        '[user]',
        "    name = $UserName",
        "    email = $UserEmail",
        "# $UserEndMarker"
    )

    if (-not (Test-Path -LiteralPath $actual)) {
        $content = @(
            "# $SkillMarker",
            '# managed-action: created-file'
        ) + $block
        Set-Content -LiteralPath $actual -Value $content
        return
    }

    $lines = @(Get-Content -LiteralPath $actual)
    $start = -1
    $end = $lines.Count
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match '^\s*\[user\]\s*$') {
            $start = $i
            if ($i -gt 0 -and $lines[$i - 1] -like "*$UserStartMarker*") { $start = $i - 1 }
            for ($j = $i + 1; $j -lt $lines.Count; $j++) {
                if ($lines[$j] -like "*$UserEndMarker*") {
                    $end = $j + 1
                    break
                }
                if ($lines[$j] -match '^\s*\[') {
                    $end = $j
                    break
                }
            }
            break
        }
    }

    if ($start -lt 0) {
        $newLines = $lines + @('', $block)
    } else {
        $sectionStart = $start
        if ($lines[$sectionStart] -like "*$UserStartMarker*") { $sectionStart++ }
        $preservedUserLines = @()
        for ($k = $sectionStart + 1; $k -lt $end; $k++) {
            if ($lines[$k] -like "*$UserEndMarker*") { continue }
            if ($lines[$k] -match '^\s*(name|email)\s*=') { continue }
            $preservedUserLines += $lines[$k]
        }
        $newBlock = @(
            "# $UserStartMarker",
            '[user]',
            "    name = $UserName",
            "    email = $UserEmail"
        ) + $preservedUserLines + @("# $UserEndMarker")
        $before = if ($start -gt 0) { $lines[0..($start - 1)] } else { @() }
        $after = if ($end -lt $lines.Count) { $lines[$end..($lines.Count - 1)] } else { @() }
        $newLines = @($before) + $newBlock + @($after)
    }
    Set-Content -LiteralPath $actual -Value $newLines
}

function Add-OrUpdateInclude {
    param(
        [Parameter(Mandatory)][string]$GitDir,
        [Parameter(Mandatory)][string]$ConfigPath
    )
    if (-not (Test-Path -LiteralPath $GlobalConfig)) {
        New-Item -ItemType File -Path $GlobalConfig -Force | Out-Null
    }
    $rules = @(Get-IncludeRules)
    $existing = @($rules | Where-Object { $_.GitDir -eq $GitDir })
    if ($existing.Count -gt 0 -and $existing[0].Path -eq $ConfigPath) { return }
    if ($existing.Count -gt 0) {
        throw "Include rule already exists for $GitDir and points to $($existing[0].Path). Remove it or confirm manually before updating."
    }
    $block = @(
        '',
        "# $SkillMarker",
        '# managed-action: created-include',
        "[includeIf `"gitdir:$GitDir`"]",
        "    path = $ConfigPath",
        "# $EndMarker"
    )
    Add-Content -LiteralPath $GlobalConfig -Value $block
}

function Remove-IncludeForGitDir {
    param([Parameter(Mandatory)][string]$GitDir)
    if (-not (Test-Path -LiteralPath $GlobalConfig)) { return $null }
    $lines = @(Get-Content -LiteralPath $GlobalConfig)
    $start = -1
    $end = -1
    $path = ''
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match "^\s*\[includeIf\s+`"gitdir:$([regex]::Escape($GitDir))`"\]\s*$") {
            $start = $i
            if ($i -gt 0 -and $lines[$i - 1] -like "*managed-action:*") { $start = $i - 1 }
            if ($start -gt 0 -and $lines[$start - 1] -like "*$SkillMarker*") { $start = $start - 1 }
            for ($j = $i + 1; $j -lt $lines.Count; $j++) {
                if ($lines[$j] -match '^\s*path\s*=\s*(.+?)\s*$') { $path = $Matches[1] }
                if ($lines[$j] -like "*$EndMarker*") {
                    $end = $j + 1
                    break
                }
                if ($lines[$j] -match '^\s*\[') {
                    $end = $j
                    break
                }
            }
            if ($end -lt 0) { $end = [Math]::Min($i + 2, $lines.Count) }
            break
        }
    }
    if ($start -lt 0) { return $null }
    $before = if ($start -gt 0) { $lines[0..($start - 1)] } else { @() }
    $after = if ($end -lt $lines.Count) { $lines[$end..($lines.Count - 1)] } else { @() }
    Set-Content -LiteralPath $GlobalConfig -Value (@($before) + @($after))
    return $path
}

function Confirm-Step {
    param([string]$Message)
    if ($Yes) { return $true }
    $answer = Read-Host "$Message Type YES to continue"
    return $answer -eq 'YES'
}

function Show-CreatePlan {
    param([string]$GitDir, [string]$ConfigPath)
    $actualConfig = ConvertTo-HomePath $ConfigPath
    $user = Get-UserValues $ConfigPath
    $rules = @(Get-IncludeRules)
    $matching = @($rules | Where-Object { $_.GitDir -eq $GitDir })
    Write-Host "Target folder: $GitDir"
    Write-Host "Config file:   $ConfigPath ($actualConfig)"
    Write-Host "Config exists: $($user.Exists)"
    if ($user.Exists) {
        Write-Host "Current user.name:  $($user.Name)"
        Write-Host "Current user.email: $($user.Email)"
    }
    if ($Name) { Write-Host "Target user.name:   $Name" }
    if ($Email) { Write-Host "Target user.email:  $Email" }
    if ($matching.Count -eq 0) {
        Write-Host "Include rule: missing"
    } else {
        Write-Host "Include rule: $($matching[0].GitDir) -> $($matching[0].Path) managed=$($matching[0].Managed)"
    }
}

if ($Action -eq 'self-test') {
    $tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("fgi-" + [guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $tmp | Out-Null
    try {
        $GlobalConfig = Join-Path $tmp '.gitconfig'
        $HOME_BACKUP = $HOME
        $target = Join-Path $tmp 'dev\darkingtail'
        New-Item -ItemType Directory -Path $target | Out-Null
        $gitdir = Resolve-GitPath $target
        if (-not $gitdir.EndsWith('/')) { throw 'normalize failed' }
        $cfg = Get-ConfigFileName $gitdir
        if ($cfg -ne '~/.gitconfig-darkingtail') { throw "name failed: $cfg" }
        Set-ManagedUserSection -ConfigPath (Join-Path $tmp '.gitconfig-darkingtail') -UserName 'darkingtail' -UserEmail 'a@example.com'
        $u = Get-UserValues (Join-Path $tmp '.gitconfig-darkingtail')
        if ($u.Name -ne 'darkingtail' -or $u.Email -ne 'a@example.com') { throw 'user section failed' }
        $existingConfig = Join-Path $tmp '.gitconfig-existing'
        Set-Content -LiteralPath $existingConfig -Value @(
            '[user]',
            '    name = old',
            '    email = old@example.com',
            '    signingkey = ABC123',
            '[core]',
            '    editor = vim'
        )
        Set-ManagedUserSection -ConfigPath $existingConfig -UserName 'new' -UserEmail 'new@example.com'
        $existingText = Get-Content -LiteralPath $existingConfig -Raw
        if ($existingText -notmatch 'signingkey = ABC123' -or $existingText -notmatch 'editor = vim') { throw 'preserve existing config failed' }
        $updated = Get-UserValues $existingConfig
        if ($updated.Name -ne 'new' -or $updated.Email -ne 'new@example.com') { throw 'update existing user failed' }
        Add-OrUpdateInclude -GitDir $gitdir -ConfigPath '~/.gitconfig-darkingtail'
        $rules = @(Get-IncludeRules)
        if ($rules.Count -ne 1 -or -not $rules[0].Managed) { throw 'include failed' }
        $removed = Remove-IncludeForGitDir -GitDir $gitdir
        if ($removed -ne '~/.gitconfig-darkingtail') { throw 'remove failed' }
        Write-Host 'self-test passed'
    } finally {
        Remove-Item -LiteralPath $tmp -Recurse -Force
    }
    exit 0
}

if ($Action -eq 'list') {
    $rules = @(Get-IncludeRules)
    if ($rules.Count -eq 0) {
        Write-Host 'No includeIf.gitdir rules found.'
    } else {
        $rules | Format-Table GitDir, Path, Managed -AutoSize
    }
    exit 0
}

if (-not $TargetPath -and $Action -ne 'purge') {
    throw "-TargetPath is required for $Action"
}

if ($TargetPath) {
    $gitDir = Resolve-GitPath $TargetPath
    $configPath = Get-ConfigFileName $gitDir
}

switch ($Action) {
    'plan-create' {
        Show-CreatePlan -GitDir $gitDir -ConfigPath $configPath
    }
    'create' {
        if (-not $Name -or -not $Email) { throw '-Name and -Email are required for create' }
        Show-CreatePlan -GitDir $gitDir -ConfigPath $configPath
        if (-not (Confirm-Step 'Create or update this folder Git identity?')) { exit 1 }
        Set-ManagedUserSection -ConfigPath $configPath -UserName $Name -UserEmail $Email
        Add-OrUpdateInclude -GitDir $gitDir -ConfigPath $configPath
        Write-Host "Configured $gitDir -> $configPath"
    }
    'plan-remove' {
        $rules = @(Get-IncludeRules)
        $matching = @($rules | Where-Object { $_.GitDir -eq $gitDir })
        if ($matching.Count -eq 0) { Write-Host "No include rule found for $gitDir"; exit 0 }
        $refs = @($rules | Where-Object { $_.Path -eq $matching[0].Path -and $_.GitDir -ne $gitDir })
        Write-Host "Target folder: $gitDir"
        Write-Host "Include rule:  $($matching[0].GitDir) -> $($matching[0].Path)"
        Write-Host "Managed:       $($matching[0].Managed)"
        Write-Host "Other refs:    $($refs.Count)"
        $refs | Format-Table GitDir, Path, Managed -AutoSize
    }
    'remove' {
        $rules = @(Get-IncludeRules)
        $matching = @($rules | Where-Object { $_.GitDir -eq $gitDir })
        if ($matching.Count -eq 0) { Write-Host "No include rule found for $gitDir"; exit 0 }
        $refs = @($rules | Where-Object { $_.Path -eq $matching[0].Path -and $_.GitDir -ne $gitDir })
        Write-Host "Will remove include rule: $($matching[0].GitDir) -> $($matching[0].Path)"
        if (-not (Confirm-Step 'Remove this include rule?')) { exit 1 }
        $removedPath = Remove-IncludeForGitDir -GitDir $gitDir
        if ($DeleteConfig) {
            if ($refs.Count -gt 0) { throw "Config file is still referenced by other include rules." }
            $actual = ConvertTo-HomePath $removedPath
            if (Test-Path -LiteralPath $actual) {
                if (Confirm-Step "Delete config file $actual?") {
                    Remove-Item -LiteralPath $actual
                }
            }
        }
        Write-Host "Removed include rule for $gitDir"
    }
    'purge' {
        $rules = @(Get-IncludeRules)
        $managed = @($rules | Where-Object { $_.Managed })
        if ($managed.Count -eq 0) { Write-Host 'No managed include rules found.'; exit 0 }
        $managed | Format-Table GitDir, Path, Managed -AutoSize
        if (-not (Confirm-Step 'Remove all managed include rules listed above?')) { exit 1 }
        foreach ($rule in $managed) {
            [void](Remove-IncludeForGitDir -GitDir $rule.GitDir)
        }
        Write-Host "Removed $($managed.Count) managed include rule(s)."
    }
}
