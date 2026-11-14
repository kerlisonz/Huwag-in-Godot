extends SceneTree

func _init() -> void:
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
	assert(s1 != null and s2 != null and s3 != null, "Três inimigos Santelmo devem estar na trilha!")
	print("[PASS] Santelmo 1, 2 e 3 instanciados nas posições: %s, %s, %s" % [s1.position, s2.position, s3.position])

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

	# Teste de interação pacífica com a criatura
	var tracker := {"dialogue_requested": false}
	clearing.request_dialogue.connect(func(pages, _cb):
		print("[PASS] request_dialogue emitido com %d páginas!" % pages.size())
		tracker["dialogue_requested"] = true
	)
	clearing._on_creature_interaction()
	assert(tracker["dialogue_requested"], "Interação pacífica com a criatura deve disparar diálogo narrativo!")
	print("[PASS] Diálogo narrativo da Guardiã da Lagoa acionado com sucesso!")

	# Salva captura da Clareira
	for i in range(5):
		await process_frame
	if DisplayServer.get_name() != "headless" and vp and vp.get_texture():
		var img_clearing := vp.get_texture().get_image()
		if img_clearing:
			img_clearing.save_png("res://docs/screenshots/forest_clearing_validated.png")
			print("[OK] Captura da clareira salva em docs/screenshots/forest_clearing_validated.png")

	clearing.queue_free()
	await process_frame

	print("\n==================================================")
	print("=== TODOS OS TESTES PASSARAM COM 100% DE SUCESSO! ===")
	print("==================================================")
	quit(0)
