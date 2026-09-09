extends SceneTree

class Stats extends Node:
	func apply_equipment_modifiers(_modifiers: Dictionary) -> void: pass

class Target extends CharacterBody2D:
	var hits: Array[Dictionary] = []
	func _ready() -> void:
		collision_layer = 2
		collision_mask = 0
		var shape := CollisionShape2D.new()
		var circle := CircleShape2D.new()
		circle.radius = 18
		shape.shape = circle
		add_child(shape)
		add_to_group(&"arsenal_targets")
	func take_damage(amount: float, context: Dictionary = {}) -> void:
		hits.append({&"amount": amount, &"context": context.duplicate(true)})
	func direct_hits() -> int:
		return hits.filter(func(hit): return hit.context.get(&"source_kind") in [&"weapon_projectile", &"weapon_melee"]).size()

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	root.get_tree().create_timer(25).timeout.connect(func(): push_error("ARSENAL_TIMEOUT"); quit(1))
	var equipment: Node = load("res://game/features/equipment/equipment_system.tscn").instantiate()
	root.add_child(equipment)
	var stats := Stats.new()
	root.add_child(stats)
	assert(equipment.configure(load("res://game/features/equipment/loadouts/default_loadout.tres"), stats))
	_check_saved_slot_policy(equipment)
	var shots := Node2D.new()
	root.add_child(shots)
	var weapon: Node2D = load("res://game/features/weapons/auto_weapon.tscn").instantiate()
	root.add_child(weapon)
	weapon.fallback_target_group = &"arsenal_targets"
	# Intentionally no balance service: optional-feature fallback must preserve all eight attacks.
	weapon.configure(shots, equipment)
	var table: Dictionary = load("res://game/features/weapon_balance/weapon_balance_table.gd").parse(FileAccess.get_file_as_string("res://game/features/weapon_balance/data/weapon_balance.csv"))
	assert(table.errors.is_empty() and table.data.size() == 8)
	var csv := FileAccess.get_file_as_string("res://game/features/weapon_balance/data/weapon_balance.csv")
	for invalid in [csv.replace("melee_arc", "unknown"), csv.replace("6.5,0.8", "nan,0.8"), csv.replace("5,24,1,0", "100,24,1,0")]:
		assert(not WeaponBalanceTable.parse(invalid).errors.is_empty(), "Reject invalid live attack data")
	var catalog: Resource = load("res://game/features/field_loot/configs/default_field_loot_equipment.tres")
	assert(catalog.validation_errors().is_empty())
	for id in table.data:
		var definition: Resource = load("res://game/features/equipment/definitions/weapons/%s.tres" % id)
		assert(definition.is_valid() and catalog.get_inventory_definition(id) != null)
		assert(equipment.equip_definition(&"main", definition), "Equip %s" % id)
		assert(equipment.set_active_weapon_slot(&"main"))
		var target := Target.new()
		shots.add_child(target)
		target.position = Vector2(65, 0)
		await physics_frame
		await physics_frame
		weapon.cooldown = 0.0
		var before: int = weapon.total_trigger_pulls
		Input.action_press(&"primary_attack")
		await process_frame
		await process_frame
		Input.action_release(&"primary_attack")
		await create_timer(0.13).timeout
		assert(weapon.total_trigger_pulls > before, "LMB trigger %s" % id)
		assert(target.direct_hits() > 0, "Real collision/sweep %s" % id)
		assert(weapon.current_balance.attack_mode == table.data[id].attack_mode)
		if String(table.data[id].attack_mode).begins_with("melee"):
			assert(shots.get_children().filter(func(n): return n is WeaponProjectile).is_empty(), "Melee must not emit bullets")
		if id == &"breach_shotgun": assert(target.direct_hits() == 5, "All five near pellets")
		for child in shots.get_children(): child.free()
		await process_frame
	# Real travelling projectile: exactly four aligned enemies, fifth beyond the pierce budget.
	assert(equipment.equip_definition(&"main", load("res://game/features/equipment/definitions/weapons/rail_rifle.tres")))
	var rail_targets: Array[Target] = []
	for i in 5:
		var target := Target.new()
		shots.add_child(target)
		target.position = Vector2(55 + i * 45, 0)
		rail_targets.append(target)
	await physics_frame
	await physics_frame
	weapon.cooldown = 0.0
	assert(weapon.try_fire_once())
	await create_timer(0.3).timeout
	for i in 4: assert(rail_targets[i].direct_hits() == 1, "Rail pierce %d" % i)
	assert(rail_targets[4].direct_hits() == 0, "Rail pierce budget")
	for child in shots.get_children(): child.free()
	# Geometry and world collision: front arc only, caps, duplicate candidates, no through-wall damage.
	var points := [Vector2(50,0), Vector2(80,0), Vector2(-50,0), Vector2(300,0), Vector2(50,90)]
	var candidates: Array = []
	for point in points:
		var target := Target.new()
		shots.add_child(target)
		target.position = point
		candidates.append(target)
	var wall := StaticBody2D.new()
	wall.collision_layer = 16
	wall.position = Vector2(68,0)
	var wall_shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(8,40)
	wall_shape.shape = rect
	wall.add_child(wall_shape)
	shots.add_child(wall)
	await physics_frame
	await physics_frame
	var strike := WeaponMeleeStrike.new()
	shots.add_child(strike)
	strike.execute(Vector2.RIGHT, 10.0, table.data[&"greatsword"], candidates + [candidates[0]], {})
	assert(candidates[0].direct_hits() == 1 and candidates[1].direct_hits() == 0, "Wall and deduplication")
	assert(candidates[2].direct_hits() == 0 and candidates[3].direct_hits() == 0, "Rear and out of reach")
	assert(candidates[4].direct_hits() == 1, "Wide sword arc")
	await create_timer(0.3).timeout
	assert(candidates[0].direct_hits() == 1, "FX never reapplies damage")
	assert(MeleeStrikePolicy.contains(Vector2(175,10), Vector2.RIGHT, 185, 8, &"melee_thrust"))
	assert(not MeleeStrikePolicy.contains(Vector2(80,35), Vector2.RIGHT, 185, 8, &"melee_thrust"))
	assert(not MeleeStrikePolicy.contains(Vector2(95,0), Vector2.RIGHT, 85, 65, &"melee_arc"))
	for child in shots.get_children(): child.free()
	# Unknown future ID uses the data contract, not an ID switch in the weapon executor.
	var future: Dictionary = table.data[&"combat_dagger"].duplicate(true)
	future.weapon_id = &"future_blade"
	future.pierce_count = 0
	var a := Target.new()
	var b := Target.new()
	shots.add_child(a); shots.add_child(b)
	a.position = Vector2(40,0); b.position = Vector2(60,0)
	await physics_frame
	await physics_frame
	var future_strike := WeaponMeleeStrike.new()
	shots.add_child(future_strike)
	future_strike.execute(Vector2.RIGHT, 3.0, future, [b,a], {})
	assert(a.direct_hits() == 1 and b.direct_hits() == 0, "Nearest-first target cap on future definition")
	weapon.free(); equipment.free(); shots.free(); stats.free()
	print("WEAPON_ARSENAL_OK weapons_8 actual_LMB hits_8 shotgun_5 melee_no_bullets walls caps geometry future_definition optional_balance")
	quit()


func _check_saved_slot_policy(equipment: Node) -> void:
	var original: Dictionary = equipment.export_runtime_state()
	var saved: Dictionary = equipment.export_runtime_state()
	var legacy := saved[&"loadout"] as EquipmentLoadout
	legacy.extension_data.erase(&"weapon_slot_policy")
	var rule := legacy.get_slot_rule(&"main")
	rule.allowed_major_tags.assign([&"ranged"])
	rule.allowed_middle_tags.assign([&"firearm"])
	rule.allowed_minor_tags.assign([&"rifle"])
	saved[&"equipment_states"][&"main"].level = 2
	saved[&"active_weapon_slot"] = &"secondary"
	var codec := LoadoutValueCodec.new()
	var encoded: Variant = codec.encode(saved)
	assert(codec.error.is_empty())
	var decoder := LoadoutValueCodec.new()
	var restored: Dictionary = decoder.decode(encoded)
	assert(decoder.error.is_empty())
	assert(equipment.validate_runtime_state(restored).is_empty())
	assert(equipment.restore_runtime_state(restored))
	var dagger: Resource = load("res://game/features/equipment/definitions/weapons/combat_dagger.tres")
	assert(equipment.can_equip_definition(&"main", dagger), "Legacy Windows save accepts melee without resetting gear")
	assert(equipment.get_equipment_state(&"main").level == 2 and equipment.active_weapon_slot == &"secondary")
	assert(not restored[&"loadout"].get_slot_rule(&"main").accepts(dagger), "Migration must not mutate snapshot")
	assert(not equipment.can_equip_definition(&"secondary", dagger), "Secondary pistol policy unchanged")
	# Explicitly versioned custom restrictions and unrelated loadouts must remain untouched.
	restored[&"loadout"].extension_data[&"weapon_slot_policy"] = &"arsenal_v1"
	assert(equipment.restore_runtime_state(restored))
	assert(not equipment.can_equip_definition(&"main", dagger))
	restored[&"loadout"].extension_data.erase(&"weapon_slot_policy")
	restored[&"loadout"].loadout_id = &"custom_operator"
	assert(equipment.restore_runtime_state(restored))
	assert(not equipment.can_equip_definition(&"main", dagger))
	assert(equipment.restore_runtime_state(original))
