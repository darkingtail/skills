# GitHub Lists management via GraphQL.
# Usage:
#   powershell -File scripts/manage_lists.ps1 get                                    - Get all lists
#   powershell -File scripts/manage_lists.ps1 create "<name>" "[description]"        - Create a new list
#   powershell -File scripts/manage_lists.ps1 delete <list_id>                       - Delete a list
#   powershell -File scripts/manage_lists.ps1 add <repo_node_id> <list_id> [...]     - Add repo to list(s)

param(
    [Parameter(Position = 0)]
    [string]$Command = 'help',

    [Parameter(Position = 1, ValueFromRemainingArguments)]
    [string[]]$Params
)

$ErrorActionPreference = 'Stop'
$MaxRetries = 3
$RetryDelay = 2
if ($env:MAX_RETRIES) { $MaxRetries = [int]$env:MAX_RETRIES }
if ($env:RETRY_DELAY) { $RetryDelay = [int]$env:RETRY_DELAY }

function Invoke-WithRetry {
    param([scriptblock]$Action)
    for ($attempt = 1; $attempt -le $MaxRetries; $attempt++) {
        try {
            return (& $Action)
        } catch {
            if ($attempt -ge $MaxRetries) { throw }
            Start-Sleep -Seconds $RetryDelay
        }
    }
}

switch ($Command) {
    'get' {
        gh api graphql -f query='query { viewer { lists(first: 32) { nodes { id name slug description items(first: 0) { totalCount } } totalCount } } }' --jq '.data.viewer.lists'
    }

    'create' {
        $Name = $Params[0]
        if (-not $Name) { throw 'name required' }
        $Desc = ''
        if ($Params.Count -gt 1) { $Desc = $Params[1] }
        Invoke-WithRetry {
            gh api graphql -f query='mutation($input: CreateUserListInput!) { createUserList(input: $input) { list { id name } } }' -f "input[name]=$Name" -f "input[description]=$Desc" --jq '.data.createUserList.list'
        }
    }

    'delete' {
        $ListId = $Params[0]
        if (-not $ListId) { throw 'list_id required' }
        Invoke-WithRetry {
            gh api graphql -f query='mutation($input: DeleteUserListInput!) { deleteUserList(input: $input) { user { login } } }' -f "input[listId]=$ListId" --jq '.data.deleteUserList.user.login'
        }
    }

    'add' {
        $RepoId = $Params[0]
        if (-not $RepoId) { throw 'repo_node_id required' }
        $ListIds = @($Params[1..($Params.Count - 1)])
        if ($ListIds.Count -eq 0) { throw 'At least one list_id required' }

        $Body = @{
            query     = 'mutation($itemId: ID!, $listIds: [ID!]!) { updateUserListsForItem(input: {itemId: $itemId, listIds: $listIds}) { user { login } } }'
            variables = @{
                itemId  = $RepoId
                listIds = $ListIds
            }
        } | ConvertTo-Json -Depth 3 -Compress

        Invoke-WithRetry {
            $Body | gh api graphql --input - --jq '.data.updateUserListsForItem.user.login'
        }
    }

    default {
        Write-Host 'Usage: manage_lists.ps1 {get|create|delete|add} [args...]'
    }
}
