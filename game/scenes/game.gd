extends Node2D

## 최상위 조립 지점입니다. 각 기능 장면을 직접 구현하지 않고 설치만 합니다.

@export var features: FeatureManifest
@export var player_scene: PackedScene

@onready var module_container: Node2D = $Modules
@onready var status_label: Label = %StatusLabel


func _ready() -> void:
	if features == null:
		push_error("FeatureManifest가 지정되지 않았습니다.")
		status_label.text = "설정 오류: FeatureManifest 없음"
		return

	if features.player_enabled:
		_install_player()

	var enabled_names := PackedStringArray()
	for module_id in features.enabled_module_ids():
		enabled_names.append(String(module_id))

	status_label.text = "활성 모듈: %s" % ", ".join(enabled_names)


func _install_player() -> void:
	if player_scene == null:
		push_error("player_enabled가 켜져 있지만 Player Scene이 없습니다.")
		return

	var player := player_scene.instantiate() as Node2D
	if player == null:
		push_error("Player Scene의 루트는 Node2D여야 합니다.")
		return

	player.name = "Player"
	module_container.add_child(player)
	player.global_position = get_viewport_rect().size * 0.5
