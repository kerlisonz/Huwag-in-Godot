class_name CorruptedEyeSwarm
extends Node2D

## Gerencia enxame abundante de WatchingEye em pontos sombrios do mapa ou bordas
## durante o Modo Corrompido (sem excessos vermelhos), reagindo ao jogador em tempo real.

var _eyes: Array[WatchingEye] = []
var _screen_space_target_mode: bool = false
var _was_active: bool = false


func _ready() -> void:
	z_index = 9
	set_process(true)
	refresh_visibility()


func setup_world_swarm(anchor_points: Array, seed_val: int = 1042, base_scale: float = 0.92) -> void:
	_clear_eyes()
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_val
	for i in range(anchor_points.size()):
		var pt: Vector2 = anchor_points[i] if anchor_points[i] is Vector2 else Vector2(anchor_points[i].get("pos", Vector2.ZERO))
		var scl: float = base_scale
		if anchor_points[i] is Dictionary:
			scl = float(anchor_points[i].get("scale", rng.randf_range(base_scale * 0.78, base_scale * 1.25)))
		else:
			scl = rng.randf_range(base_scale * 0.78, base_scale * 1.25)

		var eye := WatchingEye.new()
		eye.name = "SwarmEye_%d" % i
		eye.position = pt
		eye.scale = Vector2(scl, scl)
		eye.set_variant((i + rng.randi_range(0, 3)) % 4)
		eye.max_offset = Vector2(4.0, 2.0)
		eye.tracking_distance_scale = 32.0
		eye.modulate = Color(0.90, 0.88, 1.0, rng.randf_range(0.76, 0.96))
		add_child(eye)
		_eyes.append(eye)
	refresh_visibility()


func setup_screen_edge_swarm() -> void:
	_screen_space_target_mode = true
	var edge_pts := [
		{"pos": Vector2(22, 42), "scale": 0.78},
		{"pos": Vector2(616, 46), "scale": 0.82},
		{"pos": Vector2(18, 178), "scale": 0.72},
		{"pos": Vector2(622, 184), "scale": 0.76},
		{"pos": Vector2(26, 336), "scale": 0.85},
		{"pos": Vector2(612, 334), "scale": 0.85},
		{"pos": Vector2(318, 16), "scale": 0.70},
		{"pos": Vector2(465, 18), "scale": 0.68},
	]
	setup_world_swarm(edge_pts, 8891, 0.76)
	for i in range(_eyes.size()):
		_eyes[i].modulate.a = 0.58


func get_eye_count() -> int:
	return _eyes.size()


func get_eyes() -> Array[WatchingEye]:
	return _eyes


func is_corrupted_active() -> bool:
	if not has_node("/root/GameState"):
		return false
	var gs := get_node("/root/GameState")
	var corrupted: bool = gs.has_method("is_corrupted_mode") and bool(gs.call("is_corrupted_mode"))
	var act3: bool = gs.has_method("is_unfiltered_act3") and bool(gs.call("is_unfiltered_act3"))
	return corrupted and not act3


func refresh_visibility() -> void:
	var active := is_corrupted_active()
	visible = active
	if active and not _was_active:
		if has_node("/root/AudioManager") and is_inside_tree():
			get_node("/root/AudioManager").play_sfx("eye_open", -12.0, 0.95)
	_was_active = active


func _process(_delta: float) -> void:
	var active := is_corrupted_active()
	if visible != active:
		refresh_visibility()
	if not visible:
		return
	var tree := get_tree()
	if tree == null:
		return
	var player := tree.get_first_node_in_group("player") as Node2D
	if player == null or not is_instance_valid(player):
		return
	if _screen_space_target_mode:
		var screen_pos := player.get_global_transform_with_canvas().origin
		for eye in _eyes:
			if is_instance_valid(eye):
				eye.update_tracking_for_position(screen_pos)
	else:
		for eye in _eyes:
			if is_instance_valid(eye):
				eye.update_tracking_for_position(player.global_position)


func _clear_eyes() -> void:
	for e in _eyes:
		if is_instance_valid(e):
			e.queue_free()
	_eyes.clear()
