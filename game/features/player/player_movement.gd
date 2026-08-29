class_name PlayerMovement
extends Node

## 입력을 이동 속도로 바꾸는 독립 컴포넌트입니다.
## 방향키는 Godot 기본 ui_* 입력을 사용하고 WASD는 물리 키로 읽습니다.

@export_range(0.0, 2000.0, 10.0, "or_greater") var speed: float = 260.0


func get_velocity() -> Vector2:
	var direction := Input.get_vector(&"ui_left", &"ui_right", &"ui_up", &"ui_down")
	var wasd_direction := Vector2(
		float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A)),
		float(Input.is_physical_key_pressed(KEY_S)) - float(Input.is_physical_key_pressed(KEY_W))
	)

	if wasd_direction != Vector2.ZERO:
		direction = wasd_direction.normalized()

	return direction * speed
