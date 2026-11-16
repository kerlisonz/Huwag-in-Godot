extends SceneTree

## Integra todos os portraits 96x96 aprovados na Etapa 1 em:
## - res://assets/characters/portraits/
## - res://assets/sprites/portraits/

const PREVIEW_DIR := "res://assets/sprites/portraits_v4_preview"
const CHAR_PORTRAITS_DIR := "res://assets/characters/portraits"
const SPRITE_PORTRAITS_DIR := "res://assets/sprites/portraits"


func _copy_png(src_rel: String, dst_dir: String, dst_name: String) -> bool:
	var src_abs := ProjectSettings.globalize_path("%s/%s" % [PREVIEW_DIR, src_rel])
	var dst_abs := ProjectSettings.globalize_path("%s/%s" % [dst_dir, dst_name])
	var img := Image.new()
	var err := img.load(src_abs)
	if err != OK:
		push_error("Falha ao carregar portrait aprovado: %s (err=%d)" % [src_abs, err])
		return false
	if img.save_png(dst_abs) != OK:
		push_error("Falha ao gravar portrait em: %s" % dst_abs)
		return false
	return true


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(CHAR_PORTRAITS_DIR))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SPRITE_PORTRAITS_DIR))

	var copied := 0

	# 1. Expressões + versão corrompida do Huwag (Casual & BFP)
	var huwag_exprs := [
		"neutral", "uneasy_smile", "worried", "tired",
		"surprised", "angry", "scared", "unfiltered", "distorted"
	]
	for outfit in ["casual", "bfp"]:
		for ex in huwag_exprs:
			var fname := "huwag_%s_%s.png" % [outfit, ex]
			if _copy_png(fname, CHAR_PORTRAITS_DIR, fname):
				copied += 1
		if _copy_png("huwag_%s_normal.png" % outfit, SPRITE_PORTRAITS_DIR, "huwag_%s_normal.png" % outfit):
			copied += 1
		if _copy_png("huwag_%s_corrupted.png" % outfit, SPRITE_PORTRAITS_DIR, "huwag_%s_distorted.png" % outfit):
			copied += 1

	# 2. Todo o elenco + Santelmo + Vulto + Guardiã + Rádio/VHS
	var char_map: Array[Dictionary] = [
		{
			"src": "cap_reyes",
			"char_norm": ["fnaf_cap_reyes.png"],
			"char_dist": ["fnaf_distorted_cap_reyes.png"],
			"sprite_slug": "cap_reyes",
		},
		{
			"src": "bombeiro_ato",
			"char_norm": ["fnaf_bombeiro_ato.png"],
			"char_dist": ["fnaf_distorted_bombeiro_ato.png"],
			"sprite_slug": "bombeiro_ato",
		},
		{
			"src": "bombeiro_santos",
			"char_norm": ["fnaf_bombeiro_santos.png"],
			"char_dist": ["fnaf_distorted_bombeiro_santos.png"],
			"sprite_slug": "bombeiro_santos",
		},
		{
			"src": "enfermeira_maria",
			"char_norm": ["fnaf_enfermeira_maria.png"],
			"char_dist": ["fnaf_distorted_enfermeira_maria.png"],
			"sprite_slug": "enfermeira_maria",
		},
		{
			"src": "luningning",
			"char_norm": ["fnaf_luningning.png"],
			"char_dist": ["fnaf_distorted_luningning.png", "distorted_fnaf_luningning.png"],
			"sprite_slug": "senhora_luningning",
		},
		{
			"src": "aling_nena",
			"char_norm": ["fnaf_aling_nena.png"],
			"char_dist": ["fnaf_distorted_aling_nena.png", "distorted_fnaf_aling_nena.png"],
			"sprite_slug": "aling_nena",
		},
		{
			"src": "kuya_ben",
			"char_norm": ["fnaf_kuya_ben.png"],
			"char_dist": ["fnaf_distorted_kuya_ben.png", "distorted_fnaf_kuya_ben.png"],
			"sprite_slug": "kuya_ben",
		},
		{
			"src": "feirante",
			"char_norm": ["fnaf_feirante.png"],
			"char_dist": ["fnaf_distorted_feirante.png", "distorted_fnaf_feirante.png"],
			"sprite_slug": "mang_tomas",
		},
		{
			"src": "mang_carding",
			"char_norm": ["fnaf_mang_carding.png"],
			"char_dist": ["fnaf_distorted_mang_carding.png", "distorted_fnaf_mang_carding.png"],
			"sprite_slug": "mang_carding",
		},
		{
			"src": "toby",
			"char_norm": ["fnaf_toby.png"],
			"char_dist": ["fnaf_distorted_toby.png", "distorted_fnaf_toby.png"],
			"sprite_slug": "toby",
		},
		{
			"src": "lola_rosa",
			"char_norm": ["fnaf_lola_rosa.png"],
			"char_dist": ["fnaf_distorted_lola_rosa.png", "distorted_fnaf_lola_rosa.png"],
			"sprite_slug": "lola_rosa",
		},
		{
			"src": "criatura_lagoa",
			"char_norm": ["fnaf_criatura_lagoa.png"],
			"char_dist": ["fnaf_distorted_criatura_lagoa.png"],
			"sprite_slug": "criatura_lagoa",
		},
		{
			"src": "vulto_bosque",
			"char_norm": ["fnaf_vulto_bosque.png"],
			"char_dist": ["fnaf_distorted_vulto_bosque.png", "fnaf_distorted_bombeiro.png"],
			"sprite_slug": "vulto_bosque",
		},
		{
			"src": "santelmo",
			"char_norm": ["fnaf_santelmo.png"],
			"char_dist": ["fnaf_distorted_santelmo.png"],
			"sprite_slug": "santelmo",
		},
		{
			"src": "vhs_radio",
			"char_norm": ["fnaf_vhs_radio.png"],
			"char_dist": ["fnaf_distorted_vhs_radio.png"],
			"sprite_slug": "vhs_radio",
		},
	]

	for entry in char_map:
		var s: String = entry["src"]
		for dst in entry["char_norm"]:
			if _copy_png("%s_normal.png" % s, CHAR_PORTRAITS_DIR, dst):
				copied += 1
		for dst in entry["char_dist"]:
			if _copy_png("%s_corrupted.png" % s, CHAR_PORTRAITS_DIR, dst):
				copied += 1
		var slug: String = entry["sprite_slug"]
		if _copy_png("%s_normal.png" % s, SPRITE_PORTRAITS_DIR, "%s_normal.png" % slug):
			copied += 1
		if _copy_png("%s_corrupted.png" % s, SPRITE_PORTRAITS_DIR, "%s_distorted.png" % slug):
			copied += 1

	print("[Etapa1] Deploy concluido: %d arquivos de retrato 96x96 atualizados." % copied)
	quit(0)
