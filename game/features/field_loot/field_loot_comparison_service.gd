class_name FieldLootComparisonService
extends RefCounted

var lifecycle_provider: Node
var equipment_provider: Node
var inventory_provider: Node


func configure(
	new_lifecycle_provider: Node,
	new_equipment_provider: Node,
	new_inventory_provider: Node
) -> bool:
	if (
		not _supports(new_lifecycle_provider, [&"get_definition"])
		or not _supports(new_equipment_provider, [&"get_summary"])
		or not _supports(new_inventory_provider, [&"get_snapshot"])
	):
		return false
	lifecycle_provider = new_lifecycle_provider
	equipment_provider = new_equipment_provider
	inventory_provider = new_inventory_provider
	return true


func compare(candidate: Dictionary) -> Dictionary:
	var item_id := StringName(candidate.get(&"item_id", &""))
	var definition := lifecycle_provider.call(&"get_definition", item_id) as LootLifecycleDefinition
	if definition == null:
		return {}
	var equipment: Dictionary = equipment_provider.call(&"get_summary")
	var inventory: Dictionary = inventory_provider.call(&"get_snapshot")
	var owned_count := _owned_count(inventory, item_id)
	var candidate_grade := maxi(1, int(candidate.get(&"grade", 1)))
	var reference_grade := _reference_grade(definition.item_type, equipment)
	var grade_delta := candidate_grade - reference_grade if reference_grade > 0 else 0
	var lifecycle := LootLifecyclePresenter.present(definition)
	var comparison_label := "신규 획득"
	if reference_grade > 0:
		comparison_label = "등급 %+d" % grade_delta if grade_delta != 0 else "동급"
	elif owned_count > 0:
		comparison_label = "보유 +%d" % int(candidate.get(&"quantity", 1))
	return {
		&"item_id": item_id,
		&"display_name": definition.display_name,
		&"item_type": definition.item_type,
		&"quantity": maxi(1, int(candidate.get(&"quantity", 1))),
		&"candidate_grade": candidate_grade,
		&"reference_grade": reference_grade,
		&"grade_delta": grade_delta,
		&"owned_count": owned_count,
		&"active_weapon_name": equipment.get(&"active_weapon_name", "없음"),
		&"comparison_label": comparison_label,
		&"family_label": lifecycle.get(&"family_label", ""),
		&"use_label": lifecycle.get(&"use_label", ""),
		&"extract_label": lifecycle.get(&"extract_label", ""),
		&"death_label": lifecycle.get(&"death_label", ""),
		&"description": definition.description,
		&"source_type": candidate.get(&"source_type", &"unknown"),
		&"entry_id": candidate.get(&"entry_id", &""),
	}


func _reference_grade(item_type: StringName, equipment: Dictionary) -> int:
	if item_type == &"weapon":
		return int(equipment.get(&"active_weapon_grade", 0))
	return 0


func _owned_count(inventory: Dictionary, item_id: StringName) -> int:
	var count := 0
	for item_variant in inventory.get(&"items", []):
		var item: Dictionary = item_variant
		if StringName(item.get(&"item_id", &"")) == item_id:
			count += 1
	return count


func _supports(candidate: Node, methods: Array[StringName]) -> bool:
	if not is_instance_valid(candidate):
		return false
	for method_name in methods:
		if not candidate.has_method(method_name):
			return false
	return true
