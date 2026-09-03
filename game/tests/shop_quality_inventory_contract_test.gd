extends SceneTree

const PROFILE := preload("res://game/features/persistent_profile/persistent_profile.gd")
const SHOP := preload("res://game/features/p5_hub_progression/rotating_shop_service.gd")
const DELIVERY := preload("res://game/features/p5_hub_progression/shop_inventory_delivery_service.gd")
const INVENTORY := preload("res://game/features/inventory/grid_inventory.gd")
const EQUIPMENT_SCENE := preload("res://game/features/equipment/equipment_system.tscn")
const PLAYER_SCENE := preload("res://game/features/player/player.tscn")
const EDIT_SESSION := preload("res://game/features/inventory/inventory_edit_session.gd")

var failures := PackedStringArray()


func _init() -> void:
	call_deferred(&"_run")


func _run() -> void:
	var sandbox := Node.new()
	root.add_child(sandbox)
	var profile := PROFILE.new()
	var inventory := INVENTORY.new()
	var player := PLAYER_SCENE.instantiate()
	var equipment := EQUIPMENT_SCENE.instantiate()
	sandbox.add_child(profile)
	sandbox.add_child(inventory)
	sandbox.add_child(player)
	sandbox.add_child(equipment)
	_check(profile.configure("", false), "profile configured")
	_check(inventory.configure(load(
		"res://game/features/inventory/catalogs/default_inventory.tres"
	)), "inventory configured")
	_check(equipment.configure(
		load("res://game/features/equipment/loadouts/default_loadout.tres"),
		player, true, true, true
	), "equipment configured")

	var offers: Array[Dictionary] = []
	for quality in [&"damaged", &"standard", &"high_performance"]:
		offers.append({
			&"offer_id": StringName("%s_ballistic" % quality),
			&"display_name": "%s 탄도 코어" % quality,
			&"quality": quality,
			&"target_type": &"item",
			&"target_id": &"ballistic_core_item",
			&"quantity": 1,
			&"price": 100,
			&"performance_multiplier": (
				0.8 if quality == &"damaged" else 1.25 if quality == &"high_performance" else 1.0
			),
			&"runtime_enabled": true,
			&"source_status": "provisional",
		})
	var delivery := DELIVERY.new()
	var shop := SHOP.new()
	_check(delivery.configure(inventory), "delivery configured")
	_check(shop.configure(profile, offers, 7101, 25, 3), "shop configured")
	_check(shop.set_delivery_provider(delivery), "delivery bound")

	var high_quote: Dictionary = shop.quote(&"high_performance_ballistic")
	_check(
		high_quote.purchasable and high_quote.quality_applied
		and high_quote.delivery == "가방 실물 아이템 지급"
		and int(high_quote.quality_socket_count) == 1,
		"quality quote is concrete"
	)
	var before_bag := int(inventory.get_snapshot().items.size())
	var purchase: Dictionary = shop.purchase(
		&"high_performance_ballistic", &"quality-buy-1", shop.rotation_index
	)
	_check(purchase.success, "quality item purchased")
	_check(
		int(inventory.get_snapshot().items.size()) == before_bag + 1,
		"real item delivered"
	)
	var purchased_id := StringName(
		purchase.get(&"delivery", {}).get(&"instance_ids", [])[0]
	)
	var payload: Dictionary = inventory.get_runtime_payload(purchased_id)
	_check(
		payload.quality_id == &"high_performance"
		and is_equal_approx(float(payload.performance_multiplier), 1.25)
		and int(payload.quality_socket_count) == 1,
		"instance quality persisted"
	)

	var session := EDIT_SESSION.new()
	sandbox.add_child(session)
	session.configure(inventory, equipment)
	_check(session.begin(), "edit session begun")
	_check(session.install_item(purchased_id, &"main"), "purchased module installed")
	_check(session.commit(), "quality loadout committed")
	var installed = equipment.get_equipment_state(&"main").get_module_instance(purchased_id)
	_check(
		installed != null and is_equal_approx(installed.quality_multiplier(), 1.25),
		"quality follows I to U equipment"
	)
	_check(
		is_equal_approx(float(equipment.get_stat_modifiers().get(
			&"projectile_damage", {}
		).get(&"add", 0.0)), 1.25),
		"quality multiplier changes actual module stat"
	)

	_check(session.begin(), "second edit session begun")
	_check(session.remove_modification(&"main", &"module", purchased_id), "quality module removed")
	_check(session.commit(), "quality removal committed")
	var returned_quality_found := false
	for entry: Dictionary in inventory.get_snapshot().items:
		var returned_payload: Dictionary = entry.get(&"runtime_payload", {})
		if (
			returned_payload.get(&"transaction_id", &"") == &"quality-buy-1"
			and is_equal_approx(float(returned_payload.get(
				&"performance_multiplier", 0.0
			)), 1.25)
		):
			returned_quality_found = true
			break
	_check(returned_quality_found, "quality survives equipment to bag return")

	if failures.is_empty():
		print("P7_SHOP_QUALITY_OK quote delivery_instance option_socket inventory_equipment_roundtrip actual_stat_1_25")
		quit(0)
	else:
		printerr("P7_SHOP_QUALITY_FAILED: %s" % " / ".join(failures))
		quit(1)


func _check(condition: bool, label: String) -> void:
	if not condition:
		failures.append(label)
