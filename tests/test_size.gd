extends SceneTree

func _init() -> void:
	DisplayServer.window_set_size(Vector2i(1920, 1080))
	var main = load("res://scenes/main/Main.tscn").instantiate()
	root.add_child(main)
	call_deferred("_capture")

func _capture() -> void:
	for i in range(25):
		await process_frame
	var img = root.get_viewport().get_texture().get_image()
	print("EXACT_SIZE: ", img.get_size())
	img.save_png("res://docs/screenshots/quarto_huwag_1080p_exact.png")
	quit(0)

