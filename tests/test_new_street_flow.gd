extends SceneTree

func _init() -> void:
	create_timer(15.0).timeout.connect(func() -> void:
		push_error("TIMEOUT: test_new_street_flow excedeu 15s")
		quit(1)
	)
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
	var gs = root.get_node("GameState")
	gs.reset_to_new_game()
	gs.in_game_minutes_per_real_second = 0.0

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

	# 3B. Valida caminhada livre no tapete Banig + colisão exata na cama e na mesa de remédios
	var furn_layer := room.find_child("V2FurnitureLayer", true, false) as TileMapLayer
	assert(furn_layer != null and furn_layer.collision_enabled == true and furn_layer.y_sort_enabled == true, "V2FurnitureLayer deve ter colisão e Y-sort ativos!")
	player.position = Vector2(232, 250)
	player.facing_dir = Vector2.UP
	for _i in range(15):
		player.move_and_collide(Vector2(0, -3))
	assert(player.position.y < 244.0 and player.position.y >= 224.0, "Tapete Banig deve ser caminhável e a base da cama deve barrar em y=224..243 (y=%f)" % player.position.y)
	player.position = Vector2(288, 192)
	player.facing_dir = Vector2.LEFT
	for _i in range(18):
		player.move_and_collide(Vector2(-3, 0))
	assert(player.position.x >= 256.0 and player.position.x <= 272.0, "Lateral da cama deve travar rente ao sprite sem parede invisível no meio do quarto (x=%f)" % player.position.x)
	print("[PASS] Tapete Banig livre e colisão exata na cama validados!")

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
	print("[PASS] Huwag apareceu na rua em frente à sua casa: %s (esperado x=408, y=378)" % street_player.position)
	assert(abs(street_player.position.x - 408.0) < 2.0 and abs(street_player.position.y - 378.0) < 2.0, "Spawn diante da casa incorreto!")
	assert(street.get_node_or_null("Interactables/Quadra_Basquete") == null, "Quadra_Basquete removida conforme redesign!")

	# 6. Testa colisão da fachada da Casa de Huwag (não deve atravessar parede ao norte)
	print("Testando colisão da parede norte da Casa de Huwag...")
	for i in range(30):
		street_player.move_and_collide(Vector2(0, -5))
		await process_frame
	print("Posição de Huwag bloqueada contra a fachada: %s" % street_player.position)
	assert(street_player.position.y >= 352.0, "Fachada da casa deve bloquear travessia indevida!")
	print("[PASS] Colisão da fachada da casa barrou Huwag em y=%f" % street_player.position.y)

	# 7. Huwag interage com a porta da sua casa para retornar
	street_player.position = Vector2(408, 376)
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

	# 8b. Valida contenção da porta sul do FireStation (impede sair para o vazio)
	main_node.load_level("res://scenes/levels/FireStation.tscn", "initial")
	for i in range(15):
		await process_frame
	var fstation = main_node.get_node_or_null("LevelContainer/FireStation")
	var fs_player = fstation.get_node_or_null("YSortEntities/Player") as CharacterBody2D
	fs_player.position = Vector2(480, 540)
	for _k in range(20):
		fs_player.move_and_collide(Vector2(0, 5))
		await physics_frame
	assert(fs_player.position.y < 560.0, "Porta sul do Quartel BFP deve impedir sair para o vazio (y=%f)" % fs_player.position.y)
	print("[PASS] Contenção física da porta sul do Quartel BFP validada em y=%f!" % fs_player.position.y)

	# 9. Retorna à rua para testar as novas interações dos elementos reais da cena
	main_node.load_level("res://scenes/levels/StreetPreview.tscn", "from_room")
	for i in range(25):
		await process_frame
	var street2 = main_node.get_node_or_null("LevelContainer/StreetPreview")
	var p2 = street2.get_node_or_null("YSortEntities/Player")

	# Teste Interação 1: Sari-Sari Store
	p2.position = Vector2(520, 384)
	p2.facing_dir = Vector2.UP
	p2._update_interaction_offset()
	for f in range(5): await physics_frame
	var inter_sari = p2.get_best_interactable()
	assert(inter_sari != null and inter_sari.name == "Sari_Sari", "Sari-Sari Store deve ser detectada!")
	print("[PASS] Interação detectada: %s" % inter_sari.title)

	# Teste Interação 2: Quartel BFP (Caminhão de Bombeiros)
	p2.position = Vector2(680, 392)
	p2.facing_dir = Vector2.UP
	p2._update_interaction_offset()
	for f in range(5): await physics_frame
	var inter_truck = p2.get_best_interactable()
	assert(inter_truck != null and inter_truck.name == "Caminhao_Bombeiros", "Caminhão de Bombeiros deve ser detectado!")
	print("[PASS] Interação detectada: %s" % inter_truck.title)

	# Teste Interação 3: Triciclo
	p2.position = Vector2(904, 452)
	p2.facing_dir = Vector2.UP
	p2._update_interaction_offset()
	for f in range(5): await physics_frame
	var inter_tri = p2.get_best_interactable()
	assert(inter_tri != null and inter_tri.name == "Karinderya_Triciclo", "Triciclo deve ser detectado!")
	print("[PASS] Interação detectada: %s" % inter_tri.title)

	# Teste Interação 4: Igreja de Agdangan aproximada à rua
	p2.position = Vector2(1192, 344)
	p2.facing_dir = Vector2.UP
	p2._update_interaction_offset()
	for f in range(5): await physics_frame
	var inter_church = p2.get_best_interactable()
	assert(inter_church != null and inter_church.name == "Igreja_Agdangan", "Igreja de Agdangan deve ser detectada!")
	print("[PASS] Interação detectada: %s" % inter_church.title)

	# Teste Interação 5: Cais da Praia a Oeste
	p2.position = Vector2(160, 454)
	p2.facing_dir = Vector2.UP
	p2._update_interaction_offset()
	for f in range(5): await physics_frame
	var inter_cais = p2.get_best_interactable()
	assert(inter_cais != null and inter_cais.name == "Cais_Praia", "Píer da Praia deve ser detectado!")
	print("[PASS] Interação detectada: %s" % inter_cais.title)

	# Verifica iluminação de manhã vs noite nos postes de luz da rua
	gs.set_clock_minutes(390, false) # 06:30 manhã
	await process_frame
	var morning_lamp_e: float = (street2._lamp_lights[0] as PointLight2D).energy
	gs.set_clock_minutes(1110, false) # 18:30 noite
	await process_frame
	var night_lamp_e: float = (street2._lamp_lights[0] as PointLight2D).energy
	assert(night_lamp_e > morning_lamp_e * 2.0, "Postes da rua devem acender com mais intensidade à noite (manhã=%f, noite=%f)" % [morning_lamp_e, night_lamp_e])
	print("[PASS] Acendimento automático dos postes à noite validado (manhã=%.2f -> noite=%.2f)." % [morning_lamp_e, night_lamp_e])

	# 10. Valida Tilesets v2 (interiors_v2 / agdangan_town_v2) + Cooldown anti-loop de diálogo (E / Espaço / Mouse) + Áudio Adaptativo Low-Pass
	assert(street2.ground_normal.tile_set.resource_path.ends_with("agdangan_town_v2_normal_tileset.tres"), "StreetPreview deve usar agdangan_town_v2_normal_tileset.tres!")
	print("[PASS] StreetPreview reconstruída com agdangan_town_v2_normal_tileset.tres (16x16).")

	var nena_npc: NpcEntity = street2._npcs["NPC_Aling_Nena"]
	var nena_ia: Interactable = nena_npc.interact_area as Interactable
	assert(nena_ia != null and nena_ia.can_interact(), "Aling Nena deve permitir interação antes do diálogo")

	var dlg_open_count := {"n": 0}
	street2.request_dialogue.connect(func(_pages: Array, _cb: Callable) -> void:
		dlg_open_count["n"] += 1
	)
	nena_ia.trigger_interaction()
	await process_frame
	assert(gs.dialogue_active == true and dbox.is_open() == true, "Diálogo com Aling Nena deve abrir")
	assert(dlg_open_count["n"] == 1, "Diálogo deve abrir exatamente 1 vez")
	assert(nena_ia.can_interact() == false, "Interactable deve bloquear novas interações enquanto dialogue_active == true")

	# Tenta clicar/interagir novamente enquanto o diálogo está aberto -> não deve reiniciar!
	nena_ia.trigger_interaction()
	assert(dlg_open_count["n"] == 1, "Clicar rápido durante o diálogo NÃO deve reiniciar a conversa!")

	# Fecha o diálogo e verifica o cooldown pós-fechamento (0.28s)
	dbox.close_dialogue()
	assert(gs.dialogue_active == false and gs.dialogue_cooldown > 0.20, "Fechar diálogo deve ativar dialogue_cooldown pós-fechamento")
	assert(gs.is_interaction_blocked() == true, "Durante o cooldown pós-fechamento, o mesmo clique/E não pode reabrir o diálogo!")
	nena_ia.trigger_interaction()
	assert(dlg_open_count["n"] == 1, "Interação bloqueada durante o cooldown pós-fechamento (zero loop!)")

	# Simula passagem do cooldown (> 0.30s) -> permite nova conversa normalmente
	gs._process(0.35)
	assert(gs.is_interaction_blocked() == false and nena_ia.can_interact() == true, "Após o cooldown de 0.28s, o NPC volta a permitir conversa")
	nena_ia.trigger_interaction()
	await process_frame
	assert(dlg_open_count["n"] == 2, "Após o cooldown de 0.28s, nova conversa deve iniciar normalmente")
	dbox.close_dialogue()
	gs._process(0.35)
	print("[PASS] Correção do bug de loop de interação com NPC (E / Espaço / Mouse + cooldown 0.28s) validada!")

	# Verifica Áudio Adaptativo e Filtro Passa-Baixa (Low-Pass)
	var am = root.get_node_or_null("AudioManager")
	if am != null:
		assert(am.get_bus_lowpass_cutoff("Music") > 0.0 and am.get_bus_lowpass_cutoff("Music") <= 1700.0, "Bus Music deve ter filtro Low-Pass ativo")
		assert(am.get_bus_lowpass_cutoff("Ambience") > 0.0 and am.get_bus_lowpass_cutoff("Ambience") <= 1500.0, "Bus Ambience deve ter filtro Low-Pass ativo")
		assert(am.get_bus_lowpass_cutoff("SFX") > 0.0 and am.get_bus_lowpass_cutoff("SFX") <= 2200.0, "Bus SFX deve ter filtro Low-Pass ativo")
		gs.set_clock_minutes(420, false) # Manhã
		am.sync_adaptive_soundtrack("street_preview", false)
		assert(am.get_current_bgm() == "day_theme" and am.get_current_ambience() == "morning_ambience", "Manhã em Agdangan deve tocar day_theme + morning_ambience")
		gs.advance_to_act_2()
		gs.set_higher_dose(true)
		am.sync_adaptive_soundtrack("street_preview", false)
		assert(am.get_current_bgm() == "corrupted_tension", "Modo Corrompido deve trocar para corrupted_tension")
		gs.set_higher_dose(false)
		print("[PASS] AudioManager com Low-Pass Filter e Trilha Sonora Adaptativa validados!")

	# Verifica colisão física real + Y-sort em V2TownPropsLayer (Sari-Sari, casas, coqueiros, oceano)
	var town_props := street2.find_child("V2TownPropsLayer", true, false) as TileMapLayer
	assert(town_props != null and town_props.collision_enabled == true, "V2TownPropsLayer deve ter colisão ativada!")
	assert(town_props.y_sort_enabled == true, "V2TownPropsLayer deve ter Y-sort ativado!")
	if p2 != null:
		p2.position = Vector2(520, 384) # Diante da Sari-Sari Store de Aling Nena (x=30..34, y=18..21 -> base y=352)
		for _i in range(12):
			p2.move_and_collide(Vector2(0, -4))
		assert(p2.position.y >= 350.0, "Sari-Sari Store deve bloquear o player (y=%f)" % p2.position.y)

		p2.position = Vector2(136, 280) # Abaixo do coqueiro da praia (7, 10 -> tronco em y=248..256)
		for _i in range(12):
			p2.move_and_collide(Vector2(0, -4))
		assert(p2.position.y >= 254.0, "Coqueiro da praia deve bloquear o player (y=%f)" % p2.position.y)

		p2.position = Vector2(1192, 344) # Diante da Igreja de Agdangan (corpo até y=320)
		for _i in range(12):
			p2.move_and_collide(Vector2(0, -4))
		assert(p2.position.y >= 316.0, "Igreja deve bloquear o player (y=%f)" % p2.position.y)

		p2.position = Vector2(120, 300) # Margem oeste da praia caminhando para o oceano raso (x=96)
		for _i in range(12):
			p2.move_and_collide(Vector2(-4, 0))
		assert(p2.position.x >= 96.0, "Margem do oceano deve bloquear o player (x=%f)" % p2.position.x)
		print("[PASS] Colisões físicas de prédios, igreja, coqueiros e oceano em StreetPreview validadas!")

	print("\n==================================================")
	print("=== TODOS OS TESTES DE FLUXO E INTERAÇÕES PASSARAM! ===")
	print("==================================================")
	quit(0)
