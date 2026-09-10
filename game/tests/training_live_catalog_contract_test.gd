extends SceneTree
var failures := PackedStringArray()
func _initialize() -> void: _run.call_deferred()
func check(value: bool, label: String) -> void:
	if not value: failures.append(label)
func find_skill(rows: Array, id: StringName) -> Resource:
	for row in rows:
		if row.skill_id == id: return row
	return null
func _run() -> void:
	var quoted := SkillBalanceSnapshot.parse_rows('\ufeffnote,id\r\n"line 1\nline ""2"", comma",plasma_lance\r\n')
	check(quoted.size() == 1 and quoted[0].note == 'line 1\nline "2", comma' and quoted[0].id == 'plasma_lance', "public CSV BOM quoted newline escaped comma")
	check(SkillBalanceSnapshot.parse_rows('id,id\na,b').is_empty(), "duplicate header rejected")
	check(SkillBalanceSnapshot.parse_rows('id,note\na').is_empty(), "short row rejected")
	check(SkillBalanceSnapshot.parse_rows('id,note\na,"unfinished').is_empty(), "unterminated quote rejected")
	var game = load("res://game/scenes/game.tscn").instantiate()
	var features: Resource = game.features.duplicate(true)
	var directory := OS.get_cache_dir().path_join("sfh-live-catalog-%d" % Time.get_ticks_usec())
	DirAccess.make_dir_recursive_absolute(directory)
	for field in ["persistent_profile", "conditional_ranking", "meta_progression", "key_mapping", "skill_binding", "presentation_settings", "desktop_progress"]:
		features.set(field + "_storage_path", directory.path_join(field + ".json"))
	game.features = features
	root.add_child(game)
	for frame in 6: await process_frame
	var source: Node = game.loadout_investment_service
	var training: Node = game.training_ground_service
	var skills: Node = game.training_combat_skill_system
	var original: Resource = load("res://game/features/combat_skills/definitions/plasma_lance.tres")
	var original_damage: float = original.effect.damage
	var values := {"cooldown_seconds":3.0, "energy_cost":7.0, "maximum_charges":3, "charge_recovery_seconds":4.0, "effect":{"damage":123.0,"radius":333.0}}
	# Isolated accepted-live fixture; never sends requests or edits shared Sheets.
	source.skill_balance_values = {"plasma_lance":values.duplicate(true), "blink":{"cooldown_seconds":2.0,"energy_cost":7.0,"maximum_charges":3}}
	var provided: Resource = find_skill(source.get_skill_catalog_resources(), &"plasma_lance")
	var operation := SkillBalanceSnapshot.apply(original, values)
	check(provided.effect.damage == operation.effect.damage and provided.cooldown_seconds == 3, "training catalog must equal live operation 123/3")
	check(provided.energy_cost == 7 and provided.maximum_charges == 3 and provided.effect.radius == 333, "AP/charges/pattern applied")
	provided.effect.damage = 999
	check(original.effect.damage == original_damage, "catalog cannot mutate source resource")
	provided = find_skill(source.get_skill_catalog_resources(), &"plasma_lance")
	check(provided.effect.damage == 123, "caller cannot mutate next catalog")
	var baseline: Dictionary = skills.export_runtime_state()
	var profile_before: Dictionary = game.persistent_profile.get_snapshot().duplicate(true)
	game._cycle_hub_training()
	check(find_skill(training.skill_catalog, &"plasma_lance").effect.damage == 123, "live refresh after hub installation")
	check(skills.loadout.skills[0].cooldown_seconds == 2 and skills.loadout.skills[0].maximum_charges == 3, "already equipped trial skill refreshed")
	for index in training.skill_catalog.size():
		if skills.loadout.skills[0].skill_id == &"plasma_lance": break
		training.cycle_training_skill(0)
	check(skills.loadout.skills[0].skill_id == &"plasma_lance" and skills.loadout.skills[0].effect.damage == 123, "actual UI cycle installs live definition")
	var energy_before: float = skills.resource_provider.current_energy
	check(skills.try_activate(0), "installed live skill really activates")
	check(is_equal_approx(skills.resource_provider.current_energy, energy_before - 7), "actual live AP consumption")
	source.skill_balance_values["plasma_lance"]["effect"]["damage"] = 124.0
	check(find_skill(training.skill_catalog, &"plasma_lance").effect.damage == 123 and operation.effect.damage == 123, "running trial and operation frozen")
	check(game._finish_hub_training(), "exit succeeds")
	check(skills.loadout.skills[0].cooldown_seconds == baseline.loadout.skills[0].cooldown_seconds, "original definitions restored")
	check(skills.export_runtime_state().resources == baseline.resources, "AP and charges restored")
	game._cycle_hub_training()
	check(find_skill(training.skill_catalog, &"plasma_lance").effect.damage == 124, "next trial takes new snapshot")
	check(game._finish_hub_training(), "repeat exit")
	check(game.persistent_profile.get_snapshot() == profile_before, "no profile mutation")
	var bad := values.duplicate(true)
	bad.effect.damage = -1.0
	check(SkillBalanceSnapshot.apply(original, bad) == null, "invalid snapshot rejected")
	source._on_live_request_completed(0,200,[],"bad".to_utf8_buffer(),&"weapon")
	source._on_live_request_completed(0,200,[],"bad".to_utf8_buffer(),&"skill")
	source._on_live_request_completed(0,200,[],"bad".to_utf8_buffer(),&"patterns")
	check(find_skill(source.get_skill_catalog_resources(), &"plasma_lance").effect.damage == 124, "invalid live response retains last good data")
	source.skill_balance_values.clear()
	check(find_skill(source.get_skill_catalog_resources(), &"plasma_lance").effect.damage == original_damage, "locked fallback")
	game.queue_free()
	for frame in 3: await process_frame
	if not failures.is_empty():
		for failure in failures: printerr(failure)
		quit(1)
	else:
		print("TRAINING_LIVE_CATALOG_OK immutable training operation restoration invalid last-good")
		quit(0)
