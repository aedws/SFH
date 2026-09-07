class_name DungeonFloorLayer
extends TileMapLayer
## Visual-only tile adapter. Generation, merged collisions and navigation stay independent.

var _palette_key := ""


func rebuild(cells: Dictionary, world_cell_size: float, primary: Color, alternate: Color) -> void:
	clear()
	collision_enabled = false
	navigation_enabled = false
	z_index = -1
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var pixels := maxi(1, roundi(world_cell_size))
	scale = Vector2.ONE * world_cell_size / float(pixels)
	var key := "%d/%s/%s" % [pixels, primary.to_html(), alternate.to_html()]
	if tile_set == null or key != _palette_key:
		_palette_key = key
		var atlas_image := Image.create(pixels * 2, pixels, false, Image.FORMAT_RGBA8)
		atlas_image.fill(primary)
		atlas_image.fill_rect(Rect2i(pixels, 0, pixels, pixels), alternate)
		var atlas := TileSetAtlasSource.new()
		atlas.texture = ImageTexture.create_from_image(atlas_image)
		atlas.texture_region_size = Vector2i.ONE * pixels
		atlas.create_tile(Vector2i.ZERO)
		atlas.create_tile(Vector2i.RIGHT)
		tile_set = TileSet.new()
		tile_set.tile_size = Vector2i.ONE * pixels
		tile_set.add_source(atlas, 0)
	for cell: Vector2i in cells:
		set_cell(cell, 0, Vector2i.ZERO if (cell.x + cell.y) % 2 == 0 else Vector2i.RIGHT)


func get_snapshot() -> Dictionary:
	return {&"renderer": &"TileMapLayer", &"tile_count": get_used_cells().size(),
		&"collision_enabled": collision_enabled, &"navigation_enabled": navigation_enabled}
