extends CharacterBody2D
class_name PlayerController

signal nearby_interactable_changed(prompt: String)
signal melee_attack_performed(origin: Vector2, facing: Vector2, radius: float, arc_deg: float, damage: int)
signal combo_attack_performed(stage: int, origin: Vector2, facing: Vector2, damage: int)
signal dodge_performed(origin: Vector2, dir: Vector2)
signal water_skill_performed(origin: Vector2, facing: Vector2, range_dist: float, damage: int)
signal attack_hit_landed(hit_pos: Vector2, damage: int)
signal attack_missed(miss_pos: Vector2)
signal player_died()

@export var speed: float = 135.0
@export var run_speed_multiplier: float = 1.42
@export var attack_damage: int = 25
@export var attack_radius: float = 50.0
@export var attack_arc_degrees: float = 135.0

@export_group("Outfit & Visuals")
@export_enum("casual", "bfp", "bombeiro") var outfit: String = "casual":
	set(value):
		set_outfit(value)
	get:
		var gs := _get_game_state()
		return str(gs.get("equipped_outfit")) if gs != null else _local_outfit

@export_group("Animation Speeds")
@export var idle_fps: float = 5.0
@export var walk_fps: float = 9.5
@export var run_fps: float = 12.5
@export var attack_fps: float = 15.0
@export var combo_fps: float = 16.0
@export var dodge_fps: float = 14.0
@export var hurt_fps: float = 10.0
@export var death_fps: float = 8.0

@export_group("Combat & Combo System")
@export var combo_max_stages: int = 3
@export var combo_window: float = 0.65
@export var combo2_damage_multiplier: float = 1.28
@export var combo3_damage_multiplier: float = 1.80
@export var dodge_speed: float = 275.0
@export var dodge_duration: float = 0.25
@export var dodge_cooldown_time: float = 0.46
@export var dodge_invulnerability: float = 0.36

@export_group("Rotate Towards Mouse")
@export var rotate_towards_mouse: bool = true
@export var mouse_controls_combat: bool = true
@export var mouse_rotation_smooth: bool = false
@export var mouse_rotation_speed: float = 14.0
@export var mouse_aim_deadzone: float = 8.0

@onready var character_sprite: AnimatedSprite2D = $CharacterSprite
@onready var visual: Polygon2D = $Visual
@onready var interaction_area: Area2D = $InteractionArea
@onready var prompt_label: Label = $PromptLabel
@onready var camera: Camera2D = $Camera2D
@onready var aim_pivot: RotateTowardsMouse = get_node_or_null("AimPivot") as RotateTowardsMouse

var facing_dir: Vector2 = Vector2.DOWN
var walk_time: float = 0.0
var is_moving: bool = false
var is_running: bool = false
var is_crouching: bool = false
var is_jumping: bool = false
var is_dodging: bool = false
var is_dead: bool = false
var combo_stage: int = 0

var _local_outfit: String = "casual"
var _facing_left: bool = false
var _nearby_interactables: Array[Interactable] = []
var _interact_cooldown: float = 0.0
var _has_mouse_input: bool = false
var _override_mouse_pos: Variant = null

# Estado de combate, combos, esquiva e reações (J-ABS / Top-Down Action)
const ATTACK_DURATION := 0.26
const JUMP_DURATION := 0.42
var _attack_cooldown: float = 0.0
var _attack_anim_timer: float = 0.0
var _combo_reset_timer: float = 0.0
var _active_attack_damage: int = 25
var _active_attack_radius: float = 50.0
var _active_attack_arc: float = 135.0
var _attack_lunge_vel: Vector2 = Vector2.ZERO

var _dodge_timer: float = 0.0
var _dodge_cooldown: float = 0.0
var _dodge_invuln_timer: float = 0.0
var _dodge_dir: Vector2 = Vector2.DOWN

var _water_anim_timer: float = 0.0
var _jump_timer: float = 0.0
var _jump_height: float = 0.0
var _hurt_timer: float = 0.0
var _hurt_anim_timer: float = 0.0
var _death_anim_timer: float = 0.0
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
var _was_dodge_key_down: bool = false
var _was_interact_key_down: bool = false

# Spritesheets pixel art reconstruídos (huwag_v3, célula 48x48, escala 1:1 nítida)
const HUWAG_V3_SPRITEFRAMES := {
	"casual": "res://assets/sprites/huwag_v3/casual/huwag_casual_spriteframes.tres",
	"bfp": "res://assets/sprites/huwag_v3/bombeiro/huwag_bombeiro_spriteframes.tres",
}
const HUWAG_V2_SPRITEFRAMES := {
	"casual": "res://assets/sprites/huwag_v3/casual/huwag_casual_spriteframes.tres",
	"bfp": "res://assets/sprites/huwag_v3/bombeiro/huwag_bombeiro_spriteframes.tres",
}
const SPRITE_V2_SCALE := Vector2(1.0, 1.0)
const SPRITE_V2_OFFSET := Vector2(0.0, -7.0)
const SPRITE_V2_POS_Y := 0.0

const HERO_CELL_SIZE := Vector2i(48, 48)
const SHEET_CELL_SIZE := Vector2i(48, 48)
var _v2_frames_cache: Dictionary = {}
var _using_v2_sprites: bool = false
var _sheet_casual: Texture2D = null
var _sheet_bfp: Texture2D = null
var _pixel_font: Font = null

# Efeitos visuais de feedback (acerto / erro / dano flutuante / esquiva)
var _combat_fx: Array[Dictionary] = []


func _ready() -> void:
	add_to_group("player")
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	collision_layer = 2
	collision_mask = 1
	if ResourceLoader.exists("res://assets/fonts/undertale-deltarune-extended-fixed.otf"):
		_pixel_font = load("res://assets/fonts/undertale-deltarune-extended-fixed.otf") as Font
	for key in HUWAG_V3_SPRITEFRAMES.keys():
		var tres_path: String = str(HUWAG_V3_SPRITEFRAMES[key])
		if ResourceLoader.exists(tres_path):
			_v2_frames_cache[key] = load(tres_path) as SpriteFrames
	if ResourceLoader.exists("res://assets/characters/sprites/huwag_casual_sheet.png"):
		_sheet_casual = load("res://assets/characters/sprites/huwag_casual_sheet.png") as Texture2D
	if ResourceLoader.exists("res://assets/characters/sprites/huwag_bfp_sheet.png"):
		_sheet_bfp = load("res://assets/characters/sprites/huwag_bfp_sheet.png") as Texture2D

	_setup_character_sprite_frames()

	var gs_init := _get_game_state()
	if gs_init != null and gs_init.has_signal("outfit_changed"):
		gs_init.connect("outfit_changed", func(_o: String) -> void:
			_update_character_sprite_state()
			queue_redraw()
		)
	if visual:
		visual.visible = false
	if interaction_area:
		interaction_area.area_entered.connect(_on_interaction_area_entered)
		interaction_area.area_exited.connect(_on_interaction_area_exited)
	if aim_pivot:
		aim_pivot.enabled = rotate_towards_mouse
		aim_pivot.smooth = mouse_rotation_smooth
		aim_pivot.rotation_speed = mouse_rotation_speed
		aim_pivot.deadzone = mouse_aim_deadzone
	_style_prompt_label()
	_update_interaction_offset()
	_refresh_prompt()


func _get_game_state() -> Node:
	return get_node_or_null("/root/GameState") if is_inside_tree() else null


func _is_dialogue_active() -> bool:
	var gs := _get_game_state()
	return gs != null and (bool(gs.get("dialogue_active")) or bool(gs.get("sleep_transition_active")))


func _is_interaction_blocked() -> bool:
	var gs := _get_game_state()
	if gs != null and gs.has_method("is_interaction_blocked"):
		return bool(gs.call("is_interaction_blocked"))
	return _is_dialogue_active() or _interact_cooldown > 0.0


func set_outfit(new_outfit: String, persist_save: bool = false) -> void:
	var normalized := "bfp" if new_outfit.strip_edges().to_lower() in ["bfp", "bombeiro", "firefighter"] else "casual"
	_local_outfit = normalized
	var gs := _get_game_state()
	if gs != null:
		gs.call("set_equipped_outfit", normalized, persist_save)
	_ensure_correct_outfit_sheet()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion or event is InputEventMouseButton:
		_has_mouse_input = true
		if aim_pivot:
			aim_pivot._is_mouse_active = true


var _current_sheet_outfit: String = ""


func _ensure_correct_outfit_sheet() -> void:
	var gs := _get_game_state()
	var needed_outfit: String = str(gs.get("equipped_outfit")) if gs != null else _local_outfit
	needed_outfit = "bfp" if needed_outfit == "bfp" else "casual"
	if _current_sheet_outfit == needed_outfit:
		return
	_current_sheet_outfit = needed_outfit
	_setup_character_sprite_frames()


func _setup_character_sprite_frames() -> void:
	if character_sprite == null:
		character_sprite = get_node_or_null("CharacterSprite") as AnimatedSprite2D
	if character_sprite == null:
		return

	# Preserva animação e frame atual ao trocar de roupa sem "pular"
	var prev_anim: StringName = character_sprite.animation
	var prev_frame: int = character_sprite.frame
	var prev_progress: float = character_sprite.frame_progress

	var gs := _get_game_state()
	var raw_outfit := str(gs.get("equipped_outfit")) if gs != null else _local_outfit
	var outfit_key := "bfp" if raw_outfit == "bfp" else "casual"
	_current_sheet_outfit = outfit_key
	var v3_sf := _v2_frames_cache.get(outfit_key, null) as SpriteFrames
	if v3_sf == null:
		var tres_path: String = str(HUWAG_V3_SPRITEFRAMES.get(outfit_key, ""))
		if not tres_path.is_empty() and ResourceLoader.exists(tres_path):
			v3_sf = load(tres_path) as SpriteFrames
			_v2_frames_cache[outfit_key] = v3_sf

	if v3_sf != null:
		_using_v2_sprites = true
		_apply_configured_fps(v3_sf)
		character_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		character_sprite.sprite_frames = v3_sf
		character_sprite.scale = SPRITE_V2_SCALE
		character_sprite.offset = SPRITE_V2_OFFSET
		character_sprite.position = Vector2(0.0, SPRITE_V2_POS_Y)
		var target_anim := String(prev_anim) if (not prev_anim.is_empty() and v3_sf.has_animation(prev_anim)) else "idle_down"
		character_sprite.play(target_anim)
		if prev_frame < v3_sf.get_frame_count(target_anim):
			character_sprite.set_frame_and_progress(prev_frame, prev_progress)
		return

	_using_v2_sprites = false
	var path := "res://assets/characters/sprites/huwag_bfp_sheet.png" if outfit_key == "bfp" else "res://assets/characters/sprites/huwag_casual_sheet.png"
	var tex := load(path) as Texture2D
	if tex == null:
		return

	var sf := SpriteFrames.new()
	if sf.has_animation("default"):
		sf.remove_animation("default")

	var dirs := ["down", "left", "right", "up"]
	for r in range(4):
		var dname: String = dirs[r]
		_add_rect_animation(sf, "idle_%s" % dname, tex, r, 0, 2, idle_fps, true)
		_add_rect_animation(sf, "walk_%s" % dname, tex, r, 2, 4, walk_fps, true)
		_add_rect_animation(sf, "run_%s" % dname, tex, r, 2, 4, run_fps, true)
		_add_rect_animation(sf, "attack_%s" % dname, tex, r, 6, 4, attack_fps, false)
		_add_rect_animation(sf, "crouch_%s" % dname, tex, r, 1, 1, 6.0, true)
		_add_rect_animation(sf, "jump_%s" % dname, tex, r, 2, 1, 6.0, false)

	_add_rect_animation(sf, "idle", tex, 0, 0, 2, idle_fps, true)
	_add_rect_animation(sf, "walk", tex, 0, 2, 4, walk_fps, true)
	_add_rect_animation(sf, "run", tex, 0, 2, 4, run_fps, true)
	_add_rect_animation(sf, "attack", tex, 0, 6, 4, attack_fps, false)
	_add_rect_animation(sf, "crouch", tex, 0, 1, 1, 6.0, true)
	_add_rect_animation(sf, "jump", tex, 0, 2, 1, 6.0, false)

	character_sprite.sprite_frames = sf
	character_sprite.scale = Vector2.ONE
	character_sprite.offset = Vector2(0.0, -7.0)
	character_sprite.position = Vector2.ZERO
	character_sprite.play("idle_down")


func _apply_configured_fps(sf: SpriteFrames) -> void:
	if sf == null:
		return
	for anim in sf.get_animation_names():
		var a_str := String(anim)
		if a_str.begins_with("idle"):
			sf.set_animation_speed(anim, idle_fps)
		elif a_str.begins_with("walk"):
			sf.set_animation_speed(anim, walk_fps)
		elif a_str.begins_with("run"):
			sf.set_animation_speed(anim, run_fps)
		elif a_str.begins_with("attack"):
			sf.set_animation_speed(anim, attack_fps)
		elif a_str.begins_with("combo"):
			sf.set_animation_speed(anim, combo_fps)
		elif a_str.begins_with("dodge"):
			sf.set_animation_speed(anim, dodge_fps)
		elif a_str.begins_with("hurt"):
			sf.set_animation_speed(anim, hurt_fps)
		elif a_str.begins_with("death"):
			sf.set_animation_speed(anim, death_fps)


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
	prompt_label.add_theme_stylebox_override("normal", HuwagUiTheme.make_omori_box_style(Color(0.0, 0.0, 0.0, 0.96), Color.WHITE, 6, 3))
	var ui_font := HuwagUiTheme.get_ui_font()
	if ui_font != null:
		prompt_label.add_theme_font_override("font", ui_font)
	prompt_label.add_theme_font_size_override("font_size", 13)
	prompt_label.add_theme_color_override("font_color", Color.WHITE)


func set_camera_limits(bounds: Rect2i) -> void:
	if camera == null:
		camera = get_node_or_null("Camera2D") as Camera2D
	if camera:
		camera.limit_smoothed = false
		camera.limit_left = bounds.position.x
		camera.limit_top = bounds.position.y
		camera.limit_right = bounds.position.x + bounds.size.x
		camera.limit_bottom = bounds.position.y + bounds.size.y
		camera.reset_smoothing()
		camera.force_update_scroll()


func apply_hit(damage_or_from: Variant, from_or_damage: Variant = null) -> void:
	if not is_inside_tree() or is_queued_for_deletion() or is_dead:
		return
	if _dodge_invuln_timer > 0.0:
		_spawn_combat_fx("dodge", global_position + Vector2(0, -16), "ESQUIVA!", Color("#A8D8FF"))
		queue_redraw()
		return
	if _hurt_timer > 0.0:
		return

	var damage: int = 12
	var from_pos: Vector2 = global_position - facing_dir * 12.0
	if typeof(damage_or_from) == TYPE_VECTOR2:
		from_pos = damage_or_from as Vector2
		if typeof(from_or_damage) == TYPE_INT or typeof(from_or_damage) == TYPE_FLOAT:
			damage = int(from_or_damage)
	else:
		if typeof(damage_or_from) == TYPE_INT or typeof(damage_or_damage_valid(damage_or_from)):
			damage = int(damage_or_from)
		if typeof(from_or_damage) == TYPE_VECTOR2:
			from_pos = from_or_damage as Vector2

	_hurt_timer = 0.75
	_hurt_anim_timer = 0.28
	var push_dir := (global_position - from_pos).normalized()
	if push_dir.length_squared() < 0.01:
		push_dir = -facing_dir
	_knockback_vel = push_dir * 190.0

	var gs := _get_game_state()
	if gs != null:
		var prev_hp := int(gs.get("player_hp"))
		gs.call("damage_player", damage)
		var cur_hp := int(gs.get("player_hp"))
		var max_hp := int(gs.get("player_max_hp"))
		print("[PlayerController] Dano recebido: -%d HP (HP atual: %d/%d)" % [damage, cur_hp, max_hp])
		if prev_hp - damage <= 0 or cur_hp <= 0:
			trigger_death()
			return

	CombatSfx.play(self, "player_hurt", -5.0)
	_spawn_combat_fx("hurt", global_position + Vector2(0, -14), "-%d" % damage, Color("#FF595E"))
	_update_character_sprite_state()
	queue_redraw()


func damage_or_damage_valid(v: Variant) -> bool:
	return typeof(v) == TYPE_INT or typeof(v) == TYPE_FLOAT


var _local_stamina: float = 100.0
var _stamina_regen_delay: float = 0.0
var _stamina_exhausted: bool = false
const STAMINA_MAX: float = 100.0
const STAMINA_RUN_DRAIN: float = 28.0
const STAMINA_DODGE_COST: float = 22.0
const STAMINA_ATTACK_COSTS: Array[float] = [10.0, 12.0, 14.0]
const STAMINA_REGEN_IDLE: float = 40.0
const STAMINA_REGEN_WALK: float = 26.0
const STAMINA_RECOVER_THRESHOLD: float = 20.0


func get_stamina() -> float:
	var gs := _get_game_state()
	if gs != null and gs.get("player_stamina") != null:
		return float(gs.get("player_stamina"))
	return _local_stamina


func get_max_stamina() -> float:
	var gs := _get_game_state()
	if gs != null and gs.get("player_max_stamina") != null:
		return maxf(1.0, float(gs.get("player_max_stamina")))
	return STAMINA_MAX


func _spend_stamina(amount: float) -> void:
	if amount <= 0.0:
		return
	var gs := _get_game_state()
	if gs != null and gs.has_method("consume_stamina"):
		gs.call("consume_stamina", amount)
		_local_stamina = get_stamina()
	else:
		_local_stamina = clampf(_local_stamina - amount, 0.0, STAMINA_MAX)
	_stamina_regen_delay = 0.48
	if _local_stamina <= 0.5:
		_stamina_exhausted = true


func _regen_stamina(delta: float) -> void:
	if _stamina_regen_delay > 0.0:
		_stamina_regen_delay = maxf(0.0, _stamina_regen_delay - delta)
		return
	var rate := STAMINA_REGEN_WALK if is_moving else STAMINA_REGEN_IDLE
	var gain := rate * delta
	var gs := _get_game_state()
	if gs != null and gs.has_method("recover_stamina"):
		gs.call("recover_stamina", gain)
		_local_stamina = get_stamina()
	else:
		_local_stamina = clampf(_local_stamina + gain, 0.0, STAMINA_MAX)
	if _stamina_exhausted and _local_stamina >= STAMINA_RECOVER_THRESHOLD:
		_stamina_exhausted = false


func trigger_death() -> void:
	if is_dead:
		return
	is_dead = true
	_death_anim_timer = 0.85
	_attack_anim_timer = 0.0
	_dodge_timer = 0.0
	_jump_timer = 0.0
	_jump_height = 0.0
	is_dodging = false
	is_jumping = false
	is_moving = false
	is_running = false
	is_crouching = false
	velocity = Vector2.ZERO
	_attack_lunge_vel = Vector2.ZERO
	_knockback_vel = Vector2.ZERO
	_combat_fx.clear()
	if prompt_label:
		prompt_label.visible = false
	var gs := _get_game_state()
	if gs != null:
		if int(gs.get("player_hp")) > 0:
			gs.set("player_hp", 0)
			if gs.has_signal("hp_changed"):
				gs.emit_signal("hp_changed", 0, int(gs.get("player_max_hp")))
		gs.set("is_player_defeated", true)
	CombatSfx.play(self, "player_hurt", -3.0)
	_update_character_sprite_state()
	player_died.emit()
	queue_redraw()


func revive(restore_hp: int = -1) -> void:
	is_dead = false
	_death_anim_timer = 0.0
	_hurt_timer = 0.4
	_hurt_anim_timer = 0.0
	var gs := _get_game_state()
	if gs != null:
		gs.set("is_player_defeated", false)
		var max_hp := int(gs.get("player_max_hp"))
		var target_hp := restore_hp if restore_hp > 0 else maxi(1, int(max_hp * 0.5))
		var final_hp := clampi(target_hp, 1, max_hp)
		gs.set("player_hp", final_hp)
		if gs.has_signal("hp_changed"):
			gs.emit_signal("hp_changed", final_hp, max_hp)
		if gs.has_method("reset_stamina"):
			gs.call("reset_stamina")
	_local_stamina = STAMINA_MAX
	_stamina_exhausted = false
	_stamina_regen_delay = 0.0
	_update_character_sprite_state()
	queue_redraw()


func take_damage(amount: int, from_pos: Vector2 = Vector2.ZERO) -> void:
	apply_hit(amount, from_pos if from_pos != Vector2.ZERO else (global_position - facing_dir * 12.0))


func receive_damage(amount: int, from_pos: Vector2 = Vector2.ZERO) -> void:
	take_damage(amount, from_pos)


func perform_dodge(custom_dir: Vector2 = Vector2.ZERO) -> bool:
	if is_dead or is_dodging or _dodge_cooldown > 0.0 or _is_dialogue_active():
		return false
	if get_stamina() < 12.0:
		_spawn_combat_fx("hurt", global_position + Vector2(0, -14), "EXAUSTO", Color("#F5C84B"))
		return false
	_spend_stamina(STAMINA_DODGE_COST)
	is_dodging = true
	_dodge_timer = dodge_duration
	_dodge_cooldown = dodge_cooldown_time
	_dodge_invuln_timer = dodge_invulnerability
	_attack_anim_timer = 0.0

	var d := custom_dir.normalized() if custom_dir.length_squared() > 0.01 else facing_dir.normalized()
	if d.length_squared() < 0.01:
		d = Vector2.DOWN
	_dodge_dir = d
	facing_dir = d
	if absf(d.x) > 0.15:
		_facing_left = (d.x < 0.0)

	CombatSfx.play(self, "swing_miss", -10.5)
	if VfxLibrary.spawn_burst(self, "impact_dust", global_position + Vector2(0, 6), {
		"scale": Vector2(0.42, 0.42),
		"modulate": _get_vfx_tint(Color(0.85, 0.86, 0.92, 0.55)),
		"z_index": 3,
	}) == null:
		_spawn_combat_fx("dodge_ghost", global_position, "", Color(0.66, 0.85, 1.0, 0.55))
	dodge_performed.emit(global_position, _dodge_dir)
	_update_character_sprite_state()
	queue_redraw()
	return true


func perform_jump() -> bool:
	if is_dead or is_jumping or _attack_anim_timer > 0.0 or _is_dialogue_active():
		return false
	is_jumping = true
	_jump_timer = JUMP_DURATION
	CombatSfx.play(self, "swing_miss", -12.0)
	_update_character_sprite_state()
	return true


func perform_melee_attack() -> bool:
	if is_dead or _is_dialogue_active():
		return false
	# Permite encadear próximo estágio do combo nos instantes finais do golpe anterior
	var can_chain := _combo_reset_timer > 0.0 and combo_stage > 0 and combo_stage < combo_max_stages and _attack_cooldown <= 0.14
	if _attack_cooldown > 0.0 and not can_chain:
		return false
	if combo_stage == 0 and _stamina_exhausted and get_stamina() < 10.0:
		_spawn_combat_fx("hurt", global_position + Vector2(0, -14), "SEM FÔLEGO", Color("#F5C84B"))
		return false

	if _combo_reset_timer > 0.0 and combo_stage > 0 and combo_stage < combo_max_stages:
		combo_stage += 1
	else:
		combo_stage = 1
	var atk_cost: float = STAMINA_ATTACK_COSTS[clampi(combo_stage - 1, 0, STAMINA_ATTACK_COSTS.size() - 1)]
	_spend_stamina(atk_cost)

	_combo_reset_timer = combo_window
	_swing_dir = facing_dir.normalized()
	if _swing_dir.length_squared() < 0.01:
		_swing_dir = Vector2.DOWN
	if absf(_swing_dir.x) > 0.15:
		_facing_left = (_swing_dir.x < 0.0)

	match combo_stage:
		1:
			_active_attack_damage = attack_damage
			_active_attack_radius = attack_radius
			_active_attack_arc = attack_arc_degrees
			_attack_cooldown = 0.34
			_attack_anim_timer = ATTACK_DURATION
			_attack_lunge_vel = _swing_dir * 38.0
		2:
			_active_attack_damage = int(round(float(attack_damage) * combo2_damage_multiplier))
			_active_attack_radius = attack_radius * 1.10
			_active_attack_arc = minf(165.0, attack_arc_degrees + 18.0)
			_attack_cooldown = 0.34
			_attack_anim_timer = ATTACK_DURATION
			_attack_lunge_vel = _swing_dir * 72.0
		_:
			_active_attack_damage = int(round(float(attack_damage) * combo3_damage_multiplier))
			_active_attack_radius = attack_radius * 1.22
			_active_attack_arc = minf(180.0, attack_arc_degrees + 40.0)
			_attack_cooldown = 0.46
			_attack_anim_timer = ATTACK_DURATION + 0.06
			_attack_lunge_vel = _swing_dir * 110.0

	_swing_hit_ids.clear()
	_swing_landed_hit = false
	_swing_miss_registered = false

	_play_attack_or_combo_animation()

	var pitch_db := -9.5 if combo_stage == 1 else (-7.5 if combo_stage == 2 else -5.0)
	CombatSfx.play(self, "swing_miss", pitch_db)
	var use_crimson := combo_stage >= 3 and not _is_act3_unfiltered()
	var slash_name := "axe_slash_crimson" if use_crimson else "axe_slash_amber"
	var slash_scale := Vector2(1.0, -1.0 if combo_stage == 2 else 1.0)
	VfxLibrary.spawn_burst(self, slash_name, global_position + Vector2(0, -4), {
		"rotation": _swing_dir.angle(),
		"scale": slash_scale,
		"modulate": _get_vfx_tint(Color.WHITE),
		"z_index": 6,
	})
	melee_attack_performed.emit(global_position, _swing_dir, _active_attack_radius, _active_attack_arc, _active_attack_damage)
	combo_attack_performed.emit(combo_stage, global_position, _swing_dir, _active_attack_damage)
	_evaluate_active_melee_hitbox()
	queue_redraw()
	return true


func _play_attack_or_combo_animation() -> void:
	if character_sprite == null or character_sprite.sprite_frames == null:
		return
	var dir_str := _get_dir_suffix(_swing_dir)
	var prefix := "attack"
	if combo_stage == 2:
		prefix = "combo2"
	elif combo_stage >= 3:
		prefix = "combo3"
	var target_anim := "%s_%s" % [prefix, dir_str]
	if not character_sprite.sprite_frames.has_animation(target_anim):
		target_anim = "attack_%s" % dir_str
	if character_sprite.sprite_frames.has_animation(target_anim):
		character_sprite.frame = 0
		character_sprite.play(target_anim)
	elif character_sprite.sprite_frames.has_animation("attack"):
		character_sprite.frame = 0
		character_sprite.play("attack")


func perform_water_skill() -> bool:
	if is_dead or _attack_cooldown > 0.0 or _is_dialogue_active():
		return false
	var gs := _get_game_state()
	if gs != null and not bool(gs.call("get_switch", "016_Magia_de_agua_obtida")):
		gs.emit_signal("notification_requested", "Habilidade de Água ainda não aprendida")
		return false
	_attack_cooldown = 0.50
	_water_anim_timer = 0.26
	var dir := facing_dir.normalized()
	if dir.length_squared() < 0.01:
		dir = Vector2.DOWN
	CombatSfx.play(self, "water_cast", -5.5)
	VfxLibrary.spawn_burst(self, "water_jet", global_position + dir * 8.0 + Vector2(0, -4), {
		"rotation": dir.angle(),
		"duration": 0.28,
		"scale": Vector2(0.95, 0.95),
		"modulate": _get_vfx_tint(Color.WHITE),
		"z_index": 6,
	})
	water_skill_performed.emit(global_position, dir, 76.0, 35)
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
	if not is_inside_tree() or get_tree() == null:
		return
	var newly_hit: Array[Dictionary] = []
	for node in get_tree().get_nodes_in_group("combat_target"):
		if not is_instance_valid(node) or not node.is_inside_tree() or node.is_queued_for_deletion():
			continue
		if node.has_method("query_melee_hit"):
			var hits: Variant = node.call("query_melee_hit", global_position, _swing_dir, _active_attack_radius, _active_attack_arc, _active_attack_damage, _swing_hit_ids)
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
			if is_point_in_attack_cone(global_position, _swing_dir, target_2d.global_position, target_radius, _active_attack_radius, _active_attack_arc):
				_swing_hit_ids[tid] = true
				if target_2d.has_method("receive_melee_hit"):
					target_2d.call("receive_melee_hit", _active_attack_damage, global_position)
				newly_hit.append({
					"id": tid,
					"pos": target_2d.global_position,
					"damage": _active_attack_damage
				})

	if not newly_hit.is_empty():
		if not _swing_landed_hit:
			CombatSfx.play(self, "melee_hit", -3.5 if combo_stage < 3 else -1.5)
		_swing_landed_hit = true
		for h in newly_hit:
			var hpos: Vector2 = h.get("pos", global_position + _swing_dir * 28.0)
			var dmg: int = int(h.get("damage", _active_attack_damage))
			var contact_pos := global_position.lerp(hpos, 0.72)
			var fx_col := Color("#FFE066") if combo_stage >= 3 else Color("#FFF3B0")
			var fx_txt := "-%d!" % dmg if combo_stage >= 3 else "-%d" % dmg
			var has_spark := VfxLibrary.spawn_burst(self, "hit_spark", contact_pos, {
				"rotation": _swing_dir.angle(),
				"scale": Vector2.ONE if combo_stage >= 3 else Vector2(0.82, 0.82),
				"modulate": _get_vfx_tint(Color.WHITE),
				"z_index": 7,
			}) != null
			_spawn_combat_fx("hit_text" if has_spark else "hit", contact_pos, fx_txt, fx_col)
			attack_hit_landed.emit(contact_pos, dmg)


func _apply_water_to_scene_targets(dir: Vector2) -> void:
	if not is_inside_tree() or get_tree() == null:
		return
	var any_water_hit := false
	for node in get_tree().get_nodes_in_group("water_target"):
		if not is_instance_valid(node) or not node.is_inside_tree() or node.is_queued_for_deletion():
			continue
		if node.has_method("query_water_hit"):
			var hits: Variant = node.call("query_water_hit", global_position, dir, 76.0, 125.0, 35)
			if typeof(hits) == TYPE_ARRAY and not (hits as Array).is_empty():
				any_water_hit = true
				for h in (hits as Array):
					if typeof(h) == TYPE_DICTIONARY:
						var hpos: Vector2 = h.get("pos", global_position + dir * 36.0)
						var label_txt: String = str(h.get("label", "-35"))
						_spawn_water_impact_vfx(hpos, label_txt)
		elif node is Node2D:
			var target_2d := node as Node2D
			if is_point_in_attack_cone(global_position, dir, target_2d.global_position, 22.0, 76.0, 125.0):
				if target_2d.has_method("receive_water_hit"):
					target_2d.call("receive_water_hit", 35, global_position)
					any_water_hit = true
					_spawn_water_impact_vfx(target_2d.global_position, "-35")
	if not any_water_hit:
		if VfxLibrary.spawn_burst(self, "water_splash", global_position + dir * 56.0, {
			"scale": Vector2(0.60, 0.60),
			"modulate": _get_vfx_tint(Color.WHITE),
			"z_index": 6,
		}) == null:
			_spawn_combat_fx("miss", global_position + dir * 42.0, "", Color(0.56, 0.88, 0.96, 0.65))


func _spawn_water_impact_vfx(hpos: Vector2, label_txt: String) -> void:
	var has_splash := VfxLibrary.spawn_burst(self, "water_splash", hpos, {
		"scale": Vector2(0.72, 0.72),
		"modulate": _get_vfx_tint(Color.WHITE),
		"z_index": 7,
	}) != null
	_spawn_combat_fx("water_text" if has_splash else "water_hit", hpos, label_txt, Color("#90E0EF"))


func _is_act3_unfiltered() -> bool:
	var gs := _get_game_state()
	return gs != null and bool(gs.call("is_unfiltered_act3"))


func _get_vfx_tint(base_col: Color) -> Color:
	if _is_act3_unfiltered():
		var lum := base_col.get_luminance()
		return Color(lum * 0.84, lum * 0.85, lum * 0.88, base_col.a * 0.90)
	return base_col


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
	if _combo_reset_timer > 0.0:
		_combo_reset_timer -= delta
		if _combo_reset_timer <= 0.0:
			combo_stage = 0
	if _dodge_cooldown > 0.0:
		_dodge_cooldown -= delta
	if _dodge_invuln_timer > 0.0:
		_dodge_invuln_timer -= delta

	# Atualiza estado de morte se aplicável
	if is_dead:
		if _death_anim_timer > 0.0:
			_death_anim_timer -= delta
		_update_character_sprite_state()
		queue_redraw()
		return

	# Atualiza janela ativa da animação do ataque / combo corpo a corpo
	if _attack_anim_timer > 0.0:
		_attack_anim_timer -= delta
		if _attack_anim_timer > 0.04:
			_evaluate_active_melee_hitbox()
		elif not _swing_landed_hit and not _swing_miss_registered:
			_swing_miss_registered = true
			var miss_pos := global_position + _swing_dir * (_active_attack_radius * 0.78)
			_spawn_combat_fx("miss", miss_pos, "", Color(0.85, 0.88, 0.94, 0.55))
			attack_missed.emit(miss_pos)

	if _dodge_timer > 0.0:
		_dodge_timer -= delta
		if _dodge_timer <= 0.0:
			is_dodging = false
	else:
		is_dodging = false

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
	if _hurt_anim_timer > 0.0:
		_hurt_anim_timer -= delta

	# Atualiza partículas de feedback de combate
	for i in range(_combat_fx.size() - 1, -1, -1):
		var fx: Dictionary = _combat_fx[i]
		fx["timer"] = float(fx["timer"]) + delta
		if float(fx["timer"]) >= float(fx["duration"]):
			_combat_fx.remove_at(i)

	if _is_dialogue_active():
		_interact_cooldown = maxf(_interact_cooldown, 0.28)
		_was_interact_key_down = true
		_was_attack_key_down = true
		_was_dodge_key_down = true
		_was_water_key_down = true
		_was_outfit_key_down = true
		_was_jump_key_down = true
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

	is_crouching = (Input.is_key_pressed(KEY_CTRL) or Input.is_key_pressed(KEY_X)) and not is_jumping and not is_dodging and _attack_anim_timer <= 0.0
	var wants_run := Input.is_key_pressed(KEY_SHIFT) and not is_crouching
	is_running = wants_run and direction.length_squared() > 0.001 and not _stamina_exhausted and get_stamina() > 0.5

	if direction.length_squared() > 0.001 and not is_crouching and not is_dodging:
		direction = direction.normalized()
		if _attack_anim_timer <= 0.0:
			if not rotate_towards_mouse or not _is_mouse_aiming_active():
				facing_dir = direction
				if absf(direction.x) > 0.08:
					_facing_left = (direction.x < 0.0)
		is_moving = true
		walk_time += delta * (13.0 if is_running else 9.0)
		_update_interaction_offset()
	else:
		direction = Vector2.ZERO
		is_moving = false
		is_running = false
		walk_time += delta * 2.0

	if is_running and is_moving:
		_spend_stamina(STAMINA_RUN_DRAIN * delta)
	elif not is_dodging and _attack_anim_timer <= 0.0:
		_regen_stamina(delta)

	# Mecânica: Rotate Towards Mouse
	if rotate_towards_mouse and _is_mouse_aiming_active() and _attack_anim_timer <= 0.0 and not is_dodging:
		var target_mouse := _get_active_mouse_pos()
		var diff := target_mouse - global_position
		if diff.length_squared() >= (mouse_aim_deadzone * mouse_aim_deadzone):
			var target_dir := diff.normalized()
			if mouse_rotation_smooth:
				facing_dir = facing_dir.slerp(target_dir, clampf(mouse_rotation_speed * delta, 0.0, 1.0)).normalized()
			else:
				facing_dir = target_dir
			if absf(facing_dir.x) > 0.08:
				_facing_left = (facing_dir.x < 0.0)
			_update_interaction_offset()

	_knockback_vel = _knockback_vel.move_toward(Vector2.ZERO, 650.0 * delta)
	_attack_lunge_vel = _attack_lunge_vel.move_toward(Vector2.ZERO, 520.0 * delta)

	if is_dodging:
		velocity = _dodge_dir * dodge_speed + _knockback_vel
	else:
		var move_mult := 0.45 if _attack_anim_timer > 0.0 else (run_speed_multiplier if is_running else 1.0)
		velocity = direction * (speed * move_mult) + _attack_lunge_vel + _knockback_vel
	move_and_slide()

	_refresh_prompt()
	var interact_down := Input.is_action_pressed("interact") or Input.is_key_pressed(KEY_E)
	var interact_edge := (Input.is_action_just_pressed("interact") or (interact_down and not _was_interact_key_down))
	var mouse_left_down := mouse_controls_combat and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	var attack_down := Input.is_key_pressed(KEY_J) or Input.is_key_pressed(KEY_SPACE) or mouse_left_down
	var attack_edge := attack_down and not _was_attack_key_down
	var dodge_down := Input.is_key_pressed(KEY_Z) or Input.is_key_pressed(KEY_L)
	var water_down := Input.is_key_pressed(KEY_K) or Input.is_key_pressed(KEY_Q) or (mouse_controls_combat and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT))
	var outfit_down := Input.is_key_pressed(KEY_U)
	var jump_down := Input.is_key_pressed(KEY_V) or Input.is_key_pressed(KEY_ALT)

	var interaction_consumed := false
	if not _is_interaction_blocked() and _interact_cooldown <= 0.0:
		var target := get_best_interactable()
		if target != null:
			var clicked_target := mouse_left_down and not _was_attack_key_down and _is_mouse_aiming_active() and _get_active_mouse_pos().distance_to(target.global_position) <= 32.0
			if interact_edge or clicked_target:
				_interact_cooldown = 0.28
				_was_interact_key_down = true
				_was_attack_key_down = true
				interaction_consumed = true
				target.trigger_interaction()

	if not interaction_consumed and not _is_dialogue_active():
		if attack_edge and not _is_interaction_blocked():
			perform_melee_attack()
		elif dodge_down and not _was_dodge_key_down:
			perform_dodge(direction if direction.length_squared() > 0.01 else facing_dir)
		elif jump_down and not _was_jump_key_down:
			perform_jump()
		elif water_down and not _was_water_key_down:
			perform_water_skill()
		elif outfit_down and not _was_outfit_key_down:
			var gs_o := _get_game_state()
			if gs_o != null:
				gs_o.call("toggle_outfit")
		elif _is_heal_just_pressed() and _interact_cooldown <= 0.0:
			var gs_h := _get_game_state()
			if gs_h != null and bool(gs_h.call("use_soothing_drop")):
				_interact_cooldown = 0.3

	_was_interact_key_down = interact_down or interaction_consumed
	_was_attack_key_down = attack_down or interaction_consumed
	_was_dodge_key_down = dodge_down
	_was_water_key_down = water_down
	_was_outfit_key_down = outfit_down
	_was_jump_key_down = jump_down

	_update_character_sprite_state()
	queue_redraw()


func _is_mouse_aiming_active() -> bool:
	return _has_mouse_input or _override_mouse_pos != null or (aim_pivot != null and aim_pivot._is_mouse_active)


func _get_active_mouse_pos() -> Vector2:
	if _override_mouse_pos != null:
		return _override_mouse_pos as Vector2
	if aim_pivot != null and aim_pivot._override_mouse_pos != null:
		return aim_pivot._override_mouse_pos as Vector2
	return get_global_mouse_position()


func set_simulated_mouse_aim(world_pos: Vector2) -> void:
	_override_mouse_pos = world_pos
	_has_mouse_input = true
	if aim_pivot:
		aim_pivot.set_simulated_mouse_position(world_pos)


func clear_simulated_mouse_aim() -> void:
	_override_mouse_pos = null
	if aim_pivot:
		aim_pivot.clear_simulated_mouse_position()


func _get_dir_suffix(dir_vec: Vector2) -> String:
	if absf(dir_vec.x) > absf(dir_vec.y) * 1.05:
		return "left" if dir_vec.x < 0.0 else "right"
	return "up" if dir_vec.y < 0.0 else "down"


func _update_character_sprite_state() -> void:
	if character_sprite == null or character_sprite.sprite_frames == null:
		return

	_ensure_correct_outfit_sheet()

	var active_dir := _swing_dir if _attack_anim_timer > 0.0 else (_dodge_dir if is_dodging else facing_dir)
	var dir_str := _get_dir_suffix(active_dir)

	character_sprite.flip_h = false
	if _using_v2_sprites:
		character_sprite.position = Vector2(0.0, SPRITE_V2_POS_Y - _jump_height + (1.0 if is_crouching else 0.0))
		character_sprite.offset = SPRITE_V2_OFFSET
		character_sprite.scale = SPRITE_V2_SCALE
	else:
		character_sprite.position = Vector2(0.0, -_jump_height + (1.0 if is_crouching else 0.0))
		character_sprite.offset = Vector2(0.0, -7.0)
		character_sprite.scale = Vector2.ONE

	var gs_act := _get_game_state()
	var act3 := gs_act != null and bool(gs_act.call("is_unfiltered_act3"))
	var hurt_flash: bool = _hurt_timer > 0.0 and int(_hurt_timer * 20.0) % 2 == 0
	if hurt_flash:
		character_sprite.modulate = Color(1.0, 0.45, 0.45, 1.0)
	elif is_dodging:
		character_sprite.modulate = Color(0.82, 0.94, 1.0, 0.92)
	elif act3:
		character_sprite.modulate = Color(0.76, 0.77, 0.80, 1.0)
	else:
		character_sprite.modulate = Color.WHITE

	# Máquina de estados de animação com prioridades claras:
	# death -> hurt -> dodge -> attack/combo2/combo3 -> jump -> run/walk -> idle
	var base_anim := "idle"
	character_sprite.speed_scale = 1.45 if (is_running and is_moving) else 1.0

	if is_dead:
		base_anim = "death"
		character_sprite.speed_scale = 1.0
	elif _hurt_anim_timer > 0.0:
		base_anim = "hurt"
		character_sprite.speed_scale = 1.0
	elif is_dodging:
		base_anim = "dodge"
		character_sprite.speed_scale = 1.0
	elif _attack_anim_timer > 0.0:
		if combo_stage == 2 and character_sprite.sprite_frames.has_animation("combo2_%s" % dir_str):
			base_anim = "combo2"
		elif combo_stage >= 3 and character_sprite.sprite_frames.has_animation("combo3_%s" % dir_str):
			base_anim = "combo3"
		else:
			base_anim = "attack"
		character_sprite.speed_scale = 1.0
	elif is_jumping and character_sprite.sprite_frames.has_animation("jump_%s" % dir_str):
		base_anim = "jump"
		character_sprite.speed_scale = 1.0
	elif is_moving and not is_crouching:
		if is_running and character_sprite.sprite_frames.has_animation("run_%s" % dir_str):
			base_anim = "run"
		else:
			base_anim = "walk"
	else:
		base_anim = "idle"

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
	var dlg_active := _is_dialogue_active()
	if best != null and not dlg_active:
		prompt_label.text = best.get_prompt_text()
		prompt_label.reset_size()
		var prompt_y := -46.0 if _using_v2_sprites else -36.0
		prompt_label.position = Vector2(-prompt_label.size.x * 0.5, prompt_y)
		prompt_label.visible = true
		nearby_interactable_changed.emit(prompt_label.text)
	else:
		prompt_label.visible = false
		nearby_interactable_changed.emit("")


func get_direction_row(dir_vec: Vector2 = facing_dir) -> int:
	if _using_v2_sprites:
		if absf(dir_vec.x) > absf(dir_vec.y) * 1.05:
			return 2 if dir_vec.x < 0.0 else 3
		return 1 if dir_vec.y < 0.0 else 0
	if absf(dir_vec.x) > absf(dir_vec.y) * 1.05:
		return 1 if dir_vec.x < 0.0 else 2
	return 3 if dir_vec.y < 0.0 else 0


func get_current_sheet_cell() -> Vector2i:
	var active_dir := _swing_dir if _attack_anim_timer > 0.0 else facing_dir
	var row := get_direction_row(active_dir)
	var col := 0
	if _using_v2_sprites:
		if is_moving and not is_crouching:
			col = int(floor(walk_time * 1.15)) % 6
		return Vector2i(col, row)
	if _attack_anim_timer > 0.0:
		var p := 1.0 - clampf(_attack_anim_timer / ATTACK_DURATION, 0.0, 1.0)
		col = 6 + clampi(int(p * 4.0), 0, 3)
	elif is_moving:
		col = 2 + (int(floor(walk_time * 1.15)) % 4)
	else:
		col = int(floor(walk_time * 0.8)) % 2
	return Vector2i(col, row)


func _draw() -> void:
	# Sombra oval sutil sob os pés do protagonista (ancorada em y=8.5, alinhada aos pés em y=39 da célula 48x48)
	if not is_dead:
		var shadow_scale := clampf(1.0 - (_jump_height / 28.0), 0.55, 1.0)
		draw_Rect_ellipse(Vector2(0, 8.5), Vector2(7.5, 3.0) * shadow_scale, Color(0.03, 0.03, 0.07, 0.40))

	if _attack_anim_timer > 0.0 and VfxLibrary.get_frames("axe_slash_amber") == null:
		_draw_melee_arc()
	if _water_anim_timer > 0.0 and VfxLibrary.get_frames("water_jet") == null:
		_draw_water_stream()

	_draw_combat_feedback_fx()


func _draw_melee_arc() -> void:
	var total_dur := ATTACK_DURATION + (0.06 if combo_stage >= 3 else 0.0)
	var progress := 1.0 - clampf(_attack_anim_timer / total_dur, 0.0, 1.0)
	var base_angle := _swing_dir.angle()
	var half_arc := deg_to_rad(_active_attack_arc * 0.5)
	var sweep_start := base_angle - half_arc
	var sweep_end := base_angle + half_arc
	if combo_stage == 2:
		# No estágio 2 do combo, o arco varre no sentido inverso!
		var tmp := sweep_start
		sweep_start = sweep_end
		sweep_end = tmp

	var outer_pts := PackedVector2Array()
	var inner_pts := PackedVector2Array()
	var steps := 12
	var inner_r := _active_attack_radius * lerpf(0.34, 0.60, progress)
	for i in range(steps + 1):
		var t := float(i) / float(steps)
		var a := lerpf(sweep_start, sweep_end, t)
		outer_pts.append(Vector2(cos(a), sin(a)) * _active_attack_radius)
		inner_pts.append(Vector2(cos(a), sin(a)) * inner_r)

	var crescent := PackedVector2Array()
	for p in outer_pts:
		crescent.append(p)
	for i in range(inner_pts.size() - 1, -1, -1):
		crescent.append(inner_pts[i])

	var alpha := clampf(1.0 - progress * 0.65, 0.2, 1.0)
	var is_finisher := (combo_stage >= 3)
	var fill_col := (
		Color(1.0, 0.86, 0.32, 0.62 * alpha)
		if is_finisher else (
			Color(1.0, 0.94, 0.55, 0.56 * alpha)
			if _swing_landed_hit else
			Color(0.68, 0.86, 1.0, 0.36 * alpha)
		)
	)
	var edge_col := (
		Color(1.0, 0.96, 0.68, 0.98 * alpha)
		if is_finisher else (
			Color(1.0, 0.98, 0.85, 0.95 * alpha)
			if _swing_landed_hit else
			Color(0.92, 0.97, 1.0, 0.84 * alpha)
		)
	)
	draw_colored_polygon(crescent, fill_col)
	draw_polyline(outer_pts, edge_col, 2.4 if (is_finisher or _swing_landed_hit) else 1.6)

	var blade_angle := lerpf(sweep_start, sweep_end, clampf(progress * 1.25, 0.0, 1.0))
	var blade_tip := Vector2(cos(blade_angle), sin(blade_angle)) * _active_attack_radius
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

		if kind == "hit" or kind == "water_hit" or kind == "hit_text" or kind == "water_text":
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
		elif kind == "hurt" or kind == "dodge":
			var txt_h: String = str(fx["text"])
			if not txt_h.is_empty() and font_to_use != null:
				var text_pos := local_pos + Vector2(-12.0, -6.0 - t * 12.0)
				draw_string_outline(font_to_use, text_pos, txt_h, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, 3, Color(0.06, 0.05, 0.10, alpha))
				draw_string(font_to_use, text_pos, txt_h, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(col.r, col.g, col.b, alpha))
		elif kind == "dodge_ghost":
			draw_Rect_ellipse(local_pos + Vector2(0, -4), Vector2(6.0, 10.0) * (1.0 - t * 0.3), Color(col.r, col.g, col.b, alpha * 0.35))
		elif kind == "miss":
			var wisp_r := lerpf(3.0, 9.0, t)
			draw_arc(local_pos, wisp_r, -0.8, 0.8, 8, Color(col.r, col.g, col.b, alpha * 0.55), 1.4)


func draw_Rect_ellipse(center: Vector2, radii: Vector2, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in range(14):
		var angle: float = TAU * float(i) / 14.0
		pts.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	draw_colored_polygon(pts, col)
