extends Node2D
class_name RotateTowardsMouse

## Componente reutilizável para rotacionar um Node2D em direção à posição do mouse no espaço global 2D.
## Suporta rotação direta (look_at), interpolação suave (lerp_angle), deadzone,
## compensação angular (offset), restrição cardinal / 8-direções e atualização de facing_dir do pai.

signal aim_direction_changed(direction: Vector2)
signal rotated(current_angle: float)

@export_group("Target & Mode")
## Nó que receberá a rotação. Se for nulo, rotaciona este próprio Node2D (útil como AimPivot).
@export var target_node: Node2D = null
## Se falso, desativa a mecânica.
@export var enabled: bool = true
## Se verdadeiro, atualiza a propriedade 'facing_dir' no nó pai caso ela exista.
@export var update_parent_facing: bool = true
## Se verdadeiro, aplica a rotação ao atributo 'global_rotation' do nó alvo.
@export var rotate_transform: bool = true

@export_group("Rotation Smoothing")
## Se verdadeiro, usa interpolação suave com lerp_angle em vez de ajustar instantaneamente.
@export var smooth: bool = false
## Velocidade de interpolação angular (multiplicada por delta).
@export var rotation_speed: float = 14.0

@export_group("Angle & Constraints")
## Compensação angular em graus (ex: 90° se o sprite base foi desenhado apontando para cima).
@export var offset_degrees: float = 0.0
## Distância mínima em pixels entre o nó e o mouse para aplicar rotação (evita jitter quando o cursor está no centro).
@export var deadzone: float = 8.0
## Se verdadeiro, trava o ângulo nas 4 direções cardinais (Cima, Baixo, Esquerda, Direita).
@export var snap_to_cardinal: bool = false
## Se verdadeiro, trava o ângulo nas 8 direções (cardinais + diagonais).
@export var snap_to_8_directions: bool = false

@export_group("Visual Indicator")
## Se verdadeiro, desenha um indicador visual sutil na direção da mira.
@export var show_aim_indicator: bool = false
## Distância do indicador a partir da origem do nó.
@export var indicator_distance: float = 24.0
## Cor do indicador de mira.
@export var indicator_color: Color = Color(0.9, 0.95, 1.0, 0.45)

var last_aim_direction: Vector2 = Vector2.DOWN
var last_aim_angle: float = 0.0
var _is_mouse_active: bool = false
var _override_mouse_pos: Variant = null

func _ready() -> void:
	if target_node == null:
		target_node = self
	last_aim_angle = target_node.global_rotation
	last_aim_direction = Vector2.from_angle(last_aim_angle)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion or event is InputEventMouseButton:
		_is_mouse_active = true

func _process(delta: float) -> void:
	if not enabled or target_node == null:
		return
	if not _is_mouse_active and _override_mouse_pos == null:
		return

	# Não processa durante diálogos se GameState existir
	var tree := get_tree()
	if tree and tree.root and tree.root.has_node("GameState"):
		var gs: Node = tree.root.get_node("GameState")
		if gs and bool(gs.get("dialogue_active")):
			return

	update_rotation(delta)

func update_rotation(delta: float) -> void:
	var mouse_pos: Vector2 = get_target_mouse_position()
	var origin_pos: Vector2 = target_node.global_position
	var to_mouse := mouse_pos - origin_pos

	if to_mouse.length_squared() < (deadzone * deadzone):
		return

	var raw_angle := to_mouse.angle() + deg_to_rad(offset_degrees)
	var final_angle := _apply_snapping(raw_angle)
	var aim_dir := Vector2.from_angle(raw_angle).normalized()

	if rotate_transform:
		if smooth:
			target_node.global_rotation = lerp_angle(target_node.global_rotation, final_angle, clampf(rotation_speed * delta, 0.0, 1.0))
		else:
			target_node.global_rotation = final_angle

	last_aim_angle = final_angle
	last_aim_direction = aim_dir
	rotated.emit(final_angle)
	aim_direction_changed.emit(aim_dir)

	if update_parent_facing:
		var parent := get_parent()
		if parent and "facing_dir" in parent:
			parent.facing_dir = aim_dir
			if parent.has_method("_update_interaction_offset"):
				parent.call("_update_interaction_offset")

	if show_aim_indicator:
		queue_redraw()

func _apply_snapping(angle: float) -> float:
	if snap_to_cardinal:
		var step := PI * 0.5
		return roundf(angle / step) * step
	elif snap_to_8_directions:
		var step := PI * 0.25
		return roundf(angle / step) * step
	return angle

func get_target_mouse_position() -> Vector2:
	if _override_mouse_pos != null:
		return _override_mouse_pos as Vector2
	return get_global_mouse_position()

func set_simulated_mouse_position(pos: Vector2) -> void:
	_override_mouse_pos = pos
	_is_mouse_active = true

func clear_simulated_mouse_position() -> void:
	_override_mouse_pos = null

func get_aim_direction() -> Vector2:
	return last_aim_direction

func get_aim_angle() -> float:
	return last_aim_angle

func look_at_mouse() -> void:
	_is_mouse_active = true
	update_rotation(1.0)

func _draw() -> void:
	if not show_aim_indicator or not enabled:
		return
	var local_dir := last_aim_direction
	if target_node != self and target_node != null:
		local_dir = Vector2.from_angle(last_aim_angle)
	var tip := local_dir * indicator_distance
	draw_circle(tip, 2.5, indicator_color)
	draw_line(Vector2.ZERO, tip * 0.7, Color(indicator_color.r, indicator_color.g, indicator_color.b, indicator_color.a * 0.5), 1.2)

