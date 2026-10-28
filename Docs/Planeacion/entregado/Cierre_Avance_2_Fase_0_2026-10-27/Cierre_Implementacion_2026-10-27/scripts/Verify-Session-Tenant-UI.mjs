import fs from 'node:fs';
import { spawnSync } from 'node:child_process';
import assert from 'node:assert/strict';
const [container, envPath, out, port = '18443'] = process.argv.slice(2);
const cfg = Object.fromEntries(
  fs
    .readFileSync(envPath, 'utf8')
    .trim()
    .split(/\r?\n/)
    .map((l) => [l.slice(0, l.indexOf('=')), l.slice(l.indexOf('=') + 1)]),
);
const evidence = [];
const base = 'https://localhost:' + port;
function act(d) {
  const r = spawnSync(
    'docker',
    [
      'exec',
      '-i',
      container,
      'python',
      '-c',
      "import sys,urllib.request;print(urllib.request.urlopen(urllib.request.Request('http://127.0.0.1:6090',data=sys.stdin.buffer.read()),timeout=100).read().decode())",
    ],
    { input: JSON.stringify(d), encoding: 'utf8', timeout: 110000 },
  );
  if (r.status) throw new Error(r.stderr);
  const v = JSON.parse(r.stdout);
  if (!v.ok) throw new Error(v.error);
  return v.data;
}
function record(name, s) {
  const clean = JSON.stringify(s).replaceAll(
    cfg.LOCAL_DEMO_PASSWORD,
    '[REDACTED]',
  );
  evidence.push({ name, data: JSON.parse(clean) });
  console.log(name + ' PASS');
}
function login(email) {
  let s = act({ action: 'goto', url: base + '/#/login' });
  if (s.url.includes('session-expired')) {
    act({action:'click',name:'Sesión expirada: volver a entrar',exact:true});
  } else if (!s.url.includes('/login')) {
    act({ action: 'click', name: 'Cerrar sesión', exact: true });
  }
  act({ action: 'fill', name: 'Correo electrónico', value: email });
  act({ action: 'fill', name: 'Contraseña', value: cfg.LOCAL_DEMO_PASSWORD });
  return act({ action: 'click', name: 'Iniciar sesión', wait: 3 });
}
let adminToken,originalStatus;async function api(path,method='GET',body,token){const r=await fetch('http://127.0.0.1:18441/api/v1'+path,{method,headers:{Connection:'close','Content-Type':'application/json',...(token?{Authorization:'Bearer '+token}:{})},body:body?JSON.stringify(body):undefined});if(!r.ok)throw new Error('Local API '+path+' returned '+r.status);return (await r.json()).data;}try{
 const adminUi=login('admin@demo.example');assert(adminUi.url.includes('select-tenant'));act({action:'click',name:'Demo Norte demo-norte',exact:true,wait:2});const north=act({action:'goto',url:base+'/#/campaigns'});assert(north.aria.includes('Demo Norte'));record('ADMIN selected A',north);act({action:'click',name:'Cambiar organización'});act({action:'click',name:'Demo Sur demo-sur',exact:true,wait:2});const south=act({action:'goto',url:base+'/#/campaigns'});assert(south.aria.includes('Demo Sur'));assert(!south.aria.includes('Demo Norte'));record('ADMIN changed A to B; previous data cleared',south);act({action:'screenshot',name:'core-admin-switch-to-b.png'});act({action:'click',name:'Cerrar sesión',exact:true});
 const owner=login('owner.demo-norte@demo.example');assert(owner.url.includes('dashboard'));const auth=await api('/auth/login','POST',{email:'admin@demo.example',password:cfg.LOCAL_DEMO_PASSWORD});const selected=await api('/auth/select-tenant','POST',{tenantId:'demo-tenant-norte'},auth.accessToken);adminToken=selected.accessToken;const old=await api('/users/demo-user-demo-norte-owner','GET',undefined,adminToken);originalStatus=old.status;
 try{await api('/users/demo-user-demo-norte-owner','PATCH',{status:'INACTIVO'},adminToken);act({action:'goto',url:base+'/#/campaigns'});const expired=act({action:'wait',seconds:2});assert(expired.url.includes('session-expired'));record('real authenticated 401 clears session',expired);act({action:'screenshot',name:'core-real-session-expired.png'});}finally{await api('/users/demo-user-demo-norte-owner','PATCH',{status:originalStatus},adminToken);originalStatus=undefined;}
 act({action:'click',name:'Sesión expirada: volver a entrar',exact:true});const restored=login('owner.demo-norte@demo.example');assert(restored.url.includes('dashboard'));record('restored reserved demo status; fresh login succeeds',restored);
 fs.writeFileSync(out,JSON.stringify({date:new Date().toISOString(),pass:true,method:'401 enforced by global inactive demo user; expiry/late responses additionally covered by widget suites',evidence},null,2));console.log('SESSION_AND_TENANT_UI_PASS');
}catch(e){if(adminToken&&originalStatus)await api('/users/demo-user-demo-norte-owner','PATCH',{status:originalStatus},adminToken).catch(()=>{});fs.writeFileSync(out,JSON.stringify({date:new Date().toISOString(),pass:false,error:String(e),cause:e.cause?.code??e.cause?.message,evidence},null,2));console.error(String(e));process.exitCode=1;}
