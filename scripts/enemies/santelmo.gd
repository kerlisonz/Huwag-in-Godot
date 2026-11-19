extends CharacterBody2D
class_name SantelmoEnemy

signal enemy_defeated(position: Vector2)

@export var max_health: int = 60
@export var current_health: int = 60
@export var move_speed: float = 65.0
@export var chase_speed: float = 95.0
@export var attack_damage: int = 12
@export var detection_radius: float = 145.0
@export var attack_range: float = 40.0
@export var hit_radius: float = 20.0
@export_enum("wander", "patrol", "ambush") var behavior_mode: String = "wander"
@export var patrol_waypoints: Array[Vector2] = []

enum State { IDLE, WANDER, PATROL, AMBUSH_WAIT, CHASE, TELEGRAPH, ATTACK, HURT, DEAD }
var current_state: State = State.IDLE

const HUMANOID_FRAMES: SpriteFrames = preload("res://assets/sprites/enemies/santelmo/santelmo_humanoid_spriteframes.tres")

var player: Node2D = null
var spawn_origin: Vector2 = Vector2.ZERO
var wander_target: Vector2 = Vector2.ZERO
var wander_timer: float = 0.0
var attack_cooldown: float = 0.0
var knockback_velocity: Vector2 = Vector2.ZERO
var _patrol_index: int = 0
var _telegraph_timer: float = 0.0
var _telegraph_dir: Vector2 = Vector2.DOWN
var _telegraph_kind: String = "melee"
var _ranged_cooldown: float = 0.0
var _facing: String = "down"
var _flame_vfx: AnimatedSprite2D = null
var _killed_by_water: bool = false

@onready var sprite: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var hurtbox: Area2D = $Hurtbox
@onready var hitbox: Area2D = $Hitbox
@onready var health_bar: ProgressBar = $HealthBar
@onready var fire_particles: CPUParticles2D = $FireParticles


func _ready() -> void:
	add_to_group("enemies")
	add_to_group("combat_target")
	add_to_group("water_target")
	spawn_origin = global_position
	current_health = max_health
	_update_health_bar()
	_flame_vfx = VfxLibrary.attach_loop(self, "santelmo_flame", Vector2(0.0, -2.0), {
		"scale": Vector2(0.32, 0.32),
		"modulate": Color(1.0, 0.88, 0.76, 0.44),
		"z_index": -1,
	})
	if sprite:
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.sprite_frames = HUMANOID_FRAMES
		sprite.scale = Vector2.ONE
		if sprite.sprite_frames and sprite.sprite_frames.has_animation("idle_down"):
			sprite.play("idle_down")

	if behavior_mode == "patrol" and patrol_waypoints.size() >= 2:
		current_state = State.PATROL
	elif behavior_mode == "ambush":
		current_state = State.AMBUSH_WAIT
		if sprite:
			sprite.modulate.a = 0.42
		if _flame_vfx:
			_flame_vfx.modulate.a = 0.35
	else:
		_pick_new_wander_target()

	if hurtbox and not hurtbox.area_entered.is_connected(_on_hurtbox_area_entered):
		hurtbox.area_entered.connect(_on_hurtbox_area_entered)
	if hitbox and not hitbox.body_entered.is_connected(_on_hitbox_body_entered):
		hitbox.body_entered.connect(_on_hitbox_body_entered)


func _is_dialogue_locked() -> bool:
	if has_node("/root/GameState"):
		var gs := get_node("/root/GameState")
		if bool(gs.get("dialogue_active")) or bool(gs.get("sleep_transition_active")):
			return true
	return false


func _physics_process(delta: float) -> void:
	if current_state == State.DEAD:
		return

	if _is_dialogue_locked():
		velocity = Vector2.ZERO
		queue_redraw()
		return

	if knockback_velocity.length() > 5.0:
		velocity = knockback_velocity
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 360.0 * delta)
		move_and_slide()
		queue_redraw()
		return

	if attack_cooldown > 0.0:
		attack_cooldown -= delta
	if _ranged_cooldown > 0.0:
		_ranged_cooldown -= delta

	if not player or not is_instance_valid(player):
		var players := get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			player = players[0] as Node2D

	_state_machine_logic(delta)
	move_and_slide()
	_animate_sprite(delta)
	queue_redraw()


func _compute_steered_velocity(desired_dir: Vector2, speed_val: float, delta: float) -> Vector2:
	if desired_dir.length_squared() < 0.001:
		return Vector2.ZERO
	var base_dir := desired_dir.normalized()
	var step_dist := maxf(4.0, speed_val * maxf(delta, 0.016) * 2.0)
	if not test_move(global_transform, base_dir * step_dist):
		return base_dir * speed_val

	var candidate_angles := [0.55, -0.55, 1.05, -1.05, 1.48, -1.48]
	for ang in candidate_angles:
		var cand := base_dir.rotated(float(ang))
		if not test_move(global_transform, cand * step_dist):
			return cand * speed_val
	return -base_dir * (speed_val * 0.5)


func _state_machine_logic(delta: float) -> void:
	var dist_to_player: float = global_position.distance_to(player.global_position) if (player and is_instance_valid(player)) else 9999.0

	match current_state:
		State.AMBUSH_WAIT:
			velocity = Vector2.ZERO
			var ambush_trigger := detection_radius * 0.78
			if dist_to_player <= ambush_trigger:
				if sprite:
					sprite.modulate.a = 1.0
				if _flame_vfx:
					_flame_vfx.modulate.a = 0.78
				if has_node("/root/AudioManager"):
					get_node("/root/AudioManager").play_sfx("santelmo_cry", -9.0)
				current_state = State.CHASE

		State.PATROL:
			if dist_to_player <= detection_radius:
				current_state = State.CHASE
				return
			if patrol_waypoints.size() < 2:
				_pick_new_wander_target()
				return
			var target_wp: Vector2 = patrol_waypoints[_patrol_index % patrol_waypoints.size()]
			var to_wp := target_wp - global_position
			if to_wp.length() <= 10.0:
				_patrol_index = (_patrol_index + 1) % patrol_waypoints.size()
				velocity = Vector2.ZERO
			else:
				velocity = _compute_steered_velocity(to_wp.normalized(), move_speed * 1.05, delta)

		State.IDLE, State.WANDER:
			if dist_to_player <= detection_radius:
				current_state = State.CHASE
				return

			if behavior_mode == "patrol" and patrol_waypoints.size() >= 2:
				current_state = State.PATROL
				return

			wander_timer -= delta
			if wander_timer <= 0.0:
				_pick_new_wander_target()

			if current_state == State.WANDER:
				var dir := (wander_target - global_position).normalized()
				velocity = _compute_steered_velocity(dir, move_speed, delta)
				if global_position.distance_to(wander_target) < 10.0:
					current_state = State.IDLE
					velocity = Vector2.ZERO
					wander_timer = randf_range(0.9, 2.2)
			else:
				velocity = Vector2.ZERO

		State.CHASE:
			if dist_to_player > detection_radius * 1.65:
				if behavior_mode == "patrol" and patrol_waypoints.size() >= 2:
					current_state = State.PATROL
				else:
					current_state = State.IDLE
					wander_timer = 0.8
				return

			if player and is_instance_valid(player):
				var dir := (player.global_position - global_position).normalized()
				velocity = _compute_steered_velocity(dir, chase_speed, delta)

			if dist_to_player <= attack_range and attack_cooldown <= 0.0:
				_begin_attack_telegraph("melee")
			elif dist_to_player >= 78.0 and dist_to_player <= 150.0 and attack_cooldown <= 0.0 and _ranged_cooldown <= 0.0:
				_begin_attack_telegraph("ranged")

		State.TELEGRAPH:
			velocity = Vector2.ZERO
			_telegraph_timer -= delta
			if _telegraph_timer <= 0.0:
				if _telegraph_kind == "ranged":
					_perform_ranged_orb_attack()
				else:
					_perform_attack_dash()

		State.ATTACK:
			velocity = velocity.move_toward(Vector2.ZERO, 220.0 * delta)

		State.HURT:
			pass


func _pick_new_wander_target() -> void:
	var anchor := spawn_origin if spawn_origin != Vector2.ZERO else global_position
	var random_offset := Vector2(randf_range(-64.0, 64.0), randf_range(-64.0, 64.0))
	wander_target = anchor + random_offset
	wander_timer = randf_range(1.8, 3.6)
	current_state = State.WANDER if randf() > 0.25 else State.IDLE


func _begin_attack_telegraph(kind: String = "melee") -> void:
	current_state = State.TELEGRAPH
	_telegraph_kind = kind
	_telegraph_timer = 0.42 if kind == "ranged" else 0.30
	if player and is_instance_valid(player):
		_telegraph_dir = (player.global_position - global_position).normalized()
	if _telegraph_dir.length_squared() < 0.01:
		_telegraph_dir = Vector2.DOWN
	_update_facing(_telegraph_dir)
	_play_anim("attack2" if kind == "ranged" else "attack1")


func _perform_attack_dash() -> void:
	if current_state == State.DEAD:
		return
	current_state = State.ATTACK
	attack_cooldown = 1.55
	if player and is_instance_valid(player):
		_telegraph_dir = (player.global_position - global_position).normalized()
	if _telegraph_dir.length_squared() < 0.01:
		_telegraph_dir = Vector2.DOWN
	_update_facing(_telegraph_dir)
	_play_anim("attack1")
	knockback_velocity = _telegraph_dir * 185.0
	var tween := create_tween()
	tween.tween_interval(0.26)
	tween.tween_callback(func():
		if current_state != State.DEAD:
			current_state = State.CHASE
	)


func _perform_ranged_orb_attack() -> void:
	if current_state == State.DEAD:
		return
	current_state = State.ATTACK
	attack_cooldown = 1.65
	_ranged_cooldown = 3.2
	if player and is_instance_valid(player):
		_telegraph_dir = (player.global_position - global_position).normalized()
	if _telegraph_dir.length_squared() < 0.01:
		_telegraph_dir = Vector2.DOWN
	_update_facing(_telegraph_dir)
	_play_anim("attack2")
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").play_sfx("santelmo_cry", -10.5, 1.22)
	if is_inside_tree() and get_parent() != null:
		var orb := _SantelmoFireOrb.new()
		orb.shooter = self
		orb.direction = _telegraph_dir
		orb.damage = attack_damage
		orb.collision_mask = (hitbox.collision_mask if hitbox else 1) | 1
		orb.global_position = global_position + _telegraph_dir * 14.0
		get_parent().add_child(orb)
	var tween := create_tween()
	tween.tween_interval(0.32)
	tween.tween_callback(func():
		if current_state != State.DEAD:
			current_state = State.CHASE
	)


func take_damage(amount: int, knockback_source: Vector2 = Vector2.ZERO, is_water_damage: bool = false) -> void:
	if current_state == State.DEAD:
		return

	if sprite and sprite.modulate.a < 1.0:
		sprite.modulate.a = 1.0

	var final_damage := amount * 2 if is_water_damage else amount
	current_health = clampi(current_health - final_damage, 0, max_health)
	_update_health_bar()

	if knockback_source != Vector2.ZERO:
		var knock_dir := (global_position - knockback_source).normalized()
		knockback_velocity = knock_dir * (220.0 if not is_water_damage else 155.0)

	if sprite:
		var flash_color := Color(0.3, 0.7, 1.0, 1.0) if is_water_damage else Color(1.0, 0.25, 0.25, 1.0)
		sprite.modulate = flash_color
		var tween := create_tween()
		tween.tween_property(sprite, "modulate", Color(1, 1, 1, 1), 0.18)
	if _flame_vfx and is_instance_valid(_flame_vfx):
		_flame_vfx.modulate = Color(0.35, 0.8, 1.0, 0.85) if is_water_damage else Color(1.0, 0.4, 0.3, 0.9)
		var f_tween := create_tween()
		f_tween.tween_property(_flame_vfx, "modulate", Color(1.0, 0.92, 0.84, 0.78), 0.18)

	if current_health <= 0:
		_killed_by_water = is_water_damage
		_die()
	else:
		current_state = State.HURT
		_play_anim("hurt")
		var t := get_tree().create_timer(0.20)
		t.timeout.connect(func():
			if current_state != State.DEAD:
				current_state = State.CHASE
		)


func receive_melee_hit(damage: int, from_pos: Vector2) -> void:
	take_damage(damage, from_pos, false)


func receive_water_hit(damage: int, from_pos: Vector2) -> void:
	take_damage(damage, from_pos, true)


func _die() -> void:
	current_state = State.DEAD
	velocity = Vector2.ZERO
	knockback_velocity = Vector2.ZERO
	if health_bar:
		health_bar.visible = false

	if collision_shape:
		collision_shape.set_deferred("disabled", true)
	if hurtbox:
		hurtbox.set_deferred("monitoring", false)
		hurtbox.set_deferred("monitorable", false)
	if hitbox:
		hitbox.set_deferred("monitoring", false)
		hitbox.set_deferred("monitorable", false)

	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").play_sfx("santelmo_defeat", -7.5)

	var death_fx := "water_splash" if _killed_by_water else "blunt_hit"
	VfxLibrary.spawn_burst(self, death_fx, global_position + Vector2(0.0, 4.0), {
		"scale": Vector2(0.75, 0.75) if _killed_by_water else Vector2(0.55, 0.55),
		"z_index": 7,
	})
	_play_anim("death")
	var tween := create_tween()
	tween.tween_interval(0.32)
	if sprite:
		tween.parallel().tween_property(sprite, "modulate:a", 0.0, 0.26)
	if _flame_vfx and is_instance_valid(_flame_vfx):
		tween.parallel().tween_property(_flame_vfx, "scale", Vector2(0.08, 0.08), 0.30)
		tween.parallel().tween_property(_flame_vfx, "modulate:a", 0.0, 0.30)
	if fire_particles:
		fire_particles.emitting = false
	tween.tween_callback(func():
		enemy_defeated.emit(global_position)
		queue_free()
	)


func _update_health_bar() -> void:
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = current_health
		health_bar.visible = (current_health < max_health and current_health > 0)


func _update_facing(vec: Vector2) -> void:
	if vec.length_squared() < 0.01:
		return
	if absf(vec.x) > absf(vec.y):
		_facing = "right" if vec.x >= 0.0 else "left"
	else:
		_facing = "down" if vec.y >= 0.0 else "up"


func _play_anim(prefix: String) -> void:
	if not sprite or not sprite.sprite_frames:
		return
	var anim_name := "%s_%s" % [prefix, _facing]
	if sprite.sprite_frames.has_animation(anim_name):
		if sprite.animation != anim_name or not sprite.is_playing():
			sprite.play(anim_name)


func _animate_sprite(_delta: float) -> void:
	if not sprite:
		return
	if velocity.length_squared() > 4.0 and current_state not in [State.HURT, State.DEAD, State.TELEGRAPH, State.ATTACK]:
		_update_facing(velocity)
	var prefix := "idle"
	match current_state:
		State.DEAD:
			prefix = "death"
		State.HURT:
			prefix = "hurt"
		State.TELEGRAPH, State.ATTACK:
			prefix = "attack2" if _telegraph_kind == "ranged" else "attack1"
		State.CHASE:
			prefix = "run" if velocity.length() > 12.0 else "idle"
		State.WANDER, State.PATROL:
			prefix = "walk" if velocity.length() > 8.0 else "idle"
		_:
			prefix = "idle"
	_play_anim(prefix)


func _draw() -> void:
	if current_state == State.TELEGRAPH and _telegraph_timer > 0.0:
		var total_t := 0.42 if _telegraph_kind == "ranged" else 0.30
		var p := 1.0 - clampf(_telegraph_timer / total_t, 0.0, 1.0)
		var arc_col := Color(0.32, 0.85, 1.0, 0.85) if _telegraph_kind == "ranged" else Color(1.0, 0.42, 0.22, 0.75)
		draw_arc(Vector2.ZERO, lerpf(10.0, 24.0, p), 0.0, TAU, 20, arc_col, 1.6)
		draw_line(Vector2.ZERO, _telegraph_dir * (36.0 if _telegraph_kind == "ranged" else 26.0), Color(1.0, 0.62, 0.25, 0.85), 2.0)


class _SantelmoFireOrb extends Area2D:
	var shooter: Node2D = null
	var direction: Vector2 = Vector2.RIGHT
	var speed: float = 165.0
	var damage: int = 12
	var _life: float = 1.15
	var _t: float = 0.0

	func _ready() -> void:
		z_index = 6
		monitoring = true
		monitorable = false
		var col := CollisionShape2D.new()
		var circ := CircleShape2D.new()
		circ.radius = 6.0
		col.shape = circ
		add_child(col)
		body_entered.connect(_on_body_entered)

	func _physics_process(delta: float) -> void:
		if has_node("/root/GameState"):
			var gs := get_node("/root/GameState")
			if bool(gs.get("dialogue_active")) or bool(gs.get("sleep_transition_active")):
				return
		_t += delta
		_life -= delta
		position += direction * speed * delta
		queue_redraw()
		if _life <= 0.0:
			queue_free()

	func _draw() -> void:
		var r := 5.5 + sin(_t * 18.0) * 1.1
		draw_circle(Vector2.ZERO, r + 2.0, Color(1.0, 0.46, 0.14, 0.55))
		draw_circle(Vector2.ZERO, r, Color(1.0, 0.72, 0.20, 0.92))
		draw_circle(Vector2.ZERO, r * 0.55, Color(0.32, 0.86, 1.0, 0.98))
		draw_circle(Vector2.ZERO, 1.8, Color(1.0, 0.98, 0.90, 1.0))

	func _on_body_entered(body: Node) -> void:
		if body == null or body == shooter or body is SantelmoEnemy:
			return
		if body.is_in_group("player"):
			if body.has_method("apply_hit"):
				body.call("apply_hit", damage, global_position)
			elif body.has_method("take_damage"):
				body.call("take_damage", damage, global_position)
			VfxLibrary.spawn_burst(get_parent(), "santelmo_flame", global_position, {
				"scale": Vector2(0.42, 0.42),
				"z_index": 7,
			})
			queue_free()
		elif body is StaticBody2D or body is TileMapLayer:
			VfxLibrary.spawn_burst(get_parent(), "santelmo_flame", global_position, {
				"scale": Vector2(0.32, 0.32),
				"z_index": 7,
			})
			queue_free()


func _on_hurtbox_area_entered(area: Area2D) -> void:
	if area.is_in_group("player_attack") or area.name == "AxeHitbox":
		var dmg: int = 20
		if area.get("damage") != null:
			dmg = int(area.damage)
		take_damage(dmg, area.global_position, false)
	elif area.is_in_group("player_water_magic") or area.name == "WaterProjectile":
		var dmg: int = 30
		if area.get("damage") != null:
			dmg = int(area.damage)
		take_damage(dmg, area.global_position, true)


func _on_hitbox_body_entered(body: Node2D) -> void:
	if current_state == State.DEAD or _is_dialogue_locked():
		return
	if body.is_in_group("player"):
		if body.has_method("apply_hit"):
			body.call("apply_hit", attack_damage, global_position)
		elif body.has_method("take_damage"):
			body.call("take_damage", attack_damage, global_position)
