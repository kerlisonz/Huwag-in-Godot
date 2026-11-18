extends RefCounted
class_name AtmosphereRig

## Gerenciador atmosférico 2D para Fase 1/2: CanvasModulate calibrado por Ato,
## PointLight2D (sombras nítidas Nearest), LightOccluder2D, névoa pixelada e
## integração direta com VfxLibrary para fontes de luz (velas/fogueiras/postes).

const FOG_SHADER: Shader = preload("res://shaders/fog_drift.gdshader")
const CANOPY_SHADER: Shader = preload("res://shaders/canopy_proximity.gdshader")

const MOOD_PRESETS := {
	"morning": {
		"ambient": Color(0.86, 0.87, 0.92, 1.0),
		"fog_color": Color(0.72, 0.78, 0.86, 1.0),
		"fog_density": 0.14,
	},
	"afternoon": {
		"ambient": Color(0.72, 0.69, 0.74, 1.0),
		"fog_color": Color(0.64, 0.62, 0.68, 1.0),
		"fog_density": 0.22,
	},
	"night": {
		"ambient": Color(0.46, 0.50, 0.64, 1.0),
		"fog_color": Color(0.36, 0.44, 0.58, 1.0),
		"fog_density": 0.30,
	},
	"forest_day": {
		"ambient": Color(0.68, 0.74, 0.72, 1.0),
		"fog_color": Color(0.56, 0.68, 0.64, 1.0),
		"fog_density": 0.32,
	},
	"forest_night": {
		"ambient": Color(0.40, 0.44, 0.56, 1.0),
		"fog_color": Color(0.32, 0.40, 0.50, 1.0),
		"fog_density": 0.40,
	},
	"distorted": {
		"ambient": Color(0.56, 0.50, 0.58, 1.0),
		"fog_color": Color(0.54, 0.28, 0.34, 1.0),
		"fog_density": 0.24,
	},
	"act3_unfiltered": {
		"ambient": Color(0.84, 0.85, 0.87, 1.0),
		"fog_color": Color(0.72, 0.74, 0.76, 1.0),
		"fog_density": 0.0,
	},
}


static func get_mood_spec(mood: String, is_act3: bool = false) -> Dictionary:
	if is_act3:
		return MOOD_PRESETS["act3_unfiltered"]
	return MOOD_PRESETS.get(mood, MOOD_PRESETS["morning"])


static func apply_canvas_modulate(host: Node, mood: String, is_act3: bool = false) -> CanvasModulate:
	if host == null or not is_instance_valid(host):
		return null
	var mod_node := host.get_node_or_null("AtmosphereModulate") as CanvasModulate
	if mod_node == null:
		mod_node = CanvasModulate.new()
		mod_node.name = "AtmosphereModulate"
		host.add_child(mod_node)
	var spec := get_mood_spec(mood, is_act3)
	mod_node.color = spec["ambient"] as Color
	return mod_node


static func create_point_light(pos: Vector2, color: Color, energy: float = 0.85, texture_scale: float = 1.6, enable_shadows: bool = false) -> PointLight2D:
	var light := RetroLevelHelpers.create_point_light(pos, color, energy, texture_scale, 128)
	light.shadow_enabled = enable_shadows
	if enable_shadows:
		light.shadow_filter = Light2D.SHADOW_FILTER_NONE
		light.shadow_color = Color(0.02, 0.02, 0.06, 0.65)
	return light


static func attach_lit_vfx(parent: Node2D, vfx_name: String, local_pos: Vector2, light_color: Color, light_energy: float = 0.85, light_scale: float = 1.25, vfx_scale: float = 0.65, is_act3: bool = false) -> Dictionary:
	var out := {"vfx": null, "light": null}
	if parent == null or not is_instance_valid(parent):
		return out

	# No Ato III não há chamas/manifestações sobrenaturais (preserva invariante narrativa).
	var skip_supernatural := is_act3 and (vfx_name == "santelmo_flame" or vfx_name == "shadow_flames")
	if not skip_supernatural:
		var vfx_col := Color(0.84, 0.85, 0.87, 0.90) if is_act3 else Color.WHITE
		var vfx := VfxLibrary.attach_loop(parent, vfx_name, local_pos, {
			"scale": Vector2(vfx_scale, vfx_scale),
			"modulate": vfx_col,
			"z_index": 2,
		})
		out["vfx"] = vfx

	var l_col := Color(0.88, 0.90, 0.94, 1.0) if is_act3 else light_color
	var light := create_point_light(local_pos + Vector2(0.0, -6.0), l_col, light_energy, light_scale, false)
	light.name = "PointLight_%s" % vfx_name
	parent.add_child(light)
	out["light"] = light
	return out


static func create_fog_overlay(rect_or_size: Variant, mood_or_color: Variant = "forest_night", arg3: Variant = false, is_distorted: bool = false) -> ColorRect:
	var rect := ColorRect.new()
	rect.name = "AtmosphericFogOverlay"
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var rect_pos := Vector2.ZERO
	var rect_size := Vector2(640, 360)
	if typeof(rect_or_size) == TYPE_RECT2:
		var r := rect_or_size as Rect2
		rect_pos = r.position
		rect_size = r.size
	elif typeof(rect_or_size) == TYPE_VECTOR2:
		rect_size = rect_or_size as Vector2
	rect.position = rect_pos
	rect.size = rect_size
	rect.color = Color.WHITE
	rect.z_index = 9

	var is_act3 := false
	var fog_col := Color(0.16, 0.22, 0.24, 1.0)
	var fog_dens := 0.14
	if typeof(mood_or_color) == TYPE_STRING:
		is_act3 = bool(arg3)
		var spec := get_mood_spec(str(mood_or_color), is_act3)
		fog_col = spec["fog_color"] as Color
		fog_dens = 0.0 if is_act3 else float(spec["fog_density"])
	elif typeof(mood_or_color) == TYPE_COLOR:
		fog_col = mood_or_color as Color
		if typeof(arg3) == TYPE_FLOAT or typeof(arg3) == TYPE_INT:
			fog_dens = float(arg3)

	var mat := ShaderMaterial.new()
	mat.shader = FOG_SHADER
	mat.set_shader_parameter("fog_color", fog_col)
	mat.set_shader_parameter("fog_density", 0.0 if is_act3 else fog_dens)
	mat.set_shader_parameter("distortion_mix", 0.75 if (is_distorted and not is_act3) else 0.0)
	mat.set_shader_parameter("pixel_resolution", Vector2(maxf(64.0, rect_size.x * 0.5), maxf(64.0, rect_size.y * 0.5)))
	rect.material = mat
	rect.visible = not is_act3
	return rect


static func create_canopy_material(phase: float = 0.0, enable_fade_or_alpha: Variant = true) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = CANOPY_SHADER
	mat.set_shader_parameter("phase_offset", fmod(absf(phase), TAU))
	var enable_fade := true
	if typeof(enable_fade_or_alpha) == TYPE_BOOL:
		enable_fade = bool(enable_fade_or_alpha)
	elif typeof(enable_fade_or_alpha) == TYPE_FLOAT or typeof(enable_fade_or_alpha) == TYPE_INT:
		mat.set_shader_parameter("min_alpha", clampf(float(enable_fade_or_alpha), 0.15, 1.0))
	mat.set_shader_parameter("proximity_fade_enabled", enable_fade)
	return mat


static func create_rect_occluder(center: Vector2, size: Vector2) -> LightOccluder2D:
	var occ := LightOccluder2D.new()
	occ.position = center
	var poly := OccluderPolygon2D.new()
	var hw := size.x * 0.5
	var hh := size.y * 0.5
	poly.polygon = PackedVector2Array([
		Vector2(-hw, -hh),
		Vector2(hw, -hh),
		Vector2(hw, hh),
		Vector2(-hw, hh),
	])
	occ.occluder = poly
	return occ
