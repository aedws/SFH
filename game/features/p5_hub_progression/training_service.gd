class_name TrainingService
extends RefCounted

var scenarios: Array[Dictionary] = []
var active: Dictionary = {}
var hits: Array[Dictionary] = []
var started_msec := 0


func configure(rows: Array[Dictionary]) -> bool:
	scenarios = rows.duplicate(true)
	return not scenarios.is_empty()


func start(scenario_id: StringName) -> Dictionary:
	active = _find(scenario_id)
	if active.is_empty():
		return {&"success": false, &"reason": "훈련 시나리오 없음"}
	hits.clear()
	started_msec = Time.get_ticks_msec()
	return {&"success": true, &"scenario": active.duplicate(true), &"credit_cost": 0,
		&"free_loadout": bool(active.get(&"allow_free_loadout", false))}


func record_hit(damage: float, armor_penetration: float, cooldown_seconds: float) -> bool:
	if active.is_empty() or damage < 0.0:
		return false
	hits.append({&"damage": damage, &"armor_penetration": armor_penetration,
		&"cooldown_seconds": cooldown_seconds, &"at_msec": Time.get_ticks_msec()})
	return true


func finish() -> Dictionary:
	if active.is_empty():
		return {&"success": false, &"reason": "진행 중 훈련 없음"}
	var seconds := maxf(0.001, float(Time.get_ticks_msec() - started_msec) / 1000.0)
	var total_damage := 0.0
	var maximum_hit := 0.0
	var penetration_total := 0.0
	var cooldown_total := 0.0
	for hit in hits:
		total_damage += float(hit.get(&"damage", 0.0))
		maximum_hit = maxf(maximum_hit, float(hit.get(&"damage", 0.0)))
		penetration_total += float(hit.get(&"armor_penetration", 0.0))
		cooldown_total += float(hit.get(&"cooldown_seconds", 0.0))
	var count := maxi(1, hits.size())
	var result := {&"success": true, &"scenario_id": active.get(&"scenario_id", &""),
		&"dps": total_damage / seconds, &"hit_damage": maximum_hit,
		&"armor_penetration": penetration_total / count,
		&"cooldown": cooldown_total / count, &"hit_count": hits.size(),
		&"restored_loadout": bool(active.get(&"restore_on_exit", true))}
	active.clear()
	hits.clear()
	return result


func get_snapshot() -> Dictionary:
	var total_damage := 0.0
	for hit in hits:
		total_damage += float(hit.get(&"damage", 0.0))
	return {&"scenario_count": scenarios.size(), &"active": active.duplicate(true),
		&"hit_count": hits.size(), &"total_damage": total_damage,
		&"metrics": [&"dps", &"hit_damage", &"armor_penetration", &"cooldown"]}


func get_scenarios() -> Array[Dictionary]:
	return scenarios.duplicate(true)


func _find(scenario_id: StringName) -> Dictionary:
	for scenario in scenarios:
		if StringName(scenario.get(&"scenario_id", &"")) == scenario_id:
			return scenario
	return {}
