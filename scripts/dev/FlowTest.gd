extends Node3D
## Headless flow test: menu -> intro -> zone1 -> wake.

func _ready() -> void:
	var tree := get_tree()
	tree.root.remove_child.call_deferred(self)
	await tree.process_frame
	GameFlow.start_game()
	await tree.create_timer(1.5).timeout
	DialogueRunner.skip()
	await tree.create_timer(2.0).timeout
	DialogueRunner.skip()
	await tree.create_timer(2.0).timeout
	print("FLOW scene=", tree.current_scene.name, " mode=", GameState.mode, " obj=", GameState.objective)
	tree.quit()
