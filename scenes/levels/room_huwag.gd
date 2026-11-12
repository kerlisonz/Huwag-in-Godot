extends Node2D

signal request_level_change(target_scene: String, spawn_tag: String)
signal request_dialogue(pages: Array, callback: Callable)

@onready var player: CharacterBody2D = $YSortEntities/Player
@onready var interactables_root: Node2D = $Interactables
@onready var fan_blades: Sprite2D = get_node_or_null("YSortEntities/WallFan/FanBlades")
@onready var sunlight_overlay: Node2D = $SunlightOverlay
@onready var bg_sprite: Sprite2D = $Background
@onready var ysort_root: Node2D = $YSortEntities

var fan_angle: float = 0.0
var dust_time: float = 0.0

func _ready() -> void:
	if GameState.spawn_tag == "from_street":
		player.position = Vector2(535, 275)
		player.facing_dir = Vector2.LEFT
	else:
		player.position = Vector2(250, 205)
		player.facing_dir = Vector2.DOWN

	player.set_camera_limits(Rect2i(0, 0, 640, 360))
	_setup_room_collisions()
	_setup_interactables()

	GameState.time_of_day_changed.connect(func(_v: bool) -> void: _apply_visual_atmosphere())
	GameState.perception_changed.connect(func(_m: int) -> void: _apply_visual_atmosphere())
	GameState.outfit_changed.connect(func(_o: String) -> void: _apply_visual_atmosphere())

	_apply_visual_atmosphere()

	if not GameState.get_self_switch("EV_Introducao", "A"):
		GameState.set_self_switch("EV_Introducao", "A", true)
		call_deferred("_trigger_intro_monologue")

func _process(delta: float) -> void:
	fan_angle = fmod(fan_angle + delta * 12.0, TAU)
	if fan_blades:
		fan_blades.rotation = fan_angle
	dust_time += delta
	if sunlight_overlay:
		sunlight_overlay.queue_redraw()

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

func _apply_visual_atmosphere() -> void:
	var act3 := GameState.is_unfiltered_act3()
	var night := _is_night_room()

	var tint := Color.WHITE
	if act3:
		tint = Color(0.72, 0.74, 0.78, 1.0)
	elif night:
		tint = Color(0.68, 0.72, 0.90, 1.0)

	if bg_sprite:
		bg_sprite.modulate = tint
	if ysort_root:
		for child in ysort_root.get_children():
			if child is Sprite2D and child != player:
				child.modulate = tint

func _trigger_intro_monologue() -> void:
	var pages: Array[Dictionary] = [
		{
			"speaker": "Huwag Matitiis",
			"expression": "tired",
			"is_monologue": true,
			"text": "Sempre fui bom em fingir que estava tudo sob controle.\nTalvez seja por isso que me tornei bombeiro... Quando você passa os dias apagando os incêndios dos outros, ninguém repara na fumaça saindo de dentro de você."
		},
		{
			"speaker": "Huwag Matitiis",
			"expression": "uneasy_smile",
			"is_monologue": true,
			"text": "Hoje é mais um dia de serviço no quartel. Os remédios da manhã já começaram a fazer efeito...\nAs cores estão vivas de novo. O mundo parece calmo. Preciso me levantar e me apresentar ao Capitão Reyes."
		}
	]
	request_dialogue.emit(pages, Callable())

func _setup_room_collisions() -> void:
	var body := StaticBody2D.new()
	body.name = "RoomWalls"
	body.collision_layer = 1
	add_child(body)

	# 1. Parede norte sólida (acima de y=156)
	_add_box_collision(body, Rect2(0, 0, 640, 156))

	# 2. Borda sul inferior do piso (abaixo de y=325)
	_add_box_collision(body, Rect2(0, 325, 640, 35))

	# 3. Parede oeste sólida (lado esquerdo - sela completamente até o chão da sala em x=100)
	_add_box_collision(body, Rect2(0, 0, 100, 360))

	# 4. Parede leste superior (acima do vão da porta)
	_add_box_collision(body, Rect2(538, 0, 102, 190))

	# 5. Parede leste inferior (abaixo do vão da porta - sela até o batente da parede em x=552)
	_add_box_collision(body, Rect2(552, 260, 88, 100))

	# 6. Barreira exterior do vão da porta (bloqueia o vazio exterior a leste da soleira em x >= 560)
	_add_box_collision(body, Rect2(560, 190, 80, 70))

	# 7. Cama de bambu com dossel (x=100 a 228, y=156 a 248 - sem frestas na parede oeste)
	_add_box_collision(body, Rect2(100, 156, 128, 92))

	# 8. Armário/Aparador de cabeceira com remédios e jarro (x=390 a 456, y=150 a 208)
	_add_box_collision(body, Rect2(390, 150, 66, 58))

	# 9. Mesa de refeição sólida com lamparina e canecas (x=485 a 542, y=170 a 266)
	_add_box_collision(body, Rect2(485, 170, 57, 96))

	# 10. Gato dormindo no tapete (colisão circular ajustada na almofada x=509, y=312)
	var cat_shape := CollisionShape2D.new()
	var cat_circle := CircleShape2D.new()
	cat_circle.radius = 12.0
	cat_shape.shape = cat_circle
	cat_shape.position = Vector2(509, 312)
	body.add_child(cat_shape)

func _add_box_collision(parent: Node2D, r: Rect2) -> void:
	var shape_node := CollisionShape2D.new()
	var rect_shape := RectangleShape2D.new()
	rect_shape.size = r.size
	shape_node.shape = rect_shape
	shape_node.position = r.position + r.size * 0.5
	parent.add_child(shape_node)

func _add_poly_collision(parent: Node2D, pts: PackedVector2Array) -> void:
	var shape_node := CollisionPolygon2D.new()
	shape_node.polygon = pts
	parent.add_child(shape_node)

func _setup_interactables() -> void:
	if interactables_root == null:
		interactables_root = get_node_or_null("Interactables")
	if interactables_root == null:
		interactables_root = Node2D.new()
		interactables_root.name = "Interactables"
		add_child(interactables_root)
	# Cama de bambu (interagível ao lado da cama, na esteira)
	_add_interactable("Cama", "Cama de Bambu", "Descansar", Vector2(236, 205), Vector2(28, 40))
	# Mesa/Aparador com remédios (lado direito do armário)
	_add_interactable("Mesa_Remedios", "Mesa com Remédios", "Examinar", Vector2(435, 215), Vector2(30, 20))
	# Cabideiro de parede com uniforme
	_add_interactable("Armario_Uniforme", "Cabideiro de Serviço", "Abrir", Vector2(258, 165), Vector2(36, 20))
	# Janela tropical com palmeiras
	_add_interactable("Janela_Norte", "Janela para a Rua", "Olhar", Vector2(335, 165), Vector2(50, 20))
	# Rádio comunicador BFP na mesa (acessível pelo lado esquerdo da mesa)
	_add_interactable("Radio_Quartel", "Rádio Comunicador BFP", "Checar", Vector2(475, 215), Vector2(20, 36))
	# Jarro de água e provisões (lado esquerdo do armário)
	_add_interactable("Geladeira", "Jarro de Água e Provisões", "Examinar", Vector2(405, 215), Vector2(24, 20))
	# Porta de saída para a rua (no limiar da porta - isolada da mesa de refeição)
	_add_interactable("Porta_Saida", "Porta para Agdangan", "Sair", Vector2(550, 255), Vector2(24, 30))
	# Gatinho de estimação (sobre a almofada)
	_add_interactable("Gato", "Pusa", "Acariciar", Vector2(509, 305), Vector2(28, 24))

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

func _on_interactable_triggered(item_name: String) -> void:
	var act3 := GameState.is_unfiltered_act3()
	match item_name:
		"Cama":
			var ato_bed: int = int(GameState.get_var("Ato", 1))
			if GameState.get_switch("005_Chefe_liberou_cidade") and ato_bed == 1:
				var pages_sleep: Array = [
					{
						"speaker": "Huwag Matitiis",
						"expression": "tired",
						"text": "O plantão noturno terminou. O corpo pesa e os olhos ardem de fumaça.\nDeitar e descansar?",
						"choices": ["Dormir (Avançar para Ato 2)", "Ainda não"]
					}
				]
				request_dialogue.emit(pages_sleep, func(choice: int) -> void:
					if choice == 0:
						GameState.advance_to_act_2()
						_apply_visual_atmosphere()
						var wake_pages: Array = [
							{
								"speaker": "Huwag Matitiis",
								"expression": "neutral",
								"text": "Um novo dia começa em Agdangan. Os comprimidos da manhã já estão fazendo efeito.\nPreciso me apresentar ao Capitão Reyes no quartel."
							}
						]
						request_dialogue.emit(wake_pages, Callable())
				)
				return
			elif GameState.get_switch("019_Ato2_concluido") and ato_bed == 2:
				var pages_sleep2: Array = [
					{
						"speaker": "Huwag Matitiis",
						"expression": "tired",
						"text": "Mais um dia de fumaça e sirenes ficou para trás.\nDeitar e descansar?",
						"choices": ["Dormir (Avançar para Ato 3 — Sem Filtro)", "Ainda não"]
					}
				]
				request_dialogue.emit(pages_sleep2, func(choice: int) -> void:
					if choice == 0:
						GameState.advance_to_act_3()
						_apply_visual_atmosphere()
						var wake_act3: Array = [
							{
								"speaker": "Huwag Matitiis",
								"expression": "unfiltered",
								"text": "Acordei antes do despertador. Os frascos na mesa estão vazios.\nAs cores sumiram das paredes... Só restou a madeira gasta e o silêncio do quarto."
							}
						]
						request_dialogue.emit(wake_act3, Callable())
				)
				return

			var bed_text := (
				"A cama de bambu rangeu sob o peso. O lençol está úmido de suor.\nSem o efeito dos comprimidos, o quarto parece apenas um cubículo abafado."
				if act3 else
				"Uma cama de bambu tradicional com colcha tecida à mão e mosquiteiro.\nAcordei empapado com o calor matinal. Dormi poucas horas entre sonhos confusos e sirenes, mas o dever não espera."
			)
			request_dialogue.emit([{"speaker": "Huwag Matitiis", "expression": "tired", "text": bed_text}], Callable())

		"Mesa_Remedios":
			if act3:
				request_dialogue.emit([{
					"speaker": "Huwag Matitiis",
					"expression": "unfiltered",
					"text": "Três frascos vazios ao lado do pequeno Jeepney de lata desbotado.\nO efeito de hoje já se dissipou."
				}], Callable())
			else:
				request_dialogue.emit([
					{
						"speaker": "Huwag Matitiis",
						"expression": "neutral",
						"text": "Sobre o aparador estão meus três frascos matinais ao lado de uma miniatura de Jeepney que guardo desde criança."
					},
					{
						"speaker": "Huwag Matitiis",
						"expression": "uneasy_smile",
						"text": "Três comprimidos pela manhã. Sem falhar. Eles mantêm o mundo suportável, colorido e luminoso..."
					},
					{
						"speaker": "Huwag Matitiis",
						"expression": "worried",
						"text": "Já tomei a dose de hoje, antes que o silêncio aperte."
					}
				], Callable())

		"Armario_Uniforme":
			var cur_outfit := GameState.equipped_outfit
			var status_txt := (
				"Usando Uniforme de Bombeiro (BFP)."
				if cur_outfit == "bfp" else
				"Usando Roupa Casual."
			)
			var pages_locker: Array = [
				{
					"speaker": "Huwag Matitiis",
					"expression": "neutral",
					"text": "Cabideiro de serviço (%s).\nEscolha o que vestir:" % status_txt,
					"choices": [
						"Vestir Uniforme de Bombeiro (BFP)",
						"Vestir Roupa Casual (Jaqueta Escura)",
						"Manter roupa atual"
					]
				}
			]
			request_dialogue.emit(pages_locker, func(choice: int) -> void:
				if choice == 0:
					GameState.set_equipped_outfit("bfp", true)
				elif choice == 1:
					GameState.set_equipped_outfit("casual", true)
			)

		"Ventilador":
			request_dialogue.emit([
				{
					"speaker": "Huwag Matitiis",
					"expression": "worried",
					"text": "O ventilador de parede continua girando, rangendo baixinho.\nEle puxa o ar pesado e úmido do quarto."
				},
				{
					"speaker": "Huwag Matitiis",
					"expression": "scared",
					"text": "Por um segundo, o rangido metálico das pás quase soou como uma sirene distante... Melhor respirar fundo e focar no turno."
				}
			], Callable())

		"Janela_Norte":
			if act3:
				request_dialogue.emit([{
					"speaker": "Huwag Matitiis",
					"expression": "unfiltered",
					"text": "Pela janela aberta, os coqueiros lá fora parecem imóveis e sem cor sob o céu cinzento de Agdangan."
				}], Callable())
			elif _is_night_room():
				request_dialogue.emit([{
					"speaker": "Huwag Matitiis",
					"expression": "tired",
					"text": "Pela janela aberta, a brisa noturna balança suavemente as folhas dos coqueiros lá fora.\nOs grilos cantam na escuridão abafada de Agdangan."
				}], Callable())
			else:
				request_dialogue.emit([
					{
						"speaker": "Huwag Matitiis",
						"expression": "surprised",
						"text": "Pela janela aberta, o sol da manhã faz brilhar os coqueiros e o céu azul tropical de Agdangan!"
					},
					{
						"speaker": "Huwag Matitiis",
						"expression": "neutral",
						"text": "Lá fora, tudo parece tão acolhedor e tranquilo... Quase como uma pintura."
					}
				], Callable())

		"Radio_Quartel":
			var radio_pages: Array = [
				{
					"speaker": "Capitão Reyes",
					"text": "[Chiado de rádio] \"Estação BFP de Agdangan chamando Huwag. Está na escuta, rapaz? Compareça ao quartel assim que sair de casa.\""
				},
				{
					"speaker": "Huwag Matitiis",
					"expression": "angry",
					"text": "\"Na escuta, Capitão Reyes. Estou descendo para a rua agora mesmo.\""
				}
			]
			request_dialogue.emit(radio_pages, Callable())

		"Geladeira":
			var drink_text := (
				"Sobre o aparador de madeira há uma jarra de água fresca e algumas frutas.\nO essencial para antes de sair para o turno."
			)
			request_dialogue.emit([{"speaker": "Huwag Matitiis", "expression": "neutral", "text": drink_text}], Callable())

		"Porta_Saida":
			if GameState.get_switch("005_Chefe_liberou_cidade") and int(GameState.get_var("Ato", 1)) == 1:
				var pages_door_night: Array[Dictionary] = [
					{
						"speaker": "Huwag Matitiis",
						"expression": "tired",
						"text": "Já anoiteceu em Agdangan. Posso sair para a rua ou descansar para o próximo turno.",
						"choices": ["Sair para a rua", "Dormir e avançar para o Ato 2", "Ficar no quarto"]
					}
				]
				request_dialogue.emit(pages_door_night, func(choice: int) -> void:
					if choice == 0:
						request_level_change.emit("res://scenes/levels/StreetPreview.tscn", "from_room")
					elif choice == 1:
						GameState.advance_to_act_2()
				)
			else:
				var pages_door: Array[Dictionary] = [
					{
						"speaker": "Huwag Matitiis",
						"expression": "angry",
						"text": "Hora de ir para o quartel dos bombeiros.\nSair para a rua de Agdangan?",
						"choices": ["Sim, sair para Agdangan", "Ainda não"]
					}
				]
				request_dialogue.emit(pages_door, func(choice: int) -> void:
					if choice == 0:
						request_level_change.emit("res://scenes/levels/StreetPreview.tscn", "from_room")
				)

		"Gato":
			request_dialogue.emit([
				{
					"speaker": "Huwag Matitiis",
					"expression": "neutral",
					"text": "Pusa está enroscado no tapete, aproveitando o calor da manhã.\nEle nem se mexeu com o barulho dos meus passos... Dorme em paz, amiguinho."
				}
			], Callable())
