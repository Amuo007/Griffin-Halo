extends Node3D
## Staged intro cutscene: cave mouth at night, Griffin and Marcus.

@export var sky_path := "res://assets/game/skyboxes/skybox-night.png"
@export var solo: bool = false

func _ready() -> void:
	var env := Environment.new()
	var sky := Sky.new()
	var pano := PanoramaSkyMaterial.new()
	pano.panorama = load(sky_path)
	sky.sky_material = pano
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.35
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)

	var sun := DirectionalLight3D.new()
	sun.light_color = Color(0.4, 0.5, 0.8)
	sun.light_energy = 0.35
	sun.rotation_degrees = Vector3(-40, 30, 0)
	add_child(sun)

	var ground := MeshInstance3D.new()
	var gm := PlaneMesh.new()
	gm.size = Vector2(60, 60)
	ground.mesh = gm
	var gmat := StandardMaterial3D.new()
	gmat.albedo_color = Color(0.08, 0.07, 0.06)
	ground.material_override = gmat
	add_child(ground)

	var cave := (load("res://assets/game/cave/gate-rock.glb") as PackedScene).instantiate()
	cave.scale = Vector3(2.5, 2.5, 2.5)
	cave.position = Vector3(0, 0, -6)
	var cmat := StandardMaterial3D.new()
	cmat.albedo_color = Color(0.35, 0.33, 0.32)
	for c in cave.find_children("*", "VisualInstance3D"):
		c.material_override = cmat
	add_child(cave)

	var griffin := (load("res://scenes/player/Character_griffin.tscn") as PackedScene).instantiate()
	griffin.position = Vector3(-1.2, 0, 0)
	griffin.rotation.y = 0.6
	add_child(griffin)
	_animate(griffin)

	if not solo:
		var marcus := (load("res://scenes/player/Character_marcus.tscn") as PackedScene).instantiate()
		marcus.position = Vector3(1.4, 0, -1.0)
		marcus.rotation.y = -0.7
		add_child(marcus)
		_animate(marcus)

	var cam := Camera3D.new()
	cam.position = Vector3(0.3, 1.7, 6.8)
	cam.rotation_degrees = Vector3(-6, -2, 0)
	cam.fov = 50
	cam.current = true
	add_child(cam)

func _animate(char_root: Node) -> void:
	var tree := char_root.get_node_or_null("AnimationTree") as AnimationTree
	if tree:
		tree.active = true
		var pb = tree.get("parameters/playback")
		if pb:
			pb.travel("Locomotion")
