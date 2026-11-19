class_name HuwagUiTheme
extends RefCounted

## Sistema visual unificado estilo OMORI para UI de HUWAG:
## Fundo preto sólido (#000000), borda branca sólida e nítida com contorno externo preto de 1px
## e recuo interno preto de 1px (cantos retos 90°, zero tracejado), fonte vetorial OMORI PT-BR
## e zero excesso vermelho-sangue no Modo Corrompido.

const UI_FONT_PATH := "res://assets/fonts/omori_dialogue_font.tres"
const TITLE_FONT_PATH := "res://assets/fonts/OMORI_GAME_PTBR.ttf"

static var _ui_font_cache: Font = null
static var _title_font_cache: Font = null
static var _box_tex_cache: Dictionary = {}
static var _hand_cursor_cache: ImageTexture = null

const PALETTE_NORMAL := {
	"bg": Color("#000000", 1.0),
	"bg_soft": Color("#000000", 1.0),
	"bg_inner": Color("#000000", 1.0),
	"border": Color("#FFFFFF", 1.0),
	"trim": Color("#FFFFFF", 1.0),
	"trim_dark": Color("#1A1C24", 1.0),
	"text": Color("#FFFFFF", 1.0),
	"text_muted": Color("#B8BDC9", 1.0),
	"text_shadow": Color("#000000", 0.0),
	"accent": Color("#FFFFFF", 1.0),
	"cursor": Color("#FFFFFF", 1.0),
	"choice_bg": Color("#000000", 1.0),
	"choice_sel_bg": Color("#161820", 1.0),
	"choice_sel_border": Color("#FFFFFF", 1.0),
}

const PALETTE_ACT3 := {
	"bg": Color("#000000", 1.0),
	"bg_soft": Color("#000000", 1.0),
	"bg_inner": Color("#000000", 1.0),
	"border": Color("#D8DCE6", 1.0),
	"trim": Color("#C2C8D4", 1.0),
	"trim_dark": Color("#181A20", 1.0),
	"text": Color("#E8ECF2", 1.0),
	"text_muted": Color("#8C94A4", 1.0),
	"text_shadow": Color("#000000", 0.0),
	"accent": Color("#FFFFFF", 1.0),
	"cursor": Color("#E8ECF2", 1.0),
	"choice_bg": Color("#000000", 1.0),
	"choice_sel_bg": Color("#191C22", 1.0),
	"choice_sel_border": Color("#E8ECF2", 1.0),
}

const PALETTE_DISTORTED := {
	"bg": Color("#000000", 1.0),
	"bg_soft": Color("#000000", 1.0),
	"bg_inner": Color("#000000", 1.0),
	"border": Color("#DED8F4", 1.0),
	"trim": Color("#B6ACD8", 1.0),
	"trim_dark": Color("#171324", 1.0),
	"text": Color("#F2EEFF", 1.0),
	"text_muted": Color("#A59BC2", 1.0),
	"text_shadow": Color("#000000", 0.0),
	"accent": Color("#D8CBFF", 1.0),
	"cursor": Color("#DED8F4", 1.0),
	"choice_bg": Color("#000000", 1.0),
	"choice_sel_bg": Color("#1A1628", 1.0),
	"choice_sel_border": Color("#E4DDF8", 1.0),
}


static func get_ui_font() -> Font:
	if _ui_font_cache == null and ResourceLoader.exists(UI_FONT_PATH):
		_ui_font_cache = load(UI_FONT_PATH) as Font
	if _ui_font_cache == null and ResourceLoader.exists("res://assets/fonts/OMORI_GAME2_PTBR.ttf"):
		_ui_font_cache = load("res://assets/fonts/OMORI_GAME2_PTBR.ttf") as Font
	if _ui_font_cache == null and ResourceLoader.exists("res://assets/fonts/OMORI_GAME2.ttf"):
		_ui_font_cache = load("res://assets/fonts/OMORI_GAME2.ttf") as Font
	return _ui_font_cache


static func get_title_font() -> Font:
	if _title_font_cache == null and ResourceLoader.exists(TITLE_FONT_PATH):
		_title_font_cache = load(TITLE_FONT_PATH) as Font
	return _title_font_cache if _title_font_cache != null else get_ui_font()


static func get_palette(mode: String) -> Dictionary:
	match mode:
		"distorted":
			return PALETTE_DISTORTED
		"act3":
			return PALETTE_ACT3
		_:
			return PALETTE_NORMAL


static func _get_omori_box_texture(bg_col: Color, border_col: Color, border_w: int = 2) -> ImageTexture:
	var bw := clampi(border_w, 1, 4)
	var key := "%s|%s|%d" % [bg_col.to_html(true), border_col.to_html(true), bw]
	if _box_tex_cache.has(key):
		return _box_tex_cache[key] as ImageTexture

	## Moldura OMORI clássica (cantos retos 90°, zero tracejado, zero ruído):
	## - 1px externo preto sólido (#000000) para recorte nítido contra qualquer cenário
	## - `bw` px de borda branca sólida (#FFFFFF / border_col)
	## - 1px interno preto sólido (#000000) separando a borda do conteúdo/retrato
	## - Interior preto sólido (bg_col)
	var margin := 1 + bw + 1
	var size := margin * 2 + 8
	var img := Image.create_empty(size, size, false, Image.FORMAT_RGBA8)
	img.fill(bg_col)

	var outer_black := Color(0.0, 0.0, 0.0, 1.0)
	var inner_black := Color(0.0, 0.0, 0.0, 1.0)

	for y in range(size):
		for x in range(size):
			var dist := mini(mini(x, size - 1 - x), mini(y, size - 1 - y))
			if dist == 0:
				img.set_pixel(x, y, outer_black)
			elif dist <= bw:
				img.set_pixel(x, y, border_col)
			elif dist == bw + 1:
				img.set_pixel(x, y, inner_black)

	var tex := ImageTexture.create_from_image(img)
	_box_tex_cache[key] = tex
	return tex


static func make_omori_box_style(
	bg_col: Color = Color(0.0, 0.0, 0.0, 1.0),
	border_col: Color = Color(1.0, 1.0, 1.0, 1.0),
	pad_h: int = 8,
	pad_v: int = 6,
	border_w: int = 2
) -> StyleBoxTexture:
	var bw := clampi(border_w, 1, 4)
	var margin := float(1 + bw + 1)
	var sb := StyleBoxTexture.new()
	sb.texture = _get_omori_box_texture(bg_col, border_col, bw)
	sb.texture_margin_left = margin
	sb.texture_margin_top = margin
	sb.texture_margin_right = margin
	sb.texture_margin_bottom = margin
	sb.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	sb.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	sb.content_margin_left = float(pad_h)
	sb.content_margin_right = float(pad_h)
	sb.content_margin_top = float(pad_v)
	sb.content_margin_bottom = float(pad_v)
	return sb


static func make_box_style(
	bg_col: Color,
	border_col: Color,
	border_w: int = 2,
	pad_h: int = 0,
	pad_v: int = 0
) -> StyleBox:
	return make_omori_box_style(bg_col, border_col, pad_h, pad_v, border_w)


static func build_omori_hand_cursor_texture() -> Texture2D:
	if _hand_cursor_cache != null:
		return _hand_cursor_cache
	## Mãozinha pixel art estilo OMORI apontando para a direita (18x12) com punho vermelho/escuro
	var rows: Array[String] = [
		".......kkkk.......",
		"......kwwwwk......",
		"..rrrrkwwwwwkkkk..",
		".rkkkkkwwwwwwwwkk.",
		".rkwwwwwwwwwwwwwwk",
		".rkwwwwwwwkkkkkkk.",
		".rkwwwwwwwk.......",
		".rkwwwwwwk........",
		".rkkkkwwk.........",
		"..rrrrkkk.........",
		"..................",
		"..................",
	]
	var img := Image.create_empty(18, 12, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var k_col := Color("#08080C")
	var w_col := Color("#FFFFFF")
	var r_col := Color("#D9383A")
	for y in range(12):
		var line: String = rows[y]
		for x in range(18):
			var ch := line[x]
			if ch == "k":
				img.set_pixel(x, y, k_col)
			elif ch == "w":
				img.set_pixel(x, y, w_col)
			elif ch == "r":
				img.set_pixel(x, y, r_col)
	_hand_cursor_cache = ImageTexture.create_from_image(img)
	return _hand_cursor_cache


static func build_heart_textures() -> Dictionary:
	## Gera 3 texturas pixel-art 13x12 (full, half, empty) com contorno branco/escuro nítido.
	var mask: Array[String] = [
		"..kkk...kkk..",
		".k###k.k###k.",
		"k#####k#####k",
		"k###########k",
		"k###########k",
		"k###########k",
		".k#########k.",
		"..k#######k..",
		"...k#####k...",
		"....k###k....",
		".....k#k.....",
		"......k......",
	]
	var out_col := Color("#FFFFFF")
	var full_hi := Color("#FF949E")
	var full_mid := Color("#D92B3E")
	var full_sh := Color("#8A1422")
	var empty_mid := Color("#232A38")
	var empty_sh := Color("#161A24")
	var split_col := Color("#54101B")

	var result := {}
	for kind in ["full", "half", "empty"]:
		var img := Image.create(13, 12, false, Image.FORMAT_RGBA8)
		img.fill(Color(0, 0, 0, 0))
		for y in range(12):
			var row: String = mask[y]
			for x in range(13):
				var ch := row[x]
				if ch == ".":
					continue
				if ch == "k":
					img.set_pixel(x, y, out_col)
					continue
				var filled := false
				if kind == "full":
					filled = true
				elif kind == "half":
					filled = (x < 6)
				if kind == "half" and x == 6:
					img.set_pixel(x, y, split_col)
					continue
				if filled:
					if (y == 1 and (x == 2 or x == 3)) or (y == 2 and (x == 1 or x == 2)) or (y == 3 and x == 1):
						img.set_pixel(x, y, full_hi)
					elif y >= 7 or x >= 10:
						img.set_pixel(x, y, full_sh)
					else:
						img.set_pixel(x, y, full_mid)
				else:
					if y >= 7 or x >= 9:
						img.set_pixel(x, y, empty_sh)
					else:
						img.set_pixel(x, y, empty_mid)
		result[kind] = ImageTexture.create_from_image(img)
	return result


static func build_down_arrow_texture(_fill_col: Color, _border_col: Color = Color("#FFFFFF")) -> Texture2D:
	return build_omori_hand_cursor_texture()
