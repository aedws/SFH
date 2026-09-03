class_name SeasonHonorProfile
extends Node
## Atomic, separate cosmetic profile. No wallet or combat stat mutations.
signal changed
var storage_path := ""
var enabled := false
var player_id := ""
var owned: Dictionary = {}
var receipts: Dictionary = {}
var equipped := {"title": "", "aura": ""}
var storage_error := ""


func configure(path: String, identity: String, persist: bool) -> bool:
	storage_path = path
	player_id = identity
	enabled = persist and not path.is_empty()
	if enabled and FileAccess.file_exists(path):
		var file := FileAccess.open(path, FileAccess.READ)
		var parser := JSON.new()
		var parsed := parser.parse(file.get_as_text()) if file != null else ERR_CANT_OPEN
		var data: Variant = parser.data if parsed == OK else null
		if not data is Dictionary or int(data.get("schema", 0)) != 1 or data.get("player_id", "") != identity or not data.get("owned", {}) is Dictionary or not data.get("receipts", {}) is Dictionary or not data.get("equipped", {}) is Dictionary:
			storage_error = "칭호 저장 오류 · 원본 보존 · 지급 및 장착 중지"
			return false
		owned = data.get("owned", {}).duplicate(true)
		receipts = data.get("receipts", {}).duplicate(true)
		equipped = data.get("equipped", equipped).duplicate(true)
		for reward in owned.values():
			if not reward is Dictionary or String(reward.get("kind", "")) not in ["title", "aura"] or not Color.html_is_valid(String(reward.get("color", ""))):
				storage_error = "칭호 저장 내용 오류 · 원본 보존"
		for receipt in receipts.values():
			if not receipt is Dictionary:
				storage_error = "칭호 지급 근거 오류 · 원본 보존"
		for kind in ["title", "aura"]:
			var id := String(equipped.get(kind, ""))
			if not id.is_empty() and (not owned.has(id) or not owned[id] is Dictionary or String(owned[id].get("kind", "")) != kind):
				storage_error = "칭호 장착 정보 오류 · 원본 보존"
		if not storage_error.is_empty():
			owned.clear()
			receipts.clear()
			equipped = {"title": "", "aura": ""}
			return false
	return true


func grant(receipt_id: String, reward: Dictionary, evidence: Dictionary) -> bool:
	if not storage_error.is_empty() or receipt_id.is_empty() or receipts.has(receipt_id):
		return false
	var before := get_snapshot()
	var id := String(reward.get(&"reward_id", ""))
	if id.is_empty() or String(reward.get(&"kind", "")) not in ["title", "aura"]:
		return false
	owned[id] = reward.duplicate(true)
	receipts[receipt_id] = evidence.duplicate(true).merged({"reward_id": id})
	return _commit(before)


func equip(kind: String, reward_id: String) -> bool:
	if not storage_error.is_empty() or kind not in ["title", "aura"]:
		return false
	if not reward_id.is_empty() and (not owned.has(reward_id) or String(owned[reward_id].get("kind", "")) != kind):
		return false
	var before := get_snapshot()
	equipped[kind] = reward_id
	return _commit(before)


func get_snapshot() -> Dictionary:
	return {"owned": owned.duplicate(true), "receipts": receipts.duplicate(true), "equipped": equipped.duplicate(true), "storage_error": storage_error, "local_only": true}


func _commit(before: Dictionary) -> bool:
	if enabled:
		var file := FileAccess.open(storage_path + ".tmp", FileAccess.WRITE)
		if file != null:
			file.store_string(JSON.stringify(get_snapshot().merged({"schema": 1, "player_id": player_id})))
			file.flush()
		var error := file.get_error() if file != null else ERR_CANT_OPEN
		if file != null:
			file.close()
		if error != OK or DirAccess.rename_absolute(storage_path + ".tmp", storage_path) != OK:
			owned = before["owned"]
			receipts = before["receipts"]
			equipped = before["equipped"]
			storage_error = "칭호 저장 실패 · 지급 취소"
			return false
	changed.emit()
	return true
