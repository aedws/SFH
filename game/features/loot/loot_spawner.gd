class_name LootSpawner
extends Node

signal credits_looted(amount: int, world_position: Vector2)
signal interaction_availability_changed(available: bool, prompt: String)

@export var loot_cache_scene: PackedScene

var spawned_cache_count: int = 0
var random := RandomNumberGenerator.new()


func _ready() -> void:
	random.randomize()


func configure(map_provider: Node, loot_parent: Node2D, config: LootTierConfig) -> void:
	if (
		not is_instance_valid(map_provider)
		or not map_provider.has_method(&"get_loot_spawn_positions")
		or not is_instance_valid(loot_parent)
		or config == null
	):
		push_error("LootSpawner 구성에 맵, 부모 Node2D, 등급 Resource가 필요합니다.")
		return

	if not config.is_valid():
		push_error("LootTierConfig 값이 유효하지 않습니다.")
		return
	var minimum_count := config.minimum_cache_count
	var maximum_count := config.maximum_cache_count
	var cache_count := random.randi_range(minimum_count, maximum_count)
	var spawn_points: Array = map_provider.call(&"get_loot_spawn_points", cache_count)
	for point in spawn_points:
		_spawn_cache(
			loot_parent,
			point,
			random.randi_range(
				config.minimum_cache_credits,
				config.maximum_cache_credits
			)
		)


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


func _on_credits_collected(amount: int, world_position: Vector2) -> void:
	credits_looted.emit(amount, world_position)


func _on_interaction_availability_changed(available: bool, prompt: String) -> void:
	interaction_availability_changed.emit(available, prompt)
