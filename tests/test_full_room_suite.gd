extends SceneTree

func _init() -> void:
	call_deferred("_run_full_suite")

func _run_full_suite() -> void:
	print("==================================================")
	print("=== INICIANDO SUÍTE COMPLETA DE TESTES DO QUARTO ===")
	print("==================================================")

	if not root.has_node("GameState"):
		var gs_class = load("res://scripts/autoload/game_state.gd")
		var gs_inst = gs_class.new()
		gs_inst.name = "GameState"
		root.add_child(gs_inst)

	var room_scene: PackedScene = load("res://scenes/levels/RoomHuwag.tscn")
	assert(room_scene != null, "Falha ao carregar RoomHuwag.tscn")

	var room: Node2D = room_scene.instantiate()
	root.add_child(room)
	await process_frame

	var player: CharacterBody2D = room.get_node_or_null("YSortEntities/Player")
	assert(player != null, "Player não encontrado em RoomHuwag!")
	print("[PASS] RoomHuwag instanciado. Posição inicial: %s" % player.position)

	# ----------------------------------------------------
	# TESTE 1: Bloqueio da Parede Oeste (antigo bug das imagens 1 e 2)
	# ----------------------------------------------------
	print("\n--- TESTE 1: Bloqueio da Parede Oeste (não deve sair do quarto) ---")
	player.position = Vector2(250, 280)
	for i in range(40):
		player.move_and_collide(Vector2(-10, 0))
		await process_frame

	print("Posição após tentar atravessar parede oeste: %s" % player.position)
	assert(player.position.x >= 105.0, "ERRO: Player atravessou a parede oeste para o vazio! x=%f" % player.position.x)
	print("[PASS] Parede oeste barrou o jogador com segurança em x=%f (mínimo seguro >= 105)" % player.position.x)

	# ----------------------------------------------------
	# TESTE 2: Bloqueio da Cama de Bambu (antigo bug da imagem 3)
	# ----------------------------------------------------
	print("\n--- TESTE 2: Bloqueio da Cama de Bambu (x=100..228, y=156..248) ---")
	player.position = Vector2(110, 270)
	for i in range(40):
		player.move_and_collide(Vector2(0, -10))
		await process_frame

	print("Posição após tentar entrar na cama por baixo: %s" % player.position)
	assert(player.position.y >= 244.0, "ERRO: Player entrou na cama por baixo! y=%f" % player.position.y)
	print("[PASS] Cama de bambu barrou o jogador com sucesso em y=%f (mínimo seguro >= 244)" % player.position.y)

	player.position = Vector2(260, 200)
	for i in range(40):
		player.move_and_collide(Vector2(-10, 0))
		await process_frame

	print("Posição após tentar entrar na cama pela direita: %s" % player.position)
	assert(player.position.x >= 234.0, "ERRO: Player atravessou a cama pela lateral! x=%f" % player.position.x)
	print("[PASS] Lateral da cama barrou o jogador com sucesso em x=%f (mínimo seguro >= 234)" % player.position.x)

	# ----------------------------------------------------
	# TESTE 3: Área da Mesa de Refeição LIVRE (colisão de móvel removida a pedido)
	# ----------------------------------------------------
	print("\n--- TESTE 3: Área da Mesa de Refeição livre de colisão de móvel ---")
	player.position = Vector2(460, 260)
	for i in range(40):
		player.move_and_collide(Vector2(10, 0))
		await process_frame

	print("Posição após atravessar a antiga caixa da mesa: %s" % player.position)
	assert(player.position.x >= 500.0, "ERRO: Ainda há colisão bloqueando a área da mesa! x=%f" % player.position.x)
	print("[PASS] Área da mesa de refeição liberada; jogador avançou até x=%f" % player.position.x)

	player.position = Vector2(470, 320)
	for i in range(40):
		player.move_and_collide(Vector2(0, -10))
		await process_frame

	print("Posição após subir pela antiga caixa da mesa: %s" % player.position)
	assert(player.position.y <= 250.0, "ERRO: Ainda há colisão bloqueando a área da mesa! y=%f" % player.position.y)
	print("[PASS] Área inferior da mesa liberada; jogador subiu até y=%f" % player.position.y)

	# ----------------------------------------------------
	# TESTE 4: Bloqueio da Parede Leste Inferior (antigo bug da imagem 6)
	# ----------------------------------------------------
	print("\n--- TESTE 4: Bloqueio da Parede Leste Inferior (não deve sair do quarto) ---")
	player.position = Vector2(520, 290)
	for i in range(40):
		player.move_and_collide(Vector2(10, 0))
		await process_frame

	print("Posição após tentar atravessar parede leste: %s" % player.position)
	assert(player.position.x <= 548.0, "ERRO: Player atravessou a parede leste! x=%f" % player.position.x)
	print("[PASS] Parede leste barrou o jogador em x=%f (máximo seguro <= 548)" % player.position.x)

	# ----------------------------------------------------
	# TESTE 5: Barreira do Vão da Porta para o Vazio Exterior
	# ----------------------------------------------------
	print("\n--- TESTE 5: Barreira do Vão da Porta (caminhável até a soleira, bloqueia o vazio) ---")
	player.position = Vector2(535, 275)
	for i in range(40):
		player.move_and_collide(Vector2(10, 0))
		await process_frame

	print("Posição na soleira da porta: %s" % player.position)
	assert(player.position.x <= 555.0 and player.position.x >= 540.0, "ERRO: Posição do jogador na soleira incorreta! x=%f" % player.position.x)
	print("[PASS] Vão da porta acessível e protegido: jogador posicionado com precisão em x=%f" % player.position.x)

	# ----------------------------------------------------
	# TESTE 6: Borda Sul do Piso (não deve cair no vazio inferior)
	# ----------------------------------------------------
	print("\n--- TESTE 6: Borda Sul do Piso ---")
	player.position = Vector2(300, 280)
	for i in range(40):
		player.move_and_collide(Vector2(0, 10))
		await process_frame

	print("Posição na borda sul: %s" % player.position)
	assert(player.position.y <= 325.0, "ERRO: Player caiu no vazio sul! y=%f" % player.position.y)
	print("[PASS] Borda sul do piso barrou o jogador em y=%f (máximo seguro <= 325)" % player.position.y)

	# ----------------------------------------------------
	# TESTE 7: Parede Norte (não deve subir na parede)
	# ----------------------------------------------------
	print("\n--- TESTE 7: Parede Norte e Armário ---")
	player.position = Vector2(300, 200)
	for i in range(40):
		player.move_and_collide(Vector2(0, -10))
		await process_frame

	print("Posição na parede norte: %s" % player.position)
	assert(player.position.y >= 157.0, "ERRO: Player subiu na parede norte! y=%f" % player.position.y)
	print("[PASS] Parede norte barrou o jogador em y=%f (mínimo seguro >= 157)" % player.position.y)

	# ----------------------------------------------------
	# TESTE 8: Verificação de Interações (Porta vs Mesa)
	# ----------------------------------------------------
	print("\n--- TESTE 8: Verificação de Isolamento da Porta vs Mesa de Refeição ---")
	# 8A: Na mesa de refeição, a porta NUNCA deve ser acionada
	player.position = Vector2(470, 220)
	player.facing_dir = Vector2.RIGHT
	player._update_interaction_offset()
	for f in range(5):
		await physics_frame
	var item_at_table: Interactable = player.get_best_interactable()
	assert(item_at_table == null or item_at_table.name != "Porta_Saida", "ERRO: Porta para Agdangan acionada na mesa!")
	print("[PASS] Porta para Agdangan NUNCA é acionada na mesa de refeição! (Item ativo: %s)" % (item_at_table.name if item_at_table else "Nenhum"))

	# 8B: Na soleira da porta, a porta DEVE ser acionada com perfeição
	player.position = Vector2(538, 225)
	player.facing_dir = Vector2.RIGHT
	player._update_interaction_offset()
	for f in range(10):
		await physics_frame
	var item_at_door: Interactable = player.get_best_interactable()
	assert(item_at_door != null and item_at_door.name == "Porta_Saida", "ERRO: Porta para Agdangan NÃO encontrada na soleira! (Item: %s)" % (item_at_door.name if item_at_door else "Nulo"))
	print("[PASS] Porta para Agdangan ativada com perfeição na soleira da porta: %s" % item_at_door.get_prompt_text())

	print("\n==================================================")
	print("=== TODOS OS 8 TESTES DE VALIDAÇÃO PASSARAM! ===")
	print("==================================================")
	quit(0)
