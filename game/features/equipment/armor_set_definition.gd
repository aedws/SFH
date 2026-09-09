class_name ArmorSetDefinition
extends Resource
## Data-only, fixed-identity thresholds. No level/quality multiplier is applied.

@export var set_id: StringName
@export var display_name: String
@export var bonuses: Array[Dictionary] = []


func is_valid() -> bool:
	if set_id == &"" or display_name.is_empty() or bonuses.is_empty(): return false
	var thresholds := []
	for bonus in bonuses:
		var count := int(bonus.get("required_pieces", 0))
		if count < 1 or count > 4 or count in thresholds: return false
		thresholds.append(count)
		for target in ["player", "weapon", "skill"]:
			var modifiers: Variant = bonus.get(target, {})
			if not modifiers is Dictionary: return false
			for key in modifiers:
				if target == "player":
					if key not in ["max_health", "defense", "movement_speed"]: return false
					var entry: Variant = modifiers[key]
					if not entry is Dictionary: return false
					if not is_finite(float(entry.get("add", 0))) or not is_finite(float(entry.get("multiply", 1))) or float(entry.get("multiply", 1)) <= 0: return false
				else:
					var allowed := ["damage_multiply", "fire_interval_multiply"] if target == "weapon" else ["damage_multiply", "cooldown_multiply"]
					if key not in allowed or not is_finite(float(modifiers[key])) or float(modifiers[key]) <= 0: return false
	return true


func snapshot() -> Dictionary:
	return {"id": String(set_id), "name": display_name, "bonuses": bonuses.duplicate(true), "scaling_policy": "fixed_identity"}
