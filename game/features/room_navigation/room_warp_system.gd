class_name RoomWarpSystem
extends Node

## 확장 전술 지도에서 사용할 워프 후보와 이동 검증을 소유합니다.
## 미니맵은 후보를 표시하고 요청만 보내며 플레이어 위치를 직접 변경하지 않습니다.

signal warp_targets_changed(targets: Array[Dictionary])
signal warped(room_index: int, world_position: Vector2)
signal warp_rejected(room_index: int, reason: String)

const MAP_METHODS := [&"get_room_encounter_snapshot", &"is_walkable_world_position"]
const PROGRESS_METHODS := [&"get_snapshot", &"is_room_completed"]

var player: Node2D
var map_provider: Node
var progress_provider: Node
var room_definitions: Dictionary = {}


func configure(new_player: Node2D, new_map_provider: Node, new_progress_provider: Node) -> bool:
	if (
		not is_instance_valid(new_player)
		or not _supports_methods(new_map_provider, MAP_METHODS)
		or not _supports_methods(new_progress_provider, PROGRESS_METHODS)
	):
		return false
	player = new_player
	map_provider = new_map_provider
	progress_provider = new_progress_provider
	room_definitions.clear()
	for room: Dictionary in map_provider.call(&"get_room_encounter_snapshot"):
		room_definitions[int(room.get(&"room_index", -1))] = room
	refresh_targets()
	return not room_definitions.is_empty()


func refresh_targets() -> Array[Dictionary]:
	var targets := get_warp_targets()
	warp_targets_changed.emit(targets)
	return targets


func get_warp_targets() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for room_index: int in room_definitions:
		var room: Dictionary = room_definitions[room_index]
		var kind := _target_kind(room)
		if kind.is_empty():
			continue
		var cleared := bool(progress_provider.call(&"is_room_completed", room_index))
		var is_landmark := kind in [&"start", &"extraction"]
		if not is_landmark and not cleared:
			continue
		result.append({
			&"room_index": room_index,
			&"world_position": room.get(&"center", Vector2.ZERO),
			&"kind": kind,
			&"cleared": cleared or is_landmark,
			&"available": true,
		})
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a[&"room_index"]) < int(b[&"room_index"])
	)
	return result


func request_warp(room_index: int) -> bool:
	var reason := _warp_rejection_reason(room_index)
	if not reason.is_empty():
		warp_rejected.emit(room_index, reason)
		return false
	var target: Vector2 = room_definitions[room_index].get(&"center", player.global_position)
	player.global_position = target
	if player is CharacterBody2D:
		(player as CharacterBody2D).velocity = Vector2.ZERO
	warped.emit(room_index, target)
	return true


func get_snapshot() -> Dictionary:
	var encounter: Dictionary = progress_provider.call(&"get_snapshot")
	return {
		&"target_count": get_warp_targets().size(),
		&"active_encounter": int(encounter.get(&"active_room_index", -1)) >= 0,
		&"targets": get_warp_targets(),
	}


func _warp_rejection_reason(room_index: int) -> String:
	if not room_definitions.has(room_index):
		return "지도에 없는 지역입니다."
	var target_position: Vector2 = room_definitions[room_index].get(&"center", Vector2.ZERO)
	if not bool(map_provider.call(&"is_walkable_world_position", target_position)):
		return "안전한 워프 좌표를 찾지 못했습니다."
	var encounter: Dictionary = progress_provider.call(&"get_snapshot")
	if int(encounter.get(&"active_room_index", -1)) >= 0:
		return "방 봉쇄 전투 중에는 워프할 수 없습니다."
	for target in get_warp_targets():
		if int(target.get(&"room_index", -1)) == room_index:
			return ""
	return "클리어한 4방향 교차 방만 워프할 수 있습니다."


func _target_kind(room: Dictionary) -> StringName:
	if bool(room.get(&"is_start_room", false)):
		return &"start"
	if bool(room.get(&"is_extraction_room", false)):
		return &"extraction"
	if bool(room.get(&"is_four_way", false)):
		return &"junction"
	return &""


func _supports_methods(candidate: Node, methods: Array) -> bool:
	if not is_instance_valid(candidate):
		return false
	for method_name in methods:
		if not candidate.has_method(method_name):
			return false
	return true
