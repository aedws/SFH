class_name CombatTelemetryCollector
extends RefCounted

var window_seconds := 15.0
var elapsed_seconds := 0.0
var active := false
var finalized := false
var hits: Array[Dictionary] = []
var total_ap_spent := 0.0
var cooldown_cycles := 0
var cooldown_total := 0.0
var resource_events := 0


func begin(measurement_seconds: float) -> bool:
	if measurement_seconds <= 0.0:
		return false
	window_seconds = measurement_seconds
	elapsed_seconds = 0.0
	active = true
	finalized = false
	hits.clear()
	total_ap_spent = 0.0
	cooldown_cycles = 0
	cooldown_total = 0.0
	resource_events = 0
	return true


func advance(delta: float) -> bool:
	if not active or delta <= 0.0:
		return false
	elapsed_seconds = minf(window_seconds, elapsed_seconds + delta)
	if elapsed_seconds >= window_seconds:
		active = false
		finalized = true
		return true
	return false


func record_hit(damage: float, armor_penetration: float = 0.0) -> bool:
	if not active or damage < 0.0:
		return false
	hits.append({
		&"damage": damage,
		&"armor_penetration": clampf(armor_penetration, 0.0, 1.0),
		&"at_seconds": elapsed_seconds,
	})
	return true


func record_resource_use(ap_spent: float, cooldown_seconds: float) -> bool:
	if not active or ap_spent < 0.0 or cooldown_seconds < 0.0:
		return false
	total_ap_spent += ap_spent
	resource_events += 1
	if cooldown_seconds > 0.0:
		cooldown_cycles += 1
		cooldown_total += cooldown_seconds
	return true


func stop() -> Dictionary:
	active = false
	finalized = true
	return get_snapshot()


func get_snapshot() -> Dictionary:
	var total_damage := 0.0
	var maximum_hit := 0.0
	var last_hit := 0.0
	var penetration_total := 0.0
	for hit in hits:
		var damage := float(hit.get(&"damage", 0.0))
		total_damage += damage
		maximum_hit = maxf(maximum_hit, damage)
		last_hit = damage
		penetration_total += float(hit.get(&"armor_penetration", 0.0))
	var measured := maxf(0.001, elapsed_seconds)
	return {
		&"active": active,
		&"finalized": finalized,
		&"elapsed_seconds": elapsed_seconds,
		&"window_seconds": window_seconds,
		&"remaining_seconds": maxf(0.0, window_seconds - elapsed_seconds),
		&"window_ratio": clampf(elapsed_seconds / window_seconds, 0.0, 1.0),
		&"hit_count": hits.size(),
		&"total_damage": total_damage,
		&"dps": total_damage / measured,
		&"last_hit": last_hit,
		&"maximum_hit": maximum_hit,
		&"average_hit": total_damage / float(hits.size()) if not hits.is_empty() else 0.0,
		&"average_armor_penetration": (
			penetration_total / float(hits.size()) if not hits.is_empty() else 0.0
		),
		&"ap_spent": total_ap_spent,
		&"ap_per_second": total_ap_spent / measured,
		&"resource_events": resource_events,
		&"cooldown_cycles": cooldown_cycles,
		&"average_cooldown": (
			cooldown_total / float(cooldown_cycles) if cooldown_cycles > 0 else 0.0
		),
	}
