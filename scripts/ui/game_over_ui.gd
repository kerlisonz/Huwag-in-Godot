class_name GameOverUI
extends CanvasLayer

## Tela de Derrota (Game Over UI) em estilo 16-bit / VHS Dark Horror.
## Opera em layer = 110 com PROCESS_MODE_ALWAYS para permanecer acima de HUD,
## copas de árvores e shaders mesmo com get_tree().paused = true.

signal retry_checkpoint_requested
signal main_menu_requested

const FADE_IN_DURATION: float = 0.35
const CURSOR_ACTIVE: String = "►  "
const CURSOR_IDLE: String = "   "
const LABEL_RETRY: String = "Reiniciar do Último Ponto"
const LABEL_MENU: String = "Voltar para o Menu"

@onready var root_control: Control = $Root
@onready var backdrop: ColorRect = $Root/Backdrop
@onready var card: PanelContainer = $Root/Center/Card
@onready var top_tag: Label = $Root/Center/Card/Margin/VBox/TopTag
@onready var title_label: Label = $Root/Center/Card/Margin/VBox/TitleLabel
@onready var rule: ColorRect = $Root/Center/Card/Margin/VBox/Rule
@onready var subtitle_label: Label = $Root/Center/Card/Margin/VBox/SubtitleLabel
@onready var btn_retry: Button = $Root/Center/Card/Margin/VBox/ButtonsBox/BtnRetryCheckpoint
@onready var btn_menu: Button = $Root/Center/Card/Margin/VBox/ButtonsBox/BtnMainMenu
@onready var hint_label: Label = $Root/Center/Card/Margin/VBox/HintLabel

var _is_open: bool = false
var _action_locked: bool = false
var _fade_tween: Tween = null
var _focused_index: int = 0
var _buttons: Array[Button] = []
var _base_labels: Array[String] = [LABEL_RETRY, LABEL_MENU]


func _ready() -> void:
	layer = 110
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_buttons = [btn_retry, btn_menu]

	if btn_retry != null and btn_menu != null:
		btn_retry.focus_mode = Control.FOCUS_ALL
		btn_menu.focus_mode = Control.FOCUS_ALL
		btn_retry.mouse_filter = Control.MOUSE_FILTER_STOP
		btn_menu.mouse_filter = Control.MOUSE_FILTER_STOP

		btn_retry.focus_neighbor_top = btn_retry.get_path_to(btn_menu)
		btn_retry.focus_neighbor_bottom = btn_retry.get_path_to(btn_menu)
		btn_menu.focus_neighbor_top = btn_menu.get_path_to(btn_retry)
		btn_menu.focus_neighbor_bottom = btn_menu.get_path_to(btn_retry)

		btn_retry.pressed.connect(_activate_retry)
		btn_menu.pressed.connect(_activate_main_menu)
		btn_retry.focus_entered.connect(_on_button_focused.bind(0))
		btn_menu.focus_entered.connect(_on_button_focused.bind(1))
		btn_retry.mouse_entered.connect(_on_button_mouse_entered.bind(0))
		btn_menu.mouse_entered.connect(_on_button_mouse_entered.bind(1))

	_apply_theme("normal")
	_refresh_button_labels()


func is_open() -> bool:
	return _is_open and visible


func show_defeat(ui_mode: String = "normal") -> void:
	if _is_open and visible:
		return
	_is_open = true
	_action_locked = false
	_focused_index = 0
	_apply_theme(ui_mode)
	_refresh_button_labels()

	visible = true
	if root_control != null:
		root_control.modulate.a = 0.0
	if _fade_tween != null and is_instance_valid(_fade_tween):
		_fade_tween.kill()
	_fade_tween = create_tween()
	_fade_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_fade_tween.set_trans(Tween.TRANS_CUBIC)
	_fade_tween.set_ease(Tween.EASE_OUT)
	if root_control != null:
		_fade_tween.tween_property(root_control, "modulate:a", 1.0, FADE_IN_DURATION)

	_focus_default_button()
	call_deferred("_focus_default_button")


func hide_defeat() -> void:
	if _fade_tween != null and is_instance_valid(_fade_tween):
		_fade_tween.kill()
	_fade_tween = null
	_is_open = false
	_action_locked = false
	visible = false
	if root_control != null:
		root_control.modulate.a = 1.0


func _focus_default_button() -> void:
	if not _is_open or btn_retry == null or not is_instance_valid(btn_retry):
		return
	_focused_index = 0
	btn_retry.grab_focus()
	_refresh_button_labels()


func _mark_input_handled() -> void:
	var vp := get_viewport()
	if vp != null:
		vp.set_input_as_handled()


func _input(event: InputEvent) -> void:
	if not _is_open or not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var kc: Key = event.keycode
		if _action_locked:
			_mark_input_handled()
			return
		if kc == KEY_W or kc == KEY_UP:
			_mark_input_handled()
			_move_selection(-1)
		elif kc == KEY_S or kc == KEY_DOWN:
			_mark_input_handled()
			_move_selection(1)
		elif kc == KEY_ENTER or kc == KEY_KP_ENTER or kc == KEY_SPACE:
			_mark_input_handled()
			if _focused_index == 0:
				_activate_retry()
			else:
				_activate_main_menu()
		elif kc in [KEY_ESCAPE, KEY_F1, KEY_TAB, KEY_F5, KEY_F9, KEY_F10]:
			_mark_input_handled()


func _move_selection(delta: int) -> void:
	if _buttons.is_empty():
		return
	_focused_index = posmod(_focused_index + delta, _buttons.size())
	var target := _buttons[_focused_index]
	if target != null and is_instance_valid(target):
		target.grab_focus()
	_refresh_button_labels()
	_play_sfx("ui_move")


func _on_button_focused(idx: int) -> void:
	_focused_index = idx
	_refresh_button_labels()


func _on_button_mouse_entered(idx: int) -> void:
	if not _is_open or _action_locked:
		return
	if idx >= 0 and idx < _buttons.size():
		if _focused_index != idx:
			_play_sfx("ui_move")
		_focused_index = idx
		_buttons[idx].grab_focus()
		_refresh_button_labels()


func _refresh_button_labels() -> void:
	for i in range(_buttons.size()):
		var btn := _buttons[i]
		if btn == null:
			continue
		var prefix := CURSOR_ACTIVE if i == _focused_index else CURSOR_IDLE
		btn.text = prefix + _base_labels[i]


func _activate_retry() -> void:
	if not _is_open or _action_locked:
		return
	_action_locked = true
	_play_sfx("ui_select")
	retry_checkpoint_requested.emit()


func _activate_main_menu() -> void:
	if not _is_open or _action_locked:
		return
	_action_locked = true
	_play_sfx("ui_select")
	main_menu_requested.emit()


func _play_sfx(sfx_name: String) -> void:
	if has_node("/root/AudioManager"):
		var am := get_node("/root/AudioManager")
		if am.has_method("play_sfx"):
			am.call("play_sfx", sfx_name)


func _apply_theme(ui_mode: String) -> void:
	var pal: Dictionary = HuwagUiTheme.get_palette(ui_mode)
	var is_act3 := (ui_mode == "act3")
	var is_dist := (ui_mode == "distorted")
	var title_col := Color("#E2DCFF", 1.0) if is_dist else (Color("#E4E8F0", 1.0) if is_act3 else Color("#FFFFFF", 1.0))
	var border_col: Color = pal["border"]
	var card_bg: Color = pal["bg"]
	var btn_idle_bg: Color = pal["choice_bg"]
	var btn_idle_border := Color(border_col.r, border_col.g, border_col.b, 0.45)
	var btn_focus_bg: Color = pal["choice_sel_bg"]
	var btn_focus_border: Color = pal["choice_sel_border"]

	if backdrop != null:
		backdrop.color = Color(0.02, 0.02, 0.04, 0.86)

	if card != null:
		card.add_theme_stylebox_override("panel", HuwagUiTheme.make_omori_box_style(card_bg, border_col, 14, 12, 3))
	if top_tag != null:
		top_tag.add_theme_color_override("font_color", pal["text_muted"])
		top_tag.add_theme_color_override("font_shadow_color", pal["text_shadow"])
	if title_label != null:
		title_label.add_theme_color_override("font_color", title_col)
		title_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	if rule != null:
		rule.color = Color(border_col.r, border_col.g, border_col.b, 0.5)
	if subtitle_label != null:
		subtitle_label.add_theme_color_override("font_color", pal["text"])
		subtitle_label.add_theme_color_override("font_shadow_color", pal["text_shadow"])
	if hint_label != null:
		hint_label.add_theme_color_override("font_color", pal["text_muted"])
		hint_label.add_theme_color_override("font_shadow_color", pal["text_shadow"])

	var sb_normal := HuwagUiTheme.make_omori_box_style(btn_idle_bg, btn_idle_border, 10, 6)
	var sb_focus := HuwagUiTheme.make_omori_box_style(btn_focus_bg, btn_focus_border, 10, 6)
	var sb_pressed := HuwagUiTheme.make_omori_box_style(Color("#2A2838", 0.98) if is_dist else Color("#24262E", 0.98), border_col, 10, 6)
	for btn in _buttons:
		if btn == null:
			continue
		btn.add_theme_stylebox_override("normal", sb_normal)
		btn.add_theme_stylebox_override("hover", sb_focus)
		btn.add_theme_stylebox_override("focus", sb_focus)
		btn.add_theme_stylebox_override("pressed", sb_pressed)
		btn.add_theme_color_override("font_color", pal["text_muted"])
		btn.add_theme_color_override("font_hover_color", Color.WHITE)
		btn.add_theme_color_override("font_focus_color", Color.WHITE)
		btn.add_theme_color_override("font_pressed_color", pal["accent"])
