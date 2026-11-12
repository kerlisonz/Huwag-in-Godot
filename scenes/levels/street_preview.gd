extends Node2D

signal request_level_change(target_scene: String, spawn_tag: String)
signal request_dialogue(pages: Array, callback: Callable)

@onready var player: PlayerController = $YSortEntities/Player
@onready var bg_day: Sprite2D = $BackgroundDay
@onready var bg_night: Sprite2D = $BackgroundNight
@onready var collisions_body: StaticBody2D = $CityCollisions
@onready var interactables_root: Node2D = $Interactables

# Dimensões da rua de Agdangan em escala de jogo (1952 × 544)
const MAP_BOUNDS := Rect2i(0, 0, 1952, 544)

func _ready() -> void:
	# 1. Configura posição de entrada de acordo com spawn_tag
	match GameState.spawn_tag:
		"from_room":
			# Ponto exato diante da porta da Casa de Huwag (escadinha em x=569, y=370)
			player.position = Vector2(569, 395)
			player.facing_dir = Vector2.DOWN
		"from_station":
			# Em frente à porta de saída do Quartel BFP
			player.position = Vector2(1185, 345)
			player.facing_dir = Vector2.DOWN
		"from_forest":
			# Retorno da estrada da floresta ao leste
			player.position = Vector2(1915, 450)
			player.facing_dir = Vector2.LEFT
		_:
			player.position = Vector2(569, 395)
			player.facing_dir = Vector2.DOWN

	# 2. Configura limites da câmera para cobrir todo o mapa de 1952x544
	player.set_camera_limits(MAP_BOUNDS)

	# 3. Configura física e interações
	_setup_collisions()
	_setup_interactables()

	# 4. Atualiza atmosfera visual dia/noite
	GameState.time_of_day_changed.connect(func(_v: bool) -> void: _apply_visual_atmosphere())
	GameState.perception_changed.connect(func(_m: int) -> void: _apply_visual_atmosphere())
	GameState.switch_changed.connect(func(_k: String, _v: bool) -> void: _apply_visual_atmosphere())

	_apply_visual_atmosphere()

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

func _apply_visual_atmosphere() -> void:
	var act3 := GameState.is_unfiltered_act3()
	var night := _is_night()

	if bg_day:
		bg_day.visible = not night
	if bg_night:
		bg_night.visible = night

	var tint := Color.WHITE
	if act3:
		tint = Color(0.72, 0.74, 0.78, 1.0)
	elif night:
		tint = Color(0.92, 0.94, 1.0, 1.0)

	if bg_day:
		bg_day.modulate = tint
	if bg_night:
		bg_night.modulate = tint

	if has_node("/root/AudioManager"):
		var am = get_node("/root/AudioManager")
		if act3:
			am.play_ambience("act3_ambience")
		elif night:
			am.play_ambience("night_ambience")
		elif GameState.is_afternoon:
			am.play_ambience("afternoon_ambience")
		else:
			am.play_ambience("morning_ambience")

func _setup_collisions() -> void:
	if collisions_body == null:
		collisions_body = get_node_or_null("CityCollisions") as StaticBody2D
	if collisions_body == null:
		collisions_body = StaticBody2D.new()
		collisions_body.name = "CityCollisions"
		collisions_body.collision_layer = 1
		collisions_body.collision_mask = 0
		add_child(collisions_body)

	# --- 1. LIMITES PERIMETRAIS DO MAPA ---
	# Norte (vegetação e encosta de palmeiras acima do cenário)
	_add_box(collisions_body, Rect2(0, 0, 480, 115))
	_add_box(collisions_body, Rect2(480, 0, 280, 140))
	_add_box(collisions_body, Rect2(760, 0, 480, 120))
	_add_box(collisions_body, Rect2(1240, 0, 712, 70))

	# Sul (limite inferior da pista e vegetação da orla)
	_add_box(collisions_body, Rect2(0, 470, 300, 74))
	_add_box(collisions_body, Rect2(300, 515, 1652, 29))

	# Oeste (fundo do mar e encosta da praia)
	_add_box(collisions_body, Rect2(0, 0, 35, 544))

	# Leste (bloqueio acima e abaixo da estrada da floresta)
	_add_box(collisions_body, Rect2(1945, 0, 20, 415))
	_add_box(collisions_body, Rect2(1945, 485, 20, 60))

	# --- 2. PRAIA, CABANAS E CERCA COSTEIRA ---
	_add_box(collisions_body, Rect2(70, 75, 85, 75))      # Cabana de pescador 1 (topo)
	_add_box(collisions_body, Rect2(210, 140, 85, 75))    # Cabana de pescador 2 (meio)
	_add_box(collisions_body, Rect2(295, 385, 85, 80))    # Cabana sobre palafitas
	_add_box(collisions_body, Rect2(360, 150, 16, 320))   # Cerca de bambu ao longo da curva da estrada

	# --- 3. PÓRTICO DE ENTRADA (WELCOME TO AGDANGAN) ---
	_add_box(collisions_body, Rect2(410, 130, 16, 26))    # Pilar oeste
	_add_box(collisions_body, Rect2(462, 130, 16, 26))    # Pilar leste

	# --- 4. QUADRA DE BASQUETE E CASAS AO REDOR ---
	_add_box(collisions_body, Rect2(470, 80, 75, 75))     # Casa no canto noroeste da quadra
	_add_box(collisions_body, Rect2(550, 70, 200, 70))    # Casas ao norte da quadra
	_add_circle(collisions_body, Vector2(512, 175), 6.0)  # Tabela oeste
	_add_circle(collisions_body, Vector2(735, 175), 6.0)  # Tabela leste

	# --- 5. CASA DE HUWAG (QUITINETE) ---
	# Fachada sólida da casa (deixa a escadinha e quintal livres em y >= 370)
	_add_box(collisions_body, Rect2(500, 275, 160, 95))
	_add_box(collisions_body, Rect2(472, 280, 25, 90))    # Cerca de madeira à esquerda da casa

	# --- 6. SARI-SARI STORE (ALÍNG NENA) ---
	_add_box(collisions_body, Rect2(695, 305, 110, 80))   # Loja e balcão
	_add_box(collisions_body, Rect2(705, 385, 30, 15))    # Caixotes de produtos

	# --- 7. POSTO COMUNITÁRIO / PONTO DE ESPERA DO BARANGAY ---
	_add_box(collisions_body, Rect2(835, 315, 75, 70))

	# --- 8. QUARTEL DOS BOMBEIROS (BFP AGDANGAN FIRE STATION) ---
	_add_box(collisions_body, Rect2(940, 120, 290, 190))  # Prédio principal de 2 andares
	_add_box(collisions_body, Rect2(942, 160, 36, 170))   # Torre de treinamento / escada
	_add_box(collisions_body, Rect2(1085, 275, 52, 90))   # Caminhão de bombeiros vermelho na garagem
	_add_circle(collisions_body, Vector2(995, 345), 5.0)  # Mastro da bandeira
	_add_box(collisions_body, Rect2(932, 310, 12, 90))    # Mureta lateral oeste do pátio
	_add_box(collisions_body, Rect2(1232, 310, 12, 90))   # Mureta lateral leste do pátio

	# --- 9. KARINDERYA / LANCHONETE E TRICICLOS ---
	_add_box(collisions_body, Rect2(1255, 265, 165, 120)) # Edifício de 2 andares
	_add_box(collisions_body, Rect2(1272, 395, 36, 16))   # Mesas externas oeste
	_add_box(collisions_body, Rect2(1360, 395, 36, 16))   # Mesas externas leste
	_add_box(collisions_body, Rect2(1318, 418, 30, 20))   # Triciclo azul 1
	_add_box(collisions_body, Rect2(1408, 418, 30, 20))   # Triciclo azul 2

	# --- 10. BAIRRO RESIDENCIAL E MUROS DE PEDRA ---
	_add_box(collisions_body, Rect2(1470, 235, 140, 90))  # Casa residencial norte
	_add_box(collisions_body, Rect2(1465, 335, 150, 70))  # Casa residencial sul
	_add_box(collisions_body, Rect2(1450, 405, 75, 12))   # Trecho oeste do muro
	_add_box(collisions_body, Rect2(1565, 405, 150, 12))  # Trecho leste do muro (vão do portão livre em x:1525..1565)

	# --- 11. IGREJA DE AGDANGAN ---
	_add_box(collisions_body, Rect2(1730, 75, 160, 130))  # Prédio colonial de pedra da igreja
	_add_circle(collisions_body, Vector2(1690, 205), 4.0) # Placa de madeira indicadora

	# --- 12. POSTES DE ENERGIA AO LONGO DA VIA ---
	_add_circle(collisions_body, Vector2(680, 435), 4.0)
	_add_circle(collisions_body, Vector2(930, 435), 4.0)
	_add_circle(collisions_body, Vector2(1245, 435), 4.0)
	_add_circle(collisions_body, Vector2(1525, 435), 4.0)
	_add_circle(collisions_body, Vector2(1750, 435), 4.0)

func _add_box(parent: Node2D, r: Rect2) -> void:
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = r.size
	col.shape = shape
	col.position = r.position + r.size * 0.5
	parent.add_child(col)

func _add_circle(parent: Node2D, pos: Vector2, radius: float) -> void:
	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = radius
	col.shape = shape
	col.position = pos
	parent.add_child(col)

func _setup_interactables() -> void:
	if interactables_root == null:
		interactables_root = get_node_or_null("Interactables")
	if interactables_root == null:
		interactables_root = Node2D.new()
		interactables_root.name = "Interactables"
		add_child(interactables_root)

	# 1. Porta da Casa de Huwag (retorno ao quarto)
	_add_interactable("Casa_Huwag", "Casa de Huwag", "Entrar", Vector2(569, 375), Vector2(28, 20))

	# 2. Quadra de Basquete Comunitária
	_add_interactable("Quadra_Basquete", "Quadra do Barangay", "Observar", Vector2(620, 260), Vector2(40, 24))

	# 3. Sari-Sari Store (mercearia)
	_add_interactable("Sari_Sari", "Sari-Sari Store", "Examinar", Vector2(750, 395), Vector2(36, 22))

	# 4. Posto / Mural de Avisos do Barangay
	_add_interactable("Mural_Barangay", "Mural do Barangay", "Olhar", Vector2(870, 395), Vector2(32, 22))

	# 5. Caminhão de Bombeiros na Garagem
	_add_interactable("Caminhao_Bombeiros", "Caminhão de Bombeiros", "Examinar", Vector2(1110, 375), Vector2(44, 26))

	# 6. Porta do Quartel dos Bombeiros (BFP)
	_add_interactable("Entrada_Quartel", "Quartel dos Bombeiros", "Entrar", Vector2(1185, 335), Vector2(28, 22))

	# 7. Triciclo de Passageiros
	_add_interactable("Karinderya_Triciclo", "Triciclo", "Examinar", Vector2(1330, 440), Vector2(32, 22))

	# 8. Igreja de Agdangan
	_add_interactable("Igreja_Agdangan", "Igreja de Agdangan", "Observar", Vector2(1810, 210), Vector2(40, 26))

	# 9. Píer dos Pescadores na Praia
	_add_interactable("Cais_Praia", "Píer dos Pescadores", "Olhar", Vector2(160, 435), Vector2(36, 28))

	# 10. Estrada para a Floresta (ao leste)
	_add_interactable("Estrada_Floresta", "Estrada para a Floresta", "Seguir", Vector2(1925, 450), Vector2(28, 60))

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

func _on_interactable_triggered(id: String) -> void:
	var ato: int = int(GameState.get_var("Ato", 1))
	var act3 := GameState.is_unfiltered_act3()

	match id:
		"Casa_Huwag":
			var pages: Array[Dictionary] = [
				{
					"speaker": "Huwag Matitiis",
					"expression": "neutral",
					"text": "Minha casa em Agdangan. Retornar para o quarto?",
					"choices": ["Entrar em casa", "Ficar na rua"]
				}
			]
			request_dialogue.emit(pages, func(choice: int) -> void:
				if choice == 0:
					request_level_change.emit("res://scenes/levels/RoomHuwag.tscn", "from_street")
			)

		"Quadra_Basquete":
			if act3:
				request_dialogue.emit([
					{
						"speaker": "Huwag Matitiis",
						"expression": "unfiltered",
						"text": "A quadra comunitária está deserta. A tabela de madeira está rachada pelas chuvas tropicais... Aqui costumavam brincar as crianças antes daquela noite."
					}
				], Callable())
			else:
				request_dialogue.emit([
					{
						"speaker": "Huwag Matitiis",
						"expression": "neutral",
						"text": "A quadra comunitária de basquete do barangay. O concreto cinza sob o sol lembra as tardes em que a vizinhança inteira se reunia aqui."
					}
				], Callable())

		"Sari_Sari":
			if act3:
				request_dialogue.emit([
					{
						"speaker": "Aling Nena",
						"text": "Huwag... meu filho, você esteve acordado a noite inteira de novo? Seus olhos estão tão fundos..."
					},
					{
						"speaker": "Aling Nena",
						"text": "Nós nunca te culpamos por aquele incêndio, Huwag. Você foi um herói ao tentar tirar todo mundo da fábrica. Por favor, não continue se castigando sozinho."
					},
					{
						"speaker": "Huwag Matitiis",
						"expression": "unfiltered",
						"text": "Salamat, Aling Nena... Eu precisava ouvir isso sem a névoa dos remédios."
					}
				], Callable())
			elif ato == 2 and GameState.get_switch("007_Chefe_Ato2_apresentado") and not GameState.get_switch("011_Missao_chave2_concluida"):
				var pages_sari: Array[Dictionary] = [
					{
						"speaker": "Aling Nena",
						"text": "Huwag! Que alívio ver um bombeiro aqui! O fio da minha geladeira começou a soltar faíscas contra a parede de tábua! Pode desligar o disjuntor principal para mim?",
						"choices": ["Isolar a fiação com segurança", "Depois eu volto"]
					}
				]
				request_dialogue.emit(pages_sari, func(choice: int) -> void:
					if choice == 0:
						GameState.complete_optional_mission("011_Missao_chave2_concluida")
						request_dialogue.emit([
							{
								"speaker": "Aling Nena",
								"text": "Naku, salamat po! Você evitou que a loja inteira pegasse fogo! O Capitão Reyes tem orgulho de você, Huwag!"
							}
						], Callable())
				)
			elif GameState.get_switch("011_Missao_chave2_concluida"):
				request_dialogue.emit([
					{
						"speaker": "Aling Nena",
						"text": "A fiação está segura agora, Huwag. Obrigado por proteger nossa vendinha!"
					}
				], Callable())
			else:
				request_dialogue.emit([
					{
						"speaker": "Aling Nena",
						"text": "Magandang umaga, Huwag! Indo para mais um turno no quartel? Tome cuidado lá fora, rapaz!"
					}
				], Callable())

		"Mural_Barangay":
			if act3:
				request_dialogue.emit([
					{
						"speaker": "Huwag Matitiis",
						"expression": "unfiltered",
						"text": "Mural do barangay. Sob a poeira cinzenta, ainda há uma nota antiga: 'Gratidão aos bombeiros voluntários pelo socorro no Grande Incêndio de Quezon'."
					}
				], Callable())
			else:
				request_dialogue.emit([
					{
						"speaker": "Huwag Matitiis",
						"expression": "neutral",
						"text": "Mural informativo do barangay. Há avisos sobre prevenção contra queimadas na época de seca e o calendário de serviços comunitários de Quezon."
					}
				], Callable())

		"Caminhao_Bombeiros":
			if act3:
				request_dialogue.emit([
					{
						"speaker": "Huwag Matitiis",
						"expression": "unfiltered",
						"text": "O caminhão de combate a incêndio da BFP. Há uma fita preta discreta amarrada ao retrovisor... Uma homenagem solene aos bombeiros do meu pelotão que não voltaram."
					}
				], Callable())
			else:
				request_dialogue.emit([
					{
						"speaker": "Huwag Matitiis",
						"expression": "determined",
						"text": "O caminhão de prontidão do quartel BFP. Tanque carregado, mangueiras dobradas no padrão. Cada minuto conta quando o alarme toca."
					}
				], Callable())

		"Entrada_Quartel":
			var pages_station: Array[Dictionary] = [
				{
					"speaker": "Huwag Matitiis",
					"expression": "neutral",
					"text": "Estação do Bureau of Fire Protection (BFP) de Agdangan. Entrar no quartel?",
					"choices": ["Entrar no Quartel", "Permanecer na rua"]
				}
			]
			request_dialogue.emit(pages_station, func(choice: int) -> void:
				if choice == 0:
					request_level_change.emit("res://scenes/levels/FireStation.tscn", "from_city")
			)

		"Karinderya_Triciclo":
			if act3:
				request_dialogue.emit([
					{
						"speaker": "Kuya Ben",
						"text": "Huwag... Eu vi você andando de madrugada, com aquele olhar perdido. O Capitão Reyes está no quartel te esperando. Vá falar com ele, irmão."
					},
					{
						"speaker": "Kuya Ben",
						"text": "Ninguém aqui te julga pelo que aconteceu no ano passado. Você foi o único que sobreviveu porque seus amigos quiseram que você vivesse. Honre a vida deles vivendo a sua."
					}
				], Callable())
			elif ato == 2 and GameState.get_switch("007_Chefe_Ato2_apresentado") and not GameState.get_switch("009_Missao_chave1_concluida"):
				var pages_ben: Array[Dictionary] = [
					{
						"speaker": "Kuya Ben",
						"text": "Huwag! O motor do triciclo aqueceu demais e está pingando óleo quente perto da mangueira de combustível! Você tem um pouco d'água ou ferramentas para esfriar o bloco antes que incendeie?",
						"choices": ["Resfriar o motor e apertar a válvula", "Agora não posso"]
					}
				]
				request_dialogue.emit(pages_ben, func(choice: int) -> void:
					if choice == 0:
						GameState.complete_optional_mission("009_Missao_chave1_concluida")
						request_dialogue.emit([
							{
								"speaker": "Kuya Ben",
								"text": "Ufa! Salvou meu ganha-pão, Huwag! O Capitão Reyes disse que você é o melhor bombeiro que Quezon já viu. Obrigado, irmão!"
							}
						], Callable())
				)
			elif GameState.get_switch("009_Missao_chave1_concluida"):
				request_dialogue.emit([
					{
						"speaker": "Kuya Ben",
						"text": "O motor está roncando suave agora! Obrigado pela ajuda, Huwag!"
					}
				], Callable())
			else:
				request_dialogue.emit([
					{
						"speaker": "Kuya Ben",
						"text": "Oi, Huwag! O triciclo está pronto para levar a turma do mercado. Tenha um bom turno no quartel!"
					}
				], Callable())

		"Igreja_Agdangan":
			if act3:
				request_dialogue.emit([
					{
						"speaker": "Huwag Matitiis",
						"expression": "unfiltered",
						"text": "A igreja colonial sob o céu cinzento. Uma oração na lápide dos fundadores: 'Mesmo na cinza mais escura, a vida renasce'."
					}
				], Callable())
			else:
				request_dialogue.emit([
					{
						"speaker": "Huwag Matitiis",
						"expression": "neutral",
						"text": "A histórica igreja de pedra no alto da colina. O sino de bronze tocou em todos os grandes tufões e celebrações da cidade."
					}
				], Callable())

		"Cais_Praia":
			if act3:
				request_dialogue.emit([
					{
						"speaker": "Mang Carding",
						"text": "A maré está baixa e o vento está frio hoje, Huwag... A água do mar lava tudo, meu rapaz, menos a culpa que a gente insiste em carregar."
					},
					{
						"speaker": "Huwag Matitiis",
						"expression": "unfiltered",
						"text": "Eu achava que os remédios me protegiam, Mang Carding... Mas eles só adiavam a dor."
					}
				], Callable())
			elif ato == 2 and GameState.get_switch("007_Chefe_Ato2_apresentado") and not GameState.get_switch("013_Missao_chave3_concluida"):
				var pages_cais: Array[Dictionary] = [
					{
						"speaker": "Mang Carding",
						"text": "Bombeiro Huwag! Uma lamparina a querosene tombou na lancha dos pescadores e as redes secas estão pegando fogo! Ajude a apagar antes que atinja o barco todo!",
						"choices": ["Usar água para abafar as chamas", "Agora não dá"]
					}
				]
				request_dialogue.emit(pages_cais, func(choice: int) -> void:
					if choice == 0:
						GameState.complete_optional_mission("013_Missao_chave3_concluida")
						request_dialogue.emit([
							{
								"speaker": "Mang Carding",
								"text": "Graças a Deus e à sua rapidez, Huwag! O fogo nas redes foi apagado a tempo! Muito obrigado!"
							}
						], Callable())
				)
			elif GameState.get_switch("013_Missao_chave3_concluida"):
				request_dialogue.emit([
					{
						"speaker": "Mang Carding",
						"text": "As redes estão salvas e o barco está intacto. Grande trabalho, Huwag!"
					}
				], Callable())
			else:
				request_dialogue.emit([
					{
						"speaker": "Huwag Matitiis",
						"expression": "neutral",
						"text": "O pequeno cais de madeira sobre as águas da costa. As bancas dos pescadores balançam devagar com a brisa do oceano."
					}
				], Callable())

		"Estrada_Floresta":
			if ato == 1 and not GameState.get_switch("002_Chefe_Ato1_apresentado"):
				request_dialogue.emit([
					{
						"speaker": "Huwag Matitiis",
						"expression": "neutral",
						"text": "A estrada leste leva à floresta. Devo me apresentar ao Capitão Reyes no Quartel BFP antes de sair em patrulha."
					}
				], Callable())
			elif ato == 2 and not GameState.get_switch("014_Floresta_liberada"):
				request_dialogue.emit([
					{
						"speaker": "Huwag Matitiis",
						"expression": "neutral",
						"text": "A estrada para a floresta está sob controle da BFP. Devo atender aos pedidos de apoio na rua e verificar o quartel antes de sair."
					}
				], Callable())
			else:
				var prompt_msg := (
					"A estrada leva à clareira da floresta. As cinzas já se assentaram. Seguir para a clareira (Ato III)?"
					if act3 else (
						"Fumaça densa está subindo da mata leste! O incêndio florestal começou! Entrar na trilha em chamas?"
						if (ato == 2 and GameState.get_switch("014_Floresta_liberada")) else
						"A estrada de terra segue para a floresta e o sopé das montanhas de Quezon. Seguir pela trilha?"
					)
				)
				var pages_forest: Array[Dictionary] = [
					{
						"speaker": "Huwag Matitiis",
						"expression": "determined",
						"text": prompt_msg,
						"choices": ["Seguir para a Floresta", "Ficar em Agdangan"]
					}
				]
				request_dialogue.emit(pages_forest, func(choice: int) -> void:
					if choice == 0:
						request_level_change.emit("res://scenes/levels/forest_trail.tscn", "from_city")
				)
