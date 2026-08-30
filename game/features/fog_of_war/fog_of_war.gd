class_name BattlefieldFogOfWar
extends CanvasLayer

@export_range(160.0, 1200.0, 10.0) var vision_radius: float = 410.0
@export_range(20.0, 400.0, 10.0) var edge_softness: float = 150.0
@export var fog_color := Color(0.008, 0.014, 0.025, 0.94)

@onready var overlay: ColorRect = %FogOverlay

var tracked_actor: Node2D


func _ready() -> void:
	layer = 0
	process_mode = Node.PROCESS_MODE_PAUSABLE
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(false)


func configure(actor: Node2D) -> bool:
	if not is_instance_valid(actor):
		return false
	tracked_actor = actor
	_apply_static_shader_parameters()
	set_process(true)
	_update_focus()
	return true


func get_snapshot() -> Dictionary:
	return {
		&"vision_radius": vision_radius,
		&"edge_softness": edge_softness,
		&"fog_color": fog_color,
		&"tracks_actor": is_instance_valid(tracked_actor),
		&"canvas_layer": layer,
	}


func _process(_delta: float) -> void:
	_update_focus()


func _apply_static_shader_parameters() -> void:
	var shader_material := overlay.material as ShaderMaterial
	if shader_material == null:
		return
	shader_material.set_shader_parameter(&"vision_radius", vision_radius)
	shader_material.set_shader_parameter(&"edge_softness", edge_softness)
	shader_material.set_shader_parameter(&"fog_color", fog_color)


func _update_focus() -> void:
	if not is_instance_valid(tracked_actor):
		set_process(false)
		return
	var shader_material := overlay.material as ShaderMaterial
	if shader_material == null:
		return
	var viewport_size := get_viewport().get_visible_rect().size
	var screen_position := tracked_actor.get_global_transform_with_canvas().origin
	shader_material.set_shader_parameter(&"viewport_size", viewport_size)
	shader_material.set_shader_parameter(&"focus_position", screen_position)
