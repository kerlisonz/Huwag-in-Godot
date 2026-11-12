extends CharacterBody2D
class_name AquaticCreature

signal interaction_requested
signal creature_defeated

@export var max_health: int = 200
@export var current_health: int = 200
@export var is_hostile: bool = false

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var aura_particles: CPUParticles2D = $AuraParticles
@onready var interactable_zone: Interactable = get_node_or_null("CreatureInteractable")

var _base_pos_y: float = 0.0

func _ready() -> void:
	add_to_group("combat_target")
	add_to_group("water_target")
	_base_pos_y = position.y
	current_health = max_health

	if interactable_zone:
		interactable_zone.interacted.connect(_on_interacted)

func _process(_delta: float) -> void:
	# Flutuação ondulante sobre a água
	var t := float(Time.get_ticks_msec()) * 0.003
	if sprite:
		sprite.position.y = sin(t) * 4.0

func _on_interacted(_interactable: Interactable) -> void:
	interaction_requested.emit()

# Suporte ao sistema de interação de Huwag com a tecla [E]
func interact() -> void:
	interaction_requested.emit()

func receive_melee_hit(damage: int, _from_pos: Vector2) -> void:
	take_damage(damage)

func receive_water_hit(_damage: int, _from_pos: Vector2) -> void:
	# A criatura aquática absorve a água curando-se ou resplandecendo em azul celeste
	if sprite:
		var tween := create_tween()
		sprite.modulate = Color(0.4, 0.9, 1.0, 1.0)
		tween.tween_property(sprite, "modulate", Color(1, 1, 1, 1), 0.25)

func take_damage(amount: int) -> void:
	current_health = maxi(0, current_health - amount)
	is_hostile = true
	if sprite:
		var tween := create_tween()
		sprite.modulate = Color(1.0, 0.3, 0.3, 1.0)
		tween.tween_property(sprite, "modulate", Color(1, 1, 1, 1), 0.2)

	if current_health <= 0:
		creature_defeated.emit()
		queue_free()
