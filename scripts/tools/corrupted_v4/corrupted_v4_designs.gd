class_name CorruptedV4Designs
extends RefCounted

## Designs anatômicos individuais para os 12 personagens corrompidos (Etapa 2).
## Escala SNES calibrada ao protagonista Huwag (adultos ~24-28px em y=12..39;
## criança Toby ~20px em y=19..39; contorno crisp 1px sem pintura vermelha sobre o contorno).

const S := preload("res://scripts/tools/corrupted_v4/corrupted_v4_builder.gd")
const T := S.T

const ADULT_IDS: Array[String] = [
	"cap_reyes",
	"bombeiro_ato",
	"bombeiro_santos",
	"enfermeira_maria",
	"aling_nena",
	"kuya_ben",
	"mang_tomas",
	"mang_carding",
	"senhora_luningning",
	"lola_rosa",
	"vulto_bosque",
]

const ALL_IDS: Array[String] = [
	"cap_reyes",
	"bombeiro_ato",
	"bombeiro_santos",
	"enfermeira_maria",
	"aling_nena",
	"kuya_ben",
	"mang_tomas",
	"mang_carding",
	"toby",
	"senhora_luningning",
	"lola_rosa",
	"vulto_bosque",
]


static func get_spec(npc_id: String) -> Dictionary:
	match npc_id:
		"cap_reyes":
			return {
				"id": "cap_reyes", "label": "Cap. Reyes", "child": false, "atk_style": "cleave_diag",
				"pal": S.make_palette({
					"out": "#120B14",
					"skin_hi": "#B3A6AD", "skin": "#84767E", "skin_sh": "#50444C",
					"cloth_hi": "#2F3D5E", "cloth": "#1D263D", "cloth_sh": "#121828",
					"accent_hi": "#EB7B3D", "accent": "#B84028", "accent_sh": "#6E1D19",
					"hat_hi": "#34446B", "hat": "#1C2742", "hat_sh": "#101629",
					"hair": "#696E7D", "hair_sh": "#393C47",
					"eye_glow": "#FF3B4D", "eye_core": "#FFF3C4",
				}),
			}
		"bombeiro_ato":
			return {
				"id": "bombeiro_ato", "label": "Bombeiro Ato", "child": false, "atk_style": "overhead_slam",
				"pal": S.make_palette({
					"out": "#140B10",
					"skin_hi": "#A8887E", "skin": "#785B54", "skin_sh": "#4A3332",
					"cloth_hi": "#32384A", "cloth": "#1F2430", "cloth_sh": "#141720",
					"accent_hi": "#F29C38", "accent": "#C24E27", "accent_sh": "#6E2316",
					"hat_hi": "#E6B43C", "hat": "#B07C22", "hat_sh": "#664312",
					"hair": "#242129", "hair_sh": "#16141A",
					"eye_glow": "#FF3B30", "eye_core": "#FFE4C2",
				}),
			}
		"bombeiro_santos":
			return {
				"id": "bombeiro_santos", "label": "Bombeiro Santos", "child": false, "atk_style": "pounce_rake",
				"pal": S.make_palette({
					"out": "#14090E",
					"skin_hi": "#8F7E85", "skin": "#61525A", "skin_sh": "#3C2E36",
					"cloth_hi": "#2C374D", "cloth": "#1B2230", "cloth_sh": "#111520",
					"accent_hi": "#FF8838", "accent": "#D43F28", "accent_sh": "#731A14",
					"hat_hi": "#3A3842", "hat": "#222029", "hat_sh": "#15131A",
					"hair": "#292833", "hair_sh": "#18171F",
					"eye_glow": "#FF6A2B", "eye_core": "#FFF5BA",
				}),
			}
		"enfermeira_maria":
			return {
				"id": "enfermeira_maria", "label": "Enf. Maria", "child": false, "atk_style": "scissor_cross",
				"pal": S.make_palette({
					"out": "#150A14",
					"skin_hi": "#C4B8BE", "skin": "#948790", "skin_sh": "#5E515B",
					"cloth_hi": "#E6DFE2", "cloth": "#B3A8B0", "cloth_sh": "#736770",
					"accent_hi": "#488991", "accent": "#2B5961", "accent_sh": "#1A373F",
					"hat_hi": "#FAF2F4", "hat": "#C4B9BD", "hat_sh": "#7D7278",
					"hair": "#3D262B", "hair_sh": "#241519",
					"eye_glow": "#FF2E4C", "eye_core": "#FFFFFF",
				}),
			}
		"aling_nena":
			return {
				"id": "aling_nena", "label": "Aling Nena", "child": false, "atk_style": "broom_sweep",
				"pal": S.make_palette({
					"out": "#160B10",
					"skin_hi": "#A88E87", "skin": "#7D6460", "skin_sh": "#4F3A3A",
					"cloth_hi": "#876069", "cloth": "#593B43", "cloth_sh": "#362028",
					"accent_hi": "#CCB0A7", "accent": "#9C7D77", "accent_sh": "#634846",
					"hat_hi": "#726F78", "hat": "#4C4852", "hat_sh": "#2B2730",
					"hair": "#3B3640", "hair_sh": "#211E24",
					"eye_glow": "#FF3B52", "eye_core": "#FFEAEA",
				}),
			}
		"kuya_ben":
			return {
				"id": "kuya_ben", "label": "Kuya Ben", "child": false, "atk_style": "wrench_crush",
				"pal": S.make_palette({
					"out": "#120D14",
					"skin_hi": "#969E92", "skin": "#6A7369", "skin_sh": "#434A45",
					"cloth_hi": "#3D5D8F", "cloth": "#263D63", "cloth_sh": "#182640",
					"accent_hi": "#C4BCA9", "accent": "#827A6D", "accent_sh": "#4F4841",
					"hat_hi": "#34528A", "hat": "#1E3257", "hat_sh": "#121E36",
					"hair": "#24242B", "hair_sh": "#16161C",
					"eye_glow": "#FF453A", "eye_core": "#FFE8C8",
				}),
			}
		"mang_tomas":
			return {
				"id": "mang_tomas", "label": "Mang Tomas", "child": false, "atk_style": "cleaver_maw",
				"pal": S.make_palette({
					"out": "#170A0D",
					"skin_hi": "#9E8278", "skin": "#735952", "skin_sh": "#4A3432",
					"cloth_hi": "#4D664A", "cloth": "#324531", "cloth_sh": "#1D291E",
					"accent_hi": "#D4C5C5", "accent": "#A39193", "accent_sh": "#6B585B",
					"hat_hi": "#C2A361", "hat": "#8F733E", "hat_sh": "#544120",
					"hair": "#2E282A", "hair_sh": "#1C1719",
					"eye_glow": "#FF3044", "eye_core": "#FFF0D4",
				}),
			}
		"mang_carding":
			return {
				"id": "mang_carding", "label": "Mang Carding", "child": false, "atk_style": "long_thrust",
				"pal": S.make_palette({
					"out": "#0F0C14",
					"skin_hi": "#899096", "skin": "#5F6770", "skin_sh": "#383F47",
					"cloth_hi": "#315663", "cloth": "#1E3842", "cloth_sh": "#12232B",
					"accent_hi": "#54BFBC", "accent": "#327F7F", "accent_sh": "#1C4D50",
					"hat_hi": "#62EBE5", "hat": "#32B0AB", "hat_sh": "#1C6666",
					"hair": "#747D87", "hair_sh": "#424952",
					"eye_glow": "#EBFFFA", "eye_core": "#FF3D55",
				}),
			}
		"toby":
			return {
				"id": "toby", "label": "Toby (Criança)", "child": true, "atk_style": "none",
				"pal": S.make_palette({
					"out": "#0E0912",
					"skin_hi": "#998F96", "skin": "#6E636E", "skin_sh": "#2D2530",
					"cloth_hi": "#4D4052", "cloth": "#302736", "cloth_sh": "#1C1521",
					"accent_hi": "#CC9E3D", "accent": "#916E26", "accent_sh": "#543E16",
					"hat_hi": "#BA3842", "hat": "#822029", "hat_sh": "#4A1018",
					"hair": "#1C1620", "hair_sh": "#110D14",
					"eye_glow": "#FF3B52", "eye_core": "#FFFFFF",
				}),
			}
		"senhora_luningning":
			return {
				"id": "senhora_luningning", "label": "Sra. Luningning", "child": false, "atk_style": "lantern_curse",
				"pal": S.make_palette({
					"out": "#140916",
					"skin_hi": "#B8B0BA", "skin": "#8A808C", "skin_sh": "#524957",
					"cloth_hi": "#473757", "cloth": "#2E223B", "cloth_sh": "#1B1224",
					"accent_hi": "#8D5CA6", "accent": "#613878", "accent_sh": "#3B1E4D",
					"hat_hi": "#DCE0EB", "hat": "#9FA6B3", "hat_sh": "#616670",
					"hair": "#B4B8C4", "hair_sh": "#6D717D",
					"eye_glow": "#FF405A", "eye_core": "#FFF8E0",
				}),
			}
		"lola_rosa":
			return {
				"id": "lola_rosa", "label": "Lola Rosa", "child": false, "atk_style": "spore_swipe",
				"pal": S.make_palette({
					"out": "#140B0D",
					"skin_hi": "#A6938A", "skin": "#7A6760", "skin_sh": "#4D3E3B",
					"cloth_hi": "#5A6B47", "cloth": "#3C472E", "cloth_sh": "#222B1B",
					"accent_hi": "#997348", "accent": "#66492A", "accent_sh": "#3D2A17",
					"hat_hi": "#D9CFD2", "hat": "#A3989C", "hat_sh": "#665A60",
					"hair": "#8A8287", "hair_sh": "#524B4F",
					"eye_glow": "#FF4838", "eye_core": "#FFEBA8",
				}),
			}
		"vulto_bosque":
			return {
				"id": "vulto_bosque", "label": "Vulto Calcinado", "child": false, "atk_style": "ember_tear",
				"pal": S.make_palette({
					"out": "#11080E",
					"skin_hi": "#45373F", "skin": "#2B2129", "skin_sh": "#1A131A",
					"cloth_hi": "#3D313A", "cloth": "#241B24", "cloth_sh": "#140F17",
					"accent_hi": "#FF943B", "accent": "#DE3B28", "accent_sh": "#781515",
					"hat_hi": "#524047", "hat": "#2E2229", "hat_sh": "#1C1419",
					"hair": "#1C141A", "hair_sh": "#120C10",
					"eye_glow": "#FF5B2E", "eye_core": "#FFF8C7",
				}),
			}
	return {}


static func render_frame(npc_id: String, dir: String, anim: String, f_idx: int) -> Image:
	var spec := get_spec(npc_id)
	var pal: Dictionary = spec["pal"]
	var sc := S.PixelSculptor.new(S.CELL_W, S.CELL_H)

	if anim == "death":
		_sculpt_death(sc, npc_id, dir, f_idx)
		sc.apply_outline(T.OUT)
		return sc.render_to_image(pal)

	var pose := _calc_motion(npc_id, dir, anim, f_idx)
	_sculpt_creature(sc, npc_id, dir, anim, f_idx, pose)
	sc.apply_outline(T.OUT)
	var img := sc.render_to_image(pal)

	if anim == "attack":
		_draw_attack_arc(img, npc_id, str(spec["atk_style"]), dir, f_idx, pal)
	elif anim == "hurt" and f_idx == 0:
		_tint_hurt_flash(img)

	return img


static func _calc_motion(_npc_id: String, dir: String, anim: String, f_idx: int) -> Dictionary:
	var fx := -1.0 if dir == "left" else (1.0 if dir == "right" else 0.0)
	var fy := -1.0 if dir == "up" else (1.0 if dir == "down" else 0.0)
	var bob: float = 0.0
	var lunge_x: float = 0.0
	var stride: float = 0.0
	var head_dx: float = 0.0
	var head_dy: float = 0.0
	var jaw_open: int = 0
	var swing: float = 0.0

	match anim:
		"idle":
			var idle_bobs: Array[float] = [0.0, 0.0, 1.0, 0.0]
			var idle_hdx: Array[float] = [0.0, 0.0, 1.0 if fx >= 0.0 else -1.0, 0.0]
			bob = idle_bobs[f_idx % 4]
			head_dx = idle_hdx[f_idx % 4]
			jaw_open = 1 if f_idx == 2 else 0
		"walk":
			var bobs: Array[float] = [0.0, -1.0, 0.0, 1.0, -1.0, 0.0]
			var strides: Array[float] = [-2.6, -1.3, 1.3, 2.6, 1.3, -1.3]
			bob = bobs[f_idx % 6]
			stride = strides[f_idx % 6]
			head_dy = -1.0 if f_idx in [1, 4] else 0.0
			swing = stride * 0.4
		"talk":
			var t_jw: Array[int] = [0, 2, 3, 1]
			var t_hdx: Array[float] = [0.0, -0.5, 1.0, 0.0]
			var t_hdy: Array[float] = [0.0, -1.0, 0.0, 0.0]
			var t_sw: Array[float] = [0.0, 0.4, 1.0, 0.2]
			jaw_open = t_jw[f_idx % 4]
			head_dx = t_hdx[f_idx % 4]
			head_dy = t_hdy[f_idx % 4]
			swing = t_sw[f_idx % 4]
		"attack":
			var lxs: Array[float] = [-2.0, 3.0, 3.5, 1.5, 0.5]
			var sws: Array[float] = [-1.1, 1.05, 1.35, 0.85, 0.2]
			var jws: Array[int] = [0, 2, 3, 2, 0]
			var k: int = mini(f_idx, 4)
			swing = sws[k]
			lunge_x = fx * lxs[k]
			bob = 1.0 if k == 0 else (-1.0 if k in [1, 2] else 0.0)
			jaw_open = jws[k]
		"hurt":
			var hx: Array[float] = [-2.0, -1.0, 0.0]
			var k: int = mini(f_idx, 2)
			lunge_x = -fx * hx[k] if fx != 0.0 else (-1.0 if k == 0 else 1.0)
			bob = 1.0 if k < 2 else 0.0
			head_dy = -1.0 if k == 0 else 1.0
			jaw_open = 2 if k < 2 else 0

	return {
		"fx": fx, "fy": fy,
		"bob": bob, "lunge_x": lunge_x,
		"stride": stride, "head_dx": head_dx, "head_dy": head_dy,
		"jaw_open": jaw_open, "swing": swing,
	}


static func _sculpt_creature(sc: S.PixelSculptor, id: String, dir: String, _anim: String, _f_idx: int, pose: Dictionary) -> void:
	var cx := 24.0 + float(pose["lunge_x"])
	var bob := float(pose["bob"])
	var stride := float(pose["stride"])
	var swing := float(pose["swing"])
	var jw := int(pose["jaw_open"])
	var hx_off := float(pose["head_dx"])
	var hy_off := float(pose["head_dy"])
	var face := -1.0 if dir == "left" else (1.0 if dir == "right" else 0.0)

	# ------------------------------------------------------------------
	# TOBY — Escala Infantil (~19px altura: y=19..39) + MÃO MONSTRUOSA COM 5 DEDOS
	# ------------------------------------------------------------------
	if id == "toby":
		var foot_y := 38.0
		var leg_l := Vector2(cx - 2.0, foot_y - stride * 0.35)
		var leg_r := Vector2(cx + 2.0, foot_y + stride * 0.35)
		if dir in ["left", "right"]:
			leg_l = Vector2(cx - stride * 0.7, foot_y)
			leg_r = Vector2(cx + stride * 0.7, foot_y)
		sc.limb(Vector2(cx - 1.4, 34.0 + bob), leg_l, 1.0, 0.85, T.SKIN_SH)
		sc.limb(Vector2(cx + 1.4, 34.0 + bob), leg_r, 1.0, 0.85, T.SKIN, T.SKIN_SH)

		var torso_c := Vector2(cx + face * 0.6, 30.2 + bob)
		sc.blob(torso_c.x, torso_c.y, 3.6, 3.4, T.CLOTH, T.CLOTH_SH, T.CLOTH_HI, 2)
		if dir == "up":
			sc.blob(torso_c.x, torso_c.y + 0.5, 2.8, 2.6, T.ACCENT, T.ACCENT_SH, T.ACCENT_HI)
		elif dir == "down":
			sc.limb(torso_c + Vector2(-1.8, -2.5), torso_c + Vector2(-1.5, 2.5), 0.65, 0.65, T.ACCENT)
			sc.limb(torso_c + Vector2(1.8, -2.5), torso_c + Vector2(1.5, 2.5), 0.65, 0.65, T.ACCENT)
		else:
			sc.blob(torso_c.x - face * 2.2, torso_c.y, 1.5, 2.5, T.ACCENT, T.ACCENT_SH, T.ACCENT_HI)

		# Cabeça infantil baixa (y=23.5 -> topo com boné y=19)
		var head_c := Vector2(cx + face * 1.4 + hx_off * 0.7, 23.8 + bob + hy_off)
		sc.blob(head_c.x, head_c.y, 3.9, 3.4, T.SKIN, T.SKIN_SH, T.SKIN_HI, 1)
		if dir != "up":
			sc.blob(head_c.x + face * 1.0, head_c.y + 0.4, 2.8, 2.2, T.MAW_VOID)
			var ex0 := int(round(head_c.x - 1.3 + face * 1.2))
			var ey := int(round(head_c.y + 0.2))
			sc.px(ex0, ey, T.EYE_GLOW)
			sc.px(ex0, ey + 1, T.BLOOD_SH)
			if dir == "down":
				sc.px(int(round(head_c.x + 1.3)), ey, T.EYE_GLOW)
				sc.px(int(round(head_c.x + 1.3)), ey + 1, T.BLOOD_SH)
			if jw > 0:
				sc.px(int(round(head_c.x + face * 1.3)), ey + 2, T.FLESH)
		# Boné vermelho caído
		sc.blob(head_c.x - 0.3, head_c.y - 2.0, 4.1, 1.8, T.HAT, T.HAT_SH, T.HAT_HI)
		var brim_x := head_c.x + (face * 3.0 if face != 0.0 else 1.2)
		sc.limb(Vector2(head_c.x, head_c.y - 1.3), Vector2(brim_x, head_c.y - 0.8), 0.9, 0.7, T.HAT_SH)

		# Braço esquerdo magro + MÃO GIGANTE COM PALMA ABERTA E DEDOS SEPARADOS À FRENTE
		if dir in ["down", "up"]:
			sc.limb(torso_c + Vector2(-2.8, -1.8), Vector2(cx - 4.5, 35.0 + bob - swing), 0.85, 0.65, T.SKIN_SH)
		var r_sh := torso_c + Vector2(2.6 if dir in ["down", "up"] else face * 1.5, -1.5)
		var elbow := Vector2(cx + (4.8 if dir in ["down", "up"] else face * 4.2), 29.8 + bob)
		var palm := Vector2(cx + (7.2 if dir in ["down", "up"] else face * 8.2 + swing * 1.8), 32.2 + bob - swing * 1.5)
		if dir == "up":
			palm = Vector2(cx + 6.5, 32.0 + bob)
		sc.limb(r_sh, elbow, 0.9, 1.15, T.SKIN_SH, T.CLOTH_SH)
		sc.limb(elbow, palm, 1.15, 1.5, T.CLOTH, T.SKIN_SH)
		sc.blob(palm.x, palm.y, 1.7, 1.6, T.SKIN_SH, T.CLOTH_SH, T.SKIN)
		# 4 dedos longos ossudos espaçados com pontas rubras (zero cunha sólida!)
		var px_i := int(round(palm.x))
		var py_i := int(round(palm.y))
		var fdir := 1 if dir != "left" else -1
		for f_off: Vector2i in [Vector2i(-2, 4), Vector2i(0, 5), Vector2i(2, 4), Vector2i(4, 2)]:
			var tip_x: int = px_i + f_off.x * (1 if dir == "down" else fdir)
			var tip_y: int = mini(38, py_i + f_off.y)
			var abs_fx: int = f_off.x if f_off.x >= 0 else -f_off.x
			sc.limb(palm, Vector2(tip_x, tip_y), 0.45, 0.35, T.SKIN_SH if abs_fx >= 2 else T.CLOTH)
			sc.px(tip_x, tip_y, T.BLOOD_HI if f_off.y >= 4 else T.EYE_GLOW)
		return

	# ------------------------------------------------------------------
	# ADULTOS GROTESCOS (Calibrados em y=12..39, coerentes com Huwag!)
	# ------------------------------------------------------------------
	_sculpt_adult_legs(sc, id, dir, cx, bob, stride)
	_sculpt_adult_torso_and_head(sc, id, dir, cx, bob, hx_off, hy_off, jw)
	_sculpt_adult_arms_and_props(sc, id, dir, cx, bob, swing)


static func _sculpt_adult_legs(sc: S.PixelSculptor, id: String, dir: String, cx: float, bob: float, stride: float) -> void:
	var face := -1.0 if dir == "left" else (1.0 if dir == "right" else 0.0)
	var hip_y := 31.5 + bob
	var fy := 38.0
	var is_broad := id in ["bombeiro_ato", "mang_tomas", "kuya_ben", "cap_reyes"]
	var is_crawler := (id == "bombeiro_santos")
	var is_floating := (id in ["senhora_luningning", "vulto_bosque"])

	if is_floating:
		var hem_w := 5.6 if id == "senhora_luningning" else 6.2
		sc.blob(cx + face * 0.4, 33.2 + bob, hem_w, 4.0, T.CLOTH, T.CLOTH_SH, T.CLOTH_HI, 4)
		sc.ragged_hem(int(cx - hem_w), int(cx + hem_w), int(35 + bob * 0.4), T.CLOTH_SH, T.MAW_VOID, int(cx + stride))
		sc.px(int(cx - 2), 38, T.BONE_SH)
		sc.px(int(cx + 2), 38, T.BONE_SH)
		return

	if is_crawler:
		var hip := Vector2(cx - face * 2.5, 30.5 + bob)
		var l_foot := Vector2(cx - (3.6 if dir in ["down", "up"] else face * 4.5 + stride), fy)
		var r_foot := Vector2(cx + (3.6 if dir in ["down", "up"] else -face * 1.5 - stride), fy)
		sc.limb(hip, l_foot, 1.4, 0.95, T.CLOTH, T.CLOTH_SH, Vector2(-1.8, -2.5))
		sc.limb(hip, r_foot, 1.4, 0.95, T.CLOTH_SH, T.CLOTH_SH, Vector2(1.8, -2.5))
		return

	var r_leg := 1.65 if is_broad else 1.2
	var spread := 3.0 if is_broad else 2.3
	if dir in ["down", "up"]:
		var l_p := Vector2(cx - spread, fy - clampf(stride * 0.4, -1.8, 1.8))
		var r_p := Vector2(cx + spread, fy + clampf(stride * 0.4, -1.8, 1.8))
		sc.limb(Vector2(cx - spread * 0.7, hip_y), l_p, r_leg, 1.0, T.CLOTH, T.CLOTH_SH)
		sc.limb(Vector2(cx + spread * 0.7, hip_y), r_p, r_leg, 1.0, T.CLOTH_SH)
	else:
		var back_foot := Vector2(cx - stride - face * 1.0, fy)
		var front_foot := Vector2(cx + stride + face * 1.5, fy)
		sc.limb(Vector2(cx - face * 0.5, hip_y), back_foot, r_leg, 0.95, T.CLOTH_SH)
		sc.limb(Vector2(cx + face * 0.5, hip_y), front_foot, r_leg, 1.0, T.CLOTH, T.CLOTH_SH)


static func _sculpt_adult_torso_and_head(sc: S.PixelSculptor, id: String, dir: String, cx: float, bob: float, hx_off: float, hy_off: float, jw: int) -> void:
	var face := -1.0 if dir == "left" else (1.0 if dir == "right" else 0.0)
	var tor_c := Vector2(cx + face * 0.9, 27.5 + bob)

	# ---------------------------------------------------------
	# TRONCO (compacto SNES, y=23..33)
	# ---------------------------------------------------------
	match id:
		"cap_reyes":
			sc.blob(tor_c.x, tor_c.y, 5.4, 4.4, T.CLOTH, T.CLOTH_SH, T.CLOTH_HI, 2)
			for x in range(int(tor_c.x - 5), int(tor_c.x + 6)):
				if sc.has_px(x, int(tor_c.y + 3)):
					sc.px(x, int(tor_c.y + 3), T.ACCENT)
			if dir != "up":
				sc.blob(tor_c.x + face * 1.5, tor_c.y, 1.9, 3.0, T.MAW_VOID, T.BLOOD_SH)
				for ry in [-1, 1]:
					sc.px(int(tor_c.x + face * 1.5 - 1), int(tor_c.y + ry), T.BONE_HI)
					sc.px(int(tor_c.x + face * 1.5 + 1), int(tor_c.y + ry), T.BONE)

		"bombeiro_ato":
			# Corcunda alta nas costas + casaco BFP grosso com faixa laranja/amarela
			sc.blob(tor_c.x - face * 1.0, tor_c.y - 1.0, 6.2, 4.8, T.CLOTH, T.CLOTH_SH, T.CLOTH_HI, 3)
			var hump_x := tor_c.x + (-2.5 if dir in ["down", "up"] else -face * 3.0)
			sc.blob(hump_x, tor_c.y - 4.2, 3.6, 2.8, T.FLESH, T.BLOOD_SH, T.BLOOD_HI, 2)
			for x in range(int(tor_c.x - 5), int(tor_c.x + 6)):
				if sc.has_px(x, int(tor_c.y + 2)):
					sc.px(x, int(tor_c.y + 2), T.ACCENT_HI if x % 2 == 0 else T.ACCENT)

		"bombeiro_santos":
			var hunch := Vector2(cx + face * 2.2, 26.8 + bob)
			sc.blob(hunch.x, hunch.y, 5.0, 3.3, T.CLOTH, T.CLOTH_SH, T.CLOTH_HI, 3)
			if dir == "up":
				for vy in range(-2, 3):
					sc.px(int(hunch.x), int(hunch.y + vy), T.BONE if vy % 2 == 0 else T.EYE_GLOW)
			else:
				sc.blob(hunch.x + face * 1.2, hunch.y + 0.5, 2.1, 1.9, T.MAW_VOID, T.BLOOD_SH)
				sc.px(int(hunch.x + face * 1.2 - 1), int(hunch.y), T.BONE)
				sc.px(int(hunch.x + face * 1.2 + 1), int(hunch.y), T.BONE)
				sc.px(int(hunch.x + face * 1.2), int(hunch.y + 1), T.EYE_CORE)

		"enfermeira_maria":
			sc.blob(tor_c.x - face * 0.4, tor_c.y, 3.9, 4.4, T.ACCENT, T.ACCENT_SH, T.ACCENT_HI, 1)
			sc.blob(tor_c.x + face * 0.4, tor_c.y + 0.4, 3.0, 4.0, T.CLOTH, T.CLOTH_SH, T.CLOTH_HI, 2)
			if dir != "up":
				sc.px(int(tor_c.x + face), int(tor_c.y - 1), T.FLESH)
				sc.px(int(tor_c.x + face - 1), int(tor_c.y + 1), T.BLOOD_HI)
				sc.px(int(tor_c.x + face), int(tor_c.y + 2), T.BLOOD_SH)

		"aling_nena":
			sc.blob(tor_c.x, tor_c.y, 4.5, 4.4, T.CLOTH, T.CLOTH_SH, T.CLOTH_HI, 3)
			if dir != "up":
				sc.blob(tor_c.x + face * 0.7, tor_c.y + 0.4, 3.1, 3.8, T.ACCENT, T.ACCENT_SH, T.ACCENT_HI)
			var twig_x := tor_c.x - face * 2.2
			sc.limb(Vector2(twig_x - 1, tor_c.y - 2), Vector2(twig_x - 4.8, tor_c.y - 8.0), 0.65, 0.35, T.WOOD_SH)
			sc.limb(Vector2(twig_x + 2, tor_c.y - 2.5), Vector2(twig_x + 5.2, tor_c.y - 7.5), 0.65, 0.35, T.WOOD)

		"kuya_ben":
			sc.blob(tor_c.x + 0.8, tor_c.y - 0.5, 5.6, 4.4, T.SKIN, T.SKIN_SH, T.SKIN_HI, 3)
			sc.blob(tor_c.x, tor_c.y + 0.8, 5.0, 3.9, T.CLOTH, T.CLOTH_SH, T.CLOTH_HI, 2)
			if dir != "up":
				sc.limb(tor_c + Vector2(-2.2, -3.5), tor_c + Vector2(-1.8, 1), 0.8, 0.65, T.CLOTH_HI)

		"mang_tomas":
			# Corcunda larga com BOCA DENTUÇA NA BARRIGA (y=24..31)
			sc.blob(tor_c.x, tor_c.y, 6.6, 4.8, T.ACCENT, T.ACCENT_SH, T.ACCENT_HI, 3)
			if dir == "up":
				sc.blob(tor_c.x, tor_c.y, 6.2, 4.4, T.CLOTH, T.CLOTH_SH, T.CLOTH_HI, 2)
			else:
				var maw_w := 4.4 if dir == "down" else 3.0
				var maw_cx := tor_c.x + face * 2.5
				var maw_cy := tor_c.y + 0.4
				sc.blob(maw_cx, maw_cy, maw_w, 2.4 + float(jw) * 0.35, T.MAW_VOID, T.BLOOD_SH)
				for dx in range(-int(maw_w) + 1, int(maw_w), 2):
					sc.px(int(maw_cx) + dx, int(maw_cy - 1), T.BONE_HI)
					sc.px(int(maw_cx) + dx + 1, int(maw_cy + 1), T.BONE)
				sc.px(int(maw_cx), int(maw_cy + 2), T.BLOOD_HI)

		"mang_carding":
			# Tórax magro com costelas curvas em xilofone (diferente de costas x frente)
			sc.blob(tor_c.x, tor_c.y + 2.0, 3.8, 2.6, T.CLOTH, T.CLOTH_SH, T.CLOTH_HI)
			sc.blob(tor_c.x, tor_c.y - 1.0, 4.0, 3.4, T.SKIN_SH, T.SKIN_SH, T.SKIN, 2)
			if dir == "up":
				for ry in [-3, -1, 1]:
					sc.px(int(tor_c.x), int(tor_c.y + ry), T.BONE)
				# Alça/corda nas costas
				sc.limb(Vector2(tor_c.x - 3, tor_c.y - 3), Vector2(tor_c.x + 3, tor_c.y + 2), 0.65, 0.65, T.ACCENT_SH)
			else:
				for ry in [-3, -1, 1]:
					sc.limb(Vector2(tor_c.x - 2.6, tor_c.y + float(ry)), Vector2(tor_c.x + 2.6, tor_c.y + float(ry)), 0.5, 0.5, T.BONE)
			# Fita turquesa esfarrapada voando
			sc.limb(Vector2(tor_c.x - face * 2.0, tor_c.y - 5.0), Vector2(tor_c.x - face * 7.0 - 2.5, tor_c.y - 1.5), 0.75, 0.35, T.HAT)

		"senhora_luningning":
			sc.blob(tor_c.x, tor_c.y, 4.8, 4.2, T.ACCENT, T.ACCENT_SH, T.ACCENT_HI, 4)
			sc.ragged_hem(int(tor_c.x - 4), int(tor_c.x + 4), int(tor_c.y + 3), T.ACCENT_SH, T.CLOTH, 7)

		"lola_rosa":
			sc.blob(tor_c.x - face * 0.8, tor_c.y, 4.8, 4.2, T.CLOTH, T.CLOTH_SH, T.CLOTH_HI, 4)
			sc.limb(Vector2(tor_c.x - face * 2.5, tor_c.y - 2.5), Vector2(tor_c.x - face * 5.8, tor_c.y - 7.5), 0.7, 0.35, T.WOOD_SH)
			sc.limb(Vector2(tor_c.x - face * 1.5, tor_c.y - 1.0), Vector2(tor_c.x - face * 6.8, tor_c.y - 4.0), 0.6, 0.35, T.WOOD)

		"vulto_bosque":
			sc.blob(tor_c.x, tor_c.y, 5.2, 4.8, T.CLOTH, T.CLOTH_SH, T.CLOTH_HI, 5)
			if dir == "up":
				# Coluna carbonizada nas costas (sem fogo no peito visto por trás)
				for dy in range(-3, 4, 2):
					sc.px(int(tor_c.x), int(tor_c.y + dy), T.BONE_SH)
			else:
				for dy in range(-3, 4):
					var jx := (dy % 2)
					sc.px(int(tor_c.x + face * 1.3 + jx), int(tor_c.y + dy), T.EYE_CORE if abs(dy) <= 1 else T.EYE_GLOW)
					sc.px(int(tor_c.x + face * 1.3 + jx - 1), int(tor_c.y + dy), T.ACCENT)

	# ---------------------------------------------------------
	# PESCOÇO & CABEÇA COMPACTA SNES (topo ~y=13..16, sem alongamento excessivo!)
	# ---------------------------------------------------------
	var hc := Vector2(cx + face * 1.3 + hx_off, 18.8 + bob + hy_off)
	if id == "bombeiro_santos":
		hc = Vector2(cx + face * 5.2 + hx_off, 22.8 + bob + hy_off)
	elif id == "cap_reyes":
		hc = Vector2(cx + (1.8 if dir in ["down", "up"] else face * 2.0) + hx_off, 18.2 + bob + hy_off)
	elif id == "bombeiro_ato":
		hc = Vector2(cx + face * 2.2 + hx_off, 19.6 + bob + hy_off)
	elif id == "enfermeira_maria":
		hc = Vector2(cx + (2.4 if dir == "down" else (-2.4 if dir == "up" else face * 1.8)) + hx_off, 17.8 + bob + hy_off)
	elif id == "senhora_luningning":
		hc = Vector2(cx + (3.5 if dir in ["down", "up"] else face * 2.5) + hx_off, 19.8 + bob + hy_off) # cabeça tombada de lado
	elif id == "lola_rosa":
		hc = Vector2(cx + face * 3.2 + hx_off, 20.8 + bob + hy_off)
	elif id == "vulto_bosque":
		hc = Vector2(cx + face * 1.0 + hx_off, 16.8 + bob + hy_off)

	sc.limb(tor_c + Vector2(0, -3.0), hc, 1.2, 0.9, T.SKIN_SH, T.BLOOD_SH, Vector2(-face * 0.8, 0.4))

	if id == "vulto_bosque":
		sc.blob(hc.x, hc.y, 4.2, 4.2, T.MAW_VOID, T.CLOTH_SH, T.SKIN_HI, 4)
	elif id == "mang_carding":
		# Crânio fino afunilado (sem cara quadrada!)
		sc.blob(hc.x, hc.y - 0.5, 3.8, 3.0, T.SKIN, T.SKIN_SH, T.SKIN_HI, 1)
		sc.blob(hc.x + face * 0.6, hc.y + 1.8, 2.7, 2.0, T.SKIN_SH, T.MAW_VOID)
	else:
		sc.blob(hc.x, hc.y, 4.2, 3.7, T.SKIN, T.SKIN_SH, T.SKIN_HI, 2)

	# Rosto horror (oculto de costas!)
	if dir != "up":
		var fx_e := face * 1.4
		if id == "cap_reyes":
			sc.blob(hc.x + fx_e, hc.y + 1.8 + float(jw) * 0.3, 1.8, 1.9 + float(jw) * 0.3, T.MAW_VOID, T.BLOOD_SH)
			sc.px(int(hc.x + fx_e - 1), int(hc.y + 1), T.BONE_HI)
			sc.px(int(hc.x + fx_e + 1), int(hc.y + 1), T.BONE_HI)
			_draw_eyes(sc, hc, dir, T.EYE_GLOW, T.EYE_CORE, true)
		elif id == "bombeiro_ato":
			# Queimadura lateral + visor negro rachado com UM olho vermelho vivo
			sc.blob(hc.x + fx_e, hc.y + 0.5, 2.6, 1.9, T.FLESH, T.BLOOD_SH)
			sc.blob(hc.x + fx_e, hc.y - 0.5, 2.8, 1.1, T.MAW_VOID)
			var ex := int(round(hc.x + fx_e + (1.0 if dir != "left" else -1.0)))
			sc.px(ex, int(round(hc.y - 0.5)), T.EYE_GLOW)
			sc.px(int(round(hc.x + fx_e)), int(round(hc.y - 0.5)), T.EYE_CORE)
		elif id == "bombeiro_santos":
			sc.blob(hc.x + fx_e, hc.y, 2.8, 1.9, T.MAW_VOID)
			_draw_eyes(sc, hc, dir, T.EYE_GLOW, T.EYE_CORE, false)
			sc.px(int(hc.x + fx_e), int(hc.y + 2), T.BONE)
		elif id == "enfermeira_maria":
			_draw_eyes(sc, hc, dir, T.MAW_VOID, T.EYE_GLOW, true)
			for dy in [1, 2]:
				sc.px(int(hc.x + fx_e - 1), int(hc.y + dy), T.BLOOD_HI)
				if dir == "down":
					sc.px(int(hc.x + fx_e + 1), int(hc.y + dy), T.BLOOD_HI)
			sc.limb(hc + Vector2(fx_e - 1.8, 1.8), hc + Vector2(fx_e + 1.8, 2.0), 0.4, 0.4, T.FLESH)
		elif id == "aling_nena":
			sc.blob(hc.x + fx_e, hc.y + 2.0 + float(jw) * 0.4, 2.1, 2.6 + float(jw) * 0.4, T.MAW_VOID, T.BLOOD_SH)
			sc.px(int(hc.x + fx_e - 1), int(hc.y + 1), T.BONE_HI)
			sc.px(int(hc.x + fx_e + 1), int(hc.y + 1), T.BONE_HI)
			sc.px(int(hc.x + fx_e), int(hc.y + 3), T.BONE_HI)
			_draw_eyes(sc, hc + Vector2(0, -1.2), dir, T.EYE_GLOW, T.EYE_CORE, false)
		elif id == "kuya_ben":
			_draw_eyes(sc, hc, dir, T.EYE_GLOW, T.EYE_CORE, false)
			sc.px(int(hc.x + fx_e), int(hc.y - 2), T.MAW_VOID)
			sc.px(int(hc.x + fx_e), int(hc.y - 1), T.EYE_GLOW)
		elif id == "mang_tomas":
			sc.limb(hc + Vector2(fx_e - 1.8, -0.4), hc + Vector2(fx_e + 1.8, -0.4), 0.45, 0.45, T.MAW_VOID)
			sc.px(int(hc.x + fx_e + 1), int(hc.y + 1), T.FLESH)
		elif id == "mang_carding":
			_draw_eyes(sc, hc, dir, T.MAW_VOID, T.EYE_GLOW, false)
			sc.limb(hc + Vector2(fx_e - 1.6, 1.6), hc + Vector2(fx_e + 1.6, 1.6), 0.45, 0.45, T.BONE_HI)
		elif id == "senhora_luningning":
			# Cabeça tombada + olhão fundo vermelho-branco + rasgo bucal vertical
			sc.blob(hc.x + fx_e, hc.y, 1.9, 1.9, T.MAW_VOID)
			sc.px(int(hc.x + fx_e), int(hc.y - 1), T.EYE_CORE)
			sc.px(int(hc.x + fx_e + 1), int(hc.y), T.EYE_GLOW)
			sc.px(int(hc.x + fx_e), int(hc.y + 2), T.BLOOD_SH)
		elif id == "lola_rosa":
			_draw_eyes(sc, hc + Vector2(0, -0.8), dir, T.EYE_GLOW, T.EYE_CORE, false)
			sc.limb(hc + Vector2(fx_e - 1.8, 1.6), hc + Vector2(fx_e + 1.8, 1.6), 0.4, 0.4, T.MAW_VOID)
			for sx in [-1, 1]:
				sc.px(int(hc.x + fx_e + sx), int(hc.y + 1), T.OUT)
				sc.px(int(hc.x + fx_e + sx), int(hc.y + 2), T.OUT)
		elif id == "vulto_bosque":
			sc.px(int(hc.x + fx_e - (1.4 if dir == "down" else 0.0)), int(hc.y), T.EYE_CORE)
			if dir == "down":
				sc.px(int(hc.x + 1.4), int(hc.y), T.EYE_CORE)
			sc.px(int(hc.x + fx_e), int(hc.y + 2), T.EYE_GLOW)

	# ---------------------------------------------------------
	# CHAPÉUS / CAPACETES / CABELOS RECONHECÍVEIS
	# ---------------------------------------------------------
	match id:
		"cap_reyes":
			sc.blob(hc.x - 0.8, hc.y - 2.8, 4.5, 1.7, T.HAT, T.HAT_SH, T.HAT_HI)
			sc.px(int(hc.x + face * 1.4), int(hc.y - 3), T.BLOOD_HI)
			sc.px(int(hc.x + face * 1.4 + 1), int(hc.y - 3), T.ACCENT_HI)
		"bombeiro_ato":
			# CAPACETE BFP AMARELO LARGO COM ABA TRASEIRA (fiel ao original!)
			sc.blob(hc.x - face * 0.5, hc.y - 3.0, 4.9, 2.1, T.HAT, T.HAT_SH, T.HAT_HI, 1)
			sc.limb(hc + Vector2(-5.2 - face, -1.6), hc + Vector2(4.8 - face, -1.4), 0.85, 0.75, T.HAT_HI)
			sc.px(int(hc.x + 1), int(hc.y - 4), T.MAW_VOID)
		"bombeiro_santos":
			sc.blob(hc.x - face, hc.y - 2.4, 4.0, 2.0, T.HAIR, T.HAIR_SH, T.HAIR, 5)
		"enfermeira_maria":
			sc.blob(hc.x - face * 0.4, hc.y - 2.0, 4.4, 2.3, T.HAIR, T.HAIR_SH, T.HAIR, 3)
			sc.blob(hc.x - 2.0, hc.y - 3.9, 2.0, 1.1, T.HAT, T.HAT_SH, T.HAT_HI)
			sc.limb(hc + Vector2(-3.2, 0), hc + Vector2(-4.8, 4.8), 0.9, 0.5, T.HAIR_SH)
			sc.px(int(hc.x - 3), int(hc.y + 1), T.BLOOD_HI)
		"aling_nena":
			sc.blob(hc.x, hc.y - 2.5, 4.0, 2.0, T.HAIR, T.HAIR_SH, T.HAIR, 4)
			sc.blob(hc.x - 1.2, hc.y - 4.4, 1.8, 1.3, T.HAIR_SH, T.HAIR_SH)
		"kuya_ben":
			sc.blob(hc.x, hc.y - 2.6, 4.4, 1.8, T.HAT, T.HAT_SH, T.HAT_HI)
			sc.limb(hc + Vector2(-face * 1.4, -2.0), hc + Vector2(-face * 4.5 - 1.5, -1.5), 0.8, 0.65, T.HAT_HI)
		"mang_tomas":
			# SALAKOT CÔNICO LARGO INCLINADO
			var sx := hc.x - 1.0
			var sy := hc.y - 2.6
			sc.limb(Vector2(sx, sy - 4.2), Vector2(sx - 7.0, sy + 1.0), 1.1, 0.65, T.HAT)
			sc.limb(Vector2(sx, sy - 4.2), Vector2(sx + 6.0, sy + 1.8), 1.1, 0.65, T.HAT_SH)
			sc.blob(sx, sy - 1.0, 5.2, 1.5, T.HAT, T.HAT_SH, T.HAT_HI)
			sc.px(int(sx + 2), int(sy - 2), T.MAW_VOID)
		"mang_carding":
			sc.blob(hc.x, hc.y - 2.2, 3.8, 1.4, T.HAT, T.HAT_SH, T.HAT_HI)
			sc.blob(hc.x, hc.y - 3.3, 3.0, 1.0, T.HAIR, T.HAIR_SH)
		"senhora_luningning":
			# Mechas prateadas soltas pingando da cabeça tombada
			sc.blob(hc.x, hc.y - 2.2, 4.2, 1.9, T.HAIR, T.HAIR_SH, T.HAT_HI, 4)
			sc.limb(hc + Vector2(2.0, -1), hc + Vector2(4.2, 5.5), 0.9, 0.4, T.HAIR_SH)
			sc.limb(hc + Vector2(-2.5, 0), hc + Vector2(-3.5, 4.5), 0.7, 0.35, T.HAIR)
		"lola_rosa":
			# Lenço mortalha caindo em pontas pelos ombros (jamais capacete redondo!)
			sc.blob(hc.x - face * 0.4, hc.y - 2.0, 4.3, 2.2, T.HAT, T.HAT_SH, T.HAT_HI, 2)
			sc.limb(hc + Vector2(-face * 2.5 - 2.0, -1), hc + Vector2(-face * 3.8 - 2.5, 5.8), 1.0, 0.5, T.HAT_SH)
			sc.limb(hc + Vector2(-face * 2.5 + 2.0, -1), hc + Vector2(-face * 3.8 + 2.2, 5.2), 0.9, 0.45, T.HAT)
		"vulto_bosque":
			sc.limb(hc + Vector2(-2.2, -3.0), hc + Vector2(-5.0, -6.2), 1.2, 0.4, T.HAT, T.HAT_SH)
			sc.limb(hc + Vector2(2.2, -3.0), hc + Vector2(4.6, -5.8), 1.2, 0.4, T.HAT_SH)
			sc.px(int(hc.x), int(hc.y - 4), T.EYE_GLOW)


static func _draw_eyes(sc: S.PixelSculptor, hc: Vector2, dir: String, col_a: int, col_b: int, vertical_tear: bool) -> void:
	var ey := int(round(hc.y - 0.4))
	if dir == "down":
		sc.px(int(round(hc.x - 1.5)), ey, col_a)
		sc.px(int(round(hc.x + 1.5)), ey, col_a)
		if col_b != col_a:
			sc.px(int(round(hc.x - 1.5)), ey, col_b)
	else:
		var ex := int(round(hc.x + (-1.8 if dir == "left" else 1.8)))
		sc.px(ex, ey, col_a)
		if vertical_tear:
			sc.px(ex, ey + 1, col_b)


static func _sculpt_adult_arms_and_props(sc: S.PixelSculptor, id: String, dir: String, cx: float, bob: float, swing: float) -> void:
	var face := -1.0 if dir == "left" else (1.0 if dir == "right" else 0.0)
	var shoulder_y := 24.5 + bob

	match id:
		"cap_reyes":
			var r_hand := Vector2(cx - 5.4, 31.5 + bob - swing * 1.5)
			var l_hand := Vector2(cx + (6.4 if dir in ["down", "up"] else face * 7.0 + swing * 2.5), 34.0 + bob - swing * 2.0)
			if dir in ["down", "up"]:
				sc.limb(Vector2(cx - 4.2, shoulder_y), r_hand, 1.2, 0.9, T.CLOTH_SH)
				sc.blob(r_hand.x, r_hand.y, 1.4, 1.6, T.METAL_SH)
				sc.px(int(r_hand.x), int(r_hand.y - 1), T.EYE_GLOW)
			sc.limb(Vector2(cx + (4.5 if dir in ["down", "up"] else face * 1.8), shoulder_y), l_hand, 1.4, 1.0, T.CLOTH, T.SKIN_SH, Vector2(face * 1.8, 1.8))
			sc.claws(l_hand, Vector2(face if face != 0.0 else 0.6, 0.8), 2.5, T.BONE_HI, 0.65)

		"bombeiro_ato":
			var arm_dir := 1.0 if dir == "down" else (-1.0 if dir == "up" else face)
			var sh := Vector2(cx + arm_dir * 4.5, shoulder_y)
			var hand := Vector2(cx + arm_dir * (7.5 + swing * 2.2), 34.0 + bob - swing * 4.0)
			sc.limb(sh, hand, 1.9, 1.4, T.FLESH, T.BLOOD_SH, Vector2(arm_dir * 1.8, 1.8))
			var blade_tip := hand + Vector2(arm_dir * 3.0, 2.0 - swing * 2.5)
			sc.limb(hand, blade_tip, 1.5, 1.0, T.METAL, T.METAL_HI)
			sc.px(int(blade_tip.x), int(blade_tip.y), T.BLOOD_HI)
			if dir in ["down", "up"]:
				sc.limb(Vector2(cx - arm_dir * 4.8, shoulder_y), Vector2(cx - arm_dir * 6.0, 34.5 + bob + swing), 1.5, 1.1, T.CLOTH_SH)

		"bombeiro_santos":
			var c_sh := Vector2(cx + face * 3.0, 26.5 + bob)
			var paw1 := Vector2(cx + (6.0 if dir in ["down", "up"] else face * 8.8 + swing * 2.5), 37.2 - maxf(0.0, swing) * 3.0)
			var paw2 := Vector2(cx - (5.6 if dir in ["down", "up"] else -face * 3.0 - swing * 1.8), 37.2)
			sc.limb(c_sh, paw1, 1.2, 0.8, T.SKIN, T.SKIN_SH, Vector2(face * 1.8, 2.5))
			sc.claws(paw1, Vector2(face if face != 0.0 else 0.7, 0.5), 2.2, T.BONE, 0.7)
			if dir in ["down", "up"]:
				sc.limb(Vector2(cx - 3.6, 26.5 + bob), paw2, 1.1, 0.8, T.SKIN_SH)
				sc.claws(paw2, Vector2(-0.7, 0.5), 2.0, T.BONE_SH, 0.7)

		"enfermeira_maria":
			var l_sh := Vector2(cx - 3.5, shoulder_y)
			var r_sh := Vector2(cx + 3.5, shoulder_y)
			var l_elb := Vector2(cx - (6.2 if dir in ["down", "up"] else -face * 3.0), 30.0 + bob)
			var r_elb := Vector2(cx + (6.2 if dir in ["down", "up"] else face * 4.5), 30.0 + bob)
			var tip_r := Vector2(cx + (2.5 if dir in ["down", "up"] else face * 10.5 + swing * 2.5), 35.0 + bob - swing * 4.0)
			var tip_l := Vector2(cx - (2.5 if dir in ["down", "up"] else -face * 7.5), 34.5 + bob - swing * 3.0)
			sc.limb(r_sh, r_elb, 0.95, 0.75, T.SKIN)
			sc.limb(r_elb, tip_r, 0.75, 0.4, T.METAL_HI, T.METAL)
			if dir in ["down", "up"]:
				sc.limb(l_sh, l_elb, 0.95, 0.75, T.SKIN_SH)
				sc.limb(l_elb, tip_l, 0.75, 0.4, T.METAL, T.METAL_SH)
			sc.px(int(tip_r.x), int(tip_r.y), T.BLOOD_HI)

		"aling_nena":
			var hand := Vector2(cx + (5.2 if dir in ["down", "up"] else face * 6.0 + swing * 2.2), 30.5 + bob - swing * 1.8)
			sc.limb(Vector2(cx + face * 2.2, shoulder_y), hand, 1.0, 0.85, T.SKIN)
			sc.limb(hand + Vector2(-face * 2.8, -4.5), hand + Vector2(face * 5.0 + (2.5 if face == 0.0 else 0.0), 5.5), 0.7, 0.5, T.WOOD)
			sc.claws(hand + Vector2(face * 5.0 + (2.5 if face == 0.0 else 0.0), 5.5), Vector2(face, 1.0), 2.2, T.WOOD_SH, 0.8)

		"kuya_ben":
			# CHAVE-INGLESA EM GARRA U NÍTIDA (2 pontas de metal!)
			var hand := Vector2(cx + (6.8 if dir in ["down", "up"] else face * 7.5 + swing * 2.5), 33.5 + bob - swing * 3.5)
			sc.limb(Vector2(cx + 3.6, shoulder_y), hand, 2.0, 1.5, T.SKIN, T.SKIN_SH, Vector2(face * 1.8, 1.8))
			var wr_dir := Vector2(face if face != 0.0 else 0.5, 0.8).normalized()
			var wr_perp := Vector2(-wr_dir.y, wr_dir.x)
			sc.limb(hand, hand + wr_dir * 2.2 + wr_perp * 1.8, 0.75, 0.6, T.METAL_HI)
			sc.limb(hand, hand + wr_dir * 2.2 - wr_perp * 1.8, 0.75, 0.6, T.METAL)
			if dir in ["down", "up"]:
				sc.limb(Vector2(cx - 4.6, shoulder_y), Vector2(cx - 5.5, 33.0 + bob + swing), 1.2, 0.95, T.SKIN_SH)

		"mang_tomas":
			var c_hand := Vector2(cx + (6.8 if dir in ["down", "up"] else face * 7.2 + swing * 2.5), 31.8 + bob - swing * 3.0)
			sc.limb(Vector2(cx + 5.0, shoulder_y), c_hand, 1.5, 1.2, T.SKIN)
			sc.blob(c_hand.x + (1.8 if dir == "down" else face * 2.4), c_hand.y + 1.0 - swing * 1.8, 2.3, 1.9, T.METAL_HI, T.METAL_SH)
			sc.px(int(c_hand.x + face * 2.5), int(c_hand.y + 1.8), T.BLOOD_HI)
			if dir in ["down", "up"]:
				sc.limb(Vector2(cx - 5.5, shoulder_y), Vector2(cx - 6.8, 32.0 + bob), 1.4, 1.0, T.SKIN_SH)

		"mang_carding":
			var r_tip := Vector2(cx + (6.0 if dir in ["down", "up"] else face * 7.8 + swing * 2.5), 35.5 + bob - swing * 3.5)
			var l_tip := Vector2(cx - (6.0 if dir in ["down", "up"] else -face * 4.5 - swing * 1.5), 35.5 + bob)
			sc.limb(Vector2(cx + 3.2, shoulder_y), r_tip, 1.0, 0.7, T.SKIN, T.SKIN_SH, Vector2(face * 2.2, 2.0))
			sc.claws(r_tip, Vector2(face if face != 0.0 else 0.4, 0.9), 2.1, T.BONE_SH, 0.75)
			if dir in ["down", "up"]:
				sc.limb(Vector2(cx - 3.2, shoulder_y), l_tip, 1.0, 0.7, T.SKIN_SH)
				sc.claws(l_tip, Vector2(-0.4, 0.9), 2.0, T.BONE_SH, 0.75)

		"senhora_luningning":
			# Braço estendido segurando LANTERNA DE FERRO COM MINI-CRÂNIO EM BRASA BEM DESTACADA!
			var lan_x := cx - (8.2 if dir in ["down", "up"] else -face * 8.4 - swing * 2.0)
			var lan_y := 29.5 + bob - swing * 1.8
			sc.limb(Vector2(cx - (3.2 if dir in ["down", "up"] else 0.0), shoulder_y), Vector2(lan_x, lan_y - 4.0), 0.85, 0.6, T.SKIN_SH)
			sc.limb(Vector2(lan_x, lan_y - 4.0), Vector2(lan_x, lan_y - 1.5), 0.4, 0.4, T.METAL_HI)
			sc.blob(lan_x, lan_y + 1.2, 2.5, 2.7, T.METAL_SH, T.MAW_VOID, T.METAL)
			sc.blob(lan_x, lan_y + 1.2, 1.4, 1.6, T.FLESH, T.MAW_VOID)
			sc.px(int(lan_x), int(lan_y + 1), T.EYE_GLOW)
			sc.px(int(lan_x), int(lan_y), T.BONE_HI)
			sc.px(int(lan_x), int(lan_y + 2), T.EYE_CORE)

		"lola_rosa":
			var b_x := cx + (6.0 if dir in ["down", "up"] else face * 6.4 + swing * 1.8)
			var b_y := 31.2 + bob - swing * 1.5
			sc.limb(Vector2(cx + face * 1.8, shoulder_y + 1.0), Vector2(b_x, b_y), 0.95, 0.75, T.WOOD_SH)
			sc.blob(b_x, b_y + 1.0, 2.8, 2.0, T.ACCENT, T.ACCENT_SH, T.ACCENT_HI)
			sc.px(int(b_x - 1), int(b_y - 1), T.BLOOD_HI)
			sc.px(int(b_x + 1), int(b_y - 1), T.EYE_GLOW)

		"vulto_bosque":
			var r_paw := Vector2(cx + (6.8 if dir in ["down", "up"] else face * 8.5 + swing * 2.5), 32.2 + bob - swing * 4.0)
			var l_paw := Vector2(cx - (6.8 if dir in ["down", "up"] else -face * 5.2), 32.5 + bob)
			sc.limb(Vector2(cx + 4.0, shoulder_y), r_paw, 1.3, 0.75, T.CLOTH_SH, T.MAW_VOID, Vector2(face * 1.8, 1.0))
			sc.claws(r_paw, Vector2(face if face != 0.0 else 0.7, 0.6), 3.0, T.EYE_GLOW, 0.8)
			if dir in ["down", "up"]:
				sc.limb(Vector2(cx - 4.0, shoulder_y), l_paw, 1.3, 0.75, T.CLOTH_SH)
				sc.claws(l_paw, Vector2(-0.7, 0.6), 2.8, T.ACCENT, 0.8)


# ---------------------------------------------------------------------------
# 11 ESTILOS DE ATAQUE DISTINTOS (longe do rosto, nítidos em 1px!)
# ---------------------------------------------------------------------------
static func _draw_attack_arc(img: Image, _id: String, style: String, dir: String, f_idx: int, pal: Dictionary) -> void:
	if f_idx not in [1, 2, 3]:
		return
	var col_core: Color = pal[T.EYE_CORE]
	var col_edge: Color = pal[T.BLOOD_HI]
	var progress := f_idx - 1 # 0, 1, 2

	match style:
		"cleave_diag": # Arco diagonal largo (machado/garra Reyes)
			_paint_sweep(img, dir, progress, -6, 6, 1.0, pal[T.METAL_HI], pal[T.BLOOD_HI], true)
		"overhead_slam": # Onda pesada de esmagamento vertical à frente
			_paint_smash(img, dir, progress, pal[T.ACCENT_HI], pal[T.BLOOD_HI])
		"pounce_rake": # 3 garras paralelas rasgando à frente (Santos)
			_paint_claws_rake(img, dir, progress, pal[T.EYE_CORE], pal[T.EYE_GLOW])
		"scissor_cross": # Corte em X cirúrgico (Enf. Maria)
			_paint_scissor_x(img, dir, progress, pal[T.METAL_HI], pal[T.BLOOD_HI])
		"broom_sweep": # Varredura ampla por baixo (Aling Nena)
			_paint_sweep(img, dir, progress, -7, 7, 0.35, pal[T.WOOD], pal[T.BLOOD_HI], false)
		"wrench_crush": # Impacto estilhaçado (Kuya Ben)
			_paint_smash(img, dir, progress, pal[T.METAL_HI], pal[T.EYE_GLOW])
		"cleaver_maw": # Cutelo horizontal largo + dentada rubra (Mang Tomas)
			_paint_sweep(img, dir, progress, -7, 7, -0.3, pal[T.METAL_HI], pal[T.FLESH], false)
		"long_thrust": # Estocada longa em perfuração (Mang Carding)
			_paint_thrust(img, dir, progress, pal[T.EYE_GLOW], pal[T.BONE_HI])
		"lantern_curse": # Clarão espectral violeta-rubro (Luningning)
			_paint_curse_burst(img, dir, progress, Color("#FF9EFF"), Color("#A626FF"))
		"spore_swipe": # Esporos de brasa + arco curto (Lola Rosa)
			_paint_curse_burst(img, dir, progress, pal[T.EYE_CORE], pal[T.EYE_GLOW])
		"ember_tear": # Duplo corte flamejante (Vulto Calcinado)
			_paint_claws_rake(img, dir, progress, pal[T.EYE_CORE], pal[T.EYE_GLOW])
		_:
			_paint_sweep(img, dir, progress, -5, 5, 0.0, col_core, col_edge, false)


static func _put_vfx(img: Image, x: int, y: int, c_val: Color) -> void:
	if x >= 2 and x <= 45 and y >= 2 and y <= 41:
		img.set_pixel(x, y, c_val)


static func _paint_sweep(img: Image, dir: String, prog: int, s0: int, s1: int, tilt: float, c_core: Color, c_edge: Color, thick: bool) -> void:
	var dx := -1 if dir == "left" else (1 if dir == "right" else 0)
	var dy := -1 if dir == "up" else (1 if dir == "down" else 0)
	var bx := 24 + dx * (11 + prog * 2)
	var by := 29 + dy * (7 + prog * 2)
	for s in range(s0, s1 + 1):
		var px_x := bx + (s if dx == 0 else int(round(float(s) * tilt)))
		var px_y := by + (int(round(float(s) * tilt)) if dx == 0 else s)
		var is_mid := absf(float(s)) <= 3.0 and prog != 2
		_put_vfx(img, px_x, px_y, c_core if is_mid else c_edge)
		if thick and prog == 1:
			_put_vfx(img, px_x + dx, px_y + 1, c_edge)


static func _paint_smash(img: Image, dir: String, prog: int, c_core: Color, c_edge: Color) -> void:
	var dx := -1 if dir == "left" else (1 if dir == "right" else 0)
	var dy := -1 if dir == "up" else (1 if dir == "down" else 0)
	var tx := 24 + dx * (10 + prog * 2)
	var ty := 34 + dy * 4
	for r in range(-4 - prog, 5 + prog):
		_put_vfx(img, tx + (r if dx == 0 else (prog * dx)), ty + (0 if dx == 0 else int(float(r) * 0.5)), c_edge)
	for k in range(-2, 3):
		_put_vfx(img, tx + k, ty - prog, c_core)


static func _paint_claws_rake(img: Image, dir: String, prog: int, c_core: Color, c_edge: Color) -> void:
	var dx := -1 if dir == "left" else (1 if dir == "right" else 0)
	var dy := -1 if dir == "up" else (1 if dir == "down" else 0)
	var ox := 24 + dx * (9 + prog * 2)
	var oy := 28 + dy * (7 + prog * 2)
	for line_off: int in [-3, 0, 3]:
		for i: int in range(-3, 4):
			var px_x: int = ox + (i if dx == 0 else prog * dx) + (line_off if dy != 0 else 0)
			var px_y: int = oy + (line_off if dx != 0 else int(float(i) * 0.5)) + (i if dy == 0 else 0)
			_put_vfx(img, px_x, px_y, c_core if (prog == 1 and absf(float(i)) <= 1.5) else c_edge)


static func _paint_scissor_x(img: Image, dir: String, prog: int, c_core: Color, c_edge: Color) -> void:
	var dx := -1 if dir == "left" else (1 if dir == "right" else 0)
	var dy := -1 if dir == "up" else (1 if dir == "down" else 0)
	var ox := 24 + dx * (10 + prog)
	var oy := 28 + dy * (7 + prog)
	for i in range(-4, 5):
		_put_vfx(img, ox + i, oy + i, c_core if absf(float(i)) <= 1.0 else c_edge)
		_put_vfx(img, ox + i, oy - i, c_core if absf(float(i)) <= 1.0 else c_edge)


static func _paint_thrust(img: Image, dir: String, prog: int, c_core: Color, c_edge: Color) -> void:
	var dx := -1 if dir == "left" else (1 if dir == "right" else 0)
	var dy := -1 if dir == "up" else (1 if dir == "down" else 0)
	var ox := 24 + dx * 6
	var oy := 29 + dy * 5
	for step_i in range(2, 10 + prog * 2):
		var px_x := ox + dx * step_i
		var px_y := oy + dy * step_i
		_put_vfx(img, px_x, px_y, c_core if step_i >= 7 else c_edge)


static func _paint_curse_burst(img: Image, dir: String, prog: int, c_core: Color, c_edge: Color) -> void:
	var dx := -1 if dir == "left" else (1 if dir == "right" else 0)
	var dy := -1 if dir == "up" else (1 if dir == "down" else 0)
	var ox := 24 + dx * 10
	var oy := 29 + dy * 6
	var rad := 3 + prog * 2
	for ang_i in range(8):
		var a := float(ang_i) * PI * 0.25 + float(prog) * 0.4
		var px_x := int(round(ox + cos(a) * rad))
		var px_y := int(round(oy + sin(a) * rad * 0.7))
		_put_vfx(img, px_x, px_y, c_core if ang_i % 2 == 0 else c_edge)


static func _tint_hurt_flash(img: Image) -> void:
	# Preserva o contorno escuro crisp de 1px e roupas escuras; flash rubro sutil sem virar bloco rosa.
	for y in range(48):
		for x in range(48):
			var c_cur := img.get_pixel(x, y)
			if c_cur.a <= 0.1:
				continue
			if (c_cur.r + c_cur.g + c_cur.b) < 0.35:
				continue
			img.set_pixel(x, y, c_cur.lerp(Color("#FF4A5E"), 0.28))


# ---------------------------------------------------------------------------
# MORTES VARIADAS POR ARQUÉTIPO (ancoradas em y = 39)
# ---------------------------------------------------------------------------
static func _sculpt_death(sc: S.PixelSculptor, id: String, dir: String, f_idx: int) -> void:
	var face := -1.0 if dir == "left" else 1.0
	if f_idx == 0:
		_sculpt_creature(sc, id, dir, "hurt", 0, _calc_motion(id, dir, "hurt", 0))
		return
	elif f_idx == 1:
		sc.blob(24 + face * 2, 31.5, 5.8, 4.2, T.CLOTH, T.CLOTH_SH, T.CLOTH_HI, 4)
		sc.blob(24 + face * 4.5, 26.5, 3.8, 3.3, T.SKIN_SH, T.MAW_VOID, T.SKIN)
		sc.limb(Vector2(20, 35), Vector2(14, 38), 1.3, 0.9, T.SKIN_SH)
		sc.limb(Vector2(27, 35), Vector2(33, 38), 1.3, 0.9, T.BONE_SH)
		return

	var cx := 24.0
	if id in ["bombeiro_santos", "mang_carding", "vulto_bosque"]:
		# Monte desfeito de ossos/costelas ou cinzas fumegantes no chão
		sc.blob(cx, 36.6, 8.2, 1.9, T.MAW_VOID if id == "vulto_bosque" else T.BLOOD_SH, T.CLOTH_SH, T.SKIN_SH, 5)
		sc.blob(cx - 2.0, 35.4, 3.6, 2.0, T.BONE_SH if id != "vulto_bosque" else T.CLOTH, T.MAW_VOID)
		for rx in [-4, 0, 3]:
			sc.px(int(cx + rx), 35, T.EYE_GLOW if (id == "vulto_bosque" and f_idx <= 4) else T.BONE_HI)
	elif id == "mang_tomas":
		# Carcaça aberta com boca na barriga exposta + salakot caído virado
		sc.blob(cx - 1.5, 35.8, 7.6, 2.6, T.ACCENT, T.BLOOD_SH, T.CLOTH, 4)
		sc.blob(cx - 1.0, 35.6, 3.6, 1.4, T.MAW_VOID)
		sc.px(int(cx - 2), 35, T.BONE_HI)
		sc.px(int(cx), 36, T.BONE_HI)
		sc.blob(cx + 8.5, 36.2, 3.5, 1.6, T.HAT, T.HAT_SH, T.HAT_HI)
	elif id == "senhora_luningning":
		# Xale roxo vazio esparramado + lanterna com crânio caído ao lado
		sc.blob(cx - 1.0, 36.5, 7.2, 2.0, T.ACCENT_SH, T.CLOTH_SH, T.ACCENT, 4)
		sc.blob(cx + 7.5, 36.6, 2.0, 1.7, T.METAL_SH, T.MAW_VOID)
		sc.px(int(cx + 7), 36, T.BLOOD_SH if f_idx >= 4 else T.EYE_GLOW)
	elif id == "enfermeira_maria":
		# Avental ensanguentado caído + tesouras prateadas soltas
		sc.blob(cx, 36.0, 6.8, 2.2, T.BLOOD_SH, T.CLOTH_SH, T.CLOTH, 4)
		sc.limb(Vector2(cx + 4, 35), Vector2(cx + 9, 38), 0.7, 0.4, T.METAL_HI)
		sc.limb(Vector2(cx + 8, 35), Vector2(cx + 4, 38), 0.7, 0.4, T.METAL)
	else:
		# Tombado de lado com chapéu/capacete/ferramenta caída ao lado
		sc.blob(cx, 36.2, 8.0, 2.3, T.BLOOD_SH if f_idx >= 4 else T.CLOTH_SH, T.MAW_VOID, T.CLOTH, 4)
		sc.blob(cx - face * 2.5, 35.4, 4.8, 2.1, T.CLOTH, T.CLOTH_SH, T.CLOTH_HI, 3)
		sc.blob(cx + face * 4.2, 34.8, 3.0, 2.3, T.SKIN_SH, T.MAW_VOID, T.BONE_SH, 2)
		if id in ["cap_reyes", "bombeiro_ato", "kuya_ben", "lola_rosa"]:
			sc.blob(cx + face * 7.8, 36.5, 2.8, 1.4, T.HAT, T.HAT_SH, T.HAT_HI)
	if f_idx <= 3:
		sc.px(int(cx + face * 3.5), 35, T.EYE_GLOW)
