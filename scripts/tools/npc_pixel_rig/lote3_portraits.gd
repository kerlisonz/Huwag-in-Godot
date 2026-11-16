extends RefCounted
class_name Lote3Portraits

## Lote 3 — Sistema Unificado de Retratos 16-bit SNES/CRT (64x64 nativos exportados em 4x = 256x256 Nearest Neighbor)
## Arte orgânica 3/4 com separação interna de contorno (ink), iluminação top-left limpa sem ruído procedural,
## anatomia facial expressiva e variantes normal/distorcida individuais para todos os 15 locutores.

const PORTRAITS_LOTE3_DIR := "res://assets/sprites/portraits"
const PORTRAITS_LEGACY_DIR := "res://assets/characters/portraits"
const SIZE := 64
const EXPORT_SCALE := 4


static func _ensure_dirs() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(PORTRAITS_LOTE3_DIR))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(PORTRAITS_LEGACY_DIR))


static func _px(img: Image, x: int, y: int, c: Color) -> void:
	if x >= 0 and y >= 0 and x < SIZE and y < SIZE:
		img.set_pixel(x, y, c)


static func _fill_span(img: Image, x0: int, x1: int, y: int, c: Color) -> void:
	if y < 0 or y >= SIZE:
		return
	for x in range(maxi(0, mini(x0, x1)), mini(SIZE - 1, maxi(x0, x1)) + 1):
		img.set_pixel(x, y, c)


static func _fill_disc(img: Image, cx: float, cy: float, rx: float, ry: float, c: Color) -> void:
	var y0 := maxi(1, int(floor(cy - ry)))
	var y1 := mini(SIZE - 2, int(ceil(cy + ry)))
	for y in range(y0, y1 + 1):
		var dy := (float(y) - cy) / maxf(ry, 0.5)
		if dy * dy > 1.0:
			continue
		var hw := rx * sqrt(1.0 - dy * dy)
		_fill_span(img, int(round(cx - hw)), int(round(cx + hw)), y, c)


static func _draw_line_px(img: Image, x0: int, y0: int, x1: int, y1: int, c: Color) -> void:
	var steps := maxi(abs(x1 - x0), abs(y1 - y0))
	if steps == 0:
		_px(img, x0, y0, c)
		return
	for i in range(steps + 1):
		var t := float(i) / float(steps)
		_px(img, int(round(lerpf(float(x0), float(x1), t))), int(round(lerpf(float(y0), float(y1), t))), c)


static func _outline_fg(fg: Image, ink: Color) -> void:
	var src := fg.duplicate() as Image
	var dirs: Array[Vector2i] = [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]
	for y in range(1, SIZE - 1):
		for x in range(1, SIZE - 1):
			if src.get_pixel(x, y).a > 0.45:
				continue
			for d in dirs:
				if src.get_pixel(x + d.x, y + d.y).a > 0.55:
					fg.set_pixel(x, y, ink)
					break


static func _skin_ramp(base_hex: String, distorted: bool, mode: String = "warm") -> Array[Color]:
	var c := Color(base_hex)
	if distorted:
		if mode == "cold":
			c = c.lerp(Color("#7A8694"), 0.54)
		elif mode == "ash":
			c = c.lerp(Color("#544549"), 0.58)
		else:
			c = c.lerp(Color("#695256"), 0.48)
	return [
		c.lightened(0.18),
		c,
		c.darkened(0.22),
		c.darkened(0.42),
		c.darkened(0.64),
	]


static func _paint_backdrop(bg_top: Color, bg_bot: Color, accent: Color, distorted: bool) -> Image:
	var img := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	if distorted:
		bg_top = bg_top.lerp(Color("#1A060B"), 0.72)
		bg_bot = bg_bot.lerp(Color("#0D0206"), 0.82)
		accent = Color("#C93442")
	for y in range(SIZE):
		var t := float(y) / float(SIZE - 1)
		var base := bg_top.lerp(bg_bot, t)
		var crt := 0.96 if (y % 2 == 1) else 1.0
		for x in range(SIZE):
			var dx := absf(float(x) - 31.5) / 31.5
			var dy := absf(float(y) - 31.5) / 31.5
			var vig := clampf(1.0 - (dx * dx + dy * dy) * 0.24, 0.72, 1.0)
			img.set_pixel(x, y, Color(base.r * crt * vig, base.g * crt * vig, base.b * crt * vig, 1.0))
	for i in range(SIZE):
		img.set_pixel(i, 0, accent)
		img.set_pixel(i, SIZE - 1, accent)
		img.set_pixel(0, i, accent)
		img.set_pixel(SIZE - 1, i, accent)
	for i in range(1, SIZE - 1):
		img.set_pixel(i, 1, Color("#0A0A0E"))
		img.set_pixel(i, SIZE - 2, Color("#0A0A0E"))
		img.set_pixel(1, i, Color("#0A0A0E"))
		img.set_pixel(SIZE - 2, i, Color("#0A0A0E"))
	var corner_pts: Array[Vector2i] = [Vector2i(3, 3), Vector2i(SIZE - 4, 3), Vector2i(3, SIZE - 4), Vector2i(SIZE - 4, SIZE - 4)]
	for cxy in corner_pts:
		img.set_pixel(cxy.x, cxy.y, accent.lightened(0.24))
	return img


static func _smooth_half_width(t: float, body_type: String, is_right: bool) -> float:
	# Curva C1 suave usando amostra Hermite/cosseno (zero cantos geométricos abruptos)
	var s_jaw := 1.0 if body_type == "broad_command" else (0.86 if body_type == "slender_feminine" else (0.90 if body_type == "child" else 0.92))
	var max_w := (14.2 if body_type == "broad_command" else (12.0 if body_type == "child" else 13.0))
	if is_right:
		max_w -= 1.2  # rotação 3/4 sutil para a direita
	var w := 0.0
	if t <= 0.34:
		var u := t / 0.34
		w = max_w * (0.34 + 0.66 * sin(u * PI * 0.5))
	elif t <= 0.68:
		var u2 := (t - 0.34) / 0.34
		w = max_w * lerpf(1.0, 0.90 * s_jaw, 0.5 - 0.5 * cos(u2 * PI))
	else:
		var u3 := (t - 0.68) / 0.32
		var end_w := 5.2 if body_type == "broad_command" else (3.8 if body_type == "slender_feminine" else 4.4)
		if is_right:
			end_w -= 0.5
		w = lerpf(max_w * 0.90 * s_jaw, end_w, pow(u3, 1.08))
	return w


static func _sculpt_bust_anatomy(
	fg: Image, body_type: String, skin: Array[Color],
	cloth_hi: Color, cloth_mid: Color, cloth_sh: Color,
	y_shift: int, distorted: bool
) -> Dictionary:
	var is_child := (body_type == "child")
	var is_broad := (body_type == "broad_command")
	var ink := Color("#160E12")

	var sh_l := 11 if is_broad else (16 if is_child else 13)
	var sh_r := 53 if is_broad else (48 if is_child else 51)
	var neck_l := 26 if is_broad else (28 if is_child else 27)
	var neck_r := 38 if is_broad else (36 if is_child else 37)

	# 1. Tronco & Ombros com dobra suave de iluminação top-left
	var torso_top := 45 + y_shift
	for y in range(torso_top, 62):
		var prog := clampf(float(y - torso_top) / 8.0, 0.0, 1.0)
		var curve := sin(prog * PI * 0.5)
		var xl := int(round(lerpf(float(neck_l - 2), float(sh_l), curve)))
		var xr := int(round(lerpf(float(neck_r + 2), float(sh_r), curve)))
		for x in range(xl, xr + 1):
			var nx := float(x - xl) / maxf(float(xr - xl), 1.0)
			var col := cloth_mid
			if nx < 0.30 and y < torso_top + 9:
				col = cloth_hi
			elif nx > 0.72:
				col = cloth_sh
			_px(fg, x, y, col)
		# Borda escura do ombro esquerdo/direito ao redor da clavícula
		if y < torso_top + 6:
			_px(fg, xl, y, cloth_sh.darkened(0.35))
			_px(fg, xr, y, cloth_sh.darkened(0.45))

	# 2. Pescoço com sombra projetada limpa sob o queixo
	for y in range(38 + y_shift, 49 + y_shift):
		for x in range(neck_l, neck_r + 1):
			var col := skin[2] if y <= 44 + y_shift else skin[1]
			if x >= neck_r - 2:
				col = skin[3]
			_px(fg, x, y, col)
		_px(fg, neck_l - 1, y, ink)
		_px(fg, neck_r + 1, y, ink)
	for dy in range(4):
		_fill_span(fg, 28 + dy, 36 - dy, 46 + y_shift + dy, skin[2] if dy > 1 else skin[1])
	_fill_span(fg, 27, 37, 45 + y_shift, skin[3])

	# 3. Orelhas bilaterais (ancoragem orgânica antes do rosto!)
	var ear_y := 26 + y_shift + (2 if is_child else 0)
	var ear_lx := int(round(32.0 - _smooth_half_width(0.48, body_type, false)))
	var ear_rx := int(round(32.0 + _smooth_half_width(0.48, body_type, true)))
	for dy in range(6):
		_fill_span(fg, ear_lx - 2, ear_lx + 1, ear_y + dy, skin[1] if dy < 4 else skin[2])
		_fill_span(fg, ear_rx - 1, ear_rx + 1, ear_y + dy, skin[2] if dy < 4 else skin[3])
	_px(fg, ear_lx - 1, ear_y + 2, skin[3]); _px(fg, ear_lx - 1, ear_y + 3, skin[2])
	_px(fg, ear_rx, ear_y + 2, skin[3])

	# 4. Cabeça & Mandíbula suaves com separação de contorno interno no queixo
	var head_top := 12 + y_shift + (3 if is_child else 0)
	var chin_y := 43 + y_shift
	var row_xl: Dictionary = {}
	var row_xr: Dictionary = {}
	for y in range(head_top, chin_y + 1):
		var t := float(y - head_top) / float(chin_y - head_top)
		var xl := int(round(32.0 - _smooth_half_width(t, body_type, false)))
		var xr := int(round(32.0 + _smooth_half_width(t, body_type, true)))
		row_xl[y] = xl
		row_xr[y] = xr
		for x in range(xl, xr + 1):
			var col := skin[1]
			# Sombreamento lateral direito gentil e uniforme (sem degraus!)
			if x >= xr - 1:
				col = skin[2]
			if distorted and x >= xr - 2 and t > 0.35:
				col = skin[3]
			_px(fg, x, y, col)
		# Traço sutil de contorno ao longo da mandíbula e queixo
		if t > 0.72:
			_px(fg, xl, y, skin[4])
			_px(fg, xr, y, skin[4])
	_fill_span(fg, row_xl[chin_y], row_xr[chin_y], chin_y, skin[4])
	_fill_span(fg, row_xl[chin_y] + 1, row_xr[chin_y] - 1, chin_y - 1, skin[3])

	# 5. Destaques anatômicos localizados (maçã do rosto esquerda, testa central, queixo)
	var ey := 26 + y_shift + (2 if is_child else 0)
	_fill_span(fg, 22, 26, ey + 4, skin[0])
	_fill_span(fg, 23, 25, ey + 5, skin[0])
	_fill_span(fg, 30, 34, chin_y - 2, skin[0])

	return {
		"head_top": head_top,
		"chin_y": chin_y,
		"eye_y": ey,
		"eye_l_x": 24,
		"eye_r_x": 35,
		"nose_x": 32,
		"nose_y": ey + 5,
		"mouth_y": chin_y - 5,
		"row_xl": row_xl,
		"row_xr": row_xr,
	}


static func _draw_face_features(fg: Image, lm: Dictionary, spec: Dictionary, skin: Array[Color], distorted: bool) -> void:
	var ey: int = lm["eye_y"]
	var elx: int = lm["eye_l_x"]  # 24..27 (4px)
	var erx: int = lm["eye_r_x"]  # 35..38 (4px)
	var mood: String = spec.get("mood", "calm")
	var brow_c: Color = spec.get("brow_color", Color("#2B1A14"))
	var iris_c: Color = spec.get("iris_color", Color("#3B2318"))
	var age: int = spec.get("age", 30)
	if distorted:
		brow_c = brow_c.darkened(0.35)

	if distorted:
		# Órbitas encovadas simétricas limpas sem invadir a bochecha direita
		_fill_disc(fg, float(elx) + 1.5, float(ey) + 0.5, 2.5, 2.0, skin[3])
		_fill_disc(fg, float(erx) + 1.5, float(ey) + 0.5, 2.5, 2.0, skin[3])
		_fill_span(fg, elx, elx + 3, ey, Color("#0E080D"))
		_fill_span(fg, elx, elx + 3, ey + 1, Color("#0E080D"))
		_fill_span(fg, erx, erx + 3, ey, Color("#0E080D"))
		_fill_span(fg, erx, erx + 3, ey + 1, Color("#0E080D"))

		# Sobrancelha tensa franzida
		_fill_span(fg, elx, elx + 2, ey - 3, brow_c); _px(fg, elx + 3, ey - 2, brow_c)
		_fill_span(fg, erx + 1, erx + 3, ey - 3, brow_c); _px(fg, erx, ey - 2, brow_c)

		var glow_mode: String = spec.get("dist_eye", "red_pin")
		if glow_mode == "red_pin":
			_px(fg, elx + 2, ey + 1, Color("#FF4A4E"))
			_px(fg, erx + 1, ey + 1, Color("#FF4A4E"))
		elif glow_mode == "pale_wide":
			_fill_span(fg, elx, elx + 3, ey, Color("#DFE6F0"))
			_fill_span(fg, erx, erx + 3, ey, Color("#DFE6F0"))
			_px(fg, elx + 2, ey, Color("#110E14")); _px(fg, elx + 2, ey + 1, Color("#110E14"))
			_px(fg, erx + 1, ey, Color("#110E14")); _px(fg, erx + 1, ey + 1, Color("#110E14"))
		elif glow_mode == "amber_void":
			_px(fg, elx + 2, ey, Color("#FF9F38")); _px(fg, elx + 2, ey + 1, Color("#FFD670"))
			_px(fg, erx + 1, ey, Color("#FF9F38")); _px(fg, erx + 1, ey + 1, Color("#FFD670"))
		elif glow_mode == "hollow_black":
			_px(fg, elx + 2, ey + 1, Color("#B8304A"))
			_px(fg, erx + 1, ey + 1, Color("#B8304A"))
			_px(fg, elx + 1, ey + 2, skin[4]); _px(fg, elx + 1, ey + 3, skin[3])
	else:
		var lash := Color("#1C100C")
		var sclera := Color("#F4EFE6")

		# Sobrancelhas limpas expressivas
		if mood == "stern":
			_fill_span(fg, elx, elx + 2, ey - 3, brow_c); _px(fg, elx + 3, ey - 2, brow_c)
			_fill_span(fg, erx + 1, erx + 3, ey - 3, brow_c); _px(fg, erx, ey - 2, brow_c)
		elif mood == "elder_sad":
			_px(fg, elx, ey - 2, brow_c); _fill_span(fg, elx + 1, elx + 3, ey - 3, brow_c)
			_fill_span(fg, erx, erx + 2, ey - 3, brow_c); _px(fg, erx + 3, ey - 2, brow_c)
		else:
			_fill_span(fg, elx, elx + 3, ey - 3, brow_c)
			_fill_span(fg, erx, erx + 3, ey - 3, brow_c)

		# Olho esquerdo (4x2/3 limpo com íris escura e brilho branco)
		_fill_span(fg, elx, elx + 3, ey - 1, lash)
		_fill_span(fg, elx, elx + 3, ey, sclera)
		_fill_span(fg, elx, elx + 3, ey + 1, sclera)
		_fill_span(fg, elx + 1, elx + 2, ey, iris_c)
		_fill_span(fg, elx + 1, elx + 2, ey + 1, Color("#150D0A"))
		_px(fg, elx + 1, ey, Color("#FFFFFF"))
		if mood in ["warm", "kid"]:
			_px(fg, elx - 1, ey, lash)

		# Olho direito simétrico (4x2/3)
		_fill_span(fg, erx, erx + 3, ey - 1, lash)
		_fill_span(fg, erx, erx + 3, ey, sclera)
		_fill_span(fg, erx, erx + 3, ey + 1, sclera)
		_fill_span(fg, erx + 1, erx + 2, ey, iris_c)
		_fill_span(fg, erx + 1, erx + 2, ey + 1, Color("#150D0A"))
		_px(fg, erx + 1, ey, Color("#FFFFFF"))
		if mood in ["warm", "kid"]:
			_px(fg, erx + 4, ey, lash)

		# Pálpebra inferior suave (olheiras / idade sem manchas duras)
		if spec.get("tired_eyes", false) or age >= 50:
			_fill_span(fg, elx + 1, elx + 2, ey + 2, skin[2])
			_fill_span(fg, erx + 1, erx + 2, ey + 2, skin[2])

	# Nariz esculpido em 3/4 (ponte iluminada + sombra limpa sob a ponta)
	var nx: int = lm["nose_x"]
	var ny: int = lm["nose_y"]
	_px(fg, nx, ny - 2, skin[0])
	_px(fg, nx, ny - 1, skin[0])
	_px(fg, nx + 1, ny, skin[0])
	_fill_span(fg, nx - 1, nx + 1, ny + 1, skin[3])
	_px(fg, nx, ny + 1, skin[4])

	# Vincos nasogenianos discretos apenas para idosos/distorção
	if age >= 54:
		_px(fg, 27, ny + 2, skin[2])
		_px(fg, 36, ny + 2, skin[2])

	# Boca / Bigode / Lábio
	var my: int = lm["mouth_y"]
	var lip_col := Color("#4A221E") if distorted else Color("#7E4335")
	if spec.get("mustache", false):
		var mc: Color = spec.get("mustache_color", Color("#6B6F78"))
		if distorted:
			mc = mc.darkened(0.45)
		_fill_span(fg, 28, 35, my - 2, mc)
		_fill_span(fg, 27, 36, my - 1, mc.darkened(0.22))
		_fill_span(fg, 30, 34, my + 1, lip_col)
	elif distorted:
		_fill_span(fg, 29, 34, my, Color("#1E0A0F"))
		_px(fg, 28, my + 1, lip_col)
		_px(fg, 35, my + 1, lip_col)
	elif mood in ["warm", "kid"]:
		_fill_span(fg, 29, 34, my, lip_col)
		_px(fg, 28, my - 1, lip_col); _px(fg, 35, my - 1, lip_col)
		_fill_span(fg, 30, 33, my + 1, skin[0])
	else:
		_fill_span(fg, 29, 34, my, lip_col)
		_fill_span(fg, 30, 33, my + 1, skin[0])


static func _paint_curved_crown(fg: Image, cx: float, cy: float, rx: float, ry: float, ey_cutoff: int, col_fn: Callable) -> void:
	var y0 := maxi(3, int(floor(cy - ry)))
	var y1 := mini(ey_cutoff, int(ceil(cy + ry)))
	for y in range(y0, y1 + 1):
		var dy := float(y - cy) / maxf(ry, 1.0)
		if dy * dy > 1.0:
			continue
		var hw := rx * sqrt(1.0 - dy * dy)
		for x in range(int(round(cx - hw)), int(round(cx + hw)) + 1):
			_px(fg, x, y, col_fn.call(x, y))


static func _draw_hair_back_and_locks(fg: Image, lm: Dictionary, spec: Dictionary, distorted: bool) -> void:
	var h_col: Color = spec.get("hair_color", Color("#1F2028"))
	if distorted:
		h_col = h_col.darkened(0.36)
	var h_hi := h_col.lightened(0.24)
	var h_sh := h_col.darkened(0.36)
	var ht: int = lm["head_top"]
	var ey: int = lm["eye_y"]
	var row_xl: Dictionary = lm["row_xl"]
	var row_xr: Dictionary = lm["row_xr"]
	var style: String = spec.get("hair_style", "short")

	match style:
		"short", "commander_sides":
			_paint_curved_crown(fg, 32.0, float(ht + 4), 14.0, 8.0, ey - 4, func(x: int, y: int) -> Color:
				return h_hi if (y < ht + 1 and x < 33) else h_col
			)
			for y in range(ht + 5, ey + 2):
				var xl: int = row_xl.get(y, 19)
				var xr: int = row_xr.get(y, 44)
				_fill_span(fg, xl - 1, xl + 1, y, h_col)
				_fill_span(fg, xr - 1, xr + 1, y, h_sh)
			if style == "commander_sides":
				var silv := Color("#BCC4CE") if not distorted else Color("#6C737D")
				_fill_span(fg, 18, 20, ey - 1, silv)
				_fill_span(fg, 18, 20, ey, silv.darkened(0.22))
				_fill_span(fg, 43, 44, ey - 1, silv.darkened(0.25))
		"curly_dark":
			# Cachos orgânicos volumosos (Bombeiro Santos) — clusters em camadas com rim light contínuo
			var rim := Color("#4B638C") if not distorted else Color("#6B242F")
			_paint_curved_crown(fg, 32.0, float(ey - 8), 16.0, 12.0, ey - 4, func(_x: int, _y: int) -> Color:
				return h_col
			)
			_fill_disc(fg, 25.0, float(ht + 2), 4.5, 3.0, h_hi)
			_fill_disc(fg, 32.0, float(ht + 1), 4.0, 2.5, h_hi)
			_fill_disc(fg, 39.0, float(ht + 3), 4.0, 2.8, h_sh)
			# Arco suave contínuo de rim light no contorno superior esquerdo dos cachos
			for rx in range(20, 39):
				var t_r := float(rx - 32) / 16.0
				var ry := int(round(float(ey - 8) - 11.2 * sqrt(maxf(0.0, 1.0 - t_r * t_r))))
				_px(fg, rx, ry, rim)
			# Recorte de franja cacheada na testa + costeletas atrás das orelhas (respeitando olhos!)
			for mx in [20, 26, 32, 38]:
				_fill_disc(fg, float(mx), float(ey - 5), 2.5, 1.8, h_col)
				_px(fg, mx, ey - 3, h_sh)
			for y in range(ey - 4, ey + 2):
				var xl: int = row_xl.get(y, 19)
				var xr: int = row_xr.get(y, 44)
				_fill_span(fg, xl - 1, xl + 1, y, h_col)
				_fill_span(fg, xr - 1, xr + 1, y, h_sh)
		"maria_bun":
			# Coque baixo + cabelo castanho fluido emoldurando as têmporas com presilha vermelha
			_paint_curved_crown(fg, 32.0, float(ey - 7), 15.6, 11.5, ey - 4, func(x: int, y: int) -> Color:
				if y == ht + 1 and x >= 22 and x <= 38:
					return h_hi
				return h_col
			)
			# Franja assimétrica suave que limpa os olhos
			for x in range(20, 44):
				var cut_y := ey - 4 if x < 31 else ey - 5
				for y in range(ey - 7, cut_y + 1):
					_px(fg, x, y, h_sh if y == cut_y else h_col)
			for y in range(ey - 4, ey + 8):
				var xl: int = row_xl.get(y, 19)
				var xr: int = row_xr.get(y, 44)
				_fill_span(fg, xl - 2, xl, y, h_col)
				_fill_span(fg, xr, xr + 2, y, h_sh)
			# Coque baixo elegante atrás da orelha esquerda + fita vermelha
			_fill_disc(fg, 16.0, float(ey + 6), 3.2, 4.2, h_sh)
			_fill_disc(fg, 15.5, float(ey + 5), 2.2, 3.0, h_col)
			_fill_span(fg, 16, 18, ey + 2, Color("#D63C4D"))
		"nena_bob":
			# Cabelo ondulado com presilha coral na lateral (sem faixa de capacete!)
			_paint_curved_crown(fg, 32.0, float(ey - 7), 15.8, 11.5, ey - 4, func(x: int, y: int) -> Color:
				if y == ht + 2 and x >= 22 and x <= 37:
					return h_hi
				return h_col
			)
			for y in range(ey - 5, ey + 9):
				var xl: int = row_xl.get(y, 19)
				var xr: int = row_xr.get(y, 44)
				_fill_span(fg, xl - 2, xl + 1, y, h_col)
				_fill_span(fg, xr - 1, xr + 2, y, h_sh)
			_fill_span(fg, 18, 22, ey - 4, h_col)
			_fill_span(fg, 40, 44, ey - 4, h_sh)
			# Fivela coral elegante acima da orelha esquerda
			var clip_c := Color("#EB5B73") if not distorted else Color("#702431")
			_fill_span(fg, 20, 22, ey - 5, clip_c)
			_px(fg, 21, ey - 6, clip_c.lightened(0.2))
		"silver_bun":
			# Coque prateado alto (pusod) com penteado em ondas macias e pente de tartaruga
			_fill_disc(fg, 31.5, float(ht - 3), 7.2, 4.8, h_col)
			_fill_disc(fg, 30.0, float(ht - 4), 4.5, 2.5, h_hi)
			_paint_curved_crown(fg, 32.0, float(ey - 7), 15.0, 10.2, ey - 4, func(x: int, y: int) -> Color:
				return h_hi if x < 31 and y < ht + 3 else (h_sh if x > 40 else h_col)
			)
			_fill_span(fg, 27, 36, ht + 1, Color("#6E4226") if not distorted else Color("#382114"))
			for y in range(ey - 5, ey + 5):
				var xl: int = row_xl.get(y, 19)
				var xr: int = row_xr.get(y, 44)
				_fill_span(fg, xl - 1, xl + 1, y, h_col)
				_fill_span(fg, xr - 1, xr + 1, y, h_sh)
		"lola_braid":
			# Trança prateada ondulada contínua emoldurando suavemente o ombro esquerdo (Lola Rosa)
			var silv := Color("#DCE1EC") if not distorted else Color("#7A7D88")
			var silv_hi := silv.lightened(0.14)
			var silv_sh := silv.darkened(0.30)
			for y in range(ey + 2, ey + 19):
				var prog := float(y - (ey + 2)) / 16.0
				var bx := 18.0 + sin(prog * 1.4) * 1.5 + prog * 3.0
				var bw := 2.4 - prog * 0.7
				_fill_span(fg, int(round(bx - bw)), int(round(bx + bw)), y, silv)
				_px(fg, int(round(bx - bw + 0.5)), y, silv_hi)
				_px(fg, int(round(bx + bw)), y, silv_sh)
				if y % 3 == 0:
					_px(fg, int(round(bx)), y, silv_sh)
			_fill_span(fg, 20, 22, ey + 19, Color("#732D3B"))
			_px(fg, 21, ey + 20, silv_sh)
		"kid_bangs":
			# Mechas bagunçadas do Toby sob o boné
			_fill_span(fg, 19, 22, ey - 3, h_col)
			_fill_span(fg, 23, 27, ey - 5, h_col); _px(fg, 25, ey - 4, h_hi)
			_fill_span(fg, 31, 34, ey - 5, h_col); _px(fg, 32, ey - 4, h_hi)
			_fill_span(fg, 39, 43, ey - 4, h_sh)


static func _draw_hat_and_accessories(fg: Image, lm: Dictionary, spec: Dictionary, skin: Array[Color], distorted: bool) -> void:
	var hat: String = spec.get("hat", "none")
	var ey: int = lm["eye_y"]
	var ht: int = lm["head_top"]
	var brim_y := ey - 5

	match hat:
		"cap_bfp":
			var navy := Color("#1E283D") if not distorted else Color("#141928")
			var n_hi := Color("#35476B") if not distorted else Color("#202A40")
			var gold := Color("#F5C443") if not distorted else Color("#9C6F28")
			_paint_curved_crown(fg, 32.0, float(brim_y - 4), 16.5, 9.2, brim_y, func(x: int, y: int) -> Color:
				return n_hi if (y < ht + 1 and x < 35) else navy
			)
			_fill_disc(fg, 32.5, float(ht - 1), 2.3, 2.3, gold)
			_px(fg, 32, ht - 2, Color("#FFF3A6"))
			# Aba curva contornada
			for x in range(18, 47):
				var bow := -1 if abs(x - 32) < 6 else 0
				_px(fg, x, brim_y - 1 + bow, Color("#101521"))
				_px(fg, x, brim_y + bow, Color("#1E2A40"))
				_px(fg, x, brim_y + 1 + bow, Color("#0C1018"))
			_fill_span(fg, 21, 43, brim_y + 2, skin[3])
		"helmet_yellow":
			var y_hi := Color("#FFE05C") if not distorted else Color("#8A6228")
			var y_mid := Color("#E5A824") if not distorted else Color("#61401B")
			var y_sh := Color("#9E6414") if not distorted else Color("#38210E")
			# Protetor de nuca discreto atrás das orelhas
			for y in range(brim_y + 1, brim_y + 8):
				_fill_span(fg, 16, 18, y, y_sh)
				_fill_span(fg, 45, 47, y, y_sh.darkened(0.25))
			_paint_curved_crown(fg, 32.0, float(brim_y), 17.5, 13.5, brim_y, func(x: int, y: int) -> Color:
				if x >= 30 and x <= 34 and y < brim_y - 3:
					return y_hi
				return y_hi if (x < 29 and y < ht + 3) else (y_sh if x > 39 else y_mid)
			)
			# Escudo frontal BFP limpo
			_fill_span(fg, 30, 34, ht + 1, Color("#991B1B") if not distorted else Color("#4D1214"))
			_fill_span(fg, 31, 33, ht + 2, Color("#F5C443") if not distorted else Color("#8F5F22"))
			for x in range(17, 47):
				var bow := -1 if abs(x - 32) < 7 else 0
				_px(fg, x, brim_y - 1 + bow, Color("#1D222B"))
				_px(fg, x, brim_y + bow, Color("#374152"))
			if distorted:
				# Rachadura térmica limpa na lateral direita da copa
				_draw_line_px(fg, 36, ht - 1, 39, brim_y - 2, Color("#1A0B0D"))
				_px(fg, 37, ht + 1, Color("#FF6A2B")); _px(fg, 38, ht + 2, Color("#FFB84D"))
			_fill_span(fg, 20, 44, brim_y + 1, skin[3])
		"trucker_cap":
			var bl := Color("#2B4878") if not distorted else Color("#19263D")
			var bl_h := Color("#4871B3") if not distorted else Color("#283C5E")
			_paint_curved_crown(fg, 32.0, float(brim_y), 15.8, 10.8, brim_y, func(x: int, y: int) -> Color:
				if x >= 28 and x <= 36 and y >= ht and y <= ht + 3:
					return Color("#DFE5EE") if not distorted else Color("#6E7480")
				return bl_h if (y < ht + 2 and x < 35) else bl
			)
			for x in range(20, 49):
				var bow := -1 if (x >= 28 and x <= 39) else 0
				_px(fg, x, brim_y + bow, Color("#1A2D4F"))
				_px(fg, x, brim_y + 1 + bow, Color("#101A2E"))
			_fill_span(fg, 21, 43, brim_y + 2, skin[3])
		"salakot":
			# Salakot cônico côncavo com nervuras radiais curvas (ZERO moiré x+y!)
			var st_h := Color("#E8C46D") if not distorted else Color("#6E5835")
			var st_m := Color("#C2943C") if not distorted else Color("#4F3D24")
			var st_s := Color("#855A1E") if not distorted else Color("#2E2112")
			var top_y := ht - 10
			for y in range(top_y, brim_y + 2):
				var t := float(y - top_y) / float(maxi(1, brim_y + 1 - top_y))
				var half := int(2.0 + pow(t, 1.32) * 24.0)
				for x in range(32 - half, 33 + half):
					_px(fg, x, y, st_h if x < 29 else (st_s if x > 39 else st_m))
			# Nervuras radiais limpas saindo do pino superior
			for slope in [-1.5, -0.75, 0.0, 0.75, 1.5]:
				for step in range(3, brim_y - top_y + 1):
					var rx := int(round(32.0 + slope * pow(float(step) / 14.0, 1.25) * 14.0))
					_px(fg, rx, top_y + step, st_s)
			_fill_span(fg, 31, 33, top_y - 1, st_s)
			_px(fg, 32, top_y - 2, Color("#F2CB57") if not distorted else st_m)
			_fill_span(fg, 16, 48, brim_y + 2, skin[3])
		"bandana_teal":
			var bd := Color("#219E9E") if not distorted else Color("#125257")
			var bd_h := Color("#45CFC7") if not distorted else Color("#23787D")
			var bd_s := bd.darkened(0.32)
			for y in range(ht + 2, brim_y + 1):
				_fill_span(fg, 18, 45, y, bd_h if y < brim_y - 2 else bd)
			_fill_span(fg, 18, 45, brim_y, bd_s)
			# Nó e pontas curvas do lenço à esquerda
			_fill_disc(fg, 16.0, float(brim_y - 2), 2.0, 2.0, bd_s)
			_draw_line_px(fg, 15, brim_y - 2, 11, brim_y + 1, bd_h)
			_draw_line_px(fg, 14, brim_y - 1, 10, brim_y + 3, bd)
		"kid_cap":
			var rc := Color("#DE4232") if not distorted else Color("#6E2A32")
			var rh := Color("#F77548") if not distorted else Color("#8F4045")
			_paint_curved_crown(fg, 32.0, float(brim_y - 1), 14.2, 9.8, brim_y - 1, func(x: int, y: int) -> Color:
				if x >= 29 and x <= 34 and y >= ht + 1 and y <= ht + 3:
					return Color("#FAF4E8") if not distorted else Color("#9AA0AB")
				return rh if (y < ht + 2 and x < 33) else rc
			)
			for x in range(14, 38):
				_px(fg, x, brim_y - 1, rc.darkened(0.28))
				_px(fg, x, brim_y, rc.darkened(0.40))
		"floral_headscarf":
			# Lenço creme clássico cobrindo suavemente o topo com UM broche floral no lado esquerdo
			var sc := Color("#EDE8DC") if not distorted else Color("#6E676B")
			var sc_h := Color("#FFFDF7") if not distorted else Color("#857E82")
			var sc_s := Color("#C2BAA9") if not distorted else Color("#464044")
			_paint_curved_crown(fg, 32.0, float(ey - 6), 16.2, 11.2, ey - 4, func(x: int, y: int) -> Color:
				if y == ht + 1 and x >= 22 and x <= 36:
					return sc_h
				return sc_s if x > 39 else sc
			)
			_fill_span(fg, 20, 44, ey - 4, sc_s)
			for y in range(ey - 4, ey + 3):
				_fill_span(fg, 16, 18, y, sc)
				_fill_span(fg, 44, 46, y, sc_s)
			# Único enfeite floral coeso de 5 pétalas acima da têmpora esquerda
			var fl_c := Color("#DE4F5E") if not distorted else Color("#612029")
			var fl_g := Color("#4B8A50") if not distorted else Color("#28422B")
			_px(fg, 23, ht + 3, fl_c); _px(fg, 25, ht + 3, fl_c)
			_px(fg, 24, ht + 2, fl_c); _px(fg, 24, ht + 4, fl_c)
			_px(fg, 24, ht + 3, Color("#F5C443") if not distorted else Color("#7A6428"))
			_px(fg, 26, ht + 4, fl_g); _px(fg, 27, ht + 4, fl_g)


static func _draw_outfit_details(fg: Image, spec: Dictionary, distorted: bool) -> void:
	var kind: String = spec.get("outfit_detail", "none")
	var sy := 47
	var dark_seam := Color("#16121A")
	match kind:
		"bfp_command":
			var white := Color("#F2ECE0") if not distorted else Color("#7A787D")
			_fill_span(fg, 24, 28, sy + 1, white); _fill_span(fg, 25, 29, sy + 2, white)
			_fill_span(fg, 36, 40, sy + 1, white); _fill_span(fg, 35, 39, sy + 2, white)
			_draw_line_px(fg, 25, sy + 3, 29, sy + 6, dark_seam)
			_draw_line_px(fg, 39, sy + 3, 35, sy + 6, dark_seam)
			_fill_span(fg, 21, 44, sy + 9, Color("#E56B24") if not distorted else Color("#7D2A1E"))
			_fill_span(fg, 19, 46, sy + 11, Color("#F5C443") if not distorted else Color("#8F6924"))
			_fill_span(fg, 21, 25, sy + 5, Color("#F5C443") if not distorted else Color("#8A6826"))
		"bfp_stripes":
			_draw_line_px(fg, 25, sy + 1, 29, sy + 5, dark_seam)
			_draw_line_px(fg, 39, sy + 1, 35, sy + 5, dark_seam)
			_fill_span(fg, 16, 48, sy + 8, Color("#E56B24") if not distorted else Color("#872622"))
			_fill_span(fg, 15, 49, sy + 10, Color("#F5C443") if not distorted else Color("#8F5B28"))
		"maria_stethoscope":
			# Jaleco branco limpo com dobras V + estetoscópio U elegante
			var coat := Color("#F7FAFF") if not distorted else Color("#828C99")
			var coat_s := Color("#CFD9E6") if not distorted else Color("#626C78")
			for y in range(sy, 62):
				var lw := 3 + int((y - sy) * 0.25)
				_fill_span(fg, 23 - lw, 28, y, coat)
				_px(fg, 28, y, dark_seam)
				_fill_span(fg, 36, 41 + lw, y, coat_s)
				_px(fg, 36, y, dark_seam)
			var tube := Color("#1E242E")
			_draw_line_px(fg, 27, sy, 29, sy + 7, tube)
			_draw_line_px(fg, 37, sy, 35, sy + 7, tube)
			_fill_disc(fg, 32.0, float(sy + 9), 2.0, 2.0, Color("#98A4B8") if not distorted else Color("#5C6470"))
		"nena_apron":
			var ap := Color("#E6C99E") if not distorted else Color("#635244")
			var ap_s := Color("#B8986E") if not distorted else Color("#473A31")
			for y in range(sy + 1, 62):
				_fill_span(fg, 22, 24, y, ap); _px(fg, 21, y, dark_seam)
				_fill_span(fg, 40, 42, y, ap_s); _px(fg, 43, y, dark_seam)
			for y in range(sy + 8, 62):
				_fill_span(fg, 24, 40, y, ap if y > sy + 9 else ap_s)
		"ben_towel":
			# Toalha enrolada macia sobre os ombros com dobra ao redor da gola
			var tw := Color("#F0EFE8") if not distorted else Color("#6C6A70")
			var tw_s := Color("#C4C2B8") if not distorted else Color("#4C4A50")
			for y in range(sy - 1, sy + 11):
				_fill_span(fg, 22, 26, y, tw)
				_px(fg, 21, y, dark_seam); _px(fg, 27, y, dark_seam)
				_fill_span(fg, 38, 42, y, tw_s)
				_px(fg, 37, y, dark_seam); _px(fg, 43, y, dark_seam)
			_fill_span(fg, 23, 25, sy + 3, tw_s)
			_fill_span(fg, 39, 41, sy + 4, tw_s.darkened(0.2))
		"tomas_apron":
			# Avental branco limpo do feirante (ZERO manchas vermelhas!) com alças nítidas
			var ap := Color("#EFECE4") if not distorted else Color("#6E6568")
			var ap_s := Color("#C9C4B8") if not distorted else Color("#4F484B")
			for y in range(sy, sy + 3):
				_fill_span(fg, 22, 25, y, ap); _px(fg, 21, y, dark_seam)
				_fill_span(fg, 39, 42, y, ap_s); _px(fg, 43, y, dark_seam)
			for y in range(sy + 3, 62):
				_fill_span(fg, 22, 42, y, ap if y > sy + 4 else ap_s)
			_fill_span(fg, 21, 43, sy + 3, dark_seam)
			_fill_span(fg, 28, 36, sy + 10, ap_s)
		"carding_net":
			# Alça diagonal de rede/corda tecida de pescador
			var nc := Color("#C99E58") if not distorted else Color("#5E4B33")
			var nc_s := nc.darkened(0.32)
			for y in range(sy - 1, 62):
				var bx := 18 + int((y - sy) * 0.72)
				_fill_span(fg, bx, bx + 4, y, nc)
				_px(fg, bx - 1, y, dark_seam); _px(fg, bx + 5, y, dark_seam)
				if y % 3 == 0:
					_fill_span(fg, bx + 1, bx + 3, y, nc_s)
		"toby_straps":
			var ov := Color("#498C52") if not distorted else Color("#2B4736")
			var ov_s := Color("#366E3E") if not distorted else Color("#1E3326")
			for y in range(sy + 1, 62):
				_fill_span(fg, 20, 23, y, ov); _px(fg, 19, y, dark_seam); _px(fg, 24, y, dark_seam)
				_fill_span(fg, 41, 44, y, ov_s); _px(fg, 40, y, dark_seam); _px(fg, 45, y, dark_seam)
			_px(fg, 21, sy + 8, Color("#F5C443") if not distorted else Color("#856D28"))
			_px(fg, 42, sy + 8, Color("#F5C443") if not distorted else Color("#856D28"))
		"luningning_shawl":
			var sh_c := Color("#6E3278") if not distorted else Color("#3E1A47")
			var sh_h := Color("#9B50A8") if not distorted else Color("#592666")
			for y in range(sy, 62):
				var xl := 15 + int((y - sy) * 0.42)
				var xr := 49 - int((y - sy) * 0.42)
				_fill_span(fg, xl, xl + 6, y, sh_h)
				_fill_span(fg, xr - 6, xr, y, sh_c)
				_px(fg, xl - 1, y, dark_seam); _px(fg, xr + 1, y, dark_seam)
			_fill_span(fg, 26, 38, sy + 5, sh_c)
			_fill_disc(fg, 32.0, float(sy + 5), 1.6, 1.6, Color("#ECE8DC") if not distorted else Color("#7A7780"))
		"lola_baro":
			var br := Color("#F2EDE0") if not distorted else Color("#736E6A")
			var br_s := Color("#CEC3AF") if not distorted else Color("#524E4B")
			for y in range(sy + 1, sy + 5):
				var hw := 8 - (y - (sy + 1))
				_fill_span(fg, 32 - hw, 32 + hw, y, br if y < sy + 3 else br_s)
			_draw_line_px(fg, 25, sy + 2, 32, sy + 6, dark_seam)
			_draw_line_px(fg, 39, sy + 2, 32, sy + 6, dark_seam)


static func _build_human_portrait(spec: Dictionary, distorted: bool) -> Image:
	var bg := _paint_backdrop(spec["bg_top"], spec["bg_bot"], spec["accent"], distorted)
	var fg := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	fg.fill(Color(0, 0, 0, 0))

	var skin := _skin_ramp(spec["skin"], distorted, spec.get("dist_mode", "warm"))
	var chi: Color = spec["cloth_hi"]
	var cmd: Color = spec["cloth_mid"]
	var csh: Color = spec["cloth_sh"]
	if distorted:
		chi = chi.darkened(0.42); cmd = cmd.darkened(0.46); csh = csh.darkened(0.52)

	var y_shift := int(spec.get("y_shift", 0))
	var lm := _sculpt_bust_anatomy(fg, spec["body"], skin, chi, cmd, csh, y_shift, distorted)
	_draw_outfit_details(fg, spec, distorted)
	_draw_face_features(fg, lm, spec, skin, distorted)
	_draw_hair_back_and_locks(fg, lm, spec, distorted)
	_draw_hat_and_accessories(fg, lm, spec, skin, distorted)
	_outline_fg(fg, Color("#120D14"))

	for y in range(2, SIZE - 2):
		for x in range(2, SIZE - 2):
			var c := fg.get_pixel(x, y)
			if c.a > 0.5:
				bg.set_pixel(x, y, c)
	return bg


static func _build_vulto_portrait(distorted: bool) -> Image:
	var bg := _paint_backdrop(
		Color("#14080C") if not distorted else Color("#24060A"),
		Color("#090407"), Color("#B83234") if not distorted else Color("#FF4A38"), true
	)
	var fg := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	fg.fill(Color(0, 0, 0, 0))
	var soot: Array[Color] = [Color("#3B3338"), Color("#241E22"), Color("#161215"), Color("#0C090B"), Color("#070507")]
	var lm := _sculpt_bust_anatomy(fg, "lean_weathered", soot, Color("#2C2428"), Color("#1B1619"), Color("#0E0B0E"), 0, true)

	# Faixas carbonizadas do casaco BFP com brasas vivas no modo distorcido
	_fill_span(fg, 17, 48, 54, Color("#5E1F18") if not distorted else Color("#9C2A18"))
	_fill_span(fg, 16, 49, 56, Color("#7A3E1C") if not distorted else Color("#D96B24"))
	if distorted:
		_px(fg, 25, 55, Color("#FF9438")); _px(fg, 40, 56, Color("#FFE885"))

	var ey: int = lm["eye_y"]
	_fill_disc(fg, 25.5, float(ey), 2.5, 2.0, Color("#060407"))
	_fill_disc(fg, 36.5, float(ey), 2.5, 2.0, Color("#060407"))
	if distorted:
		_fill_span(fg, 25, 26, ey, Color("#FF6A2B")); _px(fg, 25, ey, Color("#FFF3A6"))
		_fill_span(fg, 36, 37, ey, Color("#FF6A2B")); _px(fg, 36, ey, Color("#FFF3A6"))
		_draw_line_px(fg, 21, 31, 24, 34, Color("#FF5E24"))
	else:
		_px(fg, 25, ey, Color("#A83A1E")); _px(fg, 36, ey, Color("#A83A1E"))

	var v_brim := ey - 5
	_paint_curved_crown(fg, 32.0, float(v_brim), 17.0, 13.0, v_brim, func(x: int, y: int) -> Color:
		return Color("#3D3438") if y < 14 and x < 34 else Color("#211C20")
	)
	_fill_span(fg, 18, 46, v_brim, Color("#0E0B0E"))
	if distorted:
		_draw_line_px(fg, 34, 15, 38, v_brim - 1, Color("#FF6A2B"))
		_px(fg, 36, 17, Color("#FFF3A6"))

	_outline_fg(fg, Color("#080508"))
	for y in range(2, SIZE - 2):
		for x in range(2, SIZE - 2):
			var c := fg.get_pixel(x, y)
			if c.a > 0.5:
				bg.set_pixel(x, y, c)
	return bg


static func _build_guardian_portrait(distorted: bool) -> Image:
	# Espírito aquático orgânico alinhado ao sprite Lote 3 da Guardiã da Lagoa (nadadeiras erguidas, joia frontal, cabelos líquidos)
	var bg_top := Color("#0B2630") if not distorted else Color("#111938")
	var bg_bot := Color("#05131A") if not distorted else Color("#070A1C")
	var acc := Color("#56D4C8") if not distorted else Color("#FFE688")
	var bg := _paint_backdrop(bg_top, bg_bot, acc, false)
	var fg := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	fg.fill(Color(0, 0, 0, 0))

	var skin_norm: Array[Color] = [Color("#A6FAF0"), Color("#56D4C8"), Color("#298696"), Color("#174C5E"), Color("#0B2936")]
	var skin_dist: Array[Color] = [Color("#E0FFFF"), Color("#6EE6ED"), Color("#25718F"), Color("#11344D"), Color("#08192C")]
	var skin: Array[Color] = skin_dist if distorted else skin_norm
	var lm := _sculpt_bust_anatomy(fg, "slender_feminine", skin, skin[1], skin[2], skin[3], 2, false)

	# Nadadeiras auriculares translúcidas varridas suavemente para CIMA (formato Naiad/Betta)
	for step in range(13):
		var t := float(step) / 12.0
		var y := int(round(lerpf(27.0, 15.0, pow(t, 0.85))))
		var lx := int(round(lerpf(19.0, 11.0, t) - sin(t * PI) * 2.0))
		var rx := int(round(lerpf(44.0, 52.0, t) + sin(t * PI) * 2.0))
		var w := int(round(lerpf(3.6, 1.0, t)))
		_fill_span(fg, lx, lx + w, y, skin[0] if t > 0.45 else skin[1])
		_fill_span(fg, rx - w, rx, y, skin[1] if t > 0.45 else skin[2])
	for y in range(28, 35):
		_fill_span(fg, 17, 19, y, skin[1])
		_fill_span(fg, 44, 46, y, skin[2])

	# Cabelos líquidos contínuos escorrendo em curvas até os ombros (ZERO estrias horizontais!)
	for y in range(15, 60):
		var t := float(y - 15) / 44.0
		var sway := sin(t * 4.5) * 1.4
		var taper := 3.2 - t * 1.2
		var lx := 18.0 - t * 2.0 + sway
		var rx := 45.0 + t * 2.0 - sway
		_fill_span(fg, int(round(lx - taper * 0.5)), int(round(lx + taper * 0.5)), y, skin[0] if t < 0.25 else skin[1])
		_fill_span(fg, int(round(rx - taper * 0.5)), int(round(rx + taper * 0.5)), y, skin[1] if t < 0.25 else skin[2])

	# Crista diadema suave em gota + gema dourada na testa
	_fill_disc(fg, 32.0, 14.5, 4.5, 2.5, skin[0])
	_fill_disc(fg, 32.0, 17.5, 1.5, 2.0, Color("#FFE688"))
	_px(fg, 32, 17, Color("#FFFFFF"))

	# Olhos dourados amendoados (mais intensos no estado hostil)
	var ey: int = lm["eye_y"]
	for ex in [24, 35]:
		_fill_span(fg, ex, ex + 3, ey - 1, Color("#0E2936"))
		_fill_span(fg, ex, ex + 3, ey, Color("#FFE688") if not distorted else Color("#FFFFFF"))
		_fill_span(fg, ex + 1, ex + 2, ey + 1, Color("#FFF7C2") if not distorted else Color("#FFE688"))
		_px(fg, ex + 1, ey, Color("#FFFFFF"))
	_px(fg, 32, lm["nose_y"], skin[2])
	_fill_span(fg, 29, 34, lm["mouth_y"], skin[2])

	if distorted:
		for pt in [Vector2i(12, 12), Vector2i(50, 13), Vector2i(14, 42), Vector2i(52, 40)]:
			_px(fg, pt.x, pt.y, Color("#A8FFFF"))

	_outline_fg(fg, Color("#091E28"))
	for y in range(2, SIZE - 2):
		for x in range(2, SIZE - 2):
			var c := fg.get_pixel(x, y)
			if c.a > 0.5:
				bg.set_pixel(x, y, c)
	return bg


static func _build_santelmo_portrait(distorted: bool) -> Image:
	# Chama gota orgânica harmonizada com o sprite Lote 3 do Santelmo
	var bg := _paint_backdrop(
		Color("#1E0A0C") if not distorted else Color("#26050F"),
		Color("#0C0304"), Color("#F59E28") if not distorted else Color("#E63244"), false
	)
	var fg := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	fg.fill(Color(0, 0, 0, 0))
	var c_d := Color("#B82716") if not distorted else Color("#850E2A")
	var c_m := Color("#EB641C") if not distorted else Color("#DE2142")
	var c_b := Color("#FAB828") if not distorted else Color("#FF7552")
	var c_c := Color("#FFF7C2") if not distorted else Color("#FFEBF0")

	# Chama gota clássica: base larga e arredondada embaixo, ponta sinuosa subindo para o topo!
	for y in range(8, 56):
		var ny := float(y - 8) / 47.0  # 0.0 = ponta alta, 1.0 = base redonda
		var sway := sin(ny * 4.8) * (3.5 * (1.0 - ny))
		var bell := pow(ny, 0.58) * sqrt(maxf(0.0, 1.0 - pow(maxf(0.0, (ny - 0.70) / 0.30), 2.0) * 0.88))
		var rx := clampf(1.2 + bell * 18.5, 1.0, 19.0)
		for x in range(int(round(32.0 + sway - rx)), int(round(32.0 + sway + rx)) + 1):
			var dist := absf(float(x) - (32.0 + sway)) / maxf(rx, 1.0)
			var col := c_d
			if dist < 0.38 and ny > 0.44 and ny < 0.88:
				col = c_c
			elif dist < 0.62 and ny > 0.28 and ny < 0.94:
				col = c_b
			elif dist < 0.84:
				col = c_m
			_px(fg, x, y, col)

	# Línguas laterais de fogo & faíscas subindo ao redor da chama
	_draw_line_px(fg, 44, 34, 48, 24, c_m); _px(fg, 48, 24, c_b)
	_draw_line_px(fg, 19, 36, 15, 25, c_m)
	_px(fg, 22, 13, c_b); _px(fg, 46, 16, c_c); _px(fg, 14, 18, c_b)

	# Olhos de brasa afilados bem centralizados no coração claro da chama
	for row_off in range(4):
		var w := 3 if row_off in [1, 2] else 2
		_fill_span(fg, 25, 25 + w, 36 + row_off, Color("#240706"))
		_fill_span(fg, 35, 35 + w, 36 + row_off, Color("#240706"))
	_px(fg, 26, 37, c_c); _px(fg, 27, 38, c_b)
	_px(fg, 37, 37, c_c); _px(fg, 36, 38, c_b)

	_outline_fg(fg, Color("#2E0808"))
	for y in range(2, SIZE - 2):
		for x in range(2, SIZE - 2):
			var c := fg.get_pixel(x, y)
			if c.a > 0.5:
				bg.set_pixel(x, y, c)
	return bg


static func _build_vhs_radio_portrait(distorted: bool) -> Image:
	var bg := _paint_backdrop(
		Color("#0E1A18") if not distorted else Color("#21090E"),
		Color("#060D0B") if not distorted else Color("#0B0305"),
		Color("#4ECDC4") if not distorted else Color("#E63946"), false
	)
	var fg := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	fg.fill(Color(0, 0, 0, 0))

	# Antena e pinos giratórios no topo
	for y in range(7, 25):
		_fill_span(fg, 20, 22, y, Color("#2F3842") if not distorted else Color("#3D252B"))
	_px(fg, 21, 6, Color("#F5CB5C") if not distorted else Color("#FF4A4E"))
	for kx in [28, 36]:
		_fill_span(fg, kx, kx + 2, 21, Color("#495566"))
		_fill_span(fg, kx, kx + 2, 22, Color("#2B333D"))

	# Corpo chanfrado do transmissor BFP
	for y in range(23, 58):
		_fill_span(fg, 17, 46, y, Color("#2B333D") if y > 26 else Color("#3E4A59"))
		_px(fg, 17, y, Color("#495768"))
		_px(fg, 46, y, Color("#1A2026"))

	# Tela CRT embutida com onda verde (Normal) vs ruído/grito vermelho-âmbar (Distorcida)
	for y in range(28, 39):
		_fill_span(fg, 21, 42, y, Color("#123027") if not distorted else Color("#2E0C12"))
	if distorted:
		for x in range(22, 42):
			var wy := 33 + int(round(sin(float(x) * 1.4) * 4.5))
			_px(fg, x, wy, Color("#FF4A4E"))
			if x % 3 == 0:
				_px(fg, x, 30 + (x % 7), Color("#FFB74D"))
		_draw_line_px(fg, 37, 28, 42, 34, Color("#0A0608"))
	else:
		for x in range(22, 42):
			var wy := 33 + int(round(sin(float(x) * 0.9) * (3.2 if x % 3 != 0 else 1.4)))
			_px(fg, x, wy, Color("#5CE6B8"))
			_px(fg, x, wy - 1, Color("#B8FFF0"))

	# Grade do alto-falante e LED de transmissão
	for gy in [43, 46, 49, 52]:
		_fill_span(fg, 22, 41, gy, Color("#14191F"))
	_fill_span(fg, 40, 42, 25, Color("#5CE6B8") if not distorted else Color("#FF4A4E"))

	_outline_fg(fg, Color("#0C1014"))
	for y in range(2, SIZE - 2):
		for x in range(2, SIZE - 2):
			var c := fg.get_pixel(x, y)
			if c.a > 0.5:
				bg.set_pixel(x, y, c)
	return bg


static func _upscale_nearest(img64: Image, factor: int) -> Image:
	var out := img64.duplicate() as Image
	out.resize(SIZE * factor, SIZE * factor, Image.INTERPOLATE_NEAREST)
	return out


static func _save_pair(slug: String, legacy_base: String, img64_norm: Image, img64_dist: Image) -> void:
	var n256 := _upscale_nearest(img64_norm, EXPORT_SCALE)
	var d256 := _upscale_nearest(img64_dist, EXPORT_SCALE)
	n256.save_png(ProjectSettings.globalize_path("%s/%s_normal.png" % [PORTRAITS_LOTE3_DIR, slug]))
	d256.save_png(ProjectSettings.globalize_path("%s/%s_distorted.png" % [PORTRAITS_LOTE3_DIR, slug]))
	if not legacy_base.is_empty():
		n256.save_png(ProjectSettings.globalize_path("%s/fnaf_%s.png" % [PORTRAITS_LEGACY_DIR, legacy_base]))
		d256.save_png(ProjectSettings.globalize_path("%s/fnaf_distorted_%s.png" % [PORTRAITS_LEGACY_DIR, legacy_base]))


static func _cast_specs() -> Array[Dictionary]:
	return [
		{
			"slug": "cap_reyes", "legacy": "cap_reyes", "label": "Cap. Reyes",
			"age": 56, "body": "broad_command", "skin": "#B07C56", "dist_mode": "warm",
			"bg_top": Color("#162238"), "bg_bot": Color("#0B111C"), "accent": Color("#F5CB5C"),
			"cloth_hi": Color("#304163"), "cloth_mid": Color("#212D45"), "cloth_sh": Color("#131A29"),
			"outfit_detail": "bfp_command", "mood": "stern",
			"brow_color": Color("#4A4C54"), "iris_color": Color("#2E1D15"),
			"mustache": true, "mustache_color": Color("#B6BCC4"),
			"hair_style": "commander_sides", "hair_color": Color("#474B54"), "hat": "cap_bfp",
			"dist_eye": "amber_void", "y_shift": 1
		},
		{
			"slug": "bombeiro_ato", "legacy": "bombeiro_ato", "label": "Bombeiro Ato",
			"age": 29, "body": "broad_command", "skin": "#B57D58", "dist_mode": "ash",
			"bg_top": Color("#241F18"), "bg_bot": Color("#120E0B"), "accent": Color("#FF9F1C"),
			"cloth_hi": Color("#343C4A"), "cloth_mid": Color("#232934"), "cloth_sh": Color("#151921"),
			"outfit_detail": "bfp_stripes", "mood": "stern",
			"brow_color": Color("#241914"), "iris_color": Color("#2C1B12"),
			"hair_style": "short", "hair_color": Color("#1C1C22"), "hat": "helmet_yellow",
			"dist_eye": "amber_void", "y_shift": 1
		},
		{
			"slug": "bombeiro_santos", "legacy": "bombeiro_santos", "label": "Bombeiro Santos",
			"age": 25, "body": "young_adult", "skin": "#BA835E", "dist_mode": "cold",
			"bg_top": Color("#162230"), "bg_bot": Color("#0B121A"), "accent": Color("#4ECDC4"),
			"cloth_hi": Color("#323B4D"), "cloth_mid": Color("#222836"), "cloth_sh": Color("#141821"),
			"outfit_detail": "bfp_stripes", "mood": "calm", "tired_eyes": true,
			"brow_color": Color("#1E1818"), "iris_color": Color("#33221A"),
			"hair_style": "curly_dark", "hair_color": Color("#1A1C24"), "hat": "none",
			"dist_eye": "pale_wide", "y_shift": 0
		},
		{
			"slug": "enfermeira_maria", "legacy": "enfermeira_maria", "label": "Enf. Maria",
			"age": 31, "body": "slender_feminine", "skin": "#C48E68", "dist_mode": "cold",
			"bg_top": Color("#14252E"), "bg_bot": Color("#0A1318"), "accent": Color("#90E0EF"),
			"cloth_hi": Color("#9E4250"), "cloth_mid": Color("#7A2F3B"), "cloth_sh": Color("#4D1B23"),
			"outfit_detail": "maria_stethoscope", "mood": "warm",
			"brow_color": Color("#38231A"), "iris_color": Color("#3B2418"),
			"hair_style": "maria_bun", "hair_color": Color("#3D251D"), "hat": "none",
			"dist_eye": "hollow_black", "y_shift": 0
		},
		{
			"slug": "aling_nena", "legacy": "aling_nena", "label": "Aling Nena",
			"age": 49, "body": "slender_feminine", "skin": "#AE744E", "dist_mode": "warm",
			"bg_top": Color("#241926"), "bg_bot": Color("#120C14"), "accent": Color("#FF7085"),
			"cloth_hi": Color("#8A3D58"), "cloth_mid": Color("#6B2B42"), "cloth_sh": Color("#451929"),
			"outfit_detail": "nena_apron", "mood": "warm",
			"brow_color": Color("#241816"), "iris_color": Color("#2E1B12"),
			"hair_style": "nena_bob", "hair_color": Color("#1F1C22"), "hat": "none",
			"dist_eye": "pale_wide", "y_shift": 0
		},
		{
			"slug": "kuya_ben", "legacy": "kuya_ben", "label": "Kuya Ben",
			"age": 36, "body": "broad_command", "skin": "#A66E49", "dist_mode": "warm",
			"bg_top": Color("#182430"), "bg_bot": Color("#0B1118"), "accent": Color("#FFCA3A"),
			"cloth_hi": Color("#3B598C"), "cloth_mid": Color("#2A4169"), "cloth_sh": Color("#1A2942"),
			"outfit_detail": "ben_towel", "mood": "stern",
			"brow_color": Color("#1E1410"), "iris_color": Color("#2E1A12"),
			"mustache": true, "mustache_color": Color("#291E1A"),
			"hair_style": "short", "hair_color": Color("#1C1A20"), "hat": "trucker_cap",
			"dist_eye": "red_pin", "y_shift": 1
		},
		{
			"slug": "mang_tomas", "legacy": "feirante", "label": "Mang Tomas",
			"age": 45, "body": "broad_command", "skin": "#AA704A", "dist_mode": "warm",
			"bg_top": Color("#202418"), "bg_bot": Color("#0F120C"), "accent": Color("#8AC926"),
			"cloth_hi": Color("#4E6B40"), "cloth_mid": Color("#3A522E"), "cloth_sh": Color("#25361D"),
			"outfit_detail": "tomas_apron", "mood": "calm",
			"brow_color": Color("#241A15"), "iris_color": Color("#2C1C14"),
			"hair_style": "short", "hair_color": Color("#2A282D"), "hat": "salakot",
			"dist_eye": "red_pin", "y_shift": 2
		},
		{
			"slug": "mang_carding", "legacy": "mang_carding", "label": "Mang Carding",
			"age": 54, "body": "lean_weathered", "skin": "#99603D", "dist_mode": "warm",
			"bg_top": Color("#122429"), "bg_bot": Color("#081114"), "accent": Color("#4ECDC4"),
			"cloth_hi": Color("#366C7D"), "cloth_mid": Color("#254F5C"), "cloth_sh": Color("#17333D"),
			"outfit_detail": "carding_net", "mood": "calm", "tired_eyes": true,
			"brow_color": Color("#4A484C"), "iris_color": Color("#2B1A12"),
			"mustache": true, "mustache_color": Color("#9DA3AD"),
			"hair_style": "commander_sides", "hair_color": Color("#5C626E"), "hat": "bandana_teal",
			"dist_eye": "amber_void", "y_shift": 0
		},
		{
			"slug": "toby", "legacy": "toby", "label": "Toby",
			"age": 9, "body": "child", "skin": "#CA956E", "dist_mode": "cold",
			"bg_top": Color("#182924"), "bg_bot": Color("#0C1412"), "accent": Color("#4ECDC4"),
			"cloth_hi": Color("#FFE059"), "cloth_mid": Color("#E5B226"), "cloth_sh": Color("#A37614"),
			"outfit_detail": "toby_straps", "mood": "kid",
			"brow_color": Color("#261B16"), "iris_color": Color("#3B2618"),
			"hair_style": "kid_bangs", "hair_color": Color("#1D1B22"), "hat": "kid_cap",
			"dist_eye": "pale_wide", "y_shift": 1
		},
		{
			"slug": "senhora_luningning", "legacy": "luningning", "label": "Sra. Luningning",
			"age": 68, "body": "slender_feminine", "skin": "#BF8E72", "dist_mode": "cold",
			"bg_top": Color("#21162B"), "bg_bot": Color("#100A14"), "accent": Color("#C77DFF"),
			"cloth_hi": Color("#C4A5D9"), "cloth_mid": Color("#9A7AB0"), "cloth_sh": Color("#634C75"),
			"outfit_detail": "luningning_shawl", "mood": "elder_sad", "tired_eyes": true,
			"brow_color": Color("#7A7F8A"), "iris_color": Color("#302226"),
			"hair_style": "silver_bun", "hair_color": Color("#CED4DF"), "hat": "none",
			"dist_eye": "hollow_black", "y_shift": 2
		},
		{
			"slug": "lola_rosa", "legacy": "lola_rosa", "label": "Lola Rosa",
			"age": 71, "body": "slender_feminine", "skin": "#BA835B", "dist_mode": "ash",
			"bg_top": Color("#1C241E"), "bg_bot": Color("#0D120E"), "accent": Color("#C77DFF"),
			"cloth_hi": Color("#567D52"), "cloth_mid": Color("#3E5E3B"), "cloth_sh": Color("#273D25"),
			"outfit_detail": "lola_baro", "mood": "warm",
			"brow_color": Color("#63666E"), "iris_color": Color("#2E1D15"),
			"hair_style": "lola_braid", "hair_color": Color("#CED4DF"), "hat": "floral_headscarf",
			"dist_eye": "amber_void", "y_shift": 0
		},
	]


static func build_all_portraits() -> Array[Dictionary]:
	_ensure_dirs()
	var previews: Array[Dictionary] = []

	for sp in _cast_specs():
		var im_n := _build_human_portrait(sp, false)
		var im_d := _build_human_portrait(sp, true)
		_save_pair(sp["slug"], sp["legacy"], im_n, im_d)
		previews.append({"label": sp["label"], "normal": im_n, "distorted": im_d})

	var v_n := _build_vulto_portrait(false)
	var v_d := _build_vulto_portrait(true)
	_save_pair("vulto_bosque", "vulto_bosque", v_n, v_d)
	previews.append({"label": "Vulto Calcinado", "normal": v_n, "distorted": v_d})

	var g_n := _build_guardian_portrait(false)
	var g_d := _build_guardian_portrait(true)
	_save_pair("criatura_lagoa", "criatura_lagoa", g_n, g_d)
	previews.append({"label": "Guardiã Lagoa", "normal": g_n, "distorted": g_d})

	var s_n := _build_santelmo_portrait(false)
	var s_d := _build_santelmo_portrait(true)
	_save_pair("santelmo", "santelmo", s_n, s_d)
	previews.append({"label": "Santelmo", "normal": s_n, "distorted": s_d})

	var r_n := _build_vhs_radio_portrait(false)
	var r_d := _build_vhs_radio_portrait(true)
	_save_pair("vhs_radio", "vhs_radio", r_n, r_d)
	previews.append({"label": "Rádio / VHS", "normal": r_n, "distorted": r_d})

	return previews
