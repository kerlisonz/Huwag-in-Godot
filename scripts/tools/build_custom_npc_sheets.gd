@tool
extends SceneTree

## Gerador autoral dos spritesheets personalizados 16-bit sombrios (480x192, grade 10x4 de 48x48)
## e do retrato CRT FNAF de Senhora Luningning (96x96).
## Substitui os sheets genéricos LimeZu mantendo proporções e paleta coesas com Huwag/BFP.

const OUT_SPRITES_DIR := "res://assets/characters/sprites"
const OUT_PORTRAITS_DIR := "res://assets/characters/portraits"
const CELL := 48
const COLS := 10
const ROWS := 4
const OUTLINE := Color("#0b0c12")

enum Row { DOWN = 0, LEFT = 1, RIGHT = 2, UP = 3 }


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_SPRITES_DIR))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_PORTRAITS_DIR))

	var specs := [
		_spec_aling_nena(),
		_spec_kuya_ben(),
		_spec_toby(),
		_spec_feirante(),
		_spec_luningning(),
		_spec_distorted_feirante(),
		_spec_distorted_toby(),
	]

	for s in specs:
		var sheet := _build_sheet(s)
		var out_path := "%s/%s.png" % [OUT_SPRITES_DIR, s["file"]]
		var err := sheet.save_png(ProjectSettings.globalize_path(out_path))
		print("[CustomNpcSheets] %s -> %s (err=%d)" % [s["file"], out_path, err])

	var portrait := _build_luningning_portrait()
	var port_path := "%s/fnaf_luningning.png" % OUT_PORTRAITS_DIR
	var p_err := portrait.save_png(ProjectSettings.globalize_path(port_path))
	print("[CustomNpcSheets] fnaf_luningning -> %s (err=%d)" % [port_path, p_err])

	quit(0)


# ==============================================================================
# DEFINIÇÕES DE PALETA E SILHUETA DE CADA PERSONAGEM
# ==============================================================================

func _spec_aling_nena() -> Dictionary:
	return {
		"file": "npc_aling_nena_sheet",
		"is_child": false,
		"is_distorted": false,
		"hunch": 0,
		"height_add": 0,
		"skin_light": Color("#b4886c"),
		"skin_mid": Color("#946950"),
		"skin_dark": Color("#664434"),
		"hair_light": Color("#54525e"),
		"hair_mid": Color("#2a2933"),
		"hair_dark": Color("#17161e"),
		"eye_col": Color("#111018"),
		"eye_glint": Color("#d8d4c8"),
		"shirt_light": Color("#7d3d4a"),
		"shirt_mid": Color("#5d2a35"),
		"shirt_dark": Color("#3d1a22"),
		"apron_light": Color("#4a5060"),
		"apron_mid": Color("#343946"),
		"apron_dark": Color("#21242e"),
		"pants_light": Color("#333642"),
		"pants_mid": Color("#232630"),
		"pants_dark": Color("#15171f"),
		"shoe_col": Color("#2c221e"),
		"hat_type": "bun",
		"garment_type": "apron_skirt",
		"prop_type": "broom",
		"prop_col1": Color("#785538"),
		"prop_col2": Color("#b59862"),
	}


func _spec_kuya_ben() -> Dictionary:
	return {
		"file": "npc_kuya_ben_sheet",
		"is_child": false,
		"is_distorted": false,
		"hunch": 0,
		"height_add": 1,
		"skin_light": Color("#9d7052"),
		"skin_mid": Color("#7e563c"),
		"skin_dark": Color("#563826"),
		"hair_light": Color("#2c2d34"),
		"hair_mid": Color("#1a1b22"),
		"hair_dark": Color("#0f1016"),
		"eye_col": Color("#101018"),
		"eye_glint": Color("#cfcabf"),
		"shirt_light": Color("#685f46"),
		"shirt_mid": Color("#4c4532"),
		"shirt_dark": Color("#322d20"),
		"apron_light": Color("#9a9ea8"), # toalha / alças de colete
		"apron_mid": Color("#6e727c"),
		"apron_dark": Color("#3c3e46"),
		"pants_light": Color("#353b4a"),
		"pants_mid": Color("#242934"),
		"pants_dark": Color("#161922"),
		"shoe_col": Color("#1c191a"),
		"hat_type": "cap",
		"hat_light": Color("#495262"),
		"hat_mid": Color("#313845"),
		"hat_dark": Color("#1e232c"),
		"garment_type": "mechanic_vest",
		"prop_type": "wrench",
		"prop_col1": Color("#8b96a6"),
		"prop_col2": Color("#c4cfde"),
	}


func _spec_toby() -> Dictionary:
	return {
		"file": "npc_toby_sheet",
		"is_child": true,
		"is_distorted": false,
		"hunch": 0,
		"height_add": 0,
		"skin_light": Color("#bd9275"),
		"skin_mid": Color("#9c7358"),
		"skin_dark": Color("#6d4d3a"),
		"hair_light": Color("#31313d"),
		"hair_mid": Color("#1f1f28"),
		"hair_dark": Color("#13131a"),
		"eye_col": Color("#12111a"),
		"eye_glint": Color("#e0ddd4"),
		"shirt_light": Color("#4c6a72"),
		"shirt_mid": Color("#334a52"),
		"shirt_dark": Color("#213036"),
		"apron_light": Color("#879296"), # listras da camisa
		"apron_mid": Color("#646f75"),
		"apron_dark": Color("#41494f"),
		"pants_light": Color("#3b3532"),
		"pants_mid": Color("#292422"),
		"pants_dark": Color("#1a1615"),
		"shoe_col": Color("#4b392e"),
		"hat_type": "messy_hair",
		"garment_type": "striped_shorts",
		"prop_type": "stone_throw",
		"prop_col1": Color("#7d818a"),
		"prop_col2": Color("#adb3bf"),
	}


func _spec_feirante() -> Dictionary:
	return {
		"file": "npc_feirante_sheet",
		"is_child": false,
		"is_distorted": false,
		"hunch": 0,
		"height_add": 0,
		"skin_light": Color("#ab7e5e"),
		"skin_mid": Color("#886045"),
		"skin_dark": Color("#5b3e2b"),
		"hair_light": Color("#2c282a"),
		"hair_mid": Color("#1b181b"),
		"hair_dark": Color("#100e10"),
		"eye_col": Color("#0e0d14"),
		"eye_glint": Color("#cfc8ba"),
		"shirt_light": Color("#7a6240"),
		"shirt_mid": Color("#5c482d"),
		"shirt_dark": Color("#3b2d1b"),
		"apron_light": Color("#444d3e"),
		"apron_mid": Color("#2f372b"),
		"apron_dark": Color("#1e241b"),
		"pants_light": Color("#2e3036"),
		"pants_mid": Color("#202227"),
		"pants_dark": Color("#131518"),
		"shoe_col": Color("#261f1b"),
		"hat_type": "salakot",
		"hat_light": Color("#94784f"),
		"hat_mid": Color("#705938"),
		"hat_dark": Color("#483720"),
		"garment_type": "market_apron",
		"prop_type": "knife",
		"prop_col1": Color("#929ca8"),
		"prop_col2": Color("#d5dfe8"),
	}


func _spec_luningning() -> Dictionary:
	return {
		"file": "npc_luningning_sheet",
		"is_child": false,
		"is_distorted": false,
		"hunch": 1,
		"height_add": -1,
		"skin_light": Color("#b29280"),
		"skin_mid": Color("#8f7162"),
		"skin_dark": Color("#624b41"),
		"hair_light": Color("#c2c6d1"),
		"hair_mid": Color("#8f94a1"),
		"hair_dark": Color("#5b606e"),
		"eye_col": Color("#13121a"),
		"eye_glint": Color("#cfd3dd"),
		"shirt_light": Color("#57436b"),
		"shirt_mid": Color("#3f2f50"),
		"shirt_dark": Color("#281d34"),
		"apron_light": Color("#68537c"), # xale nos ombros
		"apron_mid": Color("#49395a"),
		"apron_dark": Color("#2c2238"),
		"pants_light": Color("#2f3548"),
		"pants_mid": Color("#212534"),
		"pants_dark": Color("#151822"),
		"shoe_col": Color("#1d1a22"),
		"hat_type": "elder_bun",
		"garment_type": "shawl_skirt",
		"prop_type": "lantern",
		"prop_col1": Color("#d4963f"),
		"prop_col2": Color("#ffdc82"),
	}


func _spec_distorted_feirante() -> Dictionary:
	return {
		"file": "distorted_feirante_sheet",
		"is_child": false,
		"is_distorted": true,
		"hunch": 1,
		"height_add": 2,
		"skin_light": Color("#908b89"),
		"skin_mid": Color("#6a6665"),
		"skin_dark": Color("#3d3a3c"),
		"hair_light": Color("#1c1618"),
		"hair_mid": Color("#100c0e"),
		"hair_dark": Color("#080608"),
		"eye_col": Color("#080507"),
		"eye_glint": Color("#ff2a38"),
		"shirt_light": Color("#544c49"),
		"shirt_mid": Color("#3a3432"),
		"shirt_dark": Color("#221e1e"),
		"apron_light": Color("#7b232a"), # avental manchado de carmesim
		"apron_mid": Color("#52171d"),
		"apron_dark": Color("#2d0d11"),
		"pants_light": Color("#242226"),
		"pants_mid": Color("#171519"),
		"pants_dark": Color("#0e0c10"),
		"shoe_col": Color("#161113"),
		"hat_type": "salakot_cracked",
		"hat_light": Color("#59483b"),
		"hat_mid": Color("#3d3026"),
		"hat_dark": Color("#241c16"),
		"garment_type": "market_apron",
		"prop_type": "knife_blood",
		"prop_col1": Color("#7d8590"),
		"prop_col2": Color("#b91f2a"),
	}


func _spec_distorted_toby() -> Dictionary:
	return {
		"file": "distorted_toby_sheet",
		"is_child": true,
		"is_distorted": true,
		"hunch": 1,
		"height_add": 0,
		"skin_light": Color("#938c8f"),
		"skin_mid": Color("#6e676b"),
		"skin_dark": Color("#413c40"),
		"hair_light": Color("#1f1d24"),
		"hair_mid": Color("#121016"),
		"hair_dark": Color("#09080c"),
		"eye_col": Color("#070508"),
		"eye_glint": Color("#ff2836"),
		"shirt_light": Color("#493d42"),
		"shirt_mid": Color("#30262b"),
		"shirt_dark": Color("#1c1519"),
		"apron_light": Color("#85222c"), # listras carmesim
		"apron_mid": Color("#5a171e"),
		"apron_dark": Color("#340e12"),
		"pants_light": Color("#282326"),
		"pants_mid": Color("#1a1619"),
		"pants_dark": Color("#100d10"),
		"shoe_col": Color("#1b1315"),
		"hat_type": "messy_hair",
		"garment_type": "striped_shorts",
		"prop_type": "claw_lunge",
		"prop_col1": Color("#731f27"),
		"prop_col2": Color("#ff2e3a"),
	}


# ==============================================================================
# CONSTRUÇÃO DO SPRITESHEET 480x192
# ==============================================================================

func _build_sheet(spec: Dictionary) -> Image:
	var sheet := Image.create(CELL * COLS, CELL * ROWS, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0, 0, 0, 0))

	for row in range(ROWS):
		for col in range(COLS):
			var cell_img := _draw_character_cell(spec, row, col)
			sheet.blit_rect(cell_img, Rect2i(0, 0, CELL, CELL), Vector2i(col * CELL, row * CELL))
	return sheet


func _draw_character_cell(spec: Dictionary, row: int, col: int) -> Image:
	# Camada interna desenhada sem contorno e depois contornada com OUTLINE de 1px
	var canvas := Image.create(CELL, CELL, false, Image.FORMAT_RGBA8)
	canvas.fill(Color(0, 0, 0, 0))

	var is_child: bool = bool(spec.get("is_child", false))
	var is_distorted: bool = bool(spec.get("is_distorted", false))
	var hunch: int = int(spec.get("hunch", 0))
	var height_add: int = int(spec.get("height_add", 0))

	# Parâmetros de ciclo de animação
	var bob_y := 0
	var lunge_x := 0
	var lunge_y := 0
	var leg_l_dy := 0
	var leg_r_dy := 0
	var leg_l_dx := 0
	var leg_r_dx := 0
	var arm_l_dy := 0
	var arm_r_dy := 0
	var arm_l_dx := 0
	var arm_r_dx := 0
	var action_phase := -1 # 0..3 para cols 6..9

	if col == 1:
		bob_y = 1 # respiração sutil idle
	elif col >= 2 and col <= 5:
		var step := col - 2
		match step:
			0:
				bob_y = -1
				leg_l_dy = -1
				leg_l_dx = -1
				leg_r_dy = 1
				leg_r_dx = 1
				arm_l_dx = 1
				arm_r_dx = -1
				arm_r_dy = -1
			1:
				bob_y = 0
			2:
				bob_y = -1
				leg_l_dy = 1
				leg_l_dx = 1
				leg_r_dy = -1
				leg_r_dx = -1
				arm_l_dx = -1
				arm_l_dy = -1
				arm_r_dx = 1
			3:
				bob_y = 0
	elif col >= 6:
		action_phase = col - 6
		match action_phase:
			0: # recuo / preparação
				bob_y = 0
				lunge_x = -1 if row == Row.RIGHT else (1 if row == Row.LEFT else 0)
				lunge_y = -1 if row == Row.DOWN else (1 if row == Row.UP else 0)
				arm_r_dy = -3
			1: # impacto / bote
				bob_y = 1
				lunge_x = 2 if row == Row.RIGHT else (-2 if row == Row.LEFT else 0)
				lunge_y = 2 if row == Row.DOWN else (-2 if row == Row.UP else 0)
				arm_r_dy = 1
				arm_r_dx = 2 if row == Row.RIGHT else (-2 if row == Row.LEFT else 0)
			2: # extensão máxima
				bob_y = 1
				lunge_x = 3 if row == Row.RIGHT else (-3 if row == Row.LEFT else 0)
				lunge_y = 2 if row == Row.DOWN else (-2 if row == Row.UP else 0)
				arm_r_dy = 2
				arm_r_dx = 3 if row == Row.RIGHT else (-3 if row == Row.LEFT else 0)
			3: # retorno
				bob_y = 0
				lunge_x = 1 if row == Row.RIGHT else (-1 if row == Row.LEFT else 0)
				lunge_y = 1 if row == Row.DOWN else (-1 if row == Row.UP else 0)

	# Âncoras verticais com pés em y=39..40 (combinando com Shadow y=6 e Sprite y=-10)
	var foot_y := 39
	var leg_h := 5 if is_child else 7
	var torso_h := (6 if is_child else 9) + height_add
	var head_h := 8 if is_child else 10
	var head_w := 9 if is_child else 10

	var cx := 24 + lunge_x
	if is_distorted and col in [1, 3, 7, 8]:
		cx += (-1 if col % 2 == 1 else 1)

	var hip_y := foot_y - leg_h + bob_y
	var shoulder_y := hip_y - torso_h
	var head_y := shoulder_y - head_h + 1 + lunge_y
	var head_cx := cx + (hunch if row == Row.RIGHT else (-hunch if row == Row.LEFT else 0))

	# Helper local de desenho com sombreamento
	var side_dir := 0
	if row == Row.LEFT:
		side_dir = -1
	elif row == Row.RIGHT:
		side_dir = 1

	# 1. Pernas e pés (ou barra de saia + pés)
	_draw_legs(canvas, spec, row, cx, hip_y, foot_y, leg_l_dx, leg_l_dy, leg_r_dx, leg_r_dy, action_phase)

	# 2. Braço traseiro (nas vistas laterais ou ataque)
	if side_dir != 0:
		var back_arm_x := cx - side_dir * 2 + arm_l_dx
		_draw_arm(canvas, spec, back_arm_x, shoulder_y + 1 + arm_l_dy, is_child, -side_dir)

	# 3. Torso + roupa/avental/xale
	_draw_torso(canvas, spec, row, cx, shoulder_y, hip_y, torso_h, is_child)

	# 4. Cabeça + rosto + cabelo/chapéu
	_draw_head_and_hat(canvas, spec, row, head_cx, head_y, head_w, head_h, is_distorted)

	# 5. Braços frontais + ferramenta/arma conectada à mão
	var hand_anchor := Vector2i(cx + 4, hip_y - 1)
	if side_dir == 0:
		var left_ax := cx - (5 if not is_child else 4) + arm_l_dx
		var right_ax := cx + (4 if not is_child else 3) + arm_r_dx
		_draw_arm(canvas, spec, left_ax, shoulder_y + 1 + arm_l_dy, is_child, 0)
		if action_phase >= 0:
			var ext_y := shoulder_y + 1 + (0 if action_phase == 0 else (2 if row == Row.DOWN else -2))
			_frect(canvas, right_ax, shoulder_y + 1, 2, 4, spec["shirt_dark"])
			_frect(canvas, right_ax, ext_y + 2, 2, 3, spec["skin_mid"])
			hand_anchor = Vector2i(right_ax + 1, ext_y + 4)
		else:
			_draw_arm(canvas, spec, right_ax, shoulder_y + 1 + arm_r_dy, is_child, 0)
			hand_anchor = Vector2i(right_ax + 1, shoulder_y + 5 + arm_r_dy)
	else:
		var reach_x := 0
		var reach_y := 0
		if action_phase == 0:
			reach_y = -2
		elif action_phase == 1 or action_phase == 2:
			reach_x = side_dir * (3 if action_phase == 2 else 2)
			reach_y = 0
		var front_arm_x := cx + side_dir * 1 + arm_r_dx
		if action_phase in [1, 2]:
			# Antebraço estendido horizontalmente conectando ombro até a mão na ponta
			var bx := mini(cx, cx + reach_x + side_dir * 2)
			var bw := absi((cx + reach_x + side_dir * 2) - cx) + 2
			_frect(canvas, cx - (1 if side_dir < 0 else 0), shoulder_y + 2, 2, 2, spec["shirt_dark"])
			_frect(canvas, bx, shoulder_y + 3, bw, 2, spec["skin_mid"])
			hand_anchor = Vector2i(cx + reach_x + side_dir * 3, shoulder_y + 3)
		else:
			_draw_arm(canvas, spec, front_arm_x, shoulder_y + 2 + arm_r_dy + reach_y, is_child, side_dir)
			hand_anchor = Vector2i(front_arm_x + (0 if side_dir < 0 else 1), shoulder_y + (5 if is_child else 6) + arm_r_dy + reach_y)

	if action_phase >= 0 or spec["prop_type"] in ["wrench", "lantern", "knife", "knife_blood"]:
		_draw_prop(canvas, spec, row, hand_anchor, shoulder_y, action_phase)

	# 6. Contorno externo crisp de 1px + destaque sombrio
	return _apply_pixel_outline(canvas)


func _draw_legs(img: Image, spec: Dictionary, row: int, cx: int, hip_y: int, foot_y: int, ldx: int, ldy: int, rdx: int, rdy: int, action_phase: int) -> void:
	var p_light: Color = spec["pants_light"]
	var p_mid: Color = spec["pants_mid"]
	var p_dark: Color = spec["pants_dark"]
	var shoe: Color = spec["shoe_col"]
	var is_child: bool = bool(spec.get("is_child", false))
	var gtype: String = str(spec.get("garment_type", ""))

	var stance_spread := 1 if action_phase in [1, 2] else 0

	if gtype in ["apron_skirt", "shawl_skirt"]:
		# Saia longa com fenda de passo e sapatos na base
		var w := 4 if row in [Row.DOWN, Row.UP] else 3
		for y in range(hip_y, foot_y - 1):
			var flare := 1 if y > hip_y + 2 else 0
			for x in range(cx - w - flare, cx + w + flare):
				var col := p_mid
				if x < cx - w + 1:
					col = p_dark
				elif x == cx - 1 or x == cx + 1:
					col = p_light if (y % 2 == 0) else p_mid
				_pset(img, x, y, col)
		# Sapatos aparecendo embaixo
		if row == Row.DOWN or row == Row.UP:
			_frect(img, cx - 3 - stance_spread, foot_y - 2 + ldy, 2, 2, shoe)
			_frect(img, cx + 1 + stance_spread, foot_y - 2 + rdy, 2, 2, shoe)
		else:
			var stride := (ldx - rdx) + stance_spread
			_frect(img, cx - 3 + stride, foot_y - 2 + ldy, 3, 2, shoe)
			_frect(img, cx + 1 - stride, foot_y - 2 + rdy, 3, 2, shoe)
		return

	if row == Row.DOWN or row == Row.UP:
		var lx := cx - 3 - stance_spread
		var rx := cx + 1 + stance_spread
		var lw := 2
		# Perna esquerda
		_frect(img, lx, hip_y, lw, foot_y - hip_y - 1 + ldy, p_mid)
		_frect(img, lx, hip_y, 1, foot_y - hip_y - 1 + ldy, p_light)
		if is_child:
			_frect(img, lx, foot_y - 3 + ldy, lw, 2, spec["skin_dark"])
		_frect(img, lx, foot_y - 1 + ldy, lw + 1, 2, shoe)
		# Perna direita
		_frect(img, rx, hip_y, lw, foot_y - hip_y - 1 + rdy, p_dark)
		_frect(img, rx, hip_y, 1, foot_y - hip_y - 1 + rdy, p_mid)
		if is_child:
			_frect(img, rx, foot_y - 3 + rdy, lw, 2, spec["skin_dark"])
		_frect(img, rx - 1, foot_y - 1 + rdy, lw + 1, 2, shoe)
	else:
		# Lateral: passos alternam para frente e para trás
		var front_x := cx - 1 + (ldx * 2) - stance_spread
		var back_x := cx - 1 - (ldx * 2) + stance_spread
		_frect(img, back_x, hip_y, 2, foot_y - hip_y - 1 + rdy, p_dark)
		_frect(img, back_x, foot_y - 1 + rdy, 3, 2, shoe)
		_frect(img, front_x, hip_y, 3, foot_y - hip_y - 1 + ldy, p_mid)
		_frect(img, front_x + (1 if row == Row.RIGHT else 0), hip_y, 1, foot_y - hip_y - 1 + ldy, p_light)
		if is_child:
			_frect(img, front_x, foot_y - 3 + ldy, 2, 2, spec["skin_dark"])
		_frect(img, front_x - (1 if row == Row.LEFT else 0), foot_y - 1 + ldy, 3, 2, shoe)


func _draw_torso(img: Image, spec: Dictionary, row: int, cx: int, top_y: int, hip_y: int, torso_h: int, is_child: bool) -> void:
	var s_light: Color = spec["shirt_light"]
	var s_mid: Color = spec["shirt_mid"]
	var s_dark: Color = spec["shirt_dark"]
	var a_light: Color = spec["apron_light"]
	var a_mid: Color = spec["apron_mid"]
	var a_dark: Color = spec["apron_dark"]
	var gtype: String = str(spec.get("garment_type", ""))

	var half_w := (4 if not is_child else 3) if row in [Row.DOWN, Row.UP] else 3
	for y in range(top_y, hip_y + 1):
		for x in range(cx - half_w, cx + half_w):
			var col := s_mid
			if y == top_y:
				col = s_light
			elif x == cx - half_w or x == cx + half_w - 1 or y == hip_y:
				col = s_dark

			# Detalhes por tipo de roupa
			if gtype == "striped_shorts":
				if (y - top_y) % 2 == 1:
					col = a_mid if x > cx - half_w else a_dark
				elif (y - top_y) == 0:
					col = s_light
			elif gtype == "apron_skirt" or gtype == "market_apron":
				if row == Row.DOWN and x >= cx - 2 and x < cx + 2 and y >= top_y + 2:
					col = a_light if y == top_y + 2 else (a_dark if y == hip_y else a_mid)
				elif row == Row.UP and y == top_y + 4:
					col = a_dark # alça amarrada atrás
				elif (row == Row.LEFT or row == Row.RIGHT) and y >= top_y + 3:
					var front_edge := (row == Row.LEFT and x < cx) or (row == Row.RIGHT and x >= cx)
					if front_edge:
						col = a_mid
			elif gtype == "mechanic_vest":
				if row == Row.DOWN and (x == cx - 2 or x == cx + 1):
					col = a_dark # alças sujas de graxa
				# Toalha no ombro esquerdo
				if x >= cx - half_w and x <= cx - 1 and y >= top_y and y <= top_y + 3 and row != Row.RIGHT:
					col = a_light if y == top_y else a_mid
			elif gtype == "shawl_skirt":
				if y <= top_y + 3:
					col = a_light if y == top_y else (a_mid if y < top_y + 3 else a_dark)
			_pset(img, x, y, col)

	# Gola / sombra do pescoço
	if row != Row.UP:
		_frect(img, cx - 1, top_y, 2, 1, spec["skin_dark"])


func _draw_arm(img: Image, spec: Dictionary, ax: int, ay: int, is_child: bool, _side: int) -> void:
	var arm_h := 5 if is_child else 6
	_frect(img, ax, ay, 2, 2, spec["shirt_dark"])
	_frect(img, ax, ay + 2, 2, arm_h - 3, spec["skin_mid"])
	_pset(img, ax, ay + arm_h - 1, spec["skin_dark"])
	_pset(img, ax + 1, ay + arm_h - 1, spec["skin_light"])


func _draw_head_and_hat(img: Image, spec: Dictionary, row: int, cx: int, top_y: int, w: int, h: int, is_distorted: bool) -> void:
	var sk_l: Color = spec["skin_light"]
	var sk_m: Color = spec["skin_mid"]
	var sk_d: Color = spec["skin_dark"]
	var hr_l: Color = spec["hair_light"]
	var hr_m: Color = spec["hair_mid"]
	var hr_d: Color = spec["hair_dark"]
	var eye_c: Color = spec["eye_col"]
	var eye_g: Color = spec["eye_glint"]
	var hat_type: String = str(spec.get("hat_type", "messy_hair"))

	var hw := w / 2 if row in [Row.DOWN, Row.UP] else (w / 2 - 1)
	var hh := h

	# Oval da cabeça
	for dy in range(hh):
		var shrink := 1 if (dy == 0 or dy == hh - 1) else 0
		for dx in range(-hw + shrink, hw - shrink):
			var col := sk_m
			if row == Row.UP:
				col = hr_d if dy > hh - 3 else (hr_l if dy < 3 else hr_m)
			else:
				if dy <= 2:
					col = hr_l if dy == 0 else hr_m
				elif dy == hh - 1:
					col = sk_d
				elif dx == -hw + shrink or dx == hw - shrink - 1:
					col = sk_d
				elif dy <= 4 and dx > -2 and dx < 2:
					col = sk_l
			_pset(img, cx + dx, top_y + dy, col)

	# Cabelo traseiro nas vistas laterais e superior
	if row == Row.LEFT:
		_frect(img, cx + 1, top_y + 1, hw, hh - 3, hr_m)
		_frect(img, cx + hw - 1, top_y + 2, 2, hh - 4, hr_d)
	elif row == Row.RIGHT:
		_frect(img, cx - hw - 1, top_y + 1, hw, hh - 3, hr_m)
		_frect(img, cx - hw - 1, top_y + 2, 2, hh - 4, hr_d)
	elif row == Row.DOWN:
		# Mechas laterais do cabelo
		_frect(img, cx - hw, top_y + 2, 1, 4, hr_d)
		_frect(img, cx + hw - 1, top_y + 2, 1, 4, hr_d)

	# Rosto (Down / Left / Right)
	if row == Row.DOWN:
		var eye_y := top_y + hh - 4
		if is_distorted:
			# Órbitas fundas com ponto rubro e boca escura alongada
			_frect(img, cx - 3, eye_y - 1, 2, 2, eye_c)
			_frect(img, cx + 1, eye_y - 1, 2, 2, eye_c)
			_pset(img, cx - 2, eye_y, eye_g)
			_pset(img, cx + 1, eye_y, eye_g)
			_frect(img, cx - 1, eye_y + 2, 2, 2, eye_c)
		else:
			_frect(img, cx - 3, eye_y - 1, 1, 2, eye_c)
			_frect(img, cx + 2, eye_y - 1, 1, 2, eye_c)
			_pset(img, cx - 3, eye_y - 1, eye_g if hat_type == "elder_bun" else eye_c)
			_pset(img, cx - 1, eye_y + 2, sk_d)
			_pset(img, cx, eye_y + 2, sk_d)
	elif row == Row.LEFT:
		var ey := top_y + hh - 4
		_frect(img, cx - hw + 1, ey - 1, 1, 2, eye_c)
		if is_distorted:
			_pset(img, cx - hw + 1, ey, eye_g)
			_frect(img, cx - hw + 1, ey + 2, 2, 2, eye_c)
	elif row == Row.RIGHT:
		var ey := top_y + hh - 4
		_frect(img, cx + hw - 2, ey - 1, 1, 2, eye_c)
		if is_distorted:
			_pset(img, cx + hw - 2, ey, eye_g)
			_frect(img, cx + hw - 2, ey + 2, 2, 2, eye_c)

	# Chapéus / Coques específicos
	match hat_type:
		"bun", "elder_bun":
			var b_l := hr_l
			var b_m := hr_m
			var b_d := hr_d
			if row == Row.DOWN:
				_frect(img, cx - 2, top_y - 2, 4, 2, b_m)
				_frect(img, cx - 1, top_y - 2, 2, 1, b_l)
			elif row == Row.LEFT:
				_frect(img, cx + hw - 1, top_y + 2, 3, 4, b_d)
				_frect(img, cx + hw, top_y + 2, 2, 2, b_m)
			elif row == Row.RIGHT:
				_frect(img, cx - hw - 2, top_y + 2, 3, 4, b_d)
				_frect(img, cx - hw - 1, top_y + 2, 2, 2, b_m)
			elif row == Row.UP:
				_frect(img, cx - 2, top_y + 1, 4, 4, b_l)
				_frect(img, cx - 1, top_y + 2, 2, 3, b_d)
		"cap":
			var c_l: Color = spec["hat_light"]
			var c_m: Color = spec["hat_mid"]
			var c_d: Color = spec["hat_dark"]
			_frect(img, cx - hw, top_y - 1, hw * 2, 3, c_m)
			_frect(img, cx - hw + 1, top_y - 1, hw * 2 - 2, 1, c_l)
			if row == Row.DOWN:
				_frect(img, cx - hw, top_y + 2, hw * 2, 1, c_d)
			elif row == Row.LEFT:
				_frect(img, cx - hw - 3, top_y + 1, 4, 2, c_d)
			elif row == Row.RIGHT:
				_frect(img, cx + hw - 1, top_y + 1, 4, 2, c_d)
		"messy_hair":
			# Topetes bagunçados de criança
			_pset(img, cx - 3, top_y - 1, hr_m)
			_pset(img, cx, top_y - 1, hr_l)
			_pset(img, cx + 2, top_y - 1, hr_d)
			if row != Row.UP:
				_frect(img, cx - 2, top_y + 2, 5, 1, hr_d)
		"salakot", "salakot_cracked":
			var hl: Color = spec["hat_light"]
			var hm: Color = spec["hat_mid"]
			var hd: Color = spec["hat_dark"]
			var broken := (hat_type == "salakot_cracked")
			# Aba larga cônica do chapéu tradicional filipino salakot
			_frect(img, cx - 1, top_y - 4, 2, 2, hl)
			_frect(img, cx - 3, top_y - 2, 6, 2, hl)
			_frect(img, cx - 6, top_y, 12, 2, hm)
			_frect(img, cx - 7, top_y + 2, 14, 1, hd)
			if broken:
				# Fissura escura / palha quebrada
				_pset(img, cx + 2, top_y, Color(0, 0, 0, 0))
				_pset(img, cx + 3, top_y + 1, Color("#961c24"))
				_pset(img, cx - 5, top_y + 2, Color(0, 0, 0, 0))
			if row != Row.UP:
				# Sombra pesada sob o salakot
				_frect(img, cx - hw + 1, top_y + 3, hw * 2 - 2, 1, hd)


func _draw_prop(img: Image, spec: Dictionary, row: int, hand: Vector2i, shoulder_y: int, action_phase: int) -> void:
	var ptype: String = str(spec.get("prop_type", ""))
	var c1: Color = spec.get("prop_col1", Color("#8a8f99"))
	var c2: Color = spec.get("prop_col2", Color("#cdd4de"))

	var side := -1 if row == Row.LEFT else (1 if row == Row.RIGHT else 0)
	var hx := hand.x
	var hy := hand.y

	match ptype:
		"broom":
			if action_phase < 0:
				return
			if side != 0:
				_frect(img, hx if side > 0 else hx - 4, hy - 1, 5, 1, c1)
				_frect(img, hx + 4 if side > 0 else hx - 6, hy - 2, 2, 3, c2)
			elif row == Row.UP:
				_frect(img, hx, shoulder_y - 6, 1, 7, c1)
				_frect(img, hx - 1, shoulder_y - 8, 3, 3, c2)
			else:
				_frect(img, hx, hy - 4, 1, 7, c1)
				_frect(img, hx - 1, hy + 2, 3, 3, c2)
		"wrench":
			if side != 0:
				_frect(img, hx if side > 0 else hx - 3, hy - 1, 4, 2, c1)
				_frect(img, hx + 3 if side > 0 else hx - 4, hy - 2, 2, 3, c2)
			elif row == Row.UP:
				_frect(img, hx, shoulder_y - 5, 2, 6, c1)
				_frect(img, hx - 1, shoulder_y - 6, 3, 2, c2)
			else:
				_frect(img, hx, hy - 2, 2, 5, c1)
				_frect(img, hx - 1, hy + 2, 3, 2, c2)
		"knife", "knife_blood":
			if action_phase < 0 and ptype == "knife":
				return
			if side != 0:
				_frect(img, hx if side > 0 else hx - 1, hy, 2, 1, Color("#3a281d"))
				_frect(img, hx + 2 if side > 0 else hx - 4, hy, 3, 1, c1)
				if ptype == "knife_blood":
					_pset(img, hx + 4 if side > 0 else hx - 4, hy, c2)
			elif row == Row.UP:
				_frect(img, hx, shoulder_y - 4, 1, 4, c1)
				if ptype == "knife_blood":
					_pset(img, hx, shoulder_y - 5, c2)
			else:
				_frect(img, hx, hy, 1, 3, c1)
				if ptype == "knife_blood":
					_pset(img, hx, hy + 3, c2)
		"lantern":
			var lift := 2 if action_phase in [1, 2] else 0
			var lx := hx + (1 if side > 0 else (-1 if side < 0 else 0))
			var ly := hy - lift
			_pset(img, lx, ly - 1, Color("#52402b"))
			_frect(img, lx - 1, ly, 3, 3, c1)
			_pset(img, lx, ly + 1, c2)
			if action_phase in [1, 2]:
				_pset(img, lx - 2, ly + 1, Color(c2.r, c2.g, c2.b, 0.55))
				_pset(img, lx + 2, ly + 1, Color(c2.r, c2.g, c2.b, 0.55))
				_pset(img, lx, ly - 1, Color(c2.r, c2.g, c2.b, 0.65))
		"claw_lunge":
			if action_phase < 0:
				return
			_frect(img, hx, hy, 2, 2, c1)
			if side != 0:
				_pset(img, hx + (2 if side > 0 else -1), hy, c2)
				_pset(img, hx + (2 if side > 0 else -1), hy + 1, c2)
			else:
				_pset(img, hx, hy + (2 if row == Row.DOWN else -1), c2)
				_pset(img, hx + 1, hy + (2 if row == Row.DOWN else -1), c2)
		"stone_throw":
			if action_phase in [1, 2]:
				_frect(img, hx, hy - 1, 2, 2, c1)
				_pset(img, hx, hy - 1, c2)


func _apply_pixel_outline(src: Image) -> Image:
	var out := Image.create(CELL, CELL, false, Image.FORMAT_RGBA8)
	out.fill(Color(0, 0, 0, 0))
	for y in range(CELL):
		for x in range(CELL):
			var c := src.get_pixel(x, y)
			if c.a > 0.05:
				out.set_pixel(x, y, c)
			else:
				var has_neighbor := false
				for offset in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
					var nx: int = x + offset.x
					var ny: int = y + offset.y
					if nx >= 0 and nx < CELL and ny >= 0 and ny < CELL:
						if src.get_pixel(nx, ny).a > 0.65:
							has_neighbor = true
							break
				if has_neighbor:
					out.set_pixel(x, y, OUTLINE)
	return out


func _frect(img: Image, x0: int, y0: int, w: int, h: int, col: Color) -> void:
	for y in range(y0, y0 + h):
		for x in range(x0, x0 + w):
			_pset(img, x, y, col)


func _pset(img: Image, x: int, y: int, col: Color) -> void:
	if x >= 1 and x < CELL - 1 and y >= 1 and y < CELL - 1:
		img.set_pixel(x, y, col)


# ==============================================================================
# RETRATO CRT FNAF 96x96 DA SENHORA LUNINGNING
# ==============================================================================

func _build_luningning_portrait() -> Image:
	var bust := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	bust.fill(Color(0, 0, 0, 0))

	var hair_l := Color("#c0c5d1")
	var hair_m := Color("#888e9e")
	var hair_d := Color("#4f5463")
	var skin_l := Color("#ad8c79")
	var skin_m := Color("#8b6c5c")
	var skin_d := Color("#5f463b")
	var shawl_l := Color("#664c7d")
	var shawl_m := Color("#453257")
	var shawl_d := Color("#271b33")

	# Coque arredondado no topo
	for y in range(11, 15):
		var inset := 1 if (y == 11 or y == 14) else 0
		for x in range(13 + inset, 19 - inset):
			var c := hair_l if y == 12 else hair_m
			if y == 14:
				c = hair_d
			bust.set_pixel(x, y, c)

	# Massa orgânica de cabelo grisalho ao redor do rosto
	for y in range(14, 25):
		var inset := 2 if y == 14 else (1 if y <= 15 else 0)
		for x in range(10 + inset, 22 - inset):
			var c := hair_m
			if y <= 15:
				c = hair_l if (x >= 13 and x <= 18) else hair_m
			elif x <= 11 or x >= 20:
				c = hair_d
			bust.set_pixel(x, y, c)

	# Rosto arredondado de idosa
	for y in range(16, 25):
		var inset := 1 if (y == 16 or y >= 23) else 0
		for x in range(11 + inset, 21 - inset):
			var c := skin_m
			if y == 16:
				c = hair_d if (x <= 12 or x >= 19) else skin_d
			elif y == 24 or x == 11 or x == 20:
				c = skin_d
			elif y >= 18 and y <= 21 and x >= 13 and x <= 18:
				c = skin_l
			bust.set_pixel(x, y, c)

	# Rugas sutis e olhos melancólicos com brilho frio
	for ex in [13, 18]:
		bust.set_pixel(ex, 19, Color("#110f18"))
		bust.set_pixel(ex, 20, Color("#1d1a26"))
		bust.set_pixel(ex, 21, Color("#56403c"))
		bust.set_pixel(ex + (1 if ex == 13 else -1), 19, Color("#c8cdd9"))
	bust.set_pixel(15, 22, skin_d)
	bust.set_pixel(16, 22, skin_d)

	# Ombros curvados + Xale de vigília
	for y in range(25, 31):
		var edge := 3 if y == 25 else (2 if y == 26 else 1)
		for x in range(7 + edge, 25 - edge):
			var c := shawl_m
			if y == 25:
				c = shawl_l if (x >= 11 and x <= 20) else shawl_d
			elif x == 7 + edge or x == 24 - edge:
				c = shawl_d
			elif x >= 14 and x <= 17 and y <= 28:
				c = Color("#2a2f44") if y > 25 else Color("#75586f")
			bust.set_pixel(x, y, c)

	# Compor sobre fundo CRT escuro com contorno preto ao redor do busto
	var grid := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	for y in range(32):
		var bg := Color("#11121b") if (y % 2 == 0) else Color("#0c0d14")
		for x in range(32):
			var px := bust.get_pixel(x, y)
			if px.a > 0.5:
				grid.set_pixel(x, y, px)
			else:
				var near := false
				for o in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
					var nx: int = x + o.x
					var ny: int = y + o.y
					if nx >= 0 and nx < 32 and ny >= 0 and ny < 32 and bust.get_pixel(nx, ny).a > 0.5:
						near = true
						break
				grid.set_pixel(x, y, Color("#07080d") if near else bg)

	# Escalar 3x -> 96x96 crisp e aplicar borda CRT #C77DFF + scanlines finas
	var out := Image.create(96, 96, false, Image.FORMAT_RGBA8)
	for y in range(96):
		for x in range(96):
			var col := grid.get_pixel(x / 3, y / 3)
			if y % 3 == 2:
				col = col.darkened(0.08)
			if x == 1 or x == 94 or y == 1 or y == 94:
				col = Color("#C77DFF")
			elif x == 0 or x == 95 or y == 0 or y == 95:
				col = Color("#0b0c12")
			out.set_pixel(x, y, col)
	return out
