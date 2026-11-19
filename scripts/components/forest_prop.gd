@tool
class_name ForestProp
extends StaticBody2D

## Prop de vegetação da floresta (árvore, arbusto, coqueiro) com colisão e Y-sort
## prontos para duplicar no Editor. Sincroniza textura com a percepção dos Atos 1–3,
## aplica balanço pixel-snapped ao vento ancorado na base e atenua a copa atrás do jogador.

const TEX_NORMAL: Texture2D = preload("res://assets/tilesets/v2/forest_v2_normal.png")
const TEX_DISTORTED: Texture2D = preload("res://assets/tilesets/v2/forest_v2_distorted.png")
const TEX_ACT3: Texture2D = preload("res://assets/tilesets/v2/forest_v2_act3.png")
const CANOPY_SHADER: Shader = preload("res://shaders/canopy_proximity.gdshader")

@export var sync_perception_texture: bool = true
@export var enable_wind_sway: bool = true
@export_range(0.0, 4.0, 0.1) var wind_strength: float = 1.4
@export_range(0.1, 6.0, 0.1) var wind_speed: float = 1.6
@export var enable_proximity_fade: bool = true
@export_range(16.0, 96.0, 1.0) var fade_radius: float = 36.0
@export_range(0.15, 1.0, 0.05) var min_alpha: float = 0.42

@onready var sprite: Sprite2D = get_node_or_null("Sprite2D") as Sprite2D

static var _shared_wind_materials: Dictionary = {}

var _prop_material: ShaderMaterial = null
var _uses_shared_material: bool = false
var _cached_top_y: float = -75.0
var _cached_player: Node2D = null
var _connected_gs: Node = null


static func _get_shared_wind_material(top_y: float, w_strength: float, w_speed: float, jitter: float) -> ShaderMaterial:
	var key := "%.1f|%.2f|%.2f|%.2f" % [top_y, w_strength, w_speed, jitter]
	if _shared_wind_materials.has(key):
		return _shared_wind_materials[key] as ShaderMaterial
	var mat := ShaderMaterial.new()
	mat.shader = CANOPY_SHADER
	mat.set_shader_parameter("use_local_y", true)
	mat.set_shader_parameter("use_world_phase", true)
	mat.set_shader_parameter("local_top_y", top_y)
	mat.set_shader_parameter("local_anchor_y", 0.0)
	mat.set_shader_parameter("wind_strength", w_strength)
	mat.set_shader_parameter("wind_speed", w_speed)
	mat.set_shader_parameter("distortion_jitter", jitter)
	mat.set_shader_parameter("proximity_fade_enabled", false)
	_shared_wind_materials[key] = mat
	return mat


func _ready() -> void:
	if sprite == null:
		sprite = get_node_or_null("Sprite2D") as Sprite2D

	if Engine.is_editor_hint():
		if sprite != null:
			if sync_perception_texture and sprite.texture == null:
				sprite.texture = TEX_NORMAL
			sprite.material = null
		set_process(false)
		return

	if sprite != null and (enable_wind_sway or enable_proximity_fade):
		var rect := sprite.get_rect()
		_cached_top_y = minf(rect.position.y, -8.0)
		if enable_proximity_fade:
			_uses_shared_material = false
			var phase := fmod(absf(global_position.x * 0.05 + global_position.y * 0.02), TAU)
			_prop_material = ShaderMaterial.new()
			_prop_material.shader = CANOPY_SHADER
			_prop_material.set_shader_parameter("use_local_y", true)
			_prop_material.set_shader_parameter("local_top_y", _cached_top_y)
			_prop_material.set_shader_parameter("local_anchor_y", 0.0)
			_prop_material.set_shader_parameter("phase_offset", phase)
			_prop_material.set_shader_parameter("wind_strength", wind_strength if enable_wind_sway else 0.0)
			_prop_material.set_shader_parameter("wind_speed", wind_speed)
			_prop_material.set_shader_parameter("distortion_jitter", 0.0)
			_prop_material.set_shader_parameter("fade_radius", fade_radius)
			_prop_material.set_shader_parameter("min_alpha", min_alpha)
			_prop_material.set_shader_parameter("proximity_fade_enabled", false)
			sprite.material = _prop_material
		elif enable_wind_sway:
			_uses_shared_material = true
			_prop_material = _get_shared_wind_material(_cached_top_y, wind_strength, wind_speed, 0.0)
			sprite.material = _prop_material

	if not enable_proximity_fade or _prop_material == null:
		set_process(false)

	_connect_game_state()
	_sync_visuals()


func _exit_tree() -> void:
	_disconnect_game_state()


func _process(_delta: float) -> void:
	if Engine.is_editor_hint() or _prop_material == null or not enable_proximity_fade:
		return
	if _cached_player == null or not is_instance_valid(_cached_player):
		var tree := get_tree()
		if tree != null:
			_cached_player = tree.get_first_node_in_group("player") as Node2D
	if _cached_player != null and is_instance_valid(_cached_player):
		var ppos := _cached_player.global_position
		var reach_y := maxf(96.0, fade_radius * 2.2)
		var behind := (
			ppos.y < global_position.y
			and absf(ppos.x - global_position.x) <= fade_radius * 1.35
			and (global_position.y - ppos.y) <= reach_y
		)
		_prop_material.set_shader_parameter("proximity_fade_enabled", behind)
		if behind:
			_prop_material.set_shader_parameter("player_world_pos", ppos)
	else:
		_prop_material.set_shader_parameter("proximity_fade_enabled", false)


func _connect_game_state() -> void:
	var gs := get_node_or_null("/root/GameState")
	if gs == null or _connected_gs == gs:
		return
	_connected_gs = gs
	if gs.has_signal("perception_changed") and not gs.is_connected("perception_changed", _on_perception_changed):
		gs.connect("perception_changed", _on_perception_changed)
	if gs.has_signal("higher_dose_changed") and not gs.is_connected("higher_dose_changed", _on_higher_dose_changed):
		gs.connect("higher_dose_changed", _on_higher_dose_changed)
	if gs.has_signal("variable_changed") and not gs.is_connected("variable_changed", _on_variable_changed):
		gs.connect("variable_changed", _on_variable_changed)


func _disconnect_game_state() -> void:
	if _connected_gs == null or not is_instance_valid(_connected_gs):
		_connected_gs = null
		return
	if _connected_gs.is_connected("perception_changed", _on_perception_changed):
		_connected_gs.disconnect("perception_changed", _on_perception_changed)
	if _connected_gs.is_connected("higher_dose_changed", _on_higher_dose_changed):
		_connected_gs.disconnect("higher_dose_changed", _on_higher_dose_changed)
	if _connected_gs.is_connected("variable_changed", _on_variable_changed):
		_connected_gs.disconnect("variable_changed", _on_variable_changed)
	_connected_gs = null


func _on_perception_changed(_mode: int) -> void:
	_sync_visuals()


func _on_higher_dose_changed(_active: bool) -> void:
	_sync_visuals()


func _on_variable_changed(var_name: String, _value: Variant) -> void:
	if var_name == "Ato":
		_sync_visuals()


func _sync_visuals() -> void:
	if sprite == null or not is_instance_valid(sprite):
		return
	if Engine.is_editor_hint():
		if sync_perception_texture:
			sprite.texture = TEX_NORMAL
		return

	var gs := get_node_or_null("/root/GameState")
	var is_act3: bool = gs != null and gs.has_method("is_unfiltered_act3") and bool(gs.call("is_unfiltered_act3"))
	var is_higher: bool = gs != null and gs.has_method("is_higher_dose") and bool(gs.call("is_higher_dose"))

	if sync_perception_texture:
		if is_act3:
			sprite.texture = TEX_ACT3
		elif is_higher:
			sprite.texture = TEX_DISTORTED
		else:
			sprite.texture = TEX_NORMAL

	if _uses_shared_material:
		if not enable_wind_sway:
			_prop_material = null
			sprite.material = null
		elif is_higher and not is_act3:
			_prop_material = _get_shared_wind_material(_cached_top_y, wind_strength * 1.15, wind_speed * 1.25, 0.7)
			sprite.material = _prop_material
		else:
			_prop_material = _get_shared_wind_material(_cached_top_y, wind_strength, wind_speed, 0.0)
			sprite.material = _prop_material
	elif _prop_material != null:
		if not enable_wind_sway:
			_prop_material.set_shader_parameter("wind_strength", 0.0)
			_prop_material.set_shader_parameter("distortion_jitter", 0.0)
		elif is_higher and not is_act3:
			_prop_material.set_shader_parameter("wind_strength", wind_strength * 1.15)
			_prop_material.set_shader_parameter("wind_speed", wind_speed * 1.25)
			_prop_material.set_shader_parameter("distortion_jitter", 0.7)
		else:
			_prop_material.set_shader_parameter("wind_strength", wind_strength)
			_prop_material.set_shader_parameter("wind_speed", wind_speed)
			_prop_material.set_shader_parameter("distortion_jitter", 0.0)
