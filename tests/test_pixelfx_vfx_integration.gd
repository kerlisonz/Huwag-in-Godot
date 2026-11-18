extends SceneTree

## Validação de integração dos spritesheets VFX (pixelfx -> SpriteFrames + VfxLibrary)
## Verifica os 14 SpriteFrames, instância no PlayerController (combo/água/esquiva) e no Santelmo.


func _init() -> void:
	create_timer(15.0).timeout.connect(func() -> void:
		push_error("TIMEOUT: test_pixelfx_vfx_integration excedeu 15s")
		quit(1)
	)
	call_deferred("_run")


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


func _find_vfx_nodes(parent: Node, prefix: String = "Vfx_") -> Array[AnimatedSprite2D]:
	var out: Array[AnimatedSprite2D] = []
	for c in parent.get_children():
		if c is AnimatedSprite2D and str(c.name).begins_with(prefix):
			out.append(c as AnimatedSprite2D)
	return out


func _run() -> void:
	print("=== TESTE INTEGRAÇÃO PIXELFX (14 VFX + PLAYER + SANTELMO) ===")
	var gs := _ensure_autoloads()
	gs.call("reset_to_new_game")
	await _wait_frames(2)

	# 1. Validar carregamento de todos os 14 SpriteFrames
	for effect_name_v in VfxLibrary.EFFECTS.keys():
		var effect_name: String = str(effect_name_v)
		var sf := VfxLibrary.get_frames(effect_name)
		_assert_ok(sf != null, "SpriteFrames deve carregar: %s" % effect_name)
		_assert_ok(sf.has_animation(&"play"), "Animação 'play' ausente em %s" % effect_name)
		_assert_ok(sf.get_frame_count(&"play") > 0, "Sem frames em %s" % effect_name)
	print("[PASS] 14/14 recursos SpriteFrames carregados e íntegros.")

	# 2. Validar disparos no PlayerController (StreetPreview)
	var street := (load("res://scenes/levels/StreetPreview.tscn") as PackedScene).instantiate()
	root.add_child(street)
	await _wait_frames(4)

	var player: PlayerController = street.get("player")
	_assert_ok(player != null, "Player presente em StreetPreview")
	var host := player.get_parent()

	player.set("_dodge_cooldown", 0.0)
	_assert_ok(player.perform_dodge(Vector2.RIGHT), "Esquiva deve ativar")
	_assert_ok(_find_vfx_nodes(host, "Vfx_impact_dust").size() >= 1, "Esquiva deve gerar Vfx_impact_dust")
	player.set("is_dodging", false)
	player.set("_dodge_timer", 0.0)

	# Combo 1 -> 2 -> 3
	for expected_stage in [1, 2, 3]:
		player.set("_attack_cooldown", 0.0)
		_assert_ok(player.perform_melee_attack(), "Ataque combo %d deve disparar" % expected_stage)
	_assert_ok(_find_vfx_nodes(host, "Vfx_axe_slash_amber").size() >= 2, "Combo 1-2 devem gerar Vfx_axe_slash_amber")
	_assert_ok(_find_vfx_nodes(host, "Vfx_axe_slash_crimson").size() >= 1, "Combo 3 deve gerar Vfx_axe_slash_crimson")

	# Habilidade de Água
	gs.call("set_switch", "016_Magia_de_agua_obtida", true)
	player.set("_attack_cooldown", 0.0)
	_assert_ok(player.perform_water_skill(), "Habilidade de Água deve disparar")
	_assert_ok(_find_vfx_nodes(host, "Vfx_water_jet").size() >= 1, "Água deve gerar Vfx_water_jet")

	for v in _find_vfx_nodes(host):
		_assert_ok(v.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST, "VFX %s deve usar TEXTURE_FILTER_NEAREST" % v.name)
	print("[PASS] Player disparou axe_slash_amber/crimson, impact_dust e water_jet em Nearest.")

	street.queue_free()
	await _wait_frames(3)

	# 3. Validar Santelmo na Trilha da Floresta
	var trail := (load("res://scenes/levels/forest_trail.tscn") as PackedScene).instantiate()
	root.add_child(trail)
	await _wait_frames(4)

	var s1 := trail.get_node_or_null("ObstaclesYsort/Santelmo1") as SantelmoEnemy
	_assert_ok(s1 != null, "Santelmo1 presente em forest_trail")
	var flame := s1.get_node_or_null("Vfx_santelmo_flame") as AnimatedSprite2D
	_assert_ok(flame != null and flame.is_playing(), "Santelmo deve ter Vfx_santelmo_flame animado")

	var s_host := s1.get_parent()
	s1.take_damage(100, Vector2.ZERO, true)
	_assert_ok(_find_vfx_nodes(s_host, "Vfx_water_splash").size() >= 1, "Morte por água do Santelmo deve gerar Vfx_water_splash")
	print("[PASS] Santelmo flame overlay + extinção com water_splash validados.")

	trail.queue_free()
	await _wait_frames(4)
	print("[SUCCESS] Integração pixelfx 100% validada!")
	quit(0)
