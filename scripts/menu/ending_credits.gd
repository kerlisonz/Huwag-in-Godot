extends Control

## Tela de Encerramento da Demo — Huwag (Estilo VHS / 16-bit)
## Exibe "FIM DA DEMO — Obrigado por jogar Huwag", resumo da rota concluída e botão para voltar ao Menu Principal.

@onready var title_label: Label = get_node_or_null("CenterContainer/DemoCard/Margin/VBox/TitleLabel") as Label
@onready var subtitle_label: Label = get_node_or_null("CenterContainer/DemoCard/Margin/VBox/SubtitleLabel") as Label
@onready var route_title_label: Label = get_node_or_null("CenterContainer/DemoCard/Margin/VBox/RouteTitleLabel") as Label
@onready var route_summary_label: Label = get_node_or_null("CenterContainer/DemoCard/Margin/VBox/RouteSummaryLabel") as Label
@onready var btn_main_menu: Button = get_node_or_null("CenterContainer/DemoCard/Margin/VBox/BtnMainMenu") as Button
@onready var demo_card: PanelContainer = get_node_or_null("CenterContainer/DemoCard") as PanelContainer

var _returning: bool = false


func _ready() -> void:
	get_tree().paused = false
	if GameState.has_method("clear_transient_state"):
		GameState.clear_transient_state()

	if has_node("/root/AudioManager"):
		var am = get_node("/root/AudioManager")
		am.play_bgm("vhs_memory_bgm", 2.0)
		am.play_ambience("morning_ambience", 2.0)

	_apply_route_summary()
	_style_button()

	if btn_main_menu != null:
		btn_main_menu.pressed.connect(_return_to_title)
		btn_main_menu.grab_focus()


func _apply_route_summary() -> void:
	var summary := {
		"route_id": "normal",
		"route_title": "ROTA CONCLUÍDA: PERCEPÇÃO ESTÁVEL",
		"summary": "Você manteve a dose habitual, atendeu os moradores de Agdangan com firmeza\ne atravessou a fita VHS de olhos abertos diante do que aconteceu."
	}
	if GameState.has_method("get_demo_route_summary"):
		summary = GameState.get_demo_route_summary()

	if route_title_label != null:
		route_title_label.text = str(summary.get("route_title", ""))
		var rid := str(summary.get("route_id", "normal"))
		if rid == "corrupted":
			route_title_label.add_theme_color_override("font_color", Color(0.84, 0.78, 0.98, 1.0))
		elif rid == "reverted":
			route_title_label.add_theme_color_override("font_color", Color(0.72, 0.90, 0.86, 1.0))
		else:
			route_title_label.add_theme_color_override("font_color", Color(0.96, 0.96, 0.98, 1.0))
	if route_summary_label != null:
		route_summary_label.text = str(summary.get("summary", ""))


func _style_button() -> void:
	if btn_main_menu == null:
		return
	var pal: Dictionary = HuwagUiTheme.get_palette("normal")
	var sb_norm := HuwagUiTheme.make_omori_box_style(pal["choice_bg"], pal["border"], 14, 6)
	var sb_focus := HuwagUiTheme.make_omori_box_style(pal["choice_sel_bg"], pal["border"], 14, 6)
	btn_main_menu.add_theme_stylebox_override("normal", sb_norm)
	btn_main_menu.add_theme_stylebox_override("hover", sb_focus)
	btn_main_menu.add_theme_stylebox_override("pressed", sb_focus)
	btn_main_menu.add_theme_stylebox_override("focus", sb_focus)
	btn_main_menu.add_theme_color_override("font_color", Color(0.92, 0.94, 0.96, 1.0))
	btn_main_menu.add_theme_color_override("font_hover_color", Color(1.0, 0.94, 0.68, 1.0))
	btn_main_menu.add_theme_color_override("font_focus_color", Color(1.0, 0.94, 0.68, 1.0))


func _unhandled_input(event: InputEvent) -> void:
	if _returning:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE, KEY_ESCAPE]:
			var vp := get_viewport()
			if vp != null:
				vp.set_input_as_handled()
			_return_to_title()


func _return_to_title() -> void:
	if _returning:
		return
	_returning = true
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").play_sfx("ui_select")
	if GameState.has_method("clear_transient_state"):
		GameState.clear_transient_state()
	get_tree().paused = false
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.35)
	tw.tween_callback(func() -> void:
		if is_inside_tree():
			get_tree().change_scene_to_file("res://scenes/menu/TitleScreen.tscn")
	)
