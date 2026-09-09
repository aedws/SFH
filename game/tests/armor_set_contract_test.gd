extends SceneTree

const SLOTS := [&"head", &"body", &"hands", &"feet"]
var assertions := 0
var failures := 0

func _init() -> void:
	call_deferred(&"_run")

func check(condition: bool, message: String) -> void:
	assertions += 1
	if not condition:
		failures += 1
		push_error("ARMOR_SET_FAILED " + message)

func _run() -> void:
	var player: Node2D = load("res://game/features/player/player.tscn").instantiate()
	root.add_child(player)
	player.set_physics_process(false)
	var equipment := CharacterEquipmentSystem.new()
	root.add_child(equipment)
	var original: EquipmentLoadout = load("res://game/features/equipment/loadouts/default_loadout.tres")
	check(equipment.configure(original, player), "initial equipment")
	check(equipment.get_slot_descriptors().size() == 6, "four armor slots + two weapons")
	check(equipment.get_armor_set_snapshot().sets.is_empty(), "old equipment unchanged")
	var legacy := original.duplicate(true) as EquipmentLoadout
	legacy.slot_rules.assign(legacy.slot_rules.filter(func(rule): return rule.slot_id not in [&"head", &"hands"]))
	legacy.extension_data.erase(&"armor_slot_policy")
	var migrated := EquipmentSlotPolicyMigration.copy_current(legacy)
	check(migrated.slot_rules.size() == 6 and legacy.slot_rules.size() == 4, "non-mutating old save migration")
	check(EquipmentSlotPolicyMigration.copy_current(migrated).slot_rules.size() == 6, "idempotent migration")
	legacy.loadout_id = &"custom_policy"
	check(EquipmentSlotPolicyMigration.copy_current(legacy).slot_rules.size() == 4, "custom policy untouched")
	var catalog: FieldLootEquipCatalog = load("res://game/features/field_loot/configs/default_field_loot_equipment.tres")
	check(catalog.validation_errors().is_empty(), "loot catalog valid")
	var growth := GrowthBalanceService.new()
	check(growth.load_upgrade_csv_text(FileAccess.get_file_as_string("res://game/features/growth_balance/data/upgrade_balance.csv"), "locked_csv"), "growth CSV")
	equipment.set_upgrade_balance_provider(growth)
	var bag := GridInventory.new()
	root.add_child(bag)
	bag.grid_size = Vector2i(12, 12)
	for family in ["bastion", "strider", "conduit"]:
		for slot in SLOTS: equipment.take_equipment_state(slot)
		for i in 4:
			var id := StringName(family + "_" + String(SLOTS[i]))
			var item := catalog.get_inventory_definition(id)
			check(item != null and item.is_valid(), "bag entry " + String(id))
			check(bag.add_item(item) != &"", "actual bag placement " + String(id))
			check(catalog.get_definition(id).extract_result == &"warehouse", "extraction persistence " + String(id))
			check(equipment.equip_definition(SLOTS[i], item.linked_resource), "equip " + String(id))
			var status: Dictionary = equipment.get_armor_set_snapshot()
			check(status.sets.size() == 1 and status.sets[0].count == i+1, "piece count")
			check(status.sets[0].bonuses[0].active == (i >= 1), "two-piece threshold")
			check(status.sets[0].bonuses[1].active == (i == 3), "four-piece threshold")
		var fixed: Dictionary = equipment.get_armor_set_snapshot()
		for slot in SLOTS:
			var state := equipment.get_equipment_state(slot)
			state.level = 3
			state.item_quality_payload = {&"performance_multiplier": 1.25}
		equipment.set_upgrade_balance_provider(growth)
		check(equipment.get_armor_set_snapshot() == fixed, "set coefficients ignore quality and level")
		var codec := LoadoutValueCodec.new()
		var saved: Dictionary = codec.decode(codec.encode(equipment.export_runtime_state()))
		check(codec.error.is_empty(), "allowlisted save codec")
		check(equipment.restore_runtime_state(saved), "save restore")
		check(equipment.get_armor_set_snapshot() == fixed, "save restores set effects")
		check(not equipment.equip_definition(&"head", catalog.get_entry(StringName(family+"_feet")).definition), "wrong slot rejected")
	# Actual combat-skill activation context and cooldown consume the same set modifiers.
	var skills := CombatSkillSystem.new()
	root.add_child(skills)
	var targets := Node2D.new()
	root.add_child(targets)
	check(skills.configure(player, targets, targets, load("res://game/features/combat_skills/configs/default_combat_skills.tres"), true, null, null, equipment), "skill configure")
	var states := skills.get_skill_states()
	check(is_equal_approx(states[1].cooldown_seconds, states[1].base_cooldown_seconds * .9), "real skill cooldown -10%")
	var context: Dictionary = skills.call(&"_build_activation_context", skills.loadout.skills[1])
	var base_effect := equipment.get_active_skill_mechanic_override(&"magnetic_field")
	check(is_equal_approx(context.mechanic_override.tick_damage_multiplier, 1.2 * float(base_effect.get(&"tick_damage_multiplier", 1))), "real magnetic-field damage +20%")
	check(skills.try_activate(1), "skill cast with set")
	check(is_equal_approx(skills.cooldowns[1], states[1].cooldown_seconds), "cast applies modified cooldown")
	equipment.take_equipment_state(&"head")
	check(not equipment.get_equipment_skill_modifiers().has("damage_multiply"), "four-piece removed immediately")
	check(equipment.get_equipment_skill_modifiers().has("cooldown_multiply"), "three-piece retains two-piece")
	# 2+2 hybrid, conflicting definitions, and duplicate slots cannot inflate bonuses.
	equipment.equip_definition(&"head", catalog.get_entry(&"bastion_head").definition)
	equipment.equip_definition(&"body", catalog.get_entry(&"bastion_body").definition)
	check(equipment.get_armor_set_snapshot().sets.size() == 2, "hybrid sets")
	check(is_equal_approx(equipment.get_armor_set_snapshot().player.max_health.multiply, 1.12), "hybrid health bonus")
	var bad := equipment.get_equipment_state(&"head").duplicate(true) as EquipmentItemState
	bad.definition = bad.definition.duplicate(true)
	bad.definition.armor_set = bad.definition.armor_set.duplicate(true)
	bad.definition.armor_set.bonuses = bad.definition.armor_set.bonuses.duplicate(true)
	bad.definition.armor_set.bonuses[0].player.max_health.multiply = 9.0
	var previous := equipment.get_armor_set_snapshot()
	check(not equipment.equip_state(&"head", bad), "conflicting same-ID set rejected atomically")
	check(previous == equipment.get_armor_set_snapshot(), "failed equip preserves equipment")
	var duplicate := ArmorSetResolver.resolve([bad, bad])
	check(not duplicate.errors.is_empty() and duplicate.player.is_empty(), "duplicate slot fails closed")
	check(ArmorSetResolver.describe(previous).contains("활성"), "player-facing active set text")
	await _inventory_ui(equipment, bag)
	skills.free()
	targets.free()
	equipment.free()
	player.free()
	bag.free()
	growth.free()
	if failures == 0: print("ARMOR_SET_OK armor_14 sets_3 thresholds_2_4 four_slots hybrid save migration skill_runtime assertions_%d" % assertions)
	quit(0 if failures == 0 else 1)


func _inventory_ui(equipment: CharacterEquipmentSystem, bag: GridInventory) -> void:
	for slot in SLOTS: equipment.take_equipment_state(slot)
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1280, 720)
	root.add_child(viewport)
	var window: Control = load("res://game/features/inventory/inventory_window.tscn").instantiate()
	viewport.add_child(window)
	window.configure(bag, equipment)
	window.open_panel()
	for slot in SLOTS:
		var item_id := &""
		for entry in window.session.inventory.get_snapshot().items:
			if entry.item_id == StringName("conduit_" + String(slot)): item_id = entry.instance_id
		check(item_id != &"", "drag fixture in live bag")
		window.slot_buttons[slot].item_dropped.emit(item_id)
		await process_frame
	check(window.session.dirty and equipment.get_armor_set_snapshot().sets.is_empty(), "drag only changes draft")
	check(window.stats_label.text.contains("축전자") and window.stats_label.text.contains("활성 4세트"), "draft exposes set activation")
	window.close_panel()
	check(window.confirmation_visible, "close guard with armor changes")
	window.resolve_exit(&"cancel")
	check(window.visible and window.session.dirty, "cancel exit retains set draft")
	window.close_panel()
	window.resolve_exit(&"save")
	check(equipment.get_armor_set_snapshot().sets[0].count == 4 and not window.visible, "save applies four-piece")
	for dimensions in [Vector2i(1280,720), Vector2i(1024,720), Vector2i(768,720), Vector2i(390,844)]:
		viewport.size = dimensions
		window.open_panel()
		for tab in [0, 2]:
			window.request_tab(tab)
			for frame in 8: await process_frame
			check(Rect2(Vector2.ZERO, Vector2(dimensions)).encloses(window.get_global_rect()), "armor window bounds %s tab %d" % [dimensions, tab])
		window.close_panel()
	viewport.queue_free()
	await process_frame
