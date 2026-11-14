#!/usr/bin/env bash
# Global Claude Code PreToolUse(Bash) hook: EGM drift gate for every git repo.
# Before `git commit`, each documented folder (the nearest README.md above a changed file, repo root included)
# needs docs/egm/drift/<slug>.md newer than its newest change on this branch. Otherwise the commit is denied
# and the agent is told to run the `drift` agent. Reports list divergences only; fixing is separate work.
# Off switch: EGM_DRIFT_GATE=off. Needs git and jq. Works on bash 3.2 (macOS) and Linux.
set -uo pipefail

[ "${EGM_DRIFT_GATE:-on}" = "off" ] && exit 0
input=$(cat)
cmd=$(jq -r '.tool_input.command // ""' <<<"$input" 2>/dev/null) || exit 0
# Ignore heredoc bodies: text that only mentions a commit must not trip the gate.
# shortcut: everything after the first `<<` line is skipped, so a real commit placed after a heredoc is missed.
cmd=$(awk '{print} /<</{exit}' <<<"$cmd")
# Commits only; also matches `rtk git commit`, `git -C dir commit` and `git -c k=v commit`.
grep -Eq '(^|[;&|[:space:]])git([[:space:]]+(-[cC][[:space:]]+[^[:space:]]+|-[^[:space:]]+))*[[:space:]]+commit([[:space:]]|$)' <<<"$cmd" || exit 0

cwd=$(jq -r '.cwd // empty' <<<"$input")
[ -n "$cwd" ] && cd "$cwd" 2>/dev/null
# shortcut: follows only a leading `cd DIR &&` or `git -C DIR`; other ways of changing directory check the session cwd.
target=$(sed -nE 's/.*git[[:space:]]+-C[[:space:]]+"?([^"[:space:]]+)"?.*/\1/p' <<<"$cmd")
[ -z "$target" ] && target=$(sed -nE 's/^[[:space:]]*cd[[:space:]]+"?([^";&]+[^";&[:space:]])"?[[:space:]]*&&.*/\1/p' <<<"$cmd")
target="${target/#\~/$HOME}"
[ -n "$target" ] && cd "$target" 2>/dev/null
root=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0
cd "$root" || exit 0

mtime() { stat -c %Y "$1" 2>/dev/null || stat -f %m "$1"; }

base=""
def=$(git symbolic-ref -q --short refs/remotes/origin/HEAD 2>/dev/null | sed 's#^origin/##')
for b in "$def" main master; do
  [ -n "$b" ] && git rev-parse -q --verify "$b^{commit}" >/dev/null && { base=$(git merge-base HEAD "$b" 2>/dev/null); break; }
done
[ -z "$base" ] && base=$(git rev-parse -q --verify HEAD 2>/dev/null)

# Changed on this branch: committed, staged, unstaged or new. Deleted files are skipped (no mtime).
changed=$( { [ -n "$base" ] && git diff --name-only --diff-filter=d "$base"; git diff --name-only --cached --diff-filter=d; \
  git ls-files --others --exclude-standard; } | grep -vE '^docs/egm/|(^|/)README\.md$' | sort -u)
[ -z "$changed" ] && exit 0

# One "unit<TAB>mtime" line per changed file; unit = nearest folder with a README.md ("." = repo root).
pairs=""; uncovered=0
while IFS= read -r f; do
  [ -f "$f" ] || continue
  d=$(dirname "$f")
  while [ "$d" != "." ] && [ ! -f "$d/README.md" ]; do d=$(dirname "$d"); done
  if [ "$d" = "." ] && [ ! -f README.md ]; then uncovered=$((uncovered + 1)); continue; fi
  pairs="$pairs$d	$(mtime "$f")
"
done <<<"$changed"

stale=()
while IFS='	' read -r unit newest; do
  [ -z "$unit" ] && continue
  slug=$([ "$unit" = "." ] && echo _root || echo "${unit//\//__}")
  report="docs/egm/drift/$slug.md"
  if [ ! -f "$report" ] || [ "$(mtime "$report")" -lt "$newest" ]; then stale+=("$unit -> $report"); fi
done < <(printf '%s' "$pairs" | sort -t '	' -k1,1 -k2,2nr | awk -F '\t' '!seen[$1]++')

if [ ${#stale[@]} -eq 0 ]; then
  [ "$uncovered" -gt 0 ] && jq -n --arg c "EGM: $uncovered changed file(s) have no README.md above them, so drift is not checked for them. Suggest the egm-bootstrap skill to document that code." \
    '{hookSpecificOutput: {hookEventName: "PreToolUse", additionalContext: $c}}'
  exit 0
fi

list=$(printf -- '- %s\n' "${stale[@]}")
reason="EGM drift check needed before this commit. Code changed in these documented folders without a fresh drift report (folder -> report):
$list
For each, spawn ONE fresh \`drift\` subagent (no conversation context) on that folder's README.md. It reports ONLY divergences, each with README line and code file:line, tagged [stale-not-built]|[missing]|[contract]|[undocumented]|[wording], and overwrites the report (\"No drift detected.\" when clean). Do not fix the README or code. Then add new items to docs/egm/DRIFT_BACKLOG.md, stage docs/egm with the commit, retry it, and mention the counts in your final message. Skip with EGM_DRIFT_GATE=off only if the user says so."
jq -n --arg r "$reason" '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "deny", permissionDecisionReason: $r}}'
