extends Node2D

# VHSMemoryMinigame - Sequência Psicológica de Trauma / Memória do Ato 3
# Estética retro VHS inspirada em minigames narrativos de terror psicológico
# Proporção CRT, scanlines analógicas, paleta monocromática de fuligem e brasas
# Desafio justo de labirinto, desvio de fagulhas telegrafadas e fragmentos de memória.

signal request_level_change(target_scene: String, spawn_tag: String)
signal request_dialogue(pages: Array, callback: Callable)

@onready var player: CharacterBody2D = $YSortEntities/Player
@onready var vhs_filter: ColorRect = $CanvasLayer/VHSFilter
@onready var fragments_label: Label = get_node_or_null("CanvasLayer/UI/VBox/FragmentsLabel")
@onready var objective_label: Label = get_node_or_null("CanvasLayer/UI/ObjectiveLabel")
@onready var hazards_root: Node2D = $Hazards
@onready var interactables_root: Node2D = $Interactables
@onready var exit_door: Area2D = $ExitDoor

var _collected_fragments: int = 0
const TOTAL_FRAGMENTS := 4
var _hazard_timers: Array[float] = [0.0, 0.4, 0.8, 1.2, 1.6]
var _shake_intensity: float = 0.0

func _ready() -> void:
	# Configura posição inicial de Huwag
	if player:
		player.position = Vector2(80, 180)
		if player.has_method("set_camera_limits"):
			player.set_camera_limits(Rect2i(0, 0, 640, 360))

	# Conecta saída do pesadelo
	if exit_door:
		exit_door.body_entered.connect(_on_exit_door_entered)

	_setup_boundaries()
	_setup_memory_fragments()
	_update_ui()

	# Trilha de memória analógica com wow & flutter
	if has_node("/root/AudioManager"):
		var am = get_node("/root/AudioManager")
		am.play_bgm("vhs_memory_bgm", 1.0)
		am.play_ambience("act3_ambience", 1.5)
		am.play_sfx("vhs_glitch")

	# Diálogo de entrada no pesadelo
	call_deferred("_trigger_intro_dialogue")

func _process(delta: float) -> void:
	# Atualiza perigos de fogo/fagulhas com aviso visual telegrafado
	for i in range(_hazard_timers.size()):
		_hazard_timers[i] += delta
		if _hazard_timers[i] >= 2.0:
			_hazard_timers[i] = 0.0

	queue_redraw()

	if _shake_intensity > 0.0:
		_shake_intensity = maxf(0.0, _shake_intensity - delta * 4.0)
		if player and player.get_node_or_null("Camera2D"):
			var cam: Camera2D = player.get_node("Camera2D")
			cam.offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * _shake_intensity * 6.0

func _draw() -> void:
	# Desenha visual retro minimalista do pesadelo (linhas de fuligem, paredes e fagulhas)
	# Grade do labirinto
	var floor_col := Color(0.08, 0.09, 0.11, 1.0)
	var wall_col := Color(0.20, 0.22, 0.26, 1.0)
	var ember_warn_col := Color(0.75, 0.35, 0.15, 0.45)
	var ember_fire_col := Color(0.95, 0.85, 0.40, 0.90)

	# Pisos dos corredores
	draw_rect(Rect2(40, 50, 560, 260), floor_col)

	# Fagulhas periódicas telegrafadas em pontos do labirinto
	var hazard_pos = [
		Vector2(180, 110), Vector2(280, 240), Vector2(360, 130),
		Vector2(440, 230), Vector2(250, 180)
	]

	for i in range(hazard_pos.size()):
		var p: Vector2 = hazard_pos[i]
		var t: float = _hazard_timers[i]
		if t < 1.2:
			# Fase de aviso (telegraph sutil): poça de fumaça e faíscas fracas
			draw_circle(p, 16.0, ember_warn_col)
		else:
			# Fase de chamas ativas (dá dano se o jogador tocar)
			draw_circle(p, 20.0, ember_fire_col)
			if player and player.position.distance_to(p) < 22.0:
				_damage_player_hazard()

func _damage_player_hazard() -> void:
	_shake_intensity = 1.0
	GameState.damage_player(10)
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").play_sfx("player_hurt")
	if player:
		# Empurra ligeiramente para trás
		player.position += (player.position - Vector2(320, 180)).normalized() * 12.0

func _trigger_intro_dialogue() -> void:
	var pages: Array[Dictionary] = [
		{
			"speaker": "Voz do Passado",
			"is_monologue": true,
			"text": "[FITA VHS — REGISTRO DE CHAMADA · AGDANGAN 2025]\n\"Atenção todas as unidades da BFP... O incêndio na fábrica velha saiu do controle. Onde está o Huwag?\""
		},
		{
			"speaker": "Huwag Matitiis",
			"expression": "scared",
			"is_monologue": true,
			"text": "Essa fumaça... Eu conheço esse cheiro. Não são monstros... É a memória daquela noite que eu tentei apagar com os remédios."
		}
	]
	request_dialogue.emit(pages, Callable())

func _setup_boundaries() -> void:
	var body := StaticBody2D.new()
	body.name = "MazeWalls"
	body.collision_layer = 1
	add_child(body)

	# Perímetro externo
	_add_box(body, Rect2(0, 0, 640, 50))
	_add_box(body, Rect2(0, 310, 640, 50))
	_add_box(body, Rect2(0, 50, 40, 260))
	_add_box(body, Rect2(600, 50, 40, 260))

	# Divisórias internas do labirinto de memórias
	_add_box(body, Rect2(140, 50, 16, 170))
	_add_box(body, Rect2(220, 140, 16, 170))
	_add_box(body, Rect2(310, 50, 16, 160))
	_add_box(body, Rect2(400, 150, 16, 160))
	_add_box(body, Rect2(490, 50, 16, 170))

func _add_box(body: StaticBody2D, rect: Rect2) -> void:
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	col.shape = shape
	col.position = rect.position + rect.size * 0.5
	body.add_child(col)

func _setup_memory_fragments() -> void:
	_create_fragment("frag_1", Vector2(100, 260), "1. O Alarme Esquecido")
	_create_fragment("frag_2", Vector2(180, 80), "2. A Ordem de Evacuação")
	_create_fragment("frag_3", Vector2(360, 260), "3. O Companheiro na Fumaça")
	_create_fragment("frag_4", Vector2(450, 80), "4. A Sobrevivência e a Culpa")

func _create_fragment(id: String, pos: Vector2, title_text: String) -> void:
	var inter := Interactable.new()
	inter.name = id
	inter.interaction_id = id
	inter.title = title_text
	inter.verb = "Recuperar Memória"
	inter.position = pos

	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 24.0
	col.shape = shape
	inter.add_child(col)

	# Visual do fragmento (orbe de luz trêmula)
	var sprite := ColorRect.new()
	sprite.custom_minimum_size = Vector2(12, 12)
	sprite.position = Vector2(-6, -6)
	sprite.color = Color(0.95, 0.82, 0.45, 0.85)
	inter.add_child(sprite)

	inter.interacted.connect(func(_i: Interactable): _on_fragment_interacted(id, inter))
	interactables_root.add_child(inter)

func _on_fragment_interacted(id: String, node: Interactable) -> void:
	if not node.visible:
		return
	node.visible = false
	_collected_fragments += 1
	_shake_intensity = 0.5
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").play_sfx("ui_select")

	var texts := {
		"frag_1": [
			{"speaker": "Memória 1 — Rádio BFP", "text": "\"Alarme geral em Agdangan! As chamas bloquearam o setor sul. Equipe de Huwag, recuem imediatamente!\""},
			{"speaker": "Huwag", "expression": "worried", "text": "Eu me lembro... O rádio chiava tanto que mal dava para entender as coordenadas."}
		],
		"frag_2": [
			{"speaker": "Memória 2 — Capitão Reyes", "text": "\"Huwag, tire seus homens daí agora! Não dê uma de herói sozinho, rapaz! O teto de zinco está cedendo!\""},
			{"speaker": "Huwag", "expression": "scared", "text": "O Capitão estava gritando pelo megafone... Mas eu achei que ainda dava tempo de voltar para a última sala."}
		],
		"frag_3": [
			{"speaker": "Memória 3 — Bombeiro Ato", "text": "\"Vai, Huwag! Corre pela janela! Não olha para trás, irmão! Promete que vai viver!\""},
			{"speaker": "Huwag", "expression": "tired", "text": "A mão do Ato soltou da minha na fumaça preta... Ele me empurrou para a claraboia."}
		],
		"frag_4": [
			{"speaker": "Memória 4 — A Revelação", "text": "\"Huwag Matitiis foi o único resgatado com vida dos escombros. Diagnóstico: choque traumático severo e amnésia dissociativa medicada.\""},
			{"speaker": "Huwag", "expression": "unfiltered", "text": "Os comprimidos... Eles nunca foram para curar o corpo. Foram para me fazer ver um mundo onde ninguém se queimou, onde todo chamado termina bem."}
		]
	}

	var pages: Array = texts.get(id, [])
	request_dialogue.emit(pages, func(_choice: int):
		_update_ui()
		if _collected_fragments >= TOTAL_FRAGMENTS:
			_unlock_exit()
	)

func _unlock_exit() -> void:
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").play_sfx("save_chime")
	GameState.set_switch("023_Ato3_pesadelo_vhs_concluido", true)
	if objective_label:
		objective_label.text = "PORTA DE SAÍDA ABERTA AO LESTE ► ENCARE A REALIDADE"
		objective_label.modulate = Color(0.95, 0.90, 0.50, 1.0)
	if exit_door:
		exit_door.monitoring = true

func _on_exit_door_entered(body: Node2D) -> void:
	if body.is_in_group("player") and _collected_fragments >= TOTAL_FRAGMENTS:
		# Sai do pesadelo e acorda na Agdangan sem filtro do Ato 3
		request_level_change.emit("res://scenes/levels/RoomHuwag.tscn", "from_nightmare")

func _update_ui() -> void:
	if fragments_label:
		fragments_label.text = "Fragmentos de Memória: %d / %d" % [_collected_fragments, TOTAL_FRAGMENTS]
