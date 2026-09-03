class_name ShopItemQualityPolicy
extends RefCounted
## Pure quality contract shared by quote, delivery and equipment domains.

const QUALITY_LABELS := {
	&"damaged": "손상",
	&"standard": "표준",
	&"high_performance": "고성능",
}
const QUALITY_OPTIONS := {
	&"damaged": [&"worn_output"],
	&"standard": [&"factory_spec"],
	&"high_performance": [&"overclocked_output"],
}
const QUALITY_SOCKETS := {
	&"damaged": 0,
	&"standard": 0,
	&"high_performance": 1,
}


static func is_valid_offer(offer: Dictionary) -> bool:
	var quality := StringName(offer.get(&"quality", &""))
	var multiplier := float(offer.get(&"performance_multiplier", 1.0))
	return (
		QUALITY_LABELS.has(quality)
		and is_finite(multiplier)
		and multiplier > 0.0
	)


static func build_payload(offer: Dictionary, transaction_id: StringName) -> Dictionary:
	if not is_valid_offer(offer):
		return {}
	var quality := StringName(offer.get(&"quality", &""))
	return {
		&"quality_id": quality,
		&"quality_label": QUALITY_LABELS[quality],
		&"performance_multiplier": float(offer.get(&"performance_multiplier", 1.0)),
		&"quality_option_ids": (QUALITY_OPTIONS[quality] as Array).duplicate(),
		&"quality_socket_count": int(QUALITY_SOCKETS[quality]),
		&"source_offer_id": StringName(offer.get(&"offer_id", &"")),
		&"source_status": String(offer.get(&"source_status", "provisional")),
		&"transaction_id": transaction_id,
	}


static func performance_multiplier(payload: Dictionary) -> float:
	var value := float(payload.get(&"performance_multiplier", 1.0))
	return value if is_finite(value) and value > 0.0 else 1.0


static func scale_additive(value: float, payload: Dictionary) -> float:
	return value * performance_multiplier(payload)


static func scale_multiplicative(value: float, payload: Dictionary) -> float:
	return 1.0 + (value - 1.0) * performance_multiplier(payload)
