class_name RoomCreditRewardBox
extends Area2D

## 방 클리어 보상 전용 상호작용 오브젝트입니다.
## 크레딧 원장을 알지 않고 회수 Signal만 공개합니다.

signal credits_collected(amount: int, world_position: Vector2)
signal interaction_availability_changed(available: bool, prompt: String)

@export var interaction_action: StringName = &"interact"
@export_range(24.0, 128.0, 4.0) var interaction_radius: float = 58.0

var credit_amount: int = 1
var reward_kind: StringName = &"field_cache"
var nearby_player: Node2D
var collected := false


func _ready() -> void:
	add_to_group(&"room_credit_reward_box")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	queue_redraw()


func configure(amount: int, new_reward_kind: StringName = &"field_cache") -> void:
	credit_amount = maxi(1, amount)
	reward_kind = new_reward_kind
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
	if is_instance_valid(nearby_player) and event.is_action_pressed(interaction_action):
		if request_loot(nearby_player):
			get_viewport().set_input_as_handled()


func _on_body_entered(body: Node2D) -> void:
	if collected or not body.is_in_group(&"player"):
		return
	nearby_player = body
	interaction_availability_changed.emit(
		true, "F · 방 보상 박스 개방 · 크레딧 회수 (+%d)" % credit_amount
	)


func _on_body_exited(body: Node2D) -> void:
	if body != nearby_player:
		return
	nearby_player = null
	interaction_availability_changed.emit(false, "")


func _draw() -> void:
	var accent := Color("02e5e1")
	var reward_color := (
		Color(0.98, 0.68, 0.18, 1.0)
		if reward_kind == &"recovery_terminal" else accent
	)
	var body_rect := Rect2(-23.0, -15.0, 46.0, 30.0)
	draw_rect(Rect2(body_rect.position + Vector2(3.0, 4.0), body_rect.size), Color(0, 0, 0, 0.46))
	draw_rect(body_rect, Color(0.035, 0.07, 0.085, 1.0))
	draw_rect(body_rect, reward_color, false, 2.0)
	draw_line(Vector2(-16.0, -7.0), Vector2(16.0, -7.0), reward_color, 2.0)
	draw_circle(Vector2(0.0, 4.0), 6.0, Color(0.01, 0.02, 0.025, 1.0))
	draw_arc(Vector2(0.0, 4.0), 4.0, 0.0, TAU, 16, reward_color, 2.0)
