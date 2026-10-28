param([Parameter(Mandatory=$true)][string]$StatePath)
$ErrorActionPreference='Stop'
$settings=@{}
foreach($line in Get-Content -LiteralPath (Join-Path $StatePath 'core.env')){
 $i=$line.IndexOf('=');if($i -gt 0){$settings[$line.Substring(0,$i)]=$line.Substring($i+1)}
}
$container=(& docker ps -q --filter label=com.docker.compose.project=prospector-frontend-sprint --filter label=com.docker.compose.service=db).Trim()
if(-not $container){throw 'Dedicated sprint DB is not running'}
$output=& flutter test tool/platform_api_p2c_test.dart --reporter expanded --dart-define=P2C_BASE_URL=http://127.0.0.1:18541 ("--dart-define=P2C_DB_CONTAINER="+$container) ("--dart-define=P2C_PASSWORD="+$settings.LOCAL_DEMO_PASSWORD) 2>&1
$code=$LASTEXITCODE
$clean=($output -join "`n").Replace($settings.LOCAL_DEMO_PASSWORD,'[REDACTED]')
[IO.File]::WriteAllText((Join-Path (Get-Location).Path 'codex/evidencias/p2c-results.log'),$clean,[Text.UTF8Encoding]::new($false))
Write-Host $clean
exit $code
