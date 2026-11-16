extends SceneTree

## Etapa 1 — Constrói a prancha comparativa completa dos novos portraits (Normal vs Corrompido + Expressões Huwag)
## Estilo Anexo 5 (48x48 nativo -> 96x96 2x Nearest) + Anexos 2, 3 e 4 para horror corrompido.
## Salva somente em staging (res://assets/sprites/portraits_v4_preview/) e no diretório de artefatos para aprovação.

const C := preload("res://scripts/tools/portraits_v4/v4_canvas.gd")
const Cast := preload("res://scripts/tools/portraits_v4/v4_cast_portraits.gd")

const PREVIEW_DIR := "res://assets/sprites/portraits_v4_preview"
const ARTIFACT_DIR := "C:/Users/SnyX/.gemini/antigravity/brain/6f04634a-b7d4-4d6f-9c20-24b6fdf404a0"

const FONT_3X5 := {
	"A": ["010","101","111","101","101"], "B": ["110","101","110","101","110"],
	"C": ["011","100","100","100","011"], "D": ["110","101","101","101","110"],
	"E": ["111","100","110","100","111"], "F": ["111","100","110","100","100"],
	"G": ["011","100","101","101","011"], "H": ["101","101","111","101","101"],
	"I": ["111","010","010","010","111"], "J": ["001","001","001","101","010"],
	"K": ["101","101","110","101","101"], "L": ["100","100","100","100","111"],
	"M": ["101","111","111","101","101"], "N": ["101","111","111","111","101"],
	"O": ["010","101","101","101","010"], "P": ["110","101","110","100","100"],
	"Q": ["010","101","101","011","001"], "R": ["110","101","110","101","101"],
	"S": ["011","100","010","001","110"], "T": ["111","010","010","010","010"],
	"U": ["101","101","101","101","111"], "V": ["101","101","101","101","010"],
	"W": ["101","101","111","111","101"], "X": ["101","101","010","101","101"],
	"Y": ["101","101","010","010","010"], "Z": ["111","001","010","100","111"],
	"0": ["111","101","101","101","111"], "1": ["010","110","010","010","111"],
	"2": ["110","001","010","100","111"], "3": ["110","001","110","001","110"],
	"4": ["101","101","111","001","001"], "5": ["111","100","110","001","110"],
	"6": ["011","100","111","101","111"], "7": ["111","001","010","010","010"],
	"8": ["111","101","111","101","111"], "9": ["111","101","111","001","110"],
	".": ["000","000","000","000","010"], "-": ["000","000","111","000","000"],
	"/": ["001","001","010","100","100"], " ": ["000","000","000","000","000"],
	":": ["000","010","000","010","000"], "_": ["000","000","000","000","111"],
}


func _draw_text(img: Image, text: String, x0: int, y0: int, col: Color, px_scale: int = 2) -> void:
	var up := text.to_upper()
	var cx := x0
	for i in range(up.length()):
		var ch := up[i]
		var glyph: Array = FONT_3X5.get(ch, FONT_3X5[" "])
		for row in range(5):
			var line_s: String = glyph[row]
			for c in range(3):
				if line_s[c] == "1":
					for sy in range(px_scale):
						for sx in range(px_scale):
							var px := cx + c * px_scale + sx
							var py := y0 + row * px_scale + sy
							if px >= 0 and py >= 0 and px < img.get_width() and py < img.get_height():
								img.set_pixel(px, py, col)
		cx += 4 * px_scale


func _save_96(slug: String, img96: Image) -> void:
	img96.save_png(ProjectSettings.globalize_path("%s/%s.png" % [PREVIEW_DIR, slug]))


func _render_pair_board(pairs: Array[Dictionary], cols_pairs: int, scale: int, out_path: String) -> void:
	var cell := C.SIZE
	var gap_in := 6
	var gap_pair := 18
	var pad := 18
	var lbl_h := 16
	var pair_w := cell * 2 + gap_in
	var pair_h := cell + lbl_h
	var rows := int(ceil(float(pairs.size()) / float(cols_pairs)))
	var w := pad * 2 + cols_pairs * pair_w + (cols_pairs - 1) * gap_pair
	var h := pad * 2 + rows * pair_h + (rows - 1) * 18
	var board := Image.create(w, h, false, Image.FORMAT_RGBA8)
	board.fill(Color("#121318"))

	for idx in range(pairs.size()):
		var p := pairs[idx]
		var r := idx / cols_pairs
		var c := idx % cols_pairs
		var x := pad + c * (pair_w + gap_pair)
		var y := pad + r * (pair_h + 18)
		var n_im: Image = p["normal"]
		var d_im: Image = p["corrupted"]
		board.blit_rect(n_im, Rect2i(0, 0, cell, cell), Vector2i(x, y))
		board.blit_rect(d_im, Rect2i(0, 0, cell, cell), Vector2i(x + cell + gap_in, y))
		_draw_text(board, str(p["label"]), x, y + cell + 4, Color("#E5E7EB"), 2)

	if scale > 1:
		board.resize(w * scale, h * scale, Image.INTERPOLATE_NEAREST)
	board.save_png(out_path)


func _render_huwag_board(rows_data: Array[Dictionary], scale: int, out_path: String) -> void:
	var cell := C.SIZE
	var gap := 8
	var pad := 18
	var lbl_h := 16
	var cols: int = rows_data[0]["items"].size()
	var w := pad * 2 + cols * cell + (cols - 1) * gap
	var h := pad * 2 + rows_data.size() * (cell + lbl_h + 16)
	var board := Image.create(w, h, false, Image.FORMAT_RGBA8)
	board.fill(Color("#121318"))

	for r in range(rows_data.size()):
		var y := pad + r * (cell + lbl_h + 16)
		var items: Array = rows_data[r]["items"]
		for c in range(items.size()):
			var x := pad + c * (cell + gap)
			var it: Dictionary = items[c]
			board.blit_rect(it["img"], Rect2i(0, 0, cell, cell), Vector2i(x, y))
			_draw_text(board, str(it["label"]), x, y + cell + 4, Color("#F3F4F6"), 2)

	if scale > 1:
		board.resize(w * scale, h * scale, Image.INTERPOLATE_NEAREST)
	board.save_png(out_path)


func _init() -> void:
	print("=== Etapa 1: Gerando Pranchas Comparativas Portraits V4 (Anexo 5 + Terror) ===")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(PREVIEW_DIR))

	var pairs: Array[Dictionary] = [
		{"label": "HUWAG CASUAL", "slug": "huwag_casual", "normal": Cast.build_huwag_portrait("casual", "neutral"), "corrupted": Cast.build_huwag_portrait("casual", "distorted")},
		{"label": "HUWAG BFP", "slug": "huwag_bfp", "normal": Cast.build_huwag_portrait("bfp", "neutral"), "corrupted": Cast.build_huwag_portrait("bfp", "distorted")},
		{"label": "CAP. REYES", "slug": "cap_reyes", "normal": Cast.build_cap_reyes(false), "corrupted": Cast.build_cap_reyes(true)},
		{"label": "BOMB. ATO", "slug": "bombeiro_ato", "normal": Cast.build_bombeiro_ato(false), "corrupted": Cast.build_bombeiro_ato(true)},
		{"label": "BOMB. SANTOS", "slug": "bombeiro_santos", "normal": Cast.build_bombeiro_santos(false), "corrupted": Cast.build_bombeiro_santos(true)},
		{"label": "ENF. MARIA", "slug": "enfermeira_maria", "normal": Cast.build_enfermeira_maria(false), "corrupted": Cast.build_enfermeira_maria(true)},
		{"label": "ALING NENA", "slug": "aling_nena", "normal": Cast.build_aling_nena(false), "corrupted": Cast.build_aling_nena(true)},
		{"label": "KUYA BEN", "slug": "kuya_ben", "normal": Cast.build_kuya_ben(false), "corrupted": Cast.build_kuya_ben(true)},
		{"label": "MANG TOMAS", "slug": "feirante", "normal": Cast.build_feirante(false), "corrupted": Cast.build_feirante(true)},
		{"label": "MANG CARDING", "slug": "mang_carding", "normal": Cast.build_mang_carding(false), "corrupted": Cast.build_mang_carding(true)},
		{"label": "TOBY", "slug": "toby", "normal": Cast.build_toby(false), "corrupted": Cast.build_toby(true)},
		{"label": "SRA. LUNINGN", "slug": "luningning", "normal": Cast.build_senhora_luningning(false), "corrupted": Cast.build_senhora_luningning(true)},
		{"label": "LOLA ROSA", "slug": "lola_rosa", "normal": Cast.build_lola_rosa(false), "corrupted": Cast.build_lola_rosa(true)},
		{"label": "VULTO BOSQUE", "slug": "vulto_bosque", "normal": Cast.build_vulto_bosque(false), "corrupted": Cast.build_vulto_bosque(true)},
		{"label": "GUARDIA LAGOA", "slug": "criatura_lagoa", "normal": Cast.build_criatura_lagoa(false), "corrupted": Cast.build_criatura_lagoa(true)},
		{"label": "SANTELMO", "slug": "santelmo", "normal": Cast.build_santelmo(false), "corrupted": Cast.build_santelmo(true)},
		{"label": "RADIO / VHS", "slug": "vhs_radio", "normal": Cast.build_vhs_radio(false), "corrupted": Cast.build_vhs_radio(true)},
	]

	for p in pairs:
		_save_96("%s_normal" % p["slug"], p["normal"])
		_save_96("%s_corrupted" % p["slug"], p["corrupted"])

	var exprs: Array[String] = ["neutral", "uneasy_smile", "worried", "tired", "surprised", "angry", "scared", "unfiltered", "distorted"]
	var huwag_rows: Array[Dictionary] = []
	for outfit in ["casual", "bfp"]:
		var items: Array[Dictionary] = []
		for ex in exprs:
			var im := Cast.build_huwag_portrait(outfit, ex)
			_save_96("huwag_%s_%s" % [outfit, ex], im)
			var short_lbl := ex.left(8).to_upper()
			items.append({"label": "%s %s" % [outfit.left(1).to_upper(), short_lbl], "img": im})
		huwag_rows.append({"outfit": outfit, "items": items})

	_render_pair_board(pairs, 3, 2, "%s/etapa1_portraits_elenco_comp.png" % ARTIFACT_DIR)
	_render_pair_board(pairs, 3, 1, "%s/etapa1_portraits_elenco_1x.png" % ARTIFACT_DIR)
	_render_huwag_board(huwag_rows, 2, "%s/etapa1_huwag_expressoes_comp.png" % ARTIFACT_DIR)
	_render_huwag_board(huwag_rows, 1, "%s/etapa1_huwag_expressoes_1x.png" % ARTIFACT_DIR)

	print("Gerados %d pares e %d expressoes em %s" % [pairs.size(), exprs.size() * 2, PREVIEW_DIR])
	quit()
