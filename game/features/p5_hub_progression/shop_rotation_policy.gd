class_name ShopRotationPolicy
extends Resource

@export_range(1, 1000000, 1) var revision_seed_stride := 7919
@export var guarantee_quality_coverage := true
@export var avoid_previous_offers := true
@export_range(0, 10000, 1) var reroll_price_step := 0
@export_range(0, 100000, 1) var reroll_price_cap := 0
@export var reset_reroll_price_on_run_return := true


func is_valid() -> bool:
	return revision_seed_stride > 0 and reroll_price_step >= 0 and reroll_price_cap >= 0


func reroll_price(base_price: int, paid_reroll_count: int) -> int:
	var price := maxi(0, base_price) + maxi(0, paid_reroll_count) * reroll_price_step
	return mini(price, reroll_price_cap) if reroll_price_cap > 0 else price


func build_rotation(offers: Array[Dictionary], quality_ids: Array[StringName], slot_count: int,
		base_seed: int, next_revision: int, previous_offer_ids: Array[StringName]) -> Dictionary:
	if offers.is_empty() or slot_count <= 0 or not is_valid():
		return {&"success": false, &"reason": "회전 정책 구성 오류"}
	var random := RandomNumberGenerator.new()
	random.seed = (base_seed if base_seed != 0 else 50507) + next_revision * revision_seed_stride
	var available: Array[Dictionary] = []
	for offer in offers:
		if bool(offer.get(&"runtime_enabled", true)):
			available.append(offer.duplicate(true))
	if available.is_empty():
		return {&"success": false, &"reason": "사용 가능한 상점 매물이 없습니다"}
	var selected: Array[Dictionary] = []
	if guarantee_quality_coverage:
		for quality_id in quality_ids:
			if selected.size() >= slot_count:
				break
			var candidates: Array[Dictionary] = []
			for offer in available:
				if StringName(offer.get(&"quality", &"")) == quality_id:
					candidates.append(offer)
			var picked := _pick_weighted(candidates, selected, previous_offer_ids, random)
			if not picked.is_empty():
				selected.append(picked)
	while selected.size() < mini(slot_count, available.size()):
		var picked := _pick_weighted(available, selected, previous_offer_ids, random)
		if picked.is_empty():
			break
		selected.append(picked)
	var selected_ids := _offer_ids(selected)
	var changed_count := 0
	for offer_id in selected_ids:
		if offer_id not in previous_offer_ids:
			changed_count += 1
	return {
		&"success": not selected.is_empty(),
		&"offers": selected,
		&"seed": random.seed,
		&"changed_count": changed_count,
	}


func _pick_weighted(candidates: Array[Dictionary], selected: Array[Dictionary],
		previous_offer_ids: Array[StringName], random: RandomNumberGenerator) -> Dictionary:
	var selected_ids := _offer_ids(selected)
	var pool: Array[Dictionary] = []
	for candidate in candidates:
		var offer_id := StringName(candidate.get(&"offer_id", &""))
		if offer_id != &"" and offer_id not in selected_ids:
			pool.append(candidate)
	if pool.is_empty():
		return {}
	if avoid_previous_offers:
		var fresh: Array[Dictionary] = []
		for candidate in pool:
			if StringName(candidate.get(&"offer_id", &"")) not in previous_offer_ids:
				fresh.append(candidate)
		if not fresh.is_empty():
			pool = fresh
	var total_weight := 0
	for candidate in pool:
		total_weight += maxi(1, int(candidate.get(&"rotation_weight", 1)))
	var roll := random.randi_range(1, total_weight)
	for candidate in pool:
		roll -= maxi(1, int(candidate.get(&"rotation_weight", 1)))
		if roll <= 0:
			return candidate.duplicate(true)
	return pool.back().duplicate(true)


func _offer_ids(rows: Array[Dictionary]) -> Array[StringName]:
	var result: Array[StringName] = []
	for row in rows:
		result.append(StringName(row.get(&"offer_id", &"")))
	return result
