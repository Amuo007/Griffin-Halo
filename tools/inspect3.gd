extends SceneTree
func _initialize() -> void:
	var scene: PackedScene = ResourceLoader.load("res://assets/game/characters/anims/run.fbx")
	var root := scene.instantiate()
	var ap := _find_anim(root)
	var anim := ap.get_animation("Root|Run")
	for i in anim.get_track_count():
		print(anim.track_get_path(i))
	root.free()
	quit()
func _find_anim(n: Node) -> AnimationPlayer:
	if n is AnimationPlayer: return n
	for c in n.get_children():
		var r := _find_anim(c)
		if r: return r
	return null
