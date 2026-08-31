class_name DashCooldownHud
extends MarginContainer

## 이동 구현을 직접 참조하지 않고 공개 스냅샷만 읽는 선택형 대시 HUD입니다.

const TacticalHudIcon := preload("res://game/features/run_setup/tactical_hud_icon.gd")

@export_range(1.0, 60.0, 1.0) var refresh_hz: float = 15.0

var movement_provider: Node
var latest_snapshot: Dictionary = {}
var refresh_accumulator: float = 0.0

@onready var status_label: Label = %StatusLabel
@onready var cooldown_bar: ProgressBar = %CooldownBar
@onready var time_label: Label = %TimeLabel


func configure(new_movement_provider: Node) -> bool:
	if (
		not is_instance_valid(new_movement_provider)
		or not new_movement_provider.has_method(&"get_movement_snapshot")
	):
		return false
	movement_provider = new_movement_provider
	_refresh_state()
	set_process(true)
	return true


func get_snapshot() -> Dictionary:
	return {
		&"visible": visible,
		&"refresh_hz": refresh_hz,
		&"movement": latest_snapshot.duplicate(true),
		&"status": status_label.text,
		&"bar_value": cooldown_bar.value,
		&"icon_mode": get_node_or_null("Panel/Margin/Content/DashIcon") != null,
	}


func _ready() -> void:
	var icon_host := get_node_or_null("Panel/Margin/Content/DashIcon") as Control
	if icon_host != null:
		var icon := TacticalHudIcon.new().configure(
			TacticalHudIcon.Kind.DASH, "DASH · 회피 · 재사용 대기시간", Color("02e5e1")
		)
		icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		icon_host.add_child(icon)
	set_process(false)


func _process(delta: float) -> void:
	refresh_accumulator += maxf(0.0, delta)
	var interval := 1.0 / maxf(1.0, refresh_hz)
	if refresh_accumulator < interval:
		return
	refresh_accumulator = fmod(refresh_accumulator, interval)
	_refresh_state()


func _refresh_state() -> void:
	if not is_instance_valid(movement_provider):
		return
	latest_snapshot = movement_provider.call(&"get_movement_snapshot")
	var ready := bool(latest_snapshot.get(&"dash_ready", false))
	var active := bool(latest_snapshot.get(&"dash_active", false))
	var remaining := float(latest_snapshot.get(&"dash_cooldown_remaining", 0.0))
	var ready_ratio := clampf(float(latest_snapshot.get(&"dash_ready_ratio", 0.0)), 0.0, 1.0)
	cooldown_bar.value = ready_ratio * 100.0
	if active:
		status_label.text = "DASH"
		status_label.modulate = Color(0.72, 0.94, 1.0, 1.0)
		time_label.text = ">>"
		time_label.tooltip_text = "이동 중"
	elif ready:
		status_label.text = "READY"
		status_label.modulate = Color(0.48, 1.0, 0.72, 1.0)
		time_label.text = "100%"
		time_label.tooltip_text = "즉시 사용"
	else:
		status_label.text = "WAIT"
		status_label.modulate = Color(1.0, 0.72, 0.34, 1.0)
		time_label.text = "%.1fs" % remaining
		time_label.tooltip_text = "재사용 대기시간"
