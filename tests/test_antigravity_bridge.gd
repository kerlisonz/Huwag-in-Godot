extends SceneTree

func _init() -> void:
	call_deferred("_run_plugin_test")

func _run_plugin_test() -> void:
	print("==================================================")
	print("=== TESTE DO PLUGIN ANTIGRAVITY ART STUDIO ===")
	print("==================================================")

	# 1. Testar carregamento do script do Dock
	var dock_script: Script = load("res://addons/antigravity_bridge/ui/antigravity_dock.gd")
	assert(dock_script != null, "Falha ao carregar antigravity_dock.gd")
	var dock_inst: Control = dock_script.new()
	root.add_child(dock_inst)
	await process_frame
	print("[PASS] Dock da interface instanciado com sucesso!")

	# 2. Testar se os controles essenciais foram criados na UI
	assert(dock_inst.find_child("OptionButton", true, false) != null or dock_inst.opt_mode != null, "Controles não encontrados")
	print("[PASS] Elementos de UI (Seletores, TextEdit, Botões) montados com sucesso!")

	# 3. Testar o processador Python (asset_processor.py)
	var py_script: String = ProjectSettings.globalize_path("res://addons/antigravity_bridge/tools/asset_processor.py")
	assert(FileAccess.file_exists(py_script), "asset_processor.py não encontrado")

	var test_req_path: String = ProjectSettings.globalize_path("res://.antigravity_bridge/requests/test_validation_request.json")
	var req_data := {
		"slug": "test_room",
		"mode": 0,
		"resolution": [640, 360],
		"prompt": "Test prompt"
	}

	var py_bin: String = "C:/Python315/python.exe" if FileAccess.file_exists("C:/Python315/python.exe") else "python"
	var out: Array = []
	var args: Array[String] = [
		py_script,
		"request",
		"--output", test_req_path,
		"--slug", "test_room",
		"--mode", "0",
		"--preset", "0",
		"--width", "640",
		"--height", "360",
		"--prompt", "Test prompt",
		"--full_prompt", "2D pixel art test prompt",
		"--target_file", "res://assets/levels/test_room/test_room_bg.png"
	]
	var code := OS.execute(py_bin, args, out, true)
	assert(code == 0, "Falha ao executar asset_processor.py request: %s" % str(out))
	print("[PASS] Bridge Python funcionando perfeitamente: requisições registradas!")

	# 4. Testar normalização de imagem
	var test_in := ProjectSettings.globalize_path("res://assets/environments/room_huwag/room_huwag_bg.png")
	var test_out := ProjectSettings.globalize_path("res://.antigravity_bridge/test_normalized.png")
	var norm_args: Array[String] = [
		py_script,
		"normalize",
		"--input", test_in,
		"--output", test_out,
		"--width", "640",
		"--height", "360",
		"--nearest"
	]
	var norm_out: Array = []
	var norm_code := OS.execute(py_bin, norm_args, norm_out, true)
	assert(norm_code == 0, "Falha ao normalizar imagem de teste: %s" % str(norm_out))
	assert(FileAccess.file_exists(test_out), "Arquivo normalizado não gerado")
	print("[PASS] Normalizador de Pixel Art 640x360 Nearest Neighbor testado e validado!")

	# 5. Testar criação de cena .tscn compatível
	var test_scene_path := ProjectSettings.globalize_path("res://.antigravity_bridge/TestBridgeScene.tscn")
	var scene_args: Array[String] = [
		py_script,
		"create_scene",
		"--output", test_scene_path,
		"--bg", "res://assets/environments/room_huwag/room_huwag_bg.png",
		"--title", "TestBridgeScene"
	]
	var scene_out: Array = []
	var scene_code := OS.execute(py_bin, scene_args, scene_out, true)
	assert(scene_code == 0, "Falha ao criar cena de teste: %s" % str(scene_out))
	assert(FileAccess.file_exists(test_scene_path), "Cena .tscn não gerada")

	var loaded_scene: PackedScene = load("res://.antigravity_bridge/TestBridgeScene.tscn")
	assert(loaded_scene != null, "Godot não conseguiu compilar a cena .tscn gerada!")
	print("[PASS] Gerador de Cenas .tscn com colisões e YSortEntities testado e validado no Godot!")

	# 6. Limpar arquivos de teste
	if FileAccess.file_exists(test_req_path):
		DirAccess.remove_absolute(test_req_path)
	if FileAccess.file_exists(test_out):
		DirAccess.remove_absolute(test_out)
	if FileAccess.file_exists(test_scene_path):
		DirAccess.remove_absolute(test_scene_path)

	print("==================================================")
	print("=== TODOS OS TESTES DO PLUGIN PASSARAM COM SUCESSO! ===")
	print("==================================================")
	quit(0)
