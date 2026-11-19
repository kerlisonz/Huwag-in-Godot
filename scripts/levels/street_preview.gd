@tool
extends Node2D

signal request_level_change(target_scene: String, spawn_tag: String)
signal request_dialogue(pages: Array, callback: Callable)

const RetroLevelHelpers := preload("res://scripts/levels/retro_level_helpers.gd")
const V2TileCatalog := preload("res://scripts/levels/v2_tile_catalog.gd")
const AtmosphereRig := preload("res://scripts/levels/atmosphere_rig.gd")
const NPC_SCENE := preload("res://scenes/characters/NpcEntity.tscn")
const BACKDROP_TREE_SCENE := preload("res://scenes/components/ForestTree.tscn")
const BACKDROP_WITHERED_SCENE := preload("res://scenes/components/ForestWitheredPine.tscn")
const BACKDROP_SLENDER_SCENE := preload("res://scenes/components/ForestSlenderPine.tscn")
const TOWN_NORMAL_TS := preload("res://assets/tilesets/v2/agdangan_town_v2_normal_tileset.tres")
const TOWN_DISTORTED_TS := preload("res://assets/tilesets/v2/agdangan_town_v2_distorted_tileset.tres")
const TOWN_ACT3_TS := preload("res://assets/tilesets/v2/agdangan_town_v2_act3_tileset.tres")

# Rua compactada de Agdangan: 112 x 35 tiles de 16px (1792 x 560, faixa ativa y=128..560)
const MAP_W_TILES := 112
const MAP_H_TILES := 35
const MAP_BOUNDS := Rect2i(0, 128, MAP_W_TILES * 16, 432)

@onready var canvas_mod: CanvasModulate = $CanvasModulate
@onready var ground_normal: TileMapLayer = $TownGroundNormal
@onready var walls_normal: TileMapLayer = $TownWallsNormal
@onready var ground_distorted: TileMapLayer = $TownGroundDistorted
@onready var walls_distorted: TileMapLayer = $TownWallsDistorted
@onready var decals_layer: Node2D = $DecalsLayer
@onready var collisions_body: StaticBody2D = $CityCollisions
@onready var interactables_root: Node2D = $Interactables
@onready var ysort_root: Node2D = $YSortEntities
@onready var player: PlayerController = $YSortEntities/Player
@onready var lights_layer: Node2D = $LightsLayer

var _npcs: Dictionary = {}
var _normal_props: Array[Node2D] = []
var _distorted_props: Array[Node2D] = []
var _distorted_decals: Array[Node2D] = []
var _lamp_lights: Array[PointLight2D] = []
var _flicker_lamps: Array[PointLight2D] = []
var _window_lights: Array[PointLight2D] = []
var _spark_particles: Array[CPUParticles2D] = []
var _beacon_light: PointLight2D = null
var _wires_drawer: OverheadWiresDrawer = null
var _street_dust_particles: CPUParticles2D = null
var _street_smoke_particles: CPUParticles2D = null
var _town_props_layer: TileMapLayer = null
var _mission_interactables: Dictionary = {}
var _npc_mission_badges: Dictionary = {}
var _blink_timer: float = 0.0


class OverheadWiresDrawer extends Node2D:
	var pole_xs: Array[float] = []
	var dead_xs: Array[float] = []
	var drop_targets: Array[Dictionary] = []
	var phase_time: float = 0.0
	var is_distorted: bool = false

	func _draw() -> void:
		var cable_main := Color(0.05, 0.06, 0.09, 0.90) if not is_distorted else Color(0.06, 0.05, 0.14, 0.94)
		var cable_sec := Color(0.09, 0.11, 0.15, 0.78) if not is_distorted else Color(0.16, 0.14, 0.30, 0.86)
		var coil_col := Color(0.04, 0.05, 0.07, 0.95)
		var top_y := 326.0

		# Feixes de fios principais emaranhados conectando postes sequenciais
		for i in range(pole_xs.size() - 1):
			var x0 := pole_xs[i]
			var x1 := pole_xs[i + 1]
			var cable_count := 4 + (i % 3)
			for c in range(cable_count):
				var y_off0 := top_y + float(c % 3) * 3.0
				var y_off1 := top_y + float((c + 1) % 3) * 3.0
				var sag := 10.0 + float(c) * 4.5 + sin(x0 * 0.07 + float(c)) * 3.5
				var col := cable_main if (c % 2 == 0) else cable_sec
				var width := 1.4 if (c == 0) else 1.0
				var pts := PackedVector2Array()
				var steps := 10
				for s in range(steps + 1):
					var t := float(s) / float(steps)
					var px := lerpf(x0, x1, t)
					var arch := sin(t * PI)
					var sway := sin(phase_time * (1.4 + float(c) * 0.25) + x0 * 0.02 + float(c)) * 1.4 * arch
					var py := lerpf(y_off0, y_off1, t) + arch * sag + sway
					pts.append(Vector2(px, py))
				draw_polyline(pts, col, width, false)

		# Rolos de fio sobressalente e feixes nos isoladores de cada poste
		for i in range(pole_xs.size()):
			var px := pole_xs[i]
			draw_circle(Vector2(px + 3.0, top_y + 4.0), 3.0, coil_col)
			if i % 2 == 0:
				draw_circle(Vector2(px - 3.0, top_y + 6.0), 2.2, cable_sec)

		# Derivações diagonais para telhados/fachadas ao longo da rua
		for d in drop_targets:
			var from_pt: Vector2 = d["from"]
			var to_pt: Vector2 = d["to"]
			var sag_drop: float = float(d.get("sag", 9.0))
			var pts := PackedVector2Array()
			for s in range(7):
				var t := float(s) / 6.0
				var arch := sin(t * PI)
				var sway := sin(phase_time * 1.8 + from_pt.x * 0.03) * 0.9 * arch
				pts.append(from_pt.lerp(to_pt, t) + Vector2(0.0, arch * sag_drop + sway))
			draw_polyline(pts, cable_sec, 1.0, false)

		# Fios soltos/rompidos balançando nos postes danificados
		for dx in dead_xs:
			for k in range(2):
				var anchor := Vector2(dx + (2.0 if k == 0 else -2.0), top_y + 3.0)
				var wire_len := 24.0 + float(k) * 11.0
				var swing := sin(phase_time * (2.6 + float(k) * 0.7) + dx * 0.05) * 4.5
				var pts := PackedVector2Array([
					anchor,
					anchor + Vector2(swing * 0.45, wire_len * 0.55),
					anchor + Vector2(swing, wire_len)
				])
				draw_polyline(pts, cable_main, 1.2, false)


func _ready() -> void:
	if Engine.is_editor_hint():
		_setup_editor_preview()
		return

	match GameState.spawn_tag:
		"from_room":
			player.position = Vector2(408, 378)
			player.facing_dir = Vector2.DOWN
		"from_station":
			player.position = Vector2(792, 364)
			player.facing_dir = Vector2.DOWN
		"from_forest":
			player.position = Vector2(1704, 448)
			player.facing_dir = Vector2.LEFT
		_:
			player.position = Vector2(408, 378)
			player.facing_dir = Vector2.DOWN

	player.set_camera_limits(MAP_BOUNDS)

	_build_town_tilemaps()
	_build_town_props_and_lights()
	_build_overhead_wires()
	_build_ambient_particles()
	_setup_collisions()
	_spawn_town_npcs()
	_setup_interactables()

	GameState.time_of_day_changed.connect(func(_v: bool) -> void: _apply_visual_atmosphere())
	GameState.perception_changed.connect(func(_m: int) -> void: _apply_visual_atmosphere())
	GameState.switch_changed.connect(func(_k: String, _v: bool) -> void: _apply_visual_atmosphere())
	if GameState.has_signal("day_period_changed"):
		GameState.day_period_changed.connect(func(_p: String) -> void: _apply_visual_atmosphere())
	if GameState.has_signal("higher_dose_changed"):
		GameState.higher_dose_changed.connect(func(active: bool) -> void: apply_higher_dose_world(active))

	_apply_visual_atmosphere()


func _setup_editor_preview() -> void:
	RetroLevelHelpers.cleanup_editor_preview(self)
	_npcs.clear()
	_normal_props.clear()
	_distorted_props.clear()
	_distorted_decals.clear()
	_lamp_lights.clear()
	_flicker_lamps.clear()
	_window_lights.clear()
	_spark_particles.clear()
	_beacon_light = null
	_wires_drawer = null
	_town_props_layer = null
	_mission_interactables.clear()
	_npc_mission_badges.clear()
	var orig_gn := ground_normal
	var orig_wn := walls_normal
	var orig_gd := ground_distorted
	var orig_wd := walls_distorted
	ground_normal = RetroLevelHelpers.create_preview_tilemap(self, "EditorPreviewGround", -2)
	walls_normal = RetroLevelHelpers.create_preview_tilemap(self, "EditorPreviewWalls", -1)
	var tmp_gd := TileMapLayer.new()
	var tmp_wd := TileMapLayer.new()
	ground_distorted = tmp_gd
	walls_distorted = tmp_wd
	_build_town_tilemaps()
	_build_town_props_and_lights()
	_build_overhead_wires()
	_spawn_town_npcs()
	ground_normal = orig_gn
	walls_normal = orig_wn
	ground_distorted = orig_gd
	walls_distorted = orig_wd
	tmp_gd.free()
	tmp_wd.free()
	RetroLevelHelpers.mark_unowned_preview_children([self, ysort_root, decals_layer, lights_layer])


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_blink_timer += delta
	if _beacon_light != null:
		var pulse := 0.55 + 0.40 * absf(sin(_blink_timer * 3.4))
		_beacon_light.energy = pulse

	var higher := _is_higher_dose_active()
	for lt in _flicker_lamps:
		if lt == null or not is_instance_valid(lt):
			continue
		var phase := float(lt.get_meta("phase", 0.0))
		var burst := sin(_blink_timer * 14.0 + phase) * cos(_blink_timer * 29.0 + phase * 1.3)
		var gate := sin(_blink_timer * 2.1 + phase * 0.7)
		var e := 0.05
		if gate > 0.25 or (burst > 0.42 and not higher):
			e = 0.42 + 0.26 * absf(burst)
		elif higher and burst > 0.30:
			e = 0.58
		lt.energy = e

	if _wires_drawer != null:
		_wires_drawer.phase_time = _blink_timer
		_wires_drawer.is_distorted = higher
		_wires_drawer.queue_redraw()

	# Pulso suave nos marcadores de missão ativos da rua
	var bob := sin(_blink_timer * 4.2) * 2.0
	for nid in _npc_mission_badges:
		var badge: Label = _npc_mission_badges[nid]
		if badge != null and is_instance_valid(badge) and badge.visible:
			badge.position.y = -38.0 + bob
	for mid in _mission_interactables:
		var minter: Interactable = _mission_interactables[mid]
		if minter != null and is_instance_valid(minter) and minter.visible:
			var glow_node := minter.get_node_or_null("Beacon") as Node2D
			if glow_node != null:
				glow_node.position.y = -12.0 + bob


func apply_higher_dose_world(_active: bool) -> void:
	_apply_visual_atmosphere()


func _is_higher_dose_active() -> bool:
	if Engine.is_editor_hint():
		return false
	return GameState.has_method("is_higher_dose") and GameState.is_higher_dose()


func _is_night() -> bool:
	if Engine.is_editor_hint():
		return false
	if GameState.is_unfiltered_act3():
		return false
	if GameState.has_method("is_night_time") and GameState.is_night_time():
		return true
	var ato: int = int(GameState.get_var("Ato", 1))
	return (
		(ato == 1 and GameState.get_switch("005_Chefe_liberou_cidade"))
		or (ato == 2 and GameState.get_switch("019_Ato2_concluido"))
	)


func _build_town_tilemaps() -> void:
	var t_cat := V2TileCatalog.TOWN_TILES
	for layer in [ground_normal, walls_normal]:
		layer.tile_set = TOWN_ACT3_TS if RetroLevelHelpers.is_act3_unfiltered() else TOWN_NORMAL_TS
		layer.z_index = -2 if layer == ground_normal else -1
	for layer in [ground_distorted, walls_distorted]:
		layer.tile_set = TOWN_DISTORTED_TS
		layer.z_index = -2 if layer == ground_distorted else -1
		layer.collision_enabled = false

	for gl in [ground_normal, ground_distorted]:
		gl.clear()
		# Base contínua de gramado provincial filipino 16x16 no mapa compactado 112x35
		for gy in range(0, MAP_H_TILES):
			for gx in range(0, MAP_W_TILES):
				var gtile: Vector2i = t_cat["grass_b"] if ((gx * 7 + gy * 13) % 5 == 0) else t_cat["grass_a"]
				gl.set_cell(Vector2i(gx, gy), 0, gtile)

		# Costa oeste de Agdangan: oceano animado, água rasa, espuma costeira e transição suave areia <-> terra
		V2TileCatalog.fill_rect(gl, Rect2i(0, 0, 4, MAP_H_TILES), t_cat["sea_water_anim"])
		V2TileCatalog.fill_rect(gl, Rect2i(4, 0, 2, MAP_H_TILES), t_cat["shallow_water_anim"])
		for sy in range(0, MAP_H_TILES):
			gl.set_cell(Vector2i(6, sy), 0, t_cat["sand_edge_w"])
			for sx in range(7, 16):
				if sx <= 10:
					var stile: Vector2i = t_cat["sand_b"] if (sx == 7 or (sx + sy) % 4 == 0) else t_cat["sand_a"]
					gl.set_cell(Vector2i(sx, sy), 0, stile)
				elif sx == 11:
					gl.set_cell(Vector2i(sx, sy), 0, t_cat["sand_dirt_mix"])
				elif sx == 12:
					gl.set_cell(Vector2i(sx, sy), 0, t_cat["sand_dirt_blend"])
				else:
					var dtile: Vector2i = t_cat["dirt_b"] if ((sx + sy) % 3 == 0) else t_cat["dirt_a"]
					gl.set_cell(Vector2i(sx, sy), 0, dtile)

		# Calçadão de pedra alinhado ao píer e Píer de madeira contínuo (x: 4..13, y: 26..28)
		V2TileCatalog.fill_rect(gl, Rect2i(14, 24, 2, 7), t_cat["plaza_slab"])
		for py in range(26, 29):
			gl.set_cell(Vector2i(4, py), 0, t_cat["pier_plank_l"])
			for px in range(5, 13):
				gl.set_cell(Vector2i(px, py), 0, t_cat["pier_plank"])
			gl.set_cell(Vector2i(13, py), 0, t_cat["pier_plank_r"])
		for px in [4, 5]:
			gl.set_cell(Vector2i(px, 29), 0, t_cat["pier_post"])

		# Calçada Norte contínua (y=23..24, x=16..103) + Pátios compactos BFP, Igreja e Feira
		V2TileCatalog.fill_rect(gl, Rect2i(16, 23, 88, 1), t_cat["curb_top"])
		V2TileCatalog.fill_rect(gl, Rect2i(16, 24, 88, 1), t_cat["curb_bottom"])
		V2TileCatalog.fill_rect(gl, Rect2i(37, 21, 15, 2), t_cat["plaza_slab"]) # Pátio BFP
		V2TileCatalog.fill_rect(gl, Rect2i(68, 20, 13, 3), t_cat["plaza_slab"]) # Adro compacto da Igreja
		V2TileCatalog.fill_rect(gl, Rect2i(82, 22, 11, 1), t_cat["plaza_slab"]) # Pátio da Feira
		for alley_x in [21, 29, 35, 52, 59, 67, 81, 87, 93]:
			V2TileCatalog.fill_rect(gl, Rect2i(alley_x, 21, 1, 2), t_cat["plaza_slab"])

		# Avenida principal asfaltada contínua (x: 16..103, y: 25..31) + Calçada Sul (y=32) + acostamento em terra
		V2TileCatalog.fill_rect(gl, Rect2i(16, 25, 88, 7), t_cat["asphalt"])
		V2TileCatalog.fill_rect(gl, Rect2i(16, 32, 88, 1), t_cat["curb_top"])
		V2TileCatalog.fill_rect(gl, Rect2i(16, 33, 88, 2), t_cat["dirt_a"])
		for sx in range(16, 104, 3):
			gl.set_cell(Vector2i(sx, 34), 0, t_cat["dirt_b"])

		# Faixa central tracejada e faixas de pedestres
		for rx in range(20, 102, 3):
			gl.set_cell(Vector2i(rx, 28), 0, t_cat["asphalt_dash_h"])
		for cw_x in [25, 45, 74, 89]:
			V2TileCatalog.fill_rect(gl, Rect2i(cw_x, 25, 2, 7), t_cat["crosswalk"])

		# Estrada de terra leste entrando na floresta (x: 104..111, y: 25..31) sem recorte quadriculado
		V2TileCatalog.fill_rect(gl, Rect2i(104, 25, 8, 7), t_cat["dirt_a"])
		for dy in [26, 27, 28, 30]:
			gl.set_cell(Vector2i(103, dy), 0, t_cat["dirt_a"])
		gl.set_cell(Vector2i(102, 27), 0, t_cat["dirt_b"])
		gl.set_cell(Vector2i(102, 29), 0, t_cat["dirt_b"])
		for dy in range(26, 31):
			gl.set_cell(Vector2i(107, dy), 0, t_cat["dirt_b"])

		# Poças de chuva tropical e rachaduras discretas ao longo da avenida compacta
		for p_pos in [
			Vector2i(19, 29), Vector2i(28, 26), Vector2i(39, 30), Vector2i(50, 29),
			Vector2i(62, 26), Vector2i(71, 29), Vector2i(80, 26), Vector2i(95, 29), Vector2i(101, 26)
		]:
			gl.set_cell(p_pos, 0, t_cat["asphalt_puddle"])

		for crk_pos in [
			Vector2i(22, 27), Vector2i(34, 29), Vector2i(48, 26), Vector2i(65, 30),
			Vector2i(78, 26), Vector2i(86, 29), Vector2i(98, 27)
		]:
			gl.set_cell(crk_pos, 0, t_cat["asphalt_crack"])

	# Prédios de grande porte (Quartel BFP e Igreja trazida para perto da avenida)
	for wl in [walls_normal, walls_distorted]:
		wl.clear()
		var win_t: Vector2i = t_cat["wall_window_lit"] if (wl == walls_distorted or _is_night()) else t_cat["wall_window_dark"]

		# CENTRAL DE BOMBEIROS BFP AGDANGAN (x: 37..51, y: 10..20, porta em x=49)
		_paint_building(wl, 37, 10, 15, 11, t_cat["roof_yero_rust"], t_cat["wall_bfp_red"], true, 49)
		V2TileCatalog.fill_rect(wl, Rect2i(37, 14, 15, 1), t_cat["roof_yero_rust_eave"])
		V2TileCatalog.fill_rect(wl, Rect2i(42, 17, 4, 4), t_cat["wall_bfp_shutter"])
		for wx in [39, 41, 47, 50]:
			wl.set_cell(Vector2i(wx, 16), 0, win_t)
			wl.set_cell(Vector2i(wx, 18), 0, win_t)

		# Igreja de Agdangan próxima à rua (x: 69..79, y: 12..19, porta em x=74)
		_paint_building(wl, 69, 12, 11, 8, t_cat["roof_yero_grey"], t_cat["wall_concrete"], true, 74)
		V2TileCatalog.fill_rect(wl, Rect2i(69, 15, 11, 1), t_cat["roof_yero_grey_eave"])
		wl.set_cell(Vector2i(71, 17), 0, win_t)
		wl.set_cell(Vector2i(77, 17), 0, win_t)

		# Cercas de bambu alinhadas delimitando quintais sem árvores cortadas na frente
		V2TileCatalog.fill_rect(wl, Rect2i(14, 12, 1, 10), t_cat["fence_bamboo_v"])
		V2TileCatalog.fill_rect(wl, Rect2i(15, 12, 22, 1), t_cat["fence_bamboo_h"])
		V2TileCatalog.fill_rect(wl, Rect2i(52, 14, 17, 1), t_cat["fence_bamboo_h"])
		V2TileCatalog.fill_rect(wl, Rect2i(68, 12, 1, 10), t_cat["fence_bamboo_v"])
		V2TileCatalog.fill_rect(wl, Rect2i(80, 12, 1, 10), t_cat["fence_bamboo_v"])
		V2TileCatalog.fill_rect(wl, Rect2i(81, 14, 21, 1), t_cat["fence_bamboo_h"])
		V2TileCatalog.fill_rect(wl, Rect2i(102, 14, 1, 8), t_cat["fence_bamboo_v"])

	# Camada Y-sorted com colisão real completa (casas, lojas, coqueiros, veículos e árvores inteiras)
	if _town_props_layer == null:
		_town_props_layer = TileMapLayer.new()
		_town_props_layer.name = "V2TownPropsLayer"
		_town_props_layer.z_index = 0
		_town_props_layer.y_sort_enabled = true
		_town_props_layer.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_town_props_layer.collision_enabled = true
		if ysort_root != null:
			ysort_root.add_child(_town_props_layer)
		else:
			add_child(_town_props_layer)
	if not Engine.is_editor_hint():
		if decals_layer != null:
			decals_layer.z_index = 0
		if ysort_root != null:
			ysort_root.z_index = 2
	_town_props_layer.tile_set = TOWN_ACT3_TS if RetroLevelHelpers.is_act3_unfiltered() else (TOWN_DISTORTED_TS if _is_higher_dose_active() else TOWN_NORMAL_TS)
	_town_props_layer.clear()

	# Casas & Mercearias compactadas lado a lado ao longo do quarteirão norte
	# 1. Casa Oeste (Lola Rosa): x=15..20, y=17..21
	V2TileCatalog.stamp_rect(_town_props_layer, Vector2i(15, 17), t_cat["house_concrete_grey"], Vector2i(6, 5))
	# 2. Casa de Huwag: x=23..28, y=17..21 (porta centrada em x=408 px)
	V2TileCatalog.stamp_rect(_town_props_layer, Vector2i(23, 17), t_cat["house_concrete_rust"], Vector2i(6, 5))
	# 3. Sari-Sari Store de Aling Nena: x=30..34, y=18..21
	V2TileCatalog.stamp_rect(_town_props_layer, Vector2i(30, 18), t_cat["sari_sari_store"], Vector2i(5, 4))

	# 4. Viatura BFP no pátio do Quartel (x=40..44, y=20..22) + hidrante
	V2TileCatalog.stamp_rect(_town_props_layer, Vector2i(40, 20), t_cat["bfp_truck"], Vector2i(5, 3))
	_town_props_layer.set_cell(Vector2i(38, 22), 0, t_cat["fire_hydrant"])

	# 5. Karinderya (x=54..58, y=18..21) + Triciclo de Kuya Ben (x=55..57, y=25..26)
	V2TileCatalog.stamp_rect(_town_props_layer, Vector2i(54, 18), t_cat["sari_sari_store"], Vector2i(5, 4))
	V2TileCatalog.stamp_rect(_town_props_layer, Vector2i(55, 25), t_cat["tricycle"], Vector2i(3, 2))

	# 6. Casa Residencial Central (x=61..66, y=17..21)
	V2TileCatalog.stamp_rect(_town_props_layer, Vector2i(61, 17), t_cat["house_concrete_grey"], Vector2i(6, 5))

	# 7. Bancos próximos no adro compacto da Igreja
	V2TileCatalog.stamp_rect(_town_props_layer, Vector2i(70, 21), t_cat["plaza_bench"], Vector2i(2, 1))
	V2TileCatalog.stamp_rect(_town_props_layer, Vector2i(77, 21), t_cat["plaza_bench"], Vector2i(2, 1))

	# 8. Feira & Casa Leste compactadas (x=82..99, y=17..21)
	V2TileCatalog.stamp_rect(_town_props_layer, Vector2i(82, 18), t_cat["sari_sari_store"], Vector2i(5, 4))
	V2TileCatalog.stamp_rect(_town_props_layer, Vector2i(88, 18), t_cat["sari_sari_store"], Vector2i(5, 4))
	V2TileCatalog.stamp_rect(_town_props_layer, Vector2i(94, 17), t_cat["house_concrete_rust"], Vector2i(6, 5))

	# Abundância de coqueiros costeiros & tropicais (praia, quintais e orla sul — 100% colidíveis)
	var palm_spots := [
		Vector2i(7, 3), Vector2i(10, 6), Vector2i(7, 10), Vector2i(10, 14),
		Vector2i(7, 19),
		Vector2i(7, 29), Vector2i(10, 29),
		Vector2i(18, 12), Vector2i(26, 12),
		Vector2i(55, 12), Vector2i(63, 12), Vector2i(85, 12), Vector2i(95, 12)
	]
	for palm_pos in palm_spots:
		var p_key := "coconut_left" if palm_pos.x % 2 == 0 else "coconut_right"
		V2TileCatalog.stamp_rect(_town_props_layer, palm_pos, t_cat[p_key], Vector2i(3, 6))

	# Bananeiras esparsas apenas nos quintais e cantos de cerca
	var ban_spots := [
		Vector2i(21, 14), Vector2i(35, 14),
		Vector2i(52, 16), Vector2i(67, 15), Vector2i(81, 15), Vector2i(100, 17)
	]
	for ban_pos in ban_spots:
		V2TileCatalog.stamp_rect(_town_props_layer, ban_pos, t_cat["banana_plant"], Vector2i(2, 3))

	# Postes de iluminação ao longo da calçada compacta
	for lx_tile in [21, 35, 53, 60, 68, 81, 87, 101]:
		V2TileCatalog.stamp_rect(_town_props_layer, Vector2i(lx_tile, 19), t_cat["lamppost_lit"], Vector2i(1, 5))
	for dx_tile in [29, 79, 93]:
		V2TileCatalog.stamp_rect(_town_props_layer, Vector2i(dx_tile, 19), t_cat["lamppost_dark"], Vector2i(1, 5))


func _paint_building(wl: TileMapLayer, x0: int, y0: int, w: int, h: int, roof_tile: Vector2i, wall_tile: Vector2i, has_door: bool, door_x: int) -> void:
	var t_cat := V2TileCatalog.TOWN_TILES
	var roof_h := maxi(2, h / 2)
	V2TileCatalog.fill_rect(wl, Rect2i(x0, y0, w, roof_h), roof_tile)
	V2TileCatalog.fill_rect(wl, Rect2i(x0, y0 + roof_h, w, h - roof_h), wall_tile)
	if has_door:
		wl.set_cell(Vector2i(door_x, y0 + h - 1), 0, t_cat["wall_door"])
	for sx in range(x0, x0 + w):
		wl.set_cell(Vector2i(sx, y0 + h), 0, t_cat["shadow_top"])


func _build_town_props_and_lights() -> void:
	# Decais distorcidos Yume Nikki / manchas pela rua compactada
	for dx in [270.0, 408.0, 520.0, 680.0, 792.0, 904.0, 1024.0, 1192.0, 1340.0, 1440.0, 1580.0]:
		_add_distorted_decal("floor_stain", Vector2(dx, 444), Vector2(1.4, 1.1))
		_add_distorted_decal("yume_eye_rune", Vector2(dx - 24.0, 384), Vector2(1.1, 1.1))

	# Luzes PointLight2D nos postes acesos ao longo da via
	var lit_lamps_x := [344.0, 568.0, 856.0, 968.0, 1096.0, 1304.0, 1400.0, 1624.0]
	for lx in lit_lamps_x:
		var pl := RetroLevelHelpers.create_point_light(Vector2(lx, 396), Color(0.98, 0.80, 0.46), 0.92, 2.6)
		lights_layer.add_child(pl)
		_lamp_lights.append(pl)

	# Postes danificados com reator piscante intermitente e faíscas esparsas
	var dead_lamps_x := [472.0, 1272.0, 1496.0]
	for i in range(dead_lamps_x.size()):
		var dead_x: float = dead_lamps_x[i]
		var fl := RetroLevelHelpers.create_point_light(Vector2(dead_x, 386), Color(0.85, 0.72, 0.48), 0.35, 2.0)
		fl.set_meta("phase", float(i) * 1.93 + 0.4)
		lights_layer.add_child(fl)
		_flicker_lamps.append(fl)

		if dead_x == 472.0 or dead_x == 1496.0:
			var sparks := CPUParticles2D.new()
			sparks.position = Vector2(dead_x, 344)
			sparks.z_index = 6
			sparks.amount = 6
			sparks.lifetime = 0.65
			sparks.explosiveness = 0.75
			sparks.randomness = 0.5
			sparks.direction = Vector2(0.0, 1.0)
			sparks.spread = 55.0
			sparks.gravity = Vector2(0.0, 95.0)
			sparks.initial_velocity_min = 18.0
			sparks.initial_velocity_max = 42.0
			sparks.scale_amount_min = 1.5
			sparks.scale_amount_max = 2.5
			sparks.color = Color(1.0, 0.76, 0.30, 0.90)
			lights_layer.add_child(sparks)
			_spark_particles.append(sparks)

	# Luzes de janelas e fachadas (Casas, Sari-Sari, Quartel BFP, Igreja)
	var window_defs := [
		{"pos": Vector2(288, 326), "col": Color(0.95, 0.78, 0.44), "e": 0.46, "s": 1.15},
		{"pos": Vector2(408, 326), "col": Color(0.95, 0.78, 0.44), "e": 0.46, "s": 1.15},
		{"pos": Vector2(520, 336), "col": Color(0.82, 0.94, 0.68), "e": 0.56, "s": 1.45},
		{"pos": Vector2(704, 272), "col": Color(0.85, 0.88, 0.96), "e": 0.55, "s": 1.65},
		{"pos": Vector2(792, 308), "col": Color(0.96, 0.82, 0.52), "e": 0.60, "s": 1.40},
		{"pos": Vector2(904, 336), "col": Color(0.96, 0.74, 0.42), "e": 0.52, "s": 1.40},
		{"pos": Vector2(1192, 260), "col": Color(0.92, 0.84, 0.62), "e": 0.58, "s": 1.85}
	]
	for wd in window_defs:
		var wl_pt := RetroLevelHelpers.create_point_light(wd["pos"], wd["col"], wd["e"], wd["s"])
		wl_pt.set_meta("base_color", wd["col"])
		wl_pt.set_meta("base_energy", wd["e"])
		lights_layer.add_child(wl_pt)
		_window_lights.append(wl_pt)

	# Giroflex vermelho sobre o quartel / caminhão BFP
	_beacon_light = RetroLevelHelpers.create_point_light(Vector2(696, 328), Color(0.62, 0.56, 0.92), 0.72, 1.8)
	lights_layer.add_child(_beacon_light)

	_build_forest_backdrop()
	_build_beach_props()
	_build_backyard_props()
	_build_sidewalk_props()

	var swarm := get_node_or_null("CorruptedEyeSwarm") as CorruptedEyeSwarm
	if swarm == null:
		swarm = CorruptedEyeSwarm.new()
		swarm.name = "CorruptedEyeSwarm"
		add_child(swarm)
	swarm.setup_world_swarm([
		Vector2(210, 410), Vector2(310, 392), Vector2(440, 384), Vector2(576, 376),
		Vector2(696, 382), Vector2(820, 388), Vector2(960, 372), Vector2(1110, 384),
		Vector2(1240, 392), Vector2(1380, 380), Vector2(1510, 388), Vector2(1660, 380),
		Vector2(1810, 392), Vector2(1940, 384), Vector2(2090, 376), Vector2(140, 520),
		Vector2(260, 620), Vector2(540, 610), Vector2(890, 615), Vector2(1210, 618),
		Vector2(1560, 612), Vector2(1920, 616), Vector2(740, 290), Vector2(1360, 286)
	], 6311, 0.95)


## Mata fechada ao norte e na borda leste, com as mesmas cenas ForestTree da trilha (Y-sort + colisão no tronco).
func _build_forest_backdrop() -> void:
	if ysort_root == null:
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = 20261119
	var row_ys := [26.0, 48.0, 70.0, 92.0, 114.0, 136.0, 158.0, 180.0, 202.0, 224.0]
	var row_idx := 0
	for base_y in row_ys:
		var x := 252.0 + (13.0 if row_idx % 2 == 1 else 0.0)
		while x <= 1644.0:
			var max_y := _backdrop_max_foot_y(x)
			var jy := rng.randf_range(-3.0, 3.0)
			var jx := rng.randf_range(-4.0, 4.0)
			if base_y + jy <= max_y:
				_add_backdrop_tree(Vector2(x + jx, base_y + jy), rng)
			x += 25.0
		row_idx += 1

	# Fileira frontal colada às cercas e fundos dos telhados (elimina faixas verdes entre a mata e o quintal)
	var fx := 256.0
	var f_idx := 0
	while fx <= 1640.0:
		var edge_y := _backdrop_max_foot_y(fx)
		var jx := rng.randf_range(-3.0, 3.0)
		var jy := rng.randf_range(-2.0, 2.0)
		_add_backdrop_tree(Vector2(fx + jx, edge_y + jy), rng)
		fx += 24.0 + (2.0 if f_idx % 2 == 0 else -1.0)
		f_idx += 1

	# Borda leste: mata densa acima e abaixo da estrada de terra (y 392..512 permanece aberta)
	var east_rows: Array[float] = []
	var ey := 26.0
	while ey <= 386.0:
		east_rows.append(ey)
		ey += 22.0
	east_rows.append(534.0)
	east_rows.append(554.0)
	var east_idx := 0
	for base_y2 in east_rows:
		var ex := 1646.0 + (12.0 if east_idx % 2 == 1 else 0.0)
		while ex <= 1798.0:
			_add_backdrop_tree(Vector2(ex + rng.randf_range(-3.0, 3.0), base_y2 + rng.randf_range(-2.5, 2.5)), rng)
			ex += 25.0
		east_idx += 1


## Altura máxima (y do pé) das árvores por faixa de x, colando na cerca/fundo sem invadir telhados.
func _backdrop_max_foot_y(x: float) -> float:
	if x < 584.0:
		return 194.0   # Cerca oeste em y=192..208
	if x < 838.0:
		return 162.0   # Quartel BFP (telhado começa em y=160)
	if x < 1094.0:
		return 226.0   # Cerca central em y=224..240
	if x < 1288.0:
		return 194.0   # Igreja (telhado começa em y=192)
	if x < 1638.0:
		return 226.0   # Cerca leste em y=224..240
	return 386.0


func _add_backdrop_tree(pos: Vector2, rng: RandomNumberGenerator) -> void:
	var roll := rng.randf()
	var scene: PackedScene = BACKDROP_TREE_SCENE
	if roll < 0.12:
		scene = BACKDROP_WITHERED_SCENE
	elif roll < 0.17:
		scene = BACKDROP_SLENDER_SCENE
	var tree := scene.instantiate() as Node2D
	if tree == null:
		return
	tree.set("enable_proximity_fade", false)
	tree.position = Vector2(roundf(pos.x), roundf(pos.y))
	ysort_root.add_child(tree)


## Adiciona um sprite de prop (normal + distorcido) ancorado pelo pé, com colisão opcional na base.
func _add_ground_prop(kind: String, foot: Vector2, col_size: Vector2 = Vector2.ZERO, scl: Vector2 = Vector2.ONE) -> void:
	if ysort_root == null:
		return
	var tex_h := float(RetroLevelHelpers.get_prop_texture(kind, false).get_height())
	var n_spr := RetroLevelHelpers.create_prop_sprite(kind, false)
	n_spr.position = foot
	n_spr.scale = scl
	n_spr.offset = Vector2(0.0, -tex_h * 0.5)
	var d_spr := RetroLevelHelpers.create_prop_sprite(kind, true)
	d_spr.position = foot
	d_spr.scale = scl
	d_spr.offset = Vector2(0.0, -tex_h * 0.5)
	d_spr.visible = false
	ysort_root.add_child(n_spr)
	ysort_root.add_child(d_spr)
	_normal_props.append(n_spr)
	_distorted_props.append(d_spr)
	if col_size != Vector2.ZERO:
		var body := StaticBody2D.new()
		body.position = foot + Vector2(0.0, -col_size.y * 0.5)
		body.collision_layer = 1
		body.collision_mask = 0
		var cs := CollisionShape2D.new()
		var rs := RectangleShape2D.new()
		rs.size = col_size
		cs.shape = rs
		body.add_child(cs)
		ysort_root.add_child(body)


func _build_beach_props() -> void:
	# Coqueiros de porte total já vêm de _build_town_props_and_lights(); aqui: vegetação, restos de maré e apetrechos de pesca
	# Faixa norte do píer (y < 410)
	for d in [[Vector2(150, 206), Vector2(26, 8)], [Vector2(134, 338), Vector2(26, 8)], [Vector2(168, 118), Vector2(26, 8)]]:
		_add_ground_prop("driftwood", d[0], d[1])
	_add_ground_prop("kaing_basket", Vector2(182, 396), Vector2(12, 6))
	_add_ground_prop("kaing_basket", Vector2(124, 160), Vector2(12, 6))
	_add_ground_prop("rope_coil", Vector2(206, 402), Vector2(12, 5))
	_add_ground_prop("market_crates", Vector2(200, 250), Vector2(24, 8))
	_add_ground_prop("mossy_rock", Vector2(204, 294), Vector2(20, 8))
	_add_ground_prop("mossy_rock", Vector2(122, 72 + 60), Vector2(20, 8))
	for p in [Vector2(126, 252), Vector2(160, 304), Vector2(190, 178), Vector2(142, 372), Vector2(212, 138), Vector2(176, 262)]:
		_add_ground_prop("starfish", p)
	for p in [Vector2(140, 188), Vector2(190, 352), Vector2(118, 300), Vector2(204, 226), Vector2(158, 140)]:
		_add_ground_prop("seashell", p)
	for p in [Vector2(214, 150), Vector2(214, 222), Vector2(212, 318), Vector2(214, 356), Vector2(216, 396), Vector2(214, 190)]:
		_add_ground_prop("beach_tuft", p)
	for p in [Vector2(204, 206), Vector2(206, 336), Vector2(194, 160)]:
		_add_ground_prop("pebbles", p)
	for p in [Vector2(210, 268), Vector2(210, 172)]:
		_add_ground_prop("fern_cluster", p)

	# Entrada do píer: lanternas baixas (calçadão de pedra) — corredor y 416..464 permanece livre
	for lp in [Vector2(238, 414), Vector2(238, 480)]:
		_add_ground_prop("pier_lantern", lp, Vector2(8, 6))
		var lamp := RetroLevelHelpers.create_point_light(lp + Vector2(0, -26), Color(1.0, 0.80, 0.46), 0.70, 1.5)
		lights_layer.add_child(lamp)
		_lamp_lights.append(lamp)

	# Faixa sul do píer (y > 480)
	for d2 in [[Vector2(160, 540), Vector2(26, 8)], [Vector2(212, 522), Vector2(26, 8)]]:
		_add_ground_prop("driftwood", d2[0], d2[1])
	_add_ground_prop("kaing_basket", Vector2(196, 500), Vector2(12, 6))
	_add_ground_prop("rope_coil", Vector2(130, 512), Vector2(12, 5))
	_add_ground_prop("water_drum", Vector2(222, 508), Vector2(14, 8))
	_add_ground_prop("mossy_rock", Vector2(228, 548), Vector2(20, 8))
	for p in [Vector2(132, 494), Vector2(170, 524), Vector2(190, 548), Vector2(146, 540)]:
		_add_ground_prop("starfish", p)
	for p in [Vector2(120, 520), Vector2(206, 536), Vector2(152, 500)]:
		_add_ground_prop("seashell", p)
	for p in [Vector2(238, 492), Vector2(240, 528), Vector2(236, 556), Vector2(118, 548)]:
		_add_ground_prop("beach_tuft", p)
	for p in [Vector2(176, 512), Vector2(224, 540)]:
		_add_ground_prop("pebbles", p)


func _build_backyard_props() -> void:
	# Quintais entre as cercas e as casas (alinhados sem sobrepor troncos de coqueiros nem cercas verticais)
	for p in [Vector2(360, 254), Vector2(486, 254), Vector2(968, 264), Vector2(1476, 260)]:
		_add_ground_prop("clothesline_low", p)
	for p in [Vector2(520, 270), Vector2(1354, 266)]:
		_add_ground_prop("vegetable_bed", p)
	for p in [Vector2(394, 244), Vector2(546, 246), Vector2(1002, 260), Vector2(1076, 264), Vector2(1414, 262)]:
		_add_ground_prop("water_drum", p)
	for p in [Vector2(262, 256), Vector2(1318, 256), Vector2(1596, 256)]:
		_add_ground_prop("firewood_pile", p)
	for p in [Vector2(560, 244), Vector2(868, 264), Vector2(1446, 264)]:
		_add_ground_prop("market_crates", p)
	for p in [Vector2(252, 224), Vector2(564, 222), Vector2(862, 242), Vector2(1070, 242), Vector2(1312, 242), Vector2(1616, 242), Vector2(400, 222), Vector2(986, 242)]:
		_add_ground_prop("fern_cluster", p)
	for p in [Vector2(338, 226), Vector2(486, 226), Vector2(944, 246), Vector2(1056, 246), Vector2(1386, 246), Vector2(1504, 246)]:
		_add_ground_prop("corner_shrub", p)
	for p in [Vector2(280, 224), Vector2(452, 224), Vector2(918, 244), Vector2(1022, 244), Vector2(1564, 244), Vector2(1332, 244)]:
		_add_ground_prop("mossy_rock", p)


func _build_sidewalk_props() -> void:
	# Calçada (y ~ 358..372): mantém portas, interativos, postes e rotas de NPC 100% desobstruídos
	for p in [Vector2(262, 362), Vector2(322, 362), Vector2(386, 362), Vector2(430, 362), Vector2(506, 360), Vector2(1010, 362), Vector2(1056, 362), Vector2(1534, 362), Vector2(1580, 362)]:
		_add_ground_prop("flower_pot", p, Vector2(8, 5))
	for p in [Vector2(484, 370), Vector2(936, 366), Vector2(1378, 366)]:
		_add_ground_prop("drink_crates", p, Vector2(18, 6))
	for p in [Vector2(986, 364), Vector2(1330, 364)]:
		_add_ground_prop("wood_bench", p, Vector2(28, 8))
	for p in [Vector2(762, 372), Vector2(824, 372), Vector2(742, 380)]:
		_add_ground_prop("traffic_cone", p, Vector2(8, 5))
	for p in [Vector2(772, 358), Vector2(814, 358)]:
		_add_ground_prop("bfp_bucket", p, Vector2(10, 5))
	for p in [Vector2(246, 372), Vector2(456, 368), Vector2(1106, 368), Vector2(1478, 368)]:
		_add_ground_prop("trash_bin", p, Vector2(10, 6))
	for p in [Vector2(1258, 364), Vector2(884, 362)]:
		_add_ground_prop("bicycle", p, Vector2(24, 6))
	for p in [Vector2(598, 364), Vector2(842, 364), Vector2(1218, 362)]:
		_add_ground_prop("notice_board", p, Vector2(14, 5))
	for p in [Vector2(364, 364), Vector2(1152, 366), Vector2(1506, 368)]:
		_add_ground_prop("flower_bed", p)


func _build_overhead_wires() -> void:
	_wires_drawer = OverheadWiresDrawer.new()
	_wires_drawer.name = "OverheadWiresLayer"
	_wires_drawer.z_index = 5
	_wires_drawer.pole_xs = [344.0, 472.0, 568.0, 856.0, 968.0, 1096.0, 1304.0, 1400.0, 1496.0, 1624.0]
	_wires_drawer.dead_xs = [472.0, 1272.0, 1496.0]
	_wires_drawer.drop_targets = [
		{"from": Vector2(344, 314), "to": Vector2(408, 304), "sag": 6.0},
		{"from": Vector2(568, 314), "to": Vector2(640, 260), "sag": 10.0},
		{"from": Vector2(856, 314), "to": Vector2(904, 304), "sag": 6.0},
		{"from": Vector2(1096, 314), "to": Vector2(1148, 250), "sag": 9.0},
		{"from": Vector2(1304, 314), "to": Vector2(1344, 304), "sag": 7.0},
		{"from": Vector2(1496, 314), "to": Vector2(1544, 304), "sag": 8.0}
	]
	add_child(_wires_drawer)


func _build_ambient_particles() -> void:
	var particles_holder := Node2D.new()
	particles_holder.name = "AmbientParticlesLayer"
	particles_holder.z_index = 5
	add_child(particles_holder)

	_street_dust_particles = CPUParticles2D.new()
	_street_dust_particles.name = "StreetDustParticles"
	_street_dust_particles.position = Vector2(900, 340)
	_street_dust_particles.amount = 85
	_street_dust_particles.lifetime = 5.2
	_street_dust_particles.preprocess = 2.0
	_street_dust_particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_street_dust_particles.emission_rect_extents = Vector2(880, 200)
	_street_dust_particles.direction = Vector2(1.0, 0.12)
	_street_dust_particles.spread = 28.0
	_street_dust_particles.gravity = Vector2(3.5, -2.5)
	_street_dust_particles.initial_velocity_min = 6.0
	_street_dust_particles.initial_velocity_max = 18.0
	_street_dust_particles.scale_amount_min = 1.5
	_street_dust_particles.scale_amount_max = 3.0
	_street_dust_particles.color = Color(0.84, 0.86, 0.90, 0.34)
	particles_holder.add_child(_street_dust_particles)

	_street_smoke_particles = CPUParticles2D.new()
	_street_smoke_particles.name = "StreetSmokeParticles"
	_street_smoke_particles.position = Vector2(1020, 390)
	_street_smoke_particles.amount = 42
	_street_smoke_particles.lifetime = 6.0
	_street_smoke_particles.preprocess = 2.5
	_street_smoke_particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_street_smoke_particles.emission_rect_extents = Vector2(800, 120)
	_street_smoke_particles.direction = Vector2(-0.6, -1.0)
	_street_smoke_particles.spread = 35.0
	_street_smoke_particles.gravity = Vector2(-2.0, -5.0)
	_street_smoke_particles.initial_velocity_min = 4.0
	_street_smoke_particles.initial_velocity_max = 12.0
	_street_smoke_particles.scale_amount_min = 3.0
	_street_smoke_particles.scale_amount_max = 6.0
	_street_smoke_particles.color = Color(0.55, 0.58, 0.65, 0.14)
	particles_holder.add_child(_street_smoke_particles)


func _add_dual_prop(kind: String, pos: Vector2, scl: Vector2, offset_y: float, wind_sway: bool = false, wind_strength: float = 1.5, wind_speed: float = 1.8) -> void:
	var n_spr := RetroLevelHelpers.create_prop_sprite(kind, false)
	n_spr.position = pos
	n_spr.scale = scl
	n_spr.offset = Vector2(0, offset_y * 0.25)
	var d_spr := RetroLevelHelpers.create_prop_sprite(kind, true)
	d_spr.position = pos
	d_spr.scale = scl
	d_spr.offset = Vector2(0, offset_y * 0.25)
	d_spr.visible = false
	if wind_sway:
		var phase := pos.x * 0.037 + pos.y * 0.013
		var anchor := 0.86 if kind == "clothesline_post" else 0.82
		RetroLevelHelpers.apply_wind_sway(n_spr, phase, wind_strength, wind_speed, 0.0, anchor)
		RetroLevelHelpers.apply_wind_sway(d_spr, phase, wind_strength * 1.15, wind_speed * 1.25, 0.65, anchor)
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
	# Contenção externa, barreiras marítimas e volumes sólidos completos dos edifícios/casas
	_add_box(collisions_body, Rect2(0, 0, 96, 416))                     # Mar norte do píer
	_add_box(collisions_body, Rect2(0, 464, 96, 96))                    # Mar sul do píer
	_add_box(collisions_body, Rect2(0, 416, 64, 48))                    # Cabeceira do píer
	_add_box(collisions_body, Rect2(592, 160, 240, 176))                # Complexo completo do Quartel BFP
	_add_box(collisions_body, Rect2(1104, 192, 176, 128))               # Corpo completo da Igreja de Agdangan
	# Garantia física adicional em todas as casas/lojas (além do V2TownPropsLayer)
	_add_box(collisions_body, Rect2(243, 280, 90, 68))                  # Casa Lola Rosa
	_add_box(collisions_body, Rect2(371, 280, 90, 68))                  # Casa Huwag
	_add_box(collisions_body, Rect2(482, 294, 76, 56))                  # Sari-Sari Store
	_add_box(collisions_body, Rect2(866, 294, 76, 56))                  # Karinderya
	_add_box(collisions_body, Rect2(979, 280, 90, 68))                  # Casa Central
	_add_box(collisions_body, Rect2(1314, 294, 76, 56))                 # Feira 1
	_add_box(collisions_body, Rect2(1410, 294, 76, 56))                 # Feira 2
	_add_box(collisions_body, Rect2(1507, 280, 90, 68))                 # Casa Leste
	_add_box(collisions_body, Rect2(240, 0, MAP_W_TILES * 16 - 240, 296)) # Fundos dos quintais urbanos (evita passar atrás de casas)
	_add_box(collisions_body, Rect2(0, 0, MAP_W_TILES * 16, 192))       # Limite superior norte atrás das cercas
	_add_box(collisions_body, Rect2(0, 528, MAP_W_TILES * 16, 36))      # Borda sul ao longo da avenida
	_add_box(collisions_body, Rect2(MAP_W_TILES * 16 - 8, 0, 24, 560))  # Trava extremo leste


func _add_box(parent: Node2D, r: Rect2) -> void:
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = r.size
	col.shape = shape
	col.position = r.position + r.size * 0.5
	parent.add_child(col)


func _spawn_town_npcs() -> void:
	# 1. Aling Nena na Sari-Sari
	_spawn_npc(
		"NPC_Aling_Nena", "Aling Nena",
		"res://assets/sprites/npcs/aling_nena/aling_nena_normal_spriteframes.tres",
		"res://assets/sprites/npcs/aling_nena/aling_nena_distorted_spriteframes.tres",
		Vector2(548, 384), "down", []
	)

	# 2. Bombeiro de Ronda diante do Quartel BFP
	_spawn_npc(
		"NPC_Bombeiro_Ronda", "Bombeiro de Ronda",
		"res://assets/sprites/npcs/bombeiro_santos/bombeiro_santos_normal_spriteframes.tres",
		"res://assets/sprites/npcs/bombeiro_santos/bombeiro_santos_distorted_spriteframes.tres",
		Vector2(606, 384), "right",
		[Vector2(606, 384), Vector2(654, 384)]
	)

	# 3. Kuya Ben ao lado do Triciclo / Karinderya
	_spawn_npc(
		"NPC_Kuya_Ben", "Kuya Ben",
		"res://assets/sprites/npcs/kuya_ben/kuya_ben_normal_spriteframes.tres",
		"res://assets/sprites/npcs/kuya_ben/kuya_ben_distorted_spriteframes.tres",
		Vector2(954, 422), "left", []
	)

	# 4. Toby perto da Igreja / Feira Leste
	_spawn_npc(
		"NPC_Toby", "Toby",
		"res://assets/sprites/npcs/toby/toby_normal_spriteframes.tres",
		"res://assets/sprites/npcs/toby/toby_distorted_spriteframes.tres",
		Vector2(1312, 386), "down",
		[Vector2(1292, 386), Vector2(1348, 386)]
	)

	# 5. Mang Tomas (Feirante do Barangay) na banca leste
	_spawn_npc(
		"NPC_Feirante", "Feirante do Barangay",
		"res://assets/sprites/npcs/mang_tomas/mang_tomas_normal_spriteframes.tres",
		"res://assets/sprites/npcs/mang_tomas/mang_tomas_distorted_spriteframes.tres",
		Vector2(1446, 384), "down", []
	)

	# 6. Aparição / Vigília da Senhora Luningning perto da saída para a floresta
	_spawn_npc(
		"NPC_Vigilia_Leste", "Senhora Luningning",
		"res://assets/sprites/npcs/senhora_luningning/senhora_luningning_normal_spriteframes.tres",
		"res://assets/sprites/npcs/senhora_luningning/senhora_luningning_distorted_spriteframes.tres",
		Vector2(1596, 386), "left", []
	)

	# 7. Mang Carding no píer oeste dos pescadores (costa)
	_spawn_npc(
		"NPC_Mang_Carding", "Mang Carding",
		"res://assets/sprites/npcs/mang_carding/mang_carding_normal_spriteframes.tres",
		"res://assets/sprites/npcs/mang_carding/mang_carding_distorted_spriteframes.tres",
		Vector2(188, 436), "left", []
	)

	# 8. Lola Rosa próxima à casa costeira oeste
	_spawn_npc(
		"NPC_Lola_Rosa", "Lola Rosa",
		"res://assets/sprites/npcs/lola_rosa/lola_rosa_normal_spriteframes.tres",
		"res://assets/sprites/npcs/lola_rosa/lola_rosa_distorted_spriteframes.tres",
		Vector2(350, 386), "right", []
	)


func _spawn_npc(id: String, prompt: String, norm_path: String, dist_path: String, pos: Vector2, dir: String, patrol: Array[Vector2]) -> void:
	if Engine.is_editor_hint():
		RetroLevelHelpers.add_npc_editor_preview(ysort_root, id, norm_path, pos, dir)
		return
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
	npc.npc_interacted.connect(func(nid: String) -> void: _on_interactable_triggered(nid))
	npc.entity_defeated.connect(_on_street_npc_defeated)
	ysort_root.add_child(npc)
	_npcs[id] = npc

	if GameState.has_method("is_corrupted_npc_defeated") and GameState.is_corrupted_npc_defeated(id):
		npc.is_defeated = true
		npc.refresh_visual_state()

	if id in ["NPC_Aling_Nena", "NPC_Mang_Carding", "NPC_Feirante"]:
		var badge := Label.new()
		badge.name = "MissionBadge"
		badge.text = "!"
		badge.position = Vector2(-5.0, -38.0)
		badge.z_index = 6
		badge.visible = false
		badge.add_theme_color_override("font_color", Color(1.0, 0.88, 0.34, 1.0))
		badge.add_theme_color_override("font_outline_color", Color(0.05, 0.05, 0.07, 1.0))
		badge.add_theme_constant_override("outline_size", 3)
		badge.add_theme_font_size_override("font_size", 11)
		npc.add_child(badge)
		_npc_mission_badges[id] = badge


func _on_street_npc_defeated(npc_id: String) -> void:
	if GameState.has_method("mark_corrupted_npc_defeated"):
		GameState.mark_corrupted_npc_defeated(npc_id)
	_sync_mission_markers()


func _setup_interactables() -> void:
	_add_interactable("Casa_Huwag", "Casa de Huwag", "Entrar", Vector2(408, 360), Vector2(32, 24))
	_add_interactable("Sari_Sari", "Sari-Sari Store", "Examinar", Vector2(520, 364), Vector2(40, 24))
	_add_interactable("Mural_Barangay", "Mural do Barangay", "Olhar", Vector2(574, 364), Vector2(30, 24))
	_add_interactable("Caminhao_Bombeiros", "Caminhão de Bombeiros", "Examinar", Vector2(680, 376), Vector2(48, 28))
	_add_interactable("Entrada_Quartel", "Quartel dos Bombeiros", "Entrar", Vector2(792, 344), Vector2(32, 24))
	_add_interactable("Karinderya_Triciclo", "Triciclo", "Examinar", Vector2(904, 436), Vector2(38, 24))
	_add_interactable("Igreja_Agdangan", "Igreja de Agdangan", "Observar", Vector2(1192, 330), Vector2(42, 28))
	_add_interactable("Cais_Praia", "Píer dos Pescadores", "Olhar", Vector2(160, 440), Vector2(38, 28))
	_add_interactable("Estrada_Floresta", "Estrada para a Floresta", "Seguir", Vector2(1748, 448), Vector2(40, 88))

	# Pontos objetivos das 3 missões simples do Ato 2 (visíveis apenas quando cada missão está aberta no Modo Normal)
	_add_mission_interactable("Missao_Suprimentos_Nena", "Suprimentos e Água (Aling Nena)", "Pegar", Vector2(624, 370), Vector2(34, 26))
	_add_mission_interactable("Missao_Cesto_Carding", "Cesto e Corda de Pesca", "Recolher", Vector2(182, 396), Vector2(36, 28))
	_add_mission_interactable("Missao_Aviso_Igreja", "Aviso BFP e Lanterna da Praça", "Fixar", Vector2(1218, 376), Vector2(36, 26))
	_sync_mission_markers()


func _add_mission_interactable(id: String, title_text: String, verb_text: String, pos: Vector2, box_size: Vector2) -> void:
	var inter := Interactable.new()
	inter.name = id
	inter.interaction_id = id
	inter.title = title_text
	inter.verb = verb_text
	inter.position = pos
	inter.visible = false
	inter.monitoring = false
	inter.monitorable = false

	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = box_size
	col.shape = shape
	inter.add_child(col)

	var beacon := Node2D.new()
	beacon.name = "Beacon"
	beacon.position = Vector2(0.0, -12.0)
	beacon.z_index = 6
	var diamond := Polygon2D.new()
	diamond.color = Color(1.0, 0.88, 0.34, 0.95)
	diamond.polygon = PackedVector2Array([
		Vector2(0, -6), Vector2(5, 0), Vector2(0, 6), Vector2(-5, 0)
	])
	beacon.add_child(diamond)
	inter.add_child(beacon)

	inter.interacted.connect(func(_i: Interactable) -> void: _on_interactable_triggered(id))
	interactables_root.add_child(inter)
	_mission_interactables[id] = inter


func _set_mission_node_active(id: String, active: bool) -> void:
	if not _mission_interactables.has(id):
		return
	var inter: Interactable = _mission_interactables[id]
	if inter == null or not is_instance_valid(inter):
		return
	inter.visible = active
	inter.set_deferred("monitoring", active)
	inter.set_deferred("monitorable", active)


func _sync_mission_markers() -> void:
	if Engine.is_editor_hint():
		return
	var ato: int = int(GameState.get_var("Ato", 1))
	var higher := _is_higher_dose_active()
	var act3 := GameState.is_unfiltered_act3()
	var chief_ready := GameState.get_switch("007_Chefe_Ato2_apresentado")
	var normal_act2 := (ato == 2 and not higher and not act3 and chief_ready)

	var nena_open := normal_act2 and GameState.get_switch("010_Missao_chave2_aberta") and not GameState.get_switch("011_Missao_chave2_concluida") and not GameState.has_item("suprimentos_nena")
	var carding_open := normal_act2 and GameState.get_switch("012_Missao_chave3_aberta") and not GameState.get_switch("013_Missao_chave3_concluida") and not GameState.has_item("cesto_carding")
	var feirante_open := normal_act2 and GameState.get_switch("008_Missao_chave1_aberta") and not GameState.get_switch("009_Missao_chave1_concluida") and not GameState.has_item("aviso_igreja_verificado")

	_set_mission_node_active("Missao_Suprimentos_Nena", nena_open)
	_set_mission_node_active("Missao_Cesto_Carding", carding_open)
	_set_mission_node_active("Missao_Aviso_Igreja", feirante_open)

	_update_npc_badge("NPC_Aling_Nena", normal_act2, "010_Missao_chave2_aberta", "011_Missao_chave2_concluida", "suprimentos_nena")
	_update_npc_badge("NPC_Mang_Carding", normal_act2, "012_Missao_chave3_aberta", "013_Missao_chave3_concluida", "cesto_carding")
	_update_npc_badge("NPC_Feirante", normal_act2, "008_Missao_chave1_aberta", "009_Missao_chave1_concluida", "aviso_igreja_verificado")


func _update_npc_badge(npc_id: String, normal_act2: bool, open_sw: String, done_sw: String, item_id: String) -> void:
	if not _npc_mission_badges.has(npc_id):
		return
	var badge: Label = _npc_mission_badges[npc_id]
	if badge == null or not is_instance_valid(badge):
		return
	if not normal_act2 or GameState.get_switch(done_sw):
		badge.visible = false
		return
	badge.visible = true
	if GameState.has_item(item_id):
		badge.text = "?"
		badge.add_theme_color_override("font_color", Color(0.45, 0.96, 0.58, 1.0))
	elif GameState.get_switch(open_sw):
		badge.text = "..."
		badge.add_theme_color_override("font_color", Color(0.86, 0.88, 0.94, 0.9))
	else:
		badge.text = "!"
		badge.add_theme_color_override("font_color", Color(1.0, 0.88, 0.34, 1.0))


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

	inter.interacted.connect(func(_i: Interactable) -> void: _on_interactable_triggered(id))
	interactables_root.add_child(inter)


func _apply_visual_atmosphere() -> void:
	var act3 := GameState.is_unfiltered_act3()
	var night := _is_night()
	var higher := _is_higher_dose_active()

	var active_base_ts: TileSet = TOWN_ACT3_TS if act3 else TOWN_NORMAL_TS
	ground_normal.tile_set = active_base_ts
	walls_normal.tile_set = active_base_ts
	if _town_props_layer != null:
		_town_props_layer.tile_set = TOWN_ACT3_TS if act3 else (TOWN_DISTORTED_TS if higher else TOWN_NORMAL_TS)
	ground_normal.visible = not higher
	walls_normal.visible = not higher
	ground_distorted.visible = higher
	walls_distorted.visible = higher

	for s in _normal_props:
		s.visible = not higher
		s.modulate = Color(0.78, 0.80, 0.84, 1.0) if act3 else Color.WHITE
	for s in _distorted_props:
		s.visible = higher
	for d in _distorted_decals:
		d.visible = higher

	for id in _npcs:
		var npc: NpcEntity = _npcs[id]
		if npc != null and is_instance_valid(npc):
			if not higher and npc.is_defeated and not GameState.is_corrupted_npc_defeated(id):
				npc.is_defeated = false
				npc.is_hostile = false
				npc._hp = npc.hostile_max_hp
				npc.visible = true
			npc.set_distorted_state(higher)
	_sync_mission_markers()

	var period: String = GameState.get_day_period() if GameState.has_method("get_day_period") else ("afternoon" if GameState.is_afternoon else "morning")
	if canvas_mod:
		if act3:
			canvas_mod.color = Color(0.60, 0.62, 0.66, 1.0)
		elif higher:
			canvas_mod.color = Color(0.56, 0.52, 0.58, 1.0)
		elif night or period == "night":
			canvas_mod.color = Color(0.42, 0.46, 0.60, 1.0)
		elif period == "afternoon" or GameState.is_afternoon:
			canvas_mod.color = Color(0.72, 0.66, 0.70, 1.0)
		else:
			canvas_mod.color = Color(0.84, 0.86, 0.90, 1.0)

	for lt in _lamp_lights:
		if lt == null:
			continue
		if higher:
			lt.color = Color(0.58, 0.54, 0.90)
			lt.energy = 0.88
		elif act3:
			lt.color = Color(0.82, 0.85, 0.88)
			lt.energy = 0.68
		else:
			lt.color = Color(0.98, 0.80, 0.46)
			lt.energy = 1.08 if (night or period == "night") else (0.55 if period == "afternoon" else 0.14)

	for fl in _flicker_lamps:
		if fl == null:
			continue
		if higher:
			fl.color = Color(0.56, 0.52, 0.88)
		elif act3:
			fl.color = Color(0.76, 0.78, 0.82)
		else:
			fl.color = Color(0.92, 0.74, 0.42)

	for wl_pt in _window_lights:
		if wl_pt == null:
			continue
		var base_col: Color = wl_pt.get_meta("base_color", Color(0.95, 0.78, 0.44))
		var base_e: float = float(wl_pt.get_meta("base_energy", 0.50))
		if higher:
			wl_pt.color = Color(0.56, 0.52, 0.86)
			wl_pt.energy = base_e * 0.85
		elif act3:
			wl_pt.color = Color(0.78, 0.80, 0.84)
			wl_pt.energy = base_e * 0.45
		else:
			wl_pt.color = base_col
			wl_pt.energy = base_e * (1.25 if (night or period == "night") else (0.65 if period == "afternoon" else 0.18))

	for spk in _spark_particles:
		if spk != null:
			spk.emitting = not act3
			spk.color = Color(0.66, 0.60, 0.96, 0.88) if higher else Color(1.0, 0.76, 0.30, 0.90)

	if _street_dust_particles != null:
		if higher:
			_street_dust_particles.color = Color(0.54, 0.50, 0.84, 0.40)
		elif act3:
			_street_dust_particles.color = Color(0.74, 0.76, 0.80, 0.22)
		else:
			_street_dust_particles.color = Color(0.84, 0.86, 0.90, 0.34)

	if _street_smoke_particles != null:
		if higher:
			_street_smoke_particles.color = Color(0.14, 0.12, 0.28, 0.24)
		elif act3:
			_street_smoke_particles.color = Color(0.68, 0.70, 0.74, 0.12)
		else:
			_street_smoke_particles.color = Color(0.55, 0.58, 0.65, 0.16 if night else 0.09)

	var swarm := get_node_or_null("CorruptedEyeSwarm") as CorruptedEyeSwarm
	if swarm != null:
		swarm.refresh_visibility()
	if _beacon_light != null:
		_beacon_light.color = Color(0.62, 0.56, 0.92) if higher else Color(0.94, 0.18, 0.22)

	if _wires_drawer != null:
		_wires_drawer.is_distorted = higher
		_wires_drawer.queue_redraw()

	if has_node("/root/AudioManager"):
		var am = get_node("/root/AudioManager")
		if am.has_method("sync_adaptive_soundtrack"):
			am.call("sync_adaptive_soundtrack", "street_preview", false)
		elif act3:
			am.play_ambience("act3_ambience")
		elif higher or night:
			am.play_ambience("night_ambience")
		elif GameState.is_afternoon:
			am.play_ambience("afternoon_ambience")
		else:
			am.play_ambience("morning_ambience")


func _on_dialogue_conflict_triggered(target_id: String, _context: Dictionary) -> void:
	if _npcs.has(target_id):
		var npc: NpcEntity = _npcs[target_id]
		if npc != null and is_instance_valid(npc):
			npc.turn_hostile()
			if has_node("/root/AudioManager"):
				get_node("/root/AudioManager").play_sfx("vhs_glitch")


func _on_interactable_triggered(id: String) -> void:
	var ato: int = int(GameState.get_var("Ato", 1))
	var act3 := GameState.is_unfiltered_act3()
	var higher := _is_higher_dose_active()

	match id:
		"Casa_Huwag":
			request_dialogue.emit([
				{
					"speaker": "Huwag Matitiis",
					"expression": "neutral",
					"text": "Minha casa em Agdangan. Entrar no quarto?",
					"choices": ["Entrar em casa", "Ficar na rua"]
				}
			], func(choice: int) -> void:
				if choice == 0:
					request_level_change.emit("res://scenes/levels/RoomHuwag.tscn", "from_street")
			)

		"Missao_Suprimentos_Nena":
			if not GameState.has_item("suprimentos_nena"):
				GameState.add_item("suprimentos_nena", 1)
				GameState.save_checkpoint()
				_sync_mission_markers()
				if has_node("/root/AudioManager"):
					get_node("/root/AudioManager").play_sfx("ui_select")
				request_dialogue.emit([{
					"speaker": "Huwag Matitiis",
					"expression": "neutral",
					"text": "Peguei o pacote de suprimentos e as garrafas d'água. Hora de entregar para Aling Nena na Sari-Sari Store."
				}], Callable())

		"Missao_Cesto_Carding":
			if not GameState.has_item("cesto_carding"):
				GameState.add_item("cesto_carding", 1)
				GameState.save_checkpoint()
				_sync_mission_markers()
				if has_node("/root/AudioManager"):
					get_node("/root/AudioManager").play_sfx("ui_select")
				request_dialogue.emit([{
					"speaker": "Huwag Matitiis",
					"expression": "neutral",
					"text": "Recolhi o cesto de pesca e a corda da areia. Vou devolver ao Mang Carding no píer."
				}], Callable())

		"Missao_Aviso_Igreja":
			if not GameState.has_item("aviso_igreja_verificado"):
				GameState.add_item("aviso_igreja_verificado", 1)
				GameState.save_checkpoint()
				_sync_mission_markers()
				if has_node("/root/AudioManager"):
					get_node("/root/AudioManager").play_sfx("ui_select")
				request_dialogue.emit([{
					"speaker": "Huwag Matitiis",
					"expression": "neutral",
					"text": "Aviso de segurança do BFP fixado no mural da igreja e a lanterna da praça está funcionando. Vou confirmar com o Feirante."
				}], Callable())

		"Sari_Sari", "NPC_Aling_Nena":
			if higher:
				request_dialogue.emit([
					{
						"speaker": "Aling Nena",
						"expression": "distorted",
						"text": "A grade da mercearia range no vazio.\n\"A luz acabou na rua toda antes do galpão cair... Foi você quem cortou a chave geral ou apenas fechou os olhos, Huwag?\"",
						"choices": [
							"Conversar: \"Eu desliguei para tentar evitar que o transformador explodisse...\"",
							"\"Cala essa boca! A energia já tinha caído antes de eu chegar!\""
						],
						"conflict_choices": {1: "NPC_Aling_Nena"}
					}
				], func(choice: int) -> void:
					if choice == 0:
						request_dialogue.emit([{
							"speaker": "Aling Nena",
							"expression": "distorted",
							"text": "\"Então por que ainda há cheiro de fio derretido nas suas mãos? Não peça para ajudar ninguém hoje, Huwag...\""
						}], Callable())
				)
			elif act3:
				request_dialogue.emit([
					{
						"speaker": "Aling Nena",
						"text": "Huwag... seus olhos estão tão cansados. Você não dormiu nada depois que a névoa baixou?"
					},
					{
						"speaker": "Aling Nena",
						"text": "A cidade inteira sabe que você fez o impossível naquele galpão. Não se mate aos poucos tomando aqueles comprimidos para esquecer."
					}
				], Callable())
			elif ato == 2 and GameState.get_switch("007_Chefe_Ato2_apresentado") and not GameState.get_switch("011_Missao_chave2_concluida"):
				if GameState.has_item("suprimentos_nena"):
					GameState.add_item("suprimentos_nena", -1)
					GameState.complete_optional_mission("011_Missao_chave2_concluida")
					_sync_mission_markers()
					request_dialogue.emit([{"speaker": "Aling Nena", "text": "Naku, salamat, Huwag! Os suprimentos e a água chegaram na hora certa! Muito obrigada pela ajuda."}], Callable())
				elif not GameState.get_switch("010_Missao_chave2_aberta"):
					GameState.set_switch("010_Missao_chave2_aberta", true)
					_sync_mission_markers()
					request_dialogue.emit([{
						"speaker": "Aling Nena",
						"text": "Que bom que o Capitão Reyes te mandou, Huwag! Meu pacote de suprimentos e garrafas d'água ficou parado ali perto do pátio do quartel. Pode buscar e trazer aqui para mim?"
					}], Callable())
				else:
					request_dialogue.emit([{
						"speaker": "Aling Nena",
						"text": "O pacote de suprimentos e água está logo ali à direita, na beira do pátio do Corpo de Bombeiros."
					}], Callable())
			elif ato == 2 and GameState.get_switch("011_Missao_chave2_concluida"):
				request_dialogue.emit([{
					"speaker": "Aling Nena",
					"text": "Salamat de novo pelos suprimentos, Huwag! Veja se Mang Carding no píer ou o Feirante perto da igreja ainda precisam de apoio."
				}], Callable())
			else:
				request_dialogue.emit([{
					"speaker": "Aling Nena",
					"text": "Bom dia, Huwag. A rua anda silenciosa hoje... Fique atento aos chamados do quartel."
				}], Callable())

		"Mural_Barangay":
			request_dialogue.emit([{
				"speaker": "Huwag Matitiis",
				"expression": "scared" if higher else ("unfiltered" if act3 else "neutral"),
				"text": "Todos os cartazes no mural repetem o mesmo aviso rasgado: 'PERMANEÇAM EM CASA SE OUVIREM A SIRENE DEPOIS DA MEIA-NOITE'." if higher else (
					"Folhetos cinzentos colados sobre fita velha: 'Memória aos Voluntários do BFP Agdangan'."
					if act3 else
					"Mural informativo do barangay: avisos de queimada na mata leste e escala de plantão dos bombeiros."
				)
			}], Callable())

		"Caminhao_Bombeiros":
			request_dialogue.emit([{
				"speaker": "Huwag Matitiis",
				"expression": "scared" if higher else ("unfiltered" if act3 else "determined"),
				"text": "O vidro do caminhão está escuro como fuligem... Por dentro do para-brisa parece haver capacetes vazios enfileirados." if higher else (
					"O caminhão do quartel BFP. Uma fita preta amarrada ao retrovisor balança devagar no ar frio."
					if act3 else
					"Viatura principal do quartel BFP de Agdangan. Mangueiras e bomba revisadas."
				)
			}], Callable())

		"Entrada_Quartel":
			request_dialogue.emit([
				{
					"speaker": "Huwag Matitiis",
					"expression": "neutral",
					"text": "Quartel do Bureau of Fire Protection (BFP) de Agdangan. Entrar?",
					"choices": ["Entrar no Quartel", "Continuar na rua"]
				}
			], func(choice: int) -> void:
				if choice == 0:
					request_level_change.emit("res://scenes/levels/FireStation.tscn", "from_city")
			)

		"NPC_Bombeiro_Ronda":
			if higher:
				request_dialogue.emit([
					{
						"speaker": "Bombeiro Santos",
						"expression": "distorted",
						"text": "\"Você ouviu a sirene tocando antes mesmo de alguém ligar o caminhão? Ou só veio contar se ainda restam três nomes na placa?\"",
						"choices": [
							"\"Os nomes nunca saíram daqui... eu lembro de cada um.\"",
							"\"Sai da minha frente! Você não é do nosso turno!\""
						],
						"conflict_choices": {1: "NPC_Bombeiro_Ronda"}
					}
				], Callable())
			elif act3:
				request_dialogue.emit([{
					"speaker": "Bombeiro Santos",
					"text": "O Capitão Reyes está lá dentro esperando por você, Huwag. Ele disse que desta vez não vai esconder mais nada."
				}], Callable())
			else:
				request_dialogue.emit([{
					"speaker": "Bombeiro Santos",
					"text": "Fazendo a ronda no pátio do quartel. Fale com o Capitão lá dentro se precisar das coordenadas do turno."
				}], Callable())

		"Karinderya_Triciclo", "NPC_Kuya_Ben":
			if higher:
				request_dialogue.emit([
					{
						"speaker": "Kuya Ben",
						"expression": "distorted",
						"text": "\"A buzina tocou três vezes no meio da fumaça... Por que o teu caminhão não abriu caminho até o fim da travessa, Huwag?\"",
						"choices": [
							"\"A pista desabou na nossa frente! Tentei achar outra passagem a pé...\"",
							"\"Para de mentir! Ninguém buzinou naquela noite!\""
						],
						"conflict_choices": {1: "NPC_Kuya_Ben"}
					}
				], Callable())
			elif act3:
				request_dialogue.emit([{
					"speaker": "Kuya Ben",
					"text": "Ei, Huwag... Eu vi você andando cedo sem o peso de antes. Vai ver o Capitão Reyes e fecha essa história na clareira em paz."
				}], Callable())
			elif ato == 2 and GameState.get_switch("007_Chefe_Ato2_apresentado"):
				request_dialogue.emit([{
					"speaker": "Kuya Ben",
					"text": "Motor pronto pro serviço, Huwag! Aling Nena, Mang Carding no píer e o Feirante perto da igreja estavam chamando pelo quartel hoje."
				}], Callable())
			else:
				request_dialogue.emit([{
					"speaker": "Kuya Ben",
					"text": "Motor pronto pro serviço. Se vir fumaça pro lado da feira leste, me avisa que eu tiro o pessoal da rua."
				}], Callable())

		"Igreja_Agdangan":
			request_dialogue.emit([{
				"speaker": "Huwag Matitiis",
				"expression": "scared" if higher else ("unfiltered" if act3 else "neutral"),
				"text": "O sino preto lá em cima parece imóvel, mas sinto a vibração metálica nos dentes." if higher else "A velha igreja de pedra de Agdangan. Os sinos tocam pouco desde o incêndio do ano passado."
			}], Callable())

		"NPC_Toby":
			if higher:
				request_dialogue.emit([{
					"speaker": "Toby",
					"expression": "distorted",
					"text": "\"Os adultos fecham a cortina quando o caminhão vermelho passa... e contam nos dedos quantos capacetes ficaram no galpão.\""
				}], Callable())
			elif ato == 2 and not GameState.get_switch("014_Floresta_liberada"):
				request_dialogue.emit([{
					"speaker": "Toby",
					"text": "Ei, tio Huwag! Vi uma senhora correndo pro quartel dizendo que o gato fugiu pra floresta lá no fim da rua! Fala com o Capitão primeiro!"
				}], Callable())
			else:
				request_dialogue.emit([{
					"speaker": "Toby",
					"text": "À noite dá pra ver clarões estranhos subindo além do último poste... Como se a mata lá fora tivesse brasas andando sozinhas."
				}], Callable())

		"NPC_Feirante":
			if higher:
				request_dialogue.emit([
					{
						"speaker": "Feirante do Barangay",
						"expression": "distorted",
						"text": "\"Os preços continuam pregados nas tábuas de carne, Huwag... mas só sobrou cinza fria onde ficava o açougue do turno da noite.\"",
						"choices": [
							"Conversar: \"A fumaça tomou a travessa inteira, eu tentei avisar...\"",
							"\"Chega de acusação! Não tenho culpa do que aconteceu aqui!\""
						],
						"conflict_choices": {1: "NPC_Feirante"}
					}
				], func(choice: int) -> void:
					if choice == 0:
						request_dialogue.emit([{
							"speaker": "Feirante do Barangay",
							"expression": "distorted",
							"text": "\"Ninguém aqui quer sua ajuda com as mãos tremendo desse jeito, bombeiro...\""
						}], Callable())
				)
			elif act3:
				request_dialogue.emit([{
					"speaker": "Feirante do Barangay",
					"text": "Finalmente baixou a fumaça da mata, Huwag. Todo mundo aqui viu você continuar firme mesmo quando faltou ar."
				}], Callable())
			elif ato == 2 and GameState.get_switch("007_Chefe_Ato2_apresentado") and not GameState.get_switch("009_Missao_chave1_concluida"):
				if GameState.has_item("aviso_igreja_verificado"):
					GameState.add_item("aviso_igreja_verificado", -1)
					GameState.complete_optional_mission("009_Missao_chave1_concluida")
					_sync_mission_markers()
					request_dialogue.emit([{"speaker": "Feirante do Barangay", "text": "Ótimo trabalho, bombeiro! Com o aviso do BFP fixado e a lanterna checada na praça da igreja, os moradores ficam mais tranquilos."}], Callable())
				elif not GameState.get_switch("008_Missao_chave1_aberta"):
					GameState.set_switch("008_Missao_chave1_aberta", true)
					_sync_mission_markers()
					request_dialogue.emit([{
						"speaker": "Feirante do Barangay",
						"text": "Bombeiro Huwag! Pode fixar este aviso de segurança do Corpo de Bombeiros no mural da praça da igreja logo ali à esquerda e checar a lanterna?"
					}], Callable())
				else:
					request_dialogue.emit([{
						"speaker": "Feirante do Barangay",
						"text": "O mural e a lanterna ficam bem na frente da Igreja de Agdangan, a poucos passos daqui para a esquerda."
					}], Callable())
			elif ato == 2 and GameState.get_switch("009_Missao_chave1_concluida"):
				request_dialogue.emit([{
					"speaker": "Feirante do Barangay",
					"text": "Obrigado por cuidar do aviso na praça da igreja, Huwag!"
				}], Callable())
			else:
				request_dialogue.emit([{
					"speaker": "Feirante do Barangay",
					"text": "Quase todas as bancas do mercado leste fecharam cedo hoje. Ninguém gosta de ficar perto da borda da mata depois do pôr do sol."
				}], Callable())

		"NPC_Vigilia_Leste":
			if higher:
				request_dialogue.emit([
					{
						"speaker": "Senhora Luningning",
						"expression": "distorted",
						"text": "Ela encara o asfalto rachado sob a luz vermelha do poste.\n\"Você engoliu mais comprimidos para calar a rua... mas eles ainda estão esperando lá dentro da mata.\"",
						"choices": [
							"\"Eu sei... vou até lá encarar o que ficou para trás.\"",
							"\"Saia do meu caminho! São só alucinações!\""
						],
						"conflict_choices": {1: "NPC_Vigilia_Leste"}
					}
				], Callable())
			elif act3:
				request_dialogue.emit([{
					"speaker": "Enfermeira Maria",
					"text": "Huwag... Sem os comprimidos você finalmente está andando na mesma rua que todo mundo. A trilha leste está calma hoje."
				}], Callable())
			elif ato == 2:
				request_dialogue.emit([{
					"speaker": "Enfermeira Maria",
					"text": "Passei pela saída leste mais cedo — há cheiro forte de fumaça vindo da mata. Confirme com o Capitão no quartel antes de entrar na trilha."
				}], Callable())
			else:
				request_dialogue.emit([{
					"speaker": "Enfermeira Maria",
					"text": "Termine sua ronda no quartel e confira seus remédios antes de seguir pela estrada da floresta, Huwag."
				}], Callable())

		"Cais_Praia":
			if higher:
				request_dialogue.emit([{
					"speaker": "Huwag Matitiis",
					"expression": "scared",
					"text": "A água bate contra os pilares com um som metálico e denso, como fumaça engolindo o cais."
				}], Callable())
			elif act3:
				request_dialogue.emit([{
					"speaker": "Mang Carding",
					"text": "A maré lava o cais, Huwag... mas o que ficou para trás na memória precisa de você de olhos abertos."
				}], Callable())
			else:
				request_dialogue.emit([{
					"speaker": "Huwag Matitiis",
					"text": "O pequeno cais de madeira sobre as águas escuras da costa. O mar bate devagar contra os pilares."
				}], Callable())

		"NPC_Mang_Carding":
			if higher:
				request_dialogue.emit([
					{
						"speaker": "Mang Carding",
						"expression": "distorted",
						"text": "A lanterna do píer balança num brilho avermelhado contra a água escura.\n\"O vento sul ainda traz cheiro de querosene até a maré, bombeiro... Quantos ficaram no escuro naquela noite?\"",
						"choices": [
							"Conversar: \"Nós voltamos duas vezes na fumaça... não abandonei ninguém.\"",
							"\"Cale a boca, velho! Volte para suas redes!\""
						],
						"conflict_choices": {1: "NPC_Mang_Carding"}
					}
				], func(choice: int) -> void:
					if choice == 0:
						request_dialogue.emit([{
							"speaker": "Mang Carding",
							"expression": "distorted",
							"text": "\"A maré devolve tudo o que a gente tenta esquecer, Huwag... não adianta fingir que veio me ajudar.\""
						}], Callable())
				)
			elif act3:
				request_dialogue.emit([{
					"speaker": "Mang Carding",
					"text": "A maré lava o cais, Huwag... mas o que ficou para trás na memória precisa de você de olhos abertos."
				}], Callable())
			elif ato == 2 and GameState.get_switch("007_Chefe_Ato2_apresentado") and not GameState.get_switch("013_Missao_chave3_concluida"):
				if GameState.has_item("cesto_carding"):
					GameState.add_item("cesto_carding", -1)
					GameState.complete_optional_mission("013_Missao_chave3_concluida")
					_sync_mission_markers()
					request_dialogue.emit([{"speaker": "Mang Carding", "text": "Salamat po, Huwag! Você resgatou meu cesto e a corda inteirinhos antes da maré subir!"}], Callable())
				elif not GameState.get_switch("012_Missao_chave3_aberta"):
					GameState.set_switch("012_Missao_chave3_aberta", true)
					_sync_mission_markers()
					request_dialogue.emit([{
						"speaker": "Mang Carding",
						"text": "Bombeiro Huwag! O vento derrubou meu cesto de pesca e o rolo de corda na faixa de areia logo ao lado do píer. Pode recolher e trazer para mim?"
					}], Callable())
				else:
					request_dialogue.emit([{
						"speaker": "Mang Carding",
						"text": "O cesto e a corda estão caídos na areia bem acima do píer, a poucos passos daqui."
					}], Callable())
			elif ato == 2 and GameState.get_switch("013_Missao_chave3_concluida"):
				request_dialogue.emit([{
					"speaker": "Mang Carding",
					"text": "Salamat po de novo, Huwag! Minhas redes e meu cesto estão seguros agora."
				}], Callable())
			else:
				request_dialogue.emit([{
					"speaker": "Mang Carding",
					"text": "A maré está baixa, Huwag. A neblina da mata chega até aqui no píer quando o vento vira."
				}], Callable())

		"NPC_Lola_Rosa":
			if higher:
				request_dialogue.emit([
					{
						"speaker": "Lola Rosa",
						"expression": "distorted",
						"text": "Ela aperta a cesta de lagundi como quem segura cinzas.\n\"Por que você tranca a janela tão forte à noite, anak? Tem medo do vento entrar ou do silêncio responder?\"",
						"choices": [
							"\"Só preciso de silêncio para descansar, Lola Rosa...\"",
							"\"Pare de vigiar minha porta! Fique longe!\""
						],
						"conflict_choices": {1: "NPC_Lola_Rosa"}
					}
				], Callable())
			elif act3:
				request_dialogue.emit([{
					"speaker": "Lola Rosa",
					"text": "Vá firme hoje sem abaixar a cabeça, anak. O quarteirão inteiro reza pelo seu retorno."
				}], Callable())
			else:
				request_dialogue.emit([{
					"speaker": "Lola Rosa",
					"text": "Susmaryosep, Huwag... Peguei folhas frescas de lagundi pra tosse da fumaça — não viva só desses frascos brancos, anak."
				}], Callable())

		"Estrada_Floresta":
			if ato == 1 and not GameState.get_switch("002_Chefe_Ato1_apresentado"):
				request_dialogue.emit([{
					"speaker": "Huwag Matitiis",
					"text": "Preciso me apresentar ao Capitão Reyes no Quartel BFP antes de entrar na trilha da floresta."
				}], Callable())
			elif ato == 2 and not GameState.get_switch("014_Floresta_liberada"):
				request_dialogue.emit([{
					"speaker": "Huwag Matitiis",
					"text": "A barreira para a floresta aguarda autorização da BFP. Apoie um morador na rua e fale com o Capitão Reyes e a senhora no quartel."
				}], Callable())
			else:
				var prompt_msg := (
					"A trilha está silenciosa e sem fumaça agora. Seguir até a clareira pela última vez?"
					if act3 else (
						"Fumaça espessa e brasas sobem da mata leste. Entrar na floresta em chamas?"
						if ato == 2 else
						"A estrada de terra mergulha na escuridão da floresta ao leste. Seguir em frente?"
					)
				)
				request_dialogue.emit([
					{
						"speaker": "Huwag Matitiis",
						"expression": "scared" if higher else "determined",
						"text": prompt_msg,
						"choices": ["Seguir para a Floresta", "Ficar em Agdangan"]
					}
				], func(choice: int) -> void:
					if choice == 0:
						request_level_change.emit("res://scenes/levels/forest_trail.tscn", "from_city")
				)
