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
const FOREST_SCENE_COLLECTION: Array[String] = [
	"res://scenes/components/ForestTree.tscn",
	"res://scenes/components/ForestBush.tscn",
	"res://scenes/components/ForestCoconutTree.tscn",
	"res://scenes/components/ForestRock.tscn",
	"res://scenes/components/ForestWitheredPine.tscn",
	"res://scenes/components/ForestSlenderPine.tscn",
	"res://scenes/components/ForestGnarledTree.tscn",
	"res://scenes/components/ForestRoundTree.tscn",
	"res://scenes/components/ForestAncientTree.tscn",
]


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	var phase := "all"
	var only_biome := "all"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--phase="):
			phase = arg.trim_prefix("--phase=")
		elif arg.begins_with("--only="):
			only_biome = arg.trim_prefix("--only=")

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
		if only_biome == "all" or only_biome == "forest":
			var f_res := _compose_forest_atlas(imgs, v)
			_write_phase_outputs("forest_v2_%s" % v, f_res["image"], f_res["spec"], phase)

		if only_biome == "all" or only_biome == "town":
			var t_res := _compose_town_atlas(imgs, v)
			_write_phase_outputs("agdangan_town_v2_%s" % v, t_res["image"], t_res["spec"], phase)

		if only_biome == "all" or only_biome == "interiors":
			var i_res := _compose_interior_atlas(imgs, v)
			_write_phase_outputs("interiors_v2_%s" % v, i_res["image"], i_res["spec"], phase)

	if (phase == "images" or phase == "all") and only_biome == "all":
		_export_preview_sheet()

	print("Tilesets v2 processados (phase=%s, only=%s) em %s" % [phase, only_biome, OUT_DIR])
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
	P.blit_tiles(img, lt, Vector2i(6, 6), Vector2i(6, 0), Vector2i(3, 2), variant, 0.65, 0.48, Color("#96BA96"))
	P.blit_tiles(img, lt, Vector2i(0, 24), Vector2i(9, 0), Vector2i(3, 2), variant, 0.76, 0.76, Color("#C6DBD0"))

	# Rows 2..4: Blocos 3x3 de transição + sombras + cercas + pontes
	P.blit_tiles(img, lt, Vector2i(0, 12), Vector2i(0, 2), Vector2i(3, 3), variant, 0.74, 0.78)
	P.blit_tiles(img, lw, Vector2i(0, 0), Vector2i(3, 2), Vector2i(3, 3), variant, 0.68, 0.72, Color("#9CBFC8"))
	P.blit_tiles(img, lt, Vector2i(9, 9), Vector2i(6, 2), Vector2i(3, 3), variant, 0.70, 0.72)
	P.add_shadow_strips(img, Vector2i(9, 2), Vector2i(10, 2), Vector2i(11, 2), Vector2i(12, 2), variant)
	P.blit_tiles(img, df, Vector2i(6, 12), Vector2i(13, 2), Vector2i(5, 2), variant, 0.78, 0.85, Color.WHITE, true)
	P.blit_tiles(img, df, Vector2i(12, 8), Vector2i(19, 2), Vector2i(2, 4), variant, 0.80, 0.86, Color.WHITE, true)
	P.blit_tiles(img, df, Vector2i(12, 12), Vector2i(21, 2), Vector2i(2, 2), variant, 0.80, 0.86, Color.WHITE, true)

	# Água animada 100% seamless (water_deep_anim, water_ripple_anim), cachoeiras animadas (waterfall_top/mid/foam)
	# e leito d'água contínuo sob as pontes verticais (ancorados exatamente à paleta de pond_c em (4, 3))
	_draw_forest_water_and_bridges(img, variant)

	# Rows 5..12: Penhascos musgosos & gruta (dark_forest 8x8 -> 0..7, 5..12) + pedras (town_rpg) + clutter
	P.blit_tiles(img, df, Vector2i(0, 0), Vector2i(0, 5), Vector2i(8, 8), variant, 0.78, 0.84, Color("#D2DAD8"), true)
	P.blit_tiles(img, tr, Vector2i(0, 10), Vector2i(8, 5), Vector2i(3, 2), variant, 0.72, 0.78, Color("#C6CED2"))
	P.blit_tiles(img, df, Vector2i(6, 6), Vector2i(12, 5), Vector2i(2, 2), variant, 0.78, 0.85, Color.WHITE, true)
	P.blit_tiles(img, df, Vector2i(14, 6), Vector2i(14, 5), Vector2i(2, 2), variant, 0.82, 0.86, Color.WHITE, true)
	P.blit_tiles(img, df, Vector2i(14, 4), Vector2i(16, 5), Vector2i(2, 2), variant, 0.76, 0.82, Color.WHITE, true)
	P.blit_tiles(img, df, Vector2i(14, 12), Vector2i(18, 5), Vector2i(2, 2), variant, 0.76, 0.82, Color.WHITE, true)
	P.blit_tiles(img, df, Vector2i(8, 8), Vector2i(12, 7), Vector2i(2, 4), variant, 0.76, 0.82, Color.WHITE, true)
	P.blit_tiles(img, tr, Vector2i(1, 6), Vector2i(24, 5), Vector2i(3, 2), variant, 0.75, 0.80)

	# Rows 13..18: Árvores multi-tile com Y-sort na base e paleta verde-musgo unificada no modo normal
	P.blit_tiles(img, df, Vector2i(8, 1), Vector2i(0, 13), Vector2i(5, 6), variant, 0.78, 0.84, Color("#D4E2D8"), true)
	P.blit_tiles(img, lo, Vector2i(11, 10), Vector2i(5, 13), Vector2i(3, 5), variant, 0.74, 0.80, Color("#CFE0D4"))
	if variant == "normal":
		P.blit_tiles(img, lo, Vector2i(11, 10), Vector2i(8, 13), Vector2i(3, 5), variant, 0.70, 0.72, Color("#9CC2A8"))
	else:
		P.blit_tiles(img, lo, Vector2i(14, 10), Vector2i(8, 13), Vector2i(3, 5), variant, 0.76, 0.78, Color("#D6C6C2"))
	# Sombra suave de contato na base dos dois pinheiros (row 17..18)
	for tree_col: int in [5, 8]:
		var tcx: int = tree_col * 16 + 24
		var tcy: int = 18 * 16 - 3
		for sy in range(-3, 5):
			for sx in range(-12, 13):
				var nx := float(sx) / 12.0
				var ny := float(sy) / 4.2
				if nx * nx + ny * ny <= 1.0:
					var px_c := img.get_pixel(tcx + sx, tcy + sy)
					if px_c.a < 0.05:
						img.set_pixel(tcx + sx, tcy + sy, Color(0.03, 0.05, 0.04, 0.42))
	P.blit_tiles(img, tr, Vector2i(8, 2), Vector2i(11, 13), Vector2i(1, 6), variant, 0.76, 0.82, Color("#D2E0D4"))
	P.blit_tiles(img, lo, Vector2i(11, 5), Vector2i(13, 13), Vector2i(4, 5), variant, 0.74, 0.80, Color("#CEE0D2"))
	P.blit_tiles(img, df, Vector2i(6, 8), Vector2i(17, 13), Vector2i(2, 2), variant, 0.80, 0.84, Color.WHITE, true)
	P.blit_tiles(img, df, Vector2i(15, 8), Vector2i(19, 13), Vector2i(1, 3), variant, 0.80, 0.84, Color.WHITE, true)
	P.blit_tiles(img, lo, Vector2i(13, 0), Vector2i(20, 13), Vector2i(3, 1), variant, 0.78, 0.82)
	P.blit_tiles(img, lo, Vector2i(11, 4), Vector2i(23, 13), Vector2i(2, 2), variant, 0.74, 0.80)
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

	# Cercas sólidas (13..17, 2..3) e espuma de cachoeira (18, 2)
	for x in range(13, 18):
		solid.append(Vector2i(x, 2))
		solid.append(Vector2i(x, 3))
		surface_map[Vector2i(x, 2)] = "wood"
		surface_map[Vector2i(x, 3)] = "wood"
	solid.append(Vector2i(18, 2))
	water.append(Vector2i(18, 2))
	surface_map[Vector2i(18, 2)] = "water"
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
				solid.append(Vector2i(x, y))
			else:
				solid.append(Vector2i(x, y))
	for x in range(3, 6):
		surface_map[Vector2i(x, 0)] = "mud"
		surface_map[Vector2i(x, 1)] = "mud"
	for x in range(19, 23):
		for y in range(2, 6):
			surface_map[Vector2i(x, y)] = "wood"

	var trunk_box := PackedVector2Array([Vector2(-10, -8), Vector2(10, -8), Vector2(10, 8), Vector2(-10, 8)])
	var canopy_box := PackedVector2Array([Vector2(-12, -8), Vector2(12, -8), Vector2(12, 8), Vector2(-12, 8)])
	var big_box := PackedVector2Array([Vector2(-15, -10), Vector2(15, -10), Vector2(15, 8), Vector2(-15, 8)])
	var ancient_box := PackedVector2Array([Vector2(-28, -10), Vector2(28, -10), Vector2(28, 8), Vector2(-28, 8)])
	var full_2x2 := PackedVector2Array([Vector2(-14, -10), Vector2(14, -10), Vector2(14, 8), Vector2(-14, 8)])

	var spec := {
		"solid_cells": solid,
		"water_cells": water,
		"light_block_cells": blocks_light,
		"surface_map": surface_map,
		"animated_tiles": [
			{"coord": Vector2i(12, 0), "frames": 3, "frame_duration": 0.28, "solid": true, "poly": PackedVector2Array([Vector2(-8, -8), Vector2(8, -8), Vector2(8, 8), Vector2(-8, 8)]), "surface": "water", "is_water": true},
			{"coord": Vector2i(15, 0), "frames": 3, "frame_duration": 0.24, "solid": true, "poly": PackedVector2Array([Vector2(-8, -8), Vector2(8, -8), Vector2(8, 8), Vector2(-8, 8)]), "surface": "water", "is_water": true},
			{"coord": Vector2i(18, 0), "frames": 3, "frame_duration": 0.18, "solid": true, "poly": PackedVector2Array([Vector2(-8, -8), Vector2(8, -8), Vector2(8, 8), Vector2(-8, 8)]), "surface": "water", "is_water": true},
			{"coord": Vector2i(18, 1), "frames": 3, "frame_duration": 0.18, "solid": true, "poly": PackedVector2Array([Vector2(-8, -8), Vector2(8, -8), Vector2(8, 8), Vector2(-8, 8)]), "surface": "water", "is_water": true},
		],
		"multi_tiles": [
			{"coord": Vector2i(0, 13), "size": Vector2i(5, 6), "origin_x": 0, "y_sort_origin": 6, "collision_poly": big_box, "blocks_light": true, "surface": "wood"},
			{"coord": Vector2i(5, 13), "size": Vector2i(3, 6), "origin_x": 0, "y_sort_origin": 6, "collision_poly": trunk_box, "blocks_light": true, "surface": "wood"},
			{"coord": Vector2i(8, 13), "size": Vector2i(3, 6), "origin_x": 0, "y_sort_origin": 6, "collision_poly": trunk_box, "blocks_light": true, "surface": "wood"},
			{"coord": Vector2i(11, 13), "size": Vector2i(1, 6), "origin_x": 0, "y_sort_origin": 6, "collision_poly": trunk_box, "blocks_light": true, "surface": "wood"},
			{"coord": Vector2i(13, 13), "size": Vector2i(4, 5), "origin_x": 8, "y_sort_origin": 6, "collision_poly": canopy_box, "blocks_light": true, "surface": "wood"},
			{"coord": Vector2i(17, 13), "size": Vector2i(2, 2), "origin_x": 8, "y_sort_origin": 6, "collision_poly": full_2x2, "surface": "wood"},
			{"coord": Vector2i(19, 13), "size": Vector2i(1, 3), "origin_x": 0, "y_sort_origin": 4, "collision_poly": PackedVector2Array([Vector2(-6, -24), Vector2(6, -24), Vector2(6, 8), Vector2(-6, 8)]), "surface": "wood"},
			{"coord": Vector2i(20, 13), "size": Vector2i(3, 1), "origin_x": 0, "y_sort_origin": 4, "collision_poly": PackedVector2Array([Vector2(-22, -6), Vector2(22, -6), Vector2(22, 6), Vector2(-22, 6)]), "surface": "wood"},
			{"coord": Vector2i(23, 13), "size": Vector2i(2, 2), "origin_x": 8, "y_sort_origin": 6, "collision_poly": full_2x2, "surface": "prop"},
			{"coord": Vector2i(25, 13), "size": Vector2i(2, 2), "origin_x": 8, "y_sort_origin": 6, "collision_poly": full_2x2, "surface": "stone"},
			{"coord": Vector2i(0, 19), "size": Vector2i(14, 18), "origin_x": 8, "y_sort_origin": 6, "collision_poly": ancient_box, "blocks_light": true, "surface": "wood"},
			{"coord": Vector2i(15, 19), "size": Vector2i(3, 6), "origin_x": 0, "y_sort_origin": 6, "collision_poly": trunk_box, "surface": "wood"},
		],
		"scene_collection": FOREST_SCENE_COLLECTION,
	}
	return {"image": img, "spec": spec}


func _draw_forest_water_and_bridges(img: Image, variant: String) -> void:
	# Ancora toda a rampa de cores d'água exatamente no tom de pond_c (4, 3) para zero emendas na Lagoa Azul e riachos
	var base_c := img.get_pixel(4 * 16 + 8, 3 * 16 + 8)
	if base_c.a < 0.5:
		base_c = P.grade_color(Color("#195273"), variant, 0.68, 0.72, Color("#9CBFC8"))

	var c_deep := Color(base_c.r * 0.86, base_c.g * 0.90, base_c.b * 0.94, 1.0)
	var c_base := Color(base_c.r, base_c.g, base_c.b, 1.0)
	var mid_target := Color(0.22, 0.56, 0.68, 1.0) if variant == "normal" else (Color(0.36, 0.23, 0.29, 1.0) if variant == "distorted" else Color(0.55, 0.57, 0.59, 1.0))
	var hi_target := Color(0.46, 0.80, 0.87, 1.0) if variant == "normal" else (Color(0.50, 0.30, 0.36, 1.0) if variant == "distorted" else Color(0.74, 0.76, 0.78, 1.0))
	var foam_target := Color(0.84, 0.95, 0.97, 1.0) if variant == "normal" else (Color(0.68, 0.44, 0.48, 1.0) if variant == "distorted" else Color(0.90, 0.92, 0.93, 1.0))
	var c_mid := c_base.lerp(mid_target, 0.30)
	var c_hi := c_base.lerp(hi_target, 0.48)
	var c_foam := c_base.lerp(foam_target, 0.76)
	var c_shal_base := c_base.lerp(c_mid, 0.24)
	var c_rock_dk := P.grade_color(Color("#1A231E"), variant, 0.78, 0.82)
	var c_rock_md := P.grade_color(Color("#2E3E33"), variant, 0.78, 0.84)
	var c_rock_moss := P.grade_color(Color("#425B43"), variant, 0.78, 0.86)

	var shifts := [0, 5, 11]
	var sways := [0, 1, 0]

	# Traço horizontal fino e suave de marola 16-bit (sem pontos triangulares nem polca-dots)
	var draw_wave_line := func(ox: int, oy: int, x_start: int, y_pos: int, length: int, bright: bool) -> void:
		for i in range(length):
			var px := ox + posmod(x_start + i, 16)
			var py := oy + posmod(y_pos + (1 if (length >= 5 and (i == 0 or i == length - 1)) else 0), 16)
			var is_core := (i >= 1 and i <= length - 2)
			var col := c_hi if (bright and is_core) else (c_hi if (not bright and i == length / 2) else c_mid)
			if bright and i == length / 2:
				col = c_hi.lerp(c_foam, 0.35)
			img.set_pixel(px, py, col)

	# 1. water_deep_anim (cols 12..14, row 0) e water_ripple_anim (cols 15..17, row 0) — 3 frames 100% seamless
	for f in range(3):
		var sh_y: int = shifts[f]
		var sw_x: int = sways[f]
		var dx0 := (12 + f) * 16
		var sx0 := (15 + f) * 16
		for y in range(16):
			var vy := posmod(y - sh_y, 16)
			for x in range(16):
				# Faixas sutis de profundidade da correnteza (sem manchas circulares)
				var flow := sin(float(vy) * TAU / 8.0 + sin(float(x) * TAU / 16.0) * 0.7)
				var dcol := c_deep if flow < -0.55 else c_base
				img.set_pixel(dx0 + x, y, dcol)
				var scol := c_base if flow < -0.50 else c_shal_base
				img.set_pixel(sx0 + x, y, scol)

		# Ondinhas horizontais elegantes fluindo suavemente para baixo (equilibradas em todos os 3 frames)
		draw_wave_line.call(dx0, 0, 1 + sw_x, posmod(2 + sh_y, 16), 5, false)
		draw_wave_line.call(dx0, 0, 9 - sw_x, posmod(6 + sh_y, 16), 5, false)
		draw_wave_line.call(dx0, 0, 4 + sw_x, posmod(10 + sh_y, 16), 4, false)
		draw_wave_line.call(dx0, 0, 11 - sw_x, posmod(14 + sh_y, 16), 4, false)

		# Versão rasa/cintilante (water_ripple_anim)
		draw_wave_line.call(sx0, 0, 1 + sw_x, posmod(2 + sh_y, 16), 5, true)
		draw_wave_line.call(sx0, 0, 8 - sw_x, posmod(6 + sh_y, 16), 6, true)
		draw_wave_line.call(sx0, 0, 3 + sw_x, posmod(10 + sh_y, 16), 5, true)
		draw_wave_line.call(sx0, 0, 10 - sw_x, posmod(14 + sh_y, 16), 4, false)

	# Harmoniza pond_c (4, 3) com textura suave idêntica para eliminar efeito xadrez na Lagoa Azul
	var pcx := 4 * 16
	var pcy := 3 * 16
	for y in range(16):
		for x in range(16):
			var flow := sin(float(y) * TAU / 8.0 + sin(float(x) * TAU / 16.0) * 0.7)
			img.set_pixel(pcx + x, pcy + y, c_deep if flow < -0.58 else c_base)
	draw_wave_line.call(pcx, pcy, 2, 4, 4, false)
	draw_wave_line.call(pcx, pcy, 10, 11, 4, false)

	# 2. Cachoeira animada 3 frames: waterfall_top (18..20, 0) e waterfall_mid (18..20, 1) + waterfall_foam (18, 2)
	# Perfil orgânico de colunas d'água (larguras variadas em vez de listras rígidas)
	# 0=base/profundo, 1=correnteza média, 2=feixe luminoso, 3=crista espumante intermitente
	var col_profile := [1, 2, 1, 0, 1, 2, 3, 2, 1, 0, 1, 2, 2, 1, 3, 1]
	var col_phase := [0, 3, 6, 2, 5, 1, 4, 7, 2, 5, 0, 3, 6, 1, 4, 7]
	for f in range(3):
		var sh_y: int = shifts[f]
		var top_x := (18 + f) * 16
		var mid_x := (18 + f) * 16
		var mid_y := 16

		# waterfall_top: borda musgosa de nascente (y=0..2) + crista espumante (y=3) + queda orgânica (y=4..15)
		for y in range(16):
			for x in range(16):
				var rim_h := 2 + (1 if ((x * 5 + 3) % 7 < 3) else 0)
				if y < rim_h:
					var col_r := c_rock_dk if y == rim_h - 1 else (c_rock_moss if ((x + y) % 3 == 0) else c_rock_md)
					img.set_pixel(top_x + x, y, col_r)
				elif y == rim_h:
					var crest := c_foam if ((x + f) % 3 != 0) else c_hi
					img.set_pixel(top_x + x, y, crest)
				else:
					var vy := posmod(y - sh_y + int(col_phase[x]), 16)
					var prof: int = int(col_profile[x])
					var col_w := c_mid
					if prof == 0:
						col_w = c_base if (vy % 5 != 0) else c_mid
					elif prof == 1:
						col_w = c_mid if (vy % 4 != 0) else c_base
					elif prof == 2:
						col_w = c_hi if (vy % 8 < 5) else c_mid
					else:
						col_w = c_foam if (vy % 8 < 2) else (c_hi if (vy % 8 < 5) else c_mid)
					img.set_pixel(top_x + x, y, col_w)

		# waterfall_mid: queda contínua (y=0..9) + espuma borbulhante na base (y=9..13) + transição suave p/ water_deep_anim (y=14..15)
		for y in range(16):
			for x in range(16):
				var vy := posmod(y - sh_y + int(col_phase[x]), 16)
				var foam_top := 10 + (1 if ((x + f * 2) % 4 < 2) else 0)
				var foam_bot := 13 + (1 if ((x * 3 + f) % 5 < 2) else 0)
				var prof: int = int(col_profile[x])
				var col_m := c_base
				if y < foam_top:
					if prof == 0:
						col_m = c_base if (vy % 5 != 0) else c_mid
					elif prof == 1:
						col_m = c_mid if (vy % 4 != 0) else c_base
					elif prof == 2:
						col_m = c_hi if (vy % 8 < 5) else c_mid
					else:
						col_m = c_foam if (vy % 8 < 2) else (c_hi if (vy % 8 < 5) else c_mid)
				elif y <= foam_bot:
					var bubble := (x * 7 + y * 5 + f * 3) % 9
					if y == foam_top or bubble < 3:
						col_m = c_foam
					elif bubble < 7:
						col_m = c_hi
					else:
						col_m = c_mid
				else:
					col_m = c_hi if (y == foam_bot + 1 and (x + f) % 3 == 0) else (c_mid if ((x + f) % 4 == 0) else c_base)
				img.set_pixel(mid_x + x, mid_y + y, col_m)

	# waterfall_foam (18, 2) estático limpo (sem sobreposição de cerca)
	P.clear_tiles_rect(img, Vector2i(18, 2), Vector2i.ONE)
	var fx0 := 18 * 16
	var fy0 := 2 * 16
	for y in range(16):
		for x in range(16):
			var dist_c := absf(float(y) - 6.0)
			var b := (x * 5 + y * 7) % 11
			var col_f := c_base
			if dist_c < 2.5 and b < 6:
				col_f = c_foam
			elif dist_c < 4.5 and b < 7:
				col_f = c_hi
			elif dist_c < 6.0 and b < 5:
				col_f = c_mid
			img.set_pixel(fx0 + x, fy0 + y, col_f)

	# 3. Preenche os vãos transparentes das pontes verticais (cols 19..20, rows 2..5) com água do riacho + sombra das tábuas
	var bx0 := 19 * 16
	var by0 := 2 * 16
	var bw := 2 * 16
	var bh := 4 * 16
	var wood_mask := PackedByteArray()
	wood_mask.resize(bw * bh)
	for py in range(bh):
		for px in range(bw):
			wood_mask[py * bw + px] = 1 if img.get_pixel(bx0 + px, by0 + py).a >= 0.1 else 0
	for py in range(bh):
		for px in range(bw):
			if wood_mask[py * bw + px] == 1:
				continue
			# Sombra projetada da ponte sobre a água logo abaixo/ao lado das tábuas
			var near_wood := false
			for oy in range(-2, 2):
				for ox in range(-1, 2):
					var nx := px + ox
					var ny := py + oy
					if nx >= 0 and nx < bw and ny >= 0 and ny < bh and wood_mask[ny * bw + nx] == 1:
						near_wood = true
						break
				if near_wood:
					break
			var col_bg := c_deep if near_wood else c_base
			if not near_wood:
				var w := sin(float(px) * TAU / 16.0 + float(py) * TAU / 16.0) * 0.55 + cos(float(px) * TAU / 8.0 - float(py) * TAU / 16.0) * 0.45
				if w > 0.72:
					col_bg = c_mid
				elif w < -0.60:
					col_bg = c_deep
			img.set_pixel(bx0 + px, by0 + py, col_bg)


# ==============================================================================
# 2. CIDADE COSTEIRA DE AGDANGAN, CALABARZON (32x28 = 512x448)
# ==============================================================================
func _compose_town_atlas(imgs: Dictionary, variant: String) -> Dictionary:
	var img := P.create_sheet(32, 28)
	var sv: Image = imgs["serene"]
	var tr: Image = imgs["town_rpg"]
	var lw: Image = imgs["lpc_water"]

	# Rows 0..1: Estradas asfalto, quadra, faixa, poças + grama/areia/terra/pier/mar seamless
	Props.draw_road_and_plaza_tiles(img, Vector2i(0, 0), variant)
	P.blit_tiles(img, sv, Vector2i(4, 0), Vector2i(8, 0), Vector2i(6, 2), variant, 0.78, 0.88, Color("#DCE6E2"))
	Props.draw_ocean_and_pier_tiles(img, variant)
	Props.draw_soil_and_blend_tiles(img, variant)
	P.add_shadow_strips(img, Vector2i(25, 0), Vector2i(26, 0), Vector2i(27, 0), Vector2i(28, 0), variant)

	# Row 2: Paredes provinciais filipinas & telhados yero (zinco)
	Props.draw_modular_filipino_buildings(img, Vector2i(0, 2), Vector2i(7, 2), variant)

	# Row 3..4: Cercas Serene + cerca vertical contínua + floreiras/placas Serene + barris/caixotes
	P.blit_tiles(img, sv, Vector2i(5, 15), Vector2i(0, 3), Vector2i(3, 2), variant, 0.80, 0.86)
	Props.draw_vertical_bamboo_fence_tile(img, Vector2i(1, 3), variant)
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
	P.blit_px_centered(img, sv, Rect2i(148, 194, 27, 44), Vector2i(12, 12), Vector2i(2, 3), variant, 0.78, 0.84, Color("#D2E2D8"))
	P.blit_px_centered(img, sv, Rect2i(179, 194, 27, 44), Vector2i(14, 12), Vector2i(2, 3), variant, 0.78, 0.84, Color("#D2E2D8"))
	P.blit_px_centered(img, sv, Rect2i(211, 194, 27, 44), Vector2i(16, 12), Vector2i(2, 3), variant, 0.78, 0.84, Color("#D2E2D8"))

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
	for x in range(0, 11):
		solid.append(Vector2i(x, 2))
		blocks_light.append(Vector2i(x, 2))
		surface_map[Vector2i(x, 2)] = "stone"
	for x in range(4, 8):
		surface_map[Vector2i(x, 1)] = "dirt"
	for x in range(0, 3):
		solid.append(Vector2i(x, 3))
		surface_map[Vector2i(x, 3)] = "wood"
	for x in range(0, 4):
		solid.append(Vector2i(x, 4))
		surface_map[Vector2i(x, 4)] = "stone"

	var palm_box := PackedVector2Array([Vector2(-9, -6), Vector2(9, -6), Vector2(9, 8), Vector2(-9, 8)])
	var tree_box := PackedVector2Array([Vector2(-12, -20), Vector2(12, -20), Vector2(12, 8), Vector2(-12, 8)])
	var banana_box := PackedVector2Array([Vector2(-8, -6), Vector2(8, -6), Vector2(8, 8), Vector2(-8, 8)])
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
			{"coord": Vector2i(0, 5), "size": Vector2i(3, 6), "origin_x": 0, "y_sort_origin": 6, "collision_poly": palm_box, "surface": "wood"},
			{"coord": Vector2i(3, 5), "size": Vector2i(3, 6), "origin_x": 0, "y_sort_origin": 6, "collision_poly": palm_box, "surface": "wood"},
			{"coord": Vector2i(6, 5), "size": Vector2i(2, 3), "origin_x": 8, "y_sort_origin": 6, "collision_poly": banana_box, "surface": "prop"},
			{"coord": Vector2i(8, 5), "size": Vector2i(1, 5), "origin_x": 0, "y_sort_origin": 6, "collision_poly": PackedVector2Array([Vector2(-5, -2), Vector2(5, -2), Vector2(5, 8), Vector2(-5, 8)]), "surface": "stone"},
			{"coord": Vector2i(9, 5), "size": Vector2i(1, 5), "origin_x": 0, "y_sort_origin": 6, "collision_poly": PackedVector2Array([Vector2(-5, -2), Vector2(5, -2), Vector2(5, 8), Vector2(-5, 8)]), "surface": "stone"},
			{"coord": Vector2i(10, 5), "size": Vector2i(5, 4), "origin_x": 0, "y_sort_origin": 6, "collision_poly": PackedVector2Array([Vector2(-38, -46), Vector2(38, -46), Vector2(38, 7), Vector2(-38, 7)]), "blocks_light": true, "surface": "wood"},
			{"coord": Vector2i(15, 5), "size": Vector2i(6, 5), "origin_x": 8, "y_sort_origin": 6, "collision_poly": PackedVector2Array([Vector2(-45, -60), Vector2(45, -60), Vector2(45, 7), Vector2(-45, 7)]), "blocks_light": true, "surface": "stone"},
			{"coord": Vector2i(21, 5), "size": Vector2i(6, 5), "origin_x": 8, "y_sort_origin": 6, "collision_poly": PackedVector2Array([Vector2(-45, -60), Vector2(45, -60), Vector2(45, 7), Vector2(-45, 7)]), "blocks_light": true, "surface": "stone"},
			{"coord": Vector2i(27, 5), "size": Vector2i(1, 2), "origin_x": 0, "y_sort_origin": 6, "collision_poly": PackedVector2Array([Vector2(-5, -4), Vector2(5, -4), Vector2(5, 8), Vector2(-5, 8)]), "surface": "stone"},
			{"coord": Vector2i(28, 5), "size": Vector2i(2, 1), "origin_x": 8, "y_sort_origin": 4, "collision_poly": PackedVector2Array([Vector2(-6, -4), Vector2(22, -4), Vector2(22, 6), Vector2(-6, 6)]), "surface": "wood"},
			{"coord": Vector2i(0, 12), "size": Vector2i(5, 3), "origin_x": 0, "y_sort_origin": 6, "collision_poly": PackedVector2Array([Vector2(-36, -18), Vector2(36, -18), Vector2(36, 8), Vector2(-36, 8)]), "blocks_light": true, "surface": "stone"},
			{"coord": Vector2i(5, 12), "size": Vector2i(3, 2), "origin_x": 0, "y_sort_origin": 6, "collision_poly": PackedVector2Array([Vector2(-20, -10), Vector2(20, -10), Vector2(20, 8), Vector2(-20, 8)]), "surface": "stone"},
			{"coord": Vector2i(8, 12), "size": Vector2i(4, 2), "origin_x": 8, "y_sort_origin": 6, "collision_poly": PackedVector2Array([Vector2(-28, -10), Vector2(28, -10), Vector2(28, 8), Vector2(-28, 8)]), "surface": "wood"},
			{"coord": Vector2i(12, 12), "size": Vector2i(2, 3), "origin_x": 8, "y_sort_origin": 6, "collision_poly": tree_box, "blocks_light": true, "surface": "wood"},
			{"coord": Vector2i(14, 12), "size": Vector2i(2, 3), "origin_x": 8, "y_sort_origin": 6, "collision_poly": tree_box, "blocks_light": true, "surface": "wood"},
			{"coord": Vector2i(16, 12), "size": Vector2i(2, 3), "origin_x": 8, "y_sort_origin": 6, "collision_poly": tree_box, "blocks_light": true, "surface": "wood"},
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
	_draw_straight_wood_floor_block(img, variant)
	Props.draw_sawali_and_banig(img, Vector2i(0, 2), Vector2i(5, 0), variant)
	P.add_shadow_strips(img, Vector2i(8, 0), Vector2i(9, 0), Vector2i(10, 0), Vector2i(11, 0), variant)
	P.blit_tiles(img, io, Vector2i(3, 5), Vector2i(12, 0), Vector2i(2, 2), variant, 0.80, 0.84)

	# Rows 2..4: Paredes internas (Sawali já desenhada em 0..2,2) + Room_Builder madeira/BFP/enfermaria + portas/janelas
	P.blit_tiles(img, rb, Vector2i(12, 0), Vector2i(3, 2), Vector2i(1, 2), variant, 0.78, 0.75)
	P.blit_tiles(img, rb, Vector2i(0, 13), Vector2i(4, 2), Vector2i(2, 2), variant, 0.80, 0.82)
	P.blit_tiles(img, rb, Vector2i(0, 17), Vector2i(6, 2), Vector2i(2, 2), variant, 0.80, 0.84)
	P.blit_tiles(img, rb, Vector2i(0, 19), Vector2i(8, 2), Vector2i(2, 2), variant, 0.80, 0.86)
	P.blit_tiles(img, io, Vector2i(11, 0), Vector2i(10, 2), Vector2i(4, 3), variant, 0.82, 0.86)
	Props.draw_interior_window_tile(img, Vector2i(14, 2), variant)

	# Row 5: Props 1x1 (4 cadeiras direcionais em carvalho, castiçal, jarras)
	Props.draw_interior_chairs(img, Vector2i(0, 5), variant)
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

	P.blit_px_centered(img, im, Rect2i(2 * 16, 18 * 16 + 8, 32, 31), Vector2i(0, 12), Vector2i(2, 3), variant, 0.84, 0.88)
	P.blit_px_centered(img, im, Rect2i(7 * 16, 51 * 16 + 4, 32, 39), Vector2i(3, 12), Vector2i(2, 3), variant, 0.82, 0.86)
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
	var box_bed := PackedVector2Array([Vector2(-22, -48), Vector2(22, -48), Vector2(22, 8), Vector2(-22, 8)])
	var box_table := PackedVector2Array([Vector2(-22, -22), Vector2(22, -22), Vector2(22, 8), Vector2(-22, 8)])
	var spec := {
		"solid_cells": solid,
		"water_cells": [],
		"light_block_cells": blocks_light,
		"surface_map": surface_map,
		"animated_tiles": [],
		"multi_tiles": [
			{"coord": Vector2i(0, 7), "size": Vector2i(3, 4), "origin_x": 0, "y_sort_origin": 6, "collision_poly": box_bed, "surface": "wood"},
			{"coord": Vector2i(3, 7), "size": Vector2i(3, 3), "origin_x": 0, "y_sort_origin": 6, "collision_poly": box_table, "surface": "wood"},
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


func _draw_straight_wood_floor_block(img: Image, variant: String) -> void:
	# Tábuas horizontais retas em estilo 16-bit limpo sem ruído visual:
	# tiles (3,0),(3,1) = wood_floor_dark ; tiles (4,0),(4,1) = wood_floor_warm
	var tiles := [
		{"coord": Vector2i(3, 0), "dark": true, "phase": 0},
		{"coord": Vector2i(3, 1), "dark": true, "phase": 4},
		{"coord": Vector2i(4, 0), "dark": false, "phase": 2},
		{"coord": Vector2i(4, 1), "dark": false, "phase": 6},
	]
	for tinfo in tiles:
		var tc: Vector2i = tinfo["coord"]
		var is_dark: bool = bool(tinfo["dark"])
		var phase: int = int(tinfo["phase"])
		var base_pal := (
			[Color("#563A26"), Color("#61432D"), Color("#4B3220"), Color("#6C4C35")]
			if is_dark else
			[Color("#6C4A32"), Color("#78543A"), Color("#61412B"), Color("#845E42")]
		)
		var seam_col := P.grade_color(Color("#362216") if is_dark else Color("#462D1D"), variant, 0.82, 0.86)
		var highlight_col := P.grade_color(Color("#886044") if is_dark else Color("#966E4E"), variant, 0.80, 0.88)
		var x0 := tc.x * 16
		var y0 := tc.y * 16
		for py in range(16):
			var band := int(py / 4) # 4 tábuas de 4px por tile 16x16
			var in_band := py % 4
			var tone_idx := (band + phase) % base_pal.size()
			var plank_base := P.grade_color(base_pal[tone_idx], variant, 0.80, 0.88)
			var joint_x := (band * 5 + phase * 3 + 3) % 16
			for px in range(16):
				var col := plank_base
				if in_band == 3 or px == joint_x:
					col = seam_col
				elif in_band == 0 and ((px + band) % 5 != 0):
					col = highlight_col if (px + phase) % 7 == 0 else plank_base
				elif in_band == 1 and ((px + band * 3 + phase) % 8 == 0):
					col = P.grade_color(base_pal[(tone_idx + 2) % base_pal.size()], variant, 0.80, 0.86)
				img.set_pixel(x0 + px, y0 + py, col)


func _export_preview_sheet() -> void:
	# Gera montagem de revisão rápida apenas para inspeção (salva fora do game em docs/logs/ ou scratch)
	pass
