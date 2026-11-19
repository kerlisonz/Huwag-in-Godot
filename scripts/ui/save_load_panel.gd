class_name SaveLoadPanel
extends Control

signal slot_action_completed(slot_idx: int, mode: String)
signal panel_closed()

@onready var card: PanelContainer = $Card
@onready var title_label: Label = $Card/Margin/VBox/HeaderRow/TitleLabel
@onready var hint_label: Label = $Card/Margin/VBox/HeaderRow/HintLabel
@onready var divider: ColorRect = $Card/Margin/VBox/Divider
@onready var slots_vbox: VBoxContainer = $Card/Margin/VBox/SlotsVBox
@onready var status_label: Label = $Card/Margin/VBox/FooterRow/StatusLabel
@onready var btn_back: Button = $Card/Margin/VBox/FooterRow/BtnBack

var _mode: String = "load"
var _pending_screenshot: Image = null
var _selected_slot: int = 1
var _slot_panels: Array[PanelContainer] = []
var _slot_cursors: Array[TextureRect] = []
var _slot_summaries: Array[Dictionary] = []
var _cursor_timer: float = 0.0


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	if btn_back:
		btn_back.pressed.connect(close_panel)
	_apply_theme()


func is_open() -> bool:
	return visible


func open_panel(mode: String = "load", pending_screenshot: Image = null) -> void:
	_mode = "save" if mode == "save" else "load"
	_pending_screenshot = pending_screenshot
	_selected_slot = 1
	if title_label:
		title_label.text = "SALVAR JOGO" if _mode == "save" else "CARREGAR JOGO"
	if status_label:
		status_label.text = "Escolha onde gravar seu progresso." if _mode == "save" else "Escolha um registro para continuar."
	_apply_theme()
	_rebuild_slots()
	visible = true


func close_panel() -> void:
	if not visible:
		return
	visible = false
	_pending_screenshot = null
	_play_sfx("ui_back")
	panel_closed.emit()


func _process(delta: float) -> void:
	if not visible:
		return
	_cursor_timer += delta
	var bob := 2.0 if int(fmod(_cursor_timer * 4.0, 2.0)) == 1 else 0.0
	for i in range(_slot_cursors.size()):
		var c := _slot_cursors[i]
		if c and c.visible:
			c.custom_minimum_size = Vector2(20, 12)
			c.position.x = bob


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			close_panel()
			get_viewport().set_input_as_handled()
		elif event.keycode in [KEY_UP, KEY_W]:
			_selected_slot = 3 if _selected_slot <= 1 else _selected_slot - 1
			_refresh_selection()
			_play_sfx("ui_move")
			get_viewport().set_input_as_handled()
		elif event.keycode in [KEY_DOWN, KEY_S]:
			_selected_slot = 1 if _selected_slot >= 3 else _selected_slot + 1
			_refresh_selection()
			_play_sfx("ui_move")
			get_viewport().set_input_as_handled()
		elif event.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_E, KEY_Z, KEY_SPACE]:
			_activate_slot(_selected_slot)
			get_viewport().set_input_as_handled()


func _rebuild_slots() -> void:
	for child in slots_vbox.get_children():
		child.queue_free()
	_slot_panels.clear()
	_slot_cursors.clear()

	if has_node("/root/GameState"):
		_slot_summaries = get_node("/root/GameState").get_all_slot_summaries()
	else:
		_slot_summaries = []

	var ui_font := HuwagUiTheme.get_ui_font()
	var mode := _get_theme_mode()
	var pal := HuwagUiTheme.get_palette(mode)

	for idx in range(1, 4):
		var summary: Dictionary = _slot_summaries[idx - 1] if idx - 1 < _slot_summaries.size() else {"exists": false, "slot": idx}
		var exists: bool = bool(summary.get("exists", false))

		var row_panel := PanelContainer.new()
		row_panel.custom_minimum_size = Vector2(0, 58)
		row_panel.mouse_filter = Control.MOUSE_FILTER_STOP

		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 8)
		hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row_panel.add_child(hbox)

		var cur := TextureRect.new()
		cur.custom_minimum_size = Vector2(20, 12)
		cur.texture = HuwagUiTheme.build_omori_hand_cursor_texture()
		cur.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		cur.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
		cur.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hbox.add_child(cur)

		var thumb_frame := PanelContainer.new()
		thumb_frame.custom_minimum_size = Vector2(92, 50)
		thumb_frame.add_theme_stylebox_override("panel", HuwagUiTheme.make_omori_box_style(Color(0.04, 0.04, 0.06, 1), Color(1, 1, 1, 0.5), 2, 2))
		thumb_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE

		var thumb_path := str(summary.get("thumbnail_path", ""))
		var thumb_tex: Texture2D = _load_thumb_texture(thumb_path)
		if thumb_tex != null:
			var tr := TextureRect.new()
			tr.texture = thumb_tex
			tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
			tr.custom_minimum_size = Vector2(86, 44)
			tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
			thumb_frame.add_child(tr)
		else:
			var empty_lbl := Label.new()
			empty_lbl.text = "VAZIO" if not exists else "SEM FOTO"
			if ui_font:
				empty_lbl.add_theme_font_override("font", ui_font)
			empty_lbl.add_theme_font_size_override("font_size", 12)
			empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			empty_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			empty_lbl.add_theme_color_override("font_color", pal["text_muted"])
			thumb_frame.add_child(empty_lbl)
		hbox.add_child(thumb_frame)

		var info_box := VBoxContainer.new()
		info_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info_box.add_theme_constant_override("separation", 1)
		info_box.mouse_filter = Control.MOUSE_FILTER_IGNORE

		var l1 := Label.new()
		if ui_font:
			l1.add_theme_font_override("font", ui_font)
		l1.add_theme_font_size_override("font_size", 15)
		if exists:
			l1.text = "SLOT %d  ·  %s" % [idx, str(summary.get("place", "Agdangan")).to_upper()]
			l1.add_theme_color_override("font_color", pal["text"])
		else:
			l1.text = "SLOT %d  ·  LIVRE" % idx
			l1.add_theme_color_override("font_color", pal["text_muted"])
		info_box.add_child(l1)

		var l2 := Label.new()
		if ui_font:
			l2.add_theme_font_override("font", ui_font)
		l2.add_theme_font_size_override("font_size", 13)
		if exists:
			var tag_corr := " · CORROMPIDO" if bool(summary.get("corrupted", false)) else ""
			l2.text = "Ato %d  ·  %s  ·  HP %d%s" % [
				int(summary.get("ato", 1)),
				str(summary.get("clock_hhmm", "06:30")),
				int(summary.get("hp", 100)),
				tag_corr,
			]
			l2.add_theme_color_override("font_color", pal["accent"] if bool(summary.get("corrupted", false)) else pal["text_muted"])
		else:
			l2.text = "Clique para gravar aqui." if _mode == "save" else "Nenhum progresso salvo."
			l2.add_theme_color_override("font_color", Color(0.55, 0.58, 0.65, 1.0))
		info_box.add_child(l2)

		var l3 := Label.new()
		if ui_font:
			l3.add_theme_font_override("font", ui_font)
		l3.add_theme_font_size_override("font_size", 12)
		l3.text = str(summary.get("date", "")) if exists else ""
		l3.add_theme_color_override("font_color", Color(0.58, 0.61, 0.68, 1.0))
		info_box.add_child(l3)

		hbox.add_child(info_box)

		var captured_slot := idx
		row_panel.gui_input.connect(func(ev: InputEvent):
			if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
				_selected_slot = captured_slot
				_refresh_selection()
				_activate_slot(captured_slot)
				get_viewport().set_input_as_handled()
		)
		row_panel.mouse_entered.connect(func():
			if _selected_slot != captured_slot:
				_selected_slot = captured_slot
				_refresh_selection()
				_play_sfx("ui_move")
		)

		slots_vbox.add_child(row_panel)
		_slot_panels.append(row_panel)
		_slot_cursors.append(cur)

	_refresh_selection()


func _refresh_selection() -> void:
	var pal := HuwagUiTheme.get_palette(_get_theme_mode())
	for i in range(_slot_panels.size()):
		var is_sel := ((i + 1) == _selected_slot)
		var pnl := _slot_panels[i]
		var cur := _slot_cursors[i]
		if cur:
			cur.visible = is_sel
		if is_sel:
			pnl.add_theme_stylebox_override("panel", HuwagUiTheme.make_omori_box_style(pal["choice_sel_bg"], pal["border"], 6, 4))
		else:
			pnl.add_theme_stylebox_override("panel", HuwagUiTheme.make_omori_box_style(pal["bg"], Color(pal["border"].r, pal["border"].g, pal["border"].b, 0.35), 6, 4))


func _activate_slot(slot_idx: int) -> void:
	if not has_node("/root/GameState"):
		return
	var gs := get_node("/root/GameState")
	if _mode == "save":
		var ok := bool(gs.save_to_slot(slot_idx, _pending_screenshot))
		if ok:
			_rebuild_slots()
			if status_label:
				status_label.text = "Progresso salvo no Slot %d!" % slot_idx
			slot_action_completed.emit(slot_idx, "save")
		else:
			if status_label:
				status_label.text = "Erro ao gravar Slot %d." % slot_idx
	else:
		var summary := gs.get_slot_summary(slot_idx) as Dictionary
		if not bool(summary.get("exists", false)):
			_play_sfx("ui_back")
			if status_label:
				status_label.text = "Slot %d está vazio." % slot_idx
			return
		_play_sfx("ui_select")
		if gs.load_from_slot(slot_idx):
			visible = false
			slot_action_completed.emit(slot_idx, "load")


func _load_thumb_texture(path: String) -> Texture2D:
	if path.is_empty():
		return null
	var abs_p := ProjectSettings.globalize_path(path)
	if not FileAccess.file_exists(abs_p) and not FileAccess.file_exists(path):
		return null
	var img := Image.new()
	if img.load(abs_p if FileAccess.file_exists(abs_p) else path) == OK:
		return ImageTexture.create_from_image(img)
	return null


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
	if card:
		card.add_theme_stylebox_override("panel", HuwagUiTheme.make_omori_box_style(pal["bg"], pal["border"], 2, 2))
	if title_label:
		title_label.add_theme_color_override("font_color", pal["text"])
	if hint_label:
		hint_label.add_theme_color_override("font_color", pal["text_muted"])
	if divider:
		divider.color = Color(pal["border"].r, pal["border"].g, pal["border"].b, 0.45)
	if btn_back:
		btn_back.add_theme_stylebox_override("normal", HuwagUiTheme.make_omori_box_style(pal["choice_bg"], pal["border"], 8, 3))
		btn_back.add_theme_stylebox_override("hover", HuwagUiTheme.make_omori_box_style(pal["choice_sel_bg"], pal["border"], 8, 3))
		btn_back.add_theme_stylebox_override("focus", HuwagUiTheme.make_omori_box_style(pal["choice_sel_bg"], pal["border"], 8, 3))
		btn_back.add_theme_color_override("font_color", pal["text"])


func _play_sfx(sfx_name: String) -> void:
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").play_sfx(sfx_name)
