extends Node2D

## ForestClearing — Clareira da Lagoa (Atos 1, 2 e 3)
## Santuário montanhoso em Agdangan após a travessia perigosa da floresta.
## Estética FNAF Minigames + Yume Nikki + Chrono Trigger + Pokémon GB (960x576 / 60x36 tiles).

signal request_level_change(target_scene: String, spawn_tag: String)
signal request_dialogue(pages: Array, callback: Callable)

const RetroLevelHelpers := preload("res://scripts/levels/retro_level_helpers.gd")
const NORMAL_TS := preload("res://assets/tilesets/retro/forest_fnaf_normal_tileset.tres")
const DISTORTED_TS := preload("res://assets/tilesets/retro/forest_fnaf_distorted_tileset.tres")

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
	if creature and creature.has_signal("interaction_requested"):
		creature.interaction_requested.connect(_on_creature_interaction)

	var ato: int = int(GameState.get_var("Ato", 1))
	if ato == 2 and not GameState.get_switch("017_Gatinho_encontrado"):
		_setup_act2_cat_rescue()
	if GameState.is_unfiltered_act3():
		_setup_act3_pond_mirror()

	GameState.perception_changed.connect(func(_m: int) -> void: _sync_clearing_atmosphere())
	GameState.switch_changed.connect(func(_k: String, _v: bool) -> void: _sync_clearing_atmosphere())
	if GameState.has_signal("higher_dose_changed"):
		GameState.higher_dose_changed.connect(func(active: bool) -> void: apply_higher_dose_world(active))

	_sync_clearing_atmosphere()

	if has_node("/root/AudioManager"):
		if GameState.is_unfiltered_act3():
			get_node("/root/AudioManager").play_ambience("act3_ambience")
		else:
			get_node("/root/AudioManager").play_ambience("night_forest")


func _process(delta: float) -> void:
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
	return GameState.has_method("is_higher_dose") and GameState.is_higher_dose()


func _build_clearing_tilemaps() -> void:
	for layer in [ground_normal, walls_normal]:
		layer.tile_set = NORMAL_TS
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

	# Bacia sagrada da lagoa centrada em (495, 240) -> tiles x=29..32, y=13..16 (raio visual <= 48px)
	for x in range(MAP_W):
		for y in range(MAP_H):
			for gl in [ground_normal, ground_distorted]:
				gl.set_cell(Vector2i(x, y), 0, Vector2i(3, 0))

			var in_pond_core := (x >= 29 and x <= 32 and y >= 13 and y <= 16)
			if not walkable[x][y]:
				var wcoord := Vector2i(0, 1)
				if y > 2 and y < MAP_H - 3 and x > 1 and x < MAP_W - 2:
					if y + 1 < MAP_H and walkable[x][y + 1]:
						wcoord = Vector2i(2, 1)
					elif y - 1 >= 0 and walkable[x][y - 1]:
						wcoord = Vector2i(1, 1)
				for wl in [walls_normal, walls_distorted]:
					wl.set_cell(Vector2i(x, y), 0, wcoord)
			elif in_pond_core:
				var is_edge := (x == 29 or x == 32 or y == 13 or y == 16)
				var water_tile := Vector2i(4, 1) if is_edge else Vector2i(3, 1)
				for wl in [walls_normal, walls_distorted]:
					wl.set_cell(Vector2i(x, y), 0, water_tile)
				for gl in [ground_normal, ground_distorted]:
					gl.set_cell(Vector2i(x, y), 0, Vector2i(8, 0))
			else:
				var gtile := Vector2i(1, 0)
				if (x * 5 + y) % 8 == 0:
					gtile = Vector2i(2, 0)
				if x >= 27 and x <= 35 and y >= 11 and y <= 18:
					gtile = Vector2i(8, 0) if (x + y) % 4 != 0 else Vector2i(9, 0)
				elif x >= 23 and x <= 39 and y >= 8 and y <= 21:
					gtile = Vector2i(11, 0) if (x == 24 or x == 38 or y == 9 or y == 20) else Vector2i(6, 0)
				elif x >= 25 and x <= 36 and y >= 25 and y <= 29:
					gtile = Vector2i(11, 0)
				for gl in [ground_normal, ground_distorted]:
					gl.set_cell(Vector2i(x, y), 0, gtile)

	# Trilha oeste + píer de madeira até a margem da Guardiã + margem leste dos ovos
	for gl in [ground_normal, ground_distorted]:
		RetroLevelHelpers.paint_rect(gl, 0, 14, 24, 2, Vector2i(4, 0))
		RetroLevelHelpers.paint_rect(gl, 24, 14, 4, 2, Vector2i(10, 0))  # Píer oeste até x=448
		RetroLevelHelpers.paint_rect(gl, 35, 14, 5, 2, Vector2i(8, 0))   # Margem dos ovos (x=560..640)

	walls_distorted.collision_enabled = false


func _build_clearing_props_and_lights() -> void:
	var canopy_ring := [
		Vector2(140, 96), Vector2(260, 82), Vector2(495, 76), Vector2(720, 86),
		Vector2(835, 140), Vector2(852, 260), Vector2(840, 390),
		Vector2(740, 480), Vector2(240, 486), Vector2(130, 396)
	]
	for pos in canopy_ring:
		_add_dual_prop("pine_canopy_cluster", pos, ysort_obstacles, Vector2(0, -24))

	for pos in [Vector2(210, 118), Vector2(790, 116), Vector2(780, 420)]:
		_add_dual_prop("dead_gnarled_tree", pos, ysort_obstacles, Vector2(0, -20))

	_add_dual_prop("wooden_signpost", Vector2(215, 200), ysort_obstacles, Vector2(0, -10))

	for pos in [Vector2(380, 240), Vector2(495, 336), Vector2(610, 256), Vector2(495, 168)]:
		var st_n := RetroLevelHelpers.create_prop_sprite("floor_stain", false)
		st_n.position = pos
		decals_layer.add_child(st_n)
		_normal_props.append(st_n)

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


func _sync_clearing_atmosphere() -> void:
	var ato: int = int(GameState.get_var("Ato", 1))
	var act3 := GameState.is_unfiltered_act3()
	var higher := _is_higher_dose_active()

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

	if canvas_mod:
		if act3:
			canvas_mod.color = Color(0.64, 0.66, 0.69, 1.0)
		elif higher:
			canvas_mod.color = Color(0.34, 0.21, 0.27, 1.0)
		elif ato == 2 and GameState.get_switch("015_Floresta_em_chamas"):
			canvas_mod.color = Color(0.52, 0.38, 0.36, 1.0)
		elif GameState.is_afternoon:
			canvas_mod.color = Color(0.50, 0.44, 0.48, 1.0)
		else:
			canvas_mod.color = Color(0.42, 0.46, 0.54, 1.0)

	if _pond_light and is_instance_valid(_pond_light):
		if act3:
			_pond_light.color = Color(0.84, 0.87, 0.90)
		elif higher:
			_pond_light.color = Color(0.88, 0.15, 0.22)
		else:
			_pond_light.color = Color(0.45, 0.85, 0.96)

	if water_ripples:
		water_ripples.color = (
			Color(0.85, 0.20, 0.25, 0.55) if higher else
			(Color(0.80, 0.83, 0.86, 0.35) if act3 else Color(0.62, 0.88, 0.96, 0.50))
		)


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
				"portrait": "res://assets/characters/portraits/placeholder_creature.png",
				"text": "Na água avermelhada, três reflexos sem rosto boiam lado a lado.\n\"Os ovos nunca foram mágicos, Huwag. Você os contou porque não suportava contar capacetes vazios.\""
			}
		], Callable())
		return

	if GameState.get_switch("003_Ovos_sem_derrotar") or GameState.get_switch("004_Ovos_e_derrotou"):
		request_dialogue.emit([
			{
				"speaker": "Guardiã da Lagoa",
				"portrait": "res://assets/characters/portraits/placeholder_creature.png",
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
					"portrait": "res://assets/characters/portraits/placeholder_creature.png",
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
			if creature:
				creature.call("take_damage", 70)
			GameState.set_switch("004_Ovos_e_derrotou", true)
			GameState.set_switch("016_Magia_de_agua_obtida", true)
			GameState.trigger_turn_afternoon()
			request_dialogue.emit([
				{
					"speaker": "Huwag Matitiis",
					"expression": "angry",
					"text": "O golpe de machado estilhaçou a calmaria da água! A criatura recuou para o fundo da lagoa, deixando uma onda de choque que impregnou meu machado de energia aquática."
				}
			], Callable())
	)


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
	mirror.verb = "Observar Reflexo (Ato III)"
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
