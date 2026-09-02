class_name RotatingShopService
extends RefCounted

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


func purchase(offer_id: StringName, transaction_id: StringName) -> Dictionary:
	if transaction_id == &"" or processed_transactions.has(transaction_id) or bool(profile.call(&"has_processed_transaction", transaction_id)):
		return {&"success": false, &"reason": "중복 구매"}
	var offer := _find_rotation(offer_id)
	if offer.is_empty():
		return {&"success": false, &"reason": "현재 회전 상품 아님"}
	var unlock_id := StringName(offer.get(&"required_unlock_id", &""))
	if unlock_id != &"" and not bool(profile.call(&"is_unlocked", unlock_id)):
		return {&"success": false, &"reason": "해금 조건 미달"}
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
	return {&"rotation_index": rotation_index, &"offers": rotation.duplicate(true),
		&"reroll_price": reroll_price, &"quality_count": _quality_count()}


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
