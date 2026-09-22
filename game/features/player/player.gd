class_name PlayerCharacter
extends CharacterBody2D

signal health_changed(current: float, maximum: float)
signal runtime_stats_changed(stats: Dictionary)
signal damaged(
	health_damage: float,
	armor_damage: float,
	world_position: Vector2,
	context: Dictionary
)
signal died

@export_range(1.0, 10000.0, 1.0) var max_health: float = 100.0
@export_range(0.0, 10000.0, 0.1) var defense: float = 0.0
@export var health_recovery_policy: Resource = preload("res://game/features/player/health_recovery_policy.gd").new()

@onready var movement: PlayerMovement = $Movement
@onready var body_visual: Polygon2D = $Body
@onready var heading: Polygon2D = $Heading
@onready var hit_reaction: Node = get_node_or_null("HitReaction")

var current_health: float
var damage_enabled: bool = true
var has_taken_damage: bool = false
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
	if hit_reaction != null:
		hit_reaction.configure(self, [body_visual, heading])


func _physics_process(delta: float) -> void:
	var desired_velocity := movement.get_velocity(velocity, delta)
	velocity = (
		hit_reaction.advance(delta, desired_velocity)
		if hit_reaction != null else desired_velocity
	)
	move_and_slide()

	if desired_velocity != Vector2.ZERO:
		facing_direction = desired_velocity.normalized()
		heading.rotation = facing_direction.angle()


func configure_damage(is_enabled: bool) -> void:
	damage_enabled = is_enabled


func set_ui_input_blocked(blocked: bool) -> void:
	movement.set_ui_input_blocked(blocked)


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
	runtime_stats = _calculate_runtime_stats(stat_modifier_sources)

	max_health = maxf(1.0, float(runtime_stats.get(&"max_health", max_health)))
	defense = maxf(0.0, float(runtime_stats.get(&"defense", defense)))
	movement.speed = maxf(0.0, float(runtime_stats.get(&"movement_speed", movement.speed)))
	# Initial full-health loadout may initialize its capacity; wounded players
	# cannot obtain healing by changing max-HP equipment or selecting a buff.
	current_health = max_health if not has_taken_damage and is_equal_approx(previous_health_ratio, 1.0) else clampf(current_health, 0.0, max_health)
	health_changed.emit(current_health, max_health)
	runtime_stats_changed.emit(get_runtime_stats())


func preview_modifier_source(source_id: StringName, modifiers: Dictionary) -> Dictionary:
	var sources := stat_modifier_sources.duplicate(true)
	sources[source_id] = modifiers.duplicate(true)
	return _calculate_runtime_stats(sources)


func _calculate_runtime_stats(sources: Dictionary) -> Dictionary:
	var result := base_stats.duplicate(true)
	var aggregated: Dictionary = {}
	for source_id in sources:
		var source: Dictionary = sources[source_id]
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
		var base_value := float(result.get(stat_id, 0.0))
		var entry: Dictionary = aggregated[stat_id]
		result[stat_id] = (
			(base_value + float(entry[&"add"])) * float(entry[&"multiply"])
		)

	return result


func get_runtime_stats() -> Dictionary:
	return runtime_stats.duplicate(true)


func teleport_to(destination: Vector2) -> void:
	global_position = destination
	velocity = Vector2.ZERO
	var camera := get_node_or_null("Camera2D") as Camera2D
	if camera != null:
		camera.reset_smoothing()
		camera.force_update_scroll()


func get_health_snapshot() -> Dictionary:
	return {
		&"current": current_health,
		&"maximum": max_health,
		&"ratio": current_health / max_health if max_health > 0.0 else 0.0,
	}


func get_movement_snapshot() -> Dictionary:
	return movement.get_movement_snapshot()


func is_moving_for_resource_recovery() -> bool:
	# Actual post-collision locomotion, not a held key against a wall or a warp.
	return current_health > 0.0 and get_real_velocity().length_squared() > 1.0


func get_facing_direction() -> Vector2:
	return facing_direction


func take_damage(amount: float, hit_context: Dictionary = {}) -> void:
	if not damage_enabled or current_health <= 0.0:
		return

	var received_damage := maxf(1.0, amount - defense)
	has_taken_damage = true
	current_health = maxf(0.0, current_health - received_damage)
	var context := hit_context.duplicate(true)
	context[&"lethal"] = is_zero_approx(current_health)
	if hit_reaction != null:
		hit_reaction.react(context, received_damage)
	damaged.emit(received_damage, 0.0, global_position, context)
	health_changed.emit(current_health, max_health)

	if is_zero_approx(current_health):
		died.emit()


func can_receive_healing(source: StringName) -> bool:
	return health_recovery_policy != null and health_recovery_policy.has_method(&"allows") and bool(health_recovery_policy.call(&"allows", source))


func heal(amount: float, source: StringName = &"") -> void:
	if current_health <= 0.0 or not is_finite(amount) or amount <= 0.0 or not can_receive_healing(source):
		return

	current_health = minf(max_health, current_health + amount)
	health_changed.emit(current_health, max_health)
