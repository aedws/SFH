class_name CharacterSelectionService
extends Node

signal catalog_updated(snapshot: Dictionary, source_label: String)
signal selection_changed(snapshot: Dictionary)
signal catalog_error(message: String)

@onready var http_request: HTTPRequest = $HTTPRequest

var config: CharacterSelectionConfig
var definitions: Array[CharacterDefinition] = []
var selected_index := 0
var source_label := ""
var refresh_remaining := 0.0
var request_in_flight := false


func _ready() -> void:
	http_request.request_completed.connect(_on_request_completed)


func configure(new_config: CharacterSelectionConfig) -> bool:
	if new_config == null:
		return false
	config = new_config.duplicate(true) as CharacterSelectionConfig
	var errors := config.validation_errors()
	if not errors.is_empty():
		catalog_error.emit(" / ".join(errors))
		return false
	var loaded := _load_locked_csv()
	if config.source_mode == CharacterSelectionConfig.SourceMode.LIVE_GOOGLE_SHEET:
		request_live_catalog()
	return loaded


func _process(delta: float) -> void:
	if config == null or config.source_mode != CharacterSelectionConfig.SourceMode.LIVE_GOOGLE_SHEET:
		return
	refresh_remaining -= delta
	if refresh_remaining <= 0.0 and not request_in_flight:
		request_live_catalog()


func request_live_catalog() -> bool:
	if config == null or config.live_csv_url.is_empty() or request_in_flight:
		return false
	var separator := "&" if "?" in config.live_csv_url else "?"
	request_in_flight = http_request.request("%s%ssfh_cache=%d" % [config.live_csv_url, separator, int(Time.get_unix_time_from_system())]) == OK
	refresh_remaining = config.live_refresh_seconds
	return request_in_flight


func load_csv_text(csv_text: String, new_source_label: String) -> bool:
	var parsed := CharacterTable.parse(csv_text)
	var errors: PackedStringArray = parsed[&"errors"]
	var next_definitions: Array = parsed[&"definitions"]
	if not errors.is_empty() or next_definitions.is_empty():
		catalog_error.emit(" / ".join(errors) if not errors.is_empty() else "활성 캐릭터가 없습니다.")
		return false
	var selected_id: StringName = StringName(get_snapshot().get(&"character_id", &""))
	definitions.clear()
	for definition in next_definitions:
		definitions.append(definition as CharacterDefinition)
	selected_index = 0
	for index in definitions.size():
		if definitions[index].character_id == selected_id:
			selected_index = index
			break
	source_label = new_source_label
	catalog_updated.emit(get_snapshot(), source_label)
	selection_changed.emit(get_snapshot())
	return true


func cycle_character(direction: int = 1) -> Dictionary:
	if definitions.is_empty():
		return {}
	selected_index = posmod(selected_index + signi(direction), definitions.size())
	selection_changed.emit(get_snapshot())
	return get_snapshot()


func select_character(character_id: StringName) -> bool:
	for index in definitions.size():
		if definitions[index].character_id == character_id:
			selected_index = index
			selection_changed.emit(get_snapshot())
			return true
	return false


func get_investment_context() -> Dictionary:
	if definitions.is_empty():
		return {}
	var selected := definitions[selected_index]
	return {
		&"additional_entry_cost": selected.entry_cost,
		&"label": selected.display_name,
		&"character_id": selected.character_id,
		&"character_name": selected.display_name,
		&"passive_id": selected.passive_id,
		&"passive_name": selected.passive_name,
		&"passive_description": selected.passive_description,
		&"player_runtime_modifiers": selected.runtime_modifiers(),
		&"source_status": selected.source_status,
	}


func get_operation_setting_contribution() -> Dictionary:
	var context := get_investment_context()
	var errors := PackedStringArray()
	if definitions.is_empty():
		errors.append("선택 가능한 요원이 없습니다.")
	return {
		&"contributor_id": &"character",
		&"context_key": &"",
		&"additional_entry_cost": int(context.get(&"additional_entry_cost", 0)),
		&"context": context,
		&"validation_errors": errors,
		&"revision": source_label,
	}


func get_snapshot() -> Dictionary:
	if definitions.is_empty():
		return {&"count": 0, &"source_label": source_label}
	var result := definitions[selected_index].to_snapshot()
	result[&"count"] = definitions.size()
	result[&"selected_index"] = selected_index
	result[&"source_label"] = source_label
	return result


func _load_locked_csv() -> bool:
	var file := FileAccess.open(config.locked_csv_path, FileAccess.READ)
	var text := file.get_as_text() if file != null else ""
	if text.is_empty() and config.locked_csv_payload != null and config.locked_csv_payload.call(&"is_valid_for", config.locked_csv_path):
		text = String(config.locked_csv_payload.call(&"get_csv_text"))
	if text.is_empty():
		catalog_error.emit("확정 Character CSV를 찾을 수 없습니다.")
		return false
	return load_csv_text(text, "확정 CSV")


func _on_request_completed(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	request_in_flight = false
	if response_code < 200 or response_code >= 300:
		catalog_error.emit("Character Sheet CSV 요청 실패: HTTP %d" % response_code)
		return
	load_csv_text(body.get_string_from_utf8(), "Google Sheets 실시간")
