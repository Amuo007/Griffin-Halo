extends SceneTree
func _initialize() -> void:
	for a in ["idle","run","jump"]:
		var scene: PackedScene = ResourceLoader.load("res://assets/game/characters/anims/%s.fbx" % a)
		var root := scene.instantiate()
		var ap := _find_anim(root)
		print("== ", a, " anims=", ap.get_animation_list())
		for name in ap.get_animation_list():
			var anim := ap.get_animation(name)
			print("  ", name, " len=", anim.length, " tracks=", anim.get_track_count())
			for i in min(anim.get_track_count(), 4):
				print("    ", anim.track_get_path(i))
		root.free()
	quit()
func _find_anim(n: Node) -> AnimationPlayer:
	if n is AnimationPlayer: return n
	for c in n.get_children():
		var r := _find_anim(c)
		if r: return r
	return null
