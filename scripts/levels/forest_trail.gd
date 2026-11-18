extends Node2D

## ForestTrail — Trilha da Floresta de Agdangan (Atos 1, 2 e 3)
## Redesenhada na estética FNAF Minigames + Yume Nikki + Chrono Trigger + Pokémon GB.
## Mapa extenso (2560x768 / 160x48 tiles) com curvas, bifurcações, bolsões vazios de tensão
## e escalada de dificuldade intensa por encontros estratégicos de Santelmos (sem alterar o combate base).

signal request_level_change(target_scene: String, spawn_tag: String)
signal request_dialogue(pages: Array, callback: Callable)

const RetroLevelHelpers := preload("res://scripts/levels/retro_level_helpers.gd")
const V2TileCatalog := preload("res://scripts/levels/v2_tile_catalog.gd")
const AtmosphereRig := preload("res://scripts/levels/atmosphere_rig.gd")
const NPC_SCENE := preload("res://scenes/characters/NpcEntity.tscn")
const SANTELMO_SCENE := preload("res://scenes/enemies/santelmo.tscn")
const NORMAL_TS := preload("res://assets/tilesets/v2/forest_v2_normal_tileset.tres")
const DISTORTED_TS := preload("res://assets/tilesets/v2/forest_v2_distorted_tileset.tres")
const ACT3_TS := preload("res://assets/tilesets/v2/forest_v2_act3_tileset.tres")

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
var _ambient_dust: CPUParticles2D = null
var _understory_layer: TileMapLayer = null
var _canopy_layer: TileMapLayer = null
var _canopy_material: ShaderMaterial = null
var _fog_overlay: ColorRect = null
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
	_spawn_expanded_forest_enemies()
	_collect_santelmos()
	_spawn_higher_dose_stalker()

	if exit_area:
		exit_area.body_entered.connect(_on_exit_area_body_entered)
	if exit_city_area:
		exit_city_area.body_entered.connect(_on_exit_city_area_body_entered)

	GameState.perception_changed.connect(func(_m: int) -> void: _sync_forest_atmosphere())
	GameState.switch_changed.connect(func(_k: String, _v: bool) -> void: _sync_forest_atmosphere())
	if GameState.has_signal("day_period_changed"):
		GameState.day_period_changed.connect(func(_p: String) -> void: _sync_forest_atmosphere())
	if GameState.has_signal("higher_dose_changed"):
		GameState.higher_dose_changed.connect(func(active: bool) -> void: apply_higher_dose_world(active))

	_sync_forest_atmosphere()

	if has_node("/root/AudioManager"):
		var am = get_node("/root/AudioManager")
		if am.has_method("sync_adaptive_soundtrack"):
			am.call("sync_adaptive_soundtrack", "forest_trail", false)
		else:
			var ato: int = int(GameState.get_var("Ato", 1))
			if GameState.is_unfiltered_act3():
				am.play_ambience("act3_ambience")
			elif ato == 2 and GameState.get_switch("015_Floresta_em_chamas"):
				am.play_ambience("afternoon_ambience")
			else:
				am.play_ambience("night_forest")


func _process(delta: float) -> void:
	_time_acc += delta
	if _canopy_material != null and player != null and is_instance_valid(player):
		_canopy_material.set_shader_parameter("player_world_pos", player.global_position)
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
	var f_cat := V2TileCatalog.FOREST_TILES
	var solid_rock := func(x0: int, y0: int, w: int, h: int) -> void:
		for x in range(x0, x0 + w):
			for y in range(y0, y0 + h):
				walkable[x][y] = false
				for wl in [walls_normal, walls_distorted]:
					wl.set_cell(Vector2i(x, y), 0, f_cat["rock_round_a"])

	solid_rock.call(50, 10, 2, 2)
	solid_rock.call(69, 11, 2, 2)
	solid_rock.call(117, 9, 4, 3)   # Poço seco / cratera na clareira morta
	solid_rock.call(114, 33, 2, 2)
	solid_rock.call(126, 36, 2, 2)

	# Riachos animados cortando a Rota Sul em x=52..53 e x=68..69, cruzados por pontes em y=35..37
	for sx in [52, 53, 68, 69]:
		for sy in range(30, 43):
			if sy >= 35 and sy <= 37:
				continue
			walkable[sx][sy] = false
			var water_coord: Vector2i = f_cat["waterfall_top"] if sy == 30 else (f_cat["waterfall_mid"] if sy == 31 else f_cat["water_deep_anim"])
			for wl in [walls_normal, walls_distorted]:
				wl.set_cell(Vector2i(sx, sy), 0, water_coord)

	# Preenchimento 100% opaco do piso e barreiras de penhasco com forest_v2 (16x16, zero buracos!)
	for x in range(MAP_W):
		for y in range(MAP_H):
			var base_grass: Vector2i = f_cat["grass_a"] if ((x + y) % 2 == 0) else f_cat["grass_b"]
			for gl in [ground_normal, ground_distorted]:
				gl.set_cell(Vector2i(x, y), 0, base_grass)
			if not walkable[x][y]:
				var already_special := walls_normal.get_cell_source_id(Vector2i(x, y)) != -1
				if not already_special:
					# Apenas as células de borda junto à trilha recebem penhasco com colisão física; o interior recebe vegetação densa
					var near_walkable := false
					for dy in range(-1, 2):
						for dx in range(-1, 2):
							var nx: int = x + dx
							var ny: int = y + dy
							if nx >= 0 and nx < MAP_W and ny >= 0 and ny < MAP_H and walkable[nx][ny]:
								near_walkable = true
								break
						if near_walkable:
							break
					if near_walkable:
						var wall_coord: Vector2i = f_cat["cliff_face_mid"] if (y + 1 < MAP_H and walkable[x][y + 1]) else f_cat["cliff_top_mid"]
						for wl in [walls_normal, walls_distorted]:
							wl.set_cell(Vector2i(x, y), 0, wall_coord)
			else:
				var tile: Vector2i = f_cat["grass_a"]
				if (x + y * 3) % 5 == 0:
					tile = f_cat["grass_b"]
				elif (x * 5 + y) % 7 == 0:
					tile = f_cat["needle_grass_a"]
				if x >= 34 and x <= 87 and y <= 16:
					tile = f_cat["soil_dark"] if (x + y) % 4 != 0 else f_cat["soil_a"]
				elif x >= 84 and x <= 103 and y >= 15 and y <= 33:
					tile = f_cat["needle_grass_b"]
					if x >= 90 and x <= 96 and y >= 21 and y <= 27:
						tile = f_cat["mud_patch_center"]
				elif (x == 52 or x == 53 or x == 68 or x == 69) and y >= 35 and y <= 37:
					tile = f_cat["bridge_v_mid_l"] if x in [52, 68] else f_cat["bridge_v_mid_r"]
				elif x >= 49 and x <= 72 and y >= 31 and y <= 42:
					tile = f_cat["grass_c"] if (x + y) % 3 != 0 else f_cat["needle_grass_a"]
				elif x >= 115 and x <= 122 and y >= 7 and y <= 13:
					tile = f_cat["mud_patch_center"]
				for gl in [ground_normal, ground_distorted]:
					gl.set_cell(Vector2i(x, y), 0, tile)

	# Trilhas principais marcadas com terra batida e lama (forest_v2)
	var paint_trail := func(x0: int, y0: int, w: int, h: int, coord: Vector2i) -> void:
		for gl in [ground_normal, ground_distorted]:
			V2TileCatalog.fill_rect(gl, Rect2i(x0, y0, w, h), coord)

	paint_trail.call(0, 23, 28, 3, f_cat["soil_a"])
	paint_trail.call(26, 11, 3, 26, f_cat["soil_a"])
	paint_trail.call(29, 11, 56, 3, f_cat["soil_b"])
	paint_trail.call(29, 35, 56, 3, f_cat["soil_a"])
	for gx in [52, 53, 68, 69]:
		var b_coord: Vector2i = f_cat["bridge_v_mid_l"] if gx in [52, 68] else f_cat["bridge_v_mid_r"]
		paint_trail.call(gx, 35, 1, 3, b_coord)
	paint_trail.call(85, 12, 3, 25, f_cat["soil_b"])
	paint_trail.call(88, 23, 14, 3, f_cat["soil_a"])
	paint_trail.call(94, 10, 3, 14, f_cat["soil_b"])
	paint_trail.call(97, 10, 37, 2, f_cat["soil_b"])
	paint_trail.call(132, 11, 3, 18, f_cat["soil_a"])
	paint_trail.call(101, 35, 34, 3, f_cat["soil_dark"])
	paint_trail.call(134, 23, 26, 3, f_cat["soil_a"])

	# Camada de sub-bosque + copas de árvores em múltiplas camadas densas + neblina fog_drift
	_setup_v2_canopy_and_fog(walkable)

	walls_distorted.collision_enabled = false


func _setup_v2_canopy_and_fog(walkable: Array) -> void:
	var f_cat := V2TileCatalog.FOREST_TILES
	var active_ts: TileSet = ACT3_TS if GameState.is_unfiltered_act3() else (DISTORTED_TS if _is_higher_dose_active() else NORMAL_TS)

	if _understory_layer == null:
		_understory_layer = TileMapLayer.new()
		_understory_layer.name = "V2UnderstoryLayer"
		_understory_layer.z_index = 1
		_understory_layer.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_understory_layer.collision_enabled = false
		add_child(_understory_layer)
	_understory_layer.tile_set = active_ts
	_understory_layer.clear()

	if _canopy_layer == null:
		_canopy_layer = TileMapLayer.new()
		_canopy_layer.name = "V2CanopyLayer"
		_canopy_layer.z_index = 4
		_canopy_layer.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_canopy_layer.collision_enabled = false
		_canopy_material = AtmosphereRig.create_canopy_material(36.0, 0.36)
		_canopy_layer.material = _canopy_material
		add_child(_canopy_layer)
	_canopy_layer.tile_set = active_ts
	_canopy_layer.clear()

	# Cercas de madeira rústica e vegetação rasteira (samambaias, cogumelos, pedras e tocos) no sub-bosque
	for fx in range(4, 22, 3):
		_understory_layer.set_cell(Vector2i(fx, 22), 0, f_cat["fence_left"])
		_understory_layer.set_cell(Vector2i(fx + 1, 22), 0, f_cat["fence_mid"])
		_understory_layer.set_cell(Vector2i(fx + 2, 22), 0, f_cat["fence_right"])

	for gx in range(2, MAP_W - 3, 2):
		for gy in range(2, MAP_H - 3, 2):
			if walkable[gx][gy]:
				if (gx * 11 + gy * 7) % 19 == 0 and gy > 4 and gy < MAP_H - 4:
					_understory_layer.set_cell(Vector2i(gx, gy), 0, f_cat["pebbles"])
				continue
			var h := (gx * 13 + gy * 17) % 9
			if h == 0:
				_understory_layer.set_cell(Vector2i(gx, gy), 0, f_cat["fern_a"])
			elif h == 1:
				_understory_layer.set_cell(Vector2i(gx, gy), 0, f_cat["fern_b"])
			elif h == 2:
				_understory_layer.set_cell(Vector2i(gx, gy), 0, f_cat["mushrooms_a"])
			elif h == 3 and gx + 1 < MAP_W and gy + 1 < MAP_H and not walkable[gx + 1][gy + 1]:
				V2TileCatalog.stamp_rect(_understory_layer, Vector2i(gx, gy), f_cat["stump_rooted"], Vector2i(2, 2))
			elif h == 4 and gx + 1 < MAP_W and gy + 1 < MAP_H and not walkable[gx + 1][gy + 1]:
				V2TileCatalog.stamp_rect(_understory_layer, Vector2i(gx, gy), f_cat["moss_boulder"], Vector2i(2, 2))

	# Preenchimento denso em 2 camadas de árvores escalonadas (cobrindo todas as margens fora da trilha de terra!)
	for gy in range(0, MAP_H - 5, 3):
		var row_shift := (gy % 2) * 2
		for gx in range(0, MAP_W - 4, 3):
			var tx := gx + row_shift
			if tx >= MAP_W - 3:
				continue
			# Mantém livres apenas as trilhas principais de terra/pontes e um buffer de 1 tile ao redor delas
			var on_main_path := false
			for by in range(maxi(0, gy + 2), mini(MAP_H, gy + 6)):
				for bx in range(maxi(0, tx - 1), mini(MAP_W, tx + 4)):
					var gcell := ground_normal.get_cell_atlas_coords(Vector2i(bx, by))
					var wcell := walls_normal.get_cell_atlas_coords(Vector2i(bx, by))
					if gcell in [f_cat["soil_a"], f_cat["soil_b"], f_cat["soil_dark"], f_cat["bridge_v_mid_l"], f_cat["bridge_v_mid_r"]]:
						on_main_path = true
						break
					if wcell in [f_cat["water_deep_anim"], f_cat["waterfall_top"], f_cat["waterfall_mid"], f_cat["rock_round_a"]]:
						on_main_path = true
						break
				if on_main_path:
					break
			if on_main_path:
				continue

			var pick := (tx * 7 + gy * 5) % 6
			var target_layer: TileMapLayer = _canopy_layer if ((tx + gy) % 2 == 0) else _understory_layer
			if pick == 0 or pick == 1:
				V2TileCatalog.stamp_rect(target_layer, Vector2i(tx, gy), f_cat["pine_dark"], Vector2i(3, 6))
			elif pick == 2:
				V2TileCatalog.stamp_rect(target_layer, Vector2i(tx, gy), f_cat["pine_withered"], Vector2i(3, 6))
			elif pick == 3 and tx + 4 < MAP_W:
				V2TileCatalog.stamp_rect(target_layer, Vector2i(tx, gy), f_cat["tree_gnarled_mid"], Vector2i(5, 6))
			else:
				V2TileCatalog.stamp_rect(target_layer, Vector2i(tx + 1, gy), f_cat["pine_slender"], Vector2i(1, 6))

	# Árvores Anciãs monumentais (14x18) nos grandes bolsões da floresta
	V2TileCatalog.stamp_rect(_canopy_layer, Vector2i(34, 16), f_cat["ancient_tree"], Vector2i(14, 18))
	V2TileCatalog.stamp_rect(_canopy_layer, Vector2i(104, 14), f_cat["ancient_tree"], Vector2i(14, 18))

	if _fog_overlay == null:
		_fog_overlay = AtmosphereRig.create_fog_overlay(Rect2(0, 0, MAP_W * 16, MAP_H * 16), Color(0.16, 0.22, 0.20, 1.0), 0.14)
		add_child(_fog_overlay)


func _build_forest_props_and_lights() -> void:
	# Poeira e esporos flutuantes contínuos na floresta (árvores e vegetação vêm 100% das camadas v2)
	_ambient_dust = CPUParticles2D.new()
	_ambient_dust.name = "ForestAmbientDust"
	_ambient_dust.position = Vector2(1280, 384)
	_ambient_dust.z_index = 4
	_ambient_dust.amount = 90
	_ambient_dust.lifetime = 5.0
	_ambient_dust.preprocess = 2.0
	_ambient_dust.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_ambient_dust.emission_rect_extents = Vector2(1240, 340)
	_ambient_dust.direction = Vector2(0.7, -0.3)
	_ambient_dust.spread = 45.0
	_ambient_dust.gravity = Vector2(1.5, -3.5)
	_ambient_dust.initial_velocity_min = 5.0
	_ambient_dust.initial_velocity_max = 15.0
	_ambient_dust.scale_amount_min = 1.5
	_ambient_dust.scale_amount_max = 2.5
	_ambient_dust.color = Color(0.75, 0.85, 0.78, 0.30)
	add_child(_ambient_dust)

	# Manchas ambientais no piso (Ato 2 Dose Maior destaca sangue/cinzas & olhos Yume Nikki)
	var stain_spots := [
		Vector2(450, 384), Vector2(880, 180), Vector2(1488, 384),
		Vector2(1904, 176), Vector2(2240, 384), Vector2(2360, 384)
	]
	for pos in stain_spots:
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

	if kind in ["pine_canopy_cluster", "dead_gnarled_tree", "overgrown_weeds", "corner_shrub"]:
		var phase := pos.x * 0.05 + pos.y * 0.02
		var strength := 1.0 if kind == "dead_gnarled_tree" else 1.75
		var speed := 1.4 if kind == "dead_gnarled_tree" else 1.9
		RetroLevelHelpers.apply_wind_sway(n, phase, strength, speed, 0.0)
		RetroLevelHelpers.apply_wind_sway(d, phase, strength * 1.15, speed * 1.25, 0.7)


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

	if not GameState.is_unfiltered_act3():
		_create_interactable("Vestigios_Santelmo", "Brasas de Santelmo", "Observar", Vector2(308, 392), 26.0, func() -> void:
			_on_sign_interacted("Vestigios_Santelmo")
		)


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

		"Vestigios_Santelmo":
			if higher:
				request_dialogue.emit([
					{
						"speaker": "Santelmo",
						"expression": "distorted",
						"text": "As línguas de fogo crepitam em voz aguda entre os galhos secos:\n\"Corre na frente, Huwag... deixa a brasa alcançar o resto da equipe outra vez.\""
					}
				], Callable())
			else:
				request_dialogue.emit([
					{
						"speaker": "Santelmo",
						"text": "(Uma chama errante paira sobre as folhas úmidas sem queimá-las. O clarão zune como rádio fora de sintonia — água e golpes precisos podem apagá-lo.)"
					}
				], Callable())


func _spawn_expanded_forest_enemies() -> void:
	if ysort_obstacles == null:
		return
	var extra_spawns := [
		{"name": "Santelmo4", "pos": Vector2(310, 384), "mode": "patrol", "waypoints": [Vector2(240, 384), Vector2(390, 384)], "alpha": false},
		{"name": "Santelmo5", "pos": Vector2(440, 280), "mode": "ambush", "waypoints": [], "alpha": false},
		{"name": "Santelmo6", "pos": Vector2(680, 192), "mode": "patrol", "waypoints": [Vector2(580, 192), Vector2(780, 192)], "alpha": false},
		{"name": "Santelmo7", "pos": Vector2(1120, 192), "mode": "patrol", "waypoints": [Vector2(1010, 192), Vector2(1240, 192)], "alpha": true},
		{"name": "Santelmo8", "pos": Vector2(640, 576), "mode": "patrol", "waypoints": [Vector2(540, 576), Vector2(760, 576)], "alpha": false},
		{"name": "Santelmo9", "pos": Vector2(960, 576), "mode": "ambush", "waypoints": [], "alpha": false},
		{"name": "Santelmo10", "pos": Vector2(1220, 576), "mode": "patrol", "waypoints": [Vector2(1150, 576), Vector2(1310, 576)], "alpha": true},
		{"name": "Santelmo11", "pos": Vector2(1376, 280), "mode": "patrol", "waypoints": [Vector2(1376, 210), Vector2(1376, 480)], "alpha": false},
		{"name": "Santelmo12", "pos": Vector2(1480, 384), "mode": "wander", "waypoints": [], "alpha": true},
		{"name": "Santelmo13", "pos": Vector2(1580, 440), "mode": "ambush", "waypoints": [], "alpha": false},
		{"name": "Santelmo14", "pos": Vector2(1780, 176), "mode": "patrol", "waypoints": [Vector2(1660, 176), Vector2(1980, 176)], "alpha": false},
		{"name": "Santelmo15", "pos": Vector2(2040, 576), "mode": "patrol", "waypoints": [Vector2(1900, 576), Vector2(2140, 576)], "alpha": true},
		{"name": "Santelmo16", "pos": Vector2(2320, 384), "mode": "patrol", "waypoints": [Vector2(2200, 384), Vector2(2420, 384)], "alpha": false},
	]
	for spec in extra_spawns:
		if ysort_obstacles.has_node(str(spec["name"])):
			continue
		var enemy := SANTELMO_SCENE.instantiate() as SantelmoEnemy
		if enemy == null:
			continue
		enemy.name = str(spec["name"])
		enemy.position = spec["pos"] as Vector2
		enemy.behavior_mode = str(spec["mode"])
		var wps: Array[Vector2] = []
		for wp in spec["waypoints"]:
			wps.append(wp as Vector2)
		enemy.patrol_waypoints = wps
		if bool(spec.get("alpha", false)):
			enemy.max_health = 90
			enemy.current_health = 90
			enemy.chase_speed = 106.0
			enemy.attack_damage = 16
			enemy.scale = Vector2(1.22, 1.22)
		ysort_obstacles.add_child(enemy)


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
	npc.normal_frames_path = "res://assets/sprites/npcs/vulto_bosque/vulto_bosque_normal_spriteframes.tres"
	npc.distorted_frames_path = "res://assets/sprites/npcs/vulto_bosque/vulto_bosque_distorted_spriteframes.tres"
	npc.npc_interacted.connect(func(_id: String) -> void:
		if npc.is_hostile or npc.is_defeated:
			return
		request_dialogue.emit([
			{
				"speaker": "Vulto Calcinado",
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

	var active_base_ts: TileSet = ACT3_TS if act3 else NORMAL_TS
	ground_normal.tile_set = active_base_ts
	walls_normal.tile_set = active_base_ts
	if _understory_layer != null:
		_understory_layer.tile_set = ACT3_TS if act3 else (DISTORTED_TS if higher else NORMAL_TS)
	if _canopy_layer != null:
		_canopy_layer.tile_set = ACT3_TS if act3 else (DISTORTED_TS if higher else NORMAL_TS)
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

	var period: String = GameState.get_day_period() if GameState.has_method("get_day_period") else ("afternoon" if GameState.is_afternoon else "morning")
	if canvas_mod:
		if act3:
			canvas_mod.color = Color(0.62, 0.64, 0.67, 1.0)
		elif higher:
			canvas_mod.color = Color(0.56, 0.52, 0.58, 1.0)
		elif fire_active:
			canvas_mod.color = Color(0.58, 0.44, 0.40, 1.0)
		elif period == "night":
			canvas_mod.color = Color(0.45, 0.49, 0.58, 1.0)
		elif period == "afternoon" or GameState.is_afternoon:
			canvas_mod.color = Color(0.64, 0.58, 0.62, 1.0)
		else:
			canvas_mod.color = Color(0.76, 0.80, 0.82, 1.0)

	if fire_embers:
		fire_embers.emitting = not act3 and (fire_active or higher)
		fire_embers.color = Color(0.95, 0.18, 0.22, 0.85) if higher else Color(1.0, 0.52, 0.14, 0.78)

	if _ambient_dust:
		if act3:
			_ambient_dust.color = Color(0.76, 0.78, 0.82, 0.22)
		elif higher:
			_ambient_dust.color = Color(0.90, 0.24, 0.26, 0.40)
		elif fire_active:
			_ambient_dust.color = Color(0.95, 0.60, 0.32, 0.36)
		else:
			_ambient_dust.color = Color(0.75, 0.85, 0.78, 0.30)

	# Espiritos de fogo desaparecem no Ato 3 (revelação sem ilusões sobrenaturais)
	for s in _santelmos:
		if s == null or not is_instance_valid(s):
			continue
		var dead: bool = ("current_state" in s and int(s.current_state) == SantelmoEnemy.State.DEAD)
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
