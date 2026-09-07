class_name ShopItemQualityPolicy
extends RefCounted
## Pure quality contract shared by quote, delivery and equipment domains.

const DEFAULT_CATALOG_PATH := (
	"res://game/features/p5_hub_progression/configs/default_item_quality_catalog.tres"
)
const DESCRIPTOR := preload("res://game/core/item_quality_descriptor.gd")


static func default_catalog() -> Resource:
	return load(DEFAULT_CATALOG_PATH)


static func is_valid_offer(offer: Dictionary, catalog: Resource = null) -> bool:
	var source := catalog if catalog != null else default_catalog()
	var quality := StringName(offer.get(&"quality", &""))
	var multiplier := float(offer.get(&"performance_multiplier", 1.0))
	if source == null or not source.has_method(&"get_definition"):
		return false
	var definition: Resource = source.call(&"get_definition", quality)
	if definition == null or not definition.call(&"is_valid"):
		return false
	return (
		source != null
		and source.has_method(&"get_definition")
		and source.call(&"get_definition", quality) != null
		and is_finite(multiplier)
		and multiplier > 0.0
		and multiplier >= float(definition.get("performance_minimum"))
		and multiplier <= float(definition.get("performance_maximum"))
	)


static func build_payload(offer: Dictionary, transaction_id: StringName,
		catalog: Resource = null) -> Dictionary:
	var source := catalog if catalog != null else default_catalog()
	if not is_valid_offer(offer, source):
		return {}
	var quality := StringName(offer.get(&"quality", &""))
	var definition: Resource = source.call(&"get_definition", quality)
	var descriptor := DESCRIPTOR.new()
	descriptor.quality_id = quality
	descriptor.quality_label = String(definition.get("display_name"))
	descriptor.performance_multiplier = float(offer.get(&"performance_multiplier", 1.0))
	descriptor.quality_option_ids.assign(definition.get("option_ids"))
	descriptor.quality_socket_count = int(definition.get("socket_count"))
	descriptor.source_offer_id = StringName(offer.get(&"offer_id", &""))
	descriptor.source_status = String(offer.get(&"source_status", "provisional"))
	descriptor.transaction_id = transaction_id
	return descriptor.to_payload()


static func performance_multiplier(payload: Dictionary) -> float:
	return DESCRIPTOR.multiplier(payload)


static func scale_additive(value: float, payload: Dictionary) -> float:
	return DESCRIPTOR.scale_additive(value, payload)


static func scale_multiplicative(value: float, payload: Dictionary) -> float:
	return DESCRIPTOR.scale_multiplicative(value, payload)
