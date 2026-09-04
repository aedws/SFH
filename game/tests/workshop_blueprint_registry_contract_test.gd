extends SceneTree

const PROFILE_SCENE := preload("res://game/features/persistent_profile/persistent_profile.tscn")
const CONTRACT_SCENE := preload("res://game/features/operation_contract/operation_contract_service.tscn")
const P5_SCENE := preload("res://game/features/p5_hub_progression/p5_hub_progression_service.tscn")
const P5_CONFIG := preload("res://game/features/p5_hub_progression/configs/default_p5_hub_progression.tres")
const CONTRACT_CONFIG := preload("res://game/features/operation_contract/configs/default_operation_contracts.tres")
const PROFILE_PATH := "user://sfh_p7_blueprint_registry.json"

var failures := PackedStringArray()


func _init() -> void:
	call_deferred(&"_run")


func _run() -> void:
	if FileAccess.file_exists(PROFILE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PROFILE_PATH))
	var sandbox := Node.new()
	root.add_child(sandbox)
	var first := _create_session(sandbox)
	var first_p5: Node = first.get(&"p5")
	_check(first_p5 != null, "첫 제작소 구성")
	if first_p5 != null:
		var before: Dictionary = first_p5.call(&"get_snapshot").get(&"workshop", {})
		_check(int(before.get(&"candidate_count", -1)) == 3, "레시피 후보 3개")
		_check(int(before.get(&"registered_count", -1)) == 0, "초기 영구 등록 0개")
		_check(_candidate_state(before, &"assault_blueprint_recipe") == "도면 반출 필요", "잠금 사유 표시")
		var ignored: PackedStringArray = first_p5.call(&"register_extracted_blueprints", {&"unknown_blueprint": 1})
		_check(ignored.is_empty(), "레시피 없는 도면 등록 차단")
		var registered: PackedStringArray = first_p5.call(&"register_extracted_blueprints", {
			&"assault_rifle_blueprint": {&"quantity": 1},
		})
		_check(registered == PackedStringArray(["assault_rifle_blueprint"]), "반출 도면 1회 등록")
		_check(first_p5.call(&"register_extracted_blueprints", {&"assault_rifle_blueprint": 2}).is_empty(), "중복 등록 멱등")
		var after: Dictionary = first_p5.call(&"get_snapshot").get(&"workshop", {})
		_check(int(after.get(&"registered_count", -1)) == 1, "영구 등록 수 갱신")
		_check(_candidate_state(after, &"assault_blueprint_recipe") == "재제작 가능", "재제작 가능 표시")
		_check(bool(first_p5.call(&"craft_recipe", &"assault_blueprint_recipe", &"p7-03-craft").get(&"success", false)), "등록 도면 제작")

	for child in sandbox.get_children():
		child.queue_free()
	await process_frame
	var reloaded := _create_session(sandbox)
	var reloaded_p5: Node = reloaded.get(&"p5")
	_check(reloaded_p5 != null, "재접속 제작소 구성")
	if reloaded_p5 != null:
		var persisted: Dictionary = reloaded_p5.call(&"get_snapshot").get(&"workshop", {})
		_check(int(persisted.get(&"registered_count", -1)) == 1, "재접속 영구 등록 유지")
		_check(_candidate_state(persisted, &"assault_blueprint_recipe") == "재제작 가능", "재접속 제작 후보 유지")
		var facade_candidates: Array = reloaded_p5.call(&"get_workshop_candidates")
		_check(facade_candidates.size() == 3, "파사드 후보 조회")

	if FileAccess.file_exists(PROFILE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PROFILE_PATH))
	if failures.is_empty():
		print("P7_BLUEPRINT_REGISTRY_OK extraction permanent_registration unknown_guard idempotent reconnect recipe_candidates facade_status")
		quit(0)
	else:
		print("P7_BLUEPRINT_REGISTRY_FAILED: %s" % " / ".join(failures))
		quit(1)


func _create_session(sandbox: Node) -> Dictionary:
	var profile := PROFILE_SCENE.instantiate()
	var contract := CONTRACT_SCENE.instantiate()
	var p5 := P5_SCENE.instantiate()
	sandbox.add_child(profile)
	sandbox.add_child(contract)
	sandbox.add_child(p5)
	if not bool(profile.call(&"configure", PROFILE_PATH, true)):
		return {}
	if not bool(contract.call(&"configure", profile, CONTRACT_CONFIG)):
		return {}
	if not bool(p5.call(&"configure", profile, contract, P5_CONFIG, 703)):
		return {}
	return {&"profile": profile, &"contract": contract, &"p5": p5}


func _candidate_state(snapshot: Dictionary, recipe_id: StringName) -> String:
	for candidate in snapshot.get(&"candidates", []):
		if StringName(candidate.get(&"recipe_id", &"")) == recipe_id:
			return String(candidate.get(&"status_label", ""))
	return ""


func _check(condition: bool, label: String) -> void:
	if not condition:
		failures.append(label)
