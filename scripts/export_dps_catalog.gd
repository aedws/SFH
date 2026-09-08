extends SceneTree
## Read-only game data adapter for the authenticated wiki. Never writes balance data.
const OUTPUT := "res://docs/assets/dps-catalog.json"
const ROOTS := ["game/features/weapons", "game/features/weapon_balance", "game/features/combat_skills", "game/features/combat_resources", "game/features/equipment", "game/features/growth_balance", "game/features/character_selection", "game/features/player", "game/features/meta_progression", "game/features/enemies", "game/features/operation_contract"]
const SOURCE_FILES := ["scripts/export_dps_catalog.gd"]
var sources: Dictionary = {}

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var catalog := {"schema": 1, "weapons": [], "skills": [], "sources": {}, "source_roots": ROOTS, "source_files": SOURCE_FILES.duplicate()}
	catalog["loadout"] = preload("res://scripts/export_dps_loadout.gd").build()
	var parsed: Dictionary = load("res://game/features/weapon_balance/weapon_balance_table.gd").parse(FileAccess.get_file_as_string("res://game/features/weapon_balance/data/weapon_balance.csv"))
	assert(parsed.errors.is_empty(), "Invalid locked weapon CSV")
	var weapon_runtime: Node = load("res://game/features/weapons/auto_weapon.gd").new()
	for file in DirAccess.get_files_at("res://game/features/equipment/definitions/weapons"):
		if not file.ends_with(".tres"): continue
		var weapon: Resource = load("res://game/features/equipment/definitions/weapons/" + file)
		assert(weapon.is_valid())
		var balance: Dictionary = parsed.data.get(weapon.weapon_id, weapon_runtime._fallback_balance(weapon.weapon_id)).duplicate(true)
		balance.erase(&"projectile_color")
		var options: Array = []
		for option in weapon.fixed_options: options.append(option.snapshot())
		var innate: Dictionary = weapon.innate_skill.snapshot() if weapon.innate_skill else {}
		innate.erase(&"effect_color")
		catalog.weapons.append({"id":weapon.weapon_id, "name":weapon.display_name, "balance":balance, "tags":weapon.combat_tags, "overrides":weapon.skill_mechanic_overrides, "options":options, "innate":innate, "source_mode":"locked_csv" if parsed.data.has(weapon.weapon_id) else "runtime_fallback"})
	weapon_runtime.free()
	for file in DirAccess.get_files_at("res://game/features/combat_skills/definitions"):
		if not file.ends_with(".tres"): continue
		var skill: Resource = load("res://game/features/combat_skills/definitions/"+file)
		assert(skill.is_valid())
		var row: Dictionary = skill.get_snapshot(0)
		row.erase(&"accent_color")
		var effect_kinds := {"res://game/features/combat_skills/effects/blink_skill_effect.gd":"path", "res://game/features/combat_skills/effects/magnetic_field_skill_effect.gd":"field", "res://game/features/combat_skills/effects/speed_boost_skill_effect.gd":"utility"}
		var effect_path: String = skill.effect.get_script().resource_path
		if not effect_kinds.has(effect_path):
			push_error("Register DPS model for new effect: " + effect_path)
			quit(1)
			return
		row["kind"] = effect_kinds[effect_path]
		catalog.skills.append(row)
	var resource: Resource = load("res://game/features/combat_resources/configs/default_combat_resources.tres")
	catalog["resources"] = {"maximum":resource.maximum_energy, "starting":resource.starting_energy, "regen":resource.regeneration_policy.energy_per_second, "delay":resource.regeneration_policy.delay_after_spend}
	var enemy: Node = load("res://game/features/enemies/enemy.gd").new()
	catalog["enemy"] = {"hp":enemy.max_health, "armor":enemy.max_armor, "damage":enemy.contact_damage, "interval":enemy.contact_interval}
	enemy.free()
	catalog["difficulties"] = load("res://game/features/operation_contract/configs/default_operation_contracts.tres").difficulties
	catalog.loadout["fixtures"] = preload("res://scripts/export_dps_loadout.gd").parity(catalog, root)
	catalog["distance_fixtures"] = []
	var distance_policy = preload("res://game/features/weapon_balance/weapon_distance_policy.gd")
	for weapon in catalog.weapons:
		var curve: String = weapon.balance.get("distance_damage_curve", "0:1;1:1")
		for ratio in [0.0, 0.125, 0.25, 0.5, 0.6, 0.75, 1.0, 1.5]:
			catalog.distance_fixtures.append({"weapon": weapon.id, "ratio": ratio, "multiplier": distance_policy.multiplier(distance_policy.parse(curve), ratio * weapon.balance.target_range_px, weapon.balance.target_range_px)})
	for directory in ROOTS: _collect(directory)
	for path in SOURCE_FILES: _collect_file(path)
	for path in ["scripts/export_dps_loadout.gd", "game/core/item_quality_descriptor.gd"]:
		catalog.source_files.append(path)
		_collect_file(path)
	catalog.sources = sources
	var result := JSON.stringify(catalog, "\t", true, true) + "\n"
	if "--check" in OS.get_cmdline_user_args():
		var difference := _difference(JSON.parse_string(FileAccess.get_file_as_string(OUTPUT)), JSON.parse_string(result), "catalog")
		if not difference.is_empty():
			push_error("DPS catalog stale at " + difference + ". Run scripts/export_dps_catalog.gd")
			quit(1)
			return
	else:
		var file := FileAccess.open(OUTPUT, FileAccess.WRITE)
		file.store_string(result)
	print("DPS_CATALOG_OK weapons=%d skills=%d" % [catalog.weapons.size(),catalog.skills.size()])
	quit()

## JSON formatting and native floating-point serialization may differ across OSes.
## Source hashes and topology remain exact; only numeric roundoff receives tolerance.
func _difference(expected: Variant, actual: Variant, path: String) -> String:
	if (expected is float or expected is int) and (actual is float or actual is int):
		if absf(float(expected) - float(actual)) <= 0.000001 * maxf(1.0, maxf(absf(float(expected)), absf(float(actual)))): return ""
	elif expected is Dictionary and actual is Dictionary:
		if expected.size() != actual.size(): return path + " keys"
		for key in expected:
			if not actual.has(key): return path + "." + str(key) + " missing"
			var difference := _difference(expected[key], actual[key], path + "." + str(key))
			if not difference.is_empty(): return difference
		return ""
	elif expected is Array and actual is Array:
		if expected.size() != actual.size(): return path + " length"
		for index in expected.size():
			var difference := _difference(expected[index], actual[index], path + "[%d]" % index)
			if not difference.is_empty(): return difference
		return ""
	elif expected == actual: return ""
	return path + ": " + str(expected) + " != " + str(actual)

func _collect(directory: String) -> void:
	for file in DirAccess.get_files_at("res://"+directory):
		if file.get_extension() in ["gd","tres","tscn","csv"]: _collect_file(directory+"/"+file)
	for child in DirAccess.get_directories_at("res://"+directory): _collect(directory+"/"+child)

func _collect_file(path: String) -> void:
	sources[path] = FileAccess.get_file_as_string("res://"+path).replace("\r\n","\n").sha256_text()
