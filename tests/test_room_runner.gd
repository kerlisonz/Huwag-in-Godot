extends SceneTree

func _init() -> void:
	print("=== INICIANDO TESTE DO QUARTO DE HUWAG COM AUTOLOADS ===")
	# 1. Carregar GameState autoload
	var gs_script: Script = load("res://scripts/autoload/game_state.gd")
	var gs: Node = Node.new()
	gs.name = "GameState"
	gs.set_script(gs_script)
	root.add_child(gs)
	print("[OK] Autoload GameState instanciado com sucesso.")

	call_deferred("_run_test")

func _run_test() -> void:
	# 2. Carregar RoomHuwag
	var room_scene: PackedScene = load("res://scenes/levels/RoomHuwag.tscn")
	var room: Node2D = room_scene.instantiate() as Node2D
	root.add_child(room)
	print("[OK] RoomHuwag adicionado à árvore.")

	await process_frame
	await process_frame

	# 3. Testar referências dos nós
	var bg: Sprite2D = room.get_node_or_null("Background")
	assert(bg != null, "Background ausente")
	print("[OK] Background: %s, size: %s, filter: %d" % [bg.texture.resource_path, bg.texture.get_size(), bg.texture_filter])

	var player: PlayerController = room.get_node_or_null("YSortEntities/Player")
	assert(player != null, "Player ausente")
	print("[OK] Player presente em YSortEntities, posição: %s" % player.position)

	# 4. Verificar ausência de nós duplicados
	var cab := room.get_node_or_null("YSortEntities/Cabinet")
	var tbl := room.get_node_or_null("YSortEntities/Table")
	var cat := room.get_node_or_null("YSortEntities/Cat")
	var fan := room.get_node_or_null("YSortEntities/WallFan")
	assert(cab == null and tbl == null and cat == null and fan == null, "Nós redundantes ainda existem")
	print("[OK] Verificação de nós redundantes: nenhum duplicado encontrado.")

	# 5. Testar movimento do jogador por física
	print("Simulando movimento do jogador para a esquerda...")
	player.velocity = Vector2(-100, 0)
	for i in range(15):
		player._physics_process(0.016)
		await process_frame
	print("[OK] Posição após mover para a esquerda: %s" % player.position)

	print("Simulando movimento do jogador para a direita em direção à porta...")
	player.velocity = Vector2(100, 0)
	for i in range(30):
		player._physics_process(0.016)
		await process_frame
	print("[OK] Posição após mover para a direita: %s" % player.position)

	# 6. Salvar captura de tela
	var viewport := root.get_viewport()
	var img := viewport.get_texture().get_image()
	if img:
		img.save_png("res://docs/screenshots/room_gameplay_screenshot.png")
		print("[OK] Screenshot da validação salva em res://docs/screenshots/room_gameplay_screenshot.png")

	print("=== TODOS OS TESTES PASSARAM COM SUCESSO! ===")
	quit(0)
