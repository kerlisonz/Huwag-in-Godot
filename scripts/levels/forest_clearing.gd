@tool
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
@onready var painted_props_layer: TileMapLayer = get_node_or_null("ObstaclesYsort/PaintedPropsLayer") as TileMapLayer
@onready var lights_layer: Node2D = $LightsLayer
@onready var player: PlayerController = get_node_or_null("ObstaclesYsort/PlayerHuwag")
@onready var creature: Node2D = get_node_or_null("ObstaclesYsort/AquaticCreature")
@onready var egg_nest: StaticBody2D = get_node_or_null("ObstaclesYsort/EggNest")
@onready var nest_interactable: Interactable = get_node_or_null("ObstaclesYsort/EggNest/NestInteractable")
@onready var exit_area: Area2D = get_node_or_null("ExitToTrailArea")
@onready var water_ripples: CPUParticles2D = get_node_or_null("WaterRipples")

var _distorted_props: Array[Node2D] = []
var _distorted_decals: Array[Node2D] = []
var _lights: Array[PointLight2D] = []
var _pond_light: PointLight2D = null
var _clearing_mist: CPUParticles2D = null
var _fog_overlay: ColorRect = null
var _santelmo_barrier_root: Node2D = null
var _santelmo_barrier_col: CollisionShape2D = null
var _santelmo_barrier_interact: Interactable = null
var _santelmo_barrier_particles: CPUParticles2D = null
var _santelmo_barrier_light: PointLight2D = null
var _time_acc: float = 0.0


func _ready() -> void:
	if Engine.is_editor_hint():
		_setup_editor_preview()
		return

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
	_setup_santelmo_barrier()

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
	GameState.switch_changed.connect(func(_k: String, _v: bool) -> void:
		_sync_clearing_atmosphere()
		_update_santelmo_barrier()
	)
	if GameState.has_signal("task_state_changed"):
		GameState.task_state_changed.connect(func(_t: String, _a: bool, _c: bool) -> void: _update_santelmo_barrier())
	if GameState.has_signal("day_period_changed"):
		GameState.day_period_changed.connect(func(_p: String) -> void: _sync_clearing_atmosphere())
	if GameState.has_signal("higher_dose_changed"):
		GameState.higher_dose_changed.connect(func(active: bool) -> void: apply_higher_dose_world(active))

	_sync_clearing_atmosphere()
	_update_santelmo_barrier()

	if has_node("/root/AudioManager"):
		var am = get_node("/root/AudioManager")
		if am.has_method("sync_adaptive_soundtrack"):
			am.call("sync_adaptive_soundtrack", "forest_clearing", false)
		elif GameState.is_unfiltered_act3():
			am.play_ambience("act3_ambience")
		else:
			am.play_ambience("night_forest")


func _setup_editor_preview() -> void:
	RetroLevelHelpers.cleanup_editor_preview(self)
	_distorted_props.clear()
	_distorted_decals.clear()
	_lights.clear()
	_pond_light = null
	_clearing_mist = null
	_fog_overlay = null
	var has_baked_floor := ground_normal != null and not ground_normal.get_used_cells().is_empty()
	if has_baked_floor:
		ground_normal.tile_set = NORMAL_TS
		if walls_normal != null:
			walls_normal.tile_set = NORMAL_TS
		_build_clearing_props_and_lights()
	else:
		var orig_gn := ground_normal
		var orig_wn := walls_normal
		var orig_gd := ground_distorted
		var orig_wd := walls_distorted
		ground_normal = RetroLevelHelpers.create_preview_tilemap(self, "EditorPreviewGround", -3)
		walls_normal = RetroLevelHelpers.create_preview_tilemap(self, "EditorPreviewWalls", -2)
		var tmp_gd := TileMapLayer.new()
		var tmp_wd := TileMapLayer.new()
		ground_distorted = tmp_gd
		walls_distorted = tmp_wd
		_build_clearing_tilemaps()
		_build_clearing_props_and_lights()
		ground_normal = orig_gn
		walls_normal = orig_wn
		ground_distorted = orig_gd
		walls_distorted = orig_wd
		tmp_gd.free()
		tmp_wd.free()
	RetroLevelHelpers.mark_unowned_preview_children([self, ysort_obstacles, decals_layer, lights_layer])


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_time_acc += delta
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
	if Engine.is_editor_hint():
		return false
	return GameState.has_method("is_higher_dose") and GameState.is_higher_dose()


func _is_lagoon_water(x: int, y: int) -> bool:
	if y == 12:
		return x == 30 or x == 31
	if y == 13:
		return x >= 29 and x <= 33
	if y == 14 or y == 15:
		return x >= 28 and x <= 34
	if y == 16:
		return x >= 29 and x <= 33
	if y == 17:
		return x >= 30 and x <= 32
	return false


func _pick_lagoon_tile(x: int, y: int, f_cat: Dictionary) -> Vector2i:
	var has_n := _is_lagoon_water(x, y - 1)
	var has_s := _is_lagoon_water(x, y + 1)
	var has_w := _is_lagoon_water(x - 1, y)
	var has_e := _is_lagoon_water(x + 1, y)
	if not has_n and not has_w:
		return f_cat["pond_tl"]
	if not has_n and not has_e:
		return f_cat["pond_tr"]
	if not has_s and not has_w:
		return f_cat["pond_bl"]
	if not has_s and not has_e:
		return f_cat["pond_br"]
	if not has_n:
		return f_cat["pond_t"]
	if not has_s:
		return f_cat["pond_b"]
	if not has_w:
		return f_cat["pond_l"]
	if not has_e:
		return f_cat["pond_r"]
	return f_cat["water_deep_anim"] if ((x + y) % 3 != 0) else f_cat["pond_c"]


func _build_clearing_tilemaps() -> void:
	var f_cat := V2TileCatalog.FOREST_TILES
	for layer in [ground_normal, walls_normal]:
		layer.tile_set = ACT3_TS if RetroLevelHelpers.is_act3_unfiltered() else NORMAL_TS
	for layer in [ground_distorted, walls_distorted]:
		layer.tile_set = DISTORTED_TS

	# Preserva GroundNormal/WallsNormal salvos no .tscn (só gera o padrão caso estejam vazios)
	if ground_normal.get_used_cells().is_empty():
		walls_normal.clear()
		for x in range(MAP_W):
			for y in range(MAP_H):
				var base_grass: Vector2i = f_cat["grass_a"] if ((x + y) % 2 == 0) else f_cat["grass_b"]
				var in_pond_core := _is_lagoon_water(x, y)
				if in_pond_core:
					var water_tile: Vector2i = _pick_lagoon_tile(x, y, f_cat)
					walls_normal.set_cell(Vector2i(x, y), 0, water_tile)
					ground_normal.set_cell(Vector2i(x, y), 0, f_cat["grass_a"])
				else:
					var near_lagoon := false
					for dy in range(-1, 2):
						for dx in range(-1, 2):
							if _is_lagoon_water(x + dx, y + dy):
								near_lagoon = true
								break
						if near_lagoon:
							break
					var ddx := (float(x) - 31.0) / 8.5
					var ddy := (float(y) - 15.0) / 5.5
					var r2 := ddx * ddx + ddy * ddy
					var gtile: Vector2i = base_grass
					if near_lagoon and (x + y * 2) % 3 == 0:
						gtile = f_cat["needle_grass_b"]
					elif r2 <= 0.72 and (x + y * 2) % 3 != 0:
						gtile = f_cat["needle_grass_b"]
					ground_normal.set_cell(Vector2i(x, y), 0, gtile)

		# Trilha contínua oeste e píer rústico de madeira até a margem da Guardiã
		for sx in range(0, 24):
			var cy := 14 if (sx < 8 or sx >= 17) else 15
			ground_normal.set_cell(Vector2i(sx, cy), 0, f_cat["soil_a"])
			ground_normal.set_cell(Vector2i(sx, cy + 1), 0, f_cat["soil_b"] if sx % 2 == 0 else f_cat["soil_a"])
		V2TileCatalog.fill_rect(ground_normal, Rect2i(24, 14, 4, 2), f_cat["bridge_h_mid_t"])
		for ex in range(35, 41):
			for ey in range(14, 16):
				ground_normal.set_cell(Vector2i(ex, ey), 0, f_cat["needle_grass_b"] if (ex + ey) % 2 == 0 else f_cat["grass_b"])

	ground_distorted.tile_map_data = ground_normal.tile_map_data
	walls_distorted.tile_map_data = walls_normal.tile_map_data

	if not Engine.is_editor_hint() and _fog_overlay == null:
		_fog_overlay = AtmosphereRig.create_fog_overlay(Rect2(0, 0, MAP_W * 16, MAP_H * 16), Color(0.18, 0.28, 0.30, 1.0), 0.14)
		add_child(_fog_overlay)
	walls_distorted.collision_enabled = false


func _build_clearing_props_and_lights() -> void:
	if not Engine.is_editor_hint():
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

	var swarm := get_node_or_null("CorruptedEyeSwarm") as CorruptedEyeSwarm
	if swarm == null:
		swarm = CorruptedEyeSwarm.new()
		swarm.name = "CorruptedEyeSwarm"
		add_child(swarm)
	swarm.setup_world_swarm([
		Vector2(96, 136), Vector2(198, 96), Vector2(320, 86), Vector2(452, 82),
		Vector2(576, 94), Vector2(688, 128), Vector2(726, 224), Vector2(710, 344),
		Vector2(620, 412), Vector2(468, 424), Vector2(316, 414), Vector2(180, 390),
		Vector2(94, 336), Vector2(390, 140), Vector2(610, 150), Vector2(640, 326)
	], 8521, 0.90)


func _sync_clearing_atmosphere() -> void:
	var ato: int = int(GameState.get_var("Ato", 1))
	var act3 := GameState.is_unfiltered_act3()
	var higher := _is_higher_dose_active()

	var active_base_ts: TileSet = ACT3_TS if act3 else NORMAL_TS
	ground_normal.tile_set = active_base_ts
	walls_normal.tile_set = active_base_ts
	ground_distorted.collision_enabled = false
	var target_ts: TileSet = ACT3_TS if act3 else (DISTORTED_TS if higher else NORMAL_TS)
	if painted_props_layer != null and painted_props_layer.tile_set != target_ts:
		painted_props_layer.tile_set = target_ts
	ground_normal.visible = not higher
	walls_normal.visible = not higher
	ground_distorted.visible = higher
	walls_distorted.visible = higher

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
			_pond_light.color = Color(0.56, 0.52, 0.90)
		else:
			_pond_light.color = Color(0.45, 0.85, 0.96)

	if water_ripples:
		water_ripples.color = (
			Color(0.54, 0.48, 0.86, 0.55) if higher else
			(Color(0.80, 0.83, 0.86, 0.35) if act3 else Color(0.62, 0.88, 0.96, 0.50))
		)

	if _clearing_mist:
		if act3:
			_clearing_mist.color = Color(0.76, 0.78, 0.82, 0.20)
		elif higher:
			_clearing_mist.color = Color(0.46, 0.42, 0.80, 0.32)
		else:
			_clearing_mist.color = Color(0.68, 0.88, 0.94, 0.25)

	var swarm := get_node_or_null("CorruptedEyeSwarm") as CorruptedEyeSwarm
	if swarm != null:
		swarm.refresh_visibility()


func _on_exit_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		request_level_change.emit("res://scenes/levels/forest_trail.tscn", "from_clearing")


func _is_lagoon_sealed_by_santelmos() -> bool:
	if GameState.is_unfiltered_act3():
		return false
	if GameState.get_switch("003_Ovos_sem_derrotar") or GameState.get_switch("004_Ovos_e_derrotou") or GameState.water_boss_defeated:
		return false
	return GameState.has_method("are_all_forest_santelmos_defeated") and not GameState.are_all_forest_santelmos_defeated()


func _setup_santelmo_barrier() -> void:
	_santelmo_barrier_root = Node2D.new()
	_santelmo_barrier_root.name = "SantelmoBarrier"
	_santelmo_barrier_root.z_index = 3
	add_child(_santelmo_barrier_root)

	var body := StaticBody2D.new()
	body.name = "SantelmoBarrierBody"
	body.position = Vector2(432, 280)
	body.collision_layer = 1
	_santelmo_barrier_root.add_child(body)

	var col := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(18, 480)
	col.shape = rect
	body.add_child(col)
	_santelmo_barrier_col = col

	# Visual da barreira espiritual dos Santelmos cruzando a entrada da Lagoa
	var line := Line2D.new()
	line.width = 4.0
	line.default_color = Color(1.0, 0.42, 0.16, 0.78)
	for py in range(136, 424, 16):
		line.add_point(Vector2(432 + sin(float(py) * 0.12) * 3.0, float(py)))
	_santelmo_barrier_root.add_child(line)

	var core_line := Line2D.new()
	core_line.width = 1.6
	core_line.default_color = Color(1.0, 0.85, 0.42, 0.92)
	for py in range(136, 424, 16):
		core_line.add_point(Vector2(432 + sin(float(py) * 0.12) * 2.0, float(py)))
	_santelmo_barrier_root.add_child(core_line)

	_santelmo_barrier_particles = CPUParticles2D.new()
	_santelmo_barrier_particles.position = Vector2(432, 260)
	_santelmo_barrier_particles.amount = 36
	_santelmo_barrier_particles.lifetime = 1.4
	_santelmo_barrier_particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_santelmo_barrier_particles.emission_rect_extents = Vector2(6, 128)
	_santelmo_barrier_particles.direction = Vector2(0.0, -1.0)
	_santelmo_barrier_particles.gravity = Vector2(0.0, -18.0)
	_santelmo_barrier_particles.initial_velocity_min = 8.0
	_santelmo_barrier_particles.initial_velocity_max = 20.0
	_santelmo_barrier_particles.scale_amount_min = 1.5
	_santelmo_barrier_particles.scale_amount_max = 3.2
	_santelmo_barrier_particles.color = Color(1.0, 0.52, 0.18, 0.85)
	_santelmo_barrier_root.add_child(_santelmo_barrier_particles)

	_santelmo_barrier_light = RetroLevelHelpers.create_point_light(Vector2(432, 240), Color(1.0, 0.48, 0.18), 0.85, 2.2)
	_santelmo_barrier_root.add_child(_santelmo_barrier_light)

	var inter := Interactable.new()
	inter.name = "BarreiraSantelmoInteract"
	inter.interaction_id = "BarreiraSantelmo"
	inter.title = "Barreira dos Santelmos"
	inter.verb = "Examinar"
	inter.position = Vector2(422, 240)
	var icol := CollisionShape2D.new()
	var irect := RectangleShape2D.new()
	irect.size = Vector2(24, 180)
	icol.shape = irect
	inter.add_child(icol)
	inter.interacted.connect(func(_ia: Interactable) -> void:
		var rem := GameState.get_remaining_forest_santelmo_count()
		request_dialogue.emit([{
			"speaker": "Selo dos Santelmos",
			"text": "Uma muralha de chamas espirituais sela a entrada da Guardiã da Lagoa.\nRestam %d de %d Santelmo(s) na Trilha da Floresta — derrote todos para abrir passagem." % [rem, GameState.FOREST_SANTELMO_TOTAL]
		}], Callable())
	)
	_santelmo_barrier_root.add_child(inter)
	_santelmo_barrier_interact = inter


func _update_santelmo_barrier() -> void:
	var sealed := _is_lagoon_sealed_by_santelmos()
	if _santelmo_barrier_root != null:
		_santelmo_barrier_root.visible = sealed
	if _santelmo_barrier_col != null:
		_santelmo_barrier_col.set_deferred("disabled", not sealed)
	if _santelmo_barrier_particles != null:
		_santelmo_barrier_particles.emitting = sealed
	if _santelmo_barrier_light != null:
		_santelmo_barrier_light.enabled = sealed
	if _santelmo_barrier_interact != null:
		_santelmo_barrier_interact.set_deferred("monitoring", sealed)
		_santelmo_barrier_interact.set_deferred("monitorable", sealed)


func _on_nest_interaction(_interactable: Interactable) -> void:
	if GameState.is_unfiltered_act3():
		return
	if _is_lagoon_sealed_by_santelmos():
		var rem := GameState.get_remaining_forest_santelmo_count()
		request_dialogue.emit([{
			"speaker": "Selo dos Santelmos",
			"text": "O calor dos %d Santelmo(s) restantes na Trilha da Floresta bloqueia o acesso ao ninho e à Guardiã da Lagoa." % rem
		}], Callable())
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
	if _is_lagoon_sealed_by_santelmos():
		var rem := GameState.get_remaining_forest_santelmo_count()
		request_dialogue.emit([{
			"speaker": "Selo dos Santelmos",
			"text": "A Guardiã da Lagoa permanece inacessível atrás do calor dos Santelmos!\nAinda restam %d de %d Santelmo(s) ativos na Trilha da Floresta." % [rem, GameState.FOREST_SANTELMO_TOTAL]
		}], Callable())
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
	cat_inter.position = Vector2(360, 324)
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
