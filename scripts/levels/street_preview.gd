extends Node2D

signal request_level_change(target_scene: String, spawn_tag: String)
signal request_dialogue(pages: Array, callback: Callable)

const RetroLevelHelpers := preload("res://scripts/levels/retro_level_helpers.gd")
const NPC_SCENE := preload("res://scenes/characters/NpcEntity.tscn")
const TOWN_NORMAL_TS := preload("res://assets/tilesets/retro/town_fnaf_normal_tileset.tres")
const TOWN_DISTORTED_TS := preload("res://assets/tilesets/retro/town_fnaf_distorted_tileset.tres")

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
var _beacon_light: PointLight2D = null
var _blink_timer: float = 0.0


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
	_setup_collisions()
	_spawn_town_npcs()
	_setup_interactables()

	GameState.time_of_day_changed.connect(func(_v: bool) -> void: _apply_visual_atmosphere())
	GameState.perception_changed.connect(func(_m: int) -> void: _apply_visual_atmosphere())
	GameState.switch_changed.connect(func(_k: String, _v: bool) -> void: _apply_visual_atmosphere())
	if GameState.has_signal("higher_dose_changed"):
		GameState.higher_dose_changed.connect(func(active: bool) -> void: apply_higher_dose_world(active))

	_apply_visual_atmosphere()


func _process(delta: float) -> void:
	_blink_timer += delta
	if _beacon_light != null:
		var pulse := 0.55 + 0.40 * absf(sin(_blink_timer * 3.4))
		_beacon_light.energy = pulse


func apply_higher_dose_world(_active: bool) -> void:
	_apply_visual_atmosphere()


func _is_higher_dose_active() -> bool:
	return GameState.has_method("is_higher_dose") and GameState.is_higher_dose()


func _is_night() -> bool:
	if GameState.is_unfiltered_act3():
		return false
	var ato: int = int(GameState.get_var("Ato", 1))
	return (
		GameState.is_afternoon
		or GameState.perception_mode == GameState.PerceptionMode.FILTERED_AFTERNOON
		or (ato == 1 and GameState.get_switch("005_Chefe_liberou_cidade"))
		or (ato == 2 and GameState.get_switch("019_Ato2_concluido"))
	)


func _build_town_tilemaps() -> void:
	for layer in [ground_normal, walls_normal]:
		layer.tile_set = TOWN_NORMAL_TS
	for layer in [ground_distorted, walls_distorted]:
		layer.tile_set = TOWN_DISTORTED_TS

	for gl in [ground_normal, ground_distorted]:
		# Fundo base escuro + gramado Pokémon GB sombrio em toda a extensão 180x35
		RetroLevelHelpers.paint_rect(gl, 0, 0, 180, 35, Vector2i(10, 0))
		for gx in range(12, 178, 7):
			gl.set_cell(Vector2i(gx, 14), 0, Vector2i(11, 0))
			gl.set_cell(Vector2i(gx, 33), 0, Vector2i(11, 0))

		# Costa oeste: areia e espuma rasas (x: 0..15)
		RetroLevelHelpers.paint_rect(gl, 6, 4, 8, 29, Vector2i(12, 0))
		RetroLevelHelpers.paint_rect(gl, 4, 2, 2, 31, Vector2i(13, 0))
		# Píer de madeira oeste (x: 4..13, y: 26..28)
		RetroLevelHelpers.paint_rect(gl, 4, 26, 10, 3, Vector2i(14, 0))

		# Calçada Norte contínua (y=23..24, x=24..174) + Pátio do Quartel (x=59..77, y=20..24)
		RetroLevelHelpers.paint_rect(gl, 24, 23, 150, 1, Vector2i(5, 0))
		RetroLevelHelpers.paint_rect(gl, 24, 24, 150, 1, Vector2i(6, 0))
		RetroLevelHelpers.paint_rect(gl, 59, 20, 18, 4, Vector2i(5, 0)) # pátio BFP
		RetroLevelHelpers.paint_rect(gl, 108, 13, 12, 11, Vector2i(5, 0)) # adro da Igreja

		# Avenida principal asfaltada contínua (x: 16..172, y: 25..31)
		RetroLevelHelpers.paint_rect(gl, 16, 25, 156, 7, Vector2i(1, 0))
		# Calçada Sul estreita (y=32)
		RetroLevelHelpers.paint_rect(gl, 16, 32, 156, 1, Vector2i(5, 0))

		# Faixa amarela central tracejada e faixas de pedestres estilo GB/FNAF
		for rx in range(20, 170, 3):
			gl.set_cell(Vector2i(rx, 28), 0, Vector2i(2, 0))
		for cw_x in [36, 73, 112, 146]:
			RetroLevelHelpers.paint_rect(gl, cw_x, 25, 2, 7, Vector2i(3, 0))

		# Quadra Comunitária de Basquete (x: 31..46, y: 8..15)
		RetroLevelHelpers.paint_rect(gl, 31, 8, 16, 8, Vector2i(7, 0))
		RetroLevelHelpers.paint_rect(gl, 31, 12, 16, 1, Vector2i(8, 0))
		RetroLevelHelpers.paint_rect(gl, 34, 16, 4, 2, Vector2i(5, 0)) # acesso calçada/casa

		# Estrada de terra leste entrando na floresta (x: 171..179, y: 25..31)
		RetroLevelHelpers.paint_rect(gl, 171, 25, 9, 7, Vector2i(9, 0))

		# Poças de chuva e manchas pontuais de abandono ao longo da rua estendida
		for p_pos in [
			Vector2i(44, 26), Vector2i(64, 29), Vector2i(94, 26),
			Vector2i(124, 30), Vector2i(141, 27), Vector2i(158, 29), Vector2i(165, 26)
		]:
			gl.set_cell(p_pos, 0, Vector2i(4, 0))

		for ash_pos in [
			Vector2i(68, 22), Vector2i(118, 26), Vector2i(136, 24), Vector2i(152, 27)
		]:
			gl.set_cell(ash_pos, 0, Vector2i(15, 0))

		if gl == ground_distorted:
			# Pistas visuais de pesadelo na rua no Ato 2 dose maior
			for dist_pos in [
				Vector2i(35, 25), Vector2i(47, 25), Vector2i(74, 22), Vector2i(84, 28),
				Vector2i(114, 25), Vector2i(132, 26), Vector2i(145, 24), Vector2i(160, 28)
			]:
				gl.set_cell(dist_pos, 0, Vector2i(15, 0))

	# Paredes / Prédios nas camadas normal e distorcida
	for wl in [walls_normal, walls_distorted]:
		# Oceano Oeste impenetrável (x: 0..3)
		RetroLevelHelpers.paint_rect(wl, 0, 0, 4, 35, Vector2i(0, 1))
		# Borda Norte vegetal contínua (y: 0..3)
		RetroLevelHelpers.paint_rect(wl, 4, 0, 176, 4, Vector2i(14, 1))
		# Borda Sul da cidade (y=33..34, deixa píer livre)
		RetroLevelHelpers.paint_rect(wl, 14, 33, 166, 2, Vector2i(14, 1))

		# Cabanas da praia oeste (Bahay bamboo)
		_paint_building(wl, 5, 5, 5, 4, Vector2i(1, 1), Vector2i(4, 1), false, 0)
		_paint_building(wl, 13, 9, 5, 4, Vector2i(1, 1), Vector2i(4, 1), false, 0)
		_paint_building(wl, 18, 23, 5, 4, Vector2i(2, 1), Vector2i(4, 1), false, 0)
		# Cerca costeira com abertura na avenida (x=22)
		RetroLevelHelpers.paint_rect(wl, 22, 9, 1, 15, Vector2i(12, 1))

		# Casa de Huwag (x: 31..40, y: 17..22, porta em x=35)
		_paint_building(wl, 31, 17, 10, 6, Vector2i(2, 1), Vector2i(4, 1), true, 35)
		wl.set_cell(Vector2i(33, 21), 0, Vector2i(6, 1))
		wl.set_cell(Vector2i(38, 21), 0, Vector2i(6, 1))

		# Sari-Sari Store de Aling Nena (x: 43..50, y: 19..23, Toldo/Grade)
		_paint_building(wl, 43, 19, 7, 5, Vector2i(1, 1), Vector2i(10, 1), false, 0)
		# Mural do Barangay (x: 52..56, y: 20..23)
		_paint_building(wl, 52, 20, 5, 3, Vector2i(2, 1), Vector2i(5, 1), false, 0)

		# CENTRAL DE BOMBEIROS BFP AGDANGAN (x: 59..77, y: 8..19, porta em x=74)
		_paint_building(wl, 59, 8, 19, 12, Vector2i(3, 1), Vector2i(7, 1), true, 74)
		RetroLevelHelpers.paint_rect(wl, 67, 16, 4, 4, Vector2i(8, 1)) # Porta dupla da garagem
		for wx in [61, 63, 72, 76]:
			wl.set_cell(Vector2i(wx, 15), 0, Vector2i(6, 1))
			wl.set_cell(Vector2i(wx, 11), 0, Vector2i(6, 1))

		# Karinderya / Lanchonete (x: 79..88, y: 16..22)
		_paint_building(wl, 79, 16, 10, 7, Vector2i(1, 1), Vector2i(5, 1), false, 0)
		wl.set_cell(Vector2i(81, 21), 0, Vector2i(6, 1))
		wl.set_cell(Vector2i(86, 21), 0, Vector2i(6, 1))

		# Casas residenciais e muro intermediário (x: 91..103, y: 15..23)
		_paint_building(wl, 92, 15, 9, 7, Vector2i(2, 1), Vector2i(5, 1), false, 0)
		RetroLevelHelpers.paint_rect(wl, 91, 23, 5, 1, Vector2i(12, 1))
		RetroLevelHelpers.paint_rect(wl, 98, 23, 6, 1, Vector2i(12, 1))

		# Igreja de Agdangan ao norte (x: 108..118, y: 5..12)
		_paint_building(wl, 108, 5, 11, 8, Vector2i(2, 1), Vector2i(11, 1), true, 113)
		wl.set_cell(Vector2i(110, 11), 0, Vector2i(6, 1))
		wl.set_cell(Vector2i(116, 11), 0, Vector2i(6, 1))

		# BLOCO ESTENDIDO LESTE: Feira Abandonada & Beco das Residências (x: 123..169)
		_paint_building(wl, 124, 17, 7, 5, Vector2i(1, 1), Vector2i(10, 1), false, 0) # Barraca Feira 1
		_paint_building(wl, 134, 17, 7, 5, Vector2i(2, 1), Vector2i(10, 1), false, 0) # Barraca Feira 2
		_paint_building(wl, 145, 16, 10, 7, Vector2i(2, 1), Vector2i(5, 1), false, 0) # Sobrado fechado
		wl.set_cell(Vector2i(148, 21), 0, Vector2i(6, 1))
		wl.set_cell(Vector2i(151, 21), 0, Vector2i(6, 1))
		_paint_building(wl, 157, 17, 10, 6, Vector2i(3, 1), Vector2i(5, 1), false, 0) # Casa abandonada leste
		wl.set_cell(Vector2i(160, 21), 0, Vector2i(6, 1))
		wl.set_cell(Vector2i(163, 21), 0, Vector2i(6, 1))

		# Vegetação fechando norte/leste da saída para floresta
		RetroLevelHelpers.paint_rect(wl, 169, 4, 11, 19, Vector2i(14, 1))
		# Fechamento no extremo leste fora da trilha (y < 25 ou y > 31)
		RetroLevelHelpers.paint_rect(wl, 179, 4, 1, 21, Vector2i(14, 1))
		RetroLevelHelpers.paint_rect(wl, 179, 32, 1, 3, Vector2i(14, 1))

		if wl == walls_distorted:
			# Paredes com olhos Yume Nikki observando ao longo das fachadas fechadas
			for wy in [
				Vector2i(94, 21), Vector2i(97, 21), Vector2i(127, 20), Vector2i(137, 20),
				Vector2i(147, 20), Vector2i(159, 20), Vector2i(162, 20), Vector2i(54, 21)
			]:
				wl.set_cell(wy, 0, Vector2i(15, 1))


func _paint_building(wl: TileMapLayer, x0: int, y0: int, w: int, h: int, roof_tile: Vector2i, wall_tile: Vector2i, has_door: bool, door_x: int) -> void:
	var roof_h := maxi(2, h / 2)
	RetroLevelHelpers.paint_rect(wl, x0, y0, w, roof_h, roof_tile)
	RetroLevelHelpers.paint_rect(wl, x0, y0 + roof_h, w, h - roof_h, wall_tile)
	if has_door:
		wl.set_cell(Vector2i(door_x, y0 + h - 1), 0, Vector2i(9, 1))


func _build_town_props_and_lights() -> void:
	# Props fixos e duais Y-sorted (normal vs distorcido)
	_add_dual_prop("barangay_arch", Vector2(436, 146), Vector2(1.1, 1.1), -8)
	_add_dual_prop("basketball_hoop", Vector2(512, 175), Vector2(1.0, 1.0), -12)
	_add_dual_prop("basketball_hoop", Vector2(720, 175), Vector2(1.0, 1.0), -12)
	_add_dual_prop("bfp_firetruck", Vector2(1110, 336), Vector2(1.15, 1.15), -10)
	_add_dual_prop("jeepney_parked", Vector2(1335, 412), Vector2(1.15, 1.15), -10)
	_add_dual_prop("wooden_signpost", Vector2(2830, 396), Vector2(1.2, 1.2), -6)

	# Decais distorcidos Yume Nikki / manchas pela rua
	for dx in [569.0, 750.0, 1110.0, 1340.0, 1810.0, 2140.0, 2480.0, 2720.0]:
		_add_distorted_decal("floor_stain", Vector2(dx, 444), Vector2(1.4, 1.1))
		_add_distorted_decal("yume_eye_rune", Vector2(dx - 30.0, 384), Vector2(1.1, 1.1))

	# Postes ao longo da via (alternando áreas iluminadas e trechos escuros)
	var lit_lamps_x := [340.0, 560.0, 750.0, 1140.0, 1360.0, 1810.0, 2140.0, 2540.0, 2810.0]
	for lx in lit_lamps_x:
		var pole := RetroLevelHelpers.create_prop_sprite("streetlamp_pole", false)
		pole.position = Vector2(lx, 368)
		ysort_root.add_child(pole)

		var pl := RetroLevelHelpers.create_point_light(Vector2(lx, 396), Color(0.98, 0.80, 0.46), 0.92, 2.6)
		lights_layer.add_child(pl)
		_lamp_lights.append(pl)

	# Postes apagados propositais nos trechos de sombra e abandono
	for dead_x in [930.0, 1580.0, 1960.0, 2340.0, 2680.0]:
		var dead_pole := RetroLevelHelpers.create_prop_sprite("streetlamp_pole", true)
		dead_pole.position = Vector2(dead_x, 368)
		dead_pole.modulate = Color(0.55, 0.56, 0.62, 1.0)
		ysort_root.add_child(dead_pole)

	# Giroflex vermelho sobre o quartel / caminhão BFP
	_beacon_light = RetroLevelHelpers.create_point_light(Vector2(1140, 316), Color(0.94, 0.18, 0.22), 0.72, 1.8)
	lights_layer.add_child(_beacon_light)


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
	# Limites externos extras + veículos/postes alinhados ao mapa de 2880x560
	_add_box(collisions_body, Rect2(1070, 316, 86, 44))   # Caminhão BFP
	_add_box(collisions_body, Rect2(1296, 396, 78, 34))   # Jeepney / Triciclo
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
		"res://assets/characters/sprites/npc_aling_nena_sheet.png",
		"res://assets/characters/sprites/distorted_aling_nena_sheet.png",
		Vector2(786, 396), "down", []
	)

	# 2. Bombeiro de Ronda diante do Quartel BFP
	_spawn_npc(
		"NPC_Bombeiro_Ronda", "Bombeiro de Ronda",
		"res://assets/characters/sprites/npc_bombeiro_santos_sheet.png",
		"res://assets/characters/sprites/distorted_bombeiro_sheet.png",
		Vector2(1010, 378), "right",
		[Vector2(1010, 378), Vector2(1062, 378)]
	)

	# 3. Kuya Ben ao lado do Jeepney/Triciclo
	_spawn_npc(
		"NPC_Kuya_Ben", "Kuya Ben",
		"res://assets/characters/sprites/npc_kuya_ben_sheet.png",
		"res://assets/characters/sprites/distorted_kuya_ben_sheet.png",
		Vector2(1386, 424), "left", []
	)

	# 4. Toby na região leste da praça/feira abandonada
	_spawn_npc(
		"NPC_Toby", "Toby",
		"res://assets/characters/sprites/npc_toby_sheet.png",
		"res://assets/characters/sprites/distorted_kuya_ben_sheet.png",
		Vector2(2060, 394), "down",
		[Vector2(2040, 394), Vector2(2110, 394)]
	)

	# 5. Feirante do Barangay (banca leste - ajuda e narrativa Ato 2->3)
	_spawn_npc(
		"NPC_Feirante", "Feirante do Barangay",
		"res://assets/characters/sprites/npc_feirante_sheet.png",
		"res://assets/characters/sprites/distorted_bombeiro_sheet.png",
		Vector2(2260, 392), "down", []
	)

	# 6. Aparição / Vigília da Senhora Luningning no beco leste perto da saída da floresta
	_spawn_npc(
		"NPC_Vigilia_Leste", "Senhora Luningning",
		"res://assets/characters/sprites/npc_enfermeira_maria_sheet.png",
		"res://assets/characters/sprites/distorted_luningning_sheet.png",
		Vector2(2560, 392), "left", []
	)


func _spawn_npc(id: String, prompt: String, norm_path: String, dist_path: String, pos: Vector2, dir: String, patrol: Array[Vector2]) -> void:
	var npc := NPC_SCENE.instantiate() as NpcEntity
	npc.name = id
	npc.npc_id = id
	npc.interact_verb = "Conversar"
	npc.interact_prompt = prompt
	npc.normal_sheet_path = norm_path
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

	if canvas_mod:
		if act3:
			canvas_mod.color = Color(0.60, 0.62, 0.66, 1.0)
		elif higher:
			canvas_mod.color = Color(0.34, 0.24, 0.28, 1.0)
		elif night:
			canvas_mod.color = Color(0.36, 0.40, 0.56, 1.0)
		else:
			canvas_mod.color = Color(0.56, 0.59, 0.68, 1.0)

	for lt in _lamp_lights:
		if lt == null:
			continue
		if higher:
			lt.color = Color(0.84, 0.16, 0.22)
			lt.energy = 0.72
		elif act3:
			lt.color = Color(0.82, 0.85, 0.88)
			lt.energy = 0.68
		else:
			lt.color = Color(0.98, 0.80, 0.46)
			lt.energy = 0.90 if not night else 1.05

	if has_node("/root/AudioManager"):
		var am = get_node("/root/AudioManager")
		if act3:
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
			if act3:
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
