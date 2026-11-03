# Module 00 — Setup: results

Date: 2026-11-02 · Machine: desktop (Windows 11 Home, WSL2, Docker Desktop 29.9.2, NVIDIA driver 616.92)

Check: `powershell -File modules/00-setup/check.ps1`

| Check | Result |
|---|---|
| `docker compose up -d --wait` (postgres + redis healthy) | PASS |
| pgvector 0.8.7: `'[1,2,3]'::vector <-> '[1,2,4]'::vector` = 1 | PASS |
| Redis 8.8 `PING` with password | PASS |
| `docker compose --profile gpu run --rm gpu-check` → RTX 3090, 24576 MiB, CUDA 13.4 | PASS |

Still open before ticking 00 in `docs/PLAN.md`: Anthropic + OpenAI API keys in `.env`, spending caps set in both consoles.

## Notes

- On Windows, the NVIDIA Container Toolkit ships inside Docker Desktop (WSL2 backend) — no separate install; never install a Linux NVIDIA driver inside WSL.
- Postgres 18 images mount the volume at `/var/lib/postgresql`, not `.../data`.
- Windows PowerShell 5.1 strips embedded `"` from native-exe arguments — pipe SQL to `psql` via stdin instead of `-c "..."`.
- Docker Desktop error "initializing Inference manager ... dockerInference": stale socket file in `%LOCALAPPDATA%\Docker\run`; updating Docker Desktop fixed it.
