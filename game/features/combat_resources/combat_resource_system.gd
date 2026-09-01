class_name CombatResourceSystem
extends Node

signal resources_changed(snapshot: Dictionary)
signal pickup_spawned(resource_id: StringName, amount: float, world_position: Vector2)
signal pickup_collected(resource_id: StringName, amount: float)

@export var pickup_scene: PackedScene

var player_target: Node
var pickup_parent: Node2D
var loadout: Resource
var config: Resource
var current_energy: float = 0.0
var charges := PackedInt32Array()
var recharge_remaining := PackedFloat32Array()
var spawned_pickups: Dictionary = {&"energy": 0, &"health": 0}
var collected_pickups: Dictionary = {&"energy": 0, &"health": 0}
var random := RandomNumberGenerator.new()
var recovery_multiplier: float = 1.0


func configure(
	new_player_target: Node,
	new_pickup_parent: Node2D,
	new_loadout: Resource,
	new_config: Resource,
	seed: int = 0
) -> bool:
	if (
		not is_instance_valid(new_player_target)
		or not new_player_target.has_method(&"heal")
		or not new_player_target.has_method(&"get_health_snapshot")
		or not is_instance_valid(new_pickup_parent)
		or new_loadout == null
		or not new_loadout.has_method(&"validation_errors")
		or not new_loadout.call(&"validation_errors").is_empty()
		or new_config == null
		or not new_config.has_method(&"is_valid")
		or not bool(new_config.call(&"is_valid"))
		or pickup_scene == null
	):
		return false
	player_target = new_player_target
	pickup_parent = new_pickup_parent
	loadout = new_loadout
	config = new_config
	current_energy = float(config.get("starting_energy"))
	charges.clear()
	recharge_remaining.clear()
	for skill: Resource in loadout.get("skills"):
		charges.append(int(skill.get("maximum_charges")))
		recharge_remaining.append(0.0)
	spawned_pickups = {&"energy": 0, &"health": 0}
	collected_pickups = {&"energy": 0, &"health": 0}
	if seed == 0:
		random.randomize()
	else:
		random.seed = seed
	_emit_changed()
	return true


func set_recovery_multiplier(multiplier: float) -> void:
	recovery_multiplier = maxf(0.0, multiplier)
	_emit_changed()


func _process(delta: float) -> void:
	advance(delta)


func can_activate(slot_index: int) -> bool:
	if not _valid_slot(slot_index):
		return false
	var skill: Resource = loadout.get("skills")[slot_index]
	return (
		charges[slot_index] > 0
		and current_energy + 0.001 >= float(skill.get("energy_cost"))
	)


func consume_for_skill(slot_index: int) -> bool:
	if not can_activate(slot_index):
		return false
	var skill: Resource = loadout.get("skills")[slot_index]
	current_energy = maxf(0.0, current_energy - float(skill.get("energy_cost")))
	charges[slot_index] -= 1
	if recharge_remaining[slot_index] <= 0.0:
		recharge_remaining[slot_index] = float(skill.get("charge_recovery_seconds"))
	_emit_changed()
	return true


func advance(delta: float) -> void:
	if loadout == null or delta <= 0.0:
		return
	var changed := false
	for slot_index in charges.size():
		var skill: Resource = loadout.get("skills")[slot_index]
		var maximum := int(skill.get("maximum_charges"))
		if charges[slot_index] >= maximum:
			recharge_remaining[slot_index] = 0.0
			continue
		var recovery_seconds := float(skill.get("charge_recovery_seconds"))
		recharge_remaining[slot_index] -= delta
		while recharge_remaining[slot_index] <= 0.0 and charges[slot_index] < maximum:
			charges[slot_index] += 1
			changed = true
			if charges[slot_index] < maximum:
				recharge_remaining[slot_index] += recovery_seconds
			else:
				recharge_remaining[slot_index] = 0.0
	if changed:
		_emit_changed()


func restore_energy(amount: float) -> float:
	if config == null or amount <= 0.0:
		return 0.0
	var previous := current_energy
	current_energy = minf(float(config.get("maximum_energy")), current_energy + amount)
	var restored := current_energy - previous
	if restored > 0.0:
		_emit_changed()
	return restored


func spawn_enemy_drops(world_position: Vector2) -> int:
	if config == null or not is_instance_valid(pickup_parent):
		return 0
	var requests: Array[Dictionary] = []
	if random.randf() <= float(config.get("energy_drop_chance")):
		requests.append({&"resource_id": &"energy", &"amount": config.get("energy_drop_amount")})
	if random.randf() <= float(config.get("health_drop_chance")):
		requests.append({&"resource_id": &"health", &"amount": config.get("health_drop_amount")})
	if requests.is_empty() and bool(config.get("guarantee_one_drop")):
		requests.append({&"resource_id": &"energy", &"amount": config.get("energy_drop_amount")})
	var spawned := 0
	for request in requests:
		var offset := Vector2.RIGHT.rotated(float(spawned) * PI) * 13.0 if requests.size() > 1 else Vector2.ZERO
		if _spawn_pickup(
			StringName(request[&"resource_id"]), float(request[&"amount"]), world_position + offset
		):
			spawned += 1
	return spawned


func get_skill_resource_snapshot(slot_index: int) -> Dictionary:
	if not _valid_slot(slot_index):
		return {}
	var skill: Resource = loadout.get("skills")[slot_index]
	return {
		&"energy_current": current_energy,
		&"energy_maximum": float(config.get("maximum_energy")),
		&"energy_cost": float(skill.get("energy_cost")),
		&"current_charges": charges[slot_index],
		&"maximum_charges": int(skill.get("maximum_charges")),
		&"charge_recovery_remaining": recharge_remaining[slot_index],
		&"resource_ready": can_activate(slot_index),
	}


func capture_skill_slot_state(slot_index: int) -> Dictionary:
	if not _valid_slot(slot_index):
		return {}
	return {
		&"charges": charges[slot_index],
		&"recharge_remaining": recharge_remaining[slot_index],
	}


func reset_skill_slot(slot_index: int) -> bool:
	if not _valid_slot(slot_index):
		return false
	var skill: Resource = loadout.get("skills")[slot_index]
	charges[slot_index] = int(skill.get("maximum_charges"))
	recharge_remaining[slot_index] = 0.0
	_emit_changed()
	return true


func restore_skill_slot_state(slot_index: int, saved_state: Dictionary) -> bool:
	if not _valid_slot(slot_index) or saved_state.is_empty():
		return false
	var skill: Resource = loadout.get("skills")[slot_index]
	var maximum := int(skill.get("maximum_charges"))
	charges[slot_index] = clampi(int(saved_state.get(&"charges", maximum)), 0, maximum)
	recharge_remaining[slot_index] = maxf(
		0.0, float(saved_state.get(&"recharge_remaining", 0.0))
	)
	_emit_changed()
	return true


func get_snapshot() -> Dictionary:
	var slots: Array[Dictionary] = []
	for slot_index in charges.size():
		slots.append(get_skill_resource_snapshot(slot_index))
	return {
		&"energy_current": current_energy,
		&"energy_maximum": float(config.get("maximum_energy")) if config != null else 0.0,
		&"slots": slots,
		&"spawned_pickups": spawned_pickups.duplicate(true),
		&"collected_pickups": collected_pickups.duplicate(true),
		&"recovery_multiplier": recovery_multiplier,
	}


func _spawn_pickup(resource_id: StringName, amount: float, world_position: Vector2) -> bool:
	var pickup := pickup_scene.instantiate() as Area2D
	if pickup == null or not pickup.has_method(&"configure") or not pickup.has_signal(&"collected"):
		if pickup != null:
			pickup.free()
		return false
	pickup_parent.add_child(pickup)
	if not pickup.call(
		&"configure", resource_id, amount,
		float(config.get("pickup_magnet_radius")), float(config.get("pickup_magnet_speed"))
	):
		pickup.queue_free()
		return false
	pickup.global_position = world_position
	pickup.connect(&"collected", Callable(self, &"_on_pickup_collected"))
	spawned_pickups[resource_id] = int(spawned_pickups.get(resource_id, 0)) + 1
	pickup_spawned.emit(resource_id, amount, world_position)
	return true


func _on_pickup_collected(resource_id: StringName, amount: float) -> void:
	var applied := 0.0
	if resource_id == &"energy":
		applied = restore_energy(amount)
	elif resource_id == &"health" and is_instance_valid(player_target):
		var before: Dictionary = player_target.call(&"get_health_snapshot")
		player_target.call(&"heal", amount * recovery_multiplier)
		var after: Dictionary = player_target.call(&"get_health_snapshot")
		applied = float(after.get(&"current", 0.0)) - float(before.get(&"current", 0.0))
	collected_pickups[resource_id] = int(collected_pickups.get(resource_id, 0)) + 1
	pickup_collected.emit(resource_id, applied)


func _valid_slot(slot_index: int) -> bool:
	return loadout != null and slot_index >= 0 and slot_index < charges.size()


func _emit_changed() -> void:
	resources_changed.emit(get_snapshot())
