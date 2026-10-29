// Dependency-free CDP runner for installed Edge. Uses only synthetic responses.
import fs from 'node:fs';
import path from 'node:path';
import http from 'node:http';
import crypto from 'node:crypto';
import assert from 'node:assert/strict';
import {spawn,execFileSync} from 'node:child_process';
const root=path.resolve('build/web'),base='http://127.0.0.1:18743';
const code=crypto.randomBytes(32).toString('base64url');
const challenge=crypto.randomBytes(32).toString('base64url');
const password=crypto.randomBytes(16).toString('hex')+'Aa1!';
const cases=[],observed=[];
const mime={'.html':'text/html','.js':'application/javascript','.json':'application/json','.wasm':'application/wasm','.ttf':'font/ttf','.png':'image/png'};
const server=http.createServer((req,res)=>{
 const relative=decodeURIComponent(new URL(req.url,base).pathname);
 const file=path.resolve(root,'.'+(relative==='/'?'/index.html':relative));
 if(!file.startsWith(root+path.sep)){res.writeHead(403).end();return;}
 fs.readFile(file,(error,data)=>{if(error){res.writeHead(404).end();return;}res.writeHead(200,{'Content-Type':mime[path.extname(file)]||'application/octet-stream','Cache-Control':'no-store'}).end(data);});
});
await new Promise(resolve=>server.listen(18743,'127.0.0.1',resolve));
const edge=spawn('C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe',[
 '--headless=new','--remote-debugging-port=18744','--no-first-run',
 '--user-data-dir='+path.resolve('codex/frontend-adr006/.local/native-edge-'+crypto.randomBytes(5).toString('hex')),
 'about:blank',
],{windowsHide:true,stdio:'ignore'});
let socket, debugNames=async()=>'';
try{
 let pages;
 for(let i=0;i<100;i++){
  try{pages=await (await fetch('http://127.0.0.1:18744/json')).json();if(pages.some(p=>p.type==='page'))break;}catch{}
  await new Promise(resolve=>setTimeout(resolve,200));
 }
 assert(pages?.some(p=>p.type==='page'),'Edge CDP readiness');
 socket=new WebSocket(pages.find(p=>p.type==='page').webSocketDebuggerUrl);
 await new Promise((resolve,reject)=>{socket.addEventListener('open',resolve,{once:true});socket.addEventListener('error',reject,{once:true});});
 let sequence=0;const pending=new Map();
 const send=(method,params={})=>new Promise((resolve,reject)=>{
  const id=++sequence;pending.set(id,{resolve,reject});socket.send(JSON.stringify({id,method,params}));
 });
 const fulfill=async(event)=>{
  const req=event.request;
  let body={success:true,data:{}},status=200;
  if(req.method==='OPTIONS'){status=204;}
  else if(req.url.includes('/redeem-first-access')){
   const data=JSON.parse(req.postData);
   observed.push({operation:'redeem',codePreserved:data.activationToken===code,bearerPresent:Object.keys(req.headers).some(k=>k.toLowerCase()==='authorization')});
   body={success:true,data:{action:'CHANGE_PASSWORD_REQUIRED',firstAccessToken:challenge,expiresAt:new Date(Date.now()+900000).toISOString()}};
  }else if(req.url.includes('/complete-first-access')){
   const data=JSON.parse(req.postData);
   observed.push({operation:'complete',challengePreserved:data.firstAccessToken===challenge,passwordPreserved:data.newPassword===password});
   body={success:true,data:{action:'LOGIN_REQUIRED'}};
  }else {status=401;body={success:false,error:{code:'UNAUTHORIZED',message:'synthetic',details:{}}};}
  await send('Fetch.fulfillRequest',{requestId:event.requestId,responseCode:status,responseHeaders:[
   {name:'Content-Type',value:'application/json'},{name:'Cache-Control',value:'no-store'},
   {name:'Access-Control-Allow-Origin',value:base},{name:'Access-Control-Allow-Headers',value:'content-type,authorization'},
   {name:'Access-Control-Allow-Methods',value:'POST,GET,OPTIONS'},
  ],body:Buffer.from(status===204?'':JSON.stringify(body)).toString('base64')});
 };
 socket.addEventListener('message',event=>{
  const value=JSON.parse(event.data);
  if(value.id){const p=pending.get(value.id);pending.delete(value.id);if(value.error)p?.reject(Error(value.error.message));else p?.resolve(value.result);}
  else if(value.method==='Fetch.requestPaused')fulfill(value.params).catch(()=>{});
 });
 await send('Page.enable');await send('Runtime.enable');
 await send('Fetch.enable',{patterns:[{urlPattern:'*/api/v1/*',requestStage:'Request'}]});
 const evaluate=async(expression)=>(await send('Runtime.evaluate',{expression,returnByValue:true,awaitPromise:true})).result?.value;
 const wait=async(fn,label)=>{
  for(let i=0;i<160;i++){if(await fn())return;await new Promise(resolve=>setTimeout(resolve,150));}
  throw Error('Timed out: '+label);
 };
 await send('Page.addScriptToEvaluateOnNewDocument',{source:`
  window.__g1Writes=[];
  for(const name of ['replaceState','pushState']){
   const original=history[name].bind(history);
   history[name]=function(state,title,url){
    window.__g1Writes.push({method:name,secretInUrl:String(url).includes('code='),secretInState:JSON.stringify(state||{}).includes('code=')});
    return original(state,title,url);
   };
  }
 `});
 await send('Page.navigate',{url:base+'/#/activate?code='+code});
 await wait(()=>evaluate("location.hash==='#/activate'"),'clean activation URL');
 await wait(()=>evaluate("!!document.querySelector('flt-semantics-placeholder') || !!document.querySelector('flt-semantics-host')"),'Flutter semantics');
 await evaluate("document.querySelector('flt-semantics-placeholder')?.click()");
 const names=async()=>{const tree=await send('Accessibility.getFullAXTree');return tree.nodes.map(n=>n.name?.value||'').join('\n');};
 debugNames=names;
 await wait(async()=>(await names()).includes('Nueva contraseña'),'password form');
 assert(observed.some(r=>r.operation==='redeem'&&r.codePreserved&&!r.bearerPresent));
 const writes=await evaluate('window.__g1Writes');
 assert(!writes.some(w=>w.secretInUrl||w.secretInState));
 cases.push({caseId:'NATIVE-BOOTSTRAP-HANDOFF',status:'PASS',scope:'REAL_EDGE_MOCK_HTTP'});
 const input=await evaluate(`(()=>{
  const e=[...document.querySelectorAll('input')].find(e=>e.type==='password');
  if(!e)return null;const r=e.getBoundingClientRect();return {x:r.x+r.width/2,y:r.y+r.height/2};
 })()`);
 assert(input,'Password DOM input');
 await send('Input.dispatchMouseEvent',{type:'mousePressed',button:'left',clickCount:1,...input});
 await send('Input.dispatchMouseEvent',{type:'mouseReleased',button:'left',clickCount:1,...input});
 await wait(()=>evaluate("document.activeElement?.className.includes('flt-text-editing')"),'Flutter editing element focus');
 await send('Input.insertText',{text:password});
 const enteredLength=await evaluate("document.activeElement?.value.length");
 observed.push({operation:'input',expectedLength:password.length,enteredLength});
 const ax=await send('Accessibility.getFullAXTree');
 const submit=ax.nodes.find(n=>n.role?.value==='button'&&n.name?.value==='Establecer contraseña');
 assert(submit?.backendDOMNodeId,'Accessible submit button');
 await send('DOM.scrollIntoViewIfNeeded',{backendNodeId:submit.backendDOMNodeId});
 const {model}=await send('DOM.getBoxModel',{backendNodeId:submit.backendDOMNodeId});
 const point={x:(model.border[0]+model.border[4])/2,y:(model.border[1]+model.border[5])/2};
 await send('Input.dispatchMouseEvent',{type:'mousePressed',button:'left',clickCount:1,...point});
 await send('Input.dispatchMouseEvent',{type:'mouseReleased',button:'left',clickCount:1,...point});
 await wait(async()=>(await names()).includes('Iniciar sesión'),'LOGIN_REQUIRED navigation');
 assert(observed.some(r=>r.operation==='complete'&&r.challengePreserved&&r.passwordPreserved));
 cases.push({caseId:'NATIVE-COMPLETE-LOGIN-REQUIRED',status:'PASS',scope:'REAL_EDGE_MOCK_HTTP'});
}catch(error){
 const safe=value=>String(value).replaceAll(code,'[REDACTED]').replaceAll(challenge,'[REDACTED]').replaceAll(password,'[REDACTED]');
 cases.push({caseId:'NATIVE-BROWSER',status:'FAIL',error:safe(error).slice(0,300),accessibleState:safe(await debugNames()).slice(0,1400)});
}finally{
 socket?.close();edge.kill();server.close();
 const report={date:new Date().toISOString(),frontendSha:execFileSync('git',['rev-parse','HEAD'],{encoding:'utf8'}).trim(),browser:'installed Edge headless, CDP, normal host sandbox',scope:'MOCK_HTTP_NOT_E2E',cases,observed};
 fs.writeFileSync('codex/frontend-adr006/evidencias/native-browser.json',JSON.stringify(report,null,2)+'\n');
 for(const item of cases)console.log(item.caseId+' '+item.status+(item.error?' '+item.error:''));
 if(cases.some(item=>item.status!=='PASS'))process.exitCode=1;
}
