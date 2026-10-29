extends Node
## Cutscene/subtitle runner. Full timeline system in Phase 7.

signal cutscene_started(id)
signal cutscene_finished(id)
signal line_started(speaker, text)
signal lore_opened(lore_id)

var playing: bool = false
var _current: String = ""

func show_lore(lore_id: String) -> void:
	lore_opened.emit(lore_id)

func play_cutscene(id: String) -> void:
	if playing:
		return
	playing = true
	_current = id
	GameState.previous_mode = GameState.mode
	GameState.mode = GameState.Mode.CUTSCENE
	cutscene_started.emit(id)
	# Phase 7: camera timeline + voice + typewriter subtitles.
	# Stub: emit lines immediately and finish after a beat.
	var cs := StoryData.get_cutscene(id)
	for line in cs.get("lines", []):
		line_started.emit(line.get("speaker", ""), line.get("text", ""))
		await get_tree().create_timer(float(line.get("seconds", 1.0))).timeout
	_finish()

func skip() -> void:
	if playing:
		_finish()

func _finish() -> void:
	playing = false
	GameState.mode = GameState.previous_mode
	cutscene_finished.emit(_current)
