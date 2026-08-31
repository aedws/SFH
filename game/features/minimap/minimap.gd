class_name TacticalMinimap
extends PanelContainer

## 생성된 맵의 스냅샷과 추적 대상만 받아 표시하는 독립 HUD 모듈입니다.

const COMPACT_WIDTH_THRESHOLD := 900.0

@onready var title_label: Label = %TitleLabel
@onready var map_view: Control = %MapView
@onready var header: Control = $Margin/Content/Header

var low_obstruction_mode := true
var responsive_layout_mode := &"full_map_compact"


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	tooltip_text = "전체 전술 지도 · YOU 플레이어 · EXIT 탈출"
	map_view.tooltip_text = tooltip_text
	get_viewport().size_changed.connect(_apply_responsive_layout)
	_apply_low_obstruction_style()
	_apply_responsive_layout()


func configure(snapshot: Dictionary, tracked_actor: Node2D, display_name: String) -> void:
	title_label.text = "%s 전술 지도" % display_name
	map_view.call(&"configure", snapshot, tracked_actor)


func set_low_obstruction_mode(enabled: bool) -> void:
	low_obstruction_mode = enabled
	_apply_low_obstruction_style()
	_apply_responsive_layout()


func apply_responsive_width(viewport_width: float) -> void:
	_apply_layout_for_width(maxf(1.0, viewport_width))


func get_layout_snapshot() -> Dictionary:
	return {
		&"layout_mode": responsive_layout_mode,
		&"low_obstruction": low_obstruction_mode,
		&"header_visible": header.visible,
		&"full_map_preserved": map_view.get("map_texture") != null,
		&"size": size,
		&"background_alpha": _panel_background_alpha(),
	}


func _apply_low_obstruction_style() -> void:
	if not is_node_ready():
		return
	header.visible = not low_obstruction_mode
	var panel_style := get_theme_stylebox(&"panel").duplicate() as StyleBoxFlat
	if panel_style != null:
		panel_style.bg_color.a = 0.62 if low_obstruction_mode else 0.94
		panel_style.shadow_size = 1 if low_obstruction_mode else 5
		add_theme_stylebox_override(&"panel", panel_style)


func _apply_responsive_layout() -> void:
	if not is_node_ready():
		return
	_apply_layout_for_width(get_viewport_rect().size.x)


func _apply_layout_for_width(viewport_width: float) -> void:
	if not is_node_ready():
		return
	var compact := viewport_width < COMPACT_WIDTH_THRESHOLD
	responsive_layout_mode = &"edge_compact" if compact else &"full_map_compact"
	map_view.custom_minimum_size = Vector2(154, 98) if compact else Vector2(196, 126)
	set_anchor(SIDE_LEFT, 1.0)
	set_anchor(SIDE_TOP, 0.0)
	set_anchor(SIDE_RIGHT, 1.0)
	set_anchor(SIDE_BOTTOM, 0.0)
	var panel_size := Vector2(170, 112) if compact else Vector2(212, 140)
	offset_left = -panel_size.x - 14.0
	offset_top = 18.0
	offset_right = -14.0
	offset_bottom = 18.0 + panel_size.y


func _panel_background_alpha() -> float:
	var panel_style := get_theme_stylebox(&"panel") as StyleBoxFlat
	return panel_style.bg_color.a if panel_style != null else 0.0
