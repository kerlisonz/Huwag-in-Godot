extends Node

signal switch_changed(switch_key: String, value: bool)
signal variable_changed(var_name: String, value: Variant)
signal perception_changed(mode: int)
signal time_of_day_changed(is_afternoon: bool)
signal notification_requested(text: String)
signal hp_changed(current_hp: int, max_hp: int)
signal stamina_changed(current_stamina: float, max_stamina: float)
signal outfit_changed(outfit_id: String)
signal level_load_requested(scene_path: String, spawn_tag: String)

signal higher_dose_changed(active: bool)
signal clock_minute_changed(total_minutes: int, formatted_hhmm: String)
signal day_period_changed(period_id: String)
signal sleep_curfew_triggered(current_act: int)
signal task_state_changed(task_id: String, active: bool, completed: bool)
signal checkpoint_saved(snapshot: Dictionary)
signal checkpoint_restored(snapshot: Dictionary)

@export var in_game_minutes_per_real_second: float = 2.0
@export var day_start_minutes: int = 390 # 06:30
@export var sleep_trigger_minutes: int = 1380 # 23:00

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
	"006b_Dose_maior_pilulas": false,
	"006c_Dose_escolhida_Ato2": false,
	"006d_Enfermeira_reverteu_dose": false,
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
	"022b_Ato3_despertar_visto": false,
	"023_Ato3_pesadelo_vhs_concluido": false,
	"024_Ato3_revelacao_reyes": false,
	"025_Ato3_confronto_lagoa": false,
	"026_Jogo_finalizado": false,
}

var variables: Dictionary = {
	"Ato": 1,
	"Missoes_concluidas": 0,
	"Intoxicacao": 0,
}

var self_switches: Dictionary = {}
var inventory: Dictionary = {}
var is_afternoon: bool = false
var clock_minutes: int = 390
var clock_paused: bool = false
var sleep_transition_active: bool = false
var _clock_accum: float = 0.0
var _last_emitted_period: String = "morning"
var perception_mode: int = PerceptionMode.FILTERED_MORNING
var dialogue_active: bool = false
var dialogue_cooldown: float = 0.0
var spawn_tag: String = "default"
var current_scene_path: String = "res://scenes/levels/RoomHuwag.tscn"
var saved_player_pos: Vector2 = Vector2.ZERO
var is_player_defeated: bool = false

# Snapshot leve do último checkpoint seguro (entrada de mapa, novo dia ou evento importante)
var _last_checkpoint: Dictionary = {}
var _pending_checkpoint_spawn_pos: Vector2 = Vector2.ZERO
var _has_pending_checkpoint_spawn: bool = false
var _is_restoring_checkpoint: bool = false

const CHECKPOINT_MILESTONE_SWITCHES := {
	"002_Chefe_Ato1_apresentado": true,
	"003_Ovos_sem_derrotar": true,
	"004_Ovos_e_derrotou": true,
	"005_Chefe_liberou_cidade": true,
	"007_Chefe_Ato2_apresentado": true,
	"014_Floresta_liberada": true,
	"016_Magia_de_agua_obtida": true,
	"017_Gatinho_encontrado": true,
	"018_Gatinho_devolvido": true,
	"019_Ato2_concluido": true,
	"024_Ato3_revelacao_reyes": true,
	"025_Ato3_confronto_lagoa": true,
}

var player_hp: int = 100
var player_max_hp: int = 100
var player_stamina: float = 100.0
var player_max_stamina: float = 100.0
var water_boss_defeated: bool = false
var equipped_outfit: String = "casual" # "casual" (Imagem 3) ou "bfp" (Uniforme de Bombeiro)

const FOREST_SANTELMO_TOTAL := 16
const ACT2_STREET_TASK_NPCS: Array[String] = ["NPC_Aling_Nena", "NPC_Mang_Carding", "NPC_Feirante"]
const ACT2_NORMAL_MISSION_SWITCHES: Array[String] = [
	"009_Missao_chave1_concluida",
	"011_Missao_chave2_concluida",
	"013_Missao_chave3_concluida",
]
var corrupted_mode: bool = false
var nurse_reverted_corrupted: bool = false
var act2_route_completed: String = "" # "normal", "corrupted", "reverted"
var day_number: int = 1
var active_tasks: Dictionary = {}
var completed_tasks: Dictionary = {}
var defeated_forest_santelmos: Dictionary = {}
var defeated_corrupted_npcs: Dictionary = {}

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
const SAVE_SLOTS_DIR := "user://saves"
const MAX_SAVE_SLOTS := 3

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_last_emitted_period = get_day_period(clock_minutes)


func _process(delta: float) -> void:
	if not dialogue_active and dialogue_cooldown > 0.0:
		dialogue_cooldown = maxf(0.0, dialogue_cooldown - delta)
	if not _should_advance_clock():
		return
	_clock_accum += delta * maxf(0.0, in_game_minutes_per_real_second)
	if _clock_accum >= 1.0:
		var step_mins := int(floor(_clock_accum))
		_clock_accum -= float(step_mins)
		advance_clock_minutes(step_mins, true)


func notify_dialogue_closed(cooldown_sec: float = 0.28) -> void:
	dialogue_active = false
	dialogue_cooldown = maxf(dialogue_cooldown, cooldown_sec)


func is_interaction_blocked() -> bool:
	return dialogue_active or sleep_transition_active or is_player_defeated or dialogue_cooldown > 0.0


func _should_advance_clock() -> bool:
	if clock_paused or dialogue_active or sleep_transition_active or is_player_defeated:
		return false
	if in_game_minutes_per_real_second <= 0.0:
		return false
	if current_scene_path.ends_with("vhs_memory_minigame.tscn") or current_scene_path.ends_with("EndingCredits.tscn") or current_scene_path.ends_with("TitleScreen.tscn"):
		return false
	var tree := get_tree()
	if tree == null or tree.paused:
		return false
	return tree.get_first_node_in_group("player") != null


func get_clock_minutes() -> int:
	return clock_minutes


func get_formatted_time(minutes_val: int = -1) -> String:
	var m := clock_minutes if minutes_val < 0 else clampi(minutes_val, 0, 1439)
	var hh := int(m / 60)
	var mm := int(m % 60)
	return "%02d:%02d" % [hh, mm]


func get_day_period(minutes_val: int = -1) -> String:
	var m := clock_minutes if minutes_val < 0 else clampi(minutes_val, 0, 1439)
	if m >= 360 and m < 720:
		return "morning"
	elif m >= 720 and m < 1080:
		return "afternoon"
	return "night"


func is_night_time() -> bool:
	return get_day_period(clock_minutes) == "night"


func get_afternoon_factor() -> float:
	var p := get_day_period(clock_minutes)
	if p == "morning":
		return clampf(float(clock_minutes - 660) / 60.0, 0.0, 1.0) * 0.20
	elif p == "afternoon":
		return lerpf(0.25, 0.72, clampf(float(clock_minutes - 720) / 360.0, 0.0, 1.0))
	return 0.25


func get_night_factor() -> float:
	if clock_minutes >= 1080:
		return lerpf(0.55, 1.0, clampf(float(clock_minutes - 1080) / 180.0, 0.0, 1.0))
	elif clock_minutes < 360:
		return 1.0
	elif clock_minutes >= 1020:
		return lerpf(0.0, 0.45, clampf(float(clock_minutes - 1020) / 60.0, 0.0, 1.0))
	return 0.0


func set_clock_minutes(new_minutes: int, emit_curfew: bool = true) -> void:
	var clamped := clampi(new_minutes, 0, 1439)
	var prev_period := _last_emitted_period
	clock_minutes = clamped
	var new_period := get_day_period(clock_minutes)

	if clock_minutes >= 720 and not is_afternoon:
		is_afternoon = true
		if int(variables.get("Ato", 1)) < 3 and not is_unfiltered_act3():
			set_perception_mode(PerceptionMode.FILTERED_AFTERNOON)
		time_of_day_changed.emit(true)
	elif clock_minutes >= 360 and clock_minutes < 720 and is_afternoon:
		is_afternoon = false
		if int(variables.get("Ato", 1)) < 3 and not is_unfiltered_act3():
			set_perception_mode(PerceptionMode.FILTERED_MORNING)
		time_of_day_changed.emit(false)

	clock_minute_changed.emit(clock_minutes, get_formatted_time(clock_minutes))
	if new_period != prev_period:
		_last_emitted_period = new_period
		day_period_changed.emit(new_period)

	if emit_curfew and clock_minutes >= sleep_trigger_minutes and not sleep_transition_active:
		sleep_curfew_triggered.emit(int(variables.get("Ato", 1)))


func advance_clock_minutes(delta_minutes: int, emit_curfew: bool = true) -> void:
	if delta_minutes <= 0:
		return
	set_clock_minutes(mini(1439, clock_minutes + delta_minutes), emit_curfew)


func reset_to_new_game() -> void:
	for k in switches.keys():
		switches[k] = false
	variables = {
		"Ato": 1,
		"Missoes_concluidas": 0,
		"Intoxicacao": 0,
	}
	self_switches.clear()
	inventory.clear()
	is_afternoon = false
	clock_minutes = day_start_minutes
	_clock_accum = 0.0
	clock_paused = false
	sleep_transition_active = false
	_last_emitted_period = "morning"
	perception_mode = PerceptionMode.FILTERED_MORNING
	dialogue_active = false
	dialogue_cooldown = 0.0
	is_player_defeated = false
	_last_checkpoint.clear()
	_pending_checkpoint_spawn_pos = Vector2.ZERO
	_has_pending_checkpoint_spawn = false
	_is_restoring_checkpoint = false
	spawn_tag = "initial"
	current_scene_path = "res://scenes/levels/RoomHuwag.tscn"
	saved_player_pos = Vector2.ZERO
	player_hp = 100
	player_max_hp = 100
	player_stamina = 100.0
	player_max_stamina = 100.0
	water_boss_defeated = false
	equipped_outfit = "casual"
	day_number = 1
	corrupted_mode = false
	nurse_reverted_corrupted = false
	act2_route_completed = ""
	active_tasks.clear()
	completed_tasks.clear()
	defeated_forest_santelmos.clear()
	defeated_corrupted_npcs.clear()
	hp_changed.emit(player_hp, player_max_hp)
	stamina_changed.emit(player_stamina, player_max_stamina)
	perception_changed.emit(perception_mode)
	time_of_day_changed.emit(false)
	clock_minute_changed.emit(clock_minutes, get_formatted_time(clock_minutes))
	day_period_changed.emit("morning")
	outfit_changed.emit(equipped_outfit)

func get_equipped_outfit_label() -> String:
	return "Uniforme de Bombeiro (BFP)" if equipped_outfit == "bfp" else "Roupa Casual (Jaqueta Escura)"

func set_equipped_outfit(outfit_id: String, notify: bool = true) -> void:
	var low := outfit_id.to_lower().strip_edges()
	var norm := "bfp" if (low == "bfp" or low == "bombeiro") else "casual"
	if equipped_outfit == norm:
		return
	equipped_outfit = norm
	outfit_changed.emit(equipped_outfit)
	if notify:
		notification_requested.emit("Roupa equipada: " + get_equipped_outfit_label())

func toggle_outfit() -> void:
	set_equipped_outfit("bfp" if equipped_outfit == "casual" else "casual", true)

func get_switch(key: String) -> bool:
	return bool(switches.get(key, false))

func set_switch(key: String, value: bool) -> void:
	var prev: bool = bool(switches.get(key, false))
	switches[key] = value
	_sync_task_for_switch(key, value)
	if prev != value:
		switch_changed.emit(key, value)
		if value and not _is_restoring_checkpoint and CHECKPOINT_MILESTONE_SWITCHES.has(key):
			save_checkpoint()

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
	player_hp = clampi(player_hp - maxi(0, amount), 0, player_max_hp)
	hp_changed.emit(player_hp, player_max_hp)

func heal_player(amount: int) -> void:
	player_hp = clampi(player_hp + maxi(0, amount), 0, player_max_hp)
	hp_changed.emit(player_hp, player_max_hp)

func restore_full_vitals() -> void:
	player_hp = player_max_hp
	player_stamina = player_max_stamina
	hp_changed.emit(player_hp, player_max_hp)
	stamina_changed.emit(player_stamina, player_max_stamina)

func clear_transient_state() -> void:
	dialogue_active = false
	dialogue_cooldown = 0.0
	sleep_transition_active = false
	clock_paused = false
	is_player_defeated = false

func consume_stamina(amount: float) -> void:
	var prev := player_stamina
	player_stamina = clampf(player_stamina - maxf(0.0, amount), 0.0, player_max_stamina)
	if not is_equal_approx(prev, player_stamina):
		stamina_changed.emit(player_stamina, player_max_stamina)

func recover_stamina(amount: float) -> void:
	var prev := player_stamina
	player_stamina = clampf(player_stamina + maxf(0.0, amount), 0.0, player_max_stamina)
	if not is_equal_approx(prev, player_stamina):
		stamina_changed.emit(player_stamina, player_max_stamina)

func has_stamina(minimum: float = 1.0) -> bool:
	return player_stamina >= minimum

func reset_stamina() -> void:
	player_stamina = player_max_stamina
	stamina_changed.emit(player_stamina, player_max_stamina)

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
	if clock_minutes < 960:
		clock_minutes = 960 # 16:00 (Fim de tarde)
	_last_emitted_period = get_day_period(clock_minutes)
	if int(variables.get("Ato", 1)) < 3:
		set_perception_mode(PerceptionMode.FILTERED_AFTERNOON)
	time_of_day_changed.emit(true)
	clock_minute_changed.emit(clock_minutes, get_formatted_time(clock_minutes))
	day_period_changed.emit(_last_emitted_period)
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").play_ambience("afternoon_ambience")

## Avança para o Ato 2 ao dormir no fim do Ato 1 (switch 006)
func is_higher_dose() -> bool:
	return int(get_var("Ato", 1)) == 2 and get_switch("006b_Dose_maior_pilulas")


func is_corrupted_mode() -> bool:
	return is_higher_dose()


func set_corrupted_mode(active: bool) -> void:
	set_higher_dose(active)


func get_intoxication_level() -> int:
	return int(variables.get("Intoxicacao", 2 if is_higher_dose() else 0))


func set_intoxication_level(level: int) -> void:
	var clamped := clampi(level, 0, 3)
	variables["Intoxicacao"] = clamped
	if clamped >= 2:
		corrupted_mode = (int(variables.get("Ato", 1)) == 2)
		switches["006c_Dose_escolhida_Ato2"] = true
		set_switch("006b_Dose_maior_pilulas", true)
		variable_changed.emit("Intoxicacao", clamped)
		higher_dose_changed.emit(true)
		perception_changed.emit(perception_mode)
	else:
		set_higher_dose(false)
		variables["Intoxicacao"] = clamped
		variable_changed.emit("Intoxicacao", clamped)


func set_act(act_number: int) -> void:
	var tox := (2 if is_higher_dose() else 1) if act_number == 2 else 0
	variables["Intoxicacao"] = tox
	set_var("Ato", act_number)
	corrupted_mode = is_higher_dose()
	variable_changed.emit("Intoxicacao", tox)


func set_higher_dose(active: bool) -> void:
	var act_num: int = int(variables.get("Ato", 1))
	var tox: int = 2 if active else (1 if act_num == 2 else 0)
	variables["Intoxicacao"] = tox
	corrupted_mode = active and (act_num == 2)
	set_switch("006c_Dose_escolhida_Ato2", true)
	set_switch("006b_Dose_maior_pilulas", active)
	variable_changed.emit("Intoxicacao", tox)
	higher_dose_changed.emit(active)
	perception_changed.emit(perception_mode)


func advance_to_act_2() -> void:
	day_number = maxi(2, day_number + 1)
	variables["Ato"] = 2
	variables["Intoxicacao"] = 1
	corrupted_mode = false
	nurse_reverted_corrupted = false
	act2_route_completed = ""
	defeated_corrupted_npcs.clear()
	set_switch("006_Dormir_avancou_para_Ato2", true)
	set_switch("006b_Dose_maior_pilulas", false)
	set_switch("006c_Dose_escolhida_Ato2", false)
	set_switch("006d_Enfermeira_reverteu_dose", false)
	variable_changed.emit("Ato", 2)
	variable_changed.emit("Intoxicacao", 1)
	is_afternoon = false
	clock_minutes = day_start_minutes
	_clock_accum = 0.0
	_last_emitted_period = "morning"
	player_hp = player_max_hp
	player_stamina = player_max_stamina
	hp_changed.emit(player_hp, player_max_hp)
	stamina_changed.emit(player_stamina, player_max_stamina)
	set_perception_mode(PerceptionMode.FILTERED_MORNING)
	higher_dose_changed.emit(false)
	time_of_day_changed.emit(false)
	clock_minute_changed.emit(clock_minutes, get_formatted_time(clock_minutes))
	day_period_changed.emit("morning")
	autosave(current_scene_path, "initial")
	save_checkpoint(current_scene_path, Vector2.ZERO, "initial")
	notification_requested.emit("06:30 — Um novo turno começa em Agdangan")


func start_task(task_id: String, title_text: String = "", target_count: int = 1) -> void:
	if bool(completed_tasks.get(task_id, false)):
		return
	if not active_tasks.has(task_id):
		active_tasks[task_id] = {
			"title": title_text if not title_text.is_empty() else task_id,
			"started_day": day_number,
			"progress": 0,
			"target": maxi(1, target_count),
		}
		task_state_changed.emit(task_id, true, false)


func update_task_progress(task_id: String, progress_val: int, title_text: String = "", target_count: int = 1) -> void:
	if bool(completed_tasks.get(task_id, false)):
		return
	if not active_tasks.has(task_id):
		start_task(task_id, title_text, target_count)
	var entry: Dictionary = active_tasks[task_id]
	var target_v: int = maxi(1, int(entry.get("target", target_count)))
	entry["progress"] = clampi(progress_val, 0, target_v)
	active_tasks[task_id] = entry
	task_state_changed.emit(task_id, true, false)


func complete_task(task_id: String) -> void:
	var already := bool(completed_tasks.get(task_id, false))
	completed_tasks[task_id] = true
	if active_tasks.has(task_id):
		active_tasks.erase(task_id)
	task_state_changed.emit(task_id, false, true)
	if not already and not _is_restoring_checkpoint:
		save_checkpoint()


func is_task_active(task_id: String) -> bool:
	return active_tasks.has(task_id) and not bool(completed_tasks.get(task_id, false))


func is_task_completed(task_id: String) -> bool:
	return bool(completed_tasks.get(task_id, false))


func get_active_tasks() -> Dictionary:
	return active_tasks.duplicate(true)


func advance_day_preserving_tasks() -> int:
	# Ao atingir 23:00 ou dormir entre dias sem concluir o Ato, avanca apenas o calendario
	# preservando switches de dialogo, tarefas ativas/concluidas e progresso na floresta.
	day_number += 1
	is_afternoon = false
	set_clock_minutes(day_start_minutes, false)
	if int(variables.get("Ato", 1)) < 3:
		set_perception_mode(PerceptionMode.FILTERED_MORNING)
	if player_hp < player_max_hp:
		heal_player(25)
	reset_stamina()
	save_checkpoint(current_scene_path, Vector2.ZERO, "initial")
	notification_requested.emit("Dia %d — 06:30 · Tarefas em andamento preservadas" % day_number)
	return day_number


func _sync_task_for_switch(key: String, value: bool) -> void:
	if not value:
		return
	match key:
		"002_Chefe_Ato1_apresentado":
			complete_task("ato1_apresentacao_reyes")
			start_task("ato1_ovos_floresta", "Coletar os ovos na Floresta Leste")
		"003_Ovos_sem_derrotar", "004_Ovos_e_derrotou":
			complete_task("ato1_ovos_floresta")
			start_task("ato1_reportar_chefe", "Reportar os ovos ao Capitão Reyes no Quartel")
		"005_Chefe_liberou_cidade":
			complete_task("ato1_reportar_chefe")
			start_task("ato1_dormir_quarto", "Descansar na cama em casa")
		"006_Dormir_avancou_para_Ato2":
			complete_task("ato1_dormir_quarto")
		"007_Chefe_Ato2_apresentado":
			if is_higher_dose():
				start_task("ato2_corrompido_rua", "Enfrentar os moradores distorcidos da rua", ACT2_STREET_TASK_NPCS.size())
			else:
				start_task("ato2_ocorrencias_cidade", "Ajudar os 3 moradores de Agdangan na rua", ACT2_NORMAL_MISSION_SWITCHES.size())
		"008_Missao_chave1_aberta":
			start_task("ato2_missao_1", "Fixar aviso BFP na praça da Igreja (Feirante)")
		"009_Missao_chave1_concluida":
			complete_task("ato2_missao_1")
		"010_Missao_chave2_aberta":
			start_task("ato2_missao_2", "Entregar suprimentos e água para Aling Nena")
		"011_Missao_chave2_concluida":
			complete_task("ato2_missao_2")
		"012_Missao_chave3_aberta":
			start_task("ato2_missao_3", "Recolher cesto e corda na areia para Mang Carding")
		"013_Missao_chave3_concluida":
			complete_task("ato2_missao_3")
		"014_Floresta_liberada":
			start_task("ato2_resgate_floresta", "Purificar os 16 Santelmos e resgatar o gatinho", FOREST_SANTELMO_TOTAL)
		"018_Gatinho_devolvido":
			complete_task("ato2_resgate_floresta")
		"019_Ato2_concluido":
			complete_task("ato2_ocorrencias_cidade")
			complete_task("ato2_corrompido_rua")
			start_task("ato2_dormir_quarto", "Descansar na cama em casa (Ato 3)")


func mark_corrupted_npc_defeated(npc_id: String) -> void:
	if npc_id.is_empty():
		return
	defeated_corrupted_npcs[npc_id] = true
	var count := get_defeated_corrupted_street_npc_count()
	if count >= ACT2_STREET_TASK_NPCS.size():
		update_task_progress("ato2_corrompido_rua", count, "Retornar ao Capitão Reyes no Quartel BFP", ACT2_STREET_TASK_NPCS.size())
		notification_requested.emit("Todos os moradores hostis da rua caíram. Retorne ao Capitão Reyes no Quartel.")
	elif ACT2_STREET_TASK_NPCS.has(npc_id):
		update_task_progress("ato2_corrompido_rua", count, "Enfrentar os moradores distorcidos da rua", ACT2_STREET_TASK_NPCS.size())
		notification_requested.emit("Morador derrotado (%d/%d)" % [count, ACT2_STREET_TASK_NPCS.size()])
	if not _is_restoring_checkpoint:
		save_checkpoint()


func is_corrupted_npc_defeated(npc_id: String) -> bool:
	return bool(defeated_corrupted_npcs.get(npc_id, false))


func get_defeated_corrupted_street_npc_count() -> int:
	var c := 0
	for nid in ACT2_STREET_TASK_NPCS:
		if bool(defeated_corrupted_npcs.get(nid, false)):
			c += 1
	return c


func are_all_corrupted_street_npcs_defeated() -> bool:
	return get_defeated_corrupted_street_npc_count() >= ACT2_STREET_TASK_NPCS.size()


func get_completed_normal_street_mission_count() -> int:
	var c := 0
	for sw in ACT2_NORMAL_MISSION_SWITCHES:
		if get_switch(sw):
			c += 1
	return c


func are_all_normal_street_missions_completed() -> bool:
	return get_completed_normal_street_mission_count() >= ACT2_NORMAL_MISSION_SWITCHES.size()


func complete_corrupted_route_at_chief() -> void:
	act2_route_completed = "corrupted"
	complete_task("ato2_corrompido_rua")
	set_switch("019_Ato2_concluido", true)
	autosave(current_scene_path, spawn_tag)
	save_checkpoint()
	notification_requested.emit("A rua ficou em silêncio. Retorne para a cama em casa.")


## Reverte o Modo Corrompido após a checagem e medicação da Enfermeira Maria no Quartel BFP.
func revert_corrupted_mode_via_nurse() -> void:
	nurse_reverted_corrupted = true
	defeated_corrupted_npcs.clear()
	if inventory.has("antidoto_reversao"):
		inventory.erase("antidoto_reversao")
	if active_tasks.has("ato2_corrompido_rua"):
		active_tasks.erase("ato2_corrompido_rua")
	set_switch("006d_Enfermeira_reverteu_dose", true)
	set_higher_dose(false)
	if get_switch("007_Chefe_Ato2_apresentado") and not are_all_normal_street_missions_completed():
		start_task("ato2_ocorrencias_cidade", "Ajudar os 3 moradores de Agdangan na rua", ACT2_NORMAL_MISSION_SWITCHES.size())
		update_task_progress("ato2_ocorrencias_cidade", get_completed_normal_street_mission_count(), "Ajudar os 3 moradores de Agdangan na rua", ACT2_NORMAL_MISSION_SWITCHES.size())
	autosave(current_scene_path, spawn_tag)
	save_checkpoint()
	notification_requested.emit("Medicação aplicada — percepção estabilizada. As missões normais da rua foram restauradas.")


func get_demo_route_summary() -> Dictionary:
	var route_id := act2_route_completed
	if route_id.is_empty():
		if nurse_reverted_corrupted or get_switch("006d_Enfermeira_reverteu_dose"):
			route_id = "reverted"
		elif are_all_corrupted_street_npcs_defeated() or get_switch("006b_Dose_maior_pilulas"):
			route_id = "corrupted"
		else:
			route_id = "normal"
	match route_id:
		"corrupted":
			return {
				"route_id": "corrupted",
				"route_title": "ROTA CONCLUÍDA: PERCEPÇÃO CORROMPIDA",
				"summary": "A dose excessiva rompeu a fronteira entre lembrança e rua.\nEm meio ao silêncio que restou de Agdangan, você encarou a fita VHS até o último fragmento."
			}
		"reverted":
			return {
				"route_id": "reverted",
				"route_title": "ROTA CONCLUÍDA: REVERSÃO E RECONEXÃO",
				"summary": "Após o excesso de comprimidos, você aceitou a checagem da Enfermeira Maria,\nestabilizou a percepção, voltou a ajudar Agdangan e enfrentou a memória sem filtro."
			}
		_:
			return {
				"route_id": "normal",
				"route_title": "ROTA CONCLUÍDA: PERCEPÇÃO ESTÁVEL",
				"summary": "Você manteve a dose habitual, atendeu os moradores de Agdangan com firmeza\ne atravessou a fita VHS de olhos abertos diante do que aconteceu."
			}


func mark_forest_santelmo_defeated(santelmo_id: String) -> void:
	if santelmo_id.is_empty():
		return
	defeated_forest_santelmos[santelmo_id] = true
	var count := get_defeated_forest_santelmo_count()
	if count >= FOREST_SANTELMO_TOTAL:
		complete_task("forest_santelmos")
	else:
		update_task_progress("forest_santelmos", count, "Extinguir os 16 Santelmos da Trilha da Floresta", FOREST_SANTELMO_TOTAL)


func is_forest_santelmo_defeated(santelmo_id: String) -> bool:
	return bool(defeated_forest_santelmos.get(santelmo_id, false))


func get_defeated_forest_santelmo_count() -> int:
	var c := 0
	for k in defeated_forest_santelmos.keys():
		if bool(defeated_forest_santelmos[k]):
			c += 1
	return clampi(c, 0, FOREST_SANTELMO_TOTAL)


func get_remaining_forest_santelmo_count() -> int:
	return maxi(0, FOREST_SANTELMO_TOTAL - get_defeated_forest_santelmo_count())


func are_all_forest_santelmos_defeated() -> bool:
	return get_remaining_forest_santelmo_count() <= 0


func mark_all_forest_santelmos_defeated() -> void:
	for i in range(1, FOREST_SANTELMO_TOTAL + 1):
		defeated_forest_santelmos["Santelmo%d" % i] = true
	complete_task("forest_santelmos")

## Avança para o Ato 3 (Revelação sem filtro) após concluir o Ato 2 e descansar
func advance_to_act_3() -> void:
	variables["Ato"] = 3
	variables["Intoxicacao"] = 0
	corrupted_mode = false
	set_switch("006b_Dose_maior_pilulas", false)
	set_switch("022_Ato3_iniciado", true)
	set_switch("022b_Ato3_despertar_visto", false)
	variable_changed.emit("Ato", 3)
	variable_changed.emit("Intoxicacao", 0)
	is_afternoon = false
	clock_minutes = day_start_minutes
	_clock_accum = 0.0
	_last_emitted_period = "morning"
	restore_full_vitals()
	set_perception_mode(PerceptionMode.UNFILTERED_ACT3)
	higher_dose_changed.emit(false)
	time_of_day_changed.emit(false)
	clock_minute_changed.emit(clock_minutes, get_formatted_time(clock_minutes))
	day_period_changed.emit("morning")
	autosave(current_scene_path, "from_act2")
	save_checkpoint(current_scene_path, Vector2.ZERO, "from_act2")
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").play_ambience("act3_ambience")
		get_node("/root/AudioManager").play_sfx("vhs_glitch")
	notification_requested.emit("06:30 — O efeito dos comprimidos passou")

## Avança ciclicamente entre os Atos (Ato 1 -> Ato 2 -> Ato 3 -> Ato 1) via atalho de depuração
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
			set_var("Intoxicacao", 0)
			is_afternoon = false
			clock_minutes = day_start_minutes
			_clock_accum = 0.0
			_last_emitted_period = "morning"
			player_hp = player_max_hp
			hp_changed.emit(player_hp, player_max_hp)
			set_perception_mode(PerceptionMode.FILTERED_MORNING)
			higher_dose_changed.emit(false)
			time_of_day_changed.emit(false)
			clock_minute_changed.emit(clock_minutes, get_formatted_time(clock_minutes))
			day_period_changed.emit("morning")
			autosave(current_scene_path, "initial")
			if has_node("/root/AudioManager"):
				get_node("/root/AudioManager").play_ambience("day_ambience")
				get_node("/root/AudioManager").play_bgm("day_theme", 1.0)
			notification_requested.emit("06:30 — Manhã Filtrada em Agdangan")
			return 1

## Conclui uma das 3 missões dos moradores da rua no Ato 2 (Modo Normal ou Pós-Reversão)
func complete_optional_mission(switch_done_key: String) -> void:
	if get_switch(switch_done_key):
		return
	set_switch(switch_done_key, true)
	var done_count: int = get_completed_normal_street_mission_count()
	set_var("Missoes_concluidas", done_count)
	update_task_progress("ato2_ocorrencias_cidade", done_count, "Ajudar os 3 moradores de Agdangan na rua", ACT2_NORMAL_MISSION_SWITCHES.size())
	if not get_switch("020_Alguma_missao_completa"):
		set_switch("020_Alguma_missao_completa", true)
		trigger_turn_afternoon()
	if are_all_normal_street_missions_completed():
		act2_route_completed = "reverted" if (nurse_reverted_corrupted or get_switch("006d_Enfermeira_reverteu_dose")) else "normal"
		set_switch("019_Ato2_concluido", true)
		notification_requested.emit("Todos os moradores da rua foram ajudados! Reporte ao Capitão Reyes ou descanse em casa.")
	else:
		notification_requested.emit("Morador ajudado (%d/%d). Continue auxiliando Agdangan." % [done_count, ACT2_NORMAL_MISSION_SWITCHES.size()])
	autosave(current_scene_path, spawn_tag)
	save_checkpoint()

func set_perception_mode(mode: int) -> void:
	perception_mode = clampi(mode, 0, 2)
	perception_changed.emit(perception_mode)

func is_unfiltered_act3() -> bool:
	return perception_mode == PerceptionMode.UNFILTERED_ACT3 or int(variables.get("Ato", 1)) >= 3

func cycle_perception_preview() -> void:
	var next_mode: int = (perception_mode + 1) % 3
	set_perception_mode(next_mode)
	var labels := [
		"Manhã Filtrada (Efeito dos Comprimidos)",
		"Fim de Tarde (Luz Âmbar)",
		"Realidade Sem Filtro (Monocromático/Desgastado)"
	]
	notification_requested.emit(labels[next_mode])

# --- SAVE / LOAD SYSTEM ---

func get_place_display_name(scene_path: String) -> String:
	var scene := scene_path
	if scene.find("Street") != -1:
		return "Rua de Agdangan"
	if scene.find("Station") != -1:
		return "Quartel BFP"
	if scene.find("trail") != -1 or scene.find("Corridor") != -1:
		return "Trilha da Floresta"
	if scene.find("clearing") != -1 or scene.find("Clearing") != -1:
		return "Clareira da Lagoa"
	if scene.find("vhs_memory") != -1:
		return "Memória / Pesadelo"
	return "Quarto de Huwag"


func _get_slot_json_path(slot_idx: int) -> String:
	return "%s/slot_%d.json" % [SAVE_SLOTS_DIR, clampi(slot_idx, 1, MAX_SAVE_SLOTS)]


func get_slot_thumbnail_path(slot_idx: int) -> String:
	return "%s/slot_%d.png" % [SAVE_SLOTS_DIR, clampi(slot_idx, 1, MAX_SAVE_SLOTS)]


func has_save_file() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func has_any_save() -> bool:
	if has_save_file():
		return true
	return get_latest_save_slot() > 0


func get_latest_save_slot() -> int:
	var best_slot := -1
	var best_unix := -1
	for slot in range(1, MAX_SAVE_SLOTS + 1):
		var path := _get_slot_json_path(slot)
		if not FileAccess.file_exists(path):
			continue
		var file := FileAccess.open(path, FileAccess.READ)
		if file == null:
			continue
		var parsed: Variant = JSON.parse_string(file.get_as_text())
		if typeof(parsed) != TYPE_DICTIONARY:
			continue
		var data: Dictionary = parsed
		var ut: int = int(data.get("unix_time", 0))
		if ut >= best_unix:
			best_unix = ut
			best_slot = slot
	return best_slot


func _summarize_save_dict(data: Dictionary, slot_idx: int = 0) -> Dictionary:
	var ato: int = int(data.get("variables", {}).get("Ato", 1))
	var saved_mins: int = int(data.get("clock_minutes", 960 if bool(data.get("is_afternoon", false)) else day_start_minutes))
	var clock_hhmm: String = str(data.get("clock_hhmm", get_formatted_time(saved_mins)))
	var scene: String = str(data.get("current_scene", "RoomHuwag"))
	var place := get_place_display_name(scene)
	var sw: Dictionary = data.get("switches", {})
	var vars: Dictionary = data.get("variables", {})
	var corrupted: bool = bool(sw.get("006b_Mayor_Dose_Tomada", false)) and not bool(sw.get("006d_Enfermeira_reverteu_dose", false)) and ato < 3
	if int(vars.get("Intoxicacao", 0)) >= 2 and ato < 3:
		corrupted = true
	var thumb := get_slot_thumbnail_path(slot_idx) if slot_idx > 0 else ""
	return {
		"exists": true,
		"slot": slot_idx,
		"ato": ato,
		"clock_minutes": saved_mins,
		"clock_hhmm": clock_hhmm,
		"place": place,
		"hp": int(data.get("player_hp", 100)),
		"date": str(data.get("timestamp", "Recente")),
		"unix_time": int(data.get("unix_time", 0)),
		"corrupted": corrupted,
		"thumbnail_path": thumb if (slot_idx > 0 and FileAccess.file_exists(thumb)) else "",
	}


func get_save_summary() -> Dictionary:
	if has_save_file():
		var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
		if file != null:
			var parsed: Variant = JSON.parse_string(file.get_as_text())
			if typeof(parsed) == TYPE_DICTIONARY:
				return _summarize_save_dict(parsed as Dictionary, 0)
	var latest := get_latest_save_slot()
	if latest > 0:
		return get_slot_summary(latest)
	return {}


func get_slot_summary(slot_idx: int) -> Dictionary:
	var clamped := clampi(slot_idx, 1, MAX_SAVE_SLOTS)
	var path := _get_slot_json_path(clamped)
	if not FileAccess.file_exists(path):
		return {
			"exists": false,
			"slot": clamped,
			"ato": 0,
			"clock_minutes": 0,
			"clock_hhmm": "--:--",
			"place": "Slot Vazio",
			"hp": 0,
			"date": "",
			"unix_time": 0,
			"corrupted": false,
			"thumbnail_path": "",
		}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"exists": false, "slot": clamped}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return {"exists": false, "slot": clamped}
	return _summarize_save_dict(parsed as Dictionary, clamped)


func get_all_slot_summaries() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for i in range(1, MAX_SAVE_SLOTS + 1):
		out.append(get_slot_summary(i))
	return out


func autosave(scene_path: String = "", tag: String = "", pos: Vector2 = Vector2.ZERO) -> bool:
	if scene_path != "":
		current_scene_path = scene_path
	if tag != "":
		spawn_tag = tag
	if pos != Vector2.ZERO:
		saved_player_pos = pos
	return save_game()


func _capture_live_player_position() -> void:
	if not is_inside_tree():
		return
	var players := get_tree().get_nodes_in_group("player")
	for p in players:
		if is_instance_valid(p) and p is Node2D:
			var p2d := p as Node2D
			if p2d.global_position != Vector2.ZERO:
				saved_player_pos = p2d.global_position
			return


func _build_save_payload() -> Dictionary:
	return {
		"version": 4,
		"timestamp": Time.get_datetime_string_from_system(false, true),
		"unix_time": int(Time.get_unix_time_from_system()),
		"current_scene": current_scene_path,
		"spawn_tag": spawn_tag,
		"player_pos_x": saved_player_pos.x,
		"player_pos_y": saved_player_pos.y,
		"switches": switches,
		"variables": variables,
		"self_switches": self_switches,
		"inventory": inventory,
		"is_afternoon": is_afternoon,
		"clock_minutes": clock_minutes,
		"clock_hhmm": get_formatted_time(clock_minutes),
		"perception_mode": perception_mode,
		"player_hp": player_hp,
		"water_boss_defeated": water_boss_defeated,
		"equipped_outfit": equipped_outfit,
		"day_number": day_number,
		"active_tasks": active_tasks,
		"completed_tasks": completed_tasks,
		"defeated_forest_santelmos": defeated_forest_santelmos,
		"defeated_corrupted_npcs": defeated_corrupted_npcs,
		"nurse_reverted_corrupted": nurse_reverted_corrupted,
		"act2_route_completed": act2_route_completed,
		"settings": {
			"flash_reduction": setting_flash_reduction,
			"vhs_effects": setting_vhs_effects,
			"screen_shake": setting_screen_shake
		}
	}


func save_game() -> bool:
	var data := _build_save_payload()
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Erro ao abrir arquivo para salvar: %s" % SAVE_PATH)
		return false
	file.store_string(JSON.stringify(data, "\t"))
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").play_sfx("save_chime")
	return true


func save_to_slot(slot_idx: int, screenshot: Image = null) -> bool:
	var clamped := clampi(slot_idx, 1, MAX_SAVE_SLOTS)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SAVE_SLOTS_DIR))
	_capture_live_player_position()
	var data := _build_save_payload()
	var json_str := JSON.stringify(data, "\t")
	var slot_path := _get_slot_json_path(clamped)
	var file := FileAccess.open(slot_path, FileAccess.WRITE)
	if file == null:
		push_error("Erro ao gravar slot %d em %s" % [clamped, slot_path])
		return false
	file.store_string(json_str)
	file.close()

	# Mantém SAVE_PATH sincronizado com o salvamento mais recente
	var main_file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if main_file != null:
		main_file.store_string(json_str)
		main_file.close()

	if screenshot != null and not screenshot.is_empty():
		var thumb := screenshot.duplicate() as Image
		if thumb != null:
			if thumb.get_format() != Image.FORMAT_RGBA8 and thumb.get_format() != Image.FORMAT_RGB8:
				thumb.convert(Image.FORMAT_RGBA8)
			thumb.resize(320, 180, Image.INTERPOLATE_BILINEAR)
			var thumb_path := get_slot_thumbnail_path(clamped)
			thumb.save_png(thumb_path)

	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").play_sfx("save_chime")
	return true


func _apply_save_payload(data: Dictionary) -> bool:
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
	var loaded_mins: int = int(data.get("clock_minutes", 960 if is_afternoon else day_start_minutes))
	clock_minutes = clampi(loaded_mins, 0, 1439)
	_clock_accum = 0.0
	_last_emitted_period = get_day_period(clock_minutes)
	player_hp = int(data.get("player_hp", 100))
	water_boss_defeated = bool(data.get("water_boss_defeated", false))
	day_number = maxi(1, int(data.get("day_number", 1)))
	active_tasks = data.get("active_tasks", {}).duplicate(true) if typeof(data.get("active_tasks", null)) == TYPE_DICTIONARY else {}
	completed_tasks = data.get("completed_tasks", {}).duplicate() if typeof(data.get("completed_tasks", null)) == TYPE_DICTIONARY else {}
	defeated_forest_santelmos = data.get("defeated_forest_santelmos", {}).duplicate() if typeof(data.get("defeated_forest_santelmos", null)) == TYPE_DICTIONARY else {}
	defeated_corrupted_npcs = data.get("defeated_corrupted_npcs", {}).duplicate() if typeof(data.get("defeated_corrupted_npcs", null)) == TYPE_DICTIONARY else {}
	nurse_reverted_corrupted = bool(data.get("nurse_reverted_corrupted", get_switch("006d_Enfermeira_reverteu_dose")))
	act2_route_completed = str(data.get("act2_route_completed", ""))
	corrupted_mode = is_higher_dose()
	current_scene_path = str(data.get("current_scene", "res://scenes/levels/RoomHuwag.tscn"))
	spawn_tag = str(data.get("spawn_tag", "initial"))
	var px: float = float(data.get("player_pos_x", 0.0))
	var py: float = float(data.get("player_pos_y", 0.0))
	saved_player_pos = Vector2(px, py)
	_pending_checkpoint_spawn_pos = saved_player_pos
	_has_pending_checkpoint_spawn = (saved_player_pos != Vector2.ZERO)

	clear_transient_state()
	set_equipped_outfit(str(data.get("equipped_outfit", "casual")), false)
	set_perception_mode(int(data.get("perception_mode", PerceptionMode.FILTERED_MORNING)))
	if not variables.has("Intoxicacao"):
		variables["Intoxicacao"] = 2 if is_higher_dose() else (1 if int(variables.get("Ato", 1)) == 2 else 0)
	higher_dose_changed.emit(is_higher_dose())
	variable_changed.emit("Intoxicacao", variables["Intoxicacao"])
	clock_minute_changed.emit(clock_minutes, get_formatted_time(clock_minutes))
	day_period_changed.emit(_last_emitted_period)

	if data.has("settings") and typeof(data["settings"]) == TYPE_DICTIONARY:
		var s: Dictionary = data["settings"]
		setting_flash_reduction = bool(s.get("flash_reduction", false))
		setting_vhs_effects = bool(s.get("vhs_effects", true))
		setting_screen_shake = float(s.get("screen_shake", 1.0))

	player_stamina = player_max_stamina
	hp_changed.emit(player_hp, player_max_hp)
	stamina_changed.emit(player_stamina, player_max_stamina)
	save_checkpoint(current_scene_path, saved_player_pos, spawn_tag)
	return true


func load_game() -> bool:
	if not has_save_file():
		var latest := get_latest_save_slot()
		if latest > 0:
			return load_from_slot(latest)
		return false
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return false
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return false
	return _apply_save_payload(parsed as Dictionary)


func load_from_slot(slot_idx: int) -> bool:
	var clamped := clampi(slot_idx, 1, MAX_SAVE_SLOTS)
	var path := _get_slot_json_path(clamped)
	if not FileAccess.file_exists(path):
		return false
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return false
	var text := file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return false
	var main_file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if main_file != null:
		main_file.store_string(text)
		main_file.close()
	return _apply_save_payload(parsed as Dictionary)


# --- CHECKPOINT SYSTEM (ÚLTIMO PONTO SEGURO) ---

func _is_checkpoint_eligible_scene(scene_path: String) -> bool:
	if scene_path.is_empty():
		return false
	if scene_path.ends_with("TitleScreen.tscn") or scene_path.ends_with("EndingCredits.tscn") or scene_path.ends_with("vhs_memory_minigame.tscn"):
		return false
	return true


func has_checkpoint() -> bool:
	return not _last_checkpoint.is_empty()


func get_last_checkpoint() -> Dictionary:
	return _last_checkpoint.duplicate(true)


func has_pending_checkpoint_spawn() -> bool:
	return _has_pending_checkpoint_spawn


func consume_pending_checkpoint_spawn() -> Vector2:
	if not _has_pending_checkpoint_spawn:
		return Vector2.ZERO
	_has_pending_checkpoint_spawn = false
	var pos := _pending_checkpoint_spawn_pos
	_pending_checkpoint_spawn_pos = Vector2.ZERO
	return pos


func save_checkpoint(scene_path: String = "", spawn_pos: Vector2 = Vector2.ZERO, tag: String = "") -> Dictionary:
	if _is_restoring_checkpoint or is_player_defeated:
		return _last_checkpoint.duplicate(true)
	var target_scene := scene_path if not scene_path.is_empty() else current_scene_path
	if not _is_checkpoint_eligible_scene(target_scene):
		return _last_checkpoint.duplicate(true)

	var target_tag := tag if not tag.is_empty() else spawn_tag
	var safe_pos := spawn_pos
	if safe_pos == Vector2.ZERO:
		var tree := get_tree()
		if tree != null:
			var p := tree.get_first_node_in_group("player") as Node2D
			if p != null and is_instance_valid(p) and not bool(p.get("is_dead")):
				safe_pos = p.position
	if safe_pos == Vector2.ZERO and saved_player_pos != Vector2.ZERO:
		safe_pos = saved_player_pos

	_last_checkpoint = {
		"scene_path": target_scene,
		"spawn_position": safe_pos,
		"spawn_tag": target_tag,
		"clock_minutes": clock_minutes,
		"is_afternoon": is_afternoon,
		"day_number": day_number,
		"perception_mode": perception_mode,
		"switches": switches.duplicate(true),
		"variables": variables.duplicate(true),
		"self_switches": self_switches.duplicate(true),
		"inventory": inventory.duplicate(true),
		"active_tasks": active_tasks.duplicate(true),
		"completed_tasks": completed_tasks.duplicate(true),
		"defeated_forest_santelmos": defeated_forest_santelmos.duplicate(true),
		"defeated_corrupted_npcs": defeated_corrupted_npcs.duplicate(true),
		"nurse_reverted_corrupted": nurse_reverted_corrupted,
		"act2_route_completed": act2_route_completed,
		"water_boss_defeated": water_boss_defeated,
		"equipped_outfit": equipped_outfit,
	}
	checkpoint_saved.emit(_last_checkpoint.duplicate(true))
	return _last_checkpoint.duplicate(true)


func restore_last_checkpoint() -> bool:
	_is_restoring_checkpoint = true
	clear_transient_state()

	if _last_checkpoint.is_empty():
		# Fallback seguro caso ocorra derrota antes de qualquer snapshot explícito
		if not _is_checkpoint_eligible_scene(current_scene_path):
			current_scene_path = "res://scenes/levels/RoomHuwag.tscn"
			spawn_tag = "initial"
		_pending_checkpoint_spawn_pos = saved_player_pos
		_has_pending_checkpoint_spawn = (saved_player_pos != Vector2.ZERO)
		restore_full_vitals()
		_is_restoring_checkpoint = false
		checkpoint_restored.emit({
			"scene_path": current_scene_path,
			"spawn_position": saved_player_pos,
			"spawn_tag": spawn_tag,
		})
		return true

	var cp := _last_checkpoint
	switches = (cp.get("switches", switches) as Dictionary).duplicate(true)
	variables = (cp.get("variables", variables) as Dictionary).duplicate(true)
	self_switches = (cp.get("self_switches", {}) as Dictionary).duplicate(true)
	inventory = (cp.get("inventory", {}) as Dictionary).duplicate(true)
	active_tasks = (cp.get("active_tasks", {}) as Dictionary).duplicate(true)
	completed_tasks = (cp.get("completed_tasks", {}) as Dictionary).duplicate(true)
	defeated_forest_santelmos = (cp.get("defeated_forest_santelmos", {}) as Dictionary).duplicate(true)
	defeated_corrupted_npcs = (cp.get("defeated_corrupted_npcs", {}) as Dictionary).duplicate(true)
	nurse_reverted_corrupted = bool(cp.get("nurse_reverted_corrupted", get_switch("006d_Enfermeira_reverteu_dose")))
	act2_route_completed = str(cp.get("act2_route_completed", ""))
	corrupted_mode = is_higher_dose()
	water_boss_defeated = bool(cp.get("water_boss_defeated", false))
	day_number = maxi(1, int(cp.get("day_number", 1)))
	is_afternoon = bool(cp.get("is_afternoon", false))
	clock_minutes = clampi(int(cp.get("clock_minutes", day_start_minutes)), 0, 1439)
	_clock_accum = 0.0
	_last_emitted_period = get_day_period(clock_minutes)
	current_scene_path = str(cp.get("scene_path", "res://scenes/levels/RoomHuwag.tscn"))
	spawn_tag = str(cp.get("spawn_tag", "initial"))
	var cp_pos: Vector2 = cp.get("spawn_position", Vector2.ZERO) as Vector2
	saved_player_pos = cp_pos
	_pending_checkpoint_spawn_pos = cp_pos
	_has_pending_checkpoint_spawn = (cp_pos != Vector2.ZERO)

	set_equipped_outfit(str(cp.get("equipped_outfit", "casual")), false)
	set_perception_mode(int(cp.get("perception_mode", PerceptionMode.FILTERED_MORNING)))
	restore_full_vitals()

	higher_dose_changed.emit(is_higher_dose())
	time_of_day_changed.emit(is_afternoon)
	clock_minute_changed.emit(clock_minutes, get_formatted_time(clock_minutes))
	day_period_changed.emit(_last_emitted_period)

	_is_restoring_checkpoint = false
	checkpoint_restored.emit(_last_checkpoint.duplicate(true))
	return true
