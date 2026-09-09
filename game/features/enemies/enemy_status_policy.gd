class_name EnemyStatusPolicy
extends RefCounted
## Unknown tags remain available for combos without silently changing movement.
static func movement_multiplier(statuses: Dictionary, boss: bool) -> float:
	if statuses.has(&"stun"): return 0.65 if boss else 0.0
	if statuses.has(&"slow"): return 0.8 if boss else 0.5
	return 1.0

static func damage_multiplier(statuses: Dictionary) -> float:
	return 1.25 if statuses.has(&"vulnerable") else 1.0

static func can_attack(statuses: Dictionary, boss: bool) -> bool:
	return boss or not statuses.has(&"stun")
