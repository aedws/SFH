class_name MobileOrientationPolicy
extends RefCounted

## 기기 방향 요청만 담당합니다. 요청 실패가 로비 진입·저장·입력을 막지 않습니다.
const WEB_REQUEST := """
(() => {
  const orientation = window.screen && window.screen.orientation;
  const lock = () => {
    if (!orientation || typeof orientation.lock !== 'function') return;
    try { Promise.resolve(orientation.lock('landscape')).catch(() => {}); } catch (_) {}
  };
  if (FULLSCREEN_REQUEST && !document.fullscreenElement && typeof document.documentElement.requestFullscreen === 'function') {
    try { Promise.resolve(document.documentElement.requestFullscreen()).then(lock, lock); } catch (_) { lock(); }
  } else { lock(); }
  return 'requested';
})()
"""
const WEB_RELEASE := """
(() => {
  try { if (window.screen && window.screen.orientation && typeof window.screen.orientation.unlock === 'function') window.screen.orientation.unlock(); } catch (_) {}
})()
"""

static func request_landscape(fullscreen_requested := false) -> void:
	if OS.has_feature("web"):
		JavaScriptBridge.eval(WEB_REQUEST.replace("FULLSCREEN_REQUEST", "true" if fullscreen_requested else "false"))
	elif DisplayServer.has_feature(DisplayServer.FEATURE_ORIENTATION):
		DisplayServer.screen_set_orientation(DisplayServer.SCREEN_SENSOR_LANDSCAPE)

static func release_lock() -> void:
	if OS.has_feature("web"):
		JavaScriptBridge.eval(WEB_RELEASE)

static func is_portrait(view_size: Vector2) -> bool:
	return view_size.y > view_size.x

static func guidance(view_size: Vector2) -> String:
	if is_portrait(view_size):
		return "모바일은 가로 플레이가 기본입니다. 기기를 가로로 돌려 주세요.\n회전되지 않으면 기기의 화면 회전 잠금을 해제하세요."
	return "모바일 가로 플레이 · 왼쪽 이동 / 오른쪽 공격·스킬"
