extends SceneTree

## Valida integração completa do Huwag v2 (96x96) no Player, Quarto, Armário, Menu e Saves.

const SAVE_PREVIEW_FLAG := "--capture-room"
const SCRATCH_DIR := "C:/Users/SnyX/.gemini/antigravity/brain/6f04634a-b7d4-4d6f-9c20-24b6fdf404a0"


func _init() -> void:
	call_deferred("_run_suite")


func _wait_frames(n: int) -> void:
	for _i in range(n):
		await process_frame


func _assert_true(cond: bool, msg: String) -> void:
	if not cond:
		push_error("ASSERT FAILED: " + msg)
		assert(cond, msg)


func _ensure_autoloads() -> void:
	if not root.has_node("AudioManager"):
		var am_class = load("res://scripts/autoload/audio_manager.gd")
		var am = am_class.new()
		am.name = "AudioManager"
		root.add_child(am)
	if not root.has_node("GameState"):
		var gs_class = load("res://scripts/autoload/game_state.gd")
		var gs = gs_class.new()
		gs.name = "GameState"
		root.add_child(gs)


func _run_suite() -> void:
	print("==================================================================")
	print("=== TESTE INTEGRAÇÃO HUWAG V2 (96x96, ARMÁRIO, MENU E CÂMERA) ===")
	print("==================================================================")

	_ensure_autoloads()
	var gs := root.get_node("GameState")
	gs.call("reset_to_new_game")
	gs.call("set_self_switch", "EV_Introducao", "A", true)

	# 1. Normalização casual / bfp / bombeiro
	gs.call("set_equipped_outfit", "bombeiro", false)
	_assert_true(gs.get("equipped_outfit") == "bfp", "'bombeiro' deve normalizar para 'bfp'")
	gs.call("set_equipped_outfit", "casual", false)
	_assert_true(gs.get("equipped_outfit") == "casual", "'casual' deve permanecer 'casual'")
	print("[PASS] Normalização GameState ('casual', 'bfp', 'bombeiro') validada.")

	# 2. Instancia Main.tscn (Quarto de Huwag + HUD + Menu F1/ESC + Caixa de Diálogo)
	var main_scene := load("res://scenes/main/Main.tscn") as PackedScene
	_assert_true(main_scene != null, "Main.tscn deve carregar")
	var main := main_scene.instantiate()
	root.add_child(main)
	await _wait_frames(8)

	var room: Node2D = main.get("_current_level")
	_assert_true(room != null, "RoomHuwag deve ser carregada como nível inicial em Main")
	var player: PlayerController = room.get_node_or_null("YSortEntities/Player") as PlayerController
	_assert_true(player != null, "PlayerController deve existir em RoomHuwag")
	_assert_true(player._using_v2_sprites, "Player deve ativar SpriteFrames pixel art (huwag_v3)")
	_assert_true(player.character_sprite.sprite_frames.resource_path.ends_with("huwag_casual_spriteframes.tres"),
		"Sprite inicial deve ser huwag_casual_spriteframes.tres")
	_assert_true(player.character_sprite.scale.is_equal_approx(Vector2(1.0, 1.0)), "Escala visual do sprite deve ser 1.0 (1:1 pixel art)")
	_assert_true(player.character_sprite.offset.is_equal_approx(Vector2(0.0, -7.0)), "Offset dos pés deve ser (0, -7)")
	_assert_true(player.camera.zoom.is_equal_approx(Vector2(1.18, 1.18)), "Camera2D zoom calibrado para 1.18")
	print("[PASS] Player no Quarto com SpriteFrames v3 (1:1 pixel art), pés ancorados e câmera 1.18.")

	# 3. Movimentação 4 direções (walk_*, run_* e idle_*)
	for case in [
		{"dir": Vector2.DOWN, "suffix": "down"},
		{"dir": Vector2.UP, "suffix": "up"},
		{"dir": Vector2.LEFT, "suffix": "left"},
		{"dir": Vector2.RIGHT, "suffix": "right"},
	]:
		player.facing_dir = case["dir"]
		player.is_moving = true
		player.is_running = false
		player._update_character_sprite_state()
		_assert_true(player.character_sprite.animation == "walk_%s" % case["suffix"],
			"Esperado walk_%s, obtido %s" % [case["suffix"], player.character_sprite.animation])
		_assert_true(is_equal_approx(player.character_sprite.speed_scale, 1.0), "Velocidade walk normal = 1.0")

		player.is_running = true
		player._update_character_sprite_state()
		_assert_true(player.character_sprite.animation == "run_%s" % case["suffix"],
			"Esperado run_%s, obtido %s" % [case["suffix"], player.character_sprite.animation])
		_assert_true(is_equal_approx(player.character_sprite.speed_scale, 1.45), "Velocidade run = 1.45")

		player.is_moving = false
		player.is_running = false
		player._update_character_sprite_state()
		_assert_true(player.character_sprite.animation == "idle_%s" % case["suffix"],
			"Esperado idle_%s, obtido %s" % [case["suffix"], player.character_sprite.animation])
	print("[PASS] Todas as animações (idle_*, walk_*, run_*) respondem nas 4 direções.")

	# 4. Captura opcional em GPU real (Casual)
	var capture_mode := OS.get_cmdline_user_args().has(SAVE_PREVIEW_FLAG)
	if capture_mode:
		DirAccess.make_dir_recursive_absolute(SCRATCH_DIR)
		player.position = Vector2(258, 198)
		player.facing_dir = Vector2.DOWN
		player.is_moving = false
		player._update_character_sprite_state()
		await _wait_frames(12)
		var img_c := root.get_viewport().get_texture().get_image()
		if img_c != null:
			img_c.save_png(SCRATCH_DIR + "/room_huwag_v2_casual.png")
			print("[SHOT] Salvo room_huwag_v2_casual.png (%dx%d)" % [img_c.get_width(), img_c.get_height()])

	# 5. Interação real com Armário no Quarto de Huwag -> Bombeiro
	player.position = Vector2(258, 178)
	player.facing_dir = Vector2.UP
	await _wait_frames(4)
	var armario: Interactable = room.get_node_or_null("Interactables/Armario_Uniforme") as Interactable
	_assert_true(armario != null, "Armario_Uniforme deve existir no quarto")
	player._refresh_prompt()
	_assert_true(player.prompt_label.visible and player.prompt_label.position.y <= -45.0,
		"PromptLabel deve aparecer acima do cabelo em y <= -45")

	armario.trigger_interaction()
	await _wait_frames(2)
	var dbox: Control = main.get("dialogue_box")
	_assert_true(dbox != null and bool(dbox.call("is_open")), "Armário deve abrir caixa de diálogo de seleção de traje")
	dbox.set("_selected_choice", 0) # Vestir Uniforme de Bombeiro (BFP)
	dbox.call("_advance_page")
	await _wait_frames(3)
	_assert_true(gs.get("equipped_outfit") == "bfp", "Armário deve equipar Uniforme Bombeiro (bfp)")
	_assert_true(player.character_sprite.sprite_frames.resource_path.ends_with("huwag_bombeiro_spriteframes.tres"),
		"Player deve trocar ao vivo para huwag_bombeiro_spriteframes.tres")
	print("[PASS] Armário do Quarto trocou traje para Bombeiro BFP com sucesso.")

	if capture_mode:
		player.position = Vector2(258, 198)
		player.facing_dir = Vector2.DOWN
		player._update_character_sprite_state()
		await _wait_frames(12)
		var img_b := root.get_viewport().get_texture().get_image()
		if img_b != null:
			img_b.save_png(SCRATCH_DIR + "/room_huwag_v2_bombeiro.png")
			print("[SHOT] Salvo room_huwag_v2_bombeiro.png (%dx%d)" % [img_b.get_width(), img_b.get_height()])

	# 6. Seletor de traje via Menu F1/ESC (OutfitButton) -> volta para Casual
	main.call("_toggle_controls_modal")
	await _wait_frames(2)
	var outfit_btn: Button = main.get("outfit_button")
	_assert_true(outfit_btn != null, "OutfitButton deve existir no ControlsModal")
	_assert_true(outfit_btn.text.find("Bombeiro") != -1, "OutfitButton deve indicar traje atual Bombeiro")
	outfit_btn.emit_signal("pressed")
	await _wait_frames(2)
	_assert_true(gs.get("equipped_outfit") == "casual", "OutfitButton no menu deve alternar para casual")
	_assert_true(player.character_sprite.sprite_frames.resource_path.ends_with("huwag_casual_spriteframes.tres"),
		"Player deve voltar ao vivo para huwag_casual_spriteframes.tres")
	_assert_true(outfit_btn.text.find("Casual") != -1, "OutfitButton deve atualizar texto para Casual")
	main.call("_toggle_controls_modal")
	await _wait_frames(2)
	print("[PASS] Botão de troca de traje no Menu [F1/ESC] funcional.")

	# 7. Persistência em save/load mantendo 'bfp'
	gs.call("set_equipped_outfit", "bfp", false)
	_assert_true(gs.call("save_game"), "save_game deve concluir")
	gs.call("set_equipped_outfit", "casual", false)
	_assert_true(gs.call("load_game"), "load_game deve concluir")
	_assert_true(gs.get("equipped_outfit") == "bfp", "load_game deve restaurar equipped_outfit='bfp'")
	print("[PASS] Persistência de traje (save/load) validada.")

	main.queue_free()
	await _wait_frames(2)
	print("\n==================================================================")
	print("=== INTEGRAÇÃO HUWAG V2 VALIDADA 100% — TODOS OS TESTES PASS! ===")
	print("==================================================================")
	quit(0)
