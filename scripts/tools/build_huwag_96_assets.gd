@tool
extends SceneTree

## Standalone generator for Huwag (protagonist) 96x96 pixel-art spritesheets,
## separate weapon VFX strips, atlas metadata JSONs, and animated transparent GIFs.
## Covers 4 variants x 8 directions x 6 animations:
##   variants: casual_day, casual_dark, bfp_day, bfp_dark
##   anims:    idle (6f), walk (8f), run (8f), attack (6f), hurt (4f), defeat (6f)

const PAC := preload("res://scripts/tools/pixel_rig/pixel_art_canvas.gd")
const GIF := preload("res://scripts/tools/pixel_rig/gif89a_encoder.gd")

const CELL_W: int = 96
const CELL_H: int = 96
const FOOT_ANCHOR := Vector2(48.0, 84.0)
const DEPTH_Y: float = 0.34
const AXE_LEN_2D: float = 22.0

const OUT_BASE_RES: String = "res://assets/characters/huwag"
const ARTIFACT_PREVIEW_DIR: String = "C:/Users/SnyX/.gemini/antigravity/brain/41e1f3b5-4735-42d2-bd7e-9b58f3903223"

const VARIANTS: Array[String] = ["casual_day", "casual_dark", "bfp_day", "bfp_dark"]
const DIRECTIONS: Array[String] = [
	"down", "down_right", "right", "up_right", "up", "up_left", "left", "down_left"
]

const ANIM_SPECS: Dictionary = {
	"idle": {"frames": 6, "fps": 8, "loop": true, "has_vfx": false, "impact_frame": -1},
	"walk": {"frames": 8, "fps": 11, "loop": true, "has_vfx": false, "impact_frame": -1},
	"run": {"frames": 8, "fps": 14, "loop": true, "has_vfx": false, "impact_frame": -1},
	"attack": {"frames": 6, "fps": 14, "loop": false, "has_vfx": true, "impact_frame": 2},
	"hurt": {"frames": 4, "fps": 12, "loop": false, "has_vfx": false, "impact_frame": -1},
	"defeat": {"frames": 6, "fps": 10, "loop": false, "has_vfx": false, "impact_frame": -1},
}


func _init() -> void:
	var t0: int = Time.get_ticks_msec()
	var total_pngs: int = 0
	var total_gifs: int = 0
	var preview_strips: Dictionary = {}

	for variant_id in VARIANTS:
		var pal: Dictionary = _make_palette(variant_id)
		var var_dir: String = "%s/%s" % [OUT_BASE_RES, variant_id]
		var vfx_dir: String = "%s/vfx" % var_dir
		var gif_dir: String = "%s/gifs" % var_dir
		_ensure_dir(var_dir)
		_ensure_dir(vfx_dir)
		_ensure_dir(gif_dir)

		var atlas_anims: Dictionary = {}

		for anim_name in ["idle", "walk", "run", "attack", "hurt", "defeat"]:
			var spec: Dictionary = ANIM_SPECS[anim_name]
			var n_frames: int = int(spec["frames"])
			var fps: int = int(spec["fps"])
			var is_loop: bool = bool(spec["loop"])
			var has_vfx: bool = bool(spec["has_vfx"])
			var impact_frame: int = int(spec["impact_frame"])

			for dir_name in DIRECTIONS:
				var rendered: Dictionary = _render_strip(variant_id, pal, anim_name, dir_name, n_frames)
				var body_strip: Image = rendered["body_strip"]
				var vfx_strip: Image = rendered["vfx_strip"]
				var body_frames: Array[Image] = rendered["body_frames"]
				var vfx_frames: Array[Image] = rendered["vfx_frames"]

				var body_file: String = "huwag_%s_%s.png" % [anim_name, dir_name]
				var body_res: String = "%s/%s" % [var_dir, body_file]
				var err_b: Error = body_strip.save_png(ProjectSettings.globalize_path(body_res))
				if err_b != OK:
					push_error("Failed to save %s: %d" % [body_res, err_b])
					quit(1)
					return
				total_pngs += 1

				var vfx_rel: String = ""
				if has_vfx:
					vfx_rel = "vfx/huwag_vfx_%s_%s.png" % [anim_name, dir_name]
					var vfx_res: String = "%s/%s" % [var_dir, vfx_rel]
					var err_v: Error = vfx_strip.save_png(ProjectSettings.globalize_path(vfx_res))
					if err_v != OK:
						push_error("Failed to save %s: %d" % [vfx_res, err_v])
						quit(1)
						return
					total_pngs += 1

				var gif_frames: Array[Image] = []
				var delays_cs: Array[int] = []
				var base_cs: int = maxi(4, int(round(100.0 / float(fps))))
				for fi in range(n_frames):
					var gf: Image = body_frames[fi].duplicate()
					if has_vfx:
						PAC.blit_alpha(gf, vfx_frames[fi])
					gif_frames.append(gf)
					var d_cs: int = base_cs
					if anim_name == "attack" and fi == impact_frame:
						d_cs = base_cs + 3
					elif anim_name == "defeat" and fi == n_frames - 1:
						d_cs = 60
					delays_cs.append(d_cs)

				var gif_rel: String = "gifs/huwag_%s_%s.gif" % [anim_name, dir_name]
				var gif_abs: String = ProjectSettings.globalize_path("%s/%s" % [var_dir, gif_rel])
				var err_g: Error = GIF.save_animated_gif(gif_abs, gif_frames, delays_cs, 2)
				if err_g != OK:
					push_error("Failed to save GIF %s: %d" % [gif_abs, err_g])
					quit(1)
					return
				total_gifs += 1

				var anim_key: String = "%s_%s" % [anim_name, dir_name]
				var meta_entry: Dictionary = {
					"animation": anim_name,
					"direction": dir_name,
					"file": body_file,
					"gif_file": gif_rel,
					"frames": n_frames,
					"fps": fps,
					"loop": is_loop,
				}
				if has_vfx:
					meta_entry["vfx_file"] = vfx_rel
					meta_entry["impact_frame"] = impact_frame
					meta_entry["phases"] = {
						"anticipation": [0, 1],
						"impact_follow": [2, 3],
						"recovery": [4, 5],
					}
				elif anim_name == "defeat":
					meta_entry["phases"] = {
						"stagger": [0, 1],
						"collapse": [2, 3],
						"grounded": [4, 5],
					}
				atlas_anims[anim_key] = meta_entry

				if dir_name in ["down", "right", "up", "down_left"]:
					var pkey: String = "%s|%s|%s" % [variant_id, anim_name, dir_name]
					preview_strips[pkey] = {
						"body_frames": body_frames,
						"vfx_frames": vfx_frames,
					}

		var atlas_dict: Dictionary = {
			"character": "huwag",
			"variant": variant_id,
			"frame_size": [CELL_W, CELL_H],
			"foot_anchor": [int(FOOT_ANCHOR.x), int(FOOT_ANCHOR.y)],
			"directions": DIRECTIONS,
			"gif_scale": 2,
			"weapon": {
				"idle_walk_run_equipped": false,
				"attack_weapon": "firefighter_axe",
				"handle_length_px": AXE_LEN_2D,
			},
			"animations": atlas_anims,
		}
		var atlas_abs: String = ProjectSettings.globalize_path("%s/huwag_atlas.json" % var_dir)
		var fa: FileAccess = FileAccess.open(atlas_abs, FileAccess.WRITE)
		if fa == null:
			push_error("Cannot open atlas json: %s" % atlas_abs)
			quit(1)
			return
		fa.store_string(JSON.stringify(atlas_dict, "\t"))
		fa.close()

	_write_inspection_previews(preview_strips)
	var elapsed: int = Time.get_ticks_msec() - t0
	print("HUWAG_BUILD_OK pngs=%d gifs=%d variants=%d ms=%d" % [total_pngs, total_gifs, VARIANTS.size(), elapsed])
	quit(0)


func _ensure_dir(res_path: String) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(res_path))


func _make_palette(variant_id: String) -> Dictionary:
	var is_dark: bool = variant_id.ends_with("_dark")
	var is_bfp: bool = variant_id.begins_with("bfp_")
	if not is_dark:
		var base: Dictionary = {
			"is_dark": false,
			"is_bfp": is_bfp,
			"ink": Color.html("#120C16"),
			"hair_line": Color.html("#3E3228"),
			"shadow_in": Color(0.06, 0.04, 0.10, 0.44),
			"shadow_out": Color(0.06, 0.04, 0.10, 0.20),
			"skin": [Color.html("#5E3E29"), Color.html("#7E583D"), Color.html("#A67852"), Color.html("#C7966D")],
			"olheira": Color.html("#341E18"),
			"eye_white": Color.html("#F7F4ED"),
			"eye_pupil": Color.html("#120C16"),
			"teeth": Color.html("#F2EFEA"),
			"mouth_line": Color.html("#291616"),
			"hair_root": Color.html("#151319"),
			"hair_blond": [Color.html("#9E8E5A"), Color.html("#C7BA7B"), Color.html("#E5DB9F"), Color.html("#F5EBB7")],
			"shirt": [Color.html("#0D0D12"), Color.html("#14151D"), Color.html("#1D1F2A"), Color.html("#282B3A")],
			"cord": Color.html("#9E9588"),
			"cord_sh": Color.html("#544E46"),
			"axe_wood": [Color.html("#422A1E"), Color.html("#62402E"), Color.html("#84573E"), Color.html("#A37054")],
			"axe_red": [Color.html("#731619"), Color.html("#A82428"), Color.html("#D63B38"), Color.html("#F05D54")],
			"axe_steel": [Color.html("#546073"), Color.html("#7F8EA6"), Color.html("#B0BFD4"), Color.html("#E3ECF7")],
			"vfx": [Color.html("#7D1F18"), Color.html("#CC4726"), Color.html("#F7B53E"), Color.html("#FFF8D9")],
		}
		if not is_bfp:
			# Rich cool slate-charcoal folds so worn black hoodie clearly pops from black tee and ink line
			base["jacket"] = [Color.html("#1C1E28"), Color.html("#2C303F"), Color.html("#43485E"), Color.html("#616885")]
			base["jacket_lapel"] = [Color.html("#252836"), Color.html("#383D50"), Color.html("#525973"), Color.html("#727B9C")]
			base["pants"] = [Color.html("#171B26"), Color.html("#242A3B"), Color.html("#353E54"), Color.html("#4A5573")]
			base["boots"] = [Color.html("#15141B"), Color.html("#262633"), Color.html("#3D3D4E"), Color.html("#56566B")]
		else:
			base["jacket"] = [Color.html("#131928"), Color.html("#1F2942"), Color.html("#324266"), Color.html("#485F91")]
			base["jacket_lapel"] = [Color.html("#192136"), Color.html("#293757"), Color.html("#3F5480"), Color.html("#5B74AD")]
			base["pants"] = [Color.html("#101522"), Color.html("#1A2338"), Color.html("#293654"), Color.html("#3B4D75")]
			base["boots"] = [Color.html("#121218"), Color.html("#21222C"), Color.html("#363846"), Color.html("#4F5264")]
			base["stripe"] = [Color.html("#C25C15"), Color.html("#EB9628"), Color.html("#FAD05A"), Color.html("#FFF3AE")]
		return base
	else:
		var dark: Dictionary = {
			"is_dark": true,
			"is_bfp": is_bfp,
			"ink": Color.html("#0B0A0E"),
			"hair_line": Color.html("#2B292B"),
			"shadow_in": Color(0.03, 0.03, 0.05, 0.48),
			"shadow_out": Color(0.03, 0.03, 0.05, 0.22),
			"skin": [Color.html("#403A37"), Color.html("#5E5651"), Color.html("#827971"), Color.html("#A69C91")],
			"olheira": Color.html("#1F1B1D"),
			"eye_white": Color.html("#EAE8E5"),
			"eye_pupil": Color.html("#0B0A0E"),
			"teeth": Color.html("#E5E3E0"),
			"mouth_line": Color.html("#1A1719"),
			"hair_root": Color.html("#0F0E12"),
			"hair_blond": [Color.html("#727067"), Color.html("#9B988D"), Color.html("#C2C0B2"), Color.html("#E3E2D7")],
			"shirt": [Color.html("#0A0A0E"), Color.html("#131319"), Color.html("#1C1D25"), Color.html("#272832")],
			"cord": Color.html("#78777D"),
			"cord_sh": Color.html("#424146"),
			"axe_wood": [Color.html("#262426"), Color.html("#3E3C3F"), Color.html("#575559"), Color.html("#706D73")],
			"axe_red": [Color.html("#381F22"), Color.html("#5C2D32"), Color.html("#823D42"), Color.html("#A65459")],
			"axe_steel": [Color.html("#484C54"), Color.html("#727782"), Color.html("#9FA6B2"), Color.html("#D5DAE6")],
			"vfx": [Color.html("#3A3C44"), Color.html("#7C818E"), Color.html("#CACFD9"), Color.html("#F7F8FC")],
		}
		if not is_bfp:
			dark["jacket"] = [Color.html("#15161C"), Color.html("#252730"), Color.html("#3A3D4A"), Color.html("#575C6E")]
			dark["jacket_lapel"] = [Color.html("#1E2028"), Color.html("#30333E"), Color.html("#4A4E5E"), Color.html("#686E82")]
			dark["pants"] = [Color.html("#131419"), Color.html("#212229"), Color.html("#32353E"), Color.html("#464A57")]
			dark["boots"] = [Color.html("#0F0F13"), Color.html("#1E1F25"), Color.html("#31333C"), Color.html("#474A57")]
		else:
			dark["jacket"] = [Color.html("#11131B"), Color.html("#1E222E"), Color.html("#303647"), Color.html("#454E66")]
			dark["jacket_lapel"] = [Color.html("#171A24"), Color.html("#262C3B"), Color.html("#3B4459"), Color.html("#54607D")]
			dark["pants"] = [Color.html("#101117"), Color.html("#1D1F28"), Color.html("#2B2F3B"), Color.html("#3F4556")]
			dark["boots"] = [Color.html("#0E0E12"), Color.html("#1C1D24"), Color.html("#30323B"), Color.html("#464954")]
			dark["stripe"] = [Color.html("#59564C"), Color.html("#827E71"), Color.html("#ADA898"), Color.html("#D6D2C4")]
		return dark


func _dir_vec(dir_name: String) -> Vector2:
	match dir_name:
		"down":
			return Vector2(0.0, 1.0)
		"down_right":
			return Vector2(1.0, 1.0).normalized()
		"right":
			return Vector2(1.0, 0.0)
		"up_right":
			return Vector2(1.0, -1.0).normalized()
		"up":
			return Vector2(0.0, -1.0)
		"up_left":
			return Vector2(-1.0, -1.0).normalized()
		"left":
			return Vector2(-1.0, 0.0)
		"down_left":
			return Vector2(-1.0, 1.0).normalized()
	return Vector2(0.0, 1.0)


func _render_strip(_variant_id: String, pal: Dictionary, anim_name: String, dir_name: String, n_frames: int) -> Dictionary:
	var body_strip := Image.create(CELL_W * n_frames, CELL_H, false, Image.FORMAT_RGBA8)
	body_strip.fill(Color(0, 0, 0, 0))
	var vfx_strip := Image.create(CELL_W * n_frames, CELL_H, false, Image.FORMAT_RGBA8)
	vfx_strip.fill(Color(0, 0, 0, 0))

	var body_frames: Array[Image] = []
	var vfx_frames: Array[Image] = []

	var impact_axe_state: Dictionary = {}
	if anim_name == "attack":
		var pose_wind: Dictionary = _build_pose("attack", 1, n_frames, dir_name)
		var pose_hit: Dictionary = _build_pose("attack", 2, n_frames, dir_name)
		var pose_follow: Dictionary = _build_pose("attack", 3, n_frames, dir_name)
		impact_axe_state = {
			"windup": _project_pose_axe(pose_wind, dir_name),
			"impact": _project_pose_axe(pose_hit, dir_name),
			"follow": _project_pose_axe(pose_follow, dir_name),
		}

	for fi in range(n_frames):
		var pose: Dictionary = _build_pose(anim_name, fi, n_frames, dir_name)
		var cell_body: Image = PAC.create_cell()
		var cell_vfx: Image = PAC.create_cell()

		_draw_character_cell(cell_body, cell_vfx, pal, pose, anim_name, fi, dir_name, impact_axe_state)

		body_strip.blit_rect(cell_body, Rect2i(0, 0, CELL_W, CELL_H), Vector2i(fi * CELL_W, 0))
		vfx_strip.blit_rect(cell_vfx, Rect2i(0, 0, CELL_W, CELL_H), Vector2i(fi * CELL_W, 0))
		body_frames.append(cell_body)
		vfx_frames.append(cell_vfx)

	return {
		"body_strip": body_strip,
		"vfx_strip": vfx_strip,
		"body_frames": body_frames,
		"vfx_frames": vfx_frames,
	}


## Evaluates ~62px tall stylized action skeleton with relaxed wider stance and visible forearm clearance.
func _build_pose(anim: String, fi: int, n_frames: int, _dir_name: String) -> Dictionary:
	var p: Dictionary = {
		"root_r": 0.0,
		"root_f": 0.0,
		"pelvis_h": 21.0,
		"torso_lean_f": 0.5,
		"torso_lean_r": 0.0,
		"torso_twist": 0.0,
		"head_tilt_r": 0.7,
		"head_nod_f": 0.4,
		"head_lag_f": 0.0,
		"chest_breathe": 0.0,
		"flap_flare": 0.5,
		"flap_lag_f": 0.0,
		"shadow_rx": 12.0,
		"shadow_ry": 4.6,
		"expression": "grin",
		# Confident wide shoulder-width stance (foot +/-4.3, arms held clear off torso)
		"foot_L": Vector3(-4.3, 0.8, 0.0),
		"foot_R": Vector3(4.3, -0.6, 0.0),
		"knee_L": Vector3(-4.5, 1.6, 11.2),
		"knee_R": Vector3(4.5, 0.4, 11.2),
		"sh_L_off": Vector3(-8.0, 0.0, 36.2),
		"sh_R_off": Vector3(8.0, 0.0, 36.2),
		"el_L": Vector3(-10.4, 0.2, 27.6),
		"el_R": Vector3(10.4, 0.0, 27.6),
		"ha_L": Vector3(-9.4, 2.2, 19.8),
		"ha_R": Vector3(9.4, 2.0, 19.8),
		"has_axe": false,
		"axe_fi": 0,
		"ground_collapse": false,
		"collapse_t": 0.0,
	}

	if anim == "idle":
		var phase: float = (float(fi) / float(n_frames)) * TAU
		var br: float = sin(phase)
		var sway: float = sin(phase * 0.5)
		p["chest_breathe"] = (br * 0.5 + 0.5) * 1.4
		p["pelvis_h"] = 21.0 - (br * 0.5 + 0.5) * 0.3
		p["head_tilt_r"] = 0.7 + sin(phase - 0.5) * 0.45
		p["torso_lean_r"] = sway * 0.45
		p["flap_flare"] = 0.5 + (br * 0.5 + 0.5) * 0.7
		p["el_L"] = Vector3(-10.4 - br * 0.45, 0.3 + br * 0.3, 27.6 + br * 0.5)
		p["el_R"] = Vector3(10.4 + br * 0.45, 0.1 + br * 0.3, 27.6 + br * 0.5)
		p["ha_L"] = Vector3(-9.2 - sin(phase - 0.7) * 0.55, 2.4 + br * 0.4, 19.6 + sin(phase - 0.6) * 0.6)
		p["ha_R"] = Vector3(9.2 + sin(phase - 0.7) * 0.55, 2.1 + br * 0.4, 19.6 + sin(phase - 0.6) * 0.6)
		p["head_lag_f"] = -cos(phase) * 0.45
		p["shadow_rx"] = 12.0 + br * 0.4

	elif anim == "walk":
		var phase: float = (float(fi) / float(n_frames)) * TAU
		var s: float = sin(phase)
		var c: float = cos(phase)
		var bob: float = absf(s) * 1.5 - 0.9
		p["pelvis_h"] = 20.8 + bob
		p["torso_lean_f"] = 1.8 + absf(c) * 0.5
		p["torso_twist"] = -c * 0.18
		p["head_tilt_r"] = 0.5 + s * 0.45
		p["head_lag_f"] = -0.8 - c * 0.35
		p["flap_flare"] = 1.0 + absf(s) * 0.9
		p["flap_lag_f"] = -1.3
		var lf_fwd: float = c * 7.2
		var rf_fwd: float = -c * 7.2
		var lf_lift: float = maxf(0.0, s) * 4.2
		var rf_lift: float = maxf(0.0, -s) * 4.2
		p["foot_L"] = Vector3(-4.2, lf_fwd, lf_lift)
		p["foot_R"] = Vector3(4.2, rf_fwd, rf_lift)
		p["knee_L"] = Vector3(-4.4, lf_fwd * 0.58 + 2.0, 11.0 + lf_lift * 0.55)
		p["knee_R"] = Vector3(4.4, rf_fwd * 0.58 + 2.0, 11.0 + rf_lift * 0.55)
		p["el_L"] = Vector3(-10.2, -c * 3.8, 27.8 + bob * 0.6)
		p["el_R"] = Vector3(10.2, c * 3.8, 27.8 + bob * 0.6)
		p["ha_L"] = Vector3(-9.2, -c * 7.2 + 1.6, 20.6 + absf(c) * 1.6 + bob * 0.5)
		p["ha_R"] = Vector3(9.2, c * 7.2 + 1.6, 20.6 + absf(c) * 1.6 + bob * 0.5)
		p["shadow_rx"] = 11.8 + absf(c) * 2.0

	elif anim == "run":
		var phase: float = (float(fi) / float(n_frames)) * TAU
		var s: float = sin(phase)
		var c: float = cos(phase)
		var bob: float = absf(s) * 2.4 - 1.6
		p["pelvis_h"] = 20.0 + bob
		p["torso_lean_f"] = 5.2 + absf(c) * 0.9
		p["torso_twist"] = -c * 0.30
		p["head_tilt_r"] = 0.4 + s * 0.5
		p["head_nod_f"] = 1.8
		p["head_lag_f"] = -2.0 - absf(s) * 0.8
		p["flap_flare"] = 3.0 + absf(s) * 1.8
		p["flap_lag_f"] = -3.8
		var lf_fwd: float = c * 10.6
		var rf_fwd: float = -c * 10.6
		var lf_lift: float = maxf(0.0, s) * 7.2
		var rf_lift: float = maxf(0.0, -s) * 7.2
		p["foot_L"] = Vector3(-4.2, lf_fwd, lf_lift)
		p["foot_R"] = Vector3(4.2, rf_fwd, rf_lift)
		p["knee_L"] = Vector3(-4.4, lf_fwd * 0.55 + 3.8, 10.6 + lf_lift * 0.65)
		p["knee_R"] = Vector3(4.4, rf_fwd * 0.55 + 3.8, 10.6 + rf_lift * 0.65)
		p["el_L"] = Vector3(-10.2, -c * 5.2 - 1.8, 27.2 + bob * 0.5)
		p["el_R"] = Vector3(10.2, c * 5.2 - 1.8, 27.2 + bob * 0.5)
		p["ha_L"] = Vector3(-8.2, -c * 7.4 + 4.8, 26.8 - c * 1.8 + bob * 0.5)
		p["ha_R"] = Vector3(8.2, c * 7.4 + 4.8, 26.8 + c * 1.8 + bob * 0.5)
		p["shadow_rx"] = 12.2 + absf(c) * 2.5

	elif anim == "attack":
		p["has_axe"] = true
		p["axe_fi"] = fi
		match fi:
			0:
				# Anticipation 1: planting back foot, coiling torso & lifting axe high over rear shoulder
				p["pelvis_h"] = 19.6
				p["torso_lean_f"] = -1.2
				p["torso_twist"] = 0.44
				p["root_f"] = -1.6
				p["flap_flare"] = 1.4
				p["flap_lag_f"] = 0.8
				p["foot_L"] = Vector3(-4.8, 3.2, 0.0)
				p["foot_R"] = Vector3(4.8, -4.0, 0.0)
				p["knee_L"] = Vector3(-5.0, 4.4, 10.6)
				p["knee_R"] = Vector3(4.8, -2.2, 10.6)
				p["el_R"] = Vector3(11.2, -3.2, 35.8)
				p["ha_R"] = Vector3(8.4, -2.6, 44.6)
				p["el_L"] = Vector3(2.8, 3.4, 33.4)
				p["ha_L"] = Vector3(6.0, -0.6, 40.2)
			1:
				# Anticipation 2: peak deep coil before cleave
				p["pelvis_h"] = 19.0
				p["torso_lean_f"] = -2.4
				p["torso_twist"] = 0.58
				p["root_f"] = -2.6
				p["flap_flare"] = 2.0
				p["flap_lag_f"] = 1.8
				p["head_lag_f"] = 0.9
				p["foot_L"] = Vector3(-5.2, 3.8, 0.0)
				p["foot_R"] = Vector3(5.0, -4.8, 0.0)
				p["knee_L"] = Vector3(-5.2, 5.2, 10.2)
				p["knee_R"] = Vector3(5.0, -2.8, 10.2)
				p["el_R"] = Vector3(11.8, -5.0, 38.0)
				p["ha_R"] = Vector3(8.8, -4.8, 46.8)
				p["el_L"] = Vector3(2.2, 2.8, 35.0)
				p["ha_L"] = Vector3(6.2, -2.6, 41.8)
			2:
				# IMPACT FRAME (impact_frame = 2): heavy lunge forward, hoodie lapels flare open!
				p["pelvis_h"] = 18.0
				p["torso_lean_f"] = 6.0
				p["torso_twist"] = -0.52
				p["root_f"] = 5.2
				p["flap_flare"] = 6.0
				p["flap_lag_f"] = -4.8
				p["head_lag_f"] = -2.2
				p["head_nod_f"] = 1.6
				p["foot_L"] = Vector3(-5.0, 7.2, 0.0)
				p["foot_R"] = Vector3(4.8, -7.2, 0.0)
				p["knee_L"] = Vector3(-5.0, 9.8, 9.6)
				p["knee_R"] = Vector3(4.8, -4.6, 9.6)
				p["el_R"] = Vector3(-2.0, 9.0, 29.8)
				p["ha_R"] = Vector3(-5.5, 13.8, 28.0)
				p["el_L"] = Vector3(-9.2, 6.2, 28.0)
				p["ha_L"] = Vector3(-4.8, 11.2, 27.2)
			3:
				# Follow-through: swing finishes across opposite waist with settling cloth & sparks
				p["pelvis_h"] = 18.8
				p["torso_lean_f"] = 4.6
				p["torso_twist"] = -0.62
				p["root_f"] = 4.6
				p["flap_flare"] = 4.2
				p["flap_lag_f"] = -3.2
				p["head_lag_f"] = -1.4
				p["foot_L"] = Vector3(-4.8, 6.4, 0.0)
				p["foot_R"] = Vector3(4.6, -6.4, 0.0)
				p["knee_L"] = Vector3(-4.8, 8.6, 10.0)
				p["knee_R"] = Vector3(4.6, -4.0, 10.0)
				p["el_R"] = Vector3(-7.0, 7.2, 27.0)
				p["ha_R"] = Vector3(-9.8, 10.4, 24.0)
				p["el_L"] = Vector3(-11.0, 4.0, 26.8)
				p["ha_L"] = Vector3(-8.2, 8.2, 24.4)
			4:
				# Recovery 1: rising upright, drawing axe cleanly inward toward ready guard
				p["pelvis_h"] = 20.0
				p["torso_lean_f"] = 2.0
				p["torso_twist"] = -0.25
				p["root_f"] = 2.2
				p["flap_flare"] = 1.6
				p["flap_lag_f"] = -1.0
				p["foot_L"] = Vector3(-4.6, 3.8, 0.0)
				p["foot_R"] = Vector3(4.6, -3.6, 0.0)
				p["knee_L"] = Vector3(-4.6, 5.2, 10.8)
				p["knee_R"] = Vector3(4.6, -2.0, 10.8)
				p["el_R"] = Vector3(4.8, 4.6, 26.8)
				p["ha_R"] = Vector3(-0.6, 8.4, 25.0)
				p["el_L"] = Vector3(-9.2, 3.2, 26.8)
				p["ha_L"] = Vector3(-4.2, 7.0, 24.8)
			5:
				# Recovery 2: clean diagonal two-hand ready guard
				p["pelvis_h"] = 20.8
				p["torso_lean_f"] = 1.0
				p["torso_twist"] = -0.06
				p["root_f"] = 0.6
				p["flap_flare"] = 0.8
				p["foot_L"] = Vector3(-4.4, 1.4, 0.0)
				p["foot_R"] = Vector3(4.4, -1.2, 0.0)
				p["knee_L"] = Vector3(-4.5, 2.2, 11.0)
				p["knee_R"] = Vector3(4.5, -0.4, 11.0)
				p["el_R"] = Vector3(8.5, 2.2, 27.2)
				p["ha_R"] = Vector3(3.6, 6.2, 24.6)
				p["el_L"] = Vector3(-9.2, 1.8, 27.2)
				p["ha_L"] = Vector3(-1.4, 5.4, 24.2)
		p["shadow_rx"] = 13.0 + (2.4 if fi in [2, 3] else 0.0)

	elif anim == "hurt":
		p["expression"] = "pained"
		match fi:
			0:
				p["pelvis_h"] = 19.8
				p["torso_lean_f"] = -2.6
				p["head_nod_f"] = -2.6
				p["head_tilt_r"] = -1.6
				p["root_f"] = -1.4
				p["flap_flare"] = 2.4
				p["flap_lag_f"] = 2.4
				p["foot_L"] = Vector3(-4.6, 2.0, 0.0)
				p["foot_R"] = Vector3(4.6, -2.0, 0.0)
				p["knee_L"] = Vector3(-4.6, 3.2, 10.6)
				p["knee_R"] = Vector3(4.6, -0.6, 10.6)
				p["el_L"] = Vector3(-10.8, -1.0, 28.8)
				p["el_R"] = Vector3(11.0, -0.8, 28.8)
				p["ha_L"] = Vector3(-8.0, 4.0, 28.4)
				p["ha_R"] = Vector3(8.2, 3.8, 27.8)
			1:
				p["pelvis_h"] = 19.0
				p["torso_lean_f"] = -4.2
				p["head_nod_f"] = -3.4
				p["head_tilt_r"] = -2.4
				p["root_f"] = -3.0
				p["flap_flare"] = 3.4
				p["flap_lag_f"] = 3.4
				p["head_lag_f"] = 1.6
				p["foot_L"] = Vector3(-4.8, 2.5, 0.0)
				p["foot_R"] = Vector3(4.8, -3.0, 0.0)
				p["knee_L"] = Vector3(-4.8, 3.8, 10.2)
				p["knee_R"] = Vector3(4.8, -1.2, 10.2)
				p["el_L"] = Vector3(-11.4, -1.8, 30.2)
				p["el_R"] = Vector3(11.6, -1.6, 29.8)
				p["ha_L"] = Vector3(-8.6, 4.6, 29.8)
				p["ha_R"] = Vector3(8.8, 4.2, 29.2)
			2:
				p["pelvis_h"] = 19.8
				p["torso_lean_f"] = -1.4
				p["head_nod_f"] = -0.8
				p["head_tilt_r"] = -0.6
				p["root_f"] = -1.5
				p["flap_flare"] = 1.6
				p["foot_L"] = Vector3(-4.4, 1.5, 0.0)
				p["foot_R"] = Vector3(4.4, -1.6, 0.0)
				p["knee_L"] = Vector3(-4.4, 2.6, 10.7)
				p["knee_R"] = Vector3(4.4, -0.4, 10.7)
				p["el_L"] = Vector3(-10.6, 0.6, 27.8)
				p["el_R"] = Vector3(10.6, 0.5, 27.8)
				p["ha_L"] = Vector3(-8.8, 3.2, 22.8)
				p["ha_R"] = Vector3(8.8, 3.0, 22.6)
			3:
				p["expression"] = "grin"
				p["pelvis_h"] = 20.8
				p["torso_lean_f"] = 0.2
				p["root_f"] = -0.4
				p["foot_L"] = Vector3(-4.3, 0.9, 0.0)
				p["foot_R"] = Vector3(4.3, -0.8, 0.0)
				p["knee_L"] = Vector3(-4.4, 1.8, 11.1)
				p["knee_R"] = Vector3(4.4, 0.2, 11.1)
				p["el_L"] = Vector3(-10.4, 0.4, 27.6)
				p["el_R"] = Vector3(10.4, 0.2, 27.6)
				p["ha_L"] = Vector3(-9.2, 2.2, 20.2)
				p["ha_R"] = Vector3(9.2, 2.0, 20.2)

	elif anim == "defeat":
		p["expression"] = "pained" if fi <= 2 else "closed"
		if fi == 0:
			p["pelvis_h"] = 17.0
			p["torso_lean_f"] = 3.6
			p["head_nod_f"] = 2.8
			p["head_tilt_r"] = 1.8
			p["flap_flare"] = 1.8
			p["foot_L"] = Vector3(-5.0, 1.2, 0.0)
			p["foot_R"] = Vector3(5.0, -1.2, 0.0)
			p["knee_L"] = Vector3(-5.2, 5.4, 8.8)
			p["knee_R"] = Vector3(5.2, 3.8, 8.8)
			p["el_L"] = Vector3(-10.2, 2.2, 24.0)
			p["el_R"] = Vector3(10.2, 1.8, 24.0)
			p["ha_L"] = Vector3(-8.8, 4.8, 16.0)
			p["ha_R"] = Vector3(8.8, 4.4, 16.0)
		elif fi == 1:
			p["pelvis_h"] = 13.0
			p["torso_lean_f"] = 6.2
			p["torso_lean_r"] = 2.8
			p["head_nod_f"] = 4.2
			p["flap_flare"] = 2.4
			p["foot_L"] = Vector3(-4.8, 3.0, 0.0)
			p["foot_R"] = Vector3(4.6, -5.2, 0.0)
			p["knee_L"] = Vector3(-4.8, 7.0, 8.2)
			p["knee_R"] = Vector3(4.6, -0.8, 3.8)
			p["el_L"] = Vector3(-9.2, 6.2, 18.2)
			p["el_R"] = Vector3(9.4, 5.2, 18.4)
			p["ha_L"] = Vector3(-6.4, 9.4, 10.2)
			p["ha_R"] = Vector3(7.4, 8.6, 9.4)
		else:
			p["ground_collapse"] = true
			p["collapse_t"] = float(fi - 2) / 3.0

	return p


func _project_skeleton(pose: Dictionary, dir_name: String) -> Dictionary:
	var f: Vector2 = _dir_vec(dir_name)
	var r: Vector2 = Vector2(-f.y, f.x)
	var twist: float = float(pose["torso_twist"])
	var f_upper: Vector2 = f.rotated(twist)
	var r_upper: Vector2 = Vector2(-f_upper.y, f_upper.x)

	if bool(pose["ground_collapse"]):
		return _project_defeat_collapse(pose, f, r)

	var rf: float = float(pose["root_f"])
	var rr: float = float(pose["root_r"])
	var pelvis_h: float = float(pose["pelvis_h"])
	var breathe: float = float(pose["chest_breathe"])
	var torso_lf: float = float(pose["torso_lean_f"])
	var torso_lr: float = float(pose["torso_lean_r"])

	var proj := func(sr: float, sf: float, uh: float, use_upper: bool) -> Dictionary:
		var fv: Vector2 = f_upper if use_upper else f
		var rv: Vector2 = r_upper if use_upper else r
		var gx: float = (sr * rv.x + sf * fv.x) + rr * r.x + rf * f.x
		var gy: float = (sr * rv.y + sf * fv.y) + rr * r.y + rf * f.y
		return {
			"pos": Vector2(FOOT_ANCHOR.x + gx, FOOT_ANCHOR.y - uh + gy * DEPTH_Y),
			"depth": gy,
		}

	var foot_L_v: Vector3 = pose["foot_L"]
	var foot_R_v: Vector3 = pose["foot_R"]
	var knee_L_v: Vector3 = pose["knee_L"]
	var knee_R_v: Vector3 = pose["knee_R"]

	var fL: Dictionary = proj.call(foot_L_v.x, foot_L_v.y, foot_L_v.z, false)
	var fR: Dictionary = proj.call(foot_R_v.x, foot_R_v.y, foot_R_v.z, false)
	var kL: Dictionary = proj.call(knee_L_v.x, knee_L_v.y, knee_L_v.z, false)
	var kR: Dictionary = proj.call(knee_R_v.x, knee_R_v.y, knee_R_v.z, false)

	var hip_L: Dictionary = proj.call(-4.0, 0.0, pelvis_h, false)
	var hip_R: Dictionary = proj.call(4.0, 0.0, pelvis_h, false)
	var pelvis: Dictionary = proj.call(0.0, 0.0, pelvis_h + 1.6, false)
	var waist: Dictionary = proj.call(torso_lr * 0.4, torso_lf * 0.4, pelvis_h + 6.6, false)
	var chest: Dictionary = proj.call(torso_lr * 0.85, torso_lf * 0.85, pelvis_h + 14.8 + breathe, true)
	var neck_base: Dictionary = proj.call(torso_lr, torso_lf, pelvis_h + 16.8 + breathe, true)
	var head_h: float = pelvis_h + 26.2 + breathe
	var head_c: Dictionary = proj.call(
		torso_lr + float(pose["head_tilt_r"]),
		torso_lf + float(pose["head_nod_f"]),
		head_h,
		true
	)

	var shL_o: Vector3 = pose["sh_L_off"]
	var shR_o: Vector3 = pose["sh_R_off"]
	var sh_L: Dictionary = proj.call(shL_o.x + torso_lr, shL_o.y + torso_lf, pelvis_h + (shL_o.z - 21.0) + breathe, true)
	var sh_R: Dictionary = proj.call(shR_o.x + torso_lr, shR_o.y + torso_lf, pelvis_h + (shR_o.z - 21.0) + breathe, true)

	var elL_o: Vector3 = pose["el_L"]
	var elR_o: Vector3 = pose["el_R"]
	var haL_o: Vector3 = pose["ha_L"]
	var haR_o: Vector3 = pose["ha_R"]
	var el_L: Dictionary = proj.call(elL_o.x + torso_lr, elL_o.y + torso_lf, pelvis_h + (elL_o.z - 21.0) + breathe * 0.6, true)
	var el_R: Dictionary = proj.call(elR_o.x + torso_lr, elR_o.y + torso_lf, pelvis_h + (elR_o.z - 21.0) + breathe * 0.6, true)
	var ha_L: Dictionary = proj.call(haL_o.x + torso_lr, haL_o.y + torso_lf, pelvis_h + (haL_o.z - 21.0) + breathe * 0.5, true)
	var ha_R: Dictionary = proj.call(haR_o.x + torso_lr, haR_o.y + torso_lf, pelvis_h + (haR_o.z - 21.0) + breathe * 0.5, true)

	var lowest_foot_y: float = maxf(float((fL["pos"] as Vector2).y), float((fR["pos"] as Vector2).y))
	var ground_shift: float = 0.0
	if minf(foot_L_v.z, foot_R_v.z) <= 0.1:
		ground_shift = FOOT_ANCHOR.y - lowest_foot_y

	var shift_dict := func(d: Dictionary) -> Dictionary:
		d["pos"] = (d["pos"] as Vector2) + Vector2(0.0, ground_shift)
		return d

	return {
		"f": f,
		"r": r,
		"f_upper": f_upper,
		"r_upper": r_upper,
		"foot_L": shift_dict.call(fL),
		"foot_R": shift_dict.call(fR),
		"knee_L": shift_dict.call(kL),
		"knee_R": shift_dict.call(kR),
		"hip_L": shift_dict.call(hip_L),
		"hip_R": shift_dict.call(hip_R),
		"pelvis": shift_dict.call(pelvis),
		"waist": shift_dict.call(waist),
		"chest": shift_dict.call(chest),
		"neck_base": shift_dict.call(neck_base),
		"head": shift_dict.call(head_c),
		"sh_L": shift_dict.call(sh_L),
		"sh_R": shift_dict.call(sh_R),
		"el_L": shift_dict.call(el_L),
		"el_R": shift_dict.call(el_R),
		"ha_L": shift_dict.call(ha_L),
		"ha_R": shift_dict.call(ha_R),
		"shadow_c": Vector2(FOOT_ANCHOR.x + rr * r.x + rf * f.x, FOOT_ANCHOR.y + 1.0 + (rr * r.y + rf * f.y) * DEPTH_Y),
		"shadow_rx": float(pose["shadow_rx"]),
		"shadow_ry": float(pose["shadow_ry"]),
	}


func _project_defeat_collapse(pose: Dictionary, f: Vector2, _r: Vector2) -> Dictionary:
	var t: float = float(pose["collapse_t"])
	var fall_dir := Vector2(f.x, f.y * 0.34)
	if absf(fall_dir.x) < 0.35:
		fall_dir.x = 0.88 if f.y >= 0.0 else -0.88
	fall_dir = fall_dir.normalized()
	var side_dir := Vector2(-fall_dir.y, fall_dir.x)

	var tilt_progress: float = minf(1.0, t * 1.15)
	var lift_impact: float = sin(minf(1.0, t * 1.4) * PI) * 2.5 if t > 0.25 and t < 0.7 else 0.0
	var base_pelvis := FOOT_ANCHOR + Vector2(0.0, lerpf(-9.5, -5.0, tilt_progress) - lift_impact)

	var spine_vec: Vector2 = Vector2(0.0, -1.0).lerp(fall_dir, 0.62 + 0.36 * tilt_progress).normalized()
	var leg_vec: Vector2 = -fall_dir

	var chest_pos: Vector2 = base_pelvis + spine_vec * 14.5
	var neck_pos: Vector2 = chest_pos + spine_vec * 2.8
	var head_drop: float = maxf(0.0, t - 0.35) / 0.65
	var head_pos: Vector2 = neck_pos + spine_vec * 8.4 + Vector2(0.0, head_drop * 3.0)

	var sh_L_pos: Vector2 = chest_pos + side_dir * 4.8 + Vector2(0.0, -2.5 * (1.0 - tilt_progress))
	var sh_R_pos: Vector2 = chest_pos - side_dir * 4.8 + Vector2(0.0, 1.6)
	var el_L_pos: Vector2 = sh_L_pos + fall_dir * 8.0 + side_dir * 3.6 + Vector2(0.0, 2.0 * head_drop)
	var el_R_pos: Vector2 = sh_R_pos + fall_dir * 7.0 - side_dir * 4.8 + Vector2(0.0, 1.5)
	var ha_L_pos: Vector2 = el_L_pos + fall_dir * 6.8 + Vector2(0.0, 2.0)
	var ha_R_pos: Vector2 = el_R_pos + fall_dir * 5.6 - side_dir * 2.6 + Vector2(0.0, 1.5)

	var kL_pos: Vector2 = base_pelvis + leg_vec * 10.6 + Vector2(0.0, -1.6 * (1.0 - head_drop))
	var kR_pos: Vector2 = base_pelvis + leg_vec * 9.8 + side_dir * 3.6
	var fL_pos: Vector2 = kL_pos + leg_vec * 10.2 + Vector2(0.0, 1.8)
	var fR_pos: Vector2 = kR_pos + leg_vec * 9.8 + side_dir * 2.8 + Vector2(0.0, 1.4)

	var mid_body: Vector2 = (fL_pos + head_pos) * 0.5
	return {
		"f": f,
		"r": Vector2(-f.y, f.x),
		"f_upper": f,
		"r_upper": Vector2(-f.y, f.x),
		"foot_L": {"pos": fL_pos, "depth": -1.0},
		"foot_R": {"pos": fR_pos, "depth": 1.0},
		"knee_L": {"pos": kL_pos, "depth": -0.8},
		"knee_R": {"pos": kR_pos, "depth": 1.2},
		"hip_L": {"pos": base_pelvis + side_dir * 2.2, "depth": -0.5},
		"hip_R": {"pos": base_pelvis - side_dir * 2.2, "depth": 0.8},
		"pelvis": {"pos": base_pelvis, "depth": 0.2},
		"waist": {"pos": base_pelvis.lerp(chest_pos, 0.45), "depth": 0.3},
		"chest": {"pos": chest_pos, "depth": 0.4},
		"neck_base": {"pos": neck_pos, "depth": 0.4},
		"head": {"pos": head_pos, "depth": 0.5},
		"sh_L": {"pos": sh_L_pos, "depth": -1.2},
		"sh_R": {"pos": sh_R_pos, "depth": 1.6},
		"el_L": {"pos": el_L_pos, "depth": -1.0},
		"el_R": {"pos": el_R_pos, "depth": 2.0},
		"ha_L": {"pos": ha_L_pos, "depth": -0.8},
		"ha_R": {"pos": ha_R_pos, "depth": 2.2},
		"shadow_c": Vector2(mid_body.x, FOOT_ANCHOR.y + 0.5),
		"shadow_rx": lerpf(16.0, 24.5, tilt_progress),
		"shadow_ry": lerpf(4.6, 5.4, tilt_progress),
	}


func _project_pose_axe(pose: Dictionary, dir_name: String) -> Dictionary:
	var skel: Dictionary = _project_skeleton(pose, dir_name)
	var hand_R: Vector2 = skel["ha_R"]["pos"]
	var chest: Vector2 = skel["chest"]["pos"]
	var f: Vector2 = _dir_vec(dir_name)

	var fi: int = int(pose["axe_fi"])
	var base_fwd: Vector2 = Vector2(f.x, f.y * 0.72).normalized()
	var sweep_offsets: Array[float] = [-2.20, -2.55, 0.20, 1.12, 0.68, 0.32]
	var flip_sign: float = -1.0 if f.x < -0.15 else 1.0
	var ang: float = base_fwd.angle() + sweep_offsets[fi] * flip_sign
	var axe_u := Vector2(cos(ang), sin(ang))

	var grip: Vector2 = hand_R
	var pommel: Vector2 = grip - axe_u * 5.0
	var head_pt: Vector2 = grip + axe_u * (AXE_LEN_2D - 5.0)
	var blade_normal := Vector2(-axe_u.y, axe_u.x) * flip_sign
	var blade_tip: Vector2 = head_pt + blade_normal * 5.2

	return {
		"grip": grip,
		"pommel": pommel,
		"head": head_pt,
		"blade_tip": blade_tip,
		"axe_u": axe_u,
		"blade_normal": blade_normal,
		"pivot": chest + Vector2(0.0, 1.0),
		"angle": ang,
		"flip_sign": flip_sign,
	}


func _draw_character_cell(
	dst: Image,
	vfx_dst: Image,
	pal: Dictionary,
	pose: Dictionary,
	anim_name: String,
	fi: int,
	dir_name: String,
	impact_axe_state: Dictionary
) -> void:
	var skel: Dictionary = _project_skeleton(pose, dir_name)
	var ink: Color = pal["ink"]
	var f: Vector2 = skel["f"]
	var f_upper: Vector2 = skel["f_upper"]

	var sh_c: Vector2 = skel["shadow_c"]
	PAC.draw_ground_shadow(dst, sh_c.x, sh_c.y, float(skel["shadow_rx"]), float(skel["shadow_ry"]), pal["shadow_in"], pal["shadow_out"])

	var queue: Array[Dictionary] = []
	var legL_depth: float = minf(float(skel["foot_L"]["depth"]), float(skel["hip_L"]["depth"])) - 0.1
	var legR_depth: float = minf(float(skel["foot_R"]["depth"]), float(skel["hip_R"]["depth"])) - 0.1
	var armL_depth: float = float(skel["el_L"]["depth"]) * 0.55 + float(skel["ha_L"]["depth"]) * 0.45
	var armR_depth: float = float(skel["el_R"]["depth"]) * 0.55 + float(skel["ha_R"]["depth"]) * 0.45

	if f.x > 0.5:
		armR_depth += 1.2
		armL_depth -= 1.2
	elif f.x < -0.5:
		armL_depth += 1.2
		armR_depth -= 1.2

	queue.append({"kind": "leg_L", "depth": legL_depth})
	queue.append({"kind": "leg_R", "depth": legR_depth})
	queue.append({"kind": "torso", "depth": 0.0})
	queue.append({"kind": "hood_back", "depth": -0.6 if f_upper.y >= 0.0 else 1.2})
	queue.append({"kind": "arm_L", "depth": armL_depth})
	queue.append({"kind": "arm_R", "depth": armR_depth})
	queue.append({"kind": "head_hair", "depth": 0.35})

	var axe_geom: Dictionary = {}
	if bool(pose["has_axe"]):
		axe_geom = _project_pose_axe(pose, dir_name)
		var axe_depth: float = float(skel["ha_R"]["depth"]) + 0.5
		if fi in [0, 1] and f.y < 0.0:
			axe_depth = -1.6
		elif fi in [0, 1] and f.y >= 0.0:
			axe_depth = 0.05 if f.y > 0.7 else 1.4
		queue.append({"kind": "axe", "depth": axe_depth})

	queue.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["depth"]) < float(b["depth"]))

	for item in queue:
		var kind: String = item["kind"]
		var buf: Image = PAC.create_cell()
		match kind:
			"leg_L":
				_draw_leg(buf, pal, skel, "L", f, bool(pose["ground_collapse"]))
				PAC.stamp_outlined_part(dst, buf, ink)
			"leg_R":
				_draw_leg(buf, pal, skel, "R", f, bool(pose["ground_collapse"]))
				PAC.stamp_outlined_part(dst, buf, ink)
			"torso":
				_draw_torso(buf, pal, pose, skel, f_upper)
				PAC.stamp_outlined_part(dst, buf, ink)
			"hood_back":
				_draw_hood_back(buf, pal, pose, skel, f_upper)
				PAC.stamp_outlined_part(dst, buf, ink)
			"arm_L":
				_draw_arm(buf, pal, skel, "L", bool(pose["has_axe"]))
				PAC.stamp_outlined_part(dst, buf, ink)
			"arm_R":
				_draw_arm(buf, pal, skel, "R", bool(pose["has_axe"]))
				PAC.stamp_outlined_part(dst, buf, ink)
			"head_hair":
				_draw_head_and_hair_unified(buf, pal, pose, skel, f_upper, anim_name, fi)
				PAC.stamp_outlined_part(dst, buf, ink)
			"axe":
				_draw_axe(buf, pal, axe_geom)
				PAC.stamp_outlined_part(dst, buf, ink)

	if anim_name == "attack" and fi in [2, 3]:
		_draw_attack_vfx(vfx_dst, pal, axe_geom, impact_axe_state, fi)


func _draw_leg(buf: Image, pal: Dictionary, skel: Dictionary, side: String, f: Vector2, collapsed: bool) -> void:
	var hip: Vector2 = skel["hip_%s" % side]["pos"]
	var knee: Vector2 = skel["knee_%s" % side]["pos"]
	var foot: Vector2 = skel["foot_%s" % side]["pos"]
	var pants: Array = pal["pants"]
	var boots: Array = pal["boots"]
	var bias: float = -0.06 if side == "L" else 0.04

	PAC.draw_shaded_limb(buf, hip, knee, 3.3, 2.7, pants, bias)
	PAC.draw_shaded_limb(buf, knee, foot - Vector2(0.0, 2.2), 2.7, 2.25, pants, bias)

	if bool(pal["is_bfp"]):
		var b_a: Vector2 = knee.lerp(foot, 0.56)
		var b_b: Vector2 = knee.lerp(foot, 0.72)
		var stripe: Array = pal["stripe"]
		PAC.draw_flat_capsule(buf, b_a, b_b, 2.3, stripe[3], stripe[2], stripe[0])

	var toe_dir := Vector2(f.x * 2.8, f.y * 1.0 - 0.1)
	if collapsed:
		toe_dir = Vector2(0.0, 2.4)
	var heel: Vector2 = foot - toe_dir * 0.25 + Vector2(0.0, -0.8)
	var toe: Vector2 = foot + toe_dir * 0.95 + Vector2(0.0, -0.4)
	PAC.draw_shaded_limb(buf, foot + Vector2(0.0, -2.5), heel, 2.3, 2.2, boots, bias)
	PAC.draw_shaded_limb(buf, heel, toe, 2.2, 1.6, boots, bias + 0.08)


func _draw_torso(buf: Image, pal: Dictionary, pose: Dictionary, skel: Dictionary, f_upper: Vector2) -> void:
	var pelvis: Vector2 = skel["pelvis"]["pos"]
	var waist: Vector2 = skel["waist"]["pos"]
	var chest: Vector2 = skel["chest"]["pos"]
	var sh_L: Vector2 = skel["sh_L"]["pos"]
	var sh_R: Vector2 = skel["sh_R"]["pos"]
	var is_bfp: bool = bool(pal["is_bfp"])
	var flare: float = float(pose["flap_flare"])
	var lag_f: float = float(pose["flap_lag_f"])

	PAC.draw_shaded_oval(buf, pelvis, 5.8, 3.6, pal["pants"], -0.05)

	var shirt_pal: Array = pal["shirt"] if not is_bfp else pal["jacket"]
	PAC.draw_shaded_limb(buf, waist, chest, 5.4, 7.0, shirt_pal, 0.0)
	PAC.draw_shaded_limb(buf, sh_L.lerp(chest, 0.15), sh_R.lerp(chest, 0.15), 2.7, 2.7, shirt_pal, 0.05)

	if not is_bfp and f_upper.y > -0.2:
		# Exposed chest neck cord across upper dark shirt
		var neck_mid: Vector2 = chest + Vector2(f_upper.x * 1.4, -2.8)
		var cord_c: Color = pal["cord"]
		var cord_s: Color = pal["cord_sh"]
		for dx in range(-2, 3):
			var drop: int = 2 - absi(dx)
			PAC.set_px(buf, int(round(neck_mid.x)) + dx, int(round(neck_mid.y)) + drop, cord_c if dx <= 0 else cord_s)

	if not is_bfp:
		var jacket_pal: Array = pal["jacket"]
		var lapel_pal: Array = pal["jacket_lapel"]
		var r_u: Vector2 = skel["r_upper"]
		var open_w: float = 2.0 + flare * 0.55 if f_upper.y > -0.2 else 0.0
		var flap_off: Vector2 = Vector2(-f_upper.x * lag_f * 0.38, -f_upper.y * lag_f * 0.14)

		var l_top: Vector2 = chest + r_u * (-3.0 - open_w * 0.25) + Vector2(0.0, -1.3)
		var l_bot: Vector2 = pelvis + r_u * (-3.7 - open_w) + flap_off + Vector2(0.0, 1.4)
		var r_top: Vector2 = chest + r_u * (3.0 + open_w * 0.25) + Vector2(0.0, -1.3)
		var r_bot: Vector2 = pelvis + r_u * (3.7 + open_w) + flap_off + Vector2(0.0, 1.4)

		if f_upper.y <= -0.15:
			PAC.draw_shaded_limb(buf, pelvis + flap_off * 0.7, chest, 5.8 + flare * 0.35, 7.2, jacket_pal, -0.04)
			PAC.draw_flat_capsule(buf, chest + Vector2(0.0, 1.0), pelvis + flap_off * 0.5, 0.9, jacket_pal[3], jacket_pal[2], jacket_pal[0])
		else:
			PAC.draw_shaded_limb(buf, l_top, l_bot, 3.0, 2.7, jacket_pal, 0.10)
			PAC.draw_shaded_limb(buf, r_top, r_bot, 3.0, 2.7, jacket_pal, -0.04)
			PAC.draw_shaded_limb(buf, l_top + r_u * 1.2, l_top.lerp(l_bot, 0.78), 1.3, 1.1, lapel_pal, 0.16)
			PAC.draw_shaded_limb(buf, r_top - r_u * 1.2, r_top.lerp(r_bot, 0.78), 1.3, 1.1, lapel_pal, 0.04)
	else:
		var j_pal: Array = pal["jacket"]
		var stripe: Array = pal["stripe"]
		var r_u: Vector2 = skel["r_upper"]
		var hem_off: Vector2 = Vector2(-f_upper.x * float(pose["flap_lag_f"]) * 0.28, 0.0)
		PAC.draw_shaded_limb(buf, pelvis + hem_off, chest, 5.9 + flare * 0.3, 7.2, j_pal, 0.04)
		# Crisp horizontal BFP chest & waist reflective bands drawn cleanly within silhouette bounds
		var min_y_ch: int = int(round(waist.lerp(chest, 0.62).y))
		var min_y_hm: int = int(round(pelvis.lerp(waist, 0.22).y))
		_recolor_horizontal_band(buf, min_y_ch, 2, stripe)
		_recolor_horizontal_band(buf, min_y_hm, 2, stripe)
		# Small open collar V showing dark undershirt above stripe
		if f_upper.y > 0.1:
			var v_pt: Vector2 = chest + Vector2(f_upper.x * 1.6, -2.8)
			PAC.draw_shaded_oval(buf, v_pt, 1.8, 2.3, pal["shirt"], 0.0)
			# Crisp brass zip line center-front
			var zip_x: int = int(round(chest.x + f_upper.x * 1.5))
			for zy in range(min_y_ch + 2, min_y_hm):
				if buf.get_pixel(zip_x, zy).a > 0.5:
					buf.set_pixel(zip_x, zy, j_pal[3])


func _recolor_horizontal_band(buf: Image, cy: int, thickness: int, stripe: Array) -> void:
	for y in range(cy, cy + thickness):
		if y < 0 or y >= CELL_H:
			continue
		var xs: Array[int] = []
		for x in range(CELL_W):
			if buf.get_pixel(x, y).a > 0.5:
				xs.append(x)
		if xs.size() < 4:
			continue
		var x_min: int = xs[0]
		var x_max: int = xs[xs.size() - 1]
		var span: float = maxf(1.0, float(x_max - x_min))
		for x in xs:
			var nx: float = (float(x) - float(x_min)) / span
			var col: Color = stripe[2]
			if nx < 0.28:
				col = stripe[3]
			elif nx > 0.72:
				col = stripe[1] if y == cy else stripe[0]
			elif y > cy:
				col = stripe[1]
			buf.set_pixel(x, y, col)


func _draw_hood_back(buf: Image, pal: Dictionary, _pose: Dictionary, skel: Dictionary, f_upper: Vector2) -> void:
	var neck_b: Vector2 = skel["neck_base"]["pos"]
	var chest: Vector2 = skel["chest"]["pos"]
	var lapel_pal: Array = pal["jacket_lapel"]
	var jacket_pal: Array = pal["jacket"]

	if not bool(pal["is_bfp"]):
		var hood_off: Vector2 = Vector2(-f_upper.x * 2.4, -1.6 + (-f_upper.y * 1.2 if f_upper.y < 0.0 else 0.5))
		var hc: Vector2 = neck_b.lerp(chest, 0.25) + hood_off
		if f_upper.y <= -0.1:
			PAC.draw_shaded_oval(buf, hc + Vector2(0.0, 2.4), 6.2, 4.0, lapel_pal, 0.06)
			PAC.draw_shaded_oval(buf, hc + Vector2(0.0, 0.4), 5.4, 2.4, jacket_pal, -0.05)
		else:
			PAC.draw_shaded_oval(buf, neck_b + Vector2(-4.4, -0.8), 2.8, 2.4, lapel_pal, 0.12)
			PAC.draw_shaded_oval(buf, neck_b + Vector2(4.4, -0.8), 2.8, 2.4, lapel_pal, -0.04)
	else:
		PAC.draw_shaded_oval(buf, neck_b + Vector2(0.0, -0.8), 4.6, 2.1, lapel_pal, 0.06)


func _draw_arm(buf: Image, pal: Dictionary, skel: Dictionary, side: String, has_axe: bool) -> void:
	var sh: Vector2 = skel["sh_%s" % side]["pos"]
	var el: Vector2 = skel["el_%s" % side]["pos"]
	var ha: Vector2 = skel["ha_%s" % side]["pos"]
	var jacket_pal: Array = pal["jacket"]
	var skin_pal: Array = pal["skin"]
	var bias: float = 0.06 if side == "L" else -0.04

	var wrist: Vector2 = el.lerp(ha, 0.80)
	PAC.draw_shaded_limb(buf, sh, el, 2.8, 2.5, jacket_pal, bias)
	PAC.draw_shaded_limb(buf, el, wrist, 2.6, 2.25, jacket_pal, bias + 0.05)

	if bool(pal["is_bfp"]):
		var cuff_a: Vector2 = el.lerp(wrist, 0.65)
		var cuff_b: Vector2 = el.lerp(wrist, 0.85)
		var stripe: Array = pal["stripe"]
		PAC.draw_flat_capsule(buf, cuff_a, cuff_b, 2.25, stripe[3], stripe[2], stripe[0])

	var hand_r: float = 2.25 if has_axe else 2.05
	PAC.draw_shaded_disk(buf, ha, hand_r, skin_pal, bias + 0.10)


func _draw_head_and_hair_unified(
	buf: Image,
	pal: Dictionary,
	pose: Dictionary,
	skel: Dictionary,
	f_upper: Vector2,
	anim_name: String,
	fi: int
) -> void:
	var neck_b: Vector2 = skel["neck_base"]["pos"]
	var head_c: Vector2 = skel["head"]["pos"]
	var skin: Array = pal["skin"]
	var root_col: Color = pal["hair_root"]
	var blond_pal: Array = pal["hair_blond"]

	var lag := Vector2(
		-f_upper.x * float(pose["head_lag_f"]) * 0.45,
		-absf(float(pose["head_lag_f"])) * 0.25
	)

	var draw_lock := func(base_p: Vector2, tip_p: Vector2, hw: float, bend: float, rr: float) -> void:
		PAC.draw_pointed_hair_lock(buf, base_p, tip_p + lag, hw, bend, root_col, blond_pal, rr, 0.06)

	var draw_root_crevice := func(base_p: Vector2, tip_p: Vector2, hw: float, bend: float) -> void:
		PAC.draw_pointed_hair_lock(buf, base_p, tip_p + lag * 0.5, hw, bend, root_col, [root_col, blond_pal[0]], 0.72, 0.0)

	# 1. Back nape dark roots & subtle lower hair wisps behind neck/ears
	if f_upper.y > -0.25:
		if absf(f_upper.x) < 0.35:
			draw_lock.call(head_c + Vector2(-5.4, 1.5), head_c + Vector2(-8.6, 5.4), 1.9, -0.5, 0.24)
			draw_lock.call(head_c + Vector2(5.4, 1.5), head_c + Vector2(8.6, 5.4), 1.9, 0.5, 0.24)
		else:
			var sgn_b: float = -signf(f_upper.x)
			draw_lock.call(head_c + Vector2(sgn_b * 3.8, 1.8), head_c + Vector2(sgn_b * 7.8, 5.2), 2.1, sgn_b * 0.4, 0.24)

	# 2. Visible warm brown neck & sculpted jaw/cranium
	PAC.draw_shaded_limb(buf, neck_b + Vector2(0.0, 1.2), head_c + Vector2(0.0, 4.4), 2.55, 2.3, skin, -0.05)

	var face_yaw_x: float = f_upper.x
	# Place ears anatomically accurately by yaw angle (NEVER protruding from front profile nose!)
	if f_upper.y >= -0.75:
		if absf(face_yaw_x) < 0.35:
			PAC.draw_shaded_oval(buf, head_c + Vector2(-7.0, 1.0), 1.5, 2.1, skin, 0.05)
			PAC.draw_shaded_oval(buf, head_c + Vector2(7.0, 1.0), 1.5, 2.1, skin, -0.08)
		elif absf(face_yaw_x) < 0.80:
			var back_sgn: float = -signf(face_yaw_x)
			PAC.draw_shaded_oval(buf, head_c + Vector2(back_sgn * 6.5, 1.0), 1.4, 2.0, skin, -0.04)

	PAC.draw_shaded_oval(buf, head_c + Vector2(0.0, -0.8), 7.2, 6.1, skin, 0.05)
	PAC.draw_shaded_oval(buf, head_c + Vector2(face_yaw_x * 1.0, 3.6), 4.9, 3.8, skin, -0.02)

	# Subtle 1px angular anime nose contour ONLY on side profile
	if f_upper.y > -0.25 and absf(face_yaw_x) > 0.72:
		var nx: int = int(round(head_c.x + signf(face_yaw_x) * 7.5))
		var ny: int = int(round(head_c.y + 1.2))
		PAC.set_px(buf, nx, ny, skin[2])
		PAC.set_px(buf, nx, ny + 1, skin[1])

	# 3. Exposed eyes, heavy olheiras & signature wide grin (100% uncovered)
	if f_upper.y > -0.25:
		_draw_facial_features(buf, pal, head_c, f_upper, str(pose["expression"]), anim_name, fi)

	# In true profile, draw exposed ear neatly in center-rear cheek AFTER skull fill so it reads inside jaw
	if f_upper.y >= -0.35 and absf(face_yaw_x) >= 0.80:
		var sgn_e: float = signf(face_yaw_x)
		PAC.draw_shaded_oval(buf, head_c + Vector2(-sgn_e * 2.2, 1.4), 1.4, 2.0, skin, -0.06)

	# 4. Direction-authentic straw-blond crown hair + vertical dark root crevices (zero headband stripes)
	if absf(f_upper.x) < 0.28 and f_upper.y > 0.45:
		# FRONT VIEW ('down'): luminous straw-blond crown + staggered dark vertical root streaks
		PAC.draw_shaded_oval(buf, head_c + Vector2(0.0, -5.6), 7.8, 3.8, blond_pal, 0.05)
		draw_lock.call(head_c + Vector2(-2.2, -5.6), head_c + Vector2(-4.4, -14.8), 3.1, -0.8, 0.0)
		draw_lock.call(head_c + Vector2(1.4, -5.8), head_c + Vector2(3.4, -15.6), 3.2, 0.7, 0.0)
		draw_lock.call(head_c + Vector2(-0.3, -5.6), head_c + Vector2(0.2, -13.6), 2.8, 0.3, 0.0)
		draw_lock.call(head_c + Vector2(-5.2, -4.6), head_c + Vector2(-10.8, -10.8), 2.9, -0.7, 0.0)
		draw_lock.call(head_c + Vector2(5.2, -4.6), head_c + Vector2(10.8, -10.4), 2.9, 0.7, 0.0)
		draw_lock.call(head_c + Vector2(-6.6, -2.8), head_c + Vector2(-11.4, -4.4), 2.5, -0.4, 0.0)
		draw_lock.call(head_c + Vector2(6.6, -2.8), head_c + Vector2(11.6, -4.2), 2.5, 0.4, 0.0)
		# Crisp staggered radial dark root shards tucked cleanly between crown locks
		draw_root_crevice.call(head_c + Vector2(-0.2, -4.4), head_c + Vector2(-0.8, -10.2), 1.3, -0.2)
		draw_root_crevice.call(head_c + Vector2(-3.2, -4.2), head_c + Vector2(-5.6, -9.2), 1.2, -0.3)
		draw_root_crevice.call(head_c + Vector2(3.2, -4.2), head_c + Vector2(5.6, -9.2), 1.2, 0.3)
		# Crisp forehead framing tufts ending cleanly above eyebrows + narrow signature center strand
		draw_lock.call(head_c + Vector2(-3.8, -4.4), head_c + Vector2(-5.2, -1.6), 2.0, -0.3, 0.0)
		draw_lock.call(head_c + Vector2(3.8, -4.4), head_c + Vector2(5.2, -1.6), 2.0, 0.3, 0.0)
		draw_lock.call(head_c + Vector2(-0.3, -4.8), head_c + Vector2(0.1, -0.8), 1.4, 0.3, 0.14)

	elif absf(f_upper.x) < 0.85 and f_upper.y > 0.15:
		# 3/4 FRONT VIEW ('down_left', 'down_right')
		var sgn: float = 1.0 if f_upper.x > 0.0 else -1.0
		PAC.draw_shaded_oval(buf, head_c + Vector2(-sgn * 1.4, -5.2), 7.6, 4.0, blond_pal, 0.04)
		PAC.draw_shaded_oval(buf, head_c + Vector2(-sgn * 4.4, -1.2), 3.4, 3.6, blond_pal, -0.04)
		PAC.draw_shaded_oval(buf, head_c + Vector2(-sgn * 5.2, 1.8), 2.0, 2.0, [root_col, root_col], 0.0)
		draw_lock.call(head_c + Vector2(-sgn * 2.5, -5.6), head_c + Vector2(-sgn * 5.2, -14.8), 3.1, -sgn * 0.7, 0.0)
		draw_lock.call(head_c + Vector2(sgn * 1.2, -5.8), head_c + Vector2(sgn * 3.0, -15.4), 3.1, sgn * 0.6, 0.0)
		draw_lock.call(head_c + Vector2(-sgn * 5.6, -4.4), head_c + Vector2(-sgn * 11.4, -9.8), 2.8, -sgn * 0.6, 0.0)
		draw_lock.call(head_c + Vector2(-sgn * 6.2, -1.6), head_c + Vector2(-sgn * 11.2, -3.2), 2.5, -sgn * 0.4, 0.0)
		draw_lock.call(head_c + Vector2(sgn * 4.2, -5.2), head_c + Vector2(sgn * 8.2, -9.6), 2.4, sgn * 0.5, 0.0)
		draw_root_crevice.call(head_c + Vector2(-sgn * 0.8, -4.6), head_c + Vector2(-sgn * 2.2, -10.2), 1.3, -sgn * 0.2)
		draw_root_crevice.call(head_c + Vector2(-sgn * 4.2, -3.2), head_c + Vector2(-sgn * 7.6, -7.2), 1.2, -sgn * 0.3)
		draw_lock.call(head_c + Vector2(sgn * 2.2, -4.6), head_c + Vector2(sgn * 3.2, -1.4), 1.6, sgn * 0.4, 0.14)
		draw_lock.call(head_c + Vector2(-sgn * 2.0, -4.4), head_c + Vector2(-sgn * 3.8, -1.2), 1.8, -sgn * 0.3, 0.0)

	elif f_upper.y >= -0.25:
		# TRUE PROFILE VIEW ('left', 'right')
		var sgn: float = 1.0 if f_upper.x >= 0.0 else -1.0
		PAC.draw_shaded_oval(buf, head_c + Vector2(-sgn * 2.2, -5.0), 7.2, 4.0, blond_pal, 0.04)
		PAC.draw_shaded_oval(buf, head_c + Vector2(-sgn * 4.6, -0.8), 3.8, 4.4, blond_pal, -0.05)
		PAC.draw_shaded_oval(buf, head_c + Vector2(-sgn * 4.2, 2.8), 2.0, 1.8, [root_col, root_col], 0.0)
		draw_lock.call(head_c + Vector2(sgn * 0.6, -5.6), head_c + Vector2(sgn * 2.2, -15.2), 3.0, sgn * 0.5, 0.0)
		draw_lock.call(head_c + Vector2(-sgn * 2.2, -5.6), head_c + Vector2(-sgn * 4.2, -14.8), 3.2, -sgn * 0.7, 0.0)
		draw_lock.call(head_c + Vector2(-sgn * 4.8, -4.6), head_c + Vector2(-sgn * 10.6, -10.8), 2.9, -sgn * 0.6, 0.0)
		draw_lock.call(head_c + Vector2(-sgn * 6.0, -1.8), head_c + Vector2(-sgn * 11.4, -3.6), 2.7, -sgn * 0.4, 0.0)
		draw_lock.call(head_c + Vector2(-sgn * 5.6, 1.4), head_c + Vector2(-sgn * 10.0, 3.2), 2.2, -sgn * 0.3, 0.0)
		draw_root_crevice.call(head_c + Vector2(-sgn * 0.8, -4.6), head_c + Vector2(-sgn * 2.0, -10.4), 1.3, -sgn * 0.2)
		draw_root_crevice.call(head_c + Vector2(-sgn * 4.2, -2.6), head_c + Vector2(-sgn * 8.2, -6.4), 1.2, -sgn * 0.2)
		draw_lock.call(head_c + Vector2(sgn * 3.2, -4.8), head_c + Vector2(sgn * 7.2, -4.2), 1.8, sgn * 0.3, 0.0)

	elif absf(f_upper.x) > 0.28:
		# 3/4 REAR VIEW ('up_left', 'up_right')
		var sgn: float = 1.0 if f_upper.x > 0.0 else -1.0
		PAC.draw_shaded_oval(buf, head_c + Vector2(0.0, 3.2), 5.0, 1.9, [root_col, root_col], 0.0)
		PAC.draw_shaded_oval(buf, head_c + Vector2(0.0, -2.2), 7.6, 5.4, blond_pal, 0.0)
		draw_lock.call(head_c + Vector2(-2.2, -5.6), head_c + Vector2(-4.8, -14.8), 3.2, -0.7, 0.0)
		draw_lock.call(head_c + Vector2(2.0, -5.6), head_c + Vector2(4.6, -15.2), 3.2, 0.7, 0.0)
		draw_lock.call(head_c + Vector2(-5.4, -4.2), head_c + Vector2(-11.0, -9.6), 2.8, -0.6, 0.0)
		draw_lock.call(head_c + Vector2(5.4, -4.2), head_c + Vector2(11.0, -9.6), 2.8, 0.6, 0.0)
		draw_lock.call(head_c + Vector2(-sgn * 4.5, -1.2), head_c + Vector2(-sgn * 10.6, -2.8), 2.5, -sgn * 0.4, 0.0)
		draw_root_crevice.call(head_c + Vector2(-1.4, -4.4), head_c + Vector2(-2.8, -10.2), 1.3, -0.2)
		draw_root_crevice.call(head_c + Vector2(1.6, -4.4), head_c + Vector2(3.2, -10.2), 1.3, 0.2)
		# Layered blond nape points overlapping dark undercut cleanly
		draw_lock.call(head_c + Vector2(-2.0, 0.2), head_c + Vector2(-4.2, 5.8), 2.3, -0.2, 0.0)
		draw_lock.call(head_c + Vector2(1.8, 0.2), head_c + Vector2(3.4, 5.6), 2.2, 0.2, 0.0)

	else:
		# FULL REAR VIEW ('up')
		PAC.draw_shaded_oval(buf, head_c + Vector2(0.0, 3.4), 5.6, 2.0, [root_col, root_col], 0.0)
		PAC.draw_shaded_oval(buf, head_c + Vector2(0.0, -2.2), 7.8, 5.6, blond_pal, 0.02)
		draw_lock.call(head_c + Vector2(-2.2, -5.6), head_c + Vector2(-4.8, -14.8), 3.2, -0.7, 0.0)
		draw_lock.call(head_c + Vector2(2.2, -5.6), head_c + Vector2(4.8, -15.2), 3.2, 0.7, 0.0)
		draw_lock.call(head_c + Vector2(0.0, -5.8), head_c + Vector2(-0.4, -13.8), 2.8, 0.3, 0.0)
		draw_lock.call(head_c + Vector2(-5.4, -4.4), head_c + Vector2(-11.2, -9.8), 2.9, -0.6, 0.0)
		draw_lock.call(head_c + Vector2(5.4, -4.4), head_c + Vector2(11.2, -9.6), 2.9, 0.6, 0.0)
		draw_lock.call(head_c + Vector2(-6.6, -1.6), head_c + Vector2(-11.4, -3.0), 2.5, -0.4, 0.0)
		draw_lock.call(head_c + Vector2(6.6, -1.6), head_c + Vector2(11.4, -3.0), 2.5, 0.4, 0.0)
		draw_root_crevice.call(head_c + Vector2(-1.6, -4.2), head_c + Vector2(-3.4, -10.2), 1.3, -0.2)
		draw_root_crevice.call(head_c + Vector2(1.6, -4.2), head_c + Vector2(3.4, -10.2), 1.3, 0.2)
		# Layered blond nape locks draping over dark rear hairline
		draw_lock.call(head_c + Vector2(-3.4, 0.4), head_c + Vector2(-5.4, 6.0), 2.3, -0.3, 0.0)
		draw_lock.call(head_c + Vector2(0.0, 0.6), head_c + Vector2(0.2, 6.2), 2.4, 0.0, 0.0)
		draw_lock.call(head_c + Vector2(3.4, 0.4), head_c + Vector2(5.4, 6.0), 2.3, 0.3, 0.0)


func _draw_facial_features(
	buf: Image,
	pal: Dictionary,
	hc: Vector2,
	f: Vector2,
	expr: String,
	_anim: String,
	_fi: int
) -> void:
	var olh: Color = pal["olheira"]
	var ew: Color = pal["eye_white"]
	var ep: Color = pal["eye_pupil"]
	var teeth: Color = pal["teeth"]
	var mline: Color = pal["mouth_line"]
	var skin: Array = pal["skin"]

	var cx: int = int(round(hc.x))
	var cy: int = int(round(hc.y))

	if absf(f.x) < 0.28 and f.y > 0.5:
		# Clear front view ('down'): bold tall anime eyes, heavy dark olheiras, wide unsettling grin
		for side in [-1, 1]:
			var ex: int = cx + side * 3
			var ey: int = cy
			# Dark brows at ey - 2
			PAC.set_px(buf, ex - 1, ey - 2, ep)
			PAC.set_px(buf, ex, ey - 2, ep)
			PAC.set_px(buf, ex + side * 1, ey - 2, ep)
			if expr == "closed":
				PAC.set_px(buf, ex - 1, ey, ep)
				PAC.set_px(buf, ex, ey, ep)
				PAC.set_px(buf, ex + 1, ey, ep)
				PAC.set_px(buf, ex, ey + 1, olh)
			elif expr == "pained":
				PAC.set_px(buf, ex, ey - 1, ep)
				PAC.set_px(buf, ex - side * 1, ey, ep)
				PAC.set_px(buf, ex + side * 1, ey + 1, ep)
				PAC.set_px(buf, ex, ey + 2, olh)
			else:
				# Upper lash lid + bright 2px tall eye + heavy olheira crescent right under
				PAC.set_px(buf, ex - 1, ey - 1, ew)
				PAC.set_px(buf, ex, ey - 1, ep)
				PAC.set_px(buf, ex + 1, ey - 1, ew)
				PAC.set_px(buf, ex - 1, ey, ew)
				PAC.set_px(buf, ex, ey, ep)
				PAC.set_px(buf, ex + 1, ey, ew)
				for ox in range(-1, 2):
					PAC.set_px(buf, ex + ox, ey + 1, olh)
		# Crisp nose glint
		PAC.set_px(buf, cx, cy + 1, skin[3])
		PAC.set_px(buf, cx, cy + 2, skin[0])
		# Signature wide toothy smile at cy + 4..5
		if expr == "pained" or expr == "closed":
			for mx in range(-2, 3):
				PAC.set_px(buf, cx + mx, cy + 4, mline)
			if expr == "pained":
				PAC.set_px(buf, cx - 1, cy + 4, teeth)
				PAC.set_px(buf, cx + 1, cy + 4, teeth)
		else:
			for mx in range(-3, 4):
				PAC.set_px(buf, cx + mx, cy + 4, mline if absi(mx) == 3 else teeth)
			for mx in range(-2, 3):
				PAC.set_px(buf, cx + mx, cy + 5, teeth if absi(mx) <= 1 else mline)
			PAC.set_px(buf, cx, cy + 6, skin[0])

	elif absf(f.x) < 0.85 and f.y > 0.15:
		# 3/4 Front view ('down_left', 'down_right')
		var sgn: int = 1 if f.x > 0.0 else -1
		var near_ex: int = cx + sgn * 1
		var far_ex: int = cx + sgn * 5
		var ey: int = cy
		if expr == "closed":
			for k in range(2):
				PAC.set_px(buf, near_ex - sgn * k, ey, ep)
				PAC.set_px(buf, far_ex - sgn * k, ey, ep)
		else:
			PAC.set_px(buf, near_ex - sgn * 1, ey - 2, ep)
			PAC.set_px(buf, near_ex, ey - 2, ep)
			PAC.set_px(buf, near_ex - sgn * 1, ey - 1, ew)
			PAC.set_px(buf, near_ex, ey - 1, ep)
			PAC.set_px(buf, near_ex + sgn * 1, ey - 1, ew)
			PAC.set_px(buf, near_ex - sgn * 1, ey, ew)
			PAC.set_px(buf, near_ex, ey, ep)
			PAC.set_px(buf, near_ex + sgn * 1, ey, ew)
			PAC.set_px(buf, near_ex - sgn * 1, ey + 1, olh)
			PAC.set_px(buf, near_ex, ey + 1, olh)

			PAC.set_px(buf, far_ex, ey - 2, ep)
			PAC.set_px(buf, far_ex - sgn * 1, ey - 1, ew)
			PAC.set_px(buf, far_ex, ey - 1, ep)
			PAC.set_px(buf, far_ex - sgn * 1, ey, ew)
			PAC.set_px(buf, far_ex, ey, ep)
			PAC.set_px(buf, far_ex, ey + 1, olh)
		PAC.set_px(buf, cx + sgn * 3, cy + 1, skin[3])
		PAC.set_px(buf, cx + sgn * 3, cy + 2, skin[0])
		if expr == "pained" or expr == "closed":
			for mx in range(-1, 3):
				PAC.set_px(buf, cx + sgn * mx, cy + 4, mline)
		else:
			PAC.set_px(buf, cx, cy + 4, mline)
			PAC.set_px(buf, cx + sgn * 1, cy + 4, teeth)
			PAC.set_px(buf, cx + sgn * 2, cy + 4, teeth)
			PAC.set_px(buf, cx + sgn * 3, cy + 4, teeth)
			PAC.set_px(buf, cx + sgn * 1, cy + 5, teeth)
			PAC.set_px(buf, cx + sgn * 2, cy + 5, mline)

	else:
		# Profile view ('left', 'right')
		var sgn: int = 1 if f.x >= 0.0 else -1
		var ex: int = cx + sgn * 4
		var ey: int = cy
		PAC.set_px(buf, ex, ey - 2, ep)
		PAC.set_px(buf, ex + sgn * 1, ey - 2, ep)
		if expr == "closed":
			PAC.set_px(buf, ex, ey, ep)
			PAC.set_px(buf, ex + sgn * 1, ey, ep)
		else:
			PAC.set_px(buf, ex, ey - 1, ew)
			PAC.set_px(buf, ex + sgn * 1, ey - 1, ep)
			PAC.set_px(buf, ex, ey, ew)
			PAC.set_px(buf, ex + sgn * 1, ey, ep)
			PAC.set_px(buf, ex, ey + 1, olh)
			PAC.set_px(buf, ex + sgn * 1, ey + 1, olh)
		if expr == "pained" or expr == "closed":
			PAC.set_px(buf, cx + sgn * 3, cy + 4, mline)
			PAC.set_px(buf, cx + sgn * 4, cy + 4, mline)
		else:
			PAC.set_px(buf, cx + sgn * 2, cy + 4, mline)
			PAC.set_px(buf, cx + sgn * 3, cy + 4, teeth)
			PAC.set_px(buf, cx + sgn * 4, cy + 4, teeth)
			PAC.set_px(buf, cx + sgn * 5, cy + 4, teeth)
			PAC.set_px(buf, cx + sgn * 3, cy + 5, mline)


## Draws classic sharp firefighter axe (bevelled trapezoidal steel blade + flat square red poll).
func _draw_axe(buf: Image, pal: Dictionary, g: Dictionary) -> void:
	var pommel: Vector2 = g["pommel"]
	var head_pt: Vector2 = g["head"]
	var axe_u: Vector2 = g["axe_u"]
	var bn: Vector2 = g["blade_normal"]

	# Rigid uniform wooden handle locked at hand grip
	PAC.draw_shaded_limb(buf, pommel, head_pt + axe_u * 2.2, 1.35, 1.35, pal["axe_wood"], 0.05)

	# Red painted square socket & poll on back side of head
	for s_u in range(-2, 3):
		for s_n in range(-3, 2):
			var px_v: Vector2 = head_pt + axe_u * float(s_u) * 0.85 + bn * float(s_n) * 0.85
			var col: Color = pal["axe_red"][2] if s_n >= 0 else pal["axe_red"][1]
			if s_u == 2:
				col = pal["axe_red"][3]
			PAC.set_px(buf, int(round(px_v.x)), int(round(px_v.y)), col)

	# Sleek curved silver cutting blade widening sharply toward edge
	for i in range(1, 7):
		var t: float = float(i) / 6.0
		var half_len: float = lerpf(1.6, 3.6, t)
		var steps: int = int(ceil(half_len * 3.0))
		for k in range(-steps, steps + 1):
			var u_off: float = (float(k) / maxf(1.0, float(steps))) * half_len
			var bp: Vector2 = head_pt + bn * (1.2 + float(i) * 0.72) + axe_u * u_off
			var col: Color = pal["axe_steel"][1]
			if i >= 5:
				col = pal["axe_steel"][3]
			elif i >= 3:
				col = pal["axe_steel"][2]
			PAC.set_px(buf, int(round(bp.x)), int(round(bp.y)), col)


func _draw_attack_vfx(vfx_dst: Image, pal: Dictionary, axe_geom: Dictionary, state: Dictionary, fi: int) -> void:
	if state.is_empty():
		return
	var vfx_pal: Array = pal["vfx"]
	var dark_edge: Color = vfx_pal[0]
	var orange_mid: Color = vfx_pal[1]
	var gold_bright: Color = vfx_pal[2]
	var core_hot: Color = vfx_pal[3]

	var pivot: Vector2 = axe_geom["pivot"]
	var wind: Dictionary = state["windup"]
	var imp: Dictionary = state["impact"]
	var flip_s: float = float(imp["flip_sign"])

	var tip_imp: Vector2 = imp["blade_tip"]
	var r_outer: float = clampf((tip_imp - pivot).length(), 19.0, 27.0)
	var a_end: float = (tip_imp - pivot).angle()
	var a_start: float = (wind["blade_tip"] as Vector2 - pivot).angle()

	var span: float = fmod(a_end - a_start, TAU)
	if flip_s > 0.0:
		if span <= 0.0:
			span += TAU
		if span > PI * 1.25:
			span = PI * 0.92
	else:
		if span >= 0.0:
			span -= TAU
		if span < -PI * 1.25:
			span = -PI * 0.92

	a_start = a_end - span

	if fi == 2:
		var steps: int = 76
		for s_i in range(steps + 1):
			var t: float = float(s_i) / float(steps)
			var th: float = a_start + span * t
			var radial: Vector2 = Vector2(cos(th), sin(th))
			var width: float = 0.6 + pow(t, 1.35) * 4.8
			var half_w: float = width * 0.5
			for dr in range(-int(ceil(width)), int(ceil(width)) + 2):
				var r_cur: float = r_outer - float(dr) * 0.65
				if r_cur < 10.0:
					continue
				var dist_norm: float = absf(float(dr) * 0.65 - half_w) / maxf(0.6, half_w + 0.5)
				if dist_norm <= 1.0:
					var px_p: Vector2 = pivot + radial * r_cur
					var col: Color = dark_edge
					if dist_norm < 0.34 and t > 0.32:
						col = core_hot
					elif dist_norm < 0.62 and t > 0.16:
						col = gold_bright
					elif dist_norm < 0.84:
						col = orange_mid
					PAC.set_px(vfx_dst, int(round(px_p.x)), int(round(px_p.y)), col)
		for sp_t in [0.58, 0.76, 0.92]:
			var th_s: float = a_start + span * sp_t
			var sp_p: Vector2 = pivot + Vector2(cos(th_s), sin(th_s)) * (r_outer + 2.2)
			PAC.set_px(vfx_dst, int(round(sp_p.x)), int(round(sp_p.y)), gold_bright if sp_t < 0.85 else core_hot)

	elif fi == 3:
		var steps: int = 44
		for s_i in range(steps + 1):
			var t: float = float(s_i) / float(steps)
			if t < 0.35 or (s_i % 5 >= 3):
				continue
			var th: float = a_start + span * t
			var r_cur: float = r_outer - (1.0 - t) * 1.5
			var px_p: Vector2 = pivot + Vector2(cos(th), sin(th)) * r_cur
			var col: Color = gold_bright if t > 0.72 else orange_mid
			PAC.set_px(vfx_dst, int(round(px_p.x)), int(round(px_p.y)), col)
			if t > 0.65 and s_i % 4 == 0:
				var sp_p: Vector2 = pivot + Vector2(cos(th), sin(th)) * (r_cur + 2.0)
				PAC.set_px(vfx_dst, int(round(sp_p.x)), int(round(sp_p.y)), dark_edge)


func _write_inspection_previews(preview_strips: Dictionary) -> void:
	var pad: int = 8
	var cell: int = CELL_W
	var panel_w: int = 8 * cell + pad * 9
	var panel_h: int = 4 * cell + pad * 5
	var sheet1 := Image.create(panel_w, panel_h, false, Image.FORMAT_RGBA8)
	_fill_checkerboard(sheet1)

	for vi in range(VARIANTS.size()):
		var v_id: String = VARIANTS[vi]
		var pal: Dictionary = _make_palette(v_id)
		for di in range(DIRECTIONS.size()):
			var d_name: String = DIRECTIONS[di]
			var pose: Dictionary = _build_pose("idle", 0, 6, d_name)
			var c_img: Image = PAC.create_cell()
			var v_img: Image = PAC.create_cell()
			_draw_character_cell(c_img, v_img, pal, pose, "idle", 0, d_name, {})
			var ox: int = pad + di * (cell + pad)
			var oy: int = pad + vi * (cell + pad)
			_alpha_blend_rect(sheet1, c_img, ox, oy)

	sheet1.save_png("%s/huwag_preview_4variants_8dirs.png" % ARTIFACT_PREVIEW_DIR)

	var rows: Array[Dictionary] = [
		{"var": "casual_day", "anim": "walk", "dir": "right"},
		{"var": "casual_day", "anim": "walk", "dir": "down"},
		{"var": "casual_day", "anim": "run", "dir": "right"},
		{"var": "casual_day", "anim": "attack", "dir": "right"},
		{"var": "casual_day", "anim": "attack", "dir": "down"},
		{"var": "casual_day", "anim": "hurt", "dir": "down_left"},
		{"var": "casual_day", "anim": "defeat", "dir": "right"},
		{"var": "casual_day", "anim": "defeat", "dir": "down"},
		{"var": "bfp_day", "anim": "attack", "dir": "right"},
		{"var": "casual_dark", "anim": "attack", "dir": "right"},
		{"var": "bfp_dark", "anim": "defeat", "dir": "right"},
	]
	var max_cols: int = 8
	var s2 := Image.create(max_cols * cell + (max_cols + 1) * 6, rows.size() * cell + (rows.size() + 1) * 6, false, Image.FORMAT_RGBA8)
	_fill_checkerboard(s2)
	for ri in range(rows.size()):
		var row_spec: Dictionary = rows[ri]
		var pkey: String = "%s|%s|%s" % [row_spec["var"], row_spec["anim"], row_spec["dir"]]
		if not preview_strips.has(pkey):
			continue
		var pack: Dictionary = preview_strips[pkey]
		var bfs: Array[Image] = pack["body_frames"]
		var vfs: Array[Image] = pack["vfx_frames"]
		for fi in range(bfs.size()):
			var comp: Image = bfs[fi].duplicate()
			PAC.blit_alpha(comp, vfs[fi])
			var ox: int = 6 + fi * (cell + 6)
			var oy: int = 6 + ri * (cell + 6)
			_alpha_blend_rect(s2, comp, ox, oy)

	s2.save_png("%s/huwag_96x96_approval_preview.png" % ARTIFACT_PREVIEW_DIR)


func _fill_checkerboard(img: Image) -> void:
	var c1 := Color.html("#2B2A33")
	var c2 := Color.html("#34333E")
	for y in range(img.get_height()):
		for x in range(img.get_width()):
			var checker: bool = (((x / 8) + (y / 8)) % 2) == 0
			img.set_pixel(x, y, c1 if checker else c2)


func _alpha_blend_rect(dst: Image, src: Image, ox: int, oy: int) -> void:
	for y in range(src.get_height()):
		for x in range(src.get_width()):
			var sc: Color = src.get_pixel(x, y)
			if sc.a <= 0.01:
				continue
			var dx: int = ox + x
			var dy: int = oy + y
			if dx >= 0 and dx < dst.get_width() and dy >= 0 and dy < dst.get_height():
				if sc.a >= 0.99:
					dst.set_pixel(dx, dy, sc)
				else:
					var dc: Color = dst.get_pixel(dx, dy)
					dst.set_pixel(dx, dy, dc.lerp(Color(sc.r, sc.g, sc.b, 1.0), sc.a))
