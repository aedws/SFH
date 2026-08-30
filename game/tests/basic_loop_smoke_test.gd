extends SceneTree

const GAME_SCENE_PATH := "res://game/scenes/game.tscn"
const MAP_GENERATOR_SCENE_PATH := "res://game/features/map_generation/map_generator.tscn"
const MAP_CONFIG_PATH_PATTERN := "res://game/features/map_generation/configs/%s.tres"
const LOOT_CONFIG_PATH_PATTERN := "res://game/features/loot/configs/%s.tres"
const SPAWN_CONFIG_PATH_PATTERN := "res://game/features/spawning/configs/%s.tres"
const ROOM_ENCOUNTER_CONFIG_PATH := (
	"res://game/features/room_encounters/configs/default_room_encounters.tres"
)
const ENEMY_SPAWNER_SCENE_PATH := "res://game/features/spawning/enemy_spawner.tscn"
const EQUIPMENT_SCENE_PATH := "res://game/features/equipment/equipment_system.tscn"
const EQUIPMENT_LOADOUT_PATH := "res://game/features/equipment/loadouts/default_loadout.tres"
const INVENTORY_SCENE_PATH := "res://game/features/inventory/grid_inventory.tscn"
const INVENTORY_CATALOG_PATH := "res://game/features/inventory/catalogs/default_inventory.tres"
const WEAPON_BALANCE_SCENE_PATH := "res://game/features/weapon_balance/weapon_balance_service.tscn"
const WEAPON_BALANCE_CONFIG_PATH := "res://game/features/weapon_balance/configs/default_weapon_balance.tres"
const GROWTH_BALANCE_SCENE_PATH := "res://game/features/growth_balance/growth_balance_service.tscn"
const GROWTH_BALANCE_CONFIG_PATH := "res://game/features/growth_balance/configs/default_growth_balance.tres"
const PLAYER_SCENE_PATH := "res://game/features/player/player.tscn"
const WEAPON_SCENE_PATH := "res://game/features/weapons/auto_weapon.tscn"
const PROGRESSION_SCENE_PATH := "res://game/features/experience/progression_system.tscn"
const RUN_BUFF_SCENE_PATH := "res://game/features/run_buffs/run_buff_system.tscn"
const RUN_BUFF_CATALOG_PATH := "res://game/features/run_buffs/configs/default_run_buffs.tres"
const META_PROGRESSION_SCENE_PATH := "res://game/features/meta_progression/meta_progression_system.tscn"
const CREDIT_LEDGER_SCENE_PATH := "res://game/features/credits/credit_ledger.tscn"
const EQUIPMENT_UPGRADE_SCENE_PATH := "res://game/features/equipment_upgrade/equipment_upgrade_service.tscn"
const EQUIPMENT_UPGRADE_POLICY_PATH := "res://game/features/equipment_upgrade/configs/default_upgrade_costs.tres"
const HEALTH_RECOVERY_SCENE_PATH := "res://game/features/health_recovery/health_recovery_system.tscn"
const HEALTH_RECOVERY_CONFIG_PATH := "res://game/features/health_recovery/configs/default_health_recovery.tres"
const COMBAT_SKILL_SYSTEM_SCENE_PATH := "res://game/features/combat_skills/combat_skill_system.tscn"
const COMBAT_SKILL_HUD_SCENE_PATH := "res://game/features/combat_skills/combat_skill_hud.tscn"
const COMBAT_SKILL_LOADOUT_PATH := "res://game/features/combat_skills/configs/default_combat_skills.tres"
const ENEMY_SCENE_PATH := "res://game/features/enemies/enemy.tscn"
const PROFILE_SCENE_PATH := "res://game/features/persistent_profile/persistent_profile.tscn"
const HUB_ECONOMY_SCENE_PATH := "res://game/features/hub_economy/hub_economy_system.tscn"
const HUB_ECONOMY_CONFIG_PATH := "res://game/features/hub_economy/configs/default_hub_economy.tres"
const CONTRACT_SCENE_PATH := "res://game/features/operation_contract/operation_contract_service.tscn"
const CONTRACT_CONFIG_PATH := "res://game/features/operation_contract/configs/default_operation_contracts.tres"
const PENALTY_SCENE_PATH := "res://game/features/penalty_modifiers/penalty_system.tscn"
const PENALTY_CONFIG_PATH := "res://game/features/penalty_modifiers/configs/default_penalties.tres"
const CRAFTING_SCENE_PATH := "res://game/features/crafting/crafting_system.tscn"
const CRAFTING_CONFIG_PATH := "res://game/features/crafting/configs/default_crafting.tres"
const RANKING_SCENE_PATH := "res://game/features/conditional_ranking/conditional_ranking_system.tscn"
const RANKING_POLICY_PATH := "res://game/features/conditional_ranking/configs/default_conditional_ranking.tres"
const RESULT_SCENE_PATH := "res://game/features/operation_results/operation_result_service.tscn"
const RESULT_CONFIG_PATH := "res://game/features/operation_results/configs/default_operation_results.tres"
const SMART_TARGETING_PATH := "res://game/features/smart_targeting/configs/default_smart_targeting.tres"
const EXTRACTION_SCENE_PATH := "res://game/features/extraction/extraction_zone.tscn"
const EXTRACTION_DEFENSE_CONFIG_PATH := "res://game/features/extraction/configs/default_extraction_defense.tres"
const MAP_TIER_IDS := ["small", "medium", "large"]

var game_instance: Node
var frame_count: int = 0


func _init() -> void:
	_reset_persistent_test_data()
	if not _verify_map_tiers():
		return
	if not await _verify_player_sustain_and_movement():
		return
	if not await _verify_combat_skill_modules():
		return
	if not _verify_inventory_modules():
		return
	if not await _verify_weapon_balance_modules():
		return
	if not await _verify_growth_balance_modules():
		return
	if not await _verify_balance_mode_selector():
		return
	if not await _verify_equipment_modules():
		return
	if not await _verify_enemy_stats_modules():
		return
	if not await _verify_enemy_spawn_budget():
		return
	if not _verify_roguelike_progression_modules():
		return
	if not _verify_equipment_upgrade_economy():
		return
	if not await _verify_meta_operation_modules():
		return

	var game_scene := load(GAME_SCENE_PATH) as PackedScene
	if game_scene == null:
		_fail("Game Scene을 불러오지 못했습니다.")
		return
	if not await _verify_start_hub_flow(game_scene):
		return
	if not await _verify_optional_start_hub_module(game_scene):
		return
	if not await _verify_optional_combat_skill_module(game_scene):
		return
	if not await _verify_optional_room_encounter_module(game_scene):
		return
	if not await _verify_all_tier_entry(game_scene):
		return
	if not await _verify_optional_map_module(game_scene):
		return
	if not await _verify_optional_equipment_module(game_scene):
		return
	if not await _verify_optional_weapon_balance_module(game_scene):
		return
	if not await _verify_optional_growth_balance_module(game_scene):
		return
	if not await _verify_optional_progression_modules(game_scene):
		return
	if not await _verify_optional_meta_operation_modules(game_scene):
		return
	if not await _verify_extraction_flow(game_scene):
		return

	game_instance = game_scene.instantiate()
	root.add_child(game_instance)
	await process_frame
	var setup_overlay := game_instance.get_node("UI/RunSetupOverlay") as Control
	if (
		setup_overlay.visible
		or game_instance.get("start_hub") == null
		or game_instance.get("player") == null
	):
		_fail("첫 실행이 이동 가능한 시작 거점으로 진입하지 않았습니다.")
		return
	game_instance.call(&"start_run", "small")
	var room_encounters = game_instance.get("room_encounter_system")
	var map_generator = game_instance.get("map_generator")
	if room_encounters != null and map_generator != null:
		for room: Dictionary in map_generator.call(&"get_room_encounter_snapshot"):
			if not bool(room[&"is_start_room"]) and not bool(room[&"is_extraction_room"]):
				room_encounters.call(&"try_start_room", int(room[&"room_index"]))
				break
	frame_count = 0


func _reset_persistent_test_data() -> void:
	for path in ["user://sfh_profile.json", "user://sfh_rankings.json"]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _verify_meta_operation_modules() -> bool:
	var sandbox := Node2D.new()
	root.add_child(sandbox)
	var profile := (load(PROFILE_SCENE_PATH) as PackedScene).instantiate()
	sandbox.add_child(profile)
	profile.call(&"configure", "", false)
	var economy := (load(HUB_ECONOMY_SCENE_PATH) as PackedScene).instantiate()
	sandbox.add_child(economy)
	var contracts := (load(CONTRACT_SCENE_PATH) as PackedScene).instantiate()
	sandbox.add_child(contracts)
	var penalties := (load(PENALTY_SCENE_PATH) as PackedScene).instantiate()
	sandbox.add_child(penalties)
	var crafting := (load(CRAFTING_SCENE_PATH) as PackedScene).instantiate()
	sandbox.add_child(crafting)
	var ranking := (load(RANKING_SCENE_PATH) as PackedScene).instantiate()
	sandbox.add_child(ranking)
	var results := (load(RESULT_SCENE_PATH) as PackedScene).instantiate()
	sandbox.add_child(results)
	var failure_message := ""
	if not economy.call(&"configure", profile, load(HUB_ECONOMY_CONFIG_PATH)):
		failure_message = "상점·창고 시스템 구성이 실패했습니다."
	elif not contracts.call(&"configure", profile, load(CONTRACT_CONFIG_PATH)):
		failure_message = "작전 계약 시스템 구성이 실패했습니다."
	elif not penalties.call(&"configure", load(PENALTY_CONFIG_PATH)):
		failure_message = "페널티 시스템 구성이 실패했습니다."
	elif not crafting.call(&"configure", profile, load(CRAFTING_CONFIG_PATH), 4242):
		failure_message = "도면 제작 시스템 구성이 실패했습니다."
	elif not ranking.call(&"configure", "", load(RANKING_POLICY_PATH), false):
		failure_message = "조건부 랭킹 시스템 구성이 실패했습니다."
	elif not results.call(&"configure", profile, ranking, load(RESULT_CONFIG_PATH), 4242):
		failure_message = "작전 결과 정산 시스템 구성이 실패했습니다."
	elif not bool(economy.call(&"purchase", &"unlock_industrial").get(&"success", false)):
		failure_message = "상점 구매가 산업 지구 영구 해금을 적용하지 못했습니다."
	elif not contracts.call(&"select_region", &"industrial_district"):
		failure_message = "해금한 산업 지구를 작전 지역으로 선택하지 못했습니다."
	elif not contracts.call(&"select_difficulty", &"veteran"):
		failure_message = "베테랑 난이도를 선택하지 못했습니다."
	elif not penalties.call(&"toggle", &"reinforced_armor"):
		failure_message = "강화 장갑 페널티를 선택하지 못했습니다."
	else:
		var penalty_snapshot: Dictionary = penalties.call(&"get_snapshot")
		var small_config: Resource = load(MAP_CONFIG_PATH_PATTERN % "small")
		var quote: Dictionary = contracts.call(&"quote", small_config, penalty_snapshot)
		if int(quote.get(&"entry_cost", 0)) != 173:
			failure_message = "지역·난이도 투입 비용이 실제 데이터 배율과 일치하지 않습니다."
		elif not is_equal_approx(float(quote.get(&"reward_multiplier", 0.0)), 2.325):
			failure_message = "지역·난이도·페널티 회수 배율이 합성되지 않았습니다."
		elif float(quote.get(&"enemy_modifiers", {}).get(&"armor_multiplier", 0.0)) != 1.875:
			failure_message = "난이도와 페널티 적 장갑 배율이 합성되지 않았습니다."
		else:
			var before_invest := int(profile.call(&"get_snapshot")[&"banked_credits"])
			var invested: Dictionary = contracts.call(&"invest", small_config, penalty_snapshot)
			if not bool(invested.get(&"success", false)):
				failure_message = "작전 투입 비용을 차감하지 못했습니다."
			elif int(profile.call(&"get_snapshot")[&"banked_credits"]) != before_invest - 173:
				failure_message = "작전 투입 비용이 영구 크레딧에서 정확히 차감되지 않았습니다."
	if failure_message.is_empty():
		var test_loadout: Array[StringName] = [&"field_medkit"]
		if not economy.call(&"set_consumable_loadout", test_loadout):
			failure_message = "창고 응급키트를 소모품 로드아웃에 장착하지 못했습니다."
		else:
			var medkits_before := int(profile.call(&"get_snapshot")[&"warehouse"].get(&"field_medkit", 0))
			var consumed: Array = profile.call(&"consume_loadout_for_run")
			if &"field_medkit" not in consumed:
				failure_message = "출격 시 소모품 로드아웃을 소비하지 않았습니다."
			elif int(profile.call(&"get_snapshot")[&"warehouse"].get(&"field_medkit", 0)) != medkits_before - 1:
				failure_message = "소모품 소비량이 창고 수량에 반영되지 않았습니다."
	if failure_message.is_empty():
		var crafted: Dictionary = crafting.call(&"craft", &"assault_rifle_blueprint")
		var affixes: Array = crafted.get(&"item", {}).get(&"affixes", [])
		var affix_ids := {}
		for affix in affixes:
			affix_ids[affix.get(&"affix_id", &"")] = true
		if not bool(crafted.get(&"success", false)):
			failure_message = "도면·고철·크레딧을 사용하는 장비 제작이 실패했습니다."
		elif affixes.size() < 1 or affixes.size() > 2 or affix_ids.size() != affixes.size():
			failure_message = "제작 장비 랜덤 옵션 수량 또는 중복 방지 정책이 올바르지 않습니다."
	if failure_message.is_empty():
		var smart_policy: Resource = load(SMART_TARGETING_PATH)
		var near_target := (load(ENEMY_SCENE_PATH) as PackedScene).instantiate()
		near_target.position = Vector2(100.0, 0.0)
		near_target.set("priority_rank", 1)
		sandbox.add_child(near_target)
		var elite_target := (load(ENEMY_SCENE_PATH) as PackedScene).instantiate()
		elite_target.position = Vector2(200.0, 0.0)
		elite_target.set("priority_rank", 5)
		sandbox.add_child(elite_target)
		var selected = smart_policy.call(
			&"select_target", Vector2.ZERO, [near_target, elite_target], 800.0
		)
		if selected != elite_target:
			failure_message = "스마트 타게팅이 거리만 보지 않고 우선 등급을 합성하지 못했습니다."
	if failure_message.is_empty():
		var first_rank: Dictionary = ranking.call(&"submit_run", {
			&"success": true, &"condition_key": "city|standard|small|",
			&"recovered_value": 100, &"kills": 10, &"elapsed_seconds": 300.0,
		})
		var second_rank: Dictionary = ranking.call(&"submit_run", {
			&"success": true, &"condition_key": "city|standard|small|",
			&"recovered_value": 300, &"kills": 20, &"elapsed_seconds": 240.0,
		})
		ranking.call(&"submit_run", {
			&"success": true, &"condition_key": "lab|veteran|large|armor",
			&"recovered_value": 50, &"kills": 1, &"elapsed_seconds": 600.0,
		})
		if not bool(first_rank.get(&"accepted", false)) or int(second_rank.get(&"rank", 0)) != 1:
			failure_message = "조건부 랭킹이 동일 조건 점수를 내림차순 정렬하지 못했습니다."
		elif ranking.call(&"get_entries", "city|standard|small|").size() != 2:
			failure_message = "서로 다른 작전 조건의 랭킹이 섞였습니다."
	if failure_message.is_empty():
		var settlement: Dictionary = results.call(&"settle_success", {
			&"carried_credits": 100, &"kills": 24, &"elapsed_seconds": 500.0,
		}, {
			&"reward_multiplier": 2.0, &"blueprint_drop_multiplier": 0.0,
			&"ranking_condition_key": "test|standard|small|", &"region_id": &"ruined_city",
		})
		if int(settlement.get(&"recovered_credits", 0)) != 200 or int(settlement.get(&"salvage", 0)) != 2:
			failure_message = "성공 결과의 회수 배수·고철 정산이 영구 프로필에 반영되지 않았습니다."
	if failure_message.is_empty():
		var defense_config: Resource = load(EXTRACTION_DEFENSE_CONFIG_PATH)
		if not is_equal_approx(float(defense_config.call(&"duration_for", &"large", &"nightmare")), 35.0):
			failure_message = "탈출 방어 시간의 맵 규모·난이도 정책이 설정 데이터와 일치하지 않습니다."
	if failure_message.is_empty():
		var extraction := (load(EXTRACTION_SCENE_PATH) as PackedScene).instantiate()
		sandbox.add_child(extraction)
		var actor := Node2D.new()
		actor.add_to_group(&"player")
		sandbox.add_child(actor)
		extraction.call(&"configure", Vector2.ZERO, 5.0)
		if not extraction.call(&"request_extraction", actor):
			failure_message = "탈출 방어 카운트다운을 시작하지 못했습니다."
		else:
			extraction.call(&"advance", 4.0)
			if not bool(extraction.call(&"get_snapshot")[&"defense_active"]):
				failure_message = "카운트다운 종료 전에 탈출 방어가 완료됐습니다."
			extraction.call(&"advance", 1.1)
			if bool(extraction.call(&"get_snapshot")[&"defense_active"]):
				failure_message = "카운트다운 종료 후 탈출 방어가 완료되지 않았습니다."
	if failure_message.is_empty():
		var profile_test_path := "user://sfh_profile_roundtrip_test.json"
		var ranking_test_path := "user://sfh_ranking_roundtrip_test.json"
		for path in [profile_test_path, ranking_test_path]:
			if FileAccess.file_exists(path):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
		var stored_profile := (load(PROFILE_SCENE_PATH) as PackedScene).instantiate()
		sandbox.add_child(stored_profile)
		stored_profile.call(&"configure", profile_test_path, true)
		stored_profile.call(&"add_credits", 123)
		stored_profile.call(&"add_crafted_item", {
			&"instance_id": "roundtrip", &"definition_id": &"test", &"affixes": [],
		})
		var loaded_profile := (load(PROFILE_SCENE_PATH) as PackedScene).instantiate()
		sandbox.add_child(loaded_profile)
		loaded_profile.call(&"configure", profile_test_path, true)
		var loaded_snapshot: Dictionary = loaded_profile.call(&"get_snapshot")
		if (
			int(loaded_snapshot.get(&"banked_credits", 0)) != 5123
			or (loaded_snapshot.get(&"crafted_items", []) as Array).size() != 1
		):
			failure_message = "영구 프로필 JSON 저장·복원이 값을 보존하지 못했습니다."
		var stored_ranking := (load(RANKING_SCENE_PATH) as PackedScene).instantiate()
		sandbox.add_child(stored_ranking)
		stored_ranking.call(&"configure", ranking_test_path, load(RANKING_POLICY_PATH), true)
		stored_ranking.call(&"submit_run", {
			&"success": true, &"condition_key": "roundtrip", &"recovered_value": 100,
		})
		var loaded_ranking := (load(RANKING_SCENE_PATH) as PackedScene).instantiate()
		sandbox.add_child(loaded_ranking)
		loaded_ranking.call(&"configure", ranking_test_path, load(RANKING_POLICY_PATH), true)
		if loaded_ranking.call(&"get_entries", "roundtrip").size() != 1:
			failure_message = "조건부 랭킹 JSON 저장·복원이 기록을 보존하지 못했습니다."
		for path in [profile_test_path, ranking_test_path]:
			if FileAccess.file_exists(path):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	root.remove_child(sandbox)
	sandbox.free()
	await process_frame
	if not failure_message.is_empty():
		_fail("작전·메타 시스템 실패: %s" % failure_message)
		return false
	return true


func _verify_start_hub_flow(game_scene: PackedScene) -> bool:
	var hub_game := game_scene.instantiate()
	root.add_child(hub_game)
	await process_frame
	var hub = hub_game.get("start_hub")
	var hub_player = hub_game.get("player")
	var hub_inventory = hub_game.get("inventory_window")
	var hub_workbench = hub_game.get("equipment_workbench")
	var hub_equipment = hub_game.get("equipment_system")
	var setup_overlay := hub_game.get_node("UI/RunSetupOverlay") as Control
	var hub_hud := hub_game.get_node("UI/StartHubHUD") as Control
	var setup_panel := hub_game.get_node("UI/RunSetupOverlay/Center/Panel") as Control
	var setup_close := hub_game.get_node("UI/RunSetupOverlay/SetupCloseButton") as Button
	var small_card := hub_game.get_node(
		"UI/RunSetupOverlay/Center/Panel/Margin/Content/TierButtons/SmallMapButton"
	) as Button
	var failure_message := ""
	if hub == null or hub_player == null:
		failure_message = "시작 거점 또는 거점 플레이어가 설치되지 않았습니다."
	elif (
		hub_inventory == null
		or hub_workbench == null
		or hub_equipment == null
		or not bool(hub_workbench.get("read_only"))
	):
		failure_message = "거점 조회용 가방 또는 장비 화면이 설치되지 않았습니다."
	elif (
		not _has_key_binding(&"toggle_inventory", KEY_I)
		or not _has_key_binding(&"toggle_equipment", KEY_U)
		or not _has_key_binding(&"toggle_equipment", KEY_E)
		or not _has_key_binding(&"switch_weapon", KEY_Q)
	):
		failure_message = "거점 I·U/E·Q 단축키가 모두 등록되지 않았습니다."
	else:
		var snapshot: Dictionary = hub.call(&"get_snapshot")
		if int(snapshot.get(&"room_count", 0)) != 1:
			failure_message = "시작 거점이 하나의 큰 방으로 구성되지 않았습니다."
		elif (
			float((snapshot.get(&"room_size", Vector2.ZERO) as Vector2).x) < 1280.0
			or float((snapshot.get(&"room_size", Vector2.ZERO) as Vector2).y) < 720.0
		):
			failure_message = "시작 거점 방이 기본 화면보다 작습니다."
		elif setup_overlay.visible or not hub_hud.visible:
			failure_message = "시작 시 작전 UI가 닫히거나 거점 안내 HUD가 표시되지 않았습니다."
		elif (
			setup_panel.custom_minimum_size.x < 1000.0
			or setup_panel.custom_minimum_size.y < 580.0
			or small_card.custom_minimum_size.x < 280.0
			or not setup_close.visible
		):
			failure_message = "최적화된 세션 구성 패널·전장 카드·ESC 동선이 적용되지 않았습니다."
		else:
			var inventory_event := InputEventAction.new()
			inventory_event.action = &"toggle_inventory"
			inventory_event.pressed = true
			hub_inventory.call(&"_unhandled_input", inventory_event)
			if not hub_inventory.visible or not paused:
				failure_message = "거점 I 입력이 가방 조회 화면을 열지 못했습니다."
			else:
				hub_inventory.call(&"close_panel")
			var equipment_event := InputEventAction.new()
			equipment_event.action = &"toggle_equipment"
			equipment_event.pressed = true
			if failure_message.is_empty():
				hub_workbench.call(&"_unhandled_input", equipment_event)
				var state = hub_equipment.call(&"get_equipment_state", &"main")
				var level_before := int(state.get("level"))
				hub_workbench.call(&"_level_up_selected")
				if not hub_workbench.visible or not paused:
					failure_message = "거점 U/E 입력이 장비 조회 화면을 열지 못했습니다."
				elif int(state.get("level")) != level_before:
					failure_message = "거점 조회 전용 장비 화면에서 장비가 변경됐습니다."
				hub_workbench.call(&"close_panel")
			var switch_event := InputEventAction.new()
			switch_event.action = &"switch_weapon"
			switch_event.pressed = true
			if failure_message.is_empty():
				hub_game.call(&"_unhandled_input", switch_event)
				if hub_equipment.call(&"get_active_weapon_slot") != &"secondary":
					failure_message = "거점 Q 입력이 확인 무기를 전환하지 못했습니다."
		if failure_message.is_empty():
			hub_player.global_position = hub.call(&"get_operation_position")
			if not hub.call(&"request_operation", hub_player):
				failure_message = "작전 게이트의 F 상호작용 요청이 실패했습니다."
			elif not setup_overlay.visible or not paused:
				failure_message = "작전 게이트가 세션 구성 UI를 열지 못했습니다."
			else:
				setup_close.pressed.emit()
				if setup_overlay.visible or paused:
					failure_message = "ESC 복귀가 작전 UI를 닫지 못했습니다."
				elif not hub_game.call(&"start_run", "small"):
					failure_message = "시작 거점에서 전투 세션으로 전환하지 못했습니다."
				elif hub_game.get("start_hub") != null or hub_game.get("map_generator") == null:
					failure_message = "전투 세션 전환 후 거점과 작전 맵 상태가 분리되지 않았습니다."
				elif hub_game.get("equipment_system").call(&"get_active_weapon_slot") != &"secondary":
					failure_message = "거점 Q 선택 무기가 전투 세션에 유지되지 않았습니다."
				else:
					hub_game.call(&"_finish_run", "테스트 종료", "거점 복귀 검증")
					if "시작 거점" not in String(
						hub_game.get_node("UI/GameOverOverlay/Center/Panel/Margin/Content/RestartButton").text
					):
						failure_message = "작전 결과 UI에 시작 거점 복귀 동작이 없습니다."
					else:
						hub_game.call(&"_restart_run")
						await process_frame
						if (
							hub_game.get("start_hub") == null
							or hub_game.get("player") == null
							or hub_game.get("inventory_window") == null
							or hub_game.get("equipment_workbench") == null
							or bool(hub_game.get("run_started"))
						):
							failure_message = "전투 종료 후 시작 거점으로 복귀하지 못했습니다."
	paused = false
	root.remove_child(hub_game)
	hub_game.free()
	await process_frame
	if not failure_message.is_empty():
		_fail("시작 거점 흐름 실패: %s" % failure_message)
		return false
	return true


func _verify_combat_skill_modules() -> bool:
	if (
		not _has_key_binding(&"combat_skill_1", KEY_1)
		or not _has_key_binding(&"combat_skill_2", KEY_2)
		or not _has_key_binding(&"combat_skill_3", KEY_3)
	):
		_fail("1/2/3 전투 스킬 입력이 프로젝트에 등록되지 않았습니다.")
		return false
	var sandbox := Node2D.new()
	root.add_child(sandbox)
	var actors := Node2D.new()
	var enemies := Node2D.new()
	var effects := Node2D.new()
	sandbox.add_child(actors)
	sandbox.add_child(enemies)
	sandbox.add_child(effects)
	var player := (load(PLAYER_SCENE_PATH) as PackedScene).instantiate()
	actors.add_child(player)
	var enemy := (load(ENEMY_SCENE_PATH) as PackedScene).instantiate()
	enemy.set("max_health", 100.0)
	enemy.set("max_armor", 2.0)
	enemy.global_position = Vector2(100.0, 0.0)
	enemies.add_child(enemy)
	var system := (load(COMBAT_SKILL_SYSTEM_SCENE_PATH) as PackedScene).instantiate()
	sandbox.add_child(system)
	var loadout: Resource = load(COMBAT_SKILL_LOADOUT_PATH)
	var failure_message := ""
	var expected_patterns := ["trail", "ring", "burst"]
	var loadout_skills: Array = loadout.get("skills")
	for skill_index in loadout_skills.size():
		var effect: Resource = loadout_skills[skill_index].get("effect")
		var electric_profile: Resource = effect.get("electric_profile")
		if (
			electric_profile == null
			or not bool(electric_profile.call(&"is_valid"))
			or String(electric_profile.get("pattern")) != expected_patterns[skill_index]
			or int(electric_profile.call(&"estimated_line_segments")) > 128
			or float(electric_profile.get("geometry_refresh_hz")) > 20.0
		):
			failure_message = "전기 이펙트 프로필 또는 선분·갱신 예산이 유효하지 않습니다."
			break
	if failure_message.is_empty() and not system.call(
		&"configure", player, enemies, effects, loadout, true
	):
		failure_message = "전투 스킬 실행기 구성이 실패했습니다."
	elif failure_message.is_empty():
		var initial: Dictionary = system.call(&"get_snapshot")
		var states: Array = initial.get(&"states", [])
		if (
			int(initial.get(&"skill_count", 0)) != 3
			or String(states[0].get(&"display_name", "")) != "점멸"
			or String(states[1].get(&"display_name", "")) != "원형 자기장"
			or String(states[2].get(&"display_name", "")) != "기동 가속"
		):
			failure_message = "기본 전투 스킬 세 종류가 순서대로 로드되지 않았습니다."
		else:
			var start_position: Vector2 = player.global_position
			if not system.call(&"try_activate", 0):
				failure_message = "1번 점멸 스킬이 발동하지 않았습니다."
			elif player.global_position.distance_to(start_position) < 300.0:
				failure_message = "점멸이 충분한 전방 이동 거리를 제공하지 않습니다."
			elif system.call(&"try_activate", 0):
				failure_message = "점멸 쿨타임 중 재발동이 허용됐습니다."
			else:
				system.call(&"advance", 5.1)
				if not bool(system.call(&"get_skill_states")[0].get(&"ready", false)):
					failure_message = "점멸 쿨타임 종료가 HUD 상태에 반영되지 않았습니다."
		if failure_message.is_empty():
			enemy.global_position = player.global_position + Vector2(100.0, 0.0)
			var health_before := float(enemy.get("current_health"))
			if not system.call(&"try_activate", 1):
				failure_message = "2번 원형 자기장 스킬이 발동하지 않았습니다."
			elif float(enemy.get("current_health")) >= health_before:
				failure_message = "원형 자기장이 범위 내 적에게 피해를 주지 않았습니다."
			else:
				var health_after_first_tick := float(enemy.get("current_health"))
				var runtime_fields := get_nodes_in_group(&"combat_skill_runtime_effect")
				if runtime_fields.size() != 1:
					failure_message = "원형 자기장이 독립 지속 효과를 하나만 생성하지 않았습니다."
				else:
					runtime_fields[0].call(&"advance", 1.0)
					if float(enemy.get("current_health")) >= health_after_first_tick:
						failure_message = "원형 자기장이 고정 주기로 누적 피해를 주지 않았습니다."
		if failure_message.is_empty():
			var speed_before := float(player.call(&"get_runtime_stats").get(&"movement_speed", 0.0))
			if not system.call(&"try_activate", 2):
				failure_message = "3번 이동속도 증가 스킬이 발동하지 않았습니다."
			else:
				var speed_after := float(player.call(&"get_runtime_stats").get(&"movement_speed", 0.0))
				if speed_after < speed_before * 1.54:
					failure_message = "이동속도 증가 스킬의 55% 배율이 적용되지 않았습니다."
		if failure_message.is_empty():
			var hud := (load(COMBAT_SKILL_HUD_SCENE_PATH) as PackedScene).instantiate()
			sandbox.add_child(hud)
			if not hud.call(&"configure", system):
				failure_message = "전투 스킬 HUD가 실행기와 연결되지 않았습니다."
			else:
				var hud_snapshot: Dictionary = hud.call(&"get_snapshot")
				if (
					int(hud_snapshot.get(&"slot_count", 0)) != 3
					or hud.get_node("Panel/Margin/SkillSlots").get_child_count() != 3
				):
					failure_message = "스킬 HUD에 세 개 슬롯과 쿨타임 상태가 표시되지 않았습니다."
		if failure_message.is_empty():
			var electric_effects := get_nodes_in_group(&"combat_skill_electric_effect")
			if electric_effects.size() != 3:
				failure_message = "세 스킬이 각각 전기 이펙트 인스턴스를 생성하지 않았습니다."
			else:
				for electric in electric_effects:
					var electric_snapshot: Dictionary = electric.call(&"get_snapshot")
					if (
						int(electric_snapshot.get(&"line_segments", 999)) > 128
						or float(electric_snapshot.get(&"geometry_refresh_hz", 999.0)) > 20.0
						or int(electric_snapshot.get(&"cached_arc_count", 0)) <= 0
					):
						failure_message = "전기 이펙트가 런타임 연산 예산을 벗어났습니다."
						break
		if failure_message.is_empty():
			var emissions_before := int(system.call(&"get_snapshot").get(&"state_emission_count", 0))
			for _step in 6:
				system.call(&"_process", 1.0 / 60.0)
			var optimized_snapshot: Dictionary = system.call(&"get_snapshot")
			var emitted_updates := int(optimized_snapshot.get(&"state_emission_count", 0)) - emissions_before
			if (
				float(optimized_snapshot.get(&"hud_refresh_hz", 999.0)) > 10.01
				or emitted_updates > 2
			):
				failure_message = "쿨타임 HUD가 10Hz 예산보다 자주 상태를 갱신합니다."
	root.remove_child(sandbox)
	sandbox.free()
	await process_frame
	if not failure_message.is_empty():
		_fail("전투 스킬 모듈 실패: %s" % failure_message)
		return false
	return true


func _verify_optional_combat_skill_module(game_scene: PackedScene) -> bool:
	var skill_free_game := game_scene.instantiate()
	var skill_free_features = skill_free_game.get("features").duplicate(true)
	skill_free_features.set("combat_skills_enabled", false)
	skill_free_game.set("features", skill_free_features)
	root.add_child(skill_free_game)
	await process_frame
	var failure_message := ""
	if not skill_free_game.call(&"start_run", "small"):
		failure_message = "전투 스킬 비활성 구성에서 작전을 시작하지 못했습니다."
	elif (
		skill_free_game.get("combat_skill_system") != null
		or skill_free_game.get("combat_skill_hud") != null
		or skill_free_game.get_node_or_null("UI/CombatSkillHud") != null
	):
		failure_message = "비활성화했지만 전투 스킬 실행기 또는 HUD가 설치됐습니다."
	paused = false
	root.remove_child(skill_free_game)
	skill_free_game.free()
	await process_frame
	if not failure_message.is_empty():
		_fail("전투 스킬 선택 모듈 실패: %s" % failure_message)
		return false
	return true


func _verify_optional_room_encounter_module(game_scene: PackedScene) -> bool:
	var encounter_free_game := game_scene.instantiate()
	var encounter_free_features = encounter_free_game.get("features").duplicate(true)
	encounter_free_features.set("room_encounters_enabled", false)
	encounter_free_features.set("run_setup_enabled", false)
	encounter_free_features.set("start_hub_enabled", false)
	encounter_free_game.set("features", encounter_free_features)
	root.add_child(encounter_free_game)
	await process_frame
	var spawner = encounter_free_game.get("enemy_spawner")
	var failure_message := ""
	if not bool(encounter_free_game.get("run_started")):
		failure_message = "방 전투 비활성 구성에서 작전을 시작하지 못했습니다."
	elif encounter_free_game.get("room_encounter_system") != null:
		failure_message = "비활성화했지만 방 전투 실행기가 설치됐습니다."
	elif spawner == null or bool(spawner.call(&"get_snapshot").get(&"reinforcement_paused", true)):
		failure_message = "방 전투 제거 후 기존 전역 증원 폴백이 복구되지 않았습니다."
	root.remove_child(encounter_free_game)
	encounter_free_game.free()
	await process_frame
	if not failure_message.is_empty():
		_fail("방 전투 선택 모듈 실패: %s" % failure_message)
		return false
	return true


func _verify_optional_start_hub_module(game_scene: PackedScene) -> bool:
	var hub_free_game := game_scene.instantiate()
	var hub_free_features = hub_free_game.get("features").duplicate(true)
	hub_free_features.set("start_hub_enabled", false)
	hub_free_game.set("features", hub_free_features)
	root.add_child(hub_free_game)
	await process_frame
	var setup_overlay := hub_free_game.get_node("UI/RunSetupOverlay") as Control
	var failure_message := ""
	if hub_free_game.get("start_hub") != null or hub_free_game.get("player") != null:
		failure_message = "비활성화했지만 시작 거점 또는 거점 플레이어가 설치됐습니다."
	elif not setup_overlay.visible:
		failure_message = "시작 거점 비활성화 시 기존 작전 선택 UI로 폴백하지 않았습니다."
	elif not hub_free_game.call(&"start_run", "small"):
		failure_message = "시작 거점 없이 기존 직접 작전 진입이 실패했습니다."
	elif hub_free_game.get("map_generator") == null:
		failure_message = "시작 거점 폴백에서 작전 맵이 설치되지 않았습니다."
	root.remove_child(hub_free_game)
	hub_free_game.free()
	await process_frame
	if not failure_message.is_empty():
		_fail("시작 거점 모듈 비활성화 실패: %s" % failure_message)
		return false
	return true


func _verify_map_tiers() -> bool:
	var generator_scene := load(MAP_GENERATOR_SCENE_PATH) as PackedScene
	if generator_scene == null:
		_fail("Map Generator Scene을 불러오지 못했습니다.")
		return false

	var previous_minimum_enemies := 0
	var previous_maximum_enemies := 0
	var previous_spawn_budget := 0
	for tier_id in MAP_TIER_IDS:
		var config = load(MAP_CONFIG_PATH_PATTERN % tier_id)
		var generator := generator_scene.instantiate()
		root.add_child(generator)
		generator.call(&"generate", config, 104729)

		var room_count: int = generator.get("rooms").size()
		var minimum_rooms: int = config.get("minimum_rooms")
		var maximum_rooms: int = config.get("maximum_rooms")
		if room_count < minimum_rooms or room_count > maximum_rooms:
			_fail("%s 맵의 방 수가 범위를 벗어났습니다." % tier_id)
			return false
		var minimum_room_counts := {"small": 18, "medium": 30, "large": 45}
		var target_durations := {"small": 540, "medium": 600, "large": 660}
		if minimum_rooms < int(minimum_room_counts[tier_id]):
			_fail("%s 맵 크기가 상향 기준에 미달합니다." % tier_id)
			return false
		var minimum_room_size: Vector2i = config.get("minimum_room_size")
		if minimum_room_size.x < 40 or minimum_room_size.y < 23:
			_fail("%s 방 한 칸이 1280×720 화면 기준보다 작습니다." % tier_id)
			return false
		if int(config.get("target_run_duration_seconds")) != int(target_durations[tier_id]):
			_fail("%s 작전 목표 시간이 9~11분 페이싱과 다릅니다." % tier_id)
			return false
		if (
			int(config.get("extraction_unlock_seconds"))
			!= int(config.get("target_run_duration_seconds"))
		):
			_fail("%s 작전 탈출 개방 시간이 목표 시간과 다릅니다." % tier_id)
			return false

		var path: PackedVector2Array = generator.call(
			&"get_world_path",
			generator.call(&"get_player_spawn_position"),
			generator.call(&"get_extraction_position")
		)
		if path.is_empty():
			_fail("%s 맵의 시작점과 탈출 지점이 연결되지 않았습니다." % tier_id)
			return false
		var room_visibility_rects: Array = generator.call(&"get_visibility_room_rects")
		var start_visibility: Dictionary = generator.call(
			&"get_visibility_region", generator.call(&"get_player_spawn_position")
		)
		var corridor_position := _find_corridor_position(generator)
		var corridor_visibility: Dictionary = generator.call(
			&"get_visibility_region", corridor_position
		)
		if (
			room_visibility_rects.size() != room_count
			or start_visibility.get(&"mode") != &"room"
			or not (start_visibility.get(&"world_rect", Rect2()) as Rect2).has_point(
				generator.call(&"get_player_spawn_position")
			)
			or corridor_position == Vector2.INF
			or corridor_visibility.get(&"mode") != &"corridor"
		):
			_fail("%s 맵의 방·통로 시야 영역 계약이 올바르지 않습니다." % tier_id)
			return false
		if generator.get("obstacle_cells").is_empty():
			_fail("%s 맵에 방해물이 생성되지 않았습니다." % tier_id)
			return false
		var obstacle_kinds: Array = generator.get("obstacle_cells").values()
		if (
			&"wall" not in obstacle_kinds
			or &"pillar" not in obstacle_kinds
			or &"utility" not in obstacle_kinds
		):
			_fail("%s 맵에 칸막이·설비 블록·기둥 패턴이 모두 생성되지 않았습니다." % tier_id)
			return false
		var loot_config = load(LOOT_CONFIG_PATH_PATTERN % tier_id)
		var spawn_config = load(SPAWN_CONFIG_PATH_PATTERN % tier_id)
		if (
			spawn_config == null
			or not spawn_config.call(&"is_valid")
			or int(spawn_config.get("minimum_active_enemies")) <= previous_minimum_enemies
			or int(spawn_config.get("maximum_active_enemies")) <= previous_maximum_enemies
			or int(spawn_config.get("maximum_total_spawns")) <= previous_spawn_budget
			or int(spawn_config.get("maximum_total_spawns"))
			< int(spawn_config.get("maximum_active_enemies"))
		):
			_fail("%s 맵의 핵앤슬래시 적 수량 정책이 맵 크기에 비례하지 않습니다." % tier_id)
			return false
		previous_minimum_enemies = int(spawn_config.get("minimum_active_enemies"))
		previous_maximum_enemies = int(spawn_config.get("maximum_active_enemies"))
		previous_spawn_budget = int(spawn_config.get("maximum_total_spawns"))
		if not is_equal_approx(
			float(loot_config.get("minimum_deployment_value_multiplier")),
			2.5
		) or not is_equal_approx(
			float(loot_config.get("maximum_deployment_value_multiplier")),
			5.0
		):
			_fail("%s 작전의 자원 회수 범위가 투입 코스트 2.5~5배가 아닙니다." % tier_id)
			return false
		var maximum_placement_value := floori(
			float(config.get("entry_cost"))
			* float(loot_config.get("maximum_deployment_value_multiplier"))
		)
		if (
			int(loot_config.get("maximum_cache_count"))
			* int(loot_config.get("maximum_cache_credits"))
			< maximum_placement_value
		):
			_fail("%s 작전의 파밍 설정으로 최대 회수 배수를 구성할 수 없습니다." % tier_id)
			return false
		var loot_points: Array = generator.call(
			&"get_loot_spawn_points",
			int(loot_config.get("minimum_cache_count"))
		)
		if loot_points.size() < int(loot_config.get("minimum_cache_count")):
			_fail("%s 맵에 필요한 파밍 위치를 확보하지 못했습니다." % tier_id)
			return false
		var placement_kinds: Array[StringName] = []
		for point in loot_points:
			placement_kinds.append(point[&"placement_kind"])
		if (
			&"wall_safe" not in placement_kinds
			or &"material_locker" not in placement_kinds
			or &"recovery_terminal" not in placement_kinds
		):
			_fail("%s 맵의 금고·자재함·회수 단말기 배치 유형이 부족합니다." % tier_id)
			return false
		if not is_equal_approx(float(generator.get("cell_size")), 32.0):
			_fail("맵 타일 크기가 32px로 조정되지 않았습니다.")
			return false

		root.remove_child(generator)
		generator.free()

	return true


func _find_corridor_position(generator: Node) -> Vector2:
	var cell_size := float(generator.get("cell_size"))
	for cell in generator.get("floor_cells"):
		var world_position := (Vector2(cell) + Vector2.ONE * 0.5) * cell_size
		var context: Dictionary = generator.call(&"get_visibility_region", world_position)
		if context.get(&"mode", &"room") == &"corridor":
			return world_position
	return Vector2.INF


func _verify_player_sustain_and_movement() -> bool:
	var player_scene := load(PLAYER_SCENE_PATH) as PackedScene
	var recovery_scene := load(HEALTH_RECOVERY_SCENE_PATH) as PackedScene
	var recovery_config := load(HEALTH_RECOVERY_CONFIG_PATH)
	if player_scene == null or recovery_scene == null or recovery_config == null:
		_fail("플레이어 이동 또는 부분 체력 회복 모듈을 불러오지 못했습니다.")
		return false
	var host := Node2D.new()
	root.add_child(host)
	var player := player_scene.instantiate()
	host.add_child(player)
	await process_frame
	var movement = player.get_node("Movement")
	var movement_snapshot: Dictionary = movement.call(&"get_movement_snapshot")
	var base_speed := float(movement_snapshot[&"speed"])
	var accelerated: Vector2 = movement.call(
		&"step_velocity", Vector2.ZERO, Vector2.RIGHT, 0.05, false
	)
	var braked: Vector2 = movement.call(
		&"step_velocity", Vector2.RIGHT * base_speed, Vector2.ZERO, 0.05, false
	)
	var counter_steered: Vector2 = movement.call(
		&"step_velocity", Vector2.RIGHT * base_speed, Vector2.LEFT, 0.05, false
	)
	var cornered: Vector2 = movement.call(
		&"step_velocity", Vector2.RIGHT * base_speed, Vector2.DOWN, 0.05, false
	)
	var dashed: Vector2 = movement.call(
		&"step_velocity", Vector2.ZERO, Vector2.RIGHT, 0.016, true
	)
	var dash_exit: Vector2 = movement.call(
		&"step_velocity",
		dashed,
		Vector2.RIGHT,
		float(movement_snapshot[&"dash_duration"]) + 0.01,
		false
	)
	if (
		accelerated.x <= 0.0
		or accelerated.x < float(movement_snapshot[&"launch_speed"])
		or accelerated.x >= base_speed
		or braked.length() >= base_speed
		or counter_steered.x >= 0.0
		or cornered.y <= 0.0
		or dashed.length() <= base_speed * 2.0
		or dash_exit.length() <= base_speed
		or dash_exit.length() >= dashed.length()
		or not bool(movement.call(&"get_movement_snapshot")[&"dash_exit_active"])
	):
		_fail("초동 가속·제동·급선회·회피 후 관성 응답이 예상 범위를 벗어났습니다.")
		return false

	var recovery := recovery_scene.instantiate()
	host.add_child(recovery)
	recovery.set_process(false)
	if not recovery.call(&"configure", player, recovery_config):
		_fail("부분 체력 회복 모듈 구성에 실패했습니다.")
		return false
	player.call(&"take_damage", 50.0)
	var damaged_health := float(player.call(&"get_health_snapshot")[&"current"])
	if recovery.call(&"advance", 3.0) > 0.0:
		_fail("피격 회복 대기 시간 전에 체력이 회복됐습니다.")
		return false
	recovery.call(&"advance", 2.0)
	recovery.call(&"advance", 20.0)
	var recovered_health := float(player.call(&"get_health_snapshot")[&"current"])
	if recovered_health <= damaged_health or recovered_health > 65.01:
		_fail("부분 회복이 적용되지 않았거나 최대 체력 65% 제한을 넘었습니다.")
		return false

	root.remove_child(host)
	host.free()
	return true


func _verify_roguelike_progression_modules() -> bool:
	var player_scene := load(PLAYER_SCENE_PATH) as PackedScene
	var equipment_scene := load(EQUIPMENT_SCENE_PATH) as PackedScene
	var weapon_scene := load(WEAPON_SCENE_PATH) as PackedScene
	var buff_scene := load(RUN_BUFF_SCENE_PATH) as PackedScene
	var meta_scene := load(META_PROGRESSION_SCENE_PATH) as PackedScene
	var progression_scene := load(PROGRESSION_SCENE_PATH) as PackedScene
	if (
		player_scene == null
		or equipment_scene == null
		or weapon_scene == null
		or buff_scene == null
		or meta_scene == null
		or progression_scene == null
	):
		_fail("로그라이크 성장 모듈 Scene을 불러오지 못했습니다.")
		return false

	var host := Node2D.new()
	root.add_child(host)
	var player := player_scene.instantiate()
	host.add_child(player)
	var equipment := equipment_scene.instantiate()
	host.add_child(equipment)
	if not equipment.call(
		&"configure", load(EQUIPMENT_LOADOUT_PATH), player, true, true, true
	):
		_fail("성장 테스트용 장비 구성이 실패했습니다.")
		return false
	var projectiles := Node2D.new()
	host.add_child(projectiles)
	var weapon := weapon_scene.instantiate()
	player.add_child(weapon)
	weapon.call(&"configure", projectiles, equipment, null)
	var buff_system := buff_scene.instantiate()
	host.add_child(buff_system)
	if not buff_system.call(
		&"configure", player, weapon, load(RUN_BUFF_CATALOG_PATH)
	):
		_fail("런 버프 시스템 구성이 실패했습니다.")
		return false
	var previous_max_health := float(player.get("max_health"))
	var choices: Array[Dictionary] = buff_system.call(&"prepare_choices", 1, 5)
	var vitality_id: StringName = &""
	for choice in choices:
		if choice[&"buff_id"] == &"vitality":
			vitality_id = choice[&"buff_id"]
	if vitality_id == &"" or not buff_system.call(&"select_buff", vitality_id):
		_fail("런 레벨업 선택지에서 임시 체력 버프를 적용하지 못했습니다.")
		return false
	if not is_equal_approx(float(player.get("max_health")), previous_max_health + 15.0):
		_fail("임시 버프가 장비 스탯과 독립적으로 합산되지 않았습니다.")
		return false
	var run_snapshot: Dictionary = buff_system.call(&"get_snapshot")
	if (
		int(run_snapshot[&"selected_buff_count"]) != 1
		or int(run_snapshot[&"meta_experience"][&"character"]) != 1
	):
		_fail("임시 버프 수량이 외부 경험치 분류로 변환되지 않았습니다.")
		return false

	var meta := meta_scene.instantiate()
	host.add_child(meta)
	meta.call(&"configure", "", false)
	var settlement: Dictionary = meta.call(&"settle_run", {
		&"character": 3,
		&"weapon": 1,
		&"armor": 1,
	})
	var meta_snapshot: Dictionary = settlement[&"snapshot"]
	if (
		int(meta_snapshot[&"levels"][&"character"]) != 2
		or int(meta_snapshot[&"experience"][&"weapon"]) != 1
		or int(meta_snapshot[&"experience"][&"armor"]) != 1
	):
		_fail("외부 경험치가 캐릭터·무기·방어구 트랙에 분리되지 않았습니다.")
		return false
	meta.call(&"apply_to_targets", player, weapon, equipment)
	if float(player.get("max_health")) < previous_max_health + 20.0:
		_fail("외부 캐릭터 레벨 보너스가 임시 버프와 함께 적용되지 않았습니다.")
		return false

	var progression := progression_scene.instantiate()
	host.add_child(progression)
	progression.call(&"configure", projectiles, true)
	progression.call(&"gain_experience", 5)
	if int(progression.call(&"get_run_snapshot")[&"level"]) != 2:
		_fail("내부 경험치가 런 레벨 선택권을 생성하지 못했습니다.")
		return false

	root.remove_child(host)
	host.free()
	return true


func _verify_equipment_upgrade_economy() -> bool:
	var player_scene := load(PLAYER_SCENE_PATH) as PackedScene
	var equipment_scene := load(EQUIPMENT_SCENE_PATH) as PackedScene
	var inventory_scene := load(INVENTORY_SCENE_PATH) as PackedScene
	var wallet_scene := load(CREDIT_LEDGER_SCENE_PATH) as PackedScene
	var service_scene := load(EQUIPMENT_UPGRADE_SCENE_PATH) as PackedScene
	if (
		player_scene == null
		or equipment_scene == null
		or inventory_scene == null
		or wallet_scene == null
		or service_scene == null
	):
		_fail("장비 강화 경제 모듈 Scene을 불러오지 못했습니다.")
		return false

	var host := Node.new()
	root.add_child(host)
	var player := player_scene.instantiate()
	host.add_child(player)
	var equipment := equipment_scene.instantiate()
	host.add_child(equipment)
	equipment.call(&"configure", load(EQUIPMENT_LOADOUT_PATH), player, true, true, true)
	var inventory := inventory_scene.instantiate()
	host.add_child(inventory)
	inventory.call(&"configure", load(INVENTORY_CATALOG_PATH))
	var wallet := wallet_scene.instantiate()
	host.add_child(wallet)
	wallet.call(&"add_carried", 500)
	var service := service_scene.instantiate()
	host.add_child(service)
	if not service.call(
		&"configure",
		equipment,
		inventory,
		wallet,
		load(EQUIPMENT_UPGRADE_POLICY_PATH)
	):
		_fail("장비 강화 비용 서비스를 구성하지 못했습니다.")
		return false

	var module_item: Resource
	var part_item: Resource
	for entry in inventory.call(&"get_snapshot")[&"items"]:
		var linked: Resource = entry[&"linked_resource"]
		if linked == null:
			continue
		if linked.has_method(&"maximum_upgrade_level") and linked.get("module_id") == &"ballistic_core":
			module_item = inventory.call(&"take_item", entry[&"instance_id"])
			equipment.call(&"install_module", &"main", &"test_ballistic", linked)
		elif linked.has_method(&"supports_weapon") and linked.get("part_id") == &"rifle_scope":
			part_item = inventory.call(&"take_item", entry[&"instance_id"])
			equipment.call(&"install_part", &"main", linked)
	if module_item == null or part_item == null:
		_fail("강화 테스트용 동일 모듈·고유 파츠 아이템을 찾지 못했습니다.")
		return false
	inventory.call(&"add_item", module_item)
	inventory.call(&"add_item", part_item)
	var module_quote: Dictionary = service.call(
		&"quote_upgrade", &"module", &"main", &"test_ballistic"
	)
	if not bool(module_quote.get(&"can_upgrade", false)) or not service.call(
		&"upgrade", &"module", &"main", &"test_ballistic"
	):
		_fail("동일 모듈 아이템과 크레딧을 사용한 강화가 실패했습니다.")
		return false
	var part_quote: Dictionary = service.call(
		&"quote_upgrade", &"part", &"main", &"rifle_scope"
	)
	if not bool(part_quote.get(&"can_upgrade", false)) or not service.call(
		&"upgrade", &"part", &"main", &"rifle_scope"
	):
		_fail("동일 고유 파츠 아이템과 크레딧을 사용한 강화가 실패했습니다.")
		return false
	var main_state = equipment.call(&"get_equipment_state", &"main")
	if (
		int(wallet.get("carried_credits")) != 200
		or int(main_state.get("part_upgrade_levels").get(&"rifle_scope", 1)) != 2
		or int(main_state.call(&"get_module_instance", &"test_ballistic").get("upgrade_level")) != 2
	):
		_fail("강화 레벨 또는 크레딧 차감 결과가 예상과 다릅니다.")
		return false

	root.remove_child(host)
	host.free()
	return true


func _verify_equipment_modules() -> bool:
	var loadout := load(EQUIPMENT_LOADOUT_PATH) as EquipmentLoadout
	var equipment_scene := load(EQUIPMENT_SCENE_PATH) as PackedScene
	var player_scene := load(PLAYER_SCENE_PATH) as PackedScene
	if loadout == null or equipment_scene == null or player_scene == null:
		_fail("장비 로드아웃, 장비 Scene 또는 플레이어 Scene을 불러오지 못했습니다.")
		return false
	if not loadout.validation_errors().is_empty():
		_fail("기본 장비 로드아웃이 유효하지 않습니다: %s" % loadout.validation_errors())
		return false
	if loadout.skills.size() != 3 or loadout.armor.size() != 2:
		_fail("기본 장비 로드아웃의 스킬 또는 방어구 수가 예상과 다릅니다.")
		return false

	var rifle_skill: EquipmentSkillDefinition = loadout.skills[0]
	var dagger_skill: EquipmentSkillDefinition = loadout.skills[2]
	if (
		not rifle_skill.matches_weapon(loadout.main_weapon)
		or rifle_skill.matches_weapon(loadout.secondary_weapon)
		or dagger_skill.matches_weapon(loadout.main_weapon)
		or dagger_skill.matches_weapon(loadout.secondary_weapon)
	):
		_fail("무기 대·중·소분류의 완전 일치 판정이 올바르지 않습니다.")
		return false

	var empty_skill_loadout := loadout.duplicate(true) as EquipmentLoadout
	empty_skill_loadout.skills = []
	if not empty_skill_loadout.validation_errors().is_empty():
		_fail("스킬 0개 로드아웃이 거부됐습니다.")
		return false
	var overflow_loadout := loadout.duplicate(true) as EquipmentLoadout
	overflow_loadout.skills = []
	for _index in range(11):
		overflow_loadout.skills.append(rifle_skill)
	if "최대 10개" not in " / ".join(overflow_loadout.validation_errors()):
		_fail("스킬 10개 초과 제한이 적용되지 않았습니다.")
		return false

	var player := player_scene.instantiate()
	var equipment := equipment_scene.instantiate()
	root.add_child(player)
	root.add_child(equipment)
	await process_frame
	var configured := bool(equipment.call(&"configure", loadout, player, true, true, true))
	var failure_message := ""
	var active_ids: PackedStringArray = equipment.call(&"get_active_skill_ids")
	var inactive_ids: PackedStringArray = equipment.call(&"get_inactive_skill_ids")
	var modifiers: Dictionary = equipment.call(&"get_stat_modifiers")
	if not configured:
		failure_message = "기본 장비 로드아웃 조립이 실패했습니다."
	elif active_ids.size() != 2 or &"rifle_burst" not in active_ids or &"pistol_quickdraw" not in active_ids:
		failure_message = "호환 스킬 두 개가 활성화되지 않았습니다: %s" % active_ids
	elif inactive_ids.size() != 1 or &"dagger_dash" not in inactive_ids:
		failure_message = "비호환 단검 스킬이 비활성 목록에 없습니다: %s" % inactive_ids
	elif not is_equal_approx(float(modifiers[&"max_health"][&"add"]), 25.0):
		failure_message = "방어구 최대 체력 수정자가 집계되지 않았습니다."
	elif not is_equal_approx(float(player.get("max_health")), 125.0):
		failure_message = "장비 최대 체력이 플레이어에 적용되지 않았습니다."
	elif not is_equal_approx(float(player.get("defense")), 3.0):
		failure_message = "장비 방어력이 플레이어에 적용되지 않았습니다."
	elif not is_equal_approx(float(player.get_node("Movement").get("speed")), 300.0):
		failure_message = "장비 이동 속도가 플레이어에 적용되지 않았습니다."
	elif equipment.call(&"get_active_weapon_slot") != &"main":
		failure_message = "초기 활성 무기가 메인 슬롯이 아닙니다."
	elif not equipment.call(&"switch_active_weapon"):
		failure_message = "보조 무기로 교체하지 못했습니다."
	elif equipment.call(&"get_active_weapon").weapon_id != &"service_pistol":
		failure_message = "Q 교체용 활성 무기 상태가 권총으로 바뀌지 않았습니다."
	elif not equipment.call(&"switch_active_weapon"):
		failure_message = "메인 무기로 복귀하지 못했습니다."
	else:
		player.call(&"take_damage", 10.0)
		if not is_equal_approx(float(player.get("current_health")), 118.0):
			failure_message = "방어력 3이 피해 10에서 차감되지 않았습니다."

	if failure_message.is_empty():
		var greatsword = load("res://game/features/equipment/definitions/weapons/greatsword.tres")
		var rifle_scope = load("res://game/features/equipment/definitions/parts/rifle_scope.tres")
		var pistol_part = load("res://game/features/equipment/definitions/parts/pistol_compensator.tres")
		var ballistic = load("res://game/features/equipment/definitions/modules/ballistic_core.tres")
		var vitality = load("res://game/features/equipment/definitions/modules/vitality_matrix.tres")
		var mobility = load("res://game/features/equipment/definitions/modules/mobility_chip.tres")
		var armor_plate = load("res://game/features/equipment/definitions/modules/armor_plate.tres")
		if equipment.call(&"can_equip_definition", &"main", greatsword):
			failure_message = "메인 슬롯이 소총 외 소분류 장비를 허용했습니다."
		elif not equipment.call(&"install_part", &"main", rifle_scope):
			failure_message = "소총 전용 optic 파츠를 장착하지 못했습니다."
		elif equipment.call(&"install_part", &"main", pistol_part):
			failure_message = "권총 전용 파츠가 소총에 장착됐습니다."
		elif not equipment.call(&"install_module", &"main", &"ballistic_1", ballistic):
			failure_message = "무기 모듈을 장착하지 못했습니다."
		elif equipment.call(&"install_module", &"main", &"vitality_1", vitality):
			failure_message = "무기 모듈 코스트 한도를 초과해 장착됐습니다."
		elif not equipment.call(&"install_module", &"main", &"mobility_1", mobility):
			failure_message = "남은 코스트 범위의 두 번째 모듈을 장착하지 못했습니다."
		elif not equipment.call(&"upgrade_module", &"main", &"ballistic_1"):
			failure_message = "모듈 강화가 거부됐습니다."
		else:
			var main_state := equipment.call(&"get_equipment_state", &"main") as EquipmentItemState
			if main_state.used_module_cost() != 6:
				failure_message = "모듈 강화 후 코스트가 감소하지 않았습니다."
			elif not equipment.call(&"level_up_equipment", &"main"):
				failure_message = "무기 레벨업 1단계가 실패했습니다."
			elif not equipment.call(&"level_up_equipment", &"main"):
				failure_message = "무기 최고 레벨 도달이 실패했습니다."
			elif not equipment.call(&"grant_module_tag", &"main", &"ballistic"):
				failure_message = "최고 레벨 무기의 개조 태그 부여가 실패했습니다."
			elif main_state.used_module_cost() != 5:
				failure_message = "일치 모듈 태그의 50% 코스트 규칙이 적용되지 않았습니다."
			elif equipment.call(&"install_part", &"body", rifle_scope):
				failure_message = "방어구가 무기 파츠를 허용했습니다."
			elif not equipment.call(&"install_module", &"body", &"plate_1", armor_plate):
				failure_message = "방어구 모듈을 장착하지 못했습니다."
			elif not equipment.call(&"upgrade_module", &"body", &"plate_1"):
				failure_message = "방어구 모듈 강화가 실패했습니다."
			else:
				for _index in range(3):
					equipment.call(&"level_up_equipment", &"body")
				var body_state := equipment.call(&"get_equipment_state", &"body") as EquipmentItemState
				if not equipment.call(&"grant_module_tag", &"body", &"defense"):
					failure_message = "최고 레벨 방어구 개조가 실패했습니다."
				elif body_state.used_module_cost() != 2:
					failure_message = "방어구 태그 일치 코스트가 절반으로 줄지 않았습니다."
				elif not is_equal_approx(float(player.get("defense")), 5.0):
					failure_message = "방어구 모듈 능력치가 플레이어에 반영되지 않았습니다."

	root.remove_child(equipment)
	equipment.free()
	root.remove_child(player)
	player.free()
	if not failure_message.is_empty():
		_fail("장비 모듈 실패: %s" % failure_message)
		return false
	return true


func _verify_weapon_balance_modules() -> bool:
	var balance_scene := load(WEAPON_BALANCE_SCENE_PATH) as PackedScene
	var balance_config := load(WEAPON_BALANCE_CONFIG_PATH) as WeaponBalanceConfig
	if balance_scene == null or balance_config == null:
		_fail("무기 밸런스 Scene 또는 Config를 불러오지 못했습니다.")
		return false
	var service := balance_scene.instantiate()
	root.add_child(service)
	await process_frame
	var failure_message := ""
	if not service.call(&"configure", balance_config):
		failure_message = "확정 무기 밸런스 CSV 로드에 실패했습니다."
	else:
		var rifle: Dictionary = service.call(&"get_weapon_balance", &"assault_rifle")
		var pistol: Dictionary = service.call(&"get_weapon_balance", &"service_pistol")
		if rifle.is_empty() or pistol.is_empty():
			failure_message = "소총 또는 권총 밸런스 행이 없습니다."
		elif int(rifle.get(&"burst_count", 0)) != 3:
			failure_message = "돌격소총 3점사 특색이 적용되지 않았습니다."
		elif float(rifle.get(&"target_range_px", 0.0)) <= float(pistol.get(&"target_range_px", 0.0)):
			failure_message = "돌격소총의 장거리 특색이 권총보다 낮습니다."
		elif float(pistol.get(&"damage", 0.0)) <= float(rifle.get(&"damage", 0.0)):
			failure_message = "권총의 고위력 단발 특색이 적용되지 않았습니다."
		elif int(pistol.get(&"pierce_count", 0)) != 1:
			failure_message = "권총의 1회 관통 특색이 적용되지 않았습니다."
		elif service.call(&"load_csv_text", "weapon_id,damage\nbroken,1", "오류 테스트"):
			failure_message = "필수 열이 없는 밸런스 CSV를 허용했습니다."
		if failure_message.is_empty():
			var sheet_csv := "\n".join(PackedStringArray([
				"weapon_id,display_name,runtime_enabled,trait_id,damage,fire_interval_sec,projectile_speed_px_sec,target_range_px,projectiles_per_shot,spread_angle_deg,burst_count,burst_interval_sec,critical_chance,critical_multiplier,pierce_count,pierce_damage_retention,projectile_lifetime_sec,projectile_color_hex,description",
				"고유 ID,표시 이름,런타임 반영,특색,피해,공격 주기,투사체 속도,탐지 거리,투사체 수,분산각,점사 수,점사 간격,치명타 확률,치명타 배율,관통 수,관통 유지율,수명,색상,설명",
				"assault_rifle,돌격소총,TRUE,steady_burst,1.6,0.78,760,820,1,0,3,0.10,0.05,1.75,0,1.0,1.6,#42D6C8,테스트 소총",
				"service_pistol,제식 권총,TRUE,heavy_piercing,3.2,0.60,690,560,1,0,1,0.00,0.12,2.0,1,0.65,1.3,#F2B84B,테스트 권총",
				"combat_dagger,전투 단검,FALSE,,,,,,,,,,,,,,,,",
			]))
			var parsed_sheet := WeaponBalanceTable.parse(sheet_csv)
			var sheet_errors: PackedStringArray = parsed_sheet[&"errors"]
			var sheet_data: Dictionary = parsed_sheet[&"data"]
			if not sheet_errors.is_empty() or sheet_data.size() != 2:
				failure_message = "2행 설명을 포함한 Google Sheet CSV를 2개 런타임 무기로 읽지 못했습니다."
	if not _has_key_binding(&"switch_weapon", KEY_Q):
		failure_message = "switch_weapon 입력에 Q 키가 할당되지 않았습니다."
	root.remove_child(service)
	service.free()
	if not failure_message.is_empty():
		_fail("무기 밸런스 모듈 실패: %s" % failure_message)
		return false
	return true


func _verify_growth_balance_modules() -> bool:
	var balance_scene := load(GROWTH_BALANCE_SCENE_PATH) as PackedScene
	var balance_config := load(GROWTH_BALANCE_CONFIG_PATH) as Resource
	if balance_scene == null or balance_config == null:
		_fail("성장 밸런스 Scene 또는 Config를 불러오지 못했습니다.")
		return false
	var service := balance_scene.instantiate()
	root.add_child(service)
	await process_frame
	var failure_message := ""
	if not service.call(&"configure", balance_config):
		failure_message = "확정 성장 밸런스 CSV 로드에 실패했습니다."
	else:
		var snapshot: Dictionary = service.call(&"get_snapshot")
		var catalog := service.call(&"get_run_buff_catalog") as RunBuffCatalog
		var rifle_level_two: Dictionary = service.call(
			&"get_weapon_modifiers", &"weapon", &"assault_rifle", 2
		)
		var vest_level_two: Dictionary = service.call(
			&"get_player_modifiers", &"armor", &"tactical_vest", 2
		)
		var module_quote: Dictionary = service.call(
			&"quote_upgrade", &"module", &"ballistic_core", 1
		)
		if int(snapshot.get(&"run_buff_count", 0)) != 5:
			failure_message = "RunBuff 시트의 내부 성장 선택지 5개를 읽지 못했습니다."
		elif int(snapshot.get(&"upgrade_spec_count", 0)) != 25:
			failure_message = "Upgrade 시트의 강화 스펙 25개를 읽지 못했습니다."
		elif catalog == null or catalog.get_buff(&"vitality") == null:
			failure_message = "내부 성장 CSV를 RunBuffCatalog로 변환하지 못했습니다."
		elif not is_equal_approx(float(rifle_level_two.get(&"damage_add", 0.0)), 0.5):
			failure_message = "돌격소총 Lv.2 시트 피해 보너스를 읽지 못했습니다."
		elif not is_equal_approx(
			float((vest_level_two.get(&"defense", {}) as Dictionary).get(&"add", 0.0)),
			1.0
		):
			failure_message = "전술 방탄복 Lv.2 시트 방어력 보너스를 읽지 못했습니다."
		elif int(service.call(
			&"get_module_capacity_cost", &"ballistic_core", 2, 99
		)) != 3:
			failure_message = "모듈 Lv.2 장착 코스트를 시트에서 읽지 못했습니다."
		elif (
			int(module_quote.get(&"credit_cost", -1)) != 120
			or int(module_quote.get(&"material_quantity", -1)) != 1
		):
			failure_message = "모듈 1→2 강화 비용을 시트에서 읽지 못했습니다."
		elif service.call(&"load_upgrade_csv_text", "target_kind,target_id\nmodule,broken", "오류 테스트"):
			failure_message = "필수 열이 없는 성장 CSV를 허용했습니다."
		elif int((service.call(&"get_snapshot") as Dictionary).get(&"upgrade_spec_count", 0)) != 25:
			failure_message = "잘못된 갱신 후 마지막 정상 성장 데이터가 보존되지 않았습니다."
	root.remove_child(service)
	service.free()
	if not failure_message.is_empty():
		_fail("성장 밸런스 모듈 실패: %s" % failure_message)
		return false
	return true


func _verify_balance_mode_selector() -> bool:
	var game_scene := load(GAME_SCENE_PATH) as PackedScene
	if game_scene == null:
		_fail("밸런스 모드 UI를 검증할 Game Scene을 불러오지 못했습니다.")
		return false
	var selector_game := game_scene.instantiate()
	root.add_child(selector_game)
	await process_frame
	var locked_button := selector_game.get_node(
		"UI/RunSetupOverlay/Center/Panel/Margin/Content/BalanceModeSection/Buttons/LockedBalanceButton"
	) as Button
	var live_button := selector_game.get_node(
		"UI/RunSetupOverlay/Center/Panel/Margin/Content/BalanceModeSection/Buttons/LiveBalanceButton"
	) as Button
	var description := selector_game.get_node(
		"UI/RunSetupOverlay/Center/Panel/Margin/Content/BalanceModeSection/BalanceModeDescription"
	) as Label
	var failure_message := ""
	if not locked_button.button_pressed or live_button.button_pressed:
		failure_message = "작전 선택 화면의 기본 밸런스 모드가 확정 CSV가 아닙니다."
	elif live_button.disabled:
		failure_message = "Google Sheet URL이 있지만 실시간 테스트 버튼이 비활성화됐습니다."
	else:
		live_button.pressed.emit()
		if (
			int(selector_game.get("selected_balance_source_mode"))
			!= WeaponBalanceConfig.SourceMode.LIVE_GOOGLE_SHEET
			or not live_button.button_pressed
			or locked_button.button_pressed
			or "3초" not in description.text
		):
			failure_message = "실시간 테스트 버튼이 선택 상태와 설명을 갱신하지 못했습니다."
		locked_button.pressed.emit()
		if (
			int(selector_game.get("selected_balance_source_mode"))
			!= WeaponBalanceConfig.SourceMode.LOCKED_CSV
			or not locked_button.button_pressed
			or live_button.button_pressed
		):
			failure_message = "확정 CSV 버튼으로 복귀하지 못했습니다."
	root.remove_child(selector_game)
	selector_game.free()
	if not failure_message.is_empty():
		_fail("밸런스 모드 UI 실패: %s" % failure_message)
		return false
	return true


func _verify_inventory_modules() -> bool:
	var inventory_scene := load(INVENTORY_SCENE_PATH) as PackedScene
	var catalog := load(INVENTORY_CATALOG_PATH) as InventoryCatalog
	if inventory_scene == null or catalog == null or not catalog.validation_errors().is_empty():
		_fail("인벤토리 Scene 또는 기본 카탈로그가 유효하지 않습니다.")
		return false
	var inventory := inventory_scene.instantiate()
	root.add_child(inventory)
	if not inventory.call(&"configure", catalog):
		_fail("기본 가방 아이템 자동 배치가 실패했습니다.")
		return false
	var snapshot: Dictionary = inventory.call(&"get_snapshot")
	var sizes: Dictionary = {}
	var entries: Array = snapshot[&"items"]
	for index in range(entries.size()):
		var entry: Dictionary = entries[index]
		sizes[entry[&"grid_size"]] = true
		if entry[&"item_type"] == &"module" and entry[&"grid_size"] != Vector2i.ONE:
			_fail("모듈 아이템이 가방 한 칸보다 크게 정의됐습니다.")
			return false
		var rect := Rect2i(entry[&"position"], entry[&"grid_size"])
		if not Rect2i(Vector2i.ZERO, snapshot[&"grid_size"]).encloses(rect):
			_fail("가방 아이템이 격자 경계를 벗어났습니다.")
			return false
		for other_index in range(index + 1, entries.size()):
			var other: Dictionary = entries[other_index]
			if rect.intersects(Rect2i(other[&"position"], other[&"grid_size"])):
				_fail("가방 아이템 패널이 서로 겹쳤습니다.")
				return false
	if sizes.size() < 4:
		_fail("아이템별 가변 패널 크기가 충분히 구성되지 않았습니다.")
		return false
	var first: Dictionary = entries[0]
	if inventory.call(&"move_item", first[&"instance_id"], Vector2i(-1, 0)):
		_fail("가방 경계 밖 이동이 허용됐습니다.")
		return false
	if not _has_key_binding(&"toggle_inventory", KEY_I):
		_fail("I 키가 가방 열기 입력에 연결되지 않았습니다.")
		return false
	if not _has_key_binding(&"toggle_equipment", KEY_U):
		_fail("U 키가 장비 화면 입력에 연결되지 않았습니다.")
		return false
	if not _has_key_binding(&"toggle_equipment", KEY_E):
		_fail("E 키가 장비 화면 보조 입력에 연결되지 않았습니다.")
		return false
	root.remove_child(inventory)
	inventory.free()
	return true


func _verify_optional_equipment_module(game_scene: PackedScene) -> bool:
	var equipment_free_game := game_scene.instantiate()
	var equipment_free_features = equipment_free_game.get("features").duplicate(true)
	equipment_free_features.set("equipment_enabled", false)
	equipment_free_features.set("equipment_weapons_enabled", false)
	equipment_free_features.set("equipment_skills_enabled", false)
	equipment_free_features.set("equipment_armor_enabled", false)
	equipment_free_features.set("equipment_customization_enabled", false)
	equipment_free_features.set("equipment_upgrade_economy_enabled", false)
	equipment_free_features.set("growth_balance_enabled", false)
	equipment_free_features.set("run_setup_enabled", false)
	equipment_free_game.set("features", equipment_free_features)
	root.add_child(equipment_free_game)
	await process_frame
	var failure_message := ""
	if equipment_free_game.get("equipment_system") != null:
		failure_message = "비활성화했지만 장비 모듈이 설치됐습니다."
	elif equipment_free_game.get_node("UI/HUDMargin/Panel/Margin/Content/EquipmentLabel").visible:
		failure_message = "비활성화했지만 장비 HUD가 표시됩니다."
	elif not is_equal_approx(float(equipment_free_game.get("player").get("max_health")), 100.0):
		failure_message = "장비 비활성화 시 플레이어 기본 체력이 유지되지 않았습니다."

	root.remove_child(equipment_free_game)
	equipment_free_game.free()
	await process_frame
	if not failure_message.is_empty():
		_fail("장비 모듈 비활성화 실패: %s" % failure_message)
		return false
	return true


func _verify_optional_weapon_balance_module(game_scene: PackedScene) -> bool:
	var balance_free_game := game_scene.instantiate()
	var balance_free_features = balance_free_game.get("features").duplicate(true)
	balance_free_features.set("weapon_balance_enabled", false)
	balance_free_features.set("run_setup_enabled", false)
	balance_free_game.set("features", balance_free_features)
	root.add_child(balance_free_game)
	await process_frame
	var failure_message := ""
	var weapon = balance_free_game.get("auto_weapon")
	if balance_free_game.get("weapon_balance_service") != null:
		failure_message = "비활성화했지만 무기 밸런스 서비스가 설치됐습니다."
	elif weapon == null:
		failure_message = "밸런스 모듈과 함께 자동 무기까지 제거됐습니다."
	else:
		var snapshot: Dictionary = weapon.call(&"get_runtime_snapshot")
		if snapshot.get(&"source_label", "") != "내장 기본값":
			failure_message = "밸런스 비활성화 시 자동 무기 기본값으로 폴백하지 않았습니다."
	root.remove_child(balance_free_game)
	balance_free_game.free()
	await process_frame
	if not failure_message.is_empty():
		_fail("무기 밸런스 모듈 비활성화 실패: %s" % failure_message)
		return false
	return true


func _verify_optional_growth_balance_module(game_scene: PackedScene) -> bool:
	var growth_free_game := game_scene.instantiate()
	var growth_free_features = growth_free_game.get("features").duplicate(true)
	growth_free_features.set("growth_balance_enabled", false)
	growth_free_features.set("run_setup_enabled", false)
	growth_free_game.set("features", growth_free_features)
	root.add_child(growth_free_game)
	await process_frame
	var failure_message := ""
	var equipment = growth_free_game.get("equipment_system")
	var run_buffs = growth_free_game.get("run_buff_system")
	var upgrade_service = growth_free_game.get("equipment_upgrade_service")
	if growth_free_game.get("growth_balance_service") != null:
		failure_message = "비활성화했지만 성장 밸런스 서비스가 설치됐습니다."
	elif equipment == null or run_buffs == null or upgrade_service == null:
		failure_message = "성장 데이터와 함께 기존 장비·버프·강화 기능까지 제거됐습니다."
	elif equipment.get("upgrade_balance_provider") != null:
		failure_message = "성장 데이터 비활성화 뒤 장비 제공자가 남았습니다."
	elif upgrade_service.get("balance_provider") != null:
		failure_message = "성장 데이터 비활성화 뒤 강화 제공자가 남았습니다."
	elif run_buffs.get("catalog").call(&"get_buff", &"vitality") == null:
		failure_message = "성장 데이터 비활성화 시 기본 RunBuff Resource로 폴백하지 않았습니다."
	root.remove_child(growth_free_game)
	growth_free_game.free()
	await process_frame
	if not failure_message.is_empty():
		_fail("성장 밸런스 모듈 비활성화 실패: %s" % failure_message)
		return false
	return true


func _verify_optional_progression_modules(game_scene: PackedScene) -> bool:
	var progression_free_game := game_scene.instantiate()
	var progression_free_features = progression_free_game.get("features").duplicate(true)
	progression_free_features.set("run_buffs_enabled", false)
	progression_free_features.set("growth_balance_enabled", false)
	progression_free_features.set("meta_progression_enabled", false)
	progression_free_features.set("equipment_upgrade_economy_enabled", false)
	progression_free_features.set("health_recovery_enabled", false)
	progression_free_features.set("run_setup_enabled", false)
	progression_free_game.set("features", progression_free_features)
	root.add_child(progression_free_game)
	await process_frame
	var failure_message := ""
	if progression_free_game.get("progression_system") == null:
		failure_message = "내부 경험치 기반까지 함께 제거됐습니다."
	elif progression_free_game.get("run_buff_system") != null:
		failure_message = "비활성화했지만 런 버프 모듈이 설치됐습니다."
	elif progression_free_game.get("meta_progression_system") != null:
		failure_message = "비활성화했지만 외부 성장 모듈이 설치됐습니다."
	elif progression_free_game.get("equipment_upgrade_service") != null:
		failure_message = "비활성화했지만 장비 강화 경제 모듈이 설치됐습니다."
	elif progression_free_game.get("health_recovery_system") != null:
		failure_message = "비활성화했지만 부분 체력 회복 모듈이 설치됐습니다."
	root.remove_child(progression_free_game)
	progression_free_game.free()
	await process_frame
	if not failure_message.is_empty():
		_fail("성장·회복 선택 모듈 비활성화 실패: %s" % failure_message)
		return false
	return true


func _verify_optional_meta_operation_modules(game_scene: PackedScene) -> bool:
	var fallback_game := game_scene.instantiate()
	var fallback_features = fallback_game.get("features").duplicate(true)
	for property_name in [
		"persistent_profile_enabled", "operation_contracts_enabled",
		"extraction_defense_enabled", "hub_economy_enabled", "smart_targeting_enabled",
		"crafting_enabled", "penalty_modifiers_enabled", "conditional_ranking_enabled",
	]:
		fallback_features.set(property_name, false)
	fallback_features.set("run_setup_enabled", false)
	fallback_game.set("features", fallback_features)
	root.add_child(fallback_game)
	await process_frame
	var failure_message := ""
	if not bool(fallback_game.get("run_started")):
		failure_message = "메타·계약 모듈 비활성화 상태에서 기본 작전을 시작하지 못했습니다."
	elif (
		fallback_game.get("persistent_profile") != null
		or fallback_game.get("operation_contract_service") != null
		or fallback_game.get("hub_economy_system") != null
		or fallback_game.get("crafting_system") != null
		or fallback_game.get("penalty_system") != null
		or fallback_game.get("conditional_ranking_system") != null
	):
		failure_message = "비활성화한 메타·계약 Node가 설치됐습니다."
	else:
		var weapon = fallback_game.get("auto_weapon")
		var extraction = fallback_game.get("extraction_zone")
		if weapon == null or weapon.call(&"get_runtime_snapshot").get(&"targeting_mode") != &"nearest":
			failure_message = "스마트 타게팅 비활성화가 최근접 대상 폴백을 유지하지 못했습니다."
		elif extraction == null or float(extraction.get("defense_duration_seconds")) != 0.0:
			failure_message = "탈출 방어전 비활성화가 즉시 탈출 폴백을 유지하지 못했습니다."
	root.remove_child(fallback_game)
	fallback_game.free()
	await process_frame
	if not failure_message.is_empty():
		_fail("메타·계약 선택 모듈 실패: %s" % failure_message)
		return false
	return true


func _verify_all_tier_entry(game_scene: PackedScene) -> bool:
	var button_names := {
		"small": "SmallMapButton",
		"medium": "MediumMapButton",
		"large": "LargeMapButton",
	}
	for tier_id in MAP_TIER_IDS:
		var tier_game := game_scene.instantiate()
		root.add_child(tier_game)
		await process_frame
		var button := tier_game.get_node(
			"UI/RunSetupOverlay/Center/Panel/Margin/Content/TierButtons/%s" % button_names[tier_id]
		) as Button
		var failure_message := ""
		if button.disabled:
			failure_message = "%s 작전 버튼이 비활성화됐습니다: %s" % [tier_id, button.text]
		else:
			button.pressed.emit()
			await process_frame
			var generator = tier_game.get("map_generator")
			var minimap = tier_game.get("minimap")
			var fog = tier_game.get("fog_of_war")
			var enemy_spawner = tier_game.get("enemy_spawner")
			var room_encounters = tier_game.get("room_encounter_system")
			var loot_spawner = tier_game.get("loot_spawner")
			var auto_weapon = tier_game.get("auto_weapon")
			var config = load(MAP_CONFIG_PATH_PATTERN % tier_id)
			if not bool(tier_game.get("run_started")):
				failure_message = "%s 작전이 시작 상태로 전환되지 않았습니다." % tier_id
			elif String(tier_game.get("selected_map_size")) != tier_id:
				failure_message = "%s 작전 선택값이 조립부에 전달되지 않았습니다." % tier_id
			elif tier_game.get("player") == null or generator == null:
				failure_message = "%s 작전의 플레이어 또는 맵이 설치되지 않았습니다." % tier_id
			elif tier_game.get("extraction_zone") == null or minimap == null:
				failure_message = "%s 작전의 탈출 또는 미니맵이 설치되지 않았습니다." % tier_id
			elif fog == null or not _verify_room_and_corridor_fog(fog, generator, tier_game.get("player")):
				failure_message = "%s 작전의 전장의 안개가 플레이어를 추적하지 않습니다." % tier_id
			elif enemy_spawner == null or room_encounters == null or loot_spawner == null:
				failure_message = "%s 작전의 적 생성 또는 파밍 모듈이 설치되지 않았습니다." % tier_id
			elif auto_weapon == null or auto_weapon.get("target_provider") != enemy_spawner:
				failure_message = "%s 작전의 자동 무기에 적 대상 제공자가 연결되지 않았습니다." % tier_id
			elif not _verify_tier_population_and_value(enemy_spawner, loot_spawner, config, tier_id):
				failure_message = "%s 작전의 증원 수량 또는 최소 배치 가치가 올바르지 않습니다." % tier_id
			elif not _verify_room_encounter_flow(
				room_encounters, enemy_spawner, generator, tier_game.get("progression_system"), tier_id
			):
				failure_message = "%s 작전의 방 봉쇄·섬멸·보상 흐름이 올바르지 않습니다." % tier_id
			elif (
				tier_game.get("inventory_system") == null
				or tier_game.get("inventory_window") == null
				or tier_game.get("equipment_workbench") == null
			):
				failure_message = "%s 작전의 가방 또는 장비 개조 UI가 설치되지 않았습니다." % tier_id
			elif tier_id == "small" and not _verify_loadout_workbench_ui(tier_game):
				failure_message = "U 장비·모듈 카드 UI의 구성 또는 공개 동작이 올바르지 않습니다."
			elif generator.get("rooms").size() < int(config.get("minimum_rooms")):
				failure_message = "%s 작전의 최소 방 수를 생성하지 못했습니다." % tier_id
			else:
				var map_view = minimap.get_node("Margin/Content/MapView")
				if map_view.get("map_texture") == null:
					failure_message = "%s 작전의 미니맵 텍스처가 생성되지 않았습니다." % tier_id
				else:
					var snapshot: Dictionary = generator.call(&"get_minimap_snapshot")
					if Vector2i(map_view.get("map_texture").get_size()) != snapshot[&"cell_bounds"].size:
						failure_message = "%s 미니맵이 전체 지형 스냅샷을 유지하지 않습니다." % tier_id

		root.remove_child(tier_game)
		tier_game.free()
		await process_frame
		if not failure_message.is_empty():
			_fail("티어 진입 실패: %s" % failure_message)
			return false
	return true


func _verify_room_and_corridor_fog(fog: Node, generator: Node, player: Node2D) -> bool:
	var room_snapshot: Dictionary = fog.call(&"get_snapshot")
	if (
		not bool(room_snapshot.get(&"tracks_actor", false))
		or not bool(room_snapshot.get(&"has_visibility_provider", false))
		or room_snapshot.get(&"visibility_mode") != &"room"
		or int(room_snapshot.get(&"active_room_index", -1)) < 0
		or not is_equal_approx(float(room_snapshot.get(&"room_visibility_blend", 0.0)), 1.0)
		or int(room_snapshot.get(&"room_rect_count", 0)) != generator.get("rooms").size()
	):
		return false
	var corridor_position := _find_corridor_position(generator)
	if corridor_position == Vector2.INF:
		return false
	var original_position := player.global_position
	player.global_position = corridor_position
	var exit_seconds := float(room_snapshot.get(&"room_exit_transition_seconds", 0.0))
	fog.call(&"_process", exit_seconds * 0.5)
	var doorway_exit_snapshot: Dictionary = fog.call(&"get_snapshot")
	fog.call(&"_process", exit_seconds)
	var corridor_snapshot: Dictionary = fog.call(&"get_snapshot")
	player.global_position = original_position
	var enter_seconds := float(room_snapshot.get(&"room_enter_transition_seconds", 0.0))
	fog.call(&"_process", enter_seconds * 0.5)
	var doorway_enter_snapshot: Dictionary = fog.call(&"get_snapshot")
	fog.call(&"_process", enter_seconds)
	var settled_room_snapshot: Dictionary = fog.call(&"get_snapshot")
	return (
		doorway_exit_snapshot.get(&"visibility_mode") == &"corridor"
		and float(doorway_exit_snapshot.get(&"room_visibility_blend", 0.0)) > 0.0
		and float(doorway_exit_snapshot.get(&"room_visibility_blend", 1.0)) < 1.0
		and int(doorway_exit_snapshot.get(&"transition_room_index", -1)) >= 0
		and corridor_snapshot.get(&"visibility_mode") == &"corridor"
		and int(corridor_snapshot.get(&"active_room_index", -1)) == -1
		and int(corridor_snapshot.get(&"transition_room_index", -1)) == -1
		and is_zero_approx(float(corridor_snapshot.get(&"room_visibility_blend", 1.0)))
		and float(corridor_snapshot.get(&"corridor_forward_distance", 0.0))
		> float(corridor_snapshot.get(&"corridor_near_radius", 0.0))
		and (corridor_snapshot.get(&"facing_direction", Vector2.ZERO) as Vector2)
		== player.call(&"get_facing_direction")
		and doorway_enter_snapshot.get(&"visibility_mode") == &"room"
		and float(doorway_enter_snapshot.get(&"room_visibility_blend", 0.0)) > 0.0
		and float(doorway_enter_snapshot.get(&"room_visibility_blend", 1.0)) < 1.0
		and is_equal_approx(
			float(settled_room_snapshot.get(&"room_visibility_blend", 0.0)), 1.0
		)
	)


func _verify_tier_population_and_value(
	enemy_spawner: Node,
	loot_spawner: Node,
	map_config: Resource,
	tier_id: String
) -> bool:
	var spawn_config = load(SPAWN_CONFIG_PATH_PATTERN % tier_id)
	var population: Dictionary = enemy_spawner.call(&"get_snapshot")
	var target_count := int(population.get(&"target_active_enemies", 0))
	if (
		target_count < int(spawn_config.get("minimum_active_enemies"))
		or target_count > int(spawn_config.get("maximum_active_enemies"))
	):
		return false
	if (
		not bool(population.get(&"reinforcement_paused", false))
		or int(population.get(&"active_enemies", 0)) != 0
		or int(population.get(&"reinforcement_count", 0)) != 0
	):
		return false
	var loot_snapshot: Dictionary = loot_spawner.call(&"get_spawn_snapshot")
	var expected_minimum := ceili(float(map_config.get("entry_cost")) * 2.5)
	var expected_maximum := floori(float(map_config.get("entry_cost")) * 5.0)
	var target_total := int(loot_snapshot.get(&"target_total_credits", 0))
	var placed_total := int(loot_snapshot.get(&"total_placed_credits", 0))
	var selected_multiplier := float(loot_snapshot.get(&"selected_value_multiplier", 0.0))
	return (
		int(loot_snapshot.get(&"minimum_total_credits", 0)) == expected_minimum
		and int(loot_snapshot.get(&"maximum_total_credits", 0)) == expected_maximum
		and target_total >= expected_minimum
		and target_total <= expected_maximum
		and placed_total == target_total
		and selected_multiplier >= 2.5
		and selected_multiplier <= 5.0
		and bool(loot_snapshot.get(&"minimum_value_satisfied", false))
		and bool(loot_snapshot.get(&"maximum_value_respected", false))
		and bool(loot_snapshot.get(&"target_value_satisfied", false))
	)


func _verify_room_encounter_flow(
	room_encounters: Node,
	enemy_spawner: Node,
	generator: Node,
	progression: Node,
	tier_id: String
) -> bool:
	var room_index := -1
	for room: Dictionary in generator.call(&"get_room_encounter_snapshot"):
		if not bool(room[&"is_start_room"]) and not bool(room[&"is_extraction_room"]):
			room_index = int(room[&"room_index"])
			if not (room.get(&"doorways", []) as Array).is_empty():
				break
	if room_index < 0 or not room_encounters.call(&"try_start_room", room_index):
		return false
	var active: Dictionary = room_encounters.call(&"get_snapshot")
	var config: Resource = load(ROOM_ENCOUNTER_CONFIG_PATH)
	var tier_values: Dictionary = config.call(&"values_for", StringName(tier_id))
	var enemy_count := int(active.get(&"active_enemy_count", 0))
	if (
		int(active.get(&"active_room_index", -1)) != room_index
		or enemy_count < int(tier_values[&"minimum_enemies"])
		or enemy_count > int(tier_values[&"maximum_enemies"])
		or int(active.get(&"locked_door_count", 0)) <= 0
		or active.get(&"reinforcement_mode") != &"room_triggered"
	):
		return false
	for enemy in enemy_spawner.call(&"get_active_targets"):
		if enemy.get_meta(&"room_encounter_id", &"") == StringName("room_%d" % room_index):
			enemy.free()
	room_encounters.call(&"_process", 0.0)
	var cleared: Dictionary = room_encounters.call(&"get_snapshot")
	if (
		int(cleared.get(&"active_room_index", -2)) != -1
		or int(cleared.get(&"locked_door_count", -1)) != 0
		or int(cleared.get(&"completed_encounters", 0)) != 1
	):
		return false
	var rewards := get_nodes_in_group(&"room_encounter_reward")
	if rewards.size() != 1:
		return false
	var experience_before := 0
	if progression != null:
		experience_before = int(progression.call(&"get_run_snapshot").get(&"current_experience", 0))
	rewards[0].call(&"collect")
	if progression != null:
		var after: Dictionary = progression.call(&"get_run_snapshot")
		if int(after.get(&"current_experience", 0)) == experience_before:
			return false
	return true


func _verify_loadout_workbench_ui(tier_game: Node) -> bool:
	var workbench = tier_game.get("equipment_workbench")
	workbench.call(&"open_panel")
	var equipment_grid := workbench.get_node("%EquipmentInventoryGrid") as GridContainer
	var modification_grid := workbench.get_node("%ModificationInventoryGrid") as GridContainer
	var installed_grid := workbench.get_node("%InstalledModuleGrid") as GridContainer
	var selection_ready := false
	for child in equipment_grid.get_children():
		var card := child as Button
		if card != null and "장착 가능" in card.text:
			card.pressed.emit()
			selection_ready = not (workbench.get_node("%EquipSelectedButton") as Button).disabled
			break
	var valid: bool = (
		workbench.visible
		and paused
		and workbench.size.x >= 1100.0
		and equipment_grid.get_child_count() >= 2
		and modification_grid.get_child_count() >= 4
		and installed_grid.get_child_count() >= 1
		and selection_ready
		and workbench.has_method(&"show_weapon_tab")
		and workbench.has_method(&"show_armor_tab")
	)
	workbench.call(&"close_panel")
	return valid and not paused


func _verify_enemy_stats_modules() -> bool:
	var enemy_scene := load("res://game/features/enemies/enemy.tscn") as PackedScene
	if enemy_scene == null:
		_fail("Enemy Scene을 불러오지 못했습니다.")
		return false
	var enemy := enemy_scene.instantiate()
	root.add_child(enemy)
	await process_frame
	var health = enemy.get_node("HealthComponent")
	var armor = enemy.get_node("ArmorComponent")
	var status_bars := enemy.get_node("StatusBars") as Node2D
	var initial_health := float(health.get("current_value"))
	var initial_armor := float(armor.get("current_value"))
	enemy.call(&"take_damage", 1.0)
	var valid := (
		initial_health > 0.0
		and initial_armor > 0.0
		and is_equal_approx(float(health.get("current_value")), initial_health)
		and float(armor.get("current_value")) < initial_armor
		and status_bars.visible
	)
	root.remove_child(enemy)
	enemy.free()
	if not valid:
		_fail("적 체력·방어력 컴포넌트 또는 상태바가 정상 동작하지 않습니다.")
		return false
	return true


func _verify_enemy_spawn_budget() -> bool:
	var spawner_scene := load(ENEMY_SPAWNER_SCENE_PATH) as PackedScene
	var base_config = load(SPAWN_CONFIG_PATH_PATTERN % "small")
	if spawner_scene == null or base_config == null:
		_fail("유한 적 생성 예산 검증 리소스를 불러오지 못했습니다.")
		return false
	var host := Node2D.new()
	var target := Node2D.new()
	var enemy_parent := Node2D.new()
	root.add_child(host)
	host.add_child(target)
	host.add_child(enemy_parent)
	var spawner := spawner_scene.instantiate()
	host.add_child(spawner)
	var config = base_config.duplicate(true)
	config.set("minimum_active_enemies", 1)
	config.set("maximum_active_enemies", 1)
	config.set("minimum_reinforcement_batch", 1)
	config.set("maximum_reinforcement_batch", 1)
	config.set("initial_delay_seconds", 0.0)
	config.set("reinforcement_interval_seconds", 0.1)
	config.set("maximum_total_spawns", 2)
	if not spawner.call(&"configure", target, enemy_parent, false, null, false, false, config):
		root.remove_child(host)
		host.free()
		_fail("유한 적 생성 예산 모듈 구성에 실패했습니다.")
		return false

	spawner.call(&"_process", 1.0)
	var first_snapshot: Dictionary = spawner.call(&"get_snapshot")
	for enemy in enemy_parent.get_children():
		enemy.queue_free()
	await process_frame
	spawner.call(&"_process", 1.0)
	var exhausted_snapshot: Dictionary = spawner.call(&"get_snapshot")
	for enemy in enemy_parent.get_children():
		enemy.queue_free()
	await process_frame
	spawner.call(&"_process", 1.0)
	var final_snapshot: Dictionary = spawner.call(&"get_snapshot")
	var valid := (
		int(first_snapshot.get(&"total_spawned", 0)) == 1
		and int(exhausted_snapshot.get(&"total_spawned", 0)) == 2
		and int(exhausted_snapshot.get(&"remaining_spawn_budget", -1)) == 0
		and bool(exhausted_snapshot.get(&"spawn_budget_exhausted", false))
		and int(final_snapshot.get(&"total_spawned", 0)) == 2
		and int(final_snapshot.get(&"active_enemies", -1)) == 0
	)
	root.remove_child(host)
	host.free()
	if not valid:
		_fail("적 처치 후 총 생성 예산을 넘어서 재생성됩니다.")
		return false
	return true


func _verify_optional_map_module(game_scene: PackedScene) -> bool:
	var fallback_game := game_scene.instantiate()
	var fallback_features = fallback_game.get("features").duplicate(true)
	fallback_features.set("map_generation_enabled", false)
	fallback_features.set("room_encounters_enabled", false)
	fallback_features.set("map_obstacles_enabled", false)
	fallback_features.set("fog_of_war_enabled", false)
	fallback_features.set("minimap_enabled", false)
	fallback_features.set("extraction_enabled", false)
	fallback_features.set("extraction_defense_enabled", false)
	fallback_features.set("run_setup_enabled", false)
	fallback_features.set("loot_enabled", false)
	fallback_game.set("features", fallback_features)
	root.add_child(fallback_game)
	await process_frame

	var fallback_player = fallback_game.get("player")
	var fallback_spawner = fallback_game.get("enemy_spawner")
	var map_label := fallback_game.get_node(
		"UI/HUDMargin/Panel/Margin/Content/TopRow/MapLabel"
	) as Label
	var failure_message := ""
	if fallback_game.get("map_generator") != null:
		failure_message = "비활성화했지만 맵 생성기가 설치됐습니다."
	elif fallback_player == null or fallback_player.global_position != Vector2.ZERO:
		failure_message = "비활성화 폴백의 플레이어 시작 위치가 원점이 아닙니다: %s" % (
			fallback_player.global_position if fallback_player != null else "player=null"
		)
	elif fallback_spawner == null or fallback_spawner.get("map_provider") != null:
		failure_message = "비활성화 폴백의 적 생성기에 맵 제공자가 남아 있습니다."
	elif map_label.visible:
		failure_message = "비활성화했지만 맵 HUD가 표시됩니다."
	elif fallback_game.get("minimap") != null:
		failure_message = "비활성화했지만 미니맵이 설치됐습니다."
	elif fallback_game.get("fog_of_war") != null:
		failure_message = "비활성화했지만 전장의 안개가 설치됐습니다."

	root.remove_child(fallback_game)
	fallback_game.free()

	if not failure_message.is_empty():
		_fail("맵 모듈 비활성화 실패: %s" % failure_message)
		return false

	return true


func _verify_extraction_flow(game_scene: PackedScene) -> bool:
	var extraction_game := game_scene.instantiate()
	root.add_child(extraction_game)
	await process_frame

	if extraction_game.get("start_hub") == null or extraction_game.get("player") == null:
		_fail("첫 실행 시작 거점이 표시되지 않았습니다.")
		return false

	extraction_game.call(&"start_run", "small")
	await process_frame
	var extraction_player = extraction_game.get("player")
	var extraction_zone = extraction_game.get("extraction_zone")
	var credit_ledger = extraction_game.get("credit_ledger")
	var loot_spawner = extraction_game.get("loot_spawner")
	var failure_message := ""
	if extraction_player == null or extraction_zone == null or credit_ledger == null or loot_spawner == null:
		failure_message = "플레이어, 탈출, 크레딧 또는 파밍 모듈이 설치되지 않았습니다."
	elif not _has_f_interaction_binding():
		failure_message = "interact 입력에 F 키가 할당되지 않았습니다."
	else:
		var loot_caches: Array[Node] = []
		for child in extraction_game.get_node("World/Pickups").get_children():
			if child.has_method(&"request_loot"):
				loot_caches.append(child)
		if loot_caches.is_empty():
			failure_message = "랜덤 1회성 파밍 오브젝트가 생성되지 않았습니다."
		else:
			var spawned_kinds: Array[String] = []
			for loot_cache in loot_caches:
				spawned_kinds.append(String(loot_cache.get("placement_kind")))
			if (
				"wall_safe" not in spawned_kinds
				or "material_locker" not in spawned_kinds
				or "recovery_terminal" not in spawned_kinds
			):
				failure_message = "벽면 금고·자재함·회수 단말기 다양성이 생성되지 않았습니다."
			var cache := loot_caches[0] as Node2D
			extraction_player.global_position = cache.global_position
			if failure_message.is_empty() and not cache.call(&"request_loot", extraction_player):
				failure_message = "파밍 오브젝트에서 크레딧을 획득하지 못했습니다."
			elif cache.call(&"request_loot", extraction_player):
				failure_message = "1회성 파밍 오브젝트를 두 번 획득할 수 있습니다."
			elif int(credit_ledger.get("carried_credits")) <= 0:
				failure_message = "획득한 크레딧이 휴대 원장에 기록되지 않았습니다."

	if failure_message.is_empty():
		extraction_player.global_position = extraction_zone.global_position
		if extraction_zone.call(&"request_extraction", extraction_player):
			failure_message = "작전 목표 시간 전에 탈출할 수 있습니다."
		else:
			extraction_game.set(
				"elapsed_time", float(extraction_game.get("extraction_unlock_seconds"))
			)
			extraction_game.call(&"_process", 0.0)
		if failure_message.is_empty() and not extraction_zone.call(
			&"request_extraction", extraction_player
		):
			failure_message = "탈출 지점에서 상호작용 요청이 거부됐습니다."
		elif not bool(extraction_zone.call(&"get_snapshot").get(&"defense_active", false)):
			failure_message = "탈출 상호작용이 카운트다운 방어전을 시작하지 않았습니다."
		else:
			extraction_zone.call(
				&"advance",
				float(extraction_zone.get("defense_duration_seconds")) + 0.1
			)
		if failure_message.is_empty() and not bool(extraction_game.get("run_ended")):
			failure_message = "탈출 성공 후 작전이 종료되지 않았습니다."
		elif int(credit_ledger.get("secured_credits")) <= 0:
			failure_message = "탈출 성공 후 크레딧이 회수 처리되지 않았습니다."
		elif String(extraction_game.get_node("UI/GameOverOverlay/Center/Panel/Margin/Content/EndTitle").text) != "탈출 성공":
			failure_message = "탈출 성공 결과 화면이 표시되지 않았습니다."

	paused = false
	root.remove_child(extraction_game)
	extraction_game.free()
	if not failure_message.is_empty():
		_fail("탈출 흐름 실패: %s" % failure_message)
		return false
	return true


func _has_f_interaction_binding() -> bool:
	return _has_key_binding(&"interact", KEY_F)


func _has_key_binding(action_name: StringName, keycode: Key) -> bool:
	if not InputMap.has_action(action_name):
		return false
	for event in InputMap.action_get_events(action_name):
		if event is InputEventKey:
			var key_event := event as InputEventKey
			if key_event.keycode == keycode or key_event.physical_keycode == keycode:
				return true
	return false


func _process(_delta: float) -> bool:
	frame_count += 1

	if frame_count == 120:
		var player := get_first_node_in_group(&"player")
		var enemies := get_nodes_in_group(&"enemies")
		if player == null:
			return _fail("player 그룹이 비어 있습니다.")
		if enemies.is_empty():
			return _fail("적이 생성되지 않았습니다.")

		var progression = game_instance.get("progression_system")
		var weapon = game_instance.get("auto_weapon")
		var map_generator = game_instance.get("map_generator")
		var extraction_zone = game_instance.get("extraction_zone")
		var equipment = game_instance.get("equipment_system")
		var run_buffs = game_instance.get("run_buff_system")
		var growth_balance = game_instance.get("growth_balance_service")
		var meta_progression = game_instance.get("meta_progression_system")
		var upgrade_economy = game_instance.get("equipment_upgrade_service")
		var health_recovery = game_instance.get("health_recovery_system")
		var combat_skills = game_instance.get("combat_skill_system")
		var combat_skill_hud = game_instance.get("combat_skill_hud")
		if (
			progression == null
			or weapon == null
			or map_generator == null
			or extraction_zone == null
			or equipment == null
			or run_buffs == null
			or growth_balance == null
			or meta_progression == null
			or upgrade_economy == null
			or health_recovery == null
			or combat_skills == null
			or combat_skill_hud == null
		):
			return _fail("맵, 탈출, 장비, 전투 스킬 또는 성장 모듈이 설치되지 않았습니다.")
		if (
			int(combat_skills.call(&"get_snapshot").get(&"skill_count", 0)) != 3
			or int(combat_skill_hud.call(&"get_snapshot").get(&"slot_count", 0)) != 3
		):
			return _fail("전투 세션에 세 개 스킬과 쿨타임 HUD가 연결되지 않았습니다.")
		var small_config = load(MAP_CONFIG_PATH_PATTERN % "small")
		if map_generator.get("rooms").size() < int(small_config.get("minimum_rooms")):
			return _fail("소형 맵의 최소 방 수를 생성하지 못했습니다.")
		if map_generator.get("obstacle_cells").is_empty():
			return _fail("소형 맵에 방해물이 생성되지 않았습니다.")
		if not map_generator.call(&"is_walkable_world_position", player.global_position):
			return _fail("플레이어가 걸을 수 없는 위치에 생성됐습니다.")
		var health_label := game_instance.get_node(
			"UI/HUDMargin/Panel/Margin/Content/HealthRow/HealthLabel"
		) as Label
		var health_bar := game_instance.get_node(
			"UI/HUDMargin/Panel/Margin/Content/HealthRow/HealthBar"
		) as ProgressBar
		if "%" not in health_label.text or health_bar.custom_minimum_size.y < 26.0:
			return _fail("플레이어 체력 HUD의 수치 또는 가독성 스타일이 적용되지 않았습니다.")
		var equipment_label := game_instance.get_node(
			"UI/HUDMargin/Panel/Margin/Content/EquipmentLabel"
		) as Label
		if "스킬 2/3 활성" not in equipment_label.text or "방어 3" not in equipment_label.text:
			return _fail("장비 HUD에 무기·스킬·방어구 상태가 표시되지 않았습니다.")
		var balance = game_instance.get("weapon_balance_service")
		if balance == null or balance.call(&"get_snapshot").size() != 2:
			return _fail("무기 밸런스 모듈이 Game 조립 지점에 설치되지 않았습니다.")
		if (
			int((growth_balance.call(&"get_snapshot") as Dictionary).get(&"run_buff_count", 0)) != 5
			or equipment.get("upgrade_balance_provider") != growth_balance
			or run_buffs.get("catalog").call(&"get_buff", &"vitality") == null
		):
			return _fail("성장 밸런스가 장비와 내부 레벨업 모듈에 연결되지 않았습니다.")
		if not equipment.call(&"switch_active_weapon"):
			return _fail("런타임 Q 무기 교체 상태 전환이 실패했습니다.")

		enemies[0].call(&"take_damage", 9999.0)
		progression.call(&"gain_experience", 5)

	if frame_count == 121:
		var weapon = game_instance.get("auto_weapon")
		var snapshot: Dictionary = weapon.call(&"get_runtime_snapshot")
		var runtime_label := game_instance.get_node(
			"UI/HUDMargin/Panel/Margin/Content/WeaponRuntimeLabel"
		) as Label
		if snapshot.get(&"active_weapon_id", &"") != &"service_pistol":
			return _fail("무기 교체가 자동 공격 런타임에 반영되지 않았습니다.")
		if "고위력 관통" not in runtime_label.text or "확정 CSV" not in runtime_label.text:
			return _fail("무기 특색 또는 밸런스 출처가 HUD에 표시되지 않았습니다.")
		var selector = game_instance.get("run_buff_selector")
		var run_buffs = game_instance.get("run_buff_system")
		var offered_ids: PackedStringArray = run_buffs.get("offered_buff_ids")
		if selector == null or not selector.visible or offered_ids.is_empty():
			return _fail("런 레벨업 시 임시 버프 선택 화면이 열리지 않았습니다.")
		game_instance.call(&"_on_run_buff_selected", StringName(offered_ids[0]))
		if int(run_buffs.call(&"selected_buff_count")) != 1:
			return _fail("선택한 임시 버프가 런 상태에 기록되지 않았습니다.")

	if frame_count == 125:
		if int(game_instance.get("defeated_enemies")) < 1:
			return _fail("적 처치 이벤트가 Game에 전달되지 않았습니다.")
		if game_instance.get_node("World/Pickups").get_child_count() < 1:
			return _fail("경험치 픽업이 생성되지 않았습니다.")

		var progression = game_instance.get("progression_system")
		if int(progression.get("level")) < 2:
			return _fail("레벨 증가가 적용되지 않았습니다.")

		var player := get_first_node_in_group(&"player")
		player.call(&"take_damage", 9999.0)

	if frame_count == 130:
		var overlay := game_instance.get_node("UI/GameOverOverlay") as Control
		if not paused or not overlay.visible:
			return _fail("게임오버 상태가 적용되지 않았습니다.")
		var result_summary := String(game_instance.get_node(
			"UI/GameOverOverlay/Center/Panel/Margin/Content/GameOverSummary"
		).text)
		if "외부 성장" not in result_summary:
			return _fail("작전 종료 시 임시 버프가 외부 경험치로 정산되지 않았습니다.")

		paused = false
		print("SMOKE_TEST_OK electric_skill_effects electric_effect_budget cooldown_ui_10hz timer_stat_modifier combat_skills combat_skills_optional persistent_magnetic_field skill_1_blink skill_2_magnetic_field skill_3_speed_boost skill_cooldown_hud start_hub start_hub_optional hub_inventory_i hub_equipment_u_e hub_loadout_read_only hub_weapon_q_persisted single_room_hub operation_gate optimized_setup_ui combat_session hub_return run_setup balance_mode_ui tier_entry map map_scale screen_sized_rooms indoor_structures room_visibility corridor_visibility facing_vision room_triggered_encounter room_door_lock room_clear_reward room_encounters_optional run_pacing extraction_lock extraction_defense operation_settlement persistent_profile operation_contracts hub_economy warehouse consumable_loadout smart_targeting blueprint_crafting random_affixes penalty_modifiers conditional_ranking fog_of_war minimap minimap_full_map equipment loadout loadout_ui module_inventory_ui direct_item_selection weapon_tags skills_0_10 armor_stats inventory_grid item_footprints inventory_i equipment_u weapon_switch_q weapon_balance_csv weapon_balance_optional growth_balance_csv growth_balance_optional run_buff_sheet upgrade_sheet weapon_upgrade_spec armor_upgrade_spec module_upgrade_spec rifle_burst pistol_pierce parts module_cost module_upgrade part_upgrade upgrade_materials upgrade_credits modification_tag equipment_optional realistic_obstacles resource_recovery recovery_multiplier_range recovery_target_exact loot credits map_optional player responsive_movement dynamic_hack_slash_movement dash dash_exit_momentum health_recovery health_ui enemies reinforcement_population finite_spawn_budget armor status_bars pathfinding weapon target_provider run_experience run_buffs buff_choice meta_experience character_level weapon_level armor_level extraction_f game_over modular_progression")
		quit(0)
		return true

	return false


func _fail(message: String) -> bool:
	paused = false
	printerr("SMOKE_TEST_FAILED: %s" % message)
	quit(1)
	return true
