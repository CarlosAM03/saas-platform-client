"""Local test agent, reusing Avance2's installed Playwright image and confined CA."""
import asyncio, json, os, pathlib, subprocess, re, hashlib
from urllib.parse import urlsplit
from playwright.async_api import async_playwright

async def main():
    home=pathlib.Path(os.environ['HOME']); home.mkdir(parents=True,exist_ok=True)
    nss=home/'.pki'/'nssdb'; nss.mkdir(parents=True,exist_ok=True)
    if not (nss/'cert9.db').exists(): subprocess.run(['certutil','-N','--empty-password','-d','sql:'+str(nss)],check=True)
    subprocess.run(['certutil','-A','-d','sql:'+str(nss),'-n','Prospector Local CA','-t','C,,','-i','/certs/ca.crt'],check=True)
    display=':'+str(1000+int.from_bytes(os.urandom(2),'big')%5000)
    while pathlib.Path('/tmp/.X'+display[1:]+'-lock').exists():
        display=':'+str(1000+int.from_bytes(os.urandom(2),'big')%5000)
    os.environ['DISPLAY']=display
    xvfb=subprocess.Popen(['Xvfb',display,'-screen','0','1440x1000x24','-ac','-nolisten','tcp'],stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
    for attempt in range(100):
        if pathlib.Path('/tmp/.X11-unix/X'+display[1:]).exists(): break
        if xvfb.poll() is not None: raise RuntimeError('Isolated X server failed to start')
        await asyncio.sleep(.05)
    else: raise RuntimeError('Isolated X server readiness timed out')
    subprocess.Popen(['x11vnc','-display',display,'-forever','-shared','-nopw','-localhost','-rfbport','5900'],stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
    subprocess.Popen(['websockify','--web=/usr/share/novnc','6080','127.0.0.1:5900'],stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
    # Confined test CA also applies to Playwright's Node HTTP verifier; TLS remains enabled.
    os.environ['NODE_EXTRA_CA_CERTS']='/certs/ca.crt'
    pw=await async_playwright().start()
    ctx=await pw.chromium.launch_persistent_context(str(home/'profile'),headless=False,viewport={'width':1365,'height':900},ignore_https_errors=False,args=['--no-sandbox'])
    page=ctx.pages[0] if ctx.pages else await ctx.new_page()
    network=[]; tasks=set(); secrets=set(); token=None
    def clean(value):
        def redact(v):
            if isinstance(v,dict): return {k:('[REDACTED]' if k.lower() in ('accesstoken','password','passwordhash','authorization','previewreference') else redact(x)) for k,x in v.items()}
            if isinstance(v,list): return [redact(x) for x in v]
            return v
        s=json.dumps(redact(value),ensure_ascii=False)
        for secret in secrets:
            if secret: s=s.replace(secret,'[REDACTED]')
        s=re.sub(r'Bearer [A-Za-z0-9._-]+','Bearer [REDACTED]',s)
        s=re.sub(r'[A-Za-z0-9_.+-]+@[A-Za-z0-9.-]+','[SYNTHETIC_EMAIL]',s)
        return json.loads(s)
    async def observed(response):
        nonlocal token
        req=response.request
        if '/api/v1/' not in req.url: return
        entry={'method':req.method,'path':urlsplit(req.url).path,'status':response.status,'requestId':response.headers.get('x-request-id')}
        try:
            body=await response.json()
            data=body.get('data') or {}
            if isinstance(data,dict):
                if data.get('accessToken'): token=data['accessToken'];secrets.add(token)
                entry['id']=data.get('id');entry['summary']=data.get('summary')
                if isinstance(data.get('rows'),list): entry['classifications']=[row.get('classification') for row in data['rows']]
            entry['reason']=body.get('error',{}).get('details',{}).get('reason')
            entry['total']=body.get('meta',{}).get('total')
        except Exception: pass
        try:
            payload=req.post_data_json
            entry['requestKeys']=sorted(payload.keys())
        except Exception:
            raw=req.post_data_buffer or b''
            if b'filename=' in raw:
                # Original file bytes, excluding multipart headers and delimiters.
                sections=raw.split(b'Content-Disposition:')
                part=next((p for p in sections if b'filename=' in p.split(b'\r\n\r\n')[0]),b'')
                content=part.split(b'\r\n\r\n',1)[1].rsplit(b'\r\n--',1)[0] if b'\r\n\r\n' in part else b''
                entry['fileSha256']=hashlib.sha256(content).hexdigest()
        network.append(entry)
    def observe(r):
        t=asyncio.create_task(observed(r));tasks.add(t);t.add_done_callback(tasks.discard)
    page.on('response',observe)
    async def semantics():
        item=page.locator('flt-semantics-placeholder')
        if await item.count(): await item.evaluate('(e)=>e.click()')
    async def locator(d):
        if d.get('selector'): return page.locator(d['selector'])
        if d.get('label'): return page.get_by_label(d['label'],exact=d.get('exact',True))
        item=page.get_by_role(d.get('role','button'),name=d['name'],exact=d.get('exact',True))
        if not await item.count() and d.get('role','button')=='button': item=page.get_by_label(d['name'],exact=d.get('exact',True))
        return item
    async def action(d):
        nonlocal token
        kind=d.get('action','snapshot')
        if kind=='resetSession':
            session=await ctx.new_cdp_session(page)
            await session.send('Storage.clearDataForOrigin',{'origin':'https://localhost:18543','storageTypes':'all'})
            token=None
            network.clear()
            await page.goto('https://localhost:18543/#/login',wait_until='domcontentloaded')
            await page.reload(wait_until='domcontentloaded')
            await page.wait_for_function("document.querySelector('flt-semantics-placeholder') || document.querySelector('flt-semantics-host flt-semantics')",timeout=20000)
            await semantics()
        elif kind=='goto':
            u=urlsplit(d['url'])
            if u.scheme!='https' or u.hostname!='localhost' or u.port!=18543: raise ValueError('Only isolated sprint HTTPS origin permitted')
            await page.goto(d['url'],wait_until='domcontentloaded');await page.wait_for_function("document.querySelector('flt-semantics-placeholder') || document.querySelector('flt-semantics-host flt-semantics')",timeout=20000);await semantics()
        elif kind=='reload': await page.reload(wait_until='domcontentloaded');await semantics()
        elif kind=='fill':
            if 'contraseña' in d['name'].lower(): secrets.add(d['value'])
            item=page.get_by_label(d['name'],exact=d.get('exact',False))
            await item.click();await page.keyboard.press('ControlOrMeta+A');await page.keyboard.press('Backspace');await page.keyboard.type(d['value'],delay=5);await page.keyboard.press('Tab')
        elif kind=='click': await (await locator(d)).click()
        elif kind=='select':
            control=(await locator(d)).or_(page.get_by_role('button',name=d['name'],exact=False)).or_(page.get_by_label(d['name'],exact=False)).first
            await control.click()
            selected=False
            for attempt in range(30):
                await semantics()
                for role in ('option','menuitem','button'):
                    item=page.get_by_role(role,name=d['option'],exact=True)
                    if await item.count():
                        await item.last.click();selected=True;break
                if not selected:
                    item=page.get_by_label(d['option'],exact=True)
                    if await item.count():
                        await item.last.click();selected=True
                if selected: break
                await asyncio.sleep(.1)
            if not selected: raise ValueError('Dropdown option is not exposed semantically')
        elif kind=='file':
            async with page.expect_file_chooser() as selected: await page.get_by_role('button',name='Seleccionar CSV',exact=True).click()
            await (await selected.value).set_files({'name':'synthetic.csv','mimeType':'text/csv','buffer':d['csv'].encode()})
        elif kind=='waitText':
            for attempt in range(80):
                await semantics()
                if d['text'] in await page.locator('body').aria_snapshot(): break
                await asyncio.sleep(.25)
            else: raise TimeoutError('Expected semantic text is absent: '+d['text'])
        elif kind=='waitURL': await page.wait_for_url('**'+d['path'],timeout=20000)
        elif kind=='network': return {'http':network[d.get('after',0):],'cursor':len(network)}
        elif kind=='concurrentUserCreate':
            secrets.add(d['password'])
            pages=[]
            async def ready(p,value):
                for attempt in range(120):
                    item=p.locator('flt-semantics-placeholder')
                    if await item.count(): await item.evaluate('(e)=>e.click()')
                    if value in await p.locator('body').aria_snapshot(): return
                    await asyncio.sleep(.1)
                raise TimeoutError('Concurrent user form did not reach the expected UI state')
            try:
                for _ in range(2):
                    p=await ctx.new_page();pages.append(p);p.on('response',observe)
                    await p.goto('https://localhost:18543/#/users/new',wait_until='domcontentloaded')
                    await ready(p,'El usuario se crea como MEMBER')
                    for label,value in [('Nombre',d['name']),('Correo electrónico',d['email']),('Contraseña',d['password'])]:
                        field=p.get_by_label(label,exact=False)
                        await field.click();await p.keyboard.press('ControlOrMeta+A');await p.keyboard.press('Backspace')
                        await p.keyboard.type(value,delay=1);await p.keyboard.press('Tab')
                pending=[asyncio.create_task(p.wait_for_event('response',predicate=lambda r:r.request.method=='POST' and urlsplit(r.url).path=='/api/v1/users',timeout=30000)) for p in pages]
                await asyncio.gather(*(p.get_by_role('button',name='Guardar',exact=True).click() for p in pages))
                responses=await asyncio.gather(*pending)
                statuses=sorted(r.status for r in responses)
                if statuses!=[201,409]: raise AssertionError('Expected one creation and one unique-email rejection')
                index=next(i for i,r in enumerate(responses) if r.status==201)
                body=await responses[index].json();created_id=body['data']['id']
                await ready(pages[index],d['name'])
                await ready(pages[1-index],'La operación entra en conflicto con el estado actual.')
                await pages[1-index].reload(wait_until='domcontentloaded')
                await ready(pages[1-index],'El usuario se crea como MEMBER')
                await pages[index].reload(wait_until='domcontentloaded')
                await ready(pages[index],d['name'])
                return {'statuses':statuses,'id':created_id,'uiReread':'PASS'}
            finally:
                for p in pages: await p.close()
        elif kind=='http':
            # Complementary HTTP test only; runner must never label this as UI_TO_DB.
            if not d['path'].startswith('/api/v1/'): raise ValueError('Only Platform API permitted')
            r=await ctx.request.fetch('https://localhost:18543'+d['path'],method=d.get('method','GET'),headers={'Authorization':'Bearer '+(token or ''),**d.get('headers',{})},data=d.get('body'))
            body=await r.json()
            return {'status':r.status,'body':clean(body)}
        elif kind=='wait': await asyncio.sleep(min(d.get('seconds',1),20))
        await asyncio.sleep(.25);await semantics()
        if tasks: await asyncio.gather(*list(tasks),return_exceptions=True)
        return clean({'url':page.url,'aria':await page.locator('body').aria_snapshot(),'cursor':len(network)})
    async def handler(reader,writer):
        try:
            header=await reader.readuntil(b'\r\n\r\n')
            length=next((int(h.split(':',1)[1]) for h in header.decode().split('\r\n') if h.lower().startswith('content-length:')),0)
            d=json.loads(await reader.readexactly(length) if length else b'{}')
            body=json.dumps({'ok':True,'data':await action(d)},ensure_ascii=False).encode()
        except Exception as e: body=json.dumps({'ok':False,'error':clean(type(e).__name__+': '+str(e))[:400]}).encode()
        writer.write(b'HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nContent-Length: '+str(len(body)).encode()+b'\r\nConnection: close\r\n\r\n'+body)
        await writer.drain();writer.close()
    server=await asyncio.start_server(handler,'127.0.0.1',6090)
    print('SPRINT_TRUSTED_BROWSER_READY',flush=True)
    async with server: await server.serve_forever()
asyncio.run(main())
