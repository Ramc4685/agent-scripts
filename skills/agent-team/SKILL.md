---
name: agent-team
description: "Set up a lead-orchestrator agent team in a repo: a lead session that only routes and merges, pinned-model planner, builder, reviewer, risk-reviewer and mechanical agents, a routing doc and a lead handoff file. Use when the user asks to add or port this agent setup to a repository."
---

# Agent team

Installs one lead session plus five pinned subagents into a repository. The lead never writes product code; it
writes briefs, routes work by `docs/dev/agent-roles.md`, and merges reviewed work. Features run as chip sessions
in their own worktrees; reviews, planning and chores run as subagents.

## Install

1. Read the target repo's `CLAUDE.md` / `AGENTS.md`, test commands and riskiest directories first.
2. Copy the templates (do not overwrite existing files without asking):
   - `templates/agents/*.md` → `<repo>/.claude/agents/`
   - `templates/docs/agent-roles.md`, `templates/docs/lead-handoff.md` → `<repo>/docs/dev/`
3. Fill every placeholder from what the repo actually has; never invent a command:

   | Placeholder | Fill with |
   |---|---|
   | `{{PROJECT}}` | the project name |
   | `{{CONVENTIONS_DOC}}` | the doc that holds the repo's hard rules (often `CLAUDE.md` or `AGENTS.md`) |
   | `{{MODULE_TEST_CMD}}`, `{{FULL_SUITE_CMD}}` | the repo's own test commands |
   | `{{CHORE_CMDS}}` | format, codegen and seed commands |
   | `{{REVIEW_CHECKLIST}}` | the 4-8 correctness checks that matter here (e.g. auth checks, tenant isolation, idempotent payments) |
   | `{{RISK_AREAS}}`, `{{RISK_PATHS}}`, `{{RISK_FOCUS}}` | the directories and failure modes where a bug costs money, data or security |
   | `{{MAX_CHIPS}}` | parallel chip sessions the machine can carry (2 on a 16 GB Mac) |

4. Check nothing is left: `grep -rn '{{' .claude/agents docs/dev/agent-roles.md docs/dev/lead-handoff.md` prints nothing.
5. Add one line to the repo's `CLAUDE.md`: "Agent roles and model routing: `docs/dev/agent-roles.md`."
6. Start the lead as a fresh session: "You are the lead. Read `docs/dev/lead-handoff.md` and `docs/dev/agent-roles.md`."

## Keep

- Models stay pinned (`fable` for planner and risk-reviewer, `opus` for builder and reviewer, `haiku` for
  mechanical). Never `inherit`; never route code work to `general-purpose`.
- Repo-specific text lives only in the filled placeholders. If a repo needs more, edit its copy, not the template.

## EGM drift gate (global, already on)

Every repo gets it without install: `hooks/claude/egm-drift-gate.sh` in this repo is registered in
`~/.claude/settings.json`, and the `drift` agent lives in `~/.claude/agents/`. Before `git commit`, each changed
folder (judged by the nearest `README.md`, repo root included) needs a fresh `docs/egm/drift/<folder with / as __>.md`.
Code with no README above it is not checked; run the `egm-bootstrap` skill to document it. Off for one command:
`EGM_DRIFT_GATE=off`. Test: `hooks/claude/egm-drift-gate.test.sh`.

## Optional add-ons

- A push guard that allows only `git push origin <type>/<name>` (Conventional Commits types; never an AI-named prefix).

## Known traps

- A plugin `WorktreeCreate` hook (seen with worktrunk) can break subagent worktree isolation. Chips are
  sessions with their own worktree, so they are unaffected; test `isolation: "worktree"` before relying on it.
- Start-up hooks that say "MUST invoke skills" (superpowers) fight the routing table; the repo's rules win.
