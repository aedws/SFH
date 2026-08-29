class_name EquipmentLoadout
extends Resource

const MAX_SKILLS := 10

@export var loadout_id: StringName
@export var display_name: String
@export var main_weapon: EquipmentWeaponDefinition
@export var secondary_weapon: EquipmentWeaponDefinition
@export var skills: Array[EquipmentSkillDefinition] = []
@export var armor: Array[EquipmentArmorDefinition] = []
@export var extension_data: Dictionary = {}


func validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if loadout_id == &"" or display_name.is_empty():
		errors.append("로드아웃 ID와 표시 이름이 필요합니다.")
	if main_weapon != null and not main_weapon.is_valid():
		errors.append("메인 무기 정의가 유효하지 않습니다.")
	if secondary_weapon != null and not secondary_weapon.is_valid():
		errors.append("보조 무기 정의가 유효하지 않습니다.")
	if skills.size() > MAX_SKILLS:
		errors.append("스킬은 최대 %d개까지 장착할 수 있습니다." % MAX_SKILLS)

	var skill_ids: Dictionary = {}
	for skill in skills:
		if skill == null or not skill.is_valid():
			errors.append("유효하지 않은 스킬 정의가 있습니다.")
			continue
		if skill_ids.has(skill.skill_id):
			errors.append("중복 스킬 ID입니다: %s" % skill.skill_id)
		skill_ids[skill.skill_id] = true

	var armor_slots: Dictionary = {}
	for armor_item in armor:
		if armor_item == null or not armor_item.is_valid():
			errors.append("유효하지 않은 방어구 정의가 있습니다.")
			continue
		if armor_slots.has(armor_item.slot_id):
			errors.append("방어구 슬롯이 중복됩니다: %s" % armor_item.slot_id)
		armor_slots[armor_item.slot_id] = true
	return errors


func is_valid() -> bool:
	return validation_errors().is_empty()
