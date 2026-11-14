extends Control

# TitleScreen - Menu Inicial e Capa Original de Huwag
# Suporta navegação por teclado, mouse e controle.
# Efeitos visuais VHS sutis, áudio de ambiência e persistência de save.

@onready var cover_texture: TextureRect = $CoverTexture
@onready var title_label: Label = $VBoxTitle/TitleLabel
@onready var subtitle_label: Label = $VBoxTitle/SubtitleLabel
@onready var menu_vbox: VBoxContainer = $MenuContainer/MenuVBox
@onready var btn_new_game: Button = $MenuContainer/MenuVBox/BtnNewGame
@onready var btn_continue: Button = $MenuContainer/MenuVBox/BtnContinue
@onready var btn_options: Button = $MenuContainer/MenuVBox/BtnOptions
@onready var btn_exit: Button = $MenuContainer/MenuVBox/BtnExit
@onready var save_info_label: Label = $MenuContainer/MenuVBox/SaveInfoLabel

# Camada de pós-processamento VHS (filtra a capa e o título)
@onready var perception_layer: ColorRect = $PerceptionLayer

# OSD de videocassete
@onready var osd_rec_dot: ColorRect = $OsdRecDot
@onready var osd_rec_label: Label = $OsdRecLabel
@onready var osd_play_label: Label = $OsdPlayLabel
@onready var osd_timecode_label: Label = $OsdTimecodeLabel
@onready var osd_tape_label: Label = $OsdTapeLabel

# Modal de Opções / Acessibilidade
@onready var options_modal: Control = $OptionsModal
@onready var chk_flashes: CheckBox = $OptionsModal/Card/Margin/VBox/ChkFlashes
@onready var chk_vhs: CheckBox = $OptionsModal/Card/Margin/VBox/ChkVHS
@onready var chk_fullscreen: CheckBox = get_node_or_null("OptionsModal/Card/Margin/VBox/ChkFullscreen") as CheckBox
@onready var slider_master: HSlider = $OptionsModal/Card/Margin/VBox/MasterRow/SliderMaster
@onready var slider_music: HSlider = $OptionsModal/Card/Margin/VBox/MusicRow/SliderMusic
@onready var slider_sfx: HSlider = $OptionsModal/Card/Margin/VBox/SfxRow/SliderSfx
@onready var btn_close_options: Button = $OptionsModal/Card/Margin/VBox/BtnCloseOptions

# Valores-base dos uniformes VHS (espelham o ShaderMaterial_vhs da cena)
const BASE_PARAMS := {
	"vhs_scanline_alpha": 0.16,
	"vhs_noise_intensity": 0.05,
	"vhs_chromatic_aberration": 0.35,
	"vhs_tracking_jitter": 0.35,
	"vhs_crt_vignette": 0.4,
	"vhs_tracking_band": 0.25,
	"vhs_head_switch": 0.45,
	"vhs_dropout": 0.0,
	"vhs_tear": 0.0,
}
const GLITCH_DURATION := 0.22
const GLITCH_CURSOR := "►  "
const IDLE_CURSOR := "   "

var _buttons: Array[Button] = []
var _base_texts: Array[String] = []
var _selected_index: int = 0
var _pulse_time: float = 0.0
var _clock: float = 0.0

# OSD / glitch
var _osd_seconds: int = 0
var _osd_accum: float = 0.0
var _glitch_active: bool = false
var _glitch_t: float = 0.0
var _glitch_cooldown: float = 5.0
var _title_twitch: float = 0.0
var _shader_mat: ShaderMaterial = null

func _ready() -> void:
	# Configura resolução e proporção visual
	get_viewport().set_input_as_handled()
	_buttons = [btn_new_game, btn_continue, btn_options, btn_exit]

	# Guarda o texto-base sem cursor e remove a caixa de foco padrão do tema
	var empty_style := StyleBoxEmpty.new()
	for i in range(_buttons.size()):
		var btn := _buttons[i]
		_base_texts.append(btn.text)
		btn.text = IDLE_CURSOR + _base_texts[i]
		for st in ["normal", "hover", "pressed", "focus", "disabled"]:
			btn.add_theme_stylebox_override(st, empty_style)
		btn.mouse_entered.connect(_on_button_mouse_entered.bind(i))
		btn.focus_entered.connect(_on_button_focused.bind(i))

	btn_new_game.pressed.connect(_on_new_game_pressed)
	btn_continue.pressed.connect(_on_continue_pressed)
	btn_options.pressed.connect(_on_options_pressed)
	btn_exit.pressed.connect(_on_exit_pressed)

	if btn_close_options:
		btn_close_options.pressed.connect(_close_options_modal)
	if chk_flashes:
		chk_flashes.toggled.connect(func(v: bool):
			GameState.setting_flash_reduction = v
			_apply_vhs_setting()
		)
	if chk_vhs:
		chk_vhs.toggled.connect(func(v: bool):
			GameState.setting_vhs_effects = v
			_apply_vhs_setting()
		)
	if chk_fullscreen:
		chk_fullscreen.button_pressed = GameState.is_fullscreen()
		chk_fullscreen.toggled.connect(func(v: bool): GameState.set_fullscreen(v))
		GameState.window_mode_changed.connect(func(v: bool):
			if chk_fullscreen and is_instance_valid(chk_fullscreen):
				chk_fullscreen.set_pressed_no_signal(v)
		)
	if slider_master:
		slider_master.value_changed.connect(_on_master_slider_changed)
	if slider_music:
		slider_music.value_changed.connect(_on_music_slider_changed)
	if slider_sfx:
		slider_sfx.value_changed.connect(_on_sfx_slider_changed)

	if perception_layer and perception_layer.material is ShaderMaterial:
		_shader_mat = perception_layer.material

	_apply_vhs_setting()
	_check_save_state()
	_update_selection_visuals()

	# Inicia áudio atmosférico da tela inicial
	if has_node("/root/AudioManager"):
		var am = get_node("/root/AudioManager")
		am.play_bgm("title_theme", 1.5)
		am.play_ambience("none")

func _process(delta: float) -> void:
	_clock += delta
	_pulse_time += delta * 4.0
	# Respiração sutil da tipografia HUWAG + tremida analógica
	if title_label:
		var s := 1.0 + sin(_pulse_time * 0.5) * 0.02
		title_label.scale = Vector2(s, s)
		title_label.rotation = sin(_pulse_time * 0.37) * 0.004 + _title_twitch

	_update_button_cursors()
	_update_osd(delta)
	_update_glitch(delta)

	# Efeito sutil no botão ativo
	if _selected_index >= 0 and _selected_index < _buttons.size():
		var active_btn := _buttons[_selected_index]
		if active_btn and active_btn.is_inside_tree() and not active_btn.disabled:
			active_btn.modulate.a = 0.85 + 0.15 * sin(_pulse_time)

# --- OSD DE VIDEOCASSETE ---

func _update_osd(delta: float) -> void:
	if not GameState.setting_vhs_effects:
		return

	_osd_accum += delta
	if _osd_accum >= 1.0:
		_osd_accum -= 1.0
		_osd_seconds += 1
		if osd_timecode_label:
			osd_timecode_label.text = _format_timecode(_osd_seconds)

	# Piscar do ponto REC
	if osd_rec_dot:
		osd_rec_dot.modulate.a = 1.0 if fmod(_clock, 1.2) < 0.7 else 0.12

func _format_timecode(total_seconds: int) -> String:
	var s := total_seconds
	var h := int(s / 3600.0)
	s -= h * 3600
	var m := int(s / 60.0)
	s -= m * 60
	return "%02d:%02d:%02d" % [h, m, s]

# --- CURSOR DOS BOTÕES ---

func _update_button_cursors() -> void:
	var blink: bool = fmod(_clock, 1.0) < 0.55
	for i in range(_buttons.size()):
		var btn := _buttons[i]
		if i == _selected_index and not btn.disabled:
			btn.text = (GLITCH_CURSOR if blink else IDLE_CURSOR) + _base_texts[i]
		else:
			btn.text = IDLE_CURSOR + _base_texts[i]

# --- EVENTOS DE GLITCH DA FITA ---

func _update_glitch(delta: float) -> void:
	if not GameState.setting_vhs_effects:
		return

	if _glitch_active:
		_glitch_t -= delta
		var k: float = clampf(_glitch_t / GLITCH_DURATION, 0.0, 1.0)
		_apply_glitch(k)
		if _glitch_t <= 0.0:
			_end_glitch()
	else:
		_glitch_cooldown -= delta
		if _glitch_cooldown <= 0.0:
			_start_glitch()

func _start_glitch() -> void:
	_glitch_active = true
	_glitch_t = GLITCH_DURATION
	_glitch_cooldown = randf_range(6.0, 12.0)

	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").play_sfx("vhs_glitch", 0.5, randf_range(0.92, 1.08))

func _apply_glitch(k: float) -> void:
	# Intensifica aberração cromática, jitter e banda durante o evento
	if _shader_mat:
		_shader_mat.set_shader_parameter("vhs_chromatic_aberration", lerpf(float(BASE_PARAMS["vhs_chromatic_aberration"]), 1.0, k))
		_shader_mat.set_shader_parameter("vhs_tracking_jitter", lerpf(float(BASE_PARAMS["vhs_tracking_jitter"]), 0.85, k))
		_shader_mat.set_shader_parameter("vhs_tracking_band", lerpf(float(BASE_PARAMS["vhs_tracking_band"]), 0.6, k))
		_shader_mat.set_shader_parameter("vhs_dropout", k * 0.5)
		var tear_amt: float = k * (0.4 if GameState.setting_flash_reduction else 1.0)
		_shader_mat.set_shader_parameter("vhs_tear", tear_amt)
	_title_twitch = (randf() - 0.5) * 0.03 * k

func _end_glitch() -> void:
	_glitch_active = false
	_title_twitch = 0.0
	_restore_base_params()

func _restore_base_params() -> void:
	if _shader_mat == null:
		return
	for key in BASE_PARAMS.keys():
		_shader_mat.set_shader_parameter(key, float(BASE_PARAMS[key]))

# --- ACESSIBILIDADE / PREFERÊNCIA VHS ---

func _apply_vhs_setting() -> void:
	var on: bool = GameState.setting_vhs_effects

	if _shader_mat:
		for key in BASE_PARAMS.keys():
			var v: float = float(BASE_PARAMS[key]) * (1.0 if on else 0.15)
			_shader_mat.set_shader_parameter(key, v)

	if osd_rec_dot:
		osd_rec_dot.visible = on
	if osd_rec_label:
		osd_rec_label.visible = on
	if osd_play_label:
		osd_play_label.visible = on
	if osd_timecode_label:
		osd_timecode_label.visible = on
	if osd_tape_label:
		osd_tape_label.visible = on

	if not on:
		_end_glitch()

func _check_save_state() -> void:
	var has_save := GameState.has_save_file()
	btn_continue.disabled = not has_save

	if has_save:
		var summary := GameState.get_save_summary()
		var ato_roman := "I" if summary.get("ato", 1) == 1 else ("II" if summary.get("ato", 1) == 2 else "III")
		var place: String = summary.get("place", "Quarto de Huwag")
		var hp: int = summary.get("hp", 100)
		save_info_label.text = "Progresso salvo: Ato %s · %s (%d HP)" % [ato_roman, place, hp]
		save_info_label.modulate = Color(0.75, 0.85, 0.70, 0.85)
		_selected_index = 1 # Seleciona Continuar por padrão se houver save
		btn_continue.grab_focus()
	else:
		save_info_label.text = "Nenhum jogo salvo encontrado"
		save_info_label.modulate = Color(0.60, 0.62, 0.68, 0.60)
		_selected_index = 0
		btn_new_game.grab_focus()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F10:
			GameState.advance_act()
			_check_save_state()
			get_viewport().set_input_as_handled()
			return
		elif event.keycode == KEY_F11 or (event.keycode == KEY_ENTER and event.alt_pressed):
			GameState.toggle_fullscreen()
			get_viewport().set_input_as_handled()
			return

	if options_modal.visible:
		if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE):
			_close_options_modal()
			get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("ui_down") or (event is InputEventKey and event.pressed and (event.keycode == KEY_S or event.keycode == KEY_DOWN)):
		_move_selection(1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_up") or (event is InputEventKey and event.pressed and (event.keycode == KEY_W or event.keycode == KEY_UP)):
		_move_selection(-1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_accept") or (event is InputEventKey and event.pressed and (event.keycode == KEY_ENTER or event.keycode == KEY_SPACE or event.keycode == KEY_E)):
		_activate_selected_button()
		get_viewport().set_input_as_handled()

func _move_selection(delta: int) -> void:
	var count := _buttons.size()
	for step in range(1, count + 1):
		var target := (_selected_index + delta * step + count) % count
		if not _buttons[target].disabled:
			_selected_index = target
			_buttons[_selected_index].grab_focus()
			_play_sfx("ui_hover")
			_update_selection_visuals()
			break

func _on_button_mouse_entered(idx: int) -> void:
	if not _buttons[idx].disabled and _selected_index != idx:
		_selected_index = idx
		_buttons[idx].grab_focus()
		_play_sfx("ui_hover")
		_update_selection_visuals()

func _on_button_focused(idx: int) -> void:
	if not _buttons[idx].disabled:
		_selected_index = idx
		_update_selection_visuals()

func _update_selection_visuals() -> void:
	for i in range(_buttons.size()):
		var btn := _buttons[i]
		if btn.disabled:
			btn.modulate = Color(0.4, 0.4, 0.45, 0.6)
		elif i == _selected_index:
			btn.modulate = Color(1.0, 0.95, 0.70, 1.0)
		else:
			btn.modulate = Color(0.85, 0.88, 0.92, 0.85)

func _activate_selected_button() -> void:
	if _selected_index >= 0 and _selected_index < _buttons.size():
		var btn := _buttons[_selected_index]
		if not btn.disabled:
			btn.emit_signal("pressed")

func _on_new_game_pressed() -> void:
	_play_sfx("ui_select")
	GameState.reset_to_new_game()
	_start_game_transition("res://scenes/levels/RoomHuwag.tscn", "initial")

func _on_continue_pressed() -> void:
	if not GameState.has_save_file():
		return
	_play_sfx("ui_select")
	if GameState.load_game():
		var target := GameState.current_scene_path
		if target.is_empty():
			target = "res://scenes/levels/RoomHuwag.tscn"
		_start_game_transition(target, GameState.spawn_tag)

func _start_game_transition(target_scene: String, target_tag: String) -> void:
	# Desativa botões durante transição
	for b in _buttons:
		b.disabled = true

	var main_scene := "res://scenes/main/Main.tscn"
	GameState.current_scene_path = target_scene
	GameState.spawn_tag = target_tag

	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.6)
	tw.tween_callback(func():
		get_tree().change_scene_to_file(main_scene)
	)

func _on_options_pressed() -> void:
	_play_sfx("ui_select")
	options_modal.visible = true
	if chk_flashes:
		chk_flashes.button_pressed = GameState.setting_flash_reduction
	if chk_vhs:
		chk_vhs.button_pressed = GameState.setting_vhs_effects
	if slider_master and has_node("/root/AudioManager"):
		var am = get_node("/root/AudioManager")
		slider_master.value = am.master_volume
		slider_music.value = am.music_volume
		slider_sfx.value = am.sfx_volume
	btn_close_options.grab_focus()

func _close_options_modal() -> void:
	_play_sfx("ui_back")
	options_modal.visible = false
	btn_options.grab_focus()

func _on_master_slider_changed(val: float) -> void:
	if has_node("/root/AudioManager"):
		var am = get_node("/root/AudioManager")
		am.set_volumes(val, am.music_volume, am.sfx_volume)

func _on_music_slider_changed(val: float) -> void:
	if has_node("/root/AudioManager"):
		var am = get_node("/root/AudioManager")
		am.set_volumes(am.master_volume, val, am.sfx_volume)

func _on_sfx_slider_changed(val: float) -> void:
	if has_node("/root/AudioManager"):
		var am = get_node("/root/AudioManager")
		am.set_volumes(am.master_volume, am.music_volume, val)

func _on_exit_pressed() -> void:
	_play_sfx("ui_back")
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.3)
	tw.tween_callback(func():
		get_tree().quit()
	)

func _play_sfx(sfx_name: String) -> void:
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").play_sfx(sfx_name)
