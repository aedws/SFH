class_name LootLifecyclePresenter
extends RefCounted


static func present(definition: LootLifecycleDefinition) -> Dictionary:
	if definition == null or not definition.is_valid():
		return {}
	var is_persistent := definition.loot_family == LootLifecycleDefinition.PERSISTENT_ASSET
	var family_label := "◆ 영구 자산" if is_persistent else "◇ 이번 런 자산"
	var use_labels := {
		&"warehouse_item": "창고 보관",
		&"carry_currency": "현장 재화",
		&"permanent_unlock": "영구 해금",
		&"session_socket": "런 소켓 장착",
	}
	var extract_labels := {
		&"warehouse": "탈출 시 창고 보관",
		&"wallet": "탈출 시 지갑 정산",
		&"permanent_unlock": "탈출 시 영구 해금",
		&"auto_convert": "탈출 시 %d C 자동 환전" % definition.convert_value,
	}
	var death_label := "× 사망 시 소실" if definition.death_result == &"lost" else "◇ 사망해도 유지"
	return {
		&"title": definition.display_name,
		&"family_label": family_label,
		&"use_label": use_labels.get(definition.session_behavior, "사용 규칙 없음"),
		&"extract_label": extract_labels.get(definition.extract_result, "탈출 결과 없음"),
		&"death_label": death_label,
		&"summary": "%s · %s · %s" % [
			family_label,
			extract_labels.get(definition.extract_result, "탈출 결과 없음"),
			death_label,
		],
	}
