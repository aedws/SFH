extends RefCounted

## 플레이 단계마다 유효한 UI 레이어·일시정지·화면 경계·겹침을 한 계약으로 판정합니다.

const LAYER_IDS := [
	&"hub_hud",
	&"run_setup",
	&"combat_hud",
	&"game_result",
	&"key_mapping",
	&"inventory",
	&"equipment",
	&"minimap",
	&"combat_skills",
	&"dash_cooldown",
	&"interaction",
]

const STATE_RULES := {
	&"hub": {
		&"visible": [&"hub_hud"],
		&"hidden": [&"run_setup", &"combat_hud", &"game_result", &"key_mapping", &"inventory", &"equipment", &"minimap", &"combat_skills", &"dash_cooldown"],
		&"paused": false,
		&"modal_count": 0,
		&"inside_viewport": [&"hub_hud"],
	},
	&"key_mapping_hub": {
		&"visible": [&"key_mapping"],
		&"hidden": [&"hub_hud", &"run_setup", &"combat_hud", &"game_result", &"inventory", &"equipment", &"minimap", &"combat_skills", &"dash_cooldown"],
		&"paused": true,
		&"modal_count": 1,
		&"inside_viewport": [&"key_mapping"],
	},
	&"inventory_hub": {
		&"visible": [&"inventory"],
		&"hidden": [&"hub_hud", &"run_setup", &"combat_hud", &"game_result", &"key_mapping", &"equipment", &"minimap", &"combat_skills", &"dash_cooldown"],
		&"paused": true,
		&"modal_count": 1,
		&"inside_viewport": [&"inventory"],
	},
	&"equipment_hub": {
		&"visible": [&"equipment"],
		&"hidden": [&"hub_hud", &"run_setup", &"combat_hud", &"game_result", &"key_mapping", &"inventory", &"minimap", &"combat_skills", &"dash_cooldown"],
		&"paused": true,
		&"modal_count": 1,
		&"inside_viewport": [&"equipment"],
		&"equipment_tab": 0,
	},
	&"modification_hub": {
		&"visible": [&"equipment"],
		&"hidden": [&"hub_hud", &"run_setup", &"combat_hud", &"game_result", &"key_mapping", &"inventory", &"minimap", &"combat_skills", &"dash_cooldown"],
		&"paused": true,
		&"modal_count": 1,
		&"inside_viewport": [&"equipment"],
		&"equipment_tab": 1,
	},
	&"run_setup": {
		&"visible": [&"run_setup"],
		&"hidden": [&"hub_hud", &"combat_hud", &"game_result", &"key_mapping", &"inventory", &"equipment", &"minimap", &"combat_skills", &"dash_cooldown", &"interaction"],
		&"paused": true,
		&"modal_count": 0,
		&"inside_viewport": [&"run_setup"],
	},
	&"combat": {
		&"visible": [&"combat_hud", &"minimap", &"combat_skills", &"dash_cooldown"],
		&"hidden": [&"hub_hud", &"run_setup", &"game_result", &"key_mapping", &"inventory", &"equipment"],
		&"paused": false,
		&"modal_count": 0,
		&"inside_viewport": [&"combat_hud", &"minimap", &"combat_skills", &"dash_cooldown"],
		&"non_overlapping": [[&"minimap", &"combat_skills"], [&"minimap", &"dash_cooldown"], [&"combat_skills", &"dash_cooldown"]],
	},
	&"inventory_combat": {
		&"visible": [&"inventory"],
		&"hidden": [&"hub_hud", &"run_setup", &"combat_hud", &"game_result", &"key_mapping", &"equipment", &"minimap", &"combat_skills", &"dash_cooldown"],
		&"paused": true,
		&"modal_count": 1,
		&"inside_viewport": [&"inventory"],
	},
	&"equipment_combat": {
		&"visible": [&"equipment"],
		&"hidden": [&"hub_hud", &"run_setup", &"combat_hud", &"game_result", &"key_mapping", &"inventory", &"minimap", &"combat_skills", &"dash_cooldown"],
		&"paused": true,
		&"modal_count": 1,
		&"inside_viewport": [&"equipment"],
		&"equipment_tab": 0,
	},
	&"modification_combat": {
		&"visible": [&"equipment"],
		&"hidden": [&"hub_hud", &"run_setup", &"combat_hud", &"game_result", &"key_mapping", &"inventory", &"minimap", &"combat_skills", &"dash_cooldown"],
		&"paused": true,
		&"modal_count": 1,
		&"inside_viewport": [&"equipment"],
		&"equipment_tab": 1,
	},
	&"result": {
		&"visible": [&"game_result"],
		&"hidden": [&"hub_hud", &"run_setup", &"combat_hud", &"key_mapping", &"inventory", &"equipment", &"minimap", &"combat_skills", &"dash_cooldown", &"interaction"],
		&"paused": true,
		&"modal_count": 0,
		&"inside_viewport": [&"game_result"],
	},
}


func judge(game: Node, state_id: StringName) -> Dictionary:
	var errors := PackedStringArray()
	if not STATE_RULES.has(state_id):
		errors.append("알 수 없는 UI 상태입니다: %s" % state_id)
		return {&"success": false, &"errors": errors, &"snapshot": {}}
	var snapshot := capture(game)
	var rule: Dictionary = STATE_RULES[state_id]
	var visibility: Dictionary = snapshot[&"visibility"]
	for layer_id: StringName in rule.get(&"visible", []):
		if not bool(visibility.get(layer_id, false)):
			errors.append("필수 레이어가 보이지 않습니다: %s" % layer_id)
	for layer_id: StringName in rule.get(&"hidden", []):
		if bool(visibility.get(layer_id, false)):
			errors.append("숨겨야 할 레이어가 보입니다: %s" % layer_id)
	if bool(snapshot[&"paused"]) != bool(rule[&"paused"]):
		errors.append("일시정지 상태가 %s여야 하지만 %s입니다." % [rule[&"paused"], snapshot[&"paused"]])
	if int(snapshot[&"visible_modal_count"]) != int(rule[&"modal_count"]):
		errors.append("표시 중인 모달 수가 %d가 아니라 %d입니다." % [rule[&"modal_count"], snapshot[&"visible_modal_count"]])
	for layer_id: StringName in rule.get(&"inside_viewport", []):
		if not _is_inside_viewport(snapshot, layer_id):
			errors.append("레이어가 1280×720 화면 경계를 벗어납니다: %s" % layer_id)
	for pair: Array in rule.get(&"non_overlapping", []):
		if _layers_overlap(snapshot, pair[0], pair[1]):
			errors.append("동시에 보이는 HUD가 겹칩니다: %s ↔ %s" % [pair[0], pair[1]])
	if rule.has(&"equipment_tab") and int(snapshot[&"equipment_tab"]) != int(rule[&"equipment_tab"]):
		errors.append("장비 화면 탭이 %d가 아니라 %d입니다." % [rule[&"equipment_tab"], snapshot[&"equipment_tab"]])
	return {&"success": errors.is_empty(), &"errors": errors, &"snapshot": snapshot}


func capture(game: Node) -> Dictionary:
	var visibility := {}
	var rects := {}
	for layer_id: StringName in LAYER_IDS:
		var node: Node = _resolve_layer(game, layer_id)
		var is_visible: bool = node is CanvasItem and (node as CanvasItem).is_visible_in_tree()
		visibility[layer_id] = is_visible
		if is_visible and node is Control:
			rects[layer_id] = (node as Control).get_global_rect()
	var visible_modals := PackedStringArray()
	for panel in game.get_tree().get_nodes_in_group(&"game_modal_panel"):
		if panel is CanvasItem and panel.is_visible_in_tree():
			visible_modals.append(String(panel.name))
	var equipment: Node = _resolve_layer(game, &"equipment")
	var equipment_tab := -1
	if equipment != null and equipment.get("tabs") is TabContainer:
		equipment_tab = int((equipment.get("tabs") as TabContainer).current_tab)
	return {
		&"visibility": visibility,
		&"rects": rects,
		&"paused": game.get_tree().paused,
		&"viewport_size": game.get_viewport().get_visible_rect().size,
		&"visible_modals": visible_modals,
		&"visible_modal_count": visible_modals.size(),
		&"equipment_tab": equipment_tab,
	}


func _resolve_layer(game: Node, layer_id: StringName) -> Node:
	match layer_id:
		&"hub_hud":
			return game.get_node_or_null("UI/StartHubHUD")
		&"run_setup":
			return game.get_node_or_null("UI/RunSetupOverlay")
		&"combat_hud":
			return game.get_node_or_null("UI/HUDMargin")
		&"game_result":
			return game.get_node_or_null("UI/GameOverOverlay")
		&"key_mapping":
			return game.get("key_mapping_panel")
		&"inventory":
			return game.get("inventory_window")
		&"equipment":
			return game.get("equipment_workbench")
		&"minimap":
			return game.get("minimap")
		&"combat_skills":
			return game.get("combat_skill_hud")
		&"dash_cooldown":
			return game.get("dash_cooldown_hud")
		&"interaction":
			return game.get_node_or_null("UI/InteractionLabel")
	return null


func _is_inside_viewport(snapshot: Dictionary, layer_id: StringName) -> bool:
	var rects: Dictionary = snapshot[&"rects"]
	if not rects.has(layer_id):
		return false
	var rect: Rect2 = rects[layer_id]
	var viewport_size: Vector2 = snapshot[&"viewport_size"]
	return (
		rect.position.x >= -1.0
		and rect.position.y >= -1.0
		and rect.end.x <= viewport_size.x + 1.0
		and rect.end.y <= viewport_size.y + 1.0
	)


func _layers_overlap(snapshot: Dictionary, first_id: StringName, second_id: StringName) -> bool:
	var rects: Dictionary = snapshot[&"rects"]
	if not rects.has(first_id) or not rects.has(second_id):
		return false
	var first_rect: Rect2 = rects[first_id]
	var second_rect: Rect2 = rects[second_id]
	var intersection: Rect2 = first_rect.intersection(second_rect)
	return intersection.size.x > 1.0 and intersection.size.y > 1.0
