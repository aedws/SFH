extends RefCounted
## Read-only adapter: use the same definitions and upgrade provider as EquipmentSystem.
static func build() -> Dictionary:
	var growth := GrowthBalanceService.new()
	assert(growth.load_upgrade_csv_text(FileAccess.get_file_as_string("res://game/features/growth_balance/data/upgrade_balance.csv"), "locked_csv"))
	var result := {"weapons": [], "armor": [], "armor_sets": [], "parts": [], "modules": [], "characters": []}
	for kind in ["weapons", "armor", "parts", "modules"]:
		for file in DirAccess.get_files_at("res://game/features/equipment/definitions/" + kind):
			if not file.ends_with(".tres"): continue
			var definition: Resource = load("res://game/features/equipment/definitions/" + kind + "/" + file)
			var row := {"name": definition.display_name, "source": definition.resource_path}
			if kind in ["weapons", "armor"]:
				var state := EquipmentItemState.new()
				state.configure(&"preview", definition)
				state.set_upgrade_balance_provider(growth)
				row.merge({"id": state.definition_id(), "maximum_level": state.maximum_level(), "slots": state.module_slot_limit(), "capacity": state.module_cost_limit(), "levels": []})
				for level in range(1, state.maximum_level() + 1):
					row.levels.append({"player": growth.get_player_modifiers(&"armor", state.definition_id(), level) if kind == "armor" else {}, "weapon": growth.get_weapon_modifiers(&"weapon", state.definition_id(), level) if kind == "weapons" else {}})
				if kind == "weapons": row.merge({"minor_tag": definition.tags.minor_tag, "part_sockets": definition.part_socket_ids})
				else:
					row.merge({"slot": definition.slot_id, "stats": _stats(definition.stat_modifiers), "options": []})
					row["set_id"] = String(definition.armor_set.set_id) if definition.armor_set != null else ""
					if definition.armor_set != null and not definition.armor_set.snapshot() in result.armor_sets:
						result.armor_sets.append(definition.armor_set.snapshot())
					for option in definition.fixed_options: row.options.append(option.snapshot())
			elif kind == "parts":
				row.merge({"id": definition.part_id, "socket": definition.socket_id, "minor_tags": definition.compatible_minor_tags, "maximum_level": definition.maximum_upgrade_level, "stats": _stats(definition.stat_modifiers), "features": definition.special_feature_ids})
			else:
				var maximum := growth.get_maximum_level(&"module", definition.module_id, definition.maximum_upgrade_level())
				row.merge({"id": definition.module_id, "tags": definition.module_tags, "stats": _stats(definition.stat_modifiers), "maximum_level": maximum, "levels": [], "features": definition.special_feature_ids})
				for level in range(1, maximum + 1):
					row.levels.append({"cost": growth.get_module_capacity_cost(definition.module_id, level, definition.cost_at_level(level)), "player": growth.get_player_modifiers(&"module", definition.module_id, level), "weapon": growth.get_weapon_modifiers(&"module", definition.module_id, level)})
			result[kind].append(row)
	var parsed := CharacterTable.parse(FileAccess.get_file_as_string("res://game/features/character_selection/data/character_catalog.csv"))
	assert(parsed.errors.is_empty())
	for character in parsed.definitions: result.characters.append(character.to_snapshot())
	var player: Node = load("res://game/features/player/player.tscn").instantiate()
	result["player"] = {"max_health": player.max_health, "defense": player.defense, "movement_speed": player.get_node("Movement").speed}
	player.free()
	var carrier := CharacterModuleDefinition.new()
	result["character_carrier"] = {"maximum_level": carrier.maximum_level, "slots": carrier.module_slot_limit, "capacity": carrier.module_cost_limit}
	var sockets := ModuleSocketPolicy.new()
	result["sockets"] = {"matching": sockets.matching_cost_multiplier, "mismatching": sockets.mismatching_cost_multiplier}
	growth.free()
	return result

static func _stats(modifiers: Array) -> Dictionary:
	var result := {}
	for modifier in modifiers:
		var entry: Dictionary = result.get(modifier.stat_id, {"add": 0.0, "multiply": 1.0})
		if modifier.operation == EquipmentStatModifier.Operation.ADD: entry["add"] += modifier.amount
		else: entry["multiply"] *= modifier.amount
		result[modifier.stat_id] = entry
	return result

static func _carrier() -> Dictionary:
	return {"level": 1, "quality": 1.0, "modules": [], "parts": [], "sockets": {}}

static func parity(catalog: Dictionary, root: Node) -> Array:
	var fixtures := []
	var data: Dictionary = catalog.loadout
	for weapon in data.weapons:
		var base := {"characterId": data.characters[0].character_id, "weapon": _carrier(), "armor": [], "character": _carrier()}
		var occupied := []
		for armor in data.armor:
			if armor.slot in occupied: continue
			occupied.append(armor.slot)
			var state := _carrier()
			state["id"] = armor.id
			base.armor.append(state)
		var inputs := [base]
		for set_definition in data.armor_sets:
			for count in [2, 4]:
				var selected: Dictionary = base.duplicate(true)
				selected.armor.clear()
				for armor in data.armor:
					if armor.set_id != set_definition.id or selected.armor.size() >= count: continue
					var carrier := _carrier()
					carrier["id"] = armor.id
					selected.armor.append(carrier)
				inputs.append(selected)
		for part in data.parts:
			if weapon.minor_tag in part.minor_tags and part.socket in weapon.part_sockets:
				var input: Dictionary = base.duplicate(true)
				input.weapon.parts.append({"id": part.id, "level": part.maximum_level})
				inputs.append(input)
		for character in data.characters:
			var input: Dictionary = base.duplicate(true)
			input.characterId = character.character_id
			input.character.level = 10
			inputs.append(input)
		var targets := ["weapon", "character"]
		for armor in base.armor: targets.append(armor.id)
		for target in targets:
			for module in data.modules:
				var input: Dictionary = base.duplicate(true)
				var state: Dictionary = input.get(target, {})
				if state.is_empty():
					for armor in input.armor:
						if armor.id == target: state = armor
				state.modules.append({"id": module.id, "slot": 0, "level": module.maximum_level, "quality": 1.25})
				state.quality = 1.1
				inputs.append(input)
		for input in inputs:
			fixtures.append(_runtime_case(catalog, weapon.id, input, root))
	return fixtures

static func _definition(catalog: Dictionary, kind: String, id: String) -> Resource:
	for row in catalog.loadout[kind]:
		if row.id == id: return load(row.source)
	assert(false, "Unknown DPS definition " + id)
	return null

static func _runtime_case(catalog: Dictionary, weapon_id: String, input: Dictionary, root: Node) -> Dictionary:
	var growth := GrowthBalanceService.new()
	assert(growth.load_upgrade_csv_text(FileAccess.get_file_as_string("res://game/features/growth_balance/data/upgrade_balance.csv"), "locked_csv"))
	var player: Node = load("res://game/features/player/player.tscn").instantiate()
	root.add_child(player)
	player.set_physics_process(false)
	var loadout := EquipmentLoadout.new()
	loadout.loadout_id = &"dps_parity"
	loadout.display_name = "DPS parity"
	loadout.main_weapon = _definition(catalog, "weapons", weapon_id)
	for armor in input.armor: loadout.armor.append(_definition(catalog, "armor", armor.id))
	var equipment := CharacterEquipmentSystem.new()
	root.add_child(equipment)
	assert(equipment.configure(loadout, player))
	assert(equipment.set_upgrade_balance_provider(growth))
	equipment.set_external_character_level(input.character.level)
	for character in catalog.loadout.characters:
		if character.character_id == input.characterId: player.set_runtime_modifier_source(&"character", character.runtime_modifiers)
	player.set_runtime_modifier_source(&"meta_character", {&"max_health": {&"add": float(input.character.level - 1) * 5.0, &"multiply": 1.0}, &"movement_speed": {&"add": 0.0, &"multiply": pow(1.02, float(input.character.level - 1))}})
	var states := {"main": input.weapon, "character": input.character}
	for armor in input.armor:
		for row in catalog.loadout.armor:
			if row.id == armor.id: states[row.slot] = armor
	var costs := []
	for slot in states:
		var selected: Dictionary = states[slot]
		var state := equipment.get_equipment_state(slot)
		state.level = selected.level
		state.item_quality_payload = {&"performance_multiplier": selected.quality}
		for part in selected.parts: assert(state.install_part(_definition(catalog, "parts", part.id), part.level))
		for module in selected.modules: assert(state.install_module(module.id, _definition(catalog, "modules", module.id), module.level, {&"performance_multiplier": module.quality}, module.slot))
		costs.append(state.used_module_cost())
	equipment.set_upgrade_balance_provider(growth)
	var gun: Node = load("res://game/features/weapons/auto_weapon.tscn").instantiate()
	root.add_child(gun)
	gun.set_process(false)
	for weapon in catalog.weapons:
		if weapon.id == weapon_id: gun.current_balance = weapon.balance.duplicate(true)
	gun.set_runtime_modifiers(&"equipment_upgrade", equipment.get_active_weapon_upgrade_modifiers())
	gun.set_runtime_modifiers(&"fixed", equipment.get_active_weapon_fixed_modifiers())
	var result := {"weaponId": weapon_id, "input": input, "player": player.get_runtime_stats(), "weapon": equipment.get_active_weapon_upgrade_modifiers(), "skill": equipment.get_equipment_skill_modifiers(), "shot": gun.get_runtime_snapshot(), "costs": costs}
	gun.free()
	equipment.free()
	player.free()
	growth.free()
	return result
