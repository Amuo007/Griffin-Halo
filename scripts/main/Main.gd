extends Node
## Game boot + scene flow manager.

func _ready() -> void:
	print("[GRIFIN] boot ok, godot ", Engine.get_version_info().string)
	GameState.mode = GameState.Mode.MENU
	# Phase 8: switch to MainMenu scene. For now load gameplay test scene.
	call_deferred("_change_scene", "res://scenes/dev/DevScene.tscn")

func _change_scene(path: String) -> void:
	get_tree().change_scene_to_file(path)

func start_game() -> void:
	GameState.reset_run()
	GameState.mode = GameState.Mode.PLAY
	get_tree().change_scene_to_file("res://scenes/zones/Zone1.tscn")
