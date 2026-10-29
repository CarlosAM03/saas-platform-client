// The engine can snapshot the initial URL before Dart main runs. Scrub first,
// including history.state, and hand the original location to Dart exactly once.
(() => {
 const capture = (initial = false) => {
  const href = window.location.href;
  const fragment = href.slice(href.indexOf('#') + 1);
  if (!href.includes('#') || fragment.split('?')[0] !== '/activate') return;
  if (!initial && !fragment.includes('?')) return;
  const clean = new URL(href);
  clean.hash = '/activate';
  try {
    window.history.replaceState(null, '', clean.href);
  } catch (_) {
    throw new Error('No se pudo limpiar la ubicación de activación.');
  }
  let captured = href;
  window.__prospectorTakeActivationLocation = () => {
    const value = captured;
    captured = null;
    delete window.__prospectorTakeActivationLocation;
    return value;
  };
 };
 // Registered before Flutter so a link opened in an existing document is also
 // scrubbed before the router observes the browser navigation event.
 window.addEventListener('popstate', () => capture(), true);
 window.addEventListener('hashchange', () => capture(), true);
 capture(true);
})();

{{flutter_js}}
{{flutter_build_config}}

// Serve renderer assets from this app, not a third-party CDN on activation.
_flutter.loader.load({config: {canvasKitBaseUrl: 'canvaskit/'}});
