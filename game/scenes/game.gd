extends Node2D

## 최상위 조립 지점입니다. 기능은 활성화됐을 때만 경로로 불러옵니다.

const PLAYER_SCENE_PATH := "res://game/features/player/player.tscn"
const START_HUB_SCENE_PATH := "res://game/features/start_hub/start_hub.tscn"
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
const SPAWN_CONFIG_PATH_PATTERN := "res://game/features/spawning/configs/%s.tres"
const ROOM_ENCOUNTER_SCENE_PATH := (
	"res://game/features/room_encounters/room_encounter_system.tscn"
)
const ROOM_WARP_SCENE_PATH := "res://game/features/room_navigation/room_warp_system.tscn"
const WEAPON_SCENE_PATH := "res://game/features/weapons/auto_weapon.tscn"
const COMBAT_SKILL_SYSTEM_SCENE_PATH := (
	"res://game/features/combat_skills/combat_skill_system.tscn"
)
const COMBAT_SKILL_HUD_SCENE_PATH := (
	"res://game/features/combat_skills/combat_skill_hud.tscn"
)
const DASH_COOLDOWN_HUD_SCENE_PATH := (
	"res://game/features/movement_hud/dash_cooldown_hud.tscn"
)
const HIT_FEEDBACK_SCENE_PATH := (
	"res://game/features/hit_feedback/hit_feedback_director.tscn"
)
const COMBAT_RESOURCE_SCENE_PATH := (
	"res://game/features/combat_resources/combat_resource_system.tscn"
)
const WEAPON_BALANCE_SCENE_PATH := (
	"res://game/features/weapon_balance/weapon_balance_service.tscn"
)
const GROWTH_BALANCE_SCENE_PATH := (
	"res://game/features/growth_balance/growth_balance_service.tscn"
)
const LOOT_LIFECYCLE_SCENE_PATH := (
	"res://game/features/loot_lifecycle/loot_lifecycle_service.tscn"
)
const LOOT_TABLE_PROVIDER_SCENE_PATH := (
	"res://game/features/loot_tables/loot_table_provider.tscn"
)
const FIELD_LOOT_ACQUISITION_SCENE_PATH := (
	"res://game/features/field_loot/field_loot_acquisition_service.tscn"
)
const SESSION_SOCKET_SERVICE_SCENE_PATH := (
	"res://game/features/session_sockets/session_socket_service.tscn"
)
const SESSION_SOCKET_HUD_SCENE_PATH := (
	"res://game/features/session_sockets/session_socket_hud.tscn"
)
const RUN_SETTLEMENT_SCENE_PATH := (
	"res://game/features/run_settlement/run_settlement_service.tscn"
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
const PERSISTENT_PROFILE_SCENE_PATH := (
	"res://game/features/persistent_profile/persistent_profile.tscn"
)
const OPERATION_CONTRACT_SCENE_PATH := (
	"res://game/features/operation_contract/operation_contract_service.tscn"
)
const OPERATION_LAUNCH_PREFLIGHT_SCENE_PATH := (
	"res://game/features/operation_launch/operation_launch_preflight_service.tscn"
)
const LOOT_LAUNCH_VALIDATOR_SCENE_PATH := (
	"res://game/features/operation_launch/loot_launch_validator.tscn"
)
const CHARACTER_SELECTION_SCENE_PATH := (
	"res://game/features/character_selection/character_selection_service.tscn"
)
const LOADOUT_INVESTMENT_SCENE_PATH := (
	"res://game/features/loadout_investment/loadout_investment_service.tscn"
)
const P5_HUB_PROGRESSION_SCENE_PATH := (
	"res://game/features/p5_hub_progression/p5_hub_progression_service.tscn"
)
const HUB_ECONOMY_SCENE_PATH := "res://game/features/hub_economy/hub_economy_system.tscn"
const CRAFTING_SCENE_PATH := "res://game/features/crafting/crafting_system.tscn"
const PENALTY_SCENE_PATH := "res://game/features/penalty_modifiers/penalty_system.tscn"
const RANKING_SCENE_PATH := (
	"res://game/features/conditional_ranking/conditional_ranking_system.tscn"
)
const OPERATION_RESULT_SCENE_PATH := (
	"res://game/features/operation_results/operation_result_service.tscn"
)
const KEY_MAPPING_SERVICE_SCENE_PATH := (
	"res://game/features/key_mapping/key_mapping_service.tscn"
)
const KEY_MAPPING_PANEL_SCENE_PATH := (
	"res://game/features/key_mapping/key_mapping_panel.tscn"
)
const SKILL_BINDING_SERVICE_SCENE_PATH := (
	"res://game/features/skill_binding/skill_binding_service.tscn"
)
const PRESENTATION_SETTINGS_SCENE_PATH := (
	"res://game/features/presentation_settings/presentation_settings_service.tscn"
)
const MOBILE_CONTROL_PAD_SCENE_PATH := (
	"res://game/features/mobile_controls/mobile_control_pad.tscn"
)
const ELITE_PURSUIT_SCENE_PATH := (
	"res://game/features/elite_pursuit/elite_pursuit_service.tscn"
)
const OPERATION_TUTORIAL_SCENE_PATH := (
	"res://game/features/operation_tutorial/operation_tutorial_overlay.tscn"
)
const CYBERPUNK_OVERLAY_SCENE_PATH := (
	"res://game/features/presentation_theme/cyberpunk_overlay.tscn"
)
const OPERATION_SETUP_PRESENTER_SCRIPT := preload(
	"res://game/features/run_setup/operation_setup_presenter.gd"
)
const COMBAT_HUD_PRESENTER_SCRIPT := preload(
	"res://game/features/run_setup/combat_hud_presenter.gd"
)
const MAP_GENERATOR_METHODS := [
	&"configure_obstacles",
	&"generate",
	&"get_player_spawn_position",
	&"get_extraction_position",
	&"get_enemy_spawn_position",
	&"get_visibility_region",
	&"get_visibility_room_rects",
	&"get_room_encounter_snapshot",
	&"get_room_spawn_positions",
	&"get_loot_spawn_points",
	&"get_world_path",
]
const PLAYER_METHODS := [
	&"configure_damage",
	&"get_health_snapshot",
	&"get_movement_snapshot",
	&"get_runtime_stats",
	&"get_facing_direction",
	&"heal",
	&"set_runtime_modifier_source",
	&"remove_runtime_modifier_source",
]
const START_HUB_METHODS := [
	&"get_spawn_position",
	&"get_operation_position",
	&"get_room_rect",
	&"get_snapshot",
	&"request_operation",
]
const OPERATION_TUTORIAL_METHODS := [
	&"configure", &"show_first_operation", &"dismiss", &"get_snapshot",
]
const FOG_OF_WAR_METHODS := [&"configure", &"get_snapshot", &"set_visibility_multiplier"]
const MINIMAP_PROVIDER_METHODS := [&"get_minimap_snapshot"]
const MINIMAP_METHODS := [&"configure", &"set_warp_targets", &"set_expanded", &"is_expanded"]
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
	&"equip_state",
	&"take_equipment_state",
	&"install_part",
	&"install_module",
	&"uninstall_part",
	&"uninstall_module",
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
	&"set_upgrade_balance_provider",
	&"get_active_weapon_upgrade_modifiers",
	&"active_weapon_has_combat_tags",
	&"get_active_skill_mechanic_override",
	&"export_runtime_state",
	&"restore_runtime_state",
	&"validate_runtime_state",
	&"validate_operation_launch",
]
const WEAPON_BALANCE_METHODS := [
	&"configure",
	&"request_live_balance",
	&"load_csv_text",
	&"get_weapon_balance",
	&"get_snapshot",
]
const GROWTH_BALANCE_METHODS := [
	&"configure",
	&"request_live_balance",
	&"get_run_buff_catalog",
	&"get_upgrade_spec",
	&"get_player_modifiers",
	&"get_weapon_modifiers",
	&"quote_upgrade",
	&"get_snapshot",
]
const LOOT_LIFECYCLE_METHODS := [
	&"configure", &"request_live_catalog", &"load_csv_text", &"get_definition",
	&"get_snapshot", &"get_for_region", &"resolve_outcome",
]
const LOOT_TABLE_METHODS := [
	&"configure", &"request_live_table", &"load_csv_text", &"get_candidates",
	&"roll_drop", &"get_briefing", &"get_snapshot",
]
const FIELD_LOOT_ACQUISITION_METHODS := [
	&"configure", &"spawn_from_source", &"spawn_candidate", &"acquire_focused",
	&"equip_focused", &"restore_equipment_swaps", &"restore_run_inventory", &"cancel_preview",
	&"get_active_drops", &"get_panel", &"get_snapshot",
	&"register_enemy", &"spawn_room_reward",
]
const SESSION_SOCKET_METHODS := [
	&"configure", &"request_live_catalog", &"load_csv_text", &"socket_item",
	&"unsocket", &"clear_run", &"get_snapshot",
]
const RUN_SETTLEMENT_METHODS := [&"configure", &"settle", &"get_snapshot"]
const INVENTORY_METHODS := [
	&"configure",
	&"add_item",
	&"can_place",
	&"move_item",
	&"take_item",
	&"take_item_entry",
	&"add_linked_resource",
	&"can_add_linked_resource",
	&"get_runtime_payload",
	&"get_items_by_type",
	&"find_instance_ids_by_resource",
	&"consume_linked_resource",
	&"get_snapshot",
	&"export_runtime_state",
	&"restore_runtime_state",
	&"validate_runtime_state",
	&"validate_operation_launch",
]
const PANEL_METHODS := [&"configure", &"open_panel", &"close_panel"]
const EXTRACTION_METHODS := [
	&"configure", &"request_extraction", &"set_locked", &"advance", &"get_snapshot",
]
const CREDIT_LEDGER_METHODS := [
	&"add_carried",
	&"secure_carried",
	&"lose_carried",
	&"can_spend_carried",
	&"spend_carried",
	&"get_snapshot",
]
const LOOT_SPAWNER_METHODS := [&"configure", &"get_spawn_snapshot"]
const ENEMY_SPAWNER_METHODS := [
	&"configure", &"get_snapshot", &"get_active_targets", &"spawn_enemy_at",
	&"spawn_elite_pursuer_at", &"set_reinforcement_paused", &"get_remaining_spawn_budget",
	&"get_separation_vector",
]
const ROOM_ENCOUNTER_METHODS := [
	&"configure", &"try_start_room", &"get_snapshot", &"get_active_rewards", &"is_room_completed",
]
const ROOM_WARP_METHODS := [&"configure", &"refresh_targets", &"get_warp_targets", &"request_warp", &"get_snapshot"]
const RUN_BUFF_METHODS := [
	&"configure",
	&"prepare_choices",
	&"select_buff",
	&"selected_buff_count",
	&"get_meta_experience_breakdown",
	&"get_snapshot",
	&"set_catalog",
]
const META_PROGRESSION_METHODS := [
	&"configure",
	&"settle_run",
	&"apply_to_targets",
	&"get_snapshot",
	&"get_summary_line",
]
const EQUIPMENT_UPGRADE_METHODS := [
	&"configure", &"set_balance_provider", &"quote_upgrade", &"upgrade",
]
const HEALTH_RECOVERY_METHODS := [&"configure", &"advance", &"get_snapshot", &"set_recovery_multiplier"]
const COMBAT_SKILL_METHODS := [
	&"configure", &"try_activate", &"advance", &"set_activation_enabled",
	&"get_skill_states", &"get_snapshot", &"preview_skill_replacement",
	&"replace_skill", &"restore_skill_replacement", &"set_runtime_modifiers",
	&"remove_runtime_modifiers",
]
const COMBAT_SKILL_HUD_METHODS := [&"configure", &"get_snapshot"]
const DASH_COOLDOWN_HUD_METHODS := [&"configure", &"get_snapshot"]
const HIT_FEEDBACK_METHODS := [&"configure", &"register_actor", &"get_snapshot"]
const COMBAT_RESOURCE_METHODS := [
	&"configure", &"can_activate", &"consume_for_skill", &"restore_energy",
	&"spawn_enemy_drops", &"get_skill_resource_snapshot", &"get_snapshot",
	&"set_recovery_multiplier", &"capture_skill_slot_state", &"reset_skill_slot",
	&"restore_skill_slot_state",
]
const PERSISTENT_PROFILE_METHODS := [
	&"configure", &"can_spend", &"spend", &"add_credits", &"get_snapshot",
	&"is_unlocked", &"unlock", &"add_warehouse_item", &"has_warehouse_item",
	&"take_warehouse_item", &"add_blueprint", &"consume_blueprint",
	&"add_crafted_item", &"remove_crafted_item", &"set_consumable_loadout", &"consume_loadout_for_run",
	&"register_shop_offer", &"is_shop_offer_registered",
	&"unlock_skill", &"register_blueprint", &"is_blueprint_registered",
	&"add_codex_progress", &"get_codex_progress", &"has_processed_transaction",
	&"mark_transaction_processed",
]
const OPERATION_CONTRACT_METHODS := [
	&"configure", &"select_region", &"select_difficulty", &"cycle_region",
	&"cycle_difficulty", &"quote", &"invest", &"get_snapshot", &"clear_active_contract",
]
const OPERATION_LAUNCH_PREFLIGHT_METHODS := [
	&"configure", &"register_contributor", &"unregister_contributor",
	&"register_validator", &"unregister_validator",
	&"get_investment_context", &"create_plan", &"validate_plan", &"contract_matches_plan",
	&"clear_plan", &"get_snapshot",
]
const CHARACTER_SELECTION_METHODS := [
	&"configure", &"request_live_catalog", &"load_csv_text", &"select_character",
	&"cycle_character", &"get_investment_context", &"get_operation_setting_contribution",
	&"get_snapshot",
]
const LOADOUT_INVESTMENT_METHODS := [
	&"configure", &"request_live_catalog", &"load_catalog_text",
	&"cycle_weapon", &"cycle_skill", &"select_weapon", &"select_skill",
	&"can_launch", &"get_selection_errors", &"get_investment_context",
	&"get_operation_setting_contribution", &"commit_run_purchase", &"finish_run", &"get_snapshot",
]
const P5_HUB_PROGRESSION_METHODS := [
	&"configure", &"get_investment_context", &"get_operation_setting_contribution",
	&"create_operation_draft",
	&"confirm_operation_draft", &"begin_run", &"settle_run", &"refresh_hub",
	&"toggle_utility", &"purchase_shop_offer", &"get_shop_snapshot", &"quote_shop_offer",
	&"reroll_shop", &"craft_recipe",
	&"start_training", &"record_training_hit", &"finish_training", &"get_snapshot",
	&"perform_hub_action",
]
const HUB_ECONOMY_METHODS := [
	&"configure", &"quote", &"purchase", &"set_consumable_loadout",
	&"get_consumable_effects", &"get_snapshot",
]
const CRAFTING_METHODS := [&"configure", &"quote", &"craft"]
const PENALTY_METHODS := [
	&"configure", &"toggle", &"cycle_single", &"get_snapshot",
]
const RANKING_METHODS := [
	&"configure", &"submit_run", &"get_entries", &"get_snapshot",
	&"get_provider_status", &"set_online_gateway", &"set_provider_mode",
	&"retry_pending_submissions",
]
const OPERATION_RESULT_METHODS := [&"configure", &"settle_success", &"settle_failure"]
const KEY_MAPPING_METHODS := [
	&"configure", &"rebind_action", &"reset_defaults", &"get_entries", &"get_snapshot",
]
const PRESENTATION_SETTINGS_METHODS := [
	&"configure", &"get_snapshot", &"set_hud_anchor", &"set_key_label_format",
	&"set_mobile_controls_mode", &"cycle_hud_anchor", &"cycle_key_label_format",
	&"cycle_mobile_controls_mode", &"reset_defaults", &"should_show_mobile_controls",
]
const MOBILE_CONTROL_PAD_METHODS := [
	&"configure", &"get_snapshot", &"simulate_action", &"release_all", &"set_context_enabled",
]
const ELITE_PURSUIT_METHODS := [&"configure", &"get_snapshot", &"force_evaluate"]
const SKILL_BINDING_METHODS := [
	&"configure", &"assign_skill", &"reset_defaults", &"action_for_skill",
	&"skill_for_action", &"input_label_for_skill", &"get_entries",
	&"get_allowed_actions", &"get_snapshot", &"replace_runtime_skill",
	&"restore_runtime_skill",
]
const CYBERPUNK_OVERLAY_METHODS := [&"configure", &"get_snapshot"]
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
@onready var control_hint_label: Label = $UI/HUDMargin/Panel/Margin/Content/FooterRow/Hint
@onready var hub_control_hint_label: Label = $UI/StartHubHUD/Panel/Margin/Content/Controls
@onready var interaction_label: Label = %InteractionLabel
@onready var health_bar: ProgressBar = %HealthBar
@onready var health_label: Label = %HealthLabel
@onready var experience_bar: ProgressBar = %ExperienceBar
@onready var experience_label: Label = %ExperienceLabel
@onready var run_setup_overlay: Control = %RunSetupOverlay
@onready var start_hub_hud: Control = %StartHubHUD
@onready var setup_close_button: Button = %SetupCloseButton
@onready var balance_mode_section: Control = %BalanceModeSection
@onready var locked_balance_button: Button = %LockedBalanceButton
@onready var live_balance_button: Button = %LiveBalanceButton
@onready var balance_mode_description: Label = %BalanceModeDescription
@onready var small_map_button: Button = %SmallMapButton
@onready var medium_map_button: Button = %MediumMapButton
@onready var large_map_button: Button = %LargeMapButton
@onready var region_button: Button = %RegionButton
@onready var difficulty_button: Button = %DifficultyButton
@onready var penalty_button: Button = %PenaltyButton
@onready var contract_summary: Label = %ContractSummary
@onready var profile_summary: Label = %ProfileSummary
@onready var shop_button: Button = %ShopButton
@onready var craft_button: Button = %CraftButton
@onready var utility_button: Button = %UtilityButton
@onready var training_button: Button = %TrainingButton
@onready var codex_button: Button = %CodexButton
@onready var loadout_button: Button = %LoadoutButton
@onready var game_over_overlay: Control = %GameOverOverlay
@onready var end_title: Label = %EndTitle
@onready var game_over_summary: Label = %GameOverSummary
@onready var restart_button: Button = %RestartButton

var player
var start_hub
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
var room_encounter_system
var room_warp_system
var auto_weapon
var combat_skill_system
var combat_skill_hud
var dash_cooldown_hud
var hit_feedback_director
var combat_resource_system
var weapon_balance_service
var growth_balance_service
var loot_lifecycle_service
var loot_table_provider
var field_loot_acquisition_service
var field_loot_equip_catalog: FieldLootEquipCatalog
var session_socket_service
var session_socket_hud
var run_settlement_service
var progression_system
var health_recovery_system
var run_buff_system
var run_buff_selector
var meta_progression_system
var equipment_upgrade_service
var persistent_profile
var desktop_progress
var operation_contract_service
var operation_launch_preflight_service
var loot_launch_validator
var character_selection_service
var loadout_investment_service
var p5_hub_progression_service
var shop_browser_panel
var hub_economy_system
var crafting_system
var penalty_system
var conditional_ranking_system
var operation_result_service
var key_mapping_service
var skill_binding_service
var key_mapping_panel
var presentation_settings_service
var mobile_control_pad
var elite_pursuit_service
var boss_warning_hud
var cyberpunk_overlay
var operation_tutorial_overlay
var operation_setup_presenter := OPERATION_SETUP_PRESENTER_SCRIPT.new()
var combat_hud_presenter := COMBAT_HUD_PRESENTER_SCRIPT.new()
var operation_launch_button: Button
var character_selection_button: Button
var main_weapon_investment_button: Button
var secondary_weapon_investment_button: Button
var skill_investment_buttons: Array[Button] = []
var active_contract: Dictionary = {}
var active_launch_plan: Dictionary = {}
var current_run_id: StringName = &""
var active_ranking_context: Dictionary = {}
var run_sequence: int = 0
var last_loot_settlement: Dictionary = {}
var consumed_run_items: Array[StringName] = []
var current_map_config: Resource
var selected_map_size: String = "small"
var selected_balance_source_mode: int = WeaponBalanceConfig.SourceMode.LOCKED_CSV
var preferred_weapon_slot: StringName = &"main"
var hub_active_weapon_name: String = ""
var prepared_equipment_state: Dictionary = {}
var prepared_inventory_state: Dictionary = {}
var lose_equipped_loadout_on_return: bool = false
var elapsed_time: float = 0.0
var target_run_duration_seconds: float = 600.0
var extraction_unlock_seconds: float = 600.0
var extraction_unlocked: bool = false
var defeated_enemies: int = 0
var run_combat_metrics := preload("res://game/core/run_combat_metrics.gd").new()
var run_started: bool = false
var run_ended: bool = false
var initialization_recovery_active: bool = false
var pending_buff_levels: Array[int] = []
var modal_ui_visibility_snapshot: Dictionary = {}
var active_run_skill_loadout: Resource
var run_skill_binding_replacements: Array[Dictionary] = []


func _ready() -> void:
	control_hint_label.text = "이동 WASD · Space 대시 · LMB 기본기 · 1~9 스킬 · Q/F/I/U/E · M 전술 지도 · K 키 설정"
	hub_control_hint_label.text = "이동 WASD · I 가방 · U 장비 · E 모듈·파츠 · Q 무기 · F 게이트 · K 키 설정"
	process_mode = Node.PROCESS_MODE_ALWAYS
	if features != null and features.cyberpunk_theme_enabled:
		if not _install_cyberpunk_theme():
			return
	var operation_controls: Dictionary = operation_setup_presenter.call(&"install", run_setup_overlay)
	operation_setup_presenter.connect(&"honor_requested", func():
		if conditional_ranking_system != null:
			conditional_ranking_system.call(&"show_honors", run_setup_overlay)
	)
	operation_launch_button = operation_controls.get(&"launch_button") as Button
	character_selection_button = operation_controls.get(&"character_button") as Button
	main_weapon_investment_button = operation_controls.get(&"main_weapon_button") as Button
	secondary_weapon_investment_button = operation_controls.get(&"secondary_weapon_button") as Button
	for button in operation_controls.get(&"skill_buttons", []):
		if button is Button:
			skill_investment_buttons.append(button)
	combat_hud_presenter.call(&"install", hud_margin)
	restart_button.pressed.connect(_restart_run)
	setup_close_button.pressed.connect(_close_run_setup)
	locked_balance_button.pressed.connect(
		_select_balance_source_mode.bind(WeaponBalanceConfig.SourceMode.LOCKED_CSV)
	)
	live_balance_button.pressed.connect(
		_select_balance_source_mode.bind(WeaponBalanceConfig.SourceMode.LIVE_GOOGLE_SHEET)
	)
	small_map_button.pressed.connect(_select_map_tier.bind("small"))
	medium_map_button.pressed.connect(_select_map_tier.bind("medium"))
	large_map_button.pressed.connect(_select_map_tier.bind("large"))
	if operation_launch_button != null:
		operation_launch_button.pressed.connect(_start_selected_run)
	if character_selection_button != null:
		character_selection_button.pressed.connect(_cycle_character)
	if main_weapon_investment_button != null:
		main_weapon_investment_button.pressed.connect(_cycle_investment_weapon.bind(&"main"))
	if secondary_weapon_investment_button != null:
		secondary_weapon_investment_button.pressed.connect(_cycle_investment_weapon.bind(&"secondary"))
	for button in skill_investment_buttons:
		button.pressed.connect(_cycle_investment_skill.bind(int(button.get_meta(&"skill_slot_index", 0))))
	region_button.pressed.connect(_cycle_region)
	difficulty_button.pressed.connect(_cycle_difficulty)
	penalty_button.pressed.connect(_cycle_penalty)
	shop_button.pressed.connect(_purchase_medkit)
	craft_button.pressed.connect(_craft_default_item)
	loadout_button.pressed.connect(_toggle_medkit_loadout)
	utility_button.pressed.connect(_toggle_run_utility)
	training_button.pressed.connect(_toggle_training_session)
	codex_button.pressed.connect(_show_codex_summary)
	hud_margin.visible = false
	map_label.visible = false
	interaction_label.visible = false
	game_over_overlay.visible = false
	start_hub_hud.visible = false
	balance_mode_section.visible = false

	if features == null:
		_report_configuration_error("FeatureManifest가 지정되지 않았습니다.")
		_show_initialization_recovery("FeatureManifest를 불러오지 못했습니다.")
		return
	credit_label.visible = features.credits_enabled
	equipment_label.visible = features.equipment_enabled
	weapon_runtime_label.visible = features.weapons_enabled

	var configuration_errors := features.validation_errors()
	if not configuration_errors.is_empty():
		for message in configuration_errors:
			push_error(message)
		_show_initialization_recovery(" / ".join(configuration_errors))
		return
	if not _install_persistent_services():
		_show_initialization_recovery("영구 서비스 초기화 실패")
		return
	if features.presentation_settings_enabled and not _install_presentation_settings():
		_show_initialization_recovery("표시 설정 초기화 실패")
		return
	if features.key_mapping_enabled and not _install_key_mapping():
		_show_initialization_recovery("키 설정 초기화 실패")
		return
	if features.mobile_controls_enabled and not _install_mobile_controls():
		_show_initialization_recovery("모바일 조작 초기화 실패")
		return
	if features.operation_tutorial_enabled and not _install_operation_tutorial():
		_show_initialization_recovery("작전 튜토리얼 초기화 실패")
		return

	_configure_tier_button(small_map_button, "small")
	_configure_tier_button(medium_map_button, "medium")
	_configure_tier_button(large_map_button, "large")
	_configure_balance_mode_selector()
	if features.loot_lifecycle_enabled and not _install_loot_lifecycle():
		_show_initialization_recovery("전리품 생명주기 초기화 실패")
		return
	if features.loot_tables_enabled and not _load_field_loot_equip_catalog():
		_show_initialization_recovery("현장 전리품 카탈로그 초기화 실패")
		return
	if features.run_settlement_enabled and not _install_run_settlement():
		_show_initialization_recovery("런 정산 초기화 실패")
		return
	if features.loot_tables_enabled and not _install_loot_table_provider():
		_show_initialization_recovery("드랍 테이블 초기화 실패")
		return
	_refresh_contract_setup_ui()

	_route_initial_entry()


func _route_initial_entry() -> void:
	initialization_recovery_active = false
	game_over_overlay.visible = false
	if features.run_setup_enabled and features.start_hub_enabled:
		run_setup_overlay.visible = false
		get_tree().paused = false
		if not _install_start_hub():
			_report_configuration_error("기본 거점 진입 경로를 구성하지 못했습니다.")
			_show_initialization_recovery("기본 거점 진입 경로를 구성하지 못했습니다.")
			return
		status_label.text = "거점 준비 완료 · 작전 게이트로 이동해 F를 누르세요."
		return
	if features.run_setup_enabled:
		run_setup_overlay.visible = true
		get_tree().paused = true
		operation_setup_presenter.call(&"reset_steps")
		status_label.text = "작전 설정 1단계 · 지역과 규모를 선택하세요."
		return
	run_setup_overlay.visible = false
	get_tree().paused = false
	if start_run(features.map_size):
		return
	# 개발용 직접 실행도 빈 화면으로 남지 않도록 실패 시 복구 가능한 경로를 엽니다.
	if features.start_hub_enabled and _install_start_hub():
		status_label.text = "직접 작전 생성 실패 · 거점 게이트에서 설정을 다시 확인하세요."
		return
	run_setup_overlay.visible = true
	get_tree().paused = true
	operation_setup_presenter.call(&"reset_steps")
	status_label.text = "직접 작전 생성 실패 · 설정을 확인한 뒤 다시 투입하세요."


func _show_initialization_recovery(reason: String) -> void:
	initialization_recovery_active = true
	run_setup_overlay.visible = false
	hud_margin.visible = false
	interaction_label.visible = false
	get_tree().paused = false
	if (
		features != null
		and features.start_hub_enabled
		and not is_instance_valid(start_hub)
		and not is_instance_valid(player)
		and _install_start_hub()
	):
		initialization_recovery_active = false
		status_label.text = "제한 거점 모드 · %s" % reason
		return
	end_title.text = "초기화 복구 필요"
	game_over_summary.text = "%s\n새로고침하거나 ESC로 초기화를 다시 시도하세요." % reason
	restart_button.text = "거점 초기화 다시 시도 (Enter)"
	game_over_overlay.visible = true
	get_tree().paused = true


func _install_persistent_services() -> bool:
	if features.persistent_profile_enabled:
		persistent_profile = _instantiate_feature(
			PERSISTENT_PROFILE_SCENE_PATH, self, &"PersistentProfile"
		)
		if not _supports_methods(persistent_profile, PERSISTENT_PROFILE_METHODS):
			_report_configuration_error("영구 프로필 모듈의 공개 계약이 올바르지 않습니다.")
			return false
		persistent_profile.call(
			&"configure", features.persistent_profile_storage_path, true,
			not OS.has_feature("web") and (
				not OS.get_cmdline_args().has("--script")
				or (features.desktop_progress_enabled and features.desktop_progress_storage_path != "user://sfh_desktop_progress.json")
			)
		)
		persistent_profile.connect(&"profile_changed", Callable(self, &"_on_profile_changed"))
	if features.desktop_progress_enabled and features.persistent_profile_enabled and features.inventory_enabled and features.equipment_enabled and not OS.has_feature("web"):
		# Existing headless contracts stay isolated; restart tests supply their own path.
		if not OS.get_cmdline_args().has("--script") or features.desktop_progress_storage_path != "user://sfh_desktop_progress.json":
			desktop_progress = load("res://game/features/local_save/desktop_progress_service.gd").new()
			add_child(desktop_progress)
			desktop_progress.call(&"configure", features.desktop_progress_storage_path)
			desktop_progress.call(&"register_storage_provider", persistent_profile)
			var save_label: Label = load("res://game/features/local_save/save_status_label.gd").new()
			hub_control_hint_label.get_parent().add_child(save_label)
			save_label.call(&"configure", desktop_progress)
	if features.conditional_ranking_enabled:
		conditional_ranking_system = _instantiate_feature(
			RANKING_SCENE_PATH, self, &"ConditionalRanking"
		)
		if (
			not _supports_methods(conditional_ranking_system, RANKING_METHODS)
			or not conditional_ranking_system.call(
				&"configure", features.conditional_ranking_storage_path,
				load(features.conditional_ranking_policy_path), true,
				load(features.ranking_provider_config_path)
			)
		):
			_report_configuration_error("조건부 랭킹 모듈을 구성하지 못했습니다.")
			return false
	if features.penalty_modifiers_enabled:
		penalty_system = _instantiate_feature(PENALTY_SCENE_PATH, self, &"PenaltyModifiers")
		if (
			not _supports_methods(penalty_system, PENALTY_METHODS)
			or not penalty_system.call(&"configure", load(features.penalty_config_path))
		):
			_report_configuration_error("페널티 변형 모듈을 구성하지 못했습니다.")
			return false
		penalty_system.connect(&"selection_changed", Callable(self, &"_on_contract_changed"))
	if features.operation_contracts_enabled:
		operation_contract_service = _instantiate_feature(
			OPERATION_CONTRACT_SCENE_PATH, self, &"OperationContracts"
		)
		if (
			not _supports_methods(operation_contract_service, OPERATION_CONTRACT_METHODS)
			or not operation_contract_service.call(
				&"configure", persistent_profile, load(features.operation_contract_config_path)
			)
		):
			_report_configuration_error("작전 계약 모듈을 구성하지 못했습니다.")
			return false
		operation_contract_service.connect(
			&"contract_changed", Callable(self, &"_on_contract_changed")
		)
	if features.character_selection_enabled:
		character_selection_service = _instantiate_feature(
			CHARACTER_SELECTION_SCENE_PATH, self, &"CharacterSelection"
		)
		var character_config := load(features.character_selection_config_path) as CharacterSelectionConfig
		if (
			not _supports_methods(character_selection_service, CHARACTER_SELECTION_METHODS)
			or character_config == null
			or not character_selection_service.call(&"configure", character_config)
		):
			_report_configuration_error("캐릭터 선택 모듈을 구성하지 못했습니다.")
			return false
		character_selection_service.connect(
			&"selection_changed", Callable(self, &"_on_contract_changed")
		)
	if features.loadout_investment_enabled:
		loadout_investment_service = _instantiate_feature(
			LOADOUT_INVESTMENT_SCENE_PATH, self, &"LoadoutInvestment"
		)
		var loadout_investment_config := load(
			features.loadout_investment_config_path
		) as LoadoutInvestmentConfig
		if (
			not _supports_methods(loadout_investment_service, LOADOUT_INVESTMENT_METHODS)
			or loadout_investment_config == null
			or not loadout_investment_service.call(
				&"configure", loadout_investment_config, persistent_profile
			)
		):
			_report_configuration_error("런 장비 투자 모듈을 구성하지 못했습니다.")
			return false
		loadout_investment_service.connect(
			&"selection_changed", Callable(self, &"_on_contract_changed")
		)
	if features.p5_hub_progression_enabled:
		p5_hub_progression_service = _instantiate_feature(
			P5_HUB_PROGRESSION_SCENE_PATH, self, &"P5HubProgression"
		)
		var p5_ready := not (
			not _supports_methods(p5_hub_progression_service, P5_HUB_PROGRESSION_METHODS)
			or not bool(p5_hub_progression_service.call(
				&"configure", persistent_profile, operation_contract_service,
				load(features.p5_hub_progression_config_path), features.map_seed
			))
		)
		if not p5_ready:
			var p5_errors := PackedStringArray()
			if (
				is_instance_valid(p5_hub_progression_service)
				and p5_hub_progression_service.has_method(&"get_configuration_errors")
			):
				p5_errors = p5_hub_progression_service.call(&"get_configuration_errors")
			push_warning("P5 거점 진행 모듈 비활성 · %s" % (
				" / ".join(p5_errors) if not p5_errors.is_empty() else "구성 계약 불일치"
			))
			_free_feature_node(p5_hub_progression_service)
			p5_hub_progression_service = null
		else:
			p5_hub_progression_service.connect(
				&"snapshot_changed", Callable(self, &"_on_contract_changed")
			)
			if features.shop_browser_enabled and not p5_hub_progression_service.call(&"get_shop_snapshot").is_empty():
				shop_browser_panel = _instantiate_feature(
					"res://game/features/shop_browser/shop_browser_panel.tscn", ui_layer, &"ShopBrowser"
				)
				if _supports_panel(shop_browser_panel) and shop_browser_panel.call(&"configure", p5_hub_progression_service):
					_connect_modal_panel(shop_browser_panel)
				else:
					_free_feature_node(shop_browser_panel)
					shop_browser_panel = null
	if features.operation_launch_preflight_enabled and not _install_operation_launch_preflight():
		_report_configuration_error("작전 사전검증 모듈을 구성하지 못했습니다.")
		return false
	if features.hub_economy_enabled:
		hub_economy_system = _instantiate_feature(
			HUB_ECONOMY_SCENE_PATH, self, &"HubEconomy"
		)
		if (
			not _supports_methods(hub_economy_system, HUB_ECONOMY_METHODS)
			or not hub_economy_system.call(
				&"configure", persistent_profile, load(features.hub_economy_config_path)
			)
		):
			_report_configuration_error("거점 경제 모듈을 구성하지 못했습니다.")
			return false
	if features.crafting_enabled:
		crafting_system = _instantiate_feature(CRAFTING_SCENE_PATH, self, &"Crafting")
		if (
			not _supports_methods(crafting_system, CRAFTING_METHODS)
			or not crafting_system.call(
				&"configure", persistent_profile, load(features.crafting_config_path), features.map_seed
			)
		):
			_report_configuration_error("도면 제작 모듈을 구성하지 못했습니다.")
			return false
	if persistent_profile != null:
		operation_result_service = _instantiate_feature(
			OPERATION_RESULT_SCENE_PATH, self, &"OperationResults"
		)
		if (
			not _supports_methods(operation_result_service, OPERATION_RESULT_METHODS)
			or not operation_result_service.call(
				&"configure", persistent_profile, conditional_ranking_system,
				load(features.operation_result_config_path), features.map_seed
			)
		):
			_report_configuration_error("작전 결과 정산 모듈을 구성하지 못했습니다.")
			return false
		if desktop_progress != null:
			operation_result_service.connect(&"operation_settled", Callable(desktop_progress, &"observe_settlement"))
	return true


func _install_operation_launch_preflight() -> bool:
	operation_launch_preflight_service = _instantiate_feature(
		OPERATION_LAUNCH_PREFLIGHT_SCENE_PATH, self, &"OperationLaunchPreflight"
	)
	if (
		not _supports_methods(operation_launch_preflight_service, OPERATION_LAUNCH_PREFLIGHT_METHODS)
		or not bool(operation_launch_preflight_service.call(
			&"configure", operation_contract_service, persistent_profile
		))
	):
		return false
	for registration in [
		[&"character", character_selection_service],
		[&"loadout_investment", loadout_investment_service],
		[&"utility_investment", p5_hub_progression_service],
	]:
		var provider: Node = registration[1]
		if provider != null and not bool(operation_launch_preflight_service.call(
			&"register_contributor", registration[0], provider
		)):
			return false
	if features.loot_enabled:
		loot_launch_validator = _instantiate_feature(
			LOOT_LAUNCH_VALIDATOR_SCENE_PATH, self, &"LootLaunchValidator"
		)
		if (
			loot_launch_validator == null
			or not bool(loot_launch_validator.call(&"configure", LOOT_CONFIG_PATH_PATTERN))
			or not bool(operation_launch_preflight_service.call(
				&"register_validator", &"loot", loot_launch_validator
			))
		):
			return false
	return true


func _install_key_mapping() -> bool:
	key_mapping_service = _instantiate_feature(
		KEY_MAPPING_SERVICE_SCENE_PATH, self, &"KeyMappingService"
	)
	if (
		not _supports_methods(key_mapping_service, KEY_MAPPING_METHODS)
		or not key_mapping_service.call(
			&"configure",
			load(features.key_mapping_catalog_path),
			features.key_mapping_storage_path,
			true
		)
	):
		_report_configuration_error("키 설정 저장 모듈을 구성하지 못했습니다.")
		return false
	if features.skill_binding_enabled:
		skill_binding_service = _instantiate_feature(
			SKILL_BINDING_SERVICE_SCENE_PATH, self, &"SkillBindingService"
		)
		var skill_loadout := load(features.combat_skill_loadout_path)
		if (
			not _supports_methods(skill_binding_service, SKILL_BINDING_METHODS)
			or not skill_binding_service.call(
				&"configure",
				skill_loadout,
				load(features.skill_binding_profile_path),
				features.skill_binding_storage_path,
				key_mapping_service,
				true
			)
		):
			_report_configuration_error("스킬 배치 저장 모듈을 구성하지 못했습니다.")
			return false
	key_mapping_panel = _instantiate_feature(
		KEY_MAPPING_PANEL_SCENE_PATH, ui_layer, &"KeyMappingPanel"
	)
	if key_mapping_panel == null or not _supports_panel(key_mapping_panel):
		_report_configuration_error("키 설정 UI 모듈의 공개 계약이 올바르지 않습니다.")
		return false
	if not bool(key_mapping_panel.call(
		&"configure", key_mapping_service, skill_binding_service, presentation_settings_service
	)):
		_report_configuration_error("키 설정 UI를 입력 저장 모듈에 연결하지 못했습니다.")
		return false
	_connect_modal_panel(key_mapping_panel)
	if key_mapping_service.has_signal(&"bindings_changed"):
		key_mapping_service.connect(
			&"bindings_changed", Callable(self, &"_on_key_bindings_changed")
		)
	if is_instance_valid(skill_binding_service) and skill_binding_service.has_signal(&"bindings_changed"):
		skill_binding_service.connect(
			&"bindings_changed", Callable(self, &"_on_key_bindings_changed")
		)
	_refresh_control_hints()
	return true


func _install_presentation_settings() -> bool:
	presentation_settings_service = _instantiate_feature(
		PRESENTATION_SETTINGS_SCENE_PATH, self, &"PresentationSettings"
	)
	if (
		not _supports_methods(presentation_settings_service, PRESENTATION_SETTINGS_METHODS)
		or not presentation_settings_service.has_signal(&"settings_changed")
		or not presentation_settings_service.call(
			&"configure", features.presentation_settings_storage_path, true
		)
	):
		_report_configuration_error("HUD·모바일 표시 설정 모듈을 구성하지 못했습니다.")
		return false
	presentation_settings_service.connect(
		&"settings_changed", Callable(self, &"_on_presentation_settings_changed")
	)
	_on_presentation_settings_changed(
		presentation_settings_service.call(&"get_snapshot")
	)
	return true


func _install_mobile_controls() -> bool:
	mobile_control_pad = _instantiate_feature(
		MOBILE_CONTROL_PAD_SCENE_PATH, ui_layer, &"MobileControlPad"
	)
	if (
		not _supports_methods(mobile_control_pad, MOBILE_CONTROL_PAD_METHODS)
		or not mobile_control_pad.call(&"configure", presentation_settings_service)
	):
		_report_configuration_error("모바일 키패드 모듈을 구성하지 못했습니다.")
		return false
	return true


func _install_cyberpunk_theme() -> bool:
	cyberpunk_overlay = _instantiate_feature(
		CYBERPUNK_OVERLAY_SCENE_PATH, self, &"CyberpunkPresentation"
	)
	if not _supports_methods(cyberpunk_overlay, CYBERPUNK_OVERLAY_METHODS):
		_report_configuration_error("사이버펑크 표현 모듈의 공개 계약이 올바르지 않습니다.")
		return false
	if not bool(cyberpunk_overlay.call(
		&"configure", features.cyberpunk_motion_enabled, features.cyberpunk_noise_enabled
	)):
		_report_configuration_error("사이버펑크 표현 모듈을 구성하지 못했습니다.")
		return false
	return true


func _on_key_bindings_changed(_snapshot: Dictionary) -> void:
	_refresh_control_hints()


func _on_presentation_settings_changed(snapshot: Dictionary) -> void:
	var resolved_snapshot := snapshot.duplicate(true)
	resolved_snapshot[&"mobile_controls_visible"] = bool(
		presentation_settings_service.call(
			&"should_show_mobile_controls",
			DisplayServer.is_touchscreen_available() or OS.has_feature("mobile")
		)
		if is_instance_valid(presentation_settings_service) else false
	)
	combat_hud_presenter.call(&"apply_user_preferences", resolved_snapshot)
	_refresh_control_hints()


func _refresh_control_hints() -> void:
	if key_mapping_service == null:
		return
	if is_instance_valid(operation_tutorial_overlay):
		operation_tutorial_overlay.call(&"configure", _tutorial_binding_labels())
	combat_hud_presenter.call(&"update_action_bindings", {
		&"primary": _binding_label(&"primary_attack"),
		&"skill_1": _binding_label(&"combat_skill_1"),
		&"skill_2": _binding_label(&"combat_skill_2"),
		&"skill_3": _binding_label(&"combat_skill_3"),
		&"switch_weapon": _binding_label(&"switch_weapon"),
		&"interact": _binding_label(&"interact"),
		&"inventory": "%s/%s/%s" % [
			_binding_label(&"toggle_inventory"),
			_binding_label(&"toggle_equipment"),
			_binding_label(&"toggle_modification"),
		],
		&"key_mapping": _binding_label(&"toggle_key_mapping"),
	})
	var move_keys := "%s/%s/%s/%s" % [
		_binding_label(&"move_up"),
		_binding_label(&"move_left"),
		_binding_label(&"move_down"),
		_binding_label(&"move_right"),
	]
	var menu_keys := "%s 가방 · %s 장비 · %s 모듈·파츠" % [
		_binding_label(&"toggle_inventory"),
		_binding_label(&"toggle_equipment"),
		_binding_label(&"toggle_modification"),
	]
	control_hint_label.text = (
		"이동 %s · %s 대시 · %s 기본기 · 스킬 %s/%s/%s · %s 무기 · %s 상호작용 · %s · %s 키 설정"
		% [
			move_keys,
			_binding_label(&"dash"),
			_binding_label(&"primary_attack"),
			_binding_label(&"combat_skill_1"),
			_binding_label(&"combat_skill_2"),
			_binding_label(&"combat_skill_3"),
			_binding_label(&"switch_weapon"),
			_binding_label(&"interact"),
			menu_keys,
			_binding_label(&"toggle_key_mapping"),
		]
	)
	var active_weapon_feedback := (
		" · 현재 %s" % hub_active_weapon_name if not hub_active_weapon_name.is_empty() else ""
	)
	hub_control_hint_label.text = "이동 %s · %s · %s 무기 · %s 게이트 · %s 키 설정%s" % [
		move_keys,
		menu_keys,
		_binding_label(&"switch_weapon"),
		_binding_label(&"interact"),
		_binding_label(&"toggle_key_mapping"),
		active_weapon_feedback,
	]


func _binding_label(action_id: StringName) -> String:
	if key_mapping_service == null:
		return {
			&"move_up": "W", &"move_down": "S", &"move_left": "A", &"move_right": "D",
			&"dash": "Space", &"primary_attack": "마우스 1", &"interact": "F",
			&"switch_weapon": "Q", &"combat_skill_1": "1", &"combat_skill_2": "2",
			&"combat_skill_3": "3", &"toggle_inventory": "I", &"toggle_equipment": "U",
			&"toggle_modification": "E", &"toggle_key_mapping": "K",
			&"equip_field_loot": "R", &"toggle_map": "M",
		}.get(action_id, String(action_id))
	for entry: Dictionary in key_mapping_service.call(&"get_entries"):
		if entry[&"action_id"] == action_id:
			return String(entry[&"binding_text"])
	return String(action_id)


func _cycle_region() -> void:
	if operation_contract_service != null:
		operation_contract_service.call(&"cycle_region", 1)
	_refresh_contract_setup_ui()


func _select_map_tier(tier_id: String) -> void:
	if tier_id not in MAP_TIER_IDS:
		return
	selected_map_size = tier_id
	_refresh_contract_setup_ui()


func _start_selected_run() -> void:
	var started := start_run(selected_map_size)
	if is_instance_valid(mobile_control_pad):
		mobile_control_pad.call(&"set_context_enabled", started or start_hub != null)


func _cycle_difficulty() -> void:
	if operation_contract_service != null:
		operation_contract_service.call(&"cycle_difficulty", 1)
	_refresh_contract_setup_ui()


func _cycle_penalty() -> void:
	if penalty_system != null:
		penalty_system.call(&"cycle_single")
	_refresh_contract_setup_ui()


func _purchase_medkit() -> void:
	if is_instance_valid(shop_browser_panel):
		shop_browser_panel.call(&"open_panel")
		return
	if _perform_p5_hub_action(&"shop_purchase"): return
	if hub_economy_system == null:
		return
	var profile_snapshot: Dictionary = persistent_profile.call(&"get_snapshot")
	var unlocks: Array = profile_snapshot.get(&"unlock_ids", [])
	var offer_id: StringName = &"buy_field_medkit"
	if &"region_industrial_district" not in unlocks:
		offer_id = &"unlock_industrial"
	elif &"region_research_complex" not in unlocks:
		offer_id = &"unlock_research"
	var result: Dictionary = hub_economy_system.call(&"purchase", offer_id)
	status_label.text = (
		"거점 구매 완료 · %s" % result.get(&"target_id", offer_id)
		if bool(result.get(&"success", false))
		else "거점 구매 실패 · %s" % result.get(&"reason", "확인 필요")
	)
	_refresh_contract_setup_ui()


func _craft_default_item() -> void:
	if _perform_p5_hub_action(&"craft_default"): return
	if crafting_system == null:
		return
	var result: Dictionary = crafting_system.call(&"craft", &"assault_rifle_blueprint")
	status_label.text = (
		"제작 완료 · 랜덤 옵션 %d개" % int(result.get(&"affix_count", 0))
		if bool(result.get(&"success", false))
		else "제작 실패 · %s" % result.get(&"reason", "재료 확인")
	)
	_refresh_contract_setup_ui()


func _toggle_medkit_loadout() -> void:
	if hub_economy_system == null:
		return
	var profile_snapshot: Dictionary = persistent_profile.call(&"get_snapshot")
	var current: Array = profile_snapshot.get(&"consumable_loadout", [])
	var next: Array[StringName] = [] if not current.is_empty() else [&"field_medkit"]
	var applied: bool = hub_economy_system.call(&"set_consumable_loadout", next)
	status_label.text = "소모품 로드아웃 %s" % (
		("응급키트 장착" if current.is_empty() else "해제") if applied else "실패"
	)
	_refresh_contract_setup_ui()


func _toggle_run_utility() -> void:
	_perform_p5_hub_action(&"utility_toggle")


func _toggle_training_session() -> void:
	_perform_p5_hub_action(&"training_toggle")


func _show_codex_summary() -> void:
	_perform_p5_hub_action(&"codex_summary")


func _perform_p5_hub_action(action_id: StringName) -> bool:
	if p5_hub_progression_service == null: return false
	var presentation: Dictionary = p5_hub_progression_service.call(&"perform_hub_action", action_id)
	if not bool(presentation.get(&"handled", false)): return false
	status_label.text = String(presentation.get(&"status_text", ""))
	_refresh_contract_setup_ui()
	return true


func _on_profile_changed(_snapshot: Dictionary) -> void:
	_refresh_contract_setup_ui()


func _on_contract_changed(_snapshot: Dictionary) -> void:
	_refresh_contract_setup_ui()


func _cycle_character() -> void:
	if character_selection_service != null:
		character_selection_service.call(&"cycle_character", 1)


func _cycle_investment_weapon(slot_id: StringName) -> void:
	if loadout_investment_service != null:
		loadout_investment_service.call(&"cycle_weapon", slot_id, 1)


func _cycle_investment_skill(slot_index: int) -> void:
	if loadout_investment_service != null:
		loadout_investment_service.call(&"cycle_skill", slot_index, 1)


func _character_investment_context() -> Dictionary:
	return (
		character_selection_service.call(&"get_investment_context")
		if character_selection_service != null else {}
	)


func _operation_investment_context() -> Dictionary:
	if operation_launch_preflight_service != null:
		return operation_launch_preflight_service.call(&"get_investment_context")
	var result := _character_investment_context().duplicate(true)
	var character_cost := int(result.get(&"additional_entry_cost", 0))
	var loadout_context: Dictionary = (
		loadout_investment_service.call(&"get_investment_context")
		if loadout_investment_service != null else {}
	)
	var utility_context: Dictionary = (
		p5_hub_progression_service.call(&"get_investment_context")
		if p5_hub_progression_service != null else {}
	)
	result[&"additional_entry_cost"] = character_cost + int(
		loadout_context.get(&"additional_entry_cost", 0)
	) + int(utility_context.get(&"additional_entry_cost", 0))
	result[&"loadout_investment"] = loadout_context.duplicate(true)
	result[&"utility_investment"] = utility_context.duplicate(true)
	return result


func _refresh_contract_setup_ui() -> void:
	if not is_instance_valid(profile_summary):
		return
	var profile_snapshot: Dictionary = (
		persistent_profile.call(&"get_snapshot") if persistent_profile != null else {}
	)
	var contract_snapshot: Dictionary = (
		operation_contract_service.call(&"get_snapshot")
		if operation_contract_service != null else {}
	)
	var penalty_snapshot: Dictionary = (
		penalty_system.call(&"get_snapshot") if penalty_system != null else {}
	)
	region_button.disabled = operation_contract_service == null
	difficulty_button.disabled = operation_contract_service == null
	penalty_button.disabled = penalty_system == null
	region_button.text = "지역 · %s" % contract_snapshot.get(&"selected_region_name", "기본")
	difficulty_button.text = "난이도 · %s" % contract_snapshot.get(&"selected_difficulty_name", "표준")
	var penalty_names: PackedStringArray = penalty_snapshot.get(&"display_names", PackedStringArray())
	penalty_button.text = "페널티 · %s" % (
		"없음" if penalty_names.is_empty() else ", ".join(penalty_names)
	)
	profile_summary.text = "보유 %d C · 고철 %d / 응급키트 %d · 도면 %d · 상점 등록 %d · 스킬 %d" % [
		int(profile_snapshot.get(&"banked_credits", 0)),
		int(profile_snapshot.get(&"warehouse", {}).get(&"scrap", 0)),
		int(profile_snapshot.get(&"warehouse", {}).get(&"field_medkit", 0)),
		(profile_snapshot.get(&"blueprints", {}) as Dictionary).values().reduce(
			func(total, value): return int(total) + int(value), 0
		),
		(profile_snapshot.get(&"unlocked_shop_offer_ids", []) as Array).size(),
		(profile_snapshot.get(&"unlocked_skill_ids", []) as Array).size(),
	]
	var loadout: Array = profile_snapshot.get(&"consumable_loadout", [])
	loadout_button.text = "소모품 · %s" % ("응급키트" if not loadout.is_empty() else "비어 있음")
	if p5_hub_progression_service != null:
		var p5_snapshot: Dictionary = p5_hub_progression_service.call(&"get_snapshot")
		var p5_utility: Dictionary = p5_snapshot.get(&"utility", {}).get(&"selected", {})
		utility_button.text = "런 유틸 · 구급키트 %s" % (
			"ON" if int(p5_utility.get(&"field_medkit", 0)) > 0 else "OFF"
		)
		var p5_shop: Dictionary = p5_snapshot.get(&"shop", {})
		shop_button.text = "회전 상점 · %d품질 비교" % int(p5_shop.get(&"quality_count", 0))
		var p5_training: Dictionary = p5_snapshot.get(&"training", {})
		training_button.text = "훈련장 · %s" % (
			"측정 종료" if not (p5_training.get(&"active", {}) as Dictionary).is_empty() else "단일/밀집"
		)
		var p5_codex: Dictionary = p5_snapshot.get(&"codex", {})
		codex_button.text = "작전 도감 · %d/%d" % [
			int(p5_codex.get(&"completed_count", 0)), int(p5_codex.get(&"entry_count", 0)),
		]
	var unlocks: Array = profile_snapshot.get(&"unlock_ids", [])
	if p5_hub_progression_service == null:
		shop_button.text = (
		"상점 · 산업 지구 해금"
		if &"region_industrial_district" not in unlocks
		else "상점 · 연구 단지 해금"
		if &"region_research_complex" not in unlocks
		else "상점 · 응급키트"
		)
	var selected_tier := selected_map_size if selected_map_size in MAP_TIER_IDS else features.map_size
	var tier_path := MAP_CONFIG_PATH_PATTERN % selected_tier
	var quote: Dictionary = {}
	if operation_contract_service != null and ResourceLoader.exists(tier_path):
		quote = operation_contract_service.call(
			&"quote", load(tier_path), penalty_snapshot, _operation_investment_context()
		)
	var loot_briefing := {}
	if loot_table_provider != null:
		loot_briefing = loot_table_provider.call(&"get_briefing", {
			&"region_id": contract_snapshot.get(&"selected_region_id", &"ruined_city"),
			&"difficulty_id": contract_snapshot.get(&"selected_difficulty_id", &"standard"),
			&"map_size": StringName(selected_tier),
			&"high_grade_drop_multiplier": quote.get(&"high_grade_drop_multiplier", 1.0),
			&"boss_available": true,
		})
	contract_summary.text = "선택 계약 · 투입 %d C%s · 회수 ×%.2f · 고등급 ×%.2f · %s" % [
		int(quote.get(&"entry_cost", 0)),
		" 무료 지원" if bool(quote.get(&"bankruptcy_protection", false)) else "",
		float(quote.get(&"reward_multiplier", 1.0)),
		float(quote.get(&"high_grade_drop_multiplier", 1.0)),
		"보스 확정" if bool(quote.get(&"boss_spawn_guaranteed", false)) else "일반 생성",
	]
	for tier_id in MAP_TIER_IDS:
		_configure_tier_button(
			{"small": small_map_button, "medium": medium_map_button, "large": large_map_button}[tier_id],
			tier_id
		)
	if operation_setup_presenter != null and ResourceLoader.exists(tier_path):
		var tier_config: Resource = load(tier_path)
		var spawn_snapshot := {}
		var spawn_path := SPAWN_CONFIG_PATH_PATTERN % selected_tier
		if ResourceLoader.exists(spawn_path):
			var spawn_config: Resource = load(spawn_path)
			spawn_snapshot = {
				&"minimum_enemies": int(spawn_config.get("minimum_active_enemies")),
				&"maximum_enemies": int(spawn_config.get("maximum_active_enemies")),
			}
		operation_setup_presenter.call(&"update", {
			&"tier_id": StringName(selected_tier),
			&"region_id": contract_snapshot.get(&"selected_region_id", &"ruined_city"),
			&"region_name": contract_snapshot.get(&"selected_region_name", "기본"),
			&"difficulty_id": contract_snapshot.get(&"selected_difficulty_id", &"standard"),
			&"difficulty_name": contract_snapshot.get(&"selected_difficulty_name", "표준"),
			&"quote": quote,
			&"season": conditional_ranking_system.call(&"get_season_briefing", quote) if conditional_ranking_system != null and conditional_ranking_system.has_method(&"get_season_briefing") else {},
			&"character": (
				character_selection_service.call(&"get_snapshot")
				if character_selection_service != null else {}
			),
			&"loadout_investment": (
				loadout_investment_service.call(&"get_snapshot")
				if loadout_investment_service != null else {}
			),
			&"p5_progression": (
				p5_hub_progression_service.call(&"get_snapshot")
				if p5_hub_progression_service != null else {}
			),
			&"penalty_names": penalty_names,
			&"loadout": "응급키트" if not loadout.is_empty() else "비어 있음",
			&"can_launch": not ({
				"small": small_map_button, "medium": medium_map_button, "large": large_map_button,
			}[selected_tier] as Button).disabled and (
				loadout_investment_service == null
				or bool(loadout_investment_service.call(&"can_launch"))
			),
			&"map": {
				&"display_name": tier_config.get("display_name"),
				&"target_seconds": tier_config.get("target_run_duration_seconds"),
				&"minimum_rooms": tier_config.get("minimum_rooms"),
				&"maximum_rooms": tier_config.get("maximum_rooms"),
			},
			&"spawn": spawn_snapshot,
			&"loot_briefing": loot_briefing,
		})


func start_run(map_size: String) -> bool:
	if run_started:
		return false
	if map_size not in MAP_TIER_IDS:
		_report_configuration_error("지원하지 않는 맵 등급입니다: %s" % map_size)
		return false
	if not _tier_resources_are_available(map_size):
		return false
	if (
		loadout_investment_service != null
		and not bool(loadout_investment_service.call(&"can_launch"))
	):
		var errors: PackedStringArray = loadout_investment_service.call(&"get_selection_errors")
		status_label.text = "작전 투입 실패 · %s" % " / ".join(errors)
		_refresh_contract_setup_ui()
		return false
	var pending_config: Resource = load(MAP_CONFIG_PATH_PATTERN % map_size)
	_capture_prepared_loadout()
	if desktop_progress != null and not bool(desktop_progress.call(&"flush")):
		status_label.text = "출격 보류 · 로컬 저장 오류를 확인하세요. 기존 데이터는 유지됩니다."
		_close_run_setup()
		return false
	var launch_plan: Dictionary = {}
	if operation_contract_service != null:
		var penalty_snapshot: Dictionary = (
			penalty_system.call(&"get_snapshot") if penalty_system != null else {}
		)
		var investment_context := _operation_investment_context()
		if operation_launch_preflight_service != null:
			launch_plan = operation_launch_preflight_service.call(
				&"create_plan", pending_config, penalty_snapshot, {
					&"equipment_state": prepared_equipment_state,
					&"inventory_state": prepared_inventory_state,
					&"map_seed": features.map_seed,
				}
			)
			if not bool(launch_plan.get(&"success", false)):
				status_label.text = "작전 사전검증 실패 · %s" % launch_plan.get(&"reason", "설정 오류")
				_refresh_contract_setup_ui()
				return false
			investment_context = launch_plan.get(&"investment_context", {})
		if p5_hub_progression_service != null:
			var draft: Dictionary = p5_hub_progression_service.call(
				&"create_operation_draft", pending_config, penalty_snapshot, investment_context
			)
			active_contract = p5_hub_progression_service.call(
				&"confirm_operation_draft", StringName(draft.get(&"draft_id", &"")),
				pending_config, penalty_snapshot, investment_context
			)
		else:
			active_contract = operation_contract_service.call(
				&"invest", pending_config, penalty_snapshot, investment_context
			)
		if not bool(active_contract.get(&"success", false)):
			status_label.text = "작전 투입 실패 · %s" % active_contract.get(&"reason", "크레딧 부족")
			_refresh_contract_setup_ui()
			return false
		if (
			operation_launch_preflight_service != null
			and not bool(operation_launch_preflight_service.call(
				&"contract_matches_plan", launch_plan, active_contract
			))
		):
			_rollback_operation_investment()
			status_label.text = "작전 투입 실패 · 사전검증 계획과 결제 계약이 달라졌습니다."
			_refresh_contract_setup_ui()
			return false
	if persistent_profile != null:
		consumed_run_items = persistent_profile.call(&"consume_loadout_for_run")

	selected_map_size = map_size
	run_sequence += 1
	# Match the cross-platform anonymous identity strategy; ticks alone reset on restart.
	var run_identity_seed := "%d|%d|%d|%d" % [Time.get_unix_time_from_system(), Time.get_ticks_usec(), randi(), run_sequence]
	current_run_id = StringName(run_identity_seed.sha256_text().left(32))
	run_combat_metrics.reset()
	active_ranking_context = conditional_ranking_system.call(&"get_season_briefing", active_contract).get(&"context", {}) if conditional_ranking_system != null and conditional_ranking_system.has_method(&"get_season_briefing") else {}
	if p5_hub_progression_service != null and not bool(
		p5_hub_progression_service.call(&"begin_run", current_run_id)
	):
		_rollback_operation_investment()
		status_label.text = "작전 투입 실패 · 유틸리티 런 상태 오류"
		return false
	if (
		loadout_investment_service != null
		and not bool(loadout_investment_service.call(&"commit_run_purchase", current_run_id))
	):
		_rollback_operation_investment()
		status_label.text = "작전 투입 실패 · 런 장비 구매 확정 오류"
		_refresh_contract_setup_ui()
		return false
	_prepare_run_skill_bindings()
	if desktop_progress != null and not bool(desktop_progress.call(&"begin_run", current_run_id, active_contract)):
		_rollback_operation_investment()
		status_label.text = "출격 보류 · 작전 시작 상태를 저장하지 못했습니다."
		_close_run_setup()
		return false
	last_loot_settlement.clear()
	get_tree().paused = false
	_clear_start_hub()
	active_launch_plan = launch_plan.duplicate(true)
	run_started = true
	run_setup_overlay.visible = false
	hud_margin.visible = true
	map_label.visible = features.map_generation_enabled
	status_label.text = "%s 작전 생성 중..." % _selected_map_display_name()
	if not _assemble_game():
		var assembly_failure_message := status_label.text
		_rollback_operation_investment()
		run_started = false
		hud_margin.visible = false
		_return_to_start_hub(false)
		if features.start_hub_enabled:
			_install_start_hub()
		else:
			run_setup_overlay.visible = true
			get_tree().paused = true
			operation_setup_presenter.call(&"reset_steps")
		status_label.text = "작전 생성 실패 · %s" % assembly_failure_message
		return false
	if is_instance_valid(operation_tutorial_overlay):
		operation_tutorial_overlay.call(&"show_first_operation")
	return true


func _rollback_operation_investment() -> void:
	if desktop_progress != null:
		desktop_progress.call(&"cancel_run")
	_restore_run_skill_bindings()
	if p5_hub_progression_service != null:
		p5_hub_progression_service.call(&"settle_run", false, {})
	if loadout_investment_service != null:
		loadout_investment_service.call(&"finish_run")
	if persistent_profile != null and not active_contract.is_empty():
		persistent_profile.call(&"add_credits", int(active_contract.get(&"entry_cost", 0)))
	for item_id in consumed_run_items:
		persistent_profile.call(&"add_warehouse_item", item_id, 1)
	consumed_run_items.clear()
	if operation_contract_service != null:
		operation_contract_service.call(&"clear_active_contract")
	active_contract.clear()
	active_launch_plan.clear()
	if operation_launch_preflight_service != null:
		operation_launch_preflight_service.call(&"clear_plan")
	current_run_id = &""
	active_ranking_context.clear()


func _install_start_hub() -> bool:
	start_hub = _instantiate_feature(START_HUB_SCENE_PATH, world_container, &"StartHub")
	if (
		not _supports_methods(start_hub, START_HUB_METHODS)
		or not start_hub.has_signal(&"operation_requested")
		or not start_hub.has_signal(&"interaction_availability_changed")
	):
		_report_configuration_error("시작 거점 모듈의 공개 계약이 올바르지 않습니다.")
		return false
	player = _instantiate_feature(PLAYER_SCENE_PATH, actors_container, &"HubPlayer")
	if not _supports_methods(player, PLAYER_METHODS):
		_report_configuration_error("시작 거점 플레이어를 설치하지 못했습니다.")
		return false
	player.global_position = start_hub.call(&"get_spawn_position")
	if conditional_ranking_system != null:
		conditional_ranking_system.call(&"attach_honor_presentation", player, true)
	player.call(&"configure_damage", false)
	if not _install_hub_loadout_views():
		return false
	start_hub.connect(&"operation_requested", Callable(self, &"_open_run_setup"))
	start_hub.connect(
		&"interaction_availability_changed",
		Callable(self, &"_on_interaction_availability_changed")
	)
	run_started = false
	run_ended = false
	hud_margin.visible = false
	start_hub_hud.visible = true
	interaction_label.visible = false
	status_label.text = "거점 준비 · I 가방 · U 장비 · E 모듈·파츠 · Q 무기 · F 작전 게이트"
	return true


func _install_hub_loadout_views() -> bool:
	if features.equipment_enabled and not _install_equipment():
		return false
	if features.inventory_enabled and not _install_inventory():
		return false
	if features.equipment_customization_enabled and not _install_equipment_workbench(false):
		return false
	if desktop_progress != null:
		desktop_progress.call(&"bind_hub", inventory_system, equipment_system)
	if operation_launch_preflight_service != null:
		for registration in [
			[&"equipment", equipment_system],
			[&"inventory", inventory_system],
		]:
			var provider: Node = registration[1]
			if provider != null and not bool(operation_launch_preflight_service.call(
				&"register_validator", registration[0], provider
			)):
				return false
	return true


func _open_run_setup() -> void:
	if run_started or start_hub == null:
		return
	run_setup_overlay.visible = true
	start_hub_hud.visible = false
	interaction_label.visible = false
	get_tree().paused = true
	if is_instance_valid(mobile_control_pad):
		mobile_control_pad.call(&"set_context_enabled", false)
	operation_setup_presenter.call(&"reset_steps")
	_refresh_contract_setup_ui()


func _close_run_setup() -> void:
	if run_started:
		return
	if not is_instance_valid(start_hub) or not is_instance_valid(player):
		run_setup_overlay.visible = false
		_show_initialization_recovery("작전 설정을 닫았지만 거점 상태가 없어 복구했습니다.")
		return
	run_setup_overlay.visible = false
	get_tree().paused = false
	if is_instance_valid(mobile_control_pad):
		mobile_control_pad.call(&"set_context_enabled", true)
	if start_hub != null and player != null:
		start_hub_hud.visible = true
		var is_near: bool = (
			player.global_position.distance_to(start_hub.call(&"get_operation_position"))
			<= float(start_hub.get("interaction_radius"))
		)
		_on_interaction_availability_changed(is_near, "F · 작전 게이트 접속")


func _clear_start_hub() -> void:
	if desktop_progress != null:
		desktop_progress.call(&"unbind_hub")
	if operation_launch_preflight_service != null:
		operation_launch_preflight_service.call(&"unregister_validator", &"equipment")
		operation_launch_preflight_service.call(&"unregister_validator", &"inventory")
	start_hub_hud.visible = false
	interaction_label.visible = false
	for node in [inventory_window, equipment_workbench, equipment_system, inventory_system]:
		_free_feature_node(node)
	inventory_window = null
	equipment_workbench = null
	equipment_system = null
	inventory_system = null
	_free_feature_node(start_hub)
	start_hub = null
	_free_feature_node(player)
	player = null


func _install_operation_tutorial() -> bool:
	operation_tutorial_overlay = _instantiate_feature(
		OPERATION_TUTORIAL_SCENE_PATH, ui_layer, &"OperationTutorial"
	)
	if not _supports_methods(operation_tutorial_overlay, OPERATION_TUTORIAL_METHODS):
		_report_configuration_error("작전 튜토리얼 모듈의 공개 계약이 올바르지 않습니다.")
		return false
	combat_hud_presenter.call(&"attach_tutorial", operation_tutorial_overlay)
	return bool(operation_tutorial_overlay.call(&"configure", _tutorial_binding_labels()))


func _tutorial_binding_labels() -> Dictionary:
	return {
		&"move": "%s%s%s%s" % [
			_binding_label(&"move_up"), _binding_label(&"move_left"),
			_binding_label(&"move_down"), _binding_label(&"move_right"),
		],
		&"dash": _binding_label(&"dash"),
		&"attack": _binding_label(&"primary_attack"),
		&"interact": _binding_label(&"interact"),
		&"map": _binding_label(&"toggle_map"),
		&"skills": "%s/%s/%s" % [
			_binding_label(&"combat_skill_1"), _binding_label(&"combat_skill_2"),
			_binding_label(&"combat_skill_3"),
		],
	}


func _return_to_start_hub(route_initial_entry: bool = true) -> void:
	if is_instance_valid(operation_tutorial_overlay):
		operation_tutorial_overlay.call(&"dismiss")
	if field_loot_acquisition_service != null:
		field_loot_acquisition_service.call(&"restore_equipment_swaps")
		field_loot_acquisition_service.call(&"restore_run_inventory")
	if lose_equipped_loadout_on_return:
		prepared_equipment_state.clear()
		lose_equipped_loadout_on_return = false
	else:
		_capture_prepared_loadout(loadout_investment_service == null)
	_restore_run_skill_bindings()
	active_launch_plan.clear()
	if operation_launch_preflight_service != null:
		operation_launch_preflight_service.call(&"clear_plan")
	if loadout_investment_service != null:
		loadout_investment_service.call(&"finish_run")
	get_tree().paused = false
	game_over_overlay.visible = false
	run_setup_overlay.visible = false
	interaction_label.visible = false
	if is_instance_valid(mobile_control_pad):
		mobile_control_pad.call(&"set_context_enabled", true)
	for node in [
		fog_of_war, minimap, inventory_window, equipment_workbench,
		run_buff_selector, combat_skill_hud, dash_cooldown_hud, session_socket_hud,
		boss_warning_hud,
	]:
		_free_feature_node(node)
	for container in [
		actors_container, enemies_container, projectiles_container,
		pickups_container, module_container,
	]:
		for child in container.get_children():
			_free_feature_node(child)
	for child in world_container.get_children():
		if child not in [
			actors_container, enemies_container, projectiles_container,
			pickups_container, $World/ArenaGrid,
		]:
			_free_feature_node(child)
	_reset_run_references()
	_reset_run_state()
	if p5_hub_progression_service != null:
		p5_hub_progression_service.call(&"refresh_hub")
	if route_initial_entry:
		_route_initial_entry()


func _free_feature_node(node: Node) -> void:
	if not is_instance_valid(node):
		return
	var parent := node.get_parent()
	if parent != null:
		parent.remove_child(node)
	node.free()


func _reset_run_references() -> void:
	player = null
	map_generator = null
	fog_of_war = null
	minimap = null
	equipment_system = null
	inventory_system = null
	inventory_window = null
	equipment_workbench = null
	extraction_zone = null
	credit_ledger = null
	loot_spawner = null
	field_loot_acquisition_service = null
	session_socket_service = null
	session_socket_hud = null
	enemy_spawner = null
	elite_pursuit_service = null
	boss_warning_hud = null
	room_encounter_system = null
	room_warp_system = null
	auto_weapon = null
	combat_skill_system = null
	combat_skill_hud = null
	dash_cooldown_hud = null
	hit_feedback_director = null
	combat_resource_system = null
	weapon_balance_service = null
	growth_balance_service = null
	progression_system = null
	health_recovery_system = null
	run_buff_system = null
	run_buff_selector = null
	meta_progression_system = null
	equipment_upgrade_service = null
	current_map_config = null


func _reset_run_state() -> void:
	run_started = false
	run_ended = false
	elapsed_time = 0.0
	extraction_unlocked = false
	defeated_enemies = 0
	run_combat_metrics.reset()
	pending_buff_levels.clear()
	active_contract.clear()
	current_run_id = &""
	active_ranking_context.clear()
	active_run_skill_loadout = null
	last_loot_settlement.clear()
	consumed_run_items.clear()
	hud_margin.visible = false
	map_label.visible = false
	time_label.text = "시간 00:00"
	level_label.text = "1"
	kills_label.text = "0"
	credit_label.text = "CR 0"
	experience_bar.value = 0.0
	experience_label.text = "0 / 5"
	combat_hud_presenter.call(&"set_interaction_active", false)
	combat_hud_presenter.call(&"set_survival_ratio", 1.0)
	combat_hud_presenter.call(&"reset_status_priority")


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
	if conditional_ranking_system != null:
		conditional_ranking_system.call(&"attach_honor_presentation", player, false)
	if (
		not _supports_methods(player, PLAYER_METHODS)
		or not player.has_signal(&"health_changed")
		or not player.has_signal(&"died")
	):
		_report_configuration_error("플레이어 모듈의 공개 계약이 올바르지 않습니다.")
		return false
	if features.map_generation_enabled and map_generator == null:
		_report_configuration_error("맵 모듈을 설치하지 못했습니다.")
		return false

	player.global_position = player_spawn_position
	player.call(&"configure_damage", features.damage_enabled)
	var character_context: Dictionary = active_contract.get(&"investment_context", {})
	var character_modifiers: Dictionary = character_context.get(&"player_runtime_modifiers", {})
	if not character_modifiers.is_empty():
		player.call(&"set_runtime_modifier_source", &"selected_character", character_modifiers)
	var player_hit_reaction: Node = player.get_node_or_null("HitReaction")
	if player_hit_reaction != null:
		player_hit_reaction.set("enabled", features.hit_feedback_enabled)
	_apply_consumable_loadout()
	player.connect(&"health_changed", Callable(self, &"_on_player_health_changed"))
	player.connect(&"died", Callable(self, &"_on_player_died"))
	var health_snapshot: Dictionary = player.call(&"get_health_snapshot")
	_on_player_health_changed(
		float(health_snapshot.get(&"current", 0.0)),
		float(health_snapshot.get(&"maximum", 1.0))
	)
	if features.hit_feedback_enabled and not _install_hit_feedback():
		return false
	if not _install_dash_cooldown_hud():
		return false
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
	if features.growth_balance_enabled and not _install_growth_balance():
		return false
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
		if not _install_loot_spawner():
			return false
	if features.combat_resources_enabled and not _install_combat_resources():
		return false

	if features.experience_enabled:
		progression_system = _instantiate_feature(PROGRESSION_SCENE_PATH, module_container, &"ProgressionSystem")
		if progression_system != null:
			progression_system.connect(&"progress_changed", Callable(self, &"_on_progress_changed"))
			progression_system.connect(&"level_increased", Callable(self, &"_on_level_increased"))
			progression_system.call(
				&"configure", pickups_container, features.leveling_enabled, player
			)
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
			if features.smart_targeting_enabled:
				if (
					not auto_weapon.has_method(&"set_targeting_policy")
					or not auto_weapon.call(
						&"set_targeting_policy", load(features.smart_targeting_policy_path)
					)
				):
					_report_configuration_error("스마트 자동 타게팅 정책을 구성하지 못했습니다.")
					return false

	if features.run_buffs_enabled and not _install_run_buffs():
		return false
	if features.meta_progression_enabled and not _install_meta_progression():
		return false
	if features.enemies_enabled and features.spawning_enabled:
		if not _install_enemy_spawner():
			return false
		if features.boss_warning_enabled and not _install_boss_warning():
			return false
	if features.room_encounters_enabled and not _install_room_encounters():
		return false
	if features.elite_pursuit_enabled and not _install_elite_pursuit():
		return false
	if features.room_warp_enabled and not _install_room_warp():
		return false
	if features.combat_skills_enabled and not _install_combat_skills():
		return false
	if features.session_sockets_enabled and not _install_session_sockets():
		return false
	if features.field_loot_acquisition_enabled and not _install_field_loot_acquisition():
		return false
	combat_hud_presenter.call(
		&"attach_runtime_layers",
		combat_skill_hud as Control,
		dash_cooldown_hud as Control,
		interaction_label,
		session_socket_hud as Control
	)

	status_label.text = (
		"작전 진행 중 · %s 기본기 · 스킬 %s/%s/%s · %s 대시 · %s 무기 · %s 상호작용"
		% [
			_binding_label(&"primary_attack"),
			_binding_label(&"combat_skill_1"),
			_binding_label(&"combat_skill_2"),
			_binding_label(&"combat_skill_3"),
			_binding_label(&"dash"),
			_binding_label(&"switch_weapon"),
			_binding_label(&"interact"),
		]
	)
	_update_run_time_hud()
	return true


func _apply_consumable_loadout() -> void:
	if hub_economy_system == null or player == null:
		return
	var effects: Dictionary = hub_economy_system.call(
		&"get_consumable_effects", consumed_run_items
	)
	var modifiers: Dictionary = effects.get(&"player_modifiers", {})
	if not modifiers.is_empty() and player.has_method(&"set_runtime_modifier_source"):
		player.call(&"set_runtime_modifier_source", &"consumable_loadout", modifiers)
	var healing := float(effects.get(&"heal", 0.0))
	if healing > 0.0 and player.has_method(&"heal"):
		player.call(&"heal", healing)


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
	health_recovery_system.call(
		&"set_recovery_multiplier",
		float(active_contract.get(&"player_modifiers", {}).get(&"recovery_multiplier", 1.0))
	)
	return true


func _install_combat_skills() -> bool:
	if not ResourceLoader.exists(features.combat_skill_loadout_path):
		_report_configuration_error("전투 스킬 로드아웃을 찾을 수 없습니다.")
		return false
	var skill_loadout: Resource = _get_active_run_skill_loadout()
	if skill_loadout == null or not skill_loadout.call(&"validation_errors").is_empty():
		_report_configuration_error("전투 스킬 로드아웃이 유효하지 않습니다.")
		return false
	combat_skill_system = _instantiate_feature(
		COMBAT_SKILL_SYSTEM_SCENE_PATH, module_container, &"CombatSkills"
	)
	if (
		not _supports_methods(combat_skill_system, COMBAT_SKILL_METHODS)
		or not combat_skill_system.has_signal(&"skill_states_changed")
		or not combat_skill_system.has_signal(&"skill_activated")
	):
		_report_configuration_error("전투 스킬 실행기의 공개 계약이 올바르지 않습니다.")
		return false
	if not combat_skill_system.call(
		&"configure",
		player,
		enemies_container,
		world_container,
		skill_loadout,
		features.damage_enabled,
		combat_resource_system,
		load(features.smart_targeting_policy_path) if features.smart_targeting_enabled else null,
		equipment_system,
		skill_binding_service
	):
		_report_configuration_error("전투 스킬 실행기를 구성하지 못했습니다.")
		return false
	combat_skill_system.connect(&"skill_activated", Callable(self, &"_on_combat_skill_activated"))
	combat_skill_hud = _instantiate_feature(
		COMBAT_SKILL_HUD_SCENE_PATH, ui_layer, &"CombatSkillHud"
	)
	if (
		not _supports_methods(combat_skill_hud, COMBAT_SKILL_HUD_METHODS)
		or not combat_skill_hud.call(&"configure", combat_skill_system)
	):
		_report_configuration_error("전투 스킬 HUD를 구성하지 못했습니다.")
		return false
	return true


func _install_session_sockets() -> bool:
	if not ResourceLoader.exists(features.session_socket_config_path):
		_report_configuration_error("세션 소켓 설정을 찾을 수 없습니다.")
		return false
	var socket_config := load(features.session_socket_config_path) as SessionSocketConfig
	if socket_config == null:
		_report_configuration_error("세션 소켓 설정 형식이 올바르지 않습니다.")
		return false
	socket_config = socket_config.duplicate(true) as SessionSocketConfig
	socket_config.source_mode = selected_balance_source_mode
	session_socket_service = _instantiate_feature(
		SESSION_SOCKET_SERVICE_SCENE_PATH, module_container, &"SessionSockets"
	)
	if (
		not _supports_methods(session_socket_service, SESSION_SOCKET_METHODS)
		or not session_socket_service.has_signal(&"socket_action")
		or not session_socket_service.has_signal(&"socket_error")
	):
		_report_configuration_error("세션 소켓 모듈의 공개 계약이 올바르지 않습니다.")
		return false
	if not session_socket_service.call(
		&"configure", socket_config, loot_lifecycle_service,
		auto_weapon, combat_skill_system, player
	):
		_report_configuration_error("세션 소켓 데이터를 전투 런타임에 연결하지 못했습니다.")
		return false
	session_socket_service.connect(
		&"socket_action", Callable(self, &"_on_session_socket_action")
	)
	session_socket_service.connect(
		&"socket_error", Callable(self, &"_on_session_socket_error")
	)
	session_socket_hud = _instantiate_feature(
		SESSION_SOCKET_HUD_SCENE_PATH, ui_layer, &"SessionSocketHud"
	)
	if (
		not _supports_methods(session_socket_hud, [&"configure", &"refresh", &"get_snapshot"])
		or not session_socket_hud.call(&"configure", session_socket_service)
	):
		_report_configuration_error("세션 소켓 HUD를 구성하지 못했습니다.")
		return false
	return true


func _install_dash_cooldown_hud() -> bool:
	dash_cooldown_hud = _instantiate_feature(
		DASH_COOLDOWN_HUD_SCENE_PATH, ui_layer, &"DashCooldownHud"
	)
	if (
		not _supports_methods(dash_cooldown_hud, DASH_COOLDOWN_HUD_METHODS)
		or not dash_cooldown_hud.call(&"configure", player)
	):
		_report_configuration_error("대시 쿨타임 HUD를 구성하지 못했습니다.")
		return false
	return true


func _install_hit_feedback() -> bool:
	var profile := load(features.hit_feedback_profile_path)
	var player_camera := player.get_node_or_null("Camera2D") as Camera2D
	hit_feedback_director = _instantiate_feature(
		HIT_FEEDBACK_SCENE_PATH, world_container, &"HitFeedback"
	)
	if (
		not _supports_methods(hit_feedback_director, HIT_FEEDBACK_METHODS)
		or profile == null
		or not hit_feedback_director.call(&"configure", player_camera, profile)
		or not hit_feedback_director.call(&"register_actor", player)
	):
		_report_configuration_error("타격 피드백 모듈을 구성하지 못했습니다.")
		return false
	return true


func _install_combat_resources() -> bool:
	if (
		not ResourceLoader.exists(features.combat_resource_config_path)
		or not ResourceLoader.exists(features.combat_skill_loadout_path)
	):
		_report_configuration_error("전투 자원 설정 또는 스킬 로드아웃을 찾을 수 없습니다.")
		return false
	combat_resource_system = _instantiate_feature(
		COMBAT_RESOURCE_SCENE_PATH, module_container, &"CombatResources"
	)
	if (
		not _supports_methods(combat_resource_system, COMBAT_RESOURCE_METHODS)
		or not combat_resource_system.has_signal(&"resources_changed")
		or not combat_resource_system.has_signal(&"pickup_collected")
	):
		_report_configuration_error("전투 자원 모듈의 공개 계약이 올바르지 않습니다.")
		return false
	if not combat_resource_system.call(
		&"configure", player, pickups_container,
		_get_active_run_skill_loadout(),
		load(features.combat_resource_config_path),
		features.map_seed
	):
		_report_configuration_error("에너지·충전·회복 드랍 정책을 구성하지 못했습니다.")
		return false
	combat_resource_system.call(
		&"set_recovery_multiplier",
		float(active_contract.get(&"player_modifiers", {}).get(&"recovery_multiplier", 1.0))
	)
	combat_resource_system.connect(
		&"pickup_collected", Callable(self, &"_on_combat_resource_pickup_collected")
	)
	return true


func _install_run_buffs() -> bool:
	if not ResourceLoader.exists(features.run_buff_catalog_path):
		_report_configuration_error("런 버프 카탈로그를 찾을 수 없습니다.")
		return false
	run_buff_system = _instantiate_feature(RUN_BUFF_SCENE_PATH, module_container, &"RunBuffs")
	if not _supports_methods(run_buff_system, RUN_BUFF_METHODS):
		_report_configuration_error("런 버프 모듈의 공개 계약이 올바르지 않습니다.")
		return false
	var run_buff_catalog: Resource = load(features.run_buff_catalog_path)
	if growth_balance_service != null:
		run_buff_catalog = growth_balance_service.call(&"get_run_buff_catalog")
	if not run_buff_system.call(&"configure", player, auto_weapon, run_buff_catalog):
		_report_configuration_error("런 버프 모듈을 구성하지 못했습니다.")
		return false
	run_buff_selector = _instantiate_feature(
		RUN_BUFF_SELECTOR_SCENE_PATH, ui_layer, &"RunBuffSelector"
	)
	if run_buff_selector == null or not run_buff_selector.has_signal(&"buff_selected"):
		_report_configuration_error("런 버프 선택 UI를 구성하지 못했습니다.")
		return false
	run_buff_selector.connect(&"buff_selected", Callable(self, &"_on_run_buff_selected"))
	_connect_modal_panel(run_buff_selector)
	return true


func _install_meta_progression() -> bool:
	meta_progression_system = _instantiate_feature(
		META_PROGRESSION_SCENE_PATH, module_container, &"MetaProgression"
	)
	if not _supports_methods(meta_progression_system, META_PROGRESSION_METHODS):
		_report_configuration_error("외부 성장 모듈의 공개 계약이 올바르지 않습니다.")
		return false
	var persistence_enabled := not OS.get_cmdline_args().has("--script") or desktop_progress != null
	if not meta_progression_system.call(
		&"configure", features.meta_progression_storage_path, persistence_enabled,
		persistence_enabled and not OS.has_feature("web")
	):
		return false
	meta_progression_system.call(
		&"apply_to_targets", player, auto_weapon, equipment_system
	)
	if desktop_progress != null:
		if not bool(desktop_progress.call(&"register_storage_provider", meta_progression_system)):
			return false
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
	var configured := bool(equipment_upgrade_service.call(
		&"configure",
		equipment_system,
		inventory_system,
		credit_ledger,
		load(features.equipment_upgrade_policy_path)
	))
	if configured and growth_balance_service != null:
		configured = bool(equipment_upgrade_service.call(
			&"set_balance_provider", growth_balance_service
		))
	return configured


func _install_growth_balance() -> bool:
	if not ResourceLoader.exists(features.growth_balance_config_path):
		_report_configuration_error("성장 밸런스 설정을 찾을 수 없습니다.")
		return false
	growth_balance_service = _instantiate_feature(
		GROWTH_BALANCE_SCENE_PATH, module_container, &"GrowthBalance"
	)
	if not _supports_growth_balance(growth_balance_service):
		_report_configuration_error("성장 밸런스 모듈의 공개 계약이 올바르지 않습니다.")
		return false
	growth_balance_service.connect(
		&"growth_balance_error", Callable(self, &"_on_growth_balance_error")
	)
	growth_balance_service.connect(
		&"growth_balance_updated", Callable(self, &"_on_growth_balance_updated")
	)
	var growth_config: Resource = load(features.growth_balance_config_path)
	if growth_config == null:
		_report_configuration_error("성장 밸런스 설정 형식이 올바르지 않습니다.")
		return false
	growth_config = growth_config.duplicate(true)
	growth_config.set("source_mode", selected_balance_source_mode)
	if not growth_balance_service.call(&"configure", growth_config):
		_report_configuration_error("성장 밸런스 데이터를 불러오지 못했습니다.")
		return false
	if not equipment_system.call(&"set_upgrade_balance_provider", growth_balance_service):
		_report_configuration_error("장비에 성장 밸런스 제공자를 연결하지 못했습니다.")
		return false
	return true


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


func _install_loot_lifecycle() -> bool:
	if not ResourceLoader.exists(features.loot_lifecycle_config_path):
		_report_configuration_error("전리품 생명 주기 설정을 찾을 수 없습니다.")
		return false
	loot_lifecycle_service = _instantiate_feature(
		LOOT_LIFECYCLE_SCENE_PATH, self, &"LootLifecycle"
	)
	if not _supports_loot_lifecycle(loot_lifecycle_service):
		_report_configuration_error("전리품 생명 주기 모듈의 공개 계약이 올바르지 않습니다.")
		return false
	loot_lifecycle_service.connect(
		&"lifecycle_error", Callable(self, &"_on_loot_lifecycle_error")
	)
	var lifecycle_config := load(features.loot_lifecycle_config_path) as LootLifecycleConfig
	if lifecycle_config == null:
		_report_configuration_error("전리품 생명 주기 설정 형식이 올바르지 않습니다.")
		return false
	lifecycle_config = lifecycle_config.duplicate(true) as LootLifecycleConfig
	lifecycle_config.source_mode = selected_balance_source_mode
	if not loot_lifecycle_service.call(&"configure", lifecycle_config):
		_report_configuration_error("전리품 생명 주기 데이터를 불러오지 못했습니다.")
		return false
	return true


func _install_run_settlement() -> bool:
	if (
		loot_lifecycle_service == null
		or persistent_profile == null
		or not ResourceLoader.exists(features.operation_result_config_path)
	):
		_report_configuration_error("런 전리품 정산 모듈의 생명 주기·프로필 의존성이 없습니다.")
		return false
	run_settlement_service = _instantiate_feature(
		RUN_SETTLEMENT_SCENE_PATH, self, &"RunSettlement"
	)
	if (
		not _supports_methods(run_settlement_service, RUN_SETTLEMENT_METHODS)
		or not run_settlement_service.has_signal(&"run_loot_settled")
		or not run_settlement_service.call(
			&"configure", loot_lifecycle_service, persistent_profile,
			load(features.operation_result_config_path), field_loot_equip_catalog
		)
	):
		_report_configuration_error("런 전리품 정산 모듈의 공개 계약이 올바르지 않습니다.")
		return false
	return true


func _install_loot_table_provider() -> bool:
	if loot_lifecycle_service == null or not ResourceLoader.exists(features.loot_table_config_path):
		_report_configuration_error("드랍 테이블 제공자의 생명 주기·설정 의존성이 준비되지 않았습니다.")
		return false
	loot_table_provider = _instantiate_feature(
		LOOT_TABLE_PROVIDER_SCENE_PATH, self, &"LootTableProvider"
	)
	if not _supports_methods(loot_table_provider, LOOT_TABLE_METHODS):
		_report_configuration_error("드랍 테이블 제공자의 공개 계약이 올바르지 않습니다.")
		return false
	loot_table_provider.connect(&"table_error", Callable(self, &"_on_loot_table_error"))
	loot_table_provider.connect(&"table_updated", Callable(self, &"_on_loot_table_updated"))
	var table_config := load(features.loot_table_config_path) as LootTableConfig
	if table_config == null:
		_report_configuration_error("드랍 테이블 설정 형식이 올바르지 않습니다.")
		return false
	table_config = table_config.duplicate(true) as LootTableConfig
	table_config.source_mode = selected_balance_source_mode
	if not loot_table_provider.call(
		&"configure", table_config, loot_lifecycle_service, field_loot_equip_catalog
	):
		_report_configuration_error("지역·난이도 드랍 테이블을 불러오지 못했습니다.")
		return false
	return true


func _configure_balance_mode_selector() -> void:
	balance_mode_section.visible = (
		features.weapon_balance_enabled
		or features.growth_balance_enabled
		or features.loot_lifecycle_enabled
		or features.loot_tables_enabled
		or features.session_sockets_enabled
		or features.character_selection_enabled
		or features.loadout_investment_enabled
	)
	if not balance_mode_section.visible:
		return
	var balance_config := load(features.weapon_balance_config_path) as WeaponBalanceConfig
	var growth_config: Resource = load(features.growth_balance_config_path)
	var lifecycle_config := load(features.loot_lifecycle_config_path) as LootLifecycleConfig
	var loot_table_config := load(features.loot_table_config_path) as LootTableConfig
	var session_socket_config := (
		load(features.session_socket_config_path) as SessionSocketConfig
		if features.session_sockets_enabled else null
	)
	var character_config := (
		load(features.character_selection_config_path) as CharacterSelectionConfig
		if features.character_selection_enabled else null
	)
	var loadout_investment_config := (
		load(features.loadout_investment_config_path) as LoadoutInvestmentConfig
		if features.loadout_investment_enabled else null
	)
	if (
		balance_config == null
		or (features.growth_balance_enabled and growth_config == null)
		or (features.loot_lifecycle_enabled and lifecycle_config == null)
		or (features.loot_tables_enabled and loot_table_config == null)
		or (features.session_sockets_enabled and session_socket_config == null)
		or (features.character_selection_enabled and character_config == null)
		or (features.loadout_investment_enabled and loadout_investment_config == null)
	):
		live_balance_button.disabled = true
		_select_balance_source_mode(WeaponBalanceConfig.SourceMode.LOCKED_CSV)
		balance_mode_description.text = "밸런스 설정을 읽을 수 없어 확정 CSV만 선택할 수 있습니다."
		return
	live_balance_button.disabled = balance_config.live_csv_url.is_empty()
	if features.growth_balance_enabled:
		live_balance_button.disabled = (
			live_balance_button.disabled
			or growth_config.live_run_buff_csv_url.is_empty()
			or growth_config.live_upgrade_csv_url.is_empty()
		)
	if features.loot_lifecycle_enabled:
		live_balance_button.disabled = (
			live_balance_button.disabled or lifecycle_config.live_csv_url.is_empty()
		)
	if features.loot_tables_enabled:
		live_balance_button.disabled = (
			live_balance_button.disabled or loot_table_config.live_csv_url.is_empty()
		)
	if features.session_sockets_enabled:
		live_balance_button.disabled = (
			live_balance_button.disabled or session_socket_config.live_csv_url.is_empty()
		)
	if features.character_selection_enabled:
		live_balance_button.disabled = (
			live_balance_button.disabled or character_config.live_csv_url.is_empty()
		)
	if features.loadout_investment_enabled:
		live_balance_button.disabled = (
			live_balance_button.disabled
			or loadout_investment_config.live_weapon_csv_url.is_empty()
			or loadout_investment_config.live_skill_csv_url.is_empty()
		)
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
	if conditional_ranking_system != null:
		conditional_ranking_system.call(&"set_reward_source_mode", source_mode)
	locked_balance_button.button_pressed = (
		source_mode == WeaponBalanceConfig.SourceMode.LOCKED_CSV
	)
	live_balance_button.button_pressed = (
		source_mode == WeaponBalanceConfig.SourceMode.LIVE_GOOGLE_SHEET
	)
	if source_mode == WeaponBalanceConfig.SourceMode.LIVE_GOOGLE_SHEET:
		balance_mode_description.text = (
			"Weapon·Skill·Item·LootTable·RunAsset·RunBuff·Upgrade·Character Sheet를 기본 3초마다 다시 읽습니다. 실패 시 확정 CSV로 복구합니다."
		)
	else:
		balance_mode_description.text = (
			"무기·스킬 투자·아이템 생명 주기·지역 드랍·런 소켓·내부 성장·장비 강화·캐릭터의 저장소 확정 CSV를 사용합니다. 배포에 권장됩니다."
		)
	_reconfigure_persistent_loot_data()


func _reconfigure_persistent_loot_data() -> void:
	if loadout_investment_service != null:
		var investment_config := load(
			features.loadout_investment_config_path
		) as LoadoutInvestmentConfig
		if investment_config != null:
			investment_config = investment_config.duplicate(true) as LoadoutInvestmentConfig
			investment_config.source_mode = selected_balance_source_mode
			loadout_investment_service.call(
				&"configure", investment_config, persistent_profile
			)
	if character_selection_service != null:
		var character_config := load(features.character_selection_config_path) as CharacterSelectionConfig
		if character_config != null:
			character_config = character_config.duplicate(true) as CharacterSelectionConfig
			character_config.source_mode = selected_balance_source_mode
			character_selection_service.call(&"configure", character_config)
	if loot_lifecycle_service != null:
		var lifecycle_config := load(features.loot_lifecycle_config_path) as LootLifecycleConfig
		if lifecycle_config != null:
			lifecycle_config = lifecycle_config.duplicate(true) as LootLifecycleConfig
			lifecycle_config.source_mode = selected_balance_source_mode
			loot_lifecycle_service.call(&"configure", lifecycle_config)
	if loot_table_provider != null and loot_lifecycle_service != null:
		var table_config := load(features.loot_table_config_path) as LootTableConfig
		if table_config != null:
			table_config = table_config.duplicate(true) as LootTableConfig
			table_config.source_mode = selected_balance_source_mode
			loot_table_provider.call(
				&"configure", table_config, loot_lifecycle_service, field_loot_equip_catalog
			)
	_refresh_contract_setup_ui()


func _load_field_loot_equip_catalog() -> bool:
	field_loot_equip_catalog = load(features.field_loot_equip_catalog_path) as FieldLootEquipCatalog
	if (
		field_loot_equip_catalog == null
		or not field_loot_equip_catalog.validation_errors().is_empty()
	):
		_report_configuration_error("현장 즉시 장착 카탈로그가 올바르지 않습니다.")
		return false
	return true


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
	if (
		not prepared_equipment_state.is_empty()
		and not equipment_system.call(&"restore_runtime_state", prepared_equipment_state)
	):
		_report_configuration_error("준비한 장비 로드아웃을 복구하지 못했습니다.")
		return false
	if not _apply_run_weapon_selection():
		_report_configuration_error("선택한 런 무기 로드아웃을 적용하지 못했습니다.")
		return false
	equipment_system.connect(
		&"active_weapon_changed", Callable(self, &"_on_active_weapon_changed")
	)
	if not equipment_system.call(&"set_active_weapon_slot", preferred_weapon_slot):
		preferred_weapon_slot = &"main"
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
	if (
		not prepared_inventory_state.is_empty()
		and not inventory_system.call(&"restore_runtime_state", prepared_inventory_state)
	):
		_report_configuration_error("준비한 가방 상태를 복구하지 못했습니다.")
		return false
	inventory_window = _instantiate_feature(
		INVENTORY_WINDOW_SCENE_PATH, ui_layer, &"GridInventoryWindow"
	)
	if inventory_window == null or not _supports_panel(inventory_window):
		_report_configuration_error("가방 UI 모듈의 공개 계약이 올바르지 않습니다.")
		return false
	inventory_window.call(&"configure", inventory_system, equipment_system)
	inventory_window.connect(&"settings_saved", _on_inventory_settings_saved)
	inventory_window.connect(&"external_panel_requested", _open_inventory_destination)
	_connect_modal_panel(inventory_window)
	return true


func _open_inventory_destination(action: StringName) -> void:
	if action == &"toggle_equipment" and is_instance_valid(equipment_workbench):
		equipment_workbench.call(&"show_weapon_tab")
	elif action == &"toggle_modification" and is_instance_valid(equipment_workbench):
		equipment_workbench.call(&"show_modification_tab")
	elif action == &"toggle_key_mapping" and is_instance_valid(key_mapping_panel):
		key_mapping_panel.call(&"open_panel")
	elif action == &"toggle_map" and is_instance_valid(minimap):
		minimap.call(&"set_expanded", true)


func _on_inventory_settings_saved() -> void:
	# Combat edits remain run-owned; death/settlement retain their existing authority.
	if not run_started:
		_capture_prepared_loadout()


func _capture_prepared_loadout(include_equipment: bool = true) -> void:
	if include_equipment and is_instance_valid(equipment_system) and equipment_system.has_method(&"export_runtime_state"):
		prepared_equipment_state = equipment_system.call(&"export_runtime_state")
	if is_instance_valid(inventory_system) and inventory_system.has_method(&"export_runtime_state"):
		prepared_inventory_state = inventory_system.call(&"export_runtime_state")


func _apply_run_weapon_selection() -> bool:
	if equipment_system == null or active_contract.is_empty():
		return true
	var context: Dictionary = active_contract.get(&"investment_context", {})
	var investment: Dictionary = context.get(&"loadout_investment", {})
	var weapon_paths: Dictionary = investment.get(&"weapon_paths", {})
	for slot_id in weapon_paths:
		var path := String(weapon_paths[slot_id])
		if not ResourceLoader.exists(path):
			return false
		var definition: Resource = load(path)
		var current: Resource = equipment_system.call(&"get_weapon", StringName(slot_id))
		if current != null and current.get("weapon_id") == definition.get("weapon_id"):
			continue
		if not bool(equipment_system.call(&"equip_definition", StringName(slot_id), definition)):
			return false
	return true


func _get_active_run_skill_loadout() -> Resource:
	if active_run_skill_loadout != null:
		return active_run_skill_loadout
	if not ResourceLoader.exists(features.combat_skill_loadout_path):
		return null
	active_run_skill_loadout = load(features.combat_skill_loadout_path).duplicate(true)
	var context: Dictionary = active_contract.get(&"investment_context", {})
	var investment: Dictionary = context.get(&"loadout_investment", {})
	var skill_paths: Dictionary = investment.get(&"skill_paths", {})
	for slot_key in skill_paths:
		var slot_index := int(slot_key)
		var path := String(skill_paths[slot_key])
		if (
			slot_index >= 0
			and slot_index < active_run_skill_loadout.get("skills").size()
			and ResourceLoader.exists(path)
		):
			active_run_skill_loadout.get("skills")[slot_index] = load(path)
	return active_run_skill_loadout


func _prepare_run_skill_bindings() -> void:
	_restore_run_skill_bindings()
	if skill_binding_service == null:
		return
	var default_loadout: Resource = load(features.combat_skill_loadout_path)
	var selected_loadout := _get_active_run_skill_loadout()
	if default_loadout == null or selected_loadout == null:
		return
	for index in mini(default_loadout.skills.size(), selected_loadout.skills.size()):
		var previous: Resource = default_loadout.skills[index]
		var selected: Resource = selected_loadout.skills[index]
		var previous_id: StringName = previous.get("skill_id")
		var selected_id: StringName = selected.get("skill_id")
		if previous_id == selected_id:
			continue
		var action_id: StringName = previous.get("input_action")
		if bool(skill_binding_service.call(
			&"replace_runtime_skill", previous_id, selected_id, action_id
		)):
			run_skill_binding_replacements.append({
				&"previous_skill_id": previous_id, &"current_skill_id": selected_id,
				&"action_id": action_id,
			})


func _restore_run_skill_bindings() -> void:
	if skill_binding_service != null:
		for index in range(run_skill_binding_replacements.size() - 1, -1, -1):
			var replacement: Dictionary = run_skill_binding_replacements[index]
			skill_binding_service.call(
				&"restore_runtime_skill", replacement[&"current_skill_id"],
				replacement[&"previous_skill_id"], replacement[&"action_id"]
			)
	run_skill_binding_replacements.clear()


func _install_equipment_workbench(read_only: bool = false) -> bool:
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
		&"configure", equipment_system, inventory_system, equipment_upgrade_service, read_only
	):
		_report_configuration_error("장비 개조 UI를 연결하지 못했습니다.")
		return false
	_connect_modal_panel(equipment_workbench)
	return true


func _connect_modal_panel(panel: Node) -> void:
	if panel == null or not panel.has_signal(&"panel_visibility_changed"):
		return
	var callback := Callable(self, &"_on_modal_panel_visibility_changed")
	if not panel.is_connected(&"panel_visibility_changed", callback):
		panel.connect(&"panel_visibility_changed", callback)


func _on_modal_panel_visibility_changed(is_open: bool) -> void:
	if is_open:
		if modal_ui_visibility_snapshot.is_empty():
			modal_ui_visibility_snapshot = {
				&"hud": hud_margin.visible,
				&"hub": start_hub_hud.visible,
				&"setup": run_setup_overlay.visible,
				&"interaction": interaction_label.visible,
				&"skills": is_instance_valid(combat_skill_hud) and combat_skill_hud.visible,
				&"dash": is_instance_valid(dash_cooldown_hud) and dash_cooldown_hud.visible,
				&"minimap": is_instance_valid(minimap) and minimap.visible,
				&"tutorial": (
					is_instance_valid(operation_tutorial_overlay)
					and operation_tutorial_overlay.visible
				),
			}
		hud_margin.visible = false
		start_hub_hud.visible = false
		run_setup_overlay.visible = false
		interaction_label.visible = false
		if is_instance_valid(combat_skill_hud):
			combat_skill_hud.visible = false
		if is_instance_valid(dash_cooldown_hud):
			dash_cooldown_hud.visible = false
		if is_instance_valid(minimap):
			minimap.visible = false
		if is_instance_valid(operation_tutorial_overlay):
			operation_tutorial_overlay.visible = false
		if is_instance_valid(mobile_control_pad):
			mobile_control_pad.call(&"set_context_enabled", false)
		return
	for panel in get_tree().get_nodes_in_group(&"game_modal_panel"):
		if panel is CanvasItem and panel.visible:
			return
	if modal_ui_visibility_snapshot.is_empty():
		return
	hud_margin.visible = bool(modal_ui_visibility_snapshot.get(&"hud", false))
	start_hub_hud.visible = bool(modal_ui_visibility_snapshot.get(&"hub", false))
	run_setup_overlay.visible = bool(modal_ui_visibility_snapshot.get(&"setup", false))
	interaction_label.visible = bool(modal_ui_visibility_snapshot.get(&"interaction", false))
	if is_instance_valid(combat_skill_hud):
		combat_skill_hud.visible = bool(modal_ui_visibility_snapshot.get(&"skills", false))
	if is_instance_valid(dash_cooldown_hud):
		dash_cooldown_hud.visible = bool(modal_ui_visibility_snapshot.get(&"dash", false))
	if is_instance_valid(minimap):
		minimap.visible = bool(modal_ui_visibility_snapshot.get(&"minimap", false))
	if is_instance_valid(operation_tutorial_overlay):
		operation_tutorial_overlay.visible = bool(
			modal_ui_visibility_snapshot.get(&"tutorial", false)
		)
	if is_instance_valid(mobile_control_pad):
		mobile_control_pad.call(&"set_context_enabled", true)
	modal_ui_visibility_snapshot.clear()


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
	extraction_zone.connect(
		&"extraction_defense_started", Callable(self, &"_on_extraction_defense_started")
	)
	extraction_zone.connect(
		&"extraction_defense_cancelled", Callable(self, &"_on_extraction_defense_cancelled")
	)
	extraction_zone.connect(
		&"extraction_defense_paused", Callable(self, &"_on_extraction_defense_paused")
	)
	extraction_zone.connect(
		&"extraction_defense_resumed", Callable(self, &"_on_extraction_defense_resumed")
	)
	extraction_zone.call(
		&"configure", map_generator.call(&"get_extraction_position"),
		_extraction_defense_duration()
	)
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


func _install_loot_spawner() -> bool:
	var loot_config_path := LOOT_CONFIG_PATH_PATTERN % selected_map_size
	if not ResourceLoader.exists(loot_config_path):
		_report_configuration_error("파밍 설정을 찾을 수 없습니다: %s" % loot_config_path)
		return false
	var loot_config := load(loot_config_path)
	loot_spawner = _instantiate_feature(LOOT_SPAWNER_SCENE_PATH, module_container, &"LootSpawner")
	if loot_spawner == null:
		return false
	if not _supports_loot_spawner(loot_spawner):
		_report_configuration_error("파밍 모듈이 필수 공개 계약을 구현하지 않았습니다.")
		loot_spawner.queue_free()
		loot_spawner = null
		return false
	loot_spawner.connect(&"credits_looted", Callable(self, &"_on_credits_looted"))
	loot_spawner.connect(
		&"interaction_availability_changed",
		Callable(self, &"_on_interaction_availability_changed")
	)
	if not loot_spawner.call(
		&"configure",
		map_generator,
		pickups_container,
		loot_config,
		int(active_contract.get(&"entry_cost", current_map_config.get("entry_cost")))
	):
		_report_configuration_error("파밍 모듈이 선택된 회수 배수 목표를 충족하지 못했습니다.")
		return false
	return true


func _install_enemy_spawner() -> bool:
	var spawn_config_path := SPAWN_CONFIG_PATH_PATTERN % selected_map_size
	if not ResourceLoader.exists(spawn_config_path):
		_report_configuration_error("적 생성 설정을 찾을 수 없습니다: %s" % spawn_config_path)
		return false
	var spawn_config := load(spawn_config_path)
	if (
		spawn_config == null
		or not spawn_config.has_method(&"is_valid")
		or not spawn_config.call(&"is_valid")
	):
		_report_configuration_error("적 생성 설정이 유효하지 않습니다: %s" % spawn_config_path)
		return false
	enemy_spawner = _instantiate_feature(SPAWNER_SCENE_PATH, module_container, &"EnemySpawner")
	if not _supports_enemy_spawner(enemy_spawner):
		_report_configuration_error("적 생성 모듈의 공개 계약이 올바르지 않습니다.")
		return false
	enemy_spawner.connect(&"enemy_spawned", Callable(self, &"_on_enemy_spawned"))
	if not enemy_spawner.call(
		&"configure",
		player,
		enemies_container,
		features.damage_enabled,
		map_generator,
		features.enemy_armor_enabled,
		features.enemy_status_ui_enabled,
		spawn_config,
		active_contract.get(&"enemy_modifiers", {}),
		active_contract
	):
		_report_configuration_error("적 생성 모듈을 등급 정책으로 구성하지 못했습니다.")
		return false
	if auto_weapon != null and auto_weapon.has_method(&"set_target_provider"):
		if not auto_weapon.call(&"set_target_provider", enemy_spawner):
			_report_configuration_error("자동 무기에 적 대상 제공자를 연결하지 못했습니다.")
			return false
	return true


func _install_room_encounters() -> bool:
	if not ResourceLoader.exists(features.room_encounter_config_path):
		_report_configuration_error("방 전투 설정을 찾을 수 없습니다.")
		return false
	room_encounter_system = _instantiate_feature(
		ROOM_ENCOUNTER_SCENE_PATH, world_container, &"RoomEncounters"
	)
	if (
		not _supports_methods(room_encounter_system, ROOM_ENCOUNTER_METHODS)
		or not room_encounter_system.has_signal(&"encounter_started")
		or not room_encounter_system.has_signal(&"encounter_cleared")
		or not room_encounter_system.has_signal(&"all_encounters_completed")
		or not room_encounter_system.has_signal(&"reward_collected")
		or not room_encounter_system.has_signal(&"interaction_availability_changed")
	):
		_report_configuration_error("방 전투 모듈의 공개 계약이 올바르지 않습니다.")
		return false
	if not room_encounter_system.call(
		&"configure",
		player,
		map_generator,
		enemy_spawner,
		pickups_container,
		load(features.room_encounter_config_path),
		StringName(selected_map_size)
	):
		_report_configuration_error("방 전투 모듈을 구성하지 못했습니다.")
		return false
	room_encounter_system.connect(
		&"encounter_started", Callable(self, &"_on_room_encounter_started")
	)
	room_encounter_system.connect(
		&"encounter_cleared", Callable(self, &"_on_room_encounter_cleared")
	)
	room_encounter_system.connect(
		&"reward_collected", Callable(self, &"_on_room_reward_collected")
	)
	room_encounter_system.connect(
		&"all_encounters_completed", Callable(self, &"_on_all_room_encounters_completed")
	)
	room_encounter_system.connect(
		&"interaction_availability_changed",
		Callable(self, &"_on_interaction_availability_changed")
	)
	return true


func _install_boss_warning() -> bool:
	boss_warning_hud = _instantiate_feature(
		"res://game/features/boss_warning/boss_warning_hud.tscn", ui_layer, &"BossWarningHud"
	)
	if not _supports_methods(boss_warning_hud, [&"configure", &"get_snapshot"]) \
		or not boss_warning_hud.call(&"configure", enemy_spawner, player, hud_margin):
		_report_configuration_error("보스 경고 HUD의 생성·플레이어·전투 표시 계약이 올바르지 않습니다.")
		return false
	return true


func _install_elite_pursuit() -> bool:
	if (
		credit_ledger == null
		or enemy_spawner == null
		or player == null
		or not ResourceLoader.exists(features.elite_pursuit_config_path)
	):
		_report_configuration_error("엘리트 추격 모듈의 플레이어·크레딧·적 생성 의존성이 없습니다.")
		return false
	var player_attack_reference := 1.0
	if is_instance_valid(auto_weapon) and auto_weapon.has_method(&"get_runtime_snapshot"):
		player_attack_reference = float(
			auto_weapon.call(&"get_runtime_snapshot").get(&"damage", 1.0)
		)
	elite_pursuit_service = _instantiate_feature(
		ELITE_PURSUIT_SCENE_PATH, module_container, &"ElitePursuit"
	)
	if (
		not _supports_methods(elite_pursuit_service, ELITE_PURSUIT_METHODS)
		or not elite_pursuit_service.has_signal(&"pursuit_triggered")
		or not elite_pursuit_service.call(
			&"configure",
			player,
			credit_ledger,
			enemy_spawner,
			map_generator,
			load(features.elite_pursuit_config_path),
			int(active_contract.get(&"entry_cost", 0)),
			player_attack_reference,
			features.map_seed
		)
	):
		_report_configuration_error("엘리트 추격 임계·생성 정책을 구성하지 못했습니다.")
		return false
	elite_pursuit_service.connect(
		&"pursuit_triggered", Callable(self, &"_on_elite_pursuit_triggered")
	)
	return true


func _install_field_loot_acquisition() -> bool:
	if (
		loot_lifecycle_service == null
		or loot_table_provider == null
		or equipment_system == null
		or inventory_system == null
	):
		_report_configuration_error("현장 전리품 비교에 필요한 데이터·장비·가방 계약이 준비되지 않았습니다.")
		return false
	field_loot_acquisition_service = _instantiate_feature(
		FIELD_LOOT_ACQUISITION_SCENE_PATH, module_container, &"FieldLootAcquisition"
	)
	if (
		not _supports_methods(field_loot_acquisition_service, FIELD_LOOT_ACQUISITION_METHODS)
		or not field_loot_acquisition_service.has_signal(&"loot_acquired")
		or not field_loot_acquisition_service.has_signal(&"preview_changed")
		or not field_loot_acquisition_service.has_signal(&"interaction_availability_changed")
	):
		_report_configuration_error("현장 전리품 비교·획득 모듈의 공개 계약이 올바르지 않습니다.")
		return false
	var context := {
		&"region_id": active_contract.get(&"region_id", &"ruined_city"),
		&"difficulty_id": active_contract.get(&"difficulty_id", &"standard"),
		&"map_size": StringName(selected_map_size),
		&"high_grade_drop_multiplier": active_contract.get(&"high_grade_drop_multiplier", 1.0),
		&"boss_available": active_contract.get(&"boss_guaranteed", false),
	}
	var effective_seed := features.map_seed if features.map_seed != 0 else 7411
	if not field_loot_acquisition_service.call(
		&"configure",
		player,
		pickups_container,
		ui_layer,
		loot_lifecycle_service,
		loot_table_provider,
		equipment_system,
		inventory_system,
		context,
		effective_seed,
		field_loot_equip_catalog,
		combat_skill_system if features.field_loot_skill_equip_enabled else null,
		skill_binding_service if features.field_loot_skill_equip_enabled else null,
		session_socket_service if features.session_sockets_enabled else null,
		credit_ledger,
		features.field_loot_immediate_equip_enabled
	):
		_report_configuration_error("현장 전리품 비교·획득 모듈을 작전 문맥에 연결하지 못했습니다.")
		return false
	if is_instance_valid(enemy_spawner):
		for enemy in enemy_spawner.call(&"get_active_targets"):
			field_loot_acquisition_service.call(&"register_enemy", enemy)
	field_loot_acquisition_service.connect(
		&"loot_acquired", Callable(self, &"_on_field_loot_acquired")
	)
	field_loot_acquisition_service.connect(
		&"loot_equipped", Callable(self, &"_on_field_loot_equipped")
	)
	field_loot_acquisition_service.connect(
		&"interaction_availability_changed",
		Callable(self, &"_on_interaction_availability_changed")
	)
	return true


func _install_room_warp() -> bool:
	if minimap == null:
		_report_configuration_error("방 워프 모듈에는 설치된 미니맵이 필요합니다.")
		return false
	room_warp_system = _instantiate_feature(
		ROOM_WARP_SCENE_PATH, module_container, &"RoomWarpSystem"
	)
	if (
		not _supports_methods(room_warp_system, ROOM_WARP_METHODS)
		or not room_warp_system.has_signal(&"warp_targets_changed")
		or not room_warp_system.has_signal(&"warped")
		or not room_warp_system.has_signal(&"warp_rejected")
	):
		_report_configuration_error("방 워프 모듈의 공개 계약이 올바르지 않습니다.")
		return false
	if not room_warp_system.call(&"configure", player, map_generator, room_encounter_system):
		_report_configuration_error("방 워프 모듈을 구성하지 못했습니다.")
		return false
	room_warp_system.connect(
		&"warp_targets_changed", Callable(minimap, &"set_warp_targets")
	)
	room_warp_system.connect(&"warped", Callable(self, &"_on_room_warped"))
	room_warp_system.connect(&"warp_rejected", Callable(self, &"_on_room_warp_rejected"))
	minimap.connect(&"warp_requested", Callable(room_warp_system, &"request_warp"))
	minimap.call(&"set_warp_targets", room_warp_system.call(&"get_warp_targets"))
	return true


func _configure_tier_button(button: Button, tier_id: String) -> void:
	button.disabled = false
	if not features.map_generation_enabled:
		button.disabled = true
		button.text = "%s · 맵 기능 비활성" % tier_id
		return
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
	if features.spawning_enabled and not ResourceLoader.exists(SPAWN_CONFIG_PATH_PATTERN % tier_id):
		button.disabled = true
		button.text = "%s 적 생성 설정 없음" % config.get("display_name")
		return
	var spawn_config: Resource
	if features.spawning_enabled:
		spawn_config = load(SPAWN_CONFIG_PATH_PATTERN % tier_id)
	var enemy_range := ""
	if features.spawning_enabled and spawn_config != null:
		enemy_range = " · 적 %d~%d" % [
			spawn_config.get("minimum_active_enemies"),
			spawn_config.get("maximum_active_enemies"),
		]
	var quoted_entry_cost := int(config.get("entry_cost"))
	var reward_multiplier := 1.0
	if operation_contract_service != null:
		var quote: Dictionary = operation_contract_service.call(
			&"quote", config,
			penalty_system.call(&"get_snapshot") if penalty_system != null else {},
			_operation_investment_context()
		)
		quoted_entry_cost = int(quote.get(&"entry_cost", quoted_entry_cost))
		reward_multiplier = float(quote.get(&"reward_multiplier", 1.0))
		if persistent_profile != null and not persistent_profile.call(&"can_spend", quoted_entry_cost):
			button.disabled = true
	button.text = "%s · %d분\n투입 %d C · 회수 ×%.2f\n방 %d~%d%s" % [
		config.get("display_name"),
		roundi(float(config.get("target_run_duration_seconds")) / 60.0),
		quoted_entry_cost,
		reward_multiplier,
		config.get("minimum_rooms"),
		config.get("maximum_rooms"),
		enemy_range,
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
	if features.spawning_enabled:
		var spawn_config_path := SPAWN_CONFIG_PATH_PATTERN % tier_id
		if not ResourceLoader.exists(spawn_config_path):
			_report_configuration_error("적 생성 설정을 찾을 수 없습니다: %s" % spawn_config_path)
			return false
		var spawn_config = load(spawn_config_path)
		if (
			spawn_config == null
			or not spawn_config.has_method(&"is_valid")
			or not spawn_config.call(&"is_valid")
		):
			_report_configuration_error("유효하지 않은 적 생성 설정입니다: %s" % spawn_config_path)
			return false
	return true


func _process(delta: float) -> void:
	advance_run_clock(delta)


func advance_run_clock(delta: float) -> void:
	if not run_started or run_ended or get_tree().paused:
		return

	elapsed_time += maxf(0.0, delta)
	if (
		extraction_zone != null
		and not extraction_unlocked
		and elapsed_time >= extraction_unlock_seconds
	):
		_unlock_extraction(&"elapsed_time")
	_update_run_time_hud()


func _unlock_extraction(reason: StringName) -> void:
	if extraction_unlocked or extraction_zone == null:
		return
	extraction_unlocked = true
	extraction_zone.call(&"set_locked", false)
	status_label.text = (
		"모든 전투 방 확보 · 즉시 탈출 가능"
		if reason == &"all_rooms_cleared"
		else "탈출 신호 활성 · 탈출 지점에서 F"
	)
	_update_run_time_hud()


func get_run_pacing_snapshot() -> Dictionary:
	return {
		&"tier_id": StringName(selected_map_size),
		&"elapsed_seconds": elapsed_time,
		&"target_seconds": target_run_duration_seconds,
		&"extraction_unlock_seconds": extraction_unlock_seconds,
		&"extraction_unlocked": extraction_unlocked,
		&"run_started": run_started,
		&"run_ended": run_ended,
		&"hud_text": time_label.text,
	}


func _update_run_time_hud() -> void:
	var extraction_state := "탈출 비활성"
	if features.extraction_enabled:
		var extraction_snapshot: Dictionary = (
			extraction_zone.call(&"get_snapshot") if extraction_zone != null else {}
		)
		if bool(extraction_snapshot.get(&"defense_active", false)):
			extraction_state = "방어 %.1f초" % float(
				extraction_snapshot.get(&"defense_remaining_seconds", 0.0)
			)
		else:
			extraction_state = (
				"탈출 방어 가능"
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
	if (
		event.is_action_pressed(&"switch_weapon")
		and not event.is_echo()
		and not run_started
		and not run_setup_overlay.visible
		and equipment_system != null
	):
		equipment_system.call(&"switch_active_weapon")
		get_viewport().set_input_as_handled()
		return
	if not event is InputEventKey:
		return

	var key_event := event as InputEventKey
	if key_event.pressed and not key_event.echo:
		if run_ended and (key_event.keycode == KEY_ENTER or key_event.keycode == KEY_SPACE):
			_restart_run()
		elif run_started and not run_ended and key_event.keycode == KEY_ESCAPE:
			_abandon_run_to_start_hub()
		elif run_setup_overlay.visible and key_event.keycode == KEY_ESCAPE:
			_close_run_setup()
		elif run_setup_overlay.visible and key_event.keycode == KEY_LEFT:
			operation_setup_presenter.call(&"step_relative", -1)
		elif run_setup_overlay.visible and key_event.keycode == KEY_RIGHT:
			operation_setup_presenter.call(&"step_relative", 1)
		elif initialization_recovery_active and game_over_overlay.visible and (
			key_event.keycode == KEY_ESCAPE or key_event.keycode == KEY_ENTER
		):
			game_over_overlay.visible = false
			get_tree().paused = false
			_route_initial_entry()


func _abandon_run_to_start_hub() -> void:
	if not run_started or run_ended:
		return
	_settle_run_loot(false)
	if operation_contract_service != null:
		operation_contract_service.call(&"clear_active_contract")
	_return_to_start_hub()
	status_label.text = "작전 중단 · 획득 전리품 없이 거점으로 복귀했습니다."


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
	if not fog_of_war.call(&"configure", player, map_generator):
		_report_configuration_error("전장의 안개가 플레이어를 추적하지 못했습니다.")
		return false
	fog_of_war.call(
		&"set_visibility_multiplier",
		float(active_contract.get(&"world_modifiers", {}).get(&"vision_multiplier", 1.0))
	)
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


func _supports_growth_balance(candidate: Node) -> bool:
	if (
		not is_instance_valid(candidate)
		or not candidate.has_signal(&"growth_balance_updated")
		or not candidate.has_signal(&"growth_balance_error")
	):
		return false
	return _supports_methods(candidate, GROWTH_BALANCE_METHODS)


func _supports_loot_lifecycle(candidate: Node) -> bool:
	if (
		not is_instance_valid(candidate)
		or not candidate.has_signal(&"lifecycle_updated")
		or not candidate.has_signal(&"lifecycle_error")
	):
		return false
	return _supports_methods(candidate, LOOT_LIFECYCLE_METHODS)


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


func _supports_enemy_spawner(candidate: Node) -> bool:
	if (
		not is_instance_valid(candidate)
		or not candidate.has_signal(&"enemy_spawned")
		or not candidate.has_signal(&"reinforcement_dispatched")
		or not candidate.has_signal(&"spawn_budget_exhausted")
	):
		return false
	return _supports_methods(candidate, ENEMY_SPAWNER_METHODS)


func _supports_methods(candidate: Node, methods: Array) -> bool:
	if not is_instance_valid(candidate):
		return false
	for method_name in methods:
		if not candidate.has_method(method_name):
			return false
	return true


func _on_enemy_spawned(enemy: Node) -> void:
	run_combat_metrics.register_enemy(enemy)
	if is_instance_valid(field_loot_acquisition_service):
		field_loot_acquisition_service.call(&"register_enemy", enemy)
	if enemy.has_signal(&"defeated"):
		enemy.connect(&"defeated", Callable(self, &"_on_enemy_defeated"))
	var enemy_hit_reaction: Node = enemy.get_node_or_null("HitReaction")
	if enemy_hit_reaction != null:
		enemy_hit_reaction.set("enabled", features.hit_feedback_enabled)
	if is_instance_valid(hit_feedback_director):
		hit_feedback_director.call(&"register_actor", enemy)
	if p5_hub_progression_service != null and enemy.has_signal(&"damaged"):
		enemy.connect(&"damaged", Callable(self, &"_on_enemy_training_damage"))


func _on_enemy_training_damage(
	health_damage: float,
	armor_damage: float,
	_world_position: Vector2,
	context: Dictionary
) -> void:
	if p5_hub_progression_service != null:
		p5_hub_progression_service.call(
			&"record_training_hit",
			maxf(0.0, health_damage + armor_damage),
			float(context.get(&"armor_penetration", 0.0)),
			float(context.get(&"cooldown_seconds", 0.0))
		)


func _on_combat_skill_activated(
	slot_index: int,
	_skill_id: StringName,
	result: Dictionary
) -> void:
	status_label.text = "%d 스킬 · %s" % [
		slot_index + 1,
		result.get(&"status", "발동"),
	]


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
	combat_hud_presenter.call(&"set_interaction_active", interaction_label.visible)


func _on_credits_looted(amount: int, _world_position: Vector2) -> void:
	if credit_ledger != null:
		credit_ledger.call(&"add_carried", amount)


func _on_credits_changed(carried: int, _secured: int) -> void:
	credit_label.text = "CR %d" % carried
	credit_label.tooltip_text = "휴대 크레딧 %d" % carried


func _on_equipment_changed(summary: Dictionary) -> void:
	var defense_value := 0.0
	if player != null and player.has_method(&"get_runtime_stats"):
		defense_value = float(player.call(&"get_runtime_stats").get(&"defense", 0.0))
	var active_slot := String(summary.get(&"active_weapon_slot", &"main"))
	var main_marker := "▶" if active_slot == "main" else " "
	var secondary_marker := "▶" if active_slot == "secondary" else " "
	equipment_label.text = "%sM %s\n%sS %s · %d/%d · ARM %d · DEF %.0f" % [
		main_marker,
		summary.get(&"main_weapon_name", "없음"),
		secondary_marker,
		summary.get(&"secondary_weapon_name", "없음"),
		int(summary.get(&"active_skill_count", 0)),
		int(summary.get(&"equipped_skill_count", 0)),
		int(summary.get(&"armor_count", 0)),
		defense_value,
	]
	if run_started:
		combat_hud_presenter.call(&"reveal_detail", &"equipment")


func _on_active_weapon_changed(slot_id: StringName, weapon_definition: Resource) -> void:
	preferred_weapon_slot = slot_id
	if not run_started:
		hub_active_weapon_name = (
			String(weapon_definition.get("display_name"))
			if weapon_definition != null else String(slot_id)
		)
		_refresh_control_hints()
		status_label.text = "거점 무기 전환 · %s · U 장비 · E 모듈·파츠" % (
			hub_active_weapon_name
		)


func _on_weapon_runtime_changed(snapshot: Dictionary) -> void:
	var trait_labels := {
		&"steady_burst": "안정 3점사",
		&"heavy_piercing": "고위력 관통",
	}
	var trait_id: StringName = snapshot.get(&"trait_id", &"")
	weapon_runtime_label.text = "%s\n%.1f DMG · %.0f RNG · %s" % [
		snapshot.get(&"display_name", "무기"),
		float(snapshot.get(&"damage", 0.0)) + float(snapshot.get(&"level_damage_bonus", 0.0)),
		float(snapshot.get(&"target_range_px", 0.0)),
		trait_labels.get(trait_id, String(trait_id)),
	]
	weapon_runtime_label.tooltip_text = "현재 무기 · %s · %s · %s" % [
		snapshot.get(&"display_name", "무기"),
		trait_labels.get(trait_id, String(trait_id)),
		snapshot.get(&"source_label", "내장 기본값"),
	]
	if run_started:
		combat_hud_presenter.call(&"reveal_detail", &"weapon")


func _on_weapon_balance_error(message: String) -> void:
	push_warning(message)


func _on_growth_balance_error(message: String) -> void:
	push_warning(message)


func _on_loot_lifecycle_error(message: String) -> void:
	push_warning(message)


func _on_loot_table_error(message: String) -> void:
	push_warning(message)


func _on_loot_table_updated(_snapshot: Dictionary, _source_label: String) -> void:
	_refresh_contract_setup_ui()


func _on_growth_balance_updated(_snapshot: Dictionary, _source_label: String) -> void:
	if equipment_system != null:
		equipment_system.call(&"set_upgrade_balance_provider", growth_balance_service)
	if equipment_upgrade_service != null:
		equipment_upgrade_service.call(&"set_balance_provider", growth_balance_service)
	if run_buff_system != null:
		run_buff_system.call(
			&"set_catalog", growth_balance_service.call(&"get_run_buff_catalog")
		)


func _on_extraction_completed(_actor: Node2D) -> void:
	var carried_credits := 0
	if credit_ledger != null:
		carried_credits = int(credit_ledger.call(&"secure_carried"))
	var loot_settlement := _settle_run_loot(true)
	var settlement := {&"recovered_credits": carried_credits, &"salvage": 0, &"ranking": {}}
	if operation_result_service != null:
		settlement = operation_result_service.call(&"settle_success", {
			&"run_id": String(current_run_id),
			&"carried_credits": carried_credits,
			&"elapsed_seconds": elapsed_time,
			&"kills": defeated_enemies,
			&"boss_kills": run_combat_metrics.get_snapshot().get(&"boss_kills", 0),
			&"season_context": active_ranking_context.duplicate(true),
		}, active_contract)
	var ranking: Dictionary = settlement.get(&"ranking", {})
	var ranks: Dictionary = ranking.get(&"ranks", {})
	var ranking_provider_label := _format_ranking_provider_status(
		ranking.get(&"provider_status", {})
	)
	ranking_provider_label += String(ranking.get(&"season_text", ""))
	var blueprint_label := ""
	if StringName(settlement.get(&"blueprint_id", &"")) != &"":
		blueprint_label = " · 도면 획득"
	_finish_run(
		"탈출 성공",
		"%s 작전 · 생존 %s · 처치 %d (보스 %d) · 정산 %d C · 고철 %d%s · 가치 #%d / 시간 #%d / 처치 #%d%s%s" % [
			_selected_map_display_name(),
			_format_time(elapsed_time),
			defeated_enemies,
			int(run_combat_metrics.get_snapshot().get(&"boss_kills", 0)),
			int(settlement.get(&"recovered_credits", carried_credits)),
			int(settlement.get(&"salvage", 0)),
			blueprint_label,
			int(ranks.get(&"recovered_value", ranking.get(&"rank", 0))),
			int(ranks.get(&"elapsed_seconds", 0)),
			int(ranks.get(&"kills", 0)),
			_format_run_loot_settlement(loot_settlement),
			ranking_provider_label,
		]
	)


func _format_ranking_provider_status(status: Dictionary) -> String:
	if status.is_empty():
		return ""
	return "\n랭킹 · %s" % String(status.get(&"label", "로컬 기록"))


func _on_extraction_defense_started(_actor: Node2D, duration_seconds: float) -> void:
	status_label.text = "탈출 방어전 시작 · %.0f초 동안 구역을 지키세요." % duration_seconds


func _on_extraction_defense_cancelled() -> void:
	status_label.text = "탈출 방어 중단 · 구역으로 돌아가 F를 누르세요."


func _on_extraction_defense_paused(remaining_seconds: float) -> void:
	status_label.text = "탈출 방어 일시정지 · 구역 복귀 시 %.1f초부터 재개" % remaining_seconds


func _on_extraction_defense_resumed(remaining_seconds: float) -> void:
	status_label.text = "탈출 방어 재개 · 잔여 %.1f초" % remaining_seconds


func _extraction_defense_duration() -> float:
	if not features.extraction_defense_enabled:
		return 0.0
	var defense_config: Resource = load(features.extraction_defense_config_path)
	if defense_config == null or not defense_config.has_method(&"duration_for"):
		return 0.0
	return float(defense_config.call(
		&"duration_for", StringName(selected_map_size),
		StringName(active_contract.get(&"difficulty_id", &"standard"))
	)) * float(active_contract.get(&"world_modifiers", {}).get(&"extraction_duration_multiplier", 1.0))


func _on_enemy_defeated(reward: int, world_position: Vector2) -> void:
	defeated_enemies += 1
	kills_label.text = str(defeated_enemies)
	kills_label.tooltip_text = "처치 %d" % defeated_enemies

	if progression_system != null:
		progression_system.call_deferred(&"spawn_pickup", world_position, reward)
	if combat_resource_system != null:
		combat_resource_system.call_deferred(&"spawn_enemy_drops", world_position)


func _on_room_encounter_started(room_index: int, enemy_count: int) -> void:
	combat_hud_presenter.call(
		&"show_status",
		"방 %d 봉쇄 · 적 %d기 섬멸" % [room_index + 1, enemy_count],
		2,
		600.0
	)


func _on_elite_pursuit_triggered(threshold: int, carried: int, elite_count: int) -> void:
	var role := "추격 보스" if bool(elite_pursuit_service.call(&"get_snapshot").get(&"spawn_as_boss", false)) else "엘리트 추격자"
	combat_hud_presenter.call(
		&"show_status",
		"위협 경보 · 회수액 %d/%d C · %s %d기 접근 · 문과 무관하게 추격" % [
			carried, threshold, role, elite_count,
		],
		5,
		4.0
	)


func _on_room_encounter_cleared(room_index: int) -> void:
	var field_drop_spawned := false
	if field_loot_acquisition_service != null and map_generator != null:
		var positions: PackedVector2Array = map_generator.call(
			&"get_room_spawn_positions", room_index, 1
		)
		if not positions.is_empty():
			field_drop_spawned = field_loot_acquisition_service.call(
				&"spawn_room_reward", positions[0], room_index
			) != null
	combat_hud_presenter.call(
		&"show_status",
		(
			"방 %d 확보 · 보상 박스 + 비교 전리품 신호"
			if field_drop_spawned else "방 %d 확보 · 크레딧 보상 박스 생성"
		) % [room_index + 1],
		3,
		2.0
	)
	if room_warp_system != null:
		room_warp_system.call(&"refresh_targets")


func _on_field_loot_acquired(
	item_id: StringName,
	quantity: int,
	snapshot: Dictionary
) -> void:
	var entry: Dictionary = (snapshot.get(&"acquired_items", {}) as Dictionary).get(item_id, {})
	combat_hud_presenter.call(
		&"show_status",
		"현장 전리품 확보 · %s ×%d · 정산 전 임시 보관" % [
			entry.get(&"display_name", item_id), quantity,
		],
		4,
		2.4
	)


func _on_field_loot_equipped(
	_item_id: StringName,
	result: Dictionary,
	_snapshot: Dictionary
) -> void:
	combat_hud_presenter.call(
		&"show_status",
		"현장 즉시 장착 · %s → %s · 기존 장비는 런 임시 보관" % [
			result.get(&"previous_name", "없음"), result.get(&"candidate_name", "새 장비"),
		],
		5,
		2.8
	)


func _on_session_socket_action(result: Dictionary) -> void:
	if not bool(result.get(&"success", false)):
		var reason_labels := {
			&"duplicate_limit": "동일 자산 중복 제한",
			&"socket_full": "소켓 용량 부족",
			&"invalid_slot": "해제할 소켓 없음",
		}
		combat_hud_presenter.call(
			&"show_status",
			"런 소켓 장착 실패 · %s" % reason_labels.get(
				StringName(result.get(&"reason", &"")), "지원하지 않는 자산"
			),
			4,
			2.0
		)
		return
	var action_label := (
		"해제" if result.get(&"reason", &"") == &"unsocketed" else
		("교체" if result.get(&"reason", &"") == &"replaced_oldest" else "장착")
	)
	combat_hud_presenter.call(
		&"show_status",
		"런 소켓 %s · %s · 작전 종료 시 초기화" % [
			action_label, result.get(&"display_name", result.get(&"item_id", "자산")),
		],
		5,
		2.4
	)


func _on_session_socket_error(message: String) -> void:
	_report_configuration_error("세션 소켓 데이터 오류: %s" % message)


func _on_room_reward_collected(_room_index: int, credit_amount: int) -> void:
	if credit_ledger != null:
		credit_ledger.call(&"add_carried", credit_amount)
	combat_hud_presenter.call(
		&"show_status", "방 보상 박스 회수 · 크레딧 +%d" % credit_amount, 4, 2.0
	)


func _on_all_room_encounters_completed(completed_count: int, _required_count: int) -> void:
	var extraction_available := extraction_zone != null
	_unlock_extraction(&"all_rooms_cleared")
	combat_hud_presenter.call(
		&"show_status",
		(
			"전투 방 %d곳 확보 · 보상 박스 생성 · 조기 탈출 개방"
			if extraction_available
			else "전투 방 %d곳 확보 · 보상 박스 생성"
		) % completed_count,
		5,
		3.0
	)


func _on_room_warped(room_index: int, _world_position: Vector2) -> void:
	minimap.call(&"set_expanded", false)
	combat_hud_presenter.call(&"show_status", "전술 워프 · 방 %d" % [room_index + 1], 3, 1.6)


func _on_room_warp_rejected(_room_index: int, reason: String) -> void:
	combat_hud_presenter.call(&"show_status", reason, 4, 2.0)


func _on_player_health_changed(current: float, maximum: float) -> void:
	health_bar.max_value = maximum
	health_bar.value = current
	var ratio := current / maximum if maximum > 0.0 else 0.0
	combat_hud_presenter.call(&"set_survival_ratio", ratio)
	health_label.text = "%d/%d · %d%%" % [
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
	level_label.text = str(level)
	level_label.tooltip_text = "레벨 %d" % level
	experience_bar.max_value = required
	experience_bar.value = current
	experience_label.text = "%d / %d" % [current, required]


func _on_level_increased(new_level: int) -> void:
	if run_buff_system == null or run_buff_selector == null:
		if auto_weapon != null:
			auto_weapon.call(&"apply_level", new_level)
		return
	pending_buff_levels.append(new_level)
	_show_next_run_buff_choice()


func _on_combat_resource_pickup_collected(resource_id: StringName, amount: float) -> void:
	if amount <= 0.0:
		return
	combat_hud_presenter.call(&"show_status", (
		"에너지 자원 회수 · +%d" % roundi(amount)
		if resource_id == &"energy"
		else "체력 자원 회수 · +%d HP" % roundi(amount)
	), 0, 0.0)


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
	if operation_result_service != null:
		operation_result_service.call(&"settle_failure", {
			&"carried_credits": lost_credits,
			&"elapsed_seconds": elapsed_time,
			&"kills": defeated_enemies,
		}, active_contract)
	var loot_settlement := _settle_run_loot(false)
	lose_equipped_loadout_on_return = true
	_finish_run(
		"작전 실패",
		"생존 %s · 처치 %d · 분실 %d 크레딧%s" % [
			_format_time(elapsed_time),
			defeated_enemies,
			lost_credits,
			_format_run_loot_settlement(loot_settlement),
		]
	)


func _settle_run_loot(extracted: bool) -> Dictionary:
	var settlement: Dictionary = {}
	var acquired_items: Dictionary = {}
	if is_instance_valid(field_loot_acquisition_service):
		acquired_items = field_loot_acquisition_service.call(&"get_snapshot").get(
			&"acquired_items", {}
		)
	if run_settlement_service != null and current_run_id != &"":
		settlement = run_settlement_service.call(
			&"settle", current_run_id, acquired_items, extracted
		)
	if p5_hub_progression_service != null:
		settlement[&"p5_progression"] = p5_hub_progression_service.call(
			&"settle_run", extracted, acquired_items
		)
	last_loot_settlement = settlement
	return last_loot_settlement.duplicate(true)


func _format_run_loot_settlement(result: Dictionary) -> String:
	if not bool(result.get(&"success", false)):
		return ""
	if bool(result.get(&"extracted", false)):
		return "\n전리품 · 자동 환전 %d C · 영구 해금 %d종 · 창고 보관 %d종 · 런 종료 %d종" % [
			int(result.get(&"converted_credits", 0)) + int(result.get(&"wallet_credits", 0)),
			(result.get(&"permanent_unlocks", {}) as Dictionary).size(),
			(result.get(&"warehouse_items", {}) as Dictionary).size(),
			(result.get(&"expired_items", {}) as Dictionary).size(),
		]
	var lost: Dictionary = result.get(&"lost_items", {})
	var lost_quantity := 0
	for quantity in lost.values():
		lost_quantity += int(quantity)
	return "\n전리품 · 사망 소실 %d종 · %d개" % [lost.size(), lost_quantity]


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
	if desktop_progress != null:
		desktop_progress.call(&"finish_run", current_run_id, not lose_equipped_loadout_on_return, {
			"outcome": "failure" if lose_equipped_loadout_on_return else "extracted",
			"map_size": selected_map_size, "elapsed_seconds": elapsed_time,
			"kills": defeated_enemies, "boss_kills": run_combat_metrics.get_snapshot().get(&"boss_kills", 0),
			"entry_cost": int(active_contract.get(&"entry_cost", 0)),
			"warehouse_items": last_loot_settlement.get(&"warehouse_items", {}).duplicate(true),
			"permanent_unlocks": last_loot_settlement.get(&"permanent_unlocks", {}).duplicate(true),
		})
	_hide_active_run_ui()
	if is_instance_valid(mobile_control_pad):
		mobile_control_pad.call(&"set_context_enabled", false)
	end_title.text = title
	game_over_summary.text = final_summary
	restart_button.text = "시작 거점으로 복귀 (Enter)"
	game_over_overlay.visible = true
	get_tree().paused = true


func _hide_active_run_ui() -> void:
	hud_margin.visible = false
	interaction_label.visible = false
	for layer in [minimap, combat_skill_hud, dash_cooldown_hud]:
		if is_instance_valid(layer):
			layer.visible = false
	if is_instance_valid(operation_tutorial_overlay):
		operation_tutorial_overlay.call(&"dismiss")


func _selected_map_display_name() -> String:
	var config_path := MAP_CONFIG_PATH_PATTERN % selected_map_size
	if ResourceLoader.exists(config_path):
		return String(load(config_path).get("display_name"))
	return selected_map_size


func _restart_run() -> void:
	_return_to_start_hub()


func _report_configuration_error(message: String) -> void:
	push_error(message)
	status_label.text = "설정 오류: %s" % message


func _format_time(seconds: float) -> String:
	var total_seconds := floori(seconds)
	var minutes := floori(float(total_seconds) / 60.0)
	return "%02d:%02d" % [minutes, total_seconds % 60]
