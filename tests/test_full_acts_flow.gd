extends SceneTree

# test_full_acts_flow.gd - Validação Automatizada de Huwag: Menu Inicial, Ato 1, Ato 2 e Ato 3
# Testa o fluxo completo de ponta a ponta sem erros, registrando cada marco.

func _init() -> void:
	create_timer(15.0).timeout.connect(func() -> void:
		push_error("TIMEOUT: test_full_acts_flow excedeu 15s")
		quit(1)
	)
	call_deferred("_run_test_suite")

func _assert_ok(cond: bool, msg: String) -> void:
	if not cond:
		push_error("[FAIL] " + msg)
		printerr("[FAIL] " + msg)
		quit(1)

func _run_test_suite() -> void:
	print("======================================================================")
	print("=== INICIANDO VALIDAÇÃO DO FLUXO COMPLETO: MENU -> ATO 1 -> ATO 2 -> ATO 3 ===")
	print("======================================================================")

	# 1. Configurar Autoloads (reutiliza autoloads ativos da SceneTree)
	var gs: Node = root.get_node_or_null("GameState")
	if gs == null:
		var gs_class = load("res://scripts/autoload/game_state.gd")
		gs = gs_class.new()
		gs.name = "GameState"
		root.add_child(gs)
	print("[PASS] Autoload GameState instanciado.")

	var am: Node = root.get_node_or_null("AudioManager")
	if am == null:
		var am_class = load("res://scripts/autoload/audio_manager.gd")
		am = am_class.new()
		am.name = "AudioManager"
		root.add_child(am)
	print("[PASS] Autoload AudioManager instanciado.")

	# 2. Testar Menu Inicial (TitleScreen)
	print("\n--- ETAPA 1: Verificação da Tela Inicial (TitleScreen) ---")
	var title_scene = load("res://scenes/menu/TitleScreen.tscn")
	assert(title_scene != null, "Falha ao carregar TitleScreen.tscn")
	var title_inst = title_scene.instantiate()
	root.add_child(title_inst)
	await process_frame
	await process_frame

	var btn_new = title_inst.get_node_or_null("MenuContainer/MenuVBox/BtnNewGame") as Button
	var btn_cont = title_inst.get_node_or_null("MenuContainer/MenuVBox/BtnContinue") as Button
	var btn_exit = title_inst.get_node_or_null("MenuContainer/MenuVBox/BtnExit") as Button
	assert(btn_new != null and btn_cont != null and btn_exit != null, "Botões do menu ausentes!")
	var menu_vbox = title_inst.get_node_or_null("MenuContainer/MenuVBox")
	for child in menu_vbox.get_children():
		if child is Button:
			assert((child as Button).text.find("Ato") == -1, "Menu não deve ter botões de Ato explícitos!")
	var cover_art = title_inst.get_node_or_null("CoverArt") as TextureRect
	var title_lbl = title_inst.get_node_or_null("HeaderBox/TitleLabel") as Label
	var btn_load = title_inst.get_node_or_null("MenuContainer/MenuVBox/BtnLoadGame") as Button
	var btn_credits = title_inst.get_node_or_null("MenuContainer/MenuVBox/BtnMusicCredits") as Button
	assert(cover_art != null and cover_art.texture != null, "TitleScreen deve exibir CoverArt limpa!")
	assert(title_lbl != null and title_lbl.text == "HUWAG", "TitleLabel deve exibir HUWAG!")
	assert(btn_load != null and btn_credits != null, "BtnLoadGame e BtnMusicCredits devem estar presentes no menu!")
	assert(title_inst.get_node_or_null("OsdTimecodeLabel") == null and title_inst.get_node_or_null("OsdTapeLabel") == null,
		"Poluição VHS OSD antiga não deve existir na TitleScreen limpa!")
	print("[PASS] Menu inicial limpo validado (sem botões de Ato e sem OSD VHS poluído).")

	title_inst.queue_free()
	await process_frame

	# 3. Testar Ato 1 (Início às 06:30, Ciclo Dia/Noite 06:30 -> 18:00 -> 23:00 e Sono Automático)
	print("\n--- ETAPA 2: Validação do Relógio (06:30 -> 18:00 -> 23:00) e Transição Automática ---")
	gs.reset_to_new_game()
	gs.in_game_minutes_per_real_second = 0.0 # controle determinístico no teste
	assert(int(gs.get_var("Ato", 1)) == 1, "Ato inicial incorreto")
	assert(gs.get_clock_minutes() == 390 and gs.get_formatted_time() == "06:30", "Ato 1 deve iniciar às 06:30")
	assert(gs.get_day_period() == "morning", "Período inicial deve ser morning")
	assert(gs.perception_mode == gs.PerceptionMode.FILTERED_MORNING, "Modo de percepção inicial incorreto")

	# Instanciar Main para validar HUD sem rótulo de Ato e FSM de sono às 23:00
	var main_scene: PackedScene = load("res://scenes/main/Main.tscn")
	var main_node = main_scene.instantiate()
	root.add_child(main_node)
	for _i in range(6):
		await process_frame
	var dbox = main_node.get_node_or_null("CanvasLayer/DialogueBox")
	if dbox and dbox.is_open():
		dbox.close_dialogue()
	await process_frame

	var hud_label := main_node.get_node_or_null("CanvasLayer/HudTopRight/Margin/HBox/ActPlaceLabel") as Label
	assert(hud_label != null, "ActPlaceLabel deve existir no HUD")
	assert(hud_label.text.begins_with("06:30 ·") and hud_label.text.find("Ato") == -1, "HUD deve exibir horário e não 'Ato': %s" % hud_label.text)
	print("[PASS] HUD exibe horário discreto sem rótulo de Ato: %s" % hud_label.text)

	# Quartel - Capitão Reyes apresenta ocorrência e jogador elimina 1 Santelmo antes das 23:00
	gs.set_switch("002_Chefe_Ato1_apresentado", true)
	gs.mark_forest_santelmo_defeated("Santelmo1")
	assert(gs.is_task_active("ato1_ovos_floresta"), "Tarefa do Ato 1 deve ficar ativa")
	assert(gs.get_defeated_forest_santelmo_count() == 1, "Santelmo derrotado contabilizado")

	# Dia 1 -> 23:00 com tarefa em andamento: avança para Dia 2 preservando todas as tarefas e switches (sem forçar Ato 2)
	gs.set_clock_minutes(1380, true)
	var el_day := 0.0
	while main_node.get_sleep_state() != 0 and el_day < 3.0:
		main_node._process(0.10)
		await process_frame
		el_day += 0.10
	_assert_ok(int(gs.get_var("Ato", 1)) == 1 and gs.day_number == 2, "Às 23:00 com tarefa pendente, avança para Dia 2 mantendo Ato 1")
	_assert_ok(gs.get_switch("002_Chefe_Ato1_apresentado") == true and gs.is_task_active("ato1_ovos_floresta"), "Tarefas ativas e progresso com Capitão Reyes preservados entre dias")
	_assert_ok(gs.get_defeated_forest_santelmo_count() == 1, "Santelmos derrotados preservados ao acordar no dia seguinte")
	print("[PASS] Capitão Reyes apresentou ocorrência e sistema contínuo preservou tarefas ao passar de dia às 23:00.")

	# Clareira - Encontro com a criatura e coleta do ovo (avança para Fim de Tarde 16:00)
	gs.set_switch("003_Ovos_sem_derrotar", true)
	gs.set_switch("016_Magia_de_agua_obtida", true)
	gs.trigger_turn_afternoon()
	assert(gs.is_afternoon == true and gs.get_day_period() == "afternoon", "Falha ao virar a tarde")
	assert(gs.perception_mode == gs.PerceptionMode.FILTERED_AFTERNOON, "Fim de tarde não aplicou filtro âmbar")
	print("[PASS] Encontro na clareira pacífico: Magia de Água obtida e tarde ativada (%s)." % gs.get_formatted_time())

	# Avança para 18:00 (Noite) e verifica transição de período
	gs.set_clock_minutes(1080, true)
	await process_frame
	assert(gs.get_day_period() == "night" and gs.is_night_time(), "Às 18:00 deve entrar no período noturno")
	var mat_main := (main_node.get_node("PerceptionLayer/PerceptionRect") as ColorRect).material as ShaderMaterial
	_assert_ok(float(mat_main.get_shader_parameter("night_mix")) > 0.15, "Shader deve aplicar night_mix às 18:00")
	print("[PASS] Ciclo noturno às 18:00 ativado com sucesso.")

	# Atinge 23:00 (1380 min) -> Dispara sono automático e transição orgânica para o dia seguinte (Ato 2)
	gs.set_clock_minutes(1380, true)
	_assert_ok(gs.sleep_transition_active == true, "Às 23:00 deve bloquear inputs via sleep_transition_active")
	_assert_ok(main_node.get_sleep_state() != 0, "Main deve entrar na FSM de sono às 23:00")

	var elapsed := 0.0
	while main_node.get_sleep_state() != 0 and elapsed < 3.0:
		main_node._process(0.10)
		await process_frame
		elapsed += 0.10

	_assert_ok(main_node.get_sleep_state() == 0 and gs.sleep_transition_active == false, "FSM de sono deve concluir e liberar controles")
	_assert_ok(int(gs.get_var("Ato", 1)) == 2, "Sono automático às 23:00 deve avançar do Ato 1 para o Ato 2")
	_assert_ok(gs.get_clock_minutes() == 390 and gs.get_formatted_time() == "06:30", "Novo dia deve iniciar às 06:30")
	print("[PASS] Sono automático às 23:00 concluiu transição orgânica para o novo dia às 06:30.")

	main_node.queue_free()
	await process_frame

	# 4. Testar Ato 2 — ROTA 1 (MODO NORMAL COMPLETO: Chefe -> 3 Missões Simples -> Dormir -> Ato 3 -> VHS -> Fim da Demo)
	print("\n--- ETAPA 3: Validação ROTA 1 (Normal Completo + Persistência 23:00 + Ato 3 -> VHS -> Fim da Demo) ---")
	gs.set_higher_dose(false)
	_assert_ok(not gs.is_corrupted_mode(), "Dose padrão mantém corrupted_mode == false")

	# Fala com Capitão Reyes no FireStation para iniciar as missões da rua no Ato 2
	var fs_sc: PackedScene = load("res://scenes/levels/FireStation.tscn")
	var fs_inst = fs_sc.instantiate()
	root.add_child(fs_inst)
	await process_frame
	fs_inst._on_npc_interacted("Cap_Reyes")
	await process_frame
	_assert_ok(gs.get_switch("007_Chefe_Ato2_apresentado"), "Capitão Reyes liberou as missões do Ato 2")
	fs_inst.queue_free()
	await process_frame

	# Entra na StreetPreview e executa as 3 missões simples (Aling Nena, Mang Carding, Feirante)
	var street_sc: PackedScene = load("res://scenes/levels/StreetPreview.tscn")
	var st_inst = street_sc.instantiate()
	root.add_child(st_inst)
	await process_frame

	# Missão 1: Aling Nena (iniciar -> pegar suprimentos -> entregar)
	st_inst._on_interactable_triggered("NPC_Aling_Nena")
	_assert_ok(gs.get_switch("010_Missao_chave2_aberta"), "Missão da Aling Nena aberta")
	st_inst._on_interactable_triggered("Missao_Suprimentos_Nena")
	_assert_ok(gs.has_item("suprimentos_nena"), "Pacote de suprimentos coletado para Aling Nena")
	st_inst._on_interactable_triggered("NPC_Aling_Nena")
	_assert_ok(gs.get_switch("011_Missao_chave2_concluida"), "Missão 1 (Aling Nena) concluída")

	# Valida persistência contínua se o relógio virar 23:00 no meio do Ato 2
	var day_before_curfew: int = gs.day_number
	gs.advance_day_preserving_tasks()
	_assert_ok(gs.day_number == day_before_curfew + 1 and int(gs.get_var("Ato", 1)) == 2, "Virada de dia no meio do Ato 2 mantém Ato 2")
	_assert_ok(gs.get_switch("007_Chefe_Ato2_apresentado") and gs.get_switch("011_Missao_chave2_concluida"), "Progresso com Chefe e Aling Nena preservado após virada das 23:00")

	# Missão 2: Mang Carding (iniciar -> recolher cesto na areia -> devolver)
	st_inst._on_interactable_triggered("NPC_Mang_Carding")
	_assert_ok(gs.get_switch("012_Missao_chave3_aberta"), "Missão do Mang Carding aberta")
	st_inst._on_interactable_triggered("Missao_Cesto_Carding")
	_assert_ok(gs.has_item("cesto_carding"), "Cesto e corda recolhidos na areia")
	st_inst._on_interactable_triggered("NPC_Mang_Carding")
	_assert_ok(gs.get_switch("013_Missao_chave3_concluida"), "Missão 2 (Mang Carding) concluída")

	# Missão 3: Feirante (iniciar -> fixar aviso na Igreja -> confirmar)
	st_inst._on_interactable_triggered("NPC_Feirante")
	_assert_ok(gs.get_switch("008_Missao_chave1_aberta"), "Missão do Feirante aberta")
	st_inst._on_interactable_triggered("Missao_Aviso_Igreja")
	_assert_ok(gs.has_item("aviso_igreja_verificado"), "Aviso BFP fixado na praça da igreja")
	st_inst._on_interactable_triggered("NPC_Feirante")
	_assert_ok(gs.get_switch("009_Missao_chave1_concluida"), "Missão 3 (Feirante) concluída")
	_assert_ok(gs.are_all_normal_street_missions_completed() and gs.get_switch("019_Ato2_concluido"), "Todas as 3 missões normais concluídas liberam dormir para Ato 3")
	st_inst.queue_free()
	await process_frame
	print("[PASS] Rota 1 (Normal): 3 missões simples concluídas e persistência de tarefas validada.")

	# Dormir no Quarto no fim do Ato 2 -> Avança para Ato 3
	var room_sc: PackedScene = load("res://scenes/levels/RoomHuwag.tscn")
	var room_act2 = room_sc.instantiate()
	root.add_child(room_act2)
	await process_frame
	var bed_cb_holder := {"cb": Callable()}
	room_act2.request_dialogue.connect(func(_pages: Array, cb: Callable) -> void:
		if cb.is_valid():
			bed_cb_holder["cb"] = cb
	)
	room_act2._on_interactable_triggered("Cama")
	_assert_ok(bed_cb_holder["cb"].is_valid(), "Cama no fim do Ato 2 abre escolha de dormir")
	bed_cb_holder["cb"].call(0) # Dormir até o amanhecer -> Ato 3
	_assert_ok(int(gs.get_var("Ato", 1)) == 3 and gs.is_unfiltered_act3(), "Dormir no fim do Ato 2 avança para o Ato 3 (sem filtro)")

	# 5. Ato 3: Dormir na cama -> Minigame VHS -> Tela de Encerramento da Demo
	print("\n--- ETAPA 4: Ato 3 -> Sono Final -> Minigame VHS -> Tela de Encerramento da Demo ---")
	var act3_level_req := {"scene": ""}
	room_act2.request_level_change.connect(func(target: String, _tag: String) -> void:
		act3_level_req["scene"] = target
	)
	bed_cb_holder["cb"] = Callable()
	room_act2._on_interactable_triggered("Cama")
	_assert_ok(bed_cb_holder["cb"].is_valid(), "Cama no Ato 3 libera sono final para Minigame VHS")
	bed_cb_holder["cb"].call(0)
	_assert_ok(act3_level_req["scene"].ends_with("vhs_memory_minigame.tscn"), "Dormir no Ato 3 transiciona direto para vhs_memory_minigame.tscn")
	room_act2.queue_free()
	await process_frame

	var vhs_scene = load("res://scenes/levels/vhs_memory_minigame.tscn")
	assert(vhs_scene != null, "Falha ao carregar vhs_memory_minigame.tscn")
	var vhs_inst = vhs_scene.instantiate()
	root.add_child(vhs_inst)
	await process_frame
	var vhs_next := {"scene": ""}
	vhs_inst.request_level_change.connect(func(target: String, _tag: String) -> void:
		vhs_next["scene"] = target
	)
	vhs_inst.complete_minigame()
	_assert_ok(gs.get_switch("023_Ato3_pesadelo_vhs_concluido") and gs.get_switch("026_Jogo_finalizado"), "Conclusão do VHS marca switches finais")
	_assert_ok(vhs_next["scene"].ends_with("EndingCredits.tscn"), "Conclusão do VHS abre Tela de Encerramento da Demo")
	vhs_inst.queue_free()
	await process_frame

	var ending_scene = load("res://scenes/menu/EndingCredits.tscn")
	assert(ending_scene != null, "Falha ao carregar EndingCredits.tscn")
	var ending_inst = ending_scene.instantiate()
	root.add_child(ending_inst)
	await process_frame
	var demo_title := ending_inst.get_node_or_null("CenterContainer/DemoCard/Margin/VBox/TitleLabel") as Label
	var demo_route := ending_inst.get_node_or_null("CenterContainer/DemoCard/Margin/VBox/RouteTitleLabel") as Label
	var demo_btn := ending_inst.get_node_or_null("CenterContainer/DemoCard/Margin/VBox/BtnMainMenu") as Button
	_assert_ok(demo_title != null and demo_title.text.find("FIM DA DEMO") != -1, "Tela de encerramento exibe 'FIM DA DEMO'")
	_assert_ok(demo_route != null and demo_route.text.find("ESTÁVEL") != -1, "Resumo exibe rota Normal concluída: %s" % (demo_route.text if demo_route else ""))
	_assert_ok(demo_btn != null and demo_btn.text.find("Menu Principal") != -1, "Botão 'Voltar ao Menu Principal' presente na Tela de Encerramento")
	ending_inst.queue_free()
	await process_frame
	print("[PASS] Ato 3 -> Dormir -> Minigame VHS -> Tela de Encerramento da Demo (Rota Normal) validado.")

	# 6. Validar ROTA 2 (Corrompida Completa) e ROTA 3 (Corrompida + Reversão pela Enfermeira Maria)
	print("\n--- ETAPA 5: Validação ROTA 2 (Corrompida Completa) & ROTA 3 (Reversão pela Enfermeira) ---")
	gs.reset_to_new_game()
	gs.advance_to_act_2()
	gs.set_higher_dose(true)
	_assert_ok(gs.is_corrupted_mode() and int(gs.get_var("Intoxicacao", 0)) == 2, "Rota 2: Modo Corrompido ativado pela maior dose")

	# Fala com Chefe -> Vai à rua -> Verifica exatamente 2 escolhas (Conversar + Provocar) e derrota os 3 NPCs
	var fs_corr = fs_sc.instantiate()
	root.add_child(fs_corr)
	await process_frame
	fs_corr._on_npc_interacted("Cap_Reyes")
	_assert_ok(gs.get_switch("007_Chefe_Ato2_apresentado"), "Rota 2: Chefe ativou objetivo corrompido")
	fs_corr.queue_free()
	await process_frame

	var st_corr = street_sc.instantiate()
	root.add_child(st_corr)
	await process_frame
	for task_npc_id in ["NPC_Aling_Nena", "NPC_Mang_Carding", "NPC_Feirante"]:
		var dlg_check := {"choices": [], "conflicts": {}}
		var conn_fn := func(pages: Array, _cb: Callable) -> void:
			if pages.size() > 0:
				dlg_check["choices"] = pages[0].get("choices", [])
				dlg_check["conflicts"] = pages[0].get("conflict_choices", {})
		st_corr.request_dialogue.connect(conn_fn, CONNECT_ONE_SHOT)
		st_corr._on_interactable_triggered(task_npc_id)
		_assert_ok(dlg_check["choices"].size() == 2 and dlg_check["conflicts"].get(1, "") == task_npc_id,
			"Rota 2: %s exibe 2 opções (Conversar + Provocação Hostil)" % task_npc_id)
		st_corr._on_dialogue_conflict_triggered(task_npc_id, {})
		var npc_obj: NpcEntity = st_corr._npcs[task_npc_id]
		_assert_ok(npc_obj.is_hostile, "Rota 2: %s ficou hostil após provocação" % task_npc_id)
		npc_obj.receive_melee_hit(999, st_corr.player.global_position)
		await process_frame
		_assert_ok(npc_obj.is_defeated and gs.is_corrupted_npc_defeated(task_npc_id), "Rota 2: %s derrotado e registrado" % task_npc_id)
	_assert_ok(gs.are_all_corrupted_street_npcs_defeated(), "Rota 2: Todos os 3 NPCs hostis da rua derrotados")
	st_corr.queue_free()
	await process_frame

	# Volta ao Chefe -> libera dormir -> Ato 3 -> Fim da Demo com rota Corrompida
	var fs_corr2 = fs_sc.instantiate()
	root.add_child(fs_corr2)
	await process_frame
	fs_corr2._on_npc_interacted("Cap_Reyes")
	_assert_ok(gs.get_switch("019_Ato2_concluido") and gs.act2_route_completed == "corrupted", "Rota 2: Falar com Chefe após derrotar todos libera dormir (rota corrompida)")
	fs_corr2.queue_free()
	await process_frame
	gs.advance_to_act_3()
	_assert_ok(str(gs.get_demo_route_summary().get("route_id", "")) == "corrupted", "Resumo da Demo identifica rota Corrompida")
	print("[PASS] Rota 2 (Corrompida Completa) validada 100%.")

	# ROTA 3: Dose Maior -> Falar com Enfermeira Maria -> Checagem e Antídoto -> Reverte para Modo Normal -> Conclui 3 Missões -> Ato 3
	gs.reset_to_new_game()
	gs.advance_to_act_2()
	gs.set_higher_dose(true)
	gs.set_switch("007_Chefe_Ato2_apresentado", true)
	gs.mark_corrupted_npc_defeated("NPC_Aling_Nena")
	_assert_ok(gs.is_corrupted_mode() and gs.get_defeated_corrupted_street_npc_count() == 1, "Rota 3: Iniciou no Modo Corrompido com 1 NPC derrotado")

	var fs_nurse = fs_sc.instantiate()
	root.add_child(fs_nurse)
	await process_frame
	var nurse_cbs: Array[Callable] = []
	fs_nurse.request_dialogue.connect(func(_pages: Array, cb: Callable) -> void:
		if cb.is_valid():
			nurse_cbs.append(cb)
	)
	fs_nurse._on_npc_interacted("Enfermeira_Maria")
	_assert_ok(nurse_cbs.size() >= 1, "Rota 3: Enfermeira Maria oferece checagem médica")
	nurse_cbs[0].call(0) # Aceitar checagem
	_assert_ok(nurse_cbs.size() >= 2, "Rota 3: Após checagem, Enfermeira Maria oferece medicação de reversão")
	nurse_cbs[1].call(0) # Aceitar e tomar a medicação de reversão
	await process_frame
	_assert_ok(not gs.is_corrupted_mode() and gs.get_switch("006d_Enfermeira_reverteu_dose"), "Rota 3: Reversão pela Enfermeira desativou Modo Corrompido")
	_assert_ok(fs_nurse.get_node("FloorNormal").visible and not fs_nurse.get_node("FloorDistorted").visible, "Rota 3: Visual do Quartel revertido ao Normal")
	_assert_ok(gs.get_defeated_corrupted_street_npc_count() == 0 and gs.is_task_active("ato2_ocorrencias_cidade"), "Rota 3: NPCs da rua restaurados e tasks normais reativadas")
	fs_nurse.queue_free()
	await process_frame

	# Conclui as 3 missões normais após reversão e confirma rota "reverted"
	gs.complete_optional_mission("011_Missao_chave2_concluida")
	gs.complete_optional_mission("013_Missao_chave3_concluida")
	gs.complete_optional_mission("009_Missao_chave1_concluida")
	_assert_ok(gs.get_switch("019_Ato2_concluido") and gs.act2_route_completed == "reverted", "Rota 3: Conclusão das 3 missões pós-reversão libera Ato 3")
	gs.advance_to_act_3()
	gs.set_switch("026_Jogo_finalizado", true)
	_assert_ok(str(gs.get_demo_route_summary().get("route_id", "")) == "reverted", "Resumo da Demo identifica rota de Reversão pela Enfermeira")
	print("[PASS] Rota 3 (Corrompida + Reversão pela Enfermeira Maria) validada 100%.")

	# 7. Testar Persistência de Save / Load e Resumo de Horário no Menu Principal
	print("\n--- ETAPA 6: Validação do Sistema de Save, Load e Horário no Menu ---")
	gs.set_clock_minutes(1125, false) # 18:45
	assert(gs.save_game() == true, "Falha ao salvar jogo")
	assert(gs.has_save_file() == true, "Arquivo de save não detectado após salvar")

	var summary = gs.get_save_summary()
	assert(str(summary.get("clock_hhmm", "")) == "18:45", "Resumo do save deve conter clock_hhmm == 18:45")
	print("[PASS] Resumo do save gerado: Horário %s, Local: %s, HP: %d" % [summary.get("clock_hhmm"), summary.get("place"), summary.get("hp")])

	var title_check = title_scene.instantiate()
	root.add_child(title_check)
	await process_frame
	var save_lbl = title_check.get_node_or_null("SaveSummaryLabel") as Label
	assert(save_lbl != null and save_lbl.text.find("18:45") != -1 and save_lbl.text.find("Ato") == -1, "SaveSummaryLabel deve exibir horário salvo sem rótulo de Ato: %s" % save_lbl.text)
	title_check.queue_free()
	await process_frame

	assert(gs.load_game() == true, "Falha ao carregar save")
	assert(int(gs.get_var("Ato", 1)) == 3, "Ato carregado diverge do salvo")
	assert(gs.get_formatted_time() == "18:45", "Horário carregado diverge do salvo")
	assert(gs.get_switch("026_Jogo_finalizado") == true, "Switches carregados divergem dos salvos")
	print("[PASS] Carregamento de save e exibição de horário no menu 100% íntegros e validados.")

	print("\n======================================================================")
	print("=== TODOS OS TESTES PASSARAM COM 100% DE SUCESSO! HUWAG ATOS 1–3 PRONTO! ===")
	print("======================================================================")
	quit(0)
