extends SceneTree

const BRAIN_DIR := "C:/Users/SnyX/.gemini/antigravity/brain/57f4ed94-3583-41fc-bbbe-9e9a2d546794"
const OUT_DIR := "res://assets/characters/portraits"
const LEGACY_SPRITE_PORTRAITS_DIR := "res://assets/sprites/portraits"
const SCRATCH_SHEET := "C:/Users/SnyX/.gemini/antigravity/brain/57f4ed94-3583-41fc-bbbe-9e9a2d546794/scratch/portraits_contact_sheet.png"
const TARGET_SIZE := 96


func _init() -> void:
	print("=== Processando 48 Retratos RGBA 96x96 (Fundo 100% Transparente) ===")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(LEGACY_SPRITE_PORTRAITS_DIR))

	var normal_busts: Dictionary = {}

	# 1. Extrair os 10 bustos gerados por IA com Chroma-Key + Despill + BFS
	var ai_sources: Array[Dictionary] = [
		{"id": "cap_reyes", "file": "capitao_reyes_bust_1795071096104.jpg", "key": "magenta", "max_h": 92},
		{"id": "enfermeira_maria", "file": "enfermeira_maria_portrait_v2_1795071224334.jpg", "key": "magenta", "max_h": 92},
		{"id": "bombeiro_ato", "file": "bombeiro_ato_portrait_1795071307154.jpg", "key": "magenta", "max_h": 92},
		{"id": "bombeiro_santos", "file": "bombeiro_santos_portrait_1795071388843.jpg", "key": "magenta", "max_h": 92},
		{"id": "aling_nena", "file": "aling_nena_portrait_1795071781516.jpg", "key": "magenta", "max_h": 92},
		{"id": "kuya_ben", "file": "kuya_ben_portrait_1795071924183.jpg", "key": "magenta", "max_h": 92},
		{"id": "feirante", "file": "mang_tomas_portrait_1795071999637.jpg", "key": "magenta", "max_h": 92},
		{"id": "mang_carding", "file": "mang_carding_portrait_1795072112074.jpg", "key": "magenta", "max_h": 92},
		{"id": "criatura_lagoa", "file": "portrait_lagoon_raw_1795070656992.jpg", "key": "magenta", "max_h": 92},
		{"id": "santelmo", "file": "santelmon_portrait_green_1795070995682.jpg", "key": "green", "max_h": 92},
	]

	for entry in ai_sources:
		var cid: String = str(entry["id"])
		var raw_path := "%s/%s" % [BRAIN_DIR, str(entry["file"])]
		var im := _extract_chromakey_bust(raw_path, str(entry["key"]), int(entry["max_h"]))
		normal_busts[cid] = im
		_save_png("%s/fnaf_%s.png" % [OUT_DIR, cid], im)

	# 2. Compor os 5 retratos complementares em estilo pixel-art coerente 96x96
	var custom_map: Dictionary = {
		"luningning": _compose_luningning_96(),
		"lola_rosa": _compose_lola_rosa_96(),
		"toby": _compose_toby_96(),
		"vulto_bosque": _compose_vulto_bosque_96(),
		"vhs_radio": _compose_vhs_radio_96(),
	}
	for cid in custom_map.keys():
		var custom_im: Image = custom_map[cid]
		normal_busts[cid] = custom_im
		_save_png("%s/fnaf_%s.png" % [OUT_DIR, cid], custom_im)

	# 3. Gerar todas as 15 variantes distorcidas surreais (índigo/cinza abissal, ZERO vermelho)
	var all_npc_ids: Array[String] = [
		"cap_reyes", "bombeiro_ato", "bombeiro_santos", "enfermeira_maria",
		"luningning", "aling_nena", "kuya_ben", "feirante", "mang_carding",
		"lola_rosa", "toby", "criatura_lagoa", "vulto_bosque", "santelmo", "vhs_radio"
	]
	var distorted_busts: Dictionary = {}
	for cid in all_npc_ids:
		var base_im: Image = normal_busts[cid]
		var dist_im := _make_surreal_distorted(base_im, cid == "vhs_radio", cid == "vulto_bosque" or cid == "santelmo")
		distorted_busts[cid] = dist_im
		_save_png("%s/fnaf_distorted_%s.png" % [OUT_DIR, cid], dist_im)

	# 4. Extrair Huwag Casual do JPEG base removendo 100% o cenário do quarto + derivar Huwag BFP + 9 expressões cada
	var huwag_raw_path := "%s/.user_uploaded/media_1795068812230_f6309f5f.jpg" % BRAIN_DIR
	var huwag_casual_neutral := _extract_huwag_bust(huwag_raw_path)
	var huwag_lm := _find_huwag_face_landmarks(huwag_casual_neutral)
	print("  [Huwag] Landmarks detectados: ", huwag_lm)
	var huwag_bfp_neutral := _recolor_huwag_to_bfp(huwag_casual_neutral)

	var huwag_exprs: Array[String] = [
		"neutral", "worried", "tired", "surprised", "angry", "scared", "uneasy_smile", "unfiltered", "distorted"
	]
	var huwag_casual_set: Dictionary = {}
	var huwag_bfp_set: Dictionary = {}
	for expr in huwag_exprs:
		var c_im := _apply_huwag_expression(huwag_casual_neutral, expr)
		var b_im := _apply_huwag_expression(huwag_bfp_neutral, expr)
		huwag_casual_set[expr] = c_im
		huwag_bfp_set[expr] = b_im
		_save_png("%s/huwag_casual_%s.png" % [OUT_DIR, expr], c_im)
		_save_png("%s/huwag_bfp_%s.png" % [OUT_DIR, expr], b_im)

	# 5. Espelhar arquivos legados para que não reste nenhum retrato opaco antigo no disco
	var legacy_dist_aliases: Array[String] = [
		"aling_nena", "feirante", "kuya_ben", "lola_rosa", "luningning", "mang_carding", "toby"
	]
	for lid in legacy_dist_aliases:
		_save_png("%s/distorted_fnaf_%s.png" % [OUT_DIR, lid], distorted_busts[lid])
	_save_png("%s/fnaf_distorted_bombeiro.png" % OUT_DIR, distorted_busts["bombeiro_santos"])

	var sprite_mirror_ids: Dictionary = {
		"aling_nena": "aling_nena",
		"bombeiro_ato": "bombeiro_ato",
		"bombeiro_santos": "bombeiro_santos",
		"cap_reyes": "cap_reyes",
		"criatura_lagoa": "criatura_lagoa",
		"enfermeira_maria": "enfermeira_maria",
		"kuya_ben": "kuya_ben",
		"lola_rosa": "lola_rosa",
		"mang_carding": "mang_carding",
		"mang_tomas": "feirante",
		"santelmo": "santelmo",
		"senhora_luningning": "luningning",
		"toby": "toby",
		"vhs_radio": "vhs_radio",
		"vulto_bosque": "vulto_bosque",
	}
	for dst_id in sprite_mirror_ids.keys():
		var src_id: String = str(sprite_mirror_ids[dst_id])
		_save_png("%s/%s_normal.png" % [LEGACY_SPRITE_PORTRAITS_DIR, dst_id], normal_busts[src_id])
		_save_png("%s/%s_distorted.png" % [LEGACY_SPRITE_PORTRAITS_DIR, dst_id], distorted_busts[src_id])
	_save_png("%s/huwag_casual_normal.png" % LEGACY_SPRITE_PORTRAITS_DIR, huwag_casual_set["neutral"])
	_save_png("%s/huwag_casual_distorted.png" % LEGACY_SPRITE_PORTRAITS_DIR, huwag_casual_set["distorted"])
	_save_png("%s/huwag_bfp_normal.png" % LEGACY_SPRITE_PORTRAITS_DIR, huwag_bfp_set["neutral"])
	_save_png("%s/huwag_bfp_distorted.png" % LEGACY_SPRITE_PORTRAITS_DIR, huwag_bfp_set["distorted"])

	# 6. Gerar prancha de contato visual (xadrez transparência + preto Omori #000000)
	_build_contact_sheet(normal_busts, distorted_busts, huwag_casual_set, huwag_bfp_set)
	print("=== Concluido! Todos os 48 retratos RGBA 96x96 + legados gerados com sucesso. ===")
	quit()


func _save_png(res_path: String, im: Image) -> void:
	var err := im.save_png(ProjectSettings.globalize_path(res_path))
	if err != OK:
		push_error("Falha ao salvar %s (err=%d)" % [res_path, err])


func _load_source_sampled(abs_path: String, sample_size: int) -> Image:
	var src := Image.new()
	var err := src.load(abs_path)
	if err != OK:
		push_error("Falha ao abrir retrato fonte: %s" % abs_path)
		return Image.create(sample_size, sample_size, false, Image.FORMAT_RGBA8)
	src.convert(Image.FORMAT_RGBA8)
	var sw := src.get_width()
	var sh := src.get_height()
	var out := Image.create(sample_size, sample_size, false, Image.FORMAT_RGBA8)
	# Amostragem no centro do bloco lógico (3x3 mediano suave na parte interna do bloco) reduz ruído JPEG sem borrar silhueta
	for y in range(sample_size):
		var cy := clampi(int(floor((float(y) + 0.5) * float(sh) / float(sample_size))), 1, maxi(1, sh - 2))
		for x in range(sample_size):
			var cx := clampi(int(floor((float(x) + 0.5) * float(sw) / float(sample_size))), 1, maxi(1, sw - 2))
			var center := src.get_pixel(cx, cy)
			# Média leve somente de pixels muito similares ao centro dentro do mesmo bloco para limpar artefatos DCT
			var sum := center
			var cnt := 1.0
			for dy in [-1, 1]:
				for dx in [-1, 1]:
					var nc := src.get_pixel(cx + dx, cy + dy)
					if absf(nc.r - center.r) + absf(nc.g - center.g) + absf(nc.b - center.b) < 0.20:
						sum += nc
						cnt += 1.0
			var final_c := sum / cnt
			final_c.a = 1.0
			out.set_pixel(x, y, final_c)
	return out


func _is_key_color(c: Color, key_mode: String, strict: bool) -> bool:
	if key_mode == "magenta":
		if strict:
			return c.r > 0.62 and c.b > 0.60 and c.g < minf(c.r, c.b) * 0.50
		return c.r > 0.44 and c.b > 0.42 and c.g < minf(c.r, c.b) * 0.72 and (c.r + c.b - c.g * 2.0) > 0.30
	else:
		if strict:
			return c.g > 0.62 and c.g > maxf(c.r, c.b) * 1.45
		return c.g > 0.42 and c.g > maxf(c.r, c.b) * 1.18 and (c.g - maxf(c.r, c.b)) > 0.14


func _extract_chromakey_bust(abs_path: String, key_mode: String, max_h: int) -> Image:
	# Trabalhar numa grade de 128x128 preserva pixels finos de 1px do JPEG, remove chroma e encaixa crisp em 96x96
	var S := 128
	var work := _load_source_sampled(abs_path, S)
	var bg := PackedByteArray()
	bg.resize(S * S)
	bg.fill(0)

	# Passo 1: Flood-fill externo tolerante partindo das 4 bordas
	var queue: Array[Vector2i] = []
	for i in range(S):
		var edge_pts: Array[Vector2i] = [Vector2i(i, 0), Vector2i(i, S - 1), Vector2i(0, i), Vector2i(S - 1, i)]
		for pt in edge_pts:
			var idx := pt.y * S + pt.x
			if bg[idx] == 0 and _is_key_color(work.get_pixel(pt.x, pt.y), key_mode, false):
				bg[idx] = 1
				queue.append(pt)

	var head := 0
	var dirs: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	while head < queue.size():
		var cur := queue[head]
		head += 1
		for d in dirs:
			var nx := cur.x + d.x
			var ny := cur.y + d.y
			if nx < 0 or nx >= S or ny < 0 or ny >= S:
				continue
			var nidx := ny * S + nx
			if bg[nidx] != 0:
				continue
			if _is_key_color(work.get_pixel(nx, ny), key_mode, false):
				bg[nidx] = 1
				queue.append(Vector2i(nx, ny))

	# Passo 2: Limpar bolhas internas de chroma puro (ex: mechas de cabelo da Guardiã / Maria / Aling Nena)
	for y in range(S):
		for x in range(S):
			var idx := y * S + x
			if bg[idx] == 0 and _is_key_color(work.get_pixel(x, y), key_mode, true):
				bg[idx] = 1

	# Passo 3: Comer 1px de halo residual colado ao fundo transparente + despill
	for _pass in range(2):
		var to_clear: Array[int] = []
		for y in range(S):
			for x in range(S):
				var idx := y * S + x
				if bg[idx] == 1:
					continue
				var touches_bg := false
				for d in dirs:
					var nx := x + d.x
					var ny := y + d.y
					if nx >= 0 and nx < S and ny >= 0 and ny < S and bg[ny * S + nx] == 1:
						touches_bg = true
						break
				if touches_bg:
					var c := work.get_pixel(x, y)
					var luma := c.r * 0.299 + c.g * 0.587 + c.b * 0.114
					if _is_key_color(c, key_mode, false):
						to_clear.append(idx)
					elif key_mode == "magenta" and c.r > c.g + 0.16 and c.b > c.g + 0.16 and luma > 0.24:
						to_clear.append(idx)
					elif key_mode == "green" and c.g > maxf(c.r, c.b) * 1.12 and luma > 0.22:
						to_clear.append(idx)
		for idx_c in to_clear:
			bg[idx_c] = 1

	# Passo 4: Despill dos pixels restantes colados à borda (mata halo colorido sem apagar o contorno escuro)
	for y in range(S):
		for x in range(S):
			var idx := y * S + x
			if bg[idx] == 1:
				work.set_pixel(x, y, Color(0, 0, 0, 0))
				continue
			var touches_bg := false
			for d in dirs:
				var nx := x + d.x
				var ny := y + d.y
				if nx >= 0 and nx < S and ny >= 0 and ny < S and bg[ny * S + nx] == 1:
					touches_bg = true
					break
			if touches_bg:
				var c := work.get_pixel(x, y)
				if key_mode == "magenta":
					var mx := minf(c.r, c.b)
					if mx > c.g * 1.20:
						var avg_g := c.g
						c.r = lerpf(c.r, avg_g, 0.72)
						c.b = lerpf(c.b, avg_g, 0.72)
						work.set_pixel(x, y, c)
				else:
					if c.g > maxf(c.r, c.b) * 1.05:
						c.g = lerpf(c.g, maxf(c.r, c.b), 0.75)
						work.set_pixel(x, y, c)

	return _fit_bottom_centered_96(work, max_h)


func _fit_bottom_centered_96(src: Image, max_h: int) -> Image:
	var w := src.get_width()
	var h := src.get_height()
	var min_x := w
	var max_x := -1
	var min_y := h
	var max_y := -1
	for y in range(h):
		for x in range(w):
			if src.get_pixel(x, y).a > 0.5:
				min_x = mini(min_x, x)
				max_x = maxi(max_x, x)
				min_y = mini(min_y, y)
				max_y = maxi(max_y, y)
	if max_x < min_x or max_y < min_y:
		return Image.create(TARGET_SIZE, TARGET_SIZE, false, Image.FORMAT_RGBA8)

	var cw := max_x - min_x + 1
	var ch := max_y - min_y + 1
	var crop := src.get_region(Rect2i(min_x, min_y, cw, ch))
	var scale := minf(float(TARGET_SIZE) / float(cw), float(max_h) / float(ch))
	var dw := clampi(int(roundf(float(cw) * scale)), 1, TARGET_SIZE)
	var dh := clampi(int(roundf(float(ch) * scale)), 1, TARGET_SIZE)
	crop.resize(dw, dh, Image.INTERPOLATE_NEAREST)

	var out := Image.create(TARGET_SIZE, TARGET_SIZE, false, Image.FORMAT_RGBA8)
	var ox := (TARGET_SIZE - dw) / 2
	var oy := TARGET_SIZE - dh
	for y in range(dh):
		for x in range(dw):
			var c := crop.get_pixel(x, y)
			if c.a >= 0.55:
				c.a = 1.0
				out.set_pixel(ox + x, oy + y, c)
	return out


func _extract_huwag_bust(abs_path: String) -> Image:
	var S := 128
	var work := _load_source_sampled(abs_path, S)
	var bg := PackedByteArray()
	bg.resize(S * S)
	bg.fill(0)

	# Limpar diretamente cantos externos e parede/porta usando cor + fronteira de contorno preto do busto
	var queue: Array[Vector2i] = []
	for i in range(S):
		var edge_pts: Array[Vector2i] = [Vector2i(i, 0), Vector2i(0, i), Vector2i(S - 1, i)]
		for pt in edge_pts:
			if pt.y >= 108:
				continue
			var idx := pt.y * S + pt.x
			if bg[idx] == 0 and _is_huwag_bg_candidate(work.get_pixel(pt.x, pt.y), pt.x, pt.y, S):
				bg[idx] = 1
				queue.append(pt)

	var head := 0
	var dirs: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	while head < queue.size():
		var cur := queue[head]
		head += 1
		for d in dirs:
			var nx := cur.x + d.x
			var ny := cur.y + d.y
			if nx < 0 or nx >= S or ny < 0 or ny >= S:
				continue
			var nidx := ny * S + nx
			if bg[nidx] != 0:
				continue
			var c := work.get_pixel(nx, ny)
			# Parar apenas no contorno preto sólido, cabelo loiro quente ou pele/pescoço na faixa central
			if _is_huwag_bg_candidate(c, nx, ny, S):
				bg[nidx] = 1
				queue.append(Vector2i(nx, ny))

	# Remover quaisquer ilhas isoladas externas (quadro da parede, interruptor, maçaneta) preservando apenas o maior componente conectado centrado no busto (64, 72)
	var fg_comp := PackedByteArray()
	fg_comp.resize(S * S)
	fg_comp.fill(0)
	var seed_pt := Vector2i(64, 72)
	var cq: Array[Vector2i] = [seed_pt]
	fg_comp[seed_pt.y * S + seed_pt.x] = 1
	var ch_head := 0
	while ch_head < cq.size():
		var cp := cq[ch_head]
		ch_head += 1
		for d in dirs:
			var nx := cp.x + d.x
			var ny := cp.y + d.y
			if nx < 0 or nx >= S or ny < 0 or ny >= S:
				continue
			var nidx := ny * S + nx
			if bg[nidx] == 0 and fg_comp[nidx] == 0:
				fg_comp[nidx] = 1
				cq.append(Vector2i(nx, ny))

	# Também eliminar pixels remanescentes com tom típico de parede azulada ou madeira da porta acima dos ombros
	for y in range(S):
		for x in range(S):
			var idx := y * S + x
			if fg_comp[idx] == 0:
				work.set_pixel(x, y, Color(0, 0, 0, 0))
			else:
				var c := work.get_pixel(x, y)
				if y < 62 and (x < 18 or x > 109):
					var is_blond := c.r > 0.48 and c.g > 0.34 and c.b < c.r * 0.72
					var is_black := maxf(maxf(c.r, c.g), c.b) < 0.14
					if not is_blond and not is_black:
						work.set_pixel(x, y, Color(0, 0, 0, 0))
				elif x > 98 and y < 94 and c.r > c.b + 0.025 and c.r < 0.52 and c.g < 0.40:
					# Madeira da porta / batente à direita nunca faz parte da jaqueta grafite neutra do Huwag
					work.set_pixel(x, y, Color(0, 0, 0, 0))

	# Limpar 1px de resíduo azul-cinza da parede adjacente ao transparente fora do cabelo loiro e jaqueta
	for y in range(S):
		for x in range(S):
			if work.get_pixel(x, y).a < 0.5:
				continue
			var c := work.get_pixel(x, y)
			var is_wall_blue := c.b > c.r + 0.035 and c.b > 0.20 and c.r < 0.34 and y < 74
			var is_door_brown := (x > 96 and y < 88 and c.r > c.b + 0.055 and c.r < 0.46 and c.g < 0.34)
			if is_wall_blue or is_door_brown:
				for d in dirs:
					var nx := x + d.x
					var ny := y + d.y
					if nx >= 0 and nx < S and ny >= 0 and ny < S and work.get_pixel(nx, ny).a < 0.5:
						work.set_pixel(x, y, Color(0, 0, 0, 0))
						break

	return _fit_bottom_centered_96(work, 92)


func _is_huwag_bg_candidate(c: Color, x: int, y: int, s: int) -> bool:
	var maxc := maxf(maxf(c.r, c.g), c.b)
	# Contorno preto puro da silhueta bloqueia o flood-fill para nunca invadir o personagem
	if maxc < 0.115:
		return false
	# Cabelo loiro dourado quente bloqueia o flood-fill
	if c.r > 0.44 and c.g > 0.30 and c.b < c.g * 0.76:
		return false
	# Pele bronzeada bloqueia o flood-fill na região do rosto/pescoço
	if x > int(s * 0.24) and x < int(s * 0.76) and y > int(s * 0.25) and y < int(s * 0.85):
		if c.r > 0.34 and c.r > c.b + 0.12 and c.g < c.r * 0.88:
			return false
	# Na faixa baixa dos ombros/jaqueta (y >= 74), apenas a parede azulada ou madeira marrom externa da porta à direita vazam
	if y >= int(s * 0.58):
		var is_wall_blue := c.b > c.r + 0.03 and c.r < 0.36
		var is_side_door := x > int(s * 0.80) and c.r > c.b + 0.055 and c.r < 0.46 and c.g < 0.35
		return is_wall_blue or is_side_door
	# Acima dos ombros, parede cinza-azulada, quadro e porta são removíveis exceto cabelo loiro/contorno preto
	if x < int(s * 0.20) or x > int(s * 0.80):
		return true
	var luma := c.r * 0.299 + c.g * 0.587 + c.b * 0.114
	if luma > 0.12 and (c.b >= c.r - 0.04 or c.r < 0.44):
		return true
	return false


func _recolor_huwag_to_bfp(casual: Image) -> Image:
	var out := casual.duplicate() as Image
	for y in range(54, TARGET_SIZE):
		for x in range(TARGET_SIZE):
			var c := out.get_pixel(x, y)
			if c.a < 0.5:
				continue
			# Preservar contorno preto, pele (pescoço central), e zíper / camiseta interna próxima do centro
			var maxc := maxf(maxf(c.r, c.g), c.b)
			var is_skin := c.r > 0.35 and c.r > c.b + 0.10 and absf(float(x) - 48.0) < 20.0
			if is_skin or maxc < 0.09:
				continue
			# Recolorir área dos ombros e jaqueta externa (excluindo triângulo central escuro da camisa)
			var dx := absf(float(x) - 48.0)
			var is_inner_shirt := dx < (float(y - 54) * 0.34)
			var luma := c.r * 0.299 + c.g * 0.587 + c.b * 0.114
			if is_inner_shirt:
				continue
			# Faixas refletivas BFP horizontais no peito/ombros
			if y in [78, 79, 80, 81]:
				out.set_pixel(x, y, Color("#E87822") if luma > 0.12 else Color("#9C4814"))
			elif y in [82, 83]:
				out.set_pixel(x, y, Color("#F6D658") if luma > 0.12 else Color("#B5962B"))
			else:
				# Azul marinho BFP coerente com luminosidade da jaqueta original
				var t := clampf((luma - 0.08) / 0.26, 0.0, 1.0)
				var navy := Color("#0D192E").lerp(Color("#294775"), t)
				out.set_pixel(x, y, navy)
	return out


func _find_huwag_face_landmarks(im: Image) -> Dictionary:
	# Detectar exatamente y dos olhos buscando esclera branca neutra flanqueada por pupila escura (y=38..52)
	var eye_y := 44
	var best_eye_score := -1
	var left_ex := 38
	var right_ex := 58
	for y in range(38, 53):
		var sclera_cnt := 0
		var l_sum := 0
		var l_n := 0
		var r_sum := 0
		var r_n := 0
		for x in range(31, 65):
			var c := im.get_pixel(x, y)
			if c.a < 0.5:
				continue
			var mx := maxf(maxf(c.r, c.g), c.b)
			var mn := minf(minf(c.r, c.g), c.b)
			if mx > 0.58 and (mx - mn) < 0.14:
				sclera_cnt += 1
				if x < 48:
					l_sum += x
					l_n += 1
				else:
					r_sum += x
					r_n += 1
		if sclera_cnt > best_eye_score:
			best_eye_score = sclera_cnt
			eye_y = y
			if l_n > 0:
				left_ex = int(roundf(float(l_sum) / float(l_n)))
			if r_n > 0:
				right_ex = int(roundf(float(r_sum) / float(r_n)))

	# Detectar y da boca: risco horizontal mais escuro entre eye_y+14 e 68 centrada em 48
	var mouth_y := clampi(eye_y + 17, 54, 67)
	var best_m_score := -1
	for y in range(eye_y + 13, mini(69, eye_y + 23)):
		var dark_cnt := 0
		for x in range(42, 54):
			var c := im.get_pixel(x, y)
			if c.a > 0.5 and (c.r + c.g + c.b) < 0.45:
				dark_cnt += 1
		if dark_cnt > best_m_score:
			best_m_score = dark_cnt
			mouth_y = y

	return {"eye_y": eye_y, "mouth_y": mouth_y, "left_ex": left_ex, "right_ex": right_ex}


func _apply_huwag_expression(base: Image, expr: String) -> Image:
	if expr == "neutral":
		return base.duplicate() as Image
	if expr == "unfiltered":
		return _make_grayscale_unfiltered(base)
	if expr == "distorted":
		return _make_surreal_distorted(base, false, false)

	var im := base.duplicate() as Image
	var lm := _find_huwag_face_landmarks(im)
	var ey: int = int(lm["eye_y"])
	var my: int = int(lm["mouth_y"])
	var lx: int = int(lm["left_ex"])
	var rx: int = int(lm["right_ex"])
	var mx := int((lx + rx) / 2)

	var skin_md := Color("#A8744B")
	var skin_sh := Color("#7D5033")
	var outline := Color("#0B090A")
	var eye_w := Color("#ECE5DC")
	var pupil := Color("#16100E")

	match expr:
		"worried":
			for dx in range(6):
				_set_px_if_opaque(im, lx - 3 + dx, ey - 3 - int(dx / 2), outline)
				_set_px_if_opaque(im, rx + 3 - dx, ey - 3 - int(dx / 2), outline)
			_set_px_if_opaque(im, mx - 5, my + 1, outline)
			_set_px_if_opaque(im, mx - 4, my + 1, outline)
			_set_px_if_opaque(im, mx + 4, my + 1, outline)
			_set_px_if_opaque(im, mx + 5, my + 1, outline)
		"tired":
			for ex in [lx, rx]:
				for dx in range(-4, 5):
					_set_px_if_opaque(im, ex + dx, ey - 1, outline)
					_set_px_if_opaque(im, ex + dx, ey + 2, skin_sh)
					_set_px_if_opaque(im, ex + dx, ey + 3, skin_sh)
			for dx in range(-4, 5):
				_set_px_if_opaque(im, mx + dx, my + 1, skin_sh)
		"surprised":
			for ex in [lx, rx]:
				for dx in range(-3, 4):
					_set_px_if_opaque(im, ex + dx, ey - 5, outline)
					_set_px_if_opaque(im, ex + dx, ey - 1, eye_w)
					_set_px_if_opaque(im, ex + dx, ey, eye_w)
					_set_px_if_opaque(im, ex + dx, ey + 1, eye_w)
				for py in range(ey - 1, ey + 2):
					for px in range(ex - 1, ex + 2):
						_set_px_if_opaque(im, px, py, pupil)
			for dx in range(-2, 3):
				for dy in range(0, 3):
					var is_ring := (absi(dx) == 2 or dy in [0, 2])
					_set_px_if_opaque(im, mx + dx, my + dy, outline if is_ring else Color("#281412"))
		"angry":
			for dx in range(6):
				_set_px_if_opaque(im, lx - 3 + dx, ey - 5 + int(dx / 2), outline)
				_set_px_if_opaque(im, rx + 3 - dx, ey - 5 + int(dx / 2), outline)
			for dx in range(-4, 5):
				_set_px_if_opaque(im, mx + dx, my, outline)
			_set_px_if_opaque(im, mx - 4, my + 1, outline)
			_set_px_if_opaque(im, mx + 4, my + 1, outline)
		"scared":
			for ex in [lx, rx]:
				for dx in range(-4, 5):
					_set_px_if_opaque(im, ex + dx, ey - 5, outline)
					for py in range(ey - 1, ey + 2):
						_set_px_if_opaque(im, ex + dx, py, eye_w)
				for py in range(ey, ey + 2):
					_set_px_if_opaque(im, ex, py, pupil)
			for dx in range(-4, 5):
				_set_px_if_opaque(im, mx + dx, my + (1 if (dx % 2) == 0 else 0), outline)
			_set_px_if_opaque(im, rx + 10, ey - 3, Color("#68BCE8"))
			_set_px_if_opaque(im, rx + 10, ey - 2, Color("#BEE8FA"))
			_set_px_if_opaque(im, rx + 11, ey - 2, Color("#68BCE8"))
		"uneasy_smile":
			for dx in range(5):
				_set_px_if_opaque(im, lx - 2 + dx, ey - 4 - int(dx / 3), outline)
				_set_px_if_opaque(im, rx + 2 - dx, ey - 4 - int(dx / 3), outline)
			for dx in range(-4, 5):
				_set_px_if_opaque(im, mx + dx, my, skin_md)
				_set_px_if_opaque(im, mx + dx, my + 1, outline)
			_set_px_if_opaque(im, mx - 5, my, outline)
			_set_px_if_opaque(im, mx + 5, my, outline)
	return im


func _set_px_if_opaque(im: Image, x: int, y: int, col: Color) -> void:
	if x < 0 or x >= im.get_width() or y < 0 or y >= im.get_height():
		return
	if im.get_pixel(x, y).a > 0.5:
		var c := col
		c.a = 1.0
		im.set_pixel(x, y, c)


func _make_grayscale_unfiltered(src: Image) -> Image:
	var out := Image.create(TARGET_SIZE, TARGET_SIZE, false, Image.FORMAT_RGBA8)
	for y in range(TARGET_SIZE):
		for x in range(TARGET_SIZE):
			var c := src.get_pixel(x, y)
			if c.a < 0.5:
				continue
			var l := c.r * 0.299 + c.g * 0.587 + c.b * 0.114
			# Preto/cinza clínico frio de Ato III (zero vermelho)
			out.set_pixel(x, y, Color(l * 0.94, l * 0.96, l * 1.00, 1.0))
	return out


func _make_surreal_distorted(src: Image, is_radio: bool, _is_entity: bool) -> Image:
	var out := Image.create(TARGET_SIZE, TARGET_SIZE, false, Image.FORMAT_RGBA8)
	# Grade abissal índigo-violeta cadavérica (ZERO vermelho sangue) + cisalhamento sutil de 1px
	for y in range(TARGET_SIZE):
		var shift := 0
		if y in [44, 45, 74, 75]:
			shift = 1
		elif y == 62:
			shift = -1
		for x in range(TARGET_SIZE):
			var sx := clampi(x - shift, 0, TARGET_SIZE - 1)
			var c := src.get_pixel(sx, y)
			if c.a < 0.5:
				continue
			var l := c.r * 0.299 + c.g * 0.587 + c.b * 0.114
			var col: Color
			if l < 0.10:
				col = Color(0.03, 0.02, 0.06, 1.0)
			elif l < 0.28:
				col = Color("#120E1D").lerp(Color("#2A243D"), (l - 0.10) / 0.18)
			elif l < 0.58:
				col = Color("#2A243D").lerp(Color("#696284"), (l - 0.28) / 0.30)
			else:
				col = Color("#696284").lerp(Color("#C2BED6"), (l - 0.58) / 0.42)
			# Brilho ocular sutil apenas sobre esclera branca pura na linha dos olhos (nunca em pele quente)
			if not is_radio and ((x >= 32 and x <= 44) or (x >= 52 and x <= 64)) and y >= 36 and y <= 49:
				var maxc := maxf(maxf(c.r, c.g), c.b)
				var minc := minf(minf(c.r, c.g), c.b)
				var is_pure_sclera := maxc > 0.78 and minc > 0.68 and (maxc - minc) < 0.10
				if is_pure_sclera:
					col = Color("#E6E2FA")
			col.a = 1.0
			out.set_pixel(x, y, col)
	return out


# ==============================================================================
# COMPOSIÇÃO PIXEL-GRID 64x64 -> 96x96 TRANSPARENTE PARA OS 5 PERFIS RESTANTES
# ==============================================================================
func _new_grid64() -> Image:
	return Image.create(64, 64, false, Image.FORMAT_RGBA8)


func _g_rect(im: Image, x: int, y: int, w: int, h: int, col: Color) -> void:
	for py in range(maxi(0, y), mini(im.get_height(), y + h)):
		for px in range(maxi(0, x), mini(im.get_width(), x + w)):
			im.set_pixel(px, py, col)


func _g_ellipse(im: Image, cx: float, cy: float, rx: float, ry: float, col: Color) -> void:
	for py in range(maxi(0, int(floor(cy - ry))), mini(im.get_height(), int(ceil(cy + ry)) + 1)):
		for px in range(maxi(0, int(floor(cx - rx))), mini(im.get_width(), int(ceil(cx + rx)) + 1)):
			var nx := (float(px) - cx) / rx
			var ny := (float(py) - cy) / ry
			if nx * nx + ny * ny <= 1.0:
				im.set_pixel(px, py, col)


func _g_outline(im: Image, outline_col: Color) -> Image:
	var w := im.get_width()
	var h := im.get_height()
	var out := im.duplicate() as Image
	var dirs: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	for y in range(h):
		for x in range(w):
			if im.get_pixel(x, y).a > 0.5:
				continue
			for d in dirs:
				var nx := x + d.x
				var ny := y + d.y
				if nx >= 0 and nx < w and ny >= 0 and ny < h and im.get_pixel(nx, ny).a > 0.5:
					out.set_pixel(x, y, outline_col)
					break
	return out


func _compose_luningning_96() -> Image:
	var g := _new_grid64()
	var skin_dk := Color("#6D432B")
	var skin_sh := Color("#885A3D")
	var skin_md := Color("#AC7B56")
	var skin_hi := Color("#C99770")
	var hair_dk := Color("#3E4450")
	var hair_md := Color("#667080")
	var hair_hi := Color("#A6B0C2")
	var shawl_dk := Color("#38152B")
	var shawl_md := Color("#5A2444")
	var shawl_hi := Color("#7D3762")
	var shawl_trim := Color("#C69A64")
	var blouse := Color("#DDD4C4")
	var line := Color("#09070B")

	# Coque alto grisalho + mechas finas presas
	_g_ellipse(g, 32, 8, 8.2, 5.5, hair_dk)
	_g_ellipse(g, 31, 7, 5.6, 3.6, hair_md)
	_g_rect(g, 28, 6, 4, 1, hair_hi)
	_g_ellipse(g, 32, 23, 15.2, 13.5, hair_dk)
	_g_ellipse(g, 32, 22, 13.4, 11.4, hair_md)
	for hx in [21, 23, 39, 41]:
		_g_rect(g, hx, 14, 2, 4, hair_hi)
	# Cachos caídos finos nas têmporas
	_g_rect(g, 18, 30, 1, 7, hair_dk)
	_g_rect(g, 45, 30, 1, 7, hair_dk)

	# Xale roxo-vinho *alampay* sobre blusa clara com bordado e dobras
	_g_ellipse(g, 32, 58, 27.5, 14.5, shawl_dk)
	_g_ellipse(g, 32, 56, 24.5, 12.2, shawl_md)
	_g_rect(g, 26, 45, 12, 19, blouse)
	_g_rect(g, 25, 46, 1, 18, line)
	_g_rect(g, 38, 46, 1, 18, line)
	_g_rect(g, 19, 46, 6, 18, shawl_hi)
	_g_rect(g, 39, 46, 6, 18, shawl_hi)
	_g_rect(g, 24, 47, 1, 17, shawl_trim)
	_g_rect(g, 39, 47, 1, 17, shawl_trim)
	# Pescoço sombreado sob queixo
	_g_rect(g, 27, 38, 10, 10, skin_sh)
	_g_rect(g, 28, 40, 8, 8, skin_md)
	_g_rect(g, 28, 39, 8, 2, skin_dk)

	# Orelhas + Rosto com maçãs do rosto, rugas e nariz esculpido
	_g_ellipse(g, 18, 29, 2.4, 4.0, skin_sh)
	_g_ellipse(g, 46, 29, 2.4, 4.0, skin_sh)
	_g_rect(g, 18, 28, 1, 2, skin_dk)
	_g_rect(g, 45, 28, 1, 2, skin_dk)
	_g_ellipse(g, 32, 27, 12.2, 12.8, skin_sh)
	_g_ellipse(g, 32, 26, 11.2, 11.4, skin_md)
	_g_ellipse(g, 32, 25, 8.2, 7.6, skin_hi)
	# Franja partida
	_g_ellipse(g, 24, 17, 6.2, 3.8, hair_dk)
	_g_ellipse(g, 40, 17, 6.2, 3.8, hair_dk)
	_g_rect(g, 25, 16, 3, 2, hair_hi)
	_g_rect(g, 36, 16, 3, 2, hair_hi)
	# Rugas testa, sobrancelhas graves, olhos e boca
	_g_rect(g, 26, 20, 12, 1, skin_sh)
	_g_rect(g, 22, 24, 6, 1, line)
	_g_rect(g, 36, 24, 6, 1, line)
	_g_rect(g, 22, 26, 6, 1, line)
	_g_rect(g, 36, 26, 6, 1, line)
	_g_rect(g, 23, 27, 5, 2, Color("#EFE8E0"))
	_g_rect(g, 36, 27, 5, 2, Color("#EFE8E0"))
	_g_rect(g, 24, 27, 3, 2, Color("#24150E"))
	_g_rect(g, 37, 27, 3, 2, Color("#24150E"))
	_g_rect(g, 24, 27, 1, 1, Color.WHITE)
	_g_rect(g, 37, 27, 1, 1, Color.WHITE)
	_g_rect(g, 23, 30, 5, 1, skin_dk)
	_g_rect(g, 36, 30, 5, 1, skin_dk)
	# Nariz com dorso claro e base sombreada
	_g_rect(g, 31, 26, 2, 5, skin_hi)
	_g_rect(g, 30, 31, 4, 1, skin_dk)
	_g_rect(g, 26, 33, 2, 3, skin_sh)
	_g_rect(g, 36, 33, 2, 3, skin_sh)
	_g_rect(g, 28, 35, 8, 1, line)
	_g_rect(g, 30, 36, 4, 1, skin_dk)

	return _fit_bottom_centered_96(_g_outline(g, line), 92)


func _compose_lola_rosa_96() -> Image:
	var g := _new_grid64()
	var skin_dk := Color("#6E442C")
	var skin_sh := Color("#8B5C3E")
	var skin_md := Color("#AF7E59")
	var skin_hi := Color("#CA9871")
	var scarf_dk := Color("#9E9584")
	var scarf_md := Color("#DAD2C2")
	var scarf_hi := Color("#F4EFE6")
	var hair_silver := Color("#ACB4C0")
	var hair_dk := Color("#6E7682")
	var baro_md := Color("#CFC3A3")
	var baro_dk := Color("#9E9274")
	var leaf_dk := Color("#2B6232")
	var leaf_green := Color("#4B8B52")
	var line := Color("#0B0808")

	# Lenço branco/creme com dobras + nó no topo
	_g_ellipse(g, 32, 23, 16.5, 15.0, scarf_dk)
	_g_ellipse(g, 32, 21, 14.5, 13.0, scarf_md)
	_g_ellipse(g, 30, 14, 9.0, 5.2, scarf_hi)
	_g_rect(g, 20, 14, 3, 2, Color("#A48870"))
	_g_rect(g, 41, 15, 2, 2, Color("#A48870"))

	# Blusa *baro* texturizada + gola dobrada + ramo de *lagundi*
	_g_ellipse(g, 32, 57, 26.8, 13.8, baro_dk)
	_g_ellipse(g, 32, 56, 24.0, 11.8, baro_md)
	_g_rect(g, 25, 45, 14, 10, scarf_hi)
	_g_rect(g, 26, 45, 12, 1, line)
	_g_rect(g, 27, 38, 10, 10, skin_sh)
	_g_rect(g, 28, 39, 8, 8, skin_md)
	_g_rect(g, 28, 38, 8, 2, skin_dk)
	# Fios grisalhos sob lenço
	_g_rect(g, 19, 20, 4, 8, hair_dk)
	_g_rect(g, 41, 20, 4, 8, hair_dk)
	_g_rect(g, 20, 21, 2, 6, hair_silver)
	_g_rect(g, 42, 21, 2, 6, hair_silver)

	# Rosto gentil esculpido
	_g_ellipse(g, 32, 28, 12.0, 12.0, skin_sh)
	_g_ellipse(g, 32, 27, 11.0, 10.8, skin_md)
	_g_ellipse(g, 32, 26, 8.4, 7.6, skin_hi)
	# Ramo *lagundi* no colarinho esquerdo
	_g_rect(g, 21, 47, 5, 4, leaf_dk)
	_g_rect(g, 22, 47, 3, 3, leaf_green)
	_g_rect(g, 19, 50, 4, 3, Color("#76BF74"))
	# Olhos ternos, pálpebras e sorriso
	_g_rect(g, 23, 24, 5, 1, hair_dk)
	_g_rect(g, 36, 24, 5, 1, hair_dk)
	_g_rect(g, 23, 26, 5, 1, line)
	_g_rect(g, 36, 26, 5, 1, line)
	_g_rect(g, 24, 27, 4, 2, Color("#F4EFE8"))
	_g_rect(g, 36, 27, 4, 2, Color("#F4EFE8"))
	_g_rect(g, 25, 27, 2, 2, Color("#241510"))
	_g_rect(g, 37, 27, 2, 2, Color("#241510"))
	_g_rect(g, 25, 27, 1, 1, Color.WHITE)
	_g_rect(g, 37, 27, 1, 1, Color.WHITE)
	_g_rect(g, 31, 27, 2, 4, skin_hi)
	_g_rect(g, 30, 31, 4, 1, skin_dk)
	_g_rect(g, 28, 35, 8, 1, line)
	_g_rect(g, 27, 34, 1, 1, line)
	_g_rect(g, 36, 34, 1, 1, line)

	return _fit_bottom_centered_96(_g_outline(g, line), 90)


func _compose_toby_96() -> Image:
	var g := _new_grid64()
	var skin_dk := Color("#744729")
	var skin_sh := Color("#93613D")
	var skin_md := Color("#BB875C")
	var skin_hi := Color("#D8A67D")
	var cap_dk := Color("#9C360C")
	var cap_md := Color("#E86622")
	var cap_hi := Color("#FFA04A")
	var hair_dk := Color("#16141A")
	var hair_md := Color("#2B2834")
	var tee_dk := Color("#1E582C")
	var tee_md := Color("#368E4C")
	var tee_hi := Color("#50AA64")
	var strap := Color("#3B4558")
	var buckle := Color("#BAC4D2")
	var line := Color("#08070A")

	# Boné esportivo laranja com gomos e aba detalhada
	_g_ellipse(g, 32, 17, 14.5, 10.2, cap_dk)
	_g_ellipse(g, 32, 16, 13.0, 9.0, cap_md)
	_g_ellipse(g, 30, 13, 7.5, 4.0, cap_hi)
	_g_rect(g, 31, 8, 2, 11, cap_dk)
	_g_rect(g, 18, 20, 28, 4, cap_dk)
	_g_rect(g, 19, 20, 25, 2, cap_hi)

	# Camiseta verde juvenil + gola + mochila
	_g_ellipse(g, 32, 58, 22.0, 11.8, tee_dk)
	_g_ellipse(g, 32, 57, 19.8, 9.8, tee_md)
	_g_ellipse(g, 32, 53, 10.5, 5.2, tee_hi)
	_g_rect(g, 20, 48, 4, 16, strap)
	_g_rect(g, 40, 48, 4, 16, strap)
	_g_rect(g, 20, 56, 4, 2, buckle)
	_g_rect(g, 40, 56, 4, 2, buckle)
	_g_rect(g, 28, 42, 8, 8, skin_sh)
	_g_rect(g, 29, 43, 6, 7, skin_md)
	_g_rect(g, 29, 42, 6, 2, skin_dk)

	# Orelhas + Rosto infantil bochechudo
	_g_ellipse(g, 20, 32, 2.4, 3.4, skin_sh)
	_g_ellipse(g, 44, 32, 2.4, 3.4, skin_sh)
	_g_ellipse(g, 32, 32, 11.4, 10.8, skin_sh)
	_g_ellipse(g, 32, 31, 10.4, 9.8, skin_md)
	_g_ellipse(g, 32, 30, 8.2, 7.2, skin_hi)
	# Mechas pretas espessas sob a aba do boné
	_g_rect(g, 20, 23, 6, 4, hair_dk)
	_g_rect(g, 27, 23, 5, 3, hair_md)
	_g_rect(g, 34, 23, 9, 4, hair_dk)
	# Olhos grandes expressivos, bochechas rosadas, sorriso alegre
	_g_rect(g, 23, 27, 5, 1, line)
	_g_rect(g, 36, 27, 5, 1, line)
	_g_rect(g, 24, 29, 4, 3, Color("#FAF6F0"))
	_g_rect(g, 36, 29, 4, 3, Color("#FAF6F0"))
	_g_rect(g, 25, 29, 3, 3, Color("#1E120C"))
	_g_rect(g, 36, 29, 3, 3, Color("#1E120C"))
	_g_rect(g, 25, 29, 1, 1, Color.WHITE)
	_g_rect(g, 36, 29, 1, 1, Color.WHITE)
	_g_rect(g, 23, 33, 3, 2, Color("#CC7E66"))
	_g_rect(g, 38, 33, 3, 2, Color("#CC7E66"))
	_g_rect(g, 31, 33, 2, 2, skin_sh)
	_g_rect(g, 28, 37, 8, 1, line)
	_g_rect(g, 27, 36, 1, 1, line)
	_g_rect(g, 36, 36, 1, 1, line)

	return _fit_bottom_centered_96(_g_outline(g, line), 86)


func _compose_vulto_bosque_96() -> Image:
	var g := _new_grid64()
	var ash_dk := Color("#101116")
	var ash_md := Color("#23242E")
	var ash_hi := Color("#464858")
	var helm_dk := Color("#1A1C24")
	var helm_md := Color("#333644")
	var ember_out := Color("#EA5A10")
	var ember_hi := Color("#FFC25C")
	var glow_eye := Color("#FFF4B8")
	var line := Color("#040407")

	# Capacete BFP carbonizado e trincado
	_g_ellipse(g, 32, 16, 15.2, 11.2, helm_dk)
	_g_ellipse(g, 31, 14, 12.2, 8.2, helm_md)
	_g_rect(g, 15, 21, 34, 4, helm_dk)
	_g_rect(g, 17, 21, 30, 2, ash_hi)
	_g_rect(g, 34, 7, 2, 12, ember_out)
	_g_rect(g, 35, 10, 2, 6, ember_hi)

	# Capote rasgado de bombeiro com dobras e faixa queimada
	_g_ellipse(g, 32, 57, 26.8, 14.0, ash_dk)
	_g_ellipse(g, 32, 55, 23.2, 12.0, ash_md)
	_g_rect(g, 18, 46, 28, 18, ash_dk)
	_g_rect(g, 21, 47, 5, 16, ash_hi)
	_g_rect(g, 38, 47, 5, 16, ash_hi)
	_g_rect(g, 13, 54, 38, 4, Color("#6E3B18"))
	_g_rect(g, 17, 55, 30, 2, ember_out)
	_g_rect(g, 26, 40, 12, 14, ash_dk)

	# Rosto esqueletizado na fuligem + olhos de brasa
	_g_ellipse(g, 32, 31, 11.6, 11.6, ash_dk)
	_g_ellipse(g, 32, 29, 9.6, 8.6, ash_md)
	_g_rect(g, 22, 28, 6, 4, line)
	_g_rect(g, 36, 28, 6, 4, line)
	_g_rect(g, 24, 29, 3, 2, ember_out)
	_g_rect(g, 37, 29, 3, 2, ember_out)
	_g_rect(g, 25, 29, 1, 1, glow_eye)
	_g_rect(g, 38, 29, 1, 1, glow_eye)
	_g_rect(g, 31, 31, 2, 3, line)
	_g_rect(g, 28, 36, 8, 2, line)
	_g_rect(g, 13, 14, 3, 7, ash_hi)
	_g_rect(g, 48, 12, 3, 8, ash_hi)

	return _fit_bottom_centered_96(_g_outline(g, line), 92)


func _compose_vhs_radio_96() -> Image:
	var g := _new_grid64()
	var body_dk := Color("#171C24")
	var body_md := Color("#2B3442")
	var body_hi := Color("#4C5A6E")
	var screen_dk := Color("#0B2A30")
	var screen_glow := Color("#4ED8E0")
	var led_amber := Color("#FFAA30")
	var knob := Color("#3E4654")
	var line := Color("#06080C")

	# Antena helicoidal à esquerda
	_g_rect(g, 19, 4, 4, 22, body_dk)
	_g_rect(g, 20, 4, 2, 20, body_md)
	for ry in range(6, 22, 3):
		_g_rect(g, 19, ry, 4, 1, body_hi)
	# Botões rotativos no topo
	_g_rect(g, 32, 16, 6, 6, knob)
	_g_rect(g, 41, 17, 5, 5, knob)

	# Corpo principal do transceptor VHF BFP
	_g_rect(g, 16, 21, 32, 41, body_dk)
	_g_rect(g, 18, 22, 28, 39, body_md)
	_g_rect(g, 18, 22, 28, 2, body_hi)
	# Visor LCD cyan iluminado + ondas de frequência
	_g_rect(g, 21, 26, 22, 11, screen_dk)
	_g_rect(g, 23, 30, 2, 3, screen_glow)
	_g_rect(g, 26, 28, 2, 7, screen_glow)
	_g_rect(g, 29, 29, 2, 5, screen_glow)
	_g_rect(g, 32, 27, 2, 9, screen_glow)
	_g_rect(g, 35, 30, 2, 4, screen_glow)
	_g_rect(g, 38, 31, 3, 2, screen_glow)
	# LED TX âmbar
	_g_rect(g, 41, 24, 2, 2, led_amber)
	# Grade de alto-falante
	for sy in range(41, 55, 3):
		_g_rect(g, 21, sy, 22, 2, line)
	# Etiqueta amarela BFP na base
	_g_rect(g, 23, 56, 18, 3, Color("#D69E2E"))

	return _fit_bottom_centered_96(_g_outline(g, line), 88)


func _build_contact_sheet(
	normal_busts: Dictionary,
	distorted_busts: Dictionary,
	huwag_casual: Dictionary,
	huwag_bfp: Dictionary
) -> void:
	# Prancha comparativa: fila 1-2 = normal sobre xadrez + normal sobre #000000 Omori;
	# fila 3 = distorted sobre #000000; fila 4 = huwag expressões sobre #000000.
	var cols := 10
	var rows := 5
	var sheet := Image.create(cols * TARGET_SIZE, rows * TARGET_SIZE, false, Image.FORMAT_RGBA8)
	var keys := normal_busts.keys()

	for r in range(rows):
		for c in range(cols):
			var ox := c * TARGET_SIZE
			var oy := r * TARGET_SIZE
			var use_checker := (r == 0)
			for py in range(TARGET_SIZE):
				for px in range(TARGET_SIZE):
					var bg_col := Color(0.0, 0.0, 0.0, 1.0)
					if use_checker:
						var chk := ((int(px / 8) + int(py / 8)) % 2) == 0
						bg_col = Color("#464D58") if chk else Color("#303640")
					sheet.set_pixel(ox + px, oy + py, bg_col)

	# Row 0 & 1: 15 normal NPCs/Entities sobre xadrez e preto (primeiros 10 em r=0, próximos 5 + 5 Huwag BFP/Casual em r=1)
	for i in range(mini(10, keys.size())):
		_blit_alpha(sheet, normal_busts[keys[i]], i * TARGET_SIZE, 0)
	for i in range(10, keys.size()):
		_blit_alpha(sheet, normal_busts[keys[i]], (i - 10) * TARGET_SIZE, TARGET_SIZE)
	_blit_alpha(sheet, huwag_casual["neutral"], 5 * TARGET_SIZE, TARGET_SIZE)
	_blit_alpha(sheet, huwag_bfp["neutral"], 6 * TARGET_SIZE, TARGET_SIZE)
	_blit_alpha(sheet, huwag_casual["worried"], 7 * TARGET_SIZE, TARGET_SIZE)
	_blit_alpha(sheet, huwag_casual["angry"], 8 * TARGET_SIZE, TARGET_SIZE)
	_blit_alpha(sheet, huwag_casual["distorted"], 9 * TARGET_SIZE, TARGET_SIZE)

	# Row 2 & 3: Todas as 15 variantes distorcidas surreais + Huwag expressões restantes
	for i in range(mini(10, keys.size())):
		_blit_alpha(sheet, distorted_busts[keys[i]], i * TARGET_SIZE, 2 * TARGET_SIZE)
	for i in range(10, keys.size()):
		_blit_alpha(sheet, distorted_busts[keys[i]], (i - 10) * TARGET_SIZE, 3 * TARGET_SIZE)
	var rem_exprs := ["tired", "surprised", "scared", "uneasy_smile", "unfiltered"]
	for i in range(rem_exprs.size()):
		_blit_alpha(sheet, huwag_bfp[rem_exprs[i]], (5 + i) * TARGET_SIZE, 3 * TARGET_SIZE)

	# Row 4: Normal sobre fundo branco #F0F0F0 nos primeiros 10 para denunciar qualquer contorno falho
	for x in range(cols * TARGET_SIZE):
		for y in range(4 * TARGET_SIZE, 5 * TARGET_SIZE):
			sheet.set_pixel(x, y, Color("#EAECEF"))
	for i in range(mini(10, keys.size())):
		_blit_alpha(sheet, normal_busts[keys[i]], i * TARGET_SIZE, 4 * TARGET_SIZE)

	sheet.save_png(SCRATCH_SHEET)
	print("  [ContactSheet] Prancha visual salva em %s" % SCRATCH_SHEET)


func _blit_alpha(dst: Image, src: Image, ox: int, oy: int) -> void:
	for y in range(src.get_height()):
		for x in range(src.get_width()):
			var c := src.get_pixel(x, y)
			if c.a > 0.5:
				dst.set_pixel(ox + x, oy + y, c)
