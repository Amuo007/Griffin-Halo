extends Node
## All tunable game constants in one place.

# --- Player movement ---
const WALK_SPEED := 3.4
const RUN_SPEED := 5.6
const SPRINT_SPEED := 7.6
const CROUCH_SPEED := 1.7
const JUMP_VELOCITY := 5.2
const GRAVITY_MULT := 1.6
const ACCEL := 14.0
const DECEL := 16.0
const CROUCH_HEIGHT := 0.9
const STAND_HEIGHT := 1.7
const DODGE_IMPULSE := 8.0
const DODGE_COOLDOWN := 1.1
const DODGE_IFRAMES := 0.45
const STAMINA_MAX := 100.0
const SPRINT_DRAIN := 22.0
const STAMINA_REGEN := 16.0
const DODGE_STAMINA_COST := 25.0

# --- Noise model (metres of hearing radius) ---
const NOISE_CROUCH := 2.0
const NOISE_WALK := 6.0
const NOISE_RUN := 11.0
const NOISE_SPRINT := 16.0
const NOISE_DODGE := 13.0
const NOISE_GUNSHOT := 34.0
const NOISE_SPLASH := 14.0

# --- Camera ---
const CAM_FOV := 70.0
const CAM_FOV_AIM := 45.0
const CAM_SHOULDER := Vector3(0.55, 1.55, 0)
const CAM_SHOULDER_AIM := Vector3(0.38, 1.5, 0)
const CAM_SHOULDER_AIM_L := Vector3(-0.38, 1.5, 0)
const CAM_DISTANCE := 4.2
const CAM_DISTANCE_AIM := 2.6
const CAM_SPRING_STIFFNESS := 90.0
const MOUSE_SENS_BASE := 0.0026

# --- Combat ---
const GUNS := {
	"pistol": {"name": "Scrap Pistol", "model": "blaster-a", "damage": 34.0, "fire_rate": 0.32, "spread": 0.02, "aim_spread": 0.004, "recoil": 1.6, "shake": 0.25, "auto": false},
	"smg": {"name": "Rattler SMG", "model": "blaster-e", "damage": 16.0, "fire_rate": 0.09, "spread": 0.05, "aim_spread": 0.015, "recoil": 0.7, "shake": 0.12, "auto": true},
	"shotgun": {"name": "Boomstick", "model": "blaster-d", "damage": 13.0, "pellets": 7, "fire_rate": 0.85, "spread": 0.09, "aim_spread": 0.06, "recoil": 4.5, "shake": 0.6, "auto": false},
	"rifle": {"name": "Longshot", "model": "blaster-j", "damage": 95.0, "fire_rate": 1.15, "spread": 0.03, "aim_spread": 0.0005, "recoil": 5.5, "shake": 0.7, "auto": false},
}
const ROUNDS_PER_GUN := 5
const AMMO_PER_PICKUP := 3

# --- Torch ---
const TORCH_DRAIN := 1.15
const TORCH_MAX := 100.0
const TORCH_BATTERY_PICKUP := 40.0
const TORCH_RANGE := 16.0
const TORCH_ANGLE := 42.0

# --- Health ---
const PLAYER_MAX_HP := 100.0
const FOOD_SMALL := 20.0
const FOOD_LARGE := 45.0

# --- Enemy AI ---
const AI_SIGHT_RANGE := 18.0
const AI_SIGHT_FOV := 100.0
const AI_LOST_SEARCH_TIME := 4.0
const AI_HEARING_MULT := 1.0
const ALPHA_SIGHT_RANGE := 30.0
const ALPHA_HP := 600.0

# --- Detection HUD ---
const ALERT_FALLOFF := 6.0
