extends SceneTree
func _initialize() -> void:
	var sm := AnimationNodeStateMachine.new()
	sm.add_node(&"Locomotion", AnimationNodeAnimation.new())
	sm.initial_node = &"Locomotion"
	print("initial_node ok: ", sm.initial_node)
	quit()
