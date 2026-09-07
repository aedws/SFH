class_name ExtractionZone
extends Area2D

signal extraction_completed(actor: Node2D)
signal extraction_defense_started(actor: Node2D, duration_seconds: float)
signal extraction_defense_cancelled()
signal extraction_defense_paused(remaining_seconds: float)
signal extraction_defense_resumed(remaining_seconds: float)
signal interaction_availability_changed(available: bool, prompt: String)

@export var interaction_action: StringName = &"interact"
@export_range(32.0, 160.0, 4.0) var interaction_radius: float = 72.0
@export var fill_color := Color(1.0, 0.48, 0.12, 0.22)
@export var ring_color := Color(1.0, 0.67, 0.25, 0.95)
@export_range(0.0, 120.0, 1.0) var defense_duration_seconds: float = 20.0

var nearby_player: Node2D
var locked: bool = false
var locked_prompt: String = "탈출 신호 대기 중"
var defense_actor: Node2D
var defense_remaining_seconds: float = 0.0
var defense_paused: bool = false
var _last_prompt := ""
var _last_available := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_sync_shape.call_deferred()
	queue_redraw()


func configure(world_position: Vector2, new_defense_duration_seconds: float = 20.0) -> void:
	global_position = world_position
	defense_duration_seconds = maxf(0.0, new_defense_duration_seconds)
	_sync_shape.call_deferred()
	queue_redraw()


func _sync_shape() -> void:
	var collider := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collider == null:
		return
	var circle := CircleShape2D.new()
	circle.radius = interaction_radius
	collider.shape = circle


func _inside_zone(actor: Node2D) -> bool:
	return is_instance_valid(actor) and actor.global_position.distance_to(global_position) <= interaction_radius


func _refresh_prompt() -> void:
	var available := is_instance_valid(nearby_player)
	var prompt := _interaction_prompt() if available else ""
	if available != _last_available or prompt != _last_prompt:
		_last_available = available
		_last_prompt = prompt
		interaction_availability_changed.emit(available, prompt)


func set_locked(is_locked: bool, prompt: String = "탈출 신호 대기 중") -> void:
	locked = is_locked
	locked_prompt = prompt
	queue_redraw()
	_refresh_prompt()


func request_extraction(actor: Node2D) -> bool:
	if not is_instance_valid(actor) or not actor.is_in_group(&"player"):
		return false
	if not _inside_zone(actor):
		_refresh_prompt()
		return false
	if locked:
		interaction_availability_changed.emit(true, _interaction_prompt())
		return false

	if defense_duration_seconds <= 0.0:
		extraction_completed.emit(actor)
		return true
	if is_instance_valid(defense_actor):
		if actor == defense_actor and defense_paused:
			defense_paused = false
			extraction_defense_resumed.emit(defense_remaining_seconds)
			interaction_availability_changed.emit(true, _interaction_prompt())
			return true
		return false
	defense_actor = actor
	defense_remaining_seconds = defense_duration_seconds
	defense_paused = false
	extraction_defense_started.emit(actor, defense_duration_seconds)
	interaction_availability_changed.emit(true, _interaction_prompt())
	return true


func advance(delta: float) -> void:
	_advance_defense(delta)
	_refresh_prompt()


func get_snapshot() -> Dictionary:
	return {
		&"locked": locked,
		&"defense_active": is_instance_valid(defense_actor),
		&"defense_duration_seconds": defense_duration_seconds,
		&"defense_remaining_seconds": defense_remaining_seconds,
		&"defense_paused": defense_paused,
		&"nearby_player_valid": is_instance_valid(nearby_player),
		&"center_in_range": _inside_zone(nearby_player),
		&"interaction_radius": interaction_radius,
	}


func _process(delta: float) -> void:
	advance(delta)


func _advance_defense(delta: float) -> void:
	if not is_instance_valid(defense_actor):
		return
	if not _inside_zone(defense_actor):
		_pause_defense()
		return
	if defense_paused:
		defense_paused = false
		extraction_defense_resumed.emit(defense_remaining_seconds)
		interaction_availability_changed.emit(true, _interaction_prompt())
	defense_remaining_seconds = maxf(0.0, defense_remaining_seconds - maxf(0.0, delta))
	interaction_availability_changed.emit(true, _interaction_prompt())
	queue_redraw()
	if defense_remaining_seconds <= 0.0:
		var completed_actor := defense_actor
		defense_actor = null
		defense_paused = false
		extraction_completed.emit(completed_actor)


func _unhandled_input(event: InputEvent) -> void:
	if not is_instance_valid(nearby_player):
		return
	if event.is_action_pressed(interaction_action) and request_extraction(nearby_player):
		get_viewport().set_input_as_handled()


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group(&"player"):
		return
	nearby_player = body
	# Broad-phase overlap includes the player's collider radius, not just its center.
	# Resume only in _advance_defense after the same center-distance gate as input.
	_refresh_prompt()


func _on_body_exited(body: Node2D) -> void:
	if body != nearby_player:
		return
	nearby_player = null
	if body == defense_actor:
		_pause_defense()
	_refresh_prompt()


func _draw() -> void:
	var active_ring := Color(0.52, 0.58, 0.64, 0.9) if locked else ring_color
	draw_circle(Vector2.ZERO, interaction_radius, Color(active_ring, 0.12))
	draw_arc(Vector2.ZERO, interaction_radius, 0.0, TAU, 48, active_ring, 3.0)
	draw_arc(Vector2.ZERO, 31.0, 0.0, TAU, 48, Color(active_ring, 0.6), 2.0)
	var arrow := PackedVector2Array([
		Vector2(-9.0, 8.0),
		Vector2(0.0, -10.0),
		Vector2(9.0, 8.0),
	])
	draw_polyline(arrow, active_ring, 4.0)


func _interaction_prompt() -> String:
	if locked:
		return locked_prompt
	if is_instance_valid(defense_actor):
		if defense_paused:
			return "탈출 방어 일시정지 · 구역 복귀 시 %.1f초부터 재개" % defense_remaining_seconds
		return "탈출 방어 중 · %.1f초 · 구역 유지" % defense_remaining_seconds
	if not _inside_zone(nearby_player):
		return "탈출 구역 안으로 더 이동하세요"
	return "F · 탈출 방어전 시작"


func _cancel_defense() -> void:
	if not is_instance_valid(defense_actor):
		return
	defense_actor = null
	defense_remaining_seconds = 0.0
	defense_paused = false
	extraction_defense_cancelled.emit()
	_refresh_prompt()
	queue_redraw()


func _pause_defense() -> void:
	if not is_instance_valid(defense_actor) or defense_paused:
		return
	defense_paused = true
	extraction_defense_paused.emit(defense_remaining_seconds)
	queue_redraw()
