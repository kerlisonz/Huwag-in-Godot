@tool
extends Node
class_name ForestAssetGenerator

# Gera e garante todos os assets procedurais da nova floresta e clareira
static func ensure_all_assets() -> void:
	_ensure_dir("res://assets/enemies/")
	_ensure_dir("res://assets/environments/")
	_ensure_dir("res://assets/props/")
	_ensure_dir("res://assets/tilesets/")
	_ensure_dir("res://assets/characters/")

	if not FileAccess.file_exists("res://assets/enemies/santelmo.png"):
		var tex_s := generate_santelmo_texture()
		tex_s.get_image().save_png("res://assets/enemies/santelmo.png")

	if not FileAccess.file_exists("res://assets/environments/pond_organic.png"):
		var tex_p := generate_pond_texture()
		tex_p.get_image().save_png("res://assets/environments/pond_organic.png")

	if not FileAccess.file_exists("res://assets/props/blue_egg_nest.png"):
		var tex_n := generate_nest_texture()
		tex_n.get_image().save_png("res://assets/props/blue_egg_nest.png")

	ensure_tileset()

static func _ensure_dir(path: String) -> void:
	if not DirAccess.dir_exists_absolute(path):
		DirAccess.make_dir_recursive_absolute(path)

# Cria o sprite pixel art do Santelmo (24x24 / 32x32)
static func generate_santelmo_texture() -> ImageTexture:
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	var c_core := Color(1.0, 0.98, 0.82, 1.0)
	var c_flame := Color(0.98, 0.62, 0.14, 1.0)
	var c_mid := Color(0.92, 0.35, 0.08, 0.95)
	var c_outer := Color(0.78, 0.12, 0.06, 0.8)

	for y in range(32):
		for x in range(32):
			var dx := float(x - 16)
			var dy := float(y - 18)
			var r_eff := sqrt(dx * dx + dy * dy)
			if dy < 0.0:
				var taper := 1.0 + (-dy / 10.0) * 0.4
				r_eff = sqrt((dx * taper) * (dx * taper) + dy * dy)
			var tip := sin(dx * 0.8 + dy * 0.5) * 1.4
			r_eff += tip

			if r_eff < 4.5:
				img.set_pixel(x, y, c_core)
			elif r_eff < 8.0:
				img.set_pixel(x, y, c_flame)
			elif r_eff < 11.5:
				img.set_pixel(x, y, c_mid)
			elif r_eff < 14.5:
				img.set_pixel(x, y, c_outer)
			else:
				img.set_pixel(x, y, Color(0, 0, 0, 0))

	# Faíscas ascendentes
	img.set_pixel(15, 3, Color(1, 0.95, 0.6, 0.9))
	img.set_pixel(16, 4, Color(1, 0.95, 0.6, 0.9))
	img.set_pixel(12, 6, Color(1, 0.8, 0.3, 0.8))
	img.set_pixel(19, 7, Color(1, 0.8, 0.3, 0.8))

	return ImageTexture.create_from_image(img)

# Cria a textura da lagoa orgânica com água translúcida e margem natural
static func generate_pond_texture() -> ImageTexture:
	var img := Image.create(256, 200, false, Image.FORMAT_RGBA8)
	var center_x := 128.0
	var center_y := 100.0
	var rx := 98.0
	var ry := 74.0

	for y in range(200):
		for x in range(256):
			var dx := (float(x) - center_x) / rx
			var dy := (float(y) - center_y) / ry
			var angle := atan2(dy, dx)
			var wobble := 0.08 * sin(3.0 * angle) + 0.05 * cos(5.0 * angle) + 0.03 * sin(7.0 * angle)
			var dist := sqrt(dx * dx + dy * dy) + wobble

			if dist > 1.14:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
			elif dist > 1.05:
				var t := (dist - 1.05) / 0.09
				img.set_pixel(x, y, Color(0.24, 0.18, 0.12, 0.86 * (1.0 - t * 0.7)))
			elif dist > 0.98:
				img.set_pixel(x, y, Color(0.18, 0.36, 0.21, 0.94))
			elif dist > 0.88:
				img.set_pixel(x, y, Color(0.28, 0.75, 0.78, 0.90))
			elif dist > 0.65:
				img.set_pixel(x, y, Color(0.12, 0.55, 0.76, 0.94))
			elif dist > 0.35:
				img.set_pixel(x, y, Color(0.06, 0.31, 0.63, 0.98))
			else:
				img.set_pixel(x, y, Color(0.03, 0.18, 0.47, 1.0))

	return ImageTexture.create_from_image(img)

# Cria a textura do ninho com ovos azuis
static func generate_nest_texture() -> ImageTexture:
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	for y in range(32):
		for x in range(32):
			var dx := (float(x) - 16.0) / 13.0
			var dy := (float(y) - 18.0) / 9.0
			var d := sqrt(dx * dx + dy * dy)
			if d <= 1.0:
				if d > 0.75:
					var c := (x * 3 + y * 7) % 5
					if c == 0:
						img.set_pixel(x, y, Color(0.36, 0.25, 0.16, 1.0))
					elif c == 1:
						img.set_pixel(x, y, Color(0.51, 0.35, 0.20, 1.0))
					else:
						img.set_pixel(x, y, Color(0.27, 0.19, 0.11, 1.0))
				else:
					img.set_pixel(x, y, Color(0.18, 0.37, 0.20, 1.0))
			else:
				img.set_pixel(x, y, Color(0, 0, 0, 0))

	# Ovos azuis
	_draw_pixel_egg(img, 12, 17, 4, 6)
	_draw_pixel_egg(img, 20, 17, 4, 6)
	_draw_pixel_egg(img, 16, 13, 4, 6)

	return ImageTexture.create_from_image(img)

static func _draw_pixel_egg(img: Image, ex: int, ey: int, w: int, h: int) -> void:
	for y in range(ey - h, ey + h + 1):
		for x in range(ex - w, ex + w + 1):
			var dx := float(x - ex) / float(w)
			var y_shift := float(y - ey) / float(h)
			var narrow := 1.0 - y_shift * 0.22 if y_shift < 0.0 else 1.0
			var edist := sqrt((dx * narrow) * (dx * narrow) + y_shift * y_shift)
			if edist <= 1.0:
				if x >= 0 and x < 32 and y >= 0 and y < 32:
					if edist < 0.35 and dx < 0.0 and y_shift < 0.0:
						img.set_pixel(x, y, Color(0.86, 0.97, 1.0, 1.0))
					elif edist < 0.65:
						img.set_pixel(x, y, Color(0.43, 0.84, 0.96, 1.0))
					elif edist < 0.9:
						img.set_pixel(x, y, Color(0.12, 0.59, 0.84, 1.0))
					else:
						img.set_pixel(x, y, Color(0.04, 0.33, 0.57, 1.0))

# Cria o tileset natural da floresta
static func ensure_tileset() -> TileSet:
	var path := "res://assets/tilesets/forest_natural_tileset.tres"
	if ResourceLoader.exists(path):
		return load(path) as TileSet

	var tileset := TileSet.new()
	tileset.tile_size = Vector2i(16, 16)

	var grass_path := "res://assets/third_party/Pixel Art Top Down - Basic v1.2.3/Texture/TX Tileset Grass.png"
	if ResourceLoader.exists(grass_path):
		var tex := load(grass_path) as Texture2D
		if tex:
			var source := TileSetAtlasSource.new()
			source.texture = tex
			source.texture_region_size = Vector2i(16, 16)
			# Cria células atlas essenciais (16x16)
			var img := tex.get_image()
			if img:
				var max_x := mini(img.get_width() / 16, 16)
				var max_y := mini(img.get_height() / 16, 16)
				for ty in range(max_y):
					for tx in range(max_x):
						source.create_tile(Vector2i(tx, ty))
			tileset.add_source(source, 0)

	ResourceSaver.save(tileset, path)
	return tileset
