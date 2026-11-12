extends SceneTree

func _init() -> void:
	print("=== INICIANDO TESTE DE VALIDAÇÃO DO QUARTO DE HUWAG ===")
	call_deferred("_run_validation")

func _run_validation() -> void:
	var room_scene := load("res://scenes/levels/RoomHuwag.tscn") as PackedScene
	if not room_scene:
		print("ERRO: Falha ao carregar RoomHuwag.tscn!")
		quit(1)
		return
	print("[OK] Cena RoomHuwag.tscn carregada com sucesso.")

	var room := room_scene.instantiate() as Node2D
	root.add_child(room)
	await process_frame
	await process_frame

	# 1. Verificar nós do cenário
	var bg := room.get_node_or_null("Background") as Sprite2D
	if not bg:
		print("ERRO: Nó Background ausente!")
		quit(1)
		return
	print("[OK] Nó Background presente. Textura: %s, Tamanho: %s, Filter: %d" % [
		bg.texture.resource_path,
		bg.texture.get_size(),
		bg.texture_filter
	])

	# 2. Verificar que não existem nós duplicados
	var cab := room.get_node_or_null("YSortEntities/Cabinet")
	var tbl := room.get_node_or_null("YSortEntities/Table")
	var cat := room.get_node_or_null("YSortEntities/Cat")
	var fan := room.get_node_or_null("YSortEntities/WallFan")

	if cab or tbl or cat or fan:
		print("AVISO: Nós de sobreposição ainda presentes: cab=%s tbl=%s cat=%s fan=%s" % [cab, tbl, cat, fan])
	else:
		print("[OK] Nenhum nó de sobreposição duplicado na cena. Móveis e cenário unificados sem bordas fantasmas.")

	# 3. Verificar jogador
	var player_count := 0
	for child in room.get_node("YSortEntities").get_children():
		if child is PlayerController or child.name == "Player":
			player_count += 1
	print("[OK] Contagem de instâncias do Player em YSortEntities: %d (esperado: 1)" % player_count)
	if player_count != 1:
		print("ERRO: Número de instâncias do Player incorreto!")
		quit(1)
		return

	var player := room.get_node("YSortEntities/Player") as PlayerController
	print("[OK] Posição inicial do Player: %s" % player.position)

	# 4. Verificar interações
	var interactables := room.get_node("Interactables")
	print("[OK] Quantidade de interactables registrados: %d" % interactables.get_child_count())
	var ids: Array[String] = []
	for child in interactables.get_children():
		if child is Interactable:
			ids.append(child.interaction_id)
	print("[OK] Interactables ativos: %s" % [", ".join(ids)])

	# 5. Captura de tela para validação visual
	await process_frame
	await process_frame
	var img := root.get_viewport().get_texture().get_image()
	if img:
		var save_err := img.save_png("res://docs/screenshots/room_huwag_validated.png")
		print("[OK] Screenshot da cena salva em res://docs/screenshots/room_huwag_validated.png (err=%d)" % save_err)

	print("=== TESTE CONCLUÍDO COM SUCESSO! ===")
	quit(0)
