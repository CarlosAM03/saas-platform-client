import fs from 'node:fs';
import crypto from 'node:crypto';
import assert from 'node:assert/strict';
import {spawnSync,execFileSync} from 'node:child_process';
const project='prospector-frontend-g1',state='codex/frontend-adr006/.local',base='https://localhost:18643';
const cfg=Object.fromEntries(fs.readFileSync(state+'/core.env','utf8').trim().split(/\r?\n/).map(line=>[line.slice(0,line.indexOf('=')),line.slice(line.indexOf('=')+1)]));
const password=crypto.randomBytes(20).toString('hex')+'Aa1!';
const runId='g1fe'+crypto.randomBytes(6).toString('hex'),ownerEmail=runId+'@example.invalid';
const cases=[];
const docker=(args,input)=>{const r=spawnSync('docker',args,{input,encoding:'utf8',timeout:120000});if(r.status!==0)throw Error('Dedicated Docker operation failed');return r.stdout.trim()};
const container=name=>{const id=docker(['ps','-q','--filter','label=com.docker.compose.project='+project,'--filter','label=com.docker.compose.service='+name]);assert(id&&!id.includes('\n'));return id};
const browser=container('browser'),db=container('db');
const q=value=>"'"+value.replaceAll("'","''")+"'";
const sql=query=>docker(['exec','-i',db,'psql','-X','-Atq','-U','saas_local','-d','avance2_core','-v','ON_ERROR_STOP=1'],query);
const act=data=>{const response=JSON.parse(docker(['exec','-i',browser,'python','-c',"import sys,urllib.request;print(urllib.request.urlopen(urllib.request.Request('http://127.0.0.1:6090',data=sys.stdin.buffer.read()),timeout=90).read().decode())"],JSON.stringify(data)));if(!response.ok)throw Error(response.error);return response.data};
const text=value=>act({action:'waitText',text:value});
const fill=(name,value)=>act({action:'fill',name,value});
const click=name=>act({action:'click',name});
const go=path=>act({action:'goto',url:base+'/#'+path});
const cursor=()=>act({action:'network'}).cursor;
const network=after=>act({action:'network',after}).http;
const http=(after,method,path,status)=>{const r=network(after).filter(r=>r.method===method&&r.path===path).at(-1);assert(r,'Missing '+method+' '+path);assert.equal(r.status,status);return r};
const check=(condition,label)=>{assert.equal(sql('SELECT ('+condition+')::int;'),'1',label);return label};
const record=(id,scope,detail)=>{cases.push({caseId:id,scope,status:'PASS',...detail});console.log(id+' PASS')};
function checksum(){
  return ['tenants','roles','users','user_tenants','campaigns','prospects','campaign_prospects','prospecting_jobs'].map(table=>sql("SELECT count(*)||':'||coalesce(md5(string_agg(row_to_json(t)::text,'|' ORDER BY row_to_json(t)::text)),'empty') FROM "+table+" t;")).join('|');
}
let before,tenantId,ownerId,cleanup='NOT RUN';
try{
 assert.equal(sql("SELECT current_database()||':'||current_setting('server_version_num')::int/10000;"),'avance2_core:16');
 assert.equal(docker(['volume','inspect','--format','{{index .Labels "prospector.owner"}}',project+'_core-pg']),'frontend-g1-exclusive');
 before=checksum();
 act({action:'resetSession'});text('Iniciar sesión');
 fill('Correo electrónico','admin@demo.example');fill('Contraseña',cfg.LOCAL_DEMO_PASSWORD);
 let c=cursor();click('Iniciar sesión');text('Seleccionar organización');
 record('REG-ADMIN-LOGIN-NO-TENANT','UI_HTTP',{http:http(c,'POST','/api/v1/auth/login',200)});
 go('/tenants/new');text('Se creará la organización');
 click('Registrar organización');text('Campo obligatorio');
 fill('Nombre de empresa',runId+' Company');fill('Slug',runId);fill('Nombre del OWNER',runId+' Owner');fill('Correo del OWNER',ownerEmail);
 c=cursor();click('Registrar organización');text('Organización registrada.');
 const registration=http(c,'POST','/api/v1/tenants/register',201);
 assert.deepEqual(registration.requestKeys,['ownerEmail','ownerName','tenantName','tenantSlug']);
 tenantId=sql('SELECT id FROM tenants WHERE slug='+q(runId)+';');assert(tenantId);
 ownerId=sql('SELECT owner_user_id FROM tenant_onboardings WHERE tenant_id='+q(tenantId)+';');assert(ownerId);
 text('Entrega: ACCEPTED');text('Activación: PENDING_FIRST_ACCESS');
 record('REG-CREATE-201-ATOMIC','UI_TO_DB',{http:registration,dbAssertions:[
 check('(SELECT count(*) FROM roles WHERE tenant_id='+q(tenantId)+')=2','Two tenant roles'),
 check("EXISTS(SELECT 1 FROM users u JOIN user_tenants ut ON ut.user_id=u.id JOIN roles r ON r.id=ut.role_id WHERE u.id="+q(ownerId)+" AND u.platform_role IS NULL AND u.must_change_password AND ut.tenant_id="+q(tenantId)+" AND r.name='OWNER')",'Pending non-ADMIN user and OWNER membership'),
 check("EXISTS(SELECT 1 FROM tenant_onboardings o JOIN activation_links l ON l.onboarding_id=o.id JOIN delivery_attempts d ON d.onboarding_id=o.id WHERE o.tenant_id="+q(tenantId)+" AND o.activation_status='PENDING_FIRST_ACCESS' AND o.delivery_status='ACCEPTED' AND l.consumed_at IS NULL)",'Onboarding, hashed link and accepted delivery persisted'),
 ]});
 c=cursor();click('Consultar estado y recuperación');text('Entrega: ACCEPTED');
 const onboardingPath='/api/v1/tenants/'+tenantId+'/onboarding';
 const onboarding=http(c,'GET',onboardingPath,200);
 act({action:'reload'});text('Activación: PENDING_FIRST_ACCESS');
 record('REG-ONBOARDING-REREAD','UI_TO_DB_READ',{http:onboarding,uiReread:'PASS'});
 if(!process.argv.includes('--quick')){
 c=cursor();click('Reenviar enlace de activación');click('Confirmar');text('Se alcanzó el límite temporal.');
 record('REG-RESEND-429','UI_TO_DB',{http:http(c,'POST','/api/v1/tenants/'+tenantId+'/resend-welcome',429),dbAssertions:[check('(SELECT generation FROM tenant_onboardings WHERE tenant_id='+q(tenantId)+')=1','No generation change on throttling')]});
 const wait=Number(sql("SELECT GREATEST(0,ceil(extract(epoch FROM ((SELECT max(d.created_at) FROM delivery_attempts d JOIN tenant_onboardings o ON o.id=d.onboarding_id WHERE o.tenant_id="+q(tenantId)+")+interval '61 seconds'-clock_timestamp()))))::int;"));
 if(wait>0){console.log('Waiting for unchanged persistent resend window');await new Promise(resolve=>setTimeout(resolve,wait*1000));}
 c=cursor();click('Reenviar enlace de activación');click('Confirmar');text('Entrega: ACCEPTED');
 const resend=http(c,'POST','/api/v1/tenants/'+tenantId+'/resend-welcome',200);
 assert.equal(resend.requestBodyPresent,false);
 record('REG-RESEND-200','UI_TO_DB',{http:resend,dbAssertions:[check('(SELECT generation FROM tenant_onboardings WHERE tenant_id='+q(tenantId)+')=2','Manual resend advances generation')]});
 }
 c=cursor();act({action:'openLabActivation',recipient:ownerEmail});text('Nueva contraseña');
 const redeem=http(c,'POST','/api/v1/auth/redeem-first-access',200);
 assert.equal(redeem.authorizationPresent,false);
 assert.deepEqual(redeem.requestKeys,['activationToken']);
 assert(!act({action:'snapshot'}).url.includes('code='));
 record('REG-REDEEM-PUBLIC-CLEAN-URL','UI_TO_DB',{http:redeem,dbAssertions:[check('(SELECT count(*) FROM first_access_challenges f JOIN tenant_onboardings o ON o.id=f.onboarding_id WHERE o.tenant_id='+q(tenantId)+')=1','Single challenge persisted')]});
 fill('Nueva contraseña',password);c=cursor();click('Establecer contraseña');text('Iniciar sesión');
 const complete=http(c,'POST','/api/v1/auth/complete-first-access',200);
 assert.equal(complete.authorizationPresent,false);assert.equal(complete.action,'LOGIN_REQUIRED');
 record('REG-COMPLETE-LOGIN-REQUIRED','UI_TO_DB',{http:complete,dbAssertions:[
 check("EXISTS(SELECT 1 FROM users u JOIN tenant_onboardings o ON o.owner_user_id=u.id WHERE o.tenant_id="+q(tenantId)+" AND NOT u.must_change_password AND o.activation_status='COMPLETED' AND o.completed_at IS NOT NULL)",'Completed state and normal login enabled'),
 check("NOT EXISTS(SELECT 1 FROM first_access_challenges f JOIN tenant_onboardings o ON o.id=f.onboarding_id WHERE o.tenant_id="+q(tenantId)+" AND f.consumed_at IS NULL)",'Challenge consumed'),
 ]});
 fill('Correo electrónico',ownerEmail);fill('Contraseña',password);c=cursor();click('Iniciar sesión');text('Resumen de la organización actual');
 const ownerLogin=http(c,'POST','/api/v1/auth/login',200);
 act({action:'reload'});text('Resumen de la organización actual');
 go('/users');text(runId+' Owner');
 record('REG-OWNER-LOGIN-USERS-REREAD','UI_TO_DB_READ',{http:ownerLogin,uiReread:'PASS',dbAssertions:[check('(SELECT count(*) FROM user_tenants WHERE user_id='+q(ownerId)+' AND tenant_id='+q(tenantId)+')=1','Owner membership stable')]});
 c=cursor();go('/tenants/new');text('No tienes permisos para realizar esta acción.');
 assert(!network(c).some(r=>r.method==='POST'&&r.path==='/api/v1/tenants/register'));
 record('REG-OWNER-REGISTER-DENIED','UI_ACCESS_CONTROL',{});
 const cross=act({action:'http',method:'GET',path:'/api/v1/users/demo-owner-demo-norte'});
 assert([403,404].includes(cross.status));
 record('REG-CROSS-TENANT-ISOLATION','HTTP_SQL',{http:{method:'GET',path:'/api/v1/users/[OTHER_TENANT_USER]',status:cross.status}});
}catch(error){
 const message=String(error).replaceAll(password,'[REDACTED]').replaceAll(cfg.LOCAL_DEMO_PASSWORD,'[REDACTED]').replace(/code=[^\s"'<>]+/g,'code=[REDACTED]').replace(/[A-Za-z0-9_.+-]+@[A-Za-z0-9.-]+/g,'[SYNTHETIC_EMAIL]');
 cases.push({caseId:'E2E-EXECUTION',scope:'UI_TO_DB',status:'FAIL',error:message.slice(0,700)});
 try{cases.at(-1).uiDiagnostic=act({action:'snapshot'});cases.at(-1).recentHttp=network(0).slice(-5);}catch{}
 console.log('E2E FAIL '+message.slice(0,300));
}finally{
 try{
  // Cleanup by this exact random slug/email, in FK order; no global deletes.
  sql('BEGIN; '+['activation_links','first_access_challenges','delivery_attempts'].map(t=>'DELETE FROM '+t+' WHERE onboarding_id IN(SELECT id FROM tenant_onboardings WHERE tenant_id IN(SELECT id FROM tenants WHERE slug='+q(runId)+'));').join(' ')+
  ' DELETE FROM tenant_onboardings WHERE tenant_id IN(SELECT id FROM tenants WHERE slug='+q(runId)+'); DELETE FROM user_tenants WHERE tenant_id IN(SELECT id FROM tenants WHERE slug='+q(runId)+'); DELETE FROM users WHERE email='+q(ownerEmail)+'; DELETE FROM roles WHERE tenant_id IN(SELECT id FROM tenants WHERE slug='+q(runId)+'); DELETE FROM tenants WHERE slug='+q(runId)+'; COMMIT;');
  if(before)assert.equal(checksum(),before);
  cleanup='PASS';
 }catch{cleanup='FAIL';}
 const report={date:new Date().toISOString(),runId,frontendSha:execFileSync('git',['rev-parse','HEAD'],{encoding:'utf8'}).trim(),workingTree:true,backendSha:fs.readFileSync(state+'/backend-sha.txt','utf8').trim(),backendStatus:'VERIFIED_PR_CANDIDATE',postgres:'16',cleanup,cases};
 const out='codex/frontend-adr006/evidencias/e2e-adr006.json';
 if(fs.existsSync(out)){
  const previous=JSON.parse(fs.readFileSync(out,'utf8'));
  fs.copyFileSync(out,out.replace('.json','-'+previous.runId+'.json'));
 }
 fs.writeFileSync(out,JSON.stringify(report,null,2)+'\n');
 console.log('RESULT '+JSON.stringify({pass:cases.filter(c=>c.status==='PASS').length,fail:cases.filter(c=>c.status==='FAIL').length,cleanup}));
 if(cleanup!=='PASS'||cases.some(c=>c.status!=='PASS'))process.exitCode=1;
}
