# agent-lab plan

Goal: build skills in agent systems, evals, and custom/private LLMs (fine-tuning + serving), demonstrated by working projects with real eval numbers.

Pace: ~8–10 hrs/week. Two tracks run in parallel for the first ~6 weeks.

## Track A — Fundamentals (weeks 1–6, a few hrs/week)

- [ ] Python fluency for ML (uv, typing, dataclasses, pytest)
- [ ] PyTorch basics: tensors, autograd, a training loop, GPU usage
- [ ] Karpathy "Neural Networks: Zero to Hero" (at least through building GPT)
- [ ] Read: how transformers, tokenization, attention and KV cache work

## Track B — Build modules

Each module: build it, add an eval, record the result in `modules/NN-name/RESULTS.md`.

### Phase 1 — Applied LLM + agents (TypeScript)

- [ ] **00 Setup** — compose stack starts in one command; GPU visible in a container (`nvidia-smi`); API keys + spending caps set. *Check: `docker compose up` works; GPU test passes.*
- [ ] **01 API fundamentals** — same task on Claude and OpenAI behind one provider interface; streaming; structured JSON outputs validated with Zod. *Eval: schema-valid output rate over 30 synthetic inputs.*
- [ ] **02 Tool calling** — agent calls the mock enterprise API (look up case, check availability). *Eval: correct tool + arguments rate.*
- [ ] **03 RAG** — pgvector Q&A over public policy documents with citations; chunking + hybrid search. *Eval: retrieval hit rate, citation accuracy.*
- [ ] **04 Evals** — golden dataset, LLM-as-judge, CI gate that fails on regression; scores in Langfuse. *Eval: tracked over time.*
- [ ] **05 MCP** — MCP server over the mock API; use it from Claude Code and from an agent SDK. *Eval: module 02 evals pass through MCP.*
- [ ] **06 Agent SDKs** — multi-step agent (Claude Agent SDK; compare OpenAI Agents SDK): subagents, sessions/state, permissions, hooks. *Eval: task completion rate.*
- [ ] **07 Guardrails + human-in-the-loop** — approval queue in the UI for write actions; PII redaction; prompt-injection test suite. *Eval: attack-suite pass rate.*
- [ ] **08 Observability + cost** — tracing, cost per task, prompt caching, model routing. *Eval: cost per task before/after.*

### Phase 2 — Models (Python, on the 3090)

- [ ] **09 Local inference** — Ollama/llama.cpp, then vLLM serving an OpenAI-compatible endpoint; quantization (GGUF / AWQ / GPTQ). *Eval: tokens/sec and quality vs. full precision on a fixed eval set.*
- [ ] **10 Plug local model into the agent** — agent-runtime gets a third provider: your vLLM endpoint. *Eval: module 01–02 evals on local vs. Claude/OpenAI.*
- [ ] **11 Fine-tuning (SFT with QLoRA)** — build a synthetic dataset for a narrow task (e.g. extracting structured fields from incident narratives); train a 7–8B model with TRL/Unsloth. *Eval: base vs. fine-tuned vs. Claude on held-out set.*
- [ ] **12 Preference tuning + distillation** — DPO on preference pairs; distill from a larger open-weight teacher (not Claude/OpenAI). *Eval: win rate vs. the SFT model.*
- [ ] **13 Serve the fine-tuned model** — LoRA adapter served with vLLM; latency/throughput benchmarks.

### Phase 3 — Ship it

- [ ] **14 Durable orchestration** — queue-based workflow (Redis/BullMQ) with retries and resume. *Check: survives killing a container mid-run.*
- [ ] **15 Cloud** — deploy one service to AWS (Bedrock + ECS/Lambda) with Terraform and GitHub Actions. *Check: deploys on git push.*
- [ ] **16 Capstone** — private, fine-tuned small model for a regulated use case, running on own hardware, inside an agent with guardrails + human review; write-up comparing cost / accuracy / privacy against the Claude API; demo video. *Deliverable: public README + eval report.*

### Optional — Edge / physical AI

- [ ] Vision model + small LLM on a Jetson or Pi, connected to a camera or robotic-arm project.

## Certifications (optional, after the lab)

- AWS Certified Generative AI Developer – Professional (AIP-C01): $300, 180 min, Bedrock/RAG/agents/guardrails. Consider after Phase 1 + module 15.
- Claude certifications: only available to people at Claude Partner Network organizations (free for firms to join). Ask the contracting firm whether it will join. Free Anthropic Academy courses are open to everyone.

## Monthly check

- [ ] Review 10–20 current postings (agents + fine-tuning); note recurring skills I'm missing and adjust this plan.
