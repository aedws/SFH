class_name ShopQuotePolicy
extends RefCounted
## Pure, read-only quote. Delivery and quality effects remain external providers.

const QUALITY_POLICY := preload(
	"res://game/features/p5_hub_progression/shop_item_quality_policy.gd"
)


static func quote(offer: Dictionary, catalog: Array[Dictionary], profile: Dictionary,
		rotation_index: int, delivery_preview: Dictionary = {},
		quality_catalog: Resource = null) -> Dictionary:
	var definition_catalog := (
		quality_catalog if quality_catalog != null else QUALITY_POLICY.default_catalog()
	)
	var result := {
		&"purchasable": false, &"reason": "현재 회전 상품 아님",
		&"offer": offer.duplicate(true), &"rotation_index": rotation_index,
		&"credits": int(profile.get(&"banked_credits", 0)),
		&"quality_applied": not delivery_preview.is_empty(),
		&"delivery": delivery_preview.get(&"delivery", "창고 수량 지급"),
	}
	if offer.is_empty(): return result
	var source_error := EquipmentSupplyPolicy.hub_default().source_error(offer)
	if not source_error.is_empty():
		result[&"reason"] = source_error
		return result
	var price: Variant = offer.get(&"price")
	var quantity: Variant = offer.get(&"quantity")
	var multiplier := float(offer.get(&"performance_multiplier", 1.0))
	var quality := StringName(offer.get(&"quality", &""))
	if not price is int or price < 0 or not quantity is int or quantity <= 0 \
			or not is_finite(multiplier) or multiplier <= 0.0 \
			or not QUALITY_POLICY.is_valid_offer(offer, definition_catalog) \
			or String(offer.get(&"target_id", "")).is_empty():
		result[&"reason"] = "매물 데이터 오류 · 구매 불가"
		return result
	if StringName(offer.get(&"target_type", &"")) != &"item":
		result[&"reason"] = "미지원 지급 유형 · 구매 불가"
		return result
	var quality_definition: Resource = definition_catalog.call(&"get_definition", quality)
	result[&"quality_label"] = quality_definition.get("display_name")
	result[&"configured_performance"] = multiplier
	result[&"unit_price"] = float(price) / float(quantity)
	result[&"balance_after"] = int(result[&"credits"]) - int(price)
	result[&"owned_quantity"] = int(delivery_preview.get(
		&"owned_quantity",
		(profile.get(&"warehouse", {}) as Dictionary).get(offer[&"target_id"], 0)
	))
	result[&"quality_option_ids"] = (quality_definition.get("option_ids") as Array).duplicate()
	result[&"quality_socket_count"] = int(quality_definition.get("socket_count"))
	result[&"item_type"] = delivery_preview.get(&"item_type", &"item")
	result[&"source_status"] = String(offer.get(&"source_status", "provisional"))
	# Compare like-for-like targets, never unrelated goods or pack totals.
	for candidate in catalog:
		if StringName(candidate.get(&"quality", &"")) == &"standard" \
				and candidate.get(&"target_id") == offer.get(&"target_id") \
				and candidate.get(&"target_type") == offer.get(&"target_type") \
				and int(candidate.get(&"quantity", 0)) > 0 and int(candidate.get(&"price", 0)) > 0:
			result[&"standard_unit_price"] = float(candidate[&"price"]) / float(candidate[&"quantity"])
			result[&"price_ratio"] = float(result[&"unit_price"]) / float(result[&"standard_unit_price"])
			break
	var ratio_max := float(quality_definition.get("standard_price_ratio_maximum"))
	if ratio_max > 0.0:
		var standard_prices: Array[float] = []
		for candidate in catalog:
			if candidate.get(&"quality") != &"standard" or candidate.get(&"target_id") != offer.get(&"target_id") or candidate.get(&"target_type") != offer.get(&"target_type"):
				continue
			if int(candidate.get(&"quantity", 0)) <= 0 or int(candidate.get(&"price", 0)) <= 0:
				continue
			var unit := float(candidate[&"price"]) / float(candidate[&"quantity"])
			if not standard_prices.has(unit):
				standard_prices.append(unit)
		if standard_prices.size() != 1:
			result[&"reason"] = "표준 단가 누락 또는 중복 · 구매 불가"
			return result
		var ratio := float(result[&"unit_price"]) / standard_prices[0]
		if ratio < float(quality_definition.get("standard_price_ratio_minimum")) - 0.000001 or ratio > ratio_max + 0.000001:
			result[&"reason"] = "품질별 가격 범위 오류 · 구매 불가"
			return result
	var unlock_id := StringName(offer.get(&"required_unlock_id", &""))
	if unlock_id != &"" and unlock_id not in profile.get(&"unlock_ids", []):
		result[&"reason"] = "해금 조건 미달"
	elif int(result[&"balance_after"]) < 0:
		result[&"reason"] = "크레딧 부족"
	elif not delivery_preview.is_empty() and not bool(delivery_preview.get(&"can_deliver", false)):
		result[&"reason"] = String(delivery_preview.get(&"reason", "가방 지급 불가"))
	else:
		result[&"purchasable"] = true
		result[&"reason"] = ""
	return result
