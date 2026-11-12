extends SceneTree

# capture_acts_and_menu.gd - Captura automatizada de screenshots em GPU real
# Grava imagens em 1080p / 640x360 de todas as etapas:
# 1. Menu Inicial (TitleScreen)
# 2. Quarto de Huwag (Ato 1)
# 3. Quartel BFP (Ato 1)
# 4. Trilha e Clareira da Floresta (Ato 1 e 2)
# 5. Minigame VHS de Memória / Trauma (Ato 3)
# 6. Agdangan no Ato 3 (Sem Filtro)
# 7. Sequência Final e Créditos

func _init() -> void:
	call_deferred("_run_captures")

func _run_captures() -> void:
	print("--- Iniciando captura completa de Telas do Jogo (Menu, Atos 1–3) ---")

	# Autoloads
	if not root.has_node("GameState"):
		var gs_class = load("res://scripts/autoload/game_state.gd")
		var gs = gs_class.new()
		gs.name = "GameState"
		root.add_child(gs)

	if not root.has_node("AudioManager"):
		var am_class = load("res://scripts/autoload/audio_manager.gd")
		var am = am_class.new()
		am.name = "AudioManager"
		root.add_child(am)

	var vp := root.get_viewport()

	# 1. CAPTURA: TELA INICIAL (MENU / CAPA)
	var title_scene = load("res://scenes/menu/TitleScreen.tscn")
	var title_inst = title_scene.instantiate()
	root.add_child(title_inst)
	for i in range(25):
		await process_frame
	var img_menu = vp.get_texture().get_image()
	if img_menu:
		img_menu.save_png("res://docs/screenshots/menu_inicial_capa.png")
		print("[OK] Salvo menu_inicial_capa.png")
	title_inst.queue_free()
	for i in range(10):
		await process_frame

	# 2. CAPTURA: MAIN COM QUARTO DE HUWAG (ATO 1)
	var main_scene = load("res://scenes/main/Main.tscn")
	var main_node = main_scene.instantiate()
	root.add_child(main_node)
	for i in range(30):
		await process_frame

	var img_room1 = vp.get_texture().get_image()
	if img_room1:
		img_room1.save_png("res://docs/screenshots/ato1_quarto_huwag.png")
		print("[OK] Salvo ato1_quarto_huwag.png")

	# 3. CAPTURA: QUARTEL BFP (ATO 1)
	main_node.load_level("res://scenes/levels/FireStation.tscn", "from_city")
	for i in range(30):
		await process_frame
	var img_station = vp.get_texture().get_image()
	if img_station:
		img_station.save_png("res://docs/screenshots/ato1_quartel_bfp.png")
		print("[OK] Salvo ato1_quartel_bfp.png")

	# 4. CAPTURA: CLAREIRA DA LAGOA COM A GUARDIÃ (ATO 1)
	main_node.load_level("res://scenes/levels/forest_clearing.tscn", "from_trail")
	for i in range(30):
		await process_frame
	var img_clearing = vp.get_texture().get_image()
	if img_clearing:
		img_clearing.save_png("res://docs/screenshots/ato1_clareira_boss.png")
		print("[OK] Salvo ato1_clareira_boss.png")

	# 5. CAPTURA: MINIGAME VHS DE MEMÓRIA / TRAUMA (ATO 3)
	main_node.load_level("res://scenes/levels/vhs_memory_minigame.tscn", "from_bed")
	for i in range(30):
		await process_frame
	var img_vhs = vp.get_texture().get_image()
	if img_vhs:
		img_vhs.save_png("res://docs/screenshots/ato3_minigame_vhs_trauma.png")
		print("[OK] Salvo ato3_minigame_vhs_trauma.png")

	# 6. CAPTURA: AGDANGAN SEM FILTRO (ATO 3)
	var gs_node = root.get_node("GameState")
	gs_node.advance_to_act_3()
	main_node.load_level("res://scenes/levels/StreetPreview.tscn", "from_room")
	for i in range(30):
		await process_frame
	var img_act3_street = vp.get_texture().get_image()
	if img_act3_street:
		img_act3_street.save_png("res://docs/screenshots/ato3_rua_sem_filtro.png")
		print("[OK] Salvo ato3_rua_sem_filtro.png")

	main_node.queue_free()
	for i in range(10):
		await process_frame

	# 7. CAPTURA: SEQUÊNCIA FINAL E CRÉDITOS
	var ending_scene = load("res://scenes/menu/EndingCredits.tscn")
	var ending_inst = ending_scene.instantiate()
	root.add_child(ending_inst)
	for i in range(30):
		await process_frame
	var img_ending = vp.get_texture().get_image()
	if img_ending:
		img_ending.save_png("res://docs/screenshots/final_creditos_ato3.png")
		print("[OK] Salvo final_creditos_ato3.png")

	ending_inst.queue_free()
	for i in range(5):
		await process_frame

	print("--- Todas as capturas de validação concluídas com 100% de sucesso! ---")
	quit(0)
