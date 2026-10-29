"""Browser-only history/resilience checks against the compiled Flutter app."""
import asyncio
import json
import secrets
import urllib.request
from urllib.parse import urlencode
from playwright.async_api import async_playwright

BASE = "https://localhost:18643"


async def ready(page, text=None):
    await page.wait_for_function(
        "document.querySelector('flt-semantics-placeholder') || document.querySelector('flt-semantics-host flt-semantics')",
        timeout=30000,
    )
    placeholder = page.locator("flt-semantics-placeholder")
    if await placeholder.count():
        await placeholder.evaluate("(e)=>e.click()")
    if text:
        for _ in range(120):
            if text in await page.locator('body').aria_snapshot():
                break
            await asyncio.sleep(.25)
        else:
            raise TimeoutError('Expected accessible state did not appear')


async def open_activation(page, recipient, secret_values):
    # The only origin of real activation credentials is the confined mail sink.
    with urllib.request.urlopen("http://mail:8025/?" + urlencode({"recipient": recipient})) as response:
        code = json.load(response).get("code")
    if not code:
        raise RuntimeError("Laboratory transport has no activation message")
    import re
    if not re.fullmatch(r"[A-Za-z0-9_-]{43}", code):
        raise RuntimeError("Laboratory transport parsed an invalid code shape")
    secret_values.add(code)
    # An email link opens a document. A same-origin hash-only page.goto keeps
    # the existing Flutter instance and never executes the startup handoff.
    await page.goto('about:blank', wait_until='domcontentloaded')
    await page.goto(BASE + "/#/activate?code=" + code, wait_until="domcontentloaded")
    await page.wait_for_function("location.hash === '#/activate'", timeout=30000)
    await ready(page)


async def audit(_existing_context):
    # Isolate history and error injections from the authenticated E2E session.
    playwright = await async_playwright().start()
    browser = await playwright.chromium.launch(headless=True, args=["--no-sandbox"])
    ctx = await browser.new_context(ignore_https_errors=False)
    results = []
    code = secrets.token_urlsafe(32)
    link = BASE + "/#/activate?code=" + code

    async def case(name, fn):
        try:
            await fn()
            results.append({"caseId": name, "scope": "REAL_BROWSER", "status": "PASS"})
        except Exception as error:
            # Playwright exceptions can include the raw navigation URL.
            results.append({"caseId": name, "scope": "REAL_BROWSER", "status": "FAIL", "errorType": type(error).__name__, "assertion": str(error) if isinstance(error, AssertionError) else "browser operation"})

    async def history():
        page = await ctx.new_page()
        seen = []
        console_secret = []
        page.on("console", lambda message: console_secret.append(code in message.text))
        await page.add_init_script("""(() => {
          window.__g1Writes = [];
          for (const name of ['replaceState','pushState']) {
            const original = history[name].bind(history);
            history[name] = function(state,title,url) {
              window.__g1Writes.push({method:name,hasCode:String(url).includes('code=') || JSON.stringify(state || {}).includes('code=')});
              return original(state,title,url);
            };
          }
        })();""")
        async def invalid(route):
            seen.append(route.request.method)
            await route.fulfill(status=401, content_type="application/json", body='{"success":false,"error":{"code":"UNAUTHORIZED","message":"private","details":{}}}')
        await page.route("**/api/v1/auth/redeem-first-access", invalid)
        try:
            await page.goto(BASE + "/#/login")
            await ready(page)
            await page.goto(link)
            await page.wait_for_function("location.hash === '#/activate'")
            await ready(page, "Solicita uno nuevo al administrador.")
            writes = await page.evaluate("window.__g1Writes")
            assert writes and writes[0]["method"] == "replaceState", "first write must replace"
            assert not any(item["hasCode"] for item in writes), "router history must be clean"
            assert len(seen) == 1, "one redemption"
            assert code not in await page.evaluate("JSON.stringify(history.state)"), "history state must be clean"
            assert not await page.evaluate("(code)=>[...Object.values(localStorage),...Object.values(sessionStorage)].some(x=>x.includes(code))", code)
            await page.go_back()
            assert "#/login" in page.url, "back must return to prior login entry"
            await page.go_forward()
            await ready(page, "Solicita uno nuevo al administrador.")
            assert "code=" not in page.url, "forward must remain scrubbed"
            await page.reload()
            await ready(page, "Solicita uno nuevo al administrador.")
            assert len(seen) == 1, "no retry after reload/history restoration"
            assert not any(console_secret), "console must be clean"
        finally:
            await page.close()

    await case("HISTORY-REPLACE-BACK-FORWARD-RELOAD", history)

    async def new_tabs():
        for suffix in ["?code=" + code, "?code=one&code=two", "?code=%ZZ", ""]:
            page = await ctx.new_page()
            await page.route("**/api/v1/auth/redeem-first-access", lambda route: route.fulfill(status=401, content_type="application/json", body='{"success":false}'))
            try:
                await page.goto(BASE + "/#/activate" + suffix)
                await page.wait_for_function("location.hash === '#/activate'")
                await ready(page, "Solicita uno nuevo al administrador.")
                assert code not in json.dumps(await ctx.storage_state())
            finally:
                await page.close()
    await case("HISTORY-NEW-TAB-INVALID-DUPLICATE-SESSION-STORAGE", new_tabs)

    async def replace_failure():
        page = await ctx.new_page()
        requests = []
        await page.add_init_script("""
            window.__g1EarlyFailure = false;
            window.addEventListener('error', event => {
              if (event.message.includes('No se pudo limpiar')) window.__g1EarlyFailure = true;
            });
            history.replaceState = () => {throw new Error('controlled history failure')};
        """)
        page.on("request", lambda req: requests.append(req.url) if "/api/v1/auth/redeem-first-access" in req.url else None)
        try:
            await page.goto(link)
            await page.wait_for_function("window.__g1EarlyFailure === true")
            assert not requests
            assert not await page.locator("input").count()
        finally:
            await page.close()
    await case("HISTORY-REPLACE-FAILURE-NO-REDEEM", replace_failure)

    async def errors():
        for status in [400, 401, 403, 404, 409, 429, 500, 503, 0]:
            page = await ctx.new_page()
            calls = []
            async def fail(route):
                calls.append(1)
                if status == 0:
                    await route.abort("internetdisconnected")
                else:
                    await route.fulfill(status=status, content_type="application/json", body=json.dumps({"success": False, "error": {"message": code, "details": {"token": code}}}))
            await page.route("**/api/v1/auth/redeem-first-access", fail)
            try:
                await page.goto(link)
                await page.wait_for_function("location.hash === '#/activate'")
                await ready(page)
                await page.get_by_text("Volver al login", exact=True).wait_for()
                await page.wait_for_function("!document.querySelector('[role=progressbar]')")
                assert code not in await page.locator("body").aria_snapshot()
                assert len(calls) == 1
            finally:
                await page.close()
    await case("ACTIVATION-HTTP-ERRORS-NETWORK-NO-RETRY", errors)
    async def late_response():
        page = await ctx.new_page()
        release = asyncio.Event()
        arrived = asyncio.Event()
        async def delayed(route):
            arrived.set()
            await release.wait()
            await route.fulfill(status=200, content_type="application/json", body=json.dumps({
                "success": True, "data": {"action": "CHANGE_PASSWORD_REQUIRED",
                    "firstAccessToken": secrets.token_urlsafe(32), "expiresAt": "2100-01-01T00:00:00Z"}}))
        await page.route("**/api/v1/auth/redeem-first-access", delayed)
        try:
            await page.goto(link)
            await ready(page)
            await asyncio.wait_for(arrived.wait(), 30)
            await page.get_by_text("Volver al login", exact=True).click()
            await ready(page, "Iniciar sesión")
            release.set()
            await asyncio.sleep(.5)
            assert not await page.get_by_label("Nueva contraseña", exact=True).count(), "late response cannot reopen password form"
            assert "#/login" in page.url, "late response cannot navigate"
        finally:
            release.set()
            await page.close()
    await case("ACTIVATION-LATE-RESPONSE-AFTER-LEAVING", late_response)

    async def device_clock():
        for offset in [-86400000, 86400000]:
            page = await ctx.new_page()
            await page.add_init_script("""((offset) => {
                const Native = Date;
                globalThis.Date = class extends Native {
                    constructor(...args) {super(...(args.length ? args : [Native.now()+offset]));}
                    static now() {return Native.now()+offset;}
                };
            })(%d);""" % offset)
            async def redeem(route):
                import datetime
                assert route.request.post_data_json["activationToken"] == code, "one-shot handoff must preserve the code"
                expiry = (datetime.datetime.now(datetime.timezone.utc) + datetime.timedelta(minutes=15)).isoformat()
                await route.fulfill(status=200, content_type="application/json", body=json.dumps({
                    "success": True, "data": {"action": "CHANGE_PASSWORD_REQUIRED",
                        "firstAccessToken": secrets.token_urlsafe(32), "expiresAt": expiry}}))
            await page.route("**/api/v1/auth/redeem-first-access", redeem)
            await page.route("**/api/v1/auth/complete-first-access", lambda route: route.fulfill(
                status=200, content_type="application/json", body='{"success":true,"data":{"action":"LOGIN_REQUIRED"}}'))
            try:
                await page.goto(link)
                await ready(page, "Nueva contraseña")
                field = page.get_by_label("Nueva contraseña", exact=True)
                await field.click()
                await page.keyboard.type(secrets.token_hex(12)+"Aa1!", delay=5)
                await page.keyboard.press('Tab')
                await page.get_by_text("Establecer contraseña", exact=True).click()
                await ready(page, "Iniciar sesión")
                assert "#/login" in page.url, "server success must win over device clock"
            finally:
                await page.close()
    await case("ACTIVATION-DEVICE-CLOCK-PLUS-MINUS-24H", device_clock)
    await ctx.close()
    await browser.close()
    await playwright.stop()
    return {"cases": results}
