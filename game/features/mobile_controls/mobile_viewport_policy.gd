extends RefCounted

## CSS 픽셀 크기와 관계없이 터치 표면이 작아지지 않도록 논리 해상도를 정합니다.
static func logical_size(window_size: Vector2i, mobile: bool) -> Vector2i:
	if not mobile:
		return Vector2i(1280, 720)
	var aspect := float(window_size.x) / maxf(1.0, window_size.y)
	if aspect >= 1.0:
		return Vector2i(roundi(480.0 * aspect), 480)
	return Vector2i(480, roundi(480.0 / maxf(0.25, aspect)))
