class_name EquipmentScreenLayout
extends RefCounted
## Presentation proportions only; never owns equipment or edit transactions.
const BREAKPOINT := 1000.0

static func inventory(width: float, parts: bool) -> Dictionary:
	var narrow := width < BREAKPOINT
	return {"narrow": narrow,
		"loadout": 0.0 if narrow else clampf(width * 0.23, 240, 300),
		"inspect": 0.0 if narrow else clampf(width * 0.19, 200, 250),
		"parts": 0.0 if narrow else clampf(width * 0.40, 380, 760) if parts else 190.0}

static func module_columns(width: float) -> Dictionary:
	var narrow := width < 900
	var left := 0.0 if narrow else clampf(width * 0.22, 190, 260)
	var right := 0.0 if narrow else 220.0
	var center := width if narrow else width - left - right - 28
	return {"narrow": narrow, "left": left, "right": right,
		"cards": clampi(floori((center + 4) / 116.0), 1, 5)}
