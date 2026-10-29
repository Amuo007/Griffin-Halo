extends Area3D
## Scripted thriller event trigger: flicker, roar, whisper, spawn.

@export var event_type: String = "flicker"   # flicker|roar|whisper|spawn
@export var speaker: String = ""
@export var line_text: String = ""
@export var spawn_species: String = "fox"
@export var shake_amount: float = 0.6
@export var once: bool = true

var _fired: bool = false

func _ready() -> void:
	collision_layer = 16
	collision_mask = 4
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = Vector3(6, 4, 6)
	cs.shape = sh
	add_child(cs)
	body_entered.connect(_on_body)

func _on_body(body: Node) -> void:
	if _fired or not (body is CharacterBody3D):
		return
	_fired = true
	var player := body as CharacterBody3D
	match event_type:
		"flicker":
			_flicker()
		"roar":
			if player:
				player.add_shake(shake_amount)
			DialogueRunner.line_started.emit(speaker, line_text)
			get_tree().call_group("enemy_ai", "on_noise", global_position, 20.0)
		"whisper":
			DialogueRunner.line_started.emit(speaker, line_text)
		"spawn":
			var zone := get_tree().get_first_node_in_group("maze")
			if zone:
				var e = preload("res://scenes/enemies/Enemy.tscn").instantiate()
				e.species_id = spawn_species
				e.position = global_position
				zone.add_child(e)
	if not once:
		_fired = false

func _flicker() -> void:
	var lights := get_tree().get_nodes_in_group("torch_lights")
	for l in lights:
		if l.position.distance_to(global_position) < 14.0:
			var t := create_tween()
			for i in 6:
				t.tween_property(l, "light_energy", randf_range(0.0, 0.4), 0.12)
				t.tween_property(l, "light_energy", 1.4, 0.1)
