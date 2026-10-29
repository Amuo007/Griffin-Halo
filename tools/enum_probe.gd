extends SceneTree
func _initialize() -> void:
	var s = load("res://scripts/world/MazeBuilder.gd")
	print("MazeBuilder script: ", s)
	if s: print("base: ", s.get_base_script())
	quit()
