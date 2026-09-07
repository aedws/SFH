class_name ModuleSocketPolicy
extends Resource
## Socket economics, independent of UI, item quality and level progression.
@export_range(0.0, 1.0) var matching_cost_multiplier := 0.5
@export_range(1.0, 2.0) var mismatching_cost_multiplier := 1.0

func cost(base: int, socket: StringName, tags: Array) -> int:
	if socket == &"": return base
	return ceili(base * (matching_cost_multiplier if socket in tags else mismatching_cost_multiplier))

func is_valid() -> bool:
	return is_finite(matching_cost_multiplier) and matching_cost_multiplier >= 0.0 and matching_cost_multiplier <= 1.0 and is_finite(mismatching_cost_multiplier) and mismatching_cost_multiplier >= 1.0
