import fs from 'node:fs';
import crypto from 'node:crypto';
import {execFileSync} from 'node:child_process';
import assert from 'node:assert/strict';

const normalize = value => Array.isArray(value) ? value.map(normalize)
  : value !== null && typeof value === 'object'
    ? Object.fromEntries(Object.keys(value).sort().map(key => [key, normalize(value[key])])) : value;
const hash = value => crypto.createHash('sha256').update(JSON.stringify(normalize(value))).digest('hex');
const reference = JSON.parse(fs.readFileSync('codex/06_HANDOFF_ANDRE/openapi-served-3b5eec6.json', 'utf8'));
const response = await fetch('http://127.0.0.1:18741/api/docs-json');
assert.equal(response.status, 200);
const served = await response.json();
assert.equal(hash(served), hash(reference), 'Served contract differs from the immutable handoff');
const operations = fs.readFileSync('codex/06_HANDOFF_ANDRE/02_MATRIZ_API_FLUTTER.csv', 'utf8').split(/\r?\n/)
  .map(line => line.match(/^"[^"]*","(GET|POST|PATCH|PUT|DELETE)","([^"]+)"/)).filter(Boolean)
  .map(match => ({method: match[1], path: match[2]}));
assert.equal(operations.length, 25);
for (const {method, path} of operations) assert(served.paths[path]?.[method.toLowerCase()], `Missing ${method} ${path}`);
const report = {
  date: new Date().toISOString(),
  frontendSha: execFileSync('git', ['rev-parse', 'HEAD'], {encoding: 'utf8'}).trim(),
  backendSha: fs.readFileSync('codex/frontend-cp/.local/backend-sha.txt', 'utf8').trim(),
  command: 'node tool/sprint-cp/verify-contract.mjs', fixture: 'Pinned isolated synthetic backend, onboarding disabled',
  expected: 'Same normalized served OpenAPI as immutable handoff, all 25 method/path pairs',
  observed: {normalizedSha256: hash(served), paths: Object.keys(served.paths).length, schemas: Object.keys(served.components.schemas).length, verifiedOperations: operations.length},
  status: 'PASS', limitations: 'Contract equivalence verifies schema and documented operations, not every runtime semantic.'
};
fs.mkdirSync('codex/frontend-cp/.local/recibos', {recursive: true});
fs.writeFileSync('codex/frontend-cp/.local/recibos/CONTRATO.json', JSON.stringify(report, null, 2) + '\n');
console.log(`Contract PASS: ${report.observed.paths} paths, ${report.observed.schemas} schemas, ${operations.length} matrix operations`);
