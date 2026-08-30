class_name PlayerCharacter
extends CharacterBody2D

signal health_changed(current: float, maximum: float)
signal runtime_stats_changed(stats: Dictionary)
signal died

@export_range(1.0, 10000.0, 1.0) var max_health: float = 100.0
@export_range(0.0, 10000.0, 0.1) var defense: float = 0.0

@onready var movement: PlayerMovement = $Movement
@onready var heading: Polygon2D = $Heading

var current_health: float
var damage_enabled: bool = true
var base_stats: Dictionary = {}
var runtime_stats: Dictionary = {}
var stat_modifier_sources: Dictionary = {}
var facing_direction := Vector2.RIGHT


func _ready() -> void:
	add_to_group(&"player")
	base_stats = {
		&"max_health": max_health,
		&"defense": defense,
		&"movement_speed": movement.speed,
	}
	runtime_stats = base_stats.duplicate(true)
	current_health = max_health


func _physics_process(delta: float) -> void:
	velocity = movement.get_velocity(velocity, delta)
	move_and_slide()

	if velocity != Vector2.ZERO:
		facing_direction = velocity.normalized()
		heading.rotation = facing_direction.angle()


func configure_damage(is_enabled: bool) -> void:
	damage_enabled = is_enabled


func apply_equipment_modifiers(modifiers: Dictionary) -> void:
	set_runtime_modifier_source(&"equipment", modifiers)


func set_runtime_modifier_source(source_id: StringName, modifiers: Dictionary) -> void:
	if source_id == &"":
		return
	if modifiers.is_empty():
		stat_modifier_sources.erase(source_id)
	else:
		stat_modifier_sources[source_id] = modifiers.duplicate(true)
	_rebuild_runtime_stats()


func remove_runtime_modifier_source(source_id: StringName) -> void:
	if not stat_modifier_sources.erase(source_id):
		return
	_rebuild_runtime_stats()


func _rebuild_runtime_stats() -> void:
	var previous_max_health := max_health
	var previous_health_ratio := (
		current_health / previous_max_health
		if previous_max_health > 0.0
		else 1.0
	)
	runtime_stats = base_stats.duplicate(true)
	var aggregated: Dictionary = {}
	for source_id in stat_modifier_sources:
		var source: Dictionary = stat_modifier_sources[source_id]
		for stat_id in source:
			var modifier_data: Dictionary = source[stat_id]
			var entry: Dictionary = aggregated.get(
				stat_id,
				{&"add": 0.0, &"multiply": 1.0}
			)
			entry[&"add"] = float(entry[&"add"]) + float(modifier_data.get(&"add", 0.0))
			entry[&"multiply"] = (
				float(entry[&"multiply"])
				* float(modifier_data.get(&"multiply", 1.0))
			)
			aggregated[stat_id] = entry
	for stat_id in aggregated:
		var base_value := float(runtime_stats.get(stat_id, 0.0))
		var entry: Dictionary = aggregated[stat_id]
		runtime_stats[stat_id] = (
			(base_value + float(entry[&"add"])) * float(entry[&"multiply"])
		)

	max_health = maxf(1.0, float(runtime_stats.get(&"max_health", max_health)))
	defense = maxf(0.0, float(runtime_stats.get(&"defense", defense)))
	movement.speed = maxf(0.0, float(runtime_stats.get(&"movement_speed", movement.speed)))
	current_health = clampf(max_health * previous_health_ratio, 0.0, max_health)
	health_changed.emit(current_health, max_health)
	runtime_stats_changed.emit(get_runtime_stats())


func get_runtime_stats() -> Dictionary:
	return runtime_stats.duplicate(true)


func get_health_snapshot() -> Dictionary:
	return {
		&"current": current_health,
		&"maximum": max_health,
		&"ratio": current_health / max_health if max_health > 0.0 else 0.0,
	}


func get_movement_snapshot() -> Dictionary:
	return movement.get_movement_snapshot()


func get_facing_direction() -> Vector2:
	return facing_direction


func take_damage(amount: float) -> void:
	if not damage_enabled or current_health <= 0.0:
		return

	var received_damage := maxf(1.0, amount - defense)
	current_health = maxf(0.0, current_health - received_damage)
	health_changed.emit(current_health, max_health)

	if is_zero_approx(current_health):
		died.emit()


func heal(amount: float) -> void:
	if current_health <= 0.0:
		return

	current_health = minf(max_health, current_health + amount)
	health_changed.emit(current_health, max_health)
