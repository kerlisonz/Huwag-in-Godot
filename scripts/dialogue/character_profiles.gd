extends RefCounted
class_name CharacterProfiles

const PROFILES: Dictionary = {
	"huwag": {
		"display_name": "Huwag Matitiis",
		"role_subtitle": "Bombeiro Municipal · 23 anos",
		"accent_color": Color("#F5CB5C"),
		"is_placeholder": false,
		"portraits": {
			"default": "res://assets/characters/portraits/huwag_casual_neutral.png",
			"neutral": "res://assets/characters/portraits/huwag_casual_neutral.png",
			"worried": "res://assets/characters/portraits/huwag_casual_worried.png",
			"tired": "res://assets/characters/portraits/huwag_casual_tired.png",
			"surprised": "res://assets/characters/portraits/huwag_casual_surprised.png",
			"angry": "res://assets/characters/portraits/huwag_casual_angry.png",
			"determined": "res://assets/characters/portraits/huwag_casual_angry.png",
			"scared": "res://assets/characters/portraits/huwag_casual_scared.png",
			"uneasy_smile": "res://assets/characters/portraits/huwag_casual_uneasy_smile.png",
			"smile": "res://assets/characters/portraits/huwag_casual_uneasy_smile.png",
			"unfiltered": "res://assets/characters/portraits/huwag_casual_unfiltered.png"
		},
		"portraits_bfp": {
			"default": "res://assets/characters/portraits/huwag_bfp_neutral.png",
			"neutral": "res://assets/characters/portraits/huwag_bfp_neutral.png",
			"worried": "res://assets/characters/portraits/huwag_bfp_worried.png",
			"tired": "res://assets/characters/portraits/huwag_bfp_tired.png",
			"surprised": "res://assets/characters/portraits/huwag_bfp_surprised.png",
			"angry": "res://assets/characters/portraits/huwag_bfp_angry.png",
			"determined": "res://assets/characters/portraits/huwag_bfp_angry.png",
			"scared": "res://assets/characters/portraits/huwag_bfp_scared.png",
			"uneasy_smile": "res://assets/characters/portraits/huwag_bfp_uneasy_smile.png",
			"smile": "res://assets/characters/portraits/huwag_bfp_uneasy_smile.png",
			"unfiltered": "res://assets/characters/portraits/huwag_bfp_unfiltered.png"
		}
	},
	"cap_reyes": {
		"display_name": "Capitão Reyes",
		"role_subtitle": "Comandante · Agdangan Fire Station",
		"accent_color": Color("#F5CB5C"),
		"is_placeholder": true,
		"portraits": {
			"default": "res://assets/characters/portraits/placeholder_cap_reyes.png"
		}
	},
	"ato": {
		"display_name": "Bombeiro Ato",
		"role_subtitle": "Equipe do Quartel (BFP)",
		"accent_color": Color("#4ECDC4"),
		"is_placeholder": true,
		"portraits": {
			"default": "res://assets/characters/portraits/placeholder_station_staff.png"
		}
	},
	"santos": {
		"display_name": "Bombeiro Santos",
		"role_subtitle": "Equipe do Quartel (BFP)",
		"accent_color": Color("#4ECDC4"),
		"is_placeholder": true,
		"portraits": {
			"default": "res://assets/characters/portraits/placeholder_station_staff.png"
		}
	},
	"enfermeira_maria": {
		"display_name": "Enfermeira Maria",
		"role_subtitle": "Saúde Ocupacional (BFP)",
		"accent_color": Color("#90E0EF"),
		"is_placeholder": true,
		"portraits": {
			"default": "res://assets/characters/portraits/placeholder_station_staff.png"
		}
	},
	"senhora_luningning": {
		"display_name": "Senhora Luningning",
		"role_subtitle": "Moradora de Agdangan",
		"accent_color": Color("#C77DFF"),
		"is_placeholder": true,
		"portraits": {
			"default": "res://assets/characters/portraits/placeholder_npc_barangay.png"
		}
	},
	"aling_nena": {
		"display_name": "Aling Nena",
		"role_subtitle": "Sari-Sari Store",
		"accent_color": Color("#4ECDC4"),
		"is_placeholder": true,
		"portraits": {
			"default": "res://assets/characters/portraits/placeholder_npc_barangay.png"
		}
	},
	"kuya_ben": {
		"display_name": "Kuya Ben",
		"role_subtitle": "Motorista de Jeepney",
		"accent_color": Color("#FFCA3A"),
		"is_placeholder": true,
		"portraits": {
			"default": "res://assets/characters/portraits/placeholder_npc_barangay.png"
		}
	},
	"feirante": {
		"display_name": "Feirante do Barangay",
		"role_subtitle": "Feirinha ao lado do Quartel",
		"accent_color": Color("#8AC926"),
		"is_placeholder": true,
		"portraits": {
			"default": "res://assets/characters/portraits/placeholder_npc_barangay.png"
		}
	},
	"lola_rosa": {
		"display_name": "Lola Rosa",
		"role_subtitle": "Vizinha",
		"accent_color": Color("#C77DFF"),
		"is_placeholder": true,
		"portraits": {
			"default": "res://assets/characters/portraits/placeholder_npc_barangay.png"
		}
	},
	"toby": {
		"display_name": "Toby",
		"role_subtitle": "Criança da Rua",
		"accent_color": Color("#4ECDC4"),
		"is_placeholder": true,
		"portraits": {
			"default": "res://assets/characters/portraits/placeholder_npc_barangay.png"
		}
	},
	"criatura_lagoa": {
		"display_name": "Criatura da Lagoa",
		"role_subtitle": "Clareira da Floresta",
		"accent_color": Color("#48CAE4"),
		"is_placeholder": true,
		"portraits": {
			"default": "res://assets/characters/portraits/placeholder_creature.png"
		}
	}
}

static func resolve_speaker_id(raw_speaker: String) -> String:
	var s := raw_speaker.strip_edges().to_lower()
	if s.is_empty() or s.begins_with("huwag"):
		return "huwag"
	if s.find("reyes") != -1 or s.find("capit") != -1 or s.find("chefe") != -1:
		return "cap_reyes"
	if s.find("nena") != -1 or s.find("sari") != -1:
		return "aling_nena"
	if s.find("ben") != -1 or s.find("jeepney") != -1:
		return "kuya_ben"
	if s.find("feirante") != -1 or s.find("feirinha") != -1:
		return "feirante"
	if s.find("rosa") != -1:
		return "lola_rosa"
	if s.find("toby") != -1:
		return "toby"
	if s.find("luningning") != -1 or s.find("senhora") != -1 or s.find("velhinha") != -1:
		return "senhora_luningning"
	if s == "ato" or s.find("bombeiro ato") != -1:
		return "ato"
	if s.find("santos") != -1:
		return "santos"
	if s.find("maria") != -1 or s.find("enfermeira") != -1:
		return "enfermeira_maria"
	if s.find("criatura") != -1 or s.find("monstro") != -1:
		return "criatura_lagoa"
	return "aling_nena"

static func get_profile_data(raw_speaker: String, expression: String = "default", is_act3: bool = false, outfit_id: String = "casual") -> Dictionary:
	var speaker_id := resolve_speaker_id(raw_speaker)
	var base: Dictionary = PROFILES.get(speaker_id, PROFILES["huwag"])
	var portraits: Dictionary = base.get("portraits", {})
	if speaker_id == "huwag" and outfit_id == "bfp" and base.has("portraits_bfp"):
		portraits = base.get("portraits_bfp", portraits)

	var chosen_expr := expression.strip_edges().to_lower()
	if chosen_expr.is_empty():
		chosen_expr = "default"
	if is_act3 and speaker_id == "huwag" and portraits.has("unfiltered"):
		chosen_expr = "unfiltered"

	var portrait_path: String = str(portraits.get(chosen_expr, portraits.get("default", "res://assets/characters/portraits/huwag_casual_neutral.png")))
	var display_name: String = raw_speaker if not raw_speaker.is_empty() else str(base.get("display_name", "Huwag Matitiis"))
	if display_name == "Huwag":
		display_name = "Huwag Matitiis"

	return {
		"id": speaker_id,
		"display_name": display_name,
		"role_subtitle": str(base.get("role_subtitle", "")),
		"accent_color": base.get("accent_color", Color("#F5CB5C")),
		"is_placeholder": bool(base.get("is_placeholder", false)),
		"portrait_path": portrait_path,
		"expression": chosen_expr
	}

