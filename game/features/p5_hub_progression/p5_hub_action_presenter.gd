class_name P5HubActionPresenter
extends RefCounted

var service: Node
var config: Resource


func configure(service_provider: Node, progression_config: Resource) -> bool:
	service = service_provider
	config = progression_config
	return is_instance_valid(service) and config != null


func perform(action_id: StringName) -> Dictionary:
	match action_id:
		&"shop_purchase": return _purchase_selected_offer()
		&"craft_default": return _craft_default()
		&"utility_toggle": return _toggle_utility()
		&"training_toggle": return _toggle_training()
		&"codex_summary": return _codex_summary()
	return {&"handled": false, &"status_text": ""}


func _purchase_selected_offer() -> Dictionary:
	var offers: Array = service.call(&"get_snapshot").get(&"shop", {}).get(&"offers", [])
	if offers.is_empty(): return _presentation(false, "회전 상점 상품 없음")
	var offer: Dictionary = offers[0]
	var result: Dictionary = service.call(&"purchase_shop_offer", offer.get(&"offer_id", &""), _transaction_id(&"shop"))
	return _presentation(bool(result.get(&"success", false)), "회전 상점 %s · %s" % ["구매 완료" if bool(result.get(&"success", false)) else "구매 실패", offer.get(&"display_name", offer.get(&"offer_id", &""))], result)


func _craft_default() -> Dictionary:
	var result: Dictionary = service.call(&"craft_recipe", config.get("default_recipe_id"), _transaction_id(&"craft"))
	var text := "워크숍 제작 완료 · 옵션 %d · 소켓 %d" % [int(result.get(&"item", {}).get(&"affix_count", 0)), int(result.get(&"item", {}).get(&"socket_count", 0))]
	if not bool(result.get(&"success", false)): text = "워크숍 제작 대기 · %s" % result.get(&"reason", "도면 확인")
	return _presentation(bool(result.get(&"success", false)), text, result)


func _toggle_utility() -> Dictionary:
	var result: Dictionary = service.call(&"toggle_utility", config.get("default_utility_id"))
	return _presentation(bool(result.get(&"success", false)), "런 유틸리티 · 응급키트 %s" % ("선택" if int(result.get(&"quantity", 0)) > 0 else "해제"), result)


func _toggle_training() -> Dictionary:
	var active: Dictionary = service.call(&"get_snapshot").get(&"training", {}).get(&"active", {})
	if active.is_empty():
		var started: Dictionary = service.call(&"start_training", config.get("default_training_scenario_id"))
		return _presentation(bool(started.get(&"success", false)), "훈련장 시작 · 실제 타격 측정 대기", started)
	var finished: Dictionary = service.call(&"finish_training")
	return _presentation(bool(finished.get(&"success", false)), "훈련장 종료 · DPS %.1f · 최대 타격 %.1f · 로드아웃 원복" % [float(finished.get(&"dps", 0.0)), float(finished.get(&"hit_damage", 0.0))], finished)


func _codex_summary() -> Dictionary:
	var codex: Dictionary = service.call(&"get_snapshot").get(&"codex", {})
	return _presentation(true, "작전 도감 · %d/%d 완료 · 지역 힌트 %d곳" % [int(codex.get(&"completed_count", 0)), int(codex.get(&"entry_count", 0)), (codex.get(&"region_hints", {}) as Dictionary).size()])


func _presentation(success: bool, status_text: String, detail: Dictionary = {}) -> Dictionary:
	return {&"handled": true, &"success": success, &"status_text": status_text, &"detail": detail}


func _transaction_id(prefix: StringName) -> StringName:
	return StringName("ui_%s_%d" % [prefix, Time.get_ticks_usec()])
