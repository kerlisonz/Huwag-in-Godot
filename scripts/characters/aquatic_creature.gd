extends CharacterBody2D
class_name AquaticCreature

signal interaction_requested
signal creature_interacted
signal boss_defeated
signal boss_phase_dialogue_requested(phase_id: String)
signal boss_attack_telegraphed(attack_kind: String, origin: Vector2, target_pos: Vector2)

enum BossState {
	DORMANT = 0,
	IDLE_COMBAT = 1,
	TELEGRAPH_WAVE = 2,
	ATTACK_WAVE = 3,
	TELEGRAPH_LUNGE = 4,
	ATTACK_LUNGE = 5,
	STAGGERED = 6,
	DEFEATED = 7,
}

@export var max_hp: int = 180
@export var current_hp: int = 180
@export var move_speed: float = 60.0
@export var wave_damage: int = 15
@export var lunge_damage: int = 18
@export var wave_radius: float = 62.0
@export var lunge_speed: float = 225.0
@export var hit_radius: float = 28.0

var boss_state: BossState = BossState.DORMANT
var is_hostile: bool = false
var is_defeated: bool = false
var current_phase: int = 1

var _bob_time: float = 0.0
var _state_timer: float = 0.0
var _attack_cooldown: float = 1.15
var _hit_flash_timer: float = 0.0
var _knockback_vel: Vector2 = Vector2.ZERO
var _lunge_dir: Vector2 = Vector2.DOWN
var _lunge_target: Vector2 = Vector2.ZERO
var _attack_cycle: int = 0
var _wave_damage_applied: bool = false
var _lunge_damage_applied: bool = false
var _phase2_triggered: bool = false
var _phase3_triggered: bool = false
var _home_pos: Vector2 = Vector2.ZERO

@onready var sprite: Sprite2D = get_node_or_null("Sprite2D") as Sprite2D
@onready var interact_area: Interactable = (get_node_or_null("CreatureInteractable") if has_node("CreatureInteractable") else get_node_or_null("Interactable")) as Interactable
@onready var aura_light: PointLight2D = get_node_or_null("PointLight2D") as PointLight2D
@onready var aura_particles: CPUParticles2D = get_node_or_null("AuraParticles") as CPUParticles2D
@onready var collision_shape: CollisionShape2D = get_node_or_null("CollisionShape2D") as CollisionShape2D


func _ready() -> void:
	_home_pos = global_position
	current_hp = max_hp
	if interact_area:
		interact_area.interaction_id = "Criatura_Lagoa"
		interact_area.title = "Guardião da Lagoa Azul"
		interact_area.verb = "Aproximar"
		if not interact_area.interacted.is_connected(_on_interacted):
			interact_area.interacted.connect(_on_interacted)


func _is_dialogue_locked() -> bool:
	if has_node("/root/GameState"):
		var gs := get_node("/root/GameState")
		if bool(gs.get("dialogue_active")) or bool(gs.get("sleep_transition_active")):
			return true
	return false


func start_boss_fight() -> void:
	if is_defeated or is_hostile:
		return
	if GameState.has_method("are_all_forest_santelmos_defeated") and not GameState.is_unfiltered_act3() and not GameState.are_all_forest_santelmos_defeated():
		var rem: int = GameState.get_remaining_forest_santelmo_count()
		GameState.notification_requested.emit("Derrote todos os %d Santelmos restantes na floresta antes de enfrentar a Guardiã." % rem)
		return
	is_hostile = true
	boss_state = BossState.IDLE_COMBAT
	current_hp = max_hp
	current_phase = 1
	_attack_cooldown = 1.10
	_state_timer = 0.0
	collision_mask = 0
	add_to_group("combat_target")
	add_to_group("water_target")
	add_to_group("enemies")
	if interact_area:
		interact_area.visible = false
		interact_area.set_deferred("monitoring", false)
		interact_area.set_deferred("monitorable", false)
	if has_node("/root/AudioManager"):
		var am := get_node("/root/AudioManager")
		am.play_sfx("boss_roar", -6.0)
		if am.has_method("sync_adaptive_soundtrack"):
			am.call("sync_adaptive_soundtrack", "forest_clearing", true)
	queue_redraw()


func _physics_process(delta: float) -> void:
	_bob_time += delta * 2.4
	if _hit_flash_timer > 0.0:
		_hit_flash_timer = maxf(0.0, _hit_flash_timer - delta)

	if sprite:
		var bob_amp := 1.8 if not is_hostile else 2.6
		sprite.position.y = roundf(sin(_bob_time) * bob_amp)
		if _hit_flash_timer > 0.0:
			sprite.modulate = Color(1.0, 0.45, 0.45, 1.0)
		elif boss_state == BossState.STAGGERED:
			sprite.modulate = Color(0.72, 0.92, 1.0, 0.92)
		elif is_hostile:
			sprite.modulate = Color(0.95, 0.80, 0.86, 1.0) if current_phase >= 2 else Color.WHITE
		else:
			sprite.modulate = Color.WHITE

	if aura_light:
		var base_e := 0.85 if not is_hostile else (1.35 if current_phase >= 2 else 1.15)
		aura_light.energy = base_e + sin(_bob_time * 1.4) * 0.16
		aura_light.color = Color(0.95, 0.32, 0.42, 1.0) if is_hostile else Color(0.28, 0.85, 0.96, 1.0)

	if not is_hostile or is_defeated:
		velocity = Vector2.ZERO
		queue_redraw()
		return

	if _is_dialogue_locked():
		velocity = Vector2.ZERO
		queue_redraw()
		return

	_knockback_vel = _knockback_vel.move_toward(Vector2.ZERO, 420.0 * delta)
	_update_boss_fsm(delta)
	move_and_slide()
	global_position.x = clampf(global_position.x, 160.0, 780.0)
	global_position.y = clampf(global_position.y, 100.0, 440.0)
	queue_redraw()


func _find_player() -> Node2D:
	if not is_inside_tree() or get_tree() == null:
		return null
	return get_tree().get_first_node_in_group("player") as Node2D


func _update_boss_fsm(delta: float) -> void:
	var player := _find_player()
	var dist_to_player := global_position.distance_to(player.global_position) if player != null else 9999.0

	match boss_state:
		BossState.IDLE_COMBAT:
			_attack_cooldown = maxf(0.0, _attack_cooldown - delta)
			if player != null:
				var desired_dist := 48.0
				var to_player := player.global_position - global_position
				var spd := move_speed * (1.18 if current_phase >= 2 else 1.0)
				if dist_to_player > desired_dist + 10.0:
					velocity = to_player.normalized() * spd + _knockback_vel
				elif dist_to_player < desired_dist - 14.0:
					velocity = -to_player.normalized() * (spd * 0.55) + _knockback_vel
				else:
					var tangent := Vector2(-to_player.y, to_player.x).normalized()
					velocity = tangent * (spd * 0.55) + _knockback_vel
			else:
				velocity = _knockback_vel

			if _attack_cooldown <= 0.0 and player != null:
				if dist_to_player <= wave_radius + 12.0 and (_attack_cycle % 2 == 0):
					_begin_wave_telegraph(player.global_position)
				else:
					_begin_lunge_telegraph(player.global_position)
				_attack_cycle += 1

		BossState.TELEGRAPH_WAVE:
			velocity = _knockback_vel * 0.4
			_state_timer -= delta
			if _state_timer <= 0.0:
				_execute_wave_attack()

		BossState.ATTACK_WAVE:
			velocity = Vector2.ZERO
			_state_timer -= delta
			if not _wave_damage_applied:
				_wave_damage_applied = true
				_check_wave_hit_on_player()
			if _state_timer <= 0.0:
				_enter_staggered(0.95)

		BossState.TELEGRAPH_LUNGE:
			velocity = _knockback_vel * 0.35
			_state_timer -= delta
			if _state_timer <= 0.0:
				_execute_lunge_attack()

		BossState.ATTACK_LUNGE:
			_state_timer -= delta
			velocity = _lunge_dir * lunge_speed + _knockback_vel * 0.25
			_check_lunge_hit_on_player()
			if _state_timer <= 0.0:
				_enter_staggered(1.05)

		BossState.STAGGERED:
			velocity = _knockback_vel * 0.65
			_state_timer -= delta
			if _state_timer <= 0.0:
				boss_state = BossState.IDLE_COMBAT
				_attack_cooldown = 0.85 if current_phase >= 2 else 1.15


func _begin_wave_telegraph(target_pos: Vector2) -> void:
	boss_state = BossState.TELEGRAPH_WAVE
	_state_timer = 0.64 if current_phase >= 2 else 0.74
	_wave_damage_applied = false
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").play_sfx("boss_telegraph", -6.5)
	boss_attack_telegraphed.emit("wave", global_position, target_pos)


func _execute_wave_attack() -> void:
	boss_state = BossState.ATTACK_WAVE
	_state_timer = 0.34
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").play_sfx("water_splash", -5.5)
	for i in range(4):
		var ang := float(i) * PI * 0.5 + PI * 0.25
		var offset := Vector2(cos(ang), sin(ang)) * (wave_radius * 0.58)
		VfxLibrary.spawn_burst(self, "water_splash", global_position + offset, {
			"scale": Vector2(0.75, 0.75),
			"z_index": 6,
		})


func _check_wave_hit_on_player() -> void:
	var player := _find_player()
	if player == null:
		return
	var dist := global_position.distance_to(player.global_position)
	# Hitbox estritamente fiel ao anel visual do telégrafo
	if dist <= wave_radius:
		if player.has_method("apply_hit"):
			player.call("apply_hit", wave_damage, global_position)


func _begin_lunge_telegraph(target_pos: Vector2) -> void:
	boss_state = BossState.TELEGRAPH_LUNGE
	_state_timer = 0.62 if current_phase >= 2 else 0.70
	_lunge_damage_applied = false
	_lunge_dir = (target_pos - global_position).normalized()
	if _lunge_dir.length_squared() < 0.01:
		_lunge_dir = Vector2.DOWN
	_lunge_target = global_position + _lunge_dir * 105.0
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").play_sfx("boss_telegraph", -6.0, 0.92)
	boss_attack_telegraphed.emit("lunge", global_position, _lunge_target)


func _execute_lunge_attack() -> void:
	boss_state = BossState.ATTACK_LUNGE
	_state_timer = 0.34
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").play_sfx("boss_roar", -7.0, 1.08)
	VfxLibrary.spawn_burst(self, "water_jet", global_position, {
		"rotation": _lunge_dir.angle(),
		"scale": Vector2(0.95, 0.95),
		"z_index": 5,
	})


func _check_lunge_hit_on_player() -> void:
	if _lunge_damage_applied:
		return
	var player := _find_player()
	if player == null:
		return
	# Hitbox fiel ao corpo visível do sprite durante o bote (24 px)
	if global_position.distance_to(player.global_position) <= 24.0:
		_lunge_damage_applied = true
		if player.has_method("apply_hit"):
			player.call("apply_hit", lunge_damage, global_position)


func _enter_staggered(duration: float) -> void:
	boss_state = BossState.STAGGERED
	_state_timer = duration
	velocity = Vector2.ZERO


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

	if not PlayerController.is_point_in_attack_cone(attacker_pos, swing_dir, global_position, hit_radius, attack_radius, attack_arc_degrees):
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


func take_damage(amount: int, from_pos: Vector2 = Vector2.ZERO) -> void:
	if is_defeated:
		return
	if not is_hostile:
		start_boss_fight()
	_apply_boss_damage(amount, from_pos if from_pos != Vector2.ZERO else global_position + Vector2.LEFT * 24.0, false)


func receive_melee_hit(damage: int, from_pos: Vector2) -> void:
	if is_defeated:
		return
	if not is_hostile:
		start_boss_fight()
	_apply_boss_damage(damage, from_pos, false)


func query_water_hit(attacker_pos: Vector2, aim_dir: Vector2, max_range: float, cone_deg: float, damage: int) -> Array[Dictionary]:
	if not is_hostile or is_defeated or not is_inside_tree():
		return []
	if not PlayerController.is_point_in_attack_cone(attacker_pos, aim_dir, global_position, hit_radius, max_range, cone_deg):
		return []
	receive_water_hit(damage, attacker_pos)
	return [{
		"id": str(get_instance_id()),
		"pos": global_position,
		"label": "-%d" % damage,
		"damage": damage
	}]


func receive_water_hit(damage: int, from_pos: Vector2) -> void:
	if is_defeated:
		return
	if not is_hostile:
		start_boss_fight()
	_apply_boss_damage(damage, from_pos, true)


func _apply_boss_damage(damage: int, from_pos: Vector2, _is_water: bool) -> void:
	if is_defeated:
		return
	var bonus_dmg := int(round(float(damage) * 1.2)) if boss_state == BossState.STAGGERED else damage
	current_hp = clampi(current_hp - bonus_dmg, 0, max_hp)
	_hit_flash_timer = 0.18
	var push_dir := (global_position - from_pos).normalized()
	if push_dir.length_squared() < 0.01:
		push_dir = Vector2.UP
	_knockback_vel = push_dir * 135.0

	var hp_ratio := float(current_hp) / float(maxi(1, max_hp))
	if current_hp <= 0:
		_handle_boss_defeat()
		return

	if not _phase2_triggered and hp_ratio <= 0.62:
		_phase2_triggered = true
		current_phase = 2
		_enter_staggered(0.65)
		boss_phase_dialogue_requested.emit("phase_2")
	elif not _phase3_triggered and hp_ratio <= 0.28:
		_phase3_triggered = true
		current_phase = 3
		_enter_staggered(0.65)
		boss_phase_dialogue_requested.emit("phase_3")

	queue_redraw()


func _handle_boss_defeat() -> void:
	is_defeated = true
	is_hostile = false
	boss_state = BossState.DEFEATED
	velocity = Vector2.ZERO
	_knockback_vel = Vector2.ZERO
	remove_from_group("combat_target")
	remove_from_group("water_target")
	remove_from_group("enemies")

	if has_node("/root/GameState"):
		var gs := get_node("/root/GameState")
		gs.water_boss_defeated = true
		gs.call("set_switch", "016_Magia_de_agua_obtida", true)

	if has_node("/root/AudioManager"):
		var am := get_node("/root/AudioManager")
		am.play_sfx("santelmo_defeat", -5.5)
		if am.has_method("sync_adaptive_soundtrack"):
			am.call("sync_adaptive_soundtrack", "forest_clearing", false)

	VfxLibrary.spawn_burst(self, "water_splash", global_position, {
		"scale": Vector2(1.15, 1.15),
		"z_index": 7,
	})
	if interact_area:
		interact_area.visible = true
		interact_area.title = "Guardião Acalmado"
		interact_area.verb = "Ouvir"
		interact_area.set_deferred("monitoring", true)
		interact_area.set_deferred("monitorable", true)

	boss_defeated.emit()
	queue_redraw()


func _draw() -> void:
	if not is_hostile and not is_defeated:
		return

	# Telégrafos visuais claros no chão antes dos golpes do Boss
	if boss_state == BossState.TELEGRAPH_WAVE:
		var total_t := 0.64 if current_phase >= 2 else 0.74
		var p := 1.0 - clampf(_state_timer / total_t, 0.0, 1.0)
		draw_circle(Vector2.ZERO, wave_radius * p, Color(0.95, 0.25, 0.35, 0.20 + 0.18 * p))
		draw_arc(Vector2.ZERO, wave_radius, 0.0, TAU, 36, Color(1.0, 0.38, 0.44, 0.85), 2.0)
	elif boss_state == BossState.ATTACK_WAVE:
		draw_arc(Vector2.ZERO, wave_radius, 0.0, TAU, 36, Color(0.45, 0.92, 1.0, 0.90), 3.0)
	elif boss_state == BossState.TELEGRAPH_LUNGE:
		var total_t := 0.62 if current_phase >= 2 else 0.70
		var p := 1.0 - clampf(_state_timer / total_t, 0.0, 1.0)
		var local_end := _lunge_dir * 105.0
		var perp := Vector2(-_lunge_dir.y, _lunge_dir.x) * 14.0
		var poly := PackedVector2Array([-perp, local_end - perp, local_end + perp, perp])
		draw_colored_polygon(poly, Color(0.95, 0.24, 0.32, 0.16 + 0.22 * p))
		draw_line(Vector2.ZERO, local_end, Color(1.0, 0.42, 0.42, 0.88), 2.2)
	elif boss_state == BossState.STAGGERED:
		draw_arc(Vector2.ZERO, 22.0, 0.0, TAU, 24, Color(0.55, 0.92, 1.0, 0.55), 1.5)

	# Barra de HP do Boss acima do Guardião durante o combate
	if is_hostile and not is_defeated:
		var bar_w := 56.0
		var bar_h := 5.0
		var bar_pos := Vector2(-bar_w * 0.5, -34.0)
		var ratio := clampf(float(current_hp) / float(maxi(1, max_hp)), 0.0, 1.0)
		draw_rect(Rect2(bar_pos - Vector2(1, 1), Vector2(bar_w + 2, bar_h + 2)), Color(0.05, 0.06, 0.10, 0.92), true)
		var fill_col := Color("#38B6FF") if current_phase == 1 else (Color("#F59E0B") if current_phase == 2 else Color("#EF4444"))
		draw_rect(Rect2(bar_pos, Vector2(bar_w * ratio, bar_h)), fill_col, true)


func _on_interacted(_ia: Interactable) -> void:
	if is_hostile:
		return
	interaction_requested.emit()
	creature_interacted.emit()
