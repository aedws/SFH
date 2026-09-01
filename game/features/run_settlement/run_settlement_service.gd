class_name RunSettlementService
extends Node

signal run_loot_settled(result: Dictionary)

var lifecycle_provider: Node
var profile_provider: Node
var unlock_policy: Resource
var processed_results: Dictionary = {}
var last_result: Dictionary = {}


func configure(
	new_lifecycle_provider: Node,
	new_profile_provider: Node,
	new_unlock_policy: Resource
) -> bool:
	if (
		not _supports(new_lifecycle_provider, [&"resolve_outcome", &"get_definition"])
		or not _supports(new_profile_provider, [
			&"add_credits", &"add_warehouse_item", &"add_blueprint",
			&"register_shop_offer", &"get_snapshot",
		])
		or new_unlock_policy == null
		or not new_unlock_policy.has_method(&"shop_offer_for")
	):
		return false
	lifecycle_provider = new_lifecycle_provider
	profile_provider = new_profile_provider
	unlock_policy = new_unlock_policy
	return true


func settle(run_id: StringName, acquired_items: Dictionary, extracted: bool) -> Dictionary:
	if run_id == &"":
		return {&"success": false, &"reason": &"missing_run_id"}
	if processed_results.has(run_id):
		var duplicate: Dictionary = (processed_results[run_id] as Dictionary).duplicate(true)
		duplicate[&"duplicate_ignored"] = true
		return duplicate
	var converted_credits := 0
	var wallet_credits := 0
	var warehouse_items: Dictionary = {}
	var permanent_unlocks: Dictionary = {}
	var shop_offers: Array[StringName] = []
	var expired_items: Dictionary = {}
	var lost_items: Dictionary = {}
	var outcomes: Array[Dictionary] = []
	var item_ids := acquired_items.keys()
	item_ids.sort_custom(func(left, right): return String(left) < String(right))
	for item_key in item_ids:
		var item_id := StringName(item_key)
		var entry: Dictionary = acquired_items.get(item_key, {})
		var quantity := maxi(1, int(entry.get(&"quantity", 1)))
		var outcome: Dictionary = lifecycle_provider.call(&"resolve_outcome", item_id, extracted)
		if outcome.is_empty():
			outcome = {&"item_id": item_id, &"result": &"lost", &"retained": false}
		outcome[&"quantity"] = quantity
		var result_id := StringName(outcome.get(&"result", &"lost"))
		match result_id:
			&"auto_convert":
				var credits := maxi(0, int(outcome.get(&"credit_value", 0))) * quantity
				converted_credits += credits
				outcome[&"applied_credits"] = credits
			&"wallet":
				wallet_credits += quantity
				outcome[&"applied_credits"] = quantity
			&"warehouse":
				warehouse_items[item_id] = int(warehouse_items.get(item_id, 0)) + quantity
			&"permanent_unlock":
				permanent_unlocks[item_id] = int(permanent_unlocks.get(item_id, 0)) + quantity
				var offer_id := StringName(unlock_policy.call(&"shop_offer_for", item_id))
				if offer_id != &"" and offer_id not in shop_offers:
					shop_offers.append(offer_id)
			_:
				var terminal_items := expired_items if extracted else lost_items
				terminal_items[item_id] = int(terminal_items.get(item_id, 0)) + quantity
		outcomes.append(outcome)
	if converted_credits + wallet_credits > 0:
		profile_provider.call(&"add_credits", converted_credits + wallet_credits)
	for item_id in warehouse_items:
		profile_provider.call(&"add_warehouse_item", item_id, int(warehouse_items[item_id]))
	for blueprint_id in permanent_unlocks:
		profile_provider.call(&"add_blueprint", blueprint_id, int(permanent_unlocks[blueprint_id]))
	for offer_id in shop_offers:
		profile_provider.call(&"register_shop_offer", offer_id)
	last_result = {
		&"success": true,
		&"run_id": run_id,
		&"extracted": extracted,
		&"duplicate_ignored": false,
		&"converted_credits": converted_credits,
		&"wallet_credits": wallet_credits,
		&"warehouse_items": warehouse_items,
		&"permanent_unlocks": permanent_unlocks,
		&"registered_shop_offers": shop_offers,
		&"expired_items": expired_items,
		&"lost_items": lost_items,
		&"outcomes": outcomes,
		&"profile": profile_provider.call(&"get_snapshot"),
	}
	processed_results[run_id] = last_result.duplicate(true)
	run_loot_settled.emit(last_result.duplicate(true))
	return last_result.duplicate(true)


func get_snapshot() -> Dictionary:
	return {
		&"processed_run_count": processed_results.size(),
		&"processed_run_ids": processed_results.keys(),
		&"last_result": last_result.duplicate(true),
		&"idempotent": true,
		&"lifecycle_driven": true,
		&"profile_mutation_only": true,
	}


func _supports(candidate: Node, methods: Array[StringName]) -> bool:
	if not is_instance_valid(candidate):
		return false
	for method_name in methods:
		if not candidate.has_method(method_name):
			return false
	return true
