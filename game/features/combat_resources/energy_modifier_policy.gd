class_name EnergyModifierPolicy
extends RefCounted
## Character-neutral, value-only contract. Does not mutate the base config.

static func is_valid(values: Dictionary) -> bool:
	for key in values:
		if key not in [&"capacity_multiplier", &"moving_regeneration_multiplier"]:
			return false
		var value: Variant = values[key]
		if not (value is float or value is int) or not is_finite(float(value)) or float(value) <= 0.0 or float(value) > 5.0:
			return false
	return true


static func maximum(base: float, values: Dictionary) -> float:
	return base * float(values.get(&"capacity_multiplier", 1.0))


static func recovery_multiplier(values: Dictionary, moving: bool) -> float:
	return float(values.get(&"moving_regeneration_multiplier", 1.0)) if moving else 1.0
