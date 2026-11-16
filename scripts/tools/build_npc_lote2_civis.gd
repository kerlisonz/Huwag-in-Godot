@tool
extends SceneTree
## Generates Batch 2 (Civis de Agdangan + Toby [escala infantil, sem combate] + Vulto Calcinado)
## using Huwag v3's organic anatomical style, bespoke props, 7 distinct attacks, and 7 unique deaths.

const Builder = preload("res://scripts/tools/npc_pixel_rig/npc_sprite_builder.gd")

const ARTIFACT_DIR := "C:/Users/SnyX/.gemini/antigravity/brain/6f04634a-b7d4-4d6f-9c20-24b6fdf404a0"
const BASE_OUT_DIR := "res://assets/sprites/npcs"
const FLOOR_COLOR := Color("#2C1E16")
const FLOOR_SEAM := Color("#3B281E")


func _init() -> void:
	var specs: Array[Dictionary] = [
		_spec_aling_nena(),
		_spec_kuya_ben(),
		_spec_mang_tomas(),
		_spec_mang_carding(),
		_spec_toby(),
		_spec_senhora_luningning(),
		_spec_lola_rosa(),
		_spec_vulto_bosque(),
	]

	var results: Array[Dictionary] = []
	for spec in specs:
		var npc_id: String = str(spec["id"])
		var npc_dir: String = "%s/%s" % [BASE_OUT_DIR, npc_id]
		var res_norm: Dictionary = Builder.build_character_assets(spec, "normal", npc_dir)
		var res_dist: Dictionary = Builder.build_character_assets(spec, "distorted", npc_dir)
		results.append({
			"spec": spec,
			"normal": res_norm,
			"distorted": res_dist,
		})
		_print_metrics(npc_id, res_norm, res_dist)

	_build_boards(results)
	print("[LOTE 2] Civis + Toby + Vulto concluido com sucesso.")
	quit(0)


# ---------------------------------------------------------------------------
# Lote 2 Character Specifications
# ---------------------------------------------------------------------------
func _spec_aling_nena() -> Dictionary:
	var nena_skin_norm := {
		"p": Color("#E2A476"),
		"l": Color("#CE8E63"),
		"d": Color("#9A6245"),
		"q": Color("#B87A56"),
		"S": Color("#543323"),
		"r": Color("#8A4E38"),
		"w": Color("#F0F2F7"),
		"E": Color("#1F191C"),
	}
	return {
		"id": "aling_nena",
		"label": "Aling Nena",
		"batch": 2,
		"build": "standard",
		"head_id": "nena",
		"outfit_style": "sari_apron",
		"attack_style": "broom_sweep",
		"tired_eyes": false,
		"helmet_crack": false,
		"normal": {
			"skin": nena_skin_norm,
			"hair": {
				"base": Color("#38343B"),
				"hi": Color("#747180"),
				"sh": Color("#211E24"),
				"pin": Color("#DE4754"),
				"out": Color("#17151A"),
			},
			"hat": {
				"base": Color("#38343B"),
				"hi": Color("#747180"),
				"sh": Color("#211E24"),
				"out": Color("#17151A"),
			},
			"torso": {
				"base": Color("#2A6E75"),
				"hi": Color("#469AA3"),
				"sh": Color("#1B494F"),
				"undershirt": Color("#E8AE7B"),
				"stripe1": Color("#F2E5D2"),
				"stripe2": Color("#F2C452"),
				"strap": Color("#8C6239"),
				"stain": Color("#8C1D24"),
				"out": Color("#132629"),
			},
			"legs": {
				"base": Color("#2A3142"),
				"sh": Color("#1B202E"),
				"boots": Color("#5E3E2A"),
				"boots_hi": Color("#8C6449"),
			},
			"talk_prop": {
				"kind": "broom_fan",
				"primary": Color("#D9A85B"),
				"secondary": Color("#FAE49D"),
				"accent": Color("#E05348"),
			},
			"weapon": {
				"blade": Color("#D9AF5B"),
				"blade_hi": Color("#FFF3BA"),
				"handle": Color("#7A4E2D"),
				"accent": Color("#D9483B"),
			},
		},
		"distorted": {
			"skin": Builder.default_skin_distorted(),
			"hair": {
				"base": Color("#2D2A33"),
				"hi": Color("#54505E"),
				"sh": Color("#1A181F"),
				"pin": Color("#A8222E"),
				"out": Color("#131117"),
			},
			"hat": {
				"base": Color("#2D2A33"),
				"hi": Color("#54505E"),
				"sh": Color("#1A181F"),
				"out": Color("#131117"),
			},
			"torso": {
				"base": Color("#22383D"),
				"hi": Color("#335157"),
				"sh": Color("#162429"),
				"undershirt": Color("#82757C"),
				"stripe1": Color("#B8A5A8"),
				"stripe2": Color("#994B38"),
				"strap": Color("#4F322B"),
				"stain": Color("#991B26"),
				"out": Color("#12171A"),
			},
			"legs": {
				"base": Color("#1E202B"),
				"sh": Color("#14151D"),
				"boots": Color("#382824"),
				"boots_hi": Color("#543D38"),
			},
			"talk_prop": {
				"kind": "broom_fan",
				"primary": Color("#8C6245"),
				"secondary": Color("#BDA69D"),
				"accent": Color("#D63038"),
			},
			"weapon": {
				"blade": Color("#947353"),
				"blade_hi": Color("#D4B0AE"),
				"handle": Color("#4A291F"),
				"accent": Color("#E02D35"),
			},
		},
	}


func _spec_kuya_ben() -> Dictionary:
	return {
		"id": "kuya_ben",
		"label": "Kuya Ben",
		"batch": 2,
		"build": "broad",
		"head_id": "ben",
		"outfit_style": "mechanic_overalls",
		"attack_style": "wrench_smash",
		"tired_eyes": true,
		"helmet_crack": false,
		"normal": {
			"skin": Builder.default_skin_normal(),
			"mustache": Color("#1E1D24"),
			"hair": {
				"base": Color("#26252E"),
				"hi": Color("#444252"),
				"sh": Color("#18171E"),
				"out": Color("#121117"),
			},
			"hat": {
				"base": Color("#2F486E"),
				"hi": Color("#4D70A3"),
				"sh": Color("#1F304A"),
				"visor": Color("#151E2E"),
				"emblem": Color("#F5C142"),
				"out": Color("#121824"),
			},
			"torso": {
				"base": Color("#2C4266"),
				"hi": Color("#466699"),
				"sh": Color("#1C2B45"),
				"undershirt": Color("#D4CBBA"),
				"stripe1": Color("#2C4266"),
				"stripe2": Color("#E6643E"),
				"strap": Color("#404B5E"),
				"stain": Color("#8A1D24"),
				"out": Color("#121724"),
			},
			"legs": {
				"base": Color("#23314A"),
				"sh": Color("#161F30"),
				"boots": Color("#382B22"),
				"boots_hi": Color("#6B5342"),
			},
			"talk_prop": {
				"kind": "wrench_rag",
				"primary": Color("#758394"),
				"secondary": Color("#DCE3EB"),
				"accent": Color("#B8C4D4"),
			},
			"weapon": {
				"blade": Color("#8E9CAD"),
				"blade_hi": Color("#EDF4FC"),
				"handle": Color("#4A5563"),
				"accent": Color("#D94E34"),
			},
		},
		"distorted": {
			"skin": Builder.default_skin_distorted(),
			"mustache": Color("#2C2830"),
			"hair": {
				"base": Color("#1E1D24"),
				"hi": Color("#32303B"),
				"sh": Color("#131217"),
				"out": Color("#101014"),
			},
			"hat": {
				"base": Color("#2E384D"),
				"hi": Color("#475573"),
				"sh": Color("#1C2230"),
				"visor": Color("#131722"),
				"emblem": Color("#E03E36"),
				"out": Color("#14121C"),
			},
			"torso": {
				"base": Color("#293247"),
				"hi": Color("#41506E"),
				"sh": Color("#191F2E"),
				"rim": Color("#63759C"),
				"undershirt": Color("#8A838A"),
				"stripe1": Color("#293247"),
				"stripe2": Color("#A33930"),
				"strap": Color("#302C38"),
				"stain": Color("#9E1C24"),
				"out": Color("#13111A"),
			},
			"legs": {
				"base": Color("#181C29"),
				"sh": Color("#10131C"),
				"boots": Color("#241B1C"),
				"boots_hi": Color("#423133"),
			},
			"talk_prop": {
				"kind": "wrench_rag",
				"primary": Color("#545763"),
				"secondary": Color("#B09FA6"),
				"accent": Color("#7D7785"),
			},
			"weapon": {
				"blade": Color("#787682"),
				"blade_hi": Color("#D4C2C8"),
				"handle": Color("#38313A"),
				"accent": Color("#E03038"),
			},
		},
	}


func _spec_mang_tomas() -> Dictionary:
	return {
		"id": "mang_tomas",
		"label": "Mang Tomas",
		"batch": 2,
		"build": "broad",
		"head_id": "tomas",
		"outfit_style": "market_apron",
		"attack_style": "cleaver_slash",
		"tired_eyes": false,
		"helmet_crack": false,
		"normal": {
			"skin": Builder.default_skin_normal(),
			"mustache": Color("#2B282E"),
			"hair": {
				"base": Color("#302E36"),
				"hi": Color("#575361"),
				"sh": Color("#1D1B21"),
				"out": Color("#141217"),
			},
			"hat": {
				"base": Color("#D6B265"),
				"hi": Color("#F5DC9B"),
				"sh": Color("#9E7835"),
				"visor": Color("#6E5224"),
				"emblem": Color("#B84235"),
				"out": Color("#4A3316"),
			},
			"torso": {
				"base": Color("#3C6B50"),
				"hi": Color("#589672"),
				"sh": Color("#254533"),
				"undershirt": Color("#4F8565"),
				"stripe1": Color("#EFE8D8"),
				"stripe2": Color("#D4A95B"),
				"strap": Color("#7D583A"),
				"stain": Color("#9E1F28"),
				"out": Color("#1A261F"),
			},
			"legs": {
				"base": Color("#2A2F3B"),
				"sh": Color("#1B1E26"),
				"boots": Color("#453224"),
				"boots_hi": Color("#75573F"),
			},
			"talk_prop": {
				"kind": "salakot_wave",
				"primary": Color("#A87E46"),
				"secondary": Color("#F5DE9D"),
				"accent": Color("#CF4E38"),
			},
			"weapon": {
				"blade": Color("#7B8FA6"),
				"blade_hi": Color("#EDF7FF"),
				"handle": Color("#6E452A"),
				"accent": Color("#D12C38"),
			},
		},
		"distorted": {
			"skin": Builder.default_skin_distorted(),
			"mustache": Color("#3B3740"),
			"hair": {
				"base": Color("#26242B"),
				"hi": Color("#413D4A"),
				"sh": Color("#17151B"),
				"out": Color("#121015"),
			},
			"hat": {
				"base": Color("#78623D"),
				"hi": Color("#9C8152"),
				"sh": Color("#4D3D24"),
				"visor": Color("#332818"),
				"emblem": Color("#CC2B2B"),
				"out": Color("#291E12"),
			},
			"torso": {
				"base": Color("#283B33"),
				"hi": Color("#3B5449"),
				"sh": Color("#1A2621"),
				"undershirt": Color("#31473E"),
				"stripe1": Color("#A89296"),
				"stripe2": Color("#8A4E3B"),
				"strap": Color("#472C26"),
				"stain": Color("#AD1D28"),
				"out": Color("#17141A"),
			},
			"legs": {
				"base": Color("#1D1E26"),
				"sh": Color("#13141A"),
				"boots": Color("#291E1B"),
				"boots_hi": Color("#473530"),
			},
			"talk_prop": {
				"kind": "salakot_wave",
				"primary": Color("#6E5035"),
				"secondary": Color("#BDAA9E"),
				"accent": Color("#D93038"),
			},
			"weapon": {
				"blade": Color("#8E8691"),
				"blade_hi": Color("#F0D8DC"),
				"handle": Color("#45261F"),
				"accent": Color("#E02832"),
			},
		},
	}


func _spec_mang_carding() -> Dictionary:
	var carding_skin_norm := {
		"p": Color("#CC8E64"),
		"l": Color("#B3744D"),
		"d": Color("#855236"),
		"q": Color("#9E6342"),
		"S": Color("#47281B"),
		"r": Color("#6E3E29"),
		"w": Color("#F0F2F7"),
		"E": Color("#1E181C"),
	}
	return {
		"id": "mang_carding",
		"label": "Mang Carding",
		"batch": 2,
		"build": "standard",
		"head_id": "carding",
		"outfit_style": "pier_fisherman",
		"attack_style": "oar_sweep",
		"tired_eyes": true,
		"helmet_crack": false,
		"normal": {
			"skin": carding_skin_norm,
			"mustache": Color("#5B6170"),
			"hair": {
				"base": Color("#3D414D"),
				"hi": Color("#7E8496"),
				"sh": Color("#242730"),
				"rim": Color("#9BA3B8"),
				"out": Color("#15171F"),
			},
			"hat": {
				"base": Color("#364D5E"),
				"hi": Color("#567891"),
				"sh": Color("#22313D"),
				"visor": Color("#162029"),
				"emblem": Color("#E3B44B"),
				"out": Color("#121A21"),
			},
			"torso": {
				"base": Color("#385B66"),
				"hi": Color("#568694"),
				"sh": Color("#233B42"),
				"rim": Color("#75A1AD"),
				"undershirt": Color("#8DA6AD"),
				"stripe1": Color("#4D717D"),
				"stripe2": Color("#D9BA7C"),
				"strap": Color("#5C4630"),
				"stain": Color("#8C1D24"),
				"out": Color("#142229"),
			},
			"legs": {
				"base": Color("#263542"),
				"sh": Color("#19232B"),
				"boots": Color("#5C432D"),
				"boots_hi": Color("#8F6B4A"),
			},
			"talk_prop": {
				"kind": "kerosene_lantern",
				"primary": Color("#634A32"),
				"secondary": Color("#FFE082"),
				"accent": Color("#D9BA7C"),
			},
			"weapon": {
				"blade": Color("#B88552"),
				"blade_hi": Color("#E6C08A"),
				"handle": Color("#754E2B"),
				"accent": Color("#4895B0"),
			},
		},
		"distorted": {
			"skin": Builder.default_skin_distorted(),
			"mustache": Color("#63606E"),
			"hair": {
				"base": Color("#30313B"),
				"hi": Color("#595A69"),
				"sh": Color("#1E1F26"),
				"rim": Color("#78758A"),
				"out": Color("#131217"),
			},
			"hat": {
				"base": Color("#26313B"),
				"hi": Color("#3A4854"),
				"sh": Color("#171E24"),
				"visor": Color("#11151A"),
				"emblem": Color("#D93832"),
				"out": Color("#121318"),
			},
			"torso": {
				"base": Color("#25363D"),
				"hi": Color("#385059"),
				"sh": Color("#182329"),
				"rim": Color("#546B75"),
				"undershirt": Color("#5D696E"),
				"stripe1": Color("#2F4147"),
				"stripe2": Color("#8C7258"),
				"strap": Color("#3B2924"),
				"stain": Color("#991B26"),
				"out": Color("#14151A"),
			},
			"legs": {
				"base": Color("#1A2029"),
				"sh": Color("#11151C"),
				"boots": Color("#362620"),
				"boots_hi": Color("#543C33"),
			},
			"talk_prop": {
				"kind": "kerosene_lantern",
				"primary": Color("#3D2E27"),
				"secondary": Color("#FF5A4E"),
				"accent": Color("#8A745A"),
			},
			"weapon": {
				"blade": Color("#7A594B"),
				"blade_hi": Color("#B88E82"),
				"handle": Color("#472C22"),
				"accent": Color("#D9323A"),
			},
		},
	}


func _spec_toby() -> Dictionary:
	var toby_skin_norm := {
		"p": Color("#EAB486"),
		"l": Color("#D69C6F"),
		"d": Color("#A36E4B"),
		"q": Color("#BF855E"),
		"S": Color("#5C3A29"),
		"r": Color("#91593F"),
		"w": Color("#F4F6FA"),
		"E": Color("#211A1E"),
	}
	var toby_skin_dist := {
		"p": Color("#B3ADBA"),
		"l": Color("#96909E"),
		"d": Color("#6B6673"),
		"q": Color("#524E59"),
		"S": Color("#302B38"),
		"r": Color("#5E5261"),
		"w": Color("#DCD7E3"),
		"E": Color("#2B2638"),
	}
	return {
		"id": "toby",
		"label": "Toby",
		"batch": 2,
		"build": "child",
		"head_id": "toby",
		"outfit_style": "kid_tee_backpack",
		"attack_style": "none",
		"tired_eyes": false,
		"helmet_crack": false,
		"normal": {
			"skin": toby_skin_norm,
			"hair": {
				"base": Color("#221E26"),
				"hi": Color("#423D4D"),
				"sh": Color("#141217"),
				"out": Color("#121015"),
			},
			"hat": {
				"base": Color("#DE4F3A"),
				"hi": Color("#FF8266"),
				"sh": Color("#992B22"),
				"visor": Color("#2F384A"),
				"emblem": Color("#F7D454"),
				"out": Color("#3D1614"),
			},
			"torso": {
				"base": Color("#E6B338"),
				"hi": Color("#FFE26B"),
				"sh": Color("#AD7F1F"),
				"undershirt": Color("#3B629E"),
				"stripe1": Color("#294473"),
				"stripe2": Color("#F26849"),
				"strap": Color("#40649E"),
				"stain": Color("#AD7F1F"),
				"out": Color("#3B2814"),
			},
			"legs": {
				"base": Color("#314A70"),
				"sh": Color("#1F2F4A"),
				"boots": Color("#DE4E3B"),
				"boots_hi": Color("#EEF2FA"),
			},
			"talk_prop": {
				"kind": "kid_point_wave",
				"primary": Color("#E6B338"),
				"secondary": Color("#EEF2FA"),
				"accent": Color("#3B629E"),
			},
			"weapon": {
				"blade": Color("#E6B338"),
				"blade_hi": Color("#FFE26B"),
				"handle": Color("#3B629E"),
				"accent": Color("#EEF2FA"),
			},
		},
		"distorted": {
			"skin": toby_skin_dist,
			"hair": {
				"base": Color("#24222B"),
				"hi": Color("#3E3B4A"),
				"sh": Color("#16151C"),
				"out": Color("#141218"),
			},
			"hat": {
				"base": Color("#8A4E52"),
				"hi": Color("#AD6B70"),
				"sh": Color("#5C3135"),
				"visor": Color("#2B2B38"),
				"emblem": Color("#B8A88A"),
				"out": Color("#291A1E"),
			},
			"torso": {
				"base": Color("#9E8D5E"),
				"hi": Color("#BFB082"),
				"sh": Color("#6E603F"),
				"undershirt": Color("#3D4E6E"),
				"stripe1": Color("#2D3852"),
				"stripe2": Color("#8A544E"),
				"strap": Color("#455066"),
				"stain": Color("#6E603F"),
				"out": Color("#292420"),
			},
			"legs": {
				"base": Color("#2D374D"),
				"sh": Color("#1E2433"),
				"boots": Color("#7A4C4F"),
				"boots_hi": Color("#C2BFC9"),
			},
			"talk_prop": {
				"kind": "kid_point_wave",
				"primary": Color("#9E8D5E"),
				"secondary": Color("#DCD7E3"),
				"accent": Color("#52607D"),
			},
			"weapon": {
				"blade": Color("#9E8D5E"),
				"blade_hi": Color("#DCD7E3"),
				"handle": Color("#3D4E6E"),
				"accent": Color("#DCD7E3"),
			},
		},
	}


func _spec_senhora_luningning() -> Dictionary:
	return {
		"id": "senhora_luningning",
		"label": "Sra. Luningning",
		"batch": 2,
		"build": "standard",
		"head_id": "luningning",
		"outfit_style": "luningning_shawl",
		"attack_style": "spectral_lantern",
		"tired_eyes": true,
		"helmet_crack": false,
		"normal": {
			"skin": Builder.default_skin_normal(),
			"hair": {
				"base": Color("#8D90A3"),
				"hi": Color("#CCD0E3"),
				"sh": Color("#5B5E70"),
				"pin": Color("#A36AE0"),
				"rim": Color("#D2BFFF"),
				"out": Color("#262433"),
			},
			"hat": {
				"base": Color("#8D90A3"),
				"hi": Color("#CCD0E3"),
				"sh": Color("#5B5E70"),
				"visor": Color("#383447"),
				"emblem": Color("#E0B8FF"),
				"out": Color("#262433"),
			},
			"torso": {
				"base": Color("#4C335E"),
				"hi": Color("#7A5496"),
				"sh": Color("#2F1E3D"),
				"rim": Color("#9A75B8"),
				"undershirt": Color("#64457A"),
				"stripe1": Color("#CBB8DF"),
				"stripe2": Color("#E8C468"),
				"strap": Color("#473854"),
				"stain": Color("#941E28"),
				"out": Color("#1E1529"),
			},
			"legs": {
				"base": Color("#2C1E38"),
				"sh": Color("#1C1324"),
				"boots": Color("#3B2B45"),
				"boots_hi": Color("#634C73"),
			},
			"talk_prop": {
				"kind": "elder_lantern",
				"primary": Color("#4D4254"),
				"secondary": Color("#F5D0FF"),
				"accent": Color("#B87AE8"),
			},
			"weapon": {
				"blade": Color("#D9B8FF"),
				"blade_hi": Color("#F6EBFF"),
				"handle": Color("#4C335E"),
				"accent": Color("#B469FA"),
			},
		},
		"distorted": {
			"skin": Builder.default_skin_distorted(),
			"hair": {
				"base": Color("#6A6878"),
				"hi": Color("#9995A8"),
				"sh": Color("#42404D"),
				"pin": Color("#C92E42"),
				"rim": Color("#A6758E"),
				"out": Color("#1A1721"),
			},
			"hat": {
				"base": Color("#6A6878"),
				"hi": Color("#9995A8"),
				"sh": Color("#42404D"),
				"visor": Color("#29232E"),
				"emblem": Color("#FF4D6D"),
				"out": Color("#1A1721"),
			},
			"torso": {
				"base": Color("#34213D"),
				"hi": Color("#50345C"),
				"sh": Color("#211426"),
				"rim": Color("#754E6E"),
				"undershirt": Color("#422A4A"),
				"stripe1": Color("#9C8296"),
				"stripe2": Color("#B54B58"),
				"strap": Color("#2E1D2B"),
				"stain": Color("#B81D2B"),
				"out": Color("#17101C"),
			},
			"legs": {
				"base": Color("#211526"),
				"sh": Color("#140D17"),
				"boots": Color("#291A24"),
				"boots_hi": Color("#47303F"),
			},
			"talk_prop": {
				"kind": "elder_lantern",
				"primary": Color("#33232E"),
				"secondary": Color("#FF4D6D"),
				"accent": Color("#C92E42"),
			},
			"weapon": {
				"blade": Color("#D96B84"),
				"blade_hi": Color("#FFB8C6"),
				"handle": Color("#34213D"),
				"accent": Color("#FF3856"),
			},
		},
	}


func _spec_lola_rosa() -> Dictionary:
	return {
		"id": "lola_rosa",
		"label": "Lola Rosa",
		"batch": 2,
		"build": "standard",
		"head_id": "rosa",
		"outfit_style": "rosa_herbalist",
		"attack_style": "ash_herb_gust",
		"tired_eyes": false,
		"helmet_crack": false,
		"normal": {
			"skin": Builder.default_skin_normal(),
			"hair": {
				"base": Color("#D2D6E3"),
				"hi": Color("#F5F7FC"),
				"sh": Color("#9398AB"),
				"pin": Color("#E0647E"),
				"out": Color("#4A3E36"),
			},
			"hat": {
				"base": Color("#EDE4D5"),
				"hi": Color("#FFFFFF"),
				"sh": Color("#BFB29F"),
				"visor": Color("#8A7D6D"),
				"emblem": Color("#E0647E"),
				"out": Color("#4A3E36"),
			},
			"torso": {
				"base": Color("#4D6E43"),
				"hi": Color("#739E65"),
				"sh": Color("#31472A"),
				"undershirt": Color("#D6C3A5"),
				"stripe1": Color("#824834"),
				"stripe2": Color("#BF8B4E"),
				"strap": Color("#5E3D29"),
				"stain": Color("#D16247"),
				"out": Color("#222E1E"),
			},
			"legs": {
				"base": Color("#543124"),
				"sh": Color("#382018"),
				"boots": Color("#5C412B"),
				"boots_hi": Color("#8A6445"),
			},
			"talk_prop": {
				"kind": "herb_sprig",
				"primary": Color("#527A3E"),
				"secondary": Color("#9BE063"),
				"accent": Color("#F7E479"),
			},
			"weapon": {
				"blade": Color("#8FD45B"),
				"blade_hi": Color("#E8FA98"),
				"handle": Color("#54783B"),
				"accent": Color("#E85D4A"),
			},
		},
		"distorted": {
			"skin": Builder.default_skin_distorted(),
			"hair": {
				"base": Color("#9A98A6"),
				"hi": Color("#C7C3D1"),
				"sh": Color("#666470"),
				"pin": Color("#B82538"),
				"out": Color("#2E2629"),
			},
			"hat": {
				"base": Color("#ABA09B"),
				"hi": Color("#D1C4BE"),
				"sh": Color("#7A706B"),
				"visor": Color("#4F4744"),
				"emblem": Color("#C42736"),
				"out": Color("#2E2629"),
			},
			"torso": {
				"base": Color("#333D2E"),
				"hi": Color("#4B5944"),
				"sh": Color("#21291E"),
				"undershirt": Color("#8C7E77"),
				"stripe1": Color("#522C29"),
				"stripe2": Color("#78523B"),
				"strap": Color("#3B2420"),
				"stain": Color("#B82630"),
				"out": Color("#1A1718"),
			},
			"legs": {
				"base": Color("#33201E"),
				"sh": Color("#211413"),
				"boots": Color("#382722"),
				"boots_hi": Color("#594038"),
			},
			"talk_prop": {
				"kind": "herb_sprig",
				"primary": Color("#473026"),
				"secondary": Color("#E06641"),
				"accent": Color("#FF9A4D"),
			},
			"weapon": {
				"blade": Color("#D4623B"),
				"blade_hi": Color("#FFB270"),
				"handle": Color("#472C26"),
				"accent": Color("#FF4638"),
			},
		},
	}


func _spec_vulto_bosque() -> Dictionary:
	var vulto_skin_smolder := {
		"p": Color("#292430"),
		"l": Color("#1F1B24"),
		"d": Color("#17141C"),
		"q": Color("#17141C"),
		"S": Color("#15121A"),
		"r": Color("#382C33"),
		"w": Color("#F2A85A"),
		"E": Color("#D96B38"),
	}
	var vulto_skin_blaze := {
		"p": Color("#211B24"),
		"l": Color("#18131B"),
		"d": Color("#120E14"),
		"q": Color("#120E14"),
		"S": Color("#0F0C12"),
		"r": Color("#4A2126"),
		"w": Color("#FFE066"),
		"E": Color("#FF3B24"),
	}
	return {
		"id": "vulto_bosque",
		"label": "Vulto Calcinado",
		"batch": 2,
		"build": "broad",
		"head_id": "vulto",
		"outfit_style": "vulto_charred_coat",
		"attack_style": "charred_axe_cleave",
		"tired_eyes": false,
		"helmet_crack": true,
		"normal": {
			"skin": vulto_skin_smolder,
			"hair": {
				"base": Color("#2B2833"),
				"hi": Color("#605A70"),
				"sh": Color("#1A1821"),
				"rim": Color("#827B96"),
				"out": Color("#15131C"),
			},
			"hat": {
				"base": Color("#34313D"),
				"hi": Color("#6F6980"),
				"sh": Color("#201D26"),
				"visor": Color("#14121A"),
				"emblem": Color("#E07E38"),
				"out": Color("#443E4F"),
			},
			"torso": {
				"base": Color("#2A2633"),
				"hi": Color("#5C566B"),
				"sh": Color("#1A1721"),
				"rim": Color("#857D99"),
				"undershirt": Color("#211E29"),
				"stripe1": Color("#5C5454"),
				"stripe2": Color("#B8592C"),
				"strap": Color("#302830"),
				"stain": Color("#CC4429"),
				"out": Color("#403A4D"),
			},
			"legs": {
				"base": Color("#221F29"),
				"sh": Color("#15131C"),
				"boots": Color("#2C2736"),
				"boots_hi": Color("#595269"),
			},
			"talk_prop": {
				"kind": "ember_flare",
				"primary": Color("#473633"),
				"secondary": Color("#FFAA52"),
				"accent": Color("#D9462B"),
			},
			"weapon": {
				"blade": Color("#948B96"),
				"blade_hi": Color("#E6C2BA"),
				"handle": Color("#3B2927"),
				"accent": Color("#E8612E"),
			},
		},
		"distorted": {
			"skin": vulto_skin_blaze,
			"hair": {
				"base": Color("#221C26"),
				"hi": Color("#5C4E69"),
				"sh": Color("#151118"),
				"rim": Color("#857294"),
				"out": Color("#130F17"),
			},
			"hat": {
				"base": Color("#2E2533"),
				"hi": Color("#6C5C78"),
				"sh": Color("#19141F"),
				"visor": Color("#120F17"),
				"emblem": Color("#FFD15C"),
				"out": Color("#47394F"),
			},
			"torso": {
				"base": Color("#241D29"),
				"hi": Color("#5C4C66"),
				"sh": Color("#15101A"),
				"rim": Color("#8C7596"),
				"undershirt": Color("#1C1521"),
				"stripe1": Color("#634945"),
				"stripe2": Color("#E65529"),
				"strap": Color("#36232B"),
				"stain": Color("#FF4024"),
				"out": Color("#45364D"),
			},
			"legs": {
				"base": Color("#19151E"),
				"sh": Color("#100D14"),
				"boots": Color("#221C24"),
				"boots_hi": Color("#4D3E4A"),
			},
			"talk_prop": {
				"kind": "ember_flare",
				"primary": Color("#472621"),
				"secondary": Color("#FFD15C"),
				"accent": Color("#FF4229"),
			},
			"weapon": {
				"blade": Color("#A89BA6"),
				"blade_hi": Color("#FFD4C2"),
				"handle": Color("#402521"),
				"accent": Color("#FF3D24"),
			},
		},
	}


# ---------------------------------------------------------------------------
# Verification Metrics & Approval Boards
# ---------------------------------------------------------------------------
func _print_metrics(npc_id: String, res_norm: Dictionary, res_dist: Dictionary) -> void:
	var idle_down: Image = res_norm["samples"]["idle_down"]
	var dist_down: Image = res_dist["samples"]["idle_down"]
	var b_n := _alpha_bounds(idle_down)
	var b_d := _alpha_bounds(dist_down)
	print("[LOTE 2] %s | normal idle_down=%s (foot y=%d) | distorted idle_down=%s (foot y=%d) | tres=%s" % [
		npc_id, str(b_n), b_n.end.y - 1, str(b_d), b_d.end.y - 1, str(res_norm["tres_path"])
	])


func _alpha_bounds(img: Image) -> Rect2i:
	var min_x := 999
	var min_y := 999
	var max_x := -1
	var max_y := -1
	for y in range(img.get_height()):
		for x in range(img.get_width()):
			if img.get_pixel(x, y).a > 0.05:
				min_x = mini(min_x, x)
				min_y = mini(min_y, y)
				max_x = maxi(max_x, x)
				max_y = maxi(max_y, y)
	if max_x < min_x:
		return Rect2i()
	return Rect2i(min_x, min_y, max_x - min_x + 1, max_y - min_y + 1)


func _load_huwag_sheet_cell(variant: String, anim: String, col: int, row: int) -> Image:
	var path: String = "res://assets/sprites/huwag_v3/%s/spritesheet_%s.png" % [variant, anim]
	var abs_p := ProjectSettings.globalize_path(path)
	var full := Image.load_from_file(abs_p)
	var cell := Image.create(48, 48, false, Image.FORMAT_RGBA8)
	if full:
		cell.blit_rect(full, Rect2i(col * 48, row * 48, 48, 48), Vector2i.ZERO)
	return cell


func _make_na_cell() -> Image:
	var img := Image.create(48, 48, false, Image.FORMAT_RGBA8)
	for x in range(10, 38):
		img.set_pixel(x, 10, Color("#4D3B31"))
		img.set_pixel(x, 38, Color("#4D3B31"))
	for y in range(10, 39):
		img.set_pixel(10, y, Color("#4D3B31"))
		img.set_pixel(37, y, Color("#4D3B31"))
	for i in range(12):
		img.set_pixel(18 + i, 18 + i, Color("#6E5446"))
		img.set_pixel(29 - i, 18 + i, Color("#6E5446"))
	return img


func _build_boards(results: Array[Dictionary]) -> void:
	var cell_step_x := 54
	var cell_step_y := 54
	var na_cell := _make_na_cell()

	# 1) Main Summary Board (1x + 4x)
	var cols := 9
	var rows := 18
	var board_w := 16 + cols * cell_step_x + 10
	var board_h := 16 + rows * cell_step_y + 10
	var board := Image.create(board_w, board_h, false, Image.FORMAT_RGBA8)
	board.fill(FLOOR_COLOR)
	for y in range(0, board_h, 24):
		for x in range(board_w):
			board.set_pixel(x, y, FLOOR_SEAM)

	var huwag_casual_row: Array[Image] = [
		_load_huwag_sheet_cell("casual", "idle", 0, 0),
		_load_huwag_sheet_cell("casual", "idle", 0, 1),
		_load_huwag_sheet_cell("casual", "idle", 0, 2),
		_load_huwag_sheet_cell("casual", "idle", 0, 3),
		_load_huwag_sheet_cell("casual", "idle", 1, 0),
		_load_huwag_sheet_cell("casual", "attack", 2, 0),
		_load_huwag_sheet_cell("casual", "attack", 2, 2),
		_load_huwag_sheet_cell("casual", "hurt", 0, 0),
		_load_huwag_sheet_cell("casual", "death", 4, 0),
	]
	var huwag_bfp_row: Array[Image] = [
		_load_huwag_sheet_cell("bombeiro", "idle", 0, 0),
		_load_huwag_sheet_cell("bombeiro", "idle", 0, 1),
		_load_huwag_sheet_cell("bombeiro", "idle", 0, 2),
		_load_huwag_sheet_cell("bombeiro", "idle", 0, 3),
		_load_huwag_sheet_cell("bombeiro", "idle", 1, 0),
		_load_huwag_sheet_cell("bombeiro", "attack", 2, 0),
		_load_huwag_sheet_cell("bombeiro", "attack", 2, 2),
		_load_huwag_sheet_cell("bombeiro", "hurt", 0, 0),
		_load_huwag_sheet_cell("bombeiro", "death", 4, 0),
	]
	_blit_board_row(board, 0, huwag_casual_row, cell_step_x, cell_step_y, Color("#F2C94C"))
	_blit_board_row(board, 1, huwag_bfp_row, cell_step_x, cell_step_y, Color("#56CCF2"))

	var row_cursor := 2
	for item in results:
		for mode in ["normal", "distorted"]:
			var samples: Dictionary = item[mode]["samples"]
			var tag_col := Color("#6FCF97") if mode == "normal" else Color("#EB5757")
			var imgs: Array[Image] = [
				samples.get("idle_down", na_cell),
				samples.get("idle_up", na_cell),
				samples.get("idle_left", na_cell),
				samples.get("idle_right", na_cell),
				samples.get("talk_down", na_cell),
				samples.get("attack_down", na_cell),
				samples.get("attack_left", na_cell),
				samples.get("hurt_down", na_cell),
				samples.get("death_down", na_cell),
			]
			_blit_board_row(board, row_cursor, imgs, cell_step_x, cell_step_y, tag_col)
			row_cursor += 1

	board.save_png("%s/lote2_civis_summary_board_1x.png" % ARTIFACT_DIR)
	var board_4x := board.duplicate()
	board_4x.resize(board_w * 4, board_h * 4, Image.INTERPOLATE_NEAREST)
	board_4x.save_png("%s/lote2_civis_summary_board_4x.png" % ARTIFACT_DIR)

	# 2) Animation Strip Board (4x): Walk Left (6f) + Talk Down (4f) + Attack/Hurt Down (5f) across all 8 NPCs
	var strip_cols := 15
	var strip_rows := 10
	var sw := 16 + strip_cols * cell_step_x + 10
	var sh := 16 + strip_rows * cell_step_y + 10
	var sboard := Image.create(sw, sh, false, Image.FORMAT_RGBA8)
	sboard.fill(FLOOR_COLOR)

	var strip_sources: Array = [
		[results[0]["normal"], Color("#6FCF97")], # Aling Nena N
		[results[1]["normal"], Color("#F2C94C")], # Kuya Ben N
		[results[2]["normal"], Color("#56CCF2")], # Mang Tomas N
		[results[3]["normal"], Color("#6FCF97")], # Mang Carding N
		[results[4]["normal"], Color("#F2994A")], # Toby N (Walk+Talk+Hurt)
		[results[4]["distorted"], Color("#BB6BD9")], # Toby D (Walk+Talk+Hurt)
		[results[5]["normal"], Color("#9B51E0")], # Senhora Luningning N
		[results[5]["distorted"], Color("#EB5757")], # Senhora Luningning D
		[results[6]["normal"], Color("#6FCF97")], # Lola Rosa N
		[results[7]["distorted"], Color("#FF4D6D")], # Vulto Calcinado D
	]
	for r_idx in range(strip_sources.size()):
		var res: Dictionary = strip_sources[r_idx][0]
		var dot_col: Color = strip_sources[r_idx][1]
		var strip_imgs: Array[Image] = []
		var third_anim := "attack" if res["sheets"].has("attack") else "hurt"
		for anim_name in ["walk", "talk", third_anim]:
			var sh_img: Image = res["sheets"][anim_name]["image"]
			var f_cnt: int = int(res["sheets"][anim_name]["frames"])
			var row_dir := 2 if anim_name == "walk" else 0
			for f in range(f_cnt):
				var cell_img := Image.create(48, 48, false, Image.FORMAT_RGBA8)
				cell_img.blit_rect(sh_img, Rect2i(f * 48, row_dir * 48, 48, 48), Vector2i.ZERO)
				strip_imgs.append(cell_img)
		while strip_imgs.size() < strip_cols:
			strip_imgs.append(na_cell)
		_blit_board_row(sboard, r_idx, strip_imgs, cell_step_x, cell_step_y, dot_col)

	var sboard_4x := sboard.duplicate()
	sboard_4x.resize(sw * 4, sh * 4, Image.INTERPOLATE_NEAREST)
	sboard_4x.save_png("%s/lote2_civis_anim_strip_4x.png" % ARTIFACT_DIR)

	# 3) Dedicated 4-Direction Attacks Showcase (Down 5f | Left 5f | Up f2 | Right f2 across all 7 combat styles)
	var atk_cols := 12
	var atk_rows := 10
	var aw := 16 + atk_cols * cell_step_x + 10
	var ah := 16 + atk_rows * cell_step_y + 10
	var aboard := Image.create(aw, ah, false, Image.FORMAT_RGBA8)
	aboard.fill(FLOOR_COLOR)

	var atk_sources: Array = [
		[results[0]["normal"], Color("#6FCF97")], # Aling Nena N (Broom Sweep)
		[results[1]["normal"], Color("#F2C94C")], # Kuya Ben N (Wrench Smash)
		[results[1]["distorted"], Color("#EB5757")], # Kuya Ben D (Crimson Wrench Smash)
		[results[2]["normal"], Color("#56CCF2")], # Mang Tomas N (Cleaver Slash)
		[results[3]["normal"], Color("#6FCF97")], # Mang Carding N (Oar Sweep)
		[results[5]["normal"], Color("#9B51E0")], # Luningning N (Spectral Lantern)
		[results[5]["distorted"], Color("#FF4D6D")], # Luningning D (Crimson Lantern)
		[results[6]["normal"], Color("#27AE60")], # Lola Rosa N (Herbal Gust)
		[results[6]["distorted"], Color("#F2994A")], # Lola Rosa D (Ash/Ember Gust)
		[results[7]["distorted"], Color("#EB5757")], # Vulto D (Charred Axe Cleave)
	]
	for r_idx in range(atk_sources.size()):
		var res: Dictionary = atk_sources[r_idx][0]
		var dot_col: Color = atk_sources[r_idx][1]
		var sh_img: Image = res["sheets"]["attack"]["image"]
		var atk_imgs: Array[Image] = []
		for row_dir in [0, 2]: # Down 5f + Left 5f
			for f in range(5):
				var cell_img := Image.create(48, 48, false, Image.FORMAT_RGBA8)
				cell_img.blit_rect(sh_img, Rect2i(f * 48, row_dir * 48, 48, 48), Vector2i.ZERO)
				atk_imgs.append(cell_img)
		for row_dir_single in [1, 3]: # Up impact f2 + Right impact f2
			var cell_s := Image.create(48, 48, false, Image.FORMAT_RGBA8)
			cell_s.blit_rect(sh_img, Rect2i(2 * 48, row_dir_single * 48, 48, 48), Vector2i.ZERO)
			atk_imgs.append(cell_s)
		_blit_board_row(aboard, r_idx, atk_imgs, cell_step_x, cell_step_y, dot_col)

	var aboard_4x := aboard.duplicate()
	aboard_4x.resize(aw * 4, ah * 4, Image.INTERPOLATE_NEAREST)
	aboard_4x.save_png("%s/lote2_civis_attacks_4x.png" % ARTIFACT_DIR)


func _blit_board_row(board: Image, row_idx: int, imgs: Array[Image], step_x: int, step_y: int, tag_col: Color) -> void:
	var base_y := 12 + row_idx * step_y
	for dy in range(4, 44):
		for dx in range(3, 6):
			board.set_pixel(dx, base_y + dy, tag_col)
	for rx in [8, board.get_width() - 6]:
		board.set_pixel(rx, base_y + 39, tag_col)
		board.set_pixel(rx + 1, base_y + 39, tag_col)

	for c_idx in range(imgs.size()):
		var img: Image = imgs[c_idx]
		var dst_x := 14 + c_idx * step_x
		for gx in range(18, 30):
			board.set_pixel(dst_x + gx, base_y + 40, FLOOR_SEAM)
		board.blend_rect(img, Rect2i(0, 0, 48, 48), Vector2i(dst_x, base_y))
