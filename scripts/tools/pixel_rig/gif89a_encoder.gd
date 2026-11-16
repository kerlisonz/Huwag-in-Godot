class_name Gif89aEncoder
extends RefCounted

## Native GIF89a animated encoder with binary transparency (Disposal = 2).
## Encodes RGBA Images directly in GDScript 4 using exact variable-bit LZW.


## Saves an array of RGBA images as a looping transparent animated GIF89a.
static func save_animated_gif(
	path: String,
	frames: Array[Image],
	delays_cs: Array[int],
	scale: int = 1
) -> Error:
	if frames.is_empty():
		return ERR_INVALID_DATA

	var scaled_frames: Array[Image] = []
	for src in frames:
		var img: Image = src
		if scale > 1:
			img = src.duplicate()
			img.resize(src.get_width() * scale, src.get_height() * scale, Image.INTERPOLATE_NEAREST)
		scaled_frames.append(img)

	var w: int = scaled_frames[0].get_width()
	var h: int = scaled_frames[0].get_height()

	# Index 0 is reserved strictly for transparent pixels (alpha < 128).
	var palette: Array[Color] = [Color(0, 0, 0, 0)]
	var color_map: Dictionary = {}

	for img in scaled_frames:
		for y in range(h):
			for x in range(w):
				var c: Color = img.get_pixel(x, y)
				if c.a < 0.5:
					continue
				var rgb_key: int = (c.r8 << 16) | (c.g8 << 8) | c.b8
				if not color_map.has(rgb_key):
					if palette.size() < 256:
						color_map[rgb_key] = palette.size()
						palette.append(c)

	var bytes := PackedByteArray()
	_write_ascii(bytes, "GIF89a")

	# Logical Screen Descriptor: Global Color Table = 256 entries, 8-bit color resolution
	_write_u16(bytes, w)
	_write_u16(bytes, h)
	bytes.append(0xF7) # GCT flag (1), color res (7), sort (0), size (7 -> 2^(7+1) = 256)
	bytes.append(0x00) # Background color index (transparent)
	bytes.append(0x00) # Pixel aspect ratio

	# Global Color Table (256 * 3 bytes)
	for i in range(256):
		if i < palette.size():
			var pc: Color = palette[i]
			bytes.append(pc.r8)
			bytes.append(pc.g8)
			bytes.append(pc.b8)
		else:
			bytes.append(0)
			bytes.append(0)
			bytes.append(0)

	# Netscape 2.0 Application Extension for infinite looping
	bytes.append(0x21)
	bytes.append(0xFF)
	bytes.append(0x0B)
	_write_ascii(bytes, "NETSCAPE2.0")
	bytes.append(0x03)
	bytes.append(0x01)
	_write_u16(bytes, 0) # Loop forever
	bytes.append(0x00)

	# Encode each frame
	for f_idx in range(scaled_frames.size()):
		var img: Image = scaled_frames[f_idx]
		var delay: int = delays_cs[f_idx] if f_idx < delays_cs.size() else 10

		# Graphic Control Extension: Disposal = 2 (restore bg/transparent), Transparent = 1
		bytes.append(0x21)
		bytes.append(0xF9)
		bytes.append(0x04)
		bytes.append(0x09)
		_write_u16(bytes, delay)
		bytes.append(0x00) # Transparent color index 0
		bytes.append(0x00)

		# Image Descriptor
		bytes.append(0x2C)
		_write_u16(bytes, 0)
		_write_u16(bytes, 0)
		_write_u16(bytes, w)
		_write_u16(bytes, h)
		bytes.append(0x00) # No local color table

		# Indexed pixel buffer
		var pixels := PackedByteArray()
		pixels.resize(w * h)
		var p_offset: int = 0
		for y in range(h):
			for x in range(w):
				var c: Color = img.get_pixel(x, y)
				if c.a < 0.5:
					pixels[p_offset] = 0
				else:
					var rgb_key: int = (c.r8 << 16) | (c.g8 << 8) | c.b8
					if color_map.has(rgb_key):
						pixels[p_offset] = int(color_map[rgb_key])
					else:
						pixels[p_offset] = _find_nearest_palette_idx(c, palette)
				p_offset += 1

		# Variable-bit LZW stream (min_code_size = 8)
		bytes.append(8)
		var lzw_data := _encode_lzw(pixels, 8)
		var pos: int = 0
		while pos < lzw_data.size():
			var chunk_len: int = mini(255, lzw_data.size() - pos)
			bytes.append(chunk_len)
			for ci in range(chunk_len):
				bytes.append(lzw_data[pos + ci])
			pos += chunk_len
		bytes.append(0x00) # Block terminator

	bytes.append(0x3B) # GIF Trailer

	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_buffer(bytes)
	file.close()
	return OK


static func _encode_lzw(pixels: PackedByteArray, min_code_size: int) -> PackedByteArray:
	var clear_code: int = 1 << min_code_size
	var eoi_code: int = clear_code + 1
	var next_code: int = eoi_code + 1
	var code_size: int = min_code_size + 1

	var dict: Dictionary = {}
	var bit_buf: int = 0
	var bit_count: int = 0
	var out := PackedByteArray()

	# Emit initial Clear code
	bit_buf |= clear_code << bit_count
	bit_count += code_size
	while bit_count >= 8:
		out.append(bit_buf & 0xFF)
		bit_buf >>= 8
		bit_count -= 8

	var prefix: int = int(pixels[0])
	for i in range(1, pixels.size()):
		var k: int = int(pixels[i])
		var key: int = (prefix << 8) | k
		if dict.has(key):
			prefix = int(dict[key])
		else:
			bit_buf |= prefix << bit_count
			bit_count += code_size
			while bit_count >= 8:
				out.append(bit_buf & 0xFF)
				bit_buf >>= 8
				bit_count -= 8

			if next_code < 4096:
				dict[key] = next_code
				if next_code == (1 << code_size) and code_size < 12:
					code_size += 1
				next_code += 1
			else:
				bit_buf |= clear_code << bit_count
				bit_count += code_size
				while bit_count >= 8:
					out.append(bit_buf & 0xFF)
					bit_buf >>= 8
					bit_count -= 8
				dict.clear()
				next_code = eoi_code + 1
				code_size = min_code_size + 1

			prefix = k

	# Emit final prefix
	bit_buf |= prefix << bit_count
	bit_count += code_size
	while bit_count >= 8:
		out.append(bit_buf & 0xFF)
		bit_buf >>= 8
		bit_count -= 8

	# Sync decoder code-size increment for final implied entry before EOI
	if next_code == (1 << code_size) and code_size < 12:
		code_size += 1

	bit_buf |= eoi_code << bit_count
	bit_count += code_size
	while bit_count >= 8:
		out.append(bit_buf & 0xFF)
		bit_buf >>= 8
		bit_count -= 8

	if bit_count > 0:
		out.append(bit_buf & 0xFF)

	return out


static func _find_nearest_palette_idx(c: Color, palette: Array[Color]) -> int:
	var best_idx: int = 1
	var best_dist: float = 1e9
	for i in range(1, palette.size()):
		var p: Color = palette[i]
		var dr: float = float(c.r8 - p.r8)
		var dg: float = float(c.g8 - p.g8)
		var db: float = float(c.b8 - p.b8)
		var d: float = dr * dr + dg * dg + db * db
		if d < best_dist:
			best_dist = d
			best_idx = i
	return best_idx


static func _write_ascii(buf: PackedByteArray, s: String) -> void:
	for i in range(s.length()):
		buf.append(s.unicode_at(i))


static func _write_u16(buf: PackedByteArray, val: int) -> void:
	buf.append(val & 0xFF)
	buf.append((val >> 8) & 0xFF)
