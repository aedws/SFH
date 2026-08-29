class_name ProgressionSystem
extends Node

signal progress_changed(level: int, current: int, required: int)
signal level_increased(level: int)

@export var pickup_scene: PackedScene

var pickup_parent: Node2D
var leveling_enabled: bool = true
var level: int = 1
var current_experience: int = 0
var required_experience: int = 5


func configure(new_pickup_parent: Node2D, enable_leveling: bool) -> void:
	pickup_parent = new_pickup_parent
	leveling_enabled = enable_leveling
	progress_changed.emit(level, current_experience, required_experience)


func spawn_pickup(world_position: Vector2, amount: int) -> void:
	if pickup_scene == null or not is_instance_valid(pickup_parent):
		return

	var pickup := pickup_scene.instantiate() as Area2D
	if pickup == null:
		return

	pickup.set("amount", amount)
	pickup_parent.add_child(pickup)
	pickup.global_position = world_position
	pickup.connect(&"collected", Callable(self, &"gain_experience"))


func gain_experience(amount: int) -> void:
	if amount <= 0:
		return
	current_experience += amount

	if leveling_enabled:
		while current_experience >= required_experience:
			current_experience -= required_experience
			level += 1
			required_experience = _required_for_level(level)
			level_increased.emit(level)

	progress_changed.emit(level, current_experience, required_experience)


func get_run_snapshot() -> Dictionary:
	return {
		&"level": level,
		&"current_experience": current_experience,
		&"required_experience": required_experience,
	}


func _required_for_level(target_level: int) -> int:
	return 5 + (target_level - 1) * 4
