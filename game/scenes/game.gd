extends Node2D

## 최상위 조립 지점입니다. 기능은 활성화됐을 때만 경로로 불러옵니다.

const PLAYER_SCENE_PATH := "res://game/features/player/player.tscn"
const MAP_GENERATOR_SCENE_PATH := "res://game/features/map_generation/map_generator.tscn"
const MAP_CONFIG_PATH_PATTERN := "res://game/features/map_generation/configs/%s.tres"
const FOG_OF_WAR_SCENE_PATH := "res://game/features/fog_of_war/fog_of_war.tscn"
const MINIMAP_SCENE_PATH := "res://game/features/minimap/minimap.tscn"
const EQUIPMENT_SCENE_PATH := "res://game/features/equipment/equipment_system.tscn"
const INVENTORY_SCENE_PATH := "res://game/features/inventory/grid_inventory.tscn"
const INVENTORY_WINDOW_SCENE_PATH := "res://game/features/inventory/inventory_window.tscn"
const EQUIPMENT_WORKBENCH_SCENE_PATH := (
	"res://game/features/equipment/equipment_workbench.tscn"
)
const EXTRACTION_SCENE_PATH := "res://game/features/extraction/extraction_zone.tscn"
const CREDIT_LEDGER_SCENE_PATH := "res://game/features/credits/credit_ledger.tscn"
const LOOT_SPAWNER_SCENE_PATH := "res://game/features/loot/loot_spawner.tscn"
const LOOT_CONFIG_PATH_PATTERN := "res://game/features/loot/configs/%s.tres"
const SPAWNER_SCENE_PATH := "res://game/features/spawning/enemy_spawner.tscn"
const WEAPON_SCENE_PATH := "res://game/features/weapons/auto_weapon.tscn"
const WEAPON_BALANCE_SCENE_PATH := (
	"res://game/features/weapon_balance/weapon_balance_service.tscn"
)
const PROGRESSION_SCENE_PATH := "res://game/features/experience/progression_system.tscn"
const HEALTH_RECOVERY_SCENE_PATH := (
	"res://game/features/health_recovery/health_recovery_system.tscn"
)
const RUN_BUFF_SCENE_PATH := "res://game/features/run_buffs/run_buff_system.tscn"
const RUN_BUFF_SELECTOR_SCENE_PATH := "res://game/features/run_buffs/run_buff_selector.tscn"
const META_PROGRESSION_SCENE_PATH := (
	"res://game/features/meta_progression/meta_progression_system.tscn"
)
const EQUIPMENT_UPGRADE_SCENE_PATH := (
	"res://game/features/equipment_upgrade/equipment_upgrade_service.tscn"
)
const MAP_GENERATOR_METHODS := [
	&"configure_obstacles",
	&"generate",
	&"get_player_spawn_position",
	&"get_extraction_position",
	&"get_enemy_spawn_position",
	&"get_loot_spawn_points",
	&"get_world_path",
]
const FOG_OF_WAR_METHODS := [&"configure", &"get_snapshot"]
const MINIMAP_PROVIDER_METHODS := [&"get_minimap_snapshot"]
const MINIMAP_METHODS := [&"configure"]
const EQUIPMENT_METHODS := [
	&"configure",
	&"get_active_skill_ids",
	&"get_inactive_skill_ids",
	&"get_stat_modifiers",
	&"get_summary",
	&"get_equipment_state",
	&"get_customization_snapshot",
	&"can_equip_definition",
	&"equip_definition",
	&"install_part",
	&"install_module",
	&"upgrade_module",
	&"level_up_equipment",
	&"grant_module_tag",
	&"get_active_weapon_slot",
	&"get_active_weapon",
	&"switch_active_weapon",
	&"set_active_weapon_slot",
	&"upgrade_part",
	&"get_upgrade_context",
	&"set_external_armor_level",
]
const WEAPON_BALANCE_METHODS := [
	&"configure",
	&"request_live_balance",
	&"load_csv_text",
	&"get_weapon_balance",
	&"get_snapshot",
]
const INVENTORY_METHODS := [
	&"configure",
	&"add_item",
	&"can_place",
	&"move_item",
	&"take_item",
	&"get_items_by_type",
	&"find_instance_ids_by_resource",
	&"consume_linked_resource",
	&"get_snapshot",
]
const PANEL_METHODS := [&"configure", &"open_panel", &"close_panel"]
const EXTRACTION_METHODS := [&"configure", &"request_extraction", &"set_locked"]
const CREDIT_LEDGER_METHODS := [
	&"add_carried",
	&"secure_carried",
	&"lose_carried",
	&"can_spend_carried",
	&"spend_carried",
	&"get_snapshot",
]
const LOOT_SPAWNER_METHODS := [&"configure"]
const RUN_BUFF_METHODS := [
	&"configure",
	&"prepare_choices",
	&"select_buff",
	&"selected_buff_count",
	&"get_meta_experience_breakdown",
	&"get_snapshot",
]
const META_PROGRESSION_METHODS := [
	&"configure",
	&"settle_run",
	&"apply_to_targets",
	&"get_snapshot",
	&"get_summary_line",
]
const EQUIPMENT_UPGRADE_METHODS := [&"configure", &"quote_upgrade", &"upgrade"]
const HEALTH_RECOVERY_METHODS := [&"configure", &"advance", &"get_snapshot"]
const MAP_TIER_IDS := ["small", "medium", "large"]

@export var features: FeatureManifest

@onready var actors_container: Node2D = $World/Actors
@onready var enemies_container: Node2D = $World/Enemies
@onready var projectiles_container: Node2D = $World/Projectiles
@onready var pickups_container: Node2D = $World/Pickups
@onready var module_container: Node = $Modules
@onready var world_container: Node2D = $World
@onready var ui_layer: CanvasLayer = $UI
@onready var hud_margin: Control = $UI/HUDMargin
@onready var status_label: Label = %StatusLabel
@onready var time_label: Label = %TimeLabel
@onready var level_label: Label = %LevelLabel
@onready var kills_label: Label = %KillsLabel
@onready var credit_label: Label = %CreditLabel
@onready var map_label: Label = %MapLabel
@onready var equipment_label: Label = %EquipmentLabel
@onready var weapon_runtime_label: Label = %WeaponRuntimeLabel
@onready var interaction_label: Label = %InteractionLabel
@onready var health_bar: ProgressBar = %HealthBar
@onready var health_label: Label = %HealthLabel
@onready var experience_bar: ProgressBar = %ExperienceBar
@onready var experience_label: Label = %ExperienceLabel
@onready var run_setup_overlay: Control = %RunSetupOverlay
@onready var balance_mode_section: Control = %BalanceModeSection
@onready var locked_balance_button: Button = %LockedBalanceButton
@onready var live_balance_button: Button = %LiveBalanceButton
@onready var balance_mode_description: Label = %BalanceModeDescription
@onready var small_map_button: Button = %SmallMapButton
@onready var medium_map_button: Button = %MediumMapButton
@onready var large_map_button: Button = %LargeMapButton
@onready var game_over_overlay: Control = %GameOverOverlay
@onready var end_title: Label = %EndTitle
@onready var game_over_summary: Label = %GameOverSummary
@onready var restart_button: Button = %RestartButton

var player
var map_generator
var fog_of_war
var minimap
var equipment_system
var inventory_system
var inventory_window
var equipment_workbench
var extraction_zone
var credit_ledger
var loot_spawner
var enemy_spawner
var auto_weapon
var weapon_balance_service
var progression_system
var health_recovery_system
var run_buff_system
var run_buff_selector
var meta_progression_system
var equipment_upgrade_service
var current_map_config: Resource
var selected_map_size: String = "small"
var selected_balance_source_mode: int = WeaponBalanceConfig.SourceMode.LOCKED_CSV
var elapsed_time: float = 0.0
var target_run_duration_seconds: float = 600.0
var extraction_unlock_seconds: float = 600.0
var extraction_unlocked: bool = false
var defeated_enemies: int = 0
var run_started: bool = false
var run_ended: bool = false
var pending_buff_levels: Array[int] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	restart_button.pressed.connect(_restart_run)
	locked_balance_button.pressed.connect(
		_select_balance_source_mode.bind(WeaponBalanceConfig.SourceMode.LOCKED_CSV)
	)
	live_balance_button.pressed.connect(
		_select_balance_source_mode.bind(WeaponBalanceConfig.SourceMode.LIVE_GOOGLE_SHEET)
	)
	small_map_button.pressed.connect(start_run.bind("small"))
	medium_map_button.pressed.connect(start_run.bind("medium"))
	large_map_button.pressed.connect(start_run.bind("large"))
	hud_margin.visible = false
	map_label.visible = false
	interaction_label.visible = false
	game_over_overlay.visible = false
	balance_mode_section.visible = false

	if features == null:
		_report_configuration_error("FeatureManifest가 지정되지 않았습니다.")
		return
	credit_label.visible = features.credits_enabled
	equipment_label.visible = features.equipment_enabled
	weapon_runtime_label.visible = features.weapons_enabled

	var configuration_errors := features.validation_errors()
	if not configuration_errors.is_empty():
		for message in configuration_errors:
			push_error(message)
		status_label.text = "설정 오류: %s" % " / ".join(configuration_errors)
		return

	_configure_tier_button(small_map_button, "small")
	_configure_tier_button(medium_map_button, "medium")
	_configure_tier_button(large_map_button, "large")
	_configure_balance_mode_selector()

	if features.run_setup_enabled:
		run_setup_overlay.visible = true
		status_label.text = "작전 규모를 선택하세요."
	else:
		run_setup_overlay.visible = false
		start_run(features.map_size)


func start_run(map_size: String) -> bool:
	if run_started:
		return false
	if map_size not in MAP_TIER_IDS:
		_report_configuration_error("지원하지 않는 맵 등급입니다: %s" % map_size)
		return false
	if not _tier_resources_are_available(map_size):
		return false

	selected_map_size = map_size
	run_started = true
	run_setup_overlay.visible = false
	hud_margin.visible = true
	map_label.visible = features.map_generation_enabled
	status_label.text = "%s 작전 생성 중..." % _selected_map_display_name()
	if not _assemble_game():
		run_started = false
		hud_margin.visible = false
		run_setup_overlay.visible = features.run_setup_enabled
		return false
	return true


func _assemble_game() -> bool:
	var player_spawn_position := Vector2.ZERO
	if features.player_enabled:
		if features.map_generation_enabled:
			map_generator = _instantiate_feature(MAP_GENERATOR_SCENE_PATH, world_container, &"GeneratedMap")
			if map_generator != null:
				if not _supports_map_generator(map_generator):
					_report_configuration_error("맵 모듈이 필수 공개 계약을 구현하지 않았습니다.")
					map_generator.queue_free()
					map_generator = null
				else:
					map_generator.call(&"configure_obstacles", features.map_obstacles_enabled)
					map_generator.connect(&"map_generated", Callable(self, &"_on_map_generated"))
					var map_config_path := MAP_CONFIG_PATH_PATTERN % selected_map_size
					if ResourceLoader.exists(map_config_path):
						current_map_config = load(map_config_path)
						target_run_duration_seconds = float(
							current_map_config.get("target_run_duration_seconds")
						)
						extraction_unlock_seconds = float(
							current_map_config.get("extraction_unlock_seconds")
						)
						map_generator.call(&"generate", current_map_config, features.map_seed)
						player_spawn_position = map_generator.call(&"get_player_spawn_position")
					else:
						_report_configuration_error("맵 설정을 찾을 수 없습니다: %s" % map_config_path)

		player = _instantiate_feature(PLAYER_SCENE_PATH, actors_container, &"Player")
	if player == null:
		_report_configuration_error("플레이어 모듈을 설치하지 못했습니다.")
		return false
	if features.map_generation_enabled and map_generator == null:
		_report_configuration_error("맵 모듈을 설치하지 못했습니다.")
		return false

	player.global_position = player_spawn_position
	player.call(&"configure_damage", features.damage_enabled)
	player.connect(&"health_changed", Callable(self, &"_on_player_health_changed"))
	player.connect(&"died", Callable(self, &"_on_player_died"))
	_on_player_health_changed(float(player.get("current_health")), float(player.get("max_health")))
	if features.fog_of_war_enabled and not _install_fog_of_war():
		return false
	if features.equipment_enabled and not _install_equipment():
		return false
	if features.health_recovery_enabled and not _install_health_recovery():
		return false
	if features.inventory_enabled and not _install_inventory():
		return false

	if features.credits_enabled:
		_install_credit_ledger()
	if features.equipment_upgrade_economy_enabled and not _install_equipment_upgrade_service():
		return false
	if features.equipment_customization_enabled and not _install_equipment_workbench():
		return false

	if features.extraction_enabled and map_generator != null:
		_install_extraction_zone()
	if features.minimap_enabled and map_generator != null:
		_install_minimap()
	if (
		features.loot_enabled
		and map_generator != null
		and credit_ledger != null
		and current_map_config != null
	):
		_install_loot_spawner()

	if features.experience_enabled:
		progression_system = _instantiate_feature(PROGRESSION_SCENE_PATH, module_container, &"ProgressionSystem")
		if progression_system != null:
			progression_system.connect(&"progress_changed", Callable(self, &"_on_progress_changed"))
			progression_system.connect(&"level_increased", Callable(self, &"_on_level_increased"))
			progression_system.call(&"configure", pickups_container, features.leveling_enabled)
			_on_progress_changed(1, 0, 5)

	if features.weapons_enabled:
		if features.weapon_balance_enabled and not _install_weapon_balance():
			return false
		auto_weapon = _instantiate_feature(WEAPON_SCENE_PATH, player, &"AutoWeapon")
		if auto_weapon != null:
			auto_weapon.connect(
				&"weapon_runtime_changed", Callable(self, &"_on_weapon_runtime_changed")
			)
			auto_weapon.call(
				&"configure", projectiles_container, equipment_system, weapon_balance_service
			)

	if features.run_buffs_enabled and not _install_run_buffs():
		return false
	if features.meta_progression_enabled and not _install_meta_progression():
		return false
	if features.enemies_enabled and features.spawning_enabled:
		enemy_spawner = _instantiate_feature(SPAWNER_SCENE_PATH, module_container, &"EnemySpawner")
		if enemy_spawner != null:
			enemy_spawner.connect(&"enemy_spawned", Callable(self, &"_on_enemy_spawned"))
			enemy_spawner.call(
				&"configure",
				player,
				enemies_container,
				features.damage_enabled,
				map_generator,
				features.enemy_armor_enabled,
				features.enemy_status_ui_enabled
			)

	status_label.text = (
		"작전 진행 중 · Shift/Space 회피 · Q 무기 · F 상호작용 · I 가방 · U 장비"
	)
	_update_run_time_hud()
	return true


func _install_health_recovery() -> bool:
	if not ResourceLoader.exists(features.health_recovery_config_path):
		_report_configuration_error("부분 체력 회복 설정을 찾을 수 없습니다.")
		return false
	health_recovery_system = _instantiate_feature(
		HEALTH_RECOVERY_SCENE_PATH, module_container, &"HealthRecovery"
	)
	if not _supports_methods(health_recovery_system, HEALTH_RECOVERY_METHODS):
		_report_configuration_error("부분 체력 회복 모듈의 공개 계약이 올바르지 않습니다.")
		return false
	if not health_recovery_system.call(
		&"configure", player, load(features.health_recovery_config_path)
	):
		_report_configuration_error("부분 체력 회복 모듈을 구성하지 못했습니다.")
		return false
	return true


func _install_run_buffs() -> bool:
	if not ResourceLoader.exists(features.run_buff_catalog_path):
		_report_configuration_error("런 버프 카탈로그를 찾을 수 없습니다.")
		return false
	run_buff_system = _instantiate_feature(RUN_BUFF_SCENE_PATH, module_container, &"RunBuffs")
	if not _supports_methods(run_buff_system, RUN_BUFF_METHODS):
		_report_configuration_error("런 버프 모듈의 공개 계약이 올바르지 않습니다.")
		return false
	if not run_buff_system.call(
		&"configure", player, auto_weapon, load(features.run_buff_catalog_path)
	):
		_report_configuration_error("런 버프 모듈을 구성하지 못했습니다.")
		return false
	run_buff_selector = _instantiate_feature(
		RUN_BUFF_SELECTOR_SCENE_PATH, ui_layer, &"RunBuffSelector"
	)
	if run_buff_selector == null or not run_buff_selector.has_signal(&"buff_selected"):
		_report_configuration_error("런 버프 선택 UI를 구성하지 못했습니다.")
		return false
	run_buff_selector.connect(&"buff_selected", Callable(self, &"_on_run_buff_selected"))
	return true


func _install_meta_progression() -> bool:
	meta_progression_system = _instantiate_feature(
		META_PROGRESSION_SCENE_PATH, module_container, &"MetaProgression"
	)
	if not _supports_methods(meta_progression_system, META_PROGRESSION_METHODS):
		_report_configuration_error("외부 성장 모듈의 공개 계약이 올바르지 않습니다.")
		return false
	var persistence_enabled := not OS.get_cmdline_args().has("--script")
	if not meta_progression_system.call(
		&"configure", features.meta_progression_storage_path, persistence_enabled
	):
		return false
	meta_progression_system.call(
		&"apply_to_targets", player, auto_weapon, equipment_system
	)
	return true


func _install_equipment_upgrade_service() -> bool:
	if (
		equipment_system == null
		or inventory_system == null
		or credit_ledger == null
		or not ResourceLoader.exists(features.equipment_upgrade_policy_path)
	):
		_report_configuration_error("장비 강화 경제 모듈의 의존성이 준비되지 않았습니다.")
		return false
	equipment_upgrade_service = _instantiate_feature(
		EQUIPMENT_UPGRADE_SCENE_PATH, module_container, &"EquipmentUpgradeEconomy"
	)
	if not _supports_methods(equipment_upgrade_service, EQUIPMENT_UPGRADE_METHODS):
		_report_configuration_error("장비 강화 경제 모듈의 공개 계약이 올바르지 않습니다.")
		return false
	return bool(equipment_upgrade_service.call(
		&"configure",
		equipment_system,
		inventory_system,
		credit_ledger,
		load(features.equipment_upgrade_policy_path)
	))


func _install_weapon_balance() -> bool:
	if not ResourceLoader.exists(features.weapon_balance_config_path):
		_report_configuration_error(
			"무기 밸런스 설정을 찾을 수 없습니다: %s" % features.weapon_balance_config_path
		)
		return false
	weapon_balance_service = _instantiate_feature(
		WEAPON_BALANCE_SCENE_PATH, module_container, &"WeaponBalance"
	)
	if not _supports_weapon_balance(weapon_balance_service):
		_report_configuration_error("무기 밸런스 모듈의 공개 계약이 올바르지 않습니다.")
		return false
	weapon_balance_service.connect(&"balance_error", Callable(self, &"_on_weapon_balance_error"))
	var balance_config := load(features.weapon_balance_config_path) as WeaponBalanceConfig
	if balance_config == null:
		_report_configuration_error("무기 밸런스 설정 Resource 형식이 올바르지 않습니다.")
		return false
	balance_config = balance_config.duplicate(true) as WeaponBalanceConfig
	balance_config.source_mode = selected_balance_source_mode
	if not weapon_balance_service.call(&"configure", balance_config):
		_report_configuration_error("무기 밸런스 데이터를 불러오지 못했습니다.")
		return false
	return true


func _configure_balance_mode_selector() -> void:
	balance_mode_section.visible = features.weapon_balance_enabled
	if not balance_mode_section.visible:
		return
	var balance_config := load(features.weapon_balance_config_path) as WeaponBalanceConfig
	if balance_config == null:
		live_balance_button.disabled = true
		_select_balance_source_mode(WeaponBalanceConfig.SourceMode.LOCKED_CSV)
		balance_mode_description.text = "밸런스 설정을 읽을 수 없어 확정 CSV만 선택할 수 있습니다."
		return
	live_balance_button.disabled = balance_config.live_csv_url.is_empty()
	var initial_mode := int(balance_config.source_mode)
	if (
		initial_mode == WeaponBalanceConfig.SourceMode.LIVE_GOOGLE_SHEET
		and live_balance_button.disabled
	):
		initial_mode = WeaponBalanceConfig.SourceMode.LOCKED_CSV
	_select_balance_source_mode(initial_mode)


func _select_balance_source_mode(source_mode: int) -> void:
	if (
		source_mode == WeaponBalanceConfig.SourceMode.LIVE_GOOGLE_SHEET
		and live_balance_button.disabled
	):
		return
	selected_balance_source_mode = source_mode
	locked_balance_button.button_pressed = (
		source_mode == WeaponBalanceConfig.SourceMode.LOCKED_CSV
	)
	live_balance_button.button_pressed = (
		source_mode == WeaponBalanceConfig.SourceMode.LIVE_GOOGLE_SHEET
	)
	if source_mode == WeaponBalanceConfig.SourceMode.LIVE_GOOGLE_SHEET:
		balance_mode_description.text = (
			"Google Sheet를 기본 3초마다 다시 읽습니다. 네트워크 실패 시 확정 CSV로 복구합니다."
		)
	else:
		balance_mode_description.text = (
			"저장소에 확정된 CSV를 사용합니다. 배포와 일반 플레이에 권장됩니다."
		)


func _install_equipment() -> bool:
	if not ResourceLoader.exists(features.equipment_loadout_path):
		_report_configuration_error("장비 로드아웃을 찾을 수 없습니다: %s" % features.equipment_loadout_path)
		return false
	var loadout := load(features.equipment_loadout_path)
	equipment_system = _instantiate_feature(EQUIPMENT_SCENE_PATH, module_container, &"CharacterEquipment")
	if equipment_system == null:
		return false
	if not _supports_equipment(equipment_system):
		_report_configuration_error("장비 모듈이 필수 공개 계약을 구현하지 않았습니다.")
		equipment_system.queue_free()
		equipment_system = null
		return false
	equipment_system.connect(&"equipment_changed", Callable(self, &"_on_equipment_changed"))
	var configured := bool(equipment_system.call(
		&"configure",
		loadout,
		player,
		features.equipment_weapons_enabled,
		features.equipment_skills_enabled,
		features.equipment_armor_enabled
	))
	if not configured:
		_report_configuration_error("장비 로드아웃 조립에 실패했습니다.")
		return false
	return true


func _install_inventory() -> bool:
	if not ResourceLoader.exists(features.inventory_catalog_path):
		_report_configuration_error("인벤토리 카탈로그를 찾을 수 없습니다: %s" % features.inventory_catalog_path)
		return false
	inventory_system = _instantiate_feature(INVENTORY_SCENE_PATH, module_container, &"GridInventory")
	if inventory_system == null or not _supports_inventory(inventory_system):
		_report_configuration_error("가방 인벤토리 모듈의 공개 계약이 올바르지 않습니다.")
		return false
	if not inventory_system.call(&"configure", load(features.inventory_catalog_path)):
		_report_configuration_error("초기 가방 아이템을 배치하지 못했습니다.")
		return false
	inventory_window = _instantiate_feature(
		INVENTORY_WINDOW_SCENE_PATH, ui_layer, &"GridInventoryWindow"
	)
	if inventory_window == null or not _supports_panel(inventory_window):
		_report_configuration_error("가방 UI 모듈의 공개 계약이 올바르지 않습니다.")
		return false
	inventory_window.call(&"configure", inventory_system)
	return true


func _install_equipment_workbench() -> bool:
	if equipment_system == null or inventory_system == null:
		_report_configuration_error("장비 개조 UI에는 장비와 가방 모듈이 모두 필요합니다.")
		return false
	equipment_workbench = _instantiate_feature(
		EQUIPMENT_WORKBENCH_SCENE_PATH, ui_layer, &"EquipmentWorkbench"
	)
	if equipment_workbench == null or not _supports_panel(equipment_workbench):
		_report_configuration_error("장비 개조 UI 모듈의 공개 계약이 올바르지 않습니다.")
		return false
	if not equipment_workbench.call(
		&"configure", equipment_system, inventory_system, equipment_upgrade_service
	):
		_report_configuration_error("장비 개조 UI를 연결하지 못했습니다.")
		return false
	return true


func _install_minimap() -> void:
	if not _supports_minimap_provider(map_generator):
		_report_configuration_error("맵 모듈이 미니맵 스냅샷 계약을 구현하지 않았습니다.")
		return
	minimap = _instantiate_feature(MINIMAP_SCENE_PATH, ui_layer, &"TacticalMinimap")
	if minimap == null:
		return
	if not _supports_minimap(minimap):
		_report_configuration_error("미니맵 모듈이 필수 공개 계약을 구현하지 않았습니다.")
		minimap.queue_free()
		minimap = null
		return
	minimap.call(
		&"configure",
		map_generator.call(&"get_minimap_snapshot"),
		player,
		_selected_map_display_name()
	)


func _install_extraction_zone() -> void:
	extraction_zone = _instantiate_feature(EXTRACTION_SCENE_PATH, world_container, &"ExtractionZone")
	if extraction_zone == null:
		return
	if not _supports_extraction_zone(extraction_zone):
		_report_configuration_error("탈출 모듈이 필수 공개 계약을 구현하지 않았습니다.")
		extraction_zone.queue_free()
		extraction_zone = null
		return

	extraction_zone.connect(&"extraction_completed", Callable(self, &"_on_extraction_completed"))
	extraction_zone.connect(
		&"interaction_availability_changed",
		Callable(self, &"_on_interaction_availability_changed")
	)
	extraction_zone.call(&"configure", map_generator.call(&"get_extraction_position"))
	extraction_unlocked = extraction_unlock_seconds <= 0.0
	extraction_zone.call(
		&"set_locked",
		not extraction_unlocked,
		"탈출 신호 대기 · HUD의 개방 시간을 확인하세요"
	)


func _install_credit_ledger() -> void:
	credit_ledger = _instantiate_feature(CREDIT_LEDGER_SCENE_PATH, module_container, &"CreditLedger")
	if credit_ledger == null:
		return
	if not _supports_credit_ledger(credit_ledger):
		_report_configuration_error("크레딧 원장 모듈이 필수 공개 계약을 구현하지 않았습니다.")
		credit_ledger.queue_free()
		credit_ledger = null
		return
	credit_ledger.connect(&"credits_changed", Callable(self, &"_on_credits_changed"))
	_on_credits_changed(0, 0)


func _install_loot_spawner() -> void:
	var loot_config_path := LOOT_CONFIG_PATH_PATTERN % selected_map_size
	if not ResourceLoader.exists(loot_config_path):
		_report_configuration_error("파밍 설정을 찾을 수 없습니다: %s" % loot_config_path)
		return
	var loot_config := load(loot_config_path)
	loot_spawner = _instantiate_feature(LOOT_SPAWNER_SCENE_PATH, module_container, &"LootSpawner")
	if loot_spawner == null:
		return
	if not _supports_loot_spawner(loot_spawner):
		_report_configuration_error("파밍 모듈이 필수 공개 계약을 구현하지 않았습니다.")
		loot_spawner.queue_free()
		loot_spawner = null
		return
	loot_spawner.connect(&"credits_looted", Callable(self, &"_on_credits_looted"))
	loot_spawner.connect(
		&"interaction_availability_changed",
		Callable(self, &"_on_interaction_availability_changed")
	)
	loot_spawner.call(&"configure", map_generator, pickups_container, loot_config)


func _configure_tier_button(button: Button, tier_id: String) -> void:
	var config_path := MAP_CONFIG_PATH_PATTERN % tier_id
	if not ResourceLoader.exists(config_path):
		button.disabled = true
		button.text = "%s 설정 없음" % tier_id
		return

	var config = load(config_path)
	if config == null or not config.has_method(&"is_valid") or not config.call(&"is_valid"):
		button.disabled = true
		button.text = "%s 설정 오류" % tier_id
		return
	if features.loot_enabled and not ResourceLoader.exists(LOOT_CONFIG_PATH_PATTERN % tier_id):
		button.disabled = true
		button.text = "%s 파밍 설정 없음" % config.get("display_name")
		return
	button.text = "%s 작전 · 목표 %d분\n투자 %d · 방 %d~%d" % [
		config.get("display_name"),
		roundi(float(config.get("target_run_duration_seconds")) / 60.0),
		config.get("entry_cost"),
		config.get("minimum_rooms"),
		config.get("maximum_rooms"),
	]


func _tier_resources_are_available(tier_id: String) -> bool:
	if features.map_generation_enabled:
		var map_config_path := MAP_CONFIG_PATH_PATTERN % tier_id
		if not ResourceLoader.exists(map_config_path):
			_report_configuration_error("맵 설정을 찾을 수 없습니다: %s" % map_config_path)
			return false
		var map_config = load(map_config_path)
		if (
			map_config == null
			or not map_config.has_method(&"is_valid")
			or not map_config.call(&"is_valid")
		):
			_report_configuration_error("유효하지 않은 맵 설정입니다: %s" % map_config_path)
			return false
	if features.loot_enabled:
		var loot_config_path := LOOT_CONFIG_PATH_PATTERN % tier_id
		if not ResourceLoader.exists(loot_config_path):
			_report_configuration_error("파밍 설정을 찾을 수 없습니다: %s" % loot_config_path)
			return false
	return true


func _process(delta: float) -> void:
	if not run_started or run_ended or get_tree().paused:
		return

	elapsed_time += delta
	if (
		extraction_zone != null
		and not extraction_unlocked
		and elapsed_time >= extraction_unlock_seconds
	):
		extraction_unlocked = true
		extraction_zone.call(&"set_locked", false)
		status_label.text = "탈출 신호 활성 · 탈출 지점에서 F"
	_update_run_time_hud()


func _update_run_time_hud() -> void:
	var extraction_state := "탈출 비활성"
	if features.extraction_enabled:
		extraction_state = (
			"탈출 가능"
			if extraction_unlocked
			else "탈출 %s" % _format_time(
				maxf(0.0, extraction_unlock_seconds - elapsed_time)
			)
		)
	time_label.text = "생존 %s / 목표 %s · %s" % [
		_format_time(elapsed_time),
		_format_time(target_run_duration_seconds),
		extraction_state,
	]


func _unhandled_input(event: InputEvent) -> void:
	if not run_ended or not event is InputEventKey:
		return

	var key_event := event as InputEventKey
	if key_event.pressed and not key_event.echo:
		if key_event.keycode == KEY_ENTER or key_event.keycode == KEY_SPACE:
			_restart_run()


func _instantiate_feature(path: String, parent: Node, display_name: StringName) -> Node:
	if not ResourceLoader.exists(path):
		_report_configuration_error("기능 장면을 찾을 수 없습니다: %s" % path)
		return null

	var resource := load(path)
	if not resource is PackedScene:
		_report_configuration_error("PackedScene이 아닙니다: %s" % path)
		return null

	var instance := (resource as PackedScene).instantiate()
	instance.name = String(display_name)
	parent.add_child(instance)
	return instance


func _supports_map_generator(candidate: Node) -> bool:
	if not is_instance_valid(candidate) or not candidate.has_signal(&"map_generated"):
		return false

	for method_name in MAP_GENERATOR_METHODS:
		if not candidate.has_method(method_name):
			return false

	return true


func _install_fog_of_war() -> bool:
	fog_of_war = _instantiate_feature(FOG_OF_WAR_SCENE_PATH, self, &"BattlefieldFogOfWar")
	if not _supports_methods(fog_of_war, FOG_OF_WAR_METHODS):
		_report_configuration_error("전장의 안개 모듈의 공개 계약이 올바르지 않습니다.")
		return false
	if not fog_of_war.call(&"configure", player):
		_report_configuration_error("전장의 안개가 플레이어를 추적하지 못했습니다.")
		return false
	return true


func _supports_minimap_provider(candidate: Node) -> bool:
	if not is_instance_valid(candidate):
		return false
	for method_name in MINIMAP_PROVIDER_METHODS:
		if not candidate.has_method(method_name):
			return false
	return true


func _supports_minimap(candidate: Node) -> bool:
	if not is_instance_valid(candidate):
		return false
	for method_name in MINIMAP_METHODS:
		if not candidate.has_method(method_name):
			return false
	return true


func _supports_equipment(candidate: Node) -> bool:
	if not is_instance_valid(candidate) or not candidate.has_signal(&"equipment_changed"):
		return false
	for method_name in EQUIPMENT_METHODS:
		if not candidate.has_method(method_name):
			return false
	return true


func _supports_weapon_balance(candidate: Node) -> bool:
	if (
		not is_instance_valid(candidate)
		or not candidate.has_signal(&"balance_updated")
		or not candidate.has_signal(&"balance_error")
	):
		return false
	for method_name in WEAPON_BALANCE_METHODS:
		if not candidate.has_method(method_name):
			return false
	return true


func _supports_inventory(candidate: Node) -> bool:
	if not is_instance_valid(candidate) or not candidate.has_signal(&"inventory_changed"):
		return false
	for method_name in INVENTORY_METHODS:
		if not candidate.has_method(method_name):
			return false
	return true


func _supports_panel(candidate: Node) -> bool:
	if not is_instance_valid(candidate):
		return false
	for method_name in PANEL_METHODS:
		if not candidate.has_method(method_name):
			return false
	return true


func _supports_extraction_zone(candidate: Node) -> bool:
	if (
		not is_instance_valid(candidate)
		or not candidate.has_signal(&"extraction_completed")
		or not candidate.has_signal(&"interaction_availability_changed")
	):
		return false

	for method_name in EXTRACTION_METHODS:
		if not candidate.has_method(method_name):
			return false

	return true


func _supports_credit_ledger(candidate: Node) -> bool:
	if not is_instance_valid(candidate) or not candidate.has_signal(&"credits_changed"):
		return false
	for method_name in CREDIT_LEDGER_METHODS:
		if not candidate.has_method(method_name):
			return false
	return true


func _supports_loot_spawner(candidate: Node) -> bool:
	if (
		not is_instance_valid(candidate)
		or not candidate.has_signal(&"credits_looted")
		or not candidate.has_signal(&"interaction_availability_changed")
	):
		return false
	for method_name in LOOT_SPAWNER_METHODS:
		if not candidate.has_method(method_name):
			return false
	return true


func _supports_methods(candidate: Node, methods: Array) -> bool:
	if not is_instance_valid(candidate):
		return false
	for method_name in methods:
		if not candidate.has_method(method_name):
			return false
	return true


func _on_enemy_spawned(enemy: Node) -> void:
	if enemy.has_signal(&"defeated"):
		enemy.connect(&"defeated", Callable(self, &"_on_enemy_defeated"))


func _on_map_generated(
	display_name: String,
	_entry_cost: int,
	room_count: int,
	maximum_rooms: int,
	_used_seed: int
) -> void:
	map_label.text = "%s · 방 %d/%d" % [
		display_name,
		room_count,
		maximum_rooms,
	]


func _on_interaction_availability_changed(available: bool, prompt: String) -> void:
	interaction_label.text = prompt
	interaction_label.visible = available and not run_ended


func _on_credits_looted(amount: int, _world_position: Vector2) -> void:
	if credit_ledger != null:
		credit_ledger.call(&"add_carried", amount)


func _on_credits_changed(carried: int, _secured: int) -> void:
	credit_label.text = "휴대 크레딧 %d" % carried


func _on_equipment_changed(summary: Dictionary) -> void:
	var defense_value := 0.0
	if player != null and player.has_method(&"get_runtime_stats"):
		defense_value = float(player.call(&"get_runtime_stats").get(&"defense", 0.0))
	var active_slot := String(summary.get(&"active_weapon_slot", &"main"))
	var main_marker := "▶" if active_slot == "main" else " "
	var secondary_marker := "▶" if active_slot == "secondary" else " "
	equipment_label.text = "%sM %s [%s] · %sS %s [%s]\n스킬 %d/%d 활성 · 방어구 %d · 방어 %.0f" % [
		main_marker,
		summary.get(&"main_weapon_name", "없음"),
		summary.get(&"main_weapon_tags", "-"),
		secondary_marker,
		summary.get(&"secondary_weapon_name", "없음"),
		summary.get(&"secondary_weapon_tags", "-"),
		int(summary.get(&"active_skill_count", 0)),
		int(summary.get(&"equipped_skill_count", 0)),
		int(summary.get(&"armor_count", 0)),
		defense_value,
	]


func _on_weapon_runtime_changed(snapshot: Dictionary) -> void:
	var trait_labels := {
		&"steady_burst": "안정 3점사",
		&"heavy_piercing": "고위력 관통",
	}
	var trait_id: StringName = snapshot.get(&"trait_id", &"")
	weapon_runtime_label.text = "Q 현재 %s · %s · 피해 %.1f · 사거리 %.0f · %s" % [
		snapshot.get(&"display_name", "무기"),
		trait_labels.get(trait_id, String(trait_id)),
		float(snapshot.get(&"damage", 0.0)) + float(snapshot.get(&"level_damage_bonus", 0.0)),
		float(snapshot.get(&"target_range_px", 0.0)),
		snapshot.get(&"source_label", "내장 기본값"),
	]


func _on_weapon_balance_error(message: String) -> void:
	push_warning(message)


func _on_extraction_completed(_actor: Node2D) -> void:
	var recovered_credits := 0
	if credit_ledger != null:
		recovered_credits = int(credit_ledger.call(&"secure_carried"))
	_finish_run(
		"탈출 성공",
		"%s 작전 · 생존 %s · 처치 %d · 회수 %d 크레딧" % [
			_selected_map_display_name(),
			_format_time(elapsed_time),
			defeated_enemies,
			recovered_credits,
		]
	)


func _on_enemy_defeated(reward: int, world_position: Vector2) -> void:
	defeated_enemies += 1
	kills_label.text = "처치 %d" % defeated_enemies

	if progression_system != null:
		progression_system.call(&"spawn_pickup", world_position, reward)


func _on_player_health_changed(current: float, maximum: float) -> void:
	health_bar.max_value = maximum
	health_bar.value = current
	var ratio := current / maximum if maximum > 0.0 else 0.0
	health_label.text = "%d / %d · %d%%" % [
		ceili(current),
		ceili(maximum),
		roundi(ratio * 100.0),
	]
	var fill_style := health_bar.get_theme_stylebox(&"fill")
	if fill_style is StyleBoxFlat:
		var fill := fill_style as StyleBoxFlat
		if ratio > 0.6:
			fill.bg_color = Color(0.18, 0.82, 0.55, 1)
			health_label.modulate = Color(0.76, 0.97, 0.86, 1)
		elif ratio > 0.3:
			fill.bg_color = Color(1.0, 0.66, 0.18, 1)
			health_label.modulate = Color(1.0, 0.82, 0.48, 1)
		else:
			fill.bg_color = Color(0.95, 0.22, 0.2, 1)
			health_label.modulate = Color(1.0, 0.5, 0.48, 1)


func _on_progress_changed(level: int, current: int, required: int) -> void:
	level_label.text = "레벨 %d" % level
	experience_bar.max_value = required
	experience_bar.value = current
	experience_label.text = "%d / %d" % [current, required]


func _on_level_increased(new_level: int) -> void:
	if run_buff_system == null or run_buff_selector == null:
		if auto_weapon != null:
			auto_weapon.call(&"apply_level", new_level)
		if player != null:
			player.call(&"heal", 12.0)
		return
	pending_buff_levels.append(new_level)
	_show_next_run_buff_choice()


func _show_next_run_buff_choice() -> void:
	if pending_buff_levels.is_empty() or run_ended or run_buff_selector.visible:
		return
	var run_level: int = pending_buff_levels.pop_front()
	var choices: Array[Dictionary] = run_buff_system.call(&"prepare_choices", run_level, 3)
	if choices.is_empty():
		_show_next_run_buff_choice()
		return
	run_buff_selector.call(&"open_choices", run_level, choices)


func _on_run_buff_selected(buff_id: StringName) -> void:
	if run_buff_system != null and run_buff_system.call(&"select_buff", buff_id):
		var snapshot: Dictionary = run_buff_system.call(&"get_snapshot")
		status_label.text = "임시 버프 %d개 활성 · 작전 종료 시 외부 경험치 전환" % int(
			snapshot[&"selected_buff_count"]
		)
	_show_next_run_buff_choice()


func _on_player_died() -> void:
	if not features.game_over_enabled:
		return

	var lost_credits := 0
	if credit_ledger != null:
		lost_credits = int(credit_ledger.call(&"lose_carried"))
	_finish_run(
		"작전 실패",
		"생존 %s · 처치 %d · 분실 %d 크레딧" % [
			_format_time(elapsed_time),
			defeated_enemies,
			lost_credits,
		]
	)


func _finish_run(title: String, summary: String) -> void:
	if run_ended:
		return
	run_ended = true
	if run_buff_selector != null and run_buff_selector.visible:
		run_buff_selector.call(&"close_panel")
	pending_buff_levels.clear()
	var final_summary := summary
	if meta_progression_system != null and run_buff_system != null:
		var settlement: Dictionary = meta_progression_system.call(
			&"settle_run", run_buff_system.call(&"get_meta_experience_breakdown")
		)
		meta_progression_system.call(
			&"apply_to_targets", player, auto_weapon, equipment_system
		)
		final_summary += "\n" + String(meta_progression_system.call(
			&"get_summary_line", settlement[&"gained_experience"]
		))
	interaction_label.visible = false
	end_title.text = title
	game_over_summary.text = final_summary
	restart_button.text = "새 작전 선택 (Enter)"
	game_over_overlay.visible = true
	get_tree().paused = true


func _selected_map_display_name() -> String:
	var config_path := MAP_CONFIG_PATH_PATTERN % selected_map_size
	if ResourceLoader.exists(config_path):
		return String(load(config_path).get("display_name"))
	return selected_map_size


func _restart_run() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _report_configuration_error(message: String) -> void:
	push_error(message)
	status_label.text = "설정 오류: %s" % message


func _format_time(seconds: float) -> String:
	var total_seconds := floori(seconds)
	var minutes := floori(float(total_seconds) / 60.0)
	return "%02d:%02d" % [minutes, total_seconds % 60]
