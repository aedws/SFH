class_name HubEconomyConfig
extends Resource

@export var offers: Array[Dictionary] = []
@export var consumable_effects: Dictionary = {}


func is_valid() -> bool:
	var ids := {}
	for offer in offers:
		var offer_id := StringName(offer.get(&"offer_id", &""))
		if offer_id == &"" or ids.has(offer_id) or int(offer.get(&"price", -1)) < 0:
			return false
		ids[offer_id] = true
	return not offers.is_empty()


func get_offer(offer_id: StringName) -> Dictionary:
	for offer in offers:
		if StringName(offer.get(&"offer_id", &"")) == offer_id:
			return offer.duplicate(true)
	return {}


func get_consumable_effect(item_id: StringName) -> Dictionary:
	return (consumable_effects.get(item_id, {}) as Dictionary).duplicate(true)
