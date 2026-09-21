class_name ExtractionExitPolicy
extends Resource

## Pure timing policy. Does not own actors, input, settlement or UI nodes.
@export_range(0.0, 30.0, 0.1) var grace_seconds: float = 2.0
@export_range(0.0, 10.0, 0.1) var decay_seconds_per_second: float = 1.0

func is_valid() -> bool:
	return is_finite(grace_seconds) and grace_seconds >= 0.0 and is_finite(decay_seconds_per_second) and decay_seconds_per_second >= 0.0

func regression(previous_outside: float, current_outside: float) -> float:
	# Only the part of a frame past the grace boundary counts.
	return maxf(0.0, maxf(0.0, current_outside - grace_seconds) - maxf(0.0, previous_outside - grace_seconds)) * decay_seconds_per_second

func grace_remaining(outside_seconds: float) -> float:
	return maxf(0.0, grace_seconds - outside_seconds)

func is_decaying(outside_seconds: float) -> bool:
	return decay_seconds_per_second > 0.0 and outside_seconds > grace_seconds
