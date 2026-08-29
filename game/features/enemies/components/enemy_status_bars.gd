class_name EnemyStatusBars
extends Node2D

@export_range(20.0, 96.0, 1.0) var bar_width: float = 36.0
@export_range(2.0, 12.0, 1.0) var health_height: float = 5.0
@export_range(1.0, 8.0, 1.0) var armor_height: float = 3.0
@export var background_color := Color(0.025, 0.035, 0.045, 0.92)
@export var health_color := Color(0.95, 0.24, 0.2, 1.0)
@export var armor_color := Color(0.2, 0.66, 1.0, 1.0)
@export var border_color := Color(0.82, 0.88, 0.9, 0.75)

var health: HealthComponent
var armor: ArmorComponent


func configure(health_component: HealthComponent, armor_component: ArmorComponent) -> void:
	health = health_component
	armor = armor_component
	if not health.value_changed.is_connected(_on_value_changed):
		health.value_changed.connect(_on_value_changed)
	if armor != null and not armor.value_changed.is_connected(_on_value_changed):
		armor.value_changed.connect(_on_value_changed)
	queue_redraw()


func _on_value_changed(_current: float, _maximum: float) -> void:
	queue_redraw()


func _draw() -> void:
	if health == null:
		return

	var left := -bar_width * 0.5
	var health_y := -29.0
	var health_ratio := health.current_value / health.maximum_value
	_draw_bar(Rect2(left, health_y, bar_width, health_height), health_ratio, health_color)

	if armor != null and armor.maximum_value > 0.0:
		var armor_ratio := armor.current_value / armor.maximum_value
		_draw_bar(
			Rect2(left, health_y - armor_height - 2.0, bar_width, armor_height),
			armor_ratio,
			armor_color
		)


func _draw_bar(rect: Rect2, ratio: float, fill_color: Color) -> void:
	draw_rect(rect, background_color)
	var fill_rect := rect.grow(-1.0)
	fill_rect.size.x *= clampf(ratio, 0.0, 1.0)
	draw_rect(fill_rect, fill_color)
	draw_rect(rect, border_color, false, 1.0)
