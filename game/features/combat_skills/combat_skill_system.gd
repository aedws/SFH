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


func configure(
	new_player: Node2D,
	new_target_container: Node,
	new_effect_parent: Node2D,
	new_loadout,
	new_damage_enabled: bool = true,
	new_resource_provider: Node = null
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
		if event.is_action_pressed(loadout.skills[index].input_action, false):
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
	var effect: Resource = skill.get("effect")
	var result: Dictionary = effect.call(&"activate", player, {
		&"target_container": target_container,
		&"effect_parent": effect_parent,
		&"damage_enabled": damage_enabled,
	})
	if not bool(result.get(&"success", false)):
		return false
	if (
		is_instance_valid(resource_provider)
		and not bool(resource_provider.call(&"consume_for_skill", slot_index))
	):
		return false
	cooldowns[slot_index] = float(skill.get("cooldown_seconds"))
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


func get_skill_states() -> Array[Dictionary]:
	var states: Array[Dictionary] = []
	if loadout == null:
		return states
	for index in loadout.skills.size():
		var definition: Resource = loadout.skills[index]
		var state: Dictionary = definition.call(&"get_snapshot", index)
		var remaining := cooldowns[index] if index < cooldowns.size() else 0.0
		state[&"cooldown_remaining"] = remaining
		state[&"cooldown_ratio"] = clampf(
			remaining / float(definition.get("cooldown_seconds")), 0.0, 1.0
		)
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
			activation_enabled and remaining <= 0.0 and bool(state[&"resource_ready"])
		)
		state[&"activation_enabled"] = activation_enabled
		states.append(state)
	return states


func get_snapshot() -> Dictionary:
	return {
		&"skill_count": loadout.skills.size() if loadout != null else 0,
		&"activation_enabled": activation_enabled,
		&"hud_refresh_hz": 1.0 / hud_refresh_interval_seconds,
		&"state_emission_count": state_emission_count,
		&"active_electric_effects": get_tree().get_node_count_in_group(
			&"combat_skill_electric_effect"
		) if is_inside_tree() else 0,
		&"states": get_skill_states(),
		&"resources_enabled": is_instance_valid(resource_provider),
	}


func _emit_states() -> void:
	state_emission_count += 1
	skill_states_changed.emit(get_skill_states())


func _on_resources_changed(_snapshot: Dictionary) -> void:
	_emit_states()
