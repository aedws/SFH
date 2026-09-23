class_name HubArchivePanel
extends "res://game/features/presentation_theme/game_dossier.gd"
## A catalog view over public quotes. Only the explicit craft button issues a command.
var provider: Node
var mode := &"codex"
var cards: GridContainer
var detail: Label
var receipt: Label
var craft_button: Button
var selected_recipe := &""
var busy := false

func configure(source: Node, archive_mode: StringName) -> void:
	provider = source
	mode = archive_mode
	title = "제작소 · 회수한 도면으로 제작" if mode == &"craft" else "회수 도감 · 다음 목표 찾기"
	cards = GridContainer.new()
	cards.add_theme_constant_override("h_separation", 10)
	cards.add_theme_constant_override("v_separation", 10)
	content.add_child(cards)
	detail = Label.new()
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(detail)
	craft_button = Button.new()
	craft_button.text = "도면을 선택하세요"
	UI.action(craft_button, "craft", true)
	craft_button.pressed.connect(craft_selected)
	content.add_child(craft_button)
	receipt = Label.new()
	receipt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	receipt.add_theme_color_override("font_color", UI.GOLD)
	content.add_child(receipt)
	resized.connect(_fit_cards)
	refresh()

func refresh() -> void:
	for child in cards.get_children():
		cards.remove_child(child)
		child.queue_free()
	craft_button.visible = mode == &"craft"
	if mode == &"craft":
		var candidates: Array = provider.call(&"get_workshop_candidates")
		for candidate: Dictionary in candidates:
			var id := StringName(candidate.get(&"recipe_id", &""))
			var card := Button.new()
			card.text = "%s\n%s · %d C" % [candidate.get(&"display_name", "미확인 도면"), candidate.get(&"status_label", ""), int(candidate.get(&"credit_cost", 0))]
			card.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			card.size_flags_horizontal = SIZE_EXPAND_FILL
			card.toggle_mode = true
			card.set_pressed_no_signal(id == selected_recipe)
			UI.action(card, "craft")
			card.pressed.connect(func(): selected_recipe = id; receipt.text = ""; refresh())
			cards.add_child(card)
		if candidates.is_empty(): detail.text = "아직 제작 가능한 도면 목록이 없습니다."
		_refresh_quote()
	else:
		var entries: Array = provider.call(&"get_codex_entries")
		detail.text = "전리품을 가지고 탈출하면 수집 기록이 쌓입니다."
		if entries.is_empty(): detail.text = "아직 등록된 수집 목표가 없습니다."
		for entry: Dictionary in entries:
			var card := PanelContainer.new()
			card.size_flags_horizontal = SIZE_EXPAND_FILL
			card.add_theme_stylebox_override("panel", UI.surface(UI.GOLD, bool(entry.get(&"completed", false))))
			cards.add_child(card)
			var column := VBoxContainer.new()
			card.add_child(column)
			var label := Label.new()
			label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			var region: String = {"ruined_city": "폐허 도시", "industrial_district": "산업 지구", "research_complex": "연구 단지"}.get(String(entry.get(&"region_hint", "")), "지역 정보 없음")
			label.text = "%s\n%s · %d / %d\n수색 지역: %s" % [entry.get(&"display_name", "수집 목표"), "수집 완료" if entry.get(&"completed", false) else "회수 대기", int(entry.get(&"progress", 0)), int(entry.get(&"required_count", 1)), region]
			column.add_child(label)
			var bar := ProgressBar.new()
			bar.max_value = maxi(1, int(entry.get(&"required_count", 1)))
			bar.value = int(entry.get(&"progress", 0))
			bar.show_percentage = false
			bar.custom_minimum_size.y = 6
			column.add_child(bar)
	_fit_cards()

func _refresh_quote() -> void:
	craft_button.disabled = true
	if selected_recipe == &"":
		detail.text = "도면을 선택하면 재료와 제작 비용을 확인할 수 있습니다. 선택만으로는 재화를 소모하지 않습니다."
		return
	var quote: Dictionary = provider.call(&"quote_workshop_recipe", selected_recipe)
	var lines := PackedStringArray(["필요 %d C / 보유 %d C" % [int(quote.get(&"credit_cost", 0)), int(quote.get(&"credits", 0))]])
	for material: Dictionary in quote.get(&"material_preview", []):
		var id := String(material.get(&"item_id", ""))
		var label: String = {"scrap": "고철", "salvage": "고철", "field_medkit": "응급키트"}.get(id, id)
		lines.append("%s  %d / %d  %s" % [label, int(material.get(&"owned", 0)), int(material.get(&"required", 0)), "충족" if material.get(&"ready", false) else "부족"])
	lines.append("옵션과 소켓은 제작 시 결정 · 결과는 영구 제작 기록에 보관")
	var preview: Dictionary = quote.get(&"roll_preview", {})
	if not preview.is_empty():
		lines.append(String(preview.get(&"supply_policy", "")))
		lines.append("이 도면의 소켓 %d~%d · 기존 보유 장비는 변경하지 않음" % [int(preview.get(&"minimum_sockets", 0)), int(preview.get(&"maximum_sockets", 0))])
	var ready := bool(quote.get(&"craftable", false))
	if not ready: lines.append(String(quote.get(&"reason", "제작 불가")))
	detail.text = "\n".join(lines)
	craft_button.text = "제작 확정 · %d C" % int(quote.get(&"credit_cost", 0))
	craft_button.disabled = not ready or busy

func craft_selected() -> void:
	if busy or selected_recipe == &"": return
	busy = true
	craft_button.disabled = true
	var result: Dictionary = provider.call(&"craft_recipe", selected_recipe, StringName("workshop_ui_%d" % Time.get_ticks_usec()))
	busy = false
	refresh()
	if result.get(&"success", false):
		var item: Dictionary = result.get(&"item", {})
		receipt.text = "제작 완료 · 옵션 %d / 소켓 %d · 잔액 %d C" % [int(item.get(&"affix_count", 0)), int(item.get(&"socket_count", 0)), int(result.get(&"balance_after", 0))]
	else: receipt.text = "제작 보류 · " + String(result.get(&"reason", "상태를 확인하세요"))

func _fit_cards() -> void:
	if cards != null: cards.columns = 1 if size.x < 700 else 2
