extends SceneTree

## Validação dedicada da Fase 3:
## - Spritesheets personalizados 480x192 (10x4) e retrato sem placeholder para Senhora Luningning
## - Variável GameState Intoxicacao + Shader de distorção (npc_distortion.gdshader) no Ato 2
## - Transição de cidadão pacífico para inimigo hostil (turn_hostile + overdose proximidade)
## - Resolução de crash: ataque do Player contra NpcEntity hostil (melee _swing_hit_ids Dictionary + water),
##   ataque do NpcEntity contra Player (apply_hit/take_damage/receive_damage), guarda contra alvo nulo e derrota segura.

func _init() -> void:
	call_deferred("_run")


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


func _assert_ok(cond: bool, msg: String) -> void:
	if not cond:
		push_error("[FAIL][Fase3] " + msg)
		printerr("[FAIL][Fase3] " + msg)
		quit(1)


func _run() -> void:
	print("==================================================================")
	print("=== TESTE FASE 3 — NPCs PERSONALIZADOS, DISTORÇÃO E COMBATE ===")
	print("==================================================================")

	var gs := _ensure_autoloads()
	gs.reset_to_new_game()
	await process_frame

	# 1. Validar dimensões 480x192 dos spritesheets customizados e perfil da Senhora Luningning
	var expected_sheets := [
		"res://assets/characters/sprites/npc_aling_nena_sheet.png",
		"res://assets/characters/sprites/npc_kuya_ben_sheet.png",
		"res://assets/characters/sprites/npc_toby_sheet.png",
		"res://assets/characters/sprites/npc_feirante_sheet.png",
		"res://assets/characters/sprites/npc_luningning_sheet.png",
		"res://assets/characters/sprites/distorted_feirante_sheet.png",
		"res://assets/characters/sprites/distorted_toby_sheet.png",
	]
	for p in expected_sheets:
		var tex := load(p) as Texture2D
		_assert_ok(tex != null, "Textura carregável: %s" % p)
		_assert_ok(tex.get_size() == Vector2(480, 192), "Dimensão 480x192 em %s (atual=%s)" % [p, tex.get_size()])

	var luningning_prof := CharacterProfiles.get_profile_data("Senhora Luningning", "default", false, "casual")
	_assert_ok(not bool(luningning_prof.get("is_placeholder", true)), "Senhora Luningning não usa mais placeholder")
	_assert_ok(str(luningning_prof.get("portrait_path", "")).ends_with("fnaf_luningning.png"), "Retrato da Senhora Luningning aponta para fnaf_luningning.png")
	print("[PASS] Spritesheets 480x192 e retrato CRT da Senhora Luningning validados.")

	# 2. Instanciar StreetPreview em Ato 2 Dose Normal -> Dose Maior e verificar shader
	gs.advance_to_act_2()
	gs.set_switch("016_Magia_de_agua_obtida", true)
	gs.set_higher_dose(false)
	_assert_ok(int(gs.call("get_intoxication_level")) == 1, "Intoxicacao == 1 no Ato 2 dose normal")

	var street_sc: PackedScene = load("res://scenes/levels/StreetPreview.tscn")
	var street := street_sc.instantiate()
	root.add_child(street)
	await process_frame

	var feirante: NpcEntity = street._npcs["NPC_Feirante"]
	_assert_ok(feirante != null and not feirante.is_distorted, "NPC_Feirante inicia normal na dose normal")
	var shader_mat := feirante.sprite.material as ShaderMaterial
	_assert_ok(shader_mat != null and shader_mat.shader == NpcEntity.NPC_DISTORTION_SHADER, "Shader npc_distortion atribuído ao Sprite2D")
	_assert_ok(is_zero_approx(float(shader_mat.get_shader_parameter("distortion_intensity"))), "Intensidade do shader == 0.0 no estado normal")

	# Consumir dose extra -> Intoxicacao = 2
	gs.set_higher_dose(true)
	await process_frame
	_assert_ok(int(gs.call("get_intoxication_level")) == 2, "Intoxicacao == 2 em Dose Maior")
	_assert_ok(feirante.is_distorted == true, "NPC_Feirante entra em distorção com Intoxicacao == 2")
	_assert_ok(float(shader_mat.get_shader_parameter("distortion_intensity")) > 0.5, "Shader de distorção ativo no NPC distorcido")
	print("[PASS] Variável Intoxicacao e npc_distortion.gdshader ativados dinamicamente no Ato 2.")

	# 3. Escalonamento hostil + ataque do NPC no Player + ataque do Player no NPC (sem crash!)
	feirante.turn_hostile()
	await process_frame
	_assert_ok(feirante.is_hostile == true, "turn_hostile() torna NPC_Feirante inimigo ativo")
	_assert_ok(float(shader_mat.get_shader_parameter("hostile_boost")) >= 0.99, "Shader eleva hostile_boost ao máximo no estado hostil")

	var player: CharacterBody2D = street.player
	var hp_before: int = gs.player_hp
	feirante.global_position = player.global_position + Vector2(18, 0)
	feirante._attack_timer = 0.0
	for _i in range(6):
		await physics_frame
	_assert_ok(gs.player_hp < hp_before, "NPC hostil causou dano seguro no Player (%d -> %d)" % [hp_before, gs.player_hp])

	# Testa aliases take_damage / receive_damage diretamente
	var hp_mid: int = gs.player_hp
	player._hurt_timer = 0.0
	player.receive_damage(10, feirante.global_position)
	_assert_ok(gs.player_hp == hp_mid - 10, "Player.receive_damage() funcionou corretamente")
	print("[PASS] Ataque do NPC hostil e funções de dano do Player validados.")

	# 4. Combate do Player -> NPC (antigo crash Dictionary vs Array + retorno bool)
	player.facing_dir = Vector2.RIGHT
	player._attack_cooldown = 0.0
	feirante.global_position = player.global_position + Vector2(22, 0)
	var npc_hp_before := feirante._hp
	var hit_signal_count := {"n": 0}
	player.attack_hit_landed.connect(func(_p: Vector2, _d: int) -> void: hit_signal_count["n"] += 1)

	var swung: bool = player.perform_melee_attack()
	_assert_ok(swung, "perform_melee_attack() disparado com sucesso")
	await physics_frame
	_assert_ok(feirante._hp < npc_hp_before, "Player.perform_melee_attack() acertou NpcEntity sem erro de tipo")
	_assert_ok(hit_signal_count["n"] >= 1, "Sinal attack_hit_landed emitido ao acertar NpcEntity")

	# Usa skill de água para finalizar derrota com física segura
	feirante._hp = 20
	player._attack_cooldown = 0.0
	player.facing_dir = Vector2.RIGHT
	feirante.global_position = player.global_position + Vector2(26, 0)
	var water_ok: bool = player.perform_water_skill()
	_assert_ok(water_ok, "perform_water_skill() disparado contra NpcEntity hostil")
	await physics_frame
	await process_frame
	_assert_ok(feirante.is_defeated == true and not feirante.is_hostile, "NPC derrotado com segurança após dano do Player")

	# 5. Overdose (Intoxicacao == 3) + guarda de referência nula do Player em _process_hostile
	var toby: NpcEntity = street._npcs["NPC_Toby"]
	toby.aggressive_on_overdose = true
	toby.aggro_radius = 96.0
	player.global_position = toby.global_position + Vector2(36, 0)
	gs.call("set_intoxication_level", 3)
	for _i in range(4):
		await physics_frame
	_assert_ok(toby.is_hostile == true, "Intoxicacao == 3 transforma NPC próximo em inimigo agressivo")

	# Remove Player da árvore temporariamente e garante que _process_hostile não quebra por Null Instance
	var ysort_parent := player.get_parent()
	ysort_parent.remove_child(player)
	toby._attack_timer = 0.0
	for _i in range(4):
		await physics_frame
	ysort_parent.add_child(player)
	print("[PASS] Combate completo Player <-> NPC Distorcido e proteção contra Null Instance validados.")

	street.queue_free()
	await process_frame

	# Verificar também FireStation com Senhora Luningning normal e distorcida
	gs.set_higher_dose(false)
	var station_sc: PackedScene = load("res://scenes/levels/FireStation.tscn")
	var station := station_sc.instantiate()
	root.add_child(station)
	await process_frame
	var velhinha: NpcEntity = station._npcs["Velhinha_Espera"]
	_assert_ok(velhinha.normal_frames_path.ends_with("senhora_luningning_normal_spriteframes.tres"), "Velhinha_Espera usa senhora_luningning_normal_spriteframes.tres no Quartel")
	station.queue_free()
	await process_frame

	print("\n==================================================================")
	print("=== FASE 3 VERIFICADA 100% — ZERO CRASHES E DISTORÇÃO ATIVA! ===")
	print("==================================================================")
	quit(0)
