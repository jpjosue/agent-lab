# Module 00 — Local AI infrastructure: Docker, GPU, data services

**Time:** ~2.5 hrs (reading 60 min · labs 75 min · quiz 15 min)
**Prereqs:** Module 00 check passing (`modules/00-setup/check.ps1`)

## How this lesson works

1. **Learning objectives** — what you'll be able to do at the end.
2. **Study materials** — read these first; each lists *what to look for*.
3. **Directed training** — short concept brief + a hands-on lab on your own stack. Run every command; compare against "What you should see".
4. **Knowledge check** — quick self-test. If you miss one, re-read the linked section.
5. **Quiz** — answer in chat. Graded with feedback; 4/5 to pass.

## 1. Learning objectives

By the end you can:

- **LO1** Explain the path from a container to the RTX 3090 on Windows (container → Docker Desktop → WSL2 → Windows driver), and why there's no Linux driver in WSL.
- **LO2** Use Compose profiles to keep GPU services optional.
- **LO3** Predict when Postgres init scripts run, and reset them safely.
- **LO4** Read a port mapping and say who can reach a service.
- **LO5** Explain where Postgres 18 stores data in the container and what a wrong volume mount does.

## 2. Study materials

| # | Source | Read | Look for | Min |
|---|---|---|---|---|
| R1 | [NVIDIA — CUDA on WSL User Guide](https://docs.nvidia.com/cuda/wsl-user-guide/index.html) | "Getting Started" + the driver warning | Which driver goes where; what `/usr/lib/wsl/lib` is | 15 |
| R2 | [Docker — GPU support in Docker Desktop for Windows](https://docs.docker.com/desktop/features/gpu/) | Whole page (short) | Requirements; the `--gpus all` flag | 5 |
| R3 | [Docker — Using profiles with Compose](https://docs.docker.com/compose/how-tos/profiles/) | Whole page | What happens to a profiled service when no `--profile` is given | 10 |
| R4 | [Docker Hub — official `postgres` image](https://hub.docker.com/_/postgres) | "Initialization scripts", "PGDATA", "Environment Variables" | The one condition under which init scripts run; the 18+ PGDATA change | 15 |
| R5 | [Docker — Port publishing and mapping](https://docs.docker.com/engine/network/port-publishing/) | Whole page | Difference between `5432:5432` and `127.0.0.1:5432:5432` | 10 |
| R6 | [Microsoft — Accessing network applications with WSL](https://learn.microsoft.com/windows/wsl/networking) | "Accessing a WSL 2 distribution from your local area network" | Why LAN access to WSL needs extra steps (optional for this module) | 5 |

## 3. Directed training

Run labs from the repo root in PowerShell, with the stack up (`docker compose up -d --wait`). Windows PowerShell shows anything a tool writes to stderr in red as `NativeCommandError`, even on success, so judge by the message, not the color.

### Lab 1 — Container → GPU path (LO1)

**Concept.** Docker Desktop runs Linux containers inside a WSL2 VM. The Windows NVIDIA driver exposes the GPU to WSL through a paravirtual device (`/dev/dxg`) and maps a stub `libcuda.so` into `/usr/lib/wsl/lib`. The NVIDIA container runtime, bundled with Docker Desktop, injects those libs into any container started with `--gpus`. So the only GPU driver is the Windows one. Installing a Linux NVIDIA driver inside WSL would overwrite that stub and break CUDA.

```powershell
wsl -l -v                                    # 1. which WSL2 distros exist
wsl -d Ubuntu -- ls /usr/lib/wsl/lib         # 2. driver libs from Windows
docker info --format '{{json .Runtimes}}' | Select-String nvidia -Quiet   # 3. nvidia runtime registered?
docker run --rm nvidia/cuda:13.4.3-base-ubuntu24.04 nvidia-smi            # 4. WITHOUT --gpus
docker run --rm --gpus all nvidia/cuda:13.4.3-base-ubuntu24.04 nvidia-smi # 5. WITH --gpus
```

**What you should see.** Step 2 lists `libcuda.so*`. Step 3 prints `True`. Step 4 fails (`exec: "nvidia-smi": executable file not found in $PATH`). Step 5 shows the 3090.
**Think:** steps 4 and 5 use the same image, so where did `nvidia-smi` come from in step 5?

### Lab 2 — Compose profiles (LO2)

**Concept.** A service with `profiles:` is left out of every compose command unless you turn on that profile. Services without a profile always run. This lets one compose file serve both the 3090 desktop and the ThinkPad.

```powershell
docker compose config --services                 # 1. default view
docker compose --profile gpu config --services   # 2. with gpu profile
docker compose up -d --wait; docker compose ps   # 3. is gpu-check running?
docker compose --profile gpu run --rm gpu-check  # 4. one-shot GPU job
```

**What you should see.** Step 1 lists `postgres redis`. Step 2 adds `gpu-check`. Step 3 never shows `gpu-check`.
**Think:** in Module 09 you'll add a long-running `vllm` service. Which profile should it get, and what happens when you run `docker compose up` on the ThinkPad?

### Lab 3 — Init scripts (LO3)

**Concept.** The postgres entrypoint runs `/docker-entrypoint-initdb.d/*` only when the data directory is **empty**, which in practice means the first start of a fresh volume. Restarting the container or editing the SQL file won't re-run it. `docker compose down -v` deletes the volume, so the next start re-initializes everything and **all data is lost**.

```powershell
docker compose logs postgres | Select-String "initdb.d"   # 1. when did it run?
docker compose restart postgres
docker compose logs --since 1m postgres | Select-String "initdb.d"  # 2. after restart
docker volume ls --filter name=agent-lab                  # 3. the volumes holding state
# 4. Full reset. Safe now (no data yet); destructive later:
docker compose down -v; docker compose up -d --wait
docker compose logs postgres | Select-String "initdb.d"
```

**What you should see.** Step 1 shows one `running .../001-extensions.sql` line. Step 2 shows nothing. Step 4 shows it running again.
**Think:** in a real system, how would you apply a new SQL change without wiping data? (Preview of migrations.)

### Lab 4 — Port binding (LO4)

**Concept.** `HOST_IP:HOST_PORT:CONTAINER_PORT`. If you leave out the host IP, Docker binds `0.0.0.0`, meaning every network interface, so anything on the LAN can connect. `127.0.0.1` means only this machine. Containers reach each other by service name (`postgres:5432`) over the compose network, whatever the host binding is.

```powershell
docker compose port postgres 5432                       # 1. effective mapping
netstat -ano | Select-String ":5432 "                   # 2. what Windows is listening on
docker compose exec redis sh -c 'nc -zv postgres 5432'  # 3. container-to-container by name
```

**What you should see.** Steps 1 and 2 show `127.0.0.1:5432`. Step 3 reports the port as open.
**Think:** the ThinkPad needs Postgres. Compare (a) changing the binding to `0.0.0.0` with (b) using an SSH tunnel (`ssh -L 5432:localhost:5432 desktop`). Which fits the "regulated / audit" niche in CLAUDE.md better, and why?

### Lab 5 — Where Postgres 18 keeps data (LO5)

**Concept.** Before v18, the image kept data in `/var/lib/postgresql/data`, and the usual mount pointed there. From v18 on, `PGDATA` is `/var/lib/postgresql/18/docker` (a folder per major version, so `pg_upgrade` can work in place). Mounting a volume at the old `.../data` path means the real data goes into the container's writable layer and disappears when the container is recreated.

```powershell
docker compose exec postgres sh -c 'echo $PGDATA; ls /var/lib/postgresql'  # 1.
docker volume inspect agent-lab_pgdata --format '{{.Mountpoint}}'          # 2.
```

**What you should see.** Step 1 prints `/var/lib/postgresql/18/docker` and then `18`.
**Think:** if the mount were wrong, which command would destroy your data without any warning? (Hint: it isn't `down -v`.)

## 4. Knowledge check (self-graded)

- [ ] I can draw the container → GPU path from memory.
- [ ] I know which compose services start with a plain `docker compose up`.
- [ ] I can say exactly when `/docker-entrypoint-initdb.d` runs.
- [ ] I can tell from a port mapping whether a service is reachable from the LAN.
- [ ] I know where PG18 stores its data and why the mount path matters.

## 5. Quiz (answer in chat)

1. Why don't you need a separate NVIDIA Container Toolkit install on Windows, and what would go wrong if you installed a Linux NVIDIA driver inside WSL?
2. What does `profiles: ["gpu"]` change about `docker compose up`, and why does that matter for the ThinkPad?
3. The init SQL in `db/init` won't run again if you edit it. Why, and how would you force it to re-run?
4. Why are the ports bound to `127.0.0.1`, and what would you change to reach Postgres from the ThinkPad?
5. Postgres 18 images moved the data folder. What breaks if the volume is mounted at `/var/lib/postgresql/data` the way it was in older versions?
