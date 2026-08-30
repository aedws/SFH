class_name OperationResultService
extends Node

signal operation_settled(result: Dictionary)

var profile: Node
var ranking: Node
var config: Resource
var random := RandomNumberGenerator.new()


func configure(
	profile_provider: Node,
	ranking_provider: Node = null,
	result_config: Resource = null,
	seed: int = 0
) -> bool:
	if (
		not is_instance_valid(profile_provider)
		or not profile_provider.has_method(&"add_credits")
		or result_config == null
		or not result_config.has_method(&"is_valid")
		or not result_config.call(&"is_valid")
	):
		return false
	profile = profile_provider
	ranking = ranking_provider
	config = result_config
	random.seed = seed if seed != 0 else Time.get_ticks_usec()
	return true


func settle_success(run_data: Dictionary, contract: Dictionary) -> Dictionary:
	var raw_credits := maxi(0, int(run_data.get(&"carried_credits", 0)))
	var reward_multiplier := maxf(1.0, float(contract.get(&"reward_multiplier", 1.0)))
	var recovered := roundi(float(raw_credits) * reward_multiplier)
	profile.call(&"add_credits", recovered)
	var salvage := maxi(
		int(config.get("minimum_salvage")),
		int(run_data.get(&"kills", 0)) / int(config.get("kills_per_salvage"))
	)
	profile.call(&"add_warehouse_item", &"scrap", salvage)
	var blueprint_id: StringName = &""
	var blueprint_chance := clampf(
		float(config.get("base_blueprint_chance"))
		* float(contract.get(&"blueprint_drop_multiplier", 1.0)), 0.0, 0.8
	)
	if random.randf() <= blueprint_chance:
		blueprint_id = config.call(
			&"blueprint_for", StringName(contract.get(&"region_id", &"ruined_city"))
		)
		profile.call(&"add_blueprint", blueprint_id, 1)
	var ranking_result := {}
	if is_instance_valid(ranking):
		ranking_result = ranking.call(&"submit_run", {
			&"success": true,
			&"condition_key": contract.get(&"ranking_condition_key", ""),
			&"elapsed_seconds": run_data.get(&"elapsed_seconds", 0.0),
			&"kills": run_data.get(&"kills", 0),
			&"recovered_value": recovered,
			&"reward_multiplier": reward_multiplier,
		})
	var result := {
		&"success": true,
		&"raw_credits": raw_credits,
		&"recovered_credits": recovered,
		&"salvage": salvage,
		&"blueprint_id": blueprint_id,
		&"ranking": ranking_result,
		&"profile": profile.call(&"get_snapshot"),
	}
	operation_settled.emit(result)
	return result


func settle_failure(run_data: Dictionary, contract: Dictionary) -> Dictionary:
	var result := {
		&"success": false,
		&"lost_credits": maxi(0, int(run_data.get(&"carried_credits", 0))),
		&"entry_cost": int(contract.get(&"entry_cost", 0)),
		&"profile": profile.call(&"get_snapshot"),
	}
	operation_settled.emit(result)
	return result
