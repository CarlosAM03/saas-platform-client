// Local presentation only. Serves a built SPA and proxies /api to the explicitly owned core fixture.
const fs = require('node:fs');
const path = require('node:path');
const http = require('node:http');
const manifest = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
const backend = new URL(manifest.apiBaseUrl);
if (backend.protocol !== 'http:' || !['localhost', '127.0.0.1'].includes(backend.hostname) || manifest.productionEntrypoint !== true || manifest.serviceCredentials !== false)
  throw Error('Explicit isolated core manifest required');
const root = path.resolve(__dirname, '../build/web');
if (!fs.existsSync(path.join(root, 'index.html'))) throw Error('Build Web first with API_BASE_URL=http://127.0.0.1:18420');
const mime = { '.html': 'text/html; charset=utf-8', '.js': 'text/javascript', '.json': 'application/json', '.wasm': 'application/wasm', '.css': 'text/css', '.png': 'image/png', '.svg': 'image/svg+xml', '.woff2': 'font/woff2' };
http.createServer((req, res) => {
  if (req.url.startsWith('/api/')) {
    const forward = http.request(new URL(req.url, backend), { method: req.method, headers: { ...req.headers, host: backend.host } }, (reply) => {
      res.writeHead(reply.statusCode, reply.headers);
      reply.pipe(res);
    });
    forward.on('error', () => { if (!res.headersSent) res.writeHead(502); res.end('Local core unavailable'); });
    req.pipe(forward);
    return;
  }
  try {
    const pathname = decodeURIComponent(new URL(req.url, 'http://127.0.0.1').pathname);
    let file = path.resolve(root, '.' + pathname);
    if (file !== root && !file.startsWith(root + path.sep)) { res.writeHead(400); res.end(); return; }
    if (!fs.existsSync(file) || fs.statSync(file).isDirectory()) file = path.join(root, 'index.html');
    res.writeHead(200, { 'Content-Type': mime[path.extname(file)] || 'application/octet-stream', 'Cache-Control': 'no-store', 'X-Content-Type-Options': 'nosniff' });
    fs.createReadStream(file).pipe(res);
  } catch { res.writeHead(400); res.end(); }
}).listen(18420, '127.0.0.1', () => process.stdout.write('LOCAL_CORE_DEMO http://127.0.0.1:18420\n'));
