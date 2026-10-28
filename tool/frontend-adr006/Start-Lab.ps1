param(
 [Parameter(Mandatory=$true)][string]$BackendPath,
 [string]$BackendSha='5e214420394101ae7079f8e844cc759b01cce2a3'
)
$ErrorActionPreference='Stop'
$frontend=(Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$state=Join-Path $frontend 'codex/frontend-adr006/.local'
$project='prospector-frontend-g1'
function Run-Docker { & docker.exe @args; if($LASTEXITCODE -ne 0){throw 'Laboratory Docker command failed'} }
New-Item -ItemType Directory -Force -Path $state | Out-Null
$snapshot=Join-Path $state ('backend-'+$BackendSha.Substring(0,12))
if(-not(Test-Path -LiteralPath $snapshot)){
 $archive=Join-Path $state 'backend-source.zip'
 & git -C $BackendPath archive --format=zip --output $archive $BackendSha
 if($LASTEXITCODE -ne 0){throw 'Cannot export the verified Backend commit'}
 Expand-Archive -LiteralPath $archive -DestinationPath $snapshot
}
$envFile=Join-Path $state 'core.env'
if(-not(Test-Path -LiteralPath $envFile)){
 function Secret { [Convert]::ToHexString([Security.Cryptography.RandomNumberGenerator]::GetBytes(32)).ToLowerInvariant() }
 [IO.File]::WriteAllLines($envFile,@(('LOCAL_DB_PASSWORD='+(Secret)),('LOCAL_DEMO_PASSWORD='+(Secret)),('LOCAL_JWT_SECRET='+(Secret)),('LOCAL_EVIDENCE_DIR='+$state.Replace('\','/'))),[Text.UTF8Encoding]::new($false))
}
foreach($volume in @($project+'_core-pg',$project+'_core-tls')){
 $names=& docker volume ls --format '{{.Name}}'
 if($names -contains $volume){
  $labels=(& docker volume inspect --format '{{json .Labels}}' $volume | ConvertFrom-Json)
  if($labels.'prospector.owner' -ne 'frontend-g1-exclusive' -or $labels.'com.docker.compose.project' -ne $project){throw 'Volume ownership mismatch'}
 }
}
$ops=Join-Path $snapshot 'ops/avance2'
$compose=[IO.File]::ReadAllText((Join-Path $ops 'compose.core.yml'))
$compose=$compose.Replace('prospector-avance2-core',$project).Replace('avance2-core-exclusive','frontend-g1-exclusive').Replace('prospector-avance2-backend:core','prospector-frontend-g1-backend:'+ $BackendSha.Substring(0,7)).Replace('prospector-avance2-flutter:core-local','nginx:1.28.0-alpine').Replace('55447','55647').Replace('18441','18641').Replace('18443','18643').Replace('18450','18650')
$compose=$compose.Replace("environment: { PORT: '80' }",("volumes: ['"+(Join-Path $frontend 'build/web').Replace('\','/')+":/usr/share/nginx/html:ro']"))
$registration=@'
      JWT_EXPIRES_IN: 8h
      TENANT_REGISTRATION_ENABLED: 'true'
      PLATFORM_ACTIVATION_URL: https://localhost:18643/#/activate
      SMTP_HOST: mail
      SMTP_PORT: '2465'
      SMTP_USER: laboratory
      SMTP_PASSWORD: ${LOCAL_JWT_SECRET}
      SMTP_FROM: laboratory@example.invalid
      SMTP_TLS_MODE: implicit
      BREVO_API_KEY: ${LOCAL_JWT_SECRET}
      BREVO_FROM_EMAIL: laboratory@example.invalid
      NODE_EXTRA_CA_CERTS: /certs/ca.crt
'@
$compose=$compose.Replace("      JWT_EXPIRES_IN: 8h",$registration)
$compose=$compose.Replace("    ports: ['127.0.0.1:18641:3000']", "    volumes: ['core-tls:/certs:ro']`n    ports: ['127.0.0.1:18641:3000']")
$compose=$compose.Replace("      init: { condition: service_completed_successfully }","      init: { condition: service_completed_successfully }`n      tls-init: { condition: service_completed_successfully }")
$mail=@'
  mail:
    image: prospector-avance2-browser:trusted-local
    entrypoint: [python, /opt/mailbox.py]
    networks:
      default:
        aliases: [api.brevo.com]
    volumes: ['./mailbox.py:/opt/mailbox.py:ro', 'core-tls:/certs:ro']
    depends_on:
      tls-init: { condition: service_completed_successfully }
    restart: 'no'
'@
$compose=$compose.Replace("`nvolumes:", "`n"+$mail+"`nvolumes:")
$compose=$compose.Replace("'./browser_agent.py:/opt/browser_agent.py:ro',", "'./browser_agent.py:/opt/browser_agent.py:ro', './browser_qa.py:/opt/browser_qa.py:ro',")
[IO.File]::WriteAllText((Join-Path $state 'compose.yml'),$compose,[Text.UTF8Encoding]::new($false))
foreach($file in @('init-tls.sh','nginx-https.conf','start-browser.sh')){
 $value=[IO.File]::ReadAllText((Join-Path $ops $file)).Replace('18443','18643').Replace('DNS:localhost,IP:127.0.0.1','DNS:localhost,DNS:mail,IP:127.0.0.1')
 if($file -eq 'init-tls.sh'){
  $value += @'

if [ ! -s /certs/provider.crt ]; then
 openssl req -newkey rsa:2048 -nodes -keyout /certs/provider.key -out /certs/provider.csr -subj '/CN=api.brevo.com'
 printf 'subjectAltName=DNS:api.brevo.com
extendedKeyUsage=serverAuth
' > /certs/provider.ext
 openssl x509 -req -in /certs/provider.csr -CA /certs/ca.crt -CAkey /certs/ca.key -CAcreateserial -out /certs/provider.crt -days 30 -extfile /certs/provider.ext
 chmod 644 /certs/provider.crt
 chmod 600 /certs/provider.key
fi
'@
 }
 [IO.File]::WriteAllText((Join-Path $state $file),$value,[Text.UTF8Encoding]::new($false))
}
Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'mailbox.py') -Destination (Join-Path $state 'mailbox.py') -Force
Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'browser_qa.py') -Destination (Join-Path $state 'browser_qa.py') -Force
$agent=[IO.File]::ReadAllText((Join-Path $PSScriptRoot '../sprint/browser_agent.py')).Replace("`r`n","`n").Replace('18543','18643')
$agent=$agent.Replace('from playwright.async_api import async_playwright', "from playwright.async_api import async_playwright`nimport browser_qa")
$agent=$agent.Replace("        if kind=='resetSession':", @'
        if kind=='browserAudit':
            return await browser_qa.audit(ctx)
        elif kind=='openLabActivation':
            await browser_qa.open_activation(page, d['recipient'], secrets)
        elif kind=='resetSession':
'@)
$agent=$agent.Replace("'previewreference')", "'previewreference','activationtoken','firstaccesstoken','newpassword')")
$agent=$agent.Replace("        try:`n            body=await response.json()", "        entry['authorizationPresent']='authorization' in req.headers`n        try:`n            body=await response.json()")
$agent=$agent.Replace("entry['id']=data.get('id');", "entry['action']=data.get('action');entry['id']=data.get('id');")
$agent=$agent.Replace("        try:`n            payload=req.post_data_json", "        entry['requestBodyPresent']=bool(req.post_data_buffer)`n        try:`n            payload=req.post_data_json")
[IO.File]::WriteAllText((Join-Path $state 'browser_agent.py'),$agent,[Text.UTF8Encoding]::new($false))
Run-Docker build --target runtime -f (Join-Path $snapshot 'Dockerfile') --label ('org.opencontainers.image.revision='+$BackendSha) -t ('prospector-frontend-g1-backend:'+$BackendSha.Substring(0,7)) $snapshot
Run-Docker compose -p $project --env-file $envFile -f (Join-Path $state 'compose.yml') config --quiet
Run-Docker compose -p $project --env-file $envFile -f (Join-Path $state 'compose.yml') up -d --no-build --wait --wait-timeout 180 browser mail
Run-Docker compose -p $project --env-file $envFile -f (Join-Path $state 'compose.yml') up -d --force-recreate --no-deps --no-build --wait --wait-timeout 120 browser
[IO.File]::WriteAllText((Join-Path $state 'backend-sha.txt'),$BackendSha)
Write-Host 'Dedicated frontend G1 laboratory ready: HTTPS18643, API18641, PostgreSQL55647.'
