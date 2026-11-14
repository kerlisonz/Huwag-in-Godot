extends Node2D

signal request_level_change(target_scene: String, spawn_tag: String)
signal request_dialogue(pages: Array, callback: Callable)

const RetroLevelHelpers := preload("res://scripts/levels/retro_level_helpers.gd")
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
@onready var player: CharacterBody2D = $YSortEntities/Player
@onready var lights_layer: Node2D = $LightsLayer
@onready var light_shaft: Polygon2D = $LightShaftOverlay

var _fan_blades: Node2D = null
var _fan_angle: float = 0.0
var _flicker_time: float = 0.0
var _lamp_light: PointLight2D = null
var _window_light: PointLight2D = null
var _door_light: PointLight2D = null
var _radio_light: PointLight2D = null

var _normal_props: Array[Node2D] = []
var _distorted_props: Array[Node2D] = []
var _distorted_decals: Array[Node2D] = []


func _ready() -> void:
	if GameState.spawn_tag == "from_street":
		player.position = Vector2(540, 220)
		player.facing_dir = Vector2.LEFT
	elif GameState.spawn_tag == "from_nightmare":
		player.position = Vector2(250, 205)
		player.facing_dir = Vector2.DOWN
		GameState.advance_to_act_3()
		call_deferred("_trigger_act3_wake_monologue")
	else:
		player.position = Vector2(250, 205)
		player.facing_dir = Vector2.DOWN

	player.set_camera_limits(Rect2i(0, 0, 640, 360))

	_build_tilemaps()
	_build_room_props_and_lights()
	_setup_room_collisions()
	_setup_interactables()

	GameState.time_of_day_changed.connect(func(_v: bool) -> void: _apply_visual_atmosphere())
	GameState.perception_changed.connect(func(_m: int) -> void: _apply_visual_atmosphere())
	GameState.outfit_changed.connect(func(_o: String) -> void: _apply_visual_atmosphere())
	if GameState.has_signal("higher_dose_changed"):
		GameState.higher_dose_changed.connect(func(active: bool) -> void: apply_higher_dose_world(active))

	_apply_visual_atmosphere()

	if not GameState.get_self_switch("EV_Introducao", "A") and GameState.spawn_tag != "from_nightmare":
		GameState.set_self_switch("EV_Introducao", "A", true)
		call_deferred("_trigger_intro_monologue")
	elif int(GameState.get_var("Ato", 1)) == 2 and not GameState.get_switch("006c_Dose_escolhida_Ato2") and GameState.spawn_tag != "from_nightmare":
		call_deferred("_trigger_act2_pill_choice")


func _process(delta: float) -> void:
	_fan_angle = fmod(_fan_angle + delta * 11.0, TAU)
	if _fan_blades:
		_fan_blades.rotation = _fan_angle
	_flicker_time += delta
	if _lamp_light != null:
		var higher := _is_higher_dose_active()
		var base_e := 0.95 if not higher else 0.72
		var jitter := sin(_flicker_time * 9.0) * 0.05 + (sin(_flicker_time * 31.0) * 0.14 if higher else 0.0)
		_lamp_light.energy = maxf(0.2, base_e + jitter)


func apply_higher_dose_world(active: bool) -> void:
	_apply_visual_atmosphere()
	if active and has_node("/root/AudioManager"):
		get_node("/root/AudioManager").play_sfx("vhs_glitch")


func _is_higher_dose_active() -> bool:
	return GameState.has_method("is_higher_dose") and GameState.is_higher_dose()


func _is_night_room() -> bool:
	if GameState.is_unfiltered_act3():
		return false
	var ato: int = int(GameState.get_var("Ato", 1))
	return (
		GameState.is_afternoon
		or GameState.perception_mode == GameState.PerceptionMode.FILTERED_AFTERNOON
		or (ato == 1 and GameState.get_switch("005_Chefe_liberou_cidade"))
		or (ato == 2 and GameState.get_switch("019_Ato2_concluido"))
	)


func _build_tilemaps() -> void:
	for layer in [floor_normal, walls_normal]:
		layer.tile_set = NORMAL_TS
	for layer in [floor_distorted, walls_distorted]:
		layer.tile_set = DISTORTED_TS

	# Base void em torno do quarto (40x23) para sensação Yume Nikki / FNAF minigame
	for fl in [floor_normal, floor_distorted]:
		RetroLevelHelpers.paint_rect(fl, 0, 0, 40, 23, Vector2i(0, 0))
		RetroLevelHelpers.paint_rect(fl, 5, 6, 31, 15, Vector2i(1, 0))

		# Piso de tábuas de madeira desaturada no interior (x: 7..33, y: 10..19)
		RetroLevelHelpers.paint_rect(fl, 7, 10, 27, 10, Vector2i(4, 0))
		# Tábuas gastas espalhadas intencionalmente (não aleatório)
		for pos in [
			Vector2i(10, 17), Vector2i(11, 18), Vector2i(26, 12), Vector2i(28, 17),
			Vector2i(30, 15), Vector2i(25, 18), Vector2i(13, 18)
		]:
			fl.set_cell(pos, 0, Vector2i(5, 0))

		# Área de dormir oeste com esteira Banig filipina
		RetroLevelHelpers.paint_rect(fl, 7, 10, 7, 6, Vector2i(6, 0))

		# Tapete/Zona central quadriculada estilo FNAF Minigame (x: 15..24, y: 12..17)
		RetroLevelHelpers.paint_rect(fl, 15, 12, 10, 6, Vector2i(2, 0))
		for pos in [Vector2i(17, 14), Vector2i(21, 13), Vector2i(20, 16), Vector2i(16, 16)]:
			fl.set_cell(pos, 0, Vector2i(3, 0))

		# Rastros escuros de fuligem da porta em direção à mesa de remédios e cama
		for pos in [Vector2i(32, 14), Vector2i(30, 14), Vector2i(28, 13), Vector2i(26, 11), Vector2i(14, 15)]:
			fl.set_cell(pos, 0, Vector2i(13, 0))

		# Tapete de entrada na porta leste
		RetroLevelHelpers.paint_rect(fl, 32, 13, 2, 3, Vector2i(12, 0))

		# Pequenos detalhes surrealistas apenas no piso distorcido
		if fl == floor_distorted:
			for pos in [Vector2i(18, 14), Vector2i(22, 15), Vector2i(16, 13), Vector2i(26, 15)]:
				fl.set_cell(pos, 0, Vector2i(14, 0))
			for pos in [Vector2i(9, 18), Vector2i(10, 18), Vector2i(29, 11), Vector2i(30, 11)]:
				fl.set_cell(pos, 0, Vector2i(15, 0))
			fl.set_cell(Vector2i(23, 14), 0, Vector2i(13, 0))
			fl.set_cell(Vector2i(15, 11), 0, Vector2i(13, 0))

	# Paredes perimetrais nas camadas normal e distorcida
	for wl in [walls_normal, walls_distorted]:
		# Parede norte dupla (y=8 superior sawali/FNAF, y=9 rodapé)
		RetroLevelHelpers.paint_rect(wl, 7, 8, 27, 1, Vector2i(5, 1))
		RetroLevelHelpers.paint_rect(wl, 7, 9, 27, 1, Vector2i(6, 1))

		# Detalhes de parede FNAF: faixas verticais de metal, ventilação e janela
		wl.set_cell(Vector2i(12, 8), 0, Vector2i(3, 1))
		wl.set_cell(Vector2i(12, 9), 0, Vector2i(4, 1))
		wl.set_cell(Vector2i(15, 8), 0, Vector2i(15, 1)) # mancha/desgaste na parede
		wl.set_cell(Vector2i(17, 8), 0, Vector2i(11, 1)) # exaustor / ventilação
		wl.set_cell(Vector2i(20, 8), 0, Vector2i(10, 1)) # janela norte
		wl.set_cell(Vector2i(21, 8), 0, Vector2i(10, 1))
		wl.set_cell(Vector2i(26, 8), 0, Vector2i(3, 1))
		wl.set_cell(Vector2i(26, 9), 0, Vector2i(4, 1))
		wl.set_cell(Vector2i(30, 8), 0, Vector2i(14, 1)) # aviso / placa BFP na parede

		# Parede oeste (x=6, y=8..19) + contorno externo no vazio
		RetroLevelHelpers.paint_rect(wl, 6, 8, 1, 12, Vector2i(1, 1))
		# Borda sul do quarto (y=20)
		RetroLevelHelpers.paint_rect(wl, 6, 20, 29, 1, Vector2i(2, 1))
		# Parede leste superior e inferior
		RetroLevelHelpers.paint_rect(wl, 34, 8, 1, 4, Vector2i(1, 1))
		RetroLevelHelpers.paint_rect(wl, 34, 18, 1, 2, Vector2i(1, 1))
		# Soleira iluminada / aberta em x=34, y=12..17 + fechamento no vazio x=35
		RetroLevelHelpers.paint_rect(wl, 34, 12, 1, 6, Vector2i(12, 1))
		RetroLevelHelpers.paint_rect(wl, 35, 12, 1, 6, Vector2i(1, 1))

		if wl == walls_distorted:
			wl.set_cell(Vector2i(13, 8), 0, Vector2i(3, 1))
			wl.set_cell(Vector2i(24, 8), 0, Vector2i(15, 1))
			wl.set_cell(Vector2i(28, 8), 0, Vector2i(3, 1))


func _build_room_props_and_lights() -> void:
	# Cada objeto tem variante normal e variante distorcida Y-sorted
	_add_dual_prop("bed_huwag", Vector2(170, 195), Vector2(3.6, 2.15), -24)
	_add_dual_prop("locker_uniform", Vector2(258, 154), Vector2(1.4, 1.35), -8)
	_add_dual_prop("banig_mat", Vector2(318, 232), Vector2(2.2, 1.8), -80, true) # decal de tapete sob pés
	_add_dual_prop("pill_table", Vector2(424, 160), Vector2(1.5, 1.45), -6)
	_add_dual_prop("radio_clock", Vector2(476, 158), Vector2(1.25, 1.25), -6)
	_add_dual_prop("wooden_signpost", Vector2(376, 160), Vector2(1.0, 0.9), -6)
	_add_dual_prop("shoe_rack", Vector2(486, 296), Vector2(1.15, 1.15), -6)
	_add_dual_prop("pusa_cat", Vector2(509, 308), Vector2(1.25, 1.25), -4)

	# Decais exclusivos do estado distorcido (Yume Nikki + manchas de sangue/fuligem)
	_add_distorted_decal("floor_stain", Vector2(226, 224), Vector2(1.5, 1.3))
	_add_distorted_decal("floor_stain", Vector2(424, 182), Vector2(1.2, 1.1))
	_add_distorted_decal("yume_eye_rune", Vector2(180, 272), Vector2(1.1, 1.1))
	_add_distorted_decal("yume_eye_rune", Vector2(342, 134), Vector2(1.0, 1.0))
	_add_distorted_decal("yume_eye_rune", Vector2(492, 134), Vector2(1.0, 1.0))

	# Ventilador de parede (mantido para compatibilidade e movimento contínuo)
	var fan_root := Node2D.new()
	fan_root.name = "WallFan"
	fan_root.position = Vector2(280, 134)
	fan_root.z_index = 2
	ysort_root.add_child(fan_root)

	var cage := Polygon2D.new()
	cage.color = Color(0.14, 0.16, 0.20, 0.95)
	cage.polygon = PackedVector2Array([
		Vector2(-10, -10), Vector2(10, -10), Vector2(10, 10), Vector2(-10, 10)
	])
	fan_root.add_child(cage)

	_fan_blades = Node2D.new()
	_fan_blades.name = "FanBlades"
	for rot_idx in range(4):
		var blade := Polygon2D.new()
		blade.color = Color(0.45, 0.48, 0.54, 0.9)
		blade.rotation = rot_idx * PI * 0.5
		blade.polygon = PackedVector2Array([
			Vector2(-2, -1), Vector2(9, -3), Vector2(9, 2), Vector2(-2, 1)
		])
		_fan_blades.add_child(blade)
	fan_root.add_child(_fan_blades)

	# Luzes PointLight2D atmosféricas estilo FNAF
	_window_light = RetroLevelHelpers.create_point_light(Vector2(332, 195), Color(0.76, 0.85, 0.98), 0.72, 2.2)
	_lamp_light = RetroLevelHelpers.create_point_light(Vector2(436, 172), Color(1.0, 0.76, 0.42), 0.92, 1.8)
	_door_light = RetroLevelHelpers.create_point_light(Vector2(544, 224), Color(0.90, 0.76, 0.48), 0.58, 1.3)
	_radio_light = RetroLevelHelpers.create_point_light(Vector2(476, 158), Color(0.28, 0.92, 0.52), 0.45, 0.6)
	for lt in [_window_light, _lamp_light, _door_light, _radio_light]:
		lights_layer.add_child(lt)


func _add_dual_prop(kind: String, pos: Vector2, scl: Vector2, offset_y: float, is_floor_decal: bool = false) -> void:
	var n_spr := RetroLevelHelpers.create_prop_sprite(kind, false)
	n_spr.position = pos
	n_spr.scale = scl
	n_spr.offset = Vector2(0, offset_y * 0.25)
	var d_spr := RetroLevelHelpers.create_prop_sprite(kind, true)
	d_spr.position = pos
	d_spr.scale = scl
	d_spr.offset = Vector2(0, offset_y * 0.25)
	d_spr.visible = false
	if is_floor_decal:
		n_spr.z_index = 1
		d_spr.z_index = 1
		decals_layer.add_child(n_spr)
		decals_layer.add_child(d_spr)
	else:
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


func _apply_visual_atmosphere() -> void:
	var act3 := GameState.is_unfiltered_act3()
	var night := _is_night_room()
	var higher := _is_higher_dose_active()

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

	if canvas_mod:
		if act3:
			canvas_mod.color = Color(0.60, 0.62, 0.65, 1.0)
		elif higher:
			canvas_mod.color = Color(0.28, 0.21, 0.25, 1.0)
		elif night:
			canvas_mod.color = Color(0.36, 0.40, 0.56, 1.0)
		else:
			canvas_mod.color = Color(0.54, 0.56, 0.64, 1.0)

	if _lamp_light:
		_lamp_light.color = Color(0.86, 0.16, 0.20) if higher else (Color(0.84, 0.84, 0.86) if act3 else Color(1.0, 0.76, 0.42))
	if _window_light:
		_window_light.energy = 0.18 if higher else (0.58 if night else 0.76)
		_window_light.color = Color(0.65, 0.20, 0.28) if higher else (Color(0.82, 0.84, 0.88) if act3 else Color(0.74, 0.84, 0.96))
	if _radio_light:
		_radio_light.color = Color(0.95, 0.18, 0.22) if higher else Color(0.28, 0.92, 0.52)
	if light_shaft:
		light_shaft.visible = not higher
		light_shaft.color = Color(0.75, 0.78, 0.82, 0.05) if act3 else (Color(0.45, 0.56, 0.78, 0.06) if night else Color(0.78, 0.84, 0.94, 0.09))

	if has_node("/root/AudioManager"):
		var am = get_node("/root/AudioManager")
		if act3:
			am.play_ambience("act3_ambience")
		elif higher:
			am.play_ambience("night_ambience")
		elif night:
			am.play_ambience("night_ambience")
		elif GameState.is_afternoon:
			am.play_ambience("afternoon_ambience")
		else:
			am.play_ambience("morning_ambience")


func _setup_room_collisions() -> void:
	var body := StaticBody2D.new()
	body.name = "RoomWalls"
	body.collision_layer = 1
	add_child(body)

	# Paredes exatas alinhadas com o TileMapLayer (e compatíveis com testes)
	_add_box_collision(body, Rect2(0, 0, 640, 156))       # Norte (até y=156)
	_add_box_collision(body, Rect2(0, 324, 640, 36))      # Sul (abaixo de y=324)
	_add_box_collision(body, Rect2(0, 0, 102, 360))       # Oeste (até x=102)
	_add_box_collision(body, Rect2(544, 0, 96, 190))      # Leste acima da porta
	_add_box_collision(body, Rect2(552, 260, 88, 100))    # Leste abaixo da porta
	_add_box_collision(body, Rect2(554, 190, 86, 98))     # Trava externa do vão da porta (y=190..288)

	# Cama sólida alinhada ao sprite da cama (x=104..228, y=156..244)
	_add_box_collision(body, Rect2(104, 156, 124, 88))

	# Colisão circular do gato dormindo no canto sudeste
	var cat_shape := CollisionShape2D.new()
	var cat_circle := CircleShape2D.new()
	cat_circle.radius = 12.0
	cat_shape.shape = cat_circle
	cat_shape.position = Vector2(509, 308)
	body.add_child(cat_shape)


func _add_box_collision(parent: Node2D, r: Rect2) -> void:
	var shape_node := CollisionShape2D.new()
	var rect_shape := RectangleShape2D.new()
	rect_shape.size = r.size
	shape_node.shape = rect_shape
	shape_node.position = r.position + r.size * 0.5
	parent.add_child(shape_node)


func _setup_interactables() -> void:
	_add_interactable("Cama", "Cama de Bambu", "Descansar", Vector2(236, 205), Vector2(28, 42))
	_add_interactable("Mesa_Remedios", "Mesa de Remédios", "Examinar", Vector2(424, 190), Vector2(36, 28))
	_add_interactable("Armario_Uniforme", "Armário do Uniforme", "Abrir", Vector2(258, 168), Vector2(36, 22))
	_add_interactable("Janela_Norte", "Janela Grades", "Olhar", Vector2(332, 164), Vector2(44, 22))
	_add_interactable("Radio_Quartel", "Rádio Comunicador BFP", "Checar", Vector2(476, 190), Vector2(28, 30))
	_add_interactable("Geladeira", "Jarra e Provisões", "Examinar", Vector2(376, 190), Vector2(28, 28))
	_add_interactable("Porta_Saida", "Porta para Agdangan", "Sair", Vector2(546, 225), Vector2(26, 36))
	_add_interactable("Gato", "Pusa", "Acariciar", Vector2(509, 304), Vector2(28, 24))


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


func _trigger_intro_monologue() -> void:
	var pages: Array[Dictionary] = [
		{
			"speaker": "Huwag Matitiis",
			"expression": "tired",
			"is_monologue": true,
			"text": "Este quarto às vezes parece grande demais para um corpo só... e pequeno demais para o que tento esquecer."
		},
		{
			"speaker": "Huwag Matitiis",
			"expression": "uneasy_smile",
			"is_monologue": true,
			"text": "Os comprimidos da manhã já amorteceram os ruídos lá fora. Hora de vestir o uniforme e seguir para o quartel de Agdangan."
		}
	]
	request_dialogue.emit(pages, Callable())


func _trigger_act3_wake_monologue() -> void:
	var wake_act3: Array[Dictionary] = [
		{
			"speaker": "Huwag Matitiis",
			"expression": "unfiltered",
			"is_monologue": true,
			"text": "Acordei sem fôlego... As fitas na cabeça pararam de rodar e o quarto voltou a ter apenas o cheiro de madeira úmida e cinza antiga."
		},
		{
			"speaker": "Huwag Matitiis",
			"expression": "unfiltered",
			"is_monologue": true,
			"text": "Os frascos na mesa estão vazios. Não existe mais filtro entre mim e Agdangan. Preciso sair."
		}
	]
	request_dialogue.emit(wake_act3, Callable())


func _trigger_act2_pill_choice() -> void:
	var pages: Array[Dictionary] = [
		{
			"speaker": "Huwag Matitiis",
			"expression": "worried",
			"text": "Amanheceu no Ato 2, mas minha cabeça ainda gira com o silêncio da noite.\nSobre a mesa, os comprimidos aguardam."
		},
		{
			"speaker": "Huwag Matitiis",
			"expression": "scared",
			"text": "Tomar a dose normal para suportar o turno... ou engolir uma dose maior para silenciar de vez o que se mexe atrás das paredes?",
			"choices": [
				"Tomar a dose habitual (3 comprimidos)",
				"Tomar uma dose maior de pílulas"
			]
		}
	]
	request_dialogue.emit(pages, func(choice: int) -> void:
		var use_higher := (choice == 1)
		if GameState.has_method("set_higher_dose"):
			GameState.set_higher_dose(use_higher)
		apply_higher_dose_world(use_higher)
		if use_higher:
			request_dialogue.emit([{
				"speaker": "Huwag Matitiis",
				"expression": "scared",
				"is_monologue": true,
				"text": "Engoli o dobro da dose... O ar esfriou. Os ladrilhos parecem afundar e alguém está me encarando de dentro das frestas da janela."
			}], Callable())
		else:
			request_dialogue.emit([{
				"speaker": "Huwag Matitiis",
				"expression": "uneasy_smile",
				"is_monologue": true,
				"text": "Tomei apenas os três de sempre. Tudo voltou ao lugar... ou ao menos parece estar no lugar."
			}], Callable())
	)


func _on_interactable_triggered(item_name: String) -> void:
	var act3 := GameState.is_unfiltered_act3()
	var higher := _is_higher_dose_active()
	var ato: int = int(GameState.get_var("Ato", 1))

	match item_name:
		"Cama":
			if GameState.get_switch("005_Chefe_liberou_cidade") and ato == 1:
				request_dialogue.emit([
					{
						"speaker": "Huwag Matitiis",
						"expression": "tired",
						"text": "O plantão terminou, mas a fumaça ainda arde no peito.\nDormir até amanhã?",
						"choices": ["Dormir (Avançar para Ato 2)", "Ainda não"]
					}
				], func(choice: int) -> void:
					if choice == 0:
						GameState.advance_to_act_2()
						_apply_visual_atmosphere()
						_trigger_act2_pill_choice()
				)
				return
			elif GameState.get_switch("019_Ato2_concluido") and ato == 2:
				request_dialogue.emit([
					{
						"speaker": "Huwag Matitiis",
						"expression": "tired",
						"text": "O segundo dia terminou, mas algo antigo arranha atrás da memória.\nDeitar e fechar os olhos?",
						"choices": ["Dormir (Enfrentar a fita VHS)", "Ainda não"]
					}
				], func(choice: int) -> void:
					if choice == 0:
						request_level_change.emit("res://scenes/levels/vhs_memory_minigame.tscn", "from_bed")
				)
				return

			var bed_txt := (
				"Os lençóis estão empapados de suor frio... Há um afundamento no colchão, como se alguém tivesse saído daqui um segundo atrás."
				if higher else (
					"A cama de bambu range no quarto sem cor. Os pesadelos deixaram marcas escuras no travesseiro."
					if act3 else
					"Minha cama de bambu, com o mosquiteiro recolhido e o tapete de banig ao pé.\nUm lugar conhecido que já não parece acolhedor."
				)
			)
			request_dialogue.emit([{"speaker": "Huwag Matitiis", "expression": "tired", "text": bed_txt}], Callable())

		"Mesa_Remedios":
			if act3:
				request_dialogue.emit([{
					"speaker": "Huwag Matitiis",
					"expression": "unfiltered",
					"text": "Frascos âmbar vazios ao lado da miniatura enferrujada de Jeepney.\nNão há mais pílulas para maquiar Agdangan."
				}], Callable())
			elif ato == 2 and not GameState.get_switch("006c_Dose_escolhida_Ato2"):
				_trigger_act2_pill_choice()
			elif ato == 2:
				var txt := (
					"Os vidros estão caídos e comprimidos brancos se misturam a estilhaços sobre a madeira.\nA dose extra rasgou os contornos da realidade."
					if higher else
					"Os frascos de hoje estão alinhados ao lado da miniatura do Jeepney. Mantive a dose habitual de três comprimidos."
				)
				request_dialogue.emit([{
					"speaker": "Huwag Matitiis",
					"expression": "scared" if higher else "neutral",
					"text": txt
				}], Callable())
			else:
				request_dialogue.emit([
					{
						"speaker": "Huwag Matitiis",
						"expression": "neutral",
						"text": "Três comprimidos todo dia de manhã, ao lado da miniatura de lata que meu irmão me deu antes de tudo desmoronar."
					}
				], Callable())

		"Armario_Uniforme":
			var cur_outfit := GameState.equipped_outfit
			var status_txt := "Uniforme BFP" if cur_outfit == "bfp" else "Roupa Casual"
			request_dialogue.emit([
				{
					"speaker": "Huwag Matitiis",
					"expression": "neutral",
					"text": "Armário de serviço (%s)." % status_txt,
					"choices": [
						"Vestir Uniforme de Bombeiro (BFP)",
						"Vestir Roupa Casual",
						"Fechar"
					]
				}
			], func(choice: int) -> void:
				if choice == 0:
					GameState.set_equipped_outfit("bfp", true)
				elif choice == 1:
					GameState.set_equipped_outfit("casual", true)
			)

		"Janela_Norte":
			if higher:
				request_dialogue.emit([{
					"speaker": "Huwag Matitiis",
					"expression": "scared",
					"text": "Não há árvores nem céu além da grade da janela... só um breu compacto e dois pontos pálidos me observando de fora."
				}], Callable())
			elif act3:
				request_dialogue.emit([{
					"speaker": "Huwag Matitiis",
					"expression": "unfiltered",
					"text": "Coqueiros cinzentos e parados contra o céu chumbo de Agdangan."
				}], Callable())
			else:
				request_dialogue.emit([{
					"speaker": "Huwag Matitiis",
					"expression": "tired" if _is_night_room() else "worried",
					"text": "Pela fresta das grades, o vento traz cheiro de sal, palha úmida e fuligem antiga."
				}], Callable())

		"Radio_Quartel":
			if higher:
				request_dialogue.emit([{
					"speaker": "Huwag Matitiis",
					"expression": "scared",
					"text": "[Chiado contínuo no alto-falante] ...não acenda os faróis... não olhe para as janelas da rua... a fumaça ainda lembra o teu nome..."
				}], Callable())
			else:
				request_dialogue.emit([
					{
						"speaker": "Capitão Reyes",
						"text": "[Chiado de rádio] \"Estação BFP Agdangan na escuta. Compareça ao quartel na rua principal assim que estiver pronto.\""
					},
					{
						"speaker": "Huwag Matitiis",
						"expression": "angry",
						"text": "\"Entendido, Capitão. Saindo para Agdangan agora.\""
					}
				], Callable())

		"Geladeira":
			request_dialogue.emit([{
				"speaker": "Huwag Matitiis",
				"expression": "scared" if higher else "neutral",
				"text": "Água turva dentro da jarra... parece refletir o teto mesmo com a tampa fechada." if higher else "Uma jarra de barro com água fresca e mantimentos embrulhados antes do turno."
			}], Callable())

		"Porta_Saida":
			if ato == 2 and not GameState.get_switch("006c_Dose_escolhida_Ato2"):
				_trigger_act2_pill_choice()
				return
			if GameState.get_switch("005_Chefe_liberou_cidade") and ato == 1:
				request_dialogue.emit([
					{
						"speaker": "Huwag Matitiis",
						"expression": "tired",
						"text": "Anoiteceu em Agdangan. Sair para a rua ou descansar e iniciar o Ato 2?",
						"choices": ["Sair para a rua", "Dormir e avançar para o Ato 2", "Ficar no quarto"]
					}
				], func(choice: int) -> void:
					if choice == 0:
						request_level_change.emit("res://scenes/levels/StreetPreview.tscn", "from_room")
					elif choice == 1:
						GameState.advance_to_act_2()
						_apply_visual_atmosphere()
						_trigger_act2_pill_choice()
				)
			else:
				request_dialogue.emit([
					{
						"speaker": "Huwag Matitiis",
						"expression": "scared" if higher else "neutral",
						"text": "A fresta sob a porta dá para a rua silenciosa lá fora.\nSair para Agdangan?",
						"choices": ["Sair para Agdangan", "Ainda não"]
					}
				], func(choice: int) -> void:
					if choice == 0:
						request_level_change.emit("res://scenes/levels/StreetPreview.tscn", "from_room")
				)

		"Gato":
			if higher:
				request_dialogue.emit([{
					"speaker": "Huwag Matitiis",
					"expression": "scared",
					"text": "Pusa está imóvel como tinta derramada. Os dois olhos brancos piscaram só depois que eu desviei o olhar."
				}], Callable())
			else:
				request_dialogue.emit([{
					"speaker": "Huwag Matitiis",
					"expression": "neutral",
					"text": "Pusa dorme encolhido no canto da esteira, respirando devagar."
				}], Callable())
