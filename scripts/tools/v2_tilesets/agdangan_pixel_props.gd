class_name AgdanganPixelProps
extends RefCounted

## Sintetizador pixel art 16×16 estrito (perspectiva 3/4 top-down, contornos escuros
## e sombras projetadas) para identidade costeira filipina de Agdangan e interiores.

const P = preload("res://scripts/tools/v2_tilesets/atlas_painter.gd")


static func _set_g(img: Image, x: int, y: int, col: Color, variant: String) -> void:
	P.px(img, x, y, P.grade_color(col, variant, 0.92, 0.96, Color.WHITE))


static func _rect_g(img: Image, x0: int, y0: int, w: int, h: int, col: Color, variant: String) -> void:
	var gc := P.grade_color(col, variant, 0.92, 0.96, Color.WHITE)
	P.rect_px(img, x0, y0, w, h, gc)


static func _noisy_fill(img: Image, tile: Vector2i, c_a: Color, c_b: Color, c_speck: Color, salt: int, variant: String) -> void:
	var x0 := tile.x * 16
	var y0 := tile.y * 16
	for y in range(16):
		for x in range(16):
			var h := ((x * 73 + y * 139 + salt * 37) ^ (x * y * 17)) & 31
			var col := c_a
			if h == 0 or h == 17:
				col = c_speck
			elif h < 11:
				col = c_b
			_set_g(img, x0 + x, y0 + y, col, variant)


static func draw_ocean_and_pier_tiles(img: Image, variant: String) -> void:
	# 1. Areia costeira + borda de arrebentação contínua (cols 14..15, rows 0..1)
	var sand_a := Color("#C9B07C")
	var sand_b := Color("#BEA36E")
	var sand_sp := Color("#D8C28E")
	var sand_wet := Color("#A28B5E")
	var foam_hi := Color("#D2EDF2")
	var foam_mid := Color("#8AC3D1")
	var surf_col := Color("#2F7F99")
	_noisy_fill(img, Vector2i(15, 0), sand_a, sand_b, sand_sp, 41, variant)
	_noisy_fill(img, Vector2i(15, 1), sand_b, sand_a, Color("#AE9460"), 42, variant)
	_noisy_fill(img, Vector2i(14, 1), sand_wet, sand_b, sand_a, 43, variant)
	# (14, 0) sand_edge_w: transição suave água rasa -> espuma costeira -> areia úmida -> areia seca
	_noisy_fill(img, Vector2i(14, 0), sand_wet, sand_a, sand_b, 44, variant)
	for y in range(16):
		var wave_x := 6 + int(round(sin(float(y) * TAU / 16.0) * 1.2))
		for x in range(wave_x):
			var d_col := surf_col if x < wave_x - 2 else foam_mid
			_set_g(img, 14 * 16 + x, y, d_col, variant)
		_set_g(img, 14 * 16 + wave_x, y, foam_hi, variant)
		_set_g(img, 14 * 16 + wave_x + 1, y, sand_wet, variant)

	# 2. Mar profundo animado (19..21, 0) e água rasa costeira animada (22..24, 0) — 100% seamless
	var deep_base := Color("#154563")
	var deep_mid := Color("#1A5273")
	var deep_crest := Color("#2A6D8E")
	var shal_base := Color("#246C87")
	var shal_mid := Color("#2D7D99")
	var shal_crest := Color("#4FA0B8")
	for f in range(3):
		var phase_x := float(f) * (16.0 / 3.0)
		var dx0 := (19 + f) * 16
		var sx0 := (22 + f) * 16
		for y in range(16):
			for x in range(16):
				var wave1 := sin((float(x) + phase_x) * TAU / 16.0 + float(y) * TAU / 16.0)
				var wave2 := cos((float(x) - phase_x) * TAU / 8.0 - float(y) * TAU / 16.0)
				var v := wave1 * 0.6 + wave2 * 0.4
				var dcol := deep_base
				if v > 0.62:
					dcol = deep_crest
				elif v > 0.12:
					dcol = deep_mid
				_set_g(img, dx0 + x, y, dcol, variant)

				var scol := shal_base
				if v > 0.56:
					scol = shal_crest
				elif v > 0.08:
					scol = shal_mid
				_set_g(img, sx0 + x, y, scol, variant)

	# 3. Píer horizontal de madeira (16..18, 0) + estacas de apoio na água (17, 1)
	var out_c := Color("#12131A")
	var wood_hi := Color("#9A6D49")
	var wood_md := Color("#7C5436")
	var wood_dk := Color("#563924")
	for idx in range(3):
		var px0 := (16 + idx) * 16
		# Fundo sólido de tábuas horizontais do píer (preenche toda a largura para emendar sem falhas)
		_rect_g(img, px0, 0, 16, 16, wood_md, variant)
		_rect_g(img, px0, 0, 16, 1, out_c, variant)
		_rect_g(img, px0, 1, 16, 2, wood_hi, variant)
		_rect_g(img, px0, 13, 16, 2, wood_dk, variant)
		_rect_g(img, px0, 15, 16, 1, out_c, variant)
		for sx in range(0, 16, 4):
			_rect_g(img, px0 + sx, 3, 1, 10, wood_dk, variant)
			_rect_g(img, px0 + sx + 1, 3, 2, 10, wood_md if (sx % 8 == 0) else wood_hi, variant)
			_set_g(img, px0 + sx + 2, 4, Color("#3B271A"), variant)
			_set_g(img, px0 + sx + 2, 11, Color("#3B271A"), variant)
	# Cabeceira oeste do píer (16, 0) com vigas terminais
	_rect_g(img, 16 * 16, 0, 2, 16, out_c, variant)
	_rect_g(img, 16 * 16 + 2, 1, 2, 14, wood_dk, variant)
	# Estaca de suporte do píer dentro da água (17, 1)
	_rect_g(img, 17 * 16, 16, 16, 16, shal_base, variant)
	_rect_g(img, 17 * 16 + 5, 16, 6, 12, out_c, variant)
	_rect_g(img, 17 * 16 + 6, 16, 4, 11, wood_dk, variant)
	_rect_g(img, 17 * 16 + 6, 16, 2, 10, wood_md, variant)
	_rect_g(img, 17 * 16 + 4, 27, 8, 2, foam_hi, variant)


static func draw_soil_and_blend_tiles(img: Image, variant: String) -> void:
	# Terra costeira (4..5, 1) e transições orgânicas areia <-> terra (6..7, 1)
	var dirt_a := Color("#6D513A")
	var dirt_b := Color("#604530")
	var dirt_sp := Color("#7E6046")
	_noisy_fill(img, Vector2i(4, 1), dirt_a, dirt_b, dirt_sp, 61, variant)
	_noisy_fill(img, Vector2i(5, 1), dirt_b, dirt_a, Color("#513926"), 62, variant)

	# Pontilhos sutis de pedrinha na terra batida
	for k in range(4):
		var px := 4 * 16 + 3 + k * 3
		var py := 16 + 4 + ((k * 5) % 8)
		_set_g(img, px, py, Color("#8C7259"), variant)
		_set_g(img, px + 1, py + 1, Color("#4D3725"), variant)

	# (6, 1): Gradiente orgânico horizontal Areia (esquerda) -> Terra (direita)
	for y in range(16):
		for x in range(16):
			var sand_c := img.get_pixel(15 * 16 + x, y)
			var dirt_c := img.get_pixel(4 * 16 + x, 16 + y)
			var hash_j := float(((x * 73 + y * 139) ^ (x * y * 19)) & 15) / 15.0
			var t := clampf((float(x) + (hash_j - 0.5) * 4.5 - 2.0) / 11.0, 0.0, 1.0)
			img.set_pixel(6 * 16 + x, 16 + y, dirt_c if t > 0.5 else sand_c)

	# (7, 1): Solo misto areia-terra harmonioso (meio-termo natural sem degrau brusco)
	for y in range(16):
		for x in range(16):
			var sand_c := img.get_pixel(15 * 16 + x, y)
			var dirt_c := img.get_pixel(4 * 16 + x, 16 + y)
			var h := ((x * 59 + y * 113 + 7) ^ (x * y * 13)) & 31
			var mix_c := sand_c.lerp(dirt_c, 0.52)
			if h < 9:
				mix_c = sand_c.lerp(dirt_c, 0.30)
			elif h > 23:
				mix_c = dirt_c.lerp(sand_c, 0.25)
			img.set_pixel(7 * 16 + x, 16 + y, mix_c)


static func draw_road_and_plaza_tiles(img: Image, origin: Vector2i, variant: String) -> void:
	var asp_a := Color("#262832")
	var asp_b := Color("#2D303C")
	var asp_dk := Color("#1B1D26")
	var line_y := Color("#B89844")
	var curb_hi := Color("#787C86")
	var curb_mid := Color("#5C606B")
	var curb_dk := Color("#3D404A")
	var court_a := Color("#535963")
	var court_b := Color("#4B515B")
	var line_w := Color("#B6BCC4")

	# Cols +0..+3 row +0: Asfalto, faixa amarela H, faixa amarela V, bueiro
	_noisy_fill(img, origin + Vector2i(0, 0), asp_a, asp_b, asp_dk, 1, variant)
	_noisy_fill(img, origin + Vector2i(1, 0), asp_a, asp_b, asp_dk, 2, variant)
	_rect_g(img, (origin.x + 1) * 16 + 2, origin.y * 16 + 7, 5, 2, line_y, variant)
	_rect_g(img, (origin.x + 1) * 16 + 10, origin.y * 16 + 7, 5, 2, line_y, variant)

	_noisy_fill(img, origin + Vector2i(2, 0), asp_a, asp_b, asp_dk, 3, variant)
	_rect_g(img, (origin.x + 2) * 16 + 7, origin.y * 16 + 2, 2, 5, line_y, variant)
	_rect_g(img, (origin.x + 2) * 16 + 7, origin.y * 16 + 10, 2, 5, line_y, variant)

	_noisy_fill(img, origin + Vector2i(3, 0), asp_a, asp_b, asp_dk, 4, variant)
	var gx := (origin.x + 3) * 16
	var gy := origin.y * 16
	_rect_g(img, gx + 3, gy + 4, 10, 8, Color("#181A22"), variant)
	_rect_g(img, gx + 4, gy + 5, 8, 6, Color("#3A3E48"), variant)
	for s in range(3):
		_rect_g(img, gx + 5 + s * 2, gy + 6, 1, 4, Color("#111319"), variant)

	# Row +1 Cols +0..+3: Rachadura asfalto, poça d'água, meio-fio topo/base
	_noisy_fill(img, origin + Vector2i(0, 1), asp_a, asp_b, asp_dk, 5, variant)
	var cx := origin.x * 16
	var cy := (origin.y + 1) * 16
	for k in range(10):
		_set_g(img, cx + 2 + k, cy + 5 + (k % 3), Color("#13151B"), variant)
		_set_g(img, cx + 6 + (k / 2), cy + 7 + (k % 4), Color("#15171E"), variant)

	_noisy_fill(img, origin + Vector2i(1, 1), asp_a, asp_b, asp_dk, 6, variant)
	var px0 := (origin.x + 1) * 16
	var py0 := (origin.y + 1) * 16
	_rect_g(img, px0 + 3, py0 + 5, 10, 6, Color("#1D2D3E"), variant)
	_rect_g(img, px0 + 4, py0 + 6, 8, 4, Color("#2E4A63"), variant)
	_rect_g(img, px0 + 5, py0 + 7, 4, 1, Color("#608BA8"), variant)

	# Calçadas / meio-fio (cols +2..+3 row +1 e row +2)
	_noisy_fill(img, origin + Vector2i(2, 1), curb_mid, curb_hi, curb_dk, 7, variant)
	_rect_g(img, (origin.x + 2) * 16, (origin.y + 1) * 16 + 13, 16, 2, curb_hi, variant)
	_rect_g(img, (origin.x + 2) * 16, (origin.y + 1) * 16 + 15, 16, 1, Color("#14151C"), variant)

	_noisy_fill(img, origin + Vector2i(3, 1), curb_mid, curb_hi, curb_dk, 8, variant)
	_rect_g(img, (origin.x + 3) * 16, (origin.y + 1) * 16, 16, 2, curb_hi, variant)
	_rect_g(img, (origin.x + 3) * 16, (origin.y + 1) * 16 + 2, 16, 1, curb_dk, variant)

	# Quadra / Praça Agdangan (cols +4..+7 row +0..+1)
	_noisy_fill(img, origin + Vector2i(4, 0), court_a, court_b, curb_dk, 9, variant)
	_rect_g(img, (origin.x + 4) * 16, origin.y * 16 + 15, 16, 1, curb_dk, variant)
	_noisy_fill(img, origin + Vector2i(5, 0), court_a, court_b, curb_dk, 10, variant)
	_rect_g(img, (origin.x + 5) * 16, origin.y * 16 + 7, 16, 2, line_w, variant)
	_noisy_fill(img, origin + Vector2i(6, 0), court_a, court_b, curb_dk, 11, variant)
	_rect_g(img, (origin.x + 6) * 16 + 7, origin.y * 16, 2, 16, line_w, variant)
	# Faixa de pedestres
	_noisy_fill(img, origin + Vector2i(7, 0), asp_a, asp_b, asp_dk, 12, variant)
	for sx in [1, 6, 11]:
		_rect_g(img, (origin.x + 7) * 16 + sx, origin.y * 16 + 3, 3, 10, Color("#A4AAB5"), variant)


static func draw_modular_filipino_buildings(img: Image, wall_origin: Vector2i, roof_origin: Vector2i, variant: String) -> void:
	# Paredes provinciais 16x16 (cols +0..+7): concreto sujo, madeira kahoy, janela capiz apagada/acesa, porta, parede BFP + rolo metalico
	var conc_top := Color("#C2BAA8")
	var conc_mid := Color("#A69F8E")
	var conc_moss := Color("#5E6652")
	var out_col := Color("#11121A")
	var wood_dk := Color("#462D20")
	var wood_md := Color("#694632")
	var wood_hi := Color("#875E42")

	# Col +0: Reboco de concreto com mancha de umidade no rodapé
	_noisy_fill(img, wall_origin + Vector2i(0, 0), conc_mid, conc_top, Color("#888272"), 21, variant)
	_rect_g(img, wall_origin.x * 16, wall_origin.y * 16 + 12, 16, 3, conc_moss, variant)
	_rect_g(img, wall_origin.x * 16, wall_origin.y * 16 + 15, 16, 1, out_col, variant)

	# Col +1: Madeira provincial (kahoy) vertical
	var wx := (wall_origin.x + 1) * 16
	var wy := wall_origin.y * 16
	_rect_g(img, wx, wy, 16, 16, wood_md, variant)
	for sx in range(0, 16, 4):
		_rect_g(img, wx + sx, wy, 1, 15, wood_dk, variant)
		_rect_g(img, wx + sx + 1, wy, 1, 14, wood_hi, variant)
	_rect_g(img, wx, wy + 15, 16, 1, out_col, variant)

	# Col +2 e +3: Janela Jalousie/Capiz apagada e acesa (quente)
	for j in range(2):
		var tx := (wall_origin.x + 2 + j) * 16
		var ty := wall_origin.y * 16
		_noisy_fill(img, wall_origin + Vector2i(2 + j, 0), conc_mid, conc_top, Color("#888272"), 22 + j, variant)
		_rect_g(img, tx + 2, ty + 2, 12, 11, out_col, variant)
		_rect_g(img, tx + 3, ty + 3, 10, 9, wood_dk, variant)
		var glass := Color("#232B3A") if j == 0 else Color("#E6B85C")
		var pane_hi := Color("#3D4B61") if j == 0 else Color("#FFF0AD")
		_rect_g(img, tx + 4, ty + 4, 3, 3, glass, variant)
		_rect_g(img, tx + 9, ty + 4, 3, 3, glass, variant)
		_rect_g(img, tx + 4, ty + 8, 3, 3, pane_hi, variant)
		_rect_g(img, tx + 9, ty + 8, 3, 3, pane_hi, variant)
		_rect_g(img, tx + 2, ty + 13, 12, 2, Color("#5A564D"), variant)
		_rect_g(img, tx, ty + 15, 16, 1, out_col, variant)

	# Col +4: Porta de madeira provincial com degrau
	var dx := (wall_origin.x + 4) * 16
	var dy := wall_origin.y * 16
	_noisy_fill(img, wall_origin + Vector2i(4, 0), conc_mid, conc_top, Color("#888272"), 24, variant)
	_rect_g(img, dx + 2, dy + 1, 12, 14, out_col, variant)
	_rect_g(img, dx + 3, dy + 2, 10, 12, wood_md, variant)
	_rect_g(img, dx + 4, dy + 3, 8, 4, wood_hi, variant)
	_rect_g(img, dx + 10, dy + 8, 2, 2, Color("#D8B858"), variant)
	_rect_g(img, dx + 2, dy + 14, 12, 2, Color("#6C6E76"), variant)

	# Col +5 e +6: Parede BFP (vermelho bombeiro / creme) e portão de rolo da garagem
	var bx := (wall_origin.x + 5) * 16
	_rect_g(img, bx, dy, 16, 11, Color("#B8322E"), variant)
	_rect_g(img, bx, dy + 10, 16, 2, Color("#D4CEBC"), variant)
	_rect_g(img, bx, dy + 12, 16, 3, Color("#6C3634"), variant)
	_rect_g(img, bx, dy + 15, 16, 1, out_col, variant)

	var rx := (wall_origin.x + 6) * 16
	_rect_g(img, rx, dy, 16, 16, Color("#4D5361"), variant)
	for sy in range(1, 15, 2):
		_rect_g(img, rx + 1, dy + sy, 14, 1, Color("#6D7484"), variant)
	_rect_g(img, rx, dy, 1, 16, out_col, variant)
	_rect_g(img, rx + 15, dy, 1, 16, out_col, variant)
	_rect_g(img, rx + 2, dy + 13, 12, 2, Color("#242832"), variant)

	# Telhados de Zinco Galvanizado (Yero) cinza + enferrujado (cols +0..+3 no roof_origin)
	var zinc_a := Color("#636B78")
	var zinc_b := Color("#4B525E")
	var zinc_hi := Color("#838B99")
	var rust_a := Color("#7A422B")
	var rust_b := Color("#5A2E1E")
	for rt in range(4):
		var rtx := (roof_origin.x + rt) * 16
		var rty := roof_origin.y * 16
		var is_rust := (rt >= 2)
		for x in range(16):
			var rib := (x % 3 == 0)
			var base_c := (rust_b if rib else rust_a) if is_rust else (zinc_b if rib else zinc_a)
			_rect_g(img, rtx + x, rty, 1, 14, base_c, variant)
			if x % 3 == 1:
				_set_g(img, rtx + x, rty + 1, zinc_hi if not is_rust else Color("#9C5B3D"), variant)
		# Beiral frontal + sombra inferior
		if rt % 2 == 1:
			_rect_g(img, rtx, rty + 13, 16, 2, Color("#2A2E38"), variant)
			_rect_g(img, rtx, rty + 15, 16, 1, out_col, variant)


static func draw_coconut_palm(img: Image, tile_tl: Vector2i, lean_dir: int, variant: String) -> void:
	# 3x6 tiles = 48x96 px (ancorado no tronco em (24, 90))
	var x0 := tile_tl.x * 16
	var y0 := tile_tl.y * 16
	var cx := x0 + 24
	var out_c := Color("#0E1117")
	var sh_c := Color(0.03, 0.04, 0.08, 0.42)

	# Sombra oval no chão sob a raiz
	for sy in range(83, 94):
		for sx in range(x0 + 10, x0 + 38):
			var nx := float(sx - cx) / 13.0
			var ny := float(sy - 89) / 4.2
			if nx * nx + ny * ny <= 1.0 and ((sx + sy) % 2 == 0 or nx * nx + ny * ny < 0.65):
				P.px(img, sx, y0 + sy, sh_c)

	# Tronco curvado segmentado com anéis de palmeira
	var crown_x := float(cx + lean_dir * 4)
	var crown_y := y0 + 24
	for y in range(crown_y, y0 + 91):
		var t := float(y - crown_y) / float(90 - 24)
		var curve_x := int(round(lerpf(crown_x, float(cx), t * t * 0.4 + t * 0.6) + sin(t * 2.4) * lean_dir * 2.0))
		var half_w := 2 if t < 0.7 else 3
		_set_g(img, curve_x - half_w - 1, y, out_c, variant)
		_set_g(img, curve_x + half_w + 1, y, out_c, variant)
		var ring := ((y - crown_y) % 5 == 0)
		for wx in range(-half_w, half_w + 1):
			var col := Color("#4B3629") if ring else (Color("#8B684E") if wx < 0 else Color("#6C4D38"))
			_set_g(img, curve_x + wx, y, col, variant)

	# Cachos de cocos na base da copa
	var c_offsets: Array[Vector2i] = [Vector2i(-3, 2), Vector2i(2, 2), Vector2i(0, 4)]
	for c_off in c_offsets:
		var gx: int = int(crown_x) + c_off.x
		var gy: int = crown_y + c_off.y
		_rect_g(img, gx - 1, gy - 1, 4, 4, out_c, variant)
		_rect_g(img, gx, gy, 2, 2, Color("#6C5228"), variant)
		_set_g(img, gx, gy, Color("#8FA248"), variant)

	# 7 Palmas caídas em perspectiva 3/4
	var frond_angles := [-2.85, -2.25, -1.60, -0.95, -0.35, 0.32, 2.78]
	var frond_len := [20.0, 19.0, 16.0, 19.0, 21.0, 17.0, 17.0]
	for fi in range(frond_angles.size()):
		var ang: float = frond_angles[fi]
		var flen: float = frond_len[fi]
		for s in range(2, int(flen)):
			var u := float(s) / flen
			var fx := crown_x + cos(ang) * float(s)
			var fy := float(crown_y) + sin(ang) * float(s) * 0.65 + (u * u) * 9.0
			var ix := int(round(fx))
			var iy := int(round(fy))
			var leaf_w := 3 if (u > 0.2 and u < 0.8) else 2
			for dy in range(0, leaf_w + 1):
				var col := Color("#3E6E3B") if dy == 0 else (Color("#274C2A") if dy == 1 else Color("#18321C"))
				_set_g(img, ix, iy + dy, col, variant)
				if dy == leaf_w:
					_set_g(img, ix, iy + dy + 1, out_c, variant)
			if s % 3 == 0:
				_set_g(img, ix, iy + leaf_w + 2, out_c, variant)
	# Topo central iluminado
	_rect_g(img, int(crown_x) - 3, crown_y - 3, 7, 4, Color("#4D8245"), variant)


static func draw_banana_plant(img: Image, tile_tl: Vector2i, variant: String) -> void:
	# 2x3 tiles = 32x48 px (bananeira tropical com folhas arqueadas)
	var x0 := tile_tl.x * 16
	var y0 := tile_tl.y * 16
	var cx := x0 + 16
	var out_c := Color("#0F1512")
	# Sombra na base
	_rect_g(img, cx - 7, y0 + 42, 14, 4, Color(0.03, 0.04, 0.08, 0.40), variant)
	# Pseudocaule verde-acinzentado
	_rect_g(img, cx - 3, y0 + 22, 6, 22, out_c, variant)
	_rect_g(img, cx - 2, y0 + 22, 2, 21, Color("#627F40"), variant)
	_rect_g(img, cx, y0 + 22, 2, 21, Color("#415B2B"), variant)
	# 5 Folhas largas curvadas com nervura clara
	var f_angles := [-2.75, -2.05, -0.45, -1.05, 0.15]
	var f_lens := [13.0, 12.0, 13.0, 11.0, 11.0]
	for i in range(f_angles.size()):
		var ang: float = f_angles[i]
		var flen: float = f_lens[i]
		for s in range(2, int(flen)):
			var u := float(s) / flen
			var lx := int(round(float(cx) + cos(ang) * float(s)))
			var ly := int(round(float(y0 + 21) + sin(ang) * float(s) * 0.8 + u * u * 6.0))
			var thick := 4 if (u > 0.2 and u < 0.72) else 2
			for dy in range(0, thick):
				var lc := Color("#61974A") if dy == 0 else (Color("#3C6D34") if dy < 2 else Color("#244922"))
				_set_g(img, lx, ly + dy, lc, variant)
			_set_g(img, lx, ly - 1, out_c, variant)
			_set_g(img, lx, ly + thick, out_c, variant)


static func draw_street_lamppost(img: Image, tile_tl: Vector2i, is_broken: bool, variant: String) -> void:
	# 1x5 tiles = 16x80 px
	var x0 := tile_tl.x * 16
	var y0 := tile_tl.y * 16
	var out_c := Color("#0E1018")
	var pole_hi := Color("#7F8592")
	var pole_dk := Color("#4B505C")
	# Base de concreto (row 4 -> y0+64..79)
	_rect_g(img, x0 + 4, y0 + 68, 8, 10, out_c, variant)
	_rect_g(img, x0 + 5, y0 + 69, 6, 8, Color("#6C707C"), variant)
	_rect_g(img, x0 + 5, y0 + 75, 6, 2, Color("#494D57"), variant)
	# Poste vertical
	_rect_g(img, x0 + 6, y0 + 12, 4, 57, out_c, variant)
	_rect_g(img, x0 + 7, y0 + 13, 1, 56, pole_hi, variant)
	_rect_g(img, x0 + 8, y0 + 13, 1, 56, pole_dk, variant)
	# Transformador / caixa elétrica
	_rect_g(img, x0 + 3, y0 + 28, 5, 8, out_c, variant)
	_rect_g(img, x0 + 4, y0 + 29, 3, 6, Color("#39404D"), variant)
	# Braço da luminária no topo (row 0)
	_rect_g(img, x0 + 7, y0 + 10, 8, 3, out_c, variant)
	_rect_g(img, x0 + 8, y0 + 11, 6, 1, pole_hi, variant)
	var bulb := Color("#3B3A36") if is_broken else Color("#FFE288")
	_rect_g(img, x0 + 11, y0 + 13, 4, 3, out_c, variant)
	_rect_g(img, x0 + 12, y0 + 13, 2, 2, bulb, variant)


static func draw_sari_sari_store(img: Image, tile_tl: Vector2i, variant: String) -> void:
	# 5x4 tiles = 80x64 px fachada filipina icônica de mercearia de esquina
	var x0 := tile_tl.x * 16
	var y0 := tile_tl.y * 16
	var out_c := Color("#101018")
	# Contorno + corpo concreto/madeira
	_rect_g(img, x0 + 2, y0 + 6, 76, 56, out_c, variant)
	_rect_g(img, x0 + 4, y0 + 24, 72, 36, Color("#AEA48F"), variant)
	_rect_g(img, x0 + 4, y0 + 44, 72, 16, Color("#593A27"), variant) # balcão kahoy
	# Telhado yero superior + placa SARI-SARI
	_rect_g(img, x0 + 2, y0 + 6, 76, 18, Color("#525B6B"), variant)
	for x in range(x0 + 4, x0 + 76, 3):
		_rect_g(img, x, y0 + 7, 1, 16, Color("#3A414E"), variant)
	# Toldo listrado azul/carmesim embaixo do telhado
	for x in range(x0 + 3, x0 + 77, 4):
		var stripe_c := Color("#2D6B8E") if ((x / 4) % 2 == 0) else Color("#A83333")
		_rect_g(img, x, y0 + 23, 4, 6, stripe_c, variant)
		_rect_g(img, x, y0 + 29, 4, 2, Color(0.05, 0.05, 0.08, 0.45), variant)
	# Letreiro iluminado central no toldo
	_rect_g(img, x0 + 24, y0 + 12, 32, 9, out_c, variant)
	_rect_g(img, x0 + 25, y0 + 13, 30, 7, Color("#1D2C3A"), variant)
	_rect_g(img, x0 + 27, y0 + 15, 26, 3, Color("#E8C466"), variant)
	# Balcão com grade de ferro + mercadorias/garrafas iluminadas dentro
	_rect_g(img, x0 + 18, y0 + 31, 40, 14, out_c, variant)
	_rect_g(img, x0 + 19, y0 + 32, 38, 12, Color("#241C18"), variant)
	# Prateleira & pacotes coloridos pendurados (sachets)
	for s in range(6):
		var sx := x0 + 21 + s * 6
		var col := Color("#D94A38") if s % 3 == 0 else (Color("#E2B43B") if s % 3 == 1 else Color("#4BA3C7"))
		_rect_g(img, sx, y0 + 33, 4, 5, col, variant)
	for bx in range(x0 + 22, x0 + 56, 5):
		_rect_g(img, bx, y0 + 32, 1, 12, Color("#6F7682"), variant)
	# Geladeira de vidro à esquerda + banco de madeira (*bangko*) à direita
	_rect_g(img, x0 + 6, y0 + 32, 10, 18, out_c, variant)
	_rect_g(img, x0 + 7, y0 + 33, 8, 16, Color("#73B8C8"), variant)
	_rect_g(img, x0 + 8, y0 + 35, 6, 5, Color("#D6F4FA"), variant)
	_rect_g(img, x0 + 59, y0 + 51, 14, 6, out_c, variant)
	_rect_g(img, x0 + 60, y0 + 52, 12, 3, Color("#8A5D3B"), variant)


static func draw_provincial_house(img: Image, tile_tl: Vector2i, roof_tint: Color, variant: String) -> void:
	# 6x5 tiles = 96x80 px casa provincial filipina de concreto & madeira com telhado yero
	var x0 := tile_tl.x * 16
	var y0 := tile_tl.y * 16
	var out_c := Color("#101018")
	_rect_g(img, x0 + 3, y0 + 8, 90, 68, out_c, variant)
	# Telhado 2 águas com beiral
	_rect_g(img, x0 + 4, y0 + 9, 88, 28, roof_tint, variant)
	var roof_dk := roof_tint.darkened(0.28)
	var roof_hi := roof_tint.lightened(0.18)
	for x in range(x0 + 5, x0 + 91, 3):
		_rect_g(img, x, y0 + 10, 1, 26, roof_dk, variant)
	_rect_g(img, x0 + 4, y0 + 21, 88, 2, roof_hi, variant)
	_rect_g(img, x0 + 4, y0 + 37, 88, 3, Color("#242630"), variant)
	# Fachada superior madeira kahoy + inferior concreto úmido
	_rect_g(img, x0 + 6, y0 + 40, 84, 18, Color("#684531"), variant)
	for x in range(x0 + 8, x0 + 89, 4):
		_rect_g(img, x, y0 + 40, 1, 18, Color("#492E1F"), variant)
	_rect_g(img, x0 + 6, y0 + 58, 84, 17, Color("#ACA695"), variant)
	_rect_g(img, x0 + 6, y0 + 71, 84, 4, Color("#606753"), variant)
	# Janelas Capiz esquerda & direita + Porta central com degraus
	for wx in [x0 + 15, x0 + 66]:
		_rect_g(img, wx, y0 + 44, 15, 13, out_c, variant)
		_rect_g(img, wx + 1, y0 + 45, 13, 11, Color("#3E281C"), variant)
		_rect_g(img, wx + 2, y0 + 46, 5, 4, Color("#E8BA5D"), variant)
		_rect_g(img, wx + 8, y0 + 46, 5, 4, Color("#E8BA5D"), variant)
		_rect_g(img, wx + 2, y0 + 51, 5, 4, Color("#C6933E"), variant)
		_rect_g(img, wx + 8, y0 + 51, 5, 4, Color("#C6933E"), variant)
	# Porta principal
	_rect_g(img, x0 + 41, y0 + 53, 14, 22, out_c, variant)
	_rect_g(img, x0 + 42, y0 + 54, 12, 18, Color("#7B5135"), variant)
	_rect_g(img, x0 + 51, y0 + 62, 2, 2, Color("#E0BE58"), variant)
	_rect_g(img, x0 + 39, y0 + 73, 18, 4, Color("#7C8089"), variant)


static func draw_bfp_fire_truck(img: Image, tile_tl: Vector2i, variant: String) -> void:
	# 5x3 tiles = 80x48 px Viatura BFP estacionada em perspectiva 3/4
	var x0 := tile_tl.x * 16
	var y0 := tile_tl.y * 16
	var out_c := Color("#0E0E15")
	# Sombra inferior
	_rect_g(img, x0 + 4, y0 + 40, 72, 6, Color(0.03, 0.03, 0.06, 0.45), variant)
	# Corpo principal do caminhão BFP
	_rect_g(img, x0 + 4, y0 + 14, 70, 26, out_c, variant)
	_rect_g(img, x0 + 5, y0 + 16, 46, 22, Color("#BA2D29"), variant) # carroceria bomba
	_rect_g(img, x0 + 52, y0 + 15, 21, 23, Color("#CE3832"), variant) # cabine
	# Faixa refletiva branco/ouro BFP
	_rect_g(img, x0 + 5, y0 + 28, 68, 3, Color("#E8DFCF"), variant)
	_rect_g(img, x0 + 5, y0 + 30, 46, 1, Color("#E0AE3B"), variant)
	# Persiana prateada de equipamentos + mangueira
	_rect_g(img, x0 + 10, y0 + 19, 24, 9, Color("#7D8594"), variant)
	for sy in range(20, 28, 2):
		_rect_g(img, x0 + 11, y0 + sy, 22, 1, Color("#565E6B"), variant)
	# Para-brisa cabine + farol
	_rect_g(img, x0 + 56, y0 + 18, 13, 8, out_c, variant)
	_rect_g(img, x0 + 57, y0 + 19, 11, 6, Color("#35526E"), variant)
	_rect_g(img, x0 + 58, y0 + 20, 4, 2, Color("#79A7C7"), variant)
	_rect_g(img, x0 + 71, y0 + 31, 3, 4, Color("#FCE588"), variant)
	# Escada metálica no teto + giroflex azul/vermelho
	_rect_g(img, x0 + 8, y0 + 11, 42, 4, out_c, variant)
	_rect_g(img, x0 + 9, y0 + 12, 40, 2, Color("#A8B0BE"), variant)
	_rect_g(img, x0 + 57, y0 + 11, 10, 4, out_c, variant)
	_rect_g(img, x0 + 58, y0 + 12, 4, 2, Color("#E83B3B"), variant)
	_rect_g(img, x0 + 62, y0 + 12, 4, 2, Color("#3B8CE8"), variant)
	# Rodas
	for wx in [x0 + 14, x0 + 56]:
		_rect_g(img, wx, y0 + 35, 11, 9, out_c, variant)
		_rect_g(img, wx + 2, y0 + 37, 7, 5, Color("#24262E"), variant)
		_rect_g(img, wx + 4, y0 + 38, 3, 3, Color("#98A0AD"), variant)


static func draw_tricycle_and_banca(img: Image, tri_tl: Vector2i, banca_tl: Vector2i, variant: String) -> void:
	# Triciclo Filipino (3x2 = 48x32)
	var x0 := tri_tl.x * 16
	var y0 := tri_tl.y * 16
	var out_c := Color("#101119")
	_rect_g(img, x0 + 5, y0 + 24, 38, 5, Color(0.03, 0.03, 0.07, 0.42), variant)
	_rect_g(img, x0 + 6, y0 + 7, 27, 18, out_c, variant)
	_rect_g(img, x0 + 7, y0 + 8, 25, 6, Color("#3B76AD"), variant) # toldo azul superior
	_rect_g(img, x0 + 8, y0 + 8, 23, 2, Color("#5E98CC"), variant)
	_rect_g(img, x0 + 7, y0 + 15, 21, 9, Color("#284E73"), variant) # cabine passageiro
	_rect_g(img, x0 + 8, y0 + 21, 19, 2, Color("#D8A846"), variant) # faixa amarela provincial
	_rect_g(img, x0 + 10, y0 + 15, 8, 6, Color("#8CC2DE"), variant) # para-brisa sidecar
	_rect_g(img, x0 + 20, y0 + 16, 7, 4, Color("#6C9CB8"), variant) # janela lateral
	# Moto acoplada à direita (guidão, tanque, farol e escapamento)
	_rect_g(img, x0 + 32, y0 + 9, 11, 16, out_c, variant)
	_rect_g(img, x0 + 33, y0 + 10, 8, 3, Color("#98A0AE"), variant) # guidão/espelho
	_rect_g(img, x0 + 33, y0 + 14, 7, 8, Color("#AA3C36"), variant) # tanque moto
	_rect_g(img, x0 + 40, y0 + 14, 2, 3, Color("#FFE288"), variant) # farol
	_rect_g(img, x0 + 35, y0 + 21, 7, 6, out_c, variant)
	_rect_g(img, x0 + 37, y0 + 23, 3, 3, Color("#8E96A4"), variant)
	_rect_g(img, x0 + 9, y0 + 22, 7, 6, out_c, variant)
	_rect_g(img, x0 + 11, y0 + 24, 3, 3, Color("#8E96A4"), variant)

	# Barco de Pesca Filipino (Banca com outrigger/katig — 4x2 = 64x32)
	var bx := banca_tl.x * 16
	var by := banca_tl.y * 16
	# Braços de bambu (katig)
	_rect_g(img, bx + 14, by + 3, 2, 26, Color("#6C5234"), variant)
	_rect_g(img, bx + 48, by + 3, 2, 26, Color("#6C5234"), variant)
	_rect_g(img, bx + 6, by + 3, 52, 2, Color("#8A6D46"), variant)
	_rect_g(img, bx + 6, by + 27, 52, 2, Color("#8A6D46"), variant)
	# Casco pontudo de madeira
	_rect_g(img, bx + 4, by + 11, 56, 10, out_c, variant)
	_rect_g(img, bx + 7, by + 12, 50, 8, Color("#6D4A31"), variant)
	_rect_g(img, bx + 11, by + 13, 42, 6, Color("#4E3321"), variant)
	_rect_g(img, bx + 16, by + 14, 32, 4, Color("#8B5F3E"), variant)


static func draw_sawali_and_banig(img: Image, sawali_origin: Vector2i, banig_origin: Vector2i, variant: String) -> void:
	# 3 tiles de parede Sawali (trança de bambu filipina) com sombra na base
	for i in range(3):
		var tx := (sawali_origin.x + i) * 16
		var ty := sawali_origin.y * 16
		_rect_g(img, tx, ty, 16, 2, Color("#151116"), variant)
		for y in range(2, 15):
			for x in range(16):
				var weave := ((x / 3 + y / 2) % 2 == 0)
				var col := Color("#7D5B39") if weave else Color("#5E4126")
				if x % 6 == 0:
					col = Color("#462E19")
				_set_g(img, tx + x, ty + y, col, variant)
		_rect_g(img, tx, ty + 15, 16, 1, Color("#140F12"), variant)

	# Esteira Banig 3x2 tiles (48x32) tecida com borda marrom escura suave filipina
	var mx0 := banig_origin.x * 16
	var my0 := banig_origin.y * 16
	_rect_g(img, mx0 + 1, my0 + 1, 46, 30, Color("#3D2820"), variant)
	_rect_g(img, mx0 + 2, my0 + 2, 44, 28, Color("#8C4030"), variant)
	for y in range(my0 + 4, my0 + 28):
		for x in range(mx0 + 4, mx0 + 44):
			var pat := ((x + y) % 4 == 0) or ((x - y + 64) % 4 == 0)
			var col := Color("#B89862") if pat else Color("#9C7C49")
			_set_g(img, x, y, col, variant)


static func draw_vertical_bamboo_fence_tile(img: Image, dst_tile: Vector2i, variant: String) -> void:
	# Cerca vertical contínua de bambu (16x16 sem emendas quebradas entre tiles verticais)
	var x0 := dst_tile.x * 16
	var y0 := dst_tile.y * 16
	for py in range(16):
		for px in range(16):
			img.set_pixel(x0 + px, y0 + py, Color(0, 0, 0, 0))
	var out_c := Color("#161214")
	# Dois trilhos/varas verticais contínuos de cima a baixo (y=0..15)
	_rect_g(img, x0 + 5, y0, 6, 16, out_c, variant)
	_rect_g(img, x0 + 6, y0, 2, 16, Color("#8A6843"), variant)
	_rect_g(img, x0 + 8, y0, 2, 16, Color("#5E4126"), variant)
	# Mourão central mais largo com topo destacado + nós de bambu alinhados
	_rect_g(img, x0 + 4, y0 + 2, 8, 6, out_c, variant)
	_rect_g(img, x0 + 5, y0 + 2, 6, 2, Color("#A27C52"), variant)
	_rect_g(img, x0 + 5, y0 + 4, 6, 3, Color("#735232"), variant)
	_rect_g(img, x0 + 6, y0 + 11, 4, 1, Color("#462E19"), variant)


static func draw_interior_window_tile(img: Image, window_tl: Vector2i, variant: String) -> void:
	# Janela completa 2x3 (32x48): moldura fechada nas 4 bordas em 2x2 superior + sombra sutil na linha inferior
	P.clear_tiles_rect(img, window_tl, Vector2i(2, 3))
	var x0 := window_tl.x * 16
	var y0 := window_tl.y * 16
	var out_c := Color("#161114")
	var wood_dk := Color("#4A2F1D")
	var wood_md := Color("#744C32")
	var wood_hi := Color("#9A6B49")
	var sill_c := Color("#83583A")
	var glass_a := Color("#D8EAF2")
	var glass_b := Color("#F4F8EA")
	var glass_hi := Color("#FFFFFF")
	if variant == "distorted":
		glass_a = Color("#544F74")
		glass_b = Color("#7E79A4")
		glass_hi = Color("#CFC8F0")
	elif variant == "act3":
		glass_a = Color("#B7BEC6")
		glass_b = Color("#CFD5DC")
		glass_hi = Color("#E7EBF0")

	# Moldura externa fechada dos 4 lados (32x31 px em rows 0..1)
	_rect_g(img, x0 + 1, y0 + 1, 30, 29, out_c, variant)
	_rect_g(img, x0 + 2, y0 + 2, 28, 25, wood_md, variant)
	_rect_g(img, x0 + 2, y0 + 2, 28, 1, wood_hi, variant)
	_rect_g(img, x0 + 2, y0 + 2, 1, 25, wood_hi, variant)
	_rect_g(img, x0 + 29, y0 + 2, 1, 25, wood_dk, variant)

	# 4 vidraças simétricas com travessas centrais horizontais e verticais completas
	for py in [y0 + 5, y0 + 16]:
		for px in [x0 + 5, x0 + 17]:
			_rect_g(img, px, py, 10, 9, out_c, variant)
			_rect_g(img, px + 1, py + 1, 8, 7, glass_a, variant)
			_rect_g(img, px + 1, py + 1, 5, 5, glass_b, variant)
			_rect_g(img, px + 2, py + 2, 2, 2, glass_hi, variant)
			_set_g(img, px + 4, py + 3, glass_hi, variant)

	# Travessa central em cruz (100% fechada dentro da moldura)
	_rect_g(img, x0 + 15, y0 + 4, 2, 22, wood_dk, variant)
	_rect_g(img, x0 + 4, y0 + 14, 24, 2, wood_dk, variant)
	_rect_g(img, x0 + 4, y0 + 14, 24, 1, wood_md, variant)

	# Peitoril inferior completo projetado para frente
	_rect_g(img, x0, y0 + 27, 32, 4, out_c, variant)
	_rect_g(img, x0 + 1, y0 + 27, 30, 1, wood_hi, variant)
	_rect_g(img, x0 + 1, y0 + 28, 30, 2, sill_c, variant)

	# Sombra sutil sob o peitoril no piso (sem bloco sólido pendurado)
	P.rect_px(img, x0 + 1, y0 + 31, 30, 4, Color(0.03, 0.03, 0.06, 0.24))


static func draw_interior_chairs(img: Image, chair_origin: Vector2i, variant: String) -> void:
	# 4 cadeiras direcionais em carvalho combinando com a mesa de madeira (0..3, 5)
	P.clear_tiles_rect(img, chair_origin, Vector2i(4, 1))
	var out_c := Color("#161114")
	var wood_hi := Color("#AE825B")
	var wood_md := Color("#8B6240")
	var wood_dk := Color("#5D3D24")
	var sh_c := Color(0.03, 0.03, 0.06, 0.30)

	# Col +0: chair_down (norte da mesa / espera — encosto em cima, frente para baixo)
	var c0 := chair_origin.x * 16
	var y0 := chair_origin.y * 16
	P.rect_px(img, c0 + 2, y0 + 13, 12, 2, sh_c)
	_rect_g(img, c0 + 3, y0 + 1, 10, 13, out_c, variant)
	_rect_g(img, c0 + 4, y0 + 2, 8, 4, wood_md, variant)
	_rect_g(img, c0 + 4, y0 + 2, 8, 1, wood_hi, variant)
	_rect_g(img, c0 + 4, y0 + 6, 8, 5, wood_hi, variant)
	_rect_g(img, c0 + 4, y0 + 10, 8, 1, wood_dk, variant)
	_rect_g(img, c0 + 4, y0 + 11, 2, 3, wood_dk, variant)
	_rect_g(img, c0 + 10, y0 + 11, 2, 3, wood_dk, variant)
	P.rect_px(img, c0 + 6, y0 + 11, 4, 3, Color(0, 0, 0, 0))

	# Col +1: chair_up (sul da mesa — encosto voltado para a câmera embaixo)
	var c1 := (chair_origin.x + 1) * 16
	P.rect_px(img, c1 + 2, y0 + 13, 12, 2, sh_c)
	_rect_g(img, c1 + 3, y0 + 3, 10, 11, out_c, variant)
	_rect_g(img, c1 + 4, y0 + 4, 8, 2, wood_dk, variant)
	_rect_g(img, c1 + 4, y0 + 6, 8, 5, wood_md, variant)
	_rect_g(img, c1 + 4, y0 + 6, 8, 1, wood_hi, variant)
	_rect_g(img, c1 + 4, y0 + 11, 2, 3, wood_dk, variant)
	_rect_g(img, c1 + 10, y0 + 11, 2, 3, wood_dk, variant)
	P.rect_px(img, c1 + 6, y0 + 11, 4, 3, Color(0, 0, 0, 0))

	# Col +2: chair_right (lado esquerdo da mesa — encosto na esquerda, olhando direita)
	var c2 := (chair_origin.x + 2) * 16
	P.rect_px(img, c2 + 3, y0 + 13, 12, 2, sh_c)
	_rect_g(img, c2 + 4, y0 + 2, 3, 12, out_c, variant)
	_rect_g(img, c2 + 5, y0 + 3, 2, 8, wood_md, variant)
	_rect_g(img, c2 + 5, y0 + 3, 2, 1, wood_hi, variant)
	_rect_g(img, c2 + 6, y0 + 6, 9, 5, out_c, variant)
	_rect_g(img, c2 + 6, y0 + 7, 8, 3, wood_hi, variant)
	_rect_g(img, c2 + 5, y0 + 11, 2, 3, wood_dk, variant)
	_rect_g(img, c2 + 12, y0 + 11, 2, 3, wood_dk, variant)

	# Col +3: chair_left (lado direito da mesa — encosto na direita, olhando esquerda)
	var c3 := (chair_origin.x + 3) * 16
	P.rect_px(img, c3 + 1, y0 + 13, 12, 2, sh_c)
	_rect_g(img, c3 + 9, y0 + 2, 3, 12, out_c, variant)
	_rect_g(img, c3 + 9, y0 + 3, 2, 8, wood_md, variant)
	_rect_g(img, c3 + 9, y0 + 3, 2, 1, wood_hi, variant)
	_rect_g(img, c3 + 1, y0 + 6, 9, 5, out_c, variant)
	_rect_g(img, c3 + 2, y0 + 7, 8, 3, wood_hi, variant)
	_rect_g(img, c3 + 2, y0 + 11, 2, 3, wood_dk, variant)
	_rect_g(img, c3 + 9, y0 + 11, 2, 3, wood_dk, variant)
