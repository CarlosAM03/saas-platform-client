import {test} from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import vm from 'node:vm';

const bootstrap=fs.readFileSync(new URL('../../web/flutter_bootstrap.js',import.meta.url),'utf8').split('{{flutter_js}}')[0];
function environment(href,fail=false){
  const writes=[];
  const events = new Map();
  const window={addEventListener:(name,handler)=>events.set(name,handler),location:{href},history:{replaceState(state,title,url){
    if(fail)throw Error('controlled failure');
    window.location.href=url;
    writes.push({state,url});
  }}};
  return {window,writes,events,execute:()=>vm.runInNewContext(bootstrap,{window,URL})};
}
test('activation is scrubbed before engine startup and original is transferred once',()=>{
  const raw='https://localhost/#/activate?code='+ 'x'.repeat(43);
  const env=environment(raw);
  env.execute();
  assert.equal(env.window.location.href,'https://localhost/#/activate');
  assert.equal(env.writes.length,1);
  assert.equal(env.writes[0].state,null);
  const take=env.window.__prospectorTakeActivationLocation;
  assert.equal(take(),raw);
  assert.equal(env.window.__prospectorTakeActivationLocation,undefined);
  assert.equal(take(),null);
});
test('invalid and duplicate codes are scrubbed before Dart validation',()=>{
  for(const query of ['?code=one&code=two','?code=%ZZ','']){
    const env=environment('https://localhost/#/activate'+query);
    env.execute();
    assert.equal(env.window.location.href,'https://localhost/#/activate');
  }
});
test('normal deep links are preserved',()=>{
  const env=environment('https://localhost/#/users/synthetic');
  env.execute();
  assert.equal(env.writes.length,0);
  assert.equal(env.window.__prospectorTakeActivationLocation,undefined);
});
test('incoming link in an existing document is scrubbed before router listeners',()=>{
  const env=environment('https://localhost/#/users/synthetic');
  env.execute();
  env.window.location.href='https://localhost/#/activate?code='+'y'.repeat(43);
  env.events.get('popstate')();
  assert.equal(env.window.location.href,'https://localhost/#/activate');
  assert.equal(env.window.__prospectorTakeActivationLocation().includes('y'.repeat(43)),true);
  env.events.get('hashchange')();
  assert.equal(env.window.__prospectorTakeActivationLocation,undefined);
});
test('failed replace aborts startup without a credential handoff',()=>{
  const env=environment('https://localhost/#/activate?code='+'x'.repeat(43),true);
  assert.throws(env.execute,/No se pudo limpiar/);
  assert.equal(env.window.__prospectorTakeActivationLocation,undefined);
});
