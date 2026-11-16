@tool
extends SceneTree
## Generates Batch 1 (Nucleo BFP: Cap. Reyes, Bombeiro Ato, Bombeiro Santos, Enfermeira Maria)
## using Huwag v3's organic anatomical templates, bespoke props, and 4 unique attack choreographies.

const Builder = preload("res://scripts/tools/npc_pixel_rig/npc_sprite_builder.gd")

const ARTIFACT_DIR := "C:/Users/SnyX/.gemini/antigravity/brain/6f04634a-b7d4-4d6f-9c20-24b6fdf404a0"
const BASE_OUT_DIR := "res://assets/sprites/npcs"
const FLOOR_COLOR := Color("#2C1E16")
const FLOOR_SEAM := Color("#3B281E")


func _init() -> void:
	var specs: Array[Dictionary] = [
		_spec_cap_reyes(),
		_spec_bombeiro_ato(),
		_spec_bombeiro_santos(),
		_spec_enfermeira_maria(),
	]

	var results: Array[Dictionary] = []
	for spec in specs:
		var npc_id: String = str(spec["id"])
		var npc_dir: String = "%s/%s" % [BASE_OUT_DIR, npc_id]
		var res_norm: Dictionary = Builder.build_character_assets(spec, "normal", npc_dir)
		var res_dist: Dictionary = Builder.build_character_assets(spec, "distorted", npc_dir)
		results.append({
			"spec": spec,
			"normal": res_norm,
			"distorted": res_dist,
		})
		_print_metrics(npc_id, res_norm, res_dist)

	_build_boards(results)
	print("[LOTE 1] Organico BFP concluido com sucesso.")
	quit(0)


# ---------------------------------------------------------------------------
# Lote 1 Character Specifications
# ---------------------------------------------------------------------------
func _spec_cap_reyes() -> Dictionary:
	var reyes_skin_norm := Builder.default_skin_normal()
	var reyes_skin_dist := Builder.default_skin_distorted()
	return {
		"id": "cap_reyes",
		"label": "Cap. Reyes",
		"build": "broad",
		"head_id": "reyes",
		"outfit_style": "bfp_commander",
		"attack_style": "command_sweep",
		"tired_eyes": false,
		"helmet_crack": false,
		"normal": {
			"skin": reyes_skin_norm,
			"mustache": Color("#E4E9F2"),
			"hair": {
				"base": Color("#4C515E"),
				"hi": Color("#7F8699"),
				"sh": Color("#30343E"),
				"out": Color("#1A1D26"),
			},
			"hat": {
				"base": Color("#1E2C47"),
				"hi": Color("#324770"),
				"sh": Color("#131C30"),
				"visor": Color("#111622"),
				"emblem": Color("#F5C84C"),
				"out": Color("#101522"),
			},
			"torso": {
				"base": Color("#1F2E4A"),
				"hi": Color("#334870"),
				"sh": Color("#141E33"),
				"undershirt": Color("#1B2840"),
				"stripe1": Color("#E59F32"),
				"stripe2": Color("#F5CE51"),
				"strap": Color("#252B38"),
				"stain": Color("#8A1D24"),
				"out": Color("#101522"),
			},
			"legs": {
				"base": Color("#1B2438"),
				"sh": Color("#121826"),
				"boots": Color("#2A2E3A"),
				"boots_hi": Color("#4C5366"),
			},
			"talk_prop": {
				"kind": "radio",
				"primary": Color("#252A36"),
				"secondary": Color("#7D889E"),
				"accent": Color("#5EF27E"),
			},
			"weapon": {
				"blade": Color("#B8C4D4"),
				"blade_hi": Color("#F0F6FC"),
				"handle": Color("#293040"),
				"accent": Color("#F5C445"),
			},
		},
		"distorted": {
			"skin": reyes_skin_dist,
			"mustache": Color("#8A8E99"),
			"hair": {
				"base": Color("#3D404A"),
				"hi": Color("#5B5F6B"),
				"sh": Color("#282A33"),
				"out": Color("#16151C"),
			},
			"hat": {
				"base": Color("#1A1E2B"),
				"hi": Color("#272E40"),
				"sh": Color("#10131C"),
				"visor": Color("#101118"),
				"emblem": Color("#E03E36"),
				"out": Color("#131018"),
			},
			"torso": {
				"base": Color("#1A1F2C"),
				"hi": Color("#282F42"),
				"sh": Color("#11141F"),
				"undershirt": Color("#171C28"),
				"stripe1": Color("#7D3131"),
				"stripe2": Color("#B8503D"),
				"strap": Color("#1E1D26"),
				"stain": Color("#8A1D24"),
				"out": Color("#121018"),
			},
			"legs": {
				"base": Color("#161A24"),
				"sh": Color("#0F121A"),
				"boots": Color("#211F26"),
				"boots_hi": Color("#393640"),
			},
			"talk_prop": {
				"kind": "radio",
				"primary": Color("#1C1A22"),
				"secondary": Color("#5C4C54"),
				"accent": Color("#FF3B30"),
			},
			"weapon": {
				"blade": Color("#82757C"),
				"blade_hi": Color("#C9B2B8"),
				"handle": Color("#211D26"),
				"accent": Color("#FF4638"),
			},
		},
	}


func _spec_bombeiro_ato() -> Dictionary:
	var ato_skin_norm := {
		"p": Color("#CF8F63"),
		"l": Color("#BA7A50"),
		"d": Color("#864F33"),
		"q": Color("#A36645"),
		"S": Color("#4B2A1B"),
		"r": Color("#703E26"),
		"w": Color("#F0F2F7"),
		"E": Color("#1F181A"),
	}
	return {
		"id": "bombeiro_ato",
		"label": "Bombeiro Ato",
		"build": "broad",
		"head_id": "ato",
		"outfit_style": "bfp_turnout_hose",
		"attack_style": "axe_slam",
		"tired_eyes": false,
		"helmet_crack": true,
		"normal": {
			"skin": ato_skin_norm,
			"hair": {
				"base": Color("#24232A"),
				"hi": Color("#3A3842"),
				"sh": Color("#17161B"),
				"out": Color("#141217"),
			},
			"hat": {
				"base": Color("#E6B332"),
				"hi": Color("#FFE06B"),
				"sh": Color("#B37E1B"),
				"visor": Color("#2A303D"),
				"emblem": Color("#DCF4FF"),
				"out": Color("#543A0D"),
			},
			"torso": {
				"base": Color("#1E2C45"),
				"hi": Color("#304469"),
				"sh": Color("#131D30"),
				"undershirt": Color("#19253B"),
				"stripe1": Color("#E86A24"),
				"stripe2": Color("#F7CE46"),
				"strap": Color("#343B48"),
				"stain": Color("#8A1D24"),
				"out": Color("#101522"),
			},
			"legs": {
				"base": Color("#192336"),
				"sh": Color("#111826"),
				"boots": Color("#262A33"),
				"boots_hi": Color("#464D5E"),
			},
			"talk_prop": {
				"kind": "gauge_nozzle",
				"primary": Color("#D9A83B"),
				"secondary": Color("#F2F7FA"),
				"accent": Color("#E04538"),
			},
			"weapon": {
				"blade": Color("#9BA8BA"),
				"blade_hi": Color("#ECF2FA"),
				"handle": Color("#7E4C29"),
				"accent": Color("#DE3E34"),
			},
		},
		"distorted": {
			"skin": Builder.default_skin_distorted(),
			"hair": {
				"base": Color("#1E1D24"),
				"hi": Color("#2E2C36"),
				"sh": Color("#131217"),
				"out": Color("#121015"),
			},
			"hat": {
				"base": Color("#755A24"),
				"hi": Color("#967633"),
				"sh": Color("#4D3916"),
				"visor": Color("#1F1C24"),
				"emblem": Color("#FF3B30"),
				"out": Color("#2B1E0D"),
			},
			"torso": {
				"base": Color("#1A1C26"),
				"hi": Color("#282B38"),
				"sh": Color("#12131A"),
				"undershirt": Color("#171822"),
				"stripe1": Color("#8A3429"),
				"stripe2": Color("#B85935"),
				"strap": Color("#221F26"),
				"stain": Color("#9E1C24"),
				"out": Color("#141016"),
			},
			"legs": {
				"base": Color("#161822"),
				"sh": Color("#101118"),
				"boots": Color("#1C1A20"),
				"boots_hi": Color("#34303B"),
			},
			"talk_prop": {
				"kind": "gauge_nozzle",
				"primary": Color("#78522A"),
				"secondary": Color("#BDA8AE"),
				"accent": Color("#FF4638"),
			},
			"weapon": {
				"blade": Color("#7E7580"),
				"blade_hi": Color("#CCB6BC"),
				"handle": Color("#47271C"),
				"accent": Color("#D4282C"),
			},
		},
	}


func _spec_bombeiro_santos() -> Dictionary:
	var santos_skin_norm := {
		"p": Color("#E2A578"),
		"l": Color("#CE8E63"),
		"d": Color("#9A6245"),
		"q": Color("#B87A56"),
		"S": Color("#543323"),
		"r": Color("#824A32"),
		"w": Color("#F0F2F7"),
		"E": Color("#1F191C"),
	}
	return {
		"id": "bombeiro_santos",
		"label": "Bombeiro Santos",
		"build": "slim",
		"head_id": "santos",
		"outfit_style": "bfp_open_tee",
		"attack_style": "halligan_hook",
		"tired_eyes": false,
		"helmet_crack": false,
		"normal": {
			"skin": santos_skin_norm,
			"hair": {
				"base": Color("#222530"),
				"hi": Color("#3E4457"),
				"sh": Color("#151720"),
				"rim": Color("#637499"),
				"out": Color("#12131A"),
			},
			"torso": {
				"base": Color("#213250"),
				"hi": Color("#3F5B8C"),
				"rim": Color("#5B6F99"),
				"sh": Color("#162238"),
				"undershirt": Color("#E4EAF2"),
				"stripe1": Color("#EB8E2C"),
				"stripe2": Color("#F5CE51"),
				"strap": Color("#2A2F3B"),
				"stain": Color("#941D25"),
				"out": Color("#111726"),
			},
			"legs": {
				"base": Color("#1D283E"),
				"sh": Color("#141B2B"),
				"boots": Color("#2D323E"),
				"boots_hi": Color("#525A6E"),
			},
			"talk_prop": {
				"kind": "radio",
				"primary": Color("#252A36"),
				"secondary": Color("#7D889E"),
				"accent": Color("#5EF27E"),
			},
			"weapon": {
				"blade": Color("#95A5B8"),
				"blade_hi": Color("#E1ECF7"),
				"handle": Color("#323B4D"),
				"accent": Color("#E04B3E"),
			},
		},
		"distorted": {
			"skin": Builder.default_skin_distorted(),
			"hair": {
				"base": Color("#1C1C24"),
				"hi": Color("#30303B"),
				"sh": Color("#131318"),
				"rim": Color("#5B546E"),
				"out": Color("#111015"),
			},
			"torso": {
				"base": Color("#191D2A"),
				"hi": Color("#272D40"),
				"rim": Color("#484C63"),
				"sh": Color("#11141E"),
				"undershirt": Color("#8A8591"),
				"stripe1": Color("#8A3429"),
				"stripe2": Color("#B85935"),
				"strap": Color("#231D24"),
				"stain": Color("#941D25"),
				"out": Color("#121017"),
			},
			"legs": {
				"base": Color("#171A26"),
				"sh": Color("#11131C"),
				"boots": Color("#201E26"),
				"boots_hi": Color("#3C3847"),
			},
			"talk_prop": {
				"kind": "radio",
				"primary": Color("#1D1B24"),
				"secondary": Color("#5C4C54"),
				"accent": Color("#FF3B30"),
			},
			"weapon": {
				"blade": Color("#787380"),
				"blade_hi": Color("#C2B2BC"),
				"handle": Color("#26222B"),
				"accent": Color("#E02B32"),
			},
		},
	}


func _spec_enfermeira_maria() -> Dictionary:
	var maria_skin_norm := {
		"p": Color("#E8AE82"),
		"l": Color("#D4966C"),
		"d": Color("#9E6648"),
		"q": Color("#BF815E"),
		"S": Color("#593727"),
		"r": Color("#9E5542"),
		"w": Color("#F2F4F8"),
		"E": Color("#211A1E"),
	}
	var maria_skin_dist := {
		"p": Color("#948D9C"),
		"l": Color("#7B7482"),
		"d": Color("#56505C"),
		"q": Color("#403B45"),
		"S": Color("#241E29"),
		"r": Color("#47262E"),
		"w": Color("#2D2530"),
		"E": Color("#FF3B30"),
	}
	return {
		"id": "enfermeira_maria",
		"label": "Enfermeira Maria",
		"build": "slim",
		"head_id": "maria",
		"outfit_style": "nurse_labcoat",
		"attack_style": "scalpel_thrust",
		"tired_eyes": false,
		"helmet_crack": false,
		"normal": {
			"skin": maria_skin_norm,
			"hair": {
				"base": Color("#20232E"),
				"hi": Color("#3C4257"),
				"sh": Color("#141720"),
				"pin": Color("#E04552"),
				"out": Color("#11121A"),
			},
			"torso": {
				"base": Color("#A9BCCE"),
				"hi": Color("#D0E0F0"),
				"sh": Color("#7589A1"),
				"undershirt": Color("#3A586E"),
				"stripe1": Color("#D0E0F0"),
				"stripe2": Color("#E04552"),
				"strap": Color("#6E4A36"),
				"stain": Color("#A61B26"),
				"out": Color("#283445"),
			},
			"legs": {
				"base": Color("#1E283D"),
				"sh": Color("#141B2B"),
				"boots": Color("#262B36"),
				"boots_hi": Color("#485166"),
			},
			"talk_prop": {
				"kind": "clipboard",
				"primary": Color("#7E8A9C"),
				"secondary": Color("#F0F4F8"),
				"accent": Color("#E04552"),
			},
			"weapon": {
				"blade": Color("#A8BED4"),
				"blade_hi": Color("#F4FAFF"),
				"handle": Color("#5A6B80"),
				"accent": Color("#5EE0E8"),
			},
		},
		"distorted": {
			"skin": maria_skin_dist,
			"hair": {
				"base": Color("#191921"),
				"hi": Color("#2F2F3B"),
				"sh": Color("#111117"),
				"pin": Color("#A81C28"),
				"out": Color("#101014"),
			},
			"torso": {
				"base": Color("#737887"),
				"hi": Color("#8E93A3"),
				"sh": Color("#4D515E"),
				"undershirt": Color("#2D3642"),
				"stripe1": Color("#8E93A3"),
				"stripe2": Color("#C2232E"),
				"strap": Color("#452A24"),
				"stain": Color("#A81A25"),
				"out": Color("#21212B"),
			},
			"legs": {
				"base": Color("#171A26"),
				"sh": Color("#10121B"),
				"boots": Color("#1E1B24"),
				"boots_hi": Color("#383242"),
			},
			"talk_prop": {
				"kind": "clipboard",
				"primary": Color("#585A66"),
				"secondary": Color("#BDAAAE"),
				"accent": Color("#D92935"),
			},
			"weapon": {
				"blade": Color("#9A93A1"),
				"blade_hi": Color("#F0DEE2"),
				"handle": Color("#3E3B47"),
				"accent": Color("#E62936"),
			},
		},
	}


# ---------------------------------------------------------------------------
# Verification Metrics & Approval Boards
# ---------------------------------------------------------------------------
func _print_metrics(npc_id: String, res_norm: Dictionary, res_dist: Dictionary) -> void:
	var idle_down: Image = res_norm["samples"]["idle_down"]
	var dist_down: Image = res_dist["samples"]["idle_down"]
	var b_n := _alpha_bounds(idle_down)
	var b_d := _alpha_bounds(dist_down)
	print("[LOTE 1] %s | normal idle_down=%s (foot y=%d) | distorted idle_down=%s (foot y=%d) | tres=%s" % [
		npc_id, str(b_n), b_n.end.y - 1, str(b_d), b_d.end.y - 1, str(res_norm["tres_path"])
	])


func _alpha_bounds(img: Image) -> Rect2i:
	var min_x := 999
	var min_y := 999
	var max_x := -1
	var max_y := -1
	for y in range(img.get_height()):
		for x in range(img.get_width()):
			if img.get_pixel(x, y).a > 0.05:
				min_x = mini(min_x, x)
				min_y = mini(min_y, y)
				max_x = maxi(max_x, x)
				max_y = maxi(max_y, y)
	if max_x < min_x:
		return Rect2i()
	return Rect2i(min_x, min_y, max_x - min_x + 1, max_y - min_y + 1)


func _load_huwag_sheet_cell(variant: String, anim: String, col: int, row: int) -> Image:
	var path: String = "res://assets/sprites/huwag_v3/%s/spritesheet_%s.png" % [variant, anim]
	var abs_p := ProjectSettings.globalize_path(path)
	var full := Image.load_from_file(abs_p)
	var cell := Image.create(48, 48, false, Image.FORMAT_RGBA8)
	if full:
		cell.blit_rect(full, Rect2i(col * 48, row * 48, 48, 48), Vector2i.ZERO)
	return cell


func _build_boards(results: Array[Dictionary]) -> void:
	var cell_step_x := 54
	var cell_step_y := 54

	# 1) Main Summary Board (1x + 4x)
	var cols := 9
	var rows := 10
	var board_w := 16 + cols * cell_step_x + 10
	var board_h := 16 + rows * cell_step_y + 10
	var board := Image.create(board_w, board_h, false, Image.FORMAT_RGBA8)
	board.fill(FLOOR_COLOR)
	for y in range(0, board_h, 24):
		for x in range(board_w):
			board.set_pixel(x, y, FLOOR_SEAM)

	var huwag_casual_row: Array[Image] = [
		_load_huwag_sheet_cell("casual", "idle", 0, 0),
		_load_huwag_sheet_cell("casual", "idle", 0, 1),
		_load_huwag_sheet_cell("casual", "idle", 0, 2),
		_load_huwag_sheet_cell("casual", "idle", 0, 3),
		_load_huwag_sheet_cell("casual", "idle", 1, 0),
		_load_huwag_sheet_cell("casual", "attack", 2, 0),
		_load_huwag_sheet_cell("casual", "attack", 2, 2),
		_load_huwag_sheet_cell("casual", "hurt", 0, 0),
		_load_huwag_sheet_cell("casual", "death", 4, 0),
	]
	var huwag_bfp_row: Array[Image] = [
		_load_huwag_sheet_cell("bombeiro", "idle", 0, 0),
		_load_huwag_sheet_cell("bombeiro", "idle", 0, 1),
		_load_huwag_sheet_cell("bombeiro", "idle", 0, 2),
		_load_huwag_sheet_cell("bombeiro", "idle", 0, 3),
		_load_huwag_sheet_cell("bombeiro", "idle", 1, 0),
		_load_huwag_sheet_cell("bombeiro", "attack", 2, 0),
		_load_huwag_sheet_cell("bombeiro", "attack", 2, 2),
		_load_huwag_sheet_cell("bombeiro", "hurt", 0, 0),
		_load_huwag_sheet_cell("bombeiro", "death", 4, 0),
	]
	var huwag_b := _alpha_bounds(huwag_casual_row[0])
	print("[LOTE 1] Huwag Casual idle_down=%s (foot y=%d)" % [str(huwag_b), huwag_b.end.y - 1])

	_blit_board_row(board, 0, huwag_casual_row, cell_step_x, cell_step_y, Color("#F2C94C"))
	_blit_board_row(board, 1, huwag_bfp_row, cell_step_x, cell_step_y, Color("#56CCF2"))

	var row_cursor := 2
	for item in results:
		for mode in ["normal", "distorted"]:
			var samples: Dictionary = item[mode]["samples"]
			var tag_col := Color("#6FCF97") if mode == "normal" else Color("#EB5757")
			var imgs: Array[Image] = [
				samples["idle_down"],
				samples["idle_up"],
				samples["idle_left"],
				samples["idle_right"],
				samples["talk_down"],
				samples["attack_down"],
				samples["attack_left"],
				samples["hurt_down"],
				samples["death_down"],
			]
			_blit_board_row(board, row_cursor, imgs, cell_step_x, cell_step_y, tag_col)
			row_cursor += 1

	board.save_png("%s/lote1_bfp_summary_board_1x.png" % ARTIFACT_DIR)
	var board_4x := board.duplicate()
	board_4x.resize(board_w * 4, board_h * 4, Image.INTERPOLATE_NEAREST)
	board_4x.save_png("%s/lote1_bfp_summary_board_4x.png" % ARTIFACT_DIR)

	# 2) Walk (Left 6f) + Talk (Down 4f) + Attack (Down 5f) Strip Board (4x)
	var strip_cols := 15
	var strip_rows := 5
	var sw := 16 + strip_cols * cell_step_x + 10
	var sh := 16 + strip_rows * cell_step_y + 10
	var sboard := Image.create(sw, sh, false, Image.FORMAT_RGBA8)
	sboard.fill(FLOOR_COLOR)

	var strip_sources: Array = [
		[results[0]["normal"], Color("#6FCF97")], # Cap. Reyes N
		[results[1]["normal"], Color("#F2C94C")], # Ato N
		[results[1]["distorted"], Color("#EB5757")], # Ato D
		[results[2]["normal"], Color("#56CCF2")], # Santos N
		[results[3]["distorted"], Color("#BB6BD9")], # Maria D
	]
	for r_idx in range(strip_sources.size()):
		var res: Dictionary = strip_sources[r_idx][0]
		var dot_col: Color = strip_sources[r_idx][1]
		var strip_imgs: Array[Image] = []
		for anim_name in ["walk", "talk", "attack"]:
			var sh_img: Image = res["sheets"][anim_name]["image"]
			var f_cnt: int = int(res["sheets"][anim_name]["frames"])
			var row_dir := 2 if anim_name == "walk" else 0
			for f in range(f_cnt):
				var cell_img := Image.create(48, 48, false, Image.FORMAT_RGBA8)
				cell_img.blit_rect(sh_img, Rect2i(f * 48, row_dir * 48, 48, 48), Vector2i.ZERO)
				strip_imgs.append(cell_img)
		_blit_board_row(sboard, r_idx, strip_imgs, cell_step_x, cell_step_y, dot_col)

	var sboard_4x := sboard.duplicate()
	sboard_4x.resize(sw * 4, sh * 4, Image.INTERPOLATE_NEAREST)
	sboard_4x.save_png("%s/lote1_bfp_anim_strip_4x.png" % ARTIFACT_DIR)

	# 3) Dedicated Bespoke Attacks Showcase (Down f0..f4 | Left f0..f4 across all 4 NPCs + Distorted)
	var atk_cols := 10
	var atk_rows := 6
	var aw := 16 + atk_cols * cell_step_x + 10
	var ah := 16 + atk_rows * cell_step_y + 10
	var aboard := Image.create(aw, ah, false, Image.FORMAT_RGBA8)
	aboard.fill(FLOOR_COLOR)

	var atk_sources: Array = [
		[results[0]["normal"], Color("#6FCF97")], # Reyes N (Command Sweep)
		[results[1]["normal"], Color("#F2C94C")], # Ato N (Axe Slam)
		[results[1]["distorted"], Color("#EB5757")], # Ato D (Cracked + Crimson Axe Slam)
		[results[2]["normal"], Color("#56CCF2")], # Santos N (Halligan Hook)
		[results[3]["normal"], Color("#9B51E0")], # Maria N (Scalpel Thrust)
		[results[3]["distorted"], Color("#FF4D6D")], # Maria D (Arterial Scalpel Thrust)
	]
	for r_idx in range(atk_sources.size()):
		var res: Dictionary = atk_sources[r_idx][0]
		var dot_col: Color = atk_sources[r_idx][1]
		var sh_img: Image = res["sheets"]["attack"]["image"]
		var atk_imgs: Array[Image] = []
		for row_dir in [0, 2]: # Down 5f + Left 5f
			for f in range(5):
				var cell_img := Image.create(48, 48, false, Image.FORMAT_RGBA8)
				cell_img.blit_rect(sh_img, Rect2i(f * 48, row_dir * 48, 48, 48), Vector2i.ZERO)
				atk_imgs.append(cell_img)
		_blit_board_row(aboard, r_idx, atk_imgs, cell_step_x, cell_step_y, dot_col)

	var aboard_4x := aboard.duplicate()
	aboard_4x.resize(aw * 4, ah * 4, Image.INTERPOLATE_NEAREST)
	aboard_4x.save_png("%s/lote1_bfp_attacks_4x.png" % ARTIFACT_DIR)


func _blit_board_row(board: Image, row_idx: int, imgs: Array[Image], step_x: int, step_y: int, tag_col: Color) -> void:
	var base_y := 12 + row_idx * step_y
	for dy in range(4, 44):
		for dx in range(3, 6):
			board.set_pixel(dx, base_y + dy, tag_col)
	for rx in [8, board.get_width() - 6]:
		board.set_pixel(rx, base_y + 39, tag_col)
		board.set_pixel(rx + 1, base_y + 39, tag_col)

	for c_idx in range(imgs.size()):
		var img: Image = imgs[c_idx]
		var dst_x := 14 + c_idx * step_x
		for gx in range(18, 30):
			board.set_pixel(dst_x + gx, base_y + 40, FLOOR_SEAM)
		board.blend_rect(img, Rect2i(0, 0, 48, 48), Vector2i(dst_x, base_y))
