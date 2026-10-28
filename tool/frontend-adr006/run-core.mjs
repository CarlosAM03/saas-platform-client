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
  fill('Correo del OWNER',runId+'-created-owner@example.invalid');
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
const extra=String.raw`DELETE FROM activation_links WHERE onboarding_id IN(SELECT id FROM tenant_onboardings WHERE tenant_id IN(SELECT id FROM tenants WHERE slug='+q(runId+'-created-tenant')+')); DELETE FROM first_access_challenges WHERE onboarding_id IN(SELECT id FROM tenant_onboardings WHERE tenant_id IN(SELECT id FROM tenants WHERE slug='+q(runId+'-created-tenant')+')); DELETE FROM delivery_attempts WHERE onboarding_id IN(SELECT id FROM tenant_onboardings WHERE tenant_id IN(SELECT id FROM tenants WHERE slug='+q(runId+'-created-tenant')+')); DELETE FROM tenant_onboardings WHERE tenant_id IN(SELECT id FROM tenants WHERE slug='+q(runId+'-created-tenant')+'); DELETE FROM user_tenants WHERE tenant_id IN(SELECT id FROM tenants WHERE slug='+q(runId+'-created-tenant')+'); DELETE FROM users WHERE email='+q(runId+'-created-owner@example.invalid')+'; `;
source=source.replace("sql('BEGIN; DELETE FROM roles","sql('BEGIN; "+extra+"DELETE FROM roles");
const file=state+'/core-regression.mjs';
fs.writeFileSync(file,source);
const result=spawnSync(process.execPath,[file,state,'codex/frontend-adr006/evidencias/core-e2e.json'],{stdio:'inherit'});
process.exitCode=result.status??1;
