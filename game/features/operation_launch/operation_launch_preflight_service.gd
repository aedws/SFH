class_name OperationLaunchPreflightService
extends Node

## 작전 설정 기여자와 런타임 검증기를 모아, 결제 전에 불변 작전 계획을 만듭니다.

signal plan_changed(snapshot: Dictionary)

const CONTRIBUTION_METHOD := &"get_operation_setting_contribution"
const VALIDATION_METHOD := &"validate_operation_launch"

var contract_service: Node
var profile: Node
var contributors: Dictionary = {}
var validators: Dictionary = {}
var active_plan: Dictionary = {}
var plan_sequence := 0


func configure(new_contract_service: Node, new_profile: Node) -> bool:
	if (
		not is_instance_valid(new_contract_service)
		or not new_contract_service.has_method(&"quote")
		or not is_instance_valid(new_profile)
		or not new_profile.has_method(&"can_spend")
	):
		return false
	contract_service = new_contract_service
	profile = new_profile
	return true


func register_contributor(contributor_id: StringName, provider: Node) -> bool:
	if contributor_id == &"" or not is_instance_valid(provider) or not provider.has_method(CONTRIBUTION_METHOD):
		return false
	contributors[contributor_id] = provider
	return true


func unregister_contributor(contributor_id: StringName) -> void:
	contributors.erase(contributor_id)


func register_validator(validator_id: StringName, provider: Node) -> bool:
	if validator_id == &"" or not is_instance_valid(provider) or not provider.has_method(VALIDATION_METHOD):
		return false
	validators[validator_id] = provider
	return true


func unregister_validator(validator_id: StringName) -> void:
	validators.erase(validator_id)


func get_investment_context() -> Dictionary:
	return _collect_contributions().get(&"investment_context", {})


func create_plan(
	tier_config: Resource,
	penalty_snapshot: Dictionary = {},
	runtime_context: Dictionary = {}
) -> Dictionary:
	var collected := _collect_contributions()
	var errors: PackedStringArray = collected.get(&"errors", PackedStringArray())
	if tier_config == null:
		errors.append("작전 규모 설정이 없습니다.")
	var investment_context: Dictionary = collected.get(&"investment_context", {})
	var quote: Dictionary = (
		contract_service.call(&"quote", tier_config, penalty_snapshot, investment_context)
		if tier_config != null else {}
	)
	if quote.is_empty():
		errors.append("작전 견적을 만들 수 없습니다.")
	elif (
		not bool(quote.get(&"bankruptcy_protection", false))
		and not bool(profile.call(&"can_spend", int(quote.get(&"entry_cost", 0))))
	):
		errors.append("보유 크레딧이 투입 비용보다 적습니다.")
	var request := {
		&"tier_config": tier_config,
		&"tier_id": StringName(tier_config.get("tier_id")) if tier_config != null else &"",
		&"penalty_snapshot": penalty_snapshot.duplicate(true),
		&"investment_context": investment_context.duplicate(true),
		&"quote": quote.duplicate(true),
		&"runtime_context": runtime_context.duplicate(true),
	}
	for validator_id in _sorted_keys(validators):
		var provider: Node = validators[validator_id]
		if not is_instance_valid(provider):
			errors.append("작전 검증기 연결이 끊겼습니다: %s" % validator_id)
			continue
		var validation_result: Variant = provider.call(VALIDATION_METHOD, request)
		if not validation_result is Array and not validation_result is PackedStringArray:
			errors.append("작전 검증기가 오류 목록 계약을 지키지 않았습니다: %s" % validator_id)
			continue
		for message in validation_result:
			errors.append("%s · %s" % [validator_id, message])
	plan_sequence += 1
	var plan := {
		&"success": errors.is_empty(),
		&"plan_id": StringName("operation-plan-%d" % plan_sequence),
		&"tier_id": request[&"tier_id"],
		&"penalty_snapshot": request[&"penalty_snapshot"],
		&"investment_context": investment_context.duplicate(true),
		&"quote": quote.duplicate(true),
		&"contributions": collected.get(&"contributions", []).duplicate(true),
		&"errors": errors,
		&"reason": " / ".join(errors),
	}
	plan[&"signature"] = _signature(plan)
	active_plan = plan.duplicate(true) if errors.is_empty() else {}
	plan_changed.emit(get_snapshot())
	return plan


func validate_plan(plan: Dictionary) -> bool:
	return (
		bool(plan.get(&"success", false))
		and not String(plan.get(&"plan_id", "")).is_empty()
		and int(plan.get(&"signature", 0)) == _signature(plan)
	)


func contract_matches_plan(plan: Dictionary, contract: Dictionary) -> bool:
	if not validate_plan(plan) or not bool(contract.get(&"success", false)):
		return false
	return (
		StringName(contract.get(&"tier_id", &"")) == StringName(plan.get(&"tier_id", &""))
		and int(contract.get(&"entry_cost", -1)) == int(plan.get(&"quote", {}).get(&"entry_cost", -2))
		and contract.get(&"investment_context", {}) == plan.get(&"investment_context", {})
	)


func clear_plan() -> void:
	active_plan.clear()
	plan_changed.emit(get_snapshot())


func get_snapshot() -> Dictionary:
	return {
		&"contributor_ids": _sorted_keys(contributors),
		&"validator_ids": _sorted_keys(validators),
		&"active_plan_id": active_plan.get(&"plan_id", &""),
		&"active_plan_valid": validate_plan(active_plan) if not active_plan.is_empty() else false,
	}


func _collect_contributions() -> Dictionary:
	var errors := PackedStringArray()
	var context: Dictionary = {}
	var contribution_snapshots: Array[Dictionary] = []
	var total_cost := 0
	for registered_id in _sorted_keys(contributors):
		var provider: Node = contributors[registered_id]
		if not is_instance_valid(provider):
			errors.append("설정 기여자 연결이 끊겼습니다: %s" % registered_id)
			continue
		var contribution_result: Variant = provider.call(CONTRIBUTION_METHOD)
		if not contribution_result is Dictionary:
			errors.append("설정 기여자가 Dictionary 계약을 지키지 않았습니다: %s" % registered_id)
			continue
		var contribution: Dictionary = contribution_result
		var contributor_id := StringName(contribution.get(&"contributor_id", &""))
		if contributor_id != StringName(registered_id):
			errors.append("설정 기여자 ID가 일치하지 않습니다: %s" % registered_id)
			continue
		var cost := int(contribution.get(&"additional_entry_cost", 0))
		if cost < 0:
			errors.append("설정 기여 비용은 음수일 수 없습니다: %s" % registered_id)
			continue
		for message in contribution.get(&"validation_errors", PackedStringArray()):
			errors.append("%s · %s" % [registered_id, message])
		var payload: Dictionary = contribution.get(&"context", {})
		if not _is_snapshot_safe(payload):
			errors.append("설정 기여 문맥은 복사 가능한 값만 포함해야 합니다: %s" % registered_id)
			continue
		var context_key := StringName(contribution.get(&"context_key", &""))
		if context_key == &"":
			for key in payload:
				if key == &"additional_entry_cost" or key == "additional_entry_cost":
					continue
				if context.has(key) and context[key] != payload[key]:
					errors.append("설정 문맥 키가 충돌합니다: %s" % key)
				else:
					context[key] = payload[key]
		else:
			if context.has(context_key):
				errors.append("설정 문맥 영역이 중복됩니다: %s" % context_key)
			else:
				context[context_key] = payload.duplicate(true)
		total_cost += cost
		contribution_snapshots.append(contribution.duplicate(true))
	context[&"additional_entry_cost"] = total_cost
	return {
		&"investment_context": context,
		&"contributions": contribution_snapshots,
		&"errors": errors,
	}


func _signature(plan: Dictionary) -> int:
	var payload := plan.duplicate(true)
	payload.erase(&"signature")
	return JSON.stringify(payload).hash()


func _is_snapshot_safe(value: Variant) -> bool:
	match typeof(value):
		TYPE_NIL, TYPE_BOOL, TYPE_INT, TYPE_FLOAT, TYPE_STRING, TYPE_STRING_NAME:
			return true
		TYPE_DICTIONARY:
			for key in value:
				if not _is_snapshot_safe(key) or not _is_snapshot_safe(value[key]):
					return false
			return true
		TYPE_ARRAY:
			for item in value:
				if not _is_snapshot_safe(item):
					return false
			return true
		TYPE_PACKED_BYTE_ARRAY, TYPE_PACKED_INT32_ARRAY, TYPE_PACKED_INT64_ARRAY, \
		TYPE_PACKED_FLOAT32_ARRAY, TYPE_PACKED_FLOAT64_ARRAY, TYPE_PACKED_STRING_ARRAY:
			return true
		_:
			return false


func _sorted_keys(source: Dictionary) -> Array:
	var keys := source.keys()
	keys.sort_custom(func(left, right): return String(left) < String(right))
	return keys
