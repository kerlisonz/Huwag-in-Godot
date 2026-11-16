@tool
extends SceneTree

# Gerador mestre de spritesheets 8-direcionais (672x384, grade 14x8 de 48x48 px)
# e retratos CRT 96x96 para os 14 personagens/entidades da Fase 3 de Huwag.
#
# Estilo-mestre calibrado diretamente sobre assets/characters/sprites/npc_enfermeira_maria_sheet.png:
# - Contorno escuro suave (#0E0D12), cel-shading limpo em blocos sem AA nem gradientes
# - Cabeca oval arredondada (~14x13 px) com queixo afinado, testa visivel e mechas curvas
# - Ombros arredondados (14-18 px de largura com bracos angulados), pernas afastadas na caminhada
# - Direcoes 3/4 diagonais (down_left, down_right, up_left, up_right) com rotacao real
# - Poses de interacao expressivas (cols 6..9) vs. ataque com arco de corte (cols 6..9 combate)
#
# Uso headless:
#   Godot.exe --headless --path <repo> --script res://scripts/tools/build_phase3_8dir_sheets.gd

const CELL := 48
const COLS := 14
const DIRS := 8
const SHEET_W := CELL * COLS   # 672
const SHEET_H := CELL * DIRS   # 384
const COMPAT_W := CELL * 10    # 480
const COMPAT_H := CELL * 4     # 192

const INK := Color("#0E0D12")
const EYE_DARK := Color("#170D08")
const EYE_WHITE := Color("#F4DEC4")
const SLASH_LIGHT := Color("#FFF3D1")
const SLASH_MID := Color("#ED7B3E")
const SLASH_DARK := Color("#A82A26")

enum Dir {
	DOWN = 0,
	LEFT = 1,
	RIGHT = 2,
	UP = 3,
	DOWN_LEFT = 4,
	DOWN_RIGHT = 5,
	UP_LEFT = 6,
	UP_RIGHT = 7,
}

enum Role {
	INTERACT_RUN = 0,
	COMBAT = 1,
	DISTORTED_PEACE = 2,
}


func _init() -> void:
	print("=== Iniciando geracao refinada de spritesheets 8-dir (672x384) ===")
	var dirs_to_make: Array[String] = [
		"res://assets/characters/huwag",
		"res://assets/characters/cap_reyes",
		"res://assets/characters/enfermeira_maria",
		"res://assets/characters/bombeiro_ato",
		"res://assets/characters/bombeiro_santos",
		"res://assets/characters/aling_nena",
		"res://assets/characters/kuya_ben",
		"res://assets/characters/mang_tomas",
		"res://assets/characters/mang_carding",
		"res://assets/characters/toby",
		"res://assets/characters/senhora_luningning",
		"res://assets/characters/lola_rosa",
		"res://assets/characters/vulto_bosque",
		"res://assets/characters/santelmo",
		"res://assets/characters/aquatic_creature",
		"res://assets/characters/sprites",
		"res://assets/characters/portraits",
	]
	for d in dirs_to_make:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(d))

	var ref_maria := _load_rgba("res://assets/characters/sprites/npc_enfermeira_maria_sheet.png")
	var ref_santos := _load_rgba("res://assets/characters/sprites/npc_bombeiro_santos_sheet.png")
	var ref_reyes := _load_rgba("res://assets/characters/sprites/npc_cap_reyes_bfp_sheet.png")
	var ref_ato := _load_rgba("res://assets/characters/sprites/npc_bombeiro_ato_sheet.png")
	var ref_portrait_maria := _load_rgba("res://assets/characters/portraits/fnaf_enfermeira_maria.png")
	var ref_portrait_reyes := _load_rgba("res://assets/characters/portraits/fnaf_cap_reyes.png")

	var specs := _build_specs()

	# 1. Huwag (casual + BFP, escala 30 px alinhada a Maria)
	var huwag_casual := _compose_human_sheet(specs["huwag_casual"], Role.COMBAT, false, null, 0)
	_save_sheet_and_compat(huwag_casual, "res://assets/characters/huwag/casual_sheet.png", "res://assets/characters/sprites/huwag_casual_sheet.png")
	var huwag_bfp := _compose_human_sheet(specs["huwag_bfp"], Role.COMBAT, false, null, 0)
	_save_sheet_and_compat(huwag_bfp, "res://assets/characters/huwag/bfp_sheet.png", "res://assets/characters/sprites/huwag_bfp_sheet.png")

	# 2. Cap. Reyes (preserva cols 0..5 sem bastao; novos cols 6..13 e 4 diagonais)
	var reyes_norm := _compose_human_sheet(specs["cap_reyes"], Role.INTERACT_RUN, false, ref_reyes, 6)
	_save_sheet_and_compat(reyes_norm, "res://assets/characters/cap_reyes/normal_sheet.png", "res://assets/characters/sprites/npc_cap_reyes_bfp_sheet.png")
	var reyes_dist := _compose_human_sheet(specs["cap_reyes"], Role.DISTORTED_PEACE, true, null, 0)
	_save_sheet_and_compat(reyes_dist, "res://assets/characters/cap_reyes/distorted_sheet.png", "res://assets/characters/sprites/distorted_cap_reyes_sheet.png")
	_export_portrait(specs["cap_reyes"], false, ref_portrait_reyes, "res://assets/characters/cap_reyes/portrait.png", "res://assets/characters/portraits/fnaf_cap_reyes.png")
	_export_portrait(specs["cap_reyes"], true, null, "res://assets/characters/cap_reyes/distorted_portrait.png", "res://assets/characters/portraits/fnaf_distorted_cap_reyes.png")

	# 3. Enfermeira Maria (modelo-base: preserva 4x10 verbatim + diagonais e corrida coesas)
	var maria_norm := _compose_human_sheet(specs["enfermeira_maria"], Role.INTERACT_RUN, false, ref_maria, 10)
	_save_sheet_and_compat(maria_norm, "res://assets/characters/enfermeira_maria/normal_sheet.png", "")
	var maria_dist := _compose_human_sheet(specs["enfermeira_maria"], Role.COMBAT, true, null, 0)
	_save_sheet_and_compat(maria_dist, "res://assets/characters/enfermeira_maria/distorted_sheet.png", "res://assets/characters/sprites/distorted_enfermeira_maria_sheet.png")
	_export_portrait(specs["enfermeira_maria"], false, ref_portrait_maria, "res://assets/characters/enfermeira_maria/portrait.png", "")
	_export_portrait(specs["enfermeira_maria"], true, null, "res://assets/characters/enfermeira_maria/distorted_portrait.png", "res://assets/characters/portraits/fnaf_distorted_enfermeira_maria.png")

	# 4. Bombeiro Ato (pacifico sem machado; preserva cols 0..5 + manometro; distorcido c/ machado)
	var ato_norm := _compose_human_sheet(specs["bombeiro_ato"], Role.INTERACT_RUN, false, ref_ato, 6)
	_save_sheet_and_compat(ato_norm, "res://assets/characters/bombeiro_ato/normal_sheet.png", "res://assets/characters/sprites/npc_bombeiro_ato_sheet.png")
	var ato_dist := _compose_human_sheet(specs["bombeiro_ato"], Role.COMBAT, true, null, 0)
	if ref_ato != null:
		_overlay_soot_attack_from_ref(ato_dist, ref_ato)
	_save_sheet_and_compat(ato_dist, "res://assets/characters/bombeiro_ato/distorted_sheet.png", "res://assets/characters/sprites/distorted_bombeiro_sheet.png")
	_export_portrait(specs["bombeiro_ato"], false, null, "res://assets/characters/bombeiro_ato/portrait.png", "res://assets/characters/portraits/fnaf_bombeiro_ato.png")
	_export_portrait(specs["bombeiro_ato"], true, null, "res://assets/characters/bombeiro_ato/distorted_portrait.png", "res://assets/characters/portraits/fnaf_distorted_bombeiro_ato.png")

	# 5. Bombeiro Santos
	var santos_norm := _compose_human_sheet(specs["bombeiro_santos"], Role.INTERACT_RUN, false, ref_santos, 10)
	_save_sheet_and_compat(santos_norm, "res://assets/characters/bombeiro_santos/normal_sheet.png", "")
	var santos_dist := _compose_human_sheet(specs["bombeiro_santos"], Role.COMBAT, true, null, 0)
	_save_sheet_and_compat(santos_dist, "res://assets/characters/bombeiro_santos/distorted_sheet.png", "res://assets/characters/sprites/distorted_bombeiro_santos_sheet.png")
	_export_portrait(specs["bombeiro_santos"], false, null, "res://assets/characters/bombeiro_santos/portrait.png", "res://assets/characters/portraits/fnaf_bombeiro_santos.png")
	_export_portrait(specs["bombeiro_santos"], true, null, "res://assets/characters/bombeiro_santos/distorted_portrait.png", "res://assets/characters/portraits/fnaf_distorted_bombeiro_santos.png")

	# 6..12 Moradores
	var villagers := [
		["aling_nena", "npc_aling_nena_sheet.png", "distorted_aling_nena_sheet.png", "fnaf_aling_nena.png", Role.COMBAT],
		["kuya_ben", "npc_kuya_ben_sheet.png", "distorted_kuya_ben_sheet.png", "fnaf_kuya_ben.png", Role.COMBAT],
		["mang_tomas", "npc_feirante_sheet.png", "distorted_feirante_sheet.png", "fnaf_feirante.png", Role.COMBAT],
		["mang_carding", "npc_mang_carding_sheet.png", "distorted_mang_carding_sheet.png", "fnaf_mang_carding.png", Role.COMBAT],
		["toby", "npc_toby_sheet.png", "distorted_toby_sheet.png", "fnaf_toby.png", Role.DISTORTED_PEACE],
		["senhora_luningning", "npc_luningning_sheet.png", "distorted_luningning_sheet.png", "fnaf_luningning.png", Role.COMBAT],
		["lola_rosa", "npc_lola_rosa_sheet.png", "distorted_lola_rosa_sheet.png", "fnaf_lola_rosa.png", Role.COMBAT],
	]
	for entry in villagers:
		var cid: String = entry[0]
		var norm_compat: String = "res://assets/characters/sprites/" + entry[1]
		var dist_compat: String = "res://assets/characters/sprites/" + entry[2]
		var port_name: String = entry[3]
		var dist_role: int = entry[4]
		var spec: Dictionary = specs[cid]

		var s_norm := _compose_human_sheet(spec, Role.INTERACT_RUN, false, null, 0)
		_save_sheet_and_compat(s_norm, "res://assets/characters/%s/normal_sheet.png" % cid, norm_compat)

		var s_dist := _compose_human_sheet(spec, dist_role, true, null, 0)
		_save_sheet_and_compat(s_dist, "res://assets/characters/%s/distorted_sheet.png" % cid, dist_compat)

		_export_portrait(spec, false, null, "res://assets/characters/%s/portrait.png" % cid, "res://assets/characters/portraits/" + port_name)
		_export_portrait(spec, true, null, "res://assets/characters/%s/distorted_portrait.png" % cid, "res://assets/characters/portraits/fnaf_distorted_" + port_name.trim_prefix("fnaf_"))

	# 13. Vulto Calcinado do Bosque
	var vulto_sheet := _compose_human_sheet(specs["vulto_bosque"], Role.COMBAT, true, null, 0)
	_save_sheet_and_compat(vulto_sheet, "res://assets/characters/vulto_bosque/hostile_sheet.png", "res://assets/characters/sprites/npc_vulto_bosque_sheet.png")
	_export_portrait(specs["vulto_bosque"], true, null, "res://assets/characters/vulto_bosque/portrait.png", "res://assets/characters/portraits/fnaf_vulto_bosque.png")

	# 14A & 14B. Santelmos e Guardia da Lagoa
	_compose_santelmo_sheet().save_png(ProjectSettings.globalize_path("res://assets/characters/santelmo/combat_sheet.png"))
	_compose_guardian_sheet().save_png(ProjectSettings.globalize_path("res://assets/characters/aquatic_creature/guardian_sheet.png"))
	_export_guardian_portrait("res://assets/characters/aquatic_creature/portrait.png", "res://assets/characters/portraits/fnaf_criatura_lagoa.png")

	print("=== Concluido refinamento completo ===")
	quit()


# ---------------------------------------------------------------------------
# Especificacoes de Cores e Acessorios (calibradas as referencias)
# ---------------------------------------------------------------------------

func _build_specs() -> Dictionary:
	return {
		"huwag_casual": {
			"id": "huwag_casual",
			"height_mode": "adult",
			"skin": [Color("#C28A5D"), Color("#A66F44"), Color("#7E4E2D")],
			"hair_style": "huwag_bleached",
			"hair_col": [Color("#EFE6AD"), Color("#D2C57E"), Color("#18161E")],
			"hat": "none",
			"torso": [Color("#383B46"), Color("#282A33"), Color("#191B22")],
			"inner_shirt": Color("#14151A"),
			"collar_type": "jacket_v",
			"stripe": "none",
			"apron": "none",
			"pants": [Color("#5E523F"), Color("#42392B")],
			"boots": Color("#E2DFD7"),
			"boot_dark": Color("#23252E"),
			"prop_peace": "flashlight",
			"weapon": "axe",
			"portrait_bg": Color("#111722"),
			"portrait_border": Color("#EBE2A6"),
		},
		"huwag_bfp": {
			"id": "huwag_bfp",
			"height_mode": "adult_broad",
			"skin": [Color("#C28A5D"), Color("#A66F44"), Color("#7E4E2D")],
			"hair_style": "huwag_bleached",
			"hair_col": [Color("#EFE6AD"), Color("#D2C57E"), Color("#18161E")],
			"hat": "none",
			"torso": [Color("#303C59"), Color("#222B42"), Color("#151B2B")],
			"inner_shirt": Color("#1B2130"),
			"collar_type": "bfp_collar",
			"stripe": "bfp_huwag",
			"apron": "none",
			"pants": [Color("#242D42"), Color("#181E2E")],
			"boots": Color("#16171E"),
			"boot_dark": Color("#2A2C38"),
			"prop_peace": "flashlight",
			"weapon": "axe",
			"portrait_bg": Color("#101624"),
			"portrait_border": Color("#F5CB5C"),
		},
		"cap_reyes": {
			"id": "cap_reyes",
			"height_mode": "adult_broad",
			"skin": [Color("#B87E52"), Color("#99623B"), Color("#734527")],
			"hair_style": "short_grey_temple",
			"hair_col": [Color("#7B8190"), Color("#565B68"), Color("#22242C")],
			"mustache": true,
			"hat": "cap_bfp",
			"hat_col": [Color("#363E4F"), Color("#232936"), Color("#E6BE52")],
			"torso": [Color("#313747"), Color("#222733"), Color("#171A24")],
			"inner_shirt": Color("#E3D8BA"),
			"collar_type": "uniform_tie",
			"stripe": "reyes_chevrons",
			"apron": "none",
			"pants": [Color("#1E232E"), Color("#141720")],
			"boots": Color("#17181E"),
			"boot_dark": Color("#282A33"),
			"prop_peace": "radio_clipboard",
			"weapon": "none",
			"portrait_bg": Color("#101724"),
			"portrait_border": Color("#5C87B8"),
		},
		"enfermeira_maria": {
			"id": "enfermeira_maria",
			"height_mode": "adult",
			"skin": [Color("#C28A5B"), Color("#A66D40"), Color("#7E4D2B")],
			"hair_style": "bun_back",
			"hair_col": [Color("#26242B"), Color("#16151B"), Color("#100F14")],
			"hat": "none",
			"torso": [Color("#5C6678"), Color("#434C5C"), Color("#2E3542")],
			"inner_shirt": Color("#D8DCE6"),
			"collar_type": "v_neck",
			"stripe": "nurse_patch",
			"apron": "pouch_brown",
			"pants": [Color("#222A3D"), Color("#161B29")],
			"boots": Color("#16171E"),
			"boot_dark": Color("#282A36"),
			"prop_peace": "clipboard",
			"weapon": "scalpel_clipboard",
			"portrait_bg": Color("#111722"),
			"portrait_border": Color("#D6545D"),
		},
		"bombeiro_ato": {
			"id": "bombeiro_ato",
			"height_mode": "adult_broad",
			"skin": [Color("#BA8052"), Color("#99623B"), Color("#724629")],
			"hair_style": "short_dark",
			"hair_col": [Color("#222026"), Color("#141318"), Color("#0E0D12")],
			"hat": "helmet_yellow",
			"hat_col": [Color("#BAA848"), Color("#8F7F30"), Color("#E6C65A")], # calib. fiel ao capacete original!
			"torso": [Color("#363842"), Color("#262730"), Color("#181920")],
			"inner_shirt": Color("#22232B"),
			"collar_type": "bfp_collar",
			"stripe": "bfp_orange_yellow",
			"apron": "none",
			"pants": [Color("#23242D"), Color("#16171E")],
			"boots": Color("#181920"),
			"boot_dark": Color("#D98E48"),
			"prop_peace": "nozzle_gauge",
			"weapon": "axe",
			"portrait_bg": Color("#16161C"),
			"portrait_border": Color("#E89B3C"),
		},
		"bombeiro_santos": {
			"id": "bombeiro_santos",
			"height_mode": "adult",
			"skin": [Color("#BE8456"), Color("#A16A3F"), Color("#784A29")],
			"hair_style": "spiky_dark",
			"hair_col": [Color("#2B2830"), Color("#19171E"), Color("#100E14")],
			"hat": "none",
			"torso": [Color("#313B52"), Color("#232B3D"), Color("#161B29")],
			"inner_shirt": Color("#1E2330"),
			"collar_type": "bfp_collar",
			"stripe": "bfp_thin_orange",
			"apron": "radio_shoulder",
			"pants": [Color("#22293D"), Color("#161B29")],
			"boots": Color("#15161C"),
			"boot_dark": Color("#282A36"),
			"prop_peace": "radio_wave",
			"weapon": "heavy_tackle",
			"portrait_bg": Color("#121722"),
			"portrait_border": Color("#4C78B8"),
		},
		"aling_nena": {
			"id": "aling_nena",
			"height_mode": "adult",
			"skin": [Color("#BD8356"), Color("#9F673E"), Color("#76492B")],
			"hair_style": "bun_red_clip",
			"hair_col": [Color("#43424C"), Color("#27262E"), Color("#E03E4A")],
			"hat": "none",
			"torso": [Color("#9E3D50"), Color("#752939"), Color("#521B27")],
			"inner_shirt": Color("#F0D9DE"),
			"collar_type": "round",
			"stripe": "none",
			"apron": "apron_blue",
			"pants": [Color("#2B3040"), Color("#1D212E")],
			"boots": Color("#3B2B24"),
			"boot_dark": Color("#241914"),
			"prop_peace": "bag_fan",
			"weapon": "claws_lunge",
			"portrait_bg": Color("#1A1318"),
			"portrait_border": Color("#E07A5F"),
		},
		"kuya_ben": {
			"id": "kuya_ben",
			"height_mode": "adult_broad",
			"skin": [Color("#B87D50"), Color("#986037"), Color("#704425")],
			"hair_style": "short_dark",
			"hair_col": [Color("#26232A"), Color("#17151B"), Color("#100F13")],
			"mustache": true,
			"hat": "cap_trucker",
			"hat_col": [Color("#59789C"), Color("#3C5573"), Color("#25374D")],
			"torso": [Color("#3E6596"), Color("#2E4D75"), Color("#1E3554")],
			"inner_shirt": Color("#DEDBD2"),
			"collar_type": "towel_neck",
			"stripe": "oil_smudge",
			"apron": "none",
			"pants": [Color("#283B57"), Color("#1B283D")],
			"boots": Color("#26201D"),
			"boot_dark": Color("#161210"),
			"prop_peace": "wrench_rag",
			"weapon": "wrench_heavy",
			"portrait_bg": Color("#101720"),
			"portrait_border": Color("#7A9E9F"),
		},
		"mang_tomas": {
			"id": "mang_tomas",
			"height_mode": "adult_broad",
			"skin": [Color("#B4794C"), Color("#945E36"), Color("#6C4224")],
			"hair_style": "short_dark",
			"hair_col": [Color("#2D2A30"), Color("#1B191E"), Color("#100E12")],
			"hat": "salakot",
			"hat_col": [Color("#DDB262"), Color("#B3863D"), Color("#785522")],
			"torso": [Color("#D6C7A9"), Color("#B5A585"), Color("#8C7D62")],
			"inner_shirt": Color("#B0A082"),
			"collar_type": "round",
			"stripe": "none",
			"apron": "apron_olive",
			"pants": [Color("#2E2B2A"), Color("#1E1B1A")],
			"boots": Color("#2B221D"),
			"boot_dark": Color("#18120F"),
			"prop_peace": "crate_salakot",
			"weapon": "cleaver",
			"portrait_bg": Color("#191511"),
			"portrait_border": Color("#E09F3E"),
		},
		"mang_carding": {
			"id": "mang_carding",
			"height_mode": "adult_broad",
			"skin": [Color("#AE7246"), Color("#8E5831"), Color("#653C1F")],
			"hair_style": "short_grey_temple",
			"hair_col": [Color("#6E727E"), Color("#474A54"), Color("#2B2D33")],
			"mustache": true,
			"hat": "bandana_teal",
			"hat_col": [Color("#48A8B8"), Color("#2E7D8A"), Color("#1F545E")],
			"torso": [Color("#487A8A"), Color("#335B69"), Color("#223F4A")],
			"inner_shirt": Color("#C2BBA8"),
			"collar_type": "rope_shoulder",
			"stripe": "none",
			"apron": "none",
			"pants": [Color("#544537"), Color("#3A2F24")],
			"boots": Color("#8E5831"),
			"boot_dark": Color("#3A291D"),
			"prop_peace": "lantern_rope",
			"weapon": "oar_hook",
			"portrait_bg": Color("#10191E"),
			"portrait_border": Color("#4895EF"),
		},
		"toby": {
			"id": "toby",
			"height_mode": "child",
			"skin": [Color("#C68E5F"), Color("#AA7346"), Color("#80522E")],
			"hair_style": "messy_kid",
			"hair_col": [Color("#2B252A"), Color("#191519"), Color("#100D10")],
			"hat": "cap_backwards_red",
			"hat_col": [Color("#DE444A"), Color("#AB2D32"), Color("#751C20")],
			"torso": [Color("#EDBF4C"), Color("#CC9B2E"), Color("#3A69A6")],
			"inner_shirt": Color("#3A69A6"),
			"collar_type": "kid_stripe",
			"stripe": "backpack_straps",
			"apron": "backpack",
			"pants": [Color("#426494"), Color("#2E486E")],
			"boots": Color("#E4E0D6"),
			"boot_dark": Color("#3B5580"),
			"prop_peace": "point_kid",
			"weapon": "count_fingers",
			"portrait_bg": Color("#151A14"),
			"portrait_border": Color("#88D498"),
		},
		"senhora_luningning": {
			"id": "senhora_luningning",
			"height_mode": "elder",
			"skin": [Color("#C0875A"), Color("#A16B42"), Color("#784C2D")],
			"hair_style": "bun_silver",
			"hair_col": [Color("#E8EAF2"), Color("#BEC3D4"), Color("#8B90A3")],
			"hat": "none",
			"torso": [Color("#68557A"), Color("#4D3E5C"), Color("#342840")],
			"inner_shirt": Color("#9968B0"),
			"collar_type": "shawl_lilac",
			"stripe": "none",
			"apron": "skirt_long",
			"pants": [Color("#493A59"), Color("#32273E")],
			"boots": Color("#29242E"),
			"boot_dark": Color("#18151C"),
			"prop_peace": "lantern_cat",
			"weapon": "spectral_lantern",
			"portrait_bg": Color("#17121E"),
			"portrait_border": Color("#9A84B8"),
		},
		"lola_rosa": {
			"id": "lola_rosa",
			"height_mode": "elder",
			"skin": [Color("#BE8559"), Color("#9F6941"), Color("#764B2C")],
			"hair_style": "braid_grey",
			"hair_col": [Color("#BAC0CC"), Color("#8C91A1"), Color("#636775")],
			"hat": "headscarf_floral",
			"hat_col": [Color("#F2EFE6"), Color("#CEC9BD"), Color("#DB6570")],
			"torso": [Color("#E6DDD0"), Color("#C4B9A2"), Color("#998E79")],
			"inner_shirt": Color("#486948"),
			"collar_type": "round",
			"stripe": "none",
			"apron": "skirt_floral",
			"pants": [Color("#456645"), Color("#2E472E")],
			"boots": Color("#3B2E27"),
			"boot_dark": Color("#241B17"),
			"prop_peace": "basket_herbs",
			"weapon": "ash_herbs",
			"portrait_bg": Color("#171813"),
			"portrait_border": Color("#9EC47A"),
		},
		"vulto_bosque": {
			"id": "vulto_bosque",
			"height_mode": "adult_broad",
			"skin": [Color("#322C36"), Color("#221E26"), Color("#141117")],
			"hair_style": "short_dark",
			"hair_col": [Color("#241F26"), Color("#171319"), Color("#0E0D12")],
			"hat": "helmet_charred",
			"hat_col": [Color("#423B47"), Color("#29242E"), Color("#FF5638")],
			"torso": [Color("#332D38"), Color("#221E26"), Color("#151218")],
			"inner_shirt": Color("#D93640"),
			"collar_type": "bfp_collar",
			"stripe": "ember_cracks",
			"apron": "none",
			"pants": [Color("#242029"), Color("#151218")],
			"boots": Color("#151218"),
			"boot_dark": Color("#0E0D12"),
			"prop_peace": "axe",
			"weapon": "charred_axe",
			"portrait_bg": Color("#1B0D10"),
			"portrait_border": Color("#E84A43"),
		},
	}


# ---------------------------------------------------------------------------
# Compositor de Folha 14x8 (Preservacao Seletiva + Sintese Coesa)
# ---------------------------------------------------------------------------

func _compose_human_sheet(
	spec: Dictionary, role: int, is_distorted: bool, ref_img: Image, ref_cols_to_keep: int
) -> Image:
	var sheet := Image.create(SHEET_W, SHEET_H, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0, 0, 0, 0))

	for dir_idx in range(DIRS):
		for col in range(COLS):
			if ref_img != null and not is_distorted and dir_idx < 4 and col < ref_cols_to_keep:
				sheet.blit_rect(ref_img, Rect2i(col * CELL, dir_idx * CELL, CELL, CELL), Vector2i(col * CELL, dir_idx * CELL))
				continue
			var cell := _render_human_cell(spec, dir_idx, col, role, is_distorted)
			sheet.blit_rect(cell, Rect2i(0, 0, CELL, CELL), Vector2i(col * CELL, dir_idx * CELL))

	return sheet


func _overlay_soot_attack_from_ref(dst: Image, ref_ato: Image) -> void:
	for row in range(4):
		for col in range(10):
			var ox := col * CELL
			var oy := row * CELL
			for y in range(CELL):
				for x in range(CELL):
					var c := ref_ato.get_pixel(ox + x, oy + y)
					if c.a < 0.05:
						continue
					var lum := c.get_luminance()
					if lum < 0.08:
						dst.set_pixel(ox + x, oy + y, INK)
						continue
					var nc := c
					if c.r > 0.45 and c.g > 0.35 and c.b < 0.35 and y < 23:
						nc = Color(c.r * 0.48 + 0.06, c.g * 0.38 + 0.03, c.b * 0.28 + 0.03, 1.0)
					elif c.r > 0.62 and c.g > 0.25 and c.b < 0.25:
						nc = Color("#D64336")
					elif c.r > c.b * 1.25 and y < 27:
						nc = Color(c.r * 0.62 + 0.05, c.g * 0.54 + 0.05, c.b * 0.58 + 0.06, 1.0)
					else:
						var g := lum * 0.52
						nc = Color(g * 0.96 + 0.03, g * 0.85 + 0.02, g * 0.98 + 0.04, 1.0)
					dst.set_pixel(ox + x, oy + y, nc)
			if row != Dir.UP:
				var ex := 21 if row == Dir.DOWN else (19 if row == Dir.LEFT else 28)
				var ey := 20 if col < 6 else 21
				if dst.get_pixel(ox + ex, oy + ey).get_luminance() < 0.22:
					dst.set_pixel(ox + ex, oy + ey, Color("#FF4C43"))
					if row == Dir.DOWN:
						dst.set_pixel(ox + 26, oy + ey, Color("#FF4C43"))


func _save_sheet_and_compat(sheet: Image, full_path: String, compat_path: String) -> void:
	sheet.save_png(ProjectSettings.globalize_path(full_path))
	if not compat_path.is_empty():
		var compat := Image.create(COMPAT_W, COMPAT_H, false, Image.FORMAT_RGBA8)
		compat.blit_rect(sheet, Rect2i(0, 0, COMPAT_W, COMPAT_H), Vector2i(0, 0))
		compat.save_png(ProjectSettings.globalize_path(compat_path))


# ---------------------------------------------------------------------------
# Renderizador Modular Redondo (Silhueta Fiel a Enfermeira Maria)
# ---------------------------------------------------------------------------

func _render_human_cell(spec: Dictionary, dir_idx: int, col: int, role: int, is_distorted: bool) -> Image:
	if dir_idx == Dir.RIGHT:
		return _flip_img_h(_render_human_cell(spec, Dir.LEFT, col, role, is_distorted))
	if dir_idx == Dir.DOWN_RIGHT:
		return _flip_img_h(_render_human_cell(spec, Dir.DOWN_LEFT, col, role, is_distorted))
	if dir_idx == Dir.UP_RIGHT:
		return _flip_img_h(_render_human_cell(spec, Dir.UP_LEFT, col, role, is_distorted))

	var view := "down"
	match dir_idx:
		Dir.LEFT: view = "left"
		Dir.UP: view = "up"
		Dir.DOWN_LEFT: view = "down_left"
		Dir.UP_LEFT: view = "up_left"

	var canvas := _new_cell()
	var pal := _resolve_palette(spec, is_distorted)
	var hmode: String = spec.get("height_mode", "adult")
	var is_child := (hmode == "child")
	var is_elder := (hmode == "elder")
	var is_broad := (hmode == "adult_broad")

	var pose := _decode_pose(col, role, is_distorted)
	if pose["kind"] == "defeat" and pose["sub"] == 1:
		return _render_fallen_pose(pal, spec)

	var foot_y := 42
	var head_cy := 19 if not is_child else 22
	if is_elder:
		head_cy = 20
	var torso_top := head_cy + (7 if not is_child else 6) # pescoco curto
	var waist_y := 34 if not is_child else 35

	var bob_y: int = pose["bob_y"]
	var lean_x: int = pose["lean_x"]
	var body_drop: int = pose["drop_y"]

	head_cy += bob_y + body_drop
	torso_top += bob_y + body_drop
	waist_y += bob_y + body_drop
	var leg_bottom := mini(foot_y + int(body_drop / 2), 43)

	var cx := 24 + lean_x
	if view == "left":
		cx += 0 if pose["kind"] != "attack" else -1
	elif view == "down_left":
		cx -= 1

	var layer_back := _new_cell()
	var layer_legs := _new_cell()
	var layer_torso := _new_cell()
	var layer_head := _new_cell()
	var layer_front_arm := _new_cell()
	var layer_fx := _new_cell()

	_draw_legs(layer_legs, cx, waist_y, leg_bottom, view, pose, pal, spec, is_child)
	_draw_back_arm_and_pack(layer_back, cx, torso_top, waist_y, view, pose, pal, spec, is_child, is_broad)
	_draw_torso(layer_torso, cx, torso_top, waist_y, view, pose, pal, spec, is_child, is_broad)
	_draw_round_head(layer_head, cx, head_cy, view, pose, pal, spec, is_child, is_distorted)
	_draw_front_arm_and_prop(layer_front_arm, layer_fx, cx, torso_top, waist_y, head_cy, view, pose, pal, spec, is_child, is_broad)

	_composite_with_depth_outline(canvas, [
		layer_back,
		layer_legs,
		layer_torso,
		layer_head,
		layer_front_arm,
	], pal["ink"])
	_blit_alpha(canvas, layer_fx)

	if pose["kind"] == "hurt" and pose["sub"] == 0:
		_tint_flash(canvas, Color(1.0, 0.85, 0.85, 1.0), 0.16)

	return canvas


func _decode_pose(col: int, role: int, is_distorted: bool) -> Dictionary:
	var out := {
		"kind": "idle",
		"sub": 0,
		"bob_y": 0,
		"lean_x": 0,
		"drop_y": 0,
		"stride": 0,
		"arm_mode": "rest",
		"hurt": false,
		"head_turn": 0,
	}
	if col == 0:
		out["kind"] = "idle"; out["sub"] = 0
	elif col == 1:
		out["kind"] = "idle"; out["sub"] = 1
		out["bob_y"] = 1 if is_distorted else 0
	elif col >= 2 and col <= 5:
		out["kind"] = "walk"; out["sub"] = col - 2
		match col:
			2: out["stride"] = -1; out["bob_y"] = 0
			3: out["stride"] = 0; out["bob_y"] = -1
			4: out["stride"] = 1; out["bob_y"] = 0
			5: out["stride"] = 0; out["bob_y"] = -1
	elif col >= 6 and col <= 9:
		if role == Role.COMBAT:
			out["kind"] = "attack"; out["sub"] = col - 6
			match col:
				6: out["lean_x"] = 2; out["bob_y"] = -1; out["arm_mode"] = "windup"
				7: out["lean_x"] = -3; out["bob_y"] = 1; out["arm_mode"] = "strike"
				8: out["lean_x"] = -3; out["bob_y"] = 0; out["arm_mode"] = "follow"
				9: out["lean_x"] = -1; out["bob_y"] = 0; out["arm_mode"] = "recover"
		else:
			out["kind"] = "interact"; out["sub"] = col - 6
			match col:
				6: out["arm_mode"] = "raise_item"; out["head_turn"] = 1
				7: out["arm_mode"] = "use_item"; out["bob_y"] = 1
				8: out["arm_mode"] = "point_offer"; out["lean_x"] = -1
				9: out["arm_mode"] = "speak_react"; out["head_turn"] = -1
	elif col == 10 or col == 11:
		if role == Role.COMBAT:
			out["kind"] = "hurt"; out["sub"] = col - 10; out["hurt"] = true
			out["lean_x"] = 2 if col == 10 else 1
			out["bob_y"] = -1 if col == 10 else 0
		else:
			out["kind"] = "run"; out["sub"] = col - 10
			out["stride"] = -1 if col == 10 else 0
			out["bob_y"] = 0 if col == 10 else -1
			out["lean_x"] = -1
	else:
		if role == Role.COMBAT:
			out["kind"] = "defeat"; out["sub"] = col - 12
			out["drop_y"] = 4 if col == 12 else 9
		else:
			if col == 12:
				out["kind"] = "run"; out["sub"] = 2
				out["stride"] = 1; out["lean_x"] = -1
			else:
				out["kind"] = "special"; out["sub"] = 3
				out["arm_mode"] = "special_hold"
	return out


func _resolve_palette(spec: Dictionary, is_distorted: bool) -> Dictionary:
	var p := {
		"skin": spec["skin"].duplicate(),
		"hair": spec["hair_col"].duplicate(),
		"hat": spec.get("hat_col", [Color("#555555"), Color("#333333"), Color("#222222")]).duplicate(),
		"torso": spec["torso"].duplicate(),
		"inner": spec["inner_shirt"],
		"pants": spec["pants"].duplicate(),
		"boots": spec["boots"],
		"boot_dark": spec["boot_dark"],
		"ink": INK,
		"eye": EYE_DARK,
		"eye_hi": EYE_WHITE,
	}
	if not is_distorted:
		return p
	for i in range(p["skin"].size()):
		p["skin"][i] = _desat_shift(p["skin"][i], Color("#6E5D66"), 0.50)
	for i in range(p["torso"].size()):
		p["torso"][i] = _desat_shift(p["torso"][i], Color("#2E1920"), 0.48)
	for i in range(p["pants"].size()):
		p["pants"][i] = _desat_shift(p["pants"][i], Color("#1D1519"), 0.52)
	if spec.get("id", "") != "vulto_bosque":
		for i in range(p["hat"].size()):
			p["hat"][i] = _desat_shift(p["hat"][i], Color("#2A1E22"), 0.52)
	if spec.get("id", "") == "senhora_luningning":
		p["torso"] = [Color("#483742"), Color("#2F232B"), Color("#1E161C")]
		p["inner"] = Color("#872B3A")
	elif spec.get("id", "") == "cap_reyes":
		p["hat"][2] = Color("#B03D45")
	if spec.get("id", "") == "vulto_bosque":
		p["eye"] = Color("#FF4D42"); p["eye_hi"] = Color("#FFC266")
	elif spec.get("id", "") == "toby":
		p["eye"] = Color("#18151C"); p["eye_hi"] = Color("#C2BDCA")
	else:
		p["eye"] = Color("#1A0A0D"); p["eye_hi"] = Color("#FF4840")
	return p


func _desat_shift(c: Color, tint: Color, weight: float) -> Color:
	var g := c.get_luminance() * 0.78
	var d := Color(g, g * 0.94, g * 0.97, 1.0)
	return d.lerp(tint, weight)


func _draw_legs(
	img: Image, cx: int, waist_y: int, leg_bot: int,
	view: String, pose: Dictionary, pal: Dictionary, spec: Dictionary, is_child: bool
) -> void:
	var pc_main: Color = pal["pants"][0]
	var pc_dark: Color = pal["pants"][1]
	var boot_c: Color = pal["boots"]
	var boot_d: Color = pal["boot_dark"]
	var apron: String = spec.get("apron", "none")
	var has_skirt := (apron == "skirt_long" or apron == "skirt_floral")
	var shorts_only := is_child

	var l_step := 0
	var r_step := 0
	var s: int = pose["stride"]
	var run_boost := 1 if pose["kind"] == "run" else 0
	if s == -1:
		l_step = -2 - run_boost
		r_step = 1
	elif s == 1:
		l_step = 1
		r_step = -2 - run_boost

	if view == "down" or view == "up":
		var hip_hw := 4 if not is_child else 3
		if has_skirt:
			# Saia em A-line alargando suavemente (nunca tubo reto!)
			var sk_c := pc_main if apron == "skirt_long" else Color("#436343")
			var sk_d := pc_dark if apron == "skirt_long" else Color("#2C422C")
			for y in range(waist_y, leg_bot - 1):
				var flare := 1 if y > waist_y + 3 else 0
				_hline(img, cx - 5 - flare, cx + 4 + flare, y, sk_c)
				_hline(img, cx + 2, cx + 4 + flare, y, sk_d)
			if apron == "skirt_floral":
				_hline(img, cx - 6, cx + 5, leg_bot - 2, Color("#732D38"))
			_fill_rect(img, cx - 4, leg_bot - 2 + mini(0, l_step), cx - 2, leg_bot + mini(0, l_step), boot_c)
			_fill_rect(img, cx + 1, leg_bot - 2 + mini(0, r_step), cx + 3, leg_bot + mini(0, r_step), boot_c)
			return

		_fill_rect(img, cx - hip_hw, waist_y, cx + hip_hw - 1, waist_y + 1, pc_dark)
		var lx0 := cx - hip_hw - (1 if s == -1 else 0)
		var lx1 := cx - 2
		var rx0 := cx + 1
		var rx1 := cx + hip_hw - 1 + (1 if s == 1 else 0)
		var l_end := clampi(leg_bot + mini(0, l_step), waist_y + 3, 43)
		var r_end := clampi(leg_bot + mini(0, r_step), waist_y + 3, 43)

		var l_pants_end := waist_y + 4 if shorts_only else l_end - 2
		var r_pants_end := waist_y + 4 if shorts_only else r_end - 2
		_fill_rect(img, lx0, waist_y + 1, lx1, l_pants_end, pc_main)
		_fill_rect(img, rx0, waist_y + 1, rx1, r_pants_end, pc_dark if view == "down" else pc_main)

		if shorts_only:
			_fill_rect(img, lx0, l_pants_end + 1, lx1, l_end - 2, pal["skin"][1])
			_fill_rect(img, rx0, r_pants_end + 1, rx1, r_end - 2, pal["skin"][1])

		_fill_rect(img, lx0, l_end - 1, lx1, l_end, boot_c)
		_fill_rect(img, rx0, r_end - 1, rx1, r_end, boot_c)
		if spec.get("boots", Color.BLACK) == Color("#E2DFD7") or shorts_only:
			_hline(img, lx0, lx1, l_end - 1, boot_d)
			_hline(img, rx0, rx1, r_end - 1, boot_d)
	else:
		# Vistas laterais / diagonais com passada ampla e natural (padrao Maria!)
		var step_px := (4 + run_boost) if s != 0 else (3 if pose["kind"] == "attack" else 1)
		if view == "down_left" or view == "up_left":
			step_px = maxi(2, step_px - 1)
		var fx0 := cx - 2 - (step_px if s <= 0 else 1)
		var bx0 := cx + (step_px if s != 0 else 1)

		if has_skirt:
			var sk_c := pc_main if apron == "skirt_long" else Color("#436343")
			var sk_d := pc_dark if apron == "skirt_long" else Color("#2C422C")
			_fill_rect(img, cx - 5, waist_y, cx + 4, leg_bot - 2, sk_c)
			_fill_rect(img, cx + 1, waist_y + 1, cx + 5, leg_bot - 2, sk_d)
			if apron == "skirt_floral":
				_hline(img, cx - 5, cx + 5, leg_bot - 2, Color("#732D38"))
			_fill_rect(img, fx0, leg_bot - 2, fx0 + 3, leg_bot, boot_c)
			_fill_rect(img, bx0, leg_bot - 2, bx0 + 2, leg_bot - 1, boot_c)
			return

		var f_bot := clampi(leg_bot + (mini(0, l_step) if s != 0 else 0), waist_y + 3, 43)
		var b_bot := clampi(leg_bot - 1 + (mini(0, r_step) if s != 0 else 0), waist_y + 3, 42)
		# Perna traseira angulada
		_draw_angled_leg(img, cx + 1, waist_y + 1, bx0, b_bot - 2, 2, pc_dark, shorts_only, pal["skin"][2])
		_fill_rect(img, bx0, b_bot - 1, bx0 + 2, b_bot, boot_c)
		# Perna frontal
		var lw := 2 if is_child else 3
		_draw_angled_leg(img, cx - 1, waist_y + 1, fx0, f_bot - 2, lw, pc_main, shorts_only, pal["skin"][1])
		_fill_rect(img, fx0 - 1, f_bot - 1, fx0 + lw, f_bot, boot_c)
		if spec.get("boots", Color.BLACK) == Color("#E2DFD7") or shorts_only:
			_hline(img, fx0 - 1, fx0 + lw, f_bot - 1, boot_d)


func _draw_angled_leg(img: Image, top_x: int, top_y: int, bot_x: int, bot_y: int, w: int, col: Color, is_shorts: bool, skin_c: Color) -> void:
	var h := maxi(1, bot_y - top_y)
	for y in range(top_y, bot_y + 1):
		var t := float(y - top_y) / float(h)
		var x := int(round(lerpf(float(top_x), float(bot_x), t)))
		var c := col
		if is_shorts and y > top_y + 3:
			c = skin_c
		_hline(img, x, x + w - 1, y, c)


func _draw_back_arm_and_pack(
	img: Image, cx: int, torso_top: int, waist_y: int,
	view: String, pose: Dictionary, pal: Dictionary, spec: Dictionary,
	is_child: bool, is_broad: bool
) -> void:
	var t_hw := 5 if is_broad else (4 if not is_child else 3)
	var sleeve_m: Color = pal["torso"][1]
	var sleeve_d: Color = pal["torso"][2]
	var hand_c: Color = pal["skin"][1]
	var s: int = pose["stride"]
	var swing := s * (2 if pose["kind"] != "run" else 3)

	if view == "down" or view == "up":
		# Bracos angulados suavemente para fora (ombro estreito -> cotovelo 1 px mais largo!)
		var l_dy := swing if pose["kind"] in ["walk", "run"] else 0
		var r_dy := -swing if pose["kind"] in ["walk", "run"] else 0
		# Braco esquerdo
		_fill_rect(img, cx - t_hw - 1, torso_top + 1 + l_dy, cx - t_hw, torso_top + 2 + l_dy, pal["torso"][0])
		_fill_rect(img, cx - t_hw - 2, torso_top + 3 + l_dy, cx - t_hw - 1, waist_y - 1 + l_dy, sleeve_m)
		_fill_rect(img, cx - t_hw - 2, waist_y + l_dy, cx - t_hw - 1, waist_y + 1 + l_dy, hand_c)
		# Braco direito (se nao estiver levantado interagindo/atacando)
		if pose["kind"] not in ["interact", "attack", "special"]:
			_fill_rect(img, cx + t_hw - 1, torso_top + 1 + r_dy, cx + t_hw, torso_top + 2 + r_dy, sleeve_m)
			_fill_rect(img, cx + t_hw, torso_top + 3 + r_dy, cx + t_hw + 1, waist_y - 1 + r_dy, sleeve_d)
			_fill_rect(img, cx + t_hw, waist_y + r_dy, cx + t_hw + 1, waist_y + 1 + r_dy, hand_c)
	else:
		# Braco distante atras em perfil/diagonal
		var bx := cx - 2 + (-swing)
		if pose["kind"] == "interact" and pose["sub"] == 1:
			bx = cx - 4 # Ambas as maos para frente ao inspecionar
		_fill_rect(img, bx, torso_top + 2, bx + 2, torso_top + 6, sleeve_d)
		_fill_rect(img, bx, torso_top + 7, bx + 2, torso_top + 8, hand_c)

	# Mochila de Toby visivel lateralmente atras das costas
	if spec.get("apron", "") == "backpack" and (view == "left" or view == "down_left"):
		_fill_rect(img, cx + 2, torso_top + 1, cx + 6, waist_y - 1, Color("#6D5538"))
		_fill_rect(img, cx + 4, torso_top + 2, cx + 6, waist_y - 1, Color("#4D3B25"))


func _draw_torso(
	img: Image, cx: int, torso_top: int, waist_y: int,
	view: String, pose: Dictionary, pal: Dictionary, spec: Dictionary,
	is_child: bool, is_broad: bool
) -> void:
	var c_lit: Color = pal["torso"][0]
	var c_mid: Color = pal["torso"][1]
	var c_shd: Color = pal["torso"][2]
	var hw := 5 if is_broad else (4 if not is_child else 3)
	if view == "left":
		hw -= 1

	# Tronco com curvatura suave (ombros levemente largos, cintura 1 px afinada)
	_hline(img, cx - hw + 1, cx + hw - 2, torso_top, c_lit)
	_fill_rect(img, cx - hw, torso_top + 1, cx + hw - 1, torso_top + 4, c_mid)
	_fill_rect(img, cx - hw + 1, torso_top + 5, cx + hw - 2, waist_y - 1, c_mid)
	_fill_rect(img, cx + hw - 2, torso_top + 1, cx + hw - 1, waist_y - 1, c_shd)
	_hline(img, cx - hw + 1, cx + hw - 2, waist_y, c_shd)

	var collar: String = spec.get("collar_type", "round")
	var inner_c: Color = pal["inner"]
	if view != "up":
		if collar == "jacket_v" or collar == "v_neck":
			_fill_rect(img, cx - 2, torso_top, cx + 1, torso_top + 2, inner_c)
			_fill_rect(img, cx - 1, torso_top + 3, cx, torso_top + 4, inner_c)
		elif collar == "uniform_tie":
			_fill_rect(img, cx - 1, torso_top, cx + 1, torso_top + 1, inner_c)
			_hline(img, cx, cx, torso_top + 2, Color("#171924"))
		elif collar == "bfp_collar":
			_hline(img, cx - 2, cx + 1, torso_top, c_lit)
			_fill_rect(img, cx - 1, torso_top + 1, cx, torso_top + 2, inner_c)
		elif collar == "towel_neck":
			_hline(img, cx - 3, cx + 2, torso_top, Color("#ECEAE2"))
			_fill_rect(img, cx - 3, torso_top + 1, cx - 1, torso_top + 5, Color("#DCD9CE"))
			_fill_rect(img, cx + 1, torso_top + 1, cx + 2, torso_top + 5, Color("#C2BDB0"))
		elif collar == "rope_shoulder":
			_fill_rect(img, cx - hw, torso_top, cx - hw + 2, torso_top + 5, Color("#CFA45E"))
			_px(img, cx - hw + 1, torso_top + 2, Color("#946D35"))
			_px(img, cx - hw + 1, torso_top + 4, Color("#946D35"))
		elif collar == "shawl_lilac":
			_fill_rect(img, cx - hw, torso_top, cx + hw - 1, torso_top + 2, inner_c)
			_fill_rect(img, cx - 2, torso_top + 3, cx + 1, torso_top + 5, inner_c)
		elif collar == "kid_stripe":
			_hline(img, cx - hw, cx + hw - 1, torso_top + 3, inner_c)
			_hline(img, cx - hw, cx + hw - 1, torso_top + 4, inner_c)
	else:
		if collar == "towel_neck":
			_hline(img, cx - 3, cx + 2, torso_top, Color("#ECEAE2"))
			_hline(img, cx - 2, cx + 1, torso_top + 1, Color("#CCC8BC"))
		elif collar == "shawl_lilac":
			_fill_rect(img, cx - hw, torso_top, cx + hw - 1, torso_top + 4, inner_c)
		elif collar == "rope_shoulder":
			_fill_rect(img, cx + hw - 3, torso_top, cx + hw - 1, torso_top + 4, Color("#CFA45E"))

	var stripe: String = spec.get("stripe", "none")
	if stripe == "bfp_huwag":
		_hline(img, cx - hw, cx + hw - 1, torso_top + 4, Color("#F5CB5C"))
		_hline(img, cx - hw, cx + hw - 1, torso_top + 5, Color("#E86F24"))
	elif stripe == "bfp_orange_yellow":
		_hline(img, cx - hw, cx + hw - 1, torso_top + 3, Color("#E07D42"))
		_hline(img, cx - hw, cx + hw - 1, torso_top + 4, Color("#EDC268"))
	elif stripe == "bfp_thin_orange":
		_hline(img, cx - hw, cx + hw - 1, torso_top + 4, Color("#E87532"))
	elif stripe == "reyes_chevrons":
		_hline(img, cx - hw, cx + hw - 1, torso_top + 4, Color("#D6B254"))
		_hline(img, cx - hw, cx + hw - 1, waist_y - 1, Color("#D6B254"))
	elif stripe == "nurse_patch":
		_hline(img, cx - hw, cx + hw - 1, waist_y, Color("#24242A"))
		if view == "up":
			_hline(img, cx - hw + 1, cx + hw - 2, torso_top + 2, Color("#737C8F"))
	elif stripe == "ember_cracks":
		_px(img, cx - 1, torso_top + 2, Color("#FF4C3B"))
		_px(img, cx, torso_top + 3, Color("#FF9C38"))
		_px(img, cx + 1, torso_top + 4, Color("#D6333D"))
		_px(img, cx - 2, torso_top + 4, Color("#A8222A"))

	var apron: String = spec.get("apron", "none")
	if apron == "apron_blue" and view != "up":
		_fill_rect(img, cx - 3, torso_top + 1, cx + 2, waist_y, Color("#517599"))
		_fill_rect(img, cx - 2, waist_y - 2, cx + 1, waist_y - 1, Color("#395573"))
	elif apron == "apron_olive" and view != "up":
		_fill_rect(img, cx - 3, torso_top + 1, cx + 2, waist_y, Color("#566E41"))
		_fill_rect(img, cx - 2, waist_y - 2, cx + 1, waist_y - 1, Color("#3B4E2C"))
	elif apron == "pouch_brown":
		_fill_rect(img, cx + hw - 2, waist_y - 1, cx + hw, waist_y + 1, Color("#7A5230"))
	elif apron == "backpack" and (view == "up" or view == "up_left"):
		var bx := cx - 3 if view == "up" else cx - 1
		_fill_rect(img, bx, torso_top + 1, bx + 5, waist_y - 1, Color("#6D5538"))
		_fill_rect(img, bx + 1, torso_top + 2, bx + 4, torso_top + 3, Color("#8F734D"))


# Cabeca oval arredondada identica em proporcao e graciosidade a Enfermeira Maria!
func _draw_round_head(
	img: Image, cx: int, head_cy: int,
	view: String, pose: Dictionary, pal: Dictionary, spec: Dictionary,
	is_child: bool, is_distorted: bool
) -> void:
	var sk_lit: Color = pal["skin"][0]
	var sk_mid: Color = pal["skin"][1]
	var sk_shd: Color = pal["skin"][2]

	# Perfil de largura por linha dy = -6..+5 (tamanhos impares/pares suaves!)
	# Testa arredondada -> bochechas largas -> queixo afinado (14 -> 10 -> 6)!
	var rows_prof := [-4, -5, -6, -7, -7, -7, -7, -6, -5, -4, -3, -2]
	if is_child:
		rows_prof = [-3, -4, -5, -6, -6, -6, -5, -4, -3, -2]
	elif view == "left":
		rows_prof = [-3, -4, -5, -6, -6, -6, -6, -5, -4, -3, -2, -1]

	var top_off := -6 if not is_child else -5
	for idx in range(rows_prof.size()):
		var dy := top_off + idx
		var span: int = -rows_prof[idx]
		var l_x := cx - span
		var r_x := cx + span - (0 if view == "left" else 1)
		for x in range(l_x, r_x + 1):
			var c := sk_mid
			if dy <= -1 and x <= cx + 1:
				c = sk_lit
			elif dy >= 3 or x >= r_x - 1:
				c = sk_shd
			_px(img, x, head_cy + dy, c)

	# Nariz suave em perfil e 3/4
	if view == "left":
		_px(img, cx - 7, head_cy + 1, sk_mid)
		_px(img, cx - 7, head_cy + 2, sk_shd)
	elif view == "down_left":
		_px(img, cx - 7, head_cy + 1, sk_shd)

	_draw_round_hair(img, cx, head_cy, top_off, rows_prof, view, pal, spec)

	if view != "up":
		_draw_expressive_face(img, cx, head_cy, view, pose, pal, spec, is_child, is_distorted)

	_draw_round_headgear(img, cx, head_cy, top_off, view, pal, spec)


func _draw_round_hair(
	img: Image, cx: int, head_cy: int, top_off: int, rows_prof: Array,
	view: String, pal: Dictionary, spec: Dictionary
) -> void:
	var hs: String = spec.get("hair_style", "short_dark")
	var hc0: Color = pal["hair"][0]
	var hc1: Color = pal["hair"][1]
	var hc2: Color = pal["hair"][2]

	# Costas (up) e 3/4 costas (up_left)
	if view == "up":
		for idx in range(rows_prof.size() - 1):
			var dy := top_off + idx
			var span: int = -rows_prof[idx]
			for x in range(cx - span, cx + span):
				var c := hc0 if dy < -2 else hc1
				if hs == "huwag_bleached" and dy >= 1:
					c = hc2
				_px(img, x, head_cy + dy, c)
	elif view == "up_left":
		for idx in range(rows_prof.size() - 1):
			var dy := top_off + idx
			var span: int = -rows_prof[idx]
			var start_x := (cx - span + 2) if (dy >= 0 and dy <= 2) else (cx - span)
			for x in range(start_x, cx + span):
				var c := hc0 if dy < -2 else hc1
				if hs == "huwag_bleached" and dy >= 1:
					c = hc2
				_px(img, x, head_cy + dy, c)
	else:
		# Coroa arredondada superior + mechas laterais abraçando a orelha (deixa testa aberta no centro!)
		for idx in range(3):
			var dy := top_off + idx
			var span: int = -rows_prof[idx]
			_hline(img, cx - span, cx + span - (0 if view == "left" else 1), head_cy + dy, hc0)

		var mid_y := head_cy + top_off + 3
		if view == "down":
			# Partido em M suave deixando testa central livre acima dos olhos!
			_hline(img, cx - 7, cx - 3, mid_y, hc1)
			_hline(img, cx + 2, cx + 6, mid_y, hc1)
			_fill_rect(img, cx - 7, mid_y + 1, cx - 6, head_cy + 1, hc1)
			_fill_rect(img, cx + 5, mid_y + 1, cx + 6, head_cy + 1, hc1)
		elif view == "down_left":
			_hline(img, cx - 6, cx - 4, mid_y, hc1)
			_hline(img, cx + 2, cx + 6, mid_y, hc1)
			_fill_rect(img, cx + 4, mid_y + 1, cx + 6, head_cy + 2, hc1)
		elif view == "left":
			# Cabelo contorna apenas a nuca/topo traseiro, deixando bochecha e orelha limpos (fiel a Maria!)
			_fill_rect(img, cx + 2, mid_y, cx + 6, head_cy + 1, hc1)
			_fill_rect(img, cx + 4, head_cy + 2, cx + 6, head_cy + 3, hc1)
			_px(img, cx - 3, mid_y, hc1)

	# Perfis capilares proprios por personagem
	if hs == "huwag_bleached":
		# Topete loiro-palha espetado + raiz escura discreta apenas nas pontas da nuca/costeletas
		var ty := head_cy + top_off
		_hline(img, cx - 4, cx + 3, ty - 1, hc0)
		_px(img, cx - 3, ty - 2, hc0)
		_px(img, cx + 1, ty - 2, hc0)
		_px(img, cx - 7, ty + 1, hc1)
		_px(img, cx + 6, ty + 1, hc1)
		if view == "down" or view == "down_left":
			_px(img, cx - 1, ty + 3, hc0)
			_px(img, cx, ty + 3, hc1)
			_fill_rect(img, cx - 7, head_cy, cx - 6, head_cy + 2, hc2)
			_fill_rect(img, cx + 5, head_cy, cx + 6, head_cy + 2, hc2)
		elif view == "left":
			_fill_rect(img, cx + 3, head_cy, cx + 6, head_cy + 3, hc2)
	elif hs == "bun_back" or hs == "bun_red_clip" or hs == "bun_silver":
		# Coque baixo elegante bem visivel atras da cabeca!
		if view == "left" or view == "up_left":
			_fill_rect(img, cx + 5, head_cy - 2, cx + 8, head_cy + 2, hc1)
		elif view == "up":
			_fill_rect(img, cx - 2, head_cy - 1, cx + 2, head_cy + 3, hc2 if hs == "bun_silver" else hc1)
		elif view == "down_left":
			_fill_rect(img, cx + 5, head_cy - 1, cx + 7, head_cy + 2, hc1)
		if hs == "bun_red_clip":
			if view == "down" or view == "down_left":
				_fill_rect(img, cx + 4, head_cy + top_off + 3, cx + 5, head_cy + top_off + 4, hc2)
			else:
				_fill_rect(img, cx + 3, head_cy - 2, cx + 4, head_cy - 1, hc2)
	elif hs == "braid_grey":
		_fill_rect(img, cx + 5, head_cy, cx + 7, head_cy + 5, hc1)
	elif hs == "short_grey_temple":
		# Tempora grisalha nas laterais (Cap. Reyes / Mang Carding)
		if view == "left" or view == "down_left" or view == "up_left":
			_fill_rect(img, cx + 2, head_cy, cx + 5, head_cy + 2, hc0)


func _draw_expressive_face(
	img: Image, cx: int, head_cy: int,
	view: String, pose: Dictionary, pal: Dictionary, spec: Dictionary,
	is_child: bool, is_distorted: bool
) -> void:
	var eye_c: Color = pal["eye"]
	var hi_c: Color = pal["eye_hi"]
	var brow_c := Color("#4D2F1E") if not is_distorted else Color("#241419")
	var ey := head_cy + (1 if not is_child else 0)
	var turn: int = pose["head_turn"]

	if view == "down":
		var lx := cx - 3 + turn
		var rrx := cx + 2 + turn
		_hline(img, lx - 1, lx + 1, ey - 2, brow_c)
		_hline(img, rrx - 1, rrx + 1, ey - 2, brow_c)
		_fill_rect(img, lx, ey - 1, lx, ey, eye_c)
		_px(img, lx - 1, ey - 1, hi_c)
		_fill_rect(img, rrx, ey - 1, rrx, ey, eye_c)
		_px(img, rrx + 1, ey - 1, hi_c)
	elif view == "down_left":
		var lx := cx - 4
		var rrx := cx
		_hline(img, lx, lx + 1, ey - 2, brow_c)
		_hline(img, rrx - 1, rrx + 1, ey - 2, brow_c)
		_fill_rect(img, lx, ey - 1, lx, ey, eye_c)
		_fill_rect(img, rrx, ey - 1, rrx, ey, eye_c)
		_px(img, rrx + 1, ey - 1, hi_c)
	elif view == "left":
		var ex := cx - 4
		_hline(img, ex - 1, ex + 1, ey - 2, brow_c)
		_fill_rect(img, ex, ey - 1, ex, ey, eye_c)
		_px(img, ex + 1, ey - 1, hi_c)
	elif view == "up_left":
		_px(img, cx - 5, ey - 1, eye_c)

	if spec.get("mustache", false) and view != "up_left":
		var mc: Color = pal["hair"][0]
		if view == "down":
			_hline(img, cx - 2, cx + 1, ey + 2, mc)
		elif view == "down_left":
			_hline(img, cx - 3, cx, ey + 2, mc)
		elif view == "left":
			_hline(img, cx - 5, cx - 2, ey + 2, mc)

	if (pose["kind"] == "interact" and pose["sub"] == 3) or pose["hurt"]:
		var mx := cx - 1 if view == "down" else (cx - 2 if view == "down_left" else cx - 4)
		_px(img, mx, ey + 3, Color("#6E242B"))


func _draw_round_headgear(
	img: Image, cx: int, head_cy: int, top_off: int,
	view: String, pal: Dictionary, spec: Dictionary
) -> void:
	var hat: String = spec.get("hat", "none")
	if hat == "none":
		return
	var top_y := head_cy + top_off
	var h0: Color = pal["hat"][0]
	var h1: Color = pal["hat"][1]
	var h2: Color = pal["hat"][2]

	if hat == "salakot":
		# Salakot conico curvado com aba ampla sombreada
		_px(img, cx, top_y - 4, h2)
		_hline(img, cx - 2, cx + 1, top_y - 3, h0)
		_hline(img, cx - 4, cx + 3, top_y - 2, h0)
		_hline(img, cx - 6, cx + 5, top_y - 1, h1)
		_hline(img, cx - 9, cx + 8, top_y, h0)
		_hline(img, cx - 9, cx + 8, top_y + 1, h1)
		_hline(img, cx - 8, cx + 7, top_y + 2, h2)
	elif hat == "helmet_yellow" or hat == "helmet_charred":
		# Capacete bombeiro redondo alto + aba traseira (fiel ao Ato original!)
		_hline(img, cx - 3, cx + 2, top_y - 2, h0)
		_hline(img, cx - 6, cx + 5, top_y - 1, h0)
		_fill_rect(img, cx - 7, top_y, cx + 6, top_y + 2, h1)
		_hline(img, cx - 6, cx + 5, top_y + 3, h0)
		_fill_rect(img, cx - 1, top_y + 1, cx, top_y + 2, h2)
		if view == "left" or view == "up_left":
			_fill_rect(img, cx + 5, top_y + 2, cx + 8, top_y + 4, h1)
		elif view == "up":
			_fill_rect(img, cx - 6, top_y + 2, cx + 5, top_y + 4, h1)
	elif hat == "cap_bfp" or hat == "cap_trucker":
		_hline(img, cx - 5, cx + 4, top_y - 2, h0)
		_hline(img, cx - 7, cx + 6, top_y - 1, h0)
		_fill_rect(img, cx - 7, top_y, cx + 6, top_y + 2, h1)
		if view == "down":
			_hline(img, cx - 6, cx + 5, top_y + 3, Color("#14151D"))
			_px(img, cx, top_y + 1, h2)
		elif view == "left" or view == "down_left":
			_hline(img, cx - 9, cx - 2, top_y + 2, Color("#14151D"))
			_px(img, cx - 4, top_y + 1, h2)
	elif hat == "cap_backwards_red":
		_hline(img, cx - 5, cx + 4, top_y - 1, h0)
		_fill_rect(img, cx - 6, top_y, cx + 5, top_y + 2, h1)
		if view == "down":
			_hline(img, cx - 2, cx + 1, top_y + 1, Color("#ECE8DE"))
		if view == "left" or view == "down_left" or view == "up_left":
			_hline(img, cx + 3, cx + 8, top_y + 2, h2)
		elif view == "up":
			_hline(img, cx - 4, cx + 3, top_y + 3, h2)
	elif hat == "bandana_teal":
		_hline(img, cx - 7, cx + 6, top_y + 1, h0)
		_hline(img, cx - 7, cx + 6, top_y + 2, h1)
		if view != "down":
			_px(img, cx + 7, top_y + 2, h2)
			_px(img, cx + 8, top_y + 3, h0)
	elif hat == "headscarf_floral":
		_hline(img, cx - 5, cx + 4, top_y - 1, h0)
		_fill_rect(img, cx - 7, top_y, cx + 6, top_y + 2, h0)
		_fill_rect(img, cx + 3, top_y + 2, cx + 6, head_cy + 1, h1)
		if view == "up" or view == "up_left":
			_fill_rect(img, cx - 6, top_y + 1, cx + 5, head_cy + 2, h1)
		_px(img, cx - 3, top_y + 1, h2)
		_px(img, cx + 3, top_y + 1, h2)
		_px(img, cx, top_y, Color("#57914D"))


# Braco frontal + poses variadas de interacao + golpes amplos com arco de corte!
func _draw_front_arm_and_prop(
	img: Image, fx: Image, cx: int, torso_top: int, waist_y: int, head_cy: int,
	view: String, pose: Dictionary, pal: Dictionary, spec: Dictionary,
	is_child: bool, is_broad: bool
) -> void:
	var sleeve_c: Color = pal["torso"][0]
	var hand_c: Color = pal["skin"][0]
	var arm_m: String = pose["arm_mode"]

	var fwd_x := 0
	var fwd_y := 1
	match view:
		"down": fwd_x = 0; fwd_y = 1
		"left": fwd_x = -1; fwd_y = 0
		"up": fwd_x = 0; fwd_y = -1
		"down_left": fwd_x = -1; fwd_y = 1
		"up_left": fwd_x = -1; fwd_y = -1

	if pose["kind"] in ["idle", "walk", "run", "hurt", "defeat"]:
		if view != "down" and view != "up":
			var sway: int = int(pose["stride"]) * (-3 if pose["kind"] == "run" else -2)
			var ax := cx - 1
			var ay := torso_top + 1
			if pose["hurt"]:
				# Guarda defensiva ao receber dano
				_fill_rect(img, ax - 3, ay, ax - 1, ay + 4, sleeve_c)
				_fill_rect(img, ax - 3, ay - 1, ax - 2, ay, hand_c)
			else:
				_fill_rect(img, ax + sway, ay, ax + 1 + sway, ay + 5, sleeve_c)
				_fill_rect(img, ax + sway, ay + 6, ax + 1 + sway, ay + 7, hand_c)
		return

	# Poses de Interacao distintas em cols 6..9 + col 13 especial
	if pose["kind"] == "interact" or pose["kind"] == "special":
		var sh_x := (cx + 5) if view == "down" or view == "up" else (cx - 1)
		var sh_y := torso_top + 2
		var hx := sh_x + fwd_x * 4
		var hy := sh_y + fwd_y * 2

		if arm_m == "raise_item":
			# Col 6: Braco erguido em linha diagonal limpa ao lado da cabeca (como Maria col 6!)
			hx = (cx + 7) if view == "down" or view == "up" else (cx - 5)
			hy = head_cy - 2
			_draw_arm_line(img, sh_x, sh_y, hx, hy + 1, sleeve_c)
		elif arm_m == "use_item":
			# Col 7: Cotovelo dobrado na altura do peito inspecionando/limpando
			hx = cx - 1 + fwd_x * 4
			hy = torso_top + 4
			_draw_arm_line(img, sh_x, sh_y, hx, hy, sleeve_c)
		elif arm_m == "point_offer":
			# Col 8: Braco estendido bem a frente apontando/oferecendo!
			hx = cx + (7 if view == "down" else fwd_x * 8)
			hy = torso_top + 2 + fwd_y * 2
			_draw_arm_line(img, sh_x, sh_y, hx, hy, sleeve_c)
		elif arm_m == "speak_react":
			# Col 9: Mao erguida perto do rosto/peito conversando
			hx = cx + (6 if view == "down" else fwd_x * 6)
			hy = torso_top
			_draw_arm_line(img, sh_x, sh_y, hx, hy + 1, sleeve_c)
		else:
			# Col 13: Acolher gatinho/item no colo com ambos os bracos
			hx = cx + fwd_x * 3
			hy = torso_top + 4
			_draw_arm_line(img, sh_x, sh_y, hx, hy, sleeve_c)
			_draw_arm_line(img, cx - 3, sh_y, hx - 1, hy, sleeve_c)

		_fill_rect(img, hx - 1, hy, hx + 1, hy + 1, hand_c)
		_draw_interaction_prop(img, hx, hy, fwd_x, fwd_y, arm_m, spec)
		return

	# Ataques direcionais amplos (cols 6..9)
	if pose["kind"] == "attack":
		var sub: int = pose["sub"]
		var weapon: String = spec.get("weapon", "axe")
		if weapon == "none" or weapon == "count_fingers":
			var gx := cx + fwd_x * 5
			var gy := torso_top - 1
			_draw_arm_line(img, cx, torso_top + 2, gx, gy, sleeve_c)
			_fill_rect(img, gx - 1, gy, gx + 1, gy + 1, hand_c)
			return

		var sh_ax := (cx + 4) if fwd_x == 0 else cx
		var sh_ay := torso_top + 2
		var sx := cx
		var sy := torso_top
		if sub == 0: # Windup alto!
			sx = cx - fwd_x * 2 + (6 if fwd_x == 0 else 0)
			sy = head_cy - 5
		elif sub == 1: # Golpe impactando longo
			sx = cx + fwd_x * 8 + (4 if fwd_x == 0 else 0)
			sy = torso_top + 2 + fwd_y * 4
		elif sub == 2: # Extensao maxima
			sx = cx + fwd_x * 9 + (-4 if fwd_x == 0 else 0)
			sy = torso_top + 4 + fwd_y * 5
		else: # Retorno
			sx = cx + fwd_x * 5 + (3 if fwd_x == 0 else 0)
			sy = torso_top + 3 + fwd_y * 2

		_draw_arm_line(img, sh_ax, sh_ay, sx, sy, sleeve_c)
		_fill_rect(img, sx - 1, sy, sx + 1, sy + 1, hand_c)
		_draw_weapon_and_slash(img, fx, cx, sx, sy, fwd_x, fwd_y, sub, weapon)


func _draw_interaction_prop(img: Image, hx: int, hy: int, fx: int, fy: int, arm_m: String, spec: Dictionary) -> void:
	var ptype: String = spec.get("prop_peace", "none")

	# Pose especial: Senhora Luningning segurando gatinho laranja (col 13)
	if arm_m == "special_hold" and ptype == "lantern_cat":
		var cat_x := hx
		var cat_y := hy
		_fill_rect(img, cat_x - 3, cat_y - 2, cat_x + 3, cat_y + 1, Color("#EB913D"))
		_px(img, cat_x - 2, cat_y - 3, Color("#EB913D"))
		_px(img, cat_x + 2, cat_y - 3, Color("#EB913D"))
		_px(img, cat_x - 1, cat_y - 1, Color("#17131A"))
		_px(img, cat_x + 1, cat_y - 1, Color("#17131A"))
		_px(img, cat_x + 4, cat_y, Color("#C97128"))
		return

	if arm_m == "point_offer":
		# Col 8 enfatiza gesto de apontar com mao livre / item compacto
		if ptype in ["clipboard", "radio_clipboard", "radio_wave", "wrench_rag"]:
			return

	match ptype:
		"clipboard", "radio_clipboard":
			_fill_rect(img, hx - 2, hy - 4, hx + 2, hy + 2, Color("#855A38"))
			_fill_rect(img, hx - 1, hy - 3, hx + 1, hy + 1, Color("#F2EFE6"))
			_px(img, hx, hy - 4, Color("#A4ACBE"))
		"nozzle_gauge":
			_fill_rect(img, hx - 2, hy - 3, hx + 1, hy, Color("#E8EFF7"))
			_px(img, hx - 1, hy - 2, Color("#D63D38"))
			_fill_rect(img, hx - 1, hy + 1, hx + 2, hy + 2, Color("#C99A3E"))
		"radio_wave":
			_fill_rect(img, hx - 1, hy - 3, hx + 1, hy + 1, Color("#242936"))
			_px(img, hx - 1, hy - 5, Color("#303647"))
			_px(img, hx, hy - 2, Color("#4FE078"))
		"bag_fan":
			_fill_rect(img, hx - 2, hy, hx + 2, hy + 5, Color("#CF544A"))
			_hline(img, hx - 1, hx + 1, hy + 1, Color("#EDE4D3"))
		"wrench_rag":
			_fill_rect(img, hx - 1, hy - 4, hx + 1, hy + 1, Color("#BAC4D4"))
			_fill_rect(img, hx - 2, hy + 1, hx + 1, hy + 3, Color("#EFECE4"))
		"crate_salakot":
			_fill_rect(img, hx - 3, hy - 2, hx + 3, hy + 3, Color("#A67744"))
			_hline(img, hx - 2, hx + 2, hy, Color("#734E29"))
		"lantern_rope", "lantern_cat":
			_fill_rect(img, hx - 1, hy - 3, hx + 1, hy + 2, Color("#4D3E32"))
			_fill_rect(img, hx, hy - 2, hx, hy + 1, Color("#FFCF54"))
		"basket_herbs":
			_fill_rect(img, hx - 3, hy, hx + 3, hy + 3, Color("#BA8C4D"))
			_fill_rect(img, hx - 2, hy - 3, hx + 2, hy, Color("#56A84C"))
			_px(img, hx, hy - 4, Color("#7AE06C"))


func _draw_weapon_and_slash(
	img: Image, fx: Image, cx: int, sx: int, sy: int,
	fwd_x: int, fwd_y: int, sub: int, weapon: String
) -> void:
	var dir_x := fwd_x if fwd_x != 0 else (1 if sub <= 1 else -1)
	var dir_y := fwd_y if sub > 0 else -1

	if weapon == "axe" or weapon == "charred_axe":
		var shaft_c := Color("#8F5A38") if weapon == "axe" else Color("#2E262B")
		var head_c := Color("#CF382E") if weapon == "axe" else Color("#3A333D")
		var edge_c := Color("#E6EDF7") if weapon == "axe" else Color("#FF5438")
		# Cabo longo de 9 px + lamina larga bem visivel!
		var len_k := 8 if sub in [1, 2] else 6
		for t in range(1, len_k + 1):
			var px_x := sx + int(round(float(dir_x * t) * 0.9))
			var px_y := sy + int(round(float(dir_y * t) * 0.9))
			_fill_rect(img, px_x, px_y, px_x + 1, px_y + 1, shaft_c)
		var bx := sx + int(round(float(dir_x * len_k) * 0.9))
		var by := sy + int(round(float(dir_y * len_k) * 0.9))
		_fill_rect(img, bx - 2, by - 2, bx + 2, by + 2, head_c)
		_fill_rect(img, bx - 1 + dir_x * 2, by - 1 + dir_y, bx + dir_x * 2, by + 1 + dir_y, edge_c)
	elif weapon == "wrench_heavy":
		_fill_rect(img, sx, sy, sx + dir_x * 8, sy + dir_y * 6 + 1, Color("#8E99A8"))
		_fill_rect(img, sx + dir_x * 6 - 1, sy + dir_y * 5 - 1, sx + dir_x * 8 + 1, sy + dir_y * 6 + 2, Color("#CED7E6"))
	elif weapon == "cleaver":
		_fill_rect(img, sx + dir_x * 2, sy + dir_y * 2, sx + dir_x * 7, sy + dir_y * 5 + 3, Color("#D6DFEB"))
	elif weapon == "oar_hook":
		_fill_rect(img, sx, sy, sx + dir_x * 9, sy + dir_y * 7, Color("#7D5435"))
		_fill_rect(img, sx + dir_x * 7 - 1, sy + dir_y * 6 - 1, sx + dir_x * 9 + 1, sy + dir_y * 7 + 2, Color("#BA8D54"))
	elif weapon == "scalpel_clipboard":
		_fill_rect(img, sx - 1, sy - 2, sx + 1, sy + 1, Color("#7D5636"))
		_fill_rect(img, sx + dir_x * 2, sy + dir_y * 2, sx + dir_x * 6, sy + dir_y * 4, Color("#EAF2FA"))
		_px(img, sx + dir_x * 6, sy + dir_y * 4, Color("#D62832"))
	else:
		_fill_rect(img, sx + dir_x * 2 - 2, sy + dir_y * 2 - 2, sx + dir_x * 2 + 2, sy + dir_y * 2 + 2, Color("#DE3A42"))

	# Arco de corte amplo em 2 tons nos quadros ativos (1 e 2)
	if sub == 1 or sub == 2:
		var arc_c := SLASH_LIGHT if sub == 1 else SLASH_MID
		var ax := clampi(cx + fwd_x * 12, 4, CELL - 5)
		var ay := clampi(28 + fwd_y * 10, 4, CELL - 5)
		for k in range(-6, 7):
			var px_x: int = ax + (k if fwd_x == 0 else -int(absi(k) / 2) * fwd_x)
			var px_y: int = ay + (k if fwd_y == 0 else -int(absi(k) / 2) * fwd_y)
			var c_draw := arc_c if absi(k) <= 3 else SLASH_DARK
			_px(fx, clampi(px_x, 1, CELL - 2), clampi(px_y, 1, CELL - 2), c_draw)
			if absi(k) <= 2:
				_px(fx, clampi(px_x - fwd_x, 1, CELL - 2), clampi(px_y - fwd_y, 1, CELL - 2), SLASH_DARK)


func _render_fallen_pose(pal: Dictionary, spec: Dictionary) -> Image:
	var img := _new_cell()
	var y_base := 38
	# Corpo estendido nitido (cabeca a esquerda, tronco no meio, pernas e botas a direita)
	_fill_ellipse(img, 14, y_base - 1, 5, 4, pal["skin"][2])
	_fill_rect(img, 10, y_base - 4, 15, y_base - 1, pal["hair"][1])
	if spec.get("hat", "none") != "none":
		_fill_rect(img, 8, y_base - 4, 14, y_base, pal["hat"][1])
	_fill_rect(img, 19, y_base - 3, 29, y_base + 2, pal["torso"][1])
	_fill_rect(img, 29, y_base - 2, 36, y_base + 2, pal["pants"][1])
	_fill_rect(img, 36, y_base - 2, 39, y_base + 2, pal["boots"])
	_apply_outline(img, pal["ink"])
	return img


# ---------------------------------------------------------------------------
# Santelmos & Guardia da Lagoa Refinada (8 Direcoes)
# ---------------------------------------------------------------------------

func _compose_santelmo_sheet() -> Image:
	var sheet := Image.create(SHEET_W, SHEET_H, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0, 0, 0, 0))
	for dir_idx in range(DIRS):
		for col in range(COLS):
			sheet.blit_rect(_render_santelmo_cell(dir_idx, col), Rect2i(0, 0, CELL, CELL), Vector2i(col * CELL, dir_idx * CELL))
	return sheet


func _render_santelmo_cell(dir_idx: int, col: int) -> Image:
	var img := _new_cell()
	var pose := _decode_pose(col, Role.COMBAT, false)
	var dv := _dir_vec(dir_idx)
	var cx := 24 + int(dv.x * 2.0)
	var cy := 26 + int(dv.y * 2.0) + (col % 2 - 1)

	if pose["kind"] == "defeat":
		var r := 5 if pose["sub"] == 0 else 2
		_fill_circle(img, 24, 34, r, Color("#635E66"))
		_fill_circle(img, 24, 33, maxi(1, r - 2), Color("#E86F38") if pose["sub"] == 0 else Color("#9C94A1"))
		_apply_outline(img, INK)
		return img

	var tail_x := -int(dv.x * 6.0)
	var tail_y := -int(dv.y * 5.0) - 5
	var radius := 8 if pose["kind"] != "attack" else (10 if pose["sub"] in [1, 2] else 7)

	if pose["kind"] == "hurt":
		_fill_circle(img, cx, cy, 7, Color("#569EE8"))
		_fill_circle(img, cx, cy, 4, Color("#DCEEFF"))
		_apply_outline(img, INK)
		return img

	_fill_circle(img, cx + tail_x, cy + tail_y, 5, Color("#C92E28"))
	_fill_circle(img, cx + int(tail_x / 2), cy + int(tail_y / 2), 7, Color("#E35229"))
	_fill_circle(img, cx, cy, radius, Color("#F27D29"))
	_fill_circle(img, cx, cy + 1, maxi(3, radius - 3), Color("#FAD252"))
	_fill_circle(img, cx, cy + 2, maxi(2, radius - 5), Color("#FFF7C7"))

	if pose["kind"] == "attack" and pose["sub"] in [1, 2]:
		_fill_circle(img, cx + int(dv.x * 11), cy + int(dv.y * 10), 3, Color("#FAD252"))
		_px(img, cx + int(dv.x * 13), cy + int(dv.y * 12), Color("#FFF7C7"))

	_apply_outline(img, INK)
	if dir_idx != Dir.UP:
		var ey: int = cy + 1 + int(dv.y * 2)
		var ex: int = cx + int(dv.x * 3)
		_fill_rect(img, ex - 3, ey, ex - 2, ey + 1, Color("#1A0805"))
		_fill_rect(img, ex + 2, ey, ex + 3, ey + 1, Color("#1A0805"))
		_px(img, ex - 3, ey, Color("#FFF7C7"))
		_px(img, ex + 2, ey, Color("#FFF7C7"))
	return img


func _compose_guardian_sheet() -> Image:
	var sheet := Image.create(SHEET_W, SHEET_H, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0, 0, 0, 0))
	for dir_idx in range(DIRS):
		for col in range(COLS):
			sheet.blit_rect(_render_guardian_cell(dir_idx, col), Rect2i(0, 0, CELL, CELL), Vector2i(col * CELL, dir_idx * CELL))
	return sheet


func _render_guardian_cell(dir_idx: int, col: int) -> Image:
	if dir_idx == Dir.RIGHT:
		return _flip_img_h(_render_guardian_cell(Dir.LEFT, col))
	if dir_idx == Dir.DOWN_RIGHT:
		return _flip_img_h(_render_guardian_cell(Dir.DOWN_LEFT, col))
	if dir_idx == Dir.UP_RIGHT:
		return _flip_img_h(_render_guardian_cell(Dir.UP_LEFT, col))

	var img := _new_cell()
	var pose := _decode_pose(col, Role.COMBAT, false)
	var dv := _dir_vec(dir_idx)
	var bob: int = 1 if (col % 2 == 1) else 0
	var lean: int = int(pose["lean_x"]) if pose["kind"] == "attack" else 0
	var cx: int = 24 + lean
	var cy: int = 24 + bob + (int(pose["drop_y"]) if pose["kind"] == "defeat" else 0)

	if pose["kind"] == "defeat" and pose["sub"] == 1:
		_fill_ellipse(img, 24, 38, 12, 3, Color("#4ABFB8"))
		_fill_ellipse(img, 24, 37, 7, 2, Color("#A8F5E8"))
		_apply_outline(img, INK)
		return img

	var c_deep := Color("#174454")
	var c_mid := Color("#2B7D8C")
	var c_hi := Color("#54CFC4")
	var c_fin := Color("#9EF5EA")
	if pose["kind"] == "hurt":
		c_mid = Color("#4CA6CF"); c_hi = Color("#DCF7FF")

	# Aneis d'agua na base + cauda em curva S elegante (nao cilindro reto!)
	_fill_ellipse(img, cx, cy + 13, 11, 3, Color("#246878"))
	_fill_ellipse(img, cx + 2, cy + 11, 5, 3, c_deep)
	_fill_ellipse(img, cx + 1, cy + 7, 4, 4, c_mid)
	# Cintura esguia + tronco afinado
	_fill_rect(img, cx - 3, cy - 2, cx + 3, cy + 5, c_mid)
	_fill_rect(img, cx - 2, cy - 2, cx + 1, cy + 3, c_hi)

	# Barbatanas dorsais e de cabelos fluindo conforme a direcao!
	var fin_shift := 4 if dir_idx in [Dir.LEFT, Dir.DOWN_LEFT, Dir.UP_LEFT] else 0
	_fill_ellipse(img, cx + fin_shift + 4, cy - 4, 4, 6, c_hi)
	_fill_rect(img, cx - 8, cy - 11, cx - 5, cy - 6, c_fin)
	_fill_rect(img, cx + 5, cy - 11, cx + 8, cy - 6, c_fin)

	# Cabeca oval serena
	_fill_ellipse(img, cx, cy - 8, 5, 5, c_mid)
	_fill_ellipse(img, cx - 1, cy - 9, 3, 3, c_hi)

	# Bracos esguios + onda luminosa no ataque/bencao
	if pose["kind"] == "attack":
		var spread := 8 if pose["sub"] in [1, 2] else 6
		_fill_rect(img, cx - spread - 2, cy - 4, cx - 4, cy - 1, c_hi)
		_fill_rect(img, cx + 4, cy - 4, cx + spread + 2, cy - 1, c_hi)
		if pose["sub"] in [1, 2]:
			_fill_ellipse(img, cx + int(dv.x * 10), cy + 10 + int(dv.y * 5), 12, 3, c_fin)
	else:
		_fill_rect(img, cx - 6, cy - 1, cx - 4, cy + 4, c_mid)
		_fill_rect(img, cx + 4, cy - 1, cx + 6, cy + 4, c_deep)

	_apply_outline(img, INK)
	if dir_idx != Dir.UP:
		var ey: int = cy - 8
		if dir_idx == Dir.DOWN:
			_fill_rect(img, cx - 3, ey, cx - 2, ey + 1, Color("#FFE896"))
			_fill_rect(img, cx + 2, ey, cx + 3, ey + 1, Color("#FFE896"))
		elif dir_idx == Dir.DOWN_LEFT:
			_fill_rect(img, cx - 4, ey, cx - 3, ey + 1, Color("#FFE896"))
			_fill_rect(img, cx, ey, cx + 1, ey + 1, Color("#FFE896"))
		elif dir_idx == Dir.LEFT:
			_fill_rect(img, cx - 4, ey, cx - 3, ey + 1, Color("#FFE896"))
	return img


# ---------------------------------------------------------------------------
# Retratos CRT 96x96 com Contorno Escuro Nitido (fiel a fnaf_enfermeira_maria)
# ---------------------------------------------------------------------------

func _export_portrait(
	spec: Dictionary, is_distorted: bool, ref_portrait: Image,
	folder_path: String, mirror_path: String
) -> void:
	if ref_portrait != null and not is_distorted:
		ref_portrait.save_png(ProjectSettings.globalize_path(folder_path))
		if not mirror_path.is_empty():
			ref_portrait.save_png(ProjectSettings.globalize_path(mirror_path))
		return

	var bg_img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	var pal := _resolve_palette(spec, is_distorted)
	var bg: Color = spec.get("portrait_bg", Color("#111722"))
	if is_distorted:
		bg = _desat_shift(bg, Color("#1D0B10"), 0.65)
	bg_img.fill(bg)

	# Desenha silhueta sobre camada transparente para aplicar contorno 1px nitido!
	var fg := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	fg.fill(Color(0, 0, 0, 0))

	_fill_ellipse(fg, 16, 28, 10, 7, pal["torso"][1])
	_fill_ellipse(fg, 14, 27, 6, 4, pal["torso"][0])
	_fill_rect(fg, 13, 21, 18, 25, pal["skin"][2])
	if spec.get("collar_type", "") == "towel_neck":
		_fill_rect(fg, 10, 23, 21, 27, Color("#ECEAE2"))
	elif spec.get("collar_type", "") == "shawl_lilac":
		_fill_ellipse(fg, 16, 26, 10, 4, pal["inner"])
	elif spec.get("apron", "") == "apron_blue":
		_fill_rect(fg, 11, 25, 20, 31, Color("#517599"))
	elif spec.get("apron", "") == "apron_olive":
		_fill_rect(fg, 11, 25, 20, 31, Color("#566E41"))
	elif spec.get("stripe", "") in ["bfp_orange_yellow", "bfp_thin_orange", "bfp_huwag"]:
		_hline(fg, 7, 24, 27, Color("#E86F24"))
		_hline(fg, 7, 24, 28, Color("#F5CB5C"))
	elif spec.get("collar_type", "") == "rope_shoulder":
		_fill_rect(fg, 7, 24, 11, 30, Color("#CFA45E"))
	elif spec.get("collar_type", "") == "kid_stripe":
		_hline(fg, 8, 23, 27, pal["inner"])

	_fill_ellipse(fg, 16, 15, 7, 7, pal["skin"][1])
	_fill_ellipse(fg, 15, 14, 5, 5, pal["skin"][0])
	_hline(fg, 12, 19, 21, pal["skin"][2])

	_fill_ellipse(fg, 16, 10, 8, 4, pal["hair"][0])
	_fill_rect(fg, 8, 10, 10, 17, pal["hair"][1])
	_fill_rect(fg, 21, 10, 23, 17, pal["hair"][1])
	if spec.get("hair_style", "") == "bun_red_clip":
		_fill_rect(fg, 20, 10, 22, 11, pal["hair"][2])
	elif spec.get("hair_style", "") == "bun_silver":
		_fill_ellipse(fg, 16, 6, 4, 2, pal["hair"][1])

	var hat: String = spec.get("hat", "none")
	if hat == "salakot":
		_fill_ellipse(fg, 16, 8, 12, 3, pal["hat"][0])
		_fill_ellipse(fg, 16, 6, 6, 2, pal["hat"][1])
		_hline(fg, 14, 17, 4, pal["hat"][2])
	elif hat == "helmet_yellow" or hat == "helmet_charred":
		_fill_ellipse(fg, 16, 8, 9, 4, pal["hat"][0])
		_hline(fg, 7, 24, 10, pal["hat"][1])
		_fill_rect(fg, 14, 6, 17, 9, pal["hat"][2])
	elif hat == "cap_bfp":
		_fill_ellipse(fg, 16, 8, 8, 3, pal["hat"][0])
		_hline(fg, 9, 22, 10, Color("#15161E"))
		_px(fg, 16, 8, pal["hat"][2])
	elif hat == "cap_trucker":
		_fill_ellipse(fg, 16, 8, 8, 3, pal["hat"][0])
		_hline(fg, 8, 23, 10, pal["hat"][2])
	elif hat == "cap_backwards_red":
		_fill_ellipse(fg, 16, 8, 8, 3, pal["hat"][0])
		_fill_rect(fg, 14, 9, 17, 10, Color("#E8E4DA"))
	elif hat == "bandana_teal":
		_fill_rect(fg, 9, 9, 22, 11, pal["hat"][0])
		_hline(fg, 9, 22, 11, pal["hat"][1])
	elif hat == "headscarf_floral":
		_fill_ellipse(fg, 16, 9, 9, 4, pal["hat"][0])
		_px(fg, 11, 8, pal["hat"][2])
		_px(fg, 20, 8, pal["hat"][2])
		_px(fg, 16, 7, Color("#57914D"))

	_hline(fg, 11, 13, 13, Color("#3B2418"))
	_hline(fg, 18, 20, 13, Color("#3B2418"))
	if is_distorted:
		_fill_rect(fg, 11, 14, 13, 16, Color("#0E0B10"))
		_fill_rect(fg, 18, 14, 20, 16, Color("#0E0B10"))
		var glow := Color("#FF4A42") if spec.get("id", "") != "toby" else Color("#DCD7E3")
		_px(fg, 12, 15, glow)
		_px(fg, 19, 15, glow)
	else:
		_fill_rect(fg, 12, 14, 13, 15, EYE_DARK)
		_fill_rect(fg, 18, 14, 19, 15, EYE_DARK)
		_px(fg, 11, 14, EYE_WHITE)
		_px(fg, 20, 14, EYE_WHITE)

	if spec.get("mustache", false):
		_hline(fg, 13, 18, 18, pal["hair"][0])
	var mouth := Color("#784836") if not is_distorted else Color("#240F14")
	_hline(fg, 15, 16, 19, mouth)

	_apply_outline(fg, INK)
	for y in range(32):
		for x in range(32):
			var c := fg.get_pixel(x, y)
			if c.a > 0.5:
				bg_img.set_pixel(x, y, c)

	_finalize_and_save_crt(bg_img, spec, is_distorted, folder_path, mirror_path)


func _export_guardian_portrait(folder_path: String, mirror_path: String) -> void:
	var bg_img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	bg_img.fill(Color("#0D1C24"))
	var fg := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	fg.fill(Color(0, 0, 0, 0))
	_fill_ellipse(fg, 16, 26, 9, 6, Color("#1D596B"))
	_fill_ellipse(fg, 16, 15, 7, 7, Color("#2E8594"))
	_fill_ellipse(fg, 15, 14, 5, 5, Color("#54CFC4"))
	_fill_rect(fg, 7, 10, 9, 15, Color("#9BF2E6"))
	_fill_rect(fg, 22, 10, 24, 15, Color("#9BF2E6"))
	_fill_rect(fg, 12, 14, 13, 15, Color("#FFE896"))
	_fill_rect(fg, 18, 14, 19, 15, Color("#FFE896"))
	_apply_outline(fg, INK)
	for y in range(32):
		for x in range(32):
			var c := fg.get_pixel(x, y)
			if c.a > 0.5:
				bg_img.set_pixel(x, y, c)
	_finalize_and_save_crt(bg_img, {"portrait_border": Color("#54CFC4")}, false, folder_path, mirror_path)


func _finalize_and_save_crt(
	base32: Image, spec: Dictionary, is_distorted: bool,
	folder_path: String, mirror_path: String
) -> void:
	if is_distorted:
		var tmp := base32.duplicate()
		for y in [14, 15, 22]:
			for x in range(1, 31):
				base32.set_pixel(x, y, tmp.get_pixel(clampi(x + (1 if y % 2 == 0 else -1), 0, 31), y))

	var out := Image.create(96, 96, false, Image.FORMAT_RGBA8)
	var border_c: Color = spec.get("portrait_border", Color("#6A8CAF"))
	if is_distorted:
		border_c = Color("#D63D44")

	for y in range(96):
		var scan := 0.85 if (y % 3 == 2) else 1.0
		for x in range(96):
			if x == 0 or y == 0 or x == 95 or y == 95:
				out.set_pixel(x, y, border_c)
				continue
			if x == 1 or y == 1 or x == 94 or y == 94:
				out.set_pixel(x, y, INK)
				continue
			var sc := base32.get_pixel(int(x / 3), int(y / 3))
			out.set_pixel(x, y, Color(sc.r * scan, sc.g * scan, sc.b * scan, 1.0))

	out.save_png(ProjectSettings.globalize_path(folder_path))
	if not mirror_path.is_empty():
		out.save_png(ProjectSettings.globalize_path(mirror_path))


# ---------------------------------------------------------------------------
# Utilitarios Pixel Art
# ---------------------------------------------------------------------------

func _new_cell() -> Image:
	var img := Image.create(CELL, CELL, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	return img


func _load_rgba(res_path: String) -> Image:
	var abs_p := ProjectSettings.globalize_path(res_path)
	if not FileAccess.file_exists(abs_p):
		return null
	var img := Image.load_from_file(abs_p)
	if img != null and img.get_format() != Image.FORMAT_RGBA8:
		img.convert(Image.FORMAT_RGBA8)
	return img


func _px(img: Image, x: int, y: int, c: Color) -> void:
	if x >= 1 and x < img.get_width() - 1 and y >= 1 and y < img.get_height() - 1:
		img.set_pixel(x, y, c)


func _hline(img: Image, x0: int, x1: int, y: int, c: Color) -> void:
	for x in range(mini(x0, x1), maxi(x0, x1) + 1):
		_px(img, x, y, c)


func _fill_rect(img: Image, x0: int, y0: int, x1: int, y1: int, c: Color) -> void:
	for y in range(mini(y0, y1), maxi(y0, y1) + 1):
		for x in range(mini(x0, x1), maxi(x0, x1) + 1):
			_px(img, x, y, c)


func _draw_arm_line(img: Image, x0: int, y0: int, x1: int, y1: int, c: Color) -> void:
	var steps := maxi(1, maxi(absi(x1 - x0), absi(y1 - y0)))
	for i in range(steps + 1):
		var t := float(i) / float(steps)
		var x := int(round(lerpf(float(x0), float(x1), t)))
		var y := int(round(lerpf(float(y0), float(y1), t)))
		_fill_rect(img, x - 1, y - 1, x + 1, y, c)


func _fill_circle(img: Image, cx: int, cy: int, r: int, c: Color) -> void:
	for dy in range(-r, r + 1):
		for dx in range(-r, r + 1):
			if dx * dx + dy * dy <= r * r:
				_px(img, cx + dx, cy + dy, c)


func _fill_ellipse(img: Image, cx: int, cy: int, rx: int, ry: int, c: Color) -> void:
	if rx <= 0 or ry <= 0:
		return
	for dy in range(-ry, ry + 1):
		for dx in range(-rx, rx + 1):
			var nx := float(dx) / float(rx)
			var ny := float(dy) / float(ry)
			if nx * nx + ny * ny <= 1.05:
				_px(img, cx + dx, cy + dy, c)


func _composite_with_depth_outline(dst: Image, layers: Array, outline_c: Color) -> void:
	var w := dst.get_width()
	var h := dst.get_height()
	for layer in layers:
		var l_img: Image = layer
		var outline_pts: Array[Vector2i] = []
		for y in range(h):
			for x in range(w):
				if l_img.get_pixel(x, y).a > 0.5:
					continue
				for off in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
					var nx: int = x + off.x
					var ny: int = y + off.y
					if nx >= 0 and nx < w and ny >= 0 and ny < h:
						if l_img.get_pixel(nx, ny).a > 0.5:
							outline_pts.append(Vector2i(x, y))
							break
		for p in outline_pts:
			dst.set_pixel(p.x, p.y, outline_c)
		for y in range(h):
			for x in range(w):
				var c := l_img.get_pixel(x, y)
				if c.a > 0.5:
					dst.set_pixel(x, y, c)


func _apply_outline(img: Image, outline_c: Color) -> void:
	var w := img.get_width()
	var h := img.get_height()
	var pts: Array[Vector2i] = []
	for y in range(h):
		for x in range(w):
			if img.get_pixel(x, y).a > 0.5:
				continue
			for off in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var nx: int = x + off.x
				var ny: int = y + off.y
				if nx >= 0 and nx < w and ny >= 0 and ny < h:
					if img.get_pixel(nx, ny).a > 0.5:
						pts.append(Vector2i(x, y))
						break
	for p in pts:
		img.set_pixel(p.x, p.y, outline_c)


func _blit_alpha(dst: Image, src: Image) -> void:
	for y in range(CELL):
		for x in range(CELL):
			var c := src.get_pixel(x, y)
			if c.a > 0.5:
				dst.set_pixel(x, y, c)


func _tint_flash(img: Image, tint: Color, amount: float) -> void:
	for y in range(CELL):
		for x in range(CELL):
			var c := img.get_pixel(x, y)
			if c.a > 0.5 and c.get_luminance() > 0.08:
				img.set_pixel(x, y, c.lerp(tint, amount))


func _flip_img_h(src: Image) -> Image:
	var out := src.duplicate()
	out.flip_x()
	return out


func _dir_vec(dir_idx: int) -> Vector2:
	match dir_idx:
		Dir.DOWN: return Vector2(0, 1)
		Dir.LEFT: return Vector2(-1, 0)
		Dir.RIGHT: return Vector2(1, 0)
		Dir.UP: return Vector2(0, -1)
		Dir.DOWN_LEFT: return Vector2(-0.75, 0.75)
		Dir.DOWN_RIGHT: return Vector2(0.75, 0.75)
		Dir.UP_LEFT: return Vector2(-0.75, -0.75)
		Dir.UP_RIGHT: return Vector2(0.75, -0.75)
	return Vector2(0, 1)
