extends SceneTree

## Valida os props reutilizáveis da floresta (ForestTree, ForestBush, ForestCoconutTree),
## colisão física, duplicação, Y-sort, atenuação de copa e variantes Normal/Distorcida/Ato 3.

const ForestPropScript := preload("res://scripts/components/forest_prop.gd")

func _init() -> void:
	create_timer(15.0).timeout.connect(func() -> void:
		push_error("TIMEOUT: test_forest_props_collision excedeu 15s")
		quit(1)
	)
	call_deferred("_run")


func _assert_ok(cond: bool, msg: String) -> void:
	if not cond:
		push_error("[FAIL] " + msg)
		printerr("[FAIL] " + msg)
		quit(1)


func _test_collision_against_prop(player: CharacterBody2D, prop: Node2D, label: String) -> void:
	_assert_ok(prop != null, label + " ausente")
	_assert_ok(prop is StaticBody2D, label + " deve ser StaticBody2D")
	var sb := prop as StaticBody2D
	_assert_ok(sb.y_sort_enabled, label + " deve manter y_sort_enabled=true")
	_assert_ok((sb.collision_layer & 1) != 0, label + " deve existir na layer 1")
	var col := prop.get_node_or_null("CollisionShape2D") as CollisionShape2D
	_assert_ok(col != null and col.shape != null and not col.disabled, label + " precisa de CollisionShape2D ativo")

	player.global_position = prop.global_position + Vector2(0, 28)
	var blocked := false
	var last_blocker: Variant = null
	for _i in range(25):
		var hit := player.move_and_collide(Vector2(0, -2.0))
		if hit != null:
			last_blocker = hit.get_collider()
			if last_blocker == prop:
				blocked = true
				break
	_assert_ok(blocked, label + " deve bloquear o PlayerHuwag (pos=%s, player=%s, hit=%s)" % [prop.global_position, player.global_position, str(last_blocker)])
	if blocked:
		print("[PASS] %s colidiu e bloqueou o jogador." % label)


func _run() -> void:
	var gs: Node = root.get_node_or_null("GameState")
	if gs == null:
		var gs_script := load("res://scripts/autoload/game_state.gd") as Script
		gs = gs_script.new()
		gs.name = "GameState"
		root.add_child(gs)
	gs.call("reset_to_new_game")

	# 1. Cenas reutilizáveis + duplicação (Ctrl+D no Editor)
	for comp_name in [
		"ForestTree", "ForestBush", "ForestCoconutTree",
		"ForestWitheredPine", "ForestSlenderPine", "ForestGnarledTree", "ForestRoundTree", "ForestAncientTree"
	]:
		var sc := load("res://scenes/components/%s.tscn" % comp_name) as PackedScene
		_assert_ok(sc != null, "%s.tscn deve carregar" % comp_name)
		var inst := sc.instantiate() as StaticBody2D
		_assert_ok(inst != null and inst is ForestPropScript, "%s deve instanciar ForestProp" % comp_name)
		var dup := inst.duplicate() as StaticBody2D
		_assert_ok(dup != null and dup.get_node_or_null("CollisionShape2D") != null and dup.get_node_or_null("Sprite2D") != null,
			"%s.duplicate() preserva Sprite2D e CollisionShape2D" % comp_name)
		inst.free()
		dup.free()
	print("[PASS] Todas as 8 cenas reutilizáveis e duplicação validadas.")

	# 1b. TileSetScenesCollectionSource nos 3 TileSets (Ato 1/2 Normal, Dose Maior, Ato 3)
	var expected_scenes := {
		1: "res://scenes/components/ForestTree.tscn",
		2: "res://scenes/components/ForestBush.tscn",
		3: "res://scenes/components/ForestCoconutTree.tscn",
		4: "res://scenes/components/ForestRock.tscn",
		5: "res://scenes/components/ForestWitheredPine.tscn",
		6: "res://scenes/components/ForestSlenderPine.tscn",
		7: "res://scenes/components/ForestGnarledTree.tscn",
		8: "res://scenes/components/ForestRoundTree.tscn",
		9: "res://scenes/components/ForestAncientTree.tscn",
	}
	for ts_path in [
		"res://assets/tilesets/v2/forest_v2_normal_tileset.tres",
		"res://assets/tilesets/v2/forest_v2_distorted_tileset.tres",
		"res://assets/tilesets/v2/forest_v2_act3_tileset.tres",
	]:
		var ts := load(ts_path) as TileSet
		_assert_ok(ts != null, ts_path + " deve carregar como TileSet")
		_assert_ok(ts.has_source(1), ts_path + " precisa ter source 1 (TileSetScenesCollectionSource)")
		var sc_src := ts.get_source(1) as TileSetScenesCollectionSource
		_assert_ok(sc_src != null, ts_path + " source 1 deve ser TileSetScenesCollectionSource")
		_assert_ok(sc_src.get_scene_tiles_count() >= 9, ts_path + " deve expor ao menos 9 cenas pintáveis")
		for sid in expected_scenes.keys():
			var ps := sc_src.get_scene_tile_scene(sid)
			_assert_ok(ps != null and ps.resource_path == expected_scenes[sid],
				"%s cena id=%d deve apontar para %s" % [ts_path, sid, expected_scenes[sid]])
	print("[PASS] TileSetScenesCollectionSource (source 1, ids 1..9) validada em normal/distorted/act3.")

	# 2. ForestTrail + ForestCorridor
	var trail_sc := load("res://scenes/levels/forest_trail.tscn") as PackedScene
	var trail := trail_sc.instantiate()
	root.add_child(trail)
	await process_frame
	await process_frame

	var t_player := trail.get_node("ObstaclesYsort/PlayerHuwag") as CharacterBody2D
	var t_tree := trail.get_node_or_null("ObstaclesYsort/ForestTree") as Node2D
	var t_bush := trail.get_node_or_null("ObstaclesYsort/ForestBush") as Node2D

	_test_collision_against_prop(t_player, t_tree, "ForestTrail/ForestTree")
	_test_collision_against_prop(t_player, t_bush, "ForestTrail/ForestBush")

	# Atenuação da copa atrás da árvore + troca de texturas Atos 1-3
	t_player.global_position = t_tree.global_position + Vector2(0, -30)
	await process_frame
	await process_frame
	var t_spr := t_tree.get_node("Sprite2D") as Sprite2D
	var t_mat := t_spr.material as ShaderMaterial
	_assert_ok(t_mat != null and bool(t_mat.get_shader_parameter("proximity_fade_enabled")) == true,
		"ForestTree atenua copa quando jogador passa atrás")
	_assert_ok(bool(t_mat.get_shader_parameter("use_local_y")) == true and float(t_mat.get_shader_parameter("wind_strength")) > 0.5,
		"ForestTree possui animação de vento pixel-snapped ancorada na base")
	var b_mat := (t_bush.get_node("Sprite2D") as Sprite2D).material as ShaderMaterial
	_assert_ok(b_mat != null and float(b_mat.get_shader_parameter("wind_strength")) > 0.5,
		"ForestBush possui animação de vento")

	# 2b. PaintedPropsLayer — pintura por arraste (TileMapLayer + TileSetScenesCollectionSource)
	var t_painted := trail.get_node_or_null("ObstaclesYsort/PaintedPropsLayer") as TileMapLayer
	_assert_ok(t_painted != null, "ForestTrail precisa de ObstaclesYsort/PaintedPropsLayer")
	_assert_ok(t_painted.y_sort_enabled, "PaintedPropsLayer precisa manter y_sort_enabled=true")
	_assert_ok(t_painted.tile_set != null and t_painted.tile_set.has_source(1),
		"PaintedPropsLayer deve vir com forest_v2_normal_tileset (source 1) no Editor")
	var tree_cell := Vector2i(88, 24)
	var bush_cell := Vector2i(90, 24)
	var palm_cell := Vector2i(92, 24)
	t_painted.set_cell(tree_cell, 1, Vector2i.ZERO, 1) # ForestTree
	t_painted.set_cell(bush_cell, 1, Vector2i.ZERO, 2) # ForestBush
	t_painted.set_cell(palm_cell, 1, Vector2i.ZERO, 3) # ForestCoconutTree
	await process_frame
	await process_frame
	_assert_ok(t_painted.get_child_count() == 3,
		"PaintedPropsLayer deve instanciar 3 cenas ao pintar células (obtido %d)" % t_painted.get_child_count())
	var target_tree_pos := t_painted.map_to_local(tree_cell)
	var target_palm_pos := t_painted.map_to_local(palm_cell)
	var painted_tree: Node2D = null
	var painted_palm: Node2D = null
	for ch in t_painted.get_children():
		if ch is Node2D and (ch as Node2D).position.distance_to(target_tree_pos) < 4.0:
			painted_tree = ch as Node2D
		elif ch is Node2D and (ch as Node2D).position.distance_to(target_palm_pos) < 4.0:
			painted_palm = ch as Node2D
	_assert_ok(painted_tree != null, "ForestTree pintado deve ser encontrado próximo à célula (88, 24)")
	_assert_ok(painted_palm != null, "ForestCoconutTree pintado deve ser encontrado próximo à célula (92, 24)")
	_test_collision_against_prop(t_player, painted_tree, "PaintedPropsLayer/ForestTree")
	_test_collision_against_prop(t_player, painted_palm, "PaintedPropsLayer/ForestCoconutTree")
	var pt_mat := (painted_tree.get_node("Sprite2D") as Sprite2D).material as ShaderMaterial
	var pp_mat := (painted_palm.get_node("Sprite2D") as Sprite2D).material as ShaderMaterial
	_assert_ok(pt_mat != null and float(pt_mat.get_shader_parameter("wind_strength")) > 0.5,
		"ForestTree pintado no TileMapLayer mantém animação de vento")
	_assert_ok(pp_mat != null and float(pp_mat.get_shader_parameter("wind_strength")) > 0.5,
		"ForestCoconutTree pintado no TileMapLayer mantém animação de vento")

	# Simula refresh de preview no Editor: PaintedPropsLayer e células pintadas não podem ser apagados
	var helpers := load("res://scripts/levels/retro_level_helpers.gd")
	helpers.call("cleanup_editor_preview", trail)
	_assert_ok(trail.get_node_or_null("ObstaclesYsort/PaintedPropsLayer") == t_painted and t_painted.get_cell_source_id(tree_cell) == 1,
		"cleanup_editor_preview não deve remover PaintedPropsLayer nem células pintadas")

	gs.call("advance_to_act_2")
	gs.call("set_higher_dose", true)
	await process_frame
	await process_frame
	_assert_ok(t_spr.texture.resource_path.ends_with("forest_v2_distorted.png"), "ForestTree usa forest_v2_distorted em Dose Maior")
	_assert_ok(float(t_mat.get_shader_parameter("distortion_jitter")) > 0.1, "ForestTree ativa tremor de distorção na Dose Maior")
	_assert_ok((t_bush.get_node("Sprite2D") as Sprite2D).texture.resource_path.ends_with("forest_v2_distorted.png"), "ForestBush usa distorted")
	_assert_ok(t_painted.tile_set.resource_path.ends_with("forest_v2_distorted_tileset.tres"),
		"PaintedPropsLayer troca para forest_v2_distorted_tileset na Dose Maior")
	_assert_ok(t_painted.get_child_count() == 3,
		"PaintedPropsLayer preserva os 3 props após troca de TileSet na Dose Maior")
	for pch in t_painted.get_children():
		var painted_distorted_spr := (pch as Node2D).get_node("Sprite2D") as Sprite2D
		_assert_ok(painted_distorted_spr.texture.resource_path.ends_with("forest_v2_distorted.png"),
			"Prop pintado (%s) atualiza textura para forest_v2_distorted.png na Dose Maior" % pch.name)

	# 2c. Estrutura organizada de ForestTrail (GroundNormal assado, ForestTrees otimizado, Santelmos sem filhos aninhados)
	var t_ground := trail.get_node("GroundNormal") as TileMapLayer
	var t_walls := trail.get_node("WallsNormal") as TileMapLayer
	_assert_ok(t_ground.get_child_count() == 0 and t_ground.get_used_cells().size() == 7680,
		"ForestTrail/GroundNormal deve ter 7680 tiles (160x48) sem árvores filhas")
	_assert_ok(t_walls.get_child_count() == 0,
		"ForestTrail/WallsNormal não deve conter árvores filhas")
	var mossy_rock_cells := 0
	for w_cell in t_walls.get_used_cells():
		if t_walls.get_cell_atlas_coords(w_cell) == Vector2i(25, 13):
			mossy_rock_cells += 1
	_assert_ok(mossy_rock_cells == 0,
		"ForestTrail/WallsNormal não deve conter blocos de pedras musgosas (rock_round_a) removidos (obtido %d)" % mossy_rock_cells)
	_assert_ok(trail.get_node_or_null("TrailBoundaries/NorthWall/NorthWall") == null,
		"NorthWall duplicado removido de ForestTrail")
	_assert_ok(trail.get_node_or_null("ForestTree142") == null,
		"ForestTree142 solto na raiz removido de ForestTrail")
	var t_trees := trail.get_node_or_null("ObstaclesYsort/ForestTrees") as Node2D
	_assert_ok(t_trees != null and t_trees.y_sort_enabled and t_trees.get_child_count() >= 900,
		"ForestTrail possui ObstaclesYsort/ForestTrees densa com y_sort_enabled (obtido %d)" % (t_trees.get_child_count() if t_trees else -1))
	_assert_ok(t_trees.get_node_or_null("AncientTree_1") == null and t_trees.get_node_or_null("AncientTree_2") == null,
		"ForestTrail sem as 2 ForestAncientTree gigantes removidas a pedido")
	var t_batched_count := 0
	for ft_ch in t_trees.get_children():
		if not bool(ft_ch.get("enable_proximity_fade")):
			t_batched_count += 1
	_assert_ok(t_batched_count >= 400,
		"ForestTrail/ForestTrees deve manter loteamento GPU em árvores de fundo (obtido %d)" % t_batched_count)
	var t_sample_tree := t_trees.get_child(0) as Node2D
	_assert_ok(t_sample_tree.is_visible_in_tree() and (t_sample_tree.get_node("Sprite2D") as Sprite2D).texture.resource_path.ends_with("forest_v2_distorted.png"),
		"ForestTrail/ForestTrees permanece visível e usa forest_v2_distorted.png na Dose Maior")
	var ysort_node := trail.get_node("ObstaclesYsort") as Node2D
	for y_ch in ysort_node.get_children():
		if y_ch.scene_file_path.ends_with("santelmo.tscn"):
			for s_ch in y_ch.get_children():
				_assert_ok(not s_ch.scene_file_path.ends_with("santelmo.tscn") and not (s_ch is ForestPropScript),
					"%s não pode conter Santelmos nem árvores aninhadas (%s)" % [y_ch.name, s_ch.name])

	gs.call("advance_to_act_3")
	await process_frame
	await process_frame
	_assert_ok(t_spr.texture.resource_path.ends_with("forest_v2_act3.png"), "ForestTree usa forest_v2_act3 no Ato 3")
	_assert_ok(t_painted.tile_set.resource_path.ends_with("forest_v2_act3_tileset.tres"),
		"PaintedPropsLayer troca para forest_v2_act3_tileset no Ato 3")
	for pch in t_painted.get_children():
		var painted_act3_spr := (pch as Node2D).get_node("Sprite2D") as Sprite2D
		_assert_ok(painted_act3_spr.texture.resource_path.ends_with("forest_v2_act3.png"),
			"Prop pintado (%s) atualiza textura para forest_v2_act3.png no Ato 3" % pch.name)
	_assert_ok(t_sample_tree.is_visible_in_tree() and (t_sample_tree.get_node("Sprite2D") as Sprite2D).texture.resource_path.ends_with("forest_v2_act3.png"),
		"ForestTrail/ForestTrees permanece visível e usa forest_v2_act3.png no Ato 3")

	trail.queue_free()
	await process_frame

	var corr_sc := load("res://scenes/levels/ForestCorridor.tscn") as PackedScene
	var corr := corr_sc.instantiate()
	root.add_child(corr)
	await process_frame
	_assert_ok(corr.get_node_or_null("ObstaclesYsort/ForestTree") != null, "ForestCorridor herda ForestTree")
	_assert_ok(corr.get_node_or_null("ObstaclesYsort/ForestBush") != null, "ForestCorridor herda ForestBush")
	_assert_ok(corr.get_node_or_null("ObstaclesYsort/ForestTrees") != null, "ForestCorridor herda ForestTrees")
	_assert_ok(corr.get_node_or_null("ObstaclesYsort/PaintedPropsLayer") != null, "ForestCorridor herda PaintedPropsLayer")
	corr.queue_free()
	await process_frame

	# 3. ForestClearing otimizada (chão + Lagoa + Guardião + Ovos + ForestTrees em Y-sort + corredor oeste livre)
	gs.call("reset_to_new_game")
	var clear_sc := load("res://scenes/levels/forest_clearing.tscn") as PackedScene
	var clearing := clear_sc.instantiate()
	root.add_child(clearing)
	await process_frame
	await process_frame

	_assert_ok(clearing.get_node_or_null("ObstaclesYsort/AquaticCreature") != null, "ForestClearing mantém Guardião")
	_assert_ok(clearing.get_node_or_null("ObstaclesYsort/EggNest") != null, "ForestClearing mantém EggNest")
	_assert_ok(clearing.get_node_or_null("PondWaterBody") != null and clearing.get_node_or_null("WaterRipples") != null,
		"ForestClearing mantém Lagoa Azul (PondWaterBody + WaterRipples)")
	_assert_ok(clearing.get_node_or_null("ExitToTrailArea") != null, "ForestClearing mantém ExitToTrailArea")
	_assert_ok(clearing.get_node_or_null("ClearingBoundaries") != null, "ForestClearing mantém bordas invisíveis")
	for removed_name in ["Rock_1", "Rock_2", "ForestBush", "V2UnderstoryLayer", "V2CanopyLayer", "V2GroundClutterLayer"]:
		_assert_ok(clearing.find_child(removed_name, true, false) == null,
			"ForestClearing removida de " + removed_name)

	var c_ground := clearing.get_node("GroundNormal") as TileMapLayer
	_assert_ok(c_ground.get_child_count() == 0, "GroundNormal não deve conter árvores filhas (quebraria Dose Maior e Y-sort)")
	_assert_ok(c_ground.get_used_cells().size() >= 2100, "GroundNormal deve manter o piso preenchido (obtido %d)" % c_ground.get_used_cells().size())

	var c_trees_root := clearing.get_node_or_null("ObstaclesYsort/ForestTrees") as Node2D
	_assert_ok(c_trees_root != null and c_trees_root.y_sort_enabled,
		"ForestClearing precisa de ObstaclesYsort/ForestTrees com y_sort_enabled=true")
	var tree_count := c_trees_root.get_child_count()
	_assert_ok(tree_count >= 150 and tree_count <= 400,
		"ForestTrees deve manter contagem otimizada (obtido %d)" % tree_count)

	var rim_tree: Node2D = null
	var bg_mats := {}
	var bg_checked := 0
	for ch in c_trees_root.get_children():
		_assert_ok(ch is ForestPropScript, "Filho de ForestTrees deve ser ForestProp")
		for sub in ch.get_children():
			_assert_ok(not (sub is StaticBody2D), "Árvore não pode ter outra árvore aninhada dentro dela")
		var n2d := ch as Node2D
		if n2d.position.x >= 260.0 and n2d.position.x <= 420.0 and n2d.position.y >= 165.0 and n2d.position.y <= 215.0:
			if rim_tree == null or n2d.position.y > rim_tree.position.y:
				rim_tree = n2d
		if not bool(ch.get("enable_proximity_fade")):
			_assert_ok(not ch.is_processing(), "Árvore de fundo sem fade deve desativar _process()")
			var bmat := (ch.get_node("Sprite2D") as Sprite2D).material as ShaderMaterial
			if bmat != null:
				bg_mats[bmat.get_instance_id()] = true
			bg_checked += 1
	_assert_ok(bg_checked > 50 and bg_mats.size() <= 6,
		"Árvores de fundo devem compartilhar ShaderMaterial em lote (bg=%d, mats=%d)" % [bg_checked, bg_mats.size()])
	_assert_ok(rim_tree != null, "Deve existir árvore na borda norte interna da clareira para teste de colisão")

	var c_player := clearing.get_node("ObstaclesYsort/PlayerHuwag") as CharacterBody2D
	# Corredor oeste: caminhada livre pelo eixo central (y=243) até ExitToTrailArea (x<=24) e até a clareira (x>=400)
	c_player.global_position = Vector2(96, 243)
	for _i in range(25):
		c_player.move_and_collide(Vector2(-4.0, 0.0))
	_assert_ok(c_player.global_position.x <= 24.0,
		"Corredor oeste deve permitir voltar até ExitToTrailArea (x=%f)" % c_player.global_position.x)
	c_player.global_position = Vector2(96, 243)
	for _i in range(80):
		c_player.move_and_collide(Vector2(4.0, 0.0))
	_assert_ok(c_player.global_position.x >= 400.0,
		"Corredor oeste deve levar livremente até a clareira/Lagoa (x=%f)" % c_player.global_position.x)

	var c_painted := clearing.get_node_or_null("ObstaclesYsort/PaintedPropsLayer") as TileMapLayer
	_assert_ok(c_painted != null and c_painted.y_sort_enabled and c_painted.tile_set != null,
		"ForestClearing possui PaintedPropsLayer configurada com tile_set")
	c_painted.set_cell(Vector2i(16, 16), 1, Vector2i.ZERO, 5) # ForestWitheredPine pintado
	await process_frame
	await process_frame
	_assert_ok(c_painted.get_child_count() == 1, "ForestClearing/PaintedPropsLayer instancia pinheiro seco pintado")

	_test_collision_against_prop(c_player, rim_tree, "ForestClearing/ForestTrees/" + rim_tree.name)
	_test_collision_against_prop(c_player, c_painted.get_child(0) as Node2D, "ForestClearing/PaintedPropsLayer/ForestWitheredPine")

	# Valida visibilidade e troca de textura em Ato 2 Dose Maior e Ato 3 nas árvores de ForestTrees
	gs.call("advance_to_act_2")
	gs.call("set_higher_dose", true)
	await process_frame
	await process_frame
	_assert_ok(rim_tree.is_visible_in_tree(), "Árvores em ForestTrees permanecem visíveis na Dose Maior")
	_assert_ok((rim_tree.get_node("Sprite2D") as Sprite2D).texture.resource_path.ends_with("forest_v2_distorted.png"),
		"Árvores da clareira trocam para forest_v2_distorted.png na Dose Maior")
	gs.call("advance_to_act_3")
	await process_frame
	await process_frame
	_assert_ok(rim_tree.is_visible_in_tree(), "Árvores em ForestTrees permanecem visíveis no Ato 3")
	_assert_ok((rim_tree.get_node("Sprite2D") as Sprite2D).texture.resource_path.ends_with("forest_v2_act3.png"),
		"Árvores da clareira trocam para forest_v2_act3.png no Ato 3")

	# Testa borda invisível norte sem atravessar
	c_player.global_position = Vector2(200, 12)
	for _i in range(20):
		c_player.move_and_collide(Vector2(0, -2.0))
	_assert_ok(c_player.global_position.y >= 0.0, "ClearingBoundaries norte impede saída do mapa")

	clearing.queue_free()
	await process_frame

	print("[PASS] Todos os props de vegetação com colisão na floresta validados com 100% de sucesso!")
	quit(0)
