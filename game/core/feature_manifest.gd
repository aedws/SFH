class_name FeatureManifest
extends Resource

## 프로젝트에서 사용할 기능을 한곳에서 활성화하거나 비활성화합니다.
## 기능 사이의 의존성은 validation_errors()에서 검사합니다.

@export_category("Core modules")
@export var player_enabled: bool = true
@export var enemies_enabled: bool = true
@export var spawning_enabled: bool = true
@export var weapons_enabled: bool = true
@export var damage_enabled: bool = true
@export var experience_enabled: bool = true
@export var leveling_enabled: bool = true
@export var game_over_enabled: bool = true


func enabled_module_ids() -> Array[StringName]:
	var result: Array[StringName] = []

	if player_enabled:
		result.append(&"player")
	if enemies_enabled:
		result.append(&"enemies")
	if spawning_enabled:
		result.append(&"spawning")
	if weapons_enabled:
		result.append(&"weapons")
	if damage_enabled:
		result.append(&"damage")
	if experience_enabled:
		result.append(&"experience")
	if leveling_enabled:
		result.append(&"leveling")
	if game_over_enabled:
		result.append(&"game_over")

	return result


func validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()

	if not player_enabled and enabled_module_ids().size() > 0:
		errors.append("다른 게임 기능을 사용하려면 player 모듈이 필요합니다.")
	if spawning_enabled and not enemies_enabled:
		errors.append("spawning 모듈은 enemies 모듈이 필요합니다.")
	if weapons_enabled and not enemies_enabled:
		errors.append("weapons 모듈은 enemies 모듈이 필요합니다.")
	if experience_enabled and not enemies_enabled:
		errors.append("experience 모듈은 enemies 모듈이 필요합니다.")
	if leveling_enabled and not experience_enabled:
		errors.append("leveling 모듈은 experience 모듈이 필요합니다.")
	if game_over_enabled and not damage_enabled:
		errors.append("game_over 모듈은 damage 모듈이 필요합니다.")

	return errors
