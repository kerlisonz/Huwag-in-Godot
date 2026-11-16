class_name HuwagUiTheme
extends RefCounted

## Sistema visual unificado de UI minimalista (1px border, cantos retos 0px, Nearest Neighbor)
## Inspirado no layout retangular de referência adaptado ao tom VHS sombrio de HUWAG.

const PALETTE_NORMAL := {
	"bg": Color("#19212D", 0.96),
	"bg_soft": Color("#19212D", 0.88),
	"bg_inner": Color("#111722", 0.98),
	"border": Color("#07090D", 1.0),
	"trim": Color("#2E3D52", 0.90),
	"trim_dark": Color("#0F151F", 0.95),
	"text": Color("#E4EBF2", 1.0),
	"text_muted": Color("#9FB1C4", 1.0),
	"text_shadow": Color("#090C12", 0.95),
	"accent": Color("#F5C84B", 1.0),
	"cursor": Color("#E4EBF2", 1.0),
	"choice_bg": Color("#141B26", 0.96),
	"choice_sel_bg": Color("#243145", 0.98),
	"choice_sel_border": Color("#8AA3C4", 1.0),
}

const PALETTE_ACT3 := {
	"bg": Color("#1E2229", 0.96),
	"bg_soft": Color("#1E2229", 0.88),
	"bg_inner": Color("#14171D", 0.98),
	"border": Color("#08090C", 1.0),
	"trim": Color("#3B424F", 0.90),
	"trim_dark": Color("#111318", 0.95),
	"text": Color("#E2E8F0", 1.0),
	"text_muted": Color("#9AA4B2", 1.0),
	"text_shadow": Color("#08090D", 0.95),
	"accent": Color("#CBD5E1", 1.0),
	"cursor": Color("#E2E8F0", 1.0),
	"choice_bg": Color("#181B21", 0.96),
	"choice_sel_bg": Color("#2B313B", 0.98),
	"choice_sel_border": Color("#9AA4B2", 1.0),
}

const PALETTE_DISTORTED := {
	"bg": Color("#22070D", 0.97),
	"bg_soft": Color("#22070D", 0.91),
	"bg_inner": Color("#140307", 0.99),
	"border": Color("#050002", 1.0),
	"trim": Color("#691522", 0.95),
	"trim_dark": Color("#160206", 0.98),
	"text": Color("#F5D8DC", 1.0),
	"text_muted": Color("#D9828D", 1.0),
	"text_shadow": Color("#120104", 0.98),
	"accent": Color("#FF5A67", 1.0),
	"cursor": Color("#E63946", 1.0),
	"choice_bg": Color("#1A050A", 0.97),
	"choice_sel_bg": Color("#380C16", 0.98),
	"choice_sel_border": Color("#E63946", 1.0),
}


static func get_palette(mode: String) -> Dictionary:
	match mode:
		"distorted":
			return PALETTE_DISTORTED
		"act3":
			return PALETTE_ACT3
		_:
			return PALETTE_NORMAL


static func make_box_style(
	bg_col: Color,
	border_col: Color,
	border_w: int = 1,
	pad_h: int = 0,
	pad_v: int = 0
) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg_col
	sb.border_color = border_col
	sb.set_border_width_all(border_w)
	sb.set_corner_radius_all(0)
	sb.corner_detail = 1
	sb.anti_aliasing = false
	sb.content_margin_left = pad_h
	sb.content_margin_right = pad_h
	sb.content_margin_top = pad_v
	sb.content_margin_bottom = pad_v
	return sb


static func build_heart_textures() -> Dictionary:
	## Gera 3 texturas pixel-art 13x12 (full, half, empty) com contorno crisp de 1px.
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
	var out_col := Color("#07090D")
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


static func build_down_arrow_texture(fill_col: Color, border_col: Color = Color("#07090D")) -> Texture2D:
	## Triângulo pixel-art 9x6 nítido para o indicador animado ▼ no canto inferior direito.
	var rows: Array[String] = [
		"kkkkkkkkk",
		"kfffffffk",
		".kfffffk.",
		"..kfffk..",
		"...kfk...",
		"....k....",
	]
	var img := Image.create(9, 6, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in range(6):
		var line: String = rows[y]
		for x in range(9):
			var ch := line[x]
			if ch == "k":
				img.set_pixel(x, y, border_col)
			elif ch == "f":
				img.set_pixel(x, y, fill_col)
	return ImageTexture.create_from_image(img)
