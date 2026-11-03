# Module 00 check: core stack comes up healthy, pgvector works, Redis answers, GPU visible in a container.
# Run from the repo root:  pwsh -File modules/00-setup/check.ps1   (or powershell -File ...)
$ErrorActionPreference = 'Stop'
$fail = 0
function Step($name, [scriptblock]$body) {
  try { & $body; if ($LASTEXITCODE -ne 0) { throw "exit $LASTEXITCODE" }; Write-Host "PASS  $name" -ForegroundColor Green }
  catch { Write-Host "FAIL  $name -> $_" -ForegroundColor Red; $script:fail++ }
}

if (-not (Test-Path .env)) { throw ".env missing - copy .env.example to .env first" }

Step 'compose up (postgres + redis healthy)' { docker compose up -d --wait | Out-Null }
Step 'pgvector extension + distance query' {
  # SQL goes in via stdin: Windows PowerShell 5.1 strips embedded double quotes from native-exe args.
  $out = "SELECT '[1,2,3]'::vector <-> '[1,2,4]'::vector;" | docker compose exec -T postgres sh -c 'psql -U $POSTGRES_USER -d $POSTGRES_DB -tA'
  if ($out.Trim() -ne '1') { throw "unexpected: $out" }
}
Step 'redis ping' {
  $out = docker compose exec -T redis sh -c 'redis-cli -a $REDIS_PASSWORD --no-auth-warning ping'
  if ($out.Trim() -ne 'PONG') { throw "unexpected: $out" }
}
Step 'GPU visible in container (gpu profile)' {
  $out = docker compose --profile gpu run --rm gpu-check nvidia-smi --query-gpu=name,memory.total --format=csv,noheader
  Write-Host "      $out"
  if ($out -notmatch 'RTX 3090') { throw "3090 not found" }
}

if ($fail) { Write-Host "`n$fail check(s) failed" -ForegroundColor Red; exit 1 }
Write-Host "`nModule 00 check passed" -ForegroundColor Green
