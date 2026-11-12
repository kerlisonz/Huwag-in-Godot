extends SceneTree

func _init() -> void:
	call_deferred("_run_test")

func _run_test() -> void:
	print("==================================================")
	print("=== TESTE DO NOVO FLUXO: QUARTO <-> RUA AGDANGAN ===")
	print("==================================================")

	# 1. Carrega GameState
	if not root.has_node("GameState"):
		var gs_class = load("res://scripts/autoload/game_state.gd")
		var gs_inst = gs_class.new()
		gs_inst.name = "GameState"
		root.add_child(gs_inst)

	# 2. Carrega Main.tscn
	var main_scene: PackedScene = load("res://scenes/main/Main.tscn")
	assert(main_scene != null, "Falha ao carregar Main.tscn")
	var main_node = main_scene.instantiate()
	root.add_child(main_node)

	for i in range(20):
		await process_frame

	var dbox = main_node.get_node_or_null("CanvasLayer/DialogueBox")
	if dbox:
		dbox.close_dialogue()
	await process_frame

	# 3. Verifica início no quarto de Huwag
	var room = main_node.get_node_or_null("LevelContainer/RoomHuwag")
	assert(room != null, "Quarto de Huwag deve ser a cena inicial!")
	var player = room.get_node_or_null("YSortEntities/Player")
	assert(player != null, "Player deve estar presente no quarto!")
	print("[PASS] Início no quarto confirmado em: %s" % player.position)

	# 4. Huwag caminha até a porta de saída do quarto
	print("Huwag caminhando até a porta de saída do quarto...")
	player.position = Vector2(538, 225)
	player.facing_dir = Vector2.RIGHT
	player._update_interaction_offset()
	for f in range(5):
		await physics_frame

	var door_inter: Interactable = player.get_best_interactable()
	assert(door_inter != null and door_inter.name == "Porta_Saida", "Porta de saída do quarto deve ser detectada!")
	print("[PASS] Interação de saída detectada: %s | %s" % [door_inter.title, door_inter.verb])

	# 5. Transição do quarto para a Rua de Agdangan
	print("Saindo pela porta para a Rua de Agdangan...")
	main_node.load_level("res://scenes/levels/StreetPreview.tscn", "from_room")
	for i in range(25):
		await process_frame

	var street = main_node.get_node_or_null("LevelContainer/StreetPreview")
	assert(street != null, "Rua de Agdangan (StreetPreview) deve estar carregada!")
	var street_player = street.get_node_or_null("YSortEntities/Player")
	assert(street_player != null, "Player deve estar presente na rua!")

	# Verifica se Huwag apareceu diante da sua casa
	print("[PASS] Huwag apareceu na rua em frente à sua casa: %s (esperado x=569, y=395)" % street_player.position)
	assert(abs(street_player.position.x - 569.0) < 2.0 and abs(street_player.position.y - 395.0) < 2.0, "Spawn diante da casa incorreto!")

	# 6. Testa colisão da fachada da Casa de Huwag (não deve atravessar parede ao norte)
	print("Testando colisão da parede norte da Casa de Huwag...")
	for i in range(30):
		street_player.move_and_collide(Vector2(0, -5))
		await process_frame
	print("Posição de Huwag bloqueada contra a fachada: %s" % street_player.position)
	assert(street_player.position.y >= 370.0, "Fachada da casa deve bloquear travessia indevida!")
	print("[PASS] Colisão da fachada da casa barrou Huwag em y=%f" % street_player.position.y)

	# 7. Huwag interage com a porta da sua casa para retornar
	street_player.position = Vector2(569, 390)
	street_player.facing_dir = Vector2.UP
	street_player._update_interaction_offset()
	for f in range(5):
		await physics_frame

	var house_inter: Interactable = street_player.get_best_interactable()
	assert(house_inter != null and house_inter.name == "Casa_Huwag", "Porta da casa de Huwag deve ser detectada na rua!")
	print("[PASS] Interação da porta da casa na rua detectada: %s | %s" % [house_inter.title, house_inter.verb])

	# 8. Retorno para o quarto
	print("Retornando para o quarto pela porta...")
	main_node.load_level("res://scenes/levels/RoomHuwag.tscn", "from_street")
	for i in range(25):
		await process_frame

	var room_return = main_node.get_node_or_null("LevelContainer/RoomHuwag")
	assert(room_return != null, "Quarto deve ser recarregado no retorno!")
	var player_return = room_return.get_node_or_null("YSortEntities/Player")
	assert(player_return != null, "Player presente no quarto!")
	print("[PASS] Posição de retorno ao interior próxima à saída: %s (esperado x=540, y=220)" % player_return.position)
	assert(abs(player_return.position.x - 540.0) < 2.0 and abs(player_return.position.y - 220.0) < 2.0, "Posição de retorno incorreta!")

	# 9. Retorna à rua para testar as novas interações dos elementos reais da cena
	main_node.load_level("res://scenes/levels/StreetPreview.tscn", "from_room")
	for i in range(25):
		await process_frame
	var street2 = main_node.get_node_or_null("LevelContainer/StreetPreview")
	var p2 = street2.get_node_or_null("YSortEntities/Player")

	# Teste Interação 1: Sari-Sari Store
	p2.position = Vector2(750, 410)
	p2.facing_dir = Vector2.UP
	p2._update_interaction_offset()
	for f in range(5): await physics_frame
	var inter_sari = p2.get_best_interactable()
	assert(inter_sari != null and inter_sari.name == "Sari_Sari", "Sari-Sari Store deve ser detectada!")
	print("[PASS] Interação detectada: %s" % inter_sari.title)

	# Teste Interação 2: Quartel BFP (Caminhão de Bombeiros)
	p2.position = Vector2(1110, 395)
	p2.facing_dir = Vector2.UP
	p2._update_interaction_offset()
	for f in range(5): await physics_frame
	var inter_truck = p2.get_best_interactable()
	assert(inter_truck != null and inter_truck.name == "Caminhao_Bombeiros", "Caminhão de Bombeiros deve ser detectado!")
	print("[PASS] Interação detectada: %s" % inter_truck.title)

	# Teste Interação 3: Triciclo
	p2.position = Vector2(1330, 455)
	p2.facing_dir = Vector2.UP
	p2._update_interaction_offset()
	for f in range(5): await physics_frame
	var inter_tri = p2.get_best_interactable()
	assert(inter_tri != null and inter_tri.name == "Karinderya_Triciclo", "Triciclo deve ser detectado!")
	print("[PASS] Interação detectada: %s" % inter_tri.title)

	# Teste Interação 4: Igreja de Agdangan
	p2.position = Vector2(1810, 230)
	p2.facing_dir = Vector2.UP
	p2._update_interaction_offset()
	for f in range(5): await physics_frame
	var inter_church = p2.get_best_interactable()
	assert(inter_church != null and inter_church.name == "Igreja_Agdangan", "Igreja de Agdangan deve ser detectada!")
	print("[PASS] Interação detectada: %s" % inter_church.title)

	# Teste Interação 5: Cais da Praia a Oeste
	p2.position = Vector2(160, 455)
	p2.facing_dir = Vector2.UP
	p2._update_interaction_offset()
	for f in range(5): await physics_frame
	var inter_cais = p2.get_best_interactable()
	assert(inter_cais != null and inter_cais.name == "Cais_Praia", "Píer da Praia deve ser detectado!")
	print("[PASS] Interação detectada: %s" % inter_cais.title)

	print("\n==================================================")
	print("=== TODOS OS 9 TESTES DE FLUXO E INTERAÇÕES PASSARAM! ===")
	print("==================================================")
	quit(0)
