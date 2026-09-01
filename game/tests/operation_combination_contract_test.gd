extends SceneTree

const GAME_SCENE_PATH := "res://game/scenes/game.tscn"
const TIERS := [&"small", &"medium", &"large"]
const DIFFICULTIES := [&"standard", &"veteran", &"nightmare"]


func _init() -> void:
	call_deferred(&"_run")


func _run() -> void:
	var game_scene := load(GAME_SCENE_PATH) as PackedScene
	if game_scene == null:
		_fail("게임 장면을 불러오지 못했습니다.")
		return
	var verified := 0
	for tier_id in TIERS:
		for difficulty_id in DIFFICULTIES:
			var game := game_scene.instantiate()
			var features: Resource = game.get("features").duplicate(true)
			var suffix := "%s_%s" % [tier_id, difficulty_id]
			features.set("map_seed", 4040600 + verified)
			features.set("persistent_profile_storage_path", "user://sfh_combo_%s_profile.json" % suffix)
			features.set("conditional_ranking_storage_path", "user://sfh_combo_%s_rankings.json" % suffix)
			features.set("meta_progression_storage_path", "user://sfh_combo_%s_meta.json" % suffix)
			features.set("key_mapping_storage_path", "user://sfh_combo_%s_keys.json" % suffix)
			features.set("skill_binding_storage_path", "user://sfh_combo_%s_skills.json" % suffix)
			game.set("features", features)
			root.add_child(game)
			await process_frame
			await process_frame
			var profile = game.get("persistent_profile")
			var contracts = game.get("operation_contract_service")
			var failure := ""
			if profile == null or contracts == null:
				failure = "프로필 또는 작전 계약 서비스가 없습니다."
			else:
				profile.call(&"reset_profile", true)
				if not contracts.call(&"select_difficulty", difficulty_id):
					failure = "난이도 선택이 거부됐습니다."
				elif not game.call(&"start_run", String(tier_id)):
					failure = "start_run이 실패했습니다: %s" % game.get("status_label").text
				else:
					await process_frame
					var active: Dictionary = game.get("active_contract")
					if (
						not bool(game.get("run_started"))
						or game.get("start_hub") != null
						or game.get("player") == null
						or game.get("map_generator") == null
					):
						failure = "전투 조립 뒤 거점 또는 필수 런타임 상태가 잘못됐습니다."
					elif StringName(active.get(&"tier_id", &"")) != tier_id:
						failure = "선택 맵 등급이 active_contract에 유지되지 않았습니다."
					elif StringName(active.get(&"difficulty_id", &"")) != difficulty_id:
						failure = "선택 난이도가 active_contract에 유지되지 않았습니다."
					else:
						verified += 1
						game.call(&"_return_to_start_hub")
						await process_frame
						if game.get("start_hub") == null or bool(game.get("run_started")):
							failure = "작전 종료 뒤 거점 복귀 상태가 잘못됐습니다."
			root.remove_child(game)
			game.free()
			await process_frame
			_cleanup_paths(features)
			if not failure.is_empty():
				_fail("%s/%s 조합 실패: %s" % [tier_id, difficulty_id, failure])
				return
	print("OPERATION_COMBINATION_OK combinations_%d tiers_3 difficulties_3 launch_assemble_return" % verified)
	quit(0)


func _cleanup_paths(features: Resource) -> void:
	for property_name in [
		"persistent_profile_storage_path", "conditional_ranking_storage_path",
		"meta_progression_storage_path", "key_mapping_storage_path",
		"skill_binding_storage_path",
	]:
		var path := String(features.get(property_name))
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
