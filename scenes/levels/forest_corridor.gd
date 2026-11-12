extends Node2D

signal request_level_change(target_scene: String, spawn_tag: String)
signal request_dialogue(pages: Array, callback: Callable)

@onready var player: PlayerController = $Player
@onready var interactables_root: Node2D = $Interactables

var _tex_grass_tiles: Texture2D = null
var _tex_plants: Texture2D = null
var _tex_floors: Texture2D = null
var _tex_rocks: Texture2D = null
var _tex_mob_orc: Texture2D = null
var _tex_mob_shaman: Texture2D = null
var _tex_fire_sheet: Texture2D = null

# Fogueiras sorteadas no Ato 2 (switch 015)
var fire_hazards: Array[Dictionary] = []

# Criaturas hostis da trilha (Atos 1 e 2) para combate J-ABS no corredor
var forest_mobs: Array[Dictionary] = []

# Perseguição do Boss de Água no Ato 1 caso o jogador tenha fugido com os ovos (switch 003)
var pursuer_active: bool = false
var pursuer_pos: Vector2 = Vector2(540, 210)
var pursuer_hp: int = 120
var pursuer_max_hp: int = 120
var pursuer_atk_cooldown: float = 0.0
var pursuer_hurt_flash: float = 0.0
const PURSUER_RADIUS: float = 18.0
const MOB_RADIUS: float = 14.0
const FIRE_RADIUS: float = 14.0

func _ready() -> void:
	add_to_group("combat_target")
	add_to_group("water_target")

	_tex_grass_tiles = load("res://assets/third_party/Pixel Art Top Down - Basic v1.2.3/Texture/TX Tileset Grass.png") as Texture2D
	_tex_plants = load("res://assets/third_party/Pixel Art Top Down - Basic v1.2.3/Texture/TX Plant.png") as Texture2D
	_tex_floors = load("res://assets/third_party/Pixel Crawler - Free Pack (Exterior 0.1)/Pixel Crawler - Free Pack/Environment/Tilesets/Floors_Tiles.png") as Texture2D
	_tex_rocks = load("res://assets/third_party/Pixel Crawler - Free Pack (Exterior 0.1)/Pixel Crawler - Free Pack/Environment/Props/Static/Rocks.png") as Texture2D
	_tex_mob_orc = load("res://assets/third_party/Pixel Crawler - Free Pack (Exterior 0.1)/Pixel Crawler - Free Pack/Entities/Mobs/Orc Crew/Orc/Idle/Idle-Sheet.png") as Texture2D
	_tex_mob_shaman = load("res://assets/third_party/Pixel Crawler - Free Pack (Exterior 0.1)/Pixel Crawler - Free Pack/Entities/Mobs/Orc Crew/Orc - Shaman/Idle/Idle-Sheet.png") as Texture2D
	_tex_fire_sheet = load("res://assets/third_party/Pixel Crawler - Free Pack (Exterior 0.1)/Pixel Crawler - Free Pack/Environment/Structures/Stations/Bonfire/Fire_01-Sheet.png") as Texture2D

	if GameState.spawn_tag == "from_clearing":
		player.position = Vector2(560, 210)
		player.facing_dir = Vector2.LEFT
	else:
		player.position = Vector2(68, 210)
		player.facing_dir = Vector2.RIGHT

	player.set_camera_limits(Rect2i(0, 0, 640, 360))
	_setup_collisions()
	_setup_interactables()

	var ato: int = int(GameState.get_var("Ato", 1))
	if ato == 1:
		_spawn_forest_mobs()
		# Se pegou os ovos e fugiu sem derrotar o monstro, ele persegue pelo corredor
		if GameState.get_switch("003_Ovos_sem_derrotar") and not GameState.water_boss_defeated:
			pursuer_active = true
			pursuer_pos = Vector2(460, 210)
	elif ato == 2:
		# Switch 015: entrar no primeiro corredor bloqueia a volta e sorteia fogos
		if not GameState.get_switch("015_Floresta_em_chamas"):
			GameState.set_switch("015_Floresta_em_chamas", true)
			GameState.notification_requested.emit("As chamas tomaram a trilha! Use [J/Espaço] ou [K/Q] Magia de Água.")
		_spawn_random_fires()

func _spawn_forest_mobs() -> void:
	forest_mobs = [
		{
			"id": "corridor_mob_0",
			"pos": Vector2(250, 195),
			"home": Vector2(250, 195),
			"hp": 50,
			"max_hp": 50,
			"alive": true,
			"atk_cd": 0.0,
			"hurt_flash": 0.0,
			"phase": 0.4
		},
		{
			"id": "corridor_mob_1",
			"pos": Vector2(420, 225),
			"home": Vector2(420, 225),
			"hp": 50,
			"max_hp": 50,
			"alive": true,
			"atk_cd": 0.0,
			"hurt_flash": 0.0,
			"phase": 2.1
		}
	]

func _spawn_random_fires() -> void:
	fire_hazards.clear()
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var slots: Array[Vector2] = [
		Vector2(170, 175), Vector2(230, 235), Vector2(300, 185),
		Vector2(370, 225), Vector2(440, 180), Vector2(500, 230)
	]
	for i in range(slots.size()):
		var base_pos := slots[i]
		var offset := Vector2(rng.randf_range(-16.0, 16.0), rng.randf_range(-14.0, 14.0))
		fire_hazards.append({
			"id": "fire_hazard_%d" % i,
			"pos": base_pos + offset,
			"hp": 50,
			"max_hp": 50,
			"active": true,
			"hurt_flash": 0.0,
			"phase": rng.randf_range(0.0, TAU)
		})

func _physics_process(delta: float) -> void:
	if GameState.dialogue_active:
		return

	var needs_redraw := false

	# Atualiza criaturas da trilha no Ato 1
	for mob in forest_mobs:
		if not bool(mob["alive"]):
			continue
		needs_redraw = true
		mob["phase"] = float(mob["phase"]) + delta * 4.5
		if float(mob["atk_cd"]) > 0.0:
			mob["atk_cd"] = maxf(0.0, float(mob["atk_cd"]) - delta)
		if float(mob["hurt_flash"]) > 0.0:
			mob["hurt_flash"] = maxf(0.0, float(mob["hurt_flash"]) - delta)
		var mpos: Vector2 = mob["pos"]
		var to_player := player.global_position - mpos
		var dist := to_player.length()
		if dist < 135.0 and dist > 16.0:
			mpos += to_player.normalized() * 52.0 * delta
		elif dist >= 135.0:
			var home: Vector2 = mob["home"]
			var patrol_target := home + Vector2(sin(float(mob["phase"]) * 0.5) * 26.0, cos(float(mob["phase"]) * 0.7) * 14.0)
			mpos = mpos.move_toward(patrol_target, 30.0 * delta)
		mpos.x = clampf(mpos.x, 80.0, 580.0)
		mpos.y = clampf(mpos.y, 142.0, 274.0)
		mob["pos"] = mpos
		if dist <= 22.0 and float(mob["atk_cd"]) <= 0.0:
			mob["atk_cd"] = 1.15
			player.apply_hit(8, mpos)

	# Atualiza perseguição do monstro no Ato 1
	if pursuer_active:
		needs_redraw = true
		if pursuer_atk_cooldown > 0.0:
			pursuer_atk_cooldown -= delta
		if pursuer_hurt_flash > 0.0:
			pursuer_hurt_flash = maxf(0.0, pursuer_hurt_flash - delta)
		var to_player := player.global_position - pursuer_pos
		var dist := to_player.length()
		if dist > 16.0:
			pursuer_pos += to_player.normalized() * 78.0 * delta
		if dist <= 24.0 and pursuer_atk_cooldown <= 0.0:
			pursuer_atk_cooldown = 1.0
			player.apply_hit(12, pursuer_pos)

	# Atualiza dano de contato dos fogos no Ato 2
	for f in fire_hazards:
		if bool(f["active"]):
			needs_redraw = true
			f["phase"] = float(f["phase"]) + delta * 8.0
			if float(f.get("hurt_flash", 0.0)) > 0.0:
				f["hurt_flash"] = maxf(0.0, float(f["hurt_flash"]) - delta)
			var fpos: Vector2 = f["pos"]
			if player.global_position.distance_to(fpos) <= 20.0:
				player.apply_hit(8, fpos)

	if needs_redraw:
		queue_redraw()

## Consulta espacial e direcional do ataque corpo-a-corpo (J-ABS)
func query_melee_hit(origin: Vector2, swing_dir: Vector2, reach: float, arc_degrees: float, damage: int, already_hit_ids: Dictionary) -> Array[Dictionary]:
	var hits: Array[Dictionary] = []

	for mob in forest_mobs:
		if not bool(mob["alive"]):
			continue
		var mid: String = String(mob["id"])
		if already_hit_ids.has(mid):
			continue
		var mpos: Vector2 = mob["pos"]
		if PlayerController.is_point_in_attack_cone(origin, swing_dir, mpos, MOB_RADIUS, reach, arc_degrees):
			already_hit_ids[mid] = true
			var new_hp := maxi(0, int(mob["hp"]) - damage)
			mob["hp"] = new_hp
			mob["hurt_flash"] = 0.18
			var push_dir := (mpos - origin).normalized()
			if push_dir == Vector2.ZERO:
				push_dir = swing_dir
			mob["pos"] = Vector2(
				clampf(mpos.x + push_dir.x * 16.0, 80.0, 580.0),
				clampf(mpos.y + push_dir.y * 16.0, 142.0, 274.0)
			)
			var killed := new_hp <= 0
			if killed:
				mob["alive"] = false
			hits.append({
				"id": mid,
				"pos": mpos,
				"damage": damage,
				"killed": killed
			})

	if pursuer_active and not already_hit_ids.has("water_pursuer"):
		if PlayerController.is_point_in_attack_cone(origin, swing_dir, pursuer_pos, PURSUER_RADIUS, reach, arc_degrees):
			already_hit_ids["water_pursuer"] = true
			var hit_pos := pursuer_pos
			pursuer_hp = maxi(0, pursuer_hp - damage)
			pursuer_hurt_flash = 0.18
			var push := (pursuer_pos - origin).normalized()
			if push == Vector2.ZERO:
				push = swing_dir
			pursuer_pos += push * 18.0
			var killed := pursuer_hp <= 0
			if killed:
				pursuer_active = false
				GameState.water_boss_defeated = true
				GameState.set_switch("003_Ovos_sem_derrotar", false)
				GameState.set_switch("004_Ovos_e_derrotou", true)
				GameState.set_switch("016_Magia_de_agua_obtida", true)
				GameState.notification_requested.emit("Monstro de Água derrotado! (Switch 004 ativo)")
			hits.append({
				"id": "water_pursuer",
				"pos": hit_pos,
				"damage": damage,
				"killed": killed
			})

	for f in fire_hazards:
		if not bool(f["active"]):
			continue
		var fid: String = String(f["id"])
		if already_hit_ids.has(fid):
			continue
		var fpos: Vector2 = f["pos"]
		if PlayerController.is_point_in_attack_cone(origin, swing_dir, fpos, FIRE_RADIUS, reach, arc_degrees):
			already_hit_ids[fid] = true
			var new_hp := maxi(0, int(f.get("hp", 50)) - damage)
			f["hp"] = new_hp
			f["hurt_flash"] = 0.16
			var killed := new_hp <= 0
			if killed:
				f["active"] = false
			hits.append({
				"id": fid,
				"pos": fpos,
				"damage": damage,
				"killed": killed
			})

	if not hits.is_empty():
		queue_redraw()
	return hits

## Consulta espacial da habilidade de Água (J-ABS)
func query_water_hit(origin: Vector2, swing_dir: Vector2, reach: float, arc_deg: float, damage: int) -> Array[Dictionary]:
	var hits: Array[Dictionary] = []
	var extinguished := 0
	for f in fire_hazards:
		if bool(f["active"]):
			var fpos: Vector2 = f["pos"]
			if PlayerController.is_point_in_attack_cone(origin, swing_dir, fpos, FIRE_RADIUS, reach, arc_deg) or fpos.distance_to(origin) <= reach + FIRE_RADIUS:
				f["active"] = false
				f["hp"] = 0
				extinguished += 1
				hits.append({
					"id": String(f["id"]),
					"pos": fpos,
					"damage": damage,
					"label": "Apagado!",
					"killed": true
				})
	for mob in forest_mobs:
		if bool(mob["alive"]):
			var mpos: Vector2 = mob["pos"]
			if PlayerController.is_point_in_attack_cone(origin, swing_dir, mpos, MOB_RADIUS, reach, arc_deg):
				var new_hp := maxi(0, int(mob["hp"]) - damage)
				mob["hp"] = new_hp
				mob["hurt_flash"] = 0.18
				var killed := new_hp <= 0
				if killed:
					mob["alive"] = false
				hits.append({
					"id": String(mob["id"]),
					"pos": mpos,
					"damage": damage,
					"killed": killed
				})
	if extinguished > 0:
		GameState.notification_requested.emit("Chamas apagadas com Magia de Água!")
	if not hits.is_empty():
		queue_redraw()
	return hits

func receive_melee_hit(damage: int, from_pos: Vector2) -> void:
	var dir := (pursuer_pos - from_pos).normalized() if pursuer_active else Vector2.RIGHT
	query_melee_hit(from_pos, dir, 52.0, 360.0, damage, {})

func receive_water_hit(damage: int, from_pos: Vector2) -> void:
	query_water_hit(from_pos, Vector2.RIGHT, 68.0, 360.0, damage)

func _setup_collisions() -> void:
	var body := StaticBody2D.new()
	body.name = "ForestWalls"
	body.collision_layer = 1
	add_child(body)

	var rects: Array[Rect2] = [
		Rect2(0, 0, 640, 128),    # Copa densa norte
		Rect2(0, 286, 640, 74),   # Copa densa sul
	]
	for r in rects:
		var shape_node := CollisionShape2D.new()
		var rect_shape := RectangleShape2D.new()
		rect_shape.size = r.size
		shape_node.shape = rect_shape
		shape_node.position = r.position + r.size * 0.5
		body.add_child(shape_node)

func _setup_interactables() -> void:
	_add_interactable("Saida_Cidade", "Voltar para Agdangan", "Voltar", Vector2(28, 210), Vector2(36, 96))
	_add_interactable("Entrada_Clareira", "Clareira da Floresta", "Avançar", Vector2(612, 210), Vector2(36, 96))

func _add_interactable(id: String, title_text: String, verb_text: String, pos: Vector2, box_size: Vector2) -> void:
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

func _on_interacted(inter: Interactable) -> void:
	match inter.interaction_id:
		"Saida_Cidade":
			# Regra do Switch 015: no Ato 2 a volta fica bloqueada até resgatar o gatinho (017)
			if int(GameState.get_var("Ato", 1)) == 2 and GameState.get_switch("015_Floresta_em_chamas") and not GameState.get_switch("017_Gatinho_encontrado"):
				request_dialogue.emit([{
					"speaker": "Huwag",
					"expression": "worried",
					"text": "A fumaça e as brasas fecharam a entrada da trilha! Não posso voltar sem antes resgatar o gatinho na clareira."
				}], Callable())
			else:
				request_level_change.emit("res://scenes/levels/StreetPreview.tscn", "from_forest")

		"Entrada_Clareira":
			request_level_change.emit("res://scenes/levels/ForestClearing.tscn", "from_corridor")

func _draw() -> void:
	var act3 := GameState.is_unfiltered_act3()
	var mod := Color(0.68, 0.70, 0.68, 1.0) if act3 else Color.WHITE

	# 1. Solo de Grama e Trilha de Terra com Tilesets Reais (TX Tileset Grass + Floors_Tiles)
	draw_rect(Rect2(0, 0, 640, 360), Color("#365938") if not act3 else Color("#2F3532"))
	if _tex_grass_tiles != null:
		for gy in range(0, 360, 128):
			for gx in range(0, 640, 128):
				draw_texture_rect_region(_tex_grass_tiles, Rect2(gx, gy, 128, 128), Rect2(0, 0, 128, 128), mod)

	# Trilha central de terra batida e pedras
	draw_rect(Rect2(0, 132, 640, 152), Color("#8C6747") if not act3 else Color("#4E4A45"))
	if _tex_floors != null:
		for tx in range(0, 640, 96):
			var tw := mini(96, 640 - tx)
			draw_texture_rect_region(_tex_floors, Rect2(tx, 134, tw, 148), Rect2(160, 16, tw, 80), Color(0.92, 0.84, 0.72, 0.88) * mod)

	# Rochas e arbustos nas margens da trilha
	if _tex_rocks != null:
		for rx in [92, 276, 468, 572]:
			draw_texture_rect_region(_tex_rocks, Rect2(rx, 126, 28, 26), Rect2(36, 18, 32, 30), mod)
			draw_texture_rect_region(_tex_rocks, Rect2(rx + 36, 268, 24, 22), Rect2(100, 18, 32, 30), mod)

	# Árvores densas ao norte e ao sul usando TX Plant.png
	for x in range(16, 624, 54):
		_draw_tree(Vector2(x, 118), act3, (x / 54) % 2)
		_draw_tree(Vector2(x + 22, 342), act3, ((x / 54) + 1) % 2)

	# 1.5 Criaturas da trilha (Ato 1)
	for mob in forest_mobs:
		if bool(mob["alive"]):
			_draw_forest_mob(
				mob["pos"],
				int(mob["hp"]),
				int(mob["max_hp"]),
				float(mob["phase"]),
				float(mob["hurt_flash"])
			)

	# 2. Fogos sorteados (Ato 2 — Switch 015)
	for f in fire_hazards:
		if bool(f["active"]):
			_draw_fire_hazard(
				f["pos"],
				float(f["phase"]),
				int(f.get("hp", 50)),
				int(f.get("max_hp", 50)),
				float(f.get("hurt_flash", 0.0))
			)

	# 3. Boss perseguidor (Ato 1 — Switch 003)
	if pursuer_active:
		_draw_water_monster(pursuer_pos, pursuer_hp, pursuer_max_hp, pursuer_hurt_flash)

func _draw_tree(pos: Vector2, act3: bool, variant: int = 0) -> void:
	draw_circle(pos + Vector2(0, -2), 16.0, Color(0, 0, 0, 0.32))
	if _tex_plants != null:
		var mod := Color(0.66, 0.68, 0.66, 1.0) if act3 else Color.WHITE
		var src := Rect2(24, 14, 113, 139) if variant == 0 else Rect2(161, 17, 95, 136)
		draw_texture_rect_region(_tex_plants, Rect2(pos.x - 38, pos.y - 92, 76, 94), src, mod)
		return
	draw_rect(Rect2(pos.x - 6, pos.y - 16, 12, 22), Color("#6C4632"))
	draw_circle(Vector2(pos.x, pos.y - 28), 20.0, Color("#4DAA57") if not act3 else Color("#3E4641"))

func _draw_forest_mob(pos: Vector2, hp: int, max_hp: int, phase: float, hurt_flash: float) -> void:
	var flashing := hurt_flash > 0.0
	draw_circle(pos + Vector2(0, 8), 11.0, Color(0.04, 0.03, 0.08, 0.38))
	if _tex_mob_orc != null:
		var frame_idx := int(floor(phase * 1.6)) % 4
		var mod := Color(1.0, 0.45, 0.45, 1.0) if flashing else Color.WHITE
		draw_texture_rect_region(_tex_mob_orc, Rect2(pos.x - 18, pos.y - 26, 36, 36), Rect2(frame_idx * 32, 0, 32, 32), mod)
	else:
		draw_circle(pos, 12.0, Color("#FFF8E8") if flashing else Color("#2A9D8F"))
	var ratio := clampf(float(hp) / float(max_hp), 0.0, 1.0)
	draw_rect(Rect2(pos.x - 14, pos.y - 26, 28, 4), Color("#141824"))
	draw_rect(Rect2(pos.x - 13, pos.y - 25, 26.0 * ratio, 2), Color("#52B788"))

func _draw_fire_hazard(pos: Vector2, phase: float, hp: int, max_hp: int, hurt_flash: float) -> void:
	var flashing := hurt_flash > 0.0
	draw_circle(pos + Vector2(0, 4), 16.0, Color(1.0, 0.42, 0.1, 0.28))
	if _tex_fire_sheet != null:
		var frame_idx := int(floor(phase * 1.2)) % 4
		var mod := Color(1.0, 1.0, 1.0, 1.0) if not flashing else Color(1.0, 0.6, 0.6, 1.0)
		draw_texture_rect_region(_tex_fire_sheet, Rect2(pos.x - 18, pos.y - 34, 36, 46), Rect2(frame_idx * 32, 0, 32, 48), mod)
	else:
		draw_circle(pos, 14.0, Color("#FFBA08"))
	if hp < max_hp:
		var ratio := clampf(float(hp) / float(max_hp), 0.0, 1.0)
		draw_rect(Rect2(pos.x - 13, pos.y - 28, 26, 4), Color("#1B192E"))
		draw_rect(Rect2(pos.x - 12, pos.y - 27, 24.0 * ratio, 2), Color("#FF9F1C"))

func _draw_water_monster(pos: Vector2, hp: int, max_hp: int, hurt_flash: float = 0.0) -> void:
	var flashing := hurt_flash > 0.0
	draw_circle(pos + Vector2(0, 8), 16.0, Color(0, 0, 0, 0.4))
	if _tex_mob_shaman != null:
		var mod := Color(1.0, 0.5, 0.5, 1.0) if flashing else Color(0.55, 0.88, 1.0, 1.0)
		draw_texture_rect_region(_tex_mob_shaman, Rect2(pos.x - 22, pos.y - 32, 44, 44), Rect2(0, 0, 32, 32), mod)
	else:
		draw_circle(pos, 16.0, Color("#0077B6"))
	var ratio := clampf(float(hp) / float(max_hp), 0.0, 1.0)
	draw_rect(Rect2(pos.x - 18, pos.y - 32, 36, 5), Color("#1B192E"))
	draw_rect(Rect2(pos.x - 17, pos.y - 31, 34.0 * ratio, 3), Color("#4ECDC4"))
