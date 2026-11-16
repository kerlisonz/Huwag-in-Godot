@tool
class_name NpcHumanoidTemplates
extends RefCounted
## Organic 32x32 pixel-art anatomy templates derived directly from Huwag's approved
## proportions (x_center = 16.5 in Down/Up: x_left + x_right = 33; foot sole at y = 29 -> cell y = 39).
## Every crown, face, uniform, hat, hairstyle, and fallen silhouette is sculpted pixel-by-pixel.

# Clean Down Mannequin (width 12->16->12 around center 16.5: left_dots = right_dots + 2)
const BASE_DOWN_IDLE: Array[String] = [
	"................................", # 00
	"................................", # 01
	"................................", # 02
	"................................", # 03
	"................................", # 04
	"............SSSSSSSSSS..........", # 05 (12..21) rounded bald crown top
	"..........SSppppppppppSS........", # 06 (10..23)
	".........SppllllllllllppS.......", # 07 (9..24)
	".........SllllllllllllllS.......", # 08 (9..24)
	".........SllllllllllllllS.......", # 09 (9..24)
	".........SllllllllllllllS.......", # 10 (9..24)
	"........SdlllllllllllllldS......", # 11 (8..25) ears & temple rim
	".........SdlrrllllllrldS........", # 12 (9..24) wait 9+15+8=32 -> make 16 chars (9..24)!
	".........SdlqlllppllqpldS.......", # 13 (9..24 -> 9+16+7=32!)
	".........SdlwEklpplkEwldS.......", # 14 (9..24) crisp 1x2 eyes (w+E) + cheeks (d)
	"...........SlddpllpddlS.........", # 15 (11..22 -> 11+12+9=32!) tapered rounded chin
	"...........kkplpddpppkk.........", # 16 (11..22) neck & collar (exact Huwag!)
	"..........kkTkpplppdkTkk........", # 17 (10..23) sloping shoulders
	"..........kTkjjkkkkjjkTk........", # 18 (10..23) A-frame arms separate outward
	"..........kjjjZkggkZjjjk........", # 19 (10..23)
	".........kjjkjZkggkZjkjTk.......", # 20 (9..24) forearm curve & chest
	".........kkjkkZkggkZjkkjk.......", # 21 (9..24)
	".........kplkjZkggkZjkplk.......", # 22 (9..24) relaxed curved hands
	".........kddkkZkkkkkZkddk.......", # 23 (9..24) fingertips & hem
	"..........kkkotvoottokkk........", # 24 (10..23) pelvis & trousers
	"............kvvtkkttvk..........", # 25 (12..21)
	"............koookkoook..........", # 26 (12..21)
	"...........kvtttkktttvk.........", # 27 (11..22)
	"...........kzzTk..kTzzk.........", # 28 (11..22) boots
	"............kkk....kkk..........", # 29 (12..21) boot soles at y=29 -> y=39
	"................................", # 30
	"................................", # 31
]

# Double-checked Down Row 12-15 exact length & symmetry around x_center = 16.5 (9+24=33)
const _DOWN_HEAD_LINES_FIXED: Array[String] = [
	"................................", # 00
	"................................", # 01
	"................................", # 02
	"................................", # 03
	"................................", # 04
	"............SSSSSSSSSS..........", # 05 12+10+10 = 32
	"..........SSppppppppppSS........", # 06 10+14+8 = 32
	".........SppllllllllllppS.......", # 07 9+16+7 = 32
	".........SllllllllllllllS.......", # 08 9+16+7 = 32
	".........SllllllllllllllS.......", # 09 9+16+7 = 32
	".........SllllllllllllllS.......", # 10 9+16+7 = 32
	"........SdlllllllllllllldS......", # 11 8+18+6 = 32 (outer ear rim)
	".........SdllllpppplllldS.......", # 12 9+16+7 = 32 (smooth forehead bridge)
	".........SdllrrllllrrlldS.......", # 13 9+16+7 = 32 (symmetric brows 13..14 and 19..20)
	".........SdllwElpplEwlldS.......", # 14 9+16+7 = 32 (crisp 2x1 SNES eyes matching Huwag!)
	"...........SlqqprrpqqlS.........", # 15 11+12+9 = 32 (under-eye + centered 2px mouth 16..17)
]

const BASE_DOWN_STEP_A: Array[String] = [
	"................................", # 00..15 replaced cleanly by shared head builder
	"................................",
	"................................",
	"................................",
	"................................",
	"............SSSSSSSSSS..........",
	"..........SSppppppppppSS........",
	".........SppllllllllllppS.......",
	".........SllllllllllllllS.......",
	".........SllllllllllllllS.......",
	".........SllllllllllllllS.......",
	"........SdlllllllllllllldS......",
	".........SdlrrllllllrrldS.......",
	".........SdlqlllppllqpldS.......",
	".........SdlwEklpplkEwldS.......",
	"...........SlddpllpddlS.........",
	"...........kkplpddpppkk.........", # 16
	".........kkgkdpppppdktkk........", # 17 exact Huwag Step A body!
	"........kjjkTjkkkkkjjkjk........", # 18
	".......kdjjjjZkgggkZjjjjk.......", # 19
	".......kplkkjZkgggkZjkkjk.......", # 20
	"........kk.kkZkgggkZjkplpk......", # 21
	"...........kkZkgggkZmkddpk......", # 22
	"............kZkkkkkZokkk........", # 23
	"............kTvtottook..........", # 24
	"............kttvkoook...........", # 25
	"............kTvokkvtk...........", # 26
	"............koook.kk............", # 27
	"............kzzTk...............", # 28
	".............kkk................", # 29
	"................................", # 30
	"................................", # 31
]

const BASE_DOWN_STEP_B: Array[String] = [
	"................................",
	"................................",
	"................................",
	"................................",
	"................................",
	"............SSSSSSSSSS..........",
	"..........SSppppppppppSS........",
	".........SppllllllllllppS.......",
	".........SllllllllllllllS.......",
	".........SllllllllllllllS.......",
	".........SllllllllllllllS.......",
	"........SdlllllllllllllldS......",
	".........SdlrrllllllrrldS.......",
	".........SdlqlllppllqpldS.......",
	".........SdlwEklpplkEwldS.......",
	"...........SlddpllpddlS.........",
	"...........kkplpddpppkk.........", # 16
	".........kktkdpppppdktkk........", # 17 exact Huwag Step B body!
	".........kjkjjkkkkkjTkjjk.......", # 18
	"........kjjjjZkgggkZjjjjdk......", # 19
	"........kjkkjZkgggkZjkkplk......", # 20
	".......kplpkjZkgggkZkk.kk.......", # 21
	".......kpddkmZkgggkZkk..........", # 22
	".........kkkoZkkkkZkk...........", # 23
	"...........koottotvTk...........", # 24
	"............koookvttk...........", # 25
	"............ktvkkoook...........", # 26
	".............kk.koook...........", # 27
	"................kTzzk...........", # 28
	".................kkk............", # 29
	"................................", # 30
	"................................", # 31
]

const BASE_UP_IDLE: Array[String] = [
	"................................", # 00
	"................................", # 01
	"................................", # 02
	"................................", # 03
	"................................", # 04
	"............cccccccccc..........", # 05 12+10+10 = 32
	"..........cchhhhhhhhhhcc........", # 06 10+14+8 = 32
	".........chhbbbbbbbbbbhhc.......", # 07 9+16+7 = 32
	".........chhhhhhhhhhhhhhc.......", # 08
	".........chhhhhhhhhhhhhhc.......", # 09
	".........chhhhhhhhhhhhhhc.......", # 10
	"........SdhhhhhhhhhhhhhhdS......", # 11 ears visible at back sides
	".........chhsssssssssshhc.......", # 12
	".........SpsssshssshssspS.......", # 13 9+16+7 = 32
	".........Slrssssssssssrls.......", # 14 lower nape / ears
	"..........SSssssssssssSS........", # 15 10+14+8 = 32
	"............SssssssssS..........", # 16
	"...........ktttttttttk..........", # 17 exact Huwag Up body!
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
	"................................",
	"................................",
	"................................",
	"................................",
	"................................",
	"............cccccccccc..........",
	"..........cchhhhhhhhhhcc........",
	".........chhbbbbbbbbbbhhc.......",
	".........chhhhhhhhhhhhhhc.......",
	".........chhhhhhhhhhhhhhc.......",
	".........chhhhhhhhhhhhhhc.......",
	"........SdhhhhhhhhhhhhhhdS......",
	".........chhsssssssssshhc.......",
	".........SpsssshssshssspS.......",
	".........Slrssssssssssrls.......",
	"..........SSssssssssssSS........",
	"............SssssssssS..........",
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
	"................................",
	"................................",
	"................................",
	"................................",
	"................................",
	"............cccccccccc..........",
	"..........cchhhhhhhhhhcc........",
	".........chhbbbbbbbbbbhhc.......",
	".........chhhhhhhhhhhhhhc.......",
	".........chhhhhhhhhhhhhhc.......",
	".........chhhhhhhhhhhhhhc.......",
	"........SdhhhhhhhhhhhhhhdS......",
	".........chhsssssssssshhc.......",
	".........SpsssshssshssspS.......",
	".........Slrssssssssssrls.......",
	"..........SSssssssssssSS........",
	"............SssssssssS..........",
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

const BASE_LEFT_IDLE: Array[String] = [
	"................................", # 00
	"................................", # 01
	"................................", # 02
	"................................", # 03
	"................................", # 04
	"...........SSSSSSSSSS...........", # 05 rounded cranium top (left profile)
	"..........SpppppllllSS..........", # 06
	".........SplllllllllllS.........", # 07
	".........SllllllllllllS.........", # 08
	".........SlllllllllllldS........", # 09
	".........SlllllllllllldS........", # 10
	".........SlllllllllddddS........", # 11 forehead
	".........SpdddlllllldddS........", # 12 brow curve & ear top
	"..........SlrllpllldlddS........", # 13 side brow
	"..........SlEwllpslkdddS........", # 14 side eye (E pupil + w sclera facing left!) + nose + ear
	".........SllppllldlkddS.........", # 15 nose tip (x=9!) & upper lip
	"..........SllllllddddS..........", # 16 rounded chin & jawline
	"...........SddllSSSSSS..........", # 17 slim curved neck
	"............kkkkTjjjjTTk........", # 18 exact Huwag Left torso & curved shoulder!
	"...........kZtjjmjjjkjkk........", # 19 front chest + bent back sleeve
	"...........kZjjkjjjjkkk.........", # 20
	"...........kZjjkjjjjkk..........", # 21
	"...........kZjjkpllkjk..........", # 22 hand curving down beside thigh
	"............kkkkddlkjk..........", # 23
	"............kkkkkkookkk.........", # 24 pelvis & leg outline
	".............koooovvtk..........", # 25
	".............koookvvvk..........", # 26
	"............kvtttkoook..........", # 27
	"...........kzzzzk.kzzk..........", # 28 front & back boot cleanly separated
	"............kkkk...kkk..........", # 29 sole on y=29 -> cell y=39
	"................................", # 30
	"................................", # 31
]

const BASE_LEFT_STEP_A: Array[String] = [
	"................................",
	"................................",
	"................................",
	"................................",
	"................................",
	"...........SSSSSSSSSS...........",
	"..........SpppppllllSS..........",
	".........SplllllllllllS.........",
	".........SllllllllllllS.........",
	".........SlllllllllllldS........",
	".........SlllllllllllldS........",
	".........SlllllllllddddS........",
	".........SpdddlllllldddS........",
	"..........SlrllpllldlddS........",
	"..........SlEwllpslkdddS........",
	".........SllppllldlkddS.........",
	"..........SllllllddddS..........",
	"...........SddllSSSSSS..........",
	"............kkkkTjjjjTTk........", # 18
	"............kZtjjmjjkjkk........", # 19
	"...........kkZjjjjkkkk..........", # 20
	"..........kkkjjjjkjkkk..........", # 21
	".........kplkjjkkkjkkpk.........", # 22 Huwag wide Left stride arms
	".........kddkkkkkkjkddk.........", # 23
	"..........kkkkkkkkvkkk..........", # 24
	"............koooottttk..........", # 25 wide scissors stride!
	"...........koookkvttovk.........", # 26
	"..........koook..ktttozk........", # 27
	".........kzzzk....kkvzzk........", # 28
	"..........kkk.......kkk.........", # 29
	"................................", # 30
	"................................", # 31
]

const BASE_LEFT_STEP_B: Array[String] = [
	"................................",
	"................................",
	"................................",
	"................................",
	"................................",
	"...........SSSSSSSSSS...........",
	"..........SpppppllllSS..........",
	".........SplllllllllllS.........",
	".........SllllllllllllS.........",
	".........SlllllllllllldS........",
	".........SlllllllllllldS........",
	".........SlllllllllddddS........",
	".........SpdddlllllldddS........",
	"..........SlrllpllldlddS........",
	"..........SlEwllpslkdddS........",
	".........SllppllldlkddS.........",
	"..........SllllllddddS..........",
	"...........SddllSSSSSS..........",
	"............kkkkTjjjjTTk........", # 18
	"...........kkZjjmjjjjTk.........", # 19
	"..........kplkZjjjjjkkk.........", # 20
	"..........kddkZjjkjjjkk.........", # 21
	"...........kkkZjjkkjjkpk........", # 22 opposite wide arm swing
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

const BASE_FALLEN: Array[String] = [
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
	"................................",
	"................................", # 20
	".......SSSSSS...................", # 21
	".....SSppppppSS.................", # 22
	"....SllllllllppSkkkkkk..........", # 23
	"...SSllllllllldkjjjjjjkkkk......", # 24
	"....Slllddllldkjjmmjjjjooook....", # 25
	".....SSllpllpSSjjjjjjkoooovtk...", # 26
	".......SSSSSSkkZZZZkkoooozzk....", # 27 (7+21+4 = 32)
	"................kkkkkkkkkkkkk...", # 28
	"................................", # 29
	"................................", # 30
	"................................", # 31
]


# ==============================================================================
# SCULPTED HEADGEAR & HAIR OVERLAYS (Exact center x = 16.5 in Down/Up)
# ==============================================================================

# --- 1) Cap. Reyes: Peaked Officer Cap (Quepe) + Gold Emblem + Silver Temples + Mustache ---
const HEAD_REYES_DOWN: Array[String] = [
	"................................", # 00
	"............cccccccccc..........", # 01 12+10+10 = 32 (x_center=16.5!)
	"..........ccBBBBBBBBBBcc........", # 02 10+14+8 = 32
	".........cBHHHHHHHHHHHHBc.......", # 03 9+16+7 = 32
	".........cHHHHHGGGGHHHHHc.......", # 04 9+16+7 = 32 centered 4x2 brass emblem (15..18)
	".........cQQQQQGGGGQQQQQc.......", # 05 9+16+7 = 32
	"........ccVVVVVVVVVVVVVVcc......", # 06 8+18+6 = 32 curved dark leather visor rim
	"........cVVVVVVVVVVVVVVVVc......", # 07 8+18+6 = 32 sloped front visor shading brows
	".........cccccccccccccccc.......", # 08 9+16+7 = 32
	"........cc..............cc......", # 09 8+2+14+2+6 = 32 silver hair tufts at temples
	"........cb..............bc......", # 10
	"........ch..............hc......", # 11
	"........cs..............sc......", # 12
	"................................", # 13
	"................................", # 14
	"..............sMMMMs............", # 15 14+6+12 = 32 thick curved silver mustache (14..19)!
	"..............s....s............", # 16 14+1+4+1+12 = 32 walrus mustache tips
	"................................", # 17
]

const HEAD_REYES_UP: Array[String] = [
	"................................", # 00
	"............cccccccccc..........", # 01 12+10+10 = 32
	"..........ccBBBBBBBBBBcc........", # 02 10+14+8 = 32
	".........cBHHHHHHHHHHHHBc.......", # 03 9+16+7 = 32
	".........cHHHHHHHHHHHHHHc.......", # 04 9+16+7 = 32
	".........cQQQQQQQQQQQQQQc.......", # 05 9+16+7 = 32
	".........ccVVVVVVVVVVVVcc.......", # 06 9+16+7 = 32 curved back cap band/strap
	"..........cchhhhhhhhhhcc........", # 07 10+14+8 = 32 trimmed salt-and-pepper hair
	".........chhbhhbhhbhhbhhc.......", # 08 9+16+7 = 32 subtle salt-and-pepper streaks (no flat bar!)
	".........chhhhhhhhhhhhhhc.......", # 09
	".........chsssshsbshssshc.......", # 10
	"........SdhsssssssssssshdS......", # 11 8+18+6 = 32
	".........chsssssssssssshc.......", # 12
	"..........crrrrrrrrrrrrc........", # 13 10+14+8 = 32 tapered hairline above nape
	"..........SllllllllllllS........", # 14 10+14+8 = 32 nape skin
	"...........SSSSSSSSSSSS.........", # 15 11+12+9 = 32
]

const HEAD_REYES_LEFT: Array[String] = [
	"................................", # 00
	"...........cccccccccc...........", # 01 sloped military officer crown
	".........ccBBBBBBBBBHcc.........", # 02
	"........cGHHHHHHHHHHHQQc........", # 03 front gold emblem + sloped back
	"........cGHHHHHHHHHHHQQc........", # 04
	"......ccVVVVVVVVVVQQQQc.........", # 05 curved visor projecting cleanly forward!
	".....cVVVVVVVVVVVVVcccc.........", # 06
	"......cccccccc..csshssc.........", # 07 salt-and-pepper temple fade (darker, non-metallic!)
	"...............cshhhhssc........", # 08 (15+9+8 = 32)
	"...............cssssshsc........", # 09 (15+9+8 = 32)
	"................csssssc.........", # 10 (16+7+9 = 32)
	".................cssssc.........", # 11 (17+6+9 = 32)
	"................................", # 12
	"................................", # 13
	"................................", # 14
	".........MMMs...................", # 15 bold silver walrus mustache beneath nose tip!
	"..........MMs...................", # 16
]

# --- 2) Bombeiro Ato: Domed Amber BFP Helmet + Headlamp + Back Neck Flap ---
const HEAD_ATO_DOWN: Array[String] = [
	"................................", # 00
	".............cccccccc...........", # 01 13+8+11 = wait symmetric 16.5 -> 13+8+11: 13+20=33!
	"...........ccBBBBBBBBcc.........", # 02 11+12+9=32!
	"..........cBBHHHHHHHHBBc........", # 03 10+14+8=32!
	".........cBHHHGGGGGGHHHBc.......", # 04 9+16+7=32! centered front headlamp housing
	".........cHHHHGGGGGGHHHHc.......", # 05 glowing headlamp
	"........ccQQQQQQQQQQQQQQcc......", # 06 8+18+6=32! curved front helmet rim
	".......cBHHHHHHHHHHHHHHHHBc.....", # 07 7+20+5=32! flared protective brim
	"........ccVVVVVVVVVVVVVVcc......", # 08 shadowed rim underside
	"........cV..............Vc......", # 09 protective dark neck flap framing jaw
	"........cV..............Vc......", # 10
	"........cV..............Vc......", # 11
	"........cV..............Vc......", # 12
	"........cV..............Vc......", # 13
	".........c..............c.......", # 14
]

const HEAD_ATO_UP: Array[String] = [
	"................................", # 00
	".............cccccccc...........", # 01 13+8+11 = 32
	"...........ccBBBBBBBBcc.........", # 02
	"..........cBBHHHHHHHHBBc........", # 03
	".........cBHHHHHHHHHHHHBc.......", # 04
	".........cHHHHHHHHHHHHHHc.......", # 05
	"........ccQQQQQQQQQQQQQQcc......", # 06 back helmet ridge
	".......cBHHHHHHHHHHHHHHHHBc.....", # 07 curved wide rear brim
	"........ccVVVVVVVVVVVVVVcc......", # 08 long protective black neck drape!
	".........cVVVVVVVVVVVVVVc.......", # 09
	".........cVVVVVVVVVVVVVVc.......", # 10
	".........cVVVVVVVVVVVVVVc.......", # 11
	".........cVVVVVVVVVVVVVVc.......", # 12
	"..........cVVVVVVVVVVVVc........", # 13
	"...........cVVVVVVVVVVc.........", # 14
	"............cccccccccc..........", # 15
]

const HEAD_ATO_LEFT: Array[String] = [
	"................................", # 00
	"............cccccccc............", # 01
	"..........ccBBBBBBBBcc..........", # 02
	".........cGGHHHHHHHHBBc.........", # 03 headlamp on brow!
	"........cGGGHHHHHHHHHHBc........", # 04
	"........cBHHHHHHHHHHHHHc........", # 05
	".......ccQQQQQQQQQQQQQQcc.......", # 06
	"......cBHHHHHHHHHHHHHHHHBc......", # 07 front shield brim + longer rear tail brim
	".......ccccccVVVVVVVVVVVc.......", # 08 back neck flap sweeping diagonally down!
	"...............cVVVVVVVVc.......", # 09 leaves face/cheek clear, covers ear & nape!
	"...............cVVVVVVVVc.......", # 10
	"................cVVVVVVVc.......", # 11
	"................cVVVVVVc........", # 12
	".................cVVVVVc........", # 13
	".................ccccc..........", # 14
]

# --- 3) Bombeiro Santos: Voluminous Curly Black Hair w/ Low Fringe + 1px Rim Light ('u') ---
const HEAD_SANTOS_DOWN: Array[String] = [
	"................................", # 00
	"............uuuu..uuuu..........", # 01 subtle cool rim light across top curly crown
	".........ccchhhhbbhhhhccc.......", # 02 (9+16+7 = 32)
	"........uchbbbhhhhhhbbbhhc......", # 03 (8+18+6 = 32)
	"........uhhhhhhhhhhhhhhhhc......", # 04 (8+18+6 = 32)
	".......uchhhbhhhhhhhhbhhhhcu....", # 05 (7+20+5 = 32) rim glint on wide temple curls
	".......chhhhhhhhhhhhhhhhhhhc....", # 06 (7+20+5 = 32)
	".......chhsshhhhhhhhhhhhsshc....", # 07 (7+20+5 = 32)
	".......chshhhhhhssshhhhhhshc....", # 08 (7+20+5 = 32) textured curly fringe covering forehead!
	".......chs..shhhhs.shhhhs.sc....", # 09 (7+20+5 = 32) low curly bangs above eyes!
	"........cs...sss.....sss..sc....", # 10 curly fringe tips & sideburns!
	"........c.................sc....", # 11
	"................................", # 12
]

const HEAD_SANTOS_UP: Array[String] = [
	"................................", # 00
	"............uuuu..uuuu..........", # 01 matching top rim silhouette!
	".........ccchhhhbbhhhhccc.......", # 02
	"........uchbbbhhhhhhbbbhhc......", # 03
	"........uhhhhhhhhhhhhhhhhc......", # 04
	".......uchhhbhhhhhhhhbhhhhcu....", # 05
	".......chhhbbbbbbbbbbbbhhhc.....", # 06 curly back sheen
	".......chhhhhhhhhhhhhhhhhhc.....", # 07
	"........chhshhhhhhhhhhhshhc.....", # 08
	"........chsshhhhhhhhhhssshc.....", # 09
	".........cssshhhssssshsssc......", # 10
	"..........csssssssssssssc.......", # 11
	"...........ccsssssssscc.........", # 12
	".............SllllllS...........", # 13
]

const HEAD_SANTOS_LEFT: Array[String] = [
	"................................", # 00
	"...........uuuuu..uuuu..........", # 01 top rim on crown silhouette!
	".........uchbbbhhhbbbhhc........", # 02
	"........uhhhhhhhhhhhhhhhc.......", # 03
	".......uchhhbhhhhhhhhbhhhu......", # 04
	"......cchhhhhhhhhhhhhhhhhhc.....", # 05
	"......chhsshhhhhhhhhhhhshhc.....", # 06 fluffy curls
	"......chhhsshhhhhhhhhhsshhc.....", # 07 low textured bangs covering side forehead!
	".......ch.ssh..shhhhhshhhc......", # 08 wavy fringe clears eye (row 14) while framing brow!
	"................ssshhhsshhc.....", # 09 back volume & neck curl
	".................csssshsssc.....", # 10
	"...................cccccc.......", # 11
]

# --- 4) Enfermeira Maria: Sweeping Parted Forehead Framing Hair + Low Oval Bun w/ Red Hairpin ---
const HEAD_MARIA_DOWN: Array[String] = [
	"................................", # 00
	"................................", # 01
	"................................", # 02
	"............cccccccccc..........", # 03 12+10+10 = 32 rounded crown
	"..........ccbbbbbbbbbbcc........", # 04 glossy hair sheen
	".........cbhhhhhhhhhhhhbc.......", # 05 9+16+7 = 32
	"........chhhhhhhhhhhhhhhhc......", # 06 8+18+6 = 32
	"........chhhhhbh..bhhhhhhc......", # 07 crisp center part over crown!
	"........chhsshhh..hhhsshhc......", # 08 2px curved center part above nose bridge!
	"........chshsss....ssshshc......", # 09 soft curved parted framing locks!
	"........chs............shc......", # 10 graceful cheek-framing hair wisps!
	"........cs..............sc......", # 11
	"........c................c......", # 12
]

const HEAD_MARIA_UP: Array[String] = [
	"................................", # 00
	"................................", # 01
	"................................", # 02
	"............cccccccccc..........", # 03
	"..........ccbbbbbbbbbbcc........", # 04
	".........cbhhhhhhhhhhhhbc.......", # 05
	"........chhhhhhhhhhhhhhhhc......", # 06
	"........chhbbbbbbbbbbbbhhc......", # 07 arched sheen across back hair
	"........chhhhhhhhhhhhhhhhc......", # 08
	".........chshhhhhhhhhhhshc......", # 09
	".........ccssshhhhhhhsscc.......", # 10 gathered toward nape
	"...........cccaaaaaaccc.........", # 11 11+12+9 = 32 signature red nurse hairpin/tie!
	"............cchhhhhhcc..........", # 12 12+10+10 = 32 full round low bun!
	"............chhbbbbhhc..........", # 13 12+10+10 = 32
	".............ccsssscc...........", # 14 13+8+11 = 32
	"..............cccccc............", # 15 14+6+12 = 32
]

const HEAD_MARIA_LEFT: Array[String] = [
	"................................", # 00
	"................................", # 01
	"................................", # 02
	"...........ccccccccc............", # 03
	".........ccbbbbbbbbbcc..........", # 04
	"........chhhhhhhhhhhhhc.........", # 05
	".......chhhhhhbbbbhhhhhc........", # 06
	"......chhsshh.shhhhhhhhhc.......", # 07 parted bangs sweep forward across side forehead!
	"......chsh....sshhhhhhhaac......", # 08 framing temple strand + red hairband + low oval bun!
	".......ch......sssshhhbbhhc.....", # 09
	"................ssshhhhhhhc.....", # 10
	".................ccssshhcc......", # 11
	"...................cccccc.......", # 12
]


static func get_base_grid(dir: String, pose: String) -> Array[String]:
	var raw: Array[String]
	match dir:
		"up":
			match pose:
				"step_a": raw = BASE_UP_STEP_A
				"step_b": raw = BASE_UP_STEP_B
				_: raw = BASE_UP_IDLE
		"left":
			match pose:
				"step_a": raw = BASE_LEFT_STEP_A
				"step_b": raw = BASE_LEFT_STEP_B
				_: raw = BASE_LEFT_IDLE
		"right":
			match pose:
				"step_a": raw = mirror_grid_h(BASE_LEFT_STEP_A)
				"step_b": raw = mirror_grid_h(BASE_LEFT_STEP_B)
				_: raw = mirror_grid_h(BASE_LEFT_IDLE)
		_: # "down"
			match pose:
				"step_a": raw = BASE_DOWN_STEP_A
				"step_b": raw = BASE_DOWN_STEP_B
				_: raw = BASE_DOWN_IDLE
			# Ensure uniform symmetrical fixed Down head on rows 0..15
			var patched: Array[String] = raw.duplicate()
			for r in range(mini(16, _DOWN_HEAD_LINES_FIXED.size())):
				patched[r] = _DOWN_HEAD_LINES_FIXED[r]
			return patched
	return raw


static func mirror_grid_h(grid: Array[String]) -> Array[String]:
	var out: Array[String] = []
	for row_s in grid:
		var padded := row_s
		while padded.length() < 32:
			padded += "."
		var flipped := ""
		for i in range(32):
			flipped += padded.substr(31 - i, 1)
		out.append(flipped)
	return out
