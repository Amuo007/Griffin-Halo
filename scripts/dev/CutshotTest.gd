extends Node3D
## Captures a frame mid-cutscene to verify the screen is not black.
func _ready() -> void:
	var tree := get_tree()
	tree.root.remove_child.call_deferred(self)
	await tree.process_frame
	tree.change_scene_to_file("res://scenes/zones/Zone1.tscn")
	await tree.create_timer(1.5).timeout
	DialogueRunner.play_cutscene("wake")
	await tree.create_timer(3.0).timeout
	var img := tree.root.get_texture().get_image()
	img.save_png("res://tests/shots/cutscene_live.png")
	print("CUTSHOT saved, fade_a=", DialogueRunner._fade_rect.color.a)
	tree.quit()
