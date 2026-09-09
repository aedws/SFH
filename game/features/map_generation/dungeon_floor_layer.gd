class_name DungeonFloorLayer
extends Node2D
## One texel per logical cell; bounded chunks avoid per-tile quadrant uploads.
## Pure presentation: collision, navigation and generation remain owned by the map.
@export_range(32, 256, 32) var chunk_cells: int = 128
var _textures: Dictionary = {}
var _cells: Dictionary = {}
var _cell_size := 32.0
var _render_chunk_cells := 128

func rebuild(cells: Dictionary, world_cell_size: float, primary: Color, alternate: Color, surface_colors: Dictionary = {}) -> void:
	_textures.clear()
	_cells = cells.duplicate()
	_cell_size = world_cell_size
	_render_chunk_cells = clampi(chunk_cells, 32, 256)
	z_index = -1
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var images: Dictionary = {}
	for cell: Vector2i in cells:
		var chunk := Vector2i(floori(float(cell.x) / _render_chunk_cells), floori(float(cell.y) / _render_chunk_cells))
		if not images.has(chunk):
			var image := Image.create(_render_chunk_cells, _render_chunk_cells, false, Image.FORMAT_RGBA8)
			image.fill(Color.TRANSPARENT)
			images[chunk] = image
		var local := cell - chunk * _render_chunk_cells
		images[chunk].set_pixel(local.x, local.y, surface_colors.get(cell,primary if (cell.x + cell.y) % 2 == 0 else alternate))
	for chunk: Vector2i in images:
		_textures[chunk] = ImageTexture.create_from_image(images[chunk])
	queue_redraw()

func _draw() -> void:
	for chunk: Vector2i in _textures:
		draw_texture_rect(_textures[chunk], Rect2(Vector2(chunk * _render_chunk_cells) * _cell_size, Vector2.ONE * _render_chunk_cells * _cell_size), false)

func get_used_cells() -> Array:
	return _cells.keys()

func map_to_local(cell: Vector2i) -> Vector2:
	return (Vector2(cell) + Vector2.ONE * 0.5) * _cell_size

func get_snapshot() -> Dictionary:
	return {&"renderer": &"ChunkedCellTexture", &"tile_count": _cells.size(),
		&"chunk_count": _textures.size(), &"texture_bytes": _textures.size() * _render_chunk_cells * _render_chunk_cells * 4,
		&"collision_enabled": false, &"navigation_enabled": false}
