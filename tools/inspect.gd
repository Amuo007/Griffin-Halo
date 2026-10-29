extends SceneTree
## Headless inspection tool: godot --headless --script tools/inspect.gd

func _initialize() -> void:
	var paths := [
		"res://assets/game/characters/characterMedium.fbx",
		"res://assets/game/characters/anims/run.fbx",
		"res://assets/game/cave/corridor.glb",
		"res://assets/game/pets/animal-hog.glb",
		"res://assets/game/blasters/blaster-a.glb",
	]
	for p in paths:
		print("=== ", p)
		var res = ResourceLoader.load(p)
		if res == null:
			print("  LOAD FAILED")
			continue
		if res is PackedScene:
			var scene: PackedScene = res
			var root := scene.instantiate()
			_dump(root, 1)
			root.free()
		else:
			print("  type: ", res.get_class())
	quit()

func _dump(node: Node, depth: int) -> void:
	var pad := "  ".repeat(depth)
	var extra := ""
	if node is Skeleton3D:
		var sk := node as Skeleton3D
		var names := []
		for i in sk.get_bone_count():
			names.append(sk.get_bone_name(i))
		extra = " bones=%d\n%s%s" % [sk.get_bone_count(), pad + "  ", str(names)]
	if node is AnimationPlayer:
		var ap := node as AnimationPlayer
		extra = " anims=%s" % str(ap.get_animation_list())
	if node is MeshInstance3D:
		var mi := node as MeshInstance3D
		var mats := []
		if mi.mesh:
			for i in mi.mesh.get_surface_count():
				var m := mi.mesh.surface_get_material(i)
				mats.append(m.resource_name if m else "none")
		extra = " mesh=%s mats=%s" % [mi.mesh.resource_name if mi.mesh else "null", mats]
	print(pad, node.name, " (", node.get_class(), ")", extra)
	for c in node.get_children():
		_dump(c, depth + 1)
