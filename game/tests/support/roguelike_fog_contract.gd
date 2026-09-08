extends RefCounted
## Integration observations, separate from the pure geometry and rendered pixel tests.

static func verify(fog: Node, generator: Node, player: Node2D) -> Dictionary:
	if fog.get_snapshot().get(&"policy") == &"space_disclosure":
		return preload("res://game/tests/support/space_fog_contract.gd").verify(fog,generator,player)
	var errors: Array[String] = []
	var original := player.global_position
	fog.call(&"_process", 0.2)
	var initial: Dictionary = fog.get_snapshot()
	if initial.get(&"policy") != &"roguelike_three_state" or not initial.get(&"omnidirectional", false): errors.append("주변 360도 시야 정책 누락")
	if fog.get_visibility_state(original) != &"visible": errors.append("플레이어 위치가 가려짐")
	if initial.get(&"room_auto_reveal", true) or not initial.get(&"memory_terrain_only", false): errors.append("방 자동 공개 또는 동적 오브젝트 기억 누출")
	var memory_before := int(initial.get(&"explored_cell_count", 0))
	var facing: Vector2 = player.get_facing_direction()
	player.set("facing_direction", -facing)
	fog.call(&"_process", 0.2)
	if fog.get_snapshot().fov_updates != initial.fov_updates: errors.append("회전만으로 시야를 재계산함")
	player.set("facing_direction", facing)
	var traversed := false
	for room: Dictionary in generator.get_room_encounter_snapshot():
		for doorway: Dictionary in room.get(&"doorways", []):
			for offset in [-6.0, 8.0, -4.0, 6.0]:
				player.global_position = Vector2(doorway.position) + Vector2(doorway.outward) * offset
				fog.call(&"_process", 0.016)
				if fog.get_visibility_state(player.global_position) != &"visible": errors.append("문턱 왕복 중 플레이어 가림")
			traversed = true
			break
		if traversed: break
	if not traversed: errors.append("실제 문턱 샘플 없음")
	var distant_found := false
	for room: Dictionary in generator.get_room_encounter_snapshot():
		if Vector2(room.center).distance_to(original) <= float(initial.sight_radius) * 2: continue
		player.global_position = room.center
		fog.call(&"_process", 0.016)
		if fog.get_visibility_state(original) != &"explored": errors.append("워프 후 이전 지형 기억 미유지")
		if fog.get_visibility_state(player.global_position) != &"visible": errors.append("워프 도착 시야 미갱신")
		distant_found = true
		break
	if not distant_found: errors.append("원거리 기억 샘플 없음")
	if int(fog.get_snapshot().explored_cell_count) < memory_before: errors.append("방·통로 이동 중 기억 삭제")
	if not fog.get_snapshot().minimap_visibility_independent: errors.append("전체 미니맵 간섭")
	player.global_position = original
	fog.call(&"_process", 0.016)
	return {&"policy": &"roguelike_three_state", &"errors": errors, &"passed": errors.is_empty(), &"snapshot": fog.get_snapshot()}
