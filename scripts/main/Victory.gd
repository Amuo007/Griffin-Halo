extends Node3D
## Victory: epilogue cutscene then results screen.

func _ready() -> void:
	await get_tree().create_timer(0.3).timeout
	GameFlow.run_victory()
