class_name EquipmentUpgradeService
extends Node

signal upgrade_completed(result: Dictionary)
signal upgrade_rejected(reason: String)

const EQUIPMENT_METHODS := [&"get_upgrade_context", &"upgrade_module", &"upgrade_part"]
const INVENTORY_METHODS := [&"find_instance_ids_by_resource", &"consume_linked_resource"]
const WALLET_METHODS := [&"can_spend_carried", &"spend_carried", &"get_snapshot"]

var equipment_provider: Node
var inventory_provider: Node
var wallet_provider: Node
var policy: Resource
var balance_provider: Node


func configure(
	new_equipment_provider: Node,
	new_inventory_provider: Node,
	new_wallet_provider: Node,
	new_policy: Resource
) -> bool:
	if not _supports_methods(new_equipment_provider, EQUIPMENT_METHODS):
		push_error("강화 서비스에 장비 공개 계약이 필요합니다.")
		return false
	if not _supports_methods(new_inventory_provider, INVENTORY_METHODS):
		push_error("강화 서비스에 인벤토리 소비 계약이 필요합니다.")
		return false
	if not _supports_methods(new_wallet_provider, WALLET_METHODS):
		push_error("강화 서비스에 크레딧 소비 계약이 필요합니다.")
		return false
	if (
		new_policy == null
		or not new_policy.has_method(&"validation_errors")
		or not new_policy.call(&"validation_errors").is_empty()
	):
		push_error("유효한 장비 강화 비용 정책이 필요합니다.")
		return false
	equipment_provider = new_equipment_provider
	inventory_provider = new_inventory_provider
	wallet_provider = new_wallet_provider
	policy = new_policy
	return true


func set_balance_provider(provider: Node) -> bool:
	if provider != null and not provider.has_method(&"quote_upgrade"):
		return false
	balance_provider = provider
	return true


func quote_upgrade(
	target_kind: StringName,
	slot_id: StringName,
	target_id: StringName
) -> Dictionary:
	if target_kind not in [&"module", &"part"]:
		return {}
	var context: Dictionary = equipment_provider.call(
		&"get_upgrade_context", target_kind, slot_id, target_id
	)
	if context.is_empty() or int(context[&"current_level"]) >= int(context[&"maximum_level"]):
		return {}
	var result := context.duplicate(true)
	var balance_target_id: StringName = context.get(&"balance_target_id", target_id)
	var policy_quote: Dictionary = {}
	if balance_provider != null:
		policy_quote = balance_provider.call(
			&"quote_upgrade", target_kind, balance_target_id, int(context[&"current_level"])
		)
	if policy_quote.is_empty():
		policy_quote = policy.call(&"quote", target_kind, int(context[&"current_level"]), balance_target_id)
	result.merge(policy_quote, true)
	var material_ids: PackedStringArray = inventory_provider.call(
		&"find_instance_ids_by_resource", context[&"material_resource"]
	)
	result[&"available_materials"] = material_ids.size()
	var wallet_snapshot: Dictionary = wallet_provider.call(&"get_snapshot")
	result[&"available_credits"] = int(wallet_snapshot.get(&"carried", 0))
	result[&"can_upgrade"] = (
		material_ids.size() >= int(result[&"material_quantity"])
		and wallet_provider.call(&"can_spend_carried", int(result[&"credit_cost"]))
	)
	return result


func upgrade(
	target_kind: StringName,
	slot_id: StringName,
	target_id: StringName
) -> bool:
	var quote := quote_upgrade(target_kind, slot_id, target_id)
	if quote.is_empty():
		upgrade_rejected.emit("강화할 수 없는 대상입니다.")
		return false
	if not bool(quote[&"can_upgrade"]):
		upgrade_rejected.emit("동일 아이템 재료 또는 크레딧이 부족합니다.")
		return false
	var method_name := &"upgrade_module" if target_kind == &"module" else &"upgrade_part"
	if not equipment_provider.call(method_name, slot_id, target_id):
		upgrade_rejected.emit("장비 모듈이 강화를 거부했습니다.")
		return false
	if not inventory_provider.call(
		&"consume_linked_resource",
		quote[&"material_resource"],
		int(quote[&"material_quantity"])
	):
		upgrade_rejected.emit("강화 재료 소비에 실패했습니다.")
		return false
	if not wallet_provider.call(&"spend_carried", int(quote[&"credit_cost"])):
		upgrade_rejected.emit("크레딧 소비에 실패했습니다.")
		return false
	var result := quote.duplicate(true)
	result[&"new_level"] = int(quote[&"current_level"]) + 1
	upgrade_completed.emit(result)
	return true


func _supports_methods(candidate: Node, methods: Array) -> bool:
	if candidate == null:
		return false
	for method_name in methods:
		if not candidate.has_method(method_name):
			return false
	return true
