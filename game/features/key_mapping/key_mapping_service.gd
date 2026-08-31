class_name KeyMappingService
extends Node

signal bindings_changed(snapshot: Dictionary)
signal binding_rejected(message: String)

## InputMap 변경·충돌 교환·JSON 영속화를 UI와 분리해 담당합니다.

var catalog: Resource
var storage_path: String = "user://sfh_key_mapping.json"
var default_bindings: Dictionary = {}
var configured: bool = false


func configure(new_catalog: Resource, new_storage_path: String, load_saved: bool = true) -> bool:
	if (
		new_catalog == null
		or not new_catalog.has_method(&"validation_errors")
		or not new_catalog.has_method(&"get_entries")
		or not new_catalog.call(&"validation_errors").is_empty()
		or new_storage_path.is_empty()
	):
		return false
	catalog = new_catalog
	storage_path = new_storage_path
	default_bindings.clear()
	for entry: Dictionary in catalog.call(&"get_entries"):
		var action_id: StringName = entry[&"action_id"]
		default_bindings[action_id] = _duplicate_events(InputMap.action_get_events(action_id))
		if (default_bindings[action_id] as Array).is_empty():
			return false
	configured = true
	if load_saved and FileAccess.file_exists(storage_path):
		_load_saved_bindings()
	bindings_changed.emit(get_snapshot())
	return true


func rebind_action(action_id: StringName, input_event: InputEvent) -> Dictionary:
	if not configured or not _is_managed_action(action_id):
		return _reject("변경할 수 없는 Action입니다.")
	var normalized := _normalized_event(input_event)
	if normalized == null:
		return _reject("키보드 또는 마우스 버튼만 지정할 수 있습니다.")
	if normalized is InputEventKey and _event_keycode(normalized) == KEY_ESCAPE:
		return _reject("ESC는 모든 설정 화면의 안전한 닫기 키로 유지됩니다.")
	var current_events := InputMap.action_get_events(action_id)
	if _events_contain(current_events, normalized):
		return {&"success": true, &"message": "이미 사용 중인 키입니다.", &"swapped_action_id": &""}
	var conflicting_action := _find_conflicting_action(action_id, normalized)
	var previous_event: InputEvent = current_events[0].duplicate() if not current_events.is_empty() else null
	if not conflicting_action.is_empty() and previous_event != null:
		InputMap.action_erase_events(conflicting_action)
		InputMap.action_add_event(conflicting_action, previous_event)
	InputMap.action_erase_events(action_id)
	InputMap.action_add_event(action_id, normalized)
	if not _save_bindings():
		reset_defaults(false)
		return _reject("키 설정 파일을 저장하지 못해 기본값으로 복구했습니다.")
	var message := "%s로 변경했습니다." % format_event(normalized)
	if not conflicting_action.is_empty():
		message += " 중복된 %s 키는 서로 교환했습니다." % _display_name(conflicting_action)
	var snapshot := get_snapshot()
	bindings_changed.emit(snapshot)
	return {
		&"success": true,
		&"message": message,
		&"swapped_action_id": conflicting_action,
		&"snapshot": snapshot,
	}


func reset_defaults(save_after_reset: bool = true) -> bool:
	if not configured:
		return false
	for action_id: StringName in default_bindings:
		InputMap.action_erase_events(action_id)
		for event: InputEvent in default_bindings[action_id]:
			InputMap.action_add_event(action_id, event.duplicate())
	var saved := not save_after_reset or _save_bindings()
	bindings_changed.emit(get_snapshot())
	return saved


func get_entries() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if not configured:
		return result
	for entry: Dictionary in catalog.call(&"get_entries"):
		var copy := entry.duplicate(true)
		var action_id: StringName = copy[&"action_id"]
		var events := InputMap.action_get_events(action_id)
		copy[&"events"] = _duplicate_events(events)
		copy[&"binding_text"] = _format_events(events)
		result.append(copy)
	return result


func get_snapshot() -> Dictionary:
	return {
		&"configured": configured,
		&"storage_path": storage_path,
		&"binding_count": get_entries().size(),
		&"entries": get_entries(),
		&"reserved_keys": ["ESC"],
	}


func format_event(event: InputEvent) -> String:
	if event is InputEventKey:
		var parts := PackedStringArray()
		if event.ctrl_pressed:
			parts.append("Ctrl")
		if event.alt_pressed:
			parts.append("Alt")
		if event.shift_pressed:
			parts.append("Shift")
		if event.meta_pressed:
			parts.append("Meta")
		parts.append(OS.get_keycode_string(_event_keycode(event)))
		return "+".join(parts)
	if event is InputEventMouseButton:
		return "마우스 %d" % event.button_index
	return "미지정"


func _load_saved_bindings() -> bool:
	var file := FileAccess.open(storage_path, FileAccess.READ)
	if file == null:
		return false
	var parsed = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary or not parsed.has("bindings") or not parsed["bindings"] is Dictionary:
		return false
	var bindings: Dictionary = parsed["bindings"]
	for action_id: StringName in default_bindings:
		var serialized_events = bindings.get(String(action_id), [])
		if not serialized_events is Array or serialized_events.is_empty():
			continue
		var restored_events: Array[InputEvent] = []
		for serialized in serialized_events:
			var event := _deserialize_event(serialized)
			if event != null and not (
				event is InputEventKey and _event_keycode(event) == KEY_ESCAPE
			):
				restored_events.append(event)
		if restored_events.is_empty():
			continue
		InputMap.action_erase_events(action_id)
		for event in restored_events:
			InputMap.action_add_event(action_id, event)
	return true


func _save_bindings() -> bool:
	if storage_path.is_empty():
		return false
	var bindings := {}
	for action_id: StringName in default_bindings:
		var serialized := []
		for event: InputEvent in InputMap.action_get_events(action_id):
			var value := _serialize_event(event)
			if not value.is_empty():
				serialized.append(value)
		bindings[String(action_id)] = serialized
	var file := FileAccess.open(storage_path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify({"version": 1, "bindings": bindings}, "  "))
	return true


func _serialize_event(event: InputEvent) -> Dictionary:
	if event is InputEventKey:
		return {
			"type": "key",
			"keycode": int(event.keycode),
			"physical_keycode": int(event.physical_keycode),
			"ctrl": event.ctrl_pressed,
			"alt": event.alt_pressed,
			"shift": event.shift_pressed,
			"meta": event.meta_pressed,
		}
	if event is InputEventMouseButton:
		return {"type": "mouse", "button_index": int(event.button_index)}
	return {}


func _deserialize_event(value: Variant) -> InputEvent:
	if not value is Dictionary:
		return null
	if value.get("type", "") == "key":
		var event := InputEventKey.new()
		event.keycode = int(value.get("keycode", 0)) as Key
		event.physical_keycode = int(value.get("physical_keycode", 0)) as Key
		event.ctrl_pressed = bool(value.get("ctrl", false))
		event.alt_pressed = bool(value.get("alt", false))
		event.shift_pressed = bool(value.get("shift", false))
		event.meta_pressed = bool(value.get("meta", false))
		return _normalized_event(event)
	if value.get("type", "") == "mouse":
		var event := InputEventMouseButton.new()
		event.button_index = int(value.get("button_index", 0)) as MouseButton
		return _normalized_event(event)
	return null


func _normalized_event(source: InputEvent) -> InputEvent:
	if source is InputEventKey:
		var event := source.duplicate() as InputEventKey
		if _event_keycode(event) == KEY_NONE:
			return null
		event.pressed = false
		event.echo = false
		return event
	if source is InputEventMouseButton:
		if source.button_index <= MOUSE_BUTTON_NONE or source.button_index > MOUSE_BUTTON_XBUTTON2:
			return null
		var event := source.duplicate() as InputEventMouseButton
		event.pressed = false
		event.double_click = false
		return event
	return null


func _event_keycode(event: InputEventKey) -> Key:
	return event.physical_keycode if event.physical_keycode != KEY_NONE else event.keycode


func _find_conflicting_action(excluded_action: StringName, event: InputEvent) -> StringName:
	for action_id: StringName in default_bindings:
		if action_id != excluded_action and _events_contain(InputMap.action_get_events(action_id), event):
			return action_id
	return &""


func _events_contain(events: Array[InputEvent], target: InputEvent) -> bool:
	var target_value := JSON.stringify(_serialize_event(target))
	for event: InputEvent in events:
		if JSON.stringify(_serialize_event(event)) == target_value:
			return true
	return false


func _duplicate_events(events: Array[InputEvent]) -> Array[InputEvent]:
	var result: Array[InputEvent] = []
	for event: InputEvent in events:
		result.append(event.duplicate())
	return result


func _format_events(events: Array[InputEvent]) -> String:
	var labels := PackedStringArray()
	for event: InputEvent in events:
		labels.append(format_event(event))
	return " / ".join(labels) if not labels.is_empty() else "미지정"


func _is_managed_action(action_id: StringName) -> bool:
	return default_bindings.has(action_id)


func _display_name(action_id: StringName) -> String:
	for entry: Dictionary in catalog.call(&"get_entries"):
		if entry[&"action_id"] == action_id:
			return entry[&"display_name"]
	return String(action_id)


func _reject(message: String) -> Dictionary:
	binding_rejected.emit(message)
	return {&"success": false, &"message": message, &"swapped_action_id": &""}
