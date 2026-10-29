extends MazeBuilder
## Zone 3: The Beast Nest — the alpha stalks you to the surface.

const ROOMS := [
	{"id": "nest_entry", "cx": 0, "cz": 0, "size": 3},
	{"id": "bone_room", "cx": 6, "cz": 0, "size": 3},
	{"id": "warren", "cx": 12, "cz": 4, "size": 5},
	{"id": "steam", "cx": 12, "cz": 10, "size": 3},
	{"id": "alpha_den", "cx": 6, "cz": 12, "size": 5},
	{"id": "final_shaft", "cx": 0, "cz": 12, "size": 3},
]
const EDGES := [
	["nest_entry", "bone_room"], ["bone_room", "warren"], ["warren", "steam"],
	["steam", "alpha_den"], ["alpha_den", "final_shaft"],
]

func _ready() -> void:
	for r in ROOMS:
		add_room(r.id, r.cx, r.cz, r.size)
	for e in EDGES:
		add_edge(e[0], e[1])
	build()
	_add_torches()
	_add_pickups()
	_add_enemies()
	_add_extras()
	var cp := preload("res://scenes/world/Checkpoint.tscn").instantiate()
	cp.position = Vector3(0 * 4.0, 0.0, 1 * 4.0)
	add_child(cp)
	var hud := preload("res://scenes/ui/HUD.tscn").instantiate()
	add_child(hud)
	apply_checkpoint(3)
	GameState.set_objective("Climb to the surface. Don't let it touch you.")
	DialogueRunner.play_cutscene("alpha")

func _add_torches() -> void:
	for r in ROOMS:
		var light := OmniLight3D.new()
		light.light_color = Color(0.9, 0.45, 0.2)
		light.light_energy = 1.0
		light.omni_range = 7.0
		light.shadow_enabled = true
		light.position = Vector3(r.cx * 4.0, 3.0, r.cz * 4.0)
		light.add_to_group("torch_lights")
		add_child(light)

func _add_pickups() -> void:
	_spawn_pickup("gun", 6, 0, {"gun_id": "shotgun", "model_path": "res://assets/game/blasters/blaster-d.glb"})
	_spawn_pickup("gun", 12, 10, {"gun_id": "rifle", "model_path": "res://assets/game/blasters/blaster-j.glb"})
	_spawn_pickup("ammo", 12, 4, {"model_path": "res://assets/game/blasters/clip-large.glb"})
	_spawn_pickup("ammo", 0, 12, {"model_path": "res://assets/game/blasters/clip-large.glb"})
	_spawn_pickup("food", 6, 12, {"model_path": "res://assets/game/food/apple.glb"})
	_spawn_pickup("battery", 12, 5, {"model_path": "res://assets/game/blasters/bullet-foam.glb"})

func _spawn_pickup(type: String, cx: int, cz: int, props: Dictionary) -> void:
	var p = preload("res://scenes/pickups/Pickup.tscn").instantiate()
	p.pickup_type = type
	p.model_path = props.get("model_path", "")
	p.gun_id = props.get("gun_id", "")
	p.position = Vector3(cx * 4.0 + 1.5, 1.0, cz * 4.0 + 1.5)
	add_child(p)

func _add_enemies() -> void:
	for spawn in [["hog", 12, 3], ["cat", 13, 5], ["fox", 12, 11], ["hog", 6, 11]]:
		var e = preload("res://scenes/enemies/Enemy.tscn").instantiate()
		e.species_id = spawn[0]
		e.position = Vector3(spawn[1] * 4.0, 0.1, spawn[2] * 4.0)
		add_child(e)
	# the alpha
	var alpha = preload("res://scenes/enemies/Enemy.tscn").instantiate()
	alpha.species_id = "deer"
	alpha.position = Vector3(6 * 4.0, 0.1, 12 * 4.0)
	add_child(alpha)

func _add_extras() -> void:
	var exit := preload("res://scenes/world/ExitTrigger.tscn").instantiate()
	exit.next_scene = "res://scenes/main/Victory.tscn"
	exit.next_zone = 4
	exit.position = Vector3(0 * 4.0, 1.5, 12 * 4.0)
	add_child(exit)
	var gate := preload("res://scenes/world/ScriptedEvent.tscn").instantiate()
	gate.event_type = "cutscene"
	gate.line_text = "gate"
	gate.position = Vector3(0 * 4.0, 1.0, 11 * 4.0)
	add_child(gate)
	var ev := preload("res://scenes/world/ScriptedEvent.tscn").instantiate()
	ev.event_type = "roar"
	ev.line_text = "It knows you. It has been waiting at the gate."
	ev.shake_amount = 1.0
	ev.position = Vector3(6 * 4.0, 1.0, 10 * 4.0)
	add_child(ev)
