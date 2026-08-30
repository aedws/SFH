class_name PlayerMovement
extends Node

## 입력을 플랫포머처럼 즉각적인 가속·제동·선회·대시가 있는 탑다운 속도로 바꾸는 독립 컴포넌트입니다.
## 방향키는 Godot 기본 ui_* 입력을 사용하고 WASD는 물리 키로 읽습니다.

@export_range(0.0, 2000.0, 10.0, "or_greater") var speed: float = 280.0
@export_range(100.0, 20000.0, 50.0) var acceleration: float = 6500.0
@export_range(100.0, 24000.0, 50.0) var cornering_acceleration: float = 12000.0
@export_range(100.0, 24000.0, 50.0) var braking: float = 16000.0
@export_range(100.0, 24000.0, 50.0) var counter_steer_acceleration: float = 18000.0
@export_range(0.0, 1.0, 0.05) var launch_speed_ratio: float = 0.68
@export_range(0.0, 300.0, 5.0) var stop_snap_speed: float = 50.0
@export_range(100.0, 24000.0, 50.0) var lateral_grip: float = 18000.0
@export_range(0.0, 1.0, 0.05) var reversal_speed_retention: float = 0.18
@export_range(1.0, 4.0, 0.05) var dash_speed_multiplier: float = 2.35
@export_range(0.05, 0.5, 0.01) var dash_duration: float = 0.14
@export_range(0.1, 5.0, 0.05) var dash_cooldown: float = 0.85
@export_range(0.0, 0.5, 0.01) var dash_input_buffer: float = 0.14
@export_range(1.0, 2.0, 0.05) var dash_exit_speed_multiplier: float = 1.08
@export_range(0.0, 0.5, 0.01) var dash_exit_momentum_duration: float = 0.08

var dash_time_remaining: float = 0.0
var dash_cooldown_remaining: float = 0.0
var buffered_dash_remaining: float = 0.0
var dash_exit_time_remaining: float = 0.0
var last_move_direction := Vector2.RIGHT
var dash_direction := Vector2.RIGHT
var dash_was_down: bool = false


func get_velocity(current_velocity: Vector2, delta: float) -> Vector2:
	var direction := Input.get_vector(&"ui_left", &"ui_right", &"ui_up", &"ui_down")
	var wasd_direction := Vector2(
		float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A)),
		float(Input.is_physical_key_pressed(KEY_S)) - float(Input.is_physical_key_pressed(KEY_W))
	)

	if wasd_direction != Vector2.ZERO:
		direction = wasd_direction.normalized()
	var dash_down := (
		Input.is_physical_key_pressed(KEY_SHIFT)
		or Input.is_physical_key_pressed(KEY_SPACE)
	)
	var dash_pressed := dash_down and not dash_was_down
	dash_was_down = dash_down
	return step_velocity(current_velocity, direction, delta, dash_pressed)


func step_velocity(
	current_velocity: Vector2,
	input_direction: Vector2,
	delta: float,
	dash_pressed: bool = false
) -> Vector2:
	var safe_delta := maxf(0.0, delta)
	var was_dashing := dash_time_remaining > 0.0
	dash_cooldown_remaining = maxf(0.0, dash_cooldown_remaining - safe_delta)
	dash_time_remaining = maxf(0.0, dash_time_remaining - safe_delta)
	buffered_dash_remaining = maxf(0.0, buffered_dash_remaining - safe_delta)
	if was_dashing and dash_time_remaining <= 0.0:
		dash_exit_time_remaining = dash_exit_momentum_duration
	else:
		dash_exit_time_remaining = maxf(0.0, dash_exit_time_remaining - safe_delta)
	var direction := input_direction.limit_length(1.0)
	if direction != Vector2.ZERO:
		last_move_direction = direction.normalized()
	if dash_pressed:
		buffered_dash_remaining = dash_input_buffer
	if (
		buffered_dash_remaining > 0.0
		and dash_cooldown_remaining <= 0.0
		and direction != Vector2.ZERO
	):
		dash_time_remaining = dash_duration
		dash_cooldown_remaining = dash_cooldown
		buffered_dash_remaining = 0.0
		dash_exit_time_remaining = 0.0
		dash_direction = direction.normalized()

	if dash_time_remaining > 0.0:
		return dash_direction * speed * dash_speed_multiplier

	if direction == Vector2.ZERO:
		var stopped_velocity := current_velocity.move_toward(Vector2.ZERO, braking * safe_delta)
		if stopped_velocity.length() <= stop_snap_speed:
			return Vector2.ZERO
		return stopped_velocity

	var input_strength := direction.length()
	var move_direction := direction.normalized()
	var target_speed := speed * input_strength
	if dash_exit_time_remaining > 0.0 and dash_exit_momentum_duration > 0.0:
		var momentum_ratio := dash_exit_time_remaining / dash_exit_momentum_duration
		target_speed *= lerpf(1.0, dash_exit_speed_multiplier, momentum_ratio)
	var responsive_velocity := current_velocity
	var alignment := 1.0
	if responsive_velocity.length_squared() > 0.01:
		alignment = responsive_velocity.normalized().dot(move_direction)
		if alignment < 0.0:
			responsive_velocity *= reversal_speed_retention
		elif alignment < 0.82:
			var forward_velocity := move_direction * maxf(
				0.0,
				responsive_velocity.dot(move_direction)
			)
			var lateral_velocity := responsive_velocity - forward_velocity
			responsive_velocity = forward_velocity + lateral_velocity.move_toward(
				Vector2.ZERO,
				lateral_grip * safe_delta
			)
	var launch_speed := minf(target_speed, speed * launch_speed_ratio * input_strength)
	var forward_speed := responsive_velocity.dot(move_direction)
	if forward_speed < launch_speed:
		responsive_velocity += move_direction * (launch_speed - forward_speed)
	var response := acceleration
	if alignment < 0.0:
		response = counter_steer_acceleration
	elif alignment < 0.82:
		response = cornering_acceleration
	return responsive_velocity.move_toward(
		move_direction * target_speed,
		response * safe_delta
	)


func get_movement_snapshot() -> Dictionary:
	return {
		&"speed": speed,
		&"acceleration": acceleration,
		&"cornering_acceleration": cornering_acceleration,
		&"braking": braking,
		&"counter_steer_acceleration": counter_steer_acceleration,
		&"launch_speed": speed * launch_speed_ratio,
		&"stop_snap_speed": stop_snap_speed,
		&"lateral_grip": lateral_grip,
		&"reversal_speed_retention": reversal_speed_retention,
		&"dash_speed": speed * dash_speed_multiplier,
		&"dash_duration": dash_duration,
		&"dash_cooldown": dash_cooldown,
		&"dash_exit_speed": speed * dash_exit_speed_multiplier,
		&"dash_exit_momentum_duration": dash_exit_momentum_duration,
		&"dash_exit_active": dash_exit_time_remaining > 0.0,
		&"dash_ready": dash_cooldown_remaining <= 0.0,
	}
