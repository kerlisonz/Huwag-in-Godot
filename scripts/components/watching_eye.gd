class_name WatchingEye
extends Sprite2D

## Olho observador surreal do Modo Corrompido (16-bit):
## Esclera fixa com variantes visuais bizarras (sem vermelho sangrento) + pupila que
## rastreia player.global_position com piscadas orgânicas, dilatação por proximidade e tremor sutil.

@export var max_offset: Vector2 = Vector2(4.0, 2.0)
@export var tracking_distance_scale: float = 36.0
@export_range(0, 3) var eye_variant: int = 0
@export var blink_interval_min: float = 2.4
@export var blink_interval_max: float = 6.2
@export var enable_proximity_dilation: bool = true

var pupil_sprite: Sprite2D = null
var pupil_offset: Vector2 = Vector2.ZERO

var _blink_cooldown: float = 3.0
var _blink_timer: float = 0.0
var _tremor_phase: float = 0.0
var _base_scale: Vector2 = Vector2.ONE

static var _sclera_variants: Dictionary = {}
static var _pupil_variants: Dictionary = {}


func _init() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	texture = _get_sclera_texture(eye_variant)
	_ensure_pupil_node()


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_base_scale = scale
	if texture == null or eye_variant != 0:
		texture = _get_sclera_texture(eye_variant)
	_ensure_pupil_node()
	_blink_cooldown = randf_range(blink_interval_min, blink_interval_max)
	_tremor_phase = randf_range(0.0, TAU)
	set_process(true)


func set_variant(variant_idx: int) -> void:
	eye_variant = posmod(variant_idx, 4)
	texture = _get_sclera_texture(eye_variant)
	_ensure_pupil_node()
	if pupil_sprite:
		pupil_sprite.texture = _get_pupil_texture(eye_variant)


func _ensure_pupil_node() -> void:
	if pupil_sprite != null and is_instance_valid(pupil_sprite):
		return
	pupil_sprite = get_node_or_null("PupilSprite") as Sprite2D
	if pupil_sprite == null:
		pupil_sprite = Sprite2D.new()
		pupil_sprite.name = "PupilSprite"
		add_child(pupil_sprite)
	pupil_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	pupil_sprite.texture = _get_pupil_texture(eye_variant)
	pupil_sprite.position = pupil_offset


func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	_tremor_phase += delta * 14.0
	_update_blink(delta)
	var tree := get_tree()
	if tree == null:
		return
	var player := tree.get_first_node_in_group("player") as Node2D
	if player != null and is_instance_valid(player):
		update_tracking_for_position(player.global_position)


func _update_blink(delta: float) -> void:
	if _blink_timer > 0.0:
		_blink_timer -= delta
		var p := 1.0 - clampf(_blink_timer / 0.14, 0.0, 1.0)
		var shut := sin(p * PI)
		scale = Vector2(_base_scale.x, maxf(0.10, _base_scale.y * (1.0 - shut * 0.90)))
		if _blink_timer <= 0.0:
			scale = _base_scale
	else:
		_blink_cooldown -= delta
		if _blink_cooldown <= 0.0:
			_blink_timer = 0.14
			_blink_cooldown = randf_range(blink_interval_min, blink_interval_max)


func update_tracking_for_position(target_global_pos: Vector2) -> Vector2:
	_ensure_pupil_node()
	var delta_vec := target_global_pos - global_position
	var dist := delta_vec.length()
	if delta_vec.length_squared() < 0.001:
		pupil_offset = Vector2.ZERO
	else:
		var dir := delta_vec.normalized()
		var strength := clampf(dist / maxf(1.0, tracking_distance_scale), 0.0, 1.0)
		var raw := Vector2(dir.x * max_offset.x, dir.y * max_offset.y) * strength
		var clamped := Vector2(
			clampf(raw.x, -max_offset.x, max_offset.x),
			clampf(raw.y, -max_offset.y, max_offset.y)
		)
		pupil_offset = Vector2(roundf(clamped.x), roundf(clamped.y))
	if pupil_sprite != null:
		pupil_sprite.position = pupil_offset
		if enable_proximity_dilation:
			var dilate := 1.0 + clampf(1.0 - dist / 140.0, 0.0, 1.0) * 0.28
			pupil_sprite.scale = Vector2(dilate, dilate)
	return pupil_offset


static func _get_sclera_texture(variant_idx: int) -> ImageTexture:
	var key := posmod(variant_idx, 4)
	if _sclera_variants.has(key):
		return _sclera_variants[key] as ImageTexture
	var outline := Color(0.04, 0.03, 0.08, 0.98)
	var edge := Color(0.48, 0.45, 0.66, 0.96)
	var inner := Color(0.86, 0.85, 0.96, 0.98)
	var inner_shadow := Color(0.68, 0.65, 0.84, 0.96)

	var img := Image.create_empty(24, 16, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	match key:
		0:
			# Olho amplo clássico de pálpebra pesada
			_fill_rect(img, 3, 6, 18, 4, outline)
			_fill_rect(img, 5, 4, 14, 8, outline)
			_fill_rect(img, 7, 3, 10, 10, outline)
			_fill_rect(img, 4, 6, 16, 4, edge)
			_fill_rect(img, 6, 5, 12, 6, inner_shadow)
			_fill_rect(img, 8, 4, 8, 8, inner)
			_fill_rect(img, 7, 5, 10, 6, inner)
		1:
			# Olho redondo arregalado (surreal/pesadelo)
			_fill_rect(img, 4, 3, 16, 10, outline)
			_fill_rect(img, 6, 1, 12, 14, outline)
			_fill_rect(img, 3, 5, 18, 6, outline)
			_fill_rect(img, 5, 3, 14, 10, edge)
			_fill_rect(img, 7, 2, 10, 12, inner_shadow)
			_fill_rect(img, 6, 4, 12, 8, inner)
			_fill_rect(img, 8, 3, 8, 10, Color(0.95, 0.94, 1.0, 0.98))
		2:
			# Olho estreito e paranoico de canto de sombra
			_fill_rect(img, 2, 6, 20, 4, outline)
			_fill_rect(img, 5, 5, 14, 6, outline)
			_fill_rect(img, 3, 7, 18, 2, edge)
			_fill_rect(img, 6, 6, 12, 4, inner)
		_:
			# Par de olhinhos pequenos aglomerados nas trevas
			for ox in [0, 11]:
				_fill_rect(img, ox + 2, 5, 9, 6, outline)
				_fill_rect(img, ox + 3, 4, 7, 8, outline)
				_fill_rect(img, ox + 3, 6, 7, 4, edge)
				_fill_rect(img, ox + 4, 5, 5, 6, inner)

	var tex := ImageTexture.create_from_image(img)
	_sclera_variants[key] = tex
	return tex


static func _get_pupil_texture(variant_idx: int) -> ImageTexture:
	var key := posmod(variant_idx, 4)
	if _pupil_variants.has(key):
		return _pupil_variants[key] as ImageTexture
	var img := Image.create_empty(16, 12, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var iris := Color(0.32, 0.26, 0.58, 1.0)
	var iris_hi := Color(0.56, 0.50, 0.88, 1.0)
	var pupil := Color(0.03, 0.02, 0.06, 1.0)
	var glint := Color(0.96, 0.96, 1.0, 1.0)

	match key:
		0:
			_fill_rect(img, 6, 3, 4, 6, iris)
			_fill_rect(img, 5, 4, 6, 4, iris)
			_fill_rect(img, 6, 4, 2, 2, iris_hi)
			_fill_rect(img, 7, 4, 2, 4, pupil)
			img.set_pixel(6, 4, glint)
		1:
			# Pupila dilatada abissal + anel índigo hipnótico
			_fill_rect(img, 4, 2, 8, 8, iris)
			_fill_rect(img, 3, 3, 10, 6, iris)
			_fill_rect(img, 5, 3, 6, 6, pupil)
			img.set_pixel(5, 3, iris_hi)
			img.set_pixel(6, 3, glint)
		2:
			# Fenda fina observadora
			_fill_rect(img, 6, 3, 4, 6, iris)
			_fill_rect(img, 7, 3, 2, 6, pupil)
			img.set_pixel(7, 4, glint)
		_:
			# Duas pupilas sincronizadas
			for px in [1, 12]:
				_fill_rect(img, px, 4, 3, 4, iris)
				_fill_rect(img, px + 1, 5, 2, 2, pupil)
				img.set_pixel(px, 4, glint)

	var tex := ImageTexture.create_from_image(img)
	_pupil_variants[key] = tex
	return tex


static func _fill_rect(img: Image, x0: int, y0: int, w: int, h: int, col: Color) -> void:
	for y in range(maxi(0, y0), mini(img.get_height(), y0 + h)):
		for x in range(maxi(0, x0), mini(img.get_width(), x0 + w)):
			img.set_pixel(x, y, col)
