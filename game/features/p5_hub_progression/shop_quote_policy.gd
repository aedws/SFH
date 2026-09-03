class_name ShopQuotePolicy
extends RefCounted
## Pure, read-only quote. Quality metadata is NOT a runtime stat grant.

const QUALITY_LABELS := {&"damaged": "손상", &"standard": "표준", &"high_performance": "고성능"}


static func quote(offer: Dictionary, catalog: Array[Dictionary], profile: Dictionary,
		rotation_index: int) -> Dictionary:
	var result := {
		&"purchasable": false, &"reason": "현재 회전 상품 아님",
		&"offer": offer.duplicate(true), &"rotation_index": rotation_index,
		&"credits": int(profile.get(&"banked_credits", 0)),
		&"quality_applied": false, &"delivery": "창고 수량 지급",
	}
	if offer.is_empty(): return result
	var price: Variant = offer.get(&"price")
	var quantity: Variant = offer.get(&"quantity")
	var multiplier := float(offer.get(&"performance_multiplier", 1.0))
	var quality := StringName(offer.get(&"quality", &""))
	if not price is int or price < 0 or not quantity is int or quantity <= 0 \
			or not is_finite(multiplier) or multiplier <= 0.0 \
			or not QUALITY_LABELS.has(quality) or String(offer.get(&"target_id", "")).is_empty():
		result[&"reason"] = "매물 데이터 오류 · 구매 불가"
		return result
	if StringName(offer.get(&"target_type", &"")) != &"item":
		result[&"reason"] = "미지원 지급 유형 · 구매 불가"
		return result
	result[&"quality_label"] = QUALITY_LABELS[quality]
	result[&"configured_performance"] = multiplier
	result[&"unit_price"] = float(price) / float(quantity)
	result[&"balance_after"] = int(result[&"credits"]) - int(price)
	result[&"owned_quantity"] = int((profile.get(&"warehouse", {}) as Dictionary).get(offer[&"target_id"], 0))
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
	var unlock_id := StringName(offer.get(&"required_unlock_id", &""))
	if unlock_id != &"" and unlock_id not in profile.get(&"unlock_ids", []):
		result[&"reason"] = "해금 조건 미달"
	elif int(result[&"balance_after"]) < 0:
		result[&"reason"] = "크레딧 부족"
	else:
		result[&"purchasable"] = true
		result[&"reason"] = ""
	return result
