class_name EnergyRegenerationPolicy
extends Resource

## Provisional AP rule. No drops, charges, actor nodes or persistent state here.
@export var enabled := true
@export_range(0.0, 60.0, 0.1) var delay_after_spend := 1.0
@export_range(0.0, 1000.0, 0.1) var energy_per_second := 10.0


func is_valid() -> bool:
	return is_finite(delay_after_spend) and delay_after_spend >= 0.0 \
		and is_finite(energy_per_second) and energy_per_second >= 0.0


func recovered_amount(idle_before: float, delta: float) -> float:
	if not enabled or not is_valid() or not is_finite(delta) or delta <= 0.0:
		return 0.0
	# Only the fraction AFTER the delay counts, independent of frame partitioning.
	return maxf(0.0, delta - maxf(0.0, delay_after_spend - idle_before)) * energy_per_second
