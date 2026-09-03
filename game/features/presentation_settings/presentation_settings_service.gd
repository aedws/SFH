class_name PresentationSettingsService
extends Node

signal settings_changed(snapshot: Dictionary)

const HUD_ANCHORS := [&"bottom_left", &"bottom_center", &"bottom_right"]
const KEY_LABEL_FORMATS := [&"compact", &"boxed", &"hidden"]
const MOBILE_CONTROL_MODES := [&"auto", &"on", &"off"]
const MOBILE_UI_SCALES := [1.0, 1.25, 1.5]

var storage_path := "user://sfh_presentation_settings.json"
var hud_anchor: StringName = &"bottom_left"
var key_label_format: StringName = &"compact"
var mobile_controls_mode: StringName = &"auto"
var mobile_ui_scale := 1.25
var mobile_tutorial_seen := false
var configured := false


func configure(new_storage_path: String, load_saved: bool = true) -> bool:
	if new_storage_path.is_empty():
		return false
	storage_path = new_storage_path
	configured = true
	if load_saved and FileAccess.file_exists(storage_path):
		_load()
	settings_changed.emit(get_snapshot())
	return true


func set_hud_anchor(value: StringName, save_after_change: bool = true) -> bool:
	if value not in HUD_ANCHORS:
		return false
	hud_anchor = value
	return _commit(save_after_change)


func cycle_hud_anchor(direction: int = 1) -> Dictionary:
	var index := HUD_ANCHORS.find(hud_anchor)
	set_hud_anchor(HUD_ANCHORS[posmod(index + direction, HUD_ANCHORS.size())])
	return get_snapshot()


func set_key_label_format(value: StringName, save_after_change: bool = true) -> bool:
	if value not in KEY_LABEL_FORMATS:
		return false
	key_label_format = value
	return _commit(save_after_change)


func cycle_key_label_format(direction: int = 1) -> Dictionary:
	var index := KEY_LABEL_FORMATS.find(key_label_format)
	set_key_label_format(KEY_LABEL_FORMATS[posmod(index + direction, KEY_LABEL_FORMATS.size())])
	return get_snapshot()


func set_mobile_controls_mode(value: StringName, save_after_change: bool = true) -> bool:
	if value not in MOBILE_CONTROL_MODES:
		return false
	mobile_controls_mode = value
	return _commit(save_after_change)


func cycle_mobile_controls_mode(direction: int = 1) -> Dictionary:
	var index := MOBILE_CONTROL_MODES.find(mobile_controls_mode)
	set_mobile_controls_mode(MOBILE_CONTROL_MODES[posmod(index + direction, MOBILE_CONTROL_MODES.size())])
	return get_snapshot()


func set_mobile_ui_scale(value: float, save_after_change: bool = true) -> bool:
	if value not in MOBILE_UI_SCALES:
		return false
	var previous := mobile_ui_scale
	mobile_ui_scale = value
	if save_after_change and not _save():
		mobile_ui_scale = previous
		return false
	settings_changed.emit(get_snapshot())
	return true


func cycle_mobile_ui_scale(direction: int = 1) -> Dictionary:
	set_mobile_ui_scale(MOBILE_UI_SCALES[posmod(MOBILE_UI_SCALES.find(mobile_ui_scale) + direction, MOBILE_UI_SCALES.size())])
	return get_snapshot()


func complete_mobile_tutorial() -> bool:
	var previous := mobile_tutorial_seen
	mobile_tutorial_seen = true
	if not _save():
		mobile_tutorial_seen = previous
		return false
	settings_changed.emit(get_snapshot())
	return true


func reset_defaults(save_after_reset: bool = true) -> bool:
	hud_anchor = &"bottom_left"
	key_label_format = &"compact"
	mobile_controls_mode = &"auto"
	mobile_ui_scale = 1.25
	# 안내 확인 이력은 표시/키 설정 초기화와 별개입니다.
	return _commit(save_after_reset)


func should_show_mobile_controls(touchscreen_available: bool) -> bool:
	match mobile_controls_mode:
		&"on":
			return true
		&"off":
			return false
	return touchscreen_available


func format_key_label(label: String) -> String:
	match key_label_format:
		&"boxed":
			return "[%s]" % label
		&"hidden":
			return ""
	return label


func get_snapshot() -> Dictionary:
	return {
		&"configured": configured,
		&"storage_path": storage_path,
		&"hud_anchor": hud_anchor,
		&"hud_anchor_label": _label_for(hud_anchor),
		&"key_label_format": key_label_format,
		&"key_label_format_label": _label_for(key_label_format),
		&"mobile_controls_mode": mobile_controls_mode,
		&"mobile_ui_scale": mobile_ui_scale,
		&"mobile_ui_scale_label": "%d%%" % roundi(mobile_ui_scale * 100),
		&"mobile_ui_scale_options": MOBILE_UI_SCALES.duplicate(),
		&"mobile_tutorial_seen": mobile_tutorial_seen,
		&"mobile_controls_mode_label": _label_for(mobile_controls_mode),
		&"hud_anchor_options": HUD_ANCHORS.duplicate(),
		&"key_label_format_options": KEY_LABEL_FORMATS.duplicate(),
		&"mobile_controls_mode_options": MOBILE_CONTROL_MODES.duplicate(),
	}


func _commit(save_after_change: bool) -> bool:
	var saved := not save_after_change or _save()
	settings_changed.emit(get_snapshot())
	return saved


func _save() -> bool:
	var file := FileAccess.open(storage_path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify({
		"version": 2,
		"hud_anchor": String(hud_anchor),
		"key_label_format": String(key_label_format),
		"mobile_controls_mode": String(mobile_controls_mode),
		"mobile_ui_scale": mobile_ui_scale,
		"mobile_tutorial_seen": mobile_tutorial_seen,
	}, "  "))
	return true


func _load() -> bool:
	var file := FileAccess.open(storage_path, FileAccess.READ)
	if file == null:
		return false
	var parsed = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return false
	var loaded_anchor := StringName(parsed.get("hud_anchor", "bottom_left"))
	var loaded_format := StringName(parsed.get("key_label_format", "compact"))
	var loaded_mobile := StringName(parsed.get("mobile_controls_mode", "auto"))
	if loaded_anchor in HUD_ANCHORS:
		hud_anchor = loaded_anchor
	if loaded_format in KEY_LABEL_FORMATS:
		key_label_format = loaded_format
	if loaded_mobile in MOBILE_CONTROL_MODES:
		mobile_controls_mode = loaded_mobile
	var loaded_scale: Variant = parsed.get("mobile_ui_scale", 1.25)
	if (loaded_scale is float or loaded_scale is int) and float(loaded_scale) in MOBILE_UI_SCALES:
		mobile_ui_scale = float(loaded_scale)
	mobile_tutorial_seen = parsed.get("mobile_tutorial_seen", false) == true
	return true


func _label_for(value: StringName) -> String:
	return {
		&"bottom_left": "좌하단",
		&"bottom_center": "하단 중앙",
		&"bottom_right": "우하단",
		&"compact": "간결",
		&"boxed": "대괄호",
		&"hidden": "키 숨김",
		&"auto": "터치 자동",
		&"on": "항상 표시",
		&"off": "항상 숨김",
	}.get(value, String(value))
