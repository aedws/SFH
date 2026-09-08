class_name EquipmentModuleUIPresenter
extends RefCounted

const ITEM_QUALITY := preload("res://game/core/item_quality_descriptor.gd")

static func tag_label(id: StringName) -> String:
	return {&"ballistic": "탄도", &"mobility": "기동", &"survival": "생존", &"defense": "방어", &"rifle": "소총", &"pistol": "권총", &"greatsword": "대검", &"dagger": "단검", &"optic": "광학", &"muzzle": "총구", &"magazine": "탄창", &"blade": "칼날", &"grip": "손잡이"}.get(id, String(id))

static func tags_text(values: Array) -> String:
	var labels := PackedStringArray()
	for value in values: labels.append(tag_label(StringName(value)))
	return " · ".join(labels)

## 모듈 상태를 카드·적용 수치용 문자열로 바꾸는 표현 전용 어댑터입니다.
## 장착 가능 여부와 코스트 계산은 EquipmentItemState의 결과만 소비합니다.

const STAT_LABELS := {
	&"max_health": "최대 체력",
	&"defense": "방어력",
	&"movement_speed": "이동 속도",
	&"projectile_damage": "투사체 피해",
}


func installed_card_text(state, module_instance) -> String:
	var definition = module_instance.definition
	var quality := ""
	if not module_instance.item_quality_payload.is_empty():
		quality = " | Q×%.2f" % module_instance.quality_multiplier()
	return "COST %d | LV.%d%s\n%s\n%s" % [
		state.effective_module_cost(module_instance),
		module_instance.upgrade_level,
		quality,
		definition.display_name,
		_join_names(definition.module_tags, "태그 없음"),
	]


func inventory_card_text(entry: Dictionary, compatible: bool) -> String:
	var definition: Resource = entry.get(&"linked_resource")
	var status := "장착 가능" if compatible else "조건 확인"
	if definition is EquipmentModuleDefinition:
		var module_definition := definition as EquipmentModuleDefinition
		var payload: Dictionary = entry.get(&"runtime_payload", {})
		var quality := ""
		if payload.has(ITEM_QUALITY.KEY_ID):
			quality = " | Q×%.2f" % ITEM_QUALITY.multiplier(payload)
		return "MOD | COST %d%s\n%s\n%s\n%s" % [
			module_definition.cost_at_level(1),
			quality,
			entry.get(&"display_name", "이름 없음"),
			_join_names(module_definition.module_tags, "태그 없음"),
			status,
		]
	if definition is EquipmentPartDefinition:
		var part := definition as EquipmentPartDefinition
		return "파츠  |  %s\n%s\n%s 전용\n%s" % [
			tag_label(part.socket_id),
			entry.get(&"display_name", "이름 없음"),
			_join_names(part.compatible_minor_tags, "미지정"),
			status,
		]
	return "ITEM\n%s\n%s" % [entry.get(&"display_name", "이름 없음"), status]


func applied_effects_text(state) -> String:
	if state == null:
		return "적용 수치\n장비를 선택하면 장착 모듈의 합산 효과를 표시합니다."
	if state.installed_modules.is_empty():
		return "적용 수치\n장착된 모듈이 없습니다. 아래 보유 카드에서 모듈을 선택하세요."
	var totals := {}
	var features := PackedStringArray()
	for module_instance in state.installed_modules:
		var definition = module_instance.definition
		for modifier in definition.stat_modifiers:
			var entry: Dictionary = totals.get(
				modifier.stat_id, {&"add": 0.0, &"multiply": 1.0}
			)
			if modifier.operation == EquipmentStatModifier.Operation.ADD:
				entry[&"add"] = float(entry[&"add"]) + ITEM_QUALITY.scale_additive(
					modifier.amount, module_instance.item_quality_payload
				)
			else:
				entry[&"multiply"] = float(entry[&"multiply"]) * (
					ITEM_QUALITY.scale_multiplicative(
						modifier.amount, module_instance.item_quality_payload
					)
				)
			totals[modifier.stat_id] = entry
		for feature_id in definition.special_feature_ids:
			if not features.has(String(feature_id)):
				features.append(String(feature_id))
		if state.upgrade_balance_provider != null:
			var upgraded: Dictionary = state.upgrade_balance_provider.call(
				&"get_player_modifiers", &"module", definition.module_id, module_instance.upgrade_level
			)
			for stat_id in upgraded:
				var source: Dictionary = upgraded[stat_id]
				var entry: Dictionary = totals.get(stat_id, {&"add": 0.0, &"multiply": 1.0})
				entry[&"add"] += ITEM_QUALITY.scale_additive(float(source.get(&"add", 0.0)), module_instance.item_quality_payload)
				entry[&"multiply"] *= ITEM_QUALITY.scale_multiplicative(float(source.get(&"multiply", 1.0)), module_instance.item_quality_payload)
				totals[stat_id] = entry
	var lines := PackedStringArray(["적용 수치"])
	for stat_id in totals:
		var entry: Dictionary = totals[stat_id]
		lines.append("%s    %s" % [
			STAT_LABELS.get(stat_id, String(stat_id)),
			_format_modifier_entry(entry),
		])
	if not features.is_empty():
		lines.append("특수 기능    %d개 준비" % features.size())
	return "\n".join(lines)


func sort_value(entry: Dictionary, compatible: bool, mode: StringName) -> Array:
	var definition: Resource = entry.get(&"linked_resource")
	var cost := 999
	if definition is EquipmentModuleDefinition:
		cost = (definition as EquipmentModuleDefinition).cost_at_level(1)
	elif definition is EquipmentPartDefinition:
		cost = 0
	var name := String(entry.get(&"display_name", ""))
	if mode == &"cost":
		return [cost, 0 if compatible else 1, name]
	return [0 if compatible else 1, cost, name]


func _format_modifier_entry(entry: Dictionary) -> String:
	var add_amount := float(entry.get(&"add", 0.0))
	var multiplier := float(entry.get(&"multiply", 1.0))
	if not is_equal_approx(add_amount, 0.0) and not is_equal_approx(multiplier, 1.0):
		return "%+.1f · %+.1f%%" % [add_amount, (multiplier - 1.0) * 100.0]
	if not is_equal_approx(multiplier, 1.0):
		return "%+.1f%%" % ((multiplier - 1.0) * 100.0)
	return "%+.1f" % add_amount


func _join_names(values: Array, fallback: String) -> String:
	var names := PackedStringArray()
	for value in values:
		names.append(tag_label(StringName(value)))
	return ", ".join(names) if not names.is_empty() else fallback
