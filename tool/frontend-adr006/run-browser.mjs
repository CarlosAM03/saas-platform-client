import fs from 'node:fs';
import {spawnSync, execFileSync} from 'node:child_process';
const browser=execFileSync('docker',['ps','-q','--filter','label=com.docker.compose.project=prospector-frontend-g1','--filter','label=com.docker.compose.service=browser'],{encoding:'utf8'}).trim();
if(!browser || browser.includes('\n'))throw Error('Expected exactly one frontend G1 browser');
for(let i=0;i<40;i++){
  const health=execFileSync('docker',['inspect','--format','{{.State.Health.Status}}',browser],{encoding:'utf8'}).trim();
  if(health==='healthy')break;
  if(i===39)throw Error('Dedicated browser health timeout');
  await new Promise(resolve=>setTimeout(resolve,1000));
}
const r=spawnSync('docker',['exec','-i',browser,'python','-c',"import sys,urllib.request;print(urllib.request.urlopen(urllib.request.Request('http://127.0.0.1:6090',data=sys.stdin.buffer.read()),timeout=300).read().decode())"],{input:JSON.stringify({action:'browserAudit'}),encoding:'utf8',timeout:320000});
if(r.status!==0)throw Error('Browser audit runner failed; inspect isolated container health');
const response=JSON.parse(r.stdout);
if(!response.ok)throw Error('Browser audit could not execute');
const report={date:new Date().toISOString(),frontendSha:execFileSync('git',['rev-parse','HEAD'],{encoding:'utf8'}).trim(),workingTree:true,browser:'Chromium / Playwright in dedicated Docker laboratory',...response.data};
fs.writeFileSync('codex/frontend-adr006/evidencias/browser-qa.json',JSON.stringify(report,null,2)+'\n');
for(const test of report.cases)console.log(test.caseId+' '+test.status+(test.errorType?' '+test.errorType:''));
if(report.cases.some(test=>test.status!=='PASS'))process.exitCode=1;
