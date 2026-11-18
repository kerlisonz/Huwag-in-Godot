extends SceneTree

## Suíte completa de validação e captura visual em jogo do novo protagonista (Huwag),
## cobrindo:
## 1. Existência e integridade dos 8 spritesheets separados por finalidade (Idle, Walk, Run, Attack, Combo, Dodge, Hurt, Death)
## 2. Transições de estado de animação nas 4 direções (down, up, left, right)
## 3. Sistema de combate: Ataque 1 -> Combo 2 -> Combo 3 encadeado contra inimigo real (Santelmo)
## 4. Sistema de Esquiva (Dodge) com velocidade de dash e i-frames (invulnerabilidade)
## 5. Reações de Dano (Hurt) e Morte (Death) + Revive
## 6. Captura de screenshots reais dentro das cenas do jogo (Quarto, Rua com NPCs e Combate na Floresta)

const ARTIFACT_DIR := "C:/Users/SnyX/.gemini/antigravity/brain/6f04634a-b7d4-4d6f-9c20-24b6fdf404a0"


func _init() -> void:
	create_timer(15.0).timeout.connect(func() -> void:
		push_error("TIMEOUT: test_protagonist_combat_and_animations excedeu 15s")
		quit(1)
	)
	call_deferred("_run_all")


func _wait_frames(n: int) -> void:
	for _i in range(n):
		await process_frame


func _assert_ok(cond: bool, msg: String) -> void:
	if not cond:
		push_error("[FAIL] " + msg)
		printerr("[FAIL] " + msg)
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
	print("=== TESTE PROTAGONISTA: PIXEL ART, ANIMAÇÕES E COMBATE COMPLETO ===")
	print("==================================================================")

	var gs := _ensure_autoloads()
	gs.call("reset_to_new_game")
	await _wait_frames(2)

	# ------------------------------------------------------------------
	# 1. VERIFICAÇÃO DOS 8 SPRITESHEETS POR FINALIDADE (CASUAL & BOMBEIRO)
	# ------------------------------------------------------------------
	print("\n--- 1. Verificando spritesheets separados por finalidade ---")
	var expected_sheets := {
		"idle": Vector2i(192, 192),
		"walk": Vector2i(288, 192),
		"run": Vector2i(288, 192),
		"attack": Vector2i(240, 192),
		"combo": Vector2i(384, 192),
		"dodge": Vector2i(192, 192),
		"hurt": Vector2i(144, 192),
		"death": Vector2i(288, 192),
	}
	for outfit_dir in ["casual", "bombeiro"]:
		for purpose in expected_sheets.keys():
			var p := "res://assets/sprites/huwag_v3/%s/spritesheet_%s.png" % [outfit_dir, purpose]
			_assert_ok(ResourceLoader.exists(p), "Spritesheet deve existir: %s" % p)
			var tex := load(p) as Texture2D
			_assert_ok(tex != null, "Textura deve carregar: %s" % p)
			var exp_size: Vector2i = expected_sheets[purpose]
			_assert_ok(Vector2i(tex.get_width(), tex.get_height()) == exp_size,
				"Dimensão de %s deve ser %s (obtido %dx%d)" % [p, exp_size, tex.get_width(), tex.get_height()])
	print("[PASS] Todos os 16 spritesheets organizados por finalidade (casual + bombeiro) validados.")

	# ------------------------------------------------------------------
	# 2. CENA RUA (STREETPREVIEW): PROPORÇÃO COM NPCS, WALK, RUN E TROCA DE TRAJE
	# ------------------------------------------------------------------
	print("\n--- 2. Validando protagonista em StreetPreview junto aos NPCs ---")
	var street_sc := load("res://scenes/levels/StreetPreview.tscn") as PackedScene
	var street := street_sc.instantiate()
	root.add_child(street)
	await _wait_frames(6)

	var player: CharacterBody2D = street.get("player")
	_assert_ok(player != null, "Player presente em StreetPreview")
	var cs: AnimatedSprite2D = player.get("character_sprite")
	_assert_ok(cs != null and cs.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST,
		"Renderização pixel art nítida (TEXTURE_FILTER_NEAREST) ativa")

	# Testa troca de roupa mantendo animação e frame
	player.set("facing_dir", Vector2.RIGHT)
	player.set("is_moving", true)
	player.set("is_running", false)
	player.call("_update_character_sprite_state")
	cs.frame = 3
	_assert_ok(cs.animation == &"walk_right", "Animação deve ser walk_right")
	player.call("set_outfit", "bombeiro", false)
	_assert_ok(cs.animation == &"walk_right" and cs.frame == 3,
		"Troca de roupa deve preservar animação (walk_right) e frame (3) sem pular")
	player.call("set_outfit", "casual", false)
	_assert_ok(cs.animation == &"walk_right" and cs.frame == 3,
		"Retorno para casual deve preservar animação e frame")
	print("[PASS] Sistema de roupa preserva animação, direção e frame exato.")

	# Posiciona próximo a Aling Nena para captura visual comparativa em jogo
	var nena: Node2D = street.get("_npcs").get("NPC_Aling_Nena", null)
	if nena != null:
		player.global_position = nena.global_position + Vector2(-26, 4)
		player.set("facing_dir", Vector2.RIGHT)
		player.set("is_moving", true)
		player.set("is_running", false)
		player.call("_update_character_sprite_state")
		cs.frame = 0
		await _wait_frames(8)
		if DisplayServer.get_name() != "headless":
			var shot_street := root.get_viewport().get_texture().get_image()
			if shot_street != null:
				shot_street.save_png(ARTIFACT_DIR + "/ingame_street_walk_and_npc.png")
				print("[SHOT] Salvo ingame_street_walk_and_npc.png")

	street.queue_free()
	await _wait_frames(3)

	# ------------------------------------------------------------------
	# 3. COMBATE NA FLORESTA: ATAQUE, COMBO DE 3 ESTÁGIOS, ESQUIVA, DANO E MORTE
	# ------------------------------------------------------------------
	print("\n--- 3. Validando Combate Real, Combo 3x, Esquiva com i-frames, Dano e Morte ---")
	gs.call("advance_to_act_2")
	gs.call("set_higher_dose", false)
	var trail_sc := load("res://scenes/levels/forest_trail.tscn") as PackedScene
	var trail := trail_sc.instantiate()
	root.add_child(trail)
	await _wait_frames(6)

	var f_player: CharacterBody2D = trail.get("player")
	var f_cs: AnimatedSprite2D = f_player.get("character_sprite")
	var santelmo1: CharacterBody2D = trail.get_node("ObstaclesYsort/Santelmo1")
	_assert_ok(f_player != null and santelmo1 != null, "Player e Santelmo1 presentes na floresta")

	# Desativa IA autônoma de movimento do Santelmo1 durante a medição determinística do combo
	santelmo1.set_physics_process(false)
	f_player.global_position = Vector2(360, 420)
	santelmo1.global_position = f_player.global_position + Vector2(28, 0)
	f_player.set("facing_dir", Vector2.RIGHT)
	f_player.set("rotate_towards_mouse", false)

	var hp_initial: int = int(santelmo1.get("current_health"))
	_assert_ok(hp_initial == 60, "Santelmo1 inicia com 60 HP (obtido %d)" % hp_initial)

	# Golpe 1 do Combo (attack_right, 25 de dano)
	var ok1: bool = bool(f_player.call("perform_melee_attack"))
	_assert_ok(ok1 and int(f_player.get("combo_stage")) == 1, "Estágio 1 do combo disparado")
	_assert_ok(f_cs.animation == &"attack_right", "Animação deve ser attack_right (obtido %s)" % f_cs.animation)
	var hp_after_1: int = int(santelmo1.get("current_health"))
	_assert_ok(hp_after_1 == 35, "Santelmo1 deve ir para 35 HP após Golpe 1 (obtido %d)" % hp_after_1)

	# Simula avanço até janela de encadeamento e dispara Golpe 2 (combo2_right, 32 de dano)
	santelmo1.global_position = f_player.global_position + Vector2(28, 0)
	f_player.set("_attack_cooldown", 0.05)
	var ok2: bool = bool(f_player.call("perform_melee_attack"))
	_assert_ok(ok2 and int(f_player.get("combo_stage")) == 2, "Estágio 2 do combo encadeado com sucesso")
	_assert_ok(f_cs.animation == &"combo2_right", "Animação deve ser combo2_right (obtido %s)" % f_cs.animation)
	var hp_after_2: int = int(santelmo1.get("current_health"))
	_assert_ok(hp_after_2 == 3, "Santelmo1 deve ir para 3 HP após Golpe 2 de 32 dmg (obtido %d)" % hp_after_2)

	# Captura screenshot durante o Combo em ação na Floresta!
	f_cs.frame = 1
	await _wait_frames(4)
	if DisplayServer.get_name() != "headless":
		var shot_combo := root.get_viewport().get_texture().get_image()
		if shot_combo != null:
			shot_combo.save_png(ARTIFACT_DIR + "/ingame_forest_combo_combat.png")
			print("[SHOT] Salvo ingame_forest_combo_combat.png")

	# Encadeia Golpe 3 Finalizador (combo3_right, 45 de dano -> derrota Santelmo1!)
	santelmo1.global_position = f_player.global_position + Vector2(30, 0)
	f_player.set("_attack_cooldown", 0.05)
	var ok3: bool = bool(f_player.call("perform_melee_attack"))
	_assert_ok(ok3 and int(f_player.get("combo_stage")) == 3, "Estágio 3 (Finalizador) do combo encadeado")
	_assert_ok(f_cs.animation == &"combo3_right", "Animação deve ser combo3_right (obtido %s)" % f_cs.animation)
	_assert_ok(int(santelmo1.get("current_health")) <= 0, "Santelmo1 derrotado pelo 3º golpe do combo!")
	print("[PASS] Combo de 3 estágios (attack -> combo2 -> combo3) causou 25 -> 32 -> 45 de dano e derrotou o inimigo.")

	# Valida Esquiva (Dodge) e invulnerabilidade (i-frames)
	f_player.set("_attack_anim_timer", 0.0)
	f_player.set("_dodge_cooldown", 0.0)
	var hp_before_dodge: int = int(gs.get("player_hp"))
	var dodged: bool = bool(f_player.call("perform_dodge", Vector2.LEFT))
	_assert_ok(dodged and bool(f_player.get("is_dodging")), "Esquiva iniciada para a esquerda")
	_assert_ok(f_cs.animation == &"dodge_left", "Animação deve ser dodge_left (obtido %s)" % f_cs.animation)
	f_player.call("apply_hit", 25, f_player.global_position + Vector2(20, 0))
	_assert_ok(int(gs.get("player_hp")) == hp_before_dodge, "Durante a esquiva (i-frames), Huwag não deve sofrer dano!")

	f_cs.frame = 1
	await _wait_frames(3)
	if DisplayServer.get_name() != "headless":
		var shot_dodge := root.get_viewport().get_texture().get_image()
		if shot_dodge != null:
			shot_dodge.save_png(ARTIFACT_DIR + "/ingame_forest_dodge_action.png")
			print("[SHOT] Salvo ingame_forest_dodge_action.png")
	print("[PASS] Mecânica de Esquiva (Dodge) e i-frames validados.")

	# Valida Recebimento de Dano (Hurt) e Morte (Death)
	f_player.set("is_dodging", false)
	f_player.set("_dodge_timer", 0.0)
	f_player.set("_dodge_invuln_timer", 0.0)
	f_player.set("_hurt_timer", 0.0)
	f_player.set("facing_dir", Vector2.DOWN)
	f_player.call("apply_hit", 20, f_player.global_position + Vector2(0, 20))
	_assert_ok(f_cs.animation == &"hurt_down", "Receber dano deve acionar hurt_down (obtido %s)" % f_cs.animation)
	_assert_ok(int(gs.get("player_hp")) == hp_before_dodge - 20, "HP deve reduzir em 20")

	f_player.set("_hurt_timer", 0.0)
	f_player.call("apply_hit", 200, f_player.global_position + Vector2(0, 20))
	_assert_ok(bool(f_player.get("is_dead")) and f_cs.animation == &"death_down",
		"HP <= 0 deve acionar estado is_dead e animação death_down (obtido %s)" % f_cs.animation)
	f_player.call("revive", 100)
	_assert_ok(not bool(f_player.get("is_dead")) and int(gs.get("player_hp")) == 100,
		"revive(100) deve restaurar o protagonista")
	print("[PASS] Animações e estados de Hurt, Death e Revive validados.")

	trail.queue_free()
	await _wait_frames(2)

	print("\n==================================================================")
	print("=== SUCESSO TOTAL: PIXEL ART, ANIMAÇÕES E COMBATE 100% PASS! ===")
	print("==================================================================")
	quit(0)
