@tool
class_name NpcSpriteBuilder
extends RefCounted
## Organic 16-bit SNES pixel-art rig (48x48 cell, y=39 foot anchor) built directly
## from Huwag's approved anatomical silhouettes, with bespoke per-NPC headgear,
## uniforms, props, talk gestures, collapse deaths, and unique combat choreographies.

const Templates = preload("res://scripts/tools/npc_pixel_rig/npc_humanoid_templates.gd")
const Lote2 = preload("res://scripts/tools/npc_pixel_rig/npc_lote2_ext.gd")

const CELL_W := 48
const CELL_H := 48
const OFF_X := 8
const OFF_Y := 10
const FOOT_CELL_Y := 39 # OFF_Y (10) + 29 = 39 (identical to Huwag v3)

const DIRS := ["down", "up", "left", "right"]

const ADULT_ANIMS := [
	{"name": "idle", "frames": 4, "fps": 5.0, "loop": true},
	{"name": "walk", "frames": 6, "fps": 9.5, "loop": true},
	{"name": "talk", "frames": 4, "fps": 6.0, "loop": true},
	{"name": "attack", "frames": 5, "fps": 15.0, "loop": false},
	{"name": "hurt", "frames": 3, "fps": 10.0, "loop": false},
	{"name": "death", "frames": 6, "fps": 8.0, "loop": false},
]

const CHILD_ANIMS := [
	{"name": "idle", "frames": 4, "fps": 5.0, "loop": true},
	{"name": "walk", "frames": 6, "fps": 9.5, "loop": true},
	{"name": "talk", "frames": 4, "fps": 6.0, "loop": true},
	{"name": "hurt", "frames": 3, "fps": 10.0, "loop": false},
]


# ---------------------------------------------------------------------------
# 48x48 Token + VFX Canvas (allows clean organic shifts & limb/weapon extensions)
# ---------------------------------------------------------------------------
class Canvas48:
	var tok: PackedStringArray
	var vfx: PackedColorArray

	func _init() -> void:
		tok = PackedStringArray()
		tok.resize(CELL_W * CELL_H)
		for i in range(CELL_W * CELL_H):
			tok[i] = "."
		vfx = PackedColorArray()
		vfx.resize(CELL_W * CELL_H)
		vfx.fill(Color(0, 0, 0, 0))

	func clone() -> Canvas48:
		var copy := Canvas48.new()
		copy.tok = tok.duplicate()
		copy.vfx = vfx.duplicate()
		return copy

	func get_c(x: int, y: int) -> String:
		if x < 0 or x >= CELL_W or y < 0 or y >= CELL_H:
			return "."
		return tok[y * CELL_W + x]

	func set_c(x: int, y: int, ch: String) -> void:
		if x < 0 or x >= CELL_W or y < 0 or y >= CELL_H:
			return
		tok[y * CELL_W + x] = ch

	func set_vfx(x: int, y: int, col: Color) -> void:
		if x < 0 or x >= CELL_W or y < 0 or y >= CELL_H or col.a <= 0.0:
			return
		vfx[y * CELL_W + x] = col

	func shift_all(dx: int, dy: int) -> Canvas48:
		var out := Canvas48.new()
		for y in range(CELL_H):
			for x in range(CELL_W):
				var ch: String = get_c(x, y)
				if ch != ".":
					out.set_c(x + dx, y + dy, ch)
				var vc: Color = vfx[y * CELL_W + x]
				if vc.a > 0.0:
					out.set_vfx(x + dx, y + dy, vc)
		return out

	func shift_upper(dx: int, dy: int, cutoff_y: int = 29) -> Canvas48:
		## Shifts rows 0..cutoff_y while anchoring lower legs & feet at cutoff_y+1..CELL_H-1.
		var out := Canvas48.new()
		for y in range(CELL_H):
			for x in range(CELL_W):
				var ch: String = get_c(x, y)
				if ch == ".":
					continue
				if y <= cutoff_y:
					var ny := mini(cutoff_y, y + dy)
					out.set_c(x + dx, ny, ch)
				else:
					if out.get_c(x, y) == ".":
						out.set_c(x, y, ch)
		out.vfx = vfx.duplicate()
		return out

	func kneel_collapse(drop_px: int, foot_y: int = FOOT_CELL_Y) -> Canvas48:
		## Replicates Huwag's exact knee-collapse downward compression anchored on foot_y.
		var out := Canvas48.new()
		for y in range(CELL_H):
			for x in range(CELL_W):
				var ch: String = get_c(x, y)
				if ch == ".":
					continue
				var ny := y
				if y < foot_y - 4:
					ny = mini(foot_y - 1, y + drop_px)
				elif y < foot_y:
					ny = mini(foot_y, y + maxi(1, drop_px / 2))
				out.set_c(x, ny, ch)
		return out

	func bake(pal: Dictionary, tint_hurt: bool = false) -> Image:
		var img := Image.create(CELL_W, CELL_H, false, Image.FORMAT_RGBA8)
		img.fill(Color(0, 0, 0, 0))
		for y in range(CELL_H):
			for x in range(CELL_W):
				var ch: String = tok[y * CELL_W + x]
				if ch != "." and ch != "!":
					var col: Color = pal.get(ch, Color("#FF00FF"))
					if tint_hurt:
						var lum: float = col.r * 0.299 + col.g * 0.587 + col.b * 0.114
						if ch in ["k", "c", "S", "E"]:
							col = col.lerp(Color("#361018"), 0.45)
						elif lum < 0.28:
							col = col.lerp(Color("#C93A32"), 0.16)
						else:
							col = col.lerp(Color("#FFE4DB"), 0.26)
					img.set_pixel(x, y, col)
		for y in range(CELL_H):
			for x in range(CELL_W):
				var vc: Color = vfx[y * CELL_W + x]
				if vc.a > 0.0:
					img.set_pixel(x, y, vc)
		return img


# ---------------------------------------------------------------------------
# Color & Palette Construction (never pure #000000; crisp 2-3 tone SNES ramps)
# ---------------------------------------------------------------------------
static func c(hex: String) -> Color:
	return Color(hex)


static func default_skin_normal() -> Dictionary:
	return {
		"p": c("#DE9E72"),
		"l": c("#CA8B60"),
		"d": c("#985F42"),
		"q": c("#B5744F"),
		"S": c("#4D2B1C"),
		"r": c("#7A4929"),
		"w": c("#F0F2F7"),
		"E": c("#20181A"),
	}


static func default_skin_distorted() -> Dictionary:
	return {
		"p": c("#837D89"),
		"l": c("#6B6570"),
		"d": c("#4B4650"),
		"q": c("#36313D"),
		"S": c("#221C26"),
		"r": c("#362F3B"),
		"w": c("#2C242E"),
		"E": c("#FF3B30"),
	}


static func resolve_palette(spec: Dictionary, is_dist: bool) -> Dictionary:
	var mode_key := "distorted" if is_dist else "normal"
	var cfg: Dictionary = spec[mode_key]
	var p_map: Dictionary = {}

	var skin: Dictionary = cfg["skin"]
	for k_s in skin.keys():
		p_map[k_s] = skin[k_s]

	var hair: Dictionary = cfg.get("hair", {})
	p_map["h"] = hair.get("base", c("#36343A"))
	p_map["b"] = hair.get("hi", c("#52505A"))
	p_map["s"] = hair.get("sh", c("#242228"))
	p_map["a"] = hair.get("pin", c("#E04248"))
	p_map["M"] = cfg.get("mustache", p_map["b"])

	var hat: Dictionary = cfg.get("hat", {})
	p_map["H"] = hat.get("base", p_map["h"])
	p_map["B"] = hat.get("hi", p_map["b"])
	p_map["Q"] = hat.get("sh", p_map["s"])
	p_map["V"] = hat.get("visor", c("#141824"))
	p_map["G"] = hat.get("emblem", c("#F2C44E"))

	# Hair vs Hat outline token
	p_map["c"] = hat.get("out", hair.get("out", c("#181A24")))

	var torso: Dictionary = cfg.get("torso", {})
	p_map["j"] = torso.get("base", c("#1F2D47"))
	p_map["m"] = torso.get("sh", c("#151F33"))
	p_map["T"] = torso.get("hi", c("#304368"))
	p_map["u"] = hair.get("rim", torso.get("rim", c("#566685")))
	p_map["g"] = torso.get("undershirt", c("#26334D"))
	p_map["Z"] = torso.get("stripe1", c("#E58835"))
	p_map["Y"] = torso.get("stripe2", c("#F5D056"))
	p_map["X"] = torso.get("strap", c("#2A2D36"))
	p_map["R"] = torso.get("stain", c("#8C1D26"))

	var legs: Dictionary = cfg.get("legs", {})
	p_map["o"] = legs.get("base", c("#1B2438"))
	p_map["v"] = legs.get("sh", c("#131A29"))
	p_map["t"] = legs.get("boots", c("#2B2F3A"))
	p_map["z"] = legs.get("boots_hi", c("#4E5568"))

	# Garment/boot outline (never pure black)
	p_map["k"] = torso.get("out", c("#121622"))

	# Prop & weapon material tokens (used directly inside attack/talk grids)
	var weapon: Dictionary = cfg.get("weapon", {})
	p_map["W"] = weapon.get("blade", c("#D9E2EC"))
	p_map["P"] = weapon.get("blade_hi", c("#F5F9FC"))
	p_map["I"] = weapon.get("handle", c("#473428"))
	p_map["A"] = weapon.get("accent", c("#D93E36"))

	var prop: Dictionary = cfg.get("talk_prop", {})
	p_map["D"] = prop.get("primary", c("#2B313D"))
	p_map["L"] = prop.get("accent", c("#5EF27E"))
	p_map["N"] = prop.get("secondary", c("#EDF2F7"))

	return p_map


# ---------------------------------------------------------------------------
# Suite Exporter (48x48 sheets + .import + SpriteFrames .tres)
# ---------------------------------------------------------------------------
static func build_character_assets(spec: Dictionary, variant: String, base_dir: String) -> Dictionary:
	var npc_id: String = str(spec["id"])
	var is_dist: bool = (variant == "distorted")
	var anim_list: Array = CHILD_ANIMS if str(spec.get("build", "standard")) == "child" else ADULT_ANIMS
	var variant_dir: String = "%s/%s" % [base_dir, variant]
	var abs_variant_dir: String = ProjectSettings.globalize_path(variant_dir)
	DirAccess.make_dir_recursive_absolute(abs_variant_dir)

	var pal := resolve_palette(spec, is_dist)
	var sheets_info := {}
	var sample_frames := {}

	for anim_cfg in anim_list:
		var anim_name: String = str(anim_cfg["name"])
		var frame_count: int = int(anim_cfg["frames"])
		var sheet := Image.create(CELL_W * frame_count, CELL_H * DIRS.size(), false, Image.FORMAT_RGBA8)
		sheet.fill(Color(0, 0, 0, 0))

		for dir_idx in range(DIRS.size()):
			var dir_name: String = DIRS[dir_idx]
			for f_idx in range(frame_count):
				var frame_img: Image = render_frame(spec, is_dist, pal, dir_name, anim_name, f_idx)
				sheet.blit_rect(frame_img, Rect2i(0, 0, CELL_W, CELL_H), Vector2i(f_idx * CELL_W, dir_idx * CELL_H))
				if anim_name == "idle" and f_idx == 0:
					sample_frames["idle_%s" % dir_name] = frame_img
				elif anim_name in ["talk", "attack", "hurt", "death"] and f_idx == _preview_frame(anim_name):
					sample_frames["%s_%s" % [anim_name, dir_name]] = frame_img

		var png_res_path: String = "%s/spritesheet_%s.png" % [variant_dir, anim_name]
		var png_abs_path: String = ProjectSettings.globalize_path(png_res_path)
		sheet.save_png(png_abs_path)
		_write_pixel_art_import(png_res_path, png_abs_path)
		sheets_info[anim_name] = {
			"path": png_res_path,
			"frames": frame_count,
			"fps": float(anim_cfg["fps"]),
			"loop": bool(anim_cfg["loop"]),
			"image": sheet,
		}

	var tres_res_path: String = "%s/%s_%s_spriteframes.tres" % [base_dir, npc_id, variant]
	_write_spriteframes_tres(tres_res_path, sheets_info, anim_list)
	return {
		"npc_id": npc_id,
		"variant": variant,
		"tres_path": tres_res_path,
		"sheets": sheets_info,
		"samples": sample_frames,
	}


static func _preview_frame(anim_name: String) -> int:
	match anim_name:
		"talk": return 2
		"attack": return 2
		"hurt": return 0
		"death": return 4
	return 0


# ---------------------------------------------------------------------------
# Organic Frame Composition from Huwag Templates + Bespoke Details
# ---------------------------------------------------------------------------
static func render_frame(spec: Dictionary, is_dist: bool, pal: Dictionary, dir: String, anim: String, f_idx: int) -> Image:
	var mode_cfg: Dictionary = spec["distorted" if is_dist else "normal"]

	if anim == "death":
		return _render_death(spec, mode_cfg, is_dist, pal, dir, f_idx)

	var can := _compose_pose(spec, mode_cfg, is_dist, dir, "idle")
	var tint_hurt := false

	match anim:
		"idle":
			if f_idx == 1:
				can = can.shift_upper(0, -1, OFF_Y + 18)
			elif f_idx == 2:
				can = can.shift_upper(0, 1, OFF_Y + 18)
			elif f_idx == 3 and not is_dist:
				_apply_blink(can, dir, spec)

		"walk":
			var step_a := _compose_pose(spec, mode_cfg, is_dist, dir, "step_a")
			var step_b := _compose_pose(spec, mode_cfg, is_dist, dir, "step_b")
			match f_idx:
				0: can = step_a
				1: can = step_a.shift_upper(0, 1, OFF_Y + 28)
				2: can = can.shift_all(0, -1)
				3: can = step_b
				4: can = step_b.shift_upper(0, 1, OFF_Y + 28)
				5: can = can.shift_all(0, -1)

		"talk":
			can = _render_talk(spec, mode_cfg, is_dist, dir, f_idx)

		"attack":
			can = _render_attack(spec, mode_cfg, is_dist, dir, f_idx)

		"hurt":
			var dv := _dir_vec(dir)
			match f_idx:
				0:
					can = can.shift_all(-dv.x * 2, -1)
					_apply_blink(can, dir, spec)
					tint_hurt = true
					can.set_vfx(OFF_X + 11, OFF_Y + 15, c("#FFF5D6"))
					can.set_vfx(OFF_X + 21, OFF_Y + 16, c("#FF7A66"))
					can.set_vfx(OFF_X + 16, OFF_Y + 13, c("#FFD9B3"))
				1:
					can = can.shift_upper(-dv.x, 1, OFF_Y + 26)
					_apply_blink(can, dir, spec)
				2:
					pass

	return can.bake(pal, tint_hurt)


static func new_canvas() -> Canvas48:
	return Canvas48.new()


static func _self_script() -> GDScript:
	return load("res://scripts/tools/npc_pixel_rig/npc_sprite_builder.gd") as GDScript


static func _compose_pose(spec: Dictionary, mode_cfg: Dictionary, is_dist: bool, dir: String, pose_base: String) -> Canvas48:
	var can := Canvas48.new()
	var grid: Array[String] = Lote2.get_base_grid(spec, dir, pose_base) if int(spec.get("batch", 1)) == 2 else Templates.get_base_grid(dir, pose_base)
	_stamp_32(can, grid, false)

	# Clear sleep-deprived eyebags for rested NPCs unless tired/distorted
	if not bool(spec.get("tired_eyes", false)) and not is_dist:
		_replace_tok_in_region(can, "q", "l", OFF_X + 8, OFF_X + 26, OFF_Y + 12, OFF_Y + 16)

	# Stamp organic uniform, shoulders & silhouette onto standing body
	_apply_outfit_sculpt(can, spec, is_dist, dir, pose_base)

	# Overlay sculpted hair & headgear on rows 0..17
	var head_overlay: Array[String] = _get_head_overlay(str(spec["head_id"]), dir)
	if not head_overlay.is_empty():
		_stamp_32(can, head_overlay, true)

	# Helmet visor crack on Distorted Ato
	if is_dist and bool(spec.get("helmet_crack", false)):
		_apply_helmet_crack(can, dir)

	# Character-specific persistent accessory (Santos shoulder radio antenna, Maria badge)
	_apply_persistent_gear(can, spec, is_dist, dir, pose_base)

	# Abnormal twisted posture on Distorted NPCs: subtle 1px head tilt + lop-sided shoulder/hunch!
	if is_dist:
		can = _apply_distorted_posture(can, spec, dir)

	return can


static func _apply_distorted_posture(can: Canvas48, spec: Dictionary, dir: String) -> Canvas48:
	var out := can.clone()
	if dir in ["down", "up"]:
		var tilt_dir := 1 if str(spec["id"]) in ["cap_reyes", "bombeiro_ato"] else -1
		# Shift cranium & face (y <= OFF_Y + 14) horizontally by 1px relative to neck (y=15..16)
		for y in range(0, OFF_Y + 15):
			for x in range(CELL_W):
				out.set_c(x, y, ".")
		for y in range(0, OFF_Y + 15):
			for x in range(CELL_W):
				var ch: String = can.get_c(x, y)
				if ch != ".":
					out.set_c(x + tilt_dir, y, ch)
		# Sag the opposite shoulder & sleeve 1px down (y = OFF_Y + 17..22) for visible abnormality
		var sag_start := (OFF_X + 18) if tilt_dir > 0 else 0
		var sag_end := (CELL_W - 1) if tilt_dir > 0 else (OFF_X + 14)
		for y in range(OFF_Y + 23, OFF_Y + 16, -1):
			for x in range(sag_start, sag_end + 1):
				var ch: String = out.get_c(x, y)
				if ch != ".":
					out.set_c(x, y + 1, ch)
					if y == OFF_Y + 17:
						out.set_c(x, y, ".")
	else:
		# Profile hunch: crane head/upper chest 1px forward & 1px down in facing direction
		var fwd := -1 if dir == "left" else 1
		for y in range(OFF_Y + 18, 0, -1):
			for x in range(CELL_W):
				out.set_c(x, y, ".")
		for y in range(0, OFF_Y + 18):
			for x in range(CELL_W):
				var ch: String = can.get_c(x, y)
				if ch != ".":
					out.set_c(x + fwd, y + 1, ch)
	return out


static func _stamp_32(can: Canvas48, rows: Array[String], is_overlay: bool) -> void:
	for ly in range(rows.size()):
		var row_s: String = rows[ly]
		if row_s.length() != 32:
			push_warning("[NpcSpriteBuilder] Linha %d tem tamanho %d != 32: %s" % [ly, row_s.length(), row_s])
		for lx in range(mini(32, row_s.length())):
			var ch: String = row_s.substr(lx, 1)
			if ch == ".":
				continue
			if ch == "!":
				can.set_c(OFF_X + lx, OFF_Y + ly, ".")
			elif not is_overlay or ch != ".":
				can.set_c(OFF_X + lx, OFF_Y + ly, ch)


static func _get_head_overlay(head_id: String, dir: String) -> Array[String]:
	var d_key := "left" if dir == "right" else dir
	var raw: Array[String] = []
	match "%s_%s" % [head_id, d_key]:
		"reyes_down": raw = Templates.HEAD_REYES_DOWN
		"reyes_up": raw = Templates.HEAD_REYES_UP
		"reyes_left": raw = Templates.HEAD_REYES_LEFT
		"ato_down": raw = Templates.HEAD_ATO_DOWN
		"ato_up": raw = Templates.HEAD_ATO_UP
		"ato_left": raw = Templates.HEAD_ATO_LEFT
		"santos_down": raw = Templates.HEAD_SANTOS_DOWN
		"santos_up": raw = Templates.HEAD_SANTOS_UP
		"santos_left": raw = Templates.HEAD_SANTOS_LEFT
		"maria_down": raw = Templates.HEAD_MARIA_DOWN
		"maria_up": raw = Templates.HEAD_MARIA_UP
		"maria_left": raw = Templates.HEAD_MARIA_LEFT
	if raw.is_empty():
		return Lote2.get_head_overlay(head_id, dir)
	if dir == "right":
		return Templates.mirror_grid_h(raw)
	return raw


static func _replace_tok_in_region(can: Canvas48, from_ch: String, to_ch: String, x0: int, x1: int, y0: int, y1: int) -> void:
	for y in range(y0, y1 + 1):
		for x in range(x0, x1 + 1):
			if can.get_c(x, y) == from_ch:
				can.set_c(x, y, to_ch)


# ---------------------------------------------------------------------------
# Organic Outfit Sculpting (modifies torso tokens around curved A-frame arms!)
# ---------------------------------------------------------------------------
static func _apply_outfit_sculpt(can: Canvas48, spec: Dictionary, is_dist: bool, dir: String, _pose: String) -> void:
	if int(spec.get("batch", 1)) == 2:
		Lote2.apply_outfit_sculpt(can, spec, is_dist, dir, _pose)
		return
	var outfit: String = str(spec["outfit_style"])
	var build: String = str(spec.get("build", "standard"))

	# 1. Transform Huwag's zipper ('Z') & undershirt ('g') based on outfit
	match outfit:
		"bfp_commander":
			# Closed navy officer tunic: 'g'/'Z' become dark navy jacket + twin brass buttons
			_replace_tok_in_region(can, "g", "j", OFF_X + 12, OFF_X + 20, OFF_Y + 17, OFF_Y + 23)
			_replace_tok_in_region(can, "Z", "m", OFF_X + 12, OFF_X + 20, OFF_Y + 17, OFF_Y + 23)
			if dir == "down":
				# Brass command buttons down center placket & gold epaulets + belt buckle
				for by in [18, 20]:
					can.set_c(OFF_X + 16, OFF_Y + by, "Y")
					can.set_c(OFF_X + 17, OFF_Y + by, "Y")
				# Gold epaulets sitting on shoulder caps
				can.set_c(OFF_X + 12, OFF_Y + 17, "Y")
				can.set_c(OFF_X + 21, OFF_Y + 17, "Y")
				# Belt & long command coat skirt overhanging waist cleanly
				for bx in range(13, 21):
					if can.get_c(OFF_X + bx, OFF_Y + 22) != ".":
						can.set_c(OFF_X + bx, OFF_Y + 22, "Y" if (bx == 16 or bx == 17) else "X")
					if can.get_c(OFF_X + bx, OFF_Y + 24) in ["o", "v", "T"]:
						can.set_c(OFF_X + bx, OFF_Y + 24, "j")
			elif dir == "up":
				can.set_c(OFF_X + 12, OFF_Y + 17, "Y")
				can.set_c(OFF_X + 20, OFF_Y + 17, "Y")
				for bx in range(13, 21):
					if can.get_c(OFF_X + bx, OFF_Y + 24) in ["o", "v", "T"]:
						can.set_c(OFF_X + bx, OFF_Y + 24, "j")
			else: # left / right
				var ep_x := 16 if dir == "left" else 15
				can.set_c(OFF_X + ep_x, OFF_Y + 18, "Y")
				can.set_c(OFF_X + ep_x + (1 if dir == "left" else -1), OFF_Y + 18, "Y")
				# Gold side stripe & long coat overhang
				for lx in range(11, 21):
					if can.get_c(OFF_X + lx, OFF_Y + 24) in ["o", "v", "k"]:
						if lx >= 13 and lx <= 19:
							can.set_c(OFF_X + lx, OFF_Y + 24, "j")

		"bfp_turnout_hose":
			# Closed heavy BFP turnout coat + bold dual high-visibility stripes + shoulder hose coil
			_replace_tok_in_region(can, "g", "j", OFF_X + 12, OFF_X + 20, OFF_Y + 17, OFF_Y + 23)
			_replace_tok_in_region(can, "Z", "j", OFF_X + 12, OFF_X + 20, OFF_Y + 17, OFF_Y + 23)
			# Horizontal reflective bands across jacket body (leaves dark outline 'k' untouched!)
			for rx in range(9, 24):
				if can.get_c(OFF_X + rx, OFF_Y + 20) in ["j", "m", "T"]:
					can.set_c(OFF_X + rx, OFF_Y + 20, "Z")
				if can.get_c(OFF_X + rx, OFF_Y + 22) in ["j", "m", "T"]:
					can.set_c(OFF_X + rx, OFF_Y + 22, "Y")
			# Black diagonal coiled firehose slung from left shoulder to right hip
			var hose_pts := []
			if dir == "down":
				hose_pts = [Vector2i(13, 17), Vector2i(14, 18), Vector2i(15, 19), Vector2i(16, 20), Vector2i(17, 21), Vector2i(18, 22)]
			elif dir == "up":
				hose_pts = [Vector2i(19, 17), Vector2i(18, 18), Vector2i(17, 19), Vector2i(16, 20), Vector2i(15, 21)]
			elif dir == "left":
				hose_pts = [Vector2i(17, 18), Vector2i(16, 19), Vector2i(15, 20), Vector2i(14, 21), Vector2i(13, 22)]
			else:
				hose_pts = [Vector2i(14, 18), Vector2i(15, 19), Vector2i(16, 20), Vector2i(17, 21), Vector2i(18, 22)]
			for hp: Vector2i in hose_pts:
				can.set_c(OFF_X + hp.x, OFF_Y + hp.y, "X")
			# Brass coupling badge at center/chest
			if dir in ["down", "up"]:
				can.set_c(OFF_X + 16, OFF_Y + 20, "G")

		"bfp_open_tee":
			# Open BFP jacket over white undershirt ('g') + thin stripe + cool shoulder rim light ('u')
			if dir in ["left", "right"]:
				var front_x := 12 if dir == "left" else 19
				can.set_c(OFF_X + front_x, OFF_Y + 19, "g")
				can.set_c(OFF_X + front_x, OFF_Y + 20, "g")
			for rx in range(10, 23):
				if can.get_c(OFF_X + rx, OFF_Y + 22) in ["j", "m"]:
					can.set_c(OFF_X + rx, OFF_Y + 22, "Z")
			# 1px cool blue-grey rim highlight along outer shoulder contour
			for sy in [17, 18]:
				for sx in range(8, 25):
					if can.get_c(OFF_X + sx, OFF_Y + sy) == "k" and can.get_c(OFF_X + sx, OFF_Y + sy - 1) == ".":
						can.set_c(OFF_X + sx, OFF_Y + sy, "u")

		"nurse_labcoat":
			# Cinched slim waist + flared coat hem + dark crossbody medical strap + red badge
			if dir in ["down", "up"]:
				# Subtle slim waist pinch at y=20..21 inside jacket hem while preserving arm separation
				for wy in [19, 20]:
					if can.get_c(OFF_X + 13, OFF_Y + wy) in ["j", "m", "Z"]:
						can.set_c(OFF_X + 13, OFF_Y + wy, "k")
					if can.get_c(OFF_X + 20, OFF_Y + wy) in ["j", "m", "Z"]:
						can.set_c(OFF_X + 20, OFF_Y + wy, "k")
				# Coat skirt flare down to upper thighs (y=24) in white lab coat tone
				for fx in range(13, 20):
					if can.get_c(OFF_X + fx, OFF_Y + 23) in ["k", "Z", "g"]:
						can.set_c(OFF_X + fx, OFF_Y + 23, "j")
					if can.get_c(OFF_X + fx, OFF_Y + 24) in ["o", "v"]:
						can.set_c(OFF_X + fx, OFF_Y + 24, "m")
			# Remove bright zipper tokens: use coat lapel 'T' & scrubs 'g'
			_replace_tok_in_region(can, "Z", "T", OFF_X + 9, OFF_X + 24, OFF_Y + 17, OFF_Y + 23)
			# Crossbody nurse strap + side satchel
			var strap_pts: Array[Vector2i] = []
			if dir == "down":
				strap_pts = [Vector2i(19, 17), Vector2i(18, 18), Vector2i(17, 19), Vector2i(16, 20), Vector2i(15, 21), Vector2i(14, 22)]
				can.set_c(OFF_X + 18, OFF_Y + 19, "a") # signature red cross lapel badge!
			elif dir == "up":
				strap_pts = [Vector2i(13, 17), Vector2i(14, 18), Vector2i(15, 19), Vector2i(16, 20), Vector2i(17, 21), Vector2i(18, 22)]
			elif dir == "left":
				strap_pts = [Vector2i(17, 18), Vector2i(16, 19), Vector2i(15, 20), Vector2i(14, 21)]
			else:
				strap_pts = [Vector2i(14, 18), Vector2i(15, 19), Vector2i(16, 20), Vector2i(17, 21)]
			for sp: Vector2i in strap_pts:
				can.set_c(OFF_X + sp.x, OFF_Y + sp.y, "X")
			# Distorted nurse labcoat gets dry blood & ash splatters on torso & hem!
			if is_dist:
				for stain: Vector2i in [Vector2i(15, 19), Vector2i(18, 21), Vector2i(14, 23), Vector2i(17, 24)]:
					if can.get_c(OFF_X + stain.x, OFF_Y + stain.y) in ["j", "m", "T", "g"]:
						can.set_c(OFF_X + stain.x, OFF_Y + stain.y, "R")

	# 2. Broad chest shoulder curve (Reyes & Ato only) cleanly filling 1px shoulder pad without flattening arms!
	if build == "broad" and dir in ["down", "up"]:
		for sy in [17, 18]:
			var lx_edge := 10
			var rx_edge := 23
			if can.get_c(OFF_X + lx_edge, OFF_Y + sy) == "k":
				can.set_c(OFF_X + lx_edge - 1, OFF_Y + sy, "k")
				can.set_c(OFF_X + lx_edge, OFF_Y + sy, "T" if sy == 17 else "j")
			if can.get_c(OFF_X + rx_edge, OFF_Y + sy) == "k":
				can.set_c(OFF_X + rx_edge + 1, OFF_Y + sy, "k")
				can.set_c(OFF_X + rx_edge, OFF_Y + sy, "T" if sy == 17 else "j")


static func _apply_persistent_gear(can: Canvas48, spec: Dictionary, is_dist: bool, dir: String, _pose: String) -> void:
	if int(spec.get("batch", 1)) == 2:
		Lote2.apply_persistent_gear(can, spec, is_dist, dir, _pose)
		return
	# Bombeiro Santos keeps a shoulder walkie-talkie w/ thin 2px antenna above right/left shoulder
	if str(spec["id"]) == "bombeiro_santos":
		var ant_x := 11 if dir in ["down", "right"] else 21
		if dir == "left":
			ant_x = 18
		can.set_c(OFF_X + ant_x, OFF_Y + 17, "D")
		can.set_c(OFF_X + ant_x, OFF_Y + 16, "k")
		can.set_c(OFF_X + ant_x, OFF_Y + 15, "L" if is_dist else "k")


static func _apply_helmet_crack(can: Canvas48, dir: String) -> void:
	match dir:
		"down":
			can.set_c(OFF_X + 18, OFF_Y + 3, "Q")
			can.set_c(OFF_X + 19, OFF_Y + 4, "c")
			can.set_c(OFF_X + 18, OFF_Y + 5, "c")
			can.set_c(OFF_X + 20, OFF_Y + 5, "Q")
		"left":
			can.set_c(OFF_X + 14, OFF_Y + 3, "c")
			can.set_c(OFF_X + 15, OFF_Y + 4, "Q")
			can.set_c(OFF_X + 16, OFF_Y + 5, "c")
		"right":
			can.set_c(OFF_X + 17, OFF_Y + 3, "c")
			can.set_c(OFF_X + 16, OFF_Y + 4, "Q")
			can.set_c(OFF_X + 15, OFF_Y + 5, "c")


static func _apply_blink(can: Canvas48, dir: String, _spec: Dictionary) -> void:
	var is_child: bool = str(_spec.get("build", "standard")) == "child"
	if dir == "down":
		for ex in range(11, 23):
			if can.get_c(OFF_X + ex, OFF_Y + 13) in ["w", "E"]:
				can.set_c(OFF_X + ex, OFF_Y + 13, "l")
			if can.get_c(OFF_X + ex, OFF_Y + 14) in ["w", "E"]:
				can.set_c(OFF_X + ex, OFF_Y + 14, "l" if is_child else "r")
			if is_child and can.get_c(OFF_X + ex, OFF_Y + 15) in ["w", "E"]:
				can.set_c(OFF_X + ex, OFF_Y + 15, "r")
	elif dir in ["left", "right"]:
		for y in range(OFF_Y + 12, OFF_Y + 17):
			for x in range(OFF_X + 8, OFF_X + 25):
				if can.get_c(x, y) in ["w", "E"]:
					can.set_c(x, y, "r")


# ---------------------------------------------------------------------------
# Talk Animation (4f): Expressive Head Nod + Character Prop Gesture
# ---------------------------------------------------------------------------
static func _render_talk(spec: Dictionary, mode_cfg: Dictionary, is_dist: bool, dir: String, f_idx: int) -> Canvas48:
	if int(spec.get("batch", 1)) == 2:
		return Lote2.render_talk(_self_script(), spec, mode_cfg, is_dist, dir, f_idx) as Canvas48
	var can := _compose_pose(spec, mode_cfg, is_dist, dir, "idle")
	var kind: String = str(mode_cfg.get("talk_prop", {}).get("kind", "radio"))

	# Subtle animated head nod + mouth speech beat
	if f_idx == 1 or f_idx == 2:
		if dir == "down":
			can.set_c(OFF_X + 16, OFF_Y + 15, "S")
			can.set_c(OFF_X + 17, OFF_Y + 15, "S")
		if f_idx == 2:
			can = can.shift_upper(0, 1, OFF_Y + 18)

	# Raised foreground hand & signature prop on f_idx 1..3
	var raise := 0
	if f_idx == 1 or f_idx == 3:
		raise = 1
	elif f_idx == 2:
		raise = 2
	if raise == 0:
		return can

	var hx := 22 if dir == "down" else (10 if dir == "left" else (21 if dir == "right" else 22))
	var hy := 20 - raise
	if dir == "up":
		hy = 19 - raise

	# Extended hand tokens supporting prop cleanly
	can.set_c(OFF_X + hx, OFF_Y + hy + 1, "p")
	can.set_c(OFF_X + hx, OFF_Y + hy + 2, "k")

	match kind:
		"radio":
			# Compact walkie-talkie with bright green/red indicator & antenna
			for ry in range(-1, 2):
				can.set_c(OFF_X + hx, OFF_Y + hy + ry, "D")
				can.set_c(OFF_X + hx + 1, OFF_Y + hy + ry, "D")
				can.set_c(OFF_X + hx - 1, OFF_Y + hy + ry, "k")
				can.set_c(OFF_X + hx + 2, OFF_Y + hy + ry, "k")
			can.set_c(OFF_X + hx, OFF_Y + hy - 2, "k")
			can.set_c(OFF_X + hx, OFF_Y + hy - 3, "k")
			can.set_c(OFF_X + hx + 1, OFF_Y + hy - 1, "L")
		"gauge_nozzle":
			# Brass pressure gauge (white circular 3x3 dial + indicator)
			for dy in range(-1, 2):
				for dx in range(-1, 2):
					var is_edge := absi(dx) == 1 and absi(dy) == 1
					can.set_c(OFF_X + hx + dx, OFF_Y + hy + dy, "G" if is_edge else "N")
			can.set_c(OFF_X + hx, OFF_Y + hy, "A")
		"clipboard":
			# Nurse clipboard: wooden trim, crisp chart sheet, dark text ticks (crimson if distorted)
			for cy in range(-2, 2):
				for cx in range(-1, 2):
					var tok := "N"
					if cy == -2:
						tok = "I"
					elif cy == -1 and cx == 0:
						tok = "A" if is_dist else "k"
					elif cy == 0 and cx == -1:
						tok = "R" if is_dist else "k"
					can.set_c(OFF_X + hx + cx, OFF_Y + hy + cy, tok)
					# Clean perimeter
					if can.get_c(OFF_X + hx + cx - 1, OFF_Y + hy + cy) == ".":
						can.set_c(OFF_X + hx + cx - 1, OFF_Y + hy + cy, "k")
					if can.get_c(OFF_X + hx + cx + 1, OFF_Y + hy + cy) == ".":
						can.set_c(OFF_X + hx + cx + 1, OFF_Y + hy + cy, "k")

	return can


# ---------------------------------------------------------------------------
# 4 Truly Distinct Attack Choreographies (5f each) — Zero Cloned Crescent Arcs
# ---------------------------------------------------------------------------
static func _render_attack(spec: Dictionary, mode_cfg: Dictionary, is_dist: bool, dir: String, f_idx: int) -> Canvas48:
	if int(spec.get("batch", 1)) == 2:
		return Lote2.render_attack(_self_script(), spec, mode_cfg, is_dist, dir, f_idx) as Canvas48
	var style: String = str(spec["attack_style"])
	match style:
		"command_sweep":
			return _atk_command_sweep(spec, mode_cfg, is_dist, dir, f_idx)
		"axe_slam":
			return _atk_axe_slam(spec, mode_cfg, is_dist, dir, f_idx)
		"halligan_hook":
			return _atk_halligan_hook(spec, mode_cfg, is_dist, dir, f_idx)
		"scalpel_thrust":
			return _atk_scalpel_thrust(spec, mode_cfg, is_dist, dir, f_idx)
	return _compose_pose(spec, mode_cfg, is_dist, dir, "idle")


static func _draw_seg(can: Canvas48, x0: int, y0: int, x1: int, y1: int, tok: String, outline_tok: String = "k") -> void:
	var steps := maxi(1, maxi(absi(x1 - x0), absi(y1 - y0)))
	for i in range(steps + 1):
		var t := float(i) / float(steps)
		var px := roundi(lerpf(float(x0), float(x1), t))
		var py := roundi(lerpf(float(y0), float(y1), t))
		can.set_c(px, py, tok)
		if outline_tok != "":
			for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				if can.get_c(px + d.x, py + d.y) == ".":
					can.set_c(px + d.x, py + d.y, outline_tok)


static func _draw_vfx_seg(can: Canvas48, x0: int, y0: int, x1: int, y1: int, col: Color, col_alt: Color = Color.TRANSPARENT) -> void:
	var steps := maxi(1, maxi(absi(x1 - x0), absi(y1 - y0)))
	for i in range(steps + 1):
		var t := float(i) / float(steps)
		var px := roundi(lerpf(float(x0), float(x1), t))
		var py := roundi(lerpf(float(y0), float(y1), t))
		var draw_col := col if (col_alt.a <= 0.01 or t < 0.65) else col_alt
		can.set_vfx(px, py, draw_col)


# --- 1) Cap. Reyes: Varredura Ampla de Comando (Baton-Torch Wide Sweep + Amber Cone) ---
static func _atk_command_sweep(spec: Dictionary, mode_cfg: Dictionary, is_dist: bool, dir: String, f_idx: int) -> Canvas48:
	var dv := _dir_vec(dir)
	var pose := "step_a" if f_idx in [1, 2, 3] else "idle"
	var can := _compose_pose(spec, mode_cfg, is_dist, dir, pose)

	if f_idx == 0:
		can = can.shift_upper(-dv.x, 0, OFF_Y + 25)
	elif f_idx == 2:
		can = can.shift_all(dv.x * 2, dv.y)
	elif f_idx == 3:
		can = can.shift_all(dv.x, 0)

	var core_c := c("#FF4238") if is_dist else c("#FFE073")
	var mid_c := c("#B81D24") if is_dist else c("#DE8828")
	var tip_c := c("#FFD2CC") if is_dist else c("#FFF8D9")

	match f_idx:
		0: # Raised baton behind back/shoulder
			match dir:
				"down":
					_draw_seg(can, OFF_X + 10, OFF_Y + 19, OFF_X + 7, OFF_Y + 11, "I")
					can.set_c(OFF_X + 7, OFF_Y + 10, "A")
				"up":
					_draw_seg(can, OFF_X + 21, OFF_Y + 18, OFF_X + 25, OFF_Y + 11, "I")
					can.set_c(OFF_X + 25, OFF_Y + 10, "A")
				"left":
					_draw_seg(can, OFF_X + 20, OFF_Y + 18, OFF_X + 26, OFF_Y + 11, "I")
					can.set_c(OFF_X + 27, OFF_Y + 10, "A")
				"right":
					_draw_seg(can, OFF_X + 11, OFF_Y + 18, OFF_X + 5, OFF_Y + 11, "I")
					can.set_c(OFF_X + 4, OFF_Y + 10, "A")
		1: # Whipping mid-swing
			match dir:
				"down": _draw_seg(can, OFF_X + 11, OFF_Y + 22, OFF_X + 12, OFF_Y + 30, "W")
				"up": _draw_seg(can, OFF_X + 22, OFF_Y + 17, OFF_X + 23, OFF_Y + 7, "W")
				"left": _draw_seg(can, OFF_X + 14, OFF_Y + 17, OFF_X + 7, OFF_Y + 13, "W")
				"right": _draw_seg(can, OFF_X + 17, OFF_Y + 17, OFF_X + 24, OFF_Y + 13, "W")
		2: # Full Wide Commander Fan Sweep (solid feathered amber/crimson wedge!)
			match dir:
				"down":
					_draw_seg(can, OFF_X + 18, OFF_Y + 23, OFF_X + 27, OFF_Y + 29, "W")
					can.set_c(OFF_X + 28, OFF_Y + 30, "A")
					_draw_vfx_seg(can, 13, 35, 36, 35, mid_c)
					_draw_vfx_seg(can, 14, 36, 37, 36, core_c)
					_draw_vfx_seg(can, 16, 37, 36, 37, tip_c)
					_draw_vfx_seg(can, 19, 38, 34, 38, core_c)
					_draw_vfx_seg(can, 22, 39, 31, 39, mid_c)
				"up":
					_draw_seg(can, OFF_X + 12, OFF_Y + 16, OFF_X + 7, OFF_Y + 9, "W")
					can.set_c(OFF_X + 6, OFF_Y + 8, "A")
					_draw_vfx_seg(can, 12, 11, 35, 11, core_c)
					_draw_vfx_seg(can, 14, 10, 34, 10, tip_c)
					_draw_vfx_seg(can, 17, 9, 31, 9, mid_c)
				"left":
					_draw_seg(can, OFF_X + 12, OFF_Y + 22, OFF_X + 4, OFF_Y + 27, "W")
					can.set_c(OFF_X + 3, OFF_Y + 28, "A")
					# Solid feathered amber flashlight-baton sweep fan (no hollow C-outline!)
					_draw_vfx_seg(can, 15, 22, 9, 20, mid_c)
					_draw_vfx_seg(can, 14, 25, 7, 25, mid_c)
					_draw_vfx_seg(can, 13, 28, 6, 30, core_c)
					_draw_vfx_seg(can, 14, 31, 8, 35, mid_c)
					_draw_vfx_seg(can, 10, 20, 7, 27, core_c)
					_draw_vfx_seg(can, 7, 27, 10, 36, core_c)
					_draw_vfx_seg(can, 8, 22, 7, 33, tip_c)
				"right":
					_draw_seg(can, OFF_X + 21, OFF_Y + 22, OFF_X + 29, OFF_Y + 27, "W")
					can.set_c(OFF_X + 30, OFF_Y + 28, "A")
					_draw_vfx_seg(can, 32, 22, 38, 20, mid_c)
					_draw_vfx_seg(can, 33, 25, 40, 25, mid_c)
					_draw_vfx_seg(can, 34, 28, 41, 30, core_c)
					_draw_vfx_seg(can, 33, 31, 39, 35, mid_c)
					_draw_vfx_seg(can, 37, 20, 40, 27, core_c)
					_draw_vfx_seg(can, 40, 27, 37, 36, core_c)
					_draw_vfx_seg(can, 39, 22, 40, 33, tip_c)
		3: # Extended follow-through w/ dissolving outer beam sparks
			match dir:
				"down":
					_draw_seg(can, OFF_X + 21, OFF_Y + 23, OFF_X + 26, OFF_Y + 26, "W")
					can.set_vfx(35, 34, core_c)
					can.set_vfx(31, 38, mid_c)
				"up":
					_draw_seg(can, OFF_X + 12, OFF_Y + 16, OFF_X + 9, OFF_Y + 11, "W")
					can.set_vfx(12, 10, core_c)
				"left":
					_draw_seg(can, OFF_X + 11, OFF_Y + 22, OFF_X + 5, OFF_Y + 25, "W")
					can.set_vfx(10, 37, core_c)
				"right":
					_draw_seg(can, OFF_X + 20, OFF_Y + 22, OFF_X + 26, OFF_Y + 25, "W")
					can.set_vfx(37, 37, core_c)
	return can


# --- 2) Bombeiro Ato: Esmagamento Vertical Pesado de Machado BFP (Sky-High Raise -> Floor Impact) ---
static func _atk_axe_slam(spec: Dictionary, mode_cfg: Dictionary, is_dist: bool, dir: String, f_idx: int) -> Canvas48:
	var dv := _dir_vec(dir)
	var can := _compose_pose(spec, mode_cfg, is_dist, dir, "idle")

	var cleave_c := c("#FF5038") if is_dist else c("#FFCC55")
	var white_c := c("#FFD6CC") if is_dist else c("#FFFDF0")
	var spark_c := c("#C72636") if is_dist else c("#F27824")

	match f_idx:
		0: # Brace & haul heavy axe above shoulder
			can = can.shift_upper(0, 1, OFF_Y + 27)
			_draw_seg(can, OFF_X + 21, OFF_Y + 20, OFF_X + 23, OFF_Y + 7, "I")
			for hx in range(21, 26):
				can.set_c(OFF_X + hx, OFF_Y + 6, "A")
				can.set_c(OFF_X + hx, OFF_Y + 5, "W")
		1: # APEX SKY-HIGH OVERHEAD RAISE (cocked off-center toward dominant hand so face stays readable!)
			can = can.shift_upper(0, -1, OFF_Y + 25)
			if dir == "down":
				_draw_seg(can, OFF_X + 22, OFF_Y + 21, OFF_X + 20, OFF_Y + 4, "I")
				for ax in range(15, 24):
					can.set_c(OFF_X + ax, OFF_Y + 2, "A" if ax < 20 else "W")
					can.set_c(OFF_X + ax, OFF_Y + 3, "A" if ax < 20 else "P")
					can.set_c(OFF_X + ax, OFF_Y + 4, "W" if ax >= 20 else "k")
				can.set_vfx(OFF_X + 22, OFF_Y + 1, white_c)
			elif dir == "right":
				_draw_seg(can, OFF_X + 21, OFF_Y + 19, OFF_X + 19, OFF_Y + 4, "I")
				for ax in range(13, 21):
					can.set_c(OFF_X + ax, OFF_Y + 2, "A" if ax < 18 else "W")
					can.set_c(OFF_X + ax, OFF_Y + 3, "A" if ax < 18 else "P")
					can.set_c(OFF_X + ax, OFF_Y + 4, "W" if ax >= 18 else "k")
				can.set_vfx(OFF_X + 20, OFF_Y + 1, white_c)
			else:
				_draw_seg(can, OFF_X + 19, OFF_Y + 19, OFF_X + 23, OFF_Y + 4, "I")
				for ax in range(19, 27):
					can.set_c(OFF_X + ax, OFF_Y + 2, "W" if ax < 22 else "A")
					can.set_c(OFF_X + ax, OFF_Y + 3, "P" if ax < 22 else "A")
					can.set_c(OFF_X + ax, OFF_Y + 4, "W" if ax < 22 else "k")
				can.set_vfx(OFF_X + 18, OFF_Y + 1, white_c)
		2: # FULL-BODY CRUNCHING FLOOR SLAM (offset to dominant hand x=29, projecting ahead of feet!)
			can = can.kneel_collapse(2, FOOT_CELL_Y).shift_all(dv.x * 2, dv.y)
			match dir:
				"down":
					_draw_seg(can, 29, 31, 29, 44, "I")
					for bx in range(26, 33):
						can.set_c(bx, 42, "A" if bx < 30 else "W")
						can.set_c(bx, 43, "W" if bx >= 29 else "k")
					# Vertical cleave beam cleanly beside face/chest + floor shockwave ahead of feet!
					_draw_vfx_seg(can, 29, 28, 29, 45, white_c)
					_draw_vfx_seg(can, 28, 30, 28, 44, cleave_c)
					_draw_vfx_seg(can, 30, 30, 30, 44, cleave_c)
					_draw_vfx_seg(can, 20, 44, 26, 43, spark_c)
					_draw_vfx_seg(can, 32, 43, 38, 44, spark_c)
					can.set_vfx(21, 41, white_c)
					can.set_vfx(37, 41, white_c)
				"up":
					_draw_seg(can, 24, 21, 24, 6, "I")
					for bx in range(21, 28):
						can.set_c(bx, 6, "A" if bx < 25 else "W")
						can.set_c(bx, 7, "W" if bx >= 24 else "k")
					_draw_vfx_seg(can, 24, 5, 24, 17, white_c)
					_draw_vfx_seg(can, 17, 7, 21, 5, spark_c)
					_draw_vfx_seg(can, 27, 5, 31, 7, spark_c)
				"left":
					_draw_seg(can, 18, 27, 8, 39, "I")
					for ay in range(36, 41):
						can.set_c(7, ay, "A" if ay < 39 else "W")
						can.set_c(6, ay, "W")
					_draw_vfx_seg(can, 14, 14, 7, 35, white_c)
					_draw_vfx_seg(can, 13, 16, 6, 36, cleave_c)
					_draw_vfx_seg(can, 3, 39, 13, 39, spark_c)
					can.set_vfx(4, 36, white_c)
					can.set_vfx(13, 37, spark_c)
				"right":
					_draw_seg(can, 30, 27, 40, 39, "I")
					for ay in range(36, 41):
						can.set_c(41, ay, "A" if ay < 39 else "W")
						can.set_c(42, ay, "W")
					_draw_vfx_seg(can, 34, 14, 41, 35, white_c)
					_draw_vfx_seg(can, 35, 16, 42, 36, cleave_c)
					_draw_vfx_seg(can, 35, 39, 45, 39, spark_c)
					can.set_vfx(44, 36, white_c)
					can.set_vfx(35, 37, spark_c)
		3: # Embedded hold + lingering dust flecks
			can = can.kneel_collapse(1, FOOT_CELL_Y).shift_all(dv.x, 0)
			if dir == "down":
				_draw_seg(can, 29, 32, 29, 43, "I")
				can.set_c(30, 43, "W")
				can.set_vfx(21, 42, spark_c)
				can.set_vfx(37, 42, spark_c)
			elif dir == "left":
				_draw_seg(can, 18, 29, 9, 39, "I")
				can.set_c(8, 39, "W")
				can.set_vfx(5, 38, spark_c)
			elif dir == "right":
				_draw_seg(can, 30, 29, 39, 39, "I")
				can.set_c(40, 39, "W")
				can.set_vfx(43, 38, spark_c)
			else:
				_draw_seg(can, 24, 21, 24, 8, "I")
				can.set_c(25, 8, "W")
		4: # Heave back up
			can = _compose_pose(spec, mode_cfg, is_dist, dir, "idle")
	return can


# --- 3) Bombeiro Santos: Gancho Lateral Ágil com Barra Halligan (Coiled Whip Uppercut Hook) ---
static func _atk_halligan_hook(spec: Dictionary, mode_cfg: Dictionary, is_dist: bool, dir: String, f_idx: int) -> Canvas48:
	var dv := _dir_vec(dir)
	var pose := "step_b" if f_idx in [1, 2, 3] else "idle"
	var can := _compose_pose(spec, mode_cfg, is_dist, dir, pose)

	if f_idx == 0:
		can = can.shift_upper(-dv.x, 1, OFF_Y + 26)
	elif f_idx == 2:
		can = can.shift_all(dv.x * 2, dv.y)
	elif f_idx == 3:
		can = can.shift_all(dv.x, 0)

	var hook_c := c("#FF405A") if is_dist else c("#5EE8FF")
	var edge_c := c("#FFCFD6") if is_dist else c("#F0FCFF")

	match f_idx:
		0: # Tight spring crouch w/ red Halligan behind front hip
			match dir:
				"down": _draw_seg(can, OFF_X + 10, OFF_Y + 21, OFF_X + 7, OFF_Y + 25, "W")
				"up": _draw_seg(can, OFF_X + 21, OFF_Y + 21, OFF_X + 25, OFF_Y + 25, "W")
				"left": _draw_seg(can, OFF_X + 19, OFF_Y + 22, OFF_X + 25, OFF_Y + 27, "W")
				"right": _draw_seg(can, OFF_X + 12, OFF_Y + 22, OFF_X + 6, OFF_Y + 27, "W")
		1: # Quick launch snapping Halligan forward low
			match dir:
				"down": _draw_seg(can, OFF_X + 10, OFF_Y + 23, OFF_X + 19, OFF_Y + 26, "W")
				"left": _draw_seg(can, OFF_X + 13, OFF_Y + 24, OFF_X + 7, OFF_Y + 28, "W")
				"right": _draw_seg(can, OFF_X + 18, OFF_Y + 24, OFF_X + 24, OFF_Y + 28, "W")
				"up": _draw_seg(can, OFF_X + 21, OFF_Y + 18, OFF_X + 24, OFF_Y + 11, "W")
		2: # DIAGONAL UPWARD HALLIGAN HOOK + COMMA SLASH
			match dir:
				"down":
					_draw_seg(can, 24, 31, 35, 24, "W")
					can.set_c(35, 22, "A") # curved pry fork head
					can.set_c(36, 23, "P")
					_draw_vfx_seg(can, 22, 38, 33, 34, hook_c)
					_draw_vfx_seg(can, 33, 34, 39, 20, edge_c)
					_draw_vfx_seg(can, 26, 36, 37, 22, hook_c)
				"up":
					_draw_seg(can, 24, 20, 14, 12, "W")
					can.set_c(14, 10, "A")
					can.set_c(13, 11, "P")
					_draw_vfx_seg(can, 32, 16, 21, 10, hook_c)
					_draw_vfx_seg(can, 21, 10, 12, 13, edge_c)
				"left":
					_draw_seg(can, 15, 29, 6, 20, "W")
					can.set_c(5, 19, "A")
					can.set_c(7, 18, "P")
					_draw_vfx_seg(can, 14, 36, 6, 29, hook_c)
					_draw_vfx_seg(can, 6, 29, 5, 16, edge_c)
					_draw_vfx_seg(can, 11, 34, 4, 21, hook_c)
				"right":
					_draw_seg(can, 33, 29, 42, 20, "W")
					can.set_c(43, 19, "A")
					can.set_c(41, 18, "P")
					_draw_vfx_seg(can, 34, 36, 42, 29, hook_c)
					_draw_vfx_seg(can, 42, 29, 43, 16, edge_c)
					_draw_vfx_seg(can, 37, 34, 44, 21, hook_c)
		3: # Recoil follow-through
			match dir:
				"down":
					_draw_seg(can, 24, 29, 31, 24, "W")
					can.set_vfx(36, 20, edge_c)
				"up":
					_draw_seg(can, 23, 20, 17, 14, "W")
					can.set_vfx(13, 12, edge_c)
				"left":
					_draw_seg(can, 15, 28, 8, 21, "W")
					can.set_vfx(5, 17, edge_c)
				"right":
					_draw_seg(can, 33, 28, 40, 21, "W")
					can.set_vfx(43, 17, edge_c)
	return can


# --- 4) Enfermeira Maria: Estocada Cirúrgica Linear com Bisturi (PURE Linear Thrust + Star Tip Glint) ---
static func _atk_scalpel_thrust(spec: Dictionary, mode_cfg: Dictionary, is_dist: bool, dir: String, f_idx: int) -> Canvas48:
	var dv := _dir_vec(dir)
	var can := _compose_pose(spec, mode_cfg, is_dist, dir, "idle")

	var beam_c := c("#FF334B") if is_dist else c("#7EE0FF")
	var white_c := c("#FFD6DE") if is_dist else c("#F7FDFF")

	# Tucked clipboard on opposite hand during coiled/thrust frames (character silhouette cue!)
	if f_idx in [0, 1, 2] and dir in ["down", "left", "right"]:
		var cx := 19 if dir == "down" else (24 if dir == "left" else 23)
		can.set_c(cx, 29, "N")
		can.set_c(cx + 1, 29, "N")
		can.set_c(cx, 30, "R" if is_dist else "I")

	match f_idx:
		0: # Coiled pull-back holding scalpel tight beside cheek/rib
			can = can.shift_upper(-dv.x, 0, OFF_Y + 26)
			if dir == "down": can.set_c(OFF_X + 10, OFF_Y + 20, "P")
			elif dir == "left": can.set_c(OFF_X + 18, OFF_Y + 21, "P")
			elif dir == "right": can.set_c(OFF_X + 13, OFF_Y + 21, "P")
			else: can.set_c(OFF_X + 21, OFF_Y + 19, "P")
		1: # Tense pre-lunge alignment (dominant hand side clear of face)
			can = can.shift_upper(dv.x, 1, OFF_Y + 25)
			if dir == "down": _draw_seg(can, 30, 30, 30, 35, "P")
			elif dir == "left": _draw_seg(can, 19, 29, 13, 29, "P")
			elif dir == "right": _draw_seg(can, 29, 29, 35, 29, "P")
			else: _draw_seg(can, 29, 24, 29, 18, "P")
		2: # RAZOR LINEAR SURGICAL THRUST (Down punches cleanly along x=30 ahead of feet!)
			can = can.shift_all(dv.x * 3, dv.y)
			match dir:
				"down":
					_draw_seg(can, 30, 31, 30, 41, "W")
					can.set_c(30, 42, "P")
					_draw_vfx_seg(can, 30, 30, 30, 46, beam_c)
					_draw_vfx_seg(can, 30, 34, 30, 45, white_c)
					for gp: Vector2i in [Vector2i(28, 45), Vector2i(32, 45), Vector2i(30, 43), Vector2i(30, 47)]:
						can.set_vfx(gp.x, gp.y, white_c)
				"up":
					_draw_seg(can, 27, 22, 27, 13, "W")
					can.set_c(27, 12, "P")
					_draw_vfx_seg(can, 27, 20, 27, 5, beam_c)
					_draw_vfx_seg(can, 27, 16, 27, 6, white_c)
					for gp: Vector2i in [Vector2i(25, 6), Vector2i(29, 6), Vector2i(27, 4), Vector2i(27, 8)]:
						can.set_vfx(gp.x, gp.y, white_c)
				"left":
					_draw_seg(can, 20, 30, 10, 30, "W")
					can.set_c(9, 30, "P")
					_draw_vfx_seg(can, 21, 30, 3, 30, beam_c)
					_draw_vfx_seg(can, 15, 30, 4, 30, white_c)
					for gp: Vector2i in [Vector2i(4, 28), Vector2i(4, 32), Vector2i(2, 30), Vector2i(6, 30)]:
						can.set_vfx(gp.x, gp.y, white_c)
				"right":
					_draw_seg(can, 28, 30, 38, 30, "W")
					can.set_c(39, 30, "P")
					_draw_vfx_seg(can, 27, 30, 45, 30, beam_c)
					_draw_vfx_seg(can, 33, 30, 44, 30, white_c)
					for gp: Vector2i in [Vector2i(44, 28), Vector2i(44, 32), Vector2i(42, 30), Vector2i(46, 30)]:
						can.set_vfx(gp.x, gp.y, white_c)
		3: # Held linear pierce w/ subtle cross flicker
			can = can.shift_all(dv.x * 2, 0)
			if dir == "down":
				_draw_seg(can, 30, 31, 30, 38, "P")
				can.set_vfx(30, 43, beam_c)
			elif dir == "left":
				_draw_seg(can, 18, 30, 11, 30, "P")
				can.set_vfx(6, 30, beam_c)
			elif dir == "right":
				_draw_seg(can, 30, 30, 37, 30, "P")
				can.set_vfx(42, 30, beam_c)
			else:
				_draw_seg(can, 27, 22, 27, 15, "P")
				can.set_vfx(27, 8, beam_c)
	return can


static func _dir_vec(dir: String) -> Vector2i:
	match dir:
		"down": return Vector2i(0, 1)
		"up": return Vector2i(0, -1)
		"left": return Vector2i(-1, 0)
		"right": return Vector2i(1, 0)
	return Vector2i.ZERO


# ---------------------------------------------------------------------------
# Organic Collapse & Horizontal Fallen Death (6f @ 8fps, anchored y=39)
# ---------------------------------------------------------------------------
static func _render_death(spec: Dictionary, mode_cfg: Dictionary, is_dist: bool, pal: Dictionary, dir: String, f_idx: int) -> Image:
	if f_idx <= 3:
		var can := _compose_pose(spec, mode_cfg, is_dist, dir, "idle")
		match f_idx:
			0:
				var dv := _dir_vec(dir)
				can = can.shift_upper(-dv.x * 2, 0, OFF_Y + 25)
				_apply_blink(can, dir, spec)
				can.set_vfx(OFF_X + 12, OFF_Y + 14, c("#FFF5D6"))
			1:
				can = can.kneel_collapse(2, FOOT_CELL_Y)
				_apply_blink(can, dir, spec)
			2:
				can = can.kneel_collapse(4, FOOT_CELL_Y)
				_apply_blink(can, dir, spec)
			3:
				can = can.kneel_collapse(6, FOOT_CELL_Y)
				_apply_blink(can, dir, spec)
		return can.bake(pal, f_idx == 0)

	if int(spec.get("batch", 1)) == 2:
		return Lote2.render_death(_self_script(), spec, mode_cfg, is_dist, pal, dir, f_idx)
	# Frames 4..5: Distinct organic fallen poses per NPC anchored strictly at cell y = 39!
	var head_id: String = str(spec["head_id"])
	var head_left := not (dir in ["right", "down"])
	var can := Canvas48.new()
	var gy := FOOT_CELL_Y # y = 39

	if head_id == "ato":
		# Bombeiro Ato: HEAVY FACE-DOWN PRONE SPRAWL + helmet still tilted over brow + outstretched arm!
		var ax0 := 13 if head_left else 34
		var sgn := 1 if head_left else -1
		# Face-down amber helmet pressed onto ground + dark neck drape (hides face cleanly!)
		for step in range(6):
			for ry in range(gy - 6, gy):
				var px := ax0 + step * sgn
				if step == 0 or ry == gy - 6:
					can.set_c(px, ry, "c")
				elif step >= 4:
					can.set_c(px, ry, "V" if ry > gy - 5 else "c")
				else:
					can.set_c(px, ry, "B" if (ry == gy - 5 and step == 2) else "H")
		can.set_c(ax0 + 2 * sgn, gy - 4, "G")
		if is_dist:
			can.set_c(ax0 + 3 * sgn, gy - 4, "c") # cracked visor line
		# Outstretched forward forearm pressing into dirt next to helmet
		for arm_s in range(3):
			can.set_c(ax0 - (1 + arm_s) * sgn, gy - 1, "p" if arm_s == 2 else "j")
			can.set_c(ax0 - (1 + arm_s) * sgn, gy, "k")
		# Heavy broad humped turnout back w/ dual stripes + diagonal black hose coil
		for step in range(6, 15):
			var px := ax0 + step * sgn
			for ry in range(gy - 6, gy + 1):
				if ry == gy - 6 or ry == gy:
					can.set_c(px, ry, "k")
				elif step == 8:
					can.set_c(px, ry, "Z")
				elif step == 10:
					can.set_c(px, ry, "Y")
				elif step == 12 and ry <= gy - 2:
					can.set_c(px, ry, "X")
				else:
					can.set_c(px, ry, "m" if ry >= gy - 2 else "j")
		# Legs & boots flat behind (anchored at gy = 39)
		for step in range(15, 22):
			var px := ax0 + step * sgn
			for ry in range(gy - 4, gy + 1):
				if ry == gy - 4 or ry == gy or step == 21:
					can.set_c(px, ry, "k")
				elif step >= 19:
					can.set_c(px, ry, "z" if ry == gy - 3 else "t")
				else:
					can.set_c(px, ry, "v" if ry >= gy - 1 else "o")
		if is_dist:
			can.set_vfx(ax0 + 11 * sgn, gy - 5, c("#FF4238"))
		return can.bake(pal, false)

	# Reyes, Santos & Maria use organic BASE_FALLEN base (shifted +1 to land on y=39) + custom variation!
	var grid: Array[String] = Templates.BASE_FALLEN
	if not head_left:
		grid = Templates.mirror_grid_h(grid)
	_stamp_32(can, grid, false)
	can = can.shift_all(0, 1)

	var hx := OFF_X + (4 if head_left else 19)
	var dx_out := -1 if head_left else 1
	var outfit: String = str(spec["outfit_style"])

	if outfit == "nurse_labcoat":
		# Light coat torso/skirt overhang
		for ox in range(13, 19):
			var mx := OFF_X + (ox if head_left else 31 - ox)
			if can.get_c(mx, gy - 3) in ["j", "m"]:
				can.set_c(mx, gy - 3, "T")
			if is_dist and ox == 16:
				can.set_c(mx, gy - 3, "R")
				can.set_c(mx + 1, gy - 2, "R")

	# Closed eyelid dash on fallen face
	can.set_c(hx + (3 if head_left else 5), gy - 2, "r")

	if head_id == "reyes":
		# Side/back collapse with EXPOSED salt-and-pepper hair + mustache + DROPPED OFFICER CAP beside head!
		var cx := hx + (1 if head_left else 6)
		for step in range(3):
			for y in range(gy - 6, gy):
				can.set_c(cx + step * dx_out, y, "c" if (step == 2 or y == gy - 6) else ("b" if y == gy - 5 else "h"))
		can.set_c(hx + (2 if head_left else 5), gy - 1, "M")
		can.set_c(hx + (3 if head_left else 4), gy - 1, "M")
		# Dropped peaked BFP officer cap lying slightly tilted on the floor (gy-2..gy) beside his head!
		var cap_x := cx + 4 * dx_out
		for step in range(4):
			for y in range(gy - 3, gy + 1):
				var px := cap_x + step * dx_out
				if step == 3 or y == gy or y == gy - 3:
					can.set_c(px, y, "c")
				elif y == gy - 1:
					can.set_c(px, y, "V")
				else:
					can.set_c(px, y, "G" if step == 1 else "H")

	elif head_id == "santos":
		# Bent-knee side collapse: rear knee tucked +2px up + curly afro w/ rim light!
		var cx := hx + (0 if head_left else 7)
		for step in range(4):
			for y in range(gy - 7, gy):
				if step == 3 or (step == 2 and (y == gy - 7 or y == gy - 1)):
					can.set_c(cx + step * dx_out, y, "u" if y <= gy - 4 else "c")
				else:
					can.set_c(cx + step * dx_out, y, "b" if (step == 1 and y == gy - 5) else "h")
		# Curl the top leg into an organic bent knee peak instead of straight horizontal line
		var kx := OFF_X + (21 if head_left else 9)
		for step in range(3):
			can.set_c(kx + step * (-dx_out), gy - 5 - (1 if step == 1 else 0), "k")
			can.set_c(kx + step * (-dx_out), gy - 4 - (1 if step == 1 else 0), "o")

	elif head_id == "maria":
		# Slender side-slump w/ parted hair & bun + DROPPED NURSE CLIPBOARD beside hand at gy=39!
		var cx := hx + (1 if head_left else 7)
		for step in range(3):
			for y in range(gy - 6, gy):
				can.set_c(cx + step * dx_out, y, "c" if (step == 2 or y == gy - 6) else "h")
		var bx := cx + 2 * dx_out
		can.set_c(bx, gy - 4, "a")
		can.set_c(bx + dx_out, gy - 4, "h")
		can.set_c(bx + dx_out, gy - 3, "h")
		can.set_c(bx + dx_out * 2, gy - 4, "c")
		can.set_c(bx + dx_out * 2, gy - 3, "c")
		can.set_c(bx + dx_out, gy - 5, "c")
		can.set_c(bx + dx_out, gy - 2, "c")
		# Dropped white clipboard (with crimson blotch if distorted) resting cleanly on floor beside her!
		var cbx := cx + 4 * dx_out
		for step in range(3):
			for y in range(gy - 2, gy + 1):
				var px := cbx + step * dx_out
				if y == gy or y == gy - 2 or step == 2:
					can.set_c(px, y, "k")
				elif is_dist and step == 1:
					can.set_c(px, y, "R")
				else:
					can.set_c(px, y, "I" if step == 0 else "N")

	# Final frames ember/corrupted glow when distorted
	if is_dist:
		can.set_vfx(OFF_X + 15, gy - 4, c("#FF4238"))
		if f_idx == 5:
			can.set_vfx(OFF_X + 18, gy - 5, c("#C41E2B"))

	return can.bake(pal, false)


# ---------------------------------------------------------------------------
# Godot .import & SpriteFrames .tres Export (Exact huwag_v3 Compatibility)
# ---------------------------------------------------------------------------
static func _write_pixel_art_import(res_path: String, abs_png_path: String) -> void:
	var uid := ResourceUID.create_id()
	var uid_str := ResourceUID.id_to_text(uid)
	var content := """[remap]

importer="texture"
type="CompressedTexture2D"
uid="%s"
path=""
metadata={
"vram_texture": false
}

[deps]

source_file="%s"
dest_files=[]

[params]

compress/mode=0
compress/high_quality=false
compress/lossy_quality=0.7
compress/uastc_level=0
compress/rdo_quality_loss=0.0
compress/hdr_compression=1
compress/normal_map=0
compress/channel_pack=0
mipmaps/generate=false
mipmaps/limit=-1
roughness/mode=0
roughness/src_normal=""
process/channel_remap/red=0
process/channel_remap/green=1
process/channel_remap/blue=2
process/channel_remap/alpha=3
process/fix_alpha_border=true
process/premult_alpha=false
process/normal_map_invert_y=false
process/hdr_as_srgb=false
process/hdr_clamp_exposure=false
process/size_limit=0
detect_3d/compress_to=1
""" % [uid_str, res_path]
	var f := FileAccess.open(abs_png_path + ".import", FileAccess.WRITE)
	if f:
		f.store_string(content)
		f.close()


static func _write_spriteframes_tres(tres_res_path: String, sheets_info: Dictionary, anim_list: Array) -> void:
	var ext_lines: Array[String] = []
	var ext_ids := {}
	var ext_idx := 1
	for anim_cfg in anim_list:
		var aname: String = str(anim_cfg["name"])
		var path: String = str(sheets_info[aname]["path"])
		var eid := "%d_%s" % [ext_idx, aname]
		ext_ids[aname] = eid
		ext_lines.append('[ext_resource type="Texture2D" path="%s" id="%s"]' % [path, eid])
		ext_idx += 1

	var sub_lines: Array[String] = []
	var anim_entries: Array[String] = []

	for anim_cfg in anim_list:
		var aname: String = str(anim_cfg["name"])
		var fcount: int = int(anim_cfg["frames"])
		var fps: float = float(anim_cfg["fps"])
		var does_loop: bool = bool(anim_cfg["loop"])
		var eid: String = str(ext_ids[aname])

		for dir_idx in range(DIRS.size()):
			var dir_name: String = DIRS[dir_idx]
			var frame_refs: Array[String] = []
			for f in range(fcount):
				var sub_id := "AtlasTexture_%s_%s_%d" % [aname, dir_name, f]
				sub_lines.append('[sub_resource type="AtlasTexture" id="%s"]' % sub_id)
				sub_lines.append('atlas = ExtResource("%s")' % eid)
				sub_lines.append('region = Rect2(%d, %d, %d, %d)' % [f * CELL_W, dir_idx * CELL_H, CELL_W, CELL_H])
				sub_lines.append("")
				frame_refs.append('{\n"duration": 1.0,\n"texture": SubResource("%s")\n}' % sub_id)

			anim_entries.append("""{
"frames": [%s],
"loop": %s,
"name": &"%s_%s",
"speed": %.1f
}""" % [", ".join(frame_refs), "true" if does_loop else "false", aname, dir_name, fps])

	var header := '[gd_resource type="SpriteFrames" load_steps=%d format=3]\n\n' % (ext_idx + sub_lines.size() / 4 + 1)
	var body := "%s\n\n%s\n[resource]\nanimations = [%s]\n" % [
		"\n".join(ext_lines),
		"\n".join(sub_lines),
		", ".join(anim_entries),
	]

	var abs_tres := ProjectSettings.globalize_path(tres_res_path)
	var f := FileAccess.open(abs_tres, FileAccess.WRITE)
	if f:
		f.store_string(header + body)
		f.close()
