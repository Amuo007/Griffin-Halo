extends CharacterBody3D
## Third-person player: movement, camera, crouch, sprint, dodge, torch, combat.

signal noise_emitted(pos, radius)
signal hp_changed(hp)
signal stamina_changed(pct)
signal torch_changed(on, battery_pct)
signal ammo_changed(gun_id, rounds)
signal aim_changed(aiming)
signal weapon_changed(gun_id)

@onready var character: Node3D = $Character
@onready var anim_tree: AnimationTree = $Character/AnimationTree
@onready var skeleton: Skeleton3D = $Character/Root/Skeleton3D
@onready var spring: SpringArm3D = $SpringArm
@onready var camera: Camera3D = $SpringArm/Camera3D
@onready var flashlight: SpotLight3D = $SpringArm/Camera3D/Flashlight
@onready var collision: CollisionShape3D = $Collision
@onready var gun_point: Node3D = $Character/Root/Skeleton3D/GunPoint

var yaw: float = 0.0
var pitch: float = 0.0
var crouch_amount: float = 0.0        # 0..1 smoothed
var crouching: bool = false
var sprinting: bool = false
var grounded: bool = false
var dodge_timer: float = 0.0
var dodge_cooldown: float = 0.0
var iframes: float = 0.0
var move_speed: float = 0.0
var noise_timer: float = 0.0
var _bob_time: float = 0.0
var _aim_amount: float = 0.0
var aiming: bool = false
var _recoil_kick: float = 0.0
var _shake: float = 0.0
var _fire_cooldown: float = 0.0
var _gun_instance: Node3D = null
var _muzzle: OmniLight3D = null
var _empty_click_time: float = 0.0

func _ready() -> void:
	add_to_group("player")
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	anim_tree.active = true
	var playback = anim_tree.get("parameters/playback")
	if playback:
		playback.travel("Locomotion")
	_update_flashlight()
	_muzzle = OmniLight3D.new()
	_muzzle.light_color = Color(1.0, 0.75, 0.4)
	_muzzle.light_energy = 0.0
	_muzzle.omni_range = 6.0
	gun_point.add_child(_muzzle)
	_refresh_gun()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var sens: float = Balance.mouse_sens * (1.0 if not aiming else 0.55)
		yaw -= event.relative.x * sens
		pitch = clampf(pitch - event.relative.y * sens, -1.2, 0.9)
	if event.is_action_pressed("flashlight"):
		GameState.torch_on = not GameState.torch_on
		_update_flashlight()
	if event.is_action_pressed("dodge"):
		_try_dodge()
	if event.is_action_pressed("aim"):
		aiming = true
		aim_changed.emit(true)
	if event.is_action_released("aim"):
		aiming = false
		aim_changed.emit(false)
	if event.is_action_pressed("fire"):
		_try_fire()
	if event.is_action_pressed("interact"):
		_try_interact()
	if event.is_action_pressed("pause") and GameState.mode == GameState.Mode.PLAY:
		get_tree().paused = not get_tree().paused
		if get_tree().paused:
			GameState.previous_mode = GameState.Mode.PLAY
			GameState.mode = GameState.Mode.PAUSED
		else:
			GameState.mode = GameState.Mode.PLAY
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if get_tree().paused else Input.MOUSE_MODE_CAPTURED

func _physics_process(delta: float) -> void:
	if GameState.mode != GameState.Mode.PLAY:
		return
	grounded = is_on_floor()
	if not grounded:
		velocity.y -= Balance.WALK_SPEED * Balance.GRAVITY_MULT * delta * 2.0
	else:
		velocity.y = minf(velocity.y, 0.0)

	crouching = Input.is_action_pressed("crouch")
	sprinting = Input.is_action_pressed("sprint") and not crouching and _has_stamina()
	crouch_amount = move_toward(crouch_amount, 1.0 if crouching else 0.0, delta * 8.0)

	var input_dir := Input.get_vector("move_left", "move_right", "move_back", "move_forward")
	var cam_f := -camera.global_transform.basis.z
	cam_f.y = 0.0
	cam_f = cam_f.normalized()
	var cam_r := camera.global_transform.basis.x
	cam_r.y = 0.0
	cam_r = cam_r.normalized()
	var local_move := cam_r * input_dir.x - cam_f * input_dir.y
	var target_speed := Balance.WALK_SPEED
	if crouching:
		target_speed = Balance.CROUCH_SPEED
	elif sprinting:
		target_speed = Balance.SPRINT_SPEED
	elif input_dir.length() > 0.1:
		target_speed = Balance.RUN_SPEED
	if dodge_timer > 0.0:
		target_speed = 0.0  # dodge impulse carries us

	var direction := local_move.normalized() if local_move.length() > 0.1 else Vector3.ZERO
	if direction != Vector3.ZERO and dodge_timer <= 0.0:
		var target_vel := direction * target_speed
		velocity.x = move_toward(velocity.x, target_vel.x, Balance.ACCEL * delta)
		velocity.z = move_toward(velocity.z, target_vel.z, Balance.ACCEL * delta)
		# face movement direction smoothly
		var target_yaw := atan2(-direction.x, -direction.z)
		rotation.y = _angle_lerp(rotation.y, target_yaw, 12.0 * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, Balance.DECEL * delta)
		velocity.z = move_toward(velocity.z, 0.0, Balance.DECEL * delta)

	if grounded and Input.is_action_just_pressed("jump") and not crouching:
		velocity.y = Balance.JUMP_VELOCITY
		emit_noise(Balance.NOISE_WALK)

	if dodge_timer > 0.0:
		dodge_timer -= delta
	if dodge_cooldown > 0.0:
		dodge_cooldown -= delta
	if iframes > 0.0:
		iframes -= delta

	# stamina
	if sprinting and move_speed > Balance.RUN_SPEED * 0.9:
		GameState.stamina = maxf(0.0, GameState.stamina - Balance.SPRINT_DRAIN * delta)
	else:
		GameState.stamina = minf(Balance.STAMINA_MAX, GameState.stamina + Balance.STAMINA_REGEN * delta)
	stamina_changed.emit(GameState.stamina / Balance.STAMINA_MAX)

	move_and_slide()
	move_speed = Vector2(velocity.x, velocity.z).length()

	# footstep noise
	noise_timer -= delta
	if grounded and move_speed > 0.5 and noise_timer <= 0.0:
		var radius := Balance.NOISE_CROUCH if crouching else (Balance.NOISE_SPRINT if sprinting else (Balance.NOISE_RUN if move_speed > Balance.RUN_SPEED * 0.9 else Balance.NOISE_WALK))
		emit_noise(radius)
		noise_timer = 0.45 if crouching else 0.32

	# torch battery
	if GameState.torch_on and GameState.torch_battery > 0.0:
		GameState.torch_battery = maxf(0.0, GameState.torch_battery - Balance.TORCH_DRAIN * delta)
		if GameState.torch_battery <= 0.0:
			GameState.torch_on = false
		_update_flashlight()
		torch_changed.emit(GameState.torch_on, GameState.torch_battery / Balance.TORCH_MAX)

	_update_camera(delta)
	_update_animation(delta)
	_update_combat(delta)

func _update_combat(delta: float) -> void:
	_fire_cooldown = maxf(0.0, _fire_cooldown - delta)
	_aim_amount = move_toward(_aim_amount, 1.0 if aiming else 0.0, delta * 7.0)
	var gun_id: String = GameState.current_gun_id()
	if gun_id != "":
		var gun: Dictionary = Balance.GUNS[gun_id]
		if gun.get("auto", false) and Input.is_action_pressed("fire"):
			_try_fire()
	_refresh_gun()

func _try_fire() -> void:
	var gun_id: String = GameState.current_gun_id()
	if gun_id == "" or _fire_cooldown > 0.0:
		return
	var rounds: int = GameState.ammo.get(gun_id, 0)
	if rounds <= 0:
		if _empty_click_time <= 0.0:
			_empty_click_time = 0.5
			ammo_changed.emit(gun_id, 0)
		return
	_empty_click_time = 0.0
	var gun: Dictionary = Balance.GUNS[gun_id]
	GameState.ammo[gun_id] = rounds - 1
	_fire_cooldown = gun.fire_rate
	ammo_changed.emit(gun_id, rounds - 1)
	_fire_once(gun)

func _fire_once(gun: Dictionary) -> void:
	var spread: float = gun.spread if not aiming else gun.aim_spread
	var pellets: int = gun.get("pellets", 1)
	var base_dir := -camera.global_transform.basis.z.normalized()
	for i in pellets:
		var dir := base_dir
		if spread > 0.0:
			dir = base_dir.rotated(Vector3.RIGHT, randf_range(-spread, spread)).rotated(Vector3.UP, randf_range(-spread, spread))
		var query := PhysicsRayQueryParameters3D.create(
			camera.global_position, camera.global_position + dir * 120.0,
			0xFFFFFFFF & ~0b100)  # all except player layer
		var hit := get_world_3d().direct_space_state.intersect_ray(query)
		var end := camera.global_position + dir * 60.0
		if hit:
			end = hit.position
			var collider: Node = hit.collider
			var enemy := _find_ancestor_with(collider, "take_damage")
			if enemy:
				enemy.take_damage(gun.damage, dir)
			_spawn_impact(end, hit.normal if hit.has("normal") else -dir)
		_spawn_tracer(_muzzle.global_position, end)
	_muzzle.light_energy = 5.0
	add_recoil(gun.recoil)
	add_shake(gun.shake)
	emit_noise(Balance.NOISE_GUNSHOT)
	# muzzle flash decay handled in _process via timer
	get_tree().create_timer(0.06).timeout.connect(func(): if _muzzle: _muzzle.light_energy = 0.0)

func _spawn_tracer(from: Vector3, to: Vector3) -> void:
	var mesh := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	var length := from.distance_to(to)
	cyl.top_radius = 0.012
	cyl.bottom_radius = 0.012
	cyl.height = length
	var mat := StandardMaterial3D.new()
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.85, 0.5)
	mat.emission_energy_multiplier = 3.0
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh.mesh = cyl
	mesh.material_override = mat
	get_tree().root.add_child(mesh)
	mesh.global_transform = Transform3D(Basis(), from.lerp(to, 0.5))
	mesh.global_basis = Basis(Vector3.UP, 0).looking_at((to - from).normalized(), Vector3.UP) * Basis(Vector3.RIGHT, PI / 2.0)
	var t := get_tree().create_tween()
	t.tween_property(mesh, "transparency", 1.0, 0.12)
	t.tween_callback(mesh.queue_free)

func _spawn_impact(pos: Vector3, normal: Vector3) -> void:
	var mesh := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.05
	sm.height = 0.1
	mesh.mesh = sm
	var mat := StandardMaterial3D.new()
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.6, 0.2)
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh.material_override = mat
	mesh.position = pos + normal * 0.03
	add_child(mesh)
	var t := get_tree().create_tween()
	t.tween_property(mesh, "scale", Vector3(2.2, 2.2, 2.2), 0.1)
	t.tween_callback(mesh.queue_free)

func _find_ancestor_with(node: Node, method: String) -> Node:
	var n: Node = node
	while n != null:
		if n.has_method(method):
			return n
		n = n.get_parent()
	return null

func _try_interact() -> void:
	var query := PhysicsRayQueryParameters3D.create(
		camera.global_position, camera.global_position + (-camera.global_transform.basis.z) * 2.6, 0xFFFFFFFF & ~0b100)
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit:
		var target := _find_ancestor_with(hit.collider, "interact")
		if target:
			target.interact(self)

func _refresh_gun() -> void:
	var gun_id: String = GameState.current_gun_id()
	var current_name: String = _gun_instance.name if _gun_instance else ""
	if current_name == gun_id:
		return
	if _gun_instance:
		_gun_instance.queue_free()
		_gun_instance = null
	if gun_id == "":
		return
	var scene: PackedScene = load("res://assets/game/blasters/%s.glb" % Balance.GUNS[gun_id].model)
	_gun_instance = scene.instantiate()
	_gun_instance.name = gun_id
	_gun_instance.scale = Vector3(0.55, 0.55, 0.55)
	_gun_instance.rotation = Vector3(PI / 2.0, 0, PI)
	gun_point.add_child(_gun_instance)
	weapon_changed.emit(gun_id)

func _update_camera(delta: float) -> void:
	var shoulder_y: float = lerp(Balance.CAM_SHOULDER.y, Balance.CAM_SHOULDER.y - 0.55, crouch_amount)
	var shoulder_x: float = lerp(Balance.CAM_SHOULDER.x, Balance.CAM_SHOULDER_AIM.x, _aim_amount)
	spring.global_position = global_position + Basis(Vector3.UP, yaw) * Vector3(shoulder_x, shoulder_y, 0)
	spring.global_transform.basis = Basis.from_euler(Vector3(pitch + _recoil_kick, yaw, 0))
	spring.spring_length = lerp(Balance.CAM_DISTANCE, Balance.CAM_DISTANCE_AIM, _aim_amount)
	camera.fov = lerp(Balance.CAM_FOV, Balance.CAM_FOV_AIM, _aim_amount)
	_recoil_kick = move_toward(_recoil_kick, 0.0, delta * 6.0)
	_shake = move_toward(_shake, 0.0, delta * 2.0)
	if _shake > 0.0:
		camera.position = Vector3(randf_range(-_shake, _shake), randf_range(-_shake, _shake), 0) * 0.1
	else:
		camera.position = Vector3.ZERO

func _update_animation(delta: float) -> void:
	var speed_param := clampf(move_speed / Balance.RUN_SPEED, 0.0, 1.0) * 2.0 - 1.0
	anim_tree.set("parameters/speed/blend_position", speed_param)
	anim_tree.set("parameters/is_airborne/advance_condition", not grounded)
	# additive crouch pose on spine/hips
	if skeleton:
		var hips := skeleton.find_bone("Hips")
		var spine := skeleton.find_bone("Spine")
		var chest := skeleton.find_bone("Chest")
		if hips >= 0:
			var rest_pos := skeleton.get_bone_rest(hips).origin
			skeleton.set_bone_pose_position(hips, rest_pos + Vector3(0, -0.28 * crouch_amount, 0))
		if spine >= 0:
			skeleton.set_bone_pose_rotation(spine, skeleton.get_bone_rest(spine).basis.get_rotation_quaternion() * Quaternion(Vector3(1, 0, 0), 0.5 * crouch_amount))
		if chest >= 0:
			skeleton.set_bone_pose_rotation(chest, skeleton.get_bone_rest(chest).basis.get_rotation_quaternion() * Quaternion(Vector3(1, 0, 0), 0.25 * crouch_amount))
		# gun-hold / aim arm pose
		if GameState.current_gun_id() != "":
			var w := 0.5 + 0.5 * _aim_amount
			var rarm := skeleton.find_bone("RightArm")
			var larm := skeleton.find_bone("LeftArm")
			if rarm >= 0:
				var rest := skeleton.get_bone_rest(rarm).basis.get_rotation_quaternion()
				skeleton.set_bone_pose_rotation(rarm, rest * Quaternion(Vector3(1, 0, 0), -1.15 * w))
			if larm >= 0:
				var rest2 := skeleton.get_bone_rest(larm).basis.get_rotation_quaternion()
				skeleton.set_bone_pose_rotation(larm, rest2 * Quaternion(Vector3(1, 0, 0), -1.05 * w))

func _try_dodge() -> void:
	if dodge_cooldown > 0.0 or GameState.stamina < Balance.DODGE_STAMINA_COST:
		return
	var dir := Vector3(0, 0, -1)
	var input_dir := Input.get_vector("move_left", "move_right", "move_back", "move_forward")
	if input_dir.length() > 0.1:
		dir = (Vector3(input_dir.x, 0, input_dir.y) * global_transform.basis.orthonormalized()).normalized()
	else:
		dir = -global_transform.basis.z.normalized()
	velocity.x = dir.x * Balance.DODGE_IMPULSE
	velocity.z = dir.z * Balance.DODGE_IMPULSE
	dodge_timer = 0.3
	dodge_cooldown = Balance.DODGE_COOLDOWN
	iframes = Balance.DODGE_IFRAMES
	GameState.stamina -= Balance.DODGE_STAMINA_COST
	emit_noise(Balance.NOISE_DODGE)

func emit_noise(radius: float) -> void:
	noise_emitted.emit(global_position, radius)
	get_tree().call_group("enemy_ai", "on_noise", global_position, radius)

func take_damage(amount: float, from_dir: Vector3 = Vector3.ZERO) -> void:
	if iframes > 0.0:
		return
	iframes = 0.6
	GameState.damage_player(amount)
	hp_changed.emit(GameState.hp)
	add_shake(0.5)
	if from_dir.length() > 0.1:
		velocity += from_dir.normalized() * 3.0

func add_shake(amount: float) -> void:
	_shake = minf(1.5, _shake + amount)

func add_recoil(amount: float) -> void:
	_recoil_kick += amount * 0.02

func _has_stamina() -> bool:
	return GameState.stamina > 5.0

func _update_flashlight() -> void:
	flashlight.visible = GameState.torch_on and GameState.torch_battery > 0.0

func _angle_lerp(a: float, b: float, weight: float) -> float:
	var diff := wrapf(b - a + PI, 0.0, TAU) - PI
	return a + diff * clampf(weight, 0.0, 1.0)
