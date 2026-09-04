class_name ShopRerollTransactionService
extends RefCounted

var profile: Node
var processed_transactions: Dictionary = {}


func configure(profile_provider: Node) -> bool:
	profile = profile_provider
	return is_instance_valid(profile) \
		and profile.has_method(&"get_snapshot") \
		and profile.has_method(&"spend") \
		and profile.has_method(&"add_credits") \
		and profile.has_method(&"has_processed_transaction") \
		and profile.has_method(&"mark_transaction_processed")


func quote(price: int) -> Dictionary:
	var credits := int(profile.call(&"get_snapshot").get(&"banked_credits", 0)) if is_instance_valid(profile) else 0
	return {
		&"price": maxi(0, price),
		&"credits": credits,
		&"affordable": price >= 0 and credits >= price,
		&"reason": "" if price >= 0 and credits >= price else "크레딧 부족",
	}


func charge(transaction_id: StringName, price: int) -> Dictionary:
	if transaction_id == &"" or processed_transactions.has(transaction_id) \
			or bool(profile.call(&"has_processed_transaction", transaction_id)):
		return {&"success": false, &"reason": "중복 새로고침"}
	var current_quote := quote(price)
	if not bool(current_quote.get(&"affordable", false)):
		return {&"success": false, &"reason": current_quote.get(&"reason", "크레딧 부족")}
	if not bool(profile.call(&"spend", price)):
		return {&"success": false, &"reason": "크레딧 부족"}
	if not bool(profile.call(&"mark_transaction_processed", transaction_id)):
		profile.call(&"add_credits", price)
		return {&"success": false, &"reason": "새로고침 거래 기록 실패", &"compensated": true}
	processed_transactions[transaction_id] = true
	return {&"success": true, &"charged": price, &"transaction_id": transaction_id}
