extends SceneTree

func _init() -> void:
	call_deferred("_run_captures")

func _run_captures() -> void:
	print("--- Iniciando captura de estados do quarto de Huwag ---")
	if not root.has_node("GameState"):
		var gs_class = load("res://scripts/autoload/game_state.gd")
		var gs_inst = gs_class.new()
		gs_inst.name = "GameState"
		root.add_child(gs_inst)

	# 1. Carrega Main.tscn
	var main_scene: PackedScene = load("res://scenes/main/Main.tscn")
	var main_node = main_scene.instantiate()
	root.add_child(main_node)

	for i in range(35):
		await process_frame

	var vp := root.get_viewport()
	var dbox = main_node.get_node_or_null("CanvasLayer/DialogueBox")
	var room = main_node.get_node_or_null("LevelContainer/RoomHuwag")
	var player = room.get_node_or_null("YSortEntities/Player") if room else null

	# Captura 1: Monólogo inicial
	var img1 := vp.get_texture().get_image()
	if img1:
		img1.save_png("res://docs/screenshots/room_state1_monologue.png")
		print("[OK] Captura 1: room_state1_monologue.png")

	# Fecha o diálogo para ver o quarto limpo
	if dbox:
		dbox.close_dialogue()
	for i in range(20):
		await process_frame

	# Captura 2: Quarto limpo (sem diálogo)
	var img2 := vp.get_texture().get_image()
	if img2:
		img2.save_png("res://docs/screenshots/room_state2_exploration.png")
		print("[OK] Captura 2: room_state2_exploration.png")

	# Huwag caminha até a cama (para testar Y-sorting e proximidade)
	if player:
		player.position = Vector2(236, 215)
		player.facing_dir = Vector2.LEFT
		player._update_interaction_offset()
	for i in range(20):
		await process_frame

	# Captura 3: Huwag na cama (sem diálogo)
	var img3 := vp.get_texture().get_image()
	if img3:
		img3.save_png("res://docs/screenshots/room_state3_near_bed.png")
		print("[OK] Captura 3: room_state3_near_bed.png")

	# Huwag interage com o Cabideiro/Armário de Uniformes (abre menu de escolhas)
	if room:
		room._on_interactable_triggered("Armario_Uniforme")
	for i in range(25):
		await process_frame

	# Captura 4: Menu de escolhas no quarto
	var img4 := vp.get_texture().get_image()
	if img4:
		img4.save_png("res://docs/screenshots/room_state4_choices.png")
		print("[OK] Captura 4: room_state4_choices.png")

	# Interage com a Janela do Quarto com Retrato
	if room:
		room._on_interactable_triggered("Janela_Norte")
	for i in range(25):
		await process_frame

	# Captura 5: Diálogo com retrato
	var img5 := vp.get_texture().get_image()
	if img5:
		img5.save_png("res://docs/screenshots/room_state5_portrait.png")
		print("[OK] Captura 5: room_state5_portrait.png")

	print("--- Todas as capturas concluídas com sucesso! ---")
	quit(0)
