class_name ShopInventoryDeliveryService
extends RefCounted
## Atomic adapter between rotating-shop offers and the grid-inventory public API.

const QUALITY_POLICY := preload(
	"res://game/features/p5_hub_progression/shop_item_quality_policy.gd"
)

var inventory: Node
var quality_catalog: Resource


func get_delivery_contract() -> Dictionary:
	return {&"version": 1, &"compensating_rollback": true}


func configure(inventory_provider: Node, configured_quality_catalog: Resource = null) -> bool:
	if not is_instance_valid(inventory_provider):
		return false
	for method_name in [
		&"get_item_definition", &"can_add_catalog_items", &"add_catalog_item",
		&"remove_item_instances", &"get_snapshot",
	]:
		if not inventory_provider.has_method(method_name):
			return false
	inventory = inventory_provider
	quality_catalog = (
		configured_quality_catalog
		if configured_quality_catalog != null else QUALITY_POLICY.default_catalog()
	)
	return (
		quality_catalog != null
		and quality_catalog.has_method(&"is_valid")
		and bool(quality_catalog.call(&"is_valid"))
	)


func preview(offer: Dictionary) -> Dictionary:
	if not is_instance_valid(inventory):
		return {&"can_deliver": false, &"reason": "가방 연결 끊김"}
	var target_id := StringName(offer.get(&"target_id", &""))
	var quantity := int(offer.get(&"quantity", 0))
	var definition: Resource = inventory.call(&"get_item_definition", target_id)
	if definition == null:
		return {&"can_deliver": false, &"reason": "가방 카탈로그에 없는 아이템"}
	var owned := 0
	for entry: Dictionary in inventory.call(&"get_snapshot").get(&"items", []):
		if StringName(entry.get(&"item_id", &"")) == target_id:
			owned += 1
	var can_deliver := bool(inventory.call(&"can_add_catalog_items", target_id, quantity))
	return {
		&"can_deliver": can_deliver,
		&"reason": "" if can_deliver else "가방 공간 부족",
		&"delivery": "가방 실물 아이템 지급",
		&"owned_quantity": owned,
		&"item_type": StringName(definition.get("item_type")),
	}


func deliver(offer: Dictionary, transaction_id: StringName) -> Dictionary:
	var check := preview(offer)
	if not bool(check.get(&"can_deliver", false)):
		return {&"success": false, &"reason": check.get(&"reason", "지급 불가")}
	var payload := QUALITY_POLICY.build_payload(offer, transaction_id, quality_catalog)
	if payload.is_empty():
		return {&"success": false, &"reason": "품질 데이터 오류"}
	var target_id := StringName(offer.get(&"target_id", &""))
	var instance_ids: Array[StringName] = []
	for _index in int(offer.get(&"quantity", 0)):
		var instance_id := StringName(inventory.call(
			&"add_catalog_item", target_id, payload
		))
		if instance_id == &"":
			var compensated := rollback({&"instance_ids": instance_ids})
			return {
				&"success": false,
				&"reason": (
					"가방 지급 중 공간 변경 감지"
					if compensated else "가방 지급 롤백 실패 · 결제 보류"
				),
				&"compensated": compensated,
				&"consistency_error": not compensated,
			}
		instance_ids.append(instance_id)
	return {
		&"success": true,
		&"granted": instance_ids.size(),
		&"instance_ids": instance_ids,
		&"runtime_payload": payload,
		&"delivery": check.get(&"delivery", "가방 실물 아이템 지급"),
	}


func rollback(receipt: Dictionary) -> bool:
	return (
		is_instance_valid(inventory)
		and bool(inventory.call(
			&"remove_item_instances", receipt.get(&"instance_ids", [])
		))
	)
