class_name ShopOfferPresenter
extends RefCounted
## Presentation only. Never calculates prices or claims unimplemented quality effects.


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
	return "%s\n개당 %.1f C · %s\n창고 보유 %d개 → 구매 후 %d개\n크레딧 %d C → %d C\n설정된 품질 성능 ×%.2f · 실제 성능 적용은 후속 구현\n현재 지급: 창고 수량만 증가 · 장비/모듈 개별 품질 적용 및 가방 직접 지급은 미연결" % [
		offer.get(&"display_name", ""), float(quote.get(&"unit_price", 0.0)), comparison,
		int(quote.get(&"owned_quantity", 0)), int(quote.get(&"owned_quantity", 0)) + int(offer.get(&"quantity", 0)),
		int(quote.get(&"credits", 0)), int(quote.get(&"balance_after", 0)), float(quote.get(&"configured_performance", 1.0))]
