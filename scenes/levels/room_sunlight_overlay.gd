extends Node2D

@onready var room: Node2D = get_parent()

func _draw() -> void:
	if room == null:
		return
	var act3: bool = GameState.is_unfiltered_act3()
	var night: bool = room._is_night_room() if room.has_method("_is_night_room") else false

	# Partículas sutis de poeira flutuando no feixe de luz natural da janela
	if not act3:
		var t: float = room.dust_time if "dust_time" in room else 0.0
		var mote_col := Color(1.0, 0.98, 0.85, 0.40 if not night else 0.20)
		for i in range(8):
			var phase := float(i) * 1.35
			var mx: float = 270.0 + fmod(phase * 42.0 + t * 9.0, 130.0) + sin(t * 1.5 + phase) * 8.0
			var my: float = 70.0 + fmod(phase * 31.0 + t * 14.0, 180.0) + cos(t * 1.2 + phase) * 6.0
			var alpha_mote := clampf(sin(t * 2.0 + phase) * 0.5 + 0.5, 0.1, 0.6)
			draw_circle(Vector2(mx, my), 1.0, Color(mote_col.r, mote_col.g, mote_col.b, mote_col.a * alpha_mote))
