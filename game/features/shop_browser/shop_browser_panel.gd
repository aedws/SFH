class_name ShopBrowserPanel
extends Control

signal panel_visibility_changed(is_open: bool)

const PRESENTER := preload("res://game/features/shop_browser/shop_offer_presenter.gd")
const OFFER_CARD := preload("res://game/features/shop_browser/shop_offer_card.gd")

var provider: Node
var paused_before_open := false
var selected_id: StringName = &""
var selected_rotation := -1
var selected_quote: Dictionary = {}
var busy := false
var panel: PanelContainer
var cards: GridContainer
var offer_buttons: Dictionary = {}
var balance_label: Label
var detail_label: Label
var status_label: Label
var buy_button: Button
var reroll_button: Button
var close_button: Button


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group(&"game_modal_panel")
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_ui()
	resized.connect(_layout)
	visible = false
	_layout()


func configure(new_provider: Node) -> bool:
	if not is_instance_valid(new_provider): return false
	for method in [&"get_shop_snapshot", &"quote_shop_offer", &"purchase_shop_offer", &"reroll_shop"]:
		if not new_provider.has_method(method): return false
	if is_instance_valid(provider) and provider.has_signal(&"snapshot_changed") \
			and provider.is_connected(&"snapshot_changed", _on_snapshot_changed):
		provider.disconnect(&"snapshot_changed", _on_snapshot_changed)
	provider = new_provider
	if provider.has_signal(&"snapshot_changed"):
		provider.connect(&"snapshot_changed", _on_snapshot_changed)
	return true


func open_panel() -> void:
	if visible or not is_instance_valid(provider): return
	for other in get_tree().get_nodes_in_group(&"game_modal_panel"):
		if other == self or not other.visible: continue
		if other.has_method(&"request_leave"):
			other.call(&"request_leave", func():
				other.call(&"close_panel")
				open_panel())
			return
		if other.has_method(&"close_panel"): other.call(&"close_panel")
	paused_before_open = get_tree().paused
	selected_id = &""
	selected_quote.clear()
	selected_rotation = -1
	status_label.text = "가격과 수량을 확인한 뒤 아래 구매 버튼을 누르세요."
	visible = true
	move_to_front()
	get_tree().paused = true
	refresh()
	panel_visibility_changed.emit(true)
	close_button.grab_focus()


func close_panel() -> void:
	if not visible: return
	visible = false
	selected_id = &""
	selected_quote.clear()
	get_tree().paused = paused_before_open
	panel_visibility_changed.emit(false)


func _input(event: InputEvent) -> void:
	if visible and event.is_action_pressed(&"ui_cancel") and not event.is_echo():
		close_panel()
		get_viewport().set_input_as_handled()


func _on_snapshot_changed(_snapshot: Dictionary) -> void:
	if visible and not busy: refresh()


func refresh() -> void:
	if not is_instance_valid(provider): return
	var snapshot: Dictionary = provider.call(&"get_shop_snapshot")
	var revision := int(snapshot.get(&"rotation_index", -1))
	if selected_id != &"" and selected_rotation != revision:
		selected_id = &""
		selected_quote.clear()
		status_label.text = "매물이 갱신됐습니다 · 상품을 다시 선택하세요."
	balance_label.text = "보유 크레딧\n%d C" % int(snapshot.get(&"credits", 0))
	var reroll_quote: Dictionary = snapshot.get(&"reroll_quote", {})
	reroll_button.text = "매물 리롤 · %d C" % int(reroll_quote.get(&"price", 0))
	reroll_button.disabled = busy or not bool(reroll_quote.get(&"affordable", false))
	reroll_button.tooltip_text = (
		"현재 매물을 새 조합으로 바꿉니다. 선택만으로는 차감되지 않습니다."
		if not reroll_button.disabled else String(reroll_quote.get(&"reason", "리롤 불가"))
	)
	for child in cards.get_children():
		cards.remove_child(child)
		child.queue_free()
	offer_buttons.clear()
	for quote: Dictionary in snapshot.get(&"quotes", []):
		var offer: Dictionary = quote.get(&"offer", {})
		var id := StringName(offer.get(&"offer_id", &""))
		var button := OFFER_CARD.new()
		button.configure(quote)
		button.button_pressed = id == selected_id
		button.pressed.connect(select_offer.bind(id))
		cards.add_child(button)
		offer_buttons[id] = button
	if selected_id != &"":
		selected_quote = provider.call(&"quote_shop_offer", selected_id)
	_update_detail()


func select_offer(offer_id: StringName) -> void:
	if busy or not visible or not offer_buttons.has(offer_id): return
	selected_id = offer_id
	selected_quote = provider.call(&"quote_shop_offer", offer_id)
	selected_rotation = int(selected_quote.get(&"rotation_index", -1))
	for id in offer_buttons: offer_buttons[id].button_pressed = id == offer_id
	status_label.text = "선택 완료 · 아직 구매하지 않았습니다."
	_update_detail()


func _update_detail() -> void:
	detail_label.text = PRESENTER.detail(selected_quote)
	buy_button.disabled = busy or selected_id == &"" or not bool(selected_quote.get(&"purchasable", false))
	buy_button.text = "상품 선택 후 구매" if selected_id == &"" else "선택 상품 구매 · %d C" % int(selected_quote.get(&"offer", {}).get(&"price", 0))
	if selected_id != &"" and not bool(selected_quote.get(&"purchasable", false)):
		status_label.text = String(selected_quote.get(&"reason", "구매 불가"))


func purchase_selected() -> void:
	if busy or not visible or selected_id == &"" or buy_button.disabled: return
	busy = true
	buy_button.disabled = true
	var transaction_id := StringName("shop_ui_%d_%d" % [Time.get_ticks_usec(), get_instance_id()])
	var result: Dictionary = provider.call(&"purchase_shop_offer", selected_id, transaction_id, selected_rotation)
	busy = false
	selected_id = &""
	selected_quote.clear()
	refresh()
	if bool(result.get(&"success", false)):
		status_label.text = PRESENTER.receipt(result)
	else:
		status_label.text = "구매 실패 · %s" % result.get(&"reason", "상태 확인 필요")


func reroll_offers() -> void:
	if busy or not visible or reroll_button.disabled:
		return
	busy = true
	reroll_button.disabled = true
	var transaction_id := StringName("shop_reroll_ui_%d_%d" % [Time.get_ticks_usec(), get_instance_id()])
	var result: Dictionary = provider.call(&"reroll_shop", transaction_id)
	busy = false
	selected_id = &""
	selected_quote.clear()
	selected_rotation = -1
	refresh()
	if bool(result.get(&"success", false)):
		var snapshot: Dictionary = result.get(&"snapshot", {})
		status_label.text = "리롤 완료 · 매물 %d개가 교체됐습니다. 잔액과 새 가격을 확인하세요." % int(
			snapshot.get(&"last_changed_count", 0)
		)
	else:
		status_label.text = "리롤 실패 · %s" % result.get(&"reason", "상태 확인 필요")


func get_snapshot() -> Dictionary:
	return {&"visible": visible, &"selected_id": selected_id, &"selected_rotation": selected_rotation,
		&"selected_quote": selected_quote.duplicate(true), &"offer_count": offer_buttons.size(),
		&"columns": cards.columns, &"purchase_enabled": not buy_button.disabled,
		&"reroll_enabled": not reroll_button.disabled, &"reroll_text": reroll_button.text,
		&"status_text": status_label.text, &"panel_rect": panel.get_global_rect()}


func _build_ui() -> void:
	var backdrop := ColorRect.new()
	backdrop.color = Color(0.005, 0.02, 0.025, 0.94)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	panel = PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color("07151c")
	style.border_color = Color("02e5e1")
	style.set_border_width_all(1)
	style.set_content_margin_all(16)
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	panel.add_child(column)
	var header := HBoxContainer.new()
	column.add_child(header)
	var title := _label("보급소 / SUPPLY", 22)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	close_button = Button.new()
	close_button.text = "ESC · 닫기"
	close_button.custom_minimum_size.y = 40
	close_button.pressed.connect(close_panel)
	header.add_child(close_button)
	var economy_row := HBoxContainer.new()
	economy_row.add_theme_constant_override("separation", 10)
	column.add_child(economy_row)
	balance_label = _label("", 18)
	economy_row.add_child(balance_label)
	reroll_button = Button.new()
	reroll_button.custom_minimum_size = Vector2(180, 40)
	reroll_button.pressed.connect(reroll_offers)
	economy_row.add_child(reroll_button)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(scroll)
	var body := VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 12)
	scroll.add_child(body)
	cards = GridContainer.new()
	cards.columns = 3
	cards.add_theme_constant_override("h_separation", 10)
	cards.add_theme_constant_override("v_separation", 8)
	body.add_child(cards)
	var comparison_panel := PanelContainer.new()
	var comparison_style := StyleBoxFlat.new()
	comparison_style.bg_color = Color("10252d")
	comparison_style.border_color = Color("02e5e1")
	comparison_style.border_width_left = 3
	comparison_style.set_content_margin_all(12)
	comparison_panel.add_theme_stylebox_override("panel", comparison_style)
	body.add_child(comparison_panel)
	detail_label = _label(PRESENTER.detail({}), 15)
	comparison_panel.add_child(detail_label)
	status_label = _label("", 14)
	column.add_child(status_label)
	buy_button = Button.new()
	buy_button.text = "상품 선택 후 구매"
	buy_button.custom_minimum_size.y = 44
	buy_button.disabled = true
	buy_button.pressed.connect(purchase_selected)
	column.add_child(buy_button)


func _layout() -> void:
	if panel == null: return
	var target := Vector2(minf(1040, maxf(0, size.x - 24)), minf(660, maxf(0, size.y - 24)))
	panel.position = (size - target) * 0.5
	panel.size = target
	cards.columns = 1 if target.x < 740 else 3


func _label(text_value: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = text_value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color("daf6f4"))
	return label
