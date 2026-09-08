class_name GameDossier
extends Control
## In-game overlay, not an OS dialog. Preserves caller pause and keyboard focus.
const UI = preload("res://game/features/presentation_theme/game_ui.gd")
var title := "작전 기록"
var panel: PanelContainer
var content: VBoxContainer
var heading: Label
var close_button: Button
var requested_size := Vector2(700, 540)
var previous_focus: WeakRef
var previous_pause := false
var layout_dirty := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var shade := ColorRect.new()
	shade.color = Color(0.005, 0.01, 0.02, 0.92)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	panel = PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UI.surface(UI.ACCENT, true))
	panel.minimum_size_changed.connect(func(): layout_dirty = true)
	add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 16)
	panel.add_child(column)
	heading = UI.header(column, title, "기록 보관소 / ARCHIVE", "codex")
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	column.add_child(scroll)
	content = VBoxContainer.new()
	content.size_flags_horizontal = SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 12)
	scroll.add_child(content)
	close_button = Button.new()
	close_button.text = "돌아가기 · ESC"
	UI.action(close_button, "move")
	close_button.pressed.connect(close_panel)
	column.add_child(close_button)
	resized.connect(_layout)
	hide()

func popup_centered(target: Vector2i = Vector2i(700, 540)) -> void:
	if not visible:
		previous_pause = get_tree().paused
		var focus := get_viewport().gui_get_focus_owner()
		previous_focus = weakref(focus) if focus != null else null
	requested_size = Vector2(target)
	heading.text = title
	show()
	move_to_front()
	get_tree().paused = true
	_layout()
	close_button.grab_focus()

func close_panel() -> void:
	if not visible: return
	hide()
	get_tree().paused = previous_pause
	if previous_focus != null and is_instance_valid(previous_focus.get_ref()):
		var focus: Control = previous_focus.get_ref()
		if focus.is_visible_in_tree(): focus.grab_focus()

func _input(event: InputEvent) -> void:
	if visible and event.is_action_pressed(&"ui_cancel") and not event.is_echo():
		close_panel()
		get_viewport().set_input_as_handled()

func _layout() -> void:
	if panel == null: return
	panel.size = requested_size.min((size - Vector2(24, 24)).max(Vector2(1, 1)))
	panel.position = (size - panel.size) * 0.5

func _process(_delta: float) -> void:
	# Autowrap/grid minimum changes can emit again during layout. Coalesce once
	# per frame instead of recursively draining deferred layouts in one frame.
	if layout_dirty:
		layout_dirty = false
		_layout()
