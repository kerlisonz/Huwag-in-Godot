extends RefCounted
class_name NpcLote2Ext

## Lote 2 companion builder module for NpcSpriteBuilder:
## - Organic outfit sculpting (Aling Nena, Kuya Ben, Mang Tomas, Mang Carding, Toby, Luningning, Lola Rosa, Vulto)
## - Bespoke Talk props & gestures
## - 7 distinct Attack choreographies (no Toby combat, no cloned arcs)
## - 7 distinct y=39 Death / Dissolve silhouettes

const T1 = preload("res://scripts/tools/npc_pixel_rig/npc_humanoid_templates.gd")
const T2 = preload("res://scripts/tools/npc_pixel_rig/npc_lote2_templates.gd")

const OFF_X := 8
const OFF_Y := 10
const FOOT_CELL_Y := 39


static func c(hex: String) -> Color:
	return Color(hex)


static func get_base_grid(spec: Dictionary, dir: String, pose: String) -> Array[String]:
	if str(spec.get("build", "standard")) == "child":
		return T2.get_child_base_grid(dir, pose)
	return T1.get_base_grid(dir, pose)


static func get_head_overlay(head_id: String, dir: String) -> Array[String]:
	return T2.get_head_overlay(head_id, dir)


# ---------------------------------------------------------------------------
# Lote 2 Outfit Sculpting (curves smoothly around organic A-frame silhouette)
# ---------------------------------------------------------------------------
static func apply_outfit_sculpt(can: Object, spec: Dictionary, is_dist: bool, dir: String, _pose: String) -> void:
	var style: String = str(spec["outfit_style"])

	match style:
		"sari_apron":
			_replace_in(can, "Z", "g", 12, 21, 17, 23)
			if dir == "down":
				for y in range(18, 24):
					for x in range(13, 21):
						if can.get_c(OFF_X + x, OFF_Y + y) in ["j", "m", "T", "g"]:
							can.set_c(OFF_X + x, OFF_Y + y, "Z" if y >= 20 else "g")
				for y in [24, 25]:
					for x in range(12, 22):
						if can.get_c(OFF_X + x, OFF_Y + y) in ["o", "v", "k"]:
							can.set_c(OFF_X + x, OFF_Y + y, "Z" if (x >= 14 and x <= 19) else ("j" if y == 24 else "m"))
				can.set_c(OFF_X + 12, OFF_Y + 25, "k")
				can.set_c(OFF_X + 21, OFF_Y + 25, "k")
			elif dir == "up":
				for y in [24, 25]:
					for x in range(12, 22):
						if can.get_c(OFF_X + x, OFF_Y + y) in ["o", "v", "k"]:
							can.set_c(OFF_X + x, OFF_Y + y, "j" if y == 24 else "m")
				can.set_c(OFF_X + 15, OFF_Y + 21, "g")
				can.set_c(OFF_X + 18, OFF_Y + 21, "g")
				can.set_c(OFF_X + 16, OFF_Y + 22, "Z")
				can.set_c(OFF_X + 17, OFF_Y + 22, "Z")
			else:
				for y in range(19, 24):
					var fx := 12 if dir == "left" else 19
					if can.get_c(OFF_X + fx, OFF_Y + y) in ["j", "m", "Z", "g"]:
						can.set_c(OFF_X + fx, OFF_Y + y, "Z")
				for y in [24, 25]:
					for x in range(12, 21):
						if can.get_c(OFF_X + x, OFF_Y + y) in ["o", "v", "k"]:
							can.set_c(OFF_X + x, OFF_Y + y, "j" if x > 14 else "Z")

		"mechanic_overalls":
			_replace_in(can, "Z", "j", 12, 21, 17, 23)
			if dir == "down":
				for y in range(19, 24):
					for x in range(13, 21):
						if can.get_c(OFF_X + x, OFF_Y + y) in ["g", "j", "m"]:
							can.set_c(OFF_X + x, OFF_Y + y, "j" if y < 22 else "m")
				can.set_c(OFF_X + 14, OFF_Y + 19, "Y")
				can.set_c(OFF_X + 19, OFF_Y + 19, "Y")
				for ty in [17, 18, 19, 20]:
					can.set_c(OFF_X + 14, OFF_Y + ty, "N")
					can.set_c(OFF_X + 19, OFF_Y + ty, "N")
				can.set_c(OFF_X + 15, OFF_Y + 17, "N")
				can.set_c(OFF_X + 18, OFF_Y + 17, "N")
				if is_dist:
					can.set_c(OFF_X + 14, OFF_Y + 20, "R")
					can.set_c(OFF_X + 17, OFF_Y + 21, "R")
			elif dir == "up":
				for tx in range(13, 21):
					can.set_c(OFF_X + tx, OFF_Y + 17, "N")
					can.set_c(OFF_X + tx, OFF_Y + 18, "N" if tx in [14, 15, 18, 19] else "g")
				can.set_c(OFF_X + 14, OFF_Y + 19, "N")
				can.set_c(OFF_X + 19, OFF_Y + 19, "N")
			else:
				var fx := 13 if dir == "left" else 18
				for ty in [17, 18, 19, 20]:
					can.set_c(OFF_X + fx, OFF_Y + ty, "N")
				can.set_c(OFF_X + fx + (1 if dir == "left" else -1), OFF_Y + 18, "Y")

		"market_apron":
			_replace_in(can, "Z", "g", 11, 22, 17, 23)
			if dir == "down":
				for y in range(18, 27):
					for x in range(13, 21):
						if can.get_c(OFF_X + x, OFF_Y + y) in ["j", "m", "T", "g", "o", "v", "k"]:
							if y <= 23 or (x >= 13 and x <= 20):
								can.set_c(OFF_X + x, OFF_Y + y, "Z" if y >= 21 else "g")
				can.set_c(OFF_X + 13, OFF_Y + 26, "k")
				can.set_c(OFF_X + 20, OFF_Y + 26, "k")
			elif dir == "up":
				for bx in range(13, 21):
					if can.get_c(OFF_X + bx, OFF_Y + 21) != ".":
						can.set_c(OFF_X + bx, OFF_Y + 21, "X")
				for y in [24, 25]:
					for x in [13, 20]:
						if can.get_c(OFF_X + x, OFF_Y + y) != ".":
							can.set_c(OFF_X + x, OFF_Y + y, "Z")
			else:
				for y in range(19, 27):
					var fx0 := 11 if dir == "left" else 15
					var fx1 := 16 if dir == "left" else 20
					for x in range(fx0, fx1):
						if can.get_c(OFF_X + x, OFF_Y + y) in ["j", "m", "g", "o", "v", "Z"]:
							can.set_c(OFF_X + x, OFF_Y + y, "Z")

		"pier_fisherman":
			var rope_pts: Array[Vector2i] = []
			if dir == "down":
				rope_pts = [Vector2i(13, 17), Vector2i(14, 18), Vector2i(15, 19), Vector2i(16, 20), Vector2i(17, 21), Vector2i(18, 22)]
			elif dir == "up":
				rope_pts = [Vector2i(19, 17), Vector2i(18, 18), Vector2i(17, 19), Vector2i(16, 20), Vector2i(15, 21)]
			elif dir == "left":
				rope_pts = [Vector2i(17, 18), Vector2i(16, 19), Vector2i(15, 20), Vector2i(14, 21), Vector2i(13, 22)]
			else:
				rope_pts = [Vector2i(14, 18), Vector2i(15, 19), Vector2i(16, 20), Vector2i(17, 21), Vector2i(18, 22)]
			for i in range(rope_pts.size()):
				var pt := rope_pts[i]
				can.set_c(OFF_X + pt.x, OFF_Y + pt.y, "N" if (i % 2 == 0) else "I")
			_replace_in(can, "v", "d", 11, 23, 26, 28)
			_replace_in(can, "o", "l", 11, 23, 26, 28)

		"kid_tee_backpack":
			if dir == "up":
				can.set_c(OFF_X + 15, OFF_Y + 20, "Y")
				can.set_c(OFF_X + 16, OFF_Y + 20, "Y")
				can.set_c(OFF_X + 17, OFF_Y + 20, "Y")
				can.set_c(OFF_X + 18, OFF_Y + 20, "Y")
			elif dir == "left":
				can.set_c(OFF_X + 21, OFF_Y + 20, "Y")
				can.set_c(OFF_X + 21, OFF_Y + 21, "Y")
			elif dir == "right":
				can.set_c(OFF_X + 10, OFF_Y + 20, "Y")
				can.set_c(OFF_X + 10, OFF_Y + 21, "Y")

		"luningning_shawl":
			_replace_in(can, "g", "j", 12, 21, 17, 23)
			for y in range(24, 28):
				for x in range(12, 22):
					var cur: String = can.get_c(OFF_X + x, OFF_Y + y)
					if cur in [".", "o", "v", "t", "z", "k"] and not (cur == "." and (x < 13 or x > 20)):
						can.set_c(OFF_X + x, OFF_Y + y, "k" if (x == 12 or x == 21) else ("m" if y >= 26 else "j"))
			for y in [17, 18, 19, 20]:
				for x in range(10, 24):
					if can.get_c(OFF_X + x, OFF_Y + y) in ["j", "m", "T", "g", "Z"]:
						can.set_c(OFF_X + x, OFF_Y + y, "Z" if (y < 20 or x in [13, 14, 19, 20]) else "j")
			if dir == "down":
				for fx in [13, 19]:
					can.set_c(OFF_X + fx, OFF_Y + 21, "Z")
					can.set_c(OFF_X + fx, OFF_Y + 22, "R" if is_dist else "T")
				if is_dist:
					can.set_c(OFF_X + 12, OFF_Y + 23, "R")
					can.set_c(OFF_X + 20, OFF_Y + 23, "R")
			elif dir == "up":
				# Soft draped V-shawl silhouette down upper back (less boxy than a straight bar)
				for fx in [13, 14, 19, 20]:
					can.set_c(OFF_X + fx, OFF_Y + 20, "Z")
				for fx in [15, 16, 17, 18]:
					can.set_c(OFF_X + fx, OFF_Y + 21, "Z")
				for fx in [16, 17]:
					can.set_c(OFF_X + fx, OFF_Y + 22, "R" if is_dist else "T")

		"rosa_herbalist":
			_replace_in(can, "g", "j", 12, 21, 17, 23)
			for y in range(23, 28):
				for x in range(12, 22):
					var cur: String = can.get_c(OFF_X + x, OFF_Y + y)
					if cur in [".", "o", "v", "t", "k", "Z"] and (x >= 13 and x <= 20):
						can.set_c(OFF_X + x, OFF_Y + y, "k" if (x == 13 or x == 20) else ("R" if (y == 26 or (y == 24 and x % 3 == 0)) else "Z"))
			var bx := 22 if dir == "down" else (9 if dir == "up" else (11 if dir == "left" else 19))
			var by := 21
			for dy in range(0, 3):
				for dx in range(-1, 2):
					can.set_c(OFF_X + bx + dx, OFF_Y + by + dy, "k" if dy == 2 else "Y")
			can.set_c(OFF_X + bx - 1, OFF_Y + by - 1, "A" if is_dist else "L")
			can.set_c(OFF_X + bx, OFF_Y + by - 1, "R" if is_dist else "L")
			can.set_c(OFF_X + bx + 1, OFF_Y + by - 1, "I")

		"vulto_charred_coat":
			_replace_in(can, "g", "j", 12, 21, 17, 23)
			_replace_in(can, "Z", "m", 12, 21, 17, 23)
			if dir == "down":
				for ey in [18, 19, 20, 21, 22]:
					can.set_c(OFF_X + 16, OFF_Y + ey, "G" if (ey == 19 or ey == 20) else "A")
					can.set_c(OFF_X + 17, OFF_Y + ey, "A" if ey != 20 else "G")
					can.set_c(OFF_X + 15, OFF_Y + ey, "R" if (ey % 2 == 1) else "k")
			elif dir in ["left", "right"]:
				var cx := 12 if dir == "left" else 19
				can.set_c(OFF_X + cx, OFF_Y + 19, "G")
				can.set_c(OFF_X + cx, OFF_Y + 20, "A")
				can.set_c(OFF_X + cx, OFF_Y + 21, "R")
			for tx in [11, 14, 17, 20]:
				if can.get_c(OFF_X + tx, OFF_Y + 24) != ".":
					can.set_c(OFF_X + tx, OFF_Y + 24, "j")
					can.set_c(OFF_X + tx, OFF_Y + 25, "k" if (tx % 2 == 1) else "R")

	if str(spec.get("build", "standard")) == "broad" and dir in ["down", "up"]:
		for sy in [17, 18]:
			if can.get_c(OFF_X + 10, OFF_Y + sy) == "k":
				can.set_c(OFF_X + 9, OFF_Y + sy, "k")
				can.set_c(OFF_X + 10, OFF_Y + sy, "T" if sy == 17 else "j")
			if can.get_c(OFF_X + 23, OFF_Y + sy) == "k":
				can.set_c(OFF_X + 24, OFF_Y + sy, "k")
				can.set_c(OFF_X + 23, OFF_Y + sy, "T" if sy == 17 else "j")


static func apply_persistent_gear(can: Object, spec: Dictionary, _is_dist: bool, dir: String, _pose: String) -> void:
	if str(spec["id"]) == "vulto_bosque":
		can.set_vfx(OFF_X + 11, OFF_Y + 20, c("#FF6A2E"))
		can.set_vfx(OFF_X + 22, OFF_Y + 17, c("#E0362C"))
		if dir == "down":
			can.set_vfx(OFF_X + 16, OFF_Y + 19, c("#FFB84D"))


# ---------------------------------------------------------------------------
# Lote 2 Talk Animations (4f): Speech Nod + Iconic Handheld Prop
# ---------------------------------------------------------------------------
static func render_talk(b: GDScript, spec: Dictionary, mode_cfg: Dictionary, is_dist: bool, dir: String, f_idx: int) -> Object:
	var can: Object = b._compose_pose(spec, mode_cfg, is_dist, dir, "idle")
	var kind: String = str(mode_cfg.get("talk_prop", {}).get("kind", "none"))
	var is_child := str(spec.get("build", "standard")) == "child"

	if f_idx == 1 or f_idx == 2:
		if dir == "down":
			var my := 16 if is_child else 15
			can.set_c(OFF_X + 16, OFF_Y + my, "S")
			can.set_c(OFF_X + 17, OFF_Y + my, "S")
		if f_idx == 2:
			can = can.shift_upper(0, 1, OFF_Y + (19 if is_child else 18))

	var raise := 0
	if f_idx == 1 or f_idx == 3:
		raise = 1
	elif f_idx == 2:
		raise = 2
	if raise == 0:
		return can

	var hx := 22 if dir == "down" else (10 if dir == "left" else (21 if dir == "right" else 22))
	var hy := (21 if is_child else 20) - raise
	if dir == "up":
		hy = 19 - raise

	can.set_c(OFF_X + hx, OFF_Y + hy + 1, "p")
	can.set_c(OFF_X + hx, OFF_Y + hy + 2, "k")

	match kind:
		"broom_fan":
			for dy in range(-2, 1):
				for dx in range(-1, 2):
					can.set_c(OFF_X + hx + dx, OFF_Y + hy + dy, "L" if (dx == 0 and dy == -1) else "D")
			can.set_c(OFF_X + hx, OFF_Y + hy + 1, "I")
		"wrench_rag":
			can.set_c(OFF_X + hx, OFF_Y + hy, "D")
			can.set_c(OFF_X + hx, OFF_Y + hy - 1, "D")
			can.set_c(OFF_X + hx - 1, OFF_Y + hy - 2, "N")
			can.set_c(OFF_X + hx + 1, OFF_Y + hy - 2, "N")
		"salakot_wave":
			can.set_c(OFF_X + hx, OFF_Y + hy - 1, "D")
			can.set_c(OFF_X + hx + 1, OFF_Y + hy - 1, "L")
			can.set_c(OFF_X + hx, OFF_Y + hy - 2, "N")
			can.set_c(OFF_X + hx + 1, OFF_Y + hy - 2, "D")
		"kerosene_lantern", "elder_lantern":
			can.set_c(OFF_X + hx, OFF_Y + hy - 2, "D")
			can.set_c(OFF_X + hx - 1, OFF_Y + hy - 1, "k")
			can.set_c(OFF_X + hx, OFF_Y + hy - 1, "L")
			can.set_c(OFF_X + hx + 1, OFF_Y + hy - 1, "k")
			can.set_c(OFF_X + hx, OFF_Y + hy, "D")
			can.set_vfx(OFF_X + hx, OFF_Y + hy - 1, c("#FFE07D") if not is_dist else c("#FF4238"))
		"kid_point_wave":
			can.set_c(OFF_X + hx, OFF_Y + hy, "p")
			if is_dist:
				can.set_c(OFF_X + hx - 1, OFF_Y + hy - 1, "p")
				can.set_c(OFF_X + hx + 1, OFF_Y + hy - 1, "p")
			else:
				can.set_c(OFF_X + hx, OFF_Y + hy - 1, "p")
				can.set_c(OFF_X + hx + (1 if f_idx == 2 else -1), OFF_Y + hy - 2, "p")
		"herb_sprig":
			can.set_c(OFF_X + hx, OFF_Y + hy, "I")
			can.set_c(OFF_X + hx, OFF_Y + hy - 1, "L")
			can.set_c(OFF_X + hx - 1, OFF_Y + hy - 2, "L")
			can.set_c(OFF_X + hx + 1, OFF_Y + hy - 2, "N")
		"ember_flare":
			can.set_c(OFF_X + hx, OFF_Y + hy - 1, "D")
			can.set_vfx(OFF_X + hx, OFF_Y + hy - 2, c("#FF6A2E"))
			can.set_vfx(OFF_X + 16, OFF_Y + 19, c("#FFD066"))

	return can


# ---------------------------------------------------------------------------
# Lote 2 Attacks: 7 Unique Weapon Silhouettes & Trajectories (No Toby Combat)
# ---------------------------------------------------------------------------
static func render_attack(b: GDScript, spec: Dictionary, mode_cfg: Dictionary, is_dist: bool, dir: String, f_idx: int) -> Object:
	var style: String = str(spec["attack_style"])
	match style:
		"broom_sweep": return _atk_broom_sweep(b, spec, mode_cfg, is_dist, dir, f_idx)
		"wrench_smash": return _atk_wrench_smash(b, spec, mode_cfg, is_dist, dir, f_idx)
		"cleaver_slash": return _atk_cleaver_slash(b, spec, mode_cfg, is_dist, dir, f_idx)
		"oar_sweep": return _atk_oar_sweep(b, spec, mode_cfg, is_dist, dir, f_idx)
		"spectral_lantern": return _atk_spectral_lantern(b, spec, mode_cfg, is_dist, dir, f_idx)
		"ash_herb_gust": return _atk_ash_herb_gust(b, spec, mode_cfg, is_dist, dir, f_idx)
		"charred_axe_cleave": return _atk_charred_axe_cleave(b, spec, mode_cfg, is_dist, dir, f_idx)
	return b._compose_pose(spec, mode_cfg, is_dist, dir, "idle")


static func _atk_broom_sweep(b: GDScript, spec: Dictionary, mode_cfg: Dictionary, is_dist: bool, dir: String, f_idx: int) -> Object:
	var can: Object = b._compose_pose(spec, mode_cfg, is_dist, dir, "step_a" if f_idx in [1, 2] else "idle")
	var v_hi := c("#FF6B6B") if is_dist else c("#FAF0CA")
	var v_lo := c("#991E2A") if is_dist else c("#D9B26F")
	match f_idx:
		0:
			can = can.shift_upper(0, 1, OFF_Y + 26)
			b._draw_seg(can, 29, 25, 34, 17, "I", "k")
			for dx in range(-1, 2):
				can.set_c(34 + dx, 16, "W")
		1, 2:
			var push := 1 if f_idx == 1 else 2
			if dir == "down":
				can = can.shift_all(0, push)
				b._draw_seg(can, 28, 30, 17, 37, "I", "k")
				for br in range(-2, 2):
					can.set_c(16 + br, 38, "W")
					can.set_c(15 + br, 39, "P")
				b._draw_vfx_seg(can, 11, 36, 29, 36, v_hi, v_lo)
				b._draw_vfx_seg(can, 13, 38, 25, 39, v_hi, v_lo)
			elif dir == "up":
				can = can.shift_all(0, -push)
				can.set_c(28, 22, "p"); can.set_c(29, 21, "p")
				b._draw_seg(can, 28, 21, 17, 11, "I", "k")
				for br in range(-2, 2):
					can.set_c(16 + br, 10, "W")
					can.set_c(15 + br, 9, "P")
				b._draw_vfx_seg(can, 12, 12, 30, 12, v_hi, v_lo)
			else:
				var sgn := -1 if dir == "left" else 1
				can = can.shift_all(sgn * push, 0)
				var cx := 24
				b._draw_seg(can, cx + sgn * 2, 28, cx + sgn * 12, 34, "I", "k")
				can.set_c(cx + sgn * 13, 34, "W"); can.set_c(cx + sgn * 14, 35, "P")
				can.set_c(cx + sgn * 13, 35, "W"); can.set_c(cx + sgn * 14, 34, "P")
				b._draw_vfx_seg(can, cx + sgn * 10, 26, cx + sgn * 14, 37, v_hi, v_lo)
		3:
			b._draw_seg(can, 18, 29, 12, 33, "I", "k")
			can.set_c(11, 34, "W")
	return can


static func _atk_wrench_smash(b: GDScript, spec: Dictionary, mode_cfg: Dictionary, is_dist: bool, dir: String, f_idx: int) -> Object:
	var can: Object = b._compose_pose(spec, mode_cfg, is_dist, dir, "step_b" if f_idx in [1, 2] else "idle")
	var v_hi := c("#FF5C4D") if is_dist else c("#E0F2FE")
	var v_lo := c("#A61C24") if is_dist else c("#60A5FA")
	match f_idx:
		0:
			can = can.shift_upper(0, -1, OFF_Y + 26)
			b._draw_seg(can, 30, 25, 31, 12, "W", "k")
			can.set_c(30, 11, "P"); can.set_c(32, 11, "P")
		1, 2:
			if dir == "down":
				can = can.shift_all(0, 2)
				b._draw_seg(can, 30, 26, 30, 41, "W", "k")
				can.set_c(29, 42, "P"); can.set_c(31, 42, "P"); can.set_c(30, 40, "P")
				b._draw_vfx_seg(can, 29, 26, 29, 43, v_hi, v_lo)
				can.set_vfx(27, 43, v_hi); can.set_vfx(33, 43, v_hi)
				can.set_vfx(30, 45, v_lo)
			elif dir == "up":
				can = can.shift_all(0, -2)
				b._draw_seg(can, 30, 23, 30, 7, "W", "k")
				can.set_c(29, 6, "P"); can.set_c(31, 6, "P")
				b._draw_vfx_seg(can, 29, 6, 29, 20, v_hi, v_lo)
			else:
				var sgn := -1 if dir == "left" else 1
				can = can.shift_all(sgn * 2, 0)
				b._draw_seg(can, 24 + sgn * 3, 27, 24 + sgn * 15, 31, "W", "k")
				can.set_c(24 + sgn * 16, 30, "P"); can.set_c(24 + sgn * 16, 32, "P")
				b._draw_vfx_seg(can, 24 + sgn * 8, 22, 24 + sgn * 16, 35, v_hi, v_lo)
		3:
			b._draw_seg(can, 30, 29, 32, 37, "W", "k")
	return can


static func _atk_cleaver_slash(b: GDScript, spec: Dictionary, mode_cfg: Dictionary, is_dist: bool, dir: String, f_idx: int) -> Object:
	var can: Object = b._compose_pose(spec, mode_cfg, is_dist, dir, "step_a" if f_idx == 2 else "idle")
	var v_hi := c("#FF4D5A") if is_dist else c("#FFFFFF")
	var v_lo := c("#991B22") if is_dist else c("#56CCF2")
	match f_idx:
		0:
			can = can.shift_upper(1, 0, OFF_Y + 25)
			can.set_c(31, 25, "p")
			b._draw_seg(can, 31, 24, 34, 18, "I", "k")
			for bx in [34, 35, 36]:
				can.set_c(bx, 16, "P"); can.set_c(bx, 17, "W"); can.set_c(bx, 18, "k")
		1, 2:
			if dir == "down":
				can = can.shift_all(0, 1)
				can.set_c(30, 31, "p")
				b._draw_seg(can, 30, 32, 17, 39, "I", "k")
				# Heavy dark-outlined rectangular cleaver pushed down & forward past white apron
				for t_off in range(-4, 1):
					can.set_c(21 + t_off, 38, "W")
					can.set_c(21 + t_off, 39, "P")
					can.set_c(21 + t_off, 40, "k")
				b._draw_vfx_seg(can, 12, 37, 32, 36, v_hi, v_lo)
				b._draw_vfx_seg(can, 15, 41, 29, 40, v_hi, v_lo)
			elif dir == "up":
				can = can.shift_all(0, -1)
				can.set_c(29, 21, "p")
				b._draw_seg(can, 29, 21, 17, 11, "I", "k")
				can.set_c(16, 10, "W"); can.set_c(17, 10, "W"); can.set_c(16, 9, "P"); can.set_c(17, 9, "P")
				b._draw_vfx_seg(can, 13, 12, 30, 13, v_hi, v_lo)
			else:
				var sgn := -1 if dir == "left" else 1
				can = can.shift_all(sgn * 2, 0)
				b._draw_seg(can, 24 + sgn * 2, 26, 24 + sgn * 14, 30, "I", "k")
				can.set_c(24 + sgn * 14, 28, "P"); can.set_c(24 + sgn * 15, 29, "W"); can.set_c(24 + sgn * 14, 29, "W")
				b._draw_vfx_seg(can, 24 + sgn * 10, 23, 24 + sgn * 16, 35, v_hi, v_lo)
		3:
			b._draw_seg(can, 19, 30, 14, 35, "I", "k")
			can.set_c(13, 35, "W"); can.set_c(13, 36, "P")
	return can


static func _atk_oar_sweep(b: GDScript, spec: Dictionary, mode_cfg: Dictionary, is_dist: bool, dir: String, f_idx: int) -> Object:
	var can: Object = b._compose_pose(spec, mode_cfg, is_dist, dir, "step_a" if f_idx in [1, 2] else "idle")
	var v_hi := c("#FF6058") if is_dist else c("#A5F3FC")
	var v_lo := c("#8C1D28") if is_dist else c("#0E7490")
	match f_idx:
		0:
			can = can.shift_upper(1, 0, OFF_Y + 26)
			b._draw_seg(can, 29, 28, 37, 13, "I", "k")
			can.set_c(38, 12, "W"); can.set_c(37, 11, "P")
		1, 2:
			if dir == "down":
				can = can.shift_all(0, 1)
				b._draw_seg(can, 30, 31, 11, 38, "I", "k")
				for px in range(10, 14):
					can.set_c(px, 38, "W"); can.set_c(px, 39, "P")
				b._draw_vfx_seg(can, 10, 35, 35, 35, v_hi, v_lo)
				b._draw_vfx_seg(can, 12, 37, 32, 39, v_hi, v_lo)
			elif dir == "up":
				can = can.shift_all(0, -1)
				can.set_c(28, 22, "p"); can.set_c(29, 21, "p")
				b._draw_seg(can, 28, 21, 12, 10, "I", "k")
				for px in range(9, 14):
					can.set_c(px, 9, "W"); can.set_c(px, 10, "P")
				b._draw_vfx_seg(can, 8, 12, 34, 12, v_hi, v_lo)
			else:
				var sgn := -1 if dir == "left" else 1
				can = can.shift_all(sgn * 2, 0)
				b._draw_seg(can, 24 + sgn * 1, 29, 24 + sgn * 18, 29, "I", "k")
				can.set_c(24 + sgn * 18, 28, "W"); can.set_c(24 + sgn * 19, 29, "P")
				can.set_c(24 + sgn * 18, 30, "W")
				b._draw_vfx_seg(can, 24 + sgn * 14, 21, 24 + sgn * 18, 36, v_hi, v_lo)
		3:
			b._draw_seg(can, 22, 30, 13, 35, "I", "k")
	return can


static func _atk_spectral_lantern(b: GDScript, spec: Dictionary, mode_cfg: Dictionary, is_dist: bool, dir: String, f_idx: int) -> Object:
	var can: Object = b._compose_pose(spec, mode_cfg, is_dist, dir, "idle")
	var v_hi := c("#FF6680") if is_dist else c("#F3E8FF")
	var v_lo := c("#B81D3A") if is_dist else c("#9333EA")
	match f_idx:
		0:
			can = can.shift_upper(0, -1, OFF_Y + 25)
			can.set_c(OFF_X + 23, OFF_Y + 20, "p")
			can.set_c(OFF_X + 23, OFF_Y + 19, "k"); can.set_c(OFF_X + 24, OFF_Y + 19, "D")
			can.set_c(OFF_X + 24, OFF_Y + 20, "A" if is_dist else "G")
			can.set_vfx(OFF_X + 24, OFF_Y + 18, v_hi)
		1, 2:
			if dir == "down":
				can = can.shift_all(0, 1)
				can.set_c(OFF_X + 21, OFF_Y + 24, "p")
				can.set_c(OFF_X + 22, OFF_Y + 24, "k"); can.set_c(OFF_X + 23, OFF_Y + 24, "D")
				can.set_c(OFF_X + 22, OFF_Y + 25, "A" if is_dist else "G"); can.set_c(OFF_X + 23, OFF_Y + 25, "D")
				can.set_c(OFF_X + 22, OFF_Y + 26, "k"); can.set_c(OFF_X + 23, OFF_Y + 26, "k")
				b._draw_vfx_seg(can, OFF_X + 12, OFF_Y + 27, OFF_X + 27, OFF_Y + 29, v_hi, v_lo)
				b._draw_vfx_seg(can, OFF_X + 15, OFF_Y + 30, OFF_X + 25, OFF_Y + 32, v_hi, v_lo)
				for sx in [14, 19, 24]:
					can.set_vfx(OFF_X + sx, OFF_Y + 33, v_lo)
				can.set_vfx(OFF_X + 22, OFF_Y + 25, v_hi)
			elif dir == "up":
				can = can.shift_all(0, -1)
				can.set_c(OFF_X + 22, OFF_Y + 14, "D")
				can.set_c(OFF_X + 22, OFF_Y + 13, "A" if is_dist else "G")
				b._draw_vfx_seg(can, OFF_X + 12, OFF_Y + 9, OFF_X + 26, OFF_Y + 10, v_hi, v_lo)
				b._draw_vfx_seg(can, OFF_X + 15, OFF_Y + 6, OFF_X + 24, OFF_Y + 7, v_lo, v_hi)
			else:
				var sgn := -1 if dir == "left" else 1
				can = can.shift_all(sgn * 1, 0)
				var lx := OFF_X + 16 + sgn * 10
				can.set_c(lx - sgn, OFF_Y + 20, "p")
				can.set_c(lx, OFF_Y + 19, "D"); can.set_c(lx, OFF_Y + 20, "A" if is_dist else "G"); can.set_c(lx, OFF_Y + 21, "k")
				b._draw_vfx_seg(can, lx + sgn * 2, OFF_Y + 17, lx + sgn * 7, OFF_Y + 19, v_hi, v_lo)
				b._draw_vfx_seg(can, lx + sgn * 1, OFF_Y + 20, lx + sgn * 9, OFF_Y + 20, v_hi, v_lo)
				b._draw_vfx_seg(can, lx + sgn * 2, OFF_Y + 23, lx + sgn * 7, OFF_Y + 21, v_hi, v_lo)
		3:
			can.set_c(OFF_X + 22, OFF_Y + 21, "D")
			can.set_c(OFF_X + 22, OFF_Y + 22, "A" if is_dist else "G")
			can.set_vfx(OFF_X + 22, OFF_Y + 26, v_lo)
			can.set_vfx(OFF_X + 20, OFF_Y + 25, v_hi)
	return can


static func _atk_ash_herb_gust(b: GDScript, spec: Dictionary, mode_cfg: Dictionary, is_dist: bool, dir: String, f_idx: int) -> Object:
	var can: Object = b._compose_pose(spec, mode_cfg, is_dist, dir, "step_a" if f_idx == 2 else "idle")
	var v_hi := c("#FF7838") if is_dist else c("#9EE848")
	var v_lo := c("#C41E2B") if is_dist else c("#FAF089")
	match f_idx:
		0:
			can = can.shift_upper(-1, 0, OFF_Y + 25)
			can.set_c(OFF_X + 22, OFF_Y + 19, "p"); can.set_c(OFF_X + 23, OFF_Y + 18, "L")
			can.set_vfx(OFF_X + 24, OFF_Y + 17, v_lo)
		1, 2:
			var dv: Vector2i = b._dir_vec(dir)
			can = can.shift_all(dv.x, dv.y)
			if dir == "down":
				can.set_c(OFF_X + 21, OFF_Y + 23, "p"); can.set_c(OFF_X + 22, OFF_Y + 24, "L")
				b._draw_vfx_seg(can, 15, 34, 31, 32, v_hi, v_lo)
				b._draw_vfx_seg(can, 13, 37, 29, 36, v_lo, v_hi)
				b._draw_vfx_seg(can, 17, 40, 26, 39, v_hi, v_lo)
				for lp in [Vector2i(14, 33), Vector2i(20, 41), Vector2i(32, 34), Vector2i(28, 38)]:
					can.set_vfx(lp.x, lp.y, v_hi)
			elif dir == "up":
				b._draw_vfx_seg(can, 14, 12, 30, 10, v_hi, v_lo)
				b._draw_vfx_seg(can, 16, 8, 28, 7, v_lo, v_hi)
				for lp in [Vector2i(15, 6), Vector2i(22, 5), Vector2i(29, 9)]:
					can.set_vfx(lp.x, lp.y, v_hi)
			else:
				var sgn := -1 if dir == "left" else 1
				var cx := 24
				can.set_c(cx + sgn * 7, 29, "p"); can.set_c(cx + sgn * 8, 28, "L")
				b._draw_vfx_seg(can, cx + sgn * 8, 27, cx + sgn * 16, 23, v_hi, v_lo)
				b._draw_vfx_seg(can, cx + sgn * 9, 30, cx + sgn * 18, 28, v_lo, v_hi)
				b._draw_vfx_seg(can, cx + sgn * 8, 33, cx + sgn * 16, 34, v_hi, v_lo)
				can.set_vfx(cx + sgn * 17, 25, v_hi); can.set_vfx(cx + sgn * 15, 36, v_lo)
		3:
			can.set_vfx(OFF_X + 18, OFF_Y + 26, v_lo)
			can.set_vfx(OFF_X + 21, OFF_Y + 27, v_hi)
	return can


static func _atk_charred_axe_cleave(b: GDScript, spec: Dictionary, mode_cfg: Dictionary, is_dist: bool, dir: String, f_idx: int) -> Object:
	var can: Object = b._compose_pose(spec, mode_cfg, is_dist, dir, "step_a" if f_idx in [1, 2] else "idle")
	var v_hi := c("#FFAD33")
	var v_lo := c("#D92626")
	match f_idx:
		0:
			can = can.shift_upper(0, -1, OFF_Y + 26)
			b._draw_seg(can, 31, 25, 34, 12, "I", "k")
			for ax in [35, 36]:
				for ay in [11, 12, 13, 14]:
					can.set_c(ax, ay, "A" if ax == 36 else "W")
			can.set_vfx(36, 10, v_hi)
		1, 2:
			if dir == "down":
				can = can.shift_all(0, 2)
				b._draw_seg(can, 31, 27, 22, 42, "I", "k")
				for ax in range(18, 24):
					for ay in [41, 42, 43]:
						can.set_c(ax, ay, "A" if ay == 43 else "W")
				b._draw_vfx_seg(can, 13, 39, 32, 34, v_hi, v_lo)
				b._draw_vfx_seg(can, 16, 42, 30, 39, v_hi, v_lo)
				b._draw_vfx_seg(can, 19, 44, 28, 43, v_lo, v_lo)
			elif dir == "up":
				can = can.shift_all(0, -2)
				b._draw_seg(can, 31, 21, 21, 5, "I", "k")
				for ax in range(18, 23):
					can.set_c(ax, 5, "W"); can.set_c(ax, 4, "A")
				b._draw_vfx_seg(can, 14, 7, 32, 12, v_hi, v_lo)
				b._draw_vfx_seg(can, 16, 5, 29, 9, v_lo, v_lo)
			else:
				var sgn := -1 if dir == "left" else 1
				can = can.shift_all(sgn * 2, 0)
				var cx := 24
				b._draw_seg(can, cx + sgn * 2, 27, cx + sgn * 15, 35, "I", "k")
				can.set_c(cx + sgn * 16, 34, "W"); can.set_c(cx + sgn * 16, 36, "A")
				can.set_c(cx + sgn * 17, 35, "A"); can.set_c(cx + sgn * 15, 37, "W")
				b._draw_vfx_seg(can, cx + sgn * 11, 20, cx + sgn * 17, 37, v_hi, v_lo)
				b._draw_vfx_seg(can, cx + sgn * 14, 23, cx + sgn * 18, 35, v_lo, v_lo)
		3:
			b._draw_seg(can, 18, 29, 13, 37, "I", "k")
			can.set_c(12, 37, "W"); can.set_c(12, 38, "A")
	return can


# ---------------------------------------------------------------------------
# Lote 2 Death Poses (y=39 anchored, 7 distinct silhouettes + ash dissolve!)
# ---------------------------------------------------------------------------
static func render_death(b: GDScript, spec: Dictionary, _mode_cfg: Dictionary, is_dist: bool, pal: Dictionary, dir: String, f_idx: int) -> Image:
	var head_id: String = str(spec["head_id"])
	var gy := FOOT_CELL_Y

	if head_id == "vulto" and f_idx >= 4:
		var can: Object = b.new_canvas()
		if f_idx == 4:
			b._stamp_32(can, T1.BASE_FALLEN, false)
			for x in range(13, 21):
				can.set_c(x, gy - 4, "c")
				can.set_c(x, gy - 3, "B" if x % 3 == 0 else "H")
				can.set_c(x, gy - 2, "Q")
			# Glowing ember torso core + cracked fallen BFP helmet on right
			for x in range(28, 34):
				can.set_c(x, gy - 2, "B" if x in [29, 32] else "H")
				can.set_c(x, gy - 1, "c")
			can.set_c(30, gy - 2, "G"); can.set_c(31, gy - 1, "A")
			can.set_vfx(16, gy - 4, c("#FF9E44"))
			can.set_vfx(18, gy - 5, c("#FF4D36"))
			can.set_vfx(22, gy - 6, c("#FFD066"))
			can.set_vfx(26, gy - 3, c("#FF6A2E"))
			can.set_vfx(31, gy - 3, c("#FFD066"))
		else:
			# Dispersed ash heap + luminous cooling embers + shattered helmet piece at y=39
			for ax in range(14, 33):
				can.set_c(ax, gy, "c" if (ax == 14 or ax == 32) else ("B" if ax % 4 == 0 else "H"))
				if ax in range(17, 28):
					can.set_c(ax, gy - 1, "B" if ax % 3 == 0 else "Q")
			for cx in [19, 22, 25]:
				can.set_vfx(cx, gy - 1, c("#FF6A2E") if is_dist else c("#E06636"))
			can.set_c(29, gy - 1, "H"); can.set_c(30, gy - 1, "G"); can.set_c(31, gy - 1, "c")
			can.set_vfx(18, gy - 3, c("#FF4D36"))
			can.set_vfx(21, gy - 4, c("#FFD066"))
			can.set_vfx(25, gy - 5, c("#FF8C3B"))
			can.set_vfx(28, gy - 3, c("#C92A2A"))
		return can.bake(pal, false)

	var body_grid: Array[String] = T1.BASE_FALLEN
	if not (dir in ["right", "down"]):
		body_grid = T1.mirror_grid_h(T1.BASE_FALLEN)
	var can: Object = b.new_canvas()
	b._stamp_32(can, body_grid, false)

	var head_left := not (dir in ["right", "down"])
	var hx := 14 if head_left else 27
	var dx_out := -1 if head_left else 1

	match head_id:
		"nena":
			var cx := hx + (1 if head_left else 6)
			for step in range(4):
				for y in range(gy - 6, gy):
					can.set_c(cx + step * dx_out, y, "c" if (step == 3 or y == gy - 6) else "h")
			can.set_c(cx + dx_out * 2, gy - 5, "a")
			can.set_c(cx + dx_out * 3, gy - 4, "a")
			b._draw_seg(can, 17, gy - 1, 28, gy - 1, "I", "k")
			for bx in [29, 30, 31]:
				can.set_c(bx, gy - 1, "W" if bx < 31 else "P")
				can.set_c(bx, gy - 2, "P" if bx == 30 else "W")
				can.set_c(bx, gy, "k")
		"ben":
			for x in range(18, 27):
				can.set_c(x, gy - 5, "N")
			var wx := 28 if head_left else 14
			b._draw_seg(can, wx, gy - 1, wx + dx_out * 6, gy - 1, "W", "k")
			can.set_c(wx + dx_out * 6, gy - 2, "P")
		"tomas":
			var cx := hx + (1 if head_left else 5)
			for dx in range(-4, 5):
				can.set_c(cx + dx, gy - 2, "H")
				can.set_c(cx + dx, gy - 1, "c" if (dx == -4 or dx == 4) else "Q")
			for dx in range(-2, 3):
				can.set_c(cx + dx, gy - 3, "B")
			can.set_c(cx, gy - 4, "H")
			can.set_c(26, gy - 1, "W"); can.set_c(27, gy - 1, "P"); can.set_c(25, gy - 1, "I")
		"carding":
			var cx := hx + (1 if head_left else 6)
			for step in range(4):
				for y in range(gy - 6, gy):
					can.set_c(cx + step * dx_out, y, "H" if y in [gy - 4, gy - 3] else ("c" if y == gy - 6 else "h"))
			b._draw_seg(can, 14, gy - 1, 31, gy - 1, "I", "k")
			for ox in [32, 33, 34]:
				can.set_c(ox, gy - 2, "W")
				can.set_c(ox, gy - 1, "P")
				can.set_c(ox, gy, "k")
		"luningning":
			for x in range(16, 28):
				can.set_c(x, gy - 4, "Z")
				if x % 2 == 0:
					can.set_c(x, gy - 3, "T")
			var lx := hx + dx_out * 4
			can.set_c(lx, gy - 2, "k"); can.set_c(lx, gy - 1, "D"); can.set_c(lx + dx_out, gy - 1, "A" if is_dist else "G")
		"rosa":
			var cx := hx + (1 if head_left else 6)
			for step in range(3):
				for y in range(gy - 6, gy):
					can.set_c(cx + step * dx_out, y, "H" if y > gy - 6 else "c")
			can.set_c(cx + dx_out, gy - 4, "a")
			var bkx := cx + dx_out * 4
			can.set_c(bkx, gy - 1, "Y"); can.set_c(bkx + dx_out, gy - 1, "Y")
			can.set_c(bkx + dx_out * 2, gy - 1, "R" if is_dist else "L")
			can.set_c(bkx + dx_out, gy - 2, "R" if is_dist else "L")

	if is_dist:
		can.set_vfx(OFF_X + 15, gy - 4, c("#FF4238"))
		if f_idx == 5:
			can.set_vfx(OFF_X + 18, gy - 5, c("#C41E2B"))

	return can.bake(pal, false)


static func _replace_in(can: Object, from_ch: String, to_ch: String, x0: int, x1: int, y0: int, y1: int) -> void:
	for y in range(OFF_Y + y0, OFF_Y + y1 + 1):
		for x in range(OFF_X + x0, OFF_X + x1 + 1):
			if can.get_c(x, y) == from_ch:
				can.set_c(x, y, to_ch)
