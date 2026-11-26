param([switch]$EnableRealBrevo,[switch]$ConfirmVerifiedSender,[switch]$ConfirmFreeQuota,[switch]$ConfirmSingleManualSend)
$ErrorActionPreference='Stop'
if(-not $EnableRealBrevo){Write-Output 'PILOT_DISABLED';exit 0}
if(-not($ConfirmVerifiedSender -and $ConfirmFreeQuota -and $ConfirmSingleManualSend)){throw 'Owner sender/domain, free quota and single manual send confirmations are required'}
$frontend=(Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$state=Join-Path $frontend 'codex/frontend-adr006/.local'
$manifestPath=Join-Path $frontend 'codex/frontend-adr006/evidencias/release-manifest.json'
if(-not(Test-Path -LiteralPath $manifestPath)){throw 'Verified release manifest is required before any pilot setup'}
$manifest=Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
if($manifest.gates.E2E_LOCAL_CONJUNTO -ne 'PASS' -or $manifest.gates.READY_FOR_OWNER_EMAIL_PILOT -ne 'PASS'){throw 'Synthetic acceptance gates must pass first'}
if($manifest.uiOrigin -ne 'https://localhost:18643'){throw 'Pilot must use the verified loopback frontend'}
foreach($artifact in @('main.dart.js','flutter_bootstrap.js')){
 $actual=(Get-FileHash -LiteralPath (Join-Path $frontend ('build/web/'+$artifact)) -Algorithm SHA256).Hash.ToLowerInvariant()
 if($actual -ne $manifest.artifactHashes.$artifact){throw 'Served frontend artifact differs from verified candidate'}
}
if((Get-Content -LiteralPath (Join-Path $state 'backend-sha.txt') -Raw).Trim() -ne $manifest.backendSha){throw 'Backend candidate mismatch'}
& git -C $frontend diff --quiet $manifest.frontendAppSha -- lib web assets pubspec.yaml pubspec.lock
if($LASTEXITCODE -ne 0){throw 'Application differs from the tested candidate'}
$dbVersion=& docker exec prospector-frontend-g1-db-1 psql -X -Atq -U saas_local -d avance2_core -c "SELECT current_database()||':'||current_setting('server_version_num')::int/10000;"
if($LASTEXITCODE -ne 0 -or $dbVersion -ne 'avance2_core:16'){throw 'Expected disposable local PostgreSQL16 is unavailable'}
$apiImage=& docker inspect prospector-frontend-g1-api-1 --format '{{.Config.Image}}'
$revision=& docker image inspect $apiImage --format '{{index .Config.Labels "org.opencontainers.image.revision"}}'
if($revision -ne $manifest.backendSha){throw 'Running Backend image is not the tested candidate'}
$runtimeEnv=(& docker inspect prospector-frontend-g1-api-1 --format '{{json .Config.Env}}')|ConvertFrom-Json
$runtime=@{};foreach($line in $runtimeEnv){$pair=$line.Split('=',2);$runtime[$pair[0]]=$pair[1]}
$databaseTarget=[Uri]$runtime.DATABASE_URL
if($databaseTarget.Scheme -notin @('postgres','postgresql') -or $databaseTarget.Host -ne 'db' -or $databaseTarget.AbsolutePath -ne '/avance2_core' -or $databaseTarget.Port -ne 5432){throw 'Pilot API database must be the disposable local laboratory'}
if($runtime.PLATFORM_ACTIVATION_URL -ne 'https://localhost:18643/#/activate'){throw 'Activation URL differs from verified frontend'}
$runtime=$null;$runtimeEnv=$null
$publicAddress=[Net.Dns]::GetHostAddresses('api.brevo.com')|Where-Object {$_.AddressFamily -eq 'InterNetwork'}|Select-Object -First 1
if(-not $publicAddress){throw 'Public Brevo DNS resolution failed'}
$bytes=$publicAddress.GetAddressBytes()
if($bytes[0] -in @(0,10,127) -or ($bytes[0] -eq 172 -and $bytes[1] -ge 16 -and $bytes[1] -le 31) -or ($bytes[0] -eq 192 -and $bytes[1] -eq 168)){throw 'Brevo must resolve to a public address for this owner-only mode'}
$sender=Read-Host 'Verified Brevo sender (never the institutional recipient)'
if($sender -notmatch '^[^\s@]+@[^\s@]+\.[^\s@]+$'){throw 'Invalid verified sender'}
$key=Read-Host 'Transactional Brevo API key (private local prompt)' -AsSecureString
$keyPointer=[Runtime.InteropServices.Marshal]::SecureStringToBSTR($key)
try{
 $env:OWNER_BREVO_API_KEY=[Runtime.InteropServices.Marshal]::PtrToStringBSTR($keyPointer)
 $env:OWNER_BREVO_FROM_EMAIL=$sender
 $override=@'
services:
  api:
    environment:
      BREVO_API_KEY: ${OWNER_BREVO_API_KEY:?owner key required}
      BREVO_FROM_EMAIL: ${OWNER_BREVO_FROM_EMAIL:?verified sender required}
      PLATFORM_ACTIVATION_URL: https://localhost:18643/#/activate
      TENANT_REGISTRATION_ENABLED: 'true'
      NODE_EXTRA_CA_CERTS: ''
    logging:
      driver: none
    networks:
      default: {}
      owner-pilot-egress: {}
'@
 $override += "`n    extra_hosts: ['api.brevo.com:"+$publicAddress.IPAddressToString+"']`nnetworks:`n  owner-pilot-egress:`n    internal: false`n"
 $overridePath=Join-Path $state 'owner-pilot.override.yml'
 [IO.File]::WriteAllText($overridePath,$override,[Text.UTF8Encoding]::new($false))
 & docker compose -p prospector-frontend-g1 --env-file (Join-Path $state 'core.env') -f (Join-Path $state 'compose.yml') -f $overridePath config --quiet
 if($LASTEXITCODE -ne 0){throw 'Pilot configuration validation failed'}
 & docker compose -p prospector-frontend-g1 --env-file (Join-Path $state 'core.env') -f (Join-Path $state 'compose.yml') -f $overridePath up -d --no-deps --no-build --wait api
 if($LASTEXITCODE -ne 0){throw 'Pilot API startup failed'}
 Write-Output 'OWNER_ACTION_REQUIRED: no email was sent. Enter the institutional recipient yourself in the four-field UI using the confined browser/noVNC. Follow the private pilot guide.'
}finally{
 [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($keyPointer)
 $env:OWNER_BREVO_API_KEY=$null
 $env:OWNER_BREVO_FROM_EMAIL=$null
 $key=$null
}
