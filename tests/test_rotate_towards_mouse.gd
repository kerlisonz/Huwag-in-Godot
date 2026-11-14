extends SceneTree

var passed: int = 0
var failed: int = 0

func _init() -> void:
	print("==================================================")
	print("=== INICIANDO TESTES: ROTATE TOWARDS MOUSE ===")
	print("==================================================")
	call_deferred("_run_all_tests")

func assert_true(condition: bool, label: String) -> void:
	if condition:
		passed += 1
		print("[PASS] %s" % label)
	else:
		failed += 1
		push_error("FAIL: %s" % label)
		print("[FAIL] %s" % label)

func assert_near(val: float, expected: float, tol: float, label: String) -> void:
	var diff := absf(val - expected)
	# Trata equivalência de ângulo circular (ex: PI vs -PI)
	if absf(diff - TAU) < tol:
		diff = 0.0
	if diff <= tol:
		passed += 1
		print("[PASS] %s (valor: %f, esperado: %f)" % [label, val, expected])
	else:
		failed += 1
		push_error("FAIL: %s (valor: %f, esperado: %f, tol: %f)" % [label, val, expected, tol])
		print("[FAIL] %s (valor: %f, esperado: %f)" % [label, val, expected])

func _run_all_tests() -> void:
	await _test_component_standalone()
	await _test_snapping_and_constraints()
	await _test_player_integration()
	await _test_player_combat_with_mouse()
	await _test_strafing_and_dialogue_suspension()

	print("==================================================")
	print("=== RESULTADO: %d PASSOU, %d FALHOU ===" % [passed, failed])
	print("==================================================")
	quit(0 if failed == 0 else 1)

func _test_component_standalone() -> void:
	print("\n--- TESTE 1: Componente RotateTowardsMouse Standalone ---")
	var comp_scene: PackedScene = load("res://scenes/components/RotateTowardsMouse.tscn")
	assert_true(comp_scene != null, "Cena RotateTowardsMouse.tscn carregada com sucesso")

	var comp: RotateTowardsMouse = comp_scene.instantiate() as RotateTowardsMouse
	root.add_child(comp)
	comp.global_position = Vector2(100, 100)

	# Simula mouse à direita (ângulo 0 radianos)
	comp.set_simulated_mouse_position(Vector2(200, 100))
	comp.update_rotation(0.016)
	assert_near(comp.global_rotation, 0.0, 0.05, "Rotação para a direita resulta em ~0 radianos")
	assert_near(comp.get_aim_direction().x, 1.0, 0.05, "Vetor de mira aponta para +X (1, 0)")

	# Simula mouse para baixo (ângulo PI/2 radianos = 90 graus)
	comp.set_simulated_mouse_position(Vector2(100, 200))
	comp.update_rotation(0.016)
	assert_near(comp.global_rotation, PI * 0.5, 0.05, "Rotação para baixo resulta em ~PI/2 radianos")
	assert_near(comp.get_aim_direction().y, 1.0, 0.05, "Vetor de mira aponta para +Y (0, 1)")

	# Simula mouse para a esquerda (ângulo PI radianos = 180 graus)
	comp.set_simulated_mouse_position(Vector2(0, 100))
	comp.update_rotation(0.016)
	assert_near(absf(comp.global_rotation), PI, 0.05, "Rotação para a esquerda resulta em ~PI radianos")
	assert_near(comp.get_aim_direction().x, -1.0, 0.05, "Vetor de mira aponta para -X (-1, 0)")

	# Simula mouse para cima (ângulo -PI/2 radianos = -90 graus)
	comp.set_simulated_mouse_position(Vector2(100, 0))
	comp.update_rotation(0.016)
	assert_near(comp.global_rotation, -PI * 0.5, 0.05, "Rotação para cima resulta em ~ -PI/2 radianos")
	assert_near(comp.get_aim_direction().y, -1.0, 0.05, "Vetor de mira aponta para -Y (0, -1)")

	# Teste de deadzone: movimento dentro de 4px não deve alterar rotação
	var prev_angle := comp.global_rotation
	comp.deadzone = 12.0
	comp.set_simulated_mouse_position(Vector2(103, 103)) # dist ~ 4.2 px
	comp.update_rotation(0.016)
	assert_near(comp.global_rotation, prev_angle, 0.001, "Deadzone ignorou mouse excessivamente próximo à origem")

	comp.queue_free()
	await process_frame

func _test_snapping_and_constraints() -> void:
	print("\n--- TESTE 2: Snapping Cardinal (4 direções) e 8 Direções ---")
	var comp := RotateTowardsMouse.new()
	root.add_child(comp)
	comp.global_position = Vector2(0, 0)
	comp.snap_to_cardinal = true

	# Posição diagonal em 35 graus -> deve travar em 0 radianos (Direita)
	comp.set_simulated_mouse_position(Vector2(100, 50))
	comp.update_rotation(0.016)
	assert_near(comp.global_rotation, 0.0, 0.01, "Snap cardinal converteu 26° para 0° (Direita)")

	# Posição diagonal em 70 graus -> deve travar em PI/2 radianos (Baixo)
	comp.set_simulated_mouse_position(Vector2(40, 100))
	comp.update_rotation(0.016)
	assert_near(comp.global_rotation, PI * 0.5, 0.01, "Snap cardinal converteu ~68° para 90° (Baixo)")

	comp.queue_free()
	await process_frame

func _test_player_integration() -> void:
	print("\n--- TESTE 3: Integração no PlayerController & AimPivot ---")
	var player_scene: PackedScene = load("res://scenes/characters/Player.tscn")
	assert_true(player_scene != null, "Player.tscn carregada")

	var player = player_scene.instantiate()
	root.add_child(player)
	player.global_position = Vector2(200, 200)

	assert_true(player.aim_pivot != null, "Player possui nó AimPivot instanciado")
	assert_true(player.rotate_towards_mouse, "Propriedade rotate_towards_mouse habilitada por padrão")

	# Simula mira com mouse para a direita
	player.set_simulated_mouse_aim(Vector2(350, 200))
	player._physics_process(0.016)
	assert_true(player.facing_dir.x > 0.8, "Player facing_dir apontou para a direita seguindo o mouse")
	assert_true(player.character_sprite.animation.ends_with("right"), "Sprite escolheu animação terminada em _right")

	# Simula mira com mouse para a esquerda
	player.set_simulated_mouse_aim(Vector2(50, 200))
	player._physics_process(0.016)
	assert_true(player.facing_dir.x < -0.8, "Player facing_dir apontou para a esquerda seguindo o mouse")
	assert_true(player.character_sprite.animation.ends_with("left"), "Sprite escolheu animação terminada em _left")

	# Simula mira com mouse para cima
	player.set_simulated_mouse_aim(Vector2(200, 50))
	player._physics_process(0.016)
	assert_true(player.facing_dir.y < -0.8, "Player facing_dir apontou para cima seguindo o mouse")
	assert_true(player.character_sprite.animation.ends_with("up"), "Sprite escolheu animação terminada em _up")

	# Simula mira com mouse para baixo
	player.set_simulated_mouse_aim(Vector2(200, 350))
	player._physics_process(0.016)
	assert_true(player.facing_dir.y > 0.8, "Player facing_dir apontou para baixo seguindo o mouse")
	assert_true(player.character_sprite.animation.ends_with("down"), "Sprite escolheu animação terminada em _down")

	player.queue_free()
	await process_frame

func _test_player_combat_with_mouse() -> void:
	print("\n--- TESTE 4: Combate e Habilidades Orientados ao Mouse ---")
	var player_scene: PackedScene = load("res://scenes/characters/Player.tscn")
	var player = player_scene.instantiate()
	root.add_child(player)
	player.global_position = Vector2(100, 100)

	# Mira para Nordeste (45 graus acima da direita)
	player.set_simulated_mouse_aim(Vector2(200, 0))
	player._physics_process(0.016)

	var attack_event := {"facing": Vector2.ZERO}
	player.melee_attack_performed.connect(func(_orig: Vector2, facing: Vector2, _r: float, _a: float, _d: int):
		attack_event["facing"] = facing
	)

	# Executa ataque corpo a corpo
	var atk_res = player.perform_melee_attack()
	print("ATTACK RESULT: ", atk_res, " cooldown: ", player._attack_cooldown, " swing_dir: ", attack_event["facing"])
	assert_near(attack_event["facing"].x, player.facing_dir.x, 0.05, "Golpe de machado foi disparado exatamente na direção do mouse (X)")
	assert_near(attack_event["facing"].y, player.facing_dir.y, 0.05, "Golpe de machado foi disparado exatamente na direção do mouse (Y)")

	# Desbloqueia magia de água no GameState
	var gs = root.get_node_or_null("GameState")
	if gs:
		gs.set_switch("016_Magia_de_agua_obtida", true)
	var water_event := {"dir": Vector2.ZERO}
	player.water_skill_performed.connect(func(_orig: Vector2, dir: Vector2, _range: float, _dmg: int):
		water_event["dir"] = dir
	)

	# Mira para Sudeste (para baixo e à direita)
	player._attack_anim_timer = 0.0
	player._attack_cooldown = 0.0
	player.set_simulated_mouse_aim(Vector2(200, 200))
	player._physics_process(0.016)
	var water_res = player.perform_water_skill()
	print("WATER RESULT: ", water_res, " dir: ", water_event["dir"], " facing: ", player.facing_dir)
	assert_near(water_event["dir"].x, player.facing_dir.x, 0.05, "Magia de água disparada na direção do mouse (X)")
	assert_near(water_event["dir"].y, player.facing_dir.y, 0.05, "Magia de água disparada na direção do mouse (Y)")

	player.queue_free()
	await process_frame

func _test_strafing_and_dialogue_suspension() -> void:
	print("\n--- TESTE 5: Strafing (Mover WASD enquanto mira) & Pausa em Diálogo ---")
	var player_scene: PackedScene = load("res://scenes/characters/Player.tscn")
	var player = player_scene.instantiate()
	root.add_child(player)
	player.global_position = Vector2(100, 100)

	# 1. Strafing: mira para a direita (+X), mas move para a esquerda (-X)
	player.set_simulated_mouse_aim(Vector2(300, 100))
	player.velocity = Vector2(-100, 0)
	player._physics_process(0.016)
	assert_true(player.facing_dir.x > 0.8, "Huwag mira para a direita (+X) com o mouse")
	assert_true(player.character_sprite.animation.ends_with("right"), "Animação é orientada pela mira do mouse (_right)")

	# 2. Suspensão em Diálogo: quando diálogo ativo, mouse não deve alterar mira
	var gs = root.get_node_or_null("GameState")
	if gs:
		gs.dialogue_active = true
	var saved_facing: Vector2 = player.facing_dir
	player.set_simulated_mouse_aim(Vector2(100, 300))
	player._physics_process(0.016)
	assert_near(player.facing_dir.x, saved_facing.x, 0.01, "Diálogo ativo impediu rotação indevida do mouse (X mantido)")
	assert_near(player.facing_dir.y, saved_facing.y, 0.01, "Diálogo ativo impediu rotação indevida do mouse (Y mantido)")

	if gs:
		gs.dialogue_active = false

	player.queue_free()
	await process_frame
