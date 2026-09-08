class_name ShopOfferPresenter
extends RefCounted
## Presentation only. Never calculates prices or invents quality effects.


static func card(quote: Dictionary) -> String:
	var offer: Dictionary = quote.get(&"offer", {})
	return "%s · %s\n%s\n%d C / %d개" % [
		quote.get(&"quality_label", "확인 필요"),
		"임시 데이터" if quote.get(&"source_status", "provisional") == "provisional" else "카탈로그",
		offer.get(&"display_name", "알 수 없는 상품"), int(offer.get(&"price", 0)), int(offer.get(&"quantity", 0))]


static func detail(quote: Dictionary) -> String:
	if quote.is_empty(): return "상품을 선택해 견적을 확인하세요. 선택만으로 재화가 차감되지 않습니다."
	var offer: Dictionary = quote.get(&"offer", {})
	var comparison := "동일 품목의 표준 단가 없음"
	if quote.has(&"price_ratio"):
		comparison = "동일 품목 표준 단가 대비 %.0f%%" % (float(quote[&"price_ratio"]) * 100.0)
	var options: Array = quote.get(&"quality_option_ids", [])
	var option_text := "%d개" % options.size() if not options.is_empty() else "없음"
	var physical_quality := bool(quote.get(&"quality_applied", false))
	return "구매 견적 / %s\n개당 %.1f C · %s\n%s 수량  %d → %d개\n구매 후 잔액  %d → %d C\n설정 품질 ×%.2f · 고정 옵션 %s · 품질 소켓 %d\n지급: %s · %s" % [
		offer.get(&"display_name", ""), float(quote.get(&"unit_price", 0.0)), comparison,
		"가방" if physical_quality else "창고",
		int(quote.get(&"owned_quantity", 0)), int(quote.get(&"owned_quantity", 0)) + int(offer.get(&"quantity", 0)),
		int(quote.get(&"credits", 0)), int(quote.get(&"balance_after", 0)),
		float(quote.get(&"configured_performance", 1.0)), option_text,
		int(quote.get(&"quality_socket_count", 0)), quote.get(&"delivery", "지급 확인 필요"),
		"인스턴스별 품질 유지" if physical_quality else "수량만 지급 · 품질 효과 미적용"]


static func receipt(result: Dictionary) -> String:
	var delivery: Dictionary = result.get(&"delivery", {})
	return "구매 완료 · %s %d개 · %s. 추가 구매는 상품을 다시 선택하세요." % [
		result.get(&"offer", {}).get(&"display_name", "선택 상품"), int(result.get(&"granted", 0)),
		delivery.get(&"delivery", "창고 수량 지급")]
