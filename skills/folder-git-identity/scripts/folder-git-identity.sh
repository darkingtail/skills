#!/usr/bin/env bash
set -euo pipefail

ACTION="${1:-list}"
shift || true

TARGET=""
NAME=""
EMAIL=""
YES=0
DELETE_CONFIG=0
GLOBAL_CONFIG="${GLOBAL_CONFIG:-$HOME/.gitconfig}"

SKILL_MARKER="managed-by: folder-git-identity"
END_MARKER="end-managed-by: folder-git-identity"
USER_START_MARKER="folder-git-identity: managed user section"
USER_END_MARKER="folder-git-identity: end managed user section"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target) TARGET="$2"; shift 2 ;;
    --name) NAME="$2"; shift 2 ;;
    --email) EMAIL="$2"; shift 2 ;;
    --global-config) GLOBAL_CONFIG="$2"; shift 2 ;;
    --yes) YES=1; shift ;;
    --delete-config) DELETE_CONFIG=1; shift ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

normalize_git_path() {
  local p="$1"
  case "$p" in
    "~"*) p="$HOME${p#\~}" ;;
  esac
  if [[ -e "$p" ]]; then
    p="$(cd "$p" && pwd -P)"
  else
    local dir base
    dir="$(dirname "$p")"
    base="$(basename "$p")"
    if [[ -d "$dir" ]]; then
      p="$(cd "$dir" && pwd -P)/$base"
    else
      p="$(pwd -P)/$p"
    fi
  fi
  p="${p//\\//}"
  [[ "$p" == */ ]] || p="$p/"
  printf '%s\n' "$p"
}

home_path() {
  local p="$1"
  case "$p" in
    "~/"*) printf '%s\n' "$HOME/${p#~/}" ;;
    *) printf '%s\n' "$p" ;;
  esac
}

list_rules() {
  [[ -f "$GLOBAL_CONFIG" ]] || return 0
  awk -v marker="$SKILL_MARKER" '
    /^[[:space:]]*#.*managed-by: folder-git-identity/ { managed_next=1 }
    /^[[:space:]]*\[includeIf "gitdir:/ || /^[[:space:]]*\[includeIf "gitdir:[A-Za-z]:/ {
      line=$0
      sub(/^[^:]+:/, "", line)
      sub(/"\].*$/, "", line)
      gitdir=line
      managed=managed_next
      managed_next=0
      path=""
      while ((getline nextline) > 0) {
        if (nextline ~ /^[[:space:]]*path[[:space:]]*=/) {
          path=nextline
          sub(/^[[:space:]]*path[[:space:]]*=[[:space:]]*/, "", path)
          gsub(/[[:space:]]+$/, "", path)
          break
        }
        if (nextline ~ /^[[:space:]]*\[/) { break }
      }
      print gitdir "\t" path "\t" managed
    }
  ' "$GLOBAL_CONFIG"
}

config_file_name() {
  local gitdir="$1"
  local clean="${gitdir%/}"
  IFS='/' read -r -a parts <<< "$clean"
  local filtered=()
  local part
  for part in "${parts[@]}"; do
    [[ -n "$part" ]] && filtered+=("$part")
  done
  local count total start candidate name used
  total="${#filtered[@]}"
  for ((count=1; count<=total; count++)); do
    start=$((total-count))
    name=""
    for ((i=start; i<total; i++)); do
      part="${filtered[$i]//:/}"
      [[ -z "$name" ]] && name="$part" || name="$name-$part"
    done
    candidate="~/.gitconfig-$name"
    used=0
    while IFS=$'\t' read -r rule_dir rule_path rule_managed; do
      if [[ "$rule_path" == "$candidate" && "$rule_dir" != "$gitdir" ]]; then
        used=1
      fi
    done < <(list_rules)
    if [[ "$used" -eq 0 ]]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done
  name="$(IFS=-; echo "${filtered[*]}")"
  name="${name//:/}"
  printf '~/.gitconfig-%s\n' "$name"
}

get_user_value() {
  local cfg
  cfg="$(home_path "$1")"
  local key="$2"
  [[ -f "$cfg" ]] || return 0
  git config --file "$cfg" "user.$key" 2>/dev/null || true
}

set_managed_user_section() {
  local cfg user_name user_email actual tmp
  cfg="$1"
  user_name="$2"
  user_email="$3"
  actual="$(home_path "$cfg")"
  mkdir -p "$(dirname "$actual")"
  tmp="$(mktemp)"

  if [[ ! -f "$actual" ]]; then
    {
      echo "# $SKILL_MARKER"
      echo "# managed-action: created-file"
      echo "# $USER_START_MARKER"
      echo "[user]"
      echo "    name = $user_name"
      echo "    email = $user_email"
      echo "# $USER_END_MARKER"
    } > "$actual"
    return 0
  fi

  awk -v start_marker="$USER_START_MARKER" \
      -v end_marker="$USER_END_MARKER" \
      -v user_name="$user_name" \
      -v user_email="$user_email" '
    BEGIN { in_user=0; replaced=0 }
    function print_header() {
      print "# " start_marker
      print "[user]"
      print "    name = " user_name
      print "    email = " user_email
      replaced=1
    }
    function close_user() {
      if (in_user) {
        print "# " end_marker
        in_user=0
      }
    }
    /^[[:space:]]*#.*folder-git-identity: managed user section/ { next }
    /^[[:space:]]*#.*folder-git-identity: end managed user section/ { next }
    /^[[:space:]]*\[user\][[:space:]]*$/ {
      close_user()
      print_header()
      in_user=1
      next
    }
    in_user && /^[[:space:]]*\[/ { close_user(); print; next }
    in_user && /^[[:space:]]*(name|email)[[:space:]]*=/ { next }
    in_user { print; next }
    !in_user { print }
    END {
      close_user()
      if (!replaced) {
        print ""
        print_header()
        close_user()
      }
    }
  ' "$actual" > "$tmp"
  mv "$tmp" "$actual"
}

add_include() {
  local gitdir="$1"
  local cfg="$2"
  mkdir -p "$(dirname "$GLOBAL_CONFIG")"
  touch "$GLOBAL_CONFIG"
  while IFS=$'\t' read -r rule_dir rule_path rule_managed; do
    if [[ "$rule_dir" == "$gitdir" && "$rule_path" == "$cfg" ]]; then
      return 0
    fi
    if [[ "$rule_dir" == "$gitdir" && "$rule_path" != "$cfg" ]]; then
      echo "Include rule already exists for $gitdir and points to $rule_path." >&2
      exit 1
    fi
  done < <(list_rules)
  {
    echo ""
    echo "# $SKILL_MARKER"
    echo "# managed-action: created-include"
    echo "[includeIf \"gitdir:$gitdir\"]"
    echo "    path = $cfg"
    echo "# $END_MARKER"
  } >> "$GLOBAL_CONFIG"
}

remove_include() {
  local gitdir="$1"
  local tmp
  tmp="$(mktemp)"
  awk -v gitdir="$gitdir" -v marker="$SKILL_MARKER" -v end_marker="$END_MARKER" '
    BEGIN { skip=0; pre1=""; pre2="" }
    {
      line=$0
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", line)
      expected="[includeIf \"gitdir:" gitdir "\"]"
      if (line == expected) {
        if (pre2 !~ marker) { print pre2 }
        skip=1
        pre1=""
        pre2=""
        next
      }
      if (skip) {
        if ($0 ~ end_marker) { skip=0; next }
        if ($0 ~ /^[[:space:]]*\[/) { skip=0 }
        else { next }
      }
      if (pre2 != "") { print pre2 }
      pre2=pre1
      pre1=$0
    }
    END {
      if (pre2 != "") print pre2
      if (pre1 != "") print pre1
    }
  ' "$GLOBAL_CONFIG" > "$tmp"
  mv "$tmp" "$GLOBAL_CONFIG"
}

confirm_step() {
  local message="$1"
  [[ "$YES" -eq 1 ]] && return 0
  printf '%s Type YES to continue: ' "$message"
  read -r answer
  [[ "$answer" == "YES" ]]
}

show_create_plan() {
  local gitdir="$1"
  local cfg="$2"
  local actual
  actual="$(home_path "$cfg")"
  echo "Target folder: $gitdir"
  echo "Config file:   $cfg ($actual)"
  if [[ -f "$actual" ]]; then
    echo "Config exists: true"
    echo "Current user.name:  $(get_user_value "$cfg" name)"
    echo "Current user.email: $(get_user_value "$cfg" email)"
  else
    echo "Config exists: false"
  fi
  [[ -n "$NAME" ]] && echo "Target user.name:   $NAME"
  [[ -n "$EMAIL" ]] && echo "Target user.email:  $EMAIL"
  local found=0
  while IFS=$'\t' read -r rule_dir rule_path rule_managed; do
    if [[ "$rule_dir" == "$gitdir" ]]; then
      echo "Include rule: $rule_dir -> $rule_path managed=$rule_managed"
      found=1
    fi
  done < <(list_rules)
  [[ "$found" -eq 0 ]] && echo "Include rule: missing"
}

self_test() {
  local tmp old_home old_global target gitdir cfg
  tmp="$(mktemp -d)"
  old_global="$GLOBAL_CONFIG"
  GLOBAL_CONFIG="$tmp/.gitconfig"
  target="$tmp/dev/darkingtail"
  mkdir -p "$target"
  gitdir="$(normalize_git_path "$target")"
  [[ "$gitdir" == */ ]] || { echo "normalize failed" >&2; exit 1; }
  cfg="$(config_file_name "$gitdir")"
  [[ "$cfg" == "~/.gitconfig-darkingtail" ]] || { echo "name failed: $cfg" >&2; exit 1; }
  cfg="$tmp/.gitconfig-darkingtail"
  set_managed_user_section "$cfg" "darkingtail" "a@example.com"
  [[ "$(get_user_value "$cfg" name)" == "darkingtail" ]] || { echo "user.name failed" >&2; exit 1; }
  [[ "$(get_user_value "$cfg" email)" == "a@example.com" ]] || { echo "user.email failed" >&2; exit 1; }
  existing="$tmp/.gitconfig-existing"
  {
    echo "[user]"
    echo "    name = old"
    echo "    email = old@example.com"
    echo "    signingkey = ABC123"
    echo "[core]"
    echo "    editor = vim"
  } > "$existing"
  set_managed_user_section "$existing" "new" "new@example.com"
  grep -F "signingkey = ABC123" "$existing" >/dev/null || { echo "preserve signingkey failed" >&2; exit 1; }
  grep -F "editor = vim" "$existing" >/dev/null || { echo "preserve core failed" >&2; exit 1; }
  [[ "$(get_user_value "$existing" name)" == "new" ]] || { echo "update existing name failed" >&2; exit 1; }
  [[ "$(get_user_value "$existing" email)" == "new@example.com" ]] || { echo "update existing email failed" >&2; exit 1; }
  add_include "$gitdir" "~/.gitconfig-darkingtail"
  list_rules | grep -F "$gitdir" | grep -F "~/.gitconfig-darkingtail" >/dev/null
  remove_include "$gitdir"
  if list_rules | grep -F "$gitdir" >/dev/null; then
    echo "remove failed" >&2
    exit 1
  fi
  GLOBAL_CONFIG="$old_global"
  rm -rf "$tmp"
  echo "self-test passed"
}

case "$ACTION" in
  self-test)
    self_test
    ;;
  list)
    if ! list_rules | awk 'BEGIN{found=0} {found=1; print "GitDir: "$1"\nPath: "$2"\nManaged: "$3"\n"} END{exit found?0:1}'; then
      echo "No includeIf.gitdir rules found."
    fi
    ;;
  plan-create|create|plan-remove|remove)
    [[ -n "$TARGET" ]] || { echo "--target is required for $ACTION" >&2; exit 1; }
    GITDIR="$(normalize_git_path "$TARGET")"
    CONFIG_PATH="$(config_file_name "$GITDIR")"
    case "$ACTION" in
      plan-create)
        show_create_plan "$GITDIR" "$CONFIG_PATH"
        ;;
      create)
        [[ -n "$NAME" && -n "$EMAIL" ]] || { echo "--name and --email are required for create" >&2; exit 1; }
        show_create_plan "$GITDIR" "$CONFIG_PATH"
        confirm_step "Create or update this folder Git identity?" || exit 1
        set_managed_user_section "$CONFIG_PATH" "$NAME" "$EMAIL"
        add_include "$GITDIR" "$CONFIG_PATH"
        echo "Configured $GITDIR -> $CONFIG_PATH"
        ;;
      plan-remove)
        found=0
        while IFS=$'\t' read -r rule_dir rule_path rule_managed; do
          if [[ "$rule_dir" == "$GITDIR" ]]; then
            echo "Target folder: $GITDIR"
            echo "Include rule:  $rule_dir -> $rule_path"
            echo "Managed:       $rule_managed"
            found=1
          fi
        done < <(list_rules)
        [[ "$found" -eq 1 ]] || echo "No include rule found for $GITDIR"
        ;;
      remove)
        show=0
        while IFS=$'\t' read -r rule_dir rule_path rule_managed; do
          if [[ "$rule_dir" == "$GITDIR" ]]; then
            echo "Will remove include rule: $rule_dir -> $rule_path"
            CONFIG_PATH="$rule_path"
            show=1
          fi
        done < <(list_rules)
        [[ "$show" -eq 1 ]] || { echo "No include rule found for $GITDIR"; exit 0; }
        confirm_step "Remove this include rule?" || exit 1
        remove_include "$GITDIR"
        if [[ "$DELETE_CONFIG" -eq 1 ]]; then
          actual="$(home_path "$CONFIG_PATH")"
          if [[ -f "$actual" ]] && confirm_step "Delete config file $actual?"; then
            rm "$actual"
          fi
        fi
        echo "Removed include rule for $GITDIR"
        ;;
    esac
    ;;
  purge)
    managed_count=0
    while IFS=$'\t' read -r rule_dir rule_path rule_managed; do
      if [[ "$rule_managed" == "1" ]]; then
        echo "$rule_dir -> $rule_path"
        managed_count=$((managed_count + 1))
      fi
    done < <(list_rules)
    [[ "$managed_count" -gt 0 ]] || { echo "No managed include rules found."; exit 0; }
    confirm_step "Remove all managed include rules listed above?" || exit 1
    while IFS=$'\t' read -r rule_dir rule_path rule_managed; do
      [[ "$rule_managed" == "1" ]] && remove_include "$rule_dir"
    done < <(list_rules)
    echo "Removed managed include rules."
    ;;
  *)
    echo "Unknown action: $ACTION" >&2
    exit 1
    ;;
esac
