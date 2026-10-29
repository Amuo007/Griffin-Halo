extends Node
## Cutscene/subtitle runner: voice + typewriter subtitles + fades.

signal cutscene_started(id)
signal cutscene_finished(id)
signal line_started(speaker, text)
signal lore_opened(lore_id)

var playing: bool = false
var _queue: Array = []
var _current: String = ""
var _skip_requested: bool = false
var _fade: CanvasLayer = null
var _fade_rect: ColorRect = null
var _voice_player: AudioStreamPlayer = null

func _ready() -> void:
	_fade = CanvasLayer.new()
	_fade.layer = 20
	_fade_rect = ColorRect.new()
	_fade_rect.color = Color(0, 0, 0, 0)
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.add_child(_fade_rect)
	add_child(_fade)
	_voice_player = AudioStreamPlayer.new()
	_voice_player.bus = "Voice"
	add_child(_voice_player)

func _unhandled_input(event: InputEvent) -> void:
	if playing and (event.is_action_pressed("interact") or event.is_action_pressed("pause")):
		_skip_requested = true

func play_cutscene(id: String) -> void:
	if playing:
		if not _queue.has(id):
			_queue.append(id)
		return
	playing = true
	_skip_requested = false
	_current = id
	GameState.previous_mode = GameState.mode
	GameState.mode = GameState.Mode.CUTSCENE
	cutscene_started.emit(id)
	var cs := StoryData.get_cutscene(id)
	await _fade_to(1.0, 0.8)
	if cs.get("scene", "") != "":
		get_tree().change_scene_to_file(cs["scene"])
		await get_tree().process_frame
		await get_tree().create_timer(0.5).timeout
	for i in cs.get("lines", []).size():
		if _skip_requested:
			break
		var line: Dictionary = cs["lines"][i]
		line_started.emit(line.get("speaker", ""), line.get("text", ""))
		var dur := float(line.get("seconds", 3.0))
		var path := "res://audio/voices/%s_%02d.mp3" % [id, i]
		if FileAccess.file_exists(path):
			_voice_player.stream = load(path)
			_voice_player.play()
			dur = maxf(dur, _voice_player.stream.get_length() + 0.4)
		var waited := 0.0
		while waited < dur and not _skip_requested:
			await get_tree().create_timer(0.1).timeout
			waited += 0.1
	_voice_player.stop()
	await _fade_to(0.0, 0.8)
	_finish()

func skip() -> void:
	if playing:
		_skip_requested = true

func _finish() -> void:
	playing = false
	GameState.mode = GameState.previous_mode
	cutscene_finished.emit(_current)
	if not _queue.is_empty():
		var nxt: String = _queue.pop_front()
		play_cutscene.call_deferred(nxt)

func show_lore(lore_id: String) -> void:
	lore_opened.emit(lore_id)

func _fade_to(alpha: float, time: float) -> void:
	var start_a := _fade_rect.color.a
	var steps := int(time / 0.05) + 1
	for i in steps:
		await get_tree().create_timer(0.05).timeout
		var f := float(i + 1) / float(steps)
		_fade_rect.color.a = lerpf(start_a, alpha, f)
	_fade_rect.color.a = alpha
