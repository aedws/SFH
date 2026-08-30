class_name CreditLootCache
extends Area2D

signal credits_collected(amount: int, world_position: Vector2)
signal interaction_availability_changed(available: bool, prompt: String)

@export var interaction_action: StringName = &"interact"
@export_range(24.0, 128.0, 4.0) var interaction_radius: float = 58.0
@export var credit_amount: int = 25
@export_enum("wall_safe", "material_locker", "recovery_terminal") var placement_kind: String = "wall_safe"

var nearby_player: Node2D
var collected: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	queue_redraw()


func configure(
	amount: int,
	new_placement_kind: StringName = &"wall_safe",
	facing: Vector2 = Vector2.DOWN
) -> void:
	credit_amount = maxi(0, amount)
	placement_kind = String(
		new_placement_kind
		if new_placement_kind in [&"wall_safe", &"material_locker", &"recovery_terminal"]
		else &"wall_safe"
	)
	rotation = facing.angle() - PI * 0.5
	queue_redraw()


func request_loot(actor: Node2D) -> bool:
	if collected or not is_instance_valid(actor) or not actor.is_in_group(&"player"):
		return false
	if actor.global_position.distance_to(global_position) > interaction_radius:
		return false

	collected = true
	interaction_availability_changed.emit(false, "")
	credits_collected.emit(credit_amount, global_position)
	queue_free()
	return true


func _unhandled_input(event: InputEvent) -> void:
	if not is_instance_valid(nearby_player):
		return
	if event.is_action_pressed(interaction_action) and request_loot(nearby_player):
		get_viewport().set_input_as_handled()


func _on_body_entered(body: Node2D) -> void:
	if collected or not body.is_in_group(&"player"):
		return
	nearby_player = body
	interaction_availability_changed.emit(true, _interaction_prompt())


func _on_body_exited(body: Node2D) -> void:
	if body != nearby_player:
		return
	nearby_player = null
	interaction_availability_changed.emit(false, "")


func _draw() -> void:
	match placement_kind:
		"material_locker":
			_draw_material_locker()
		"recovery_terminal":
			_draw_recovery_terminal()
		_:
			_draw_wall_safe()


func _interaction_prompt() -> String:
	match placement_kind:
		"material_locker":
			return "F · 벽면 자재함 개방 · 자원 회수 (+%d)" % credit_amount
		"recovery_terminal":
			return "F · 회수 단말기 접속 · 크레딧 전송 (+%d)" % credit_amount
		_:
			return "F · 벽면 금고 잠금 해제 · 크레딧 회수 (+%d)" % credit_amount


func _draw_wall_safe() -> void:
	var body_rect := Rect2(-22.0, -9.0, 44.0, 28.0)
	draw_rect(Rect2(body_rect.position + Vector2(3.0, 4.0), body_rect.size), Color(0, 0, 0, 0.42))
	draw_rect(body_rect, Color(0.13, 0.17, 0.19, 1.0))
	draw_rect(body_rect.grow(-2.5), Color(0.27, 0.34, 0.35, 1.0), false, 2.0)
	draw_circle(Vector2(8.0, 5.0), 7.0, Color(0.07, 0.1, 0.11, 1.0))
	draw_arc(Vector2(8.0, 5.0), 4.0, 0.0, TAU, 16, Color(0.28, 0.94, 0.73, 1.0), 2.0)
	draw_rect(Rect2(-16.0, -2.0, 11.0, 4.0), Color(0.86, 0.61, 0.18, 1.0))


func _draw_material_locker() -> void:
	var body_rect := Rect2(-25.0, -8.0, 50.0, 30.0)
	draw_rect(Rect2(body_rect.position + Vector2(3.0, 4.0), body_rect.size), Color(0, 0, 0, 0.4))
	draw_rect(body_rect, Color(0.18, 0.21, 0.22, 1.0))
	for index in range(3):
		var door := Rect2(-21.0 + index * 15.0, -4.0, 12.0, 22.0)
		draw_rect(door, Color(0.34, 0.37, 0.35, 1.0))
		draw_rect(door, Color(0.63, 0.49, 0.18, 1.0), false, 1.5)
		draw_circle(door.position + Vector2(8.5, 11.0), 1.8, Color(0.95, 0.72, 0.24, 1.0))


func _draw_recovery_terminal() -> void:
	var base := PackedVector2Array([
		Vector2(-20.0, 14.0), Vector2(20.0, 14.0), Vector2(15.0, 23.0), Vector2(-15.0, 23.0)
	])
	draw_colored_polygon(base, Color(0.11, 0.16, 0.18, 1.0))
	draw_rect(Rect2(-17.0, -18.0, 34.0, 34.0), Color(0.14, 0.22, 0.25, 1.0))
	draw_rect(Rect2(-12.0, -13.0, 24.0, 17.0), Color(0.04, 0.09, 0.1, 1.0))
	draw_rect(Rect2(-9.0, -10.0, 18.0, 11.0), Color(0.18, 0.8, 0.67, 0.85))
	draw_line(Vector2(-8.0, 8.0), Vector2(8.0, 8.0), Color(0.88, 0.62, 0.2, 1.0), 3.0)
