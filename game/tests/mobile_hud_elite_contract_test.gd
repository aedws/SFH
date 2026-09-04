extends SceneTree

const SETTINGS_PATH := "user://sfh_mobile_hud_elite_settings.json"
const SETTINGS_SCENE := preload(
	"res://game/features/presentation_settings/presentation_settings_service.tscn"
)
const MOBILE_SCENE := preload(
	"res://game/features/mobile_controls/mobile_control_pad.tscn"
)
const PLAYER_SCENE := preload("res://game/features/player/player.tscn")
const LEDGER_SCENE := preload("res://game/features/credits/credit_ledger.tscn")
const SPAWNER_SCENE := preload("res://game/features/spawning/enemy_spawner.tscn")
const ELITE_SCENE := preload(
	"res://game/features/elite_pursuit/elite_pursuit_service.tscn"
)


func _init() -> void:
	call_deferred(&"_run")


func _run() -> void:
	_cleanup()
	if not _verify_manifest_boundaries():
		return
	if not await _verify_presentation_and_mobile():
		return
	if not await _verify_elite_pursuit():
		return
	var pursuit_contract := preload("res://game/tests/support/pursuit_boss_contract.gd").new()
	var pursuit_error: String = await pursuit_contract.verify(self)
	if not pursuit_error.is_empty():
		_fail(pursuit_error)
		return
	print("PURSUIT_BOSS_OK half_cost rounded_free_entry failed_spawn_retry locked_door_damage reclosed_door_damage boss_kill_once no_respawn")
	_cleanup()
	print("MOBILE_HUD_ELITE_OK optional_modules dependencies hud_bottom_left movable_anchor key_format mobile_semantic_pad threshold_entry_cost random_elite faster_stronger infinite_room_independent")
	quit(0)


func _verify_manifest_boundaries() -> bool:
	var manifest: Resource = load("res://game/core/feature_manifest.tres").duplicate(true)
	var enabled: Array = manifest.call(&"enabled_module_ids")
	for module_id in [&"presentation_settings", &"mobile_controls", &"elite_pursuit"]:
		if module_id not in enabled:
			return _fail("신규 기능이 FeatureManifest 모듈 목록에 없습니다: %s" % module_id)
	manifest.set("presentation_settings_enabled", false)
	manifest.set("mobile_controls_enabled", false)
	manifest.set("elite_pursuit_enabled", false)
	var disabled: Array = manifest.call(&"enabled_module_ids")
	for module_id in [&"presentation_settings", &"mobile_controls", &"elite_pursuit"]:
		if module_id in disabled:
			return _fail("신규 기능을 FeatureManifest에서 분리 비활성화할 수 없습니다: %s" % module_id)
	manifest.set("mobile_controls_enabled", true)
	var dependency_errors: PackedStringArray = manifest.call(&"validation_errors")
	if not dependency_errors.has("mobile_controls 모듈은 presentation_settings 모듈이 필요합니다."):
		return _fail("모바일 입력의 표현 설정 의존성이 검증되지 않습니다: %s" % dependency_errors)
	return true


func _verify_presentation_and_mobile() -> bool:
	root.content_scale_size = Vector2i.ZERO
	root.size = Vector2i(1280, 720)
	var settings = SETTINGS_SCENE.instantiate()
	var pad = MOBILE_SCENE.instantiate()
	root.add_child(settings)
	root.add_child(pad)
	await process_frame
	if not settings.call(&"configure", SETTINGS_PATH, false):
		return _fail("표현 설정 서비스를 구성하지 못했습니다.")
	if (
		not settings.call(&"set_hud_anchor", &"bottom_right")
		or not settings.call(&"set_key_label_format", &"boxed")
		or not settings.call(&"set_mobile_controls_mode", &"on")
	):
		return _fail("HUD 위치·키 포맷·모바일 표시 설정을 저장하지 못했습니다.")
	if not pad.call(&"configure", settings, true):
		return _fail("모바일 키패드를 표현 설정에 연결하지 못했습니다.")
	await process_frame
	var snapshot: Dictionary = pad.call(&"get_snapshot")
	if (
		not bool(snapshot.get(&"visible", false))
		or int(snapshot.get(&"action_count", 0)) != 16
		or not bool(snapshot.get(&"semantic_actions", false))
		or not bool(snapshot.get(&"multi_touch_ready", false))
		or float(snapshot.get(&"viewport_coverage_ratio", 1.0)) > 0.14
	):
		return _fail("모바일 키패드가 화면을 과도하게 가리지 않는 16개 semantic Action을 제공하지 않습니다: %s" % snapshot)
	pad.call(&"simulate_action", &"move_right", true)
	if not Input.is_action_pressed(&"move_right"):
		return _fail("모바일 이동 버튼이 기존 InputMap Action을 누르지 못했습니다.")
	pad.call(&"set_context_enabled", false)
	if Input.is_action_pressed(&"move_right") or bool(pad.call(&"get_snapshot").get(&"visible", true)):
		return _fail("모달 전환 시 모바일 입력을 해제하고 패드를 숨기지 못했습니다.")
	pad.call(&"set_context_enabled", true)
	settings.call(&"set_mobile_controls_mode", &"off")
	await process_frame
	if bool(pad.call(&"get_snapshot").get(&"visible", true)):
		return _fail("모바일 키패드 숨김 설정이 즉시 반영되지 않았습니다.")
	root.remove_child(pad)
	pad.free()
	root.remove_child(settings)
	settings.free()
	var restored = SETTINGS_SCENE.instantiate()
	root.add_child(restored)
	await process_frame
	if not restored.call(&"configure", SETTINGS_PATH, true):
		return _fail("저장된 표현 설정을 다시 불러오지 못했습니다.")
	var restored_snapshot: Dictionary = restored.call(&"get_snapshot")
	if (
		restored_snapshot.get(&"hud_anchor") != &"bottom_right"
		or restored_snapshot.get(&"key_label_format") != &"boxed"
		or restored_snapshot.get(&"mobile_controls_mode") != &"off"
		or restored.call(&"format_key_label", "Q") != "[Q]"
	):
		return _fail("HUD 위치·키 포맷·모바일 표시 설정이 영속되지 않았습니다: %s" % restored_snapshot)
	root.remove_child(restored)
	restored.free()
	return true


func _verify_elite_pursuit() -> bool:
	var player = PLAYER_SCENE.instantiate()
	var enemies := Node2D.new()
	var ledger = LEDGER_SCENE.instantiate()
	var spawner = SPAWNER_SCENE.instantiate()
	var elite_service = ELITE_SCENE.instantiate()
	root.add_child(player)
	root.add_child(enemies)
	root.add_child(ledger)
	root.add_child(spawner)
	root.add_child(elite_service)
	await process_frame
	var spawn_config: Resource = load(
		"res://game/features/spawning/configs/small.tres"
	)
	if not spawner.call(
		&"configure", player, enemies, true, null, true, true, spawn_config, {}, {}
	):
		return _fail("엘리트 검증용 적 생성기를 구성하지 못했습니다.")
	if not elite_service.call(
		&"configure",
		player,
		ledger,
		spawner,
		null,
		load("res://game/features/elite_pursuit/configs/default_elite_pursuit.tres"),
		100,
		10.0,
		460601
	):
		return _fail("엘리트 추격 서비스를 구성하지 못했습니다.")
	ledger.call(&"add_carried", 49)
	await process_frame
	if bool(elite_service.call(&"get_snapshot").get(&"triggered", false)):
		return _fail("투입비 회수 전 엘리트가 조기 생성됐습니다.")
	ledger.call(&"add_carried", 1)
	await process_frame
	var snapshot: Dictionary = elite_service.call(&"get_snapshot")
	var spawner_snapshot: Dictionary = spawner.call(&"get_snapshot")
	var targets: Array = spawner.call(&"get_active_targets")
	if (
		not bool(snapshot.get(&"triggered", false))
		or int(snapshot.get(&"threshold_credits", 0)) != 50
		or int(snapshot.get(&"active_elite_count", 0)) < 1
		or int(snapshot.get(&"active_elite_count", 0)) != 1
		or int(spawner_snapshot.get(&"total_spawned", -1)) != 0
		or int(spawner_snapshot.get(&"elite_pursuer_count", 0)) != targets.size()
	):
		return _fail("투입비 임계 엘리트 생성·일반 스폰 예산 분리 결과가 올바르지 않습니다: %s / %s" % [snapshot, spawner_snapshot])
	var elite: Node2D = targets[0]
	var player_speed := float(player.call(&"get_runtime_stats").get(&"movement_speed", 0.0))
	var targeting: Dictionary = elite.call(&"get_targeting_snapshot")
	if (
		float(elite.get("move_speed")) <= player_speed
		or float(elite.get("contact_damage")) <= 10.0
		or not bool(elite.get_meta(&"elite_pursuer", false))
		or StringName(elite.get_meta(&"room_encounter_id", &"invalid")) != &""
		or (int(elite.get("collision_mask")) & 16) != 0
		or not bool(targeting.get(&"ignore_room_barriers", false))
		or int(targeting.get(&"priority_rank", 0)) < 4
	):
		return _fail("엘리트가 플레이어보다 빠르고 강하며 방 문을 무시하는 전역 추격자가 아닙니다: %s" % targeting)
	for node in [elite_service, spawner, ledger, enemies, player]:
		if is_instance_valid(node):
			root.remove_child(node)
			node.free()
	return true


func _cleanup() -> void:
	Input.action_release(&"move_right")
	if FileAccess.file_exists(SETTINGS_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SETTINGS_PATH))


func _fail(message: String) -> bool:
	_cleanup()
	push_error(message)
	quit(1)
	return false
