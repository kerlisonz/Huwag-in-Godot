class_name NpcEntity
extends CharacterBody2D

## Entidade de NPC animada para sheets 480x192 (10x4 células de 48x48).
## Suporta:
## - Estado normal vs Estado distorcido (Ato 2 dose maior de pílulas)
## - Interação delegada ao nível via Area2D interactable (layer 4)
## - Escalonamento hostil via turn_hostile() integrando-se ao combate existente (combat_target/water_target).

signal npc_interacted(npc_id: String)
signal entity_defeated(npc_id: String)

@export var npc_id: String = ""
@export var interact_verb: String = "Conversar"
@export var interact_prompt: String = "Pessoa"
@export_file("*.png") var normal_sheet_path: String = ""
@export_file("*.png") var distorted_sheet_path: String = ""
@export var facing_dir: String = "down" ## down, left, right, up
@export var patrol_points: Array[Vector2] = []
@export var patrol_speed: float = 28.0
@export var patrol_pause: float = 2.0

# Combat settings (activated only when turned hostile in Act 2 Higher Dose)
@export var hostile_max_hp: int = 75
@export var hostile_move_speed: float = 78.0
@export var hostile_attack_damage: int = 16
@export var hostile_attack_cooldown: float = 1.05
@export var hostile_water_weakness: bool = false

var is_distorted: bool = false
var is_hostile: bool = false
var is_defeated: bool = false
var _hp: int = 75
var _normal_tex: Texture2D = null
var _distorted_tex: Texture2D = null
var _anim_timer: float = 0.0
var _attack_timer: float = 0.0
var _attack_anim_timer: float = 0.0
var _hit_flash_timer: float = 0.0
var _knockback_vel: Vector2 = Vector2.ZERO
var _patrol_index: int = 0
var _patrol_wait: float = 0.0
var _twitch_timer: float = 0.0
var _facing_row: int = 0

@onready var sprite: Sprite2D = $Sprite2D
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

	_load_textures()
	_set_facing_from_name(facing_dir)
	refresh_visual_state()


func _on_area_interacted(_ia: Interactable) -> void:
	var p := get_tree().get_first_node_in_group("player")
	_handle_interact(p)


func _load_textures() -> void:
	_normal_tex = _load_png_tex(normal_sheet_path)
	_distorted_tex = _load_png_tex(distorted_sheet_path)


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
	pass


func set_distorted_state(distorted: bool) -> void:
	is_distorted = distorted
	if not is_distorted and is_hostile:
		is_hostile = false
	refresh_visual_state()


func refresh_visual_state() -> void:
	if sprite == null:
		return
	var tex: Texture2D = _distorted_tex if (is_distorted and _distorted_tex != null) else _normal_tex
	if tex != null:
		sprite.texture = tex
		sprite.hframes = 10
		sprite.vframes = 4
	if interact_area is Interactable:
		var ia := interact_area as Interactable
		ia.interaction_id = npc_id
		ia.verb = interact_verb
		ia.title = interact_prompt
		ia.visible = not is_hostile and not is_defeated
		ia.monitoring = not is_hostile and not is_defeated
		ia.monitorable = not is_hostile and not is_defeated
	if is_defeated:
		visible = false
		set_physics_process(false)
		if body_col != null:
			body_col.set_deferred("disabled", true)
	else:
		visible = true
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


func turn_hostile() -> void:
	if is_defeated:
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
	if interact_area != null:
		interact_area.visible = false
		interact_area.set_deferred("monitoring", false)
		interact_area.set_deferred("monitorable", false)
	refresh_visual_state()


func _handle_interact(player: Node) -> void:
	if is_hostile or is_defeated:
		return
	if player is Node2D:
		face_toward((player as Node2D).global_position)
	npc_interacted.emit(npc_id)


func _physics_process(delta: float) -> void:
	if is_defeated:
		return

	if _hit_flash_timer > 0.0:
		_hit_flash_timer -= delta
		sprite.modulate = Color(1.6, 0.35, 0.35, 1.0)
	elif is_distorted:
		sprite.modulate = Color(0.95, 0.90, 0.92, 1.0)
	else:
		sprite.modulate = Color.WHITE

	if _attack_anim_timer > 0.0:
		_attack_anim_timer = maxf(0.0, _attack_anim_timer - delta)

	if is_hostile:
		_process_hostile(delta)
	else:
		_process_peaceful(delta)


func _get_game_state() -> Node:
	return get_node_or_null("/root/GameState")


func _get_audio_manager() -> Node:
	return get_node_or_null("/root/AudioManager")


func _process_peaceful(delta: float) -> void:
	var gs := _get_game_state()
	var dlg_active := gs != null and bool(gs.get("dialogue_active"))
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

	var players := get_tree().get_nodes_in_group("player")
	var target_player: Node2D = null
	if not players.is_empty() and players[0] is Node2D:
		target_player = players[0] as Node2D

	var chase_vel := Vector2.ZERO
	var gs := _get_game_state()
	var dlg_active := gs != null and bool(gs.get("dialogue_active"))
	if target_player != null and not dlg_active:
		var diff := target_player.global_position - global_position
		var dist := diff.length()
		if dist > 4.0:
			var dir := diff / dist
			_set_facing_from_vec(dir)
			chase_vel = dir * hostile_move_speed
		if dist <= 28.0 and _attack_timer <= 0.0:
			_attack_timer = hostile_attack_cooldown
			_attack_anim_timer = 0.45
			if target_player.has_method("apply_hit"):
				target_player.call("apply_hit", hostile_attack_damage, global_position)
			elif target_player.has_method("take_damage"):
				target_player.call("take_damage", hostile_attack_damage, global_position)

	_knockback_vel = _knockback_vel.move_toward(Vector2.ZERO, 420.0 * delta)
	velocity = chase_vel + _knockback_vel
	move_and_slide()
	_update_frame(delta, false)


func _set_facing_from_vec(dir: Vector2) -> void:
	if absf(dir.x) > absf(dir.y):
		_facing_row = 2 if dir.x >= 0.0 else 1
	elif absf(dir.y) > 0.05:
		_facing_row = 0 if dir.y >= 0.0 else 3


func _update_frame(delta: float, twitch_pose: bool) -> void:
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


# === API padrão de combate J-ABS de PlayerController ===
func query_melee_hit(attacker_pos: Vector2, swing_dir: Vector2, attack_radius: float, attack_arc_degrees: float, damage: int, hit_ids: Array) -> bool:
	if not is_hostile or is_defeated:
		return false
	var id := get_instance_id()
	if hit_ids.has(id):
		return false
	var to_me := global_position - attacker_pos
	var dist := to_me.length()
	if dist > attack_radius + 14.0:
		return false
	if dist > 6.0 and swing_dir.length_squared() > 0.01:
		var cos_half := cos(deg_to_rad(attack_arc_degrees * 0.5))
		if (to_me / dist).dot(swing_dir.normalized()) < cos_half:
			return false
	hit_ids.append(id)
	receive_melee_hit(damage, attacker_pos)
	return true


func receive_melee_hit(damage: int, from_pos: Vector2) -> void:
	if not is_hostile or is_defeated:
		return
	_apply_damage(damage, from_pos, false)


func query_water_hit(attacker_pos: Vector2, aim_dir: Vector2, max_range: float, cone_deg: float, damage: int) -> bool:
	if not is_hostile or is_defeated:
		return false
	var to_me := global_position - attacker_pos
	var dist := to_me.length()
	if dist > max_range + 12.0:
		return false
	if dist > 6.0 and aim_dir.length_squared() > 0.01:
		var cos_half := cos(deg_to_rad(cone_deg * 0.5))
		if (to_me / dist).dot(aim_dir.normalized()) < cos_half:
			return false
	receive_water_hit(damage, attacker_pos)
	return true


func receive_water_hit(damage: int, from_pos: Vector2) -> void:
	if not is_hostile or is_defeated:
		return
	var final_dmg := damage * 2 if hostile_water_weakness else damage
	_apply_damage(final_dmg, from_pos, true)


func _apply_damage(damage: int, from_pos: Vector2, _is_water: bool) -> void:
	_hp = maxi(0, _hp - damage)
	_hit_flash_timer = 0.16
	var kb := (global_position - from_pos).normalized()
	_knockback_vel = kb * 175.0
	var am := _get_audio_manager()
	if am != null and am.has_method("play_sfx"):
		am.play_sfx("melee_hit")
	if _hp <= 0:
		_on_defeated()


func _on_defeated() -> void:
	is_defeated = true
	is_hostile = false
	remove_from_group("combat_target")
	remove_from_group("water_target")
	remove_from_group("enemies")
	if not npc_id.is_empty():
		var gs := _get_game_state()
		if gs != null and gs.has_method("set_switch"):
			gs.set_switch("hostile_defeated_" + npc_id, true)
	entity_defeated.emit(npc_id)
	refresh_visual_state()
