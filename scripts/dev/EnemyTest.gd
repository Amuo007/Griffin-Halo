extends Node3D
func _ready() -> void:
	await get_tree().create_timer(0.5).timeout
	var zone := get_node("../Zone1")
	var player := get_tree().get_first_node_in_group("player")
	if player:
		player.global_position = Vector3(14 * 4.0, 0.1, 7 * 4.0)
		player.yaw = PI  # face +Z toward fox at (14,9)
