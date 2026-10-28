param([Parameter(Mandatory=$true)][string]$BackendPath,[string]$StatePath=(Join-Path ([IO.Path]::GetTempPath()) 'prospector-frontend-sprint'),[switch]$SkipBuild,[switch]$CachedToolchain)
$ErrorActionPreference='Stop'
function Invoke-SprintDocker { & docker.exe @args; if($LASTEXITCODE -ne 0){throw 'Docker operation failed; see sanitized build output'} }
$frontend=(Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$backend=(Resolve-Path $BackendPath).Path
$sha=(& git -C $backend rev-parse origin/main).Trim()
if($sha -ne 'b51b265f1a545fa915f1dd1c57ef2f5858ec6492'){throw 'Re-audit changed Backend main before running this baseline'}
$project='prospector-frontend-sprint'
New-Item -ItemType Directory -Force -Path $StatePath | Out-Null
foreach($file in @('init-tls.sh','nginx-https.conf','start-browser.sh')){
 $value=& git -C $backend show ("origin/main:ops/avance2/"+$file)
 if($LASTEXITCODE -ne 0){throw 'Cannot extract verified baseline tooling'}
 if($file -eq 'nginx-https.conf'){$value=($value -join "`n").Replace('18443','18543')}
 [IO.File]::WriteAllText((Join-Path $StatePath $file),($value -join "`n")+"`n",[Text.UTF8Encoding]::new($false))
}
Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'browser_agent.py') -Destination (Join-Path $StatePath 'browser_agent.py') -Force
$compose=(& git -C $backend show origin/main:ops/avance2/compose.core.yml) -join "`n"
$compose=$compose.Replace('prospector-avance2-core',$project).Replace('avance2-core-exclusive','frontend-sprint-exclusive').Replace('prospector-avance2-backend:core','sprint-frontend-core-backend:local').Replace('prospector-avance2-flutter:core-local','sprint-frontend-core-web:local').Replace('55447','55547').Replace('18441','18541').Replace('18443','18543').Replace('18450','18550')
[IO.File]::WriteAllText((Join-Path $StatePath 'compose.yml'),$compose,[Text.UTF8Encoding]::new($false))
# Browser has no build step here: reuse the project's already installed trusted image.
# Its source context is not used when up is invoked with --no-build.
$envFile=Join-Path $StatePath 'core.env'
if(-not(Test-Path -LiteralPath $envFile)){
 function Secret { [Convert]::ToHexString([Security.Cryptography.RandomNumberGenerator]::GetBytes(32)).ToLowerInvariant() }
 $evidence=Join-Path $StatePath 'evidence';New-Item -ItemType Directory -Force -Path $evidence | Out-Null
 [IO.File]::WriteAllLines($envFile,@(('LOCAL_DB_PASSWORD='+(Secret)),('LOCAL_DEMO_PASSWORD='+(Secret)),('LOCAL_JWT_SECRET='+(Secret)),('LOCAL_EVIDENCE_DIR='+$evidence.Replace('\','/'))),[Text.UTF8Encoding]::new($false))
}
foreach($volume in @($project+'_core-pg',$project+'_core-tls')){
 $names=& docker volume ls --format '{{.Name}}'
 if($names -contains $volume){
  $labels=(& docker volume inspect --format '{{json .Labels}}' $volume | ConvertFrom-Json)
  if($labels.'prospector.owner' -ne 'frontend-sprint-exclusive' -or $labels.'com.docker.compose.project' -ne $project){throw 'Volume ownership mismatch'}
 }
}
if(-not $SkipBuild){
 # Export a verified snapshot outside Backend: its working tree may be experimental.
 $snapshot=Join-Path $StatePath ('backend-'+$sha.Substring(0,12))
 $archive=Join-Path $StatePath 'backend-source.zip'
 if(-not(Test-Path -LiteralPath $snapshot)){
  & git -C $backend archive --format=zip --output $archive origin/main
  if($LASTEXITCODE -ne 0){throw 'Cannot export verified Backend main'}
  Expand-Archive -LiteralPath $archive -DestinationPath $snapshot
 }
 Invoke-SprintDocker build --target runtime -f (Join-Path $snapshot 'Dockerfile') --label ('org.opencontainers.image.revision='+$sha) -t sprint-frontend-core-backend:local $snapshot
 & docker.exe image inspect prospector-avance2-browser:trusted-local *> $null
 if($LASTEXITCODE -ne 0){
  Invoke-SprintDocker build -f (Join-Path $snapshot 'ops/avance2/Dockerfile.browser') -t prospector-avance2-browser:trusted-local (Join-Path $snapshot 'ops/avance2')
 }
 $source=& git -C $frontend rev-parse HEAD
 if((& git -C $frontend diff --name-only -- lib pubspec.yaml pubspec.lock web assets Dockerfile.vercel)){throw 'Commit application sources before building evidence'}
 $webDockerfile=if($CachedToolchain){Join-Path $PSScriptRoot 'Dockerfile.e2e'}else{Join-Path $frontend 'Dockerfile.vercel'}
 Invoke-SprintDocker build -f $webDockerfile --build-arg API_BASE_URL=https://localhost:18543 --label ("org.opencontainers.image.revision="+$source.Trim()) -t sprint-frontend-core-web:local $frontend
}
Invoke-SprintDocker compose -p $project --env-file $envFile -f (Join-Path $StatePath 'compose.yml') config --quiet
Invoke-SprintDocker compose -p $project --env-file $envFile -f (Join-Path $StatePath 'compose.yml') up -d --no-build --wait --wait-timeout 180 browser
Write-Host 'PASS: isolated sprint stack; API loopback18541, HTTPS18543, DB55547, noVNC18550. Private config is outside the repository.'
