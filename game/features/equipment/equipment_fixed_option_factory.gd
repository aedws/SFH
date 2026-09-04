class_name EquipmentFixedOptionFactory
extends RefCounted

## 제작·드랍 payload의 옵션을 장비 인스턴스에 귀속되는 고정 옵션으로 변환합니다.
## 이 어댑터만 데이터 포맷을 알고 장비 계산 계층은 EquipmentFixedOption만 소비합니다.


static func from_payload(definition: Resource, payload: Dictionary) -> Array[EquipmentFixedOption]:
	var result: Array[EquipmentFixedOption] = []
	for affix_value in payload.get(&"affixes", []):
		if not affix_value is Dictionary:
			continue
		var option := _from_affix(definition, affix_value as Dictionary)
		if option != null:
			result.append(option)
	return result


static func _from_affix(definition: Resource, affix: Dictionary) -> EquipmentFixedOption:
	var stat_id := StringName(affix.get(&"stat_id", &""))
	var rolled_value := float(affix.get(&"rolled_value", 0.0))
	var affix_id := StringName(affix.get(&"affix_id", &""))
	if affix_id == &"" or stat_id == &"" or not is_finite(rolled_value) or rolled_value <= 0.0:
		return null
	var option := EquipmentFixedOption.new()
	option.option_id = StringName("rolled_%s" % String(affix_id))
	option.display_name = String(affix.get(&"display_name", "고정 옵션"))
	option.description = "획득 시 결정되며 내부·외부 레벨과 모듈 강화에 의해 변하지 않습니다."

	if definition is EquipmentWeaponDefinition:
		option.target_kind = EquipmentFixedOption.TargetKind.WEAPON
		match stat_id:
			&"damage_multiply":
				option.modifier_id = &"damage_multiply"
				option.operation = EquipmentFixedOption.Operation.MULTIPLY
				option.amount = 1.0 + rolled_value
			&"fire_interval_reduction":
				option.modifier_id = &"fire_interval_multiply"
				option.operation = EquipmentFixedOption.Operation.MULTIPLY
				option.amount = maxf(0.05, 1.0 - rolled_value)
			_:
				return null
	elif definition is EquipmentArmorDefinition:
		option.target_kind = EquipmentFixedOption.TargetKind.PLAYER
		match stat_id:
			&"max_health", &"defense", &"movement_speed":
				option.modifier_id = stat_id
				option.operation = EquipmentFixedOption.Operation.ADD
				option.amount = rolled_value
			_:
				return null
	else:
		return null

	return option if option.is_valid() else null
