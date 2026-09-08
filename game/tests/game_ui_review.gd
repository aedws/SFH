extends Node
## Local visual fixture. Never selected by the application entry point.
## Browser driver advances each frame only after taking its screenshot.
var game: Node

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_run.call_deferred()

func _run() -> void:
	game = load("res://game/scenes/game.tscn").instantiate()
	var manifest: Resource = game.features.duplicate(true)
	for key in ["persistent_profile_storage_path", "conditional_ranking_storage_path", "meta_progression_storage_path", "key_mapping_storage_path", "skill_binding_storage_path", "presentation_settings_storage_path"]:
		manifest.set(key, "user://ui_review_" + key + ".json")
	game.features = manifest
	add_child(game)
	await _capture("hub")
	game.hub_preparation_panel.open_panel()
	await _capture("preparation")
	game._open_hub_archive(&"craft")
	await _capture("workshop")
	var archive = game.hub_archive_panel
	if archive.cards.get_child_count() > 0:
		archive.cards.get_child(0).pressed.emit()
	await _capture("workshop_quote")
	archive.close_panel()
	game._open_hub_archive(&"codex")
	await _capture("codex")
	game.hub_archive_panel.close_panel()
	game.hub_preparation_panel.close_panel()
	game._toggle_training_session()
	await _capture("training")
	game._finish_hub_training()
	game.shop_browser_panel.open_panel()
	await _capture("shop")
	game.shop_browser_panel.close_panel()
	game.inventory_window.open_panel()
	await _capture("bag")
	game.inventory_window.request_tab(1)
	await _capture("weapon_parts")
	game.inventory_window.request_tab(2)
	await _capture("modules")
	game.inventory_window.close_panel()
	game.equipment_workbench.open_panel()
	await _capture("equipment")
	game.equipment_workbench.tabs.current_tab = 1
	await _capture("upgrade")
	game.equipment_workbench.close_panel()
	game.key_mapping_panel.open_panel()
	await _capture("keys")
	var tabs = game.key_mapping_panel.find_children("*", "TabContainer", true, false)[0]
	tabs.current_tab = 1
	await _capture("skill_mapping")
	tabs.current_tab = 2
	await _capture("hud_settings")
	game.key_mapping_panel.close_panel()
	game._open_run_setup()
	await _capture("operation_1")
	game.operation_setup_presenter.step_relative(1)
	await _capture("operation_2")
	game.operation_setup_presenter.step_relative(1)
	await _capture("operation_3")
	game.operation_setup_presenter.season_history_dialog.popup_centered()
	await _capture("season_history")
	game.operation_setup_presenter.season_history_dialog.close_panel()
	game.conditional_ranking_system.show_honors(game.ui_layer)
	await _capture("honors")
	game.conditional_ranking_system.honor_panel.close_panel()
	game._start_selected_run()
	await _capture("combat")
	var comparison := FieldLootComparisonPanel.new()
	game.ui_layer.add_child(comparison)
	comparison.show_comparison({"display_name": "전술 돌격소총", "candidate_grade": 3, "item_type": "weapon", "comparison_label": "공격력 상승", "active_weapon_name": "제식 권총", "family_label": "장비", "use_label": "즉시 장착 가능", "extract_label": "탈출 시 보관", "death_label": "사망 시 소실", "equip_preview": {"available": true, "previous_destination_label": "기존 장비는 가방으로"}})
	await _capture("loot_compare")
	comparison.show_acquisition_error("가방 공간이 부족합니다")
	await _capture("loot_blocked")
	comparison.free()
	game.presentation_settings_service.set_mobile_controls_mode(&"on", false)
	await _capture("mobile_combat")
	var tutorial := MobileTutorialPopup.new()
	game.ui_layer.add_child(tutorial)
	await _capture("mobile_tutorial")
	tutorial.free()
	game.presentation_settings_service.set_mobile_controls_mode(&"off", false)
	game.minimap.set_expanded(true)
	await _capture("expanded_map")
	game.minimap.set_expanded(false)
	var choices: Array[Dictionary] = game.run_buff_system.prepare_choices(2, 3)
	game.run_buff_selector.open_choices(2, choices)
	await _capture("augment")
	game.run_buff_selector.close_panel()
	# Use the real end-of-run UI boundary; showing just the result panel would
	# artificially leave live HUD/tutorial layers above it.
	game._finish_run("생환 성공", "회수 기록 테스트", {"extracted": true})
	game.operation_result_presenter.render({"extracted": true, "map_name": "물류 창고", "elapsed_seconds": 426, "kills": 142, "operation_credits": 650, "salvage": 12}, "생환 성공", "회수 기록 테스트")
	await _capture("extracted")
	game.operation_result_presenter.render({"extracted": false, "elapsed_seconds": 426, "kills": 142, "operation_credits": 650}, "신호 소실", "손실 기록 테스트")
	await _capture("defeated")
	if OS.has_feature("web"): JavaScriptBridge.eval("window.sfhReviewDone=true")
	else: get_tree().quit()

func _capture(id: String) -> void:
	for _frame in 12: await get_tree().process_frame
	var bounded_panel: Control = null
	if id == "preparation": bounded_panel = game.hub_preparation_panel.panel
	if id in ["keys", "skill_mapping", "hud_settings"]: bounded_panel = game.key_mapping_panel.settings_panel
	if bounded_panel != null and not Rect2(Vector2.ZERO, get_viewport().get_visible_rect().size).encloses(bounded_panel.get_global_rect()):
		push_error("UI review bounds failed: " + id)
	if get_tree().paused and is_instance_valid(game.training_telemetry_presenter) and game.training_telemetry_presenter.is_visible_in_tree():
		push_error("Training HUD leaked over modal: " + id)
	if id == "mobile_combat" and game.operation_tutorial_overlay.visible:
		if game.operation_tutorial_overlay.panel.get_global_rect().intersects(game.mobile_control_pad.menu_group.get_global_rect()):
			push_error("Mobile tutorial overlaps menu")
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.sfhReviewAdvance=false;window.sfhReviewFrame=" + JSON.stringify(id))
		while not bool(JavaScriptBridge.eval("window.sfhReviewAdvance===true")):
			await get_tree().process_frame
	print("UI_REVIEW_FRAME ", id)
