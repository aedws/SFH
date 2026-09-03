extends SceneTree
const PATH := "user://sfh_season_rewards_contract.json"
var now := 1001
var failures: Array[String] = []


func _init() -> void:
	call_deferred(&"_run")


func _ranking() -> ConditionalRankingSystem:
	var ranking := ConditionalRankingSystem.new()
	root.add_child(ranking)
	var config: Resource = load("res://game/features/conditional_ranking/configs/default_ranking_provider.tres").duplicate(true)
	config.provider_mode = "local"
	config.season_policy.starts_at = 1000
	config.season_policy.duration_seconds = 60
	_check(ranking.configure(PATH, ConditionalRankingPolicy.new(), true, config, null, func(): return now), "configure")
	return ranking


func _run() -> void:
	_clean()
	var ranking := _ranking()
	var contract := {&"condition_key": "ruined_city|standard|large", &"penalty_score": 10}
	var context: Dictionary = ranking.get_season_briefing(contract)[&"context"]
	var result := contract.merged({&"run_id": "reward-run", &"success": true, &"elapsed_seconds": 20.0, &"recovered_value": 250, &"kills": 80, &"boss_kills": 1, &"reward_multiplier": 1.0, &"season_context": context})
	_check(ranking.submit_run(result).get(&"season", {}).get(&"accepted", false), "season submission")
	_check(ranking.honor_profile.get_snapshot()["owned"].is_empty(), "no rewards before close")
	var frozen: Array = ranking.get_snapshot()[&"season"][&"active"][&"reward_catalog"].duplicate(true)
	var csv := FileAccess.get_file_as_string("res://game/features/conditional_ranking/data/season_reward.csv")
	_check(ranking.reward_catalog.load_csv_text(csv.replace("회수 전문가", "다음 시즌 이름"), "live fixture"), "live valid")
	_check(ranking.reward_catalog.load_csv_text(csv.replace("02e5e1", "001234"), "numeric hex") and ranking.reward_catalog.rows[0][&"color"] == "001234", "leading-zero hex color lost")
	_check(not ranking.reward_catalog.load_csv_text(csv.replace("recovered_value,3,title", "recovered_value,1.5,title"), "fractional rank"), "fractional max rank accepted")
	_check(ranking.get_snapshot()[&"season"][&"active"][&"reward_catalog"] == frozen, "frozen season changed")
	_check(not ranking.reward_catalog.load_csv_text(csv.replace("salvager_title,recovered_value,3,title", "salvager_title,recovered_value,0,weapon"), "invalid"), "invalid kind/rank accepted")
	ranking.free() # Close while offline; next initialization closes and grants once.
	now = 1061
	ranking = _ranking()
	var honors: Dictionary = ranking.get_snapshot()[&"honors"]
	_check(honors["owned"].size() == 6 and honors["receipts"].size() == 6, "six cosmetics after close")
	for _index in 4:
		ranking.get_season_briefing(contract)
	_check(ranking.honor_profile.get_snapshot()["receipts"].size() == 6, "duplicate grant")
	_check(ranking.honor_profile.equip("title", "salvager_title"), "equip title")
	_check(ranking.honor_profile.equip("aura", "salvager_aura"), "equip aura")
	_check(not ranking.honor_profile.equip("aura", "salvager_title") and not ranking.honor_profile.equip("title", "unknown"), "wrong kind or unowned equipped")
	var actor := Node2D.new()
	root.add_child(actor)
	ranking.attach_honor_presentation(actor, true)
	var presentation: Node = actor.get_node("SeasonHonorPresentation")
	_check(presentation.title_label.text == "회수 전문가" and presentation.aura_color.a > 0, "visual title/aura missing")
	ranking.show_honors(root)
	await process_frame
	_check(ranking.honor_panel.visible and ranking.honor_panel.selectors["title"].item_count == 4, "honor panel options")
	ranking.honor_panel.hide()
	ranking.honor_panel.free()
	actor.free()
	ranking.free()
	ranking = _ranking()
	_check(ranking.honor_profile.get_snapshot()["equipped"]["aura"] == "salvager_aura", "restart did not retain equipped aura")
	_check(ranking.honor_profile.equip("aura", ""), "unequip")
	var receipt_count: int = ranking.honor_profile.receipts.size()
	var snapshot: Dictionary = ranking.season_service.get_snapshot()
	var stranger := SeasonHonorProfile.new()
	root.add_child(stranger)
	stranger.configure("", "different-player", false)
	_check(ranking.reward_service.synchronize(snapshot, stranger, "different-player") == 0 and stranger.owned.is_empty(), "foreign identity received rewards")
	stranger.free()
	var ranked_profile := SeasonHonorProfile.new()
	root.add_child(ranked_profile)
	ranked_profile.configure("", ranking.identity.get_player_id(), false)
	var second_place: Dictionary = snapshot.duplicate(true)
	for conditions in second_place[&"archives"][0][&"ladder"][&"entries_by_condition"].values():
		for entries in conditions.values():
			if entries.is_empty(): continue
			var higher: Dictionary = entries[0].duplicate(true)
			higher[&"player_id"] = "higher-ranked-player"
			entries.push_front(higher)
	_check(ranking.reward_service.synchronize(second_place, ranked_profile, ranking.identity.get_player_id()) == 3 and ranked_profile.owned.size() == 3, "rank two must receive titles only")
	ranked_profile.free()
	var failing_profile := SeasonHonorProfile.new()
	root.add_child(failing_profile)
	failing_profile.configure(PATH + "/missing-parent/honors.json", "save-failure", true)
	_check(not failing_profile.grant("test-receipt", frozen[0], {}) and failing_profile.owned.is_empty() and failing_profile.receipts.is_empty(), "failed save did not roll back grant")
	failing_profile.free()
	snapshot[&"archives"][0][&"read_only"] = false
	_check(ranking.reward_service.synchronize(snapshot, ranking.honor_profile, ranking.identity.get_player_id()) == 0 and ranking.honor_profile.receipts.size() == receipt_count, "open archive granted")
	ranking.free()
	var honor_path := PATH.replace(".json", "_honors.json")
	var file := FileAccess.open(honor_path, FileAccess.WRITE)
	file.store_string("{broken-json")
	file.close()
	ranking = _ranking()
	_check(not ranking.honor_profile.get_snapshot()["storage_error"].is_empty(), "corrupt profile not blocked")
	_check(FileAccess.get_file_as_string(honor_path) == "{broken-json", "corrupt profile overwritten")
	_check(not ranking.get_season_briefing(contract).is_empty(), "cosmetic corruption blocked operation")
	ranking.free()
	_clean()
	if failures.is_empty():
		print("P6_REWARD_OK offline_close once_only identity_scoped frozen_catalog live_validation atomic_profile restart equip_unequip visual_aura title_panel corrupt_preserved cosmetic_only")
		quit(0)
	else:
		for failure in failures: push_error(failure)
		quit(1)


func _check(ok: bool, message: String) -> void:
	if not ok: failures.append(message)


func _clean() -> void:
	for suffix in ["", "_identity", "_submissions", "_seasons", "_honors"]:
		var path := PATH.replace(".json", suffix + ".json")
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
