class_name CharacterProfiles
extends RefCounted

## Banco central de perfis visuais de personagens para a caixa de diálogo de HUWAG.
## Utiliza os retratos 96x96 (Anime Pixel Art / Terror Psicologico) integrados na Etapa 1.

const PROFILES: Dictionary = {
	"huwag": {
		"display_name": "Huwag Matitiis",
		"role": "Bombeiro Voluntário",
		"accent": Color("#F5C84B"),
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
			"unfiltered": "res://assets/characters/portraits/huwag_casual_unfiltered.png",
			"distorted": "res://assets/characters/portraits/huwag_casual_distorted.png"
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
			"unfiltered": "res://assets/characters/portraits/huwag_bfp_unfiltered.png",
			"distorted": "res://assets/characters/portraits/huwag_bfp_distorted.png"
		}
	},
	"cap_reyes": {
		"display_name": "Capitão Reyes",
		"role": "Comandante da BFP Agdangan",
		"accent": Color("#F5C445"),
		"is_placeholder": false,
		"portraits": {
			"default": "res://assets/characters/portraits/fnaf_cap_reyes.png",
			"distorted": "res://assets/characters/portraits/fnaf_distorted_cap_reyes.png"
		}
	},
	"bombeiro_ato": {
		"display_name": "Bombeiro Ato",
		"role": "Equipe de Resgate BFP",
		"accent": Color("#FF9E44"),
		"is_placeholder": false,
		"portraits": {
			"default": "res://assets/characters/portraits/fnaf_bombeiro_ato.png",
			"distorted": "res://assets/characters/portraits/fnaf_distorted_bombeiro_ato.png"
		}
	},
	"bombeiro_santos": {
		"display_name": "Bombeiro Santos",
		"role": "Combatente BFP",
		"accent": Color("#64D2FF"),
		"is_placeholder": false,
		"portraits": {
			"default": "res://assets/characters/portraits/fnaf_bombeiro_santos.png",
			"distorted": "res://assets/characters/portraits/fnaf_distorted_bombeiro_santos.png"
		}
	},
	"enfermeira_maria": {
		"display_name": "Enfermeira Maria",
		"role": "Posto Clínico de Agdangan",
		"accent": Color("#70E0D0"),
		"is_placeholder": false,
		"portraits": {
			"default": "res://assets/characters/portraits/fnaf_enfermeira_maria.png",
			"distorted": "res://assets/characters/portraits/fnaf_distorted_enfermeira_maria.png"
		}
	},
	"senhora_luningning": {
		"display_name": "Senhora Luningning",
		"role": "Moradora de Agdangan",
		"accent": Color("#C792EA"),
		"is_placeholder": false,
		"portraits": {
			"default": "res://assets/characters/portraits/fnaf_luningning.png",
			"distorted": "res://assets/characters/portraits/fnaf_distorted_luningning.png"
		}
	},
	"aling_nena": {
		"display_name": "Aling Nena",
		"role": "Dona da Sari-Sari",
		"accent": Color("#F48FB1"),
		"is_placeholder": false,
		"portraits": {
			"default": "res://assets/characters/portraits/fnaf_aling_nena.png",
			"distorted": "res://assets/characters/portraits/fnaf_distorted_aling_nena.png"
		}
	},
	"kuya_ben": {
		"display_name": "Kuya Ben",
		"role": "Motorista de Jeepney",
		"accent": Color("#F2C94C"),
		"is_placeholder": false,
		"portraits": {
			"default": "res://assets/characters/portraits/fnaf_kuya_ben.png",
			"distorted": "res://assets/characters/portraits/fnaf_distorted_kuya_ben.png"
		}
	},
	"feirante": {
		"display_name": "Mang Tomas",
		"role": "Feirante do Barangay",
		"accent": Color("#9CCC65"),
		"is_placeholder": false,
		"portraits": {
			"default": "res://assets/characters/portraits/fnaf_feirante.png",
			"distorted": "res://assets/characters/portraits/fnaf_distorted_feirante.png"
		}
	},
	"mang_carding": {
		"display_name": "Mang Carding",
		"role": "Pescador do Píer",
		"accent": Color("#56CCF2"),
		"is_placeholder": false,
		"portraits": {
			"default": "res://assets/characters/portraits/fnaf_mang_carding.png",
			"distorted": "res://assets/characters/portraits/fnaf_distorted_mang_carding.png"
		}
	},
	"lola_rosa": {
		"display_name": "Lola Rosa",
		"role": "Anciã Erborista",
		"accent": Color("#B8A4E6"),
		"is_placeholder": false,
		"portraits": {
			"default": "res://assets/characters/portraits/fnaf_lola_rosa.png",
			"distorted": "res://assets/characters/portraits/fnaf_distorted_lola_rosa.png"
		}
	},
	"toby": {
		"display_name": "Toby",
		"role": "Criança do Barangay",
		"accent": Color("#8CE99A"),
		"is_placeholder": false,
		"portraits": {
			"default": "res://assets/characters/portraits/fnaf_toby.png",
			"distorted": "res://assets/characters/portraits/fnaf_distorted_toby.png"
		}
	},
	"criatura_lagoa": {
		"display_name": "Guardiã da Lagoa",
		"role": "Espírito das Águas",
		"accent": Color("#56D4C8"),
		"is_placeholder": false,
		"portraits": {
			"default": "res://assets/characters/portraits/fnaf_criatura_lagoa.png",
			"distorted": "res://assets/characters/portraits/fnaf_distorted_criatura_lagoa.png"
		}
	},
	"vulto_bosque": {
		"display_name": "Vulto Calcinado",
		"role": "Eco da Brigada na Fumaça",
		"accent": Color("#E63946"),
		"is_placeholder": false,
		"portraits": {
			"default": "res://assets/characters/portraits/fnaf_vulto_bosque.png",
			"distorted": "res://assets/characters/portraits/fnaf_distorted_vulto_bosque.png"
		}
	},
	"santelmo": {
		"display_name": "Santelmo",
		"role": "Fogo-Fátuo da Mata",
		"accent": Color("#FF7B29"),
		"is_placeholder": false,
		"portraits": {
			"default": "res://assets/characters/portraits/fnaf_santelmo.png",
			"distorted": "res://assets/characters/portraits/fnaf_distorted_santelmo.png"
		}
	},
	"vhs_radio": {
		"display_name": "Rádio BFP / Fita VHS",
		"role": "Transmissão & Registro de Chamada",
		"accent": Color("#7BC4D4"),
		"is_placeholder": false,
		"portraits": {
			"default": "res://assets/characters/portraits/fnaf_vhs_radio.png",
			"distorted": "res://assets/characters/portraits/fnaf_distorted_vhs_radio.png"
		}
	}
}


static func resolve_speaker_id(raw_speaker: String) -> String:
	var s := raw_speaker.strip_edges().to_lower()
	if s.is_empty():
		return "huwag"
	# Identificadores específicos antes de prefixos genéricos (como "bombeiro" ou "memória")
	if "reyes" in s or "cap." in s or "capit" in s:
		return "cap_reyes"
	if "ato" in s:
		return "bombeiro_ato"
	if "santos" in s:
		return "bombeiro_santos"
	if "maria" in s or "enferm" in s:
		return "enfermeira_maria"
	if "luningning" in s or "velhinha" in s:
		return "senhora_luningning"
	if "nena" in s:
		return "aling_nena"
	if "ben" in s:
		return "kuya_ben"
	if "tomas" in s or "feirante" in s or "barangay" in s:
		return "feirante"
	if "carding" in s or "pescador" in s:
		return "mang_carding"
	if "rosa" in s or "lola" in s:
		return "lola_rosa"
	if "toby" in s:
		return "toby"
	if "lagoa" in s or "criatura" in s or "guardi" in s:
		return "criatura_lagoa"
	if "santelmo" in s or "espirito" in s or "espírito" in s:
		return "santelmo"
	if "vulto" in s or "calcinado" in s or "sombra" in s:
		return "vulto_bosque"
	if "radio" in s or "rádio" in s or "vhs" in s or "voz do passado" in s or "revelação" in s or "sistema" in s:
		return "vhs_radio"
	if "huwag" in s or "matitiis" in s:
		return "huwag"
	if "bombeiro" in s:
		return "bombeiro_ato"
	return "huwag"


static func get_profile_data(raw_speaker: String, expression: String = "default", is_act3: bool = false, outfit_id: String = "casual") -> Dictionary:
	var speaker_id := resolve_speaker_id(raw_speaker)
	var base: Dictionary = PROFILES.get(speaker_id, PROFILES["huwag"])
	var portraits: Dictionary = base.get("portraits", {})
	if speaker_id == "huwag" and outfit_id == "bfp" and base.has("portraits_bfp"):
		portraits = base.get("portraits_bfp", portraits)

	var chosen_expr := expression.strip_edges().to_lower()
	if chosen_expr.is_empty():
		chosen_expr = "default"
	if is_act3 and speaker_id == "huwag" and chosen_expr in ["default", "neutral", "determined", "uneasy_smile", "smile"]:
		chosen_expr = "unfiltered"
	if not portraits.has(chosen_expr):
		chosen_expr = "default"

	var portrait_path: String = str(portraits.get(chosen_expr, portraits.get("default", "res://assets/characters/portraits/huwag_casual_neutral.png")))
	var is_dist := (chosen_expr == "distorted")
	return {
		"id": speaker_id,
		"display_name": str(base.get("display_name", raw_speaker)),
		"role_subtitle": str(base.get("role", "")),
		"accent_color": base.get("accent", Color("#F5C84B")) if not is_dist else Color("#D4C8FF"),
		"is_placeholder": bool(base.get("is_placeholder", false)),
		"is_distorted": is_dist,
		"portrait_path": portrait_path,
		"expression": chosen_expr
	}
