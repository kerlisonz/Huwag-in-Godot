extends RefCounted
class_name NpcLote2Templates

## Organic SNES pixel-art templates (32x32 logical space strictly centered on x=16.5, soles y=29 -> cell y=39)
## for Lote 2: Civis de Agdangan + Toby (child scale) + Vulto Calcinado do Bosque.
## Center invariant for symmetrical Down/Up silhouettes: min_x + max_x == 33 (left_dots - right_dots == 2).

const _LOTE1 = preload("res://scripts/tools/npc_pixel_rig/npc_humanoid_templates.gd")

# ===========================================================================
# TOBY — CHILD ANATOMICAL TEMPLATES (~14x22 logical, feet locked at y=29)
# ===========================================================================
const CHILD_DOWN_IDLE: Array[String] = [
	"................................", # 00
	"................................", # 01
	"................................", # 02
	"................................", # 03
	"................................", # 04
	"................................", # 05
	"................................", # 06
	"................................", # 07
	"................................", # 08
	"............SSSSSSSSSS..........", # 09 child crown (12..21 -> center 16.5)
	"..........SSppppppppppSS........", # 10 (10..23)
	".........SppllllllllllppS.......", # 11 (9..24)
	".........SllllllllllllllS.......", # 12 (9..24)
	"........SdlllllllllllllldS......", # 13 (8..25) ears & temples
	".........SdlrllllllllrldS.......", # 14 (9..24) soft brows
	".........SdlwEklpplkEwldS.......", # 15 (9..24) crisp 2x1 child eyes (y=15)
	"...........SlddpllpddlS.........", # 16 (11..22) rounded child chin
	"...........kkplpddpppkk.........", # 17 (11..22) neck & tee collar
	"..........kkTjjkkkkjjTkk........", # 18 (10..23) compact shoulders
	"..........kjjgjjjjjjgjjk........", # 19 (10..23) mustard tee + blue backpack straps (g)
	".........kjjjgZZZZZZgjjjk.......", # 20 (9..24) A-frame arms + navy chest stripe (Z)
	".........kjjjkZZZZZZkjjjk.......", # 21 (9..24)
	".........kplkjjjjjjjjkplk.......", # 22 (9..24) curved little hands
	".........kddkkkkkkkkkkddk.......", # 23 (9..24) shirt hem
	"...........kkoovkkvookk.........", # 24 (11..22) denim shorts waist
	"............koookkoook..........", # 25 (12..21) denim shorts legs
	"............kddk..kddk..........", # 26 (12..21) tanned calves
	"............kllk..kllk..........", # 27 (12..21) ankles
	"...........kzzTk..kTzzk.........", # 28 (11..22) big SNES sneakers
	"............kkk....kkk..........", # 29 (12..21) sneaker soles strictly at y=29 -> cell y=39
	"................................", # 30
	"................................", # 31
]

const CHILD_DOWN_STEP_A: Array[String] = [
	"................................",
	"................................",
	"................................",
	"................................",
	"................................",
	"................................",
	"................................",
	"................................",
	"................................",
	"............SSSSSSSSSS..........",
	"..........SSppppppppppSS........",
	".........SppllllllllllppS.......",
	".........SllllllllllllllS.......",
	"........SdlllllllllllllldS......",
	".........SdlrllllllllrldS.......",
	".........SdlwEklpplkEwldS.......",
	"...........SlddpllpddlS.........",
	"...........kkplpddpppkk.........",
	"..........kkTjjkkkkjjTkk........",
	".........kjjjgjjjjjjgjjjk.......",
	"........kplkjgZZZZZZgjjk........",
	"........kddk.kZZZZZZkplk........",
	".............kjjjjjjkddk........",
	"............kkkkkkkkkk..........",
	"...........kkoovkkvookk.........",
	"............koook.koook.........",
	"............kddk...kllk.........",
	"...........kzzTk...kzzk.........",
	"............kkk....kTzk.........",
	"....................kk..........",
	"................................",
	"................................",
]

const CHILD_UP_IDLE: Array[String] = [
	"................................", # 00
	"................................", # 01
	"................................", # 02
	"................................", # 03
	"................................", # 04
	"................................", # 05
	"................................", # 06
	"................................", # 07
	"................................", # 08
	"............SSSSSSSSSS..........", # 09
	"..........SSddddddddddSS........", # 10
	".........SddddddddddddddS.......", # 11
	".........SddddddddddddddS.......", # 12
	"........SddddddddddddddddS......", # 13
	".........SddddddddddddddS.......", # 14
	".........SddddddddddddddS.......", # 15
	"...........SddddddddddS.........", # 16
	"...........kkddddddddkk.........", # 17
	"..........kkTjjjjjjjjTkk........", # 18
	"..........kjjgZZZZZZgjjk........", # 19 tee + blue backpack top
	".........kjjjgZggggZgjjjk.......", # 20 padded backpack body
	".........kjjjgZggggZgjjjk.......", # 21
	".........kplkgZZZZZZgkplk.......", # 22 backpack bottom & arms
	".........kddkkkkkkkkkkddk.......", # 23
	"...........kkoovkkvookk.........", # 24 shorts
	"............koookkoook..........", # 25
	"............kddk..kddk..........", # 26
	"............kllk..kllk..........", # 27
	"...........kzzTk..kTzzk.........", # 28 sneakers
	"............kkk....kkk..........", # 29 soles at y=29
	"................................", # 30
	"................................", # 31
]

const CHILD_UP_STEP_A: Array[String] = [
	"................................",
	"................................",
	"................................",
	"................................",
	"................................",
	"................................",
	"................................",
	"................................",
	"................................",
	"............SSSSSSSSSS..........",
	"..........SSddddddddddSS........",
	".........SddddddddddddddS.......",
	".........SddddddddddddddS.......",
	"........SddddddddddddddddS......",
	".........SddddddddddddddS.......",
	".........SddddddddddddddS.......",
	"...........SddddddddddS.........",
	"...........kkddddddddkk.........",
	"..........kkTjjjjjjjjTkk........",
	".........kjjjgZZZZZZgjjjk.......",
	"........kplkjgZggggZgjjk........",
	"........kddk.gZZZZZZgkplk.......",
	".............kkkkkkkkkddk.......",
	"............kkkkkkkkkk..........",
	"...........kkoovkkvookk.........",
	"............koook.koook.........",
	"............kddk...kllk.........",
	"...........kzzTk...kzzk.........",
	"............kkk....kTzk.........",
	"....................kk..........",
	"................................",
	"................................",
]

const CHILD_LEFT_IDLE: Array[String] = [
	"................................", # 00
	"................................", # 01
	"................................", # 02
	"................................", # 03
	"................................", # 04
	"................................", # 05
	"................................", # 06
	"................................", # 07
	"................................", # 08
	"...........SSSSSSSSSS...........", # 09 child crown
	"..........SpppppllllSS..........", # 10
	".........SplllllllllllS.........", # 11
	".........SlllllllllllldS........", # 12
	".........SpdddlllllldddS........", # 13
	"..........SlrllpllldlddS........", # 14 side brow
	"..........SlEwllpslkdddS........", # 15 side eye (Ew) + nose + ear
	".........SllppllldlkddS.........", # 16 nose tip (col 9) + mouth
	"..........SllllllddddS..........", # 17 rounded child jaw
	"...........SddllSSSSSS..........", # 18 neck
	"...........kkTjjgjjjkk..........", # 19 tee + shoulder + strap
	"..........kZZjjgjjjjgkZZk.......", # 20 chest stripe + blue backpack sticking back!
	"..........kZZkplkjjjkZggk.......", # 21 hand curved + padded pack
	"...........kkddkkjjjkZZgk.......", # 22 pack lower edge
	"............kkkkkkkjjkkkk.......", # 23 shirt hem
	"............kkooookvvtk.........", # 24 denim shorts
	".............kddk.kddk..........", # 25 calves
	".............kllk.kllk..........", # 26 ankles
	".............kllk.kllk..........", # 27 socks
	"...........kzzzzk.kzzk..........", # 28 big sneakers
	"............kkkk...kkk..........", # 29 sneaker soles y=29
	"................................", # 30
	"................................", # 31
]

const CHILD_LEFT_STEP_A: Array[String] = [
	"................................",
	"................................",
	"................................",
	"................................",
	"................................",
	"................................",
	"................................",
	"................................",
	"................................",
	"...........SSSSSSSSSS...........",
	"..........SpppppllllSS..........",
	".........SplllllllllllS.........",
	".........SlllllllllllldS........",
	".........SpdddlllllldddS........",
	"..........SlrllpllldlddS........",
	"..........SlEwllpslkdddS........",
	".........SllppllldlkddS.........",
	"..........SllllllddddS..........",
	"...........SddllSSSSSS..........",
	"...........kkTjjgjjjkk..........",
	".........kplkjggjjjjkZZk........",
	".........kddkZjkjjjkZZgk........",
	"............kkjkkkkjkZZk........",
	"............kkkkkkkjjkkk........",
	"............kkoookkoovk.........",
	"...........kddkk...kddk.........",
	"...........kllk.....kllk........",
	"..........kzzzk.....kzzk........",
	"...........kkkk......kkkk.......",
	"............kk........kk........",
	"................................",
	"................................",
]

const CHILD_LEFT_STEP_B: Array[String] = [
	"................................",
	"................................",
	"................................",
	"................................",
	"................................",
	"................................",
	"................................",
	"................................",
	"................................",
	"...........SSSSSSSSSS...........",
	"..........SpppppllllSS..........",
	".........SplllllllllllS.........",
	".........SlllllllllllldS........",
	".........SpdddlllllldddS........",
	"..........SlrllpllldlddS........",
	"..........SlEwllpslkdddS........",
	".........SllppllldlkddS.........",
	"..........SllllllddddS..........",
	"...........SddllSSSSSS..........",
	"...........kkTjjgjjjkk..........",
	"..........kZZjjgjjjkplkk........",
	"..........kZZjjkjjjkddgk........",
	"...........kkjjkkkkjkZZk........",
	"............kkkkkkkjjkkk........",
	"............koookkkoook.........",
	"............kddk..kddkk.........",
	"............kllk...kllk.........",
	"...........kzzzk...kzzk.........",
	"...........kkkk.....kkk.........",
	"............kk.......kk.........",
	"................................",
	"................................",
]


# ===========================================================================
# HEAD OVERLAYS FOR LOTE 2 (strictly aligned around x=16.5 in Down/Up)
# ===========================================================================

# 1. TOBY — Big red backward snapback cap + messy dark tufts on forehead (rows 6..12)
const HEAD_TOBY_DOWN: Array[String] = [
	"................................", # 00
	"................................", # 01
	"................................", # 02
	"................................", # 03
	"................................", # 04
	"................................", # 05
	".............cccccccc...........", # 06 (13..20)
	"...........ccBBHHHHBBcc.........", # 07 (11..22)
	"..........cBBHHHHHHHHBBc........", # 08 (10..23)
	".........cBHHHHQQQQHHHHBc.......", # 09 (9..24) snapback cutout at center
	".........cchchcQQQQchchcc.......", # 10 (9..24) messy dark tufts peeking below snapback
	".........chbshsssssshsbhc.......", # 11 (9..24) 9+16+7=32
	".........cchsh.s..s.hshcc.......", # 12 (9..24) wait 9+16+7=32
	"................................", # 13
	"................................", # 14
	"................................", # 15
	"................................", # 16
	"................................", # 17
]

const HEAD_TOBY_UP: Array[String] = [
	"................................", # 00
	"................................", # 01
	"................................", # 02
	"................................", # 03
	"................................", # 04
	"................................", # 05
	".............cccccccc...........", # 06 (13..20)
	"...........ccBBHHHHBBcc.........", # 07 (11..22)
	"..........cBBHHHHHHHHBBc........", # 08 (10..23)
	".........cBHHHHHHHHHHHHBc.......", # 09 (9..24)
	".........ccHHHHHHHHHHHHcc.......", # 10 (9..24)
	"........ccQQQVVVVVVVVQQQcc......", # 11 (8..25) big backward visor
	".........cchccVVVVVVcchcc.......", # 12 (9..24)
	".........cchsssssssssshhc.......", # 13 (9..24) dark hair at nape
	"..........ccsssssssssscc........", # 14 (10..23)
	"............cccccccccc..........", # 15 (12..21)
	"................................", # 16
	"................................", # 17
]

const HEAD_TOBY_LEFT: Array[String] = [
	"................................",
	"................................",
	"................................",
	"................................",
	"................................",
	"................................",
	"............ccccccccc...........",
	"..........ccBBHHHHHHBcc.........",
	".........cBBHHHHHHHHHHBc........",
	".........cchQHHHHHHHHQQQccc.....",
	"........cchbshhQQQQVVVVVVQQc....",
	"........cchshhss..ccccccccc.....",
	".........ccshhs.....sshhc.......",
	"..........ccss........shc.......",
	"................................",
	"................................",
	"................................",
	"................................",
]

# 2. ALING NENA — High salt-and-pepper top bun + bright red hairpin ('a') + smooth parted waves
const HEAD_NENA_DOWN: Array[String] = [
	"................................", # 00
	"..............cccccc............", # 01 (14..19)
	".............cbbbbhhc...........", # 02 (13..20)
	"............chhhssbaac..........", # 03 (12..21) red clip gleaming on bun side
	"...........cchhhhhbaacc.........", # 04 (11..22)
	"..........cbhhhhhhhhhbbc........", # 05 (10..23)
	".........cbbhhsshhsshhbbc.......", # 06 (9..24)
	"........cchhs........shhcc......", # 07 (8..25)
	"........csh............shc......", # 08 (8..25)
	"........cs..............sc......", # 09 (8..25)
	"........c................c......", # 10 (8..25) side wisps framing cheeks
	"................................", # 11
	"................................", # 12
	"................................", # 13
	"................................", # 14
	"................................", # 15
	"................................", # 16
	"................................", # 17
]

const HEAD_NENA_UP: Array[String] = [
	"................................", # 00
	"..............cccccc............", # 01 (14..19)
	".............cbhhhhbc...........", # 02 (13..20)
	"............chhbbhhshc..........", # 03 (12..21)
	"...........cshaaaaaaahc.........", # 04 (11..22) red hairpin across back of bun!
	".........cbbhhsssssshhbbc.......", # 05 (9..24)
	".........chhhhhhhhhhhhhhc.......", # 06 (9..24)
	".........chhhsssssssshhhc.......", # 07 (9..24)
	"........cchhhsssssssshhhcc......", # 08 (8..25)
	"........cchhhsssssssshhhcc......", # 09 (8..25)
	".........chhhsssssssshhhc.......", # 10 (9..24)
	".........cchhsssssssshhcc.......", # 11 (9..24)
	".........cchsssssssssshhc.......", # 12 (9..24)
	"..........ccsssssssssscc........", # 13 (10..23)
	"...........ccsssssssscc.........", # 14 (11..22)
	"............cccccccccc..........", # 15 (12..21)
	"................................", # 16
	"................................", # 17
]

const HEAD_NENA_LEFT: Array[String] = [
	"................................",
	"...............cccccc...........",
	"..............cbhhhhbc..........",
	".............chhshaaaac.........",
	"..........ccchhsshaaaacc........",
	".........cbbhhhhhhshhhbbc.......",
	"........cbhhhss.......shhc......",
	"........chhs...........sshc.....",
	"........chs.............shc.....",
	"........cs..............shc.....",
	".........................sh.....",
	".........................ss.....",
	"................................",
	"................................",
	"................................",
	"................................",
	"................................",
	"................................",
]

# 3. KUYA BEN — Slate-blue mechanic/trucker cap w/ visor + dark temples + dark mustache ('M')
const HEAD_BEN_DOWN: Array[String] = [
	"................................", # 00
	"................................", # 01
	"............cccccccccc..........", # 02 (12..21)
	"..........ccBBHHHHHHBBcc........", # 03 (10..23)
	".........cBBHHHHHHHHHHBBc.......", # 04 (9..24)
	".........cHHHHHHHHHHHHHHc.......", # 05 (9..24)
	".........cHHHQGGGGGGQHHHc.......", # 06 (9..24) mechanic emblem patch
	".........cQQQQQQQQQQQQQQc.......", # 07 (9..24) brim fold
	".........cVVVVVVVVVVVVVVc.......", # 08 (9..24) rounded visor shade cleanly above eyes (13..14)
	"........ccsh..VVVVVV..shcc......", # 09 (8..25) dark short sideburns
	"........cs..............sc......", # 10 (8..25)
	"................................", # 11
	"................................", # 12
	"................................", # 13
	"................................", # 14
	".............cMMMMMMc...........", # 15 (13..20) thick dark mustache!
	"................................", # 16
	"................................", # 17
]

const HEAD_BEN_UP: Array[String] = [
	"................................", # 00
	"................................", # 01
	"............cccccccccc..........", # 02 (12..21)
	"..........ccBBHHHHHHBBcc........", # 03 (10..23)
	".........cBBHHHHHHHHHHBBc.......", # 04 (9..24)
	".........cHHHHHHHHHHHHHHc.......", # 05 (9..24)
	".........cHHHHHHHHHHHHHHc.......", # 06 (9..24)
	".........cHHHQVVVVVVQHHHc.......", # 07 (9..24) rear trucker snap cutout
	".........cQQQVVc..cVVQQQc.......", # 08 (9..24)
	"........ccshhhhhhhhhhhshcc......", # 09 (8..25 -> 8+18+6=32)
	"........cssssssssssssssssc......", # 10 (8..25 -> wait 8+18+6=32: "........cssssssssssssssssc......" = 8+18+6=32!)
	".........cssssssssssssssc.......", # 11 (9..24 -> 9+16+7=32) -> wait 9 dots + c + 14 s + c + 7 dots!
	".........ccsssssssssssscc.......", # 12 (9..24)
	"..........ccsssssssssscc........", # 13 (10..23)
	"...........ccsssssssscc.........", # 14 (11..22)
	"............cccccccccc..........", # 15 (12..21)
	"................................", # 16
	"................................", # 17
]

const HEAD_BEN_LEFT: Array[String] = [
	"................................",
	"................................",
	"...........ccccccccccc..........",
	".........ccBBHHHHHHHHBcc........",
	"........cBBHHHHHHHHHHHHBc.......",
	"........cHHHHHHHHHHHHHHHc.......",
	"......cccQQQQQHHHHHHHHHHc.......",
	".....cVVVVVVVVVQQQQQHHHHc.......",
	".....ccccVVVVQQQQshhhhhhc.......",
	"........cs.......sshhhhc........",
	"........cs........sshhc.........",
	"....................shc.........",
	"................................",
	"................................",
	"................................",
	"..........cMMMc.................",
	"................................",
	"................................",
]

# 4. MANG TOMAS (FEIRANTE) — Wide conical straw SALAKOT centered on x=16.5 + chin strap ('X')
const HEAD_TOMAS_DOWN: Array[String] = [
	"...............cccc.............", # 00 (15..18 -> sum=33!)
	"..............cBBBBc............", # 01 (14..19)
	".............cBBHHBBc...........", # 02 (13..20)
	"............cBBHHHHBBc..........", # 03 (12..21)
	"...........cBBHHHHHHBBc.........", # 04 (11..22)
	".........ccBBHHHHHHHHBBcc.......", # 05 (9..24)
	".......ccBBHHHHQQQQHHHHBBcc.....", # 06 (7..26)
	".....ccBBHHHHQQQQQQQQHHHHBBcc...", # 07 (5..28) wide conical brim
	"....cHHHHHHHHHHHHHHHHHHHHHHHHc..", # 08 (4..29)
	"...cQQQQQQQQQQQQQQQQQQQQQQQQQQc.", # 09 (3..30 -> 3+30=33!)
	"...ccccccccQQQQQQQQQQQQcccccccc.", # 10 (3..30) crisp shadow underside above forehead
	".........ccsssssssssssscc.......", # 11 (9..24)
	"................................", # 12
	"................................", # 13
	"..........X............X........", # 14 (10..23) chin strap hugging cheeks
	"...........X..........X.........", # 15 (11..22)
	"............XXXXXXXXXX..........", # 16 (12..21) chin strap under jaw!
	"................................", # 17
]

const HEAD_TOMAS_UP: Array[String] = [
	"...............cccc.............", # 00 (15..18)
	"..............cBBBBc............", # 01 (14..19)
	".............cBBHHBBc...........", # 02 (13..20)
	"............cBBHHHHBBc..........", # 03 (12..21)
	"...........cBBHHHHHHBBc.........", # 04 (11..22)
	".........ccBBHHHHHHHHBBcc.......", # 05 (9..24)
	".......ccBBHHHHHHHHHHHHBBcc.....", # 06 (7..26)
	".....ccBBHHHHHHHHHHHHHHHHBBcc...", # 07 (5..28)
	"....cHHHHHHHHHHHHHHHHHHHHHHHHc..", # 08 (4..29)
	"...cQQQQQQQQQQQQQQQQQQQQQQQQQQc.", # 09 (3..30)
	"...cccccccccccccccccccccccccccc.", # 10 (3..30)
	".........ccsssssssssssscc.......", # 11 (9..24)
	"..........cssssssssssssc........", # 12 (10..23)
	"...........ccsssssssscc.........", # 13 (11..22)
	"............ccsssssscc..........", # 14 (12..21)
	".............cccccccc...........", # 15 (13..20)
	"................................", # 16
	"................................", # 17
]

const HEAD_TOMAS_LEFT: Array[String] = [
	"..............cccc..............",
	".............cBBBBc.............",
	"............cBBHHBBc............",
	"...........cBBHHHHBBc...........",
	".........ccBBHHHHHHBBcc.........",
	".......ccBBHHHHHHHHHHBBcc.......",
	".....ccBBHHHHQQQQQHHHHHBBcc.....",
	"...ccBBHHHHQQQQQQQQQHHHHHBBcc...",
	"..cHHHHHHHHHHHHHHHHHHHHHHHHHHc..",
	"..cQQQQQQQQQQQQQQQQQQQQQQQQQQc..",
	"..cccccccccccccccccccccccccccc..",
	"..........cshhhhhhhshc..........",
	"...................shc..........",
	"...................shc..........",
	".............X..................",
	"............X...................",
	"...........XX...................",
	"................................",
]

# 5. MANG CARDING — Turquoise forehead bandana w/ knotted back tail-ties + short graying hair + mustache
const HEAD_CARDING_DOWN: Array[String] = [
	"................................", # 00
	"................................", # 01
	"................................", # 02
	"................................", # 03
	"............cccccccccc..........", # 04 (12..21) weathered crown hair
	"..........ccbbbbhhhhbbcc........", # 05 (10..23)
	".........cBBHHHHHHHHHHBBc.......", # 06 (9..24) TURQUOISE FOREHEAD BANDANA!
	"........cHHHHHHHHHHHHHHHHc......", # 07 (8..25)
	"........cQQQQHHHHHHHHQQQQc......", # 08 (8..25) folded brow trim
	"........cccccccccccccccccc......", # 09 (8..25)
	".........css..........ssc.......", # 10 (9..24) -> wait count 9 dots + css (3) + 10 dots + ssc (3) + 7 dots = 32!
	"................................", # 11
	"................................", # 12
	"................................", # 13
	"................................", # 14
	".............cMMMMMMc...........", # 15 (13..20) fisher mustache
	"................................", # 16
	"................................", # 17
]

const HEAD_CARDING_UP: Array[String] = [
	"................................", # 00
	"................................", # 01
	"................................", # 02
	"................................", # 03
	"............cccccccccc..........", # 04 (12..21)
	"..........ccbbbbhhhhbbcc........", # 05 (10..23)
	".........cBBHHHHHHHHHHBBc.......", # 06 (9..24)
	"........cHHHHHHHHHHHHHHHHc......", # 07 (8..25)
	"........cHHHHQQQBBQQQHHHHc......", # 08 (8..25) centered knot!
	"........ccccQQcBHHBcQQcccc......", # 09 (8..25) fluttering bandana tails!
	".........cchhBcHHHHcBhhcc.......", # 10 (9..24: 9+16+7=32)
	".........ccssccQ..Qccsscc.......", # 11 (9..24: 9+16+7=32)
	"..........ccss......sscc........", # 12 (10..23)
	"..........ccsssssssssscc........", # 13 (10..23)
	"...........ccsssssssscc.........", # 14 (11..22)
	"............cccccccccc..........", # 15 (12..21)
	"................................", # 16
	"................................", # 17
]

const HEAD_CARDING_LEFT: Array[String] = [
	"................................",
	"................................",
	"................................",
	"................................",
	"...........cccccccccc...........",
	".........ccbbbbhhhhbbcc.........",
	"........cBBHHHHHHHHHHBBc........",
	"........cHHHHHHHHHHHHHHQQccc....",
	"........cQQQQHHHHHHHHQQQBBBBc...",
	"........cccccQQQQQQQQccQQccQc...",
	"........csh.......shhs..c.......",
	"...................shc..........",
	"...................shc..........",
	"................................",
	"................................",
	"..........cMMMc.................",
	"................................",
	"................................",
]

# 6. SENHORA LUNINGNING — Silvery hair neatly parted + LOW NAPE BUN (no clip, calm elder frame)
const HEAD_LUNINGNING_DOWN: Array[String] = [
	"................................", # 00
	"................................", # 01
	"................................", # 02
	"................................", # 03
	"............cccccccccc..........", # 04 (12..21)
	"..........ccbbbbbbbbbbcc........", # 05 (10..23)
	".........cbbbbbhllhbbbbbc.......", # 06 (9..24) silver parted waves
	".........cbbhss....sshbbc.......", # 07 (9..24)
	"........cbhs..........shbc......", # 08 (8..25)
	"........ccs............scc......", # 09 (8..25)
	"................................", # 10
	"................................", # 11
	"................................", # 12
	"................................", # 13
	"................................", # 14
	"................................", # 15
	"................................", # 16
	"................................", # 17
]

const HEAD_LUNINGNING_UP: Array[String] = [
	"................................", # 00
	"................................", # 01
	"................................", # 02
	"................................", # 03
	"............cccccccccc..........", # 04 (12..21)
	"..........ccbbbbbbbbbbcc........", # 05 (10..23)
	".........cbbbbhhhhhhbbbbc.......", # 06 (9..24)
	".........cbhhhhhhhhhhhhbc.......", # 07 (9..24)
	".........chhhhcccccchhhhc.......", # 08 (9..24)
	".........chhccbhhhhbcchhc.......", # 09 (9..24)
	".........cshccbhhhhbcchsc.......", # 10 (9..24)
	"..........ccccbhhhhbcccc........", # 11 (10..23)
	"...........ccsshhhhsscc.........", # 12 (11..22)
	"............cccccccccc..........", # 13 (12..21)
	"...........ccsssssssscc.........", # 14 (11..22)
	"............cccccccccc..........", # 15 (12..21)
	"................................", # 16
	"................................", # 17
]

const HEAD_LUNINGNING_LEFT: Array[String] = [
	"................................",
	"................................",
	"................................",
	"................................",
	"...........cccccccccc...........",
	".........ccbbbbbbbbbbcc.........",
	"........cbbbhhhhsshhhhbc........",
	"........cbhs.........shhc.......",
	"........chs...........shhccc....",
	"........cs............shbbbBc...",
	".......................shbhhc...",
	".......................ssshcc...",
	".......................ccccc....",
	"................................",
	"................................",
	"................................",
	"................................",
	"................................",
]

# 7. LOLA ROSA — White floral headscarf ('H/B/Q' + 'a' rose specks) + thick silver BRAID down shoulder
const HEAD_ROSA_DOWN: Array[String] = [
	"................................", # 00
	"................................", # 01
	"................................", # 02
	"............cccccccccc..........", # 03 (12..21)
	"..........ccBBHHHHHHBBcc........", # 04 (10..23)
	".........cBBHaHHHHHHaHBBc.......", # 05 (9..24) white scarf + floral pink motifs ('a')
	".........cHHHHQQQQQQHHHHc.......", # 06 (9..24)
	".........cQHaH......HaHQc.......", # 07 (9..24)
	"........cQhs..........shQc......", # 08 (8..25)
	"........cQ..............Qc......", # 09 (8..25)
	".........c..............hc......", # 10 (9..25 -> intentional braid starting down viewer's right!)
	".......................cbc......", # 11 braid descending over left shoulder!
	".......................chc......", # 12
	"......................cbc.......", # 13
	"......................chc.......", # 14
	"......................cbc.......", # 15
	"......................cac.......", # 16 braid ribbon tie
	".......................c........", # 17
]

const HEAD_ROSA_UP: Array[String] = [
	"................................", # 00
	"................................", # 01
	"................................", # 02
	"............cccccccccc..........", # 03 (12..21)
	"..........ccBBHHHHHHBBcc........", # 04 (10..23)
	".........cBBHHaHHHHaHHBBc.......", # 05 (9..24)
	".........cHHHHHHHHHHHHHHc.......", # 06 (9..24)
	".........cHHHaHHHHHHaHHHc.......", # 07 (9..24)
	".........cQQQQQQQQQQQQQQc.......", # 08 (9..24)
	"..........ccQQQccccQQQcc........", # 09 (10..23)
	"...........ccshhssshhcc.........", # 10 (11..22)
	"...........csbhsssshsbc.........", # 11 (11..22) braid emerging left side!
	"...........cbhc....shc..........", # 12
	"..........cbc...................", # 13
	"..........chc...................", # 14
	"..........cac...................", # 15
	"...........c....................", # 16
	"................................", # 17
]

const HEAD_ROSA_LEFT: Array[String] = [
	"................................",
	"................................",
	"................................",
	"...........cccccccccc...........",
	".........ccBBHHHHHHBBcc.........",
	"........cBBHaHHHHaHHHBBc........",
	"........cHHHHQQQQQQQQHHc........",
	"........cQHs.........shQcc......",
	"........cQs...........shQQc.....",
	".........s.............shhc.....",
	"........................shc.....",
	".......................cbhc.....",
	"......................cbhs......",
	"......................chc.......",
	"......................cbc.......",
	"......................chc.......",
	"......................cac.......",
	".......................c........",
]

# 8. VULTO CALCINADO DO BOSQUE — Cracked charred BFP helmet + incandescent fissure + pitch void w/ glowing eye slits
const HEAD_VULTO_DOWN: Array[String] = [
	"..............cccccc............", # 00 (14..19) charred BFP helmet crown
	"............ccBBHHBBcc..........", # 01 (12..21)
	"..........ccBBHHGGHHBBcc........", # 02 (10..23) glowing ember crack!
	".........cBBHHHAAAGHHHBBc.......", # 03 (9..24)
	".........cHHHHQAAAAQHHHHc.......", # 04 (9..24)
	"........ccQQQQQQAAQQQQQQcc......", # 05 (8..25) wide soot helmet brim
	".......cccSSSSSSSSSSSSSSccc.....", # 06 (7..26) pitch charred face void!
	".........cSSSSSSSSSSSSSSc.......", # 07 (9..24)
	".........cSSSSSSSSSSSSSSc.......", # 08 (9..24)
	".........cSSSSSSSSSSSSSSc.......", # 09 (9..24)
	".........cSSSSSSSSSSSSSSc.......", # 10 (9..24)
	".........cSSSSSSSSSSSSSSc.......", # 11 (9..24)
	".........cSSSSSSSSSSSSSSc.......", # 12 (9..24)
	".........cSSAAASSSSAAASSc.......", # 13 (9..24) brow ember gleam
	".........cSSEESSSSSSEESSc.......", # 14 (9..24) TWO BRIGHT EMBER EYE SLITS aligned at 12..13 & 20..21!
	"...........cSSSSSSSSSSc.........", # 15 (11..22)
	"............ccSSSSSScc..........", # 16 (12..21)
	"................................", # 17
]

const HEAD_VULTO_UP: Array[String] = [
	"..............cccccc............", # 00 (14..19)
	"............ccBBHHBBcc..........", # 01 (12..21)
	"..........ccBBHHHHHHBBcc........", # 02 (10..23)
	".........cBBHHHQQAAQQHHBc.......", # 03 (9..24) wait 9+16+7=32!
	".........cHHHHHQQAAQQHHHc.......", # 04 (9..24)
	"........ccHHHHHHHHHHHHHHcc......", # 05 (8..25)
	".......ccQQQQQQQQQQQQQQQQcc.....", # 06 (7..26) long rear charred helmet cape
	"........cQQQQQQQQQQQQQQQQc......", # 07 (8..25)
	"........cQQQSSSSSSSSSSQQQc......", # 08 (8..25)
	"........cQQSSSSSSSSSSSSQQc......", # 09 (8..25)
	"........cQSSSSSSSSSSSSSSQc......", # 10 (8..25)
	".........cSSSSSSSSSSSSSSc.......", # 11 (9..24)
	".........cQSSSSSSSSSSSSQc.......", # 12 (9..24)
	"..........cSSSSSSSSSSSSc........", # 13 (10..23)
	"...........ccSSSSSSSScc.........", # 14 (11..22)
	"............cS.SSSS.Sc..........", # 15 (12..21) tattered ash skirt edges
	"................................", # 16
	"................................", # 17
]

const HEAD_VULTO_LEFT: Array[String] = [
	"............ccccccccc...........",
	"..........ccBBHHHHHHBcc.........",
	".........cBBHHHGGAAAAHBc........",
	"........cBBHHHHQAAQHHHHBc.......",
	"......cccQQQQQQQQQHHHHHQQcc.....",
	".....cVVVVVVQQQQQQQQQQQQQQQc....",
	".....ccccSSSSSScSSSSSSSSSSc.....",
	"........cSSSSSScSSSSSSSSSSc.....",
	"........cSSSSSSSSSSSSSSSSQc.....",
	"........cSSSSSSSSSSSSSSSSQc.....",
	"........cSSSSSSSSSSSSSSSSc......",
	"........cSSSSSSSSSSSSSSc........",
	"........cSSSSSSSSSSSSSSc........",
	"........cSSAAASSSSSSSSSc........",
	"........cSSEESSSSSSSSSSc........",
	".........cSSSSSSSSSSSSc.........",
	"..........cSSSSSSSSSSc..........",
	"...........ccSSSSSScc...........",
]


static func _patch_rows(grid: Array[String], replacements: Dictionary) -> Array[String]:
	var out: Array[String] = grid.duplicate()
	for idx_v in replacements.keys():
		var idx: int = int(idx_v)
		if idx >= 0 and idx < out.size():
			out[idx] = str(replacements[idx_v])
	return out


static func _sanitize_32(grid: Array[String]) -> Array[String]:
	var out: Array[String] = []
	for s in grid:
		if s.length() == 32:
			out.append(s)
		elif s.length() < 32:
			out.append(s + ".".repeat(32 - s.length()))
		else:
			out.append(s.substr(0, 32))
	return out


static func get_child_base_grid(dir: String, pose: String) -> Array[String]:
	var raw: Array[String] = []
	match dir:
		"down":
			match pose:
				"step_a": raw = CHILD_DOWN_STEP_A
				"step_b": raw = _LOTE1.mirror_grid_h(CHILD_DOWN_STEP_A)
				_: raw = CHILD_DOWN_IDLE
		"up":
			match pose:
				"step_a": raw = CHILD_UP_STEP_A
				"step_b": raw = _LOTE1.mirror_grid_h(CHILD_UP_STEP_A)
				_: raw = CHILD_UP_IDLE
		"left":
			match pose:
				"step_a": raw = CHILD_LEFT_STEP_A
				"step_b": raw = CHILD_LEFT_STEP_B
				_: raw = CHILD_LEFT_IDLE
		"right":
			raw = _LOTE1.mirror_grid_h(get_child_base_grid("left", pose))
	return _sanitize_32(raw)


static func get_head_overlay(head_id: String, dir: String) -> Array[String]:
	var d_key := "left" if dir == "right" else dir
	var raw: Array[String] = []
	match "%s_%s" % [head_id, d_key]:
		"toby_down": raw = HEAD_TOBY_DOWN
		"toby_up": raw = HEAD_TOBY_UP
		"toby_left": raw = HEAD_TOBY_LEFT
		"nena_down": raw = HEAD_NENA_DOWN
		"nena_up": raw = HEAD_NENA_UP
		"nena_left": raw = HEAD_NENA_LEFT
		"ben_down": raw = HEAD_BEN_DOWN
		"ben_up": raw = HEAD_BEN_UP
		"ben_left": raw = HEAD_BEN_LEFT
		"tomas_down": raw = HEAD_TOMAS_DOWN
		"tomas_up": raw = HEAD_TOMAS_UP
		"tomas_left": raw = HEAD_TOMAS_LEFT
		"carding_down": raw = HEAD_CARDING_DOWN
		"carding_up": raw = HEAD_CARDING_UP
		"carding_left": raw = HEAD_CARDING_LEFT
		"luningning_down": raw = HEAD_LUNINGNING_DOWN
		"luningning_up": raw = HEAD_LUNINGNING_UP
		"luningning_left": raw = HEAD_LUNINGNING_LEFT
		"rosa_down": raw = HEAD_ROSA_DOWN
		"rosa_up": raw = HEAD_ROSA_UP
		"rosa_left": raw = HEAD_ROSA_LEFT
		"vulto_down": raw = HEAD_VULTO_DOWN
		"vulto_up": raw = HEAD_VULTO_UP
		"vulto_left": raw = HEAD_VULTO_LEFT
	if raw.is_empty():
		return []
	raw = _sanitize_32(raw)
	if dir == "right":
		return _LOTE1.mirror_grid_h(raw)
	return raw
