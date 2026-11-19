class_name PauseMenu
extends CanvasLayer

signal menu_closed()
signal return_to_title_requested()
signal load_slot_requested(slot_idx: int)

@onready var main_card: PanelContainer = $MainCard
@onready var title_label: Label = $MainCard/Margin/VBox/TitleLabel
@onready var context_label: Label = $MainCard/Margin/VBox/ContextLabel
@onready var buttons_vbox: VBoxContainer = $MainCard/Margin/VBox/ButtonsVBox
@onready var options_panel: PanelContainer = $OptionsPanel
@onready var slider_master: HSlider = $OptionsPanel/Margin/VBox/RowMaster/SliderMaster
@onready var slider_music: HSlider = $OptionsPanel/Margin/VBox/RowMusic/SliderMusic
@onready var slider_sfx: HSlider = $OptionsPanel/Margin/VBox/RowSfx/SliderSfx
@onready var check_fullscreen: CheckButton = $OptionsPanel/Margin/VBox/CheckFullscreen
@onready var check_flash: CheckButton = $OptionsPanel/Margin/VBox/CheckFlash
@onready var btn_options_back: Button = $OptionsPanel/Margin/VBox/BtnOptionsBack
@onready var confirm_panel: PanelContainer = $ConfirmPanel
@onready var btn_confirm_yes: Button = $ConfirmPanel/Margin/VBox/Btns/BtnConfirmYes
@onready var btn_confirm_no: Button = $ConfirmPanel/Margin/VBox/Btns/BtnConfirmNo
@onready var save_load_panel: SaveLoadPanel = $SaveLoadPanel

const ITEMS := [
	{"id": "resume", "label": "CONTINUAR"},
	{"id": "save", "label": "SALVAR JOGO"},
	{"id": "load", "label": "CARREGAR JOGO"},
	{"id": "options", "label": "OPÇÕES"},
	{"id": "title", "label": "MENU PRINCIPAL"},
]

var _captured_frame: Image = null
var _selected_idx: int = 0
var _item_panels: Array[PanelContainer] = []
var _item_labels: Array[Label] = []
var _item_cursors: Array[TextureRect] = []
var _cursor_timer: float = 0.0
var _just_opened: bool = false


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_menu_items()

	if btn_options_back:
		btn_options_back.pressed.connect(_close_options)
	if slider_master:
		slider_master.value_changed.connect(func(_v): _sync_volumes())
	if slider_music:
		slider_music.value_changed.connect(func(_v): _sync_volumes())
	if slider_sfx:
		slider_sfx.value_changed.connect(func(_v): _sync_volumes())
	if check_fullscreen:
		check_fullscreen.toggled.connect(func(on: bool):
			if has_node("/root/GameState"):
				get_node("/root/GameState").set_fullscreen(on)
		)
	if check_flash:
		check_flash.toggled.connect(func(on: bool):
			if has_node("/root/GameState"):
				get_node("/root/GameState").setting_flash_reduction = on
		)
	if btn_confirm_yes:
		btn_confirm_yes.pressed.connect(_confirm_exit_to_title)
	if btn_confirm_no:
		btn_confirm_no.pressed.connect(_close_confirm)
	if save_load_panel:
		save_load_panel.panel_closed.connect(_on_subpanel_closed)
		save_load_panel.slot_action_completed.connect(_on_slot_action_completed)

	_apply_theme()


func is_open() -> bool:
	return visible


func open_pause(captured_frame: Image = null) -> void:
	if visible:
		return
	_captured_frame = captured_frame
	_selected_idx = 0
	_just_opened = true
	if options_panel:
		options_panel.visible = false
	if confirm_panel:
		confirm_panel.visible = false
	if save_load_panel:
		save_load_panel.visible = false
	if main_card:
		main_card.visible = true
	_refresh_context()
	_apply_theme()
	_refresh_selection()
	visible = true
	if get_tree() != null:
		get_tree().paused = true
	_play_sfx("ui_select")


func close_pause() -> void:
	if not visible:
		return
	visible = false
	_captured_frame = null
	if options_panel:
		options_panel.visible = false
	if confirm_panel:
		confirm_panel.visible = false
	if save_load_panel:
		save_load_panel.visible = false
	if get_tree() != null:
		get_tree().paused = false
	_play_sfx("ui_back")
	menu_closed.emit()


func _process(delta: float) -> void:
	_just_opened = false
	if not visible:
		return
	_cursor_timer += delta
	var bob := 2.0 if int(fmod(_cursor_timer * 4.0, 2.0)) == 1 else 0.0
	for i in range(_item_cursors.size()):
		if _item_cursors[i] and _item_cursors[i].visible:
			_item_cursors[i].position.x = bob


func _input(event: InputEvent) -> void:
	if not visible or _just_opened:
		return
	if save_load_panel and save_load_panel.visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			if options_panel and options_panel.visible:
				_close_options()
			elif confirm_panel and confirm_panel.visible:
				_close_confirm()
			else:
				close_pause()
			get_viewport().set_input_as_handled()
			return
		if (options_panel and options_panel.visible) or (confirm_panel and confirm_panel.visible):
			return
		if event.keycode in [KEY_UP, KEY_W]:
			_selected_idx = (_selected_idx - 1 + ITEMS.size()) % ITEMS.size()
			_refresh_selection()
			_play_sfx("ui_move")
			get_viewport().set_input_as_handled()
		elif event.keycode in [KEY_DOWN, KEY_S]:
			_selected_idx = (_selected_idx + 1) % ITEMS.size()
			_refresh_selection()
			_play_sfx("ui_move")
			get_viewport().set_input_as_handled()
		elif event.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_E, KEY_Z, KEY_SPACE]:
			_activate_item(ITEMS[_selected_idx]["id"])
			get_viewport().set_input_as_handled()


func _build_menu_items() -> void:
	for c in buttons_vbox.get_children():
		c.queue_free()
	_item_panels.clear()
	_item_labels.clear()
	_item_cursors.clear()

	var ui_font := HuwagUiTheme.get_ui_font()
	for i in range(ITEMS.size()):
		var item: Dictionary = ITEMS[i]
		var pnl := PanelContainer.new()
		pnl.mouse_filter = Control.MOUSE_FILTER_STOP
		pnl.custom_minimum_size = Vector2(0, 28)

		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pnl.add_child(row)

		var cur := TextureRect.new()
		cur.custom_minimum_size = Vector2(20, 12)
		cur.texture = HuwagUiTheme.build_omori_hand_cursor_texture()
		cur.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		cur.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
		cur.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(cur)

		var lbl := Label.new()
		lbl.text = str(item["label"])
		if ui_font:
			lbl.add_theme_font_override("font", ui_font)
		lbl.add_theme_font_size_override("font_size", 16)
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(lbl)

		var idx := i
		var id_str := str(item["id"])
		pnl.gui_input.connect(func(ev: InputEvent):
			if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
				_selected_idx = idx
				_refresh_selection()
				_activate_item(id_str)
				get_viewport().set_input_as_handled()
		)
		pnl.mouse_entered.connect(func():
			if _selected_idx != idx:
				_selected_idx = idx
				_refresh_selection()
				_play_sfx("ui_move")
		)

		buttons_vbox.add_child(pnl)
		_item_panels.append(pnl)
		_item_labels.append(lbl)
		_item_cursors.append(cur)


func _activate_item(item_id: String) -> void:
	match item_id:
		"resume":
			close_pause()
		"save":
			_play_sfx("ui_select")
			main_card.visible = false
			save_load_panel.open_panel("save", _captured_frame)
		"load":
			_play_sfx("ui_select")
			main_card.visible = false
			save_load_panel.open_panel("load", null)
		"options":
			_open_options()
		"title":
			_open_confirm()


func _open_options() -> void:
	_play_sfx("ui_select")
	if has_node("/root/AudioManager"):
		var am := get_node("/root/AudioManager")
		if slider_master:
			slider_master.set_value_no_signal(float(am.get("master_volume")) * 100.0)
		if slider_music:
			slider_music.set_value_no_signal(float(am.get("music_volume")) * 100.0)
		if slider_sfx:
			slider_sfx.set_value_no_signal(float(am.get("sfx_volume")) * 100.0)
	if has_node("/root/GameState"):
		var gs := get_node("/root/GameState")
		if check_fullscreen:
			check_fullscreen.set_pressed_no_signal(gs.is_fullscreen())
		if check_flash:
			check_flash.set_pressed_no_signal(gs.setting_flash_reduction)
	main_card.visible = false
	options_panel.visible = true


func _close_options() -> void:
	_play_sfx("ui_back")
	options_panel.visible = false
	main_card.visible = true


func _open_confirm() -> void:
	_play_sfx("ui_select")
	main_card.visible = false
	confirm_panel.visible = true


func _close_confirm() -> void:
	_play_sfx("ui_back")
	confirm_panel.visible = false
	main_card.visible = true


func _confirm_exit_to_title() -> void:
	_play_sfx("ui_select")
	visible = false
	if get_tree() != null:
		get_tree().paused = false
	return_to_title_requested.emit()
	if get_tree() != null:
		get_tree().change_scene_to_file("res://scenes/menu/TitleScreen.tscn")


func _on_subpanel_closed() -> void:
	if visible and main_card:
		main_card.visible = true


func _on_slot_action_completed(slot_idx: int, mode: String) -> void:
	if mode == "save":
		if main_card:
			main_card.visible = true
	elif mode == "load":
		visible = false
		if get_tree() != null:
			get_tree().paused = false
		load_slot_requested.emit(slot_idx)
		if get_tree() != null:
			get_tree().change_scene_to_file("res://scenes/main/Main.tscn")


func _sync_volumes() -> void:
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").set_volumes(
			slider_master.value / 100.0,
			slider_music.value / 100.0,
			slider_sfx.value / 100.0
		)


func _refresh_context() -> void:
	if context_label == null or not has_node("/root/GameState"):
		return
	var gs := get_node("/root/GameState")
	var ato := int(gs.get_var("Ato", 1))
	var place: String = str(gs.get_place_display_name(str(gs.current_scene_path)))
	var hhmm: String = str(gs.get_formatted_time())
	context_label.text = "Ato %d · %s · %s" % [ato, place, hhmm]


func _refresh_selection() -> void:
	var pal := HuwagUiTheme.get_palette(_get_theme_mode())
	var sb_sel := StyleBoxFlat.new()
	sb_sel.bg_color = pal["choice_sel_bg"]
	sb_sel.content_margin_left = 6.0
	sb_sel.content_margin_right = 8.0
	sb_sel.content_margin_top = 4.0
	sb_sel.content_margin_bottom = 4.0
	var sb_idle := StyleBoxEmpty.new()
	sb_idle.content_margin_left = 6.0
	sb_idle.content_margin_right = 8.0
	sb_idle.content_margin_top = 4.0
	sb_idle.content_margin_bottom = 4.0
	for i in range(_item_panels.size()):
		var is_sel := (i == _selected_idx)
		_item_cursors[i].visible = is_sel
		if is_sel:
			_item_panels[i].add_theme_stylebox_override("panel", sb_sel)
			_item_labels[i].add_theme_color_override("font_color", pal["text"])
		else:
			_item_panels[i].add_theme_stylebox_override("panel", sb_idle)
			_item_labels[i].add_theme_color_override("font_color", pal["text_muted"])


func _get_theme_mode() -> String:
	if has_node("/root/GameState"):
		var gs := get_node("/root/GameState")
		if gs.has_method("is_unfiltered_act3") and bool(gs.call("is_unfiltered_act3")):
			return "act3"
		if gs.has_method("is_corrupted_mode") and bool(gs.call("is_corrupted_mode")):
			return "distorted"
	return "normal"


func _apply_theme() -> void:
	var pal := HuwagUiTheme.get_palette(_get_theme_mode())
	for pnl in [main_card, options_panel, confirm_panel]:
		if pnl:
			pnl.add_theme_stylebox_override("panel", HuwagUiTheme.make_omori_box_style(pal["bg"], pal["border"], 5, 5, 3))
	if title_label:
		title_label.add_theme_color_override("font_color", pal["text"])
	if context_label:
		context_label.add_theme_color_override("font_color", pal["text_muted"])
	for btn in [btn_options_back, btn_confirm_yes, btn_confirm_no]:
		if btn:
			btn.add_theme_stylebox_override("normal", HuwagUiTheme.make_omori_box_style(pal["choice_bg"], pal["border"], 8, 4, 2))
			btn.add_theme_stylebox_override("hover", HuwagUiTheme.make_omori_box_style(pal["choice_sel_bg"], pal["border"], 8, 4, 2))
			btn.add_theme_stylebox_override("focus", HuwagUiTheme.make_omori_box_style(pal["choice_sel_bg"], pal["border"], 8, 4, 2))
			btn.add_theme_color_override("font_color", pal["text"])


func _play_sfx(sfx_name: String) -> void:
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").play_sfx(sfx_name)
