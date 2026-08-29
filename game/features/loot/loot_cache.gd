class_name CreditLootCache
extends Area2D

signal credits_collected(amount: int, world_position: Vector2)
signal interaction_availability_changed(available: bool, prompt: String)

@export var interaction_action: StringName = &"interact"
@export_range(24.0, 128.0, 4.0) var interaction_radius: float = 58.0
@export var credit_amount: int = 25

var nearby_player: Node2D
var collected: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	queue_redraw()


func configure(amount: int) -> void:
	credit_amount = maxi(0, amount)


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
	interaction_availability_changed.emit(true, "F · 보급 상자 수색 (+%d 크레딧)" % credit_amount)


func _on_body_exited(body: Node2D) -> void:
	if body != nearby_player:
		return
	nearby_player = null
	interaction_availability_changed.emit(false, "")


func _draw() -> void:
	var shadow := Rect2(-18.0, -12.0, 36.0, 28.0)
	draw_rect(Rect2(shadow.position + Vector2(3.0, 4.0), shadow.size), Color(0.0, 0.0, 0.0, 0.35))
	draw_rect(shadow, Color(0.34, 0.25, 0.11, 1.0))
	draw_rect(Rect2(-18.0, -12.0, 36.0, 8.0), Color(0.75, 0.54, 0.18, 1.0))
	draw_rect(Rect2(-3.0, -12.0, 6.0, 28.0), Color(0.92, 0.7, 0.25, 1.0))
	draw_circle(Vector2(0.0, 3.0), 5.0, Color(1.0, 0.83, 0.32, 1.0))
	draw_circle(Vector2(0.0, 3.0), 2.0, Color(0.45, 0.3, 0.08, 1.0))
