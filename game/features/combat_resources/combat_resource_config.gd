class_name CombatResourceConfig
extends Resource

@export_range(1.0, 10000.0, 1.0) var maximum_energy: float = 100.0
@export_range(0.0, 10000.0, 1.0) var starting_energy: float = 100.0
@export_range(0.0, 1.0, 0.01) var energy_drop_chance: float = 0.55
@export_range(1.0, 1000.0, 1.0) var energy_drop_amount: float = 20.0
@export_range(0.0, 1.0, 0.01) var health_drop_chance: float = 0.20
@export_range(1.0, 1000.0, 1.0) var health_drop_amount: float = 15.0
@export var guarantee_one_drop: bool = true
@export_range(16.0, 1000.0, 8.0) var pickup_magnet_radius: float = 150.0
@export_range(1.0, 2000.0, 10.0) var pickup_magnet_speed: float = 320.0
@export var regeneration_policy: Resource


func is_valid() -> bool:
	return (
		maximum_energy > 0.0
		and starting_energy >= 0.0
		and starting_energy <= maximum_energy
		and energy_drop_chance >= 0.0
		and energy_drop_chance <= 1.0
		and energy_drop_amount > 0.0
		and health_drop_chance >= 0.0
		and health_drop_chance <= 1.0
		and health_drop_amount > 0.0
		and pickup_magnet_radius > 0.0
		and pickup_magnet_speed > 0.0
		and (regeneration_policy == null or (
			regeneration_policy.has_method(&"is_valid")
			and regeneration_policy.has_method(&"recovered_amount")
			and bool(regeneration_policy.call(&"is_valid"))
		))
	)
