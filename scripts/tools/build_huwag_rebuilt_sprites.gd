@tool
extends SceneTree

## Reconstrutor Pixel Art do Protagonista (Huwag) — Casual & Bombeiro (BFP)
## Baseado fielmente na Imagem 1 oficial (18x28 px lógicos dentro de célula 48x48 px,
## escala 1:1 nítida) e refinado com a qualidade de clusters e fluidez da Imagem 2.
##
## Gera spritesheets separados por finalidade para cada traje:
## - spritesheet_idle.png   (4 direções x 4 frames)
## - spritesheet_walk.png   (4 direções x 6 frames)
## - spritesheet_run.png    (4 direções x 6 frames)
## - spritesheet_attack.png (4 direções x 5 frames)
## - spritesheet_combo.png  (4 direções x 8 frames: combo2 [0..3] + combo3 [4..7])
## - spritesheet_dodge.png  (4 direções x 4 frames)
## - spritesheet_hurt.png   (4 direções x 3 frames)
## - spritesheet_death.png  (4 direções x 6 frames)
## Além de SpriteFrames (.tres), GIFs animados e pranchas de inspeção 1x e 8x.

const Gif89aEncoderScript := preload("res://scripts/tools/pixel_rig/gif89a_encoder.gd")

const CELL_W := 48
const CELL_H := 48
# Deslocamento que posiciona a grade 32x32 extraída da Imagem 1 dentro da célula 48x48
# (pés na linha y=29 da grade 32x32 passam para y=39 na célula 48x48, igual aos NPCs)
const OFF_X := 8
const OFF_Y := 10

const DIRS := ["down", "up", "left", "right"]

const ARTIFACT_DIR := "C:/Users/SnyX/.gemini/antigravity/brain/57f4ed94-3583-41fc-bbbe-9e9a2d546794/scratch"

# ==============================================================================
# MATRIZES BASE RECONSTRUÍDAS A PARTIR DA IMAGEM 1 (GRADE 32x32, CORPO 18x28)
# ==============================================================================

# Row 0: DOWN (Frente) — Simetria exata no eixo x=16.5 (x_esq + x_dir = 33) fiel à Imagem 1
const BASE_DOWN_IDLE: Array[String] = [
	"................................", # 00
	"................................", # 01
	"..............ccc...............", # 02
	"..........ccc.cbbcc..c..........", # 03
	"..........cbbccsbbbc.cc.........", # 04
	"..........chhhhshhbhchbc........", # 05
	"...........chhhhhhhhshhc........", # 06
	"........cccsshhhhhhhhhscc.......", # 07
	"........chhshhhhhhhhhhhhc.......", # 08
	".........crhhbhdbhdhhhhsc.......", # 09
	".........cssbbrlbhrrhhdsc.......", # 10
	"........ksrshrlhhrlprhdsk.......", # 11
	".........kkhcdsdrprsdrdk........", # 12
	".........krrdcksppdccdclk.......", # 13
	".........kddlwklpplkwlddk.......", # 14
	"...........klddpllpddlk.........", # 15
	"...........kkplpddpppkk.........", # 16
	"..........kktkdppppdktkk........", # 17
	"..........ktkjjkkkkjjktk........", # 18
	"..........kjjjzkggkzjjjk........", # 19
	".........kjjkjzkggkzjkjtk.......", # 20
	".........kkjkkzkggkzjkkjk.......", # 21
	".........kplkjzkggkzjkplk.......", # 22
	".........kddkkzkkkkkzkddk.......", # 23
	"..........kkkotvoottokkk........", # 24
	"............kvvtkkttvk..........", # 25
	"............koookkoook..........", # 26
	"...........kvtttkktttvk.........", # 27
	"...........kzztk..ktzzk.........", # 28
	"............kkk....kkk..........", # 29
	"................................", # 30
	"................................", # 31
]

# Passo A Frente (perna esquerda à frente, braço direito à frente) — eixo x=16.5 fiel à Cell [0,0]
const BASE_DOWN_STEP_A: Array[String] = [
	"................................", # 00
	"................................", # 01
	"..............ccc...............", # 02
	"..........ccc.cbbcc..c..........", # 03
	"..........cbbccsbbbc.cc.........", # 04
	"..........chhhhshhbhchbc........", # 05
	"...........chhhhhhhhshhc........", # 06
	"........cccsshhhhhhhhhscc.......", # 07
	"........chhshhhhhhhhhhhhc.......", # 08
	".........crhhbhdbhdhhhhsc.......", # 09
	".........cssbbrlbhrrhhdsc.......", # 10
	"........ksrshrlhhrlprhdsk.......", # 11
	".........kkhcdsdrprsdrdk........", # 12
	".........krrdcksppdccdclk.......", # 13
	".........kddlwklpplkwlddk.......", # 14
	"...........klddpllpddlk.........", # 15
	"...........kkplpddpppkk.........", # 16
	".........kkgkdpppppdktkk........", # 17
	"........kjjktjkkkkkjjkjk........", # 18
	".......kdjjjjzkgggkzjjjjk.......", # 19
	".......kplkkjzkgggkzjkkjk.......", # 20
	"........kk.kkzkgggkzjkplpk......", # 21
	"...........kkzkgggkzmkddpk......", # 22
	"............kzkkkkkzokkk........", # 23
	"............ktvtottook..........", # 24
	"............kttvkoook...........", # 25
	"............ktvokkvtk...........", # 26
	"............koook.kk............", # 27
	"............kzztk...............", # 28
	".............kkk................", # 29
	"................................", # 30
	"................................", # 31
]

# Passo B Frente (perna direita à frente, braço esquerdo à frente) — espelho de corpo no eixo x=16.5
const BASE_DOWN_STEP_B: Array[String] = [
	"................................", # 00
	"................................", # 01
	"..............ccc...............", # 02
	"..........ccc.cbbcc..c..........", # 03
	"..........cbbccsbbbc.cc.........", # 04
	"..........chhhhshhbhchbc........", # 05
	"...........chhhhhhhhshhc........", # 06
	"........cccsshhhhhhhhhscc.......", # 07
	"........chhshhhhhhhhhhhhc.......", # 08
	".........crhhbhdbhdhhhhsc.......", # 09
	".........cssbbrlbhrrhhdsc.......", # 10
	"........ksrshrlhhrlprhdsk.......", # 11
	".........kkhcdsdrprsdrdk........", # 12
	".........krrdcksppdccdclk.......", # 13
	".........kddlwklpplkwlddk.......", # 14
	"...........klddpllpddlk.........", # 15
	"...........kkplpddpppkk.........", # 16
	".........kktkdpppppdkgkk........", # 17
	".........kjkjjkkkkkjtkjjk.......", # 18
	"........kjjjjzkgggkzjjjjdk......", # 19
	"........kjkkjzkgggkzjkkplk......", # 20
	".......kplpkjzkgggkzkk.kk.......", # 21
	".......kpddkmzkgggkzkk..........", # 22
	".........kkkozkkkkzkk...........", # 23
	"...........koottotvtk...........", # 24
	"............koookvttk...........", # 25
	"............ktvkkoook...........", # 26
	".............kk.koook...........", # 27
	"................ktzzk...........", # 28
	".................kkk............", # 29
	"................................", # 30
	"................................", # 31
]

# Row 1: UP (Costas) — Coroa loira limpa com brilho 'b' e altura normalizada (28 px, y=2..29)
const BASE_UP_IDLE: Array[String] = [
	"................................", # 00
	"................................", # 01
	"..............ccc...............", # 02
	"..........ccc.cbhc...c..........", # 03
	"..........cbbdcsbbs.chc.........", # 04
	"..........chbbbsbbhsshc.........", # 05
	"........cccchbbbbhhhhhcc........", # 06
	"........cbbhhhbbbhhhhhhcc.......", # 07
	"........csbbhhhhhhhhhhhhc.......", # 08
	".........cshhhhhhhhhhhsc........", # 09
	"........chhhhhhhhhhhhhssrc......", # 10
	"........cssshhhhhhhhhsscc.......", # 11
	".........csshshhshhshssk........", # 12
	"........kpsssshssshsssspk.......", # 13
	"........klrsssssssssssrlk.......", # 14
	".........kkssssssssssskk........", # 15
	"...........ksssssssssk..........", # 16
	"...........ktttttttttk..........", # 17
	"..........kjjjmmmmmjjjk.........", # 18
	".........kjmkkjjjjjkkjmk........", # 19
	".........kmkkkkkkkkkkkmk........", # 20
	"........kjjkjjjjjjjjjkjjk.......", # 21
	"........kjjkjjmmmmmjjkjjk.......", # 22
	"........kpdkjjkkkkkjjkdpk.......", # 23
	".........kkkotvoooovtokkk.......", # 24
	"...........koookkkoook..........", # 25
	"...........koookkkoook..........", # 26
	"..........kvtttkkktttvk.........", # 27
	"..........kzzzk...kzzzk.........", # 28
	"...........kkk.....kkk..........", # 29
	"................................", # 30
	"................................", # 31
]

const BASE_UP_STEP_A: Array[String] = [
	"................................", # 00
	"................................", # 01
	"..............ccc...............", # 02
	"..........ccc.cbhc...c..........", # 03
	"..........cbbdcsbbs.chc.........", # 04
	"..........chbbbsbbhsshc.........", # 05
	"........cccchbbbbhhhhhcc........", # 06
	"........cbbhhhbbbhhhhhhcc.......", # 07
	"........csbbhhhhhhhhhhhhc.......", # 08
	".........cshhhhhhhhhhhsc........", # 09
	"........chhhhhhhhhhhhhssrc......", # 10
	"........cssshhhhhhhhhsscc.......", # 11
	".........csshshhshhshssk........", # 12
	"........kpsssshssshsssspk.......", # 13
	"........klrsssssssssssrlk.......", # 14
	".........kkssssssssssskk........", # 15
	"...........ksssssssssk..........", # 16
	"...........ktttttttttk..........", # 17
	"..........kjjjmmmmmjjjk.........", # 18
	".........kmkjjjjjjjjjkgk........", # 19
	"........kmmkkkmmjjkkkjmk........", # 20
	".......kplkjkjkkkkkjkmjmk.......", # 21
	".......kddkjjjjjjjjjjkjkk.......", # 22
	"........kkkjjjjjjjjjjkplk.......", # 23
	"...........kotttoooookddk.......", # 24
	"...........koookkkoookkk........", # 25
	"...........kttvkkkoook..........", # 26
	"...........kzzzk.kvttk..........", # 27
	"............kkk..kzzzk..........", # 28
	"..................kkk...........", # 29
	"................................", # 30
	"................................", # 31
]

const BASE_UP_STEP_B: Array[String] = [
	"................................", # 00
	"................................", # 01
	"..............ccc...............", # 02
	"..........ccc.cbhc...c..........", # 03
	"..........cbbdcsbbs.chc.........", # 04
	"..........chbbbsbbhsshc.........", # 05
	"........cccchbbbbhhhhhcc........", # 06
	"........cbbhhhbbbhhhhhhcc.......", # 07
	"........csbbhhhhhhhhhhhhc.......", # 08
	".........cshhhhhhhhhhhsc........", # 09
	"........chhhhhhhhhhhhhssrc......", # 10
	"........cssshhhhhhhhhsscc.......", # 11
	".........csshshhshhshssk........", # 12
	"........kpsssshssshsssspk.......", # 13
	"........klrsssssssssssrlk.......", # 14
	".........kkssssssssssskk........", # 15
	"...........ksssssssssk..........", # 16
	"...........ktttttttttk..........", # 17
	"..........kjjjmmmmmjjjk.........", # 18
	"........kgkjjjjjjjjjjkmk........", # 19
	"........kmjkkkjjmmkkkmmk........", # 20
	".......kmjmkjkkkkkjkjkplk.......", # 21
	".......kkjkjjjjjjjjjjkddk.......", # 22
	".......klpkjjjjjjjjjjkkk........", # 23
	".......kddkoooootttok...........", # 24
	"........kkkoookkkoook...........", # 25
	"..........koookkkvttk...........", # 26
	"..........kttvk.kzzzk...........", # 27
	"..........kzzzk..kkk............", # 28
	"...........kkk..................", # 29
	"................................", # 30
	"................................", # 31
]

# Row 2: LEFT (Perfil Esquerdo) — Cabeça idêntica à Imagem 1 [2,0]/[2,1], tronco encorpado (10-11 px)
const BASE_LEFT_IDLE: Array[String] = [
	"................................", # 00
	"................................", # 01
	"..............cc................", # 02
	".........cccc.chhc..............", # 03
	".........chhhscshhh.cc..........", # 04
	"..........chhhhshhhdchc.........", # 05
	"..........cshhhhhhhhhhc.c.......", # 06
	".........chhhhhhhhhhhhccc.......", # 07
	".......cchhhhhhhhhhhhhhhc.......", # 08
	"........cchlhhhhhhhhhhsc........", # 09
	".........chdcbhhhhhhhlsk........", # 10
	".........csslchchhshssssk.......", # 11
	".........cpdddrchhssssssk.......", # 12
	"..........klkddshclksssk........", # 13
	"..........klkwllhslkssk.........", # 14
	".........kllpdllldlksc..........", # 15
	"..........klllllldsssk..........", # 16
	"...........kddllskkkkk..........", # 17
	"............kkkktjjjjttk........", # 18
	"...........kztjjmjjjkjkk........", # 19
	"...........kzjjkjjjjkkk.........", # 20
	"...........kzjjkjjjjkk..........", # 21
	"...........kzjjkpllkjk..........", # 22
	"............kkkkddlkjk..........", # 23
	"............kkkkkkookkk.........", # 24
	".............koooovvtk..........", # 25
	".............koookvvvk..........", # 26
	"............kvtttkoook..........", # 27
	"...........kzzzzk.kzzk..........", # 28
	"............kkkk...kkk..........", # 29
	"................................", # 30
	"................................", # 31
]

# Passo A Perfil Esquerdo (perna da frente/esquerda avança, braço da frente avança) — de Cell [2,0]
const BASE_LEFT_STEP_A: Array[String] = [
	"................................", # 00
	"................................", # 01
	"..............cc................", # 02
	".........cccc.chhc..............", # 03
	".........chhhscshhh.cc..........", # 04
	"..........chhhhshhhdchc.........", # 05
	"..........cshhhhhhhhhhc.c.......", # 06
	".........chhhhhhhhhhhhccc.......", # 07
	".......cchhhhhhhhhhhhhhhc.......", # 08
	"........cchlhhhhhhhhhhsc........", # 09
	".........chdcbhhhhhhhlsk........", # 10
	".........csslchchhshssssk.......", # 11
	".........cpdddrchhssssssk.......", # 12
	"..........klkddshclksssk........", # 13
	"..........klkwllhslkssk.........", # 14
	".........kllpdllldlksc..........", # 15
	"..........klllllldsssk..........", # 16
	"...........kddllskkkkk..........", # 17
	"............kkkktjjjjttk........", # 18
	"............kztjjmjjkjkk........", # 19
	"...........kkzjjjjkkkk..........", # 20
	"..........kkkjjjjkjkkk..........", # 21
	".........kplkjjkkkjkkpk.........", # 22
	".........kddkkkkkkjkddk.........", # 23
	"..........kkkkkkkkvkkk..........", # 24
	"............koooottttk..........", # 25
	"...........koookkvttovk.........", # 26
	"..........koook..ktttozk........", # 27
	".........kzzzk....kkvzzk........", # 28
	"..........kkk.......kkk.........", # 29
	"................................", # 30
	"................................", # 31
]

# Passo B Perfil Esquerdo (perna oposta avança, braço da frente recua e braço de trás avança)
const BASE_LEFT_STEP_B: Array[String] = [
	"................................", # 00
	"................................", # 01
	"..............cc................", # 02
	".........cccc.chhc..............", # 03
	".........chhhscshhh.cc..........", # 04
	"..........chhhhshhhdchc.........", # 05
	"..........cshhhhhhhhhhc.c.......", # 06
	".........chhhhhhhhhhhhccc.......", # 07
	".......cchhhhhhhhhhhhhhhc.......", # 08
	"........cchlhhhhhhhhhhsc........", # 09
	".........chdcbhhhhhhhlsk........", # 10
	".........csslchchhshssssk.......", # 11
	".........cpdddrchhssssssk.......", # 12
	"..........klkddshclksssk........", # 13
	"..........klkwllhslkssk.........", # 14
	".........kllpdllldlksc..........", # 15
	"..........klllllldsssk..........", # 16
	"...........kddllskkkkk..........", # 17
	"............kkkktjjjjttk........", # 18
	"...........kkzjjmjjjjtk.........", # 19
	"..........kplkzjjjjjkkk.........", # 20
	"..........kddkzjjkjjjkk.........", # 21
	"...........kkkzjjkkjjkpk........", # 22
	".............kkkkkkjjkddk.......", # 23
	"............kkoooovkkkkk........", # 24
	"...........kttttooook...........", # 25
	"..........kvottvkkkoook.........", # 26
	".........kzotttk..koook.........", # 27
	".........kzzvkk....kzzzk........", # 28
	"..........kkk.......kkk.........", # 29
	"................................", # 30
	"................................", # 31
]


func _init() -> void:
	print("==================================================================")
	print("=== RECONSTRUINDO SPRITESHEETS PIXEL ART DO PROTAGONISTA HUWAG ===")
	print("==================================================================")

	for outfit_id in ["casual", "bombeiro"]:
		_generate_outfit_assets(outfit_id)

	_generate_comparison_and_inspection_boards()
	print("=== GERAÇÃO CONCLUÍDA COM SUCESSO! ===")
	quit(0)


func _get_palette(outfit_id: String) -> Dictionary:
	var pal := {
		".": Color(0, 0, 0, 0),
		"c": Color("#462814"), # Contorno marrom-escuro quente do cabelo
		"b": Color("#FAF0B8"), # Brilho loiro-claro solar nas pontas superiores
		"h": Color("#EAD482"), # Loiro-palha principal (fiel à Imagem 1)
		"s": Color("#BD934A"), # Sombra ocre-dourada do cabelo e nuca
		"r": Color("#7A4B26"), # Vincos internos do cabelo, sobrancelhas e boca
		"p": Color("#DE9E72"), # Luz da pele morena (testa/nariz/mãos)
		"l": Color("#CA8B60"), # Pele morena base (fiel à Imagem 1)
		"d": Color("#925E42"), # Sombra da pele / olheiras marcadas sob os olhos
		"w": Color("#F0F0F6"), # Esclera branca nítida (1 px)
		"k": Color("#14151C"), # Contorno escuro da roupa e pupila
		# Cores de efeitos de combate (slash / energia)
		"A": Color("#FFFDF2"), # Borda brilhante do corte
		"B": Color("#A8D8FF"), # Corpo ciano-prateado do arco de ataque
		"C": Color("#4E7EC2"), # Rastro azul-aço do golpe
		"D": Color("#FFE066"), # Brilho dourado de impacto (Combo 3)
		"E": Color("#E67E22"), # Rastro âmbar intenso (Combo 3)
	}
	if outfit_id == "casual":
		pal["j"] = Color("#232733") # Jaqueta preta-carvão
		pal["m"] = Color("#353B4C") # Dobras/volume médio da jaqueta
		pal["t"] = Color("#525B70") # Luz nos ombros/capuz e cinza médio do tênis
		pal["z"] = Color("#9298A6") # Zíper cinza-claro e bico do tênis
		pal["g"] = Color("#1B1E28") # Camiseta interna escura
		pal["o"] = Color("#6E7E52") # Calça verde-oliva principal
		pal["v"] = Color("#505E3C") # Sombra da calça verde-oliva
	else:
		# Uniforme Bombeiro (BFP) com mesma silhueta e anatomia exata
		pal["j"] = Color("#1C202B") # Casaco de aproximação BFP preto-azulado
		pal["m"] = Color("#2D3344") # Volume do casaco BFP
		pal["t"] = Color("#E67E22") # Faixa refletiva laranja-âmbar nos ombros/punhos
		pal["z"] = Color("#F7DC6F") # Faixa refletiva amarelo-ouro de alta visibilidade
		pal["g"] = Color("#252936") # Gola/peito interno escuro
		pal["o"] = Color("#343946") # Calça de bombeiro chumbo-escuro
		pal["v"] = Color("#D4AC0D") # Faixa refletiva nos joelhos/barra e botas
	return pal


func _generate_outfit_assets(outfit_id: String) -> void:
	var pal := _get_palette(outfit_id)
	var v3_dir := "res://assets/sprites/huwag_v3/%s" % outfit_id
	var v3_gifs_dir := "%s/gifs" % v3_dir
	var v2_dir := "res://assets/sprites/huwag_v2/%s" % outfit_id
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(v3_dir))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(v3_gifs_dir))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(v2_dir))

	# 1. Constrói os 8 spritesheets separados por finalidade
	var idle_sheet := _build_idle_sheet(pal)
	var walk_sheet := _build_walk_sheet(pal)
	var run_sheet := _build_run_sheet(pal)
	var attack_sheet := _build_attack_sheet(pal)
	var combo_sheet := _build_combo_sheet(pal)
	var dodge_sheet := _build_dodge_sheet(pal)
	var hurt_sheet := _build_hurt_sheet(pal)
	var death_sheet := _build_death_sheet(pal)

	var sheets_info := {
		"idle": {"img": idle_sheet, "cols": 4, "fps": 5.0, "loop": true},
		"walk": {"img": walk_sheet, "cols": 6, "fps": 9.5, "loop": true},
		"run": {"img": run_sheet, "cols": 6, "fps": 12.5, "loop": true},
		"attack": {"img": attack_sheet, "cols": 5, "fps": 15.0, "loop": false},
		"combo": {"img": combo_sheet, "cols": 8, "fps": 16.0, "loop": false},
		"dodge": {"img": dodge_sheet, "cols": 4, "fps": 14.0, "loop": false},
		"hurt": {"img": hurt_sheet, "cols": 3, "fps": 10.0, "loop": false},
		"death": {"img": death_sheet, "cols": 6, "fps": 8.0, "loop": false},
	}

	var saved_textures := {}
	for purpose in sheets_info.keys():
		var img: Image = sheets_info[purpose]["img"]
		var png_path := "%s/spritesheet_%s.png" % [v3_dir, purpose]
		img.save_png(ProjectSettings.globalize_path(png_path))
		var loaded_tex := load(png_path) as Texture2D
		saved_textures[purpose] = loaded_tex if loaded_tex != null else ImageTexture.create_from_image(img)
		print("  [%s] Salvo %s (%dx%d)" % [outfit_id, png_path, img.get_width(), img.get_height()])

	# Também salva compatibilidade de nomes em v3 e v2
	walk_sheet.save_png(ProjectSettings.globalize_path("%s/huwag_%s_walk.png" % [v3_dir, outfit_id]))
	walk_sheet.save_png(ProjectSettings.globalize_path("%s/huwag_%s_walk.png" % [v2_dir, outfit_id]))

	# Constrói também a folha 10x4 legada (480x192) em res://assets/characters/sprites/
	var legacy_sheet := _build_legacy_10x4_sheet(idle_sheet, walk_sheet, attack_sheet)
	var legacy_name := "huwag_casual_sheet.png" if outfit_id == "casual" else "huwag_bfp_sheet.png"
	var legacy_path := "res://assets/characters/sprites/%s" % legacy_name
	legacy_sheet.save_png(ProjectSettings.globalize_path(legacy_path))

	# 2. Monta o SpriteFrames completo com todas as animações e direções
	var sf := _build_sprite_frames(saved_textures, sheets_info)
	var tres_v3 := "%s/huwag_%s_spriteframes.tres" % [v3_dir, outfit_id]
	var tres_v2 := "%s/huwag_%s_spriteframes.tres" % [v2_dir, outfit_id]
	ResourceSaver.save(sf, tres_v3)
	ResourceSaver.save(sf, tres_v2)
	print("  [%s] SpriteFrames salvos em %s e %s" % [outfit_id, tres_v3, tres_v2])

	# 3. Exporta GIFs de prévia para inspeção visual
	_export_gif_previews(v3_gifs_dir, outfit_id, idle_sheet, walk_sheet, run_sheet, attack_sheet, combo_sheet, dodge_sheet)


# ==============================================================================
# CONSTRUTORES DOS 8 SPRITESHEETS SEPARADOS POR FINALIDADE
# ==============================================================================

func _build_idle_sheet(pal: Dictionary) -> Image:
	# 4 direções (down, up, left, right) x 4 frames:
	# Frame 0: postura base
	# Frame 1: inspiração sutil (ombros/capuz sobem 1px)
	# Frame 2: respiração relaxada (cabeça/tronco descem 1px mantendo pés fixos em y=39)
	# Frame 3: postura base com piscada natural (olhos semifechados)
	var cols := 4
	var sheet := Image.create(CELL_W * cols, CELL_H * 4, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0, 0, 0, 0))

	for dir_idx in range(4):
		var dir_name: String = DIRS[dir_idx]
		for col in range(cols):
			var cell := _render_base_grid(_get_idle_grid(dir_name), dir_name == "right", pal)
			if col == 1:
				cell = _apply_breathing_shift(cell, -1, false)
			elif col == 2:
				cell = _apply_breathing_shift(cell, 1, false)
			elif col == 3:
				cell = _apply_blink(cell, dir_name, pal)
			sheet.blit_rect(cell, Rect2i(0, 0, CELL_W, CELL_H), Vector2i(col * CELL_W, dir_idx * CELL_H))
	return sheet


func _build_walk_sheet(pal: Dictionary) -> Image:
	# 4 direções x 6 frames fluidos:
	# Col 0: Passo A (contato)
	# Col 1: Passo A (impulso)
	# Col 2: Passagem A (corpo sobe 1px - bounce estilo Imagem 2)
	# Col 3: Passo B (contato oposto)
	# Col 4: Passo B (impulso oposto)
	# Col 5: Passagem B (corpo sobe 1px - bounce estilo Imagem 2)
	var cols := 6
	var sheet := Image.create(CELL_W * cols, CELL_H * 4, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0, 0, 0, 0))

	for dir_idx in range(4):
		var dir_name: String = DIRS[dir_idx]
		var flip_h := (dir_name == "right")
		var idle_c := _render_base_grid(_get_idle_grid(dir_name), flip_h, pal)
		var step_a := _render_base_grid(_get_step_a_grid(dir_name), flip_h, pal)
		var step_b := _render_base_grid(_get_step_b_grid(dir_name), flip_h, pal)

		var frames: Array[Image] = [
			step_a,
			_shift_upper_body(step_a, 0, 1),
			_shift_whole_character(idle_c, 0, -1),
			step_b,
			_shift_upper_body(step_b, 0, 1),
			_shift_whole_character(idle_c, 0, -1),
		]
		for col in range(cols):
			sheet.blit_rect(frames[col], Rect2i(0, 0, CELL_W, CELL_H), Vector2i(col * CELL_W, dir_idx * CELL_H))
	return sheet


func _build_run_sheet(pal: Dictionary) -> Image:
	# 4 direções x 6 frames de corrida dinâmica:
	# Inclinação para frente na direção do movimento, passada ampliada e balanço do cabelo
	var cols := 6
	var sheet := Image.create(CELL_W * cols, CELL_H * 4, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0, 0, 0, 0))

	for dir_idx in range(4):
		var dir_name: String = DIRS[dir_idx]
		var flip_h := (dir_name == "right")
		var idle_c := _render_base_grid(_get_idle_grid(dir_name), flip_h, pal)
		var step_a := _render_base_grid(_get_step_a_grid(dir_name), flip_h, pal)
		var step_b := _render_base_grid(_get_step_b_grid(dir_name), flip_h, pal)

		var lean_dx := -1 if dir_name == "left" else (1 if dir_name == "right" else 0)
		var lean_dy := 1 if dir_name == "down" else (-1 if dir_name == "up" else 0)

		var f0 := _apply_run_posture(step_a, dir_name, lean_dx, lean_dy, -1, pal)
		var f1 := _apply_run_posture(step_a, dir_name, lean_dx * 2, lean_dy, 0, pal)
		var f2 := _shift_whole_character(idle_c, lean_dx, -2)
		var f3 := _apply_run_posture(step_b, dir_name, lean_dx, lean_dy, -1, pal)
		var f4 := _apply_run_posture(step_b, dir_name, lean_dx * 2, lean_dy, 0, pal)
		var f5 := _shift_whole_character(idle_c, lean_dx, -2)

		var frames: Array[Image] = [f0, f1, f2, f3, f4, f5]
		for col in range(cols):
			sheet.blit_rect(frames[col], Rect2i(0, 0, CELL_W, CELL_H), Vector2i(col * CELL_W, dir_idx * CELL_H))
	return sheet


func _build_attack_sheet(pal: Dictionary) -> Image:
	# 4 direções x 5 frames:
	# 0: Antecipação (recuo de ombro + arma preparada)
	# 1: Golpe principal (avanço + arco de corte amplo brilhante)
	# 2: Impacto / Follow-through (extensão máxima + rastro do arco)
	# 3: Recuperação 1 (recolhendo arma)
	# 4: Recuperação 2 (retorno à guarda)
	var cols := 5
	var sheet := Image.create(CELL_W * cols, CELL_H * 4, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0, 0, 0, 0))

	for dir_idx in range(4):
		var dir_name: String = DIRS[dir_idx]
		var flip_h := (dir_name == "right")
		var idle_c := _render_base_grid(_get_idle_grid(dir_name), flip_h, pal)
		var step_a := _render_base_grid(_get_step_a_grid(dir_name), flip_h, pal)

		var l_dx := -1 if dir_name == "left" else (1 if dir_name == "right" else 0)
		var l_dy := 1 if dir_name == "down" else (-1 if dir_name == "up" else 0)

		for col in range(cols):
			var frame: Image
			match col:
				0:
					frame = _shift_upper_body(idle_c, -l_dx, -l_dy)
					_draw_slash_fx(frame, dir_name, 0, 1, pal)
				1:
					frame = _shift_whole_character(step_a, l_dx * 2, l_dy)
					_draw_slash_fx(frame, dir_name, 1, 1, pal)
				2:
					frame = _shift_whole_character(step_a, l_dx * 2, l_dy)
					_draw_slash_fx(frame, dir_name, 2, 1, pal)
				3:
					frame = _shift_upper_body(step_a, l_dx, 0)
					_draw_slash_fx(frame, dir_name, 3, 1, pal)
				_:
					frame = idle_c.duplicate() as Image
			sheet.blit_rect(frame, Rect2i(0, 0, CELL_W, CELL_H), Vector2i(col * CELL_W, dir_idx * CELL_H))
	return sheet


func _build_combo_sheet(pal: Dictionary) -> Image:
	# 4 direções x 8 frames:
	# Cols 0..3: Combo Etapa 2 (corte reverso cruzado veloz)
	# Cols 4..7: Combo Etapa 3 (finalizador pesado dourado com salto e impacto)
	var cols := 8
	var sheet := Image.create(CELL_W * cols, CELL_H * 4, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0, 0, 0, 0))

	for dir_idx in range(4):
		var dir_name: String = DIRS[dir_idx]
		var flip_h := (dir_name == "right")
		var idle_c := _render_base_grid(_get_idle_grid(dir_name), flip_h, pal)
		var step_a := _render_base_grid(_get_step_a_grid(dir_name), flip_h, pal)
		var step_b := _render_base_grid(_get_step_b_grid(dir_name), flip_h, pal)

		var l_dx := -1 if dir_name == "left" else (1 if dir_name == "right" else 0)
		var l_dy := 1 if dir_name == "down" else (-1 if dir_name == "up" else 0)

		# Combo 2 (cols 0..3): corte reverso usando passo oposto
		for c2 in range(4):
			var f2: Image
			match c2:
				0:
					f2 = _shift_upper_body(step_b, -l_dx, 0)
					_draw_slash_fx(f2, dir_name, 0, 2, pal)
				1:
					f2 = _shift_whole_character(step_b, l_dx * 2, l_dy)
					_draw_slash_fx(f2, dir_name, 1, 2, pal)
				2:
					f2 = _shift_whole_character(step_b, l_dx * 3, l_dy)
					_draw_slash_fx(f2, dir_name, 2, 2, pal)
				_:
					f2 = _shift_upper_body(idle_c, l_dx, 0)
			sheet.blit_rect(f2, Rect2i(0, 0, CELL_W, CELL_H), Vector2i(c2 * CELL_W, dir_idx * CELL_H))

		# Combo 3 (cols 4..7): finalizador pesado dourado
		for c3 in range(4):
			var f3: Image
			match c3:
				0:
					f3 = _shift_whole_character(idle_c, -l_dx, -2)
					_draw_slash_fx(f3, dir_name, 0, 3, pal)
				1:
					f3 = _shift_whole_character(step_a, l_dx * 3, l_dy * 2)
					_draw_slash_fx(f3, dir_name, 1, 3, pal)
				2:
					f3 = _shift_whole_character(step_a, l_dx * 3, l_dy * 2 + 1)
					_draw_slash_fx(f3, dir_name, 2, 3, pal)
				_:
					f3 = _shift_upper_body(idle_c, l_dx, 1)
			sheet.blit_rect(f3, Rect2i(0, 0, CELL_W, CELL_H), Vector2i((4 + c3) * CELL_W, dir_idx * CELL_H))
	return sheet


func _build_dodge_sheet(pal: Dictionary) -> Image:
	# 4 direções x 4 frames de esquiva ágil (dash com postura baixa e linhas de velocidade)
	var cols := 4
	var sheet := Image.create(CELL_W * cols, CELL_H * 4, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0, 0, 0, 0))

	for dir_idx in range(4):
		var dir_name: String = DIRS[dir_idx]
		var flip_h := (dir_name == "right")
		var idle_c := _render_base_grid(_get_idle_grid(dir_name), flip_h, pal)
		var step_a := _render_base_grid(_get_step_a_grid(dir_name), flip_h, pal)

		var d_dx := -1 if dir_name == "left" else (1 if dir_name == "right" else 0)
		var d_dy := 1 if dir_name == "down" else (-1 if dir_name == "up" else 0)

		for col in range(cols):
			var frame: Image
			match col:
				0:
					# Impulso inicial agachado
					frame = _shift_upper_body(idle_c, d_dx, 2)
				1:
					# Dash em alta velocidade com rastro fantasma
					frame = _shift_whole_character(step_a, d_dx * 3, d_dy * 2 + 1)
					_draw_dodge_speedlines(frame, dir_name, pal)
				2:
					# Deslize de desaceleração
					frame = _shift_whole_character(step_a, d_dx * 2, d_dy + 1)
					_draw_dodge_speedlines(frame, dir_name, pal)
				_:
					# Pouso firme
					frame = _shift_upper_body(idle_c, 0, 1)
			sheet.blit_rect(frame, Rect2i(0, 0, CELL_W, CELL_H), Vector2i(col * CELL_W, dir_idx * CELL_H))
	return sheet


func _build_hurt_sheet(pal: Dictionary) -> Image:
	# 4 direções x 3 frames de recebimento de dano (recuo + expressão de dor)
	var cols := 3
	var sheet := Image.create(CELL_W * cols, CELL_H * 4, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0, 0, 0, 0))

	for dir_idx in range(4):
		var dir_name: String = DIRS[dir_idx]
		var flip_h := (dir_name == "right")
		var idle_c := _render_base_grid(_get_idle_grid(dir_name), flip_h, pal)
		var wince_c := _apply_blink(idle_c, dir_name, pal)

		var r_dx := 1 if dir_name == "left" else (-1 if dir_name == "right" else 0)
		var r_dy := -1 if dir_name == "down" else (1 if dir_name == "up" else 0)

		var f0 := _shift_whole_character(wince_c, r_dx * 2, r_dy)
		var f1 := _shift_upper_body(_shift_whole_character(wince_c, r_dx * 3, r_dy), r_dx, 1)
		var f2 := _shift_upper_body(wince_c, r_dx, 1)

		var frames: Array[Image] = [f0, f1, f2]
		for col in range(cols):
			sheet.blit_rect(frames[col], Rect2i(0, 0, CELL_W, CELL_H), Vector2i(col * CELL_W, dir_idx * CELL_H))
	return sheet


func _build_death_sheet(pal: Dictionary) -> Image:
	# 4 direções x 6 frames:
	# 0: Impacto forte
	# 1: Cambaleio
	# 2: Queda de joelhos
	# 3: Inclinando para o chão
	# 4: Queda horizontal no chão
	# 5: Imóvel derrotado no chão
	var cols := 6
	var sheet := Image.create(CELL_W * cols, CELL_H * 4, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0, 0, 0, 0))

	for dir_idx in range(4):
		var dir_name: String = DIRS[dir_idx]
		var flip_h := (dir_name == "right")
		var idle_c := _render_base_grid(_get_idle_grid(dir_name), flip_h, pal)
		var wince_c := _apply_blink(idle_c, dir_name, pal)

		for col in range(cols):
			var frame: Image
			match col:
				0:
					frame = _shift_upper_body(wince_c, -1, 1)
				1:
					frame = _apply_kneel_collapse(wince_c, 2)
				2:
					frame = _apply_kneel_collapse(wince_c, 4)
				3:
					frame = _apply_kneel_collapse(wince_c, 7)
				4:
					frame = _build_fallen_ground_pose(pal, flip_h, 0)
				_:
					frame = _build_fallen_ground_pose(pal, flip_h, 1)
			sheet.blit_rect(frame, Rect2i(0, 0, CELL_W, CELL_H), Vector2i(col * CELL_W, dir_idx * CELL_H))
	return sheet


func _build_legacy_10x4_sheet(idle_sheet: Image, walk_sheet: Image, attack_sheet: Image) -> Image:
	# Mantém compatibilidade com a folha 480x192 (10x4, ordem: down, left, right, up)
	var sheet := Image.create(CELL_W * 10, CELL_H * 4, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0, 0, 0, 0))
	var legacy_to_v3_row := [0, 2, 3, 1] # down=0, left=2, right=3, up=1
	for l_row in range(4):
		var src_row: int = legacy_to_v3_row[l_row]
		# Cols 0..1: Idle
		for c in range(2):
			sheet.blit_rect(idle_sheet, Rect2i(c * CELL_W, src_row * CELL_H, CELL_W, CELL_H), Vector2i(c * CELL_W, l_row * CELL_H))
		# Cols 2..5: Walk (frames 0, 2, 3, 5)
		var walk_cols := [0, 2, 3, 5]
		for i in range(4):
			var wc: int = walk_cols[i]
			sheet.blit_rect(walk_sheet, Rect2i(wc * CELL_W, src_row * CELL_H, CELL_W, CELL_H), Vector2i((2 + i) * CELL_W, l_row * CELL_H))
		# Cols 6..9: Attack (frames 0, 1, 2, 3)
		for a in range(4):
			sheet.blit_rect(attack_sheet, Rect2i(a * CELL_W, src_row * CELL_H, CELL_W, CELL_H), Vector2i((6 + a) * CELL_W, l_row * CELL_H))
	return sheet


# ==============================================================================
# MONTAGEM DO RESOURCE SPRITEFRAMES (.TRES)
# ==============================================================================

func _build_sprite_frames(textures: Dictionary, sheets_info: Dictionary) -> SpriteFrames:
	var sf := SpriteFrames.new()
	if sf.has_animation("default"):
		sf.remove_animation("default")

	for purpose in ["idle", "walk", "run", "attack", "dodge", "hurt", "death"]:
		var tex: Texture2D = textures[purpose]
		var cols: int = int(sheets_info[purpose]["cols"])
		var fps: float = float(sheets_info[purpose]["fps"])
		var loop: bool = bool(sheets_info[purpose]["loop"])

		for dir_idx in range(4):
			var dir_name: String = DIRS[dir_idx]
			var anim_name := "%s_%s" % [purpose, dir_name]
			_add_strip_to_sf(sf, anim_name, tex, dir_idx, 0, cols, fps, loop)
		# Atalho sem sufixo apontando para "down"
		_add_strip_to_sf(sf, purpose, tex, 0, 0, cols, fps, loop)

	# Animações de Combo (combo2_*, combo3_* e combo_* completo)
	var combo_tex: Texture2D = textures["combo"]
	var combo_fps: float = float(sheets_info["combo"]["fps"])
	for dir_idx in range(4):
		var dir_name: String = DIRS[dir_idx]
		_add_strip_to_sf(sf, "combo2_%s" % dir_name, combo_tex, dir_idx, 0, 4, combo_fps, false)
		_add_strip_to_sf(sf, "combo3_%s" % dir_name, combo_tex, dir_idx, 4, 4, combo_fps, false)
		_add_strip_to_sf(sf, "combo_%s" % dir_name, combo_tex, dir_idx, 0, 8, combo_fps, false)
		# Alias jump_* para compatibilidade com chamadas existentes
		_add_strip_to_sf(sf, "jump_%s" % dir_name, textures["dodge"], dir_idx, 0, 4, 12.0, false)
	_add_strip_to_sf(sf, "combo2", combo_tex, 0, 0, 4, combo_fps, false)
	_add_strip_to_sf(sf, "combo3", combo_tex, 0, 4, 4, combo_fps, false)
	_add_strip_to_sf(sf, "combo", combo_tex, 0, 0, 8, combo_fps, false)
	_add_strip_to_sf(sf, "jump", textures["dodge"], 0, 0, 4, 12.0, false)

	return sf


func _add_strip_to_sf(sf: SpriteFrames, anim_name: String, tex: Texture2D, row: int, col_start: int, count: int, fps: float, loop: bool) -> void:
	if sf.has_animation(anim_name):
		sf.remove_animation(anim_name)
	sf.add_animation(anim_name)
	sf.set_animation_speed(anim_name, fps)
	sf.set_animation_loop(anim_name, loop)
	for i in range(count):
		var atlas := AtlasTexture.new()
		atlas.atlas = tex
		atlas.region = Rect2(float((col_start + i) * CELL_W), float(row * CELL_H), float(CELL_W), float(CELL_H))
		sf.add_frame(anim_name, atlas)


# ==============================================================================
# HELPERS DE RENDERIZAÇÃO E TRANSFORMAÇÃO PIXEL ART (100% NEAREST / INTEIRO)
# ==============================================================================

func _get_idle_grid(dir_name: String) -> Array[String]:
	match dir_name:
		"up":
			return BASE_UP_IDLE
		"left", "right":
			return BASE_LEFT_IDLE
		_:
			return BASE_DOWN_IDLE


func _get_step_a_grid(dir_name: String) -> Array[String]:
	match dir_name:
		"up":
			return BASE_UP_STEP_A
		"left", "right":
			return BASE_LEFT_STEP_A
		_:
			return BASE_DOWN_STEP_A


func _get_step_b_grid(dir_name: String) -> Array[String]:
	match dir_name:
		"up":
			return BASE_UP_STEP_B
		"left", "right":
			return BASE_LEFT_STEP_B
		_:
			return BASE_DOWN_STEP_B


func _render_base_grid(grid: Array[String], flip_h: bool, pal: Dictionary) -> Image:
	var img := Image.create(CELL_W, CELL_H, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in range(grid.size()):
		var row_str: String = grid[y]
		for x in range(row_str.length()):
			var ch: String = row_str.substr(x, 1)
			if ch == "." or not pal.has(ch):
				continue
			var draw_x := (31 - x) if flip_h else x
			img.set_pixel(OFF_X + draw_x, OFF_Y + y, pal[ch])
	return img


func _apply_breathing_shift(src: Image, dy: int, include_head: bool) -> Image:
	# Desloca apenas o tronco (ou cabeça+tronco) mantendo as pernas ancoradas no chão e preenchendo a junta de 1px sem fenda transparente!
	var dst := Image.create(CELL_W, CELL_H, false, Image.FORMAT_RGBA8)
	dst.fill(Color(0, 0, 0, 0))
	var split_top := OFF_Y + (0 if include_head else 17)
	var split_bottom := OFF_Y + 24

	for y in range(CELL_H):
		for x in range(CELL_W):
			if y < split_top or y >= split_bottom:
				dst.set_pixel(x, y, src.get_pixel(x, y))
	# Preenche a linha exposta pelo deslocamento antes de blitar o tronco deslocado (evita linha vazia de 1px no torso)
	if dy > 0:
		for extra_y in range(split_top, mini(CELL_H, split_top + dy)):
			for x in range(CELL_W):
				var seam_c := src.get_pixel(x, extra_y)
				if seam_c.a > 0.0:
					dst.set_pixel(x, extra_y, seam_c)
	elif dy < 0:
		for extra_y in range(maxi(0, split_bottom + dy), split_bottom):
			for x in range(CELL_W):
				var seam_c := src.get_pixel(x, extra_y)
				if seam_c.a > 0.0:
					dst.set_pixel(x, extra_y, seam_c)
	for y in range(split_top, split_bottom):
		var ty := clampi(y + dy, 0, CELL_H - 1)
		for x in range(CELL_W):
			var c := src.get_pixel(x, y)
			if c.a > 0.0:
				dst.set_pixel(x, ty, c)
	return dst


func _apply_blink(src: Image, dir_name: String, pal: Dictionary) -> Image:
	var dst: Image = src.duplicate() as Image
	if dir_name == "up":
		return dst
	# Substitui os pixels da esclera/pupila na linha dos olhos (y = OFF_Y + 14) por pálpebra fechada
	var eye_y := OFF_Y + 14
	for x in range(CELL_W):
		var c := dst.get_pixel(x, eye_y)
		if c.is_equal_approx(pal["w"]) or (x >= OFF_X + 11 and x <= OFF_X + 20 and c.is_equal_approx(pal["k"])):
			dst.set_pixel(x, eye_y, pal["r"])
	return dst


func _shift_whole_character(src: Image, dx: int, dy: int) -> Image:
	var dst := Image.create(CELL_W, CELL_H, false, Image.FORMAT_RGBA8)
	dst.fill(Color(0, 0, 0, 0))
	for y in range(CELL_H):
		for x in range(CELL_W):
			var c := src.get_pixel(x, y)
			if c.a > 0.0:
				var nx := clampi(x + dx, 0, CELL_W - 1)
				var ny := clampi(y + dy, 0, CELL_H - 1)
				dst.set_pixel(nx, ny, c)
	return dst


func _shift_upper_body(src: Image, dx: int, dy: int) -> Image:
	# Desloca cabeça + tronco (y < OFF_Y + 24) mantendo as pernas fixas no chão e preenchendo junta
	var dst := Image.create(CELL_W, CELL_H, false, Image.FORMAT_RGBA8)
	dst.fill(Color(0, 0, 0, 0))
	var hip_line := OFF_Y + 24
	for y in range(hip_line, CELL_H):
		for x in range(CELL_W):
			dst.set_pixel(x, y, src.get_pixel(x, y))
	if dy < 0:
		for extra_y in range(maxi(0, hip_line + dy), hip_line):
			for x in range(CELL_W):
				var seam_c := src.get_pixel(x, extra_y)
				if seam_c.a > 0.0:
					dst.set_pixel(clampi(x + dx, 0, CELL_W - 1), extra_y, seam_c)
	for y in range(0, hip_line):
		for x in range(CELL_W):
			var c := src.get_pixel(x, y)
			if c.a > 0.0:
				var nx := clampi(x + dx, 0, CELL_W - 1)
				var ny := clampi(y + dy, 0, CELL_H - 1)
				dst.set_pixel(nx, ny, c)
	return dst


func _apply_run_posture(src: Image, dir_name: String, lean_dx: int, lean_dy: int, bounce_y: int, _pal: Dictionary) -> Image:
	# Na corrida, a cabeça e o tronco inclinam na direção do movimento e os pés sobem 1px no impulso
	var dst := Image.create(CELL_W, CELL_H, false, Image.FORMAT_RGBA8)
	dst.fill(Color(0, 0, 0, 0))
	var hip_line := OFF_Y + 24
	# Pernas com leve impulso vertical
	for y in range(hip_line, CELL_H):
		for x in range(CELL_W):
			var c := src.get_pixel(x, y)
			if c.a > 0.0:
				dst.set_pixel(x, clampi(y + bounce_y, 0, CELL_H - 1), c)
	# Tronco e cabeça inclinados na direção da corrida
	for y in range(0, hip_line):
		for x in range(CELL_W):
			var c := src.get_pixel(x, y)
			if c.a > 0.0:
				var extra_head := lean_dx if y < OFF_Y + 17 else 0
				var nx := clampi(x + lean_dx + (1 if extra_head > 0 else (-1 if extra_head < 0 else 0)), 0, CELL_W - 1)
				var ny := clampi(y + lean_dy + bounce_y, 0, CELL_H - 1)
				dst.set_pixel(nx, ny, c)
	return dst


func _draw_axe_pixel_segment(img: Image, p0: Vector2, p1: Vector2, thickness: int, col: Color, outline: Color = Color.TRANSPARENT) -> void:
	var steps := maxi(1, int(ceil(p0.distance_to(p1) * 2.0)))
	for i in range(steps + 1):
		var t := float(i) / float(steps)
		var pt := p0.lerp(p1, t)
		var px := int(round(pt.x))
		var py := int(round(pt.y))
		if outline.a > 0.05:
			for oy in range(-1, 2):
				for ox in range(-1, 2):
					if img.get_pixel(clampi(px + ox, 0, CELL_W - 1), clampi(py + oy, 0, CELL_H - 1)).a <= 0.05:
						_set_px_safe(img, px + ox, py + oy, outline)
		_set_px_safe(img, px, py, col)
		if thickness >= 2:
			_set_px_safe(img, px + 1, py, col)


func _draw_fire_axe_head(img: Image, head_pos: Vector2, blade_dir: Vector2, outline: Color, combo_stage: int) -> void:
	var axe_red := Color("#C92A2A")
	var axe_red_hi := Color("#F03E3E")
	var steel_edge := Color("#F2F6FC") if combo_stage >= 3 else Color("#E2E8F2")
	var steel_mid := Color("#98A4B8")
	var norm := blade_dir.normalized()
	var perp := Vector2(-norm.y, norm.x)

	# Ponteira traseira do machado de bombeiro (pick spike)
	var pick_tip := head_pos - norm * 3.5
	_draw_axe_pixel_segment(img, head_pos - norm * 1.0, pick_tip, 1, steel_mid, outline)

	# Corpo forjado vermelho do machado
	for f in range(1, 4):
		for w in range(-2, 3):
			var bp := head_pos + norm * float(f) + perp * float(w) * 0.7
			var bx := int(round(bp.x))
			var by := int(round(bp.y))
			for oy in range(-1, 2):
				for ox in range(-1, 2):
					var nx := clampi(bx + ox, 0, CELL_W - 1)
					var ny := clampi(by + oy, 0, CELL_H - 1)
					if img.get_pixel(nx, ny).a <= 0.05:
						img.set_pixel(nx, ny, outline)
			img.set_pixel(bx, by, axe_red_hi if w <= 0 else axe_red)

	# Lâmina de corte prateada brilhante
	for w in range(-3, 4):
		var ep := head_pos + norm * 4.5 + perp * float(w) * 0.85
		_set_px_safe(img, int(round(ep.x)), int(round(ep.y)), steel_edge)


func _draw_fire_axe_in_hand(img: Image, hand_pos: Vector2, axe_dir: Vector2, blade_dir: Vector2, combo_stage: int, pal: Dictionary, behind_body: bool = false) -> void:
	var target: Image = img
	if behind_body:
		target = Image.create(CELL_W, CELL_H, false, Image.FORMAT_RGBA8)
		target.fill(Color(0, 0, 0, 0))
	var wood_dk := Color("#6E4427")
	var wood_lt := Color("#9E683E")
	var outline: Color = pal["k"]
	var dir_n := axe_dir.normalized()
	var shaft_len := 10.5 if combo_stage < 3 else 12.0
	var tip_pos := hand_pos + dir_n * shaft_len
	_draw_axe_pixel_segment(target, hand_pos - dir_n * 2.0, tip_pos, 1, wood_dk, outline)
	_draw_axe_pixel_segment(target, hand_pos, tip_pos - dir_n * 1.5, 1, wood_lt, Color.TRANSPARENT)
	_draw_fire_axe_head(target, tip_pos, blade_dir, outline, combo_stage)
	if behind_body:
		for y in range(CELL_H):
			for x in range(CELL_W):
				var wc := target.get_pixel(x, y)
				if wc.a > 0.05 and img.get_pixel(x, y).a <= 0.05:
					img.set_pixel(x, y, wc)


func _draw_slash_fx(img: Image, dir_name: String, phase: int, combo_stage: int, pal: Dictionary) -> void:
	# Desenha braço + mão + machado de bombeiro 16-bit + arco luminoso de impacto exclusivamente nos ataques/combos
	var col_edge: Color = pal["A"]
	var col_mid: Color = pal["D"] if combo_stage == 3 else pal["B"]
	var col_trail: Color = pal["E"] if combo_stage == 3 else pal["C"]
	var col_sleeve: Color = pal["j"]
	var col_hand: Color = pal["l"]
	var col_outline: Color = pal["k"]

	if phase == 0:
		# Recuo (windup) segurando o machado atrás do ombro/costas sem cobrir o rosto
		var hand := Vector2(30, 28)
		var axe_dir := Vector2(0.85, -0.60)
		var blade_dir := Vector2(-0.4, 0.9)
		var behind := false
		match dir_name:
			"down":
				hand = Vector2(30, 28)
				axe_dir = Vector2(0.85, -0.55)
				blade_dir = Vector2(0.55, 0.85)
			"up":
				hand = Vector2(30, 24)
				axe_dir = Vector2(0.75, -0.8)
				blade_dir = Vector2(-0.7, -0.6)
				behind = true
			"left":
				hand = Vector2(27, 29)
				axe_dir = Vector2(0.88, -0.55)
				blade_dir = Vector2(0.55, -0.85)
				behind = true
			"right":
				hand = Vector2(20, 29)
				axe_dir = Vector2(-0.88, -0.55)
				blade_dir = Vector2(-0.55, -0.85)
				behind = true
		_set_px_safe(img, int(hand.x), int(hand.y), col_hand)
		_draw_fire_axe_in_hand(img, hand, axe_dir, blade_dir, combo_stage, pal, behind)
		return

	if phase == 3:
		# Recuperação final com o machado baixado antes de guardar
		var hand_r := Vector2(28, 32)
		var dir_r := Vector2(0.55, 0.85)
		var blade_r := Vector2(-0.85, 0.5)
		var behind_r := (dir_name == "up")
		match dir_name:
			"up":
				hand_r = Vector2(18, 26)
				dir_r = Vector2(-0.75, -0.55)
				blade_r = Vector2(0.5, -0.85)
			"left":
				hand_r = Vector2(16, 31)
				dir_r = Vector2(-0.8, 0.65)
				blade_r = Vector2(-0.5, 0.85)
			"right":
				hand_r = Vector2(31, 31)
				dir_r = Vector2(0.8, 0.65)
				blade_r = Vector2(0.5, 0.85)
		_set_px_safe(img, int(hand_r.x), int(hand_r.y), col_hand)
		_draw_fire_axe_in_hand(img, hand_r, dir_r, blade_r, combo_stage, pal, behind_r)
		return

	# Fases 1 (golpe ativo) e 2 (follow-through com arco de corte + machado em extensão)
	var reach := (2 if combo_stage >= 2 else 0) + (1 if phase == 2 else 0)
	var rev := -1 if combo_stage == 2 else 1
	match dir_name:
		"down":
			var arm_x := 21 if combo_stage == 2 else 26
			for ay in range(30, 34):
				_set_px_safe(img, arm_x, ay, col_sleeve if ay < 32 else col_hand)
				_set_px_safe(img, arm_x + 1, ay, col_outline)
			var base_y := 40 + reach
			var hand_d := Vector2(arm_x, 33)
			var adir_d := Vector2(-0.32 * rev if phase == 1 else -0.65 * rev, 0.92).normalized()
			_draw_fire_axe_in_hand(img, hand_d, adir_d, Vector2(float(rev), 0.25), combo_stage, pal, false)
			for dx in range(-10, 11):
				var curve := int(absf(float(dx)) * 0.35)
				var py := base_y - curve
				var px := 24 + dx * rev
				if phase == 1 or dx >= -4:
					_set_px_safe(img, px, py, col_edge)
					_set_px_safe(img, px, py - 1, col_mid)
					if abs(dx) < 7:
						_set_px_safe(img, px, py - 2, col_trail)
		"up":
			var arm_x := 20 if combo_stage == 2 else 28
			for ay in range(19, 24):
				_set_px_safe(img, arm_x, ay, col_hand if ay < 21 else col_sleeve)
			var base_y := 9 - reach
			var hand_u := Vector2(arm_x, 19)
			var adir_u := Vector2(-0.35 * rev if phase == 1 else -0.65 * rev, -0.92).normalized()
			_draw_fire_axe_in_hand(img, hand_u, adir_u, Vector2(float(rev), -0.25), combo_stage, pal, true)
			for dx in range(-10, 11):
				var curve := int(absf(float(dx)) * 0.35)
				var py := base_y + curve
				var px := 24 + dx * rev
				if phase == 1 or dx <= 4:
					_set_px_safe(img, px, py, col_edge)
					_set_px_safe(img, px, py + 1, col_mid)
					if abs(dx) < 7:
						_set_px_safe(img, px, py + 2, col_trail)
		"left":
			for ax in range(15, 20):
				_set_px_safe(img, ax, 29, col_hand if ax < 17 else col_sleeve)
				_set_px_safe(img, ax, 30, col_outline)
			var base_x := 9 - reach
			var hand_l := Vector2(15, 29)
			var adir_l := Vector2(-0.92, 0.35 * rev if phase == 1 else 0.65 * rev).normalized()
			_draw_fire_axe_in_hand(img, hand_l, adir_l, Vector2(-0.25, float(rev)), combo_stage, pal)
			for dy in range(-9, 10):
				var curve := int(absf(float(dy)) * 0.38)
				var px := base_x + curve
				var py := 28 + dy * rev
				if phase == 1 or dy <= 4:
					_set_px_safe(img, px, py, col_edge)
					_set_px_safe(img, px + 1, py, col_mid)
					if abs(dy) < 6:
						_set_px_safe(img, px + 2, py, col_trail)
		"right":
			for ax in range(28, 33):
				_set_px_safe(img, ax, 29, col_hand if ax > 30 else col_sleeve)
				_set_px_safe(img, ax, 30, col_outline)
			var base_x := 38 + reach
			var hand_rt := Vector2(32, 29)
			var adir_rt := Vector2(0.92, 0.35 * rev if phase == 1 else 0.65 * rev).normalized()
			_draw_fire_axe_in_hand(img, hand_rt, adir_rt, Vector2(0.25, float(rev)), combo_stage, pal)
			for dy in range(-9, 10):
				var curve := int(absf(float(dy)) * 0.38)
				var px := base_x - curve
				var py := 28 + dy * rev
				if phase == 1 or dy >= -4:
					_set_px_safe(img, px, py, col_edge)
					_set_px_safe(img, px - 1, py, col_mid)
					if abs(dy) < 6:
						_set_px_safe(img, px - 2, py, col_trail)


func _draw_dodge_speedlines(img: Image, dir_name: String, pal: Dictionary) -> void:
	var c1: Color = pal["B"]
	var c2: Color = pal["C"]
	c1.a = 0.85
	c2.a = 0.65
	match dir_name:
		"left":
			for i in range(4):
				_set_px_safe(img, 33 + i, 22, c1 if i < 2 else c2)
				_set_px_safe(img, 34 + i, 29, c1 if i < 2 else c2)
				_set_px_safe(img, 32 + i, 35, c2)
		"right":
			for i in range(4):
				_set_px_safe(img, 14 - i, 22, c1 if i < 2 else c2)
				_set_px_safe(img, 13 - i, 29, c1 if i < 2 else c2)
				_set_px_safe(img, 15 - i, 35, c2)
		"down":
			for i in range(4):
				_set_px_safe(img, 17, 11 + i, c2)
				_set_px_safe(img, 30, 11 + i, c2)
		"up":
			for i in range(4):
				_set_px_safe(img, 17, 38 - i, c2)
				_set_px_safe(img, 30, 38 - i, c2)


func _apply_kneel_collapse(src: Image, drop_px: int) -> Image:
	var dst := Image.create(CELL_W, CELL_H, false, Image.FORMAT_RGBA8)
	dst.fill(Color(0, 0, 0, 0))
	var foot_line := OFF_Y + 29
	for y in range(CELL_H):
		for x in range(CELL_W):
			var c := src.get_pixel(x, y)
			if c.a <= 0.0:
				continue
			var ny: int = mini(foot_line, y + drop_px)
			dst.set_pixel(x, ny, c)
	return dst


func _build_fallen_ground_pose(pal: Dictionary, flip_h: bool, settle: int) -> Image:
	# Pose caída horizontal no chão (mantendo cabelo loiro espetado, jaqueta preta e calça verde)
	var fallen_grid: Array[String] = [
		"................................", # 00..20 vazios
		"................................",
		"................................",
		"................................",
		"................................",
		"................................",
		"................................",
		"................................",
		"................................",
		"................................",
		"................................",
		"................................",
		"................................",
		"................................",
		"................................",
		"................................",
		"................................",
		"................................",
		"................................",
		"................................",
		"......ccc..cc...................", # 20
		"....ccbbhchhhcc.................", # 21
		"...chhhhhhhhhhsc.kkkkkk.........", # 22
		"..cchhhshhhhhhskkjjjjjjkkkk.....", # 23
		"...kshhllldllskjjmmjjjjooook....", # 24
		"....kklldddllkkjjjjjjkoooovtk...", # 25
		".....kkkkplpkkkkzzzzkkoooozzk...", # 26
		"........kkkk...kkkkkkkkkkkkkk...", # 27
		"................................", # 28
		"................................", # 29
		"................................", # 30
		"................................", # 31
	]
	var img := _render_base_grid(fallen_grid, flip_h, pal)
	return _shift_whole_character(img, 0, 2 + settle)


func _set_px_safe(img: Image, x: int, y: int, col: Color) -> void:
	if x >= 0 and x < img.get_width() and y >= 0 and y < img.get_height():
		img.set_pixel(x, y, col)


func _write_pixel_art_import_file(res_path: String) -> void:
	var abs_import := ProjectSettings.globalize_path(res_path) + ".import"
	var content := """[remap]

importer="texture"
type="CompressedTexture2D"

[deps]

source_file="%s"

[params]

compress/mode=0
compress/high_quality=false
compress/lossy_quality=0.7
compress/hdr_compression=1
compress/normal_map=0
compress/channel_pack=0
mipmaps/generate=false
mipmaps/limit=-1
roughness/mode=0
roughness/src_normal=""
process/fix_alpha_border=false
process/premult_alpha=false
process/normal_map_invert_y=false
process/hdr_as_srgb=false
process/hdr_clamp_exposure=false
process/size_limit=0
detect_3d/compress_to=1
""" % res_path
	var f := FileAccess.open(abs_import, FileAccess.WRITE)
	if f:
		f.store_string(content)
		f.close()


func _export_gif_previews(gifs_dir: String, outfit_id: String, idle_s: Image, walk_s: Image, run_s: Image, atk_s: Image, combo_s: Image, dodge_s: Image) -> void:
	var tasks := [
		{"name": "idle_down", "sheet": idle_s, "row": 0, "cols": 4, "delay": 20},
		{"name": "walk_down", "sheet": walk_s, "row": 0, "cols": 6, "delay": 10},
		{"name": "walk_up", "sheet": walk_s, "row": 1, "cols": 6, "delay": 10},
		{"name": "walk_left", "sheet": walk_s, "row": 2, "cols": 6, "delay": 10},
		{"name": "walk_right", "sheet": walk_s, "row": 3, "cols": 6, "delay": 10},
		{"name": "run_down", "sheet": run_s, "row": 0, "cols": 6, "delay": 8},
		{"name": "attack_down", "sheet": atk_s, "row": 0, "cols": 5, "delay": 7},
		{"name": "combo_down", "sheet": combo_s, "row": 0, "cols": 8, "delay": 7},
		{"name": "dodge_left", "sheet": dodge_s, "row": 2, "cols": 4, "delay": 7},
	]

	for t in tasks:
		var frames: Array[Image] = []
		var delays: Array[int] = []
		var s_img: Image = t["sheet"]
		var row: int = int(t["row"])
		var cols: int = int(t["cols"])
		var d_cs: int = int(t["delay"])
		for c in range(cols):
			var frame_1x := Image.create(CELL_W, CELL_H, false, Image.FORMAT_RGBA8)
			frame_1x.fill(Color(0, 0, 0, 0))
			frame_1x.blit_rect(s_img, Rect2i(c * CELL_W, row * CELL_H, CELL_W, CELL_H), Vector2i.ZERO)
			frames.append(frame_1x)
			delays.append(d_cs)
		var out_gif := ProjectSettings.globalize_path("%s/huwag_%s_%s.gif" % [gifs_dir, outfit_id, t["name"]])
		Gif89aEncoderScript.save_animated_gif(out_gif, frames, delays, 3)
		if t["name"] in ["walk_down", "attack_down", "combo_down"]:
			Gif89aEncoderScript.save_animated_gif("%s/huwag_%s_%s.gif" % [ARTIFACT_DIR, outfit_id, t["name"]], frames, delays, 4)


func _generate_comparison_and_inspection_boards() -> void:
	# Gera pranchas comparativas em 1x e 8x sobre o piso marrom do jogo para inspeção visual imediata
	var pal_casual := _get_palette("casual")
	var pal_bfp := _get_palette("bombeiro")
	var walk_casual := _build_walk_sheet(pal_casual)
	var atk_casual := _build_attack_sheet(pal_casual)
	var combo_casual := _build_combo_sheet(pal_casual)
	var dodge_casual := _build_dodge_sheet(pal_casual)
	var walk_bfp := _build_walk_sheet(pal_bfp)

	# Prancha 3x3 equivalente à Imagem 1 (Step A, Idle, Step B nas linhas Down, Up, Left/Right)
	var board_1x := Image.create(CELL_W * 6, CELL_H * 4, false, Image.FORMAT_RGBA8)
	var floor_col := Color("#2C1E16")
	var plank_col := Color("#231710")
	board_1x.fill(floor_col)
	for y in range(board_1x.get_height()):
		if y % 16 == 0:
			for x in range(board_1x.get_width()):
				board_1x.set_pixel(x, y, plank_col)

	# Cols 0..2: Casual (Step A, Idle, Step B) para Down, Up, Left, Right
	for r in range(4):
		board_1x.blend_rect(walk_casual, Rect2i(0 * CELL_W, r * CELL_H, CELL_W, CELL_H), Vector2i(0 * CELL_W, r * CELL_H))
		board_1x.blend_rect(walk_casual, Rect2i(2 * CELL_W, r * CELL_H, CELL_W, CELL_H), Vector2i(1 * CELL_W, r * CELL_H))
		board_1x.blend_rect(walk_casual, Rect2i(3 * CELL_W, r * CELL_H, CELL_W, CELL_H), Vector2i(2 * CELL_W, r * CELL_H))
		# Col 3: Attack | Col 4: Combo 3 Finisher | Col 5: Bombeiro Idle/Walk
		board_1x.blend_rect(atk_casual, Rect2i(1 * CELL_W, r * CELL_H, CELL_W, CELL_H), Vector2i(3 * CELL_W, r * CELL_H))
		board_1x.blend_rect(combo_casual, Rect2i(5 * CELL_W, r * CELL_H, CELL_W, CELL_H), Vector2i(4 * CELL_W, r * CELL_H))
		board_1x.blend_rect(walk_bfp, Rect2i(0 * CELL_W, r * CELL_H, CELL_W, CELL_H), Vector2i(5 * CELL_W, r * CELL_H))

	board_1x.save_png(ARTIFACT_DIR + "/huwag_rebuilt_sheet_1x_floor.png")
	var board_6x := _upscale_nearest(board_1x, 6)
	board_6x.save_png(ARTIFACT_DIR + "/huwag_rebuilt_sheet_6x_floor.png")
	print("[Board] Salvo huwag_rebuilt_sheet_6x_floor.png em Artifacts.")


func _upscale_nearest(src: Image, factor: int) -> Image:
	var w := src.get_width()
	var h := src.get_height()
	var dst := Image.create(w * factor, h * factor, false, Image.FORMAT_RGBA8)
	for y in range(h):
		for x in range(w):
			var c := src.get_pixel(x, y)
			for dy in range(factor):
				for dx in range(factor):
					dst.set_pixel(x * factor + dx, y * factor + dy, c)
	return dst
