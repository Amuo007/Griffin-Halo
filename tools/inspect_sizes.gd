extends SceneTree
func _initialize() -> void:
	var dir := DirAccess.open("res://assets/game/cave")
	var files := dir.get_files()
	files.sort()
	for f in files:
		if not f.ends_with(".glb"): continue
		var ps: PackedScene = ResourceLoader.load("res://assets/game/cave/" + f)
		var root := ps.instantiate()
		var aabb := AABB()
		var first := true
		for mi in _meshes(root):
			var m: AABB = mi.get_aabb()
			m = mi.global_transform * m  # local only, no parent transform applied; fine at root
			if first: aabb = m; first = false
			else: aabb = aabb.merge(m)
		print("%s: size=%s" % [f.trim_suffix(".glb"), str(aabb.size.round())])
		root.free()
	quit()
func _meshes(n: Node) -> Array:
	var out := []
	if n is MeshInstance3D: out.append(n)
	for c in n.get_children(): out.append_array(_meshes(c))
	return out
