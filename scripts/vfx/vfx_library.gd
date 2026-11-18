extends RefCounted
class_name VfxLibrary

## Biblioteca nativa para instanciar spritesheets VFX pré-renderizados (assets/vfx/)
## usando AnimatedSprite2D + Nearest Neighbor sem dependências/plugins em runtime.

const VFX_DIR := "res://assets/vfx"

const EFFECTS := {
	"axe_slash_amber": {
		"offset": Vector2(15.5, -11.5),
		"loop": false,
	},
	"axe_slash_crimson": {
		"offset": Vector2(18.5, -11.5),
		"loop": false,
	},
	"claw_swipe_horror": {
		"offset": Vector2(-4.5, 1.5),
		"loop": false,
	},
	"hit_spark": {
		"offset": Vector2(23.0, -6.0),
		"loop": false,
	},
	"blunt_hit": {
		"offset": Vector2(0.5, -9.0),
		"loop": false,
	},
	"impact_dust": {
		"offset": Vector2(-1.5, -7.0),
		"loop": false,
	},
	"water_jet": {
		"offset": Vector2(46.5, 10.0),
		"loop": true,
	},
	"water_splash": {
		"offset": Vector2(-3.0, -17.5),
		"loop": false,
	},
	"water_ripples": {
		"offset": Vector2(0.0, -3.0),
		"loop": true,
	},
	"santelmo_flame": {
		"offset": Vector2(0.0, -21.5),
		"loop": true,
	},
	"shadow_flames": {
		"offset": Vector2(0.0, -39.0),
		"loop": true,
	},
	"grasping_hands": {
		"offset": Vector2(0.0, -30.0),
		"loop": false,
	},
	"campfire_ember": {
		"offset": Vector2(0.5, -34.0),
		"loop": true,
	},
	"candle_flicker": {
		"offset": Vector2(0.0, -24.0),
		"loop": true,
	},
}

static func get_frames(effect_name: String) -> SpriteFrames:
	if not EFFECTS.has(effect_name):
		push_warning("VfxLibrary: efeito desconhecido '%s'" % effect_name)
		return null

	var res_path := "%s/%s_spriteframes.tres" % [VFX_DIR, effect_name]
	if not ResourceLoader.exists(res_path):
		return null
	return ResourceLoader.load(res_path) as SpriteFrames


static func _create_sprite(effect_name: String, opts: Dictionary) -> AnimatedSprite2D:
	var sf := get_frames(effect_name)
	if sf == null:
		return null

	var spec: Dictionary = EFFECTS[effect_name]
	var anim := AnimatedSprite2D.new()
	anim.name = "Vfx_%s" % effect_name
	anim.set_meta(&"pixelfx_id", effect_name)
	anim.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	anim.sprite_frames = sf
	anim.centered = true
	anim.offset = opts.get("offset", spec["offset"]) as Vector2
	anim.rotation = float(opts.get("rotation", 0.0))
	anim.scale = opts.get("scale", Vector2.ONE) as Vector2
	anim.flip_h = bool(opts.get("flip_h", false))
	anim.flip_v = bool(opts.get("flip_v", false))
	anim.modulate = opts.get("modulate", Color.WHITE) as Color
	anim.speed_scale = float(opts.get("speed_scale", 1.0))
	anim.z_index = int(opts.get("z_index", 6))
	return anim


static func spawn_burst(anchor: Node, effect_name: String, world_pos: Vector2, opts: Dictionary = {}) -> AnimatedSprite2D:
	if anchor == null or not anchor.is_inside_tree():
		return null
	var host: Node = opts.get("parent", anchor.get_parent()) as Node
	if host == null or not is_instance_valid(host) or not host.is_inside_tree():
		host = anchor.get_tree().current_scene
	if host == null or not is_instance_valid(host):
		return null

	var anim := _create_sprite(effect_name, opts)
	if anim == null:
		return null

	host.add_child(anim, true)
	if anim is Node2D:
		(anim as Node2D).global_position = world_pos
	anim.play(&"play")

	var duration: float = float(opts.get("duration", 0.0))
	var spec: Dictionary = EFFECTS[effect_name]
	if not bool(spec["loop"]) and duration <= 0.0:
		anim.animation_finished.connect(anim.queue_free, CONNECT_ONE_SHOT)
	elif duration > 0.0:
		var tree := anim.get_tree()
		if tree != null:
			tree.create_timer(duration).timeout.connect(anim.queue_free, CONNECT_ONE_SHOT)
	return anim


static func attach_loop(parent: Node2D, effect_name: String, local_pos: Vector2 = Vector2.ZERO, opts: Dictionary = {}) -> AnimatedSprite2D:
	if parent == null or not is_instance_valid(parent):
		return null
	var anim := _create_sprite(effect_name, opts)
	if anim == null:
		return null
	anim.position = local_pos
	parent.add_child(anim)
	anim.play(&"play")
	return anim
