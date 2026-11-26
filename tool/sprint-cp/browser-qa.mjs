import assert from 'node:assert/strict';
import {execFileSync} from 'node:child_process';
import fs from 'node:fs/promises';
import http from 'node:http';
import path from 'node:path';
import {chromium} from '../../codex/frontend-cp/.local/browser/node_modules/playwright-core/index.mjs';

const [buildPath, outputPath] = process.argv.slice(2);
assert(buildPath && outputPath && process.env.CHROMIUM_EXECUTABLE,
  'Provide the release build, receipt directory and CHROMIUM_EXECUTABLE.');
const build = path.resolve(buildPath);
const output = path.resolve(outputPath);
const lab = path.resolve('codex/frontend-cp/.local');
const origin = 'http://127.0.0.1:18742';
const apiOrigin = 'http://127.0.0.1:18741';
const owner = 'owner.demo-norte@demo.example';
const tenant = 'demo-tenant-norte';
const password = (await fs.readFile(path.join(lab, 'lab.env'), 'utf8'))
  .match(/^CP_SEED_PASSWORD=([a-f0-9]+)$/m)?.[1];
assert(password, 'Synthetic seed password missing.');
const frontendSha = execFileSync('git', ['rev-parse', process.env.CP_BUILD_SHA ?? 'HEAD'], {
  encoding: 'utf8',
}).trim();
const backendSha = (await fs.readFile(path.join(lab, 'backend-sha.txt'), 'utf8')).trim();
assert.equal(backendSha, '779fc7885faefdfe9e3cb0f3fee86810d96d2711');

async function post(endpoint, data, token) {
  const response = await fetch(apiOrigin + '/api/v1/' + endpoint, {
    method: 'POST',
    headers: {
      'content-type': 'application/json',
      ...(token && {authorization: 'Bearer ' + token}),
    },
    body: JSON.stringify(data),
  });
  assert(response.ok, 'Fixture POST ' + endpoint + ' returned ' + response.status);
  return (await response.json()).data;
}

const login = await post('auth/login', {email: owner, password});
const session = await post('auth/select-tenant', {tenantId: tenant}, login.accessToken);
const runId = Date.now();
const campaign = await post('campaigns', {name: 'QA Chromium ' + runId}, session.accessToken);
const prospect = await post('prospects', {
  campaignId: campaign.id,
  name: 'Comercio sintético ' + runId,
}, session.accessToken);
assert(prospect.id);

const contentType = {
  '.html': 'text/html',
  '.js': 'application/javascript',
  '.json': 'application/json',
  '.wasm': 'application/wasm',
  '.ttf': 'font/ttf',
};
const server = http.createServer(async (request, response) => {
  const uri = new URL(request.url, origin);
  const file = path.resolve(build, '.' + (uri.pathname === '/' ? '/index.html' : decodeURIComponent(uri.pathname)));
  if (!file.startsWith(build + path.sep)) {
    response.writeHead(403).end();
    return;
  }
  try {
    const data = await fs.readFile(file);
    response.writeHead(200, {
      'Content-Type': contentType[path.extname(file)] ?? 'application/octet-stream',
      'Cache-Control': 'no-store',
    }).end(data);
  } catch {
    response.writeHead(404).end();
  }
});

async function enableSemantics(page) {
  await page.waitForFunction(() =>
    document.querySelector('flt-semantics-placeholder, flt-semantics-host flt-semantics'));
  await page.evaluate(() => document.querySelector('flt-semantics-placeholder')?.click());
}

function semantic(page, name) {
  return page.getByLabel(name).or(page.getByText(name)).first();
}

async function capture(page, name) {
  // Flutter paints route and tab transitions into the canvas.
  await page.waitForTimeout(450);
  await page.screenshot({path: path.join(output, name + '.png')});
}

async function type(page, label, value) {
  const fieldType = label === 'Contraseña' ? 'password' : 'email';
  await page.getByLabel(label, {exact: true}).first().click();
  await page.waitForFunction(type => {
    const active = document.activeElement;
    return active instanceof HTMLInputElement &&
      (active.type === type || (type === 'email' && active.type === 'text'));
  }, fieldType);
  await page.keyboard.press('Control+a');
  await page.keyboard.insertText(value);
  await page.waitForFunction(length => document.activeElement?.value?.length === length, value.length);
}

const cases = [];
let browser;
let browserVersion;
await fs.mkdir(output, {recursive: true});
await new Promise((resolve, reject) => {
  server.once('error', reject);
  server.listen(18742, '127.0.0.1', resolve);
});
try {
  browser = await chromium.launch({executablePath: process.env.CHROMIUM_EXECUTABLE, headless: true});
  browserVersion = browser.version();
  for (const [label, viewport] of Object.entries({
    desktop: {width: 1440, height: 960},
    mobile: {width: 390, height: 844},
  })) {
    const context = await browser.newContext({
      viewport, serviceWorkers: 'block', reducedMotion: 'reduce',
    });
    const page = await context.newPage();
    page.setDefaultTimeout(20000);
    const pageErrors = [];
    page.on('pageerror', error => pageErrors.push(error.name));
    await page.route('**/*', route => {
      const requestOrigin = new URL(route.request().url()).origin;
      return [origin, apiOrigin].includes(requestOrigin) ? route.continue() : route.abort();
    });
    await page.goto(origin + '/#/login');
    await enableSemantics(page);
    await page.getByRole('button', {name: 'Iniciar sesión'}).waitFor();
    await capture(page, label + '-login');
    await type(page, 'Correo electrónico', owner);
    await type(page, 'Contraseña', password);
    const loginResponse = page.waitForResponse(result =>
      new URL(result.url()).pathname === '/api/v1/auth/login' &&
      result.request().method() === 'POST');
    await page.getByRole('button', {name: 'Iniciar sesión'}).click();
    const loginResult = await loginResponse;
    assert(loginResult.ok(), 'Browser login returned ' + loginResult.status());
    await page.waitForURL(/#\/(select-tenant|dashboard)$/);
    if (page.url().endsWith('/dashboard')) {
      await page.getByRole('button', {name: /Cambiar organización/i})
        .or(semantic(page, /Cambiar organización/i)).first().click();
      await page.waitForURL('**/#/change-tenant');
    }
    await semantic(page, /Demo Norte/i).click();
    await page.waitForURL('**/#/dashboard');
    await semantic(page, /Campañas recientes|Encuentra a tu próximo cliente/i).waitFor();
    await capture(page, label + '-dashboard');
    await page.goto(origin + '/#/campaigns/' + campaign.id);
    await enableSemantics(page);
    const summaryTab = semantic(page, /Resumen comercial/i);
    await summaryTab.click();
    await semantic(page, 'Total de participaciones: 1').waitFor();
    await capture(page, label + '-resumen');
    for (const [name, filter, value] of [
      [/Sin gestionar, 1 de 1 prospectos/i, 'stage', 'SIN_GESTIONAR'],
      [/Asignar responsables/i, 'responsibleId', 'UNASSIGNED'],
      [/Revisar prospectos sin evaluar/i, 'evaluation', 'SIN_EVALUAR'],
    ]) {
      const response = page.waitForResponse(result => {
        const uri = new URL(result.url());
        return uri.pathname === '/api/v1/campaigns/' + campaign.id + '/prospects'
          && uri.searchParams.get(filter) === value && uri.searchParams.get('page') === '1'
          && result.request().method() === 'GET';
      });
      await page.getByRole('button', {name}).or(semantic(page, name)).first().click();
      assert.equal((await response).status(), 200);
      await semantic(page, 'Página 1 · 1 registros').waitFor();
      await summaryTab.click();
    }
    await page.getByRole('button', {name: 'Cerrar sesión'}).first().click();
    await page.waitForURL('**/#/login');
    await page.goto(origin + '/#/campaigns/' + campaign.id);
    await page.waitForURL('**/#/login');
    assert.deepEqual(pageErrors, []);
    cases.push({viewport, status: 'PASS', checks: [
      'login', 'tenant selection', 'dashboard', 'campaign summary',
      'filtered reads on page one', 'logout', 'authenticated route guard',
    ]});
    await context.close();
  }
} finally {
  await browser?.close();
  server.close();
  await fs.writeFile(path.join(output, 'CHROMIUM.json'), JSON.stringify({
    frontendSha, backendSha, browserVersion, cases,
    status: cases.length === 2 ? 'PASS' : 'FAIL',
    fixture: 'Disposable synthetic NestJS and PostgreSQL16 laboratory; screens and HTTP requests are real.',
  }, null, 2) + '\n');
}
