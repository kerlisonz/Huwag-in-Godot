extends Node2D

@onready var level_container: Node2D = $LevelContainer
@onready var perception_rect: ColorRect = $PerceptionLayer/PerceptionRect
@onready var hud_top_left: PanelContainer = $CanvasLayer/HudTopLeft
@onready var badge_icon: ColorRect = $CanvasLayer/HudTopLeft/Margin/HBox/BadgeIcon
@onready var hp_title: Label = $CanvasLayer/HudTopLeft/Margin/HBox/HpTitle
@onready var hp_bar: ProgressBar = $CanvasLayer/HudTopLeft/Margin/HBox/HpBar
@onready var hp_value: Label = $CanvasLayer/HudTopLeft/Margin/HBox/HpValue
@onready var skills_label: Label = $CanvasLayer/HudTopLeft/Margin/HBox/SkillsLabel
@onready var hud_top_right: PanelContainer = $CanvasLayer/HudTopRight
@onready var act_place_label: Label = $CanvasLayer/HudTopRight/Margin/HBox/ActPlaceLabel
@onready var help_hint: Label = $CanvasLayer/HudTopRight/Margin/HBox/HelpHint
@onready var status_label: Label = $CanvasLayer/StatusLabel
@onready var dialogue_box: DialogueBox = $CanvasLayer/DialogueBox
@onready var controls_modal: Control = $CanvasLayer/ControlsModal
@onready var controls_card: PanelContainer = $CanvasLayer/ControlsModal/Card

var _current_level: Node2D = null
var _pending_dialogue_callback: Callable = Callable()
var _current_scene_path: String = "res://scenes/levels/RoomHuwag.tscn"
var _toast_timer: float = 0.0

func _ready() -> void:
	GameState.perception_changed.connect(_on_perception_changed)
	GameState.switch_changed.connect(func(_k: String, _v: bool) -> void: _update_hud())
	GameState.variable_changed.connect(func(_k: String, _v: Variant) -> void: _update_hud())
	GameState.hp_changed.connect(func(_c: int, _m: int) -> void: _update_hud())
	GameState.notification_requested.connect(_on_notification_requested)
	dialogue_box.dialogue_finished.connect(_on_dialogue_finished)
	if dialogue_box.has_signal("conflict_triggered"):
		dialogue_box.conflict_triggered.connect(_on_dialogue_conflict_triggered)

	_apply_hud_style(GameState.perception_mode)
	_apply_shader_mode(GameState.perception_mode)
	load_level("res://scenes/levels/RoomHuwag.tscn", "initial")

func _process(delta: float) -> void:
	if _toast_timer > 0.0:
		_toast_timer -= delta
		if _toast_timer <= 0.0 and status_label:
			status_label.text = ""

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F1 or event.keycode == KEY_ESCAPE:
			_toggle_controls_modal()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_TAB:
			GameState.cycle_perception_preview()
			if _current_level:
				_current_level.queue_redraw()
		elif event.keycode == KEY_F5:
			if GameState.save_game():
				_on_notification_requested("Progresso salvo")
		elif event.keycode == KEY_F9:
			if GameState.load_game():
				load_level(_current_scene_path, GameState.spawn_tag)
				_on_notification_requested("Estado carregado")

func _toggle_controls_modal() -> void:
	if controls_modal == null:
		return
	var next_vis := not controls_modal.visible
	controls_modal.visible = next_vis
	if next_vis:
		GameState.dialogue_active = true
	else:
		GameState.dialogue_active = dialogue_box.is_open()

func load_level(scene_path: String, spawn_tag: String = "default") -> void:
	GameState.spawn_tag = spawn_tag
	_current_scene_path = scene_path
	if _current_level != null and is_instance_valid(_current_level):
		_current_level.queue_free()
		_current_level = null

	var packed: PackedScene = load(scene_path)
	if packed == null:
		push_error("Falha ao carregar cena: %s" % scene_path)
		return
	var instance := packed.instantiate() as Node2D
	_current_level = instance
	level_container.add_child(instance)

	if instance.has_signal("request_level_change"):
		instance.connect("request_level_change", _on_request_level_change)
	if instance.has_signal("request_dialogue"):
		instance.connect("request_dialogue", _on_request_dialogue)

	_update_hud()

func _on_request_level_change(target_scene: String, spawn_tag: String) -> void:
	call_deferred("load_level", target_scene, spawn_tag)

func _on_request_dialogue(pages: Array, callback: Callable) -> void:
	_pending_dialogue_callback = callback
	dialogue_box.start_dialogue(pages)
	_update_hud_visibility()

func _on_dialogue_finished(choice_index: int) -> void:
	var cb := _pending_dialogue_callback
	_pending_dialogue_callback = Callable()
	if cb.is_valid():
		cb.call(choice_index)
	_update_hud()

func _on_dialogue_conflict_triggered(target_id: String, context: Dictionary) -> void:
	if _current_level != null and is_instance_valid(_current_level):
		if _current_level.has_method("_on_dialogue_conflict_triggered"):
			_current_level.call("_on_dialogue_conflict_triggered", target_id, context)

func _on_perception_changed(mode: int) -> void:
	_apply_shader_mode(mode)
	_apply_hud_style(mode)
	_update_hud()

func _apply_shader_mode(mode: int) -> void:
	if perception_rect == null or perception_rect.material == null:
		return
	var mat := perception_rect.material as ShaderMaterial
	if mat == null:
		return
	match mode:
		GameState.PerceptionMode.FILTERED_MORNING:
			mat.set_shader_parameter("afternoon_mix", 0.0)
			mat.set_shader_parameter("unfiltered_mix", 0.0)
		GameState.PerceptionMode.FILTERED_AFTERNOON:
			mat.set_shader_parameter("afternoon_mix", 1.0)
			mat.set_shader_parameter("unfiltered_mix", 0.0)
		GameState.PerceptionMode.UNFILTERED_ACT3:
			mat.set_shader_parameter("afternoon_mix", 0.0)
			mat.set_shader_parameter("unfiltered_mix", 1.0)

func _apply_hud_style(mode: int) -> void:
	var act3 := (mode == GameState.PerceptionMode.UNFILTERED_ACT3)
	var accent := Color("#7C858E") if act3 else Color("#F5CB5C")
	var bg := Color(0.08, 0.09, 0.11, 0.86) if act3 else Color(0.07, 0.08, 0.11, 0.86)
	var border_light := Color(0.76, 0.79, 0.84, 0.55)

	var left_sb := StyleBoxFlat.new()
	left_sb.corner_detail = 1
	left_sb.corner_radius_top_left = 0
	left_sb.corner_radius_bottom_left = 0
	left_sb.corner_radius_top_right = 4
	left_sb.corner_radius_bottom_right = 6
	left_sb.border_width_left = 3
	left_sb.border_width_top = 1
	left_sb.border_width_right = 1
	left_sb.border_width_bottom = 1
	left_sb.bg_color = bg
	left_sb.border_color = border_light
	left_sb.shadow_color = Color(0.0, 0.0, 0.0, 0.65)
	left_sb.shadow_size = 2
	if hud_top_left:
		hud_top_left.add_theme_stylebox_override("panel", left_sb)

	var right_sb := StyleBoxFlat.new()
	right_sb.corner_detail = 1
	right_sb.corner_radius_top_left = 4
	right_sb.corner_radius_bottom_left = 6
	right_sb.corner_radius_top_right = 0
	right_sb.corner_radius_bottom_right = 0
	right_sb.border_width_left = 1
	right_sb.border_width_top = 1
	right_sb.border_width_right = 3
	right_sb.border_width_bottom = 1
	right_sb.bg_color = bg
	right_sb.border_color = border_light
	right_sb.shadow_color = Color(0.0, 0.0, 0.0, 0.65)
	right_sb.shadow_size = 2
	if hud_top_right:
		hud_top_right.add_theme_stylebox_override("panel", right_sb)

	if controls_card:
		var modal_sb := StyleBoxFlat.new()
		modal_sb.corner_detail = 1
		modal_sb.set_corner_radius_all(6)
		modal_sb.set_border_width_all(1)
		modal_sb.bg_color = Color(0.07, 0.08, 0.11, 0.94) if not act3 else Color(0.09, 0.10, 0.12, 0.94)
		modal_sb.border_color = border_light
		modal_sb.shadow_color = Color(0.0, 0.0, 0.0, 0.78)
		modal_sb.shadow_size = 4
		controls_card.add_theme_stylebox_override("panel", modal_sb)

	if hp_bar:
		var bar_bg := StyleBoxFlat.new()
		bar_bg.set_corner_radius_all(2)
		bar_bg.bg_color = Color(0.16, 0.15, 0.24, 1.0) if not act3 else Color(0.18, 0.19, 0.21, 1.0)
		var bar_fill := StyleBoxFlat.new()
		bar_fill.set_corner_radius_all(2)
		bar_fill.bg_color = Color("#E85D56") if not act3 else Color("#8A7968")
		hp_bar.add_theme_stylebox_override("background", bar_bg)
		hp_bar.add_theme_stylebox_override("fill", bar_fill)

	if badge_icon:
		badge_icon.color = accent
	if hp_title:
		hp_title.add_theme_color_override("font_color", accent)
	if help_hint:
		help_hint.add_theme_color_override("font_color", accent)

func _on_notification_requested(text: String) -> void:
	if status_label:
		status_label.text = text
		_toast_timer = 3.5

func _update_hud_visibility() -> void:
	var hide_hud := (dialogue_box != null and dialogue_box.is_open())
	if hud_top_left:
		hud_top_left.modulate.a = 0.65 if hide_hud else 1.0
	if hud_top_right:
		hud_top_right.modulate.a = 0.65 if hide_hud else 1.0

func _update_hud() -> void:
	_update_hud_visibility()
	if hp_bar:
		hp_bar.max_value = float(maxi(1, GameState.player_max_hp))
		hp_bar.value = float(clampi(GameState.player_hp, 0, GameState.player_max_hp))
	if hp_value:
		hp_value.text = "%d/%d" % [GameState.player_hp, GameState.player_max_hp]

	if skills_label:
		var tags: PackedStringArray = []
		if GameState.get_switch("016_Magia_de_agua_obtida"):
			tags.append("Água")
		var heal_count: int = GameState.get_item_count("gota_calmante")
		if heal_count > 0:
			tags.append("Cura×%d" % heal_count)
		skills_label.visible = not tags.is_empty()
		skills_label.text = "· " + " · ".join(tags)

	if act_place_label:
		var place_name := "Quarto de Huwag"
		if _current_scene_path.ends_with("StreetPreview.tscn"):
			place_name = "Rua de Agdangan"
		elif _current_scene_path.ends_with("FireStation.tscn"):
			place_name = "Quartel dos Bombeiros"
		elif _current_scene_path.ends_with("ForestCorridor.tscn"):
			place_name = "Trilha da Floresta"
		elif _current_scene_path.ends_with("ForestClearing.tscn"):
			place_name = "Clareira da Lagoa"

		var ato: int = int(GameState.get_var("Ato", 1))
		var roman := "I"
		if ato == 2:
			roman = "II"
		elif ato >= 3 or GameState.is_unfiltered_act3():
			roman = "III"
		act_place_label.text = "Ato %s · %s" % [roman, place_name]
