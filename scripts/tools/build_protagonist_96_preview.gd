extends SceneTree

# ==============================================================================
# GERADOR DE SPRITESHEETS 96x96 — V4 (CABELO MASCULINO EM MECHAS + EMPUNHADURA 2 MÃOS)
# Protagonista: Huwag (Ramon Dela Cruz) — Variantes BFP e Casual
# ==============================================================================

const CELL_W: int = 96
const CELL_H: int = 96
const COLS: int = 38
const ROWS: int = 8

enum Dir {
	DOWN = 0,
	LEFT = 1,
	RIGHT = 2,
	UP = 3,
	DOWN_LEFT = 4,
	DOWN_RIGHT = 5,
	UP_LEFT = 6,
	UP_RIGHT = 7
}

const INK: Color = Color8(18, 12, 22, 255)
const SHADOW_GROUND_INNER: Color = Color8(22, 14, 30, 225)
const SHADOW_GROUND_OUTER: Color = Color8(36, 24, 48, 180)

func _init() -> void:
	print("=== Gerando Protagonista Huwag V4 em 96x96 (38x8) ===")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://assets/characters/huwag"))

	var bfp_sheet: Image = _build_huwag_sheet(true)
	var casual_sheet: Image = _build_huwag_sheet(false)

	var err_bfp: Error = bfp_sheet.save_png("res://assets/characters/huwag/bfp_sheet.png")
	var err_cas: Error = casual_sheet.save_png("res://assets/characters/huwag/casual_sheet.png")
	print("Saved bfp_sheet.png: ", err_bfp, " | casual_sheet.png: ", err_cas)

	var preview: Image = _build_showcase_preview(bfp_sheet, casual_sheet)
	var preview_path: String = "C:/Users/SnyX/.gemini/antigravity/brain/41e1f3b5-4735-42d2-bd7e-9b58f3903223/huwag_96x96_approval_preview.png"
	preview.save_png(preview_path)
	print("Saved preview to: ", preview_path)
	print("=== Concluido V4! ===")
	quit(0)


func _build_huwag_sheet(is_bfp: bool) -> Image:
	var sheet: Image = Image.create(COLS * CELL_W, ROWS * CELL_H, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0, 0, 0, 0))
	var pal: Dictionary = _get_palettes(is_bfp)

	for row in range(ROWS):
		for col in range(COLS):
			var cell: Image = Image.create(CELL_W, CELL_H, false, Image.FORMAT_RGBA8)
			cell.fill(Color(0, 0, 0, 0))
			_draw_huwag_frame(cell, row, col, pal, is_bfp)
			sheet.blit_rect(cell, Rect2i(0, 0, CELL_W, CELL_H), Vector2i(col * CELL_W, row * CELL_H))

	return sheet


func _get_palettes(is_bfp: bool) -> Dictionary:
	var skin: Array[Color] = [
		Color8(116, 66, 52),
		Color8(164, 102, 78),
		Color8(210, 142, 110),
		Color8(240, 182, 148),
		Color8(254, 218, 192)
	]
	var hair: Array[Color] = [
		Color8(20, 16, 30),
		Color8(36, 30, 52),
		Color8(58, 48, 82),
		Color8(92, 78, 124),
		Color8(142, 126, 176)
	]
	var boots: Array[Color] = [
		Color8(24, 18, 30),
		Color8(46, 36, 56),
		Color8(74, 60, 88),
		Color8(114, 96, 132)
	]
	var axe_wood: Array[Color] = [
		Color8(72, 38, 26),
		Color8(114, 64, 42),
		Color8(158, 96, 62),
		Color8(202, 138, 94)
	]
	var axe_red: Array[Color] = [
		Color8(104, 18, 30),
		Color8(164, 28, 44),
		Color8(222, 52, 66),
		Color8(255, 118, 122)
	]
	var axe_steel: Array[Color] = [
		Color8(84, 98, 122),
		Color8(136, 154, 182),
		Color8(198, 216, 238),
		Color8(250, 254, 255)
	]
	var belt_pal: Array[Color] = [
		Color8(28, 20, 26),
		Color8(56, 40, 48),
		Color8(88, 66, 74),
		Color8(232, 184, 78)
	]

	if is_bfp:
		return {
			"skin": skin,
			"hair": hair,
			"coat": [
				Color8(20, 26, 44),
				Color8(34, 46, 74),
				Color8(54, 74, 112),
				Color8(86, 112, 158)
			],
			"inner": [
				Color8(108, 26, 34),
				Color8(156, 38, 48),
				Color8(204, 62, 68),
				Color8(242, 106, 104)
			],
			"trim": [
				Color8(146, 76, 18),
				Color8(214, 130, 28),
				Color8(250, 192, 56),
				Color8(255, 244, 164)
			],
			"pants": [
				Color8(18, 22, 36),
				Color8(32, 40, 62),
				Color8(50, 64, 94),
				Color8(78, 96, 134)
			],
			"helmet": [
				Color8(132, 68, 16),
				Color8(194, 114, 24),
				Color8(242, 168, 42),
				Color8(255, 228, 118)
			],
			"glove": [
				Color8(28, 22, 36),
				Color8(50, 40, 64),
				Color8(78, 64, 96),
				Color8(112, 94, 132)
			],
			"boots": boots,
			"belt": belt_pal,
			"axe_wood": axe_wood,
			"axe_red": axe_red,
			"axe_steel": axe_steel
		}
	else:
		return {
			"skin": skin,
			"hair": hair,
			"coat": [
				Color8(28, 44, 48),
				Color8(46, 70, 76),
				Color8(72, 106, 114),
				Color8(108, 150, 158)
			],
			"inner": [
				Color8(134, 118, 108),
				Color8(178, 160, 148),
				Color8(218, 204, 192),
				Color8(246, 236, 226)
			],
			"trim": [
				Color8(62, 88, 94),
				Color8(92, 126, 134),
				Color8(126, 166, 176),
				Color8(168, 208, 216)
			],
			"pants": [
				Color8(34, 28, 44),
				Color8(54, 46, 68),
				Color8(80, 70, 98),
				Color8(114, 102, 134)
			],
			"helmet": hair,
			"glove": skin,
			"boots": boots,
			"belt": belt_pal,
			"axe_wood": axe_wood,
			"axe_red": axe_red,
			"axe_steel": axe_steel
		}


func _compute_pose(row: int, col: int) -> Dictionary:
	var dir_x: float = 0.0
	var dir_y: float = 1.0
	match row:
		Dir.DOWN: dir_x = 0.0; dir_y = 1.0
		Dir.LEFT: dir_x = -1.0; dir_y = 0.0
		Dir.RIGHT: dir_x = 1.0; dir_y = 0.0
		Dir.UP: dir_x = 0.0; dir_y = -1.0
		Dir.DOWN_LEFT: dir_x = -0.707; dir_y = 0.707
		Dir.DOWN_RIGHT: dir_x = 0.707; dir_y = 0.707
		Dir.UP_LEFT: dir_x = -0.707; dir_y = -0.707
		Dir.UP_RIGHT: dir_x = 0.707; dir_y = -0.707

	var p: Dictionary = {
		"dir_x": dir_x,
		"dir_y": dir_y,
		"anim": "idle",
		"frame_idx": 0,
		"body_x": 0.0,
		"body_y": 0.0,
		"torso_lean": 0.0,
		"torso_twist": 0.0,
		"chest_breathe": 0.0,
		"head_nod": 0.0,
		"lag": 0.0,
		"coat_flare": 0.9,
		"l_foot": Vector2(-8.2, 0.0),
		"r_foot": Vector2(8.2, 0.0),
		"l_knee_bend": 1.6,
		"r_knee_bend": 1.6,
		"l_arm_ang": 0.45,
		"r_arm_ang": -0.45,
		"l_elbow_bend": 0.5,
		"r_elbow_bend": 0.65,
		"axe_mode": "carry",
		"axe_angle": -0.35,
		"slash_stage": -1,
		"blink": false,
		"collapse": 0.0,
		"shadow_scale": 1.0
	}

	var face_sign: float = -1.0 if dir_x < -0.1 else (1.0 if dir_x > 0.1 else 1.0)

	if col <= 5:
		p["anim"] = "idle"
		var f: int = col
		p["frame_idx"] = f
		var phase: float = float(f) / 6.0 * TAU
		var lag_phase: float = phase - 0.95
		p["body_y"] = round(sin(phase) * 1.4)
		p["chest_breathe"] = sin(phase) * 1.0
		p["head_nod"] = sin(lag_phase) * 0.8
		p["lag"] = sin(lag_phase) * 1.8
		p["coat_flare"] = 1.0 + 0.55 * sin(lag_phase)
		p["l_foot"] = Vector2(-8.4, 0.5 * face_sign)
		p["r_foot"] = Vector2(8.4, -0.5 * face_sign)
		p["l_knee_bend"] = 1.6 + 0.5 * maxf(0.0, sin(phase))
		p["r_knee_bend"] = 1.6 + 0.5 * maxf(0.0, sin(phase))
		p["l_arm_ang"] = 0.48 + 0.14 * sin(phase)
		p["r_arm_ang"] = -0.45 - 0.14 * sin(lag_phase)
		p["axe_angle"] = -0.28 + 0.12 * sin(lag_phase)
		p["blink"] = (f == 4)
	elif col <= 13:
		p["anim"] = "walk"
		var f: int = col - 6
		p["frame_idx"] = f
		var phase: float = float(f) / 8.0 * TAU
		var lag_phase: float = phase - 0.85
		var stride: float = sin(phase)
		var lift_l: float = maxf(0.0, -cos(phase))
		var lift_r: float = maxf(0.0, cos(phase))
		var bob_table: Array[float] = [1.0, 2.2, 0.0, -1.2, 1.0, 2.2, 0.0, -1.2]
		p["body_y"] = bob_table[f]
		p["torso_lean"] = 1.6
		p["torso_twist"] = stride * 0.45
		p["lag"] = cos(lag_phase) * 2.6
		p["coat_flare"] = 1.7 + abs(stride) * 1.4

		if abs(dir_x) > 0.25:
			var step_x: float = face_sign * 8.5
			p["l_foot"] = Vector2(-4.5 + stride * step_x, stride * dir_y * 2.2 - lift_l * 5.2)
			p["r_foot"] = Vector2(4.5 - stride * step_x, -stride * dir_y * 2.2 - lift_r * 5.2)
		else:
			p["l_foot"] = Vector2(-6.5, stride * 5.2 * sign(dir_y) - lift_l * 4.8)
			p["r_foot"] = Vector2(6.5, -stride * 5.2 * sign(dir_y) - lift_r * 4.8)

		p["l_knee_bend"] = 2.0 + lift_l * 4.2
		p["r_knee_bend"] = 2.0 + lift_r * 4.2
		p["l_arm_ang"] = -stride * 0.82
		p["r_arm_ang"] = stride * 0.72
		p["axe_angle"] = -0.36 + stride * 0.28
		p["shadow_scale"] = 1.0 + abs(stride) * 0.12
	elif col <= 21:
		p["anim"] = "run"
		var f: int = col - 14
		p["frame_idx"] = f
		var phase: float = float(f) / 8.0 * TAU
		var lag_phase: float = phase - 0.95
		var stride: float = sin(phase)
		var lift_l: float = maxf(0.0, -cos(phase))
		var lift_r: float = maxf(0.0, cos(phase))
		var bob_table: Array[float] = [1.5, 2.8, -1.2, -2.8, 1.5, 2.8, -1.2, -2.8]
		p["body_y"] = bob_table[f]
		p["torso_lean"] = 4.2
		p["torso_twist"] = stride * 0.75
		p["lag"] = cos(lag_phase) * 3.8 + 2.4
		p["coat_flare"] = 3.2 + abs(stride) * 2.0

		if abs(dir_x) > 0.25:
			var step_x: float = face_sign * 12.5
			p["l_foot"] = Vector2(-4.0 + stride * step_x, stride * dir_y * 2.5 - lift_l * 7.8)
			p["r_foot"] = Vector2(4.0 - stride * step_x, -stride * dir_y * 2.5 - lift_r * 7.8)
		else:
			p["l_foot"] = Vector2(-6.8, stride * 6.8 * sign(dir_y) - lift_l * 7.2)
			p["r_foot"] = Vector2(6.8, -stride * 6.8 * sign(dir_y) - lift_r * 7.2)

		p["l_knee_bend"] = 2.8 + lift_l * 5.5
		p["r_knee_bend"] = 2.8 + lift_r * 5.5
		p["l_arm_ang"] = -stride * 1.18
		p["r_arm_ang"] = stride * 1.05
		p["l_elbow_bend"] = 0.95
		p["r_elbow_bend"] = 0.95
		p["axe_angle"] = -0.62 + stride * 0.38
		p["shadow_scale"] = 0.88 + abs(stride) * 0.25
	elif col <= 27:
		p["anim"] = "attack"
		var f: int = col - 22
		p["frame_idx"] = f
		p["axe_mode"] = "swing"
		match f:
			0:
				p["body_x"] = -face_sign * 3.0 if abs(dir_x) > 0.2 else 0.0
				p["body_y"] = 1.0
				p["torso_lean"] = -2.2
				p["torso_twist"] = -0.75
				p["lag"] = -2.0
				p["coat_flare"] = 2.0
				p["l_foot"] = Vector2(-9.5, -dir_y * 1.5)
				p["r_foot"] = Vector2(8.5, dir_y * 1.5)
				p["axe_angle"] = -1.95
			1:
				p["body_x"] = -face_sign * 5.0 if abs(dir_x) > 0.2 else 0.0
				p["body_y"] = 2.5
				p["torso_lean"] = -3.5
				p["torso_twist"] = -1.05
				p["lag"] = -3.2
				p["coat_flare"] = 2.8
				p["l_foot"] = Vector2(-11.0, -dir_y * 2.0)
				p["r_foot"] = Vector2(9.0, dir_y * 2.0)
				p["l_knee_bend"] = 3.8
				p["r_knee_bend"] = 3.2
				p["axe_angle"] = -2.45
				p["slash_stage"] = 0
			2:
				p["body_x"] = face_sign * 6.5 if abs(dir_x) > 0.2 else 0.0
				p["body_y"] = 4.8
				p["torso_lean"] = 5.2
				p["torso_twist"] = 0.95
				p["lag"] = 4.5
				p["coat_flare"] = 4.2
				if face_sign < 0.0:
					p["l_foot"] = Vector2(-14.5, 2.0)
					p["r_foot"] = Vector2(12.5, -1.0)
					p["l_knee_bend"] = 5.2
					p["r_knee_bend"] = 0.8
				else:
					p["l_foot"] = Vector2(-12.5, -1.0)
					p["r_foot"] = Vector2(14.5, 2.0)
					p["l_knee_bend"] = 0.8
					p["r_knee_bend"] = 5.2
				p["axe_angle"] = 0.52
				p["slash_stage"] = 1
				p["shadow_scale"] = 1.38
			3:
				p["body_x"] = face_sign * 7.2 if abs(dir_x) > 0.2 else 0.0
				p["body_y"] = 5.5
				p["torso_lean"] = 5.8
				p["torso_twist"] = 1.15
				p["lag"] = 5.0
				p["coat_flare"] = 3.8
				if face_sign < 0.0:
					p["l_foot"] = Vector2(-15.0, 2.2)
					p["r_foot"] = Vector2(13.0, -1.0)
					p["l_knee_bend"] = 5.5
					p["r_knee_bend"] = 0.6
				else:
					p["l_foot"] = Vector2(-13.0, -1.0)
					p["r_foot"] = Vector2(15.0, 2.2)
					p["l_knee_bend"] = 0.6
					p["r_knee_bend"] = 5.5
				p["axe_angle"] = 0.78
				p["slash_stage"] = 2
				p["shadow_scale"] = 1.42
			4:
				p["body_x"] = face_sign * 3.5 if abs(dir_x) > 0.2 else 0.0
				p["body_y"] = 2.5
				p["torso_lean"] = 2.6
				p["torso_twist"] = 0.5
				p["lag"] = 2.2
				p["coat_flare"] = 2.2
				p["l_foot"] = Vector2(-9.5, 0.5)
				p["r_foot"] = Vector2(9.5, 0.5)
				p["l_knee_bend"] = 2.8
				p["r_knee_bend"] = 2.8
				p["axe_angle"] = 0.15
			5:
				p["body_x"] = face_sign * 1.0 if abs(dir_x) > 0.2 else 0.0
				p["body_y"] = 0.8
				p["torso_lean"] = 0.8
				p["lag"] = 0.8
				p["coat_flare"] = 1.2
				p["l_foot"] = Vector2(-8.5, 0.0)
				p["r_foot"] = Vector2(8.5, 0.0)
				p["axe_angle"] = -0.25
	elif col <= 31:
		p["anim"] = "hurt"
		var f: int = col - 28
		p["frame_idx"] = f
		match f:
			0:
				p["body_x"] = -face_sign * 4.0
				p["body_y"] = -1.0
				p["torso_lean"] = -3.8
				p["head_nod"] = -2.8
				p["lag"] = -3.5
				p["coat_flare"] = 3.2
				p["l_foot"] = Vector2(-9.5, 1.0)
				p["r_foot"] = Vector2(8.5, -1.5)
				p["l_arm_ang"] = -1.25
				p["r_arm_ang"] = 1.05
			1:
				p["body_x"] = -face_sign * 6.0
				p["body_y"] = 2.2
				p["torso_lean"] = -4.2
				p["head_nod"] = 1.8
				p["lag"] = -2.6
				p["coat_flare"] = 2.8
				p["l_foot"] = Vector2(-10.5, 1.5)
				p["r_foot"] = Vector2(7.5, 2.0)
				p["l_knee_bend"] = 4.0
				p["r_knee_bend"] = 3.8
				p["l_arm_ang"] = 0.75
				p["r_arm_ang"] = -0.65
			2:
				p["body_x"] = -face_sign * 4.5
				p["body_y"] = 4.2
				p["torso_lean"] = 2.5
				p["head_nod"] = 2.8
				p["lag"] = 1.5
				p["coat_flare"] = 1.8
				p["l_foot"] = Vector2(-9.0, 1.0)
				p["r_foot"] = Vector2(8.5, 1.5)
				p["l_knee_bend"] = 4.8
				p["r_knee_bend"] = 4.5
			3:
				p["body_x"] = -face_sign * 2.0
				p["body_y"] = 1.8
				p["torso_lean"] = 1.2
				p["head_nod"] = 1.0
				p["lag"] = 0.6
				p["coat_flare"] = 1.1
				p["l_knee_bend"] = 2.6
				p["r_knee_bend"] = 2.6
	else:
		p["anim"] = "defeat"
		var f: int = col - 32
		p["frame_idx"] = f
		p["collapse"] = float(f) / 5.0

	return p


func _draw_huwag_frame(img: Image, row: int, col: int, pal: Dictionary, is_bfp: bool) -> void:
	var pose: Dictionary = _compute_pose(row, col)
	var cx: float = 48.0 + float(pose["body_x"])
	var ground_y: float = 82.0

	if String(pose["anim"]) == "defeat" and int(pose["frame_idx"]) >= 2:
		_draw_defeat_sequence(img, row, int(pose["frame_idx"]), cx, ground_y, pal, is_bfp)
		return

	var sh_scale: float = float(pose["shadow_scale"])
	_draw_ground_shadow(img, cx, ground_y + 1.0, 19.0 * sh_scale, 4.8)

	var dir_x: float = float(pose["dir_x"])
	var dir_y: float = float(pose["dir_y"])
	var body_y: float = float(pose["body_y"])
	if String(pose["anim"]) == "defeat":
		var cf: int = int(pose["frame_idx"])
		body_y += float(cf + 1) * 4.0
		pose["torso_lean"] = float(cf + 1) * 2.5
		pose["l_knee_bend"] = 4.0 + float(cf) * 2.8
		pose["r_knee_bend"] = 4.0 + float(cf) * 2.8

	var lean_x: float = dir_x * float(pose["torso_lean"])
	var lean_y: float = abs(float(pose["torso_lean"])) * 0.35
	var hip_center: Vector2 = Vector2(cx + lean_x * 0.4, 57.5 + body_y)
	var shoulder_center: Vector2 = Vector2(cx + lean_x, 44.0 + body_y + lean_y - float(pose["chest_breathe"]) * 0.7)
	var head_center: Vector2 = Vector2(shoulder_center.x + dir_x * 0.8, shoulder_center.y - 9.4 + float(pose["head_nod"]) * 0.5)

	var is_back: bool = (dir_y < -0.25)
	var is_profile: bool = (abs(dir_x) > 0.85)
	var hip_spread: float = 4.2 if not is_profile else 2.0
	var sh_spread: float = 6.8 if not is_profile else 3.2

	var right_is_far: bool = (dir_x < -0.1)
	var left_is_far: bool = (dir_x > 0.1)

	var part: Image = Image.create(CELL_W, CELL_H, false, Image.FORMAT_RGBA8)

	# LAYER 1: Back Coat Flap
	if not is_back:
		part.fill(Color(0, 0, 0, 0))
		_draw_coat_tails(part, hip_center, dir_x, dir_y, float(pose["coat_flare"]), float(pose["lag"]), pal, is_bfp, true)
		_stamp_outlined_part(img, part, INK)

	# LAYER 2: Back-carried weapon when facing UP
	if is_back and String(pose["axe_mode"]) == "carry":
		part.fill(Color(0, 0, 0, 0))
		_draw_axe_and_arms(part, shoulder_center, sh_spread, row, pose, pal, is_bfp, true)
		_stamp_outlined_part(img, part, INK)

	# LAYER 3 & 4: Articulated Legs + Separate Outlined Boots
	var l_hip: Vector2 = hip_center + Vector2(-hip_spread, 1.0)
	var r_hip: Vector2 = hip_center + Vector2(hip_spread, 1.0)
	var l_ankle: Vector2 = Vector2(cx + (pose["l_foot"] as Vector2).x, ground_y - 3.0 + (pose["l_foot"] as Vector2).y)
	var r_ankle: Vector2 = Vector2(cx + (pose["r_foot"] as Vector2).x, ground_y - 3.0 + (pose["r_foot"] as Vector2).y)

	if left_is_far:
		_stamp_leg_and_boot(img, part, l_hip, l_ankle, float(pose["l_knee_bend"]), dir_x, pal, true, true)
		_stamp_leg_and_boot(img, part, r_hip, r_ankle, float(pose["r_knee_bend"]), dir_x, pal, false, false)
	else:
		_stamp_leg_and_boot(img, part, r_hip, r_ankle, float(pose["r_knee_bend"]), dir_x, pal, false, right_is_far)
		_stamp_leg_and_boot(img, part, l_hip, l_ankle, float(pose["l_knee_bend"]), dir_x, pal, true, false)

	# LAYER 5: Front/Side Flared Coat Tails
	part.fill(Color(0, 0, 0, 0))
	_draw_coat_tails(part, hip_center, dir_x, dir_y, float(pose["coat_flare"]), float(pose["lag"]), pal, is_bfp, false)
	_stamp_outlined_part(img, part, INK)

	# LAYER 6: Sculpted Torso, Jacket & Tactical Belt
	part.fill(Color(0, 0, 0, 0))
	_draw_sculpted_torso(part, shoulder_center, hip_center, sh_spread, hip_spread, row, pose, pal, is_bfp)
	_stamp_outlined_part(img, part, INK)

	# LAYER 7: Unified Head, Face, Eyes & Spiky Masculine Hair / BFP Helmet
	_stamp_head_and_hair(img, part, head_center, shoulder_center, row, pose, pal, is_bfp)

	# LAYER 8: Foreground 2-Handed Arms & Large Firefighter Axe (both arms gripping & visible!)
	part.fill(Color(0, 0, 0, 0))
	_draw_axe_and_arms(part, shoulder_center, sh_spread, row, pose, pal, is_bfp, false)
	_stamp_outlined_part(img, part, INK)

	# LAYER 9: Solid Distance-Field Crescent Slash Wave
	if int(pose["slash_stage"]) >= 0:
		_draw_slash_arc(img, shoulder_center, row, int(pose["slash_stage"]), is_bfp)


func _stamp_leg_and_boot(img: Image, part: Image, hip: Vector2, ankle: Vector2, knee_bend: float, dir_x: float, pal: Dictionary, is_left: bool, is_far: bool) -> void:
	var pants: Array = pal["pants"]
	var boots: Array = pal["boots"]
	var trim: Array = pal["trim"]

	var mid: Vector2 = (hip + ankle) * 0.5
	var side_push: float = (-2.2 if is_left else 2.2)
	if abs(dir_x) > 0.5:
		side_push = dir_x * knee_bend * 1.25
	else:
		side_push += (-1.0 if is_left else 1.0) * knee_bend * 0.55
	var knee: Vector2 = mid + Vector2(side_push, -0.8 + knee_bend * 0.3)
	var shade_bias: float = -0.22 if is_far else 0.08

	part.fill(Color(0, 0, 0, 0))
	_draw_shaded_limb(part, hip, knee, 3.6, 2.8, pants, shade_bias)
	var upper_calf: Vector2 = knee.lerp(ankle, 0.38) + Vector2(-dir_x * 0.7, 0.0)
	_draw_shaded_limb(part, knee, upper_calf, 2.9, 3.0, pants, shade_bias)
	_draw_shaded_limb(part, upper_calf, ankle, 2.9, 2.2, pants, shade_bias)
	_plot_shaded_disk(part, knee, 2.4, pants, shade_bias + 0.2)
	var cuff_pos: Vector2 = knee.lerp(ankle, 0.68)
	_draw_shaded_limb(part, cuff_pos + Vector2(-1.8, 0.0), cuff_pos + Vector2(1.8, 0.0), 1.3, 1.3, trim, shade_bias)
	_stamp_outlined_part(img, part, INK)

	part.fill(Color(0, 0, 0, 0))
	var toe_dir: float = dir_x
	if abs(toe_dir) < 0.25:
		toe_dir = -0.75 if is_left else 0.75
	var cuff_top: Vector2 = ankle + Vector2(0.0, -1.2)
	var heel: Vector2 = ankle + Vector2(-toe_dir * 1.8, 2.6)
	var toe: Vector2 = ankle + Vector2(toe_dir * 4.5, 2.8)
	_draw_shaded_limb(part, cuff_top, heel, 2.4, 2.3, boots, shade_bias)
	_draw_shaded_limb(part, heel, toe, 2.4, 2.0, boots, shade_bias + 0.15)
	_stamp_outlined_part(img, part, INK)


func _draw_sculpted_torso(buf: Image, sh: Vector2, hip: Vector2, sh_spread: float, hip_spread: float, row: int, pose: Dictionary, pal: Dictionary, is_bfp: bool) -> void:
	var coat: Array = pal["coat"]
	var inner: Array = pal["inner"]
	var trim: Array = pal["trim"]
	var belt: Array = pal["belt"]
	var dir_x: float = float(pose["dir_x"])
	var dir_y: float = float(pose["dir_y"])
	var twist: float = float(pose["torso_twist"])

	var waist: Vector2 = sh.lerp(hip, 0.65)
	var waist_spread: float = lerpf(sh_spread, hip_spread, 0.80) * 0.82

	var steps: int = 16
	for i in range(steps + 1):
		var t: float = float(i) / float(steps)
		var c: Vector2
		var half_w: float
		if t < 0.65:
			var lt: float = t / 0.65
			c = sh.lerp(waist, lt)
			half_w = lerpf(sh_spread + 0.8, waist_spread, sin(lt * PI * 0.5))
		else:
			var lt: float = (t - 0.65) / 0.35
			c = waist.lerp(hip, lt)
			half_w = lerpf(waist_spread, hip_spread + 0.8, lt)

		var iy: int = int(round(c.y))
		var left_x: int = int(round(c.x - half_w))
		var right_x: int = int(round(c.x + half_w))
		for ix in range(left_x, right_x + 1):
			var nx: float = (float(ix) - c.x) / maxf(1.0, half_w)
			var ny: float = (t - 0.45) * 1.2
			var light_val: float = -nx * 0.58 - ny * 0.45 + 0.18
			var col_idx: int = clampi(int(round((light_val + 0.55) * 2.8)), 0, 3)
			var px_col: Color = coat[col_idx]

			if dir_y > -0.1:
				var center_x: float = c.x + dir_x * 2.0 + twist * 1.4
				var dist_center: float = abs(float(ix) - center_x)
				if not is_bfp and dist_center < 2.3 and t < 0.82:
					px_col = inner[clampi(col_idx, 0, 3)]
				elif not is_bfp and dist_center >= 2.3 and dist_center < 3.3 and t < 0.82:
					px_col = INK
				elif is_bfp and dist_center < 1.0 and t < 0.85:
					px_col = trim[3] if (i % 4 == 1) else INK

			if is_bfp and t >= 0.34 and t <= 0.48:
				px_col = trim[clampi(col_idx + 1, 0, 3)]

			_set_px_safe(buf, ix, iy, px_col)

	var collar_y: float = sh.y - 1.2
	_draw_shaded_limb(buf, Vector2(sh.x - sh_spread * 0.68, collar_y), Vector2(sh.x + sh_spread * 0.68, collar_y), 2.0, 2.0, coat, 0.18)

	var belt_y: float = hip.y - 1.2
	var belt_w: float = hip_spread + 1.4
	for bx in range(int(round(hip.x - belt_w)), int(round(hip.x + belt_w)) + 1):
		var bnx: float = (float(bx) - hip.x) / maxf(1.0, belt_w)
		var b_col: Color = belt[2] if bnx < 0.0 else belt[1]
		if dir_y > -0.1 and abs(float(bx) - (hip.x + dir_x * 1.8)) <= 1.4:
			b_col = belt[3]
		_set_px_safe(buf, bx, int(round(belt_y)), b_col)
		_set_px_safe(buf, bx, int(round(belt_y + 1.0)), belt[0])


func _draw_coat_tails(buf: Image, hip: Vector2, dir_x: float, dir_y: float, flare: float, lag: float, pal: Dictionary, is_bfp: bool, back_pass: bool) -> void:
	var coat: Array = pal["coat"]
	var trim: Array = pal["trim"]
	var tail_len: float = 7.5 if is_bfp else 5.8

	for side in [-1.0, 1.0]:
		var is_back_flap: bool = (side * dir_x < -0.2) or (dir_y > 0.2 and back_pass)
		if back_pass != is_back_flap:
			continue
		var start_p: Vector2 = hip + Vector2(side * 3.8, 0.0)
		var end_p: Vector2 = hip + Vector2(side * (6.2 + flare * 1.15) - dir_x * lag * 0.75, tail_len - abs(lag) * 0.25)
		var shade_bias: float = -0.22 if back_pass else 0.12
		_draw_shaded_limb(buf, start_p, end_p, 3.2, 2.4, coat, shade_bias)
		if is_bfp:
			var hem_p: Vector2 = start_p.lerp(end_p, 0.82)
			_plot_shaded_disk(buf, hem_p, 1.8, trim, shade_bias + 0.2)


func _stamp_head_and_hair(img: Image, part: Image, hc: Vector2, sh: Vector2, row: int, pose: Dictionary, pal: Dictionary, is_bfp: bool) -> void:
	var skin: Array = pal["skin"]
	var hair: Array = pal["hair"]
	var helmet: Array = pal["helmet"]
	var trim: Array = pal["trim"]
	var dir_x: float = float(pose["dir_x"])
	var dir_y: float = float(pose["dir_y"])
	var lag: float = float(pose["lag"])
	var is_back: bool = (dir_y < -0.25)
	var is_profile: bool = (abs(dir_x) > 0.85)
	var head_rx: float = 6.8 if not is_profile else 6.0
	var head_ry: float = 6.8

	part.fill(Color(0, 0, 0, 0))

	# 1. Compact Neck
	var neck_top: Vector2 = hc + Vector2(0.0, 4.8)
	var neck_bot: Vector2 = sh + Vector2(0.0, -1.0)
	_draw_shaded_limb(part, neck_top, neck_bot, 2.3, 2.5, skin, -0.22)

	# 2. Tucked masculine nape hair (cropped close to the neck, no flared pageboy wings!)
	for i in range(-1, 2):
		var tuft_base: Vector2 = hc + Vector2(float(i) * 2.0 - dir_x * 1.5, 0.5)
		var tuft_tip: Vector2 = tuft_base + Vector2(float(i) * 0.9 - dir_x * (1.8 + lag * 0.25), 3.6)
		_draw_shaded_limb(part, tuft_base, tuft_tip, 1.8, 0.9, hair, -0.2)

	# 3. Sculpted Anime-Pixel Face & Tapered Chin
	for dy in range(-6, 7):
		var fy: float = float(dy)
		var y_norm: float = fy / head_ry
		var width_factor: float
		if y_norm < 0.15:
			width_factor = sqrt(maxf(0.0, 1.0 - y_norm * y_norm * 0.75))
		else:
			var chin_t: float = (y_norm - 0.15) / 0.85
			width_factor = maxf(0.0, (1.0 - chin_t * chin_t * 0.72) * (1.0 - chin_t * 0.22))

		var half_w: float = head_rx * width_factor
		var shift_x: float = dir_x * (1.5 if fy >= 0.0 and fy <= 4.0 else 0.6)
		var left_x: int = int(round(hc.x + shift_x - half_w))
		var right_x: int = int(round(hc.x + shift_x + half_w))
		var py: int = int(round(hc.y + fy))

		for px in range(left_x, right_x + 1):
			var nx: float = (float(px) - (hc.x + shift_x)) / maxf(1.0, half_w)
			var light_v: float = -nx * 0.55 - y_norm * 0.42 + 0.34
			var s_idx: int = clampi(int(round((light_v + 0.5) * 3.4)), 1, 4)
			if dy <= -1 and not is_back:
				s_idx = clampi(s_idx - 1, 0, 4)
			var col_skin: Color = skin[s_idx] if not is_back else hair[clampi(s_idx - 1, 0, 3)]
			_set_px_safe(part, px, py, col_skin)

	# 4. Compact Hair Crown + Bold Spiky Outer Tufts (so Casual Huwag has dynamic spiky anime hair, NOT a round bowl!)
	var crown: Vector2 = hc + Vector2(-dir_x * 0.4, -3.6)
	_plot_shaded_oval(part, crown, head_rx + 0.8, 3.2, hair, 0.15)

	if not is_bfp:
		var spikes: Array[Vector2] = [
			Vector2(-8.2, -4.8),
			Vector2(-5.5, -8.8),
			Vector2(-1.2, -10.2),
			Vector2(3.2, -9.2),
			Vector2(7.5, -6.2),
			Vector2(8.5, -2.5),
			Vector2(-8.5, -1.8)
		]
		for sp in spikes:
			var base_p: Vector2 = crown + sp * 0.25
			var tip: Vector2 = hc + sp + Vector2(-dir_x * lag * 0.45, 0.0)
			_draw_shaded_limb(part, base_p, tip, 2.4, 0.8, hair, 0.20 if sp.x < 0.0 else -0.05)

	# Temple Sideburns & Pointed V-Bangs
	if not is_back:
		var l_temple_top: Vector2 = hc + Vector2(-head_rx + 0.4, -3.8)
		var l_temple_tip: Vector2 = hc + Vector2(-head_rx + 0.2, 1.8)
		var r_temple_top: Vector2 = hc + Vector2(head_rx - 0.4, -3.8)
		var r_temple_tip: Vector2 = hc + Vector2(head_rx - 0.2, 1.8)
		_draw_shaded_limb(part, l_temple_top, l_temple_tip, 1.6, 0.8, hair, 0.15)
		_draw_shaded_limb(part, r_temple_top, r_temple_tip, 1.6, 0.8, hair, -0.1)

		var shift_f: float = dir_x * 1.6
		var v_locks: Array[Vector2] = [
			Vector2(-4.5 + shift_f * 0.6, -0.8),
			Vector2(-1.6 + shift_f * 0.8, -0.2),
			Vector2(0.5 + shift_f, 0.4),
			Vector2(2.6 + shift_f * 0.8, -0.4),
			Vector2(4.8 + shift_f * 0.6, -1.0)
		]
		for vl in v_locks:
			var b_root: Vector2 = hc + Vector2(vl.x * 0.75, -4.8)
			var b_tip: Vector2 = hc + vl
			_draw_shaded_limb(part, b_root, b_tip, 1.7, 0.8, hair, 0.12 if vl.x < 0.0 else -0.05)
			_set_px_safe(part, int(round(b_tip.x)), int(round(b_tip.y)), hair[0])

	if not is_bfp:
		for hx in range(int(round(hc.x - head_rx + 1.0)), int(round(hc.x + head_rx - 1.0)) + 1):
			var hy: int = int(round(hc.y - 5.2 + abs(float(hx) - hc.x) * 0.14))
			if part.get_pixel(hx, hy).a > 0.5:
				_set_px_safe(part, hx, hy, hair[4])

	# 5. Expressive Anime-Pixel Eyes in Lower Half of Face
	if not is_back:
		var eye_y: int = int(round(hc.y + 1.0))
		var blink: bool = bool(pose["blink"]) or (String(pose["anim"]) == "hurt" and int(pose["frame_idx"]) <= 1)
		var lash_color: Color = INK
		var iris_dark: Color = Color8(48, 24, 22)
		var iris_lit: Color = Color8(196, 112, 56)
		var sclera: Color = Color8(252, 248, 244)
		var catchlight: Color = Color8(255, 255, 255)

		if is_profile:
			var ex: int = int(round(hc.x + dir_x * 3.8))
			var back_step: int = -int(sign(dir_x))
			if blink:
				_set_px_safe(part, ex, eye_y + 1, lash_color)
				_set_px_safe(part, ex + back_step, eye_y + 1, lash_color)
			else:
				_set_px_safe(part, ex, eye_y, lash_color)
				_set_px_safe(part, ex + back_step, eye_y, lash_color)
				_set_px_safe(part, ex, eye_y + 1, catchlight)
				_set_px_safe(part, ex + back_step, eye_y + 1, sclera)
				_set_px_safe(part, ex, eye_y + 2, iris_lit)
				_set_px_safe(part, ex + back_step, eye_y + 2, iris_dark)
		else:
			var shift: float = dir_x * 1.8
			var lx: int = int(round(hc.x + shift - 3.6))
			var rx: int = int(round(hc.x + shift + 2.0))
			for ex in [lx, rx]:
				if blink:
					_set_px_safe(part, ex, eye_y + 1, lash_color)
					_set_px_safe(part, ex + 1, eye_y + 1, lash_color)
				else:
					_set_px_safe(part, ex, eye_y, lash_color)
					_set_px_safe(part, ex + 1, eye_y, lash_color)
					_set_px_safe(part, ex, eye_y + 1, catchlight)
					_set_px_safe(part, ex + 1, eye_y + 1, iris_dark)
					_set_px_safe(part, ex, eye_y + 2, iris_lit)
					_set_px_safe(part, ex + 1, eye_y + 2, sclera)

	_stamp_outlined_part(img, part, INK)

	# 6. Sculpted BFP Firefighter Helmet (on BFP variant)
	if is_bfp:
		part.fill(Color(0, 0, 0, 0))
		var h_c: Vector2 = hc + Vector2(-dir_x * 0.5, -5.8)
		_plot_shaded_oval(part, h_c, head_rx + 1.4, 4.2, helmet, 0.15)
		_draw_shaded_limb(part, h_c + Vector2(-dir_x * 2.0, -4.2), h_c + Vector2(dir_x * 2.5, -3.2), 2.0, 1.5, helmet, 0.35)
		var brim_l: Vector2 = hc + Vector2(-head_rx - 2.4, -3.2 + dir_x * 0.6)
		var brim_r: Vector2 = hc + Vector2(head_rx + 2.4, -3.2 - dir_x * 0.6)
		_draw_shaded_limb(part, brim_l, brim_r, 1.4, 1.4, helmet, 0.22)
		if not is_back:
			var badge_x: int = int(round(hc.x + dir_x * 2.2))
			var badge_y: int = int(round(hc.y - 5.8))
			_set_px_safe(part, badge_x, badge_y, Color8(224, 48, 58))
			_set_px_safe(part, badge_x, badge_y - 1, trim[3])
			_set_px_safe(part, badge_x + 1, badge_y, Color8(224, 48, 58))
		_stamp_outlined_part(img, part, INK)


func _draw_axe_and_arms(buf: Image, sh: Vector2, sh_spread: float, row: int, pose: Dictionary, pal: Dictionary, is_bfp: bool, back_only: bool) -> void:
	var dir_x: float = float(pose["dir_x"])
	var dir_y: float = float(pose["dir_y"])
	var is_back: bool = (dir_y < -0.25)
	if back_only != (is_back and String(pose["axe_mode"]) == "carry"):
		if back_only:
			return

	var coat: Array = pal["coat"]
	var skin: Array = pal["skin"]
	var glove: Array = pal["glove"]
	var trim: Array = pal["trim"]
	var wood: Array = pal["axe_wood"]
	var axe_red: Array = pal["axe_red"]
	var steel: Array = pal["axe_steel"]

	var l_sh: Vector2 = sh + Vector2(-sh_spread, 0.5)
	var r_sh: Vector2 = sh + Vector2(sh_spread, 0.5)

	if String(pose["axe_mode"]) == "swing":
		var swing_a: float = float(pose["axe_angle"])
		var base_dir: Vector2 = Vector2(dir_x, dir_y * 0.65)
		if base_dir.length() < 0.2:
			base_dir = Vector2(0.0, 1.0)
		base_dir = base_dir.normalized()

		var swing_vec: Vector2 = base_dir.rotated(swing_a)
		var grip_center: Vector2 = sh + Vector2(dir_x * 4.5, 3.2) + swing_vec * 9.5
		var l_elb: Vector2 = (l_sh + grip_center) * 0.5 + Vector2(-2.5, 2.0)
		var r_elb: Vector2 = (r_sh + grip_center) * 0.5 + Vector2(2.5, 2.0)

		_draw_shaded_limb(buf, l_sh, l_elb, 2.7, 2.3, coat, -0.05)
		_draw_shaded_limb(buf, l_elb, grip_center + Vector2(-1.4, 0.0), 2.3, 1.9, coat if is_bfp else skin, 0.08)
		_draw_shaded_limb(buf, r_sh, r_elb, 2.7, 2.3, coat, 0.12)
		_draw_shaded_limb(buf, r_elb, grip_center + Vector2(1.4, 0.0), 2.3, 1.9, coat if is_bfp else skin, 0.18)
		if is_bfp:
			_plot_shaded_disk(buf, l_elb.lerp(grip_center, 0.7), 1.8, trim, 0.1)
			_plot_shaded_disk(buf, r_elb.lerp(grip_center, 0.7), 1.8, trim, 0.15)

		var pommel: Vector2 = grip_center - swing_vec * 9.0
		var head_pos: Vector2 = grip_center + swing_vec * 22.0
		var blade_norm: Vector2 = Vector2(-swing_vec.y, swing_vec.x)
		if dir_x < -0.1:
			blade_norm = Vector2(swing_vec.y, -swing_vec.x)
		_draw_axe_weapon(buf, pommel, head_pos, blade_norm, wood, axe_red, steel)
		_plot_shaded_disk(buf, grip_center + Vector2(-1.4, 0.0), 2.2, glove, 0.1)
		_plot_shaded_disk(buf, grip_center + Vector2(1.4, 0.0), 2.2, glove, 0.2)
	else:
		# Purposeful 2-Handed Diagonal Tactical Carry (both hands grip the shaft, both elbows clearly visible!)
		var face_s: float = -1.0 if dir_x < -0.1 else 1.0
		var axe_a: float = float(pose["axe_angle"])
		var axe_dir: Vector2 = Vector2(face_s * 0.85, axe_a).normalized()
		var shaft_center: Vector2 = sh + Vector2(face_s * 2.5, 7.2 + sin(float(pose["l_arm_ang"])) * 1.4)

		var front_hand: Vector2 = shaft_center + axe_dir * 6.5
		var rear_hand: Vector2 = shaft_center - axe_dir * 5.5
		var pommel: Vector2 = rear_hand - axe_dir * 4.5
		var head_pos: Vector2 = front_hand + axe_dir * 14.5

		var l_target: Vector2 = front_hand if face_s < 0.0 else rear_hand
		var r_target: Vector2 = rear_hand if face_s < 0.0 else front_hand
		var l_elb: Vector2 = (l_sh + l_target) * 0.5 + Vector2(-3.2, 2.2)
		var r_elb: Vector2 = (r_sh + r_target) * 0.5 + Vector2(3.2, 2.2)

		# Draw rear arm, then weapon shaft & blade, then front arm & both hands on the handle!
		_draw_shaded_limb(buf, l_sh, l_elb, 2.7, 2.3, coat, 0.05)
		_draw_shaded_limb(buf, l_elb, l_target, 2.3, 1.9, coat if is_bfp else skin, 0.10)
		_draw_shaded_limb(buf, r_sh, r_elb, 2.7, 2.3, coat, 0.12)
		_draw_shaded_limb(buf, r_elb, r_target, 2.3, 1.9, coat if is_bfp else skin, 0.16)
		if is_bfp:
			_plot_shaded_disk(buf, l_elb.lerp(l_target, 0.72), 1.8, trim, 0.12)
			_plot_shaded_disk(buf, r_elb.lerp(r_target, 0.72), 1.8, trim, 0.15)

		var blade_norm: Vector2 = Vector2(axe_dir.y, -axe_dir.x) * face_s
		_draw_axe_weapon(buf, pommel, head_pos, blade_norm, wood, axe_red, steel)
		_plot_shaded_disk(buf, l_target, 2.2, glove, 0.15)
		_plot_shaded_disk(buf, r_target, 2.2, glove, 0.20)


func _draw_axe_weapon(buf: Image, pommel: Vector2, head_pos: Vector2, blade_dir: Vector2, wood: Array, axe_red: Array, steel: Array) -> void:
	_draw_shaded_limb(buf, pommel, head_pos, 1.6, 1.8, wood, 0.12)
	_plot_shaded_disk(buf, pommel, 2.1, steel, 0.05)

	var b_norm: Vector2 = blade_dir.normalized()
	var shaft_dir: Vector2 = (head_pos - pommel).normalized()
	var back_spike: Vector2 = head_pos - b_norm * 5.2
	_draw_shaded_limb(buf, head_pos, back_spike, 2.4, 1.0, axe_red, -0.05)
	_set_px_safe(buf, int(round(back_spike.x)), int(round(back_spike.y)), steel[3])

	var blade_mid: Vector2 = head_pos + b_norm * 5.5
	var blade_top: Vector2 = head_pos + b_norm * 7.8 + shaft_dir * 4.8
	var blade_bot: Vector2 = head_pos + b_norm * 7.2 - shaft_dir * 5.2
	_draw_shaded_limb(buf, head_pos - shaft_dir * 2.5, head_pos + shaft_dir * 2.8, 2.6, 2.6, axe_red, 0.12)
	_draw_shaded_limb(buf, head_pos, blade_mid, 3.0, 4.6, axe_red, 0.18)
	_draw_shaded_limb(buf, blade_top, blade_bot, 2.6, 2.6, steel, 0.28)
	for i in range(11):
		var t: float = float(i) / 10.0
		var edge_p: Vector2 = blade_top.lerp(blade_bot, t) + b_norm * sin(t * PI) * 1.8
		_set_px_safe(buf, int(round(edge_p.x)), int(round(edge_p.y)), steel[3])
		_set_px_safe(buf, int(round(edge_p.x - b_norm.x)), int(round(edge_p.y - b_norm.y)), steel[2])


func _draw_slash_arc(img: Image, center: Vector2, row: int, stage: int, is_bfp: bool) -> void:
	var c_dark: Color = Color8(96, 14, 28)
	var c_outer: Color = Color8(188, 34, 48) if not is_bfp else Color8(212, 68, 28)
	var c_mid: Color = Color8(246, 114, 44) if not is_bfp else Color8(252, 162, 42)
	var c_core: Color = Color8(255, 232, 136)
	var c_white: Color = Color8(255, 254, 245)

	var base_ang: float = PI * 0.5
	match row:
		Dir.DOWN: base_ang = PI * 0.5
		Dir.LEFT: base_ang = PI
		Dir.RIGHT: base_ang = 0.0
		Dir.UP: base_ang = -PI * 0.5
		Dir.DOWN_LEFT: base_ang = PI * 0.72
		Dir.DOWN_RIGHT: base_ang = PI * 0.28
		Dir.UP_LEFT: base_ang = -PI * 0.72
		Dir.UP_RIGHT: base_ang = -PI * 0.28

	if stage == 0:
		var glint: Vector2 = center + Vector2(cos(base_ang - 2.2), sin(base_ang - 2.2)) * 24.0
		for d in range(-4, 5):
			_set_px_safe(img, int(round(glint.x + float(d))), int(round(glint.y)), c_white)
			_set_px_safe(img, int(round(glint.x)), int(round(glint.y + float(d))), c_white)
		return

	var arc_buf: Image = Image.create(CELL_W, CELL_H, false, Image.FORMAT_RGBA8)
	arc_buf.fill(Color(0, 0, 0, 0))

	var span_half: float = 1.18 if stage == 1 else 0.85
	var mid_ang: float = base_ang - (0.22 if stage == 1 else 0.05)
	var rad_x: float = 30.0
	var rad_y: float = 23.0
	var pivot: Vector2 = center + Vector2(0.0, 4.0)
	var max_thick: float = 0.22 if stage == 1 else 0.11

	for y in range(10, 92):
		for x in range(4, 92):
			var nx: float = (float(x) - pivot.x) / rad_x
			var ny: float = (float(y) - pivot.y) / rad_y
			var r_ell: float = sqrt(nx * nx + ny * ny)
			if r_ell < 0.65 or r_ell > 1.35:
				continue
			var ang: float = atan2(ny, nx)
			var d_ang: float = wrapf(ang - mid_ang, -PI, PI)
			if abs(d_ang) > span_half:
				continue
			var t: float = (d_ang + span_half) / (2.0 * span_half)
			if stage == 2 and fmod(t * 7.0, 1.0) > 0.70:
				continue
			var local_half_w: float = sin(t * PI) * max_thick
			var dr: float = r_ell - 1.0
			if abs(dr) <= local_half_w:
				var rel: float = dr / maxf(0.001, local_half_w)
				var col: Color = c_outer
				if rel > 0.45:
					col = c_white
				elif rel > -0.05:
					col = c_core
				elif rel > -0.50:
					col = c_mid
				arc_buf.set_pixel(x, y, col)

	_stamp_outlined_part(img, arc_buf, c_dark)

	for s_i in range(7):
		var st: float = float(s_i) / 6.0
		var sa: float = mid_ang - span_half + st * 2.0 * span_half
		var sp: Vector2 = pivot + Vector2(cos(sa) * 35.0, sin(sa) * 27.0)
		_set_px_safe(img, int(round(sp.x)), int(round(sp.y)), c_white)
		_set_px_safe(img, int(round(sp.x + 1.0)), int(round(sp.y)), c_mid)
		_set_px_safe(img, int(round(sp.x)), int(round(sp.y + 1.0)), c_dark)


func _draw_defeat_sequence(img: Image, row: int, f_idx: int, cx: float, ground_y: float, pal: Dictionary, is_bfp: bool) -> void:
	var collapse_t: float = clampf(float(f_idx - 1) / 3.0, 0.0, 1.0)
	_draw_ground_shadow(img, cx + 2.0, ground_y + 1.0, lerpf(19.0, 26.0, collapse_t), 5.2)

	var part: Image = Image.create(CELL_W, CELL_H, false, Image.FORMAT_RGBA8)
	var dir_x: float = -1.0 if (row == Dir.LEFT or row == Dir.DOWN_LEFT or row == Dir.UP_LEFT) else 1.0
	var pelvis: Vector2 = Vector2(cx - dir_x * 4.5 * collapse_t, lerpf(65.0, 77.0, collapse_t))
	var shoulder: Vector2 = pelvis + Vector2(dir_x * lerpf(3.5, 14.0, collapse_t), lerpf(-11.0, -2.0, collapse_t))
	var head_c: Vector2 = shoulder + Vector2(dir_x * lerpf(2.5, 8.5, collapse_t), lerpf(-8.5, 0.5, collapse_t))

	part.fill(Color(0, 0, 0, 0))
	var knee1: Vector2 = pelvis + Vector2(-dir_x * 6.5, 3.0)
	var boot1: Vector2 = knee1 + Vector2(-dir_x * 7.0, 1.5)
	var knee2: Vector2 = pelvis + Vector2(-dir_x * 4.5, 4.5)
	var boot2: Vector2 = knee2 + Vector2(-dir_x * 6.5, 1.5)
	_draw_shaded_limb(part, pelvis, knee1, 3.4, 2.8, pal["pants"], -0.15)
	_draw_shaded_limb(part, knee1, boot1, 2.6, 2.3, pal["boots"], -0.15)
	_draw_shaded_limb(part, pelvis, knee2, 3.4, 2.8, pal["pants"], 0.1)
	_draw_shaded_limb(part, knee2, boot2, 2.6, 2.3, pal["boots"], 0.1)
	_stamp_outlined_part(img, part, INK)

	part.fill(Color(0, 0, 0, 0))
	var coat_bounce: float = 2.8 if f_idx == 3 else 0.0
	_draw_shaded_limb(part, pelvis, shoulder, 4.8, 5.2, pal["coat"], 0.1)
	if is_bfp:
		var mid_t: Vector2 = pelvis.lerp(shoulder, 0.55)
		_draw_shaded_limb(part, mid_t + Vector2(0.0, -3.8), mid_t + Vector2(0.0, 3.8), 1.6, 1.6, pal["trim"], 0.2)
	_draw_shaded_limb(part, pelvis, pelvis + Vector2(-dir_x * 5.5, -2.8 - coat_bounce), 3.0, 2.2, pal["coat"], 0.15)
	_stamp_outlined_part(img, part, INK)

	part.fill(Color(0, 0, 0, 0))
	_plot_shaded_oval(part, head_c, 6.2, 5.6, pal["skin"], 0.05)
	_plot_shaded_oval(part, head_c + Vector2(-dir_x * 1.4, -2.0), 6.6, 4.8, pal["helmet"] if is_bfp else pal["hair"], 0.15)
	_stamp_outlined_part(img, part, INK)

	part.fill(Color(0, 0, 0, 0))
	var elbow: Vector2 = shoulder + Vector2(dir_x * 4.8, 3.5)
	var hand: Vector2 = elbow + Vector2(dir_x * 6.0, 1.5)
	_draw_shaded_limb(part, shoulder, elbow, 2.6, 2.2, pal["coat"], 0.1)
	_draw_shaded_limb(part, elbow, hand, 2.2, 1.9, pal["coat"] if is_bfp else pal["skin"], 0.1)
	_plot_shaded_disk(part, hand, 2.2, pal["glove"], 0.15)
	var axe_p1: Vector2 = Vector2(cx - dir_x * 3.0, ground_y + 2.0)
	var axe_p2: Vector2 = Vector2(cx + dir_x * 20.0, ground_y + 1.0)
	_draw_axe_weapon(part, axe_p1, axe_p2, Vector2(0.0, -1.0), pal["axe_wood"], pal["axe_red"], pal["axe_steel"])
	_stamp_outlined_part(img, part, INK)


func _draw_ground_shadow(img: Image, cx: float, cy: float, rx: float, ry: float) -> void:
	for y in range(int(floor(cy - ry - 1.0)), int(ceil(cy + ry + 1.0)) + 1):
		for x in range(int(floor(cx - rx - 1.0)), int(ceil(cx + rx + 1.0)) + 1):
			var dx: float = (float(x) - cx) / maxf(1.0, rx)
			var dy: float = (float(y) - cy) / maxf(1.0, ry)
			var d2: float = dx * dx + dy * dy
			if d2 <= 0.72:
				_set_px_safe(img, x, y, SHADOW_GROUND_INNER)
			elif d2 <= 1.0:
				_set_px_safe(img, x, y, SHADOW_GROUND_OUTER)


func _draw_shaded_limb(buf: Image, a: Vector2, b: Vector2, r_a: float, r_b: float, pal: Array, shade_bias: float) -> void:
	var min_x: int = clampi(int(floor(minf(a.x, b.x) - maxf(r_a, r_b) - 1.0)), 0, CELL_W - 1)
	var max_x: int = clampi(int(ceil(maxf(a.x, b.x) + maxf(r_a, r_b) + 1.0)), 0, CELL_W - 1)
	var min_y: int = clampi(int(floor(minf(a.y, b.y) - maxf(r_a, r_b) - 1.0)), 0, CELL_H - 1)
	var max_y: int = clampi(int(ceil(maxf(a.y, b.y) + maxf(r_a, r_b) + 1.0)), 0, CELL_H - 1)

	var ab: Vector2 = b - a
	var ab_len2: float = maxf(0.001, ab.length_squared())
	var max_idx: int = min(3, pal.size() - 1)

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
				var light_v: float = -nx * 0.58 - ny * 0.52 + 0.22 + shade_bias
				var idx: int = clampi(int(round((light_v + 0.5) * float(max_idx))), 0, max_idx)
				buf.set_pixel(x, y, pal[idx])


func _plot_shaded_disk(buf: Image, c: Vector2, r: float, pal: Array, shade_bias: float) -> void:
	_plot_shaded_oval(buf, c, r, r, pal, shade_bias)


func _plot_shaded_oval(buf: Image, c: Vector2, rx: float, ry: float, pal: Array, shade_bias: float) -> void:
	var max_idx: int = min(3, pal.size() - 1)
	var min_x: int = clampi(int(floor(c.x - rx - 1.0)), 0, CELL_W - 1)
	var max_x: int = clampi(int(ceil(c.x + rx + 1.0)), 0, CELL_W - 1)
	var min_y: int = clampi(int(floor(c.y - ry - 1.0)), 0, CELL_H - 1)
	var max_y: int = clampi(int(ceil(c.y + ry + 1.0)), 0, CELL_H - 1)
	for y in range(min_y, max_y + 1):
		for x in range(min_x, max_x + 1):
			var nx: float = (float(x) - c.x) / maxf(1.0, rx)
			var ny: float = (float(y) - c.y) / maxf(1.0, ry)
			if nx * nx + ny * ny <= 1.0:
				var light_v: float = -nx * 0.58 - ny * 0.52 + 0.22 + shade_bias
				var idx: int = clampi(int(round((light_v + 0.5) * float(max_idx))), 0, max_idx)
				buf.set_pixel(x, y, pal[idx])


func _stamp_outlined_part(dst: Image, part: Image, ink: Color) -> void:
	for y in range(8, 92):
		for x in range(4, 92):
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


func _set_px_safe(img: Image, x: int, y: int, col: Color) -> void:
	if x >= 0 and x < img.get_width() and y >= 0 and y < img.get_height():
		img.set_pixel(x, y, col)


func _build_showcase_preview(bfp: Image, casual: Image) -> Image:
	var card_w: int = 1280
	var card_h: int = 720
	var card: Image = Image.create(card_w, card_h, false, Image.FORMAT_RGBA8)
	card.fill(Color8(248, 246, 250, 255))

	var showcase_frames: Array[Dictionary] = [
		{"sheet": bfp, "row": Dir.DOWN_LEFT, "col": 1, "x": 28, "y": 20},
		{"sheet": bfp, "row": Dir.DOWN_LEFT, "col": 23, "x": 232, "y": 20},
		{"sheet": bfp, "row": Dir.DOWN_LEFT, "col": 24, "x": 436, "y": 20},
		{"sheet": casual, "row": Dir.DOWN_RIGHT, "col": 1, "x": 640, "y": 20},
		{"sheet": casual, "row": Dir.RIGHT, "col": 16, "x": 844, "y": 20},
		{"sheet": casual, "row": Dir.DOWN_LEFT, "col": 24, "x": 1048, "y": 20}
	]

	for item in showcase_frames:
		var src_sheet: Image = item["sheet"]
		var r: int = int(item["row"])
		var c: int = int(item["col"])
		var cell: Image = src_sheet.get_region(Rect2i(c * CELL_W, r * CELL_H, CELL_W, CELL_H))
		cell.resize(CELL_W * 2, CELL_H * 2, Image.INTERPOLATE_NEAREST)
		card.blit_rect(cell, Rect2i(0, 0, CELL_W * 2, CELL_H * 2), Vector2i(int(item["x"]), int(item["y"])))

	for dir_i in range(8):
		var cell_idle: Image = bfp.get_region(Rect2i(1 * CELL_W, dir_i * CELL_H, CELL_W, CELL_H))
		var cell_atk: Image = bfp.get_region(Rect2i(24 * CELL_W, dir_i * CELL_H, CELL_W, CELL_H))
		card.blit_rect(cell_idle, Rect2i(0, 0, CELL_W, CELL_H), Vector2i(32 + dir_i * 152, 232))
		card.blit_rect(cell_atk, Rect2i(0, 0, CELL_W, CELL_H), Vector2i(102 + dir_i * 152, 232))

	var strip1_cols: Array[int] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13]
	for idx in range(strip1_cols.size()):
		var c: int = strip1_cols[idx]
		var cell: Image = bfp.get_region(Rect2i(c * CELL_W, Dir.DOWN_LEFT * CELL_H, CELL_W, CELL_H))
		card.blit_rect(cell, Rect2i(0, 0, CELL_W, CELL_H), Vector2i(12 + idx * 88, 352))

	var strip2_cols: Array[int] = [14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27]
	for idx in range(strip2_cols.size()):
		var c: int = strip2_cols[idx]
		var cell: Image = bfp.get_region(Rect2i(c * CELL_W, Dir.DOWN_LEFT * CELL_H, CELL_W, CELL_H))
		card.blit_rect(cell, Rect2i(0, 0, CELL_W, CELL_H), Vector2i(12 + idx * 88, 464))

	var strip3_cols: Array[int] = [6, 7, 8, 9, 22, 23, 24, 25, 28, 29, 30, 33, 34, 36]
	for idx in range(strip3_cols.size()):
		var c: int = strip3_cols[idx]
		var cell: Image = casual.get_region(Rect2i(c * CELL_W, Dir.DOWN_LEFT * CELL_H, CELL_W, CELL_H))
		card.blit_rect(cell, Rect2i(0, 0, CELL_W, CELL_H), Vector2i(12 + idx * 88, 576))

	return card
