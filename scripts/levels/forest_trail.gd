extends Node2D

# ForestTrail - Trilha da Floresta (Atos 1, 2 e 3)
# Ato 1: Caminho verdejante até a clareira da lagoa
# Ato 2: Trilha tomada por queimada florestal com inimigos Santelmo e barreiras de fogo
# Ato 3: Natureza desbotada, silenciosa e real a caminho do confronto final

signal request_level_change(target_scene: String, spawn_tag: String)
signal request_dialogue(pages: Array, callback: Callable)

@onready var exit_area: Area2D = get_node_or_null("ExitToClearingArea")
@onready var exit_city_area: Area2D = get_node_or_null("ExitToCityArea")
@onready var player: PlayerController = get_node_or_null("ObstaclesYsort/PlayerHuwag")
@onready var ysort_obstacles: Node2D = get_node_or_null("ObstaclesYsort")

func _ready() -> void:
	if exit_area:
		exit_area.body_entered.connect(_on_exit_area_body_entered)
	if exit_city_area:
		exit_city_area.body_entered.connect(_on_exit_city_area_body_entered)

	if player:
		if GameState.spawn_tag == "from_clearing":
			player.position = Vector2(1330, 200)
			player.facing_dir = Vector2.LEFT
		else:
			player.position = Vector2(80, 190)
			player.facing_dir = Vector2.RIGHT

		player.set_camera_limits(Rect2i(0, 0, 1400, 450))
		if player.camera:
			player.camera.zoom = Vector2(1.0, 1.0)

	var ato: int = int(GameState.get_var("Ato", 1))
	var act3 := GameState.is_unfiltered_act3()

	if act3:
		# Ato 3: Floresta sem filtros
		if has_node("/root/AudioManager"):
			get_node("/root/AudioManager").play_ambience("act3_ambience")
	elif ato == 2 and GameState.get_switch("014_Floresta_liberada") and not GameState.get_switch("019_Ato2_concluido"):
		# Ato 2: Incêndio florestal ativo!
		_setup_act2_wildfire()
		if has_node("/root/AudioManager"):
			get_node("/root/AudioManager").play_ambience("fire_hazard")
	else:
		# Ato 1: Manhã pacífica
		if has_node("/root/AudioManager"):
			get_node("/root/AudioManager").play_ambience("morning_ambience")

func _setup_act2_wildfire() -> void:
	# Spawna Santelmo (espírito de fogo filipino) no meio da trilha
	var santelmo_scene := load("res://scenes/enemies/santelmo.tscn") as PackedScene
	if santelmo_scene and ysort_obstacles:
		var s1 := santelmo_scene.instantiate() as CharacterBody2D
		s1.position = Vector2(620, 210)
		ysort_obstacles.add_child(s1)

		var s2 := santelmo_scene.instantiate() as CharacterBody2D
		s2.position = Vector2(1020, 190)
		ysort_obstacles.add_child(s2)

	# Adiciona aviso de perigo
	GameState.notification_requested.emit("PERIGO: Incêndio florestal ativo! Use Magia de Água [Q/K]!")

func _on_exit_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		request_level_change.emit("res://scenes/levels/forest_clearing.tscn", "from_trail")

func _on_exit_city_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		request_level_change.emit("res://scenes/levels/StreetPreview.tscn", "from_forest")
