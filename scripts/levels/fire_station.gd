extends Node2D

signal request_level_change(target_scene: String, spawn_tag: String)
signal request_dialogue(pages: Array, callback: Callable)

const RetroLevelHelpers := preload("res://scripts/levels/retro_level_helpers.gd")
const NPC_SCENE := preload("res://scenes/characters/NpcEntity.tscn")
const NORMAL_TS := preload("res://assets/tilesets/retro/interior_fnaf_normal_tileset.tres")
const DISTORTED_TS := preload("res://assets/tilesets/retro/interior_fnaf_distorted_tileset.tres")

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
	for layer in [floor_normal, walls_normal]:
		layer.tile_set = NORMAL_TS
	for layer in [floor_distorted, walls_distorted]:
		layer.tile_set = DISTORTED_TS

	# Complexo 60x40 tiles (960x640) emoldurado pelo vazio escuro estilo FNAF Minigame
	for fl in [floor_normal, floor_distorted]:
		RetroLevelHelpers.paint_rect(fl, 0, 0, 60, 40, Vector2i(0, 0))
		RetroLevelHelpers.paint_rect(fl, 4, 3, 52, 34, Vector2i(1, 0))

		# 1. Hall de Recepção e Espera (x: 19..40, y: 21..34) - Quadriculado arcade
		RetroLevelHelpers.paint_rect(fl, 19, 21, 22, 14, Vector2i(2, 0))
		for c_pos in [
			Vector2i(23, 25), Vector2i(33, 27), Vector2i(26, 30), Vector2i(35, 31)
		]:
			fl.set_cell(c_pos, 0, Vector2i(3, 0))
		# Faixa de entrada vermelha BFP sul e transição norte
		RetroLevelHelpers.paint_rect(fl, 28, 31, 4, 4, Vector2i(12, 0))
		RetroLevelHelpers.paint_rect(fl, 28, 19, 4, 3, Vector2i(11, 0))

		# 2. Central de Comando & Despacho (x: 19..40, y: 5..18)
		RetroLevelHelpers.paint_rect(fl, 19, 5, 22, 14, Vector2i(7, 0))
		RetroLevelHelpers.paint_rect(fl, 26, 12, 8, 5, Vector2i(2, 0))
		RetroLevelHelpers.paint_rect(fl, 27, 8, 6, 4, Vector2i(11, 0))

		# 3. Ala Oeste - Prontidão & Armários (x: 6..16, y: 7..32) + corredores x:17..18
		RetroLevelHelpers.paint_rect(fl, 6, 7, 11, 26, Vector2i(9, 0))
		for gy in range(13, 26, 3):
			fl.set_cell(Vector2i(11, gy), 0, Vector2i(8, 0)) # ralos de drenagem
		RetroLevelHelpers.paint_rect(fl, 17, 10, 2, 3, Vector2i(11, 0)) # corredor norte <-> comando
		RetroLevelHelpers.paint_rect(fl, 17, 25, 2, 3, Vector2i(11, 0)) # corredor sul <-> recepção

		# 4. Ala Leste - Enfermaria & Arquivo Médico (x: 43..53, y: 7..32) + corredores x:41..42
		RetroLevelHelpers.paint_rect(fl, 43, 7, 11, 26, Vector2i(10, 0))
		RetroLevelHelpers.paint_rect(fl, 41, 10, 2, 3, Vector2i(11, 0)) # corredor norte <-> comando
		RetroLevelHelpers.paint_rect(fl, 41, 25, 2, 3, Vector2i(11, 0)) # corredor sul <-> recepção

		if fl == floor_distorted:
			# Pistas visuais surreais no estado distorcido (olhos no corredor + manchas nos ralos)
			for eye_pos in [
				Vector2i(29, 20), Vector2i(17, 11), Vector2i(41, 11),
				Vector2i(17, 26), Vector2i(41, 26), Vector2i(29, 14)
			]:
				fl.set_cell(eye_pos, 0, Vector2i(14, 0))
			for stain_pos in [
				Vector2i(11, 16), Vector2i(11, 22), Vector2i(47, 19),
				Vector2i(48, 22), Vector2i(24, 29), Vector2i(30, 11)
			]:
				fl.set_cell(stain_pos, 0, Vector2i(13, 0))
			RetroLevelHelpers.paint_rect(fl, 8, 29, 2, 2, Vector2i(15, 0))
			RetroLevelHelpers.paint_rect(fl, 50, 28, 2, 2, Vector2i(15, 0))

	# Paredes internas e externas nas camadas normal e distorcida
	for wl in [walls_normal, walls_distorted]:
		# Parede Norte do Comando (y=4..5) com janelas e ventilação
		RetroLevelHelpers.paint_rect(wl, 18, 4, 24, 1, Vector2i(7, 1))
		RetroLevelHelpers.paint_rect(wl, 18, 5, 24, 1, Vector2i(8, 1))
		wl.set_cell(Vector2i(22, 4), 0, Vector2i(10, 1))
		wl.set_cell(Vector2i(23, 4), 0, Vector2i(10, 1))
		wl.set_cell(Vector2i(36, 4), 0, Vector2i(10, 1))
		wl.set_cell(Vector2i(37, 4), 0, Vector2i(10, 1))
		wl.set_cell(Vector2i(30, 4), 0, Vector2i(11, 1))
		# Consoles de despacho no comando (x=28..31, y=7)
		wl.set_cell(Vector2i(21, 6), 0, Vector2i(2, 2))
		wl.set_cell(Vector2i(22, 6), 0, Vector2i(2, 2))
		wl.set_cell(Vector2i(29, 6), 0, Vector2i(3, 2))
		wl.set_cell(Vector2i(30, 6), 0, Vector2i(3, 2))
		wl.set_cell(Vector2i(37, 6), 0, Vector2i(2, 2))
		wl.set_cell(Vector2i(38, 6), 0, Vector2i(2, 2))

		# Parede divisória Comando <-> Recepção (y=19..20, arco aberto em x=28..31)
		RetroLevelHelpers.paint_rect(wl, 19, 19, 9, 1, Vector2i(7, 1))
		RetroLevelHelpers.paint_rect(wl, 19, 20, 9, 1, Vector2i(8, 1))
		RetroLevelHelpers.paint_rect(wl, 32, 19, 9, 1, Vector2i(7, 1))
		RetroLevelHelpers.paint_rect(wl, 32, 20, 9, 1, Vector2i(8, 1))
		wl.set_cell(Vector2i(26, 19), 0, Vector2i(14, 1))
		wl.set_cell(Vector2i(33, 19), 0, Vector2i(14, 1))

		# Ala Oeste (x=5 parede oeste, y=5..6 norte, y=33 sul)
		RetroLevelHelpers.paint_rect(wl, 5, 5, 13, 1, Vector2i(3, 1))
		RetroLevelHelpers.paint_rect(wl, 5, 6, 13, 1, Vector2i(4, 1))
		wl.set_cell(Vector2i(11, 5), 0, Vector2i(11, 1))
		wl.set_cell(Vector2i(9, 7), 0, Vector2i(4, 2))   # Cilindros de combate
		wl.set_cell(Vector2i(10, 7), 0, Vector2i(4, 2))  # Cilindros de combate
		wl.set_cell(Vector2i(11, 7), 0, Vector2i(4, 2))
		RetroLevelHelpers.paint_rect(wl, 5, 5, 1, 29, Vector2i(1, 1))
		RetroLevelHelpers.paint_rect(wl, 6, 9, 1, 12, Vector2i(1, 2)) # Fileira de armários oeste
		RetroLevelHelpers.paint_rect(wl, 5, 33, 13, 1, Vector2i(2, 1))

		# Parede divisória Ala Oeste <-> Centro (x=17..18, corredores abertos y=10..12 e y=25..27)
		RetroLevelHelpers.paint_rect(wl, 17, 5, 2, 5, Vector2i(1, 1))
		RetroLevelHelpers.paint_rect(wl, 17, 13, 2, 12, Vector2i(1, 1))
		RetroLevelHelpers.paint_rect(wl, 17, 28, 2, 7, Vector2i(1, 1))

		# Ala Leste - Enfermaria (x=54 leste, y=5..6 norte, y=33 sul)
		RetroLevelHelpers.paint_rect(wl, 42, 5, 13, 1, Vector2i(9, 1))
		RetroLevelHelpers.paint_rect(wl, 42, 6, 13, 1, Vector2i(8, 1))
		wl.set_cell(Vector2i(47, 5), 0, Vector2i(10, 1))
		wl.set_cell(Vector2i(48, 5), 0, Vector2i(10, 1))
		wl.set_cell(Vector2i(44, 7), 0, Vector2i(2, 2)) # Arquivo médico norte
		wl.set_cell(Vector2i(45, 7), 0, Vector2i(2, 2))
		RetroLevelHelpers.paint_rect(wl, 54, 5, 1, 29, Vector2i(1, 1))
		RetroLevelHelpers.paint_rect(wl, 42, 33, 13, 1, Vector2i(2, 1))

		# Parede divisória Centro <-> Ala Leste (x=41..42, corredores y=10..12 e y=25..27)
		RetroLevelHelpers.paint_rect(wl, 41, 5, 2, 5, Vector2i(1, 1))
		RetroLevelHelpers.paint_rect(wl, 41, 13, 2, 12, Vector2i(1, 1))
		RetroLevelHelpers.paint_rect(wl, 41, 28, 2, 7, Vector2i(1, 1))

		# Parede Sul da Recepção (y=35, porta dupla em x=28..31)
		RetroLevelHelpers.paint_rect(wl, 18, 35, 10, 1, Vector2i(2, 1))
		RetroLevelHelpers.paint_rect(wl, 32, 35, 10, 1, Vector2i(2, 1))
		RetroLevelHelpers.paint_rect(wl, 28, 35, 4, 1, Vector2i(12, 1))
		RetroLevelHelpers.paint_rect(wl, 28, 36, 4, 1, Vector2i(2, 1))


func _build_station_props_and_lights() -> void:
	# Props por ala (normal vs distorcido)
	_add_dual_prop("bfp_desk", Vector2(480, 146), Vector2(2.2, 1.5), -8)          # Mesa Cap. Reyes
	_add_dual_prop("bfp_desk", Vector2(560, 426), Vector2(1.4, 1.3), -6)          # Balcão Recepção Leste
	_add_dual_prop("wooden_signpost", Vector2(368, 434), Vector2(2.1, 1.0), -4)   # Banco Sala de Espera
	_add_dual_prop("locker_uniform", Vector2(132, 150), Vector2(1.3, 1.3), -6)    # Armário Prontidão
	_add_dual_prop("locker_uniform", Vector2(158, 150), Vector2(1.3, 1.3), -6)
	_add_dual_prop("radio_clock", Vector2(168, 476), Vector2(1.2, 1.2), -4)       # Mesa / Rádio dos Bombeiros Oeste
	_add_dual_prop("pill_table", Vector2(772, 166), Vector2(1.5, 1.4), -6)        # Mesa Médica Enfermaria
	_add_dual_prop("medical_bed", Vector2(818, 250), Vector2(1.35, 1.35), -8)     # Maca Clínica 1
	_add_dual_prop("medical_bed", Vector2(818, 350), Vector2(1.35, 1.35), -8)     # Maca Clínica 2

	# Decais exclusivos no estado distorcido
	_add_distorted_decal("floor_stain", Vector2(480, 232), Vector2(1.8, 1.5))
	_add_distorted_decal("floor_stain", Vector2(180, 280), Vector2(1.6, 1.4))
	_add_distorted_decal("floor_stain", Vector2(760, 290), Vector2(1.7, 1.4))
	_add_distorted_decal("yume_eye_rune", Vector2(280, 340), Vector2(1.2, 1.2))
	_add_distorted_decal("yume_eye_rune", Vector2(680, 340), Vector2(1.2, 1.2))
	_add_distorted_decal("yume_eye_rune", Vector2(480, 310), Vector2(1.4, 1.4))

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
		"res://assets/characters/sprites/npc_cap_reyes_bfp_sheet.png",
		"res://assets/characters/sprites/distorted_bombeiro_sheet.png",
		Vector2(480, 196), "down", []
	)

	# 2. Bombeiro Ato (Ala Oeste - Armários & Prontidão)
	var ato_patrol: Array[Vector2] = [Vector2(174, 212), Vector2(236, 212)]
	_spawn_npc(
		"Bombeiro_Ato", "Bombeiro Ato",
		"res://assets/characters/sprites/npc_bombeiro_ato_sheet.png",
		"res://assets/characters/sprites/distorted_bombeiro_sheet.png",
		Vector2(174, 212), "down", ato_patrol
	)

	# 3. Bombeiro Santos (Ala Oeste Sul - Mesa de Descanso)
	_spawn_npc(
		"Bombeiro_Santos", "Bombeiro Santos",
		"res://assets/characters/sprites/npc_bombeiro_santos_sheet.png",
		"res://assets/characters/sprites/distorted_bombeiro_sheet.png",
		Vector2(214, 456), "left", []
	)

	# 4. Enfermeira Maria (Ala Leste - Enfermaria)
	_spawn_npc(
		"Enfermeira_Maria", "Enfermeira Maria",
		"res://assets/characters/sprites/npc_enfermeira_maria_sheet.png",
		"res://assets/characters/sprites/distorted_luningning_sheet.png",
		Vector2(752, 216), "left", []
	)

	# 5. Senhora Luningning / Espera (visível principalmente no Ato 2 na Recepção)
	_spawn_npc(
		"Velhinha_Espera", "Senhora Luningning",
		"res://assets/characters/sprites/distorted_luningning_sheet.png",
		"res://assets/characters/sprites/distorted_luningning_sheet.png",
		Vector2(368, 464), "up", []
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

	if canvas_mod:
		if act3:
			canvas_mod.color = Color(0.62, 0.64, 0.67, 1.0)
		elif higher:
			canvas_mod.color = Color(0.34, 0.24, 0.28, 1.0)
		else:
			canvas_mod.color = Color(0.56, 0.58, 0.66, 1.0)

	for lt in _lights:
		if lt == null:
			continue
		if higher:
			lt.color = Color(0.86, 0.16, 0.22)
		elif act3:
			lt.color = Color(0.86, 0.88, 0.90)


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
