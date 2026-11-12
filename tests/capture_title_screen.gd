extends SceneTree

func _init() -> void:
	var title_scene: PackedScene = load("res://scenes/menu/TitleScreen.tscn")
	var instance: Node = title_scene.instantiate()
	root.add_child(instance)
	call_deferred("_capture")

func _capture() -> void:
	for i in range(10):
		await process_frame

	var vp := root.get_viewport()
	var img := vp.get_texture().get_image()
	if img:
		img.save_png("res://docs/screenshots/title_screen_validated.png")
		print("[OK] Screenshot da Tela Inicial gravada em docs/screenshots/title_screen_validated.png")
	quit(0)
