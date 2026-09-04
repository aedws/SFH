extends SceneTree

const GAME_SCENE := preload("res://game/scenes/game.tscn")
const CHARACTER_SCENE := preload(
	"res://game/features/character_selection/character_selection_service.tscn"
)
const CONFIG := preload(
	"res://game/features/character_selection/configs/default_character_selection.tres"
)


func _init() -> void:
	call_deferred(&"_run")


func _run() -> void:
	if not _verify_manifest_boundary():
		return
	var service = CHARACTER_SCENE.instantiate()
	root.add_child(service)
	await process_frame
	if not service.call(&"configure", CONFIG):
		_fail("확정 Character CSV를 구성하지 못했습니다.")
		return
	var snapshot: Dictionary = service.call(&"get_snapshot")
	if int(snapshot.get(&"count", 0)) != 3 or snapshot.get(&"character_id") != &"vanguard":
		_fail("기본 캐릭터 목록·선택이 올바르지 않습니다: %s" % snapshot)
		return
	service.call(&"select_character", &"runner")
	var context: Dictionary = service.call(&"get_investment_context")
	if int(context.get(&"additional_entry_cost", -1)) != 120 or not context.get(&"player_runtime_modifiers", {}).has(&"movement_speed"):
		_fail("질주자 비용·패시브 계약이 올바르지 않습니다: %s" % context)
		return
	root.remove_child(service)
	service.free()
	if not await _verify_player_visible_flow():
		return
	print("CHARACTER_SELECTION_OK characters_3 optional_module locked_live_csv briefing_quote passive_runtime entry_cost_once")
	quit(0)


func _verify_manifest_boundary() -> bool:
	var manifest: Resource = load("res://game/core/feature_manifest.tres").duplicate(true)
	if &"character_selection" not in manifest.call(&"enabled_module_ids"):
		return _fail("character_selection이 활성 모듈 목록에 없습니다.")
	manifest.set("character_selection_enabled", false)
	if &"character_selection" in manifest.call(&"enabled_module_ids"):
		return _fail("character_selection을 독립적으로 끌 수 없습니다.")
	manifest.set("character_selection_enabled", true)
	manifest.set("operation_contracts_enabled", false)
	if not manifest.call(&"validation_errors").has("character_selection은 operation_contracts 모듈이 필요합니다."):
		return _fail("캐릭터 선택의 계약 의존성이 검증되지 않습니다.")
	return true


func _verify_player_visible_flow() -> bool:
	var game = GAME_SCENE.instantiate()
	var features: Resource = game.get("features").duplicate(true)
	features.set("persistent_profile_storage_path", "user://sfh_character_profile.json")
	features.set("conditional_ranking_storage_path", "user://sfh_character_rankings.json")
	features.set("meta_progression_storage_path", "user://sfh_character_meta.json")
	features.set("key_mapping_storage_path", "user://sfh_character_keys.json")
	features.set("skill_binding_storage_path", "user://sfh_character_skills.json")
	features.set("presentation_settings_storage_path", "user://sfh_character_presentation.json")
	game.set("features", features)
	root.add_child(game)
	await process_frame
	await process_frame
	var profile = game.get("persistent_profile")
	var selection = game.get("character_selection_service")
	if profile == null or selection == null:
		return _fail("게임 조립에서 프로필 또는 캐릭터 선택 서비스를 찾지 못했습니다.")
	profile.call(&"reset_profile", true)
	selection.call(&"select_character", &"runner")
	await process_frame
	var button: Button = game.get("character_selection_button")
	if button == null or "질주자" not in button.text or "120 C" not in button.text:
		return _fail("브리핑이 캐릭터와 추가 비용을 플레이어에게 표시하지 않습니다.")
	var tier_config: Resource = load("res://game/features/map_generation/configs/small.tres")
	var base_quote: Dictionary = game.get("operation_contract_service").call(&"quote", tier_config, {}, {})
	var runner_quote: Dictionary = game.get("operation_contract_service").call(
		&"quote", tier_config, {}, selection.call(&"get_investment_context")
	)
	if int(runner_quote.get(&"entry_cost", 0)) - int(base_quote.get(&"entry_cost", 0)) != 120:
		return _fail("캐릭터 추가 비용이 계약 견적에 정확히 한 번 반영되지 않았습니다.")
	if not game.call(&"start_run", "small"):
		return _fail("질주자 선택 뒤 작전 진입에 실패했습니다.")
	await process_frame
	var player = game.get("player")
	var stats: Dictionary = player.call(&"get_runtime_stats") if player != null else {}
	# 장비 고정 옵션(+12)은 캐릭터 패시브와 별도 원천으로 먼저 합성되고,
	# 질주자 배율(×1.10)은 합성된 이동 속도에 적용됩니다: (300 + 12) × 1.10.
	if player == null or not is_equal_approx(float(stats.get(&"movement_speed", 0.0)), 343.2):
		return _fail("선택 캐릭터 패시브가 런타임 플레이어에 적용되지 않았습니다: %s" % stats)
	game.call(&"_return_to_start_hub")
	root.remove_child(game)
	game.free()
	for property_name in [
		"persistent_profile_storage_path", "conditional_ranking_storage_path",
		"meta_progression_storage_path", "key_mapping_storage_path",
		"skill_binding_storage_path", "presentation_settings_storage_path",
	]:
		var path := String(features.get(property_name))
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	return true


func _fail(message: String) -> bool:
	push_error(message)
	quit(1)
	return false
