extends Node2D

signal request_level_change(target_scene: String, spawn_tag: String)
signal request_dialogue(pages: Array, callback: Callable)

@onready var player: PlayerController = $Player
@onready var interactables_root: Node2D = $Interactables

# Estado do Boss de Água (Ato 1)
var boss_alive: bool = false
var boss_hostile: bool = false
var boss_pos: Vector2 = Vector2(390, 175)
var boss_hp: int = 200
var boss_max_hp: int = 200
var boss_atk_cooldown: float = 0.0
var boss_prepare_timer: float = 0.0
var boss_hurt_flash: float = 0.0
var drop_thresholds_triggered: Array[bool] = [false, false, false] # 75%, 50%, 25%
var ground_drops: Array[Vector2] = []

# Estado do Ato 2 (Boss Rush de Fogo + Gatinho)
var fire_enemies: Array[Dictionary] = []
var kitten_visible: bool = false

var _boss_interactable: Interactable = null
var _eggs_interactable: Interactable = null
var _kitten_interactable: Interactable = null

var _tex_grass: Texture2D
var _tex_plant: Texture2D
var _tex_floors: Texture2D
var _tex_rocks: Texture2D
var _tex_village: Texture2D
var _tex_fire: Texture2D
var _tex_shaman: Texture2D
var _anim_clock: float = 0.0

func _ready() -> void:
	_tex_grass = load("res://assets/third_party/Pixel Art Top Down - Basic v1.2.3/Texture/TX Tileset Grass.png") as Texture2D
	_tex_plant = load("res://assets/third_party/Pixel Art Top Down - Basic v1.2.3/Texture/TX Plant.png") as Texture2D
	_tex_floors = load("res://assets/third_party/Pixel Crawler - Free Pack (Exterior 0.1)/Pixel Crawler - Free Pack/Environment/Tilesets/Floors_Tiles.png") as Texture2D
	_tex_rocks = load("res://assets/third_party/Pixel Crawler - Free Pack (Exterior 0.1)/Pixel Crawler - Free Pack/Environment/Props/Static/Rocks.png") as Texture2D
	_tex_village = load("res://assets/third_party/Serene_Village_revamped_v1.9/SERENE_VILLAGE_REVAMPED/Serene_Village_16x16.png") as Texture2D
	_tex_fire = load("res://assets/third_party/Pixel Crawler - Free Pack (Exterior 0.1)/Pixel Crawler - Free Pack/Environment/Structures/Stations/Bonfire/Fire_01-Sheet.png") as Texture2D
	_tex_shaman = load("res://assets/third_party/Pixel Crawler - Free Pack (Exterior 0.1)/Pixel Crawler - Free Pack/Entities/Mobs/Orc Crew/Orc - Shaman/Idle/Idle-Sheet.png") as Texture2D

	add_to_group("combat_target")
	add_to_group("water_target")

	player.position = Vector2(84, 196)
	player.facing_dir = Vector2.RIGHT
	player.set_camera_limits(Rect2i(0, 0, 640, 360))

	_setup_collisions()
	_setup_scenario()

func _setup_collisions() -> void:
	var body := StaticBody2D.new()
	body.name = "ClearingWalls"
	body.collision_layer = 1
	add_child(body)

	var rects: Array[Rect2] = [
		Rect2(0, 0, 640, 72),
		Rect2(0, 304, 640, 56),
		Rect2(576, 0, 64, 360),
		Rect2(0, 0, 32, 136),
		Rect2(0, 248, 32, 112),
	]
	for r in rects:
		var shape_node := CollisionShape2D.new()
		var rect_shape := RectangleShape2D.new()
		rect_shape.size = r.size
		shape_node.shape = rect_shape
		shape_node.position = r.position + r.size * 0.5
		body.add_child(shape_node)

func _setup_scenario() -> void:
	_add_interactable("Voltar_Corredor", "Trilha da Floresta", "Fugir / Voltar", Vector2(28, 196), Vector2(36, 92))

	var ato: int = int(GameState.get_var("Ato", 1))
	if ato == 1:
		if not GameState.water_boss_defeated:
			boss_alive = true
			boss_hostile = GameState.get_switch("003_Ovos_sem_derrotar")
			_boss_interactable = _add_interactable("Monstro_Agua", "Criatura da Lagoa", "Observar / Conversar", boss_pos, Vector2(54, 54))

		if not GameState.get_switch("003_Ovos_sem_derrotar") and not GameState.get_switch("004_Ovos_e_derrotou"):
			_eggs_interactable = _add_interactable("Ovos_Monstro", "Ninho com Ovos", "Coletar", Vector2(492, 175), Vector2(42, 42))
	elif ato == 2:
		kitten_visible = not GameState.get_switch("017_Gatinho_encontrado")
		if kitten_visible:
			_kitten_interactable = _add_interactable("Gatinho_Perdido", "Gatinho Assustado", "Resgatar", Vector2(512, 180), Vector2(38, 38))
			fire_enemies = [
				{"pos": Vector2(340, 145), "hp": 70, "max_hp": 70, "cd": 0.5, "hurt": 0.0},
				{"pos": Vector2(380, 225), "hp": 70, "max_hp": 70, "cd": 0.8, "hurt": 0.0},
			]

func _add_interactable(id: String, title_text: String, verb_text: String, pos: Vector2, box_size: Vector2) -> Interactable:
	var inter := Interactable.new()
	inter.name = id
	inter.interaction_id = id
	inter.title = title_text
	inter.verb = verb_text
	inter.position = pos

	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = box_size
	col.shape = shape
	inter.add_child(col)

	inter.interacted.connect(_on_interacted)
	interactables_root.add_child(inter)
	return inter

func _physics_process(delta: float) -> void:
	_anim_clock += delta
	if int(_anim_clock * 10.0) != int((_anim_clock - delta) * 10.0):
		queue_redraw()

	if boss_hurt_flash > 0.0:
		boss_hurt_flash = maxf(0.0, boss_hurt_flash - delta)
		queue_redraw()

	if GameState.dialogue_active:
		return

	# Coleta automática das Cápsulas/Gotas de Cura dropadas pelo Boss no chão
	for i in range(ground_drops.size() - 1, -1, -1):
		if player.global_position.distance_to(ground_drops[i]) <= 24.0:
			ground_drops.remove_at(i)
			GameState.add_item("gota_calmante", 1)
			GameState.notification_requested.emit("Pegou Cápsula Calmante ([H/C] para usar)")
			queue_redraw()

	# IA do Boss de Água em tempo real (J-ABS: sight / pursuit / prepare)
	if boss_alive:
		if _boss_interactable and is_instance_valid(_boss_interactable):
			_boss_interactable.position = boss_pos
			_boss_interactable.visible = not boss_hostile

		if boss_hostile:
			if boss_atk_cooldown > 0.0:
				boss_atk_cooldown -= delta
			var to_player := player.global_position - boss_pos
			var dist := to_player.length()
			if dist > 22.0:
				boss_pos += to_player.normalized() * 68.0 * delta
			if dist <= 34.0 and boss_atk_cooldown <= 0.0:
				boss_prepare_timer += delta
				if boss_prepare_timer >= 0.35:
					boss_prepare_timer = 0.0
					boss_atk_cooldown = 1.15
					player.apply_hit(14, boss_pos)
			else:
				boss_prepare_timer = maxf(0.0, boss_prepare_timer - delta)
			queue_redraw()

	# IA das Criaturas de Fogo no Ato 2 (Boss Rush perto do Gatinho)
	var fire_updated := false
	for enemy in fire_enemies:
		var hurt_t: float = float(enemy.get("hurt", 0.0))
		if hurt_t > 0.0:
			enemy["hurt"] = maxf(0.0, hurt_t - delta)
			fire_updated = true
		if int(enemy["hp"]) <= 0:
			continue
		fire_updated = true
		var epos: Vector2 = enemy["pos"]
		var cd: float = float(enemy["cd"]) - delta
		var to_p := player.global_position - epos
		var d := to_p.length()
		if d > 18.0 and d < 180.0:
			epos += to_p.normalized() * 72.0 * delta
		if d <= 24.0 and cd <= 0.0:
			cd = 1.0
			player.apply_hit(10, epos)
		enemy["pos"] = epos
		enemy["cd"] = cd
	if fire_updated:
		queue_redraw()

func query_melee_hit(origin: Vector2, swing_dir: Vector2, reach: float, arc_deg: float, damage: int, already_hit_ids: Dictionary) -> Array[Dictionary]:
	var hits: Array[Dictionary] = []
	if boss_alive and not already_hit_ids.has("water_boss"):
		if PlayerController.is_point_in_attack_cone(origin, swing_dir, boss_pos, 22.0, reach, arc_deg):
			already_hit_ids["water_boss"] = true
			_damage_water_boss(damage, origin)
			hits.append({"id": "water_boss", "pos": boss_pos, "damage": damage})

	for i in range(fire_enemies.size()):
		var enemy: Dictionary = fire_enemies[i]
		if int(enemy["hp"]) <= 0:
			continue
		var tid := "fire_clearing_%d" % i
		if already_hit_ids.has(tid):
			continue
		var epos: Vector2 = enemy["pos"]
		if PlayerController.is_point_in_attack_cone(origin, swing_dir, epos, 15.0, reach, arc_deg):
			already_hit_ids[tid] = true
			enemy["hp"] = maxi(0, int(enemy["hp"]) - damage)
			enemy["hurt"] = 0.18
			var push_dir := (epos - origin).normalized()
			if push_dir.length_squared() < 0.01:
				push_dir = swing_dir
			enemy["pos"] = epos + push_dir * 16.0
			hits.append({"id": tid, "pos": epos, "damage": damage})
			queue_redraw()
	return hits

func query_water_hit(origin: Vector2, dir: Vector2, reach: float, arc_deg: float, damage: int) -> Array[Dictionary]:
	var hits: Array[Dictionary] = []
	for i in range(fire_enemies.size()):
		var enemy: Dictionary = fire_enemies[i]
		if int(enemy["hp"]) <= 0:
			continue
		var epos: Vector2 = enemy["pos"]
		if PlayerController.is_point_in_attack_cone(origin, dir, epos, 16.0, reach, arc_deg):
			var dealt := damage * 2
			enemy["hp"] = maxi(0, int(enemy["hp"]) - dealt)
			enemy["hurt"] = 0.20
			if int(enemy["hp"]) <= 0:
				GameState.notification_requested.emit("Espírito de Fogo extinto com Magia de Água!")
			hits.append({"id": "fire_clearing_%d" % i, "pos": epos, "label": "-%d" % dealt})
			queue_redraw()
	return hits

func receive_melee_hit(damage: int, from_pos: Vector2) -> void:
	if boss_alive and boss_pos.distance_to(from_pos) <= 64.0:
		_damage_water_boss(damage, from_pos)

	for enemy in fire_enemies:
		if int(enemy["hp"]) > 0 and (enemy["pos"] as Vector2).distance_to(from_pos) <= 56.0:
			enemy["hp"] = maxi(0, int(enemy["hp"]) - damage)
			enemy["hurt"] = 0.18
			enemy["pos"] = (enemy["pos"] as Vector2) + ((enemy["pos"] as Vector2) - from_pos).normalized() * 16.0
			queue_redraw()

func receive_water_hit(damage: int, from_pos: Vector2) -> void:
	for enemy in fire_enemies:
		if int(enemy["hp"]) > 0 and (enemy["pos"] as Vector2).distance_to(from_pos) <= 68.0:
			enemy["hp"] = maxi(0, int(enemy["hp"]) - damage * 2)
			enemy["hurt"] = 0.20
			if int(enemy["hp"]) <= 0:
				GameState.notification_requested.emit("Espírito de Fogo extinto com Magia de Água!")
			queue_redraw()

func _damage_water_boss(damage: int, from_pos: Vector2) -> void:
	boss_hostile = true
	boss_hurt_flash = 0.18
	boss_hp = maxi(0, boss_hp - damage)
	var push_dir := (boss_pos - from_pos).normalized()
	if push_dir.length_squared() < 0.01:
		push_dir = Vector2.RIGHT
	boss_pos += push_dir * 14.0
	boss_pos.x = clampf(boss_pos.x, 76.0, 540.0)
	boss_pos.y = clampf(boss_pos.y, 92.0, 286.0)

	# Drops de item de cura em 75% (150 HP), 50% (100 HP) e 25% (50 HP) conforme Guia §8.1
	var ratios := [0.75, 0.50, 0.25]
	for i in range(ratios.size()):
		if not drop_thresholds_triggered[i] and float(boss_hp) <= float(boss_max_hp) * ratios[i]:
			drop_thresholds_triggered[i] = true
			var drop_offset := Vector2(randf_range(-28.0, 28.0), randf_range(-24.0, 24.0))
			ground_drops.append(boss_pos + drop_offset)
			GameState.notification_requested.emit("O monstro expeliu uma Cápsula Calmante!")

	if boss_hp <= 0:
		boss_alive = false
		GameState.water_boss_defeated = true
		GameState.set_switch("016_Magia_de_agua_obtida", true)
		if GameState.get_switch("003_Ovos_sem_derrotar"):
			GameState.set_switch("003_Ovos_sem_derrotar", false)
			GameState.set_switch("004_Ovos_e_derrotou", true)
			GameState.trigger_turn_afternoon()
		GameState.notification_requested.emit("Criatura derrotada! Magia de Água obtida ([K/Q]).")
	queue_redraw()

func _on_dialogue_conflict_triggered(target_id: String, _context: Dictionary) -> void:
	if target_id == "Monstro_Agua" and boss_alive:
		_damage_water_boss(player.attack_damage, player.global_position)

func _on_interacted(inter: Interactable) -> void:
	match inter.interaction_id:
		"Voltar_Corredor":
			request_level_change.emit("res://scenes/levels/ForestCorridor.tscn", "from_clearing")

		"Monstro_Agua":
			if not boss_alive:
				return
			var pages: Array = [
				{
					"speaker": "Criatura da Lagoa",
					"text": "Uma criatura anfíbia — metade peixe, metade vulto encharcado — respira pesadamente diante do ninho de ovos translúcidos.",
					"choices": [
						"Observar seus movimentos",
						"Tentar acalmá-la com a voz",
						"Avançar de forma hostil (Iniciar Conflito)",
						"Recuar em silêncio"
					],
					"conflict_choices": {
						2: "Monstro_Agua"
					}
				}
			]
			request_dialogue.emit(pages, func(choice: int) -> void:
				if choice == 0:
					request_dialogue.emit([{
						"speaker": "Huwag Matitiis",
						"expression": "neutral",
						"text": "Suas guelras inflam quando me aproximo dos ovos. Ela só ataca se sentir a ninhada ameaçada — e traz pequenas cápsulas brilhantes presas às escamas."
					}], Callable())
				elif choice == 1:
					request_dialogue.emit([{
						"speaker": "Huwag Matitiis",
						"expression": "worried",
						"text": "\"Calma... Eu só vim cumprir ordens do quartel.\" A criatura inclina a cabeça com olhos turvos, mas não sai da frente do ninho."
					}], Callable())
			)

		"Ovos_Monstro":
			GameState.add_item("ovos_monstro", 1)
			GameState.set_switch("016_Magia_de_agua_obtida", true)
			GameState.trigger_turn_afternoon()

			if GameState.water_boss_defeated or not boss_alive:
				GameState.set_switch("004_Ovos_e_derrotou", true)
				request_dialogue.emit([{
					"speaker": "Huwag Matitiis",
					"expression": "neutral",
					"text": "Recolhi os ovos translúcidos da clareira. O frio da água impregna minhas mãos (Magia de Água desbloqueada em [K / Q]).\nO sol já está baixando — preciso voltar ao Capitão Reyes."
				}], Callable())
			else:
				GameState.set_switch("003_Ovos_sem_derrotar", true)
				boss_hostile = true
				request_dialogue.emit([{
					"speaker": "Huwag Matitiis",
					"expression": "scared",
					"text": "Peguei os ovos! O frio deles despertou um jato d'água em minhas mãos ([K / Q] Magia de Água).\nA criatura percebeu! Posso fugir pela trilha à esquerda ou enfrentá-la aqui!"
				}], Callable())

			if _eggs_interactable and is_instance_valid(_eggs_interactable):
				_eggs_interactable.visible = false

		"Gatinho_Perdido":
			var active_fires := 0
			for enemy in fire_enemies:
				if int(enemy["hp"]) > 0:
					active_fires += 1
			if active_fires > 0:
				request_dialogue.emit([{
					"speaker": "Huwag Matitiis",
					"expression": "angry",
					"text": "As chamas vivas estão cercando o gatinho! Preciso apagá-las com [K / Q] (Magia de Água) ou [J / Espaço] primeiro!"
				}], Callable())
				return

			GameState.set_switch("017_Gatinho_encontrado", true)
			kitten_visible = false
			if _kitten_interactable and is_instance_valid(_kitten_interactable):
				_kitten_interactable.visible = false
			request_dialogue.emit([{
				"speaker": "Huwag Matitiis",
				"expression": "worried",
				"text": "Consegui pegar o gatinho! Ele está tremendo de susto e fuligem, mas sem queimaduras.\nA trilha de volta para Agdangan está livre agora."
			}], Callable())
			queue_redraw()

func _draw() -> void:
	var act3 := GameState.is_unfiltered_act3()
	var tint := Color(1, 1, 1) if not act3 else Color(0.55, 0.58, 0.56)

	# 1. Clareira e Lagoa Central com Tilesets Reais
	draw_rect(Rect2(0, 0, 640, 360), Color("#2D6A4F") if not act3 else Color("#2F3532"))
	if _tex_grass:
		for x in range(0, 640, 128):
			for y in range(0, 360, 128):
				draw_texture_rect_region(_tex_grass, Rect2(x, y, 128, 128), Rect2(0, 0, 128, 128), tint)

	# Borda rochosa/clareira central e trilha de terra
	draw_circle(Vector2(340, 190), 145.0, Color("#567D46", 0.55) if not act3 else Color("#3E4641", 0.55))
	draw_circle(Vector2(340, 190), 120.0, Color("#8A6B4E", 0.85) if not act3 else Color("#524B44", 0.85))
	if _tex_floors:
		for x in range(0, 320, 64):
			draw_texture_rect_region(_tex_floors, Rect2(x, 156, 64, 76), Rect2(160, 16, 64, 64), tint)
		for x in range(240, 440, 64):
			for y in range(116, 260, 64):
				draw_texture_rect_region(_tex_floors, Rect2(x, y, 64, 64), Rect2(160, 16, 64, 64), Color(tint.r, tint.g, tint.b, 0.82))

	# Lagoa Cristalina (Serene Village pond + água profunda)
	draw_circle(Vector2(420, 180), 70.0, Color("#2A7F8E") if not act3 else Color("#384448"))
	draw_circle(Vector2(424, 180), 56.0, Color("#4ECDC4") if not act3 else Color("#485458"))
	if _tex_village:
		draw_texture_rect_region(_tex_village, Rect2(364, 124, 112, 112), Rect2(176, 0, 48, 48), tint)

	# Rochas decorativas ao redor da lagoa
	if _tex_rocks:
		draw_texture_rect_region(_tex_rocks, Rect2(344, 112, 32, 30), Rect2(36, 18, 32, 30), tint)
		draw_texture_rect_region(_tex_rocks, Rect2(462, 214, 32, 30), Rect2(36, 18, 32, 30), tint)
		draw_texture_rect_region(_tex_rocks, Rect2(248, 232, 32, 30), Rect2(36, 18, 32, 30), tint)

	for x in range(40, 610, 64):
		_draw_clearing_tree(Vector2(x, 62), act3, int(x / 64))
		_draw_clearing_tree(Vector2(x + 16, 336), act3, int(x / 64) + 1)
	for y in range(110, 290, 64):
		_draw_clearing_tree(Vector2(596, y), act3, int(y / 64))

	# 2. Ninho com os 3 Ovos
	if _eggs_interactable and is_instance_valid(_eggs_interactable) and _eggs_interactable.visible:
		var npos := Vector2(492, 175)
		if _tex_plant:
			draw_texture_rect_region(_tex_plant, Rect2(npos.x - 18, npos.y - 16, 36, 32), Rect2(216, 185, 47, 42), Color(0.85, 0.72, 0.55))
		draw_circle(npos, 14.0, Color("#5A3A28", 0.85))
		draw_circle(npos + Vector2(-5, -2), 5.0, Color("#E0FBFC"))
		draw_circle(npos + Vector2(5, -2), 5.0, Color("#E0FBFC"))
		draw_circle(npos + Vector2(0, 5), 5.0, Color("#90E0EF"))

	# 3. Drops de cura no chão (75%, 50%, 25% HP)
	for dpos in ground_drops:
		draw_circle(dpos, 7.0, Color("#1B192E"))
		draw_circle(dpos, 5.5, Color("#FFCA3A"))
		draw_circle(dpos + Vector2(-1, -1), 2.5, Color("#FFFFFF"))

	# 4. Boss de Água
	if boss_alive:
		_draw_water_boss_art(boss_pos)

	# 5. Ato 2: Criaturas de Fogo e Gatinho
	for enemy in fire_enemies:
		if int(enemy["hp"]) > 0:
			_draw_fire_creature(enemy["pos"], int(enemy["hp"]), int(enemy["max_hp"]), float(enemy.get("hurt", 0.0)) > 0.0)

	if kitten_visible:
		var kpos := Vector2(512, 180)
		draw_circle(kpos + Vector2(0, 4), 9.0, Color(0, 0, 0, 0.35))
		draw_rect(Rect2(kpos.x - 7, kpos.y - 6, 14, 10), Color("#F77F00"))
		draw_rect(Rect2(kpos.x - 5, kpos.y - 12, 10, 7), Color("#F77F00"))
		draw_colored_polygon(PackedVector2Array([kpos + Vector2(-5, -12), kpos + Vector2(-2, -16), kpos + Vector2(-1, -12)]), Color("#F77F00"))
		draw_colored_polygon(PackedVector2Array([kpos + Vector2(1, -12), kpos + Vector2(4, -16), kpos + Vector2(5, -12)]), Color("#F77F00"))

func _draw_water_boss_art(pos: Vector2) -> void:
	var flash := boss_hurt_flash > 0.0
	draw_circle(pos + Vector2(0, 12), 22.0, Color(0.05, 0.12, 0.22, 0.45))
	if boss_prepare_timer > 0.0:
		draw_arc(pos, 26.0, 0.0, TAU, 24, Color(1.0, 0.35, 0.3, 0.8), 2.0)

	# Aura aquática + Sprite animado da Criatura Anfíbia
	draw_circle(pos, 18.0, Color(0.18, 0.72, 0.88, 0.32))
	if _tex_shaman:
		var frame := int(_anim_clock * 7.0) % 4
		var mod := Color(1.8, 1.8, 1.8, 1.0) if flash else (Color(0.45, 0.92, 1.0, 1.0) if not boss_hostile else Color(0.28, 0.68, 0.95, 1.0))
		draw_texture_rect_region(_tex_shaman, Rect2(pos.x - 24, pos.y - 28, 48, 48), Rect2(frame * 32, 0, 32, 32), mod)
	else:
		draw_circle(pos, 18.0, Color("#0077B6"))

	var ratio := clampf(float(boss_hp) / float(boss_max_hp), 0.0, 1.0)
	draw_rect(Rect2(pos.x - 24, pos.y - 36, 48, 6), Color("#1B192E"))
	draw_rect(Rect2(pos.x - 23, pos.y - 35, 46.0 * ratio, 4), Color("#4ECDC4") if not flash else Color("#FFF3B0"))

func _draw_clearing_tree(pos: Vector2, act3: bool, variant: int = 0) -> void:
	var tint := Color(1, 1, 1) if not act3 else Color(0.52, 0.56, 0.54)
	draw_circle(pos + Vector2(0, 4), 18.0, Color(0, 0, 0, 0.28))
	if _tex_plant:
		var src := Rect2(24, 14, 113, 139) if (variant % 2 == 0) else Rect2(161, 17, 95, 136)
		draw_texture_rect_region(_tex_plant, Rect2(pos.x - 28, pos.y - 54, 56, 68), src, tint)

func _draw_fire_creature(pos: Vector2, hp: int, max_hp: int, flash: bool = false) -> void:
	draw_circle(pos + Vector2(0, 6), 14.0, Color(0, 0, 0, 0.35))
	if _tex_fire:
		var frame := int(_anim_clock * 10.0) % 4
		var mod := Color(2.0, 2.0, 2.0, 1.0) if flash else Color(1.0, 0.88, 0.72, 1.0)
		draw_texture_rect_region(_tex_fire, Rect2(pos.x - 16, pos.y - 28, 32, 42), Rect2(frame * 32, 0, 32, 48), mod)
	else:
		draw_circle(pos, 13.0, Color("#E63946"))
	var ratio := clampf(float(hp) / float(max_hp), 0.0, 1.0)
	draw_rect(Rect2(pos.x - 16, pos.y - 28, 32, 5), Color("#1B192E"))
	draw_rect(Rect2(pos.x - 15, pos.y - 27, 30.0 * ratio, 3), Color("#FFBA08"))
