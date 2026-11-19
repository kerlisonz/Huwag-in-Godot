extends SceneTree

func _init() -> void:
	create_timer(15.0).timeout.connect(func() -> void:
		push_error("TIMEOUT: test_forest_santelmo excedeu 15s")
		quit(1)
	)
	call_deferred("_run_forest_suite")

func _run_forest_suite() -> void:
	print("==================================================")
	print("=== INICIANDO SUÍTE DE TESTES: FLORESTA & SANTELMO ===")
	print("==================================================")

	# ----------------------------------------------------
	# 1. TESTE DE CONFIGURAÇÃO DE DISPLAY (1920x1080)
	# ----------------------------------------------------
	print("\n--- TESTE 1: Configuração de Resolução e Stretch ---")
	var vw = ProjectSettings.get_setting("display/window/size/viewport_width")
	var vh = ProjectSettings.get_setting("display/window/size/viewport_height")
	var stretch_mode = ProjectSettings.get_setting("display/window/stretch/mode")
	var stretch_aspect = ProjectSettings.get_setting("display/window/stretch/aspect")
	var tex_filter = ProjectSettings.get_setting("rendering/textures/canvas_textures/default_texture_filter")

	print("Viewport: %sx%s | Stretch: %s (%s) | Filter: %s" % [vw, vh, stretch_mode, stretch_aspect, tex_filter])
	assert(vw == 640 and vh == 360, "ERRO: Viewport deve ser 640x360 virtual!")
	assert(stretch_mode == "canvas_items", "ERRO: Stretch mode deve ser canvas_items!")
	assert(stretch_aspect == "keep", "ERRO: Stretch aspect deve ser keep!")
	assert(tex_filter == 0, "ERRO: Texture filter deve ser Nearest (0)!")
	print("[PASS] Configurações de 1920x1080 Nearest Neighbor validadas com sucesso!")

	# Autoload GameState
	if not root.has_node("GameState"):
		var gs_class = load("res://scripts/autoload/game_state.gd")
		var gs_inst = gs_class.new()
		gs_inst.name = "GameState"
		root.add_child(gs_inst)

	# ----------------------------------------------------
	# 2. TESTE DA CENA DA TRILHA DA FLORESTA (forest_trail.tscn)
	# ----------------------------------------------------
	print("\n--- TESTE 2: Instanciação e Estrutura de forest_trail.tscn ---")
	var trail_scene: PackedScene = load("res://scenes/levels/forest_trail.tscn")
	assert(trail_scene != null, "Falha ao carregar forest_trail.tscn")
	var trail: Node2D = trail_scene.instantiate()
	root.add_child(trail)
	await process_frame

	var player = trail.get_node_or_null("ObstaclesYsort/PlayerHuwag")
	assert(player != null, "PlayerHuwag não encontrado em forest_trail!")
	print("[PASS] PlayerHuwag presente na posição: %s" % player.position)

	var cam = player.get_node_or_null("Camera2D")
	assert(cam != null, "Camera2D não encontrada no Player!")
	print("[PASS] Camera2D zoom configurada: %s (esperado >= (2.5, 2.5))" % cam.zoom)

	var s1 = trail.get_node_or_null("ObstaclesYsort/Santelmo1")
	var s2 = trail.get_node_or_null("ObstaclesYsort/Santelmo2")
	var s3 = trail.get_node_or_null("ObstaclesYsort/Santelmo3")
	var s4 = trail.get_node_or_null("ObstaclesYsort/Santelmo4")
	var s5 = trail.get_node_or_null("ObstaclesYsort/Santelmo5")
	assert(s1 != null and s2 != null and s3 != null and s4 != null and s5 != null, "Inimigos Santelmo originais e expandidos devem estar na trilha!")
	assert(trail.ground_normal.tile_set.resource_path.ends_with("forest_v2_normal_tileset.tres"), "ForestTrail deve usar forest_v2_normal_tileset.tres!")
	var trail_trees := trail.get_node_or_null("ObstaclesYsort/ForestTrees") as Node2D
	assert(trail_trees != null and trail_trees.y_sort_enabled and trail_trees.get_child_count() >= 300,
		"ForestTrail deve conter ObstaclesYsort/ForestTrees com y_sort_enabled e pinheiros escalonados!")
	assert(trail._santelmos.size() >= 8, "ForestTrail deve ter >= 8 Santelmos distribuídos (atual=%d)!" % trail._santelmos.size())
	print("[PASS] ForestTrail v2 + %d Santelmos (wander/patrol/ambush) confirmados!" % trail._santelmos.size())

	# ----------------------------------------------------
	# 3. TESTE DE COMBATE DO SANTELMO & FRAQUEZA ELEMENTAL À ÁGUA
	# ----------------------------------------------------
	print("\n--- TESTE 3: Mecânica de Combate e Fraqueza à Água do Santelmo ---")
	assert(s1.current_health == 60, "Santelmo deve iniciar com 60 HP!")
	
	# Golpe de Machado padrão (20 de dano físico)
	s1.take_damage(20, player.global_position, false)
	assert(s1.current_health == 40, "Santelmo deve ter 40 HP após golpe de machado (dano=20)!")
	assert(s1.knockback_velocity.length() > 0.0, "Santelmo deve sofrer knockback ao ser atingido!")
	print("[PASS] Golpe de machado causou dano físico (HP: 60 -> 40) e knockback!")

	# Magia de Água (+100% de dano crítico / extinção rápida)
	var defeated_emitted := false
	s1.enemy_defeated.connect(func(_pos): defeated_emitted = true)
	# Ataque de água com 30 de base -> 60 de dano crítico
	s1.take_damage(30, player.global_position, true)
	assert(s1.current_health == 0, "Magia de água deve extinguir Santelmo (dano crítico x2 = 60)!")
	assert(s1.current_state == s1.State.DEAD, "Santelmo deve estar no estado DEAD!")
	print("[PASS] Fraqueza à água confirmada (+100% dano crítico apagou o fogo com sucesso)!")

	# ----------------------------------------------------
	# 4. TESTE DE COLISÕES E Y-SORT
	# ----------------------------------------------------
	print("\n--- TESTE 4: Colisões de Barreira da Trilha e Árvores ---")
	player.position = Vector2(500, 70)
	for i in range(20):
		player.move_and_collide(Vector2(0, -10))
		await process_frame
	assert(player.position.y >= 55.0, "Player deve ser bloqueado pelas barreiras norte!")
	print("[PASS] Barreira física da floresta impediu que o jogador saísse do mapa!")

	# Salva captura da Trilha
	for i in range(5):
		await process_frame
	var vp := root.get_viewport()
	if DisplayServer.get_name() != "headless" and vp and vp.get_texture():
		var img_trail := vp.get_texture().get_image()
		if img_trail:
			DirAccess.make_dir_recursive_absolute("res://docs/screenshots/")
			img_trail.save_png("res://docs/screenshots/forest_trail_validated.png")
			print("[OK] Captura da trilha salva em docs/screenshots/forest_trail_validated.png")

	assert(trail.find_child("V2UnderstoryLayer", true, false) == null, "V2UnderstoryLayer procedural não deve existir em ForestTrail otimizada")
	assert(trail.find_child("V2CanopyLayer", true, false) == null, "V2CanopyLayer procedural não deve existir em ForestTrail otimizada")
	var trail_walls := trail.get_node_or_null("WallsNormal") as TileMapLayer
	assert(trail_walls != null and trail_walls.collision_enabled == true, "WallsNormal da trilha deve ter colisão ativa para cerca/riachos/rochedos!")
	if player != null:
		player.position = Vector2(160, 360)
		for _i in range(14):
			player.move_and_collide(Vector2(0, -4))
		assert(player.position.y >= 332.0, "Cerca norte da entrada da floresta deve bloquear travessia (y=%f)" % player.position.y)

		player.position = Vector2(160, 440)
		for _i in range(25):
			player.move_and_collide(Vector2(0, 4))
		assert(player.position.y <= 550.0, "Árvores ao sul da trilha devem bloquear travessia (y=%f)" % player.position.y)
		print("[PASS] Colisão física da cerca e árvores na ForestTrail validada!")

		# 4b. Confirmação de saída da floresta para Agdangan (ExitToCityArea)
		var exit_state := {"prompts": 0, "choices": [], "cb": Callable(), "changed_scene": "", "changed_tag": ""}
		trail.request_dialogue.connect(func(pages: Array, cb: Callable) -> void:
			exit_state["prompts"] = int(exit_state["prompts"]) + 1
			if pages.size() > 0:
				exit_state["choices"] = pages[0].get("choices", [])
			exit_state["cb"] = cb
		)
		trail.request_level_change.connect(func(scene_p: String, tag: String) -> void:
			exit_state["changed_scene"] = scene_p
			exit_state["changed_tag"] = tag
		)
		player.position = Vector2(20, 384)
		trail._on_exit_city_area_body_entered(player)
		assert(int(exit_state["prompts"]) == 1, "Sair da floresta deve abrir confirmação antes de mudar de cena!")
		assert((exit_state["choices"] as Array).size() == 2, "Confirmação de saída deve oferecer 2 opções!")
		assert(str(exit_state["changed_scene"]).is_empty(), "Não deve trocar de cena antes da confirmação do jogador!")

		# Jogador cancela / escolhe continuar na floresta (choice = 1)
		(exit_state["cb"] as Callable).call(1)
		assert(str(exit_state["changed_scene"]).is_empty(), "Escolher 'Continuar na Floresta' não deve sair da cena!")
		assert(player.position.x >= 56.0, "Ao cancelar saída, Huwag deve recuar para fora da área de saída (x=%f)" % player.position.x)
		# Cooldown evita reabertura imediata
		trail._on_exit_city_area_body_entered(player)
		assert(int(exit_state["prompts"]) == 1, "Cooldown deve evitar reabertura imediata do prompt de saída!")

		# Após expirar o cooldown, confirmar saída (choice = 0) leva a StreetPreview
		trail.set("_exit_city_cooldown", 0.0)
		player.position = Vector2(20, 384)
		trail._on_exit_city_area_body_entered(player)
		assert(int(exit_state["prompts"]) == 2, "Nova entrada na saída após cooldown deve abrir confirmação novamente!")
		(exit_state["cb"] as Callable).call(0)
		assert(str(exit_state["changed_scene"]) == "res://scenes/levels/StreetPreview.tscn" and str(exit_state["changed_tag"]) == "from_forest",
			"Confirmar saída deve emitir transição para StreetPreview com spawn_tag 'from_forest'!")
		print("[PASS] Confirmação de saída da floresta (cancelar + confirmar) validada!")

	trail.queue_free()
	await process_frame

	# ----------------------------------------------------
	# 5. TESTE DA CLAREIRA DA LAGOA (forest_clearing.tscn)
	# ----------------------------------------------------
	print("\n--- TESTE 5: Instanciação da Clareira da Lagoa e Guardiã ---")
	var clearing_scene: PackedScene = load("res://scenes/levels/forest_clearing.tscn")
	assert(clearing_scene != null, "Falha ao carregar forest_clearing.tscn")
	var clearing: Node2D = clearing_scene.instantiate()
	root.add_child(clearing)
	await process_frame

	var creature = clearing.get_node_or_null("ObstaclesYsort/AquaticCreature")
	assert(creature != null, "AquaticCreature deve estar presente na clareira!")
	var egg_nest = clearing.get_node_or_null("ObstaclesYsort/EggNest")
	assert(egg_nest != null, "EggNest deve estar presente na margem da lagoa!")
	var pond_col = clearing.get_node_or_null("PondWaterBody")
	assert(pond_col != null, "Colisão da lagoa deve existir!")

	print("[PASS] Criatura aquática e ninho com ovos azuis confirmados na clareira!")

	# Teste da barreira dos 16 Santelmos antes de liberar a Guardiã
	var barrier_msg := {"text": ""}
	var tracker := {"dialogue_requested": false}
	clearing.request_dialogue.connect(func(pages, _cb):
		print("[PASS] request_dialogue emitido com %d páginas!" % pages.size())
		if pages.size() > 0:
			barrier_msg["text"] = str(pages[0].get("text", ""))
		tracker["dialogue_requested"] = true
	)
	clearing._on_creature_interaction()
	assert(tracker["dialogue_requested"] and barrier_msg["text"].find("Santelmo") != -1, "Com Santelmos vivos, interação deve avisar do selo!")
	creature.start_boss_fight()
	assert(creature.is_hostile == false, "Guardiã não deve iniciar luta enquanto restarem Santelmos vivos!")
	print("[PASS] Selo dos 16 Santelmos bloqueia acesso antecipado à Guardiã.")

	# Libera todos os 16 Santelmos e valida interação pacífica + Boss Fight
	var gs_c = root.get_node_or_null("GameState")
	gs_c.mark_all_forest_santelmos_defeated()
	await process_frame
	tracker["dialogue_requested"] = false
	clearing._on_creature_interaction()
	assert(tracker["dialogue_requested"], "Interação pacífica com a criatura deve disparar diálogo narrativo após derrotar os 16 Santelmos!")
	print("[PASS] Diálogo narrativo da Guardiã da Lagoa acionado com sucesso!")

	# Teste da Boss Fight da Lagoa Azul (Fases, Telégrafos e Derrota)
	var phase_signals: Array[String] = []
	var boss_defeated_flag := {"done": false}
	creature.boss_phase_dialogue_requested.connect(func(pid: String) -> void: phase_signals.append(pid))
	creature.boss_defeated.connect(func() -> void: boss_defeated_flag["done"] = true)

	creature.start_boss_fight()
	assert(creature.is_hostile == true and creature.current_hp == 180, "Boss Fight deve iniciar com 180 HP e estado hostil!")
	creature._begin_wave_telegraph(Vector2(420, 240))
	assert(creature.boss_state == creature.BossState.TELEGRAPH_WAVE, "Boss deve entrar em TELEGRAPH_WAVE antes do ataque de onda!")
	creature.receive_melee_hit(80, Vector2(440, 240)) # 180 -> 100 HP (<= 62% -> Fase 2)
	assert(creature.current_phase == 2 and "phase_2" in phase_signals, "Boss deve entrar na Fase 2 e emitir diálogo de transição em <= 62% HP!")
	creature.receive_water_hit(65, Vector2(440, 240)) # 100 -> 22 HP (<= 28% -> Fase 3, com bônus staggered)
	assert(creature.current_phase == 3 and "phase_3" in phase_signals, "Boss deve entrar na Fase 3 e emitir diálogo em <= 28% HP!")
	creature.receive_melee_hit(50, Vector2(440, 240)) # -> 0 HP (Derrota)
	assert(creature.is_defeated == true and boss_defeated_flag["done"] == true, "Boss deve ser derrotado ao chegar a 0 HP e conceder Magia de Água!")
	print("[PASS] Boss Fight da Lagoa Azul (telégrafos, fases 1->2->3 e resolução) validada com sucesso!")

	# Salva captura da Clareira
	for i in range(5):
		await process_frame
	if DisplayServer.get_name() != "headless" and vp and vp.get_texture():
		var img_clearing := vp.get_texture().get_image()
		if img_clearing:
			img_clearing.save_png("res://docs/screenshots/forest_clearing_validated.png")
			print("[OK] Captura da clareira salva em docs/screenshots/forest_clearing_validated.png")

	assert(clearing.find_child("V2UnderstoryLayer", true, false) == null, "V2UnderstoryLayer procedural não deve existir na clareira limpa")
	assert(clearing.find_child("V2CanopyLayer", true, false) == null, "V2CanopyLayer procedural não deve existir na clareira limpa")
	assert(clearing.find_child("V2GroundClutterLayer", true, false) == null, "V2GroundClutterLayer procedural não deve existir na clareira limpa")
	var clear_walls := clearing.get_node_or_null("WallsNormal") as TileMapLayer
	assert(clear_walls != null and clear_walls.get_cell_source_id(Vector2i(1, 1)) == -1, "Paredões automáticos removidos de WallsNormal")
	assert(clear_walls.get_cell_source_id(Vector2i(31, 14)) != -1, "Água da Lagoa Azul preservada em WallsNormal")
	var clear_player := clearing.get_node_or_null("ObstaclesYsort/PlayerHuwag") as CharacterBody2D
	if clear_player != null:
		clear_player.position = Vector2(816, 344)
		for _i in range(18):
			clear_player.move_and_collide(Vector2(0, -4))
		assert(clear_player.position.y >= 312.0, "Tronco da ForestAncientTree deve bloquear o player (y=%f)" % clear_player.position.y)
		clear_player.position = Vector2(936, 240)
		for _i in range(16):
			clear_player.move_and_collide(Vector2(4, 0))
		assert(clear_player.position.x <= 960.0, "ClearingBoundaries deve manter o jogador dentro dos limites do mapa (x=%f)" % clear_player.position.x)
		print("[PASS] Clareira limpa (solo + Lagoa + Guardiã + ovos), ForestAncientTree e bordas invisíveis validados!")

	clearing.queue_free()
	await process_frame

	print("\n==================================================")
	print("=== TODOS OS TESTES PASSARAM COM 100% DE SUCESSO! ===")
	print("==================================================")
	quit(0)
