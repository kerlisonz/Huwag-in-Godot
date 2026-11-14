extends SceneTree

## Suíte abrangente para validar toda a reestruturação visual, narrativa e jogável de Huwag:
## - 4 ambientes reconstruídos (Quarto, Quartel BFP multi-ala, Rua 2880x560, Floresta 2560x768 + Clareira 960x576)
## - Escolha de dose de pílulas no Ato 2 e transformação normal <-> distorcida
## - Diálogos com conflict_choices -> turn_hostile() -> combate até derrota
## - Pontes/atalhos/dificuldade escalonada da Floresta + progressão Ato 2 -> Ato 3 + Save/Load

func _init() -> void:
	call_deferred("_run_all")


func _ensure_autoloads() -> Node:
	if not root.has_node("AudioManager"):
		var am := Node.new()
		am.set_script(load("res://scripts/autoload/audio_manager.gd"))
		am.name = "AudioManager"
		root.add_child(am)
	if not root.has_node("GameState"):
		var gs := Node.new()
		gs.set_script(load("res://scripts/autoload/game_state.gd"))
		gs.name = "GameState"
		root.add_child(gs)
	return root.get_node("GameState")


func _assert_ok(cond: bool, msg: String) -> void:
	if not cond:
		push_error("[FAIL] " + msg)
		printerr("[FAIL] " + msg)
		quit(1)


func _run_all() -> void:
	print("==================================================================")
	print("=== TESTE ABRANGENTE DE REESTRUTURAÇÃO — HUWAG (ATOS 1–3) ===")
	print("==================================================================")

	var gs := _ensure_autoloads()
	gs.reset_to_new_game()
	await process_frame

	# ------------------------------------------------------------------
	# 1. VERIFICAR INSTANCIAÇÃO DOS 4 AMBIENTES + WRAPPERS DE FLORESTA
	# ------------------------------------------------------------------
	print("\n--- 1. Validando instanciação e estrutura das cenas reconstruídas ---")
	var room_sc: PackedScene = load("res://scenes/levels/RoomHuwag.tscn")
	var station_sc: PackedScene = load("res://scenes/levels/FireStation.tscn")
	var street_sc: PackedScene = load("res://scenes/levels/StreetPreview.tscn")
	var trail_sc: PackedScene = load("res://scenes/levels/forest_trail.tscn")
	var corridor_sc: PackedScene = load("res://scenes/levels/ForestCorridor.tscn")
	var clearing_sc: PackedScene = load("res://scenes/levels/forest_clearing.tscn")
	var clearing_wrap_sc: PackedScene = load("res://scenes/levels/ForestClearing.tscn")
	_assert_ok(room_sc != null and station_sc != null and street_sc != null, "Cenas urbanas carregam")
	_assert_ok(trail_sc != null and corridor_sc != null and clearing_sc != null and clearing_wrap_sc != null, "Cenas da floresta carregam")

	# Quarto Normal vs Dose Maior
	gs.advance_to_act_2()
	gs.set_higher_dose(false)
	var room := room_sc.instantiate()
	root.add_child(room)
	await process_frame
	_assert_ok(room.get_node("FloorNormal").visible == true and room.get_node("FloorDistorted").visible == false, "Quarto inicia em modo normal")
	gs.set_higher_dose(true)
	await process_frame
	_assert_ok(room.get_node("FloorNormal").visible == false and room.get_node("FloorDistorted").visible == true, "Quarto alterna para tilemap distorcido na Dose Maior")
	room.queue_free()
	await process_frame
	print("[PASS] RoomHuwag alterna normal <-> distorcido com fidelidade.")

	# ------------------------------------------------------------------
	# 2. QUARTEL BFP MULTI-ALA + NPCs + CONFLITO HOSTIL
	# ------------------------------------------------------------------
	print("\n--- 2. Validando FireStation (alas, bombeiros distorcidos e combate hostil) ---")
	var station := station_sc.instantiate()
	root.add_child(station)
	await process_frame
	_assert_ok(station.get_node("FloorNormal").visible == false and station.get_node("FloorDistorted").visible == true, "FireStation inicia distorcida quando Dose Maior está ativa")
	for npc_id in ["Cap_Reyes", "Bombeiro_Ato", "Bombeiro_Santos", "Enfermeira_Maria", "Velhinha_Espera"]:
		_assert_ok(station._npcs.has(npc_id) and station._npcs[npc_id] != null, "NPC %s presente no Quartel" % npc_id)
	var ato_npc: NpcEntity = station._npcs["Bombeiro_Ato"]
	_assert_ok(ato_npc.is_distorted == true, "Bombeiro_Ato em sprite distorcido sob Dose Maior")

	# Dispara escolha de conflito e derrota NPC hostil via dano físico + água
	station._on_dialogue_conflict_triggered("Bombeiro_Ato", {})
	await process_frame
	_assert_ok(ato_npc.is_hostile == true, "Conflito de diálogo torna Bombeiro_Ato hostil")
	var defeat_flag := {"done": false}
	ato_npc.entity_defeated.connect(func(_id: String) -> void: defeat_flag["done"] = true)
	ato_npc.receive_melee_hit(40, station.player.global_position)
	ato_npc.receive_water_hit(45, station.player.global_position)
	await process_frame
	_assert_ok(defeat_flag["done"] and ato_npc.is_defeated, "Combate existente derrota NPC hostil no Quartel")
	station.queue_free()
	await process_frame
	print("[PASS] FireStation: multi-ala, NPCs bombeiros e conflito hostil validados.")

	# ------------------------------------------------------------------
	# 3. RUA ESTENDIDA (2880x560) + MORADORES + CONFLITO DE DIÁLOGO
	# ------------------------------------------------------------------
	print("\n--- 3. Validando StreetPreview (rua estendida, leste e hostilidade) ---")
	var street := street_sc.instantiate()
	root.add_child(street)
	await process_frame
	_assert_ok(street.MAP_BOUNDS.size.x >= 2880, "Rua estendida possui largura >= 2880px")
	_assert_ok(street.get_node("TownGroundDistorted").visible == true, "Rua reflete Dose Maior")
	for s_npc in ["NPC_Aling_Nena", "NPC_Bombeiro_Ronda", "NPC_Kuya_Ben", "NPC_Toby", "NPC_Feirante", "NPC_Vigilia_Leste"]:
		_assert_ok(street._npcs.has(s_npc) and street._npcs[s_npc] != null, "NPC urbano %s presente" % s_npc)
	var east_npc: NpcEntity = street._npcs["NPC_Vigilia_Leste"]
	_assert_ok(east_npc.global_position.x > 2400.0, "Bloco leste estendido povoado com NPC em x > 2400")
	street._on_dialogue_conflict_triggered("NPC_Aling_Nena", {})
	await process_frame
	_assert_ok(street._npcs["NPC_Aling_Nena"].is_hostile == true, "NPC_Aling_Nena reage à escolha errada ficando hostil")
	street.queue_free()
	await process_frame
	print("[PASS] StreetPreview estendida e conflitos urbanos validados.")

	# ------------------------------------------------------------------
	# 4. FLORESTA LONGA (2560x768): CURVAS, PONTES, PICKUPS, 13 SANTELMOS
	# ------------------------------------------------------------------
	print("\n--- 4. Validando ForestTrail (13 inimigos escalonados, pontes e perseguição distorcida) ---")
	var trail := trail_sc.instantiate()
	root.add_child(trail)
	await process_frame
	_assert_ok(trail._santelmos.size() == 13, "Floresta possui 13 Santelmos (encontrado %d)" % trail._santelmos.size())
	var s1: SantelmoEnemy = trail.get_node("ObstaclesYsort/Santelmo1")
	var s13: SantelmoEnemy = trail.get_node("ObstaclesYsort/Santelmo13")
	_assert_ok(s1.max_health == 60 and s13.max_health >= 130, "Dificuldade crescente validada (S1=%d HP, S13=%d HP)" % [s1.max_health, s13.max_health])
	_assert_ok(s13.chase_speed > s1.chase_speed and s13.attack_damage > s1.attack_damage, "Velocidade e dano crescem até o portão da lagoa")

	# Valida pontes de madeira sobre o riacho vs água profunda adjacente
	var walls: TileMapLayer = trail.get_node("WallsNormal")
	_assert_ok(walls.get_cell_source_id(Vector2i(52, 36)) == -1, "Ponte oeste sobre o riacho livre para passagem")
	_assert_ok(walls.get_cell_source_id(Vector2i(68, 36)) == -1, "Ponte leste sobre o riacho livre para passagem")
	_assert_ok(walls.get_cell_source_id(Vector2i(52, 31)) != -1, "Água profunda do riacho bloqueia passagem fora da ponte")

	# Valida Vulto Calcinado exclusivo da Dose Maior
	_assert_ok(trail._stalker_npc != null and trail._stalker_npc.visible == true, "Vulto da floresta aparece na Dose Maior")
	trail._on_dialogue_conflict_triggered("NPC_Vulto_Bosque", {})
	await process_frame
	_assert_ok(trail._stalker_npc.is_hostile == true, "Vulto da floresta torna-se hostil ao negar confronto")

	trail.queue_free()
	await process_frame
	var corr := corridor_sc.instantiate()
	root.add_child(corr)
	await process_frame
	_assert_ok(corr.get_node_or_null("ObstaclesYsort/Santelmo13") != null, "ForestCorridor wrapper íntegro")
	corr.queue_free()
	await process_frame
	print("[PASS] ForestTrail extensa, pontes, 13 Santelmos e stalker distorcido validados.")

	# ------------------------------------------------------------------
	# 5. PROGRESSÃO ATO 2 -> ATO 3 + SAVE/LOAD DA DOSE MAIOR
	# ------------------------------------------------------------------
	print("\n--- 5. Validando Persistência Save/Load (Dose Maior) e Ato 3 Sem Filtro ---")
	_assert_ok(gs.save_game() == true, "Salva estado em Dose Maior do Ato 2")
	gs.set_higher_dose(false)
	_assert_ok(gs.is_higher_dose() == false, "Reset temporário de higher_dose")
	_assert_ok(gs.load_game() == true and gs.is_higher_dose() == true, "load_game() restaura estado is_higher_dose()")

	gs.advance_to_act_3()
	var trail_act3 := trail_sc.instantiate()
	root.add_child(trail_act3)
	await process_frame
	_assert_ok(trail_act3.get_node("ObstaclesYsort/Santelmo1").visible == false, "Ato 3 sem filtro oculta espíritos de fogo na trilha")
	trail_act3.queue_free()
	await process_frame

	var clearing_act3 := clearing_sc.instantiate()
	root.add_child(clearing_act3)
	await process_frame
	_assert_ok(clearing_act3.get_node("ObstaclesYsort/AquaticCreature").visible == false, "Ato 3 oculta Guardiã aquática na lagoa")
	_assert_ok(clearing_act3.get_node_or_null("PondMirrorInteractable") != null, "Espelho real da lagoa disponível no Ato 3")
	clearing_act3.queue_free()
	await process_frame

	var clr_wrap := clearing_wrap_sc.instantiate()
	root.add_child(clr_wrap)
	await process_frame
	_assert_ok(clr_wrap.get_node_or_null("PondWaterBody") != null, "ForestClearing wrapper íntegro")
	clr_wrap.queue_free()
	await process_frame

	print("\n==================================================================")
	print("=== TODOS OS TESTES ABRANGENTES PASSARAM 100%! ===")
	print("==================================================================")
	quit(0)
