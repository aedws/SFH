extends Node

## 시작 진입점은 선택형 입력 화면만 조립합니다. 꺼진 기능은 로드하지 않습니다.
func _ready() -> void:
	var features: Resource = load("res://game/core/feature_manifest.tres")
	var destination := "res://game/scenes/game.tscn"
	if features != null and features.mobile_controls_enabled and features.presentation_settings_enabled:
		destination = "res://game/features/mobile_controls/control_mode_entry.tscn"
	get_tree().change_scene_to_file.call_deferred(destination)
