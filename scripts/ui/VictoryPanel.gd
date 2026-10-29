extends Control
## Post-credits results screen.

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var box := VBoxContainer.new()
	box.anchor_left = 0.5
	box.anchor_top = 0.5
	box.anchor_right = 0.5
	box.anchor_bottom = 0.5
	box.offset_left = -220
	box.offset_right = 220
	box.offset_top = -160
	box.offset_bottom = 160
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 12)
	add_child(box)
	var title := Label.new()
	title.text = "YOU ESCAPED"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 52)
	title.add_theme_color_override("font_color", Color(0.95, 0.9, 0.75))
	box.add_child(title)
	var stats := Label.new()
	stats.text = "Beasts slain: %d\nRelics recovered: %d\nInfection stage: %d" % [GameState.kills, GameState.lore_found.size(), GameState.infection_stage]
	stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats.add_theme_font_size_override("font_size", 20)
	box.add_child(stats)
	var b := Button.new()
	b.text = "RETURN TO MENU"
	b.custom_minimum_size = Vector2(320, 48)
	var sb := StyleBoxTexture.new()
	sb.texture = load("res://assets/game/ui/buttonLong_brown.png")
	b.add_theme_stylebox_override("normal", sb)
	b.add_theme_stylebox_override("hover", sb)
	b.pressed.connect(func(): GameFlow.go_menu())
	box.add_child(b)
