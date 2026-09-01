class_name LootLifecycleService
extends Node

signal lifecycle_updated(snapshot: Dictionary, source_label: String)
signal lifecycle_error(message: String)

@onready var http_request: HTTPRequest = $HTTPRequest

var config: LootLifecycleConfig
var definitions: Dictionary = {}
var current_source_label := ""
var refresh_remaining := 0.0
var request_in_flight := false


func _ready() -> void:
	http_request.request_completed.connect(_on_request_completed)


func configure(new_config: LootLifecycleConfig) -> bool:
	if new_config == null:
		return false
	config = new_config.duplicate(true) as LootLifecycleConfig
	var errors := config.validation_errors()
	if not errors.is_empty():
		lifecycle_error.emit(" / ".join(errors))
		return false
	var locked_loaded := _load_locked_csv()
	if config.source_mode == LootLifecycleConfig.SourceMode.LIVE_GOOGLE_SHEET:
		request_live_catalog()
	return locked_loaded


func _process(delta: float) -> void:
	if config == null or config.source_mode != LootLifecycleConfig.SourceMode.LIVE_GOOGLE_SHEET:
		return
	refresh_remaining -= delta
	if refresh_remaining <= 0.0 and not request_in_flight:
		request_live_catalog()


func request_live_catalog() -> bool:
	if config == null or config.live_csv_url.is_empty() or request_in_flight:
		return false
	var separator := "&" if "?" in config.live_csv_url else "?"
	var url := "%s%ssfh_cache=%d" % [config.live_csv_url, separator, int(Time.get_unix_time_from_system())]
	request_in_flight = http_request.request(url) == OK
	refresh_remaining = config.live_refresh_seconds
	return request_in_flight


func load_csv_text(csv_text: String, source_label: String) -> bool:
	var parsed := LootLifecycleTable.parse(csv_text)
	var errors: PackedStringArray = parsed[&"errors"]
	if not errors.is_empty():
		lifecycle_error.emit(" / ".join(errors))
		return false
	var parsed_data: Dictionary = parsed[&"data"]
	if parsed_data.is_empty():
		lifecycle_error.emit("유효한 전리품 생명 주기 행이 없습니다.")
		return false
	definitions = parsed_data
	current_source_label = source_label
	lifecycle_updated.emit(get_snapshot(), current_source_label)
	return true


func get_definition(item_id: StringName) -> LootLifecycleDefinition:
	return definitions.get(item_id) as LootLifecycleDefinition


func get_snapshot() -> Dictionary:
	var snapshot: Dictionary = {}
	for item_id in definitions:
		snapshot[item_id] = (definitions[item_id] as LootLifecycleDefinition).to_snapshot()
	return snapshot


func get_for_region(region_id: StringName) -> Array[LootLifecycleDefinition]:
	var result: Array[LootLifecycleDefinition] = []
	for definition_value in definitions.values():
		var definition := definition_value as LootLifecycleDefinition
		if "global" in definition.region_tags or String(region_id) in definition.region_tags:
			result.append(definition)
	return result


func resolve_outcome(item_id: StringName, extracted: bool) -> Dictionary:
	var definition := get_definition(item_id)
	if definition == null:
		return {}
	var result_id := definition.extract_result if extracted else definition.death_result
	return {
		&"item_id": item_id,
		&"loot_family": definition.loot_family,
		&"result": result_id,
		&"credit_value": definition.convert_value if result_id == &"auto_convert" else 0,
		&"retained": result_id != &"lost",
	}


func _load_locked_csv() -> bool:
	var csv_text := _read_locked_text(config.locked_csv_path, config.locked_csv_payload)
	if csv_text.is_empty():
		lifecycle_error.emit("확정 Item CSV를 찾을 수 없습니다.")
		return false
	return load_csv_text(csv_text, "확정 CSV")


func _read_locked_text(path: String, payload: Resource) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	if file != null:
		return file.get_as_text()
	if payload != null and payload.call(&"is_valid_for", path):
		return String(payload.call(&"get_csv_text"))
	return ""


func _on_request_completed(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	request_in_flight = false
	if response_code < 200 or response_code >= 300:
		lifecycle_error.emit("Item Sheet CSV 요청 실패: HTTP %d" % response_code)
		if definitions.is_empty() and config.fallback_to_locked_csv:
			_load_locked_csv()
		return
	if not load_csv_text(body.get_string_from_utf8(), "Google Sheets 실시간"):
		if definitions.is_empty() and config.fallback_to_locked_csv:
			_load_locked_csv()
