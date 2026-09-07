class_name HealthRecoverySystem
extends Node

signal recovery_state_changed(snapshot: Dictionary)

const PLAYER_METHODS := [&"heal", &"get_health_snapshot"]

var player_target: Node
var config: Resource
var delay_remaining: float = 0.0
var last_health: float = 0.0
var recovery_multiplier: float = 1.0


func configure(new_player_target: Node, new_config: Resource) -> bool:
	if not _supports_methods(new_player_target, PLAYER_METHODS):
		push_error("부분 체력 회복에는 플레이어 체력 공개 계약이 필요합니다.")
		return false
	if (
		new_config == null
		or not new_config.has_method(&"is_valid")
		or not new_config.call(&"is_valid")
	):
		push_error("유효한 부분 체력 회복 설정이 필요합니다.")
		return false
	player_target = new_player_target
	config = new_config
	var health: Dictionary = player_target.call(&"get_health_snapshot")
	last_health = float(health.get(&"current", 0.0))
	player_target.connect(&"health_changed", Callable(self, &"_on_health_changed"))
	recovery_state_changed.emit(get_snapshot())
	return true


func set_recovery_multiplier(multiplier: float) -> void:
	recovery_multiplier = maxf(0.0, multiplier)


func _process(delta: float) -> void:
	advance(delta)


func advance(delta: float) -> float:
	if player_target == null or config == null:
		return 0.0
	if player_target.has_method(&"can_receive_healing") and not player_target.call(&"can_receive_healing", &"regeneration"):
		return 0.0
	delay_remaining = maxf(0.0, delay_remaining - maxf(0.0, delta))
	var health: Dictionary = player_target.call(&"get_health_snapshot")
	var current := float(health.get(&"current", 0.0))
	var maximum := float(health.get(&"maximum", 1.0))
	var ceiling := maximum * float(config.get("maximum_recovery_ratio"))
	if delay_remaining > 0.0 or current <= 0.0 or current >= ceiling:
		return 0.0
	var healed := minf(
		float(config.get("healing_per_second")) * recovery_multiplier * maxf(0.0, delta),
		ceiling - current
	)
	if healed <= 0.0:
		return 0.0
	player_target.call(&"heal", healed, &"regeneration")
	return healed


func get_snapshot() -> Dictionary:
	return {
		&"delay_remaining": delay_remaining,
		&"healing_per_second": (
			float(config.get("healing_per_second")) if config != null else 0.0
		),
		&"maximum_recovery_ratio": (
			float(config.get("maximum_recovery_ratio")) if config != null else 0.0
		),
		&"recovering": delay_remaining <= 0.0 and is_instance_valid(player_target) and player_target.has_method(&"can_receive_healing") and bool(player_target.call(&"can_receive_healing", &"regeneration")),
		&"recovery_multiplier": recovery_multiplier,
	}


func _on_health_changed(current: float, _maximum: float) -> void:
	if current < last_health:
		delay_remaining = float(config.get("delay_after_damage_seconds"))
	last_health = current
	recovery_state_changed.emit(get_snapshot())


func _supports_methods(candidate: Node, methods: Array) -> bool:
	if candidate == null or not candidate.has_signal(&"health_changed"):
		return false
	for method_name in methods:
		if not candidate.has_method(method_name):
			return false
	return true
