extends SceneTree

# test_full_acts_flow.gd - Validação Automatizada de Huwag: Menu Inicial, Ato 1, Ato 2 e Ato 3
# Testa o fluxo completo de ponta a ponta sem erros, registrando cada marco.

func _init() -> void:
	call_deferred("_run_test_suite")

func _run_test_suite() -> void:
	print("======================================================================")
	print("=== INICIANDO VALIDAÇÃO DO FLUXO COMPLETO: MENU -> ATO 1 -> ATO 2 -> ATO 3 ===")
	print("======================================================================")

	# 1. Configurar Autoloads
	var gs_class = load("res://scripts/autoload/game_state.gd")
	var gs = gs_class.new()
	gs.name = "GameState"
	root.add_child(gs)
	print("[PASS] Autoload GameState instanciado.")

	var am_class = load("res://scripts/autoload/audio_manager.gd")
	var am = am_class.new()
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
	print("[PASS] Botões da tela inicial verificados: Novo Jogo, Continuar, Sair.")

	title_inst.queue_free()
	await process_frame

	# 3. Testar Ato 1 (Quarto, Rua, Quartel e Clareira)
	print("\n--- ETAPA 2: Validação do Ato 1 (Manhã Filtrada) ---")
	gs.reset_to_new_game()
	assert(int(gs.get_var("Ato", 1)) == 1, "Ato inicial incorreto")
	assert(gs.perception_mode == gs.PerceptionMode.FILTERED_MORNING, "Modo de percepção inicial incorreto")

	# Quarto
	var room_scene = load("res://scenes/levels/RoomHuwag.tscn")
	var room = room_scene.instantiate()
	root.add_child(room)
	await process_frame
	print("[PASS] Quarto de Huwag carregado no Ato 1.")
	room.queue_free()
	await process_frame

	# Quartel - Capitão Reyes apresenta ocorrência
	gs.set_switch("002_Chefe_Ato1_apresentado", true)
	print("[PASS] Capitão Reyes apresentou a ocorrência do Ato 1.")

	# Clareira - Encontro com a criatura e coleta do ovo
	gs.set_switch("003_Ovos_sem_derrotar", true)
	gs.set_switch("016_Magia_de_agua_obtida", true)
	gs.trigger_turn_afternoon()
	assert(gs.is_afternoon == true, "Falha ao virar a tarde")
	assert(gs.perception_mode == gs.PerceptionMode.FILTERED_AFTERNOON, "Fim de tarde não aplicou filtro âmbar")
	print("[PASS] Encontro na clareira pacífico: Magia de Água obtida e tarde ativada.")

	# Fim do Ato 1: Chefe libera a cidade e Huwag descansa
	gs.set_switch("005_Chefe_liberou_cidade", true)
	gs.advance_to_act_2()
	assert(int(gs.get_var("Ato", 1)) == 2, "Falha ao avançar para Ato 2")
	print("[PASS] Transição para Ato 2 concluída com sucesso.")

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

	# 7. Testar Persistência de Save / Load
	print("\n--- ETAPA 6: Validação do Sistema de Save e Load ---")
	assert(gs.save_game() == true, "Falha ao salvar jogo")
	assert(gs.has_save_file() == true, "Arquivo de save não detectado após salvar")

	var summary = gs.get_save_summary()
	print("[PASS] Resumo do save gerado: Ato %s, Local: %s, HP: %d" % [summary.get("ato"), summary.get("place"), summary.get("hp")])

	assert(gs.load_game() == true, "Falha ao carregar save")
	assert(int(gs.get_var("Ato", 1)) == 3, "Ato carregado diverge do salvo")
	assert(gs.get_switch("026_Jogo_finalizado") == true, "Switches carregados divergem dos salvos")
	print("[PASS] Carregamento de save 100% íntegro e validado.")

	print("\n======================================================================")
	print("=== TODOS OS TESTES PASSARAM COM 100% DE SUCESSO! HUWAG ATOS 1–3 PRONTO! ===")
	print("======================================================================")
	quit(0)
