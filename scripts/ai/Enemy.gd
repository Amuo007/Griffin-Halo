extends CharacterBody3D
## Beast AI: wander -> investigate -> chase -> attack -> lost(search ~4s) -> return.
## Vision cone + LOS raycast (rocks block sight), hearing, pack alert propagation.

@export var species_id: String = "fox"

enum S { IDLE, WANDER, INVESTIGATE, CHASE, ATTACK, LOST, SEARCH, RETURN, DEAD }

var state: int = S.IDLE
var def: Dictionary = {}
var hp: float = 50.0
var home: Vector3 = Vector3.ZERO
var player: Node3D = null
var maze: Node = null
var path: PackedVector3Array = []
var path_index: int = 0
var path_timer: float = 0.0
var last_known: Vector3 = Vector3.ZERO
var lost_timer: float = 0.0
var search_timer: float = 0.0
var attack_cd: float = 0.0
var state_timer: float = 0.0
var _wander_target: Vector3 = Vector3.ZERO
var leg_nodes: Array = []
var eye_l: MeshInstance3D = null
var eye_r: MeshInstance3D = null
var visual: Node3D = null
var _time: float = 0.0
var _frozen_stare: float = 0.0   # freeze-when-seen creepiness
var alerted_by_pack: bool = false

func _ready() -> void:
	add_to_group("enemy_ai")
	def = Species.DEFS[species_id]
	hp = def.hp
	home = global_position
	maze = get_tree().get_first_node_in_group("maze")
	collision_layer = 2
	collision_mask = 1 | 4
	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.35 * def.scale * 0.6
	cap.height = 1.0 * def.scale * 0.8
	cs.shape = cap
	cs.position = Vector3(0, cap.height / 2.0, 0)
	add_child(cs)
	_build_visual()

func _build_visual() -> void:
	var scene: PackedScene = load("res://assets/game/pets/%s.glb" % def.model)
	visual = scene.instantiate()
	visual.scale = Vector3(def.scale, def.scale, def.scale)
	add_child(visual)
	# pale flesh palette swap
	_pale(visual)
	# glowing eyes
	var eye_mat := StandardMaterial3D.new()
	eye_mat.emission_enabled = true
	eye_mat.emission = def.eye
	eye_mat.emission_energy_multiplier = 3.0
	eye_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var eye_size: float = 0.06 * def.scale
	for side in [-1, 1]:
		var e := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = eye_size
		sm.height = eye_size * 2
		e.mesh = sm
		e.material_override = eye_mat
		e.position = Vector3(side * eye_size * 1.6, 0.55 * def.scale, -0.45 * def.scale)
		visual.add_child(e)
		if side < 0: eye_l = e
		else: eye_r = e
	# collect leg nodes for procedural walk
	for n in _all_children(visual):
		if "leg" in n.name.to_lower():
			leg_nodes.append(n)

func _pale(node: Node) -> void:
	for mi in _meshes(node):
		if mi.mesh == null:
			continue
		var src: StandardMaterial3D = mi.mesh.surface_get_material(0) if mi.mesh.get_surface_count() > 0 else null
		var m := StandardMaterial3D.new()
		if src and src.albedo_texture:
			m.albedo_texture = src.albedo_texture
			m.albedo_color = Color(0.75, 0.68, 0.62)  # sickly pale tint
		else:
			m.albedo_color = Color(0.7, 0.62, 0.58)
		m.roughness = 0.9
		mi.material_override = m

func _physics_process(delta: float) -> void:
	if state == S.DEAD:
		return
	_time += delta
	attack_cd = maxf(0.0, attack_cd - delta)
	state_timer += delta
	path_timer -= delta
	player = _find_player()
	_perceive(delta)
	_step(delta)
	_animate(delta)

func _perceive(delta: float) -> void:
	if player == null or not is_instance_valid(player):
		return
	var to_player := player.global_position - global_position
	var dist := to_player.length()
	var sees := _can_see(to_player, dist)
	if sees:
		last_known = player.global_position
		if state in [S.IDLE, S.WANDER, S.INVESTIGATE, S.LOST, S.RETURN]:
			_enter(S.CHASE)
		if state == S.CHASE and dist <= def.attack_range:
			_enter(S.ATTACK)
		if state == S.ATTACK and dist > def.attack_range * 1.4:
			_enter(S.CHASE)
		_frozen_stare = 0.0
	else:
		if state == S.CHASE or state == S.ATTACK:
			lost_timer = Balance.AI_LOST_SEARCH_TIME
			_enter(S.LOST)
		if state == S.LOST:
			lost_timer -= delta
			if lost_timer <= 0.0:
				_enter(S.SEARCH)
				search_timer = 2.5
		elif state == S.SEARCH:
			search_timer -= delta
			if search_timer <= 0.0:
				_enter(S.RETURN)

func _can_see(to_player: Vector3, dist: float) -> bool:
	if dist > def.sight:
		return false
	var fwd := -global_transform.basis.z
	var ang := rad_to_deg(fwd.signed_angle_to(to_player.normalized(), Vector3.UP))
	if absf(ang) > def.fov / 2.0:
		return false
	var target := player.global_position + Vector3(0, 0.8, 0)
	var query := PhysicsRayQueryParameters3D.create(global_position + Vector3(0, 0.6, 0), target, 0b101)
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return true
	var col: Node = hit.collider
	return col == player or col.get_parent() == player

func on_noise(pos: Vector3, radius: float) -> void:
	if state == S.DEAD:
		return
	var d := global_position.distance_to(pos)
	if d <= radius * Balance.AI_HEARING_MULT:
		if state in [S.IDLE, S.WANDER, S.RETURN]:
			last_known = pos
			_enter(S.INVESTIGATE)

func on_alert_heard(pos: Vector3) -> void:
	if state == S.DEAD or state == S.CHASE or state == S.ATTACK:
		return
	if global_position.distance_to(pos) < 18.0:
		last_known = pos
		alerted_by_pack = true
		_enter(S.INVESTIGATE)

func _enter(new_state: int) -> void:
	if state == new_state:
		return
	state = new_state
	state_timer = 0.0
	path = []
	path_timer = 0.0
	match state:
		S.CHASE, S.ATTACK:
			# pack propagation: nearby beasts hear the hunt start
			get_tree().call_group("enemy_ai", "on_alert_heard", global_position)
		S.LOST:
			pass
		S.SEARCH:
			_pick_search_spot()

func _step(delta: float) -> void:
	var speed: float = def.speed
	match state:
		S.IDLE:
			if state_timer > randf_range(2.0, 5.0):
				_enter(S.WANDER)
		S.WANDER:
			if path.is_empty() and state_timer > 0.5:
				_wander_target = _random_walkable_near(home, 12.0)
				_repath(_wander_target)
			speed = def.speed * 0.5
		S.INVESTIGATE:
			speed = def.speed * 0.8
			_repath(last_known)
			if _reached(last_known, 1.5) or state_timer > 8.0:
				_enter(S.SEARCH)
				search_timer = 3.0
		S.CHASE:
			speed = def.sprint
			_repath(last_known)
		S.ATTACK:
			speed = 0.0
			if player:
				var d := global_position.distance_to(player.global_position)
				if d < def.attack_range * 0.7:
					var away := (global_position - player.global_position).normalized()
					velocity.x = away.x * def.speed * 0.6
					velocity.z = away.z * def.speed * 0.6
			if attack_cd <= 0.0 and player and global_position.distance_to(player.global_position) <= def.attack_range * 1.3:
				attack_cd = def.attack_cd
				var dir := (player.global_position - global_position).normalized()
				player.take_damage(def.damage, dir)
		S.LOST:
			speed = def.sprint * 0.9
			_repath(last_known)
		S.SEARCH:
			speed = def.speed * 0.6
			if path.is_empty():
				_pick_search_spot()
		S.RETURN:
			speed = def.speed * 0.7
			_repath(home)
			if _reached(home, 1.5):
				_enter(S.IDLE)
	# ambush species: only sprint when very close
	if def.get("ambush", false) and state in [S.CHASE, S.LOST]:
		speed = def.speed if global_position.distance_to(last_known) > 6.0 else def.sprint
	_follow_path(delta, speed)
	# gravity
	if not is_on_floor():
		velocity.y -= 20.0 * delta
	move_and_slide()
	# face movement/path
	var face := _face_dir()
	if face.length() > 0.1:
		rotation.y = lerp_angle(rotation.y, atan2(-face.x, -face.z), 8.0 * delta)

func _follow_path(delta: float, speed: float) -> void:
	if state == S.ATTACK and path.is_empty():
		return
	if path.is_empty() or speed <= 0.0:
		velocity.x = move_toward(velocity.x, 0.0, 20 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 20 * delta)
		return
	if path_index >= path.size():
		path = []
		return
	var target := path[path_index]
	var to := target - global_position
	to.y = 0
	if to.length() < 0.6:
		path_index += 1
		return
	var dir := to.normalized()
	velocity.x = dir.x * speed
	velocity.z = dir.z * speed

func _repath(target: Vector3) -> void:
	if path_timer > 0.0 and not path.is_empty():
		return
	path_timer = 0.5
	if maze:
		path = maze.find_path(global_position, target)
	else:
		path = [target]
	path_index = 0

func _reached(p: Vector3, r: float) -> bool:
	return global_position.distance_to(p) < r

func _pick_search_spot() -> void:
	if maze:
		_repath(_random_walkable_near(global_position, 8.0))

func _random_walkable_near(origin: Vector3, radius: float) -> Vector3:
	if maze == null:
		return origin
	var cells: Array = maze.walkable_cells().keys()
	for i in 12:
		var c: Vector2i = cells[randi() % cells.size()]
		var w := Vector3(c.x * 4.0, 0, c.y * 4.0)
		if w.distance_to(origin) < radius and w.distance_to(origin) > 2.0:
			return w
	return origin

func _face_dir() -> Vector3:
	if not path.is_empty() and path_index < path.size():
		var d := path[path_index] - global_position
		d.y = 0
		return d
	if player and state in [S.ATTACK, S.CHASE]:
		return player.global_position - global_position
	return Vector3.ZERO

func take_damage(amount: float, from_dir: Vector3 = Vector3.ZERO) -> void:
	if state == S.DEAD:
		return
	hp -= amount
	Gore.blood_burst(get_parent(), global_position + Vector3(0, 0.5 * def.scale, 0), amount)
	if from_dir.length() > 0.1:
		velocity += from_dir.normalized() * 2.0
	if hp <= 0.0:
		_die()
	else:
		# being shot = the whole pack knows
		get_tree().call_group("enemy_ai", "on_alert_heard", global_position)
		if state in [S.IDLE, S.WANDER, S.RETURN, S.SEARCH]:
			last_known = global_position + from_dir * -5.0
			_enter(S.INVESTIGATE)

func _die() -> void:
	state = S.DEAD
	GameState.kills += 1
	var pos := global_position + Vector3(0, 0.4 * def.scale, 0)
	Gore.blood_burst(get_parent(), pos, hp + 60.0)
	Gore.blood_decal(get_tree().current_scene, global_position, 1.2 + def.scale * 0.3)
	# collapse: tip over and sink
	var t := create_tween()
	t.tween_property(visual, "rotation.x", PI / 2.0, 0.4)
	t.tween_property(visual, "position:y", -0.3, 1.2).set_ease(Tween.EASE_IN)
	t.tween_interval(6.0)
	t.tween_property(self, "scale", Vector3(0.01, 0.01, 0.01), 2.0)
	t.tween_callback(queue_free)
	set_collision_layer_value(1, false)
	set_collision_mask_value(1, false)

func _animate(delta: float) -> void:
	if state == S.DEAD:
		return
	var moving := Vector2(velocity.x, velocity.z).length() > 0.5
	var swing := sin(_time * (6.0 + Vector2(velocity.x, velocity.z).length())) * 0.6
	for leg in leg_nodes:
		var f := 1.0 if "front" in leg.name else -1.0
		var l := 1.0 if "left" in leg.name else -1.0
		leg.rotation.x = swing * f * l if moving else 0.0
	# eye flicker when hunting
	if eye_l and state in [S.CHASE, S.ATTACK]:
		var flick := 2.0 + sin(_time * 20.0)
		eye_l.material_override.emission_energy_multiplier = flick
		eye_r.material_override.emission_energy_multiplier = flick
	# hover bob for bees
	if def.get("hover", false):
		visual.position.y = 0.6 + sin(_time * 5.0) * 0.15

func _find_player() -> Node3D:
	return get_tree().get_first_node_in_group("player")

func _meshes(n: Node) -> Array:
	var out := []
	if n is MeshInstance3D:
		out.append(n)
	for c in n.get_children():
		out.append_array(_meshes(c))
	return out

func _all_children(n: Node) -> Array:
	var out := []
	for c in n.get_children():
		out.append(c)
		out.append_array(_all_children(c))
	return out
