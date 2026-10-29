extends SceneTree
## Screenshot tool: godot --script tools/shot.gd -- <scene> <frames> <out.png>
## Runs with the real renderer (window flashes briefly).

var frames := 0
var target_frames := 90
var out_path := "/tmp/shot.png"
var scene_path := "res://scenes/dev/DevScene.tscn"

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0: scene_path = args[0]
	if args.size() > 1: target_frames = int(args[1])
	if args.size() > 2: out_path = args[2]
	root.size = Vector2i(1280, 720)
	change_scene_to_file(scene_path)
	await process_frame
	var gs := root.get_node_or_null("GameState")
	if gs:
		gs.mode = 3

func _process(_delta: float) -> bool:
	frames += 1
	var dr := root.get_node_or_null("DialogueRunner")
	if frames == 30 and dr and dr.playing:
		dr.skip()
	var gs := root.get_node_or_null("GameState")
	if gs and dr and not dr.playing:
		gs.mode = 3
	if frames == target_frames:
		await process_frame
		var gs2 := root.get_node_or_null("GameState")
		var dr2 := root.get_node_or_null("DialogueRunner")
		var cam2 := root.get_viewport().get_camera_3d()
		print("DBG mode=", gs2.mode if gs2 else "no-gs", " playing=", dr2.playing if dr2 else "no-dr", " cam=", cam2.global_position if cam2 else "no-cam")
		var img := root.get_texture().get_image()
		img.save_png(out_path)
		print("saved ", out_path)
		return true
	return false
