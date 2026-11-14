extends Control
class_name DialogueBox

signal dialogue_finished(choice_index: int)
signal conflict_triggered(target_id: String, context: Dictionary)

@onready var backdrop_shade: ColorRect = $BackdropShade
@onready var listener_card: Control = $ListenerCard
@onready var listener_texture: TextureRect = $ListenerCard/ListenerTexture
@onready var dialogue_row: HBoxContainer = $DialogueRow
@onready var portrait_slot: Control = $DialogueRow/PortraitSlot
@onready var portrait_card: Control = $DialogueRow/PortraitSlot/PortraitCard
@onready var pedestal: Panel = $DialogueRow/PortraitSlot/PortraitCard/Pedestal
@onready var portrait_texture: TextureRect = $DialogueRow/PortraitSlot/PortraitCard/PortraitTexture
@onready var placeholder_tag: Label = $DialogueRow/PortraitSlot/PortraitCard/PlaceholderTag
@onready var spine_bar: Panel = $DialogueRow/SpineBar
@onready var speech_column: VBoxContainer = $DialogueRow/SpeechColumn
@onready var panel: PanelContainer = $DialogueRow/SpeechColumn/Panel
@onready var speaker_badge: PanelContainer = $DialogueRow/SpeechColumn/HeaderRow/SpeakerBadge
@onready var speaker_label: Label = $DialogueRow/SpeechColumn/HeaderRow/SpeakerBadge/BadgeMargin/SpeakerLabel
@onready var role_label: Label = $DialogueRow/SpeechColumn/HeaderRow/RoleLabel
@onready var header_rule: ColorRect = $DialogueRow/SpeechColumn/Panel/Margin/VBox/HeaderRule
@onready var body_label: RichTextLabel = $DialogueRow/SpeechColumn/Panel/Margin/VBox/BodyLabel
@onready var choices_vbox: VBoxContainer = $DialogueRow/SpeechColumn/Panel/Margin/VBox/ChoicesVBox
@onready var prompt_label: Label = $DialogueRow/SpeechColumn/Panel/Margin/VBox/BottomRow/PromptLabel

var _pages: Array[Dictionary] = []
var _page_index: int = 0
var _active: bool = false
var _selected_choice: int = 0
var _current_choices: Array[String] = []
var _choice_labels: Array[Label] = []
var _input_cooldown: float = 0.0
var _last_speaker_id: String = ""
var _last_expression: String = ""
var _texture_cache: Dictionary = {}
var _active_tween: Tween = null
var _cursor_pulse: float = 0.0
var _pixel_font: Font = null

const CARD_BASE_POS := Vector2(0.0, 0.0)

func _ready() -> void:
	visible = false
	if ResourceLoader.exists("res://assets/fonts/undertale-deltarune-extended-fixed.otf"):
		_pixel_font = load("res://assets/fonts/undertale-deltarune-extended-fixed.otf") as Font
	if portrait_texture:
		portrait_texture.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	if listener_texture:
		listener_texture.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	GameState.perception_changed.connect(_on_perception_changed)
	GameState.outfit_changed.connect(func(_o: String) -> void:
		if _active:
			_show_current_page(false)
	)
	_apply_theme_style(GameState.perception_mode, Color("#F5CB5C"))

func is_open() -> bool:
	return _active

func close_dialogue() -> void:
	_active = false
	visible = false
	GameState.dialogue_active = false

func start_dialogue(pages: Array) -> void:
	if pages.is_empty():
		dialogue_finished.emit(-1)
		return
	_pages.clear()
	for p in pages:
		if typeof(p) == TYPE_DICTIONARY:
			_pages.append(p.duplicate(true))
	if _pages.is_empty():
		dialogue_finished.emit(-1)
		return

	_page_index = 0
	_selected_choice = 0
	_last_speaker_id = ""
	_last_expression = ""
	_active = true
	GameState.dialogue_active = true
	visible = true
	_input_cooldown = 0.12
	_show_current_page(true)

func _process(delta: float) -> void:
	if not _active:
		return

	queue_redraw()

	if not _current_choices.is_empty():
		_cursor_pulse = fmod(_cursor_pulse + delta * 5.0, TAU)
		if _selected_choice >= 0 and _selected_choice < _choice_labels.size():
			var alpha: float = 0.85 + sin(_cursor_pulse) * 0.15
			_choice_labels[_selected_choice].modulate.a = alpha

	if _input_cooldown > 0.0:
		_input_cooldown -= delta
		return

	if not _current_choices.is_empty():
		if Input.is_action_just_pressed("ui_up") or Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
			_change_choice(-1)
			_input_cooldown = 0.14
			return
		elif Input.is_action_just_pressed("ui_down") or Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
			_change_choice(1)
			_input_cooldown = 0.14
			return
		elif Input.is_action_just_pressed("ui_left") or Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
			_change_choice(-1)
			_input_cooldown = 0.14
			return
		elif Input.is_action_just_pressed("ui_right") or Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
			_change_choice(1)
			_input_cooldown = 0.14
			return

	if _is_confirm_just_pressed():
		_advance_page()
		_input_cooldown = 0.14

func _is_confirm_just_pressed() -> bool:
	return (
		Input.is_action_just_pressed("ui_accept")
		or Input.is_action_just_pressed("interact")
		or Input.is_key_pressed(KEY_E)
		or Input.is_key_pressed(KEY_ENTER)
		or Input.is_key_pressed(KEY_SPACE)
	)

func _change_choice(delta_idx: int) -> void:
	if _current_choices.is_empty():
		return
	_selected_choice = wrapi(_selected_choice + delta_idx, 0, _current_choices.size())
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").play_sfx("ui_hover")
	_refresh_choice_visuals()

func _infer_expression(speaker_id: String, text: String, explicit_expr: String) -> String:
	if not explicit_expr.is_empty():
		return explicit_expr
	if speaker_id != "huwag":
		return "default"
	var lower := text.to_lower()
	if lower.find("assust") != -1 or lower.find("choque") != -1 or lower.find("sangue") != -1 or lower.find("horror") != -1 or lower.find("socorro") != -1 or lower.find("não pode ser") != -1:
		return "scared"
	if lower.find("preciso") != -1 or lower.find("resgat") != -1 or lower.find("apagar") != -1 or lower.find("enfrent") != -1 or lower.find("dever") != -1 or lower.find("não vou") != -1 or lower.find("basta") != -1:
		return "angry"
	if lower.find("cansa") != -1 or lower.find("suor") != -1 or lower.find("fumaça") != -1 or lower.find("vazio") != -1 or lower.find("dormi") != -1 or lower.find("pálido") != -1 or lower.find("preocup") != -1 or lower.find("estranh") != -1:
		return "worried"
	return "neutral"

func _format_narrative_text(raw_text: String) -> String:
	var lines := raw_text.split("\n")
	var formatted: Array[String] = []
	for line in lines:
		var trimmed := line.strip_edges()
		if trimmed.is_empty():
			formatted.append("")
		elif trimmed.begins_with("* "):
			formatted.append(trimmed.substr(2))
		else:
			formatted.append(trimmed)
	return "\n".join(formatted)

func _load_portrait_texture(path: String) -> Texture2D:
	if _texture_cache.has(path):
		return _texture_cache[path] as Texture2D
	if ResourceLoader.exists(path):
		var tex := load(path) as Texture2D
		if tex != null:
			_texture_cache[path] = tex
			return tex
	return null

func _find_other_interlocutor(current_speaker_id: String) -> Dictionary:
	var is_act3 := GameState.is_unfiltered_act3()
	for p in _pages:
		var sp := str(p.get("speaker", "Huwag Matitiis"))
		var sid := CharacterProfiles.resolve_speaker_id(sp)
		if sid != current_speaker_id:
			return CharacterProfiles.get_profile_data(sp, "neutral", is_act3, GameState.equipped_outfit)
	if current_speaker_id != "huwag":
		return CharacterProfiles.get_profile_data("Huwag Matitiis", "neutral", is_act3, GameState.equipped_outfit)
	return {}

func _show_current_page(is_opening: bool = false) -> void:
	var page: Dictionary = _pages[_page_index]
	var raw_speaker: String = str(page.get("speaker", "Huwag Matitiis"))
	var text: String = str(page.get("text", ""))
	var explicit_expr: String = str(page.get("expression", ""))
	var is_act3 := GameState.is_unfiltered_act3()

	var speaker_id := CharacterProfiles.resolve_speaker_id(raw_speaker)
	var expr := _infer_expression(speaker_id, text, explicit_expr)
	var outfit_id: String = str(page.get("outfit", GameState.equipped_outfit))
	var profile := CharacterProfiles.get_profile_data(raw_speaker, expr, is_act3, outfit_id)

	var display_name: String = str(profile.get("display_name", raw_speaker))
	var role_sub: String = str(profile.get("role_subtitle", ""))
	var is_placeholder: bool = bool(profile.get("is_placeholder", false))
	var accent_col: Color = profile.get("accent_color", Color("#F5CB5C"))
	var portrait_path: String = str(profile.get("portrait_path", ""))
	var resolved_expr: String = str(profile.get("expression", expr))

	var is_monologue: bool = bool(page.get("is_monologue", false)) or bool(page.get("is_thought", false)) or not bool(page.get("show_portrait", true))

	speaker_label.text = display_name
	if is_placeholder and not role_sub.is_empty():
		role_label.text = "· %s" % role_sub
		role_label.visible = true
	elif not role_sub.is_empty():
		role_label.text = "· %s" % role_sub
		role_label.visible = false
	else:
		role_label.text = ""
		role_label.visible = false

	body_label.text = _format_narrative_text(text)
	body_label.add_theme_font_size_override("normal_font_size", 9)

	var tex := _load_portrait_texture(portrait_path)
	if portrait_texture:
		portrait_texture.texture = tex
	
	if portrait_slot:
		portrait_slot.visible = (tex != null and not is_monologue)
	if spine_bar:
		spine_bar.visible = (tex != null and not is_monologue)

	if placeholder_tag:
		placeholder_tag.visible = is_placeholder and not is_monologue
	if pedestal:
		pedestal.visible = is_placeholder and not is_monologue

	# Exibe o segundo personagem (ouvinte) à direita quando há diálogo entre dois personagens (como na referência CrossCode)
	if listener_card and listener_texture:
		var other_profile := _find_other_interlocutor(speaker_id)
		var other_path: String = str(other_profile.get("portrait_path", ""))
		var other_tex := _load_portrait_texture(other_path) if not other_path.is_empty() else null
		if other_tex != null and _pages.size() > 1 and not is_monologue:
			listener_texture.texture = other_tex
			listener_card.visible = true
		else:
			listener_card.visible = false

	_apply_theme_style(GameState.perception_mode, accent_col)

	for child in choices_vbox.get_children():
		child.queue_free()
	_choice_labels.clear()
	_current_choices.clear()

	if page.has("choices") and typeof(page["choices"]) == TYPE_ARRAY:
		for item in page["choices"]:
			_current_choices.append(str(item))

	if not _current_choices.is_empty():
		_selected_choice = 0
		choices_vbox.visible = true
		for i in range(_current_choices.size()):
			var lbl := Label.new()
			if _pixel_font != null:
				lbl.add_theme_font_override("font", _pixel_font)
			lbl.add_theme_font_size_override("font_size", 9)
			lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.95))
			lbl.add_theme_constant_override("shadow_offset_x", 1)
			lbl.add_theme_constant_override("shadow_offset_y", 1)
			choices_vbox.add_child(lbl)
			_choice_labels.append(lbl)
		_refresh_choice_visuals()
		prompt_label.text = "[W/S] Escolher · [E] Confirmar"
	else:
		choices_vbox.visible = false
		if _page_index < _pages.size() - 1:
			prompt_label.text = "[E / Enter] ▸"
		else:
			prompt_label.text = "[E / Enter] ■"

	if is_opening:
		_play_open_transition()
	elif speaker_id != _last_speaker_id or resolved_expr != _last_expression:
		_play_speaker_switch_transition()
	_last_speaker_id = speaker_id
	_last_expression = resolved_expr

func _play_open_transition() -> void:
	if _active_tween and _active_tween.is_valid():
		_active_tween.kill()
	modulate.a = 0.0
	if portrait_card:
		portrait_card.position = CARD_BASE_POS + Vector2(-6.0, 0.0)
	_active_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_active_tween.tween_property(self, "modulate:a", 1.0, 0.14)
	if portrait_card:
		_active_tween.tween_property(portrait_card, "position", CARD_BASE_POS, 0.16)

func _play_speaker_switch_transition() -> void:
	if portrait_card == null:
		return
	if _active_tween and _active_tween.is_valid():
		_active_tween.kill()
	portrait_card.position = CARD_BASE_POS + Vector2(-4.0, 0.0)
	_active_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_active_tween.tween_property(portrait_card, "position", CARD_BASE_POS, 0.12)

func _refresh_choice_visuals() -> void:
	var act3 := GameState.is_unfiltered_act3()
	var accent_col: Color = Color("#FFF3B0") if not act3 else Color("#E2E8F0")
	for i in range(_choice_labels.size()):
		var lbl: Label = _choice_labels[i]
		if i == _selected_choice:
			lbl.text = "▸ %s" % _current_choices[i]
			lbl.modulate = accent_col
		else:
			lbl.text = "  %s" % _current_choices[i]
			lbl.modulate = Color("#98A4B8")

func _advance_page() -> void:
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").play_sfx("ui_select" if not _current_choices.is_empty() else "ui_dialogue")
	var current_page: Dictionary = _pages[_page_index]
	if _page_index < _pages.size() - 1:
		_page_index += 1
		_show_current_page(false)
	else:
		var chosen: int = _selected_choice if not _current_choices.is_empty() else -1
		var conflict_target := _resolve_conflict_target(current_page, chosen)
		_active = false
		visible = false
		GameState.dialogue_active = false
		dialogue_finished.emit(chosen)
		if not conflict_target.is_empty():
			conflict_triggered.emit(conflict_target, {
				"choice_index": chosen,
				"speaker": str(current_page.get("speaker", "")),
				"page": current_page
			})

func _resolve_conflict_target(page: Dictionary, chosen_index: int) -> String:
	if page.has("trigger_conflict"):
		var raw_tc: Variant = page["trigger_conflict"]
		if typeof(raw_tc) == TYPE_STRING and not str(raw_tc).is_empty():
			return str(raw_tc)
		elif typeof(raw_tc) == TYPE_BOOL and bool(raw_tc):
			return str(page.get("speaker", "hostile_target"))
	if page.has("conflict_choices") and typeof(page["conflict_choices"]) == TYPE_DICTIONARY:
		var cc: Dictionary = page["conflict_choices"]
		if cc.has(chosen_index):
			return str(cc[chosen_index])
		if cc.has(str(chosen_index)):
			return str(cc[str(chosen_index)])
	return ""

func _on_perception_changed(mode: int) -> void:
	_apply_theme_style(mode, Color("#F5CB5C"))

func _apply_theme_style(mode: int, _accent_col: Color) -> void:
	if panel == null:
		return
	var act3 := (mode == GameState.PerceptionMode.UNFILTERED_ACT3)

	var has_portrait := (portrait_slot != null and portrait_slot.visible)

	# 1. Barra vertical estrutural à direita do retrato (estilo CrossCode da imagem de referência)
	if spine_bar:
		var spine_sb := StyleBoxFlat.new()
		spine_sb.bg_color = Color("#8D8982") if not act3 else Color("#6E7075")
		spine_sb.border_width_left = 1
		spine_sb.border_width_top = 1
		spine_sb.border_width_right = 1
		spine_sb.border_width_bottom = 0
		spine_sb.border_color = Color("#121318")
		spine_bar.add_theme_stylebox_override("panel", spine_sb)

	# 2. Caixa separada de Nome (Nameplate) com canto chanfrado 45° e fundo escuro translúcido
	if speaker_badge:
		var badge_sb := StyleBoxFlat.new()
		badge_sb.corner_detail = 1
		badge_sb.corner_radius_top_left = 0 if has_portrait else 4
		badge_sb.corner_radius_bottom_left = 0
		badge_sb.corner_radius_top_right = 5
		badge_sb.corner_radius_bottom_right = 2
		badge_sb.border_width_left = 1 if not has_portrait else 0
		badge_sb.border_width_top = 1
		badge_sb.border_width_right = 1
		badge_sb.border_width_bottom = 1
		badge_sb.bg_color = Color(0.08, 0.09, 0.12, 0.88) if not act3 else Color(0.09, 0.10, 0.12, 0.90)
		badge_sb.border_color = Color(0.76, 0.79, 0.84, 0.58)
		badge_sb.shadow_color = Color(0.0, 0.0, 0.0, 0.72)
		badge_sb.shadow_size = 2
		speaker_badge.add_theme_stylebox_override("panel", badge_sb)

	# 3. Caixa separada de Fala (Speech Box) ancorada na barra vertical, com chanfro 45° à direita
	var sb := StyleBoxFlat.new()
	sb.corner_detail = 1
	sb.corner_radius_top_left = 0 if has_portrait else 5
	sb.corner_radius_bottom_left = 0 if has_portrait else 5
	sb.corner_radius_top_right = 5
	sb.corner_radius_bottom_right = 6
	sb.border_width_left = 1 if not has_portrait else 0
	sb.border_width_top = 1
	sb.border_width_right = 1
	sb.border_width_bottom = 1
	sb.bg_color = Color(0.07, 0.08, 0.11, 0.88) if not act3 else Color(0.08, 0.09, 0.11, 0.90)
	sb.border_color = Color(0.76, 0.79, 0.84, 0.54)
	sb.shadow_color = Color(0.0, 0.0, 0.0, 0.75)
	sb.shadow_size = 3
	panel.add_theme_stylebox_override("panel", sb)

	if pedestal:
		var ped_sb := StyleBoxFlat.new()
		ped_sb.set_corner_radius_all(3)
		ped_sb.set_border_width_all(1)
		ped_sb.bg_color = Color(0.08, 0.08, 0.12, 0.86)
		ped_sb.border_color = Color(0.76, 0.79, 0.84, 0.45)
		pedestal.add_theme_stylebox_override("panel", ped_sb)

	if speaker_label:
		speaker_label.modulate = Color("#FAF8F2") if not act3 else Color("#E2E8F0")
