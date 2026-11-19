extends SceneTree

## Auditoria, Padronização e Regeneração 16-bit de Retratos (Portraits) — Huwag (Godot 4)
## Base obrigatória: Visual Padrão 16-bit de Huwag (huwag_casual_neutral.png)
## - 96x96 px exatos em 100% dos arquivos
## - Contorno 1px escuro nítido, zero anti-aliasing borrado, zero fundo sólido (PNG Alpha == 0.0 fora da silhueta)
## - 15 NPCs/Entidades Normais + 15 Variantes em Modo Corrompido (pele pálida/acinzentada cadavérica,
##   olheiras profundas, veias/rachaduras escuras na pele, expressão vazia/perturbadora e olhos opacos/dilatados)
## - 18 Variantes de Huwag (Casual & BFP: 8 expressões alinhadas + Modo Corrompido cadavérico)

const TARGET_SIZE := 96
const PRIMARY_DIR := "res://assets/characters/portraits/"
const SPRITES_PORTRAIT_DIR := "res://assets/sprites/portraits/"
const BACKUP_DIR := "C:/Users/kennedy/.gemini/antigravity/brain/723210f5-bfa7-47fb-b4be-e278499af4f2/scratch/backup_portraits/"
const SCRATCH_DIR := "C:/Users/kennedy/.gemini/antigravity/brain/723210f5-bfa7-47fb-b4be-e278499af4f2/scratch/"


func _init() -> void:
	print("=== [Portraits 16-Bit] Iniciando Auditoria e Regeneracao Completa (96x96 RGBA Alpha) ===")

	# 1. Carregar e limpar o Retrato Mestre 16-bit de Huwag (huwag_casual_neutral.png)
	var huwag_base := _load_source_png("huwag_casual_neutral.png")
	_clean_huwag_master_silhouette(huwag_base)
	var huwag_bfp_base := _build_huwag_bfp_from_casual(huwag_base)

	var exprs := ["neutral", "worried", "tired", "surprised", "angry", "scared", "uneasy_smile", "unfiltered", "distorted"]
	var huwag_casual_map: Dictionary = {}
	var huwag_bfp_map: Dictionary = {}
	for e: String in exprs:
		huwag_casual_map[e] = _make_huwag_expression(huwag_base, e)
		huwag_bfp_map[e] = _make_huwag_expression(huwag_bfp_base, e)

	# 2. Carregar e padronizar os 10 retratos 16-bit de NPCs/Chefes existentes
	var normal_npcs: Dictionary = {}
	normal_npcs["cap_reyes"] = _clean_border_outline(_load_source_png("fnaf_cap_reyes.png"))
	normal_npcs["bombeiro_ato"] = _polish_bombeiro_ato(_load_source_png("fnaf_bombeiro_ato.png"))
	normal_npcs["bombeiro_santos"] = _clean_border_outline(_load_source_png("fnaf_bombeiro_santos.png"))
	normal_npcs["enfermeira_maria"] = _clean_border_outline(_load_source_png("fnaf_enfermeira_maria.png"))
	normal_npcs["aling_nena"] = _polish_aling_nena(_load_source_png("fnaf_aling_nena.png"))
	normal_npcs["kuya_ben"] = _polish_kuya_ben(_load_source_png("fnaf_kuya_ben.png"))
	normal_npcs["feirante"] = _clean_border_outline(_load_source_png("fnaf_feirante.png"))
	normal_npcs["mang_carding"] = _clean_border_outline(_load_source_png("fnaf_mang_carding.png"))
	normal_npcs["criatura_lagoa"] = _clean_border_outline(_load_source_png("fnaf_criatura_lagoa.png"))
	normal_npcs["santelmo"] = _polish_santelmo(_load_source_png("fnaf_santelmo.png"))

	# 3. Construir os 5 retratos 16-bit que estavam em estilo primitivo (Luningning, Lola Rosa, Toby, Vulto, Radio VHF)
	normal_npcs["luningning"] = _build_16bit_luningning()
	normal_npcs["lola_rosa"] = _build_16bit_lola_rosa()
	normal_npcs["toby"] = _build_16bit_toby()
	normal_npcs["vulto_bosque"] = _build_16bit_vulto_bosque()
	normal_npcs["vhs_radio"] = _build_16bit_vhs_radio()

	# 4. Construir todas as 15 variantes em Modo Corrompido 16-bit (fnaf_distorted_*)
	var distorted_npcs: Dictionary = {}
	for k: String in normal_npcs.keys():
		distorted_npcs[k] = _build_16bit_corrupted_npc(normal_npcs[k], k)

	# 5. Salvar todos os arquivos na pasta principal res://assets/characters/portraits/
	var saved_count := 0
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(PRIMARY_DIR))

	for e: String in exprs:
		_save_png(huwag_casual_map[e], PRIMARY_DIR + "huwag_casual_%s.png" % e)
		_save_png(huwag_bfp_map[e], PRIMARY_DIR + "huwag_bfp_%s.png" % e)
		saved_count += 2

	for k: String in normal_npcs.keys():
		_save_png(normal_npcs[k], PRIMARY_DIR + "fnaf_%s.png" % k)
		_save_png(distorted_npcs[k], PRIMARY_DIR + "fnaf_distorted_%s.png" % k)
		saved_count += 2

	# Aliases legados para compatibilidade total em res://assets/characters/portraits/
	_save_png(distorted_npcs["bombeiro_santos"], PRIMARY_DIR + "fnaf_distorted_bombeiro.png")
	var legacy_dist := ["aling_nena", "feirante", "kuya_ben", "lola_rosa", "luningning", "mang_carding", "toby"]
	for lk: String in legacy_dist:
		_save_png(distorted_npcs[lk], PRIMARY_DIR + "distorted_fnaf_%s.png" % lk)
	_save_png(normal_npcs["criatura_lagoa"], PRIMARY_DIR + "placeholder_creature.png")
	_save_png(normal_npcs["kuya_ben"], PRIMARY_DIR + "placeholder_npc_barangay.png")

	# 5b. Sincronizar espelhos em res://assets/sprites/portraits/ (<id>_normal.png / <id>_distorted.png)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SPRITES_PORTRAIT_DIR))
	_save_png(huwag_casual_map["neutral"], SPRITES_PORTRAIT_DIR + "huwag_casual_normal.png")
	_save_png(huwag_casual_map["distorted"], SPRITES_PORTRAIT_DIR + "huwag_casual_distorted.png")
	_save_png(huwag_bfp_map["neutral"], SPRITES_PORTRAIT_DIR + "huwag_bfp_normal.png")
	_save_png(huwag_bfp_map["distorted"], SPRITES_PORTRAIT_DIR + "huwag_bfp_distorted.png")
	var sprites_dir_map := {
		"aling_nena": "aling_nena",
		"bombeiro_ato": "bombeiro_ato",
		"bombeiro_santos": "bombeiro_santos",
		"cap_reyes": "cap_reyes",
		"criatura_lagoa": "criatura_lagoa",
		"enfermeira_maria": "enfermeira_maria",
		"kuya_ben": "kuya_ben",
		"lola_rosa": "lola_rosa",
		"mang_carding": "mang_carding",
		"mang_tomas": "feirante",
		"santelmo": "santelmo",
		"senhora_luningning": "luningning",
		"toby": "toby",
		"vhs_radio": "vhs_radio",
		"vulto_bosque": "vulto_bosque",
	}
	for sp_name: String in sprites_dir_map.keys():
		var src_k: String = sprites_dir_map[sp_name]
		_save_png(normal_npcs[src_k], SPRITES_PORTRAIT_DIR + "%s_normal.png" % sp_name)
		_save_png(distorted_npcs[src_k], SPRITES_PORTRAIT_DIR + "%s_distorted.png" % sp_name)
		saved_count += 2

	# 6. Sincronizar também os retratos individuais em res://assets/characters/<npc>/portrait.png
	var char_folder_map := {
		"aling_nena": "aling_nena",
		"aquatic_creature": "criatura_lagoa",
		"bombeiro_ato": "bombeiro_ato",
		"bombeiro_santos": "bombeiro_santos",
		"cap_reyes": "cap_reyes",
		"enfermeira_maria": "enfermeira_maria",
		"kuya_ben": "kuya_ben",
		"lola_rosa": "lola_rosa",
		"mang_carding": "mang_carding",
		"mang_tomas": "feirante",
		"senhora_luningning": "luningning",
		"toby": "toby",
		"vulto_bosque": "vulto_bosque",
	}
	for folder: String in char_folder_map.keys():
		var key: String = char_folder_map[folder]
		var p_norm := "res://assets/characters/%s/portrait.png" % folder
		var p_dist := "res://assets/characters/%s/distorted_portrait.png" % folder
		if FileAccess.file_exists(ProjectSettings.globalize_path(p_norm)):
			_save_png(normal_npcs[key], p_norm)
		if FileAccess.file_exists(ProjectSettings.globalize_path(p_dist)):
			_save_png(distorted_npcs[key], p_dist)

	if DirAccess.dir_exists_absolute(SCRATCH_DIR):
		_save_preview_huwag(huwag_casual_map, huwag_bfp_map, SCRATCH_DIR + "preview_new_huwag.png")
		_save_preview_npcs(normal_npcs, SCRATCH_DIR + "preview_new_normal_npcs.png")
		_save_preview_npcs(distorted_npcs, SCRATCH_DIR + "preview_new_distorted_npcs.png")
		_save_preview_5_rebuilt_3x(normal_npcs, distorted_npcs, SCRATCH_DIR + "preview_5_rebuilt_3x.png")

	print("=== [Portraits 16-Bit] Concluido com sucesso! (%d arquivos principais gravados) ===" % saved_count)
	quit(0)


func _load_source_png(fname: String) -> Image:
	var backup_path := BACKUP_DIR + fname
	if FileAccess.file_exists(backup_path):
		var b_img := Image.load_from_file(backup_path)
		if b_img != null:
			b_img.convert(Image.FORMAT_RGBA8)
			return b_img
	var proj_path := ProjectSettings.globalize_path("res://assets/characters/portraits/" + fname)
	var img := Image.load_from_file(proj_path)
	img.convert(Image.FORMAT_RGBA8)
	return img


func _save_png(img: Image, res_path: String) -> void:
	var abs_p := ProjectSettings.globalize_path(res_path)
	img.save_png(abs_p)


# ==============================================================================
# 1. HUWAG MASTER CLEANUP, BFP UNIFORM & PIXEL-PERFECT EXPRESSIONS
# ==============================================================================

func _clean_huwag_master_silhouette(img: Image) -> void:
	var ink := Color("#030000")
	for y in range(54, 65):
		for x in range(83, 96):
			img.set_pixel(x, y, Color(0, 0, 0, 0))
	for x in [21, 22]:
		img.set_pixel(x, 46, Color(0, 0, 0, 0))

	for y in range(68, 96):
		var t := float(y - 68) / 27.0
		var min_x := int(round(lerpf(14.0, 11.0, clampf(t * 1.4, 0.0, 1.0))))
		var max_x := int(round(lerpf(79.0, 86.0, clampf(t * 1.4, 0.0, 1.0))))
		for x in range(0, min_x):
			img.set_pixel(x, y, Color(0, 0, 0, 0))
		for x in range(max_x + 1, 96):
			img.set_pixel(x, y, Color(0, 0, 0, 0))
		for x in range(min_x, 48):
			if img.get_pixel(x, y).a > 0.5:
				img.set_pixel(x, y, ink)
				break
		for x in range(max_x, 48, -1):
			if img.get_pixel(x, y).a > 0.5:
				img.set_pixel(x, y, ink)
				break

	_keep_largest_alpha_island(img, 48, 48)


func _build_huwag_bfp_from_casual(casual_base: Image) -> Image:
	var out := casual_base.duplicate() as Image
	var ink := Color("#030000")
	for y in range(58, 96):
		for x in range(96):
			var c := out.get_pixel(x, y)
			if c.a < 0.5:
				continue
			if _is_skin_color(c, x, y, "huwag"):
				continue
			var lum := c.r * 0.299 + c.g * 0.587 + c.b * 0.114
			if lum < 0.05:
				out.set_pixel(x, y, ink)
				continue
			var in_lapel_v := (x >= 37 and x <= 57 and y >= 78) and (c.b > c.r + 0.02 or lum > 0.15)
			var on_jacket_shoulder := (y >= 88 and y <= 91) and (x <= 27 or x >= 68)
			if on_jacket_shoulder:
				var row_rel := y - 88
				var base_ref := Color("#E86E1C") if (row_rel == 0 or row_rel == 3) else Color("#F2D238")
				var shade_k := clampf(0.82 + lum * 0.75, 0.75, 1.10)
				out.set_pixel(x, y, Color(
					clampf(base_ref.r * shade_k, 0.0, 1.0),
					clampf(base_ref.g * shade_k, 0.0, 1.0),
					clampf(base_ref.b * shade_k, 0.0, 1.0),
					1.0
				))
			elif in_lapel_v:
				if lum < 0.14:
					out.set_pixel(x, y, Color("#111722"))
				elif lum < 0.24:
					out.set_pixel(x, y, Color("#1D2636"))
				else:
					out.set_pixel(x, y, Color("#2B384E"))
			else:
				if lum < 0.13:
					out.set_pixel(x, y, Color("#0D1524"))
				elif lum < 0.22:
					out.set_pixel(x, y, Color("#182640"))
				elif lum < 0.32:
					out.set_pixel(x, y, Color("#25395C"))
				else:
					out.set_pixel(x, y, Color("#375280"))
	return out


func _erase_huwag_mouth(img: Image) -> void:
	var skin_base := Color("#A17653")
	var skin_sh := Color("#72513F")
	for y in range(55, 61):
		for x in range(41, 57):
			var c := skin_base
			if x >= 54 or (y >= 60 and x >= 51):
				c = skin_sh
			img.set_pixel(x, y, c)


func _make_huwag_expression(base: Image, expr: String) -> Image:
	var out := base.duplicate() as Image
	if expr == "neutral":
		return out
	if expr == "distorted":
		return _build_16bit_corrupted_huwag(out)

	var skin_base := Color("#A17653")
	var skin_sh := Color("#72513F")
	var skin_deep := Color("#52342A")
	var ink := Color("#030000")
	var sclera := Color("#DED6C4")

	if expr == "worried":
		_erase_huwag_mouth(out)
		for x in range(40, 44):
			out.set_pixel(x, 33, ink)
			out.set_pixel(x, 36, skin_base)
		for x in range(51, 55):
			out.set_pixel(x, 32, ink)
			out.set_pixel(x, 35, skin_base)
		for x in range(34, 42):
			out.set_pixel(x, 43, skin_deep)
		for x in range(53, 61):
			out.set_pixel(x, 42, skin_deep)
		for x in range(45, 52):
			out.set_pixel(x, 57, ink if (x >= 47 and x <= 50) else skin_deep)
		out.set_pixel(44, 58, skin_deep)
		out.set_pixel(52, 58, skin_deep)
		for x in range(47, 51):
			out.set_pixel(x, 59, skin_sh)

	elif expr == "tired":
		_erase_huwag_mouth(out)
		for x in range(34, 42):
			out.set_pixel(x, 40, skin_sh)
			out.set_pixel(x, 41, ink)
			out.set_pixel(x, 43, skin_deep)
			out.set_pixel(x, 44, skin_sh)
		for x in range(53, 61):
			out.set_pixel(x, 39, skin_sh)
			out.set_pixel(x, 40, ink)
			out.set_pixel(x, 42, skin_deep)
			out.set_pixel(x, 43, skin_sh)
		for x in range(45, 53):
			out.set_pixel(x, 58, ink if (x >= 47 and x <= 50) else skin_deep)
		for x in range(47, 51):
			out.set_pixel(x, 60, skin_sh)

	elif expr == "surprised":
		_erase_huwag_mouth(out)
		for x in range(34, 43):
			out.set_pixel(x, 33, ink)
			out.set_pixel(x, 36, skin_base)
		for x in range(52, 61):
			out.set_pixel(x, 32, ink)
			out.set_pixel(x, 35, skin_base)
		for x in range(34, 42):
			out.set_pixel(x, 39, ink)
		for y in [40, 41]:
			out.set_pixel(34, y, sclera)
			out.set_pixel(35, y, sclera)
			out.set_pixel(36, y, skin_deep)
			out.set_pixel(37, y, ink)
			out.set_pixel(38, y, ink)
			out.set_pixel(39, y, skin_deep)
			out.set_pixel(40, y, sclera)
			out.set_pixel(41, y, sclera)
		out.set_pixel(37, 40, Color("#F2ECE0"))
		for x in range(53, 61):
			out.set_pixel(x, 38, ink)
		for y in [39, 40]:
			out.set_pixel(53, y, sclera)
			out.set_pixel(54, y, sclera)
			out.set_pixel(55, y, skin_deep)
			out.set_pixel(56, y, ink)
			out.set_pixel(57, y, ink)
			out.set_pixel(58, y, skin_deep)
			out.set_pixel(59, y, sclera)
			out.set_pixel(60, y, sclera)
		out.set_pixel(56, 39, Color("#F2ECE0"))
		for x in range(47, 51):
			out.set_pixel(x, 56, skin_deep)
			out.set_pixel(x, 57, ink)
			out.set_pixel(x, 58, ink)
			out.set_pixel(x, 59, skin_deep)
		out.set_pixel(46, 57, skin_deep)
		out.set_pixel(46, 58, skin_deep)
		out.set_pixel(51, 57, skin_deep)
		out.set_pixel(51, 58, skin_deep)

	elif expr == "angry":
		_erase_huwag_mouth(out)
		for x in range(40, 44):
			out.set_pixel(x, 36, ink)
			out.set_pixel(x, 37, ink)
		for x in range(50, 54):
			out.set_pixel(x, 35, ink)
			out.set_pixel(x, 36, ink)
		out.set_pixel(46, 36, skin_deep)
		out.set_pixel(47, 37, skin_deep)
		for x in range(44, 53):
			out.set_pixel(x, 57, ink)
		out.set_pixel(43, 58, ink)
		out.set_pixel(53, 58, ink)
		for x in range(46, 51):
			out.set_pixel(x, 59, skin_deep)

	elif expr == "scared":
		_erase_huwag_mouth(out)
		for x in range(40, 44):
			out.set_pixel(x, 33, ink)
			out.set_pixel(x, 36, skin_base)
		for x in range(51, 55):
			out.set_pixel(x, 32, ink)
			out.set_pixel(x, 35, skin_base)
		for x in range(34, 42):
			out.set_pixel(x, 39, ink)
			out.set_pixel(x, 43, skin_deep)
		for y in [40, 41]:
			for x in range(34, 42):
				out.set_pixel(x, y, sclera)
			out.set_pixel(37, y, ink)
			out.set_pixel(38, y, ink)
		out.set_pixel(36, 41, skin_deep)
		for x in range(53, 61):
			out.set_pixel(x, 38, ink)
			out.set_pixel(x, 42, skin_deep)
		for y in [39, 40]:
			for x in range(53, 61):
				out.set_pixel(x, y, sclera)
			out.set_pixel(56, y, ink)
			out.set_pixel(57, y, ink)
		out.set_pixel(55, 40, skin_deep)
		for x in range(45, 53):
			out.set_pixel(x, 56, skin_deep)
			out.set_pixel(x, 57, Color("#CFC4B4") if (x >= 46 and x <= 51) else ink)
			out.set_pixel(x, 58, ink)
		out.set_pixel(44, 58, skin_deep)
		out.set_pixel(53, 58, skin_deep)
		for x in range(46, 52):
			out.set_pixel(x, 59, skin_deep)

	elif expr == "uneasy_smile":
		for x in range(40, 44):
			out.set_pixel(x, 33, ink)
		for x in range(51, 55):
			out.set_pixel(x, 32, ink)
		for x in range(34, 42):
			out.set_pixel(x, 43, skin_deep)
		for x in range(53, 61):
			out.set_pixel(x, 42, skin_deep)
		out.set_pixel(41, 56, skin_deep)
		out.set_pixel(41, 57, skin_sh)

	elif expr == "unfiltered":
		_erase_huwag_mouth(out)
		for x in range(44, 53):
			out.set_pixel(x, 57, ink if (x >= 46 and x <= 51) else skin_deep)
		for x in range(46, 51):
			out.set_pixel(x, 59, skin_deep)
		for x in range(34, 42):
			out.set_pixel(x, 43, skin_deep)
		for x in range(53, 61):
			out.set_pixel(x, 42, skin_deep)
		for y in range(96):
			for x in range(96):
				var c := out.get_pixel(x, y)
				if c.a < 0.5:
					continue
				var g := c.r * 0.299 + c.g * 0.587 + c.b * 0.114
				g = clampf((g - 0.5) * 1.16 + 0.46, 0.0, 1.0)
				out.set_pixel(x, y, Color(g * 0.93, g * 0.95, minf(1.0, g * 1.02), 1.0))

	return out


# ==============================================================================
# 2. POLISHING THE 10 EXISTING 16-BIT PORTRAITS TO MATCH MAP SPRITES
# ==============================================================================

func _clean_border_outline(img: Image) -> Image:
	var out := img.duplicate() as Image
	var ink := Color("#050408")
	for y in range(96):
		if out.get_pixel(0, y).a > 0.5:
			out.set_pixel(0, y, Color(0, 0, 0, 0))
			if out.get_pixel(1, y).a > 0.5:
				out.set_pixel(1, y, ink)
		if out.get_pixel(95, y).a > 0.5:
			out.set_pixel(95, y, Color(0, 0, 0, 0))
			if out.get_pixel(94, y).a > 0.5:
				out.set_pixel(94, y, ink)
		if out.get_pixel(94, y).a > 0.5 and out.get_pixel(95, y).a < 0.5:
			var c94 := out.get_pixel(94, y)
			if (c94.r + c94.g + c94.b) > 0.35:
				out.set_pixel(94, y, ink)
	return out


func _polish_bombeiro_ato(img: Image) -> Image:
	var out := _clean_border_outline(img)
	for y in range(79, 85):
		for x in range(75, 86):
			var c := out.get_pixel(x, y)
			if c.a < 0.5:
				continue
			var mx := 94 - x
			var mc := out.get_pixel(mx, y)
			if mc.a > 0.5 and (mc.r > 0.65 and mc.g > 0.45):
				out.set_pixel(x, y, mc.darkened(0.08))
	return out


func _polish_aling_nena(img: Image) -> Image:
	var out := _clean_border_outline(img)
	for y in range(70, 96):
		for x in range(96):
			var c := out.get_pixel(x, y)
			if c.a < 0.5:
				continue
			var in_neck_skin := (x >= 35 and x <= 59 and y <= 81)
			if not in_neck_skin and (c.r > c.g + 0.12) and (c.r > 0.45):
				var lum := c.r * 0.299 + c.g * 0.587 + c.b * 0.114
				var col: Color
				if lum < 0.34:
					col = Color("#1F3F4A")
				elif lum < 0.46:
					col = Color("#2E5968")
				elif lum < 0.58:
					col = Color("#3F7385")
				else:
					col = Color("#568F9E")
				out.set_pixel(x, y, col)
	return out


func _polish_kuya_ben(img: Image) -> Image:
	var out := _clean_border_outline(img)
	for y in range(4, 34):
		for x in range(20, 76):
			var c := out.get_pixel(x, y)
			if c.a < 0.5:
				continue
			var lum := c.r * 0.299 + c.g * 0.587 + c.b * 0.114
			if lum > 0.16 and (c.g > c.b + 0.04 or c.b > c.r + 0.05) and (y <= 25 or (x >= 27 and x <= 68 and y <= 28)):
				var col: Color
				if lum < 0.28:
					col = Color("#1D2E4A")
				elif lum < 0.38:
					col = Color("#2A4268")
				elif lum < 0.48:
					col = Color("#395887")
				else:
					col = Color("#4E73A8")
				out.set_pixel(x, y, col)
	for y in range(14, 17):
		for x in range(44, 52):
			if y == 14 or y == 16 or x == 44 or x == 51:
				out.set_pixel(x, y, Color("#8A6828"))
			else:
				out.set_pixel(x, y, Color("#D4A848"))

	for y in range(67, 96):
		for x in range(96):
			var c := out.get_pixel(x, y)
			if c.a < 0.5:
				continue
			var in_neck := (x >= 35 and x <= 60 and y <= 82) and (c.r > c.g + 0.08) and (c.r > c.b + 0.12)
			if in_neck:
				continue
			var lum := c.r * 0.299 + c.g * 0.587 + c.b * 0.114
			if lum < 0.08:
				continue
			var col: Color
			if lum < 0.20:
				col = Color("#152033")
			elif lum < 0.30:
				col = Color("#20324E")
			elif lum < 0.42:
				col = Color("#2E476E")
			elif lum < 0.54:
				col = Color("#3E5E8E")
			else:
				col = Color("#5478AD")
			out.set_pixel(x, y, col)
	return out


func _polish_santelmo(img: Image) -> Image:
	var out := _clean_border_outline(img)
	for y in range(6, 36):
		for x in range(18, 78):
			if y >= 24 and x >= 31 and x <= 64:
				continue
			var c := out.get_pixel(x, y)
			if c.a < 0.5:
				continue
			var lum := c.r * 0.299 + c.g * 0.587 + c.b * 0.114
			var is_cyan_flame := (c.b > c.r + 0.20 and lum > 0.35)
			if not is_cyan_flame and lum >= 0.14 and lum <= 0.34:
				if lum > 0.23:
					out.set_pixel(x, y, Color("#B53E1A") if ((x + y) % 3 != 0) else Color("#E86E24"))
				elif lum > 0.18:
					out.set_pixel(x, y, Color("#662010"))
	return out


# ==============================================================================
# 3. FIVE NEW 16-BIT PORTRAITS (LUNINGNING, LOLA ROSA, TOBY, VULTO, RADIO VHF)
# ==============================================================================

func _build_16bit_luningning() -> Image:
	var nena := _load_source_png("fnaf_aling_nena.png")
	var maria := _load_source_png("fnaf_enfermeira_maria.png")
	var out := Image.create(96, 96, false, Image.FORMAT_RGBA8)
	out.fill(Color(0, 0, 0, 0))
	var ink := Color("#06050A")

	for y in range(10, 96):
		for x in range(96):
			var c := nena.get_pixel(x, y)
			if x >= 22 and x <= 30 and y >= 20 and y <= 31:
				var mc := nena.get_pixel(95 - x, y)
				if mc.a > 0.5:
					c = mc
			if c.a < 0.5:
				continue
			if y >= 44 and y <= 63 and (x <= 23 or x >= 72):
				continue
			out.set_pixel(x, y, c)

	for y in range(4, 17):
		for x in range(35, 61):
			var mc := maria.get_pixel(x, y)
			if mc.a > 0.5 and out.get_pixel(x, y).a < 0.5:
				var lum := mc.r * 0.299 + mc.g * 0.587 + mc.b * 0.114
				var sc: Color
				if lum < 0.06:
					sc = ink
				elif lum < 0.13:
					sc = Color("#4E5566")
				elif lum < 0.20:
					sc = Color("#7E879B")
				elif lum < 0.28:
					sc = Color("#AEB7CA")
				else:
					sc = Color("#DCE3F2")
				out.set_pixel(x, y, sc)

	for y in range(4, 65):
		for x in range(18, 78):
			var c := out.get_pixel(x, y)
			if c.a < 0.5:
				continue
			var lum := c.r * 0.299 + c.g * 0.587 + c.b * 0.114
			if lum < 0.07:
				continue
			var is_skin := (c.r > c.b + 0.13) and (y >= 20)
			if not is_skin:
				var sc: Color
				if lum < 0.22:
					sc = Color("#464C5C")
				elif lum < 0.34:
					sc = Color("#747D91")
				elif lum < 0.46:
					sc = Color("#A5AEBF")
				elif lum < 0.58:
					sc = Color("#CFD6E6")
				else:
					sc = Color("#EEF2FA")
				out.set_pixel(x, y, sc)

	var sk_hi := Color("#D8A67E")
	var sk_base := Color("#BF8C66")
	var sk_mid := Color("#9E6C49")
	var sk_sh := Color("#754B30")
	var sk_deep := Color("#4E2E1D")
	for y in range(20, 84):
		for x in range(24, 72):
			var c := out.get_pixel(x, y)
			if c.a < 0.5:
				continue
			if c.r > c.b + 0.13 and c.r > c.g + 0.05 and y < 78:
				var lum := c.r * 0.299 + c.g * 0.587 + c.b * 0.114
				if lum > 0.62:
					out.set_pixel(x, y, sk_hi)
				elif lum > 0.50:
					out.set_pixel(x, y, sk_base)
				elif lum > 0.38:
					out.set_pixel(x, y, sk_mid)
				elif lum > 0.24:
					out.set_pixel(x, y, sk_sh)
	for y in range(53, 61):
		for x in range(37, 59):
			var col := sk_base
			if x <= 39 or x >= 56 or y >= 59:
				col = sk_mid
			out.set_pixel(x, y, col)
	for x in range(44, 52):
		out.set_pixel(x, 56, sk_deep if (x >= 46 and x <= 49) else sk_sh)
	out.set_pixel(43, 57, sk_deep)
	out.set_pixel(44, 57, sk_sh)
	out.set_pixel(51, 57, sk_sh)
	out.set_pixel(52, 57, sk_deep)
	for x in range(46, 50):
		out.set_pixel(x, 57, sk_hi)
		out.set_pixel(x, 58, sk_sh)
	out.set_pixel(39, 53, sk_sh); out.set_pixel(38, 54, sk_sh); out.set_pixel(38, 55, sk_mid)
	out.set_pixel(56, 53, sk_sh); out.set_pixel(57, 54, sk_sh); out.set_pixel(57, 55, sk_mid)
	out.set_pixel(40, 34, sk_deep); out.set_pixel(41, 33, sk_deep)
	out.set_pixel(55, 34, sk_deep); out.set_pixel(54, 33, sk_deep)

	for y in range(68, 96):
		for x in range(96):
			var c := out.get_pixel(x, y)
			if c.a < 0.5:
				continue
			var in_neck := (x >= 36 and x <= 59 and y <= 80) and (c.r > c.b + 0.12)
			if in_neck:
				continue
			var lum := c.r * 0.299 + c.g * 0.587 + c.b * 0.114
			if lum < 0.07:
				continue
			var is_shawl_strap := (c.r > 0.62 and c.g > 0.56 and c.b > 0.48)
			if is_shawl_strap:
				if lum < 0.68:
					out.set_pixel(x, y, Color("#8868A6"))
				elif lum < 0.78:
					out.set_pixel(x, y, Color("#A888C4"))
				else:
					out.set_pixel(x, y, Color("#C9ADE0"))
			elif x >= 37 and x <= 58 and y >= 82:
				if lum < 0.36:
					out.set_pixel(x, y, Color("#A69B92"))
				elif lum < 0.50:
					out.set_pixel(x, y, Color("#C9BFB4"))
				else:
					out.set_pixel(x, y, Color("#EAE2D8"))
			else:
				if lum < 0.34:
					out.set_pixel(x, y, Color("#2E1A42"))
				elif lum < 0.46:
					out.set_pixel(x, y, Color("#462963"))
				elif lum < 0.58:
					out.set_pixel(x, y, Color("#603B82"))
				else:
					out.set_pixel(x, y, Color("#7B50A1"))

	return _clean_border_outline(out)


func _build_16bit_lola_rosa() -> Image:
	var nena := _load_source_png("fnaf_aling_nena.png")
	var feirante := _load_source_png("fnaf_feirante.png")
	var out := Image.create(96, 96, false, Image.FORMAT_RGBA8)
	out.fill(Color(0, 0, 0, 0))
	var ink := Color("#060508")

	for y in range(66, 96):
		for x in range(96):
			var fc := feirante.get_pixel(x, y)
			if fc.a < 0.5:
				continue
			var lum := fc.r * 0.299 + fc.g * 0.587 + fc.b * 0.114
			if lum < 0.07:
				out.set_pixel(x, y, ink)
				continue
			var is_skin := (x >= 35 and x <= 60 and y <= 83) and (fc.r > fc.g + 0.08)
			if is_skin:
				out.set_pixel(x, y, fc)
				continue
			var is_towel := (fc.r > 0.62 and fc.g > 0.62 and fc.b > 0.58)
			if is_towel:
				if lum < 0.68:
					out.set_pixel(x, y, Color("#A8987E"))
				elif lum < 0.80:
					out.set_pixel(x, y, Color("#C9BA9E"))
				else:
					out.set_pixel(x, y, Color("#E8DEC6"))
			elif x >= 40 and x <= 55 and y >= 78:
				if lum < 0.28:
					out.set_pixel(x, y, Color("#4A2E1D"))
				elif lum < 0.40:
					out.set_pixel(x, y, Color("#6B442B"))
				else:
					out.set_pixel(x, y, Color("#8C5B3C"))
			else:
				if lum < 0.24:
					out.set_pixel(x, y, Color("#182B16"))
				elif lum < 0.34:
					out.set_pixel(x, y, Color("#264223"))
				elif lum < 0.46:
					out.set_pixel(x, y, Color("#385E34"))
				else:
					out.set_pixel(x, y, Color("#4D7D48"))

	var sk_hi := Color("#C98E62")
	var sk_base := Color("#AD734A")
	var sk_mid := Color("#8F5A36")
	var sk_sh := Color("#6B3F23")
	var sk_deep := Color("#472614")
	for y in range(10, 75):
		for x in range(22, 74):
			var nc := nena.get_pixel(x, y)
			if x >= 22 and x <= 30 and y >= 20 and y <= 31:
				var mc := nena.get_pixel(95 - x, y)
				if mc.a > 0.5:
					nc = mc
			if nc.a < 0.5:
				continue
			var lum := nc.r * 0.299 + nc.g * 0.587 + nc.b * 0.114
			var is_skin := (nc.r > nc.b + 0.13) and (y >= 20)
			if is_skin:
				var sc := sk_base
				if lum > 0.62:
					sc = sk_hi
				elif lum > 0.50:
					sc = sk_base
				elif lum > 0.38:
					sc = sk_mid
				elif lum > 0.24:
					sc = sk_sh
				else:
					sc = sk_deep
				out.set_pixel(x, y, sc)
			elif y <= 65:
				out.set_pixel(x, y, nc)

	for y in range(53, 60):
		for x in range(37, 59):
			var col := sk_base
			if x <= 39 or x >= 56 or y >= 59:
				col = sk_mid
			out.set_pixel(x, y, col)
	for x in range(43, 53):
		out.set_pixel(x, 56, ink if (x >= 45 and x <= 50) else sk_deep)
	out.set_pixel(42, 55, sk_deep)
	out.set_pixel(53, 55, sk_deep)
	for x in range(45, 51):
		out.set_pixel(x, 57, sk_hi)
		out.set_pixel(x, 58, sk_sh)
	out.set_pixel(37, 51, sk_deep)

	var sc_hi := Color("#F2ECE0")
	var sc_base := Color("#DDD4C2")
	var sc_mid := Color("#BEB29C")
	var sc_sh := Color("#968972")
	# Smooth top headscarf crown & seal upper silhouette contour cleanly
	for y in range(10, 14):
		for x in range(42, 54):
			if out.get_pixel(x, y).a < 0.5:
				out.set_pixel(x, y, ink if y == 10 else (sc_hi if x < 48 else sc_base))

	for y in range(8, 34):
		for x in range(21, 75):
			var cur := out.get_pixel(x, y)
			if cur.a < 0.5:
				continue
			var lum := cur.r * 0.299 + cur.g * 0.587 + cur.b * 0.114
			if lum < 0.07:
				continue
			var is_skin := (cur.r > cur.b + 0.13) and (y >= 22)
			var in_scarf_zone := (y <= 23) or (y <= 33 and (x <= 28 or x >= 67))
			if in_scarf_zone and (not is_skin or y <= 22):
				var col := sc_base
				if y == 23 and x >= 27 and x <= 68:
					col = ink
				elif y == 22 and x >= 27 and x <= 68:
					col = sc_sh
				elif lum < 0.24:
					col = sc_sh
				elif lum < 0.36:
					col = sc_mid
				elif lum < 0.48:
					col = sc_base
				else:
					col = sc_hi
				if y == 18 and (x in [36, 37, 47, 48, 58, 59]):
					col = Color("#C84638")
				out.set_pixel(x, y, col)

	# Ensure crisp 1px dark outline along upper contour of headscarf
	for x in range(20, 76):
		for y in range(8, 24):
			if out.get_pixel(x, y).a > 0.5:
				if out.get_pixel(x, y - 1).a < 0.5:
					out.set_pixel(x, y, ink)
				break

	# Delicate curved silver braid behind left earlobe resting over left collarbone (y=53..79)
	for y in range(53, 80):
		var t := float(y - 53) / 26.0
		var cx_b := 26.0 + sin(t * PI * 0.65) * 3.5
		var hw := lerpf(2.2, 1.3, t)
		var xl := int(round(cx_b - hw))
		var xr := int(round(cx_b + hw))
		for x in range(xl, xr + 1):
			if x == xl or x == xr or y == 79:
				out.set_pixel(x, y, ink)
			else:
				var seg := ((y + x) % 4)
				if seg == 0:
					out.set_pixel(x, y, Color("#626A7C"))
				elif float(x) < cx_b:
					out.set_pixel(x, y, Color("#EEF2FA") if seg == 1 else Color("#C8D0E0"))
				else:
					out.set_pixel(x, y, Color("#9EA6B8") if seg == 1 else Color("#767E91"))

	var leaf_pts := [
		Vector2i(33, 76), Vector2i(34, 76), Vector2i(32, 77), Vector2i(33, 77), Vector2i(34, 77),
		Vector2i(35, 78), Vector2i(36, 78), Vector2i(33, 79), Vector2i(34, 79), Vector2i(32, 80)
	]
	for lp in leaf_pts:
		out.set_pixel(lp.x, lp.y, Color("#78C268") if (lp.x + lp.y) % 2 == 0 else Color("#3E7834"))

	_keep_largest_alpha_island(out, 48, 48)
	return _clean_border_outline(out)


func _build_16bit_toby() -> Image:
	var santos := _load_source_png("fnaf_bombeiro_santos.png")
	var ben := _load_source_png("fnaf_kuya_ben.png")
	var out := Image.create(96, 96, false, Image.FORMAT_RGBA8)
	out.fill(Color(0, 0, 0, 0))
	var ink := Color("#050408")
	var sk_hi := Color("#D8A274")
	var sk_base := Color("#BD8356")
	var sk_sh := Color("#915C38")
	var sk_deep := Color("#5E361E")

	# 1. Clean 16-bit neck (y=62..78, x=39..56) drawn first so the chin sits cleanly on top of it
	for y in range(62, 79):
		for x in range(39, 57):
			if x == 39 or x == 56:
				out.set_pixel(x, y, ink)
			else:
				var dx := float(x) - 47.5
				var chin_sh_y := 67.5 - absf(dx) * 0.22
				if float(y) <= chin_sh_y:
					out.set_pixel(x, y, sk_deep if float(y) <= chin_sh_y - 1.2 else sk_sh)
				elif dx > 3.5:
					out.set_pixel(x, y, sk_sh)
				else:
					out.set_pixel(x, y, sk_base)

	# 2. Youthful crew-neck golden-yellow t-shirt with navy collar ring, chest stripe & olive backpack straps (y=73..95)
	for y in range(73, 96):
		var prog := float(y - 73) / 22.0
		var hw := int(round(lerpf(11.0, 35.0, pow(prog, 0.72))))
		var xl := 47 - hw
		var xr := 48 + hw
		for x in range(xl, xr + 1):
			# Keep inner neck opening at y <= 78
			var neck_half := maxi(0, 9 - (y - 72) * 2)
			if y <= 77 and absi(x - 47) < neck_half:
				continue
			if x == xl or x == xr or (y == 73 and absi(x - 47) >= neck_half):
				out.set_pixel(x, y, ink)
				continue
			# Olive-green backpack straps (x=21..26 and x=69..74, y >= 76)
			var on_strap := (y >= 76) and ((x >= 21 and x <= 26) or (x >= 69 and x <= 74))
			if on_strap:
				if x in [21, 26, 69, 74] or y == 76:
					out.set_pixel(x, y, ink)
				elif y in [85, 86]:
					out.set_pixel(x, y, Color("#AEB8C4"))
				else:
					out.set_pixel(x, y, Color("#4A7D52") if (x in [22, 23, 70, 71]) else Color("#2E5436"))
				continue
			# Navy crew-neck collar ring (2px around neck opening) or horizontal chest stripe (y=87..89)
			var dist_neck := absi(x - 47) - neck_half
			var on_collar_ring := (y <= 80 and dist_neck >= 0 and dist_neck <= 3 and absi(x - 47) <= 12)
			var on_chest_stripe := (y >= 87 and y <= 89)
			if on_collar_ring or on_chest_stripe:
				if on_collar_ring and dist_neck == 3:
					out.set_pixel(x, y, ink)
				elif y == 87 or y == 89:
					out.set_pixel(x, y, Color("#141E33"))
				else:
					out.set_pixel(x, y, Color("#243659") if x < 48 else Color("#18243D"))
			else:
				# 16-bit golden-yellow t-shirt with shoulder highlights and sleeve fold shadows
				var dx := float(x) - 47.5
				var col := Color("#DB9F20")
				if dx < -6.0 and y < 85:
					col = Color("#F5C238")
				elif dx > 10.0 or (absi(int(dx)) in [14, 15] and y >= 83):
					col = Color("#8A5E0B")
				elif dx > 3.0 or ((x + y) % 5 == 0 and dx > -4.0):
					col = Color("#B58014")
				out.set_pixel(x, y, col)

	# 3. Copy Santos's 16-bit youthful face down to his actual chin outline (y=24..64 -> sy=24..66)
	for y in range(24, 65):
		var sy := y if y <= 46 else (y + 2)
		for x in range(22, 74):
			var sx := int(round(47.5 + (float(x) - 47.5) * 1.04))
			var sc := santos.get_pixel(sx, sy)
			if sc.a < 0.5:
				continue
			# Exclude Santos's neck & shirt pixels outside the chin oval on rows y=58..64
			if y >= 58:
				var max_chin_hw := lerpf(13.0, 5.5, float(y - 58) / 6.0)
				if absf(float(x) - 47.5) > max_chin_hw:
					continue
			out.set_pixel(x, y, sc)

	for y in range(35, 39):
		for x in range(42, 54):
			out.set_pixel(x, y, sk_base if y < 38 else sk_sh)
	for x in range(34, 42):
		out.set_pixel(x, 34, ink)
		out.set_pixel(x, 35, ink if x <= 36 else sk_base)
		out.set_pixel(x, 36, sk_base)
	for x in range(54, 62):
		out.set_pixel(x, 34, ink)
		out.set_pixel(x, 35, ink if x >= 59 else sk_base)
		out.set_pixel(x, 36, sk_base)
	for side in [0, 1]:
		var bx := 33 if side == 0 else 53
		for x in range(bx + 1, bx + 8):
			out.set_pixel(x, 38, ink)
		for y in [39, 40, 41]:
			out.set_pixel(bx, y, ink)
			out.set_pixel(bx + 1, y, Color("#EFE8DC"))
			out.set_pixel(bx + 2, y, Color("#EFE8DC") if y < 41 else sk_sh)
			out.set_pixel(bx + 3, y, Color("#4A2A18"))
			out.set_pixel(bx + 4, y, ink)
			out.set_pixel(bx + 5, y, ink)
			out.set_pixel(bx + 6, y, Color("#4A2A18"))
			out.set_pixel(bx + 7, y, Color("#EFE8DC"))
			out.set_pixel(bx + 8, y, ink)
		out.set_pixel(bx + 3, 39, Color("#FFFFFF"))
		out.set_pixel(bx + 4, 39, Color("#FFFFFF"))
	for y in range(52, 59):
		for x in range(40, 56):
			out.set_pixel(x, y, sk_base)
	for x in range(43, 53):
		out.set_pixel(x, 55, ink if (x >= 45 and x <= 50) else sk_deep)
	out.set_pixel(42, 54, sk_deep)
	out.set_pixel(53, 54, sk_deep)
	for x in range(46, 50):
		out.set_pixel(x, 56, sk_hi)
		out.set_pixel(x, 57, sk_sh)

	for y in range(6, 33):
		for x in range(18, 78):
			var bc := ben.get_pixel(x, y + 1)
			if bc.a < 0.5:
				continue
			var lum := bc.r * 0.299 + bc.g * 0.587 + bc.b * 0.114
			var is_skin := (y >= 22 and x >= 31 and x <= 64 and bc.r > bc.g + 0.08 and bc.r > bc.b + 0.12)
			if is_skin:
				continue
			if lum < 0.08:
				out.set_pixel(x, y, ink)
			elif y <= 26 and (bc.g > bc.b + 0.03 or bc.b > bc.r + 0.05) and lum > 0.16:
				var cc: Color
				if lum < 0.23:
					cc = Color("#63160A")
				elif lum < 0.33:
					cc = Color("#942412")
				elif lum < 0.43:
					cc = Color("#C4381E")
				elif lum < 0.53:
					cc = Color("#E65232")
				else:
					cc = Color("#FF7654")
				out.set_pixel(x, y, cc)
			elif y >= 21:
				out.set_pixel(x, y, Color("#151822") if lum < 0.15 else Color("#272C3D"))

	return _clean_border_outline(out)


func _build_16bit_vulto_bosque() -> Image:
	var ato := _load_source_png("fnaf_bombeiro_ato.png")
	var out := Image.create(96, 96, false, Image.FORMAT_RGBA8)
	out.fill(Color(0, 0, 0, 0))
	var ink := Color("#030306")

	for y in range(26, 96):
		for x in range(96):
			var ac := ato.get_pixel(x, y)
			if ac.a < 0.5:
				continue
			var lum := ac.r * 0.299 + ac.g * 0.587 + ac.b * 0.114
			if lum < 0.06:
				out.set_pixel(x, y, ink)
				continue
			var in_neck_v := (y <= 84 and x >= 37 and x <= 58) and not (y >= 78 and (x <= 41 or x >= 54) and ac.r > 0.70)
			var is_refl := (y >= 75) and not in_neck_v and (ac.r > 0.65 and ac.g > 0.35 and ac.b < 0.35)
			var is_skin := in_neck_v or ((y <= 70 and x >= 24 and x <= 71) and (ac.r > ac.b + 0.12))
			if is_skin:
				if y <= 43:
					out.set_pixel(x, y, Color("#0A0B10") if lum < 0.48 else Color("#141722"))
				elif lum < 0.34:
					out.set_pixel(x, y, Color("#0E1017"))
				elif lum < 0.48:
					out.set_pixel(x, y, Color("#1A1D29"))
				elif lum < 0.60:
					out.set_pixel(x, y, Color("#272B3B"))
				else:
					out.set_pixel(x, y, Color("#363B4F"))
			elif is_refl:
				if lum > 0.62:
					out.set_pixel(x, y, Color("#E86A1E"))
				elif lum < 0.42:
					out.set_pixel(x, y, Color("#AD3E10"))
				else:
					out.set_pixel(x, y, Color("#662008"))
			else:
				if lum < 0.14:
					out.set_pixel(x, y, Color("#0B0C11"))
				elif lum < 0.22:
					out.set_pixel(x, y, Color("#151721"))
				elif lum < 0.32:
					out.set_pixel(x, y, Color("#222533"))
				else:
					out.set_pixel(x, y, Color("#33384A"))

	for side in [0, 1]:
		var bx := 33 if side == 0 else 54
		for y in range(38, 42):
			for x in range(bx, bx + 9):
				out.set_pixel(x, y, ink)
		for y in [39, 40]:
			out.set_pixel(bx + 2, y, Color("#8F240A"))
			out.set_pixel(bx + 3, y, Color("#E85C14"))
			out.set_pixel(bx + 4, y, Color("#FFB838"))
			out.set_pixel(bx + 5, y, Color("#E85C14"))
			out.set_pixel(bx + 6, y, Color("#8F240A"))
		out.set_pixel(bx + 4, 39, Color("#FFF4C2"))

	for x in range(43, 53):
		out.set_pixel(x, 56, ink)
		out.set_pixel(x, 57, Color("#24120C") if (x % 2 == 0) else ink)

	for y in range(5, 34):
		var cy := 21.0
		var rx := 25.0 if y < 25 else 29.0
		var ry := 16.0
		for x in range(16, 80):
			var dx := (float(x) - 47.5) / rx
			var dy := (float(y) - cy) / ry
			var d2 := dx * dx + dy * dy
			var in_dome := (y <= 26 and d2 <= 1.0)
			var in_visor_brim := (y >= 24 and y <= 30 and absf(float(x) - 47.5) <= 27.5 - float(absi(y - 27)) * 1.8)
			var in_ear_flaps := (y >= 28 and y <= 42 and ((x >= 19 and x <= 25) or (x >= 70 and x <= 76)))
			if in_dome or in_visor_brim or in_ear_flaps:
				var col := Color("#1F222E")
				if in_visor_brim:
					if y == 24 or y == 30 or absf(float(x) - 47.5) >= 26.0 - float(absi(y - 27)) * 1.8:
						col = ink
					elif y <= 26:
						col = Color("#34394C")
					else:
						col = Color("#11131C")
				elif in_ear_flaps:
					if x in [19, 25, 70, 76] or y == 42:
						col = ink
					else:
						col = Color("#161822") if (x in [20, 75]) else Color("#242836")
				else:
					if d2 > 0.88:
						col = ink
					elif d2 > 0.72 or dx > 0.42:
						col = Color("#13151E")
					elif dx < -0.22 and dy < -0.15:
						col = Color("#3C4256")
					elif absf(dx) < 0.14:
						col = Color("#2C3142")
				out.set_pixel(x, y, col)

	var crack_pts := [
		Vector2i(50, 9), Vector2i(50, 10), Vector2i(51, 11), Vector2i(51, 12), Vector2i(52, 13),
		Vector2i(51, 14), Vector2i(51, 15), Vector2i(52, 16), Vector2i(53, 17), Vector2i(52, 18),
		Vector2i(52, 19), Vector2i(51, 20), Vector2i(51, 21), Vector2i(52, 22), Vector2i(52, 23),
		Vector2i(51, 24), Vector2i(51, 25), Vector2i(50, 26), Vector2i(50, 27)
	]
	for cp in crack_pts:
		out.set_pixel(cp.x - 1, cp.y, ink)
		out.set_pixel(cp.x, cp.y, Color("#FF731E") if (cp.y % 3 != 0) else Color("#FFC84D"))
		out.set_pixel(cp.x + 1, cp.y, Color("#9E2B0C"))

	return _clean_border_outline(out)


func _build_16bit_vhs_radio() -> Image:
	var out := Image.create(96, 96, false, Image.FORMAT_RGBA8)
	out.fill(Color(0, 0, 0, 0))
	var ink := Color("#05060A")
	var c_dk := Color("#131720")
	var c_sh := Color("#1E2430")
	var c_md := Color("#2D3646")
	var c_hi := Color("#435066")
	var c_spec := Color("#637491")

	for y in range(4, 27):
		var hw := 3 if y >= 7 else 2
		var cx := 26
		for x in range(cx - hw, cx + hw + 1):
			if x == cx - hw or x == cx + hw or y == 4:
				out.set_pixel(x, y, ink)
			elif y >= 24:
				out.set_pixel(x, y, Color("#A88C4A") if x < cx else Color("#6E5828"))
			else:
				var rib := (y % 3 == 0)
				if x == cx - hw + 1:
					out.set_pixel(x, y, c_spec if rib else c_hi)
				elif x == cx:
					out.set_pixel(x, y, c_hi if rib else c_md)
				else:
					out.set_pixel(x, y, c_sh if rib else c_dk)

	for k in [[46, 54, 18], [58, 66, 19]]:
		var x0: int = k[0]
		var x1: int = k[1]
		var y0: int = k[2]
		for y in range(y0, 27):
			for x in range(x0, x1 + 1):
				if x == x0 or x == x1 or y == y0:
					out.set_pixel(x, y, ink)
				else:
					var knurl := (x % 2 == 0)
					if x <= x0 + 2:
						out.set_pixel(x, y, c_spec if knurl else c_hi)
					elif x >= x1 - 2:
						out.set_pixel(x, y, c_dk)
					else:
						out.set_pixel(x, y, c_hi if knurl else c_md)
	for y in range(22, 27):
		for x in range(35, 42):
			if x == 35 or x == 41 or y == 22:
				out.set_pixel(x, y, ink)
			else:
				out.set_pixel(x, y, Color("#F06A24") if y == 23 else Color("#B84312"))

	for y in range(26, 94):
		var inset := 2 if (y == 26 or y == 93) else (1 if (y == 27 or y == 92) else 0)
		var xl := 19 + inset
		var xr := 72 - inset
		for x in range(xl, xr + 1):
			if x == xl or x == xr or y == 26 or y == 93:
				out.set_pixel(x, y, ink)
			elif y == 27 or x == xl + 1:
				out.set_pixel(x, y, c_spec if (y < 55 and x < 55) else c_hi)
			elif y == 92 or x == xr - 1:
				out.set_pixel(x, y, c_dk)
			elif x <= xl + 3:
				out.set_pixel(x, y, c_hi if (y % 4 != 0) else c_sh)
			elif x >= xr - 3:
				out.set_pixel(x, y, c_sh if (y % 4 != 0) else c_dk)
			else:
				var dither := ((x + y) % 2 == 0)
				if x < 42 and y < 58:
					out.set_pixel(x, y, c_md if dither else c_hi)
				elif x > 55 or y > 78:
					out.set_pixel(x, y, c_sh if dither else c_md)
				else:
					out.set_pixel(x, y, c_md)

	for y in range(36, 55):
		for x in range(15, 20):
			if x == 15 or y == 36 or y == 54:
				out.set_pixel(x, y, ink)
			elif x == 16:
				out.set_pixel(x, y, Color("#FF8838") if (y % 3 != 0) else Color("#C44E14"))
			else:
				out.set_pixel(x, y, Color("#D95B1C") if (y % 3 != 0) else Color("#8F330B"))

	for y in range(29, 32):
		for x in range(62, 65):
			out.set_pixel(x, y, Color("#52FF7E") if (x == 63 and y == 30) else Color("#186E32"))

	for y in range(33, 54):
		for x in range(25, 67):
			if x == 25 or x == 66 or y == 33 or y == 53:
				out.set_pixel(x, y, ink)
			elif x == 26 or y == 34:
				out.set_pixel(x, y, Color("#061418"))
			elif x == 65 or y == 52:
				out.set_pixel(x, y, Color("#245C66"))
			else:
				var scan := (y % 2 == 0)
				out.set_pixel(x, y, Color("#0C282E") if scan else Color("#11363D"))

	for b in range(4):
		var bx := 29 + b * 3
		for by in range(39 - b, 40):
			out.set_pixel(bx, by, Color("#72F2E0"))
			out.set_pixel(bx + 1, by, Color("#3AB5A6"))
	for x in range(29, 63):
		var amp := 5.5 * sin(float(x - 29) * 0.55) * cos(float(x - 29) * 0.23)
		var wy := clampi(int(round(45.0 + amp)), 37, 50)
		for y in range(mini(45, wy), maxi(45, wy) + 1):
			out.set_pixel(x, y, Color("#B8FFF4") if y == wy else Color("#40C9B8"))

	for y in range(57, 83):
		for x in range(25, 67):
			var dx := float(x) - 45.5
			var dy := float(y) - 70.0
			var in_cone := (dx * dx + dy * dy <= 120.0)
			if x == 25 or x == 66 or y == 57 or y == 82:
				out.set_pixel(x, y, ink)
			elif (y - 57) % 3 == 1 and x >= 28 and x <= 63:
				if x in [39, 52]:
					out.set_pixel(x, y, c_md)
				else:
					out.set_pixel(x, y, ink if in_cone else c_dk)
			elif (y - 57) % 3 == 2 and x >= 28 and x <= 63:
				out.set_pixel(x, y, c_hi if not in_cone else c_md)
			else:
				out.set_pixel(x, y, c_sh if in_cone else c_md)

	for y in range(85, 90):
		for x in range(31, 61):
			if x == 31 or x == 60 or y == 85 or y == 89:
				out.set_pixel(x, y, ink)
			elif y == 87 and (x in [35, 36, 38, 40, 41, 45, 47, 48, 51, 53, 55, 56]):
				out.set_pixel(x, y, Color("#2B200E"))
			else:
				out.set_pixel(x, y, Color("#E0B244") if y == 86 else Color("#B58928"))

	for y in range(72, 95):
		var t := float(y - 72) / 22.0
		var cx_c := int(round(73.0 + sin(t * PI * 3.5) * 2.2 + t * 4.5))
		for dx in range(-2, 3):
			var px := cx_c + dx
			if dx == -2 or dx == 2 or y == 72 or y == 94:
				out.set_pixel(px, y, ink)
			elif dx == -1:
				out.set_pixel(px, y, c_hi)
			elif dx == 0:
				out.set_pixel(px, y, c_md)
			else:
				out.set_pixel(px, y, c_dk)

	return out


# ==============================================================================
# 4. CORRUPTED MODE 16-BIT TRANSFORMATION (HUWAG + ALL 15 NPCS/ENTITIES)
# ==============================================================================

func _is_skin_color(c: Color, x: int, y: int, id: String) -> bool:
	if y < 18 or y > 84 or x < 20 or x > 76:
		return false
	var lum := c.r * 0.299 + c.g * 0.587 + c.b * 0.114
	if id == "santelmo":
		return (y >= 26 and x >= 31 and x <= 64) and (lum > 0.34 and c.b >= c.r - 0.05)
	if id == "criatura_lagoa":
		return (c.b > c.r + 0.08 and lum > 0.22)
	if id == "huwag":
		if y < 25:
			return false
		if c.h >= 0.094 or (c.g - c.b) > 0.235:
			return false
		return (c.r > c.b + 0.12) and (c.r > c.g + 0.05)
	if id == "toby":
		if y <= 26:
			return false
		if y >= 67 and (x < 38 or x > 57 or y > 79):
			return false
		if c.h >= 0.096 or (c.g - c.b) > 0.35:
			return false
		return (c.r > c.b + 0.12) and (c.r > c.g + 0.04)
	if id == "cap_reyes" or id == "kuya_ben" or id == "feirante" or id == "lola_rosa":
		if y <= 23:
			return false
	return (c.r > c.b + 0.11) and (c.r > c.g + 0.04) and (c.h >= 0.038 and c.h <= 0.095)


func _build_16bit_corrupted_huwag(normal_huwag: Image) -> Image:
	var out := normal_huwag.duplicate() as Image
	_erase_huwag_mouth(out)
	_apply_cadaverous_palette(out, "huwag")
	var ink := Color("#050508")
	var sock_dk := Color("#16171E")
	var sock_md := Color("#2E303B")
	var sock_hi := Color("#4A4D5C")
	var sclera_dead := Color("#8C909C")
	var pinpoint := Color("#C8CDD8")

	for y in range(38, 46):
		for x in range(32, 44):
			var d := absf(float(x) - 37.5) / 5.5 + absf(float(y) - 41.5) / 3.5
			if d <= 1.25 and out.get_pixel(x, y).a > 0.5:
				out.set_pixel(x, y, sock_dk if d < 0.75 else (sock_md if d < 1.0 else sock_hi))
		for x in range(51, 63):
			var d := absf(float(x) - 56.5) / 5.5 + absf(float(y) - 40.5) / 3.5
			if d <= 1.25 and out.get_pixel(x, y).a > 0.5:
				out.set_pixel(x, y, sock_dk if d < 0.75 else (sock_md if d < 1.0 else sock_hi))

	for x in range(34, 42):
		out.set_pixel(x, 39, ink)
	for y in [40, 41]:
		out.set_pixel(33, y, ink)
		out.set_pixel(34, y, sclera_dead)
		out.set_pixel(35, y, sock_dk)
		out.set_pixel(36, y, ink)
		out.set_pixel(37, y, ink)
		out.set_pixel(38, y, ink)
		out.set_pixel(39, y, sock_dk)
		out.set_pixel(40, y, sclera_dead)
		out.set_pixel(41, y, ink)
	out.set_pixel(37, 41, pinpoint)

	for x in range(53, 61):
		out.set_pixel(x, 38, ink)
	for y in [39, 40]:
		out.set_pixel(52, y, ink)
		out.set_pixel(53, y, sclera_dead)
		out.set_pixel(54, y, sock_dk)
		out.set_pixel(55, y, ink)
		out.set_pixel(56, y, ink)
		out.set_pixel(57, y, ink)
		out.set_pixel(58, y, sock_dk)
		out.set_pixel(59, y, sclera_dead)
		out.set_pixel(60, y, ink)
	out.set_pixel(56, 40, pinpoint)

	_paint_corrupted_mouth(out, 48, 57, 0)

	_paint_dark_veins(out, [
		[Vector2i(33, 44), Vector2i(33, 47), Vector2i(32, 50), Vector2i(34, 53), Vector2i(33, 56)],
		[Vector2i(33, 49), Vector2i(36, 51), Vector2i(37, 54)],
		[Vector2i(59, 43), Vector2i(60, 46), Vector2i(59, 49), Vector2i(61, 52), Vector2i(60, 56)],
		[Vector2i(59, 48), Vector2i(56, 51), Vector2i(55, 53)],
		[Vector2i(42, 65), Vector2i(43, 69), Vector2i(41, 73), Vector2i(42, 78)],
		[Vector2i(54, 66), Vector2i(53, 71), Vector2i(55, 76), Vector2i(54, 81)],
	])
	return out


func _build_16bit_corrupted_npc(normal_img: Image, id: String) -> Image:
	var out := normal_img.duplicate() as Image
	if id == "vhs_radio":
		return _build_16bit_corrupted_radio(out)

	_apply_cadaverous_palette(out, id)
	var ink := Color("#050508")
	var sock_dk := Color("#16171E")
	var sock_md := Color("#2E303B")
	var sock_hi := Color("#4A4D5C")
	var sclera_dead := Color("#868A96")
	var pinpoint := Color("#C6CBD6")

	if id == "vulto_bosque":
		# Vulto do Bosque corrupted: ash-pale spectral face & cracked helmet so silhouette and deep sockets read clearly against #000000
		for y in range(28, 84):
			for x in range(24, 72):
				var c := out.get_pixel(x, y)
				if c.a < 0.5:
					continue
				var lum := c.r * 0.299 + c.g * 0.587 + c.b * 0.114
				var in_neck_skin := (y >= 67 and x >= 37 and x <= 58)
				var in_face_oval := (y >= 31 and y <= 67 and x >= 29 and x <= 66)
				if (in_face_oval or in_neck_skin) and lum > 0.055:
					if lum > 0.17:
						out.set_pixel(x, y, Color("#8C909E"))
					elif lum > 0.10:
						out.set_pixel(x, y, Color("#606472"))
					else:
						out.set_pixel(x, y, Color("#3B3E4A"))
		for y in range(37, 46):
			for x in range(31, 43):
				var d := absf(float(x) - 37.0) / 5.5 + absf(float(y) - 41.0) / 3.8
				if d <= 1.25 and out.get_pixel(x, y).a > 0.5:
					out.set_pixel(x, y, sock_dk if d < 0.72 else sock_md)
			for x in range(52, 64):
				var d := absf(float(x) - 58.0) / 5.5 + absf(float(y) - 41.0) / 3.8
				if d <= 1.25 and out.get_pixel(x, y).a > 0.5:
					out.set_pixel(x, y, sock_dk if d < 0.72 else sock_md)
		for side in [0, 1]:
			var bx := 33 if side == 0 else 54
			for y in range(38, 42):
				for x in range(bx, bx + 9):
					out.set_pixel(x, y, ink)
			out.set_pixel(bx + 4, 40, pinpoint)
			out.set_pixel(bx + 4, 39, sock_hi)
		_paint_corrupted_mouth(out, 48, 56, 2)
		_paint_dark_veins(out, [
			[Vector2i(33, 45), Vector2i(32, 48), Vector2i(34, 52), Vector2i(33, 56)],
			[Vector2i(61, 45), Vector2i(62, 49), Vector2i(60, 53), Vector2i(61, 56)],
			[Vector2i(42, 68), Vector2i(43, 72), Vector2i(41, 76)],
			[Vector2i(53, 68), Vector2i(52, 72), Vector2i(54, 76)],
		])
		return out

	var ey_y := 39
	var el_x := 33
	var er_x := 53
	var m_y := 56
	if id == "santelmo":
		ey_y = 40
		m_y = 57
	elif id == "criatura_lagoa":
		ey_y = 39
		m_y = 55
	elif id == "toby":
		m_y = 55

	var ref_skin_base := out.get_pixel(36, 48)
	var ref_skin_sh := out.get_pixel(36, 48).darkened(0.22)
	if id != "cap_reyes" and id != "feirante":
		for y in range(m_y - 2, m_y + 4):
			for x in range(39, 57):
				var cur := out.get_pixel(x, y)
				if cur.a > 0.5:
					out.set_pixel(x, y, ref_skin_base if (x > 41 and x < 54 and y < m_y + 2) else ref_skin_sh)

	for y in range(ey_y - 2, ey_y + 7):
		for x in range(el_x - 2, el_x + 11):
			var d := absf(float(x) - float(el_x + 4)) / 6.0 + absf(float(y) - float(ey_y + 2)) / 4.2
			if d <= 1.25 and out.get_pixel(x, y).a > 0.5:
				out.set_pixel(x, y, sock_dk if d < 0.72 else (sock_md if d < 0.98 else sock_hi))
		for x in range(er_x - 2, er_x + 11):
			var d := absf(float(x) - float(er_x + 4)) / 6.0 + absf(float(y) - float(ey_y + 2)) / 4.2
			if d <= 1.25 and out.get_pixel(x, y).a > 0.5:
				out.set_pixel(x, y, sock_dk if d < 0.72 else (sock_md if d < 0.98 else sock_hi))

	for side in [0, 1]:
		var bx := el_x if side == 0 else er_x
		for x in range(bx, bx + 9):
			out.set_pixel(x, ey_y - 1, ink)
			out.set_pixel(x, ey_y + 2, sock_dk)
		for y in [ey_y, ey_y + 1]:
			out.set_pixel(bx, y, ink)
			out.set_pixel(bx + 1, y, sclera_dead)
			out.set_pixel(bx + 2, y, sock_dk)
			out.set_pixel(bx + 3, y, ink)
			out.set_pixel(bx + 4, y, ink)
			out.set_pixel(bx + 5, y, ink)
			out.set_pixel(bx + 6, y, sock_dk)
			out.set_pixel(bx + 7, y, sclera_dead)
			out.set_pixel(bx + 8, y, ink)
		out.set_pixel(bx + 4, ey_y, pinpoint)

	var m_style := absi(id.hash()) % 3
	if id in ["cap_reyes", "feirante"]:
		m_style = 1
	_paint_corrupted_mouth(out, 48, m_y + 1, m_style)

	var v_chains := [
		[Vector2i(33, ey_y + 4), Vector2i(32, ey_y + 7), Vector2i(34, ey_y + 10), Vector2i(33, ey_y + 14)],
		[Vector2i(33, ey_y + 8), Vector2i(36, ey_y + 10), Vector2i(37, ey_y + 12)],
		[Vector2i(61, ey_y + 4), Vector2i(62, ey_y + 7), Vector2i(60, ey_y + 10), Vector2i(61, ey_y + 14)],
		[Vector2i(60, ey_y + 9), Vector2i(57, ey_y + 11), Vector2i(56, ey_y + 13)],
		[Vector2i(42, 65), Vector2i(43, 69), Vector2i(41, 73), Vector2i(42, 77)],
		[Vector2i(53, 66), Vector2i(52, 70), Vector2i(54, 74), Vector2i(53, 78)],
	]
	if m_style == 0:
		v_chains.append([Vector2i(36, 26), Vector2i(37, 29), Vector2i(35, 32)])
	elif m_style == 2:
		v_chains.append([Vector2i(58, 26), Vector2i(57, 29), Vector2i(59, 32)])
	_paint_dark_veins(out, v_chains)

	return out


func _paint_corrupted_mouth(img: Image, cx: int, my: int, style: int) -> void:
	var ink := Color("#050508")
	var lip_dk := Color("#252730")
	var lip_sh := Color("#464956")
	var lip_hi := Color("#6E7280")
	if style == 1:
		for x in range(cx - 4, cx + 4):
			img.set_pixel(x, my, ink if (x >= cx - 2 and x <= cx + 1) else lip_dk)
			img.set_pixel(x, my - 1, lip_sh)
		img.set_pixel(cx - 5, my + 1, lip_dk)
		img.set_pixel(cx - 4, my + 1, lip_sh)
		img.set_pixel(cx + 3, my + 1, lip_sh)
		img.set_pixel(cx + 4, my + 1, lip_dk)
		for x in range(cx - 2, cx + 2):
			img.set_pixel(x, my + 1, lip_hi)
			img.set_pixel(x, my + 2, lip_sh)
	elif style == 2:
		for x in range(cx - 3, cx + 3):
			img.set_pixel(x, my - 1, lip_sh)
			img.set_pixel(x, my, ink)
			img.set_pixel(x, my + 1, ink if (x >= cx - 2 and x <= cx + 1) else lip_dk)
			img.set_pixel(x, my + 2, lip_sh)
		img.set_pixel(cx - 4, my, lip_dk)
		img.set_pixel(cx - 4, my + 1, lip_sh)
		img.set_pixel(cx + 3, my, lip_dk)
		img.set_pixel(cx + 3, my + 1, lip_sh)
	else:
		for x in range(cx - 3, cx + 3):
			img.set_pixel(x, my - 1, lip_sh)
			img.set_pixel(x, my, ink)
		for x in range(cx - 2, cx + 2):
			img.set_pixel(x, my + 1, ink)
			img.set_pixel(x, my + 2, lip_sh)
		img.set_pixel(cx - 4, my + 1, lip_dk)
		img.set_pixel(cx - 3, my + 1, lip_dk)
		img.set_pixel(cx + 2, my + 1, lip_dk)
		img.set_pixel(cx + 3, my + 1, lip_dk)


func _build_16bit_corrupted_radio(normal_radio: Image) -> Image:
	var out := normal_radio.duplicate() as Image
	_apply_cadaverous_palette(out, "vhs_radio")
	var ink := Color("#040407")
	for y in range(35, 52):
		for x in range(27, 65):
			var scan := (y % 2 == 0)
			out.set_pixel(x, y, Color("#101218") if scan else Color("#181B24"))
	for y in range(38, 49):
		for x in range(34, 57):
			var dx := (float(x) - 45.5) / 10.0
			var dy := (float(y) - 43.0) / 4.2
			var d := dx * dx + dy * dy
			if d <= 1.0:
				if d > 0.78:
					out.set_pixel(x, y, ink)
				else:
					var pd := pow((float(x) - 45.5) / 3.8, 2.0) + pow((float(y) - 43.0) / 3.5, 2.0)
					if pd <= 0.25:
						out.set_pixel(x, y, Color("#D4D8E2"))
					elif pd <= 1.0:
						out.set_pixel(x, y, ink)
					else:
						out.set_pixel(x, y, Color("#8E93A0") if dy > -0.3 else Color("#5E626E"))
	var crack := [
		Vector2i(28, 36), Vector2i(31, 38), Vector2i(35, 40), Vector2i(39, 43),
		Vector2i(52, 44), Vector2i(57, 47), Vector2i(61, 50), Vector2i(56, 39), Vector2i(60, 36)
	]
	for p in crack:
		out.set_pixel(p.x, p.y, ink)
		out.set_pixel(p.x + 1, p.y, Color("#4A4E5C"))
	return out


func _apply_cadaverous_palette(img: Image, id: String) -> void:
	var ink := Color("#050508")
	for y in range(96):
		for x in range(96):
			var c := img.get_pixel(x, y)
			if c.a < 0.5:
				continue
			var lum := c.r * 0.299 + c.g * 0.587 + c.b * 0.114
			if lum < 0.07:
				img.set_pixel(x, y, ink)
				continue

			if _is_skin_color(c, x, y, id):
				var cad: Color
				if lum > 0.60:
					cad = Color("#CFD3DA")
				elif lum > 0.48:
					cad = Color("#AEB2BC")
				elif lum > 0.37:
					cad = Color("#878B96")
				elif lum > 0.25:
					cad = Color("#5E616C")
				else:
					cad = Color("#383A44")
				img.set_pixel(x, y, cad)
			else:
				var gray := Color(lum * 0.92, lum * 0.94, minf(1.0, lum * 0.99), 1.0)
				var bleak := c.lerp(gray, 0.74).darkened(0.22)
				bleak.a = 1.0
				img.set_pixel(x, y, bleak)


func _paint_dark_veins(img: Image, chains: Array) -> void:
	var v_main := Color("#23252E")
	var v_sub := Color("#434652")
	for chain in chains:
		var pts: Array = chain
		for i in range(pts.size() - 1):
			var p0: Vector2i = pts[i]
			var p1: Vector2i = pts[i + 1]
			var steps := maxi(absi(p1.x - p0.x), absi(p1.y - p0.y))
			for s in range(steps + 1):
				var t := float(s) / float(maxi(1, steps))
				var px := int(round(lerpf(float(p0.x), float(p1.x), t)))
				var py := int(round(lerpf(float(p0.y), float(p1.y), t)))
				if px >= 22 and px <= 73 and py >= 20 and py <= 83:
					var cur := img.get_pixel(px, py)
					var lum := cur.r * 0.299 + cur.g * 0.587 + cur.b * 0.114
					if cur.a > 0.5 and lum > 0.30 and absf(cur.r - cur.b) < 0.12:
						img.set_pixel(px, py, v_main if i == 0 else v_sub)


func _keep_largest_alpha_island(img: Image, seed_x: int, seed_y: int) -> void:
	var w := img.get_width()
	var h := img.get_height()
	var visited := PackedByteArray()
	visited.resize(w * h)
	var queue: Array[Vector2i] = [Vector2i(seed_x, seed_y)]
	visited[seed_y * w + seed_x] = 1
	var head := 0
	while head < queue.size():
		var cur := queue[head]
		head += 1
		for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 1), Vector2i(-1, 1), Vector2i(1, -1), Vector2i(-1, -1)]:
			var nx: int = cur.x + d.x
			var ny: int = cur.y + d.y
			if nx >= 0 and nx < w and ny >= 0 and ny < h:
				var idx: int = ny * w + nx
				if visited[idx] == 0 and img.get_pixel(nx, ny).a > 0.5:
					visited[idx] = 1
					queue.append(Vector2i(nx, ny))
	for y in range(h):
		for x in range(w):
			if img.get_pixel(x, y).a > 0.0 and visited[y * w + x] == 0:
				img.set_pixel(x, y, Color(0, 0, 0, 0))


# ==============================================================================
# 5. PREVIEW CONTACT SHEETS FOR VISUAL AUDIT
# ==============================================================================

func _save_preview_huwag(casual: Dictionary, bfp: Dictionary, out_path: String) -> void:
	var exprs := ["neutral", "worried", "tired", "surprised", "angry", "scared", "uneasy_smile", "unfiltered", "distorted"]
	var list: Array[Image] = []
	for e: String in exprs:
		list.append(casual[e])
	for e: String in exprs:
		list.append(bfp[e])
	_render_pair_grid(list, 6, out_path)


func _save_preview_npcs(map: Dictionary, out_path: String) -> void:
	var order := [
		"cap_reyes", "bombeiro_ato", "bombeiro_santos", "enfermeira_maria", "aling_nena",
		"kuya_ben", "feirante", "mang_carding", "luningning", "lola_rosa",
		"toby", "vulto_bosque", "santelmo", "criatura_lagoa", "vhs_radio"
	]
	var list: Array[Image] = []
	for k: String in order:
		list.append(map[k])
	_render_pair_grid(list, 5, out_path)


func _save_preview_5_rebuilt_3x(norm: Dictionary, dist: Dictionary, out_path: String) -> void:
	var keys := ["luningning", "lola_rosa", "toby", "vulto_bosque", "vhs_radio"]
	var scale := 3
	var cw := 96 * scale + 8
	var ch := 96 * scale + 8
	var sheet := Image.create(5 * cw, 2 * ch, false, Image.FORMAT_RGBA8)
	sheet.fill(Color("#121318"))
	for i in range(keys.size()):
		var k: String = keys[i]
		for row: int in [0, 1]:
			var img: Image = norm[k] if row == 0 else dist[k]
			var ox: int = i * cw + 4
			var oy: int = row * ch + 4
			for y in range(96):
				for x in range(96):
					var c := img.get_pixel(x, y)
					var dc := c if c.a > 0.5 else Color(0, 0, 0, 1)
					for dy in range(scale):
						for dx in range(scale):
							sheet.set_pixel(ox + x * scale + dx, oy + y * scale + dy, dc)
	sheet.save_png(out_path)


func _render_pair_grid(list: Array[Image], cols: int, out_path: String) -> void:
	var rows := int(ceil(float(list.size()) / float(cols)))
	var cw := 204
	var ch := 106
	var sheet := Image.create(cols * cw, rows * ch, false, Image.FORMAT_RGBA8)
	sheet.fill(Color("#181A20"))
	for i in range(list.size()):
		var img := list[i]
		var ox := (i % cols) * cw + 4
		var oy := int(i / cols) * ch + 5
		for y in range(96):
			for x in range(96):
				var chk := ((int(x / 8) + int(y / 8)) % 2) == 0
				var bg := Color("#C832C8") if chk else Color("#641964")
				var c := img.get_pixel(x, y)
				sheet.set_pixel(ox + x, oy + y, c if c.a > 0.5 else bg)
				sheet.set_pixel(ox + 100 + x, oy + y, c if c.a > 0.5 else Color(0, 0, 0, 1))
		for bx in range(98):
			sheet.set_pixel(ox + 99 + bx, oy - 1, Color.WHITE)
			sheet.set_pixel(ox + 99 + bx, oy + 96, Color.WHITE)
		for by in range(98):
			sheet.set_pixel(ox + 99, oy - 1 + by, Color.WHITE)
			sheet.set_pixel(ox + 196, oy - 1 + by, Color.WHITE)
	sheet.save_png(out_path)
