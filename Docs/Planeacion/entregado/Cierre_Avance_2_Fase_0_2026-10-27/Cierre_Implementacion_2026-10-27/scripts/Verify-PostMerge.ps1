param(
 [Parameter(Mandatory=$true)][string]$FrontendUrl,
 [string]$ApiBaseUrl='https://saas-platform-backend-l55n.onrender.com',
 [string]$ExpectedBackendDevSha='09593bb715cd83270821d34126a4344c8ef97cb0',
 [string]$ExpectedFlutterDevSha='cd527ef12bc7c1327ed9a8520e1a07f0fc8be39f',
 [string]$ExpectedBundleSha256,
 [switch]$AuthenticatedSmoke,
 [string]$OutputPath=(Join-Path $PSScriptRoot '../evidencias/post-merge-verification.json')
)
$ErrorActionPreference='Stop'
foreach($u in @($FrontendUrl,$ApiBaseUrl)){if(([uri]$u).Scheme -ne 'https'){throw 'Public verification requires HTTPS'}}
$authLines=('protocol=https'+[char]10+'host=github.com'+[char]10+[char]10) | & git credential fill
if($LASTEXITCODE -ne 0){throw 'GitHub read credential unavailable'}
$credential=@{};foreach($line in $authLines){if($line -match '^([^=]+)=(.*)$'){$credential[$Matches[1]]=$Matches[2]}}
$ghHeaders=@{Authorization=('Bearer '+$credential.password);Accept='application/vnd.github+json';'X-GitHub-Api-Version'='2022-11-28'}
function Get-Gh([string]$Path){Invoke-RestMethod -Uri ('https://api.github.com/repos/CarlosAM03/'+$Path) -Headers $ghHeaders -Method Get}
$report=[ordered]@{date=(Get-Date).ToUniversalTime().ToString('o');mode='READ ONLY; NO SEEDS OR CONFIGURATION CHANGES';repositories=@();http=@();limitations=@()}
try {
foreach($r in @(@{name='saas-platform-backend';expected=$ExpectedBackendDevSha;checks=@('quality','postgres-integration','docker-build')},@{name='saas-platform-client';expected=$ExpectedFlutterDevSha;checks=@('foundation','container','production-container')})){
 $branch=Get-Gh ($r.name+'/branches/main');$actual=$branch.commit.sha
 $expectedCommit=Get-Gh ($r.name+'/git/commits/'+$r.expected)
 $actualCommit=Get-Gh ($r.name+'/git/commits/'+$actual)
 $treeMatches=$expectedCommit.tree.sha -eq $actualCommit.tree.sha
 $checks=Get-Gh ($r.name+'/commits/'+$actual+'/check-runs?per_page=100')
 $missing=@();foreach($checkName in $r.checks){$matching=@($checks.check_runs | Where-Object {$_.name -eq $checkName -and $_.conclusion -eq 'success'});if(-not $matching.Count){$missing+=$checkName}}
 $runs=Get-Gh ($r.name+'/actions/runs?head_sha='+$actual)
 $deployments=Get-Gh ($r.name+'/deployments?sha='+$actual)
 $deploymentsInfo=@();foreach($deployment in $deployments){$statuses=Get-Gh ($r.name+'/deployments/'+$deployment.id+'/statuses');$last=$statuses | Select-Object -First 1;$deploymentsInfo+=@{id=$deployment.id;environment=$deployment.environment;state=$last.state;url=$last.environment_url;logUrl=$last.log_url}}
 $statuses=Get-Gh ($r.name+'/commits/'+$actual+'/status')
 $report.repositories+=@{name=$r.name;expectedCandidate=$r.expected;main=$actual;treeMatches=$treeMatches;missingSuccessfulChecks=$missing;workflowRuns=@($runs.workflow_runs|Select-Object id,head_sha,status,conclusion,html_url);deployments=$deploymentsInfo;commitStatuses=@($statuses.statuses|Select-Object context,state,target_url)}
 if(-not $treeMatches){$report.limitations+=($r.name+': main does not match candidate tree; no deployment attestation')}
 if($missing.Count){$report.limitations+=($r.name+': exact main HEAD checks pending or failed')}
 if(-not $deploymentsInfo.Count){$report.limitations+=($r.name+': provider deployment ID/SHA requires read-only Render/Vercel attestation; health is insufficient')}
}
foreach($path in @('/api/v1/health/live','/api/v1/health/ready','/api/docs','/api/docs-json')){$response=Invoke-WebRequest -Uri ($ApiBaseUrl.TrimEnd('/')+$path) -Method Get;$report.http+=@{url=$response.BaseResponse.RequestMessage.RequestUri.AbsoluteUri;status=[int]$response.StatusCode};if($path -eq '/api/docs-json'){if(($response.Content|ConvertFrom-Json).info.version -ne '1.0.0'){throw 'Swagger version mismatch'}}}
$frontend=Invoke-WebRequest -Uri $FrontendUrl -Method Get
$bundle=Invoke-WebRequest -Uri ($FrontendUrl.TrimEnd('/')+'/main.dart.js') -Method Get
$report.http+=@{url=$FrontendUrl;status=[int]$frontend.StatusCode;bundleStatus=[int]$bundle.StatusCode}
[byte[]]$bundleBytes=$bundle.RawContentStream.ToArray()
$bundleText=[Text.Encoding]::UTF8.GetString($bundleBytes)
if($bundleText -match 'https?://(localhost|127\.0\.0\.1)([:/])'){throw 'Loopback URL in public bundle'}
if($ExpectedBundleSha256){$actualHash=[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($bundleBytes)).ToLowerInvariant();$report.bundle=@{sha256=$actualHash;expected=$ExpectedBundleSha256;matches=($actualHash -eq $ExpectedBundleSha256)};if($actualHash -ne $ExpectedBundleSha256){$report.limitations+='Public bundle differs from local candidate; inspect provider build provenance/configuration'}}
$origin=([uri]$FrontendUrl).GetLeftPart([UriPartial]::Authority)
$cors=Invoke-WebRequest -Uri ($ApiBaseUrl.TrimEnd('/')+'/api/v1/campaigns') -Method Options -Headers @{Origin=$origin;'Access-Control-Request-Method'='GET';'Access-Control-Request-Headers'='authorization'}
$report.cors=@{origin=$origin;status=[int]$cors.StatusCode;allowed=($cors.Headers['Access-Control-Allow-Origin'] -contains $origin)}
if(-not $report.cors.allowed){$report.limitations+='Production CORS not verified for the actual frontend origin'}
if($AuthenticatedSmoke){$secure=Read-Host 'JWT privado productivo autorizado (no usar credenciales demo)' -AsSecureString;$pointer=[Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure);try{$token=[Runtime.InteropServices.Marshal]::PtrToStringBSTR($pointer);foreach($path in @('/auth/me','/campaigns','/prospects','/prospecting-jobs')){$v=Invoke-RestMethod -Method Get -Uri ($ApiBaseUrl.TrimEnd('/')+'/api/v1'+$path) -Headers @{Authorization=('Bearer '+$token)};$report.http+=@{method='GET';path=$path;success=$v.success}}}finally{$token=$null;[Runtime.InteropServices.Marshal]::ZeroFreeBSTR($pointer)}}else{$report.limitations+='Authenticated production smoke NOT RUN'}
}
catch { $report.error=$_.Exception.Message; $report.limitations+='Verification interrupted by a read-only endpoint failure; inspect error' }
$report.verdict=if($report.limitations.Count){'VALIDADO CON LIMITACIONES / REVISAR PENDIENTES'}else{'READ-ONLY CHECKS PASS; owner must confirm provider revision'}
$report | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $OutputPath
$ghHeaders.Clear();$credential.Clear();Write-Host ('Evidence: '+$OutputPath);Write-Host $report.verdict
