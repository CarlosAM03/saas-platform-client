import fs from 'node:fs';
const frontend=process.argv[2];
if(!frontend||!/^https:\/\/saas-platform-client[-.][a-z0-9.-]+\.vercel\.app$/.test(frontend))throw Error('Pass the exact verified Vercel deployment URL');
const backend='https://saas-platform-backend-l55n.onrender.com';
const cases=[];
async function probe(caseId,url,options={},check=()=>true){
 try{
  const r=await fetch(url,{...options,signal:AbortSignal.timeout(45000)});
  const body=await r.text();
  const status=check(r,body)?'PASS':'FAIL';
  const item={caseId,url,method:options.method||'GET',httpStatus:r.status,status};
  if(options.headers?.Origin)item.corsAllowOrigin=r.headers.get('access-control-allow-origin');
  if(url.includes('vercel.app')&&([401,403].includes(r.status)||new URL(r.url).hostname==='vercel.com')){item.status='BLOCKED';item.reason='Deployment authentication prevents public access';}
  cases.push(item);return {r,body,item};
 }catch(e){cases.push({caseId,url,status:'BLOCKED',reason:e.name+': '+e.message});return null;}
}
await probe('REMOTE-HEALTH-LIVE',backend+'/api/v1/health/live',{},r=>r.status===200);
await probe('REMOTE-HEALTH-READY',backend+'/api/v1/health/ready',{},r=>r.status===200);
const docs=await probe('REMOTE-SWAGGER',backend+'/api/docs-json',{},(r,body)=>{
 if(r.status!==200)return false;
 const d=JSON.parse(body);return d.info.version==='1.0.0'&&Boolean(d.paths['/api/v1/prospecting-jobs']?.post?.responses?.['503']);
});
const front=await probe('REMOTE-VERCEL-DEPLOYMENT',frontend+'/',{},r=>r.status===200);
const alias='https://saas-platform-client.vercel.app';
await probe('REMOTE-VERCEL-ALIAS',alias+'/',{},r=>r.status===200);
const bundle=await probe('REMOTE-BUNDLE-API-ORIGIN',frontend+'/main.dart.js',{},(r,body)=>r.status===200&&body.includes(backend));
await probe('REMOTE-CORS-DEPLOYMENT',backend+'/api/v1/auth/login',{method:'OPTIONS',headers:{Origin:frontend,'Access-Control-Request-Method':'POST','Access-Control-Request-Headers':'content-type'}},r=>r.headers.get('access-control-allow-origin')===frontend);
await probe('REMOTE-CORS-ALIAS',backend+'/api/v1/auth/login',{method:'OPTIONS',headers:{Origin:alias,'Access-Control-Request-Method':'POST','Access-Control-Request-Headers':'content-type'}},r=>r.headers.get('access-control-allow-origin')===alias);
await probe('REMOTE-CORS-DENIED',backend+'/api/v1/auth/login',{method:'OPTIONS',headers:{Origin:'https://sprint-unapproved.example.invalid','Access-Control-Request-Method':'POST'}},r=>!r.headers.get('access-control-allow-origin'));
cases.push({caseId:'REMOTE-AUTHENTICATED-UI',status:'NOT RUN',reason:'Executed separately by remote-ui.mjs with protected stdin; see remote-ui.json. Public smoke never handles credentials.'});
cases.push({caseId:'REMOTE-BACKEND-SHA',status:'BLOCKED',reason:'GitHub exposes no Backend deployment record; health/Swagger do not prove the Render source SHA.'});
const output={date:new Date().toISOString(),scope:'Public read-only smoke, no database access, no deployment and no writes',frontendDeploymentSha:null,githubReportedProductionSha:'7731649a2c69b45cb9776d02de4a6105d6fd9886',frontendDeploymentSource:'User supplied frontend URL; GitHub deployment7373752531 alone does not prove its alias mapping',backendDeploymentSha:null,cases};
fs.writeFileSync('codex/evidencias/remote-smoke.json',JSON.stringify(output,null,2)+'\n');
console.log(JSON.stringify(cases,null,2));
