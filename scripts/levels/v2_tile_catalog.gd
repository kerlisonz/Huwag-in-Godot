class_name V2TileCatalog
extends RefCounted

## Catálogo centralizado dos tilesets 16×16 v2 (Fase 1/2):
## Fonte única de verdade para coordenadas de atlas, multi-tiles e caminhos de recursos.

const V2_DIR := "res://assets/tilesets/v2"

const FOREST_TILES := {
	"grass_a": Vector2i(0, 0),
	"grass_b": Vector2i(1, 0),
	"grass_c": Vector2i(2, 0),
	"grass_d": Vector2i(0, 1),
	"soil_a": Vector2i(3, 0),
	"soil_b": Vector2i(4, 0),
	"soil_dark": Vector2i(5, 0),
	"needle_grass_a": Vector2i(6, 0),
	"needle_grass_b": Vector2i(7, 0),
	"tall_grass_a": Vector2i(9, 0),
	"tall_grass_b": Vector2i(10, 0),
	"tall_grass_c": Vector2i(11, 0),
	"water_deep_anim": Vector2i(12, 0),
	"water_ripple_anim": Vector2i(15, 0),
	"waterfall_top": Vector2i(18, 0),
	"waterfall_mid": Vector2i(18, 1),
	"waterfall_foam": Vector2i(18, 2),
	"mud_patch_center": Vector2i(5, 0),
	"water_shore_center": Vector2i(6, 0),
	"pit_center": Vector2i(5, 0),
	"cliff_top_mid": Vector2i(1, 5),
	"cliff_face_mid": Vector2i(1, 10),
	"rock_round_a": Vector2i(25, 13),
	"shadow_top": Vector2i(9, 2),
	"shadow_left": Vector2i(10, 2),
	"shadow_corner": Vector2i(11, 2),
	"shadow_blob": Vector2i(12, 2),
	"fence_left": Vector2i(13, 2),
	"fence_mid": Vector2i(14, 2),
	"fence_right": Vector2i(15, 2),
	"bridge_v_top_l": Vector2i(19, 2),
	"bridge_v_mid_l": Vector2i(19, 3),
	"bridge_v_mid_r": Vector2i(20, 3),
	"bridge_h_l": Vector2i(21, 2),
	"bridge_h_mid_t": Vector2i(22, 2),
	"pebbles": Vector2i(12, 5),
	"mushrooms_a": Vector2i(14, 5),
	"fern_a": Vector2i(16, 5),
	"fern_b": Vector2i(18, 5),
	"tree_gnarled_mid": Vector2i(0, 13),     # 5x6
	"pine_dark": Vector2i(5, 13),            # 3x6
	"pine_withered": Vector2i(8, 13),        # 3x6
	"pine_slender": Vector2i(11, 13),        # 2x5
	"tree_canopy_round": Vector2i(13, 13),   # 4x5
	"stump_rooted": Vector2i(17, 13),        # 2x2
	"log_v": Vector2i(19, 13),               # 1x3
	"log_h": Vector2i(20, 13),               # 3x1
	"bush_dense": Vector2i(23, 13),          # 2x2
	"moss_boulder": Vector2i(25, 13),        # 2x2
	"ancient_tree": Vector2i(0, 19),         # 14x18
}

const TOWN_TILES := {
	"asphalt": Vector2i(0, 0),
	"asphalt_dash_h": Vector2i(1, 0),
	"asphalt_dash_v": Vector2i(2, 0),
	"road_grate": Vector2i(3, 0),
	"asphalt_crack": Vector2i(0, 1),
	"asphalt_puddle": Vector2i(1, 1),
	"curb_top": Vector2i(2, 1),
	"curb_bottom": Vector2i(3, 1),
	"plaza_slab": Vector2i(4, 0),
	"plaza_line_h": Vector2i(5, 0),
	"plaza_line_v": Vector2i(6, 0),
	"plaza_corner": Vector2i(4, 0),
	"crosswalk": Vector2i(7, 0),
	"grass_a": Vector2i(8, 0),
	"grass_b": Vector2i(9, 0),
	"grass_c": Vector2i(8, 0),
	"grass_d": Vector2i(9, 0),
	"dirt_a": Vector2i(15, 0),
	"dirt_b": Vector2i(15, 1),
	"sand_a": Vector2i(15, 0),
	"sand_b": Vector2i(15, 1),
	"sand_edge_w": Vector2i(14, 0),
	"pier_plank_l": Vector2i(16, 0),
	"pier_plank": Vector2i(17, 0),
	"pier_plank_r": Vector2i(18, 0),
	"pier_post": Vector2i(17, 1),
	"fence_bamboo_h": Vector2i(0, 3),
	"fence_bamboo_v": Vector2i(1, 3),
	"sea_water_anim": Vector2i(19, 0),
	"shallow_water_anim": Vector2i(22, 0),
	"shadow_top": Vector2i(25, 0),
	"shadow_left": Vector2i(26, 0),
	"shadow_corner": Vector2i(27, 0),
	"shadow_blob": Vector2i(28, 0),
	"wall_concrete": Vector2i(0, 2),
	"wall_wood": Vector2i(1, 2),
	"wall_window_dark": Vector2i(2, 2),
	"wall_window_lit": Vector2i(3, 2),
	"wall_door": Vector2i(4, 2),
	"wall_bfp_red": Vector2i(5, 2),
	"wall_bfp_shutter": Vector2i(6, 2),
	"roof_yero_grey": Vector2i(7, 2),
	"roof_yero_grey_eave": Vector2i(8, 2),
	"roof_yero_rust": Vector2i(9, 2),
	"roof_yero_rust_eave": Vector2i(10, 2),
	"coconut_left": Vector2i(0, 5),          # 3x6
	"coconut_right": Vector2i(3, 5),         # 3x6
	"banana_plant": Vector2i(6, 5),          # 2x3
	"lamppost_lit": Vector2i(8, 5),          # 1x5
	"lamppost_dark": Vector2i(9, 5),         # 1x5
	"sari_sari_store": Vector2i(10, 5),      # 5x4
	"house_concrete_grey": Vector2i(15, 5),  # 6x5
	"house_concrete_rust": Vector2i(21, 5),  # 6x5
	"fire_hydrant": Vector2i(27, 5),         # 1x2
	"plaza_bench": Vector2i(28, 5),          # 2x1
	"bfp_truck": Vector2i(0, 12),            # 5x3
	"tricycle": Vector2i(5, 12),             # 3x2
	"banca_boat": Vector2i(8, 12),           # 4x2
	"coastal_tree_a": Vector2i(12, 12),      # 2x3
	"coastal_tree_b": Vector2i(14, 12),      # 2x3
	"coastal_tree_c": Vector2i(16, 12),      # 2x3
}

const INTERIOR_TILES := {
	"void": Vector2i(3, 2),
	"wood_floor_dark": Vector2i(3, 1),
	"wood_floor_warm": Vector2i(4, 1),
	"tile_terracotta": Vector2i(1, 0),
	"concrete_station": Vector2i(2, 0),
	"checker_clinic": Vector2i(1, 1),
	"checker_clinic_alt": Vector2i(2, 1),
	"banig_tl": Vector2i(5, 0),
	"shadow_top": Vector2i(8, 0),
	"shadow_left": Vector2i(9, 0),
	"shadow_corner": Vector2i(10, 0),
	"shadow_blob": Vector2i(11, 0),
	"rug_crimson_tl": Vector2i(12, 0),
	"wall_sawali_l": Vector2i(0, 2),
	"wall_sawali_m": Vector2i(1, 2),
	"wall_sawali_r": Vector2i(2, 2),
	"wall_ceiling_cap": Vector2i(3, 2),
	"wall_trim_gold": Vector2i(3, 2),
	"wall_wood_left": Vector2i(4, 2),
	"wall_wood_mid": Vector2i(4, 2),
	"wall_wood_right": Vector2i(5, 2),
	"wall_station_left": Vector2i(6, 2),
	"wall_station_mid": Vector2i(6, 2),
	"wall_clinic_mid": Vector2i(8, 2),
	"wall_clinic_right": Vector2i(9, 2),
	"door_wood_tl": Vector2i(10, 2),
	"door_station_tl": Vector2i(12, 2),
	"window_day_tl": Vector2i(14, 2),
	"window_night_tl": Vector2i(14, 2),
	"chair_down": Vector2i(0, 5),
	"candlestick": Vector2i(4, 5),
	"jar_clay": Vector2i(5, 5),
	"bed_huwag": Vector2i(0, 7),             # 3x4
	"table_dining": Vector2i(3, 7),          # 3x3
	"bookshelf_a": Vector2i(6, 7),           # 2x2
	"bookshelf_b": Vector2i(8, 7),           # 2x2
	"kitchen_counter": Vector2i(10, 7),      # 4x3
	"bulletin_board": Vector2i(14, 7),       # 2x2
	"chalkboard_bfp": Vector2i(16, 7),       # 2x2
	"radio_pc_bfp": Vector2i(18, 7),         # 1x2
	"dispatch_desk": Vector2i(19, 7),        # 6x2
	"fridge_sari": Vector2i(0, 12),          # 3x2
	"wardrobe": Vector2i(3, 12),             # 2x3
	"indoor_palm": Vector2i(5, 12),          # 2x3
	"supply_crates": Vector2i(7, 12),        # 2x2
	"debris_broken": Vector2i(9, 12),        # 3x2
	"curtain_drape": Vector2i(12, 12),       # 3x3
}


static func get_tileset_path(biome: String, variant: String = "normal") -> String:
	return "%s/%s_v2_%s_tileset.tres" % [V2_DIR, biome, variant]


static func load_tileset(biome: String, variant: String = "normal") -> TileSet:
	var p := get_tileset_path(biome, variant)
	if not ResourceLoader.exists(p):
		return null
	return ResourceLoader.load(p) as TileSet


static func fill_rect(layer: TileMapLayer, rect: Rect2i, atlas_coord: Vector2i, source_id: int = 0) -> void:
	if layer == null:
		return
	for y in range(rect.position.y, rect.position.y + rect.size.y):
		for x in range(rect.position.x, rect.position.x + rect.size.x):
			layer.set_cell(Vector2i(x, y), source_id, atlas_coord)


static func stamp_rect(layer: TileMapLayer, dst_pos: Vector2i, atlas_coord: Vector2i, size: Vector2i = Vector2i.ONE, source_id: int = 0) -> void:
	if layer == null:
		return
	var ts := layer.tile_set
	if ts != null and ts.has_source(source_id):
		var src := ts.get_source(source_id) as TileSetAtlasSource
		if src != null and src.has_tile(atlas_coord):
			var tile_sz := src.get_tile_size_in_atlas(atlas_coord)
			if tile_sz.x > 1 or tile_sz.y > 1:
				var td := src.get_tile_data(atlas_coord, 0)
				var ox: int = td.texture_origin.x if td != null else 0
				var oy: int = td.texture_origin.y if td != null else 0
				var cx: int = dst_pos.x + int(round(float(tile_sz.x * 8 + ox - 8) / 16.0))
				var cy: int = dst_pos.y + int(round(float(tile_sz.y * 8 + oy - 8) / 16.0))
				layer.set_cell(Vector2i(cx, cy), source_id, atlas_coord)
				return
			for dy in range(size.y):
				for dx in range(size.x):
					var c := atlas_coord + Vector2i(dx, dy)
					layer.set_cell(dst_pos + Vector2i(dx, dy), source_id, c if src.has_tile(c) else atlas_coord)
			return
	layer.set_cell(dst_pos, source_id, atlas_coord)
