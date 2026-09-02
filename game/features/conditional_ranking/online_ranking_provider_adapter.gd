class_name OnlineRankingProviderAdapter
extends "res://game/features/conditional_ranking/ranking_provider.gd"

var gateway: Node
var provider_label := "온라인 랭킹"
var last_error := ""


func configure(provider_gateway: Node = null, display_name: String = "온라인 랭킹") -> bool:
	gateway = provider_gateway
	provider_label = display_name.strip_edges() if not display_name.strip_edges().is_empty() else "온라인 랭킹"
	last_error = "" if is_available() else "온라인 공급자 연결 대기"
	provider_status_changed.emit(get_provider_status())
	return true


func is_available() -> bool:
	return (
		is_instance_valid(gateway)
		and gateway.has_method(&"is_available")
		and (gateway.has_method(&"submit_envelope") or gateway.has_method(&"submit_run"))
		and gateway.has_method(&"get_entries")
		and bool(gateway.call(&"is_available"))
	)


func submit_run(result: Dictionary) -> Dictionary:
	if not is_available():
		last_error = "온라인 공급자 연결 대기"
		provider_status_changed.emit(get_provider_status())
		return {&"accepted": false, &"reason": last_error, &"provider_status": get_provider_status()}
	var response: Variant = gateway.call(&"submit_run", result.duplicate(true))
	if not response is Dictionary:
		last_error = "온라인 공급자 응답 형식 오류"
		provider_status_changed.emit(get_provider_status())
		return {&"accepted": false, &"reason": last_error, &"provider_status": get_provider_status()}
	var parsed := (response as Dictionary).duplicate(true)
	last_error = "" if bool(parsed.get(&"accepted", false)) else String(parsed.get(&"reason", "온라인 제출 거부"))
	provider_status_changed.emit(get_provider_status())
	return parsed


func submit_envelope(envelope: Dictionary) -> Dictionary:
	if not is_available():
		last_error = "온라인 공급자 연결 대기"
		provider_status_changed.emit(get_provider_status())
		return {
			&"accepted": false, &"retryable": true, &"reason": last_error,
			&"provider_status": get_provider_status(),
		}
	var response: Variant
	if gateway.has_method(&"submit_envelope"):
		response = gateway.call(&"submit_envelope", envelope.duplicate(true))
	else:
		# P6-01 게이트웨이는 payload만 받았으므로 교체 기간 동안 호환합니다.
		response = gateway.call(&"submit_run", envelope.get(&"payload", {}).duplicate(true))
	if not response is Dictionary:
		last_error = "온라인 공급자 응답 형식 오류"
		provider_status_changed.emit(get_provider_status())
		return {&"accepted": false, &"retryable": true, &"reason": last_error}
	var parsed := (response as Dictionary).duplicate(true)
	last_error = "" if bool(parsed.get(&"accepted", false)) else String(parsed.get(&"reason", "온라인 제출 거부"))
	provider_status_changed.emit(get_provider_status())
	return parsed


func get_entries(condition_key: String, ranking_id: StringName = &"recovered_value") -> Array[Dictionary]:
	if not is_available():
		return []
	var response: Variant = gateway.call(&"get_entries", condition_key, ranking_id)
	var result: Array[Dictionary] = []
	if response is Array:
		for entry in response:
			if entry is Dictionary:
				result.append((entry as Dictionary).duplicate(true))
	return result


func get_snapshot() -> Dictionary:
	return {&"provider_status": get_provider_status()}


func get_provider_status() -> Dictionary:
	var online := is_available()
	return {
		&"mode": &"online",
		&"state": &"online" if online else &"unavailable",
		&"label": "%s · 연결됨" % provider_label if online else "%s · 연결 대기" % provider_label,
		&"online": online,
		&"local_preserved": false,
		&"sync_state": &"ready" if online else &"waiting_for_provider",
		&"last_error": last_error,
	}
