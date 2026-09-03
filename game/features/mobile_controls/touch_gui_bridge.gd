extends RefCounted

## 패드 밖의 터치를 GUI에만 전달합니다. InputMap의 마우스 공격 상태는 누르지 않습니다.
var finger := -1
var position := Vector2.ZERO

func handle(event: InputEvent, viewport: Viewport) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and not event.canceled and finger == -1:
			finger = event.index
			position = event.position
			_mouse_button(viewport, true)
		elif event.index == finger and (not event.pressed or event.canceled):
			position = Vector2(-1000, -1000) if event.canceled else event.position
			release(viewport)
	elif event is InputEventScreenDrag and event.index == finger:
		var motion := InputEventMouseMotion.new()
		motion.position = event.position
		motion.relative = event.position - position
		motion.button_mask = MOUSE_BUTTON_MASK_LEFT
		position = event.position
		viewport.push_input(motion, true)

func release(viewport: Viewport, cancel: bool = false) -> void:
	if finger == -1:
		return
	finger = -1
	if cancel:
		position = Vector2(-1000, -1000)
	_mouse_button(viewport, false)

func _mouse_button(viewport: Viewport, pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.position = position
	event.button_index = MOUSE_BUTTON_LEFT
	event.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
	event.pressed = pressed
	viewport.push_input(event, true)
