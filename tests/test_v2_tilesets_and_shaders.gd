extends SceneTree

## Validação automática da Fase 1 (Tilesets v2 16×16, multi-tiles, animações e AtmosphereRig/shaders).

func _init() -> void:
	create_timer(15.0).timeout.connect(func() -> void:
		push_error("TIMEOUT: test_v2_tilesets_and_shaders excedeu 15s")
		quit(1)
	)
	call_deferred("_run")


func _assert_ok(cond: bool, msg: String) -> void:
	if not cond:
		push_error("[FAIL] " + msg)
		printerr("[FAIL] " + msg)
		quit(1)


func _run() -> void:
	print("=== TESTE FASE 1: TILESETS V2 16x16 & ATMOSPHERE RIG ===")

	# 1. Todos os 9 TileSets (3 biomas × 3 variantes de Ato)
	var biomes := ["forest", "agdangan_town", "interiors"]
	var variants := ["normal", "distorted", "act3"]
	for biome in biomes:
		for variant in variants:
			var ts := V2TileCatalog.load_tileset(biome, variant)
			_assert_ok(ts != null, "TileSet nulo para %s/%s" % [biome, variant])
			_assert_ok(ts.tile_size == Vector2i(16, 16), "TileSize deve ser 16x16 em %s/%s" % [biome, variant])
			_assert_ok(ts.get_physics_layers_count() >= 1, "PhysicsLayer ausente em %s/%s" % [biome, variant])
			_assert_ok(ts.get_custom_data_layers_count() >= 3, "CustomDataLayers ausentes em %s/%s" % [biome, variant])
			_assert_ok(ts.get_custom_data_layer_name(0) == "surface_type", "CustomData 0 deve ser surface_type")
			_assert_ok(ts.get_custom_data_layer_name(1) == "is_water", "CustomData 1 deve ser is_water")
			_assert_ok(ts.get_custom_data_layer_name(2) == "blocks_light", "CustomData 2 deve ser blocks_light")
			var src := ts.get_source(0) as TileSetAtlasSource
			_assert_ok(src != null and src.texture != null, "AtlasSource sem textura em %s/%s" % [biome, variant])
			_assert_ok(src.texture.get_width() == 512, "Largura do atlas deve ser 512px (32 colunas 16px) em %s/%s" % [biome, variant])
	print("[PASS] 9/9 TileSets v2 carregados com grid 16x16, física e metadados.")

	# 2. Floresta: água animada + árvores multi-tile + origem Y-sort
	var f_ts := V2TileCatalog.load_tileset("forest", "normal")
	var f_src := f_ts.get_source(0) as TileSetAtlasSource
	var creek_coord: Vector2i = V2TileCatalog.FOREST_TILES["water_deep_anim"]
	_assert_ok(f_src.has_tile(creek_coord), "water_deep_anim ausente")
	_assert_ok(f_src.get_tile_animation_columns(creek_coord) == 3, "water_deep_anim deve ter 3 colunas de animação")
	_assert_ok(f_src.get_tile_animation_frames_count(creek_coord) == 3, "water_deep_anim deve ter 3 frames")
	var creek_td := f_src.get_tile_data(creek_coord, 0)
	_assert_ok(bool(creek_td.get_custom_data("is_water")) == true, "water_deep_anim deve marcar is_water=true")
	_assert_ok(creek_td.get_collision_polygons_count(0) >= 1, "water_deep_anim precisa colisão de margem/leito")
	for wf_key in ["waterfall_top", "waterfall_mid"]:
		var wf_coord: Vector2i = V2TileCatalog.FOREST_TILES[wf_key]
		_assert_ok(f_src.get_tile_animation_frames_count(wf_coord) == 3, "%s deve ter 3 frames animados" % wf_key)
		var wf_td := f_src.get_tile_data(wf_coord, 0)
		_assert_ok(bool(wf_td.get_custom_data("is_water")) == true and wf_td.get_collision_polygons_count(0) >= 1,
			"%s precisa de is_water=true e colisão" % wf_key)
	var f_img: Image = f_src.texture.get_image()
	for frame_i in range(3):
		var distinct := {}
		var fx0 := (creek_coord.x + frame_i) * 16
		for py in range(16):
			for px in range(16):
				var c := f_img.get_pixel(fx0 + px, py)
				distinct["%d,%d,%d" % [int(c.r * 255), int(c.g * 255), int(c.b * 255)]] = true
		_assert_ok(distinct.size() >= 3, "Frame %d de water_deep_anim não pode ficar liso/vazio (cores=%d)" % [frame_i, distinct.size()])
	_assert_ok(f_img.get_pixel(3 * 16, 2 * 16).a < 0.05, "Canto externo de pond_tl deve ser transparente para mesclar na grama da floresta")
	_assert_ok(f_img.get_pixel(19 * 16 + 1, 3 * 16 + 1).a > 0.9, "Ponte vertical deve ter água preenchida sob os vãos das tábuas")

	var ancient_coord: Vector2i = V2TileCatalog.FOREST_TILES["ancient_tree"]
	_assert_ok(f_src.get_tile_size_in_atlas(ancient_coord) == Vector2i(14, 18), "ancient_tree deve ser 14x18")
	var ancient_td := f_src.get_tile_data(ancient_coord, 0)
	_assert_ok(ancient_td.texture_origin == Vector2i(8, 136), "ancient_tree texture_origin esperado (8, 136)")
	_assert_ok(ancient_td.y_sort_origin == 6, "ancient_tree y_sort_origin esperado 6")
	_assert_ok(bool(ancient_td.get_custom_data("blocks_light")) == true, "ancient_tree deve bloquear luz")
	_assert_ok(f_src.get_tile_size_in_atlas(V2TileCatalog.FOREST_TILES["pine_slender"]) == Vector2i(1, 6), "pine_slender deve ser 1x6")
	print("[PASS] Tileset da Floresta (água animada, multi-tiles e Y-sort) íntegro.")

	# 3. Cidade de Agdangan: prédios, coqueiros, BFP e mar animado
	var t_ts := V2TileCatalog.load_tileset("agdangan_town", "normal")
	var t_src := t_ts.get_source(0) as TileSetAtlasSource
	var sari_coord: Vector2i = V2TileCatalog.TOWN_TILES["sari_sari_store"]
	_assert_ok(t_src.get_tile_size_in_atlas(sari_coord) == Vector2i(5, 4), "sari_sari_store deve ser 5x4")
	var sari_td := t_src.get_tile_data(sari_coord, 0)
	_assert_ok(sari_td.texture_origin == Vector2i(0, 24), "sari_sari_store texture_origin esperado (0, 24)")
	_assert_ok(bool(sari_td.get_custom_data("blocks_light")) == true, "sari_sari_store deve marcar blocks_light")
	_assert_ok(t_src.get_tile_size_in_atlas(V2TileCatalog.TOWN_TILES["coconut_left"]) == Vector2i(3, 6), "coconut_left deve ser 3x6")
	_assert_ok(t_src.get_tile_size_in_atlas(V2TileCatalog.TOWN_TILES["bfp_truck"]) == Vector2i(5, 3), "bfp_truck deve ser 5x3")
	_assert_ok(t_src.get_tile_size_in_atlas(V2TileCatalog.TOWN_TILES["coastal_tree_a"]) == Vector2i(2, 3), "coastal_tree_a deve ser 2x3")
	var sea_coord: Vector2i = V2TileCatalog.TOWN_TILES["sea_water_anim"]
	_assert_ok(t_src.get_tile_animation_frames_count(sea_coord) == 3, "sea_water_anim deve ter 3 frames")
	print("[PASS] Tileset de Agdangan (Sari-Sari, casas, coqueiros, viatura BFP e mar) íntegro.")

	# 4. Interiores: sawali, paredes, móveis e geladeira
	var i_ts := V2TileCatalog.load_tileset("interiors", "normal")
	var i_src := i_ts.get_source(0) as TileSetAtlasSource
	_assert_ok(i_src.get_tile_size_in_atlas(V2TileCatalog.INTERIOR_TILES["bed_huwag"]) == Vector2i(3, 4), "bed_huwag deve ser 3x4")
	_assert_ok(i_src.get_tile_size_in_atlas(V2TileCatalog.INTERIOR_TILES["fridge_sari"]) == Vector2i(2, 3), "fridge_sari deve ser 2x3")
	_assert_ok(i_src.get_tile_size_in_atlas(V2TileCatalog.INTERIOR_TILES["dispatch_desk"]) == Vector2i(6, 2), "dispatch_desk deve ser 6x2")
	var wall_td := i_src.get_tile_data(V2TileCatalog.INTERIOR_TILES["wall_wood_mid"], 0)
	_assert_ok(bool(wall_td.get_custom_data("blocks_light")) == true, "Parede de madeira deve bloquear luz")
	_assert_ok(wall_td.get_collision_polygons_count(0) >= 1, "Parede de madeira deve ter colisão")
	print("[PASS] Tileset de Interiores íntegro.")

	# 5. Shaders atmosféricos e AtmosphereRig (incluindo preservação do Ato III sem filtro)
	_assert_ok(AtmosphereRig.FOG_SHADER != null and not AtmosphereRig.FOG_SHADER.code.is_empty(), "fog_drift.gdshader deve carregar")
	_assert_ok(AtmosphereRig.CANOPY_SHADER != null and not AtmosphereRig.CANOPY_SHADER.code.is_empty(), "canopy_proximity.gdshader deve carregar")

	var host := Node2D.new()
	root.add_child(host)
	var mod_morning := AtmosphereRig.apply_canvas_modulate(host, "morning", false)
	var mod_night := AtmosphereRig.apply_canvas_modulate(host, "night", false)
	_assert_ok(mod_morning == mod_night, "apply_canvas_modulate deve reutilizar AtmosphereModulate")
	var morning_spec := AtmosphereRig.get_mood_spec("morning", false)
	var night_spec := AtmosphereRig.get_mood_spec("night", false)
	_assert_ok((night_spec["ambient"] as Color).r < (morning_spec["ambient"] as Color).r, "Noite deve ser mais escura que manhã")

	AtmosphereRig.apply_canvas_modulate(host, "distorted", true)
	_assert_ok(mod_night.color == AtmosphereRig.MOOD_PRESETS["act3_unfiltered"]["ambient"], "Ato III deve sobrepor qualquer mood com paleta clínica")

	var fog_dist := AtmosphereRig.create_fog_overlay(Vector2(640, 360), "forest_night", false, true)
	_assert_ok(fog_dist.visible == true, "Névoa deve ficar visível no Ato 1/2")
	_assert_ok(float((fog_dist.material as ShaderMaterial).get_shader_parameter("distortion_mix")) > 0.5, "Modo distorcido deve ativar distortion_mix")

	var fog_act3 := AtmosphereRig.create_fog_overlay(Vector2(640, 360), "distorted", true, true)
	_assert_ok(fog_act3.visible == false, "Névoa sobrenatural deve ser desativada no Ato III")
	_assert_ok(float((fog_act3.material as ShaderMaterial).get_shader_parameter("fog_density")) == 0.0, "fog_density deve ser 0.0 no Ato III")

	var res_norm := AtmosphereRig.attach_lit_vfx(host, "santelmo_flame", Vector2(100, 100), Color("#FF7A3A"), 0.9, 1.3, 0.55, false)
	_assert_ok(res_norm["vfx"] != null and res_norm["light"] != null, "attach_lit_vfx deve criar chama + PointLight2D em Ato 1/2")

	var res_act3 := AtmosphereRig.attach_lit_vfx(host, "santelmo_flame", Vector2(120, 100), Color("#FF7A3A"), 0.9, 1.3, 0.55, true)
	_assert_ok(res_act3["vfx"] == null and res_act3["light"] != null, "Ato III deve suprimir santelmo_flame sobrenatural mantendo luz física se houver")

	var candle_act3 := AtmosphereRig.attach_lit_vfx(host, "candle_flicker", Vector2(140, 100), Color("#FFB85C"), 0.8, 1.2, 0.45, true)
	_assert_ok(candle_act3["vfx"] != null, "Vela comum (candle_flicker) permanece no Ato III")

	var pt := AtmosphereRig.create_point_light(Vector2.ZERO, Color.WHITE, 1.0, 1.5, true)
	_assert_ok(pt.shadow_enabled and pt.shadow_filter == Light2D.SHADOW_FILTER_NONE, "Sombras de PointLight2D devem usar SHADOW_FILTER_NONE para pixel art")

	var occ := AtmosphereRig.create_rect_occluder(Vector2(32, 32), Vector2(16, 16))
	_assert_ok(occ.occluder != null and occ.occluder.closed == true, "LightOccluder2D deve ser fechado")

	fog_dist.free()
	fog_act3.free()
	pt.free()
	occ.free()
	host.free()
	await process_frame
	print("[PASS] Shaders, AtmosphereRig e invariantes do Ato III validados com sucesso.")
	quit(0)
