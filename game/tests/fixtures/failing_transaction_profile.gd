extends "res://game/features/persistent_profile/persistent_profile.gd"


func mark_transaction_processed(_transaction_id: StringName) -> bool:
	return false


func apply_economy_transaction(_transaction_id: StringName, _credit_delta: int,
		_warehouse_deltas: Dictionary, _crafted_item: Dictionary = {}) -> Dictionary:
	return {&"success": false, &"reason": "강제 원자 거래 실패"}
