extends Control
## Main menu: title, new game, continue, settings, quit.

const UI := "res://assets/game/ui/"
var _settings_panel: Control = null

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	# backdrop
	var bg := TextureRect.new()
	bg.texture = load("res://assets/game/skyboxes/skybox-night.png")
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var box := VBoxContainer.new()
	box.anchor_left = 0.5
	box.anchor_right = 0.5
	box.offset_left = -180
	box.offset_right = 180
	box.offset_top = 120
	box.offset_bottom = 620
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 14)
	add_child(box)

	var title := Label.new()
	title.text = "GRIFIN"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 72)
	title.add_theme_color_override("font_color", Color(0.85, 0.87, 0.95))
	title.add_theme_color_override("font_outline_color", Color(0.6, 0.05, 0.05))
	title.add_theme_constant_override("outline_size", 10)
	box.add_child(title)
	var sub := Label.new()
	sub.text = "Escape from Hollow Cave"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 22)
	sub.add_theme_color_override("font_color", Color(0.6, 0.62, 0.7))
	box.add_child(sub)
	box.add_child(Control.new())

	box.add_child(_button("NEW GAME", func(): GameFlow.start_game()))
	var cont := _button("CONTINUE", func(): GameFlow.continue_game())
	cont.visible = SaveManager.has_save()
	box.add_child(cont)
	box.add_child(_button("SETTINGS", _toggle_settings))
	box.add_child(_button("QUIT", func(): get_tree().quit()))

	var hint := Label.new()
	hint.text = "WASD move · Shift sprint · Ctrl crouch · Space jump · Q dodge · F torch\nLMB fire · RMB aim · E interact · Esc pause"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 14)
	hint.add_theme_color_override("font_color", Color(0.5, 0.52, 0.6))
	box.add_child(hint)

func _button(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(360, 52)
	var normal := StyleBoxTexture.new()
	normal.texture = load(UI + "buttonLong_brown.png")
	var pressed := StyleBoxTexture.new()
	pressed.texture = load(UI + "buttonLong_brown_pressed.png")
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", normal)
	b.add_theme_stylebox_override("pressed", pressed)
	b.add_theme_font_size_override("font_size", 20)
	b.add_theme_color_override("font_color", Color(0.95, 0.92, 0.85))
	b.pressed.connect(cb)
	return b

func _toggle_settings() -> void:
	if _settings_panel:
		_settings_panel.queue_free()
		_settings_panel = null
		return
	_settings_panel = SettingsPanel.new()
	add_child(_settings_panel)
