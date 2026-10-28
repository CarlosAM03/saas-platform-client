import fs from 'node:fs';
import path from 'node:path';
import {createRequire} from 'node:module';
import {execFileSync} from 'node:child_process';
let [backend, ref = 'origin/main'] = process.argv.slice(2);
backend = backend && path.resolve(fs.realpathSync('.'), backend);
if (!backend) throw Error('Usage: node tool/sprint/contract-audit.mjs BACKEND [REF]');
const yaml = createRequire(path.resolve(backend, 'package.json'))('js-yaml');
const git = (...a) => execFileSync('git', ['-C', backend, ...a], {encoding:'utf8'}).trim();
const target = yaml.load(git('show', ref+':Docs/Contracts/platform-api.v1.yaml'));
const client = yaml.load(fs.readFileSync('Docs/Contracts/platform-api.v1.yaml','utf8'));
const disabled = new Set(['POST /api/v1/prospecting-jobs','POST /api/v1/prospecting-jobs/{id}/cancel','POST /api/v1/prospecting-jobs/{id}/persist','GET /api/v1/prospecting-jobs/{id}/export']);
const rows = [];
for (const [route,item] of Object.entries(target.paths)) for (const method of ['get','post','patch','delete','put']) {
 if (!item[method]) continue;
 const op = method.toUpperCase()+' '+route, t=item[method], c=client.paths[route]?.[method];
 const request = x => JSON.stringify({body:x?.requestBody,parameters:x?.parameters});
 rows.push({operation:op,operationId:t.operationId,availability:disabled.has(op)?'DISABLED_503':'AVAILABLE',requestParity:request(t)===request(c),targetResponses:Object.keys(t.responses),clientResponses:Object.keys(c?.responses??{}),targetPreserved:Boolean(c?.['x-target-responses']),runtime:'NOT RUN'});
}
const componentDifferences = Object.keys(target.components.schemas).filter(k=>JSON.stringify(target.components.schemas[k])!==JSON.stringify(client.components.schemas[k]));
fs.mkdirSync('codex/evidencias',{recursive:true});
fs.writeFileSync('codex/evidencias/contract-audit.json',JSON.stringify({date:new Date().toISOString(),backendSha:git('rev-parse',ref),operations:rows,componentDifferences},null,2)+'\n');
fs.writeFileSync('codex/evidencias/matriz-contrato-1a1.md','# Matriz contractual Core V1\n\nBackend '+git('rev-parse',ref)+'. AVAILABLE describe código inspeccionado y no certifica runtime. Deployment-document.ts limita cuatro operaciones Jobs a503 y conserva consultas.\n\n| Operación | Implementación | Request equivalente | HTTP objetivo | HTTP Flutter | Runtime |\n|---|---|---|---|---|---|\n'+rows.map(r=>'| '+[r.operation,r.availability,r.requestParity?'PASS':'FAIL',r.targetResponses.join(','),r.clientResponses.join(','),r.runtime].join(' | ')+' |').join('\n')+'\n');
fs.writeFileSync('codex/evidencias/contract-diff.md','# Objetivo / implementado / Flutter\n\n'+rows.length+' operaciones objetivo. Jobs futuras conservadas como x-target-responses, no éxitos reales. Diferencias de schemas: '+(componentDifferences.join(', ')||'ninguna')+'. Requests diferentes: '+(rows.filter(r=>!r.requestParity).map(r=>r.operation).join('; ')||'ninguno')+'.\n');
console.log(JSON.stringify({operations:rows.length,requestDifferences:rows.filter(r=>!r.requestParity).length,componentDifferences}));
