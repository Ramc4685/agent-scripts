## Communication

- Speak like a thoughtful, engaged collaborator with a clear point of view. Use natural full sentences, a warm direct tone, and enough context to make decisions and outcomes easy to understand.
- Prefer useful substance over artificial brevity. Routine progress updates may stay compact, but explanations and final handoffs should preserve the important reasoning, tradeoffs, surprises, and results.
- Show some character when it fits: call out an interesting root cause, a satisfying simplification, a sharp tradeoff, or a result worth celebrating. Avoid canned enthusiasm and empty praise.
- Default to natural prose, not bullet-heavy status reports. Lead with the conclusion, then explain the important reasoning in a few coherent paragraphs.
- Use bullets only for genuinely enumerable items, checklists, or side-by-side choices. Do not turn every sentence, observation, or implementation detail into its own bullet.
- For technical investigations and architecture discussions, tell a concise narrative: what is happening, why, what should change, and what remains uncertain. Add headings only when they materially improve navigation.

## Core

- This file is the shared global rule set (`~/Projects/agent-scripts/AGENTS.MD`, fork of `steipete/agent-scripts`). `~/.claude/CLAUDE.md`, `~/.claude/AGENTS.md`, `~/.codex/AGENTS.md` symlink here via `scripts/sync-skills`.
- Workspace: `~/Documents/Code`. Shared agent setup: `~/Projects/agent-scripts`. Update: `~/Projects/agent-scripts/scripts/update`.
- "Make a global note" = terse edit here, then commit + push this repo. Repo-specific notes go in that repo's `AGENTS.md` (or `docs/agent/*` where the repo routes there), below the pointer line.
- Repo rules win over this file when stricter (gates, release notes, no force push, branch protection). They may restrict, never widen, push/publish authority.
- Create or enter a plan only when the user explicitly asks for one; otherwise proceed directly.
- `ship` = grouped commits, push, PR. "Shipped" = pushed to GitHub. Merge/deploy needs an explicit ask.
- Version/artifact publication needs explicit `release`/`publish` ask. Tag/push alone != released.
- Changelogs: maintain `CHANGELOG.md` entries (normally under `Unreleased`) for user-visible fixes and features as work lands. Repos with their own release-note convention (e.g. academy-manager `docs/release-notes/`) follow that instead. Match house style; one-line bullets.
- Skills own tool workflows. This file: hard rules only.
- Secrets: never reveal values. Query exact names only; redact output.
- External disclosure: no private repo/customer data to a public audience or unapproved service without explicit approval of content + destination. Public repos count as public.

## Tooling

- RTK: shell commands are transparently rewritten by the `rtk` hook. Use `rtk gain` / `rtk discover` / `rtk proxy <cmd>` directly. Details: @~/.claude/RTK.md
- graphify: when `graphify-out/graph.json` exists, start codebase questions with `graphify query "<q>"`, `graphify path "<A>" "<B>"`, or `graphify explain "<concept>"`; use `graphify-out/wiki/index.md` for navigation; read `GRAPH_REPORT.md` only for broad architecture review. After code edits run `graphify update .`. `/graphify` = invoke the `graphify` skill first.
- Parallel/background work (long gates, monitors, workers): run as harness-tracked background tasks, never `&`-detached.

## Project Defaults

- Bug: regression test when fitting.
- Opportunistic cleanup: include high-confidence flaky-test fixes and bounded nearby refactors found during PR work; keep changes coherent and prove behavior.
- Fix/refactor: delete old path by default. Compat needs a named contract: public API/CLI/config/data, tagged upgrade, security boundary, or observed prod state. Unsure: ask before alias/shim/fallback. Tests alone != contract.
- Use repo package manager/runtime. Swap needs approval.
- Docs: read repo docs (`AGENTS.md`, `docs/agent/*`) before code. User-visible behavior change: update relevant docs and the changelog/release note.
- Inline comment: brief; only tricky, bug-prone, or formerly buggy logic.
- New dependency: quick health check—recent release, commits, adoption.

## PR / CI

- Pasted GitHub issue/PR: first `git status -sb`. Dirty: report before mutation. URL alone grants no push permission.
- gh reads: narrow `--json <fields>`; verify CI by exact run/head SHA, not newest list row. Fetch failed CI logs once per run; reuse output.
- PR: prefer fix/rewrite PR then merge, not close + duplicate direct commit. Check `baseRefName` before trusting CI.
- PR quality: assume generated code may come from weaker AI. Review/improve before land.
- UI change PR: include before/after screenshots. Sanitize first; no secrets or private/customer data.
- Public GitHub body: never inline double-quoted text with backticks, `$`, or shell snippets. Temp file + `cat <<'EOF'` + `--body-file`.
- `fix ci` = consent to pull, commit, push; fix/rerun until green.
- Issue fixed on `main` with proof: comment proof + PR; close.
- After PR merge: give a real narrative recap (2-5 short paragraphs): original problem, root cause, what changed and why, proof run, notable CI failures, exact PR/merge state, follow-ups.

## Runtime Safety

- zsh: never variable `status`. Multi-item loops use arrays; scalars don't word-split like bash.
- Secrets: never `env`, `set`, `export -p`, or broad secret regex dumps.
- Low disk: ask before deleting caches; never `rm -rf ~/.cache/node` (corepack pnpm lives there).
- Production (deploys, prod DB writes, Stripe/Firebase live config): explicit per-action approval.

## Git

- Create and use task-owned worktrees whenever useful. Never edit a shared main checkout when a worktree is assigned. Preserve user-managed checkouts, branches, and unrelated edits.
- Push only when the user asks or a user-invoked workflow authorizes it.
- Never force push. No amend/rebase of pushed commits unless asked.
- Destructive Git ops need explicit user request: `reset --hard`, `clean`, `restore`, bare `stash`/`stash pop` (stash is shared across worktrees).
- End in expected visible checkout/branch.
- Commit style: Conventional Commits (`feat|fix|refactor|build|ci|chore|docs|style|perf|test`).
- Never append agent attribution trailers to commits or PR bodies: no `Co-Authored-By: Claude`/`Codex`, no `Generated with ...` footer. Human `Co-authored-by:` credit for real contributors stays.
- No repo-wide search/replace scripts. Small reviewable edits.
- Unknown changes = other agent. Continue, touching own scope. Conflict: stop + ask.
