"""Read-only smoke against the explicitly authorized production origin.
Credentials arrive only through stdin; no screenshots, bodies, HAR, or trace.
"""
import asyncio,json,sys,re
from urllib.parse import urlsplit
from playwright.async_api import async_playwright
async def main():
    credentials=json.load(sys.stdin)
    origin='https://saas-platform-client-web.vercel.app'
    result={'scope':'REMOTE_UI_HTTP_READ_ONLY','frontendOrigin':origin,'cases':[],'http':[]}
    secrets=[credentials['email'],credentials['password']]
    def clean(value):
        s=str(value)
        for v in secrets: s=s.replace(v,'[REDACTED]')
        return re.sub(r'[A-Za-z0-9_.+-]+@[A-Za-z0-9.-]+','[REDACTED]',s)[:500]
    async with async_playwright() as pw:
        browser=await pw.chromium.launch(headless=True,args=['--no-sandbox'])
        context=await browser.new_context(viewport={'width':1365,'height':900},ignore_https_errors=False)
        page=await context.new_page()
        async def guard(route):
            request=route.request
            u=urlsplit(request.url)
            if request.method not in ('GET','HEAD','OPTIONS'):
                if request.method!='POST' or u.hostname!='saas-platform-backend-l55n.onrender.com' or u.path not in ('/api/v1/auth/login','/api/v1/auth/select-tenant','/api/v1/auth/logout'):
                    await route.abort()
                    return
            await route.continue_()
        await context.route('**/*',guard)
        tenant_list={'observed':False,'empty':None,'firstName':None}
        async def response(r):
            u=urlsplit(r.url)
            if u.path.startswith('/api/v1/'):
                record_path=re.sub(r'(/api/v1/(?:tenants|users|campaigns|prospects|prospecting-jobs))/[^/]+',r'\1/{id}',u.path)
                result['http'].append({'method':r.request.method,'path':record_path,'status':r.status,'requestId':r.headers.get('x-request-id')})
                if u.path=='/api/v1/tenants' and r.status==200:
                    body=await r.json()
                    tenant_list['observed']=True
                    tenant_list['empty']=isinstance(body.get('data'),list) and len(body['data'])==0
                    if isinstance(body.get('data'),list) and body['data']:
                        tenant_list['firstName']=body['data'][0].get('name')
                        secrets.extend(str(body['data'][0].get(k,'')) for k in ('id','name','slug'))
        page.on('response',response)
        async def semantics():
            placeholder=page.locator('flt-semantics-placeholder')
            if await placeholder.count(): await placeholder.evaluate('(e)=>e.click()')
        async def wait_semantic(value):
            for _ in range(160):
                await semantics()
                if value in await page.locator('body').aria_snapshot(): return
                await asyncio.sleep(.25)
            raise TimeoutError('Expected UI state not observed')
        async def logout():
            await page.get_by_role('button',name='Cerrar sesión',exact=True).click()
            await page.wait_for_url('**/#/login',timeout=30000)
            for _ in range(80):
                if any(h['path']=='/api/v1/auth/logout' and h['status']==200 for h in result['http']): break
                await asyncio.sleep(.25)
            else: raise TimeoutError('Remote logout response was not observed')
            await page.reload(wait_until='domcontentloaded')
            await wait_semantic('Iniciar sesión')
            assert page.url.endswith('/#/login'),'Logout did not survive a reload'
            result['cases'].append({'caseId':'REMOTE-LOGOUT','status':'PASS','http':True,'reload':True})
        try:
            await page.goto(origin+'/#/login',wait_until='domcontentloaded',timeout=90000)
            await page.wait_for_function("document.querySelector('flt-semantics-placeholder') || document.querySelector('flt-semantics-host flt-semantics')",timeout=60000)
            await semantics()
            for label,value in [('Correo electrónico',credentials['email']),('Contraseña',credentials['password'])]:
                field=page.get_by_label(label,exact=True)
                await field.click()
                await page.keyboard.press('ControlOrMeta+A')
                await page.keyboard.type(value,delay=35)
                await page.keyboard.press('Tab')
            await page.get_by_role('button',name='Iniciar sesión',exact=True).click()
            await page.wait_for_url(re.compile(r'.*/#/(select-tenant|dashboard)$'),timeout=60000)
            login=next((r for r in result['http'] if r['path']=='/api/v1/auth/login'),None)
            assert login and login['status']==200,'Login did not return HTTP200'
            result['cases'].append({'caseId':'REMOTE-LOGIN','status':'PASS','ui':True,'http':True})
            if '/select-tenant' in page.url:
                await wait_semantic('Seleccionar organización')
                for _ in range(40):
                    if tenant_list['observed']: break
                    await asyncio.sleep(.25)
                candidates=page.get_by_role('button',name=re.compile(r'^(?!Crear organización$|Cerrar sesión$|Back$|Atrás$).+'))
                if await candidates.count()==0 and tenant_list['firstName']:
                    candidates=page.get_by_label(tenant_list['firstName'],exact=False)
                if await candidates.count()==0:
                    result['tenantRead']={'httpObserved':tenant_list['observed'],'listEmpty':tenant_list['empty']}
                    result['cases'].append({'caseId':'REMOTE-TENANT-CONTEXT','status':'BLOCKED','reason':'No selectable organization in the authorized read-only session'})
                    await logout()
                    print(json.dumps(result,ensure_ascii=False));return
                await candidates.first.click()
            await wait_semantic('Resumen de la organización actual')
            for path,label in [('/dashboard','Dashboard'),('/campaigns','Campañas'),('/prospects','Prospectos'),('/users','Usuarios'),('/jobs','Trabajos')]:
                start=len(result['http'])
                await page.goto(origin+'/#'+path,wait_until='domcontentloaded')
                await wait_semantic(label)
                if path=='/dashboard': await page.get_by_role('button',name='Actualizar dashboard',exact=True).click()
                for _ in range(80):
                    new=result['http'][start:]
                    if any(r['method']=='GET' and r['status']==200 for r in new): break
                    await asyncio.sleep(.25)
                else: raise TimeoutError('No successful HTTP read observed')
                result['cases'].append({'caseId':'REMOTE-READ-'+path[1:].upper(),'status':'PASS','ui':True,'http':True,'businessDataRecorded':False})
            await logout()
        except Exception as e:
            result['cases'].append({'caseId':'REMOTE-UI','status':'FAIL','reason':clean(type(e).__name__+': '+str(e))})
        finally:
            await context.close();await browser.close()
    # No credential, token, business names, query strings, or response bodies are returned.
    print(json.dumps(result,ensure_ascii=False))
    if any(c['status']!='PASS' for c in result['cases']):sys.exit(1)
asyncio.run(main())
