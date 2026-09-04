extends SceneTree

var isolation := preload("res://game/tests/support/save_test_isolation.gd").new()
var failures: Array[String] = []


func _init() -> void:
	node_added.connect(isolation.isolate)
	call_deferred(&"_run")


func _run() -> void:
	var scene: PackedScene = load("res://game/scenes/game.tscn")
	var game: Node = scene.instantiate()
	var features: Resource = game.features.duplicate(true)
	features.shop_item_delivery_enabled = false
	game.features = features
	root.add_child(game)
	for _frame in 6:
		await process_frame
	_check(game.p5_hub_progression_service != null, "P5 remains active")
	_check(game.inventory_system != null, "inventory remains active")
	_check(
		&"shop_item_delivery" not in features.call(&"enabled_module_ids"),
		"delivery module absent"
	)
	var shop: Dictionary = game.p5_hub_progression_service.call(&"get_shop_snapshot")
	var offers: Array = shop.get(&"offers", [])
	_check(not offers.is_empty(), "shop remains active")
	if not offers.is_empty():
		var offer: Dictionary = offers[0]
		var target_id := StringName(offer.get(&"target_id", &""))
		var quantity := int(offer.get(&"quantity", 0))
		var before_bag := int(game.inventory_system.get_snapshot().items.size())
		var before_warehouse := int(
			game.persistent_profile.get_snapshot().warehouse.get(target_id, 0)
		)
		var result: Dictionary = game.p5_hub_progression_service.call(
			&"purchase_shop_offer", offer.get(&"offer_id", &""),
			&"delivery-disabled-purchase", int(shop.get(&"rotation_index", -1))
		)
		_check(bool(result.get(&"success", false)), "legacy purchase succeeds")
		_check(
			int(game.inventory_system.get_snapshot().items.size()) == before_bag,
			"bag unchanged"
		)
		_check(
			int(game.persistent_profile.get_snapshot().warehouse.get(target_id, 0))
			== before_warehouse + quantity,
			"warehouse receives purchase"
		)
	var invalid_features: Resource = features.duplicate(true)
	invalid_features.shop_item_delivery_enabled = true
	invalid_features.inventory_enabled = false
	_check(
		not invalid_features.call(&"validation_errors").is_empty(),
		"manifest rejects missing dependency"
	)
	game.free()
	await process_frame
	if failures.is_empty():
		print("P7_SHOP_DELIVERY_MODULE_OK p5_on delivery_off legacy_warehouse bag_unchanged manifest_dependency")
		quit(0)
	else:
		printerr("P7_SHOP_DELIVERY_MODULE_FAILED: %s" % " / ".join(failures))
		quit(1)


func _check(condition: bool, label: String) -> void:
	if not condition:
		failures.append(label)
