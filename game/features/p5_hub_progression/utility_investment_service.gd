class_name UtilityInvestmentService
extends RefCounted

var profile: Node
var catalog: Array[Dictionary] = []
var selected: Dictionary = {}
var active_run_id: StringName = &""
var active_quantities: Dictionary = {}


func configure(profile_provider: Node, rows: Array[Dictionary]) -> bool:
	if not is_instance_valid(profile_provider) or rows.is_empty():
		return false
	profile = profile_provider
	catalog = rows.duplicate(true)
	for row in catalog:
		if bool(row.get(&"default_owned", false)) and StringName(row.get(&"utility_type", &"")) == &"bag":
			var id := StringName(row.get(&"utility_id", &""))
			selected[id] = 1
	return true


func set_quantity(utility_id: StringName, quantity: int) -> bool:
	var item := _find(utility_id)
	if item.is_empty() or quantity < 0 or quantity > int(item.get(&"max_quantity", 0)):
		return false
	var unlock_id := StringName(item.get(&"required_unlock_id", &""))
	if quantity > 0 and unlock_id != &"" and not bool(profile.call(&"is_unlocked", unlock_id)):
		return false
	if quantity == 0:
		selected.erase(utility_id)
	else:
		selected[utility_id] = quantity
	return true


func get_investment_context() -> Dictionary:
	var cost := 0
	var entries: Array[Dictionary] = []
	for id in selected:
		var item := _find(id)
		var quantity := int(selected[id])
		cost += int(item.get(&"run_price", 0)) * quantity
		entries.append({&"utility_id": id, &"display_name": item.get(&"display_name", id),
			&"quantity": quantity, &"utility_type": item.get(&"utility_type", &""),
			&"price": int(item.get(&"run_price", 0)) * quantity})
	return {&"additional_entry_cost": cost, &"utilities": entries}


func begin_run(run_id: StringName) -> bool:
	if run_id == &"" or active_run_id != &"":
		return false
	active_run_id = run_id
	active_quantities = selected.duplicate(true)
	return true


func use(utility_id: StringName, condition: StringName) -> Dictionary:
	var item := _find(utility_id)
	if active_run_id == &"" or item.is_empty() or int(active_quantities.get(utility_id, 0)) <= 0:
		return {&"success": false, &"reason": "보유 수량 없음"}
	var required := StringName(item.get(&"use_condition", &""))
	if required not in [&"", &"passive"] and required != condition:
		return {&"success": false, &"reason": "사용 조건 불일치"}
	active_quantities[utility_id] = int(active_quantities[utility_id]) - 1
	return {&"success": true, &"utility_id": utility_id,
		&"effect_id": item.get(&"effect_id", &""), &"effect_value": item.get(&"effect_value", 0),
		&"remaining": active_quantities[utility_id]}


func settle_run(_extracted: bool) -> Dictionary:
	var expired := active_quantities.duplicate(true)
	active_run_id = &""
	active_quantities.clear()
	return {&"expired": expired, &"persistent_grant": {}}


func get_snapshot() -> Dictionary:
	return {&"selected": selected.duplicate(true), &"active": active_quantities.duplicate(true),
		&"active_run_id": active_run_id, &"investment": get_investment_context(),
		&"catalog_count": catalog.size()}


func _find(utility_id: StringName) -> Dictionary:
	for row in catalog:
		if StringName(row.get(&"utility_id", &"")) == utility_id:
			return row
	return {}
