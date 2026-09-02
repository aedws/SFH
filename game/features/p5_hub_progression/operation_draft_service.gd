class_name OperationDraftService
extends RefCounted

var contracts: Node
var drafts: Dictionary = {}
var confirmed_ids: Dictionary = {}
var sequence := 0


func configure(contract_service: Node) -> bool:
	contracts = contract_service
	return is_instance_valid(contracts) and contracts.has_method(&"quote") and contracts.has_method(&"invest")


func create_draft(tier_config: Resource, penalty: Dictionary, context: Dictionary) -> Dictionary:
	var quote: Dictionary = contracts.call(&"quote", tier_config, penalty, context)
	if quote.is_empty():
		return {}
	quote = _with_break_even(quote)
	sequence += 1
	var draft_id := StringName("draft_%d_%d" % [Time.get_ticks_usec(), sequence])
	var fingerprint := _fingerprint(quote)
	var draft := {&"draft_id": draft_id, &"fingerprint": fingerprint,
		&"quote": quote.duplicate(true), &"confirmed": false}
	drafts[draft_id] = draft
	return draft.duplicate(true)


func confirm_draft(draft_id: StringName, tier_config: Resource,
		penalty: Dictionary, context: Dictionary) -> Dictionary:
	if confirmed_ids.has(draft_id):
		return {&"success": false, &"reason": "이미 확정된 작전"}
	var draft: Dictionary = drafts.get(draft_id, {})
	if draft.is_empty():
		return {&"success": false, &"reason": "작전 초안 없음"}
	var current_quote: Dictionary = contracts.call(&"quote", tier_config, penalty, context)
	if _fingerprint(current_quote) != String(draft.get(&"fingerprint", "")):
		return {&"success": false, &"reason": "선택 변경으로 견적 만료", &"stale": true}
	var result: Dictionary = contracts.call(&"invest", tier_config, penalty, context)
	if bool(result.get(&"success", false)):
		confirmed_ids[draft_id] = true
		drafts.erase(draft_id)
	return result


func get_snapshot() -> Dictionary:
	return {&"open_drafts": drafts.size(), &"confirmed_count": confirmed_ids.size()}


func _fingerprint(quote: Dictionary) -> String:
	return JSON.stringify({&"region": quote.get(&"region_id"), &"difficulty": quote.get(&"difficulty_id"),
		&"tier": quote.get(&"tier_id"), &"cost": quote.get(&"entry_cost"),
		&"investment": quote.get(&"investment_context", {})})


func _with_break_even(quote: Dictionary) -> Dictionary:
	var enriched := quote.duplicate(true)
	var reward_multiplier := maxf(0.01, float(quote.get(&"reward_multiplier", 1.0)))
	enriched[&"break_even_recovery_credits"] = ceili(float(quote.get(&"entry_cost", 0)) / reward_multiplier)
	return enriched
