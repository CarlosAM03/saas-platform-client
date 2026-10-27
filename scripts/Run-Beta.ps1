param(
  [Parameter(Mandatory = $true)]
  [uri]$BackendUrl,
  [int]$WebPort = 4200
)
$ErrorActionPreference = 'Stop'
if ($BackendUrl.Scheme -notin @('http', 'https') -or -not $BackendUrl.Host) {
  throw 'Usa la URL HTTP/HTTPS del servidor.'
}
if ($BackendUrl.AbsolutePath -ne '/' -or $BackendUrl.Query -or $BackendUrl.Fragment -or $BackendUrl.UserInfo) {
  throw 'Usa solamente el origen del servidor, por ejemplo https://api.empresa.com, sin /api/v1 ni /api/docs.'
}
$betaRoot = Split-Path -Parent $PSScriptRoot
$betaEdge = 'C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe'
$betaChrome = 'C:\Program Files\Google\Chrome\Application\chrome.exe'
if (-not $env:CHROME_EXECUTABLE) {
  if (Test-Path -LiteralPath $betaChrome) { $env:CHROME_EXECUTABLE = $betaChrome }
  elseif (Test-Path -LiteralPath $betaEdge) { $env:CHROME_EXECUTABLE = $betaEdge }
}
Push-Location $betaRoot
try {
  flutter pub get
  if ($LASTEXITCODE -ne 0) { throw 'No se pudieron preparar las dependencias.' }
  dart run build_runner build --delete-conflicting-outputs
  if ($LASTEXITCODE -ne 0) { throw 'No se pudieron generar los modelos de autenticación.' }
  $betaOrigin = $BackendUrl.GetLeftPart([System.UriPartial]::Authority)
  flutter run -d chrome "--web-port=$WebPort" "--dart-define=API_BASE_URL=$betaOrigin"
  if ($LASTEXITCODE -ne 0) { throw 'Flutter no pudo iniciar la beta.' }
}
finally { Pop-Location }
