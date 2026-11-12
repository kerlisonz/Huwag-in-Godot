@tool
extends Control

var opt_mode: OptionButton
var edit_id: LineEdit
var opt_preset: OptionButton
var edit_prompt: TextEdit
var edit_input_file: LineEdit
var btn_browse_file: Button
var btn_generate: Button
var btn_normalize: Button
var btn_create_scene: Button
var log_label: RichTextLabel
var file_dialog: EditorFileDialog

const RESOLUTIONS = {
	0: Vector2i(640, 360),
	1: Vector2i(512, 512),
	2: Vector2i(48, 48)
}

const PRESET_PREFIXES = {
	0: "2D 16-bit pixel art interior, traditional Filipino Bahay Kubo, bamboo weave walls sawali, wood plank floor, warm sunlight, top-down 3/4 perspective: ",
	1: "2D 16-bit pixel art interior, Bureau of Fire Protection (BFP) station in Agdangan Philippines, concrete and red wood, fire gear, dispatch radio table, top-down 3/4 perspective: ",
	2: "2D 16-bit pixel art exterior, tropical street in Agdangan Quezon province Philippines, palm trees, dirt road, wooden fences, top-down 3/4 perspective: ",
	3: "2D 16-bit pixel art interior, psychological unfiltered Act 3, desaturated gloomy muted colors, cold lighting, top-down 3/4 perspective: "
}

func _init() -> void:
	name = "AntigravityStudio"
	custom_minimum_size = Vector2(300, 450)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL

func _ready() -> void:
	_build_ui()

func _build_ui() -> void:
	for c in get_children():
		c.queue_free()

	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.set_anchors_preset(PRESET_FULL_RECT)
	add_child(scroll)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_child(vbox)

	# 1. Header
	var title := Label.new()
	title.text = "⚡ Antigravity Art & Scenery"
	title.add_theme_font_size_override("font_size", 14)
	vbox.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Ponte integrada de geração de fotos e cenários"
	subtitle.add_theme_color_override("font_color", Color(0.7, 0.75, 0.8))
	vbox.add_child(subtitle)

	var sep1 := HSeparator.new()
	vbox.add_child(sep1)

	# 2. Tipo de Asset
	var lbl_mode := Label.new()
	lbl_mode.text = "Tipo de Asset / Resolução:"
	vbox.add_child(lbl_mode)

	opt_mode = OptionButton.new()
	opt_mode.add_item("Cenário de Nível (640 × 360 px - Estilo Quarto)", 0)
	opt_mode.add_item("Retrato de Diálogo (512 × 512 px - Anime)", 1)
	opt_mode.add_item("Objeto / Móvel Top-Down (48 × 48 px)", 2)
	vbox.add_child(opt_mode)

	# 3. ID / Nome do Arquivo
	var lbl_id := Label.new()
	lbl_id.text = "Nome do Asset (slug):"
	vbox.add_child(lbl_id)

	edit_id = LineEdit.new()
	edit_id.text = "station_bfp"
	edit_id.placeholder_text = "ex: station_bfp, clinic_agdangan"
	vbox.add_child(edit_id)

	# 4. Preset Estético
	var lbl_preset := Label.new()
	lbl_preset.text = "Estilo / Ambientação Filipina:"
	vbox.add_child(lbl_preset)

	opt_preset = OptionButton.new()
	opt_preset.add_item("Bahay Kubo / Tradicional Filipino (Quente, Madeira)", 0)
	opt_preset.add_item("Quartel BFP de Agdangan (Concreto, Vermelho)", 1)
	opt_preset.add_item("Rua Tropical / Centro de Agdangan (Palmeiras)", 2)
	opt_preset.add_item("Psicológico / Dessaturado (Ato 3 - Frio)", 3)
	vbox.add_child(opt_preset)

	# 5. Prompt de Geração
	var lbl_prompt := Label.new()
	lbl_prompt.text = "Descrição do Cenário:"
	vbox.add_child(lbl_prompt)

	edit_prompt = TextEdit.new()
	edit_prompt.custom_minimum_size = Vector2(0, 85)
	edit_prompt.text = "Interior do Quartel de Bombeiros BFP de Agdangan. Baia do caminhão ao fundo, mesa de despacho com rádio transmissor, prateleiras de mangueiras e machados contra incêndio, janelas para a praça. Vista top-down 3/4."
	vbox.add_child(edit_prompt)

	# 6. Botão Gerar com Antigravity
	btn_generate = Button.new()
	btn_generate.text = "🚀 Gerar Cenário com Antigravity"
	btn_generate.pressed.connect(_on_btn_generate_pressed)
	vbox.add_child(btn_generate)

	var sep2 := HSeparator.new()
	vbox.add_child(sep2)

	# 7. Seção de Normalização de Arquivo Existente
	var lbl_norm_title := Label.new()
	lbl_norm_title.text = "Normalizar Imagem Externa:"
	vbox.add_child(lbl_norm_title)

	var hbox_file := HBoxContainer.new()
	vbox.add_child(hbox_file)

	edit_input_file = LineEdit.new()
	edit_input_file.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	edit_input_file.placeholder_text = "Caminho da imagem (.png / .jpg)"
	hbox_file.add_child(edit_input_file)

	btn_browse_file = Button.new()
	btn_browse_file.text = "..."
	btn_browse_file.pressed.connect(_on_btn_browse_pressed)
	hbox_file.add_child(btn_browse_file)

	btn_normalize = Button.new()
	btn_normalize.text = "🎯 Normalizar para 640x360 (Nearest Neighbor)"
	btn_normalize.pressed.connect(_on_btn_normalize_pressed)
	vbox.add_child(btn_normalize)

	btn_create_scene = Button.new()
	btn_create_scene.text = "📦 Gerar Cena .tscn com Colisões"
	btn_create_scene.pressed.connect(_on_btn_create_scene_pressed)
	vbox.add_child(btn_create_scene)

	# 8. Console de Log
	var lbl_log := Label.new()
	lbl_log.text = "Status / Console:"
	vbox.add_child(lbl_log)

	log_label = RichTextLabel.new()
	log_label.custom_minimum_size = Vector2(0, 90)
	log_label.bbcode_enabled = true
	log_label.scroll_following = true
	log_label.text = "[color=#77aaff]Antigravity Art Studio pronto.[/color]\nSelecione o modo e descreva o cenário."
	vbox.add_child(log_label)

func _log(msg: String, color: String = "#ffffff") -> void:
	if log_label:
		log_label.append_text("[color=%s]%s[/color]\n" % [color, msg])

func _get_target_resolution() -> Vector2i:
	var mode_idx: int = opt_mode.selected if opt_mode else 0
	return RESOLUTIONS.get(mode_idx, Vector2i(640, 360))

func _get_python_path() -> String:
	# Tenta caminho padrão detectado no Windows
	if FileAccess.file_exists("C:/Python315/python.exe"):
		return "C:/Python315/python.exe"
	return "python"

func _get_tool_script_path() -> String:
	return ProjectSettings.globalize_path("res://addons/antigravity_bridge/tools/asset_processor.py")

func _on_btn_generate_pressed() -> void:
	var slug := edit_id.text.strip_edges()
	if slug.is_empty():
		_log("ERRO: Digite um nome para o asset (slug).", "#ff6666")
		return

	var res := _get_target_resolution()
	var mode_idx := opt_mode.selected
	var preset_idx := opt_preset.selected
	var user_prompt := edit_prompt.text.strip_edges()
	var full_prompt: String = str(PRESET_PREFIXES.get(preset_idx, "")) + user_prompt

	var target_folder := "res://assets/environments/%s" % slug if mode_idx == 0 else "res://assets/portraits"
	var target_file := "%s/%s_bg.png" % [target_folder, slug] if mode_idx == 0 else "%s/%s.png" % [target_folder, slug]

	_log("Registrando solicitação para '%s' (%dx%d)..." % [slug, res.x, res.y], "#ffcc44")

	var req_data := {
		"slug": slug,
		"mode": mode_idx,
		"preset": preset_idx,
		"resolution": [res.x, res.y],
		"user_prompt": user_prompt,
		"full_prompt": full_prompt,
		"target_file": target_file,
		"reference_bg": "res://assets/environments/room_huwag/room_huwag_bg.png"
	}

	var req_global_path := ProjectSettings.globalize_path("res://.antigravity_bridge/requests/%s_request.json" % slug)
	var py := _get_python_path()
	var script_path := _get_tool_script_path()

	var args: Array[String] = [
		script_path,
		"request",
		"--output", req_global_path,
		"--slug", slug,
		"--mode", str(mode_idx),
		"--preset", str(preset_idx),
		"--width", str(res.x),
		"--height", str(res.y),
		"--prompt", user_prompt,
		"--full_prompt", full_prompt,
		"--target_file", target_file
	]

	var output: Array = []
	var exit_code := OS.execute(py, args, output, true)
	if exit_code == 0:
		_log("✓ Solicitação enviada com sucesso!", "#66ff66")
		_log("Arquivo de requisição: [color=#ffffaa]%s[/color]" % req_global_path)
		_log("O Antigravity processará a imagem com a paleta de Huwag.", "#aaccff")
	else:
		_log("Erro ao registrar requisição: %s" % str(output), "#ff6666")

func _on_btn_normalize_pressed() -> void:
	var in_path := edit_input_file.text.strip_edges()
	if in_path.is_empty():
		_log("ERRO: Selecione um arquivo de entrada para normalizar.", "#ff6666")
		return

	var slug := edit_id.text.strip_edges()
	if slug.is_empty():
		slug = "asset_normalized"

	var res := _get_target_resolution()
	var out_dir := ProjectSettings.globalize_path("res://assets/environments/%s" % slug)
	var out_path := "%s/%s_bg.png" % [out_dir, slug]

	_log("Normalizando imagem para %dx%d (Nearest)..." % [res.x, res.y], "#ffcc44")

	var py := _get_python_path()
	var script_path := _get_tool_script_path()
	var global_in := ProjectSettings.globalize_path(in_path) if in_path.begins_with("res://") else in_path

	var args: Array[String] = [
		script_path,
		"normalize",
		"--input", global_in,
		"--output", out_path,
		"--width", str(res.x),
		"--height", str(res.y),
		"--nearest"
	]

	var output: Array = []
	var exit_code := OS.execute(py, args, output, true)
	if exit_code == 0:
		_log("✓ Imagem normalizada e salva!", "#66ff66")
		_log("Destino: [color=#ffffaa]%s[/color]" % out_path)
		if Engine.is_editor_hint():
			EditorInterface.get_resource_filesystem().scan()
	else:
		_log("Falha ao normalizar: %s" % str(output), "#ff6666")

func _on_btn_create_scene_pressed() -> void:
	var slug := edit_id.text.strip_edges()
	if slug.is_empty():
		_log("ERRO: Digite o nome do asset (slug).", "#ff6666")
		return

	var scene_global_path := ProjectSettings.globalize_path("res://scenes/levels/%s.tscn" % slug.capitalize().replace(" ", ""))
	var bg_res_path := "res://assets/levels/%s/%s_bg.png" % [slug, slug]

	_log("Criando cena .tscn com base 640x360...", "#ffcc44")

	var py := _get_python_path()
	var script_path := _get_tool_script_path()

	var args: Array[String] = [
		script_path,
		"create_scene",
		"--output", scene_global_path,
		"--bg", bg_res_path,
		"--title", slug.capitalize().replace(" ", "")
	]

	var output: Array = []
	var exit_code := OS.execute(py, args, output, true)
	if exit_code == 0:
		_log("✓ Cena criada com sucesso!", "#66ff66")
		_log("Caminho: [color=#ffffaa]%s[/color]" % scene_global_path)
		if Engine.is_editor_hint():
			EditorInterface.get_resource_filesystem().scan()
	else:
		_log("Falha ao criar cena: %s" % str(output), "#ff6666")

func _on_btn_browse_pressed() -> void:
	if not Engine.is_editor_hint():
		return
	if file_dialog == null:
		file_dialog = EditorFileDialog.new()
		file_dialog.file_mode = EditorFileDialog.FILE_MODE_OPEN_FILE
		file_dialog.add_filter("*.png, *.jpg, *.jpeg, *.webp ; Imagens Suportadas")
		file_dialog.file_selected.connect(func(path: String) -> void:
			if edit_input_file:
				edit_input_file.text = path
		)
		add_child(file_dialog)
	file_dialog.popup_file_dialog()
