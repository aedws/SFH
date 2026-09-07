class_name ItemQualityDefinition
extends Resource
## Designer-owned quality tier. Runtime offers provide only the per-item multiplier.

@export var quality_id: StringName
@export var display_name := "표준"
@export var option_ids: Array[StringName] = []
@export_range(0, 32, 1) var socket_count := 0
@export var performance_minimum := 0.01
@export var performance_maximum := 100.0
## Zero disables the price band for this quality; compare identical target unit prices.
@export var standard_price_ratio_minimum := 0.0
@export var standard_price_ratio_maximum := 0.0


func is_valid() -> bool:
	return (
		quality_id != &"" and not display_name.is_empty() and socket_count >= 0
		and is_finite(performance_minimum) and is_finite(performance_maximum)
		and performance_minimum > 0.0 and performance_maximum >= performance_minimum
		and is_finite(standard_price_ratio_minimum) and is_finite(standard_price_ratio_maximum)
		and standard_price_ratio_minimum >= 0.0
		and standard_price_ratio_maximum >= standard_price_ratio_minimum
	)
