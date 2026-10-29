extends CharacterBody3D
## Third-person player: movement, camera, crouch, sprint, dodge, torch.

signal noise_emitted(pos, radius)
signal hp_changed(hp)
signal stamina_changed(pct)
signal torch_changed(on, battery_pct)

@onready var character: Node3D = $Character
@onready var anim_tree: AnimationTree = $Character/AnimationTree
@onready var skeleton: Skeleton3D = $Character/Root/Skeleton3D
@onready var spring: SpringArm3D = $SpringArm
@onready var camera: Camera3D = $SpringArm/Camera3D
@onready var flashlight: SpotLight3D = $SpringArm/Camera3D/Flashlight
@onready var collision: CollisionShape3D = $Collision

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
var _aim_amount: float = 0.0          # Phase 4: ADS blend
var _recoil_kick: float = 0.0
var _shake: float = 0.0

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	anim_tree.active = true
	var playback = anim_tree.get("parameters/playback")
	if playback:
		playback.travel("Locomotion")
	_update_flashlight()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var sens: float = Balance.MOUSE_SENS_BASE
		yaw -= event.relative.x * sens
		pitch = clampf(pitch - event.relative.y * sens, -1.2, 0.9)
	if event.is_action_pressed("flashlight"):
		GameState.torch_on = not GameState.torch_on
		_update_flashlight()
	if event.is_action_pressed("dodge"):
		_try_dodge()
	if event.is_action_pressed("pause"):
		get_tree().paused = not get_tree().paused
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if get_tree().paused else Input.MOUSE_MODE_CAPTURED

func _physics_process(delta: float) -> void:
	grounded = is_on_floor()
	if not grounded:
		velocity.y -= Balance.WALK_SPEED * Balance.GRAVITY_MULT * delta * 2.0
	else:
		velocity.y = minf(velocity.y, 0.0)

	crouching = Input.is_action_pressed("crouch")
	sprinting = Input.is_action_pressed("sprint") and not crouching and _has_stamina()
	crouch_amount = move_toward(crouch_amount, 1.0 if crouching else 0.0, delta * 8.0)

	var input_dir := Input.get_vector("move_left", "move_right", "move_back", "move_forward")
	var local_move := (Vector3(input_dir.x, 0, input_dir.y) * global_transform.basis.orthonormalized())
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

func _update_camera(delta: float) -> void:
	var shoulder_y: float = lerp(Balance.CAM_SHOULDER.y, Balance.CAM_SHOULDER.y - 0.55, crouch_amount)
	spring.global_position = global_position + Basis(Vector3.UP, yaw) * Vector3(Balance.CAM_SHOULDER.x, shoulder_y, 0)
	spring.global_transform.basis = Basis.from_euler(Vector3(pitch + _recoil_kick, yaw, 0))
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
