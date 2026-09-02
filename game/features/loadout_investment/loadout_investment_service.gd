class_name LoadoutInvestmentService
extends Node

signal catalog_updated(snapshot: Dictionary, source_label: String)
signal selection_changed(snapshot: Dictionary)
signal catalog_error(message: String)

@onready var weapon_request: HTTPRequest = $WeaponHTTPRequest
@onready var skill_request: HTTPRequest = $SkillHTTPRequest

var config: LoadoutInvestmentConfig
var profile: Node
var weapon_entries: Array[LoadoutInvestmentEntry] = []
var skill_entries: Array[LoadoutInvestmentEntry] = []
var selected_weapon_ids := {&"main": &"", &"secondary": &""}
var selected_skill_ids: Dictionary = {}
var source_label := ""
var active_run_id: StringName
var refresh_remaining := 0.0
var pending_live_text := {}


func _ready() -> void:
	weapon_request.request_completed.connect(_on_live_request_completed.bind(&"weapon"))
	skill_request.request_completed.connect(_on_live_request_completed.bind(&"skill"))


func configure(new_config: LoadoutInvestmentConfig, new_profile: Node) -> bool:
	if new_config == null or not is_instance_valid(new_profile) or not new_profile.has_method(&"is_unlocked"):
		return false
	config = new_config.duplicate(true) as LoadoutInvestmentConfig
	profile = new_profile
	var errors := config.validation_errors()
	if not errors.is_empty():
		catalog_error.emit(" / ".join(errors))
		return false
	var loaded := _load_locked_csv()
	if loaded and config.source_mode == LoadoutInvestmentConfig.SourceMode.LIVE_GOOGLE_SHEET:
		request_live_catalog()
	return loaded


func _process(delta: float) -> void:
	if config == null or config.source_mode != LoadoutInvestmentConfig.SourceMode.LIVE_GOOGLE_SHEET:
		return
	refresh_remaining -= delta
	if refresh_remaining <= 0.0 and not _request_in_flight():
		request_live_catalog()


func request_live_catalog() -> bool:
	if config == null or _request_in_flight():
		return false
	pending_live_text.clear()
	var cache := int(Time.get_unix_time_from_system())
	var weapon_error := weapon_request.request(_cache_url(config.live_weapon_csv_url, cache))
	var skill_error := skill_request.request(_cache_url(config.live_skill_csv_url, cache))
	refresh_remaining = config.live_refresh_seconds
	return weapon_error == OK and skill_error == OK


func load_catalog_text(weapon_csv: String, skill_csv: String, new_source_label: String) -> bool:
	var weapons := _parse_sheet_or_locked(weapon_csv, &"weapon")
	var skills := _parse_sheet_or_locked(skill_csv, &"skill")
	var errors := PackedStringArray()
	errors.append_array(weapons[&"errors"])
	errors.append_array(skills[&"errors"])
	if not errors.is_empty() or weapons[&"entries"].is_empty() or skills[&"entries"].is_empty():
		catalog_error.emit(" / ".join(errors) if not errors.is_empty() else "활성 투자 항목이 없습니다.")
		return false
	var previous_weapons := selected_weapon_ids.duplicate()
	var previous_skills := selected_skill_ids.duplicate()
	weapon_entries.clear()
	for entry in weapons[&"entries"]:
		weapon_entries.append(entry)
	skill_entries.clear()
	for entry in skills[&"entries"]:
		skill_entries.append(entry)
	_restore_or_select_defaults(previous_weapons, previous_skills)
	source_label = new_source_label
	catalog_updated.emit(get_snapshot(), source_label)
	selection_changed.emit(get_snapshot())
	return true


func cycle_weapon(slot_id: StringName, direction: int = 1) -> Dictionary:
	var candidates := _entries_for_slot(weapon_entries, slot_id)
	if candidates.is_empty():
		return {}
	var current := StringName(selected_weapon_ids.get(slot_id, &""))
	var index := 0
	for candidate_index in candidates.size():
		if candidates[candidate_index].item_id == current:
			index = candidate_index
			break
	selected_weapon_ids[slot_id] = candidates[posmod(index + signi(direction), candidates.size())].item_id
	selection_changed.emit(get_snapshot())
	return get_snapshot()


func cycle_skill(slot_index: int, direction: int = 1) -> Dictionary:
	var slot_id := StringName("skill_%d" % slot_index)
	var candidates := _entries_for_slot(skill_entries, slot_id)
	if candidates.is_empty():
		return {}
	var current := StringName(selected_skill_ids.get(slot_index, &""))
	var index := 0
	for candidate_index in candidates.size():
		if candidates[candidate_index].item_id == current:
			index = candidate_index
			break
	selected_skill_ids[slot_index] = candidates[posmod(index + signi(direction), candidates.size())].item_id
	selection_changed.emit(get_snapshot())
	return get_snapshot()


func select_weapon(slot_id: StringName, item_id: StringName) -> bool:
	var entry := _find_entry(weapon_entries, item_id)
	if entry == null or entry.slot_id != slot_id:
		return false
	selected_weapon_ids[slot_id] = item_id
	selection_changed.emit(get_snapshot())
	return true


func select_skill(slot_index: int, item_id: StringName) -> bool:
	var entry := _find_entry(skill_entries, item_id)
	if entry == null or entry.slot_id != StringName("skill_%d" % slot_index):
		return false
	selected_skill_ids[slot_index] = item_id
	selection_changed.emit(get_snapshot())
	return true


func can_launch() -> bool:
	return get_selection_errors().is_empty()


func get_selection_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	var selected := _selected_entries()
	for entry in selected:
		var snapshot := entry.to_snapshot(profile, not active_run_id.is_empty())
		if not bool(snapshot[&"unlocked"]):
			errors.append("%s 미해금" % entry.display_name)
	var selected_weapons: Array[Resource] = []
	for slot_id in [&"main", &"secondary"]:
		var entry := _find_entry(weapon_entries, selected_weapon_ids.get(slot_id, &""))
		if entry != null:
			selected_weapons.append(load(entry.definition_path))
	for slot_index in selected_skill_ids:
		var entry := _find_entry(skill_entries, selected_skill_ids[slot_index])
		if entry == null:
			continue
		var skill: Resource = load(entry.definition_path)
		var required: Array = skill.get("required_combat_tags")
		if not required.is_empty() and not selected_weapons.any(func(weapon): return _weapon_has_tags(weapon, required)):
			errors.append("%s 무기 태그 불일치" % entry.display_name)
	return errors


func get_investment_context() -> Dictionary:
	var weapon_paths := {}
	var skill_paths := {}
	var total := 0
	var selected_snapshots: Array[Dictionary] = []
	for entry in _selected_entries():
		var snapshot := entry.to_snapshot(profile, not active_run_id.is_empty())
		selected_snapshots.append(snapshot)
		if not entry.default_owned:
			total += entry.run_investment_price
		if entry.item_kind == &"weapon":
			weapon_paths[entry.slot_id] = entry.definition_path
		else:
			skill_paths[int(String(entry.slot_id).trim_prefix("skill_"))] = entry.definition_path
	return {
		&"additional_entry_cost": total,
		&"weapon_paths": weapon_paths, &"skill_paths": skill_paths,
		&"selected_items": selected_snapshots, &"selection_ready": can_launch(),
		&"selection_errors": get_selection_errors(), &"source_label": source_label,
	}


func get_operation_setting_contribution() -> Dictionary:
	var context := get_investment_context()
	context[&"equipment_override_policy"] = &"replace_selected_slot_restore_hub_state"
	return {
		&"contributor_id": &"loadout_investment",
		&"context_key": &"loadout_investment",
		&"additional_entry_cost": int(context.get(&"additional_entry_cost", 0)),
		&"context": context,
		&"validation_errors": get_selection_errors(),
		&"revision": source_label,
	}


func commit_run_purchase(run_id: StringName) -> bool:
	if run_id == &"" or not can_launch() or not active_run_id.is_empty():
		return false
	active_run_id = run_id
	selection_changed.emit(get_snapshot())
	return true


func finish_run() -> void:
	if active_run_id.is_empty():
		return
	active_run_id = &""
	selection_changed.emit(get_snapshot())


func get_snapshot() -> Dictionary:
	var context := get_investment_context()
	var weapons := {}
	for slot_id in [&"main", &"secondary"]:
		var entry := _find_entry(weapon_entries, selected_weapon_ids.get(slot_id, &""))
		weapons[slot_id] = entry.to_snapshot(profile, not active_run_id.is_empty()) if entry != null else {}
	var skills: Array[Dictionary] = []
	var slots := selected_skill_ids.keys()
	slots.sort()
	for slot_index in slots:
		var entry := _find_entry(skill_entries, selected_skill_ids[slot_index])
		if entry != null:
			var snapshot := entry.to_snapshot(profile, not active_run_id.is_empty())
			snapshot[&"slot_index"] = slot_index
			skills.append(snapshot)
	return {
		&"configured": config != null, &"source_label": source_label,
		&"weapon_count": weapon_entries.size(), &"skill_count": skill_entries.size(),
		&"weapons": weapons, &"skills": skills,
		&"additional_entry_cost": context[&"additional_entry_cost"],
		&"selection_ready": context[&"selection_ready"],
		&"selection_errors": context[&"selection_errors"],
		&"active_run_id": active_run_id,
	}


func _load_locked_csv() -> bool:
	var weapon_text := _read_csv(config.weapon_csv_path, config.weapon_csv_payload)
	var skill_text := _read_csv(config.skill_csv_path, config.skill_csv_payload)
	if weapon_text.is_empty() or skill_text.is_empty():
		catalog_error.emit("확정 Weapon·Skill 투자 CSV를 찾을 수 없습니다.")
		return false
	return load_catalog_text(weapon_text, skill_text, "확정 CSV")


func _read_csv(path: String, payload: Resource) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	var text := file.get_as_text() if file != null else ""
	if text.is_empty() and payload != null and payload.call(&"is_valid_for", path):
		text = String(payload.call(&"get_csv_text"))
	return text


func _parse_sheet_or_locked(text: String, kind: StringName) -> Dictionary:
	if "item_id,display_name,slot_id,resource_path" in text:
		return LoadoutInvestmentTable.parse(text, kind)
	return _extract_sheet_rows(text, kind)


func _extract_sheet_rows(text: String, kind: StringName) -> Dictionary:
	var matrix: Array[PackedStringArray] = []
	for line in text.replace("\r\n", "\n").replace("\r", "\n").split("\n", false):
		if not line.strip_edges().is_empty():
			matrix.append(LoadoutInvestmentTable._parse_csv_line(line))
	if matrix.size() < 3:
		return {&"entries": [], &"errors": PackedStringArray(["%s Sheet가 비어 있습니다." % kind])}
	var headers := matrix[0]
	var id_column := "weapon_id" if kind == &"weapon" else "skill_id"
	var required := [id_column, "display_name", "runtime_enabled", "run_investment_price", "default_owned", "required_unlock_id", "investment_source_status"]
	if kind == &"weapon": required.append("allowed_slots")
	else: required.append("target_slot_index")
	for column in required:
		if column not in headers:
			return {&"entries": [], &"errors": PackedStringArray(["%s Sheet 필수 열 누락: %s" % [kind, column]])}
	var csv_lines := PackedStringArray(["item_id,display_name,slot_id,resource_path,run_investment_price,default_owned,required_unlock_id,source_status"])
	for row_index in range(2, matrix.size()):
		var row := LoadoutInvestmentTable._to_row(headers, matrix[row_index])
		if row[&"runtime_enabled"].to_lower() not in ["true", "1", "yes", "y", "on"]:
			continue
		var item_id: String = String(row[StringName(id_column)])
		var slot_id: String = String(row[&"allowed_slots"]) if kind == &"weapon" else "skill_%d" % int(row[&"target_slot_index"])
		var path := (
			"res://game/features/equipment/definitions/weapons/%s.tres" % item_id
			if kind == &"weapon" else
			"res://game/features/combat_skills/definitions/%s.tres" % item_id
		)
		csv_lines.append(",".join([
			item_id, row[&"display_name"], slot_id, path, row[&"run_investment_price"],
			row[&"default_owned"], row[&"required_unlock_id"], row[&"investment_source_status"],
		]))
	return LoadoutInvestmentTable.parse("\n".join(csv_lines), kind)


func _restore_or_select_defaults(previous_weapons: Dictionary, previous_skills: Dictionary) -> void:
	for slot_id in [&"main", &"secondary"]:
		var previous := StringName(previous_weapons.get(slot_id, &""))
		var entry := _find_entry(weapon_entries, previous)
		if entry == null or entry.slot_id != slot_id:
			var candidates := _entries_for_slot(weapon_entries, slot_id)
			previous = candidates[0].item_id if not candidates.is_empty() else &""
		selected_weapon_ids[slot_id] = previous
	selected_skill_ids.clear()
	var skill_slots := {}
	for entry in skill_entries:
		skill_slots[int(String(entry.slot_id).trim_prefix("skill_"))] = true
	for slot_index in skill_slots:
		var previous := StringName(previous_skills.get(slot_index, &""))
		var entry := _find_entry(skill_entries, previous)
		if entry == null or entry.slot_id != StringName("skill_%d" % slot_index):
			var candidates := _entries_for_slot(skill_entries, StringName("skill_%d" % slot_index))
			previous = candidates[0].item_id if not candidates.is_empty() else &""
		selected_skill_ids[slot_index] = previous


func _selected_entries() -> Array[LoadoutInvestmentEntry]:
	var result: Array[LoadoutInvestmentEntry] = []
	for slot_id in [&"main", &"secondary"]:
		var entry := _find_entry(weapon_entries, selected_weapon_ids.get(slot_id, &""))
		if entry != null: result.append(entry)
	for slot_index in selected_skill_ids:
		var entry := _find_entry(skill_entries, selected_skill_ids[slot_index])
		if entry != null: result.append(entry)
	return result


func _entries_for_slot(entries: Array[LoadoutInvestmentEntry], slot_id: StringName) -> Array[LoadoutInvestmentEntry]:
	return entries.filter(func(entry): return entry.slot_id == slot_id)


func _find_entry(entries: Array[LoadoutInvestmentEntry], item_id: StringName) -> LoadoutInvestmentEntry:
	for entry in entries:
		if entry.item_id == item_id: return entry
	return null


func _weapon_has_tags(weapon: Resource, required: Array) -> bool:
	if weapon == null: return false
	var tags: Array = weapon.get("combat_tags")
	return required.all(func(tag): return StringName(tag) in tags)


func _cache_url(url: String, cache: int) -> String:
	return "%s%ssfh_cache=%d" % [url, "&" if "?" in url else "?", cache]


func _request_in_flight() -> bool:
	return weapon_request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED or skill_request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED


func _on_live_request_completed(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray, kind: StringName) -> void:
	if response_code < 200 or response_code >= 300:
		catalog_error.emit("%s 투자 Sheet 요청 실패: HTTP %d" % [kind, response_code])
		return
	pending_live_text[kind] = body.get_string_from_utf8()
	if pending_live_text.has(&"weapon") and pending_live_text.has(&"skill"):
		load_catalog_text(pending_live_text[&"weapon"], pending_live_text[&"skill"], "Google Sheets 실시간")
