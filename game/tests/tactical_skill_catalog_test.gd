extends SceneTree
var errors := PackedStringArray()
func _initialize() -> void: _run.call_deferred()
func check(value: bool, message: String) -> void:
	if not value: errors.append(message)
func _run() -> void:
	var world := Node2D.new()
	root.add_child(world)
	var player: Node2D = load("res://game/features/player/player.tscn").instantiate()
	world.add_child(player)
	var targets := Node2D.new()
	world.add_child(targets)
	var count := 0
	var activated := 0
	for file in DirAccess.get_files_at("res://game/features/combat_skills/definitions"):
		if not file.ends_with(".tres"): continue
		var skill: Resource = load("res://game/features/combat_skills/definitions/"+file)
		check(skill != null and skill.is_valid(), "definition: "+file)
		count += 1
		var victim: Node2D = load("res://game/features/enemies/enemy.tscn").instantiate()
		victim.max_health = 10000
		targets.add_child(victim)
		victim.set_physics_process(false)
		player.global_position = Vector2.ZERO
		victim.global_position = Vector2(100,0)
		var kit := CombatSkillLoadout.new()
		kit.skills = [skill]
		var resources: Node = load("res://game/features/combat_resources/combat_resource_system.tscn").instantiate()
		world.add_child(resources)
		check(resources.configure(player, world, kit, load("res://game/features/combat_resources/configs/default_combat_resources.tres")), "resources: "+file)
		resources.set_process(false)
		var system := CombatSkillSystem.new()
		world.add_child(system)
		check(system.configure(player, targets, world, kit, true, resources, load("res://game/features/smart_targeting/configs/default_smart_targeting.tres")), "system: "+file)
		system.set_process(false)
		var mobility_policy := {&"families":"mobility|self", &"cooldown_multiplier":0.8}
		system.set_character_specialization(mobility_policy)
		var energy: float = resources.current_energy
		if system.try_activate(0): activated += 1
		check(is_equal_approx(resources.current_energy, energy - skill.energy_cost), "AP consumption: "+file)
		var factor: float = SkillSpecializationPolicy.modifiers(skill, mobility_policy).get(&"cooldown_multiply", 1.0)
		check(is_equal_approx(system.cooldowns[0], skill.cooldown_seconds * factor), "passive cooldown: "+file)
		check(is_equal_approx(resources.recharge_remaining[0], skill.charge_recovery_seconds * factor), "passive charge: "+file)
		check(not system.try_activate(0), "cooldown denial: "+file)
		system.cancel_runtime_effects()
		system.free()
		resources.free()
		victim.free()
		if skill == null or not skill.effect is TacticalPatternEffect: continue
		player.global_position = Vector2.ZERO
		var enemy: Node2D = load("res://game/features/enemies/enemy.tscn").instantiate()
		targets.add_child(enemy)
		enemy.set_physics_process(false)
		enemy.global_position = Vector2(120,0)
		var stats: Dictionary = player.get_runtime_stats()
		var result: Dictionary = skill.effect.activate(player, {&"target_container":targets, &"effect_parent":world,
			&"target":enemy, &"target_point":Vector2(120,0), &"direction":Vector2.RIGHT, &"damage_enabled":true})
		check(result.success, "activation: "+file)
		if result.get(&"runtime") != null:
			var effect: Node = result.runtime
			effect.set_process(false)
			effect.advance(30)
			check(effect.emitted == skill.effect.pulses, "bounded complete pulse schedule: "+file)
			if skill.effect.shape != "self" and not (skill.effect.shape == "ring" and skill.effect.inner_radius > 120):
				check(effect.hits > 0, "actual hits: "+file)
			effect.free()
			check(player.get_runtime_stats() == stats, "buff cleanup: "+file)
		enemy.free()
	check(count >= 40, "40 definitions")
	check(activated == count, "40 real combat/resource activations")
	var csv := FileAccess.get_file_as_string("res://game/features/combat_skills/data/skill_catalog.csv")
	var patterns := FileAccess.get_file_as_string("res://game/features/combat_skills/data/tactical_patterns.csv")
	check(not SkillBalanceSnapshot.parse(csv, patterns).has(&"error"), "live snapshot valid")
	check(SkillBalanceSnapshot.parse(csv, "skill_id\n").has(&"error"), "missing patterns rejected")
	check(SkillBalanceSnapshot.parse(csv, patterns + "\n" + patterns.split("\n")[1]).has(&"error"), "duplicate rejected")
	var lance: Resource = load("res://game/features/combat_skills/definitions/plasma_lance.tres")
	var modified: Resource = SkillBalanceSnapshot.apply(lance, {"effect":{"damage":99.0}})
	check(modified.effect.damage == 99 and lance.effect.damage != 99, "immutable resources")
	check(SkillBalanceSnapshot.apply(lance, {"effect":{"interval":0.0}}) == null, "zero interval rejected")
	var specialization := {&"families":"line|cone", &"damage_multiplier":1.2}
	check(SkillSpecializationPolicy.modifiers(lance, specialization).damage_multiply == 1.2, "fixed damage specialization")
	check(SkillSpecializationPolicy.modifiers(load("res://game/features/combat_skills/definitions/frost_zone.tres"), specialization).is_empty(), "off-family unchanged")
	var statuses := {&"stun": {&"remaining":2}}
	check(EnemyStatusPolicy.movement_multiplier(statuses,false)==0, "normal stun")
	check(EnemyStatusPolicy.movement_multiplier(statuses,true)>0, "boss resistance")
	check(not EnemyStatusPolicy.can_attack(statuses,false), "stun attack denial")
	var panel := InitialLoadoutPanel.new()
	root.add_child(panel)
	await process_frame
	check(panel.characters.size()==3 and not panel.confirm_button.disabled, "initial selector")
	panel.free()
	await _entry_layout()
	world.free()
	await _initial_launch_matrix()
	if not errors.is_empty():
		for error in errors: push_error(error)
		quit(1)
	else:
		print("TACTICAL_SKILL_CATALOG_PASS definitions=40 actual_effects=36 resource_activations=40 initial_combinations=24 immutable_live=true cleanup=true")
		quit()

func _entry_layout() -> void:
	var entry: Control = load("res://game/features/mobile_controls/control_mode_entry.gd").new()
	entry.launch_game = false
	entry.settings_path = "user://sfh_tactical_entry_test.json"
	root.add_child(entry)
	entry.launch_game = true
	entry._finish_selection(&"off")
	root.content_scale_size = Vector2i.ZERO
	for dimensions in [Vector2i(1280,800), Vector2i(640,400), Vector2i(390,844)]:
		root.size = dimensions
		for frame in 12: await process_frame
		check(root.get_visible_rect().grow(1).encloses(entry.initial_panel.confirm_button.get_global_rect()), "initial confirm visible: "+str(dimensions))
		for arg in OS.get_cmdline_user_args():
			if arg.begins_with("--capture-dir=") and DisplayServer.get_name() != "headless":
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png(arg.trim_prefix("--capture-dir=").path_join("initial-%dx%d.png" % [dimensions.x, dimensions.y]))
	entry.free()
	root.size = Vector2i(1280,800)
	if FileAccess.file_exists("user://sfh_tactical_entry_test.json"):
		DirAccess.remove_absolute(ProjectSettings.globalize_path("user://sfh_tactical_entry_test.json"))

func _initial_launch_matrix() -> void:
	var game: Node = load("res://game/scenes/game.tscn").instantiate()
	var features: Resource = game.features.duplicate(true)
	features.desktop_progress_enabled = false
	var paths := PackedStringArray()
	for property in features.get_property_list():
		if String(property.name).ends_with("storage_path"):
			var path := "user://sfh_tactical_test_%s.json" % property.name
			features.set(property.name, path)
			paths.append(path)
	game.features = features
	root.add_child(game)
	await process_frame
	await process_frame
	game.persistent_profile.reset_profile(true)
	var count := 0
	for character in [&"vanguard", &"runner", &"bulwark"]:
		for file in DirAccess.get_files_at("res://game/features/equipment/definitions/weapons"):
			if not file.ends_with(".tres"): continue
			var path := "res://game/features/equipment/definitions/weapons/"+file
			check(InitialLoadoutPanel.apply_selection({&"character_id":character,&"weapon_path":path}, game.character_selection_service, game.equipment_system), "initial apply: "+file)
			check(game.start_hub != null and not game.run_started, "selection stays in lobby")
			check(game.training_combat_skill_system.character_specialization == game.character_selection_service.get_investment_context().skill_specialization, "training specialization follows selection")
			if not game.start_run("small"):
				check(false, "initial launch: "+file+" "+str(game.status_label.text))
				continue
			check(game.equipment_system.get_equipment_state(&"main").definition.resource_path == path, "equipped weapon preserved: "+file)
			check(not game.combat_skill_system.character_specialization.is_empty(), "passive in combat")
			count += 1
			game._abandon_run_to_start_hub()
	check(count == 24, "initial launch 3x8")
	game.free()
	for path in paths:
		if FileAccess.file_exists(path): DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
