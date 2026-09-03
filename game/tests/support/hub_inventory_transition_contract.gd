extends RefCounted


func verify(tree: SceneTree, game: Node, tap: Callable, click: Callable) -> String:
	var bag_window = game.inventory_window
	var bench = game.equipment_workbench
	var bag = game.inventory_system
	var gear = game.equipment_system
	var original_bag: Dictionary = bag.export_runtime_state()
	var original_gear: Dictionary = gear.export_runtime_state()
	if game.run_started or bench.read_only or tree.paused:
		return "거점 로드아웃 편집 시작 상태가 올바르지 않음"
	for source in [KEY_I, KEY_U, KEY_E]:
		for destination in [KEY_I, KEY_U, KEY_E]:
			if source == destination:
				continue
			await tap.call(source)
			if bench.visible:
				bench.slot_buttons[&"main"].grab_focus()
			else:
				bag_window.tabs[0].grab_focus()
			await tap.call(destination)
			if bag_window.visible != (destination == KEY_I) or bench.visible != (destination != KEY_I) or not tree.paused:
				return "거점 I/U/E 직접 전환 또는 단일 창 표시 실패: %s→%s" % [source, destination]
			if bench.visible and bench.tabs.current_tab != (0 if destination == KEY_U else 1):
				return "U/E 직접 전환이 잘못된 탭을 표시함"
			await tap.call(KEY_ESCAPE)
			if bag_window.visible or bench.visible or tree.paused:
				return "거점 창 종료 후 입력/일시정지 복원 실패"
	# Reopening the same view via UI commands must not capture 'paused=true' as its baseline.
	bench.show_weapon_tab()
	bench.show_modification_tab()
	bench.show_armor_tab()
	await tap.call(KEY_ESCAPE)
	if tree.paused:
		return "이미 열린 장비 창 재진입 후 ESC가 거점을 영구 일시정지시킴"
	await tap.call(KEY_U)
	bench._select_slot(&"main")
	for _frame in 4:
		await tree.process_frame
	var candidate: Button
	for card in bench.equipment_inventory_grid.get_children():
		if card is Button and not card.disabled:
			candidate = card
			break
	if candidate == null:
		return "거점 교체용 무기 카드 없음"
	await click.call(candidate)
	var selected: Resource = bench.selected_inventory_entry.get(&"linked_resource")
	await click.call(bench.equip_selected_button)
	await tap.call(KEY_I)
	if bag_window.session.equipment.get_equipment_state(&"main").definition != selected or bag_window.session.conflicted:
		return "U에서 실제 교체한 무기가 I의 새 편집본에 반영되지 않음"
	# I draft -> E: cancel stays in draft; save commits, then E -> I starts fresh.
	var entry: Dictionary = bag_window.session.inventory.get_snapshot()[&"items"][0]
	var destination := _empty_position(bag_window.session.inventory, entry)
	if not bag_window.session.move_item(entry[&"instance_id"], destination):
		return "전환 검증용 가방 이동 실패"
	await tap.call(KEY_E)
	if not bag_window.confirmation_visible or bench.visible:
		return "I→E가 미저장 세팅을 무시하고 열림"
	await tap.call(KEY_ESCAPE)
	if not bag_window.visible or not bag_window.session.dirty or bench.visible:
		return "I→E 이탈 취소가 편집을 보존하지 못함"
	await tap.call(KEY_E)
	await click.call(bag_window.confirm_buttons[0])
	if not bench.visible or bench.tabs.current_tab != 1 or bag.placements[entry[&"instance_id"]] != destination:
		return "I 저장 후 E 전환 실패"
	# Install a compatible module and part via actual action buttons; reopen I after each change.
	for kind in [&"module", &"part"]:
		bench._select_slot(&"main")
		var item := {}
		for option: Dictionary in bag.get_items_by_type(kind):
			if bench._can_install_entry(gear.get_equipment_state(&"main"), option):
				item = option
				break
		if item.is_empty():
			return "거점 호환 모듈/파츠 없음: %s" % kind
		bench._select_inventory_candidate(item, &"modification")
		await click.call(bench.install_selected_modification_button)
		await tap.call(KEY_I)
		var state: Resource = bag_window.session.equipment.get_equipment_state(&"main")
		if (kind == &"module" and state.installed_modules.size() != 1) or (kind == &"part" and state.installed_parts.size() != 1):
			return "E 장착 결과가 I 편집본에서 누락됨: %s" % kind
		await tap.call(KEY_E)
		var installed_id: StringName = state.installed_modules[0].instance_id if kind == &"module" else state.installed_parts[0].part_id
		bench._select_installed(kind, installed_id)
		await click.call(bench.uninstall_selected_button)
		await tap.call(KEY_I)
		state = bag_window.session.equipment.get_equipment_state(&"main")
		if not state.installed_modules.is_empty() or not state.installed_parts.is_empty():
			return "E 해제 결과가 I 편집본에 반영되지 않음"
		await tap.call(KEY_E)
	await tap.call(KEY_ESCAPE)
	bag.restore_runtime_state(original_bag)
	gear.restore_runtime_state(original_gear)
	return "" if not tree.paused else "거점 편집 종료 후 일시정지 잔류"


func _empty_position(bag: Node, entry: Dictionary) -> Vector2i:
	for y in bag.grid_size.y:
		for x in bag.grid_size.x:
			var cell := Vector2i(x, y)
			if cell != entry[&"position"] and bag.can_place(entry[&"grid_size"], cell, entry[&"instance_id"]):
				return cell
	return Vector2i(-1, -1)
