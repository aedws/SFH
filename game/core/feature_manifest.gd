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
@export var weapons_enabled: bool = true
@export var combat_skills_enabled: bool = true
@export var weapon_balance_enabled: bool = true
@export var growth_balance_enabled: bool = true
@export var damage_enabled: bool = true
@export var health_recovery_enabled: bool = true
@export var experience_enabled: bool = true
@export var leveling_enabled: bool = true
@export var run_buffs_enabled: bool = true
@export var meta_progression_enabled: bool = true
@export var equipment_upgrade_economy_enabled: bool = true
@export var game_over_enabled: bool = true

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

@export_category("Combat skills")
@export_file("*.tres") var combat_skill_loadout_path: String = (
	"res://game/features/combat_skills/configs/default_combat_skills.tres"
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

@export_category("Health recovery")
@export_file("*.tres") var health_recovery_config_path: String = (
	"res://game/features/health_recovery/configs/default_health_recovery.tres"
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
	if weapons_enabled:
		result.append(&"weapons")
	if combat_skills_enabled:
		result.append(&"combat_skills")
	if weapon_balance_enabled:
		result.append(&"weapon_balance")
	if growth_balance_enabled:
		result.append(&"growth_balance")
	if damage_enabled:
		result.append(&"damage")
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
	if game_over_enabled:
		result.append(&"game_over")

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
	if game_over_enabled and not damage_enabled:
		errors.append("game_over 모듈은 damage 모듈이 필요합니다.")

	return errors
