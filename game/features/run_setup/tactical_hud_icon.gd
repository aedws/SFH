class_name TacticalHudIcon
extends Control

## 외부 텍스처와 이모지 글꼴에 의존하지 않는 전술 HUD 벡터 아이콘입니다.

enum Kind {
	HEALTH,
	EXPERIENCE,
	LEVEL,
	KILLS,
	CREDIT,
	WEAPON,
	ARMOR,
	SKILL,
	ENERGY,
	DASH,
	INTERACT,
	INPUT,
}

@export var kind: Kind = Kind.INPUT
@export var accent_color := Color("02e5e1")
@export_range(0, 8, 1) var variant: int = 0


func configure(
	new_kind: Kind,
	semantic_label: String,
	new_accent: Color = Color("02e5e1"),
	new_variant: int = 0
) -> TacticalHudIcon:
	kind = new_kind
	accent_color = new_accent
	variant = new_variant
	tooltip_text = semantic_label
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(24.0, 24.0)
	queue_redraw()
	return self


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()


func _draw() -> void:
	var icon_size := minf(size.x, size.y)
	if icon_size <= 2.0:
		return
	var center := Vector2(icon_size * 0.5, size.y * 0.5)
	var radius := maxf(4.0, icon_size * 0.31)
	var faint := Color(accent_color.r, accent_color.g, accent_color.b, 0.16)
	var line := maxf(1.25, icon_size * 0.07)
	draw_rect(
		Rect2(center - Vector2(radius + 3.0, radius + 3.0), Vector2.ONE * (radius + 3.0) * 2.0),
		faint,
		true
	)
	match kind:
		Kind.HEALTH:
			_draw_health(center, radius, line)
		Kind.EXPERIENCE:
			_draw_experience(center, radius, line)
		Kind.LEVEL:
			_draw_level(center, radius, line)
		Kind.KILLS:
			_draw_kills(center, radius, line)
		Kind.CREDIT:
			_draw_credit(center, radius, line)
		Kind.WEAPON:
			_draw_weapon(center, radius, line)
		Kind.ARMOR:
			_draw_armor(center, radius, line)
		Kind.SKILL:
			_draw_skill(center, radius, line)
		Kind.ENERGY:
			_draw_energy(center, radius, line)
		Kind.DASH:
			_draw_dash(center, radius, line)
		Kind.INTERACT:
			_draw_interact(center, radius, line)
		_:
			_draw_input(center, radius, line)


func _draw_health(center: Vector2, radius: float, line: float) -> void:
	var lobe := radius * 0.42
	draw_circle(center + Vector2(-lobe * 0.58, -lobe * 0.34), lobe, accent_color)
	draw_circle(center + Vector2(lobe * 0.58, -lobe * 0.34), lobe, accent_color)
	draw_colored_polygon(PackedVector2Array([
		center + Vector2(-radius * 0.82, -radius * 0.15),
		center + Vector2(radius * 0.82, -radius * 0.15),
		center + Vector2(0.0, radius * 0.9),
	]), accent_color)


func _draw_experience(center: Vector2, radius: float, line: float) -> void:
	var points := PackedVector2Array([
		center + Vector2(0.0, -radius), center + Vector2(radius, 0.0),
		center + Vector2(0.0, radius), center + Vector2(-radius, 0.0),
		center + Vector2(0.0, -radius),
	])
	draw_polyline(points, accent_color, line, true)
	draw_circle(center, radius * 0.22, accent_color)


func _draw_level(center: Vector2, radius: float, line: float) -> void:
	for offset in [-0.34, 0.34]:
		draw_polyline(PackedVector2Array([
			center + Vector2(-radius * 0.72, radius * offset),
			center + Vector2(0.0, radius * (offset - 0.5)),
			center + Vector2(radius * 0.72, radius * offset),
		]), accent_color, line, true)


func _draw_kills(center: Vector2, radius: float, line: float) -> void:
	draw_arc(center, radius * 0.65, 0.0, TAU, 24, accent_color, line, true)
	draw_circle(center, radius * 0.16, accent_color)
	draw_line(center + Vector2(-radius, 0.0), center + Vector2(-radius * 0.42, 0.0), accent_color, line)
	draw_line(center + Vector2(radius * 0.42, 0.0), center + Vector2(radius, 0.0), accent_color, line)
	draw_line(center + Vector2(0.0, -radius), center + Vector2(0.0, -radius * 0.42), accent_color, line)
	draw_line(center + Vector2(0.0, radius * 0.42), center + Vector2(0.0, radius), accent_color, line)


func _draw_credit(center: Vector2, radius: float, line: float) -> void:
	draw_arc(center, radius * 0.82, 0.0, TAU, 24, accent_color, line, true)
	draw_arc(center, radius * 0.48, PI * 0.28, PI * 1.72, 18, accent_color, line, true)


func _draw_weapon(center: Vector2, radius: float, line: float) -> void:
	draw_line(center + Vector2(-radius, -radius * 0.18), center + Vector2(radius * 0.76, -radius * 0.18), accent_color, line * 1.35)
	draw_line(center + Vector2(-radius * 0.55, radius * 0.1), center + Vector2(radius * 0.35, radius * 0.1), accent_color, line)
	draw_line(center + Vector2(radius * 0.1, radius * 0.05), center + Vector2(radius * 0.42, radius * 0.82), accent_color, line * 1.2)


func _draw_armor(center: Vector2, radius: float, line: float) -> void:
	draw_polyline(PackedVector2Array([
		center + Vector2(0.0, -radius), center + Vector2(radius * 0.8, -radius * 0.62),
		center + Vector2(radius * 0.62, radius * 0.48), center + Vector2(0.0, radius),
		center + Vector2(-radius * 0.62, radius * 0.48), center + Vector2(-radius * 0.8, -radius * 0.62),
		center + Vector2(0.0, -radius),
	]), accent_color, line, true)


func _draw_skill(center: Vector2, radius: float, line: float) -> void:
	if variant == 1:
		draw_arc(center, radius * 0.75, 0.0, TAU, 28, accent_color, line, true)
		draw_arc(center, radius * 0.35, 0.0, TAU, 20, accent_color, line, true)
	elif variant == 2:
		_draw_dash(center, radius, line)
	else:
		_draw_energy(center, radius, line)


func _draw_energy(center: Vector2, radius: float, line: float) -> void:
	draw_colored_polygon(PackedVector2Array([
		center + Vector2(radius * 0.15, -radius), center + Vector2(-radius * 0.55, radius * 0.08),
		center + Vector2(-radius * 0.05, radius * 0.08), center + Vector2(-radius * 0.22, radius),
		center + Vector2(radius * 0.62, -radius * 0.2), center + Vector2(radius * 0.12, -radius * 0.2),
	]), accent_color)


func _draw_dash(center: Vector2, radius: float, line: float) -> void:
	for offset in [-0.34, 0.34]:
		draw_polyline(PackedVector2Array([
			center + Vector2(radius * (offset - 0.42), -radius * 0.72),
			center + Vector2(radius * (offset + 0.28), 0.0),
			center + Vector2(radius * (offset - 0.42), radius * 0.72),
		]), accent_color, line, true)


func _draw_interact(center: Vector2, radius: float, line: float) -> void:
	draw_arc(center, radius * 0.72, 0.0, TAU, 24, accent_color, line, true)
	draw_circle(center, radius * 0.2, accent_color)


func _draw_input(center: Vector2, radius: float, line: float) -> void:
	draw_rect(Rect2(center - Vector2(radius * 0.78, radius * 0.58), Vector2(radius * 1.56, radius * 1.16)), accent_color, false, line)
	draw_line(center + Vector2(-radius * 0.42, radius * 0.2), center + Vector2(radius * 0.42, radius * 0.2), accent_color, line)
