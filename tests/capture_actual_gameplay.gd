extends SceneTree

func _init() -> void:
	call_deferred("_run_capture")

func _run_capture() -> void:
	print("Carregando Main.tscn...")
	var main_scene: PackedScene = load("res://scenes/main/Main.tscn")
	var main_node: Node2D = main_scene.instantiate()
	root.add_child(main_node)

	# Espera alguns quadros para a renderização do quarto e diálogo inicial
	for i in range(30):
		await process_frame

	var vp := root.get_viewport()
	var img := vp.get_texture().get_image()
	if img:
		img.save_png("res://docs/screenshots/final_validated_room.png")
		print("[OK] Captura salva com sucesso em res://docs/screenshots/final_validated_room.png")

	quit(0)
