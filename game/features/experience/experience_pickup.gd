class_name ExperiencePickup
extends Area2D

signal collected(amount: int)

@export_range(1, 1000, 1) var amount: int = 1
@export_range(16.0, 1000.0, 8.0) var magnet_radius: float = 150.0
@export_range(1.0, 2000.0, 10.0) var magnet_speed: float = 320.0


func _physics_process(delta: float) -> void:
	var player := get_tree().get_first_node_in_group(&"player") as Node2D
	if not is_instance_valid(player):
		return

	if global_position.distance_squared_to(player.global_position) <= magnet_radius * magnet_radius:
		global_position = global_position.move_toward(player.global_position, magnet_speed * delta)


func _on_body_entered(body: Node) -> void:
	if body.is_in_group(&"player"):
		collected.emit(amount)
		queue_free()
