extends SceneTree

## Validação automatizada da Tela de Derrota (DefeatOverlay / game_over_ui.tscn)
## e do sistema de Checkpoint (save_checkpoint / restore_last_checkpoint) no GameState.

func _init() -> void:
	create_timer(20.0, true, false, true).timeout.connect(func() -> void:
		push_error("TIMEOUT: test_defeat_and_checkpoint excedeu 20s")
		paused = false
		quit(1)
	)
	call_deferred("_run")


func _assert_ok(cond: bool, msg: String) -> void:
	if not cond:
		push_error("[FAIL] " + msg)
		printerr("[FAIL] " + msg)
		paused = false
		quit(1)


func _wait_frames(n: int = 2) -> void:
	for _i in range(n):
		await process_frame


func _send_key(overlay: Node, kc: Key) -> void:
	var ev := InputEventKey.new()
	ev.keycode = kc
	ev.pressed = true
	ev.echo = false
	overlay.call("_input", ev)


func _run() -> void:
	print("=== INICIANDO SUÍTE: TELA DE DERROTA (GAME OVER UI) & CHECKPOINT ===")

	var gs := root.get_node_or_null("GameState")
	_assert_ok(gs != null, "Autoload GameState deve estar disponível")
	gs.call("reset_to_new_game")
	gs.set("in_game_minutes_per_real_second", 0.0) # Determinístico para validar horário do checkpoint

	# 1. Carrega Main.tscn e entra em ForestTrail (auto-save de checkpoint ao entrar no mapa)
	var main_sc := load("res://scenes/main/Main.tscn") as PackedScene
	_assert_ok(main_sc != null, "Main.tscn deve carregar")
	var main_inst := main_sc.instantiate()
	root.add_child(main_inst)
	current_scene = main_inst
	await _wait_frames(3)

	gs.call("set_switch", "002_Chefe_Ato1_apresentado", true)
	gs.call("set_clock_minutes", 510, false) # 08:30
	main_inst.call("load_level", "res://scenes/levels/forest_trail.tscn", "from_city")
	await _wait_frames(4)

	_assert_ok(bool(gs.call("has_checkpoint")), "Entrar em ForestTrail deve salvar checkpoint automático")
	var cp: Dictionary = gs.call("get_last_checkpoint")
	_assert_ok(str(cp.get("scene_path", "")) == "res://scenes/levels/forest_trail.tscn",
		"Checkpoint deve apontar para forest_trail.tscn (obtido %s)" % str(cp.get("scene_path", "")))
	_assert_ok((cp.get("spawn_position", Vector2.ZERO) as Vector2).distance_to(Vector2(96, 384)) < 2.0,
		"Checkpoint deve salvar a posição segura de entrada (96, 384), obtido %s" % str(cp.get("spawn_position", Vector2.ZERO)))
	_assert_ok(int(cp.get("clock_minutes", -1)) == 510, "Checkpoint deve registrar o horário 08:30 (510 min)")
	_assert_ok((cp.get("active_tasks", {}) as Dictionary).has("ato1_ovos_floresta"),
		"Checkpoint deve registrar tasks ativas")
	print("[PASS] Auto-save de checkpoint ao entrar na cena validado (cena, posição, horário e tasks).")

	# 2. Altera posição, consome estamina, avança horário e simula derrota letal
	var lvl: Node2D = main_inst.get("_current_level") as Node2D
	var player := lvl.get_node("ObstaclesYsort/PlayerHuwag") as CharacterBody2D
	player.position = Vector2(440, 320)
	gs.call("consume_stamina", 60.0)
	gs.call("set_clock_minutes", 740, false) # 12:20 (posterior ao checkpoint)
	gs.call("add_item", "gota_calmante", 2)

	var death_emissions := {"count": 0}
	player.connect("player_died", func() -> void:
		death_emissions["count"] = int(death_emissions["count"]) + 1
	)

	player.set("_hurt_timer", 0.0)
	player.call("apply_hit", 250, player.global_position + Vector2(16, 0))
	# Tenta disparar morte duplicada imediatamente (deve ser ignorada)
	player.call("trigger_death")
	await _wait_frames(3)

	_assert_ok(int(death_emissions["count"]) == 1, "Sinal player_died não deve disparar duplicado (obtido %d)" % int(death_emissions["count"]))
	_assert_ok(int(gs.get("player_hp")) == 0, "Dano letal deve zerar player_hp (obtido %d)" % int(gs.get("player_hp")))
	_assert_ok(bool(player.get("is_dead")), "PlayerHuwag deve entrar em is_dead=true")
	var fx_list: Array = player.get("_combat_fx")
	for fx in fx_list:
		_assert_ok(str((fx as Dictionary).get("text", "")).find("DERROTADO") == -1,
			"Texto flutuante antigo 'DERROTADO' no mundo deve ter sido removido")

	var overlay: CanvasLayer = main_inst.get("defeat_overlay") as CanvasLayer
	_assert_ok(overlay != null and bool(overlay.call("is_open")), "DefeatOverlay deve estar aberta após HP chegar a 0")
	_assert_ok(overlay.layer == 110, "DefeatOverlay deve estar na CanvasLayer 110 (obtido %d)" % overlay.layer)
	_assert_ok(overlay.process_mode == Node.PROCESS_MODE_ALWAYS, "DefeatOverlay precisa de PROCESS_MODE_ALWAYS")
	_assert_ok(paused == true, "Simulação do mundo deve estar pausada (get_tree().paused = true) enquanto a derrota estiver aberta")

	var btn_retry := overlay.get_node("Root/Center/Card/Margin/VBox/ButtonsBox/BtnRetryCheckpoint") as Button
	var btn_menu := overlay.get_node("Root/Center/Card/Margin/VBox/ButtonsBox/BtnMainMenu") as Button
	_assert_ok(btn_retry != null and btn_menu != null, "Os dois botões obrigatórios devem existir")
	_assert_ok(btn_retry.has_focus(), "Botão 'Reiniciar do Último Ponto' deve receber foco inicial automático")

	# Valida navegação por teclado (S / W)
	_send_key(overlay, KEY_S)
	await _wait_frames(1)
	_assert_ok(btn_menu.has_focus(), "Tecla S deve mover o foco para 'Voltar para o Menu'")
	_send_key(overlay, KEY_W)
	await _wait_frames(1)
	_assert_ok(btn_retry.has_focus(), "Tecla W deve retornar o foco para 'Reiniciar do Último Ponto'")
	print("[PASS] Exibição da DefeatOverlay (layer=110, pausa, foco e navegação W/S) validada.")

	# 3. Confirma 'Reiniciar do Último Ponto' (Enter) e valida restauração completa do checkpoint
	_send_key(overlay, KEY_ENTER)
	await _wait_frames(4)

	_assert_ok(paused == false, "Pausa deve ser limpa ao reiniciar do checkpoint")
	_assert_ok(not bool(overlay.call("is_open")), "DefeatOverlay deve fechar ao reiniciar do checkpoint")
	_assert_ok(int(gs.get("player_hp")) == int(gs.get("player_max_hp")), "HP deve restaurar 100% no checkpoint")
	_assert_ok(is_equal_approx(float(gs.get("player_stamina")), float(gs.get("player_max_stamina"))),
		"Estamina deve restaurar 100% no checkpoint")
	_assert_ok(not bool(gs.get("is_player_defeated")) and not bool(gs.get("dialogue_active")),
		"Travas de combate/diálogo devem ser limpas ao restaurar checkpoint")
	_assert_ok(int(gs.call("get_clock_minutes")) == 510, "Horário deve voltar ao snapshot salvo (510 min)")
	_assert_ok(int(gs.call("get_item_count", "gota_calmante")) == 0,
		"Inventário deve restaurar exatamente ao estado do snapshot de checkpoint")

	var restored_lvl: Node2D = main_inst.get("_current_level") as Node2D
	var restored_player := restored_lvl.get_node("ObstaclesYsort/PlayerHuwag") as CharacterBody2D
	_assert_ok(restored_player != null and not bool(restored_player.get("is_dead")),
		"Novo PlayerHuwag deve estar vivo após restaurar checkpoint")
	_assert_ok(restored_player.position.distance_to(Vector2(96, 384)) < 2.0,
		"PlayerHuwag deve retornar à posição salva do checkpoint (96, 384), obtido %s" % str(restored_player.position))
	print("[PASS] restore_last_checkpoint() restaurou cena, posição, HP/estamina, horário e flags perfeitamente!")

	# 4. Derrota novamente e escolhe 'Voltar para o Menu' -> TitleScreen.tscn
	restored_player.set("_hurt_timer", 0.0)
	restored_player.call("apply_hit", 250, restored_player.global_position + Vector2(12, 0))
	await _wait_frames(3)
	_assert_ok(paused == true and bool(overlay.call("is_open")), "Segunda derrota deve reabrir DefeatOverlay e pausar")

	_send_key(overlay, KEY_DOWN)
	await _wait_frames(1)
	_assert_ok(btn_menu.has_focus(), "Seta para baixo deve focar 'Voltar para o Menu'")
	_send_key(overlay, KEY_SPACE)
	await _wait_frames(5)

	_assert_ok(paused == false, "Pausa deve ser limpa ao voltar para o Menu Principal")
	_assert_ok(not bool(gs.get("is_player_defeated")) and not bool(gs.get("dialogue_active")),
		"Estados transitórios devem estar limpos no Menu Principal")
	_assert_ok(current_scene != null and current_scene.scene_file_path.ends_with("TitleScreen.tscn"),
		"Deve transicionar para TitleScreen.tscn (obtido %s)" % (current_scene.scene_file_path if current_scene else "null"))
	print("[PASS] Retorno limpo ao Menu Principal (TitleScreen.tscn) validado!")

	print("\n==================================================================")
	print("=== TELA DE DERROTA & CHECKPOINT VALIDADOS 100% COM SUCESSO! ===")
	print("==================================================================")
	quit(0)
