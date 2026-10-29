extends Node
## Audio: buses, procedural SFX, ambience. Full mix in Phase 7.

var bus_master := 0
var bus_music := 0
var bus_sfx := 0
var bus_voice := 0
var bus_ambience := 0
var _sfx_pool: Array = []
var _ambience_player: AudioStreamPlayer = null

func _ready() -> void:
	bus_master = AudioServer.get_bus_index("Master")
	bus_music = AudioServer.get_bus_index("Music")
	bus_sfx = AudioServer.get_bus_index("SFX")
	bus_voice = AudioServer.get_bus_index("Voice")
	bus_ambience = AudioServer.get_bus_index("Ambience")
	for i in 24:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_sfx_pool.append(p)
	_ambience_player = AudioStreamPlayer.new()
	_ambience_player.bus = "Ambience"
	_ambience_player.volume_db = -8.0
	add_child(_ambience_player)

func play_sfx(stream: AudioStream, volume_db := 0.0, pitch := 1.0) -> void:
	if stream == null:
		return
	for p in _sfx_pool:
		if not p.playing:
			p.stream = stream
			p.volume_db = volume_db
			p.pitch_scale = pitch
			p.play()
			return

func play_ambience(stream: AudioStream) -> void:
	if stream == null:
		return
	_ambience_player.stream = stream
	_ambience_player.play()

func stop_ambience() -> void:
	_ambience_player.stop()

func set_bus_volume(bus_name: String, linear: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx < 0:
		return
	AudioServer.set_bus_volume_db(idx, linear_to_db(clampf(linear, 0.0001, 1.0)))
