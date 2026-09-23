class_name InventoryCapacityService
extends "res://game/features/balance_data/validated_csv_catalog_service.gd"
## Profile unlock + payment is one durable transaction. Bag geometry is a projection.
var bag: Node
var profile: Node
var purchase_allowed: Callable

func _init() -> void:
	catalog_name = "ContainerCapacity"
	live_csv_url = "https://docs.google.com/spreadsheets/d/1dtQKVZiMf7VRFWrVnaL3BqzR0g4ZgEG6ueH9RIN3xqM/gviz/tq?tqx=out:csv&headers=1&sheet=ContainerCapacity"
	catalog = create_catalog()

func create_catalog() -> RefCounted: return InventoryCapacityCatalog.new()

func bind(inventory: Node, account: Node, guard: Callable) -> bool:
	bag = inventory
	profile = account
	purchase_allowed = guard
	if not catalog_changed.is_connected(_on_catalog_changed): catalog_changed.connect(_on_catalog_changed)
	return apply_current()

func current_row(kind: StringName) -> Dictionary:
	var result := {}
	for row in get_rows():
		if row.container_id == kind and (row.stage == 0 or (is_instance_valid(profile) and profile.call(&"is_unlocked", unlock_id(row)))): result = row
	return result

func unlock_id(row: Dictionary) -> StringName: return StringName("container_%s_%d" % [row.container_id, row.stage])

func get_quote(kind: StringName) -> Dictionary:
	var current := current_row(kind)
	for row in get_rows():
		if row.container_id != kind or row.stage != int(current.get(&"stage", -1)) + 1: continue
		var quote := row.duplicate(true)
		quote[&"available"] = is_instance_valid(bag) and bag.reserve_access_enabled and purchase_allowed.is_valid() and purchase_allowed.call() and row.upgrade_enabled and is_instance_valid(profile) and profile.call(&"can_spend", row.credit_cost)
		return quote
	return {}

func purchase(kind: StringName, expected: Dictionary) -> Dictionary:
	var quote := get_quote(kind)
	if quote.is_empty() or quote != expected or not quote.available: return {&"success": false, &"reason": "확장 조건 또는 가격이 바뀌었습니다. 거점에서 다시 확인하세요."}
	var candidate := _project(quote)
	if candidate.is_empty() or not bag.validate_runtime_state(candidate).is_empty(): return {&"success": false, &"reason": "가방 이관 검증 실패 · 결제하지 않았습니다."}
	var grants: Array[StringName] = [unlock_id(quote)]
	var paid: Dictionary = profile.call(&"apply_economy_transaction", unlock_id(quote), -int(quote.credit_cost), {}, {}, grants)
	if not paid.get(&"success", false): return paid
	# The unlock is authoritative even if a crash interrupts its geometric projection.
	if not apply_current():
		return {&"success": false, &"reason": "확장은 저장됐지만 가방 반영에 실패했습니다. 재결제하지 말고 거점으로 다시 들어오세요."}
	return {&"success": true, &"reason": "영구 확장 완료", &"stage": quote.stage}

func apply_current() -> bool:
	if not is_instance_valid(bag): return false
	var state := _project({})
	if state.is_empty() or not bag.validate_runtime_state(state).is_empty(): return false
	var row := current_row(&"backpack")
	bag.restore_capacity = Vector2i(row.columns, row.rows)
	return bag.restore_runtime_state(state)

func _project(override_row: Dictionary) -> Dictionary:
	var backpack := current_row(&"backpack")
	var pouch_row := current_row(&"pouch")
	if not override_row.is_empty():
		if override_row.container_id == &"backpack": backpack = override_row
		else: pouch_row = override_row
	if backpack.is_empty() or pouch_row.is_empty(): return {}
	var state: Dictionary = bag.prepare_capacity_restore(bag.export_runtime_state(), Vector2i(backpack.columns, backpack.rows))
	if state.is_empty(): return {}
	state[&"pouch_size"] = Vector2i(pouch_row.columns, pouch_row.rows)
	var fitting := {}
	for id in state.get(&"pouch", {}):
		var entry: Dictionary = state.pouch[id]
		var position := InventoryPouchPolicy.position_for(fitting, InventoryReservePolicy.size_of(entry), state.pouch_size)
		if position.x < 0: state.reserve[id] = entry
		else:
			entry.position = position
			fitting[id] = entry
	state[&"pouch"] = fitting
	return state

func _on_catalog_changed(_snapshot: Dictionary) -> void:
	# Never shrink a running/training bag or apply provisional rows to its frozen state.
	if is_instance_valid(bag) and purchase_allowed.is_valid() and purchase_allowed.call(): apply_current()
