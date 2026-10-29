extends Node3D
## Place player facing a wall, report camera distance to wall.
func _ready() -> void:
	var tree := get_tree()
	tree.root.remove_child.call_deferred(self)
	await tree.process_frame
	tree.change_scene_to_file("res://scenes/zones/Zone1.tscn")
	await tree.create_timer(1.5).timeout
	var gs := tree.root.get_node("GameState")
	gs.mode = 3
	var p := tree.current_scene.get_node("Player")
	# stand in start room facing the north wall (room half-extent 6m)
	p.global_position = Vector3(0, 0.1, 4)
	p.yaw = 0.0
	# push camera behind into wall: face so camera sits against wall
	p.yaw = PI  # camera now toward +z... just sample both
	await tree.create_timer(0.5).timeout
	var n := 0
	for c2 in tree.current_scene.get_children():
		if c2 is StaticBody3D and c2.collision_mask == 0:
			n = c2.get_child_count()
	print("GRIDWALLS ", n)
	for yaw in [0.0, PI / 2.0, PI, -PI / 2.0]:
		p.yaw = yaw
		await tree.create_timer(0.4).timeout
		var cam := p.get_node("SpringArm/Camera3D")
		var d: float = p.global_position.distance_to(cam.global_position)
		print("CAMTEST yaw=", yaw, " dist=", snappedf(d, 0.01), " cam=", cam.global_position)
		var q := PhysicsRayQueryParameters3D.create(p.global_position + Vector3(0, 1.4, 0), p.global_position + Vector3(0, 1.4, 0) + (-cam.global_transform.basis.z * 8.0))
		q.collision_mask = 1
		var hit: Dictionary = tree.root.get_world_3d().direct_space_state.intersect_ray(q)
		print("  RAY behind-cam hit=", not hit.is_empty(), " at ", hit.get("position", Vector3.ZERO))
	tree.quit()
