extends Node2D

signal request_level_change(target_scene: String, spawn_tag: String)
signal request_dialogue(pages: Array, callback: Callable)

@onready var player: PlayerController = $Player
@onready var interactables_root: Node2D = $Interactables

var fan_angle: float = 0.0
var dust_time: float = 0.0

var _tex_room_builder: Texture2D = null
var _tex_interiors: Texture2D = null

const ROOM_RECT := Rect2(96, 36, 448, 288)

# Regiões dos tiles de Room_Builder_free_16x16.png (16x16 px cada)
const TILE_FLOOR_WOOD := Rect2i(176, 208, 16, 16)
const TILE_FLOOR_KITCHEN := Rect2i(176, 112, 16, 16)
const TILE_FLOOR_TERRACOTTA := Rect2i(184, 80, 16, 16)
const TILE_WALL_TOP := Rect2i(16, 160, 16, 16)
const TILE_WALL_MID := Rect2i(16, 176, 16, 16)
const TILE_WALL_BOT := Rect2i(16, 192, 16, 16)
const TILE_BORDER_TOP := Rect2i(0, 0, 16, 16)
const TILE_BORDER_SIDE := Rect2i(0, 16, 16, 16)

# Regiões dos móveis reais de Interiors_free_16x16.png
const ITEM_BED := Rect2i(88, 8, 49, 78)
const ITEM_NIGHTSTAND := Rect2i(0, 914, 18, 24)
const ITEM_WARDROBE := Rect2i(112, 816, 34, 46)
const ITEM_BOOKSHELF := Rect2i(78, 220, 36, 40)
const ITEM_WINDOW := Rect2i(66, 388, 42, 30)
const ITEM_FRIDGE := Rect2i(204, 609, 38, 35)
const ITEM_COUNTER := Rect2i(0, 526, 74, 34)
const ITEM_RUG := Rect2i(112, 256, 64, 34)
const ITEM_DOOR := Rect2i(174, 384, 36, 34)
const ITEM_PALM := Rect2i(210, 700, 30, 40)
const ITEM_PLANT := Rect2i(164, 708, 22, 40)
# Decoração adicional verificada em Interiors_free_16x16.png
const ITEM_MAP := Rect2i(164, 1068, 34, 22)     # Quadro do mapa-múndi
const ITEM_ART_A := Rect2i(4, 331, 28, 16)      # Quadro de paisagem/mar (moldura cinza)
const ITEM_ART_B := Rect2i(212, 334, 30, 22)    # Quadro abstrato (moldura dourada)
const ITEM_GLOBE := Rect2i(218, 580, 24, 26)    # Globo terrestre
const ITEM_BENCH := Rect2i(34, 828, 28, 20)     # Banco/tamborete de vime
const ITEM_FRAME := Rect2i(34, 528, 18, 20)     # Pequeno quadro emoldurado

func _load_room_textures() -> void:
	var path_rb := "res://assets/third_party/Modern_Interiors_Free_v2.2/Modern tiles_Free/Interiors_free/16x16/Room_Builder_free_16x16.png"
	var path_int := "res://assets/third_party/Modern_Interiors_Free_v2.2/Modern tiles_Free/Interiors_free/16x16/Interiors_free_16x16.png"
	if ResourceLoader.exists(path_rb):
		_tex_room_builder = load(path_rb) as Texture2D
	if ResourceLoader.exists(path_int):
		_tex_interiors = load(path_int) as Texture2D

func _ready() -> void:
	_load_room_textures()
	if GameState.spawn_tag == "from_street":
		player.position = Vector2(288, 286)
		player.facing_dir = Vector2.UP
	else:
		player.position = Vector2(204, 174)
		player.facing_dir = Vector2.DOWN

	player.set_camera_limits(Rect2i(0, 0, 640, 360))
	_setup_walls_and_furniture_collision()
	_setup_interactables()
	GameState.time_of_day_changed.connect(func(_v: bool) -> void: queue_redraw())
	GameState.perception_changed.connect(func(_m: int) -> void: queue_redraw())
	GameState.outfit_changed.connect(func(_o: String) -> void: queue_redraw())

	if not GameState.get_self_switch("EV_Introducao", "A"):
		GameState.set_self_switch("EV_Introducao", "A", true)
		call_deferred("_trigger_intro_monologue")

func _process(delta: float) -> void:
	fan_angle = fmod(fan_angle + delta * 11.0, TAU)
	dust_time += delta
	queue_redraw()

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

func _setup_walls_and_furniture_collision() -> void:
	var body := StaticBody2D.new()
	body.name = "RoomWalls"
	body.collision_layer = 1
	add_child(body)

	var rects: Array[Rect2] = [
		Rect2(80, 16, 480, 60),    # Parede norte sólida
		Rect2(80, 324, 184, 20),   # Parede sul esquerda
		Rect2(318, 324, 242, 20),  # Parede sul direita (deixa vão livre para porta)
		Rect2(80, 16, 16, 324),    # Parede oeste
		Rect2(544, 16, 16, 324),   # Parede leste
		Rect2(118, 104, 56, 70),   # Cama com dossel
		Rect2(176, 98, 24, 24),    # Criado-mudo com remédios e mini-Jeepney
		Rect2(216, 54, 82, 46),    # Guarda-roupa + Estante de livros
		Rect2(444, 64, 96, 44),    # Geladeira e balcão de cozinha com pia
		Rect2(102, 266, 24, 38),   # Palmeira canto sudoeste
		Rect2(148, 264, 38, 24),   # Baú
		Rect2(482, 264, 28, 22),   # Cesto canto sudeste
		Rect2(126, 282, 28, 22),   # Cesto oeste
	]
	for r in rects:
		var shape_node := CollisionShape2D.new()
		var rect_shape := RectangleShape2D.new()
		rect_shape.size = r.size
		shape_node.shape = rect_shape
		shape_node.position = r.position + r.size * 0.5
		body.add_child(shape_node)

func _setup_interactables() -> void:
	_add_interactable("Cama", "Cama com Dossel", "Descansar", Vector2(147, 145), Vector2(58, 64))
	_add_interactable("Mesa_Remedios", "Mesa com Remédios", "Examinar", Vector2(187, 112), Vector2(24, 24))
	_add_interactable("Armario_Uniforme", "Guarda-Roupa de Serviço", "Abrir", Vector2(233, 80), Vector2(34, 46))
	_add_interactable("Ventilador", "Ventilador de Teto", "Ouvir", Vector2(300, 84), Vector2(46, 32))
	_add_interactable("Janela_Norte", "Janela Shoji para a Rua", "Olhar", Vector2(358, 82), Vector2(44, 30))
	_add_interactable("Radio_Quartel", "Rádio Comunicador BFP", "Checar", Vector2(398, 82), Vector2(24, 24))
	_add_interactable("Geladeira", "Geladeira da Cozinha", "Abrir", Vector2(521, 82), Vector2(36, 32))
	_add_interactable("Porta_Saida", "Porta para Agdangan", "Sair", Vector2(292, 314), Vector2(40, 28))

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
						queue_redraw()
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
						queue_redraw()
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
				"A cama de madeira rangeu sob o peso. O lençol está úmido de suor.\nSem o efeito dos comprimidos, o quarto parece apenas um cubículo abafado."
				if act3 else
				"Uma cama simples e acolhedora com colcha tecida à mão.\nAcordei empapado com o calor matinal. Dormi poucas horas entre sonhos confusos e sirenes, mas o dever não espera."
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
						"text": "Sobre a mesa de cabeceira estão meus três frascos matinais ao lado de uma miniatura de Jeepney que guardo desde criança."
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
					"text": "Armário de serviço (%s).\nEscolha o que vestir:" % status_txt,
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
					"text": "Pela janela de madeira, a vegetação tropical lá fora parece imóvel e sem cor sob o céu cinzento de Agdangan."
				}], Callable())
			elif _is_night_room():
				request_dialogue.emit([{
					"speaker": "Huwag Matitiis",
					"expression": "tired",
					"text": "Pelas venezianas abertas, a brisa noturna balança as folhas de bananeira e coqueiro lá fora.\nOs grilos cantam na escuridão abafada de Agdangan."
				}], Callable())
			else:
				request_dialogue.emit([
					{
						"speaker": "Huwag Matitiis",
						"expression": "surprised",
						"text": "Pela janela, o sol da manhã faz brilhar as folhas de bananeira e os telhados da rua lá embaixo!"
					},
					{
						"speaker": "Huwag Matitiis",
						"expression": "neutral",
						"text": "O brilho reflete nas cores vivas dos Jeepneys e na torre da igreja ao longe.\nLá fora, tudo parece tão alegre... Quase como uma pintura infantil."
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
			var fridge_text := (
				"A geladeira vibra baixinho com um ímã do mapa das Filipinas na porta.\nAo lado da pia de cozinha há pacotes de pancit canton e garrafas d'água mineral."
			)
			request_dialogue.emit([{"speaker": "Huwag Matitiis", "expression": "neutral", "text": fridge_text}], Callable())

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
						"text": "Hora de ir para o quartel dos bombeiros.\nSair para a rua?",
						"choices": ["Sim, sair para Agdangan", "Ainda não"]
					}
				]
				request_dialogue.emit(pages_door, func(choice: int) -> void:
					if choice == 0:
						request_level_change.emit("res://scenes/levels/StreetPreview.tscn", "from_room")
				)

func _draw() -> void:
	var act3 := GameState.is_unfiltered_act3()
	var night := _is_night_room()

	# 1. Vazio externo escuro profundo
	draw_rect(Rect2(-500, -500, 1600, 1200), Color("#07070B") if not act3 else Color("#0C0D10"))

	# Modulação de cor para iluminação de cena (Ato 3 sem filtro vs Manhã ensolarada vs Noite)
	var scene_tint := Color.WHITE
	if act3:
		scene_tint = Color(0.72, 0.74, 0.78, 1.0)
	elif night:
		scene_tint = Color(0.68, 0.72, 0.90, 1.0)

	# 2. Parede e borda perimetral com tilesets reais
	_draw_walls_and_borders(scene_tint)

	# 3. Piso unificado com tilesets reais (Parquet na área de dormir/viver, Cerâmica na cozinha)
	_draw_textured_floors(scene_tint)

	# 3b. Coesão do piso: unifica o tom da madeira, acalma a cerâmica e aplica vinheta
	_draw_floor_cohesion(act3)

	# 4. Móveis autênticos de pixel art de Interiors_free_16x16.png
	_draw_pixel_furniture(scene_tint, act3, night)

	# 4b. Lavagem de luz ambiente sobre toda a cena (coesão cromática)
	_draw_ambient_light(act3, night)

	# 5. Feixe de luz solar matinal pela janela (ou luar suave à noite)
	_draw_window_sunlight(act3, night)

	# 6. Vinheta de ambiente (profundidade de cena)
	_draw_edge_vignette(Rect2(80, 14, 480, 326), Color(0.02, 0.02, 0.04, 0.30), 40.0)

func _draw_walls_and_borders(tint: Color) -> void:
	var act3 := GameState.is_unfiltered_act3()
	var wall_dark := Color("#151322") * tint
	var wall_edge := Color("#2A273D") * tint

	# Borda superior e paredes norte exteriores
	draw_rect(Rect2(80, 14, 480, 14), wall_dark)
	draw_line(Vector2(80, 27), Vector2(560, 27), wall_edge, 1.0)

	# Paredes laterais: faixa de madeira sólida (com gradiente e borda interna iluminada)
	draw_rect(Rect2(80, 14, 16, 326), wall_dark)
	draw_rect(Rect2(544, 14, 16, 326), wall_dark)
	_draw_side_wall(Rect2(80, 28, 16, 296), tint, false)   # oeste (borda interna à direita)
	_draw_side_wall(Rect2(544, 28, 16, 296), tint, true)   # leste (borda interna à esquerda)

	# Parede sul exterior (y=324..340, exceto abertura da porta em x=272..312)
	draw_rect(Rect2(80, 324, 192, 16), wall_dark)
	draw_rect(Rect2(312, 324, 248, 16), wall_dark)
	draw_line(Vector2(80, 325), Vector2(272, 325), wall_edge, 1.0)
	draw_line(Vector2(312, 325), Vector2(560, 325), wall_edge, 1.0)

	# Parede norte: parte superior colorida (menta) + moldura + rodapé de madeira
	var wall_top := (Color("#BCE2D6") if not act3 else Color("#8A8F92")) * tint
	var wall_bot := (Color("#A6D3C6") if not act3 else Color("#787D80")) * tint
	draw_polygon(
		PackedVector2Array([Vector2(96, 28), Vector2(544, 28), Vector2(544, 58), Vector2(96, 58)]),
		PackedColorArray([wall_top, wall_top, wall_bot, wall_bot])
	)
	draw_rect(Rect2(96, 58, 448, 2), (Color("#7FB8A8") if not act3 else Color("#5E6265")) * tint)
	draw_rect(Rect2(96, 60, 448, 16), (Color("#6E4A2E") if not act3 else Color("#4A4A48")) * tint)
	# Pilares de madeira dividindo os painéis da parede (estilo anexo 2)
	var pillar_col := (Color("#8C6A45") if not act3 else Color("#5A5A56")) * tint
	var pillar_hi := (Color("#B08A57") if not act3 else Color("#72726E")) * tint
	for px in [100.0, 196.0, 292.0, 388.0, 484.0]:
		draw_rect(Rect2(px, 28, 9, 40), pillar_col)
		draw_line(Vector2(px + 2, 28), Vector2(px + 2, 68), pillar_hi, 1.0)

func _draw_side_wall(rect: Rect2, tint: Color, inner_left: bool) -> void:
	var act3 := GameState.is_unfiltered_act3()
	var top := (Color("#BCE2D6") if not act3 else Color("#8A8F92")) * tint
	var bot := (Color("#9CCBBC") if not act3 else Color("#6E7274")) * tint
	draw_polygon(
		PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)]),
		PackedColorArray([top, top, bot, bot])
	)
	var edge_col := (Color("#D8F0E6") if not act3 else Color("#9AA0A2")) * tint
	var ex: float = rect.position.x + 1.0 if inner_left else rect.end.x - 1.0
	draw_line(Vector2(ex, rect.position.y + 2.0), Vector2(ex, rect.end.y - 2.0), edge_col, 1.0)

func _draw_textured_floors(tint: Color) -> void:
	# 1. Piso de madeira nobre e acolhedor (taboado) na área de dormir/estar (x=96..438)
	_draw_wood_floor(tint)

	# Sombra suave de oclusão de contato nas paredes norte, leste e oeste
	draw_rect(Rect2(96, 76, 448, 8), Color(0.04, 0.03, 0.07, 0.32))
	draw_rect(Rect2(96, 76, 6, 248), Color(0.04, 0.03, 0.07, 0.22))
	draw_rect(Rect2(538, 76, 6, 248), Color(0.04, 0.03, 0.07, 0.22))

func _draw_wood_floor(tint: Color) -> void:
	# Taboado de madeira quente (direção de arte #8C6240): calmo, com juntas escalonadas e veios
	var act3 := GameState.is_unfiltered_act3()
	var x0 := 96.0
	var x1 := 544.0
	var y0 := 76.0
	var y1 := 324.0
	var top_col := Color("#A0744A") if not act3 else Color("#74746F")
	var bot_col := Color("#6A4628") if not act3 else Color("#50504C")
	top_col = top_col * tint
	bot_col = bot_col * tint
	draw_polygon(
		PackedVector2Array([Vector2(x0, y0), Vector2(x1, y0), Vector2(x1, y1), Vector2(x0, y1)]),
		PackedColorArray([top_col, top_col, bot_col, bot_col])
	)

	var seam := Color(0.24, 0.13, 0.06, 0.26) if not act3 else Color(0.12, 0.12, 0.14, 0.24)
	var seam_v := Color(0.24, 0.13, 0.06, 0.12) if not act3 else Color(0.12, 0.12, 0.14, 0.11)
	var grain := Color(0.30, 0.18, 0.10, 0.12) if not act3 else Color(0.16, 0.16, 0.18, 0.10)

	# Réguas finas de 16 px com juntas verticais escalonadas a cada 64 px
	var plank_h := 16.0
	var plank_len := 64.0
	var row := 0
	var y := y0
	while y < y1 - 0.5:
		var yy_b: float = minf(y + plank_h, y1)
		var tone := (float((row * 7) % 3) - 1.0) * 0.010
		if tone >= 0.0:
			draw_rect(Rect2(x0, y, x1 - x0, yy_b - y), Color(1.0, 0.94, 0.84, tone))
		else:
			draw_rect(Rect2(x0, y, x1 - x0, yy_b - y), Color(0.0, 0.0, 0.0, -tone))
		var offset: float = 0.0 if row % 2 == 0 else plank_len * 0.5
		var sx := x0 + offset
		while sx < x1:
			draw_line(Vector2(sx, y), Vector2(sx, yy_b), seam_v, 1.0)
			sx += plank_len
		var gx := x0 + 10.0 + float((row * 23) % 52)
		while gx < x1 - 12.0:
			draw_line(Vector2(gx, y + 7.0), Vector2(gx + 16.0, y + 7.0), grain, 1.0)
			gx += 58.0
		draw_line(Vector2(x0, yy_b - 0.5), Vector2(x1, yy_b - 0.5), seam, 1.0)
		row += 1
		y += plank_h

func _draw_pixel_furniture(tint: Color, act3: bool, _night: bool) -> void:
	if _tex_interiors == null:
		return

	# 1. Esteira (tatami) sob a área de dormir
	_draw_tatami(Rect2(108, 100, 176, 148), tint, act3)

	# 2. Cama com dossel (four-poster) sobre a esteira
	_draw_canopy_bed(Vector2(120, 104), tint, act3)

	# 3. Criado-mudo com remédios e mini-Jeepney
	draw_rect(Rect2(176, 108, 20, 16), Color(0.03, 0.02, 0.06, 0.35))
	_draw_item(ITEM_NIGHTSTAND, Vector2(176, 100), tint)
	_draw_jeepney_miniature(Vector2(178, 99), act3)

	# 4. Guarda-roupa entalhado (parede norte)
	draw_rect(Rect2(216, 66, 36, 36), Color(0.03, 0.02, 0.06, 0.40))
	_draw_item(ITEM_WARDROBE, Vector2(216, 54), tint)

	# 5. Estante de livros (parede norte)
	draw_rect(Rect2(258, 68, 38, 30), Color(0.03, 0.02, 0.06, 0.38))
	_draw_item(ITEM_BOOKSHELF, Vector2(258, 56), tint)

	# 6. Ventilador de teto com pás de palha
	_draw_ceiling_fan(Vector2(300, 58), tint, act3)

	# 7. Janela shoji iluminada
	_draw_shoji_window(Vector2(336, 32), tint, act3)

	# 8. Rádio comunicador BFP na parede
	_draw_wall_radio_item(Vector2(398, 44), act3)

	# 9. Tapeçarias (kakejiku) penduradas na parede
	_draw_tapestry(Vector2(110, 30), tint, act3, Color("#C0503A"))
	_draw_tapestry(Vector2(206, 32), tint, act3, Color("#5B6EA8"))
	_draw_tapestry(Vector2(496, 30), tint, act3, Color("#4E8C7A"))

	# 10. Balcão com pia e geladeira (canto nordeste)
	draw_rect(Rect2(444, 78, 62, 24), Color(0.03, 0.02, 0.06, 0.35))
	_draw_item(Rect2i(0, 526, 60, 34), Vector2(442, 66), tint)
	draw_rect(Rect2(504, 88, 36, 14), Color(0.03, 0.02, 0.06, 0.35))
	_draw_item(ITEM_FRIDGE, Vector2(502, 62), tint)

	# 11. Palmeiras, baú e cestos de vime
	_draw_item(ITEM_PALM, Vector2(102, 268), tint)
	_draw_trunk(Vector2(150, 266), tint, act3)
	_draw_basket(Vector2(486, 266), tint, act3)
	_draw_basket(Vector2(128, 284), tint, act3)

	# 12. Tapete e mesinha baixa (kotatsu) no centro
	_draw_item(ITEM_RUG, Vector2(268, 196), tint)
	_draw_low_table(Vector2(300, 210), act3)

	# 12b. Banco de vime e caixotes no canto leste
	_draw_item(ITEM_BENCH, Vector2(414, 250), tint)
	_draw_crate(Vector2(452, 250), tint, act3)
	_draw_crate(Vector2(450, 226), tint, act3)
	_draw_item(ITEM_PALM, Vector2(516, 176), tint)

	# 13. Porta de saída ao sul
	_draw_item(ITEM_DOOR, Vector2(274, 306), tint)

func _draw_tatami(rect: Rect2, tint: Color, act3: bool) -> void:
	var base := (Color("#CBBA82") if not act3 else Color("#8E8C7E")) * tint
	var weave := (Color("#B0A067") if not act3 else Color("#76746A")) * tint
	var border := (Color("#5E5636") if not act3 else Color("#4A4A44")) * tint
	# Sombra suave sob a esteira
	draw_rect(Rect2(rect.position.x + 3, rect.position.y + rect.size.y - 2, rect.size.x, 6), Color(0.03, 0.02, 0.06, 0.22))
	draw_rect(rect, base)
	var y := rect.position.y + 5.0
	while y < rect.end.y - 3.0:
		draw_line(Vector2(rect.position.x + 3.0, y), Vector2(rect.end.x - 3.0, y), weave, 1.0)
		y += 4.0
	draw_rect(rect, border, false, 3.0)
	draw_rect(Rect2(rect.position.x + 4, rect.position.y + 4, rect.size.x - 8, rect.size.y - 8), border, false, 1.0)

func _draw_canopy_bed(pos: Vector2, tint: Color, act3: bool) -> void:
	var post := (Color("#8C6A45") if not act3 else Color("#5E5A56")) * tint
	var post_hi := (Color("#A98455") if not act3 else Color("#6E6E6A")) * tint
	var sheer := Color(1.0, 1.0, 1.0, 0.34) if not act3 else Color(0.85, 0.86, 0.88, 0.26)
	# Sombra sob a cama
	draw_rect(Rect2(pos.x + 2, pos.y + 68, 46, 12), Color(0.03, 0.02, 0.06, 0.30))
	# Base da cama (sprite)
	_draw_item(ITEM_BED, pos, tint)
	# Dossel translúcido (tecido) sobre a cama
	draw_rect(Rect2(pos.x - 5, pos.y - 8, 60, 30), sheer)
	draw_rect(Rect2(pos.x - 5, pos.y - 8, 11, 84), sheer)
	draw_rect(Rect2(pos.x + 44, pos.y - 8, 11, 84), sheer)
	# Postes nos 4 cantos
	for px in [pos.x - 5.0, pos.x + 44.0]:
		for py in [pos.y - 8.0, pos.y + 70.0]:
			draw_rect(Rect2(px, py, 4, 6), post)
	# Cornija superior e ripas
	draw_line(Vector2(pos.x - 5, pos.y - 6), Vector2(pos.x + 48, pos.y - 6), post, 2.0)
	draw_line(Vector2(pos.x - 3, pos.y - 3), Vector2(pos.x + 46, pos.y - 3), post_hi, 1.0)
	# Sanefa (valance) de tecido com barra arredondada
	var cloth := Color(0.98, 0.98, 0.96, 0.55) if not act3 else Color(0.82, 0.82, 0.84, 0.42)
	draw_rect(Rect2(pos.x - 5, pos.y - 8, 60, 6), cloth)
	for i in range(6):
		var vx: float = pos.x - 5.0 + float(i) * 10.0
		draw_circle(Vector2(vx + 5.0, pos.y - 2.0), 5.0, cloth)

func _draw_ceiling_fan(pos: Vector2, tint: Color, act3: bool) -> void:
	var center := pos + Vector2(0, 14)
	var hub := (Color("#6B5A3E") if not act3 else Color("#484844")) * tint
	var blade := (Color("#CBA85A") if not act3 else Color("#7E7C72")) * tint
	var blade_d := (Color("#A98455") if not act3 else Color("#63615A")) * tint
	var rod := (Color("#3A3A40") if not act3 else Color("#2E2E32")) * tint
	# Haste até o teto
	draw_line(Vector2(pos.x, pos.y - 12), Vector2(pos.x, center.y), rod, 2.0)
	# Pás de palha girando
	for i in range(6):
		var a: float = fan_angle * 0.55 + float(i) * TAU / 6.0
		var mid := center + Vector2(cos(a), sin(a)) * 22.0
		var b1 := center + Vector2(cos(a - 0.26), sin(a - 0.26)) * 20.0
		var b2 := center + Vector2(cos(a + 0.26), sin(a + 0.26)) * 20.0
		draw_colored_polygon(PackedVector2Array([center, b1, mid, b2]), blade)
		draw_line(center, mid, blade_d, 1.0)
	draw_circle(center, 4.0, hub)

func _draw_shoji_window(pos: Vector2, tint: Color, act3: bool) -> void:
	var w := 44.0
	var h := 30.0
	var frame := (Color("#8C6A45") if not act3 else Color("#5E5A56")) * tint
	var glow := (Color("#F2E2AE") if not act3 else Color("#8A8C88")) * tint
	var lattice := (Color("#6E4A2E") if not act3 else Color("#4A4A46")) * tint
	if not act3:
		_draw_soft_glow(pos + Vector2(w * 0.5, h * 0.5), Vector2(w * 0.7, h * 0.9), Color(1.0, 0.92, 0.6, 0.22))
	draw_rect(Rect2(pos.x, pos.y, w, h), frame)
	draw_rect(Rect2(pos.x + 2, pos.y + 2, w - 4, h - 4), glow)
	for i in range(1, 4):
		var gx: float = pos.x + 2.0 + (w - 4.0) * float(i) / 4.0
		draw_line(Vector2(gx, pos.y + 2), Vector2(gx, pos.y + h - 2), lattice, 1.0)
	draw_line(Vector2(pos.x + 2, pos.y + h * 0.5), Vector2(pos.x + w - 2, pos.y + h * 0.5), lattice, 1.0)

func _draw_tapestry(pos: Vector2, tint: Color, act3: bool, col: Color) -> void:
	var w := 22.0
	var h := 36.0
	var rod := (Color("#6E4A2E") if not act3 else Color("#4A4A46")) * tint
	var c := (col if not act3 else Color(0.52, 0.52, 0.54)) * tint
	var cd := Color(c.r * 0.70, c.g * 0.70, c.b * 0.70, 1.0)
	var cl := Color(minf(c.r * 1.18, 1.0), minf(c.g * 1.18, 1.0), minf(c.b * 1.18, 1.0), 1.0)
	draw_line(Vector2(pos.x - 4, pos.y), Vector2(pos.x + w + 4, pos.y), rod, 2.0)
	draw_rect(Rect2(pos.x, pos.y, w, h), c)
	draw_rect(Rect2(pos.x + 2, pos.y + 3, w - 4, h - 10), cl)
	draw_rect(Rect2(pos.x + 5, pos.y + 8, w - 10, 4), cd)
	draw_rect(Rect2(pos.x + 5, pos.y + 20, w - 10, 4), cd)
	draw_rect(Rect2(pos.x, pos.y + h - 4, w, 4), rod)

func _draw_trunk(pos: Vector2, tint: Color, act3: bool) -> void:
	var wood := (Color("#8A5A2E") if not act3 else Color("#5A5048")) * tint
	var wood_d := (Color("#6E4420") if not act3 else Color("#443E38")) * tint
	var metal := (Color("#C9A85C") if not act3 else Color("#7E7C72")) * tint
	draw_rect(Rect2(pos.x, pos.y + 20, 34, 8), Color(0.03, 0.02, 0.06, 0.28))
	draw_rect(Rect2(pos.x, pos.y, 34, 20), wood)
	draw_rect(Rect2(pos.x, pos.y, 34, 6), wood_d)
	draw_line(Vector2(pos.x + 6, pos.y), Vector2(pos.x + 6, pos.y + 20), metal, 1.5)
	draw_line(Vector2(pos.x + 27, pos.y), Vector2(pos.x + 27, pos.y + 20), metal, 1.5)
	draw_rect(Rect2(pos.x + 14, pos.y + 8, 6, 6), metal)

func _draw_basket(pos: Vector2, tint: Color, act3: bool) -> void:
	var wicker := (Color("#C9A25E") if not act3 else Color("#8A867A")) * tint
	var dark := (Color("#9C7A3E") if not act3 else Color("#6E6A60")) * tint
	var cloth := (Color("#C0503A") if not act3 else Color("#7A6E68")) * tint
	draw_rect(Rect2(pos.x - 1, pos.y + 14, 24, 6), Color(0.03, 0.02, 0.06, 0.28))
	draw_colored_polygon(PackedVector2Array([
		Vector2(pos.x, pos.y + 4), Vector2(pos.x + 22, pos.y + 4),
		Vector2(pos.x + 18, pos.y + 18), Vector2(pos.x + 4, pos.y + 18)
	]), wicker)
	for i in range(3):
		var yy: float = pos.y + 7.0 + float(i) * 4.0
		draw_line(Vector2(pos.x + 3, yy), Vector2(pos.x + 19, yy), dark, 1.0)
	draw_rect(Rect2(pos.x + 4, pos.y, 14, 6), cloth)

func _draw_crate(pos: Vector2, tint: Color, act3: bool) -> void:
	var wood := (Color("#B98A4E") if not act3 else Color("#7A7266")) * tint
	var wood_d := (Color("#8C6A38") if not act3 else Color("#5E5A50")) * tint
	draw_rect(Rect2(pos.x, pos.y + 22, 26, 6), Color(0.03, 0.02, 0.06, 0.26))
	draw_rect(Rect2(pos.x, pos.y, 26, 22), wood)
	draw_rect(Rect2(pos.x, pos.y, 26, 3), wood_d)
	draw_rect(Rect2(pos.x, pos.y + 19, 26, 3), wood_d)
	draw_line(Vector2(pos.x, pos.y + 11), Vector2(pos.x + 26, pos.y + 11), wood_d, 1.0)
	draw_line(Vector2(pos.x + 13, pos.y), Vector2(pos.x + 13, pos.y + 22), wood_d, 1.0)

	# 17. Luminária de pé com brilho quente ao lado da cama
	_draw_floor_lamp(Vector2(168, 92), act3)

func _draw_low_table(pos: Vector2, act3: bool) -> void:
	var top_col := Color("#9A6534") if not act3 else Color("#6A6058")
	var lip_col := Color("#B47C46") if not act3 else Color("#78706A")
	var leg_col := Color("#5E3A20") if not act3 else Color("#433D38")
	# Sombra projetada
	draw_rect(Rect2(pos.x - 1, pos.y + 10, 24, 8), Color(0.03, 0.02, 0.06, 0.28))
	# Pernas
	draw_line(Vector2(pos.x + 3, pos.y + 11), Vector2(pos.x + 3, pos.y + 14), leg_col, 1.5)
	draw_line(Vector2(pos.x + 19, pos.y + 11), Vector2(pos.x + 19, pos.y + 14), leg_col, 1.5)
	# Tampo
	draw_rect(Rect2(pos.x, pos.y, 22, 12), top_col)
	draw_rect(Rect2(pos.x + 2, pos.y + 2, 18, 6), lip_col)
	# Xícara sobre a mesa
	_draw_counter_cup(pos + Vector2(13, -5), act3)

func _draw_counter_cup(pos: Vector2, act3: bool) -> void:
	draw_rect(Rect2(pos.x, pos.y, 5, 5), Color("#E8E4D8") if not act3 else Color("#8A8C8A"))
	draw_rect(Rect2(pos.x, pos.y + 1, 5, 3), Color("#8C5A3C") if not act3 else Color("#5A4E48"))
	var vp := fmod(dust_time * 0.8, 1.0)
	draw_circle(Vector2(pos.x + 2.5, pos.y - 3.0 - vp * 4.0), 1.0, Color(1, 1, 1, 0.18 * (1.0 - vp)))

func _draw_wall_clock(pos: Vector2, act3: bool) -> void:
	var c := pos + Vector2(9, 9)
	var rim := Color("#3B3244") if not act3 else Color("#33363C")
	var face := Color("#E8E4D8") if not act3 else Color("#9A9C99")
	var hand := Color("#20222B") if not act3 else Color("#3A3C40")
	draw_circle(c, 9.0, rim)
	draw_circle(c, 7.5, face)
	var t := dust_time * 0.5
	draw_line(c, c + Vector2(cos(t), sin(t)) * 5.0, hand, 1.4)
	draw_line(c, c + Vector2(cos(t * 0.12 + 1.0), sin(t * 0.12 + 1.0)) * 3.2, hand, 1.4)
	draw_circle(c, 1.0, hand)

func _draw_slippers(pos: Vector2, act3: bool) -> void:
	var s1 := Color("#3FA7D6") if not act3 else Color("#5A646B")
	var s2 := Color("#2E8BB8") if not act3 else Color("#4C555B")
	var strap := Color("#E8E4D8") if not act3 else Color("#8A8C8A")
	for i in range(2):
		var p := pos + Vector2(float(i) * 7.0, 0)
		draw_rect(Rect2(p.x, p.y, 6, 11), s1)
		draw_rect(Rect2(p.x + 1, p.y + 1, 4, 9), s2)
		draw_line(p + Vector2(3, 1), p + Vector2(3, 6), strap, 1.0)

func _draw_desk(pos: Vector2, act3: bool) -> void:
	var top_col := Color("#9A6534") if not act3 else Color("#6A6058")
	var lip_col := Color("#B47C46") if not act3 else Color("#78706A")
	var leg_col := Color("#5E3A20") if not act3 else Color("#433D38")
	var paper := Color("#E8E4D8") if not act3 else Color("#8A8C8A")
	# Sombra projetada
	draw_rect(Rect2(pos.x - 2, pos.y + 22, 50, 11), Color(0.03, 0.02, 0.06, 0.30))
	# Pernas
	draw_line(Vector2(pos.x + 4, pos.y + 22), Vector2(pos.x + 4, pos.y + 30), leg_col, 2.0)
	draw_line(Vector2(pos.x + 42, pos.y + 22), Vector2(pos.x + 42, pos.y + 30), leg_col, 2.0)
	# Tampo
	draw_rect(Rect2(pos.x, pos.y, 46, 22), top_col)
	draw_rect(Rect2(pos.x + 3, pos.y + 3, 40, 16), lip_col)
	# Itens: papéis, pasta azul e livro aberto
	draw_rect(Rect2(pos.x + 6, pos.y + 6, 13, 9), paper)
	draw_rect(Rect2(pos.x + 7, pos.y + 8, 11, 1), Color("#B6B0A4") if not act3 else Color("#6E6E6E"))
	draw_rect(Rect2(pos.x + 22, pos.y + 5, 9, 11), Color("#3FA7D6") if not act3 else Color("#5A646B"))
	draw_rect(Rect2(pos.x + 33, pos.y + 7, 10, 8), Color("#5E8C3A") if not act3 else Color("#5A645A"))
	draw_line(Vector2(pos.x + 38, pos.y + 7), Vector2(pos.x + 38, pos.y + 15), Color("#2E4A1E") if not act3 else Color("#3A403A"), 1.0)
	# Cadeira encaixada sob a escrivaninha
	var chair := Color("#7A5A3A") if not act3 else Color("#565250")
	draw_rect(Rect2(pos.x + 12, pos.y + 18, 14, 14), chair)
	draw_rect(Rect2(pos.x + 12, pos.y + 16, 14, 4), Color("#8C6A45") if not act3 else Color("#605C5A"))

func _draw_floor_lamp(pos: Vector2, act3: bool) -> void:
	var pole := Color("#3A3A40") if not act3 else Color("#2E2E32")
	var shade := Color("#E8C878") if not act3 else Color("#8A8578")
	if not act3:
		_draw_soft_glow(pos + Vector2(0, -22), Vector2(26, 18), Color(1.0, 0.85, 0.52, 0.22))
	draw_rect(Rect2(pos.x - 5, pos.y, 10, 3), pole)
	draw_line(Vector2(pos.x, pos.y), Vector2(pos.x, pos.y - 22), pole, 2.0)
	draw_colored_polygon(PackedVector2Array([
		Vector2(pos.x - 6, pos.y - 22), Vector2(pos.x + 6, pos.y - 22),
		Vector2(pos.x + 4, pos.y - 32), Vector2(pos.x - 4, pos.y - 32)
	]), shade)

func _draw_item(src_rect: Rect2i, pos: Vector2, tint: Color) -> void:
	draw_texture_rect_region(_tex_interiors, Rect2(pos.x, pos.y, src_rect.size.x, src_rect.size.y), src_rect, tint)

func _draw_jeepney_miniature(pos: Vector2, act3: bool) -> void:
	# Mini-Jeepney amarelo e vermelho sobre o criado-mudo (detalhe narrativo canônico)
	var jx := pos.x
	var jy := pos.y
	var col_j_body := Color("#E8AB2C") if not act3 else Color("#6E685C")
	var col_j_hood := Color("#D63B34") if not act3 else Color("#5A4A48")
	var col_j_top := Color("#E6E4DF") if not act3 else Color("#7E7D7A")
	draw_rect(Rect2(jx, jy + 2, 13, 6), col_j_body)
	draw_rect(Rect2(jx + 2, jy, 9, 3), col_j_top)
	draw_rect(Rect2(jx + 10, jy + 3, 3, 4), col_j_hood)
	# Frascos de remédio
	draw_rect(Rect2(jx + 15, jy + 2, 3, 5), Color("#FF595E") if not act3 else Color("#5B4748"))
	draw_rect(Rect2(jx + 19, jy + 3, 3, 4), Color("#FFCA3A") if not act3 else Color("#6B6554"))

func _draw_wall_fan_animated(pos: Vector2, act3: bool) -> void:
	var center := pos + Vector2(12, 12)
	var box := Rect2(pos.x, pos.y, 24, 24)
	var col_metal := Color("#6C757D") if not act3 else Color("#45484D")
	var col_dark := Color("#212529") if not act3 else Color("#1A1C1E")
	var col_blade := Color("#CED4DA") if not act3 else Color("#55595E")

	draw_rect(box, col_metal)
	draw_rect(box, Color("#15161A"), false, 1.2)
	draw_circle(center, 9.0, col_dark)

	# Pás giratórias
	for i in range(4):
		var a: float = fan_angle + float(i) * TAU / 4.0
		var p1 := center + Vector2(cos(a - 0.25), sin(a - 0.25)) * 2.0
		var p2 := center + Vector2(cos(a - 0.15), sin(a - 0.15)) * 7.5
		var p3 := center + Vector2(cos(a + 0.15), sin(a + 0.15)) * 7.5
		var p4 := center + Vector2(cos(a + 0.25), sin(a + 0.25)) * 2.0
		draw_colored_polygon(PackedVector2Array([p1, p2, p3, p4]), col_blade)

	draw_circle(center, 2.5, Color("#343A40"))

func _draw_wall_radio_item(pos: Vector2, act3: bool) -> void:
	var r := Rect2(pos.x, pos.y + 4, 18, 12)
	var col_body := Color("#2B3344") if not act3 else Color("#30333A")
	draw_rect(r, col_body)
	draw_rect(r, Color("#14161C"), false, 1.0)
	draw_line(Vector2(pos.x + 14, pos.y + 4), Vector2(pos.x + 14, pos.y - 4), Color("#14161C"), 1.5) # Antena
	draw_rect(Rect2(pos.x + 2, pos.y + 6, 8, 4), Color("#80ED99") if not act3 else Color("#555B58")) # Display
	var led_blink := int(dust_time * 3.0) % 2 == 0
	var led_col := (Color("#FF595E") if led_blink else Color("#FFCA3A")) if not act3 else Color("#555B58")
	draw_circle(Vector2(pos.x + 13, pos.y + 8), 1.3, led_col)

func _draw_floor_cohesion(act3: bool) -> void:
	# Verniz quente sutil sobre a madeira (dá profundidade e unifica o tom)
	draw_rect(Rect2(96, 76, 448, 248), Color(1.0, 0.88, 0.66, 0.05) if not act3 else Color(0.90, 0.92, 0.96, 0.04))
	# Zona da cozinha: leve escurecimento + limiar discreto (sem bloco de cor)
	draw_rect(Rect2(440, 76, 104, 248), Color(0.16, 0.10, 0.05, 0.16) if not act3 else Color(0.10, 0.10, 0.12, 0.16))
	draw_rect(Rect2(438, 76, 3, 248), Color(0.22, 0.14, 0.09, 0.22) if not act3 else Color(0.12, 0.12, 0.14, 0.22))
	# Vinheta de contato nas bordas do piso
	_draw_edge_vignette(Rect2(96, 76, 448, 248), Color(0.03, 0.02, 0.05, 0.28), 28.0)

func _draw_edge_vignette(rect: Rect2, col: Color, width: float) -> void:
	var clear := Color(col.r, col.g, col.b, 0.0)
	var x0 := rect.position.x
	var y0 := rect.position.y
	var x1 := rect.position.x + rect.size.x
	var y1 := rect.position.y + rect.size.y
	draw_polygon(PackedVector2Array([Vector2(x0, y0), Vector2(x1, y0), Vector2(x1, y0 + width), Vector2(x0, y0 + width)]), PackedColorArray([col, col, clear, clear]))
	draw_polygon(PackedVector2Array([Vector2(x0, y1 - width), Vector2(x1, y1 - width), Vector2(x1, y1), Vector2(x0, y1)]), PackedColorArray([clear, clear, col, col]))
	draw_polygon(PackedVector2Array([Vector2(x0, y0), Vector2(x0 + width, y0), Vector2(x0 + width, y1), Vector2(x0, y1)]), PackedColorArray([col, clear, clear, col]))
	draw_polygon(PackedVector2Array([Vector2(x1 - width, y0), Vector2(x1, y0), Vector2(x1, y1), Vector2(x1 - width, y1)]), PackedColorArray([clear, col, col, clear]))

func _draw_ambient_light(act3: bool, night: bool) -> void:
	var room := Rect2(80, 14, 480, 326)
	if act3:
		draw_rect(room, Color(0.55, 0.58, 0.64, 0.08))
	elif night:
		draw_rect(room, Color(0.30, 0.42, 0.72, 0.12))
	else:
		draw_rect(room, Color(1.0, 0.86, 0.60, 0.07))

func _ellipse_points(center: Vector2, radii: Vector2) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in range(16):
		var a: float = TAU * float(i) / 16.0
		pts.append(center + Vector2(cos(a) * radii.x, sin(a) * radii.y))
	return pts

func _draw_soft_glow(center: Vector2, radii: Vector2, col: Color) -> void:
	var layers := 6
	for i in range(layers):
		var t := float(i) / float(layers - 1)
		var r := radii * (1.0 - t * 0.85)
		var a := col.a * (0.35 + t * 0.65) / float(layers) * 2.2
		draw_colored_polygon(_ellipse_points(center, r), Color(col.r, col.g, col.b, a))

func _draw_window_sunlight(act3: bool, night: bool) -> void:
	var wx := 324.0
	var ww := 42.0
	var cx := wx + ww * 0.5

	if night:
		_draw_soft_glow(Vector2(cx, 126), Vector2(52, 26), Color(0.50, 0.70, 0.95, 0.28))
		return
	if act3:
		_draw_soft_glow(Vector2(cx, 118), Vector2(44, 22), Color(0.72, 0.76, 0.82, 0.16))
		return

	# Feixe de sol suave em camadas (sem aresta dura)
	for i in range(3):
		var spread := float(i) * 12.0
		var bottom := 150.0 + float(i) * 14.0
		draw_colored_polygon(PackedVector2Array([
			Vector2(wx + 3.0 - spread, 64),
			Vector2(wx + ww - 3.0 + spread, 64),
			Vector2(wx + ww + 18.0 + spread * 2.0, bottom),
			Vector2(wx - 12.0 - spread * 2.0, bottom)
		]), Color(1.0, 0.94, 0.70, 0.05))
	# Poça difusa de luz no piso e brilho na parede
	_draw_soft_glow(Vector2(cx, 126), Vector2(48, 24), Color(1.0, 0.92, 0.62, 0.34))
	_draw_soft_glow(Vector2(cx, 50), Vector2(40, 16), Color(1.0, 0.90, 0.58, 0.30))
	# Poeira flutuando no feixe de luz
	for i in range(10):
		var phase := dust_time * 1.4 + float(i) * 0.7
		var dx := wx + 3.0 + fmod(float(i) * 4.7 + sin(phase) * 3.0, ww - 6.0)
		var dy := 78.0 + float((i * 21) % 76) + cos(phase * 0.8) * 2.4
		draw_circle(Vector2(dx, dy), 1.0, Color(1.0, 0.98, 0.82, 0.42))
