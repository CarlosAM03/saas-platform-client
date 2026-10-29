const fs=require('node:fs');
const yaml=require('node:module').createRequire('/app/package.json')('js-yaml');
const crypto=require('node:crypto');
const core=yaml.load(fs.readFileSync('/app/Docs/Contracts/platform-api.v1.yaml','utf8'));
const approved=yaml.load(fs.readFileSync('/app/Docs/Contracts/platform-api.tenant-registration.approved.yaml','utf8'));
const consumer=yaml.load(fs.readFileSync('/consumer/Contracts/platform-api.tenant-registration.approved.yaml','utf8'));
const disabled=new Set(['POST /api/v1/prospecting-jobs','POST /api/v1/prospecting-jobs/{id}/cancel','POST /api/v1/prospecting-jobs/{id}/persist','GET /api/v1/prospecting-jobs/{id}/export']);
function normalize(value,document,seen=new Set()){
 if(Array.isArray(value))return value.map(item=>normalize(item,document,seen));
 if(!value||typeof value!=='object')return value;
 if(value.in&&value.name&&value.required===undefined)value={required:false,...value};
 if(value.$ref&&!seen.has(value.$ref)){
  const next=new Set(seen);next.add(value.$ref);
  const resolved=value.$ref.split('/').slice(1).reduce((current,key)=>current[key],document);
  return normalize(resolved,document,next);
 }
 return Object.fromEntries(Object.keys(value).sort().filter(key=>!['description','summary','example','examples','title','operationId','tags'].includes(key)&&!key.startsWith('x-')).map(key=>[key,normalize(value[key],document,seen)]));
}
const shape=(value,document)=>JSON.stringify(normalize(value,document));
(async()=>{
 const runtime=await(await fetch('http://api:3000/api/docs-json',{signal:AbortSignal.timeout(10000)})).json();
 const rows=[];
 for(const [path,item] of Object.entries(approved.paths)){
  for(const method of ['get','post','patch','delete','put']){
   const operation=item[method];if(!operation)continue;
   const name=method.toUpperCase()+' '+path,r=runtime.paths[path]?.[method],c=consumer.paths[path]?.[method];
   const request=o=>({body:o?.requestBody,parameters:o?.parameters});
   const responses=Object.keys(operation.responses);
   const baselineRequest=JSON.parse(JSON.stringify(request(operation)));
   let preservedCoreSpecialization=false;
   if(name==='GET /api/v1/prospecting-jobs'){
    baselineRequest.parameters=baselineRequest.parameters.map(parameter=>parameter.$ref==='#/components/parameters/SortBy'?{name:'sortBy',in:'query',schema:{type:'string',default:'createdAt',enum:['createdAt','updatedAt','startedAt','completedAt','status','id']}}:parameter);
    preservedCoreSpecialization=shape(baselineRequest,approved)===shape(request(r),runtime);
   }
   rows.push({
    operation:name,scope:core.paths[path]?.[method]?'CORE':'ADR006',runtimePresent:!!r,
    consumerRequestParity:shape(request(operation),approved)===shape(request(c),consumer),
    runtimeRequestParity:shape(request(operation),approved)===shape(request(r),runtime)||preservedCoreSpecialization,
    preservedCoreSpecialization:preservedCoreSpecialization?'b51b265 deployment-document.ts: unchanged Jobs sortBy refinement':undefined,
    requestDifference:shape(request(operation),approved)===shape(request(r),runtime)?undefined:{approved:normalize(request(operation),approved),runtime:normalize(request(r),runtime)},
    authorization:operation.security??approved.security??[],
    runtimeAuthorization:r?.security??runtime.security??[],
    authorizationParity:shape(operation.security??approved.security??[],approved)===shape(r?.security??runtime.security??[],runtime),
    approvedHttp:responses,runtimeHttp:Object.keys(r?.responses||{}),
    intended503:disabled.has(name),
    responseSchemaParity:disabled.has(name)?null:responses.filter(status=>r?.responses?.[status]).every(status=>shape(operation.responses[status]?.content,approved)===shape(r.responses[status]?.content,runtime)),
   });
  }
 }
 const report={date:new Date().toISOString(),backendSha:'5e214420394101ae7079f8e844cc759b01cce2a3',coreOperations:rows.filter(r=>r.scope==='CORE').length,adr006Operations:rows.filter(r=>r.scope==='ADR006').length,runtimeOperations:Object.values(runtime.paths).reduce((n,item)=>n+['get','post','patch','delete','put'].filter(m=>item[m]).length,0),approvedSha256:crypto.createHash('sha256').update(fs.readFileSync('/app/Docs/Contracts/platform-api.tenant-registration.approved.yaml')).digest('hex'),operations:rows};
 fs.writeFileSync('/output/contract-38.json',JSON.stringify(report,null,2)+'\n');
 console.log(JSON.stringify({core:report.coreOperations,adr006:report.adr006Operations,runtime:report.runtimeOperations,missing:rows.filter(r=>!r.runtimePresent).map(r=>r.operation),requestDifferences:rows.filter(r=>!r.runtimeRequestParity||!r.consumerRequestParity).map(r=>r.operation),responseDifferences:rows.filter(r=>r.responseSchemaParity===false).map(r=>r.operation)}));
 if(rows.length!==38||report.coreOperations!==33||report.adr006Operations!==5||rows.some(r=>!r.runtimePresent||!r.consumerRequestParity||!r.runtimeRequestParity||!r.authorizationParity||r.responseSchemaParity===false||r.intended503&&!r.runtimeHttp.includes('503')))process.exitCode=1;
})().catch(()=>{console.log('Contract audit failed without publishing payloads');process.exitCode=1});
