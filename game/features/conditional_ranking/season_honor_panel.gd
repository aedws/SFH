class_name SeasonHonorPanel
extends "res://game/features/presentation_theme/game_dossier.gd"
var profile: Node
var selectors: Dictionary = {}
var rebuilding := false


func configure(source: Node) -> void:
	profile = source
	title = "명예의 전당 · 칭호와 오라"
	var help := Label.new()
	help.text = "마감된 시즌의 조건별 순위로 지급 · 능력치 변화 없음\n기기 로컬 보상이며 온라인 경쟁 보상이 아닙니다."
	help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(help)
	for kind in ["title", "aura"]:
		var selector := OptionButton.new()
		selector.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		selector.custom_minimum_size.y = 36
		selector.add_theme_icon_override(&"arrow", GameUI.icon("honor"))
		selector.item_selected.connect(func(index):
			if not rebuilding:
				profile.call(&"equip", kind, String(selector.get_item_metadata(index)))
		)
		content.add_child(selector)
		selectors[kind] = selector
	var evidence := RichTextLabel.new()
	evidence.name = "Evidence"
	evidence.fit_content = true
	evidence.custom_minimum_size.y = 130
	content.add_child(evidence)
	profile.changed.connect(_refresh)
	_refresh()


func _refresh() -> void:
	rebuilding = true
	var state: Dictionary = profile.call(&"get_snapshot")
	var owned: Dictionary = state["owned"]
	for kind in selectors:
		var selector: OptionButton = selectors[kind]
		selector.clear()
		selector.add_item(("칭호" if kind == "title" else "오라") + " · 해제")
		selector.set_item_metadata(0, "")
		for id in owned:
			if String(owned[id].get("kind", "")) != kind:
				continue
			selector.add_item(String(owned[id].get("display_name", id)))
			var index := selector.item_count - 1
			selector.set_item_metadata(index, id)
			if state["equipped"].get(kind, "") == id:
				selector.select(index)
		selector.disabled = not String(state.get("storage_error", "")).is_empty()
	var lines := PackedStringArray([String(state.get("storage_error", ""))])
	for receipt in state["receipts"].values():
		var reward: Dictionary = owned.get(receipt.get("reward_id", ""), {})
		var mode := String(receipt.get("ranking_id", ""))
		lines.append("%s · %s\n%s %d위 → %s" % [receipt.get("season_id", ""), receipt.get("condition", ""), {"loot": "회수 가치", "speedrun": "탈출 시간", "kills": "처치"}.get(mode, "조건부 기록"), int(receipt.get("rank", 0)), reward.get("display_name", "시즌 보상")])
	if state["receipts"].is_empty():
		lines.append("아직 지급된 보상이 없습니다.\n시즌 조건으로 탈출한 후 주간 마감 시 지급됩니다.")
	content.get_node("Evidence").text = "\n".join(lines)
	rebuilding = false
