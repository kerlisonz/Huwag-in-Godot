class_name RetroLevelHelpers
extends RefCounted

## Helpers visuais retrô (FNAF Minigames + Yume Nikki + Chrono Trigger + Pokémon GB)
## Gera sprites Y-sorted pixel-sharp em cache, luzes PointLight2D sem texturas nulas,
## decals ambientais e helpers de construção para TileMapLayer duplo (Normal vs Distorcido).

static var _tex_cache: Dictionary = {}
static var _light_tex_cache: Dictionary = {}


static func get_radial_light_texture(diameter: int = 128) -> ImageTexture:
	if _light_tex_cache.has(diameter):
		return _light_tex_cache[diameter]
	var img := Image.create_empty(diameter, diameter, false, Image.FORMAT_RGBA8)
	var center := Vector2(diameter * 0.5, diameter * 0.5)
	var radius := diameter * 0.5
	for y in range(diameter):
		for x in range(diameter):
			var d := Vector2(x + 0.5, y + 0.5).distance_to(center) / radius
			var a := clampf(1.0 - d, 0.0, 1.0)
			a = pow(a, 1.85)
			img.set_pixel(x, y, Color(1.0, 1.0, 1.0, a))
	var tex := ImageTexture.create_from_image(img)
	_light_tex_cache[diameter] = tex
	return tex


static func create_point_light(pos: Vector2, color: Color, energy: float = 0.85, texture_scale: float = 1.6, diameter: int = 128) -> PointLight2D:
	var light := PointLight2D.new()
	light.position = pos
	light.texture = get_radial_light_texture(diameter)
	light.color = color
	light.energy = energy
	light.texture_scale = texture_scale
	light.blend_mode = Light2D.BLEND_MODE_ADD
	return light


static func paint_rect(layer: TileMapLayer, x0: int, y0: int, w: int, h: int, atlas_coord: Vector2i) -> void:
	for y in range(y0, y0 + h):
		for x in range(x0, x0 + w):
			layer.set_cell(Vector2i(x, y), 0, atlas_coord)


static func paint_border(layer: TileMapLayer, x0: int, y0: int, w: int, h: int, top_coord: Vector2i, side_coord: Vector2i, bottom_coord: Vector2i) -> void:
	for x in range(x0, x0 + w):
		layer.set_cell(Vector2i(x, y0), 0, top_coord)
		layer.set_cell(Vector2i(x, y0 + h - 1), 0, bottom_coord)
	for y in range(y0 + 1, y0 + h - 1):
		layer.set_cell(Vector2i(x0, y), 0, side_coord)
		layer.set_cell(Vector2i(x0 + w - 1, y), 0, side_coord)


static func create_prop_sprite(kind: String, distorted: bool = false) -> Sprite2D:
	var spr := Sprite2D.new()
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	spr.texture = get_prop_texture(kind, distorted)
	return spr


static func get_prop_texture(kind: String, distorted: bool = false) -> ImageTexture:
	var key := "%s_%s" % [kind, "dist" if distorted else "norm"]
	if _tex_cache.has(key):
		return _tex_cache[key]

	var img := _build_prop_image(kind, distorted)
	var tex := ImageTexture.create_from_image(img)
	_tex_cache[key] = tex
	return tex


static func _px_rect(img: Image, x0: int, y0: int, w: int, h: int, col: Color) -> void:
	var iw := img.get_width()
	var ih := img.get_height()
	for y in range(maxi(0, y0), mini(ih, y0 + h)):
		for x in range(maxi(0, x0), mini(iw, x0 + w)):
			img.set_pixel(x, y, col)


static func _outline_rect(img: Image, x0: int, y0: int, w: int, h: int, fill: Color, border: Color) -> void:
	_px_rect(img, x0, y0, w, h, border)
	if w > 2 and h > 2:
		_px_rect(img, x0 + 1, y0 + 1, w - 2, h - 2, fill)


static func _build_prop_image(kind: String, dist: bool) -> Image:
	var ink := Color(0.05, 0.05, 0.08, 1.0)
	var wood_dark := Color(0.18, 0.13, 0.10, 1.0) if not dist else Color(0.11, 0.07, 0.09, 1.0)
	var wood_mid := Color(0.32, 0.23, 0.16, 1.0) if not dist else Color(0.19, 0.11, 0.13, 1.0)
	var steel := Color(0.28, 0.31, 0.37, 1.0) if not dist else Color(0.16, 0.15, 0.20, 1.0)
	var red_bfp := Color(0.68, 0.14, 0.16, 1.0) if not dist else Color(0.56, 0.05, 0.09, 1.0)
	var eye_glow := Color(0.92, 0.92, 0.88, 1.0)

	match kind:
		"bed_huwag":
			var img := Image.create_empty(32, 48, false, Image.FORMAT_RGBA8)
			img.fill(Color(0, 0, 0, 0))
			_outline_rect(img, 2, 2, 28, 44, wood_dark, ink)
			_outline_rect(img, 4, 4, 24, 10, Color(0.56, 0.56, 0.58) if not dist else Color(0.34, 0.30, 0.32), ink)
			_outline_rect(img, 4, 14, 24, 28, Color(0.18, 0.25, 0.34) if not dist else Color(0.22, 0.06, 0.09), ink)
			# FNAF-style stitched fold + crimson pill-stain in distorted
			_px_rect(img, 4, 14, 24, 3, Color(0.72, 0.72, 0.70) if not dist else Color(0.42, 0.09, 0.12))
			if dist:
				_px_rect(img, 10, 22, 12, 8, Color(0.45, 0.04, 0.07))
				_px_rect(img, 12, 7, 3, 2, ink)
				_px_rect(img, 17, 7, 3, 2, ink)
			return img

		"pill_table":
			var img := Image.create_empty(36, 26, false, Image.FORMAT_RGBA8)
			img.fill(Color(0, 0, 0, 0))
			_outline_rect(img, 2, 4, 32, 18, wood_mid, ink)
			_px_rect(img, 3, 22, 4, 4, wood_dark)
			_px_rect(img, 29, 22, 4, 4, wood_dark)
			# Orange amber medicine bottles + pill blister + brass lamp
			_outline_rect(img, 7, 5, 5, 7, Color(0.84, 0.45, 0.14) if not dist else Color(0.78, 0.10, 0.14), ink)
			_px_rect(img, 8, 4, 3, 2, Color(0.86, 0.86, 0.84))
			_outline_rect(img, 14, 7, 5, 6, Color(0.84, 0.45, 0.14) if not dist else Color(0.78, 0.10, 0.14), ink)
			_px_rect(img, 15, 6, 3, 2, Color(0.86, 0.86, 0.84))
			if dist:
				_px_rect(img, 11, 13, 2, 2, Color(0.92, 0.90, 0.86))
				_px_rect(img, 19, 15, 2, 2, Color(0.92, 0.90, 0.86))
				_px_rect(img, 25, 11, 6, 6, Color(0.50, 0.05, 0.08))
			# Desk lamp
			_outline_rect(img, 24, 3, 8, 6, Color(0.78, 0.65, 0.28) if not dist else Color(0.45, 0.12, 0.14), ink)
			_px_rect(img, 27, 9, 2, 4, steel)
			return img

		"locker_uniform":
			var img := Image.create_empty(24, 38, false, Image.FORMAT_RGBA8)
			img.fill(Color(0, 0, 0, 0))
			_outline_rect(img, 2, 2, 20, 34, steel, ink)
			_px_rect(img, 11, 4, 2, 30, ink)
			_px_rect(img, 5, 6, 4, 1, ink)
			_px_rect(img, 15, 6, 4, 1, ink)
			# Hanging BFP orange/red turnout stripe peek or blood leak in dist
			_px_rect(img, 5, 16, 4, 10, Color(0.68, 0.22, 0.16) if not dist else Color(0.46, 0.04, 0.07))
			_px_rect(img, 5, 22, 4, 2, Color(0.86, 0.72, 0.22) if not dist else Color(0.20, 0.20, 0.24))
			return img

		"radio_clock":
			var img := Image.create_empty(24, 24, false, Image.FORMAT_RGBA8)
			img.fill(Color(0, 0, 0, 0))
			_outline_rect(img, 2, 6, 20, 14, Color(0.14, 0.15, 0.19), ink)
			_px_rect(img, 4, 8, 10, 6, Color(0.18, 0.36, 0.28) if not dist else Color(0.55, 0.06, 0.09))
			_px_rect(img, 17, 2, 1, 5, Color(0.60, 0.64, 0.70))
			_px_rect(img, 16, 9, 3, 2, Color(0.85, 0.24, 0.20))
			if dist:
				_px_rect(img, 6, 10, 2, 2, eye_glow)
				_px_rect(img, 10, 10, 2, 2, eye_glow)
			return img

		"pusa_cat":
			var img := Image.create_empty(20, 18, false, Image.FORMAT_RGBA8)
			img.fill(Color(0, 0, 0, 0))
			var fur := Color(0.24, 0.24, 0.28) if not dist else Color(0.04, 0.04, 0.06)
			_outline_rect(img, 4, 7, 11, 7, fur, ink)
			_outline_rect(img, 4, 3, 7, 6, fur, ink)
			_px_rect(img, 4, 2, 2, 2, fur)
			_px_rect(img, 9, 2, 2, 2, fur)
			_px_rect(img, 5, 5, 1, 1, Color(0.86, 0.80, 0.36) if not dist else Color(0.95, 0.95, 0.95))
			_px_rect(img, 9, 5, 1, 1, Color(0.86, 0.80, 0.36) if not dist else Color(0.95, 0.95, 0.95))
			_px_rect(img, 14, 9, 4, 2, fur)
			return img

		"banig_mat":
			var img := Image.create_empty(48, 32, false, Image.FORMAT_RGBA8)
			img.fill(Color(0, 0, 0, 0))
			_outline_rect(img, 1, 1, 46, 30, Color(0.42, 0.36, 0.26) if not dist else Color(0.20, 0.14, 0.16), ink)
			for y in range(4, 28, 4):
				for x in range(4, 44, 4):
					if ((x + y) / 4) % 2 == 0:
						_px_rect(img, x, y, 2, 2, Color(0.55, 0.26, 0.22) if not dist else Color(0.48, 0.05, 0.09))
			if dist:
				# Yume Nikki watching pupil woven right into the sleeping mat
				_px_rect(img, 18, 12, 12, 8, Color(0.84, 0.82, 0.78))
				_px_rect(img, 22, 13, 4, 6, ink)
			return img

		"shoe_rack":
			var img := Image.create_empty(24, 16, false, Image.FORMAT_RGBA8)
			img.fill(Color(0, 0, 0, 0))
			_outline_rect(img, 2, 4, 8, 9, Color(0.12, 0.12, 0.14), ink)
			_outline_rect(img, 13, 4, 8, 9, Color(0.12, 0.12, 0.14), ink)
			_px_rect(img, 4, 10, 4, 2, Color(0.65, 0.65, 0.68))
			_px_rect(img, 15, 10, 4, 2, Color(0.65, 0.65, 0.68))
			return img

		"yume_eye_rune":
			var img := Image.create_empty(24, 16, false, Image.FORMAT_RGBA8)
			img.fill(Color(0, 0, 0, 0))
			_px_rect(img, 5, 5, 14, 6, Color(0.85, 0.84, 0.80))
			_px_rect(img, 8, 3, 8, 10, Color(0.85, 0.84, 0.80))
			_px_rect(img, 10, 4, 4, 8, Color(0.58, 0.06, 0.10))
			_px_rect(img, 11, 6, 2, 4, ink)
			return img

		"floor_stain":
			var img := Image.create_empty(32, 24, false, Image.FORMAT_RGBA8)
			img.fill(Color(0, 0, 0, 0))
			var col := Color(0.08, 0.07, 0.08, 0.75) if not dist else Color(0.46, 0.04, 0.08, 0.88)
			_px_rect(img, 6, 6, 16, 10, col)
			_px_rect(img, 14, 3, 12, 8, col)
			_px_rect(img, 3, 12, 9, 6, col)
			return img

		"bfp_firetruck":
			var img := Image.create_empty(96, 48, false, Image.FORMAT_RGBA8)
			img.fill(Color(0, 0, 0, 0))
			# Shadow
			_px_rect(img, 4, 38, 88, 7, Color(0.01, 0.01, 0.02, 0.65))
			# Wheels
			_outline_rect(img, 14, 34, 12, 10, Color(0.08, 0.08, 0.10), ink)
			_outline_rect(img, 70, 34, 12, 10, Color(0.08, 0.08, 0.10), ink)
			# Body + cab (FNAF boxy arcade silhouette)
			_outline_rect(img, 6, 14, 58, 23, red_bfp, ink)
			_outline_rect(img, 64, 17, 26, 20, red_bfp, ink)
			# Windshield
			_outline_rect(img, 72, 20, 14, 9, Color(0.18, 0.28, 0.38) if not dist else Color(0.03, 0.03, 0.04), ink)
			if dist:
				_px_rect(img, 76, 23, 2, 2, eye_glow)
				_px_rect(img, 81, 23, 2, 2, eye_glow)
			# Pump panel & reflective yellow BFP stripe
			_px_rect(img, 8, 25, 54, 3, Color(0.84, 0.72, 0.24) if not dist else Color(0.32, 0.04, 0.07))
			_outline_rect(img, 20, 20, 14, 12, steel, ink)
			# Roof ladder & emergency lightbar
			_outline_rect(img, 10, 9, 44, 5, Color(0.62, 0.65, 0.70), ink)
			_outline_rect(img, 71, 13, 8, 4, Color(0.90, 0.20, 0.22), ink)
			return img

		"jeepney_parked":
			var img := Image.create_empty(80, 40, false, Image.FORMAT_RGBA8)
			img.fill(Color(0, 0, 0, 0))
			_px_rect(img, 4, 31, 72, 6, Color(0.01, 0.01, 0.02, 0.60))
			_outline_rect(img, 10, 27, 10, 9, Color(0.09, 0.09, 0.11), ink)
			_outline_rect(img, 60, 27, 10, 9, Color(0.09, 0.09, 0.11), ink)
			var body := Color(0.24, 0.34, 0.44) if not dist else Color(0.18, 0.10, 0.14)
			_outline_rect(img, 6, 10, 68, 20, body, ink)
			_px_rect(img, 8, 12, 42, 7, Color(0.12, 0.14, 0.18))
			_px_rect(img, 54, 13, 14, 8, Color(0.20, 0.30, 0.40) if not dist else Color(0.03, 0.03, 0.04))
			_px_rect(img, 8, 22, 64, 3, Color(0.84, 0.70, 0.25) if not dist else Color(0.55, 0.06, 0.10))
			return img

		"streetlamp_pole":
			var img := Image.create_empty(16, 48, false, Image.FORMAT_RGBA8)
			img.fill(Color(0, 0, 0, 0))
			_px_rect(img, 6, 42, 4, 5, steel)
			_px_rect(img, 7, 10, 2, 34, steel)
			_px_rect(img, 4, 8, 8, 3, Color(0.20, 0.22, 0.26))
			_px_rect(img, 5, 11, 6, 4, Color(0.95, 0.82, 0.44) if not dist else Color(0.75, 0.12, 0.18))
			return img

		"barangay_arch":
			var img := Image.create_empty(64, 48, false, Image.FORMAT_RGBA8)
			img.fill(Color(0, 0, 0, 0))
			_outline_rect(img, 2, 10, 8, 36, steel, ink)
			_outline_rect(img, 54, 10, 8, 36, steel, ink)
			_outline_rect(img, 2, 2, 60, 12, Color(0.18, 0.24, 0.32) if not dist else Color(0.24, 0.05, 0.09), ink)
			_px_rect(img, 8, 5, 48, 5, Color(0.84, 0.78, 0.56) if not dist else Color(0.68, 0.12, 0.15))
			return img

		"bfp_desk":
			var img := Image.create_empty(48, 24, false, Image.FORMAT_RGBA8)
			img.fill(Color(0, 0, 0, 0))
			_outline_rect(img, 2, 4, 44, 16, wood_mid, ink)
			_outline_rect(img, 8, 6, 12, 8, steel, ink) # monitor
			_px_rect(img, 10, 7, 8, 5, Color(0.22, 0.45, 0.35) if not dist else Color(0.55, 0.08, 0.10))
			_outline_rect(img, 28, 8, 10, 6, Color(0.80, 0.80, 0.76), ink) # logbook
			return img

		"medical_bed":
			var img := Image.create_empty(32, 44, false, Image.FORMAT_RGBA8)
			img.fill(Color(0, 0, 0, 0))
			_outline_rect(img, 2, 2, 28, 40, steel, ink)
			_outline_rect(img, 4, 4, 24, 36, Color(0.76, 0.80, 0.84) if not dist else Color(0.38, 0.34, 0.38), ink)
			_px_rect(img, 6, 5, 20, 7, Color(0.88, 0.90, 0.92))
			_px_rect(img, 6, 18, 20, 18, Color(0.28, 0.46, 0.54) if not dist else Color(0.48, 0.06, 0.09))
			return img

		"basketball_hoop":
			var img := Image.create_empty(24, 48, false, Image.FORMAT_RGBA8)
			img.fill(Color(0, 0, 0, 0))
			_px_rect(img, 10, 14, 4, 32, steel)
			_outline_rect(img, 4, 2, 16, 12, Color(0.72, 0.74, 0.76) if not dist else Color(0.25, 0.22, 0.26), ink)
			_px_rect(img, 9, 10, 6, 2, Color(0.78, 0.24, 0.18))
			return img

		"pine_canopy_cluster":
			var img := Image.create_empty(48, 64, false, Image.FORMAT_RGBA8)
			img.fill(Color(0, 0, 0, 0))
			var leaf_dark := Color(0.06, 0.11, 0.08) if not dist else Color(0.08, 0.04, 0.07)
			var leaf_mid := Color(0.11, 0.19, 0.13) if not dist else Color(0.16, 0.06, 0.10)
			_px_rect(img, 19, 44, 10, 18, wood_dark)
			_outline_rect(img, 8, 26, 32, 22, leaf_dark, ink)
			_outline_rect(img, 12, 14, 24, 18, leaf_mid, ink)
			_outline_rect(img, 16, 4, 16, 14, leaf_mid, ink)
			if dist:
				_px_rect(img, 20, 22, 2, 2, eye_glow)
				_px_rect(img, 26, 22, 2, 2, eye_glow)
			return img

		"dead_gnarled_tree":
			var img := Image.create_empty(36, 52, false, Image.FORMAT_RGBA8)
			img.fill(Color(0, 0, 0, 0))
			var bark := Color(0.13, 0.11, 0.12) if not dist else Color(0.16, 0.05, 0.07)
			_outline_rect(img, 14, 20, 8, 30, bark, ink)
			_outline_rect(img, 4, 12, 12, 5, bark, ink)
			_outline_rect(img, 20, 8, 12, 5, bark, ink)
			_outline_rect(img, 10, 4, 6, 12, bark, ink)
			if dist:
				_px_rect(img, 16, 28, 4, 6, Color(0.68, 0.08, 0.12))
			return img

		"calm_drop_pickup":
			var img := Image.create_empty(20, 24, false, Image.FORMAT_RGBA8)
			img.fill(Color(0, 0, 0, 0))
			_outline_rect(img, 5, 4, 10, 14, Color(0.28, 0.68, 0.84), ink)
			_px_rect(img, 8, 2, 4, 3, Color(0.86, 0.86, 0.84))
			_px_rect(img, 7, 9, 6, 6, Color(0.62, 0.90, 0.96))
			return img

		"wooden_signpost":
			var img := Image.create_empty(24, 28, false, Image.FORMAT_RGBA8)
			img.fill(Color(0, 0, 0, 0))
			_px_rect(img, 10, 14, 4, 12, wood_dark)
			_outline_rect(img, 2, 4, 20, 11, wood_mid, ink)
			_px_rect(img, 5, 7, 14, 2, Color(0.76, 0.72, 0.62) if not dist else Color(0.70, 0.12, 0.15))
			_px_rect(img, 5, 11, 10, 2, Color(0.76, 0.72, 0.62) if not dist else Color(0.70, 0.12, 0.15))
			return img

		_:
			var fallback := Image.create_empty(16, 16, false, Image.FORMAT_RGBA8)
			fallback.fill(Color(0.20, 0.22, 0.26, 1.0))
			return fallback
