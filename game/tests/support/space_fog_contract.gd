extends RefCounted

static func verify(fog: Node, generator: Node, player: Node2D) -> Dictionary:
	var errors: Array[String] = []
	var original := player.global_position
	var rooms: Array = generator.get_room_encounter_snapshot()
	var distant_before: StringName = fog.get_visibility_state(rooms[2].center)
	for room: Dictionary in rooms.slice(0,2):
		player.global_position = room.center
		fog.call(&"_process", 0.2)
		var rect: Rect2 = room.world_rect
		for position in [rect.position+Vector2(80,80),rect.end-Vector2(80,80)]:
			if generator.room_contains_cell(room.room_index,Vector2i((position/generator.cell_size).floor())) and fog.get_visibility_state(position)!=&"visible": errors.append("현재 방의 실제 바닥 미공개")
		for door: Dictionary in room.doorways:
			for offset in [-6.0,8.0,-4.0,6.0,40.0]:
				player.global_position=Vector2(door.position)+Vector2(door.outward)*offset
				fog.call(&"_process",0.016)
				if fog.get_visibility_state(player.global_position)!=&"visible": errors.append("문턱에서 플레이어 가림")
			break
	player.global_position=rooms[1].center
	fog.call(&"_process",0.2)
	if fog.get_visibility_state(rooms[0].center)!=&"explored": errors.append("떠난 방 지형 기억 누락")
	if fog.get_visibility_state(rooms[2].center)!=distant_before: errors.append("비활성 방 정보 누출")
	var snapshot: Dictionary=fog.get_snapshot()
	if not snapshot.memory_terrain_only or not snapshot.room_auto_reveal: errors.append("공간 공개 정책 미적용")
	player.global_position=original
	fog.call(&"_process",0.2)
	return {&"policy":&"space_disclosure",&"passed":errors.is_empty(),&"errors":errors,&"snapshot":snapshot}
