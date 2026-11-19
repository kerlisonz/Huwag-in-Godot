class_name RetroLevelHelpers
extends RefCounted

## Helpers visuais retrô (FNAF Minigames + Yume Nikki + Chrono Trigger + Pokémon GB)
## Gera sprites Y-sorted pixel-sharp em cache, luzes PointLight2D sem texturas nulas,
## decals ambientais e helpers de construção para TileMapLayer duplo (Normal vs Distorcido).

const WIND_SWAY_SHADER: Shader = preload("res://shaders/wind_sway.gdshader")
const WATCHING_EYE_SCRIPT := preload("res://scripts/components/watching_eye.gd")

static var _tex_cache: Dictionary = {}
static var _light_tex_cache: Dictionary = {}


static func is_act3_unfiltered() -> bool:
	if Engine.is_editor_hint():
		return false
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return false
	var gs := tree.root.get_node_or_null("GameState")
	return gs != null and gs.has_method("is_unfiltered_act3") and bool(gs.call("is_unfiltered_act3"))


static func cleanup_editor_preview(host: Node) -> void:
	if host == null or not is_instance_valid(host):
		return
	var stack: Array[Node] = [host]
	while not stack.is_empty():
		var curr: Node = stack.pop_back()
		for ch in curr.get_children():
			if ch.has_meta("_editor_preview"):
				curr.remove_child(ch)
				ch.free()
			else:
				stack.append(ch)


static func create_preview_tilemap(parent: Node, layer_name: String, z_idx: int) -> TileMapLayer:
	var layer := TileMapLayer.new()
	layer.name = layer_name
	layer.z_index = z_idx
	layer.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	layer.collision_enabled = false
	layer.set_meta("_editor_preview", true)
	parent.add_child(layer)
	return layer


static func mark_unowned_preview_children(containers: Array[Node]) -> void:
	for container in containers:
		if container == null or not is_instance_valid(container):
			continue
		for ch in container.get_children():
			if ch.owner == null:
				ch.set_meta("_editor_preview", true)


static func add_npc_editor_preview(parent: Node, node_name: String, frames_path: String, pos: Vector2, dir: String = "down") -> void:
	if parent == null or not is_instance_valid(parent):
		return
	var sf := load(frames_path) as SpriteFrames
	if sf == null:
		return
	var anim := AnimatedSprite2D.new()
	anim.name = node_name
	anim.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	anim.sprite_frames = sf
	var anim_name := "idle_" + dir
	if sf.has_animation(anim_name):
		anim.animation = anim_name
	anim.position = pos
	anim.offset = Vector2(0, -7)
	anim.set_meta("_editor_preview", true)
	parent.add_child(anim)


static func apply_wind_sway(spr: CanvasItem, phase: float = 0.0, strength: float = 1.5, speed: float = 1.8, jitter: float = 0.0, vertical_anchor: float = 0.82) -> void:
	if spr == null:
		return
	var mat := ShaderMaterial.new()
	mat.shader = WIND_SWAY_SHADER
	mat.set_shader_parameter("phase_offset", fmod(absf(phase), TAU))
	mat.set_shader_parameter("wind_strength", strength)
	mat.set_shader_parameter("wind_speed", speed)
	mat.set_shader_parameter("distortion_jitter", jitter)
	mat.set_shader_parameter("vertical_anchor", vertical_anchor)
	spr.material = mat


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
	if kind == "yume_eye_rune":
		return WATCHING_EYE_SCRIPT.new() as Sprite2D
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
	var wood_dark := Color(0.18, 0.13, 0.10, 1.0) if not dist else Color(0.10, 0.09, 0.16, 1.0)
	var wood_mid := Color(0.32, 0.23, 0.16, 1.0) if not dist else Color(0.16, 0.15, 0.24, 1.0)
	var steel := Color(0.28, 0.31, 0.37, 1.0) if not dist else Color(0.16, 0.15, 0.24, 1.0)
	var red_bfp := Color(0.68, 0.14, 0.16, 1.0) if not dist else Color(0.28, 0.22, 0.42, 1.0)
	var eye_glow := Color(0.92, 0.92, 0.88, 1.0) if not dist else Color(0.84, 0.82, 0.98, 1.0)

	match kind:
		"bed_huwag":
			var img := Image.create_empty(32, 48, false, Image.FORMAT_RGBA8)
			img.fill(Color(0, 0, 0, 0))
			_outline_rect(img, 2, 2, 28, 44, wood_dark, ink)
			_outline_rect(img, 4, 4, 24, 10, Color(0.56, 0.56, 0.58) if not dist else Color(0.28, 0.27, 0.36), ink)
			_outline_rect(img, 4, 14, 24, 28, Color(0.18, 0.25, 0.34) if not dist else Color(0.11, 0.10, 0.19), ink)
			_px_rect(img, 4, 14, 24, 3, Color(0.72, 0.72, 0.70) if not dist else Color(0.26, 0.24, 0.38))
			if dist:
				_px_rect(img, 10, 22, 12, 8, Color(0.06, 0.05, 0.11))
				_px_rect(img, 12, 7, 3, 2, ink)
				_px_rect(img, 17, 7, 3, 2, ink)
			return img

		"pill_table":
			var img := Image.create_empty(36, 26, false, Image.FORMAT_RGBA8)
			img.fill(Color(0, 0, 0, 0))
			_outline_rect(img, 2, 4, 32, 18, wood_mid, ink)
			_px_rect(img, 3, 22, 4, 4, wood_dark)
			_px_rect(img, 29, 22, 4, 4, wood_dark)
			_outline_rect(img, 7, 5, 5, 7, Color(0.84, 0.45, 0.14) if not dist else Color(0.36, 0.32, 0.58), ink)
			_px_rect(img, 8, 4, 3, 2, Color(0.86, 0.86, 0.84))
			_outline_rect(img, 14, 7, 5, 6, Color(0.84, 0.45, 0.14) if not dist else Color(0.36, 0.32, 0.58), ink)
			_px_rect(img, 15, 6, 3, 2, Color(0.86, 0.86, 0.84))
			if dist:
				_px_rect(img, 11, 13, 2, 2, Color(0.86, 0.84, 0.96))
				_px_rect(img, 19, 15, 2, 2, Color(0.86, 0.84, 0.96))
				_px_rect(img, 25, 11, 6, 6, Color(0.08, 0.06, 0.14))
			_outline_rect(img, 24, 3, 8, 6, Color(0.78, 0.65, 0.28) if not dist else Color(0.32, 0.28, 0.48), ink)
			_px_rect(img, 27, 9, 2, 4, steel)
			return img

		"pill_nightstand":
			var img := Image.create_empty(24, 24, false, Image.FORMAT_RGBA8)
			img.fill(Color(0, 0, 0, 0))
			_px_rect(img, 2, 20, 20, 3, Color(0.02, 0.02, 0.04, 0.48))
			_outline_rect(img, 3, 8, 18, 14, wood_dark, ink)
			_outline_rect(img, 2, 7, 20, 4, wood_mid, ink)
			_outline_rect(img, 5, 12, 14, 7, wood_mid, ink)
			_px_rect(img, 11, 15, 2, 1, Color(0.84, 0.78, 0.58) if not dist else Color(0.62, 0.58, 0.80))
			_outline_rect(img, 5, 2, 5, 6, Color(0.84, 0.48, 0.16) if not dist else Color(0.40, 0.36, 0.64), ink)
			_px_rect(img, 6, 1, 3, 2, Color(0.90, 0.90, 0.88))
			_outline_rect(img, 12, 3, 5, 5, Color(0.38, 0.72, 0.88) if not dist else Color(0.34, 0.32, 0.52), ink)
			_px_rect(img, 13, 4, 3, 2, Color(0.72, 0.92, 0.98) if not dist else Color(0.76, 0.74, 0.92))
			if dist:
				_px_rect(img, 18, 5, 2, 2, Color(0.86, 0.84, 0.98))
			return img

		"locker_uniform":
			var img := Image.create_empty(24, 38, false, Image.FORMAT_RGBA8)
			img.fill(Color(0, 0, 0, 0))
			_outline_rect(img, 2, 2, 20, 34, steel, ink)
			_px_rect(img, 11, 4, 2, 30, ink)
			_px_rect(img, 5, 6, 4, 1, ink)
			_px_rect(img, 15, 6, 4, 1, ink)
			_px_rect(img, 5, 16, 4, 10, Color(0.68, 0.22, 0.16) if not dist else Color(0.24, 0.20, 0.38))
			_px_rect(img, 5, 22, 4, 2, Color(0.86, 0.72, 0.22) if not dist else Color(0.38, 0.34, 0.58))
			return img

		"radio_clock":
			var img := Image.create_empty(24, 24, false, Image.FORMAT_RGBA8)
			img.fill(Color(0, 0, 0, 0))
			_outline_rect(img, 2, 6, 20, 14, Color(0.14, 0.15, 0.19), ink)
			_px_rect(img, 4, 8, 10, 6, Color(0.18, 0.36, 0.28) if not dist else Color(0.28, 0.24, 0.48))
			_px_rect(img, 17, 2, 1, 5, Color(0.60, 0.64, 0.70))
			_px_rect(img, 16, 9, 3, 2, Color(0.85, 0.24, 0.20) if not dist else Color(0.66, 0.62, 0.92))
			if dist:
				_px_rect(img, 6, 10, 2, 2, eye_glow)
				_px_rect(img, 10, 10, 2, 2, eye_glow)
			return img

		"pusa_cat":
			return _build_pusa_cat_frame_image(0, dist)

		"banig_mat":
			var img := Image.create_empty(48, 32, false, Image.FORMAT_RGBA8)
			img.fill(Color(0, 0, 0, 0))
			_outline_rect(img, 1, 1, 46, 30, Color(0.42, 0.36, 0.26) if not dist else Color(0.14, 0.13, 0.22), ink)
			for y in range(4, 28, 4):
				for x in range(4, 44, 4):
					if ((x + y) / 4) % 2 == 0:
						_px_rect(img, x, y, 2, 2, Color(0.55, 0.26, 0.22) if not dist else Color(0.24, 0.20, 0.38))
			if dist:
				_px_rect(img, 18, 12, 12, 8, Color(0.84, 0.82, 0.94))
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
			_px_rect(img, 5, 5, 14, 6, Color(0.86, 0.84, 0.96))
			_px_rect(img, 8, 3, 8, 10, Color(0.86, 0.84, 0.96))
			_px_rect(img, 10, 4, 4, 8, Color(0.38, 0.32, 0.68))
			_px_rect(img, 11, 6, 2, 4, ink)
			return img

		"floor_stain":
			var img := Image.create_empty(32, 24, false, Image.FORMAT_RGBA8)
			img.fill(Color(0, 0, 0, 0))
			var col := Color(0.08, 0.07, 0.08, 0.72) if not dist else Color(0.05, 0.04, 0.11, 0.84)
			_px_rect(img, 6, 6, 16, 10, col)
			_px_rect(img, 14, 3, 12, 8, col)
			_px_rect(img, 3, 12, 9, 6, col)
			if dist:
				_px_rect(img, 10, 8, 6, 4, Color(0.16, 0.14, 0.28, 0.72))
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
			_px_rect(img, 8, 25, 54, 3, Color(0.84, 0.72, 0.24) if not dist else Color(0.28, 0.26, 0.44))
			_outline_rect(img, 20, 20, 14, 12, steel, ink)
			# Roof ladder & emergency lightbar
			_outline_rect(img, 10, 9, 44, 5, Color(0.62, 0.65, 0.70), ink)
			_outline_rect(img, 71, 13, 8, 4, Color(0.90, 0.20, 0.22) if not dist else Color(0.56, 0.52, 0.86), ink)
			return img

		"jeepney_parked":
			var img := Image.create_empty(80, 40, false, Image.FORMAT_RGBA8)
			img.fill(Color(0, 0, 0, 0))
			_px_rect(img, 4, 31, 72, 6, Color(0.01, 0.01, 0.02, 0.60))
			_outline_rect(img, 10, 27, 10, 9, Color(0.09, 0.09, 0.11), ink)
			_outline_rect(img, 60, 27, 10, 9, Color(0.09, 0.09, 0.11), ink)
			var body := Color(0.24, 0.34, 0.44) if not dist else Color(0.11, 0.10, 0.18)
			_outline_rect(img, 6, 10, 68, 20, body, ink)
			_px_rect(img, 8, 12, 42, 7, Color(0.12, 0.14, 0.18))
			_px_rect(img, 54, 13, 14, 8, Color(0.20, 0.30, 0.40) if not dist else Color(0.03, 0.03, 0.06))
			_px_rect(img, 8, 22, 64, 3, Color(0.84, 0.70, 0.25) if not dist else Color(0.28, 0.26, 0.46))
			return img

		"streetlamp_pole":
			var img := Image.create_empty(16, 48, false, Image.FORMAT_RGBA8)
			img.fill(Color(0, 0, 0, 0))
			_px_rect(img, 6, 42, 4, 5, steel)
			_px_rect(img, 7, 10, 2, 34, steel)
			_px_rect(img, 4, 8, 8, 3, Color(0.20, 0.22, 0.26))
			_px_rect(img, 5, 11, 6, 4, Color(0.95, 0.82, 0.44) if not dist else Color(0.62, 0.58, 0.92))
			return img

		"barangay_arch":
			var img := Image.create_empty(64, 48, false, Image.FORMAT_RGBA8)
			img.fill(Color(0, 0, 0, 0))
			_outline_rect(img, 2, 10, 8, 36, steel, ink)
			_outline_rect(img, 54, 10, 8, 36, steel, ink)
			_outline_rect(img, 2, 2, 60, 12, Color(0.18, 0.24, 0.32) if not dist else Color(0.12, 0.10, 0.20), ink)
			_px_rect(img, 8, 5, 48, 5, Color(0.84, 0.78, 0.56) if not dist else Color(0.46, 0.42, 0.68))
			return img

		"bfp_desk":
			var img := Image.create_empty(48, 24, false, Image.FORMAT_RGBA8)
			img.fill(Color(0, 0, 0, 0))
			_outline_rect(img, 2, 4, 44, 16, wood_mid, ink)
			_outline_rect(img, 8, 6, 12, 8, steel, ink) # monitor
			_px_rect(img, 10, 7, 8, 5, Color(0.22, 0.45, 0.35) if not dist else Color(0.32, 0.28, 0.54))
			_outline_rect(img, 28, 8, 10, 6, Color(0.80, 0.80, 0.76), ink) # logbook
			return img

		"medical_bed":
			var img := Image.create_empty(32, 44, false, Image.FORMAT_RGBA8)
			img.fill(Color(0, 0, 0, 0))
			_outline_rect(img, 2, 2, 28, 40, steel, ink)
			_outline_rect(img, 4, 4, 24, 36, Color(0.76, 0.80, 0.84) if not dist else Color(0.28, 0.27, 0.36), ink)
			_px_rect(img, 6, 5, 20, 7, Color(0.88, 0.90, 0.92))
			_px_rect(img, 6, 18, 20, 18, Color(0.28, 0.46, 0.54) if not dist else Color(0.16, 0.14, 0.28))
			return img

		"basketball_hoop":
			var img := Image.create_empty(24, 48, false, Image.FORMAT_RGBA8)
			img.fill(Color(0, 0, 0, 0))
			_px_rect(img, 10, 14, 4, 32, steel)
			_outline_rect(img, 4, 2, 16, 12, Color(0.72, 0.74, 0.76) if not dist else Color(0.25, 0.22, 0.30), ink)
			_px_rect(img, 9, 10, 6, 2, Color(0.78, 0.24, 0.18) if not dist else Color(0.34, 0.30, 0.54))
			return img

		"pine_canopy_cluster":
			var img := Image.create_empty(48, 64, false, Image.FORMAT_RGBA8)
			img.fill(Color(0, 0, 0, 0))
			var leaf_dark := Color(0.06, 0.11, 0.08) if not dist else Color(0.06, 0.05, 0.10)
			var leaf_mid := Color(0.11, 0.19, 0.13) if not dist else Color(0.10, 0.09, 0.16)
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
			var bark := Color(0.13, 0.11, 0.12) if not dist else Color(0.09, 0.08, 0.14)
			_outline_rect(img, 14, 20, 8, 30, bark, ink)
			_outline_rect(img, 4, 12, 12, 5, bark, ink)
			_outline_rect(img, 20, 8, 12, 5, bark, ink)
			_outline_rect(img, 10, 4, 6, 12, bark, ink)
			if dist:
				_px_rect(img, 16, 28, 4, 6, Color(0.04, 0.03, 0.08))
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
			_px_rect(img, 5, 7, 14, 2, Color(0.76, 0.72, 0.62) if not dist else Color(0.56, 0.52, 0.76))
			_px_rect(img, 5, 11, 10, 2, Color(0.76, 0.72, 0.62) if not dist else Color(0.56, 0.52, 0.76))
			return img

		"trash_pile":
			var img := Image.create_empty(28, 20, false, Image.FORMAT_RGBA8)
			img.fill(Color(0, 0, 0, 0))
			var bag := Color(0.11, 0.12, 0.15) if not dist else Color(0.08, 0.07, 0.14)
			var box_col := Color(0.36, 0.28, 0.19) if not dist else Color(0.15, 0.14, 0.22)
			_px_rect(img, 2, 15, 24, 4, Color(0.02, 0.02, 0.03, 0.55))
			_outline_rect(img, 14, 7, 10, 9, box_col, ink)
			_outline_rect(img, 4, 8, 10, 8, bag, ink)
			_outline_rect(img, 9, 4, 9, 8, bag, ink)
			_px_rect(img, 12, 2, 3, 2, Color(0.26, 0.28, 0.34))
			_px_rect(img, 2, 13, 3, 2, Color(0.56, 0.58, 0.62))
			_px_rect(img, 22, 14, 4, 2, Color(0.68, 0.24, 0.20) if not dist else Color(0.26, 0.24, 0.44))
			if dist:
				_px_rect(img, 7, 15, 9, 3, Color(0.05, 0.04, 0.10, 0.85))
				_px_rect(img, 12, 7, 2, 2, eye_glow)
			return img

		"market_crates":
			var img := Image.create_empty(36, 24, false, Image.FORMAT_RGBA8)
			img.fill(Color(0, 0, 0, 0))
			var tarp := Color(0.20, 0.34, 0.48) if not dist else Color(0.14, 0.12, 0.24)
			_px_rect(img, 3, 18, 30, 4, Color(0.02, 0.02, 0.03, 0.55))
			_outline_rect(img, 4, 8, 12, 11, wood_mid, ink)
			_px_rect(img, 5, 11, 10, 1, wood_dark)
			_px_rect(img, 5, 15, 10, 1, wood_dark)
			_outline_rect(img, 17, 10, 11, 9, wood_dark, ink)
			_outline_rect(img, 8, 4, 14, 6, tarp, ink)
			_outline_rect(img, 27, 13, 6, 5, Color(0.26, 0.48, 0.58) if not dist else Color(0.20, 0.18, 0.34), ink)
			if dist:
				_px_rect(img, 12, 16, 12, 4, Color(0.05, 0.04, 0.10, 0.85))
				_px_rect(img, 19, 13, 2, 2, eye_glow)
			return img

		"abandoned_tricycle":
			var img := Image.create_empty(44, 28, false, Image.FORMAT_RGBA8)
			img.fill(Color(0, 0, 0, 0))
			var rust_cab := Color(0.24, 0.27, 0.33) if not dist else Color(0.12, 0.11, 0.19)
			var roof_col := Color(0.38, 0.22, 0.18) if not dist else Color(0.18, 0.15, 0.28)
			_px_rect(img, 4, 21, 36, 5, Color(0.02, 0.02, 0.03, 0.62))
			_outline_rect(img, 8, 17, 9, 8, Color(0.09, 0.09, 0.11), ink)
			_outline_rect(img, 30, 19, 7, 5, Color(0.36, 0.22, 0.20), ink)
			_outline_rect(img, 6, 9, 20, 12, rust_cab, ink)
			_outline_rect(img, 8, 3, 18, 7, roof_col, ink)
			_px_rect(img, 14, 11, 8, 5, Color(0.12, 0.14, 0.18))
			_outline_rect(img, 26, 12, 11, 8, steel, ink)
			_px_rect(img, 29, 9, 4, 3, Color(0.45, 0.24, 0.14))
			if dist:
				_px_rect(img, 35, 14, 2, 2, eye_glow)
				_px_rect(img, 10, 19, 12, 3, Color(0.06, 0.05, 0.11))
			return img

		"abandoned_car_wreck":
			var img := Image.create_empty(76, 36, false, Image.FORMAT_RGBA8)
			img.fill(Color(0, 0, 0, 0))
			var body_col := Color(0.25, 0.26, 0.29) if not dist else Color(0.11, 0.10, 0.17)
			var rust_col := Color(0.38, 0.21, 0.15) if not dist else Color(0.18, 0.16, 0.28)
			_px_rect(img, 4, 27, 68, 6, Color(0.02, 0.02, 0.03, 0.68))
			_outline_rect(img, 12, 23, 9, 6, Color(0.32, 0.32, 0.35), ink)
			_outline_rect(img, 54, 23, 9, 6, Color(0.32, 0.32, 0.35), ink)
			_outline_rect(img, 6, 13, 64, 12, body_col, ink)
			_outline_rect(img, 18, 5, 32, 9, body_col, ink)
			_px_rect(img, 22, 7, 10, 5, Color(0.08, 0.09, 0.12))
			_px_rect(img, 36, 7, 10, 5, Color(0.08, 0.09, 0.12))
			_px_rect(img, 52, 11, 14, 3, rust_col)
			_px_rect(img, 10, 17, 18, 4, rust_col)
			_px_rect(img, 38, 15, 12, 3, rust_col)
			if dist:
				_px_rect(img, 38, 8, 2, 2, eye_glow)
				_px_rect(img, 43, 8, 2, 2, eye_glow)
				_px_rect(img, 24, 22, 24, 4, Color(0.06, 0.05, 0.11, 0.88))
			return img

		"utility_box":
			var img := Image.create_empty(20, 32, false, Image.FORMAT_RGBA8)
			img.fill(Color(0, 0, 0, 0))
			_px_rect(img, 4, 27, 12, 3, Color(0.02, 0.02, 0.03, 0.55))
			_outline_rect(img, 4, 4, 12, 24, steel, ink)
			_px_rect(img, 6, 7, 8, 6, Color(0.20, 0.22, 0.26))
			_px_rect(img, 8, 9, 4, 3, Color(0.76, 0.62, 0.18) if not dist else Color(0.46, 0.42, 0.72))
			_px_rect(img, 13, 16, 2, 4, Color(0.08, 0.08, 0.10))
			_px_rect(img, 2, 10, 2, 10, Color(0.10, 0.10, 0.13))
			_px_rect(img, 16, 13, 2, 11, Color(0.10, 0.10, 0.13))
			if dist:
				_px_rect(img, 7, 18, 6, 7, Color(0.06, 0.05, 0.11))
			return img

		"overgrown_weeds":
			var img := Image.create_empty(32, 20, false, Image.FORMAT_RGBA8)
			img.fill(Color(0, 0, 0, 0))
			var leaf_a := Color(0.10, 0.18, 0.11) if not dist else Color(0.08, 0.08, 0.15)
			var leaf_b := Color(0.17, 0.28, 0.16) if not dist else Color(0.14, 0.13, 0.24)
			var spore := Color(0.32, 0.36, 0.20) if not dist else Color(0.56, 0.52, 0.84)
			_outline_rect(img, 4, 11, 24, 7, leaf_a, ink)
			_outline_rect(img, 6, 6, 8, 10, leaf_b, ink)
			_outline_rect(img, 13, 3, 7, 12, leaf_b, ink)
			_outline_rect(img, 19, 7, 8, 9, leaf_a, ink)
			_px_rect(img, 8, 4, 2, 4, spore)
			_px_rect(img, 22, 5, 2, 3, spore)
			return img

		"corner_shrub":
			var img := Image.create_empty(28, 28, false, Image.FORMAT_RGBA8)
			img.fill(Color(0, 0, 0, 0))
			var dark_leaf := Color(0.07, 0.13, 0.09) if not dist else Color(0.06, 0.06, 0.12)
			var mid_leaf := Color(0.13, 0.22, 0.14) if not dist else Color(0.12, 0.11, 0.20)
			_px_rect(img, 4, 23, 20, 3, Color(0.02, 0.02, 0.03, 0.50))
			_outline_rect(img, 3, 11, 22, 13, dark_leaf, ink)
			_outline_rect(img, 6, 5, 16, 12, mid_leaf, ink)
			_outline_rect(img, 9, 2, 10, 7, mid_leaf, ink)
			if dist:
				_px_rect(img, 11, 11, 2, 2, eye_glow)
				_px_rect(img, 16, 11, 2, 2, eye_glow)
			return img

		"clothesline_post":
			var img := Image.create_empty(48, 36, false, Image.FORMAT_RGBA8)
			img.fill(Color(0, 0, 0, 0))
			var cloth_a := Color(0.56, 0.56, 0.58) if not dist else Color(0.18, 0.17, 0.26)
			var cloth_b := Color(0.26, 0.34, 0.44) if not dist else Color(0.14, 0.13, 0.24)
			_outline_rect(img, 3, 4, 4, 28, wood_dark, ink)
			_outline_rect(img, 41, 4, 4, 28, wood_dark, ink)
			_px_rect(img, 6, 7, 36, 1, Color(0.46, 0.44, 0.40))
			_outline_rect(img, 10, 8, 9, 13, cloth_a, ink)
			_outline_rect(img, 21, 8, 8, 15, cloth_b, ink)
			_outline_rect(img, 31, 8, 7, 11, cloth_a, ink)
			if dist:
				_px_rect(img, 13, 13, 3, 5, Color(0.07, 0.06, 0.13))
				_px_rect(img, 23, 14, 4, 5, Color(0.05, 0.04, 0.09))
			return img

		_:
			var coastal := _build_town_ambient_prop_image(kind, dist, ink)
			if coastal != null:
				return coastal
			var bfp_img := _build_bfp_interior_prop_image(kind, dist, ink)
			if bfp_img != null:
				return bfp_img
			var fallback := Image.create_empty(16, 16, false, Image.FORMAT_RGBA8)
			fallback.fill(Color(0.20, 0.22, 0.26, 1.0))
			return fallback


## Props costeiros, de quintal e de calçada de Agdangan (pixel art 16-bit, base alinhada ao fundo da imagem).
static func _build_town_ambient_prop_image(kind: String, dist: bool, ink: Color) -> Image:
	var T := func(c: Color) -> Color:
		if not dist:
			return c
		var l := c.get_luminance()
		return Color(l * 0.52 + 0.04, l * 0.50 + 0.04, minf(1.0, l * 0.78 + 0.08), c.a)
	var shadow := Color(0.02, 0.02, 0.03, 0.46)
	var img: Image = null
	match kind:
		"driftwood":
			img = Image.create_empty(36, 14, false, Image.FORMAT_RGBA8)
			img.fill(Color(0, 0, 0, 0))
			_px_rect(img, 2, 10, 32, 3, shadow)
			_outline_rect(img, 2, 4, 30, 6, T.call(Color(0.52, 0.45, 0.36)), ink)
			_outline_rect(img, 24, 2, 9, 5, T.call(Color(0.42, 0.35, 0.27)), ink)
			_px_rect(img, 6, 5, 8, 1, T.call(Color(0.68, 0.61, 0.50)))
			_px_rect(img, 16, 7, 6, 1, T.call(Color(0.34, 0.28, 0.22)))
		"kaing_basket":
			img = Image.create_empty(18, 18, false, Image.FORMAT_RGBA8)
			img.fill(Color(0, 0, 0, 0))
			_px_rect(img, 2, 14, 14, 3, shadow)
			_outline_rect(img, 3, 6, 12, 10, T.call(Color(0.64, 0.48, 0.24)), ink)
			for sy in [8, 11, 14]:
				_px_rect(img, 4, sy, 10, 1, T.call(Color(0.44, 0.32, 0.16)))
			_px_rect(img, 5, 2, 8, 1, ink)
			_px_rect(img, 4, 3, 1, 3, ink)
			_px_rect(img, 13, 3, 1, 3, ink)
		"rope_coil":
			img = Image.create_empty(16, 12, false, Image.FORMAT_RGBA8)
			img.fill(Color(0, 0, 0, 0))
			_px_rect(img, 1, 8, 14, 3, shadow)
			_outline_rect(img, 2, 3, 12, 7, T.call(Color(0.72, 0.62, 0.40)), ink)
			_outline_rect(img, 5, 5, 6, 3, T.call(Color(0.40, 0.33, 0.20)), ink)
		"starfish":
			img = Image.create_empty(10, 10, false, Image.FORMAT_RGBA8)
			img.fill(Color(0, 0, 0, 0))
			var sf := T.call(Color(0.92, 0.46, 0.30)) as Color
			_px_rect(img, 4, 1, 2, 8, sf)
			_px_rect(img, 1, 4, 8, 2, sf)
			_px_rect(img, 3, 3, 4, 4, T.call(Color(0.98, 0.62, 0.42)))
			_px_rect(img, 4, 4, 2, 2, T.call(Color(1.0, 0.82, 0.60)))
		"seashell":
			img = Image.create_empty(8, 7, false, Image.FORMAT_RGBA8)
			img.fill(Color(0, 0, 0, 0))
			_outline_rect(img, 1, 1, 6, 5, T.call(Color(0.94, 0.88, 0.80)), ink)
			_px_rect(img, 3, 2, 1, 3, T.call(Color(0.80, 0.66, 0.58)))
		"pier_lantern":
			img = Image.create_empty(12, 36, false, Image.FORMAT_RGBA8)
			img.fill(Color(0, 0, 0, 0))
			_px_rect(img, 2, 32, 8, 3, shadow)
			_outline_rect(img, 5, 10, 3, 24, T.call(Color(0.30, 0.22, 0.16)), ink)
			_outline_rect(img, 2, 2, 8, 9, T.call(Color(0.28, 0.30, 0.34)), ink)
			_px_rect(img, 4, 4, 4, 5, T.call(Color(1.0, 0.84, 0.44)))
		"water_drum":
			img = Image.create_empty(18, 24, false, Image.FORMAT_RGBA8)
			img.fill(Color(0, 0, 0, 0))
			_px_rect(img, 2, 20, 14, 3, shadow)
			_outline_rect(img, 3, 3, 12, 19, T.call(Color(0.16, 0.34, 0.66)), ink)
			_px_rect(img, 4, 8, 10, 1, T.call(Color(0.10, 0.22, 0.46)))
			_px_rect(img, 4, 15, 10, 1, T.call(Color(0.10, 0.22, 0.46)))
			_px_rect(img, 5, 4, 3, 14, T.call(Color(0.30, 0.52, 0.86)))
		"firewood_pile":
			img = Image.create_empty(28, 20, false, Image.FORMAT_RGBA8)
			img.fill(Color(0, 0, 0, 0))
			_px_rect(img, 2, 16, 24, 3, shadow)
			for ry in range(3):
				for rx in range(4 - (ry % 2)):
					var lx := 3 + rx * 6 + (3 if ry % 2 == 1 else 0)
					_outline_rect(img, lx, 12 - ry * 5, 6, 6, T.call(Color(0.46, 0.32, 0.20)), ink)
					_px_rect(img, lx + 2, 14 - ry * 5, 2, 2, T.call(Color(0.70, 0.56, 0.38)))
			_outline_rect(img, 2, 1, 24, 4, T.call(Color(0.16, 0.30, 0.52)), ink)
		"bicycle":
			img = Image.create_empty(32, 20, false, Image.FORMAT_RGBA8)
			img.fill(Color(0, 0, 0, 0))
			_px_rect(img, 3, 17, 26, 2, shadow)
			_outline_rect(img, 3, 8, 9, 9, T.call(Color(0.12, 0.12, 0.14)), ink)
			_outline_rect(img, 20, 8, 9, 9, T.call(Color(0.12, 0.12, 0.14)), ink)
			_px_rect(img, 5, 10, 5, 5, Color(0, 0, 0, 0))
			_px_rect(img, 22, 10, 5, 5, Color(0, 0, 0, 0))
			_px_rect(img, 7, 7, 15, 2, T.call(Color(0.80, 0.18, 0.18)))
			_px_rect(img, 12, 4, 2, 5, T.call(Color(0.60, 0.12, 0.12)))
			_px_rect(img, 21, 3, 5, 2, ink)
			_px_rect(img, 10, 3, 5, 2, ink)
		"wood_bench":
			img = Image.create_empty(32, 18, false, Image.FORMAT_RGBA8)
			img.fill(Color(0, 0, 0, 0))
			_px_rect(img, 2, 14, 28, 3, shadow)
			_outline_rect(img, 2, 3, 28, 4, T.call(Color(0.48, 0.34, 0.22)), ink)
			_outline_rect(img, 2, 8, 28, 4, T.call(Color(0.56, 0.40, 0.26)), ink)
			_outline_rect(img, 4, 11, 3, 5, T.call(Color(0.28, 0.20, 0.14)), ink)
			_outline_rect(img, 25, 11, 3, 5, T.call(Color(0.28, 0.20, 0.14)), ink)
		"flower_pot":
			img = Image.create_empty(14, 16, false, Image.FORMAT_RGBA8)
			img.fill(Color(0, 0, 0, 0))
			_px_rect(img, 2, 13, 10, 2, shadow)
			_outline_rect(img, 3, 9, 8, 6, T.call(Color(0.70, 0.34, 0.22)), ink)
			_outline_rect(img, 2, 3, 10, 7, T.call(Color(0.18, 0.46, 0.22)), ink)
			_px_rect(img, 4, 4, 2, 2, T.call(Color(0.96, 0.78, 0.22)))
			_px_rect(img, 8, 5, 2, 2, T.call(Color(0.92, 0.32, 0.44)))
		"notice_board":
			img = Image.create_empty(22, 30, false, Image.FORMAT_RGBA8)
			img.fill(Color(0, 0, 0, 0))
			_px_rect(img, 3, 27, 16, 2, shadow)
			_outline_rect(img, 3, 14, 3, 14, T.call(Color(0.28, 0.20, 0.14)), ink)
			_outline_rect(img, 16, 14, 3, 14, T.call(Color(0.28, 0.20, 0.14)), ink)
			_outline_rect(img, 1, 2, 20, 16, T.call(Color(0.44, 0.32, 0.22)), ink)
			_px_rect(img, 4, 5, 6, 5, T.call(Color(0.92, 0.90, 0.82)))
			_px_rect(img, 12, 5, 6, 4, T.call(Color(0.90, 0.30, 0.26)))
			_px_rect(img, 5, 11, 7, 4, T.call(Color(0.86, 0.84, 0.74)))
		"traffic_cone":
			img = Image.create_empty(12, 14, false, Image.FORMAT_RGBA8)
			img.fill(Color(0, 0, 0, 0))
			_px_rect(img, 1, 12, 10, 2, shadow)
			_outline_rect(img, 1, 10, 10, 3, T.call(Color(0.20, 0.20, 0.22)), ink)
			_outline_rect(img, 3, 2, 6, 9, T.call(Color(0.96, 0.46, 0.12)), ink)
			_px_rect(img, 4, 5, 4, 2, T.call(Color(0.96, 0.96, 0.92)))
		"trash_bin":
			img = Image.create_empty(14, 18, false, Image.FORMAT_RGBA8)
			img.fill(Color(0, 0, 0, 0))
			_px_rect(img, 2, 15, 10, 2, shadow)
			_outline_rect(img, 2, 5, 10, 11, T.call(Color(0.20, 0.42, 0.28)), ink)
			_outline_rect(img, 1, 3, 12, 3, T.call(Color(0.14, 0.30, 0.20)), ink)
			_px_rect(img, 4, 8, 1, 6, T.call(Color(0.30, 0.56, 0.38)))
		"beach_tuft":
			img = Image.create_empty(16, 12, false, Image.FORMAT_RGBA8)
			img.fill(Color(0, 0, 0, 0))
			_px_rect(img, 2, 9, 12, 2, shadow)
			for bx in [3, 6, 9, 12]:
				_px_rect(img, bx, 3 + (bx % 3), 2, 7 - (bx % 3), T.call(Color(0.28, 0.46, 0.22)))
				_px_rect(img, bx, 3 + (bx % 3), 1, 7 - (bx % 3), T.call(Color(0.42, 0.62, 0.30)))
		"pebbles":
			img = Image.create_empty(18, 8, false, Image.FORMAT_RGBA8)
			img.fill(Color(0, 0, 0, 0))
			_outline_rect(img, 1, 3, 6, 4, T.call(Color(0.52, 0.52, 0.54)), ink)
			_outline_rect(img, 8, 2, 5, 4, T.call(Color(0.44, 0.44, 0.48)), ink)
			_outline_rect(img, 12, 4, 5, 3, T.call(Color(0.58, 0.56, 0.54)), ink)
		"mossy_rock":
			img = Image.create_empty(26, 18, false, Image.FORMAT_RGBA8)
			img.fill(Color(0, 0, 0, 0))
			_px_rect(img, 2, 14, 22, 3, shadow)
			_outline_rect(img, 2, 6, 22, 10, T.call(Color(0.40, 0.42, 0.44)), ink)
			_outline_rect(img, 6, 2, 14, 8, T.call(Color(0.46, 0.48, 0.50)), ink)
			_px_rect(img, 7, 3, 9, 3, T.call(Color(0.24, 0.40, 0.22)))
			_px_rect(img, 4, 8, 5, 2, T.call(Color(0.24, 0.40, 0.22)))
		"fern_cluster":
			img = Image.create_empty(24, 18, false, Image.FORMAT_RGBA8)
			img.fill(Color(0, 0, 0, 0))
			_px_rect(img, 3, 15, 18, 2, shadow)
			for fx in range(5):
				var fh := 6 + (fx % 3) * 3
				_px_rect(img, 3 + fx * 4, 15 - fh, 3, fh, T.call(Color(0.14, 0.38, 0.20)))
				_px_rect(img, 3 + fx * 4, 15 - fh, 1, fh, T.call(Color(0.30, 0.58, 0.30)))
		"vegetable_bed":
			img = Image.create_empty(34, 20, false, Image.FORMAT_RGBA8)
			img.fill(Color(0, 0, 0, 0))
			_px_rect(img, 2, 17, 30, 2, shadow)
			_outline_rect(img, 1, 6, 32, 11, T.call(Color(0.34, 0.24, 0.16)), ink)
			for vx in range(6):
				_px_rect(img, 4 + vx * 5, 3, 4, 6, T.call(Color(0.22, 0.52, 0.22)))
				_px_rect(img, 5 + vx * 5, 2, 2, 3, T.call(Color(0.40, 0.70, 0.30)))
			_px_rect(img, 2, 5, 30, 1, T.call(Color(0.58, 0.46, 0.30)))
		"clothesline_low":
			img = Image.create_empty(52, 28, false, Image.FORMAT_RGBA8)
			img.fill(Color(0, 0, 0, 0))
			_px_rect(img, 4, 25, 44, 2, shadow)
			_outline_rect(img, 3, 4, 3, 22, T.call(Color(0.32, 0.24, 0.16)), ink)
			_outline_rect(img, 46, 4, 3, 22, T.call(Color(0.32, 0.24, 0.16)), ink)
			_px_rect(img, 6, 6, 40, 1, T.call(Color(0.84, 0.82, 0.74)))
			_outline_rect(img, 10, 7, 8, 11, T.call(Color(0.92, 0.92, 0.88)), ink)
			_outline_rect(img, 21, 7, 8, 13, T.call(Color(0.30, 0.46, 0.74)), ink)
			_outline_rect(img, 32, 7, 7, 9, T.call(Color(0.90, 0.78, 0.30)), ink)
		"drink_crates":
			img = Image.create_empty(22, 20, false, Image.FORMAT_RGBA8)
			img.fill(Color(0, 0, 0, 0))
			_px_rect(img, 2, 17, 18, 2, shadow)
			_outline_rect(img, 2, 9, 18, 9, T.call(Color(0.76, 0.18, 0.18)), ink)
			_px_rect(img, 4, 11, 14, 2, T.call(Color(0.56, 0.12, 0.12)))
			_outline_rect(img, 4, 2, 14, 8, T.call(Color(0.18, 0.44, 0.72)), ink)
			for bx in [6, 9, 12, 15]:
				_px_rect(img, bx, 1, 2, 3, T.call(Color(0.36, 0.66, 0.34)))
		"bfp_bucket":
			img = Image.create_empty(14, 14, false, Image.FORMAT_RGBA8)
			img.fill(Color(0, 0, 0, 0))
			_px_rect(img, 2, 11, 10, 2, shadow)
			_outline_rect(img, 3, 4, 8, 8, T.call(Color(0.80, 0.16, 0.16)), ink)
			_px_rect(img, 4, 5, 6, 2, T.call(Color(0.76, 0.68, 0.48)))
			_px_rect(img, 4, 2, 6, 1, ink)
			_px_rect(img, 3, 3, 1, 2, ink)
			_px_rect(img, 10, 3, 1, 2, ink)
		"flower_bed":
			img = Image.create_empty(30, 14, false, Image.FORMAT_RGBA8)
			img.fill(Color(0, 0, 0, 0))
			_px_rect(img, 2, 11, 26, 2, shadow)
			_outline_rect(img, 1, 6, 28, 6, T.call(Color(0.46, 0.46, 0.50)), ink)
			_px_rect(img, 3, 4, 24, 5, T.call(Color(0.18, 0.44, 0.20)))
			for fx in [5, 11, 18, 23]:
				_px_rect(img, fx, 3, 2, 2, T.call(Color(0.96, 0.80, 0.22) if fx % 2 == 1 else Color(0.92, 0.36, 0.48)))
	return img


## Props temáticos 16-bit do interior do Corpo de Bombeiros (BFP Agdangan) — estilo interiors_v2.
static func _build_bfp_interior_prop_image(kind: String, dist: bool, ink: Color) -> Image:
	var T := func(c: Color) -> Color:
		if not dist:
			return c
		var l := c.get_luminance()
		return Color(l * 0.52 + 0.04, l * 0.50 + 0.04, minf(1.0, l * 0.78 + 0.08), c.a)
	var shadow := Color(0.02, 0.02, 0.04, 0.48)
	var red_bfp: Color = T.call(Color(0.76, 0.18, 0.18))
	var red_dark: Color = T.call(Color(0.50, 0.10, 0.12))
	var gold_bfp: Color = T.call(Color(0.92, 0.76, 0.26))
	var steel_l: Color = T.call(Color(0.56, 0.60, 0.66))
	var steel_d: Color = T.call(Color(0.34, 0.38, 0.44))
	var wood_m: Color = T.call(Color(0.48, 0.32, 0.20))
	var wood_d: Color = T.call(Color(0.32, 0.20, 0.12))
	var cream: Color = T.call(Color(0.90, 0.88, 0.82))
	var img: Image = null
	match kind:
		"bfp_locker_bank":
			img = Image.create_empty(28, 44, false, Image.FORMAT_RGBA8)
			img.fill(Color(0, 0, 0, 0))
			_px_rect(img, 2, 40, 24, 3, shadow)
			_outline_rect(img, 2, 2, 24, 39, steel_d, ink)
			_px_rect(img, 3, 3, 22, 4, red_bfp)
			for i in range(2):
				var lx := 4 + i * 11
				_outline_rect(img, lx, 8, 9, 31, steel_l, ink)
				_px_rect(img, lx + 2, 11, 5, 1, steel_d)
				_px_rect(img, lx + 2, 13, 5, 1, steel_d)
				_px_rect(img, lx + 2, 15, 5, 1, steel_d)
				_px_rect(img, lx + 6, 22, 2, 4, red_dark)
				_px_rect(img, lx + 2, 33, 5, 1, steel_d)
		"bfp_locker_single":
			img = Image.create_empty(18, 38, false, Image.FORMAT_RGBA8)
			img.fill(Color(0, 0, 0, 0))
			_px_rect(img, 2, 34, 14, 3, shadow)
			_outline_rect(img, 2, 2, 14, 33, steel_l, ink)
			_px_rect(img, 3, 3, 12, 3, red_bfp)
			_px_rect(img, 5, 9, 8, 1, steel_d)
			_px_rect(img, 5, 11, 8, 1, steel_d)
			_px_rect(img, 11, 18, 2, 4, red_dark)
			_px_rect(img, 5, 29, 8, 1, steel_d)
		"bfp_locker_bench":
			img = Image.create_empty(20, 52, false, Image.FORMAT_RGBA8)
			img.fill(Color(0, 0, 0, 0))
			_px_rect(img, 3, 47, 14, 4, shadow)
			_outline_rect(img, 4, 3, 12, 44, wood_m, ink)
			_px_rect(img, 7, 4, 1, 42, wood_d)
			_px_rect(img, 12, 4, 1, 42, wood_d)
			_outline_rect(img, 3, 9, 14, 4, steel_d, ink)
			_outline_rect(img, 3, 37, 14, 4, steel_d, ink)
		"bfp_ppe_rack":
			img = Image.create_empty(58, 38, false, Image.FORMAT_RGBA8)
			img.fill(Color(0, 0, 0, 0))
			_px_rect(img, 3, 34, 52, 3, shadow)
			_outline_rect(img, 2, 3, 54, 5, steel_d, ink)
			_outline_rect(img, 3, 7, 3, 28, steel_d, ink)
			_outline_rect(img, 52, 7, 3, 28, steel_d, ink)
			_px_rect(img, 5, 11, 48, 2, steel_l)
			# 3 conjuntos de EPI (jaqueta amarela/laranja + faixa refletiva + capacetes)
			for i in range(3):
				var gx := 8 + i * 15
				var helm_col: Color = red_bfp if i != 1 else gold_bfp
				var coat_col: Color = T.call(Color(0.90, 0.64, 0.16) if i % 2 == 0 else Color(0.86, 0.42, 0.14))
				var stripe_col: Color = T.call(Color(0.86, 0.96, 0.42)) if not dist else Color(0.54, 0.50, 0.84)
				_outline_rect(img, gx + 2, 0, 9, 5, helm_col, ink)
				_px_rect(img, gx + 1, 4, 11, 2, helm_col)
				_outline_rect(img, gx, 12, 13, 15, coat_col, ink)
				_px_rect(img, gx + 1, 18, 11, 2, stripe_col)
				_px_rect(img, gx + 1, 23, 11, 2, stripe_col)
				_outline_rect(img, gx + 2, 26, 4, 8, wood_d, ink)
				_outline_rect(img, gx + 7, 26, 4, 8, wood_d, ink)
		"bfp_hose_rack":
			img = Image.create_empty(38, 28, false, Image.FORMAT_RGBA8)
			img.fill(Color(0, 0, 0, 0))
			_px_rect(img, 2, 24, 34, 3, shadow)
			_outline_rect(img, 2, 16, 34, 9, wood_d, ink)
			_px_rect(img, 4, 18, 30, 2, wood_m)
			_px_rect(img, 4, 21, 30, 2, wood_m)
			# 2 rolos de mangueira (vermelha e amarela) com esguicho metálico
			_outline_rect(img, 4, 4, 14, 14, red_bfp, ink)
			_outline_rect(img, 7, 7, 8, 8, red_dark, ink)
			_px_rect(img, 10, 10, 2, 2, gold_bfp)
			_outline_rect(img, 20, 4, 14, 14, gold_bfp, ink)
			_outline_rect(img, 23, 7, 8, 8, T.call(Color(0.68, 0.50, 0.12)), ink)
			_px_rect(img, 26, 10, 2, 2, steel_l)
		"bfp_extinguisher":
			img = Image.create_empty(14, 24, false, Image.FORMAT_RGBA8)
			img.fill(Color(0, 0, 0, 0))
			_px_rect(img, 2, 21, 10, 2, shadow)
			_outline_rect(img, 3, 7, 8, 15, red_bfp, ink)
			_px_rect(img, 5, 9, 2, 10, T.call(Color(0.94, 0.36, 0.32)))
			_px_rect(img, 4, 13, 6, 3, cream)
			_outline_rect(img, 5, 3, 4, 4, steel_d, ink)
			_px_rect(img, 8, 4, 3, 2, ink)
			_px_rect(img, 10, 6, 2, 9, ink)
		"bfp_extinguisher_row":
			img = Image.create_empty(48, 28, false, Image.FORMAT_RGBA8)
			img.fill(Color(0, 0, 0, 0))
			_px_rect(img, 2, 24, 44, 3, shadow)
			_outline_rect(img, 2, 16, 44, 9, steel_d, ink)
			for i in range(3):
				var cx := 5 + i * 14
				_outline_rect(img, cx, 5, 10, 18, red_bfp, ink)
				_px_rect(img, cx + 2, 7, 2, 12, T.call(Color(0.94, 0.36, 0.32)))
				_px_rect(img, cx + 2, 11, 6, 3, gold_bfp)
				_outline_rect(img, cx + 3, 2, 4, 3, steel_l, ink)
		"bfp_axe_case":
			img = Image.create_empty(18, 24, false, Image.FORMAT_RGBA8)
			img.fill(Color(0, 0, 0, 0))
			_outline_rect(img, 1, 1, 16, 22, red_bfp, ink)
			_outline_rect(img, 3, 3, 12, 18, T.call(Color(0.24, 0.32, 0.38)), ink)
			# Machado de incêndio diagonal/vertical atrás do vidro
			_px_rect(img, 8, 6, 2, 13, wood_m)
			_px_rect(img, 5, 5, 8, 4, steel_l)
			_px_rect(img, 11, 5, 2, 2, red_bfp)
			_px_rect(img, 4, 4, 2, 6, Color(0.85, 0.92, 0.98, 0.35))
		"bfp_command_desk":
			img = Image.create_empty(124, 42, false, Image.FORMAT_RGBA8)
			img.fill(Color(0, 0, 0, 0))
			_px_rect(img, 4, 37, 116, 4, shadow)
			# Corpo robusto da bancada de comando + faixa vermelha BFP frontal
			_outline_rect(img, 2, 10, 120, 28, wood_d, ink)
			_outline_rect(img, 4, 8, 116, 14, wood_m, ink)
			_px_rect(img, 4, 24, 116, 3, red_bfp)
			_px_rect(img, 4, 27, 116, 1, gold_bfp)
			# Rádio VHF/UHF à esquerda com LEDs e antena
			_outline_rect(img, 10, 3, 26, 14, steel_d, ink)
			_px_rect(img, 12, 5, 14, 6, T.call(Color(0.14, 0.24, 0.20)))
			_px_rect(img, 13, 6, 12, 2, Color(0.32, 0.94, 0.44) if not dist else Color(0.62, 0.58, 0.92))
			_px_rect(img, 28, 6, 2, 2, Color(0.96, 0.22, 0.22) if not dist else Color(0.76, 0.72, 0.98))
			_px_rect(img, 31, 6, 2, 2, Color(0.30, 0.94, 0.40) if not dist else Color(0.62, 0.58, 0.92))
			_px_rect(img, 28, 10, 6, 4, steel_l)
			_px_rect(img, 12, 0, 2, 4, steel_l)
			# Mapa aberto + prancheta de ocorrências ao centro
			_outline_rect(img, 44, 10, 26, 10, cream, ink)
			_px_rect(img, 47, 12, 8, 5, T.call(Color(0.28, 0.56, 0.34)))
			_px_rect(img, 56, 13, 10, 4, T.call(Color(0.24, 0.48, 0.72)))
			_px_rect(img, 54, 14, 2, 2, red_bfp)
			_outline_rect(img, 74, 9, 11, 11, wood_d, ink)
			_px_rect(img, 76, 11, 7, 7, cream)
			_px_rect(img, 77, 12, 5, 1, steel_d)
			_px_rect(img, 77, 14, 5, 1, red_bfp)
			# Telefone vermelho de emergência + luminária de mesa à direita
			_outline_rect(img, 89, 10, 12, 9, red_bfp, ink)
			_px_rect(img, 88, 9, 14, 3, red_dark)
			_px_rect(img, 92, 13, 6, 3, cream)
			_outline_rect(img, 106, 2, 10, 6, gold_bfp, ink)
			_px_rect(img, 110, 8, 2, 8, steel_d)
			_outline_rect(img, 106, 15, 10, 4, steel_d, ink)
		"bfp_chief_chair":
			img = Image.create_empty(22, 26, false, Image.FORMAT_RGBA8)
			img.fill(Color(0, 0, 0, 0))
			_px_rect(img, 3, 22, 16, 3, shadow)
			_outline_rect(img, 4, 2, 14, 15, T.call(Color(0.22, 0.16, 0.18)), ink)
			_px_rect(img, 6, 4, 10, 4, red_dark)
			_outline_rect(img, 3, 14, 16, 7, T.call(Color(0.18, 0.14, 0.16)), ink)
			_px_rect(img, 9, 21, 4, 3, steel_d)
		"bfp_filing_cabinet":
			img = Image.create_empty(22, 34, false, Image.FORMAT_RGBA8)
			img.fill(Color(0, 0, 0, 0))
			_px_rect(img, 2, 30, 18, 3, shadow)
			_outline_rect(img, 2, 2, 18, 29, steel_d, ink)
			for i in range(3):
				var dy := 4 + i * 9
				_outline_rect(img, 4, dy, 14, 8, steel_l, ink)
				_px_rect(img, 9, dy + 2, 4, 2, gold_bfp)
				_px_rect(img, 8, dy + 5, 6, 1, ink)
		"bfp_radio_rack":
			img = Image.create_empty(24, 38, false, Image.FORMAT_RGBA8)
			img.fill(Color(0, 0, 0, 0))
			_px_rect(img, 2, 34, 20, 3, shadow)
			_outline_rect(img, 2, 4, 20, 31, steel_d, ink)
			_px_rect(img, 5, 0, 2, 5, steel_l)
			_px_rect(img, 17, 1, 2, 4, steel_l)
			_outline_rect(img, 4, 7, 16, 8, T.call(Color(0.16, 0.22, 0.24)), ink)
			_px_rect(img, 6, 9, 5, 3, Color(0.32, 0.94, 0.44) if not dist else Color(0.62, 0.58, 0.92))
			_px_rect(img, 13, 9, 5, 3, Color(0.96, 0.72, 0.22) if not dist else Color(0.74, 0.70, 0.96))
			for gy in [18, 20, 22, 24]:
				_px_rect(img, 5, gy, 14, 1, ink)
			_outline_rect(img, 5, 27, 14, 5, steel_l, ink)
		"bfp_tactical_map":
			img = Image.create_empty(54, 34, false, Image.FORMAT_RGBA8)
			img.fill(Color(0, 0, 0, 0))
			_outline_rect(img, 1, 1, 52, 32, wood_d, ink)
			_px_rect(img, 3, 3, 48, 28, T.call(Color(0.24, 0.42, 0.26)))
			# Costa oeste azul, areia, rua principal cinza e floresta leste
			_px_rect(img, 3, 3, 10, 28, T.call(Color(0.18, 0.40, 0.64)))
			_px_rect(img, 13, 3, 4, 28, T.call(Color(0.76, 0.68, 0.48)))
			_px_rect(img, 17, 15, 22, 4, T.call(Color(0.34, 0.36, 0.40)))
			_px_rect(img, 39, 3, 12, 28, T.call(Color(0.14, 0.30, 0.18)))
			# Pinos de ocorrência vermelhos/amarelos
			_px_rect(img, 24, 12, 3, 3, red_bfp)
			_px_rect(img, 43, 11, 3, 3, Color(0.98, 0.22, 0.18))
			_px_rect(img, 45, 21, 3, 3, gold_bfp if not dist else Color(0.68, 0.64, 0.94))
			if dist:
				_px_rect(img, 30, 8, 16, 16, Color(0.10, 0.09, 0.22, 0.58))
		"bfp_crest_banner":
			img = Image.create_empty(24, 34, false, Image.FORMAT_RGBA8)
			img.fill(Color(0, 0, 0, 0))
			_outline_rect(img, 2, 1, 20, 4, gold_bfp, ink)
			_outline_rect(img, 3, 5, 18, 25, red_bfp, ink)
			_px_rect(img, 5, 28, 14, 4, red_dark)
			_px_rect(img, 7, 30, 10, 3, gold_bfp)
			# Brasão central dourado BFP
			_outline_rect(img, 7, 9, 10, 12, gold_bfp, ink)
			_px_rect(img, 9, 11, 6, 8, red_dark)
			_px_rect(img, 11, 12, 2, 6, gold_bfp)
			_px_rect(img, 9, 14, 6, 2, gold_bfp)
		"bfp_roster_board":
			img = Image.create_empty(44, 32, false, Image.FORMAT_RGBA8)
			img.fill(Color(0, 0, 0, 0))
			_outline_rect(img, 1, 1, 42, 30, wood_m, ink)
			_px_rect(img, 3, 3, 38, 26, cream)
			_px_rect(img, 3, 3, 38, 5, red_bfp)
			for ry in [11, 16, 21, 25]:
				_px_rect(img, 5, ry, 14, 2, steel_d)
				_px_rect(img, 22, ry, 16, 2, T.call(Color(0.24, 0.46, 0.68)) if ry != 21 else red_bfp)
		"bfp_water_cooler":
			img = Image.create_empty(18, 34, false, Image.FORMAT_RGBA8)
			img.fill(Color(0, 0, 0, 0))
			_px_rect(img, 3, 30, 12, 3, shadow)
			_outline_rect(img, 3, 14, 12, 17, cream, ink)
			_px_rect(img, 5, 17, 3, 3, red_bfp)
			_px_rect(img, 10, 17, 3, 3, T.call(Color(0.20, 0.50, 0.86)))
			_outline_rect(img, 4, 2, 10, 12, T.call(Color(0.42, 0.74, 0.94)), ink)
			_px_rect(img, 6, 4, 2, 8, T.call(Color(0.74, 0.92, 1.0)))
		"bfp_manual_shelf":
			img = Image.create_empty(42, 36, false, Image.FORMAT_RGBA8)
			img.fill(Color(0, 0, 0, 0))
			_px_rect(img, 2, 32, 38, 3, shadow)
			_outline_rect(img, 2, 2, 38, 31, wood_d, ink)
			for sy in [5, 14, 23]:
				_px_rect(img, 4, sy + 6, 34, 2, wood_m)
				for bx in range(5):
					var bc: Color = red_bfp if (bx + sy) % 3 == 0 else (T.call(Color(0.22, 0.42, 0.66)) if bx % 2 == 0 else gold_bfp)
					_outline_rect(img, 5 + bx * 6, sy, 5, 7, bc, ink)
		"bfp_reception_counter_h":
			img = Image.create_empty(92, 36, false, Image.FORMAT_RGBA8)
			img.fill(Color(0, 0, 0, 0))
			_px_rect(img, 3, 31, 86, 4, shadow)
			_outline_rect(img, 2, 12, 88, 21, wood_d, ink)
			_outline_rect(img, 3, 10, 86, 8, wood_m, ink)
			_px_rect(img, 4, 22, 84, 3, red_bfp)
			_px_rect(img, 4, 25, 84, 1, gold_bfp)
			# Divisória superior de vidro + livro de ocorrências + telefone + rádio portátil
			_outline_rect(img, 8, 2, 38, 9, Color(0.70, 0.86, 0.94, 0.45), steel_d)
			_outline_rect(img, 50, 9, 14, 8, cream, ink)
			_px_rect(img, 56, 10, 2, 6, steel_d)
			_outline_rect(img, 68, 9, 10, 7, red_bfp, ink)
			_outline_rect(img, 81, 6, 6, 10, steel_d, ink)
			_px_rect(img, 83, 2, 2, 4, ink)
		"bfp_reception_counter_v":
			img = Image.create_empty(22, 48, false, Image.FORMAT_RGBA8)
			img.fill(Color(0, 0, 0, 0))
			_px_rect(img, 3, 44, 16, 3, shadow)
			_outline_rect(img, 2, 2, 18, 43, wood_d, ink)
			_outline_rect(img, 4, 4, 14, 35, wood_m, ink)
			_px_rect(img, 4, 39, 14, 3, red_bfp)
		"bfp_wait_chairs":
			img = Image.create_empty(68, 22, false, Image.FORMAT_RGBA8)
			img.fill(Color(0, 0, 0, 0))
			_px_rect(img, 3, 18, 62, 3, shadow)
			_px_rect(img, 4, 15, 60, 2, steel_d)
			for i in range(4):
				var cx := 4 + i * 16
				_outline_rect(img, cx, 2, 13, 8, red_bfp, ink)
				_outline_rect(img, cx, 9, 13, 6, red_dark, ink)
				_px_rect(img, cx + 2, 15, 2, 5, steel_d)
				_px_rect(img, cx + 9, 15, 2, 5, steel_d)
		"bfp_side_table_brochures":
			img = Image.create_empty(22, 20, false, Image.FORMAT_RGBA8)
			img.fill(Color(0, 0, 0, 0))
			_px_rect(img, 2, 17, 18, 2, shadow)
			_outline_rect(img, 2, 5, 18, 12, wood_m, ink)
			_px_rect(img, 3, 14, 3, 4, wood_d)
			_px_rect(img, 16, 14, 3, 4, wood_d)
			_px_rect(img, 5, 7, 5, 5, cream)
			_px_rect(img, 6, 8, 3, 2, red_bfp)
			_px_rect(img, 11, 8, 6, 4, gold_bfp)
		"bfp_potted_plant":
			img = Image.create_empty(18, 26, false, Image.FORMAT_RGBA8)
			img.fill(Color(0, 0, 0, 0))
			_px_rect(img, 3, 23, 12, 2, shadow)
			_outline_rect(img, 4, 15, 10, 9, T.call(Color(0.66, 0.34, 0.22)), ink)
			_outline_rect(img, 2, 5, 14, 11, T.call(Color(0.16, 0.44, 0.22)), ink)
			_px_rect(img, 5, 2, 8, 5, T.call(Color(0.24, 0.58, 0.28)))
		"bfp_alarm_bell":
			img = Image.create_empty(16, 18, false, Image.FORMAT_RGBA8)
			img.fill(Color(0, 0, 0, 0))
			_outline_rect(img, 3, 2, 10, 10, red_bfp, ink)
			_px_rect(img, 5, 4, 3, 3, T.call(Color(0.98, 0.56, 0.46)))
			_px_rect(img, 7, 12, 2, 4, steel_l)
			_px_rect(img, 6, 15, 4, 2, gold_bfp)
		"bfp_safety_posters":
			img = Image.create_empty(40, 26, false, Image.FORMAT_RGBA8)
			img.fill(Color(0, 0, 0, 0))
			_outline_rect(img, 1, 1, 38, 24, wood_d, ink)
			_px_rect(img, 3, 3, 34, 20, T.call(Color(0.56, 0.44, 0.30)))
			# Cartaz 1 (Extintor) + Cartaz 2 (Rota de Fuga) + Cartaz 3 (Emergência)
			_outline_rect(img, 5, 5, 9, 15, cream, ink)
			_px_rect(img, 8, 8, 3, 7, red_bfp)
			_outline_rect(img, 16, 5, 10, 15, T.call(Color(0.22, 0.54, 0.32)), ink)
			_px_rect(img, 18, 9, 6, 2, cream)
			_outline_rect(img, 28, 5, 8, 12, gold_bfp, ink)
			_px_rect(img, 30, 8, 4, 4, red_bfp)
		"bfp_hazard_strip":
			img = Image.create_empty(56, 8, false, Image.FORMAT_RGBA8)
			img.fill(Color(0, 0, 0, 0))
			_outline_rect(img, 0, 0, 56, 8, gold_bfp, ink)
			for hx in range(2, 54, 8):
				_px_rect(img, hx, 1, 4, 6, ink)
		"bfp_door_jamb":
			img = Image.create_empty(12, 28, false, Image.FORMAT_RGBA8)
			img.fill(Color(0, 0, 0, 0))
			_outline_rect(img, 1, 1, 10, 26, steel_d, ink)
			_px_rect(img, 3, 3, 6, 22, steel_l)
			_px_rect(img, 3, 18, 6, 4, red_bfp)
		"bfp_footlocker":
			img = Image.create_empty(34, 18, false, Image.FORMAT_RGBA8)
			img.fill(Color(0, 0, 0, 0))
			_px_rect(img, 2, 15, 30, 2, shadow)
			_outline_rect(img, 2, 3, 30, 13, red_dark, ink)
			_px_rect(img, 3, 4, 28, 4, red_bfp)
			_px_rect(img, 15, 7, 4, 3, gold_bfp)
		"bfp_nightstand":
			img = Image.create_empty(18, 22, false, Image.FORMAT_RGBA8)
			img.fill(Color(0, 0, 0, 0))
			_px_rect(img, 2, 19, 14, 2, shadow)
			_outline_rect(img, 2, 4, 14, 16, wood_m, ink)
			_outline_rect(img, 4, 11, 10, 6, wood_d, ink)
			_px_rect(img, 8, 13, 2, 2, gold_bfp)
			_px_rect(img, 5, 5, 7, 3, cream)
		"bfp_boots_pair":
			img = Image.create_empty(18, 12, false, Image.FORMAT_RGBA8)
			img.fill(Color(0, 0, 0, 0))
			_px_rect(img, 1, 9, 16, 2, shadow)
			_outline_rect(img, 2, 2, 6, 8, T.call(Color(0.14, 0.14, 0.18)), ink)
			_outline_rect(img, 10, 2, 6, 8, T.call(Color(0.14, 0.14, 0.18)), ink)
			_px_rect(img, 3, 7, 4, 2, gold_bfp)
			_px_rect(img, 11, 7, 4, 2, gold_bfp)
		"bfp_med_cabinet":
			img = Image.create_empty(26, 26, false, Image.FORMAT_RGBA8)
			img.fill(Color(0, 0, 0, 0))
			_outline_rect(img, 1, 1, 24, 24, cream, ink)
			_px_rect(img, 3, 3, 20, 20, T.call(Color(0.96, 0.96, 0.96)))
			# Cruz vermelha de primeiros socorros
			_px_rect(img, 11, 6, 4, 14, Color(0.84, 0.12, 0.14))
			_px_rect(img, 6, 11, 14, 4, Color(0.84, 0.12, 0.14))
			_px_rect(img, 21, 12, 2, 4, steel_d)
		"bfp_med_cart":
			img = Image.create_empty(26, 30, false, Image.FORMAT_RGBA8)
			img.fill(Color(0, 0, 0, 0))
			_px_rect(img, 2, 26, 22, 3, shadow)
			_outline_rect(img, 2, 6, 22, 20, steel_l, ink)
			_px_rect(img, 4, 14, 18, 2, steel_d)
			_px_rect(img, 4, 22, 18, 2, steel_d)
			_outline_rect(img, 4, 3, 8, 6, cream, ink)
			_px_rect(img, 7, 4, 2, 4, red_bfp)
			_outline_rect(img, 14, 4, 7, 5, red_bfp, ink)
			_px_rect(img, 4, 26, 3, 3, ink)
			_px_rect(img, 19, 26, 3, 3, ink)
		"bfp_coffee_table":
			img = Image.create_empty(48, 30, false, Image.FORMAT_RGBA8)
			img.fill(Color(0, 0, 0, 0))
			_px_rect(img, 3, 26, 42, 3, shadow)
			_outline_rect(img, 2, 9, 44, 17, wood_m, ink)
			_px_rect(img, 4, 22, 4, 5, wood_d)
			_px_rect(img, 40, 22, 4, 5, wood_d)
			# Garrafa térmica prateada/vermelha + 3 canecas + bloco de plantão
			_outline_rect(img, 7, 2, 8, 12, steel_l, ink)
			_px_rect(img, 8, 2, 6, 3, red_bfp)
			_outline_rect(img, 18, 7, 5, 6, cream, ink)
			_outline_rect(img, 25, 7, 5, 6, red_bfp, ink)
			_outline_rect(img, 32, 8, 5, 5, gold_bfp, ink)
			_px_rect(img, 39, 10, 5, 5, cream)
		"bfp_wall_clock":
			img = Image.create_empty(16, 16, false, Image.FORMAT_RGBA8)
			img.fill(Color(0, 0, 0, 0))
			_outline_rect(img, 2, 2, 12, 12, steel_d, ink)
			_px_rect(img, 4, 4, 8, 8, cream)
			_px_rect(img, 7, 5, 2, 4, ink)
			_px_rect(img, 7, 8, 4, 1, red_bfp)
		"bfp_curtained_window":
			img = Image.create_empty(36, 44, false, Image.FORMAT_RGBA8)
			img.fill(Color(0, 0, 0, 0))
			_outline_rect(img, 2, 2, 32, 40, wood_d, ink)
			_px_rect(img, 5, 5, 26, 34, T.call(Color(0.56, 0.72, 0.82)))
			# Persianas / cortinas laterais
			for by in range(7, 24, 3):
				_px_rect(img, 5, by, 26, 1, T.call(Color(0.80, 0.82, 0.78)))
			_outline_rect(img, 3, 4, 7, 36, T.call(Color(0.32, 0.44, 0.56)), ink)
			_outline_rect(img, 26, 4, 7, 36, T.call(Color(0.32, 0.44, 0.56)), ink)
	return img


static func _build_pusa_cat_frame_image(frame_idx: int, dist: bool) -> Image:
	## Pusa (gato preto de estimação de Huwag), 24x20 pixel art detalhada com calda animada, orelhas e piscar.
	var img := Image.create_empty(24, 20, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var ink := Color(0.03, 0.03, 0.06, 1.0)
	var fur_dk := Color(0.10, 0.10, 0.14, 1.0) if not dist else Color(0.04, 0.04, 0.08, 1.0)
	var fur_md := Color(0.18, 0.18, 0.24, 1.0) if not dist else Color(0.09, 0.08, 0.15, 1.0)
	var fur_hi := Color(0.28, 0.28, 0.36, 1.0) if not dist else Color(0.18, 0.16, 0.28, 1.0)
	var ear_in := Color(0.46, 0.30, 0.34, 1.0) if not dist else Color(0.24, 0.20, 0.36, 1.0)
	var eye_c := Color(0.95, 0.84, 0.30, 1.0) if not dist else Color(0.84, 0.80, 0.98, 1.0)
	var collar_c := Color(0.76, 0.26, 0.24, 1.0) if not dist else Color(0.36, 0.30, 0.58, 1.0)

	# Sombra suave no piso
	_px_rect(img, 3, 16, 17, 3, Color(0.02, 0.02, 0.04, 0.48))

	# Rabo curvado animado (oscila suavemente nos frames 0..3)
	var tail_dy := -1 if (frame_idx == 1 or frame_idx == 2) else 0
	var tail_tip_y := 8 + ( -2 if frame_idx == 1 else (-1 if frame_idx == 2 else 0) )
	_px_rect(img, 14, 14, 4, 2, ink)
	_px_rect(img, 14, 14, 3, 1, fur_dk)
	_px_rect(img, 17, 11 + tail_dy, 3, 4, ink)
	_px_rect(img, 18, 11 + tail_dy, 1, 3, fur_md)
	_px_rect(img, 18, tail_tip_y, 3, 3, ink)
	_px_rect(img, 19, tail_tip_y + 1, 1, 1, fur_hi)

	# Corpo sentado compacto
	var chest_dy := 1 if frame_idx == 2 else 0
	_outline_rect(img, 5, 9 + chest_dy, 10, 9 - chest_dy, fur_dk, ink)
	_px_rect(img, 6, 10 + chest_dy, 7, 6 - chest_dy, fur_md)
	# Patinhas dianteiras e peito
	_px_rect(img, 6, 16, 2, 2, ink)
	_px_rect(img, 11, 16, 2, 2, ink)
	_px_rect(img, 7, 16, 1, 1, fur_hi)
	_px_rect(img, 11, 16, 1, 1, fur_hi)
	# Coleira discreta com guizo
	_px_rect(img, 6, 9 + chest_dy, 8, 1, collar_c)
	_px_rect(img, 9, 10 + chest_dy, 2, 1, Color(0.94, 0.84, 0.36) if not dist else Color(0.76, 0.72, 0.94))

	# Cabeça redonda e orelhas pontudas (orelha direita mexe levemente no frame 1)
	_outline_rect(img, 4, 3, 11, 7, fur_md, ink)
	_px_rect(img, 6, 4, 7, 2, fur_hi)
	# Orelha esquerda
	_px_rect(img, 4, 1, 3, 3, ink)
	_px_rect(img, 5, 2, 1, 2, ear_in)
	# Orelha direita
	var r_ear_y := 2 if frame_idx == 1 else 1
	_px_rect(img, 12, r_ear_y, 3, 3, ink)
	_px_rect(img, 13, r_ear_y + 1, 1, 1, ear_in)

	# Olhos dourados (piscam fechados brevemente no frame 3) & focinho
	if frame_idx == 3:
		_px_rect(img, 6, 6, 2, 1, ink)
		_px_rect(img, 11, 6, 2, 1, ink)
	else:
		_px_rect(img, 6, 5, 2, 2, eye_c)
		_px_rect(img, 11, 5, 2, 2, eye_c)
		_px_rect(img, 6, 6, 1, 1, ink)
		_px_rect(img, 11, 6, 1, 1, ink)
	_px_rect(img, 9, 7, 1, 1, Color(0.68, 0.44, 0.48) if not dist else Color(0.46, 0.42, 0.68))
	return img


static func build_pusa_cat_frames(distorted: bool = false) -> SpriteFrames:
	var sf := SpriteFrames.new()
	if not sf.has_animation("idle"):
		sf.add_animation("idle")
	sf.set_animation_loop("idle", true)
	sf.set_animation_speed("idle", 2.8)
	# Sequência natural: 0 (alerta), 1 (orelha+rabo), 0 (pausa), 2 (respira+rabo), 0 (pausa), 3 (piscada rápida)
	var seq := [0, 1, 0, 2, 0, 3]
	var tex_cache := {}
	for f in range(4):
		tex_cache[f] = ImageTexture.create_from_image(_build_pusa_cat_frame_image(f, distorted))
	for f_id in seq:
		sf.add_frame("idle", tex_cache[f_id])
	return sf

