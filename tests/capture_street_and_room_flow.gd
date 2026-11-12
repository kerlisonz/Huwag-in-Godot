extends SceneTree

func _init() -> void:
	call_deferred("_run_captures")

func _run_captures() -> void:
	print("--- Iniciando captura visual do fluxo Quarto <-> Rua ---")
	if not root.has_node("GameState"):
		var gs_class = load("res://scripts/autoload/game_state.gd")
		var gs_inst = gs_class.new()
		gs_inst.name = "GameState"
		root.add_child(gs_inst)

	# 1. Carrega Main.tscn
	var main_scene: PackedScene = load("res://scenes/main/Main.tscn")
	var main_node = main_scene.instantiate()
	root.add_child(main_node)

	for i in range(30):
		await process_frame

	var vp := root.get_viewport()
	var dbox = main_node.get_node_or_null("CanvasLayer/DialogueBox")
	if dbox:
		dbox.close_dialogue()
	for i in range(15):
		await process_frame

	var room = main_node.get_node_or_null("LevelContainer/RoomHuwag")
	var p_room = room.get_node_or_null("YSortEntities/Player") if room else null

	# 1. Huwag dentro do quarto, perto da porta
	if p_room:
		p_room.position = Vector2(536, 225)
		p_room.facing_dir = Vector2.RIGHT
		p_room._update_interaction_offset()
	for i in range(25):
		await process_frame

	var img1 := vp.get_texture().get_image()
	if img1:
		img1.save_png("res://docs/screenshots/shot1_quarto_porta.png")
		print("[OK] Salvo shot1_quarto_porta.png")

	# 2. Huwag saindo pela porta e aparecendo na rua diante de sua casa
	main_node.load_level("res://scenes/levels/StreetPreview.tscn", "from_room")
	for i in range(35):
		await process_frame

	var street = main_node.get_node_or_null("LevelContainer/StreetPreview")
	var p_street = street.get_node_or_null("YSortEntities/Player") if street else null
	if p_street:
		p_street.facing_dir = Vector2.DOWN
		p_street._update_interaction_offset()
	for i in range(25):
		await process_frame

	var img2 := vp.get_texture().get_image()
	if img2:
		img2.save_png("res://docs/screenshots/shot2_rua_saida_casa.png")
		print("[OK] Salvo shot2_rua_saida_casa.png")

	# 3. Huwag diante da Sari-Sari Store
	if p_street:
		p_street.position = Vector2(750, 410)
		p_street.facing_dir = Vector2.UP
		p_street._update_interaction_offset()
	for i in range(25):
		await process_frame

	var img3 := vp.get_texture().get_image()
	if img3:
		img3.save_png("res://docs/screenshots/shot3_rua_dia_sari_sari.png")
		print("[OK] Salvo shot3_rua_dia_sari_sari.png")

	# 4. Huwag diante do Caminhão de Bombeiros no Quartel BFP
	if p_street:
		p_street.position = Vector2(1110, 395)
		p_street.facing_dir = Vector2.UP
		p_street._update_interaction_offset()
	for i in range(25):
		await process_frame

	var img4 := vp.get_texture().get_image()
	if img4:
		img4.save_png("res://docs/screenshots/shot4_rua_dia_quartel_bfp.png")
		print("[OK] Salvo shot4_rua_dia_quartel_bfp.png")

	# 5. Huwag diante do Triciclo e Karinderya
	if p_street:
		p_street.position = Vector2(1330, 455)
		p_street.facing_dir = Vector2.UP
		p_street._update_interaction_offset()
	for i in range(25):
		await process_frame

	var img5 := vp.get_texture().get_image()
	if img5:
		img5.save_png("res://docs/screenshots/shot5_rua_dia_triciclo_karinderya.png")
		print("[OK] Salvo shot5_rua_dia_triciclo_karinderya.png")

	# 6. Versão Noturna da Rua de Agdangan
	var gs = root.get_node("GameState")
	gs.is_afternoon = true
	gs.set_switch("005_Chefe_liberou_cidade", true)
	if street:
		street._apply_visual_atmosphere()
	if p_street:
		p_street.position = Vector2(1080, 430)
		p_street.facing_dir = Vector2.RIGHT
		p_street._update_interaction_offset()
	for i in range(30):
		await process_frame

	var img6 := vp.get_texture().get_image()
	if img6:
		img6.save_png("res://docs/screenshots/shot6_rua_noite_agdangan.png")
		print("[OK] Salvo shot6_rua_noite_agdangan.png")

	print("--- Todas as 6 capturas concluídas com sucesso! ---")
	quit(0)
