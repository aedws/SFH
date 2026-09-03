class_name MobilePadLayout
extends RefCounted

## 배율과 양손/상단 HUD 안전 영역만 계산하는 교체 가능한 배치 정책입니다.
@export var edge_margin := 18.0
@export var bottom_margin := 24.0
@export var hand_gap := 16.0
@export var button_gap := 5.0
@export var joystick_ratio := 2.2
@export var reserved_top := 282.0

func calculate(view_size: Vector2, requested_scale: float) -> Dictionary:
	var base := clampf((view_size.x - 56.0) / 7.0, 48.0, 64.0)
	var width_limit := (view_size.x - edge_margin * 2 - hand_gap - button_gap * 2) / (3.0 + joystick_ratio)
	var button := minf(base * requested_scale, width_limit)
	var effective := button / base
	var energy_height := 24.0 * effective
	var combat_size := Vector2(button * 3 + button_gap * 2, button * 2 + button_gap + energy_height)
	var stick := minf(button * joystick_ratio, view_size.y - reserved_top - bottom_margin)
	return {
		&"button_size": button, &"effective_scale": effective, &"energy_height": energy_height,
		&"movement_rect": Rect2(Vector2(edge_margin, view_size.y - stick - bottom_margin), Vector2.ONE * stick),
		&"combat_rect": Rect2(view_size - combat_size - Vector2(edge_margin, bottom_margin), combat_size),
		&"button_gap": button_gap,
	}
