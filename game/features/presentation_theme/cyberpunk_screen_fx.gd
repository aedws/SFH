class_name CyberpunkScreenFX
extends Control

## 전체 화면의 정적 스캔라인·희박한 도트 노이즈·모서리 HUD를 그립니다.
## 게임 상태나 다른 UI 입력은 소유하지 않습니다.

const ACCENT := Color("02e5e1")
const SCANLINE_SPACING := 6
const NOISE_CELL_SIZE := 32

var noise_enabled: bool = true
var noise_point_count: int = 0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)
	queue_redraw()


func configure(new_noise_enabled: bool) -> void:
	noise_enabled = new_noise_enabled
	queue_redraw()


func get_snapshot() -> Dictionary:
	return {
		&"accent_hex": "#02e5e1",
		&"scanline_spacing": SCANLINE_SPACING,
		&"noise_enabled": noise_enabled,
		&"noise_point_count": noise_point_count,
		&"size": size,
	}


func _draw() -> void:
	noise_point_count = 0
	if size.x <= 1.0 or size.y <= 1.0:
		return
	for y in range(0, int(size.y), SCANLINE_SPACING):
		draw_line(Vector2(0.0, y), Vector2(size.x, y), Color(ACCENT, 0.018), 1.0)
	if noise_enabled:
		_draw_deterministic_noise()
	_draw_frame_marks()


func _draw_deterministic_noise() -> void:
	var columns := int(ceil(size.x / float(NOISE_CELL_SIZE)))
	var rows := int(ceil(size.y / float(NOISE_CELL_SIZE)))
	for row in rows:
		for column in columns:
			var sample := (column * 19 + row * 31 + column * row * 3) % 23
			if sample not in [0, 7]:
				continue
			var point := Vector2(
				column * NOISE_CELL_SIZE + 5 + sample,
				row * NOISE_CELL_SIZE + 4 + ((column + row) % 13)
			)
			draw_rect(Rect2(point, Vector2(1.0, 1.0)), Color(ACCENT, 0.075), true)
			noise_point_count += 1


func _draw_frame_marks() -> void:
	var inset := 7.0
	var length := 36.0
	var line_color := Color(ACCENT, 0.36)
	var corners := [
		[Vector2(inset, inset + length), Vector2(inset, inset), Vector2(inset + length, inset)],
		[Vector2(size.x - inset - length, inset), Vector2(size.x - inset, inset), Vector2(size.x - inset, inset + length)],
		[Vector2(inset, size.y - inset - length), Vector2(inset, size.y - inset), Vector2(inset + length, size.y - inset)],
		[Vector2(size.x - inset - length, size.y - inset), Vector2(size.x - inset, size.y - inset), Vector2(size.x - inset, size.y - inset - length)],
	]
	for points in corners:
		draw_polyline(PackedVector2Array(points), line_color, 1.0)
	draw_line(
		Vector2(size.x * 0.5 - 72.0, inset),
		Vector2(size.x * 0.5 + 72.0, inset),
		Color(ACCENT, 0.18), 1.0
	)
