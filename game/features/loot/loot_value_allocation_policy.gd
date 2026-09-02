class_name LootValueAllocationPolicy
extends RefCounted


func allocate(config: Resource, deployment_cost: int, random: RandomNumberGenerator) -> Dictionary:
	if config == null or deployment_cost < 0 or random == null:
		return {&"success": false, &"reason": "회수 가치 정책 입력 오류"}
	var minimum_total := ceili(
		float(deployment_cost) * float(config.get("minimum_deployment_value_multiplier"))
	)
	var maximum_total := floori(
		float(deployment_cost) * float(config.get("maximum_deployment_value_multiplier"))
	)
	var minimum_multiplier := float(config.get("minimum_deployment_value_multiplier"))
	var maximum_multiplier := float(config.get("maximum_deployment_value_multiplier"))
	var selected_multiplier := (
		clampf(
			snappedf(random.randf_range(minimum_multiplier, maximum_multiplier), 0.1),
			minimum_multiplier,
			maximum_multiplier
		)
		if deployment_cost > 0 else 0.0
	)
	var target_total := (
		clampi(
			ceili(float(deployment_cost) * selected_multiplier),
			minimum_total,
			maximum_total
		)
		if deployment_cost > 0
		else int(config.get("minimum_cache_count")) * int(config.get("minimum_cache_credits"))
	)
	var minimum_count := int(config.get("minimum_cache_count"))
	var maximum_count := int(config.get("maximum_cache_count"))
	var base_minimum_value := int(config.get("minimum_cache_credits"))
	var base_maximum_value := int(config.get("maximum_cache_credits"))
	var effective_minimum_value := mini(base_minimum_value, maxi(0, target_total / maxi(1, minimum_count)))
	var effective_maximum_value := maxi(
		base_maximum_value,
		ceili(float(target_total) / float(maxi(1, minimum_count)))
	)
	var required_count := ceili(float(target_total) / float(maxi(1, effective_maximum_value)))
	var affordable_count := (
		floori(float(target_total) / float(effective_minimum_value))
		if effective_minimum_value > 0 else maximum_count
	)
	var allowed_minimum_count := maxi(minimum_count, required_count)
	var allowed_maximum_count := mini(maximum_count, affordable_count)
	if allowed_minimum_count > allowed_maximum_count:
		return {&"success": false, &"reason": "회수 지점 수·가치 배분 불가"}
	var cache_count := random.randi_range(allowed_minimum_count, allowed_maximum_count)
	return {
		&"success": true,
		&"deployment_cost": deployment_cost,
		&"minimum_total_credits": minimum_total,
		&"maximum_total_credits": maximum_total,
		&"target_total_credits": target_total,
		&"selected_value_multiplier": selected_multiplier,
		&"cache_count": cache_count,
		&"minimum_cache_credits": effective_minimum_value,
		&"maximum_cache_credits": effective_maximum_value,
		&"per_cache_value_scaled": effective_maximum_value > base_maximum_value,
	}


func build_credit_amounts(
	count: int,
	minimum_value: int,
	maximum_value: int,
	target_total: int,
	random: RandomNumberGenerator
) -> PackedInt32Array:
	var amounts := PackedInt32Array()
	if count <= 0 or minimum_value < 0 or maximum_value < minimum_value:
		return amounts
	for _index in range(count):
		amounts.append(random.randi_range(minimum_value, maximum_value))
	var indices: Array[int] = []
	for index in range(count):
		indices.append(index)
	indices.shuffle()
	var difference := target_total - _sum(amounts)
	if difference > 0:
		for index in indices:
			if difference <= 0:
				break
			var added := mini(difference, maximum_value - amounts[index])
			amounts[index] += added
			difference -= added
	elif difference < 0:
		var surplus := -difference
		for index in indices:
			if surplus <= 0:
				break
			var removed := mini(surplus, amounts[index] - minimum_value)
			amounts[index] -= removed
			surplus -= removed
	return amounts


func _sum(amounts: PackedInt32Array) -> int:
	var total := 0
	for amount in amounts:
		total += amount
	return total
