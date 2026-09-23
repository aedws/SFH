class_name WorkshopCraftTransactionService
extends RefCounted

var profile: Node
var roll_policy: Resource
var session_seed := 70404
var supply_policy := EquipmentSupplyPolicy.hub_default()


func configure(profile_provider: Node, workshop_roll_policy: Resource, seed: int) -> bool:
	profile = profile_provider
	roll_policy = workshop_roll_policy
	supply_policy = EquipmentSupplyPolicy.hub_default()
	if roll_policy != null and roll_policy.has_method(&"get_supply_policy"):
		var supplied: Resource = roll_policy.call(&"get_supply_policy")
		if not supplied is EquipmentSupplyPolicy or not supplied.is_valid(): return false
		supply_policy = supplied.duplicate(true)
	session_seed = seed if seed != 0 else 70404
	return (
		is_instance_valid(profile)
		and profile.has_method(&"get_snapshot")
		and profile.has_method(&"apply_economy_transaction")
		and profile.has_method(&"has_processed_transaction")
		and roll_policy != null
		and roll_policy.has_method(&"is_valid")
		and bool(roll_policy.call(&"is_valid"))
		and roll_policy.has_method(&"describe")
		and roll_policy.has_method(&"roll")
	)


func quote(recipe: Dictionary, materials: Dictionary, registration_ready: bool) -> Dictionary:
	var snapshot: Dictionary = profile.call(&"get_snapshot") if is_instance_valid(profile) else {}
	var credit_cost := int(recipe.get(&"credit_cost", -1))
	var roll_preview: Dictionary = roll_policy.call(&"describe", recipe) if roll_policy != null else {}
	var material_preview: Array[Dictionary] = []
	var materials_ready := _valid_materials(materials)
	for item_id in materials:
		var required := int(materials[item_id])
		var owned := int(snapshot.get(&"warehouse", {}).get(item_id, 0))
		material_preview.append({
			&"item_id": StringName(item_id), &"required": required, &"owned": owned,
			&"ready": required > 0 and owned >= required,
		})
		materials_ready = materials_ready and required > 0 and owned >= required
	var reason := ""
	if not registration_ready:
		reason = "영구 등록 도면 필요"
	elif credit_cost < 0 or not bool(roll_preview.get(&"valid", false)) or not _valid_materials(materials):
		reason = String(roll_preview.get(&"reason", "제작 데이터 오류"))
		if reason.is_empty(): reason = "제작 데이터 오류"
	elif int(snapshot.get(&"banked_credits", 0)) < credit_cost:
		reason = "크레딧 부족"
	elif not materials_ready:
		reason = "재료 부족"
	var source_check := supply_policy.recipe_preview(recipe)
	if not source_check.valid: reason = source_check.reason
	return {
		&"craftable": reason.is_empty(),
		&"reason": reason,
		&"recipe": recipe.duplicate(true),
		&"credit_cost": maxi(0, credit_cost),
		&"credits": int(snapshot.get(&"banked_credits", 0)),
		&"balance_after": int(snapshot.get(&"banked_credits", 0)) - maxi(0, credit_cost),
		&"materials": materials.duplicate(true),
		&"material_preview": material_preview,
		&"roll_preview": roll_preview,
	}


func execute(recipe: Dictionary, materials: Dictionary, registration_ready: bool,
		transaction_id: StringName) -> Dictionary:
	if transaction_id == &"" or bool(profile.call(&"has_processed_transaction", transaction_id)):
		return {&"success": false, &"reason": "중복 제작"}
	var draft := quote(recipe, materials, registration_ready)
	if not bool(draft.get(&"craftable", false)):
		return {&"success": false, &"reason": draft.get(&"reason", "제작 불가"), &"quote": draft}
	var recipe_id := StringName(recipe.get(&"recipe_id", &""))
	var item: Dictionary = roll_policy.call(&"roll", recipe, recipe_id, transaction_id, session_seed)
	if item.is_empty():
		return {&"success": false, &"reason": "옵션 생성 실패", &"quote": draft}
	var supply_error := supply_policy.crafted_error(item)
	if not supply_error.is_empty(): return {&"success": false, &"reason": supply_error, &"quote": draft}
	var warehouse_deltas := {}
	for item_id in materials:
		warehouse_deltas[StringName(item_id)] = -int(materials[item_id])
	var transaction: Dictionary = profile.call(
		&"apply_economy_transaction", transaction_id, -int(draft[&"credit_cost"]),
		warehouse_deltas, item
	)
	if not bool(transaction.get(&"success", false)):
		return {
			&"success": false,
			&"reason": transaction.get(&"reason", "제작 거래 실패"),
			&"quote": draft,
		}
	return {
		&"success": true,
		&"item": item,
		&"consumed": materials.duplicate(true),
		&"credit_cost": int(draft[&"credit_cost"]),
		&"balance_after": int(transaction.get(&"balance_after", draft[&"balance_after"])),
		&"transaction_id": transaction_id,
	}


func _valid_materials(materials: Dictionary) -> bool:
	for item_id in materials:
		if StringName(item_id) == &"" or int(materials[item_id]) <= 0:
			return false
	return true
