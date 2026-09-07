class_name CombatSkillSystem
extends Node

signal skill_states_changed(states: Array[Dictionary])
signal skill_activated(slot_index: int, skill_id: StringName, result: Dictionary)

@export_range(0.05, 0.5, 0.01) var hud_refresh_interval_seconds: float = 0.1

var player: Node2D
var target_container: Node
var effect_parent: Node2D
var loadout
var resource_provider: Node
var damage_enabled: bool = true
var activation_enabled: bool = true
var cooldowns: Array[float] = []
var hud_refresh_accumulator: float = 0.0
var state_emission_count: int = 0
var targeting_policy: Resource
var equipment_provider: Node
var binding_provider: Node
var runtime_modifier_sources: Dictionary = {}


func configure(
	new_player: Node2D,
	new_target_container: Node,
	new_effect_parent: Node2D,
	new_loadout,
	new_damage_enabled: bool = true,
	new_resource_provider: Node = null,
	new_targeting_policy: Resource = null,
	new_equipment_provider: Node = null,
	new_binding_provider: Node = null
) -> bool:
	if (
		not is_instance_valid(new_player)
		or not is_instance_valid(new_target_container)
		or not is_instance_valid(new_effect_parent)
		or new_loadout == null
		or not new_loadout.call(&"validation_errors").is_empty()
	):
		return false
	player = new_player
	target_container = new_target_container
	effect_parent = new_effect_parent
	loadout = new_loadout
	damage_enabled = new_damage_enabled
	targeting_policy = new_targeting_policy
	equipment_provider = new_equipment_provider
	binding_provider = (
		new_binding_provider
		if is_instance_valid(new_binding_provider)
		and new_binding_provider.has_method(&"action_for_skill")
		and new_binding_provider.has_method(&"input_label_for_skill")
		else null
	)
	if (
		is_instance_valid(binding_provider)
		and binding_provider.has_signal(&"bindings_changed")
		and not binding_provider.is_connected(
			&"bindings_changed", Callable(self, &"_on_skill_bindings_changed")
		)
	):
		binding_provider.connect(
			&"bindings_changed", Callable(self, &"_on_skill_bindings_changed")
		)
	if (
		is_instance_valid(equipment_provider)
		and equipment_provider.has_signal(&"active_weapon_changed")
		and not equipment_provider.is_connected(&"active_weapon_changed", Callable(self, &"_on_active_weapon_changed"))
	):
		equipment_provider.connect(&"active_weapon_changed", Callable(self, &"_on_active_weapon_changed"))
	resource_provider = (
		new_resource_provider
		if is_instance_valid(new_resource_provider)
		and new_resource_provider.has_signal(&"resources_changed")
		and new_resource_provider.has_method(&"can_activate")
		and new_resource_provider.has_method(&"consume_for_skill")
		and new_resource_provider.has_method(&"get_skill_resource_snapshot")
		else null
	)
	if is_instance_valid(resource_provider) and not resource_provider.is_connected(
		&"resources_changed", Callable(self, &"_on_resources_changed")
	):
		resource_provider.connect(&"resources_changed", Callable(self, &"_on_resources_changed"))
	hud_refresh_accumulator = 0.0
	state_emission_count = 0
	cooldowns.clear()
	runtime_modifier_sources.clear()
	for _skill in loadout.skills:
		cooldowns.append(0.0)
	_emit_states()
	return true


func _process(delta: float) -> void:
	_advance_cooldowns(delta, false)


func _unhandled_input(event: InputEvent) -> void:
	if not activation_enabled or loadout == null:
		return
	for index in loadout.skills.size():
		var action_id := _action_for_skill(loadout.skills[index])
		if not action_id.is_empty() and event.is_action_pressed(action_id, false):
			try_activate(index)
			get_viewport().set_input_as_handled()
			return


func try_activate(slot_index: int) -> bool:
	if (
		not activation_enabled
		or loadout == null
		or slot_index < 0
		or slot_index >= loadout.skills.size()
		or cooldowns[slot_index] > 0.0
		or not is_instance_valid(player)
		or (is_instance_valid(resource_provider) and not resource_provider.call(&"can_activate", slot_index))
	):
		return false
	var skill: Resource = loadout.skills[slot_index]
	if not _skill_matches_active_weapon(skill):
		return false
	var effect: Resource = skill.get("effect")
	var activation_context := _build_activation_context(skill)
	var result: Dictionary = effect.call(&"activate", player, {
		&"target_container": activation_context[&"target_container"],
		&"effect_parent": activation_context[&"effect_parent"],
		&"damage_enabled": activation_context[&"damage_enabled"],
		&"target": activation_context[&"target"],
		&"target_point": activation_context[&"target_point"],
		&"direction": activation_context[&"direction"],
		&"mechanic_override": activation_context[&"mechanic_override"],
	})
	if not bool(result.get(&"success", false)):
		return false
	if (
		is_instance_valid(resource_provider)
		and not bool(resource_provider.call(&"consume_for_skill", slot_index))
	):
		return false
	cooldowns[slot_index] = _modified_cooldown(float(skill.get("cooldown_seconds")))
	skill_activated.emit(slot_index, skill.get("skill_id"), result.duplicate(true))
	_emit_states()
	return true


func advance(delta: float) -> void:
	_advance_cooldowns(delta, true)


func _advance_cooldowns(delta: float, force_emit: bool) -> void:
	if loadout == null or delta <= 0.0:
		return
	var changed := false
	var became_ready := false
	for index in cooldowns.size():
		var previous := cooldowns[index]
		cooldowns[index] = maxf(0.0, previous - delta)
		changed = changed or not is_equal_approx(previous, cooldowns[index])
		became_ready = became_ready or (previous > 0.0 and cooldowns[index] <= 0.0)
	if not changed:
		return
	hud_refresh_accumulator += delta
	if force_emit or became_ready or hud_refresh_accumulator >= hud_refresh_interval_seconds:
		hud_refresh_accumulator = fmod(
			hud_refresh_accumulator, hud_refresh_interval_seconds
		) if not force_emit else 0.0
		_emit_states()


func set_activation_enabled(is_enabled: bool) -> void:
	activation_enabled = is_enabled
	_emit_states()


func set_runtime_modifiers(source_id: StringName, modifiers: Dictionary) -> void:
	if source_id == &"":
		return
	if modifiers.is_empty():
		runtime_modifier_sources.erase(source_id)
	else:
		runtime_modifier_sources[source_id] = modifiers.duplicate(true)
	_emit_states()


func remove_runtime_modifiers(source_id: StringName) -> void:
	if runtime_modifier_sources.erase(source_id):
		_emit_states()


func get_slot_bindings() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var capacity := int(loadout.get("slot_capacity")) if loadout != null else 0
	for slot_index in capacity:
		var action := StringName("combat_skill_%d" % (slot_index + 1))
		var skill_id: StringName = &""
		if is_instance_valid(binding_provider) and binding_provider.has_method(&"skill_for_action"):
			skill_id = binding_provider.call(&"skill_for_action", action)
		elif slot_index < loadout.skills.size():
			skill_id = loadout.skills[slot_index].get("skill_id")
		result.append({
			&"slot_index": slot_index,
			&"action": action,
			&"events": InputMap.action_get_events(action),
			&"skill_id": skill_id,
			&"occupied": not skill_id.is_empty(),
		})
	return result


func preview_skill_replacement(slot_index: int, candidate: Resource) -> Dictionary:
	if (
		loadout == null
		or slot_index < 0
		or slot_index >= loadout.skills.size()
		or candidate == null
		or not candidate.has_method(&"is_valid")
		or not bool(candidate.call(&"is_valid"))
	):
		return {&"available": false, &"reason": &"invalid_candidate"}
	var candidate_id := StringName(candidate.get("skill_id"))
	for index in loadout.skills.size():
		if index != slot_index and StringName(loadout.skills[index].get("skill_id")) == candidate_id:
			return {&"available": false, &"reason": &"duplicate_skill"}
	var previous: Resource = loadout.skills[slot_index]
	var compatible := _skill_matches_active_weapon(candidate)
	return {
		&"available": compatible,
		&"reason": &"" if compatible else &"weapon_tags_mismatch",
		&"slot_index": slot_index,
		&"candidate_skill_id": candidate_id,
		&"candidate_name": String(candidate.get("display_name")),
		&"previous_skill_id": StringName(previous.get("skill_id")),
		&"previous_name": String(previous.get("display_name")),
		&"required_combat_tags": (candidate.get("required_combat_tags") as Array).duplicate(),
		&"weapon_tags_ready": compatible,
	}


func replace_skill(slot_index: int, candidate: Resource) -> Dictionary:
	var preview := preview_skill_replacement(slot_index, candidate)
	if not bool(preview.get(&"available", false)):
		return {&"success": false, &"reason": preview.get(&"reason", &"rejected")}
	var previous: Resource = loadout.skills[slot_index]
	var previous_cooldown := cooldowns[slot_index]
	var previous_resource_state := {}
	if is_instance_valid(resource_provider) and resource_provider.has_method(&"capture_skill_slot_state"):
		previous_resource_state = resource_provider.call(&"capture_skill_slot_state", slot_index)
	loadout.skills[slot_index] = candidate
	cooldowns[slot_index] = 0.0
	if (
		is_instance_valid(resource_provider)
		and resource_provider.has_method(&"reset_skill_slot")
		and not bool(resource_provider.call(&"reset_skill_slot", slot_index))
	):
		loadout.skills[slot_index] = previous
		cooldowns[slot_index] = previous_cooldown
		return {&"success": false, &"reason": &"resource_reset_failed"}
	_emit_states()
	return {
		&"success": true,
		&"slot_index": slot_index,
		&"previous_definition": previous,
		&"previous_cooldown": previous_cooldown,
		&"previous_resource_state": previous_resource_state,
	}


func restore_skill_replacement(
	slot_index: int,
	previous_definition: Resource,
	previous_cooldown: float,
	previous_resource_state: Dictionary
) -> bool:
	if (
		loadout == null
		or slot_index < 0
		or slot_index >= loadout.skills.size()
		or previous_definition == null
		or not previous_definition.has_method(&"is_valid")
		or not bool(previous_definition.call(&"is_valid"))
	):
		return false
	loadout.skills[slot_index] = previous_definition
	cooldowns[slot_index] = maxf(0.0, previous_cooldown)
	if (
		is_instance_valid(resource_provider)
		and resource_provider.has_method(&"restore_skill_slot_state")
		and not bool(resource_provider.call(
			&"restore_skill_slot_state", slot_index, previous_resource_state
		))
	):
		return false
	_emit_states()
	return true


func get_skill_states() -> Array[Dictionary]:
	var states: Array[Dictionary] = []
	if loadout == null:
		return states
	for index in loadout.skills.size():
		var definition: Resource = loadout.skills[index]
		var state: Dictionary = definition.call(&"get_snapshot", index)
		state[&"input_action"] = _action_for_skill(definition)
		state[&"input_label"] = _input_label_for_skill(definition)
		var remaining := cooldowns[index] if index < cooldowns.size() else 0.0
		state[&"cooldown_remaining"] = remaining
		var base_cooldown := float(definition.get("cooldown_seconds"))
		var effective_cooldown := _modified_cooldown(base_cooldown)
		state[&"base_cooldown_seconds"] = base_cooldown
		state[&"cooldown_seconds"] = effective_cooldown
		state[&"cooldown_ratio"] = clampf(remaining / effective_cooldown, 0.0, 1.0)
		var resource_state := {
			&"energy_current": 0.0,
			&"energy_maximum": 0.0,
			&"energy_cost": 0.0,
			&"current_charges": -1,
			&"maximum_charges": -1,
			&"charge_recovery_remaining": 0.0,
			&"resource_ready": true,
		}
		if is_instance_valid(resource_provider):
			resource_state = resource_provider.call(&"get_skill_resource_snapshot", index)
		state.merge(resource_state, true)
		state[&"ready"] = (
			activation_enabled
			and remaining <= 0.0
			and bool(state[&"resource_ready"])
			and _skill_matches_active_weapon(definition)
		)
		state[&"weapon_tags_ready"] = _skill_matches_active_weapon(definition)
		state[&"activation_enabled"] = activation_enabled
		states.append(state)
	return states


func get_snapshot() -> Dictionary:
	return {
		&"skill_count": loadout.skills.size() if loadout != null else 0,
		&"slot_capacity": int(loadout.get("slot_capacity")) if loadout != null else 0,
		&"slot_bindings": get_slot_bindings(),
		&"activation_enabled": activation_enabled,
		&"hud_refresh_hz": 1.0 / hud_refresh_interval_seconds,
		&"state_emission_count": state_emission_count,
		&"active_electric_effects": get_tree().get_node_count_in_group(
			&"combat_skill_electric_effect"
		) if is_inside_tree() else 0,
		&"states": get_skill_states(),
		&"resources_enabled": is_instance_valid(resource_provider),
		&"skill_binding_enabled": is_instance_valid(binding_provider),
		&"runtime_modifiers": _aggregated_runtime_modifiers(),
	}


func _emit_states() -> void:
	state_emission_count += 1
	skill_states_changed.emit(get_skill_states())


func _on_resources_changed(_snapshot: Dictionary) -> void:
	_emit_states()


func _on_active_weapon_changed(_slot_id: StringName, _weapon_definition: Resource) -> void:
	_emit_states()


func _on_skill_bindings_changed(_snapshot: Dictionary) -> void:
	_emit_states()


func _action_for_skill(skill: Resource) -> StringName:
	var skill_id: StringName = skill.get("skill_id")
	if is_instance_valid(binding_provider):
		var assigned: StringName = binding_provider.call(&"action_for_skill", skill_id)
		if not assigned.is_empty():
			return assigned
	return StringName(skill.get("input_action"))


func _input_label_for_skill(skill: Resource) -> String:
	var skill_id: StringName = skill.get("skill_id")
	if is_instance_valid(binding_provider):
		return String(binding_provider.call(&"input_label_for_skill", skill_id))
	return String(skill.get("input_label"))


func _build_activation_context(skill: Resource) -> Dictionary:
	var direction := Vector2.RIGHT
	if is_instance_valid(player) and player.has_method(&"get_facing_direction"):
		direction = player.call(&"get_facing_direction")
	var candidates: Array = []
	if is_instance_valid(target_container):
		candidates = target_container.get_children()
	var target: Node2D
	var target_point := player.global_position if is_instance_valid(player) else Vector2.ZERO
	var mode := StringName(skill.get("targeting_mode"))
	var maximum_range := float(skill.get("targeting_range"))
	var mechanic_override := {}
	if (
		is_instance_valid(equipment_provider)
		and equipment_provider.has_method(&"get_active_skill_mechanic_override")
	):
		mechanic_override = equipment_provider.call(
			&"get_active_skill_mechanic_override", skill.get("skill_id")
		)
	mechanic_override = mechanic_override.duplicate(true)
	var runtime_modifiers := _aggregated_runtime_modifiers()
	for modifier_id in runtime_modifiers:
		if modifier_id == &"cooldown_multiply":
			continue
		mechanic_override[modifier_id] = runtime_modifiers[modifier_id]
	if runtime_modifiers.has(&"damage_multiply"):
		mechanic_override[&"damage_multiplier"] = (
			float(mechanic_override.get(&"damage_multiplier", 1.0))
			* float(runtime_modifiers[&"damage_multiply"])
		)
		mechanic_override[&"tick_damage_multiplier"] = (
			float(mechanic_override.get(&"tick_damage_multiplier", 1.0))
			* float(runtime_modifiers[&"damage_multiply"])
		)
	if targeting_policy != null and targeting_policy.has_method(&"resolve"):
		var resolved: Dictionary
		if targeting_policy.has_method(&"resolve_for_skill") and skill.has_method(&"get_targeting_radius"):
			resolved = targeting_policy.call(&"resolve_for_skill", mode, player.global_position,
				candidates, maximum_range, direction, skill.call(&"get_targeting_radius", mechanic_override))
		else:
			# Legacy/custom policies keep the original five-argument contract.
			resolved = targeting_policy.call(&"resolve", mode, player.global_position, candidates, maximum_range, direction)
		target = resolved.get(&"target") as Node2D
		target_point = resolved.get(&"target_point", target_point)
		direction = resolved.get(&"direction", direction)
	return {
		&"target_container": target_container,
		&"effect_parent": effect_parent,
		&"damage_enabled": damage_enabled,
		&"target": target,
		&"target_point": target_point,
		&"direction": direction.normalized() if not direction.is_zero_approx() else Vector2.RIGHT,
		&"mechanic_override": mechanic_override,
	}


func _skill_matches_active_weapon(skill: Resource) -> bool:
	var required: Array = skill.get("required_combat_tags")
	if required.is_empty():
		return true
	if not is_instance_valid(equipment_provider):
		return true
	return (
		equipment_provider.has_method(&"active_weapon_has_combat_tags")
		and bool(equipment_provider.call(&"active_weapon_has_combat_tags", required))
	)


func _modified_cooldown(base_value: float) -> float:
	return maxf(
		0.05,
		base_value * float(_aggregated_runtime_modifiers().get(&"cooldown_multiply", 1.0))
	)


func _aggregated_runtime_modifiers() -> Dictionary:
	var result: Dictionary = {}
	for source_id in runtime_modifier_sources:
		var source: Dictionary = runtime_modifier_sources[source_id]
		for modifier_id in source:
			if String(modifier_id).ends_with("_multiply"):
				result[modifier_id] = float(result.get(modifier_id, 1.0)) * float(source[modifier_id])
			else:
				result[modifier_id] = float(result.get(modifier_id, 0.0)) + float(source[modifier_id])
	return result
