class_name HuwagUiTheme
extends RefCounted

## Sistema visual unificado estilo OMORI para UI de HUWAG:
## Fundo preto sólido (#000000), bordas brancas duplas/rabiscadas à mão (sketchy hand-drawn),
## fonte personalizada OMORI PT-BR e zero excesso vermelho-sangue no Modo Corrompido.

const UI_FONT_PATH := "res://assets/fonts/omori_dialogue_font.tres"
const TITLE_FONT_PATH := "res://assets/fonts/OMORI_GAME.ttf"

static var _ui_font_cache: Font = null
static var _title_font_cache: Font = null
static var _sketch_tex_cache: Dictionary = {}
static var _hand_cursor_cache: ImageTexture = null

const PALETTE_NORMAL := {
	"bg": Color("#000000", 0.98),
	"bg_soft": Color("#000000", 0.93),
	"bg_inner": Color("#000000", 0.99),
	"border": Color("#FFFFFF", 1.0),
	"trim": Color("#E6E8EE", 0.95),
	"trim_dark": Color("#1E2028", 0.95),
	"text": Color("#FFFFFF", 1.0),
	"text_muted": Color("#B8BDC9", 1.0),
	"text_shadow": Color("#000000", 0.95),
	"accent": Color("#FFFFFF", 1.0),
	"cursor": Color("#FFFFFF", 1.0),
	"choice_bg": Color("#000000", 0.98),
	"choice_sel_bg": Color("#1C1D24", 0.98),
	"choice_sel_border": Color("#FFFFFF", 1.0),
}

const PALETTE_ACT3 := {
	"bg": Color("#000000", 0.98),
	"bg_soft": Color("#000000", 0.93),
	"bg_inner": Color("#000000", 0.99),
	"border": Color("#D4D8E2", 1.0),
	"trim": Color("#B6BCC9", 0.95),
	"trim_dark": Color("#1A1C22", 0.95),
	"text": Color("#E8ECF2", 1.0),
	"text_muted": Color("#8C94A4", 1.0),
	"text_shadow": Color("#000000", 0.95),
	"accent": Color("#FFFFFF", 1.0),
	"cursor": Color("#E8ECF2", 1.0),
	"choice_bg": Color("#000000", 0.98),
	"choice_sel_bg": Color("#191C22", 0.98),
	"choice_sel_border": Color("#E8ECF2", 1.0),
}

const PALETTE_DISTORTED := {
	"bg": Color("#000000", 0.98),
	"bg_soft": Color("#040308", 0.94),
	"bg_inner": Color("#020206", 0.99),
	"border": Color("#DED8F4", 1.0),
	"trim": Color("#A99ED0", 0.95),
	"trim_dark": Color("#171324", 0.95),
	"text": Color("#F2EEFF", 1.0),
	"text_muted": Color("#A59BC2", 1.0),
	"text_shadow": Color("#05030C", 0.98),
	"accent": Color("#D8CBFF", 1.0),
	"cursor": Color("#DED8F4", 1.0),
	"choice_bg": Color("#040308", 0.98),
	"choice_sel_bg": Color("#1C172B", 0.98),
	"choice_sel_border": Color("#E4DDF8", 1.0),
}


static func get_ui_font() -> Font:
	if _ui_font_cache == null and ResourceLoader.exists(UI_FONT_PATH):
		_ui_font_cache = load(UI_FONT_PATH) as Font
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


static func _get_sketchy_box_texture(bg_col: Color, border_col: Color) -> ImageTexture:
	var key := "%s|%s" % [bg_col.to_html(true), border_col.to_html(true)]
	if _sketch_tex_cache.has(key):
		return _sketch_tex_cache[key] as ImageTexture

	var size := 48
	var img := Image.create_empty(size, size, false, Image.FORMAT_RGBA8)
	img.fill(bg_col)

	var line_main := border_col
	var line_soft := Color(border_col.r, border_col.g, border_col.b, 0.72)
	var gap_black := Color(0.0, 0.0, 0.0, maxf(0.96, bg_col.a))
	var edge_outer := Color(0.0, 0.0, 0.0, 0.92)

	# 1px dark outer hairline for clean contrast against bright tiles
	for i in range(size):
		img.set_pixel(i, 0, edge_outer)
		img.set_pixel(i, size - 1, edge_outer)
		img.set_pixel(0, i, edge_outer)
		img.set_pixel(size - 1, i, edge_outer)

	# Primary sketchy white double-border (Omori hand-drawn irregularity on 1px scale)
	for i in range(1, size - 1):
		var jitter_t := 0 if ((i * 7 + 3) % 11 != 0) else 1
		var jitter_b := 0 if ((i * 5 + 2) % 13 != 0) else 1
		var jitter_l := 0 if ((i * 9 + 1) % 12 != 0) else 1
		var jitter_r := 0 if ((i * 3 + 7) % 10 != 0) else 1

		# Top border (rows 1..3)
		img.set_pixel(i, 1 + jitter_t, line_main)
		img.set_pixel(i, 2, line_main)
		if (i % 9) in [0, 1, 2]:
			img.set_pixel(i, 3, line_soft)

		# Bottom border (rows size-4..size-2)
		img.set_pixel(i, size - 2 - jitter_b, line_main)
		img.set_pixel(i, size - 3, line_main)
		if (i % 8) in [0, 1]:
			img.set_pixel(i, size - 4, line_soft)

		# Left border (cols 1..3)
		img.set_pixel(1 + jitter_l, i, line_main)
		img.set_pixel(2, i, line_main)
		if (i % 10) in [0, 1]:
			img.set_pixel(3, i, line_soft)

		# Right border (cols size-4..size-2)
		img.set_pixel(size - 2 - jitter_r, i, line_main)
		img.set_pixel(size - 3, i, line_main)
		if (i % 7) in [0, 1]:
			img.set_pixel(size - 4, i, line_soft)

	# Inner separation trench + thin secondary sketch hairline inside (rows/cols 4..5)
	for i in range(4, size - 4):
		img.set_pixel(i, 4, gap_black)
		img.set_pixel(i, size - 5, gap_black)
		img.set_pixel(4, i, gap_black)
		img.set_pixel(size - 5, i, gap_black)
		if (i % 5) != 2:
			img.set_pixel(i, 5, Color(border_col.r, border_col.g, border_col.b, 0.34))
			img.set_pixel(i, size - 6, Color(border_col.r, border_col.g, border_col.b, 0.34))
			img.set_pixel(5, i, Color(border_col.r, border_col.g, border_col.b, 0.34))
			img.set_pixel(size - 6, i, Color(border_col.r, border_col.g, border_col.b, 0.34))

	# Clean squared corners
	for cpos in [Vector2i(1, 1), Vector2i(size - 3, 1), Vector2i(1, size - 3), Vector2i(size - 3, size - 3)]:
		img.set_pixel(cpos.x, cpos.y, line_main)
		img.set_pixel(cpos.x + 1, cpos.y, line_main)
		img.set_pixel(cpos.x, cpos.y + 1, line_main)
		img.set_pixel(cpos.x + 1, cpos.y + 1, line_main)

	var tex := ImageTexture.create_from_image(img)
	_sketch_tex_cache[key] = tex
	return tex


static func make_omori_box_style(
	bg_col: Color = Color(0.0, 0.0, 0.0, 0.98),
	border_col: Color = Color(1.0, 1.0, 1.0, 1.0),
	pad_h: int = 8,
	pad_v: int = 6
) -> StyleBoxTexture:
	var sb := StyleBoxTexture.new()
	sb.texture = _get_sketchy_box_texture(bg_col, border_col)
	sb.texture_margin_left = 7.0
	sb.texture_margin_top = 7.0
	sb.texture_margin_right = 7.0
	sb.texture_margin_bottom = 7.0
	sb.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_TILE
	sb.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_TILE
	sb.content_margin_left = float(pad_h)
	sb.content_margin_right = float(pad_h)
	sb.content_margin_top = float(pad_v)
	sb.content_margin_bottom = float(pad_v)
	return sb


static func make_box_style(
	bg_col: Color,
	border_col: Color,
	_border_w: int = 1,
	pad_h: int = 0,
	pad_v: int = 0
) -> StyleBox:
	return make_omori_box_style(bg_col, border_col, pad_h, pad_v)


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
