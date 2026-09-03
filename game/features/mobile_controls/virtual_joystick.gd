extends Control

## 손가락 하나의 소유권과 방향만 관리합니다. 이동·전투 규칙은 알지 못합니다.
signal direction_changed(direction: Vector2)
@export_range(0.0, 0.4) var deadzone := 0.12
var finger := -1
var direction := Vector2.ZERO

func begin(index: int, point: Vector2) -> bool:
	if finger != -1 or not get_global_rect().has_point(point):
		return false
	finger = index
	drag(index, point)
	return true

func drag(index: int, point: Vector2) -> void:
	if index != finger:
		return
	var radius := maxf(1.0, size.x * 0.36)
	var raw := ((point - get_global_rect().get_center()) / radius).limit_length()
	direction = Vector2.ZERO if raw.length() < deadzone else raw
	direction_changed.emit(direction)
	queue_redraw()

func release(index: int = -1) -> void:
	if index != -1 and index != finger:
		return
	finger = -1
	direction = Vector2.ZERO
	direction_changed.emit(direction)
	queue_redraw()

func _draw() -> void:
	var center := size * 0.5
	var radius := size.x * 0.42
	draw_circle(center, radius, Color("03141aaa"))
	draw_arc(center, radius, 0, TAU, 64, Color("02e5e180"), 2, true)
	draw_line(center - Vector2(radius * 0.65, 0), center + Vector2(radius * 0.65, 0), Color("02e5e12e"))
	draw_line(center - Vector2(0, radius * 0.65), center + Vector2(0, radius * 0.65), Color("02e5e12e"))
	draw_circle(center + direction * size.x * 0.28, radius * 0.34, Color("02e5e1b0"))
