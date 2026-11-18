class_name V2AtlasPainter
extends RefCounted

## Utilitário compartilhado de composição 16×16, gradação sombria por Ato
## (Normal, Distorcido Ato 2, Realidade Crua Ato 3) e construção de TileSet Godot 4.

const TILE := 16


static func load_rgba(res_path: String) -> Image:
	var abs_path := ProjectSettings.globalize_path(res_path)
	var img := Image.load_from_file(abs_path)
	if img == null:
		push_error("V2AtlasPainter: falha ao carregar %s" % res_path)
		return null
	img.convert(Image.FORMAT_RGBA8)
	return img


static func create_sheet(cols: int, rows: int) -> Image:
	var img := Image.create_empty(cols * TILE, rows * TILE, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	return img


static func grade_color(c: Color, variant: String, sat_mul: float = 0.86, val_mul: float = 0.90, tint: Color = Color.WHITE) -> Color:
	if c.a < 0.04:
		return Color(0, 0, 0, 0)
	var lum := c.r * 0.299 + c.g * 0.587 + c.b * 0.114
	if variant == "act3":
		# Ato III: realidade fria monocromática sem filtros sobrenaturais
		var gray := clampf(lum * 0.92 + 0.03, 0.04, 0.90)
		return Color(gray * 0.96, gray * 0.98, clampf(gray * 1.02, 0.0, 1.0), c.a)
	if variant == "distorted":
		# Ato II Dose Alta: cinza carbonizado/ardósia com vestígios carmesim
		var d_lum := clampf((lum - 0.10) * 0.62 + 0.06, 0.03, 0.52)
		var r := d_lum * 0.96
		var g := d_lum * 0.72
		var b := d_lum * 0.80
		if c.r > c.g * 1.25 and lum > 0.25:
			r = clampf(d_lum * 1.48, 0.16, 0.68)
			g = d_lum * 0.34
			b = d_lum * 0.38
		return Color(clampf(r, 0.0, 1.0), clampf(g, 0.0, 1.0), clampf(b, 0.0, 1.0), c.a)

	var r := lerpf(lum, c.r, sat_mul) * val_mul * tint.r
	var g := lerpf(lum, c.g, sat_mul) * val_mul * tint.g
	var b := lerpf(lum, c.b, sat_mul) * val_mul * tint.b
	return Color(clampf(r, 0.0, 1.0), clampf(g, 0.0, 1.0), clampf(b, 0.0, 1.0), c.a)


static func blit_tiles(dst: Image, src: Image, src_tile: Vector2i, dst_tile: Vector2i, size_tiles: Vector2i = Vector2i.ONE, variant: String = "normal", sat_mul: float = 0.86, val_mul: float = 0.90, tint: Color = Color.WHITE, key_white: bool = false) -> void:
	if dst == null or src == null:
		return
	var sx0 := src_tile.x * TILE
	var sy0 := src_tile.y * TILE
	var dx0 := dst_tile.x * TILE
	var dy0 := dst_tile.y * TILE
	var pw := size_tiles.x * TILE
	var ph := size_tiles.y * TILE
	for py in range(ph):
		var sy := sy0 + py
		var dy := dy0 + py
		if sy < 0 or sy >= src.get_height() or dy < 0 or dy >= dst.get_height():
			continue
		for px in range(pw):
			var sx := sx0 + px
			var dx := dx0 + px
			if sx < 0 or sx >= src.get_width() or dx < 0 or dx >= dst.get_width():
				continue
			var col := src.get_pixel(sx, sy)
			if col.a < 0.04:
				continue
			if key_white and col.r >= 0.95 and col.g >= 0.95 and col.b >= 0.95:
				continue
			dst.set_pixel(dx, dy, grade_color(col, variant, sat_mul, val_mul, tint))


static func clear_tiles_rect(dst: Image, dst_tile: Vector2i, size_tiles: Vector2i) -> void:
	if dst == null:
		return
	var x0 := dst_tile.x * TILE
	var y0 := dst_tile.y * TILE
	for y in range(y0, y0 + size_tiles.y * TILE):
		for x in range(x0, x0 + size_tiles.x * TILE):
			if x >= 0 and x < dst.get_width() and y >= 0 and y < dst.get_height():
				dst.set_pixel(x, y, Color(0, 0, 0, 0))


static func blit_px_centered(dst: Image, src: Image, src_rect: Rect2i, dst_tile: Vector2i, dst_size_tiles: Vector2i, variant: String = "normal", sat_mul: float = 0.86, val_mul: float = 0.90, tint: Color = Color.WHITE) -> void:
	if dst == null or src == null:
		return
	var dst_w := dst_size_tiles.x * TILE
	var dst_h := dst_size_tiles.y * TILE
	var off_x := dst_tile.x * TILE + maxi(0, (dst_w - src_rect.size.x) / 2)
	var off_y := dst_tile.y * TILE + maxi(0, dst_h - src_rect.size.y)
	for py in range(src_rect.size.y):
		var sy := src_rect.position.y + py
		var dy := off_y + py
		if sy < 0 or sy >= src.get_height() or dy < 0 or dy >= dst.get_height():
			continue
		for px_i in range(src_rect.size.x):
			var sx := src_rect.position.x + px_i
			var dx := off_x + px_i
			if sx < 0 or sx >= src.get_width() or dx < 0 or dx >= dst.get_width():
				continue
			var col := src.get_pixel(sx, sy)
			if col.a < 0.04:
				continue
			dst.set_pixel(dx, dy, grade_color(col, variant, sat_mul, val_mul, tint))


static func blit_graded_overlay(dst: Image, overlay_img: Image, dst_tile: Vector2i, variant: String) -> void:
	if dst == null or overlay_img == null:
		return
	var dx0 := dst_tile.x * TILE
	var dy0 := dst_tile.y * TILE
	for py in range(overlay_img.get_height()):
		var dy := dy0 + py
		if dy < 0 or dy >= dst.get_height():
			continue
		for px in range(overlay_img.get_width()):
			var dx := dx0 + px
			if dx < 0 or dx >= dst.get_width():
				continue
			var col := overlay_img.get_pixel(px, py)
			if col.a < 0.04:
				continue
			dst.set_pixel(dx, dy, grade_color(col, variant, 0.96, 0.98, Color.WHITE))


static func fill_tile(dst: Image, tile: Vector2i, col: Color, variant: String) -> void:
	var gcol := grade_color(col, variant, 0.92, 0.96, Color.WHITE)
	var x0 := tile.x * TILE
	var y0 := tile.y * TILE
	for y in range(y0, y0 + TILE):
		for x in range(x0, x0 + TILE):
			dst.set_pixel(x, y, gcol)


static func px(dst: Image, x: int, y: int, col: Color) -> void:
	if x < 0 or x >= dst.get_width() or y < 0 or y >= dst.get_height():
		return
	dst.set_pixel(x, y, col)


static func rect_px(dst: Image, x0: int, y0: int, w: int, h: int, col: Color) -> void:
	for y in range(y0, y0 + h):
		for x in range(x0, x0 + w):
			px(dst, x, y, col)


static func add_shadow_strips(dst: Image, top_tile: Vector2i, left_tile: Vector2i, corner_tile: Vector2i, blob_tile: Vector2i, variant: String) -> void:
	var sh_base := Color(0.03, 0.04, 0.08, 0.45) if variant != "distorted" else Color(0.02, 0.01, 0.03, 0.56)
	# Sombra projetada superior (abaixo de paredes/telhados horizontais)
	var tx0 := top_tile.x * TILE
	var ty0 := top_tile.y * TILE
	for y in range(6):
		var a := lerpf(sh_base.a, 0.08, float(y) / 5.0)
		for x in range(TILE):
			dst.set_pixel(tx0 + x, ty0 + y, Color(sh_base.r, sh_base.g, sh_base.b, a))
	# Sombra lateral esquerda (ao lado direito de paredes verticais)
	var lx0 := left_tile.x * TILE
	var ly0 := left_tile.y * TILE
	for x in range(5):
		var a := lerpf(sh_base.a, 0.08, float(x) / 4.0)
		for y in range(TILE):
			dst.set_pixel(lx0 + x, ly0 + y, Color(sh_base.r, sh_base.g, sh_base.b, a))
	# Sombra de quina interna
	var cx0 := corner_tile.x * TILE
	var cy0 := corner_tile.y * TILE
	for y in range(TILE):
		for x in range(TILE):
			var d := minf(float(x) / 5.0, float(y) / 6.0)
			if d < 1.0:
				dst.set_pixel(cx0 + x, cy0 + y, Color(sh_base.r, sh_base.g, sh_base.b, lerpf(sh_base.a, 0.08, d)))
	# Sombra oval de copa/adereço no solo (16×16 pontilhada)
	var bx0 := blob_tile.x * TILE
	var by0 := blob_tile.y * TILE
	for y in range(TILE):
		for x in range(TILE):
			var nx := (float(x) + 0.5 - 8.0) / 7.2
			var ny := (float(y) + 0.5 - 9.0) / 5.2
			var dist := nx * nx + ny * ny
			if dist <= 1.0:
				var dither_a := sh_base.a if dist < 0.65 or ((x + y) % 2 == 0) else sh_base.a * 0.45
				dst.set_pixel(bx0 + x, by0 + y, Color(sh_base.r, sh_base.g, sh_base.b, dither_a))


static func _cell_has_ink(img: Image, tile: Vector2i, size_tiles: Vector2i = Vector2i.ONE) -> bool:
	var x0 := tile.x * TILE
	var y0 := tile.y * TILE
	var x1 := mini(img.get_width(), x0 + size_tiles.x * TILE)
	var y1 := mini(img.get_height(), y0 + size_tiles.y * TILE)
	for y in range(y0, y1):
		for x in range(x0, x1):
			if img.get_pixel(x, y).a > 0.02:
				return true
	return false


static func save_atlas_and_tileset(out_dir: String, name_base: String, img: Image, spec: Dictionary) -> void:
	var png_res := "%s/%s.png" % [out_dir, name_base]
	var tres_res := "%s/%s_tileset.tres" % [out_dir, name_base]
	img.save_png(ProjectSettings.globalize_path(png_res))

	var tex: Texture2D = null
	if FileAccess.file_exists(ProjectSettings.globalize_path(png_res + ".import")):
		tex = ResourceLoader.load(png_res) as Texture2D
	if tex == null:
		tex = ImageTexture.create_from_image(img)

	var ts := TileSet.new()
	ts.tile_size = Vector2i(TILE, TILE)
	ts.add_physics_layer(0)
	ts.set_physics_layer_collision_layer(0, 1)
	ts.set_physics_layer_collision_mask(0, 0)

	# Camadas de metadados de piso/iluminação para scripts na Fase 2
	ts.add_custom_data_layer(0)
	ts.set_custom_data_layer_name(0, "surface_type")
	ts.set_custom_data_layer_type(0, TYPE_STRING)
	ts.add_custom_data_layer(1)
	ts.set_custom_data_layer_name(1, "is_water")
	ts.set_custom_data_layer_type(1, TYPE_BOOL)
	ts.add_custom_data_layer(2)
	ts.set_custom_data_layer_name(2, "blocks_light")
	ts.set_custom_data_layer_type(2, TYPE_BOOL)

	var src := TileSetAtlasSource.new()
	src.texture = tex
	src.texture_region_size = Vector2i(TILE, TILE)
	ts.add_source(src, 0)

	var multi_tiles: Array = spec.get("multi_tiles", [])
	var anim_tiles: Array = spec.get("animated_tiles", [])
	var solid_cells: Array = spec.get("solid_cells", [])
	var surface_map: Dictionary = spec.get("surface_map", {})
	var water_cells: Array = spec.get("water_cells", [])
	var light_block_cells: Array = spec.get("light_block_cells", [])

	var occupied: Dictionary = {}

	# 1. Tiles animados (frames consecutivos horizontais no atlas)
	for anim_cfg_v in anim_tiles:
		var cfg: Dictionary = anim_cfg_v
		var coord: Vector2i = cfg["coord"]
		var frames: int = int(cfg.get("frames", 3))
		var dur: float = float(cfg.get("frame_duration", 0.35))
		for fx in range(frames):
			occupied[Vector2i(coord.x + fx, coord.y)] = true
		src.create_tile(coord)
		src.set_tile_animation_columns(coord, frames)
		src.set_tile_animation_frames_count(coord, frames)
		for fi in range(frames):
			src.set_tile_animation_frame_duration(coord, fi, dur)
		_apply_tile_metadata(src, coord, cfg.get("solid", false), cfg.get("poly", PackedVector2Array()), str(cfg.get("surface", "water")), bool(cfg.get("is_water", true)), false, 0, Vector2i.ZERO)

	# 2. Objetos multi-tile (coqueiros, árvores, casas, viaturas, móveis) com Y-sort na base
	for mt_v in multi_tiles:
		var mt: Dictionary = mt_v
		var coord: Vector2i = mt["coord"]
		var sz: Vector2i = mt["size"]
		for dy in range(sz.y):
			for dx in range(sz.x):
				occupied[Vector2i(coord.x + dx, coord.y + dy)] = true
		src.create_tile(coord, sz)
		var origin_x := int(mt.get("origin_x", 8 if sz.x % 2 == 0 else 0))
		var origin_y := (sz.y - 1) * 8
		var y_sort := int(mt.get("y_sort_origin", 6))
		var poly: PackedVector2Array = mt.get("collision_poly", PackedVector2Array([
			Vector2(-7, -6), Vector2(7, -6), Vector2(7, 8), Vector2(-7, 8)
		]))
		if origin_x != 0 and not poly.is_empty():
			var shifted := PackedVector2Array()
			for pt in poly:
				shifted.append(pt - Vector2(float(origin_x), 0.0))
			poly = shifted
		_apply_tile_metadata(
			src,
			coord,
			bool(mt.get("solid", true)),
			poly,
			str(mt.get("surface", "prop")),
			false,
			bool(mt.get("blocks_light", false)),
			y_sort,
			Vector2i(origin_x, origin_y)
		)

	# 3. Demais tiles 1×1 com conteúdo no atlas
	var cols := img.get_width() / TILE
	var rows := img.get_height() / TILE
	var full_box := PackedVector2Array([Vector2(-8, -8), Vector2(8, -8), Vector2(8, 8), Vector2(-8, 8)])
	for y in range(rows):
		for x in range(cols):
			var c := Vector2i(x, y)
			if occupied.has(c):
				continue
			if not _cell_has_ink(img, c):
				continue
			src.create_tile(c)
			var is_solid := solid_cells.has(c)
			var is_water := water_cells.has(c)
			var blocks_l := light_block_cells.has(c)
			var surf := str(surface_map.get(c, "water" if is_water else "ground"))
			_apply_tile_metadata(src, c, is_solid, full_box, surf, is_water, blocks_l, 0, Vector2i.ZERO)

	var err := ResourceSaver.save(ts, tres_res)
	if err != OK:
		push_error("V2AtlasPainter: erro ao salvar TileSet %s (err=%d)" % [tres_res, err])


static func _apply_tile_metadata(
	src: TileSetAtlasSource,
	coord: Vector2i,
	is_solid: bool,
	poly: PackedVector2Array,
	surface_type: String,
	is_water: bool,
	blocks_light: bool,
	y_sort_origin: int,
	texture_origin: Vector2i
) -> void:
	var td := src.get_tile_data(coord, 0)
	if td == null:
		return
	td.texture_origin = texture_origin
	td.y_sort_origin = y_sort_origin
	td.set_custom_data("surface_type", surface_type)
	td.set_custom_data("is_water", is_water)
	td.set_custom_data("blocks_light", blocks_light)
	if is_solid and not poly.is_empty():
		td.add_collision_polygon(0)
		td.set_collision_polygon_points(0, 0, poly)
