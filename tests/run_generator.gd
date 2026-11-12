extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	print("Rodando ForestAssetGenerator...")
	var gen = load("res://scripts/utils/forest_procedural_assets.gd")
	gen.ensure_all_assets()
	print("Tileset gerado!")
	quit(0)
