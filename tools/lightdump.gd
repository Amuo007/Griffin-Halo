extends SceneTree
func _initialize() -> void:
	change_scene_to_file("res://scenes/zones/Zone1.tscn")
	for i in 30:
		await process_frame
	var cam := root.get_viewport().get_camera_3d()
	print("CAM ", cam.global_position)
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
