class_name Gore
extends RefCounted
## Blood/gore FX helpers: bursts, gibs, decals.

static var _blood_tex: ImageTexture = null

static func blood_texture() -> ImageTexture:
	if _blood_tex:
		return _blood_tex
	var img := Image.create(128, 128, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var rng := RandomNumberGenerator.new()
	rng.seed = 666
	for i in 26:
		var cx := rng.randf_range(20, 108)
		var cy := rng.randf_range(20, 108)
		var r := rng.randf_range(6, 26)
		var col := Color(0.35, 0.01, 0.02, rng.randf_range(0.5, 0.95))
		for x in range(int(cx - r), int(cx + r)):
			for y in range(int(cy - r), int(cy + r)):
				var d := Vector2(x - cx, y - cy).length()
				if d < r * rng.randf_range(0.7, 1.0):
					img.set_pixel(x, y, col)
	_blood_tex = ImageTexture.create_from_image(img)
	return _blood_tex

static func blood_burst(parent: Node, pos: Vector3, amount: float) -> void:
	var n := int(clampf(amount / 4.0, 3.0, 14.0))
	for i in n:
		var p := MeshInstance3D.new()
		var sm := SphereMesh.new()
		var s := randf_range(0.03, 0.09)
		sm.radius = s
		sm.height = s * 2
		p.mesh = sm
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.4, 0.01, 0.02)
		mat.roughness = 0.4
		p.material_override = mat
		p.global_position = pos
		parent.add_child(p)
		var vel := Vector3(randf_range(-2, 2), randf_range(1, 4), randf_range(-2, 2))
		var t := parent.get_tree().create_tween()
		t.set_parallel(true)
		t.tween_property(p, "global_position", pos + vel * 0.4 + Vector3(0, -0.8, 0), 0.4)
		t.tween_property(p, "scale", Vector3(0.1, 0.1, 0.1), 0.4)
		t.chain().tween_callback(p.queue_free)

static func blood_decal(parent: Node, pos: Vector3, size: float) -> void:
	var d := Decal.new()
	d.texture_albedo = blood_texture()
	d.size = Vector3(size, 0.6, size)
	d.upper_fade = 0.15
	d.global_position = pos + Vector3(0, 0.35, 0)
	parent.add_child(d)

static func screen_blood(_amount: float) -> void:
	pass  # HUD hook, wired in Phase 7
