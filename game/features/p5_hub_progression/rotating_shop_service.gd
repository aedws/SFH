class_name RotatingShopService
extends RefCounted

const QUOTE_POLICY := preload("res://game/features/p5_hub_progression/shop_quote_policy.gd")
const ROTATION_STATE := preload("res://game/features/p5_hub_progression/shop_rotation_state.gd")
const REROLL_TRANSACTION := preload("res://game/features/p5_hub_progression/shop_reroll_transaction_service.gd")

var profile: Node
var offers: Array[Dictionary] = []
var reroll_price := 25
var slot_count := 3
var base_seed := 50507
var processed_transactions: Dictionary = {}
var delivery_provider
var quality_catalog: Resource
var rotation_policy: Resource
var rotation_state = ROTATION_STATE.new()
var reroll_transaction = REROLL_TRANSACTION.new()
var supply_policy := EquipmentSupplyPolicy.hub_default()

var rotation_index: int:
	get:
		return int(rotation_state.rotation_index)


func configure(profile_provider: Node, rows: Array[Dictionary], seed: int,
		price: int, slots: int, configured_quality_catalog: Resource = null,
		configured_rotation_policy: Resource = null) -> bool:
	rotation_state = ROTATION_STATE.new()
	reroll_transaction = REROLL_TRANSACTION.new()
	processed_transactions.clear()
	delivery_provider = null
	profile = profile_provider
	offers = rows.duplicate(true)
	quality_catalog = (
		configured_quality_catalog
		if configured_quality_catalog != null
		else preload("res://game/features/p5_hub_progression/shop_item_quality_policy.gd").default_catalog()
	)
	rotation_policy = (
		configured_rotation_policy
		if configured_rotation_policy != null
		else preload("res://game/features/p5_hub_progression/shop_rotation_policy.gd").new()
	)
	if (
		not is_instance_valid(profile)
		or offers.is_empty()
		or quality_catalog == null
		or not quality_catalog.has_method(&"is_valid")
		or not bool(quality_catalog.call(&"is_valid"))
		or rotation_policy == null
		or not rotation_policy.has_method(&"is_valid")
		or not bool(rotation_policy.call(&"is_valid"))
		or not bool(reroll_transaction.call(&"configure", profile))
	):
		return false
	base_seed = seed if seed != 0 else 50507
	reroll_price = maxi(0, price)
	slot_count = maxi(1, slots)
	return bool(refresh(false, &"", &"initial").get(&"success", false))


func refresh(paid: bool = false, transaction_id: StringName = &"",
		reason: StringName = &"manual") -> Dictionary:
	var previous_ids: Array[StringName] = []
	for offer in rotation_state.offers:
		previous_ids.append(StringName(offer.get(&"offer_id", &"")))
	var next_revision: int = int(rotation_state.rotation_index) + 1
	var proposal: Dictionary = rotation_policy.call(
		&"build_rotation", _eligible_offers(), quality_catalog.call(&"get_quality_ids"), slot_count,
		base_seed, next_revision, previous_ids
	)
	if not bool(proposal.get(&"success", false)):
		return proposal
	if paid:
		var debit: Dictionary = reroll_transaction.call(&"charge", transaction_id, _current_reroll_price())
		if not bool(debit.get(&"success", false)):
			return debit
	if not bool(rotation_state.call(
		&"apply", proposal.get(&"offers", []), reason,
		int(proposal.get(&"changed_count", 0))
	)):
		return {&"success": false, &"reason": "회전 상태 적용 실패"}
	if paid:
		rotation_state.call(&"record_paid_reroll")
	return {&"success": true, &"paid": paid, &"reason": reason, &"snapshot": get_snapshot()}


func begin_run(run_id: StringName) -> bool:
	return bool(rotation_state.call(&"begin_run", run_id))


func cancel_run() -> bool:
	return bool(rotation_state.call(&"cancel_run"))


func refresh_after_run() -> Dictionary:
	var completion: Dictionary = rotation_state.call(&"complete_run")
	if not bool(completion.get(&"success", false)):
		return {&"success": true, &"changed": false, &"snapshot": get_snapshot()}
	if bool(rotation_policy.get("reset_reroll_price_on_run_return")):
		rotation_state.call(&"reset_paid_rerolls")
	var result := refresh(false, &"", &"run_return")
	result[&"changed"] = bool(result.get(&"success", false))
	result[&"run_id"] = completion.get(&"run_id", &"")
	return result


func quote_reroll() -> Dictionary:
	var result: Dictionary = reroll_transaction.call(&"quote", _current_reroll_price())
	result[&"rotation_index"] = rotation_state.rotation_index
	result[&"paid_reroll_count"] = rotation_state.paid_reroll_count
	return result


func _current_reroll_price() -> int:
	return int(rotation_policy.call(
		&"reroll_price", reroll_price, int(rotation_state.paid_reroll_count)
	))


func quote(offer_id: StringName) -> Dictionary:
	var offer := _find_rotation(offer_id)
	var delivery_preview: Dictionary = (
		delivery_provider.call(&"preview", offer)
		if delivery_provider != null else {}
	)
	return QUOTE_POLICY.quote(
		offer, offers, profile.call(&"get_snapshot"), rotation_index, delivery_preview,
		quality_catalog
	)


func set_delivery_provider(provider) -> bool:
	if provider != null:
		for method_name in [&"get_delivery_contract", &"preview", &"deliver", &"rollback"]:
			if not provider.has_method(method_name):
				return false
		var contract: Dictionary = provider.call(&"get_delivery_contract")
		if (
			int(contract.get(&"version", 0)) != 1
			or not bool(contract.get(&"compensating_rollback", false))
		):
			return false
	delivery_provider = provider
	return true


func purchase(offer_id: StringName, transaction_id: StringName, expected_rotation: int = -1) -> Dictionary:
	if transaction_id == &"" or processed_transactions.has(transaction_id) or bool(profile.call(&"has_processed_transaction", transaction_id)):
		return {&"success": false, &"reason": "중복 구매"}
	if expected_rotation >= 0 and expected_rotation != rotation_index:
		return {&"success": false, &"reason": "매물이 갱신됐습니다 · 다시 선택하세요"}
	var current_quote := quote(offer_id)
	if not bool(current_quote.get(&"purchasable", false)):
		return {&"success": false, &"reason": current_quote.get(&"reason", "구매 불가")}
	var offer: Dictionary = current_quote[&"offer"]
	if not bool(profile.call(&"spend", int(offer.get(&"price", 0)))):
		return {&"success": false, &"reason": "크레딧 부족"}
	if delivery_provider != null:
		var receipt: Dictionary = delivery_provider.call(
			&"deliver", offer, transaction_id
		)
		if not bool(receipt.get(&"success", false)):
			var consistency_error := bool(receipt.get(&"consistency_error", false))
			if consistency_error:
				processed_transactions[transaction_id] = true
			else:
				profile.call(&"add_credits", int(offer.get(&"price", 0)))
			return {&"success": false, &"reason": receipt.get(&"reason", "지급 실패")}
		if not bool(profile.call(&"mark_transaction_processed", transaction_id)):
			var compensated := bool(delivery_provider.call(&"rollback", receipt))
			if compensated:
				profile.call(&"add_credits", int(offer.get(&"price", 0)))
			else:
				processed_transactions[transaction_id] = true
			return {
				&"success": false,
				&"reason": (
					"구매 거래 기록 실패"
					if compensated else "지급 롤백 실패 · 결제 보류"
				),
				&"compensated": compensated,
				&"consistency_error": not compensated,
			}
		processed_transactions[transaction_id] = true
		return {
			&"success": true, &"offer": offer,
			&"granted": int(receipt.get(&"granted", 0)), &"delivery": receipt,
		}
	var granted := int(profile.call(&"add_warehouse_item", StringName(offer.get(&"target_id", &"")), int(offer.get(&"quantity", 1))))
	if granted <= 0:
		profile.call(&"add_credits", int(offer.get(&"price", 0)))
		return {&"success": false, &"reason": "지급 실패"}
	if not bool(profile.call(&"mark_transaction_processed", transaction_id)):
		profile.call(&"take_warehouse_item", StringName(offer.get(&"target_id", &"")), granted)
		profile.call(&"add_credits", int(offer.get(&"price", 0)))
		return {&"success": false, &"reason": "구매 거래 기록 실패"}
	processed_transactions[transaction_id] = true
	return {&"success": true, &"offer": offer, &"granted": granted}


func get_snapshot() -> Dictionary:
	var quotes: Array[Dictionary] = []
	var visible_offers: Array[Dictionary] = []
	for offer in rotation_state.offers:
		if not _supply_allowed(offer): continue
		visible_offers.append(offer.duplicate(true))
		quotes.append(quote(StringName(offer.get(&"offer_id", &""))))
	var state_snapshot: Dictionary = rotation_state.call(&"get_snapshot")
	return {&"rotation_index": rotation_index, &"offers": visible_offers,
		&"reroll_price": _current_reroll_price(), &"quality_count": _quality_count(), &"quotes": quotes,
		&"credits": int(profile.call(&"get_snapshot").get(&"banked_credits", 0)),
		&"reroll_quote": quote_reroll(),
		&"active_run_id": state_snapshot.get(&"active_run_id", &""),
		&"last_refresh_reason": state_snapshot.get(&"last_refresh_reason", &"initial"),
		&"last_changed_count": state_snapshot.get(&"last_changed_count", 0)}

func _eligible_offers() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for offer in offers:
		if _supply_allowed(offer): result.append(offer)
	return result

func _supply_allowed(offer: Dictionary) -> bool:
	if not supply_policy.source_error(offer).is_empty(): return false
	if delivery_provider != null:
		return not bool(delivery_provider.call(&"preview", offer).get(&"supply_blocked", false))
	return true


func _quality_count() -> int:
	var ids := {}
	for row in rotation_state.offers:
		if not _supply_allowed(row): continue
		ids[row.get(&"quality", &"")] = true
	return ids.size()


func _find_rotation(offer_id: StringName) -> Dictionary:
	for offer in rotation_state.offers:
		if StringName(offer.get(&"offer_id", &"")) == offer_id:
			return offer
	return {}
