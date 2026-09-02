class_name ConditionalRankingSystem
extends "res://game/features/conditional_ranking/ranking_provider.gd"

const LOCAL_PROVIDER_SCRIPT := preload("res://game/features/conditional_ranking/local_ranking_provider.gd")
const ONLINE_PROVIDER_SCRIPT := preload("res://game/features/conditional_ranking/online_ranking_provider_adapter.gd")
const PROVIDER_CONFIG_SCRIPT := preload("res://game/features/conditional_ranking/ranking_provider_config.gd")

var local_provider: Node
var online_provider: Node
var provider_config: Resource
var last_provider_status: Dictionary = {}


func configure(
	new_storage_path: String,
	ranking_policy: Resource,
	enable_persistence: bool = true,
	new_provider_config: Resource = null,
	provider_gateway: Node = null
) -> bool:
	provider_config = new_provider_config
	if provider_config == null:
		provider_config = PROVIDER_CONFIG_SCRIPT.new()
	if not provider_config.is_valid():
		return false

	if local_provider == null:
		local_provider = LOCAL_PROVIDER_SCRIPT.new()
		local_provider.name = &"LocalRankingProvider"
		add_child(local_provider)
		local_provider.ranking_updated.connect(_on_local_ranking_updated)
	if online_provider == null:
		online_provider = ONLINE_PROVIDER_SCRIPT.new()
		online_provider.name = &"OnlineRankingProvider"
		add_child(online_provider)

	if not local_provider.configure(new_storage_path, ranking_policy, enable_persistence):
		return false
	online_provider.configure(provider_gateway, provider_config.online_provider_label)
	_publish_provider_status(_resolve_provider_status())
	return true


func submit_run(result: Dictionary) -> Dictionary:
	# P6-02 재시도 큐 전에도 네트워크 장애가 플레이어의 로컬 기록을 잃게 만들지 않는다.
	var local_result: Dictionary = local_provider.submit_run(result)
	if not bool(local_result.get(&"accepted", false)):
		local_result[&"provider_status"] = _resolve_provider_status()
		return local_result

	var status := _resolve_provider_status()
	if provider_config.provider_mode == "local":
		local_result[&"provider_status"] = status
		_publish_provider_status(status)
		return local_result

	if online_provider.is_available():
		var online_result: Dictionary = online_provider.submit_run(result)
		if bool(online_result.get(&"accepted", false)):
			status = {
				&"mode": StringName(provider_config.provider_mode),
				&"state": &"synced",
				&"label": "%s · 동기화 완료 · 로컬 보존" % provider_config.online_provider_label,
				&"online": true,
				&"local_preserved": true,
				&"sync_state": &"synced",
				&"last_error": "",
			}
			local_result[&"online_result"] = online_result
		else:
			status = _offline_fallback_status(String(online_result.get(&"reason", "온라인 제출 실패")))
	else:
		status = _offline_fallback_status("온라인 공급자 연결 대기")

	local_result[&"provider_status"] = status
	_publish_provider_status(status)
	return local_result


func calculate_score(result: Dictionary) -> float:
	return local_provider.calculate_score(result) if local_provider != null else 0.0


func get_entries(condition_key: String, ranking_id: StringName = &"recovered_value") -> Array[Dictionary]:
	if (
		provider_config != null
		and provider_config.provider_mode != "local"
		and online_provider != null
		and online_provider.is_available()
	):
		var online_entries: Array[Dictionary] = online_provider.get_entries(condition_key, ranking_id)
		if not online_entries.is_empty():
			return online_entries
	return local_provider.get_entries(condition_key, ranking_id) if local_provider != null else []


func get_snapshot() -> Dictionary:
	var local_snapshot: Dictionary = local_provider.get_snapshot() if local_provider != null else {}
	var snapshot: Dictionary = local_snapshot.duplicate(true)
	snapshot[&"provider_mode"] = provider_config.provider_mode if provider_config != null else "local"
	snapshot[&"provider_status"] = get_provider_status()
	snapshot[&"local_snapshot"] = local_snapshot
	snapshot[&"online_snapshot"] = online_provider.get_snapshot() if online_provider != null else {}
	return snapshot


func get_provider_status() -> Dictionary:
	return last_provider_status.duplicate(true) if not last_provider_status.is_empty() else _resolve_provider_status()


func set_online_gateway(provider_gateway: Node) -> void:
	if online_provider == null:
		return
	online_provider.configure(provider_gateway, provider_config.online_provider_label)
	_publish_provider_status(_resolve_provider_status())


func set_provider_mode(mode: String) -> bool:
	if provider_config == null or mode not in ["local", "auto", "online"]:
		return false
	provider_config.provider_mode = mode
	_publish_provider_status(_resolve_provider_status())
	return true


func _resolve_provider_status() -> Dictionary:
	if provider_config == null or provider_config.provider_mode == "local":
		return local_provider.get_provider_status() if local_provider != null else super.get_provider_status()
	if online_provider != null and online_provider.is_available():
		return {
			&"mode": StringName(provider_config.provider_mode),
			&"state": &"online_ready",
			&"label": "%s · 연결됨 · 로컬 보존" % provider_config.online_provider_label,
			&"online": true,
			&"local_preserved": true,
			&"sync_state": &"ready",
			&"last_error": "",
		}
	return _offline_fallback_status("온라인 공급자 연결 대기")


func _offline_fallback_status(reason: String) -> Dictionary:
	var fallback_enabled: bool = provider_config == null or provider_config.offline_fallback_enabled
	return {
		&"mode": StringName(provider_config.provider_mode) if provider_config != null else &"local",
		&"state": &"offline_fallback" if fallback_enabled else &"unavailable",
		&"label": "오프라인 · 로컬 보존 · 동기화 대기" if fallback_enabled else "온라인 랭킹 사용 불가",
		&"online": false,
		&"local_preserved": true,
		&"sync_state": &"waiting_for_provider",
		&"last_error": reason,
	}


func _publish_provider_status(status: Dictionary) -> void:
	last_provider_status = status.duplicate(true)
	provider_status_changed.emit(last_provider_status.duplicate(true))


func _on_local_ranking_updated(condition_key: String, entries: Array[Dictionary]) -> void:
	ranking_updated.emit(condition_key, entries)
