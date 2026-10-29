extends Node3D
## Automated QA: runs scripted scenarios headless, prints PASS/FAIL.

var _tree: SceneTree
var _fails := 0

func _ready() -> void:
	_tree = get_tree()
	_tree.root.remove_child.call_deferred(self)
	await _tree.process_frame
	await _t(0.5)
	_t_new_game()

func _t(sec: float) -> void:
	await _tree.create_timer(sec).timeout

func check(name: String, cond: bool) -> void:
	print(("PASS " if cond else "FAIL ") + name)
	if not cond:
		_fails += 1

func _scene_name() -> String:
	return _tree.current_scene.name if _tree.current_scene else "<none>"

func _player() -> Node:
	return _tree.current_scene.get_node_or_null("Player") if _tree.current_scene else null

func _t_new_game() -> void:
	GameFlow.start_game()
	await _t(1.0)
	DialogueRunner.skip()
	await _t(1.5)
	DialogueRunner.skip()
	await _t(2.0)
	check("new-game reaches Zone1", _scene_name() == "Zone1")
	check("mode is PLAY", GameState.mode == GameState.Mode.PLAY)
	check("player exists", _player() != null)
	_t_zone_flow()

func _t_zone_flow() -> void:
	# Zone1 -> Zone2 via exit trigger
	var p := _player()
	p.global_position = Vector3(2 * 4.0, 1.0, 16 * 4.0)
	await _t(1.5)
	check("Zone1 exit -> Zone2", _scene_name() == "Zone2")
	DialogueRunner.skip()  # journal
	await _t(1.0)
	var p2 := _player()
	p2.global_position = Vector3(12 * 4.0, 1.0, 14 * 4.0)
	await _t(1.5)
	check("Zone2 exit -> Zone3", _scene_name() == "Zone3")
	DialogueRunner.skip()  # alpha
	await _t(1.0)
	var p3 := _player()
	p3.global_position = Vector3(0 * 4.0, 1.0, 12 * 4.0)
	await _t(1.5)
	check("Zone3 exit -> Victory", _scene_name() == "Victory")
	DialogueRunner.skip()  # dawn
	await _t(2.0)
	check("victory panel added", _tree.current_scene.get_children().any(func(c): return c.name == "VictoryPanel"))
	GameFlow.go_menu()
	await _t(1.0)
	check("return to menu", _scene_name() == "MainMenu")
	_t_death_respawn()

func _t_death_respawn() -> void:
	GameFlow.start_game()
	await _t(1.0)
	DialogueRunner.skip()
	await _t(1.5)
	DialogueRunner.skip()
	await _t(1.5)
	# checkpoint: walk onto campfire
	var p := _player()
	p.global_position = Vector3(0, 1.0, 4)
	await _t(0.8)
	check("checkpoint saved", SaveManager.has_save() and int(GameState.checkpoint.get("zone", 0)) == 1)
	# take damage -> dead
	GameState.damage_player(999.0)
	await _t(0.5)
	check("death sets DEAD", GameState.mode == GameState.Mode.DEAD)
	var hud := _tree.current_scene.get_node_or_null("HUD")
	check("death overlay shown", hud and hud.get("_death_panel") != null)
	# respawn
	hud._resume() if hud.get("_pause_panel") else null
	GameFlow.respawn()
	await _t(1.5)
	check("respawn restores PLAY", GameState.mode == GameState.Mode.PLAY)
	check("respawn in Zone1", _scene_name() == "Zone1")
	check("respawn restored hp", GameState.hp > 0)
	_t_combat()

func _t_combat() -> void:
	var p := _player()
	if not p:
		check("combat: player present", false)
		_t_pickups()
		return
	# give pistol
	GameState.add_weapon("pistol")
	await _t(0.2)
	check("weapon granted", GameState.ammo.get("pistol", 0) > 0)
	# spawn enemy in front of player
	var e = load("res://scenes/enemies/Enemy.tscn").instantiate()
	e.species_id = "fox"
	e.position = p.global_position + Vector3(0, 0, 3)
	_tree.current_scene.add_child(e)
	await _t(0.3)
	var hp0: float = e.hp
	e.take_damage(999.0, Vector3.FORWARD)
	await _t(0.5)
	check("enemy dies from damage", e.hp <= 0.0)
	check("kill counted", GameState.kills >= 1)
	_t_pickups()

func _t_pickups() -> void:
	var p := _player()
	var before: int = GameState.food_inventory
	var f = load("res://scenes/pickups/Pickup.tscn").instantiate()
	f.pickup_type = "food"
	f.model_path = "res://assets/game/food/apple.glb"
	f.position = p.global_position
	_tree.current_scene.add_child(f)
	await _t(0.8)
	check("food pickup collected", GameState.food_inventory > before)
	var l = load("res://scenes/pickups/Pickup.tscn").instantiate()
	l.pickup_type = "lore"
	l.lore_id = "miner1"
	l.position = p.global_position + Vector3(0, 0.5, 0)
	_tree.current_scene.add_child(l)
	await _t(0.8)
	check("lore registered", GameState.lore_found.has("miner1"))
	_t_audio()

func _t_audio() -> void:
	var ok := true
	var missing := ""
	for cs in StoryData.CUTSCENES.keys():
		var lines: Array = StoryData.CUTSCENES[cs].get("lines", [])
		for i in lines.size():
			var path := "res://audio/voices/%s_%02d.mp3" % [cs, i]
			if not FileAccess.file_exists(path):
				ok = false
				missing += path + " "
			else:
				var s = load(path)
				if s == null or s.get_length() <= 0:
					ok = false
					missing += path + "(len) "
	check("all voice files load", ok)
	if missing:
		print("  missing: ", missing)
	print("QA RESULT: %d failures" % _fails)
	_tree.quit()
