extends SceneTree

const EdgeProjection := preload("res://game/features/boss_warning/boss_edge_projection.gd")
const HudScene := preload("res://game/features/boss_warning/boss_warning_hud.tscn")

class Actor extends Node2D:
	signal defeated(reward: int, world_position: Vector2)
	var boss := true
	var pursuer := true
	func get_combat_identity() -> Dictionary:
		return {&"is_boss": boss, &"is_elite_pursuer": pursuer}

class Spawner extends Node:
	signal enemy_spawned(enemy: Node)
	var targets: Array[Node] = []
	func get_active_targets() -> Array[Node]:
		return targets.duplicate()


func _init() -> void:
	call_deferred(&"_run")


func _run() -> void:
	for dimensions in [Vector2(1280, 720), Vector2(1920, 1080), Vector2(640, 360), Vector2(390, 844)]:
		for direction in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN,
			Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
			var result := EdgeProjection.project(dimensions * 0.5 + direction * 5000.0, dimensions, 24.0)
			var point: Vector2 = result.get(&"position", Vector2.INF)
			if not Rect2(Vector2.ONE * 23.0, dimensions - Vector2.ONE * 46.0).has_point(point) \
				or absf(angle_difference(float(result.get(&"angle", 99)), direction.angle())) > 0.001:
				return _fail("외곽 8방향·뷰포트 경계 오류: %s / %s" % [dimensions, result])
		if not EdgeProjection.project(dimensions * 0.5, dimensions, 24).is_empty():
			return _fail("화면 안 보스에 외곽 화살표가 표시됨")
	if not EdgeProjection.project(Vector2.INF, Vector2(1280, 720), 24).is_empty():
		return _fail("비정상 좌표를 표시함")
	root.size = Vector2i(1280, 720)
	var fixture := Node2D.new()
	root.add_child(fixture)
	var player := Node2D.new()
	fixture.add_child(player)
	var source := Spawner.new()
	fixture.add_child(source)
	var boss := Actor.new()
	fixture.add_child(boss)
	boss.position = Vector2(2000, 360)
	source.targets.append(boss)
	var context := Control.new()
	fixture.add_child(context)
	var layer := CanvasLayer.new()
	fixture.add_child(layer)
	var hud = HudScene.instantiate()
	layer.add_child(hud)
	if not hud.configure(source, player, context):
		return _fail("보스 HUD 구성 실패")
	hud._process(0.0)
	var snapshot: Dictionary = hud.get_snapshot()
	if not snapshot.warning_visible or snapshot.indicators.size() != 1 \
		or not snapshot.input_passthrough or "추격" not in snapshot.warning_text:
		return _fail("설치 전 생성된 보스의 등장 경고·외곽 방향 누락: %s" % snapshot)
	source.enemy_spawned.emit(boss)
	hud._process(0.0)
	if hud.warning_count != 1:
		return _fail("중복 생성 신호로 경고가 재발동함")
	var ordinary := Actor.new()
	ordinary.boss = false
	fixture.add_child(ordinary)
	source.enemy_spawned.emit(ordinary)
	if hud.warning_count != 1:
		return _fail("일반 적을 보스로 경고함")
	# Camera translation + zoom changes viewport projection, not just world direction.
	var original_transform := root.canvas_transform
	root.canvas_transform = Transform2D(0, Vector2(0.5, 0.5), 0, Vector2(-500, 0))
	hud._process(0.0)
	if not hud.indicators.is_empty():
		return _fail("카메라 이동·줌 뒤 화면 안 보스 화살표가 남음")
	root.canvas_transform = original_transform
	hud._process(0.0)
	var lifetime: float = hud.warning_remaining
	paused = true
	hud._process(2.0)
	if hud.visible or hud.warning_remaining != lifetime:
		return _fail("일시정지 중 경고가 표시되거나 수명이 소모됨")
	paused = false
	context.hide()
	hud._process(1.0)
	if hud.visible:
		return _fail("모달/결과 창에서 경고가 남음")
	context.show()
	hud._process(0.0)
	if not hud.visible:
		return _fail("전투 재개 후 경고 미복원")
	hud._process(4.0)
	if hud.get_snapshot().warning_visible or hud.indicators.size() != 1:
		return _fail("등장 경고 만료가 추적 화살표까지 제거함")
	var other_boss := Actor.new()
	other_boss.pursuer = false
	other_boss.position = Vector2(-2000, 360)
	fixture.add_child(other_boss)
	source.enemy_spawned.emit(other_boss)
	hud._process(0.0)
	if hud.indicators.size() != 2 or "교전" not in hud.warning_text:
		return _fail("일반 보스·복수 방향 경고 누락")
	boss.defeated.emit(1, boss.global_position)
	hud._process(0.0)
	if hud.indicators.size() != 1:
		return _fail("처치 즉시 해당 화살표 제거 실패")
	other_boss.queue_free()
	hud._process(0.0)
	if hud.visible or not hud.indicators.is_empty():
		return _fail("마지막 보스 제거 후 잔상 유지")
	hud.free()
	if source.enemy_spawned.get_connections().size() != 0:
		return _fail("HUD 제거 뒤 생성 신호 연결 누수")
	fixture.free()
	print("BOSS_WARNING_OK initial_spawn once_only normal_boss pursuer multi_boss directions_8 viewports_4 camera_zoom onscreen_hide pause_freeze context_hide kill_cleanup optional_disconnect input_passthrough")
	quit(0)


func _fail(message: String) -> void:
	paused = false
	push_error(message)
	quit(1)
