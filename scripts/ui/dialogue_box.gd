class_name DialogueBox
extends Control

signal dialogue_finished(choice_index: int)
signal conflict_triggered(target_id: String, context: Dictionary)

@onready var frame_panel: Panel = $FramePanel
@onready var nameplate_panel: PanelContainer = $NameplatePanel
@onready var speaker_label: Label = $NameplatePanel/NameplateMargin/SpeakerLabel
@onready var portrait_frame: PanelContainer = $PortraitFrame
@onready var portrait_texture: TextureRect = $PortraitFrame/SpeakerPortrait
@onready var speech_area: Control = $SpeechArea
@onready var dialogue_label: Label = $SpeechArea/DialogueText
@onready var choices_panel: PanelContainer = $ChoicesPanel
@onready var choices_vbox: VBoxContainer = $ChoicesPanel/ChoicesMargin/ChoicesVBox
@onready var continue_hint: TextureRect = $ContinueHint

var active: bool = false
var _pages: Array = []
var _page_index: int = 0
var _current_choices: Array = []
var _selected_choice: int = 0
var _choice_labels: Array[Label] = []
var _choice_boxes: Array[PanelContainer] = []
var _choice_cursors: Array[TextureRect] = []
var _full_text: String = ""
var _revealed_chars: float = 0.0
var _typing: bool = false
var _chars_per_sec: float = 48.0
var _last_speaker_id: String = ""
var _last_expression: String = ""
var _portrait_cache: Dictionary = {}
var _cursor_timer: float = 0.0
var _is_corrupted_theme: bool = false
var _theme_mode: String = "normal"
var _advance_cooldown: float = 0.0
var _base_hint_pos_x: float = 0.0
var _base_hint_pos_y: float = 0.0

const SCROLL_ACCENT_COLOR_DEFAULT := Color(1.0, 1.0, 1.0, 1.0)


func _ready() -> void:
	visible = false
	active = false
	choices_panel.visible = false
	continue_hint.visible = false
	if continue_hint:
		_base_hint_pos_x = continue_hint.position.x
		_base_hint_pos_y = continue_hint.position.y
	if portrait_texture:
		portrait_texture.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if has_node("/root/GameState"):
		var gs := get_node("/root/GameState")
		if gs.has_signal("perception_changed"):
			gs.perception_changed.connect(_on_perception_changed)
	_apply_theme(_resolve_base_theme_mode())


func _on_perception_changed(_mode: int) -> void:
	if visible:
		_apply_theme("distorted" if _is_corrupted_theme else _resolve_base_theme_mode())
	else:
		_apply_theme(_resolve_base_theme_mode())


func is_open() -> bool:
	return visible and active


func _resolve_base_theme_mode() -> String:
	if has_node("/root/GameState"):
		var gs := get_node("/root/GameState")
		if gs.has_method("is_unfiltered_act3") and bool(gs.call("is_unfiltered_act3")):
			return "act3"
	return "normal"


func start_dialogue(pages: Array) -> void:
	if pages.is_empty():
		dialogue_finished.emit(-1)
		return
	_pages = pages.duplicate(true)
	_page_index = 0
	active = true
	visible = true
	_advance_cooldown = 0.14
	if has_node("/root/GameState"):
		var gs := get_node("/root/GameState")
		gs.dialogue_active = true
	_last_speaker_id = ""
	_last_expression = ""
	_show_current_page()
	_play_box_open_animation()


func _process(delta: float) -> void:
	if not active:
		return
	if _advance_cooldown > 0.0:
		_advance_cooldown -= delta
	if _typing:
		_revealed_chars += delta * _chars_per_sec
		var chars_now: int = mini(int(_revealed_chars), _full_text.length())
		dialogue_label.visible_characters = chars_now
		if chars_now >= _full_text.length():
			_finish_typing()
	if continue_hint.visible:
		_cursor_timer += delta
		var step := int(fmod(_cursor_timer * 4.0, 4.0))
		var dx := 0.0 if step == 0 else (1.5 if step in [1, 3] else 3.0)
		var base_x := frame_panel.position.x + frame_panel.size.x - 28.0 if frame_panel else _base_hint_pos_x
		var base_y := frame_panel.position.y + frame_panel.size.y - 20.0 if frame_panel else _base_hint_pos_y
		continue_hint.position.x = base_x + dx
		continue_hint.position.y = base_y


func _input(event: InputEvent) -> void:
	if not is_open():
		return
	_handle_dialogue_input(event)


func _unhandled_input(event: InputEvent) -> void:
	if not is_open():
		return
	_handle_dialogue_input(event)


func _handle_dialogue_input(event: InputEvent) -> void:
	if _advance_cooldown > 0.0:
		return

	if not _typing and not _current_choices.is_empty():
		if event.is_action_pressed("ui_up") or (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_W):
			_move_choice(-1)
			get_viewport().set_input_as_handled()
			return
		elif event.is_action_pressed("ui_down") or (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_S):
			_move_choice(1)
			get_viewport().set_input_as_handled()
			return

	var accept: bool = (
		event.is_action_pressed("interact")
		or event.is_action_pressed("ui_accept")
		or (event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_E, KEY_Z, KEY_ENTER, KEY_SPACE])
		or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT)
	)
	if accept:
		get_viewport().set_input_as_handled()
		if _typing:
			_finish_typing()
		elif not _current_choices.is_empty():
			_advance_page()
		else:
			_advance_page()


func _move_choice(delta_idx: int) -> void:
	if _current_choices.is_empty():
		return
	_selected_choice = (_selected_choice + delta_idx + _current_choices.size()) % _current_choices.size()
	_refresh_choices_visual()
	_play_ui_sfx("ui_move")


func _infer_expression(speaker_id: String, text: String, explicit_expr: String) -> String:
	if not explicit_expr.strip_edges().is_empty():
		return explicit_expr.strip_edges().to_lower()
	if has_node("/root/GameState"):
		var gs := get_node("/root/GameState")
		if gs.has_method("is_corrupted_mode") and bool(gs.call("is_corrupted_mode")) and speaker_id != "huwag":
			return "distorted"
	var low := text.to_lower()
	if low.contains("socorro") or low.contains("medo") or low.contains("pavor") or low.contains("monstro") or low.contains("olhos") or low.contains("sangue"):
		return "scared"
	if low.contains("raiva") or low.contains("basta") or low.contains("pare") or low.contains("mentira") or low.contains("não vou") or low.contains("fogo!"):
		return "angry"
	if low.contains("?") and (low.contains("como") or low.contains("quem") or low.contains("que") or low.contains("espera") or low.contains("sério")):
		return "surprised"
	if low.contains("desculp") or low.contains("cuidado") or low.contains("perigo") or low.contains("preocup") or low.contains("sinto muito") or low.contains("dose"):
		return "worried"
	if low.contains("cansad") or low.contains("sono") or low.contains("noite") or low.contains("pesadel") or low.contains("exausto") or low.contains("..."):
		return "tired"
	if low.contains("obrigad") or low.contains("bom dia") or low.contains("sorri") or low.contains("gentil"):
		return "uneasy_smile"
	return "neutral"


func _load_cached_texture(path: String) -> Texture2D:
	if path.is_empty():
		return null
	if _portrait_cache.has(path):
		return _portrait_cache[path] as Texture2D
	if ResourceLoader.exists(path):
		var loaded := load(path) as Texture2D
		if loaded != null:
			_portrait_cache[path] = loaded
			return loaded
	var abs_p := ProjectSettings.globalize_path(path)
	if FileAccess.file_exists(abs_p):
		var im := Image.new()
		if im.load(abs_p) == OK:
			var tex := ImageTexture.create_from_image(im)
			_portrait_cache[path] = tex
			return tex
	return null


func _show_current_page() -> void:
	choices_panel.visible = false
	continue_hint.visible = false
	_current_choices.clear()

	var page: Dictionary = _pages[_page_index]
	var raw_speaker: String = str(page.get("speaker", "Huwag Matitiis"))
	var text: String = str(page.get("text", ""))
	var explicit_expr: String = str(page.get("expression", ""))
	var explicit_outfit: String = str(page.get("outfit", ""))
	var is_monologue: bool = bool(page.get("is_monologue", page.get("is_thought", false)))
	var hide_portrait: bool = (page.has("show_portrait") and not bool(page.get("show_portrait")))

	var is_act3 := false
	var outfit_id := explicit_outfit if not explicit_outfit.is_empty() else "casual"
	if has_node("/root/GameState"):
		var gs := get_node("/root/GameState")
		is_act3 = gs.has_method("is_unfiltered_act3") and bool(gs.call("is_unfiltered_act3"))
		if explicit_outfit.is_empty() and gs.get("equipped_outfit") != null:
			outfit_id = str(gs.get("equipped_outfit"))

	var speaker_id := CharacterProfiles.resolve_speaker_id(raw_speaker)
	var expr := _infer_expression(speaker_id, text, explicit_expr)
	var profile := CharacterProfiles.get_profile_data(raw_speaker, expr, is_act3, outfit_id)

	var display_name: String = str(profile.get("display_name", raw_speaker))
	var portrait_path: String = str(profile.get("portrait_path", ""))
	var explicit_portrait: String = str(page.get("portrait", ""))
	if not explicit_portrait.is_empty():
		portrait_path = explicit_portrait

	var resolved_expr: String = str(profile.get("expression", expr))
	_is_corrupted_theme = (
		resolved_expr == "distorted"
		or bool(page.get("distorted", false))
	)
	var target_mode := "distorted" if _is_corrupted_theme else _resolve_base_theme_mode()
	_apply_theme(target_mode)

	if speaker_label:
		speaker_label.text = display_name.to_upper()
	if nameplate_panel:
		var show_name := (not display_name.is_empty()) and (not is_monologue)
		nameplate_panel.visible = show_name
		if show_name:
			nameplate_panel.reset_size()
			var target_w := maxf(76.0, speaker_label.get_minimum_size().x + 24.0)
			nameplate_panel.offset_right = nameplate_panel.offset_left + target_w

	var pal := HuwagUiTheme.get_palette(target_mode)
	if speaker_label:
		speaker_label.add_theme_color_override("font_color", pal["text"])

	var tex := _load_cached_texture(portrait_path)
	var show_p := (not hide_portrait) and (tex != null)
	portrait_frame.visible = show_p
	if show_p:
		portrait_texture.texture = tex
		portrait_texture.modulate = Color.WHITE

	var trimmed := text.strip_edges()
	dialogue_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	dialogue_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	dialogue_label.text = trimmed
	dialogue_label.add_theme_color_override("font_color", pal["text_muted"] if is_monologue else pal["text"])

	_full_text = trimmed
	_revealed_chars = 0.0
	dialogue_label.visible_characters = 0

	if page.has("choices") and typeof(page["choices"]) == TYPE_ARRAY:
		_current_choices = page["choices"].duplicate()

	if _full_text.is_empty():
		_typing = false
		_finish_typing()
	else:
		_typing = true
		_play_ui_sfx("ui_dialogue")

	if _last_speaker_id.is_empty() and show_p:
		_last_speaker_id = speaker_id
		_last_expression = resolved_expr
	elif speaker_id != _last_speaker_id or resolved_expr != _last_expression:
		if show_p:
			_play_speaker_switch_transition()
		_last_speaker_id = speaker_id
		_last_expression = resolved_expr


func _play_box_open_animation() -> void:
	if portrait_frame.visible:
		portrait_texture.modulate.a = 0.0
		var ptw := create_tween()
		ptw.tween_property(portrait_texture, "modulate:a", 1.0, 0.14)


func _play_speaker_switch_transition() -> void:
	if portrait_frame.visible:
		portrait_texture.modulate.a = 0.35
		var ptw := create_tween()
		ptw.tween_property(portrait_texture, "modulate:a", 1.0, 0.12)


func _finish_typing() -> void:
	_typing = false
	dialogue_label.visible_characters = -1
	if not _current_choices.is_empty():
		_populate_choices()
	else:
		continue_hint.visible = true
		_cursor_timer = 0.0
		continue_hint.position.x = _base_hint_pos_x


func _populate_choices() -> void:
	for child in choices_vbox.get_children():
		child.queue_free()
	_choice_labels.clear()
	_choice_boxes.clear()
	_choice_cursors.clear()

	for i in range(_current_choices.size()):
		var btn_box := PanelContainer.new()
		btn_box.mouse_filter = Control.MOUSE_FILTER_STOP
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE

		var cursor_icon := TextureRect.new()
		cursor_icon.custom_minimum_size = Vector2(18, 12)
		cursor_icon.texture = HuwagUiTheme.build_omori_hand_cursor_texture()
		cursor_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		cursor_icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
		cursor_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(cursor_icon)

		var lbl := Label.new()
		lbl.text = str(_current_choices[i])
		var f := HuwagUiTheme.get_ui_font()
		if f:
			lbl.add_theme_font_override("font", f)
		lbl.add_theme_font_size_override("font_size", 16)
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(lbl)

		btn_box.add_child(row)
		var idx := i
		btn_box.gui_input.connect(func(ev: InputEvent):
			if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
				_selected_choice = idx
				_refresh_choices_visual()
				get_viewport().set_input_as_handled()
				_advance_page()
		)
		btn_box.mouse_entered.connect(func():
			if _selected_choice != idx:
				_selected_choice = idx
				_refresh_choices_visual()
				_play_ui_sfx("ui_move")
		)
		choices_vbox.add_child(btn_box)
		_choice_labels.append(lbl)
		_choice_boxes.append(btn_box)
		_choice_cursors.append(cursor_icon)

	_selected_choice = 0
	var bottom_y := -146.0 if (nameplate_panel != null and nameplate_panel.visible) else -116.0
	choices_panel.offset_bottom = bottom_y
	choices_panel.offset_top = bottom_y - float(maxi(1, _current_choices.size()) * 26 + 16)
	_refresh_choices_visual()
	choices_panel.visible = true


func _refresh_choices_visual() -> void:
	var pal := HuwagUiTheme.get_palette(_theme_mode)
	for i in range(_choice_labels.size()):
		var lbl := _choice_labels[i]
		var box := _choice_boxes[i]
		var cur := _choice_cursors[i]
		var is_sel := (i == _selected_choice)
		lbl.text = str(_current_choices[i])
		cur.visible = is_sel
		cur.modulate = Color.WHITE if is_sel else Color(1, 1, 1, 0)
		if is_sel:
			box.add_theme_stylebox_override("panel", HuwagUiTheme.make_omori_box_style(pal["choice_sel_bg"], pal["choice_sel_border"], 6, 3))
			lbl.add_theme_color_override("font_color", pal["text"])
		else:
			box.add_theme_stylebox_override("panel", HuwagUiTheme.make_omori_box_style(pal["choice_bg"], Color(pal["border"].r, pal["border"].g, pal["border"].b, 0.35), 6, 3))
			lbl.add_theme_color_override("font_color", pal["text_muted"])


func _advance_page() -> void:
	_play_ui_sfx("ui_select")
	var current_page: Dictionary = _pages[_page_index] if (_page_index >= 0 and _page_index < _pages.size()) else {}
	var chosen: int = _selected_choice if not _current_choices.is_empty() else -1
	var conflict_target: String = _resolve_conflict_target(current_page, chosen)
	_page_index += 1
	if _page_index >= _pages.size():
		_close_dialogue()
		dialogue_finished.emit(chosen)
		if not conflict_target.is_empty():
			conflict_triggered.emit(conflict_target, {
				"choice": chosen,
				"speaker": str(current_page.get("speaker", "")),
			})
	else:
		_show_current_page()


func _resolve_conflict_target(page: Dictionary, choice_index: int) -> String:
	if page.has("trigger_conflict"):
		var direct := str(page.get("trigger_conflict", ""))
		if not direct.is_empty():
			return direct
	if page.has("conflict_choices") and typeof(page["conflict_choices"]) == TYPE_DICTIONARY and choice_index >= 0:
		var cmap: Dictionary = page["conflict_choices"]
		if cmap.has(choice_index):
			return str(cmap[choice_index])
		var k_str := str(choice_index)
		if cmap.has(k_str):
			return str(cmap[k_str])
	return ""


func close_dialogue() -> void:
	_close_dialogue()


func _close_dialogue() -> void:
	_is_corrupted_theme = false
	active = false
	visible = false
	choices_panel.visible = false
	continue_hint.visible = false
	_current_choices.clear()
	if has_node("/root/GameState"):
		var gs := get_node("/root/GameState")
		gs.dialogue_active = false
		if gs.has_method("notify_dialogue_closed"):
			gs.notify_dialogue_closed(0.28)


func _apply_theme(mode: String) -> void:
	_theme_mode = mode
	var pal := HuwagUiTheme.get_palette(mode)

	if frame_panel:
		frame_panel.add_theme_stylebox_override("panel", HuwagUiTheme.make_omori_box_style(pal["bg"], pal["border"], 8, 6))
	if nameplate_panel:
		nameplate_panel.add_theme_stylebox_override("panel", HuwagUiTheme.make_omori_box_style(pal["bg"], pal["border"], 0, 0))
	if portrait_frame:
		portrait_frame.add_theme_stylebox_override("panel", HuwagUiTheme.make_omori_box_style(pal["bg_inner"], pal["border"], 4, 4))
	if choices_panel:
		choices_panel.add_theme_stylebox_override("panel", HuwagUiTheme.make_omori_box_style(pal["bg"], pal["border"], 2, 2))

	var ui_font := HuwagUiTheme.get_ui_font()
	if ui_font:
		if speaker_label:
			speaker_label.add_theme_font_override("font", ui_font)
		if dialogue_label:
			dialogue_label.add_theme_font_override("font", ui_font)

	if speaker_label:
		speaker_label.add_theme_font_size_override("font_size", 16)
		speaker_label.add_theme_color_override("font_color", pal["text"])
	if dialogue_label:
		dialogue_label.add_theme_font_size_override("font_size", 16)
		dialogue_label.add_theme_color_override("font_color", pal["text"])
	if continue_hint:
		continue_hint.texture = HuwagUiTheme.build_omori_hand_cursor_texture()
		continue_hint.modulate = Color.WHITE


func _play_ui_sfx(sfx_name: String) -> void:
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").play_sfx(sfx_name)
