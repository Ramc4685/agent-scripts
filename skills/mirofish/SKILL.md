---
name: mirofish
description: "MiroFish multi-agent simulation: predict how users, markets, or the public react to a launch, policy, or scenario."
---

# MiroFish — swarm simulation for "what happens if…"

MiroFish (`666ghj/MiroFish`, ~77k stars, AGPL-3.0) turns seed material into a knowledge graph, spawns hundreds–thousands of LLM agents with personas and memory, runs them in a simulated social platform (OASIS engine), then writes a prediction report you can interrogate. It does not read or write code. Use it for product and decision questions that sit next to the code.

## When to reach for it

Good fits:
- Predict user/customer reaction to a feature, pricing change, rename, or announcement before shipping.
- Rehearse public/PR reaction to a release note, policy, incident post-mortem, or comms draft.
- Explore stakeholder dynamics: parents/teachers/students for an edtech rollout, buyers/sellers for a marketplace change.
- Scenario "what ifs" from a report, spec, or story (novel endings, market moves) when the user asks for a forecast.

Not a fit: code review, debugging, tests, architecture, anything with a deterministic answer. Don't run it for trivia or when a quick opinion suffices.

## Rules

- Suggest it when a task matches; **ask before running**. A run burns many LLM tokens (README: start under 40 rounds) and sends the seed material to the configured LLM + Zep Cloud. No private/customer data without explicit approval of content + destination.
- Output is a simulation, not evidence. Present it as one signal, with its assumptions; never as fact.
- Never write, echo, or ask for API key values. The user fills `.env` themselves.

## Setup (once per machine)

Install location: `~/Projects/MiroFish`. Check first: `test -d ~/Projects/MiroFish && echo installed`.

Prereqs: Node 18+, Python 3.11–3.12, `uv`.

```bash
git clone https://github.com/666ghj/MiroFish ~/Projects/MiroFish
cd ~/Projects/MiroFish && cp .env.example .env
npm run setup:all
```

`.env` needs (user fills in): `LLM_API_KEY`, `LLM_BASE_URL`, `LLM_MODEL_NAME` (any OpenAI-compatible endpoint), `ZEP_API_KEY` (Zep Cloud free tier is enough for small runs). Fully local alternative: `nikmcfly/MiroFish-Offline` (Neo4j + Ollama, no cloud keys).

Docker instead: `cp .env.example .env && docker compose up -d`.

## Run

- Start: `cd ~/Projects/MiroFish && npm run dev` as a harness-tracked background task (never `&`).
- UI: http://localhost:3000 · API: http://localhost:5001
- Flow in UI: upload seed docs (spec, PRD, release note, survey, news) → describe the prediction question in plain language → graph build → environment/persona setup → simulation → report → chat with any agent or the ReportAgent.

## API (scripted runs)

Blueprints: `/api/graph`, `/api/simulation`, `/api/report`. Pipeline order:

1. `POST /api/graph/ontology/generate` (upload seed + requirement) → `POST /api/graph/build` → poll `GET /api/graph/task/<task_id>`
2. `POST /api/simulation/create` → `POST /api/simulation/prepare` → poll `POST /api/simulation/prepare/status` → `POST /api/simulation/start`
3. `POST /api/report/generate` → poll `POST /api/report/generate/status` → `GET /api/report/<report_id>` (or `/download`)
4. Follow-ups: `POST /api/report/chat`

Request bodies change between versions: read the route in `backend/app/api/{graph,simulation,report}.py` before scripting a call.

## Writing seed + question

- Seed: the real artifact (spec, changelog, landing copy) plus who the audience is. Strip secrets and personal data.
- Question: one concrete outcome. "How will teachers react to auto-grading in week 1? Main objections, adoption rate, who champions it" beats "what will happen?".
- Keep rounds low first; rerun with variables injected ("price drops to $X") to compare.

## Handoff

Summarize: question, seed used, rounds/agents, key predicted reactions, surprises, confidence caveats, link/path to the full report.
