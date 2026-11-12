extends Node2D

signal request_level_change(target_scene: String, spawn_tag: String)
signal request_dialogue(pages: Array, callback: Callable)

@onready var player: PlayerController = $Player
@onready var interactables_root: Node2D = $Interactables

var _tex_floors_walls: Texture2D = null
var _tex_furniture: Texture2D = null
var _tex_small_items: Texture2D = null
var _tex_crawler_props: Texture2D = null
var _tex_crawler_walls: Texture2D = null
var _tex_npc_bob: Texture2D = null
var _tex_npc_adam: Texture2D = null
var _tex_npc_alex: Texture2D = null
var _tex_npc_amelia: Texture2D = null

func _ready() -> void:
	_tex_floors_walls = load("res://assets/third_party/Top-Down_Retro_Interior/TopDownHouse_FloorsAndWalls.png") as Texture2D
	_tex_furniture = load("res://assets/third_party/Top-Down_Retro_Interior/TopDownHouse_FurnitureState1.png") as Texture2D
	_tex_small_items = load("res://assets/third_party/Top-Down_Retro_Interior/TopDownHouse_SmallItems.png") as Texture2D
	_tex_crawler_props = load("res://assets/third_party/Pixel Crawler - Free Pack (Exterior 0.1)/Pixel Crawler - Free Pack/Environment/Structures/Buildings/Interior/Interior_Props_01.png") as Texture2D
	_tex_crawler_walls = load("res://assets/third_party/Pixel Crawler - Free Pack (Exterior 0.1)/Pixel Crawler - Free Pack/Environment/Structures/Buildings/Interior/Interior_Walls_01.png") as Texture2D
	_tex_npc_bob = load("res://assets/third_party/Modern_Interiors_Free_v2.2/Modern tiles_Free/Characters_free/Bob_16x16.png") as Texture2D
	_tex_npc_adam = load("res://assets/third_party/Modern_Interiors_Free_v2.2/Modern tiles_Free/Characters_free/Adam_16x16.png") as Texture2D
	_tex_npc_alex = load("res://assets/third_party/Modern_Interiors_Free_v2.2/Modern tiles_Free/Characters_free/Alex_16x16.png") as Texture2D
	_tex_npc_amelia = load("res://assets/third_party/Modern_Interiors_Free_v2.2/Modern tiles_Free/Characters_free/Amelia_16x16.png") as Texture2D

	player.position = Vector2(320, 286)
	player.facing_dir = Vector2.UP
	player.set_camera_limits(Rect2i(0, 0, 640, 360))
	_setup_collisions()
	_setup_interactables()
	GameState.switch_changed.connect(func(_k: String, _v: bool) -> void: queue_redraw())

func _setup_collisions() -> void:
	var body := StaticBody2D.new()
	body.name = "StationWalls"
	body.collision_layer = 1
	add_child(body)

	var rects: Array[Rect2] = [
		Rect2(80, 20, 480, 52),
		Rect2(80, 326, 480, 20),
		Rect2(80, 20, 16, 324),
		Rect2(544, 20, 16, 324),
		Rect2(268, 86, 104, 34),
		Rect2(116, 212, 84, 32),
	]
	for r in rects:
		var shape_node := CollisionShape2D.new()
		var rect_shape := RectangleShape2D.new()
		rect_shape.size = r.size
		shape_node.shape = rect_shape
		shape_node.position = r.position + r.size * 0.5
		body.add_child(shape_node)

func _setup_interactables() -> void:
	_add_interactable("Cap_Reyes", "Capitão Reyes", "Conversar", Vector2(320, 108), Vector2(96, 48))
	_add_interactable("Bombeiro_Ato", "Bombeiro Ato", "Conversar", Vector2(416, 152), Vector2(36, 36))
	_add_interactable("Bombeiro_Santos", "Bombeiro Santos", "Conversar", Vector2(204, 184), Vector2(36, 36))
	_add_interactable("Enfermeira_Maria", "Enfermeira Maria", "Conversar", Vector2(468, 224), Vector2(36, 36))
	_add_interactable("Velhinha_Espera", "Senhora na Espera", "Conversar", Vector2(158, 224), Vector2(56, 38))
	_add_interactable("Cilindros_Parede", "Cilindros de Combate", "Examinar", Vector2(164, 76), Vector2(44, 28))
	_add_interactable("Porta_Saida_Quartel", "Porta do Quartel", "Sair", Vector2(320, 314), Vector2(48, 28))

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

	inter.interacted.connect(_on_interacted)
	interactables_root.add_child(inter)

func _on_interacted(inter: Interactable) -> void:
	var id := inter.interaction_id
	var ato: int = int(GameState.get_var("Ato", 1))

	match id:
		"Cap_Reyes":
			if ato == 1:
				if GameState.get_switch("003_Ovos_sem_derrotar") or GameState.get_switch("004_Ovos_e_derrotou"):
					if not GameState.get_switch("005_Chefe_liberou_cidade"):
						GameState.set_switch("005_Chefe_liberou_cidade", true)
						var msg := (
							"Você trouxe os ovos e enfrentou aquela criatura na clareira? Bom trabalho, Huwag. Vá para casa descansar por hoje."
							if GameState.get_switch("004_Ovos_e_derrotou") else
							"Você recolheu os ovos e conseguiu escapar da clareira a tempo. Já é fim de tarde, Huwag — vá para casa descansar."
						)
						request_dialogue.emit([{"speaker": "Capitão Reyes", "text": msg}], Callable())
					else:
						request_dialogue.emit([{"speaker": "Capitão Reyes", "text": "Seu turno já terminou por hoje, anak. Vá descansar em casa."}], Callable())
				elif not GameState.get_switch("002_Chefe_Ato1_apresentado"):
					GameState.set_switch("002_Chefe_Ato1_apresentado", true)
					request_dialogue.emit([
						{
							"speaker": "Capitão Reyes",
							"text": "Huwag, precisamos conversar sobre ontem... Você estava distraído durante o chamado. Está tomando a medicação corretamente? Eu me preocupo com você, anak."
						},
						{
							"speaker": "Capitão Reyes",
							"text": "Hoje temos uma ocorrência estranha perto da trilha leste, na clareira da floresta. Vá verificar a área e traga o que encontrar."
						}
					], Callable())
				else:
					request_dialogue.emit([
						{
							"speaker": "Huwag",
							"text": "(O Capitão Reyes está concentrado nos relatórios do rádio. Preciso seguir pela saída leste da cidade até a floresta.)"
						}
					], Callable())
			elif ato == 2:
				if not GameState.get_switch("007_Chefe_Ato2_apresentado"):
					GameState.set_switch("007_Chefe_Ato2_apresentado", true)
					request_dialogue.emit([
						{
							"speaker": "Capitão Reyes",
							"text": "Bom dia, Huwag. Três pessoas na rua (Kuya Ben no Jeepney, Aling Nena na Sari-Sari e o feirante ao lado do quartel) pediram apoio. Ajude pelo menos uma delas e tenho uma recompensa para você."
						}
					], Callable())
				elif GameState.get_switch("020_Alguma_missao_completa") and not GameState.get_switch("021_Recompensa_entregue"):
					GameState.set_switch("021_Recompensa_entregue", true)
					GameState.add_item("gota_calmante", 1)
					request_dialogue.emit([
						{
							"speaker": "Capitão Reyes",
							"text": "Bom trabalho apoiando a vizinhança, Huwag. Aqui está o suprimento prometido para o seu turno (+1 Cápsula Calmante).\nAgora fale com a senhora que está aguardando no banco da sala de espera — é urgente."
						}
					], Callable())
				elif GameState.get_switch("019_Ato2_concluido"):
					request_dialogue.emit([
						{
							"speaker": "Capitão Reyes",
							"text": "Você conteve as chamas na trilha e trouxe o animal da senhora em segurança. Pode encerrar o expediente e ir dormir em casa quando quiser."
						}
					], Callable())
				else:
					request_dialogue.emit([
						{
							"speaker": "Capitão Reyes",
							"text": "Atenda aos moradores na rua e depois verifique a senhora na sala de espera, Huwag."
						}
					], Callable())
			else:
				GameState.set_switch("024_Ato3_revelacao_reyes", true)
				request_dialogue.emit([
					{
						"speaker": "Capitão Reyes",
						"text": "Huwag... Eu vi no seu rosto quando você entrou. Os comprimidos acabaram, não foi?"
					},
					{
						"speaker": "Capitão Reyes",
						"text": "Desde aquela noite no galpão, quando o teto desabou e perdemos o pelotão... você nunca mais dormiu em paz. Os calmantes foram receitados para amortecer o choque, mas eu vi quando o mundo de mentira tomou conta da sua cabeça."
					},
					{
						"speaker": "Capitão Reyes",
						"text": "Você passou a enxergar criaturas na água e fagulhas místicas na mata para tentar dar um sentido a uma tragédia terrível. Mas você sobreviveu, Huwag. Sobreviver não é culpa."
					},
					{
						"speaker": "Huwag Matitiis",
						"expression": "unfiltered",
						"text": "Capitão... Eu achei que se eu continuasse apagando as chamas, de alguma forma eu salvaria todo mundo que ficou para trás..."
					},
					{
						"speaker": "Capitão Reyes",
						"text": "Você é o melhor bombeiro deste quartel, anak. Mas para continuar protegendo Agdangan, você precisa aceitar que você também está vivo. Vá até a clareira uma última vez, em paz consigo mesmo."
					}
				], Callable())

		"Velhinha_Espera":
			if ato < 2:
				request_dialogue.emit([
					{
						"speaker": "Huwag",
						"text": "O banco de madeira da sala de espera está vazio agora pela manhã."
					}
				], Callable())
			elif ato == 2:
				if GameState.get_switch("018_Gatinho_devolvido"):
					request_dialogue.emit([
						{
							"speaker": "Senhora Luningning",
							"text": "Salamat po, Huwag! Meu gatinho está seguro no meu colo graças a você. Vá descansar em paz, meu filho."
						}
					], Callable())
				elif GameState.get_switch("017_Gatinho_encontrado"):
					GameState.set_switch("018_Gatinho_devolvido", true)
					GameState.set_switch("019_Ato2_concluido", true)
					request_dialogue.emit([
						{
							"speaker": "Senhora Luningning",
							"text": "Meu gatinho! Você o tirou do meio daquela fumaça na clareira!\nMuito obrigada, Huwag! Agora você já pode encerrar seu turno e voltar para casa descansar."
						}
					], Callable())
				elif GameState.get_switch("020_Alguma_missao_completa"):
					GameState.set_switch("014_Floresta_liberada", true)
					request_dialogue.emit([
						{
							"speaker": "Senhora Luningning",
							"text": "Por favor, bombeiro Huwag! Começou um incêndio na mata ao leste e meu gatinho correu assustado para a clareira!\nA saída da floresta já está aberta — use sua água para apagar o fogo e salvá-lo!"
						}
					], Callable())
				else:
					request_dialogue.emit([
						{
							"speaker": "Senhora Luningning",
							"text": "Estou aguardando o Capitão registrar minha ocorrência... Parece que há fumaça subindo lá para os lados da floresta."
						}
					], Callable())
			else:
				request_dialogue.emit([
					{
						"speaker": "Huwag",
						"text": "O banco de madeira da sala de espera está vazio e marcado de fuligem."
					}
				], Callable())

		"Bombeiro_Ato":
			request_dialogue.emit([
				{
					"speaker": "Ato",
					"text": "Ei, pare! O que você está fazendo? Você não pode simplesmente... isso não é certo! Vou chamar o capitão!"
				}
			], Callable())

		"Bombeiro_Santos":
			request_dialogue.emit([
				{
					"speaker": "Santos",
					"text": "Bro, você parece cansado hoje. Quer jogar baralho depois do turno?"
				}
			], Callable())

		"Enfermeira_Maria":
			request_dialogue.emit([
				{
					"speaker": "Enfermeira Maria",
					"text": "Huwag, vim fazer seu check-up semanal. Você está sentindo algum efeito colateral? A insônia? As visões?"
				}
			], Callable())

		"Cilindros_Parede":
			request_dialogue.emit([
				{
					"speaker": "Huwag",
					"text": "Três cilindros vermelhos de extintor alinhados junto à parede azul do quartel. Sempre três, em fila."
				}
			], Callable())

		"Porta_Saida_Quartel":
			if ato == 1 and not GameState.get_switch("002_Chefe_Ato1_apresentado"):
				GameState.set_switch("001_Porta_Bombeiros_1a_vez", true)
				request_dialogue.emit([
					{
						"speaker": "Huwag",
						"text": "Acabei de chegar ao quartel. Não posso sair antes de me apresentar ao Capitão Reyes."
					}
				], Callable())
			else:
				request_dialogue.emit([
					{
						"speaker": "Huwag",
						"text": "Sair do quartel para a cidade?",
						"choices": ["Sair para a cidade", "Ficar no quartel"]
					}
				], func(choice: int) -> void:
					if choice == 0:
						request_level_change.emit("res://scenes/levels/StreetPreview.tscn", "from_station")
				)

func _draw() -> void:
	var act3 := GameState.is_unfiltered_act3()
	var ato: int = int(GameState.get_var("Ato", 1))
	var mod := Color(0.72, 0.74, 0.78, 1.0) if act3 else Color.WHITE

	draw_rect(Rect2(-500, -500, 1600, 1200), Color("#0B0C12"))
	draw_rect(Rect2(74, 18, 492, 322), Color(0, 0, 0, 0.55))
	draw_rect(Rect2(80, 22, 480, 312), Color("#262235") if not act3 else Color("#24262B"))
	draw_rect(Rect2(80, 22, 480, 312), Color("#14121D"), false, 2.0)

	# 1. Piso ladrilhado do quartel usando TopDownHouse_FloorsAndWalls.png e Interior_Walls_01.png
	if _tex_floors_walls != null:
		for y in range(74, 324, 48):
			var th := mini(48, 324 - y)
			for x in range(96, 544, 60):
				var tw := mini(60, 544 - x)
				draw_texture_rect_region(_tex_floors_walls, Rect2(x, y, tw, th), Rect2(82, 80, tw, th), Color(0.84, 0.88, 0.96, 1.0) * mod)
	else:
		draw_rect(Rect2(96, 74, 448, 250), Color("#98A4B3") if not act3 else Color("#55585C"))

	# Tapete institucional na recepção e na entrada
	if _tex_furniture != null:
		draw_texture_rect_region(_tex_furniture, Rect2(262, 118, 116, 48), Rect2(160, 16, 48, 32), mod)

	# 2. Parede Norte do Quartel BFP (painéis de madeira/alvenaria dos tilesets + faixa institucional azul)
	draw_rect(Rect2(96, 32, 448, 42), Color("#345C8A") if not act3 else Color("#464E57"))
	if _tex_floors_walls != null:
		for wx in range(96, 544, 64):
			var ww := mini(64, 544 - wx)
			draw_texture_rect_region(_tex_floors_walls, Rect2(wx, 32, ww, 42), Rect2(144, 18, ww, 42), Color(0.68, 0.82, 0.98, 0.55) * mod)
	draw_rect(Rect2(96, 68, 448, 6), Color("#1D3557") if not act3 else Color("#2F343A"))
	draw_rect(Rect2(96, 74, 448, 8), Color(0, 0, 0, 0.28))

	# Janelas e armários de equipamentos na parede norte
	if _tex_crawler_props != null:
		draw_texture_rect_region(_tex_crawler_props, Rect2(220, 34, 34, 36), Rect2(64, 176, 28, 40), mod)
		draw_texture_rect_region(_tex_crawler_props, Rect2(386, 34, 34, 36), Rect2(64, 176, 28, 40), mod)
	if _tex_furniture != null:
		# Armários de prontidão e arquivo na parede norte-leste
		draw_texture_rect_region(_tex_furniture, Rect2(448, 36, 46, 45), Rect2(33, 64, 46, 47), mod)
		draw_texture_rect_region(_tex_furniture, Rect2(496, 36, 42, 45), Rect2(97, 66, 46, 45), mod)

	# 3. Três cilindros vermelhos de combate a incêndio junto à parede
	for i in range(3):
		draw_rect(Rect2(149 + i * 12, 51, 8, 20), Color(0, 0, 0, 0.30))
		draw_rect(Rect2(148 + i * 12, 49, 8, 20), Color("#E63946") if not act3 else Color("#6E3835"))
		draw_rect(Rect2(149 + i * 12, 46, 6, 3), Color("#2B2D42"))
		draw_rect(Rect2(148 + i * 12, 49, 8, 20), Color("#141118"), false, 1.0)

	# 4. Capitão Reyes atrás do balcão de comando + Mesa de comando do tileset
	_draw_station_npc(Vector2(320, 84), _tex_npc_bob, Color("#98C1D9"), true)
	draw_rect(Rect2(268, 88, 104, 34), Color(0, 0, 0, 0.32))
	if _tex_crawler_props != null:
		draw_texture_rect_region(_tex_crawler_props, Rect2(268, 84, 104, 34), Rect2(0, 0, 64, 26), mod)
	else:
		draw_rect(Rect2(268, 86, 104, 32), Color("#8D5B4C"))
	if _tex_small_items != null:
		# Rádio comunicador e relatórios sobre a mesa do Capitão Reyes
		draw_texture_rect_region(_tex_small_items, Rect2(342, 86, 16, 15), Rect2(98, 51, 13, 12), mod)
		draw_texture_rect_region(_tex_small_items, Rect2(282, 90, 16, 12), Rect2(36, 22, 9, 9), mod)

	# 5. Equipe do Quartel (Bombeiro Ato, Bombeiro Santos, Enfermeira Maria) com sprites pixel-art
	_draw_station_npc(Vector2(416, 152), _tex_npc_adam, Color("#F5CB5C"), false)
	_draw_station_npc(Vector2(204, 184), _tex_npc_alex, Color("#F5CB5C"), false)
	_draw_station_npc(Vector2(468, 224), _tex_npc_amelia, Color("#E0FBFC"), false)

	# 6. Banco de madeira da sala de espera + Senhora Luningning no Ato 2
	draw_rect(Rect2(116, 216, 84, 28), Color(0, 0, 0, 0.30))
	if _tex_crawler_props != null:
		draw_texture_rect_region(_tex_crawler_props, Rect2(116, 210, 84, 30), Rect2(128, 295, 48, 21), mod)
	else:
		draw_rect(Rect2(116, 212, 84, 28), Color("#6C4632"))
	if ato == 2:
		_draw_station_npc(Vector2(158, 218), _tex_npc_amelia, Color("#D8B4E2"), false)
		if GameState.get_switch("018_Gatinho_devolvido"):
			draw_rect(Rect2(165, 210, 8, 6), Color("#F77F00"))
			draw_rect(Rect2(165, 210, 8, 6), Color("#141118"), false, 1.0)

	# 7. Porta sul de saída do quartel
	draw_rect(Rect2(296, 316, 48, 10), Color("#A46843"))
	draw_rect(Rect2(294, 316, 52, 10), Color("#1B192E"), false, 2.0)

func _draw_station_npc(pos: Vector2, sheet_tex: Texture2D, tint_col: Color, has_cap: bool) -> void:
	var act3 := GameState.is_unfiltered_act3()
	draw_circle(pos + Vector2(0, 2), 8.0, Color(0, 0, 0, 0.34))
	if sheet_tex != null:
		var mod := Color(0.75, 0.76, 0.80, 1.0) if act3 else tint_col.lerp(Color.WHITE, 0.55)
		# Quadro frontal parado (x=48, y=0, w=16, h=32) escalado para 24x40 compatível com o mundo 32x32
		draw_texture_rect_region(sheet_tex, Rect2(pos.x - 12, pos.y - 36, 24, 40), Rect2(48, 0, 16, 32), mod)
		if has_cap:
			draw_rect(Rect2(pos.x - 7, pos.y - 34, 14, 4), Color("#1D3557"))
			draw_rect(Rect2(pos.x - 4, pos.y - 31, 8, 2), Color("#F5CB5C"))
		return
	var outline := Color("#141118")
	draw_rect(Rect2(pos.x - 7, pos.y - 16, 14, 12), outline)
	draw_rect(Rect2(pos.x - 6, pos.y - 15, 12, 10), tint_col)
