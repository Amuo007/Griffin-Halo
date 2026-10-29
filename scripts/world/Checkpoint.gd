extends Area3D
## Campfire checkpoint: saves the game and marks respawn.

var used: bool = false

func _ready() -> void:
	collision_layer = 16
	collision_mask = 4
	var cs := CollisionShape3D.new()
	var sh := SphereShape3D.new()
	sh.radius = 2.5
	cs.shape = sh
	add_child(cs)
	body_entered.connect(_on_body)

	# campfire visual: crate + flickering light
	var crate := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.8, 0.5, 0.8)
	crate.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.25, 0.15, 0.08)
	crate.material_override = mat
	add_child(crate)
	var fire := OmniLight3D.new()
	fire.light_color = Color(1.0, 0.55, 0.2)
	fire.light_energy = 0.6
	fire.omni_range = 3.0
	fire.position = Vector3(0, 0.8, 0)
	add_child(fire)
	var t := create_tween()
	t.set_loops()
	t.tween_property(fire, "light_energy", 0.85, 0.35)
	t.tween_property(fire, "light_energy", 0.5, 0.3)

func _on_body(body: Node3D) -> void:
	if GameState.mode != GameState.Mode.PLAY:
		return
	if not body.is_in_group("player"):
		return
	GameState.checkpoint = {
		"zone": GameState.zone,
		"pos": [global_position.x, global_position.y + 1.0, global_position.z],
	}
	SaveManager.save_game()
	GameState.checkpoint_reached.emit()
