import fs from 'node:fs';
import crypto from 'node:crypto';
import assert from 'node:assert/strict';
import {spawnSync,execFileSync} from 'node:child_process';
const state=process.argv[2];
if(!state)throw Error('Usage: node tool/sprint/api-negative.mjs PRIVATE_STATE_DIR');
const cfg=Object.fromEntries(fs.readFileSync(state+'/core.env','utf8').trim().split(/\r?\n/).map(l=>[l.slice(0,l.indexOf('=')),l.slice(l.indexOf('=')+1)]));
const runId='negative'+crypto.randomBytes(8).toString('hex');
const base='http://127.0.0.1:18541',project='prospector-frontend-sprint',cases=[],traffic=[];
const docker=(args,input)=>{const r=spawnSync('docker',args,{input,encoding:'utf8',timeout:30000});if(r.status!==0)throw Error('Dedicated PostgreSQL command failed');return r.stdout.trim()};
const db=docker(['ps','-q','--filter','label=com.docker.compose.project='+project,'--filter','label=com.docker.compose.service=db']);
if(!db||db.includes('\n'))throw Error('Expected one dedicated sprint DB');
const sql=query=>docker(['exec','-i',db,'psql','-X','-Atq','-U','saas_local','-d','avance2_core','-v','ON_ERROR_STOP=1'],query);
const q=s=>"'"+s.replaceAll("'","''")+"'";
assert.equal(sql("SELECT current_database()||':'||(current_setting('server_version_num')::int/10000);"),'avance2_core:16');
assert.equal(docker(['volume','inspect','--format','{{index .Labels "prospector.owner"}}',project+'_core-pg']),'frontend-sprint-exclusive');
function checksum(){return ['tenants','roles','users','user_tenants','campaigns','prospects','campaign_prospects','prospecting_jobs'].map(t=>sql("SELECT count(*)||':'||coalesce(md5(string_agg(row_to_json(t)::text,'|' ORDER BY row_to_json(t)::text)),'empty') FROM "+t+" t;")).join('|')}
async function request(method,path,body,token){
 const headers={};if(token)headers.Authorization='Bearer '+token;
 const multipart=body instanceof FormData;
 if(body&&!multipart)headers['Content-Type']='application/json';
 const r=await fetch(base+path,{method,headers,body:body?(multipart?body:JSON.stringify(body)):undefined,signal:AbortSignal.timeout(30000)});
 const response=await r.json();
 traffic.push({method,path,status:r.status,requestId:r.headers.get('x-request-id')});
 return {status:r.status,body:response};
}
async function test(caseId,fn){
 const start=traffic.length;
 try{await fn();cases.push({caseId,scope:'HTTP_SQL',status:'PASS',http:traffic.slice(start),dbAssertions:['Direct SQL verifies no partial or unauthorized writes']});console.log(caseId+' PASS')}
 catch(e){cases.push({caseId,scope:'HTTP_SQL',status:'FAIL',error:e.name+': '+e.message,http:traffic.slice(start)});console.log(caseId+' FAIL')}
}
let campaignId,token,baseline;
const unchanged=before=>assert.equal(sql('SELECT count(*) FROM prospects;'),before);
try{
 baseline=checksum();
 const auth=await request('POST','/api/v1/auth/login',{email:'owner.demo-norte@demo.example',password:cfg.LOCAL_DEMO_PASSWORD});
 assert.equal(auth.status,200);token=auth.body.data.accessToken;
 const claims=JSON.parse(Buffer.from(token.split('.')[1],'base64url'));
 const created=await request('POST','/api/v1/campaigns',{name:runId},token);assert.equal(created.status,201);campaignId=created.body.data.id;
 const csv='name,email\n'+runId+','+runId+'@example.invalid\n';
 const form=(reference,file=csv)=>{
  const f=new FormData();f.append('campaignId',campaignId);f.append('file',new Blob([file],{type:'text/csv'}),'synthetic.csv');
  if(reference){f.append('previewReference',reference);f.append('decisions',JSON.stringify([{record:1,action:'CREATE'}]));}
  return f;
 };
 const preview=await request('POST','/api/v1/prospects/import/preview',form(),token);assert.equal(preview.status,200);
 const reference=preview.body.data.previewReference;
 const before=sql('SELECT count(*) FROM prospects;');
 await test('AUTH-EXPIRED-401',async()=>{
  const header=Buffer.from(JSON.stringify({alg:'HS256',typ:'JWT'})).toString('base64url');
  const payload=Buffer.from(JSON.stringify({...claims,iat:Math.floor(Date.now()/1000)-28860,exp:Math.floor(Date.now()/1000)-60})).toString('base64url');
  const signature=crypto.createHmac('sha256',cfg.LOCAL_JWT_SECRET).update(header+'.'+payload).digest('base64url');
  assert.equal((await request('GET','/api/v1/users',null,header+'.'+payload+'.'+signature)).status,401);
  unchanged(before);
 });
 await test('CSV-EXPIRED-400',async()=>{
  const payload=JSON.parse(Buffer.from(reference.split('.')[0],'base64url'));payload.expiresAt=Date.now()-1;
  const encoded=Buffer.from(JSON.stringify(payload)).toString('base64url');
  const signature=crypto.createHmac('sha256',cfg.LOCAL_JWT_SECRET).update('prospect-csv-preview-v1:').update(encoded).digest('base64url');
  assert.equal((await request('POST','/api/v1/prospects/import/confirm',form(encoded+'.'+signature),token)).status,400);
  unchanged(before);
 });
 await test('CSV-BYTES-MISMATCH-400',async()=>{
  assert.equal((await request('POST','/api/v1/prospects/import/confirm',form(reference,csv+'changed\n'),token)).status,400);unchanged(before);
 });
 await test('CSV-OVERSIZE-413',async()=>{
  assert.equal((await request('POST','/api/v1/prospects/import/preview',form(null,'name\n'+'x'.repeat(5*1024*1024)),token)).status,413);unchanged(before);
 });
 await test('CSV-REPLAY-409',async()=>{
  assert.equal((await request('POST','/api/v1/prospects/import/confirm',form(reference),token)).status,200);
  const count=sql('SELECT count(*) FROM prospects;');assert.equal(Number(count),Number(before)+1);
  assert.equal((await request('POST','/api/v1/prospects/import/confirm',form(reference),token)).status,409);
  unchanged(count);assert.equal(sql('SELECT count(*) FROM campaign_prospects WHERE campaign_id='+q(campaignId)+';'),'1');
 });
 await test('AUTH-RATE-LIMIT-429',async()=>{
  let limited=false;
  for(let i=0;i<6;i++){const r=await request('POST','/api/v1/auth/login',{email:'owner.demo-norte@demo.example',password:cfg.LOCAL_DEMO_PASSWORD});if(r.status===429){limited=true;break}assert.equal(r.status,200)}
  assert(limited,'Expected unchanged five-per-minute authentication limit');
  assert.equal(sql('SELECT count(*) FROM users WHERE email LIKE '+q(runId+'%')+';'),'0');
 });
} catch(e){cases.push({caseId:'NEGATIVE-SETUP',scope:'HTTP_SQL',status:'FAIL',error:e.name+': '+e.message})}
finally{
 let cleanup='NOT RUN';
 if(baseline){try{
  if(campaignId)sql('BEGIN; DELETE FROM campaign_prospects WHERE campaign_id='+q(campaignId)+'; DELETE FROM prospects WHERE campaign_id='+q(campaignId)+'; DELETE FROM campaigns WHERE id='+q(campaignId)+' AND name='+q(runId)+'; COMMIT;');
  assert.equal(checksum(),baseline);cleanup='PASS';
 }catch{cleanup='FAIL'}}
 const runnerSha=execFileSync('git',['rev-parse','HEAD'],{encoding:'utf8'}).trim();
 fs.writeFileSync('codex/evidencias/api-negative.json',JSON.stringify({date:new Date().toISOString(),runId,runnerSha,environment:'local-isolated',scope:'HTTP_SQL complementary; never UI_TO_DB',cleanup,cases},null,2)+'\n');
 console.log(JSON.stringify({pass:cases.filter(c=>c.status==='PASS').length,fail:cases.filter(c=>c.status==='FAIL').length,cleanup}));
 if(cleanup!=='PASS'||cases.some(c=>c.status!=='PASS'))process.exitCode=1;
}
