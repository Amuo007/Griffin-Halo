extends SceneTree
func _initialize() -> void:
	change_scene_to_file("res://scenes/zones/Zone2.tscn")
	var gs := root.get_node_or_null("GameState")
	var dr := root.get_node_or_null("DialogueRunner")
	for i in 60:
		await process_frame
		if i == 30 and dr and dr.playing: dr.skip()
		if gs and dr and not dr.playing: gs.mode = 3
	var cam := root.get_viewport().get_camera_3d()
	print("MODE ", gs.mode, " playing ", dr.playing)
	print("CAM ", cam.global_position)
	var pl: Node = root.current_scene.get_node_or_null("Player")
	if pl: print("PLAYER ", pl.global_position)
	_walk(root, cam)
	quit()

func _walk(n: Node, cam: Camera3D) -> void:
	for c in n.get_children():
		if c is OmniLight3D or c is SpotLight3D or c is DirectionalLight3D:
			var d := cam.global_position.distance_to(c.global_position)
			if d < 12:
				var e: float = c.light_energy
				var r: float = c.omni_range if c is OmniLight3D else c.spot_range
				print("LIGHT ", c.name, " at ", c.global_position, " e=", e, " r=", r, " dist=", d)
		_walk(c, cam)
