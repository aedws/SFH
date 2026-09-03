class_name MetaProgressionSystem
extends Node

signal meta_progress_changed(snapshot: Dictionary)
signal run_settled(result: Dictionary)

const TARGET_IDS := [&"character", &"weapon", &"armor"]
const PLAYER_MODIFIER_METHOD := &"set_runtime_modifier_source"
const WEAPON_MODIFIER_METHOD := &"set_runtime_modifiers"
const ARMOR_LEVEL_METHOD := &"set_external_armor_level"

var levels: Dictionary = {}
var experience: Dictionary = {}
var storage_path: String = "user://sfh_meta_progression.json"
var persistence_enabled: bool = true
var safe_persistence := false
var storage_error := ""
var save_store = preload("res://game/core/persistence/atomic_json_store.gd").new()


func configure(
	new_storage_path: String = "user://sfh_meta_progression.json",
	enable_persistence: bool = true,
	use_safe_storage: bool = false
) -> bool:
	storage_path = new_storage_path
	persistence_enabled = enable_persistence and not storage_path.is_empty()
	safe_persistence = use_safe_storage
	storage_error = ""
	_reset_values()
	if persistence_enabled:
		_load()
	meta_progress_changed.emit(get_snapshot())
	return true


func settle_run(meta_experience: Dictionary) -> Dictionary:
	var gained := {&"character": 0, &"weapon": 0, &"armor": 0}
	var levels_before := levels.duplicate(true)
	for target_id in TARGET_IDS:
		var amount := maxi(0, int(meta_experience.get(target_id, 0)))
		gained[target_id] = amount
		experience[target_id] = int(experience[target_id]) + amount
		while int(experience[target_id]) >= required_experience(target_id):
			experience[target_id] = (
				int(experience[target_id]) - required_experience(target_id)
			)
			levels[target_id] = int(levels[target_id]) + 1
	if persistence_enabled:
		_save()
	var result := {
		&"gained_experience": gained,
		&"levels_before": levels_before,
		&"levels_after": levels.duplicate(true),
		&"snapshot": get_snapshot(),
	}
	meta_progress_changed.emit(get_snapshot())
	run_settled.emit(result)
	return result


func apply_to_targets(player_target: Node, weapon_target: Node, equipment_target: Node) -> void:
	var character_level := int(levels[&"character"])
	if player_target != null and player_target.has_method(PLAYER_MODIFIER_METHOD):
		player_target.call(PLAYER_MODIFIER_METHOD, &"meta_character", {
			&"max_health": {&"add": float(character_level - 1) * 5.0, &"multiply": 1.0},
			&"movement_speed": {
				&"add": 0.0,
				&"multiply": pow(1.02, float(character_level - 1)),
			},
		})
	var weapon_level := int(levels[&"weapon"])
	if weapon_target != null and weapon_target.has_method(WEAPON_MODIFIER_METHOD):
		weapon_target.call(WEAPON_MODIFIER_METHOD, &"meta_weapon", {
			&"damage_add": float(weapon_level - 1) * 0.5,
		})
	if equipment_target != null and equipment_target.has_method(ARMOR_LEVEL_METHOD):
		equipment_target.call(ARMOR_LEVEL_METHOD, int(levels[&"armor"]))


func required_experience(target_id: StringName) -> int:
	var current_level := maxi(1, int(levels.get(target_id, 1)))
	return 3 + (current_level - 1) * 2


func get_snapshot() -> Dictionary:
	var required: Dictionary = {}
	for target_id in TARGET_IDS:
		required[target_id] = required_experience(target_id)
	return {
		&"levels": levels.duplicate(true),
		&"experience": experience.duplicate(true),
		&"required_experience": required,
	}


func get_summary_line(gained: Dictionary = {}) -> String:
	return "외부 성장 · 캐릭터 Lv.%d (+%d) · 무기 Lv.%d (+%d) · 방어구 Lv.%d (+%d)" % [
		int(levels[&"character"]),
		int(gained.get(&"character", 0)),
		int(levels[&"weapon"]),
		int(gained.get(&"weapon", 0)),
		int(levels[&"armor"]),
		int(gained.get(&"armor", 0)),
	]


func reset_progress(delete_storage: bool = false) -> void:
	_reset_values()
	if delete_storage and FileAccess.file_exists(storage_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(storage_path))
	meta_progress_changed.emit(get_snapshot())


func _reset_values() -> void:
	levels = {&"character": 1, &"weapon": 1, &"armor": 1}
	experience = {&"character": 0, &"weapon": 0, &"armor": 0}


func _save() -> void:
	if safe_persistence:
		if not storage_error.is_empty(): return
		if not save_store.write(storage_path, {"levels": levels, "experience": experience}, true):
			storage_error = save_store.last_error
		return
	var file := FileAccess.open(storage_path, FileAccess.WRITE)
	if file == null:
		push_warning("외부 성장 저장 파일을 열 수 없습니다: %s" % storage_path)
		return
	file.store_string(JSON.stringify({
		"levels": _string_key_dictionary(levels),
		"experience": _string_key_dictionary(experience),
	}))


func _load() -> void:
	var parsed: Variant
	if safe_persistence:
		var stored: Dictionary = save_store.read(storage_path, true)
		if not stored.ok:
			storage_error = "외부 성장 복원 실패 · 원본 보존"
			return
		if stored.status == "new": return
		parsed = stored.data
	else:
		if not FileAccess.file_exists(storage_path): return
		var file := FileAccess.open(storage_path, FileAccess.READ)
		parsed = JSON.parse_string(file.get_as_text()) if file != null else null
	if not parsed is Dictionary:
		push_warning("외부 성장 저장 데이터 형식이 올바르지 않습니다.")
		return
	for key in ["levels", "experience"]:
		if not parsed.get(key, {}) is Dictionary:
			storage_error = "외부 성장 저장 형식 오류"
			return
		for value in parsed.get(key, {}).values():
			if not (value is float or value is int):
				storage_error = "외부 성장 저장 수치 오류"
				return
	var parsed_levels: Dictionary = parsed.get("levels", {})
	var parsed_experience: Dictionary = parsed.get("experience", {})
	for target_id in TARGET_IDS:
		var key := String(target_id)
		levels[target_id] = maxi(1, int(parsed_levels.get(key, 1)))
		experience[target_id] = maxi(0, int(parsed_experience.get(key, 0)))


func get_storage_status() -> Dictionary:
	return {"ok": storage_error.is_empty(), "message": storage_error, "path": storage_path}


func _string_key_dictionary(source: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for key in source:
		result[String(key)] = source[key]
	return result
