class_name FieldLootEquipCatalog
extends Resource

const DESTINATIONS := [&"run_storage", &"world_drop", &"lost"]

@export var entries: Array[FieldLootEquipEntry] = []
@export var skill_entries: Array[FieldLootSkillEntry] = []
@export_enum("run_storage", "world_drop", "lost") var replaced_item_destination := "run_storage"
@export_enum("provisional", "confirmed") var policy_status := "provisional"


func validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	var seen := {}
	if StringName(replaced_item_destination) not in DESTINATIONS:
		errors.append("기존 장비 처리 정책이 올바르지 않습니다.")
	for entry in entries:
		if entry == null:
			errors.append("비어 있는 현장 장착 항목이 있습니다.")
			continue
		for message in entry.validation_errors():
			errors.append("%s: %s" % [entry.item_id, message])
		if seen.has(entry.item_id):
			errors.append("현장 장착 item_id가 중복됩니다: %s" % entry.item_id)
		seen[entry.item_id] = true
	for entry in skill_entries:
		if entry == null:
			errors.append("비어 있는 현장 스킬 항목이 있습니다.")
			continue
		for message in entry.validation_errors():
			errors.append("%s: %s" % [entry.item_id, message])
		if seen.has(entry.item_id):
			errors.append("현장 장착 item_id가 중복됩니다: %s" % entry.item_id)
		seen[entry.item_id] = true
	return errors


func get_entry(item_id: StringName) -> FieldLootEquipEntry:
	for entry in entries:
		if entry != null and entry.item_id == item_id:
			return entry
	return null


func get_definition(item_id: StringName) -> LootLifecycleDefinition:
	var entry := get_entry(item_id)
	if entry != null:
		return entry.to_lifecycle_definition()
	var skill_entry := get_skill_entry(item_id)
	return skill_entry.to_lifecycle_definition() if skill_entry != null else null


func get_skill_entry(item_id: StringName) -> FieldLootSkillEntry:
	for entry in skill_entries:
		if entry != null and entry.item_id == item_id:
			return entry
	return null


func destination_label() -> String:
	return {
		&"run_storage": "기존 장비 → 런 임시 보관",
		&"world_drop": "기존 장비 → 현장 드랍",
		&"lost": "기존 장비 → 소실",
	}.get(StringName(replaced_item_destination), "기존 장비 처리 미정")


func get_snapshot() -> Dictionary:
	var item_snapshots: Array[Dictionary] = []
	for entry in entries:
		if entry != null:
			item_snapshots.append(entry.get_snapshot())
	var skill_snapshots: Array[Dictionary] = []
	for entry in skill_entries:
		if entry != null:
			skill_snapshots.append(entry.get_snapshot())
	return {
		&"entry_count": item_snapshots.size() + skill_snapshots.size(),
		&"weapon_entry_count": item_snapshots.size(),
		&"skill_entry_count": skill_snapshots.size(),
		&"entries": item_snapshots,
		&"skill_entries": skill_snapshots,
		&"replaced_item_destination": StringName(replaced_item_destination),
		&"destination_label": destination_label(),
		&"policy_status": StringName(policy_status),
	}
