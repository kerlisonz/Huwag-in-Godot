extends SceneTree

func _init() -> void:
	if not root.has_node("GameState"):
		var gs_script: Script = load("res://scripts/autoload/game_state.gd")
		var gs: Node = Node.new()
		gs.name = "GameState"
		gs.set_script(gs_script)
		root.add_child(gs)
	call_deferred("_inspect")

func _inspect() -> void:
	var s: PackedScene = load("res://scenes/levels/RoomHuwag.tscn")
	var inst: Node = s.instantiate()
	print("Instantiated RoomHuwag root:", inst.name, "type:", inst.get_class())
	_print_tree(inst, "")
	inst.free()
	quit(0)

func _print_tree(n: Node, prefix: String) -> void:
	print(prefix, "- ", n.name, " (", n.get_class(), ", script=", n.get_script(), ")")
	for c in n.get_children():
		_print_tree(c, prefix + "  ")
