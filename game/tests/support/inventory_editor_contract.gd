extends RefCounted

const SESSION = preload("res://game/features/inventory/inventory_edit_session.gd")
const GRID = preload("res://game/features/inventory/grid_inventory.gd")
const WINDOW = preload("res://game/features/inventory/inventory_window.tscn")


func verify(tree: SceneTree, game: Node) -> String:
	var fixture := Node.new()
	tree.root.add_child(fixture)
	var editor = SESSION.new()
	fixture.add_child(editor)
	var bag = GRID.new()
	fixture.add_child(bag)
	bag.restore_runtime_state(game.inventory_system.export_runtime_state())
	var gear: Node = game.equipment_system.create_edit_copy(editor)
	fixture.add_child(gear)
	editor.configure(bag, gear)
	editor.begin()
	var original: Dictionary = bag.export_runtime_state()
	var error := _verify_transactions(editor, bag, gear)
	if not error.is_empty():
		fixture.queue_free()
		return error
	bag.restore_runtime_state(original)
	for viewport_size in [Vector2i(1280, 720), Vector2i(1024, 720), Vector2i(768, 720), Vector2i(390, 844)]:
		var viewport := SubViewport.new()
		viewport.size = viewport_size
		viewport.process_mode = Node.PROCESS_MODE_ALWAYS
		tree.root.add_child(viewport)
		var window = WINDOW.instantiate()
		viewport.add_child(window)
		window.configure(bag, gear)
		window.open_panel()
		for tab in 3:
			window.request_tab(tab)
			for _frame in 8:
				await tree.process_frame
			var bounds := Rect2(Vector2.ZERO, Vector2(viewport_size))
			if not bounds.encloses(window.get_global_rect()):
				return "인벤토리 화면 경계 실패: %s tab %d rect %s" % [viewport_size, tab, window.get_global_rect()]
			if tab != 2 and window.bag_scroll.get_h_scroll_bar().visible:
				return "가방에 불필요한 가로 스크롤 발생: %s" % viewport_size
			if tab != 2 and window.grid_view.custom_minimum_size.x > window.bag_scroll.size.x:
				return "가방 마지막 열 잘림: %s / %s" % [viewport_size, window.get_density_snapshot()]
			if not window.tabs[tab].button_pressed:
				return "선택 탭 시각 상태 실패"
		# Fill the bag vertically and verify scroll actually reaches its last row.
		window.request_tab(0) # The module workspace deliberately hides the bag grid.
		for _frame in 8: await tree.process_frame
		window.bag_scroll.scroll_vertical = 10000
		await tree.process_frame
		var bottom: float = window.grid_view.get_global_rect().end.y
		if bottom > window.bag_scroll.get_global_rect().end.y + 2:
			return "가방 세로 스크롤 마지막 행 접근 실패"
		window.close_panel()
		viewport.queue_free()
		await tree.process_frame
	fixture.queue_free()
	await tree.process_frame
	return ""


func _verify_transactions(editor: Node, bag: Node, gear: Node) -> String:
	var entries: Array = bag.get_snapshot()[&"items"]
	var first: Dictionary = entries[0]
	var id: StringName = first[&"instance_id"]
	var before: Vector2i = first[&"position"]
	var destination := _empty_position(editor.inventory, first)
	if not editor.move_item(id, destination) or not editor.dirty or bag.placements[id] != before:
		return "가방 임시 이동이 원본에 유출되거나 변경 상태가 누락됨"
	if editor.move_item(id, Vector2i(-1, 0)) or editor.move_item(id, entries[1][&"position"]):
		return "가방 겹침·경계 밖 이동을 허용함"
	if not editor.commit() or bag.placements[id] != destination or editor.dirty:
		return "가방 저장 적용 실패"
	editor.begin()
	if not editor.move_item(id, before):
		return "두 번째 편집 시작 실패"
	editor.begin()
	if editor.inventory.placements[id] != destination or editor.dirty:
		return "변경 취소가 저장된 상태를 복구하지 않음"
	var module_id: StringName
	var weapon_id: StringName
	var armor_id: StringName
	for entry: Dictionary in editor.inventory.get_snapshot()[&"items"]:
		if entry[&"item_type"] == &"module" and module_id == &"":
			module_id = entry[&"instance_id"]
		if entry[&"item_type"] == &"weapon" and gear.can_equip_definition(&"main", entry[&"linked_resource"]):
			weapon_id = entry[&"instance_id"]
		if entry[&"item_type"] == &"armor":
			armor_id = entry[&"instance_id"]
	var count_before: int = editor.inventory.items.size()
	if editor.equip_item(armor_id, &"main") or editor.inventory.items.size() != count_before or editor.dirty:
		return "잘못된 슬롯 장착 실패가 아이템/dirty 상태를 변경함"
	if not editor.equip_item(weapon_id, &"main") or not bag.items.has(weapon_id):
		return "장비 임시 교체가 실패하거나 원본에서 아이템을 제거함"
	if not editor.install_item(module_id, &"main"):
		return "무기 모듈 장착 실패: %s" % editor.error_message
	var state: Resource = editor.equipment.get_equipment_state(&"main")
	if state.installed_modules.is_empty() or not gear.get_equipment_state(&"main").installed_modules.is_empty():
		return "모듈 편집 원본 격리 실패"
	if not editor.remove_modification(&"main", &"module", module_id):
		return "모듈 해제 실패"
	if not editor.unequip_item(&"main"):
		return "장비 해제 실패"
	# A full draft bag must not lose an equipped item.
	editor.begin()
	var filler: Resource = load("res://game/features/inventory/items/ballistic_core_item.tres")
	while editor.inventory.add_item(filler) != &"":
		pass
	var full_count: int = editor.inventory.items.size()
	if editor.unequip_item(&"main") or editor.inventory.items.size() != full_count or editor.equipment.get_equipment_state(&"main") == null:
		return "가방 가득 참 해제 실패에서 아이템 손실"
	editor.begin()
	editor.move_item(id, before)
	bag.move_item(id, before)
	if editor.commit() or not editor.conflicted or not editor.dirty:
		return "원본 변경 충돌을 무시하고 저장함"
	return ""


func _empty_position(bag: Node, entry: Dictionary) -> Vector2i:
	for y in bag.grid_size.y:
		for x in bag.grid_size.x:
			var cell := Vector2i(x, y)
			if cell != entry[&"position"] and bag.can_place(entry[&"grid_size"], cell, entry[&"instance_id"]):
				return cell
	return Vector2i(-1, -1)
