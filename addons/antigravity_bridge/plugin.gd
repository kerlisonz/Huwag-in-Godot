@tool
extends EditorPlugin

const AntigravityDockClass := preload("res://addons/antigravity_bridge/ui/antigravity_dock.gd")
var dock_instance: Control = null

func _enter_tree() -> void:
	dock_instance = AntigravityDockClass.new()
	dock_instance.name = "Antigravity"
	add_control_to_dock(EditorPlugin.DOCK_SLOT_RIGHT_UL, dock_instance)
	print("[Antigravity Bridge] Plugin ativado com sucesso! Aba 'Antigravity' adicionada ao painel lateral.")

func _exit_tree() -> void:
	if dock_instance:
		remove_control_from_docks(dock_instance)
		dock_instance.free()
		dock_instance = null
		print("[Antigravity Bridge] Plugin desativado.")
