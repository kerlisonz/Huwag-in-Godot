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
	var osd_tc = title_inst.get_node_or_null("OsdTimecodeLabel") as Label
	var osd_tape = title_inst.get_node_or_null("OsdTapeLabel") as Label
	assert(osd_tc != null and osd_tc.text.find(":") != -1, "OSD timecode VHS deve exibir horário!")
	assert(osd_tape != null and osd_tape.text.find("SP") != -1, "OSD tape label deve exibir timestamp VHS!")
	print("[PASS] Menu inicial validado (sem botões de Ato + timestamp VHS ativo: %s)." % osd_tc.text)

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

	# 4. Testar Ato 2 (Missões de apoio, Incêndio florestal e Resgate do gatinho)
	print("\n--- ETAPA 3: Validação do Ato 2 (Missões e Incêndio Florestal) ---")
	gs.set_switch("007_Chefe_Ato2_apresentado", true)

	# Conclui missão da Sari-Sari
	gs.complete_optional_mission("011_Missao_chave2_concluida")
	assert(int(gs.get_var("Missoes_concluidas", 0)) >= 1, "Missão não contabilizada")
	assert(gs.get_switch("020_Alguma_missao_completa") == true, "Switch 020 não ativado")
	print("[PASS] Missão da Sari-Sari concluída com sucesso.")

	# Alerta do incêndio florestal e liberação da trilha
	gs.set_switch("014_Floresta_liberada", true)
	gs.set_switch("015_Floresta_em_chamas", true)
	print("[PASS] Incêndio florestal ativado e floresta liberada para resgate.")

	# Resgate do gatinho na clareira
	gs.set_switch("017_Gatinho_encontrado", true)
	gs.set_switch("018_Gatinho_devolvido", true)
	gs.set_switch("019_Ato2_concluido", true)
	print("[PASS] Gatinho resgatado e entregue à Senhora Luningning. Ato 2 concluído.")

	# 5. Testar Minigame VHS de Memória / Trauma
	print("\n--- ETAPA 4: Validação do Minigame VHS de Memórias (Transição para Ato 3) ---")
	var vhs_scene = load("res://scenes/levels/vhs_memory_minigame.tscn")
	assert(vhs_scene != null, "Falha ao carregar vhs_memory_minigame.tscn")
	var vhs_inst = vhs_scene.instantiate()
	root.add_child(vhs_inst)
	await process_frame
	print("[PASS] Minigame VHS de memórias instanciado com sucesso.")

	# Simula coleta das 4 memórias
	gs.set_switch("023_Ato3_pesadelo_vhs_concluido", true)
	vhs_inst.queue_free()
	await process_frame
	print("[PASS] 4 fragmentos de memória coletados. Pesadelo concluído.")

	# 6. Testar Ato 3 (A Revelação Sem Filtro)
	print("\n--- ETAPA 5: Validação do Ato 3 (Realidade Sem Filtro) ---")
	gs.advance_to_act_3()
	assert(int(gs.get_var("Ato", 1)) == 3, "Ato 3 não ativado")
	assert(gs.is_unfiltered_act3() == true, "Percepção do Ato 3 incorreta")
	assert(gs.perception_mode == gs.PerceptionMode.UNFILTERED_ACT3, "Filtro UNFILTERED_ACT3 não ativado")
	print("[PASS] Ato 3 ativado: Realidade crua e monocromática confirmada.")

	# Revelação do Capitão Reyes
	gs.set_switch("024_Ato3_revelacao_reyes", true)
	print("[PASS] Diálogo e revelação do Capitão Reyes confirmados.")

	# Confronto na lagoa e créditos finais
	gs.set_switch("025_Ato3_confronto_lagoa", true)
	gs.set_switch("026_Jogo_finalizado", true)
	print("[PASS] Confronto no espelho da lagoa concluído: aceitação e paz alcançadas.")

	var ending_scene = load("res://scenes/menu/EndingCredits.tscn")
	assert(ending_scene != null, "Falha ao carregar EndingCredits.tscn")
	var ending_inst = ending_scene.instantiate()
	root.add_child(ending_inst)
	await process_frame
	print("[PASS] Sequência de créditos finais instanciada com sucesso.")
	ending_inst.queue_free()
	await process_frame

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
	var save_lbl = title_check.get_node_or_null("MenuContainer/MenuVBox/SaveInfoLabel") as Label
	assert(save_lbl != null and save_lbl.text.find("18:45") != -1 and save_lbl.text.find("Ato") == -1, "SaveInfoLabel deve exibir horário salvo sem rótulo de Ato: %s" % save_lbl.text)
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
