class_name ItemQualityDescriptor
extends Resource
## Canonical, save-compatible contract for per-item quality metadata.

const KEY_ID := &"quality_id"
const KEY_LABEL := &"quality_label"
const KEY_MULTIPLIER := &"performance_multiplier"
const KEY_OPTION_IDS := &"quality_option_ids"
const KEY_SOCKET_COUNT := &"quality_socket_count"
const KEY_SOURCE_OFFER_ID := &"source_offer_id"
const KEY_SOURCE_STATUS := &"source_status"
const KEY_TRANSACTION_ID := &"transaction_id"

@export var quality_id: StringName = &"standard"
@export var quality_label := "표준"
@export_range(0.01, 100.0, 0.01) var performance_multiplier := 1.0
@export var quality_option_ids: Array[StringName] = []
@export_range(0, 32, 1) var quality_socket_count := 0
@export var source_offer_id: StringName
@export var source_status := "provisional"
@export var transaction_id: StringName


func is_valid() -> bool:
	return (
		quality_id != &""
		and not quality_label.is_empty()
		and is_finite(performance_multiplier)
		and performance_multiplier > 0.0
		and quality_socket_count >= 0
	)


func to_payload() -> Dictionary:
	if not is_valid():
		return {}
	return {
		KEY_ID: quality_id,
		KEY_LABEL: quality_label,
		KEY_MULTIPLIER: performance_multiplier,
		KEY_OPTION_IDS: quality_option_ids.duplicate(),
		KEY_SOCKET_COUNT: quality_socket_count,
		KEY_SOURCE_OFFER_ID: source_offer_id,
		KEY_SOURCE_STATUS: source_status,
		KEY_TRANSACTION_ID: transaction_id,
	}


static func multiplier(payload: Dictionary) -> float:
	return _valid_multiplier(payload.get(KEY_MULTIPLIER, 1.0))


static func label(payload: Dictionary) -> String:
	return String(payload.get(KEY_LABEL, "표준"))


static func socket_count(payload: Dictionary) -> int:
	return maxi(0, int(payload.get(KEY_SOCKET_COUNT, 0)))


static func scale_additive(value: float, payload: Dictionary) -> float:
	return value * multiplier(payload)


static func scale_multiplicative(value: float, payload: Dictionary) -> float:
	return 1.0 + (value - 1.0) * multiplier(payload)


static func _valid_multiplier(value: Variant) -> float:
	var parsed := float(value)
	return parsed if is_finite(parsed) and parsed > 0.0 else 1.0
