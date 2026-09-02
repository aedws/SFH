class_name FeatureManifest
extends Resource

## 프로젝트에서 사용할 기능을 한곳에서 활성화하거나 비활성화합니다.
## 기능 사이의 의존성은 validation_errors()에서 검사합니다.

@export_category("Core modules")
@export var player_enabled: bool = true
@export var start_hub_enabled: bool = true
@export var map_generation_enabled: bool = true
@export var map_obstacles_enabled: bool = true
@export var fog_of_war_enabled: bool = true
@export var minimap_enabled: bool = true
@export var extraction_enabled: bool = true
@export var credits_enabled: bool = true
@export var loot_enabled: bool = true
@export var enemies_enabled: bool = true
@export var enemy_armor_enabled: bool = true
@export var enemy_status_ui_enabled: bool = true
@export var equipment_enabled: bool = true
@export var equipment_weapons_enabled: bool = true
@export var equipment_skills_enabled: bool = true
@export var equipment_armor_enabled: bool = true
@export var inventory_enabled: bool = true
@export var equipment_customization_enabled: bool = true
@export var spawning_enabled: bool = true
@export var room_encounters_enabled: bool = true
@export var room_warp_enabled: bool = true
@export var weapons_enabled: bool = true
@export var combat_skills_enabled: bool = true
@export var combat_resources_enabled: bool = true
@export var weapon_balance_enabled: bool = true
@export var growth_balance_enabled: bool = true
@export var loot_lifecycle_enabled: bool = true
@export var loot_tables_enabled: bool = true
@export var field_loot_acquisition_enabled: bool = true
@export var field_loot_immediate_equip_enabled: bool = true
@export var field_loot_skill_equip_enabled: bool = true
@export var session_sockets_enabled: bool = true
@export var run_settlement_enabled: bool = true
@export var damage_enabled: bool = true
@export var hit_feedback_enabled: bool = true
@export var health_recovery_enabled: bool = true
@export var experience_enabled: bool = true
@export var leveling_enabled: bool = true
@export var run_buffs_enabled: bool = true
@export var meta_progression_enabled: bool = true
@export var equipment_upgrade_economy_enabled: bool = true
@export var persistent_profile_enabled: bool = true
@export var operation_contracts_enabled: bool = true
@export var character_selection_enabled: bool = true
@export var loadout_investment_enabled: bool = true
@export var p5_hub_progression_enabled: bool = true
@export var extraction_defense_enabled: bool = true
@export var hub_economy_enabled: bool = true
@export var smart_targeting_enabled: bool = true
@export var crafting_enabled: bool = true
@export var penalty_modifiers_enabled: bool = true
@export var conditional_ranking_enabled: bool = true
@export var game_over_enabled: bool = true
@export var key_mapping_enabled: bool = true
@export var skill_binding_enabled: bool = true
@export var presentation_settings_enabled: bool = true
@export var mobile_controls_enabled: bool = true
@export var elite_pursuit_enabled: bool = true
@export var cyberpunk_theme_enabled: bool = true
@export var cyberpunk_motion_enabled: bool = true
@export var cyberpunk_noise_enabled: bool = true

@export_category("Run setup")
@export var run_setup_enabled: bool = true
@export_enum("small", "medium", "large") var map_size: String = "small"
@export_range(0, 2147483647, 1) var map_seed: int = 0

@export_category("Equipment")
@export_file("*.tres") var equipment_loadout_path: String = (
	"res://game/features/equipment/loadouts/default_loadout.tres"
)

@export_category("Weapon balance")
@export_file("*.tres") var weapon_balance_config_path: String = (
	"res://game/features/weapon_balance/configs/default_weapon_balance.tres"
)
@export_file("*.tres") var growth_balance_config_path: String = (
	"res://game/features/growth_balance/configs/default_growth_balance.tres"
)
@export_file("*.tres") var loot_lifecycle_config_path: String = (
	"res://game/features/loot_lifecycle/configs/default_loot_lifecycle.tres"
)
@export_file("*.tres") var loot_table_config_path: String = (
	"res://game/features/loot_tables/configs/default_loot_table.tres"
)
@export_file("*.tres") var field_loot_equip_catalog_path: String = (
	"res://game/features/field_loot/configs/default_field_loot_equipment.tres"
)
@export_file("*.tres") var session_socket_config_path: String = (
	"res://game/features/session_sockets/configs/default_session_sockets.tres"
)

@export_category("Combat skills")
@export_file("*.tres") var combat_skill_loadout_path: String = (
	"res://game/features/combat_skills/configs/default_combat_skills.tres"
)
@export_file("*.tres") var combat_resource_config_path: String = (
	"res://game/features/combat_resources/configs/default_combat_resources.tres"
)

@export_category("Room encounters")
@export_file("*.tres") var room_encounter_config_path: String = (
	"res://game/features/room_encounters/configs/default_room_encounters.tres"
)

@export_category("Inventory")
@export_file("*.tres") var inventory_catalog_path: String = (
	"res://game/features/inventory/catalogs/default_inventory.tres"
)

@export_category("Roguelike progression")
@export_file("*.tres") var run_buff_catalog_path: String = (
	"res://game/features/run_buffs/configs/default_run_buffs.tres"
)
@export var meta_progression_storage_path: String = "user://sfh_meta_progression.json"
@export var persistent_profile_storage_path: String = "user://sfh_profile.json"
@export var conditional_ranking_storage_path: String = "user://sfh_rankings.json"
@export_file("*.tres") var ranking_provider_config_path: String = (
	"res://game/features/conditional_ranking/configs/default_ranking_provider.tres"
)

@export_category("Key mapping")
@export_file("*.tres") var key_mapping_catalog_path: String = (
	"res://game/features/key_mapping/configs/default_key_mapping.tres"
)
@export var key_mapping_storage_path: String = "user://sfh_key_mapping.json"
@export_file("*.tres") var skill_binding_profile_path: String = (
	"res://game/features/skill_binding/configs/default_skill_bindings.tres"
)
@export var skill_binding_storage_path: String = "user://sfh_skill_bindings.json"
@export var presentation_settings_storage_path: String = "user://sfh_presentation_settings.json"

@export_category("Elite pursuit")
@export_file("*.tres") var elite_pursuit_config_path: String = (
	"res://game/features/elite_pursuit/configs/default_elite_pursuit.tres"
)

@export_category("Operation and meta systems")
@export_file("*.tres") var operation_contract_config_path: String = (
	"res://game/features/operation_contract/configs/default_operation_contracts.tres"
)
@export_file("*.tres") var character_selection_config_path: String = (
	"res://game/features/character_selection/configs/default_character_selection.tres"
)
@export_file("*.tres") var loadout_investment_config_path: String = (
	"res://game/features/loadout_investment/configs/default_loadout_investment.tres"
)
@export_file("*.tres") var p5_hub_progression_config_path: String = (
	"res://game/features/p5_hub_progression/configs/default_p5_hub_progression.tres"
)
@export_file("*.tres") var hub_economy_config_path: String = (
	"res://game/features/hub_economy/configs/default_hub_economy.tres"
)
@export_file("*.tres") var smart_targeting_policy_path: String = (
	"res://game/features/smart_targeting/configs/default_smart_targeting.tres"
)
@export_file("*.tres") var crafting_config_path: String = (
	"res://game/features/crafting/configs/default_crafting.tres"
)
@export_file("*.tres") var penalty_config_path: String = (
	"res://game/features/penalty_modifiers/configs/default_penalties.tres"
)
@export_file("*.tres") var extraction_defense_config_path: String = (
	"res://game/features/extraction/configs/default_extraction_defense.tres"
)
@export_file("*.tres") var operation_result_config_path: String = (
	"res://game/features/operation_results/configs/default_operation_results.tres"
)
@export_file("*.tres") var conditional_ranking_policy_path: String = (
	"res://game/features/conditional_ranking/configs/default_conditional_ranking.tres"
)

@export_category("Health recovery")
@export_file("*.tres") var health_recovery_config_path: String = (
	"res://game/features/health_recovery/configs/default_health_recovery.tres"
)

@export_category("Hit feedback")
@export_file("*.tres") var hit_feedback_profile_path: String = (
	"res://game/features/hit_feedback/configs/default_hit_feedback.tres"
)

@export_category("Equipment upgrade economy")
@export_file("*.tres") var equipment_upgrade_policy_path: String = (
	"res://game/features/equipment_upgrade/configs/default_upgrade_costs.tres"
)


func enabled_module_ids() -> Array[StringName]:
	var result: Array[StringName] = []

	if player_enabled:
		result.append(&"player")
	if start_hub_enabled:
		result.append(&"start_hub")
	if map_generation_enabled:
		result.append(&"map_generation")
	if map_obstacles_enabled:
		result.append(&"map_obstacles")
	if fog_of_war_enabled:
		result.append(&"fog_of_war")
	if minimap_enabled:
		result.append(&"minimap")
	if extraction_enabled:
		result.append(&"extraction")
	if credits_enabled:
		result.append(&"credits")
	if loot_enabled:
		result.append(&"loot")
	if run_setup_enabled:
		result.append(&"run_setup")
	if enemies_enabled:
		result.append(&"enemies")
	if enemy_armor_enabled:
		result.append(&"enemy_armor")
	if enemy_status_ui_enabled:
		result.append(&"enemy_status_ui")
	if equipment_enabled:
		result.append(&"equipment")
	if equipment_weapons_enabled:
		result.append(&"equipment_weapons")
	if equipment_skills_enabled:
		result.append(&"equipment_skills")
	if equipment_armor_enabled:
		result.append(&"equipment_armor")
	if inventory_enabled:
		result.append(&"inventory")
	if equipment_customization_enabled:
		result.append(&"equipment_customization")
	if spawning_enabled:
		result.append(&"spawning")
	if room_encounters_enabled:
		result.append(&"room_encounters")
	if room_warp_enabled:
		result.append(&"room_warp")
	if weapons_enabled:
		result.append(&"weapons")
	if combat_skills_enabled:
		result.append(&"combat_skills")
	if combat_resources_enabled:
		result.append(&"combat_resources")
	if weapon_balance_enabled:
		result.append(&"weapon_balance")
	if growth_balance_enabled:
		result.append(&"growth_balance")
	if loot_lifecycle_enabled:
		result.append(&"loot_lifecycle")
	if loot_tables_enabled:
		result.append(&"loot_tables")
	if field_loot_acquisition_enabled:
		result.append(&"field_loot_acquisition")
	if field_loot_immediate_equip_enabled:
		result.append(&"field_loot_immediate_equip")
	if field_loot_skill_equip_enabled:
		result.append(&"field_loot_skill_equip")
	if session_sockets_enabled:
		result.append(&"session_sockets")
	if run_settlement_enabled:
		result.append(&"run_settlement")
	if damage_enabled:
		result.append(&"damage")
	if hit_feedback_enabled:
		result.append(&"hit_feedback")
	if health_recovery_enabled:
		result.append(&"health_recovery")
	if experience_enabled:
		result.append(&"experience")
	if leveling_enabled:
		result.append(&"leveling")
	if run_buffs_enabled:
		result.append(&"run_buffs")
	if meta_progression_enabled:
		result.append(&"meta_progression")
	if equipment_upgrade_economy_enabled:
		result.append(&"equipment_upgrade_economy")
	if persistent_profile_enabled:
		result.append(&"persistent_profile")
	if operation_contracts_enabled:
		result.append(&"operation_contracts")
	if character_selection_enabled:
		result.append(&"character_selection")
	if loadout_investment_enabled:
		result.append(&"loadout_investment")
	if p5_hub_progression_enabled:
		result.append(&"p5_hub_progression")
	if extraction_defense_enabled:
		result.append(&"extraction_defense")
	if hub_economy_enabled:
		result.append(&"hub_economy")
	if smart_targeting_enabled:
		result.append(&"smart_targeting")
	if crafting_enabled:
		result.append(&"crafting")
	if penalty_modifiers_enabled:
		result.append(&"penalty_modifiers")
	if conditional_ranking_enabled:
		result.append(&"conditional_ranking")
	if game_over_enabled:
		result.append(&"game_over")
	if key_mapping_enabled:
		result.append(&"key_mapping")
	if skill_binding_enabled:
		result.append(&"skill_binding")
	if presentation_settings_enabled:
		result.append(&"presentation_settings")
	if mobile_controls_enabled:
		result.append(&"mobile_controls")
	if elite_pursuit_enabled:
		result.append(&"elite_pursuit")
	if cyberpunk_theme_enabled:
		result.append(&"cyberpunk_theme")

	return result


func validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()

	if not player_enabled and enabled_module_ids().size() > 0:
		errors.append("다른 게임 기능을 사용하려면 player 모듈이 필요합니다.")
	if start_hub_enabled and not player_enabled:
		errors.append("start_hub 모듈은 player 모듈이 필요합니다.")
	if map_generation_enabled and map_size not in ["small", "medium", "large"]:
		errors.append("map_size는 small, medium, large 중 하나여야 합니다.")
	if map_obstacles_enabled and not map_generation_enabled:
		errors.append("map_obstacles 모듈은 map_generation 모듈이 필요합니다.")
	if fog_of_war_enabled and not player_enabled:
		errors.append("fog_of_war 모듈은 player 모듈이 필요합니다.")
	if minimap_enabled and not map_generation_enabled:
		errors.append("minimap 모듈은 map_generation 모듈이 필요합니다.")
	if extraction_enabled and not map_generation_enabled:
		errors.append("extraction 모듈은 map_generation 모듈이 필요합니다.")
	if loot_enabled and not map_generation_enabled:
		errors.append("loot 모듈은 map_generation 모듈이 필요합니다.")
	if loot_enabled and not credits_enabled:
		errors.append("loot 모듈은 credits 모듈이 필요합니다.")
	if run_setup_enabled and not map_generation_enabled:
		errors.append("run_setup 모듈은 map_generation 모듈이 필요합니다.")
	if spawning_enabled and not enemies_enabled:
		errors.append("spawning 모듈은 enemies 모듈이 필요합니다.")
	if room_encounters_enabled and not spawning_enabled:
		errors.append("room_encounters 모듈은 spawning 모듈이 필요합니다.")
	if room_encounters_enabled and not map_generation_enabled:
		errors.append("room_encounters 모듈은 map_generation 모듈이 필요합니다.")
	if room_encounters_enabled and not _resource_exists(room_encounter_config_path):
		errors.append("방 전투 설정 Resource 경로가 유효하지 않습니다.")
	if room_encounters_enabled and not credits_enabled:
		errors.append("room_encounters 보상은 credits 모듈이 필요합니다.")
	if room_warp_enabled and not room_encounters_enabled:
		errors.append("room_warp 모듈은 room_encounters 모듈이 필요합니다.")
	if room_warp_enabled and not minimap_enabled:
		errors.append("room_warp 모듈은 minimap 모듈이 필요합니다.")
	if enemy_armor_enabled and not enemies_enabled:
		errors.append("enemy_armor 모듈은 enemies 모듈이 필요합니다.")
	if enemy_status_ui_enabled and not enemies_enabled:
		errors.append("enemy_status_ui 모듈은 enemies 모듈이 필요합니다.")
	if equipment_weapons_enabled and not equipment_enabled:
		errors.append("equipment_weapons 모듈은 equipment 모듈이 필요합니다.")
	if equipment_skills_enabled and not equipment_enabled:
		errors.append("equipment_skills 모듈은 equipment 모듈이 필요합니다.")
	if equipment_skills_enabled and not equipment_weapons_enabled:
		errors.append("equipment_skills 모듈은 equipment_weapons 모듈이 필요합니다.")
	if equipment_armor_enabled and not equipment_enabled:
		errors.append("equipment_armor 모듈은 equipment 모듈이 필요합니다.")
	if equipment_customization_enabled and not equipment_enabled:
		errors.append("equipment_customization 모듈은 equipment 모듈이 필요합니다.")
	if equipment_customization_enabled and not inventory_enabled:
		errors.append("equipment_customization 모듈은 inventory 모듈이 필요합니다.")
	if equipment_enabled and (
		equipment_loadout_path.is_empty()
		or not ResourceLoader.exists(equipment_loadout_path)
	):
		errors.append("equipment 로드아웃 Resource 경로가 유효하지 않습니다.")
	if inventory_enabled and (
		inventory_catalog_path.is_empty()
		or not ResourceLoader.exists(inventory_catalog_path)
	):
		errors.append("inventory 카탈로그 Resource 경로가 유효하지 않습니다.")
	if weapons_enabled and not enemies_enabled:
		errors.append("weapons 모듈은 enemies 모듈이 필요합니다.")
	if combat_skills_enabled and not player_enabled:
		errors.append("combat_skills 모듈은 player 모듈이 필요합니다.")
	if combat_skills_enabled and (
		combat_skill_loadout_path.is_empty()
		or not ResourceLoader.exists(combat_skill_loadout_path)
	):
		errors.append("combat_skills 로드아웃 Resource 경로가 유효하지 않습니다.")
	if combat_resources_enabled and (
		combat_resource_config_path.is_empty()
		or not ResourceLoader.exists(combat_resource_config_path)
	):
		errors.append("combat_resources 설정 Resource 경로가 유효하지 않습니다.")
	if weapon_balance_enabled and not weapons_enabled:
		errors.append("weapon_balance 모듈은 weapons 모듈이 필요합니다.")
	if weapon_balance_enabled and (
		weapon_balance_config_path.is_empty()
		or not ResourceLoader.exists(weapon_balance_config_path)
	):
		errors.append("weapon_balance 설정 Resource 경로가 유효하지 않습니다.")
	if growth_balance_enabled and not run_buffs_enabled:
		errors.append("growth_balance 모듈은 run_buffs 모듈이 필요합니다.")
	if growth_balance_enabled and not equipment_enabled:
		errors.append("growth_balance 모듈은 equipment 모듈이 필요합니다.")
	if growth_balance_enabled and (
		growth_balance_config_path.is_empty()
		or not ResourceLoader.exists(growth_balance_config_path)
	):
		errors.append("growth_balance 설정 Resource 경로가 유효하지 않습니다.")
	if loot_lifecycle_enabled and not inventory_enabled:
		errors.append("loot_lifecycle 모듈은 inventory 모듈이 필요합니다.")
	if loot_lifecycle_enabled and (
		loot_lifecycle_config_path.is_empty()
		or not ResourceLoader.exists(loot_lifecycle_config_path)
	):
		errors.append("loot_lifecycle 설정 Resource 경로가 유효하지 않습니다.")
	if loot_tables_enabled and not loot_lifecycle_enabled:
		errors.append("loot_tables 모듈은 loot_lifecycle 모듈이 필요합니다.")
	if loot_tables_enabled and (
		loot_table_config_path.is_empty()
		or not ResourceLoader.exists(loot_table_config_path)
	):
		errors.append("loot_tables 설정 Resource 경로가 유효하지 않습니다.")
	if field_loot_acquisition_enabled and not loot_tables_enabled:
		errors.append("field_loot_acquisition 모듈은 loot_tables 모듈이 필요합니다.")
	if field_loot_acquisition_enabled and not loot_lifecycle_enabled:
		errors.append("field_loot_acquisition 모듈은 loot_lifecycle 모듈이 필요합니다.")
	if field_loot_acquisition_enabled and not equipment_enabled:
		errors.append("field_loot_acquisition 모듈은 equipment 모듈이 필요합니다.")
	if field_loot_acquisition_enabled and not inventory_enabled:
		errors.append("field_loot_acquisition 모듈은 inventory 모듈이 필요합니다.")
	if field_loot_immediate_equip_enabled and not field_loot_acquisition_enabled:
		errors.append("field_loot_immediate_equip 모듈은 field_loot_acquisition 모듈이 필요합니다.")
	if field_loot_immediate_equip_enabled and not equipment_weapons_enabled:
		errors.append("field_loot_immediate_equip 모듈은 equipment_weapons 모듈이 필요합니다.")
	if field_loot_immediate_equip_enabled and not _resource_exists(field_loot_equip_catalog_path):
		errors.append("현장 즉시 장착 카탈로그 Resource 경로가 유효하지 않습니다.")
	if field_loot_skill_equip_enabled and not field_loot_immediate_equip_enabled:
		errors.append("현장 스킬 교체 모듈은 현장 즉시 장착 모듈이 필요합니다.")
	if field_loot_skill_equip_enabled and not combat_skills_enabled:
		errors.append("현장 스킬 교체 모듈은 combat_skills 모듈이 필요합니다.")
	if field_loot_skill_equip_enabled and not skill_binding_enabled:
		errors.append("현장 스킬 교체 모듈은 skill_binding 모듈이 필요합니다.")
	if session_sockets_enabled and not loot_lifecycle_enabled:
		errors.append("session_sockets 모듈은 loot_lifecycle 모듈이 필요합니다.")
	if session_sockets_enabled and not weapons_enabled:
		errors.append("session_sockets 모듈은 weapons 모듈이 필요합니다.")
	if session_sockets_enabled and not combat_skills_enabled:
		errors.append("session_sockets 모듈은 combat_skills 모듈이 필요합니다.")
	if session_sockets_enabled and not _resource_exists(session_socket_config_path):
		errors.append("세션 소켓 설정 Resource 경로가 유효하지 않습니다.")
	if run_settlement_enabled and not loot_lifecycle_enabled:
		errors.append("run_settlement 모듈은 loot_lifecycle 모듈이 필요합니다.")
	if run_settlement_enabled and not persistent_profile_enabled:
		errors.append("run_settlement 모듈은 persistent_profile 모듈이 필요합니다.")
	if experience_enabled and not enemies_enabled:
		errors.append("experience 모듈은 enemies 모듈이 필요합니다.")
	if leveling_enabled and not experience_enabled:
		errors.append("leveling 모듈은 experience 모듈이 필요합니다.")
	if run_buffs_enabled and not leveling_enabled:
		errors.append("run_buffs 모듈은 leveling 모듈이 필요합니다.")
	if run_buffs_enabled and (
		run_buff_catalog_path.is_empty()
		or not ResourceLoader.exists(run_buff_catalog_path)
	):
		errors.append("run_buffs 카탈로그 Resource 경로가 유효하지 않습니다.")
	if meta_progression_enabled and not run_buffs_enabled:
		errors.append("meta_progression 모듈은 run_buffs 모듈이 필요합니다.")
	if meta_progression_enabled and meta_progression_storage_path.is_empty():
		errors.append("meta_progression 저장 경로가 필요합니다.")
	if health_recovery_enabled and (
		health_recovery_config_path.is_empty()
		or not ResourceLoader.exists(health_recovery_config_path)
	):
		errors.append("부분 체력 회복 설정 Resource 경로가 유효하지 않습니다.")
	if equipment_upgrade_economy_enabled and not equipment_customization_enabled:
		errors.append("equipment_upgrade_economy는 equipment_customization 모듈이 필요합니다.")
	if equipment_upgrade_economy_enabled and not credits_enabled:
		errors.append("equipment_upgrade_economy는 credits 모듈이 필요합니다.")
	if equipment_upgrade_economy_enabled and (
		equipment_upgrade_policy_path.is_empty()
		or not ResourceLoader.exists(equipment_upgrade_policy_path)
	):
		errors.append("장비 강화 비용 정책 Resource 경로가 유효하지 않습니다.")
	if persistent_profile_enabled and persistent_profile_storage_path.is_empty():
		errors.append("영구 프로필 저장 경로가 필요합니다.")
	if operation_contracts_enabled and not persistent_profile_enabled:
		errors.append("operation_contracts는 persistent_profile 모듈이 필요합니다.")
	if operation_contracts_enabled and not _resource_exists(operation_contract_config_path):
		errors.append("작전 계약 설정 Resource 경로가 유효하지 않습니다.")
	if character_selection_enabled and not operation_contracts_enabled:
		errors.append("character_selection은 operation_contracts 모듈이 필요합니다.")
	if character_selection_enabled and not _resource_exists(character_selection_config_path):
		errors.append("캐릭터 선택 설정 Resource 경로가 유효하지 않습니다.")
	if loadout_investment_enabled and not operation_contracts_enabled:
		errors.append("loadout_investment는 operation_contracts 모듈이 필요합니다.")
	if loadout_investment_enabled and (not equipment_enabled or not combat_skills_enabled):
		errors.append("loadout_investment는 equipment·combat_skills 모듈이 필요합니다.")
	if loadout_investment_enabled and not _resource_exists(loadout_investment_config_path):
		errors.append("로드아웃 투자 설정 Resource 경로가 유효하지 않습니다.")
	if p5_hub_progression_enabled and (
		not persistent_profile_enabled or not operation_contracts_enabled
	):
		errors.append("p5_hub_progression은 persistent_profile·operation_contracts 모듈이 필요합니다.")
	if p5_hub_progression_enabled and not _resource_exists(p5_hub_progression_config_path):
		errors.append("P5 거점 진행 설정 Resource 경로가 유효하지 않습니다.")
	if extraction_defense_enabled and not extraction_enabled:
		errors.append("extraction_defense는 extraction 모듈이 필요합니다.")
	if extraction_defense_enabled and not _resource_exists(extraction_defense_config_path):
		errors.append("탈출 방어 설정 Resource 경로가 유효하지 않습니다.")
	if hub_economy_enabled and not persistent_profile_enabled:
		errors.append("hub_economy는 persistent_profile 모듈이 필요합니다.")
	if hub_economy_enabled and not _resource_exists(hub_economy_config_path):
		errors.append("거점 경제 설정 Resource 경로가 유효하지 않습니다.")
	if smart_targeting_enabled and not weapons_enabled:
		errors.append("smart_targeting은 weapons 모듈이 필요합니다.")
	if smart_targeting_enabled and not _resource_exists(smart_targeting_policy_path):
		errors.append("스마트 타게팅 정책 Resource 경로가 유효하지 않습니다.")
	if crafting_enabled and not persistent_profile_enabled:
		errors.append("crafting은 persistent_profile 모듈이 필요합니다.")
	if crafting_enabled and not _resource_exists(crafting_config_path):
		errors.append("제작 설정 Resource 경로가 유효하지 않습니다.")
	if penalty_modifiers_enabled and not operation_contracts_enabled:
		errors.append("penalty_modifiers는 operation_contracts 모듈이 필요합니다.")
	if penalty_modifiers_enabled and not _resource_exists(penalty_config_path):
		errors.append("페널티 설정 Resource 경로가 유효하지 않습니다.")
	if conditional_ranking_enabled and not operation_contracts_enabled:
		errors.append("conditional_ranking은 operation_contracts 모듈이 필요합니다.")
	if conditional_ranking_enabled and conditional_ranking_storage_path.is_empty():
		errors.append("조건부 랭킹 저장 경로가 필요합니다.")
	if conditional_ranking_enabled and not _resource_exists(conditional_ranking_policy_path):
		errors.append("조건부 랭킹 정책 Resource 경로가 유효하지 않습니다.")
	if conditional_ranking_enabled and not _resource_exists(ranking_provider_config_path):
		errors.append("랭킹 공급자 설정 Resource 경로가 유효하지 않습니다.")
	if persistent_profile_enabled and not _resource_exists(operation_result_config_path):
		errors.append("작전 결과 설정 Resource 경로가 유효하지 않습니다.")
	if game_over_enabled and not damage_enabled:
		errors.append("game_over 모듈은 damage 모듈이 필요합니다.")
	if hit_feedback_enabled and not damage_enabled:
		errors.append("hit_feedback 모듈은 damage 모듈이 필요합니다.")
	if hit_feedback_enabled and not _resource_exists(hit_feedback_profile_path):
		errors.append("타격 피드백 프로필 Resource 경로가 유효하지 않습니다.")
	if key_mapping_enabled and not _resource_exists(key_mapping_catalog_path):
		errors.append("키 설정 카탈로그 Resource 경로가 유효하지 않습니다.")
	if key_mapping_enabled and key_mapping_storage_path.is_empty():
		errors.append("키 설정 저장 경로가 필요합니다.")
	if skill_binding_enabled and not key_mapping_enabled:
		errors.append("skill_binding 모듈은 key_mapping 모듈이 필요합니다.")
	if skill_binding_enabled and not combat_skills_enabled:
		errors.append("skill_binding 모듈은 combat_skills 모듈이 필요합니다.")
	if skill_binding_enabled and not _resource_exists(skill_binding_profile_path):
		errors.append("스킬 배치 프로필 Resource 경로가 유효하지 않습니다.")
	if skill_binding_enabled and skill_binding_storage_path.is_empty():
		errors.append("스킬 배치 저장 경로가 필요합니다.")
	if presentation_settings_enabled and presentation_settings_storage_path.is_empty():
		errors.append("HUD·모바일 표시 설정 저장 경로가 필요합니다.")
	if mobile_controls_enabled and not presentation_settings_enabled:
		errors.append("mobile_controls 모듈은 presentation_settings 모듈이 필요합니다.")
	if elite_pursuit_enabled and not spawning_enabled:
		errors.append("elite_pursuit 모듈은 spawning 모듈이 필요합니다.")
	if elite_pursuit_enabled and not credits_enabled:
		errors.append("elite_pursuit 모듈은 credits 모듈이 필요합니다.")
	if elite_pursuit_enabled and not _resource_exists(elite_pursuit_config_path):
		errors.append("엘리트 추격 설정 Resource 경로가 유효하지 않습니다.")

	return errors


func _resource_exists(path: String) -> bool:
	return not path.is_empty() and ResourceLoader.exists(path)
