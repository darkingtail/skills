# Fetch starred repos for the authenticated user.
# Output: one JSON object per line (jsonl).
# Usage:
#   powershell -Command "& './scripts/fetch_stars.ps1'"              # all stars
#   powershell -Command "& './scripts/fetch_stars.ps1' -Limit 10"   # latest 10

param(
    [int]$Limit = 0
)

$ErrorActionPreference = 'Stop'

if ($Limit -gt 0) {
    $PerPage = [Math]::Min($Limit, 100)
    $raw = gh api "/user/starred?per_page=$PerPage"
    $repos = $raw | ConvertFrom-Json
    $repos = @($repos | Select-Object -First $Limit)
} else {
    $raw = gh api "/user/starred?per_page=100" --paginate
    $repos = $raw | ConvertFrom-Json
}

foreach ($r in $repos) {
    $desc = ''; if ($r.description) { $desc = $r.description }
    $topics = @(); if ($r.topics) { $topics = @($r.topics) }
    $lang = ''; if ($r.language) { $lang = $r.language }

    $obj = [ordered]@{
        id                = $r.node_id
        full_name         = $r.full_name
        description       = $desc
        topics            = $topics
        language          = $lang
        url               = $r.html_url
        pushed_at         = $r.pushed_at
        archived          = [bool]$r.archived
        open_issues_count = [int]$r.open_issues_count
    }
    ConvertTo-Json $obj -Compress
}
