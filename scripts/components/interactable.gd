extends Area2D
class_name Interactable

signal interacted(interactable: Interactable)

@export var interaction_id: String = ""
@export var title: String = "Objeto"
@export var verb: String = "Examinar"
@export var auto_trigger_on_enter: bool = false
@export var one_shot_self_switch: String = ""

func _ready() -> void:
	collision_layer = 4
	collision_mask = 2
	monitoring = true
	monitorable = true
	body_entered.connect(_on_body_entered)

func can_interact() -> bool:
	if not visible:
		return false
	var gs := _get_game_state()
	if gs:
		if bool(gs.get("dialogue_active")) or bool(gs.get("sleep_transition_active")):
			return false
		if not one_shot_self_switch.is_empty() and gs.get_self_switch(interaction_id, one_shot_self_switch):
			return false
	return true

func get_prompt_text() -> String:
	return "[E] %s: %s" % [verb, title]

func trigger_interaction() -> void:
	if not can_interact():
		return
	var gs_block := _get_game_state()
	if gs_block and gs_block.has_method("is_interaction_blocked") and bool(gs_block.call("is_interaction_blocked")):
		return
	if not one_shot_self_switch.is_empty():
		var gs := _get_game_state()
		if gs:
			gs.set_self_switch(interaction_id, one_shot_self_switch, true)
	interacted.emit(self)

func _get_game_state() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree and tree.root and tree.root.has_node("GameState"):
		return tree.root.get_node("GameState")
	return null

func _on_body_entered(body: Node2D) -> void:
	if auto_trigger_on_enter and body.is_in_group("player") and can_interact():
		trigger_interaction()
