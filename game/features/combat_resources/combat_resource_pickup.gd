class_name CombatResourcePickup
extends Area2D

signal collected(resource_id: StringName, amount: float)

const ENERGY_COLOR := Color(0.22, 0.72, 1.0, 1.0)
const HEALTH_COLOR := Color(0.3, 1.0, 0.48, 1.0)

@export var resource_id: StringName = &"energy"
@export_range(0.1, 1000.0, 0.1) var amount: float = 1.0
@export_range(16.0, 1000.0, 8.0) var magnet_radius: float = 150.0
@export_range(1.0, 2000.0, 10.0) var magnet_speed: float = 320.0

@onready var body: Polygon2D = $Body


func configure(
	new_resource_id: StringName,
	new_amount: float,
	new_magnet_radius: float,
	new_magnet_speed: float
) -> bool:
	if new_resource_id not in [&"energy", &"health"] or new_amount <= 0.0:
		return false
	resource_id = new_resource_id
	amount = new_amount
	magnet_radius = new_magnet_radius
	magnet_speed = new_magnet_speed
	body.color = ENERGY_COLOR if resource_id == &"energy" else HEALTH_COLOR
	return true


func _physics_process(delta: float) -> void:
	var player := get_tree().get_first_node_in_group(&"player") as Node2D
	if not is_instance_valid(player):
		return
	if global_position.distance_squared_to(player.global_position) <= magnet_radius * magnet_radius:
		global_position = global_position.move_toward(player.global_position, magnet_speed * delta)


func _on_body_entered(candidate: Node) -> void:
	if not candidate.is_in_group(&"player"):
		return
	collected.emit(resource_id, amount)
	queue_free()
