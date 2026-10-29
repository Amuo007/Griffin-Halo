extends Node
## Global game state: mode, player stats, flags, objectives, infection.

enum Mode { BOOT, MENU, CUTSCENE, PLAY, PAUSED, DEAD, VICTORY }

var mode: int = Mode.BOOT
var previous_mode: int = Mode.MENU

# Player runtime
var hp: float = Balance.PLAYER_MAX_HP
var stamina: float = Balance.STAMINA_MAX
var torch_on: bool = true
var torch_battery: float = Balance.TORCH_MAX
var weapons: Array = []          # gun ids owned, e.g. ["pistol"]
var ammo: Dictionary = {}        # gun id -> reserve rounds carried
var current_weapon: int = -1     # index into weapons
var food_inventory: int = 0
var infection_stage: int = 0     # 0..3, spreads across story

# Progress
var zone: int = 1
var checkpoint: Dictionary = {}  # {"zone":1, "pos":Vector3, "rot":0.0}
var flags: Dictionary = {}       # story/scripted flags
var lore_found: Array = []
var kills: int = 0

# Objective shown on HUD
var objective: String = ""
signal objective_changed(text)

# Detection HUD state
var threat_level: int = 0        # 0 none, 1 heard, 2 spotted, 3 hunting
var threat_direction: Vector3 = Vector3.ZERO
signal threat_changed(level, direction)

func set_objective(text: String) -> void:
	objective = text
	objective_changed.emit(text)

func set_flag(key: String, value: bool = true) -> void:
	flags[key] = value

func has_flag(key: String) -> bool:
	return flags.get(key, false)

func add_weapon(gun_id: String) -> void:
	if gun_id not in weapons:
		weapons.append(gun_id)
		if not ammo.has(gun_id):
			ammo[gun_id] = Balance.ROUNDS_PER_GUN
		if current_weapon < 0:
			current_weapon = 0

func current_gun_id() -> String:
	if current_weapon < 0 or current_weapon >= weapons.size():
		return ""
	return weapons[current_weapon]

func damage_player(amount: float) -> void:
	if mode != Mode.PLAY:
		return
	hp = maxf(0.0, hp - amount)
	if hp <= 0.0:
		mode = Mode.DEAD

func heal_player(amount: float) -> void:
	hp = minf(Balance.PLAYER_MAX_HP, hp + amount)

func reset_run() -> void:
	hp = Balance.PLAYER_MAX_HP
	stamina = Balance.STAMINA_MAX
	torch_on = true
	torch_battery = Balance.TORCH_MAX
	weapons.clear()
	ammo.clear()
	current_weapon = -1
	food_inventory = 0
	infection_stage = 0
	zone = 1
	checkpoint = {}
	flags.clear()
	lore_found.clear()
	kills = 0
	threat_level = 0
	objective = ""
