class_name SessionSocketService
extends Node

signal catalog_updated(snapshot: Dictionary, source_label: String)
signal sockets_changed(snapshot: Dictionary)
signal socket_action(result: Dictionary)
signal socket_error(message: String)

const MODIFIER_SOURCE := &"session_sockets"
const SOCKET_ORDER := [&"rune", &"core", &"artifact"]

@onready var http_request: HTTPRequest = $HTTPRequest

var config: SessionSocketConfig
var lifecycle_provider: Node
var weapon_target: Node
var skill_target: Node
var player_target: Node
var rules_by_item: Dictionary = {}
var capacities: Dictionary = {}
var equipped: Dictionary = {}
var source_label := ""
var sequence := 0
var refresh_remaining := 0.0
var request_in_flight := false
var last_action: Dictionary = {}


func _ready() -> void:
	http_request.request_completed.connect(_on_request_completed)


func configure(
	new_config: SessionSocketConfig,
	new_lifecycle_provider: Node,
	new_weapon_target: Node,
	new_skill_target: Node,
	new_player_target: Node
) -> bool:
	if (
		new_config == null
		or not _supports(new_lifecycle_provider, [&"get_definition"])
		or not _supports(new_weapon_target, [&"set_runtime_modifiers", &"remove_runtime_modifiers"])
		or not _supports(new_skill_target, [&"set_runtime_modifiers", &"remove_runtime_modifiers"])
		or not _supports(new_player_target, [&"set_runtime_modifier_source", &"remove_runtime_modifier_source"])
	):
		return false
	config = new_config.duplicate(true) as SessionSocketConfig
	var errors := config.validation_errors()
	if not errors.is_empty():
		socket_error.emit(" / ".join(errors))
		return false
	lifecycle_provider = new_lifecycle_provider
	weapon_target = new_weapon_target
	skill_target = new_skill_target
	player_target = new_player_target
	clear_run()
	var locked_loaded := _load_locked_csv()
	if config.source_mode == SessionSocketConfig.SourceMode.LIVE_GOOGLE_SHEET:
		request_live_catalog()
	return locked_loaded


func _process(delta: float) -> void:
	if config == null or config.source_mode != SessionSocketConfig.SourceMode.LIVE_GOOGLE_SHEET:
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


func load_csv_text(csv_text: String, new_source_label: String) -> bool:
	var parsed := SessionSocketTable.parse(csv_text)
	var errors: PackedStringArray = parsed[&"errors"]
	var rules: Array = parsed[&"rules"]
	if not errors.is_empty():
		socket_error.emit(" / ".join(errors))
		return false
	if rules.is_empty():
		socket_error.emit("활성 세션 소켓 규칙이 없습니다.")
		return false
	var next_rules: Dictionary = {}
	var next_capacities: Dictionary = {}
	for value in rules:
		var rule := value as SessionSocketRule
		var lifecycle = lifecycle_provider.call(&"get_definition", rule.item_id)
		if (
			lifecycle == null
			or StringName(lifecycle.get("loot_family")) != &"session_convertible"
			or StringName(lifecycle.get("session_behavior")) != &"session_socket"
			or StringName(lifecycle.get("item_type")) != rule.socket_type
		):
			socket_error.emit("%s 규칙이 Item 생명 주기 계약과 일치하지 않습니다." % rule.item_id)
			return false
		var item_rules: Array = next_rules.get(rule.item_id, [])
		item_rules.append(rule)
		next_rules[rule.item_id] = item_rules
		next_capacities[rule.socket_type] = rule.slot_capacity
	rules_by_item = next_rules
	capacities = next_capacities
	source_label = new_source_label
	_reconcile_equipped()
	_apply_modifiers()
	catalog_updated.emit(get_snapshot(), source_label)
	return true


func socket_item(item_id: StringName) -> Dictionary:
	var item_rules: Array = rules_by_item.get(item_id, [])
	if item_rules.is_empty():
		return _record_action({&"success": false, &"reason": &"not_session_socket", &"item_id": item_id})
	var exemplar := item_rules[0] as SessionSocketRule
	var slots: Array = equipped.get(exemplar.socket_type, [])
	var same_count := 0
	for slot: Dictionary in slots:
		if slot.get(&"item_id") == item_id:
			same_count += 1
	if same_count >= exemplar.duplicate_limit:
		return _record_action({
			&"success": false, &"reason": &"duplicate_limit", &"item_id": item_id,
			&"socket_type": exemplar.socket_type, &"duplicate_limit": exemplar.duplicate_limit,
		})
	var replaced := {}
	var capacity := int(capacities.get(exemplar.socket_type, exemplar.slot_capacity))
	if slots.size() >= capacity:
		if exemplar.replacement_policy == &"reject":
			return _record_action({
				&"success": false, &"reason": &"socket_full", &"item_id": item_id,
				&"socket_type": exemplar.socket_type,
			})
		replaced = slots.pop_front()
	sequence += 1
	slots.append({
		&"item_id": item_id,
		&"display_name": exemplar.display_name,
		&"socket_type": exemplar.socket_type,
		&"description": exemplar.description,
		&"sequence": sequence,
	})
	equipped[exemplar.socket_type] = slots
	_apply_modifiers()
	var result := {
		&"success": true,
		&"reason": &"replaced_oldest" if not replaced.is_empty() else &"socketed",
		&"item_id": item_id,
		&"display_name": exemplar.display_name,
		&"socket_type": exemplar.socket_type,
		&"replaced_item_id": replaced.get(&"item_id", &""),
		&"runtime_only": true,
	}
	_record_action(result)
	sockets_changed.emit(get_snapshot())
	return result


func unsocket(socket_type: StringName, slot_index: int) -> Dictionary:
	var slots: Array = equipped.get(socket_type, [])
	if slot_index < 0 or slot_index >= slots.size():
		return _record_action({&"success": false, &"reason": &"invalid_slot", &"socket_type": socket_type})
	var removed: Dictionary = slots.pop_at(slot_index)
	equipped[socket_type] = slots
	_apply_modifiers()
	var result := {
		&"success": true, &"reason": &"unsocketed", &"socket_type": socket_type,
		&"item_id": removed.get(&"item_id", &""), &"runtime_only": true,
	}
	_record_action(result)
	sockets_changed.emit(get_snapshot())
	return result


func clear_run() -> void:
	equipped.clear()
	for socket_type in SOCKET_ORDER:
		equipped[socket_type] = []
	sequence = 0
	last_action.clear()
	_remove_modifiers()
	if is_inside_tree():
		sockets_changed.emit(get_snapshot())


func get_snapshot() -> Dictionary:
	var slot_snapshots: Dictionary = {}
	var installed_count := 0
	for socket_type in SOCKET_ORDER:
		var slots: Array = equipped.get(socket_type, [])
		var capacity := int(capacities.get(socket_type, 0))
		var view: Array[Dictionary] = []
		for index in capacity:
			var entry: Dictionary = slots[index].duplicate(true) if index < slots.size() else {}
			entry[&"slot_index"] = index
			entry[&"socket_type"] = socket_type
			entry[&"occupied"] = index < slots.size()
			view.append(entry)
		slot_snapshots[socket_type] = view
		installed_count += slots.size()
	return {
		&"slots": slot_snapshots,
		&"capacities": capacities.duplicate(true),
		&"installed_count": installed_count,
		&"rule_item_count": rules_by_item.size(),
		&"source_label": source_label,
		&"last_action": last_action.duplicate(true),
		&"runtime_only": true,
		&"separate_from_equipment_modules": true,
		&"modifiers": _aggregate_modifiers(),
	}


func _apply_modifiers() -> void:
	var aggregated := _aggregate_modifiers()
	weapon_target.call(&"set_runtime_modifiers", MODIFIER_SOURCE, aggregated[&"weapon"])
	skill_target.call(&"set_runtime_modifiers", MODIFIER_SOURCE, aggregated[&"skill"])
	player_target.call(&"set_runtime_modifier_source", MODIFIER_SOURCE, aggregated[&"player"])


func _remove_modifiers() -> void:
	if is_instance_valid(weapon_target):
		weapon_target.call(&"remove_runtime_modifiers", MODIFIER_SOURCE)
	if is_instance_valid(skill_target):
		skill_target.call(&"remove_runtime_modifiers", MODIFIER_SOURCE)
	if is_instance_valid(player_target):
		player_target.call(&"remove_runtime_modifier_source", MODIFIER_SOURCE)


func _aggregate_modifiers() -> Dictionary:
	var result := {&"weapon": {}, &"skill": {}, &"player": {}}
	for socket_type in SOCKET_ORDER:
		for slot: Dictionary in equipped.get(socket_type, []):
			for value in rules_by_item.get(slot.get(&"item_id", &""), []):
				var rule := value as SessionSocketRule
				var target: Dictionary = result[rule.effect_target]
				if rule.effect_target == &"player":
					var entry: Dictionary = target.get(rule.modifier_id, {&"add": 0.0, &"multiply": 1.0})
					if rule.modifier_operation == &"multiply":
						entry[&"multiply"] = float(entry[&"multiply"]) * rule.modifier_value
					else:
						entry[&"add"] = float(entry[&"add"]) + rule.modifier_value
					target[rule.modifier_id] = entry
				elif rule.modifier_operation == &"multiply":
					target[rule.modifier_id] = float(target.get(rule.modifier_id, 1.0)) * rule.modifier_value
				else:
					target[rule.modifier_id] = float(target.get(rule.modifier_id, 0.0)) + rule.modifier_value
				result[rule.effect_target] = target
	return result


func _reconcile_equipped() -> void:
	for socket_type in SOCKET_ORDER:
		var capacity := int(capacities.get(socket_type, 0))
		var kept: Array = []
		for slot: Dictionary in equipped.get(socket_type, []):
			if rules_by_item.has(slot.get(&"item_id", &"")) and kept.size() < capacity:
				kept.append(slot)
		equipped[socket_type] = kept


func _record_action(result: Dictionary) -> Dictionary:
	last_action = result.duplicate(true)
	socket_action.emit(last_action.duplicate(true))
	return result


func _load_locked_csv() -> bool:
	var text := _read_locked_text(config.locked_csv_path, config.locked_csv_payload)
	if text.is_empty():
		socket_error.emit("확정 RunAsset CSV를 찾을 수 없습니다.")
		return false
	return load_csv_text(text, "확정 CSV")


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
		socket_error.emit("RunAsset Sheet CSV 요청 실패: HTTP %d" % response_code)
		return
	load_csv_text(body.get_string_from_utf8(), "Google Sheets 실시간")


func _supports(candidate: Node, methods: Array[StringName]) -> bool:
	if not is_instance_valid(candidate):
		return false
	for method_name in methods:
		if not candidate.has_method(method_name):
			return false
	return true
