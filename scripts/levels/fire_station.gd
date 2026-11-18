extends Node2D

signal request_level_change(target_scene: String, spawn_tag: String)
signal request_dialogue(pages: Array, callback: Callable)

const RetroLevelHelpers := preload("res://scripts/levels/retro_level_helpers.gd")
const V2TileCatalog := preload("res://scripts/levels/v2_tile_catalog.gd")
const AtmosphereRig := preload("res://scripts/levels/atmosphere_rig.gd")
const NPC_SCENE := preload("res://scenes/characters/NpcEntity.tscn")
const NORMAL_TS := preload("res://assets/tilesets/v2/interiors_v2_normal_tileset.tres")
const DISTORTED_TS := preload("res://assets/tilesets/v2/interiors_v2_distorted_tileset.tres")
const ACT3_TS := preload("res://assets/tilesets/v2/interiors_v2_act3_tileset.tres")

@onready var canvas_mod: CanvasModulate = $CanvasModulate
@onready var floor_normal: TileMapLayer = $FloorNormal
@onready var walls_normal: TileMapLayer = $WallsNormal
@onready var floor_distorted: TileMapLayer = $FloorDistorted
@onready var walls_distorted: TileMapLayer = $WallsDistorted
@onready var decals_layer: Node2D = $DecalsLayer
@onready var interactables_root: Node2D = $Interactables
@onready var ysort_root: Node2D = $YSortEntities
@onready var player: PlayerController = $YSortEntities/Player
@onready var lights_layer: Node2D = $LightsLayer

var _npcs: Dictionary = {}
var _normal_props: Array[Node2D] = []
var _distorted_props: Array[Node2D] = []
var _distorted_decals: Array[Node2D] = []
var _lights: Array[PointLight2D] = []
var _bay_flicker_light: PointLight2D = null
var _furniture_layer: TileMapLayer = null
var _time_acc: float = 0.0


func _ready() -> void:
	player.position = Vector2(480, 512)
	player.facing_dir = Vector2.UP
	player.set_camera_limits(Rect2i(0, 0, 960, 640))

	_build_station_tilemaps()
	_build_station_props_and_lights()
	_setup_collisions()
	_spawn_firefighter_npcs()
	_setup_static_interactables()

	GameState.perception_changed.connect(func(_m: int) -> void: _apply_station_atmosphere())
	GameState.switch_changed.connect(func(_k: String, _v: bool) -> void: _apply_station_atmosphere())
	if GameState.has_signal("day_period_changed"):
		GameState.day_period_changed.connect(func(_p: String) -> void: _apply_station_atmosphere())
	if GameState.has_signal("higher_dose_changed"):
		GameState.higher_dose_changed.connect(func(active: bool) -> void: apply_higher_dose_world(active))

	_apply_station_atmosphere()


func _process(delta: float) -> void:
	_time_acc += delta
	if _bay_flicker_light != null:
		var higher := _is_higher_dose_active()
		var base_e := 0.72 if not higher else 0.45
		var pulse := sin(_time_acc * 11.0) * 0.06
		if higher and fmod(_time_acc, 4.3) > 4.05:
			pulse = -0.30
		elif not higher and fmod(_time_acc, 6.7) > 6.52:
			pulse = -0.18
		_bay_flicker_light.energy = maxf(0.15, base_e + pulse)


func apply_higher_dose_world(_active: bool) -> void:
	_apply_station_atmosphere()


func _is_higher_dose_active() -> bool:
	return GameState.has_method("is_higher_dose") and GameState.is_higher_dose()


func _build_station_tilemaps() -> void:
	var t_cat := V2TileCatalog.INTERIOR_TILES
	for layer in [floor_normal, walls_normal]:
		layer.tile_set = ACT3_TS if GameState.is_unfiltered_act3() else NORMAL_TS
	for layer in [floor_distorted, walls_distorted]:
		layer.tile_set = DISTORTED_TS

	# Complexo 60x40 tiles (960x640) reconstruído com interiors_v2 (16x16, zero sobreposição)
	for fl in [floor_normal, floor_distorted]:
		fl.clear()
		V2TileCatalog.fill_rect(fl, Rect2i(5, 4, 50, 32), t_cat["wood_floor_dark"])

		# 1. Hall de Recepção e Espera (x: 19..40, y: 21..34) - Ladrilho claro BFP
		for ry in range(21, 35):
			for rx in range(19, 41):
				var rtile: Vector2i = t_cat["checker_clinic"] if (rx + ry) % 2 == 0 else t_cat["checker_clinic_alt"]
				fl.set_cell(Vector2i(rx, ry), 0, rtile)
		V2TileCatalog.stamp_rect(fl, Vector2i(28, 31), t_cat["rug_crimson_tl"], Vector2i(2, 2))
		V2TileCatalog.stamp_rect(fl, Vector2i(30, 31), t_cat["rug_crimson_tl"], Vector2i(2, 2))
		V2TileCatalog.fill_rect(fl, Rect2i(28, 19, 4, 3), t_cat["concrete_station"])

		# 2. Central de Comando & Despacho (x: 19..40, y: 5..18)
		V2TileCatalog.fill_rect(fl, Rect2i(19, 6, 22, 13), t_cat["concrete_station"])
		V2TileCatalog.fill_rect(fl, Rect2i(26, 11, 8, 6), t_cat["wood_floor_warm"])
		V2TileCatalog.stamp_rect(fl, Vector2i(28, 9), t_cat["rug_crimson_tl"], Vector2i(2, 2))
		V2TileCatalog.stamp_rect(fl, Vector2i(30, 9), t_cat["rug_crimson_tl"], Vector2i(2, 2))

		# 3. Ala Oeste - Prontidão & Armários (x: 6..16, y: 7..32) + corredores x:17..18
		V2TileCatalog.fill_rect(fl, Rect2i(6, 7, 11, 26), t_cat["concrete_station"])
		for gy in [13, 19, 25]:
			V2TileCatalog.stamp_rect(fl, Vector2i(10, gy), t_cat["banig_tl"], Vector2i(3, 2))
		V2TileCatalog.fill_rect(fl, Rect2i(17, 10, 2, 3), t_cat["wood_floor_warm"])
		V2TileCatalog.fill_rect(fl, Rect2i(17, 25, 2, 3), t_cat["wood_floor_warm"])

		# 4. Ala Leste - Enfermaria & Arquivo Médico (x: 43..53, y: 7..32) + corredores x:41..42
		for cy in range(7, 33):
			for cx in range(43, 54):
				var ctile: Vector2i = t_cat["checker_clinic"] if (cx + cy) % 2 == 0 else t_cat["checker_clinic_alt"]
				fl.set_cell(Vector2i(cx, cy), 0, ctile)
		V2TileCatalog.fill_rect(fl, Rect2i(41, 10, 2, 3), t_cat["wood_floor_warm"])
		V2TileCatalog.fill_rect(fl, Rect2i(41, 25, 2, 3), t_cat["wood_floor_warm"])

	# Paredes internas e externas + sombras projetadas (sem móveis misturados na camada de parede)
	for wl in [walls_normal, walls_distorted]:
		wl.clear()
		V2TileCatalog.fill_rect(wl, Rect2i(18, 4, 24, 1), t_cat["wall_station_mid"])
		V2TileCatalog.fill_rect(wl, Rect2i(18, 5, 24, 1), t_cat["wall_wood_mid"])
		for sx in range(19, 41):
			wl.set_cell(Vector2i(sx, 6), 0, t_cat["shadow_top"])

		# Parede divisória Comando <-> Recepção (y=19..20, arco aberto em x=28..31)
		V2TileCatalog.fill_rect(wl, Rect2i(19, 19, 9, 1), t_cat["wall_station_mid"])
		V2TileCatalog.fill_rect(wl, Rect2i(19, 20, 9, 1), t_cat["wall_wood_mid"])
		V2TileCatalog.fill_rect(wl, Rect2i(32, 19, 9, 1), t_cat["wall_station_mid"])
		V2TileCatalog.fill_rect(wl, Rect2i(32, 20, 9, 1), t_cat["wall_wood_mid"])

		# Ala Oeste - Prontidão (x=5 parede oeste, y=5..6 norte, y=33 sul)
		V2TileCatalog.fill_rect(wl, Rect2i(5, 5, 13, 1), t_cat["wall_station_mid"])
		V2TileCatalog.fill_rect(wl, Rect2i(5, 6, 13, 1), t_cat["wall_wood_mid"])
		V2TileCatalog.fill_rect(wl, Rect2i(5, 5, 1, 29), t_cat["wall_station_left"])
		V2TileCatalog.fill_rect(wl, Rect2i(5, 33, 13, 1), t_cat["wall_trim_gold"])

		# Parede divisória Ala Oeste <-> Centro (x=17..18)
		V2TileCatalog.fill_rect(wl, Rect2i(17, 5, 2, 5), t_cat["wall_station_mid"])
		V2TileCatalog.fill_rect(wl, Rect2i(17, 13, 2, 12), t_cat["wall_station_mid"])
		V2TileCatalog.fill_rect(wl, Rect2i(17, 28, 2, 7), t_cat["wall_station_mid"])

		# Ala Leste - Enfermaria (x=54 leste, y=5..6 norte, y=33 sul)
		V2TileCatalog.fill_rect(wl, Rect2i(42, 5, 13, 1), t_cat["wall_clinic_mid"])
		V2TileCatalog.fill_rect(wl, Rect2i(42, 6, 13, 1), t_cat["wall_wood_mid"])
		V2TileCatalog.fill_rect(wl, Rect2i(54, 5, 1, 29), t_cat["wall_clinic_right"])
		V2TileCatalog.fill_rect(wl, Rect2i(42, 33, 13, 1), t_cat["wall_trim_gold"])

		# Parede divisória Centro <-> Ala Leste (x=41..42)
		V2TileCatalog.fill_rect(wl, Rect2i(41, 5, 2, 5), t_cat["wall_clinic_mid"])
		V2TileCatalog.fill_rect(wl, Rect2i(41, 13, 2, 12), t_cat["wall_clinic_mid"])
		V2TileCatalog.fill_rect(wl, Rect2i(41, 28, 2, 7), t_cat["wall_clinic_mid"])

		# Parede Sul da Recepção (y=35, porta dupla livre em x=28..31)
		V2TileCatalog.fill_rect(wl, Rect2i(18, 35, 10, 1), t_cat["wall_trim_gold"])
		V2TileCatalog.fill_rect(wl, Rect2i(32, 35, 10, 1), t_cat["wall_trim_gold"])

	# Camada dedicada para mobiliário multi-tile v2 do Quartel BFP (zero sobreposição)
	if _furniture_layer == null:
		_furniture_layer = TileMapLayer.new()
		_furniture_layer.name = "V2StationFurnitureLayer"
		_furniture_layer.z_index = 0
		_furniture_layer.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_furniture_layer.collision_enabled = false
		add_child(_furniture_layer)
	if ysort_root != null:
		ysort_root.z_index = 2
	_furniture_layer.tile_set = ACT3_TS if GameState.is_unfiltered_act3() else (DISTORTED_TS if _is_higher_dose_active() else NORMAL_TS)
	_furniture_layer.clear()

	# Comando Central: Janelas, Lousa BFP, Mesa de Comando Cap. Reyes, Rádio e Estantes
	V2TileCatalog.stamp_rect(_furniture_layer, Vector2i(22, 4), t_cat["window_day_tl"], Vector2i(2, 3))
	V2TileCatalog.stamp_rect(_furniture_layer, Vector2i(36, 4), t_cat["window_day_tl"], Vector2i(2, 3))
	V2TileCatalog.stamp_rect(_furniture_layer, Vector2i(29, 4), t_cat["chalkboard_bfp"], Vector2i(2, 2))
	V2TileCatalog.stamp_rect(_furniture_layer, Vector2i(20, 6), t_cat["radio_pc_bfp"], Vector2i(1, 3))
	V2TileCatalog.stamp_rect(_furniture_layer, Vector2i(37, 6), t_cat["bookshelf_b"], Vector2i(2, 2))
	V2TileCatalog.stamp_rect(_furniture_layer, Vector2i(27, 7), t_cat["dispatch_desk"], Vector2i(6, 2))
	V2TileCatalog.stamp_rect(_furniture_layer, Vector2i(25, 19), t_cat["bulletin_board"], Vector2i(2, 2))
	V2TileCatalog.stamp_rect(_furniture_layer, Vector2i(33, 19), t_cat["bulletin_board"], Vector2i(2, 2))

	# Recepção: Balcão de Atendimento Leste e Cadeiras de Espera Oeste
	V2TileCatalog.stamp_rect(_furniture_layer, Vector2i(32, 25), t_cat["dispatch_desk"], Vector2i(6, 2))
	for cx in range(21, 25):
		_furniture_layer.set_cell(Vector2i(cx, 26), 0, t_cat["chair_down"])

	# Ala Oeste (Prontidão): Armários, Suprimentos e Mesa de Rádio
	V2TileCatalog.stamp_rect(_furniture_layer, Vector2i(11, 7), t_cat["supply_crates"], Vector2i(2, 2))
	V2TileCatalog.stamp_rect(_furniture_layer, Vector2i(14, 7), t_cat["supply_crates"], Vector2i(2, 2))
	for wy in [10, 14, 18, 22]:
		V2TileCatalog.stamp_rect(_furniture_layer, Vector2i(6, wy), t_cat["wardrobe"], Vector2i(2, 3))
	V2TileCatalog.stamp_rect(_furniture_layer, Vector2i(9, 28), t_cat["table_dining"], Vector2i(3, 3))

	# Ala Leste (Enfermaria): Janela, Arquivo Médico, Mesa Médica e 2 Macas
	V2TileCatalog.stamp_rect(_furniture_layer, Vector2i(48, 4), t_cat["window_day_tl"], Vector2i(2, 3))
	V2TileCatalog.stamp_rect(_furniture_layer, Vector2i(44, 6), t_cat["bookshelf_a"], Vector2i(2, 2))
	V2TileCatalog.stamp_rect(_furniture_layer, Vector2i(47, 9), t_cat["table_dining"], Vector2i(3, 3))
	V2TileCatalog.stamp_rect(_furniture_layer, Vector2i(50, 14), t_cat["bed_huwag"], Vector2i(3, 4))
	V2TileCatalog.stamp_rect(_furniture_layer, Vector2i(50, 21), t_cat["bed_huwag"], Vector2i(3, 4))


func _build_station_props_and_lights() -> void:
	# Decais exclusivos no estado distorcido (mobiliário agora vem 100% do atlas interiors_v2)
	_add_distorted_decal("floor_stain", Vector2(480, 232), Vector2(1.8, 1.5))
	_add_distorted_decal("floor_stain", Vector2(180, 280), Vector2(1.6, 1.4))
	_add_distorted_decal("floor_stain", Vector2(760, 290), Vector2(1.7, 1.4))
	_add_distorted_decal("yume_eye_rune", Vector2(280, 340), Vector2(1.2, 1.2))
	_add_distorted_decal("yume_eye_rune", Vector2(680, 340), Vector2(1.2, 1.2))
	_add_distorted_decal("yume_eye_rune", Vector2(480, 310), Vector2(1.4, 1.4))
	for corridor_eye in [
		Vector2i(29, 20), Vector2i(17, 11), Vector2i(41, 11),
		Vector2i(17, 26), Vector2i(41, 26), Vector2i(29, 14)
	]:
		_add_distorted_decal("yume_eye_rune", Vector2(corridor_eye.x * 16 + 8, corridor_eye.y * 16 + 8), Vector2(1.0, 1.0))

	# Luzes PointLight2D distribuídas nas 4 alas (fluorescente / tungsten / clínica)
	var cmd_light := RetroLevelHelpers.create_point_light(Vector2(480, 176), Color(0.86, 0.90, 0.98), 0.85, 3.0)
	var rec_light := RetroLevelHelpers.create_point_light(Vector2(480, 446), Color(0.95, 0.84, 0.56), 0.78, 2.8)
	var clinic_light := RetroLevelHelpers.create_point_light(Vector2(768, 256), Color(0.76, 0.94, 0.98), 0.78, 2.5)
	_bay_flicker_light = RetroLevelHelpers.create_point_light(Vector2(184, 260), Color(0.96, 0.74, 0.44), 0.78, 2.7)
	var bay_lower_light := RetroLevelHelpers.create_point_light(Vector2(168, 444), Color(0.94, 0.72, 0.44), 0.72, 2.3)
	var wait_corner_light := RetroLevelHelpers.create_point_light(Vector2(348, 468), Color(0.92, 0.80, 0.56), 0.70, 2.2)
	var exit_light := RetroLevelHelpers.create_point_light(Vector2(480, 548), Color(0.82, 0.86, 0.94), 0.55, 1.4)

	for lt in [cmd_light, rec_light, clinic_light, _bay_flicker_light, bay_lower_light, wait_corner_light, exit_light]:
		lights_layer.add_child(lt)
		_lights.append(lt)


func _add_dual_prop(kind: String, pos: Vector2, scl: Vector2, offset_y: float) -> void:
	var n_spr := RetroLevelHelpers.create_prop_sprite(kind, false)
	n_spr.position = pos
	n_spr.scale = scl
	n_spr.offset = Vector2(0, offset_y * 0.25)
	var d_spr := RetroLevelHelpers.create_prop_sprite(kind, true)
	d_spr.position = pos
	d_spr.scale = scl
	d_spr.offset = Vector2(0, offset_y * 0.25)
	d_spr.visible = false
	ysort_root.add_child(n_spr)
	ysort_root.add_child(d_spr)
	_normal_props.append(n_spr)
	_distorted_props.append(d_spr)


func _add_distorted_decal(kind: String, pos: Vector2, scl: Vector2) -> void:
	var spr := RetroLevelHelpers.create_prop_sprite(kind, true)
	spr.position = pos
	spr.scale = scl
	spr.visible = false
	decals_layer.add_child(spr)
	_distorted_decals.append(spr)


func _setup_collisions() -> void:
	var body := StaticBody2D.new()
	body.name = "StationFurnitureBounds"
	body.collision_layer = 1
	add_child(body)

	var boxes: Array[Rect2] = [
		Rect2(432, 134, 96, 30),   # Mesa Comando Cap. Reyes
		Rect2(536, 412, 48, 28),   # Balcão Recepção Leste
		Rect2(340, 424, 56, 20),   # Banco Espera
		Rect2(746, 154, 52, 24),   # Mesa Enfermaria
		Rect2(800, 224, 36, 52),   # Maca 1
		Rect2(800, 324, 36, 52),   # Maca 2
		Rect2(154, 464, 28, 24),   # Mesa Rádio Oeste
	]
	for r in boxes:
		var cs := CollisionShape2D.new()
		var rs := RectangleShape2D.new()
		rs.size = r.size
		cs.shape = rs
		cs.position = r.position + r.size * 0.5
		body.add_child(cs)


func _spawn_firefighter_npcs() -> void:
	# 1. Capitão Reyes (Comando Norte)
	_spawn_npc(
		"Cap_Reyes", "Capitão Reyes",
		"res://assets/sprites/npcs/cap_reyes/cap_reyes_normal_spriteframes.tres",
		"res://assets/sprites/npcs/cap_reyes/cap_reyes_distorted_spriteframes.tres",
		Vector2(480, 196), "down", []
	)

	# 2. Bombeiro Ato (Ala Oeste - Armários & Prontidão)
	var ato_patrol: Array[Vector2] = [Vector2(174, 212), Vector2(236, 212)]
	_spawn_npc(
		"Bombeiro_Ato", "Bombeiro Ato",
		"res://assets/sprites/npcs/bombeiro_ato/bombeiro_ato_normal_spriteframes.tres",
		"res://assets/sprites/npcs/bombeiro_ato/bombeiro_ato_distorted_spriteframes.tres",
		Vector2(174, 212), "down", ato_patrol
	)

	# 3. Bombeiro Santos (Ala Oeste Sul - Mesa de Descanso)
	_spawn_npc(
		"Bombeiro_Santos", "Bombeiro Santos",
		"res://assets/sprites/npcs/bombeiro_santos/bombeiro_santos_normal_spriteframes.tres",
		"res://assets/sprites/npcs/bombeiro_santos/bombeiro_santos_distorted_spriteframes.tres",
		Vector2(214, 456), "left", []
	)

	# 4. Enfermeira Maria (Ala Leste - Enfermaria)
	_spawn_npc(
		"Enfermeira_Maria", "Enfermeira Maria",
		"res://assets/sprites/npcs/enfermeira_maria/enfermeira_maria_normal_spriteframes.tres",
		"res://assets/sprites/npcs/enfermeira_maria/enfermeira_maria_distorted_spriteframes.tres",
		Vector2(752, 216), "left", []
	)

	# 5. Senhora Luningning / Espera (visível principalmente no Ato 2 na Recepção)
	_spawn_npc(
		"Velhinha_Espera", "Senhora Luningning",
		"res://assets/sprites/npcs/senhora_luningning/senhora_luningning_normal_spriteframes.tres",
		"res://assets/sprites/npcs/senhora_luningning/senhora_luningning_distorted_spriteframes.tres",
		Vector2(368, 464), "up", []
	)


func _spawn_npc(id: String, prompt: String, norm_path: String, dist_path: String, pos: Vector2, dir: String, patrol: Array[Vector2]) -> void:
	var npc := NPC_SCENE.instantiate() as NpcEntity
	npc.name = id
	npc.npc_id = id
	npc.interact_verb = "Conversar"
	npc.interact_prompt = prompt
	if norm_path.ends_with(".tres"):
		npc.normal_frames_path = norm_path
	else:
		npc.normal_sheet_path = norm_path
	if dist_path.ends_with(".tres"):
		npc.distorted_frames_path = dist_path
	else:
		npc.distorted_sheet_path = dist_path
	npc.facing_dir = dir
	npc.patrol_points = patrol
	npc.position = pos
	npc.npc_interacted.connect(_on_npc_interacted)
	ysort_root.add_child(npc)
	_npcs[id] = npc


func _setup_static_interactables() -> void:
	_add_interactable("Cilindros_Parede", "Cilindros de Combate", "Examinar", Vector2(168, 134), Vector2(56, 30))
	_add_interactable("Porta_Saida_Quartel", "Saída do Quartel", "Sair", Vector2(480, 550), Vector2(64, 28))
	_add_interactable("Arquivo_Clinica", "Prontuário Ocupacional", "Examinar", Vector2(720, 146), Vector2(48, 28))


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

	inter.interacted.connect(_on_static_interacted)
	interactables_root.add_child(inter)


func _apply_station_atmosphere() -> void:
	var act3 := GameState.is_unfiltered_act3()
	var higher := _is_higher_dose_active()
	var ato: int = int(GameState.get_var("Ato", 1))

	var active_base_ts: TileSet = ACT3_TS if act3 else NORMAL_TS
	floor_normal.tile_set = active_base_ts
	walls_normal.tile_set = active_base_ts
	if _furniture_layer != null:
		_furniture_layer.tile_set = ACT3_TS if act3 else (DISTORTED_TS if higher else NORMAL_TS)
	floor_normal.visible = not higher
	walls_normal.visible = not higher
	floor_distorted.visible = higher
	walls_distorted.visible = higher

	for s in _normal_props:
		s.visible = not higher
	for s in _distorted_props:
		s.visible = higher
	for d in _distorted_decals:
		d.visible = higher

	for id in _npcs:
		var npc: NpcEntity = _npcs[id]
		if npc == null or not is_instance_valid(npc):
			continue
		if id == "Velhinha_Espera":
			var show_luningning := (ato == 2 and not GameState.get_switch("018_Gatinho_devolvido"))
			npc.visible = show_luningning
			npc.set_physics_process(show_luningning)
			var ia := npc.get_node_or_null("InteractArea")
			if ia:
				ia.visible = show_luningning
			npc.set_distorted_state(higher)
		else:
			npc.set_distorted_state(higher)

	var period: String = GameState.get_day_period() if GameState.has_method("get_day_period") else ("afternoon" if GameState.is_afternoon else "morning")
	if canvas_mod:
		if act3:
			canvas_mod.color = Color(0.62, 0.64, 0.67, 1.0)
		elif higher:
			canvas_mod.color = Color(0.54, 0.49, 0.56, 1.0)
		elif period == "night":
			canvas_mod.color = Color(0.50, 0.54, 0.64, 1.0)
		elif period == "afternoon":
			canvas_mod.color = Color(0.66, 0.62, 0.68, 1.0)
		else:
			canvas_mod.color = Color(0.74, 0.76, 0.82, 1.0)

	for lt in _lights:
		if lt == null:
			continue
		if higher:
			lt.color = Color(0.92, 0.46, 0.52)
		elif act3:
			lt.color = Color(0.86, 0.88, 0.90)

	if has_node("/root/AudioManager"):
		var am = get_node("/root/AudioManager")
		if am.has_method("sync_adaptive_soundtrack"):
			am.call("sync_adaptive_soundtrack", "fire_station", false)


func _on_npc_interacted(npc_id: String) -> void:
	_trigger_interaction_id(npc_id)


func _on_static_interacted(inter: Interactable) -> void:
	_trigger_interaction_id(inter.interaction_id)


func _on_dialogue_conflict_triggered(target_id: String, _context: Dictionary) -> void:
	if _npcs.has(target_id):
		var npc: NpcEntity = _npcs[target_id]
		if npc != null and is_instance_valid(npc):
			npc.turn_hostile()
			if has_node("/root/AudioManager"):
				get_node("/root/AudioManager").play_sfx("vhs_glitch")


func _trigger_interaction_id(id: String) -> void:
	var ato: int = int(GameState.get_var("Ato", 1))
	var higher := _is_higher_dose_active()

	match id:
		"Cap_Reyes":
			if higher:
				request_dialogue.emit([
					{
						"speaker": "Capitão Reyes",
						"expression": "distorted",
						"text": "\"Você tomou os frascos inteiros hoje, não foi, Huwag? Olhe para o mapa atrás de mim... os pinos não saem daquele galpão há dezoito meses.\""
					},
					{
						"speaker": "Capitão Reyes",
						"expression": "distorted",
						"text": "\"Termine os atendimentos na rua e fale com a senhora na recepção antes que o fogo engula a trilha leste outra vez.\""
					}
				], Callable())
				if not GameState.get_switch("007_Chefe_Ato2_apresentado"):
					GameState.set_switch("007_Chefe_Ato2_apresentado", true)
				return

			if ato == 1:
				if GameState.get_switch("003_Ovos_sem_derrotar") or GameState.get_switch("004_Ovos_e_derrotou"):
					if not GameState.get_switch("005_Chefe_liberou_cidade"):
						GameState.set_switch("005_Chefe_liberou_cidade", true)
						var msg := (
							"Você trouxe os ovos e enfrentou aquela criatura na clareira? Bom trabalho, Huwag. Vá para casa descansar por hoje."
							if GameState.get_switch("004_Ovos_e_derrotou") else
							"Você recolheu os ovos e conseguiu sair da clareira a tempo. Já é fim de tarde, Huwag — vá para casa descansar."
						)
						request_dialogue.emit([{"speaker": "Capitão Reyes", "text": msg}], Callable())
					else:
						request_dialogue.emit([{"speaker": "Capitão Reyes", "text": "Seu turno já terminou por hoje, anak. Vá descansar em casa."}], Callable())
				elif not GameState.get_switch("002_Chefe_Ato1_apresentado"):
					GameState.set_switch("002_Chefe_Ato1_apresentado", true)
					request_dialogue.emit([
						{
							"speaker": "Capitão Reyes",
							"text": "Huwag, precisamos conversar sobre ontem... Você estava distante no chamado. Está tomando os remédios direito? Eu me preocupo com você, anak."
						},
						{
							"speaker": "Capitão Reyes",
							"text": "Recebemos um chamado estranho na trilha leste, dentro da floresta de Agdangan. Siga até a clareira e traga o que encontrar."
						}
					], Callable())
				else:
					request_dialogue.emit([{
						"speaker": "Huwag",
						"text": "(O Capitão Reyes revisa os despachos no rádio. Preciso ir para a estrada da floresta ao leste da cidade.)"
					}], Callable())
			elif ato == 2:
				if not GameState.get_switch("007_Chefe_Ato2_apresentado"):
					GameState.set_switch("007_Chefe_Ato2_apresentado", true)
					request_dialogue.emit([{
						"speaker": "Capitão Reyes",
						"text": "Bom dia, Huwag. Kuya Ben no Jeepney, Aling Nena na Sari-Sari e o pessoal da feira pediram ajuda na rua principal. Apoie ao menos um deles e volte para retirar seu suprimento."
					}], Callable())
				elif GameState.get_switch("020_Alguma_missao_completa") and not GameState.get_switch("021_Recompensa_entregue"):
					GameState.set_switch("021_Recompensa_entregue", true)
					GameState.add_item("gota_calmante", 1)
					request_dialogue.emit([{
						"speaker": "Capitão Reyes",
						"text": "Excelente apoio aos moradores, Huwag (+1 Cápsula Calmante).\nAgora fale imediatamente com a Senhora Luningning na sala de espera da recepção — é uma emergência na floresta."
					}], Callable())
				elif GameState.get_switch("019_Ato2_concluido"):
					request_dialogue.emit([{
						"speaker": "Capitão Reyes",
						"text": "Você conteve o incêndio na floresta e salvou o gato da senhora. Pode voltar ao seu quarto para descansar quando quiser."
					}], Callable())
				else:
					request_dialogue.emit([{
						"speaker": "Capitão Reyes",
						"text": "Ajude os moradores na rua principal e depois atenda à senhora na recepção, Huwag."
					}], Callable())
			else:
				GameState.set_switch("024_Ato3_revelacao_reyes", true)
				request_dialogue.emit([
					{
						"speaker": "Capitão Reyes",
						"text": "Huwag... Eu vi no seu olhar assim que cruzou a porta. Os comprimidos acabaram, não foi?"
					},
					{
						"speaker": "Capitão Reyes",
						"text": "Desde aquela madrugada no galpão, quando o teto desabou sobre a equipe... você nunca mais dormiu em paz. Os remédios amorteceram o impacto, mas transformaram a culpa em monstros de água e fogo."
					},
					{
						"speaker": "Capitão Reyes",
						"text": "Sobreviver não faz de você o culpado, anak. Para continuar de pé por Agdangan, vá até a clareira uma última vez e encare o que restou sem filtros."
					}
				], Callable())

		"Velhinha_Espera":
			if ato < 2:
				request_dialogue.emit([{"speaker": "Huwag", "text": "O banco da recepção está vazio e frio."}], Callable())
			elif ato == 2:
				if GameState.get_switch("018_Gatinho_devolvido"):
					request_dialogue.emit([{"speaker": "Senhora Luningning", "text": "Salamat po, Huwag! Meu gatinho está seguro graças a você."}], Callable())
				elif GameState.get_switch("017_Gatinho_encontrado"):
					GameState.set_switch("018_Gatinho_devolvido", true)
					GameState.set_switch("019_Ato2_concluido", true)
					request_dialogue.emit([{
						"speaker": "Senhora Luningning",
						"text": "Você o tirou da fumaça na clareira! Muito obrigada, Huwag! Seu turno por hoje acabou — vá descansar em casa."
					}], Callable())
				elif GameState.get_switch("020_Alguma_missao_completa"):
					GameState.set_switch("014_Floresta_liberada", true)
					GameState.set_switch("015_Floresta_em_chamas", true)
					request_dialogue.emit([{
						"speaker": "Senhora Luningning",
						"expression": "distorted" if higher else "default",
						"text": "Bombeiro Huwag! O fogo tomou a floresta ao leste e meu gatinho fugiu direto para a clareira!\nA estrada foi liberada — atravesse a mata e traga-o de volta!"
					}], Callable())
				else:
					request_dialogue.emit([{
						"speaker": "Senhora Luningning",
						"text": "Estou aguardando o Capitão liberar o chamado... Já dá para sentir cheiro de fumaça subindo do leste."
					}], Callable())
			else:
				request_dialogue.emit([{"speaker": "Huwag", "text": "Só há marcas de bota e cinza secas no banco da sala de espera."}], Callable())

		"Bombeiro_Ato":
			if higher:
				request_dialogue.emit([
					{
						"speaker": "Bombeiro Ato",
						"expression": "distorted",
						"text": "\"Por que você deixou o trinco fechado por fora quando a viga desabou sobre nós no galpão, Huwag?\"\nOs olhos dele não piscam sob o capacete queimado.",
						"choices": [
							"\"A fumaça me cegou... eu não alcancei a corrente!\"",
							"\"Não foi culpa minha! Cala essa boca!\""
						],
						"conflict_choices": {1: "Bombeiro_Ato"}
					}
				], Callable())
			else:
				request_dialogue.emit([{
					"speaker": "Bombeiro Ato",
					"text": "Tô conferindo a pressão das mangueiras aqui na ala oeste. O caminhão lá fora também precisa de revisão se precisar de ajuda na rua."
				}], Callable())

		"Bombeiro_Santos":
			if higher:
				request_dialogue.emit([{
					"speaker": "Bombeiro Santos",
					"expression": "distorted",
					"text": "\"Ainda lembra quantos pares de luvas sobram na fileira? Ficam sempre três pares vazios esperando dono.\""
				}], Callable())
			else:
				request_dialogue.emit([{
					"speaker": "Bombeiro Santos",
					"text": "Bro, você mal dormiu de novo. Toma água na enfermaria se sentir a visão turvar durante a ronda."
				}], Callable())

		"Enfermeira_Maria":
			if higher:
				request_dialogue.emit([
					{
						"speaker": "Enfermeira Maria",
						"expression": "distorted",
						"text": "Ela segura uma prancheta manchada de vermelho.\n\"A dosagem de hoje passou do limite seguro, Huwag. Vai continuar negando que os nomes neste prontuário eram reais?\"",
						"choices": [
							"\"Eu me lembro deles... não estou tentando apagar ninguém.\"",
							"\"Você está inventando isso! Larga essa prancheta!\""
						],
						"conflict_choices": {1: "Enfermeira_Maria"}
					}
				], Callable())
			else:
				request_dialogue.emit([{
					"speaker": "Enfermeira Maria",
					"text": "Passei cedo para conferir seus sinais vitais e receitas, Huwag. Não exceda três comprimidos por dia — o rebote piora os apagões."
				}], Callable())

		"Cilindros_Parede":
			request_dialogue.emit([{
				"speaker": "Huwag",
				"text": "Três cilindros vermelhos de combate em fila junto ao armário de prontidão. Sempre três, alinhados milimetricamente."
			}], Callable())

		"Arquivo_Clinica":
			request_dialogue.emit([{
				"speaker": "Huwag",
				"expression": "scared" if higher else "worried",
				"text": "Fichas médicas da BFP Agdangan. Metade das linhas no meu prontuário está riscada com caneta preta."
			}], Callable())

		"Porta_Saida_Quartel":
			if ato == 1 and not GameState.get_switch("002_Chefe_Ato1_apresentado"):
				GameState.set_switch("001_Porta_Bombeiros_1a_vez", true)
				request_dialogue.emit([{
					"speaker": "Huwag",
					"text": "Acabei de entrar no quartel. Preciso me apresentar ao Capitão Reyes no comando ao norte antes de sair."
				}], Callable())
			else:
				request_dialogue.emit([
					{
						"speaker": "Huwag",
						"text": "Sair do quartel para a rua de Agdangan?",
						"choices": ["Sair para a rua", "Continuar no quartel"]
					}
				], func(choice: int) -> void:
					if choice == 0:
						request_level_change.emit("res://scenes/levels/StreetPreview.tscn", "from_station")
				)
