class_name LootSpawner
extends Node

const LOOT_VALUE_POLICY_SCRIPT := preload(
	"res://game/features/loot/loot_value_allocation_policy.gd"
)

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
var effective_maximum_cache_credits: int = 0
var per_cache_value_scaled := false
var random := RandomNumberGenerator.new()
var value_policy := LOOT_VALUE_POLICY_SCRIPT.new()


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
	var allocation: Dictionary = value_policy.call(
		&"allocate", config, deployment_cost, random
	)
	if not bool(allocation.get(&"success", false)):
		push_error(String(allocation.get(&"reason", "회수 가치 정책 계산 실패")))
		return false
	minimum_total_credits = int(allocation[&"minimum_total_credits"])
	maximum_total_credits = int(allocation[&"maximum_total_credits"])
	target_total_credits = int(allocation[&"target_total_credits"])
	selected_value_multiplier = float(allocation[&"selected_value_multiplier"])
	effective_maximum_cache_credits = int(allocation[&"maximum_cache_credits"])
	per_cache_value_scaled = bool(allocation[&"per_cache_value_scaled"])
	var cache_count := int(allocation[&"cache_count"])
	var spawn_points: Array = map_provider.call(&"get_loot_spawn_points", cache_count)
	if spawn_points.size() < cache_count:
		push_error("맵이 선택된 배수 목표에 필요한 회수 위치를 제공하지 못했습니다.")
		return false
	var credit_amounts: PackedInt32Array = value_policy.call(
		&"build_credit_amounts",
		spawn_points.size(),
		int(allocation[&"minimum_cache_credits"]),
		effective_maximum_cache_credits,
		target_total_credits,
		random
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
		&"effective_maximum_cache_credits": effective_maximum_cache_credits,
		&"per_cache_value_scaled": per_cache_value_scaled,
		&"minimum_value_satisfied": total_placed_credits >= minimum_total_credits,
		&"maximum_value_respected": total_placed_credits <= maximum_total_credits,
		&"target_value_satisfied": total_placed_credits == target_total_credits,
	}
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
