extends MazeBuilder
## Zone 2: Flooded Warrens — stealth emphasis, pack hunters.

const ROOMS := [
	{"id": "entry", "cx": 0, "cz": 0, "size": 3},
	{"id": "junction", "cx": 6, "cz": 0, "size": 3},
	{"id": "flood_a", "cx": 12, "cz": 0, "size": 5},
	{"id": "side", "cx": 6, "cz": 6, "size": 3},
	{"id": "flood_b", "cx": 12, "cz": 8, "size": 3},
	{"id": "deep", "cx": 6, "cz": 14, "size": 5},
	{"id": "pump", "cx": 0, "cz": 14, "size": 3},
	{"id": "nest_gate", "cx": 12, "cz": 14, "size": 3},
]
const EDGES := [
	["entry", "junction"], ["junction", "flood_a"], ["junction", "side"],
	["flood_a", "flood_b"], ["side", "deep"], ["flood_b", "deep"],
	["deep", "pump"], ["deep", "nest_gate"],
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
	apply_checkpoint(2)
	GameState.set_objective("Reach the pump house and find the way up")
	DialogueRunner.play_cutscene("journal")

func _add_torches() -> void:
	for r in ROOMS:
		if r.id in ["flood_a", "flood_b"]:
			continue  # dark flooded rooms
		var light := OmniLight3D.new()
		light.light_color = Color(1.0, 0.6, 0.25)
		light.light_energy = 1.2
		light.omni_range = 8.0
		light.shadow_enabled = true
		light.position = Vector3(r.cx * 4.0, 3.0, r.cz * 4.0)
		light.add_to_group("torch_lights")
		add_child(light)

func _add_pickups() -> void:
	_spawn_pickup("gun", 6, 6, {"gun_id": "smg", "model_path": "res://assets/game/blasters/blaster-e.glb"})
	_spawn_pickup("ammo", 12, 0, {"model_path": "res://assets/game/blasters/clip-small.glb"})
	_spawn_pickup("ammo", 0, 14, {"model_path": "res://assets/game/blasters/clip-large.glb"})
	_spawn_pickup("food", 6, 0, {"model_path": "res://assets/game/food/bread.glb"})
	_spawn_pickup("battery", 12, 8, {"model_path": "res://assets/game/blasters/bullet-foam.glb"})
	_spawn_pickup("food", 6, 14, {"model_path": "res://assets/game/food/bowl-soup.glb"})

func _spawn_pickup(type: String, cx: int, cz: int, props: Dictionary) -> void:
	var p = preload("res://scenes/pickups/Pickup.tscn").instantiate()
	p.pickup_type = type
	p.model_path = props.get("model_path", "")
	p.gun_id = props.get("gun_id", "")
	p.position = Vector3(cx * 4.0 + 1.5, 1.0, cz * 4.0 + 1.5)
	add_child(p)

func _add_enemies() -> void:
	for spawn in [["fox", 12, 2], ["fox", 13, 1], ["cat", 12, 8], ["crab", 12, 9], ["bee", 6, 12], ["bee", 7, 13], ["hog", 6, 16]]:
		var e = preload("res://scenes/enemies/Enemy.tscn").instantiate()
		e.species_id = spawn[0]
		e.position = Vector3(spawn[1] * 4.0, 0.1, spawn[2] * 4.0)
		add_child(e)

func _add_extras() -> void:
	var exit := preload("res://scenes/world/ExitTrigger.tscn").instantiate()
	exit.next_scene = "res://scenes/zones/Zone3.tscn"
	exit.next_zone = 3
	exit.position = Vector3(12 * 4.0, 1.5, 14 * 4.0)
	add_child(exit)
	var vera := preload("res://scenes/world/ScriptedEvent.tscn").instantiate()
	vera.event_type = "cutscene"
	vera.line_text = "vera"
	vera.position = Vector3(0 * 4.0, 1.0, 14 * 4.0)
	add_child(vera)
	var ev := preload("res://scenes/world/ScriptedEvent.tscn").instantiate()
	ev.event_type = "whisper"
	ev.speaker = ""
	ev.line_text = "The water ripples. Something huge is moving under the surface."
	ev.position = Vector3(12 * 4.0, 1.0, 4 * 4.0)
	add_child(ev)
