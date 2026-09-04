class_name MobilePadLayout
extends RefCounted

## 배율과 양손/상단 HUD 안전 영역만 계산하는 교체 가능한 배치 정책입니다.
@export var edge_margin := 18.0
@export var bottom_margin := 24.0
@export var hand_gap := 16.0
@export var button_gap := 5.0
@export var joystick_ratio := 1.9
@export var reserved_top := 282.0

func calculate(view_size: Vector2, requested_scale: float) -> Dictionary:
	# 기본 셀을 작게 유지해 125%에서도 전장을 가리지 않되, 아래의 44px
	# 하한으로 접근 가능한 터치 표적을 보장합니다.
	var base := clampf((view_size.x - 56.0) / 7.0, 44.0, 46.0)
	var width_limit := (view_size.x - edge_margin * 2 - hand_gap - button_gap * 2) / (3.0 + joystick_ratio)
	# 터치 표적은 44 px 아래로 줄이지 않습니다. 세로 화면은 논리 가로
	# 뷰포트 정책이 담당하고, 여기서는 양손 영역의 가로 충돌만 제한합니다.
	var button := maxf(44.0, minf(base * requested_scale, width_limit))
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
