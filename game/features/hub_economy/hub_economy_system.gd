class_name HubEconomySystem
extends Node

signal purchase_completed(result: Dictionary)

var profile: Node
var config: Resource


func configure(profile_provider: Node, economy_config: Resource) -> bool:
	if (
		not is_instance_valid(profile_provider)
		or not profile_provider.has_method(&"spend")
		or not profile_provider.has_method(&"add_warehouse_item")
		or economy_config == null
		or not economy_config.has_method(&"is_valid")
		or not economy_config.call(&"is_valid")
	):
		return false
	profile = profile_provider
	config = economy_config
	return true


func quote(offer_id: StringName) -> Dictionary:
	var offer: Dictionary = config.call(&"get_offer", offer_id) if config != null else {}
	if offer.is_empty():
		return {&"available": false, &"reason": "존재하지 않는 상점 항목"}
	var unlock_required := StringName(offer.get(&"required_unlock_id", &""))
	var registration_required := StringName(offer.get(&"required_offer_registration", &""))
	var available := (
		unlock_required == &""
		or bool(profile.call(&"is_unlocked", unlock_required))
	) and (
		registration_required == &""
		or (
			profile.has_method(&"is_shop_offer_registered")
			and bool(profile.call(&"is_shop_offer_registered", registration_required))
		)
	)
	return {
		&"available": available,
		&"offer": offer,
		&"can_afford": profile.call(&"can_spend", int(offer.get(&"price", 0))),
		&"registration_required": registration_required,
	}


func purchase(offer_id: StringName) -> Dictionary:
	var offer_quote := quote(offer_id)
	if not bool(offer_quote.get(&"available", false)):
		return {&"success": false, &"reason": offer_quote.get(&"reason", "잠긴 항목")}
	var offer: Dictionary = offer_quote[&"offer"]
	if not profile.call(&"spend", int(offer.get(&"price", 0))):
		return {&"success": false, &"reason": "크레딧 부족"}
	var offer_type := StringName(offer.get(&"offer_type", &"item"))
	var target_id := StringName(offer.get(&"target_id", &""))
	if offer_type == &"unlock":
		profile.call(&"unlock", target_id)
	elif offer_type == &"skill" and profile.has_method(&"unlock_skill"):
		profile.call(&"unlock_skill", target_id)
	else:
		profile.call(&"add_warehouse_item", target_id, int(offer.get(&"quantity", 1)))
	var result := {&"success": true, &"offer_id": offer_id, &"target_id": target_id}
	purchase_completed.emit(result)
	return result


func set_consumable_loadout(item_ids: Array[StringName]) -> bool:
	return profile.call(&"set_consumable_loadout", item_ids, 3)


func get_consumable_effects(item_ids: Array[StringName]) -> Dictionary:
	var player_modifiers: Dictionary = {}
	var healing := 0.0
	for item_id in item_ids:
		var effect: Dictionary = config.call(&"get_consumable_effect", item_id)
		healing += float(effect.get(&"heal", 0.0))
		var modifiers: Dictionary = effect.get(&"player_modifiers", {})
		for stat_id in modifiers:
			var modifier: Dictionary = modifiers[stat_id]
			var current: Dictionary = player_modifiers.get(stat_id, {
				&"add": 0.0, &"multiply": 1.0,
			})
			current[&"add"] = float(current.get(&"add", 0.0)) + float(modifier.get(&"add", 0.0))
			current[&"multiply"] = float(current.get(&"multiply", 1.0)) * float(
				modifier.get(&"multiply", 1.0)
			)
			player_modifiers[stat_id] = current
	return {&"player_modifiers": player_modifiers, &"heal": healing}


func get_snapshot() -> Dictionary:
	return {
		&"offer_count": config.get("offers").size() if config != null else 0,
		&"profile": profile.call(&"get_snapshot") if profile != null else {},
	}
