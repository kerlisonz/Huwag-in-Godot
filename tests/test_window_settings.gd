extends SceneTree

var passed: int = 0
var failed: int = 0

func _init() -> void:
	print("==================================================")
	print("=== INICIANDO TESTES: CONFIGURAÇÕES DE JANELA ===")
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
	# 1. Validação de ProjectSettings para janela adaptável com 3 botões padrão (minimizar, maximizar, fechar)
	var mode = ProjectSettings.get_setting("display/window/size/mode")
	assert_true(mode == 0, "Modo de exibição inicial é WINDOWED (0) com bordas e barra de título")

	var resizable = ProjectSettings.get_setting("display/window/size/resizable")
	assert_true(resizable == true, "Janela está configurada como RESIZABLE (permite redimensionar e maximizar)")

	var borderless = ProjectSettings.get_setting("display/window/size/borderless")
	assert_true(borderless == false, "Janela possui moldura do SO com os 3 botões (minimizar, maximizar, fechar)")

	var init_pos = ProjectSettings.get_setting("display/window/size/initial_position_type")
	assert_true(init_pos == 2, "Janela inicia centralizada na tela principal (initial_position_type = 2)")

	var w_override = ProjectSettings.get_setting("display/window/size/window_width_override")
	var h_override = ProjectSettings.get_setting("display/window/size/window_height_override")
	print("Tamanho inicial de janela override: %dx%d" % [w_override, h_override])
	assert_true(w_override == 1280 and h_override == 720, "Tamanho de janela inicial é 1280x720 (escala limpa 2x de 640x360)")

	var stretch_mode = ProjectSettings.get_setting("display/window/stretch/mode")
	var stretch_aspect = ProjectSettings.get_setting("display/window/stretch/aspect")
	assert_true(stretch_mode == "canvas_items", "Stretch mode é canvas_items para escala adaptável")
	assert_true(stretch_aspect == "keep", "Stretch aspect é keep para preservar proporção 16:9 sem distorção")

	# 2. Testar API do GameState (toggle_fullscreen / set_fullscreen)
	var gs = root.get_node_or_null("GameState")
	if gs:
		assert_true(gs.has_method("toggle_fullscreen"), "GameState possui método toggle_fullscreen")
		assert_true(gs.has_method("set_fullscreen"), "GameState possui método set_fullscreen")
		assert_true(gs.has_method("is_fullscreen"), "GameState possui método is_fullscreen")

	# 3. Testar TitleScreen OptionsModal ChkFullscreen
	var title_scene = load("res://scenes/menu/TitleScreen.tscn")
	assert_true(title_scene != null, "TitleScreen.tscn carregada com sucesso")
	var title = title_scene.instantiate()
	root.add_child(title)
	await process_frame

	var chk_fs: CheckBox = title.get_node_or_null("OptionsModal/Card/Margin/VBox/ChkFullscreen")
	assert_true(chk_fs != null, "Opção ChkFullscreen presente no modal de configurações")

	title.queue_free()
	await process_frame

	print("==================================================")
	print("=== RESULTADO: %d PASSOU, %d FALHOU ===" % [passed, failed])
	print("==================================================")
	quit(0 if failed == 0 else 1)

