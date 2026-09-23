class_name DesktopProgressService
extends Node
## Owns native hub loadout checkpoints and run history, never temporary combat loot.
signal storage_changed(snapshot: Dictionary)
const Store := preload("res://game/core/persistence/atomic_json_store.gd")
const Codec := preload("res://game/features/local_save/loadout_value_codec.gd")
const SCHEMA := 1
const HISTORY_LIMIT := 100
var storage_path := ""
var store := Store.new()
var document := {"schema_version": SCHEMA, "loadout": null, "history": [], "total_runs": 0, "extractions": 0, "pending_run": {}}
var enabled := false
var blocked := false
var status := "새 기록"
var message := ""
var restored := false
var dirty := false
var bag: Node
var gear: Node
var delay := 0.0
var storage_providers: Array[Node] = []
var result_details := {}
var temporary_loadout := false


func begin_temporary_loadout() -> bool:
	if temporary_loadout:
		return false
	if not flush():
		return false
	temporary_loadout = true
	return true


func end_temporary_loadout() -> bool:
	# Caller has restored every participant before releasing this checkpoint barrier.
	temporary_loadout = false
	if not flush():
		temporary_loadout = true
		return false
	return true


func observe_settlement(result: Dictionary) -> void:
	result_details = {}
	for key in [&"raw_credits", &"recovered_credits", &"salvage", &"lost_credits"]:
		if result.has(key): result_details[String(key)] = int(result[key])


func register_storage_provider(provider: Node) -> bool:
	if is_instance_valid(provider) and provider.has_method(&"get_storage_status"):
		storage_providers.append(provider)
		var health: Dictionary = provider.call(&"get_storage_status")
		if not health.get("ok", false):
			return _block("자동 저장 확인 필요", String(health.get("message", "")))
		return true
	return false


func configure(path: String, enable: bool = true) -> bool:
	storage_path = path
	enabled = enable and not path.is_empty()
	process_mode = Node.PROCESS_MODE_ALWAYS
	if not enabled: return true
	var loaded := store.read(path)
	if not loaded.ok:
		return _block("저장 복원 실패 · 원본 보존", store.last_error)
	var data: Dictionary = loaded.data
	if not data.is_empty():
		if not _valid_document(data):
			return _block("지원하지 않는 저장 데이터", "파일을 덮어쓰지 않았습니다.")
		document = data.duplicate(true)
		status = "백업에서 복구" if loaded.status == "recovered" else "이전 기록 불러옴"
	# A quit/crash never extracts unbanked loot or refunds an already paid entry.
	if not document.pending_run.is_empty():
		var pending: Dictionary = document.pending_run.duplicate(true)
		_complete(pending.run_id, false, {"outcome": "interrupted", "entry_cost": pending.get("entry_cost", 0)})
	storage_changed.emit(get_snapshot())
	return not blocked


func bind_hub(inventory: Node, equipment: Node) -> bool:
	unbind_hub()
	if not enabled: return true
	if blocked: return false
	for target in [inventory, equipment]:
		if not is_instance_valid(target): return _block("저장 연결 실패", "가방·장비가 필요합니다.")
		for method in [&"export_runtime_state", &"validate_runtime_state", &"restore_runtime_state"]:
			if not target.has_method(method):
				return _block("저장 연결 실패", "가방·장비 공개 계약이 필요합니다.")
	if not inventory.has_signal(&"inventory_changed") or not equipment.has_signal(&"customization_changed") or not equipment.has_signal(&"active_weapon_changed"):
		return _block("저장 연결 실패", "가방·장비 변경 Signal이 필요합니다.")
	var migrated_capacity := false
	if not restored and document.loadout != null:
		var codec := Codec.new()
		var saved: Variant = codec.decode(document.loadout)
		if not codec.error.is_empty() or not saved is Dictionary:
			return _block("세팅 복원 실패 · 원본 보존", codec.error)
		if not saved.get(&"bag") is Dictionary or not saved.get(&"gear") is Dictionary:
			return _block("세팅 복원 실패 · 원본 보존", "가방·장비 저장 구획 오류")
		if inventory.has_method(&"prepare_saved_state"):
			var prepared: Dictionary = inventory.call(&"prepare_saved_state", saved.bag)
			if prepared.is_empty(): return _block("가방 이관 실패 · 원본 보존", "원본 가방을 검증하지 못했습니다.")
			migrated_capacity = prepared.get(&"grid_size") != saved.bag.get(&"grid_size")
			saved.bag = prepared
		if not inventory.call(&"validate_runtime_state", saved.bag).is_empty() or not equipment.call(&"validate_runtime_state", saved.gear).is_empty():
			return _block("세팅 규칙 불일치 · 원본 보존", "현재 빌드에서 읽을 수 없는 장비/가방 데이터입니다.")
		var before_bag: Dictionary = inventory.call(&"export_runtime_state")
		var before_gear: Dictionary = equipment.call(&"export_runtime_state")
		var ok := bool(inventory.call(&"restore_runtime_state", saved.bag))
		if ok and not saved.gear.is_empty(): ok = bool(equipment.call(&"restore_runtime_state", saved.gear))
		if not ok:
			inventory.call(&"restore_runtime_state", before_bag)
			equipment.call(&"restore_runtime_state", before_gear)
			return _block("세팅 복원 실패 · 기본 장비 유지", "복원 변경을 취소했습니다.")
	restored = true
	bag = inventory
	gear = equipment
	bag.connect(&"inventory_changed", _on_changed)
	gear.connect(&"customization_changed", _on_changed)
	gear.connect(&"active_weapon_changed", _on_weapon_changed)
	if migrated_capacity:
		dirty = true
		if not flush(): return false
	storage_changed.emit(get_snapshot())
	return true


func unbind_hub() -> void:
	if dirty: flush()
	for binding in [[bag, &"inventory_changed", _on_changed], [gear, &"customization_changed", _on_changed], [gear, &"active_weapon_changed", _on_weapon_changed]]:
		if is_instance_valid(binding[0]) and binding[0].is_connected(binding[1], binding[2]):
			binding[0].disconnect(binding[1], binding[2])
	bag = null
	gear = null


func _exit_tree() -> void:
	unbind_hub()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST and enabled and dirty:
		flush()


func _process(delta: float) -> void:
	if not dirty: return
	delay -= delta
	if delay <= 0.0: flush()


func _on_changed(_value: Dictionary) -> void:
	dirty = true
	delay = 0.15


func _on_weapon_changed(_slot: StringName, _weapon: Resource) -> void:
	_on_changed({})


func flush() -> bool:
	if not enabled: return true
	if blocked: return false
	if not temporary_loadout and is_instance_valid(bag) and is_instance_valid(gear):
		var saved := {&"bag": bag.call(&"export_runtime_state"), &"gear": gear.call(&"export_runtime_state")}
		if not bag.call(&"validate_runtime_state", saved.bag).is_empty() or not gear.call(&"validate_runtime_state", saved.gear).is_empty():
			return _block("세팅 저장 실패", "유효하지 않은 가방/장비는 저장하지 않습니다.")
		var codec := Codec.new()
		var encoded: Variant = codec.encode(saved)
		if not codec.error.is_empty(): return _block("세팅 저장 실패", codec.error)
		document.loadout = encoded
	dirty = false
	return _write()


func begin_run(run_id: StringName, contract: Dictionary) -> bool:
	if temporary_loadout: return false
	if not enabled: return true
	if not flush(): return false
	result_details.clear()
	document.pending_run = {"run_id": String(run_id), "entry_cost": int(contract.get(&"entry_cost", 0)), "started_at": int(Time.get_unix_time_from_system())}
	return _write()


func cancel_run() -> void:
	if not enabled or blocked: return
	document.pending_run = {}
	_write()


func finish_run(run_id: StringName, extracted: bool, details: Dictionary) -> bool:
	if not enabled: return true
	return _complete(String(run_id), extracted, details)


func _complete(run_id: String, extracted: bool, details: Dictionary) -> bool:
	if blocked or run_id.is_empty(): return false
	for entry in document.history:
		if entry.get("run_id") == run_id: return true
	var record := details.duplicate(true)
	record.merge(result_details, true)
	record.merge({"run_id": run_id, "extracted": extracted, "finished_at": int(Time.get_unix_time_from_system())}, true)
	document.history.push_front(record)
	while document.history.size() > HISTORY_LIMIT: document.history.pop_back()
	document.total_runs = int(document.total_runs) + 1
	document.extractions = int(document.extractions) + (1 if extracted else 0)
	document.pending_run = {}
	if not extracted and document.loadout != null:
		var codec := Codec.new()
		var saved: Variant = codec.decode(document.loadout)
		if not codec.error.is_empty() or not saved is Dictionary: return _block("저장 복원 실패", codec.error)
		saved[&"gear"] = {} # Existing death rule: equipped loadout lost, free starter restored.
		codec = Codec.new()
		document.loadout = codec.encode(saved)
		if not codec.error.is_empty(): return _block("저장 실패", codec.error)
	return _write()


func get_snapshot() -> Dictionary:
	return {&"enabled": enabled, &"blocked": blocked, &"status": status, &"message": message,
		&"path": ProjectSettings.globalize_path(storage_path) if not storage_path.is_empty() else "",
		&"total_runs": int(document.total_runs), &"extractions": int(document.extractions),
		&"history": document.history.duplicate(true), &"pending_run": document.pending_run.duplicate(true),
		&"dirty": dirty, &"hub_bound": is_instance_valid(bag), &"temporary_loadout": temporary_loadout}


func _write() -> bool:
	for provider in storage_providers:
		if is_instance_valid(provider):
			var health: Dictionary = provider.call(&"get_storage_status")
			if not health.get("ok", false): return _block("자동 저장 확인 필요", String(health.get("message", "")))
	if not store.write(storage_path, document): return _block("자동 저장 실패", store.last_error)
	status = "로컬 저장 완료"
	message = ""
	storage_changed.emit(get_snapshot())
	return true


func _block(label: String, detail: String) -> bool:
	blocked = true
	dirty = false
	status = label
	message = detail
	storage_changed.emit(get_snapshot())
	return false


func _valid_document(data: Dictionary) -> bool:
	if data.get("schema_version") != SCHEMA or not data.get("history") is Array or not data.get("pending_run") is Dictionary:
		return false
	if not data.has("loadout") or not (data.loadout == null or data.loadout is Dictionary): return false
	for key in ["total_runs", "extractions"]:
		if not (data.get(key) is float or data.get(key) is int) or float(data[key]) < 0: return false
	if data.history.size() > HISTORY_LIMIT: return false
	for entry in data.history:
		if not entry is Dictionary or not entry.get("run_id") is String: return false
	return data.pending_run.is_empty() or data.pending_run.get("run_id") is String
