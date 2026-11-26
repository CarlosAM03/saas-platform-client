$ErrorActionPreference='Stop'
$frontend=(Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$state=Join-Path $frontend 'codex/frontend-cp/.local'
docker compose -p andre-sprint-cp --env-file (Join-Path $state 'lab.env') -f (Join-Path $state 'compose.yml') down
if($LASTEXITCODE -ne 0){throw 'Cannot stop the synthetic laboratory'}
# PostgreSQL lives in tmpfs: removing this project's DB container discards only its synthetic data.
