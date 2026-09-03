class_name RotatingShopService
extends RefCounted

const QUOTE_POLICY := preload("res://game/features/p5_hub_progression/shop_quote_policy.gd")

var profile: Node
var offers: Array[Dictionary] = []
var rotation: Array[Dictionary] = []
var random := RandomNumberGenerator.new()
var reroll_price := 25
var slot_count := 3
var rotation_index := 0
var processed_transactions: Dictionary = {}


func configure(profile_provider: Node, rows: Array[Dictionary], seed: int,
		price: int, slots: int) -> bool:
	profile = profile_provider
	offers = rows.duplicate(true)
	random.seed = seed if seed != 0 else 50507
	reroll_price = maxi(0, price)
	slot_count = maxi(1, slots)
	refresh(false)
	return is_instance_valid(profile) and not offers.is_empty()


func refresh(paid: bool = false, transaction_id: StringName = &"") -> Dictionary:
	if paid:
		if transaction_id == &"" or processed_transactions.has(transaction_id) or bool(profile.call(&"has_processed_transaction", transaction_id)):
			return {&"success": false, &"reason": "중복 새로고침"}
		if not bool(profile.call(&"spend", reroll_price)):
			return {&"success": false, &"reason": "크레딧 부족"}
		if not bool(profile.call(&"mark_transaction_processed", transaction_id)):
			profile.call(&"add_credits", reroll_price)
			return {&"success": false, &"reason": "새로고침 거래 기록 실패"}
		processed_transactions[transaction_id] = true
	rotation_index += 1
	rotation.clear()
	var qualities := [&"damaged", &"standard", &"high_performance"]
	for quality in qualities:
		var candidates := offers.filter(func(row): return StringName(row.get(&"quality", &"")) == quality)
		if not candidates.is_empty() and rotation.size() < slot_count:
			rotation.append(candidates[random.randi_range(0, candidates.size() - 1)].duplicate(true))
	for offer in offers:
		if rotation.size() >= slot_count:
			break
		if StringName(offer.get(&"offer_id", &"")) not in rotation.map(func(row): return StringName(row.get(&"offer_id", &""))):
			rotation.append(offer.duplicate(true))
	return {&"success": true, &"paid": paid, &"snapshot": get_snapshot()}


func quote(offer_id: StringName) -> Dictionary:
	return QUOTE_POLICY.quote(_find_rotation(offer_id), offers, profile.call(&"get_snapshot"), rotation_index)


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
	for offer in rotation:
		quotes.append(quote(StringName(offer.get(&"offer_id", &""))))
	return {&"rotation_index": rotation_index, &"offers": rotation.duplicate(true),
		&"reroll_price": reroll_price, &"quality_count": _quality_count(), &"quotes": quotes,
		&"credits": int(profile.call(&"get_snapshot").get(&"banked_credits", 0))}


func _quality_count() -> int:
	var ids := {}
	for row in rotation:
		ids[row.get(&"quality", &"")] = true
	return ids.size()


func _find_rotation(offer_id: StringName) -> Dictionary:
	for offer in rotation:
		if StringName(offer.get(&"offer_id", &"")) == offer_id:
			return offer
	return {}
