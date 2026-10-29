extends SceneTree
var f := 0
func _initialize() -> void:
	var ps: PackedScene = load("res://scenes/zones/Zone1.tscn")
	root.add_child(ps.instantiate())
func _process(_d: float) -> bool:
	f += 1
	if f == 3:
		for c in root.get_children():
			if c.has_method("debug_dump"):
				c.debug_dump()
		return true
	return false
