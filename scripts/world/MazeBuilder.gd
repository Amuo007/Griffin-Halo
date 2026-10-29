class_name MazeBuilder
extends Node3D
## Builds a cave maze from the modular cave kit.
## Rooms placed on a 4m grid; corridors auto-route with L-shaped paths and
## pick straight/corner/junction/end modules based on connections.

const CELL := 4.0
const CAVE_DIR := "res://assets/game/cave/"

var rooms: Array = []       # [{id, cx, cz, size}] size in cells (3 => 12m)
var edges: Array = []       # [[roomA, roomB], ...]
var _corridor_cells := {}   # Vector2i -> true
var _room_cells := {}       # Vector2i -> room index
var _module_cache := {}

func add_room(id: String, cx: int, cz: int, size_cells: int = 3) -> void:
	rooms.append({"id": id, "cx": cx, "cz": cz, "size": size_cells})

func add_edge(a: String, b: String) -> void:
	edges.append([a, b])

func build() -> void:
	add_to_group("maze")
	_mark_rooms()
	for e in edges:
		_route(e[0], e[1])
	_place_rooms()
	_place_corridors()
	_build_grid_collision()
	_place_walls()
	_seal_bounds()

func _build_grid_collision() -> void:
	var cells := walkable_cells()
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	add_child(body)
	for c in cells.keys():
		var cx: float = c.x * CELL
		var cz: float = c.y * CELL
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			if not cells.has(c + d):
				var cs := CollisionShape3D.new()
				var sh := BoxShape3D.new()
				if d.x != 0:
					sh.size = Vector3(0.5, 5, CELL)
				else:
					sh.size = Vector3(CELL, 5, 0.5)
				cs.shape = sh
				cs.position = Vector3(cx + d.x * CELL * 0.5, 2.5, cz + d.y * CELL * 0.5)
				body.add_child(cs)

func walkable_cells() -> Dictionary:
	var w := {}
	for c in _room_cells.keys():
		w[c] = true
	for c in _corridor_cells.keys():
		w[c] = true
	return w

func find_path(from_world: Vector3, to_world: Vector3) -> PackedVector3Array:
	return MazeNavigator.find_path(walkable_cells(), from_world, to_world, CELL)

func _seal_bounds() -> void:
	var min_x := 100000
	var max_x := -100000
	var min_z := 100000
	var max_z := -100000
	for c in _room_cells.keys():
		min_x = mini(min_x, c.x); max_x = maxi(max_x, c.x)
		min_z = mini(min_z, c.y); max_z = maxi(max_z, c.y)
	for c in _corridor_cells.keys():
		min_x = mini(min_x, c.x); max_x = maxi(max_x, c.x)
		min_z = mini(min_z, c.y); max_z = maxi(max_z, c.y)
	var w := float(max_x - min_x + 3) * CELL
	var h := float(max_z - min_z + 3) * CELL
	var cx := float(min_x + max_x) / 2.0 * CELL
	var cz := float(min_z + max_z) / 2.0 * CELL
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color(0.05, 0.045, 0.04)
	dark.roughness = 1.0
	# ceiling
	var ceil_mesh := PlaneMesh.new()
	ceil_mesh.size = Vector2(w, h)
	var ceil_node := MeshInstance3D.new()
	ceil_node.mesh = ceil_mesh
	ceil_node.material_override = dark
	ceil_node.position = Vector3(cx, 4.02, cz)
	add_child(ceil_node)
	# floor
	var floor_mesh := PlaneMesh.new()
	floor_mesh.size = Vector2(w, h)
	var floor_body := StaticBody3D.new()
	floor_body.collision_layer = 1
	add_child(floor_body)
	var floor_node := MeshInstance3D.new()
	floor_node.mesh = floor_mesh
	floor_node.material_override = dark
	floor_node.position = Vector3(cx, -0.02, cz)
	add_child(floor_node)
	var fcs := CollisionShape3D.new()
	var fshape := BoxShape3D.new()
	fshape.size = Vector3(w, 0.2, h)
	fcs.shape = fshape
	fcs.position = Vector3(cx, -0.12, cz)
	floor_body.add_child(fcs)

func _room(id: String) -> Dictionary:
	for r in rooms:
		if r.id == id: return r
	return {}

func _mark_rooms() -> void:
	for r in rooms:
		var h: int = r.size / 2
		for dx in range(-h, h + 1):
			for dz in range(-h, h + 1):
				_room_cells[Vector2i(r.cx + dx, r.cz + dz)] = r.id

func _route(a_id: String, b_id: String) -> void:
	var a := _room(a_id)
	var b := _room(b_id)
	var x: int = a.cx
	var z: int = a.cz
	var step_x: int = 1 if b.cx > x else -1
	var step_z: int = 1 if b.cz > z else -1
	while x != b.cx:
		x += step_x
		_try_corridor(x, z)
	while z != b.cz:
		z += step_z
		_try_corridor(x, z)

func _try_corridor(x: int, z: int) -> void:
	var c := Vector2i(x, z)
	if _room_cells.has(c):
		return
	_corridor_cells[c] = true

func _place_rooms() -> void:
	for r in rooms:
		var module: String = "room-small" if r.size == 3 else ("room-large" if r.size == 5 else "room-wide")
		var node := _instance(module)
		node.position = Vector3(r.cx * CELL, 0, r.cz * CELL)
		add_child(node)

func _place_corridors() -> void:
	for c in _corridor_cells.keys():
		var conns := 0
		var dirs := 0  # N=1 E=2 S=4 W=8
		if _corridor_cells.has(c + Vector2i(0, -1)) or _room_cells.has(c + Vector2i(0, -1)):
			conns += 1
			dirs |= 1
		if _corridor_cells.has(c + Vector2i(1, 0)) or _room_cells.has(c + Vector2i(1, 0)):
			conns += 1
			dirs |= 2
		if _corridor_cells.has(c + Vector2i(0, 1)) or _room_cells.has(c + Vector2i(0, 1)):
			conns += 1
			dirs |= 4
		if _corridor_cells.has(c + Vector2i(-1, 0)) or _room_cells.has(c + Vector2i(-1, 0)):
			conns += 1
			dirs |= 8
		var module := _corridor_module(conns, dirs)
		var rot := _corridor_rotation(module, dirs)
		var node := _instance(module)
		node.position = Vector3(c.x * CELL, 0, c.y * CELL)
		node.rotation.y = rot
		add_child(node)

func _corridor_module(conns: int, dirs: int) -> String:
	if conns <= 1:
		return "corridor-end"
	if conns == 2:
		if dirs == 5 or dirs == 10:
			return "corridor"  # straight N-S or E-W
		return "corridor-corner"
	if conns == 3:
		return "corridor-junction"
	return "corridor-intersection"

func _corridor_rotation(module: String, dirs: int) -> float:
	# Base orientations determined by visual testing; adjusted per module.
	match module:
		"corridor":
			if dirs == 10:  # E-W
				return PI / 2.0
			return 0.0
		"corridor-corner":
			match dirs:
				3: return 0.0            # N+E
				6: return -PI / 2.0      # E+S
				12: return PI            # S+W
				9: return PI / 2.0       # W+N
		"corridor-junction":
			match dirs:
				7: return 0.0            # N+E+S (missing W)
				14: return -PI / 2.0     # E+S+W
				13: return PI            # S+W+N
				11: return PI / 2.0      # W+N+E
		"corridor-end":
			match dirs:
				1: return PI             # opening N
				4: return 0.0            # opening S
				2: return PI / 2.0       # opening E
				8: return -PI / 2.0      # opening W
	return 0.0

func _place_walls() -> void:
	# Solid blocks around the perimeter of used space to prevent escapes.
	var min_x := 100000
	var max_x := -100000
	var min_z := 100000
	var max_z := -100000
	for c in _room_cells.keys():
		min_x = mini(min_x, c.x); max_x = maxi(max_x, c.x)
		min_z = mini(min_z, c.y); max_z = maxi(max_z, c.y)
	for c in _corridor_cells.keys():
		min_x = mini(min_x, c.x); max_x = maxi(max_x, c.x)
		min_z = mini(min_z, c.y); max_z = maxi(max_z, c.y)
	var wall := _instance("template-wall")
	for x in range(min_x - 1, max_x + 2):
		for z in [min_z - 1, max_z + 1]:
			var n := wall.duplicate()
			n.position = Vector3(x * CELL, 0, z * CELL)
			add_child(n)
	for z in range(min_z, max_z + 1):
		for x in [min_x - 1, max_x + 1]:
			var n := wall.duplicate()
			n.position = Vector3(x * CELL, 0, z * CELL)
			add_child(n)

func _instance(module: String) -> Node3D:
	if not _module_cache.has(module):
		_module_cache[module] = load(CAVE_DIR + module + ".glb")
	var node: Node3D = _module_cache[module].instantiate()
	_add_collision(node)
	return node

func _add_collision(node: Node3D) -> void:
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	body.name = "Body"
	node.add_child(body)
	for mi in _meshes(node):
		if mi.mesh == null:
			continue
		var xf := Transform3D.IDENTITY
		var n: Node = mi
		while n != node and n != null:
			xf = n.transform * xf
			n = n.get_parent()
		var shape: Shape3D = mi.mesh.create_trimesh_shape()
		if shape == null:
			continue
		var cs := CollisionShape3D.new()
		cs.shape = shape
		cs.transform = xf
		body.add_child(cs)

func _meshes(n: Node) -> Array:
	var out := []
	if n is MeshInstance3D:
		out.append(n)
	for c in n.get_children():
		out.append_array(_meshes(c))
	return out

func debug_dump() -> void:
	var min_x := 100000
	var max_x := -100000
	var min_z := 100000
	var max_z := -100000
	for c in _room_cells.keys():
		min_x = mini(min_x, c.x); max_x = maxi(max_x, c.x)
		min_z = mini(min_z, c.y); max_z = maxi(max_z, c.y)
	for c in _corridor_cells.keys():
		min_x = mini(min_x, c.x); max_x = maxi(max_x, c.x)
		min_z = mini(min_z, c.y); max_z = maxi(max_z, c.y)
	for z in range(min_z, max_z + 1):
		var line := ""
		for x in range(min_x, max_x + 1):
			var c := Vector2i(x, z)
			if _room_cells.has(c): line += "R"
			elif _corridor_cells.has(c): line += "#"
			else: line += "."
		print(line)

func apply_checkpoint(zone_id: int) -> void:
	if int(GameState.checkpoint.get("zone", 0)) != zone_id:
		return
	var pos_arr = GameState.checkpoint.get("pos", [])
	var p := get_node_or_null("Player")
	if p and pos_arr.size() == 3:
		p.global_position = Vector3(pos_arr[0], pos_arr[1], pos_arr[2])
