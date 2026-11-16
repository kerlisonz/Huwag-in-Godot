class_name PixelArtCanvas
extends RefCounted

## Crisp integer-pixel drawing primitives for 96x96 character sheets.
## Produces clean ink silhouettes, discrete 4-tone cel-shading (zero AA/gradients),
## sharp pointed hair locks with dual root/tip shading, and ground shadows.

const CELL_W: int = 96
const CELL_H: int = 96
const FOOT_ANCHOR := Vector2(48.0, 82.0)


static func create_cell() -> Image:
	var img := Image.create(CELL_W, CELL_H, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	return img


static func draw_ground_shadow(img: Image, cx: float, cy: float, rx: float, ry: float, inner_col: Color, outer_col: Color) -> void:
	for y in range(int(floor(cy - ry - 1.0)), int(ceil(cy + ry + 1.0)) + 1):
		for x in range(int(floor(cx - rx - 1.0)), int(ceil(cx + rx + 1.0)) + 1):
			var dx: float = (float(x) - cx) / maxf(1.0, rx)
			var dy: float = (float(y) - cy) / maxf(1.0, ry)
			var d2: float = dx * dx + dy * dy
			if d2 <= 0.68:
				set_px(img, x, y, inner_col)
			elif d2 <= 1.0:
				set_px(img, x, y, outer_col)


static func draw_shaded_limb(buf: Image, a: Vector2, b: Vector2, r_a: float, r_b: float, pal: Array, shade_bias: float = 0.0) -> void:
	var min_x: int = clampi(int(floor(minf(a.x, b.x) - maxf(r_a, r_b) - 1.0)), 0, CELL_W - 1)
	var max_x: int = clampi(int(ceil(maxf(a.x, b.x) + maxf(r_a, r_b) + 1.0)), 0, CELL_W - 1)
	var min_y: int = clampi(int(floor(minf(a.y, b.y) - maxf(r_a, r_b) - 1.0)), 0, CELL_H - 1)
	var max_y: int = clampi(int(ceil(maxf(a.y, b.y) + maxf(r_a, r_b) + 1.0)), 0, CELL_H - 1)

	var ab: Vector2 = b - a
	var ab_len2: float = maxf(0.001, ab.length_squared())
	var max_idx: int = pal.size() - 1

	for y in range(min_y, max_y + 1):
		for x in range(min_x, max_x + 1):
			var p: Vector2 = Vector2(float(x), float(y))
			var t: float = clampf((p - a).dot(ab) / ab_len2, 0.0, 1.0)
			var closest: Vector2 = a + ab * t
			var r: float = lerpf(r_a, r_b, t)
			var diff: Vector2 = p - closest
			var dist: float = diff.length()
			if dist <= r:
				var nx: float = diff.x / maxf(1.0, r)
				var ny: float = diff.y / maxf(1.0, r)
				var light_v: float = -nx * 0.56 - ny * 0.52 + 0.24 + shade_bias
				var idx: int = clampi(int(round((light_v + 0.5) * float(max_idx))), 0, max_idx)
				buf.set_pixel(x, y, pal[idx])


static func draw_shaded_oval(buf: Image, c: Vector2, rx: float, ry: float, pal: Array, shade_bias: float = 0.0) -> void:
	var max_idx: int = pal.size() - 1
	var min_x: int = clampi(int(floor(c.x - rx - 1.0)), 0, CELL_W - 1)
	var max_x: int = clampi(int(ceil(c.x + rx + 1.0)), 0, CELL_W - 1)
	var min_y: int = clampi(int(floor(c.y - ry - 1.0)), 0, CELL_H - 1)
	var max_y: int = clampi(int(ceil(c.y + ry + 1.0)), 0, CELL_H - 1)
	for y in range(min_y, max_y + 1):
		for x in range(min_x, max_x + 1):
			var nx: float = (float(x) - c.x) / maxf(1.0, rx)
			var ny: float = (float(y) - c.y) / maxf(1.0, ry)
			if nx * nx + ny * ny <= 1.0:
				var light_v: float = -nx * 0.56 - ny * 0.52 + 0.24 + shade_bias
				var idx: int = clampi(int(round((light_v + 0.5) * float(max_idx))), 0, max_idx)
				buf.set_pixel(x, y, pal[idx])


static func draw_shaded_disk(buf: Image, c: Vector2, r: float, pal: Array, shade_bias: float = 0.0) -> void:
	draw_shaded_oval(buf, c, r, r, pal, shade_bias)


## Draws a sharp triangular/curved anime hair spike tapering from half_w at root down to a 1px tip.
## root_ratio controls how much of the base shows dark unbleached hair root.
static func draw_pointed_hair_lock(
	buf: Image,
	base: Vector2,
	tip: Vector2,
	half_w: float,
	bend: float,
	root_col: Color,
	blond_pal: Array,
	root_ratio: float = 0.28,
	shade_bias: float = 0.0
) -> void:
	var dir: Vector2 = tip - base
	var len_val: float = dir.length()
	if len_val < 0.8:
		return
	var u: Vector2 = dir / len_val
	var n: Vector2 = Vector2(-u.y, u.x)

	var pad: float = half_w + absf(bend) + 2.0
	var min_x: int = clampi(int(floor(minf(base.x, tip.x) - pad)), 0, CELL_W - 1)
	var max_x: int = clampi(int(ceil(maxf(base.x, tip.x) + pad)), 0, CELL_W - 1)
	var min_y: int = clampi(int(floor(minf(base.y, tip.y) - pad)), 0, CELL_H - 1)
	var max_y: int = clampi(int(ceil(maxf(base.y, tip.y) + pad)), 0, CELL_H - 1)

	var max_idx: int = blond_pal.size() - 1
	for y in range(min_y, max_y + 1):
		for x in range(min_x, max_x + 1):
			var rel: Vector2 = Vector2(float(x), float(y)) - base
			var t: float = rel.dot(u) / len_val
			if t < -0.05 or t > 1.02:
				continue
			var ct: float = clampf(t, 0.0, 1.0)
			var spine_offset: float = sin(ct * PI) * bend
			var s: float = rel.dot(n) - spine_offset
			# Concave anime spike taper reaching a crisp 0.45px tip at ct=1
			var local_w: float = maxf(0.45, half_w * pow(1.0 - ct, 1.15))
			if absf(s) <= local_w:
				if ct < root_ratio:
					buf.set_pixel(x, y, root_col)
				else:
					var side_n: float = s / maxf(0.5, local_w)
					var tip_boost: float = (ct - root_ratio) * 0.48
					var light_v: float = -u.y * 0.28 - u.x * 0.18 - side_n * 0.35 + tip_boost + shade_bias
					var idx: int = clampi(int(round(clampf(light_v + 0.45, 0.0, 1.0) * float(max_idx))), 0, max_idx)
					buf.set_pixel(x, y, blond_pal[idx])


## Draws a solid un-outlined bar across an axis with discrete light/shadow tones.
static func draw_flat_capsule(buf: Image, a: Vector2, b: Vector2, half_w: float, col_light: Color, col_mid: Color, col_dark: Color) -> void:
	var ab: Vector2 = b - a
	var ab_len2: float = maxf(0.001, ab.length_squared())
	var min_x: int = clampi(int(floor(minf(a.x, b.x) - half_w - 1.0)), 0, CELL_W - 1)
	var max_x: int = clampi(int(ceil(maxf(a.x, b.x) + half_w + 1.0)), 0, CELL_W - 1)
	var min_y: int = clampi(int(floor(minf(a.y, b.y) - half_w - 1.0)), 0, CELL_H - 1)
	var max_y: int = clampi(int(ceil(maxf(a.y, b.y) + half_w + 1.0)), 0, CELL_H - 1)
	for y in range(min_y, max_y + 1):
		for x in range(min_x, max_x + 1):
			var p := Vector2(float(x), float(y))
			var t: float = clampf((p - a).dot(ab) / ab_len2, 0.0, 1.0)
			var closest: Vector2 = a + ab * t
			var diff: Vector2 = p - closest
			if diff.length() <= half_w:
				var lv: float = -diff.x - diff.y
				if lv > half_w * 0.35:
					buf.set_pixel(x, y, col_light)
				elif lv < -half_w * 0.35:
					buf.set_pixel(x, y, col_dark)
				else:
					buf.set_pixel(x, y, col_mid)


## Stamps a drawn buffer onto dst while generating a crisp 1px cardinal ink outline around it.
static func stamp_outlined_part(dst: Image, part: Image, ink: Color, x_min: int = 1, x_max: int = CELL_W - 2, y_min: int = 1, y_max: int = CELL_H - 2) -> void:
	for y in range(y_min, y_max + 1):
		for x in range(x_min, x_max + 1):
			var c: Color = part.get_pixel(x, y)
			if c.a > 0.5:
				dst.set_pixel(x, y, c)
			elif (
				part.get_pixel(x - 1, y).a > 0.5
				or part.get_pixel(x + 1, y).a > 0.5
				or part.get_pixel(x, y - 1).a > 0.5
				or part.get_pixel(x, y + 1).a > 0.5
			):
				dst.set_pixel(x, y, ink)


static func blit_alpha(dst: Image, src: Image) -> void:
	for y in range(CELL_H):
		for x in range(CELL_W):
			var c: Color = src.get_pixel(x, y)
			if c.a > 0.1:
				dst.set_pixel(x, y, c)


static func set_px(img: Image, x: int, y: int, col: Color) -> void:
	if x >= 0 and x < img.get_width() and y >= 0 and y < img.get_height():
		img.set_pixel(x, y, col)
