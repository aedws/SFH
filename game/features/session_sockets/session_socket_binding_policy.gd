class_name SessionSocketBindingPolicy
extends Resource
## Provisional: current weapon (slot/definition), first skill if not specified.
## Explicit IDs allow future UI and policy replacements without editing Game.
@export var bind_to_target := true
@export var default_target_index := 0


func choose(candidates: Array, requested: StringName = &"") -> Dictionary:
	if candidates.is_empty():
		return {}
	if requested != &"":
		for entry: Dictionary in candidates:
			if StringName(entry.get(&"target_id", &"")) == requested:
				return entry.duplicate(true)
		return {}
	return candidates[clampi(default_target_index, 0, candidates.size() - 1)].duplicate(true)
