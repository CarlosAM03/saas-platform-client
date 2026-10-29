// Reuse the established Core UI/SQL suite in an independent G1 stack.
import fs from 'node:fs';
import {spawnSync} from 'node:child_process';
const state='codex/frontend-adr006/.local';
let source=fs.readFileSync('tool/sprint/e2e.mjs','utf8')
  .replaceAll('prospector-frontend-sprint','prospector-frontend-g1')
  .replaceAll('https://localhost:18543','https://localhost:18643')
  .replaceAll('frontend-sprint-exclusive','frontend-g1-exclusive')
  .replaceAll('sprint-frontend-core-web:local','prospector-frontend-g1-web:local')
  .replaceAll('b51b265f1a545fa915f1dd1c57ef2f5858ec6492',fs.readFileSync(state+'/backend-sha.txt','utf8').trim());
// /tenants/new now has the approved assisted registration UI. Keep the real
// UI + HTTP + SQL + reread chain, adding the first OWNER/onboarding assertions.
const begin=source.indexOf(" await caseRun('TEN-CREATE-ADMIN'");
const end=source.indexOf(" await caseRun('CAM-DELETE-ADMIN'",begin);
if(begin<0||end<0)throw Error('Core suite changed: review the adapter');
source=source.slice(0,begin)+`
 await caseRun('TEN-CREATE-ADMIN','UI_TO_DB','admin',async()=>{
  go('/tenants/new','Se creará la organización');
  fill('Nombre de empresa',runId+' created-tenant');
  fill('Slug',runId+'-created-tenant');
  fill('Nombre del OWNER',runId+' created-owner');
  fill('Correo del OWNER',runId+'-onboarding-owner@example.invalid');
  const c=cursor();click('Registrar organización');text('Organización registrada.');
  const http=httpAfter(c,'POST','/api/v1/tenants/register',201);
  const id=sql('SELECT id FROM tenants WHERE slug='+q(runId+'-created-tenant')+';');
  return{http,dbAssertions:[
   sqlAssert('EXISTS(SELECT 1 FROM tenants WHERE id='+q(id)+')','Tenant persisted'),
   sqlAssert('(SELECT count(*) FROM roles WHERE tenant_id='+q(id)+')=2','Both tenant roles persisted'),
   sqlAssert('EXISTS(SELECT 1 FROM tenant_onboardings WHERE tenant_id='+q(id)+')','First OWNER onboarding persisted')
  ],uiReread:reread('/tenants/'+id,runId+' created-tenant')};
 });
`+source.slice(end);
const extra=String.raw`DELETE FROM first_access_challenges WHERE onboarding_id IN(SELECT id FROM tenant_onboardings WHERE tenant_id IN(SELECT id FROM tenants WHERE slug='+q(runId+'-created-tenant')+')); DELETE FROM activation_links WHERE onboarding_id IN(SELECT id FROM tenant_onboardings WHERE tenant_id IN(SELECT id FROM tenants WHERE slug='+q(runId+'-created-tenant')+')); DELETE FROM delivery_attempts WHERE onboarding_id IN(SELECT id FROM tenant_onboardings WHERE tenant_id IN(SELECT id FROM tenants WHERE slug='+q(runId+'-created-tenant')+')); DELETE FROM tenant_onboardings WHERE tenant_id IN(SELECT id FROM tenants WHERE slug='+q(runId+'-created-tenant')+'); DELETE FROM user_tenants WHERE tenant_id IN(SELECT id FROM tenants WHERE slug='+q(runId+'-created-tenant')+'); DELETE FROM users WHERE email='+q(runId+'-onboarding-owner@example.invalid')+'; `;
source=source.replace("sql('BEGIN; DELETE FROM roles","sql('BEGIN; "+extra+"DELETE FROM roles");
const file=state+'/core-regression.mjs';
const staleBegin=source.indexOf(" await caseRun('JWT-OWNER-SNAPSHOT'");
const staleEnd=source.indexOf(" await caseRun('AUTH-MEMBER'",staleBegin);
if(staleBegin<0||staleEnd<0)throw Error('Review changed Core authorization scenario');
// D4 explicitly supersedes snapshot authority only for sensitive Users writes.
source=source.slice(0,staleBegin)+`
 await caseRun('JWT-OWNER-SENSITIVE-LIVE-403','UI_TO_DB','owner',async()=>{
  sql('UPDATE user_tenants SET role_id='+q(a+'MEMBER')+' WHERE user_id='+q(actors.owner)+' AND tenant_id='+q(a)+';');
  try {
   const beforeUsers=sql('SELECT count(*) FROM users;'), beforeMemberships=sql('SELECT count(*) FROM user_tenants;');
   go('/users/new','El usuario se crea como MEMBER');
   fill('Nombre',runId+' stale-owner');fill('Correo electrónico',email('stale-owner'));fill('Contraseña',cfg.LOCAL_DEMO_PASSWORD+'Aa1!');
   const c=cursor();click('Guardar');text('No tienes permisos para realizar esta acción.');
   const http=httpAfter(c,'POST','/api/v1/users',403);
   assert.equal(sql('SELECT count(*) FROM users;'),beforeUsers);
   assert.equal(sql('SELECT count(*) FROM user_tenants;'),beforeMemberships);
   return{http,dbAssertions:['D4 denies stale OWNER authority without partial User or membership writes'],uiReread:reread('/dashboard','Resumen de la organización actual'),sessionPreserved:true};
  } finally {sql('UPDATE user_tenants SET role_id='+q(a+'OWNER')+' WHERE user_id='+q(actors.owner)+' AND tenant_id='+q(a)+';')}
 });
`+source.slice(staleEnd);
const navigation=process.argv.includes('--navigation');
if(navigation){
 const from=source.indexOf(" await caseRun('AUTH-OWNER'");
 const to=source.indexOf("} catch(e){evidence.push",from);
 if(from<0||to<0)throw Error('Review navigation adapter boundaries');
 source=source.slice(0,from)+`
 await caseRun('CORE-PAGINATION-SEARCH-SORT-RESTORE','UI_HTTP_SQL','owner',async()=>{
  for(let i=0;i<25;i++){
   const id=runId+'page'+i;
   sql('INSERT INTO users(id,name,email,password_hash,created_at,updated_at) SELECT '+[q(id),q(runId+' paging'+i),q(email('paging-'+i)),"password_hash",'now()','now()'].join(',')+" FROM users WHERE email='admin@demo.example'; INSERT INTO user_tenants(user_id,tenant_id,role_id) VALUES ("+[q(id),q(a),q(a+'MEMBER')].join(',')+');');
  }
  await login('owner');go('/users','Página 1');
  const count=Number(sql('SELECT count(*) FROM user_tenants WHERE tenant_id='+q(a)+';'));
  assert(count>20);let c=cursor();click('Página siguiente');text('Página 2');
  const secondPage=httpAfter(c,'GET','/api/v1/users',200);
  click('Página anterior');text('Página 1');
  fill('Buscar',runId+' paging24');c=cursor();click('Buscar',{role:'button'});text(runId+' paging24');text('1 registros');
  const searched=httpAfter(c,'GET','/api/v1/users',200);
  click('Cambiar orden');text(runId+' paging24');
  act({action:'reload'});text('Página 1');text('Cerrar sesión');
  return{secondPage,searched,dbAssertions:['25 synthetic members produce more than one real API page','Search returns one own-tenant member'],restoredSession:true,uiReread:'PASS'};
 });
`+source.slice(to);
}
fs.writeFileSync(file,source);
const result=spawnSync(process.execPath,[file,state,navigation?'codex/frontend-adr006/evidencias/core-navigation.json':'codex/frontend-adr006/evidencias/core-e2e.json',...process.argv.slice(2).filter(arg=>arg!=='--navigation')],{stdio:'inherit'});
process.exitCode=result.status??1;
