extends Node2D

signal request_level_change(target_scene: String, spawn_tag: String)
signal request_dialogue(pages: Array, callback: Callable)

const RetroLevelHelpers := preload("res://scripts/levels/retro_level_helpers.gd")
const V2TileCatalog := preload("res://scripts/levels/v2_tile_catalog.gd")
const AtmosphereRig := preload("res://scripts/levels/atmosphere_rig.gd")
const NPC_SCENE := preload("res://scenes/characters/NpcEntity.tscn")
const TOWN_NORMAL_TS := preload("res://assets/tilesets/v2/agdangan_town_v2_normal_tileset.tres")
const TOWN_DISTORTED_TS := preload("res://assets/tilesets/v2/agdangan_town_v2_distorted_tileset.tres")
const TOWN_ACT3_TS := preload("res://assets/tilesets/v2/agdangan_town_v2_act3_tileset.tres")

# Rua estendida de Agdangan: 180 x 35 tiles de 16px (2880 x 560)
const MAP_BOUNDS := Rect2i(0, 0, 2880, 560)

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
var _blink_timer: float = 0.0


class OverheadWiresDrawer extends Node2D:
	var pole_xs: Array[float] = []
	var dead_xs: Array[float] = []
	var drop_targets: Array[Dictionary] = []
	var phase_time: float = 0.0
	var is_distorted: bool = false

	func _draw() -> void:
		var cable_main := Color(0.05, 0.06, 0.09, 0.90) if not is_distorted else Color(0.14, 0.04, 0.06, 0.94)
		var cable_sec := Color(0.09, 0.11, 0.15, 0.78) if not is_distorted else Color(0.24, 0.05, 0.08, 0.85)
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
	match GameState.spawn_tag:
		"from_room":
			player.position = Vector2(569, 395)
			player.facing_dir = Vector2.DOWN
		"from_station":
			player.position = Vector2(1185, 345)
			player.facing_dir = Vector2.DOWN
		"from_forest":
			player.position = Vector2(2808, 448)
			player.facing_dir = Vector2.LEFT
		_:
			player.position = Vector2(569, 395)
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


func _process(delta: float) -> void:
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


func apply_higher_dose_world(_active: bool) -> void:
	_apply_visual_atmosphere()


func _is_higher_dose_active() -> bool:
	return GameState.has_method("is_higher_dose") and GameState.is_higher_dose()


func _is_night() -> bool:
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
		layer.tile_set = TOWN_ACT3_TS if GameState.is_unfiltered_act3() else TOWN_NORMAL_TS
	for layer in [ground_distorted, walls_distorted]:
		layer.tile_set = TOWN_DISTORTED_TS

	for gl in [ground_normal, ground_distorted]:
		gl.clear()
		# Base contínua de gramado provincial filipino 16x16 em TODO o mapa 180x35 (zero buracos!)
		for gy in range(0, 35):
			for gx in range(0, 180):
				var gtile: Vector2i = t_cat["grass_b"] if ((gx * 7 + gy * 13) % 5 == 0) else t_cat["grass_a"]
				gl.set_cell(Vector2i(gx, gy), 0, gtile)

		# Vielas pavimentadas entre lotes e pátio da feira leste
		for alley_x in [28, 41, 50, 57, 77, 89, 104, 121, 132, 142, 155, 167]:
			V2TileCatalog.fill_rect(gl, Rect2i(alley_x, 18, 2, 5), t_cat["plaza_slab"])
		V2TileCatalog.fill_rect(gl, Rect2i(123, 15, 19, 3), t_cat["plaza_slab"])

		# Costa oeste de Agdangan: oceano animado, água rasa, praia de areia contínua e píer (x: 0..13)
		V2TileCatalog.fill_rect(gl, Rect2i(0, 0, 4, 35), t_cat["sea_water_anim"])
		V2TileCatalog.fill_rect(gl, Rect2i(4, 0, 2, 35), t_cat["shallow_water_anim"])
		for sy in range(0, 35):
			for sx in range(6, 14):
				var stile: Vector2i = t_cat["sand_b"] if ((sx + sy) % 4 == 0) else t_cat["sand_a"]
				gl.set_cell(Vector2i(sx, sy), 0, stile)
		# Píer de madeira contínuo (x: 4..13, y: 26..28)
		for py in range(26, 29):
			gl.set_cell(Vector2i(4, py), 0, t_cat["pier_plank_l"])
			for px in range(5, 13):
				gl.set_cell(Vector2i(px, py), 0, t_cat["pier_plank"])
			gl.set_cell(Vector2i(13, py), 0, t_cat["pier_plank_r"])
		for px in range(4, 14, 3):
			gl.set_cell(Vector2i(px, 29), 0, t_cat["pier_post"])

		# Calçada Norte contínua (y=23..24, x=16..172) + Pátio do Quartel BFP + Adro da Igreja
		V2TileCatalog.fill_rect(gl, Rect2i(16, 23, 156, 1), t_cat["curb_top"])
		V2TileCatalog.fill_rect(gl, Rect2i(16, 24, 156, 1), t_cat["curb_bottom"])
		V2TileCatalog.fill_rect(gl, Rect2i(59, 20, 19, 3), t_cat["plaza_slab"])
		V2TileCatalog.fill_rect(gl, Rect2i(108, 13, 11, 10), t_cat["plaza_slab"])

		# Avenida principal asfaltada contínua (x: 16..172, y: 25..31) + Calçada Sul (y=32)
		V2TileCatalog.fill_rect(gl, Rect2i(16, 25, 156, 7), t_cat["asphalt"])
		V2TileCatalog.fill_rect(gl, Rect2i(16, 32, 156, 1), t_cat["curb_top"])

		# Faixa central tracejada, rachaduras no asfalto e faixas de pedestres
		for rx in range(20, 170, 3):
			gl.set_cell(Vector2i(rx, 28), 0, t_cat["asphalt_dash_h"])
		for cw_x in [35, 73, 112, 146]:
			V2TileCatalog.fill_rect(gl, Rect2i(cw_x, 25, 2, 7), t_cat["crosswalk"])

		# Quadra Comunitária de Basquete do Barangay (x: 31..46, y: 8..15)
		V2TileCatalog.fill_rect(gl, Rect2i(31, 8, 16, 8), t_cat["plaza_slab"])
		V2TileCatalog.fill_rect(gl, Rect2i(31, 12, 16, 1), t_cat["plaza_line_h"])
		V2TileCatalog.fill_rect(gl, Rect2i(38, 8, 1, 8), t_cat["plaza_line_v"])
		V2TileCatalog.fill_rect(gl, Rect2i(34, 16, 4, 2), t_cat["plaza_slab"])

		# Estrada de terra leste entrando na floresta de Agdangan (x: 172..179, y: 25..31)
		V2TileCatalog.fill_rect(gl, Rect2i(172, 25, 8, 7), t_cat["dirt_a"])
		for dy in range(26, 31):
			gl.set_cell(Vector2i(175, dy), 0, t_cat["dirt_b"])

		# Poças de chuva tropical e rachaduras discretas ao longo da avenida
		for p_pos in [
			Vector2i(21, 29), Vector2i(29, 26), Vector2i(44, 26), Vector2i(53, 30),
			Vector2i(64, 29), Vector2i(80, 26), Vector2i(94, 26), Vector2i(104, 29),
			Vector2i(124, 30), Vector2i(130, 26), Vector2i(141, 27), Vector2i(150, 30),
			Vector2i(158, 29), Vector2i(165, 26)
		]:
			gl.set_cell(p_pos, 0, t_cat["asphalt_puddle"])

		for crk_pos in [
			Vector2i(24, 27), Vector2i(49, 29), Vector2i(68, 26), Vector2i(87, 30),
			Vector2i(101, 26), Vector2i(118, 26), Vector2i(136, 27), Vector2i(142, 29),
			Vector2i(152, 27), Vector2i(163, 30)
		]:
			gl.set_cell(crk_pos, 0, t_cat["asphalt_crack"])

	# Prédios de grande porte em tiles 1x1 (Quartel BFP e Igreja de Agdangan) sem sobreposição
	for wl in [walls_normal, walls_distorted]:
		wl.clear()
		var win_t: Vector2i = t_cat["wall_window_lit"] if (wl == walls_distorted or _is_night()) else t_cat["wall_window_dark"]

		# CENTRAL DE BOMBEIROS BFP AGDANGAN (x: 59..77, y: 8..19, porta em x=74)
		_paint_building(wl, 59, 8, 19, 12, t_cat["roof_yero_rust"], t_cat["wall_bfp_red"], true, 74)
		V2TileCatalog.fill_rect(wl, Rect2i(59, 13, 19, 1), t_cat["roof_yero_rust_eave"])
		V2TileCatalog.fill_rect(wl, Rect2i(67, 16, 4, 4), t_cat["wall_bfp_shutter"])
		for wx in [61, 63, 72, 76]:
			wl.set_cell(Vector2i(wx, 15), 0, win_t)
			wl.set_cell(Vector2i(wx, 17), 0, win_t)

		# Igreja de Agdangan ao norte (x: 108..118, y: 5..12, porta em x=113)
		_paint_building(wl, 108, 5, 11, 8, t_cat["roof_yero_grey"], t_cat["wall_concrete"], true, 113)
		V2TileCatalog.fill_rect(wl, Rect2i(108, 8, 11, 1), t_cat["roof_yero_grey_eave"])
		wl.set_cell(Vector2i(110, 10), 0, win_t)
		wl.set_cell(Vector2i(116, 10), 0, win_t)

		# Cercas de bambu alinhadas entre lotes
		V2TileCatalog.fill_rect(wl, Rect2i(22, 10, 1, 12), t_cat["fence_bamboo_v"])
		V2TileCatalog.fill_rect(wl, Rect2i(51, 21, 6, 1), t_cat["fence_bamboo_h"])
		V2TileCatalog.fill_rect(wl, Rect2i(86, 22, 5, 1), t_cat["fence_bamboo_h"])
		V2TileCatalog.fill_rect(wl, Rect2i(99, 22, 7, 1), t_cat["fence_bamboo_h"])

	# Camada dedicada para casas, Sari-Sari Store, veículos, postes e vegetação v2 (100% alinhados no grid, zero sobreposição)
	if _town_props_layer == null:
		_town_props_layer = TileMapLayer.new()
		_town_props_layer.name = "V2TownPropsLayer"
		_town_props_layer.z_index = 0
		_town_props_layer.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_town_props_layer.collision_enabled = false
		add_child(_town_props_layer)
	if ysort_root != null:
		ysort_root.z_index = 2
	_town_props_layer.tile_set = TOWN_ACT3_TS if GameState.is_unfiltered_act3() else (TOWN_DISTORTED_TS if _is_higher_dose_active() else TOWN_NORMAL_TS)
	_town_props_layer.clear()

	# Barco Banca no píer oeste + Casas costeiras
	V2TileCatalog.stamp_rect(_town_props_layer, Vector2i(5, 23), t_cat["banca_boat"], Vector2i(4, 2))
	V2TileCatalog.stamp_rect(_town_props_layer, Vector2i(7, 6), t_cat["house_concrete_rust"], Vector2i(6, 5))
	V2TileCatalog.stamp_rect(_town_props_layer, Vector2i(15, 11), t_cat["house_concrete_grey"], Vector2i(6, 5))
	V2TileCatalog.stamp_rect(_town_props_layer, Vector2i(15, 17), t_cat["house_concrete_rust"], Vector2i(6, 5))

	# Casa de Huwag (x: 33..38, y: 18..22 -> porta alinhada em x=35, y=22 / px=569)
	V2TileCatalog.stamp_rect(_town_props_layer, Vector2i(33, 18), t_cat["house_concrete_rust"], Vector2i(6, 5))

	# Sari-Sari Store de Aling Nena (x: 44..48, y: 19..22 -> centrada em px=750)
	V2TileCatalog.stamp_rect(_town_props_layer, Vector2i(44, 19), t_cat["sari_sari_store"], Vector2i(5, 4))

	# Viatura BFP estacionada no pátio do Quartel (x: 67..71, y: 20..22 -> px=1110)
	V2TileCatalog.stamp_rect(_town_props_layer, Vector2i(67, 20), t_cat["bfp_truck"], Vector2i(5, 3))
	_town_props_layer.set_cell(Vector2i(64, 22), 0, t_cat["fire_hydrant"])

	# Karinderya (x: 80..84, y: 19..22) + Triciclo de Kuya Ben (x: 82..84, y: 25..26 -> px=1330)
	V2TileCatalog.stamp_rect(_town_props_layer, Vector2i(80, 19), t_cat["sari_sari_store"], Vector2i(5, 4))
	V2TileCatalog.stamp_rect(_town_props_layer, Vector2i(82, 25), t_cat["tricycle"], Vector2i(3, 2))

	# Casa Residencial Central (x: 92..97, y: 18..22)
	V2TileCatalog.stamp_rect(_town_props_layer, Vector2i(92, 18), t_cat["house_concrete_grey"], Vector2i(6, 5))

	# Feira do Barangay & Casas do Beco Leste (x: 125..163, y: 18..22)
	V2TileCatalog.stamp_rect(_town_props_layer, Vector2i(125, 19), t_cat["sari_sari_store"], Vector2i(5, 4))
	V2TileCatalog.stamp_rect(_town_props_layer, Vector2i(134, 19), t_cat["sari_sari_store"], Vector2i(5, 4))
	V2TileCatalog.stamp_rect(_town_props_layer, Vector2i(146, 18), t_cat["house_concrete_grey"], Vector2i(6, 5))
	V2TileCatalog.stamp_rect(_town_props_layer, Vector2i(158, 18), t_cat["house_concrete_rust"], Vector2i(6, 5))

	# Bancos na quadra e no adro da Igreja
	V2TileCatalog.stamp_rect(_town_props_layer, Vector2i(32, 16), t_cat["plaza_bench"], Vector2i(2, 1))
	V2TileCatalog.stamp_rect(_town_props_layer, Vector2i(109, 16), t_cat["plaza_bench"], Vector2i(2, 1))
	V2TileCatalog.stamp_rect(_town_props_layer, Vector2i(116, 16), t_cat["plaza_bench"], Vector2i(2, 1))

	# Coqueiros (3x6), Bananeiras (2x3) e Árvores Costeiras (2x3) em posições livres de gramado
	for palm_pos in [
		Vector2i(8, 14), Vector2i(24, 15), Vector2i(52, 13), Vector2i(86, 14),
		Vector2i(102, 14), Vector2i(120, 14), Vector2i(141, 14), Vector2i(165, 14)
	]:
		var p_key := "coconut_left" if palm_pos.x % 2 == 0 else "coconut_right"
		V2TileCatalog.stamp_rect(_town_props_layer, palm_pos, t_cat[p_key], Vector2i(3, 6))

	for ban_pos in [
		Vector2i(24, 8), Vector2i(48, 9), Vector2i(86, 8), Vector2i(101, 8),
		Vector2i(121, 8), Vector2i(141, 8), Vector2i(154, 16), Vector2i(166, 20)
	]:
		V2TileCatalog.stamp_rect(_town_props_layer, ban_pos, t_cat["banana_plant"], Vector2i(2, 3))

	# Fileira norte e borda leste de árvores costeiras
	for tx in range(14, 174, 6):
		if (tx >= 30 and tx <= 47) or (tx >= 58 and tx <= 78) or (tx >= 107 and tx <= 119):
			continue
		var t_key := "coastal_tree_a" if tx % 12 == 0 else ("coastal_tree_b" if tx % 12 == 6 else "coastal_tree_c")
		V2TileCatalog.stamp_rect(_town_props_layer, Vector2i(tx, 1), t_cat[t_key], Vector2i(2, 3))

	for fy in [5, 9, 13, 17, 21]:
		for fx in [171, 174, 177]:
			V2TileCatalog.stamp_rect(_town_props_layer, Vector2i(fx, fy), t_cat["coastal_tree_c"], Vector2i(2, 3))

	# Postes de iluminação nos intervalos entre os prédios ao longo da calçada norte (zero sobreposição com fachadas)
	for lx_tile in [21, 30, 41, 56, 78, 90, 105, 121, 142, 156, 170]:
		V2TileCatalog.stamp_rect(_town_props_layer, Vector2i(lx_tile, 19), t_cat["lamppost_lit"], Vector2i(1, 5))
	for dx_tile in [50, 99, 132, 165]:
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
	# Decais distorcidos Yume Nikki / manchas pela rua (arquitetura, árvores e veículos agora vêm 100% de V2TownPropsLayer)
	for dx in [310.0, 569.0, 750.0, 960.0, 1110.0, 1340.0, 1590.0, 1810.0, 2140.0, 2380.0, 2480.0, 2720.0]:
		_add_distorted_decal("floor_stain", Vector2(dx, 444), Vector2(1.4, 1.1))
		_add_distorted_decal("yume_eye_rune", Vector2(dx - 30.0, 384), Vector2(1.1, 1.1))

	# Luzes PointLight2D nos postes acesos ao longo da via
	var lit_lamps_x := [340.0, 560.0, 750.0, 1140.0, 1360.0, 1810.0, 2140.0, 2540.0, 2810.0]
	for lx in lit_lamps_x:
		var pl := RetroLevelHelpers.create_point_light(Vector2(lx, 396), Color(0.98, 0.80, 0.46), 0.92, 2.6)
		lights_layer.add_child(pl)
		_lamp_lights.append(pl)

	# Postes danificados com reator piscante intermitente e faíscas esparsas
	var dead_lamps_x := [930.0, 1580.0, 1960.0, 2340.0, 2680.0]
	for i in range(dead_lamps_x.size()):
		var dead_x: float = dead_lamps_x[i]
		var fl := RetroLevelHelpers.create_point_light(Vector2(dead_x, 386), Color(0.85, 0.72, 0.48), 0.35, 2.0)
		fl.set_meta("phase", float(i) * 1.93 + 0.4)
		lights_layer.add_child(fl)
		_flicker_lamps.append(fl)

		if dead_x == 930.0 or dead_x == 2340.0:
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

	# Luzes de janelas e fachadas (atividade humana / abandono)
	var window_defs := [
		{"pos": Vector2(546, 338), "col": Color(0.95, 0.78, 0.44), "e": 0.46, "s": 1.15},
		{"pos": Vector2(604, 338), "col": Color(0.95, 0.78, 0.44), "e": 0.46, "s": 1.15},
		{"pos": Vector2(748, 356), "col": Color(0.82, 0.94, 0.68), "e": 0.56, "s": 1.45},
		{"pos": Vector2(1110, 272), "col": Color(0.85, 0.88, 0.96), "e": 0.55, "s": 1.65},
		{"pos": Vector2(1185, 308), "col": Color(0.96, 0.82, 0.52), "e": 0.60, "s": 1.40},
		{"pos": Vector2(1324, 338), "col": Color(0.96, 0.74, 0.42), "e": 0.52, "s": 1.40},
		{"pos": Vector2(1810, 182), "col": Color(0.92, 0.84, 0.62), "e": 0.58, "s": 1.90}
	]
	for wd in window_defs:
		var wl_pt := RetroLevelHelpers.create_point_light(wd["pos"], wd["col"], wd["e"], wd["s"])
		wl_pt.set_meta("base_color", wd["col"])
		wl_pt.set_meta("base_energy", wd["e"])
		lights_layer.add_child(wl_pt)
		_window_lights.append(wl_pt)

	# Giroflex vermelho sobre o quartel / caminhão BFP
	_beacon_light = RetroLevelHelpers.create_point_light(Vector2(1140, 316), Color(0.94, 0.18, 0.22), 0.72, 1.8)
	lights_layer.add_child(_beacon_light)


func _build_overhead_wires() -> void:
	_wires_drawer = OverheadWiresDrawer.new()
	_wires_drawer.name = "OverheadWiresLayer"
	_wires_drawer.z_index = 5
	_wires_drawer.pole_xs = [344.0, 488.0, 664.0, 808.0, 904.0, 1256.0, 1448.0, 1592.0, 1688.0, 1944.0, 2120.0, 2280.0, 2504.0, 2648.0, 2728.0]
	_wires_drawer.dead_xs = [808.0, 1592.0, 2120.0, 2648.0]
	_wires_drawer.drop_targets = [
		{"from": Vector2(488, 314), "to": Vector2(544, 304), "sag": 6.0},
		{"from": Vector2(664, 314), "to": Vector2(720, 318), "sag": 5.0},
		{"from": Vector2(904, 314), "to": Vector2(1020, 244), "sag": 12.0},
		{"from": Vector2(1256, 314), "to": Vector2(1300, 304), "sag": 8.0},
		{"from": Vector2(1448, 314), "to": Vector2(1504, 304), "sag": 9.0},
		{"from": Vector2(1944, 314), "to": Vector2(2020, 308), "sag": 10.0},
		{"from": Vector2(2280, 314), "to": Vector2(2360, 304), "sag": 10.0},
		{"from": Vector2(2504, 314), "to": Vector2(2560, 304), "sag": 10.0}
	]
	add_child(_wires_drawer)


func _build_ambient_particles() -> void:
	var particles_holder := Node2D.new()
	particles_holder.name = "AmbientParticlesLayer"
	particles_holder.z_index = 5
	add_child(particles_holder)

	_street_dust_particles = CPUParticles2D.new()
	_street_dust_particles.name = "StreetDustParticles"
	_street_dust_particles.position = Vector2(1440, 280)
	_street_dust_particles.amount = 110
	_street_dust_particles.lifetime = 5.2
	_street_dust_particles.preprocess = 2.0
	_street_dust_particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_street_dust_particles.emission_rect_extents = Vector2(1400, 260)
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
	_street_smoke_particles.position = Vector2(1600, 370)
	_street_smoke_particles.amount = 55
	_street_smoke_particles.lifetime = 6.0
	_street_smoke_particles.preprocess = 2.5
	_street_smoke_particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_street_smoke_particles.emission_rect_extents = Vector2(1300, 140)
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
	# Limites externos extras + veículos/postes alinhados ao mapa de 2880x560
	_add_box(collisions_body, Rect2(1070, 316, 86, 44))   # Caminhão BFP
	_add_box(collisions_body, Rect2(1296, 396, 78, 34))   # Jeepney / Triciclo
	_add_box(collisions_body, Rect2(1976, 490, 68, 28))   # Carcaça de carro abandonado oeste-leste
	_add_box(collisions_body, Rect2(2606, 490, 68, 28))   # Carcaça de carro abandonado leste
	_add_box(collisions_body, Rect2(1730, 80, 176, 128))  # Corpo da Igreja
	_add_box(collisions_body, Rect2(496, 272, 160, 96))   # Fachada Casa de Huwag
	_add_box(collisions_body, Rect2(2872, 0, 20, 560))    # Trava extremo leste


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
		Vector2(786, 396), "down", []
	)

	# 2. Bombeiro de Ronda diante do Quartel BFP
	_spawn_npc(
		"NPC_Bombeiro_Ronda", "Bombeiro de Ronda",
		"res://assets/sprites/npcs/bombeiro_santos/bombeiro_santos_normal_spriteframes.tres",
		"res://assets/sprites/npcs/bombeiro_santos/bombeiro_santos_distorted_spriteframes.tres",
		Vector2(1010, 378), "right",
		[Vector2(1010, 378), Vector2(1062, 378)]
	)

	# 3. Kuya Ben ao lado do Jeepney/Triciclo
	_spawn_npc(
		"NPC_Kuya_Ben", "Kuya Ben",
		"res://assets/sprites/npcs/kuya_ben/kuya_ben_normal_spriteframes.tres",
		"res://assets/sprites/npcs/kuya_ben/kuya_ben_distorted_spriteframes.tres",
		Vector2(1386, 424), "left", []
	)

	# 4. Toby na região leste da praça/feira abandonada
	_spawn_npc(
		"NPC_Toby", "Toby",
		"res://assets/sprites/npcs/toby/toby_normal_spriteframes.tres",
		"res://assets/sprites/npcs/toby/toby_distorted_spriteframes.tres",
		Vector2(2060, 394), "down",
		[Vector2(2040, 394), Vector2(2110, 394)]
	)

	# 5. Mang Tomas (Feirante do Barangay) na banca leste - ajuda e narrativa Ato 2->3
	_spawn_npc(
		"NPC_Feirante", "Feirante do Barangay",
		"res://assets/sprites/npcs/mang_tomas/mang_tomas_normal_spriteframes.tres",
		"res://assets/sprites/npcs/mang_tomas/mang_tomas_distorted_spriteframes.tres",
		Vector2(2260, 392), "down", []
	)

	# 6. Aparição / Vigília da Senhora Luningning no beco leste perto da saída da floresta
	_spawn_npc(
		"NPC_Vigilia_Leste", "Senhora Luningning",
		"res://assets/sprites/npcs/senhora_luningning/senhora_luningning_normal_spriteframes.tres",
		"res://assets/sprites/npcs/senhora_luningning/senhora_luningning_distorted_spriteframes.tres",
		Vector2(2560, 392), "left", []
	)

	# 7. Mang Carding no píer oeste dos pescadores (costa)
	_spawn_npc(
		"NPC_Mang_Carding", "Mang Carding",
		"res://assets/sprites/npcs/mang_carding/mang_carding_normal_spriteframes.tres",
		"res://assets/sprites/npcs/mang_carding/mang_carding_distorted_spriteframes.tres",
		Vector2(188, 436), "left", []
	)

	# 8. Lola Rosa (vizinha erborista no quarteirão oeste próximo à Casa de Huwag)
	_spawn_npc(
		"NPC_Lola_Rosa", "Lola Rosa",
		"res://assets/sprites/npcs/lola_rosa/lola_rosa_normal_spriteframes.tres",
		"res://assets/sprites/npcs/lola_rosa/lola_rosa_distorted_spriteframes.tres",
		Vector2(448, 392), "right", []
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
	npc.npc_interacted.connect(func(nid: String) -> void: _on_interactable_triggered(nid))
	ysort_root.add_child(npc)
	_npcs[id] = npc


func _setup_interactables() -> void:
	_add_interactable("Casa_Huwag", "Casa de Huwag", "Entrar", Vector2(569, 375), Vector2(30, 22))
	_add_interactable("Quadra_Basquete", "Quadra do Barangay", "Observar", Vector2(620, 260), Vector2(40, 24))
	_add_interactable("Sari_Sari", "Sari-Sari Store", "Examinar", Vector2(750, 395), Vector2(38, 24))
	_add_interactable("Mural_Barangay", "Mural do Barangay", "Olhar", Vector2(870, 395), Vector2(34, 24))
	_add_interactable("Caminhao_Bombeiros", "Caminhão de Bombeiros", "Examinar", Vector2(1110, 375), Vector2(46, 28))
	_add_interactable("Entrada_Quartel", "Quartel dos Bombeiros", "Entrar", Vector2(1185, 335), Vector2(30, 24))
	_add_interactable("Karinderya_Triciclo", "Triciclo", "Examinar", Vector2(1330, 440), Vector2(36, 24))
	_add_interactable("Igreja_Agdangan", "Igreja de Agdangan", "Observar", Vector2(1810, 210), Vector2(42, 28))
	_add_interactable("Cais_Praia", "Píer dos Pescadores", "Olhar", Vector2(160, 435), Vector2(38, 28))
	_add_interactable("Estrada_Floresta", "Estrada para a Floresta", "Seguir", Vector2(2848, 448), Vector2(40, 88))


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
	for s in _distorted_props:
		s.visible = higher
	for d in _distorted_decals:
		d.visible = higher

	for id in _npcs:
		var npc: NpcEntity = _npcs[id]
		if npc != null and is_instance_valid(npc):
			npc.set_distorted_state(higher)

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
			lt.color = Color(0.92, 0.46, 0.52)
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
			fl.color = Color(0.92, 0.42, 0.48)
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
			wl_pt.color = Color(0.90, 0.42, 0.50)
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
			spk.color = Color(0.96, 0.22, 0.26, 0.90) if higher else Color(1.0, 0.76, 0.30, 0.90)

	if _street_dust_particles != null:
		if higher:
			_street_dust_particles.color = Color(0.92, 0.28, 0.22, 0.48)
		elif act3:
			_street_dust_particles.color = Color(0.74, 0.76, 0.80, 0.22)
		else:
			_street_dust_particles.color = Color(0.84, 0.86, 0.90, 0.34)

	if _street_smoke_particles != null:
		if higher:
			_street_smoke_particles.color = Color(0.45, 0.08, 0.12, 0.24)
		elif act3:
			_street_smoke_particles.color = Color(0.68, 0.70, 0.74, 0.12)
		else:
			_street_smoke_particles.color = Color(0.55, 0.58, 0.65, 0.16 if night else 0.09)

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

		"Quadra_Basquete":
			request_dialogue.emit([{
				"speaker": "Huwag Matitiis",
				"expression": "scared" if higher else ("unfiltered" if act3 else "neutral"),
				"text": "O aro enferrujado balança sem vento... O concreto parece marcado por pegadas de borracha carbonizada." if higher else (
					"A quadra está vazia sob o céu cinzento. Aqui os colegas do pelotão jogavam nos fins de tarde."
					if act3 else
					"A quadra comunitária do barangay. As linhas brancas já descascaram sob o calor úmido."
				)
			}], Callable())

		"Sari_Sari", "NPC_Aling_Nena":
			if higher:
				request_dialogue.emit([
					{
						"speaker": "Aling Nena",
						"expression": "distorted",
						"text": "A grade da mercearia range no vazio.\n\"A luz acabou na rua toda antes do galpão cair... Foi você quem cortou a chave geral ou apenas fechou os olhos, Huwag?\"",
						"choices": [
							"\"Eu desliguei para tentar evitar que o transformador explodisse perto de vocês...\"",
							"\"Cala essa boca! A energia já tinha caído antes de eu chegar!\""
						],
						"conflict_choices": {1: "NPC_Aling_Nena"}
					}
				], Callable())
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
				request_dialogue.emit([
					{
						"speaker": "Aling Nena",
						"text": "Huwag! O fio do freezer está soltando faíscas contra a madeira seca da fachada! Pode desligar o disjuntor para mim?",
						"choices": ["Desligar e isolar a fiação", "Depois eu volto"]
					}
				], func(choice: int) -> void:
					if choice == 0:
						GameState.complete_optional_mission("011_Missao_chave2_concluida")
						request_dialogue.emit([{"speaker": "Aling Nena", "text": "Naku, salamat! Salvou minha loja! Passe no quartel falar com o Capitão Reyes!"}], Callable())
				)
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
			elif ato == 2 and GameState.get_switch("007_Chefe_Ato2_apresentado") and not GameState.get_switch("009_Missao_chave1_concluida"):
				request_dialogue.emit([
					{
						"speaker": "Kuya Ben",
						"text": "Huwag! O motor do Jeepney/triciclo superaqueceu e está gotejando óleo quente! Ajuda a resfriar e fechar o registro?",
						"choices": ["Resfriar motor e fechar válvula", "Volto já"]
					}
				], func(choice: int) -> void:
					if choice == 0:
						GameState.complete_optional_mission("009_Missao_chave1_concluida")
						request_dialogue.emit([{"speaker": "Kuya Ben", "text": "Valeu mesmo, irmão! Pode cobrar o suprimento lá com o Capitão Reyes!"}], Callable())
				)
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
						"text": "\"Os preços continuam pregados nas tábuas de carne, Huwag... mas só sobrou cinza fria onde ficava o açougue do turno da noite.\""
					}
				], Callable())
			elif act3:
				request_dialogue.emit([{
					"speaker": "Feirante do Barangay",
					"text": "Finalmente baixou a fumaça da mata, Huwag. Todo mundo aqui viu você continuar firme mesmo quando faltou ar."
				}], Callable())
			elif ato == 2 and GameState.get_switch("007_Chefe_Ato2_apresentado") and not GameState.get_switch("013_Missao_chave3_concluida"):
				request_dialogue.emit([
					{
						"speaker": "Feirante do Barangay",
						"text": "Bombeiro Huwag! O botijão da barraca leste está vazando perto das brasas do fogareiro! Pode fechar o registro e ventilar a área?",
						"choices": ["Fechar registro e ventilar barraca", "Depois eu volto"]
					}
				], func(choice: int) -> void:
					if choice == 0:
						GameState.complete_optional_mission("013_Missao_chave3_concluida")
						request_dialogue.emit([{"speaker": "Feirante do Barangay", "text": "Obrigado, bombeiro! O Capitão Reyes pediu para você retornar ao quartel assim que encerrar aqui!"}], Callable())
				)
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
			if act3:
				request_dialogue.emit([{
					"speaker": "Mang Carding",
					"text": "A maré lava o cais, Huwag... mas o que ficou para trás na memória precisa de você de olhos abertos."
				}], Callable())
			elif ato == 2 and GameState.get_switch("007_Chefe_Ato2_apresentado") and not GameState.get_switch("013_Missao_chave3_concluida"):
				request_dialogue.emit([
					{
						"speaker": "Mang Carding",
						"text": "Bombeiro! Uma lamparina caiu sobre as redes secas aqui no cais! Ajude a abafar antes que pegue no barco?",
						"choices": ["Usar água para apagar", "Depois"]
					}
				], func(choice: int) -> void:
					if choice == 0:
						GameState.complete_optional_mission("013_Missao_chave3_concluida")
						request_dialogue.emit([{"speaker": "Mang Carding", "text": "Salamat po! O fogo nas redes apagou a tempo!"}], Callable())
				)
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
						"text": "A lamparina balança num brilho avermelhado contra o casco do barco.\n\"O vento sul ainda traz cheiro de querosene até a maré, bombeiro... Quantos ficaram no escuro naquela noite?\"",
						"choices": [
							"\"Nós voltamos duas vezes na fumaça... não abandonei ninguém lá dentro.\"",
							"\"Cale a boca, velho! Volte para suas redes!\""
						],
						"conflict_choices": {1: "NPC_Mang_Carding"}
					}
				], Callable())
			elif act3:
				request_dialogue.emit([{
					"speaker": "Mang Carding",
					"text": "A maré lava o cais, Huwag... mas o que ficou para trás na memória precisa de você de olhos abertos."
				}], Callable())
			elif ato == 2 and GameState.get_switch("007_Chefe_Ato2_apresentado") and not GameState.get_switch("013_Missao_chave3_concluida"):
				request_dialogue.emit([
					{
						"speaker": "Mang Carding",
						"text": "Bombeiro! Uma lamparina caiu sobre as redes secas aqui no cais! Ajude a abafar antes que pegue no barco?",
						"choices": ["Usar água para apagar", "Depois"]
					}
				], func(choice: int) -> void:
					if choice == 0:
						GameState.complete_optional_mission("013_Missao_chave3_concluida")
						request_dialogue.emit([{"speaker": "Mang Carding", "text": "Salamat po! O fogo nas redes apagou a tempo!"}], Callable())
				)
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
