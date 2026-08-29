class_name RunBuffSystem
extends Node

signal choices_prepared(run_level: int, choices: Array[Dictionary])
signal buff_applied(snapshot: Dictionary)

const PLAYER_MODIFIER_METHOD := &"set_runtime_modifier_source"
const WEAPON_MODIFIER_METHOD := &"set_runtime_modifiers"

var player_target: Node
var weapon_target: Node
var catalog: Resource
var selected_stacks: Dictionary = {}
var offered_buff_ids := PackedStringArray()


func configure(
	new_player_target: Node,
	new_weapon_target: Node,
	new_catalog: Resource
) -> bool:
	if (
		new_catalog == null
		or not new_catalog.has_method(&"validation_errors")
		or not new_catalog.call(&"validation_errors").is_empty()
	):
		push_error("유효한 RunBuffCatalog가 필요합니다.")
		return false
	if new_player_target == null or not new_player_target.has_method(PLAYER_MODIFIER_METHOD):
		push_error("런 버프 대상이 플레이어 수정자 계약을 구현하지 않았습니다.")
		return false
	player_target = new_player_target
	weapon_target = new_weapon_target
	catalog = new_catalog
	selected_stacks.clear()
	offered_buff_ids.clear()
	_apply_aggregated_modifiers()
	return true


func prepare_choices(run_level: int, choice_count: int = 3) -> Array[Dictionary]:
	var candidates: Array[Resource] = []
	for buff in catalog.get("buffs"):
		var current_buff_id: StringName = buff.get("buff_id")
		if int(selected_stacks.get(current_buff_id, 0)) >= int(buff.get("maximum_stacks")):
			continue
		if not _is_applicable(buff):
			continue
		candidates.append(buff)
	candidates.sort_custom(func(left: Resource, right: Resource) -> bool:
		return String(left.get("buff_id")) < String(right.get("buff_id"))
	)
	offered_buff_ids.clear()
	var result: Array[Dictionary] = []
	if candidates.is_empty():
		choices_prepared.emit(run_level, result)
		return result
	var start_index := posmod(run_level + selected_buff_count() - 1, candidates.size())
	for offset in range(mini(choice_count, candidates.size())):
		var buff: Resource = candidates[(start_index + offset) % candidates.size()]
		var current_buff_id: StringName = buff.get("buff_id")
		offered_buff_ids.append(String(current_buff_id))
		result.append(buff.call(
			&"choice_snapshot", int(selected_stacks.get(current_buff_id, 0))
		))
	choices_prepared.emit(run_level, result)
	return result


func select_buff(buff_id: StringName) -> bool:
	if buff_id not in offered_buff_ids:
		return false
	var buff: Resource = catalog.call(&"get_buff", buff_id)
	if buff == null:
		return false
	var next_stacks := int(selected_stacks.get(buff_id, 0)) + 1
	if next_stacks > int(buff.get("maximum_stacks")):
		return false
	selected_stacks[buff_id] = next_stacks
	offered_buff_ids.clear()
	_apply_aggregated_modifiers()
	if float(buff.get("heal_on_apply")) > 0.0 and player_target.has_method(&"heal"):
		player_target.call(&"heal", float(buff.get("heal_on_apply")))
	var snapshot := get_snapshot()
	snapshot[&"last_selected_buff_id"] = buff_id
	buff_applied.emit(snapshot)
	return true


func selected_buff_count() -> int:
	var result := 0
	for buff_id in selected_stacks:
		result += int(selected_stacks[buff_id])
	return result


func get_meta_experience_breakdown() -> Dictionary:
	var result := {&"character": 0, &"weapon": 0, &"armor": 0}
	for buff_id in selected_stacks:
		var buff: Resource = catalog.call(&"get_buff", buff_id)
		if buff == null:
			continue
		var target_id: StringName = buff.call(&"meta_target_id")
		result[target_id] = int(result[target_id]) + int(selected_stacks[buff_id])
	return result


func get_snapshot() -> Dictionary:
	return {
		&"selected_stacks": selected_stacks.duplicate(true),
		&"selected_buff_count": selected_buff_count(),
		&"meta_experience": get_meta_experience_breakdown(),
	}


func _is_applicable(buff: Resource) -> bool:
	var player_modifiers: Dictionary = buff.get("player_modifiers")
	var weapon_modifiers: Dictionary = buff.get("weapon_modifiers")
	if not player_modifiers.is_empty():
		return true
	return (
		weapon_target != null
		and weapon_target.has_method(WEAPON_MODIFIER_METHOD)
		and not weapon_modifiers.is_empty()
	)


func _apply_aggregated_modifiers() -> void:
	var player_aggregated: Dictionary = {}
	var weapon_aggregated: Dictionary = {}
	for buff_id in selected_stacks:
		var buff: Resource = catalog.call(&"get_buff", buff_id)
		if buff == null:
			continue
		for _stack in range(int(selected_stacks[buff_id])):
			_accumulate_player_modifiers(player_aggregated, buff.get("player_modifiers"))
			_accumulate_weapon_modifiers(weapon_aggregated, buff.get("weapon_modifiers"))
	player_target.call(PLAYER_MODIFIER_METHOD, &"run_buffs", player_aggregated)
	if weapon_target != null and weapon_target.has_method(WEAPON_MODIFIER_METHOD):
		weapon_target.call(WEAPON_MODIFIER_METHOD, &"run_buffs", weapon_aggregated)


func _accumulate_player_modifiers(target: Dictionary, modifiers: Dictionary) -> void:
	for stat_id in modifiers:
		var source: Dictionary = modifiers[stat_id]
		var entry: Dictionary = target.get(stat_id, {&"add": 0.0, &"multiply": 1.0})
		entry[&"add"] = float(entry[&"add"]) + float(source.get(&"add", 0.0))
		entry[&"multiply"] = (
			float(entry[&"multiply"]) * float(source.get(&"multiply", 1.0))
		)
		target[stat_id] = entry


func _accumulate_weapon_modifiers(target: Dictionary, modifiers: Dictionary) -> void:
	for modifier_id in modifiers:
		if String(modifier_id).ends_with("_multiply"):
			target[modifier_id] = (
				float(target.get(modifier_id, 1.0)) * float(modifiers[modifier_id])
			)
		else:
			target[modifier_id] = (
				float(target.get(modifier_id, 0.0)) + float(modifiers[modifier_id])
			)
