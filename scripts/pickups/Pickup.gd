extends Area3D
## World pickup: gun / ammo / food / battery / lore. Auto-collect on touch or E.

@export var pickup_type: String = "gun"     # gun|ammo|food|battery|lore
@export var gun_id: String = "pistol"
@export var lore_id: String = ""
@export var model_path: String = ""
@export var bob_speed: float = 2.0

var _collected: bool = false
var _base_y: float = 0.0
var _time: float = 0.0
var _glow: OmniLight3D = null

func _ready() -> void:
	_base_y = position.y
	collision_layer = 8          # Pickups layer 4
	collision_mask = 4           # detect player layer 3
	body_entered.connect(_on_body_entered)
	var cs := CollisionShape3D.new()
	var sh := SphereShape3D.new()
	sh.radius = 0.5
	cs.shape = sh
	add_child(cs)
	if model_path != "":
		var scene: PackedScene = load(model_path)
		var model := scene.instantiate()
		model.scale = Vector3(0.6, 0.6, 0.6)
		add_child(model)
	_glow = OmniLight3D.new()
	_glow.light_color = Color(0.4, 0.9, 1.0) if pickup_type != "gun" else Color(1.0, 0.8, 0.3)
	_glow.light_energy = 0.8
	_glow.omni_range = 2.5
	add_child(_glow)

func _process(delta: float) -> void:
	_time += delta
	position.y = _base_y + sin(_time * bob_speed) * 0.08
	rotation.y += delta * 1.2

func _on_body_entered(body: Node) -> void:
	if body is CharacterBody3D and not _collected:
		interact(body)

func interact(_player: Node) -> void:
	if _collected:
		return
	match pickup_type:
		"gun":
			GameState.add_weapon(gun_id)
			GameState.set_flag("gun_" + gun_id)
		"ammo":
			var gid: String = GameState.current_gun_id()
			if gid == "":
				return
			GameState.ammo[gid] = GameState.ammo.get(gid, 0) + Balance.AMMO_PER_PICKUP
		"food":
			GameState.food_inventory += 1
		"battery":
			GameState.torch_battery = minf(Balance.TORCH_MAX, GameState.torch_battery + Balance.TORCH_BATTERY_PICKUP)
		"lore":
			if lore_id in GameState.lore_found:
				return
			GameState.lore_found.append(lore_id)
			DialogueRunner.show_lore(lore_id)
	_collected = true
	var t := create_tween()
	t.tween_property(self, "scale", Vector3.ZERO, 0.2)
	t.tween_callback(queue_free)
