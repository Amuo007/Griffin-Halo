extends Node
## Save/load to user://save.dat

const SAVE_PATH := "user://griffin_save.dat"

func save_game() -> void:
	var data := {
		"hp": GameState.hp,
		"stamina": GameState.stamina,
		"torch_on": GameState.torch_on,
		"torch_battery": GameState.torch_battery,
		"weapons": GameState.weapons.duplicate(),
		"ammo": GameState.ammo.duplicate(),
		"food_inventory": GameState.food_inventory,
		"infection_stage": GameState.infection_stage,
		"zone": GameState.zone,
		"checkpoint": GameState.checkpoint,
		"flags": GameState.flags,
		"lore_found": GameState.lore_found,
		"kills": GameState.kills,
		"objective": GameState.objective,
	}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		push_error("Save failed: %s" % FileAccess.get_open_error())
		return
	f.store_string(JSON.stringify(data))
	f.close()

func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return false
	var parsed = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return false
	GameState.hp = parsed.get("hp", GameState.hp)
	GameState.stamina = parsed.get("stamina", GameState.stamina)
	GameState.torch_on = parsed.get("torch_on", true)
	GameState.torch_battery = parsed.get("torch_battery", Balance.TORCH_MAX)
	GameState.weapons = parsed.get("weapons", [])
	GameState.ammo = parsed.get("ammo", {})
	GameState.food_inventory = parsed.get("food_inventory", 0)
	GameState.infection_stage = parsed.get("infection_stage", 0)
	GameState.zone = parsed.get("zone", 1)
	GameState.checkpoint = parsed.get("checkpoint", {})
	GameState.flags = parsed.get("flags", {})
	GameState.lore_found = parsed.get("lore_found", [])
	GameState.kills = parsed.get("kills", 0)
	GameState.objective = parsed.get("objective", "")
	return true

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func delete_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
