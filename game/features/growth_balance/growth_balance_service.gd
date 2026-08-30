class_name GrowthBalanceService
extends Node

const CONFIG_SCRIPT = preload("res://game/features/growth_balance/growth_balance_config.gd")
const TABLE_SCRIPT = preload("res://game/features/growth_balance/growth_balance_table.gd")

signal growth_balance_updated(snapshot: Dictionary, source_label: String)
signal growth_balance_error(message: String)

@onready var run_buff_request: HTTPRequest = $RunBuffRequest
@onready var upgrade_request: HTTPRequest = $UpgradeRequest

var config: Resource
var run_buff_rows: Dictionary = {}
var upgrade_rows: Dictionary = {}
var current_source_label: String = ""
var refresh_remaining: float = 0.0
var run_buff_request_in_flight: bool = false
var upgrade_request_in_flight: bool = false


func _ready() -> void:
	run_buff_request.request_completed.connect(_on_run_buff_request_completed)
	upgrade_request.request_completed.connect(_on_upgrade_request_completed)


func configure(new_config: Resource) -> bool:
	if new_config == null:
		return false
	config = new_config.duplicate(true)
	var errors: PackedStringArray = config.call(&"validation_errors")
	if not errors.is_empty():
		growth_balance_error.emit(" / ".join(errors))
		return false
	var locked_loaded := _load_locked_csvs()
	if config.get("source_mode") == CONFIG_SCRIPT.SourceMode.LIVE_GOOGLE_SHEET:
		request_live_balance()
	return locked_loaded


func _process(delta: float) -> void:
	if config == null or config.get("source_mode") != CONFIG_SCRIPT.SourceMode.LIVE_GOOGLE_SHEET:
		return
	refresh_remaining -= delta
	if (
		refresh_remaining <= 0.0
		and not run_buff_request_in_flight
		and not upgrade_request_in_flight
	):
		request_live_balance()


func request_live_balance() -> bool:
	if config == null or run_buff_request_in_flight or upgrade_request_in_flight:
		return false
	if config.live_run_buff_csv_url.is_empty() or config.live_upgrade_csv_url.is_empty():
		return false
	var cache_value := int(Time.get_unix_time_from_system())
	run_buff_request_in_flight = run_buff_request.request(
		_cache_busted_url(config.live_run_buff_csv_url, cache_value)
	) == OK
	upgrade_request_in_flight = upgrade_request.request(
		_cache_busted_url(config.live_upgrade_csv_url, cache_value)
	) == OK
	refresh_remaining = config.live_refresh_seconds
	return run_buff_request_in_flight and upgrade_request_in_flight


func load_run_buff_csv_text(csv_text: String, source_label: String) -> bool:
	var parsed := TABLE_SCRIPT.parse_run_buffs(csv_text)
	var errors: PackedStringArray = parsed[&"errors"]
	if not errors.is_empty():
		growth_balance_error.emit(" / ".join(errors))
		return false
	var data: Dictionary = parsed[&"data"]
	if data.is_empty():
		growth_balance_error.emit("유효한 내부 성장 선택지가 없습니다.")
		return false
	run_buff_rows = data
	current_source_label = source_label
	_emit_updated()
	return true


func load_upgrade_csv_text(csv_text: String, source_label: String) -> bool:
	var parsed := TABLE_SCRIPT.parse_upgrades(csv_text)
	var errors: PackedStringArray = parsed[&"errors"]
	if not errors.is_empty():
		growth_balance_error.emit(" / ".join(errors))
		return false
	var data: Dictionary = parsed[&"data"]
	if data.is_empty():
		growth_balance_error.emit("유효한 장비 강화 스펙이 없습니다.")
		return false
	upgrade_rows = data
	current_source_label = source_label
	_emit_updated()
	return true


func get_run_buff_catalog() -> RunBuffCatalog:
	var catalog := RunBuffCatalog.new()
	for buff_id in run_buff_rows:
		var row: Dictionary = run_buff_rows[buff_id]
		var buff := RunBuffDefinition.new()
		buff.buff_id = row[&"buff_id"]
		buff.display_name = row[&"display_name"]
		buff.description = row[&"description"]
		buff.maximum_stacks = row[&"maximum_stacks"]
		buff.meta_target = _meta_target_value(row[&"meta_target"])
		buff.heal_on_apply = row[&"heal_on_apply"]
		buff.player_modifiers = _run_buff_player_modifiers(row)
		buff.weapon_modifiers = _run_buff_weapon_modifiers(row)
		catalog.buffs.append(buff)
	return catalog


func get_upgrade_spec(
	target_kind: StringName,
	target_id: StringName,
	level: int
) -> Dictionary:
	var key := TABLE_SCRIPT.upgrade_key(target_kind, target_id, level)
	if upgrade_rows.has(key):
		return (upgrade_rows[key] as Dictionary).duplicate(true)
	var fallback_key := TABLE_SCRIPT.upgrade_key(target_kind, &"*", level)
	return (upgrade_rows.get(fallback_key, {}) as Dictionary).duplicate(true)


func get_maximum_level(
	target_kind: StringName,
	target_id: StringName,
	fallback: int
) -> int:
	var result := maxi(1, fallback)
	for row in upgrade_rows.values():
		if row[&"target_kind"] != target_kind:
			continue
		if row[&"target_id"] not in [target_id, &"*"]:
			continue
		result = maxi(result, int(row[&"maximum_level"]))
	return result


func get_module_capacity_cost(module_id: StringName, level: int, fallback: int) -> int:
	var spec := get_upgrade_spec(&"module", module_id, level)
	return int(spec.get(&"module_capacity_cost", fallback)) if not spec.is_empty() else fallback


func quote_upgrade(
	target_kind: StringName,
	target_id: StringName,
	current_level: int
) -> Dictionary:
	var spec := get_upgrade_spec(target_kind, target_id, current_level)
	if spec.is_empty():
		return {}
	return {
		&"credit_cost": int(spec[&"credit_cost"]),
		&"material_quantity": int(spec[&"material_quantity"]),
		&"source_label": current_source_label,
	}


func get_player_modifiers(
	target_kind: StringName,
	target_id: StringName,
	level: int
) -> Dictionary:
	var spec := get_upgrade_spec(target_kind, target_id, level)
	var stat_id: StringName = spec.get(&"player_stat_id", &"")
	if stat_id == &"":
		return {}
	return {
		stat_id: {
			&"add": float(spec.get(&"player_stat_add", 0.0)),
			&"multiply": float(spec.get(&"player_stat_multiply", 1.0)),
		},
	}


func get_weapon_modifiers(
	target_kind: StringName,
	target_id: StringName,
	level: int
) -> Dictionary:
	var spec := get_upgrade_spec(target_kind, target_id, level)
	if spec.is_empty():
		return {}
	return {
		&"damage_add": float(spec.get(&"weapon_damage_add", 0.0)),
		&"damage_multiply": float(spec.get(&"weapon_damage_multiply", 1.0)),
		&"fire_interval_multiply": float(
			spec.get(&"weapon_fire_interval_multiply", 1.0)
		),
		&"target_range_multiply": float(
			spec.get(&"weapon_target_range_multiply", 1.0)
		),
	}


func get_snapshot() -> Dictionary:
	return {
		&"run_buff_count": run_buff_rows.size(),
		&"upgrade_spec_count": upgrade_rows.size(),
		&"source_label": current_source_label,
		&"run_buffs": run_buff_rows.duplicate(true),
		&"upgrades": upgrade_rows.duplicate(true),
	}


func _load_locked_csvs() -> bool:
	var run_buff_text := _read_file(config.locked_run_buff_csv_path)
	var upgrade_text := _read_file(config.locked_upgrade_csv_path)
	if run_buff_text.is_empty() or upgrade_text.is_empty():
		growth_balance_error.emit("확정 성장 밸런스 CSV를 찾을 수 없습니다.")
		return false
	var run_ok := load_run_buff_csv_text(run_buff_text, "확정 CSV")
	var upgrade_ok := load_upgrade_csv_text(upgrade_text, "확정 CSV")
	return run_ok and upgrade_ok


func _read_file(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	return file.get_as_text() if file != null else ""


func _emit_updated() -> void:
	if run_buff_rows.is_empty() or upgrade_rows.is_empty():
		return
	growth_balance_updated.emit(get_snapshot(), current_source_label)


func _on_run_buff_request_completed(
	_result: int,
	response_code: int,
	_headers: PackedStringArray,
	body: PackedByteArray
) -> void:
	run_buff_request_in_flight = false
	if response_code < 200 or response_code >= 300:
		_handle_live_error("RunBuff", response_code)
		return
	if not load_run_buff_csv_text(body.get_string_from_utf8(), "Google Sheets 실시간"):
		_fallback_if_empty()


func _on_upgrade_request_completed(
	_result: int,
	response_code: int,
	_headers: PackedStringArray,
	body: PackedByteArray
) -> void:
	upgrade_request_in_flight = false
	if response_code < 200 or response_code >= 300:
		_handle_live_error("Upgrade", response_code)
		return
	if not load_upgrade_csv_text(body.get_string_from_utf8(), "Google Sheets 실시간"):
		_fallback_if_empty()


func _handle_live_error(tab_name: String, response_code: int) -> void:
	growth_balance_error.emit("%s Google Sheets CSV 요청 실패: HTTP %d" % [tab_name, response_code])
	_fallback_if_empty()


func _fallback_if_empty() -> void:
	if config.fallback_to_locked_csv and (run_buff_rows.is_empty() or upgrade_rows.is_empty()):
		_load_locked_csvs()


func _cache_busted_url(url: String, cache_value: int) -> String:
	var separator := "&" if "?" in url else "?"
	return "%s%ssfh_cache=%d" % [url, separator, cache_value]


func _meta_target_value(target_id: StringName) -> RunBuffDefinition.MetaTarget:
	if target_id == &"weapon":
		return RunBuffDefinition.MetaTarget.WEAPON
	if target_id == &"armor":
		return RunBuffDefinition.MetaTarget.ARMOR
	return RunBuffDefinition.MetaTarget.CHARACTER


func _run_buff_player_modifiers(row: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	_append_player_modifier(result, &"max_health", row[&"max_health_add"], 1.0)
	_append_player_modifier(result, &"defense", row[&"defense_add"], 1.0)
	_append_player_modifier(
		result,
		&"movement_speed",
		row[&"movement_speed_add"],
		row[&"movement_speed_multiply"]
	)
	return result


func _append_player_modifier(
	target: Dictionary,
	stat_id: StringName,
	add_value: float,
	multiply_value: float
) -> void:
	if not is_zero_approx(add_value) or not is_equal_approx(multiply_value, 1.0):
		target[stat_id] = {&"add": add_value, &"multiply": multiply_value}


func _run_buff_weapon_modifiers(row: Dictionary) -> Dictionary:
	var result := {
		&"damage_add": float(row[&"weapon_damage_add"]),
		&"damage_multiply": float(row[&"weapon_damage_multiply"]),
		&"fire_interval_multiply": float(row[&"fire_interval_multiply"]),
		&"target_range_multiply": float(row[&"target_range_multiply"]),
	}
	for key in result.keys():
		var neutral := 0.0 if key == &"damage_add" else 1.0
		if is_equal_approx(float(result[key]), neutral):
			result.erase(key)
	return result
