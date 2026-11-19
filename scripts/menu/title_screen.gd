extends Control

@onready var cover_art: TextureRect = $CoverArt
@onready var mist_overlay: ColorRect = $MistOverlay
@onready var ambient_fx: Control = $AmbientFX
@onready var title_label: Label = $HeaderBox/TitleLabel
@onready var subtitle_label: Label = $HeaderBox/SubtitleLabel
@onready var menu_container: PanelContainer = $MenuContainer
@onready var menu_vbox: VBoxContainer = $MenuContainer/MenuVBox
@onready var btn_new_game: Button = $MenuContainer/MenuVBox/BtnNewGame
@onready var btn_continue: Button = $MenuContainer/MenuVBox/BtnContinue
@onready var btn_load_game: Button = $MenuContainer/MenuVBox/BtnLoadGame
@onready var btn_options: Button = $MenuContainer/MenuVBox/BtnOptions
@onready var btn_music_credits: Button = $MenuContainer/MenuVBox/BtnMusicCredits
@onready var btn_exit: Button = $MenuContainer/MenuVBox/BtnExit
@onready var hand_cursor: TextureRect = $HandCursor
@onready var save_summary_label: Label = $SaveSummaryLabel
@onready var footer_label: Label = get_node_or_null("FooterLabel") as Label
@onready var save_load_panel: SaveLoadPanel = $SaveLoadPanel

@onready var options_modal: ColorRect = $OptionsModal
@onready var options_card: PanelContainer = $OptionsModal/Card
@onready var options_title: Label = $OptionsModal/Card/Margin/VBox/Title
@onready var chk_flashes: CheckBox = $OptionsModal/Card/Margin/VBox/ChkFlashes
@onready var chk_vhs: CheckBox = $OptionsModal/Card/Margin/VBox/ChkVHS
@onready var chk_fullscreen: CheckBox = $OptionsModal/Card/Margin/VBox/ChkFullscreen
@onready var slider_master: HSlider = $OptionsModal/Card/Margin/VBox/MasterRow/SliderMaster
@onready var slider_music: HSlider = $OptionsModal/Card/Margin/VBox/MusicRow/SliderMusic
@onready var slider_sfx: HSlider = $OptionsModal/Card/Margin/VBox/SfxRow/SliderSfx
@onready var btn_close_options: Button = $OptionsModal/Card/Margin/VBox/BtnCloseOptions

@onready var credits_modal: ColorRect = $CreditsModal
@onready var credits_card: PanelContainer = $CreditsModal/Card
@onready var credits_list: VBoxContainer = $CreditsModal/Card/Margin/VBox/CreditsList
@onready var btn_close_credits: Button = $CreditsModal/Card/Margin/VBox/BtnCloseCredits
@onready var fade_overlay: ColorRect = $FadeOverlay

var _buttons: Array[Button] = []
var _base_texts: Array[String] = []
var _selected_index: int = 0
var _anim_time: float = 0.0
var _fireflies: Array[Dictionary] = []
var _forest_eyes: Array[Dictionary] = []


func _ready() -> void:
	get_tree().paused = false
	options_modal.visible = false
	credits_modal.visible = false
	if save_load_panel:
		save_load_panel.visible = false
		save_load_panel.slot_action_completed.connect(_on_slot_loaded)
		save_load_panel.panel_closed.connect(func():
			if btn_load_game:
				btn_load_game.grab_focus()
		)

	fade_overlay.visible = false
	fade_overlay.color = Color(0, 0, 0, 0)

	_buttons = [btn_new_game, btn_continue, btn_load_game, btn_options, btn_music_credits, btn_exit]
	var empty_style := StyleBoxEmpty.new()
	for i in range(_buttons.size()):
		var btn := _buttons[i]
		_base_texts.append(btn.text)
		btn.text = "      " + _base_texts[i]
		for st in ["normal", "hover", "pressed", "focus", "disabled"]:
			btn.add_theme_stylebox_override(st, empty_style)
		btn.mouse_entered.connect(_on_button_mouse_entered.bind(i))
		btn.focus_entered.connect(_on_button_focused.bind(i))

	btn_new_game.pressed.connect(_on_new_game_pressed)
	btn_continue.pressed.connect(_on_continue_pressed)
	btn_load_game.pressed.connect(_on_load_game_pressed)
	btn_options.pressed.connect(_on_options_pressed)
	btn_music_credits.pressed.connect(_on_credits_pressed)
	btn_exit.pressed.connect(_on_exit_pressed)

	if btn_close_options:
		btn_close_options.pressed.connect(_close_options_modal)
	if btn_close_credits:
		btn_close_credits.pressed.connect(_close_credits_modal)

	chk_flashes.toggled.connect(func(v: bool) -> void: GameState.setting_flash_reduction = v)
	chk_vhs.toggled.connect(func(v: bool) -> void: GameState.setting_vhs_effects = v)
	if chk_fullscreen:
		chk_fullscreen.button_pressed = GameState.is_fullscreen()
		chk_fullscreen.toggled.connect(func(v: bool) -> void: GameState.set_fullscreen(v))
		if GameState.has_signal("window_mode_changed"):
			GameState.window_mode_changed.connect(func(v: bool) -> void:
				if is_instance_valid(chk_fullscreen):
					chk_fullscreen.set_pressed_no_signal(v)
			)

	if slider_master:
		slider_master.value_changed.connect(_on_volume_slider_changed)
	if slider_music:
		slider_music.value_changed.connect(_on_volume_slider_changed)
	if slider_sfx:
		slider_sfx.value_changed.connect(_on_volume_slider_changed)

	_init_ambient_elements()
	if ambient_fx:
		ambient_fx.draw.connect(_draw_ambient_fx)

	if hand_cursor:
		hand_cursor.texture = HuwagUiTheme.build_omori_hand_cursor_texture()

	_apply_omori_styles()
	_populate_credits_list()
	_check_save_state()

	if has_node("/root/AudioManager"):
		var am = get_node("/root/AudioManager")
		am.play_bgm("title_theme", 1.2)
		if am.has_method("play_ambience"):
			am.play_ambience("night_ambience", 1.0)
		if am.has_method("set_music_lowpass_cutoff"):
			am.set_music_lowpass_cutoff(16000.0, 0.3)

	call_deferred("_sync_hand_cursor_position")


func _init_ambient_elements() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 941122
	_fireflies.clear()
	for i in range(18):
		_fireflies.append({
			"base": Vector2(rng.randf_range(240.0, 624.0), rng.randf_range(40.0, 325.0)),
			"amp": Vector2(rng.randf_range(6.0, 18.0), rng.randf_range(4.0, 12.0)),
			"speed": rng.randf_range(0.55, 1.35),
			"phase": rng.randf_range(0.0, TAU),
			"is_ember": i % 4 == 0,
		})
	# Olhos discretos escondidos na copa escura da árvore à direita (Agdangan à noite)
	_forest_eyes = [
		{"pos": Vector2(548, 86), "phase": 0.4, "spread": 6.0},
		{"pos": Vector2(586, 128), "phase": 2.1, "spread": 5.0},
		{"pos": Vector2(492, 62), "phase": 4.2, "spread": 6.0},
	]


func _process(delta: float) -> void:
	_anim_time += delta
	if cover_art:
		cover_art.position.x = -4.0 + sin(_anim_time * 0.22) * 2.5
		cover_art.position.y = -4.0 + cos(_anim_time * 0.17) * 2.0
	if ambient_fx:
		ambient_fx.queue_redraw()
	_sync_hand_cursor_position()


func _draw_ambient_fx() -> void:
	if ambient_fx == null:
		return
	# Brilho quente suave nas janelas da casa na arte de capa
	var win_pulse := 0.14 + 0.06 * sin(_anim_time * 1.9)
	for wp in [Vector2(344, 246), Vector2(368, 244), Vector2(442, 238)]:
		ambient_fx.draw_circle(wp, 14.0, Color(1.0, 0.78, 0.36, win_pulse))
		ambient_fx.draw_circle(wp, 6.0, Color(1.0, 0.90, 0.56, win_pulse * 1.25))

	# Vaga-lumes / brasas flutuando suavemente
	for ff in _fireflies:
		var base: Vector2 = ff["base"]
		var amp: Vector2 = ff["amp"]
		var sp: float = float(ff["speed"])
		var ph: float = float(ff["phase"])
		var pos := Vector2(
			base.x + sin(_anim_time * sp + ph) * amp.x,
			base.y + cos(_anim_time * sp * 0.8 + ph) * amp.y
		)
		var glow := clampf(0.35 + 0.55 * sin(_anim_time * 2.2 + ph * 1.7), 0.10, 0.92)
		var col := Color(1.0, 0.62, 0.24, glow * 0.65) if bool(ff["is_ember"]) else Color(0.84, 0.96, 0.66, glow * 0.68)
		ambient_fx.draw_rect(Rect2(pos.round(), Vector2(2, 2)), col)
		ambient_fx.draw_circle(pos, 5.0, Color(col.r, col.g, col.b, glow * 0.12))

	# Olhos muito sutis espiando da escuridão das árvores (piscam em intervalos esparsos)
	for ey in _forest_eyes:
		var cycle := fmod(_anim_time + float(ey["phase"]), 6.5)
		if cycle > 3.6:
			continue
		var blink_close := (cycle > 1.8 and cycle < 1.94)
		var fade := sin(clampf(cycle / 3.6, 0.0, 1.0) * PI)
		if blink_close:
			continue
		var ep: Vector2 = ey["pos"]
		var sp_x: float = float(ey["spread"])
		var eye_col := Color(0.82, 0.86, 0.96, 0.38 * fade)
		ambient_fx.draw_rect(Rect2(ep + Vector2(-sp_x * 0.5, 0), Vector2(2, 2)), eye_col)
		ambient_fx.draw_rect(Rect2(ep + Vector2(sp_x * 0.5, 0), Vector2(2, 2)), eye_col)


func _sync_hand_cursor_position() -> void:
	if hand_cursor == null or _selected_index < 0 or _selected_index >= _buttons.size():
		return
	var btn := _buttons[_selected_index]
	if btn == null or not btn.is_inside_tree():
		return
	var modal_open := options_modal.visible or credits_modal.visible or (save_load_panel != null and save_load_panel.visible)
	hand_cursor.visible = not modal_open
	if not modal_open:
		var bob := 2.0 if int(fmod(_anim_time * 4.0, 2.0)) == 1 else 0.0
		var pos := btn.global_position
		hand_cursor.position = Vector2(pos.x + 2.0 + bob, pos.y + (btn.size.y - 12.0) * 0.5)


func _apply_omori_styles() -> void:
	var pal := HuwagUiTheme.get_palette("normal")
	if menu_container:
		menu_container.add_theme_stylebox_override("panel", HuwagUiTheme.make_omori_box_style(pal["bg"], pal["border"], 12, 10, 3))
	if options_card:
		options_card.add_theme_stylebox_override("panel", HuwagUiTheme.make_omori_box_style(pal["bg"], pal["border"], 5, 5, 3))
	if credits_card:
		credits_card.add_theme_stylebox_override("panel", HuwagUiTheme.make_omori_box_style(pal["bg"], pal["border"], 5, 5, 3))
	for btn in [btn_close_options, btn_close_credits]:
		if btn:
			btn.add_theme_stylebox_override("normal", HuwagUiTheme.make_omori_box_style(pal["choice_bg"], pal["border"], 10, 4, 2))
			btn.add_theme_stylebox_override("hover", HuwagUiTheme.make_omori_box_style(pal["choice_sel_bg"], pal["border"], 10, 4, 2))
			btn.add_theme_stylebox_override("focus", HuwagUiTheme.make_omori_box_style(pal["choice_sel_bg"], pal["border"], 10, 4, 2))
			btn.add_theme_color_override("font_color", pal["text"])


func _populate_credits_list() -> void:
	if credits_list == null:
		return
	for c in credits_list.get_children():
		c.queue_free()
	var ui_font := HuwagUiTheme.get_ui_font()
	var credits: Array = AudioManager.MUSIC_CREDITS if has_node("/root/AudioManager") else []
	for entry in credits:
		var row := Label.new()
		if ui_font:
			row.add_theme_font_override("font", ui_font)
		row.add_theme_font_size_override("font_size", 13)
		row.add_theme_color_override("font_color", Color(0.92, 0.94, 0.98, 1))
		row.text = "• \"%s\" — %s (%s) · %s" % [
			str(entry.get("title", "")),
			str(entry.get("artist", "")),
			str(entry.get("license", "CC-BY 4.0")),
			str(entry.get("usage", "")),
		]
		row.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		credits_list.add_child(row)

	var extra := Label.new()
	if ui_font:
		extra.add_theme_font_override("font", ui_font)
	extra.add_theme_font_size_override("font_size", 12)
	extra.add_theme_color_override("font_color", Color(0.72, 0.76, 0.84, 1))
	extra.text = "Tipografia UI: OMORI_GAME / OMORI_GAME2 com extensão vetorial PT-BR e pixel art original."
	credits_list.add_child(extra)


func _check_save_state() -> void:
	var has_save: bool = GameState.has_any_save() if GameState.has_method("has_any_save") else GameState.has_save_file()
	btn_continue.disabled = not has_save
	btn_load_game.disabled = not has_save
	if has_save:
		var s: Dictionary = GameState.get_save_summary()
		var place := str(s.get("place", "Quarto de Huwag"))
		var hhmm := str(s.get("clock_hhmm", "06:30"))
		var hp := int(s.get("hp", 100))
		save_summary_label.text = "Último registro: %s · %s (%d HP)" % [place, hhmm, hp]
		_selected_index = 1
		btn_continue.grab_focus()
	else:
		save_summary_label.text = ""
		_selected_index = 0
		btn_new_game.grab_focus()
	_refresh_button_colors()


func _refresh_button_colors() -> void:
	for i in range(_buttons.size()):
		var btn := _buttons[i]
		if btn.disabled:
			btn.add_theme_color_override("font_color", Color(0.45, 0.48, 0.56, 0.7))
		elif i == _selected_index:
			btn.add_theme_color_override("font_color", Color.WHITE)
		else:
			btn.add_theme_color_override("font_color", Color(0.76, 0.80, 0.88, 1))


func _unhandled_input(event: InputEvent) -> void:
	if save_load_panel and save_load_panel.visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if options_modal.visible:
			if event.keycode == KEY_ESCAPE:
				_close_options_modal()
				get_viewport().set_input_as_handled()
			return
		if credits_modal.visible:
			if event.keycode == KEY_ESCAPE:
				_close_credits_modal()
				get_viewport().set_input_as_handled()
			return
		if event.keycode == KEY_F11 or (event.keycode == KEY_ENTER and event.alt_pressed):
			GameState.toggle_fullscreen()
			get_viewport().set_input_as_handled()
		elif event.keycode in [KEY_UP, KEY_W]:
			_move_focus(-1)
			get_viewport().set_input_as_handled()
		elif event.keycode in [KEY_DOWN, KEY_S]:
			_move_focus(1)
			get_viewport().set_input_as_handled()
		elif event.keycode in [KEY_E, KEY_Z, KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]:
			var active := _buttons[_selected_index]
			if active and not active.disabled:
				active.emit_signal("pressed")
				get_viewport().set_input_as_handled()


func _move_focus(dir: int) -> void:
	for _step in range(_buttons.size()):
		_selected_index = (_selected_index + dir + _buttons.size()) % _buttons.size()
		if not _buttons[_selected_index].disabled:
			break
	_buttons[_selected_index].grab_focus()
	_refresh_button_colors()
	_play_sfx("ui_move")


func _on_button_mouse_entered(idx: int) -> void:
	if not _buttons[idx].disabled and not options_modal.visible and not credits_modal.visible and not (save_load_panel and save_load_panel.visible):
		if _selected_index != idx:
			_selected_index = idx
			_buttons[idx].grab_focus()
			_refresh_button_colors()
			_play_sfx("ui_move")


func _on_button_focused(idx: int) -> void:
	_selected_index = idx
	_refresh_button_colors()


func _on_new_game_pressed() -> void:
	_play_sfx("ui_select")
	GameState.reset_to_new_game()
	_start_game_transition("res://scenes/levels/RoomHuwag.tscn", "initial")


func _on_continue_pressed() -> void:
	_play_sfx("ui_select")
	if GameState.load_game():
		_start_game_transition(GameState.current_scene_path, GameState.spawn_tag)


func _on_load_game_pressed() -> void:
	_play_sfx("ui_select")
	if save_load_panel:
		save_load_panel.open_panel("load", null)


func _on_slot_loaded(_slot_idx: int, mode: String) -> void:
	if mode == "load":
		_start_game_transition(GameState.current_scene_path, GameState.spawn_tag)


func _start_game_transition(target_scene: String, target_tag: String) -> void:
	set_process(false)
	set_process_unhandled_input(false)
	GameState.current_scene_path = target_scene
	GameState.spawn_tag = target_tag
	fade_overlay.visible = true
	var tw := create_tween()
	tw.tween_property(fade_overlay, "color:a", 1.0, 0.35)
	tw.finished.connect(func() -> void:
		get_tree().change_scene_to_file("res://scenes/main/Main.tscn")
	)


func _on_options_pressed() -> void:
	_play_sfx("ui_select")
	options_modal.visible = true
	chk_flashes.set_pressed_no_signal(GameState.setting_flash_reduction)
	chk_vhs.set_pressed_no_signal(GameState.setting_vhs_effects)
	if chk_fullscreen:
		chk_fullscreen.set_pressed_no_signal(GameState.is_fullscreen())
	if has_node("/root/AudioManager"):
		var am = get_node("/root/AudioManager")
		if slider_master:
			slider_master.set_value_no_signal(float(am.master_volume) * 100.0)
		if slider_music:
			slider_music.set_value_no_signal(float(am.music_volume) * 100.0)
		if slider_sfx:
			slider_sfx.set_value_no_signal(float(am.sfx_volume) * 100.0)
	if btn_close_options:
		btn_close_options.grab_focus()


func _close_options_modal() -> void:
	_play_sfx("ui_back")
	options_modal.visible = false
	btn_options.grab_focus()


func _on_credits_pressed() -> void:
	_play_sfx("ui_select")
	_populate_credits_list()
	credits_modal.visible = true
	if btn_close_credits:
		btn_close_credits.grab_focus()


func _close_credits_modal() -> void:
	_play_sfx("ui_back")
	credits_modal.visible = false
	btn_music_credits.grab_focus()


func _on_volume_slider_changed(_val: float) -> void:
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").set_volumes(
			slider_master.value / 100.0,
			slider_music.value / 100.0,
			slider_sfx.value / 100.0
		)


func _on_exit_pressed() -> void:
	_play_sfx("ui_back")
	get_tree().quit()


func _play_sfx(sfx_name: String) -> void:
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").play_sfx(sfx_name)
