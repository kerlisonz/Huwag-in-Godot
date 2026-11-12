extends Node2D

# ForestClearing - Clareira da Lagoa (Atos 1, 2 e 3)
# Ato 1: Encontro ético com a Guardiã Aquática (atacar/conversar/observar/fugir) e ninho de ovos azuis
# Ato 2: Ocorrência do incêndio florestal e resgate do gatinho da Senhora Luningning
# Ato 3: A revelação e reflexo da realidade sem filtros, levando à conclusão da jornada

signal request_level_change(target_scene: String, spawn_tag: String)
signal request_dialogue(pages: Array, callback: Callable)

@onready var exit_area: Area2D = get_node_or_null("ExitToTrailArea")
@onready var creature: Node2D = get_node_or_null("ObstaclesYsort/AquaticCreature")
@onready var player: PlayerController = get_node_or_null("ObstaclesYsort/PlayerHuwag")
@onready var egg_nest: Node2D = get_node_or_null("ObstaclesYsort/EggNest")
@onready var obstacles_ysort: Node2D = get_node_or_null("ObstaclesYsort")

var _cat_node: Node2D = null
var _pond_mirror_node: Interactable = null

func _ready() -> void:
	if exit_area:
		exit_area.body_entered.connect(_on_exit_area_body_entered)

	if player:
		player.position = Vector2(120, 240)
		player.facing_dir = Vector2.RIGHT
		player.set_camera_limits(Rect2i(0, 0, 800, 480))
		if player.camera:
			player.camera.zoom = Vector2(1.0, 1.0)

	var ato: int = int(GameState.get_var("Ato", 1))
	var act3 := GameState.is_unfiltered_act3()

	# Configurações de acordo com o Ato
	if act3:
		# No Ato 3, os monstros e fantasmas sumiram. Resta a lagoa real.
		if creature:
			creature.visible = false
			creature.position = Vector2(-999, -999)
		if egg_nest:
			egg_nest.visible = false
		_setup_act3_pond_mirror()
		if has_node("/root/AudioManager"):
			get_node("/root/AudioManager").play_ambience("act3_ambience")
	elif ato == 2:
		# Ato 2: Fogo na floresta e gatinho para resgate
		if creature:
			creature.visible = false
			creature.position = Vector2(-999, -999)
		if egg_nest:
			egg_nest.visible = false
		if GameState.get_switch("014_Floresta_liberada") and not GameState.get_switch("018_Gatinho_devolvido"):
			_setup_act2_cat_rescue()
		if has_node("/root/AudioManager"):
			get_node("/root/AudioManager").play_ambience("afternoon_ambience")
	else:
		# Ato 1: Guardiã Aquática e Ninho
		if creature and creature.has_signal("interaction_requested"):
			creature.connect("interaction_requested", _on_creature_interaction)
		if egg_nest:
			var nest_inter := egg_nest.get_node_or_null("NestInteractable") as Interactable
			if nest_inter:
				nest_inter.interacted.connect(_on_nest_interaction)
		if has_node("/root/AudioManager"):
			get_node("/root/AudioManager").play_ambience("morning_ambience")

func _on_exit_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		request_level_change.emit("res://scenes/levels/forest_trail.tscn", "from_clearing")

func _on_nest_interaction(_interactable: Interactable) -> void:
	if GameState.get_switch("003_Ovos_sem_derrotar") or GameState.get_switch("004_Ovos_e_derrotou"):
		request_dialogue.emit([
			{
				"speaker": "Huwag",
				"portrait": "res://assets/characters/portraits/huwag_casual_neutral.png",
				"text": "O ninho de musgo está em repouso. Os ovos restantes continuam aquecidos pela brisa da lagoa."
			}
		], Callable())
		return

	var pages: Array[Dictionary] = [
		{
			"speaker": "Huwag Matitiis",
			"expression": "worried",
			"text": "Três ovos azuis brilhantes repousam sobre o canteiro de musgo úmido. Emanam um pulso suave de energia aquática.\nComo agir diante do ninho?",
			"choices": [
				"Colher 1 ovo com cuidado (Observar o ciclo da natureza)",
				"Tentar recolher todos os ovos para estudo",
				"Não interferir no ninho"
			]
		}
	]
	request_dialogue.emit(pages, func(choice: int) -> void:
		if choice == 0:
			GameState.set_switch("003_Ovos_sem_derrotar", true)
			GameState.set_switch("016_Magia_de_agua_obtida", true)
			GameState.trigger_turn_afternoon()
			if has_node("/root/AudioManager"):
				get_node("/root/AudioManager").play_sfx("ui_select")
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
	cat_inter.position = Vector2(430, 240)

	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 32.0
	col.shape = shape
	cat_inter.add_child(col)

	var cat_sprite := ColorRect.new()
	cat_sprite.custom_minimum_size = Vector2(16, 12)
	cat_sprite.position = Vector2(-8, -6)
	cat_sprite.color = Color(0.95, 0.70, 0.35, 1.0) # Gatinho alaranjado
	cat_inter.add_child(cat_sprite)

	cat_inter.interacted.connect(func(_i: Interactable):
		if GameState.get_switch("017_Gatinho_encontrado"):
			return
		GameState.set_switch("017_Gatinho_encontrado", true)
		cat_inter.visible = false
		if has_node("/root/AudioManager"):
			get_node("/root/AudioManager").play_sfx("ui_select")
		request_dialogue.emit([
			{
				"speaker": "Huwag Matitiis",
				"expression": "worried",
				"text": "Miau! O gatinho está tremendo em cima de uma pedra cercada por fumaça, com os pelos chamuscados."
			},
			{
				"speaker": "Huwag Matitiis",
				"expression": "neutral",
				"text": "Calma, pequenino... você está seguro agora.\n(Envolvi o gatinho com cuidado no forro térmico do meu casaco BFP. Preciso levá-lo imediatamente para a Senhora Luningning no quartel!)."
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
	mirror.position = Vector2(495, 240)

	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 50.0
	col.shape = shape
	mirror.add_child(col)

	mirror.interacted.connect(func(_i: Interactable):
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
		request_dialogue.emit(pages, func(_choice: int):
			GameState.set_switch("025_Ato3_confronto_lagoa", true)
			GameState.set_switch("026_Jogo_finalizado", true)
			var tw := create_tween()
			tw.tween_interval(0.5)
			tw.tween_callback(func():
				request_level_change.emit("res://scenes/menu/EndingCredits.tscn", "from_clearing")
			)
		)
	)

	add_child(mirror)
