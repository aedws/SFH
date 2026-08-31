class_name AutoWeapon
extends Node2D

signal weapon_runtime_changed(snapshot: Dictionary)

@export var projectile_scene: PackedScene
@export var fallback_target_group: StringName = &"enemies"
@export var primary_attack_action: StringName = &"primary_attack"
@export var requires_primary_attack: bool = true

var projectile_parent: Node2D
var equipment_provider: Node
var balance_provider: Node
var target_provider: Node
var targeting_policy: Resource
var current_balance: Dictionary = {}
var active_weapon_id: StringName = &"assault_rifle"
var active_weapon_slot: StringName = &"main"
var current_level: int = 1
var cooldown: float = 0.2
var burst_remaining: int = 0
var burst_direction := Vector2.RIGHT
var runtime_modifier_sources: Dictionary = {}


func configure(
	new_projectile_parent: Node2D,
	new_equipment_provider: Node = null,
	new_balance_provider: Node = null
) -> void:
	projectile_parent = new_projectile_parent
	equipment_provider = new_equipment_provider
	balance_provider = new_balance_provider
	if equipment_provider != null and equipment_provider.has_signal(&"active_weapon_changed"):
		equipment_provider.connect(
			&"active_weapon_changed", Callable(self, &"_on_active_weapon_changed")
		)
		active_weapon_slot = equipment_provider.call(&"get_active_weapon_slot")
		var weapon = equipment_provider.call(&"get_active_weapon")
		if weapon != null:
			active_weapon_id = weapon.weapon_id
	if (
		equipment_provider != null
		and equipment_provider.has_signal(&"weapon_upgrade_modifiers_changed")
		and equipment_provider.has_method(&"get_active_weapon_upgrade_modifiers")
	):
		equipment_provider.connect(
			&"weapon_upgrade_modifiers_changed",
			Callable(self, &"_on_weapon_upgrade_modifiers_changed")
		)
		set_runtime_modifiers(
			&"equipment_upgrade",
			equipment_provider.call(&"get_active_weapon_upgrade_modifiers")
		)
	if balance_provider != null and balance_provider.has_signal(&"balance_updated"):
		balance_provider.connect(&"balance_updated", Callable(self, &"_on_balance_updated"))
	_refresh_balance()


func set_target_provider(new_target_provider: Node) -> bool:
	if (
		not is_instance_valid(new_target_provider)
		or not new_target_provider.has_method(&"get_active_targets")
	):
		target_provider = null
		return false
	target_provider = new_target_provider
	return true


func set_targeting_policy(new_policy: Resource) -> bool:
	if (
		new_policy == null
		or not new_policy.has_method(&"is_valid")
		or not new_policy.has_method(&"select_target")
		or not bool(new_policy.call(&"is_valid"))
	):
		targeting_policy = null
		return false
	targeting_policy = new_policy
	_emit_runtime_snapshot()
	return true


func _unhandled_input(event: InputEvent) -> void:
	if (
		event.is_action_pressed(&"switch_weapon")
		and not event.is_echo()
		and equipment_provider != null
	):
		equipment_provider.call(&"switch_active_weapon")
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	cooldown -= delta
	if requires_primary_attack and not Input.is_action_pressed(primary_attack_action):
		burst_remaining = 0
		return
	if cooldown > 0.0:
		return
	if burst_remaining > 0:
		_fire_pattern(burst_direction)
		burst_remaining -= 1
		cooldown = (
			_modified_interval(float(current_balance.get(&"burst_interval_sec", 0.1)))
			if burst_remaining > 0
			else _modified_interval(float(current_balance.get(&"fire_interval_sec", 0.72)))
		)
		return
	var target := _find_nearest_enemy()
	if target == null:
		return
	burst_direction = global_position.direction_to(target.global_position)
	_fire_pattern(burst_direction)
	burst_remaining = maxi(0, int(current_balance.get(&"burst_count", 1)) - 1)
	cooldown = (
		_modified_interval(float(current_balance.get(&"burst_interval_sec", 0.1)))
		if burst_remaining > 0
		else _modified_interval(float(current_balance.get(&"fire_interval_sec", 0.72)))
	)


func try_fire_once() -> bool:
	if cooldown > 0.0:
		return false
	var target := _find_nearest_enemy()
	if target == null:
		return false
	burst_direction = global_position.direction_to(target.global_position)
	_fire_pattern(burst_direction)
	burst_remaining = maxi(0, int(current_balance.get(&"burst_count", 1)) - 1)
	cooldown = _modified_interval(float(current_balance.get(&"fire_interval_sec", 0.72)))
	return true


func apply_level(level: int) -> void:
	current_level = maxi(1, level)
	_emit_runtime_snapshot()


func set_runtime_modifiers(source_id: StringName, modifiers: Dictionary) -> void:
	if source_id == &"":
		return
	if modifiers.is_empty():
		runtime_modifier_sources.erase(source_id)
	else:
		runtime_modifier_sources[source_id] = modifiers.duplicate(true)
	_emit_runtime_snapshot()


func remove_runtime_modifiers(source_id: StringName) -> void:
	if runtime_modifier_sources.erase(source_id):
		_emit_runtime_snapshot()


func get_runtime_snapshot() -> Dictionary:
	var result := current_balance.duplicate(true)
	result[&"damage"] = _modified_damage(float(current_balance.get(&"damage", 1.0)))
	result[&"fire_interval_sec"] = _modified_interval(
		float(current_balance.get(&"fire_interval_sec", 0.72))
	)
	result[&"target_range_px"] = _modified_target_range(
		float(current_balance.get(&"target_range_px", 760.0))
	)
	result[&"active_weapon_id"] = active_weapon_id
	result[&"active_weapon_slot"] = active_weapon_slot
	result[&"level"] = current_level
	result[&"level_damage_bonus"] = floorf(float(current_level - 1) / 3.0)
	result[&"source_label"] = (
		balance_provider.get("current_source_label") if balance_provider != null else "내장 기본값"
	)
	result[&"targeting_mode"] = &"smart_weighted" if targeting_policy != null else &"nearest"
	result[&"fire_input_action"] = primary_attack_action
	result[&"hold_to_fire"] = requires_primary_attack
	result[&"targeting_policy"] = (
		targeting_policy.call(&"get_snapshot") if targeting_policy != null else {}
	)
	return result


func _find_nearest_enemy() -> Node2D:
	var target_range := _modified_target_range(
		float(current_balance.get(&"target_range_px", 760.0))
	)
	var candidates := _target_candidates()
	if targeting_policy != null:
		return targeting_policy.call(&"select_target_for_mode", _resolved_targeting_mode(), global_position, candidates, target_range)
	var nearest: Node2D
	var nearest_distance_squared := target_range * target_range
	for candidate in candidates:
		if not candidate is Node2D:
			continue
		var candidate_2d := candidate as Node2D
		var distance_squared := global_position.distance_squared_to(candidate_2d.global_position)
		if distance_squared < nearest_distance_squared:
			nearest = candidate_2d
			nearest_distance_squared = distance_squared
	return nearest


func _target_candidates() -> Array:
	if is_instance_valid(target_provider):
		return target_provider.call(&"get_active_targets")
	return get_tree().get_nodes_in_group(fallback_target_group)


func _resolved_targeting_mode() -> StringName:
	var configured := StringName(current_balance.get(&"smart_targeting_mode", &""))
	if configured in [&"nearest", &"highest_health", &"elite"]:
		return configured
	return &"elite" if active_weapon_id == &"service_pistol" else &"nearest"


func _fire_pattern(base_direction: Vector2) -> void:
	var projectile_count := int(current_balance.get(&"projectiles_per_shot", 1))
	var spread_radians := deg_to_rad(float(current_balance.get(&"spread_angle_deg", 0.0)))
	for projectile_index in range(projectile_count):
		var angle_offset := 0.0
		if projectile_count > 1:
			angle_offset = lerpf(
				-spread_radians * 0.5,
				spread_radians * 0.5,
				float(projectile_index) / float(projectile_count - 1)
			)
		_spawn_projectile(base_direction.rotated(angle_offset))


func _spawn_projectile(direction: Vector2) -> void:
	if projectile_scene == null or not is_instance_valid(projectile_parent):
		return
	var projectile := projectile_scene.instantiate() as Area2D
	if projectile == null:
		return
	var damage := _modified_damage(float(current_balance.get(&"damage", 1.0)))
	damage += floorf(float(current_level - 1) / 3.0)
	if randf() < float(current_balance.get(&"critical_chance", 0.0)):
		damage *= float(current_balance.get(&"critical_multiplier", 1.0))
	projectile_parent.add_child(projectile)
	projectile.global_position = global_position
	projectile.call(
		&"launch",
		direction,
		damage,
		float(current_balance.get(&"projectile_speed_px_sec", 640.0)),
		float(current_balance.get(&"projectile_lifetime_sec", 1.8)),
		int(current_balance.get(&"pierce_count", 0)),
		float(current_balance.get(&"pierce_damage_retention", 1.0)),
		current_balance.get(&"projectile_color", Color.WHITE)
	)


func _on_active_weapon_changed(
	slot_id: StringName,
	weapon_definition: EquipmentWeaponDefinition
) -> void:
	if weapon_definition == null:
		return
	active_weapon_slot = slot_id
	active_weapon_id = weapon_definition.weapon_id
	burst_remaining = 0
	cooldown = 0.08
	_refresh_balance()


func _on_balance_updated(_snapshot: Dictionary, _source_label: String) -> void:
	_refresh_balance()


func _on_weapon_upgrade_modifiers_changed(modifiers: Dictionary) -> void:
	set_runtime_modifiers(&"equipment_upgrade", modifiers)


func _refresh_balance() -> void:
	current_balance = {}
	if balance_provider != null:
		current_balance = balance_provider.call(&"get_weapon_balance", active_weapon_id)
	if current_balance.is_empty():
		current_balance = _fallback_balance(active_weapon_id)
	_emit_runtime_snapshot()


func _emit_runtime_snapshot() -> void:
	weapon_runtime_changed.emit(get_runtime_snapshot())


func _modified_damage(base_value: float) -> float:
	return (
		base_value + _modifier_total(&"damage_add", 0.0, true)
	) * _modifier_total(&"damage_multiply", 1.0, false)


func _modified_interval(base_value: float) -> float:
	return maxf(
		0.02,
		base_value * _modifier_total(&"fire_interval_multiply", 1.0, false)
	)


func _modified_target_range(base_value: float) -> float:
	return maxf(
		32.0,
		base_value * _modifier_total(&"target_range_multiply", 1.0, false)
	)


func _modifier_total(modifier_id: StringName, default_value: float, additive: bool) -> float:
	var result := default_value
	for source_id in runtime_modifier_sources:
		var source: Dictionary = runtime_modifier_sources[source_id]
		if not source.has(modifier_id):
			continue
		if additive:
			result += float(source[modifier_id])
		else:
			result *= float(source[modifier_id])
	return result


func _fallback_balance(weapon_id: StringName) -> Dictionary:
	if weapon_id == &"service_pistol":
		return {
			&"display_name": "제식 권총", &"trait_id": &"heavy_piercing", &"damage": 3.2,
			&"fire_interval_sec": 0.6, &"projectile_speed_px_sec": 690.0,
			&"target_range_px": 560.0, &"projectiles_per_shot": 1, &"spread_angle_deg": 0.0,
			&"burst_count": 1, &"burst_interval_sec": 0.0, &"critical_chance": 0.12,
			&"critical_multiplier": 2.0, &"pierce_count": 1,
			&"pierce_damage_retention": 0.65, &"projectile_lifetime_sec": 1.3,
			&"projectile_color": Color("f6b94b")
		}
	return {
		&"display_name": "돌격소총", &"trait_id": &"steady_burst", &"damage": 1.6,
		&"fire_interval_sec": 0.78, &"projectile_speed_px_sec": 760.0,
		&"target_range_px": 820.0, &"projectiles_per_shot": 1, &"spread_angle_deg": 0.0,
		&"burst_count": 3, &"burst_interval_sec": 0.1, &"critical_chance": 0.05,
		&"critical_multiplier": 1.75, &"pierce_count": 0,
		&"pierce_damage_retention": 1.0, &"projectile_lifetime_sec": 1.6,
		&"projectile_color": Color("47d7d0")
	}
