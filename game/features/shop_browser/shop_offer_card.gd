class_name ShopOfferCard
extends Button
## A selectable quote, never a purchase action. The provider owns all values.

const ICON := preload("res://game/features/run_setup/tactical_hud_icon.gd")
const PRESENTER := preload("res://game/features/shop_browser/shop_offer_presenter.gd")


func configure(quote: Dictionary) -> void:
	var offer: Dictionary = quote.get(&"offer", {})
	var quality := String(offer.get(&"quality", "standard"))
	var accent := Color("02e5e1")
	if quality == "damaged": accent = Color("ffc17c")
	elif quality == "high_performance": accent = Color("c6acff")
	toggle_mode = true
	custom_minimum_size = Vector2(0, 164)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tooltip_text = PRESENTER.card(quote) + "\n" + PRESENTER.detail(quote)
	for state in ["normal", "hover", "pressed", "hover_pressed", "focus"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color("153139") if state in ["pressed", "hover_pressed"] else Color("0b1922")
		style.border_color = accent if state != "normal" else Color("34515c")
		style.set_border_width_all(2 if state in ["pressed", "hover_pressed", "focus"] else 1)
		style.border_width_top = 3
		add_theme_stylebox_override(state, style)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 12)
	add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	margin.add_child(column)
	column.add_child(_label(String(quote.get(&"quality_label", "품질 확인 필요")), 13, accent))
	var row := HBoxContainer.new()
	column.add_child(row)
	var icon := ICON.new()
	icon.configure(ICON.Kind.INTERACT, "보급품", accent)
	icon.custom_minimum_size = Vector2(42, 42)
	row.add_child(icon)
	var item_name := _label(String(offer.get(&"display_name", "알 수 없는 상품")), 18, Color("e8f5f6"))
	item_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(item_name)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(spacer)
	column.add_child(_label("%d C   /   %d개" % [int(offer.get(&"price", 0)), int(offer.get(&"quantity", 0))], 22, accent))
	var hint := _label("", 12, Color("a4bdc7"))
	column.add_child(hint)
	hint.text = "선택하여 구매 견적 확인"
	toggled.connect(func(selected: bool): hint.text = "선택됨 · 아래에서 구매 확정" if selected else "선택하여 구매 견적 확인")
	_ignore_pointer(margin)


func _ignore_pointer(node: Control) -> void:
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in node.get_children():
		if child is Control: _ignore_pointer(child)


func _label(value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label
