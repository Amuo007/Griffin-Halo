extends SceneTree
## Build tool: assembles scenes/player/Character.tscn from FBX + merged anims.
## Run: godot --headless --script tools/build_character.gd

const SKINS := {
	"griffin": "res://assets/game/characters/skins/skaterMaleA.png",
	"marcus": "res://assets/game/characters/skins/criminalMaleA.png",
	"elena": "res://assets/game/characters/skins/skaterFemaleA.png",
	"vera": "res://assets/game/characters/skins/cyborgFemaleA.png",
}

func _initialize() -> void:
	for skin in SKINS:
		_build(skin, SKINS[skin])
	print("character scenes built")
	quit()

func _build(skin_name: String, skin_path: String) -> void:
	var base: PackedScene = ResourceLoader.load("res://assets/game/characters/characterMedium.fbx")
	var root := base.instantiate()
	root.name = "Character"

	var mesh := _find_mesh(root)
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = load(skin_path)
	mat.roughness = 0.8
	mesh.material_override = mat

	var skel := _find_skel(root)

	# AnimationPlayer with merged clips
	var ap := AnimationPlayer.new()
	ap.name = "AnimationPlayer"
	root.add_child(ap)
	ap.owner = root
	var lib := AnimationLibrary.new()
	for clip in ["idle", "run", "jump"]:
		var anim_scene: PackedScene = ResourceLoader.load("res://assets/game/characters/anims/%s.fbx" % clip)
		var ar := anim_scene.instantiate()
		var src_ap := _find_anim(ar)
		var src_anim: Animation = src_ap.get_animation("Root|%s" % clip.capitalize())
		var anim := src_anim.duplicate()
		lib.add_animation(clip, anim)
		ar.free()
	ap.add_animation_library("", lib)

	# Gun mount on right hand
	var gun_point := BoneAttachment3D.new()
	gun_point.name = "GunPoint"
	gun_point.bone_name = "RightHand"
	skel.add_child(gun_point)
	gun_point.owner = root

	# AnimationTree: Locomotion(idle<->run 1D) <-> Jump
	var tree := AnimationTree.new()
	tree.name = "AnimationTree"
	root.add_child(tree)
	tree.owner = root
	tree.anim_player = NodePath("../AnimationPlayer")

	var sm := AnimationNodeStateMachine.new()

	var loco := AnimationNodeBlendSpace1D.new()
	loco.set_name("speed")
	var idle_n := AnimationNodeAnimation.new(); idle_n.animation = "idle"
	var run_n := AnimationNodeAnimation.new(); run_n.animation = "run"
	loco.add_blend_point(idle_n, -1.0)
	loco.add_blend_point(run_n, 1.0)

	var jump_n := AnimationNodeAnimation.new(); jump_n.animation = "jump"

	sm.add_node("Locomotion", loco)
	sm.add_node("Jump", jump_n)
	var t_to_jump := AnimationNodeStateMachineTransition.new()
	t_to_jump.advance_mode = AnimationNodeStateMachineTransition.ADVANCE_MODE_ENABLED
	t_to_jump.advance_condition = "is_airborne"
	sm.add_transition("Locomotion", "Jump", t_to_jump)
	var t_to_loco := AnimationNodeStateMachineTransition.new()
	t_to_loco.advance_mode = AnimationNodeStateMachineTransition.ADVANCE_MODE_ENABLED
	t_to_loco.advance_condition = "!is_airborne"
	sm.add_transition("Jump", "Locomotion", t_to_loco)

	tree.tree_root = sm
	tree.active = true

	var ps := PackedScene.new()
	var err := ps.pack(root)
	if err != OK:
		print("PACK FAILED")
		quit(1)
		return
	var target := "res://scenes/player/Character_%s.tscn" % skin_name
	var save_err := ResourceSaver.save(ps, target)
	print("saved ", target, " err=", save_err)
	root.free()

func _find_mesh(n: Node) -> MeshInstance3D:
	if n is MeshInstance3D: return n
	for c in n.get_children():
		var r := _find_mesh(c)
		if r: return r
	return null

func _find_skel(n: Node) -> Skeleton3D:
	if n is Skeleton3D: return n
	for c in n.get_children():
		var r := _find_skel(c)
		if r: return r
	return null

func _find_anim(n: Node) -> AnimationPlayer:
	if n is AnimationPlayer: return n
	for c in n.get_children():
		var r := _find_anim(c)
		if r: return r
	return null
