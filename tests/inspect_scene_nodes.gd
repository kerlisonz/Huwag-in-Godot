extends SceneTree

func _init() -> void:
	var s: PackedScene = load("res://scenes/levels/RoomHuwag.tscn")
	var inst: Node = s.instantiate()
	print("Instantiated RoomHuwag root:", inst.name, "type:", inst.get_class())
	_print_tree(inst, "")
	quit(0)

func _print_tree(n: Node, prefix: String) -> void:
	print(prefix, "- ", n.name, " (", n.get_class(), ", script=", n.get_script(), ")")
	for c in n.get_children():
		_print_tree(c, prefix + "  ")
