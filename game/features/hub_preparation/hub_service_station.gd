class_name HubServiceStation
extends Node2D
## Placeable interaction endpoint. No shop, inventory or operation state ownership.
signal service_requested(service_id: StringName)
signal interaction_availability_changed(available: bool, prompt: String)

@export var service_id: StringName = &"shop"
@export var display_name := "보급 상점"
@export var accent := Color("02e5e1")
@export_range(48, 180, 4) var interaction_radius := 110.0
@export var interaction_action: StringName = &"interact"
var actor: Node2D


func _ready() -> void:
	var area := Area2D.new()
	area.collision_layer = 0
	area.collision_mask = 1
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = interaction_radius
	collision.shape = shape
	area.add_child(collision)
	add_child(area)
	area.body_entered.connect(func(body):
		if body.is_in_group(&"player"):
			actor = body
			interaction_availability_changed.emit(true, "F · %s" % display_name))
	area.body_exited.connect(func(body):
		if body == actor:
			actor = null
			interaction_availability_changed.emit(false, ""))
	var label := Label.new()
	label.text = display_name
	label.position = Vector2(-105, 62)
	label.size = Vector2(210, 36)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", accent)
	add_child(label)
	queue_redraw()


func request_service(player: Node2D) -> bool:
	if not is_instance_valid(player) or not player.is_in_group(&"player"):
		return false
	if player != actor and player.global_position.distance_to(global_position) > interaction_radius:
		return false
	service_requested.emit(service_id)
	return true


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(interaction_action) and not event.is_echo() and request_service(actor):
		get_viewport().set_input_as_handled()


func _draw() -> void:
	draw_circle(Vector2.ZERO, interaction_radius, Color(accent, 0.07))
	draw_rect(Rect2(-58, -42, 116, 84), Color("071c26"))
	draw_rect(Rect2(-58, -42, 116, 84), accent, false, 3)
	draw_rect(Rect2(-36, -24, 72, 40), Color(accent, 0.18))
	draw_line(Vector2(-28, 30), Vector2(28, 30), accent, 4)
