---
name: darkingtail:folder-git-identity
description: Configure, verify, update, and remove directory-scoped Git identity with includeIf.gitdir. Use when the user wants one Git user.name/user.email to apply automatically to all repositories under a workspace folder, wants separate personal/company/client/open-source Git identities by folder, wants to inspect includeIf identity rules, or wants to safely delete or purge folder-level Git identity configuration.
---

# Folder Git Identity

Manage Git `user.name` and `user.email` by workspace folder using Git's `includeIf.gitdir`.

Use scripts when possible:

```text
Windows:      scripts/folder-git-identity.ps1
macOS/Linux:  scripts/folder-git-identity.sh
```

## Non-Negotiable Rules

- Recommend defaults, but require explicit user confirmation before writing, overwriting, or deleting Git config.
- Configure folders, not subjective identity categories. Prefer `.gitconfig-darkingtail` or `.gitconfig-ykc`, not `.gitconfig-personal` or `.gitconfig-company`.
- Only manage the include rule and `[user]` identity fields. Preserve unrelated config.
- Add managed markers to content created or updated by this skill.
- Before deletion, discover references and show the impact.
- Bulk cleanup only selects content marked with `managed-by: folder-git-identity`.

## Commands

PowerShell:

```powershell
.\scripts\folder-git-identity.ps1 list
.\scripts\folder-git-identity.ps1 plan-create -TargetPath D:\dev\darkingtail
.\scripts\folder-git-identity.ps1 create -TargetPath D:\dev\darkingtail -Name darkingtail -Email 1603774836@qq.com
.\scripts\folder-git-identity.ps1 plan-remove -TargetPath D:\dev\darkingtail
.\scripts\folder-git-identity.ps1 remove -TargetPath D:\dev\darkingtail
.\scripts\folder-git-identity.ps1 purge
```

Bash:

```bash
bash scripts/folder-git-identity.sh list
bash scripts/folder-git-identity.sh plan-create --target ~/dev/darkingtail
bash scripts/folder-git-identity.sh create --target ~/dev/darkingtail --name darkingtail --email 1603774836@qq.com
bash scripts/folder-git-identity.sh plan-remove --target ~/dev/darkingtail
bash scripts/folder-git-identity.sh remove --target ~/dev/darkingtail
bash scripts/folder-git-identity.sh purge
```

Use `-Yes` or `--yes` only after the user has explicitly confirmed the shown plan.

## Target Folder Selection

The target folder is the `includeIf.gitdir` path prefix. It usually should be the workspace folder that contains repositories, not one repository itself.

If the current directory is inside a Git repository, run:

```bash
git rev-parse --show-toplevel
```

Then show choices:

```text
Detected repository: D:/dev/darkingtail/skills
Recommended workspace: D:/dev/darkingtail/

Choose target:
- Repository only: D:/dev/darkingtail/skills/
- Workspace folder: D:/dev/darkingtail/
```

Recommend the workspace parent, but let the user decide.

Normalize all target paths before writing:

- absolute path
- forward slashes
- Windows drive letter preserved
- trailing `/`

Example:

```text
D:\dev\darkingtail -> D:/dev/darkingtail/
```

## Config File Naming

Generate config file names from the target folder path:

```text
D:/dev/darkingtail/ -> ~/.gitconfig-darkingtail
D:/dev/ykc/         -> ~/.gitconfig-ykc
```

If the final folder name conflicts, prepend parent folder names until unique:

```text
D:/work/client-a/app     -> ~/.gitconfig-client-a-app
D:/personal/client-a/app -> ~/.gitconfig-personal-client-a-app
```

Use drive letters only as the final disambiguation:

```text
D:/dev/foo/backend -> ~/.gitconfig-dev-foo-backend
E:/dev/foo/backend -> ~/.gitconfig-E-dev-foo-backend
```

## Create Flow

1. Confirm the target folder and affected scope.
2. Ask the user for `user.name` and `user.email`.
3. Run `plan-create`.
4. If the config file exists, show current `[user]` values and target values.
5. If the include rule exists, show whether it points to the intended config file.
6. After confirmation, run `create`.
7. Verify from a repository under the target folder:

```bash
git config --show-origin user.name
git config --show-origin user.email
git remote -v
```

## Delete Flow

Prefer deletion by target folder.

1. Run `plan-remove`.
2. Show the include rule, referenced config file, managed marker status, and other references.
3. Ask whether to delete only the include rule or also delete the config file.
4. Run `remove` after confirmation.
5. Do not delete an unmarked config file or a config file still referenced by other rules unless the user explicitly confirms.

## Purge Flow

Use `purge` only when the user wants to stop using this setup broadly.

The script must:

- select only include blocks marked `managed-by: folder-git-identity`
- show referenced config files
- show unmarked related config separately
- ask for confirmation before deleting anything

## Markers

Global include block:

```ini
# managed-by: folder-git-identity
# managed-action: created-include
[includeIf "gitdir:D:/dev/darkingtail/"]
    path = ~/.gitconfig-darkingtail
# end-managed-by: folder-git-identity
```

Managed `[user]` block:

```ini
# folder-git-identity: managed user section
[user]
    name = darkingtail
    email = 1603774836@qq.com
# folder-git-identity: end managed user section
```
