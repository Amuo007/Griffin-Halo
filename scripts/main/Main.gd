extends Node
## Game boot + scene flow manager.

func _ready() -> void:
	print("[GRIFIN] boot ok, godot ", Engine.get_version_info().string)
	GameState.mode = GameState.Mode.MENU
	# Phase 8: switch to MainMenu scene. For now load gameplay test scene.
	call_deferred("_boot")

func _boot() -> void:
	GameFlow.start_game()


