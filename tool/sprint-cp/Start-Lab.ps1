param(
  [Parameter(Mandatory=$true)][string]$BackendPath,
  [string]$BackendSha='779fc7885faefdfe9e3cb0f3fee86810d96d2711',
  [switch]$SkipBuild
)
$ErrorActionPreference='Stop'
$frontend=(Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$state=Join-Path $frontend 'codex/frontend-cp/.local'
New-Item -ItemType Directory -Force -Path $state | Out-Null
$snapshot=Join-Path $state ('backend-'+$BackendSha.Substring(0,12))
if(-not(Test-Path -LiteralPath $snapshot)) {
  $archive=Join-Path $state 'source.zip'
  git -C $BackendPath archive --format=zip --output $archive $BackendSha
  if($LASTEXITCODE -ne 0){throw 'Cannot export the pinned backend'}
  Expand-Archive -LiteralPath $archive -DestinationPath $snapshot
}
$envFile=Join-Path $state 'lab.env'
if(-not(Test-Path -LiteralPath $envFile)) {
  function New-LabSecret { [Convert]::ToHexString([Security.Cryptography.RandomNumberGenerator]::GetBytes(32)).ToLowerInvariant() }
  [IO.File]::WriteAllLines($envFile,@(('CP_DB_PASSWORD='+(New-LabSecret)),('CP_SEED_PASSWORD='+(New-LabSecret)),('CP_JWT_SECRET='+(New-LabSecret))),[Text.UTF8Encoding]::new($false))
}
$compose=@'
services:
  db:
    image: postgres:16
    environment:
      POSTGRES_USER: cp_local
      POSTGRES_PASSWORD: ${CP_DB_PASSWORD}
      POSTGRES_DB: cp_synthetic
    tmpfs: ['/var/lib/postgresql/data']
    healthcheck:
      test: [CMD-SHELL, 'pg_isready -U cp_local -d cp_synthetic']
      interval: 2s
      timeout: 3s
      retries: 30
  init:
    image: saas-cp-qa-backend:779fc78
    depends_on:
      db: {condition: service_healthy}
    environment: &api-env
      NODE_ENV: development
      DATABASE_ENV: local
      DATABASE_URL: postgresql://cp_local:${CP_DB_PASSWORD}@db:5432/cp_synthetic
      JWT_SECRET: ${CP_JWT_SECRET}
      JWT_EXPIRES_IN: 8h
      DEV_SEED_PASSWORD: ${CP_SEED_PASSWORD}
      TENANT_REGISTRATION_ENABLED: 'false'
      CORS_ORIGINS: http://localhost:18742,http://127.0.0.1:18742
      PORT: '3000'
    command: [sh, -c, 'npm run prisma:migrate:deploy && npm run prisma:seed:dev']
  api:
    image: saas-cp-qa-backend:779fc78
    networks: [default, ingress]
    depends_on:
      init: {condition: service_completed_successfully}
    environment: *api-env
    command: [sh, -c, 'npm run build && node dist/src/main.js']
    ports: ['127.0.0.1:18741:3000']
    healthcheck:
      test: [CMD, node, -e, "require('http').get('http://127.0.0.1:3000/api/v1/health/ready',r=>process.exit(r.statusCode===200?0:1)).on('error',()=>process.exit(1))"]
      interval: 3s
      timeout: 3s
      retries: 40
      start_period: 30s
networks:
  default: {internal: true}
  ingress: {}
'@
$compose=$compose.Replace('saas-cp-qa-backend:779fc78',('saas-cp-qa-backend:'+$BackendSha.Substring(0,7)))
[IO.File]::WriteAllText((Join-Path $state 'compose.yml'),$compose,[Text.UTF8Encoding]::new($false))
if(-not $SkipBuild) {
  docker build --target development --label ('org.opencontainers.image.revision='+$BackendSha) -t ('saas-cp-qa-backend:'+$BackendSha.Substring(0,7)) $snapshot
  if($LASTEXITCODE -ne 0){throw 'Backend image build failed'}
}
docker compose -p andre-sprint-cp --env-file $envFile -f (Join-Path $state 'compose.yml') up -d --wait --wait-timeout 180 api
if($LASTEXITCODE -ne 0){throw 'Synthetic laboratory did not become ready'}
[IO.File]::WriteAllText((Join-Path $state 'backend-sha.txt'),$BackendSha)
Write-Host 'Synthetic CP laboratory ready on loopback port 18741. No remote services.'
