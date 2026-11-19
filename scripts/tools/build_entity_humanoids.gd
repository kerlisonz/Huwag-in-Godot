@tool
extends SceneTree

## Gerador de spritesheets pixel art 16-bit (48x48, 4 direções) para entidades humanoides:
## 1) Sant'Elmon Humanoide (espectro de vestes chamuscadas com chamas azul/âmbar)
## 2) Guardiã da Lagoa Humanoide (entidade anfíbia abissal com algas, guelras e escamas)
## Gera animações: idle, walk, run, attack1, attack2, hurt, death nas 4 direções (_down/_up/_left/_right)
## e salva .tres SpriteFrames + folhas PNG individuais + prancha de inspeção no scratch.

const CELL := 48
const DIRS := ["down", "up", "left", "right"]
const SCRATCH_DIR := "C:/Users/SnyX/.gemini/antigravity/brain/57f4ed94-3583-41fc-bbbe-9e9a2d546794/scratch"

func _init() -> void:
	DirAccess.make_dir_recursive_absolute(SCRATCH_DIR)
	_build_santelmo_humanoid()
	_build_lagoon_guardian_humanoid()
	quit(0)


func _new_cell() -> Image:
	var im := Image.create(CELL, CELL, false, Image.FORMAT_RGBA8)
	im.fill(Color(0, 0, 0, 0))
	return im


func _px(im: Image, x: int, y: int, col: Color) -> void:
	if x >= 0 and x < CELL and y >= 0 and y < CELL:
		im.set_pixel(x, y, col)


func _rect(im: Image, x0: int, y0: int, w: int, h: int, col: Color) -> void:
	for y in range(maxi(0, y0), mini(CELL, y0 + h)):
		for x in range(maxi(0, x0), mini(CELL, x0 + w)):
			im.set_pixel(x, y, col)


func _ellipse(im: Image, cx: float, cy: float, rx: float, ry: float, col: Color) -> void:
	for y in range(maxi(0, int(floor(cy - ry))), mini(CELL, int(ceil(cy + ry)) + 1)):
		for x in range(maxi(0, int(floor(cx - rx))), mini(CELL, int(ceil(cx + rx)) + 1)):
			var dx := (float(x) - cx) / maxf(0.5, rx)
			var dy := (float(y) - cy) / maxf(0.5, ry)
			if dx * dx + dy * dy <= 1.0:
				im.set_pixel(x, y, col)


func _outline(im: Image, out_col: Color) -> Image:
	var copy: Image = im.duplicate() as Image
	for y in range(1, CELL - 1):
		for x in range(1, CELL - 1):
			if im.get_pixel(x, y).a > 0.15:
				continue
			var adj := (
				im.get_pixel(x - 1, y).a > 0.25 or im.get_pixel(x + 1, y).a > 0.25
				or im.get_pixel(x, y - 1).a > 0.25 or im.get_pixel(x, y + 1).a > 0.25
			)
			if adj:
				copy.set_pixel(x, y, out_col)
	return copy


func _draw_slash_arc(im: Image, dir_name: String, phase: int, col_hi: Color, col_mid: Color, col_deep: Color, is_heavy: bool = false) -> void:
	var reach := (3 if is_heavy else 0) + (1 if phase == 2 else 0)
	match dir_name:
		"down":
			var by := 37 + reach
			for dx in range(-11, 12):
				var cy := by - int(absf(float(dx)) * 0.34)
				_px(im, 24 + dx, cy, col_hi)
				_px(im, 24 + dx, cy - 1, col_mid)
				if abs(dx) < 8:
					_px(im, 24 + dx, cy - 2, col_deep)
		"up":
			var by := 11 - reach
			for dx in range(-11, 12):
				var cy := by + int(absf(float(dx)) * 0.34)
				_px(im, 24 + dx, cy, col_hi)
				_px(im, 24 + dx, cy + 1, col_mid)
				if abs(dx) < 8:
					_px(im, 24 + dx, cy + 2, col_deep)
		"left":
			var bx := 11 - reach
			for dy in range(-10, 11):
				var cx := bx + int(absf(float(dy)) * 0.36)
				_px(im, cx, 26 + dy, col_hi)
				_px(im, cx + 1, 26 + dy, col_mid)
				if abs(dy) < 7:
					_px(im, cx + 2, 26 + dy, col_deep)
		"right":
			var bx := 37 + reach
			for dy in range(-10, 11):
				var cx := bx - int(absf(float(dy)) * 0.36)
				_px(im, cx, 26 + dy, col_hi)
				_px(im, cx - 1, 26 + dy, col_mid)
				if abs(dy) < 7:
					_px(im, cx - 2, 26 + dy, col_deep)


func _save_sheet_and_frames(
	out_dir: String,
	sf_path: String,
	preview_name: String,
	anims: Array[Dictionary]
) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out_dir))
	var sf := SpriteFrames.new()
	var preview := Image.create(CELL * 8, CELL * 4, false, Image.FORMAT_RGBA8)
	preview.fill(Color("#161A24"))

	for anim_def in anims:
		var aname: String = anim_def["name"]
		var fps: float = float(anim_def["fps"])
		var loop: bool = bool(anim_def["loop"])
		var cols: int = int(anim_def["cols"])
		var sheet := Image.create(CELL * cols, CELL * 4, false, Image.FORMAT_RGBA8)
		sheet.fill(Color(0, 0, 0, 0))
		var builder: Callable = anim_def["builder"]

		for d_idx in range(4):
			var d_name: String = DIRS[d_idx]
			var full_anim := "%s_%s" % [aname, d_name]
			if not sf.has_animation(full_anim):
				sf.add_animation(full_anim)
			sf.set_animation_speed(full_anim, fps)
			sf.set_animation_loop(full_anim, loop)
			for c in range(cols):
				var cell_im: Image = builder.call(d_name, c)
				sheet.blit_rect(cell_im, Rect2i(0, 0, CELL, CELL), Vector2i(c * CELL, d_idx * CELL))

		var png_path := "%s/%s.png" % [out_dir, anim_def["file"]]
		sheet.save_png(png_path)
		var loaded_tex: Texture2D = ResourceLoader.load(png_path, "", ResourceLoader.CACHE_MODE_REPLACE) as Texture2D
		if loaded_tex == null:
			loaded_tex = ImageTexture.create_from_image(sheet)

		for d_idx in range(4):
			var full_anim := "%s_%s" % [aname, DIRS[d_idx]]
			for c in range(cols):
				var atlas := AtlasTexture.new()
				atlas.atlas = loaded_tex
				atlas.region = Rect2(c * CELL, d_idx * CELL, CELL, CELL)
				sf.add_frame(full_anim, atlas)

		# Preenche prancha de inspeção (col por animação)
		var p_col := -1
		match aname:
			"idle": p_col = 0
			"walk": p_col = 1
			"run": p_col = 2
			"attack1": p_col = 3
			"attack2": p_col = 5
			"hurt": p_col = 6
			"death": p_col = 7
		if p_col >= 0:
			var sample_f := 1 if cols > 1 else 0
			for r in range(4):
				preview.blend_rect(sheet, Rect2i(sample_f * CELL, r * CELL, CELL, CELL), Vector2i(p_col * CELL, r * CELL))
				if aname == "attack1":
					preview.blend_rect(sheet, Rect2i(mini(2, cols - 1) * CELL, r * CELL, CELL, CELL), Vector2i(4 * CELL, r * CELL))

	ResourceSaver.save(sf, sf_path)
	var up := Image.create(preview.get_width() * 4, preview.get_height() * 4, false, Image.FORMAT_RGBA8)
	for py in range(preview.get_height()):
		for px in range(preview.get_width()):
			var col := preview.get_pixel(px, py)
			for dy in range(4):
				for dx in range(4):
					up.set_pixel(px * 4 + dx, py * 4 + dy, col)
	up.save_png("%s/%s" % [SCRATCH_DIR, preview_name])
	print("  [EntityHumanoid] Salvo %s + %s" % [sf_path, preview_name])


# ==============================================================================
# 1. SANT'ELMON HUMANOIDE (Espectro de vestes chamuscadas com chamas azul/âmbar)
# ==============================================================================
func _draw_santelmo_pose(
	dir_name: String,
	bob_y: int,
	step_x: int,
	lunge: Vector2i,
	arm_mode: String,
	flame_phase: int,
	fade: float = 1.0,
	flash: bool = false,
	collapse_y: int = 0
) -> Image:
	var im := _new_cell()
	var cx := 24 + lunge.x
	var cy_off := bob_y + lunge.y + collapse_y

	var outline := Color("#120A10")
	var coat_dk := Color("#1E1820")
	var coat_md := Color("#32252B")
	var coat_hi := Color("#4B363C")
	var ember_glow := Color("#E8590C")
	var flame_out := Color("#FF7A18")
	var flame_mid := Color("#FFBF36")
	var flame_blue := Color("#47D4FF")
	var flame_core := Color("#FFFBE6")

	if flash:
		coat_dk = Color("#6A5860")
		coat_md = Color("#B0969E")
		coat_hi = Color("#E8DDE2")

	# Pernas e barra da túnica chamuscada (deslocamento orgânico por passo)
	if collapse_y < 8:
		var l_leg_y := 34 + cy_off - maxi(0, -step_x)
		var r_leg_y := 34 + cy_off - maxi(0, step_x)
		if dir_name in ["down", "up"]:
			_rect(im, cx - 5, 31 + cy_off, 4, mini(7, 39 - (31 + cy_off)), coat_dk)
			_rect(im, cx + 1, 31 + cy_off, 4, mini(7, 39 - (31 + cy_off)), coat_dk)
			_px(im, cx - 4, l_leg_y + 3, ember_glow)
			_px(im, cx + 2, r_leg_y + 3, ember_glow)
		else:
			_rect(im, cx - 3 + step_x, 31 + cy_off, 4, 7, coat_dk)
			_rect(im, cx - 1 - step_x, 32 + cy_off, 4, 6, coat_md)

	# Tronco e casaco chamuscado esfarrapado
	var torso_w := 14 if dir_name in ["down", "up"] else 10
	var torso_h := maxi(4, 15 - int(collapse_y * 0.6))
	_ellipse(im, float(cx), float(24 + cy_off), float(torso_w) * 0.52, float(torso_h) * 0.55, coat_dk)
	_ellipse(im, float(cx), float(23 + cy_off), float(torso_w) * 0.42, float(torso_h) * 0.44, coat_md)
	if dir_name == "down":
		# Peito em brasa sob a vestimenta aberta
		_rect(im, cx - 2, 19 + cy_off, 4, 7, flame_out)
		_rect(im, cx - 1, 20 + cy_off, 2, 4, flame_blue)
		_px(im, cx, 21 + cy_off, flame_core)
	elif dir_name in ["left", "right"]:
		var sd := -1 if dir_name == "left" else 1
		_rect(im, cx + sd * 2, 20 + cy_off, 2, 6, ember_glow)

	# Pontas esfarrapadas da barra com brasas e cauda do casaco
	for tx in [-6, -3, 0, 3, 6]:
		var tail_len := 2 + ((absi(tx) + flame_phase) % 2)
		_rect(im, cx + tx, 30 + cy_off, 2, tail_len, coat_dk)
		_px(im, cx + tx, 31 + cy_off + (tx + flame_phase) % 2, coat_hi)
		if (tx + flame_phase) % 2 == 0:
			_px(im, cx + tx, 31 + tail_len + cy_off, ember_glow)

	# Ombros conectados e braços/mãos flamejantes
	var sh_x := 6 if dir_name in ["down", "up"] else 3
	var l_arm := Vector2i(cx - sh_x, 20 + cy_off)
	var r_arm := Vector2i(cx + sh_x, 20 + cy_off)
	if arm_mode == "cast":
		l_arm += Vector2i(-2 if dir_name == "down" else (-3 if dir_name == "left" else 1), -3)
		r_arm += Vector2i(2 if dir_name == "down" else (-1 if dir_name == "left" else 3), -3)
	elif arm_mode == "swing":
		l_arm += Vector2i(1, 2)
		r_arm += Vector2i(2 if dir_name != "left" else -2, 1)
	elif arm_mode == "windup":
		l_arm += Vector2i(-1, -2)
		r_arm += Vector2i(1, -3)

	var l_sh := Vector2i(cx - 4 if dir_name in ["down", "up"] else cx - 1, 20 + cy_off)
	var r_sh := Vector2i(cx + 4 if dir_name in ["down", "up"] else cx + 1, 20 + cy_off)
	for pair in [[l_sh, l_arm], [r_sh, r_arm]]:
		var sh: Vector2i = pair[0]
		var ap: Vector2i = pair[1]
		for t in range(5):
			var px_s := int(roundf(lerpf(float(sh.x), float(ap.x), float(t) / 4.0)))
			var py_s := int(roundf(lerpf(float(sh.y), float(ap.y + 1), float(t) / 4.0)))
			_ellipse(im, float(px_s), float(py_s), 2.1, 2.0, coat_md)
		_ellipse(im, float(ap.x), float(ap.y + 3), 2.1, 3.3, coat_md)
		_ellipse(im, float(ap.x), float(ap.y + 5), 1.8, 1.8, flame_out)
		_px(im, ap.x, ap.y + 5, flame_mid)
		_px(im, ap.x, ap.y + 6, flame_blue)

	# Cabeça humanoide espectral + coroa de chamas azul-âmbar
	var hy := 13 + cy_off + int(collapse_y * 0.25)
	_ellipse(im, float(cx), float(hy), 5.6, 5.2, coat_dk)
	# Chamas subindo da cabeça com núcleo azul elétrico e línguas âmbar
	for f_idx in range(-4, 5):
		var h_flame: int = 4 + (absi(f_idx * 3 + flame_phase) % 4) - int(absi(f_idx) / 2)
		for fy in range(1, h_flame + 1):
			var py := hy - 3 - fy
			var fx := cx + f_idx + ((flame_phase + fy) % 2 - 0 if f_idx % 2 == 0 else 0)
			var fcol := flame_blue if (abs(f_idx) <= 1 and fy <= 3) else (flame_mid if fy <= 4 else flame_out)
			_px(im, fx, py, fcol)
	_px(im, cx, hy - 5, flame_core)

	# Rosto sombreado com olhos incandescentes azul/branco
	if dir_name == "down":
		_rect(im, cx - 3, hy - 1, 2, 2, flame_blue)
		_rect(im, cx + 1, hy - 1, 2, 2, flame_blue)
		_px(im, cx - 2, hy, flame_core)
		_px(im, cx + 2, hy, flame_core)
	elif dir_name == "left":
		_rect(im, cx - 4, hy - 1, 2, 2, flame_blue)
		_px(im, cx - 4, hy, flame_core)
	elif dir_name == "right":
		_rect(im, cx + 2, hy - 1, 2, 2, flame_blue)
		_px(im, cx + 3, hy, flame_core)

	# Se for ataque1 (garra flamejante) ou ataque2 (orbe de fogo concentrado)
	if arm_mode == "orb":
		var orb_pos := Vector2i(cx, hy + 4)
		match dir_name:
			"down": orb_pos = Vector2i(cx, 31 + cy_off)
			"up": orb_pos = Vector2i(cx, 12 + cy_off)
			"left": orb_pos = Vector2i(cx - 10, 23 + cy_off)
			"right": orb_pos = Vector2i(cx + 10, 23 + cy_off)
		_ellipse(im, float(orb_pos.x), float(orb_pos.y), 4.5, 4.5, flame_out)
		_ellipse(im, float(orb_pos.x), float(orb_pos.y), 3.0, 3.0, flame_blue)
		_px(im, orb_pos.x, orb_pos.y, flame_core)

	im = _outline(im, outline)
	if fade < 0.99:
		for y in range(CELL):
			for x in range(CELL):
				var c := im.get_pixel(x, y)
				if c.a > 0.0:
					c.a *= fade
					im.set_pixel(x, y, c)
	return im


func _se_frame(d: String, f: int, aname: String) -> Image:
	var l := Vector2i(-1 if d == "left" else (1 if d == "right" else 0), 1 if d == "down" else (-1 if d == "up" else 0))
	match aname:
		"idle":
			return _draw_santelmo_pose(d, 1 if f in [1, 2] else 0, 0, Vector2i.ZERO, "idle", f)
		"walk":
			var sx: int = [-1, -2, 0, 1, 2, 0][f]
			var by: int = [0, -1, -1, 0, -1, -1][f]
			return _draw_santelmo_pose(d, by, sx, Vector2i.ZERO, "idle", f)
		"run":
			var sxr: int = [-2, -3, 0, 2, 3, 0][f]
			var lean := Vector2i(-2 if d == "left" else (2 if d == "right" else 0), 1 if d == "down" else (-1 if d == "up" else 0))
			return _draw_santelmo_pose(d, [0, -1, -2, 0, -1, -2][f], sxr, lean, "cast", f)
		"attack1":
			if f == 0:
				return _draw_santelmo_pose(d, 0, 0, -l * 2, "windup", f)
			elif f == 1 or f == 2:
				var im := _draw_santelmo_pose(d, 0, 1, l * 3, "swing", f)
				_draw_slash_arc(im, d, f, Color("#FFF8DC"), Color("#FFA928"), Color("#47D4FF"), false)
				return im
			return _draw_santelmo_pose(d, 0, 0, l, "idle", f)
		"attack2":
			if f <= 1:
				return _draw_santelmo_pose(d, -1, 0, Vector2i.ZERO, "windup", f)
			elif f <= 3:
				return _draw_santelmo_pose(d, 0, 0, l * 2, "orb", f)
			return _draw_santelmo_pose(d, 0, 0, l, "cast", f)
		"hurt":
			var kb := Vector2i(2 if d == "left" else (-2 if d == "right" else 0), -2 if d == "down" else 2)
			return _draw_santelmo_pose(d, 0, 0, kb if f < 2 else Vector2i.ZERO, "idle", f, 1.0, f == 0)
		_:
			var col_y: int = [0, 2, 5, 9, 13, 16][f]
			var fd: float = [1.0, 0.95, 0.85, 0.70, 0.45, 0.18][f]
			var im_d := _draw_santelmo_pose(d, 0, 0, Vector2i.ZERO, "idle", f, fd, false, col_y)
			for e in range(4):
				_px(im_d, 18 + (e * 4 + f * 3) % 13, 28 - f * 3 - e * 2, Color(1.0, 0.65, 0.25, fd))
			return im_d


func _build_santelmo_humanoid() -> void:
	var anims: Array[Dictionary] = [
		{"name": "idle", "file": "spritesheet_idle", "fps": 6.0, "loop": true, "cols": 4, "builder": _se_frame.bind("idle")},
		{"name": "walk", "file": "spritesheet_walk", "fps": 9.0, "loop": true, "cols": 6, "builder": _se_frame.bind("walk")},
		{"name": "run", "file": "spritesheet_run", "fps": 13.0, "loop": true, "cols": 6, "builder": _se_frame.bind("run")},
		{"name": "attack1", "file": "spritesheet_attack1", "fps": 14.0, "loop": false, "cols": 5, "builder": _se_frame.bind("attack1")},
		{"name": "attack2", "file": "spritesheet_attack2", "fps": 12.0, "loop": false, "cols": 5, "builder": _se_frame.bind("attack2")},
		{"name": "hurt", "file": "spritesheet_hurt", "fps": 10.0, "loop": false, "cols": 3, "builder": _se_frame.bind("hurt")},
		{"name": "death", "file": "spritesheet_death", "fps": 8.0, "loop": false, "cols": 6, "builder": _se_frame.bind("death")},
	]
	_save_sheet_and_frames(
		"res://assets/sprites/enemies/santelmo",
		"res://assets/sprites/enemies/santelmo/santelmo_humanoid_spriteframes.tres",
		"preview_santelmo_humanoid_4x.png",
		anims
	)


# ==============================================================================
# 2. GUARDIÃ DA LAGOA HUMANOIDE (Entidade anfíbia abissal c/ algas e guelras)
# ==============================================================================
func _draw_lagoon_pose(
	dir_name: String,
	bob_y: int,
	step_x: int,
	lunge: Vector2i,
	arm_mode: String,
	kelp_phase: int,
	fade: float = 1.0,
	flash: bool = false,
	collapse_y: int = 0
) -> Image:
	var im := _new_cell()
	var cx := 24 + lunge.x
	var cy_off := bob_y + lunge.y + collapse_y

	var outline := Color("#071018")
	var skin_dk := Color("#2B6A70")
	var skin_md := Color("#54A8A6")
	var skin_hi := Color("#8CE0D6")
	var kelp_dk := Color("#122B30")
	var kelp_md := Color("#20494E")
	var kelp_hi := Color("#367070")
	var fin_glow := Color("#80FFF4")
	var eye_glow := Color("#E2FFFF")
	var water_foam := Color("#74D4EC")

	if flash:
		skin_dk = Color("#6A9AA0")
		skin_md = Color("#B6EAE6")
		skin_hi = Color("#F0FFFF")

	# Saia / vestes aquáticas esfarrapadas e pés anfibios descalços
	if collapse_y < 10:
		_ellipse(im, float(cx), float(33 + cy_off), 7.5, 4.5, kelp_dk)
		_ellipse(im, float(cx), float(31 + cy_off), 6.2, 4.0, kelp_md)
		# Ondas suaves na barra úmida
		for wx in range(-5, 6, 2):
			_px(im, cx + wx, 36 + cy_off + ((wx + kelp_phase) % 2), water_foam)
		if dir_name in ["down", "up"]:
			_rect(im, cx - 5, 34 + cy_off, 3, mini(6, 40 - (34 + cy_off)), skin_dk)
			_rect(im, cx + 2, 34 + cy_off, 3, mini(6, 40 - (34 + cy_off)), skin_dk)
			_px(im, cx - 5 + (step_x % 2), 39 + cy_off, skin_md)
			_px(im, cx + 2 - (step_x % 2), 39 + cy_off, skin_md)
		else:
			_rect(im, cx - 3 + step_x, 34 + cy_off, 4, 6, skin_dk)
			_rect(im, cx - 1 - step_x, 34 + cy_off, 3, 6, skin_md)

	# Tronco esguio feminino escamado e faixa de algas
	var tw := 11 if dir_name in ["down", "up"] else 8
	var th := maxi(4, 15 - int(collapse_y * 0.6))
	_ellipse(im, float(cx), float(24 + cy_off), float(tw) * 0.50, float(th) * 0.56, skin_dk)
	_ellipse(im, float(cx), float(23 + cy_off), float(tw) * 0.38, float(th) * 0.44, skin_md)
	# Xale de algas e crista dorsal aquática
	_rect(im, cx - int(tw * 0.4), 19 + cy_off, int(tw * 0.8), 3, kelp_md)
	if dir_name == "down":
		_rect(im, cx - 2, 23 + cy_off, 4, 5, skin_hi)
		_px(im, cx, 24 + cy_off, fin_glow)
	elif dir_name == "up":
		# Barbatana dorsal alongada descendo pelas costas
		for dy in range(18, 29):
			_px(im, cx, dy + cy_off, fin_glow if dy % 2 == 0 else skin_hi)

	# Braços longos conectados aos ombros com garras e barbatanas de antebraço
	var l_arm := Vector2i(cx - (6 if dir_name in ["down", "up"] else 3), 20 + cy_off)
	var r_arm := Vector2i(cx + (6 if dir_name in ["down", "up"] else 3), 20 + cy_off)
	if arm_mode == "cast":
		l_arm += Vector2i(-1 if dir_name in ["down", "up"] else (-3 if dir_name == "left" else 1), -3)
		r_arm += Vector2i(1 if dir_name in ["down", "up"] else (-1 if dir_name == "left" else 3), -3)
	elif arm_mode == "swing":
		l_arm += Vector2i(0, 2)
		r_arm += Vector2i(3 if dir_name != "left" else -3, 1)
	elif arm_mode == "windup":
		l_arm += Vector2i(-1, -2)
		r_arm += Vector2i(1, -3)

	var l_sh_lg := Vector2i(cx - 4 if dir_name in ["down", "up"] else cx - 1, 20 + cy_off)
	var r_sh_lg := Vector2i(cx + 4 if dir_name in ["down", "up"] else cx + 1, 20 + cy_off)
	for pair in [[l_sh_lg, l_arm], [r_sh_lg, r_arm]]:
		var sh: Vector2i = pair[0]
		var ap: Vector2i = pair[1]
		for t in range(4):
			var px_s := int(roundf(lerpf(float(sh.x), float(ap.x), float(t) / 3.0)))
			var py_s := int(roundf(lerpf(float(sh.y), float(ap.y + 1), float(t) / 3.0)))
			_ellipse(im, float(px_s), float(py_s), 1.6, 1.6, skin_md)
		_ellipse(im, float(ap.x), float(ap.y + 4), 1.8, 3.8, skin_md)
		_px(im, ap.x, ap.y + 3, fin_glow)
		_px(im, ap.x, ap.y + 8, skin_hi)

	# Cabeça humanoide + longos cabelos de algas flutuantes + guelras laterais
	var hy := 12 + cy_off + int(collapse_y * 0.25)
	var hair_sway := 1 if (kelp_phase % 2 == 0) else -1
	if dir_name in ["down", "up"]:
		_ellipse(im, float(cx + hair_sway), float(hy + 3), 7.2, 7.0, kelp_dk)
		_ellipse(im, float(cx), float(hy + 2), 6.2, 6.0, kelp_md)
		if dir_name == "up":
			for hs in [-3, 0, 3]:
				_rect(im, cx + hs, hy + 5, 2, 5 + ((kelp_phase + hs) % 2), kelp_hi)
		else:
			_ellipse(im, float(cx), float(hy), 4.6, 4.5, skin_md)
			_ellipse(im, float(cx), float(hy - 2), 3.2, 1.8, skin_hi)
	else:
		# Perfil lateral: cabelo de algas varrido para trás e rosto para frente
		var back_dir := 1 if dir_name == "left" else -1
		_ellipse(im, float(cx + back_dir * 3), float(hy + 2), 5.6, 6.8, kelp_dk)
		_ellipse(im, float(cx + back_dir * 2), float(hy + 1), 4.8, 5.8, kelp_md)
		_rect(im, cx + back_dir * 4, hy + 4 + hair_sway, 3, 6, kelp_hi)
		_ellipse(im, float(cx - back_dir), float(hy), 4.2, 4.4, skin_md)
		_ellipse(im, float(cx - back_dir), float(hy - 2), 2.8, 1.6, skin_hi)

	# Coroa de pequenas barbatanas dorsais no topo da cabeça
	_px(im, cx, hy - 6, fin_glow)
	_px(im, cx - 2, hy - 5, kelp_hi)
	_px(im, cx + 2, hy - 5, kelp_hi)

	# Guelras luminosas saindo dos lados das têmporas
	if dir_name in ["down", "up"]:
		for gy in [-1, 1]:
			_px(im, cx - 6, hy + gy, fin_glow)
			_px(im, cx - 7, hy + gy + hair_sway, kelp_hi)
			_px(im, cx + 6, hy + gy, fin_glow)
			_px(im, cx + 7, hy + gy - hair_sway, kelp_hi)
	else:
		var fd := 1 if dir_name == "left" else -1
		_px(im, cx + fd * 4, hy, fin_glow)
		_px(im, cx + fd * 5, hy + 1, kelp_hi)

	# Olhos luminosos abissais com órbita escura de alto contraste
	if dir_name == "down":
		_rect(im, cx - 4, hy - 1, 3, 3, kelp_dk)
		_rect(im, cx + 1, hy - 1, 3, 3, kelp_dk)
		_rect(im, cx - 3, hy, 2, 2, eye_glow)
		_rect(im, cx + 1, hy, 2, 2, eye_glow)
		_px(im, cx - 2, hy + 1, Color("#0A2C34"))
		_px(im, cx + 2, hy + 1, Color("#0A2C34"))
	elif dir_name == "left":
		_rect(im, cx - 4, hy - 1, 3, 3, kelp_dk)
		_rect(im, cx - 4, hy, 2, 2, eye_glow)
		_px(im, cx - 4, hy + 1, Color("#0A2C34"))
	elif dir_name == "right":
		_rect(im, cx + 1, hy - 1, 3, 3, kelp_dk)
		_rect(im, cx + 2, hy, 2, 2, eye_glow)
		_px(im, cx + 3, hy + 1, Color("#0A2C34"))

	# Jato / esfera de água sendo conjurada em attack2
	if arm_mode == "wave":
		var wp := Vector2i(cx, 28 + cy_off)
		match dir_name:
			"down": wp = Vector2i(cx, 30 + cy_off)
			"up": wp = Vector2i(cx, 9 + cy_off)
			"left": wp = Vector2i(cx - 11, 22 + cy_off)
			"right": wp = Vector2i(cx + 11, 22 + cy_off)
		_ellipse(im, float(wp.x), float(wp.y), 5.2, 4.0, Color("#228BE6"))
		_ellipse(im, float(wp.x), float(wp.y), 3.2, 2.4, water_foam)
		_px(im, wp.x, wp.y, eye_glow)

	im = _outline(im, outline)
	if fade < 0.99:
		for y in range(CELL):
			for x in range(CELL):
				var c := im.get_pixel(x, y)
				if c.a > 0.0:
					c.a *= fade
					im.set_pixel(x, y, c)
	return im


func _lg_frame(d: String, f: int, aname: String) -> Image:
	var l := Vector2i(-1 if d == "left" else (1 if d == "right" else 0), 1 if d == "down" else (-1 if d == "up" else 0))
	match aname:
		"idle":
			return _draw_lagoon_pose(d, 1 if f in [1, 2] else 0, 0, Vector2i.ZERO, "idle", f)
		"walk":
			var sx: int = [-1, -2, 0, 1, 2, 0][f]
			return _draw_lagoon_pose(d, [0, -1, -1, 0, -1, -1][f], sx, Vector2i.ZERO, "idle", f)
		"run":
			var sxr: int = [-2, -3, 0, 2, 3, 0][f]
			var lean := Vector2i(-2 if d == "left" else (2 if d == "right" else 0), 1 if d == "down" else (-1 if d == "up" else 0))
			return _draw_lagoon_pose(d, [0, -1, -2, 0, -1, -2][f], sxr, lean, "cast", f)
		"attack1":
			if f == 0:
				return _draw_lagoon_pose(d, 0, 0, -l * 2, "windup", f)
			elif f == 1 or f == 2:
				var im := _draw_lagoon_pose(d, 0, 1, l * 3, "swing", f)
				_draw_slash_arc(im, d, f, Color("#E6FFFF"), Color("#66D9E8"), Color("#1C7ED6"), false)
				return im
			return _draw_lagoon_pose(d, 0, 0, l, "idle", f)
		"attack2":
			if f <= 1:
				return _draw_lagoon_pose(d, -1, 0, Vector2i.ZERO, "windup", f)
			elif f <= 3:
				var im := _draw_lagoon_pose(d, 0, 0, l * 2, "wave", f)
				_draw_slash_arc(im, d, f, Color("#E6FFFF"), Color("#4DABF7"), Color("#1864AB"), true)
				return im
			return _draw_lagoon_pose(d, 0, 0, l, "cast", f)
		"hurt":
			var kb := Vector2i(2 if d == "left" else (-2 if d == "right" else 0), -2 if d == "down" else 2)
			return _draw_lagoon_pose(d, 0, 0, kb if f < 2 else Vector2i.ZERO, "idle", f, 1.0, f == 0)
		_:
			var col_y: int = [0, 2, 5, 8, 12, 16][f]
			var fd: float = [1.0, 0.92, 0.80, 0.60, 0.35, 0.14][f]
			var im_d := _draw_lagoon_pose(d, 0, 0, Vector2i.ZERO, "idle", f, fd, false, col_y)
			for b in range(5):
				_px(im_d, 16 + (b * 4 + f * 3) % 16, 34 - f * 2 - (b % 3) * 3, Color(0.55, 0.92, 1.0, fd))
			return im_d


func _build_lagoon_guardian_humanoid() -> void:
	var anims: Array[Dictionary] = [
		{"name": "idle", "file": "spritesheet_idle", "fps": 5.5, "loop": true, "cols": 4, "builder": _lg_frame.bind("idle")},
		{"name": "walk", "file": "spritesheet_walk", "fps": 8.0, "loop": true, "cols": 6, "builder": _lg_frame.bind("walk")},
		{"name": "run", "file": "spritesheet_run", "fps": 12.0, "loop": true, "cols": 6, "builder": _lg_frame.bind("run")},
		{"name": "attack1", "file": "spritesheet_attack1", "fps": 13.0, "loop": false, "cols": 5, "builder": _lg_frame.bind("attack1")},
		{"name": "attack2", "file": "spritesheet_attack2", "fps": 11.0, "loop": false, "cols": 5, "builder": _lg_frame.bind("attack2")},
		{"name": "hurt", "file": "spritesheet_hurt", "fps": 10.0, "loop": false, "cols": 3, "builder": _lg_frame.bind("hurt")},
		{"name": "death", "file": "spritesheet_death", "fps": 8.0, "loop": false, "cols": 6, "builder": _lg_frame.bind("death")},
	]
	_save_sheet_and_frames(
		"res://assets/sprites/enemies/lagoon_guardian",
		"res://assets/sprites/enemies/lagoon_guardian/lagoon_guardian_spriteframes.tres",
		"preview_lagoon_guardian_4x.png",
		anims
	)
