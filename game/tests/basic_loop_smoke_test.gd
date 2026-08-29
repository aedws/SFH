extends SceneTree

const GAME_SCENE_PATH := "res://game/scenes/game.tscn"
const MAP_GENERATOR_SCENE_PATH := "res://game/features/map_generation/map_generator.tscn"
const MAP_CONFIG_PATH_PATTERN := "res://game/features/map_generation/configs/%s.tres"
const LOOT_CONFIG_PATH_PATTERN := "res://game/features/loot/configs/%s.tres"
const EQUIPMENT_SCENE_PATH := "res://game/features/equipment/equipment_system.tscn"
const EQUIPMENT_LOADOUT_PATH := "res://game/features/equipment/loadouts/default_loadout.tres"
const INVENTORY_SCENE_PATH := "res://game/features/inventory/grid_inventory.tscn"
const INVENTORY_CATALOG_PATH := "res://game/features/inventory/catalogs/default_inventory.tres"
const WEAPON_BALANCE_SCENE_PATH := "res://game/features/weapon_balance/weapon_balance_service.tscn"
const WEAPON_BALANCE_CONFIG_PATH := "res://game/features/weapon_balance/configs/default_weapon_balance.tres"
const PLAYER_SCENE_PATH := "res://game/features/player/player.tscn"
const MAP_TIER_IDS := ["small", "medium", "large"]

var game_instance: Node
var frame_count: int = 0


func _init() -> void:
	if not _verify_map_tiers():
		return
	if not _verify_inventory_modules():
		return
	if not await _verify_weapon_balance_modules():
		return
	if not await _verify_equipment_modules():
		return
	if not await _verify_enemy_stats_modules():
		return

	var game_scene := load(GAME_SCENE_PATH) as PackedScene
	if game_scene == null:
		_fail("Game Scene을 불러오지 못했습니다.")
		return
	if not await _verify_all_tier_entry(game_scene):
		return
	if not await _verify_optional_map_module(game_scene):
		return
	if not await _verify_optional_equipment_module(game_scene):
		return
	if not await _verify_optional_weapon_balance_module(game_scene):
		return
	if not await _verify_extraction_flow(game_scene):
		return

	game_instance = game_scene.instantiate()
	root.add_child(game_instance)
	await process_frame
	var setup_overlay := game_instance.get_node("UI/RunSetupOverlay") as Control
	if not setup_overlay.visible or game_instance.get("player") != null:
		_fail("작전 규모 선택 화면이 게임 조립 전에 표시되지 않았습니다.")
		return
	game_instance.call(&"start_run", "small")
	frame_count = 0


func _verify_map_tiers() -> bool:
	var generator_scene := load(MAP_GENERATOR_SCENE_PATH) as PackedScene
	if generator_scene == null:
		_fail("Map Generator Scene을 불러오지 못했습니다.")
		return false

	for tier_id in MAP_TIER_IDS:
		var config = load(MAP_CONFIG_PATH_PATTERN % tier_id)
		var generator := generator_scene.instantiate()
		root.add_child(generator)
		generator.call(&"generate", config, 104729)

		var room_count: int = generator.get("rooms").size()
		var minimum_rooms: int = config.get("minimum_rooms")
		var maximum_rooms: int = config.get("maximum_rooms")
		if room_count < minimum_rooms or room_count > maximum_rooms:
			_fail("%s 맵의 방 수가 범위를 벗어났습니다." % tier_id)
			return false

		var path: PackedVector2Array = generator.call(
			&"get_world_path",
			generator.call(&"get_player_spawn_position"),
			generator.call(&"get_extraction_position")
		)
		if path.is_empty():
			_fail("%s 맵의 시작점과 탈출 지점이 연결되지 않았습니다." % tier_id)
			return false
		if generator.get("obstacle_cells").is_empty():
			_fail("%s 맵에 방해물이 생성되지 않았습니다." % tier_id)
			return false
		var obstacle_kinds: Array = generator.get("obstacle_cells").values()
		if &"wall" not in obstacle_kinds or &"pillar" not in obstacle_kinds:
			_fail("%s 맵에 실내 벽과 기둥 패턴이 모두 생성되지 않았습니다." % tier_id)
			return false
		var loot_config = load(LOOT_CONFIG_PATH_PATTERN % tier_id)
		var loot_positions: PackedVector2Array = generator.call(
			&"get_loot_spawn_positions",
			int(loot_config.get("minimum_cache_count"))
		)
		if loot_positions.size() < int(loot_config.get("minimum_cache_count")):
			_fail("%s 맵에 필요한 파밍 위치를 확보하지 못했습니다." % tier_id)
			return false
		if not is_equal_approx(float(generator.get("cell_size")), 32.0):
			_fail("맵 타일 크기가 32px로 조정되지 않았습니다.")
			return false

		root.remove_child(generator)
		generator.free()

	return true


func _verify_equipment_modules() -> bool:
	var loadout := load(EQUIPMENT_LOADOUT_PATH) as EquipmentLoadout
	var equipment_scene := load(EQUIPMENT_SCENE_PATH) as PackedScene
	var player_scene := load(PLAYER_SCENE_PATH) as PackedScene
	if loadout == null or equipment_scene == null or player_scene == null:
		_fail("장비 로드아웃, 장비 Scene 또는 플레이어 Scene을 불러오지 못했습니다.")
		return false
	if not loadout.validation_errors().is_empty():
		_fail("기본 장비 로드아웃이 유효하지 않습니다: %s" % loadout.validation_errors())
		return false
	if loadout.skills.size() != 3 or loadout.armor.size() != 2:
		_fail("기본 장비 로드아웃의 스킬 또는 방어구 수가 예상과 다릅니다.")
		return false

	var rifle_skill: EquipmentSkillDefinition = loadout.skills[0]
	var dagger_skill: EquipmentSkillDefinition = loadout.skills[2]
	if (
		not rifle_skill.matches_weapon(loadout.main_weapon)
		or rifle_skill.matches_weapon(loadout.secondary_weapon)
		or dagger_skill.matches_weapon(loadout.main_weapon)
		or dagger_skill.matches_weapon(loadout.secondary_weapon)
	):
		_fail("무기 대·중·소분류의 완전 일치 판정이 올바르지 않습니다.")
		return false

	var empty_skill_loadout := loadout.duplicate(true) as EquipmentLoadout
	empty_skill_loadout.skills = []
	if not empty_skill_loadout.validation_errors().is_empty():
		_fail("스킬 0개 로드아웃이 거부됐습니다.")
		return false
	var overflow_loadout := loadout.duplicate(true) as EquipmentLoadout
	overflow_loadout.skills = []
	for _index in range(11):
		overflow_loadout.skills.append(rifle_skill)
	if "최대 10개" not in " / ".join(overflow_loadout.validation_errors()):
		_fail("스킬 10개 초과 제한이 적용되지 않았습니다.")
		return false

	var player := player_scene.instantiate()
	var equipment := equipment_scene.instantiate()
	root.add_child(player)
	root.add_child(equipment)
	await process_frame
	var configured := bool(equipment.call(&"configure", loadout, player, true, true, true))
	var failure_message := ""
	var active_ids: PackedStringArray = equipment.call(&"get_active_skill_ids")
	var inactive_ids: PackedStringArray = equipment.call(&"get_inactive_skill_ids")
	var modifiers: Dictionary = equipment.call(&"get_stat_modifiers")
	if not configured:
		failure_message = "기본 장비 로드아웃 조립이 실패했습니다."
	elif active_ids.size() != 2 or &"rifle_burst" not in active_ids or &"pistol_quickdraw" not in active_ids:
		failure_message = "호환 스킬 두 개가 활성화되지 않았습니다: %s" % active_ids
	elif inactive_ids.size() != 1 or &"dagger_dash" not in inactive_ids:
		failure_message = "비호환 단검 스킬이 비활성 목록에 없습니다: %s" % inactive_ids
	elif not is_equal_approx(float(modifiers[&"max_health"][&"add"]), 25.0):
		failure_message = "방어구 최대 체력 수정자가 집계되지 않았습니다."
	elif not is_equal_approx(float(player.get("max_health")), 125.0):
		failure_message = "장비 최대 체력이 플레이어에 적용되지 않았습니다."
	elif not is_equal_approx(float(player.get("defense")), 3.0):
		failure_message = "장비 방어력이 플레이어에 적용되지 않았습니다."
	elif not is_equal_approx(float(player.get_node("Movement").get("speed")), 280.0):
		failure_message = "장비 이동 속도가 플레이어에 적용되지 않았습니다."
	elif equipment.call(&"get_active_weapon_slot") != &"main":
		failure_message = "초기 활성 무기가 메인 슬롯이 아닙니다."
	elif not equipment.call(&"switch_active_weapon"):
		failure_message = "보조 무기로 교체하지 못했습니다."
	elif equipment.call(&"get_active_weapon").weapon_id != &"service_pistol":
		failure_message = "Q 교체용 활성 무기 상태가 권총으로 바뀌지 않았습니다."
	elif not equipment.call(&"switch_active_weapon"):
		failure_message = "메인 무기로 복귀하지 못했습니다."
	else:
		player.call(&"take_damage", 10.0)
		if not is_equal_approx(float(player.get("current_health")), 118.0):
			failure_message = "방어력 3이 피해 10에서 차감되지 않았습니다."

	if failure_message.is_empty():
		var greatsword = load("res://game/features/equipment/definitions/weapons/greatsword.tres")
		var rifle_scope = load("res://game/features/equipment/definitions/parts/rifle_scope.tres")
		var pistol_part = load("res://game/features/equipment/definitions/parts/pistol_compensator.tres")
		var ballistic = load("res://game/features/equipment/definitions/modules/ballistic_core.tres")
		var vitality = load("res://game/features/equipment/definitions/modules/vitality_matrix.tres")
		var mobility = load("res://game/features/equipment/definitions/modules/mobility_chip.tres")
		var armor_plate = load("res://game/features/equipment/definitions/modules/armor_plate.tres")
		if equipment.call(&"can_equip_definition", &"main", greatsword):
			failure_message = "메인 슬롯이 소총 외 소분류 장비를 허용했습니다."
		elif not equipment.call(&"install_part", &"main", rifle_scope):
			failure_message = "소총 전용 optic 파츠를 장착하지 못했습니다."
		elif equipment.call(&"install_part", &"main", pistol_part):
			failure_message = "권총 전용 파츠가 소총에 장착됐습니다."
		elif not equipment.call(&"install_module", &"main", &"ballistic_1", ballistic):
			failure_message = "무기 모듈을 장착하지 못했습니다."
		elif equipment.call(&"install_module", &"main", &"vitality_1", vitality):
			failure_message = "무기 모듈 코스트 한도를 초과해 장착됐습니다."
		elif not equipment.call(&"install_module", &"main", &"mobility_1", mobility):
			failure_message = "남은 코스트 범위의 두 번째 모듈을 장착하지 못했습니다."
		elif not equipment.call(&"upgrade_module", &"main", &"ballistic_1"):
			failure_message = "모듈 강화가 거부됐습니다."
		else:
			var main_state := equipment.call(&"get_equipment_state", &"main") as EquipmentItemState
			if main_state.used_module_cost() != 6:
				failure_message = "모듈 강화 후 코스트가 감소하지 않았습니다."
			elif not equipment.call(&"level_up_equipment", &"main"):
				failure_message = "무기 레벨업 1단계가 실패했습니다."
			elif not equipment.call(&"level_up_equipment", &"main"):
				failure_message = "무기 최고 레벨 도달이 실패했습니다."
			elif not equipment.call(&"grant_module_tag", &"main", &"ballistic"):
				failure_message = "최고 레벨 무기의 개조 태그 부여가 실패했습니다."
			elif main_state.used_module_cost() != 5:
				failure_message = "일치 모듈 태그의 50% 코스트 규칙이 적용되지 않았습니다."
			elif equipment.call(&"install_part", &"body", rifle_scope):
				failure_message = "방어구가 무기 파츠를 허용했습니다."
			elif not equipment.call(&"install_module", &"body", &"plate_1", armor_plate):
				failure_message = "방어구 모듈을 장착하지 못했습니다."
			elif not equipment.call(&"upgrade_module", &"body", &"plate_1"):
				failure_message = "방어구 모듈 강화가 실패했습니다."
			else:
				for _index in range(3):
					equipment.call(&"level_up_equipment", &"body")
				var body_state := equipment.call(&"get_equipment_state", &"body") as EquipmentItemState
				if not equipment.call(&"grant_module_tag", &"body", &"defense"):
					failure_message = "최고 레벨 방어구 개조가 실패했습니다."
				elif body_state.used_module_cost() != 2:
					failure_message = "방어구 태그 일치 코스트가 절반으로 줄지 않았습니다."
				elif not is_equal_approx(float(player.get("defense")), 5.0):
					failure_message = "방어구 모듈 능력치가 플레이어에 반영되지 않았습니다."

	root.remove_child(equipment)
	equipment.free()
	root.remove_child(player)
	player.free()
	if not failure_message.is_empty():
		_fail("장비 모듈 실패: %s" % failure_message)
		return false
	return true


func _verify_weapon_balance_modules() -> bool:
	var balance_scene := load(WEAPON_BALANCE_SCENE_PATH) as PackedScene
	var balance_config := load(WEAPON_BALANCE_CONFIG_PATH) as WeaponBalanceConfig
	if balance_scene == null or balance_config == null:
		_fail("무기 밸런스 Scene 또는 Config를 불러오지 못했습니다.")
		return false
	var service := balance_scene.instantiate()
	root.add_child(service)
	await process_frame
	var failure_message := ""
	if not service.call(&"configure", balance_config):
		failure_message = "확정 무기 밸런스 CSV 로드에 실패했습니다."
	else:
		var rifle: Dictionary = service.call(&"get_weapon_balance", &"assault_rifle")
		var pistol: Dictionary = service.call(&"get_weapon_balance", &"service_pistol")
		if rifle.is_empty() or pistol.is_empty():
			failure_message = "소총 또는 권총 밸런스 행이 없습니다."
		elif int(rifle.get(&"burst_count", 0)) != 3:
			failure_message = "돌격소총 3점사 특색이 적용되지 않았습니다."
		elif float(rifle.get(&"target_range_px", 0.0)) <= float(pistol.get(&"target_range_px", 0.0)):
			failure_message = "돌격소총의 장거리 특색이 권총보다 낮습니다."
		elif float(pistol.get(&"damage", 0.0)) <= float(rifle.get(&"damage", 0.0)):
			failure_message = "권총의 고위력 단발 특색이 적용되지 않았습니다."
		elif int(pistol.get(&"pierce_count", 0)) != 1:
			failure_message = "권총의 1회 관통 특색이 적용되지 않았습니다."
		elif service.call(&"load_csv_text", "weapon_id,damage\nbroken,1", "오류 테스트"):
			failure_message = "필수 열이 없는 밸런스 CSV를 허용했습니다."
		if failure_message.is_empty():
			var sheet_csv := "\n".join(PackedStringArray([
				"weapon_id,display_name,runtime_enabled,trait_id,damage,fire_interval_sec,projectile_speed_px_sec,target_range_px,projectiles_per_shot,spread_angle_deg,burst_count,burst_interval_sec,critical_chance,critical_multiplier,pierce_count,pierce_damage_retention,projectile_lifetime_sec,projectile_color_hex,description",
				"고유 ID,표시 이름,런타임 반영,특색,피해,공격 주기,투사체 속도,탐지 거리,투사체 수,분산각,점사 수,점사 간격,치명타 확률,치명타 배율,관통 수,관통 유지율,수명,색상,설명",
				"assault_rifle,돌격소총,TRUE,steady_burst,1.6,0.78,760,820,1,0,3,0.10,0.05,1.75,0,1.0,1.6,#42D6C8,테스트 소총",
				"service_pistol,제식 권총,TRUE,heavy_piercing,3.2,0.60,690,560,1,0,1,0.00,0.12,2.0,1,0.65,1.3,#F2B84B,테스트 권총",
				"combat_dagger,전투 단검,FALSE,,,,,,,,,,,,,,,,",
			]))
			var parsed_sheet := WeaponBalanceTable.parse(sheet_csv)
			var sheet_errors: PackedStringArray = parsed_sheet[&"errors"]
			var sheet_data: Dictionary = parsed_sheet[&"data"]
			if not sheet_errors.is_empty() or sheet_data.size() != 2:
				failure_message = "2행 설명을 포함한 Google Sheet CSV를 2개 런타임 무기로 읽지 못했습니다."
	if not _has_key_binding(&"switch_weapon", KEY_Q):
		failure_message = "switch_weapon 입력에 Q 키가 할당되지 않았습니다."
	root.remove_child(service)
	service.free()
	if not failure_message.is_empty():
		_fail("무기 밸런스 모듈 실패: %s" % failure_message)
		return false
	return true


func _verify_inventory_modules() -> bool:
	var inventory_scene := load(INVENTORY_SCENE_PATH) as PackedScene
	var catalog := load(INVENTORY_CATALOG_PATH) as InventoryCatalog
	if inventory_scene == null or catalog == null or not catalog.validation_errors().is_empty():
		_fail("인벤토리 Scene 또는 기본 카탈로그가 유효하지 않습니다.")
		return false
	var inventory := inventory_scene.instantiate()
	root.add_child(inventory)
	if not inventory.call(&"configure", catalog):
		_fail("기본 가방 아이템 자동 배치가 실패했습니다.")
		return false
	var snapshot: Dictionary = inventory.call(&"get_snapshot")
	var sizes: Dictionary = {}
	var entries: Array = snapshot[&"items"]
	for index in range(entries.size()):
		var entry: Dictionary = entries[index]
		sizes[entry[&"grid_size"]] = true
		if entry[&"item_type"] == &"module" and entry[&"grid_size"] != Vector2i.ONE:
			_fail("모듈 아이템이 가방 한 칸보다 크게 정의됐습니다.")
			return false
		var rect := Rect2i(entry[&"position"], entry[&"grid_size"])
		if not Rect2i(Vector2i.ZERO, snapshot[&"grid_size"]).encloses(rect):
			_fail("가방 아이템이 격자 경계를 벗어났습니다.")
			return false
		for other_index in range(index + 1, entries.size()):
			var other: Dictionary = entries[other_index]
			if rect.intersects(Rect2i(other[&"position"], other[&"grid_size"])):
				_fail("가방 아이템 패널이 서로 겹쳤습니다.")
				return false
	if sizes.size() < 4:
		_fail("아이템별 가변 패널 크기가 충분히 구성되지 않았습니다.")
		return false
	var first: Dictionary = entries[0]
	if inventory.call(&"move_item", first[&"instance_id"], Vector2i(-1, 0)):
		_fail("가방 경계 밖 이동이 허용됐습니다.")
		return false
	if not _has_key_binding(&"toggle_inventory", KEY_I):
		_fail("I 키가 가방 열기 입력에 연결되지 않았습니다.")
		return false
	if not _has_key_binding(&"toggle_equipment", KEY_U):
		_fail("U 키가 장비 화면 입력에 연결되지 않았습니다.")
		return false
	root.remove_child(inventory)
	inventory.free()
	return true


func _verify_optional_equipment_module(game_scene: PackedScene) -> bool:
	var equipment_free_game := game_scene.instantiate()
	var equipment_free_features = equipment_free_game.get("features").duplicate(true)
	equipment_free_features.set("equipment_enabled", false)
	equipment_free_features.set("equipment_weapons_enabled", false)
	equipment_free_features.set("equipment_skills_enabled", false)
	equipment_free_features.set("equipment_armor_enabled", false)
	equipment_free_features.set("equipment_customization_enabled", false)
	equipment_free_features.set("run_setup_enabled", false)
	equipment_free_game.set("features", equipment_free_features)
	root.add_child(equipment_free_game)
	await process_frame
	var failure_message := ""
	if equipment_free_game.get("equipment_system") != null:
		failure_message = "비활성화했지만 장비 모듈이 설치됐습니다."
	elif equipment_free_game.get_node("UI/HUDMargin/Panel/Margin/Content/EquipmentLabel").visible:
		failure_message = "비활성화했지만 장비 HUD가 표시됩니다."
	elif not is_equal_approx(float(equipment_free_game.get("player").get("max_health")), 100.0):
		failure_message = "장비 비활성화 시 플레이어 기본 체력이 유지되지 않았습니다."

	root.remove_child(equipment_free_game)
	equipment_free_game.free()
	await process_frame
	if not failure_message.is_empty():
		_fail("장비 모듈 비활성화 실패: %s" % failure_message)
		return false
	return true


func _verify_optional_weapon_balance_module(game_scene: PackedScene) -> bool:
	var balance_free_game := game_scene.instantiate()
	var balance_free_features = balance_free_game.get("features").duplicate(true)
	balance_free_features.set("weapon_balance_enabled", false)
	balance_free_features.set("run_setup_enabled", false)
	balance_free_game.set("features", balance_free_features)
	root.add_child(balance_free_game)
	await process_frame
	var failure_message := ""
	var weapon = balance_free_game.get("auto_weapon")
	if balance_free_game.get("weapon_balance_service") != null:
		failure_message = "비활성화했지만 무기 밸런스 서비스가 설치됐습니다."
	elif weapon == null:
		failure_message = "밸런스 모듈과 함께 자동 무기까지 제거됐습니다."
	else:
		var snapshot: Dictionary = weapon.call(&"get_runtime_snapshot")
		if snapshot.get(&"source_label", "") != "내장 기본값":
			failure_message = "밸런스 비활성화 시 자동 무기 기본값으로 폴백하지 않았습니다."
	root.remove_child(balance_free_game)
	balance_free_game.free()
	await process_frame
	if not failure_message.is_empty():
		_fail("무기 밸런스 모듈 비활성화 실패: %s" % failure_message)
		return false
	return true


func _verify_all_tier_entry(game_scene: PackedScene) -> bool:
	var button_names := {
		"small": "SmallMapButton",
		"medium": "MediumMapButton",
		"large": "LargeMapButton",
	}
	for tier_id in MAP_TIER_IDS:
		var tier_game := game_scene.instantiate()
		root.add_child(tier_game)
		await process_frame
		var button := tier_game.get_node(
			"UI/RunSetupOverlay/Center/Panel/Margin/Content/TierButtons/%s" % button_names[tier_id]
		) as Button
		var failure_message := ""
		if button.disabled:
			failure_message = "%s 작전 버튼이 비활성화됐습니다: %s" % [tier_id, button.text]
		else:
			button.pressed.emit()
			await process_frame
			var generator = tier_game.get("map_generator")
			var minimap = tier_game.get("minimap")
			var config = load(MAP_CONFIG_PATH_PATTERN % tier_id)
			if not bool(tier_game.get("run_started")):
				failure_message = "%s 작전이 시작 상태로 전환되지 않았습니다." % tier_id
			elif String(tier_game.get("selected_map_size")) != tier_id:
				failure_message = "%s 작전 선택값이 조립부에 전달되지 않았습니다." % tier_id
			elif tier_game.get("player") == null or generator == null:
				failure_message = "%s 작전의 플레이어 또는 맵이 설치되지 않았습니다." % tier_id
			elif tier_game.get("extraction_zone") == null or minimap == null:
				failure_message = "%s 작전의 탈출 또는 미니맵이 설치되지 않았습니다." % tier_id
			elif (
				tier_game.get("inventory_system") == null
				or tier_game.get("inventory_window") == null
				or tier_game.get("equipment_workbench") == null
			):
				failure_message = "%s 작전의 가방 또는 장비 개조 UI가 설치되지 않았습니다." % tier_id
			elif generator.get("rooms").size() < int(config.get("minimum_rooms")):
				failure_message = "%s 작전의 최소 방 수를 생성하지 못했습니다." % tier_id
			else:
				var map_view = minimap.get_node("Margin/Content/MapView")
				if map_view.get("map_texture") == null:
					failure_message = "%s 작전의 미니맵 텍스처가 생성되지 않았습니다." % tier_id

		root.remove_child(tier_game)
		tier_game.free()
		await process_frame
		if not failure_message.is_empty():
			_fail("티어 진입 실패: %s" % failure_message)
			return false
	return true


func _verify_enemy_stats_modules() -> bool:
	var enemy_scene := load("res://game/features/enemies/enemy.tscn") as PackedScene
	if enemy_scene == null:
		_fail("Enemy Scene을 불러오지 못했습니다.")
		return false
	var enemy := enemy_scene.instantiate()
	root.add_child(enemy)
	await process_frame
	var health = enemy.get_node("HealthComponent")
	var armor = enemy.get_node("ArmorComponent")
	var status_bars := enemy.get_node("StatusBars") as Node2D
	var initial_health := float(health.get("current_value"))
	var initial_armor := float(armor.get("current_value"))
	enemy.call(&"take_damage", 1.0)
	var valid := (
		initial_health > 0.0
		and initial_armor > 0.0
		and is_equal_approx(float(health.get("current_value")), initial_health)
		and float(armor.get("current_value")) < initial_armor
		and status_bars.visible
	)
	root.remove_child(enemy)
	enemy.free()
	if not valid:
		_fail("적 체력·방어력 컴포넌트 또는 상태바가 정상 동작하지 않습니다.")
		return false
	return true


func _verify_optional_map_module(game_scene: PackedScene) -> bool:
	var fallback_game := game_scene.instantiate()
	var fallback_features = fallback_game.get("features").duplicate(true)
	fallback_features.set("map_generation_enabled", false)
	fallback_features.set("map_obstacles_enabled", false)
	fallback_features.set("minimap_enabled", false)
	fallback_features.set("extraction_enabled", false)
	fallback_features.set("run_setup_enabled", false)
	fallback_features.set("loot_enabled", false)
	fallback_game.set("features", fallback_features)
	root.add_child(fallback_game)
	await process_frame

	var fallback_player = fallback_game.get("player")
	var fallback_spawner = fallback_game.get("enemy_spawner")
	var map_label := fallback_game.get_node(
		"UI/HUDMargin/Panel/Margin/Content/TopRow/MapLabel"
	) as Label
	var failure_message := ""
	if fallback_game.get("map_generator") != null:
		failure_message = "비활성화했지만 맵 생성기가 설치됐습니다."
	elif fallback_player == null or fallback_player.global_position != Vector2.ZERO:
		failure_message = "비활성화 폴백의 플레이어 시작 위치가 원점이 아닙니다: %s" % (
			fallback_player.global_position if fallback_player != null else "player=null"
		)
	elif fallback_spawner == null or fallback_spawner.get("map_provider") != null:
		failure_message = "비활성화 폴백의 적 생성기에 맵 제공자가 남아 있습니다."
	elif map_label.visible:
		failure_message = "비활성화했지만 맵 HUD가 표시됩니다."
	elif fallback_game.get("minimap") != null:
		failure_message = "비활성화했지만 미니맵이 설치됐습니다."

	root.remove_child(fallback_game)
	fallback_game.free()

	if not failure_message.is_empty():
		_fail("맵 모듈 비활성화 실패: %s" % failure_message)
		return false

	return true


func _verify_extraction_flow(game_scene: PackedScene) -> bool:
	var extraction_game := game_scene.instantiate()
	root.add_child(extraction_game)
	await process_frame

	var setup_overlay := extraction_game.get_node("UI/RunSetupOverlay") as Control
	if not setup_overlay.visible:
		_fail("첫 실행 작전 규모 선택 화면이 표시되지 않았습니다.")
		return false

	extraction_game.call(&"start_run", "small")
	await process_frame
	var extraction_player = extraction_game.get("player")
	var extraction_zone = extraction_game.get("extraction_zone")
	var credit_ledger = extraction_game.get("credit_ledger")
	var loot_spawner = extraction_game.get("loot_spawner")
	var failure_message := ""
	if extraction_player == null or extraction_zone == null or credit_ledger == null or loot_spawner == null:
		failure_message = "플레이어, 탈출, 크레딧 또는 파밍 모듈이 설치되지 않았습니다."
	elif not _has_f_interaction_binding():
		failure_message = "interact 입력에 F 키가 할당되지 않았습니다."
	else:
		var loot_caches: Array[Node] = []
		for child in extraction_game.get_node("World/Pickups").get_children():
			if child.has_method(&"request_loot"):
				loot_caches.append(child)
		if loot_caches.is_empty():
			failure_message = "랜덤 1회성 파밍 오브젝트가 생성되지 않았습니다."
		else:
			var cache := loot_caches[0] as Node2D
			extraction_player.global_position = cache.global_position
			if not cache.call(&"request_loot", extraction_player):
				failure_message = "파밍 오브젝트에서 크레딧을 획득하지 못했습니다."
			elif cache.call(&"request_loot", extraction_player):
				failure_message = "1회성 파밍 오브젝트를 두 번 획득할 수 있습니다."
			elif int(credit_ledger.get("carried_credits")) <= 0:
				failure_message = "획득한 크레딧이 휴대 원장에 기록되지 않았습니다."

	if failure_message.is_empty():
		extraction_player.global_position = extraction_zone.global_position
		if not extraction_zone.call(&"request_extraction", extraction_player):
			failure_message = "탈출 지점에서 상호작용 요청이 거부됐습니다."
		elif not bool(extraction_game.get("run_ended")):
			failure_message = "탈출 성공 후 작전이 종료되지 않았습니다."
		elif int(credit_ledger.get("secured_credits")) <= 0:
			failure_message = "탈출 성공 후 크레딧이 회수 처리되지 않았습니다."
		elif String(extraction_game.get_node("UI/GameOverOverlay/Center/Panel/Margin/Content/EndTitle").text) != "탈출 성공":
			failure_message = "탈출 성공 결과 화면이 표시되지 않았습니다."

	paused = false
	root.remove_child(extraction_game)
	extraction_game.free()
	if not failure_message.is_empty():
		_fail("탈출 흐름 실패: %s" % failure_message)
		return false
	return true


func _has_f_interaction_binding() -> bool:
	return _has_key_binding(&"interact", KEY_F)


func _has_key_binding(action_name: StringName, keycode: Key) -> bool:
	if not InputMap.has_action(action_name):
		return false
	for event in InputMap.action_get_events(action_name):
		if event is InputEventKey:
			var key_event := event as InputEventKey
			if key_event.keycode == keycode or key_event.physical_keycode == keycode:
				return true
	return false


func _process(_delta: float) -> bool:
	frame_count += 1

	if frame_count == 120:
		var player := get_first_node_in_group(&"player")
		var enemies := get_nodes_in_group(&"enemies")
		if player == null:
			return _fail("player 그룹이 비어 있습니다.")
		if enemies.is_empty():
			return _fail("적이 생성되지 않았습니다.")

		var progression = game_instance.get("progression_system")
		var weapon = game_instance.get("auto_weapon")
		var map_generator = game_instance.get("map_generator")
		var extraction_zone = game_instance.get("extraction_zone")
		var equipment = game_instance.get("equipment_system")
		if progression == null or weapon == null or map_generator == null or extraction_zone == null or equipment == null:
			return _fail("맵, 탈출, 장비, 전투 또는 성장 모듈이 설치되지 않았습니다.")
		var small_config = load(MAP_CONFIG_PATH_PATTERN % "small")
		if map_generator.get("rooms").size() < int(small_config.get("minimum_rooms")):
			return _fail("소형 맵의 최소 방 수를 생성하지 못했습니다.")
		if map_generator.get("obstacle_cells").is_empty():
			return _fail("소형 맵에 방해물이 생성되지 않았습니다.")
		if not map_generator.call(&"is_walkable_world_position", player.global_position):
			return _fail("플레이어가 걸을 수 없는 위치에 생성됐습니다.")
		var health_label := game_instance.get_node(
			"UI/HUDMargin/Panel/Margin/Content/HealthRow/HealthLabel"
		) as Label
		var health_bar := game_instance.get_node(
			"UI/HUDMargin/Panel/Margin/Content/HealthRow/HealthBar"
		) as ProgressBar
		if "%" not in health_label.text or health_bar.custom_minimum_size.y < 26.0:
			return _fail("플레이어 체력 HUD의 수치 또는 가독성 스타일이 적용되지 않았습니다.")
		var equipment_label := game_instance.get_node(
			"UI/HUDMargin/Panel/Margin/Content/EquipmentLabel"
		) as Label
		if "스킬 2/3 활성" not in equipment_label.text or "방어 3" not in equipment_label.text:
			return _fail("장비 HUD에 무기·스킬·방어구 상태가 표시되지 않았습니다.")
		var balance = game_instance.get("weapon_balance_service")
		if balance == null or balance.call(&"get_snapshot").size() != 2:
			return _fail("무기 밸런스 모듈이 Game 조립 지점에 설치되지 않았습니다.")
		if not equipment.call(&"switch_active_weapon"):
			return _fail("런타임 Q 무기 교체 상태 전환이 실패했습니다.")

		enemies[0].call(&"take_damage", 9999.0)
		progression.call(&"gain_experience", 5)

	if frame_count == 121:
		var weapon = game_instance.get("auto_weapon")
		var snapshot: Dictionary = weapon.call(&"get_runtime_snapshot")
		var runtime_label := game_instance.get_node(
			"UI/HUDMargin/Panel/Margin/Content/WeaponRuntimeLabel"
		) as Label
		if snapshot.get(&"active_weapon_id", &"") != &"service_pistol":
			return _fail("무기 교체가 자동 공격 런타임에 반영되지 않았습니다.")
		if "고위력 관통" not in runtime_label.text or "확정 CSV" not in runtime_label.text:
			return _fail("무기 특색 또는 밸런스 출처가 HUD에 표시되지 않았습니다.")

	if frame_count == 125:
		if int(game_instance.get("defeated_enemies")) < 1:
			return _fail("적 처치 이벤트가 Game에 전달되지 않았습니다.")
		if game_instance.get_node("World/Pickups").get_child_count() < 1:
			return _fail("경험치 픽업이 생성되지 않았습니다.")

		var progression = game_instance.get("progression_system")
		if int(progression.get("level")) < 2:
			return _fail("레벨 증가가 적용되지 않았습니다.")

		var player := get_first_node_in_group(&"player")
		player.call(&"take_damage", 9999.0)

	if frame_count == 130:
		var overlay := game_instance.get_node("UI/GameOverOverlay") as Control
		if not paused or not overlay.visible:
			return _fail("게임오버 상태가 적용되지 않았습니다.")

		paused = false
		print("SMOKE_TEST_OK run_setup tier_entry map minimap equipment loadout weapon_tags skills_0_10 armor_stats inventory_grid item_footprints inventory_i equipment_u weapon_switch_q weapon_balance_csv weapon_balance_optional rifle_burst pistol_pierce parts module_cost module_upgrade modification_tag equipment_optional realistic_obstacles loot credits map_optional player health_ui enemies armor status_bars pathfinding weapon experience leveling extraction_f game_over")
		quit(0)
		return true

	return false


func _fail(message: String) -> bool:
	paused = false
	printerr("SMOKE_TEST_FAILED: %s" % message)
	quit(1)
	return true
