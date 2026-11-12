extends SceneTree

func _init() -> void:
	var room_bg: Texture2D = load("res://assets/environments/room_huwag/room_huwag_bg.png")
	print("QUARTO:", room_bg != null, room_bg.get_size() if room_bg else Vector2i.ZERO)
	var cover: Texture2D = load("res://assets/ui/title_cover.png")
	print("CAPA:", cover != null, cover.get_size() if cover else Vector2i.ZERO)
	quit(0 if room_bg != null and cover != null else 1)
