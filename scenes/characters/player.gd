extends CharacterBody2D
class_name PlayerController

signal nearby_interactable_changed(prompt: String)
signal melee_attack_performed(origin: Vector2, facing: Vector2, radius: float, arc_deg: float, damage: int)
signal water_skill_performed(origin: Vector2, facing: Vector2, range_dist: float, damage: int)
signal attack_hit_landed(hit_pos: Vector2, damage: int)
signal attack_missed(miss_pos: Vector2)

@export var speed: float = 135.0
@export var run_speed_multiplier: float = 1.42
@export var attack_damage: int = 25
@export var attack_radius: float = 44.0
@export var attack_arc_degrees: float = 120.0

@onready var character_sprite: AnimatedSprite2D = $CharacterSprite
@onready var visual: Polygon2D = $Visual
@onready var interaction_area: Area2D = $InteractionArea
@onready var prompt_label: Label = $PromptLabel
@onready var camera: Camera2D = $Camera2D

var facing_dir: Vector2 = Vector2.DOWN
var walk_time: float = 0.0
var is_moving: bool = false
var is_running: bool = false
var is_crouching: bool = false
var is_jumping: bool = false
var _facing_left: bool = false
var _nearby_interactables: Array[Interactable] = []
var _interact_cooldown: float = 0.0

# Estado de combate e acrobacia (J-ABS / Top-Down Action)
const ATTACK_DURATION := 0.26
const JUMP_DURATION := 0.42
var _attack_cooldown: float = 0.0
var _attack_anim_timer: float = 0.0
var _water_anim_timer: float = 0.0
var _jump_timer: float = 0.0
var _jump_height: float = 0.0
var _hurt_timer: float = 0.0
var _knockback_vel: Vector2 = Vector2.ZERO

# Rastreamento preciso do golpe atual (posição, direção, duração e alvos atingidos)
var _swing_dir: Vector2 = Vector2.DOWN
var _swing_hit_ids: Dictionary = {}
var _swing_landed_hit: bool = false
var _swing_miss_registered: bool = false
var _was_attack_key_down: bool = false
var _was_water_key_down: bool = false
var _was_outfit_key_down: bool = false
var _was_jump_key_down: bool = false

# Spritesheets auxiliares e de referência (128x128 male_hero_free + 48x48 sheets)
const HERO_CELL_SIZE := Vector2i(128, 128)
const SHEET_CELL_SIZE := Vector2i(48, 48)
var _sheet_casual: Texture2D = null
var _sheet_bfp: Texture2D = null
var _pixel_font: Font = null

# Efeitos visuais de feedback (acerto / erro / dano flutuante)
var _combat_fx: Array[Dictionary] = []

func _ready() -> void:
	add_to_group("player")
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	collision_layer = 2
	collision_mask = 1
	if ResourceLoader.exists("res://assets/fonts/undertale-deltarune-extended-fixed.otf"):
		_pixel_font = load("res://assets/fonts/undertale-deltarune-extended-fixed.otf") as Font
	if ResourceLoader.exists("res://assets/characters/sprites/huwag_casual_sheet.png"):
		_sheet_casual = load("res://assets/characters/sprites/huwag_casual_sheet.png") as Texture2D
	if ResourceLoader.exists("res://assets/characters/sprites/huwag_bfp_sheet.png"):
		_sheet_bfp = load("res://assets/characters/sprites/huwag_bfp_sheet.png") as Texture2D

	_setup_character_sprite_frames()

	GameState.outfit_changed.connect(func(_o: String) -> void:
		_update_character_sprite_state()
		queue_redraw()
	)
	if visual:
		visual.visible = false
	if interaction_area:
		interaction_area.area_entered.connect(_on_interaction_area_entered)
		interaction_area.area_exited.connect(_on_interaction_area_exited)
	_style_prompt_label()
	_update_interaction_offset()
	_refresh_prompt()

var _current_sheet_outfit: String = ""

func _ensure_correct_outfit_sheet() -> void:
	var needed_outfit: String = GameState.equipped_outfit
	if _current_sheet_outfit == needed_outfit:
		return
	_current_sheet_outfit = needed_outfit
	_setup_character_sprite_frames()

func _setup_character_sprite_frames() -> void:
	if character_sprite == null:
		character_sprite = get_node_or_null("CharacterSprite") as AnimatedSprite2D
	if character_sprite == null:
		return

	var is_bfp := (GameState.equipped_outfit == "bfp")
	var path := "res://assets/characters/sprites/huwag_bfp_sheet.png" if is_bfp else "res://assets/characters/sprites/huwag_casual_sheet.png"
	var tex := load(path) as Texture2D
	if tex == null:
		return

	var sf := SpriteFrames.new()
	if sf.has_animation("default"):
		sf.remove_animation("default")

	var dirs := ["down", "left", "right", "up"]
	for r in range(4):
		var dname: String = dirs[r]
		# 1. Idle (cols 0..1, 4 FPS)
		_add_rect_animation(sf, "idle_%s" % dname, tex, r, 0, 2, 4.0, true)
		# 2. Walk (cols 2..5, 9 FPS)
		_add_rect_animation(sf, "walk_%s" % dname, tex, r, 2, 4, 9.0, true)
		# 3. Run (cols 2..5, 14 FPS)
		_add_rect_animation(sf, "run_%s" % dname, tex, r, 2, 4, 14.0, true)
		# 4. Attack (cols 6..9, 22 FPS)
		_add_rect_animation(sf, "attack_%s" % dname, tex, r, 6, 4, 22.0, false)
		# 5. Crouch (col 1, 1 frame)
		_add_rect_animation(sf, "crouch_%s" % dname, tex, r, 1, 1, 6.0, true)
		# 6. Jump (col 2, 1 frame)
		_add_rect_animation(sf, "jump_%s" % dname, tex, r, 2, 1, 6.0, false)

	# Aliases para compatibilidade total com testes
	_add_rect_animation(sf, "idle", tex, 0, 0, 2, 4.0, true)
	_add_rect_animation(sf, "walk", tex, 0, 2, 4, 9.0, true)
	_add_rect_animation(sf, "run", tex, 0, 2, 4, 14.0, true)
	_add_rect_animation(sf, "attack", tex, 0, 6, 4, 22.0, false)
	_add_rect_animation(sf, "crouch", tex, 0, 1, 1, 6.0, true)
	_add_rect_animation(sf, "jump", tex, 0, 2, 1, 6.0, false)

	character_sprite.sprite_frames = sf
	character_sprite.offset = Vector2(0.0, -8.0)
	character_sprite.play("idle_down")

func _add_rect_animation(sf: SpriteFrames, anim_name: String, tex: Texture2D, row: int, col_start: int, count: int, fps: float, loop: bool) -> void:
	sf.add_animation(anim_name)
	sf.set_animation_speed(anim_name, fps)
	sf.set_animation_loop(anim_name, loop)
	for i in range(count):
		var atlas := AtlasTexture.new()
		atlas.atlas = tex
		atlas.region = Rect2(
			float((col_start + i) * 48),
			float(row * 48),
			48.0,
			48.0
		)
		sf.add_frame(anim_name, atlas)

func _style_prompt_label() -> void:
	if prompt_label == null:
		return
	var sb := StyleBoxFlat.new()
	sb.corner_detail = 1
	sb.set_corner_radius_all(3)
	sb.set_border_width_all(1)
	sb.content_margin_left = 6
	sb.content_margin_right = 6
	sb.content_margin_top = 2
	sb.content_margin_bottom = 2
	sb.bg_color = Color(0.07, 0.08, 0.11, 0.88)
	sb.border_color = Color(0.76, 0.79, 0.84, 0.65)
	prompt_label.add_theme_stylebox_override("normal", sb)

func set_camera_limits(bounds: Rect2i) -> void:
	if camera == null:
		camera = get_node_or_null("Camera2D") as Camera2D
	if camera:
		camera.limit_left = bounds.position.x
		camera.limit_top = bounds.position.y
		camera.limit_right = bounds.position.x + bounds.size.x
		camera.limit_bottom = bounds.position.y + bounds.size.y
		camera.reset_smoothing()

func apply_hit(damage: int, from_pos: Vector2) -> void:
	if _hurt_timer > 0.0:
		return
	_hurt_timer = 0.55
	var push_dir := (global_position - from_pos).normalized()
	if push_dir.length_squared() < 0.01:
		push_dir = -facing_dir
	_knockback_vel = push_dir * 190.0
	GameState.damage_player(damage)
	CombatSfx.play(self, "player_hurt", -5.0)
	_spawn_combat_fx("hurt", global_position + Vector2(0, -14), "-%d" % damage, Color("#FF595E"))
	queue_redraw()

func take_damage(amount: int, from_pos: Vector2 = Vector2.ZERO) -> void:
	apply_hit(amount, from_pos if from_pos != Vector2.ZERO else (global_position - facing_dir * 12.0))

func perform_jump() -> bool:
	if is_jumping or _attack_anim_timer > 0.0 or GameState.dialogue_active:
		return false
	is_jumping = true
	_jump_timer = JUMP_DURATION
	CombatSfx.play(self, "swing_miss", -12.0)
	if character_sprite and character_sprite.sprite_frames and character_sprite.sprite_frames.has_animation("jump"):
		character_sprite.frame = 0
		character_sprite.play("jump")
	return true

func perform_melee_attack() -> bool:
	if _attack_cooldown > 0.0 or GameState.dialogue_active:
		return false
	_attack_cooldown = 0.40
	_attack_anim_timer = ATTACK_DURATION
	_swing_dir = facing_dir.normalized()
	if _swing_dir.length_squared() < 0.01:
		_swing_dir = Vector2.DOWN
	if absf(_swing_dir.x) > 0.15:
		_facing_left = (_swing_dir.x < 0.0)
	_swing_hit_ids.clear()
	_swing_landed_hit = false
	_swing_miss_registered = false

	if character_sprite and character_sprite.sprite_frames and character_sprite.sprite_frames.has_animation("attack"):
		character_sprite.frame = 0
		character_sprite.play("attack")

	CombatSfx.play(self, "swing_miss", -9.5)
	melee_attack_performed.emit(global_position, _swing_dir, attack_radius, attack_arc_degrees, attack_damage)
	_evaluate_active_melee_hitbox()
	queue_redraw()
	return true

func perform_water_skill() -> bool:
	if _attack_cooldown > 0.0 or GameState.dialogue_active:
		return false
	if not GameState.get_switch("016_Magia_de_agua_obtida"):
		GameState.notification_requested.emit("Habilidade de Água ainda não aprendida")
		return false
	_attack_cooldown = 0.50
	_water_anim_timer = 0.26
	var dir := facing_dir.normalized()
	if dir.length_squared() < 0.01:
		dir = Vector2.DOWN
	CombatSfx.play(self, "water_cast", -5.5)
	water_skill_performed.emit(global_position, dir, 62.0, 35)
	_apply_water_to_scene_targets(dir)
	queue_redraw()
	return true

static func is_point_in_attack_cone(origin: Vector2, swing_dir: Vector2, target_pos: Vector2, target_radius: float, reach: float, arc_deg: float) -> bool:
	var to_target := target_pos - origin
	var center_dist := to_target.length()
	var effective_dist := maxf(0.0, center_dist - target_radius)
	if effective_dist > reach:
		return false
	if center_dist <= target_radius + 8.0:
		return to_target.length_squared() < 1.0 or swing_dir.dot(to_target.normalized()) >= -0.25
	var half_arc_rad := deg_to_rad(arc_deg * 0.5)
	var angle := absf(swing_dir.angle_to(to_target.normalized()))
	var angular_pad := atan2(target_radius, maxf(8.0, center_dist))
	return (angle - angular_pad) <= half_arc_rad

func _evaluate_active_melee_hitbox() -> void:
	var newly_hit: Array[Dictionary] = []
	for node in get_tree().get_nodes_in_group("combat_target"):
		if not is_instance_valid(node):
			continue
		if node.has_method("query_melee_hit"):
			var hits: Variant = node.call("query_melee_hit", global_position, _swing_dir, attack_radius, attack_arc_degrees, attack_damage, _swing_hit_ids)
			if typeof(hits) == TYPE_ARRAY:
				for h in hits:
					if typeof(h) == TYPE_DICTIONARY:
						newly_hit.append(h)
		elif node is Node2D:
			var target_2d := node as Node2D
			var tid := str(target_2d.get_instance_id())
			if _swing_hit_ids.has(tid):
				continue
			var target_radius: float = float(target_2d.get("hit_radius")) if target_2d.get("hit_radius") != null else 16.0
			if is_point_in_attack_cone(global_position, _swing_dir, target_2d.global_position, target_radius, attack_radius, attack_arc_degrees):
				_swing_hit_ids[tid] = true
				if target_2d.has_method("receive_melee_hit"):
					target_2d.call("receive_melee_hit", attack_damage, global_position)
				newly_hit.append({
					"id": tid,
					"pos": target_2d.global_position,
					"damage": attack_damage
				})

	if not newly_hit.is_empty():
		if not _swing_landed_hit:
			CombatSfx.play(self, "melee_hit", -3.5)
		_swing_landed_hit = true
		for h in newly_hit:
			var hpos: Vector2 = h.get("pos", global_position + _swing_dir * 28.0)
			var dmg: int = int(h.get("damage", attack_damage))
			var contact_pos := global_position.lerp(hpos, 0.72)
			_spawn_combat_fx("hit", contact_pos, "-%d" % dmg, Color("#FFF3B0"))
			attack_hit_landed.emit(contact_pos, dmg)

func _apply_water_to_scene_targets(dir: Vector2) -> void:
	var any_water_hit := false
	for node in get_tree().get_nodes_in_group("water_target"):
		if not is_instance_valid(node):
			continue
		if node.has_method("query_water_hit"):
			var hits: Variant = node.call("query_water_hit", global_position, dir, 64.0, 110.0, 35)
			if typeof(hits) == TYPE_ARRAY and not (hits as Array).is_empty():
				any_water_hit = true
				for h in (hits as Array):
					if typeof(h) == TYPE_DICTIONARY:
						var hpos: Vector2 = h.get("pos", global_position + dir * 36.0)
						var label_txt: String = str(h.get("label", "-35"))
						_spawn_combat_fx("water_hit", hpos, label_txt, Color("#90E0EF"))
		elif node is Node2D:
			var target_2d := node as Node2D
			if is_point_in_attack_cone(global_position, dir, target_2d.global_position, 18.0, 64.0, 110.0):
				if target_2d.has_method("receive_water_hit"):
					target_2d.call("receive_water_hit", 35, global_position)
					any_water_hit = true
					_spawn_combat_fx("water_hit", target_2d.global_position, "-35", Color("#90E0EF"))
	if not any_water_hit:
		_spawn_combat_fx("miss", global_position + dir * 42.0, "", Color(0.56, 0.88, 0.96, 0.65))

func _spawn_combat_fx(kind: String, world_pos: Vector2, text: String, col: Color) -> void:
	_combat_fx.append({
		"kind": kind,
		"world_pos": world_pos,
		"text": text,
		"color": col,
		"timer": 0.0,
		"duration": 0.34 if kind != "miss" else 0.22
	})

func _physics_process(delta: float) -> void:
	if _interact_cooldown > 0.0:
		_interact_cooldown -= delta
	if _attack_cooldown > 0.0:
		_attack_cooldown -= delta

	# Atualiza janela ativa da animação do ataque corpo a corpo
	if _attack_anim_timer > 0.0:
		_attack_anim_timer -= delta
		if _attack_anim_timer > 0.04:
			_evaluate_active_melee_hitbox()
		elif not _swing_landed_hit and not _swing_miss_registered:
			_swing_miss_registered = true
			var miss_pos := global_position + _swing_dir * (attack_radius * 0.78)
			_spawn_combat_fx("miss", miss_pos, "", Color(0.85, 0.88, 0.94, 0.55))
			attack_missed.emit(miss_pos)

	if _jump_timer > 0.0:
		_jump_timer -= delta
		var jp := 1.0 - clampf(_jump_timer / JUMP_DURATION, 0.0, 1.0)
		_jump_height = sin(jp * PI) * 14.0
		if _jump_timer <= 0.0:
			is_jumping = false
			_jump_height = 0.0
	else:
		is_jumping = false
		_jump_height = 0.0

	if _water_anim_timer > 0.0:
		_water_anim_timer -= delta
	if _hurt_timer > 0.0:
		_hurt_timer -= delta

	# Atualiza partículas de feedback de combate (hit sparks / miss wisps)
	for i in range(_combat_fx.size() - 1, -1, -1):
		var fx: Dictionary = _combat_fx[i]
		fx["timer"] = float(fx["timer"]) + delta
		if float(fx["timer"]) >= float(fx["duration"]):
			_combat_fx.remove_at(i)

	if GameState.dialogue_active:
		velocity = Vector2.ZERO
		is_moving = false
		is_running = false
		is_crouching = false
		if prompt_label:
			prompt_label.visible = false
		_update_character_sprite_state()
		queue_redraw()
		return

	var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if Input.is_key_pressed(KEY_A):
		direction.x -= 1.0
	if Input.is_key_pressed(KEY_D):
		direction.x += 1.0
	if Input.is_key_pressed(KEY_W):
		direction.y -= 1.0
	if Input.is_key_pressed(KEY_S):
		direction.y += 1.0

	is_crouching = (Input.is_key_pressed(KEY_CTRL) or Input.is_key_pressed(KEY_X)) and not is_jumping and _attack_anim_timer <= 0.0
	is_running = Input.is_key_pressed(KEY_SHIFT) and not is_crouching

	if direction.length_squared() > 0.001 and not is_crouching:
		direction = direction.normalized()
		if _attack_anim_timer <= 0.0:
			facing_dir = direction
			if absf(direction.x) > 0.08:
				_facing_left = (direction.x < 0.0)
		is_moving = true
		walk_time += delta * (13.0 if is_running else 9.0)
		_update_interaction_offset()
	else:
		direction = Vector2.ZERO
		is_moving = false
		walk_time += delta * 2.0

	_knockback_vel = _knockback_vel.move_toward(Vector2.ZERO, 650.0 * delta)
	var move_mult := 0.55 if _attack_anim_timer > 0.0 else (run_speed_multiplier if is_running else 1.0)
	velocity = direction * (speed * move_mult) + _knockback_vel
	move_and_slide()

	_refresh_prompt()
	if _is_interact_just_pressed() and _interact_cooldown <= 0.0:
		var target := get_best_interactable()
		if target != null:
			_interact_cooldown = 0.25
			target.trigger_interaction()

	var attack_down := Input.is_key_pressed(KEY_J) or Input.is_key_pressed(KEY_SPACE)
	var water_down := Input.is_key_pressed(KEY_K) or Input.is_key_pressed(KEY_Q)
	var outfit_down := Input.is_key_pressed(KEY_U)
	var jump_down := Input.is_key_pressed(KEY_V) or Input.is_key_pressed(KEY_ALT)
	if attack_down and not _was_attack_key_down:
		perform_melee_attack()
	elif jump_down and not _was_jump_key_down:
		perform_jump()
	elif water_down and not _was_water_key_down:
		perform_water_skill()
	elif outfit_down and not _was_outfit_key_down:
		GameState.toggle_outfit()
	elif _is_heal_just_pressed() and _interact_cooldown <= 0.0:
		if GameState.use_soothing_drop():
			_interact_cooldown = 0.3
	_was_attack_key_down = attack_down
	_was_water_key_down = water_down
	_was_outfit_key_down = outfit_down
	_was_jump_key_down = jump_down

	_update_character_sprite_state()
	queue_redraw()

func _update_character_sprite_state() -> void:
	if character_sprite == null or character_sprite.sprite_frames == null:
		return

	_ensure_correct_outfit_sheet()

	var active_dir := _swing_dir if _attack_anim_timer > 0.0 else facing_dir
	var dir_str := "down"
	if absf(active_dir.x) > absf(active_dir.y) * 1.05:
		dir_str = "left" if active_dir.x < 0.0 else "right"
	else:
		dir_str = "up" if active_dir.y < 0.0 else "down"

	character_sprite.flip_h = false
	character_sprite.position = Vector2(0.0, -_jump_height + (2.0 if is_crouching else 0.0))
	character_sprite.offset = Vector2(0.0, -8.0)

	var act3 := GameState.is_unfiltered_act3()
	var hurt_flash: bool = _hurt_timer > 0.0 and int(_hurt_timer * 20.0) % 2 == 0
	if hurt_flash:
		character_sprite.modulate = Color(1.0, 0.45, 0.45, 1.0)
	elif act3:
		character_sprite.modulate = Color(0.76, 0.77, 0.80, 1.0)
	else:
		character_sprite.modulate = Color.WHITE

	var base_anim := "idle"
	if _attack_anim_timer > 0.0:
		base_anim = "attack"
	elif is_jumping:
		base_anim = "jump"
	elif is_crouching:
		base_anim = "crouch"
	elif is_moving:
		base_anim = "run" if is_running else "walk"

	var full_anim := "%s_%s" % [base_anim, dir_str]
	if character_sprite.sprite_frames.has_animation(full_anim):
		if character_sprite.animation != full_anim:
			character_sprite.play(full_anim)
	elif character_sprite.sprite_frames.has_animation(base_anim):
		if character_sprite.animation != base_anim:
			character_sprite.play(base_anim)

func _is_interact_just_pressed() -> bool:
	return Input.is_action_just_pressed("interact")

func _is_heal_just_pressed() -> bool:
	return Input.is_key_pressed(KEY_H) or Input.is_key_pressed(KEY_C)

func _update_interaction_offset() -> void:
	if interaction_area:
		interaction_area.position = facing_dir.normalized() * 14.0

func _on_interaction_area_entered(area: Area2D) -> void:
	if area is Interactable and not _nearby_interactables.has(area):
		_nearby_interactables.append(area)
		_refresh_prompt()

func _on_interaction_area_exited(area: Area2D) -> void:
	if area is Interactable:
		_nearby_interactables.erase(area)
		_refresh_prompt()

func get_best_interactable() -> Interactable:
	var best: Interactable = null
	var best_dist: float = INF
	for item in _nearby_interactables:
		if is_instance_valid(item) and item.can_interact():
			var d := global_position.distance_squared_to(item.global_position)
			if d < best_dist:
				best_dist = d
				best = item
	return best

func _refresh_prompt() -> void:
	var best := get_best_interactable()
	if prompt_label == null:
		return
	if best != null and not GameState.dialogue_active:
		prompt_label.text = best.get_prompt_text()
		prompt_label.reset_size()
		prompt_label.position = Vector2(-prompt_label.size.x * 0.5, -36.0)
		prompt_label.visible = true
		nearby_interactable_changed.emit(prompt_label.text)
	else:
		prompt_label.visible = false
		nearby_interactable_changed.emit("")

func get_direction_row(dir_vec: Vector2 = facing_dir) -> int:
	if absf(dir_vec.x) > absf(dir_vec.y) * 1.05:
		return 1 if dir_vec.x < 0.0 else 2
	return 3 if dir_vec.y < 0.0 else 0

func get_current_sheet_cell() -> Vector2i:
	var active_dir := _swing_dir if _attack_anim_timer > 0.0 else facing_dir
	var row := get_direction_row(active_dir)
	var col := 0
	if _attack_anim_timer > 0.0:
		var p := 1.0 - clampf(_attack_anim_timer / ATTACK_DURATION, 0.0, 1.0)
		col = 6 + clampi(int(p * 4.0), 0, 3)
	elif is_moving:
		col = 2 + (int(floor(walk_time * 1.15)) % 4)
	else:
		col = int(floor(walk_time * 0.8)) % 2
	return Vector2i(col, row)

func _draw() -> void:
	# Sombra elíptica ancorada aos pés no chão
	var shadow_scale := clampf(1.0 - (_jump_height / 28.0), 0.55, 1.0)
	draw_Rect_ellipse(Vector2(0, 9.5), Vector2(10.0, 4.0) * shadow_scale, Color(0.03, 0.03, 0.07, 0.42))

	if _attack_anim_timer > 0.0:
		_draw_melee_arc()
	if _water_anim_timer > 0.0:
		_draw_water_stream()

	_draw_combat_feedback_fx()

func _draw_melee_arc() -> void:
	var progress := 1.0 - clampf(_attack_anim_timer / ATTACK_DURATION, 0.0, 1.0)
	var base_angle := _swing_dir.angle()
	var half_arc := deg_to_rad(attack_arc_degrees * 0.5)
	var sweep_start := base_angle - half_arc
	var sweep_end := base_angle + half_arc

	var outer_pts := PackedVector2Array()
	var inner_pts := PackedVector2Array()
	var steps := 12
	var inner_r := attack_radius * lerpf(0.32, 0.58, progress)
	for i in range(steps + 1):
		var t := float(i) / float(steps)
		var a := lerpf(sweep_start, sweep_end, t)
		outer_pts.append(Vector2(cos(a), sin(a)) * attack_radius)
		inner_pts.append(Vector2(cos(a), sin(a)) * inner_r)

	var crescent := PackedVector2Array()
	for p in outer_pts:
		crescent.append(p)
	for i in range(inner_pts.size() - 1, -1, -1):
		crescent.append(inner_pts[i])

	var alpha := clampf(1.0 - progress * 0.65, 0.2, 1.0)
	var fill_col := (
		Color(1.0, 0.94, 0.55, 0.56 * alpha)
		if _swing_landed_hit else
		Color(0.88, 0.94, 1.0, 0.34 * alpha)
	)
	var edge_col := (
		Color(1.0, 0.98, 0.85, 0.95 * alpha)
		if _swing_landed_hit else
		Color(0.92, 0.96, 1.0, 0.80 * alpha)
	)
	draw_colored_polygon(crescent, fill_col)
	draw_polyline(outer_pts, edge_col, 2.2 if _swing_landed_hit else 1.6)

	var blade_angle := lerpf(sweep_start, sweep_end, clampf(progress * 1.25, 0.0, 1.0))
	var blade_tip := Vector2(cos(blade_angle), sin(blade_angle)) * attack_radius
	draw_line(Vector2(cos(blade_angle), sin(blade_angle)) * 10.0, blade_tip, edge_col, 2.4)

func _draw_water_stream() -> void:
	var dir := facing_dir.normalized()
	var perp := Vector2(-dir.y, dir.x)
	var p1 := dir * 10.0 - perp * 5.0
	var p2 := dir * 60.0 - perp * 15.0
	var p3 := dir * 60.0 + perp * 15.0
	var p4 := dir * 10.0 + perp * 5.0
	draw_colored_polygon(PackedVector2Array([p1, p2, p3, p4]), Color(0.3, 0.82, 0.96, 0.65))
	draw_circle(dir * 50.0, 10.0, Color(0.75, 0.95, 1.0, 0.82))

func _draw_combat_feedback_fx() -> void:
	var font_to_use: Font = _pixel_font if _pixel_font != null else ThemeDB.fallback_font
	for fx in _combat_fx:
		var kind: String = str(fx["kind"])
		var t: float = float(fx["timer"]) / maxf(0.01, float(fx["duration"]))
		var local_pos: Vector2 = (fx["world_pos"] as Vector2) - global_position
		var col: Color = fx["color"]
		var alpha := clampf(1.0 - t, 0.0, 1.0)

		if kind == "hit" or kind == "water_hit":
			var burst_r := lerpf(4.0, 15.0, t)
			draw_arc(local_pos, burst_r, 0.0, TAU, 16, Color(col.r, col.g, col.b, alpha * 0.85), 1.8)
			for i in range(4):
				var a := float(i) * PI * 0.5 + PI * 0.25
				var p_in := local_pos + Vector2(cos(a), sin(a)) * (burst_r * 0.45)
				var p_out := local_pos + Vector2(cos(a), sin(a)) * (burst_r * 1.15)
				draw_line(p_in, p_out, Color(1.0, 1.0, 1.0, alpha), 1.6)
			var txt: String = str(fx["text"])
			if not txt.is_empty() and font_to_use != null:
				var text_pos := local_pos + Vector2(-10.0, -8.0 - t * 14.0)
				draw_string_outline(font_to_use, text_pos, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, 3, Color(0.06, 0.05, 0.10, alpha))
				draw_string(font_to_use, text_pos, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(col.r, col.g, col.b, alpha))
		elif kind == "hurt":
			var txt_h: String = str(fx["text"])
			if not txt_h.is_empty() and font_to_use != null:
				var text_pos := local_pos + Vector2(-10.0, -6.0 - t * 12.0)
				draw_string_outline(font_to_use, text_pos, txt_h, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, 3, Color(0.06, 0.05, 0.10, alpha))
				draw_string(font_to_use, text_pos, txt_h, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(1.0, 0.42, 0.42, alpha))
		elif kind == "miss":
			var wisp_r := lerpf(3.0, 9.0, t)
			draw_arc(local_pos, wisp_r, -0.8, 0.8, 8, Color(col.r, col.g, col.b, alpha * 0.55), 1.4)

func draw_Rect_ellipse(center: Vector2, radii: Vector2, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in range(14):
		var angle: float = TAU * float(i) / 14.0
		pts.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	draw_colored_polygon(pts, col)
