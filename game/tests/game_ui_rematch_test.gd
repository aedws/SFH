extends SceneTree
const PANEL = preload("res://game/features/p5_hub_progression/hub_archive_panel.gd")
var failures: Array[String] = []

class CatalogFixture extends Node:
	var writes := 0
	var credits := 100
	var fail_save := false
	func get_workshop_candidates() -> Array:
		return [{"recipe_id": &"future_recipe", "display_name": "미래 제공자 도면", "status_label": "재제작 가능", "credit_cost": 40}]
	func quote_workshop_recipe(_id: StringName) -> Dictionary:
		return {"craftable": credits >= 40, "credit_cost": 40, "credits": credits,
			"reason": "크레딧 부족", "material_preview": [{"item_id": "salvage", "owned": 2, "required": 1, "ready": true}]}
	func craft_recipe(_id: StringName, _transaction: StringName) -> Dictionary:
		if fail_save: return {"success": false, "reason": "저장 실패"}
		if credits < 40: return {"success": false, "reason": "크레딧 부족"}
		writes += 1
		credits -= 40
		return {"success": true, "balance_after": credits, "item": {"affix_count": 1, "socket_count": 2}}
	func get_codex_entries() -> Array:
		return [{"entry_id": "future_codex", "display_name": "다음 수집품", "region_hint": "research_complex", "progress": 2, "required_count": 3, "completed": false}]

func _init() -> void: _run.call_deferred()

func _run() -> void:
	var fixture := CatalogFixture.new()
	root.add_child(fixture)
	for dimensions in [Vector2i(1280,720), Vector2i(960,540), Vector2i(640,360)]:
		var view := SubViewport.new()
		view.size = dimensions
		root.add_child(view)
		var panel = PANEL.new()
		view.add_child(panel)
		panel.configure(fixture, &"craft")
		panel.popup_centered(Vector2i(760,600))
		for _frame in 8: await process_frame
		_check(Rect2(Vector2.ZERO, Vector2(dimensions)).encloses(panel.panel.get_global_rect()), "dossier bounds %s actual=%s host=%s minimum=%s" % [dimensions, panel.panel.get_global_rect(), panel.size, panel.panel.get_combined_minimum_size()])
		_check(panel.panel.get_global_rect().encloses(panel.close_button.get_global_rect()), "close reachable %s" % dimensions)
		_check(panel.craft_button.disabled and fixture.writes == 0, "browse must not spend")
		panel.cards.get_child(0).pressed.emit()
		_check(not panel.craft_button.disabled and fixture.writes == 0 and "고철" in panel.detail.text, "select shows quote only")
		panel.close_panel()
		_check(not paused, "pause restored")
		view.free()
	var panel = PANEL.new()
	root.add_child(panel)
	panel.configure(fixture, &"craft")
	panel.selected_recipe = &"future_recipe"
	fixture.fail_save = true
	panel.craft_selected()
	_check(fixture.writes == 0 and fixture.credits == 100 and "저장 실패" in panel.receipt.text, "failed command visible, no false reward")
	fixture.fail_save = false
	panel.craft_selected()
	_check(fixture.writes == 1 and fixture.credits == 60 and "제작 완료" in panel.receipt.text, "one command one receipt")
	fixture.credits = 0
	panel.refresh()
	_check(panel.craft_button.disabled and "크레딧 부족" in panel.detail.text, "insufficient resources disabled with reason")
	panel.free()
	panel = PANEL.new()
	root.add_child(panel)
	panel.configure(fixture, &"codex")
	_check(panel.cards.get_child_count() == 1 and not panel.craft_button.visible and fixture.writes == 1, "codex read-only future rows")
	panel.free()
	fixture.free()
	if failures.is_empty(): print("GAME_UI_REMATCH_OK views_3 browse_select_no_debit explicit_craft failure_receipt future_catalog codex_readonly close_pause")
	else:
		for failure in failures: printerr("GAME_UI_REMATCH_FAILED ", failure)
	quit(0 if failures.is_empty() else 1)

func _check(condition: bool, message: String) -> void:
	if not condition: failures.append(message)
