extends SceneTree

func _init() -> void:
	call_deferred("_run_suite")

func _run_suite() -> void:
	print("==================================================")
	print("=== TESTE COMPLETO: QUARTO, UI E ACESSO AO BOSS ===")
	print("==================================================")

	# Autoload GameState
	if not root.has_node("GameState"):
		var gs_class = load("res://scripts/autoload/game_state.gd")
		var gs_inst = gs_class.new()
		gs_inst.name = "GameState"
		root.add_child(gs_inst)

	# ----------------------------------------------------
	# PARTE 1: TESTE DO QUARTO DE HUWAG (RoomHuwag)
	# ----------------------------------------------------
	print("\n--- PARTE 1: Verificação de RoomHuwag ---")
	var room_scene: PackedScene = load("res://scenes/levels/RoomHuwag.tscn")
	assert(room_scene != null, "Falha ao carregar RoomHuwag.tscn")
	var room: Node2D = room_scene.instantiate()
	root.add_child(room)
	await process_frame

	var player = room.get_node_or_null("YSortEntities/Player")
	assert(player != null, "Player não encontrado no quarto!")
	print("[PASS] Quarto instanciado. Posição inicial: %s" % player.position)

	# Testa colisão da cama
	player.position = Vector2(110, 270)
	for i in range(20):
		player.move_and_collide(Vector2(0, -10))
		await process_frame
	assert(player.position.y >= 244.0, "Cama deve barrar entrada por baixo!")
	print("[PASS] Colisão da cama de bambu validada com sucesso em y=%f" % player.position.y)

	# Testa barreira leste
	player.position = Vector2(530, 290)
	for i in range(20):
		player.move_and_collide(Vector2(10, 0))
		await process_frame
	assert(player.position.x <= 548.0, "Parede leste deve barrar saída para o vácuo!")
	print("[PASS] Barreira da parede leste validada em x=%f" % player.position.x)

	room.queue_free()
	await process_frame

	# ----------------------------------------------------
	# PARTE 2: TESTE DE ACESSO E INTERAÇÃO COM A GUARDIÃ DA LAGOA
	# ----------------------------------------------------
	print("\n--- PARTE 2: Acesso e Interação com a Guardiã na Clareira ---")
	var clearing_scene: PackedScene = load("res://scenes/levels/forest_clearing.tscn")
	assert(clearing_scene != null, "Falha ao carregar forest_clearing.tscn")
	var clearing: Node2D = clearing_scene.instantiate()
	root.add_child(clearing)
	await process_frame

	var cl_player = clearing.get_node_or_null("ObstaclesYsort/PlayerHuwag")
	assert(cl_player != null, "PlayerHuwag presente na clareira!")
	var boss = clearing.get_node_or_null("ObstaclesYsort/AquaticCreature")
	assert(boss != null, "Guardiã aquática presente na clareira!")
	var nest = clearing.get_node_or_null("ObstaclesYsort/EggNest")
	assert(nest != null, "Ninho com ovos azuis presente!")

	# Huwag caminha em direção à margem oeste da lagoa
	print("Huwag caminhando em direção à margem da lagoa...")
	cl_player.position = Vector2(350, 235)
	cl_player.facing_dir = Vector2.RIGHT

	for i in range(30):
		cl_player.move_and_collide(Vector2(4, 0))
		await process_frame

	print("Posição de Huwag na margem: %s" % cl_player.position)
	assert(cl_player.position.x >= 420.0, "Huwag deve conseguir caminhar até a margem d'água!")

	# Verifica se a interação com a Guardiã foi detectada
	var best_inter: Interactable = cl_player.get_best_interactable()
	assert(best_inter != null, "Huwag deve detectar um objeto interativo na margem da lagoa!")
	print("[PASS] Interagível detectado: '%s' | Prompt: '%s'" % [best_inter.title, best_inter.get_prompt_text()])
	assert(best_inter.title == "Guardiã da Lagoa", "O interagível deve ser a Guardiã da Lagoa!")

	# Testa acionamento do diálogo
	var dialogue_tracker := {"triggered": false}
	clearing.request_dialogue.connect(func(pages, _cb):
		print("[PASS] Diálogo narrativo disparado com sucesso! Páginas: %d" % pages.size())
		dialogue_tracker["triggered"] = true
	)
	best_inter.trigger_interaction()
	assert(dialogue_tracker["triggered"], "Interação com a Guardiã deve disparar o diálogo!")

	# Huwag caminha ao redor da lagoa até o ninho na margem leste
	print("\nHuwag contornando a lagoa em direção ao ninho de ovos azuis...")
	cl_player.position = Vector2(600, 240)
	cl_player.facing_dir = Vector2.RIGHT
	for i in range(5):
		await process_frame

	var nest_inter: Interactable = cl_player.get_best_interactable()
	assert(nest_inter != null, "Huwag deve detectar o ninho de ovos na margem leste!")
	print("[PASS] Interagível detectado: '%s' | Prompt: '%s'" % [nest_inter.title, nest_inter.get_prompt_text()])
	assert(nest_inter.title == "Ninho com Ovos Azuis", "O interagível deve ser o Ninho com Ovos Azuis!")

	# Testa bloqueio de água profunda (não deve entrar no centro da lagoa)
	cl_player.position = Vector2(495, 310)
	for i in range(30):
		cl_player.move_and_collide(Vector2(0, -5))
		await process_frame
	print("Posição de Huwag barrada na água profunda: %s" % cl_player.position)
	assert(cl_player.position.y >= 275.0, "Água profunda deve bloquear a travessia direta!")
	print("[PASS] Barreira de água profunda impediu afogamento/travessia indevida!")

	clearing.queue_free()
	await process_frame

	print("\n==================================================")
	print("=== TODOS OS TESTES PASSARAM COM 100% DE SUCESSO! ===")
	print("==================================================")
	quit(0)
