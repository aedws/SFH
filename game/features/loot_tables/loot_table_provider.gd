class_name LootTableProvider
extends Node

signal table_updated(snapshot: Dictionary, source_label: String)
signal table_error(message: String)

@onready var http_request: HTTPRequest = $HTTPRequest

var config: LootTableConfig
var lifecycle_provider: Node
var additional_definition_provider: Resource
var entries: Array[LootDropEntry] = []
var current_source_label := ""
var refresh_remaining := 0.0
var request_in_flight := false


func _ready() -> void:
	http_request.request_completed.connect(_on_request_completed)


func configure(
	new_config: LootTableConfig,
	new_lifecycle_provider: Node,
	new_additional_definition_provider: Resource = null
) -> bool:
	if new_config == null or not _supports_lifecycle_provider(new_lifecycle_provider):
		return false
	config = new_config.duplicate(true) as LootTableConfig
	lifecycle_provider = new_lifecycle_provider
	additional_definition_provider = new_additional_definition_provider
	if (
		additional_definition_provider != null
		and not additional_definition_provider.has_method(&"get_definition")
	):
		return false
	var errors := config.validation_errors()
	if not errors.is_empty():
		table_error.emit(" / ".join(errors))
		return false
	var locked_loaded := _load_locked_csv()
	if config.source_mode == LootTableConfig.SourceMode.LIVE_GOOGLE_SHEET:
		request_live_table()
	return locked_loaded


func _process(delta: float) -> void:
	if config == null or config.source_mode != LootTableConfig.SourceMode.LIVE_GOOGLE_SHEET:
		return
	refresh_remaining -= delta
	if refresh_remaining <= 0.0 and not request_in_flight:
		request_live_table()


func request_live_table() -> bool:
	if config == null or config.live_csv_url.is_empty() or request_in_flight:
		return false
	var separator := "&" if "?" in config.live_csv_url else "?"
	var url := "%s%ssfh_cache=%d" % [config.live_csv_url, separator, int(Time.get_unix_time_from_system())]
	request_in_flight = http_request.request(url) == OK
	refresh_remaining = config.live_refresh_seconds
	return request_in_flight


func load_csv_text(csv_text: String, source_label: String) -> bool:
	var parsed := LootTable.parse(csv_text)
	var errors: PackedStringArray = parsed[&"errors"]
	var parsed_entries: Array[LootDropEntry] = parsed[&"data"]
	for entry in parsed_entries:
		var definition := _definition_for(entry.item_id)
		if definition == null:
			errors.append(
				"%s: Item/Weapon 목록에 없는 item_id입니다: %s" % [entry.entry_id, entry.item_id]
			)
			continue
		var region_tags: PackedStringArray = definition.get("region_tags")
		if "global" not in region_tags and String(entry.region_id) not in region_tags:
			errors.append("%s: Item의 region_tags와 일치하지 않습니다." % entry.entry_id)
	if not errors.is_empty():
		table_error.emit(" / ".join(errors))
		return false
	if parsed_entries.is_empty():
		table_error.emit("유효한 드랍 테이블 행이 없습니다.")
		return false
	entries = parsed_entries
	current_source_label = source_label
	table_updated.emit(get_snapshot(), current_source_label)
	return true


func get_candidates(context: Dictionary) -> Array[Dictionary]:
	var multiplier := float(context.get(&"high_grade_drop_multiplier", 1.0))
	var result: Array[Dictionary] = []
	for entry in entries:
		if entry.matches(context):
			var requested_type := StringName(context.get(&"item_type", &""))
			if requested_type != &"":
				var definition := _definition_for(entry.item_id)
				if definition == null or definition.item_type != requested_type:
					continue
			result.append(entry.to_snapshot(multiplier))
	result.sort_custom(func(a: Dictionary, b: Dictionary): return float(a[&"effective_weight"]) > float(b[&"effective_weight"]))
	return result


func roll_drop(context: Dictionary, seed: int, roll_index: int = 0) -> Dictionary:
	var candidates := get_candidates(context)
	if candidates.is_empty():
		return {}
	var total_weight := 0.0
	for candidate in candidates:
		total_weight += float(candidate[&"effective_weight"])
	var rng := RandomNumberGenerator.new()
	rng.seed = _combined_seed(seed, context)
	for _index in range(maxi(0, roll_index)):
		rng.randf()
	var ticket := rng.randf_range(0.0, total_weight)
	var cursor := 0.0
	var selected: Dictionary = candidates.back().duplicate(true)
	for candidate in candidates:
		cursor += float(candidate[&"effective_weight"])
		if ticket <= cursor:
			selected = candidate.duplicate(true)
			break
	selected[&"quantity"] = rng.randi_range(
		int(selected[&"minimum_quantity"]), int(selected[&"maximum_quantity"])
	)
	selected[&"source_label"] = current_source_label
	return selected


func get_briefing(context: Dictionary) -> Dictionary:
	var candidates := get_candidates(context)
	var labels := PackedStringArray()
	var ids := PackedStringArray()
	var seen := {}
	var highest_grade := 0
	for candidate in candidates:
		highest_grade = maxi(highest_grade, int(candidate[&"grade"]))
		var item_id := StringName(candidate[&"item_id"])
		if seen.has(item_id) or labels.size() >= config.briefing_item_count:
			continue
		seen[item_id] = true
		ids.append(String(item_id))
		var definition := _definition_for(item_id)
		labels.append(String(definition.get("display_name")) if definition != null else String(item_id))
	return {
		&"candidate_count": candidates.size(),
		&"target_item_ids": ids,
		&"target_item_labels": labels,
		&"highest_grade": highest_grade,
		&"source_label": current_source_label,
	}


func get_snapshot() -> Dictionary:
	var by_region := {}
	for entry in entries:
		by_region[entry.region_id] = int(by_region.get(entry.region_id, 0)) + 1
	return {
		&"entry_count": entries.size(),
		&"by_region": by_region,
		&"source_label": current_source_label,
		&"lifecycle_linked": _supports_lifecycle_provider(lifecycle_provider),
		&"equipment_definition_linked": additional_definition_provider != null,
		&"deterministic_rolls": true,
	}


func _combined_seed(seed: int, context: Dictionary) -> int:
	var text := "%s|%s|%s|%s" % [
		context.get(&"region_id", ""), context.get(&"difficulty_id", "any"),
		context.get(&"map_size", "any"), context.get(&"source_type", "any"),
	]
	var stable_hash := 2166136261
	for byte in text.to_utf8_buffer():
		stable_hash = int((stable_hash ^ int(byte)) * 16777619) & 0x7fffffff
	return (seed ^ stable_hash) & 0x7fffffff


func _load_locked_csv() -> bool:
	var csv_text := _read_locked_text(config.locked_csv_path, config.locked_csv_payload)
	if csv_text.is_empty():
		table_error.emit("확정 LootTable CSV를 찾을 수 없습니다.")
		return false
	return load_csv_text(csv_text, "확정 CSV")


func _read_locked_text(path: String, payload: Resource) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	if file != null:
		return file.get_as_text()
	if payload != null and payload.call(&"is_valid_for", path):
		return String(payload.call(&"get_csv_text"))
	return ""


func _supports_lifecycle_provider(candidate: Node) -> bool:
	return is_instance_valid(candidate) and candidate.has_method(&"get_definition")


func _definition_for(item_id: StringName) -> Resource:
	var definition: Resource = lifecycle_provider.call(&"get_definition", item_id)
	if definition == null and additional_definition_provider != null:
		definition = additional_definition_provider.call(&"get_definition", item_id)
	return definition


func _on_request_completed(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	request_in_flight = false
	if response_code < 200 or response_code >= 300:
		table_error.emit("LootTable Sheet CSV 요청 실패: HTTP %d" % response_code)
		if entries.is_empty() and config.fallback_to_locked_csv:
			_load_locked_csv()
		return
	if not load_csv_text(body.get_string_from_utf8(), "Google Sheets 실시간"):
		if entries.is_empty() and config.fallback_to_locked_csv:
			_load_locked_csv()
