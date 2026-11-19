extends SceneTree

## Suíte abrangente de validação dos 9 pilares da atualização estrutural, visual e narrativa de Huwag.

func _fail(msg: String) -> void:
	push_error("[FAIL] " + msg)
	printerr("[FAIL] " + msg)
	quit(1)


func _assert_ok(cond: bool, msg: String) -> void:
	if not cond:
		_fail(msg)


func _init() -> void:
	create_timer(20.0).timeout.connect(func(): _fail("TIMEOUT: test_overhaul_9_pillars excedeu 20s"))
	call_deferred("_run_all")


func _gs() -> Node:
	return root.get_node_or_null("GameState")


func _am() -> Node:
	return root.get_node_or_null("AudioManager")


func _cleanup_test_slot(slot_idx: int) -> void:
	var gs := _gs()
	if gs == null:
		return
	var json_path := "%s/slot_%d.json" % [gs.SAVE_SLOTS_DIR, slot_idx]
	var png_path := "%s/slot_%d.png" % [gs.SAVE_SLOTS_DIR, slot_idx]
	if FileAccess.file_exists(json_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(json_path))
	if FileAccess.file_exists(png_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(png_path))


func _run_all() -> void:
	print("=== INICIANDO TESTE DOS 9 PILARES (OVERHAUL HUWAG) ===")
	await process_frame
	var gs := _gs()
	var am := _am()
	_assert_ok(gs != null and am != null, "Autoloads GameState e AudioManager presentes")

	# ------------------------------------------------------------------
	# PILAR 6: Trilha Sonora Royalty-Free (Incompetech CC-BY 4.0) + Font
	# ------------------------------------------------------------------
	print("--- Pilar 6: Áudio & Fontes ---")
	_assert_ok(am.BGM_FILE_MAP.size() >= 6, "AudioManager.BGM_FILE_MAP possui >= 6 faixas")
	_assert_ok(am.MUSIC_CREDITS.size() >= 6, "AudioManager.MUSIC_CREDITS possui >= 6 entradas")
	for track_key in am.BGM_FILE_MAP.keys():
		var mp3_path: String = str(am.BGM_FILE_MAP[track_key])
		var stream := load(mp3_path)
		_assert_ok(stream != null and stream is AudioStream, "Faixa BGM carregada com sucesso: %s" % mp3_path)
	var custom_font_path: String = str(ProjectSettings.get_setting("gui/theme/custom_font", ""))
	_assert_ok(custom_font_path == "res://assets/fonts/omori_dialogue_font.tres",
		"Projeto usa globalmente omori_dialogue_font.tres (atual=%s)" % custom_font_path)
	print("[PASS] Pilar 6: 6 faixas MP3 + créditos musicais + fonte Omori global validados.")

	# ------------------------------------------------------------------
	# PILAR 4: Menu Principal Limpo (CoverArt, sem VHS OSD, 6 botões)
	# ------------------------------------------------------------------
	print("--- Pilar 4: Menu Principal ---")
	var title_scene: PackedScene = load("res://scenes/menu/TitleScreen.tscn")
	var title_ui := title_scene.instantiate()
	root.add_child(title_ui)
	await process_frame
	await process_frame
	_assert_ok(title_ui.get_node_or_null("OsdTimecodeLabel") == null, "Sem OSD VHS de timecode")
	_assert_ok(title_ui.get_node_or_null("OsdTapeLabel") == null, "Sem OSD VHS SP/REC")
	var cover := title_ui.get_node_or_null("CoverArt") as TextureRect
	_assert_ok(cover != null and cover.texture != null, "CoverArt presente com textura")
	var btn_names := ["BtnNewGame", "BtnContinue", "BtnLoadGame", "BtnOptions", "BtnMusicCredits", "BtnExit"]
	for bn in btn_names:
		_assert_ok(title_ui.get_node_or_null("MenuContainer/MenuVBox/" + bn) != null, "Botão do menu presente: " + bn)
	title_ui.call("_on_credits_pressed")
	await process_frame
	var credits_list := title_ui.get_node_or_null("CreditsModal/Card/Margin/VBox/CreditsList") as VBoxContainer
	_assert_ok(credits_list != null and credits_list.get_child_count() >= 6, "Modal de Créditos Musicais lista >= 6 faixas")
	title_ui.queue_free()
	await process_frame
	print("[PASS] Pilar 4: TitleScreen limpa + 6 botões + Créditos Musicais validados.")

	# ------------------------------------------------------------------
	# PILAR 5 & 8: Retratos 96x96 Transparentes (48) + DialogueBox Omori
	# ------------------------------------------------------------------
	print("--- Pilares 5 & 8: 48 Retratos Transparentes + DialogueBox Omori ---")
	var tested_portraits := 0
	for cid in CharacterProfiles.PROFILES.keys():
		var prof: Dictionary = CharacterProfiles.PROFILES[cid]
		for dict_key in ["portraits", "portraits_bfp"]:
			if not prof.has(dict_key):
				continue
			var pdict: Dictionary = prof[dict_key]
			for p_key in pdict.keys():
				var p_path: String = str(pdict[p_key])
				_assert_ok(FileAccess.file_exists(p_path), "Retrato existe no disco: %s" % p_path)
				var pim := Image.new()
				_assert_ok(pim.load(ProjectSettings.globalize_path(p_path)) == OK, "Imagem válida: %s" % p_path)
				_assert_ok(pim.get_width() == 96 and pim.get_height() == 96, "Retrato %s deve ser 96x96" % p_path)
				_assert_ok(pim.get_pixel(0, 0).a < 0.02 and pim.get_pixel(95, 0).a < 0.02,
					"Cantos superiores do retrato %s devem ter alpha == 0.0" % p_path)
				var mid_opaque := false
				for sy in range(28, 95, 4):
					if pim.get_pixel(48, sy).a > 0.5:
						mid_opaque = true
						break
				_assert_ok(mid_opaque, "Retrato %s precisa conter busto opaco visível no centro/base" % p_path)
				tested_portraits += 1
	_assert_ok(tested_portraits >= 48, "Pelo menos 48 entradas de retrato testadas (total=%d)" % tested_portraits)

	var dbox_scene: PackedScene = load("res://scenes/ui/DialogueBox.tscn")
	var dbox: DialogueBox = dbox_scene.instantiate() as DialogueBox
	root.add_child(dbox)
	await process_frame
	for node_name in ["FramePanel", "NameplatePanel", "PortraitFrame", "PortraitFrame/SpeakerPortrait", "SpeechArea/DialogueText", "ContinueHint", "ChoicesPanel"]:
		_assert_ok(dbox.get_node_or_null(node_name) != null, "DialogueBox Omori possui nó " + node_name)
	_assert_ok(dbox.nameplate_panel.position.y < dbox.frame_panel.position.y, "NameplatePanel fica flutuando acima da caixa")
	_assert_ok(dbox.portrait_frame.position.y < dbox.frame_panel.position.y and dbox.portrait_frame.position.x > dbox.nameplate_panel.position.x,
		"PortraitFrame fica flutuando acima à direita da caixa")
	dbox.queue_free()
	await process_frame
	print("[PASS] Pilares 5 & 8: %d retratos 96x96 alpha=0 + DialogueBox estilo Omori validados." % tested_portraits)

	# ------------------------------------------------------------------
	# PILAR 1: RoomHuwag Reorganizado (sem mesa/cadeiras, Pusa animado)
	# ------------------------------------------------------------------
	print("--- Pilar 1: RoomHuwag Reorganizado ---")
	gs.reset_to_new_game()
	gs.set_corrupted_mode(false)
	var room_scene: PackedScene = load("res://scenes/levels/RoomHuwag.tscn")
	var room := room_scene.instantiate()
	root.add_child(room)
	for _i in range(4):
		await process_frame
	_assert_ok(room.find_child("DiningTable", true, false) == null and room.find_child("Mesa_Jantar", true, false) == null,
		"Mesa de jantar central deve ter sido removida")
	var rem := room.get_node_or_null("ObstaclesYsort/Mesa_Remedios") as Node2D
	if rem == null:
		rem = room.find_child("Mesa_Remedios", true, false) as Node2D
	_assert_ok(rem != null and rem.position.y <= 185.0, "Mesa_Remedios deve ficar no criado-mudo encostado à parede norte (y=%s)" % (str(rem.position.y) if rem else "null"))
	var pusa := room.find_child("PusaCatNormal", true, false) as AnimatedSprite2D
	_assert_ok(pusa != null and pusa.sprite_frames != null and pusa.sprite_frames.has_animation("idle"),
		"PusaCatNormal deve existir como AnimatedSprite2D animado")
	var r_player := room.find_child("Player", true, false) as CharacterBody2D
	if r_player == null:
		r_player = get_first_node_in_group("player") as CharacterBody2D
	_assert_ok(r_player != null, "Player presente em RoomHuwag")
	if r_player == null:
		return
	r_player.global_position = Vector2(350.0, 270.0)
	var hit_center := r_player.test_move(r_player.global_transform, Vector2(36.0, 0.0))
	_assert_ok(not hit_center, "Área central do quarto (onde antes ficava a mesa) deve estar 100% livre para caminhar!")
	room.queue_free()
	await process_frame
	print("[PASS] Pilar 1: RoomHuwag livre no centro, criado-mudo norte e gato Pusa animado validados.")

	# ------------------------------------------------------------------
	# PILAR 2: Main (ESC PauseMenu vs F1 ControlsModal) + Save/Load Multi-Slot c/ Thumbnail 320x180
	# ------------------------------------------------------------------
	print("--- Pilar 2: Pause ESC vs F1 + Save/Load 3 Slots c/ Thumbnail ---")
	var main_scene: PackedScene = load("res://scenes/main/Main.tscn")
	var main_node := main_scene.instantiate()
	root.add_child(main_node)
	for _i in range(6):
		await process_frame
	var dbox_m := main_node.get_node_or_null("CanvasLayer/DialogueBox") as DialogueBox
	if dbox_m and dbox_m.is_open():
		dbox_m.close_dialogue()
	await process_frame

	var ev_f1 := InputEventKey.new()
	ev_f1.keycode = KEY_F1
	ev_f1.pressed = true
	main_node._unhandled_input(ev_f1)
	await process_frame
	var ctrl_modal := main_node.get_node_or_null("CanvasLayer/ControlsModal") as Control
	_assert_ok(ctrl_modal != null and ctrl_modal.visible, "Tecla F1 deve abrir ControlsModal")
	_assert_ok(not paused, "F1 ControlsModal não pausa a SceneTree")
	main_node._unhandled_input(ev_f1)
	await process_frame
	_assert_ok(not ctrl_modal.visible, "F1 fecha ControlsModal")

	var ev_esc := InputEventKey.new()
	ev_esc.keycode = KEY_ESCAPE
	ev_esc.pressed = true
	main_node._unhandled_input(ev_esc)
	await process_frame
	var pmenu := main_node.get_node_or_null("PauseMenu") as PauseMenu
	_assert_ok(pmenu != null and pmenu.is_open(), "ESC deve abrir PauseMenu")
	_assert_ok(paused, "PauseMenu aberto deve pausar a SceneTree")
	pmenu.close_pause()
	await process_frame
	_assert_ok(not paused, "Fechar PauseMenu despausa a SceneTree")

	_cleanup_test_slot(3)
	var thumb_src := Image.create(640, 360, false, Image.FORMAT_RGBA8)
	thumb_src.fill(Color("#1A2233"))
	var m_player := get_first_node_in_group("player") as Node2D
	if m_player == null:
		m_player = main_node.find_child("Player", true, false) as Node2D
	_assert_ok(m_player != null, "Player encontrado na cena principal")
	m_player.global_position = Vector2(312.0, 268.0)
	gs.player_hp = 55
	_assert_ok(gs.save_to_slot(3, thumb_src), "save_to_slot(3) deve gravar JSON + thumbnail")
	var summary: Dictionary = gs.get_slot_summary(3)
	_assert_ok(bool(summary.get("exists", false)) and int(summary.get("hp", 0)) == 55, "Summary do slot 3 válido")
	var thumb_loaded := Image.new()
	_assert_ok(thumb_loaded.load(ProjectSettings.globalize_path(str(summary["thumbnail_path"]))) == OK, "Thumbnail PNG legível")
	_assert_ok(thumb_loaded.get_width() == 320 and thumb_loaded.get_height() == 180,
		"Thumbnail deve ter exatamente 320x180 (atual=%dx%d)" % [thumb_loaded.get_width(), thumb_loaded.get_height()])
	gs.player_hp = 100
	m_player.global_position = Vector2(120.0, 120.0)
	_assert_ok(gs.load_from_slot(3), "load_from_slot(3) restaura estado")
	_assert_ok(gs.player_hp == 55 and gs.has_pending_checkpoint_spawn() and gs.consume_pending_checkpoint_spawn().distance_to(Vector2(312.0, 268.0)) < 1.0,
		"load_from_slot(3) preservou HP e posição exata do jogador")
	_cleanup_test_slot(3)
	main_node.queue_free()
	await process_frame
	print("[PASS] Pilar 2: Pause ESC vs F1 + Save/Load com thumbnail 320x180 validados.")

	# ------------------------------------------------------------------
	# PILAR 7: Machado BFP Exclusivo nos Ataques + Zero Gap no Idle
	# ------------------------------------------------------------------
	print("--- Pilar 7: Protagonista Huwag Machado nos Ataques & Zero Gap ---")
	var idle_im := Image.new()
	_assert_ok(idle_im.load(ProjectSettings.globalize_path("res://assets/sprites/huwag_v3/casual/spritesheet_idle.png")) == OK,
		"spritesheet_idle.png carregado")
	var empty_mid_rows := 0
	for yy in range(20, 30):
		var row_opaque := false
		for xx in range(20, 28):
			if idle_im.get_pixel(xx, yy).a > 0.5:
				row_opaque = true
				break
		if not row_opaque:
			empty_mid_rows += 1
	_assert_ok(empty_mid_rows == 0,
		"Idle de Huwag não pode possuir fenda transparente no pescoço/tronco (empty_rows=%d)" % empty_mid_rows)

	var atk_im := Image.new()
	_assert_ok(atk_im.load(ProjectSettings.globalize_path("res://assets/sprites/huwag_v3/casual/spritesheet_attack.png")) == OK,
		"spritesheet_attack.png carregado")
	var combo_im := Image.new()
	_assert_ok(combo_im.load(ProjectSettings.globalize_path("res://assets/sprites/huwag_v3/casual/spritesheet_combo.png")) == OK,
		"spritesheet_combo.png carregado")
	var idle_axe_reds := 0
	for py in range(48):
		for px in range(48):
			var c := idle_im.get_pixel(px, py)
			if c.a > 0.5 and c.r > 0.68 and c.g < 0.25 and c.b < 0.25:
				idle_axe_reds += 1
	var atk_axe_reds := 0
	for py in range(atk_im.get_height()):
		for px in range(atk_im.get_width()):
			var c := atk_im.get_pixel(px, py)
			if c.a > 0.5 and c.r > 0.68 and c.g < 0.25 and c.b < 0.25:
				atk_axe_reds += 1
	_assert_ok(idle_axe_reds == 0 and atk_axe_reds >= 8,
		"Machado de bombeiro só aparece em ataques, nunca no idle (idle_reds=%d, atk_reds=%d)" % [idle_axe_reds, atk_axe_reds])
	print("[PASS] Pilar 7: Zero gap no torso do idle + machado BFP exclusivo nos golpes validados.")

	# ------------------------------------------------------------------
	# PILAR 3: Sant'Elmon & Guardiã da Lagoa Humanoides + Attack2 Orb
	# ------------------------------------------------------------------
	print("--- Pilar 3: Sant'Elmon & Guardiã Humanoides 4 Direções ---")
	var sant_scene: PackedScene = load("res://scenes/enemies/santelmo.tscn")
	var sant := sant_scene.instantiate() as SantelmoEnemy
	root.add_child(sant)
	await process_frame
	_assert_ok(sant.sprite is AnimatedSprite2D and sant.sprite.sprite_frames != null, "Santelmo usa AnimatedSprite2D")
	for anim_prefix in ["idle", "walk", "run", "attack1", "attack2", "hurt", "death"]:
		for d in ["down", "up", "left", "right"]:
			_assert_ok(sant.sprite.sprite_frames.has_animation("%s_%s" % [anim_prefix, d]),
				"Santelmo SpriteFrames contém %s_%s" % [anim_prefix, d])
	var before_children := root.get_child_count()
	sant._perform_ranged_orb_attack()
	_assert_ok(root.get_child_count() > before_children, "Santelmo attack2 instancia projétil orbe ígneo desviável")
	sant.queue_free()
	await process_frame

	var guard_scene: PackedScene = load("res://scenes/characters/aquatic_creature.tscn")
	var guard := guard_scene.instantiate() as AquaticCreature
	root.add_child(guard)
	await process_frame
	_assert_ok(guard.sprite is AnimatedSprite2D and guard.sprite.sprite_frames != null, "Guardiã usa AnimatedSprite2D")
	for anim_prefix in ["idle", "walk", "run", "attack1", "attack2", "hurt", "death"]:
		for d in ["down", "up", "left", "right"]:
			_assert_ok(guard.sprite.sprite_frames.has_animation("%s_%s" % [anim_prefix, d]),
				"Guardiã SpriteFrames contém %s_%s" % [anim_prefix, d])
	guard.queue_free()
	await process_frame
	print("[PASS] Pilar 3: Sant'Elmon & Guardiã humanoides 4 direções + Attack2 orbe validados.")

	# ------------------------------------------------------------------
	# PILAR 9: Modo Corrompido Surreal (Índigo s/ sangue + Enxame de Olhos)
	# ------------------------------------------------------------------
	print("--- Pilar 9: Modo Corrompido Surreal + Enxame de Olhos ---")
	var dist_pal: Dictionary = HuwagUiTheme.get_palette("distorted")
	var dist_border: Color = dist_pal["border"]
	_assert_ok(dist_border.b >= dist_border.r,
		"Borda do tema distorcido não deve puxar vermelho sangue (border=%s)" % str(dist_border))

	gs.reset_to_new_game()
	gs.set_var("Ato", 2)
	gs.set_corrupted_mode(true)
	var corr_main := main_scene.instantiate()
	root.add_child(corr_main)
	for _i in range(6):
		await process_frame
	var c_dbox := corr_main.get_node_or_null("CanvasLayer/DialogueBox") as DialogueBox
	if c_dbox and c_dbox.is_open():
		c_dbox.close_dialogue()
	await process_frame

	var edge_eyes := corr_main.get_node_or_null("CanvasLayer/ScreenEdgeEyeLayer") as CorruptedEyeSwarm
	_assert_ok(edge_eyes != null and edge_eyes.get_eye_count() >= 6 and edge_eyes.visible,
		"ScreenEdgeEyeLayer deve existir visível no Modo Corrompido com >= 6 olhos (atual=%d)" % (edge_eyes.get_eye_count() if edge_eyes else -1))

	var swarm_node: CorruptedEyeSwarm = null
	var lvl_cont := corr_main.get_node_or_null("LevelContainer")
	if lvl_cont and lvl_cont.get_child_count() > 0:
		swarm_node = lvl_cont.get_child(0).find_child("CorruptedEyeSwarm", true, false) as CorruptedEyeSwarm
	_assert_ok(swarm_node != null and swarm_node.get_eye_count() >= 6 and swarm_node.visible,
		"CorruptedEyeSwarm no cenário deve estar ativo e populado no Modo Corrompido")

	var c_player := get_first_node_in_group("player") as Node2D
	if c_player == null:
		c_player = corr_main.find_child("Player", true, false) as Node2D
	_assert_ok(c_player != null, "Player encontrado na cena corrompida")
	var sample_eye: WatchingEye = swarm_node.get_eyes()[0]
	c_player.global_position = sample_eye.global_position + Vector2(-90.0, 0.0)
	await process_frame
	var px_left := sample_eye.pupil_sprite.position.x
	c_player.global_position = sample_eye.global_position + Vector2(90.0, 0.0)
	await process_frame
	var px_right := sample_eye.pupil_sprite.position.x
	_assert_ok(px_left < 0.0 and px_right > 0.0,
		"Olhos do enxame devem rastrear player.global_position em tempo real (esq=%f, dir=%f)" % [px_left, px_right])

	corr_main.queue_free()
	await process_frame
	gs.set_corrupted_mode(false)
	print("[PASS] Pilar 9: Modo Corrompido surreal não-rubro + enxames rastreadores validados.")

	print("=== TODOS OS 9 PILARES PASSARAM COM SUCESSO! ===")
	quit(0)
