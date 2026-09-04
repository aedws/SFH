class_name TrainingHudLayout
extends Node

## 훈련장 HUD의 화면 배치만 담당합니다. 계측·세팅·스킬 규칙은 알지 못하며,
## CanvasLayer 직속 Control도 뷰포트 안에 놓이도록 절대 좌표를 계산합니다.

const WIDE_BREAKPOINT := 1100.0
const EDGE_MARGIN := 16.0
const WIDE_PANEL_WIDTH := 368.0
const COMPACT_PANEL_WIDTH := 332.0
const TELEMETRY_HEIGHT := 118.0
const LOADOUT_HEIGHT := 74.0
const SKILL_HEIGHT := 84.0
const PANEL_GAP := 8.0

var target_viewport: Viewport
var telemetry_panel: Control
var loadout_panel: Control
var skill_panel: Control


func configure(
	new_viewport: Viewport,
	new_telemetry_panel: Control,
	new_loadout_panel: Control,
	new_skill_panel: Control = null
) -> bool:
	if (
		new_viewport == null
		or not is_instance_valid(new_telemetry_panel)
		or not is_instance_valid(new_loadout_panel)
	):
		return false
	target_viewport = new_viewport
	telemetry_panel = new_telemetry_panel
	loadout_panel = new_loadout_panel
	skill_panel = new_skill_panel
	if not target_viewport.size_changed.is_connected(_apply_layout):
		target_viewport.size_changed.connect(_apply_layout)
	_apply_layout()
	return true


func get_snapshot() -> Dictionary:
	var viewport_rect := target_viewport.get_visible_rect() if target_viewport != null else Rect2()
	return {
		&"viewport_rect": viewport_rect,
		&"telemetry_rect": _rect_of(telemetry_panel),
		&"loadout_rect": _rect_of(loadout_panel),
		&"skill_rect": _rect_of(skill_panel),
		&"all_inside_viewport": (
			_contains(viewport_rect, _rect_of(telemetry_panel))
			and _contains(viewport_rect, _rect_of(loadout_panel))
			and (not is_instance_valid(skill_panel) or _contains(viewport_rect, _rect_of(skill_panel)))
		),
		&"panels_do_not_overlap": (
			not _rect_of(telemetry_panel).intersects(_rect_of(loadout_panel))
			and (not is_instance_valid(skill_panel) or (
				not _rect_of(telemetry_panel).intersects(_rect_of(skill_panel))
				and not _rect_of(loadout_panel).intersects(_rect_of(skill_panel))
			))
		),
		&"skill_compact": not is_instance_valid(skill_panel) or _rect_of(skill_panel).size.y <= 96.0,
	}


func _apply_layout() -> void:
	if target_viewport == null:
		return
	var viewport_size := target_viewport.get_visible_rect().size
	var panel_width := (
		WIDE_PANEL_WIDTH if viewport_size.x >= WIDE_BREAKPOINT else COMPACT_PANEL_WIDTH
	)
	panel_width = minf(panel_width, maxf(280.0, viewport_size.x - EDGE_MARGIN * 2.0))
	var x := maxf(EDGE_MARGIN, viewport_size.x - EDGE_MARGIN - panel_width)
	_place(telemetry_panel, Rect2(x, EDGE_MARGIN, panel_width, TELEMETRY_HEIGHT))
	_place(loadout_panel, Rect2(
		x, EDGE_MARGIN + TELEMETRY_HEIGHT + PANEL_GAP,
		panel_width, LOADOUT_HEIGHT
	))
	if is_instance_valid(skill_panel):
		_place(skill_panel, Rect2(
			x, maxf(
				EDGE_MARGIN + TELEMETRY_HEIGHT + LOADOUT_HEIGHT + PANEL_GAP * 2.0,
				viewport_size.y - EDGE_MARGIN - SKILL_HEIGHT
			),
			panel_width, SKILL_HEIGHT
		))


func _place(control: Control, rect: Rect2) -> void:
	if not is_instance_valid(control):
		return
	control.set_anchors_preset(Control.PRESET_TOP_LEFT, true)
	control.grow_horizontal = Control.GROW_DIRECTION_END
	control.grow_vertical = Control.GROW_DIRECTION_END
	control.custom_minimum_size = rect.size
	control.position = rect.position
	control.size = rect.size
	control.z_index = 30


func _rect_of(control: Control) -> Rect2:
	return control.get_global_rect() if is_instance_valid(control) else Rect2()


func _contains(outer: Rect2, inner: Rect2) -> bool:
	return (
		inner.has_area()
		and inner.position.x >= outer.position.x
		and inner.position.y >= outer.position.y
		and inner.end.x <= outer.end.x + 0.5
		and inner.end.y <= outer.end.y + 0.5
	)
