extends SceneTree

const GifEncoderScript = preload("res://scripts/tools/pixel_rig/gif89a_encoder.gd")

const BASE_DIR := "res://assets/sprites/huwag_v2"
const PREVIEW_OUT_PATH := "C:/Users/SnyX/.gemini/antigravity/brain/41e1f3b5-4735-42d2-bd7e-9b58f3903223/huwag_v2_normalized_preview.png"

const CELL_SIZE: int = 96
const TARGET_CHAR_HEIGHT: int = 80
const FOOT_ANCHOR_X: int = 48
const FOOT_ANCHOR_Y: int = 90
const WALK_FPS: float = 8.0
const GIF_DELAYS_CS: Array[int] = [13, 12, 13, 12]
const DIRECTIONS := ["down", "up", "left", "right"]

# Matches process_huwag_v2_sheets.py:
# side walk cycles use natively drawn LEFT frames [r2c0, r3c3, r2c0, r3c0]
# and mirror them horizontally for RIGHT frames.
const DIRECTION_MAP := {
	"down": [[0, 0, false], [0, 1, false], [0, 2, false], [0, 3, false]],
	"up": [[1, 0, false], [1, 1, false], [1, 2, false], [1, 3, false]],
	"left": [[2, 0, false], [3, 3, false], [2, 0, false], [3, 0, false]],
	"right": [[2, 0, true], [3, 3, true], [2, 0, true], [3, 0, true]],
}

const OUTFITS := [
	{"name": "bombeiro", "raw": "res://assets/sprites/huwag_v2/raw/huwag_bombeiro_raw_v5.jpg"},
	{"name": "casual", "raw": "res://assets/sprites/huwag_v2/raw/huwag_casual_raw_v1.jpg"},
]


func _init() -> void:
	var user_args := OS.get_cmdline_user_args()
	var phase := "images"
	for arg in user_args:
		if arg.begins_with("--phase="):
			phase = arg.trim_prefix("--phase=")

	if phase == "spriteframes":
		var ok := _build_all_spriteframes()
		quit(0 if ok else 1)
		return
	if phase == "verify":
		var ok_v := _verify_spriteframes()
		quit(0 if ok_v else 1)
		return

	var ok_img := _process_all_images()
	quit(0 if ok_img else 1)


func _process_all_images() -> bool:
	var prepared: Array = []
	var ref_heights: Array[float] = []

	for cfg in OUTFITS:
		var outfit_name: String = str(cfg["name"])
		var raw_path: String = ProjectSettings.globalize_path(str(cfg["raw"]))
		var raw_img := Image.new()
		var err := raw_img.load(raw_path)
		if err != OK:
			push_error("Failed loading raw sheet %s: err=%d" % [raw_path, err])
			return false
		raw_img.convert(Image.FORMAT_RGBA8)
		var clean_img := _remove_chromakey_and_despill(raw_img)
		var grid := _segment_4x4_cells(clean_img)

		var cells: Array = []
		var metrics: Array = []
		var baselines: Array[float] = []
		for r in range(4):
			var row_cells: Array = []
			var row_metrics: Array = []
			var max_bottom: float = 0.0
			for c in range(4):
				var rect: Rect2i = grid[r][c]
				var crop := Image.create(rect.size.x, rect.size.y, false, Image.FORMAT_RGBA8)
				crop.blit_rect(clean_img, rect, Vector2i.ZERO)
				var m := _measure_foreground_metrics(crop)
				row_cells.append(crop)
				row_metrics.append(m)
				max_bottom = maxf(max_bottom, float(m["max_y"]) + 1.0)
			cells.append(row_cells)
			metrics.append(row_metrics)
			baselines.append(max_bottom)

		ref_heights.append(float(metrics[0][0]["height"]))
		prepared.append({
			"name": outfit_name,
			"cells": cells,
			"metrics": metrics,
			"baselines": baselines,
		})

	var avg_ref_h: float = 0.0
	for h in ref_heights:
		avg_ref_h += h
	avg_ref_h /= maxf(1.0, float(ref_heights.size()))
	var global_scale: float = float(TARGET_CHAR_HEIGHT) / maxf(1.0, avg_ref_h)
	print("Global uniform raw->96x96 scale: %.6f (ref_height=%.2f px)" % [global_scale, avg_ref_h])

	var sheets_for_preview: Dictionary = {}
	for entry in prepared:
		var outfit_name: String = str(entry["name"])
		var out_dir := "%s/%s" % [BASE_DIR, outfit_name]
		var abs_out := ProjectSettings.globalize_path(out_dir)
		DirAccess.make_dir_recursive_absolute(abs_out)
		DirAccess.make_dir_recursive_absolute(abs_out + "/gifs")

		var cells: Array = entry["cells"]
		var metrics: Array = entry["metrics"]
		var baselines: Array[float] = entry["baselines"]

		var cut_cache: Dictionary = {}
		var all_frames: Array[Image] = []
		for d in DIRECTIONS:
			var specs: Array = DIRECTION_MAP[d]
			for spec in specs:
				var r: int = int(spec[0])
				var c: int = int(spec[1])
				var flip: bool = bool(spec[2])
				var key := "%d_%d_%s" % [r, c, "1" if flip else "0"]
				if cut_cache.has(key):
					continue
				var m: Dictionary = metrics[r][c]
				var frame := _downsample_crisp_cell(cells[r][c], global_scale, float(m["cx"]), baselines[r])
				if flip:
					frame.flip_x()
				cut_cache[key] = frame
				all_frames.append(frame)

		var unique_colors := _deduplicate_palette(all_frames, 12, 180)
		var sheet := Image.create(CELL_SIZE * 4, CELL_SIZE * 4, false, Image.FORMAT_RGBA8)
		var anims_meta: Dictionary = {}

		for r_idx in range(DIRECTIONS.size()):
			var d: String = DIRECTIONS[r_idx]
			var walk_frames: Array[Image] = []
			for spec in DIRECTION_MAP[d]:
				var key := "%d_%d_%s" % [int(spec[0]), int(spec[1]), "1" if bool(spec[2]) else "0"]
				walk_frames.append(cut_cache[key])

			var idle_file := "huwag_idle_%s.png" % d
			walk_frames[0].save_png(abs_out + "/" + idle_file)
			anims_meta["idle_%s" % d] = {"file": idle_file, "frames": 1, "fps": int(WALK_FPS), "loop": false}

			var walk_strip := Image.create(CELL_SIZE * 4, CELL_SIZE, false, Image.FORMAT_RGBA8)
			for col in range(4):
				var frm: Image = walk_frames[col]
				walk_strip.blit_rect(frm, Rect2i(0, 0, CELL_SIZE, CELL_SIZE), Vector2i(col * CELL_SIZE, 0))
				sheet.blit_rect(frm, Rect2i(0, 0, CELL_SIZE, CELL_SIZE), Vector2i(col * CELL_SIZE, r_idx * CELL_SIZE))

			var walk_file := "huwag_walk_%s.png" % d
			walk_strip.save_png(abs_out + "/" + walk_file)
			anims_meta["walk_%s" % d] = {"file": walk_file, "frames": 4, "fps": int(WALK_FPS), "loop": true}

			var gif_path := abs_out + ("/gifs/huwag_walk_%s.gif" % d)
			var gif_err := GifEncoderScript.save_animated_gif(gif_path, walk_frames, GIF_DELAYS_CS, 2)
			if gif_err != OK:
				push_error("Failed encoding GIF %s: err=%d" % [gif_path, gif_err])
				return false

		var sheet_file := "huwag_%s_sheet_96x96.png" % outfit_name
		sheet.save_png(abs_out + "/" + sheet_file)
		sheets_for_preview[outfit_name] = sheet

		var measured_standing := _measure_foreground_metrics(cut_cache["0_0_0"])
		var atlas_dict := {
			"character": "Huwag",
			"outfit": outfit_name,
			"cell_size": [CELL_SIZE, CELL_SIZE],
			"foot_anchor": [FOOT_ANCHOR_X, FOOT_ANCHOR_Y],
			"target_height_px": TARGET_CHAR_HEIGHT,
			"measured_standing_bbox_height_px": int(measured_standing["height"]),
			"scale_from_raw": snapped(global_scale, 0.000001),
			"unique_palette_colors": unique_colors,
			"sheet_file": sheet_file,
			"animations": anims_meta,
		}
		var json_file := FileAccess.open(abs_out + "/huwag_atlas.json", FileAccess.WRITE)
		if json_file == null:
			push_error("Failed writing huwag_atlas.json for %s" % outfit_name)
			return false
		json_file.store_string(JSON.stringify(atlas_dict, "  ") + "\n")
		json_file.close()
		print("Exported %s: %d palette colors, standing bbox height=%dpx" % [
			outfit_name, unique_colors, int(measured_standing["height"])
		])

	_save_comparison_preview(sheets_for_preview["bombeiro"], sheets_for_preview["casual"])
	return true


func _build_all_spriteframes() -> bool:
	for cfg in OUTFITS:
		var outfit_name: String = str(cfg["name"])
		var out_dir := "%s/%s" % [BASE_DIR, outfit_name]
		var sheet_res_path := "%s/huwag_%s_sheet_96x96.png" % [out_dir, outfit_name]
		var tex := ResourceLoader.load(sheet_res_path) as Texture2D
		if tex == null:
			push_error("Texture not imported yet at %s. Run Godot --import first." % sheet_res_path)
			return false

		var sf := SpriteFrames.new()
		if sf.has_animation("default"):
			sf.remove_animation("default")

		for r_idx in range(DIRECTIONS.size()):
			var d: String = DIRECTIONS[r_idx]
			var idle_anim := "idle_%s" % d
			sf.add_animation(idle_anim)
			sf.set_animation_loop(idle_anim, false)
			sf.set_animation_speed(idle_anim, WALK_FPS)
			var idle_at := AtlasTexture.new()
			idle_at.atlas = tex
			idle_at.region = Rect2(0, r_idx * CELL_SIZE, CELL_SIZE, CELL_SIZE)
			sf.add_frame(idle_anim, idle_at)

			var walk_anim := "walk_%s" % d
			sf.add_animation(walk_anim)
			sf.set_animation_loop(walk_anim, true)
			sf.set_animation_speed(walk_anim, WALK_FPS)
			for col in range(4):
				var walk_at := AtlasTexture.new()
				walk_at.atlas = tex
				walk_at.region = Rect2(col * CELL_SIZE, r_idx * CELL_SIZE, CELL_SIZE, CELL_SIZE)
				sf.add_frame(walk_anim, walk_at)

		var tres_path := "%s/huwag_%s_spriteframes.tres" % [out_dir, outfit_name]
		var err := ResourceSaver.save(sf, tres_path)
		if err != OK:
			push_error("Failed saving SpriteFrames %s: err=%d" % [tres_path, err])
			return false
		print("Saved SpriteFrames: %s (%d animations)" % [tres_path, sf.get_animation_names().size()])
	return true


func _verify_spriteframes() -> bool:
	for cfg in OUTFITS:
		var outfit_name: String = str(cfg["name"])
		var tres_path := "%s/%s/huwag_%s_spriteframes.tres" % [BASE_DIR, outfit_name, outfit_name]
		var sf := ResourceLoader.load(tres_path) as SpriteFrames
		if sf == null:
			push_error("Failed loading SpriteFrames at %s" % tres_path)
			return false
		var names: PackedStringArray = sf.get_animation_names()
		if names.size() != 8:
			push_error("Unexpected animation count %d in %s" % [names.size(), tres_path])
			return false
		for d in DIRECTIONS:
			var idle_anim := "idle_%s" % d
			var walk_anim := "walk_%s" % d
			if not sf.has_animation(idle_anim) or sf.get_frame_count(idle_anim) != 1 or sf.get_animation_loop(idle_anim):
				push_error("Invalid %s in %s" % [idle_anim, tres_path])
				return false
			if not sf.has_animation(walk_anim) or sf.get_frame_count(walk_anim) != 4 or not sf.get_animation_loop(walk_anim):
				push_error("Invalid %s in %s" % [walk_anim, tres_path])
				return false
			if sf.get_frame_texture(idle_anim, 0) == null:
				push_error("Null texture on %s in %s" % [idle_anim, tres_path])
				return false
			for fi in range(4):
				if sf.get_frame_texture(walk_anim, fi) == null:
					push_error("Null texture on %s frame %d in %s" % [walk_anim, fi, tres_path])
					return false
		print("VERIFIED %s: animations=%s" % [tres_path, ", ".join(names)])
	return true


func _is_chromakey_green(r: int, g: int, b: int) -> bool:
	var max_rb := maxi(r, b)
	var excess := g - max_rb
	if g > 110 and excess >= 48 and max_rb < 145:
		return true
	if g > 55 and excess >= 36 and r < 55 and b < 55:
		return true
	return false


func _remove_chromakey_and_despill(src: Image) -> Image:
	var w: int = src.get_width()
	var h: int = src.get_height()
	var data: PackedByteArray = src.get_data()
	var alpha_mask := PackedByteArray()
	alpha_mask.resize(w * h)

	for y in range(h):
		for x in range(w):
			var p := y * w + x
			var idx := p * 4
			var r: int = data[idx]
			var g: int = data[idx + 1]
			var b: int = data[idx + 2]
			if _is_chromakey_green(r, g, b):
				alpha_mask[p] = 0
				data[idx] = 0
				data[idx + 1] = 0
				data[idx + 2] = 0
				data[idx + 3] = 0
			else:
				alpha_mask[p] = 255
				data[idx + 3] = 255

	# Pass 2: despill fringe pixels touching transparency within 2 px
	for y in range(h):
		for x in range(w):
			var p := y * w + x
			if alpha_mask[p] == 0:
				continue
			var touches_bg := false
			for dy in range(-2, 3):
				var ny := y + dy
				if ny < 0 or ny >= h:
					touches_bg = true
					break
				for dx in range(-2, 3):
					var nx := x + dx
					if nx < 0 or nx >= w or alpha_mask[ny * w + nx] == 0:
						touches_bg = true
						break
				if touches_bg:
					break
			if not touches_bg:
				continue
			var idx := p * 4
			var r: int = data[idx]
			var g: int = data[idx + 1]
			var b: int = data[idx + 2]
			var max_rb := maxi(r, b)
			if g - max_rb > 14:
				data[idx + 1] = mini(g, max_rb)

	return Image.create_from_data(w, h, false, Image.FORMAT_RGBA8, data)


func _find_contiguous_bands(counts: Array[int], min_pixels: int, max_gap: int) -> Array:
	var bands: Array = []
	var in_band := false
	var start: int = 0
	var last_fg: int = 0
	for idx in range(counts.size()):
		if counts[idx] >= min_pixels:
			if not in_band:
				in_band = true
				start = idx
			last_fg = idx
		elif in_band and (idx - last_fg) > max_gap:
			bands.append([start, last_fg])
			in_band = false
	if in_band:
		bands.append([start, last_fg])
	return bands


func _segment_4x4_cells(img: Image) -> Array:
	var w: int = img.get_width()
	var h: int = img.get_height()
	var data: PackedByteArray = img.get_data()

	var row_counts: Array[int] = []
	row_counts.resize(h)
	var col_counts: Array[int] = []
	col_counts.resize(w)

	for y in range(h):
		for x in range(w):
			if data[(y * w + x) * 4 + 3] > 0:
				row_counts[y] += 1
				col_counts[x] += 1

	var y_bands := _find_contiguous_bands(row_counts, 8, 3)
	var x_bands := _find_contiguous_bands(col_counts, 8, 3)

	var y_splits: Array[int] = [0]
	if y_bands.size() == 4:
		for i in range(3):
			y_splits.append((int(y_bands[i][1]) + int(y_bands[i + 1][0])) / 2)
		y_splits.append(h)
	else:
		for i in range(1, 5):
			y_splits.append(roundi(float(i * h) / 4.0))

	var x_splits: Array[int] = [0]
	if x_bands.size() == 4:
		for i in range(3):
			x_splits.append((int(x_bands[i][1]) + int(x_bands[i + 1][0])) / 2)
		x_splits.append(w)
	else:
		for i in range(1, 5):
			x_splits.append(roundi(float(i * w) / 4.0))

	var grid: Array = []
	for r in range(4):
		var row_rects: Array = []
		for c in range(4):
			row_rects.append(Rect2i(
				x_splits[c], y_splits[r],
				x_splits[c + 1] - x_splits[c], y_splits[r + 1] - y_splits[r]
			))
		grid.append(row_rects)
	return grid


func _measure_foreground_metrics(cell: Image) -> Dictionary:
	var w: int = cell.get_width()
	var h: int = cell.get_height()
	var data: PackedByteArray = cell.get_data()
	var min_x: int = w
	var min_y: int = h
	var max_x: int = -1
	var max_y: int = -1

	for y in range(h):
		for x in range(w):
			if data[(y * w + x) * 4 + 3] > 0:
				min_x = mini(min_x, x)
				min_y = mini(min_y, y)
				max_x = maxi(max_x, x)
				max_y = maxi(max_y, y)

	if max_x < min_x:
		return {"min_x": 0, "min_y": 0, "max_x": w - 1, "max_y": h - 1, "cx": float(w) * 0.5, "height": float(h)}

	var band_top: int = maxi(min_y, max_y - maxi(6, int(float(max_y - min_y + 1) * 0.08)))
	var sum_x: float = 0.0
	var count: int = 0
	for y in range(band_top, max_y + 1):
		for x in range(min_x, max_x + 1):
			if data[(y * w + x) * 4 + 3] > 0:
				sum_x += float(x)
				count += 1
	var cx: float = (sum_x / float(count)) + 0.5 if count > 0 else float(min_x + max_x + 1) * 0.5
	return {
		"min_x": min_x,
		"min_y": min_y,
		"max_x": max_x,
		"max_y": max_y,
		"cx": cx,
		"height": float(max_y - min_y + 1),
	}


func _downsample_crisp_cell(cell: Image, scale: float, anchor_src_x: float, anchor_src_y: float) -> Image:
	var w: int = cell.get_width()
	var h: int = cell.get_height()
	var src: PackedByteArray = cell.get_data()
	var dst := PackedByteArray()
	dst.resize(CELL_SIZE * CELL_SIZE * 4)

	var half_fp: float = maxf(0.75, 0.5 / scale)
	for dy in range(CELL_SIZE):
		var sy_center: float = anchor_src_y + (float(dy) + 0.5 - float(FOOT_ANCHOR_Y)) / scale
		var sy0: int = maxi(0, floori(sy_center - half_fp))
		var sy1: int = mini(h - 1, ceili(sy_center + half_fp))
		for dx in range(CELL_SIZE):
			if sy1 < sy0:
				continue
			var sx_center: float = anchor_src_x + (float(dx) + 0.5 - float(FOOT_ANCHOR_X)) / scale
			var sx0: int = maxi(0, floori(sx_center - half_fp))
			var sx1: int = mini(w - 1, ceili(sx_center + half_fp))
			if sx1 < sx0:
				continue

			var opaque: Array = []
			var darks: Array = []
			var total: int = 0
			for sy in range(sy0, sy1 + 1):
				for sx in range(sx0, sx1 + 1):
					total += 1
					var s_idx := (sy * w + sx) * 4
					if src[s_idx + 3] >= 128:
						var rgb := [int(src[s_idx]), int(src[s_idx + 1]), int(src[s_idx + 2])]
						opaque.append(rgb)
						if maxi(rgb[0], maxi(rgb[1], rgb[2])) <= 28:
							darks.append(rgb)

			if total == 0 or (float(opaque.size()) / float(total)) < 0.42:
				continue

			var d_idx := (dy * CELL_SIZE + dx) * 4
			if darks.size() > 0 and (float(darks.size()) / float(opaque.size())) >= 0.30:
				var best_d: Array = darks[0]
				var best_sum: int = int(best_d[0]) + int(best_d[1]) + int(best_d[2])
				for col in darks:
					var s: int = int(col[0]) + int(col[1]) + int(col[2])
					if s < best_sum:
						best_sum = s
						best_d = col
				dst[d_idx] = int(best_d[0])
				dst[d_idx + 1] = int(best_d[1])
				dst[d_idx + 2] = int(best_d[2])
				dst[d_idx + 3] = 255
				continue

			var cx_i := clampi(roundi(sx_center), 0, w - 1)
			var cy_i := clampi(roundi(sy_center), 0, h - 1)
			var c_idx := (cy_i * w + cx_i) * 4
			if src[c_idx + 3] >= 128 and maxi(src[c_idx], maxi(src[c_idx + 1], src[c_idx + 2])) > 28:
				dst[d_idx] = src[c_idx]
				dst[d_idx + 1] = src[c_idx + 1]
				dst[d_idx + 2] = src[c_idx + 2]
				dst[d_idx + 3] = 255
			else:
				var pool: Array = []
				for col in opaque:
					if maxi(int(col[0]), maxi(int(col[1]), int(col[2]))) > 28:
						pool.append(col)
				if pool.is_empty():
					pool = opaque
				var best_m: Array = pool[0]
				var best_dist: int = 1 << 30
				for a_col in pool:
					var sum_d: int = 0
					for b_col in pool:
						sum_d += absi(int(a_col[0]) - int(b_col[0])) + absi(int(a_col[1]) - int(b_col[1])) + absi(int(a_col[2]) - int(b_col[2]))
					if sum_d < best_dist:
						best_dist = sum_d
						best_m = a_col
				dst[d_idx] = int(best_m[0])
				dst[d_idx + 1] = int(best_m[1])
				dst[d_idx + 2] = int(best_m[2])
				dst[d_idx + 3] = 255

	return Image.create_from_data(CELL_SIZE, CELL_SIZE, false, Image.FORMAT_RGBA8, dst)


func _deduplicate_palette(frames: Array[Image], max_l1_merge: int, target_max_colors: int = 180) -> int:
	var freq: Dictionary = {}
	for frame in frames:
		var data := frame.get_data()
		for i in range(0, data.size(), 4):
			if data[i + 3] >= 128:
				var key: int = (int(data[i]) << 16) | (int(data[i + 1]) << 8) | int(data[i + 2])
				freq[key] = int(freq.get(key, 0)) + 1

	var entries: Array = []
	for key in freq.keys():
		entries.append({"key": int(key), "count": int(freq[key])})
	entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["count"]) > int(b["count"]))

	var palette: Array[int] = []
	var remap: Dictionary = {}
	for entry in entries:
		var col: int = int(entry["key"])
		var r1: int = (col >> 16) & 0xFF
		var g1: int = (col >> 8) & 0xFF
		var b1: int = col & 0xFF
		var found: int = -1
		for pcol in palette:
			var r2: int = (pcol >> 16) & 0xFF
			var g2: int = (pcol >> 8) & 0xFF
			var b2: int = pcol & 0xFF
			if absi(r1 - r2) + absi(g1 - g2) + absi(b1 - b2) <= max_l1_merge:
				found = pcol
				break
		if found == -1:
			palette.append(col)
			remap[col] = col
		else:
			remap[col] = found

	if palette.size() > target_max_colors:
		var kept: Array[int] = palette.slice(0, target_max_colors)
		var kept_set: Dictionary = {}
		for kcol in kept:
			kept_set[kcol] = true
		for orig_key in remap.keys():
			var mapped_key: int = int(remap[orig_key])
			if kept_set.has(mapped_key):
				continue
			var mr: int = (mapped_key >> 16) & 0xFF
			var mg: int = (mapped_key >> 8) & 0xFF
			var mb: int = mapped_key & 0xFF
			var best_col: int = kept[0]
			var best_d: int = 1 << 30
			for pcol in kept:
				var pr: int = (pcol >> 16) & 0xFF
				var pg: int = (pcol >> 8) & 0xFF
				var pb: int = pcol & 0xFF
				var d: int = absi(mr - pr) + absi(mg - pg) + absi(mb - pb)
				if d < best_d:
					best_d = d
					best_col = pcol
			remap[orig_key] = best_col
		palette = kept

	for frame in frames:
		var data := frame.get_data()
		for i in range(0, data.size(), 4):
			if data[i + 3] >= 128:
				var key: int = (int(data[i]) << 16) | (int(data[i + 1]) << 8) | int(data[i + 2])
				var mapped: int = int(remap[key])
				data[i] = (mapped >> 16) & 0xFF
				data[i + 1] = (mapped >> 8) & 0xFF
				data[i + 2] = mapped & 0xFF
				data[i + 3] = 255
			else:
				data[i] = 0
				data[i + 1] = 0
				data[i + 2] = 0
				data[i + 3] = 0
		frame.set_data(frame.get_width(), frame.get_height(), false, Image.FORMAT_RGBA8, data)

	return palette.size()


func _save_comparison_preview(bombeiro_sheet: Image, casual_sheet: Image) -> void:
	# Side-by-side 2x nearest preview over subtle dark checkerboard so transparency and edges are obvious.
	var sw: int = bombeiro_sheet.get_width()
	var sh: int = bombeiro_sheet.get_height()
	var canvas_w: int = (sw * 2 + 16) * 2
	var canvas_h: int = (sh + 16) * 2
	var preview := Image.create(canvas_w, canvas_h, false, Image.FORMAT_RGBA8)
	var data := preview.get_data()
	for y in range(canvas_h):
		for x in range(canvas_w):
			var checker: bool = (((x / 16) + (y / 16)) % 2) == 0
			var c: int = 38 if checker else 52
			var idx := (y * canvas_w + x) * 4
			data[idx] = c
			data[idx + 1] = c + 2
			data[idx + 2] = c + 5
			data[idx + 3] = 255
	preview.set_data(canvas_w, canvas_h, false, Image.FORMAT_RGBA8, data)

	var b2 := bombeiro_sheet.duplicate()
	b2.resize(sw * 2, sh * 2, Image.INTERPOLATE_NEAREST)
	var c2 := casual_sheet.duplicate()
	c2.resize(sw * 2, sh * 2, Image.INTERPOLATE_NEAREST)
	preview.blend_rect(b2, Rect2i(0, 0, b2.get_width(), b2.get_height()), Vector2i(16, 16))
	preview.blend_rect(c2, Rect2i(0, 0, c2.get_width(), c2.get_height()), Vector2i(16 + sw * 2 + 16, 16))
	preview.save_png(PREVIEW_OUT_PATH)
