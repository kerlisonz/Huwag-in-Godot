extends Node2D

@onready var level_container: Node2D = $LevelContainer
@onready var perception_rect: ColorRect = $PerceptionLayer/PerceptionRect
@onready var hud_top_left: PanelContainer = $CanvasLayer/HudTopLeft
@onready var heart_1: TextureRect = $CanvasLayer/HudTopLeft/Margin/VBox/TopRow/HeartsRow/Heart1
@onready var heart_2: TextureRect = $CanvasLayer/HudTopLeft/Margin/VBox/TopRow/HeartsRow/Heart2
@onready var heart_3: TextureRect = $CanvasLayer/HudTopLeft/Margin/VBox/TopRow/HeartsRow/Heart3
@onready var skills_label: Label = $CanvasLayer/HudTopLeft/Margin/VBox/TopRow/SkillsLabel
@onready var stamina_bar: Control = $CanvasLayer/HudTopLeft/Margin/VBox/StaminaBar
@onready var stamina_bg: Panel = $CanvasLayer/HudTopLeft/Margin/VBox/StaminaBar/StaminaBg
@onready var stamina_fill: ColorRect = $CanvasLayer/HudTopLeft/Margin/VBox/StaminaBar/StaminaFill
@onready var hud_top_right: PanelContainer = $CanvasLayer/HudTopRight
@onready var act_place_label: Label = $CanvasLayer/HudTopRight/Margin/HBox/ActPlaceLabel
@onready var help_hint: Label = $CanvasLayer/HudTopRight/Margin/HBox/HelpHint
@onready var status_label: Label = $CanvasLayer/StatusLabel
@onready var dialogue_box: DialogueBox = $CanvasLayer/DialogueBox
@onready var controls_modal: Control = $CanvasLayer/ControlsModal
@onready var controls_card: PanelContainer = $CanvasLayer/ControlsModal/Card
@onready var controls_title: Label = $CanvasLayer/ControlsModal/Card/Margin/VBox/Title
@onready var controls_rule: ColorRect = $CanvasLayer/ControlsModal/Card/Margin/VBox/Rule
@onready var controls_grid: GridContainer = $CanvasLayer/ControlsModal/Card/Margin/VBox/Grid
@onready var controls_footer: Label = $CanvasLayer/ControlsModal/Card/Margin/VBox/Footer
@onready var outfit_button: Button = get_node_or_null("CanvasLayer/ControlsModal/Card/Margin/VBox/OutfitButton") as Button

var _current_level: Node2D = null
var _pending_dialogue_callback: Callable = Callable()
var _current_scene_path: String = "res://scenes/levels/RoomHuwag.tscn"
var _toast_timer: float = 0.0
var _heart_textures: Dictionary = {}
var _heart_pulse_time: float = 0.0
var _hp_segments: int = 6
var _ui_mode: String = "normal"

func _ready() -> void:
	_heart_textures = HuwagUiTheme.build_heart_textures()
	for h in _get_heart_nodes():
		h.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if status_label:
		status_label.visible = false

	GameState.perception_changed.connect(_on_perception_changed)
	GameState.switch_changed.connect(func(_k: String, _v: bool) -> void: _update_hud())
	GameState.variable_changed.connect(func(_k: String, _v: Variant) -> void: _update_hud())
	GameState.hp_changed.connect(func(_c: int, _m: int) -> void: _update_hud())
	if GameState.has_signal("stamina_changed"):
		GameState.stamina_changed.connect(func(_c: float, _m: float) -> void: _update_stamina_hud())
	GameState.outfit_changed.connect(func(_o: String) -> void: _refresh_outfit_button())
	GameState.notification_requested.connect(_on_notification_requested)
	dialogue_box.dialogue_finished.connect(_on_dialogue_finished)
	if outfit_button:
		outfit_button.pressed.connect(func() -> void: GameState.toggle_outfit())
		_refresh_outfit_button()
	if GameState.has_signal("higher_dose_changed"):
		GameState.higher_dose_changed.connect(_on_higher_dose_changed)
	if dialogue_box.has_signal("conflict_triggered"):
		dialogue_box.conflict_triggered.connect(_on_dialogue_conflict_triggered)

	_apply_hud_style(GameState.perception_mode)
	_apply_shader_mode(GameState.perception_mode)
	load_level("res://scenes/levels/RoomHuwag.tscn", "initial")

func _process(delta: float) -> void:
	if status_label:
		if _toast_timer > 0.0:
			_toast_timer -= delta
			if _toast_timer <= 0.0:
				status_label.text = ""
				status_label.visible = false
		elif status_label.visible and status_label.text.is_empty():
			status_label.visible = false

	if _hp_segments > 0 and _hp_segments <= 2:
		_heart_pulse_time += delta * 7.5
		var pulse := 0.5 + 0.5 * sin(_heart_pulse_time)
		if heart_1:
			heart_1.modulate = Color(1.0, 0.55 + 0.45 * pulse, 0.55 + 0.45 * pulse, 1.0)
			heart_1.position.y = -1.0 if sin(_heart_pulse_time * 1.5) > 0.35 else 0.0
	else:
		_heart_pulse_time = 0.0
		if heart_1:
			heart_1.modulate = Color.WHITE
			heart_1.position.y = 0.0

	if perception_rect == null or perception_rect.material == null:
		return
	var mat := perception_rect.material as ShaderMaterial
	if mat == null:
		return
	var higher_dose: bool = GameState.has_method("is_higher_dose") and GameState.is_higher_dose()
	if higher_dose:
		_dose_pulse_cooldown -= delta
		if _dose_pulse_cooldown <= 0.0:
			_dose_pulse_cooldown = randf_range(5.5, 10.5)
			trigger_vhs_glitch(randf_range(0.16, 0.32), randf_range(0.45, 0.85))
	if _glitch_timer > 0.0:
		_glitch_timer = maxf(0.0, _glitch_timer - delta)
		var pulse := (_glitch_timer / maxf(0.01, _glitch_duration)) * _glitch_strength
		mat.set_shader_parameter("vhs_tracking_jitter", 0.006 * pulse)
		mat.set_shader_parameter("vhs_tear", 0.14 * pulse)
		mat.set_shader_parameter("vhs_dropout", 0.12 * pulse)
		mat.set_shader_parameter("vhs_head_switch", 0.18 * pulse)
		mat.set_shader_parameter("vhs_chromatic_aberration", 0.002 + 0.005 * pulse)
		if _glitch_timer <= 0.0:
			_glitch_strength = 0.0
			_apply_shader_mode(GameState.perception_mode)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F1 or event.keycode == KEY_ESCAPE:
			_toggle_controls_modal()
			get_viewport().set_input_as_handled()
		elif controls_modal and controls_modal.visible and event.keycode == KEY_M:
			get_tree().change_scene_to_file("res://scenes/menu/TitleScreen.tscn")
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
		elif event.keycode == KEY_F10:
			GameState.advance_act()
			load_level(_current_scene_path, GameState.spawn_tag)
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_F11 or (event.keycode == KEY_ENTER and event.alt_pressed):
			GameState.toggle_fullscreen()
			get_viewport().set_input_as_handled()

func _toggle_controls_modal() -> void:
	if controls_modal == null:
		return
	var next_vis := not controls_modal.visible
	controls_modal.visible = next_vis
	if next_vis:
		_refresh_outfit_button()
		GameState.dialogue_active = true
	else:
		GameState.dialogue_active = dialogue_box.is_open()

func _refresh_outfit_button() -> void:
	if outfit_button == null:
		return
	outfit_button.text = "Trocar Traje (Atual: %s)" % GameState.get_equipped_outfit_label()

func load_level(scene_path: String, spawn_tag: String = "default") -> void:
	if scene_path.find("EndingCredits") != -1:
		get_tree().change_scene_to_file("res://scenes/menu/EndingCredits.tscn")
		return

	if dialogue_box != null and is_instance_valid(dialogue_box):
		dialogue_box.close_dialogue()
	GameState.spawn_tag = spawn_tag
	_current_scene_path = scene_path
	GameState.current_scene_path = scene_path
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

var _glitch_timer: float = 0.0
var _glitch_duration: float = 0.0
var _glitch_strength: float = 0.0
var _dose_pulse_cooldown: float = 5.0


func trigger_vhs_glitch(duration: float = 0.35, strength: float = 1.0) -> void:
	_glitch_duration = maxf(_glitch_duration, duration)
	_glitch_timer = _glitch_duration
	_glitch_strength = maxf(_glitch_strength, strength)


func _on_higher_dose_changed(active: bool) -> void:
	_apply_shader_mode(GameState.perception_mode)
	_apply_hud_style(GameState.perception_mode)
	_update_hud()
	if _current_level != null and is_instance_valid(_current_level) and _current_level.has_method("apply_higher_dose_world"):
		_current_level.call("apply_higher_dose_world", active)
	if active:
		trigger_vhs_glitch(0.65, 1.2)
		if AudioManager.has_method("play_sfx"):
			AudioManager.play_sfx("vhs_glitch")


func _apply_shader_mode(mode: int) -> void:
	if perception_rect == null or perception_rect.material == null:
		return
	var mat := perception_rect.material as ShaderMaterial
	if mat == null:
		return
	var higher_dose: bool = GameState.has_method("is_higher_dose") and GameState.is_higher_dose()
	var is_vhs_scene := _current_scene_path.ends_with("vhs_memory_minigame.tscn")
	match mode:
		GameState.PerceptionMode.FILTERED_MORNING:
			mat.set_shader_parameter("afternoon_mix", 0.0)
			mat.set_shader_parameter("night_mix", 0.18 if higher_dose else 0.0)
			mat.set_shader_parameter("unfiltered_mix", 0.0)
		GameState.PerceptionMode.FILTERED_AFTERNOON:
			mat.set_shader_parameter("afternoon_mix", 0.55 if not higher_dose else 0.25)
			mat.set_shader_parameter("night_mix", 0.35 if higher_dose else 0.08)
			mat.set_shader_parameter("unfiltered_mix", 0.0)
		GameState.PerceptionMode.UNFILTERED_ACT3:
			mat.set_shader_parameter("afternoon_mix", 0.0)
			mat.set_shader_parameter("night_mix", 0.0)
			mat.set_shader_parameter("unfiltered_mix", 1.0)
	if is_vhs_scene:
		mat.set_shader_parameter("vhs_scanline_alpha", 0.14)
		mat.set_shader_parameter("vhs_noise_intensity", 0.07)
		mat.set_shader_parameter("vhs_chromatic_aberration", 0.0035)
		mat.set_shader_parameter("vhs_tracking_jitter", 0.0025)
		mat.set_shader_parameter("vhs_tracking_band", 0.22)
		mat.set_shader_parameter("vhs_head_switch", 0.12)
		mat.set_shader_parameter("vhs_dropout", 0.05)
		mat.set_shader_parameter("vhs_tear", 0.06)
		mat.set_shader_parameter("vhs_crt_vignette", 0.42)
	elif higher_dose:
		# Ato 2 dose maior: interferência analógica sutil contínua + bursts estratégicos
		mat.set_shader_parameter("vhs_scanline_alpha", 0.085)
		mat.set_shader_parameter("vhs_noise_intensity", 0.032)
		mat.set_shader_parameter("vhs_chromatic_aberration", 0.002)
		mat.set_shader_parameter("vhs_tracking_jitter", 0.0)
		mat.set_shader_parameter("vhs_tracking_band", 0.09)
		mat.set_shader_parameter("vhs_head_switch", 0.04)
		mat.set_shader_parameter("vhs_dropout", 0.0)
		mat.set_shader_parameter("vhs_tear", 0.0)
		mat.set_shader_parameter("vhs_crt_vignette", 0.36)
	else:
		# Visual-base limpo estilo minigame retrô de arcade (sem VHS excessivo)
		mat.set_shader_parameter("vhs_scanline_alpha", 0.035)
		mat.set_shader_parameter("vhs_noise_intensity", 0.0)
		mat.set_shader_parameter("vhs_chromatic_aberration", 0.0)
		mat.set_shader_parameter("vhs_tracking_jitter", 0.0)
		mat.set_shader_parameter("vhs_tracking_band", 0.0)
		mat.set_shader_parameter("vhs_head_switch", 0.0)
		mat.set_shader_parameter("vhs_dropout", 0.0)
		mat.set_shader_parameter("vhs_tear", 0.0)
		mat.set_shader_parameter("vhs_crt_vignette", 0.38 if mode == GameState.PerceptionMode.UNFILTERED_ACT3 else 0.16)

func _get_heart_nodes() -> Array[TextureRect]:
	var arr: Array[TextureRect] = []
	for h in [heart_1, heart_2, heart_3]:
		if h != null:
			arr.append(h)
	return arr

func _resolve_hud_theme_mode(mode: int) -> String:
	if mode == GameState.PerceptionMode.UNFILTERED_ACT3:
		return "act3"
	var higher_dose: bool = GameState.has_method("is_higher_dose") and bool(GameState.is_higher_dose())
	if higher_dose:
		return "distorted"
	return "normal"

func _apply_hud_style(mode: int) -> void:
	_ui_mode = _resolve_hud_theme_mode(mode)
	var pal: Dictionary = HuwagUiTheme.get_palette(_ui_mode)

	var left_sb := HuwagUiTheme.make_box_style(pal["bg_soft"], pal["border"], 1)
	if hud_top_left:
		hud_top_left.add_theme_stylebox_override("panel", left_sb)

	var right_sb := HuwagUiTheme.make_box_style(pal["bg_soft"], pal["border"], 1)
	if hud_top_right:
		hud_top_right.add_theme_stylebox_override("panel", right_sb)

	if stamina_bg:
		stamina_bg.add_theme_stylebox_override("panel", HuwagUiTheme.make_box_style(pal["bg_inner"], pal["border"], 1))

	if status_label:
		var toast_sb := HuwagUiTheme.make_box_style(pal["bg"], pal["border"], 1, 7, 3)
		status_label.add_theme_stylebox_override("normal", toast_sb)
		status_label.add_theme_color_override("font_color", pal["accent"])
		status_label.add_theme_color_override("font_shadow_color", pal["text_shadow"])

	if controls_card:
		controls_card.add_theme_stylebox_override("panel", HuwagUiTheme.make_box_style(pal["bg"], pal["trim"], 1))
	if controls_title:
		controls_title.add_theme_color_override("font_color", pal["accent"])
		controls_title.add_theme_color_override("font_shadow_color", pal["text_shadow"])
	if controls_rule:
		controls_rule.color = pal["trim"]
	if controls_grid:
		for child in controls_grid.get_children():
			if child is Label:
				var lbl := child as Label
				if lbl.name.begins_with("K"):
					lbl.add_theme_color_override("font_color", pal["accent"])
				else:
					lbl.add_theme_color_override("font_color", pal["text"])
	if controls_footer:
		controls_footer.add_theme_color_override("font_color", pal["text_muted"])
	if outfit_button:
		var btn_norm := HuwagUiTheme.make_box_style(pal["choice_bg"], pal["trim"], 1, 8, 5)
		var btn_hov := HuwagUiTheme.make_box_style(pal["choice_sel_bg"], pal["choice_sel_border"], 1, 8, 5)
		outfit_button.add_theme_stylebox_override("normal", btn_norm)
		outfit_button.add_theme_stylebox_override("hover", btn_hov)
		outfit_button.add_theme_stylebox_override("pressed", btn_hov)
		outfit_button.add_theme_stylebox_override("focus", btn_hov)
		outfit_button.add_theme_color_override("font_color", pal["accent"])
		outfit_button.add_theme_color_override("font_hover_color", pal["text"])
		outfit_button.add_theme_color_override("font_focus_color", pal["text"])

	if act_place_label:
		act_place_label.add_theme_color_override("font_color", pal["text"])
		act_place_label.add_theme_color_override("font_shadow_color", pal["text_shadow"])
	if help_hint:
		help_hint.add_theme_color_override("font_color", pal["accent"])
		help_hint.add_theme_color_override("font_shadow_color", pal["text_shadow"])
	_update_stamina_hud()

func _on_notification_requested(text: String) -> void:
	if status_label:
		status_label.text = text
		status_label.visible = not text.is_empty()
		_toast_timer = 3.5 if status_label.visible else 0.0

func _update_hud_visibility() -> void:
	var hide_hud := (dialogue_box != null and dialogue_box.is_open())
	if hud_top_left:
		hud_top_left.modulate.a = 0.72 if hide_hud else 1.0
	if hud_top_right:
		hud_top_right.modulate.a = 0.72 if hide_hud else 1.0

func _update_stamina_hud() -> void:
	if stamina_fill == null:
		return
	var st_max: float = maxf(1.0, float(GameState.player_max_stamina))
	var st_cur: float = clampf(float(GameState.player_stamina), 0.0, st_max)
	var ratio: float = st_cur / st_max
	var inner_w: float = maxf(10.0, (stamina_bar.custom_minimum_size.x - 2.0) if stamina_bar else 43.0)
	stamina_fill.size.x = 0.0 if st_cur <= 0.5 else maxf(1.0, roundf(inner_w * ratio))
	if ratio < 0.20:
		stamina_fill.color = Color("#E64C5A")
	elif ratio < 0.45:
		stamina_fill.color = Color("#E8B84B")
	elif _ui_mode == "act3":
		stamina_fill.color = Color("#B8C4D4")
	elif _ui_mode == "distorted":
		stamina_fill.color = Color("#E86A78")
	else:
		stamina_fill.color = Color("#5CC8E8")

func _update_hud() -> void:
	_update_hud_visibility()
	if _heart_textures.is_empty():
		_heart_textures = HuwagUiTheme.build_heart_textures()
	var hp: int = clampi(GameState.player_hp, 0, maxi(1, GameState.player_max_hp))
	var max_hp: int = maxi(1, GameState.player_max_hp)
	var segments: int = 0 if hp <= 0 else clampi(int(ceil(float(hp) * 6.0 / float(max_hp))), 1, 6)
	_hp_segments = segments
	var hearts := _get_heart_nodes()
	for i in range(hearts.size()):
		var h := hearts[i]
		var seg_start := i * 2
		if segments >= seg_start + 2:
			h.texture = _heart_textures["full"]
		elif segments == seg_start + 1:
			h.texture = _heart_textures["half"]
		else:
			h.texture = _heart_textures["empty"]
	_update_stamina_hud()

	if skills_label:
		var tags: PackedStringArray = []
		if GameState.get_switch("016_Magia_de_agua_obtida"):
			tags.append("H2O")
		var heal_count: int = GameState.get_item_count("gota_calmante")
		if heal_count > 0:
			tags.append("Cura×%d" % heal_count)
		skills_label.visible = not tags.is_empty()
		skills_label.text = " · ".join(tags)

	if act_place_label:
		var place_name := "Quarto de Huwag"
		if _current_scene_path.ends_with("StreetPreview.tscn"):
			place_name = "Rua de Agdangan"
		elif _current_scene_path.ends_with("FireStation.tscn"):
			place_name = "Quartel dos Bombeiros"
		elif _current_scene_path.ends_with("ForestCorridor.tscn") or _current_scene_path.ends_with("forest_trail.tscn"):
			place_name = "Trilha da Floresta"
		elif _current_scene_path.ends_with("ForestClearing.tscn") or _current_scene_path.ends_with("forest_clearing.tscn"):
			place_name = "Clareira da Lagoa"
		elif _current_scene_path.find("vhs_memory") != -1:
			place_name = "Memória / Pesadelo"

		var ato: int = int(GameState.get_var("Ato", 1))
		var roman := "I"
		if ato == 2:
			roman = "II"
		elif ato >= 3 or GameState.is_unfiltered_act3():
			roman = "III"
		act_place_label.text = "Ato %s · %s" % [roman, place_name]
