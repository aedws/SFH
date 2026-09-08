class_name RoomDoorBarrier
extends Node2D

const COLLISION_LAYER := 16

var barrier_size := Vector2(14.0, 32.0)


func configure(world_position: Vector2, new_size: Vector2) -> bool:
	if new_size.x <= 0.0 or new_size.y <= 0.0:
		return false
	global_position = world_position
	barrier_size = new_size
	add_to_group(&"fog_visibility_blocker")
	var body := StaticBody2D.new()
	body.collision_layer = COLLISION_LAYER
	body.collision_mask = 0
	var shape := RectangleShape2D.new()
	shape.size = barrier_size
	var collision := CollisionShape2D.new()
	collision.shape = shape
	body.add_child(collision)
	add_child(body)
	queue_redraw()
	return true


func get_visibility_bounds() -> Rect2:
	return Rect2(global_position - barrier_size * 0.5, barrier_size)


func _draw() -> void:
	var rect := Rect2(-barrier_size * 0.5, barrier_size)
	draw_rect(rect, Color(0.08, 0.18, 0.24, 0.96), true)
	draw_rect(rect.grow(-2.0), Color(0.2, 0.62, 1.0, 0.68), true)
	var horizontal := barrier_size.x > barrier_size.y
	var span := barrier_size.x if horizontal else barrier_size.y
	var segment_count := maxi(1, floori(span / 12.0))
	for segment_index in segment_count:
		var ratio := (float(segment_index) + 0.5) / float(segment_count) - 0.5
		var offset := ratio * span
		if horizontal:
			draw_line(Vector2(offset, -barrier_size.y * 0.4), Vector2(offset, barrier_size.y * 0.4), Color(0.76, 0.94, 1.0), 2.0)
		else:
			draw_line(Vector2(-barrier_size.x * 0.4, offset), Vector2(barrier_size.x * 0.4, offset), Color(0.76, 0.94, 1.0), 2.0)
