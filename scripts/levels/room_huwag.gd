extends Node2D

signal request_level_change(target_scene: String, spawn_tag: String)
signal request_dialogue(pages: Array, callback: Callable)

const RetroLevelHelpers := preload("res://scripts/levels/retro_level_helpers.gd")
const V2TileCatalog := preload("res://scripts/levels/v2_tile_catalog.gd")
const AtmosphereRig := preload("res://scripts/levels/atmosphere_rig.gd")
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
var _furniture_layer: TileMapLayer = null


func _ready() -> void:
	if GameState.spawn_tag == "from_street":
		player.position = Vector2(540, 220)
		player.facing_dir = Vector2.LEFT
	elif GameState.spawn_tag == "from_nightmare":
		player.position = Vector2(288, 224)
		player.facing_dir = Vector2.DOWN
		GameState.advance_to_act_3()
		call_deferred("_trigger_act3_wake_monologue")
	else:
		player.position = Vector2(288, 224)
		player.facing_dir = Vector2.DOWN

	player.set_camera_limits(Rect2i(105, 55, 542, 305))

	_build_tilemaps()
	_build_room_props_and_lights()
	_setup_room_collisions()
	_setup_interactables()

	GameState.time_of_day_changed.connect(func(_v: bool) -> void: _apply_visual_atmosphere())
	GameState.perception_changed.connect(func(_m: int) -> void: _apply_visual_atmosphere())
	GameState.outfit_changed.connect(func(_o: String) -> void: _apply_visual_atmosphere())
	if GameState.has_signal("day_period_changed"):
		GameState.day_period_changed.connect(func(_p: String) -> void: _apply_visual_atmosphere())
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
	if GameState.has_method("is_night_time") and GameState.is_night_time():
		return true
	var ato: int = int(GameState.get_var("Ato", 1))
	return (
		(ato == 1 and GameState.get_switch("005_Chefe_liberou_cidade"))
		or (ato == 2 and GameState.get_switch("019_Ato2_concluido"))
	)


func _build_tilemaps() -> void:
	var t_cat := V2TileCatalog.INTERIOR_TILES
	for layer in [floor_normal, walls_normal]:
		layer.tile_set = ACT3_TS if GameState.is_unfiltered_act3() else NORMAL_TS
	for layer in [floor_distorted, walls_distorted]:
		layer.tile_set = DISTORTED_TS
		layer.collision_enabled = false

	# Fundo void limpo em torno do quarto compacto (21x10 tiles úteis: x=13..33, y=10..19)
	for fl in [floor_normal, floor_distorted]:
		fl.clear()
		V2TileCatalog.fill_rect(fl, Rect2i(12, 8, 23, 13), t_cat["wood_floor_dark"])
		V2TileCatalog.fill_rect(fl, Rect2i(13, 10, 21, 10), t_cat["wood_floor_warm"])

		# Tábuas mais escuras alternadas para textura contínua de madeira filipina
		for y in range(10, 20):
			for x in range(13, 34):
				if (x + y * 2) % 4 == 0:
					fl.set_cell(Vector2i(x, y), 0, t_cat["wood_floor_dark"])

		# Área de dormir oeste com UMA esteira Banig limpa ao pé da cama (100% caminhável)
		V2TileCatalog.stamp_rect(fl, Vector2i(13, 14), t_cat["banig_tl"], Vector2i(3, 2))

		# Tapete vermelho central tecido na sala de estar sob a janela (livres os trilhos ao redor da mesa)
		V2TileCatalog.stamp_rect(fl, Vector2i(18, 14), t_cat["rug_crimson_tl"], Vector2i(2, 2))
		V2TileCatalog.stamp_rect(fl, Vector2i(20, 14), t_cat["rug_crimson_tl"], Vector2i(2, 2))

		# Canto nordeste de cozinha compacta com piso terracota e tábuas contínuas na entrada
		V2TileCatalog.fill_rect(fl, Rect2i(26, 10, 8, 3), t_cat["concrete_station"])

	# Paredes perimetrais Sawali + Madeira + Sombra projetada nas camadas normal e distorcida
	for wl in [walls_normal, walls_distorted]:
		wl.clear()
		V2TileCatalog.fill_rect(wl, Rect2i(13, 8, 21, 1), t_cat["wall_sawali_m"])
		V2TileCatalog.fill_rect(wl, Rect2i(13, 9, 21, 1), t_cat["wall_wood_mid"])
		wl.set_cell(Vector2i(13, 8), 0, t_cat["wall_sawali_l"])
		wl.set_cell(Vector2i(33, 8), 0, t_cat["wall_sawali_r"])
		wl.set_cell(Vector2i(13, 9), 0, t_cat["wall_wood_left"])
		wl.set_cell(Vector2i(33, 9), 0, t_cat["wall_wood_right"])

		# Sombras projetadas pelas paredes sobre o piso (profundidade 16x16)
		for sx in range(14, 34):
			wl.set_cell(Vector2i(sx, 10), 0, t_cat["shadow_top"])
		for sy in range(11, 20):
			wl.set_cell(Vector2i(13, sy), 0, t_cat["shadow_left"])
		wl.set_cell(Vector2i(13, 10), 0, t_cat["shadow_corner"])

		# Parede oeste (x=12) + borda sul (y=20) + parede leste com vão compacto de porta (y=13..15)
		V2TileCatalog.fill_rect(wl, Rect2i(12, 8, 1, 12), t_cat["wall_wood_left"])
		V2TileCatalog.fill_rect(wl, Rect2i(12, 20, 23, 1), t_cat["wall_trim_gold"])
		V2TileCatalog.fill_rect(wl, Rect2i(34, 8, 1, 5), t_cat["wall_wood_right"])
		V2TileCatalog.fill_rect(wl, Rect2i(34, 16, 1, 4), t_cat["wall_wood_right"])

	# Camada Y-sorted com colisão real para mobiliário multi-tile v2 (sem apagar paredes nem bloquear a porta)
	if _furniture_layer == null:
		_furniture_layer = TileMapLayer.new()
		_furniture_layer.name = "V2FurnitureLayer"
		_furniture_layer.z_index = 0
		_furniture_layer.y_sort_enabled = true
		_furniture_layer.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_furniture_layer.collision_enabled = true
		if ysort_root != null:
			ysort_root.add_child(_furniture_layer)
		else:
			add_child(_furniture_layer)
	if ysort_root != null:
		ysort_root.z_index = 2
	_furniture_layer.tile_set = ACT3_TS if GameState.is_unfiltered_act3() else (DISTORTED_TS if _is_higher_dose_active() else NORMAL_TS)
	_furniture_layer.clear()

	# Zona de descanso (canto NO) + Estudo/Armário alinhados abaixo da parede superior + Janela na parede + Cozinha NE + Mesa com 4 cadeiras
	V2TileCatalog.stamp_rect(_furniture_layer, Vector2i(13, 10), t_cat["bed_huwag"], Vector2i(3, 4))
	V2TileCatalog.stamp_rect(_furniture_layer, Vector2i(16, 8), t_cat["wardrobe"], Vector2i(2, 3))
	V2TileCatalog.stamp_rect(_furniture_layer, Vector2i(18, 9), t_cat["bookshelf_a"], Vector2i(2, 2))
	V2TileCatalog.stamp_rect(_furniture_layer, Vector2i(21, 8), t_cat["window_day_tl"], Vector2i(2, 3))
	V2TileCatalog.stamp_rect(_furniture_layer, Vector2i(24, 8), t_cat["radio_pc_bfp"], Vector2i(1, 3))
	V2TileCatalog.stamp_rect(_furniture_layer, Vector2i(26, 8), t_cat["fridge_sari"], Vector2i(2, 3))
	V2TileCatalog.stamp_rect(_furniture_layer, Vector2i(29, 9), t_cat["kitchen_counter"], Vector2i(4, 3))
	V2TileCatalog.stamp_rect(_furniture_layer, Vector2i(24, 14), t_cat["table_dining"], Vector2i(3, 3))
	_furniture_layer.set_cell(Vector2i(25, 13), 0, t_cat["chair_down"])
	_furniture_layer.set_cell(Vector2i(25, 17), 0, t_cat["chair_up"])
	_furniture_layer.set_cell(Vector2i(23, 15), 0, t_cat["chair_right"])
	_furniture_layer.set_cell(Vector2i(27, 15), 0, t_cat["chair_left"])
	V2TileCatalog.stamp_rect(_furniture_layer, Vector2i(13, 17), t_cat["indoor_palm"], Vector2i(2, 3))


func _build_room_props_and_lights() -> void:
	# Gato Pusa no canto sudeste do quarto compacto
	_add_dual_prop("pusa_cat", Vector2(504, 298), Vector2(1.25, 1.25), -4)

	# Decais exclusivos do estado distorcido (Yume Nikki + manchas dentro dos novos limites x=224..528)
	_add_distorted_decal("floor_stain", Vector2(288, 224), Vector2(1.4, 1.2))
	_add_distorted_decal("floor_stain", Vector2(456, 200), Vector2(1.2, 1.1))
	_add_distorted_decal("yume_eye_rune", Vector2(280, 272), Vector2(1.1, 1.1))
	_add_distorted_decal("yume_eye_rune", Vector2(360, 146), Vector2(1.0, 1.0))
	_add_distorted_decal("yume_eye_rune", Vector2(492, 146), Vector2(1.0, 1.0))

	# Ventilador compacto na parede norte entre a estante (x=18..19) e a janela (x=21..22)
	var fan_root := Node2D.new()
	fan_root.name = "WallFan"
	fan_root.position = Vector2(328, 138)
	fan_root.z_index = 2
	ysort_root.add_child(fan_root)

	var cage := Polygon2D.new()
	cage.color = Color(0.18, 0.20, 0.24, 0.92)
	cage.polygon = PackedVector2Array([
		Vector2(-6, -6), Vector2(6, -6), Vector2(6, 6), Vector2(-6, 6)
	])
	fan_root.add_child(cage)

	_fan_blades = Node2D.new()
	_fan_blades.name = "FanBlades"
	for rot_idx in range(4):
		var blade := Polygon2D.new()
		blade.color = Color(0.52, 0.56, 0.62, 0.9)
		blade.rotation = rot_idx * PI * 0.5
		blade.polygon = PackedVector2Array([
			Vector2(-1, -1), Vector2(5, -2), Vector2(5, 1), Vector2(-1, 1)
		])
		_fan_blades.add_child(blade)
	fan_root.add_child(_fan_blades)

	if light_shaft != null:
		light_shaft.polygon = PackedVector2Array([
			Vector2(336, 144), Vector2(368, 144), Vector2(392, 236), Vector2(312, 236)
		])

	# Luzes PointLight2D atmosféricas alinhadas ao quarto compacto
	_window_light = RetroLevelHelpers.create_point_light(Vector2(352, 195), Color(0.76, 0.85, 0.98), 0.72, 2.2)
	_lamp_light = RetroLevelHelpers.create_point_light(Vector2(408, 240), Color(1.0, 0.76, 0.42), 0.92, 1.8)
	_door_light = RetroLevelHelpers.create_point_light(Vector2(536, 228), Color(0.90, 0.76, 0.48), 0.58, 1.3)
	_radio_light = RetroLevelHelpers.create_point_light(Vector2(392, 152), Color(0.28, 0.92, 0.52), 0.45, 0.6)
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

	var period: String = GameState.get_day_period() if GameState.has_method("get_day_period") else ("afternoon" if GameState.is_afternoon else "morning")
	if canvas_mod:
		if act3:
			canvas_mod.color = Color(0.60, 0.62, 0.65, 1.0)
		elif higher:
			canvas_mod.color = Color(0.54, 0.49, 0.56, 1.0)
		elif night or period == "night":
			canvas_mod.color = Color(0.42, 0.46, 0.60, 1.0)
		elif period == "afternoon" or GameState.is_afternoon:
			canvas_mod.color = Color(0.68, 0.62, 0.66, 1.0)
		else:
			canvas_mod.color = Color(0.76, 0.78, 0.84, 1.0)

	if _lamp_light:
		_lamp_light.color = Color(0.92, 0.46, 0.52) if higher else (Color(0.84, 0.84, 0.86) if act3 else Color(1.0, 0.76, 0.42))
	if _window_light:
		_window_light.energy = 0.48 if higher else (0.58 if night else 0.82)
		_window_light.color = Color(0.84, 0.48, 0.56) if higher else (Color(0.82, 0.84, 0.88) if act3 else Color(0.74, 0.84, 0.96))
	if _radio_light:
		_radio_light.color = Color(0.95, 0.36, 0.42) if higher else Color(0.28, 0.92, 0.52)
	if light_shaft:
		light_shaft.visible = not higher
		light_shaft.color = Color(0.75, 0.78, 0.82, 0.05) if act3 else (Color(0.45, 0.56, 0.78, 0.06) if night else Color(0.78, 0.84, 0.94, 0.09))

	if has_node("/root/AudioManager"):
		var am = get_node("/root/AudioManager")
		if am.has_method("sync_adaptive_soundtrack"):
			am.call("sync_adaptive_soundtrack", "room_huwag", false)
		elif act3:
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

	# Paredes exatas alinhadas ao quarto compacto (interior x=208..544, y=160..320; móveis/cama colidem via V2FurnitureLayer)
	_add_box_collision(body, Rect2(192, 0, 384, 156))       # Norte (até y=156)
	_add_box_collision(body, Rect2(192, 320, 384, 40))      # Sul (abaixo de y=320)
	_add_box_collision(body, Rect2(0, 0, 208, 360))         # Oeste (até x=208)
	_add_box_collision(body, Rect2(544, 0, 96, 208))        # Leste acima da porta
	_add_box_collision(body, Rect2(544, 256, 96, 104))      # Leste abaixo da porta
	_add_box_collision(body, Rect2(552, 208, 88, 48))       # Trava externa do vão da porta (y=208..256)

	# Colisão circular do gato dormindo no canto sudeste
	var cat_shape := CollisionShape2D.new()
	var cat_circle := CircleShape2D.new()
	cat_circle.radius = 11.0
	cat_shape.shape = cat_circle
	cat_shape.position = Vector2(504, 298)
	body.add_child(cat_shape)


func _add_box_collision(parent: Node2D, r: Rect2) -> void:
	var shape_node := CollisionShape2D.new()
	var rect_shape := RectangleShape2D.new()
	rect_shape.size = r.size
	shape_node.shape = rect_shape
	shape_node.position = r.position + r.size * 0.5
	parent.add_child(shape_node)


func _setup_interactables() -> void:
	_add_interactable("Cama", "Cama de Bambu", "Descansar", Vector2(236, 198), Vector2(68, 66))
	_add_interactable("Mesa_Remedios", "Mesa de Remédios", "Examinar", Vector2(408, 248), Vector2(56, 48))
	_add_interactable("Armario_Uniforme", "Armário do Uniforme", "Abrir", Vector2(270, 166), Vector2(36, 20))
	_add_interactable("Janela_Norte", "Janela Grades", "Olhar", Vector2(352, 166), Vector2(40, 24))
	_add_interactable("Radio_Quartel", "Rádio Comunicador BFP", "Checar", Vector2(392, 166), Vector2(28, 24))
	_add_interactable("Geladeira", "Jarra e Provisões", "Examinar", Vector2(432, 166), Vector2(40, 24))
	_add_interactable("Porta_Saida", "Porta para Agdangan", "Sair", Vector2(546, 228), Vector2(26, 44))
	_add_interactable("Gato", "Pusa", "Acariciar", Vector2(504, 296), Vector2(28, 24))


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
			"text": "Amanheceu um novo dia, mas minha cabeça ainda gira com o silêncio da noite.\nSobre a mesa, os comprimidos aguardam."
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
						"choices": ["Dormir até o amanhecer", "Ainda não"]
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
			var status_txt := GameState.get_equipped_outfit_label()
			var current_id := GameState.equipped_outfit
			request_dialogue.emit([
				{
					"speaker": "Huwag Matitiis",
					"expression": "neutral",
					"text": "Armário do quarto (equipado: %s).\nEscolha o traje para Agdangan:" % status_txt,
					"choices": [
						"Vestir Uniforme de Bombeiro (BFP)" + (" [Atual]" if current_id == "bfp" else ""),
						"Vestir Roupa Casual (Jaqueta Escura)" + (" [Atual]" if current_id == "casual" else ""),
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
					"speaker": "Rádio BFP",
					"expression": "distorted",
					"text": "[Chiado contínuo no alto-falante] ...não acenda os faróis... não olhe para as janelas da rua... a fumaça ainda lembra o teu nome..."
				}], Callable())
			else:
				request_dialogue.emit([
					{
						"speaker": "Rádio BFP",
						"text": "[Estática chiada na faixa de emergência de Agdangan...]"
					},
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
						"text": "Anoiteceu em Agdangan. Sair para a rua ou descansar até o próximo turno?",
						"choices": ["Sair para a rua", "Dormir até o amanhecer", "Ficar no quarto"]
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
