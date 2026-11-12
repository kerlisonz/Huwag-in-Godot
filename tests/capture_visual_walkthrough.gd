extends SceneTree

func _init() -> void:
	call_deferred("_run_walkthrough")

func _run_walkthrough() -> void:
	# Autoload GameState
	if not root.has_node("GameState"):
		var gs_class = load("res://scripts/autoload/game_state.gd")
		var gs_inst = gs_class.new()
		gs_inst.name = "GameState"
		root.add_child(gs_inst)

	# 1. Carrega Main.tscn (Quarto de Huwag com HUD e Diálogo inicial)
	var main_scene: PackedScene = load("res://scenes/main/Main.tscn")
	var main_node = main_scene.instantiate()
	root.add_child(main_node)

	for i in range(25):
		await process_frame

	var vp := root.get_viewport()
	var img_room := vp.get_texture().get_image()
	if img_room:
		img_room.save_png("res://docs/screenshots/quarto_huwag_1080p.png")
		print("[OK] Captura 1 salva: res://docs/screenshots/quarto_huwag_1080p.png (tamanho: %s)" % img_room.get_size())

	# 2. Muda para a Rua de Agdangan (StreetPreview)
	main_node.call("load_level", "res://scenes/levels/StreetPreview.tscn", "from_room")
	for i in range(25):
		await process_frame
	var img_street := vp.get_texture().get_image()
	if img_street:
		img_street.save_png("res://docs/screenshots/rua_agdangan_1080p.png")
		print("[OK] Captura 2 salva: res://docs/screenshots/rua_agdangan_1080p.png (tamanho: %s)" % img_street.get_size())

	# 3. Muda para a Trilha da Floresta (forest_trail.tscn)
	main_node.call("load_level", "res://scenes/levels/forest_trail.tscn", "from_city")
	for i in range(25):
		await process_frame
	var img_trail := vp.get_texture().get_image()
	if img_trail:
		img_trail.save_png("res://docs/screenshots/trilha_floresta_1080p.png")
		print("[OK] Captura 3 salva: res://docs/screenshots/trilha_floresta_1080p.png (tamanho: %s)" % img_trail.get_size())

	# 4. Muda para a Clareira da Lagoa com Huwag na margem interagindo com a Guardiã
	main_node.call("load_level", "res://scenes/levels/forest_clearing.tscn", "from_trail")
	for i in range(15):
		await process_frame

	var cl_player = root.find_child("PlayerHuwag", true, false)
	if cl_player:
		cl_player.position = Vector2(435, 235)
		cl_player.facing_dir = Vector2.RIGHT

	for i in range(25):
		await process_frame

	var img_clearing := vp.get_texture().get_image()
	if img_clearing:
		img_clearing.save_png("res://docs/screenshots/clareira_boss_agua_1080p.png")
		print("[OK] Captura 4 salva: res://docs/screenshots/clareira_boss_agua_1080p.png (tamanho: %s)" % img_clearing.get_size())

	quit(0)
