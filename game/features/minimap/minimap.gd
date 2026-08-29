class_name TacticalMinimap
extends PanelContainer

## 생성된 맵의 스냅샷과 추적 대상만 받아 표시하는 독립 HUD 모듈입니다.

@onready var title_label: Label = %TitleLabel
@onready var map_view: Control = %MapView


func configure(snapshot: Dictionary, tracked_actor: Node2D, display_name: String) -> void:
	title_label.text = "%s 전술 지도" % display_name
	map_view.call(&"configure", snapshot, tracked_actor)
