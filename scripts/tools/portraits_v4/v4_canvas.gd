extends RefCounted
class_name V4Canvas

## Motor de pintura pixel-art ANIME nativo 96x96 (1px = 1 pixel real, sem anti-aliasing).
## Contornos limpos sem "doubles", proporção facial anime com queixo em V, olhos grandes
## expressivos com brilho/olheiras, nariz mínimo de 1-2px e mechas em curva Bézier.

const SIZE := 96

const BAYER4 := [
	[ 0,  8,  2, 10],
	[12,  4, 14,  6],
	[ 3, 11,  1,  9],
	[15,  7, 13,  5],
]


static func new_canvas() -> Image:
	var img := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	return img


static func px(img: Image, x: int, y: int, c: Color) -> void:
	if x >= 0 and y >= 0 and x < SIZE and y < SIZE:
		img.set_pixel(x, y, c)


static func span(img: Image, x0: int, x1: int, y: int, c: Color) -> void:
	if y < 0 or y >= SIZE:
		return
	var a := mini(x0, x1)
	var b := maxi(x0, x1)
	for x in range(maxi(0, a), mini(SIZE - 1, b) + 1):
		img.set_pixel(x, y, c)


static func rect(img: Image, x0: int, y0: int, x1: int, y1: int, c: Color) -> void:
	for y in range(maxi(0, mini(y0, y1)), mini(SIZE - 1, maxi(y0, y1)) + 1):
		span(img, x0, x1, y, c)


static func disc(img: Image, cx: float, cy: float, rx: float, ry: float, c: Color) -> void:
	if rx <= 0.0 or ry <= 0.0:
		return
	var ix0 := maxi(0, int(floor(cx - rx)))
	var ix1 := mini(SIZE - 1, int(ceil(cx + rx)))
	var iy0 := maxi(0, int(floor(cy - ry)))
	var iy1 := mini(SIZE - 1, int(ceil(cy + ry)))
	for y in range(iy0, iy1 + 1):
		var dy := (float(y) - cy) / ry
		var dy2 := dy * dy
		if dy2 > 1.0:
			continue
		for x in range(ix0, ix1 + 1):
			var dx := (float(x) - cx) / rx
			if dx * dx + dy2 <= 1.0:
				img.set_pixel(x, y, c)


static func line_px(img: Image, x0: int, y0: int, x1: int, y1: int, c: Color) -> void:
	## Bresenham 1px limpo (sem L-doubles desnecessários em diagonais!)
	var dx: int = absi(x1 - x0)
	var dy: int = absi(y1 - y0)
	var sx := 1 if x0 < x1 else -1
	var sy := 1 if y0 < y1 else -1
	var err := dx - dy
	var x := x0
	var y := y0
	while true:
		px(img, x, y, c)
		if x == x1 and y == y1:
			break
		var e2 := 2 * err
		if e2 > -dy:
			err -= dy
			x += sx
		if e2 < dx:
			err += dx
			y += sy


static func quad_bezier_line(img: Image, p0: Vector2, p1: Vector2, p2: Vector2, c: Color, thick: int = 1) -> void:
	var steps := maxi(8, int(p0.distance_to(p1) + p1.distance_to(p2) + 4.0))
	var prev := Vector2i(int(round(p0.x)), int(round(p0.y)))
	for i in range(1, steps + 1):
		var t := float(i) / float(steps)
		var omt := 1.0 - t
		var pt := omt * omt * p0 + 2.0 * omt * t * p1 + t * t * p2
		var cur := Vector2i(int(round(pt.x)), int(round(pt.y)))
		line_px(img, prev.x, prev.y, cur.x, cur.y, c)
		if thick >= 2:
			px(img, cur.x, cur.y + 1, c)
		prev = cur


static func backdrop_solid(col: Color) -> Image:
	var img := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	img.fill(col)
	return img


static func backdrop_horror_dither(top_col: Color, bot_col: Color, mode: String = "crimson_dither") -> Image:
	var img := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	for y in range(SIZE):
		var ny := float(y) / float(SIZE - 1)
		for x in range(SIZE):
			var b: float = float(BAYER4[y % 4][x % 4]) / 16.0
			if mode == "duotone_red":
				var d_vign := clampf(absf(float(x) - 47.5) / 56.0, 0.0, 1.0)
				var col := top_col if (ny * 0.52 + d_vign * 0.30) < b + 0.22 else bot_col
				img.set_pixel(x, y, col)
			elif mode == "scan_crt":
				var g: float = ny * 0.85
				var col := top_col if g + (0.14 if y % 3 == 0 else -0.05) < b else bot_col
				if y % 3 == 0:
					col = col.darkened(0.24)
				img.set_pixel(x, y, col)
			else:
				var d_edge := clampf(absf(float(x) - 47.5) / 47.5, 0.0, 1.0)
				var bias := clampf(ny * 0.62 + d_edge * 0.42, 0.0, 1.0)
				img.set_pixel(x, y, bot_col if bias > b + 0.06 else top_col)
	return img


static func composite(bg: Image, fg: Image, x_off: int = 0, y_off: int = 0) -> Image:
	var out := bg.duplicate() as Image
	for y in range(SIZE):
		for x in range(SIZE):
			var sx := x - x_off
			var sy := y - y_off
			if sx >= 0 and sy >= 0 and sx < SIZE and sy < SIZE:
				var c := fg.get_pixel(sx, sy)
				if c.a > 0.01:
					out.set_pixel(x, y, c)
	return out


static func skin_tones(base_hex: String, mode: String = "normal") -> Dictionary:
	var base := Color(base_hex)
	if mode == "unfiltered":
		var g := base.r * 0.299 + base.g * 0.587 + base.b * 0.114
		var b_mono := Color(g * 0.94, g * 0.95, g * 0.97)
		var b_mid := b_mono.darkened(0.18)
		return {
			"hi": b_mono.lightened(0.16),
			"base": b_mono,
			"soft": b_mono.lerp(b_mid, 0.45),
			"mid": b_mid,
			"sh": b_mono.darkened(0.40),
			"ink": Color("#1E1E22"),
			"lip": b_mono.darkened(0.32),
		}
	if mode == "pale":
		var p_base := Color("#ECE4DF")
		var p_mid := Color("#C2B5B6")
		return {
			"hi": Color("#FBF8F5"),
			"base": p_base,
			"soft": p_base.lerp(p_mid, 0.45),
			"mid": p_mid,
			"sh": Color("#8A767E"),
			"ink": Color("#190E14"),
			"lip": Color("#753A44"),
		}
	if mode == "corpse":
		var c_base := base.lerp(Color("#ADA19E"), 0.65)
		var c_mid := base.lerp(Color("#7C6D70"), 0.72)
		return {
			"hi": base.lerp(Color("#D4CAC6"), 0.55),
			"base": c_base,
			"soft": c_base.lerp(c_mid, 0.45),
			"mid": c_mid,
			"sh": Color("#463940"),
			"ink": Color("#140B10"),
			"lip": Color("#632E38"),
		}
	if mode == "ash":
		var a_base := base.lerp(Color("#6E6062"), 0.62)
		var a_mid := Color("#463A3E")
		return {
			"hi": base.lerp(Color("#9A8E8C"), 0.52),
			"base": a_base,
			"soft": a_base.lerp(a_mid, 0.45),
			"mid": a_mid,
			"sh": Color("#261B20"),
			"ink": Color("#0D0609"),
			"lip": Color("#451822"),
		}
	if mode == "blood_lit":
		var bl_base := base.lerp(Color("#C96B61"), 0.30)
		var bl_mid := Color("#8A2D32")
		return {
			"hi": base.lerp(Color("#F2A89C"), 0.34),
			"base": bl_base,
			"soft": bl_base.lerp(bl_mid, 0.45),
			"mid": bl_mid,
			"sh": Color("#4F111A"),
			"ink": Color("#17060B"),
			"lip": Color("#7A1A26"),
		}
	var n_mid := Color(clampf(base.r * 0.84, 0.0, 1.0), clampf(base.g * 0.75, 0.0, 1.0), clampf(base.b * 0.71, 0.0, 1.0))
	return {
		"hi": base.lightened(0.18),
		"base": base,
		"soft": base.lerp(n_mid, 0.44),
		"mid": n_mid,
		"sh": Color(clampf(base.r * 0.62, 0.0, 1.0), clampf(base.g * 0.49, 0.0, 1.0), clampf(base.b * 0.49, 0.0, 1.0)),
		"ink": Color("#261417"),
		"lip": Color(clampf(base.r * 0.68, 0.0, 1.0), clampf(base.g * 0.44, 0.0, 1.0), clampf(base.b * 0.43, 0.0, 1.0)),
	}


static func draw_hair_strand(
	fg: Image, p0: Vector2, p1: Vector2, p2: Vector2,
	w0: float, w1: float, base_col: Color, sh_col: Color, hi_col: Color, ink_col: Color,
	draw_hi: bool = false, outline_root: bool = false
) -> void:
	## Desenha uma mecha curva em Bézier quadrática com afilamento anime fino (w0 -> w1) e contorno nítido 1px!
	var steps := maxi(16, int((p0.distance_to(p1) + p1.distance_to(p2)) * 1.4))
	var pts: Array[Vector2] = []
	var left_pts: Array[Vector2i] = []
	var right_pts: Array[Vector2i] = []
	for i in range(steps + 1):
		var t := float(i) / float(steps)
		var omt := 1.0 - t
		var pt := omt * omt * p0 + 2.0 * omt * t * p1 + t * t * p2
		var tang := 2.0 * omt * (p1 - p0) + 2.0 * t * (p2 - p1)
		if tang.length_squared() < 0.001:
			tang = Vector2(0, 1)
		tang = tang.normalized()
		var nrm := Vector2(-tang.y, tang.x)
		var hw := lerpf(w0, w1, pow(t, 0.85))
		pts.append(pt)
		left_pts.append(Vector2i(int(round(pt.x - nrm.x * hw)), int(round(pt.y - nrm.y * hw))))
		right_pts.append(Vector2i(int(round(pt.x + nrm.x * hw)), int(round(pt.y + nrm.y * hw))))

	# Preenchimento sólido da mecha + sombra na borda direita e ponta
	for i in range(steps + 1):
		var t := float(i) / float(steps)
		var hw := maxf(0.4, lerpf(w0, w1, pow(t, 0.85)) - 0.35)
		var fill_c := sh_col if t > 0.72 else base_col
		disc(fg, pts[i].x, pts[i].y, hw, hw, fill_c)
		if draw_hi and t > 0.12 and t < 0.48 and hw > 1.2:
			px(fg, int(round(pts[i].x - hw * 0.28)), int(round(pts[i].y)), hi_col)

	# Contorno limpo 1px ao longo das bordas esquerda/direita da mecha (preservando raiz contínua para franjas)
	var i_start := 1 if outline_root else maxi(2, int(steps * 0.20))
	for i in range(i_start, steps):
		line_px(fg, left_pts[i - 1].x, left_pts[i - 1].y, left_pts[i].x, left_pts[i].y, ink_col)
		line_px(fg, right_pts[i - 1].x, right_pts[i - 1].y, right_pts[i].x, right_pts[i].y, ink_col)
	var tip := Vector2i(int(round(p2.x)), int(round(p2.y)))
	px(fg, tip.x, tip.y, ink_col)


static func draw_anime_crown(
	fg: Image, cx: float, cy: float, rx: float, ry: float,
	base_col: Color, sh_col: Color, hi_col: Color, ink_col: Color
) -> void:
	## Desenha volume orgânico da copa do cabelo anime com brilho angular (halo de anime!) e borda limpa 1px.
	var iy0 := maxi(1, int(floor(cy - ry)))
	var iy1 := mini(SIZE - 2, int(ceil(cy + ry * 0.55)))
	var xl_m: Dictionary = {}
	var xr_m: Dictionary = {}
	for y in range(iy0, iy1 + 1):
		var dy := (float(y) - cy) / ry
		if dy * dy > 1.0:
			continue
		var hw := rx * sqrt(maxf(0.0, 1.0 - dy * dy))
		var xl := int(round(cx - hw))
		var xr := int(round(cx + hw))
		xl_m[y] = xl
		xr_m[y] = xr
		for x in range(xl, xr + 1):
			var col := base_col
			var nx := (float(x) - cx) / rx
			if nx > 0.36:
				col = sh_col
			elif dy > -0.62 and dy < -0.24 and nx > -0.78 and nx < 0.52:
				# Reflexo clássico anime dividido em segmentos sobre a curvatura da coroa!
				if (x + y) % 9 < 6:
					col = hi_col
			px(fg, x, y, col)
	for y in range(iy0, iy1):
		if not xl_m.has(y):
			continue
		var xl: int = xl_m[y]
		var xr: int = xr_m[y]
		px(fg, xl, y, ink_col)
		px(fg, xr, y, ink_col)
		if xl_m.has(y + 1):
			var nl: int = xl_m[y + 1]
			var nr: int = xr_m[y + 1]
			if absi(nl - xl) > 1:
				span(fg, mini(nl, xl), maxi(nl, xl), y, ink_col)
			if absi(nr - xr) > 1:
				span(fg, mini(nr, xr), maxi(nr, xr), y, ink_col)
	if xl_m.has(iy0):
		span(fg, xl_m[iy0], xr_m[iy0], iy0, ink_col)


static func sculpt_anime_face(
	fg: Image, sk: Dictionary, archetype: String = "teen", shift_x: int = 0, shift_y: int = 0, tilt: int = 0
) -> Dictionary:
	## Constrói rostos ANIME variados por perfil (huwag, child, fem, teen, male_adult, male_wide, elder_fem)
	## com sombreamento volumétrico de pele (maçãs do rosto, interior das orelhas, pescoço e clavículas).
	var is_fem := (archetype == "fem")
	var is_elder_fem := (archetype == "elder_fem")
	var is_child := (archetype == "child")
	var is_huwag := (archetype == "huwag")
	var is_wide := (archetype == "male_wide")
	var is_adult := (archetype == "male_adult" or archetype == "elder" or is_wide)

	var cx := 47.5 + float(shift_x)
	var top_y := (29 if is_child else (27 if is_elder_fem else 26)) + shift_y
	var chin_y := (67 if is_child else (70 if (is_fem or is_huwag or is_elder_fem) else 72)) + shift_y

	var temple_w := 20.0 if (is_fem or is_elder_fem) else (22.0 if is_child else (23.6 if is_wide else (22.6 if is_adult else 21.0)))
	var cheek_w := 21.2 if is_fem else (21.6 if is_elder_fem else (24.4 if is_child else (25.0 if is_wide else (23.8 if is_adult else 21.8))))
	var chin_tip_w := 2.4 if is_fem else (4.2 if is_elder_fem else (5.2 if is_child else (4.4 if is_huwag else (7.2 if is_wide else (5.4 if is_adult else 3.4)))))

	# 1. Pescoço esculpido com sombra triangular sob o queixo, musculatura e clavículas nítidas
	var neck_hw := 6.6 if (is_fem or is_elder_fem) else (6.5 if is_child else (10.2 if is_wide else (9.6 if is_adult else 8.0)))
	var neck_cx := cx - float(tilt) * 0.5
	var ny0 := chin_y - 5
	var ny1 := 95
	var nxl_m: Dictionary = {}
	var nxr_m: Dictionary = {}
	for y in range(ny0, ny1 + 1):
		var spread := clampf(float(y - (chin_y + 7)) * 0.48, 0.0, 5.5)
		var nhw := neck_hw + spread
		var nxl := int(round(neck_cx - nhw))
		var nxr := int(round(neck_cx + nhw))
		nxl_m[y] = nxl
		nxr_m[y] = nxr
		for x in range(nxl, nxr + 1):
			var dx := float(x) - neck_cx
			var adx := absf(dx)
			var sh_lim := float(chin_y + 8) - adx * 0.44 + (dx * 0.24)
			var col: Color = sk["base"]
			if float(y) <= sh_lim:
				col = sk["sh"] if float(y) <= sh_lim - 2.2 else sk["mid"]
			elif dx > neck_hw * 0.42:
				col = sk["mid"]
			# Tendões cervicais sutis descendo em direção à fúrcula
			if y >= chin_y + 7 and y <= chin_y + 12 and adx > neck_hw * 0.35 and adx < neck_hw * 0.60:
				col = sk["mid"]
			# Fosseta supraesternal + clavículas esculpidas com luz acima e sombra abaixo
			var clav_y := mini(SIZE - 2, chin_y + 12)
			if y == clav_y and adx <= 2.2:
				col = sk["sh"] if adx <= 1.2 else sk["mid"]
			elif adx > 2.2 and adx < nhw - 1.5:
				var wing_y := int(round(float(clav_y) - (adx - 2.2) * 0.22))
				if y == wing_y:
					col = sk["mid"] if dx > 0.0 else sk["sh"]
				elif y == wing_y - 1:
					col = sk["hi"]
			px(fg, x, y, col)
	for y in range(ny0 + 4, ny1):
		px(fg, nxl_m[y], y, sk["ink"])
		px(fg, nxr_m[y], y, sk["ink"])

	# 2. Orelhas anime com dobra da hélice e concha sombreada internamente
	var eye_y := (47 if is_child else (43 if is_huwag else 45)) + shift_y
	var ear_lx := int(round(cx - cheek_w + 0.5))
	var ear_rx := int(round(cx + cheek_w - 0.5))
	for dy in range(11):
		var ew := 3 if (dy >= 2 and dy <= 7) else (2 if dy >= 1 and dy <= 9 else 1)
		var lx_out := ear_lx - ew
		var rx_out := ear_rx + ew
		span(fg, lx_out + 1, ear_lx + 1, eye_y + dy, sk["base"] if dy < 7 else sk["mid"])
		span(fg, ear_rx - 1, rx_out - 1, eye_y + dy, sk["mid"] if dy < 7 else sk["sh"])
		if dy in [2, 3] and ew >= 3:
			px(fg, lx_out + 1, eye_y + dy, sk["hi"])
		px(fg, lx_out, eye_y + dy, sk["ink"])
		px(fg, rx_out, eye_y + dy, sk["ink"])
		if dy >= 3 and dy <= 7:
			px(fg, lx_out + 2, eye_y + dy, sk["sh"] if dy in [4, 5] else sk["mid"])
			px(fg, rx_out - 2, eye_y + dy, sk["sh"] if dy in [4, 5] else sk["mid"])
			if dy == 5:
				px(fg, lx_out + 3, eye_y + dy, sk["mid"])
				px(fg, rx_out - 3, eye_y + dy, sk["sh"])
	px(fg, ear_lx - 1, eye_y + 11, sk["ink"])
	px(fg, ear_rx + 1, eye_y + 11, sk["ink"])

	# 3. Crânio e maxilar anime diferenciados por perfil com sombreamento de maçãs do rosto
	var xl_map: Dictionary = {}
	var xr_map: Dictionary = {}
	var face_h := float(chin_y - top_y)
	for y in range(top_y, chin_y + 1):
		var t := float(y - top_y) / face_h
		var slant := float(tilt) * (t - 0.5) * 1.4
		var hinge := 0.54 if is_child else (0.65 if is_wide else (0.63 if is_elder_fem else 0.60))
		var hw: float
		if t < 0.36:
			var k := t / 0.36
			hw = lerpf(temple_w * 0.84, temple_w, sin(k * PI * 0.5))
		elif t < hinge:
			var k2 := (t - 0.36) / maxf(0.05, hinge - 0.36)
			hw = lerpf(temple_w, cheek_w, sin(k2 * PI * 0.5))
		else:
			var k3 := (t - hinge) / (1.0 - hinge)
			var curve: float
			if is_child or is_wide:
				curve = k3 * 0.62 + (k3 * k3) * 0.38
			elif is_huwag:
				curve = k3 * 0.72 + (k3 * k3) * 0.28
			elif is_adult or is_elder_fem:
				curve = k3 * 0.78 + (k3 * k3) * 0.22
			else:
				curve = pow(k3, 0.86)
			hw = lerpf(cheek_w, chin_tip_w, curve)
		# Arredondamento suave da ponta do queixo (preservando queixos mais firmes em adultos/homens)
		if y == chin_y:
			hw = maxf(1.4, hw * (0.86 if (is_wide or is_adult) else 0.64))
		elif y == chin_y - 1:
			hw = maxf(2.0, hw * (0.94 if (is_wide or is_adult) else 0.85))

		var xl := int(round(cx + slant - hw * 1.01))
		var xr := int(round(cx + slant + hw * 0.98))
		xl_map[y] = xl
		xr_map[y] = xr
		var soft_m: Color = sk.get("soft", sk["mid"])
		for x in range(xl + 1, xr):
			var col: Color = sk["base"]
			var nx := (float(x) - (cx + slant)) / maxf(1.0, hw)
			# Sombra volumétrica contínua conectada à borda lateral (luz topo-esquerda -> transição soft -> mid à direita)
			if nx > 0.74 and t > 0.24:
				col = sk["mid"]
			elif nx > 0.56 and t > 0.52 and t < 0.88:
				col = soft_m
			elif nx < -0.76 and t > 0.62 and t < 0.90:
				col = soft_m
			elif nx < -0.35 and nx > -0.66 and t > 0.50 and t < 0.61:
				col = sk["hi"]
			# Sombra sutil nas maçãs / têmpora em rostos idosos ligada à borda externa (sem manchas isoladas!)
			if is_elder_fem and t > 0.54 and t < 0.74:
				if nx > 0.58:
					col = sk["mid"]
				elif nx < -0.68:
					col = soft_m
			px(fg, x, y, col)

	# 4. Contorno pixel-art de 1px SEM doubles ao longo de toda a mandíbula e queixo
	for y in range(top_y + 2, chin_y):
		var xl: int = xl_map[y]
		var xr: int = xr_map[y]
		px(fg, xl, y, sk["ink"])
		px(fg, xr, y, sk["ink"])
		if xl_map.has(y + 1):
			var nl: int = xl_map[y + 1]
			var nr: int = xr_map[y + 1]
			if nl - xl > 1:
				span(fg, xl + 1, nl - 1, y, sk["ink"])
			if xr - nr > 1:
				span(fg, nr + 1, xr - 1, y, sk["ink"])
	span(fg, xl_map[chin_y], xr_map[chin_y], chin_y, sk["ink"])
	if xl_map.has(chin_y - 1):
		span(fg, int(round(cx)) - 2, int(round(cx)) + 2, chin_y - 2, sk["mid"])

	return {
		"cx": int(round(cx)),
		"top_y": top_y,
		"chin_y": chin_y,
		"eye_y": eye_y,
		"el_x": int(round(cx)) - 17,
		"er_x": int(round(cx)) + 5,
		"eye_w": 12,
		"nose_y": eye_y + (12 if is_huwag else (10 if is_child else 11)),
		"mouth_y": chin_y - (6 if is_child else 7),
		"archetype": archetype,
		"xl_map": xl_map,
		"xr_map": xr_map,
	}


static func draw_anime_eyes(
	fg: Image, lm: Dictionary, sk: Dictionary, iris: Color,
	mood: String = "neutral", archetype: String = "teen", brow_col: Color = Color("#1B1418")
) -> void:
	## Olhos ANIME expressivos adaptados por idade/personalidade (olheiras, brilho, pés de galinha e sobrancelhas).
	var ey: int = lm["eye_y"]
	var elx: int = lm["el_x"]
	var erx: int = lm["er_x"]
	var ew: int = lm["eye_w"]
	var is_big := (archetype == "fem" or archetype == "child")
	var is_elder_fem := (archetype == "elder_fem")
	var is_elder := (archetype == "elder" or is_elder_fem)
	var is_huwag := (archetype == "huwag")
	var is_stern := (archetype in ["male_adult", "male_wide", "elder", "elder_fem", "huwag"])
	var eye_h := 8 if is_big else (6 if is_stern else 7)
	if mood in ["scared", "surprised"]:
		eye_h += 1
	elif mood == "stern" and is_stern:
		eye_h = maxi(5, eye_h - 1)

	var lash := Color("#150C11")
	var white := Color("#FAF6F2") if not is_elder_fem else Color("#EFE9E4")
	var sclera_sh := Color("#D8D0D5")
	var iris_dark := iris.darkened(0.36)
	var iris_rim := iris.darkened(0.55)
	var pupil := Color("#0D060A")

	# 1. Sobrancelhas finas curvas / retas / franzidas por expressão
	var b_y := ey - (5 if mood == "surprised" else (2 if mood in ["stern", "gruff", "tired"] else 3))
	if mood in ["worried", "scared", "sad"]:
		quad_bezier_line(fg, Vector2(elx - 1, b_y + 1), Vector2(elx + 5, b_y), Vector2(elx + ew, b_y - 2), brow_col, 1)
		quad_bezier_line(fg, Vector2(erx, b_y - 2), Vector2(erx + 6, b_y), Vector2(erx + ew + 1, b_y + 1), brow_col, 1)
	elif mood in ["angry", "stern"]:
		quad_bezier_line(fg, Vector2(elx - 1, b_y - 2), Vector2(elx + 5, b_y), Vector2(elx + ew, b_y + 2), brow_col, 2)
		quad_bezier_line(fg, Vector2(erx, b_y + 2), Vector2(erx + 6, b_y), Vector2(erx + ew + 1, b_y - 2), brow_col, 2)
		# Vinco vertical tenso entre as sobrancelhas (autoridade / tensão)
		var mid_x: int = lm["cx"]
		px(fg, mid_x - 1, b_y + 1, sk["sh"])
		px(fg, mid_x + 1, b_y + 1, sk["mid"])
		px(fg, mid_x, b_y, sk["sh"])
	elif mood in ["gruff", "serious"] or (is_huwag and mood == "neutral"):
		# Sobrancelhas firmes e niveladas de foco / seriedade (sem arco alegre!)
		quad_bezier_line(fg, Vector2(elx - 1, b_y), Vector2(elx + 5, b_y), Vector2(elx + ew, b_y + 1), brow_col, 2 if mood == "gruff" else 1)
		quad_bezier_line(fg, Vector2(erx, b_y + 1), Vector2(erx + 6, b_y), Vector2(erx + ew + 1, b_y), brow_col, 2 if mood == "gruff" else 1)
	else:
		quad_bezier_line(fg, Vector2(elx - 1, b_y + 1), Vector2(elx + 5, b_y - 1), Vector2(elx + ew, b_y), brow_col, 1)
		quad_bezier_line(fg, Vector2(erx, b_y), Vector2(erx + 6, b_y - 1), Vector2(erx + ew + 1, b_y + 1), brow_col, 1)

	# 2. Para cada olho (esquerdo e direito)
	for side in [0, 1]:
		var bx: int = elx if side == 0 else erx
		var look_dx := 1 if side == 0 else -1
		var top_drop := 1 if mood in ["tired", "unfiltered", "sad", "gruff"] else 0

		# Esclera branca limpa + leve sombra sob pálpebra superior
		for dy in range(1, eye_h):
			var row_y := ey + dy + top_drop
			var inset := 2 if dy == 1 else (1 if dy == eye_h - 1 else 0)
			if inset < ew - 2:
				var c_scl := sclera_sh if dy == 1 else white
				span(fg, bx + inset, bx + ew - 1 - inset, row_y, c_scl)

		# Íris anime (menor e mais sóbria em idosos / adultos sérios!)
		var icx := float(bx) + float(ew) * 0.5 + float(look_dx) * 0.4
		var icy := float(ey + top_drop) + float(eye_h) * 0.54
		if mood == "scared":
			disc(fg, icx, icy, 2.2, 2.4, iris_rim)
			disc(fg, icx, icy, 1.4, 1.6, pupil)
			px(fg, int(round(icx - 1)), int(round(icy - 1)), white)
		else:
			var irx := 3.4 if is_big else (2.7 if is_elder_fem else 3.1)
			var iry := 3.8 if is_big else (2.8 if (is_elder_fem or is_stern) else 3.4)
			var iy0 := ey + 1 + top_drop
			var iy1 := ey + eye_h - 1 + top_drop
			for y in range(iy0, iy1 + 1):
				for x in range(bx + 1, bx + ew - 1):
					var d := pow((float(x) - icx) / irx, 2.0) + pow((float(y) - icy) / iry, 2.0)
					if d <= 1.0:
						var ic := iris
						if d > 0.78:
							ic = iris_rim
						elif float(y) < icy - 0.3:
							ic = iris_dark
						elif absf(float(x) - icx) < 1.15 and absf(float(y) - icy) < 1.35:
							ic = pupil
						px(fg, x, y, ic)
			# Brilho especular (discreto 1px para idosas, luminoso duplo para jovens!)
			var spx := int(round(icx - 1.5))
			var spy := int(round(icy - 1.3))
			px(fg, spx, spy, white)
			if not is_elder_fem:
				px(fg, spx + 1, spy, white)
				px(fg, spx, spy + 1, white)
				px(fg, int(round(icx + 1.5)), int(round(icy + 1.5)), white)

		# Pálpebra superior curva com cílio externo orgânico
		var p_in := Vector2(bx, ey + 2 + top_drop)
		var p_mid := Vector2(bx + ew * 0.5, ey - 1 + top_drop)
		var p_out := Vector2(bx + ew - 1, ey + 2 + top_drop)
		if side == 0:
			quad_bezier_line(fg, Vector2(bx - 1, ey + 2 + top_drop), p_mid, p_out, lash, 2)
		else:
			quad_bezier_line(fg, p_in, p_mid, Vector2(bx + ew, ey + 2 + top_drop), lash, 2)
		# Vinco da pálpebra dupla (mais acentuado em idosos e olhares cansados)
		span(fg, bx + 2, bx + ew - 3, ey - 1 + top_drop, sk["sh"] if is_elder else sk["mid"])
		span(fg, bx + 2, bx + ew - 4, ey + eye_h + top_drop, sk["sh"])
		if archetype == "fem":
			px(fg, bx - 1 if side == 0 else bx + ew, ey + 1 + top_drop, lash)

		# Pés de galinha discretos nos cantos externos para personagens idosos
		if is_elder:
			var cx_out := (bx - 2) if side == 0 else (bx + ew + 1)
			var dir_x := -1 if side == 0 else 1
			px(fg, cx_out, ey + eye_h - 1 + top_drop, sk["sh"])
			px(fg, cx_out + dir_x, ey + eye_h + top_drop, sk["mid"])

		# Olheiras marcadas (especialmente forte em Huwag para fidelidade ao sprite, e em cansados/idosos)
		if mood in ["tired", "worried", "unfiltered", "scared", "gruff"] or archetype in ["huwag", "teen", "elder", "elder_fem"]:
			var bag_y := ey + eye_h + top_drop + 2
			var strong_bag := (is_huwag or mood in ["tired", "unfiltered"] or is_elder)
			quad_bezier_line(
				fg,
				Vector2(bx + 1, bag_y),
				Vector2(bx + ew * 0.5, bag_y + 1),
				Vector2(bx + ew - 2, bag_y - 1),
				sk["sh"] if is_huwag or mood == "tired" else sk["mid"],
				1
			)
			if strong_bag:
				span(fg, bx + 2, bx + ew - 4, bag_y - 1, sk["mid"])
				if is_huwag or mood == "tired":
					span(fg, bx + 2, bx + ew - 5, bag_y + 1, sk["mid"])


static func draw_anime_nose_mouth(
	fg: Image, lm: Dictionary, sk: Dictionary, mood: String = "neutral",
	mustache: bool = false, mc: Color = Color("#5A5E66"), blush: bool = false, elder_age: bool = false
) -> void:
	## Nariz minimalista com sombra lateral 3D suave, sulcos de idade opcionais e boca individualizada por expressão.
	var cx: int = lm["cx"]
	var ny: int = lm["nose_y"]
	var my: int = lm["mouth_y"]
	var lip: Color = sk["lip"]
	var dark_in := Color("#1E0C12")

	if blush:
		var base_c: Color = sk["base"]
		var bl := base_c.lerp(Color("#DE6A73"), 0.34)
		span(fg, lm["el_x"] + 2, lm["el_x"] + 6, ny - 3, bl)
		span(fg, lm["er_x"] + 5, lm["er_x"] + 9, ny - 3, bl)

	# Nariz mínimo com volume lateral suave (luz topo-esquerda em hi, lateral direita em soft/mid + narina em sh)
	var soft_m: Color = sk.get("soft", sk["mid"])
	px(fg, cx, ny, sk["sh"])
	px(fg, cx - 1, ny, sk["mid"])
	px(fg, cx + 1, ny - 1, soft_m)
	px(fg, cx + 1, ny - 2, soft_m)
	px(fg, cx + 1, ny - 3, soft_m)
	px(fg, cx, ny - 2, sk["hi"])
	px(fg, cx, ny - 3, sk["hi"])

	# Sulcos nasogenianos contínuos e sutis em rostos idosos (Luningning / Lola Rosa / idosos)
	if elder_age or lm.get("archetype", "") in ["elder_fem", "elder"]:
		line_px(fg, cx - 6, ny + 2, cx - 8, my, soft_m)
		px(fg, cx - 7, ny + 2, sk["mid"])
		line_px(fg, cx + 6, ny + 2, cx + 8, my, soft_m)
		px(fg, cx + 7, ny + 2, sk["mid"])

	if mustache:
		quad_bezier_line(fg, Vector2(cx - 8, my - 2), Vector2(cx - 4, my - 4), Vector2(cx, my - 3), mc, 2)
		quad_bezier_line(fg, Vector2(cx, my - 3), Vector2(cx + 4, my - 4), Vector2(cx + 8, my - 2), mc.darkened(0.20), 2)

	# Boca pequena e expressiva SEM sorriso padrão repetido
	if mood == "uneasy_smile":
		span(fg, cx - 4, cx + 1, my + 1, lip)
		line_px(fg, cx + 1, my + 1, cx + 5, my - 1, lip)
		px(fg, cx + 6, my - 1, sk["mid"])
		span(fg, cx - 2, cx + 2, my + 3, sk["mid"])
	elif mood == "warm":
		quad_bezier_line(fg, Vector2(cx - 4, my - 1), Vector2(cx, my + 2), Vector2(cx + 4, my - 1), lip, 1)
		span(fg, cx - 1, cx + 1, my + 3, sk["mid"])
	elif mood == "surprised":
		disc(fg, float(cx), float(my + 1), 2.8, 3.0, dark_in)
		span(fg, cx - 1, cx + 1, my - 1, Color("#EFE6DE"))
		span(fg, cx - 2, cx + 2, my + 4, sk["sh"])
	elif mood == "scared":
		disc(fg, float(cx), float(my + 1), 4.2, 2.6, dark_in)
		span(fg, cx - 3, cx + 3, my, Color("#F2EBE4"))
		span(fg, cx - 2, cx + 2, my + 2, Color("#8A2E38"))
		span(fg, cx - 2, cx + 2, my + 4, sk["sh"])
	elif mood in ["worried", "angry"]:
		quad_bezier_line(fg, Vector2(cx - 4, my + 1), Vector2(cx, my - 1), Vector2(cx + 4, my + 1), lip, 1)
		span(fg, cx - 2, cx + 2, my + 3, sk["sh"])
	elif mood == "stern":
		# Boca tensa e firme de autoridade (canto levemente caído e contraído)
		span(fg, cx - 4, cx + 4, my, lip)
		px(fg, cx - 5, my + 1, lip); px(fg, cx + 5, my + 1, lip)
		span(fg, cx - 2, cx + 2, my + 2, sk["sh"])
	elif mood == "gruff":
		# Boca reta e pesada de trabalho duro
		span(fg, cx - 4, cx + 4, my + 1, lip)
		px(fg, cx - 5, my + 1, sk["mid"]); px(fg, cx + 5, my + 2, lip)
		span(fg, cx - 2, cx + 2, my + 3, sk["sh"])
	elif mood == "tired":
		span(fg, cx - 3, cx + 3, my + 1, lip.darkened(0.14))
		span(fg, cx - 1, cx + 1, my + 3, sk["sh"])
	elif mood == "unfiltered":
		span(fg, cx - 4, cx + 4, my, dark_in)
		span(fg, cx - 2, cx + 2, my + 2, sk["sh"])
	else:
		# Neutro / Sério: boca reta limpa (zero sorriso puxado para cima!)
		span(fg, cx - 4, cx + 3, my + 1, lip)
		span(fg, cx - 1, cx + 1, my + 3, sk["mid"])


static func draw_anime_shoulders(
	fg: Image, y_neck: int, y_edge: int, col_mid: Color, col_sh: Color, col_hi: Color, col_ink: Color,
	width_half: int = 34, v_cut: int = 7, cx_pos: int = 47
) -> void:
	## Desenha ombros orgânicos e gola com dobras de tecido e sombreado em planos anime.
	var xl_m: Dictionary = {}
	var xr_m: Dictionary = {}
	for y in range(y_neck, SIZE):
		var dy: int = y - y_neck
		var prog := clampf(float(dy) / maxf(1.0, float(maxi(1, y_edge - y_neck))), 0.0, 1.0)
		var hw := int(round(lerpf(11.0, float(width_half), sin(prog * PI * 0.5))))
		var gap: int = maxi(-1, v_cut - int(round(float(dy) * 0.65))) if v_cut > 0 else -1
		var xl := cx_pos - hw
		var xr := cx_pos + hw
		xl_m[y] = xl
		xr_m[y] = xr
		for x in range(xl + 1, xr):
			if gap >= 0 and absi(x - cx_pos) <= gap:
				if absi(x - cx_pos) == gap:
					px(fg, x, y, col_ink)
				continue
			if y == y_neck:
				px(fg, x, y, col_ink)
				continue
			var col_draw := col_mid
			var dx := float(x - cx_pos)
			# Iluminação no ombro esquerdo e aresta da gola + dobras inclinadas da manga/axila
			if dx < -3.0 and (prog < 0.42 or x < cx_pos - hw + 6):
				col_draw = col_hi
			elif dy >= 6 and (absf(absf(dx) - float(hw) * 0.62) < 1.3 and dy < 13):
				col_draw = col_sh
			elif dy >= 7 and x < cx_pos - 4 and absi(x - (cx_pos - 9 - (dy - 7) / 2)) <= 0:
				col_draw = col_sh
			elif dx > 6.0 or (dy > 4 and x > cx_pos + hw - 6):
				col_draw = col_sh
			px(fg, x, y, col_draw)
	for y in range(y_neck, SIZE - 1):
		px(fg, xl_m[y], y, col_ink)
		px(fg, xr_m[y], y, col_ink)
		if xl_m.has(y + 1):
			var nl: int = xl_m[y + 1]
			var nr: int = xr_m[y + 1]
			if absi(xl_m[y] - nl) > 1:
				span(fg, mini(xl_m[y], nl), maxi(xl_m[y], nl), y, col_ink)
			if absi(xr_m[y] - nr) > 1:
				span(fg, mini(xr_m[y], nr), maxi(xr_m[y], nr), y, col_ink)


static func split_half_shadow(fg: Image, lm: Dictionary, side: String = "right") -> void:
	## Mergulha metade do busto anime no breu absoluto (Anexo 4 World of Horror!)
	var shadow := Color("#080409")
	var cx: int = lm["cx"]
	for y in range(6, SIZE):
		for x in range(6, SIZE - 6):
			if fg.get_pixel(x, y).a < 0.5:
				continue
			var cut := cx + (1 if y % 6 < 3 else 0)
			if (side == "right" and x >= cut) or (side == "left" and x <= cut):
				fg.set_pixel(x, y, shadow)
