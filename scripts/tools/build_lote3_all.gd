extends SceneTree

## Gerador Lote 3 — Criaturas (Santelmo, Guardiã da Lagoa), Gatos (Pusa, Gatinho) & Retratos CRT (15 personagens)
## Gera SpriteFrames modulares em res://assets/sprites/{creatures,cats,portraits}/ e pranchas-resumo para aprovação.

const Lote3CreaturesCats = preload("res://scripts/tools/npc_pixel_rig/lote3_creatures_cats.gd")
const Lote3Portraits = preload("res://scripts/tools/npc_pixel_rig/lote3_portraits.gd")
const ARTIFACT_DIR := "C:/Users/SnyX/.gemini/antigravity/brain/6f04634a-b7d4-4d6f-9c20-24b6fdf404a0"


func _init() -> void:
	call_deferred("_run")


func _load_huwag_cell(sheet_path: String) -> Image:
	var full := Image.new()
	if full.load(ProjectSettings.globalize_path(sheet_path)) != OK:
		return Image.create(48, 48, false, Image.FORMAT_RGBA8)
	var cell := Image.create(48, 48, false, Image.FORMAT_RGBA8)
	cell.blit_rect(full, Rect2i(0, 0, 48, 48), Vector2i.ZERO)
	return cell


func _center_in_48(im: Image) -> Image:
	if im.get_width() == 48 and im.get_height() == 48:
		return im
	var out := Image.create(48, 48, false, Image.FORMAT_RGBA8)
	out.fill(Color(0, 0, 0, 0))
	var ox := (48 - im.get_width()) / 2
	var oy := 39 - 26 # alinha y=26 do gato (32x32) no mesmo chão y=39 de Huwag (48x48)!
	out.blit_rect(im, Rect2i(0, 0, im.get_width(), im.get_height()), Vector2i(ox, oy))
	return out


func _blit_tile_bg(board: Image, x: int, y: int, w: int, h: int, bg: Color, border: Color) -> void:
	for py in range(y, y + h):
		for px in range(x, x + w):
			var c := border if (px == x or py == y or px == x + w - 1 or py == y + h - 1) else bg
			if px >= 0 and py >= 0 and px < board.get_width() and py < board.get_height():
				board.set_pixel(px, py, c)


func _run() -> void:
	print("=== Gerando Lote 3 (Criaturas, Gatos & Retratos CRT 64x64) ===")
	var res_sant := Lote3CreaturesCats.build_santelmo()
	var res_guard := Lote3CreaturesCats.build_guardian()
	var res_pusa := Lote3CreaturesCats.build_pusa()
	var res_gatinho := Lote3CreaturesCats.build_gatinho()
	var portraits := Lote3Portraits.build_all_portraits()

	var huwag_casual := _load_huwag_cell("res://assets/sprites/huwag_v3/casual/spritesheet_idle.png")
	var huwag_bfp := _load_huwag_cell("res://assets/sprites/huwag_v3/bombeiro/spritesheet_idle.png")

	# -----------------------------------------------------------------------
	# Prancha 1: Criaturas + Gatos comparados em escala 1:1 com Huwag
	# -----------------------------------------------------------------------
	var pad := 6
	var cell := 48
	var rows_data: Array[Array] = [
		[huwag_casual, huwag_bfp] + res_sant["normal"],
		[huwag_casual, huwag_bfp] + res_sant["distorted"],
		[huwag_bfp] + res_guard["previews"],
		[
			huwag_casual,
			_center_in_48(res_pusa["normal"]),
			_center_in_48(Lote3CreaturesCats._render_pusa_frame("blink", 1, false)),
			_center_in_48(res_pusa["distorted"]),
			_center_in_48(res_gatinho["previews"][0]),
			_center_in_48(res_gatinho["previews"][2]),
			_center_in_48(res_gatinho["previews"][3]),
		],
	]
	var max_cols := 8
	var cw := pad + max_cols * (cell + pad)
	var ch := pad + rows_data.size() * (cell + pad)
	var cboard := Image.create(cw, ch, false, Image.FORMAT_RGBA8)
	cboard.fill(Color("#1A1412"))

	var row_bgs := [Color("#291E1B"), Color("#2E161B"), Color("#16282E"), Color("#24201C")]
	var row_rims := [Color("#F5A623"), Color("#E63946"), Color("#56D4C8"), Color("#E67E2E")]
	for r in range(rows_data.size()):
		var arr: Array = rows_data[r]
		var ry := pad + r * (cell + pad)
		for c in range(arr.size()):
			var rx := pad + c * (cell + pad)
			_blit_tile_bg(cboard, rx, ry, cell, cell, row_bgs[r], row_rims[r] if c > 0 else Color("#7A8C99"))
			var spr: Image = arr[c]
			cboard.blend_rect(spr, Rect2i(0, 0, spr.get_width(), spr.get_height()), Vector2i(rx, ry))

	var cboard_4x := cboard.duplicate() as Image
	cboard_4x.resize(cw * 4, ch * 4, Image.INTERPOLATE_NEAREST)
	cboard.save_png(ARTIFACT_DIR + "/lote3_creatures_cats_1x.png")
	cboard_4x.save_png(ARTIFACT_DIR + "/lote3_creatures_cats_4x.png")

	# -----------------------------------------------------------------------
	# Prancha 2: Todos os 15 Retratos CRT (Normal | Distorted lado a lado)
	# -----------------------------------------------------------------------
	var cols_p := 3
	var rows_p := ceili(float(portraits.size()) / float(cols_p))
	var p_w := 64
	var gap := 4
	var pair_gap := 10
	var bw := pair_gap + cols_p * (p_w * 2 + gap + pair_gap)
	var bh := pair_gap + rows_p * (p_w + pair_gap)
	var pboard := Image.create(bw, bh, false, Image.FORMAT_RGBA8)
	pboard.fill(Color("#121318"))

	for idx in range(portraits.size()):
		var entry: Dictionary = portraits[idx]
		var col := idx % cols_p
		var row := idx / cols_p
		var px := pair_gap + col * (p_w * 2 + gap + pair_gap)
		var py := pair_gap + row * (p_w + pair_gap)
		var n_img: Image = entry["normal"]
		var d_img: Image = entry["distorted"]
		pboard.blit_rect(n_img, Rect2i(0, 0, p_w, p_w), Vector2i(px, py))
		pboard.blit_rect(d_img, Rect2i(0, 0, p_w, p_w), Vector2i(px + p_w + gap, py))

	var pboard_3x := pboard.duplicate() as Image
	pboard_3x.resize(bw * 3, bh * 3, Image.INTERPOLATE_NEAREST)
	pboard.save_png(ARTIFACT_DIR + "/lote3_portraits_board_1x.png")
	pboard_3x.save_png(ARTIFACT_DIR + "/lote3_portraits_board_3x.png")

	print("Gerados SpriteFrames:", res_sant["normal_tres"], res_sant["distorted_tres"], res_guard["tres"], res_pusa["normal_tres"], res_gatinho["tres"])
	print("Retratos gerados:", portraits.size(), "pares em", Lote3Portraits.PORTRAITS_LOTE3_DIR)
	quit(0)
