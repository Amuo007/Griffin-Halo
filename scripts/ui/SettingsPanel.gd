class_name SettingsPanel
extends Control
## Settings: bus volumes + mouse sensitivity. Persists to user://settings.cfg.

const CFG := "user://settings.cfg"
var _sens := 1.0

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.75)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var cfg := ConfigFile.new()
	cfg.load(CFG)
	_sens = cfg.get_value("input", "sensitivity", 1.0)

	var panel := PanelContainer.new()
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -220
	panel.offset_right = 220
	panel.offset_top = -200
	panel.offset_bottom = 200
	add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)
	var title := Label.new()
	title.text = "SETTINGS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	box.add_child(title)

	box.add_child(_slider("Master", "Master", cfg.get_value("audio", "master", 1.0)))
	box.add_child(_slider("Music", "Music", cfg.get_value("audio", "music", 0.8)))
	box.add_child(_slider("SFX", "SFX", cfg.get_value("audio", "sfx", 1.0)))
	box.add_child(_slider("Voice", "Voice", cfg.get_value("audio", "voice", 1.0)))

	var sens := HSlider.new()
	sens.min_value = 0.3
	sens.max_value = 2.5
	sens.value = _sens
	sens.custom_minimum_size = Vector2(0, 30)
	var sens_label := Label.new()
	sens_label.text = "Mouse Sensitivity"
	sens.value_changed.connect(func(v): _sens = v; sens_label.text = "Mouse Sensitivity: %.2f" % v)
	box.add_child(sens_label)
	box.add_child(sens)

	var close := Button.new()
	close.text = "CLOSE"
	close.custom_minimum_size = Vector2(0, 44)
	close.pressed.connect(func():
		var c := ConfigFile.new()
		c.set_value("audio", "master", _bus_lin("Master"))
		c.set_value("audio", "music", _bus_lin("Music"))
		c.set_value("audio", "sfx", _bus_lin("SFX"))
		c.set_value("audio", "voice", _bus_lin("Voice"))
		c.set_value("input", "sensitivity", _sens)
		c.save(CFG)
		queue_free())
	box.add_child(close)
	_apply()

func _slider(label: String, bus: String, value: float) -> Control:
	var l := Label.new()
	l.text = label
	var s := HSlider.new()
	s.min_value = 0.0
	s.max_value = 1.0
	s.value = value
	s.custom_minimum_size = Vector2(0, 30)
	s.value_changed.connect(func(v): AudioManager.set_bus_volume(bus, v); l.text = "%s: %d%%" % [label, int(v * 100)])
	l.text = "%s: %d%%" % [label, int(value * 100)]
	var box := VBoxContainer.new()
	box.add_child(l)
	box.add_child(s)
	return box

func _bus_lin(bus: String) -> float:
	var idx := AudioServer.get_bus_index(bus)
	return db_to_linear(AudioServer.get_bus_volume_db(idx))

func _apply() -> void:
	Balance.mouse_sens = 0.0026 * _sens

static func apply_saved() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(CFG) != OK:
		return
	AudioManager.set_bus_volume("Master", cfg.get_value("audio", "master", 1.0))
	AudioManager.set_bus_volume("Music", cfg.get_value("audio", "music", 0.8))
	AudioManager.set_bus_volume("SFX", cfg.get_value("audio", "sfx", 1.0))
	AudioManager.set_bus_volume("Voice", cfg.get_value("audio", "voice", 1.0))
	Balance.mouse_sens = 0.0026 * cfg.get_value("input", "sensitivity", 1.0)
