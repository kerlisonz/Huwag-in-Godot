extends SceneTree

## Validação de integração em runtime do Lote 1 (Núcleo BFP) em FireStation e StreetPreview:
## 1. Carrega e valida todos os SpriteFrames normal e distorted dos 4 NPCs BFP (24 animações cada)
## 2. Instancia FireStation.tscn: valida Cap_Reyes, Bombeiro_Ato, Bombeiro_Santos e Enfermeira_Maria em AnimatedSprite2D
##    e compatibilidade legada para Velhinha_Espera (Lote 2)
## 3. Testa talk, distorção dinâmica (Intoxicacao=2), turn_hostile, attack, hurt e death persistente (frame final)
## 4. Instancia StreetPreview.tscn e valida NPC_Bombeiro_Ronda com bombero_santos SpriteFrames
## 5. Salva capturas reais de jogo em FireStation para conferência visual lado a lado com Huwag

const ARTIFACT_DIR := "C:/Users/SnyX/.gemini/antigravity/brain/6f04634a-b7d4-4d6f-9c20-24b6fdf404a0"


func _init() -> void:
	call_deferred("_run_all")


func _wait_frames(n: int) -> void:
	for _i in range(n):
		await process_frame


func _wait_physics(n: int) -> void:
	for _i in range(n):
		await physics_frame


func _assert_ok(cond: bool, msg: String) -> void:
	if not cond:
		push_error("[FAIL][Lote1] " + msg)
		printerr("[FAIL][Lote1] " + msg)
		quit(1)


func _ensure_autoloads() -> Node:
	if not root.has_node("AudioManager"):
		var am := Node.new()
		am.set_script(load("res://scripts/autoload/audio_manager.gd"))
		am.name = "AudioManager"
		root.add_child(am)
	if not root.has_node("GameState"):
		var gs := Node.new()
		gs.set_script(load("res://scripts/autoload/game_state.gd"))
		gs.name = "GameState"
		root.add_child(gs)
	return root.get_node("GameState")


func _run_all() -> void:
	print("==================================================================")
	print("=== TESTE INTEGRAÇÃO LOTE 1 — NÚCLEO BFP (ANIMATEDSPRITE2D) ===")
	print("==================================================================")

	var gs := _ensure_autoloads()
	gs.call("reset_to_new_game")
	await _wait_frames(2)

	# 1. Validar recursos SpriteFrames (4 NPCs × 2 variantes × 24 animações)
	var ids := ["cap_reyes", "bombeiro_ato", "bombeiro_santos", "enfermeira_maria"]
	var expected_anims := [
		"idle_down", "idle_up", "idle_left", "idle_right",
		"walk_down", "walk_up", "walk_left", "walk_right",
		"talk_down", "talk_up", "talk_left", "talk_right",
		"attack_down", "attack_up", "attack_left", "attack_right",
		"hurt_down", "hurt_up", "hurt_left", "hurt_right",
		"death_down", "death_up", "death_left", "death_right",
	]
	for npc_slug in ids:
		for variant in ["normal", "distorted"]:
			var tres_path := "res://assets/sprites/npcs/%s/%s_%s_spriteframes.tres" % [npc_slug, npc_slug, variant]
			var sf := load(tres_path) as SpriteFrames
			_assert_ok(sf != null, "SpriteFrames carregável: " + tres_path)
			for aname in expected_anims:
				_assert_ok(sf.has_animation(aname), "%s possui animação '%s'" % [tres_path, aname])
				var fc := sf.get_frame_count(aname)
				_assert_ok(fc >= 3, "%s '%s' tem frames >= 3 (obtido %d)" % [tres_path, aname, fc])
				var tex := sf.get_frame_texture(aname, 0)
				_assert_ok(tex != null and tex.get_size() == Vector2(48, 48),
					"%s '%s' frame 0 deve ter 48x48" % [tres_path, aname])
	print("[PASS] Todos os 8 SpriteFrames Lote 1 (192 animações no total) válidos e importados.")

	# 2. Instanciar FireStation.tscn (Ato 1 normal)
	var fs_scene := load("res://scenes/levels/FireStation.tscn") as PackedScene
	_assert_ok(fs_scene != null, "FireStation.tscn carregável")
	var fs := fs_scene.instantiate()
	root.add_child(fs)
	await _wait_frames(4)

	var npcs_dict: Dictionary = fs.get("_npcs")
	var bfp_ids := ["Cap_Reyes", "Bombeiro_Ato", "Bombeiro_Santos", "Enfermeira_Maria"]
	for nid in bfp_ids:
		var npc: NpcEntity = npcs_dict.get(nid, null)
		_assert_ok(npc != null, "NPC %s presente no Quartel BFP" % nid)
		_assert_ok(npc.anim_sprite != null and npc.anim_sprite.visible, "%s usa AnimatedSprite2D visível" % nid)
		_assert_ok(npc.sprite != null and not npc.sprite.visible, "%s oculta Sprite2D legado" % nid)
		_assert_ok(npc.anim_sprite.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST,
			"%s usa TEXTURE_FILTER_NEAREST" % nid)
		_assert_ok(npc.anim_sprite.offset == Vector2(0.0, -7.0), "%s usa offset (0, -7)" % nid)
		var cur_anim := String(npc.anim_sprite.animation)
		_assert_ok(cur_anim.begins_with("idle_") or cur_anim.begins_with("walk_"),
			"%s inicia em idle/walk (obtido '%s')" % [nid, cur_anim])

	# Verificar que Velhinha_Espera também já utiliza SpriteFrames Lote 2 (senhora_luningning)
	var velhinha: NpcEntity = npcs_dict.get("Velhinha_Espera", null)
	if velhinha != null:
		_assert_ok(bool(velhinha.get("_using_spriteframes")) and velhinha.normal_frames_path.contains("senhora_luningning"),
			"Velhinha_Espera usa SpriteFrames Lote 2 (senhora_luningning)")

	# Captura real em jogo no Quartel BFP com Huwag próximo ao Capitão Reyes e equipe
	var fs_player := fs.get("player") as CharacterBody2D
	_assert_ok(fs_player != null, "Player presente em FireStation")
	var reyes: NpcEntity = npcs_dict["Cap_Reyes"]
	var ato: NpcEntity = npcs_dict["Bombeiro_Ato"]
	var santos: NpcEntity = npcs_dict["Bombeiro_Santos"]
	var maria: NpcEntity = npcs_dict["Enfermeira_Maria"]

	# Posiciona brevemente o elenco BFP ao redor da área central para foto comparativa real 1:1 com Huwag
	fs_player.global_position = Vector2(480, 305)
	ato.patrol_points = []
	ato.global_position = Vector2(422, 268)
	reyes.global_position = Vector2(462, 268)
	santos.global_position = Vector2(502, 268)
	maria.global_position = Vector2(542, 268)
	reyes.face_toward(fs_player.global_position)
	ato.face_toward(fs_player.global_position)
	santos.face_toward(fs_player.global_position)
	maria.face_toward(fs_player.global_position)
	var cam := fs_player.get_node_or_null("Camera2D") as Camera2D
	if cam != null:
		cam.reset_smoothing()
	await _wait_physics(4)
	await _wait_frames(6)

	if DisplayServer.get_name() != "headless":
		var shot_norm := root.get_viewport().get_texture().get_image()
		if shot_norm != null:
			shot_norm.save_png(ARTIFACT_DIR + "/ingame_fire_station_lote1_normal.png")
			print("[SHOT] Salvo ingame_fire_station_lote1_normal.png")

	# 3. Testar Talk, Distorção (Ato 2 Dose Maior), Hostile Attack, Hurt e Death persistente!
	gs.call("advance_to_act_2")
	gs.call("set_higher_dose", true)
	await _wait_frames(3)
	for nid in bfp_ids:
		var npc: NpcEntity = npcs_dict[nid]
		_assert_ok(npc.is_distorted, "%s entrou em estado distorted no Ato 2 Dose Maior" % nid)
		_assert_ok(npc.anim_sprite.sprite_frames == npc.get("_distorted_sf"),
			"%s trocou SpriteFrames para variante distorted" % nid)

	# Testar talk em Santos antes de combate
	santos.call("_handle_interact", fs_player)
	await _wait_physics(2)
	_assert_ok(String(santos.anim_sprite.animation).begins_with("talk_"),
		"Santos exibe animação talk_* ao interagir (obtido %s)" % santos.anim_sprite.animation)

	# Combate real: Ato ataca, Maria recebe dano (hurt), Reyes sofre golpe fatal e cai (death)
	ato.turn_hostile()
	maria.turn_hostile()
	reyes.turn_hostile()
	await _wait_frames(2)
	ato.play_action_pulse(0.5)
	await _wait_physics(3)
	_assert_ok(String(ato.anim_sprite.animation).begins_with("attack_"),
		"Ato exibe animação attack_* (obtido %s)" % ato.anim_sprite.animation)

	var maria_hits: Array[Dictionary] = maria.query_melee_hit(fs_player.global_position, maria.global_position - fs_player.global_position, 140.0, 1.0, 25, {})
	_assert_ok(maria_hits.size() == 1, "Maria recebeu query_melee_hit corretamente")
	await _wait_physics(2)
	_assert_ok(String(maria.anim_sprite.animation).begins_with("hurt_"),
		"Maria exibe animação hurt_* ao receber dano (obtido %s)" % maria.anim_sprite.animation)

	# Golpe fatal em Reyes -> death_* + permanece visível no último frame
	var reyes_fatal: Array[Dictionary] = reyes.query_melee_hit(fs_player.global_position, reyes.global_position - fs_player.global_position, 140.0, 1.0, 999, {})
	_assert_ok(reyes_fatal.size() == 1 and reyes.is_defeated, "Cap_Reyes derrotado por dano fatal")
	_assert_ok(String(reyes.anim_sprite.animation).begins_with("death_"),
		"Cap_Reyes iniciou animação death_* (obtido %s)" % reyes.anim_sprite.animation)
	for _k in range(60):
		await _wait_physics(2)
		if not bool(reyes.get("_death_playing")):
			break
	_assert_ok(not bool(reyes.get("_death_playing")), "Animação de morte de Cap_Reyes concluiu")
	_assert_ok(reyes.visible and reyes.anim_sprite.visible, "Corpo caído de Cap_Reyes permanece visível no último frame")
	_assert_ok(reyes.anim_sprite.frame == reyes.anim_sprite.sprite_frames.get_frame_count(reyes.anim_sprite.animation) - 1,
		"Cap_Reyes parado exatamente no último frame de death_* (frame=%d)" % reyes.anim_sprite.frame)

	if DisplayServer.get_name() != "headless":
		var shot_comb := root.get_viewport().get_texture().get_image()
		if shot_comb != null:
			shot_comb.save_png(ARTIFACT_DIR + "/ingame_fire_station_lote1_combat.png")
			print("[SHOT] Salvo ingame_fire_station_lote1_combat.png")

	# Limpar FireStation
	fs.queue_free()
	await _wait_frames(3)

	# 4. Instanciar StreetPreview.tscn e validar NPC_Bombeiro_Ronda
	gs.call("reset_to_new_game")
	await _wait_frames(2)
	var sp_scene := load("res://scenes/levels/StreetPreview.tscn") as PackedScene
	_assert_ok(sp_scene != null, "StreetPreview.tscn carregável")
	var sp := sp_scene.instantiate()
	root.add_child(sp)
	await _wait_frames(4)
	var sp_npcs: Dictionary = sp.get("_npcs")
	var ronda: NpcEntity = sp_npcs.get("NPC_Bombeiro_Ronda", null)
	_assert_ok(ronda != null and bool(ronda.get("_using_spriteframes")),
		"NPC_Bombeiro_Ronda em StreetPreview usa SpriteFrames Lote 1")
	_assert_ok(ronda.anim_sprite.visible and ronda.normal_frames_path.contains("bombeiro_santos"),
		"NPC_Bombeiro_Ronda vinculado a bombeiro_santos_normal_spriteframes.tres")
	sp.queue_free()
	await _wait_frames(3)

	print("[PASS] Fluxo completo Lote 1 em FireStation & StreetPreview verificado!")
	print("==================================================================")
	print("=== LOTE 1 VERIFICADO 100% EM RUNTIME GODOT 4.7 ===")
	print("==================================================================")
	quit(0)
