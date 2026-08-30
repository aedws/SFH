class_name LootSpawner
extends Node

signal credits_looted(amount: int, world_position: Vector2)
signal interaction_availability_changed(available: bool, prompt: String)

@export var loot_cache_scene: PackedScene

var spawned_cache_count: int = 0
var total_placed_credits: int = 0
var minimum_total_credits: int = 0
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
	deployment_cost = new_deployment_cost
	minimum_total_credits = ceili(
		float(deployment_cost) * config.minimum_deployment_value_multiplier
	)
	var minimum_count := config.minimum_cache_count
	var maximum_count := config.maximum_cache_count
	var required_count := 0
	if minimum_total_credits > 0 and config.maximum_cache_credits > 0:
		required_count = ceili(
			float(minimum_total_credits) / float(config.maximum_cache_credits)
		)
	if required_count > maximum_count:
		push_error("최대 회수 지점 수로 투입 코스트 최소 보정값을 충족할 수 없습니다.")
		return false
	var cache_count := maxi(
		random.randi_range(minimum_count, maximum_count),
		required_count
	)
	var spawn_points: Array = map_provider.call(&"get_loot_spawn_points", cache_count)
	if spawn_points.size() < required_count:
		push_error("맵이 투입 코스트 최소 보정값에 필요한 회수 위치를 제공하지 못했습니다.")
		return false
	var credit_amounts := _build_credit_amounts(spawn_points.size(), config)
	for index in range(spawn_points.size()):
		_spawn_cache(
			loot_parent,
			spawn_points[index],
			credit_amounts[index]
		)
	return total_placed_credits >= minimum_total_credits


func get_spawn_snapshot() -> Dictionary:
	return {
		&"deployment_cost": deployment_cost,
		&"minimum_total_credits": minimum_total_credits,
		&"total_placed_credits": total_placed_credits,
		&"spawned_cache_count": spawned_cache_count,
		&"minimum_value_satisfied": total_placed_credits >= minimum_total_credits,
	}


func _build_credit_amounts(count: int, config: LootTierConfig) -> PackedInt32Array:
	var amounts := PackedInt32Array()
	for _index in range(count):
		amounts.append(random.randi_range(
			config.minimum_cache_credits,
			config.maximum_cache_credits
		))
	var deficit := maxi(0, minimum_total_credits - _sum_amounts(amounts))
	var indices: Array[int] = []
	for index in range(count):
		indices.append(index)
	indices.shuffle()
	for index in indices:
		if deficit <= 0:
			break
		var added := mini(deficit, config.maximum_cache_credits - amounts[index])
		amounts[index] += added
		deficit -= added
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
