extends Node2D

signal request_level_change(target_scene: String, spawn_tag: String)
signal request_dialogue(pages: Array, callback: Callable)

@onready var player: PlayerController = $Player
@onready var interactables_root: Node2D = $Interactables

var _tex_grass_tiles: Texture2D = null
var _tex_plants: Texture2D = null
var _tex_props: Texture2D = null
var _tex_serene: Texture2D = null
var _tex_floors: Texture2D = null
var _tex_npc_bob: Texture2D = null
var _tex_npc_amelia: Texture2D = null
var _tex_npc_adam: Texture2D = null

func _ready() -> void:
	_tex_grass_tiles = load("res://assets/third_party/Pixel Art Top Down - Basic v1.2.3/Texture/TX Tileset Grass.png") as Texture2D
	_tex_plants = load("res://assets/third_party/Pixel Art Top Down - Basic v1.2.3/Texture/TX Plant.png") as Texture2D
	_tex_props = load("res://assets/third_party/Pixel Art Top Down - Basic v1.2.3/Texture/TX Props.png") as Texture2D
	_tex_serene = load("res://assets/third_party/Serene_Village_revamped_v1.9/SERENE_VILLAGE_REVAMPED/Serene_Village_16x16.png") as Texture2D
	_tex_floors = load("res://assets/third_party/Pixel Crawler - Free Pack (Exterior 0.1)/Pixel Crawler - Free Pack/Environment/Tilesets/Floors_Tiles.png") as Texture2D
	_tex_npc_bob = load("res://assets/third_party/Modern_Interiors_Free_v2.2/Modern tiles_Free/Characters_free/Bob_16x16.png") as Texture2D
	_tex_npc_amelia = load("res://assets/third_party/Modern_Interiors_Free_v2.2/Modern tiles_Free/Characters_free/Amelia_16x16.png") as Texture2D
	_tex_npc_adam = load("res://assets/third_party/Modern_Interiors_Free_v2.2/Modern tiles_Free/Characters_free/Adam_16x16.png") as Texture2D

	match GameState.spawn_tag:
		"from_room":
			player.position = Vector2(148, 178)
			player.facing_dir = Vector2.DOWN
		"from_station":
			player.position = Vector2(548, 178)
			player.facing_dir = Vector2.DOWN
		"from_forest":
			player.position = Vector2(676, 224)
			player.facing_dir = Vector2.LEFT
		_:
			player.position = Vector2(148, 178)
			player.facing_dir = Vector2.DOWN

	player.set_camera_limits(Rect2i(0, 0, 760, 360))
	_setup_collisions()
	_setup_interactables()
	GameState.time_of_day_changed.connect(func(_v: bool) -> void: queue_redraw())
	GameState.switch_changed.connect(func(_k: String, _v: bool) -> void: queue_redraw())

func _setup_collisions() -> void:
	var body := StaticBody2D.new()
	body.name = "CityCollisions"
	body.collision_layer = 1
	add_child(body)

	var obstacles: Array[Rect2] = [
		Rect2(0, 0, 760, 72),
		Rect2(0, 344, 760, 24),
		Rect2(0, 0, 24, 360),
		Rect2(736, 0, 24, 360),
		Rect2(76, 72, 136, 82),    # Quitinete de Huwag
		Rect2(256, 76, 112, 76),   # Sari-Sari Store (Aling Nena / chave2)
		Rect2(400, 82, 84, 68),    # Feirinha ao lado do quartel (chave3)
		Rect2(496, 68, 144, 86),   # Quartel dos Bombeiros de Agdangan
		Rect2(216, 198, 92, 42),   # Jeepney do Kuya Ben (chave1)
	]
	for r in obstacles:
		var shape_node := CollisionShape2D.new()
		var rect_shape := RectangleShape2D.new()
		rect_shape.size = r.size
		shape_node.shape = rect_shape
		shape_node.position = r.position + r.size * 0.5
		body.add_child(shape_node)

func _setup_interactables() -> void:
	_add_interactable("Voltar_Apartamento", "Quitinete de Huwag", "Entrar", Vector2(148, 158), Vector2(36, 24))
	_add_interactable("Vendedora_Sari_Sari", "Aling Nena (Sari-Sari)", "Conversar", Vector2(312, 160), Vector2(44, 28))
	_add_interactable("Feirinha_Banca", "Feirinha do Barangay", "Interagir", Vector2(442, 156), Vector2(48, 26))
	_add_interactable("Jeepney_Veiculo", "Jeepney", "Examinar", Vector2(262, 220), Vector2(96, 48))
	_add_interactable("Motorista_Jeepney", "Kuya Ben", "Conversar", Vector2(324, 224), Vector2(32, 32))
	_add_interactable("Vizinha_Velha", "Lola Rosa", "Conversar", Vector2(136, 268), Vector2(32, 32))
	_add_interactable("Crianca_Jogando", "Toby", "Conversar", Vector2(446, 272), Vector2(32, 32))
	_add_interactable("Entrada_Quartel", "Quartel dos Bombeiros", "Entrar", Vector2(548, 158), Vector2(42, 24))
	_add_interactable("Bloqueio_Floresta", "Estrada para a Floresta", "Seguir", Vector2(708, 224), Vector2(44, 80))

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
	var afternoon := GameState.is_afternoon
	var act3 := GameState.is_unfiltered_act3()

	match id:
		"Voltar_Apartamento":
			request_level_change.emit("res://scenes/levels/RoomHuwag.tscn", "from_street")

		"Entrada_Quartel":
			request_level_change.emit("res://scenes/levels/FireStation.tscn", "from_street")

		"Vendedora_Sari_Sari":
			# No Ato 2 com 007 ligado, Aling Nena é a missão opcional chave2 (010 / 011)
			if ato == 2 and GameState.get_switch("007_Chefe_Ato2_apresentado"):
				if not GameState.get_switch("010_Missao_chave2_aberta"):
					GameState.set_switch("010_Missao_chave2_aberta", true)
					request_dialogue.emit([{
						"speaker": "Aling Nena (Missão Chave 2)",
						"text": "Huwag, ainda bem que veio! Preciso avisar a Lola Rosa que os mantimentos dela chegaram, mas não posso deixar o balcão sozinho. Fale comigo de novo após avisá-la (ou confirme aqui para levar o pacote)!"
					}], Callable())
					return
				elif not GameState.get_switch("011_Missao_chave2_concluida"):
					GameState.complete_optional_mission("011_Missao_chave2_concluida")
					request_dialogue.emit([{
						"speaker": "Aling Nena (Missão Chave 2)",
						"text": "Salamat, Huwag! Entregou o pacote e o recado direitinho. O Capitão Reyes pediu para você passar no quartel quando terminasse um apoio!"
					}], Callable())
					return

			if act3:
				request_dialogue.emit([{
					"speaker": "Aling Nena",
					"text": "As grades enferrujadas da sari-sari estão meio fechadas. Aling Nena conta moedas em silêncio sob uma lâmpada fraca."
				}], Callable())
			elif afternoon and ato == 1:
				request_dialogue.emit([{
					"speaker": "Huwag",
					"text": "A grade da sari-sari store da Aling Nena está abaixada agora no fim da tarde."
				}], Callable())
			else:
				request_dialogue.emit([{
					"speaker": "Aling Nena",
					"text": "Magandang umaga, Huwag! Indo trabalhar tão cedo?\nTenho pão pandesal fresquinho e café solúvel se quiser. Se cuide lá no corpo de bombeiros, viu? O barangay precisa de rapazes dedicados como você."
				}], Callable())

		"Feirinha_Banca":
			# No Ato 2 com 007 ligado, a Feirinha é a missão opcional chave3 (012 / 013)
			if ato == 2 and GameState.get_switch("007_Chefe_Ato2_apresentado"):
				if not GameState.get_switch("012_Missao_chave3_aberta"):
					GameState.set_switch("012_Missao_chave3_aberta", true)
					request_dialogue.emit([{
						"speaker": "Feirante (Missão Chave 3)",
						"text": "Bombeiro Huwag! O vento soltou a lona da barraca e espalhou os caixotes ao lado do quartel. Pode me ajudar a prender as cordas? Interaja novamente para amarrar tudo!"
					}], Callable())
					return
				elif not GameState.get_switch("013_Missao_chave3_concluida"):
					GameState.complete_optional_mission("013_Missao_chave3_concluida")
					request_dialogue.emit([{
						"speaker": "Feirante (Missão Chave 3)",
						"text": "Pronto, a lona e os caixotes estão firmes! Muito obrigado pela força, Huwag!"
					}], Callable())
					return

			request_dialogue.emit([{
				"speaker": "Huwag",
				"text": "A pequena feirinha ao lado do corpo de bombeiros. Caixotes de frutas, peixe seco e lonas esticadas."
			}], Callable())

		"Jeepney_Veiculo":
			request_dialogue.emit([{
				"speaker": "Huwag",
				"text": "O Jeepney colorido do Kuya Ben.\nPinturas religiosas e frases populares decoram a lataria. O motor a diesel solta um cheiro característico de fumaça."
			}], Callable())

		"Motorista_Jeepney":
			# No Ato 2 com 007 ligado, Kuya Ben é a missão opcional chave1 (008 / 009)
			if ato == 2 and GameState.get_switch("007_Chefe_Ato2_apresentado"):
				if not GameState.get_switch("008_Missao_chave1_aberta"):
					GameState.set_switch("008_Missao_chave1_aberta", true)
					request_dialogue.emit([{
						"speaker": "Kuya Ben (Missão Chave 1)",
						"text": "Huwag! A mangueira do radiador do Jeepney soltou e minha chave inglesa caiu aqui perto. Pode pegar e me entregar? Fale comigo em seguida!"
					}], Callable())
					return
				elif not GameState.get_switch("009_Missao_chave1_concluida"):
					GameState.complete_optional_mission("009_Missao_chave1_concluida")
					request_dialogue.emit([{
						"speaker": "Kuya Ben (Missão Chave 1)",
						"text": "Achou a chave! Agora consigo apertar a braçadeira e seguir viagem. Valeu mesmo, Huwag! O Capitão Reyes estava perguntando por você no quartel."
					}], Callable())
					return

			if act3:
				request_dialogue.emit([{
					"speaker": "Kuya Ben",
					"text": "A pintura do Jeepney está descascada e coberta de poeira da estrada. Kuya Ben limpa o para-brisa com um pano escuro."
				}], Callable())
			elif afternoon and ato == 1:
				request_dialogue.emit([{
					"speaker": "Kuya Ben",
					"text": "Já fazendo a última viagem do dia, Huwag! Vá descansar logo, rapaz."
				}], Callable())
			else:
				request_dialogue.emit([{
					"speaker": "Kuya Ben",
					"text": "Mabuhay, Huwag! O Jeepney tá quase cheio, saio em dez minutos para o centro da cidade!\nVai direto pro quartel hoje? O trânsito na avenida tá uma loucura, melhor ir a pé mesmo!"
				}], Callable())

		"Vizinha_Velha":
			if ato == 2 and GameState.get_switch("010_Missao_chave2_aberta") and not GameState.get_switch("011_Missao_chave2_concluida"):
				GameState.complete_optional_mission("011_Missao_chave2_concluida")
				request_dialogue.emit([{
					"speaker": "Lola Rosa",
					"text": "O recado da Aling Nena? Muito obrigada por me avisar, meu filho. Volte lá ou passe no quartel, viu?"
				}], Callable())
				return

			if afternoon and ato == 1:
				request_dialogue.emit([{
					"speaker": "Huwag",
					"text": "Lola Rosa já recolheu sua cadeira da calçada por hoje."
				}], Callable())
			else:
				request_dialogue.emit([{
					"speaker": "Lola Rosa",
					"text": "Huwag, anak... Que bom te ver de pé.\nVocê parece tão pálido ultimamente. Está comendo direito? Não guarde todo o peso do mundo nas suas costas, meu filho. Deus olha por aqueles que apagam o fogo dos outros."
				}], Callable())

		"Crianca_Jogando":
			if afternoon and ato == 1:
				request_dialogue.emit([{
					"speaker": "Huwag",
					"text": "Toby já foi chamado para dentro de casa. Só restou um risco de giz no concreto."
				}], Callable())
			else:
				request_dialogue.emit([
					{
						"speaker": "Toby",
						"text": "Kuya Huwag! Olha só o meu caminhão de bombeiro de lata!\nQuando eu crescer, quero ser corajoso igualzinho a você!"
					},
					{
						"speaker": "Huwag",
						"text": "(Um sorriso forçado escapa... Se ele soubesse o vazio que existe por trás deste uniforme...)"
					}
				], Callable())

		"Bloqueio_Floresta":
			if ato == 1:
				if not GameState.get_switch("002_Chefe_Ato1_apresentado"):
					request_dialogue.emit([{
						"speaker": "Huwag",
						"text": "Esta estrada leva para a saída da cidade e a floresta.\nPreciso primeiro me apresentar ao Capitão Reyes no quartel."
					}], Callable())
				else:
					request_level_change.emit("res://scenes/levels/ForestCorridor.tscn", "from_city")
			elif ato == 2:
				if not GameState.get_switch("014_Floresta_liberada"):
					request_dialogue.emit([{
						"speaker": "Huwag",
						"text": "A trilha da floresta está fechada. Preciso falar com o Capitão Reyes, ajudar um morador na cidade e verificar a sala de espera do quartel."
					}], Callable())
				else:
					request_level_change.emit("res://scenes/levels/ForestCorridor.tscn", "from_city")
			else:
				request_level_change.emit("res://scenes/levels/ForestCorridor.tscn", "from_city")

func _draw() -> void:
	var act3 := GameState.is_unfiltered_act3()
	var afternoon := GameState.is_afternoon
	var ato: int = int(GameState.get_var("Ato", 1))

	# 1. Céu / Horizonte Norte com a silhueta do Luminous Cross of Grace Sanctuary e vegetação tropical
	var sky_col := Color("#1B1926") if afternoon and not act3 else (Color("#2D3A4A") if not act3 else Color("#2A2D32"))
	draw_rect(Rect2(-200, -100, 1200, 180), sky_col)
	# Brilho cálido no horizonte
	if not act3:
		draw_rect(Rect2(-200, 22, 1200, 34), Color(0.95, 0.58, 0.24, 0.22 if afternoon else 0.35))
	draw_rect(Rect2(0, 44, 760, 32), Color("#1E3B2B") if not act3 else Color("#292D2C"))

	# Silhueta do Santuário ao fundo (Luminous Cross of Grace Sanctuary)
	var tower_x: float = 382.0
	draw_rect(Rect2(tower_x - 8, 12, 16, 52), Color("#E8D8B8") if not act3 else Color("#5C6066"))
	draw_circle(Vector2(tower_x, 26), 11.0, Color("#F7B801") if not act3 else Color("#4C5054"))
	draw_circle(Vector2(tower_x, 26), 6.0, Color("#FFF5D6") if not act3 else Color("#6A6E72"))
	draw_line(Vector2(tower_x, 1), Vector2(tower_x, 13), Color("#FFE66D") if not act3 else Color("#7D8287"), 2.0)
	draw_line(Vector2(tower_x - 4, 5), Vector2(tower_x + 4, 5), Color("#FFE66D") if not act3 else Color("#7D8287"), 2.0)

	# 2. Solo e Estrada de Terra de Agdangan (coeso, sem trincheira ou passarelas flutuantes gigantes)
	var earth_col := Color("#4A3528") if not act3 else Color("#383634")
	var road_col := Color("#3A2B22") if not act3 else Color("#2B2C2E")
	var road_dust := Color("#4E3A2E") if not act3 else Color("#343538")
	var grass_edge := Color("#233D27") if not act3 else Color("#272B28")

	# Base de terra natural do terreno
	draw_rect(Rect2(0, 72, 760, 288), earth_col)

	# Grama tropical ao fundo e nas bordas
	if _tex_grass_tiles != null:
		var g_mod := Color(0.55, 0.56, 0.54, 0.65) if act3 else Color(0.72, 0.70, 0.58, 0.70)
		for gy in range(72, 170, 128):
			for gx in range(0, 760, 128):
				draw_texture_rect_region(_tex_grass_tiles, Rect2(gx, gy, 128, 98), Rect2(0, 0, 128, 98), g_mod)
		# Faixa de grama ao sul (ombro da rua)
		for gx in range(0, 760, 128):
			draw_texture_rect_region(_tex_grass_tiles, Rect2(gx, 320, 128, 40), Rect2(0, 0, 128, 40), g_mod)

	# Leito contínuo da estrada de terra batida (estende-se de y=168 a y=334)
	draw_rect(Rect2(0, 168, 760, 160), road_col)
	if _tex_floors != null:
		var r_mod := Color(0.52, 0.52, 0.54, 0.50) if act3 else Color(0.78, 0.68, 0.56, 0.55)
		for rx in range(0, 760, 96):
			var rw := mini(96, 760 - rx)
			draw_texture_rect_region(_tex_floors, Rect2(rx, 172, rw, 150), Rect2(256, 16, rw, 80), r_mod)

	# Marcas de rodagem de pneus e sulcos de terra da rua filipina
	for ry in [198, 226, 258, 292]:
		draw_line(Vector2(0, ry), Vector2(760, ry), Color(0.08, 0.06, 0.05, 0.28), 1.5)
		draw_line(Vector2(0, ry + 1), Vector2(760, ry + 1), road_dust, 1.0)

	# Pequenas pedras e cascalho espalhados na estrada de terra
	var gravel_pts := [
		Vector2(92, 210), Vector2(174, 245), Vector2(285, 280), Vector2(360, 195),
		Vector2(420, 240), Vector2(510, 215), Vector2(612, 268), Vector2(680, 225),
		Vector2(145, 305), Vector2(230, 185), Vector2(395, 310), Vector2(570, 295)
	]
	for gp in gravel_pts:
		draw_circle(gp, 1.8, Color("#261B13") if not act3 else Color("#1E1E20"))
		draw_circle(gp + Vector2(-0.5, -0.5), 1.2, Color("#6B523F") if not act3 else Color("#454341"))

	# Varanda elevada contínua de madeira em frente às casas e ao quartel (calçada norte)
	_draw_wooden_boardwalk(Rect2(56, 146, 616, 26), act3)

	# Degraus de acesso de madeira da varanda para a estrada de terra
	_draw_wood_steps(Vector2(136, 172), 26.0, act3) # Casa de Huwag
	_draw_wood_steps(Vector2(296, 172), 34.0, act3) # Sari-Sari Store
	_draw_wood_steps(Vector2(424, 172), 30.0, act3) # Feirinha
	_draw_wood_steps(Vector2(534, 172), 32.0, act3) # Quartel dos Bombeiros

	# Cercas rústicas baixas de madeira no ombro sul da estrada, integradas à vegetação
	_draw_wood_fence(Vector2(32, 332), 160.0, act3)
	_draw_wood_fence(Vector2(460, 332), 230.0, act3)

	# Banquinho e vaso da Lola Rosa no ombro da rua
	_draw_lola_rosa_spot(Vector2(136, 274), act3)

	# 3. Vegetação Tropical de Agdangan (Bananeiras e Coqueiros ao fundo das construções)
	_draw_banana_cluster(Vector2(48, 128), act3, 0.95)
	_draw_banana_cluster(Vector2(228, 132), act3, 0.9)
	_draw_banana_cluster(Vector2(384, 134), act3, 0.85)
	_draw_banana_cluster(Vector2(662, 132), act3, 1.0)

	# 4. Quitinete de Huwag (Casa de Madeira e Bambu com Varanda e Lanterna)
	_draw_huwag_house(Rect2(76, 68, 136, 86), act3)

	# 5. Sari-Sari Store da Aling Nena (Inspirada na Imagem 1: telhado de zinco, varanda de madeira, lanternas vermelhas, sachês pendurados)
	_draw_sari_sari_store(Rect2(256, 72, 112, 80), act3, afternoon and ato == 1)

	# 6. Feirinha do Barangay ao lado do Quartel
	_draw_market_stall(Rect2(400, 80, 84, 70), act3)

	# 7. Quartel dos Bombeiros de Agdangan (BFP Fire Station reconhecível e integrada à madeira/zinco local)
	_draw_fire_station_facade(Rect2(496, 62, 144, 92), act3)

	# 8. Iluminação Quente no Solo (Halos das lanternas, janelas e faróis antes dos veículos e NPCs)
	_draw_street_light_pools(act3, afternoon)

	# 9. Jeepney / Veículo Filipino do Kuya Ben (com faróis acesos e detalhes de madeira/metal)
	_draw_jeepney(Rect2(216, 196, 92, 44), act3)

	# 10. Postes de Madeira com Luminárias Quentes
	_draw_wood_lamp_post(Vector2(236, 148), act3)
	_draw_wood_lamp_post(Vector2(488, 148), act3)
	_draw_wood_lamp_post(Vector2(652, 148), act3)

	# 11. NPCs na rua (com arte top-down detalhada coerente com o sprite do Huwag)
	if not (afternoon and ato == 1):
		# Kuya Ben ao lado do Jeepney
		_draw_detailed_npc(Vector2(324, 224), Color("#C94A38"), Color("#2E3846"), Color("#1E1B24"), false, act3)
		# Lola Rosa na calçada sul
		_draw_detailed_npc(Vector2(136, 268), Color("#8352A8"), Color("#4A3B54"), Color("#D8D4D0"), true, act3)
		# Menino Toby brincando perto do caminhãozinho de lata
		_draw_detailed_npc(Vector2(446, 272), Color("#3B9E96"), Color("#384B6B"), Color("#1A181E"), false, act3, 0.80)
		# Caminhão de bombeiro de lata do Toby
		draw_rect(Rect2(426, 271, 13, 8), Color("#141118"))
		draw_rect(Rect2(427, 272, 11, 6), Color("#D62828") if not act3 else Color("#6E4848"))
		draw_rect(Rect2(434, 273, 3, 3), Color("#90E0EF"))
		draw_line(Vector2(428, 271), Vector2(435, 271), Color("#F2C14E"), 1.0)

	# 12. Palmeiras Tropicais no Primeiro Plano / Laterais (emoldurando a rua como na Imagem 1)
	_draw_palm_tree(Vector2(42, 162), act3, 1.0)
	_draw_palm_tree(Vector2(244, 156), act3, 0.88)
	_draw_palm_tree(Vector2(678, 164), act3, 1.05)
	_draw_banana_cluster(Vector2(692, 298), act3, 0.95)
	_draw_banana_cluster(Vector2(44, 306), act3, 0.90)

	# 13. Cavalete da floresta se ainda bloqueada
	var forest_blocked: bool = (ato == 1 and not GameState.get_switch("002_Chefe_Ato1_apresentado")) or (ato == 2 and not GameState.get_switch("014_Floresta_liberada"))
	if forest_blocked:
		draw_rect(Rect2(701, 194, 14, 58), Color("#141118"))
		draw_rect(Rect2(702, 196, 12, 54), Color("#E07A22"))
		draw_rect(Rect2(702, 210, 12, 8), Color("#F5EFE6"))
		draw_rect(Rect2(702, 228, 12, 8), Color("#F5EFE6"))

	# 14. Fiação elétrica aérea
	draw_line(Vector2(0, 56), Vector2(380, 64), Color(0.08, 0.08, 0.12, 0.65), 1.5)
	draw_line(Vector2(380, 64), Vector2(760, 54), Color(0.08, 0.08, 0.12, 0.65), 1.5)

func _draw_wooden_boardwalk(rect: Rect2, act3: bool) -> void:
	var base_wood := Color("#6E472B") if not act3 else Color("#4A443E")
	var plank_alt := Color("#7D5233") if not act3 else Color("#544E48")
	var border_col := Color("#2B1B12") if not act3 else Color("#242220")
	# Sombra projetada da passarela
	draw_rect(Rect2(rect.position.x + 2, rect.position.y + 3, rect.size.x, rect.size.y), Color(0, 0, 0, 0.35))
	draw_rect(rect, border_col)
	draw_rect(rect.grow(-2.0), base_wood)

	if rect.size.x > rect.size.y:
		var step: int = 14
		var count: int = int(rect.size.x / step)
		for i in range(count):
			var px: float = rect.position.x + 2 + i * step
			if i % 2 == 0:
				draw_rect(Rect2(px, rect.position.y + 2, step - 2, rect.size.y - 4), plank_alt)
			draw_line(Vector2(px, rect.position.y + 2), Vector2(px, rect.end.y - 2), border_col, 1.0)
			draw_rect(Rect2(px + 3, rect.position.y + 4, 2, 2), border_col)
			draw_rect(Rect2(px + 3, rect.end.y - 6, 2, 2), border_col)
	else:
		var step_y: int = 10
		var count_y: int = int(rect.size.y / step_y)
		for j in range(count_y):
			var py: float = rect.position.y + 2 + j * step_y
			if j % 2 == 0:
				draw_rect(Rect2(rect.position.x + 2, py, rect.size.x - 4, step_y - 2), plank_alt)
			draw_line(Vector2(rect.position.x + 2, py), Vector2(rect.end.x - 2, py), border_col, 1.0)

func _draw_wood_fence(start: Vector2, length: float, act3: bool) -> void:
	var post_col := Color("#543622") if not act3 else Color("#3E3A36")
	var rail_col := Color("#6E472B") if not act3 else Color("#4A4540")
	var outline := Color("#1E140E")
	draw_rect(Rect2(start.x, start.y - 8, length, 3), outline)
	draw_rect(Rect2(start.x, start.y - 7, length, 2), rail_col)
	draw_rect(Rect2(start.x, start.y - 3, length, 2), rail_col)
	var posts: int = int(length / 22.0)
	for i in range(posts + 1):
		var px: float = start.x + i * 22.0
		draw_rect(Rect2(px - 2, start.y - 12, 5, 14), outline)
		draw_rect(Rect2(px - 1, start.y - 11, 3, 12), post_col)

func _draw_wood_steps(pos: Vector2, width: float, act3: bool) -> void:
	var outline := Color("#161219")
	var step_wood := Color("#6E4527") if not act3 else Color("#45403B")
	var step_hi := Color("#875936") if not act3 else Color("#524B45")
	# Degrau 1
	draw_rect(Rect2(pos.x - 1, pos.y, width + 2, 5), outline)
	draw_rect(Rect2(pos.x, pos.y + 1, width, 3), step_wood)
	draw_line(Vector2(pos.x, pos.y + 1), Vector2(pos.x + width, pos.y + 1), step_hi, 1.0)
	# Degrau 2 (tocando a terra batida)
	draw_rect(Rect2(pos.x - 2, pos.y + 4, width + 4, 4), outline)
	draw_rect(Rect2(pos.x - 1, pos.y + 5, width + 2, 2), step_wood.darkened(0.12))

func _draw_lola_rosa_spot(pos: Vector2, act3: bool) -> void:
	var outline := Color("#161219")
	var wood := Color("#6B462C") if not act3 else Color("#45413C")
	# Banquinho de madeira rústica
	draw_rect(Rect2(pos.x - 10, pos.y - 12, 20, 8), outline)
	draw_rect(Rect2(pos.x - 9, pos.y - 11, 18, 6), wood)
	draw_rect(Rect2(pos.x - 8, pos.y - 4, 3, 6), outline)
	draw_rect(Rect2(pos.x + 5, pos.y - 4, 3, 6), outline)
	# Vaso de planta com flor branca (Sampaguita / Calamansi)
	draw_rect(Rect2(pos.x + 14, pos.y - 10, 10, 10), outline)
	draw_rect(Rect2(pos.x + 15, pos.y - 9, 8, 8), Color("#A05030") if not act3 else Color("#54403B"))
	draw_circle(Vector2(pos.x + 19, pos.y - 12), 4.5, Color("#265C30") if not act3 else Color("#39453C"))
	draw_circle(Vector2(pos.x + 18, pos.y - 14), 1.5, Color("#F5F0E6"))
	draw_circle(Vector2(pos.x + 21, pos.y - 12), 1.5, Color("#F5F0E6"))

func _draw_huwag_house(rect: Rect2, act3: bool) -> void:
	var outline := Color("#161219")
	var roof_col := Color("#5A6570") if not act3 else Color("#45484C")
	var rust_col := Color("#8C4A32") if not act3 else Color("#4E423E")
	var wall_col := Color("#8A5A36") if not act3 else Color("#575048")
	var plank_dark := Color("#6E4527") if not act3 else Color("#47413A")
	var win_glow := Color("#FFBE55") if not act3 else Color("#7A7E85")

	# Sombra no chão
	draw_rect(Rect2(rect.position.x + 4, rect.position.y + 6, rect.size.x, rect.size.y), Color(0, 0, 0, 0.38))
	draw_rect(rect, outline)
	# Parede de madeira e bambu
	draw_rect(Rect2(rect.position.x + 2, rect.position.y + 26, rect.size.x - 4, rect.size.y - 28), wall_col)
	for y in range(int(rect.position.y) + 32, int(rect.end.y) - 4, 8):
		draw_line(Vector2(rect.position.x + 2, y), Vector2(rect.end.x - 2, y), plank_dark, 1.0)

	# Telhado de zinco ondulado com manchas de ferrugem tropical
	draw_rect(Rect2(rect.position.x - 2, rect.position.y, rect.size.x + 4, 28), outline)
	draw_rect(Rect2(rect.position.x, rect.position.y + 2, rect.size.x, 24), roof_col)
	draw_rect(Rect2(rect.position.x + 14, rect.position.y + 6, 26, 10), rust_col)
	draw_rect(Rect2(rect.position.x + 88, rect.position.y + 12, 32, 8), rust_col)
	for rx in range(int(rect.position.x) + 4, int(rect.end.x) - 2, 6):
		draw_line(Vector2(rx, rect.position.y + 2), Vector2(rx, rect.position.y + 26), Color(0, 0, 0, 0.25), 1.0)

	# Janela iluminada com grade capiz
	var win_r := Rect2(rect.position.x + 18, rect.position.y + 40, 34, 26)
	draw_rect(win_r, outline)
	draw_rect(win_r.grow(-2.0), win_glow)
	draw_line(Vector2(win_r.position.x + 17, win_r.position.y + 2), Vector2(win_r.position.x + 17, win_r.end.y - 2), outline, 2.0)
	draw_line(Vector2(win_r.position.x + 2, win_r.position.y + 13), Vector2(win_r.end.x - 2, win_r.position.y + 13), outline, 2.0)

	# Porta de madeira e degraus da varanda (em x=148)
	var door_r := Rect2(132, rect.end.y - 40, 32, 38)
	draw_rect(door_r, outline)
	draw_rect(door_r.grow(-2.0), Color("#4E301D") if not act3 else Color("#3B3530"))
	draw_rect(Rect2(136, rect.end.y - 34, 24, 14), win_glow.darkened(0.15))
	# Degraus de madeira
	draw_rect(Rect2(128, rect.end.y - 2, 40, 8), outline)
	draw_rect(Rect2(130, rect.end.y, 36, 5), Color("#7D5233") if not act3 else Color("#4F4943"))

	# Barris de madeira ao lado da casa (como na Imagem 1)
	_draw_wood_barrel(Vector2(88, rect.end.y - 8), act3)
	_draw_wood_barrel(Vector2(104, rect.end.y - 6), act3)

	# Lanterna pendente na varanda
	_draw_hanging_lantern(Vector2(176, rect.position.y + 30), act3)

func _draw_sari_sari_store(rect: Rect2, act3: bool, closed_shutter: bool) -> void:
	var outline := Color("#161219")
	var roof_col := Color("#636E78") if not act3 else Color("#46494D")
	var rust_col := Color("#9E4730") if not act3 else Color("#52433F")
	var wood_wall := Color("#96613B") if not act3 else Color("#595149")
	var deck_col := Color("#85532F") if not act3 else Color("#4E4740")

	# Sombra e deck de madeira frontal
	draw_rect(Rect2(rect.position.x + 4, rect.position.y + 6, rect.size.x, rect.size.y + 6), Color(0, 0, 0, 0.38))
	draw_rect(rect, outline)
	draw_rect(rect.grow(-2.0), wood_wall)

	# Varanda de madeira na base da loja
	var porch_r := Rect2(rect.position.x - 4, rect.end.y - 14, rect.size.x + 8, 16)
	draw_rect(porch_r, outline)
	draw_rect(porch_r.grow(-2.0), deck_col)
	for px in range(int(porch_r.position.x) + 6, int(porch_r.end.x) - 4, 8):
		draw_line(Vector2(px, porch_r.position.y + 2), Vector2(px, porch_r.end.y - 2), outline, 1.0)

	# Telhado de zinco ondulado inclinado (fiel à loja da Imagem 1)
	var roof_r := Rect2(rect.position.x - 6, rect.position.y - 2, rect.size.x + 12, 26)
	draw_rect(roof_r, outline)
	draw_rect(roof_r.grow(-2.0), roof_col)
	draw_rect(Rect2(roof_r.position.x + 12, roof_r.position.y + 4, 34, 9), rust_col)
	draw_rect(Rect2(roof_r.position.x + 68, roof_r.position.y + 10, 28, 8), rust_col)
	for rx in range(int(roof_r.position.x) + 4, int(roof_r.end.x) - 2, 5):
		draw_line(Vector2(rx, roof_r.position.y + 2), Vector2(rx, roof_r.end.y - 2), Color(0, 0, 0, 0.28), 1.0)

	# Balcão aberto com luz quente interna e sachês coloridos pendurados (chichirya)
	var counter_r := Rect2(rect.position.x + 14, rect.position.y + 26, rect.size.x - 28, 30)
	draw_rect(counter_r, outline)
	if closed_shutter:
		draw_rect(counter_r.grow(-2.0), Color("#4A4E54"))
		for sy in range(int(counter_r.position.y) + 4, int(counter_r.end.y) - 2, 4):
			draw_line(Vector2(counter_r.position.x + 2, sy), Vector2(counter_r.end.x - 2, sy), outline, 1.0)
	else:
		draw_rect(counter_r.grow(-2.0), Color("#382214") if not act3 else Color("#2B2826"))
		draw_rect(Rect2(counter_r.position.x + 4, counter_r.position.y + 4, counter_r.size.x - 8, 18), Color("#FFB042") if not act3 else Color("#63605B"))
		# Aling Nena no balcão
		draw_circle(Vector2(312, counter_r.position.y + 16), 5.5, Color("#C68B59") if not act3 else Color("#8A827C"))
		draw_rect(Rect2(306, counter_r.position.y + 20, 12, 6), Color("#D6453A") if not act3 else Color("#5E5252"))
		# Tiras de sachês coloridos pendurados (como na Imagem 1)
		var pack_cols: Array[Color] = [Color("#E63946"), Color("#F7B801"), Color("#4ECDC4"), Color("#8AC926"), Color("#FF6B35"), Color("#F7B801")]
		for i in range(6):
			var sx: float = counter_r.position.x + 6 + i * 13.0
			var c: Color = pack_cols[i] if not act3 else Color("#66625E")
			draw_rect(Rect2(sx, counter_r.position.y + 2, 7, 15), outline)
			draw_rect(Rect2(sx + 1, counter_r.position.y + 3, 5, 5), c)
			draw_rect(Rect2(sx + 1, counter_r.position.y + 9, 5, 6), c.lightened(0.2))

	# Duas lanternas redondas vermelho-alaranjadas penduradas nas pontas do beiral (marca registrada da Imagem 1)
	_draw_hanging_lantern(Vector2(rect.position.x + 4, rect.position.y + 28), act3)
	_draw_hanging_lantern(Vector2(rect.end.x - 4, rect.position.y + 28), act3)

	# Mesinha e banquinho de madeira na varanda
	draw_rect(Rect2(rect.position.x + 6, rect.end.y - 16, 22, 12), outline)
	draw_rect(Rect2(rect.position.x + 7, rect.end.y - 15, 20, 10), Color("#A46843") if not act3 else Color("#5C534C"))

func _draw_market_stall(rect: Rect2, act3: bool) -> void:
	var outline := Color("#161219")
	draw_rect(Rect2(rect.position.x + 3, rect.position.y + 5, rect.size.x, rect.size.y), Color(0, 0, 0, 0.35))
	draw_rect(rect, outline)
	draw_rect(rect.grow(-2.0), Color("#6E472B") if not act3 else Color("#4A433C"))
	# Toldo listrado artesanal
	var canopy_r := Rect2(rect.position.x - 2, rect.position.y, rect.size.x + 4, 22)
	draw_rect(canopy_r, outline)
	for i in range(6):
		var stripe_c := (Color("#D95338") if i % 2 == 0 else Color("#E8B84B")) if not act3 else (Color("#544B48") if i % 2 == 0 else Color("#66615B"))
		draw_rect(Rect2(canopy_r.position.x + 2 + i * 14, canopy_r.position.y + 2, 14, 18), stripe_c)
	# Caixotes de frutas tropicais
	draw_rect(Rect2(rect.position.x + 8, rect.position.y + 32, rect.size.x - 16, 28), Color("#94603C") if not act3 else Color("#574E47"))
	draw_circle(Vector2(422, 126), 5.0, Color("#8AC926") if not act3 else Color("#61665C"))
	draw_circle(Vector2(442, 126), 5.0, Color("#FFCA3A") if not act3 else Color("#706B5E"))
	draw_circle(Vector2(462, 126), 5.0, Color("#FF595E") if not act3 else Color("#695858"))
	_draw_hanging_lantern(Vector2(rect.end.x - 6, rect.position.y + 26), act3)

func _draw_fire_station_facade(rect: Rect2, act3: bool) -> void:
	var outline := Color("#161219")
	var roof_col := Color("#A82424") if not act3 else Color("#523838")
	var wall_col := Color("#2F5C8F") if not act3 else Color("#434C56")
	var wood_trim := Color("#6E472B") if not act3 else Color("#47413B")
	var sign_col := Color("#F5CB5C") if not act3 else Color("#78725E")
	var win_glow := Color("#FFC864") if not act3 else Color("#747880")

	draw_rect(Rect2(rect.position.x + 4, rect.position.y + 6, rect.size.x, rect.size.y), Color(0, 0, 0, 0.4))
	draw_rect(rect, outline)
	draw_rect(Rect2(rect.position.x + 2, rect.position.y + 24, rect.size.x - 4, rect.size.y - 26), wall_col)
	# Base de madeira e pedra
	draw_rect(Rect2(rect.position.x + 2, rect.end.y - 18, rect.size.x - 4, 16), wood_trim)

	# Telhado metálico vermelho do Quartel BFP
	draw_rect(Rect2(rect.position.x - 4, rect.position.y, rect.size.x + 8, 24), outline)
	draw_rect(Rect2(rect.position.x - 2, rect.position.y + 2, rect.size.x + 4, 20), roof_col)
	for rx in range(int(rect.position.x), int(rect.end.x), 8):
		draw_line(Vector2(rx, rect.position.y + 2), Vector2(rx, rect.position.y + 22), Color(0, 0, 0, 0.25), 1.0)

	# Faixa de identificação BFP AGDANGAN e giroflex
	draw_rect(Rect2(rect.position.x + 14, rect.position.y + 28, rect.size.x - 28, 10), outline)
	draw_rect(Rect2(rect.position.x + 16, rect.position.y + 30, rect.size.x - 32, 6), sign_col)
	draw_circle(Vector2(rect.position.x + 72, rect.position.y + 12), 5.0, Color("#FF4D4D") if not act3 else Color("#6E4C4C"))

	# Portas duplas de madeira do quartel (em x=548) e janela iluminada da recepção
	var door_r := Rect2(528, rect.end.y - 42, 40, 40)
	draw_rect(door_r, outline)
	draw_rect(door_r.grow(-2.0), Color("#7A4A2E") if not act3 else Color("#4C433D"))
	draw_line(Vector2(548, door_r.position.y + 2), Vector2(548, door_r.end.y - 2), outline, 2.0)
	draw_rect(Rect2(533, door_r.position.y + 6, 11, 12), win_glow)
	draw_rect(Rect2(552, door_r.position.y + 6, 11, 12), win_glow)

	# Janela lateral do quartel
	var win_r := Rect2(582, rect.position.y + 46, 42, 26)
	draw_rect(win_r, outline)
	draw_rect(win_r.grow(-2.0), win_glow)
	draw_line(Vector2(win_r.position.x + 21, win_r.position.y + 2), Vector2(win_r.position.x + 21, win_r.end.y - 2), outline, 2.0)

func _draw_jeepney(rect: Rect2, act3: bool) -> void:
	var outline := Color("#161219")
	var body_col := Color("#E59A28") if not act3 else Color("#6B6452")
	var roof_col := Color("#D8C9B4") if not act3 else Color("#696763")
	var stripe_red := Color("#D64038") if not act3 else Color("#5C4848")
	var stripe_teal := Color("#3BA8A0") if not act3 else Color("#4E5959")

	# Sombra
	draw_rect(Rect2(rect.position.x + 4, rect.position.y + 8, rect.size.x, rect.size.y), Color(0, 0, 0, 0.42))
	draw_rect(rect, outline)
	draw_rect(Rect2(rect.position.x + 2, rect.position.y + 2, rect.size.x - 4, rect.size.y - 6), body_col)
	# Teto metálico com bagageiro
	draw_rect(Rect2(rect.position.x + 6, rect.position.y + 3, 68, 12), roof_col)
	draw_rect(Rect2(rect.position.x + 12, rect.position.y + 5, 56, 8), outline)
	draw_rect(Rect2(rect.position.x + 14, rect.position.y + 6, 52, 6), Color("#8C5836") if not act3 else Color("#4F4842"))
	# Faixas laterais filipinas
	draw_rect(Rect2(rect.position.x + 4, rect.position.y + 18, rect.size.x - 8, 8), stripe_red)
	draw_rect(Rect2(rect.position.x + 4, rect.position.y + 26, rect.size.x - 8, 5), stripe_teal)
	# Para-brisa e capô frontal
	draw_rect(Rect2(rect.end.x - 22, rect.position.y + 5, 16, 13), outline)
	draw_rect(Rect2(rect.end.x - 20, rect.position.y + 7, 12, 9), Color("#90E0EF") if not act3 else Color("#6D7B80"))
	# Faróis acesos na frente
	var headlight_col := Color("#FFF3B0") if not act3 else Color("#8C8A7E")
	draw_circle(Vector2(rect.end.x - 1, rect.position.y + 14), 3.5, headlight_col)
	draw_circle(Vector2(rect.end.x - 1, rect.end.y - 10), 3.5, headlight_col)
	# Rodas com calota
	for wx in [rect.position.x + 20, rect.end.x - 20]:
		draw_circle(Vector2(wx, rect.end.y - 2), 8.0, outline)
		draw_circle(Vector2(wx, rect.end.y - 2), 4.0, Color("#A8B0B8"))

func _draw_hanging_lantern(pos: Vector2, act3: bool) -> void:
	var glow_col := Color(1.0, 0.45, 0.15, 0.32) if not act3 else Color(0.5, 0.5, 0.5, 0.08)
	var body_col := Color("#FF542E") if not act3 else Color("#5E524F")
	var core_col := Color("#FFE082") if not act3 else Color("#8A8680")
	draw_circle(pos, 14.0, glow_col)
	draw_line(Vector2(pos.x, pos.y - 9), Vector2(pos.x, pos.y - 5), Color("#161219"), 1.5)
	draw_circle(pos, 6.0, Color("#161219"))
	draw_circle(pos, 4.8, body_col)
	draw_circle(pos, 2.4, core_col)

func _draw_wood_lamp_post(base_pos: Vector2, act3: bool) -> void:
	var outline := Color("#161219")
	var post_col := Color("#543622") if not act3 else Color("#3E3A36")
	# Poste vertical e braço
	draw_rect(Rect2(base_pos.x - 3, base_pos.y - 44, 6, 44), outline)
	draw_rect(Rect2(base_pos.x - 2, base_pos.y - 42, 4, 40), post_col)
	draw_rect(Rect2(base_pos.x - 2, base_pos.y - 44, 14, 4), outline)
	draw_rect(Rect2(base_pos.x - 1, base_pos.y - 43, 12, 2), post_col)
	# Luminária pendente
	var lamp_pos := Vector2(base_pos.x + 10, base_pos.y - 36)
	draw_circle(lamp_pos, 16.0, Color(1.0, 0.68, 0.25, 0.28) if not act3 else Color(0.5, 0.5, 0.5, 0.08))
	draw_rect(Rect2(lamp_pos.x - 4, lamp_pos.y - 4, 8, 8), outline)
	draw_rect(Rect2(lamp_pos.x - 3, lamp_pos.y - 3, 6, 6), Color("#FFD166") if not act3 else Color("#7D7A74"))

func _draw_street_light_pools(act3: bool, afternoon: bool) -> void:
	if act3:
		return
	var alpha_mult: float = 1.15 if afternoon else 0.90
	var soft_warm := Color(1.0, 0.72, 0.32, 0.11 * alpha_mult)
	var core_warm := Color(1.0, 0.85, 0.45, 0.15 * alpha_mult)
	var porch_light := Color(1.0, 0.76, 0.38, 0.12 * alpha_mult)

	# 1. Luz cônica dos faróis do Jeepney iluminando a estrada de terra à frente
	var j_origin := Vector2(308, 218)
	var beam_outer := PackedVector2Array([
		Vector2(306, 206),
		Vector2(416, 186),
		Vector2(422, 248),
		Vector2(306, 230)
	])
	var beam_inner := PackedVector2Array([
		Vector2(308, 210),
		Vector2(382, 196),
		Vector2(386, 238),
		Vector2(308, 226)
	])
	draw_colored_polygon(beam_outer, Color(1.0, 0.94, 0.65, 0.10 * alpha_mult))
	draw_colored_polygon(beam_inner, Color(1.0, 0.98, 0.82, 0.16 * alpha_mult))
	# Mancha suave de luz no solo onde o feixe do Jeepney atinge
	draw_circle(Vector2(370, 218), 24.0, Color(1.0, 0.92, 0.68, 0.12 * alpha_mult))

	# 2. Banho de luz quente nas varandas em frente às janelas e portas
	# Quitinete de Huwag (janela e porta)
	draw_rect(Rect2(96, 148, 54, 24), porch_light)
	draw_circle(Vector2(148, 160), 16.0, soft_warm)
	# Sari-Sari Store (balcão iluminado e lanternas)
	draw_rect(Rect2(266, 148, 92, 24), Color(1.0, 0.70, 0.28, 0.14 * alpha_mult))
	draw_circle(Vector2(260, 100), 14.0, soft_warm)
	draw_circle(Vector2(364, 100), 14.0, soft_warm)
	# Quartel dos Bombeiros (porta e janela)
	draw_rect(Rect2(530, 148, 48, 24), porch_light)
	draw_circle(Vector2(548, 160), 16.0, soft_warm)

	# 3. Postes de iluminação: poças ovais sutis sob as luminárias (não círculos gigantes)
	var lamp_spots: Array[Vector2] = [
		Vector2(246, 154),
		Vector2(498, 154),
		Vector2(662, 154)
	]
	for lp in lamp_spots:
		draw_circle(lp, 18.0, soft_warm)
		draw_circle(lp, 9.0, core_warm)

	# 4. Pequenos vagalumes / fagulhas sutis no ar da noite filipina perto das lanternas
	if not afternoon:
		var fireflies := [
			Vector2(178, 136), Vector2(262, 118), Vector2(358, 114),
			Vector2(436, 138), Vector2(502, 128), Vector2(660, 122)
		]
		for ff in fireflies:
			draw_circle(ff, 1.5, Color(1.0, 0.95, 0.60, 0.55))
			draw_circle(ff, 3.5, Color(1.0, 0.85, 0.40, 0.18))

func _draw_wood_barrel(pos: Vector2, act3: bool) -> void:
	if _tex_props != null:
		var mod := Color(0.72, 0.72, 0.75, 1.0) if act3 else Color.WHITE
		draw_texture_rect_region(_tex_props, Rect2(pos.x - 10, pos.y - 20, 20, 26), Rect2(96, 76, 32, 49), mod)
		return
	var outline := Color("#161219")
	var wood := Color("#6E472B") if not act3 else Color("#4A443E")
	draw_rect(Rect2(pos.x - 6, pos.y - 12, 12, 14), outline)
	draw_rect(Rect2(pos.x - 5, pos.y - 11, 10, 12), wood)

func _draw_palm_tree(base_pos: Vector2, act3: bool, sc: float = 1.0) -> void:
	var outline := Color("#141118")
	var trunk_col := Color("#6B462C") if not act3 else Color("#47423D")
	var leaf_dark := Color("#1E4D2B") if not act3 else Color("#333B36")
	var leaf_light := Color("#387D44") if not act3 else Color("#444D47")

	draw_circle(base_pos + Vector2(2, 2), 12.0 * sc, Color(0, 0, 0, 0.32))
	if _tex_plants != null:
		var t_mod := Color(0.66, 0.68, 0.66, 0.92) if act3 else Color(0.92, 0.96, 0.88, 0.95)
		draw_texture_rect_region(_tex_plants, Rect2(base_pos.x - 36 * sc, base_pos.y - 84 * sc, 72 * sc, 88 * sc), Rect2(24, 14, 113, 139), t_mod)
	var top_pos := base_pos + Vector2(-4.0 * sc, -48.0 * sc)
	for i in range(8):
		var t: float = float(i) / 7.0
		var p := base_pos.lerp(top_pos, t) + Vector2(sin(t * PI) * 3.0 * sc, 0.0)
		var w: float = lerpf(9.0, 6.0, t) * sc
		draw_rect(Rect2(p.x - w * 0.5 - 1, p.y - 6 * sc, w + 2, 7 * sc), outline)
		draw_rect(Rect2(p.x - w * 0.5, p.y - 5 * sc, w, 5 * sc), trunk_col)

	var frond_dirs: Array[Vector2] = [
		Vector2(-24, -6), Vector2(-20, 10), Vector2(-8, -18),
		Vector2(8, -18), Vector2(22, -6), Vector2(20, 10)
	]
	for d in frond_dirs:
		var tip := top_pos + d * sc
		var mid := top_pos.lerp(tip, 0.5) + Vector2(0, -4.0 * sc)
		draw_line(top_pos, mid, outline, 5.0 * sc)
		draw_line(mid, tip, outline, 4.0 * sc)
		draw_line(top_pos, mid, leaf_dark, 3.5 * sc)
		draw_line(mid, tip, leaf_light, 2.5 * sc)
	draw_circle(top_pos + Vector2(0, 2 * sc), 4.0 * sc, Color("#4E331E"))

func _draw_banana_cluster(base_pos: Vector2, act3: bool, sc: float = 1.0) -> void:
	draw_circle(base_pos + Vector2(0, 2), 10.0 * sc, Color(0, 0, 0, 0.28))
	if _tex_plants != null:
		var b_mod := Color(0.68, 0.70, 0.68, 1.0) if act3 else Color.WHITE
		draw_texture_rect_region(_tex_plants, Rect2(base_pos.x - 22 * sc, base_pos.y - 34 * sc, 44 * sc, 38 * sc), Rect2(216, 185, 47, 42), b_mod)
		return
	var outline := Color("#141118")
	var leaf_dark := Color("#255C34") if not act3 else Color("#363E39")
	draw_circle(base_pos, 8.0 * sc, outline)
	draw_circle(base_pos, 6.5 * sc, leaf_dark)

func _draw_detailed_npc(pos: Vector2, shirt_col: Color, _pants_col: Color, _hair_col: Color, is_elder: bool, act3: bool, sc: float = 1.0) -> void:
	draw_circle(pos + Vector2(0, 2), 7.5 * sc, Color(0, 0, 0, 0.35))
	var sheet_tex: Texture2D = _tex_npc_amelia if is_elder else (_tex_npc_adam if sc < 0.9 else _tex_npc_bob)
	if sheet_tex != null:
		var mod := Color(0.72, 0.74, 0.78, 1.0) if act3 else shirt_col.lerp(Color.WHITE, 0.58)
		draw_texture_rect_region(sheet_tex, Rect2(pos.x - 12 * sc, pos.y - 36 * sc, 24 * sc, 40 * sc), Rect2(48, 0, 16, 32), mod)
		return
	draw_rect(Rect2(pos.x - 6 * sc, pos.y - 24 * sc, 12 * sc, 24 * sc), shirt_col)
