extends CanvasLayer
## In-game HUD: health, stamina, torch, ammo, objective, crosshair, vignette.

var health_bar: ColorRect
var health_bg: ColorRect
var stamina_bar: ColorRect
var torch_bar: ColorRect
var ammo_label: Label
var weapon_label: Label
var objective_label: Label
var crosshair: TextureRect
var vignette: Control
var subtitle_label: Label
var interact_hint: Label
var player: Node = null

const UI_DIR := "res://assets/game/ui/"
const CH_DIR := "res://assets/game/crosshair/"

func _ready() -> void:
	layer = 10
	_build()
	player = get_tree().get_first_node_in_group("player")
	if player:
		if player.has_signal("hp_changed"):
			player.hp_changed.connect(_on_hp)
			player.stamina_changed.connect(_on_stamina)
			player.torch_changed.connect(_on_torch)
			player.ammo_changed.connect(_on_ammo)
			player.aim_changed.connect(_on_aim)
			player.weapon_changed.connect(_on_weapon)
	GameState.objective_changed.connect(_on_objective)
	DialogueRunner.line_started.connect(_on_line)
	_on_hp(GameState.hp)
	_on_stamina(1.0)
	_on_torch(GameState.torch_on, GameState.torch_battery / Balance.TORCH_MAX)
	_refresh_ammo()

func _build() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	# --- bottom-left: health / stamina / torch ---
	var stack := VBoxContainer.new()
	stack.position = Vector2(24, -110)
	stack.anchor_top = 1.0
	stack.anchor_bottom = 1.0
	stack.offset_top = -110
	stack.offset_left = 24
	stack.offset_right = 284
	stack.offset_bottom = -24
	stack.add_theme_constant_override("separation", 8)
	root.add_child(stack)

	health_bg = _panel_bar(stack, 260, 22)
	health_bar = ColorRect.new()
	health_bar.color = Color(0.75, 0.1, 0.1)
	health_bar.position = Vector2(3, 3)
	health_bar.size = Vector2(254, 16)
	health_bg.add_child(health_bar)

	var stam_bg := _panel_bar(stack, 200, 12)
	stamina_bar = ColorRect.new()
	stamina_bar.color = Color(0.2, 0.5, 0.8)
	stamina_bar.position = Vector2(2, 2)
	stamina_bar.size = Vector2(196, 8)
	stam_bg.add_child(stamina_bar)

	var torch_bg := _panel_bar(stack, 160, 12)
	torch_bar = ColorRect.new()
	torch_bar.color = Color(0.9, 0.75, 0.2)
	torch_bar.position = Vector2(2, 2)
	torch_bar.size = Vector2(156, 8)
	torch_bg.add_child(torch_bar)

	# --- bottom-right: weapon + ammo ---
	var ammo_box := VBoxContainer.new()
	ammo_box.anchor_left = 1.0
	ammo_box.anchor_top = 1.0
	ammo_box.anchor_right = 1.0
	ammo_box.anchor_bottom = 1.0
	ammo_box.offset_left = -260
	ammo_box.offset_top = -90
	ammo_box.offset_right = -24
	ammo_box.offset_bottom = -24
	ammo_box.alignment = BoxContainer.ALIGNMENT_END
	root.add_child(ammo_box)
	weapon_label = Label.new()
	weapon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	weapon_label.add_theme_font_size_override("font_size", 16)
	weapon_label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.9))
	ammo_box.add_child(weapon_label)
	ammo_label = Label.new()
	ammo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	ammo_label.add_theme_font_size_override("font_size", 40)
	ammo_label.add_theme_color_override("font_color", Color(1, 1, 1))
	ammo_box.add_child(ammo_label)

	# --- top-center: objective ---
	objective_label = Label.new()
	objective_label.anchor_left = 0.5
	objective_label.anchor_right = 0.5
	objective_label.offset_left = -300
	objective_label.offset_right = 300
	objective_label.offset_top = 18
	objective_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	objective_label.add_theme_font_size_override("font_size", 18)
	objective_label.add_theme_color_override("font_color", Color(0.8, 0.82, 0.9, 0.9))
	root.add_child(objective_label)

	# --- crosshair ---
	crosshair = TextureRect.new()
	crosshair.texture = load(CH_DIR + "glow/crosshair-004.png")
	crosshair.custom_minimum_size = Vector2(32, 32)
	crosshair.size = Vector2(32, 32)
	crosshair.anchor_left = 0.5
	crosshair.anchor_top = 0.5
	crosshair.anchor_right = 0.5
	crosshair.anchor_bottom = 0.5
	crosshair.offset_left = -16
	crosshair.offset_top = -16
	crosshair.offset_right = 16
	crosshair.offset_bottom = 16
	crosshair.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	crosshair.modulate.a = 0.0
	root.add_child(crosshair)

	# --- damage vignette ---
	var grad := GradientTexture2D.new()
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
	g.colors = PackedColorArray([Color(0, 0, 0, 0), Color(0.3, 0, 0, 0.15), Color(0.6, 0, 0, 0.55)])
	grad.gradient = g
	grad.fill = GradientTexture2D.FILL_RADIAL
	grad.fill_from = Vector2(0.5, 0.5)
	grad.fill_to = Vector2(0.5, 0.92)
	grad.width = 256
	grad.height = 256
	var vi := TextureRect.new()
	vi.texture = grad
	vi.set_anchors_preset(Control.PRESET_FULL_RECT)
	vi.stretch_mode = TextureRect.STRETCH_SCALE
	vi.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vi.modulate.a = 0.0
	root.add_child(vi)
	vignette = vi

	# --- subtitle ---
	subtitle_label = Label.new()
	subtitle_label.anchor_left = 0.5
	subtitle_label.anchor_top = 1.0
	subtitle_label.anchor_right = 0.5
	subtitle_label.anchor_bottom = 1.0
	subtitle_label.offset_left = -400
	subtitle_label.offset_right = 400
	subtitle_label.offset_top = -160
	subtitle_label.offset_bottom = -100
	subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle_label.add_theme_font_size_override("font_size", 24)
	subtitle_label.add_theme_color_override("font_color", Color(1, 1, 1))
	subtitle_label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	subtitle_label.add_theme_constant_override("outline_size", 6)
	subtitle_label.text = ""
	root.add_child(subtitle_label)

func _panel_bar(parent: Node, w: int, h: int) -> ColorRect:
	var bg := ColorRect.new()
	bg.color = Color(0.08, 0.08, 0.1, 0.8)
	bg.custom_minimum_size = Vector2(w, h)
	bg.size = Vector2(w, h)
	parent.add_child(bg)
	return bg

func _on_hp(hp: float) -> void:
	var pct := clampf(hp / Balance.PLAYER_MAX_HP, 0.0, 1.0)
	health_bar.size.x = 254.0 * pct
	vignette.modulate.a = clampf((1.0 - pct) * 1.4, 0.0, 0.9)

func _on_stamina(pct: float) -> void:
	stamina_bar.size.x = 196.0 * clampf(pct, 0.0, 1.0)

func _on_torch(on: bool, pct: float) -> void:
	torch_bar.size.x = 156.0 * clampf(pct, 0.0, 1.0)
	torch_bar.color = Color(0.9, 0.75, 0.2) if on else Color(0.3, 0.25, 0.1)

func _on_ammo(_gun_id: String, _rounds: int) -> void:
	_refresh_ammo()

func _refresh_ammo() -> void:
	var gid: String = GameState.current_gun_id()
	if gid == "":
		ammo_label.text = ""
		weapon_label.text = ""
		return
	ammo_label.text = str(GameState.ammo.get(gid, 0))
	weapon_label.text = Balance.GUNS[gid].name

func _on_weapon(_gid: String) -> void:
	_refresh_ammo()

func _on_aim(aiming: bool) -> void:
	var t := create_tween()
	t.tween_property(crosshair, "modulate:a", 1.0 if aiming else 0.25, 0.15)

func _on_objective(text: String) -> void:
	objective_label.text = "— " + text + " —" if text != "" else ""

func _on_line(speaker: String, text: String) -> void:
	subtitle_label.text = ("%s: %s" % [speaker.to_upper(), text]) if speaker != "" else text
	var t := create_tween()
	t.tween_interval(3.0)
	t.tween_property(subtitle_label, "modulate:a", 0.0, 0.6)
	t.tween_callback(func(): subtitle_label.text = ""; subtitle_label.modulate.a = 1.0)
