extends RefCounted
class_name V4CastPortraits

## Retratos 96x96 nativos em estética ANIME PIXEL ART (Anexos 2, 4 e 5):
## queixo em V delicado, bochechas suaves, olhos grandes com brilho/pálpebra/olheiras,
## nariz mínimo de 1-2px e mechas orgânicas em curva Bézier com fidelidade horror nos corrompidos.

const C := preload("res://scripts/tools/portraits_v4/v4_canvas.gd")


# ==============================================================================
# PROTAGONISTA: HUWAG MATITIIS (Casual, BFP, Ato 3 Unfiltered & Corrompido)
# ==============================================================================

static func _draw_huwag_head_and_hair(fg: Image, sk: Dictionary, outfit: String, expr: String, mode: String) -> Dictionary:
	var is_unfilt := (mode == "unfiltered" or expr == "unfiltered")
	var is_corr := (mode == "corrupted")

	var ink_h := Color("#261B12") if not is_unfilt else Color("#242428")
	var root_c := Color("#16131C") if not is_corr else Color("#0A060D")
	var bl_hi := Color("#F7EEAE") if not is_unfilt else Color("#C8CACF")
	var bl_mid := Color("#E5D37E") if not is_unfilt else Color("#A5A7AD")
	var bl_sh := Color("#AD944E") if not is_unfilt else Color("#6C6E74")
	if is_corr:
		bl_hi = Color("#D6BA8A")
		bl_mid = Color("#9B7E55")
		bl_sh = Color("#543A2C")
		ink_h = Color("#140B0E")

	# 1. Cabelo de trás (raízes escuras rente à nuca e atrás das orelhas, sem orelhas de cachorro soltas!)
	C.draw_anime_crown(fg, 47.5, 29.0, 24.5, 16.5, root_c, Color("#0C0A10"), root_c, ink_h)
	C.disc(fg, 25.5, 42.0, 3.2, 6.5, root_c)
	C.disc(fg, 69.5, 42.0, 3.2, 6.5, root_c)

	# 2. Rosto anime protagonista (testa 2px menor, olhos/sobrancelhas elevados e queixo menos pontudo)
	var lm := C.sculpt_anime_face(fg, sk, "huwag", 0, 1, 0)
	var ey: int = lm["eye_y"]
	var elx: int = lm["el_x"]
	var erx: int = lm["er_x"]

	# 3. Expressão facial anime (olheiras marcadas + olhar cansado/sério + nariz lateral 3D!)
	if is_corr:
		C.draw_anime_eyes(fg, lm, sk, Color("#361E18"), "scared", "huwag", Color("#171219"))
		C.draw_anime_nose_mouth(fg, lm, sk, "neutral" if outfit == "casual" else "scared")
	else:
		var e_mood := expr
		if expr == "determined":
			e_mood = "angry"
		elif expr == "smile":
			e_mood = "uneasy_smile"
		C.draw_anime_eyes(fg, lm, sk, Color("#40281D"), e_mood, "huwag", Color("#1C151D"))
		if expr in ["scared", "worried"]:
			# Gota de suor estilo anime na têmpora
			C.disc(fg, 65.5, float(ey + 2), 1.8, 2.8, Color("#C6ECFF"))
			C.px(fg, 65, ey + 1, Color("#FFFFFF"))
			C.line_px(fg, 64, ey + 1, 64, ey + 4, Color("#3B698A"))
		C.draw_anime_nose_mouth(fg, lm, sk, e_mood)

	# 4. Ombros e gola inclinados anime POR CIMA do pescoço
	if outfit == "bfp":
		var nav_h := Color("#313D54") if not is_unfilt else Color("#4E5056")
		var nav_m := Color("#1E2638") if not is_unfilt else Color("#35373D")
		var nav_s := Color("#101521") if not is_unfilt else Color("#1D1E24")
		var nav_i := Color("#0A0D16")
		C.draw_anime_shoulders(fg, 81, 95, nav_m, nav_s, nav_h, nav_i, 36, 8, 47)
		# Gola branca interna + faixa refletiva amarela BFP + fecho metálico D-ring
		for dy in range(6):
			C.span(fg, 41 + dy, 53 - dy, 83 + dy, Color("#E3DFD6") if not is_unfilt else Color("#95979B"))
		var refl := Color("#DCE846") if not is_unfilt else Color("#A0A2A6")
		C.rect(fg, 20, 91, 41, 93, refl)
		C.rect(fg, 53, 91, 75, 93, refl)
		C.span(fg, 17, 78, 94, Color("#99A2AD") if not is_unfilt else Color("#6C6E74"))
		C.rect(fg, 43, 89, 51, 93, Color("#88909B"))
		C.rect(fg, 45, 91, 49, 92, Color("#4E555E"))
	else:
		var blk_h := Color("#2D303C") if not is_unfilt else Color("#46484E")
		var blk_m := Color("#181A22") if not is_unfilt else Color("#2A2C32")
		var blk_s := Color("#0B0C11") if not is_unfilt else Color("#15161A")
		C.draw_anime_shoulders(fg, 81, 95, blk_m, blk_s, blk_h, Color("#07070A"), 35, 8, 47)
		# Camiseta cinza escura no V + dobra caída natural do capuz + zíper limpo
		for dy in range(8):
			C.span(fg, 41 + dy / 2, 53 - dy / 2, 83 + dy, Color("#242630") if not is_unfilt else Color("#383A40"))
		C.draw_hair_strand(fg, Vector2(36, 81), Vector2(39, 86), Vector2(44, 91), 3.2, 2.0, blk_h, blk_m, blk_h, Color("#07070A"), false, true)
		C.draw_hair_strand(fg, Vector2(59, 81), Vector2(56, 86), Vector2(51, 91), 3.2, 2.0, blk_m, blk_s, blk_m, Color("#07070A"), false, true)
		for zy in range(90, 96):
			C.px(fg, 47, zy, Color("#7A828F") if zy % 2 == 0 else Color("#4D535E"))

	# 5. Cabelo loiro-palha arrepiado ANIME com volume acima da cabeça + mechas em Bézier + raízes escuras!
	# Copa volumosa superior
	C.draw_anime_crown(fg, 47.5, 22.0, 23.0, 12.5, bl_mid, bl_sh, bl_hi, ink_h)
	# Pontas arrepiadas dinâmicas ao redor da copa (curvas em Bézier afilando até 1px!)
	C.draw_hair_strand(fg, Vector2(31, 18), Vector2(25, 11), Vector2(21, 5), 4.6, 0.5, bl_hi, bl_mid, bl_hi, ink_h, true, true)
	C.draw_hair_strand(fg, Vector2(39, 15), Vector2(36, 8), Vector2(34, 2), 4.8, 0.5, bl_hi, bl_mid, bl_hi, ink_h, true, true)
	C.draw_hair_strand(fg, Vector2(47, 14), Vector2(48, 7), Vector2(48, 1), 5.0, 0.5, bl_mid, bl_sh, bl_hi, ink_h, true, true)
	C.draw_hair_strand(fg, Vector2(54, 15), Vector2(58, 9), Vector2(61, 4), 4.8, 0.5, bl_mid, bl_sh, bl_hi, ink_h, false, true)
	C.draw_hair_strand(fg, Vector2(61, 18), Vector2(68, 13), Vector2(74, 9), 4.5, 0.5, bl_mid, bl_sh, bl_hi, ink_h, false, true)
	C.draw_hair_strand(fg, Vector2(66, 23), Vector2(74, 21), Vector2(79, 20), 4.2, 0.5, bl_mid, bl_sh, bl_hi, ink_h, false, true)
	C.draw_hair_strand(fg, Vector2(67, 29), Vector2(74, 31), Vector2(78, 35), 3.6, 0.5, bl_sh, bl_sh, bl_mid, ink_h, false, true)
	C.draw_hair_strand(fg, Vector2(27, 22), Vector2(20, 18), Vector2(16, 15), 4.2, 0.5, bl_hi, bl_mid, bl_hi, ink_h, true, true)
	C.draw_hair_strand(fg, Vector2(26, 28), Vector2(19, 29), Vector2(16, 33), 3.8, 0.5, bl_mid, bl_sh, bl_hi, ink_h, false, true)

	# Raízes escuras marcadas nas têmporas e costeletas sobre as orelhas (identidade oficial do sprite!)
	C.draw_hair_strand(fg, Vector2(26, 33), Vector2(24, 41), Vector2(26, 51), 3.0, 0.5, root_c, Color("#0C0A10"), root_c, ink_h, false, false)
	C.draw_hair_strand(fg, Vector2(69, 33), Vector2(71, 41), Vector2(69, 51), 3.0, 0.5, root_c, Color("#0C0A10"), root_c, ink_h, false, false)

	# Franja repicada loira caindo organicamente sem esconder os olhos expressivos
	C.draw_hair_strand(fg, Vector2(31, 25), Vector2(28, 33), Vector2(27, 42), 4.2, 0.5, bl_hi, bl_mid, bl_hi, ink_h, true, false)
	C.draw_hair_strand(fg, Vector2(37, 24), Vector2(36, 32), Vector2(35, 39), 4.2, 0.5, bl_hi, bl_mid, bl_hi, ink_h, true, false)
	C.draw_hair_strand(fg, Vector2(41, 22), Vector2(41, 29), Vector2(40, 35), 3.6, 0.4, bl_hi, bl_mid, bl_hi, ink_h, true, false)
	C.draw_hair_strand(fg, Vector2(46, 23), Vector2(47, 33), Vector2(47, 43), 4.6, 0.5, bl_hi, bl_sh, bl_hi, ink_h, true, false)
	C.draw_hair_strand(fg, Vector2(51, 22), Vector2(52, 29), Vector2(53, 35), 3.5, 0.4, bl_mid, bl_sh, bl_hi, ink_h, false, false)
	C.draw_hair_strand(fg, Vector2(55, 23), Vector2(57, 32), Vector2(59, 40), 4.2, 0.5, bl_mid, bl_sh, bl_hi, ink_h, false, false)
	C.draw_hair_strand(fg, Vector2(63, 25), Vector2(66, 33), Vector2(68, 42), 4.0, 0.5, bl_mid, bl_sh, bl_hi, ink_h, false, false)

	return lm


static func build_huwag_portrait(outfit: String, expr: String) -> Image:
	if expr == "distorted":
		var bg := C.backdrop_horror_dither(Color("#940E16"), Color("#090407"), "duotone_red" if outfit == "casual" else "crimson_dither")
		var fg := C.new_canvas()
		var sk := C.skin_tones("#BE8962", "ash" if outfit == "bfp" else "blood_lit")
		var lm := _draw_huwag_head_and_hair(fg, sk, outfit, "distorted", "corrupted")
		var ey: int = lm["eye_y"]
		var my: int = lm["mouth_y"]
		if outfit == "casual":
			# Metade direita em breu total; olho esquerdo lacrimejando sangue; olho direito carmesim + sorriso rasgado anime!
			C.split_half_shadow(fg, lm, "right")
			for lx in [lm["el_x"] + 3, lm["el_x"] + 6, lm["el_x"] + 8]:
				C.quad_bezier_line(fg, Vector2(lx, ey + 7), Vector2(lx - 1, ey + 13), Vector2(lx + 1, ey + 19), Color("#800D18"), 1)
			# Olho esquerdo vermelho brilhante
			C.disc(fg, float(lm["el_x"] + 6), float(ey + 4), 2.5, 2.8, Color("#FF2E3C"))
			C.px(fg, lm["el_x"] + 5, ey + 3, Color("#FFFFFF"))
			# Olho direito arregalado dentro do breu absoluto!
			C.disc(fg, float(lm["er_x"] + 6), float(ey + 4), 5.0, 3.6, Color("#F2ECE6"))
			C.disc(fg, float(lm["er_x"] + 5), float(ey + 4), 2.4, 2.6, Color("#FF2436"))
			C.px(fg, lm["er_x"] + 4, ey + 3, Color("#FFFFFF"))
			# Sorriso anatômico rasgado acompanhando a bochecha com cavidade funda, borda muscular e dentes irregulares
			var lip_m := Color("#6E1E26")
			var rim_m := Color("#3D0C14")
			var cav_m := Color("#170206")
			# Sulco muscular na bochecha exposta puxada para cima
			C.quad_bezier_line(fg, Vector2(36, my - 2), Vector2(34, my + 1), Vector2(36, my + 4), sk["sh"], 1)
			for gx in range(37, 65):
				var t_g := float(gx - 37) / 27.0
				var yc := int(round(float(my + 1) - pow(t_g, 1.45) * 9.0 + sin(t_g * PI) * 2.2))
				var half_open := 1 if (gx < 41 or gx > 61) else 2
				C.px(fg, gx, yc - half_open - 1, lip_m if gx < 47 else rim_m)
				for gy in range(yc - half_open, yc + half_open + 1):
					C.px(fg, gx, gy, cav_m)
				C.px(fg, gx, yc + half_open + 1, sk["sh"] if gx < 47 else rim_m)
				if gx in [42, 43, 45, 48, 51, 52, 55, 58]:
					C.px(fg, gx, yc - half_open + 1, Color("#E3D8CE") if gx < 49 else Color("#B59EA2"))
				if gx in [44, 47, 50, 53, 56]:
					C.px(fg, gx, yc + half_open - 1, Color("#C4B0AA") if gx < 49 else Color("#8F6C72"))
		else:
			C.split_half_shadow(fg, lm, "left")
			C.disc(fg, float(lm["el_x"] + 6), float(ey + 4), 2.8, 2.3, Color("#FF7538"))
			C.px(fg, lm["el_x"] + 5, ey + 3, Color("#FFF0B8"))
			# Lágrima escura de fuligem/sangue escorrendo pela bochecha exposta à direita
			var tear_x : int = int(lm["er_x"]) + 3
			C.quad_bezier_line(fg, Vector2(tear_x, ey + 7), Vector2(tear_x + 1, ey + 14), Vector2(tear_x - 1, ey + 21), Color("#2A0810"), 2)
			C.line_px(fg, tear_x, ey + 8, tear_x, ey + 17, Color("#7A1624"))
			C.px(fg, tear_x - 1, ey + 21, Color("#540C18"))
			# Rachaduras incandescentes subindo pelo pescoço BFP e rosto
			C.quad_bezier_line(fg, Vector2(43, 92), Vector2(48, 81), Vector2(54, 69), Color("#0A0407"), 2)
			C.quad_bezier_line(fg, Vector2(44, 90), Vector2(49, 80), Vector2(53, 71), Color("#D94A1E"), 1)
		return C.composite(bg, fg)

	var is_unfilt := (expr == "unfiltered")
	var bg_col := Color("#5A6E62") if outfit == "casual" else Color("#53677E")
	if is_unfilt:
		bg_col = Color("#6B6C70")
	var bg := C.backdrop_solid(bg_col)
	var fg := C.new_canvas()
	var sk := C.skin_tones("#BE8962", "unfiltered" if is_unfilt else "normal")
	_draw_huwag_head_and_hair(fg, sk, outfit, expr, "unfiltered" if is_unfilt else "normal")
	return C.composite(bg, fg)


# ==============================================================================
# HELPER DE CHAPÉUS ANIME COM ABAS ORGÂNICAS E SOMBRA PROJETADA
# ==============================================================================

static func _draw_peaked_cap(
	fg: Image, lm: Dictionary, crown_m: Color, crown_h: Color, crown_s: Color,
	visor_c: Color, badge_c: Color, ink_c: Color, shift_y: int = 0, low_shadow: bool = false
) -> void:
	var cy := 21.0 + float(shift_y)
	C.draw_anime_crown(fg, 47.5, cy, 24.5, 11.0, crown_m, crown_s, crown_h, ink_c)
	# Emblema frontal limpo
	C.disc(fg, 47.5, cy - 2.0, 3.0, 2.8, badge_c)
	C.px(fg, 46, int(cy - 3), Color("#FFF7D6"))
	# Aba curva do boné/quepe
	var vy := 31 + shift_y
	for y in range(vy, vy + 5):
		var t := float(y - vy) / 4.0
		var hw := int(round(lerpf(25.0, 22.0, t)))
		var vy_curve := y + int(round((1.0 - t) * 2.0))
		C.span(fg, 47 - hw, 48 + hw, vy_curve, visor_c if y < vy + 3 else ink_c)
	if low_shadow:
		var ey_s : int = int(lm["eye_y"])
		for x in range(28, 68):
			var dx_n : float = absf(float(x) - 47.5) / 20.0
			var hatch : int = (2 if (x % 2 == 0) else 0) + (2 if (absf(float(x) - 47.5) < 7.0) else 0)
			var y_lim : int = int(round(float(ey_s) + 6.5 - pow(dx_n, 1.35) * 4.5)) + hatch
			for y in range(vy + 4, y_lim):
				if fg.get_pixel(x, y).a > 0.5:
					C.px(fg, x, y, Color("#070408") if y < y_lim - 2 else Color("#1D1018"))
	else:
		C.quad_bezier_line(fg, Vector2(25, vy + 5), Vector2(47, vy + 7), Vector2(70, vy + 5), Color("#3B282A"), 2)


# ==============================================================================
# ELENCO COMPLETO — PARES NORMAL vs CORROMPIDO EM ESTÉTICA ANIME PIXEL ART
# ==============================================================================

static func build_cap_reyes(corrupted: bool) -> Image:
	if corrupted:
		var bg := C.backdrop_horror_dither(Color("#8F0D14"), Color("#070306"), "crimson_dither")
		var fg := C.new_canvas()
		var sk := C.skin_tones("#B47E5A", "corpse")
		var lm := C.sculpt_anime_face(fg, sk, "male_adult", 0, 1, 0)
		C.draw_anime_nose_mouth(fg, lm, sk, "angry", true, Color("#6E6A6E"))
		C.draw_anime_shoulders(fg, 82, 95, Color("#10141E"), Color("#07080D"), Color("#1E2436"), Color("#05060A"), 36, 7, 47)
		C.rect(fg, 44, 85, 50, 95, Color("#5E1019"))
		# Sangramento escorrendo dos cantos da boca cerrada sobre o uniforme
		C.quad_bezier_line(fg, Vector2(42, lm["mouth_y"] + 2), Vector2(40, 76), Vector2(42, 90), Color("#9E101B"), 2)
		C.quad_bezier_line(fg, Vector2(52, lm["mouth_y"] + 2), Vector2(54, 77), Vector2(52, 88), Color("#730B14"), 2)
		# Sombra opressiva do quepe engolindo metade do rosto + 2 olhos pálidos fixos
		_draw_peaked_cap(fg, lm, Color("#121724"), Color("#1C2336"), Color("#090C14"), Color("#07090F"), Color("#9E6822"), Color("#050408"), 4, true)
		var ey: int = lm["eye_y"]
		C.disc(fg, 37.0, float(ey + 5), 1.8, 1.8, Color("#F5EFE8"))
		C.disc(fg, 58.0, float(ey + 3), 2.0, 2.0, Color("#FFE28A"))
		return C.composite(bg, fg)

	var bg := C.backdrop_solid(Color("#AE8A52"))
	var fg := C.new_canvas()
	var sk := C.skin_tones("#B47E5A")
	var lm := C.sculpt_anime_face(fg, sk, "male_adult", 0, 1, 0)
	C.draw_anime_eyes(fg, lm, sk, Color("#3B241A"), "stern", "male_adult", Color("#5B606B"))
	# Linhas discretas de idade madura anime (pés de galinha sutis)
	C.px(fg, lm["el_x"] - 2, lm["eye_y"] + 5, sk["sh"]); C.px(fg, lm["er_x"] + 13, lm["eye_y"] + 5, sk["sh"])
	C.draw_anime_nose_mouth(fg, lm, sk, "stern", true, Color("#BAC0CA"), false, true)
	C.draw_anime_shoulders(fg, 82, 95, Color("#202B44"), Color("#121928"), Color("#2E3E61"), Color("#0B0F1A"), 36, 7, 47)
	for dy in range(7):
		C.span(fg, 41 + dy / 2, 53 - dy / 2, 84 + dy, Color("#EAE4D8"))
	C.rect(fg, 19, 91, 41, 94, Color("#DF7228")); C.rect(fg, 54, 91, 76, 94, Color("#DF7228"))
	# Costeletas grisalhas anime nas têmporas + quepe naval elegante
	C.draw_hair_strand(fg, Vector2(26, 36), Vector2(25, 42), Vector2(26, 48), 2.6, 0.5, Color("#9EA4AE"), Color("#6E747E"), Color("#D2D7E0"), Color("#1B1D24"), false, true)
	C.draw_hair_strand(fg, Vector2(69, 36), Vector2(70, 42), Vector2(69, 48), 2.6, 0.5, Color("#6E747E"), Color("#4B4F57"), Color("#9EA4AE"), Color("#1B1D24"), false, true)
	_draw_peaked_cap(fg, lm, Color("#1D2840"), Color("#2D3D61"), Color("#121828"), Color("#0D121E"), Color("#F2C249"), Color("#090C14"), 0, false)
	return C.composite(bg, fg)


static func build_bombeiro_ato(corrupted: bool) -> Image:
	if corrupted:
		var bg := C.backdrop_horror_dither(Color("#91180E"), Color("#080304"), "crimson_dither")
		var fg := C.new_canvas()
		var sk := C.skin_tones("#B8805B", "ash")
		var lm := C.sculpt_anime_face(fg, sk, "male_adult", 0, 1, 2)
		# Metade direita carbonizada com rachaduras de brasa ardente
		for y in range(28, 78):
			for x in range(47, 74):
				if fg.get_pixel(x, y).a > 0.5:
					C.px(fg, x, y, Color("#0E080A"))
		C.draw_anime_eyes(fg, lm, sk, Color("#FFE082"), "angry", "male_adult", Color("#1C1414"))
		# Escurece olho direito carbonizado deixando olho esquerdo brilhando ember + fissura incandescente!
		for y in range(41, 56):
			C.span(fg, 48, 66, y, Color("#0E080A"))
		C.quad_bezier_line(fg, Vector2(51, 34), Vector2(58, 49), Vector2(61, 66), Color("#FF641E"), 2)
		C.quad_bezier_line(fg, Vector2(52, 37), Vector2(57, 49), Vector2(60, 62), Color("#FFD466"), 1)
		# Boca gritando com dentes expostos pela fenda da mandíbula
		C.disc(fg, 48.0, 65.0, 9.0, 5.0, Color("#080305"))
		for tx in [41, 44, 47, 50, 53]:
			C.rect(fg, tx, 62, tx + 1, 64, Color("#E3D8CC"))
			C.rect(fg, tx, 66, tx + 1, 67, Color("#BDAFA2"))
		C.px(fg, 54, 65, Color("#FF7326"))
		C.draw_anime_shoulders(fg, 81, 95, Color("#1A1314"), Color("#0A0607"), Color("#301D1A"), Color("#050304"), 36, 5, 47)
		C.rect(fg, 18, 91, 77, 94, Color("#D44B1A"))
		_draw_peaked_cap(fg, lm, Color("#66441A"), Color("#855922"), Color("#3D270E"), Color("#291A12"), Color("#AD2323"), Color("#120905"), 1, false)
		C.quad_bezier_line(fg, Vector2(46, 11), Vector2(50, 22), Vector2(52, 34), Color("#080304"), 2)
		C.px(fg, 49, 20, Color("#FF7326")); C.px(fg, 50, 26, Color("#FFD466"))
		return C.composite(bg, fg)

	var bg := C.backdrop_solid(Color("#9D5D46"))
	var fg := C.new_canvas()
	var sk := C.skin_tones("#B8805B")
	# Protetor traseiro curvo do capacete bombeiro
	C.disc(fg, 47.5, 36.0, 28.0, 12.0, Color("#8A5612"))
	var lm := C.sculpt_anime_face(fg, sk, "male_adult", 0, 1, 0)
	C.draw_anime_eyes(fg, lm, sk, Color("#382216"), "stern", "male_adult", Color("#1C1514"))
	C.draw_anime_nose_mouth(fg, lm, sk, "stern")
	C.draw_anime_shoulders(fg, 81, 95, Color("#212733"), Color("#13171F"), Color("#323B4D"), Color("#0A0D12"), 36, 5, 47)
	C.rect(fg, 19, 90, 76, 92, Color("#F0B838")); C.rect(fg, 17, 93, 78, 95, Color("#E36B24"))
	_draw_peaked_cap(fg, lm, Color("#E3A422"), Color("#FFE266"), Color("#B07612"), Color("#222833"), Color("#AD2323"), Color("#291808"), 1, false)
	return C.composite(bg, fg)


static func build_bombeiro_santos(corrupted: bool) -> Image:
	if corrupted:
		var bg := C.backdrop_horror_dither(Color("#8F1018"), Color("#0A0508"), "crimson_dither")
		var fg := C.new_canvas()
		var sk := C.skin_tones("#BE8962", "pale")
		var ink_h := Color("#07070A")
		C.draw_anime_crown(fg, 47.5, 31.0, 24.5, 17.5, Color("#0E0F14"), Color("#07080B"), Color("#1E222E"), ink_h)
		var lm := C.sculpt_anime_face(fg, sk, "teen", 0, 1, 0)
		C.draw_anime_eyes(fg, lm, sk, Color("#2E1216"), "scared", "teen", Color("#100B0E"))
		# Olheiras carmesim marcadas + lágrimas de sangue escorrendo pelas bochechas anime!
		for lx in [lm["el_x"] + 2, lm["el_x"] + 6, lm["er_x"] + 5, lm["er_x"] + 9]:
			C.quad_bezier_line(fg, Vector2(lx, lm["eye_y"] + 10), Vector2(lx - 1, lm["eye_y"] + 16), Vector2(lx + 1, lm["eye_y"] + 23), Color("#A81422"), 2)
		C.span(fg, lm["el_x"] + 1, lm["el_x"] + 10, lm["eye_y"] + 10, Color("#B81624"))
		C.span(fg, lm["er_x"] + 1, lm["er_x"] + 10, lm["eye_y"] + 10, Color("#B81624"))
		C.draw_anime_nose_mouth(fg, lm, sk, "scared")
		C.draw_anime_shoulders(fg, 81, 95, Color("#171921"), Color("#0B0C10"), Color("#262A36"), Color("#06070A"), 34, 7, 47)
		C.draw_anime_crown(fg, 47.5, 22.0, 23.0, 11.5, Color("#12131A"), Color("#08080C"), Color("#262C3D"), ink_h)
		for pt in [
			[Vector2(31, 22), Vector2(28, 32), Vector2(26, 43)],
			[Vector2(40, 20), Vector2(39, 31), Vector2(37, 41)],
			[Vector2(49, 20), Vector2(51, 31), Vector2(51, 41)],
			[Vector2(58, 21), Vector2(61, 32), Vector2(63, 42)],
			[Vector2(65, 24), Vector2(69, 34), Vector2(70, 45)],
		]:
			C.draw_hair_strand(fg, pt[0], pt[1], pt[2], 3.8, 0.5, Color("#12131A"), Color("#08080C"), Color("#262C3D"), ink_h, false, false)
		return C.composite(bg, fg)

	var bg := C.backdrop_solid(Color("#618C94"))
	var fg := C.new_canvas()
	var sk := C.skin_tones("#BE8962")
	var ink_h := Color("#0E0F15")
	C.draw_anime_crown(fg, 47.5, 31.0, 24.0, 16.5, Color("#151721"), Color("#0D0F16"), Color("#2D364D"), ink_h)
	var lm := C.sculpt_anime_face(fg, sk, "teen", 0, 1, 0)
	C.draw_anime_eyes(fg, lm, sk, Color("#33221A"), "worried", "teen", Color("#17141C"))
	C.draw_anime_nose_mouth(fg, lm, sk, "worried")
	C.draw_anime_shoulders(fg, 81, 95, Color("#202736"), Color("#121620"), Color("#2E384D"), Color("#0B0E14"), 34, 7, 47)
	for dy in range(6):
		C.span(fg, 41 + dy / 2, 53 - dy / 2, 83 + dy, Color("#EDE8E0"))
	C.rect(fg, 19, 92, 76, 94, Color("#F2BA3A"))
	# Franja repicada macia caindo sobre a testa com reflexo anime
	C.draw_anime_crown(fg, 47.5, 21.5, 22.8, 11.2, Color("#1D212E"), Color("#11131C"), Color("#435173"), ink_h)
	for pt in [
		[Vector2(29, 23), Vector2(26, 33), Vector2(25, 45)],
		[Vector2(36, 20), Vector2(34, 30), Vector2(32, 39)],
		[Vector2(41, 19), Vector2(41, 27), Vector2(40, 34)],
		[Vector2(45, 19), Vector2(46, 30), Vector2(46, 40)],
		[Vector2(50, 19), Vector2(51, 27), Vector2(52, 34)],
		[Vector2(54, 19), Vector2(57, 30), Vector2(58, 39)],
		[Vector2(63, 21), Vector2(67, 32), Vector2(69, 44)],
	]:
		C.draw_hair_strand(fg, pt[0], pt[1], pt[2], 4.2, 0.5, Color("#1D212E"), Color("#11131C"), Color("#435173"), ink_h, true, false)
	return C.composite(bg, fg)


static func build_enfermeira_maria(corrupted: bool) -> Image:
	if corrupted:
		var bg := C.backdrop_horror_dither(Color("#5C0A18"), Color("#0B0409"), "crimson_dither")
		var fg := C.new_canvas()
		var sk := C.skin_tones("#CA956E", "corpse")
		var ink_h := Color("#12080A")
		# Cabelo longo solto molhado caindo pelos dois lados atrás dos ombros
		C.draw_hair_strand(fg, Vector2(26, 36), Vector2(20, 62), Vector2(23, 94), 6.5, 4.0, Color("#1E1113"), Color("#10080A"), Color("#382124"), ink_h, false, true)
		C.draw_hair_strand(fg, Vector2(69, 36), Vector2(75, 62), Vector2(72, 94), 6.5, 4.0, Color("#140B0C"), Color("#0A0506"), Color("#29171A"), ink_h, false, true)
		var lm := C.sculpt_anime_face(fg, sk, "fem", 0, 0, -2)
		# Olhos encovados chorando rios vermelhos pelas bochechas em V + mordida na boca + arranhões no pescoço
		C.draw_anime_eyes(fg, lm, sk, Color("#B81422"), "scared", "fem", Color("#180C0E"))
		for lx in [lm["el_x"] + 3, lm["el_x"] + 7, lm["er_x"] + 4, lm["er_x"] + 8]:
			C.quad_bezier_line(fg, Vector2(lx, lm["eye_y"] + 8), Vector2(lx - 1, lm["eye_y"] + 16), Vector2(lx + 1, lm["eye_y"] + 25), Color("#9C101B"), 2)
		C.draw_anime_nose_mouth(fg, lm, sk, "scared")
		C.quad_bezier_line(fg, Vector2(46, lm["mouth_y"] + 3), Vector2(47, 72), Vector2(46, 79), Color("#9C101B"), 1)
		C.quad_bezier_line(fg, Vector2(39, 77), Vector2(46, 76), Vector2(54, 75), Color("#A8121E"), 1)
		C.quad_bezier_line(fg, Vector2(40, 80), Vector2(48, 79), Vector2(55, 78), Color("#800D17"), 1)
		C.draw_anime_shoulders(fg, 81, 95, Color("#858991"), Color("#4A4D54"), Color("#B0B4BC"), Color("#26282E"), 32, 8, 47)
		C.draw_anime_crown(fg, 47.5, 22.0, 23.0, 12.0, Color("#241514"), Color("#120A0A"), Color("#422A28"), ink_h)
		C.draw_hair_strand(fg, Vector2(28, 28), Vector2(21, 50), Vector2(24, 76), 4.8, 1.0, Color("#241514"), Color("#120A0A"), Color("#422A28"), ink_h, false, false)
		C.draw_hair_strand(fg, Vector2(67, 28), Vector2(74, 50), Vector2(71, 76), 4.8, 1.0, Color("#180D0C"), Color("#0C0606"), Color("#2E1C1B"), ink_h, false, false)
		C.draw_hair_strand(fg, Vector2(44, 19), Vector2(36, 30), Vector2(30, 41), 4.8, 0.6, Color("#241514"), Color("#120A0A"), Color("#422A28"), ink_h, false, false)
		C.draw_hair_strand(fg, Vector2(48, 19), Vector2(57, 30), Vector2(64, 41), 4.8, 0.6, Color("#1D1010"), Color("#0F0808"), Color("#36201F"), ink_h, false, false)
		return C.composite(bg, fg)

	var bg := C.backdrop_solid(Color("#86B0B5"))
	var fg := C.new_canvas()
	var sk := C.skin_tones("#CA956E")
	var ink_h := Color("#1E100E")
	# Coque baixo elegante bem preso atrás da nuca esquerda + fundo do cabelo
	C.disc(fg, 27.0, 56.0, 7.2, 8.0, Color("#331D16"))
	C.draw_anime_crown(fg, 47.5, 28.0, 23.0, 16.0, Color("#2E1B15"), Color("#1E100D"), Color("#5C3A2E"), ink_h)
	var lm := C.sculpt_anime_face(fg, sk, "fem", 0, 1, 0)
	C.draw_anime_eyes(fg, lm, sk, Color("#4D2D1E"), "warm", "fem", Color("#331F18"))
	C.draw_anime_nose_mouth(fg, lm, sk, "warm", false, Color("#5A5E66"), true)
	C.draw_anime_shoulders(fg, 81, 95, Color("#EBF0F5"), Color("#BCC7D4"), Color("#FFFFFF"), Color("#3A4659"), 32, 8, 47)
	# Jaleco aberto em V mostrando uniforme bordô hospitalar por dentro
	for dy in range(7):
		C.span(fg, 41 + dy / 2, 53 - dy / 2, 84 + dy, Color("#7A2B38") if dy < 4 else Color("#5E1E29"))
	# Franja partida em cortina suave estilo anime + mechas emoldurando bochechas + presilha vermelha
	C.draw_anime_crown(fg, 47.5, 22.0, 22.5, 11.5, Color("#3D241C"), Color("#241410"), Color("#6E4638"), ink_h)
	C.draw_hair_strand(fg, Vector2(46, 18), Vector2(36, 28), Vector2(28, 44), 5.2, 0.6, Color("#3D241C"), Color("#241410"), Color("#6E4638"), ink_h, true, false)
	C.draw_hair_strand(fg, Vector2(49, 18), Vector2(59, 28), Vector2(67, 44), 5.2, 0.6, Color("#3D241C"), Color("#241410"), Color("#6E4638"), ink_h, true, false)
	C.draw_hair_strand(fg, Vector2(26, 30), Vector2(22, 46), Vector2(25, 62), 4.0, 0.5, Color("#3D241C"), Color("#241410"), Color("#6E4638"), ink_h, false, false)
	C.draw_hair_strand(fg, Vector2(69, 30), Vector2(73, 46), Vector2(70, 62), 4.0, 0.5, Color("#2E1B15"), Color("#1E100D"), Color("#4F3025"), ink_h, false, false)
	C.rect(fg, 26, 40, 30, 42, Color("#D93B4E"))
	return C.composite(bg, fg)


static func build_aling_nena(corrupted: bool) -> Image:
	if corrupted:
		var bg := C.backdrop_horror_dither(Color("#7D0B18"), Color("#070306"), "crimson_dither")
		var fg := C.new_canvas()
		var sk := C.skin_tones("#B27852", "pale")
		var ink_h := Color("#0B080D")
		C.draw_anime_crown(fg, 47.5, 34.0, 25.0, 22.0, Color("#141118"), Color("#08060A"), Color("#2E2633"), ink_h)
		var lm := C.sculpt_anime_face(fg, sk, "fem", 0, 1, 0)
		C.draw_anime_eyes(fg, lm, sk, Color("#1E1015"), "scared", "fem", Color("#141118"))
		C.draw_anime_nose_mouth(fg, lm, sk, "uneasy_smile")
		C.draw_anime_shoulders(fg, 81, 95, Color("#3B1424"), Color("#1C0710"), Color("#521D32"), Color("#12040A"), 34, 7, 47)
		C.draw_anime_crown(fg, 47.5, 22.0, 23.0, 11.5, Color("#141118"), Color("#08060A"), Color("#2E2633"), ink_h)
		C.draw_hair_strand(fg, Vector2(27, 29), Vector2(23, 46), Vector2(26, 62), 4.2, 0.6, Color("#141118"), Color("#08060A"), Color("#2E2633"), ink_h, false, false)
		# Metade direita engolida pelo breu + olho dourado + sorriso rasgado anatômico na divisão!
		C.split_half_shadow(fg, lm, "right")
		C.disc(fg, float(lm["er_x"] + 6), float(lm["eye_y"] + 4), 4.2, 2.8, Color("#FFE24A"))
		C.disc(fg, float(lm["er_x"] + 5), float(lm["eye_y"] + 4), 1.8, 2.0, Color("#D6192C"))
		var n_my: int = lm["mouth_y"]
		for gx in range(38, 65):
			var t_n := float(gx - 38) / 26.0
			var yc := int(round(float(n_my + 1) - pow(t_n, 1.45) * 9.0 + sin(t_n * PI) * 2.0))
			var ho := 1 if (gx < 42 or gx > 61) else 2
			C.px(fg, gx, yc - ho - 1, Color("#7A1A26"))
			for gy in range(yc - ho, yc + ho + 1):
				C.px(fg, gx, gy, Color("#1A0308"))
			C.px(fg, gx, yc + ho + 1, Color("#5E1822"))
			if gx in [43, 47, 51, 55, 59]:
				C.px(fg, gx, yc, Color("#E8DCE0") if gx < 49 else Color("#B87078"))
		return C.composite(bg, fg)

	var bg := C.backdrop_solid(Color("#9C6A75"))
	var fg := C.new_canvas()
	var sk := C.skin_tones("#B47A54")
	var ink_h := Color("#161119")
	C.draw_anime_crown(fg, 47.5, 34.0, 25.0, 21.0, Color("#1B1721"), Color("#100D14"), Color("#443D4D"), ink_h)
	var lm := C.sculpt_anime_face(fg, sk, "fem", 0, 1, 0)
	C.draw_anime_eyes(fg, lm, sk, Color("#362016"), "warm", "fem", Color("#261D20"))
	C.draw_anime_nose_mouth(fg, lm, sk, "warm")
	C.draw_anime_shoulders(fg, 81, 95, Color("#6E2A42"), Color("#451727"), Color("#8F3B58"), Color("#240A14"), 34, 7, 47)
	# Xale bege tricotado caído em V nos ombros
	C.draw_hair_strand(fg, Vector2(31, 80), Vector2(38, 86), Vector2(46, 93), 4.5, 1.8, Color("#E3C8A2"), Color("#C2A076"), Color("#F5E3C6"), Color("#523926"), false, true)
	C.draw_hair_strand(fg, Vector2(63, 80), Vector2(56, 86), Vector2(48, 93), 4.5, 1.8, Color("#DEC29B"), Color("#AD8B62"), Color("#E3C8A2"), Color("#523926"), false, true)
	C.draw_anime_crown(fg, 47.5, 22.0, 23.2, 11.8, Color("#241E2B"), Color("#131017"), Color("#4A4259"), ink_h)
	C.draw_hair_strand(fg, Vector2(41, 20), Vector2(33, 28), Vector2(26, 40), 4.6, 0.5, Color("#241E2B"), Color("#131017"), Color("#4A4259"), ink_h, true, false)
	C.draw_hair_strand(fg, Vector2(53, 20), Vector2(61, 28), Vector2(69, 41), 4.6, 0.5, Color("#241E2B"), Color("#131017"), Color("#4A4259"), ink_h, false, false)
	C.draw_hair_strand(fg, Vector2(26, 34), Vector2(22, 48), Vector2(26, 62), 4.2, 0.5, Color("#241E2B"), Color("#131017"), Color("#4A4259"), ink_h, false, false)
	C.draw_hair_strand(fg, Vector2(69, 34), Vector2(73, 48), Vector2(69, 62), 4.2, 0.5, Color("#19141E"), Color("#0F0C12"), Color("#383142"), ink_h, false, false)
	C.rect(fg, 27, 34, 32, 36, Color("#E3526A"))
	return C.composite(bg, fg)


static func build_kuya_ben(corrupted: bool) -> Image:
	if corrupted:
		var bg := C.backdrop_horror_dither(Color("#5E0B1A"), Color("#070307"), "crimson_dither")
		var fg := C.new_canvas()
		var sk := C.skin_tones("#AA724D", "ash")
		var lm := C.sculpt_anime_face(fg, sk, "male_wide", 1, 0, -2)
		var ey: int = lm["eye_y"]
		# Cavidades orbitais irregulares sombreadas + pupilas carmesim brilhando + mechas molhadas sob o quepe
		C.draw_anime_eyes(fg, lm, sk, Color("#080306"), "scared", "male_wide", Color("#0E090C"))
		for ep_x in [int(lm["el_x"]) + 6, int(lm["er_x"]) + 6]:
			C.disc(fg, float(ep_x), float(ey + 4), 4.6, 3.4, Color("#12070D"))
			C.disc(fg, float(ep_x), float(ey + 4), 3.0, 2.2, Color("#060206"))
			C.disc(fg, float(ep_x), float(ey + 4), 1.4, 1.4, Color("#FF3B48"))
			C.px(fg, ep_x - 1, ey + 3, Color("#FFD6D6"))
		# Boca em grito oval alongado dentro do rosto anime
		C.disc(fg, 47.0, 65.0, 5.6, 7.2, Color("#070306"))
		C.disc(fg, 47.0, 66.2, 3.0, 3.8, Color("#4D0912"))
		C.span(fg, 44, 50, 59, Color("#EDE5DC"))
		C.draw_anime_shoulders(fg, 82, 95, Color("#1A263D"), Color("#0C121E"), Color("#293B5C"), Color("#070B14"), 35, 7, 47)
		C.draw_hair_strand(fg, Vector2(36, 80), Vector2(36, 87), Vector2(37, 95), 4.2, 3.2, Color("#8D8E94"), Color("#61636B"), Color("#B0B1B8"), Color("#181920"), false, true)
		C.draw_hair_strand(fg, Vector2(59, 80), Vector2(59, 87), Vector2(58, 95), 4.2, 3.2, Color("#61636B"), Color("#42444D"), Color("#8D8E94"), Color("#181920"), false, true)
		_draw_peaked_cap(fg, lm, Color("#132036"), Color("#1E3152"), Color("#09101C"), Color("#070C14"), Color("#9EA6B5"), Color("#05080F"), -1, false)
		C.draw_hair_strand(fg, Vector2(28, 34), Vector2(24, 38), Vector2(25, 44), 2.4, 0.5, Color("#18161C"), Color("#0C0A0F"), Color("#2C2833"), Color("#050408"), false, false)
		C.draw_hair_strand(fg, Vector2(67, 34), Vector2(71, 38), Vector2(70, 44), 2.4, 0.5, Color("#18161C"), Color("#0C0A0F"), Color("#2C2833"), Color("#050408"), false, false)
		return C.composite(bg, fg)

	var bg := C.backdrop_solid(Color("#C2A472"))
	var fg := C.new_canvas()
	var sk := C.skin_tones("#AA724D")
	var lm := C.sculpt_anime_face(fg, sk, "male_wide", 0, 1, 0)
	C.draw_anime_eyes(fg, lm, sk, Color("#301D14"), "gruff", "male_wide", Color("#1B1412"))
	C.draw_anime_nose_mouth(fg, lm, sk, "gruff", true, Color("#241916"))
	C.draw_anime_shoulders(fg, 81, 95, Color("#2A4470"), Color("#192945"), Color("#3C5E96"), Color("#0E182B"), 35, 7, 47)
	# Toalha enrolada na nuca caindo pelos ombros
	C.draw_hair_strand(fg, Vector2(36, 79), Vector2(36, 87), Vector2(38, 95), 4.5, 3.2, Color("#F2F0E9"), Color("#CFCBC0"), Color("#FFFFFF"), Color("#3B3934"), false, true)
	C.draw_hair_strand(fg, Vector2(59, 79), Vector2(59, 87), Vector2(57, 95), 4.5, 3.2, Color("#E3DFD6"), Color("#B5B1A6"), Color("#F2F0E9"), Color("#3B3934"), false, true)
	_draw_peaked_cap(fg, lm, Color("#294778"), Color("#3B63A3"), Color("#1B2F52"), Color("#162847"), Color("#E6ECF5"), Color("#0C1629"), -2, false)
	C.draw_hair_strand(fg, Vector2(28, 32), Vector2(25, 37), Vector2(26, 43), 2.2, 0.5, Color("#221C1B"), Color("#141010"), Color("#382E2C"), Color("#0E0B0B"), false, false)
	C.draw_hair_strand(fg, Vector2(67, 32), Vector2(70, 37), Vector2(69, 43), 2.2, 0.5, Color("#221C1B"), Color("#141010"), Color("#382E2C"), Color("#0E0B0B"), false, false)
	return C.composite(bg, fg)


static func _draw_salakot(fg: Image, c_hi: Color, c_mid: Color, c_sh: Color, ink_c: Color, ragged: bool = false) -> void:
	## Chapéu cônico filipino Salakot estilo anime (silhueta limpa + linhas finas de palha e contorno 1px)
	for y in range(6, 37):
		var t := float(y - 6) / 30.0
		var hw := 2 + int(round(pow(t, 1.22) * 39.0))
		var xl := 47 - hw
		var xr := 48 + hw
		if ragged and y > 32:
			xl -= (y % 3)
			xr += ((y + 1) % 3)
		for x in range(xl + 1, xr):
			var nx := float(x - 47) / maxf(1.0, float(hw))
			var col := c_hi if nx < -0.15 else (c_mid if nx < 0.45 else c_sh)
			if y % 6 == 0:
				col = c_sh if nx > 0.0 else c_mid
			C.px(fg, x, y, col)
		C.px(fg, xl, y, ink_c)
		C.px(fg, xr, y, ink_c)
	C.span(fg, 47 - 41, 48 + 41, 37, ink_c)
	C.disc(fg, 47.5, 5.5, 3.0, 2.2, c_hi)


static func build_feirante(corrupted: bool) -> Image:
	if corrupted:
		var bg := C.backdrop_horror_dither(Color("#7A1214"), Color("#080406"), "crimson_dither")
		var fg := C.new_canvas()
		var sk := C.skin_tones("#AD744F", "ash")
		var lm := C.sculpt_anime_face(fg, sk, "male_wide", 0, 2, 0)
		var ey_f : int = int(lm["eye_y"])
		for x in range(26, 70):
			var dx_n : float = absf(float(x) - 47.5) / 22.0
			var hatch : int = (2 if (x % 2 == 0) else 0) + (2 if (absf(float(x) - 47.5) < 8.0) else 0)
			var y_lim : int = int(round(float(ey_f) + 6.0 - pow(dx_n, 1.3) * 4.5)) + hatch
			for y in range(28, y_lim):
				if fg.get_pixel(x, y).a > 0.5:
					C.px(fg, x, y, Color("#080406") if y < y_lim - 2 else Color("#1D0E12"))
		# 3 olhos anime sinistros espiando de dentro da sombra escura do chapéu
		for pt in [Vector2i(35, 46), Vector2i(48, 43), Vector2i(61, 47)]:
			C.disc(fg, float(pt.x), float(pt.y), 4.2, 2.2, Color("#FAF4EE"))
			C.disc(fg, float(pt.x), float(pt.y), 1.8, 1.8, Color("#B81422"))
			C.px(fg, pt.x - 1, pt.y - 1, Color("#FFFFFF"))
		# Sorriso largo crescente com cavidade negra e presas assimétricas irregulares
		C.quad_bezier_line(fg, Vector2(32, 58), Vector2(48, 70), Vector2(64, 57), Color("#070204"), 2)
		for x in range(34, 62):
			var nx : float = absf(float(x) - 48.0) / 14.0
			var y_top : int = int(round(60.0 + (1.0 - nx * nx) * 1.5))
			var y_bot : int = int(round(67.5 - nx * nx * 6.0))
			for y in range(y_top, y_bot + 1):
				C.px(fg, x, y, Color("#070204") if y < y_bot else Color("#1E090E"))
		# Presas superiores assimétricas
		C.line_px(fg, 37, 60, 38, 63, Color("#E3D8C8"))
		C.line_px(fg, 42, 61, 42, 64, Color("#D1C4B2"))
		C.line_px(fg, 47, 61, 48, 63, Color("#E8DDD0"))
		C.line_px(fg, 54, 60, 53, 64, Color("#E3D8C8"))
		C.line_px(fg, 58, 59, 58, 62, Color("#BEB2A2"))
		# Presas inferiores desencontradas
		C.line_px(fg, 40, 66, 40, 64, Color("#BEB2A2"))
		C.line_px(fg, 45, 67, 46, 65, Color("#E3D8C8"))
		C.line_px(fg, 51, 67, 50, 64, Color("#D1C4B2"))
		C.line_px(fg, 56, 65, 56, 63, Color("#BEB2A2"))
		C.draw_anime_shoulders(fg, 82, 95, Color("#26331F"), Color("#12190E"), Color("#394C2E"), Color("#090D07"), 34, 7, 47)
		_draw_salakot(fg, Color("#5E4826"), Color("#423118"), Color("#291E0E"), Color("#0B0704"), true)
		C.draw_hair_strand(fg, Vector2(12, 36), Vector2(10, 44), Vector2(12, 51), 1.4, 0.4, Color("#423118"), Color("#291E0E"), Color("#5E4826"), Color("#0B0704"), false, true)
		C.draw_hair_strand(fg, Vector2(84, 36), Vector2(85, 44), Vector2(83, 51), 1.4, 0.4, Color("#423118"), Color("#291E0E"), Color("#5E4826"), Color("#0B0704"), false, true)
		return C.composite(bg, fg)

	var bg := C.backdrop_solid(Color("#7C8F66"))
	var fg := C.new_canvas()
	var sk := C.skin_tones("#AD744F")
	var lm := C.sculpt_anime_face(fg, sk, "male_wide", 0, 2, 0)
	C.draw_anime_eyes(fg, lm, sk, Color("#301E16"), "gruff", "male_wide", Color("#261B16"))
	C.draw_anime_nose_mouth(fg, lm, sk, "gruff", false, Color("#5A5E66"), false, true)
	C.draw_anime_shoulders(fg, 82, 95, Color("#3B522E"), Color("#25361D"), Color("#4F6E3E"), Color("#152010"), 34, 7, 47)
	for dy in range(6):
		C.span(fg, 41 + dy / 2, 53 - dy / 2, 84 + dy, Color("#ECE8DE"))
	_draw_salakot(fg, Color("#E3C066"), Color("#C99E46"), Color("#9A7127"), Color("#33220B"), false)
	C.quad_bezier_line(fg, Vector2(18, 38), Vector2(47, 40), Vector2(77, 38), sk["sh"], 1)
	return C.composite(bg, fg)


static func build_mang_carding(corrupted: bool) -> Image:
	if corrupted:
		var bg := C.backdrop_horror_dither(Color("#36114A"), Color("#06030A"), "void_purple")
		var fg := C.new_canvas()
		var sk := C.skin_tones("#965E3B", "ash")
		var lm := C.sculpt_anime_face(fg, sk, "elder", 0, 1, 2)
		var ey: int = lm["eye_y"]
		# Olho esquerdo oco chorando líquido preto + bigode cansado
		C.disc(fg, float(lm["el_x"] + 6), float(ey + 4), 5.0, 4.2, Color("#050308"))
		C.disc(fg, float(lm["el_x"] + 6), float(ey + 4), 1.8, 1.8, Color("#FFE270"))
		C.quad_bezier_line(fg, Vector2(lm["el_x"] + 6, ey + 8), Vector2(lm["el_x"] + 5, 62), Vector2(lm["el_x"] + 7, 81), Color("#0B0712"), 2)
		C.draw_anime_nose_mouth(fg, lm, sk, "unfiltered", true, Color("#636872"))
		C.draw_anime_shoulders(fg, 81, 95, Color("#152D38"), Color("#09151C"), Color("#224452"), Color("#050C12"), 34, 6, 47)
		C.quad_bezier_line(fg, Vector2(23, 81), Vector2(33, 88), Vector2(43, 95), Color("#66563D"), 3)
		# Bandana turquesa desbotada com contorno 1px + mechas pesadas encharcadas cobrindo o olho direito!
		C.draw_anime_crown(fg, 47.5, 22.0, 22.0, 10.5, Color("#1A2029"), Color("#0E1117"), Color("#2E3745"), Color("#08090D"))
		C.rect(fg, 25, 28, 70, 32, Color("#144B52"))
		C.span(fg, 25, 70, 27, Color("#061B20"))
		C.span(fg, 25, 70, 33, Color("#061B20"))
		C.line_px(fg, 24, 28, 24, 32, Color("#061B20"))
		C.line_px(fg, 71, 28, 71, 32, Color("#061B20"))
		C.draw_hair_strand(fg, Vector2(25, 30), Vector2(18, 39), Vector2(14, 51), 3.2, 0.6, Color("#144B52"), Color("#0A2C33"), Color("#206B75"), Color("#061B20"), false, true)
		C.draw_hair_strand(fg, Vector2(27, 32), Vector2(24, 38), Vector2(25, 44), 2.8, 0.5, Color("#1A2029"), Color("#0E1117"), Color("#2E3745"), Color("#05060A"), false, false)
		C.draw_hair_strand(fg, Vector2(56, 23), Vector2(61, 41), Vector2(59, 63), 4.8, 0.8, Color("#0F1522"), Color("#07090F"), Color("#1E283D"), Color("#05060A"), false, false)
		C.draw_hair_strand(fg, Vector2(64, 26), Vector2(69, 44), Vector2(67, 67), 4.2, 0.7, Color("#0A0D16"), Color("#05060A"), Color("#151C2B"), Color("#040508"), false, false)
		return C.composite(bg, fg)

	var bg := C.backdrop_solid(Color("#4D707D"))
	var fg := C.new_canvas()
	var sk := C.skin_tones("#9E6642")
	var lm := C.sculpt_anime_face(fg, sk, "elder", 0, 1, 0)
	C.draw_anime_eyes(fg, lm, sk, Color("#2E1D14"), "tired", "elder", Color("#5B616C"))
	C.draw_anime_nose_mouth(fg, lm, sk, "neutral", true, Color("#BAC0CA"))
	C.draw_anime_shoulders(fg, 81, 95, Color("#244E5C"), Color("#15303A"), Color("#366C7D"), Color("#0C1C22"), 34, 6, 47)
	C.quad_bezier_line(fg, Vector2(23, 81), Vector2(33, 88), Vector2(43, 95), Color("#CFB276"), 3)
	C.draw_anime_crown(fg, 47.5, 22.0, 22.2, 10.5, Color("#737985"), Color("#4D525C"), Color("#A5ACB8"), Color("#2A2D34"))
	C.rect(fg, 25, 28, 70, 32, Color("#30C4BE"))
	C.span(fg, 25, 70, 27, Color("#0F4D4E"))
	C.span(fg, 26, 68, 29, Color("#6EEAE4"))
	C.span(fg, 25, 70, 33, Color("#0F4D4E"))
	C.line_px(fg, 24, 28, 24, 32, Color("#0F4D4E"))
	C.line_px(fg, 71, 28, 71, 32, Color("#0F4D4E"))
	C.draw_hair_strand(fg, Vector2(25, 29), Vector2(16, 33), Vector2(11, 39), 3.6, 0.5, Color("#30C4BE"), Color("#1E8F8E"), Color("#6EEAE4"), Color("#0F4D4E"), false, true)
	C.draw_hair_strand(fg, Vector2(27, 32), Vector2(24, 38), Vector2(26, 44), 2.8, 0.5, Color("#737985"), Color("#4D525C"), Color("#A5ACB8"), Color("#2A2D34"), false, false)
	C.draw_hair_strand(fg, Vector2(68, 32), Vector2(71, 38), Vector2(69, 44), 2.8, 0.5, Color("#5E6470"), Color("#3B404A"), Color("#89909E"), Color("#2A2D34"), false, false)
	return C.composite(bg, fg)


static func _paint_finger_limb(
	fg: Image, p0: Vector2, p1: Vector2, p2: Vector2,
	w0: float, w1: float, hi_c: Color, mid_c: Color, sh_c: Color, ink_c: Color, nail: bool = false
) -> void:
	var steps := maxi(14, int((p0.distance_to(p1) + p1.distance_to(p2)) * 1.5))
	for i in range(steps + 1):
		var t := float(i) / float(steps)
		var omt := 1.0 - t
		var pt := omt * omt * p0 + 2.0 * omt * t * p1 + t * t * p2
		var hw := lerpf(w0, w1, pow(t, 0.85))
		C.disc(fg, pt.x, pt.y, hw + 1.0, hw + 1.0, ink_c)
	for i in range(steps + 1):
		var t := float(i) / float(steps)
		var omt := 1.0 - t
		var pt := omt * omt * p0 + 2.0 * omt * t * p1 + t * t * p2
		var hw := maxf(0.5, lerpf(w0, w1, pow(t, 0.85)) - 0.15)
		var ix0 := maxi(0, int(floor(pt.x - hw)))
		var ix1 := mini(C.SIZE - 1, int(ceil(pt.x + hw)))
		var iy0 := maxi(0, int(floor(pt.y - hw)))
		var iy1 := mini(C.SIZE - 1, int(ceil(pt.y + hw)))
		for y in range(iy0, iy1 + 1):
			for x in range(ix0, ix1 + 1):
				var dx := float(x) - pt.x
				var dy := float(y) - pt.y
				if dx * dx + dy * dy <= hw * hw:
					var col_f := mid_c
					if dx < -hw * 0.25 and t > 0.20:
						col_f = hi_c
					elif dx > hw * 0.28 or t < 0.16:
						col_f = sh_c
					C.px(fg, x, y, col_f)
		if t > 0.44 and t < 0.50:
			C.px(fg, int(round(pt.x)), int(round(pt.y)), sh_c)
	if nail:
		var tx := int(round(p2.x))
		var ty := int(round(p2.y))
		C.px(fg, tx, ty, Color("#FBF5EE"))
		C.px(fg, tx - 1, ty + 1, Color("#DED0C6"))


static func build_toby(corrupted: bool) -> Image:
	if corrupted:
		var bg := C.backdrop_horror_dither(Color("#940C16"), Color("#070306"), "duotone_red")
		var fg := C.new_canvas()
		var sk := C.skin_tones("#BE8962", "corpse")
		var ink_h := Color("#0B0609")
		C.draw_anime_crown(fg, 47.5, 31.0, 24.5, 16.0, Color("#0E0A0E"), Color("#070408"), Color("#211A24"), ink_h)
		var lm := C.sculpt_anime_face(fg, sk, "child", 0, 1, 0)
		C.draw_anime_eyes(fg, lm, sk, Color("#1C0B10"), "scared", "child", Color("#0C0609"))
		C.draw_anime_nose_mouth(fg, lm, sk, "worried")
		C.draw_anime_shoulders(fg, 83, 95, Color("#66511A"), Color("#36280B"), Color("#8A6E26"), Color("#1F1706"), 30, 5, 47)
		C.rect(fg, 27, 83, 32, 95, Color("#244D29")); C.rect(fg, 62, 83, 67, 95, Color("#1A3B1E"))
		# Boné escuro + franja bagunçada lançando sombra espessa sobre a testa
		for y in range(28, 35):
			C.span(fg, 28, 67, y, Color("#120A0E") if y < 34 else ink_h)
		C.draw_anime_crown(fg, 47.5, 24.0, 23.0, 11.5, Color("#120A0E"), Color("#090407"), Color("#291B24"), ink_h)
		for pt in [
			[Vector2(30, 28), Vector2(28, 36), Vector2(27, 43)],
			[Vector2(39, 27), Vector2(39, 35), Vector2(40, 42)],
			[Vector2(50, 27), Vector2(51, 35), Vector2(51, 42)],
			[Vector2(60, 28), Vector2(63, 36), Vector2(65, 43)],
		]:
			C.draw_hair_strand(fg, pt[0], pt[1], pt[2], 3.8, 0.5, Color("#120A0E"), Color("#090407"), Color("#241920"), ink_h, false, false)

		# Mão infantil pálida esculpida anatomicamente com contorno 1px entre dedos e sombras interdigitais
		var ink := Color("#12080C")
		var h_hi := Color("#EFE6DC")
		var h_mid := Color("#D1C1B8")
		var h_sh := Color("#947E78")
		var h_cleft := Color("#5A4442")
		_paint_finger_limb(fg, Vector2(57, 95), Vector2(57, 88), Vector2(57, 81), 7.6, 6.8, h_hi, h_mid, h_sh, ink, false)
		# Mindinho dobrado na lateral direita + anelar, médio e indicador com fendas bem separadas
		_paint_finger_limb(fg, Vector2(64, 82), Vector2(67, 85), Vector2(65, 89), 2.3, 2.0, h_mid, h_sh, h_cleft, ink, false)
		_paint_finger_limb(fg, Vector2(63, 81), Vector2(65, 72), Vector2(67, 64), 2.5, 1.7, h_hi, h_mid, h_sh, ink, true)
		_paint_finger_limb(fg, Vector2(57, 79), Vector2(57, 68), Vector2(57, 59), 2.6, 1.8, h_hi, h_mid, h_sh, ink, true)
		_paint_finger_limb(fg, Vector2(50, 81), Vector2(49, 71), Vector2(47, 62), 2.5, 1.7, h_hi, h_mid, h_sh, ink, true)
		# Sombra profunda nos vãos entre os dedos (juntas da palma) + polegar dobrado por cima
		for vy in range(74, 80):
			C.px(fg, 53, vy, ink if vy < 77 else h_cleft)
			C.px(fg, 61, vy, ink if vy < 77 else h_cleft)
			C.px(fg, 54, vy, h_sh if vy >= 76 else ink)
			C.px(fg, 60, vy, h_sh if vy >= 76 else ink)
		_paint_finger_limb(fg, Vector2(49, 86), Vector2(54, 83), Vector2(59, 84), 3.0, 2.1, h_mid, h_sh, h_cleft, ink, false)
		C.quad_bezier_line(fg, Vector2(54, 89), Vector2(58, 91), Vector2(63, 89), h_cleft, 1)
		return C.composite(bg, fg)

	var bg := C.backdrop_solid(Color("#7BB3A2"))
	var fg := C.new_canvas()
	var sk := C.skin_tones("#D29D76")
	var ink_h := Color("#1D1620")
	C.draw_anime_crown(fg, 47.5, 31.0, 24.5, 15.5, Color("#1E1B24"), Color("#121017"), Color("#3B3647"), ink_h)
	var lm := C.sculpt_anime_face(fg, sk, "child", 0, 1, 0)
	C.draw_anime_eyes(fg, lm, sk, Color("#4D2E1B"), "surprised", "child", Color("#1D1920"))
	C.draw_anime_nose_mouth(fg, lm, sk, "warm", false, Color("#5A5E66"), true)
	C.draw_anime_shoulders(fg, 83, 95, Color("#E5B226"), Color("#A37614"), Color("#FFE059"), Color("#5C3F0B"), 30, 5, 47)
	C.rect(fg, 27, 83, 32, 95, Color("#498C52")); C.rect(fg, 62, 83, 67, 95, Color("#3A7342"))
	# Base contínua de cabelo sob o boné + boné vermelho virado para trás + franja cheia infantil
	for y in range(28, 35):
		var col_b := Color("#24202C") if y < 33 else (Color("#141118") if y == 33 else ink_h)
		C.span(fg, 28, 67, y, col_b)
	C.draw_anime_crown(fg, 47.5, 23.0, 23.0, 11.5, Color("#DE4232"), Color("#9C271E"), Color("#FF7566"), Color("#5E140E"))
	C.draw_hair_strand(fg, Vector2(26, 27), Vector2(18, 29), Vector2(12, 32), 3.6, 1.8, Color("#9C271E"), Color("#701A13"), Color("#DE4232"), Color("#5E140E"), false, true)
	C.rect(fg, 42, 27, 53, 30, Color("#F2EBE0"))
	for pt in [
		[Vector2(30, 29), Vector2(28, 36), Vector2(27, 42)],
		[Vector2(37, 28), Vector2(38, 36), Vector2(39, 42)],
		[Vector2(47, 28), Vector2(48, 36), Vector2(49, 42)],
		[Vector2(57, 28), Vector2(59, 36), Vector2(61, 42)],
		[Vector2(65, 29), Vector2(68, 37), Vector2(70, 44)],
	]:
		C.draw_hair_strand(fg, pt[0], pt[1], pt[2], 3.8, 0.5, Color("#24202C"), Color("#141118"), Color("#433C52"), ink_h, true, false)
	return C.composite(bg, fg)


static func build_senhora_luningning(corrupted: bool) -> Image:
	if corrupted:
		var bg := C.backdrop_horror_dither(Color("#380B42"), Color("#060208"), "void_purple")
		var fg := C.new_canvas()
		var sk := C.skin_tones("#BF8E72", "corpse")
		var ink_h := Color("#282930")
		C.draw_anime_crown(fg, 47.5, 34.0, 25.0, 20.0, Color("#565861"), Color("#363840"), Color("#818491"), ink_h)
		var lm := C.sculpt_anime_face(fg, sk, "elder_fem", 0, 0, 0)
		var ey: int = lm["eye_y"]
		for bx in [lm["el_x"] + 6, lm["er_x"] + 6]:
			C.disc(fg, float(bx), float(ey + 4), 4.6, 5.6, Color("#07020A"))
			C.px(fg, bx, ey + 4, Color("#FFFFFF"))
			C.quad_bezier_line(fg, Vector2(bx, ey + 8), Vector2(bx - 1, ey + 17), Vector2(bx, ey + 26), Color("#1E0610"), 2)
			C.quad_bezier_line(fg, Vector2(bx + 2, ey + 9), Vector2(bx + 2, ey + 16), Vector2(bx + 1, ey + 22), Color("#800D1E"), 1)
		C.draw_anime_nose_mouth(fg, lm, sk, "unfiltered", false, Color("#5A5E66"), false, true)
		C.draw_anime_shoulders(fg, 81, 95, Color("#331740"), Color("#180920"), Color("#4B235E"), Color("#0E0414"), 32, 7, 47)
		C.draw_anime_crown(fg, 47.5, 22.0, 22.0, 11.5, Color("#7A7C85"), Color("#4B4D54"), Color("#9EA1AB"), ink_h)
		C.draw_hair_strand(fg, Vector2(28, 28), Vector2(21, 45), Vector2(20, 68), 4.2, 0.5, Color("#7A7C85"), Color("#4B4D54"), Color("#9EA1AB"), ink_h, false, false)
		C.draw_hair_strand(fg, Vector2(67, 28), Vector2(74, 45), Vector2(75, 68), 4.2, 0.5, Color("#60626B"), Color("#3B3D44"), Color("#7A7C85"), ink_h, false, false)
		return C.composite(bg, fg)

	var bg := C.backdrop_solid(Color("#867094"))
	var fg := C.new_canvas()
	var sk := C.skin_tones("#C59579")
	var ink_h := Color("#4C505C")
	C.draw_anime_crown(fg, 47.0, 13.0, 11.5, 7.5, Color("#DCE1EB"), Color("#AEB5C4"), Color("#F2F5FC"), ink_h)  # coque alto prateado
	C.draw_anime_crown(fg, 47.5, 29.0, 23.0, 15.0, Color("#A4ABB8"), Color("#7A8191"), Color("#DCE1EB"), ink_h)
	var lm := C.sculpt_anime_face(fg, sk, "elder_fem", 0, 2, 0)
	C.draw_anime_eyes(fg, lm, sk, Color("#402E34"), "sad", "elder_fem", Color("#7A7F8A"))
	C.draw_anime_nose_mouth(fg, lm, sk, "worried", false, Color("#5A5E66"), false, true)
	C.draw_anime_shoulders(fg, 81, 95, Color("#9674AB"), Color("#5E4570"), Color("#BD9BD1"), Color("#352242"), 32, 7, 47)
	for dy in range(6):
		C.span(fg, 41 + dy / 2, 53 - dy / 2, 84 + dy, Color("#6D3178"))
	C.draw_anime_crown(fg, 47.5, 22.0, 22.0, 11.0, Color("#C6CCD6"), Color("#8F96A3"), Color("#EEF2FC"), ink_h)
	C.draw_hair_strand(fg, Vector2(46, 18), Vector2(36, 26), Vector2(26, 40), 4.8, 0.6, Color("#C6CCD6"), Color("#8F96A3"), Color("#EEF2FC"), ink_h, true, false)
	C.draw_hair_strand(fg, Vector2(49, 18), Vector2(59, 26), Vector2(69, 40), 4.8, 0.6, Color("#C6CCD6"), Color("#8F96A3"), Color("#EEF2FC"), ink_h, false, false)
	return C.composite(bg, fg)


static func build_lola_rosa(corrupted: bool) -> Image:
	if corrupted:
		var bg := C.backdrop_horror_dither(Color("#540C1E"), Color("#070306"), "crimson_dither")
		var fg := C.new_canvas()
		var sk := C.skin_tones("#BA835B", "corpse")
		var v_ink := Color("#060308")
		# Véu escuro de luto caído pelos ombros + rosto pálido enlutado
		C.draw_anime_crown(fg, 47.5, 34.0, 26.0, 24.0, Color("#1E1721"), Color("#0E0A10"), Color("#342838"), v_ink)
		var lm := C.sculpt_anime_face(fg, sk, "elder_fem", 0, 1, 1)
		C.draw_anime_shoulders(fg, 81, 95, Color("#1D2B1B"), Color("#0D140C"), Color("#2C4229"), Color("#070A06"), 34, 7, 47)
		C.draw_anime_crown(fg, 47.5, 22.0, 24.0, 12.5, Color("#241C28"), Color("#120D14"), Color("#3C2E42"), v_ink)
		# Drapeado do xale rasgado emoldurando as têmporas até os ombros + mechas grisalhas soltas
		C.draw_hair_strand(fg, Vector2(26, 26), Vector2(19, 54), Vector2(24, 93), 4.6, 2.2, Color("#241C28"), Color("#120D14"), Color("#3C2E42"), v_ink, false, false)
		C.draw_hair_strand(fg, Vector2(69, 26), Vector2(76, 54), Vector2(71, 93), 4.6, 2.2, Color("#1B141E"), Color("#0C090E"), Color("#2E2333"), v_ink, false, false)
		C.draw_hair_strand(fg, Vector2(36, 72), Vector2(31, 82), Vector2(28, 94), 3.6, 1.4, Color("#6C707A"), Color("#43464F"), Color("#9498A3"), v_ink, false, true)
		# Olheiras arroxeadas fundas sob 4 olhos anime assombrados com pupilas carmesim
		C.disc(fg, 37.0, 49.0, 8.2, 8.0, Color("#21121B"))
		C.disc(fg, 58.0, 49.0, 8.2, 8.0, Color("#21121B"))
		for ep in [Vector2i(36, 44), Vector2i(58, 44), Vector2i(38, 53), Vector2i(58, 54)]:
			C.disc(fg, float(ep.x), float(ep.y), 4.4, 2.4, Color("#0E060B"))
			C.disc(fg, float(ep.x), float(ep.y), 3.1, 1.7, Color("#F5E2B8"))
			C.disc(fg, float(ep.x), float(ep.y), 1.4, 1.4, Color("#B0101D"))
			C.px(fg, ep.x - 1, ep.y - 1, Color("#FFFFFF"))
		# Nariz sutil + boca trêmula escavada em agonia (nunca sorridente!)
		C.px(fg, 47, 56, Color("#3A252E")); C.px(fg, 46, 57, Color("#1A0C12"))
		C.quad_bezier_line(fg, Vector2(40, 66), Vector2(47, 63), Vector2(54, 67), Color("#0C0508"), 1)
		C.disc(fg, 47.0, 66.0, 3.6, 2.0, Color("#0C0508"))
		C.span(fg, 45, 49, 65, Color("#CFC4BC"))
		return C.composite(bg, fg)

	var bg := C.backdrop_solid(Color("#C2B08E"))
	var fg := C.new_canvas()
	var sk := C.skin_tones("#BE8862")
	var ink_v := Color("#544A3D")
	# Alampay (lenço de cabeça) cobrindo lateralmente atrás das orelhas
	C.draw_anime_crown(fg, 47.5, 30.0, 24.5, 17.5, Color("#D6CFBF"), Color("#B5AE9E"), Color("#F5F0E4"), ink_v)
	var lm := C.sculpt_anime_face(fg, sk, "elder_fem", 0, 1, 0)
	C.draw_anime_eyes(fg, lm, sk, Color("#3B251A"), "warm", "elder_fem", Color("#6B7078"))
	C.draw_anime_nose_mouth(fg, lm, sk, "warm", false, Color("#5A5E66"), false, true)
	C.draw_anime_shoulders(fg, 81, 95, Color("#40613C"), Color("#273D24"), Color("#598254"), Color("#162414"), 34, 7, 47)
	for dy in range(5):
		C.span(fg, 42 + dy / 2, 52 - dy / 2, 84 + dy, Color("#EFE9DB"))
	C.draw_anime_crown(fg, 47.5, 22.0, 23.0, 11.5, Color("#EAE4D5"), Color("#C9C2B2"), Color("#FBF7ED"), ink_v)
	C.draw_hair_strand(fg, Vector2(26, 26), Vector2(22, 37), Vector2(23, 47), 3.6, 0.8, Color("#EAE4D5"), Color("#C9C2B2"), Color("#FBF7ED"), ink_v, false, false)
	C.draw_hair_strand(fg, Vector2(69, 26), Vector2(73, 37), Vector2(72, 47), 3.6, 0.8, Color("#D6CFBF"), Color("#B5AE9E"), Color("#EAE4D5"), ink_v, false, false)
	# Trança prateada orgânica descendo suave atrás da orelha sobre o ombro esquerdo (zero corte no rosto!)
	C.draw_hair_strand(fg, Vector2(33, 71), Vector2(29, 82), Vector2(27, 94), 4.0, 1.8, Color("#D4DAE6"), Color("#9DA4B2"), Color("#F2F5FC"), Color("#4D525E"), true, true)
	for by in [78, 84, 90]:
		C.px(fg, 32 - (by - 78) / 2, by, Color("#858C9C"))
	C.disc(fg, 31.0, 27.0, 1.8, 1.6, Color("#DE4F5E"))
	return C.composite(bg, fg)


# ==============================================================================
# ENTIDADES SOBRENATURAIS & RÁDIO (ARHAT SPIRAL / LAGO / CHAMA / OLHO CRT)
# ==============================================================================

static func build_vulto_bosque(corrupted: bool) -> Image:
	if corrupted:
		var bg := C.backdrop_horror_dither(Color("#3D0818"), Color("#060205"), "void_purple")
		var fg := C.new_canvas()
		C.draw_anime_shoulders(fg, 76, 95, Color("#171115"), Color("#090608"), Color("#2E1F24"), Color("#050304"), 38, 0, 47)
		C.rect(fg, 16, 87, 79, 90, Color("#C43616")); C.rect(fg, 14, 91, 81, 93, Color("#FF9E2C"))
		# Cabeça anime velada substituída pelo vácuo com espiral hipnótica estilo Arhat
		C.disc(fg, 47.5, 44.0, 24.0, 27.0, Color("#0A0609"))
		for a_step in range(190):
			var th := float(a_step) * 0.20
			var r := float(a_step) * 0.115
			var sx := int(round(47.5 + cos(th) * r))
			var sy := int(round(44.0 + sin(th) * r * 1.10))
			var col := Color("#FFEBC2") if a_step < 40 else (Color("#FF6A24") if a_step < 110 else Color("#B8142C"))
			C.px(fg, sx, sy, col); C.px(fg, sx + 1, sy, col)
		C.span(fg, 35, 41, 43, Color("#FFFFFF")); C.span(fg, 54, 60, 43, Color("#FFFFFF"))
		return C.composite(bg, fg)

	var bg := C.backdrop_solid(Color("#363A42"))
	var fg := C.new_canvas()
	C.draw_anime_shoulders(fg, 78, 95, Color("#1E2026"), Color("#111216"), Color("#3A4152"), Color("#08090C"), 36, 0, 47)
	C.rect(fg, 19, 89, 76, 92, Color("#853C22"))
	C.disc(fg, 47.5, 44.0, 21.5, 24.0, Color("#14151A"))
	C.draw_anime_crown(fg, 47.5, 22.0, 23.0, 10.5, Color("#242730"), Color("#14151A"), Color("#424A5E"), Color("#0B0C10"))
	C.span(fg, 24, 71, 32, Color("#0B0C10"))
	C.span(fg, 37, 40, 45, Color("#D95E26")); C.span(fg, 55, 58, 45, Color("#D95E26"))
	return C.composite(bg, fg)


static func _draw_webbed_fin(fg: Image, p_base: Vector2, p_tip: Vector2, p_low: Vector2, c_web: Color, c_ray: Color, c_ink: Color) -> void:
	var min_y := mini(int(p_base.y), mini(int(p_tip.y), int(p_low.y)))
	var max_y := maxi(int(p_base.y), maxi(int(p_tip.y), int(p_low.y)))
	for y in range(min_y, max_y + 1):
		var xs: Array[float] = []
		for seg in [[p_base, p_tip], [p_tip, p_low], [p_low, p_base]]:
			var a: Vector2 = seg[0]
			var b: Vector2 = seg[1]
			if (a.y <= float(y) and b.y >= float(y)) or (b.y <= float(y) and a.y >= float(y)):
				if absf(b.y - a.y) > 0.01:
					var t := (float(y) - a.y) / (b.y - a.y)
					xs.append(lerpf(a.x, b.x, t))
		if xs.size() >= 2:
			xs.sort()
			C.span(fg, int(round(xs[0])), int(round(xs[xs.size() - 1])), y, c_web)
	C.quad_bezier_line(fg, p_base, p_tip, p_tip, c_ink, 1)
	C.quad_bezier_line(fg, p_tip, p_low, p_low, c_ink, 1)
	C.line_px(fg, int(p_base.x), int(p_base.y) + 2, int(lerpf(p_base.x, p_tip.x, 0.72)), int(lerpf(p_base.y, p_tip.y, 0.72)), c_ray)


static func build_criatura_lagoa(corrupted: bool) -> Image:
	if corrupted:
		var bg := C.backdrop_horror_dither(Color("#290B40"), Color("#05020A"), "void_purple")
		var fg := C.new_canvas()
		var sk := C.skin_tones("#4C8E8A", "corpse")
		var ink_h := Color("#04090C")
		C.draw_hair_strand(fg, Vector2(26, 36), Vector2(18, 62), Vector2(20, 94), 6.0, 2.5, Color("#0A1A20"), Color("#050D12"), Color("#193D47"), ink_h, false, true)
		C.draw_hair_strand(fg, Vector2(69, 36), Vector2(77, 62), Vector2(75, 94), 6.0, 2.5, Color("#061116"), Color("#03080B"), Color("#122B33"), ink_h, false, true)
		_draw_webbed_fin(fg, Vector2(26, 40), Vector2(8, 22), Vector2(24, 52), Color("#1C4D54"), Color("#4AC4C8"), Color("#091E24"))
		_draw_webbed_fin(fg, Vector2(69, 40), Vector2(87, 22), Vector2(71, 52), Color("#14353D"), Color("#2D8C96"), Color("#07151A"))
		var lm := C.sculpt_anime_face(fg, sk, "fem", 0, 1, 0)
		C.draw_anime_shoulders(fg, 81, 95, Color("#133742"), Color("#081A21"), Color("#225663"), Color("#051014"), 32, 7, 47)
		for ep in [Vector2i(36, 43), Vector2i(58, 43), Vector2i(38, 52), Vector2i(57, 52)]:
			C.disc(fg, float(ep.x), float(ep.y), 4.4, 2.6, Color("#08030F"))
			C.disc(fg, float(ep.x), float(ep.y), 2.8, 1.8, Color("#FFE866"))
			C.px(fg, ep.x - 1, ep.y - 1, Color("#FFFFFF"))
		C.quad_bezier_line(fg, Vector2(39, 63), Vector2(47.5, 69), Vector2(56, 63), Color("#040207"), 1)
		C.disc(fg, 47.5, 64.5, 6.2, 4.8, Color("#050208"))
		C.line_px(fg, 43, 61, 43, 63, Color("#E8E3DC"))
		C.line_px(fg, 46, 60, 46, 63, Color("#CFD8DE"))
		C.line_px(fg, 49, 60, 49, 63, Color("#E8E3DC"))
		C.line_px(fg, 52, 61, 52, 63, Color("#99AFB8"))
		C.line_px(fg, 44, 68, 44, 66, Color("#99AFB8"))
		C.line_px(fg, 48, 69, 48, 66, Color("#E8E3DC"))
		C.line_px(fg, 51, 68, 51, 66, Color("#99AFB8"))
		C.disc(fg, 47.5, 31.0, 2.2, 2.2, Color("#FF4A6B"))
		C.draw_anime_crown(fg, 47.5, 21.0, 22.0, 11.0, Color("#0C1E26"), Color("#050D12"), Color("#1F4754"), ink_h)
		for pt in [
			[Vector2(30, 24), Vector2(24, 42), Vector2(23, 62)],
			[Vector2(41, 20), Vector2(39, 32), Vector2(36, 44)],
			[Vector2(54, 20), Vector2(57, 33), Vector2(60, 45)],
			[Vector2(66, 24), Vector2(71, 44), Vector2(72, 64)],
		]:
			C.draw_hair_strand(fg, pt[0], pt[1], pt[2], 4.2, 0.5, Color("#0C1E26"), Color("#050D12"), Color("#1F4754"), ink_h, false, false)
		return C.composite(bg, fg)

	var bg := C.backdrop_solid(Color("#23505C"))
	var fg := C.new_canvas()
	var sk := C.skin_tones("#7ADBD0")
	var ink_h := Color("#0D333D")
	C.draw_hair_strand(fg, Vector2(26, 36), Vector2(18, 62), Vector2(20, 94), 6.2, 2.8, Color("#1E6775"), Color("#12414D"), Color("#4EC2BA"), ink_h, false, true)
	C.draw_hair_strand(fg, Vector2(69, 36), Vector2(77, 62), Vector2(75, 94), 6.2, 2.8, Color("#144957"), Color("#0B2D38"), Color("#2E8F99"), ink_h, false, true)
	_draw_webbed_fin(fg, Vector2(26, 41), Vector2(10, 24), Vector2(24, 52), Color("#5CE3D6"), Color("#99FFF5"), ink_h)
	_draw_webbed_fin(fg, Vector2(69, 41), Vector2(85, 24), Vector2(71, 52), Color("#268E9B"), Color("#5CE3D6"), ink_h)
	var lm := C.sculpt_anime_face(fg, sk, "fem", 0, 1, 0)
	C.disc(fg, 47.5, 31.0, 2.0, 2.4, Color("#FFE875")); C.px(fg, 47, 30, Color("#FFFFFF"))
	C.draw_anime_eyes(fg, lm, sk, Color("#FFE866"), "sad", "fem", Color("#1D6270"))
	C.draw_anime_nose_mouth(fg, lm, sk, "neutral")
	C.draw_anime_shoulders(fg, 81, 95, Color("#2B8796"), Color("#164E5C"), Color("#56D4C8"), Color("#0E3642"), 32, 7, 47)
	C.draw_anime_crown(fg, 47.5, 22.0, 22.0, 11.2, Color("#247987"), Color("#144957"), Color("#5AD6CA"), ink_h)
	for pt in [
		[Vector2(30, 24), Vector2(24, 42), Vector2(22, 62)],
		[Vector2(42, 20), Vector2(36, 30), Vector2(30, 42)],
		[Vector2(53, 20), Vector2(59, 30), Vector2(65, 42)],
		[Vector2(66, 24), Vector2(72, 42), Vector2(73, 62)],
	]:
		C.draw_hair_strand(fg, pt[0], pt[1], pt[2], 4.4, 0.5, Color("#247987"), Color("#144957"), Color("#5AD6CA"), ink_h, true, false)
	return C.composite(bg, fg)


static func build_santelmo(corrupted: bool) -> Image:
	if corrupted:
		var bg := C.backdrop_horror_dither(Color("#8F0D1F"), Color("#070206"), "crimson_dither")
		var fg := C.new_canvas()
		for y in range(8, 89):
			var ny := float(y - 8) / 80.0
			var sway := sin(ny * 6.0) * 4.5 * (1.0 - ny)
			var rx := 1.5 + sin(pow(ny, 1.62) * PI) * 28.0
			for x in range(int(round(47.5 + sway - rx)), int(round(47.5 + sway + rx)) + 1):
				var d := absf(float(x) - (47.5 + sway)) / maxf(rx, 1.0)
				C.px(fg, x, y, Color("#D61A38") if d > 0.68 else (Color("#FF6347") if d > 0.40 else Color("#FFE6EC")))
		C.draw_hair_strand(fg, Vector2(24, 62), Vector2(18, 48), Vector2(18, 34), 3.6, 0.4, Color("#FF4A4E"), Color("#B8142C"), Color("#FF9EA8"), Color("#660916"), false, true)
		C.draw_hair_strand(fg, Vector2(70, 62), Vector2(76, 48), Vector2(75, 34), 3.6, 0.4, Color("#FF4A4E"), Color("#B8142C"), Color("#FF9EA8"), Color("#660916"), false, true)
		# Crânio calcinado detalhado 96x96 dentro do bojo da chama
		C.disc(fg, 47.5, 61.0, 14.5, 15.5, Color("#1C0B12"))
		C.disc(fg, 47.5, 58.0, 12.2, 12.0, Color("#C4AEB2"))
		C.disc(fg, 40.5, 57.5, 3.8, 4.2, Color("#0A0307")); C.px(fg, 40, 57, Color("#FF4A4E"))
		C.disc(fg, 54.5, 57.5, 3.8, 4.2, Color("#0A0307")); C.px(fg, 54, 57, Color("#FF4A4E"))
		C.line_px(fg, 47, 63, 46, 65, Color("#0A0307")); C.line_px(fg, 47, 63, 48, 65, Color("#0A0307"))
		C.span(fg, 40, 55, 70, Color("#0A0307"))
		for tx in [41, 44, 47, 50, 53]:
			C.rect(fg, tx, 68, tx + 1, 70, Color("#EFE2E4"))
		return C.composite(bg, fg)

	var bg := C.backdrop_solid(Color("#361E1D"))
	var fg := C.new_canvas()
	for y in range(8, 89):
		var ny := float(y - 8) / 80.0
		var sway := sin(ny * 5.2) * 4.0 * (1.0 - ny)
		var rx := 1.5 + sin(pow(ny, 1.62) * PI) * 26.5
		for x in range(int(round(47.5 + sway - rx)), int(round(47.5 + sway + rx)) + 1):
			var d := absf(float(x) - (47.5 + sway)) / maxf(rx, 1.0)
			C.px(fg, x, y, Color("#C93A16") if d > 0.72 else (Color("#F28E1C") if d > 0.44 else Color("#FFF4BA")))
	C.draw_hair_strand(fg, Vector2(26, 60), Vector2(20, 48), Vector2(20, 36), 3.4, 0.4, Color("#F28E1C"), Color("#C93A16"), Color("#FFF4BA"), Color("#751E0A"), false, true)
	C.draw_hair_strand(fg, Vector2(69, 62), Vector2(74, 50), Vector2(73, 38), 3.4, 0.4, Color("#F28E1C"), Color("#C93A16"), Color("#FFF4BA"), Color("#751E0A"), false, true)
	C.disc(fg, 39.0, 62.0, 2.8, 3.4, Color("#240A06")); C.px(fg, 38, 61, Color("#FFE875"))
	C.disc(fg, 55.0, 62.0, 2.8, 3.4, Color("#240A06")); C.px(fg, 54, 61, Color("#FFE875"))
	return C.composite(bg, fg)


static func build_vhs_radio(corrupted: bool) -> Image:
	if corrupted:
		var bg := C.backdrop_horror_dither(Color("#700A14"), Color("#060205"), "scan_crt")
		var fg := C.new_canvas()
		C.quad_bezier_line(fg, Vector2(27, 26), Vector2(25, 16), Vector2(20, 8), Color("#2B1A1F"), 3)
		C.disc(fg, 20.0, 7.0, 2.2, 2.2, Color("#FF3B4E"))
		C.rect(fg, 20, 26, 75, 93, Color("#1F1418"))
		C.rect(fg, 20, 26, 75, 31, Color("#38232A"))
		C.rect(fg, 26, 36, 69, 63, Color("#26060B"))
		for sy in range(38, 62, 3):
			C.span(fg, 27, 68, sy, Color("#400A12"))
		# Enorme olho humano anime horrorizado encarando através da tela rachada do rádio
		C.disc(fg, 47.5, 49.5, 13.5, 7.8, Color("#F2EAE4"))
		C.disc(fg, 47.5, 49.5, 5.8, 5.8, Color("#B01220"))
		C.disc(fg, 47.5, 49.5, 2.8, 2.8, Color("#0A0306"))
		C.px(fg, 44, 47, Color("#FFFFFF")); C.px(fg, 45, 47, Color("#FFFFFF")); C.px(fg, 44, 48, Color("#FFFFFF"))
		C.quad_bezier_line(fg, Vector2(33, 46), Vector2(47, 40), Vector2(62, 46), Color("#0A0306"), 2)
		C.quad_bezier_line(fg, Vector2(60, 36), Vector2(65, 44), Vector2(69, 50), Color("#090407"), 1)
		for gy in [71, 77, 83]:
			C.rect(fg, 28, gy, 67, gy + 1, Color("#0E0608"))
		C.quad_bezier_line(fg, Vector2(36, 68), Vector2(37, 79), Vector2(35, 90), Color("#800D18"), 2)
		return C.composite(bg, fg)

	var bg := C.backdrop_solid(Color("#394A43"))
	var fg := C.new_canvas()
	C.rect(fg, 26, 8, 28, 28, Color("#2E3842"))
	C.disc(fg, 27.0, 7.0, 2.0, 2.0, Color("#F5CB5C"))
	C.rect(fg, 20, 28, 75, 93, Color("#27303A"))
	C.rect(fg, 20, 28, 75, 33, Color("#3E4C59"))
	C.rect(fg, 26, 38, 69, 61, Color("#113026"))
	for x in range(28, 68):
		var wy := 50 + int(round(sin(float(x) * 0.42) * 6.0))
		C.px(fg, x, wy, Color("#5CE6B8")); C.px(fg, x, wy - 1, Color("#B8FFF0"))
	for gy in [71, 77, 83]:
		C.rect(fg, 28, gy, 67, gy + 1, Color("#14191F"))
	return C.composite(bg, fg)
