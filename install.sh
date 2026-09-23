#!/usr/bin/env bash
# Install the omarchy-plugin-publish skill into your coding agents.
#
# All four supported agents read the same SKILL.md format, so this copies one
# skill directory into each agent's skill path.
#
#   ./install.sh                     install for every agent detected on this machine
#   ./install.sh --agent claude      install for one agent (claude|codex|opencode|cursor)
#   ./install.sh --all               install for all four, whether detected or not
#   ./install.sh --project [DIR]     install into a repo instead of your home directory
#   ./install.sh --link              symlink instead of copy (for developing this skill)
#   ./install.sh --uninstall         remove it from every location it was installed to
#   ./install.sh --list              show target paths and what is currently installed
#
# Nothing outside the listed skill directories is touched.

set -euo pipefail

SKILL="omarchy-plugin-publish"
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$REPO/skills/$SKILL"

AGENTS=(claude codex opencode cursor)
MODE=install
SELECT=""
ALL=0
LINK=0
FORCE=0
PROJECT=""

die() { echo "install: $*" >&2; exit 1; }

while [ $# -gt 0 ]; do
  case "$1" in
    --agent) SELECT="${2:-}"; [ -n "$SELECT" ] || die "--agent needs a value"; shift 2 ;;
    --all) ALL=1; shift ;;
    --link) LINK=1; shift ;;
    --force) FORCE=1; shift ;;
    --uninstall) MODE=uninstall; shift ;;
    --list) MODE=list; shift ;;
    --project)
      if [ -n "${2:-}" ] && [ "${2#-}" = "$2" ]; then PROJECT="$2"; shift 2; else PROJECT="$PWD"; shift; fi ;;
    -h|--help) sed -n '2,18p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) die "unknown option: $1" ;;
  esac
done

[ -f "$SRC/SKILL.md" ] || die "skills/$SKILL/SKILL.md not found under $REPO."

if [ -n "$PROJECT" ]; then
  [ -d "$PROJECT" ] || die "not a directory: $PROJECT"
  PROJECT="$(cd "$PROJECT" && pwd)"
fi

# Verified skill paths per agent (see README.md for sources).
target_dir() {
  local agent="$1"
  if [ -n "$PROJECT" ]; then
    case "$agent" in
      claude)   echo "$PROJECT/.claude/skills" ;;
      codex)    echo "$PROJECT/.agents/skills" ;;
      opencode) echo "$PROJECT/.opencode/skills" ;;
      cursor)   echo "$PROJECT/.cursor/skills" ;;
    esac
  else
    case "$agent" in
      claude)   echo "$HOME/.claude/skills" ;;
      codex)    echo "$HOME/.agents/skills" ;;
      opencode) echo "$HOME/.config/opencode/skills" ;;
      cursor)   echo "$HOME/.cursor/skills" ;;
    esac
  fi
}

detected() {
  case "$1" in
    claude)   command -v claude   >/dev/null 2>&1 || [ -d "$HOME/.claude" ] ;;
    codex)    command -v codex    >/dev/null 2>&1 || [ -d "$HOME/.codex" ] || [ -d "$HOME/.agents" ] ;;
    opencode) command -v opencode >/dev/null 2>&1 || [ -d "$HOME/.config/opencode" ] ;;
    cursor)   command -v cursor   >/dev/null 2>&1 || [ -d "$HOME/.cursor" ] ;;
  esac
}

# Which agents to act on.
CHOSEN=()
if [ -n "$SELECT" ]; then
  case " ${AGENTS[*]} " in
    *" $SELECT "*) CHOSEN=("$SELECT") ;;
    *) die "unknown agent \"$SELECT\". Choose from: ${AGENTS[*]}" ;;
  esac
elif [ "$ALL" -eq 1 ] || [ -n "$PROJECT" ] || [ "$MODE" != "install" ]; then
  CHOSEN=("${AGENTS[@]}")
else
  for a in "${AGENTS[@]}"; do detected "$a" && CHOSEN+=("$a"); done
  if [ "${#CHOSEN[@]}" -eq 0 ]; then
    echo "No supported agent detected on this machine."
    echo "Use --all to install anyway, or --agent <${AGENTS[*]// /|}>."
    exit 1
  fi
fi

if [ "$MODE" = "list" ]; then
  echo "Skill: $SKILL"
  echo "Source: $SRC"
  [ -n "$PROJECT" ] && echo "Scope: project ($PROJECT)" || echo "Scope: user (\$HOME)"
  echo
  printf '%-10s %-8s %-9s %s\n' AGENT PRESENT INSTALLED PATH
  for a in "${AGENTS[@]}"; do
    d="$(target_dir "$a")/$SKILL"
    p=no; detected "$a" && p=yes
    i=no; [ -e "$d" ] && i=yes; [ -L "$d" ] && i=link
    printf '%-10s %-8s %-9s %s\n' "$a" "$p" "$i" "$d"
  done
  exit 0
fi

if [ "$MODE" = "uninstall" ]; then
  removed=0
  for a in "${CHOSEN[@]}"; do
    d="$(target_dir "$a")/$SKILL"
    if [ -e "$d" ] || [ -L "$d" ]; then
      # Only ever removes the skill's own directory.
      rm -rf -- "$d"
      echo "removed  $a  $d"
      removed=$((removed + 1))
    fi
  done
  if [ "$removed" -eq 0 ]; then
    echo "Nothing to remove."
  else
    echo
    echo "Removed from $removed location(s)."
  fi
  exit 0
fi

echo "Installing $SKILL for: ${CHOSEN[*]}"
[ -n "$PROJECT" ] && echo "Scope: project ($PROJECT)"
echo

for a in "${CHOSEN[@]}"; do
  base="$(target_dir "$a")"
  dest="$base/$SKILL"

  if { [ -e "$dest" ] || [ -L "$dest" ]; } && [ "$FORCE" -eq 0 ] && [ -t 0 ]; then
    printf 'replace existing %s? [y/N] ' "$dest"
    read -r reply </dev/tty || reply=n
    case "$reply" in [yY]*) ;; *) echo "skipped   $a"; continue ;; esac
  fi

  mkdir -p "$base"
  rm -rf -- "$dest"

  if [ "$LINK" -eq 1 ]; then
    ln -s "$SRC" "$dest"
    echo "linked    $a  $dest -> $SRC"
  else
    mkdir -p "$dest"
    cp -R "$SRC/." "$dest/"
    [ -f "$dest/scripts/readiness-check.sh" ] && chmod +x "$dest/scripts/readiness-check.sh"
    echo "installed $a  $dest"
  fi
done

cat <<EOF

Done. Start a new agent session so the skill is discovered, then ask:

  "Check whether my Omarchy plugin at ~/code/my-plugin is ready to publish."

Claude Code and opencode load it by description; in Codex type \$ to pick it,
in Cursor @-mention it. A readiness pass alone needs no network:

  $SRC/scripts/readiness-check.sh /path/to/plugin

Run './install.sh --list' to see where it landed, '--uninstall' to remove it.
EOF
