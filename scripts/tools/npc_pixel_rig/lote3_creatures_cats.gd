extends RefCounted
class_name Lote3CreaturesCats

## Lote 3 — Criaturas (Santelmo, Guardiã da Lagoa) & Gatos (Pusa, Gatinho)
## Pixel art 16-bit autoral, escala orgânica coerente com Huwag (48x48 criaturas / 32x32 gatos, Nearest Neighbor)

const OUT_CREATURES := "res://assets/sprites/creatures"
const OUT_CATS := "res://assets/sprites/cats"


static func _set_px(img: Image, x: int, y: int, c: Color) -> void:
	if x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height():
		img.set_pixel(x, y, c)


static func _blend_px(img: Image, x: int, y: int, c: Color) -> void:
	if x < 0 or y < 0 or x >= img.get_width() or y >= img.get_height():
		return
	var dst := img.get_pixel(x, y)
	if dst.a <= 0.01:
		img.set_pixel(x, y, c)
	else:
		img.set_pixel(x, y, dst.lerp(c, c.a))


static func _blit_grid(img: Image, ox: int, oy: int, rows: PackedStringArray, pal: Dictionary, flip_x: bool = false) -> void:
	var h := rows.size()
	for ry in range(h):
		var line := rows[ry]
		var w := line.length()
		for rx in range(w):
			var ch := line.substr(rx, 1)
			if ch == "." or ch == " " or not pal.has(ch):
				continue
			var px := ox + (w - 1 - rx if flip_x else rx)
			var py := oy + ry
			_set_px(img, px, py, pal[ch])


static func _apply_dark_outline(img: Image, outline_col: Color) -> void:
	var w := img.get_width()
	var h := img.get_height()
	var src := img.duplicate() as Image
	var dirs: Array[Vector2i] = [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]
	for y in range(h):
		for x in range(w):
			if src.get_pixel(x, y).a > 0.45:
				continue
			for d in dirs:
				var nx: int = x + d.x
				var ny: int = y + d.y
				if nx >= 0 and ny >= 0 and nx < w and ny < h:
					if src.get_pixel(nx, ny).a > 0.55:
						img.set_pixel(x, y, outline_col)
						break


static func _draw_ellipse_alpha(img: Image, cx: int, cy: int, rx: float, ry: float, col: Color) -> void:
	for y in range(cy - int(ceil(ry)) - 1, cy + int(ceil(ry)) + 2):
		for x in range(cx - int(ceil(rx)) - 1, cx + int(ceil(rx)) + 2):
			var dx := float(x - cx) / maxf(rx, 0.5)
			var dy := float(y - cy) / maxf(ry, 0.5)
			if dx * dx + dy * dy <= 1.0:
				_blend_px(img, x, y, col)


static func _ensure_dir(res_path: String) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(res_path))


static func _save_tex(img: Image, res_path: String) -> Texture2D:
	var abs_p := ProjectSettings.globalize_path(res_path)
	img.save_png(abs_p)
	return ImageTexture.create_from_image(img)


static func _make_spriteframes(anims: Array[Dictionary]) -> SpriteFrames:
	var sf := SpriteFrames.new()
	if sf.has_animation("default"):
		sf.remove_animation("default")
	for anim_def in anims:
		var name: String = anim_def["name"]
		var fps: float = anim_def.get("fps", 6.0)
		var loop_flag: bool = anim_def.get("loop", true)
		var frames: Array = anim_def["frames"]
		sf.add_animation(name)
		sf.set_animation_speed(name, fps)
		sf.set_animation_loop(name, loop_flag)
		for tex in frames:
			sf.add_frame(name, tex)
	return sf


static func _save_sheet(frames: Array[Image], out_png: String) -> void:
	if frames.is_empty():
		return
	var cw := frames[0].get_width()
	var ch := frames[0].get_height()
	var sheet := Image.create(cw * frames.size(), ch, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0, 0, 0, 0))
	for i in range(frames.size()):
		sheet.blit_rect(frames[i], Rect2i(0, 0, cw, ch), Vector2i(i * cw, 0))
	sheet.save_png(ProjectSettings.globalize_path(out_png))


# ===========================================================================
# 1. SANTELMO (Espírito de Fogo Folclórico — 48x48 orgânico)
# ===========================================================================

static func _santelmo_palette(distorted: bool, quenched: bool = false) -> Dictionary:
	if quenched:
		return {
			"O": Color("#18324D"),
			"D": Color("#2E6BA8"),
			"M": Color("#5CB8FF"),
			"B": Color("#AEE6FF"),
			"C": Color("#F0FBFF"),
			"E": Color("#0E2036"),
			"G": Color("#FFFFFF"),
			"S": Color("#7F8FA6"),
		}
	if distorted:
		return {
			"O": Color("#2B0712"),
			"D": Color("#7D0F24"),
			"M": Color("#D92338"),
			"B": Color("#FF6E4A"),
			"C": Color("#FFE8F0"),
			"E": Color("#140308"),
			"G": Color("#FFF5B8"),
			"S": Color("#6B2430"),
		}
	return {
		"O": Color("#380F0C"),
		"D": Color("#A82218"),
		"M": Color("#EB5D1E"),
		"B": Color("#FAB02D"),
		"C": Color("#FFF7C2"),
		"E": Color("#240706"),
		"G": Color("#FFFCE0"),
		"S": Color("#8A4E3C"),
	}


const SANTELMO_IDLE_0: PackedStringArray = [
	"..........DD............",
	".........DMDD...........",
	"........DDMBD...D.......",
	".......DDMMBBD.DM.......",
	"......DDMMBBBBDMD.......",
	".....DDMMBBCCBBMD.......",
	"....DDMMBBCCCCBBMD......",
	"....DMMBBCCCCCCBBMD.....",
	"...DDMMBCCGCCCGCCMD.....",
	"...DMMBBCEECMCEECMD.....",
	"...DMMBBCEECMCEECMD.....",
	"...DMMBBCCCCCCCCBMD.....",
	"...DDMMBBCCCCCCBBMD.....",
	"....DMMBBBBCCBBBMD......",
	"....DDMMBBBBBBBBMD......",
	".....DDMMMMMMMMMDD......",
	"......DDDDMMMMDDD.......",
	"........DDDDDDDD........",
]

const SANTELMO_IDLE_1: PackedStringArray = [
	"............DD..........",
	".......D...DMMD.........",
	".......MD.DDMBMD........",
	"......DMDDDMBBBDD.......",
	".....DDMMBMMBBBBMD......",
	"....DDMMBBBCCBBBMD......",
	"....DMMBBCCCCCCBBMD.....",
	"...DDMMBCCCCCCCCBMD.....",
	"...DMMBBCGCCMCCGCBMD....",
	"...DMMBBCEECMCEECBMD....",
	"...DMMBBCEECBCEECBMD....",
	"...DMMBBBCCCCCCBBMD.....",
	"....DMMBBBCCCCBBMD......",
	"....DDMMBBBBBBBBMD......",
	".....DDMMMMMMMMMDD......",
	"......DDDMMMMMDDD.......",
	"........DDDDDDDD........",
]

const SANTELMO_IDLE_2: PackedStringArray = [
	".............DD.........",
	"........D...DMMD........",
	".......DMD.DDMBMD.......",
	".......DMBDDMMBBD.......",
	"......DDMBBMMBBBMD......",
	".....DDMMBBBCCBBMMD.....",
	".....DMMBBCCCCCCBMD.....",
	"....DDMMBCCCCCCCCBMD....",
	"....DMMBCCGCCMCCGCBM....",
	"...DDMMBCEECMMCEECBM....",
	"...DMMBBCEECBBCEECBM....",
	"...DMMBBCCCCCCCCBBMD....",
	"....DMMBBBCCCCCCBMD.....",
	"....DDMMBBBBCCBBMD......",
	".....DDMMBBBBBBMDD......",
	"......DDMMMMMMMMDD......",
	".......DDDDMMMDDD.......",
	"........DDDDDDDD........",
]

const SANTELMO_IDLE_3: PackedStringArray = [
	".........DD.............",
	"........DMMD...D........",
	".......DDMBD..DMD.......",
	".......DMMBBD.DMBD......",
	"......DDMMBBBDDMBD......",
	".....DDMMBBCCBBMMD......",
	"....DDMMBBCCCCCCBMD.....",
	"....DMMBBCCCCCCCCBMD....",
	"...DDMMBCCGCCMCCGCBM....",
	"...DMMBBCEECMMCEECBM....",
	"...DMMBBCEECBBCEECBM....",
	"...DMMBBCCCCCCCCBBMD....",
	"....DMMBBBCCCCCCBMD.....",
	"....DDMMBBBBCCBBMD......",
	".....DMMBBBBBBBMMD......",
	"......DMMMMMMMMMDD......",
	".......DDDMMMMDDD.......",
	"........DDDDDDDD........",
]

const SANTELMO_MOVE_0: PackedStringArray = [
	"...DD...................",
	"..DMDD..................",
	"...DMMBD....DD..........",
	"....DMMBDDMMMMD.........",
	"...DDMMBMMBBBBMD........",
	"...DMMMBBCCBBBBMD.......",
	"...DMMBBCCCCCCCBBMD.....",
	"..DDMMBCCGCCMCCGCBMD....",
	"..DMMBBCEECMMCEECBBMD...",
	"..DMMBBCEECBBCEECBBMD...",
	"...DMMBBCCCCCCCCBBMD....",
	"...DDMMBBBBCCCBBBMD.....",
	"....DDMMBBBBBBBBMD......",
	".....DDMMMMMMMMDD.......",
	".......DDDDDDDDD........",
]

const SANTELMO_MOVE_1: PackedStringArray = [
	".DD.....................",
	"..DMMD.....DD...........",
	"...DMMBD..DMMMD.........",
	"..DDMMBBDMMBBBBMD.......",
	"...DMMMBBCCBBBBMD.......",
	"...DMMBBCCCCCCCBBMD.....",
	"..DDMMBCCGCCMCCGCBMD....",
	"..DMMBBCEECMMCEECBBMD...",
	"..DMMBBCEECBBCEECBBMD...",
	"...DMMBBBCCCCCCBBMD.....",
	"...DDMMBBBBCCCBBBMD.....",
	"....DDMMBBBBBBBBMD......",
	".....DDMMMMMMMDDD.......",
	".......DDDDDDDDD........",
]

const SANTELMO_ATK_CHARGE: PackedStringArray = [
	".........DD..DD.........",
	"........DMBDDBMD........",
	".......DDMBBBBMMD.......",
	"......DDMMBCCCBBMD......",
	".....DDMMBCCCCCCBMD.....",
	".....DMMBCGCCMCGCBMD....",
	".....DMMBCEECMCEECMD....",
	".....DMMBCCCCCCCBMMD....",
	"......DMMBBBBBBBBMD.....",
	".......DMMMMMMMMMD......",
	"........DDDDDDDDD.......",
]

const SANTELMO_ATK_BURST: PackedStringArray = [
	"....D......DD......D....",
	"...DM.....DMBD.....MD...",
	"D..DMB...DDMBBDD...BMD.D",
	".M.DMBB..DMMBBMD..BBMDM.",
	".DMDDMBBMMMCCCBBMBBDMD..",
	"..DMMMBBCCCCCCCCBBMMD...",
	"DDMMBBCCGCCCCCCGCCBMMDDD",
	".DMMBBCEECMMCCCEECBBMMD.",
	"DDMMBBCEECBBCCCEECBBMMDD",
	".DMMBBCCCCCCCCCCCCBBMMD..",
	"..DMMBBBBCCCCCCCBBBMD...",
	".DDMMBBBBBBBBBBBBMMDD...",
	"D..DDMMMMMMMMMMMMDD..D..",
	"...D.DDDMMMMMMDDD.D.....",
	"..D.....DDDDDD.....D....",
]

const SANTELMO_HURT_GRID: PackedStringArray = [
	"......SS......SS........",
	".....S..S....S..........",
	".......DDD..DDD.........",
	"......DMMBBDMBBD........",
	".....DDMBBCCCCBMD.......",
	".....DMMBCGCCGCBMD......",
	".....DMMBCEEBCEEMD......",
	".....DMMBCCCCCCCBMD.....",
	"......DMMBBBBBBBMD......",
	".......DDMMMMMMDD.......",
	"........DDDDDDDD........",
]

const SANTELMO_DEATH_1: PackedStringArray = [
	".........SS....SS.......",
	"........S........S......",
	".........DDDDDD.........",
	".......DDMMBBBMDD.......",
	"......DMMBCCCCBBMD......",
	"......DMMBCCCCCCMD......",
	"......DDMBBBBBBMDD......",
	".......DDDDMMMDDD.......",
	"........SSSSSSSS........",
]

const SANTELMO_DEATH_2: PackedStringArray = [
	".......S.........S......",
	"........S......S........",
	"........................",
	".........DDDDDD.........",
	".......DDMMBBBMDD.......",
	".......DSSSSSSSSMD......",
	"......SSSSSSSSSSSS......",
]

const SANTELMO_DEATH_3: PackedStringArray = [
	".......S..........S.....",
	"..........S.............",
	"........................",
	".......SS..DD..SS.......",
	"......SSSSSSSSSSSS......",
]


static func _render_santelmo_frame(kind: String, fidx: int, distorted: bool) -> Image:
	var img := Image.create(48, 48, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var quenched: bool = (kind == "hurt" and fidx != 1)
	var pal := _santelmo_palette(distorted, quenched)
	var eye_line: Color = pal["O"]

	var bob: int = 0
	var ox: int = 12
	var oy: int = 11
	var grid: PackedStringArray = SANTELMO_IDLE_0

	match kind:
		"idle":
			var idles: Array[PackedStringArray] = [SANTELMO_IDLE_0, SANTELMO_IDLE_1, SANTELMO_IDLE_2, SANTELMO_IDLE_3]
			grid = idles[fidx % 4]
			var bobs_i: Array[int] = [0, -1, 0, 1]
			bob = bobs_i[fidx % 4]
		"move":
			grid = SANTELMO_MOVE_0 if (fidx % 2 == 0) else SANTELMO_MOVE_1
			var m_ox: Array[int] = [-1, 1, 0, -1]
			var m_bob: Array[int] = [-1, 0, -1, 1]
			ox = 12 + m_ox[fidx % 4]
			bob = m_bob[fidx % 4]
		"attack":
			if fidx == 0:
				grid = SANTELMO_ATK_CHARGE
				oy = 15
			elif fidx == 1 or fidx == 2:
				grid = SANTELMO_ATK_BURST
				ox = 12 + (1 if fidx == 2 else 0)
				oy = 12
			else:
				grid = SANTELMO_IDLE_1
				oy = 11
		"hurt":
			grid = SANTELMO_HURT_GRID
			ox = 12 + (2 if fidx == 0 else (-2 if fidx == 1 else 0))
			oy = 15
		"death":
			if fidx == 0:
				grid = SANTELMO_ATK_CHARGE
				oy = 18
			elif fidx == 1:
				grid = SANTELMO_DEATH_1
				oy = 22
			elif fidx == 2:
				grid = SANTELMO_DEATH_2
				oy = 27
			elif fidx == 3:
				grid = SANTELMO_DEATH_3
				oy = 30
			else:
				# Último frame: apenas cinzas tênues
				_draw_ellipse_alpha(img, 24, 36, 7.0, 2.0, Color(0.24, 0.20, 0.22, 0.72))
				_set_px(img, 22, 35, pal["D"])
				_set_px(img, 26, 36, pal["S"])
				return img

	# Sombra quente de brasa no chão em y=38
	var glow_alpha := 0.26 if kind != "hurt" else 0.14
	var floor_col := Color(0.85, 0.16, 0.25, glow_alpha) if distorted else Color(0.95, 0.45, 0.15, glow_alpha)
	_draw_ellipse_alpha(img, 24, 38, 8.0, 2.5, floor_col)

	_blit_grid(img, ox, oy + bob, grid, pal)
	_apply_dark_outline(img, eye_line)

	# Fagulhas soltas orbitando / subindo orgânicas
	if kind in ["idle", "move"]:
		var sp_x1 := 14 + ((fidx * 3) % 5)
		var sp_y1 := 12 - (fidx % 3) * 2
		var sp_x2 := 31 - ((fidx * 2) % 4)
		var sp_y2 := 15 - ((fidx + 1) % 3) * 2
		_set_px(img, sp_x1, sp_y1, pal["B"])
		_set_px(img, sp_x2, sp_y2, pal["C"])
		if kind == "move":
			_set_px(img, 36, 18 + (fidx % 2), pal["D"])
			_set_px(img, 38, 16 - (fidx % 2), pal["M"])
	elif kind == "attack" and (fidx == 1 or fidx == 2):
		for pt in [Vector2i(9, 14), Vector2i(38, 13), Vector2i(11, 29), Vector2i(36, 28)]:
			_set_px(img, pt.x + (1 if fidx == 2 else 0), pt.y, pal["C"])

	return img


static func build_santelmo() -> Dictionary:
	var dir_path := OUT_CREATURES + "/santelmo"
	_ensure_dir(dir_path)
	var out_dict := {}
	for variant in ["normal", "distorted"]:
		var is_dist: bool = (variant == "distorted")
		var anims: Array[Dictionary] = []
		var spec_defs := [
			{"name": "idle", "count": 4, "fps": 7.5, "loop": true},
			{"name": "move", "count": 4, "fps": 9.0, "loop": true},
			{"name": "attack", "count": 4, "fps": 12.0, "loop": false},
			{"name": "hurt", "count": 3, "fps": 10.0, "loop": false},
			{"name": "death", "count": 5, "fps": 8.0, "loop": false},
		]
		var preview_frames: Array[Image] = []
		for sd in spec_defs:
			var imgs: Array[Image] = []
			var texs: Array = []
			for f in range(sd["count"]):
				var im := _render_santelmo_frame(sd["name"], f, is_dist)
				imgs.append(im)
				texs.append(_save_tex(im, "%s/%s_%s_%d.png" % [dir_path, variant, sd["name"], f]))
				if f == 0 or (sd["name"] == "attack" and f == 1):
					preview_frames.append(im)
			_save_sheet(imgs, "%s/santelmo_%s_%s.png" % [dir_path, variant, sd["name"]])
			anims.append({"name": sd["name"], "fps": sd["fps"], "loop": sd["loop"], "frames": texs})
		var sf := _make_spriteframes(anims)
		var sf_path := "%s/santelmo_%s_spriteframes.tres" % [dir_path, variant]
		ResourceSaver.save(sf, sf_path)
		out_dict[variant] = preview_frames
		out_dict[variant + "_tres"] = sf_path
	return out_dict


# ===========================================================================
# 2. GUARDIÃ DA LAGOA (Diwata Bioluminescente das Águas — 48x48 orgânica)
# ===========================================================================

static func _guardian_palette(mode: String) -> Dictionary:
	var hurt := (mode == "hurt")
	var hostile := (mode == "hostile")
	if hurt:
		return {
			"O": Color("#143B4D"),
			"D": Color("#2E7CA3"),
			"M": Color("#5DC0EB"),
			"H": Color("#A9ECFF"),
			"F": Color("#E0FAFF"),
			"W": Color("#FFFFFF"),
			"E": Color("#FFF8C4"),
			"R": Color("#75D8F5"),
		}
	if hostile:
		return {
			"O": Color("#0B1F2E"),
			"D": Color("#143D54"),
			"M": Color("#227594"),
			"H": Color("#4AD9D2"),
			"F": Color("#9FFAF0"),
			"W": Color("#EBFFFD"),
			"E": Color("#FFD645"),
			"R": Color("#38A5C4"),
		}
	return {
		"O": Color("#0C2430"),
		"D": Color("#174C5E"),
		"M": Color("#298696"),
		"H": Color("#56D4C8"),
		"F": Color("#A6FAF0"),
		"W": Color("#EAFFFC"),
		"E": Color("#FFE688"),
		"R": Color("#3CA2B8"),
	}


const GUARDIAN_IDLE_BODY: PackedStringArray = [
	".............FF.............",
	"............FWWF............",
	"............FHHF............",
	"...FF......DHHHHM......FF...",
	"..FWHF....DMHHHHMD....FHWF..",
	".FWHHHFD.DMHHHHHHMD.DFHHHWF.",
	".FHMMHHHDMHHWWWWWHMDHHHMMHF.",
	".FHMDDHHMHHWEMMMEWHHMHDDMHF.",
	"..FD.DMHMHHWEHMHEWHHMHMD.DF.",
	"......DDMMHHHHHHHHMMDD......",
	"........DDMHHHHHHMDD........",
	".........DMHHHHHHMD.........",
	"........DDMHHHHHHMDD........",
	".......DMHHMHHHHMHHMD.......",
	"......DMHHMMHHHHMMHHMD......",
	"......DMHDDMHHHHMDDHMD......",
	".....DMHD.DDMHHMDD.DHMD.....",
	".....DFD...DMHHMD...DFD.....",
	"..........DDMHHMDD..........",
	".........DDMMHHMMDD.........",
	"........DDMMHHHHMMDD........",
	".......DDMMHHWWWHMMDD.......",
	"......DDMMMHHHHHHMMMDD......",
	".....DDMMMMMHHHHMMMMMDD.....",
	"....RRRRRRRRRRRRRRRRRRRR....",
]

const GUARDIAN_CALM_BODY: PackedStringArray = [
	".............FF.............",
	"............FWWF............",
	"............FHHF............",
	"...FF......DHHHHM......FF...",
	"..FWHF....DMHHHHMD....FHWF..",
	".FWHHHFD.DMHHHHHHMD.DFHHHWF.",
	".FHMMHHHDMHHWWWWWHMDHHHMMHF.",
	".FHMDDHHMHHWEMMMEWHHMHDDMHF.",
	"..FD.DMHMHHWEHMHEWHHMHMD.DF.",
	"......DDMMHHHHHHHHMMDD......",
	"........DDMHHHHHHMDD........",
	"......WW.DMHHHHHHMD.WW......",
	".....FWFDMMHHHHHHMMDWF......",
	"....FHHHDMHHHHHHHHMDHHHF....",
	"...FHD..DMHMHHHHMHMMD..DHF..",
	"...FD....DMHMHHMHMDD....DF..",
	"..........DDMHHMDD..........",
	".........DDMMHHMMDD.........",
	"........DDMMHHHHMMDD........",
	".......DDMMHHWWWHMMDD.......",
	"......DDMMMHHHHHHMMMDD......",
	".....DDMMMMMHHHHMMMMMDD.....",
	"....RRRRRRRRRRRRRRRRRRRR....",
]

const GUARDIAN_HOSTILE_BODY: PackedStringArray = [
	"....F........WW........F....",
	"...FHF......FHHF......FHF...",
	"..FWHHF....DHHHHM....FHHWF..",
	".FWHMMHFD.DMHHHHMD.DFHMMHWF.",
	".FHMMMHHHDMHHHHHHMDHHHMMMHF.",
	".FHDDMHHHMHHWWWWWHHMHHMDDHF.",
	"..FF.DMHMHHWEMMMEWHHMHMD.FF.",
	"......DDMMHHEHMEHHMMDD......",
	"...WW...DDMMHHHHMMDD...WW...",
	"..FWWF...DDMHHHHMDD...FWWF..",
	".FHHHF..DDMHHHHHHMDD..FHHHF.",
	".FHD...DMHHMHHHHMHHMD...DHF.",
	".......DMHDDDMHMDDDHMD......",
	"......DMHD..DMHMD..DHMD.....",
	"......DFD..DDMHMMDD.DFD.....",
	"..........DDMMHHMMDD........",
	".........DDMMHHHHMMDD.......",
	"........DDMMHHWWWHMMDD......",
	"......WWWMMMHHHHHHMMMWWW....",
	"....WWWWMMMMHHHHHHMMMMWWWW..",
	"...RRRRRRRRRRRRRRRRRRRRRRRR.",
]


static func _render_guardian_frame(mode: String, fidx: int) -> Image:
	var img := Image.create(48, 48, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var pal := _guardian_palette(mode)

	var ox: int = 10
	var oy: int = 11
	var bob_arr: Array[int] = [0, -1, 0, 1]
	var bob: int = bob_arr[fidx % 4]
	var grid: PackedStringArray = GUARDIAN_IDLE_BODY

	if mode == "calm":
		grid = GUARDIAN_CALM_BODY
		oy = 12
	elif mode == "hostile":
		grid = GUARDIAN_HOSTILE_BODY
		oy = 12
		var hb: Array[int] = [-1, 0, -2, 0]
		bob = hb[fidx % 4]
	elif mode == "hurt":
		grid = GUARDIAN_HOSTILE_BODY
		var hx: Array[int] = [-2, 2, -1]
		ox = 10 + hx[fidx % 3]
		oy = 13
		bob = 0

	# Anéis concêntricos de água sobre a lagoa em y=38
	var ripple_w := 14.0 + float((fidx % 2) * 2)
	_draw_ellipse_alpha(img, 24, 39, ripple_w + 3.0, 4.0, Color(0.14, 0.46, 0.56, 0.55))
	_draw_ellipse_alpha(img, 24, 38, ripple_w, 3.0, Color(0.38, 0.85, 0.88, 0.72))

	_blit_grid(img, ox, oy + bob, grid, pal)
	_apply_dark_outline(img, pal["O"])

	# Gotículas orbitais luminosas em calma / espuma agitada em hostil
	if mode == "calm":
		var pts := [Vector2i(8, 22), Vector2i(39, 22), Vector2i(11, 14), Vector2i(36, 14)]
		for idx in range(pts.size()):
			var p: Vector2i = pts[idx]
			var dy := -((fidx + idx) % 3)
			_set_px(img, p.x, p.y + dy, pal["F"])
			_set_px(img, p.x, p.y + dy - 1, pal["W"])
	elif mode == "hostile":
		for wx in [7, 13, 34, 40]:
			_set_px(img, wx, 34 - (fidx % 3), pal["W"])
			_set_px(img, wx + 1, 33 - ((fidx + 1) % 3), pal["F"])

	return img


static func build_guardian() -> Dictionary:
	var dir_path := OUT_CREATURES + "/aquatic_creature"
	_ensure_dir(dir_path)
	var anims: Array[Dictionary] = []
	var spec_defs := [
		{"name": "idle", "mode": "idle", "count": 4, "fps": 5.0, "loop": true},
		{"name": "calm", "mode": "calm", "count": 4, "fps": 6.0, "loop": true},
		{"name": "hostile", "mode": "hostile", "count": 4, "fps": 8.0, "loop": true},
		{"name": "hurt", "mode": "hurt", "count": 3, "fps": 10.0, "loop": false},
	]
	var previews: Array[Image] = []
	for sd in spec_defs:
		var imgs: Array[Image] = []
		var texs: Array = []
		for f in range(sd["count"]):
			var im := _render_guardian_frame(sd["mode"], f)
			imgs.append(im)
			texs.append(_save_tex(im, "%s/guardian_%s_%d.png" % [dir_path, sd["name"], f]))
			if f == 0:
				previews.append(im)
		_save_sheet(imgs, "%s/guardian_%s.png" % [dir_path, sd["name"]])
		anims.append({"name": sd["name"], "fps": sd["fps"], "loop": sd["loop"], "frames": texs})

	var sf := _make_spriteframes(anims)
	var sf_path := dir_path + "/aquatic_creature_spriteframes.tres"
	ResourceSaver.save(sf, sf_path)
	return {"previews": previews, "tres": sf_path}


# ===========================================================================
# 3. GATOS — PUSA (Quarto do Huwag) & GATINHO (Clareira / Luningning) — 32x32
# ===========================================================================

static func _pusa_palette(distorted: bool) -> Dictionary:
	if distorted:
		return {
			"O": Color("#050408"),
			"D": Color("#0E0C16"),
			"M": Color("#1A1728"),
			"H": Color("#2E2942"),
			"C": Color("#46425C"),
			"P": Color("#8A2E44"),
			"E": Color("#FF4A5A"),
			"G": Color("#FFF0F2"),
		}
	return {
		"O": Color("#12131A"),
		"D": Color("#232533"),
		"M": Color("#363A4E"),
		"H": Color("#555B75"),
		"C": Color("#EAE3D3"),
		"P": Color("#DF8D98"),
		"E": Color("#F2C94C"),
		"G": Color("#FFF9DB"),
	}


const PUSA_IDLE_0: PackedStringArray = [
	"...MM.......MM.....",
	"..MPM......MPM.....",
	"..MMMMDDDDMMMM.....",
	".DMHHHHHHHHHHMD....",
	".DMHGEHMMMHEGHMD...",
	".DMHEEHMPMHEEHMD...",
	"..DMHHCCCCCHHMD....",
	"...DDMCCCCCMDD.....",
	"..DDMMCCCCCMMDD..MM",
	".DMHHHCCCCCHHHMDMMD",
	".DMHHHHCCCHHHHMDMD.",
	".DMHHHHHHHHHHHMMDD.",
	"..DMHHDDDDDHHMMDD..",
	"..DMCCMD.DMCCMD....",
	"..DDDDD...DDDDD....",
]

const PUSA_IDLE_1: PackedStringArray = [
	"...MM.......MM.....",
	"..MPM......MPM.....",
	"..MMMMDDDDMMMM.....",
	".DMHHHHHHHHHHMD....",
	".DMHGEHMMMHEGHMD...",
	".DMHEEHMPMHEEHMD...",
	"..DMHHCCCCCHHMD....",
	"...DDMCCCCCMDD.....",
	"..DDMMCCCCCMMDD.MM.",
	".DMHHHCCCCCHHHMDMM.",
	".DMHHHHCCCHHHHMDM..",
	".DMHHHHHHHHHHHMMD..",
	"..DMHHDDDDDHHMMD...",
	"..DMCCMD.DMCCMD....",
	"..DDDDD...DDDDD....",
]

const PUSA_BLINK_GRID: PackedStringArray = [
	"...MM.......MM.....",
	"..MPM......MPM.....",
	"..MMMMDDDDMMMM.....",
	".DMHHHHHHHHHHMD....",
	".DMHHHHHHHHHHHMD...",
	".DMDDDHMPMHHHDDD...",
	"..DMHHCCCCCHHMD....",
	"...DDMCCCCCMDD.....",
	"..DDMMCCCCCMMDDMM..",
	".DMHHHCCCCCHHHMMM..",
	".DMHHHHCCCHHHHMD...",
	".DMHHHHHHHHHHHMD...",
	"..DMHHDDDDDHHMD....",
	"..DMCCMD.DMCCMD....",
	"..DDDDD...DDDDD....",
]

const PUSA_DISTORTED_GRID: PackedStringArray = [
	"..MMM.......MMM....",
	"..MPM..M.M..MPM....",
	"..MMMMDDDDMMMM.....",
	".DMHHHHHHHHHHMD....",
	"MDMHGEMMMMEGHMDM...",
	".DMHEEHMPMHEEHMD...",
	"..DMHHCCCCCHHMD....",
	"...DDMCCCCCMDD.....",
	".MDDMMCCCCCMMDD..M.",
	".DMHHHCCCCCHHHMDMM.",
	"MDMHHHHCCCHHHHMDMD.",
	".DMHHHHHHHHHHHMMDD.",
	"..DMHHDDDDDHHMMDD..",
	"..DMCCMD.DMCCMD....",
	"..DDDDD...DDDDD....",
]


static func _render_pusa_frame(anim: String, fidx: int, distorted: bool) -> Image:
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var pal := _pusa_palette(distorted)

	_draw_ellipse_alpha(img, 16, 26, 9.0, 3.0, Color(0, 0, 0, 0.32))
	var grid := PUSA_IDLE_0 if (fidx % 2 == 0) else PUSA_IDLE_1
	if distorted:
		grid = PUSA_DISTORTED_GRID
	elif anim == "blink" and (fidx == 1 or fidx == 2):
		grid = PUSA_BLINK_GRID

	var by := 12 + (1 if (not distorted and anim == "idle" and fidx == 2) else 0)
	_blit_grid(img, 7, by, grid, pal)
	_apply_dark_outline(img, pal["O"])
	return img


static func build_pusa() -> Dictionary:
	var dir_path := OUT_CATS + "/pusa"
	_ensure_dir(dir_path)
	var out := {}
	for variant in ["normal", "distorted"]:
		var is_dist: bool = (variant == "distorted")
		var anims: Array[Dictionary] = []
		var defs := [
			{"name": "idle", "count": 4, "fps": 4.5, "loop": true},
			{"name": "blink", "count": 4, "fps": 5.0, "loop": true},
		]
		var preview: Image = null
		for sd in defs:
			var imgs: Array[Image] = []
			var texs: Array = []
			for f in range(sd["count"]):
				var im := _render_pusa_frame(sd["name"], f, is_dist)
				imgs.append(im)
				texs.append(_save_tex(im, "%s/%s_%s_%d.png" % [dir_path, variant, sd["name"], f]))
				if preview == null and sd["name"] == "idle":
					preview = im
			_save_sheet(imgs, "%s/pusa_%s_%s.png" % [dir_path, variant, sd["name"]])
			anims.append({"name": sd["name"], "fps": sd["fps"], "loop": sd["loop"], "frames": texs})
		var sf := _make_spriteframes(anims)
		var sf_path := "%s/pusa_%s_spriteframes.tres" % [dir_path, variant]
		ResourceSaver.save(sf, sf_path)
		out[variant] = preview
		out[variant + "_tres"] = sf_path
	return out


static func _gatinho_palette() -> Dictionary:
	return {
		"O": Color("#38190B"),
		"S": Color("#9E4216"),
		"D": Color("#C45E1E"),
		"M": Color("#E67E2E"),
		"H": Color("#F7AD54"),
		"C": Color("#FDE4B8"),
		"P": Color("#EB8896"),
		"E": Color("#4EA854"),
		"G": Color("#FFFFFF"),
	}


const GATINHO_SHIVER_0: PackedStringArray = [
	"..SM.....MS...",
	".SMPM...MPMS..",
	".SMMMSSSMMMS..",
	".MHHSHMSHSHM..",
	".MHGEHMHMEGHM.",
	".MHEEHMMPHEEM.",
	"..MHCCCCCCCM..",
	"..DMCCCCCCMD.M",
	".DMHHCCCHHHMMM",
	".DMSSHHSHHHMM.",
	".DMCCCCCCCCM..",
	"..MCCM..MCCM..",
	"..SSSS..SSSS..",
]

const GATINHO_MEOW_GRID: PackedStringArray = [
	"..SM.....MS...",
	".SMPM...MPMS..",
	".SMMMSSSMMMS..",
	".MHHSHMSHSHM..",
	".MHGEHMHMEGHM.",
	".MHEEHMPPHEEM.",
	"..MHCCPPCCCM..",
	"..DMCCCCCCMD.M",
	".DMHHCCCHHHMMM",
	".DMSSHHSHHHMM.",
	".DMCCCCCCCCM..",
	"..MCCM..MCCM..",
	"..SSSS..SSSS..",
]

const GATINHO_SAFE_GRID: PackedStringArray = [
	"..SM.....MS...",
	".SMPM...MPMS..",
	".SMMMSSSMMMS..",
	".MHHSHMSHSHM..",
	".MHSSEHMHESSM.",
	"..MHCCCCCCCM..",
	"..MMCCCCCCMM..",
	".DMHHCCCHHHMM.",
	".DMSSHHSHHHMMM",
	".DMHHHHHHHHMMM",
	"..DMCCCCCCMM..",
	"...SSSSSSSS...",
]


static func _render_gatinho_frame(anim: String, fidx: int) -> Image:
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var pal := _gatinho_palette()

	_draw_ellipse_alpha(img, 16, 26, 7.0, 2.5, Color(0, 0, 0, 0.30))
	var ox: int = 9
	var oy: int = 14
	var grid: PackedStringArray = GATINHO_SHIVER_0

	if anim == "idle":
		var shv: Array[int] = [0, -1, 0, 1]
		ox = 9 + shv[fidx % 4]
	elif anim == "meow":
		grid = GATINHO_MEOW_GRID if (fidx in [1, 2]) else GATINHO_SHIVER_0
		oy = 14 - (1 if fidx in [1, 2] else 0)
	elif anim == "safe":
		grid = GATINHO_SAFE_GRID
		oy = 15 + (1 if fidx == 2 else 0)

	_blit_grid(img, ox, oy, grid, pal)
	_apply_dark_outline(img, pal["O"])
	if anim == "meow" and fidx in [1, 2]:
		# Pequeno brilho de miado de pedido de socorro acima da orelha
		_set_px(img, 24, 9, Color("#FFF3B0"))
		_set_px(img, 24, 10, Color("#FFF3B0"))
		_set_px(img, 24, 12, Color("#F5CB5C"))
	return img


static func build_gatinho() -> Dictionary:
	var dir_path := OUT_CATS + "/gatinho"
	_ensure_dir(dir_path)
	var anims: Array[Dictionary] = []
	var defs := [
		{"name": "idle", "count": 4, "fps": 6.0, "loop": true},
		{"name": "meow", "count": 4, "fps": 5.5, "loop": true},
		{"name": "safe", "count": 4, "fps": 4.0, "loop": true},
	]
	var previews: Array[Image] = []
	for sd in defs:
		var imgs: Array[Image] = []
		var texs: Array = []
		for f in range(sd["count"]):
			var im := _render_gatinho_frame(sd["name"], f)
			imgs.append(im)
			texs.append(_save_tex(im, "%s/gatinho_%s_%d.png" % [dir_path, sd["name"], f]))
			if f == 0 or (sd["name"] == "meow" and f == 1):
				previews.append(im)
		_save_sheet(imgs, "%s/gatinho_%s.png" % [dir_path, sd["name"]])
		anims.append({"name": sd["name"], "fps": sd["fps"], "loop": sd["loop"], "frames": texs})
	var sf := _make_spriteframes(anims)
	var sf_path := dir_path + "/gatinho_spriteframes.tres"
	ResourceSaver.save(sf, sf_path)
	return {"previews": previews, "tres": sf_path}
