class_name SeasonRankingService
extends Node

## Owns local season lifecycle only. Lifetime results/rewards remain independent.
const LOCAL_PROVIDER := preload("res://game/features/conditional_ranking/local_ranking_provider.gd")
var policy: Resource
var ranking_policy: Resource
var clock: Callable
var storage_path := ""
var persistence_enabled := false
var active: Dictionary = {}
var archives: Array[Dictionary] = []
var closed_through := 0
var ladder: Node
var storage_error := ""


func configure(path: String, season_policy: Resource, score_policy: Resource, persist: bool, time_source: Callable = Callable()) -> bool:
	if season_policy == null or not season_policy.has_method(&"is_valid") or not season_policy.is_valid():
		return false
	policy = season_policy.duplicate(true)
	ranking_policy = score_policy.duplicate(true)
	# Season participation owns its threshold, not the lifetime ladder default.
	ranking_policy.minimum_penalty_score = 0
	clock = time_source if time_source.is_valid() else func(): return int(Time.get_unix_time_from_system())
	storage_path = path
	persistence_enabled = persist and not path.is_empty()
	ladder = LOCAL_PROVIDER.new()
	add_child(ladder)
	if not ladder.configure("", ranking_policy, false):
		return false
	if persistence_enabled:
		_load()
	advance()
	return true


func advance() -> void:
	if not storage_error.is_empty():
		return
	var now := int(clock.call())
	if not active.is_empty() and now >= int(active[&"ends_at"]):
		archives.append({&"season": active.duplicate(true), &"ladder": ladder.get_snapshot(), &"closed_at": int(active[&"ends_at"]), &"read_only": true})
		closed_through = maxi(closed_through, int(active[&"ends_at"]))
		while archives.size() > int(policy.maximum_archives):
			archives.pop_front()
		active.clear()
		ladder.restore_snapshot({})
		_save()
	if active.is_empty() and now >= closed_through:
		active = policy.season_at(now)
		if not active.is_empty():
			_save()


func preview(contract: Dictionary) -> Dictionary:
	advance()
	var participation: Dictionary = policy.participation(active, contract)
	if not storage_error.is_empty():
		participation = {&"eligible": false, &"reason": storage_error}
	if not active.is_empty() and int(clock.call()) < int(active[&"starts_at"]):
		participation = {&"eligible": false, &"reason": "기기 시간 확인 필요"}
	return participation.merged({
		&"season": active.duplicate(true), &"context": policy.context_for(active),
		&"local_only": true, &"archive_count": archives.size(),
	}, true)


func freeze_reward_catalog(rows: Array) -> void:
	advance()
	if storage_error.is_empty() and not active.is_empty() and not active.has(&"reward_catalog"):
		active[&"reward_catalog"] = rows.duplicate(true)
		_save()


func submit_run(result: Dictionary) -> Dictionary:
	var state := preview(result)
	if not bool(state.get(&"eligible", false)):
		return {&"accepted": false, &"reason": state.get(&"reason", "시즌 조건 불일치")}
	var context: Dictionary = result.get(&"season_context", {})
	if context != policy.context_for(active):
		return {&"accepted": false, &"reason": "시즌 종료 또는 출격 시 시즌 미지정 · 일반 기록 유지"}
	var response: Dictionary = ladder.submit_run(result)
	if bool(response.get(&"accepted", false)):
		_save()
		if not storage_error.is_empty():
			return {&"accepted": false, &"reason": storage_error}
	response[&"season_id"] = active.get(&"season_id", "")
	response[&"reason"] = "로컬 시즌 기록 · 온라인 순위·보상 아님"
	return response


func get_snapshot() -> Dictionary:
	advance()
	return {&"active": active.duplicate(true), &"ladder": ladder.get_snapshot(), &"archives": archives.duplicate(true), &"storage_error": storage_error, &"local_only": true}


func get_archive(season_id: String) -> Dictionary:
	advance()
	for archive in archives:
		if String(archive.get(&"season", {}).get(&"season_id", "")) == season_id:
			return archive.duplicate(true)
	return {}


func _save() -> void:
	if not persistence_enabled:
		return
	var temporary := storage_path + ".tmp"
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		storage_error = "시즌 저장 실패 · 일반 기록 유지"
		return
	file.store_string(JSON.stringify({&"schema_version": 1, &"active": active, &"ladder": ladder.get_snapshot(), &"archives": archives, &"closed_through": closed_through}))
	file.flush()
	var error := file.get_error()
	file.close()
	if error != OK or DirAccess.rename_absolute(temporary, storage_path) != OK:
		storage_error = "시즌 저장 실패 · 일반 기록 유지"


func _load() -> void:
	if not FileAccess.file_exists(storage_path):
		return
	var file := FileAccess.open(storage_path, FileAccess.READ)
	var parsed: Variant = JSON.parse_string(file.get_as_text()) if file != null else null
	if not parsed is Dictionary or int(parsed.get("schema_version", 0)) != 1 or not parsed.get("active", {}) is Dictionary or not parsed.get("archives", []) is Array or not parsed.get("ladder", {}) is Dictionary:
		storage_error = "시즌 저장 형식 오류 · 원본 보존 · 일반 기록 유지"
		return
	active = parsed.get("active", {}).duplicate(true)
	if not active.is_empty() and not _valid_season(active):
		storage_error = "시즌 저장 필수값 누락 · 원본 보존"
		return
	closed_through = int(parsed.get("closed_through", 0))
	for archive in parsed.get("archives", []):
		if not archive is Dictionary or not archive.get("season", {}) is Dictionary or not _valid_season(archive.get("season", {})) or not archive.get("ladder", {}) is Dictionary or not ladder.restore_snapshot(archive.get("ladder", {})):
			storage_error = "시즌 마감 기록 형식 오류 · 원본 보존"
			return
		archives.append(archive.duplicate(true))
	if not ladder.restore_snapshot(parsed.get("ladder", {})):
		storage_error = "시즌 순위 형식 오류 · 원본 보존"


func _valid_season(value: Dictionary) -> bool:
	return value.has("ends_at") and value.has("starts_at") and value.has("season_id") and value.has("policy_id") and int(value["ends_at"]) > int(value["starts_at"]) and value.get("allowed_map_sizes", []) is Array
