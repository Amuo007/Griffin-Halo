extends MazeBuilder
## Zone 1: The Shaft — tutorial area.

const ROOMS := [
	{"id": "start", "cx": 0, "cz": 0, "size": 3},
	{"id": "hall", "cx": 8, "cz": 0, "size": 5},
	{"id": "fork", "cx": 8, "cz": 8, "size": 3},
	{"id": "storage", "cx": 2, "cz": 8, "size": 3},
	{"id": "flooded", "cx": 14, "cz": 8, "size": 3},
	{"id": "shrine", "cx": 14, "cz": 16, "size": 3},
	{"id": "nest_edge", "cx": 8, "cz": 16, "size": 3},
	{"id": "exit", "cx": 2, "cz": 16, "size": 3},
]
const EDGES := [
	["start", "hall"], ["hall", "fork"], ["fork", "storage"],
	["fork", "flooded"], ["flooded", "shrine"], ["shrine", "nest_edge"],
	["nest_edge", "exit"],
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
	var hud := preload("res://scenes/ui/HUD.tscn").instantiate()
	add_child(hud)
	GameState.set_objective("Find a way out of the mine")

func _add_enemies() -> void:
	_spawn_enemy("fox", 14, 9)
	_spawn_enemy("hog", 8, 16)
	_spawn_enemy("cat", 14, 12)

func _spawn_enemy(species: String, cx: int, cz: int) -> void:
	var e = preload("res://scenes/enemies/Enemy.tscn").instantiate()
	e.species_id = species
	e.position = Vector3(cx * CELL, 0.1, cz * CELL)
	add_child(e)

func _add_pickups() -> void:
	_spawn_pickup("gun", 2, 8, {"gun_id": "pistol", "model_path": "res://assets/game/blasters/blaster-a.glb"})
	_spawn_pickup("ammo", 14, 8, {"model_path": "res://assets/game/blasters/clip-small.glb"})
	_spawn_pickup("food", 8, 0, {"model_path": "res://assets/game/food/can-open.glb"})
	_spawn_pickup("battery", 8, 8, {"model_path": "res://assets/game/blasters/bullet-foam.glb"})
	_spawn_pickup("ammo", 14, 16, {"model_path": "res://assets/game/blasters/clip-large.glb"})

func _spawn_pickup(type: String, cx: int, cz: int, props: Dictionary) -> void:
	var p = preload("res://scenes/pickups/Pickup.tscn").instantiate()
	p.pickup_type = type
	p.model_path = props.get("model_path", "")
	p.gun_id = props.get("gun_id", "")
	p.position = Vector3(cx * CELL + 1.5, 1.0, cz * CELL + 1.5)
	add_child(p)

func _add_torches() -> void:
	for r in ROOMS:
		var light := OmniLight3D.new()
		light.light_color = Color(1.0, 0.6, 0.25)
		light.light_energy = 1.4
		light.omni_range = 9.0
		light.shadow_enabled = true
		light.position = Vector3(r.cx * CELL, 3.0, r.cz * CELL)
		light.add_to_group("torch_lights")
		add_child(light)
		var flame := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.12
		sm.height = 0.24
		flame.mesh = sm
		var mat := StandardMaterial3D.new()
		mat.emission_enabled = true
		mat.emission = Color(1.0, 0.7, 0.3)
		mat.emission_energy_multiplier = 4.0
		flame.material_override = mat
		flame.position = light.position
		add_child(flame)


func _add_extras() -> void:
	# exit gate to Zone 2
	var exit := preload("res://scenes/world/ExitTrigger.tscn").instantiate()
	exit.position = Vector3(2 * CELL, 1.5, 16 * CELL)
	add_child(exit)
	# scripted scares
	var ev1 := preload("res://scenes/world/ScriptedEvent.tscn").instantiate()
	ev1.event_type = "flicker"
	ev1.position = Vector3(8 * CELL, 1.0, 4 * CELL)
	add_child(ev1)
	var ev2 := preload("res://scenes/world/ScriptedEvent.tscn").instantiate()
	ev2.event_type = "roar"
	ev2.speaker = ""
	ev2.line_text = "Something enormous is moving in the dark. Three corridors over. Getting closer."
	ev2.position = Vector3(14 * CELL, 1.0, 12 * CELL)
	add_child(ev2)
