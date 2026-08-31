extends Control

## 에셋 없이도 작전 지역의 구조·경로·위험도를 읽을 수 있는 전술 브리핑 프리뷰입니다.

var accent_color := Color("36d9bd")
var danger_color := Color("ffad45")
var risk_level: int = 0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(500.0, 238.0)


func update_context(region_id: StringName, tier_id: StringName, difficulty_id: StringName) -> void:
	risk_level = {&"standard": 0, &"veteran": 1, &"nightmare": 2}.get(difficulty_id, 0)
	accent_color = {
		&"ruined_city": Color("35d8bd"),
		&"industrial_district": Color("5ac8fa"),
		&"research_complex": Color("b89cff"),
	}.get(region_id, Color("35d8bd"))
	danger_color = {
		&"small": Color("6fe7c8"),
		&"medium": Color("ffcb68"),
		&"large": Color("ff7d78"),
	}.get(tier_id, Color("ffad45"))
	queue_redraw()


func _draw() -> void:
	var bounds := Rect2(Vector2.ZERO, size)
	draw_rect(bounds, Color("07121a"), true)
	draw_rect(bounds.grow(-1.0), Color(accent_color, 0.72), false, 2.0)
	for x in range(24, int(size.x), 32):
		draw_line(Vector2(x, 0), Vector2(x, size.y), Color(accent_color, 0.055), 1.0)
	for y in range(20, int(size.y), 28):
		draw_line(Vector2(0, y), Vector2(size.x, y), Color(accent_color, 0.055), 1.0)

	var rooms := [
		Rect2(34, 42, 92, 58), Rect2(164, 28, 112, 72), Rect2(320, 44, 142, 62),
		Rect2(60, 146, 126, 58), Rect2(226, 132, 92, 70), Rect2(368, 140, 96, 62),
	]
	for index in rooms.size():
		var room: Rect2 = rooms[index]
		var fill := Color(accent_color, 0.08 + float(index % 3) * 0.025)
		draw_rect(room, fill, true)
		draw_rect(room, Color(accent_color, 0.42), false, 1.5)
		var inset := room.grow(-8.0)
		draw_line(inset.position, inset.position + Vector2(inset.size.x, 0), Color(accent_color, 0.18), 1.0)

	var route := PackedVector2Array([
		Vector2(78, 72), Vector2(164, 64), Vector2(220, 64), Vector2(320, 75),
		Vector2(390, 75), Vector2(414, 140), Vector2(414, 170),
	])
	draw_polyline(route, Color(accent_color, 0.9), 3.0, true)
	for point in route:
		draw_circle(point, 4.0, Color("d8fff8"))
	draw_circle(route[0], 11.0, Color(accent_color, 0.18))
	draw_circle(route[0], 7.0, accent_color)
	draw_circle(route[-1], 12.0, Color(danger_color, 0.22))
	draw_circle(route[-1], 7.0, danger_color)

	for index in range(3 + risk_level * 2):
		var point := Vector2(118.0 + index * 61.0, 118.0 + (index % 2) * 36.0)
		draw_circle(point, 5.0, Color(danger_color, 0.92))
		draw_circle(point, 11.0, Color(danger_color, 0.12), false, 1.0)
