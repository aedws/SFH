class_name RoomRewardPickup
extends Area2D

signal collected(room_index: int, experience_amount: int)

var room_index: int = -1
var experience_amount: int = 1
var elapsed_seconds: float = 0.0


func configure(new_room_index: int, new_experience_amount: int) -> bool:
	if new_room_index < 0 or new_experience_amount <= 0:
		return false
	room_index = new_room_index
	experience_amount = new_experience_amount
	add_to_group(&"room_encounter_reward")
	return true


func collect() -> void:
	if is_queued_for_deletion():
		return
	collected.emit(room_index, experience_amount)
	queue_free()


func _process(delta: float) -> void:
	elapsed_seconds += maxf(0.0, delta)
	rotation = sin(elapsed_seconds * 2.2) * 0.08
	queue_redraw()


func _on_body_entered(body: Node) -> void:
	if body.is_in_group(&"player"):
		collect()


func _draw() -> void:
	var pulse := 1.0 + sin(elapsed_seconds * 4.0) * 0.08
	draw_circle(Vector2.ZERO, 22.0 * pulse, Color(0.08, 0.32, 0.46, 0.72))
	draw_circle(Vector2.ZERO, 15.0 * pulse, Color(0.2, 0.78, 1.0, 0.92))
	draw_rect(Rect2(Vector2(-8, -7), Vector2(16, 14)), Color(0.7, 0.94, 1.0), true)
	draw_line(Vector2(-5, 0), Vector2(5, 0), Color(0.08, 0.26, 0.34), 2.0)
