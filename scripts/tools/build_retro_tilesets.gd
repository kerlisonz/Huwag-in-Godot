@tool
extends SceneTree

# Builds Huwag's FNAF-Minigames + Yume-Nikki + Chrono-Trigger + Pokemon-GB
# retro 16x16 tileset atlases & Godot TileSet .tres resources under res://assets/tilesets/retro/
# derived cleanly from existing third_party packs + custom arcade horror pixel tiles.

const OUT_DIR := "res://assets/tilesets/retro"

func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))

	var house_fw := _load_img("res://assets/third_party/Top-Down_Retro_Interior/TopDownHouse_FloorsAndWalls.png")
	var room_bld := _load_img("res://assets/third_party/Modern_Interiors_Free_v2.2/Modern tiles_Free/Interiors_free/16x16/Room_Builder_free_16x16.png")
	var interiors := _load_img("res://assets/third_party/Modern_Interiors_Free_v2.2/Modern tiles_Free/Interiors_free/16x16/Interiors_free_16x16.png")
	var serene := _load_img("res://assets/third_party/Serene_Village_revamped_v1.9/SERENE_VILLAGE_REVAMPED/Serene_Village_16x16.png")
	var tx_grass := _load_img("res://assets/third_party/Pixel Art Top Down - Basic v1.2.3/Texture/TX Tileset Grass.png")
	var tx_stone := _load_img("res://assets/third_party/Pixel Art Top Down - Basic v1.2.3/Texture/TX Tileset Stone Ground.png")

	# 1. INTERIOR ATLAS (256x256, 16x16 grid, 3 active rows)
	var int_norm := _build_interior_atlas(house_fw, room_bld, interiors, false)
	var int_dist := _build_interior_atlas(house_fw, room_bld, interiors, true)
	_save_atlas_and_tileset("interior_fnaf_normal", int_norm, _interior_solid_coords())
	_save_atlas_and_tileset("interior_fnaf_distorted", int_dist, _interior_solid_coords())

	# 2. TOWN ATLAS
	var town_norm := _build_town_atlas(serene, tx_stone, tx_grass, false)
	var town_dist := _build_town_atlas(serene, tx_stone, tx_grass, true)
	_save_atlas_and_tileset("town_fnaf_normal", town_norm, _town_solid_coords())
	_save_atlas_and_tileset("town_fnaf_distorted", town_dist, _town_solid_coords())

	# 3. FOREST ATLAS
	var forest_norm := _build_forest_atlas(tx_grass, tx_stone, serene, false)
	var forest_dist := _build_forest_atlas(tx_grass, tx_stone, serene, true)
	_save_atlas_and_tileset("forest_fnaf_normal", forest_norm, _forest_solid_coords())
	_save_atlas_and_tileset("forest_fnaf_distorted", forest_dist, _forest_solid_coords())

	# Preview sheet for visual inspection in scratch
	_save_preview_sheet(int_norm, int_dist, town_norm, town_dist, forest_norm, forest_dist)
	print("Retro FNAF-Minigames tilesets generated successfully in " + OUT_DIR)
	quit(0)


func _load_img(res_path: String) -> Image:
	var img := Image.load_from_file(ProjectSettings.globalize_path(res_path))
	if img != null:
		img.convert(Image.FORMAT_RGBA8)
	return img


func _save_atlas_and_tileset(name_base: String, img: Image, solid_coords: Array[Vector2i]) -> void:
	var png_res := "%s/%s.png" % [OUT_DIR, name_base]
	var tres_res := "%s/%s_tileset.tres" % [OUT_DIR, name_base]
	img.save_png(ProjectSettings.globalize_path(png_res))

	var tex: Texture2D = null
	if FileAccess.file_exists(png_res + ".import"):
		tex = ResourceLoader.load(png_res) as Texture2D
	if tex == null:
		tex = ImageTexture.create_from_image(img)

	var ts := TileSet.new()
	ts.tile_size = Vector2i(16, 16)
	ts.add_physics_layer(0)
	ts.set_physics_layer_collision_layer(0, 1)
	ts.set_physics_layer_collision_mask(0, 0)

	var source := TileSetAtlasSource.new()
	source.texture = tex
	source.texture_region_size = Vector2i(16, 16)
	ts.add_source(source, 0)

	var poly := PackedVector2Array([
		Vector2(-8, -8), Vector2(8, -8), Vector2(8, 8), Vector2(-8, 8)
	])

	var cols := img.get_width() / 16
	var rows := img.get_height() / 16
	for y in range(rows):
		for x in range(cols):
			var c := Vector2i(x, y)
			if _tile_has_pixels(img, c):
				source.create_tile(c)
				if solid_coords.has(c):
					var td := source.get_tile_data(c, 0)
					if td != null:
						td.add_collision_polygon(0)
						td.set_collision_polygon_points(0, 0, poly)

	ResourceSaver.save(ts, tres_res)


func _tile_has_pixels(img: Image, coord: Vector2i) -> bool:
	var x0 := coord.x * 16
	var y0 := coord.y * 16
	for y in range(y0, y0 + 16):
		for x in range(x0, x0 + 16):
			if img.get_pixel(x, y).a > 0.02:
				return true
	return false


func _blit_graded(dst: Image, src: Image, src_rect: Rect2i, dest_tile: Vector2i, sat_mul: float, val_mul: float, tint: Color, distorted: bool) -> void:
	if src == null:
		return
	var dx0 := dest_tile.x * 16
	var dy0 := dest_tile.y * 16
	for py in range(16):
		for px in range(16):
			var sx := clampi(src_rect.position.x + (px % src_rect.size.x), 0, src.get_width() - 1)
			var sy := clampi(src_rect.position.y + (py % src_rect.size.y), 0, src.get_height() - 1)
			var c := src.get_pixel(sx, sy)
			if c.a < 0.05:
				continue
			var l := c.r * 0.299 + c.g * 0.587 + c.b * 0.114
			var r := lerpf(l, c.r, sat_mul) * val_mul * tint.r
			var g := lerpf(l, c.g, sat_mul) * val_mul * tint.g
			var b := lerpf(l, c.b, sat_mul) * val_mul * tint.b
			if distorted:
				# High contrast dark ash/charcoal + cold slate + sparse crimson decay (no pink washout)
				var cl := clampf((l - 0.15) * 0.55 + 0.08, 0.03, 0.44)
				r = cl * 0.88 * tint.r
				g = cl * 0.72 * tint.g
				b = cl * 0.80 * tint.b
				if (px * 5 + py * 3) % 29 == 0 and l > 0.35:
					r = clampf(cl * 1.45, 0.18, 0.56)
					g = cl * 0.18
					b = cl * 0.22
			dst.set_pixel(dx0 + px, dy0 + py, Color(clampf(r, 0.0, 1.0), clampf(g, 0.0, 1.0), clampf(b, 0.0, 1.0), 1.0))


func _fill_tile(dst: Image, tile: Vector2i, col: Color) -> void:
	var x0 := tile.x * 16
	var y0 := tile.y * 16
	for y in range(y0, y0 + 16):
		for x in range(x0, x0 + 16):
			dst.set_pixel(x, y, col)


func _px(dst: Image, tile: Vector2i, x: int, y: int, col: Color) -> void:
	if x < 0 or x >= 16 or y < 0 or y >= 16:
		return
	dst.set_pixel(tile.x * 16 + x, tile.y * 16 + y, col)


func _rect_t(dst: Image, tile: Vector2i, x0: int, y0: int, w: int, h: int, col: Color) -> void:
	for y in range(maxi(0, y0), mini(16, y0 + h)):
		for x in range(maxi(0, x0), mini(16, x0 + w)):
			dst.set_pixel(tile.x * 16 + x, tile.y * 16 + y, col)


func _interior_solid_coords() -> Array[Vector2i]:
	var arr: Array[Vector2i] = []
	for x in range(12):
		arr.append(Vector2i(x, 1))
	arr.append(Vector2i(13, 1))
	arr.append(Vector2i(14, 1))
	arr.append(Vector2i(15, 1))
	for x in range(16):
		arr.append(Vector2i(x, 2))
	return arr


func _town_solid_coords() -> Array[Vector2i]:
	var arr: Array[Vector2i] = []
	for x in range(16):
		if x != 9: # Door threshold walkable / triggerable
			arr.append(Vector2i(x, 1))
	return arr


func _forest_solid_coords() -> Array[Vector2i]:
	var arr: Array[Vector2i] = []
	for x in range(8):
		arr.append(Vector2i(x, 1))
	return arr


func _build_interior_atlas(house_fw: Image, room_bld: Image, _interiors: Image, dist: bool) -> Image:
	var img := Image.create_empty(256, 64, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	var void_col := Color(0.012, 0.012, 0.022, 1.0)
	var c_dark := Color(0.075, 0.08, 0.11, 1.0) if not dist else Color(0.04, 0.03, 0.05, 1.0)
	var c_mid := Color(0.145, 0.155, 0.20, 1.0) if not dist else Color(0.18, 0.07, 0.09, 1.0)

	# Row 0: Floors
	_fill_tile(img, Vector2i(0, 0), void_col)
	_fill_tile(img, Vector2i(1, 0), void_col)
	for y in range(0, 16, 2):
		_rect_t(img, Vector2i(1, 0), 0, y, 16, 1, Color(0.035, 0.035, 0.055, 1.0))

	# (2,0) FNAF Checkerboard
	for y in range(16):
		for x in range(16):
			var chk := ((x / 8) + (y / 8)) % 2 == 0
			_px(img, Vector2i(2, 0), x, y, c_dark if chk else c_mid)
	# (3,0) Worn/Cracked Checkerboard
	img.blit_rect(img, Rect2i(32, 0, 16, 16), Vector2i(48, 0))
	var crack_col := Color(0.03, 0.03, 0.04, 1.0) if not dist else Color(0.45, 0.06, 0.09, 1.0)
	for i in range(3, 13):
		_px(img, Vector2i(3, 0), i, (i * 2) % 14 + 1, crack_col)
		if dist:
			_px(img, Vector2i(3, 0), clampi(i + 1, 0, 15), (i * 2 + 1) % 14 + 1, Color(0.68, 0.10, 0.14, 1.0))

	# (4,0) Huwag Desaturated Wood Floor (from TopDownHouse_FloorsAndWalls bottom-left wood)
	_blit_graded(img, house_fw, Rect2i(16, 80, 16, 16), Vector2i(4, 0), 0.38, 0.56 if not dist else 0.38, Color(0.95, 0.88, 0.82) if not dist else Color(0.85, 0.65, 0.68), dist)
	# (5,0) Worn Wood Plank B
	_blit_graded(img, house_fw, Rect2i(32, 96, 16, 16), Vector2i(5, 0), 0.32, 0.50 if not dist else 0.34, Color(0.9, 0.84, 0.78), dist)
	_rect_t(img, Vector2i(5, 0), 3, 6, 9, 1, Color(0.05, 0.04, 0.04) if not dist else Color(0.45, 0.08, 0.10))

	# (6,0) Banig Mat
	_blit_graded(img, house_fw, Rect2i(96, 96, 16, 16), Vector2i(6, 0), 0.35, 0.62 if not dist else 0.44, Color(0.96, 0.90, 0.76), dist)
	# (7,0) Concrete Station Floor A
	_fill_tile(img, Vector2i(7, 0), Color(0.16, 0.18, 0.22) if not dist else Color(0.11, 0.11, 0.14))
	_rect_t(img, Vector2i(7, 0), 0, 0, 16, 1, Color(0.11, 0.12, 0.16))
	_rect_t(img, Vector2i(7, 0), 0, 0, 1, 16, Color(0.11, 0.12, 0.16))
	_px(img, Vector2i(7, 0), 5, 11, Color(0.22, 0.24, 0.29))
	_px(img, Vector2i(7, 0), 12, 4, Color(0.10, 0.11, 0.14))
	# (8,0) Concrete Drain Grate
	img.blit_rect(img, Rect2i(7 * 16, 0, 16, 16), Vector2i(8 * 16, 0))
	_rect_t(img, Vector2i(8, 0), 4, 4, 8, 8, Color(0.06, 0.06, 0.09))
	for gx in range(5, 11, 2):
		_rect_t(img, Vector2i(8, 0), gx, 5, 1, 6, Color(0.24, 0.26, 0.30) if not dist else Color(0.48, 0.09, 0.12))
	# (9,0) Truck Bay Oil Concrete
	_fill_tile(img, Vector2i(9, 0), Color(0.12, 0.13, 0.17))
	for y in range(16):
		for x in range(16):
			if (x + y) % 8 < 3 and y >= 12:
				_px(img, Vector2i(9, 0), x, y, Color(0.62, 0.45, 0.14) if not dist else Color(0.55, 0.12, 0.14))
	# (10,0) Clinic Pale Floor
	_fill_tile(img, Vector2i(10, 0), Color(0.24, 0.27, 0.32) if not dist else Color(0.17, 0.16, 0.20))
	_rect_t(img, Vector2i(10, 0), 0, 0, 16, 1, Color(0.16, 0.18, 0.23))
	_rect_t(img, Vector2i(10, 0), 0, 0, 1, 16, Color(0.16, 0.18, 0.23))
	# (11,0) BFP Red Trim Floor
	_fill_tile(img, Vector2i(11, 0), Color(0.16, 0.18, 0.22))
	_rect_t(img, Vector2i(11, 0), 0, 0, 16, 3, Color(0.48, 0.13, 0.15) if not dist else Color(0.65, 0.08, 0.10))
	_rect_t(img, Vector2i(11, 0), 0, 13, 16, 3, Color(0.48, 0.13, 0.15) if not dist else Color(0.65, 0.08, 0.10))
	# (12,0) Entry Mat
	_fill_tile(img, Vector2i(12, 0), Color(0.18, 0.12, 0.13))
	_rect_t(img, Vector2i(12, 0), 1, 2, 14, 12, Color(0.32, 0.13, 0.15))
	# (13,0) Dark Soot / Crimson Floor Stain
	_fill_tile(img, Vector2i(13, 0), Color(0.14, 0.12, 0.13) if not dist else Color(0.28, 0.05, 0.08))
	_rect_t(img, Vector2i(13, 0), 4, 5, 7, 6, Color(0.08, 0.07, 0.09) if not dist else Color(0.55, 0.06, 0.10))
	_rect_t(img, Vector2i(13, 0), 7, 3, 5, 4, Color(0.09, 0.08, 0.10) if not dist else Color(0.48, 0.05, 0.08))
	# (14,0) Yume Nikki Watching Eye Tile / Chalk Mark
	_fill_tile(img, Vector2i(14, 0), c_dark)
	var eye_white := Color(0.76, 0.77, 0.74) if dist else Color(0.28, 0.29, 0.34)
	_rect_t(img, Vector2i(14, 0), 4, 6, 8, 4, eye_white)
	_rect_t(img, Vector2i(14, 0), 6, 5, 4, 6, eye_white)
	_rect_t(img, Vector2i(14, 0), 7, 6, 2, 4, Color(0.65, 0.07, 0.11) if dist else Color(0.05, 0.05, 0.08))
	# (15,0) Abyss Shadow Spill
	_fill_tile(img, Vector2i(15, 0), Color(0.03, 0.03, 0.05))

	# Row 1: Walls (FNAF Arcade Horizontal Scan-Ribbed Walls!)
	# (0,1) Top Wall Void Cap
	_fill_tile(img, Vector2i(0, 1), void_col)
	_rect_t(img, Vector2i(0, 1), 0, 12, 16, 4, Color(0.14, 0.15, 0.20))
	# (1,1) Side Wall Void Cap
	_fill_tile(img, Vector2i(1, 1), void_col)
	_rect_t(img, Vector2i(1, 1), 6, 0, 4, 16, Color(0.14, 0.15, 0.20))
	# (2,1) Bottom Wall Rim
	_fill_tile(img, Vector2i(2, 1), void_col)
	_rect_t(img, Vector2i(2, 1), 0, 0, 16, 4, Color(0.14, 0.15, 0.20))
	# (3,1) FNAF Ribbed Wall Upper
	_fill_tile(img, Vector2i(3, 1), Color(0.17, 0.18, 0.23) if not dist else Color(0.12, 0.09, 0.13))
	for y in range(0, 16, 2):
		_rect_t(img, Vector2i(3, 1), 0, y, 16, 1, Color(0.12, 0.13, 0.17) if not dist else Color(0.07, 0.04, 0.07))
	if dist:
		_rect_t(img, Vector2i(3, 1), 5, 5, 6, 3, Color(0.82, 0.82, 0.78))
		_rect_t(img, Vector2i(3, 1), 7, 5, 2, 3, Color(0.04, 0.04, 0.06))
	# (4,1) FNAF Ribbed Wall Lower + Baseboard
	_fill_tile(img, Vector2i(4, 1), Color(0.13, 0.14, 0.18) if not dist else Color(0.09, 0.06, 0.09))
	for y in range(0, 12, 2):
		_rect_t(img, Vector2i(4, 1), 0, y, 16, 1, Color(0.09, 0.10, 0.14))
	_rect_t(img, Vector2i(4, 1), 0, 12, 16, 4, Color(0.07, 0.07, 0.10))
	# (5,1) Sawali Bamboo Upper Wall
	_blit_graded(img, house_fw, Rect2i(144, 16, 16, 16), Vector2i(5, 1), 0.32, 0.48 if not dist else 0.34, Color(0.92, 0.84, 0.72), dist)
	# (6,1) Sawali Lower Wall
	_blit_graded(img, house_fw, Rect2i(144, 48, 16, 16), Vector2i(6, 1), 0.32, 0.42 if not dist else 0.30, Color(0.88, 0.80, 0.68), dist)
	_rect_t(img, Vector2i(6, 1), 0, 13, 16, 3, Color(0.08, 0.06, 0.06))
	# (7,1) BFP Station Wall Upper w/ Red Ribbon
	_fill_tile(img, Vector2i(7, 1), Color(0.21, 0.23, 0.29) if not dist else Color(0.14, 0.10, 0.14))
	for y in range(0, 16, 2):
		_rect_t(img, Vector2i(7, 1), 0, y, 16, 1, Color(0.16, 0.18, 0.23))
	_rect_t(img, Vector2i(7, 1), 0, 11, 16, 3, Color(0.58, 0.14, 0.16) if not dist else Color(0.45, 0.04, 0.07))
	# (8,1) BFP Station Lower Wall
	_fill_tile(img, Vector2i(8, 1), Color(0.15, 0.17, 0.21))
	_rect_t(img, Vector2i(8, 1), 0, 13, 16, 3, Color(0.07, 0.08, 0.10))
	# (9,1) Infirmary Wall
	_fill_tile(img, Vector2i(9, 1), Color(0.26, 0.30, 0.36) if not dist else Color(0.18, 0.15, 0.19))
	_rect_t(img, Vector2i(9, 1), 0, 10, 16, 2, Color(0.55, 0.60, 0.65) if not dist else Color(0.48, 0.12, 0.14))
	# (10,1) Windowed Wall
	img.blit_rect(img, Rect2i(5 * 16, 16, 16, 16), Vector2i(10 * 16, 16))
	_rect_t(img, Vector2i(10, 1), 2, 2, 12, 11, Color(0.08, 0.08, 0.11))
	_rect_t(img, Vector2i(10, 1), 3, 3, 10, 9, Color(0.32, 0.44, 0.54) if not dist else Color(0.02, 0.02, 0.03))
	if dist:
		_px(img, Vector2i(10, 1), 5, 7, Color(0.9, 0.9, 0.9))
		_px(img, Vector2i(10, 1), 10, 7, Color(0.9, 0.9, 0.9))
	else:
		_rect_t(img, Vector2i(10, 1), 7, 3, 2, 9, Color(0.14, 0.12, 0.10))
		_rect_t(img, Vector2i(10, 1), 3, 7, 10, 1, Color(0.14, 0.12, 0.10))
	# (11,1) Air Vent Wall
	img.blit_rect(img, Rect2i(7 * 16, 16, 16, 16), Vector2i(11 * 16, 16))
	_rect_t(img, Vector2i(11, 1), 3, 4, 10, 8, Color(0.06, 0.07, 0.10))
	for vy in range(5, 11, 2):
		_rect_t(img, Vector2i(11, 1), 4, vy, 8, 1, Color(0.22, 0.24, 0.28))
	# (12,1) Open Lit Door Threshold (walkable)
	_fill_tile(img, Vector2i(12, 1), Color(0.38, 0.30, 0.18) if not dist else Color(0.36, 0.07, 0.10))
	_rect_t(img, Vector2i(12, 1), 0, 0, 2, 16, Color(0.12, 0.13, 0.17))
	_rect_t(img, Vector2i(12, 1), 14, 0, 2, 16, Color(0.12, 0.13, 0.17))
	# (13,1) Sealed Hazard Door
	_fill_tile(img, Vector2i(13, 1), Color(0.14, 0.10, 0.11))
	for i in range(2, 14):
		_px(img, Vector2i(13, 1), i, i, Color(0.65, 0.12, 0.14))
		_px(img, Vector2i(13, 1), 15 - i, i, Color(0.65, 0.12, 0.14))
	# (14,1) Wall Exit Sign
	img.blit_rect(img, Rect2i(7 * 16, 16, 16, 16), Vector2i(14 * 16, 16))
	_rect_t(img, Vector2i(14, 1), 3, 4, 10, 6, Color(0.68, 0.14, 0.16))
	_rect_t(img, Vector2i(14, 1), 5, 6, 6, 2, Color(0.92, 0.90, 0.84))
	# (15,1) Wall Peel / Crimson Stain
	img.blit_rect(img, Rect2i(4 * 16, 16, 16, 16), Vector2i(15 * 16, 16))
	_rect_t(img, Vector2i(15, 1), 5, 2, 4, 8, Color(0.10, 0.08, 0.09) if not dist else Color(0.55, 0.05, 0.09))

	# Row 2: Simple crisp FNAF/RPG Furniture Tiles (optional direct tile placement + we'll also add Y-sorted Node props!)
	_blit_graded(img, room_bld, Rect2i(176, 16, 16, 16), Vector2i(0, 2), 0.35, 0.72, Color(0.9, 0.9, 0.95), dist)
	# (1,2) Metal Locker
	_fill_tile(img, Vector2i(1, 2), Color(0.18, 0.21, 0.26))
	_rect_t(img, Vector2i(1, 2), 1, 1, 14, 14, Color(0.28, 0.31, 0.38))
	_rect_t(img, Vector2i(1, 2), 7, 2, 2, 12, Color(0.08, 0.09, 0.12))
	_rect_t(img, Vector2i(1, 2), 3, 4, 3, 1, Color(0.08, 0.09, 0.12))
	_rect_t(img, Vector2i(1, 2), 10, 4, 3, 1, Color(0.08, 0.09, 0.12))
	# (2,2) Filing Cabinet
	_fill_tile(img, Vector2i(2, 2), Color(0.22, 0.23, 0.27))
	_rect_t(img, Vector2i(2, 2), 2, 2, 12, 5, Color(0.32, 0.34, 0.39))
	_rect_t(img, Vector2i(2, 2), 2, 9, 12, 5, Color(0.28, 0.30, 0.35))
	_rect_t(img, Vector2i(2, 2), 6, 4, 4, 1, Color(0.75, 0.75, 0.70))
	_rect_t(img, Vector2i(2, 2), 6, 11, 4, 1, Color(0.75, 0.75, 0.70))
	# (3,2) Radio Dispatch Console
	_fill_tile(img, Vector2i(3, 2), Color(0.16, 0.18, 0.22))
	_rect_t(img, Vector2i(3, 2), 2, 2, 12, 9, Color(0.07, 0.08, 0.11))
	_rect_t(img, Vector2i(3, 2), 3, 3, 6, 5, Color(0.15, 0.35, 0.28) if not dist else Color(0.45, 0.08, 0.10))
	_px(img, Vector2i(3, 2), 11, 4, Color(0.85, 0.20, 0.20))
	_px(img, Vector2i(3, 2), 11, 7, Color(0.35, 0.75, 0.35) if not dist else Color(0.85, 0.15, 0.18))
	# (4,2) Extinguisher Rack
	_fill_tile(img, Vector2i(4, 2), Color(0.14, 0.15, 0.19))
	_rect_t(img, Vector2i(4, 2), 4, 4, 3, 9, Color(0.72, 0.16, 0.18))
	_rect_t(img, Vector2i(4, 2), 9, 4, 3, 9, Color(0.72, 0.16, 0.18))
	_rect_t(img, Vector2i(4, 2), 5, 2, 1, 2, Color(0.80, 0.72, 0.28))
	_rect_t(img, Vector2i(4, 2), 10, 2, 1, 2, Color(0.80, 0.72, 0.28))

	return img


func _build_town_atlas(serene: Image, tx_stone: Image, tx_grass: Image, dist: bool) -> Image:
	var img := Image.create_empty(256, 32, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	# Row 0: Ground & Road
	_fill_tile(img, Vector2i(0, 0), Color(0.015, 0.015, 0.025))
	# (1,0) Asphalt
	_fill_tile(img, Vector2i(1, 0), Color(0.10, 0.11, 0.14) if not dist else Color(0.06, 0.05, 0.07))
	_px(img, Vector2i(1, 0), 4, 9, Color(0.14, 0.15, 0.18))
	_px(img, Vector2i(1, 0), 11, 3, Color(0.07, 0.07, 0.10))
	# (2,0) Asphalt Yellow Center Dashed Line
	img.blit_rect(img, Rect2i(16, 0, 16, 16), Vector2i(32, 0))
	_rect_t(img, Vector2i(2, 0), 2, 7, 10, 2, Color(0.58, 0.46, 0.18) if not dist else Color(0.45, 0.09, 0.12))
	# (3,0) Crosswalk White Stripes
	img.blit_rect(img, Rect2i(16, 0, 16, 16), Vector2i(48, 0))
	_rect_t(img, Vector2i(3, 0), 3, 1, 10, 5, Color(0.55, 0.56, 0.58) if not dist else Color(0.32, 0.30, 0.34))
	_rect_t(img, Vector2i(3, 0), 3, 9, 10, 5, Color(0.55, 0.56, 0.58) if not dist else Color(0.32, 0.30, 0.34))
	# (4,0) Wet Puddle / Crack
	img.blit_rect(img, Rect2i(16, 0, 16, 16), Vector2i(64, 0))
	_rect_t(img, Vector2i(4, 0), 3, 4, 9, 6, Color(0.08, 0.15, 0.22) if not dist else Color(0.28, 0.04, 0.07))
	# (5,0) Sidewalk Concrete
	_blit_graded(img, tx_stone, Rect2i(0, 0, 16, 16), Vector2i(5, 0), 0.15, 0.48 if not dist else 0.30, Color(0.86, 0.88, 0.94), dist)
	_rect_t(img, Vector2i(5, 0), 0, 15, 16, 1, Color(0.14, 0.15, 0.19))
	_rect_t(img, Vector2i(5, 0), 15, 0, 1, 16, Color(0.14, 0.15, 0.19))
	# (6,0) Curb South Edge
	img.blit_rect(img, Rect2i(5 * 16, 0, 16, 16), Vector2i(6 * 16, 0))
	_rect_t(img, Vector2i(6, 0), 0, 12, 16, 4, Color(0.16, 0.17, 0.21))
	# (7,0) Basketball Court Floor
	_fill_tile(img, Vector2i(7, 0), Color(0.19, 0.22, 0.27) if not dist else Color(0.12, 0.10, 0.14))
	# (8,0) Court Line
	_fill_tile(img, Vector2i(8, 0), Color(0.19, 0.22, 0.27) if not dist else Color(0.12, 0.10, 0.14))
	_rect_t(img, Vector2i(8, 0), 0, 7, 16, 2, Color(0.62, 0.64, 0.66) if not dist else Color(0.55, 0.14, 0.16))
	# (9,0) Packed Dirt Road
	_blit_graded(img, serene, Rect2i(80, 16, 16, 16), Vector2i(9, 0), 0.32, 0.45 if not dist else 0.30, Color(0.95, 0.85, 0.72), dist)
	# (10,0) Muted Grass A
	_blit_graded(img, tx_grass, Rect2i(0, 0, 16, 16), Vector2i(10, 0), 0.38, 0.42 if not dist else 0.26, Color(0.78, 0.88, 0.76), dist)
	# (11,0) Muted Grass B
	_blit_graded(img, tx_grass, Rect2i(16, 32, 16, 16), Vector2i(11, 0), 0.34, 0.38 if not dist else 0.24, Color(0.75, 0.85, 0.72), dist)
	# (12,0) Coastal Sand
	_blit_graded(img, serene, Rect2i(240, 16, 16, 16), Vector2i(12, 0), 0.30, 0.48 if not dist else 0.34, Color(0.92, 0.88, 0.74), dist)
	# (13,0) Shallow Foam / Edge
	_fill_tile(img, Vector2i(13, 0), Color(0.11, 0.19, 0.25) if not dist else Color(0.16, 0.05, 0.08))
	_rect_t(img, Vector2i(13, 0), 12, 0, 4, 16, Color(0.32, 0.38, 0.42) if not dist else Color(0.45, 0.12, 0.15))
	# (14,0) Wooden Pier Planks
	_blit_graded(img, serene, Rect2i(160, 48, 16, 16), Vector2i(14, 0), 0.38, 0.52 if not dist else 0.34, Color(0.90, 0.78, 0.66), dist)
	# (15,0) Ash/Blood Road Stain Decal
	img.blit_rect(img, Rect2i(16, 0, 16, 16), Vector2i(15 * 16, 0))
	_rect_t(img, Vector2i(15, 0), 3, 4, 9, 7, Color(0.06, 0.05, 0.06) if not dist else Color(0.55, 0.06, 0.10))

	# Row 1: Solid Buildings, Roofs & Sea
	# (0,1) Deep Sea
	_fill_tile(img, Vector2i(0, 1), Color(0.05, 0.10, 0.15) if not dist else Color(0.08, 0.02, 0.04))
	# (1,1) Corrugated Roof Rust Red
	_fill_tile(img, Vector2i(1, 1), Color(0.35, 0.16, 0.16) if not dist else Color(0.28, 0.06, 0.08))
	for x in range(0, 16, 2):
		_rect_t(img, Vector2i(1, 1), x, 0, 1, 16, Color(0.22, 0.10, 0.10))
	# (2,1) Corrugated Roof Slate Grey
	_fill_tile(img, Vector2i(2, 1), Color(0.20, 0.22, 0.27))
	for x in range(0, 16, 2):
		_rect_t(img, Vector2i(2, 1), x, 0, 1, 16, Color(0.13, 0.14, 0.18))
	# (3,1) Corrugated Roof BFP Navy
	_fill_tile(img, Vector2i(3, 1), Color(0.15, 0.20, 0.30))
	for x in range(0, 16, 2):
		_rect_t(img, Vector2i(3, 1), x, 0, 1, 16, Color(0.10, 0.13, 0.21))
	# (4,1) Bahay Kubo Bamboo Facade
	_fill_tile(img, Vector2i(4, 1), Color(0.30, 0.24, 0.18) if not dist else Color(0.18, 0.14, 0.14))
	for y in range(0, 16, 2):
		_rect_t(img, Vector2i(4, 1), 0, y, 16, 1, Color(0.20, 0.15, 0.12))
	# (5,1) Concrete Town Facade
	_fill_tile(img, Vector2i(5, 1), Color(0.27, 0.29, 0.34) if not dist else Color(0.16, 0.15, 0.19))
	_rect_t(img, Vector2i(5, 1), 0, 13, 16, 3, Color(0.16, 0.17, 0.21))
	# (6,1) Town Facade Window (lit or hollow creepy black)
	img.blit_rect(img, Rect2i(5 * 16, 16, 16, 16), Vector2i(6 * 16, 16))
	_rect_t(img, Vector2i(6, 1), 3, 3, 10, 9, Color(0.06, 0.06, 0.09))
	_rect_t(img, Vector2i(6, 1), 4, 4, 8, 7, Color(0.66, 0.48, 0.20) if not dist else Color(0.02, 0.02, 0.03))
	if dist:
		_px(img, Vector2i(6, 1), 6, 7, Color(0.92, 0.92, 0.90))
		_px(img, Vector2i(6, 1), 9, 7, Color(0.92, 0.92, 0.90))
	# (7,1) BFP Station Red & Slate Wall
	_fill_tile(img, Vector2i(7, 1), Color(0.22, 0.24, 0.30) if not dist else Color(0.13, 0.10, 0.12))
	_rect_t(img, Vector2i(7, 1), 0, 5, 16, 4, Color(0.62, 0.14, 0.16) if not dist else Color(0.55, 0.05, 0.08))
	_rect_t(img, Vector2i(7, 1), 0, 13, 16, 3, Color(0.12, 0.13, 0.17))
	# (8,1) BFP Garage Shutter
	_fill_tile(img, Vector2i(8, 1), Color(0.15, 0.16, 0.20))
	for y in range(1, 16, 2):
		_rect_t(img, Vector2i(8, 1), 1, y, 14, 1, Color(0.24, 0.26, 0.31))
	# (9,1) Door Threshold (walkable!)
	_fill_tile(img, Vector2i(9, 1), Color(0.28, 0.20, 0.14) if not dist else Color(0.25, 0.05, 0.07))
	_rect_t(img, Vector2i(9, 1), 2, 1, 12, 14, Color(0.45, 0.34, 0.20) if not dist else Color(0.02, 0.02, 0.03))
	# (10,1) Sari-Sari Store Awning + Barred Grill
	_fill_tile(img, Vector2i(10, 1), Color(0.18, 0.17, 0.20))
	for x in range(0, 16, 4):
		_rect_t(img, Vector2i(10, 1), x, 0, 2, 6, Color(0.58, 0.17, 0.17) if not dist else Color(0.40, 0.06, 0.09))
		_rect_t(img, Vector2i(10, 1), x + 2, 0, 2, 6, Color(0.66, 0.62, 0.54) if not dist else Color(0.22, 0.20, 0.22))
	_rect_t(img, Vector2i(10, 1), 2, 7, 12, 7, Color(0.06, 0.06, 0.08))
	for gx in range(3, 13, 2):
		_rect_t(img, Vector2i(10, 1), gx, 7, 1, 7, Color(0.32, 0.34, 0.38))
	# (11,1) Church Stone Wall
	_blit_graded(img, tx_stone, Rect2i(16, 16, 16, 16), Vector2i(11, 1), 0.12, 0.44 if not dist else 0.28, Color(0.85, 0.85, 0.88), dist)
	# (12,1) Town Fence
	_fill_tile(img, Vector2i(12, 1), Color(0.14, 0.17, 0.14))
	_rect_t(img, Vector2i(12, 1), 0, 6, 16, 2, Color(0.34, 0.29, 0.24))
	_rect_t(img, Vector2i(12, 1), 2, 2, 3, 12, Color(0.38, 0.32, 0.26))
	_rect_t(img, Vector2i(12, 1), 11, 2, 3, 12, Color(0.38, 0.32, 0.26))
	# (13,1) Hydrant / Pole Base
	_fill_tile(img, Vector2i(13, 1), Color(0.24, 0.26, 0.30))
	_rect_t(img, Vector2i(13, 1), 5, 3, 6, 10, Color(0.62, 0.16, 0.16))
	# (14,1) Dense Foliage Hedge
	_blit_graded(img, serene, Rect2i(144, 144, 16, 16), Vector2i(14, 1), 0.42, 0.42 if not dist else 0.25, Color(0.75, 0.85, 0.72), dist)
	# (15,1) Yume Nikki Watching Wall / Glitch
	_fill_tile(img, Vector2i(15, 1), Color(0.05, 0.04, 0.06))
	_rect_t(img, Vector2i(15, 1), 3, 5, 10, 6, Color(0.84, 0.84, 0.80) if dist else Color(0.20, 0.20, 0.24))
	_rect_t(img, Vector2i(15, 1), 7, 5, 2, 6, Color(0.65, 0.06, 0.09) if dist else Color(0.04, 0.04, 0.06))

	return img


func _build_forest_atlas(tx_grass: Image, tx_stone: Image, serene: Image, dist: bool) -> Image:
	var img := Image.create_empty(256, 32, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	# Row 0: Walkable Forest Terrain
	_fill_tile(img, Vector2i(0, 0), Color(0.02, 0.03, 0.025))
	# (1,0) Mossy Grass A
	_blit_graded(img, tx_grass, Rect2i(0, 0, 16, 16), Vector2i(1, 0), 0.42, 0.36 if not dist else 0.22, Color(0.72, 0.86, 0.70), dist)
	# (2,0) Mossy Grass B Tuft
	_blit_graded(img, tx_grass, Rect2i(16, 32, 16, 16), Vector2i(2, 0), 0.42, 0.38 if not dist else 0.24, Color(0.74, 0.88, 0.72), dist)
	# (3,0) Dark Undergrowth Border
	_blit_graded(img, tx_grass, Rect2i(48, 0, 16, 16), Vector2i(3, 0), 0.35, 0.28 if not dist else 0.16, Color(0.65, 0.78, 0.65), dist)
	# (4,0) Mud / Ash Trail Center
	_blit_graded(img, serene, Rect2i(80, 16, 16, 16), Vector2i(4, 0), 0.32, 0.40 if not dist else 0.26, Color(0.88, 0.78, 0.66), dist)
	# (5,0) Trail Rough Edge
	_blit_graded(img, tx_grass, Rect2i(0, 128, 16, 16), Vector2i(5, 0), 0.32, 0.38 if not dist else 0.24, Color(0.78, 0.82, 0.74), dist)
	# (6,0) Stepping Stone Path
	_blit_graded(img, tx_grass, Rect2i(16, 144, 16, 16), Vector2i(6, 0), 0.22, 0.42 if not dist else 0.28, Color(0.82, 0.84, 0.88), dist)
	# (7,0) Scorched Ember Ash Soil (Santelmo ambush ground!)
	_fill_tile(img, Vector2i(7, 0), Color(0.08, 0.07, 0.09) if not dist else Color(0.18, 0.05, 0.07))
	_px(img, Vector2i(7, 0), 4, 6, Color(0.82, 0.34, 0.14))
	_px(img, Vector2i(7, 0), 11, 10, Color(0.75, 0.26, 0.12))
	_px(img, Vector2i(7, 0), 8, 3, Color(0.24, 0.20, 0.22))
	# (8,0) Pond Muddy Shore Bank
	_fill_tile(img, Vector2i(8, 0), Color(0.11, 0.16, 0.14) if not dist else Color(0.14, 0.08, 0.10))
	# (9,0) Pale Reeds / Distorted Eye Flower
	img.blit_rect(img, Rect2i(16, 0, 16, 16), Vector2i(9 * 16, 0))
	_rect_t(img, Vector2i(9, 0), 5, 5, 6, 5, Color(0.78, 0.78, 0.72) if dist else Color(0.32, 0.42, 0.32))
	_rect_t(img, Vector2i(9, 0), 7, 6, 2, 3, Color(0.04, 0.04, 0.05) if dist else Color(0.68, 0.78, 0.86))
	# (10,0) Log Footbridge Plank
	_fill_tile(img, Vector2i(10, 0), Color(0.27, 0.20, 0.15))
	for y in range(2, 16, 4):
		_rect_t(img, Vector2i(10, 0), 0, y, 16, 1, Color(0.14, 0.10, 0.08))
	# (11,0) Sanctuary Stone Floor
	_blit_graded(img, tx_stone, Rect2i(0, 0, 16, 16), Vector2i(11, 0), 0.18, 0.46 if not dist else 0.32, Color(0.84, 0.88, 0.94), dist)

	# Row 1: Solid Forest Barriers & Water
	# (0,1) Impassable Canopy Thicket
	_blit_graded(img, serene, Rect2i(144, 144, 16, 16), Vector2i(0, 1), 0.36, 0.24 if not dist else 0.15, Color(0.65, 0.75, 0.65), dist)
	# (1,1) Basalt Ridge Top
	_blit_graded(img, tx_stone, Rect2i(0, 0, 16, 16), Vector2i(1, 1), 0.15, 0.36 if not dist else 0.24, Color(0.80, 0.82, 0.90), dist)
	# (2,1) Basalt Cliff Crag Wall
	_fill_tile(img, Vector2i(2, 1), Color(0.11, 0.12, 0.15))
	_rect_t(img, Vector2i(2, 1), 2, 2, 5, 12, Color(0.17, 0.18, 0.22))
	_rect_t(img, Vector2i(2, 1), 9, 1, 5, 14, Color(0.15, 0.16, 0.20))
	# (3,1) Deep Pond Water
	_fill_tile(img, Vector2i(3, 1), Color(0.05, 0.12, 0.17) if not dist else Color(0.10, 0.03, 0.06))
	_rect_t(img, Vector2i(3, 1), 3, 6, 5, 1, Color(0.14, 0.26, 0.34) if not dist else Color(0.32, 0.08, 0.12))
	# (4,1) Shallow Pond Edge
	_fill_tile(img, Vector2i(4, 1), Color(0.09, 0.18, 0.24) if not dist else Color(0.16, 0.05, 0.09))
	# (5,1) Boulder / Stump Obstacle
	_fill_tile(img, Vector2i(5, 1), Color(0.10, 0.14, 0.10))
	_rect_t(img, Vector2i(5, 1), 2, 3, 12, 10, Color(0.24, 0.25, 0.29))
	_rect_t(img, Vector2i(5, 1), 4, 4, 8, 6, Color(0.32, 0.34, 0.39))
	# (6,1) Charred Trunk Obstacle
	_fill_tile(img, Vector2i(6, 1), Color(0.09, 0.12, 0.09))
	_rect_t(img, Vector2i(6, 1), 4, 0, 8, 16, Color(0.14, 0.10, 0.10))
	if dist:
		_rect_t(img, Vector2i(6, 1), 6, 6, 4, 5, Color(0.75, 0.12, 0.15))
	# (7,1) Wood Roadblock
	_fill_tile(img, Vector2i(7, 1), Color(0.22, 0.16, 0.12))
	_rect_t(img, Vector2i(7, 1), 0, 3, 16, 4, Color(0.45, 0.24, 0.16))
	_rect_t(img, Vector2i(7, 1), 0, 10, 16, 4, Color(0.45, 0.24, 0.16))

	return img


func _save_preview_sheet(in_n: Image, in_d: Image, tw_n: Image, tw_d: Image, fr_n: Image, fr_d: Image) -> void:
	var prev := Image.create_empty(512, 192, false, Image.FORMAT_RGBA8)
	prev.fill(Color(0.08, 0.08, 0.10, 1.0))
	prev.blend_rect(in_n, Rect2i(0, 0, 256, 64), Vector2i(0, 0))
	prev.blend_rect(in_d, Rect2i(0, 0, 256, 64), Vector2i(256, 0))
	prev.blend_rect(tw_n, Rect2i(0, 0, 256, 32), Vector2i(0, 80))
	prev.blend_rect(tw_d, Rect2i(0, 0, 256, 32), Vector2i(256, 80))
	prev.blend_rect(fr_n, Rect2i(0, 0, 256, 32), Vector2i(0, 128))
	prev.blend_rect(fr_d, Rect2i(0, 0, 256, 32), Vector2i(256, 128))
	prev.resize(1024, 384, Image.INTERPOLATE_NEAREST)
	var out_dir := ProjectSettings.globalize_path("res://docs/logs")
	DirAccess.make_dir_recursive_absolute(out_dir)
	prev.save_png(out_dir.path_join("retro_tilesets_preview.png"))
