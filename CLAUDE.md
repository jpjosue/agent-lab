# agent-lab — Claude Code context

This is Jon's personal, hands-on AI engineering lab. Read this file and `docs/PLAN.md` at the start of every session.

## Who I am and why this repo exists

- Senior full-stack engineer, ~25 years (Intel 2001–2018, then state-government contracting). Strong in Vue 3, Node.js/Fastify, TypeScript, C#/.NET, Oracle/SQL, Docker, Azure DevOps CI/CD.
- Goal: move from building Node/PWA business apps to **AI engineering work that's closer to the models** — agent systems, evals, and fine-tuning/serving open-weight LLMs — and build real solutions for people.
- Target profile: engineer who combines **agent systems + custom/private models**, with evals as the backbone. Regulated/public-sector use cases (privacy, audit trails, on-prem models) are my niche.

## How to work with me — LEARNING MODE (important)

The point of this repo is for **me** to build skill, not for you to write everything.

- Explain the concept first, briefly, then let me write the core logic of each module (the agent loop, the eval scorer, the training loop, the retrieval code).
- You may freely write boilerplate: Dockerfiles, compose services, config, types, test scaffolding, seed data.
- When I'm stuck, give a hint or point to the relevant doc before writing the solution. If I say "just write it", write it.
- Review my code like a senior reviewer: correctness, cost, failure modes, security.
- After each module, quiz me with 3–5 questions on what I should now understand.
- Prefer official docs (Anthropic, OpenAI, Hugging Face, PyTorch, vLLM). Check current versions of SDKs/libraries before using them — don't rely on memory for APIs that change.

## Hard rules

1. **Synthetic or public data only.** Never put work code, client data, or anything from my day job (NDA) in this repo.
2. **Secrets** live in `.env` (git-ignored). Commit only `.env.example`.
3. **Cost control:** default to the cheapest model that works (e.g. Claude Haiku / small OpenAI models) for development; log token usage per run; never loop API calls without a max-iterations cap.
4. **Training data:** do not use Claude or OpenAI outputs to train/distill models (their terms restrict it). Use open-weight models as teachers.
5. Every module ends with an **eval** — a number I can compare before and after a change.

## Hardware

| Machine | GPU | Role |
|---|---|---|
| Desktop | RTX 3090, 24 GB (Ampere: bf16 + FlashAttention 2, **no FP8**) | GPU server: training, vLLM serving, Docker with NVIDIA Container Toolkit |
| ThinkPad | RTX 5070 Laptop, 8 GB (**Blackwell: needs CUDA 12.8+ and a recent PyTorch build**) | Dev machine, Ollama for small local models, VS Code Remote-SSH to desktop |

Rough 3090 capacity: QLoRA on 7–8B (up to ~14B with care), bf16 LoRA on 1–4B, 4-bit inference up to ~30–32B. 70B needs rented cloud GPUs.

## Stack conventions

- **App/agent services:** TypeScript, Node.js, Fastify, Vue 3 + PrimeVue, Vitest. pnpm.
- **ML work:** Python 3.11+, PyTorch, Hugging Face (transformers, datasets, PEFT, TRL), Unsloth where useful; `uv` for envs. Notebooks allowed for exploration, but final code goes in `.py` modules.
- **Infra:** Docker Compose for everything local; GPU services use a compose profile `gpu`.
- **Data:** Postgres + pgvector, Redis.
- **Observability:** self-hosted Langfuse (traces, cost, eval scores).
- **Providers:** Anthropic (Claude) and OpenAI behind one small provider interface so every lab can run against either.

## Repo layout (target — create as modules are reached)

```
agent-lab/
  CLAUDE.md
  docs/PLAN.md            # roadmap + progress checkboxes
  docker-compose.yml
  .env.example
  services/
    mock-enterprise-api/  # Fastify, synthetic case/scheduling/forms data
    mcp-server/           # MCP server wrapping the mock API
    agent-runtime/        # Fastify, provider switch Claude/OpenAI
    ui/                   # Vue 3: chat, approval queue, traces
  evals/                  # datasets + eval runner
  ml/                     # Python: inference, fine-tuning, DPO
  modules/NN-name/        # per-module notes, exercises, results
```

## Current status

See the checkboxes in `docs/PLAN.md`. Update them (and add a short "results" note with the eval numbers) when a module is finished.
