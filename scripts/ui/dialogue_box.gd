class_name DialogueBox
extends Control

signal dialogue_finished(choice_index: int)
signal conflict_triggered(target_id: String, context: Dictionary)

@onready var frame_panel: Panel = $FramePanel
@onready var top_trim: ColorRect = $TopTrim
@onready var vhs_scuff_left: ColorRect = $TopTrim/VhsScuffLeft
@onready var vhs_scuff_right: ColorRect = $TopTrim/VhsScuffRight
@onready var portrait_frame: PanelContainer = $PortraitFrame
@onready var portrait_texture: TextureRect = $PortraitFrame/SpeakerPortrait
@onready var speech_area: Control = $SpeechArea
@onready var speaker_label: Label = $SpeechArea/SpeakerLabel
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

const CURSOR_BASE_TOP := -12.0
const PIXEL_FONT := preload("res://assets/fonts/undertale-deltarune-extended-fixed.otf")


func _ready() -> void:
	hide()
	mouse_filter = Control.MOUSE_FILTER_STOP
	if portrait_texture:
		portrait_texture.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		portrait_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if continue_hint:
		continue_hint.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_apply_theme("normal")

	if has_node("/root/GameState"):
		var gs := get_node("/root/GameState")
		if gs.has_signal("perception_changed") and not gs.is_connected("perception_changed", _on_perception_changed):
			gs.connect("perception_changed", _on_perception_changed)


func _on_perception_changed(_mode: int) -> void:
	if active and _page_index >= 0 and _page_index < _pages.size():
		_show_current_page()
	else:
		_apply_theme(_resolve_base_theme_mode())


func is_open() -> bool:
	return active and visible


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
	if has_node("/root/GameState"):
		get_node("/root/GameState").dialogue_active = true
	if not is_visible_in_tree():
		_last_speaker_id = ""
		_last_expression = ""
	show()
	_show_current_page()


func _process(delta: float) -> void:
	if not active:
		return

	if _typing:
		_revealed_chars += _chars_per_sec * delta
		var chars_now: int = mini(int(_revealed_chars), _full_text.length())
		dialogue_label.visible_characters = chars_now
		if chars_now >= _full_text.length():
			_finish_typing()
	elif continue_hint and continue_hint.visible:
		_cursor_timer += delta
		var step := int(fmod(_cursor_timer * 3.5, 4.0))
		var dy := 0.0 if step == 0 else (1.0 if step in [1, 3] else 2.0)
		continue_hint.offset_top = CURSOR_BASE_TOP + dy
		continue_hint.offset_bottom = CURSOR_BASE_TOP + 6.0 + dy


func _unhandled_input(event: InputEvent) -> void:
	if not active:
		return

	if _current_choices.size() > 0:
		if event.is_action_pressed("ui_up") or (event is InputEventKey and event.pressed and (event.keycode == KEY_W or event.keycode == KEY_UP)):
			_move_choice(-1)
			get_viewport().set_input_as_handled()
			return
		elif event.is_action_pressed("ui_down") or (event is InputEventKey and event.pressed and (event.keycode == KEY_S or event.keycode == KEY_DOWN)):
			_move_choice(1)
			get_viewport().set_input_as_handled()
			return

	var accept: bool = (
		event.is_action_pressed("ui_accept")
		or event.is_action_pressed("interact")
		or (event is InputEventKey and event.pressed and not event.echo and (event.keycode == KEY_E or event.keycode == KEY_ENTER or event.keycode == KEY_SPACE or event.keycode == KEY_Z))
		or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and _current_choices.is_empty())
	)

	if accept:
		get_viewport().set_input_as_handled()
		if _typing:
			_finish_typing()
		else:
			_advance_page()


func _move_choice(delta_idx: int) -> void:
	if _current_choices.is_empty():
		return
	_selected_choice = wrapi(_selected_choice + delta_idx, 0, _current_choices.size())
	_refresh_choices_visual()
	_play_ui_sfx("ui_hover")


func _infer_expression(speaker_id: String, text: String, explicit_expr: String) -> String:
	if not explicit_expr.strip_edges().is_empty():
		return explicit_expr.strip_edges().to_lower()
	if speaker_id != "huwag":
		return "default"

	var low := text.to_lower()
	if "não aguento" in low or "desabou" in low or "sangue" in low or "breu" in low or "vazio" in low or "sufoc" in low or "fumaça" in low:
		return "scared"
	if "!" in text and ("afaste" in low or "atacar" in low or "chega" in low or "agora" in low or "fora" in low):
		return "angry"
	if "?" in text and ("como" in low or "o que" in low or "onde" in low or "quem" in low):
		return "surprised"
	if "cansa" in low or "dorm" in low or "noite" in low or "exaust" in low or "hospital" in low:
		return "tired"
	if "culpa" in low or "receio" in low or "remédio" in low or "comprimid" in low or "triste" in low or "temo" in low:
		return "worried"
	if "obrigado" in low or "bom dia" in low or "salamat" in low or "calma" in low or "equilíbrio" in low:
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
	if _page_index >= _pages.size():
		_close_dialogue()
		return

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
		is_act3 = bool(gs.call("is_unfiltered_act3"))
		if explicit_outfit.is_empty() and gs.get("equipped_outfit") != null:
			outfit_id = str(gs.get("equipped_outfit"))

	var speaker_id := CharacterProfiles.resolve_speaker_id(raw_speaker)
	var expr := _infer_expression(speaker_id, text, explicit_expr)
	var profile := CharacterProfiles.get_profile_data(raw_speaker, expr, is_act3, outfit_id)

	var display_name: String = str(profile.get("display_name", raw_speaker))
	var portrait_path: String = str(profile.get("portrait_path", ""))
	var explicit_portrait: String = str(page.get("portrait", ""))
	if explicit_portrait.begins_with("res://") and ResourceLoader.exists(explicit_portrait):
		portrait_path = explicit_portrait

	var resolved_expr: String = str(profile.get("expression", expr))
	_is_corrupted_theme = (
		resolved_expr == "distorted"
		or bool(page.get("distorted", false))
		or (speaker_id == "vulto_bosque" and not is_act3)
	)
	var target_mode := "distorted" if _is_corrupted_theme else _resolve_base_theme_mode()
	_apply_theme(target_mode)

	if speaker_label:
		speaker_label.text = display_name.to_upper()
		speaker_label.visible = not display_name.is_empty() and not is_monologue
		var pal := HuwagUiTheme.get_palette(target_mode)
		speaker_label.add_theme_color_override("font_color", profile.get("accent_color", pal["accent"]))

	if portrait_frame and portrait_texture:
		var tex := _load_cached_texture(portrait_path)
		var show_p := (not hide_portrait) and (tex != null)
		portrait_frame.visible = show_p
		if show_p:
			portrait_texture.texture = tex
			portrait_texture.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			portrait_texture.modulate = Color.WHITE
		if speech_area:
			speech_area.offset_left = 90.0 if show_p else 14.0

	if dialogue_label:
		dialogue_label.offset_top = 12.0 if (speaker_label and speaker_label.visible) else 2.0
		var trimmed := text.strip_edges()
		var short_centered := (trimmed.length() <= 92 and trimmed.count("\n") <= 1)
		dialogue_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER if short_centered else HORIZONTAL_ALIGNMENT_LEFT
		dialogue_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		dialogue_label.text = text

	_full_text = text
	_revealed_chars = 0.0
	_typing = true
	dialogue_label.visible_characters = 0

	if continue_hint:
		continue_hint.visible = false
	_cursor_timer = 0.0

	for child in choices_vbox.get_children():
		child.queue_free()
	_choice_labels.clear()
	_choice_boxes.clear()
	_current_choices = page.get("choices", [])
	_selected_choice = 0
	if choices_panel:
		choices_panel.visible = false

	if _page_index == 0 and speaker_id != _last_speaker_id:
		_play_box_open_animation()
	elif speaker_id != _last_speaker_id or resolved_expr != _last_expression:
		_play_speaker_switch_transition()

	_last_speaker_id = speaker_id
	_last_expression = resolved_expr


func _play_box_open_animation() -> void:
	if portrait_texture:
		portrait_texture.modulate.a = 0.0
		var ptw := create_tween()
		ptw.tween_property(portrait_texture, "modulate:a", 1.0, 0.14)


func _play_speaker_switch_transition() -> void:
	if portrait_texture:
		portrait_texture.modulate.a = 0.35
		var ptw := create_tween()
		ptw.tween_property(portrait_texture, "modulate:a", 1.0, 0.12)


func _finish_typing() -> void:
	_typing = false
	dialogue_label.visible_characters = -1
	if _current_choices.size() > 0:
		_populate_choices()
	else:
		if continue_hint:
			continue_hint.visible = true
		_cursor_timer = 0.0


func _populate_choices() -> void:
	for child in choices_vbox.get_children():
		child.queue_free()
	_choice_labels.clear()
	_choice_boxes.clear()

	for i in range(_current_choices.size()):
		var btn_box := PanelContainer.new()
		btn_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn_box.mouse_filter = Control.MOUSE_FILTER_STOP
		var lbl := Label.new()
		lbl.custom_minimum_size = Vector2(220, 0)
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbl.text = "► " + str(_current_choices[i])
		lbl.add_theme_font_override("font", PIXEL_FONT)
		lbl.add_theme_font_size_override("font_size", 7)
		lbl.add_theme_constant_override("shadow_offset_x", 1)
		lbl.add_theme_constant_override("shadow_offset_y", 1)
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		btn_box.add_child(lbl)

		btn_box.mouse_entered.connect(func():
			_selected_choice = i
			_refresh_choices_visual()
			_play_ui_sfx("ui_hover")
		)
		btn_box.gui_input.connect(func(ev: InputEvent):
			if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
				_selected_choice = i
				_advance_page()
		)

		choices_vbox.add_child(btn_box)
		_choice_boxes.append(btn_box)
		_choice_labels.append(lbl)

	if choices_panel:
		choices_panel.custom_minimum_size = Vector2(252, 0)
		choices_panel.visible = true
		choices_panel.reset_size()
	_refresh_choices_visual()


func _refresh_choices_visual() -> void:
	var pal := HuwagUiTheme.get_palette(_theme_mode)
	for i in range(_choice_labels.size()):
		var lbl := _choice_labels[i]
		var box := _choice_boxes[i]
		var is_sel := (i == _selected_choice)
		var txt := str(_current_choices[i])
		lbl.text = ("► " + txt) if is_sel else ("  " + txt)
		if is_sel:
			box.add_theme_stylebox_override("panel", HuwagUiTheme.make_box_style(pal["choice_sel_bg"], pal["choice_sel_border"], 1, 6, 3))
			lbl.add_theme_color_override("font_color", pal["accent"])
			lbl.add_theme_color_override("font_shadow_color", pal["text_shadow"])
		else:
			box.add_theme_stylebox_override("panel", HuwagUiTheme.make_box_style(pal["choice_bg"], pal["border"], 1, 6, 3))
			lbl.add_theme_color_override("font_color", pal["text_muted"])
			lbl.add_theme_color_override("font_shadow_color", pal["text_shadow"])


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
				"choice_index": chosen,
				"speaker": str(current_page.get("speaker", "")),
				"page_index": _page_index - 1
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
	active = false
	_is_corrupted_theme = false
	if choices_panel:
		choices_panel.visible = false
	hide()
	if has_node("/root/GameState"):
		get_node("/root/GameState").dialogue_active = false


func _apply_theme(mode: String) -> void:
	_theme_mode = mode
	var pal := HuwagUiTheme.get_palette(mode)

	if frame_panel:
		frame_panel.add_theme_stylebox_override("panel", HuwagUiTheme.make_box_style(pal["bg"], pal["border"], 1))
	if portrait_frame:
		var p_border: Color = Color("#591320") if mode == "distorted" else pal["border"]
		portrait_frame.add_theme_stylebox_override("panel", HuwagUiTheme.make_box_style(pal["bg_inner"], p_border, 1, 1, 1))
	if choices_panel:
		choices_panel.add_theme_stylebox_override("panel", HuwagUiTheme.make_box_style(pal["bg"], pal["border"], 1, 0, 0))
	if top_trim:
		top_trim.color = pal["trim"]
	if vhs_scuff_left:
		vhs_scuff_left.color = pal["trim_dark"]
	if vhs_scuff_right:
		vhs_scuff_right.color = pal["trim_dark"]
	if dialogue_label:
		dialogue_label.add_theme_color_override("font_color", pal["text"])
		dialogue_label.add_theme_color_override("font_shadow_color", pal["text_shadow"])
	if speaker_label:
		speaker_label.add_theme_color_override("font_shadow_color", pal["text_shadow"])
	if continue_hint:
		continue_hint.texture = HuwagUiTheme.build_down_arrow_texture(pal["cursor"], pal["border"])
	if not _choice_boxes.is_empty():
		_refresh_choices_visual()


func _play_ui_sfx(sfx_name: String) -> void:
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").play_sfx(sfx_name)
