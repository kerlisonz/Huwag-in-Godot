extends Node

signal switch_changed(switch_key: String, value: bool)
signal variable_changed(var_name: String, value: Variant)
signal perception_changed(mode: int)
signal time_of_day_changed(is_afternoon: bool)
signal notification_requested(text: String)
signal hp_changed(current_hp: int, max_hp: int)
signal outfit_changed(outfit_id: String)
signal level_load_requested(scene_path: String, spawn_tag: String)

signal higher_dose_changed(active: bool)

enum PerceptionMode {
	FILTERED_MORNING = 0,
	FILTERED_AFTERNOON = 1,
	UNFILTERED_ACT3 = 2,
}

# Switches canônicos de Huwag (Atos 1, 2 e 3)
var switches: Dictionary = {
	"001_Porta_Bombeiros_1a_vez": false,
	"002_Chefe_Ato1_apresentado": false,
	"003_Ovos_sem_derrotar": false,
	"004_Ovos_e_derrotou": false,
	"005_Chefe_liberou_cidade": false,
	"006_Dormir_avancou_para_Ato2": false,
	"007_Chefe_Ato2_apresentado": false,
	"008_Missao_chave1_aberta": false,
	"009_Missao_chave1_concluida": false,
	"010_Missao_chave2_aberta": false,
	"011_Missao_chave2_concluida": false,
	"012_Missao_chave3_aberta": false,
	"013_Missao_chave3_concluida": false,
	"014_Floresta_liberada": false,
	"015_Floresta_em_chamas": false,
	"016_Magia_de_agua_obtida": false,
	"017_Gatinho_encontrado": false,
	"018_Gatinho_devolvido": false,
	"019_Ato2_concluido": false,
	"020_Alguma_missao_completa": false,
	"021_Recompensa_entregue": false,
	# Switches do Ato 3
	"022_Ato3_iniciado": false,
	"023_Ato3_pesadelo_vhs_concluido": false,
	"024_Ato3_revelacao_reyes": false,
	"025_Ato3_confronto_lagoa": false,
	"026_Jogo_finalizado": false,
}

var variables: Dictionary = {
	"Ato": 1,
	"Missoes_concluidas": 0,
}

var self_switches: Dictionary = {}
var inventory: Dictionary = {}
var is_afternoon: bool = false
var perception_mode: int = PerceptionMode.FILTERED_MORNING
var dialogue_active: bool = false
var spawn_tag: String = "default"
var current_scene_path: String = "res://scenes/levels/RoomHuwag.tscn"
var saved_player_pos: Vector2 = Vector2.ZERO

var player_hp: int = 100
var player_max_hp: int = 100
var water_boss_defeated: bool = false
var equipped_outfit: String = "casual" # "casual" (Imagem 3) ou "bfp" (Uniforme de Bombeiro)

# Configurações de acessibilidade e preferência
var setting_flash_reduction: bool = false
var setting_vhs_effects: bool = true
var setting_screen_shake: float = 1.0

signal window_mode_changed(is_fullscreen: bool)

func is_fullscreen() -> bool:
	return DisplayServer.window_get_mode() in [DisplayServer.WINDOW_MODE_FULLSCREEN, DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN]

func toggle_fullscreen() -> void:
	set_fullscreen(not is_fullscreen())

func set_fullscreen(fullscreen: bool) -> void:
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	window_mode_changed.emit(fullscreen)

const SAVE_PATH := "user://huwag_save.json"

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func reset_to_new_game() -> void:
	for k in switches.keys():
		switches[k] = false
	variables = {
		"Ato": 1,
		"Missoes_concluidas": 0,
	}
	self_switches.clear()
	inventory.clear()
	is_afternoon = false
	perception_mode = PerceptionMode.FILTERED_MORNING
	dialogue_active = false
	spawn_tag = "initial"
	current_scene_path = "res://scenes/levels/RoomHuwag.tscn"
	saved_player_pos = Vector2.ZERO
	player_hp = 100
	player_max_hp = 100
	water_boss_defeated = false
	equipped_outfit = "casual"
	hp_changed.emit(player_hp, player_max_hp)
	perception_changed.emit(perception_mode)
	time_of_day_changed.emit(false)
	outfit_changed.emit(equipped_outfit)

func set_equipped_outfit(outfit_id: String, notify: bool = true) -> void:
	var norm := "bfp" if outfit_id.to_lower() == "bfp" else "casual"
	if equipped_outfit == norm:
		return
	equipped_outfit = norm
	outfit_changed.emit(equipped_outfit)
	if notify:
		var label := "Uniforme de Bombeiro (BFP)" if equipped_outfit == "bfp" else "Roupa Casual (Jaqueta Escura)"
		notification_requested.emit("Roupa equipada: " + label)

func toggle_outfit() -> void:
	set_equipped_outfit("bfp" if equipped_outfit == "casual" else "casual", true)

func get_switch(key: String) -> bool:
	return bool(switches.get(key, false))

func set_switch(key: String, value: bool) -> void:
	var prev: bool = bool(switches.get(key, false))
	switches[key] = value
	if prev != value:
		switch_changed.emit(key, value)

func get_var(var_name: String, default_value: Variant = 0) -> Variant:
	return variables.get(var_name, default_value)

func set_var(var_name: String, value: Variant) -> void:
	variables[var_name] = value
	variable_changed.emit(var_name, value)

func get_self_switch(event_id: String, ch: String = "A") -> bool:
	var full_key := "%s:%s" % [event_id, ch]
	return bool(self_switches.get(full_key, false))

func set_self_switch(event_id: String, ch: String, value: bool) -> void:
	var full_key := "%s:%s" % [event_id, ch]
	self_switches[full_key] = value

func add_item(item_id: String, amount: int = 1) -> void:
	var current: int = int(inventory.get(item_id, 0))
	inventory[item_id] = maxi(0, current + amount)
	variable_changed.emit("inventory_" + item_id, inventory[item_id])

func get_item_count(item_id: String) -> int:
	return int(inventory.get(item_id, 0))

func has_item(item_id: String) -> bool:
	return get_item_count(item_id) > 0

func damage_player(amount: int) -> void:
	player_hp = clampi(player_hp - amount, 1, player_max_hp)
	hp_changed.emit(player_hp, player_max_hp)

func heal_player(amount: int) -> void:
	player_hp = clampi(player_hp + amount, 1, player_max_hp)
	hp_changed.emit(player_hp, player_max_hp)

func use_soothing_drop() -> bool:
	var count := get_item_count("gota_calmante")
	if count <= 0 or player_hp >= player_max_hp:
		return false
	add_item("gota_calmante", -1)
	heal_player(35)
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").play_sfx("ui_select")
	notification_requested.emit("Usou Cápsula Calmante (+35 HP)")
	return true

## Equivalente ao Common Event "Virar_Tarde" dos documentos (switches 003, 004, 020)
func trigger_turn_afternoon() -> void:
	is_afternoon = true
	if int(variables.get("Ato", 1)) < 3:
		set_perception_mode(PerceptionMode.FILTERED_AFTERNOON)
	time_of_day_changed.emit(true)
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").play_ambience("afternoon_ambience")

## Avança para o Ato 2 ao dormir no fim do Ato 1 (switch 006)
func is_higher_dose() -> bool:
	return int(get_var("Ato", 1)) == 2 and get_switch("006b_Dose_maior_pilulas")


func set_higher_dose(active: bool) -> void:
	set_switch("006c_Dose_escolhida_Ato2", true)
	set_switch("006b_Dose_maior_pilulas", active)
	higher_dose_changed.emit(active)
	perception_changed.emit(perception_mode)


func advance_to_act_2() -> void:
	set_switch("006_Dormir_avancou_para_Ato2", true)
	set_switch("006b_Dose_maior_pilulas", false)
	set_switch("006c_Dose_escolhida_Ato2", false)
	set_var("Ato", 2)
	is_afternoon = false
	player_hp = player_max_hp
	hp_changed.emit(player_hp, player_max_hp)
	set_perception_mode(PerceptionMode.FILTERED_MORNING)
	higher_dose_changed.emit(false)
	time_of_day_changed.emit(false)
	autosave(current_scene_path, "initial")
	notification_requested.emit("Ato II Iniciado — Um novo turno em Agdangan")

## Avança para o Ato 3 (Revelação sem filtro) após concluir o Ato 2 e descansar
func advance_to_act_3() -> void:
	set_switch("022_Ato3_iniciado", true)
	set_var("Ato", 3)
	is_afternoon = false
	set_perception_mode(PerceptionMode.UNFILTERED_ACT3)
	time_of_day_changed.emit(false)
	autosave(current_scene_path, "from_act2")
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").play_ambience("act3_ambience")
		get_node("/root/AudioManager").play_sfx("vhs_glitch")
	notification_requested.emit("Ato III — O efeito dos comprimidos passou")

## Avança ciclicamente entre os Atos (Ato 1 -> Ato 2 -> Ato 3 -> Ato 1) via atalho F10 ou depuração
func advance_act() -> int:
	var current_act: int = int(variables.get("Ato", 1))
	match current_act:
		1:
			advance_to_act_2()
			return 2
		2:
			advance_to_act_3()
			return 3
		_:
			set_switch("006_Dormir_avancou_para_Ato2", false)
			set_switch("007_Chefe_Ato2_apresentado", false)
			set_switch("014_Floresta_liberada", false)
			set_switch("015_Floresta_em_chamas", false)
			set_switch("019_Ato2_concluido", false)
			set_switch("022_Ato3_iniciado", false)
			set_switch("023_Ato3_pesadelo_vhs_concluido", false)
			set_switch("024_Ato3_revelacao_reyes", false)
			set_switch("025_Ato3_confronto_lagoa", false)
			set_switch("026_Jogo_finalizado", false)
			set_var("Ato", 1)
			set_var("Missoes_concluidas", 0)
			is_afternoon = false
			player_hp = player_max_hp
			hp_changed.emit(player_hp, player_max_hp)
			set_perception_mode(PerceptionMode.FILTERED_MORNING)
			time_of_day_changed.emit(false)
			autosave(current_scene_path, "initial")
			if has_node("/root/AudioManager"):
				get_node("/root/AudioManager").play_ambience("day_ambience")
				get_node("/root/AudioManager").play_bgm("day_theme", 1.0)
			notification_requested.emit("Ato I Iniciado — Manhã Filtrada")
			return 1

## Conclui uma das 3 missões opcionais do Ato 2
func complete_optional_mission(switch_done_key: String) -> void:
	if get_switch(switch_done_key):
		return
	set_switch(switch_done_key, true)
	var done_count: int = int(get_var("Missoes_concluidas", 0)) + 1
	set_var("Missoes_concluidas", done_count)
	if not get_switch("020_Alguma_missao_completa"):
		set_switch("020_Alguma_missao_completa", true)
		trigger_turn_afternoon()
		notification_requested.emit("O tempo passou (Fim de Tarde). Retorne ao Quartel.")
	autosave(current_scene_path, spawn_tag)

func set_perception_mode(mode: int) -> void:
	perception_mode = clampi(mode, 0, 2)
	perception_changed.emit(perception_mode)

func is_unfiltered_act3() -> bool:
	return perception_mode == PerceptionMode.UNFILTERED_ACT3 or int(variables.get("Ato", 1)) >= 3

func cycle_perception_preview() -> void:
	var next_mode: int = (perception_mode + 1) % 3
	set_perception_mode(next_mode)
	var labels := [
		"Ato 1–2: Manhã Filtrada (Efeito dos Comprimidos)",
		"Ato 1–2: Fim de Tarde (Virar_Tarde)",
		"Ato 3: Realidade Sem Filtro (Monocromático/Desgastado)"
	]
	notification_requested.emit(labels[next_mode])

# --- SAVE / LOAD SYSTEM ---

func has_save_file() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func get_save_summary() -> Dictionary:
	if not has_save_file():
		return {}
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	var data: Dictionary = parsed
	var ato: int = int(data.get("variables", {}).get("Ato", 1))
	var scene: String = str(data.get("current_scene", "Quarto"))
	var place := "Quarto de Huwag"
	if scene.find("Street") != -1:
		place = "Rua de Agdangan"
	elif scene.find("Station") != -1:
		place = "Quartel BFP"
	elif scene.find("trail") != -1 or scene.find("Corridor") != -1:
		place = "Trilha da Floresta"
	elif scene.find("clearing") != -1 or scene.find("Clearing") != -1:
		place = "Clareira da Lagoa"
	elif scene.find("vhs_memory") != -1:
		place = "Memória / Pesadelo"
	return {
		"ato": ato,
		"place": place,
		"hp": int(data.get("player_hp", 100)),
		"date": str(data.get("timestamp", "Recente"))
	}

func autosave(scene_path: String = "", tag: String = "", pos: Vector2 = Vector2.ZERO) -> bool:
	if scene_path != "":
		current_scene_path = scene_path
	if tag != "":
		spawn_tag = tag
	if pos != Vector2.ZERO:
		saved_player_pos = pos
	return save_game()

func save_game() -> bool:
	var data := {
		"version": 2,
		"timestamp": Time.get_datetime_string_from_system(),
		"current_scene": current_scene_path,
		"spawn_tag": spawn_tag,
		"player_pos_x": saved_player_pos.x,
		"player_pos_y": saved_player_pos.y,
		"switches": switches,
		"variables": variables,
		"self_switches": self_switches,
		"inventory": inventory,
		"is_afternoon": is_afternoon,
		"perception_mode": perception_mode,
		"player_hp": player_hp,
		"water_boss_defeated": water_boss_defeated,
		"equipped_outfit": equipped_outfit,
		"settings": {
			"flash_reduction": setting_flash_reduction,
			"vhs_effects": setting_vhs_effects,
			"screen_shake": setting_screen_shake
		}
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Erro ao abrir arquivo para salvar: %s" % SAVE_PATH)
		return false
	file.store_string(JSON.stringify(data, "\t"))
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").play_sfx("save_chime")
	return true

func load_game() -> bool:
	if not has_save_file():
		return false
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return false
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return false
	var data: Dictionary = parsed

	if data.has("switches") and typeof(data["switches"]) == TYPE_DICTIONARY:
		for k in data["switches"].keys():
			switches[k] = bool(data["switches"][k])
	if data.has("variables") and typeof(data["variables"]) == TYPE_DICTIONARY:
		for k in data["variables"].keys():
			variables[k] = data["variables"][k]
	if data.has("self_switches") and typeof(data["self_switches"]) == TYPE_DICTIONARY:
		self_switches = data["self_switches"].duplicate()
	if data.has("inventory") and typeof(data["inventory"]) == TYPE_DICTIONARY:
		inventory = data["inventory"].duplicate()

	is_afternoon = bool(data.get("is_afternoon", false))
	player_hp = int(data.get("player_hp", 100))
	water_boss_defeated = bool(data.get("water_boss_defeated", false))
	current_scene_path = str(data.get("current_scene", "res://scenes/levels/RoomHuwag.tscn"))
	spawn_tag = str(data.get("spawn_tag", "initial"))
	var px: float = float(data.get("player_pos_x", 0.0))
	var py: float = float(data.get("player_pos_y", 0.0))
	saved_player_pos = Vector2(px, py)

	set_equipped_outfit(str(data.get("equipped_outfit", "casual")), false)
	set_perception_mode(int(data.get("perception_mode", PerceptionMode.FILTERED_MORNING)))
	higher_dose_changed.emit(is_higher_dose())

	if data.has("settings") and typeof(data["settings"]) == TYPE_DICTIONARY:
		var s: Dictionary = data["settings"]
		setting_flash_reduction = bool(s.get("flash_reduction", false))
		setting_vhs_effects = bool(s.get("vhs_effects", true))
		setting_screen_shake = float(s.get("screen_shake", 1.0))

	hp_changed.emit(player_hp, player_max_hp)
	return true
