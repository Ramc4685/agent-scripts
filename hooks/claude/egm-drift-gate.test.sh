#!/usr/bin/env bash
# Self-test for egm-drift-gate.sh in a throwaway repo. Usage: hooks/claude/egm-drift-gate.test.sh
set -euo pipefail
gate="$(cd "$(dirname "$0")" && pwd)/egm-drift-gate.sh"
repo=$(mktemp -d)
trap 'rm -rf "$repo"' EXIT
cd "$repo"
git init -q -b main && git config user.email t@t && git config user.name t
echo root > README.md && mkdir -p api/users web && echo api > api/README.md
echo x > web/app.js && echo y > api/users/u.py && git add -A && git commit -qm init
git checkout -qb feature

run() { jq -n --arg c "$1" --arg d "$repo" '{tool_input: {command: $c}, cwd: $d}' | bash "$gate"; }
fail() { echo "FAIL: $1"; exit 1; }

[ -z "$(run 'ls')" ] || fail "non-commit command produced output"
[ -z "$(run 'git commit -m x')" ] || fail "nothing changed on branch, yet denied"

sleep 1; echo z >> api/users/u.py; echo w >> web/app.js
out=$(run 'rtk git commit -m x')
grep -q '"deny"' <<<"$out" || fail "stale folders not denied"
grep -q '"deny"' <<<"$(run 'git -c user.name=t --no-pager commit -m x')" || fail "git -c option form not matched"
[ -z "$(run 'git log --oneline')" ] || fail "non-commit git command matched"
[ -z "$(run "$(printf 'cat <<EOF\nthen git commit -m x\nEOF')")" ] || fail "heredoc body mentioning a commit matched"
grep -q '"deny"' <<<"$(run "$(printf 'git commit -F - <<EOF\nmsg\nEOF')")" || fail "commit with heredoc message not matched"
grep -q 'api -> docs/egm/drift/api.md' <<<"$out" || fail "nested file not mapped to nearest README folder"
grep -q '\. -> docs/egm/drift/_root.md' <<<"$out" || fail "root README unit missing"

mkdir -p docs/egm/drift && sleep 1 && echo ok > docs/egm/drift/api.md && echo ok > docs/egm/drift/_root.md
[ -z "$(run "cd $repo && git commit -m x")" ] || fail "fresh reports still denied"
# `cd ~/...` must resolve to the same repo: from a stale cwd, a tilde path to the fresh repo is allowed.
home_repo=$(mktemp -d "$HOME/.egm-gate-test.XXXXXX"); trap 'rm -rf "$repo" "$home_repo"' EXIT
cp -R "$repo/." "$home_repo"; touch "$home_repo"/docs/egm/drift/*.md
out_tilde=$(jq -n --arg c "cd ~/${home_repo#$HOME/} && git commit -m x" --arg d "/" '{tool_input: {command: $c}, cwd: $d}' | bash "$gate")
[ -z "$out_tilde" ] || fail "cd ~/path not expanded"

sleep 1; echo v >> api/users/u.py
grep -q 'api -> ' <<<"$(run 'git commit -m x')" || fail "report older than new change not denied"
[ -z "$(EGM_DRIFT_GATE=off run 'git commit -m x')" ] || fail "off switch ignored"

rm README.md docs/egm/drift/_root.md; git rm -q --cached README.md
sleep 1; echo u >> web/app.js; echo ok > docs/egm/drift/api.md
grep -q 'egm-bootstrap' <<<"$(run 'git commit -m x')" || fail "uncovered files not reported"
echo "egm-drift-gate: all checks passed"
