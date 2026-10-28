import fs from 'node:fs';
import {spawnSync} from 'node:child_process';
// Stdin only. Never save input, echo commands, or include credentials in argv.
const credentials=JSON.parse(fs.readFileSync(0,'utf8'));
if(!credentials.email||!credentials.password)throw Error('Credentials must be supplied through protected stdin');
const source=fs.readFileSync(new URL('./remote_ui.py',import.meta.url),'utf8');
const r=spawnSync('docker',['exec','-i','prospector-frontend-sprint-browser-1','python','-c',source],{input:JSON.stringify(credentials),encoding:'utf8',timeout:240000});
let output=(r.stdout||'').replaceAll(credentials.email,'[REDACTED]').replaceAll(credentials.password,'[REDACTED]');
try{
 const report=JSON.parse(output);report.date=new Date().toISOString();
 fs.writeFileSync('codex/evidencias/remote-ui.json',JSON.stringify(report,null,2)+'\n');
 console.log(JSON.stringify({cases:report.cases,httpRequests:report.http.length},null,2));
 if(report.cases.some(c=>c.status!=='PASS'))process.exitCode=1;
}catch{
 console.log('BLOCKED: remote browser runner did not return a sanitized report');
 process.exitCode=1;
}
if(r.status!==0)process.exitCode=1;
