import fs from 'node:fs';
import crypto from 'node:crypto';
import assert from 'node:assert/strict';
import {spawnSync,execFileSync} from 'node:child_process';
const [stateDir,out='codex/evidencias/e2e-local.json'] = process.argv.slice(2);
if(!stateDir) throw Error('Usage: node tool/sprint/e2e.mjs PRIVATE_STATE_DIR [OUTPUT]');
const project='prospector-frontend-sprint', base='https://localhost:18543';
const cfg=Object.fromEntries(fs.readFileSync(stateDir+'/core.env','utf8').trim().split(/\r?\n/).map(l=>[l.slice(0,l.indexOf('=')),l.slice(l.indexOf('=')+1)]));
const recovery=process.argv[4];
if(recovery&&!/^sprint[a-f0-9]{14}$/.test(recovery))throw Error('Invalid recovery run ID');
const runId=recovery||'sprint'+crypto.randomBytes(7).toString('hex');
const a=runId+'a',b=runId+'b';
const actors={owner:runId+'owner',member:runId+'member',admin:runId+'admin',other:runId+'other',shared:runId+'shared'};
const email=k=>runId+'-'+k+'@example.invalid';
const evidence=[], logins=[];
let stopping=false;process.on('SIGINT',()=>{stopping=true;});
const safe=e=>String(e).replaceAll(cfg.LOCAL_DEMO_PASSWORD,'[REDACTED]').replace(/[A-Za-z0-9_.+-]+@[A-Za-z0-9.-]+/g,'[SYNTHETIC_EMAIL]');
const docker=(args,input)=>{const r=spawnSync('docker',args,{input,encoding:'utf8',timeout:100000});if(r.status!==0)throw Error('Docker command failed: '+safe(r.stderr).slice(0,500));return r.stdout.trim()};
const container=service=>{const ids=docker(['ps','-q','--filter','label=com.docker.compose.project='+project,'--filter','label=com.docker.compose.service='+service]).split(/\s+/).filter(Boolean);assert.equal(ids.length,1,'Expected one dedicated '+service);return ids[0]};
const browser=recovery?null:container('browser'),db=container('db');
const sql=query=>docker(['exec','-i',db,'psql','-X','-Atq','-U','saas_local','-d','avance2_core','-v','ON_ERROR_STOP=1'],query);
const q=s=>"'"+s.replaceAll("'","''")+"'";
const act=d=>{
 const response=docker(['exec','-i',browser,'python','-c',"import sys,urllib.request;print(urllib.request.urlopen(urllib.request.Request('http://127.0.0.1:6090',data=sys.stdin.buffer.read()),timeout=80).read().decode())"],JSON.stringify(d));
 const v=JSON.parse(response);if(!v.ok)throw Error(safe(v.error));return v.data;
};
const snapshot=()=>act({action:'snapshot'});
const click=(name,extra={})=>act({action:'click',name,...extra});
const fill=(name,value)=>act({action:'fill',name,value});
const text=value=>act({action:'waitText',text:value});
const go=(route,expected)=>{act({action:'goto',url:base+'/#'+route});if(expected)text(expected);return snapshot()};
const network=after=>act({action:'network',after}).http;
const cursor=()=>act({action:'network'}).cursor;
const sleep=ms=>new Promise(r=>setTimeout(r,ms));
async function login(role,tenant=a){
 const recent=logins.filter(t=>Date.now()-t<61000);
 if(recent.length>=4){console.log('Waiting for the unchanged authentication rate window');await sleep(61000-(Date.now()-recent[0]));}
 let s=go('/login');
 if(!s.url.endsWith('/login')){click('Cerrar sesión');text('Iniciar sesión');}
 fill('Correo electrónico',email(role));fill('Contraseña',cfg.LOCAL_DEMO_PASSWORD);
 click('Iniciar sesión');logins.push(Date.now());
 if(role==='admin'||role==='shared'){
  text('Seleccionar organización');
  click(tenant===a?runId+' A':runId+' B',{exact:false});
 }
 text('Resumen de la organización actual');
}
async function caseRun(caseId,scope,role,fn){
 if(stopping){evidence.push({caseId,scope,role,status:'NOT RUN',reason:'Interrupted; cleanup still runs'});return null;}
 try{const detail=await fn();evidence.push({caseId,scope,role,tenantFixture:role==='other'?'B':'A',status:'PASS',...detail});console.log(caseId+' PASS');return detail;}
 catch(e){let uiDiagnostic;try{uiDiagnostic=snapshot()}catch{}evidence.push({caseId,scope,role,status:'FAIL',error:safe(e),uiDiagnostic});console.log(caseId+' FAIL '+safe(e).slice(0,260));return null;}
}
function httpAfter(start,method,path,status){
 const matches=network(start).filter(h=>h.method===method&&h.path===path);
 const h=matches.at(-1);assert(h,'Missing browser HTTP '+method+' '+path);
 assert.equal(h.status,status);return h;
}
function sqlAssert(condition,label){
 assert.equal(sql('SELECT ('+condition+')::int;'),'1',label);return label;
}
function reread(route,label){go(route,label);act({action:'reload'});text(label);return 'PASS'}
function checksum(){
 const tables=['tenants','roles','users','user_tenants','campaigns','prospects','campaign_prospects','prospecting_jobs'];
 return tables.map(t=>sql("SELECT count(*)||':'||coalesce(md5(string_agg(row_to_json(t)::text,'|' ORDER BY row_to_json(t)::text)),'empty') FROM "+t+" t;")).join('|');
}
function setup(){
 assert.equal(sql("SELECT current_database()||':'||current_setting('server_version_num')::int/10000;"),'avance2_core:16');
 const label=docker(['volume','inspect','--format','{{index .Labels "prospector.owner"}}',project+'_core-pg']);
 assert.equal(label,'frontend-sprint-exclusive');
 const statements=[];
 statements.push('BEGIN; INSERT INTO tenants(id,name,slug,created_at,updated_at) VALUES '+[a,b].map((id,i)=>'('+[q(id),q(runId+(i?' B':' A')),q(id),'now()','now()'].join(',')+')').join(',')+';');
 // This run owns a new DB transaction and all inserted identities. Copy only a synthetic seed hash.
 statements.push('INSERT INTO roles(id,tenant_id,name,created_at,updated_at) VALUES '+[a,b].flatMap(t=>['OWNER','MEMBER'].map(r=>'('+[q(t+r),q(t),q(r),'now()','now()'].join(',')+')')).join(',')+';');
 for(const [role,id]of Object.entries(actors)){
  statements.push('INSERT INTO users(id,name,email,password_hash,platform_role,created_at,updated_at) SELECT '+[q(id),q(runId+' '+role),q(email(role)),"password_hash",role==='admin'?"'ADMIN'":'NULL','now()','now()'].join(',')+" FROM users WHERE email='admin@demo.example';");
  const tenant=role==='other'?b:a,roleName=role==='owner'||role==='other'?'OWNER':'MEMBER';
  statements.push('INSERT INTO user_tenants(user_id,tenant_id,role_id) VALUES ('+[q(id),q(tenant),q(tenant+roleName)].join(',')+');');
 }
 statements.push('INSERT INTO user_tenants(user_id,tenant_id,role_id) VALUES ('+[q(actors.shared),q(b),q(b+'MEMBER')].join(',')+');COMMIT;');
 sql(statements.join('\n'));
}
function cleanup(){
 sql('BEGIN; DELETE FROM roles WHERE tenant_id IN(SELECT id FROM tenants WHERE slug='+q(runId+'-created-tenant')+' AND name='+q(runId+' created-tenant')+'); DELETE FROM tenants WHERE slug='+q(runId+'-created-tenant')+' AND name='+q(runId+' created-tenant')+'; DELETE FROM campaign_prospects WHERE campaign_id IN(SELECT id FROM campaigns WHERE tenant_id IN('+q(a)+','+q(b)+')) OR prospect_id IN(SELECT id FROM prospects WHERE tenant_id IN('+q(a)+','+q(b)+')); DELETE FROM prospecting_jobs WHERE tenant_id IN('+q(a)+','+q(b)+'); DELETE FROM prospects WHERE tenant_id IN('+q(a)+','+q(b)+'); DELETE FROM campaigns WHERE tenant_id IN('+q(a)+','+q(b)+'); DELETE FROM user_tenants WHERE tenant_id IN('+q(a)+','+q(b)+'); DELETE FROM users WHERE id IN('+Object.values(actors).map(q).join(',')+') OR email LIKE '+q(runId+'-%@example.invalid')+'; DELETE FROM roles WHERE tenant_id IN('+q(a)+','+q(b)+'); DELETE FROM tenants WHERE id IN('+q(a)+','+q(b)+'); COMMIT;');
}
async function createUser(kind){
 go('/users/new','El usuario se crea como MEMBER');
 fill('Nombre',runId+' '+kind);fill('Correo electrónico',email(kind));fill('Contraseña',cfg.LOCAL_DEMO_PASSWORD+'Aa1!');
 const start=cursor();click('Guardar');text(runId+' '+kind);
 const http=httpAfter(start,'POST','/api/v1/users',201);assert(http.id);
 assert.deepEqual(http.requestKeys,['email','name','password']);
 const dbAssertions=[sqlAssert("EXISTS(SELECT 1 FROM users u JOIN user_tenants m ON m.user_id=u.id JOIN roles r ON r.id=m.role_id WHERE u.id="+q(http.id)+" AND m.tenant_id="+q(a)+" AND r.name='MEMBER')",'User and tenant MEMBER membership persisted atomically')];
 return {id:http.id,http,dbAssertions,uiReread:reread('/users/'+http.id,runId+' '+kind)};
}
async function createCampaign(kind,actor='owner'){
 go('/campaigns/new','Guardar');fill('Nombre',runId+' '+kind);fill('Descripción','Synthetic sprint fixture');
 const start=cursor();click('Guardar');click('Confirmar');text(runId+' '+kind);
 const http=httpAfter(start,'POST','/api/v1/campaigns',201);assert(http.id);
 return {id:http.id,http,dbAssertions:[sqlAssert('EXISTS(SELECT 1 FROM campaigns WHERE id='+q(http.id)+' AND tenant_id='+q(a)+' AND created_by='+q(actors[actor])+')','Campaign tenant and creator persisted')],uiReread:reread('/campaigns/'+http.id,runId+' '+kind)};
}
async function importCsv(campaign,campaignName,csv,decision='CREATE',existingId=null){
 go('/prospects');
 go('/prospects/import','Seleccionar CSV');
 click('Seleccionar campaña');click(campaignName,{exact:false});
 act({action:'file',csv});const start=cursor();click('Generar vista previa');
 text('Las coincidencias se omiten hasta que elijas vincularlas o actualizarlas.');
 if(decision!=='CREATE'){
  // A single synthetic row deliberately makes this semantic selector unambiguous.
  click('1.',{exact:false});
  const option={SKIP:'Omitir',LINK_EXISTING:'Vincular sin modificar',UPDATE_EXISTING:'Actualizar y vincular'}[decision];
  act({action:'select',role:'combobox',name:decision==='SKIP'?'Crear prospecto':'Omitir',option});
 }
 click('Confirmar importación');click('Importar ahora');text('Importación terminada');
 const observed=network(start),preview=observed.find(h=>h.method==='POST'&&h.path.endsWith('/preview')),confirm=observed.find(h=>h.method==='POST'&&h.path.endsWith('/confirm'));
 assert(preview&&confirm);assert.equal(preview.status,200);assert.equal(confirm.status,200);
 assert(preview.fileSha256);assert.equal(preview.fileSha256,confirm.fileSha256,'Original CSV bytes must be reused');
 const name=csv.split(/\r?\n/)[1].split(',')[0];
 let assertions=[];
 if(decision==='SKIP')assertions.push(sqlAssert('NOT EXISTS(SELECT 1 FROM prospects WHERE name='+q(name)+')','SKIP creates no rows'));
 else if(existingId)assertions.push(sqlAssert('EXISTS(SELECT 1 FROM campaign_prospects WHERE campaign_id='+q(campaign)+' AND prospect_id='+q(existingId)+')','Existing prospect linked to target campaign'));
 else assertions.push(sqlAssert("EXISTS(SELECT 1 FROM prospects WHERE name="+q(name)+" AND tenant_id="+q(a)+" AND campaign_id="+q(campaign)+" AND source='csv')",'CSV prospect and source persisted'));
 if(decision==='UPDATE_EXISTING')assertions.push(sqlAssert('EXISTS(SELECT 1 FROM prospects WHERE id='+q(existingId)+' AND name='+q(name)+" AND category='Updated category')",'Existing prospect category changed without changing the normalized-name match'));
 if(existingId)reread('/prospects/'+existingId,decision==='UPDATE_EXISTING'?'Updated category':runId+' manual');
 else{go('/campaigns/'+campaign);click('Prospectos',{role:'tab'});act({action:'reload'});click('Prospectos',{role:'tab'});if(decision!=='SKIP')text(name);}
 return {http:[preview,confirm],dbAssertions:assertions,uiReread:'PASS',originalBytes:'PASS'};
}
let before,started=false,campaign,campaign2,user,manual;
if(recovery){cleanup();console.log('PASS: removed only the identified interrupted sprint run');process.exit(0);}
try{
 for(let attempt=0;attempt<60;attempt++){
  if(docker(['inspect','--format','{{.State.Health.Status}}',browser])==='healthy')break;
  if(attempt===59)throw Error('Browser did not become healthy');
  await sleep(1000);
 }
 act({action:'resetSession'});text('Iniciar sesión');
 before=checksum();started=true;setup();
 await caseRun('AUTH-OWNER','UI_HTTP','owner',async()=>{const c=cursor();await login('owner');return{http:httpAfter(c,'POST','/api/v1/auth/login',200),uiReread:reread('/dashboard','Resumen de la organización actual')}});
 user=await caseRun('USR-CREATE-OWNER','UI_TO_DB','owner',()=>createUser('created-owner'));
 if(user)await caseRun('USR-PATCH-DIFFERENTIAL','UI_TO_DB','owner',async()=>{
  go('/users/'+user.id+'/edit','Guardar');fill('Nombre',runId+' edited');const c=cursor();click('Guardar');text(runId+' edited');
  const http=httpAfter(c,'PATCH','/api/v1/users/'+user.id,200);assert.deepEqual(http.requestKeys,['name']);
  return{http,dbAssertions:[sqlAssert('EXISTS(SELECT 1 FROM users WHERE id='+q(user.id)+' AND name='+q(runId+' edited')+' AND email='+q(email('created-owner'))+')','Only changed name persisted')],uiReread:reread('/users/'+user.id,runId+' edited')};
 });
 await caseRun('USR-DUPLICATE-409','UI_TO_DB','owner',async()=>{
  const count=sql('SELECT count(*) FROM users;'),members=sql('SELECT count(*) FROM user_tenants;');
  go('/users/new','Guardar');fill('Nombre',runId+' duplicate');fill('Correo electrónico',email('created-owner'));fill('Contraseña',cfg.LOCAL_DEMO_PASSWORD+'Aa1!');
  const c=cursor();click('Guardar');text('La operación entra en conflicto con el estado actual.');
  const http=httpAfter(c,'POST','/api/v1/users',409);assert.equal(sql('SELECT count(*) FROM users;'),count);assert.equal(sql('SELECT count(*) FROM user_tenants;'),members);
  act({action:'reload'});text('Guardar');return{http,dbAssertions:['No partial User or UserTenant writes'],uiReread:'PASS'};
 });
 await caseRun('USR-INVALID-400','UI_TO_DB','owner',async()=>{
  const count=sql('SELECT count(*) FROM users;'),members=sql('SELECT count(*) FROM user_tenants;');
  go('/users/new','Guardar');fill('Nombre',runId+' invalid');fill('Correo electrónico','not-an-email');fill('Contraseña',cfg.LOCAL_DEMO_PASSWORD+'Aa1!');
  const c=cursor();click('Guardar');text('Revisa los datos ingresados.');
  const http=httpAfter(c,'POST','/api/v1/users',400);assert.equal(sql('SELECT count(*) FROM users;'),count);assert.equal(sql('SELECT count(*) FROM user_tenants;'),members);
  return{http,dbAssertions:['Validation rejects User and membership atomically'],uiReread:reread('/users/new','El usuario se crea como MEMBER')};
 });
 await caseRun('USR-CONCURRENT-CREATE','UI_TO_DB','owner',async()=>{
  const c=cursor();const result=act({action:'concurrentUserCreate',name:runId+' concurrent',email:email('concurrent'),password:cfg.LOCAL_DEMO_PASSWORD+'Aa1!'});
  const http=network(c).filter(h=>h.method==='POST'&&h.path==='/api/v1/users');
  assert.deepEqual(http.map(h=>h.status).sort(),[201,409]);
  return{http,dbAssertions:[sqlAssert('(SELECT count(*) FROM users WHERE email='+q(email('concurrent'))+')=1','Unique email under simultaneous UI submissions'),sqlAssert('(SELECT count(*) FROM user_tenants WHERE user_id='+q(result.id)+')=1','One complete membership and no partial duplicate')],uiReread:result.uiReread,concurrentBrowserTabs:2};
 });
 await caseRun('USR-SEC01-GLOBAL-403','UI_TO_DB','owner',async()=>{
  const original=sql('SELECT name FROM users WHERE id='+q(actors.shared)+';');
  go('/users/'+actors.shared+'/edit','Guardar');fill('Nombre',runId+' forbidden');const c=cursor();click('Guardar');text('No tienes permisos para realizar esta acción.');
  const http=httpAfter(c,'PATCH','/api/v1/users/'+actors.shared,403);assert.equal(http.reason,'GLOBAL_IDENTITY_PROTECTED');assert.equal(sql('SELECT name FROM users WHERE id='+q(actors.shared)+';'),original);
  return{http,dbAssertions:['SEC-01 leaves shared global identity intact'],uiReread:reread('/users/'+actors.shared,original)};
 });
 await caseRun('USR-SHARED-NOOP','UI_TO_DB','owner',async()=>{
  go('/users/'+actors.shared+'/edit','Guardar');const c=cursor();click('Guardar');text(runId+' shared');assert(!network(c).some(h=>h.method==='PATCH'));
  return{http:network(c),dbAssertions:[sqlAssert('EXISTS(SELECT 1 FROM users WHERE id='+q(actors.shared)+' AND name='+q(runId+' shared')+')','No-op leaves shared identity unchanged')],uiReread:reread('/users/'+actors.shared,runId+' shared')};
 });
 campaign=await caseRun('CAM-CREATE','UI_TO_DB','owner',()=>createCampaign('campaign'));
 campaign2=await caseRun('CAM-CREATE-CSV-TARGET','UI_TO_DB','owner',()=>createCampaign('csv-target'));
 if(campaign)manual=await caseRun('PRO-MANUAL','UI_TO_DB','owner',async()=>{
  go('/prospects/new','Seleccionar campaña');click('Seleccionar campaña');click(runId+' campaign',{exact:false});
  fill('Nombre',runId+' manual');fill('Correo electrónico',email('prospect'));fill('Teléfono','12345');
  const c=cursor();click('Guardar');text(runId+' manual');const http=httpAfter(c,'POST','/api/v1/prospects',201);
  return{id:http.id,http,dbAssertions:[sqlAssert("EXISTS(SELECT 1 FROM prospects WHERE id="+q(http.id)+" AND tenant_id="+q(a)+" AND campaign_id="+q(campaign.id)+" AND source='manual')",'Manual prospect, tenant and origin campaign persisted')],uiReread:reread('/prospects/'+http.id,runId+' manual')};
 });
 if(manual)await caseRun('PRO-NULLABLE-PATCH','UI_TO_DB','owner',async()=>{
  go('/prospects/'+manual.id+'/edit','Guardar');fill('Teléfono','');const c=cursor();click('Guardar');text(runId+' manual');
  const http=httpAfter(c,'PATCH','/api/v1/prospects/'+manual.id,200);assert.deepEqual(http.requestKeys,['phone']);
  return{http,dbAssertions:[sqlAssert('EXISTS(SELECT 1 FROM prospects WHERE id='+q(manual.id)+' AND phone IS NULL AND email='+q(email('prospect'))+')','Explicit null clears phone, omitted email preserved')],uiReread:reread('/prospects/'+manual.id,runId+' manual')};
 });
 if(campaign)await caseRun('CSV-CREATE','UI_TO_DB','owner',()=>importCsv(campaign.id,runId+' campaign','name,email\n'+runId+' csv,'+email('csv')+'\n'));
 if(campaign)await caseRun('CSV-SKIP','UI_TO_DB','owner',()=>importCsv(campaign.id,runId+' campaign','name,email\n'+runId+' skipped,'+email('skipped')+'\n','SKIP'));
 if(campaign2&&manual)await caseRun('CSV-LINK','UI_TO_DB','owner',()=>importCsv(campaign2.id,runId+' csv-target','name,email\n'+runId+' manual,'+email('prospect')+'\n','LINK_EXISTING',manual.id));
 if(campaign2&&manual)await caseRun('CSV-UPDATE','UI_TO_DB','owner',()=>importCsv(campaign2.id,runId+' csv-target','name,email,category\n'+runId+' manual,'+email('prospect')+',Updated category\n','UPDATE_EXISTING',manual.id));
 if(campaign)await caseRun('CAM-EDIT-STATUS','UI_TO_DB','owner',async()=>{
  go('/campaigns/'+campaign.id+'/edit','Guardar');fill('Descripción','Edited synthetic fixture');
  act({action:'select',role:'button',name:'ACTIVA',exact:false,option:'PAUSADA'});
  const c=cursor();click('Guardar');text('PAUSADA');
  return{http:httpAfter(c,'PATCH','/api/v1/campaigns/'+campaign.id,200),dbAssertions:[sqlAssert("EXISTS(SELECT 1 FROM campaigns WHERE id="+q(campaign.id)+" AND description='Edited synthetic fixture' AND status='PAUSADA')",'Campaign changes and status persisted')],uiReread:reread('/campaigns/'+campaign.id,'PAUSADA')};
 });
 await caseRun('JWT-OWNER-SNAPSHOT','UI_TO_DB','owner',async()=>{
  sql('UPDATE user_tenants SET role_id='+q(a+'MEMBER')+' WHERE user_id='+q(actors.owner)+' AND tenant_id='+q(a)+';');
  try{return await createUser('snapshot-owner')}finally{sql('UPDATE user_tenants SET role_id='+q(a+'OWNER')+' WHERE user_id='+q(actors.owner)+' AND tenant_id='+q(a)+';')}
 });
 await caseRun('AUTH-MEMBER','UI_HTTP','member',async()=>{await login('member');return{uiReread:reread('/dashboard','Resumen de la organización actual')}});
 await caseRun('CAM-CREATE-MEMBER','UI_TO_DB','member',()=>createCampaign('member-campaign','member'));
 await caseRun('USR-MEMBER-403','UI_ACCESS_CONTROL_AND_HTTP_SQL','member',async()=>{
  sql('UPDATE user_tenants SET role_id='+q(a+'OWNER')+' WHERE user_id='+q(actors.member)+' AND tenant_id='+q(a)+';');
  try{
   const count=sql('SELECT count(*) FROM users;');go('/users/new','No tienes permisos para realizar esta acción.');
   const response=act({action:'http',method:'POST',path:'/api/v1/users',body:{name:runId+' denied',email:email('denied'),password:cfg.LOCAL_DEMO_PASSWORD+'Aa1!'}});
   assert.equal(response.status,403);assert.equal(sql('SELECT count(*) FROM users;'),count);
   act({action:'reload'});text('No tienes permisos para realizar esta acción.');
   return{http:{method:'POST',path:'/api/v1/users',status:403,source:'complementary HTTP, not UI mutation'},dbAssertions:['No partial writes; UI MEMBER remains snapshot despite DB promotion'],uiReread:'PASS'};
  }finally{sql('UPDATE user_tenants SET role_id='+q(a+'MEMBER')+' WHERE user_id='+q(actors.member)+' AND tenant_id='+q(a)+';')}
 });
 await caseRun('TEN-CROSS-READ','UI_TO_DB_READ','other',async()=>{
  await login('other',b);assert(campaign);const c=cursor();go('/campaigns/'+campaign.id,'No se encontró la información solicitada.');
  const http=httpAfter(c,'GET','/api/v1/campaigns/'+campaign.id,404);
  const s=snapshot();assert(!s.aria.includes(runId+' campaign'));
  return{http,dbAssertions:[sqlAssert('EXISTS(SELECT 1 FROM campaigns WHERE id='+q(campaign.id)+' AND tenant_id='+q(a)+')','Campaign remains scoped to A')],uiReread:reread('/campaigns/'+campaign.id,'No se encontró la información solicitada.')};
 });
 await caseRun('ADMIN-DISCOVERY-MEMBERSHIP','UI_HTTP_SQL','admin',async()=>{
  await login('admin');const c=cursor();go('/change-tenant','Seleccionar organización');
  text(runId+' B');const http=httpAfter(c,'GET','/api/v1/tenants',200);
  click(runId+' B',{exact:false});text('Resumen de la organización actual');
  return{http,dbAssertions:[sqlAssert('NOT EXISTS(SELECT 1 FROM user_tenants WHERE user_id='+q(actors.admin)+' AND tenant_id='+q(b)+')','ADMIN discovers B without membership')],uiReread:reread('/dashboard','Resumen de la organización actual')};
 });
 await caseRun('USR-CREATE-ADMIN','UI_TO_DB','admin',async()=>{
  go('/change-tenant','Seleccionar organización');click(runId+' A',{exact:false});text('Resumen de la organización actual');return await createUser('created-admin');
 });
 if(user)await caseRun('USR-DEACTIVATE-ADMIN','UI_TO_DB','admin',async()=>{
  go('/users/'+user.id,runId+' edited');const c=cursor();click('Desactivar usuario');click('Confirmar');text('INACTIVO');
  return{http:httpAfter(c,'DELETE','/api/v1/users/'+user.id,200),dbAssertions:[sqlAssert("EXISTS(SELECT 1 FROM users WHERE id="+q(user.id)+" AND status='INACTIVO')",'ADMIN deactivation persisted')],uiReread:reread('/users/'+user.id,'INACTIVO')};
 });
 if(campaign)await caseRun('CAM-ARCHIVE','UI_TO_DB','admin',async()=>{
  go('/campaigns/'+campaign.id,runId+' campaign');const c=cursor();click('Archivar campaña');click('Confirmar');text('ARCHIVADA');
  return{http:httpAfter(c,'DELETE','/api/v1/campaigns/'+campaign.id,200),dbAssertions:[sqlAssert("EXISTS(SELECT 1 FROM campaigns WHERE id="+q(campaign.id)+" AND status='ARCHIVADA')",'Campaign archived')],uiReread:reread('/campaigns/'+campaign.id,'ARCHIVADA')};
 });
 if(campaign)await caseRun('JOBS-DISABLED-503','HTTP_SQL','admin',async()=>{
  const job=runId+'job';sql("INSERT INTO prospecting_jobs(id,tenant_id,campaign_id,requested_by,status,query,created_at,updated_at) VALUES ("+[q(job),q(a),q(campaign.id),q(actors.admin),"'QUEUED'",q(JSON.stringify({keyword:'coffee',location:'Tijuana',source:'google_maps',limit:10}))+"::jsonb",'now()','now()'].join(',')+");");
  const checks=[];
  for(const [method,path,body]of [['POST','/api/v1/prospecting-jobs',{campaignId:campaign.id,query:{keyword:'coffee',location:'Tijuana',source:'google_maps',limit:10}}],['POST','/api/v1/prospecting-jobs/'+job+'/cancel'],['POST','/api/v1/prospecting-jobs/'+job+'/persist'],['GET','/api/v1/prospecting-jobs/'+job+'/export?format=csv']]){
   const r=act({action:'http',method,path,body,headers:{'Idempotency-Key':crypto.randomUUID()}});
   assert.equal(r.status,503);assert.equal(r.body.error.details.reason,'PROSPECTOR_INTEGRATION_PENDING');checks.push({method,path,status:r.status});
  }
  assert.equal(sql('SELECT count(*) FROM prospecting_jobs WHERE tenant_id='+q(a)+';'),'1');
  return{http:checks,dbAssertions:['Four unavailable operations leave Jobs unchanged']};
 });
 await caseRun('JOBS-READ-UI','UI_TO_DB_READ','admin',async()=>{
  const job=runId+'job';const c=cursor();go('/jobs','Trabajo '+job);click('Trabajo '+job,{exact:false});text('coffee');
  const http=[httpAfter(c,'GET','/api/v1/prospecting-jobs',200),httpAfter(c,'GET','/api/v1/prospecting-jobs/'+job,200)];
  return{http,dbAssertions:[sqlAssert("EXISTS(SELECT 1 FROM prospecting_jobs WHERE id="+q(job)+" AND tenant_id="+q(a)+" AND query->>'source'='google_maps')",'Persisted contractual Job read without generated results')],uiReread:reread('/jobs/'+job,'coffee')};
 });
 await caseRun('DASH-SQL-TOTALS','UI_TO_DB_READ','admin',async()=>{
  const c=cursor();go('/dashboard','Resumen de la organización actual');
  const http=[];
  for(const [table,route,label]of [['campaigns','campaigns','Campañas'],['prospects','prospects','Prospectos'],['prospecting_jobs','prospecting-jobs','Trabajos']]){
   const count=Number(sql('SELECT count(*) FROM '+table+' WHERE tenant_id='+q(a)+';'));
   text(count+' '+label);const response=httpAfter(c,'GET','/api/v1/'+route,200);assert.equal(response.total,count);http.push(response);
  }
  return{http,dbAssertions:['All three meta.total values match direct SQL totals for A'],uiReread:reread('/dashboard','Resumen de la organización actual')};
 });
 await caseRun('TEN-CREATE-ADMIN','UI_TO_DB','admin',async()=>{
  go('/tenants/new','Guardar');fill('Nombre',runId+' created-tenant');fill('Slug',runId+'-created-tenant');const c=cursor();click('Guardar');text(runId+' created-tenant');
  const http=httpAfter(c,'POST','/api/v1/tenants',201);
  return{http,dbAssertions:[sqlAssert('EXISTS(SELECT 1 FROM tenants WHERE id='+q(http.id)+' AND slug='+q(runId+'-created-tenant')+')','Tenant persisted'),sqlAssert('(SELECT count(*) FROM roles WHERE tenant_id='+q(http.id)+')=2','Core tenant roles created atomically')],uiReread:reread('/tenants/'+http.id,runId+' created-tenant')};
 });
 await caseRun('CAM-DELETE-ADMIN','UI_TO_DB','admin',async()=>{
  const empty=await createCampaign('delete-target','admin');
  go('/campaigns/'+empty.id,runId+' delete-target');const c=cursor();click('Eliminar permanentemente');click('Confirmar');
  const http=httpAfter(c,'DELETE','/api/v1/campaigns/'+empty.id,200);
  return{http,dbAssertions:[sqlAssert('NOT EXISTS(SELECT 1 FROM campaigns WHERE id='+q(empty.id)+')','Permanent deletion removes the campaign')],uiReread:reread('/campaigns/'+empty.id,'No se encontró la información solicitada.')};
 });
 await caseRun('AUTH-LOGOUT-DEEPLINK','UI_HTTP','admin',async()=>{
  const c=cursor();click('Cerrar sesión');text('Iniciar sesión');go('/users','Iniciar sesión');
  return{http:httpAfter(c,'POST','/api/v1/auth/logout',200),uiReread:reread('/users','Iniciar sesión')};
 });
} catch(e){evidence.push({caseId:'ENV-SETUP',scope:'ENVIRONMENT',status:'FAIL',error:safe(e)});console.log('Setup FAIL '+safe(e).slice(0,260));}
finally{
 let cleanupStatus='NOT RUN';
 if(started){try{cleanup();assert.equal(checksum(),before,'Original seed rows must remain byte-for-byte equivalent');cleanupStatus='PASS'}catch(e){cleanupStatus='FAIL';evidence.push({caseId:'CLEANUP',scope:'SQL',status:'FAIL',error:safe(e)});}}
 const runnerSha=execFileSync('git',['rev-parse','HEAD'],{encoding:'utf8'}).trim();
 const imageSha=docker(['image','inspect','--format','{{index .Config.Labels "org.opencontainers.image.revision"}}','sprint-frontend-core-web:local']);
 const catalog=[...fs.readFileSync(new URL(import.meta.url),'utf8').matchAll(/caseRun\('([^']+)'/g)].map(x=>x[1]);
 for(const caseId of catalog)if(!evidence.some(c=>c.caseId===caseId))evidence.push({caseId,status:'NOT RUN',reason:'Prerequisite scenario did not complete'});
 const sources=['lib','web','assets','pubspec.yaml','pubspec.lock','analysis_options.yaml','Dockerfile.vercel','docker'];
 const sourceMatches=spawnSync('git',['diff','--quiet',imageSha,runnerSha,'--',...sources]).status===0&&spawnSync('git',['diff','--quiet','HEAD','--',...sources]).status===0;
 const report={date:new Date().toISOString(),runId,environment:'local-isolated',frontendSha:imageSha,runnerSha,frontendImageSha:imageSha,sourceMatches,backendSha:'b51b265f1a545fa915f1dd1c57ef2f5858ec6492',postgres:'16',tls:'CA confined to browser container; ignore_https_errors=false',cleanup:cleanupStatus,cases:evidence.map(c=>({...c,cleanup:cleanupStatus}))};
 if(fs.existsSync(out)){const previous=JSON.parse(fs.readFileSync(out,'utf8'));const archive=out.replace(/\.json$/, '-'+previous.runId+'.json');if(!fs.existsSync(archive))fs.copyFileSync(out,archive);}
 fs.writeFileSync(out,JSON.stringify(report,null,2)+'\n');
 console.log('RESULT '+JSON.stringify({pass:evidence.filter(c=>c.status==='PASS').length,fail:evidence.filter(c=>c.status==='FAIL').length,cleanup:cleanupStatus}));
 if(evidence.some(c=>c.status!=='PASS')||cleanupStatus!=='PASS'||!sourceMatches)process.exitCode=1;
}
