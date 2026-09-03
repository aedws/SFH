extends RefCounted
## Extends the real game session: real room actors die, then physical F/I inputs.
var acquired_ids: Array[StringName] = []
var acquired_items: Dictionary = {}


func verify(tree: SceneTree, game: Node, tap: Callable) -> String:
	var loot = game.field_loot_acquisition_service
	var bag = game.inventory_system
	var encounters = game.room_encounter_system
	var player: Node2D = game.player
	# The first room/weapon pickup was already verified by the main E2E flow.
	for id in bag.items:
		if not loot.inventory_service.bag_before[&"items"].has(id) and bag.items[id].item_type == &"weapon":
			acquired_ids.append(id)
			acquired_items[bag.items[id].item_id] = true
	if acquired_ids.is_empty(): return "First room weapon did not enter the real bag"
	encounters.tier_values[&"maximum_encounters"] = 4
	for category in [&"armor", &"module", &"part"]:
		var entered := false
		for room: Dictionary in game.map_generator.get_room_encounter_snapshot():
			if room[&"room_index"] in encounters.completed_rooms or room.get(&"is_start_room", false) or room.get(&"is_extraction_room", false):
				continue
			player.global_position = room[&"center"]
			await tree.physics_frame
			encounters.call(&"_process", 0.0)
			if encounters.active_room_index == int(room[&"room_index"]):
				entered = true
				break
		if not entered: return "Additional room entry failed: %s" % category
		if encounters.active_doors.is_empty() or encounters.active_enemies.size() < int(encounters.tier_values[&"minimum_enemies"]):
			return "Additional room did not lock/spawn its minimum horde"
		var room_index: int = encounters.active_room_index
		for enemy in encounters.active_enemies.duplicate():
			enemy.take_damage(100000.0, {&"source_kind": &"e2e_room_clear"})
		for _frame in 4: await tree.process_frame
		encounters.call(&"_process", 0.0)
		if not encounters.completed_rooms.has(room_index) or not encounters.active_doors.is_empty():
			return "Additional room did not clear/open"
		var drop: Node2D
		for candidate in loot.get_active_drops():
			if candidate.candidate[&"source_type"] == &"room_reward" and candidate.comparison[&"item_type"] == category:
				drop = candidate
				break
		if drop == null: return "Room category guarantee missing: %s" % category
		var spawned: int = loot.total_spawned
		if loot.spawn_room_reward(drop.global_position, room_index) != null or loot.total_spawned != spawned:
			return "Repeated clear created another reward"
		var before: Dictionary = bag.items.duplicate()
		await _focus(tree, loot, player, drop)
		await tap.call(KEY_F)
		if is_instance_valid(drop): return "Physical F did not collect %s" % category
		var added := false
		for id in bag.items:
			if not before.has(id) and bag.items[id].item_type == category:
				acquired_ids.append(id)
				acquired_items[bag.items[id].item_id] = true
				added = true
		if not added: return "Collected item missing from actual bag: %s" % category
	# Kill the actual independent pursuit boss; room state must not change.
	var boss: Node2D
	for enemy in game.enemy_spawner.get_active_targets():
		if enemy.get_meta(&"elite_pursuer", false): boss = enemy
	if boss == null: return "Pursuit boss missing before boss loot test"
	var completed: int = encounters.completed_rooms.size()
	var boss_before := _count_source(loot, &"boss")
	loot.register_enemy(boss) # Registration is idempotent.
	boss.take_damage(100000.0, {&"source_kind": &"e2e_boss_clear"})
	for _frame in 4: await tree.process_frame
	if _count_source(loot, &"boss") - boss_before != loot.spawn_policy.boss_drop_count or encounters.completed_rooms.size() != completed:
		return "Boss drops missing/duplicated or boss death changed rooms"
	# Full bag, including partial multi-item acquisition, must be atomic.
	var checkpoint: Dictionary = bag.export_runtime_state()
	var filler := InventoryItemDefinition.new()
	filler.item_id = &"e2e_filler"
	filler.display_name = "E2E filler"
	filler.item_type = &"test"
	var fillers: Array[StringName] = []
	while true:
		var id: StringName = bag.add_item(filler)
		if id == &"": break
		fillers.append(id)
	if fillers.is_empty(): return "No bag space for atomic pickup test"
	bag.take_item(fillers.back()) # Exactly one cell available; request two modules.
	var full_before: Dictionary = bag.export_runtime_state()
	var total_before: int = loot.total_acquired
	var full_drop: Node2D = loot.spawn_candidate(player.global_position, {&"item_id": &"ballistic_core_item", &"grade": 2, &"quantity": 2, &"source_type": &"room_reward"})
	await _focus(tree, loot, player, full_drop)
	await tap.call(KEY_F)
	if not is_instance_valid(full_drop) or loot.total_acquired != total_before or bag.export_runtime_state() != full_before or "공간 부족" not in loot.panel.controls_label.text:
		return "Partial pickup lost/duplicated items or omitted full-bag feedback"
	loot.cancel_preview()
	bag.restore_runtime_state(checkpoint)
	# Controlled compatible variants complement the random drops; definitions are
	# real catalogue entries, not preloaded inventory placeholders.
	for item_id in [&"assault_rifle", &"rifle_scope_item"]:
		var before: Dictionary = bag.items.duplicate()
		var drop: Node2D = loot.spawn_candidate(player.global_position, {&"item_id": item_id, &"grade": 2, &"quantity": 1, &"source_type": &"room_reward"})
		await _focus(tree, loot, player, drop)
		await tap.call(KEY_F)
		if is_instance_valid(drop): return "Compatible variant pickup failed"
		for id in bag.items:
			if not before.has(id):
				acquired_ids.append(id)
				acquired_items[item_id] = true
	# The same physical inventory entry point edits these exact dropped instances.
	await tap.call(KEY_I)
	var window = game.inventory_window
	if not window.visible: return "I did not open the run inventory"
	var session = window.session
	var installed_kinds: Dictionary = {}
	for id in acquired_ids:
		var item: Dictionary = session.get_item_entry(id)
		var kind: StringName = item[&"item_type"]
		var installed := false
		var compatible := false
		if kind in [&"weapon", &"armor"]:
			for slot in [&"main", &"secondary", &"body", &"feet"]:
				if not session.equipment.can_equip_definition(slot, item[&"linked_resource"]): continue
				compatible = true
				if session.equip_item(id, slot):
					installed = true
					break
		else:
			# A part may target a weapon not currently active; use a compatible owned spare.
			for slot in [&"main", &"secondary", &"body", &"feet"]:
				if session.install_item(id, slot):
					installed = true
					break
			if not installed and kind == &"part":
				for spare in session.inventory.get_items_by_type(&"weapon"):
					var preview := EquipmentItemState.new()
					preview.configure(&"e2e", spare[&"linked_resource"])
					if preview.install_part(item[&"linked_resource"], 1):
						installed = session.equip_item(spare[&"instance_id"], &"main") and session.install_item(id, &"main")
						break
		if installed:
			installed_kinds[kind] = true
		elif compatible or kind in [&"armor", &"module"]:
			return "Compatible dropped %s could not be equipped: %s" % [kind, session.error_message]
		elif session.get_item_entry(id).is_empty():
			return "Incompatible drop was not retained in bag"
	if installed_kinds.size() != 4: return "Compatible dropped variants did not cover all four equipment categories"
	if not session.commit(): return "Dropped loadout commit failed"
	await tap.call(KEY_ESCAPE)
	if tree.paused or window.visible: return "Inventory did not resume combat"
	return ""


func verify_settlement(game: Node) -> String:
	var result: Dictionary = game.last_loot_settlement
	for item_id in acquired_items:
		if int(result.get(&"warehouse_items", {}).get(item_id, 0)) < 1 or not game.persistent_profile.has_warehouse_item(item_id):
			return "Extracted dropped item not in permanent warehouse: %s" % item_id
	return ""


func verify_return(game: Node) -> String:
	for id in acquired_ids:
		if game.inventory_system.items.has(id): return "Run item duplicated into hub bag and warehouse"
	return ""


func _focus(tree: SceneTree, loot: Node, player: Node2D, drop: Node2D) -> void:
	loot.cancel_preview()
	player.global_position = Vector2(-100000, -100000)
	for candidate in loot.get_active_drops(): candidate.call(&"_process", 0.0)
	player.global_position = drop.global_position
	drop.call(&"_process", 0.0)
	await tree.process_frame


func _count_source(loot: Node, source: StringName) -> int:
	var count := 0
	for drop in loot.get_active_drops():
		if drop.candidate[&"source_type"] == source: count += 1
	return count
