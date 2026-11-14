extends SceneTree

# capture_acts_and_menu.gd - Captura automatizada de screenshots em GPU real
# Grava imagens atuais (estética FNAF Minigames / Yume Nikki) para o README:
#  1. menu_inicial_capa.png      (Tela inicial VHS)
#  2. ato1_quarto_huwag.png      (Quarto de Huwag — Ato 1)
#  3. ato1_rua_agdangan.png      (Avenida de Agdangan — Ato 1 dia)
#  4. ato1_quartel_bfp.png       (Quartel BFP multi-ala + retrato CRT)
#  5. ato2_rua_dose_alta.png     (Agdangan Ato 2 — Dose Alta distorcida + VHS)
#  6. ato1_trilha_santelmo.png   (Trilha da floresta com Santelmos)
#  7. ato1_clareira_boss.png     (Clareira da lagoa com a Guardiã)
#  8. ato3_minigame_vhs_trauma.png (Minigame VHS do incêndio de 2025)
#  9. ato3_rua_sem_filtro.png    (Agdangan sem filtro — Ato 3)
# 10. final_creditos_ato3.png    (Sequência final e créditos)


func _init() -> void:
	call_deferred("_run_captures")


func _wait_frames(n: int) -> void:
	for _i in range(n):
		await process_frame


func _save_shot(filename: String) -> void:
	var img := root.get_viewport().get_texture().get_image()
	if img == null:
		push_error("Viewport sem imagem para " + filename)
		return
	var out_path := "res://docs/screenshots/" + filename
	img.save_png(out_path)
	print("[OK] Salvo %s (%dx%d)" % [filename, img.get_width(), img.get_height()])


func _run_captures() -> void:
	print("--- Iniciando captura completa de Telas do Jogo (Menu, Atos 1–3) ---")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://docs/screenshots"))

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

	var gs_node: Node = root.get_node("GameState")

	# 1. MENU INICIAL (CAPA VHS)
	var title_scene: PackedScene = load("res://scenes/menu/TitleScreen.tscn")
	var title_inst := title_scene.instantiate()
	root.add_child(title_inst)
	await _wait_frames(25)
	_save_shot("menu_inicial_capa.png")
	title_inst.queue_free()
	await _wait_frames(8)

	# Evita popups iniciais bloqueando a câmera na primeira captura do quarto
	gs_node.call("reset_to_new_game")
	gs_node.call("set_self_switch", "EV_Introducao", "A", true)

	# 2. QUARTO DE HUWAG (ATO 1)
	var main_scene: PackedScene = load("res://scenes/main/Main.tscn")
	var main_node := main_scene.instantiate()
	root.add_child(main_node)
	await _wait_frames(30)
	_save_shot("ato1_quarto_huwag.png")

	# 3. AVENIDA DE AGDANGAN (ATO 1 DIA)
	main_node.call("load_level", "res://scenes/levels/StreetPreview.tscn", "from_room")
	await _wait_frames(30)
	_save_shot("ato1_rua_agdangan.png")

	# 4. QUARTEL BFP (ATO 1) + CAIXA DE DIÁLOGO CRT DO CAP. REYES
	main_node.call("load_level", "res://scenes/levels/FireStation.tscn", "from_city")
	await _wait_frames(25)
	main_node.call("_on_request_dialogue", [{
		"speaker": "Cap. Reyes",
		"portrait": "cap_reyes",
		"text": "Bom dia, Matitiis. Mantenha o rádio ligado e conclua a vistoria do setor norte."
	}], Callable())
	await _wait_frames(20)
	_save_shot("ato1_quartel_bfp.png")
	# Fecha diálogo antes de seguir
	var dlg := main_node.get_node_or_null("CanvasLayer/DialogueBox")
	if dlg:
		dlg.hide()
		dlg.set("active", false)
	gs_node.set("dialogue_active", false)
	main_node.call("_update_hud_visibility")

	# 5. AGDANGAN NO ATO 2 — DOSE ALTA DISTORCIDA + VHS
	gs_node.call("advance_to_act_2")
	gs_node.call("set_higher_dose", true)
	main_node.call("load_level", "res://scenes/levels/StreetPreview.tscn", "from_station")
	await _wait_frames(30)
	_save_shot("ato2_rua_dose_alta.png")

	# Volta para dose normal ao mostrar a trilha e clareira limpas
	gs_node.call("set_higher_dose", false)
	gs_node.call("reset_to_new_game")
	gs_node.call("set_self_switch", "EV_Introducao", "A", true)
	var status_lbl := main_node.get_node_or_null("CanvasLayer/StatusLabel")
	if status_lbl:
		status_lbl.text = ""
	main_node.set("_toast_timer", 0.0)

	# 6. TRILHA DA FLORESTA COM SANTELMOS
	main_node.call("load_level", "res://scenes/levels/forest_trail.tscn", "from_city")
	await _wait_frames(15)
	var tr_player = root.find_child("PlayerHuwag", true, false)
	if tr_player:
		tr_player.position = Vector2(280, 340)
		tr_player.set("facing_dir", Vector2.RIGHT)
	await _wait_frames(20)
	_save_shot("ato1_trilha_santelmo.png")

	# 7. CLAREIRA DA LAGOA COM A GUARDIÃ E NINHO AZUL
	main_node.call("load_level", "res://scenes/levels/forest_clearing.tscn", "from_trail")
	await _wait_frames(15)
	var cl_player = root.find_child("PlayerHuwag", true, false)
	if cl_player:
		cl_player.position = Vector2(360, 240)
		cl_player.set("facing_dir", Vector2.RIGHT)
	await _wait_frames(25)
	_save_shot("ato1_clareira_boss.png")

	# 8. MINIGAME VHS DE MEMÓRIA / TRAUMA (ATO 3)
	gs_node.call("advance_to_act_3")
	main_node.call("load_level", "res://scenes/levels/vhs_memory_minigame.tscn", "from_bed")
	await _wait_frames(30)
	_save_shot("ato3_minigame_vhs_trauma.png")

	# 9. AGDANGAN SEM FILTRO (ATO 3)
	main_node.call("load_level", "res://scenes/levels/StreetPreview.tscn", "from_room")
	await _wait_frames(30)
	_save_shot("ato3_rua_sem_filtro.png")

	main_node.queue_free()
	await _wait_frames(10)

	# 10. SEQUÊNCIA FINAL E CRÉDITOS
	var ending_scene: PackedScene = load("res://scenes/menu/EndingCredits.tscn")
	var ending_inst := ending_scene.instantiate()
	root.add_child(ending_inst)
	ending_inst.set("_scroll_pos", 260.0)
	await _wait_frames(10)
	_save_shot("final_creditos_ato3.png")

	ending_inst.queue_free()
	await _wait_frames(5)

	print("--- Todas as 10 capturas concluídas com sucesso! ---")
	quit(0)
