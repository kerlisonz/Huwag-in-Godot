@tool
extends SceneTree

## Construtor nativo (Godot 4.7 GDScript) dos 3 novos Atlases 16×16 e TileSets .tres:
## - Agdangan (Calabarzon, Filipinas)
## - Floresta Densa e Opressiva
## - Interiores Detalhados
## Gera variantes normal (Ato 1/2), distorted (Ato 2 Dose Alta) e act3 (Ato 3 sem filtro).

const P = preload("res://scripts/tools/v2_tilesets/atlas_painter.gd")
const Props = preload("res://scripts/tools/v2_tilesets/agdangan_pixel_props.gd")
const Cat = preload("res://scripts/levels/v2_tile_catalog.gd")

const OUT_DIR := "res://assets/tilesets/v2"
const VARIANTS := ["normal", "distorted", "act3"]


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	var phase := "all"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--phase="):
			phase = arg.trim_prefix("--phase=")

	var imgs := {
		"dark_forest": P.load_rgba("res://assets/third_party/oga_16x16_jrpg_forest/dark_forest.png"),
		"town_rpg": P.load_rgba("res://assets/third_party/town_rpg_pack/graphics/transparent-bg-tiles.png"),
		"lpc_terrain": P.load_rgba("res://assets/third_party/lpc-tileset-16x16/tileset_basic_terrain.png"),
		"lpc_other": P.load_rgba("res://assets/third_party/lpc-tileset-16x16/tileset_other.png"),
		"lpc_water": P.load_rgba("res://assets/third_party/lpc-tileset-16x16/tileset_water_animated.png"),
		"serene": P.load_rgba("res://assets/third_party/Serene_Village_revamped_v1.9/SERENE_VILLAGE_REVAMPED/Serene_Village_16x16.png"),
		"interior_oga": P.load_rgba("res://assets/third_party/tileset_16x16_interior/tileset_16x16_interior.png"),
		"room_builder": P.load_rgba("res://assets/third_party/Modern_Interiors_Free_v2.2/Modern tiles_Free/Interiors_free/16x16/Room_Builder_free_16x16.png"),
		"interiors_modern": P.load_rgba("res://assets/third_party/Modern_Interiors_Free_v2.2/Modern tiles_Free/Interiors_free/16x16/Interiors_free_16x16.png"),
	}

	for v in VARIANTS:
		var f_res := _compose_forest_atlas(imgs, v)
		_write_phase_outputs("forest_v2_%s" % v, f_res["image"], f_res["spec"], phase)

		var t_res := _compose_town_atlas(imgs, v)
		_write_phase_outputs("agdangan_town_v2_%s" % v, t_res["image"], t_res["spec"], phase)

		var i_res := _compose_interior_atlas(imgs, v)
		_write_phase_outputs("interiors_v2_%s" % v, i_res["image"], i_res["spec"], phase)

	if phase == "images" or phase == "all":
		_export_preview_sheet()

	print("Tilesets v2 processados (phase=%s) em %s" % [phase, OUT_DIR])
	quit(0)


func _write_phase_outputs(name_base: String, img: Image, spec: Dictionary, phase: String) -> void:
	var png_res := "%s/%s.png" % [OUT_DIR, name_base]
	if phase == "images" or phase == "all":
		img.save_png(ProjectSettings.globalize_path(png_res))
	if phase == "tilesets" or phase == "all":
		P.save_atlas_and_tileset(OUT_DIR, name_base, img, spec)


# ==============================================================================
# 1. FLORESTA DENSA E OPRESSIVA (32x37 = 512x592)
# ==============================================================================
func _compose_forest_atlas(imgs: Dictionary, variant: String) -> Dictionary:
	var img := P.create_sheet(32, 37)
	var df: Image = imgs["dark_forest"]
	var tr: Image = imgs["town_rpg"]
	var lt: Image = imgs["lpc_terrain"]
	var lo: Image = imgs["lpc_other"]
	var lw: Image = imgs["lpc_water"]

	# Rows 0..1: Solos sombrios, lama, agulhas de pinheiro, mato alto e água animada
	P.blit_tiles(img, df, Vector2i(0, 12), Vector2i(0, 0), Vector2i(3, 2), variant, 0.78, 0.88, Color("#DCEBE0"), true)
	P.blit_tiles(img, lt, Vector2i(0, 15), Vector2i(3, 0), Vector2i(3, 1), variant, 0.72, 0.78, Color("#D6CFC6"))
	P.blit_tiles(img, df, Vector2i(14, 0), Vector2i(3, 1), Vector2i(2, 1), variant, 0.78, 0.86, Color("#D8D0C4"), true)
	P.blit_tiles(img, lt, Vector2i(0, 16), Vector2i(5, 1), Vector2i(1, 1), variant, 0.75, 0.78)
	P.blit_tiles(img, lt, Vector2i(6, 6), Vector2i(6, 0), Vector2i(3, 2), variant, 0.72, 0.76, Color("#CEDFD2"))
	P.blit_tiles(img, lt, Vector2i(0, 24), Vector2i(9, 0), Vector2i(3, 2), variant, 0.76, 0.76, Color("#C6DBD0"))

	# Água animada horizontal (3 frames: cols 12..14 e cols 15..17) + cachoeira 1x3 (col 18)
	P.blit_tiles(img, lw, Vector2i(18, 0), Vector2i(12, 0), Vector2i(3, 1), variant, 0.68, 0.72, Color("#9AC2CE"))
	P.blit_tiles(img, lw, Vector2i(21, 0), Vector2i(15, 0), Vector2i(3, 1), variant, 0.68, 0.76, Color("#A4CCD6"))
	P.blit_tiles(img, tr, Vector2i(11, 8), Vector2i(18, 0), Vector2i(1, 3), variant, 0.74, 0.78, Color("#9AC2CE"))

	# Rows 2..4: Blocos 3x3 de transição + sombras + cercas + pontes
	P.blit_tiles(img, lt, Vector2i(0, 12), Vector2i(0, 2), Vector2i(3, 3), variant, 0.74, 0.78)
	P.blit_tiles(img, lw, Vector2i(0, 6), Vector2i(3, 2), Vector2i(3, 3), variant, 0.68, 0.72, Color("#9CBFC8"))
	P.blit_tiles(img, lt, Vector2i(9, 9), Vector2i(6, 2), Vector2i(3, 3), variant, 0.70, 0.72)
	P.add_shadow_strips(img, Vector2i(9, 2), Vector2i(10, 2), Vector2i(11, 2), Vector2i(12, 2), variant)
	P.blit_tiles(img, df, Vector2i(6, 12), Vector2i(13, 2), Vector2i(6, 2), variant, 0.78, 0.85, Color.WHITE, true)
	P.blit_tiles(img, df, Vector2i(12, 8), Vector2i(19, 2), Vector2i(2, 4), variant, 0.80, 0.86, Color.WHITE, true)
	P.blit_tiles(img, df, Vector2i(12, 12), Vector2i(21, 2), Vector2i(2, 2), variant, 0.80, 0.86, Color.WHITE, true)

	# Rows 5..12: Penhascos musgosos & gruta (dark_forest 8x8 -> 0..7, 5..12) + pedras (town_rpg) + clutter
	P.blit_tiles(img, df, Vector2i(0, 0), Vector2i(0, 5), Vector2i(8, 8), variant, 0.78, 0.84, Color("#D2DAD8"), true)
	P.blit_tiles(img, tr, Vector2i(0, 10), Vector2i(8, 5), Vector2i(3, 2), variant, 0.72, 0.78, Color("#C6CED2"))
	P.blit_tiles(img, df, Vector2i(6, 6), Vector2i(12, 5), Vector2i(2, 2), variant, 0.78, 0.85, Color.WHITE, true)
	P.blit_tiles(img, df, Vector2i(14, 6), Vector2i(14, 5), Vector2i(2, 2), variant, 0.82, 0.86, Color.WHITE, true)
	P.blit_tiles(img, df, Vector2i(14, 4), Vector2i(16, 5), Vector2i(2, 2), variant, 0.76, 0.82, Color.WHITE, true)
	P.blit_tiles(img, df, Vector2i(14, 12), Vector2i(18, 5), Vector2i(2, 2), variant, 0.76, 0.82, Color.WHITE, true)
	P.blit_tiles(img, df, Vector2i(8, 8), Vector2i(12, 7), Vector2i(2, 4), variant, 0.76, 0.82, Color.WHITE, true)
	P.blit_tiles(img, tr, Vector2i(1, 6), Vector2i(24, 5), Vector2i(3, 2), variant, 0.75, 0.80)

	# Rows 13..18: Árvores multi-tile com Y-sort na base
	P.blit_tiles(img, df, Vector2i(8, 1), Vector2i(0, 13), Vector2i(5, 6), variant, 0.78, 0.84, Color("#D4E2D8"), true)
	P.blit_tiles(img, lo, Vector2i(11, 10), Vector2i(5, 13), Vector2i(3, 6), variant, 0.74, 0.80, Color("#CFE0D4"))
	P.blit_tiles(img, lo, Vector2i(14, 10), Vector2i(8, 13), Vector2i(3, 6), variant, 0.76, 0.78, Color("#D6C6C2"))
	P.blit_tiles(img, tr, Vector2i(8, 2), Vector2i(11, 13), Vector2i(1, 6), variant, 0.76, 0.82, Color("#D2E0D4"))
	P.blit_tiles(img, lo, Vector2i(11, 5), Vector2i(13, 13), Vector2i(4, 5), variant, 0.74, 0.80, Color("#CEE0D2"))
	P.blit_tiles(img, df, Vector2i(6, 8), Vector2i(17, 13), Vector2i(2, 2), variant, 0.80, 0.84, Color.WHITE, true)
	P.blit_tiles(img, df, Vector2i(15, 8), Vector2i(19, 13), Vector2i(1, 3), variant, 0.80, 0.84, Color.WHITE, true)
	P.blit_tiles(img, lo, Vector2i(13, 0), Vector2i(20, 13), Vector2i(3, 1), variant, 0.78, 0.82)
	P.blit_tiles(img, lo, Vector2i(11, 4), Vector2i(23, 13), Vector2i(1, 2), variant, 0.74, 0.80)
	P.blit_tiles(img, df, Vector2i(10, 10), Vector2i(25, 13), Vector2i(2, 2), variant, 0.78, 0.84, Color.WHITE, true)

	# Rows 19..36: Árvore Ancestral gigante (14x18) + coqueiro de borda tropical (3x6)
	P.blit_tiles(img, df, Vector2i(0, 17), Vector2i(0, 19), Vector2i(14, 18), variant, 0.78, 0.82, Color("#CFE0D4"), true)
	P.clear_tiles_rect(img, Vector2i(0, 19), Vector2i(2, 1))
	P.clear_tiles_rect(img, Vector2i(0, 36), Vector2i(4, 1))
	Props.draw_coconut_palm(img, Vector2i(15, 19), -1, variant)

	var solid: Array[Vector2i] = []
	var water: Array[Vector2i] = []
	var blocks_light: Array[Vector2i] = []
	var surface_map: Dictionary = {}

	# Penhascos e cercas sólidos
	for x in range(13, 19):
		solid.append(Vector2i(x, 2))
		solid.append(Vector2i(x, 3))
		surface_map[Vector2i(x, 2)] = "wood"
		surface_map[Vector2i(x, 3)] = "wood"
	for y in range(5, 13):
		for x in range(0, 8):
			# Deixa interior central de platô (1..3, 6..8) caminhável; bordas e paredes sólidas
			if y >= 8 or x == 0 or x >= 4 or y == 5:
				solid.append(Vector2i(x, y))
				blocks_light.append(Vector2i(x, y))
				surface_map[Vector2i(x, y)] = "stone"
	for y in range(5, 8):
		for x in range(8, 12):
			solid.append(Vector2i(x, y))
			blocks_light.append(Vector2i(x, y))
			surface_map[Vector2i(x, y)] = "stone"
	for y in range(2, 5):
		for x in range(3, 9):
			if x <= 5:
				water.append(Vector2i(x, y))
				if x == 4 and y == 3:
					solid.append(Vector2i(x, y))
			else:
				solid.append(Vector2i(x, y))
	for x in range(3, 6):
		surface_map[Vector2i(x, 0)] = "mud"
		surface_map[Vector2i(x, 1)] = "mud"
	for x in range(19, 23):
		for y in range(2, 6):
			surface_map[Vector2i(x, y)] = "wood"

	var trunk_box := PackedVector2Array([Vector2(-7, -4), Vector2(7, -4), Vector2(7, 8), Vector2(-7, 8)])
	var big_box := PackedVector2Array([Vector2(-12, -6), Vector2(12, -6), Vector2(12, 8), Vector2(-12, 8)])
	var ancient_box := PackedVector2Array([Vector2(-24, -6), Vector2(24, -6), Vector2(24, 8), Vector2(-24, 8)])
	var full_2x2 := PackedVector2Array([Vector2(-14, -10), Vector2(14, -10), Vector2(14, 8), Vector2(-14, 8)])

	var spec := {
		"solid_cells": solid,
		"water_cells": water,
		"light_block_cells": blocks_light,
		"surface_map": surface_map,
		"animated_tiles": [
			{"coord": Vector2i(12, 0), "frames": 3, "frame_duration": 0.36, "solid": true, "poly": PackedVector2Array([Vector2(-8, -8), Vector2(8, -8), Vector2(8, 8), Vector2(-8, 8)]), "surface": "water", "is_water": true},
			{"coord": Vector2i(15, 0), "frames": 3, "frame_duration": 0.30, "solid": true, "poly": PackedVector2Array([Vector2(-8, -8), Vector2(8, -8), Vector2(8, 8), Vector2(-8, 8)]), "surface": "water", "is_water": true},
		],
		"multi_tiles": [
			{"coord": Vector2i(0, 13), "size": Vector2i(5, 6), "origin_x": 0, "y_sort_origin": 6, "collision_poly": big_box, "blocks_light": true, "surface": "wood"},
			{"coord": Vector2i(5, 13), "size": Vector2i(3, 6), "origin_x": 0, "y_sort_origin": 6, "collision_poly": trunk_box, "blocks_light": true, "surface": "wood"},
			{"coord": Vector2i(8, 13), "size": Vector2i(3, 6), "origin_x": 0, "y_sort_origin": 6, "collision_poly": trunk_box, "blocks_light": true, "surface": "wood"},
			{"coord": Vector2i(11, 13), "size": Vector2i(1, 6), "origin_x": 0, "y_sort_origin": 6, "collision_poly": trunk_box, "blocks_light": true, "surface": "wood"},
			{"coord": Vector2i(13, 13), "size": Vector2i(4, 5), "origin_x": 8, "y_sort_origin": 6, "collision_poly": trunk_box, "blocks_light": true, "surface": "wood"},
			{"coord": Vector2i(17, 13), "size": Vector2i(2, 2), "origin_x": 8, "y_sort_origin": 6, "collision_poly": full_2x2, "surface": "wood"},
			{"coord": Vector2i(19, 13), "size": Vector2i(1, 3), "origin_x": 0, "y_sort_origin": 4, "collision_poly": PackedVector2Array([Vector2(-6, -24), Vector2(6, -24), Vector2(6, 8), Vector2(-6, 8)]), "surface": "wood"},
			{"coord": Vector2i(20, 13), "size": Vector2i(3, 1), "origin_x": 0, "y_sort_origin": 4, "collision_poly": PackedVector2Array([Vector2(-22, -6), Vector2(22, -6), Vector2(22, 6), Vector2(-22, 6)]), "surface": "wood"},
			{"coord": Vector2i(23, 13), "size": Vector2i(1, 2), "origin_x": 0, "y_sort_origin": 6, "collision_poly": trunk_box, "surface": "prop"},
			{"coord": Vector2i(25, 13), "size": Vector2i(2, 2), "origin_x": 8, "y_sort_origin": 6, "collision_poly": full_2x2, "surface": "stone"},
			{"coord": Vector2i(0, 19), "size": Vector2i(14, 18), "origin_x": 8, "y_sort_origin": 6, "collision_poly": ancient_box, "blocks_light": true, "surface": "wood"},
			{"coord": Vector2i(15, 19), "size": Vector2i(3, 6), "origin_x": 0, "y_sort_origin": 6, "collision_poly": trunk_box, "surface": "wood"},
		],
	}
	return {"image": img, "spec": spec}


# ==============================================================================
# 2. CIDADE COSTEIRA DE AGDANGAN, CALABARZON (32x28 = 512x448)
# ==============================================================================
func _compose_town_atlas(imgs: Dictionary, variant: String) -> Dictionary:
	var img := P.create_sheet(32, 28)
	var sv: Image = imgs["serene"]
	var tr: Image = imgs["town_rpg"]
	var lw: Image = imgs["lpc_water"]

	# Rows 0..1: Estradas asfalto, quadra, faixa, poças + grama/areia/pier Serene + mar animado + sombras
	Props.draw_road_and_plaza_tiles(img, Vector2i(0, 0), variant)
	P.blit_tiles(img, sv, Vector2i(4, 0), Vector2i(8, 0), Vector2i(6, 2), variant, 0.78, 0.88, Color("#DCE6E2"))
	P.blit_tiles(img, sv, Vector2i(16, 4), Vector2i(14, 0), Vector2i(2, 2), variant, 0.78, 0.86, Color("#DDD6CC"))
	P.blit_tiles(img, sv, Vector2i(10, 4), Vector2i(16, 0), Vector2i(3, 2), variant, 0.80, 0.88)
	P.blit_tiles(img, lw, Vector2i(18, 0), Vector2i(19, 0), Vector2i(3, 1), variant, 0.72, 0.78, Color("#9CC8D6"))
	P.blit_tiles(img, lw, Vector2i(21, 0), Vector2i(22, 0), Vector2i(3, 1), variant, 0.72, 0.82, Color("#AED6DF"))
	P.add_shadow_strips(img, Vector2i(25, 0), Vector2i(26, 0), Vector2i(27, 0), Vector2i(28, 0), variant)

	# Row 2: Paredes provinciais filipinas & telhados yero (zinco)
	Props.draw_modular_filipino_buildings(img, Vector2i(0, 2), Vector2i(7, 2), variant)

	# Row 3..4: Cercas Serene + floreiras/placas Serene + barris/caixotes + mureta/escada costeira
	P.blit_tiles(img, sv, Vector2i(5, 15), Vector2i(0, 3), Vector2i(3, 2), variant, 0.80, 0.86)
	P.blit_tiles(img, sv, Vector2i(4, 18), Vector2i(6, 3), Vector2i(4, 2), variant, 0.80, 0.86)
	P.blit_tiles(img, tr, Vector2i(8, 8), Vector2i(10, 3), Vector2i(2, 1), variant, 0.82, 0.88)
	P.blit_tiles(img, sv, Vector2i(6, 13), Vector2i(12, 3), Vector2i(2, 2), variant, 0.82, 0.88)
	P.blit_tiles(img, sv, Vector2i(1, 7), Vector2i(0, 15), Vector2i(4, 4), variant, 0.76, 0.84)

	# Hidrante BFP (27, 5 -> 1x2) & Banco de Praça (28, 5 -> 2x1)
	var hx := 27 * 16
	var hy := 5 * 16
	P.rect_px(img, hx + 5, hy + 12, 6, 17, P.grade_color(Color("#12121A"), variant))
	P.rect_px(img, hx + 6, hy + 13, 4, 14, P.grade_color(Color("#CC2C28"), variant))
	P.rect_px(img, hx + 4, hy + 17, 8, 3, P.grade_color(Color("#E65C48"), variant))
	var bx := 28 * 16
	P.rect_px(img, bx + 2, hy + 5, 28, 9, P.grade_color(Color("#12121A"), variant))
	P.rect_px(img, bx + 3, hy + 6, 26, 4, P.grade_color(Color("#7C5338"), variant))
	P.rect_px(img, bx + 4, hy + 10, 5, 4, P.grade_color(Color("#7A7E86"), variant))
	P.rect_px(img, bx + 23, hy + 10, 5, 4, P.grade_color(Color("#7A7E86"), variant))

	# Multi-tiles Agdangan Hero Assets (rows 5..15)
	Props.draw_coconut_palm(img, Vector2i(0, 5), -1, variant)
	Props.draw_coconut_palm(img, Vector2i(3, 5), 1, variant)
	Props.draw_banana_plant(img, Vector2i(6, 5), variant)
	Props.draw_street_lamppost(img, Vector2i(8, 5), false, variant)
	Props.draw_street_lamppost(img, Vector2i(9, 5), true, variant)
	Props.draw_sari_sari_store(img, Vector2i(10, 5), variant)
	Props.draw_provincial_house(img, Vector2i(15, 5), Color("#636B78"), variant)
	Props.draw_provincial_house(img, Vector2i(21, 5), Color("#7D442B"), variant)
	Props.draw_bfp_fire_truck(img, Vector2i(0, 12), variant)
	Props.draw_tricycle_and_banca(img, Vector2i(5, 12), Vector2i(8, 12), variant)
	# Árvores costeiras Serene recortadas em pixel para evitar corte nas bordas (3 unidades 2x3 em 12..17)
	P.blit_px_centered(img, sv, Rect2i(160, 194, 23, 44), Vector2i(12, 12), Vector2i(2, 3), variant, 0.78, 0.84, Color("#D2E2D8"))
	P.blit_px_centered(img, sv, Rect2i(184, 194, 25, 44), Vector2i(14, 12), Vector2i(2, 3), variant, 0.78, 0.84, Color("#D2E2D8"))
	P.blit_px_centered(img, sv, Rect2i(212, 194, 26, 44), Vector2i(16, 12), Vector2i(2, 3), variant, 0.78, 0.84, Color("#D2E2D8"))

	var solid: Array[Vector2i] = []
	var blocks_light: Array[Vector2i] = []
	var surface_map: Dictionary = {}

	for x in range(0, 4):
		surface_map[Vector2i(x, 0)] = "asphalt"
		surface_map[Vector2i(x, 1)] = "stone"
	for x in range(4, 8):
		surface_map[Vector2i(x, 0)] = "stone"
	for x in range(16, 19):
		surface_map[Vector2i(x, 0)] = "wood"
		surface_map[Vector2i(x, 1)] = "wood"
	for x in range(0, 7):
		solid.append(Vector2i(x, 2))
		blocks_light.append(Vector2i(x, 2))
		surface_map[Vector2i(x, 2)] = "stone"
	for x in range(0, 3):
		solid.append(Vector2i(x, 3))
		surface_map[Vector2i(x, 3)] = "wood"
	for x in range(0, 4):
		solid.append(Vector2i(x, 4))
		surface_map[Vector2i(x, 4)] = "stone"

	var trunk_box := PackedVector2Array([Vector2(-6, -4), Vector2(6, -4), Vector2(6, 8), Vector2(-6, 8)])
	var spec := {
		"solid_cells": solid,
		"water_cells": [],
		"light_block_cells": blocks_light,
		"surface_map": surface_map,
		"animated_tiles": [
			{"coord": Vector2i(19, 0), "frames": 3, "frame_duration": 0.36, "solid": true, "poly": PackedVector2Array([Vector2(-8, -8), Vector2(8, -8), Vector2(8, 8), Vector2(-8, 8)]), "surface": "water", "is_water": true},
			{"coord": Vector2i(22, 0), "frames": 3, "frame_duration": 0.30, "solid": true, "poly": PackedVector2Array([Vector2(-8, -8), Vector2(8, -8), Vector2(8, 8), Vector2(-8, 8)]), "surface": "water", "is_water": true},
		],
		"multi_tiles": [
			{"coord": Vector2i(0, 5), "size": Vector2i(3, 6), "origin_x": 0, "y_sort_origin": 6, "collision_poly": trunk_box, "surface": "wood"},
			{"coord": Vector2i(3, 5), "size": Vector2i(3, 6), "origin_x": 0, "y_sort_origin": 6, "collision_poly": trunk_box, "surface": "wood"},
			{"coord": Vector2i(6, 5), "size": Vector2i(2, 3), "origin_x": 8, "y_sort_origin": 6, "collision_poly": trunk_box, "surface": "prop"},
			{"coord": Vector2i(8, 5), "size": Vector2i(1, 5), "origin_x": 0, "y_sort_origin": 6, "collision_poly": PackedVector2Array([Vector2(-5, -2), Vector2(5, -2), Vector2(5, 8), Vector2(-5, 8)]), "surface": "stone"},
			{"coord": Vector2i(9, 5), "size": Vector2i(1, 5), "origin_x": 0, "y_sort_origin": 6, "collision_poly": PackedVector2Array([Vector2(-5, -2), Vector2(5, -2), Vector2(5, 8), Vector2(-5, 8)]), "surface": "stone"},
			{"coord": Vector2i(10, 5), "size": Vector2i(5, 4), "origin_x": 0, "y_sort_origin": 6, "collision_poly": PackedVector2Array([Vector2(-38, -22), Vector2(38, -22), Vector2(38, 8), Vector2(-38, 8)]), "blocks_light": true, "surface": "wood"},
			{"coord": Vector2i(15, 5), "size": Vector2i(6, 5), "origin_x": 8, "y_sort_origin": 6, "collision_poly": PackedVector2Array([Vector2(-44, -26), Vector2(44, -26), Vector2(44, 8), Vector2(-44, 8)]), "blocks_light": true, "surface": "stone"},
			{"coord": Vector2i(21, 5), "size": Vector2i(6, 5), "origin_x": 8, "y_sort_origin": 6, "collision_poly": PackedVector2Array([Vector2(-44, -26), Vector2(44, -26), Vector2(44, 8), Vector2(-44, 8)]), "blocks_light": true, "surface": "stone"},
			{"coord": Vector2i(27, 5), "size": Vector2i(1, 2), "origin_x": 0, "y_sort_origin": 6, "collision_poly": PackedVector2Array([Vector2(-5, -4), Vector2(5, -4), Vector2(5, 8), Vector2(-5, 8)]), "surface": "stone"},
			{"coord": Vector2i(28, 5), "size": Vector2i(2, 1), "origin_x": 8, "y_sort_origin": 4, "collision_poly": PackedVector2Array([Vector2(-6, -4), Vector2(22, -4), Vector2(22, 6), Vector2(-6, 6)]), "surface": "wood"},
			{"coord": Vector2i(0, 12), "size": Vector2i(5, 3), "origin_x": 0, "y_sort_origin": 6, "collision_poly": PackedVector2Array([Vector2(-36, -14), Vector2(36, -14), Vector2(36, 8), Vector2(-36, 8)]), "blocks_light": true, "surface": "stone"},
			{"coord": Vector2i(5, 12), "size": Vector2i(3, 2), "origin_x": 0, "y_sort_origin": 6, "collision_poly": PackedVector2Array([Vector2(-20, -8), Vector2(20, -8), Vector2(20, 8), Vector2(-20, 8)]), "surface": "stone"},
			{"coord": Vector2i(8, 12), "size": Vector2i(4, 2), "origin_x": 8, "y_sort_origin": 6, "collision_poly": PackedVector2Array([Vector2(-28, -8), Vector2(28, -8), Vector2(28, 8), Vector2(-28, 8)]), "surface": "wood"},
			{"coord": Vector2i(12, 12), "size": Vector2i(2, 3), "origin_x": 8, "y_sort_origin": 6, "collision_poly": trunk_box, "blocks_light": true, "surface": "wood"},
			{"coord": Vector2i(14, 12), "size": Vector2i(2, 3), "origin_x": 8, "y_sort_origin": 6, "collision_poly": trunk_box, "blocks_light": true, "surface": "wood"},
			{"coord": Vector2i(16, 12), "size": Vector2i(2, 3), "origin_x": 8, "y_sort_origin": 6, "collision_poly": trunk_box, "blocks_light": true, "surface": "wood"},
		],
	}
	return {"image": img, "spec": spec}


# ==============================================================================
# 3. INTERIORES DETALHADOS (32x20 = 512x320)
# ==============================================================================
func _compose_interior_atlas(imgs: Dictionary, variant: String) -> Dictionary:
	var img := P.create_sheet(32, 20)
	var rb: Image = imgs["room_builder"]
	var im: Image = imgs["interiors_modern"]
	var io: Image = imgs["interior_oga"]

	# Rows 0..1: Pisos, esteira Banig, sombras projetadas nas paredes e tapetes
	P.blit_tiles(img, rb, Vector2i(12, 14), Vector2i(0, 0), Vector2i(1, 2), variant, 0.80, 0.78)
	P.blit_tiles(img, rb, Vector2i(12, 6), Vector2i(1, 0), Vector2i(2, 2), variant, 0.80, 0.82)
	P.blit_tiles(img, rb, Vector2i(12, 12), Vector2i(3, 0), Vector2i(2, 2), variant, 0.78, 0.80)
	Props.draw_sawali_and_banig(img, Vector2i(0, 2), Vector2i(5, 0), variant)
	P.add_shadow_strips(img, Vector2i(8, 0), Vector2i(9, 0), Vector2i(10, 0), Vector2i(11, 0), variant)
	P.blit_tiles(img, io, Vector2i(3, 5), Vector2i(12, 0), Vector2i(2, 2), variant, 0.80, 0.84)

	# Rows 2..4: Paredes internas (Sawali já desenhada em 0..2,2) + Room_Builder madeira/BFP/enfermaria + portas/janelas
	P.blit_tiles(img, rb, Vector2i(12, 0), Vector2i(3, 2), Vector2i(1, 2), variant, 0.78, 0.75)
	P.blit_tiles(img, rb, Vector2i(0, 13), Vector2i(4, 2), Vector2i(2, 2), variant, 0.80, 0.82)
	P.blit_tiles(img, rb, Vector2i(0, 17), Vector2i(6, 2), Vector2i(2, 2), variant, 0.80, 0.84)
	P.blit_tiles(img, rb, Vector2i(0, 19), Vector2i(8, 2), Vector2i(2, 2), variant, 0.80, 0.86)
	P.blit_tiles(img, io, Vector2i(11, 0), Vector2i(10, 2), Vector2i(4, 3), variant, 0.82, 0.86)
	P.blit_tiles(img, io, Vector2i(9, 0), Vector2i(14, 2), Vector2i(2, 3), variant, 0.84, 0.88)

	# Row 5: Props 1x1 (cadeiras, castiçal, jarras)
	P.blit_tiles(img, io, Vector2i(14, 4), Vector2i(0, 5), Vector2i(2, 1), variant, 0.82, 0.86)
	P.blit_tiles(img, io, Vector2i(14, 6), Vector2i(2, 5), Vector2i(2, 1), variant, 0.82, 0.86)
	P.blit_tiles(img, io, Vector2i(15, 10), Vector2i(4, 5), Vector2i(1, 1), variant, 0.88, 0.94)
	P.blit_tiles(img, io, Vector2i(13, 14), Vector2i(5, 5), Vector2i(3, 1), variant, 0.82, 0.86)

	# Rows 7..16: Móveis Multi-tile Y-sorted
	P.blit_tiles(img, io, Vector2i(5, 6), Vector2i(0, 7), Vector2i(3, 4), variant, 0.82, 0.86)
	P.blit_tiles(img, io, Vector2i(11, 3), Vector2i(3, 7), Vector2i(3, 3), variant, 0.82, 0.86)
	P.blit_tiles(img, im, Vector2i(5, 14), Vector2i(6, 7), Vector2i(2, 2), variant, 0.82, 0.86)
	P.blit_tiles(img, im, Vector2i(5, 16), Vector2i(8, 7), Vector2i(2, 2), variant, 0.82, 0.86)
	P.blit_tiles(img, io, Vector2i(11, 7), Vector2i(10, 7), Vector2i(4, 3), variant, 0.82, 0.86)
	P.blit_tiles(img, im, Vector2i(13, 38), Vector2i(14, 7), Vector2i(2, 2), variant, 0.82, 0.86)
	P.blit_tiles(img, im, Vector2i(10, 40), Vector2i(16, 7), Vector2i(2, 2), variant, 0.82, 0.86)
	P.blit_px_centered(img, im, Rect2i(12 * 16, 39 * 16 + 14, 16, 34), Vector2i(18, 7), Vector2i(1, 3), variant, 0.82, 0.86)
	P.blit_tiles(img, im, Vector2i(1, 36), Vector2i(19, 7), Vector2i(6, 2), variant, 0.82, 0.86)

	P.blit_tiles(img, im, Vector2i(2, 18), Vector2i(0, 12), Vector2i(2, 3), variant, 0.84, 0.88)
	P.blit_tiles(img, im, Vector2i(7, 51), Vector2i(3, 12), Vector2i(2, 3), variant, 0.82, 0.86)
	P.blit_tiles(img, im, Vector2i(13, 44), Vector2i(5, 12), Vector2i(2, 3), variant, 0.82, 0.88)
	P.blit_tiles(img, io, Vector2i(11, 10), Vector2i(7, 12), Vector2i(2, 2), variant, 0.82, 0.86)
	P.blit_tiles(img, im, Vector2i(2, 62), Vector2i(9, 12), Vector2i(2, 2), variant, 0.80, 0.82)
	P.blit_tiles(img, io, Vector2i(8, 5), Vector2i(12, 12), Vector2i(3, 3), variant, 0.82, 0.86)

	var solid: Array[Vector2i] = []
	var blocks_light: Array[Vector2i] = []
	var surface_map: Dictionary = {}

	for x in range(0, 10):
		for y in range(2, 4):
			if not (x >= 0 and x <= 2 and y == 3):
				solid.append(Vector2i(x, y))
				blocks_light.append(Vector2i(x, y))
				surface_map[Vector2i(x, y)] = "wood" if x < 6 else "stone"
	for x in range(0, 4):
		solid.append(Vector2i(x, 5))
		surface_map[Vector2i(x, 5)] = "wood"
	for x in range(0, 2):
		surface_map[Vector2i(x, 0)] = "wood"
	for x in range(2, 5):
		surface_map[Vector2i(x, 0)] = "stone"

	var box_2x := PackedVector2Array([Vector2(-14, -10), Vector2(14, -10), Vector2(14, 8), Vector2(-14, 8)])
	var box_3x := PackedVector2Array([Vector2(-22, -12), Vector2(22, -12), Vector2(22, 8), Vector2(-22, 8)])
	var spec := {
		"solid_cells": solid,
		"water_cells": [],
		"light_block_cells": blocks_light,
		"surface_map": surface_map,
		"animated_tiles": [],
		"multi_tiles": [
			{"coord": Vector2i(0, 7), "size": Vector2i(3, 4), "origin_x": 0, "y_sort_origin": 6, "collision_poly": box_3x, "surface": "wood"},
			{"coord": Vector2i(3, 7), "size": Vector2i(3, 3), "origin_x": 0, "y_sort_origin": 6, "collision_poly": box_3x, "surface": "wood"},
			{"coord": Vector2i(6, 7), "size": Vector2i(2, 2), "origin_x": 8, "y_sort_origin": 6, "collision_poly": box_2x, "surface": "wood"},
			{"coord": Vector2i(8, 7), "size": Vector2i(2, 2), "origin_x": 8, "y_sort_origin": 6, "collision_poly": box_2x, "surface": "wood"},
			{"coord": Vector2i(10, 7), "size": Vector2i(4, 3), "origin_x": 8, "y_sort_origin": 6, "collision_poly": PackedVector2Array([Vector2(-28, -10), Vector2(28, -10), Vector2(28, 8), Vector2(-28, 8)]), "surface": "wood"},
			{"coord": Vector2i(14, 7), "size": Vector2i(2, 2), "origin_x": 8, "y_sort_origin": 4, "solid": false, "surface": "wood"},
			{"coord": Vector2i(16, 7), "size": Vector2i(2, 2), "origin_x": 8, "y_sort_origin": 4, "solid": false, "surface": "stone"},
			{"coord": Vector2i(18, 7), "size": Vector2i(1, 3), "origin_x": 0, "y_sort_origin": 6, "collision_poly": PackedVector2Array([Vector2(-7, -6), Vector2(7, -6), Vector2(7, 8), Vector2(-7, 8)]), "surface": "stone"},
			{"coord": Vector2i(19, 7), "size": Vector2i(6, 2), "origin_x": 8, "y_sort_origin": 6, "collision_poly": PackedVector2Array([Vector2(-44, -8), Vector2(44, -8), Vector2(44, 8), Vector2(-44, 8)]), "surface": "wood"},
			{"coord": Vector2i(0, 12), "size": Vector2i(2, 3), "origin_x": 8, "y_sort_origin": 6, "collision_poly": box_2x, "surface": "stone"},
			{"coord": Vector2i(3, 12), "size": Vector2i(2, 3), "origin_x": 8, "y_sort_origin": 6, "collision_poly": box_2x, "surface": "wood"},
			{"coord": Vector2i(5, 12), "size": Vector2i(2, 3), "origin_x": 8, "y_sort_origin": 6, "collision_poly": box_2x, "surface": "prop"},
			{"coord": Vector2i(7, 12), "size": Vector2i(2, 2), "origin_x": 8, "y_sort_origin": 6, "collision_poly": box_2x, "surface": "wood"},
			{"coord": Vector2i(9, 12), "size": Vector2i(2, 2), "origin_x": 8, "y_sort_origin": 6, "collision_poly": box_2x, "surface": "wood"},
			{"coord": Vector2i(12, 12), "size": Vector2i(3, 3), "origin_x": 0, "y_sort_origin": 6, "solid": false, "surface": "prop"},
		],
	}
	return {"image": img, "spec": spec}


func _export_preview_sheet() -> void:
	# Gera montagem de revisão rápida apenas para inspeção (salva fora do game em docs/logs/ ou scratch)
	pass
