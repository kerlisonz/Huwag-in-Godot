class_name CorruptedV4Builder
extends RefCounted

## Gerador procedural pixel-art grotesco (Etapa 2) em grade 48x48, ancoragem y = 39.
## Construído por escultura anatômica orgânica + passagem de contorno nítido de 1px (sem blocos geométricos).

const CELL_W := 48
const CELL_H := 48
const FOOT_Y := 39
const DIRS: Array[String] = ["down", "up", "left", "right"]

const C_NONE := -1
const C_OUT := 0

# Paleta compartilhada + tokens específicos por criatura (mapeados via pal dict)
# Chave int -> Color
static func c(hex: String) -> Color:
	return Color(hex)


class PixelSculptor:
	var w: int
	var h: int
	var grid: PackedInt32Array

	func _init(pw: int = 48, ph: int = 48) -> void:
		w = pw
		h = ph
		grid = PackedInt32Array()
		grid.resize(w * h)
		grid.fill(C_NONE)

	func clear() -> void:
		grid.fill(C_NONE)

	func has_px(x: int, y: int) -> bool:
		return x >= 0 and x < w and y >= 0 and y < h and grid[y * w + x] != C_NONE

	func get_tok(x: int, y: int) -> int:
		if x < 0 or x >= w or y < 0 or y >= h:
			return C_NONE
		return grid[y * w + x]

	func px(x: int, y: int, tok: int, only_if_empty: bool = false) -> void:
		if x < 1 or x >= w - 1 or y < 1 or y > FOOT_Y - 1:
			return
		var idx := y * w + x
		if only_if_empty and grid[idx] != C_NONE:
			return
		grid[idx] = tok

	func blob(cx: float, cy: float, rx: float, ry: float, tok: int, shade_tok: int = -99, hi_tok: int = -99, jag: int = 0) -> void:
		var x0 := int(floor(cx - rx - 1.0))
		var x1 := int(ceil(cx + rx + 1.0))
		var y0 := int(floor(cy - ry - 1.0))
		var y1 := int(ceil(cy + ry + 1.0))
		for y in range(y0, y1 + 1):
			for x in range(x0, x1 + 1):
				var dx := (float(x) - cx) / maxf(0.5, rx)
				var dy := (float(y) - cy) / maxf(0.5, ry)
				var d := dx * dx + dy * dy
				if jag != 0:
					var hsh := ((x * 73 + y * 139 + jag * 31) & 7) - 3
					d += float(hsh) * 0.045
				if d <= 1.0:
					var use := tok
					if shade_tok != -99 and (dy > 0.35 or dx > 0.42):
						use = shade_tok
					elif hi_tok != -99 and dy < -0.32 and dx < 0.25:
						use = hi_tok
					px(x, y, use)

	func limb(p0: Vector2, p1: Vector2, r0: float, r1: float, tok: int, shade_tok: int = -99, bend: Vector2 = Vector2.ZERO) -> void:
		var dist := p0.distance_to(p1) + bend.length()
		var steps := maxi(4, int(ceil(dist * 2.2)))
		var mid := (p0 + p1) * 0.5 + bend
		for i in range(steps + 1):
			var t := float(i) / float(steps)
			var omt := 1.0 - t
			var pt := p0 * (omt * omt) + mid * (2.0 * omt * t) + p1 * (t * t)
			var r := lerpf(r0, r1, t)
			if r <= 0.65:
				px(int(round(pt.x)), int(round(pt.y)), tok if t < 0.7 or shade_tok == -99 else shade_tok)
			else:
				var irx := int(ceil(r))
				for dy in range(-irx, irx + 1):
					for dx in range(-irx, irx + 1):
						if float(dx * dx + dy * dy) <= r * r + 0.15:
							var col_t := shade_tok if (shade_tok != -99 and (dx > 0 or t > 0.68)) else tok
							px(int(round(pt.x)) + dx, int(round(pt.y)) + dy, col_t)

	func claws(tip: Vector2, dir_vec: Vector2, len_px: float, tok: int, spread: float = 0.7) -> void:
		var n := dir_vec.normalized()
		var perp := Vector2(-n.y, n.x)
		for s: float in [-1.0, 0.0, 1.0]:
			var p_end: Vector2 = tip + (n * len_px) + (perp * (s * len_px * spread))
			limb(tip, p_end, 0.55, 0.35, tok)

	func ragged_hem(x0: int, x1: int, y_base: int, tok_a: int, tok_b: int, seed_v: int) -> void:
		for x in range(x0, x1 + 1):
			var drop := ((x * 53 + seed_v * 19) % 4)
			for dy in range(0, drop + 1):
				px(x, y_base + dy, tok_b if (dy == drop or ((x + dy) % 3 == 0)) else tok_a)

	func apply_outline(out_tok: int = C_OUT) -> void:
		var out_pts: Array[Vector2i] = []
		for y in range(1, h - 1):
			for x in range(1, w - 1):
				if grid[y * w + x] != C_NONE:
					continue
				if (grid[(y - 1) * w + x] != C_NONE
					or grid[(y + 1) * w + x] != C_NONE
					or grid[y * w + (x - 1)] != C_NONE
					or grid[y * w + (x + 1)] != C_NONE):
					out_pts.append(Vector2i(x, y))
		for pt in out_pts:
			grid[pt.y * w + pt.x] = out_tok

	func render_to_image(pal: Dictionary) -> Image:
		var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
		img.fill(Color(0, 0, 0, 0))
		for y in range(h):
			for x in range(w):
				var t := grid[y * w + x]
				if t != C_NONE and pal.has(t):
					img.set_pixel(x, y, pal[t])
		return img


# Tokens padrão universais (0..29)
enum T {
	OUT = 0,
	# Pele necrosada / cinza-esverdeada / pálida
	SKIN_HI = 1,
	SKIN = 2,
	SKIN_SH = 3,
	# Osso / costela / dentes / garra pálida
	BONE_HI = 4,
	BONE = 5,
	BONE_SH = 6,
	# Vísceras / sangue / boca escura
	MAW_VOID = 7,
	FLESH = 8,
	BLOOD_HI = 9,
	BLOOD_SH = 10,
	# Olho / brasa / brilho sobrenatural
	EYE_GLOW = 11,
	EYE_CORE = 12,
	# Roupa principal (rasgada/suja)
	CLOTH_HI = 13,
	CLOTH = 14,
	CLOTH_SH = 15,
	# Faixa / avental / xale / detalhe secundário
	ACCENT_HI = 16,
	ACCENT = 17,
	ACCENT_SH = 18,
	# Chapéu / capacete / lenço / cabelo
	HAT_HI = 19,
	HAT = 20,
	HAT_SH = 21,
	HAIR = 22,
	HAIR_SH = 23,
	# Arma / metal / cabo
	METAL_HI = 24,
	METAL = 25,
	METAL_SH = 26,
	WOOD = 27,
	WOOD_SH = 28,
}


static func make_palette(cfg: Dictionary) -> Dictionary:
	var p := {
		T.OUT: c(cfg.get("out", "#140B12")),
		T.SKIN_HI: c(cfg.get("skin_hi", "#9A8F93")),
		T.SKIN: c(cfg.get("skin", "#73656B")),
		T.SKIN_SH: c(cfg.get("skin_sh", "#4B3E45")),
		T.BONE_HI: c("#F0E6DC"),
		T.BONE: c("#CBB8AD"),
		T.BONE_SH: c("#8A7570"),
		T.MAW_VOID: c("#1D060D"),
		T.FLESH: c("#941928"),
		T.BLOOD_HI: c("#DF2E43"),
		T.BLOOD_SH: c("#5C0B17"),
		T.EYE_GLOW: c(cfg.get("eye_glow", "#FF3B4D")),
		T.EYE_CORE: c(cfg.get("eye_core", "#FFF2C2")),
		T.CLOTH_HI: c(cfg.get("cloth_hi", "#3A4458")),
		T.CLOTH: c(cfg.get("cloth", "#232A38")),
		T.CLOTH_SH: c(cfg.get("cloth_sh", "#141822")),
		T.ACCENT_HI: c(cfg.get("accent_hi", "#E09A48")),
		T.ACCENT: c(cfg.get("accent", "#9E4D2D")),
		T.ACCENT_SH: c(cfg.get("accent_sh", "#61291D")),
		T.HAT_HI: c(cfg.get("hat_hi", "#7D6835")),
		T.HAT: c(cfg.get("hat", "#544321")),
		T.HAT_SH: c(cfg.get("hat_sh", "#322614")),
		T.HAIR: c(cfg.get("hair", "#322E38")),
		T.HAIR_SH: c(cfg.get("hair_sh", "#1D1A22")),
		T.METAL_HI: c(cfg.get("metal_hi", "#DCE6F0")),
		T.METAL: c(cfg.get("metal", "#8F9AA6")),
		T.METAL_SH: c(cfg.get("metal_sh", "#4F5763")),
		T.WOOD: c(cfg.get("wood", "#5E3B2C")),
		T.WOOD_SH: c(cfg.get("wood_sh", "#38221A")),
	}
	return p
