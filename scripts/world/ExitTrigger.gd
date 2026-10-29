extends Area3D
## Zone exit: moves the player to the next zone.

@export var next_scene: String = "res://scenes/zones/Zone2.tscn"
@export var next_zone: int = 2
@export var gate_label: String = "A rusted gate bars the way. Something clicks open."

var _fired: bool = false

func _ready() -> void:
	collision_layer = 16
	collision_mask = 4
	body_entered.connect(_on_body)

func _on_body(body: Node) -> void:
	if _fired or not (body is CharacterBody3D):
		return
	_fired = true
	GameState.zone = next_zone
	GameState.set_objective("")
	get_tree().change_scene_to_file(next_scene)
