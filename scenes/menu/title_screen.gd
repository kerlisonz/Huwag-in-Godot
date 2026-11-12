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

# Modal de Opções / Acessibilidade
@onready var options_modal: Control = $OptionsModal
@onready var chk_flashes: CheckBox = $OptionsModal/Card/Margin/VBox/ChkFlashes
@onready var chk_vhs: CheckBox = $OptionsModal/Card/Margin/VBox/ChkVHS
@onready var slider_master: HSlider = $OptionsModal/Card/Margin/VBox/MasterRow/SliderMaster
@onready var slider_music: HSlider = $OptionsModal/Card/Margin/VBox/MusicRow/SliderMusic
@onready var slider_sfx: HSlider = $OptionsModal/Card/Margin/VBox/SfxRow/SliderSfx
@onready var btn_close_options: Button = $OptionsModal/Card/Margin/VBox/BtnCloseOptions

var _buttons: Array[Button] = []
var _selected_index: int = 0
var _pulse_time: float = 0.0

func _ready() -> void:
	# Configura resolução e proporção visual
	get_viewport().set_input_as_handled()
	_buttons = [btn_new_game, btn_continue, btn_options, btn_exit]

	# Conecta eventos de mouse e foco para cada botão
	for i in range(_buttons.size()):
		var btn := _buttons[i]
		btn.mouse_entered.connect(_on_button_mouse_entered.bind(i))
		btn.focus_entered.connect(_on_button_focused.bind(i))

	btn_new_game.pressed.connect(_on_new_game_pressed)
	btn_continue.pressed.connect(_on_continue_pressed)
	btn_options.pressed.connect(_on_options_pressed)
	btn_exit.pressed.connect(_on_exit_pressed)

	if btn_close_options:
		btn_close_options.pressed.connect(_close_options_modal)
	if chk_flashes:
		chk_flashes.toggled.connect(func(v: bool): GameState.setting_flash_reduction = v)
	if chk_vhs:
		chk_vhs.toggled.connect(func(v: bool): GameState.setting_vhs_effects = v)
	if slider_master:
		slider_master.value_changed.connect(_on_master_slider_changed)
	if slider_music:
		slider_music.value_changed.connect(_on_music_slider_changed)
	if slider_sfx:
		slider_sfx.value_changed.connect(_on_sfx_slider_changed)

	_check_save_state()
	_update_selection_visuals()

	# Inicia áudio atmosférico da tela inicial
	if has_node("/root/AudioManager"):
		var am = get_node("/root/AudioManager")
		am.play_bgm("title_theme", 1.5)
		am.play_ambience("none")

func _process(delta: float) -> void:
	_pulse_time += delta * 4.0
	# Respiração sutil da tipografia HUWAG
	if title_label:
		var s := 1.0 + sin(_pulse_time * 0.5) * 0.02
		title_label.scale = Vector2(s, s)

	# Efeito sutil no botão ativo
	if _selected_index >= 0 and _selected_index < _buttons.size():
		var active_btn := _buttons[_selected_index]
		if active_btn and active_btn.is_inside_tree() and not active_btn.disabled:
			active_btn.modulate.a = 0.85 + 0.15 * sin(_pulse_time)

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
