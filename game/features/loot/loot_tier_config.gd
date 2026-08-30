class_name LootTierConfig
extends Resource

@export var tier_id: StringName = &"small"
@export_range(0, 100, 1) var minimum_cache_count: int = 4
@export_range(0, 100, 1) var maximum_cache_count: int = 6
@export_range(0, 10000, 1) var minimum_cache_credits: int = 15
@export_range(0, 10000, 1) var maximum_cache_credits: int = 35
@export_range(1.0, 10.0, 0.1) var minimum_deployment_value_multiplier: float = 2.5
@export_range(1.0, 20.0, 0.1) var maximum_deployment_value_multiplier: float = 5.0


func is_valid() -> bool:
	return (
		minimum_cache_count >= 0
		and maximum_cache_count >= minimum_cache_count
		and minimum_cache_credits >= 0
		and maximum_cache_credits >= minimum_cache_credits
		and minimum_deployment_value_multiplier >= 1.0
		and maximum_deployment_value_multiplier >= minimum_deployment_value_multiplier
	)
