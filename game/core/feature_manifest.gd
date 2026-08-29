class_name FeatureManifest
extends Resource

## 프로젝트에서 사용할 기능을 한곳에서 활성화하거나 비활성화합니다.
## 아직 구현되지 않은 기능은 기본적으로 꺼져 있습니다.

@export_category("Core modules")
@export var player_enabled: bool = true
@export var enemies_enabled: bool = false
@export var spawning_enabled: bool = false
@export var weapons_enabled: bool = false
@export var damage_enabled: bool = false
@export var experience_enabled: bool = false
@export var leveling_enabled: bool = false
@export var game_over_enabled: bool = false


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
