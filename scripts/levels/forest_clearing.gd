extends Node2D

## ForestClearing — Clareira da Lagoa (Atos 1, 2 e 3)
## Santuário montanhoso em Agdangan após a travessia perigosa da floresta.
## Estética FNAF Minigames + Yume Nikki + Chrono Trigger + Pokémon GB (960x576 / 60x36 tiles).

signal request_level_change(target_scene: String, spawn_tag: String)
signal request_dialogue(pages: Array, callback: Callable)

const RetroLevelHelpers := preload("res://scripts/levels/retro_level_helpers.gd")
const V2TileCatalog := preload("res://scripts/levels/v2_tile_catalog.gd")
const AtmosphereRig := preload("res://scripts/levels/atmosphere_rig.gd")
const NORMAL_TS := preload("res://assets/tilesets/v2/forest_v2_normal_tileset.tres")
const DISTORTED_TS := preload("res://assets/tilesets/v2/forest_v2_distorted_tileset.tres")
const ACT3_TS := preload("res://assets/tilesets/v2/forest_v2_act3_tileset.tres")

const MAP_W := 60
const MAP_H := 36

@onready var canvas_mod: CanvasModulate = $CanvasModulate
@onready var ground_normal: TileMapLayer = $GroundNormal
@onready var walls_normal: TileMapLayer = $WallsNormal
@onready var ground_distorted: TileMapLayer = $GroundDistorted
@onready var walls_distorted: TileMapLayer = $WallsDistorted
@onready var decals_layer: Node2D = $DecalsLayer
@onready var ysort_obstacles: Node2D = $ObstaclesYsort
@onready var lights_layer: Node2D = $LightsLayer
@onready var player: PlayerController = get_node_or_null("ObstaclesYsort/PlayerHuwag")
@onready var creature: Node2D = get_node_or_null("ObstaclesYsort/AquaticCreature")
@onready var egg_nest: StaticBody2D = get_node_or_null("ObstaclesYsort/EggNest")
@onready var nest_interactable: Interactable = get_node_or_null("ObstaclesYsort/EggNest/NestInteractable")
@onready var exit_area: Area2D = get_node_or_null("ExitToTrailArea")
@onready var water_ripples: CPUParticles2D = get_node_or_null("WaterRipples")

var _normal_props: Array[Node2D] = []
var _distorted_props: Array[Node2D] = []
var _distorted_decals: Array[Node2D] = []
var _lights: Array[PointLight2D] = []
var _pond_light: PointLight2D = null
var _clearing_mist: CPUParticles2D = null
var _understory_layer: TileMapLayer = null
var _canopy_layer: TileMapLayer = null
var _canopy_material: ShaderMaterial = null
var _fog_overlay: ColorRect = null
var _time_acc: float = 0.0


func _ready() -> void:
	if player:
		if GameState.spawn_tag == "from_ending":
			player.position = Vector2(520, 320)
			player.facing_dir = Vector2.UP
		else:
			player.position = Vector2(96, 240)
			player.facing_dir = Vector2.RIGHT
		player.set_camera_limits(Rect2i(0, 0, MAP_W * 16, MAP_H * 16))

	_build_clearing_tilemaps()
	_build_clearing_props_and_lights()

	if exit_area:
		exit_area.body_entered.connect(_on_exit_area_body_entered)
	if nest_interactable:
		nest_interactable.interacted.connect(_on_nest_interaction)
	if creature:
		if creature.has_signal("interaction_requested"):
			creature.interaction_requested.connect(_on_creature_interaction)
		if creature.has_signal("boss_phase_dialogue_requested"):
			creature.connect("boss_phase_dialogue_requested", _on_boss_phase_dialogue)
		if creature.has_signal("boss_defeated"):
			creature.connect("boss_defeated", _on_boss_defeated)

	var ato: int = int(GameState.get_var("Ato", 1))
	if ato == 2 and not GameState.get_switch("017_Gatinho_encontrado"):
		_setup_act2_cat_rescue()
	if GameState.is_unfiltered_act3():
		_setup_act3_pond_mirror()

	GameState.perception_changed.connect(func(_m: int) -> void: _sync_clearing_atmosphere())
	GameState.switch_changed.connect(func(_k: String, _v: bool) -> void: _sync_clearing_atmosphere())
	if GameState.has_signal("day_period_changed"):
		GameState.day_period_changed.connect(func(_p: String) -> void: _sync_clearing_atmosphere())
	if GameState.has_signal("higher_dose_changed"):
		GameState.higher_dose_changed.connect(func(active: bool) -> void: apply_higher_dose_world(active))

	_sync_clearing_atmosphere()

	if has_node("/root/AudioManager"):
		var am = get_node("/root/AudioManager")
		if am.has_method("sync_adaptive_soundtrack"):
			am.call("sync_adaptive_soundtrack", "forest_clearing", false)
		elif GameState.is_unfiltered_act3():
			am.play_ambience("act3_ambience")
		else:
			am.play_ambience("night_forest")


func _process(delta: float) -> void:
	_time_acc += delta
	if _canopy_material != null and player != null and is_instance_valid(player):
		_canopy_material.set_shader_parameter("player_world_pos", player.global_position)
	if _pond_light != null and is_instance_valid(_pond_light):
		var higher := _is_higher_dose_active()
		var base_e := 0.85 if not higher else 0.72
		var pulse := sin(_time_acc * 2.4) * 0.08
		if higher and fmod(_time_acc, 4.6) > 4.25:
			pulse = -0.25
		_pond_light.energy = maxf(0.20, base_e + pulse)


func apply_higher_dose_world(_active: bool) -> void:
	_sync_clearing_atmosphere()


func _is_higher_dose_active() -> bool:
	return GameState.has_method("is_higher_dose") and GameState.is_higher_dose()


func _build_clearing_tilemaps() -> void:
	var f_cat := V2TileCatalog.FOREST_TILES
	for layer in [ground_normal, walls_normal]:
		layer.tile_set = ACT3_TS if GameState.is_unfiltered_act3() else NORMAL_TS
	for layer in [ground_distorted, walls_distorted]:
		layer.tile_set = DISTORTED_TS

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

	# Corredor oeste vindo da trilha + ampla clareira central + santuário sul
	carve.call(0, 12, 12, 6)
	carve.call(8, 5, 44, 24)
	carve.call(20, 27, 22, 5)

	# Bacia sagrada da Lagoa Azul centrada em (495, 240) -> tiles x=29..32, y=13..16 + cachoeira norte
	for x in range(MAP_W):
		for y in range(MAP_H):
			var base_grass: Vector2i = f_cat["grass_a"] if ((x + y) % 2 == 0) else f_cat["grass_b"]
			for gl in [ground_normal, ground_distorted]:
				gl.set_cell(Vector2i(x, y), 0, base_grass)

			var in_pond_core := (x >= 29 and x <= 32 and y >= 13 and y <= 16)
			if not walkable[x][y]:
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
					var wcoord: Vector2i = f_cat["cliff_face_mid"] if (y + 1 < MAP_H and walkable[x][y + 1]) else f_cat["cliff_top_mid"]
					for wl in [walls_normal, walls_distorted]:
						wl.set_cell(Vector2i(x, y), 0, wcoord)
			elif in_pond_core:
				var is_edge := (x == 29 or x == 32 or y == 13 or y == 16)
				var water_tile: Vector2i = f_cat["water_ripple_anim"] if is_edge else f_cat["water_deep_anim"]
				if y == 13 and (x == 30 or x == 31):
					water_tile = f_cat["waterfall_foam"]
				for wl in [walls_normal, walls_distorted]:
					wl.set_cell(Vector2i(x, y), 0, water_tile)
				for gl in [ground_normal, ground_distorted]:
					gl.set_cell(Vector2i(x, y), 0, f_cat["water_shore_center"])
			else:
				var gtile: Vector2i = f_cat["grass_a"]
				if (x * 5 + y) % 6 == 0:
					gtile = f_cat["grass_b"]
				if x >= 27 and x <= 35 and y >= 11 and y <= 18:
					gtile = f_cat["needle_grass_a"] if (x + y) % 2 == 0 else f_cat["needle_grass_b"]
				elif x >= 23 and x <= 39 and y >= 8 and y <= 21:
					gtile = f_cat["mud_patch_center"] if (x == 24 or x == 38 or y == 9 or y == 20) else f_cat["needle_grass_b"]
				elif x >= 25 and x <= 36 and y >= 25 and y <= 29:
					gtile = f_cat["soil_b"]
				for gl in [ground_normal, ground_distorted]:
					gl.set_cell(Vector2i(x, y), 0, gtile)

	# Cachoeira sagrada norte desaguando na Lagoa Azul
	for wl in [walls_normal, walls_distorted]:
		for wx in [30, 31]:
			wl.set_cell(Vector2i(wx, 10), 0, f_cat["waterfall_top"])
			wl.set_cell(Vector2i(wx, 11), 0, f_cat["waterfall_mid"])
			wl.set_cell(Vector2i(wx, 12), 0, f_cat["waterfall_foam"])

	# Trilha oeste + píer de madeira até a margem da Guardiã + margem leste dos ovos
	for gl in [ground_normal, ground_distorted]:
		V2TileCatalog.fill_rect(gl, Rect2i(0, 14, 24, 2), f_cat["soil_a"])
		V2TileCatalog.fill_rect(gl, Rect2i(24, 14, 4, 2), f_cat["bridge_h_mid_t"])
		V2TileCatalog.fill_rect(gl, Rect2i(35, 14, 5, 2), f_cat["needle_grass_a"])

	_setup_v2_clearing_canopy_and_fog(walkable)
	walls_distorted.collision_enabled = false


func _setup_v2_clearing_canopy_and_fog(walkable: Array) -> void:
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
		_canopy_material = AtmosphereRig.create_canopy_material(38.0, 0.36)
		_canopy_layer.material = _canopy_material
		add_child(_canopy_layer)
	_canopy_layer.tile_set = active_ts
	_canopy_layer.clear()

	# Samambaias, cogumelos e pedras musgosas no sub-bosque (sobre piso opaco)
	for gx in range(2, MAP_W - 2, 2):
		for gy in range(2, MAP_H - 2, 2):
			if walkable[gx][gy]:
				if (gx >= 26 and gx <= 36 and gy >= 10 and gy <= 19) and not (gx >= 28 and gx <= 33 and gy >= 12 and gy <= 17):
					if (gx + gy) % 3 == 0:
						_understory_layer.set_cell(Vector2i(gx, gy), 0, f_cat["fern_a" if gx % 2 == 0 else "mushrooms_a"])
				continue
			var h := (gx * 11 + gy * 17) % 6
			if h == 0:
				_understory_layer.set_cell(Vector2i(gx, gy), 0, f_cat["fern_a"])
			elif h == 1:
				_understory_layer.set_cell(Vector2i(gx, gy), 0, f_cat["fern_b"])
			elif h == 2:
				_understory_layer.set_cell(Vector2i(gx, gy), 0, f_cat["mushrooms_a"])

	# Anel florestal denso em torno de toda a Clareira da Lagoa Azul (abraçando de perto a trilha oeste e o santuário)
	for gy in range(0, MAP_H - 5, 3):
		var row_shift := (gy % 2) * 2
		for gx in range(0, MAP_W - 4, 3):
			var tx := gx + row_shift
			if tx >= MAP_W - 3:
				continue
			var base_y := gy + 5
			var in_west_path := (tx <= 23 and base_y >= 13 and base_y <= 17)
			var in_lagoon_sanctuary := (tx + 2 >= 23 and tx <= 39 and base_y >= 8 and base_y <= 22)
			var in_east_glade := (tx >= 39 and tx <= 45 and base_y >= 12 and base_y <= 18)
			var in_ancient_tree_trunk := (tx >= 45 and tx <= 55 and base_y >= 11 and base_y <= 20)
			if in_west_path or in_lagoon_sanctuary or in_east_glade or in_ancient_tree_trunk:
				continue
			var pick := (tx * 5 + gy * 7) % 5
			var target_layer: TileMapLayer = _canopy_layer if ((tx + gy) % 2 == 0) else _understory_layer
			if pick == 0 or pick == 1:
				V2TileCatalog.stamp_rect(target_layer, Vector2i(tx, gy), f_cat["pine_dark"], Vector2i(3, 6))
			elif pick == 2:
				V2TileCatalog.stamp_rect(target_layer, Vector2i(tx, gy), f_cat["pine_withered"], Vector2i(3, 6))
			elif pick == 3 and tx + 4 < MAP_W:
				V2TileCatalog.stamp_rect(target_layer, Vector2i(tx, gy), f_cat["tree_gnarled_mid"], Vector2i(5, 6))
			else:
				V2TileCatalog.stamp_rect(target_layer, Vector2i(tx + 1, gy), f_cat["pine_slender"], Vector2i(1, 6))

	# Árvore Anciã Sagrada (14x18) no extremo leste da clareira
	V2TileCatalog.stamp_rect(_canopy_layer, Vector2i(44, 2), f_cat["ancient_tree"], Vector2i(14, 18))

	if _fog_overlay == null:
		_fog_overlay = AtmosphereRig.create_fog_overlay(Rect2(0, 0, MAP_W * 16, MAP_H * 16), Color(0.18, 0.28, 0.30, 1.0), 0.14)
		add_child(_fog_overlay)


func _build_clearing_props_and_lights() -> void:
	_clearing_mist = CPUParticles2D.new()
	_clearing_mist.name = "ClearingMistParticles"
	_clearing_mist.position = Vector2(480, 288)
	_clearing_mist.z_index = 4
	_clearing_mist.amount = 45
	_clearing_mist.lifetime = 5.5
	_clearing_mist.preprocess = 2.0
	_clearing_mist.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_clearing_mist.emission_rect_extents = Vector2(400, 220)
	_clearing_mist.direction = Vector2(0.8, -0.25)
	_clearing_mist.spread = 35.0
	_clearing_mist.gravity = Vector2(1.0, -2.5)
	_clearing_mist.initial_velocity_min = 4.0
	_clearing_mist.initial_velocity_max = 12.0
	_clearing_mist.scale_amount_min = 2.0
	_clearing_mist.scale_amount_max = 4.0
	_clearing_mist.color = Color(0.68, 0.88, 0.94, 0.25)
	add_child(_clearing_mist)

	_add_dual_prop("wooden_signpost", Vector2(215, 200), ysort_obstacles, Vector2(0, -10))

	for pos in [Vector2(380, 240), Vector2(495, 336), Vector2(610, 256), Vector2(495, 168)]:
		var st_d := RetroLevelHelpers.create_prop_sprite("floor_stain", true)
		st_d.position = pos
		st_d.visible = false
		decals_layer.add_child(st_d)
		_distorted_props.append(st_d)

	for eye_pos in [
		Vector2(416, 176), Vector2(576, 176), Vector2(416, 304),
		Vector2(576, 304), Vector2(495, 384), Vector2(495, 132)
	]:
		var eye := RetroLevelHelpers.create_prop_sprite("yume_eye_rune", true)
		eye.position = eye_pos
		eye.visible = false
		decals_layer.add_child(eye)
		_distorted_decals.append(eye)

	_pond_light = RetroLevelHelpers.create_point_light(Vector2(495, 240), Color(0.45, 0.85, 0.96), 0.90, 2.8)
	lights_layer.add_child(_pond_light)
	_lights.append(_pond_light)

	var entry_light := RetroLevelHelpers.create_point_light(Vector2(130, 240), Color(0.62, 0.74, 0.86), 0.65, 2.0)
	lights_layer.add_child(entry_light)
	_lights.append(entry_light)


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
		var strength := 1.0 if kind == "dead_gnarled_tree" else 1.7
		var speed := 1.4 if kind == "dead_gnarled_tree" else 1.85
		RetroLevelHelpers.apply_wind_sway(n, phase, strength, speed, 0.0)
		RetroLevelHelpers.apply_wind_sway(d, phase, strength * 1.15, speed * 1.25, 0.7)


func _sync_clearing_atmosphere() -> void:
	var ato: int = int(GameState.get_var("Ato", 1))
	var act3 := GameState.is_unfiltered_act3()
	var higher := _is_higher_dose_active()

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

	# No Ato 3 não há entidades fantásticas nem ovos na lagoa
	if creature and is_instance_valid(creature):
		creature.visible = not act3
		creature.set_physics_process(not act3)
		var c_inter := creature.get_node_or_null("CreatureInteractable") as Area2D
		if c_inter:
			c_inter.monitoring = not act3
			c_inter.monitorable = not act3
	if egg_nest and is_instance_valid(egg_nest):
		egg_nest.visible = not act3
		if nest_interactable:
			nest_interactable.monitoring = not act3
			nest_interactable.monitorable = not act3

	var period: String = GameState.get_day_period() if GameState.has_method("get_day_period") else ("afternoon" if GameState.is_afternoon else "morning")
	if canvas_mod:
		if act3:
			canvas_mod.color = Color(0.64, 0.66, 0.69, 1.0)
		elif higher:
			canvas_mod.color = Color(0.56, 0.52, 0.58, 1.0)
		elif ato == 2 and GameState.get_switch("015_Floresta_em_chamas"):
			canvas_mod.color = Color(0.58, 0.44, 0.40, 1.0)
		elif period == "night":
			canvas_mod.color = Color(0.42, 0.46, 0.56, 1.0)
		elif period == "afternoon" or GameState.is_afternoon:
			canvas_mod.color = Color(0.64, 0.58, 0.62, 1.0)
		else:
			canvas_mod.color = Color(0.76, 0.80, 0.82, 1.0)

	if _pond_light and is_instance_valid(_pond_light):
		if act3:
			_pond_light.color = Color(0.84, 0.87, 0.90)
		elif higher:
			_pond_light.color = Color(0.92, 0.46, 0.52)
		else:
			_pond_light.color = Color(0.45, 0.85, 0.96)

	if water_ripples:
		water_ripples.color = (
			Color(0.85, 0.20, 0.25, 0.55) if higher else
			(Color(0.80, 0.83, 0.86, 0.35) if act3 else Color(0.62, 0.88, 0.96, 0.50))
		)

	if _clearing_mist:
		if act3:
			_clearing_mist.color = Color(0.76, 0.78, 0.82, 0.20)
		elif higher:
			_clearing_mist.color = Color(0.86, 0.20, 0.26, 0.34)
		else:
			_clearing_mist.color = Color(0.68, 0.88, 0.94, 0.25)


func _on_exit_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		request_level_change.emit("res://scenes/levels/forest_trail.tscn", "from_clearing")


func _on_nest_interaction(_interactable: Interactable) -> void:
	if GameState.is_unfiltered_act3():
		return
	if GameState.get_switch("003_Ovos_sem_derrotar") or GameState.get_switch("004_Ovos_e_derrotou"):
		request_dialogue.emit([
			{
				"speaker": "Huwag Matitiis",
				"expression": "neutral",
				"text": "Os ovos azuis brilham suavemente no ninho agora vazio da energia coletada."
			}
		], Callable())
		return

	var pages: Array[Dictionary] = [
		{
			"speaker": "Huwag Matitiis",
			"expression": "worried",
			"text": "Há três ovos luminosos descansando sobre a vegetação da margem. Uma energia fresca emana deles... O que fazer?",
			"choices": [
				"Tocar e recolher uma gota de essência sem ferir a Guardiã",
				"Tomar o ninho à força para si"
			]
		}
	]
	request_dialogue.emit(pages, func(choice: int) -> void:
		if choice == 0:
			GameState.set_switch("003_Ovos_sem_derrotar", true)
			GameState.set_switch("016_Magia_de_agua_obtida", true)
			GameState.trigger_turn_afternoon()
			request_dialogue.emit([
				{
					"speaker": "Huwag Matitiis",
					"expression": "neutral",
					"text": "Ao tocar suavemente em um dos ovos, uma gota fresca de energia cristalina envolveu minha mão.\n(Magia de Água obtida! Pressione Q ou K para apagar focos de calor)."
				},
				{
					"speaker": "Huwag Matitiis",
					"expression": "tired",
					"text": "A tarde começou a cair sobre a floresta. Devo retornar ao Quartel BFP para reportar ao Capitão Reyes."
				}
			], Callable())
		elif choice == 1:
			GameState.set_switch("004_Ovos_e_derrotou", true)
			GameState.set_switch("016_Magia_de_agua_obtida", true)
			GameState.trigger_turn_afternoon()
			if creature:
				creature.call("take_damage", 100)
			request_dialogue.emit([
				{
					"speaker": "Huwag Matitiis",
					"expression": "worried",
					"text": "A água agitou-se violentamente em resposta à ganância. A energia dos ovos se dispersou em minhas mãos antes que a calma retornasse."
				}
			], Callable())
	)


func _on_creature_interaction() -> void:
	if GameState.is_unfiltered_act3():
		return
	var higher := _is_higher_dose_active()
	if higher:
		request_dialogue.emit([
			{
				"speaker": "Guardiã da Lagoa",
				"expression": "distorted",
				"text": "Na água avermelhada, três reflexos sem rosto boiam lado a lado.\n\"Os ovos nunca foram mágicos, Huwag. Você os contou porque não suportava contar capacetes vazios.\""
			}
		], Callable())
		return

	if GameState.get_switch("003_Ovos_sem_derrotar") or GameState.get_switch("004_Ovos_e_derrotou"):
		request_dialogue.emit([
			{
				"speaker": "Guardiã da Lagoa",
				"text": "(A presença aquática descansa sob as ondulações turquesa da lagoa, em harmonia com a floresta.)"
			}
		], Callable())
		return

	var pages: Array[Dictionary] = [
		{
			"speaker": "Huwag Matitiis",
			"expression": "worried",
			"text": "A criatura aquática ergue-se das águas serenas. Ela observa meus passos com calma solene.\nQual abordagem adotar?",
			"choices": [
				"Conversar (Apresentar-se como bombeiro e buscar diálogo)",
				"Observar (Analisar a postura protetora da criatura)",
				"Atacar com o machado de bombeiro",
				"Afastar-se"
			]
		}
	]
	request_dialogue.emit(pages, func(choice: int) -> void:
		if choice == 0:
			GameState.set_switch("003_Ovos_sem_derrotar", true)
			GameState.set_switch("016_Magia_de_agua_obtida", true)
			GameState.trigger_turn_afternoon()
			request_dialogue.emit([
				{
					"speaker": "Guardiã da Lagoa",
					"text": "\"Aquele que apaga o fogo destrutivo compreende o valor da água que preserva a vida. Leve a bênção da lagoa, jovem bombeiro.\""
				},
				{
					"speaker": "Huwag Matitiis",
					"expression": "uneasy_smile",
					"text": "A criatura assentiu devagar, permitindo que eu colhesse uma amostra dos ovos sem violência.\n(Magia de Água obtida!). Já é fim de tarde, preciso voltar ao quartel."
				}
			], Callable())
		elif choice == 1:
			request_dialogue.emit([
				{
					"speaker": "Huwag Matitiis",
					"expression": "neutral",
					"text": "A criatura não tem intenção hostil. Seus olhos apenas velam pelo ninho de ovos azuis na margem úmida."
				}
			], Callable())
		elif choice == 2:
			request_dialogue.emit([
				{
					"speaker": "Guardiã da Lagoa",
					"text": "As águas da Lagoa Azul erguem-se em colunas turquesa e carmesim!\n\"Se trazes o ferro e a cinza ao santuário da montanha, provarás a fúria da correnteza!\""
				},
				{
					"speaker": "Huwag Matitiis",
					"expression": "angry",
					"text": "Firmei o cabo do machado BFP. Preciso observar os anéis de aviso na água e esquivar (Z/L) antes de contra-atacar!"
				}
			], func(_c: int) -> void:
				if creature and creature.has_method("start_boss_fight"):
					creature.call("start_boss_fight")
			)
	)


func _on_boss_phase_dialogue(phase_id: String) -> void:
	if phase_id == "phase_2":
		request_dialogue.emit([
			{
				"speaker": "Guardiã da Lagoa",
				"text": "O redemoinho da lagoa acelera!\n\"Por que golpeias a água que poderia apagar o incêndio dentro do teu próprio peito, bombeiro?!\""
			}
		], Callable())
	elif phase_id == "phase_3":
		request_dialogue.emit([
			{
				"speaker": "Huwag Matitiis",
				"expression": "worried",
				"text": "As escamas dela brilham como sirenes sob a neblina... Mais alguns golpes certeiros e a tormenta da lagoa vai ceder!"
			}
		], Callable())


func _on_boss_defeated() -> void:
	GameState.set_switch("004_Ovos_e_derrotou", true)
	GameState.set_switch("016_Magia_de_agua_obtida", true)
	GameState.trigger_turn_afternoon()
	request_dialogue.emit([
		{
			"speaker": "Guardiã da Lagoa",
			"text": "A criatura afunda lentamente nas águas agora serenas da Lagoa Azul.\n\"Venceste pela força... mas a água que levas contigo ainda carrega o peso do que recusas lembrar.\""
		},
		{
			"speaker": "Huwag Matitiis",
			"expression": "tired",
			"text": "A onda final impregnou meu machado e minhas mãos com a essência fria da lagoa.\n(Magia de Água obtida! O fim de tarde já tingiu o céu — preciso voltar ao Quartel BFP)."
		}
	], Callable())


func _setup_act2_cat_rescue() -> void:
	var cat_inter := Interactable.new()
	cat_inter.name = "CatRescueInteractable"
	cat_inter.interaction_id = "Resgatar_Gato"
	cat_inter.title = "Gatinho da Senhora Luningning"
	cat_inter.verb = "Resgatar"
	cat_inter.position = Vector2(400, 324)
	cat_inter.collision_layer = 4
	cat_inter.collision_mask = 2

	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 32.0
	col.shape = shape
	cat_inter.add_child(col)

	var cat_spr := RetroLevelHelpers.create_prop_sprite("pusa_cat", false)
	cat_spr.modulate = Color(1.45, 0.95, 0.55, 1.0)
	cat_inter.add_child(cat_spr)

	cat_inter.interacted.connect(func(_i: Interactable) -> void:
		if GameState.get_switch("017_Gatinho_encontrado"):
			return
		GameState.set_switch("017_Gatinho_encontrado", true)
		cat_inter.visible = false
		cat_inter.monitoring = false
		cat_inter.monitorable = false
		if has_node("/root/AudioManager"):
			get_node("/root/AudioManager").play_sfx("ui_select")
		request_dialogue.emit([
			{
				"speaker": "Huwag Matitiis",
				"expression": "worried",
				"text": "Miau! O gatinho está tremendo perto das pedras da margem, com os pelos chamuscados pela fumaça."
			},
			{
				"speaker": "Huwag Matitiis",
				"expression": "neutral",
				"text": "Calma, pequenino... você está seguro agora.\n(Envolvi o gatinho no forro térmico do casaco BFP. Preciso devolvê-lo à Senhora Luningning no quartel!)."
			}
		], Callable())
	)

	add_child(cat_inter)


func _setup_act3_pond_mirror() -> void:
	var mirror := Interactable.new()
	mirror.name = "PondMirrorInteractable"
	mirror.interaction_id = "Espelho_Lagoa"
	mirror.title = "Reflexo das Águas da Lagoa"
	mirror.verb = "Observar Reflexo"
	mirror.position = Vector2(436, 240)
	mirror.collision_layer = 4
	mirror.collision_mask = 2

	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 52.0
	col.shape = shape
	mirror.add_child(col)

	mirror.interacted.connect(func(_i: Interactable) -> void:
		var pages: Array[Dictionary] = [
			{
				"speaker": "Huwag Matitiis",
				"expression": "unfiltered",
				"text": "Olho para a superfície escura e calma da lagoa da montanha..."
			},
			{
				"speaker": "Huwag Matitiis",
				"expression": "unfiltered",
				"text": "Não há monstros aquáticos. Não há fadas nem espíritos do fogo. Só o vento frio de Agdangan e o meu próprio reflexo na água."
			},
			{
				"speaker": "Huwag Matitiis",
				"expression": "unfiltered",
				"text": "Eu sou Huwag Matitiis. 23 anos. Bombeiro municipal. Eu sobrevivi ao incêndio que levou meus amigos... E por muito tempo achei que viver era uma covardia."
			},
			{
				"speaker": "Huwag Matitiis",
				"expression": "unfiltered",
				"text": "Tirei a insígnia de metal do bolso do casaco e a coloquei com respeito sobre a pedra na margem da água. Uma homenagem silenciosa ao Ato, ao Santos e a todos que ficaram no passado."
			},
			{
				"speaker": "Huwag Matitiis",
				"expression": "unfiltered",
				"text": "O sol da manhã começa a romper as nuvens cinzentas. A fumaça finalmente se dissipou da minha mente. Eu não preciso esquecer para continuar vivendo."
			}
		]
		request_dialogue.emit(pages, func(_choice: int) -> void:
			GameState.set_switch("025_Ato3_confronto_lagoa", true)
			GameState.set_switch("026_Jogo_finalizado", true)
			var tw := create_tween()
			tw.tween_interval(0.5)
			tw.tween_callback(func() -> void:
				request_level_change.emit("res://scenes/menu/EndingCredits.tscn", "from_clearing")
			)
		)
	)

	add_child(mirror)
