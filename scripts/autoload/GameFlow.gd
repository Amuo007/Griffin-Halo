extends Node
## Game flow orchestration (survives scene changes).

func _ready() -> void:
	SettingsPanel.apply_saved()

func start_game() -> void:
	GameState.reset_run()
	GameState.mode = GameState.Mode.PLAY
	DialogueRunner.play_cutscene("intro")
	await DialogueRunner.cutscene_finished
	get_tree().change_scene_to_file("res://scenes/zones/Zone1.tscn")
	await get_tree().process_frame
	await get_tree().create_timer(0.3).timeout
	DialogueRunner.play_cutscene("wake")

func go_menu() -> void:
	GameState.mode = GameState.Mode.MENU
	get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn")

func continue_game() -> void:
	if SaveManager.load_game():
		GameState.mode = GameState.Mode.PLAY
		match GameState.zone:
			2: get_tree().change_scene_to_file("res://scenes/zones/Zone2.tscn")
			3: get_tree().change_scene_to_file("res://scenes/zones/Zone3.tscn")
			_: get_tree().change_scene_to_file("res://scenes/zones/Zone1.tscn")

func run_victory() -> void:
	GameState.mode = GameState.Mode.VICTORY
	DialogueRunner.play_cutscene("dawn")
	await DialogueRunner.cutscene_finished
	var panel = preload("res://scenes/ui/VictoryPanel.tscn").instantiate()
	get_tree().current_scene.add_child(panel)

func respawn() -> void:
	if GameState.checkpoint.get("zone", 0) != 0:
		SaveManager.load_game()
	else:
		GameState.hp = Balance.PLAYER_MAX_HP
	GameState.mode = GameState.Mode.PLAY
	var zone := int(GameState.checkpoint.get("zone", GameState.zone))
	match zone:
		2: get_tree().change_scene_to_file("res://scenes/zones/Zone2.tscn")
		3: get_tree().change_scene_to_file("res://scenes/zones/Zone3.tscn")
		_: get_tree().change_scene_to_file("res://scenes/zones/Zone1.tscn")
