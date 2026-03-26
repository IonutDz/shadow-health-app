{{flutter_js}}
{{flutter_build_config}}

const isMobile = /Android|iPhone|iPad|iPod|Mobile/i.test(navigator.userAgent);
_flutter.loader.load({
  config: {
    renderer: isMobile ? "skwasm" : "canvaskit",
  },
});
