class_name CombatSkillSystem
extends Node

signal skill_states_changed(states: Array[Dictionary])
signal skill_activated(slot_index: int, skill_id: StringName, result: Dictionary)

var player: Node2D
var target_container: Node
var effect_parent: Node2D
var loadout
var damage_enabled: bool = true
var activation_enabled: bool = true
var cooldowns: Array[float] = []


func configure(
	new_player: Node2D,
	new_target_container: Node,
	new_effect_parent: Node2D,
	new_loadout,
	new_damage_enabled: bool = true
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
	cooldowns.clear()
	for _skill in loadout.skills:
		cooldowns.append(0.0)
	_emit_states()
	return true


func _process(delta: float) -> void:
	advance(delta)


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
	cooldowns[slot_index] = float(skill.get("cooldown_seconds"))
	skill_activated.emit(slot_index, skill.get("skill_id"), result.duplicate(true))
	_emit_states()
	return true


func advance(delta: float) -> void:
	if loadout == null or delta <= 0.0:
		return
	var changed := false
	for index in cooldowns.size():
		var previous := cooldowns[index]
		cooldowns[index] = maxf(0.0, previous - delta)
		changed = changed or not is_equal_approx(previous, cooldowns[index])
	if changed:
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
		state[&"ready"] = activation_enabled and remaining <= 0.0
		state[&"activation_enabled"] = activation_enabled
		states.append(state)
	return states


func get_snapshot() -> Dictionary:
	return {
		&"skill_count": loadout.skills.size() if loadout != null else 0,
		&"activation_enabled": activation_enabled,
		&"states": get_skill_states(),
	}


func _emit_states() -> void:
	skill_states_changed.emit(get_skill_states())
