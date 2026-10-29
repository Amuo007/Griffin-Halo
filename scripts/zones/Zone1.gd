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
	GameState.set_objective("Find a way out of the mine")

func _add_torches() -> void:
	for r in ROOMS:
		var light := OmniLight3D.new()
		light.light_color = Color(1.0, 0.6, 0.25)
		light.light_energy = 1.4
		light.omni_range = 9.0
		light.shadow_enabled = true
		light.position = Vector3(r.cx * CELL, 3.0, r.cz * CELL)
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
