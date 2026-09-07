class_name CharacterModuleDefinition
extends Resource
## Account-character carrier. Not armor, not loot; external character XP owns its level.
@export var display_name := "캐릭터 · 공용 모듈"
@export var maximum_level := 40
@export var module_slot_limit := 4
@export var module_cost_limit := 12
@export var fixed_options: Array[EquipmentFixedOption] = []

func is_valid() -> bool:
	return maximum_level > 1 and module_slot_limit > 0 and module_cost_limit >= 0
