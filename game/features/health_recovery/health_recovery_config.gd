class_name HealthRecoveryConfig
extends Resource

@export_range(0.0, 30.0, 0.1) var delay_after_damage_seconds: float = 4.0
@export_range(0.0, 100.0, 0.1) var healing_per_second: float = 3.0
@export_range(0.1, 1.0, 0.05) var maximum_recovery_ratio: float = 0.65


func is_valid() -> bool:
	return (
		delay_after_damage_seconds >= 0.0
		and healing_per_second > 0.0
		and maximum_recovery_ratio > 0.0
		and maximum_recovery_ratio <= 1.0
	)
