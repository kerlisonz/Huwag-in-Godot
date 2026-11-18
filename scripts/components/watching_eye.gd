extends Sprite2D
class_name WatchingEye

## Olho observador do Modo Corrompido (estilo 16-bit / Yume Nikki):
## Esclera fixa em Sprite2D + pupila filha que rastreia dinamicamente player.global_position
## com deslocamento limitado (clamp) e arredondado para pixels inteiros (TEXTURE_FILTER_NEAREST).

@export var max_offset: Vector2 = Vector2(4.0, 2.0)
@export var tracking_distance_scale: float = 36.0

var pupil_sprite: Sprite2D = null
var pupil_offset: Vector2 = Vector2.ZERO

static var _sclera_tex: ImageTexture = null
static var _pupil_tex: ImageTexture = null


func _init() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	texture = _get_sclera_texture()
	_ensure_pupil_node()


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if texture == null:
		texture = _get_sclera_texture()
	_ensure_pupil_node()
	set_process(true)


func _ensure_pupil_node() -> void:
	if pupil_sprite != null and is_instance_valid(pupil_sprite):
		return
	pupil_sprite = get_node_or_null("PupilSprite") as Sprite2D
	if pupil_sprite == null:
		pupil_sprite = Sprite2D.new()
		pupil_sprite.name = "PupilSprite"
		add_child(pupil_sprite)
	pupil_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	pupil_sprite.texture = _get_pupil_texture()
	pupil_sprite.position = pupil_offset


func _process(_delta: float) -> void:
	if not is_visible_in_tree():
		return
	var tree := get_tree()
	if tree == null:
		return
	var player := tree.get_first_node_in_group("player") as Node2D
	if player != null and is_instance_valid(player):
		update_tracking_for_position(player.global_position)


func update_tracking_for_position(target_global_pos: Vector2) -> Vector2:
	_ensure_pupil_node()
	var delta_vec := target_global_pos - global_position
	if delta_vec.length_squared() < 0.001:
		pupil_offset = Vector2.ZERO
	else:
		var dir := delta_vec.normalized()
		var strength := clampf(delta_vec.length() / maxf(1.0, tracking_distance_scale), 0.0, 1.0)
		var raw := Vector2(dir.x * max_offset.x, dir.y * max_offset.y) * strength
		var clamped := Vector2(
			clampf(raw.x, -max_offset.x, max_offset.x),
			clampf(raw.y, -max_offset.y, max_offset.y)
		)
		pupil_offset = Vector2(roundf(clamped.x), roundf(clamped.y))
	if pupil_sprite != null:
		pupil_sprite.position = pupil_offset
	return pupil_offset


static func _get_sclera_texture() -> ImageTexture:
	if _sclera_tex != null:
		return _sclera_tex
	var img := Image.create_empty(24, 16, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var outline := Color(0.08, 0.05, 0.09, 0.96)
	var sclera_edge := Color(0.74, 0.68, 0.72, 0.96)
	var sclera_inner := Color(0.90, 0.88, 0.85, 0.98)
	var vein := Color(0.68, 0.22, 0.28, 0.92)

	# Contorno amendoado 16-bit
	_fill_rect(img, 3, 6, 18, 4, outline)
	_fill_rect(img, 5, 4, 14, 8, outline)
	_fill_rect(img, 7, 3, 10, 10, outline)

	# Esclera clara com borda sombreada e veias sutis nos cantos
	_fill_rect(img, 4, 6, 16, 4, sclera_edge)
	_fill_rect(img, 6, 5, 12, 6, sclera_inner)
	_fill_rect(img, 8, 4, 8, 8, sclera_inner)
	_fill_rect(img, 5, 7, 2, 1, vein)
	_fill_rect(img, 17, 8, 2, 1, vein)

	_sclera_tex = ImageTexture.create_from_image(img)
	return _sclera_tex


static func _get_pupil_texture() -> ImageTexture:
	if _pupil_tex != null:
		return _pupil_tex
	var img := Image.create_empty(8, 8, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var iris := Color(0.68, 0.12, 0.18, 1.0)
	var iris_hi := Color(0.86, 0.26, 0.30, 1.0)
	var pupil := Color(0.05, 0.04, 0.07, 1.0)
	var glint := Color(0.96, 0.94, 0.92, 1.0)

	_fill_rect(img, 2, 1, 4, 6, iris)
	_fill_rect(img, 1, 2, 6, 4, iris)
	_fill_rect(img, 2, 2, 2, 2, iris_hi)
	_fill_rect(img, 3, 2, 2, 4, pupil)
	img.set_pixel(2, 2, glint)

	_pupil_tex = ImageTexture.create_from_image(img)
	return _pupil_tex


static func _fill_rect(img: Image, x0: int, y0: int, w: int, h: int, col: Color) -> void:
	for y in range(maxi(0, y0), mini(img.get_height(), y0 + h)):
		for x in range(maxi(0, x0), mini(img.get_width(), x0 + w)):
			img.set_pixel(x, y, col)
