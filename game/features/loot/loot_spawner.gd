class_name LootSpawner
extends Node

signal credits_looted(amount: int, world_position: Vector2)
signal interaction_availability_changed(available: bool, prompt: String)

@export var loot_cache_scene: PackedScene

var spawned_cache_count: int = 0
var total_placed_credits: int = 0
var minimum_total_credits: int = 0
var maximum_total_credits: int = 0
var target_total_credits: int = 0
var selected_value_multiplier: float = 0.0
var deployment_cost: int = 0
var random := RandomNumberGenerator.new()


func _ready() -> void:
	random.randomize()


func configure(
	map_provider: Node,
	loot_parent: Node2D,
	config: LootTierConfig,
	new_deployment_cost: int = 0
) -> bool:
	if (
		not is_instance_valid(map_provider)
		or not map_provider.has_method(&"get_loot_spawn_points")
		or not is_instance_valid(loot_parent)
		or config == null
		or new_deployment_cost < 0
	):
		push_error("LootSpawner 구성에 맵, 부모 Node2D, 등급 Resource가 필요합니다.")
		return false

	if not config.is_valid():
		push_error("LootTierConfig 값이 유효하지 않습니다.")
		return false
	spawned_cache_count = 0
	total_placed_credits = 0
	deployment_cost = new_deployment_cost
	minimum_total_credits = ceili(
		float(deployment_cost) * config.minimum_deployment_value_multiplier
	)
	maximum_total_credits = floori(
		float(deployment_cost) * config.maximum_deployment_value_multiplier
	)
	selected_value_multiplier = clampf(
		snappedf(random.randf_range(
			config.minimum_deployment_value_multiplier,
			config.maximum_deployment_value_multiplier
		), 0.1),
		config.minimum_deployment_value_multiplier,
		config.maximum_deployment_value_multiplier
	)
	target_total_credits = clampi(
		ceili(float(deployment_cost) * selected_value_multiplier),
		minimum_total_credits,
		maximum_total_credits
	)
	var minimum_count := config.minimum_cache_count
	var maximum_count := config.maximum_cache_count
	var required_count := 0
	if target_total_credits > 0 and config.maximum_cache_credits > 0:
		required_count = ceili(
			float(target_total_credits) / float(config.maximum_cache_credits)
		)
	var affordable_count := maximum_count
	if config.minimum_cache_credits > 0:
		affordable_count = floori(
			float(target_total_credits) / float(config.minimum_cache_credits)
		)
	var allowed_minimum_count := maxi(minimum_count, required_count)
	var allowed_maximum_count := mini(maximum_count, affordable_count)
	if allowed_minimum_count > allowed_maximum_count:
		push_error("회수 지점 수·가치 범위로 선택된 배수 목표를 구성할 수 없습니다.")
		return false
	var cache_count := random.randi_range(allowed_minimum_count, allowed_maximum_count)
	var spawn_points: Array = map_provider.call(&"get_loot_spawn_points", cache_count)
	if spawn_points.size() < cache_count:
		push_error("맵이 선택된 배수 목표에 필요한 회수 위치를 제공하지 못했습니다.")
		return false
	var credit_amounts := _build_credit_amounts(
		spawn_points.size(), config, target_total_credits
	)
	for index in range(spawn_points.size()):
		_spawn_cache(
			loot_parent,
			spawn_points[index],
			credit_amounts[index]
		)
	return total_placed_credits == target_total_credits


func get_spawn_snapshot() -> Dictionary:
	return {
		&"deployment_cost": deployment_cost,
		&"minimum_total_credits": minimum_total_credits,
		&"maximum_total_credits": maximum_total_credits,
		&"target_total_credits": target_total_credits,
		&"total_placed_credits": total_placed_credits,
		&"selected_value_multiplier": selected_value_multiplier,
		&"spawned_cache_count": spawned_cache_count,
		&"minimum_value_satisfied": total_placed_credits >= minimum_total_credits,
		&"maximum_value_respected": total_placed_credits <= maximum_total_credits,
		&"target_value_satisfied": total_placed_credits == target_total_credits,
	}


func _build_credit_amounts(
	count: int,
	config: LootTierConfig,
	target_total: int
) -> PackedInt32Array:
	var amounts := PackedInt32Array()
	for _index in range(count):
		amounts.append(random.randi_range(
			config.minimum_cache_credits,
			config.maximum_cache_credits
		))
	var indices: Array[int] = []
	for index in range(count):
		indices.append(index)
	indices.shuffle()
	var difference := target_total - _sum_amounts(amounts)
	if difference > 0:
		for index in indices:
			if difference <= 0:
				break
			var added := mini(difference, config.maximum_cache_credits - amounts[index])
			amounts[index] += added
			difference -= added
	elif difference < 0:
		var surplus := -difference
		for index in indices:
			if surplus <= 0:
				break
			var removed := mini(surplus, amounts[index] - config.minimum_cache_credits)
			amounts[index] -= removed
			surplus -= removed
	return amounts


func _sum_amounts(amounts: PackedInt32Array) -> int:
	var result := 0
	for amount in amounts:
		result += amount
	return result


func _spawn_cache(parent: Node2D, point: Dictionary, credit_amount: int) -> void:
	if loot_cache_scene == null:
		push_error("LootSpawner에 Loot Cache Scene이 지정되지 않았습니다.")
		return
	var cache := loot_cache_scene.instantiate() as Area2D
	if cache == null:
		return
	parent.add_child(cache)
	cache.global_position = point.get(&"position", Vector2.ZERO)
	cache.call(
		&"configure",
		credit_amount,
		point.get(&"placement_kind", &"wall_safe"),
		point.get(&"facing", Vector2.DOWN)
	)
	cache.connect(&"credits_collected", Callable(self, &"_on_credits_collected"))
	cache.connect(
		&"interaction_availability_changed",
		Callable(self, &"_on_interaction_availability_changed")
	)
	spawned_cache_count += 1
	total_placed_credits += credit_amount


func _on_credits_collected(amount: int, world_position: Vector2) -> void:
	credits_looted.emit(amount, world_position)


func _on_interaction_availability_changed(available: bool, prompt: String) -> void:
	interaction_availability_changed.emit(available, prompt)
