extends Node2D

## ForestTrail — Trilha da Floresta de Agdangan (Atos 1, 2 e 3)
## Redesenhada na estética FNAF Minigames + Yume Nikki + Chrono Trigger + Pokémon GB.
## Mapa extenso (2560x768 / 160x48 tiles) com curvas, bifurcações, bolsões vazios de tensão
## e escalada de dificuldade intensa por encontros estratégicos de Santelmos (sem alterar o combate base).

signal request_level_change(target_scene: String, spawn_tag: String)
signal request_dialogue(pages: Array, callback: Callable)

const RetroLevelHelpers := preload("res://scripts/levels/retro_level_helpers.gd")
const NPC_SCENE := preload("res://scenes/characters/NpcEntity.tscn")
const NORMAL_TS := preload("res://assets/tilesets/retro/forest_fnaf_normal_tileset.tres")
const DISTORTED_TS := preload("res://assets/tilesets/retro/forest_fnaf_distorted_tileset.tres")

const MAP_W := 160
const MAP_H := 48

@onready var canvas_mod: CanvasModulate = $CanvasModulate
@onready var ground_normal: TileMapLayer = $GroundNormal
@onready var walls_normal: TileMapLayer = $WallsNormal
@onready var ground_distorted: TileMapLayer = $GroundDistorted
@onready var walls_distorted: TileMapLayer = $WallsDistorted
@onready var decals_layer: Node2D = $DecalsLayer
@onready var interactables_root: Node2D = $Interactables
@onready var ysort_obstacles: Node2D = $ObstaclesYsort
@onready var lights_layer: Node2D = $LightsLayer
@onready var fire_embers: CPUParticles2D = $FireEmbers
@onready var exit_area: Area2D = get_node_or_null("ExitToClearingArea")
@onready var exit_city_area: Area2D = get_node_or_null("ExitToCityArea")
@onready var player: PlayerController = get_node_or_null("ObstaclesYsort/PlayerHuwag")

var _normal_props: Array[Node2D] = []
var _distorted_props: Array[Node2D] = []
var _distorted_decals: Array[Node2D] = []
var _lights: Array[PointLight2D] = []
var _santelmos: Array[Node] = []
var _stalker_npc: NpcEntity = null
var _time_acc: float = 0.0


func _ready() -> void:
	if player:
		if GameState.spawn_tag == "from_clearing":
			player.position = Vector2(2480, 384)
			player.facing_dir = Vector2.LEFT
		else:
			player.position = Vector2(96, 384)
			player.facing_dir = Vector2.RIGHT
		player.set_camera_limits(Rect2i(0, 0, MAP_W * 16, MAP_H * 16))

	_build_forest_tilemaps()
	_build_forest_props_and_lights()
	_setup_interactables_and_pickups()
	_collect_santelmos()
	_spawn_higher_dose_stalker()

	if exit_area:
		exit_area.body_entered.connect(_on_exit_area_body_entered)
	if exit_city_area:
		exit_city_area.body_entered.connect(_on_exit_city_area_body_entered)

	GameState.perception_changed.connect(func(_m: int) -> void: _sync_forest_atmosphere())
	GameState.switch_changed.connect(func(_k: String, _v: bool) -> void: _sync_forest_atmosphere())
	if GameState.has_signal("higher_dose_changed"):
		GameState.higher_dose_changed.connect(func(active: bool) -> void: apply_higher_dose_world(active))

	_sync_forest_atmosphere()

	if has_node("/root/AudioManager"):
		var ato: int = int(GameState.get_var("Ato", 1))
		if GameState.is_unfiltered_act3():
			get_node("/root/AudioManager").play_ambience("act3_ambience")
		elif ato == 2 and GameState.get_switch("015_Floresta_em_chamas"):
			get_node("/root/AudioManager").play_ambience("afternoon_ambience")
		else:
			get_node("/root/AudioManager").play_ambience("night_forest")


func _process(delta: float) -> void:
	_time_acc += delta
	var higher := _is_higher_dose_active()
	for i in range(_lights.size()):
		var lt := _lights[i]
		if lt == null or not is_instance_valid(lt):
			continue
		var phase := float(i) * 1.37
		var base_e: float = float(lt.get_meta("base_energy", 0.72))
		var pulse := sin(_time_acc * 3.4 + phase) * 0.08
		if higher and fmod(_time_acc + phase, 5.1) > 4.75:
			pulse = -0.28
		lt.energy = maxf(0.14, base_e + pulse)


func apply_higher_dose_world(_active: bool) -> void:
	_sync_forest_atmosphere()


func _is_higher_dose_active() -> bool:
	return GameState.has_method("is_higher_dose") and GameState.is_higher_dose()


func _build_forest_tilemaps() -> void:
	for layer in [ground_normal, walls_normal]:
		layer.tile_set = NORMAL_TS
	for layer in [ground_distorted, walls_distorted]:
		layer.tile_set = DISTORTED_TS

	# Matriz booleana 160x48 para esculpir caminhos curvos, bifurcações e riacho
	var walkable: Array = []
	for x in range(MAP_W):
		var col: Array = []
		col.resize(MAP_H)
		col.fill(false)
		walkable.append(col)

	var carve := func(x0: int, y0: int, w: int, h: int) -> void:
		for x in range(maxi(0, x0), mini(MAP_W, x0 + w)):
			for y in range(maxi(0, y0), mini(MAP_H, y0 + h)):
				walkable[x][y] = true

	# 1. Portão oeste & clareira de entrada (mantém espaço norte x=24..41 livre abaixo de y=0..2)
	carve.call(0, 21, 5, 6)
	carve.call(2, 16, 32, 16)
	carve.call(24, 3, 18, 15)

	# 2. Bifurcação 1 -> Rota Norte (Serra das Cinzas, estreita e perigosa)
	carve.call(34, 6, 54, 11)

	# 3. Bifurcação 1 -> Rota Sul (Riacho da Cruz, pontes de madeira & abrigo)
	carve.call(26, 28, 16, 13)
	carve.call(40, 30, 48, 13)

	# 4. Bacia Central Silenciosa (Yume Nikki empty pocket)
	carve.call(84, 12, 20, 25)

	# 5. Bifurcação 2 -> Norte-Leste (Clareira Morta / Poço Seco)
	carve.call(102, 5, 38, 13)
	carve.call(130, 16, 10, 12)

	# 6. Desfiladeiro em Brasas & Portão Leste para a Lagoa
	carve.call(100, 29, 44, 13)
	carve.call(132, 20, 25, 14)
	carve.call(156, 21, 4, 6)

	# Obstáculos internos (rochedos & poço seco) preservando amplas rotas de desvio
	var solid_rock := func(x0: int, y0: int, w: int, h: int) -> void:
		for x in range(x0, x0 + w):
			for y in range(y0, y0 + h):
				walkable[x][y] = false
				for wl in [walls_normal, walls_distorted]:
					wl.set_cell(Vector2i(x, y), 0, Vector2i(5, 1))

	solid_rock.call(50, 10, 2, 2)
	solid_rock.call(69, 11, 2, 2)
	solid_rock.call(117, 9, 4, 3)   # Poço seco / cratera na clareira morta
	solid_rock.call(114, 33, 2, 2)
	solid_rock.call(126, 36, 2, 2)

	# Riachos cortando a Rota Sul em x=52..53 e x=68..69, cruzados por pontes em y=35..37
	for sx in [52, 53, 68, 69]:
		for sy in range(30, 43):
			if sy >= 35 and sy <= 37:
				continue
			walkable[sx][sy] = false
			var water_coord := Vector2i(3, 1) if (sy <= 31 or sy >= 41) else Vector2i(4, 1)
			for wl in [walls_normal, walls_distorted]:
				wl.set_cell(Vector2i(sx, sy), 0, water_coord)

	# Preenchimento do piso e barreiras vegetais/basalto
	for x in range(MAP_W):
		for y in range(MAP_H):
			for gl in [ground_normal, ground_distorted]:
				gl.set_cell(Vector2i(x, y), 0, Vector2i(3, 0))
			if not walkable[x][y]:
				var already_special := walls_normal.get_cell_source_id(Vector2i(x, y)) != -1
				if not already_special:
					var wall_coord := Vector2i(0, 1)
					if y > 2 and y < MAP_H - 3 and x > 1 and x < MAP_W - 2:
						if y + 1 < MAP_H and walkable[x][y + 1]:
							wall_coord = Vector2i(2, 1)  # Paredão basalto acima da trilha
						elif y - 1 >= 0 and walkable[x][y - 1]:
							wall_coord = Vector2i(1, 1)  # Crista de pedra abaixo da trilha
					for wl in [walls_normal, walls_distorted]:
						wl.set_cell(Vector2i(x, y), 0, wall_coord)
			else:
				# Seleciona tipo de chão walkable por bioma local
				var tile := Vector2i(1, 0)
				if (x + y * 3) % 7 == 0:
					tile = Vector2i(2, 0)
				if x >= 34 and x <= 87 and y <= 16:
					tile = Vector2i(7, 0) if (x + y) % 5 != 0 else Vector2i(4, 0)
				elif x >= 84 and x <= 103 and y >= 15 and y <= 33:
					tile = Vector2i(6, 0)
					if x >= 90 and x <= 96 and y >= 21 and y <= 27:
						tile = Vector2i(11, 0)
				elif (x == 52 or x == 53 or x == 68 or x == 69) and y >= 35 and y <= 37:
					tile = Vector2i(10, 0) # Pontes de madeira sobre o riacho
				elif x >= 49 and x <= 72 and y >= 31 and y <= 42:
					tile = Vector2i(8, 0) if (x + y) % 3 != 0 else Vector2i(9, 0)
				elif x >= 115 and x <= 122 and y >= 7 and y <= 13:
					tile = Vector2i(11, 0)
				for gl in [ground_normal, ground_distorted]:
					gl.set_cell(Vector2i(x, y), 0, tile)

	# Trilhas principais marcadas (leitura clara estilo Pokémon GB / Chrono Trigger)
	var paint_trail := func(x0: int, y0: int, w: int, h: int, coord: Vector2i) -> void:
		for gl in [ground_normal, ground_distorted]:
			RetroLevelHelpers.paint_rect(gl, x0, y0, w, h, coord)

	paint_trail.call(0, 23, 28, 3, Vector2i(4, 0))
	paint_trail.call(26, 11, 3, 26, Vector2i(4, 0))
	paint_trail.call(29, 11, 56, 3, Vector2i(4, 0))   # Trilha Norte
	paint_trail.call(29, 35, 56, 3, Vector2i(5, 0))   # Trilha Sul até riacho
	for gx in [52, 53, 68, 69]:
		paint_trail.call(gx, 35, 1, 3, Vector2i(10, 0)) # Reforça tábuas da ponte acima do chão
	paint_trail.call(85, 12, 3, 25, Vector2i(5, 0))   # Ligação na Bacia Central
	paint_trail.call(88, 23, 14, 3, Vector2i(4, 0))
	paint_trail.call(94, 10, 3, 14, Vector2i(5, 0))
	paint_trail.call(97, 10, 37, 2, Vector2i(5, 0))   # Ligação Poço Seco
	paint_trail.call(132, 11, 3, 18, Vector2i(4, 0))
	paint_trail.call(101, 35, 34, 3, Vector2i(7, 0))  # Desfiladeiro Leste em cinzas
	paint_trail.call(134, 23, 26, 3, Vector2i(4, 0))  # Reta final até o lago

	# Decals do fundo do poço seco na Clareira Morta (visual sem alterar colisão de borda)
	for gl in [ground_normal, ground_distorted]:
		RetroLevelHelpers.paint_rect(gl, 118, 10, 2, 1, Vector2i(0, 0))

	walls_distorted.collision_enabled = false


func _build_forest_props_and_lights() -> void:
	# Árvores de copa densa nas bordas e divisórias internas (fora das áreas caminháveis)
	var canopy_spots := [
		Vector2(110, 210), Vector2(210, 220), Vector2(360, 210),
		Vector2(760, 330), Vector2(880, 350), Vector2(1010, 330), Vector2(1150, 360),
		Vector2(1190, 420), Vector2(1290, 330), Vector2(1540, 140),
		Vector2(1820, 330), Vector2(1960, 350), Vector2(2080, 340),
		Vector2(180, 560), Vector2(330, 570), Vector2(1420, 620),
		Vector2(2260, 140), Vector2(2460, 260), Vector2(2460, 520)
	]
	for pos in canopy_spots:
		_add_dual_prop("pine_canopy_cluster", pos, ysort_obstacles, Vector2(0, -24))

	# Árvores secas retorcidas em torno da serra das cinzas e poço seco
	var dead_spots := [
		Vector2(670, 95), Vector2(1100, 95), Vector2(1300, 265),
		Vector2(1790, 110), Vector2(1960, 96), Vector2(2120, 115),
		Vector2(1760, 620), Vector2(2040, 610)
	]
	for pos in dead_spots:
		_add_dual_prop("dead_gnarled_tree", pos, ysort_obstacles, Vector2(0, -20))

	# Manchas ambientais no piso (Ato 2 Dose Maior destaca sangue/cinzas & olhos Yume Nikki)
	var stain_spots := [
		Vector2(450, 384), Vector2(880, 180), Vector2(1488, 384),
		Vector2(1904, 176), Vector2(2240, 384), Vector2(2360, 384)
	]
	for pos in stain_spots:
		var st_n := RetroLevelHelpers.create_prop_sprite("floor_stain", false)
		st_n.position = pos
		decals_layer.add_child(st_n)
		_normal_props.append(st_n)

		var st_d := RetroLevelHelpers.create_prop_sprite("floor_stain", true)
		st_d.position = pos
		st_d.visible = false
		decals_layer.add_child(st_d)
		_distorted_props.append(st_d)

	for eye_pos in [
		Vector2(760, 250), Vector2(1488, 330), Vector2(1488, 438),
		Vector2(1904, 130), Vector2(2240, 330), Vector2(2384, 332)
	]:
		var eye := RetroLevelHelpers.create_prop_sprite("yume_eye_rune", true)
		eye.position = eye_pos
		eye.visible = false
		decals_layer.add_child(eye)
		_distorted_decals.append(eye)

	# Iluminação esparsa de horror retrô — áreas intencionalmente escuras entre focos de luz
	var light_defs := [
		{"pos": Vector2(120, 384), "col": Color(0.58, 0.72, 0.88), "e": 0.85, "s": 2.5},
		{"pos": Vector2(544, 368), "col": Color(0.62, 0.76, 0.90), "e": 0.76, "s": 2.3},
		{"pos": Vector2(900, 180), "col": Color(0.95, 0.48, 0.22), "e": 0.84, "s": 2.4},
		{"pos": Vector2(848, 560), "col": Color(0.65, 0.82, 0.92), "e": 0.86, "s": 2.5},
		{"pos": Vector2(1088, 560), "col": Color(0.55, 0.82, 0.92), "e": 0.88, "s": 2.6},
		{"pos": Vector2(1488, 384), "col": Color(0.76, 0.82, 0.90), "e": 0.82, "s": 2.7},
		{"pos": Vector2(1904, 176), "col": Color(0.72, 0.78, 0.88), "e": 0.78, "s": 2.4},
		{"pos": Vector2(1952, 560), "col": Color(0.96, 0.45, 0.20), "e": 0.84, "s": 2.4},
		{"pos": Vector2(2240, 384), "col": Color(0.96, 0.42, 0.20), "e": 0.90, "s": 2.8},
		{"pos": Vector2(2384, 384), "col": Color(0.98, 0.40, 0.18), "e": 0.92, "s": 2.6}
	]
	for def in light_defs:
		var lt := RetroLevelHelpers.create_point_light(def["pos"], def["col"], def["e"], def["s"])
		lt.set_meta("base_energy", def["e"])
		lights_layer.add_child(lt)
		_lights.append(lt)


func _add_dual_prop(kind: String, pos: Vector2, parent_node: Node2D, offset_px: Vector2 = Vector2.ZERO) -> void:
	var n := RetroLevelHelpers.create_prop_sprite(kind, false)
	n.position = pos
	n.offset = offset_px
	parent_node.add_child(n)
	_normal_props.append(n)

	var d := RetroLevelHelpers.create_prop_sprite(kind, true)
	d.position = pos
	d.offset = offset_px
	d.visible = false
	parent_node.add_child(d)
	_distorted_props.append(d)


func _setup_interactables_and_pickups() -> void:
	var signs := [
		{
			"id": "Placa_Entrada",
			"title": "Aviso BFP na Entrada",
			"verb": "Ler Placa",
			"pos": Vector2(220, 336)
		},
		{
			"id": "Placa_Bifurcacao",
			"title": "Marco da Bifurcação",
			"verb": "Examinar",
			"pos": Vector2(544, 304)
		},
		{
			"id": "Placa_Bacia",
			"title": "Pedra do Centro",
			"verb": "Examinar",
			"pos": Vector2(1488, 328)
		}
	]
	for s in signs:
		_add_dual_prop("wooden_signpost", s["pos"], ysort_obstacles, Vector2(0, -10))
		_create_interactable(s["id"], s["title"], s["verb"], s["pos"], 26.0, func() -> void:
			_on_sign_interacted(s["id"])
		)

	_create_calm_pickup("pickup_trail_creek", Vector2(976, 628))
	_create_calm_pickup("pickup_trail_pit", Vector2(2016, 224))


func _create_calm_pickup(pickup_key: String, pos: Vector2) -> void:
	if GameState.get_self_switch("forest_trail", pickup_key):
		return
	var holder := Node2D.new()
	holder.position = pos
	ysort_obstacles.add_child(holder)

	var spr := RetroLevelHelpers.create_prop_sprite("calm_drop_pickup", false)
	spr.offset = Vector2(0, -6)
	holder.add_child(spr)

	var inter := Interactable.new()
	inter.interaction_id = pickup_key
	inter.title = "Cápsula Calmante"
	inter.verb = "Coletar"
	inter.collision_layer = 4
	inter.collision_mask = 2
	var col := CollisionShape2D.new()
	var sh := CircleShape2D.new()
	sh.radius = 24.0
	col.shape = sh
	inter.add_child(col)
	inter.interacted.connect(func(_i: Interactable) -> void:
		if GameState.get_self_switch("forest_trail", pickup_key):
			return
		GameState.set_self_switch("forest_trail", pickup_key, true)
		GameState.add_item("gota_calmante", 1)
		holder.visible = false
		inter.monitoring = false
		inter.monitorable = false
		if has_node("/root/AudioManager"):
			get_node("/root/AudioManager").play_sfx("ui_select")
		request_dialogue.emit([
			{
				"speaker": "Huwag Matitiis",
				"expression": "neutral",
				"text": "Encontrei uma Cápsula Calmante caída entre as pedras (+1 Cura em inventário; pressione [C] ou abra o menu de apoio para usar quando precisar)."
			}
		], Callable())
	)
	holder.add_child(inter)


func _create_interactable(id: String, title_txt: String, verb_txt: String, pos: Vector2, rad: float, cb: Callable) -> Interactable:
	var inter := Interactable.new()
	inter.name = id
	inter.interaction_id = id
	inter.title = title_txt
	inter.verb = verb_txt
	inter.position = pos
	inter.collision_layer = 4
	inter.collision_mask = 2
	var col := CollisionShape2D.new()
	var sh := CircleShape2D.new()
	sh.radius = rad
	col.shape = sh
	inter.add_child(col)
	inter.interacted.connect(func(_i: Interactable) -> void: cb.call())
	interactables_root.add_child(inter)
	return inter


func _on_sign_interacted(id: String) -> void:
	var higher := _is_higher_dose_active()
	var act3 := GameState.is_unfiltered_act3()
	match id:
		"Placa_Entrada":
			var txt := (
				"A fita de isolamento da BFP está partida ao vento frio. Ninguém mais vigia a trilha."
				if act3 else (
					"A tinta na madeira parece derreter em letras repetidas: NÃO ERA PARA VOCÊ TER SAÍDO DO GALPÃO."
					if higher else
					"Aviso BFP: Trilha da Floresta de Agdangan. Relatos de focos térmicos erráticos — evite prosseguir sem apoio."
				)
			)
			request_dialogue.emit([{"speaker": "Huwag Matitiis", "expression": "scared" if higher else "neutral", "text": txt}], Callable())

		"Placa_Bifurcacao":
			var txt := (
				"Seta Norte: Serra das Cinzas (caminho mais curto, calor intenso). Seta Sul: Riacho da Cruz (contorno longo com vestígios de água)."
				if not higher else
				"Uma das setas foi riscada com carvão: NENHUM DOS DOIS CAMINHOS VOLTA ANTES DO FOGO."
			)
			request_dialogue.emit([{"speaker": "Huwag Matitiis", "expression": "worried", "text": txt}], Callable())

		"Placa_Bacia":
			var txt := (
				"Três nomes gravados às pressas na base da pedra antiga... O vento silencia por um instante."
				if act3 else (
					"Três marcas frescas de mão cheia de fuligem apontam direto para as minhas próprias botas."
					if higher else
					"Uma bacia de pedra fria no meio da floresta densa. Aqui o ar parece parado antes da garganta leste."
				)
			)
			request_dialogue.emit([{"speaker": "Huwag Matitiis", "expression": "scared" if higher else "worried", "text": txt}], Callable())


func _collect_santelmos() -> void:
	_santelmos.clear()
	if ysort_obstacles == null:
		return
	for ch in ysort_obstacles.get_children():
		if ch is SantelmoEnemy or ch.is_in_group("enemies"):
			_santelmos.append(ch)


func _spawn_higher_dose_stalker() -> void:
	if _stalker_npc != null or ysort_obstacles == null:
		return
	var npc: NpcEntity = NPC_SCENE.instantiate() as NpcEntity
	if npc == null:
		return
	npc.name = "NPC_Vulto_Bosque"
	npc.npc_id = "NPC_Vulto_Bosque"
	npc.interact_prompt = "Vulto Calcinado"
	npc.interact_verb = "Confrontar"
	npc.position = Vector2(2240, 384)
	npc.facing_dir = "left"
	npc.hostile_move_speed = 92.0
	npc.hostile_max_hp = 130
	npc.hostile_attack_damage = 16
	npc.normal_sheet_path = "res://assets/characters/sprites/distorted_bombeiro_sheet.png"
	npc.distorted_sheet_path = "res://assets/characters/sprites/distorted_bombeiro_sheet.png"
	npc.npc_interacted.connect(func(_id: String) -> void:
		if npc.is_hostile or npc.is_defeated:
			return
		request_dialogue.emit([
			{
				"speaker": "Bombeiro",
				"expression": "distorted",
				"text": "O vulto sem rosto cheira a querosene e papel queimado no meio da trilha.\n\"As chamas daqui são todas suas, Huwag. Vai passar por cima de nós outra vez para fingir que salvou o lago?\"",
				"choices": [
					"\"Eu não vou apagar vocês da minha cabeça... saia do caminho, por favor.\"",
					"\"Você não existe! Sai da frente agora!\""
				],
				"conflict_choices": {1: "NPC_Vulto_Bosque"}
			}
		], func(choice: int) -> void:
			if choice == 0:
				npc.visible = false
				npc.set_physics_process(false)
				var ia := npc.get_node_or_null("InteractArea")
				if ia:
					ia.visible = false
				request_dialogue.emit([{
					"speaker": "Huwag Matitiis",
					"expression": "worried",
					"text": "A silhueta se desfez entre as árvores como fumaça fria."
				}], Callable())
		)
	)
	ysort_obstacles.add_child(npc)
	_stalker_npc = npc


func _on_dialogue_conflict_triggered(target_id: String, _context: Dictionary) -> void:
	if target_id == "NPC_Vulto_Bosque" and _stalker_npc != null and is_instance_valid(_stalker_npc):
		_stalker_npc.turn_hostile()
		if has_node("/root/AudioManager"):
			get_node("/root/AudioManager").play_sfx("vhs_glitch")


func _sync_forest_atmosphere() -> void:
	var ato: int = int(GameState.get_var("Ato", 1))
	var act3 := GameState.is_unfiltered_act3()
	var higher := _is_higher_dose_active()
	var fire_active := (ato == 2 and GameState.get_switch("015_Floresta_em_chamas"))

	ground_normal.visible = not higher
	walls_normal.visible = not higher
	ground_distorted.visible = higher
	walls_distorted.visible = higher

	for sp in _normal_props:
		if sp and is_instance_valid(sp):
			sp.visible = not higher
	for sp in _distorted_props:
		if sp and is_instance_valid(sp):
			sp.visible = higher
	for dec in _distorted_decals:
		if dec and is_instance_valid(dec):
			dec.visible = higher

	if canvas_mod:
		if act3:
			canvas_mod.color = Color(0.62, 0.64, 0.67, 1.0)
		elif higher:
			canvas_mod.color = Color(0.35, 0.22, 0.27, 1.0)
		elif fire_active:
			canvas_mod.color = Color(0.54, 0.36, 0.32, 1.0)
		elif GameState.is_afternoon:
			canvas_mod.color = Color(0.50, 0.42, 0.46, 1.0)
		else:
			canvas_mod.color = Color(0.45, 0.49, 0.57, 1.0)

	if fire_embers:
		fire_embers.emitting = not act3 and (fire_active or higher)
		fire_embers.color = Color(0.95, 0.18, 0.22, 0.85) if higher else Color(1.0, 0.52, 0.14, 0.78)

	# Espiritos de fogo desaparecem no Ato 3 (revelação sem ilusões sobrenaturais)
	for s in _santelmos:
		if s == null or not is_instance_valid(s):
			continue
		var dead: bool = ("current_state" in s and int(s.current_state) == 5)
		var show_enemy: bool = not act3 and not dead
		s.visible = show_enemy
		s.set_physics_process(show_enemy)
		if s is CollisionObject2D:
			s.collision_layer = 4 if show_enemy else 0
			s.collision_mask = 3 if show_enemy else 0
		var hb: Area2D = s.get_node_or_null("Hurtbox") as Area2D
		var atk: Area2D = s.get_node_or_null("Hitbox") as Area2D
		if hb:
			hb.monitoring = show_enemy
			hb.monitorable = show_enemy
		if atk:
			atk.monitoring = show_enemy
			atk.monitorable = show_enemy

	if _stalker_npc != null and is_instance_valid(_stalker_npc):
		var show_stalker: bool = higher and not _stalker_npc.is_defeated
		_stalker_npc.visible = show_stalker
		_stalker_npc.set_physics_process(show_stalker)
		var ia := _stalker_npc.get_node_or_null("InteractArea")
		if ia:
			ia.visible = show_stalker and not _stalker_npc.is_hostile
		if show_stalker:
			_stalker_npc.set_distorted_state(true)

	for lt in _lights:
		if lt == null or not is_instance_valid(lt):
			continue
		if act3:
			lt.color = Color(0.84, 0.86, 0.88)
		elif higher:
			lt.color = Color(0.88, 0.14, 0.20)
		elif fire_active:
			lt.color = Color(1.0, 0.46, 0.18)


func _on_exit_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		request_level_change.emit("res://scenes/levels/forest_clearing.tscn", "from_trail")


func _on_exit_city_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		request_level_change.emit("res://scenes/levels/StreetPreview.tscn", "from_forest")
