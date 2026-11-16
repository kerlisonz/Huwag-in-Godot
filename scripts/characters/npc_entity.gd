class_name NpcEntity
extends CharacterBody2D

## Entidade de NPC animada para sheets 480x192 (10x4 células de 48x48).
## Suporta:
## - Estado normal vs Estado distorcido (Ato 2: shader glitch/esticamento/carmesim + spritesheet distorcido)
## - Escalonamento pacífico -> inimigo agressivo via turn_hostile() ou intoxicação severa
## - Interação delegada ao nível via Area2D InteractArea (layer 4)
## - Integração segura com combate do Player (query_melee_hit / query_water_hit / apply_hit).

signal npc_interacted(npc_id: String)
signal entity_defeated(npc_id: String)

const NPC_DISTORTION_SHADER: Shader = preload("res://shaders/npc_distortion.gdshader")

@export var npc_id: String = ""
@export var interact_verb: String = "Conversar"
@export var interact_prompt: String = "Pessoa"
@export_file("*.png") var normal_sheet_path: String = ""
@export_file("*.png") var distorted_sheet_path: String = ""
@export_file("*.tres") var normal_frames_path: String = ""
@export_file("*.tres") var distorted_frames_path: String = ""
@export var facing_dir: String = "down" ## down, left, right, up
@export var patrol_points: Array[Vector2] = []
@export var patrol_speed: float = 28.0
@export var patrol_pause: float = 2.0

# Configurações de Distorção e Combate do Ato 2
@export var can_be_distorted: bool = true
@export var auto_aggro_on_higher_dose: bool = false
@export var aggressive_on_overdose: bool = true
@export var aggro_radius: float = 54.0
@export var hostile_max_hp: int = 75
@export var hostile_move_speed: float = 78.0
@export var hostile_attack_damage: int = 16
@export var hostile_attack_range: float = 28.0
@export var hostile_attack_cooldown: float = 1.05
@export var hostile_water_weakness: bool = false

var is_distorted: bool = false
var is_hostile: bool = false
var is_defeated: bool = false
var target_player: Node2D = null

var _hp: int = 75
var _normal_tex: Texture2D = null
var _distorted_tex: Texture2D = null
var _normal_sf: SpriteFrames = null
var _distorted_sf: SpriteFrames = null
var _using_spriteframes: bool = false
var _distortion_material: ShaderMaterial = null
var _anim_timer: float = 0.0
var _attack_timer: float = 0.0
var _attack_anim_timer: float = 0.0
var _hurt_anim_timer: float = 0.0
var _talk_anim_timer: float = 0.0
var _death_playing: bool = false
var _hit_flash_timer: float = 0.0
var _knockback_vel: Vector2 = Vector2.ZERO
var _patrol_index: int = 0
var _patrol_wait: float = 0.0
var _twitch_timer: float = 0.0
var _facing_row: int = 0
var _warned_missing_player: bool = false

@onready var sprite: Sprite2D = $Sprite2D
@onready var anim_sprite: AnimatedSprite2D = get_node_or_null("AnimatedSprite") as AnimatedSprite2D
@onready var shadow: Polygon2D = $Shadow
@onready var body_col: CollisionShape2D = $CollisionShape2D
@onready var interact_area: Area2D = $InteractArea
@onready var interact_shape: CollisionShape2D = $InteractArea/CollisionShape2D


func _ready() -> void:
	z_index = 2
	y_sort_enabled = false
	collision_layer = 1 # Bloqueia movimento do jogador enquanto sólido
	collision_mask = 1

	_hp = hostile_max_hp
	if interact_area is Interactable:
		var ia := interact_area as Interactable
		ia.interaction_id = npc_id
		ia.verb = interact_verb
		ia.title = interact_prompt
		ia.collision_layer = 4
		ia.collision_mask = 2
		if not ia.interacted.is_connected(_on_area_interacted):
			ia.interacted.connect(_on_area_interacted)

	_ensure_distortion_material()
	_load_textures()
	_set_facing_from_name(facing_dir)

	var gs := _get_game_state()
	if gs != null:
		if gs.has_signal("variable_changed") and not gs.variable_changed.is_connected(_on_game_variable_changed):
			gs.variable_changed.connect(_on_game_variable_changed)
		if can_be_distorted and gs.has_method("get_intoxication_level") and int(gs.call("get_intoxication_level")) >= 2:
			is_distorted = true

	refresh_visual_state()


func _ensure_distortion_material() -> void:
	if _distortion_material == null:
		_distortion_material = ShaderMaterial.new()
		_distortion_material.shader = NPC_DISTORTION_SHADER
		var seed_val := fmod(absf(global_position.x * 0.017 + global_position.y * 0.031), 10.0)
		_distortion_material.set_shader_parameter("phase_seed", seed_val)
		_distortion_material.set_shader_parameter("distortion_intensity", 0.0)
		_distortion_material.set_shader_parameter("hostile_boost", 0.0)
	if sprite != null and sprite.material != _distortion_material:
		sprite.material = _distortion_material
	if anim_sprite != null and anim_sprite.material != _distortion_material:
		anim_sprite.material = _distortion_material


func _on_game_variable_changed(var_name: String, value: Variant) -> void:
	if var_name != "Intoxicacao" or is_defeated or not can_be_distorted:
		return
	var tox := int(value)
	var should_distort := tox >= 2
	if should_distort != is_distorted and not is_hostile:
		set_distorted_state(should_distort)


func _on_area_interacted(_ia: Interactable) -> void:
	if not is_inside_tree():
		return
	var p := get_tree().get_first_node_in_group("player")
	_handle_interact(p)


func _load_textures() -> void:
	_normal_sf = _load_spriteframes(normal_frames_path)
	_distorted_sf = _load_spriteframes(distorted_frames_path)
	_normal_tex = _load_png_tex(normal_sheet_path)
	_distorted_tex = _load_png_tex(distorted_sheet_path)


func _load_spriteframes(res_path: String) -> SpriteFrames:
	if res_path.is_empty():
		return null
	if ResourceLoader.exists(res_path):
		var r := ResourceLoader.load(res_path)
		if r is SpriteFrames:
			return r as SpriteFrames
	return null


func _load_png_tex(res_path: String) -> Texture2D:
	if res_path.is_empty():
		return null
	if ResourceLoader.exists(res_path):
		var r := load(res_path)
		if r is Texture2D:
			return r
	var abs_p := ProjectSettings.globalize_path(res_path)
	if FileAccess.file_exists(abs_p):
		var img := Image.load_from_file(abs_p)
		if img != null and not img.is_empty():
			return ImageTexture.create_from_image(img)
	return null


func _exit_tree() -> void:
	target_player = null


func set_distorted_state(distorted: bool) -> void:
	var target_distorted := distorted and can_be_distorted
	var changed := (target_distorted != is_distorted)
	is_distorted = target_distorted
	if not is_distorted and is_hostile:
		is_hostile = false
	if changed:
		print("[NpcEntity][%s] Distorção=%s (Intoxicacao=%d)" % [npc_id, str(is_distorted), _get_intoxication_level()])
	refresh_visual_state()


func refresh_visual_state() -> void:
	if sprite == null and anim_sprite == null:
		return
	_ensure_distortion_material()

	var tox := _get_intoxication_level()
	var active_dist := is_distorted or is_hostile or (can_be_distorted and tox >= 2)
	var sf: SpriteFrames = _distorted_sf if (active_dist and _distorted_sf != null) else _normal_sf
	_using_spriteframes = (anim_sprite != null and sf != null)

	if _using_spriteframes:
		if sprite != null:
			sprite.visible = false
		anim_sprite.visible = true
		anim_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		anim_sprite.offset = Vector2(0.0, -7.0)
		anim_sprite.position = Vector2.ZERO
		if anim_sprite.sprite_frames != sf:
			anim_sprite.sprite_frames = sf
	else:
		if anim_sprite != null:
			anim_sprite.visible = false
		if sprite != null:
			sprite.visible = true
			var tex: Texture2D = _distorted_tex if (active_dist and _distorted_tex != null) else _normal_tex
			if tex != null:
				sprite.texture = tex
				sprite.hframes = 10
				sprite.vframes = 4

	if _distortion_material != null:
		var intensity := 0.88 if is_hostile else (0.58 if active_dist else 0.0)
		var boost := 1.0 if is_hostile else 0.0
		_distortion_material.set_shader_parameter("distortion_intensity", intensity)
		_distortion_material.set_shader_parameter("hostile_boost", boost)

	var target_mod := Color.WHITE
	if is_hostile:
		target_mod = Color(1.0, 0.72, 0.72, 1.0)
	elif active_dist:
		target_mod = Color(0.95, 0.88, 0.90, 1.0)
	if sprite != null:
		sprite.modulate = target_mod
	if anim_sprite != null:
		anim_sprite.modulate = target_mod

	if interact_area is Interactable:
		var ia := interact_area as Interactable
		ia.interaction_id = npc_id
		ia.verb = interact_verb
		ia.title = interact_prompt
		var can_talk := (not is_hostile) and (not is_defeated)
		ia.visible = can_talk
		ia.set_deferred("monitoring", can_talk)
		ia.set_deferred("monitorable", can_talk)

	if is_defeated:
		if not _death_playing:
			visible = false
			set_physics_process(false)
		if body_col != null:
			body_col.set_deferred("disabled", true)
	else:
		set_physics_process(true)
		if body_col != null:
			body_col.set_deferred("disabled", false)
	_update_frame(0.0, false)


func _set_facing_from_name(dir_name: String) -> void:
	match dir_name.to_lower():
		"down": _facing_row = 0
		"left": _facing_row = 1
		"right": _facing_row = 2
		"up": _facing_row = 3
		_: _facing_row = 0


func face_toward(world_pos: Vector2) -> void:
	var diff := world_pos - global_position
	if absf(diff.x) > absf(diff.y):
		_facing_row = 2 if diff.x >= 0.0 else 1
	else:
		_facing_row = 0 if diff.y >= 0.0 else 3
	_update_frame(0.0, false)


func play_action_pulse(duration: float = 0.6) -> void:
	_attack_anim_timer = maxf(_attack_anim_timer, duration)
	_play_one_shot_anim("attack_" + _facing_name(), true)


func _facing_name() -> String:
	match _facing_row:
		1: return "left"
		2: return "right"
		3: return "up"
		_: return "down"


func _play_one_shot_anim(anim_name: String, restart: bool = true) -> void:
	if not _using_spriteframes or anim_sprite == null or anim_sprite.sprite_frames == null:
		return
	if not anim_sprite.sprite_frames.has_animation(anim_name):
		return
	if restart or anim_sprite.animation != anim_name:
		anim_sprite.play(anim_name)
		if restart:
			anim_sprite.frame = 0


func provoke_from_intoxication() -> void:
	if not can_be_distorted or is_defeated or is_hostile:
		return
	turn_hostile()


func turn_hostile() -> void:
	if is_defeated or is_hostile:
		return
	is_hostile = true
	is_distorted = true
	_hp = hostile_max_hp
	_attack_timer = 0.35
	_attack_anim_timer = 0.45
	collision_layer = 4 # Mesmo canal de inimigos
	collision_mask = 3
	add_to_group("combat_target")
	add_to_group("water_target")
	add_to_group("enemies")
	target_player = _find_valid_player()
	if interact_area != null:
		interact_area.visible = false
		interact_area.set_deferred("monitoring", false)
		interact_area.set_deferred("monitorable", false)
	print("[NpcEntity][%s] Transformado em inimigo hostil (HP=%d, Intoxicacao=%d)" % [npc_id, _hp, _get_intoxication_level()])
	refresh_visual_state()


func _handle_interact(player: Node) -> void:
	if is_hostile or is_defeated:
		return
	if player is Node2D and is_instance_valid(player):
		face_toward((player as Node2D).global_position)
	_talk_anim_timer = 1.6
	npc_interacted.emit(npc_id)


func _physics_process(delta: float) -> void:
	if not is_inside_tree():
		return
	if is_defeated:
		if _death_playing:
			_update_death_anim()
		return

	if _hurt_anim_timer > 0.0:
		_hurt_anim_timer = maxf(0.0, _hurt_anim_timer - delta)
	if _talk_anim_timer > 0.0:
		_talk_anim_timer = maxf(0.0, _talk_anim_timer - delta)

	var mod_col := Color.WHITE
	if _hit_flash_timer > 0.0:
		_hit_flash_timer -= delta
		mod_col = Color(1.6, 0.35, 0.35, 1.0)
	elif is_hostile:
		mod_col = Color(1.0, 0.72, 0.72, 1.0)
	elif is_distorted:
		mod_col = Color(0.95, 0.88, 0.90, 1.0)
	if sprite != null:
		sprite.modulate = mod_col
	if anim_sprite != null:
		anim_sprite.modulate = mod_col

	if _attack_anim_timer > 0.0:
		_attack_anim_timer = maxf(0.0, _attack_anim_timer - delta)

	if is_hostile:
		_process_hostile(delta)
	else:
		_process_peaceful(delta)


func _get_game_state() -> Node:
	return get_node_or_null("/root/GameState")


func _get_intoxication_level() -> int:
	var gs := _get_game_state()
	if gs != null and gs.has_method("get_intoxication_level"):
		return int(gs.call("get_intoxication_level"))
	if gs != null and gs.has_method("is_higher_dose") and bool(gs.call("is_higher_dose")):
		return 2
	return 0


func _get_audio_manager() -> Node:
	return get_node_or_null("/root/AudioManager")


func _find_valid_player() -> Node2D:
	if not is_inside_tree() or get_tree() == null:
		return null
	var players := get_tree().get_nodes_in_group("player")
	for p in players:
		if p is Node2D and is_instance_valid(p) and (p as Node).is_inside_tree() and not (p as Node).is_queued_for_deletion():
			return p as Node2D
	return null


func _process_peaceful(delta: float) -> void:
	var gs := _get_game_state()
	var dlg_active := gs != null and bool(gs.get("dialogue_active"))

	if not dlg_active and visible and is_distorted and can_be_distorted:
		var tox := _get_intoxication_level()
		if auto_aggro_on_higher_dose or (aggressive_on_overdose and tox >= 3):
			var p := _find_valid_player()
			if p != null and global_position.distance_to(p.global_position) <= aggro_radius:
				turn_hostile()
				return

	if dlg_active or patrol_points.is_empty():
		velocity = Vector2.ZERO
		var twitch := false
		if is_distorted:
			_twitch_timer += delta
			twitch = fmod(_twitch_timer, 3.2) > 2.9
		_update_frame(delta, twitch)
		return

	if _patrol_wait > 0.0:
		_patrol_wait -= delta
		velocity = Vector2.ZERO
		_update_frame(delta, false)
		return

	var target: Vector2 = patrol_points[_patrol_index]
	var to_target := target - global_position
	if to_target.length() <= 6.0:
		_patrol_index = (_patrol_index + 1) % patrol_points.size()
		_patrol_wait = patrol_pause
		velocity = Vector2.ZERO
		_update_frame(delta, false)
		return

	var dir := to_target.normalized()
	_set_facing_from_vec(dir)
	velocity = dir * patrol_speed
	move_and_slide()
	_update_frame(delta, false)


func _process_hostile(delta: float) -> void:
	if _attack_timer > 0.0:
		_attack_timer -= delta

	if not is_instance_valid(target_player) or not target_player.is_inside_tree() or target_player.is_queued_for_deletion():
		target_player = _find_valid_player()

	var chase_vel := Vector2.ZERO
	var gs := _get_game_state()
	var dlg_active := gs != null and bool(gs.get("dialogue_active"))

	if target_player == null:
		if not _warned_missing_player:
			_warned_missing_player = true
			print("[NpcEntity][%s] Aviso: Player nulo ou fora da árvore; ataque cancelado com segurança." % npc_id)
	elif not dlg_active:
		_warned_missing_player = false
		var diff := target_player.global_position - global_position
		var dist := diff.length()
		if dist > 4.0:
			var dir := diff / dist
			_set_facing_from_vec(dir)
			chase_vel = dir * hostile_move_speed
		if dist <= hostile_attack_range and _attack_timer <= 0.0:
			_attack_timer = hostile_attack_cooldown
			_attack_anim_timer = 0.45
			_play_one_shot_anim("attack_" + _facing_name(), true)
			_deliver_attack_to_player(target_player, dist)

	_knockback_vel = _knockback_vel.move_toward(Vector2.ZERO, 420.0 * delta)
	velocity = chase_vel + _knockback_vel
	move_and_slide()
	_update_frame(delta, false)


func _deliver_attack_to_player(player_node: Node2D, dist: float) -> void:
	if not is_instance_valid(player_node) or player_node.is_queued_for_deletion() or not player_node.is_inside_tree():
		print("[NpcEntity][%s] Abortou ataque: referência do Player inválida." % npc_id)
		return
	if player_node.has_method("apply_hit"):
		print("[NpcEntity][%s] Atacou Player via apply_hit (dano=%d, dist=%.1f)" % [npc_id, hostile_attack_damage, dist])
		player_node.call("apply_hit", hostile_attack_damage, global_position)
	elif player_node.has_method("take_damage"):
		print("[NpcEntity][%s] Atacou Player via take_damage (dano=%d, dist=%.1f)" % [npc_id, hostile_attack_damage, dist])
		player_node.call("take_damage", hostile_attack_damage, global_position)
	elif player_node.has_method("receive_damage"):
		print("[NpcEntity][%s] Atacou Player via receive_damage (dano=%d, dist=%.1f)" % [npc_id, hostile_attack_damage, dist])
		player_node.call("receive_damage", hostile_attack_damage, global_position)
	else:
		push_warning("[NpcEntity][%s] Player '%s' não implementa função de recepção de dano!" % [npc_id, player_node.name])


func _set_facing_from_vec(dir: Vector2) -> void:
	if absf(dir.x) > absf(dir.y):
		_facing_row = 2 if dir.x >= 0.0 else 1
	elif absf(dir.y) > 0.05:
		_facing_row = 0 if dir.y >= 0.0 else 3


func _update_frame(delta: float, twitch_pose: bool) -> void:
	if is_defeated or _death_playing:
		return
	if _using_spriteframes and anim_sprite != null and anim_sprite.sprite_frames != null:
		var sf := anim_sprite.sprite_frames
		var dir_name := _facing_name()
		var target_anim := "idle_" + dir_name
		if _hurt_anim_timer > 0.0 and sf.has_animation("hurt_" + dir_name):
			target_anim = "hurt_" + dir_name
		elif (_attack_anim_timer > 0.0 or twitch_pose) and sf.has_animation("attack_" + dir_name):
			target_anim = "attack_" + dir_name
		elif velocity.length_squared() > 9.0 and sf.has_animation("walk_" + dir_name):
			target_anim = "walk_" + dir_name
		elif _talk_anim_timer > 0.0 and sf.has_animation("talk_" + dir_name):
			target_anim = "talk_" + dir_name
		if sf.has_animation(target_anim):
			var switched := (anim_sprite.animation != target_anim)
			if switched:
				var prev_name := String(anim_sprite.animation)
				var prev_prefix := prev_name.get_slice("_", 0)
				var next_prefix := target_anim.get_slice("_", 0)
				var prev_frame := anim_sprite.frame
				var prev_prog := anim_sprite.frame_progress
				anim_sprite.play(target_anim)
				if prev_prefix == next_prefix and sf.get_animation_loop(target_anim):
					var fc := sf.get_frame_count(target_anim)
					if fc > 0:
						anim_sprite.set_frame_and_progress(mini(prev_frame, fc - 1), prev_prog)
			elif sf.get_animation_loop(target_anim) and not anim_sprite.is_playing():
				anim_sprite.play(target_anim)
		return

	if sprite == null or sprite.texture == null:
		return
	_anim_timer += delta
	var col := 0
	if _attack_anim_timer > 0.0 or twitch_pose:
		col = 6 + (int(_anim_timer * 10.0) % 4)
	elif velocity.length_squared() > 9.0:
		col = 2 + (int(_anim_timer * 7.5) % 4)
	else:
		col = int(_anim_timer * 2.2) % 2
	sprite.frame = _facing_row * 10 + col


# === API de combate compatível com PlayerController (retorna Array[Dictionary] e aceita Dictionary ou Array em hit_ids) ===
func query_melee_hit(attacker_pos: Vector2, swing_dir: Vector2, attack_radius: float, attack_arc_degrees: float, damage: int, hit_ids: Variant = null) -> Array[Dictionary]:
	if not is_hostile or is_defeated or not is_inside_tree():
		return []
	var id_int := get_instance_id()
	var id_str := str(id_int)
	if typeof(hit_ids) == TYPE_DICTIONARY:
		var dict_ids := hit_ids as Dictionary
		if dict_ids.has(id_int) or dict_ids.has(id_str):
			return []
	elif typeof(hit_ids) == TYPE_ARRAY:
		var arr_ids := hit_ids as Array
		if id_int in arr_ids or id_str in arr_ids:
			return []

	var to_me := global_position - attacker_pos
	var dist := to_me.length()
	if dist > attack_radius + 14.0:
		return []
	if dist > 6.0 and swing_dir.length_squared() > 0.01:
		var cos_half := cos(deg_to_rad(attack_arc_degrees * 0.5))
		if (to_me / dist).dot(swing_dir.normalized()) < cos_half:
			return []

	if typeof(hit_ids) == TYPE_DICTIONARY:
		var dict_ids := hit_ids as Dictionary
		dict_ids[id_int] = true
		dict_ids[id_str] = true
	elif typeof(hit_ids) == TYPE_ARRAY:
		(hit_ids as Array).append(id_int)

	receive_melee_hit(damage, attacker_pos)
	return [{
		"id": id_str,
		"pos": global_position,
		"damage": damage
	}]


func receive_melee_hit(damage: int, from_pos: Vector2) -> void:
	if not is_hostile or is_defeated:
		return
	print("[NpcEntity][%s] Dano corpo-a-corpo recebido: -%d HP (antes=%d)" % [npc_id, damage, _hp])
	_apply_damage(damage, from_pos, false)


func query_water_hit(attacker_pos: Vector2, aim_dir: Vector2, max_range: float, cone_deg: float, damage: int) -> Array[Dictionary]:
	if not is_hostile or is_defeated or not is_inside_tree():
		return []
	var to_me := global_position - attacker_pos
	var dist := to_me.length()
	if dist > max_range + 12.0:
		return []
	if dist > 6.0 and aim_dir.length_squared() > 0.01:
		var cos_half := cos(deg_to_rad(cone_deg * 0.5))
		if (to_me / dist).dot(aim_dir.normalized()) < cos_half:
			return []
	var final_dmg := damage * 2 if hostile_water_weakness else damage
	receive_water_hit(damage, attacker_pos)
	return [{
		"id": str(get_instance_id()),
		"pos": global_position,
		"label": "-%d" % final_dmg,
		"damage": final_dmg
	}]


func receive_water_hit(damage: int, from_pos: Vector2) -> void:
	if not is_hostile or is_defeated:
		return
	var final_dmg := damage * 2 if hostile_water_weakness else damage
	print("[NpcEntity][%s] Dano de água recebido: -%d HP (antes=%d)" % [npc_id, final_dmg, _hp])
	_apply_damage(final_dmg, from_pos, true)


func _apply_damage(damage: int, from_pos: Vector2, _is_water: bool) -> void:
	_hp = maxi(0, _hp - damage)
	_hit_flash_timer = 0.16
	_hurt_anim_timer = 0.32
	var kb := (global_position - from_pos).normalized()
	_knockback_vel = kb * 175.0
	var am := _get_audio_manager()
	if am != null and am.has_method("play_sfx"):
		am.play_sfx("melee_hit")
	print("[NpcEntity][%s] HP restante: %d/%d" % [npc_id, _hp, hostile_max_hp])
	if _hp <= 0:
		_on_defeated()
	else:
		_play_one_shot_anim("hurt_" + _facing_name(), true)


func _on_defeated() -> void:
	if is_defeated:
		return
	is_defeated = true
	is_hostile = false
	velocity = Vector2.ZERO
	_knockback_vel = Vector2.ZERO
	_attack_anim_timer = 0.0
	_hurt_anim_timer = 0.0
	_talk_anim_timer = 0.0
	remove_from_group("combat_target")
	remove_from_group("water_target")
	remove_from_group("enemies")
	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 0)
	if not npc_id.is_empty():
		var gs := _get_game_state()
		if gs != null and gs.has_method("set_switch"):
			gs.set_switch("hostile_defeated_" + npc_id, true)
	print("[NpcEntity][%s] Inimigo derrotado e desativado com segurança." % npc_id)
	entity_defeated.emit(npc_id)

	var death_anim := "death_" + _facing_name()
	var can_play_death := _using_spriteframes and anim_sprite != null and anim_sprite.sprite_frames != null and anim_sprite.sprite_frames.has_animation(death_anim)
	_death_playing = can_play_death
	refresh_visual_state()
	if can_play_death:
		visible = true
		z_index = 1
		_hit_flash_timer = 0.0
		anim_sprite.modulate = Color(0.88, 0.84, 0.86, 1.0)
		anim_sprite.play(death_anim)
		anim_sprite.frame = 0
		set_physics_process(true)


func _update_death_anim() -> void:
	if not _death_playing:
		return
	if anim_sprite == null or anim_sprite.sprite_frames == null:
		_death_playing = false
		set_physics_process(false)
		return
	var anim_name := String(anim_sprite.animation)
	var fc := anim_sprite.sprite_frames.get_frame_count(anim_name)
	if fc <= 0 or anim_sprite.frame >= fc - 1 or not anim_sprite.is_playing():
		if fc > 0:
			anim_sprite.pause()
			anim_sprite.frame = fc - 1
		_death_playing = false
		set_physics_process(false)
