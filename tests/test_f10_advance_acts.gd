extends SceneTree

var passed: int = 0
var failed: int = 0

func _init() -> void:
	print("==================================================")
	print("=== INICIANDO TESTES: F10 AVANÇAR ENTRE ATOS ===")
	print("==================================================")
	call_deferred("_run_tests")

func assert_true(cond: bool, label: String) -> void:
	if cond:
		passed += 1
		print("[PASS] %s" % label)
	else:
		failed += 1
		push_error("FAIL: %s" % label)
		print("[FAIL] %s" % label)

func _run_tests() -> void:
	var gs = root.get_node_or_null("GameState")
	assert_true(gs != null, "Autoload GameState presente")
	if not gs:
		quit(1)
		return

	# Garante que inicia no Ato 1
	gs.reset_to_new_game()
	assert_true(int(gs.get_var("Ato", 1)) == 1, "Início verificado no Ato 1")

	# 1. Teste da API advance_act(): Ato 1 -> Ato 2
	var next_act = gs.advance_act()
	assert_true(next_act == 2 and int(gs.get_var("Ato", 1)) == 2, "Avançou para o Ato 2 com sucesso")
	assert_true(gs.get_switch("006_Dormir_avancou_para_Ato2") == true, "Switch do Ato 2 ativado")

	# 2. Teste da API advance_act(): Ato 2 -> Ato 3
	next_act = gs.advance_act()
	assert_true(next_act == 3 and int(gs.get_var("Ato", 1)) == 3, "Avançou para o Ato 3 com sucesso")
	assert_true(gs.get_switch("022_Ato3_iniciado") == true, "Switch do Ato 3 ativado")
	assert_true(gs.is_unfiltered_act3() == true, "Percepção crua e sem filtro ativada no Ato 3")

	# 3. Teste da API advance_act(): Ciclo Ato 3 -> Ato 1
	next_act = gs.advance_act()
	assert_true(next_act == 1 and int(gs.get_var("Ato", 1)) == 1, "Ciclo retornou ao Ato 1 com sucesso")
	assert_true(gs.get_switch("006_Dormir_avancou_para_Ato2") == false, "Switches de transição resetados para novo ciclo")

	# 4. Teste de Simulação de Tecla F10 na cena principal (Main.tscn)
	var main_scene: PackedScene = load("res://scenes/main/Main.tscn")
	assert_true(main_scene != null, "Cena Main.tscn carregada com sucesso")
	var main = main_scene.instantiate()
	root.add_child(main)
	await process_frame

	var act_label: Label = main.get_node_or_null("CanvasLayer/HudTopRight/Margin/HBox/ActPlaceLabel")
	assert_true(act_label != null, "Label de Ato/Local presente no HUD")
	assert_true(act_label.text.begins_with("Ato I"), "HUD inicia exibindo Ato I")

	# Simula evento de tecla F10 pressionada
	var f10_event := InputEventKey.new()
	f10_event.keycode = KEY_F10
	f10_event.pressed = true
	main._unhandled_input(f10_event)
	await process_frame

	assert_true(int(gs.get_var("Ato", 1)) == 2, "Tecla F10 avançou o jogo para o Ato 2")
	assert_true(act_label.text.begins_with("Ato II"), "HUD atualizado para exibir Ato II")

	# Simula F10 novamente -> Avança para Ato 3
	main._unhandled_input(f10_event)
	await process_frame

	assert_true(int(gs.get_var("Ato", 1)) == 3, "Segunda pressão de F10 avançou o jogo para o Ato 3")
	assert_true(act_label.text.begins_with("Ato III"), "HUD atualizado para exibir Ato III")

	main.queue_free()
	await process_frame

	print("==================================================")
	print("=== RESULTADO: %d PASSOU, %d FALHOU ===" % [passed, failed])
	print("==================================================")
	quit(0 if failed == 0 else 1)

