class_name ItemQualityDefinition
extends Resource
## Designer-owned quality tier. Runtime offers provide only the per-item multiplier.

@export var quality_id: StringName
@export var display_name := "표준"
@export var option_ids: Array[StringName] = []
@export_range(0, 32, 1) var socket_count := 0


func is_valid() -> bool:
	return quality_id != &"" and not display_name.is_empty() and socket_count >= 0
