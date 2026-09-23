extends SceneTree
const PROFILE = preload("res://game/features/persistent_profile/persistent_profile.gd")
const TRANSACTION = preload("res://game/features/p5_hub_progression/workshop_craft_transaction_service.gd")
const ROLL = preload("res://game/features/p5_hub_progression/configs/default_workshop_roll_policy.tres")
const SHOP = preload("res://game/features/p5_hub_progression/rotating_shop_service.gd")
const DELIVERY = preload("res://game/features/p5_hub_progression/shop_inventory_delivery_service.gd")
const BAG = preload("res://game/features/inventory/grid_inventory.gd")
var failures: Array[String] = []

class InvalidRoll extends WorkshopRollPolicy:
	func roll(recipe: Dictionary, recipe_id: StringName, transaction_id: StringName, seed_value: int) -> Dictionary:
		var result := super.roll(recipe, recipe_id, transaction_id, seed_value)
		result.socket_count = 3
		result.sockets = [{}, {}, {}]
		return result

func _init() -> void: call_deferred(&"run_test")
func check(value: bool, message: String) -> void:
	if not value: failures.append(message)

func run_test() -> void:
	var policy := EquipmentSupplyPolicy.new()
	for grade in range(1, 6): check(policy.source_error({&"grade": grade}).is_empty() == (grade <= 3), "grade cap %d" % grade)
	check(not policy.source_error({&"unique_modifiers": [&"chain_explosion"]}).is_empty(), "unique rejected")
	check(not policy.source_error({&"deep_only": true}).is_empty(), "deep exclusive rejected")
	var recipe := {&"recipe_id": &"test", &"result_id": &"test", &"grade": 3, &"credit_cost": 10, &"minimum_affixes": 1, &"maximum_affixes": 2, &"minimum_sockets": 0, &"maximum_sockets": 2}
	var original := recipe.duplicate(true)
	for seed_value in 100:
		var item: Dictionary = ROLL.roll(recipe, &"test", StringName("roll_%d" % seed_value), seed_value)
		check(not item.is_empty() and policy.crafted_error(item).is_empty(), "bounded deterministic roll")
	check(recipe == original, "recipe input immutable")
	var high := recipe.duplicate(true)
	high.maximum_sockets = 3
	check(not ROLL.describe(high).valid and ROLL.roll(high, &"test", &"bad", 1).is_empty(), "reject not silently clamp high socket")
	var profile := PROFILE.new()
	root.add_child(profile)
	profile.configure("", false, true)
	var transaction := TRANSACTION.new()
	check(transaction.configure(profile, ROLL, 9), "transaction configure")
	var before: Dictionary = profile.get_snapshot()
	check(not transaction.execute(high, {&"scrap": 1}, true, &"denied").success and profile.get_snapshot() == before, "blocked recipe no charge")
	var malicious := InvalidRoll.new()
	malicious.affix_pool = ROLL.affix_pool.duplicate(true)
	check(transaction.configure(profile, malicious, 9), "replaceable roll")
	check(not transaction.execute(recipe, {&"scrap": 1}, true, &"bad_supplier").success and profile.get_snapshot() == before, "supplier result revalidated before save")
	transaction.configure(profile, ROLL, 9)
	check(transaction.execute(recipe, {&"scrap": 1}, true, &"good").success, "normal craft works")
	check(not transaction.execute(recipe, {&"scrap": 1}, true, &"good").success, "duplicate craft blocked")
	var inventory := BAG.new()
	root.add_child(inventory)
	var catalog: Resource = load("res://game/features/inventory/catalogs/default_inventory.tres").duplicate(true)
	check(inventory.configure(catalog), "bag configure")
	var delivery := DELIVERY.new()
	check(delivery.configure(inventory), "delivery configure")
	var offer := {&"offer_id": &"rare_test", &"target_type": &"item", &"target_id": &"spare_assault_rifle", &"quality": &"standard", &"performance_multiplier": 1.0, &"quantity": 1, &"price": 10, &"runtime_enabled": true}
	var weapon: Resource = inventory.get_item_definition(&"spare_assault_rifle").linked_resource
	var saved_grade: int = weapon.grade
	weapon.grade = 4
	check(delivery.preview(offer).get(&"supply_blocked", false), "actual definition not only offer checked")
	check(not delivery.deliver(offer, &"illegal").success, "direct delivery blocked")
	weapon.grade = saved_grade
	var shop := SHOP.new()
	var offers: Array[Dictionary] = [offer]
	check(shop.configure(profile, offers, 1, 25, 1), "shop configure")
	check(shop.set_delivery_provider(delivery), "shop bind")
	weapon.extension_data[&"deep_only"] = true
	before = profile.get_snapshot()
	check(shop.get_snapshot().offers.is_empty(), "blocked equipment hidden")
	check(not shop.purchase(&"rare_test", &"bad_buy").success and before == profile.get_snapshot(), "direct buy blocked no debit")
	check(not shop.refresh(true, &"bad_reroll").success and before == profile.get_snapshot(), "empty eligible reroll no debit")
	weapon.extension_data.erase(&"deep_only")
	var legacy_craft := preload("res://game/features/crafting/crafting_system.gd").new()
	root.add_child(legacy_craft)
	var legacy_config: Resource = load("res://game/features/crafting/configs/default_crafting.tres").duplicate(true)
	legacy_config.recipes[0][&"deep_only"] = true
	check(legacy_craft.configure(profile, legacy_config, 1), "legacy craft setup")
	before = profile.get_snapshot()
	check(not legacy_craft.craft(&"assault_rifle_blueprint").success and before == profile.get_snapshot(), "legacy craft gate before spend")
	var legacy_shop := preload("res://game/features/hub_economy/hub_economy_system.gd").new()
	root.add_child(legacy_shop)
	var economy_config: Resource = load("res://game/features/hub_economy/configs/default_hub_economy.tres").duplicate(true)
	economy_config.offers[0][&"grade"] = 5
	check(legacy_shop.configure(profile, economy_config), "legacy shop setup")
	check(not legacy_shop.purchase(&"buy_field_medkit").success and before == profile.get_snapshot(), "legacy shop gate before spend")
	legacy_craft.free()
	legacy_shop.free()
	profile.free()
	inventory.free()
	if failures.is_empty(): print("HUB_SUPPLY_OK cap recipe source hidden no_debit result_guard immutable legacy_preserved")
	else: printerr("HUB_SUPPLY_FAILED ", failures)
	quit(0 if failures.is_empty() else 1)
