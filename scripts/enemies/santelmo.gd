extends CharacterBody2D
class_name SantelmoEnemy

signal enemy_defeated(position: Vector2)

@export var max_health: int = 60
@export var current_health: int = 60
@export var move_speed: float = 65.0
@export var chase_speed: float = 95.0
@export var attack_damage: int = 12
@export var detection_radius: float = 140.0
@export var attack_range: float = 38.0
@export var hit_radius: float = 16.0

enum State { IDLE, WANDER, CHASE, ATTACK, HURT, DEAD }
var current_state: State = State.IDLE

var player: Node2D = null
var wander_target: Vector2 = Vector2.ZERO
var wander_timer: float = 0.0
var attack_cooldown: float = 0.0
var knockback_velocity: Vector2 = Vector2.ZERO

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var hurtbox: Area2D = $Hurtbox
@onready var hitbox: Area2D = $Hitbox
@onready var health_bar: ProgressBar = $HealthBar
@onready var fire_particles: CPUParticles2D = $FireParticles

func _ready() -> void:
	add_to_group("enemies")
	add_to_group("combat_target")
	add_to_group("water_target")
	current_health = max_health
	_update_health_bar()
	_pick_new_wander_target()

	if hurtbox:
		hurtbox.area_entered.connect(_on_hurtbox_area_entered)
	if hitbox:
		hitbox.body_entered.connect(_on_hitbox_body_entered)

func _physics_process(delta: float) -> void:
	if current_state == State.DEAD:
		return

	# Recuperação de Knockback
	if knockback_velocity.length() > 5.0:
		velocity = knockback_velocity
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 350.0 * delta)
		move_and_slide()
		return

	# Cooldown de ataque
	if attack_cooldown > 0.0:
		attack_cooldown -= delta

	# Busca pelo jogador caso ainda não referenciado
	if not player or not is_instance_valid(player):
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			player = players[0]

	_state_machine_logic(delta)
	move_and_slide()
	_animate_sprite(delta)

func _state_machine_logic(delta: float) -> void:
	var dist_to_player: float = global_position.distance_to(player.global_position) if (player and is_instance_valid(player)) else 9999.0

	match current_state:
		State.IDLE, State.WANDER:
			if dist_to_player <= detection_radius:
				current_state = State.CHASE
				return

			wander_timer -= delta
			if wander_timer <= 0.0:
				_pick_new_wander_target()

			if current_state == State.WANDER:
				var dir := (wander_target - global_position).normalized()
				velocity = dir * move_speed
				if global_position.distance_to(wander_target) < 10.0:
					current_state = State.IDLE
					velocity = Vector2.ZERO
					wander_timer = randf_range(1.0, 2.5)

		State.CHASE:
			if dist_to_player > detection_radius * 1.5:
				current_state = State.IDLE
				wander_timer = 1.0
				return

			if player and is_instance_valid(player):
				var dir := (player.global_position - global_position).normalized()
				velocity = dir * chase_speed

			if dist_to_player <= attack_range and attack_cooldown <= 0.0:
				_perform_attack()

		State.ATTACK:
			velocity = velocity.move_toward(Vector2.ZERO, 200.0 * delta)

		State.HURT:
			# O knockback processa a movimentação
			pass

func _pick_new_wander_target() -> void:
	var random_offset := Vector2(randf_range(-60.0, 60.0), randf_range(-60.0, 60.0))
	wander_target = global_position + random_offset
	wander_timer = randf_range(2.0, 4.0)
	current_state = State.WANDER if randf() > 0.3 else State.IDLE

func _perform_attack() -> void:
	current_state = State.ATTACK
	attack_cooldown = 1.6

	# Efeito visual de carga de chama antes da investida
	var tween := create_tween()
	if sprite:
		tween.tween_property(sprite, "scale", Vector2(1.3, 1.3), 0.15)
	tween.tween_callback(func():
		if player and is_instance_valid(player):
			var dash_dir := (player.global_position - global_position).normalized()
			knockback_velocity = dash_dir * 180.0
	)
	if sprite:
		tween.tween_property(sprite, "scale", Vector2(1.0, 1.0), 0.2)
	tween.tween_callback(func():
		if current_state != State.DEAD:
			current_state = State.CHASE
	)

func take_damage(amount: int, knockback_source: Vector2 = Vector2.ZERO, is_water_damage: bool = false) -> void:
	if current_state == State.DEAD:
		return

	# Fraqueza elementar à água (+100% de dano crítico)
	var final_damage := amount * 2 if is_water_damage else amount
	current_health = clampi(current_health - final_damage, 0, max_health)
	_update_health_bar()

	# Aplicação de Knockback
	if knockback_source != Vector2.ZERO:
		var knock_dir := (global_position - knockback_source).normalized()
		knockback_velocity = knock_dir * (220.0 if not is_water_damage else 150.0)

	# Flash de dano (azul claro para água, vermelho vivo para machado)
	if sprite:
		var flash_color := Color(0.3, 0.7, 1.0, 1.0) if is_water_damage else Color(1.0, 0.2, 0.2, 1.0)
		sprite.modulate = flash_color
		var tween := create_tween()
		tween.tween_property(sprite, "modulate", Color(1, 1, 1, 1), 0.18)

	if current_health <= 0:
		_die()
	else:
		current_state = State.HURT
		var t := get_tree().create_timer(0.2)
		t.timeout.connect(func():
			if current_state != State.DEAD:
				current_state = State.CHASE
		)

# Integração com PlayerController (query_melee_hit / receive_melee_hit)
func receive_melee_hit(damage: int, from_pos: Vector2) -> void:
	take_damage(damage, from_pos, false)

# Integração com PlayerController (query_water_hit / receive_water_hit)
func receive_water_hit(damage: int, from_pos: Vector2) -> void:
	take_damage(damage, from_pos, true)

func _die() -> void:
	current_state = State.DEAD
	velocity = Vector2.ZERO
	knockback_velocity = Vector2.ZERO
	if health_bar:
		health_bar.visible = false

	# Desativa colisões
	if collision_shape:
		collision_shape.set_deferred("disabled", true)
	if hurtbox:
		hurtbox.set_deferred("monitoring", false)
		hurtbox.set_deferred("monitorable", false)
	if hitbox:
		hitbox.set_deferred("monitoring", false)
		hitbox.set_deferred("monitorable", false)

	# Animação de extinção do fogo
	var tween := create_tween()
	if sprite:
		tween.parallel().tween_property(sprite, "scale", Vector2(0.1, 0.1), 0.35)
		tween.parallel().tween_property(sprite, "modulate:a", 0.0, 0.35)
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

func _animate_sprite(_delta: float) -> void:
	if not sprite:
		return
	# Pulsação orgânica da chama viva
	var pulse := sin(Time.get_ticks_msec() * 0.008) * 0.08
	sprite.scale = Vector2(1.0 + pulse, 1.0 - pulse)

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
	if body.is_in_group("player"):
		if body.has_method("apply_hit"):
			body.call("apply_hit", attack_damage, global_position)
		elif body.has_method("take_damage"):
			body.call("take_damage", attack_damage, global_position)
