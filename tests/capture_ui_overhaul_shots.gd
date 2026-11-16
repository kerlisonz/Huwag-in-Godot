extends SceneTree

## Captura screenshots reais em janela (sem --headless) da nova UI, HUD de 3 Corações +
## Mini Barra de Estamina, Portraits 96x96 Nearest, Choices/Toast, ControlsModal e Title Options.

const OUT_DIR := "C:/Users/SnyX/.gemini/antigravity/brain/6f04634a-b7d4-4d6f-9c20-24b6fdf404a0"

func _init() -> void:
	call_deferred("_run")


func _wait_frames(n: int = 8) -> void:
	for _i in range(n):
		await process_frame


func _save_shot(filename: String) -> void:
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	if img == null:
		push_error("Viewport image null for " + filename)
		return
	var out_path := "%s/%s" % [OUT_DIR, filename]
	img.save_png(out_path)
	print("[UI Shot] Salvo: ", out_path)


func _run() -> void:
	var gs := root.get_node_or_null("GameState")
	assert(gs != null, "GameState autoload precisa existir")

	# ---------------------------------------------------------
	# 1. TitleScreen + OptionsModal
	# ---------------------------------------------------------
	var title_ps: PackedScene = load("res://scenes/menu/TitleScreen.tscn")
	var title_node := title_ps.instantiate()
	root.add_child(title_node)
	await _wait_frames(15)
	title_node.call("_on_options_pressed")
	await _wait_frames(12)
	await _save_shot("ui_shot_title_options.png")
	title_node.queue_free()
	await _wait_frames(6)

	# ---------------------------------------------------------
	# 2. Instanciar Main em Ato I Normal (FireStation + Cap. Reyes)
	# ---------------------------------------------------------
	gs.call("reset_to_new_game")
	gs.set("equipped_outfit", "bombeiro")
	var main_ps: PackedScene = load("res://scenes/main/Main.tscn")
	var main_node := main_ps.instantiate()
	root.add_child(main_node)
	main_node.call("load_level", "res://scenes/levels/FireStation.tscn", "default")
	await _wait_frames(18)

	var dlg := main_node.get_node_or_null("CanvasLayer/DialogueBox")
	main_node.call("_on_request_dialogue", [
		{
			"speaker": "Capitão Reyes",
			"expression": "neutral",
			"text": "Mantenha a calma em Agdangan, Huwag. O fogo no bosque ainda não cedeu.",
		}
	], Callable())
	await _wait_frames(12)
	if dlg:
		dlg.call("_finish_typing")
	await _wait_frames(8)
	await _save_shot("ui_shot_dialogue_normal_huwag_reyes.png")

	# ---------------------------------------------------------
	# 3. ChoicesPanel + Toast Notificação em RoomHuwag (Rádio BFP)
	# ---------------------------------------------------------
	if dlg:
		dlg.call("close_dialogue")
	main_node.call("load_level", "res://scenes/levels/RoomHuwag.tscn", "initial")
	await _wait_frames(15)
	main_node.call("_on_notification_requested", "Progresso salvo em Agdangan")
	main_node.call("_on_request_dialogue", [
		{
			"speaker": "Rádio BFP",
			"expression": "neutral",
			"text": "Canal 04... Quem ainda está escutando na frequência do quartel?",
			"choices": ["Responder como Bombeiro", "Desligar o receptor em silêncio"],
		}
	], Callable())
	await _wait_frames(12)
	if dlg:
		dlg.call("_finish_typing")
	await _wait_frames(8)
	await _save_shot("ui_shot_dialogue_choices_toast.png")

	# ---------------------------------------------------------
	# 4. HUD Crítico: 3 Corações (Meio Coração + 2 Vazios) + Mini Barra de Estamina + Badges
	# ---------------------------------------------------------
	if dlg:
		dlg.call("close_dialogue")
	var st := main_node.get_node_or_null("CanvasLayer/StatusLabel") as Label
	if st:
		st.text = ""
		st.visible = false
	gs.set("player_hp", 14)
	gs.hp_changed.emit(14, 100)
	gs.set("player_stamina", 36.0)
	gs.stamina_changed.emit(36.0, 100.0)
	gs.call("set_switch", "016_Magia_de_agua_obtida", true)
	gs.call("add_item", "gota_calmante", 2)
	main_node.call("_update_hud")
	await _wait_frames(15)
	await _save_shot("ui_shot_hud_low_hp_stamina.png")

	# ---------------------------------------------------------
	# 5. ControlsModal [F1] unificado 1px
	# ---------------------------------------------------------
	main_node.call("_toggle_controls_modal")
	await _wait_frames(10)
	await _save_shot("ui_shot_controls_modal.png")
	main_node.call("_toggle_controls_modal")
	await _wait_frames(6)

	# ---------------------------------------------------------
	# 6. Modo Distorcido / Carmesim (Ato 2 Dose Maior + Toby Corrompido)
	# ---------------------------------------------------------
	gs.call("advance_to_act_2")
	gs.call("set_higher_dose", true)
	gs.set("player_hp", 50) # 1 coração cheio + meio + vazio
	gs.hp_changed.emit(50, 100)
	main_node.call("load_level", "res://scenes/levels/StreetPreview.tscn", "from_room")
	await _wait_frames(18)
	gs.set("player_stamina", 16.0) # exausto / barra vermelha crítica
	gs.stamina_changed.emit(16.0, 100.0)
	main_node.call("_on_request_dialogue", [
		{
			"speaker": "Toby",
			"expression": "distorted",
			"text": "Huwag... a minha mão não para de crescer debaixo das cinzas...",
		}
	], Callable())
	await _wait_frames(8)
	if dlg:
		dlg.call("_finish_typing")
	await _wait_frames(4)
	gs.set("player_stamina", 16.0)
	gs.stamina_changed.emit(16.0, 100.0)
	await _wait_frames(2)
	await _save_shot("ui_shot_dialogue_distorted_crimson.png")

	# ---------------------------------------------------------
	# 7. Santelmo Retrato Novo + Trilha da Floresta
	# ---------------------------------------------------------
	if dlg:
		dlg.call("close_dialogue")
	gs.call("set_higher_dose", false)
	gs.call("set_act", 1)
	gs.call("set_perception_mode", gs.PerceptionMode.FILTERED_MORNING)
	main_node.call("load_level", "res://scenes/levels/forest_trail.tscn", "from_street")
	await _wait_frames(18)
	main_node.call("_on_request_dialogue", [
		{
			"speaker": "Santelmo",
			"expression": "neutral",
			"text": "As chamas antigas ainda lembram de quem fugiu pela trilha.",
		}
	], Callable())
	await _wait_frames(12)
	if dlg:
		dlg.call("_finish_typing")
	await _wait_frames(6)
	await _save_shot("ui_shot_santelmo_portrait.png")

	main_node.queue_free()
	await _wait_frames(5)
	print("[UI Shot] Captura completa!")
	quit(0)
