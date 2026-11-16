extends SceneTree

## Gera TODOS os spritesheets corrompidos da Etapa 2 em STAGING (corrupted_v4_preview/)
## e exporta as pranchas comparativas para revisão do usuário antes de integrar nas cenas ativas.

const Builder := preload("res://scripts/tools/npc_pixel_rig/npc_sprite_builder.gd")
const CBuilder := preload("res://scripts/tools/corrupted_v4/corrupted_v4_builder.gd")
const Designs := preload("res://scripts/tools/corrupted_v4/corrupted_v4_designs.gd")

const STAGING_ROOT := "res://assets/sprites/corrupted_v4_preview"
const ARTIFACT_DIR := "C:/Users/SnyX/.gemini/antigravity/brain/6f04634a-b7d4-4d6f-9c20-24b6fdf404a0"

const BG_FLOOR := Color("#1E171D")
const BG_SEAM := Color("#2B212A")
const CELL_BG := Color("#281F27")
const CELL_BORDER := Color("#3D303B")
const FOOT_LINE := Color("#543845")


func _init() -> void:
	var built := {}
	for npc_id in Designs.ALL_IDS:
		built[npc_id] = _build_one_corrupted(npc_id)
	_export_boards(built)
	print("[Etapa2] Staging gerado (12 entidades) e pranchas exportadas em ", ARTIFACT_DIR)
	quit()


func _build_one_corrupted(npc_id: String) -> Dictionary:
	var spec := Designs.get_spec(npc_id)
	var is_child := bool(spec.get("child", false))
	var anim_list: Array = Builder.CHILD_ANIMS if is_child else Builder.ADULT_ANIMS
	var base_dir := "%s/%s" % [STAGING_ROOT, npc_id]
	var var_dir := "%s/distorted" % base_dir
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(var_dir))

	var sheets_info := {}
	var samples := {}

	for anim_cfg in anim_list:
		var aname: String = str(anim_cfg["name"])
		var fcount: int = int(anim_cfg["frames"])
		var sheet := Image.create(CBuilder.CELL_W * fcount, CBuilder.CELL_H * CBuilder.DIRS.size(), false, Image.FORMAT_RGBA8)
		sheet.fill(Color(0, 0, 0, 0))

		for d_idx in range(CBuilder.DIRS.size()):
			var dname: String = CBuilder.DIRS[d_idx]
			for f_idx in range(fcount):
				var fr := Designs.render_frame(npc_id, dname, aname, f_idx)
				sheet.blit_rect(fr, Rect2i(0, 0, 48, 48), Vector2i(f_idx * 48, d_idx * 48))
				if aname == "idle" and f_idx == 0:
					samples["idle_%s" % dname] = fr
				elif aname == "talk" and f_idx == 2 and dname == "down":
					samples["talk_down"] = fr
				elif aname == "attack" and f_idx == 2 and dname in ["down", "left"]:
					samples["attack_%s" % dname] = fr
				elif aname == "hurt" and f_idx == 0 and dname == "down":
					samples["hurt_down"] = fr
				elif aname == "death" and f_idx == 5 and dname == "down":
					samples["death_down"] = fr

		var png_res := "%s/spritesheet_%s.png" % [var_dir, aname]
		var png_abs := ProjectSettings.globalize_path(png_res)
		sheet.save_png(png_abs)
		Builder._write_pixel_art_import(png_res, png_abs)
		sheets_info[aname] = {
			"path": png_res,
			"frames": fcount,
			"fps": float(anim_cfg["fps"]),
			"loop": bool(anim_cfg["loop"]),
			"image": sheet,
		}

	var tres_path := "%s/%s_distorted_spriteframes.tres" % [base_dir, npc_id]
	Builder._write_spriteframes_tres(tres_path, sheets_info, anim_list)
	return {
		"npc_id": npc_id,
		"label": spec.get("label", npc_id),
		"is_child": is_child,
		"sheets": sheets_info,
		"samples": samples,
	}


func _load_cell(res_path: String, col: int, row: int) -> Image:
	var abs_p := ProjectSettings.globalize_path(res_path)
	if not FileAccess.file_exists(abs_p):
		return Image.create(48, 48, false, Image.FORMAT_RGBA8)
	var src := Image.load_from_file(abs_p)
	var out := Image.create(48, 48, false, Image.FORMAT_RGBA8)
	out.blit_rect(src, Rect2i(col * 48, row * 48, 48, 48), Vector2i.ZERO)
	return out


func _make_na_cell() -> Image:
	var img := Image.create(48, 48, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for i in range(14):
		img.set_pixel(17 + i, 17 + i, Color("#613E4C"))
		img.set_pixel(30 - i, 17 + i, Color("#613E4C"))
	return img


func _blit_row(board: Image, row_idx: int, cells: Array[Image], badge_col: Color) -> void:
	var step := 52
	var y0 := 10 + row_idx * step
	# Marcador colorido de categoria à esquerda
	for dy in range(10, 38):
		for dx in range(4):
			board.set_pixel(5 + dx, y0 + dy, badge_col)

	for col_idx in range(cells.size()):
		var x0 := 14 + col_idx * step
		for py in range(48):
			for px in range(48):
				var is_edge := (px == 0 or py == 0 or px == 47 or py == 47)
				if is_edge:
					board.set_pixel(x0 + px, y0 + py, CELL_BORDER)
				elif py == 39:
					board.set_pixel(x0 + px, y0 + py, FOOT_LINE)
				else:
					board.set_pixel(x0 + px, y0 + py, CELL_BG)
		var cell := cells[col_idx]
		board.blit_rect(cell, Rect2i(0, 0, 48, 48), Vector2i(x0, y0))


func _make_huwag_row() -> Array[Image]:
	return [
		_load_cell("res://assets/sprites/huwag_v3/casual/spritesheet_idle.png", 0, 0),
		_load_cell("res://assets/sprites/huwag_v3/casual/spritesheet_idle.png", 0, 0),
		_load_cell("res://assets/sprites/huwag_v3/casual/spritesheet_idle.png", 0, 1),
		_load_cell("res://assets/sprites/huwag_v3/casual/spritesheet_idle.png", 0, 2),
		_load_cell("res://assets/sprites/huwag_v3/casual/spritesheet_idle.png", 0, 3),
		_load_cell("res://assets/sprites/huwag_v3/casual/spritesheet_idle.png", 1, 0),
		_load_cell("res://assets/sprites/huwag_v3/casual/spritesheet_attack.png", 2, 0),
		_load_cell("res://assets/sprites/huwag_v3/casual/spritesheet_attack.png", 2, 2),
		_load_cell("res://assets/sprites/huwag_v3/casual/spritesheet_hurt.png", 0, 0),
		_load_cell("res://assets/sprites/huwag_v3/casual/spritesheet_death.png", 4, 0),
	]


func _save_board(board: Image, base_name: String, scale_up: int = 3) -> void:
	var p1 := "%s/%s_1x.png" % [ARTIFACT_DIR, base_name]
	board.save_png(p1)
	var up := board.duplicate()
	up.resize(board.get_width() * scale_up, board.get_height() * scale_up, Image.INTERPOLATE_NEAREST)
	up.save_png("%s/%s_%dx.png" % [ARTIFACT_DIR, base_name, scale_up])


func _export_boards(built: Dictionary) -> void:
	var na := _make_na_cell()
	var huwag := _make_huwag_row()

	# Prancha A: Grupo BFP + Enfermeira Maria + Vulto Calcinado (Huwag Ref + 5 criaturas)
	var group_a := [
		["cap_reyes", Color("#56CCF2")],
		["bombeiro_ato", Color("#F2C94C")],
		["bombeiro_santos", Color("#F2994A")],
		["enfermeira_maria", Color("#EB5757")],
		["vulto_bosque", Color("#FF3B4D")],
	]
	_render_group_board(built, huwag, na, group_a, "etapa2_corrupted_bfp_vulto")

	# Prancha B: Civis + Idosos + Toby (Huwag Ref + 7 criaturas)
	var group_b := [
		["aling_nena", Color("#6FCF97")],
		["kuya_ben", Color("#56CCF2")],
		["mang_tomas", Color("#F2C94C")],
		["mang_carding", Color("#4ECDC4")],
		["senhora_luningning", Color("#BB6BD9")],
		["lola_rosa", Color("#6FCF97")],
		["toby", Color("#EB5757")],
	]
	_render_group_board(built, huwag, na, group_b, "etapa2_corrupted_civis_toby")

	# Prancha C: Tiras de Movimento (Walk L 6f + Talk D 4f + Attack/Hurt D 4f + Death 3f)
	var strip_ids := [
		["cap_reyes", Color("#56CCF2")],
		["bombeiro_ato", Color("#F2C94C")],
		["enfermeira_maria", Color("#EB5757")],
		["aling_nena", Color("#6FCF97")],
		["mang_tomas", Color("#F2C94C")],
		["toby", Color("#EB5757")],
		["senhora_luningning", Color("#BB6BD9")],
		["vulto_bosque", Color("#FF3B4D")],
	]
	var step := 52
	var sboard := Image.create(18 + 14 * step, 18 + strip_ids.size() * step, false, Image.FORMAT_RGBA8)
	sboard.fill(BG_FLOOR)
	for r in range(strip_ids.size()):
		var nid: String = strip_ids[r][0]
		var dot: Color = strip_ids[r][1]
		var info: Dictionary = built[nid]
		var sheets: Dictionary = info["sheets"]
		var cells: Array[Image] = []
		# 6 frames Walk Left
		var wimg: Image = sheets["walk"]["image"]
		for f in range(6):
			var fr := Image.create(48, 48, false, Image.FORMAT_RGBA8)
			fr.blit_rect(wimg, Rect2i(f * 48, 2 * 48, 48, 48), Vector2i.ZERO)
			cells.append(fr)
		# 3 frames Talk Down
		var timg: Image = sheets["talk"]["image"]
		for f in [0, 1, 2]:
			var fr := Image.create(48, 48, false, Image.FORMAT_RGBA8)
			fr.blit_rect(timg, Rect2i(f * 48, 0, 48, 48), Vector2i.ZERO)
			cells.append(fr)
		# 3 frames Attack (ou Hurt se Toby)
		var is_child: bool = bool(info["is_child"])
		var aimg: Image = sheets["hurt" if is_child else "attack"]["image"]
		for f in [0, 1, 2]:
			var fr := Image.create(48, 48, false, Image.FORMAT_RGBA8)
			fr.blit_rect(aimg, Rect2i(f * 48, 0, 48, 48), Vector2i.ZERO)
			cells.append(fr)
		# 2 frames Death (ou Hurt/NA para Toby)
		if is_child:
			cells.append(na)
			cells.append(na)
		else:
			var dimg: Image = sheets["death"]["image"]
			for f in [1, 5]:
				var fr := Image.create(48, 48, false, Image.FORMAT_RGBA8)
				fr.blit_rect(dimg, Rect2i(f * 48, 0, 48, 48), Vector2i.ZERO)
				cells.append(fr)
		_blit_row(sboard, r, cells, dot)
	_save_board(sboard, "etapa2_corrupted_anim_strips", 3)


func _render_group_board(built: Dictionary, huwag: Array[Image], na: Image, group: Array, out_name: String) -> void:
	var step := 52
	var cols := 10
	var rows := 1 + group.size()
	var board := Image.create(18 + cols * step, 18 + rows * step, false, Image.FORMAT_RGBA8)
	board.fill(BG_FLOOR)
	for y in range(0, board.get_height(), step):
		for x in range(board.get_width()):
			board.set_pixel(x, y, BG_SEAM)

	_blit_row(board, 0, huwag, Color("#F5C84B"))
	for i in range(group.size()):
		var nid: String = group[i][0]
		var badge: Color = group[i][1]
		var norm_idle := _load_cell("res://assets/sprites/npcs/%s/normal/spritesheet_idle.png" % nid, 0, 0)
		if nid == "vulto_bosque":
			norm_idle = _load_cell("res://assets/sprites/npcs/vulto_bosque/distorted/spritesheet_idle.png", 0, 0)
		var sm: Dictionary = built[nid]["samples"]
		var row_imgs: Array[Image] = [
			norm_idle,
			sm.get("idle_down", na),
			sm.get("idle_up", na),
			sm.get("idle_left", na),
			sm.get("idle_right", na),
			sm.get("talk_down", na),
			sm.get("attack_down", na),
			sm.get("attack_left", na),
			sm.get("hurt_down", na),
			sm.get("death_down", na),
		]
		_blit_row(board, i + 1, row_imgs, badge)
	_save_board(board, out_name, 3)
