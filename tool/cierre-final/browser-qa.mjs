// Closure QA for the three roles against the disposable local laboratory.
// Screens and HTTP requests are real; no remote service is contacted.
import assert from 'node:assert/strict';
import {execFileSync} from 'node:child_process';
import fs from 'node:fs/promises';
import http from 'node:http';
import path from 'node:path';
import {chromium} from '../../codex/frontend-cp/.local/browser/node_modules/playwright-core/index.mjs';

const [buildPath, outputPath] = process.argv.slice(2);
assert(
  buildPath && outputPath && process.env.CHROMIUM_EXECUTABLE,
  'Provide the release build, receipt directory and CHROMIUM_EXECUTABLE.',
);
const build = path.resolve(buildPath);
const output = path.resolve(outputPath);
const lab = path.resolve('codex/frontend-cp/.local');
const origin = 'http://127.0.0.1:18742';
const apiOrigin = 'http://127.0.0.1:18741';
const password = (await fs.readFile(path.join(lab, 'lab.env'), 'utf8')).match(
  /^CP_SEED_PASSWORD=([a-f0-9]+)$/m,
)?.[1];
assert(password, 'Synthetic seed password missing.');
const frontendSha = execFileSync(
  'git',
  ['rev-parse', process.env.CP_BUILD_SHA ?? 'HEAD'],
  {encoding: 'utf8'},
).trim();
const backendSha = (await fs.readFile(path.join(lab, 'backend-sha.txt'), 'utf8')).trim();

const accounts = {
  admin: 'admin@demo.example',
  owner: 'owner.demo-norte@demo.example',
  member: 'member.demo-norte@demo.example',
};
const contentType = {
  '.html': 'text/html',
  '.js': 'application/javascript',
  '.json': 'application/json',
  '.wasm': 'application/wasm',
  '.ttf': 'font/ttf',
};
const server = http.createServer(async (request, response) => {
  const uri = new URL(request.url, origin);
  const file = path.resolve(
    build,
    '.' + (uri.pathname === '/' ? '/index.html' : decodeURIComponent(uri.pathname)),
  );
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
  await page.evaluate(() =>
    document.querySelector('flt-semantics-placeholder')?.click());
}

function semantic(page, name) {
  return page.getByLabel(name).or(page.getByText(name)).first();
}

async function type(page, label, value) {
  const fieldType = label === 'Contraseña' ? 'password' : 'email';
  await page.getByLabel(label, {exact: true}).first().click();
  await page.waitForFunction((type) => {
    const active = document.activeElement;
    return active instanceof HTMLInputElement &&
      (active.type === type || (type === 'email' && active.type === 'text'));
  }, fieldType);
  await page.keyboard.press('Control+a');
  await page.keyboard.insertText(value);
  await page.waitForFunction((length) => document.activeElement?.value?.length === length, value.length);
}

async function capture(page, name) {
  await page.waitForTimeout(500);
  await page.screenshot({path: path.join(output, name + '.png')});
}

async function login(page, role) {
  await page.goto(origin + '/#/login');
  await enableSemantics(page);
  await page.getByRole('button', {name: 'Iniciar sesión'}).waitFor();
  await type(page, 'Correo electrónico', accounts[role]);
  await type(page, 'Contraseña', password);
  await page.getByRole('button', {name: 'Iniciar sesión'}).click();
  await page.waitForURL(/#\/(select-tenant|dashboard)$/, {timeout: 20000});
  if (page.url().endsWith('/select-tenant')) {
    await semantic(page, /Demo Norte/i).click();
    await page.waitForURL('**/#/dashboard', {timeout: 20000});
  }
  await enableSemantics(page);
}

async function logout(page) {
  await page.getByRole('button', {name: 'Cerrar sesión'}).first().click();
  await page.waitForURL('**/#/login', {timeout: 20000});
}

function watchBatchRequests(page) {
  const requests = [];
  page.on('request', (request) => {
    const uri = new URL(request.url());
    if (uri.pathname.includes('prospecting-batches')) {
      requests.push(request.method() + ' ' + uri.pathname);
    }
  });
  return requests;
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
  browser = await chromium.launch({
    executablePath: process.env.CHROMIUM_EXECUTABLE,
    headless: true,
  });
  browserVersion = browser.version();

  async function runCase(name, viewport, body) {
    const context = await browser.newContext({
      viewport,
      serviceWorkers: 'block',
      reducedMotion: 'reduce',
    });
    const page = await context.newPage();
    page.setDefaultTimeout(20000);
    const pageErrors = [];
    page.on('pageerror', (error) => pageErrors.push(error.name));
    await page.route('**/*', (route) => {
      const requestOrigin = new URL(route.request().url()).origin;
      return [origin, apiOrigin].includes(requestOrigin)
        ? route.continue()
        : route.abort();
    });
    try {
      await body(page);
      assert.deepEqual(pageErrors, [], 'browser runtime errors');
      cases.push({name, viewport, status: 'PASS'});
    } catch (error) {
      await capture(page, 'FAIL-' + name).catch(() => {});
      cases.push({
        name,
        viewport,
        status: 'FAIL',
        error: String(error.message).split('\n')[0],
      });
    } finally {
      await context.close();
    }
  }

  await runCase('owner-desktop-full-flow', {width: 1440, height: 960}, async (page) => {
    await login(page, 'owner');
    await semantic(page, /Lotes recientes|Encuentra a tu próximo cliente/i).waitFor();
    await page.getByText('Ver lotes', {exact: true}).waitFor();
    await capture(page, 'desktop-owner-dashboard');

    await page.getByText('Ver lotes', {exact: true}).click();
    await page.waitForURL('**/#/jobs');
    await semantic(page, /Mis lotes|El servicio no está disponible temporalmente/i).first().waitFor();
    await capture(page, 'desktop-owner-batches');

    await page.goto(origin + '/#/jobs/inexistente-qa');
    await page.waitForURL('**/#/jobs/inexistente-qa');
    await semantic(page, /Reintentar|Ver lotes/i).first().waitFor();
    await capture(page, 'desktop-owner-batch-not-found');

    await page.goto(origin + '/#/generate');
    await enableSemantics(page);
    await semantic(page, 'Prospección por lotes').waitFor();
    await semantic(page, 'Solicitar lote').waitFor();
    await capture(page, 'desktop-owner-generate');

    await page.goto(origin + '/#/campaigns');
    await enableSemantics(page);
    await semantic(page, 'Campaña 2 Demo Norte').click();
    await page.waitForURL('**/#/campaigns/**');
    await enableSemantics(page);
    await semantic(page, 'Prospectos').click();
    await semantic(page, 'Prospecto 1 Demo Norte').waitFor();
    await capture(page, 'desktop-owner-campaign-prospects');
    await semantic(page, 'Resumen comercial').click();
    await semantic(page, /Total de participaciones/i).waitFor();
    await capture(page, 'desktop-owner-campaign-summary');

    await page.goto(origin + '/#/prospects');
    await enableSemantics(page);
    await semantic(page, 'Prospecto 1 Demo Norte').waitFor();
    await capture(page, 'desktop-owner-prospects');

    await logout(page);
    await page.goto(origin + '/#/campaigns');
    await page.waitForURL('**/#/login');

    await page.setViewportSize({width: 390, height: 844});
    await login(page, 'owner');
    await semantic(page, /Lotes recientes|Encuentra a tu próximo cliente/i).waitFor();
    await capture(page, 'mobile-owner-dashboard');
    await page.goto(origin + '/#/jobs');
    await enableSemantics(page);
    await semantic(page, /Mis lotes|El servicio no está disponible temporalmente/i).first().waitFor();
    await capture(page, 'mobile-owner-batches');
    await page.goto(origin + '/#/generate');
    await enableSemantics(page);
    await semantic(page, 'Solicitar lote').waitFor();
    await capture(page, 'mobile-owner-generate');
  });

  await runCase('member-desktop-and-mobile-denials', {width: 1440, height: 960}, async (page) => {
    const batchRequests = watchBatchRequests(page);
    await login(page, 'member');
    await semantic(page, /Lotes recientes|Encuentra a tu próximo cliente/i).waitFor();
    assert.equal(await page.getByText('Buscar prospectos', {exact: true}).count(), 0);
    assert.equal(await page.getByText('Lotes', {exact: true}).count(), 0);
    await capture(page, 'desktop-member-dashboard');

    await page.goto(origin + '/#/jobs');
    await enableSemantics(page);
    await page.getByText('No tienes permisos para realizar esta acción.').waitFor();
    await capture(page, 'desktop-member-batches-denied');

    await page.goto(origin + '/#/generate');
    await enableSemantics(page);
    await page.getByText('No tienes permisos para realizar esta acción.').waitFor();
    await capture(page, 'desktop-member-generate-denied');

    await page.goto(origin + '/#/prospects/new');
    await enableSemantics(page);
    await page.getByText('No tienes permisos para realizar esta acción.').waitFor();
    await capture(page, 'desktop-member-create-denied');

    await page.goto(origin + '/#/campaigns');
    await enableSemantics(page);
    await semantic(page, 'Campaña 1 Demo Norte').waitFor();
    await capture(page, 'desktop-member-campaigns');

    await page.setViewportSize({width: 390, height: 844});
    await page.goto(origin + '/#/dashboard');
    await enableSemantics(page);
    await semantic(page, /Lotes recientes|Encuentra a tu próximo cliente/i).waitFor();
    await capture(page, 'mobile-member-dashboard');
    const menu = page.getByRole('button', {name: /menu|menú/i}).first();
    if (await menu.count()) {
      await menu.click();
      await page.waitForTimeout(300);
      assert.equal(await page.getByText('Buscar prospectos', {exact: true}).count(), 0);
      await capture(page, 'mobile-member-drawer');
    }
    assert.deepEqual(batchRequests, []);
  });

  await runCase('admin-desktop', {width: 1440, height: 960}, async (page) => {
    await login(page, 'admin');
    await page.goto(origin + '/#/tenants');
    await enableSemantics(page);
    await semantic(page, 'Demo Norte').waitFor();
    await semantic(page, 'Demo Sur').waitFor();
    await capture(page, 'desktop-admin-tenants');

    await page.goto(origin + '/#/tenants/new');
    await enableSemantics(page);
    await semantic(page, 'Registrar organización').waitFor();
    await capture(page, 'desktop-admin-register');

    await page.goto(origin + '/#/change-tenant');
    await enableSemantics(page);
    await semantic(page, /Demo Norte/i).click();
    await page.waitForURL('**/#/dashboard');
    await page.goto(origin + '/#/users');
    await enableSemantics(page);
    await semantic(page, /Usuarios/i).first().waitFor();
    await capture(page, 'desktop-admin-users');
  });
} finally {
  await browser?.close();
  server.close();
  const failed = cases.filter((item) => item.status !== 'PASS');
  await fs.writeFile(
    path.join(output, 'CHROMIUM.json'),
    JSON.stringify({
      frontendSha,
      backendSha,
      browserVersion,
      cases,
      status: cases.length === 3 && failed.length === 0 ? 'PASS' : 'FAIL',
      fixture: 'Disposable synthetic NestJS and PostgreSQL 16 laboratory; screens and HTTP requests are real.',
      limits:
        'Prospector Service/Engine are not part of this laboratory. Batch admission, generation and confirmation remain NOT_RUN here; role, navigation, denial and visual states are covered.',
    }, null, 2) + '\n',
  );
  if (failed.length) process.exitCode = 1;
}
