class_name PlayerHealthRecoveryPolicy
extends Resource

## Standard survival profile. Missing/unknown sources fail closed.
## Alternate profiles can explicitly allow regeneration/drop/buff/level_up later.
@export var allowed_sources: Array[StringName] = [&"consumable"]

func allows(source: StringName) -> bool:
	return source != &"" and source in allowed_sources
