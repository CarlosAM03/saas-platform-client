{{flutter_js}}
{{flutter_build_config}}

// Serve renderer assets from this app, not a third-party CDN on activation.
_flutter.loader.load({config: {canvasKitBaseUrl: 'canvaskit/'}});
