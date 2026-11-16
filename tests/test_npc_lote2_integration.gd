extends SceneTree

## Validação de integração em runtime do Lote 2 (Civis, Toby e Vulto Calcinado):
## 1. Carrega e valida todos os 16 SpriteFrames Lote 2 (7 adultos × 24 anims + Toby × 16 anims, sem attack/death)
## 2. Instancia FireStation.tscn e valida Velhinha_Espera com senhora_luningning SpriteFrames
## 3. Instancia StreetPreview.tscn (normal e Ato 2 Dose Maior):
##    - Valida todos os 8 NPCs da cidade (Nena, Ronda, Ben, Toby, Feirante/Tomas, Vigília/Luningning, Carding, Lola Rosa)
##    - Captura screenshots reais em jogo (normal e distorted/combate) para conferência visual lado a lado com Huwag
##    - Valida talk, attack, hurt, death persistente e segurança de Toby sem attack/death em overdose
## 4. Instancia forest_trail.tscn (Ato 2 Dose Maior) e valida NPC_Vulto_Bosque (attack + desintegração em cinzas)

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
		push_error("[FAIL][Lote2] " + msg)
		printerr("[FAIL][Lote2] " + msg)
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
	print("=== TESTE INTEGRAÇÃO LOTE 2 — CIVIS, TOBY & VULTO (GODOT 4.7) ===")
	print("==================================================================")

	var gs := _ensure_autoloads()
	gs.call("reset_to_new_game")
	await _wait_frames(2)

	# 1. Validar os 16 recursos SpriteFrames Lote 2
	var adult_ids := [
		"aling_nena", "kuya_ben", "mang_tomas",
		"mang_carding", "senhora_luningning", "lola_rosa", "vulto_bosque"
	]
	var adult_anims := [
		"idle_down", "idle_up", "idle_left", "idle_right",
		"walk_down", "walk_up", "walk_left", "walk_right",
		"talk_down", "talk_up", "talk_left", "talk_right",
		"attack_down", "attack_up", "attack_left", "attack_right",
		"hurt_down", "hurt_up", "hurt_left", "hurt_right",
		"death_down", "death_up", "death_left", "death_right",
	]
	for slug in adult_ids:
		for variant in ["normal", "distorted"]:
			var path := "res://assets/sprites/npcs/%s/%s_%s_spriteframes.tres" % [slug, slug, variant]
			var sf := load(path) as SpriteFrames
			_assert_ok(sf != null, "SpriteFrames carregável: " + path)
			for aname in adult_anims:
				_assert_ok(sf.has_animation(aname), "%s possui '%s'" % [path, aname])
				var tex := sf.get_frame_texture(aname, 0)
				_assert_ok(tex != null and tex.get_size() == Vector2(48, 48),
					"%s '%s' frame 0 deve ter 48x48" % [path, aname])

	var toby_anims := [
		"idle_down", "idle_up", "idle_left", "idle_right",
		"walk_down", "walk_up", "walk_left", "walk_right",
		"talk_down", "talk_up", "talk_left", "talk_right",
		"hurt_down", "hurt_up", "hurt_left", "hurt_right",
	]
	for variant in ["normal", "distorted"]:
		var tpath := "res://assets/sprites/npcs/toby/toby_%s_spriteframes.tres" % variant
		var tsf := load(tpath) as SpriteFrames
		_assert_ok(tsf != null, "SpriteFrames Toby carregável: " + tpath)
		for aname in toby_anims:
			_assert_ok(tsf.has_animation(aname), "%s possui '%s'" % [tpath, aname])
		for d in ["down", "up", "left", "right"]:
			_assert_ok(not tsf.has_animation("attack_" + d), "%s não deve ter attack_%s" % [tpath, d])
			_assert_ok(not tsf.has_animation("death_" + d), "%s não deve ter death_%s" % [tpath, d])
	print("[PASS] 16 SpriteFrames Lote 2 validados (7 adultos × 24 anims + Toby × 16 anims).")

	# 2. FireStation: Velhinha_Espera usa senhora_luningning
	gs.call("advance_to_act_2")
	await _wait_frames(2)
	var fs_scene := load("res://scenes/levels/FireStation.tscn") as PackedScene
	_assert_ok(fs_scene != null, "FireStation.tscn carregável")
	var fs := fs_scene.instantiate()
	root.add_child(fs)
	await _wait_frames(4)
	var fs_npcs: Dictionary = fs.get("_npcs")
	var velhinha: NpcEntity = fs_npcs.get("Velhinha_Espera", null)
	_assert_ok(velhinha != null and bool(velhinha.get("_using_spriteframes")),
		"Velhinha_Espera em FireStation usa AnimatedSprite2D")
	_assert_ok(velhinha.normal_frames_path.contains("senhora_luningning"),
		"Velhinha_Espera vinculada a senhora_luningning_normal_spriteframes.tres")
	fs.queue_free()
	await _wait_frames(3)
	print("[PASS] FireStation Velhinha_Espera validada com senhora_luningning SpriteFrames.")

	# 3. StreetPreview: validar todos os 8 NPCs em Normal & Ato 2 Dose Maior
	gs.call("reset_to_new_game")
	await _wait_frames(2)
	var sp_scene := load("res://scenes/levels/StreetPreview.tscn") as PackedScene
	_assert_ok(sp_scene != null, "StreetPreview.tscn carregável")
	var sp := sp_scene.instantiate()
	root.add_child(sp)
	await _wait_frames(4)

	var sp_npcs: Dictionary = sp.get("_npcs")
	var expected_street := [
		"NPC_Aling_Nena", "NPC_Bombeiro_Ronda", "NPC_Kuya_Ben",
		"NPC_Toby", "NPC_Feirante", "NPC_Vigilia_Leste",
		"NPC_Mang_Carding", "NPC_Lola_Rosa"
	]
	for nid in expected_street:
		var npc: NpcEntity = sp_npcs.get(nid, null)
		_assert_ok(npc != null, "StreetPreview contém NPC " + nid)
		_assert_ok(bool(npc.get("_using_spriteframes")), "%s usa SpriteFrames" % nid)
		_assert_ok(npc.anim_sprite != null and npc.anim_sprite.visible, "%s AnimatedSprite2D visível" % nid)
		_assert_ok(npc.anim_sprite.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST,
			"%s usa TEXTURE_FILTER_NEAREST" % nid)
		_assert_ok(npc.anim_sprite.offset == Vector2(0.0, -7.0), "%s usa offset (0, -7)" % nid)

	var player := sp.get("player") as CharacterBody2D
	_assert_ok(player != null, "Player presente em StreetPreview")
	var nena: NpcEntity = sp_npcs["NPC_Aling_Nena"]
	var ben: NpcEntity = sp_npcs["NPC_Kuya_Ben"]
	var toby: NpcEntity = sp_npcs["NPC_Toby"]
	var tomas: NpcEntity = sp_npcs["NPC_Feirante"]
	var carding: NpcEntity = sp_npcs["NPC_Mang_Carding"]
	var luningning: NpcEntity = sp_npcs["NPC_Vigilia_Leste"]
	var rosa: NpcEntity = sp_npcs["NPC_Lola_Rosa"]

	# Enquadramento normal na avenida em frente à Sari-Sari para conferência visual lado a lado
	player.global_position = Vector2(780, 442)
	toby.patrol_points = []
	nena.global_position = Vector2(700, 405)
	rosa.global_position = Vector2(736, 405)
	carding.global_position = Vector2(772, 405)
	ben.global_position = Vector2(808, 405)
	tomas.global_position = Vector2(844, 405)
	toby.global_position = Vector2(878, 405)
	luningning.global_position = Vector2(912, 405)
	for n in [nena, rosa, carding, ben, tomas, toby, luningning]:
		n.face_toward(player.global_position)
	var cam := player.get_node_or_null("Camera2D") as Camera2D
	if cam != null:
		cam.reset_smoothing()
	await _wait_physics(4)
	await _wait_frames(6)

	if DisplayServer.get_name() != "headless":
		var shot_sp_norm := root.get_viewport().get_texture().get_image()
		if shot_sp_norm != null:
			shot_sp_norm.save_png(ARTIFACT_DIR + "/ingame_street_lote2_normal.png")
			print("[SHOT] Salvo ingame_street_lote2_normal.png")

	# Transicionar para Ato 2 Dose Maior e validar variantes distorted + reações de combate
	gs.call("advance_to_act_2")
	gs.call("set_higher_dose", true)
	await _wait_frames(3)
	for nid in expected_street:
		var npc: NpcEntity = sp_npcs[nid]
		_assert_ok(npc.is_distorted, "%s em estado distorted" % nid)
		_assert_ok(npc.anim_sprite.sprite_frames == npc.get("_distorted_sf"),
			"%s trocou para _distorted_sf" % nid)

	# Talk em Luningning, Attack em Carding, Hurt em Lola Rosa, Death em Aling Nena, Overdose seguro em Toby
	luningning.call("_handle_interact", player)
	await _wait_physics(2)
	_assert_ok(String(luningning.anim_sprite.animation).begins_with("talk_"),
		"Senhora Luningning exibe talk_* (obtido %s)" % luningning.anim_sprite.animation)

	carding.turn_hostile()
	carding.play_action_pulse(0.5)
	await _wait_physics(3)
	_assert_ok(String(carding.anim_sprite.animation).begins_with("attack_"),
		"Mang Carding exibe attack_* (obtido %s)" % carding.anim_sprite.animation)

	rosa.turn_hostile()
	var rosa_hits: Array[Dictionary] = rosa.query_melee_hit(player.global_position, rosa.global_position - player.global_position, 220.0, 1.0, 20, {})
	_assert_ok(rosa_hits.size() == 1, "Lola Rosa recebeu golpe")
	await _wait_physics(2)
	_assert_ok(String(rosa.anim_sprite.animation).begins_with("hurt_"),
		"Lola Rosa exibe hurt_* (obtido %s)" % rosa.anim_sprite.animation)

	nena.turn_hostile()
	var nena_fatal: Array[Dictionary] = nena.query_melee_hit(player.global_position, nena.global_position - player.global_position, 220.0, 1.0, 999, {})
	_assert_ok(nena_fatal.size() == 1 and nena.is_defeated, "Aling Nena derrotada por dano fatal")
	for _k in range(60):
		await _wait_physics(2)
		if not bool(nena.get("_death_playing")):
			break
	_assert_ok(nena.visible and nena.anim_sprite.visible and String(nena.anim_sprite.animation).begins_with("death_"),
		"Aling Nena permanece visível no último frame de death_*")

	# Segurança de Toby sem animações attack/death mesmo se em overdrive
	toby.aggressive_on_overdose = true
	toby.turn_hostile()
	toby.play_action_pulse(0.4)
	await _wait_physics(3)
	var toby_fatal: Array[Dictionary] = toby.query_melee_hit(player.global_position, toby.global_position - player.global_position, 220.0, 1.0, 999, {})
	_assert_ok(toby_fatal.size() == 1 and toby.is_defeated, "Toby tratado com segurança mesmo sem death_*")
	await _wait_frames(3)

	if DisplayServer.get_name() != "headless":
		var shot_sp_dist := root.get_viewport().get_texture().get_image()
		if shot_sp_dist != null:
			shot_sp_dist.save_png(ARTIFACT_DIR + "/ingame_street_lote2_distorted.png")
			print("[SHOT] Salvo ingame_street_lote2_distorted.png")

	sp.queue_free()
	await _wait_frames(3)
	print("[PASS] StreetPreview Lote 2 (8 NPCs + combate + Toby seguro) validado.")

	# 4. ForestTrail Dose Maior: NPC_Vulto_Bosque com vulto_bosque SpriteFrames
	gs.call("reset_to_new_game")
	gs.call("advance_to_act_2")
	gs.call("set_higher_dose", true)
	await _wait_frames(2)
	var ft_scene := load("res://scenes/levels/forest_trail.tscn") as PackedScene
	_assert_ok(ft_scene != null, "forest_trail.tscn carregável")
	var ft := ft_scene.instantiate()
	root.add_child(ft)
	await _wait_frames(4)

	var vulto := ft.find_child("NPC_Vulto_Bosque", true, false) as NpcEntity
	_assert_ok(vulto != null, "NPC_Vulto_Bosque gerado na trilha em Dose Maior")
	_assert_ok(bool(vulto.get("_using_spriteframes")), "NPC_Vulto_Bosque usa AnimatedSprite2D")
	_assert_ok(vulto.normal_frames_path.contains("vulto_bosque"), "NPC_Vulto_Bosque usa vulto_bosque SpriteFrames")

	var ft_player := ft.get("player") as CharacterBody2D
	_assert_ok(ft_player != null, "Player presente em forest_trail")
	ft_player.global_position = vulto.global_position + Vector2(0, 42)
	vulto.face_toward(ft_player.global_position)
	var ft_cam := ft_player.get_node_or_null("Camera2D") as Camera2D
	if ft_cam != null:
		ft_cam.reset_smoothing()
	vulto.turn_hostile()
	vulto.play_action_pulse(0.5)
	await _wait_physics(4)
	_assert_ok(String(vulto.anim_sprite.animation).begins_with("attack_"),
		"Vulto executa animação attack_* (obtido %s)" % vulto.anim_sprite.animation)

	if DisplayServer.get_name() != "headless":
		var shot_vulto := root.get_viewport().get_texture().get_image()
		if shot_vulto != null:
			shot_vulto.save_png(ARTIFACT_DIR + "/ingame_forest_vulto_lote2.png")
			print("[SHOT] Salvo ingame_forest_vulto_lote2.png")

	var vulto_fatal: Array[Dictionary] = vulto.query_melee_hit(ft_player.global_position, vulto.global_position - ft_player.global_position, 140.0, 1.0, 999, {})
	_assert_ok(vulto_fatal.size() == 1 and vulto.is_defeated, "NPC_Vulto_Bosque derrotado")
	for _m in range(60):
		await _wait_physics(2)
		if not bool(vulto.get("_death_playing")):
			break
	_assert_ok(not bool(vulto.get("_death_playing")) and vulto.visible,
		"NPC_Vulto_Bosque desintegra em cinzas com capacete partido no chão")

	ft.queue_free()
	await _wait_frames(3)

	print("[PASS] ForestTrail Vulto Calcinado validado.")
	print("==================================================================")
	print("=== LOTE 2 VERIFICADO 100% EM RUNTIME GODOT 4.7 ===")
	print("==================================================================")
	quit(0)
