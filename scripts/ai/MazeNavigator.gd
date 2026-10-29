class_name MazeNavigator
extends RefCounted
## A* pathfinding on the 4m maze cell grid.

static func find_path(walkable: Dictionary, from_world: Vector3, to_world: Vector3, cell: float) -> PackedVector3Array:
	var start := world_to_cell(from_world, cell)
	var goal := world_to_cell(to_world, cell)
	if not walkable.has(start) or not walkable.has(goal):
		return [to_world]
	if start == goal:
		return [to_world]
	var open := {start: true}
	var came := {}
	var g := {start: 0.0}
	var f := {start: _h(start, goal)}
	var dirs4 := [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	var guard := 0
	while not open.is_empty() and guard < 4000:
		guard += 1
		# pop lowest f
		var best: Vector2i = start
		var first := true
		for k in open.keys():
			if first or f[k] < f[best]:
				best = k
				first = false
		var current: Vector2i = best
		open.erase(current)
		if current == goal:
			return _reconstruct(came, goal, cell)
		for d in dirs4:
			var n: Vector2i = current + d
			if not walkable.has(n):
				continue
			var tentative: float = g[current] + 1.0
			if tentative < g.get(n, INF):
				came[n] = current
				g[n] = tentative
				f[n] = tentative + _h(n, goal)
				open[n] = true
	return [to_world]  # no path: beeline (may bump walls)

static func world_to_cell(w: Vector3, cell: float) -> Vector2i:
	return Vector2i(int(round(w.x / cell)), int(round(w.z / cell)))

static func cell_to_world(c: Vector2i, cell: float) -> Vector3:
	return Vector3(c.x * cell, 0, c.y * cell)

static func _h(a: Vector2i, b: Vector2i) -> float:
	return absf(a.x - b.x) + absf(a.y - b.y)

static func _reconstruct(came: Dictionary, current: Vector2i, cell: float) -> PackedVector3Array:
	var path := PackedVector3Array()
	while came.has(current):
		path.append(cell_to_world(current, cell))
		current = came[current]
	path.reverse()
	return path
