// Real candidate APIs + independent PostgreSQL database; only Brevo is faked.
import fs from 'node:fs';
import crypto from 'node:crypto';
import assert from 'node:assert/strict';
import {spawnSync} from 'node:child_process';
const project='prospector-frontend-g1',runId='g1http'+crypto.randomBytes(5).toString('hex');
const database=runId,records=[],containers=[];
const docker=(args,input)=>{const r=spawnSync('docker',args,{input,encoding:'utf8',timeout:120000});if(r.status!==0){const error=Error('Dedicated Docker operation failed');error.diagnostic=(r.stderr||'').split(/\r?\n/).find(line=>/^ERROR:/.test(line))?.replace(/'[^']*'/g,"'[REDACTED]'");throw error;}return r.stdout.trim()};
const existing=JSON.parse(docker(['inspect',project+'-api-1']))[0];
assert.equal(existing.Config.Image,'prospector-frontend-g1-backend:5e21442');
const env=Object.fromEntries(existing.Config.Env.map(line=>[line.slice(0,line.indexOf('=')),line.slice(line.indexOf('=')+1)]));
const target=new URL(env.DATABASE_URL);assert.equal(target.hostname,'db');assert.equal(target.pathname,'/avance2_core');
target.pathname='/'+database;env.DATABASE_URL=target.toString();
const password=Object.fromEntries(fs.readFileSync('codex/frontend-adr006/.local/core.env','utf8').trim().split(/\r?\n/).map(line=>line.split('=')) ).LOCAL_DEMO_PASSWORD;
const q=s=>"'"+s.replaceAll("'","''")+"'";
const sql=query=>docker(['exec','-i',project+'-db-1','psql','-X','-Atq','-U','saas_local','-d',database,'-v','ON_ERROR_STOP=1'],query);
const argsEnv=()=>Object.entries(env).filter(([key])=>/^(NODE_ENV|DATABASE_URL|DATABASE_ENV|PORT|JWT_SECRET|JWT_EXPIRES_IN|CORS_ORIGINS|TENANT_REGISTRATION_ENABLED|PLATFORM_ACTIVATION_URL|BREVO_API_KEY|BREVO_FROM_EMAIL|NODE_EXTRA_CA_CERTS)$/.test(key)).flatMap(([key,value])=>['--env',key+'='+value]);
const mail=(path,body)=>JSON.parse(docker(['exec','-i',project+'-mail-1','python','-c',
 "import sys,json,urllib.request;d=json.load(sys.stdin);r=urllib.request.urlopen(urllib.request.Request('http://127.0.0.1:8025'+d['path'],data=json.dumps(d['body']).encode() if d.get('body') is not None else None,headers={'Content-Type':'application/json'}));print(r.read().decode() or '{}')"],JSON.stringify({path,body})));
const request=async(port,path,body,token,method=body===undefined?'GET':'POST')=>{
 assert([18642,18644].includes(port));assert(path.startsWith('/api/v1/'));
 const name=runId+(port===18642?'-off':'-on');
 const client="const fs=require('node:fs'); const d=JSON.parse(fs.readFileSync(0,'utf8')); fetch('http://127.0.0.1:3000'+d.path,{method:d.method,signal:AbortSignal.timeout(d.path.includes('/health/')?5000:30000),headers:{...(d.body===undefined?{}:{'Content-Type':'application/json'}),...(d.token?{Authorization:'Bearer '+d.token}:{})},body:d.body===undefined?undefined:JSON.stringify(d.body)}).then(async r=>console.log(JSON.stringify({status:r.status,json:await r.json()}))).catch(()=>process.exit(1));";
 return JSON.parse(docker(['exec','-i',name,'node','-e',client],JSON.stringify({path,method,body,token})));
};
const record=(caseId,detail={})=>{records.push({caseId,status:'PASS',scope:'HTTP_SQL',...detail});console.log(caseId+' PASS')};
const login=async(port,email,pw=password)=>{const result=await request(port,'/api/v1/auth/login',{email,password:pw});assert.equal(result.status,200);return result.json.data.accessToken};
const register=async(token,suffix)=>{const recipient=runId+'-'+suffix+'@example.invalid';const body={tenantName:runId+' '+suffix,tenantSlug:runId+'-'+suffix,ownerName:'Synthetic Owner',ownerEmail:recipient};return{recipient,body,result:await request(18644,'/api/v1/tenants/register',body,token)}};
let created=false,cleanup='NOT RUN';
try{
 docker(['exec',project+'-db-1','createdb','-U','saas_local',database]);created=true;
 const migration=docker(['run','--rm','--network',project+'_default',...argsEnv(),'--volume',project+'_core-tls:/certs:ro',existing.Config.Image,'npm','run','prisma:migrate:deploy']);
 docker(['run','--rm','--network',project+'_default',...argsEnv(),'--env','DEV_SEED_PASSWORD='+password,existing.Config.Image,'node','dist/Prisma/seed_dev.js']);
 assert.equal(sql("SELECT current_setting('server_version_num')::int/10000;"),'16');
 for(const [flag,port] of [[false,18642],[true,18644]]){
  const name=runId+(flag?'-on':'-off');containers.push(name);
  env.TENANT_REGISTRATION_ENABLED=String(flag);
  docker(['run','-d','--name',name,'--label','prospector.owner=frontend-g1-exclusive','--network',project+'_default',...argsEnv(),'--volume',project+'_core-tls:/certs:ro',existing.Config.Image]);
  let healthy=false;
  for(let i=0;i<90;i++){try{const r=await request(port,'/api/v1/health/ready');if(r.status===200){healthy=true;break}}catch{}await new Promise(r=>setTimeout(r,500))}
  assert(healthy,'Candidate API readiness');
 }
 const admin=await login(18644,'admin@demo.example');
 const offAdmin=await login(18642,'admin@demo.example');
 const count=()=>sql('SELECT (SELECT count(*) FROM tenants)||\':\'||(SELECT count(*) FROM users);');
 const before=count();
 assert.equal((await request(18642,'/api/v1/tenants/register',{tenantName:'Off',tenantSlug:runId+'-off',ownerName:'Off',ownerEmail:runId+'-off@example.invalid'},offAdmin)).status,503);
 assert.equal(count(),before);record('E03-FLAG-OFF-NO-WRITES');
 const pending=await register(admin,'pending');assert.equal(pending.result.status,201);
 const id=pending.result.json.data.tenant.id;
 assert.equal((await request(18642,'/api/v1/tenants/'+id+'/onboarding',undefined,offAdmin)).status,200);
 assert.equal((await request(18642,'/api/v1/tenants/'+id+'/resend-welcome',undefined,offAdmin,'POST')).status,503);
 const unchanged=count();
 assert.equal((await request(18644,'/api/v1/tenants/register',pending.body,admin)).status,409);
 assert.equal(count(),unchanged);
 assert.equal((await request(18644,'/api/v1/tenants/register',{},admin)).status,400);
 for(const role of ['owner','member']){
  const token=await login(18644,role+'.demo-norte@demo.example');
  assert.equal((await request(18644,'/api/v1/tenants/register',pending.body,token)).status,403);
 }
 assert.equal(count(),unchanged);record('E05-VALIDATION-ROLES-CONFLICT-NO-PARTIAL-WRITES');
 const code=mail('/?recipient='+encodeURIComponent(pending.recipient)).code;
 const redeemed=await request(18642,'/api/v1/auth/redeem-first-access',{activationToken:code});assert.equal(redeemed.status,200);
 assert.equal(redeemed.json.data.action,'CHANGE_PASSWORD_REQUIRED');
 assert.equal(sql("SELECT (extract(epoch FROM (f.expires_at-f.created_at))<=900)::int FROM first_access_challenges f JOIN tenant_onboardings o ON o.id=f.onboarding_id WHERE o.tenant_id="+q(id)+';'),'1');
 const challenge=redeemed.json.data.firstAccessToken;
 assert.equal((await request(18642,'/api/v1/auth/complete-first-access',{firstAccessToken:challenge,newPassword:'short'})).status,400);
 const ownerPassword=crypto.randomBytes(16).toString('hex')+'Aa1!';
 const complete=await request(18642,'/api/v1/auth/complete-first-access',{firstAccessToken:challenge,newPassword:ownerPassword});assert.equal(complete.status,200);assert.deepEqual(complete.json.data,{action:'LOGIN_REQUIRED'});
 assert.equal((await request(18642,'/api/v1/auth/redeem-first-access',{activationToken:code})).status,401);
 await login(18642,pending.recipient,ownerPassword);
 record('E03-RECOVERY-WHILE-FLAG-OFF');record('E14-PASSWORD-400-RECOVERABLE-TTL-AND-REPLAY');
 for(const [mode,delivery] of [[400,'FAILED'],[429,'FAILED'],[500,'UNKNOWN'],['timeout','UNKNOWN']]){
  const suffix='failure-'+mode,recipient=runId+'-'+suffix+'@example.invalid';
  mail('/lab/control',{recipient,mode});
  const result=await register(admin,suffix);assert.equal(result.result.status,201);
  assert.equal(result.result.json.data.onboarding.deliveryStatus,delivery);
  assert.equal(mail('/lab/stats?recipient='+encodeURIComponent(recipient)).attempts,1);
  assert.equal(sql('SELECT count(*) FROM tenant_onboardings WHERE tenant_id='+q(result.result.json.data.tenant.id)+';'),'1');
  record('E08-PROVIDER-'+mode,{http:201,deliveryStatus:delivery,providerAttempts:1,persistence:'PASS'});
 }
 const expiring=await register(admin,'expiring');
 const expCode=mail('/?recipient='+encodeURIComponent(expiring.recipient)).code;
 const expRedeem=await request(18644,'/api/v1/auth/redeem-first-access',{activationToken:expCode});assert.equal(expRedeem.status,200);
 sql("UPDATE first_access_challenges SET created_at=clock_timestamp()-interval '16 minutes',expires_at=clock_timestamp()-interval '2 minutes' WHERE onboarding_id IN(SELECT id FROM tenant_onboardings WHERE tenant_id="+q(expiring.result.json.data.tenant.id)+');');
 assert.equal((await request(18644,'/api/v1/auth/complete-first-access',{firstAccessToken:expRedeem.json.data.firstAccessToken,newPassword:ownerPassword})).status,401);
 record('E14-EXPIRED-CHALLENGE-REJECTED-BY-SERVER');
}catch(error){records.push({caseId:'HTTP-SQL-EXECUTION',status:'FAIL',errorType:error.name,diagnostic:error.diagnostic,location:error.stack?.split('\n').find(line=>line.includes('http-sql.mjs:'))?.trim(),message: String(error).startsWith('AssertionError')?'Assertion failed':'Laboratory operation failed'});}
finally{
 try{
  for(const name of containers){assert(name.startsWith(runId));docker(['stop',name]);docker(['rm',name]);}
  if(created){assert(/^g1http[a-f0-9]{10}$/.test(database));docker(['exec',project+'-db-1','dropdb','-U','saas_local',database]);}
  cleanup='PASS';
 }catch{cleanup='FAIL'}
 fs.writeFileSync('codex/frontend-adr006/evidencias/http-sql.json',JSON.stringify({date:new Date().toISOString(),backendSha:'5e214420394101ae7079f8e844cc759b01cce2a3',database,postgres:'16',cleanup,cases:records},null,2)+'\n');
 if(cleanup!=='PASS'||records.some(r=>r.status!=='PASS'))process.exitCode=1;
}
