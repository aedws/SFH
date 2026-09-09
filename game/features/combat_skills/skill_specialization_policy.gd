class_name SkillSpecializationPolicy
extends RefCounted
## Character-owned immutable policy; no editable passive slot and no character ID switch.
static func modifiers(skill: Resource, policy: Dictionary) -> Dictionary:
	if policy.is_empty() or skill == null: return {}
	var parameters: Dictionary = skill.effect.call(&"get_parameters")
	var family := String(parameters.get(&"shape", "mobility" if parameters.has(&"distance") or parameters.has(&"speed_multiplier") else "circle"))
	if family not in String(policy.get(&"families", "")).split("|"): return {}
	return {&"damage_multiply": float(policy.get(&"damage_multiplier", 1.0)),
		&"cooldown_multiply": float(policy.get(&"cooldown_multiplier", 1.0)),
		&"radius_multiplier": float(policy.get(&"radius_multiplier", 1.0))}
