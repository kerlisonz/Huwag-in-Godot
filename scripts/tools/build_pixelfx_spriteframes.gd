extends SceneTree

## Gera os recursos Godot SpriteFrames (.tres) em res://assets/vfx/
## a partir dos spritesheets PNG e do manifesto em res://assets/vfx/vfx_manifest.json.

const MANIFEST_PATH := "res://assets/vfx/vfx_manifest.json"
const OUT_DIR := "res://assets/vfx"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var file := FileAccess.open(MANIFEST_PATH, FileAccess.READ)
	if file == null:
		push_error("Nao foi possivel abrir %s" % MANIFEST_PATH)
		quit(1)
		return

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY or not (parsed as Dictionary).has("effects"):
		push_error("Manifesto VFX invalido em %s" % MANIFEST_PATH)
		quit(1)
		return

	var effects: Dictionary = (parsed as Dictionary)["effects"]
	var count := 0
	for effect_name_v in effects.keys():
		var effect_name: String = str(effect_name_v)
		var info: Dictionary = effects[effect_name]
		var png_path := "%s/%s.png" % [OUT_DIR, effect_name]
		var tex := ResourceLoader.load(png_path) as Texture2D
		if tex == null:
			push_error("Textura ainda nao importada em %s. Execute --import antes." % png_path)
			quit(1)
			return

		var sf := SpriteFrames.new()
		if sf.has_animation("default"):
			sf.remove_animation("default")

		var anim_name: StringName = &"play"
		sf.add_animation(anim_name)
		sf.set_animation_loop(anim_name, bool(info.get("loop", false)))
		sf.set_animation_speed(anim_name, float(info.get("fps", 12)))

		var frame_count: int = int(info.get("frame_count", 1))
		var cols: int = maxi(1, int(info.get("columns", 1)))
		var fsize: Array = info.get("frame_size", [32, 32])
		var cw: int = int(fsize[0])
		var ch: int = int(fsize[1])

		for i in range(frame_count):
			var gx: int = (i % cols) * cw
			var gy: int = int(i / cols) * ch
			var at := AtlasTexture.new()
			at.atlas = tex
			at.region = Rect2(gx, gy, cw, ch)
			at.filter_clip = true
			sf.add_frame(anim_name, at)

		var out_path := "%s/%s_spriteframes.tres" % [OUT_DIR, effect_name]
		var err := ResourceSaver.save(sf, out_path)
		if err != OK:
			push_error("Falha ao salvar %s (err=%d)" % [out_path, err])
			quit(1)
			return
		count += 1
		print("SpriteFrames gerado: %s (%d frames @ %sfps, cell=%dx%d)" % [out_path, frame_count, info.get("fps", 12), cw, ch])

	print("Total de SpriteFrames pixelfx gerados: %d" % count)
	quit(0)
