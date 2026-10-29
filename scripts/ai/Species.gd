class_name Species
extends RefCounted
## Beast species definitions — pale, wrong, and hungry.

const DEFS := {
	"hog": {
		"model": "animal-hog", "scale": 2.0, "hp": 90.0, "speed": 4.6, "sprint": 6.8,
		"sight": 16.0, "fov": 100.0, "attack_range": 1.6, "damage": 22.0, "attack_cd": 1.3,
		"eye": Color(0.9, 0.15, 0.1), "growl": 0.7,
	},
	"fox": {
		"model": "animal-fox", "scale": 1.9, "hp": 55.0, "speed": 5.4, "sprint": 8.2,
		"sight": 20.0, "fov": 110.0, "attack_range": 1.4, "damage": 14.0, "attack_cd": 0.9,
		"eye": Color(1.0, 0.6, 0.1), "growl": 1.2,
	},
	"cat": {
		"model": "animal-cat", "scale": 1.8, "hp": 50.0, "speed": 5.0, "sprint": 8.6,
		"sight": 20.0, "fov": 110.0, "attack_range": 1.4, "damage": 16.0, "attack_cd": 1.0,
		"eye": Color(0.2, 1.0, 0.4), "growl": 1.4,
	},
	"bee": {
		"model": "animal-bee", "scale": 1.6, "hp": 20.0, "speed": 6.0, "sprint": 7.5,
		"sight": 14.0, "fov": 120.0, "attack_range": 1.0, "damage": 8.0, "attack_cd": 0.7,
		"eye": Color(1.0, 0.9, 0.2), "growl": 2.0, "hover": true,
	},
	"crab": {
		"model": "animal-crab", "scale": 2.2, "hp": 120.0, "speed": 1.2, "sprint": 6.5,
		"sight": 10.0, "fov": 90.0, "attack_range": 1.5, "damage": 30.0, "attack_cd": 1.6,
		"eye": Color(0.9, 0.2, 0.6), "growl": 0.5, "ambush": true,
	},
	"deer": {
		"model": "animal-deer", "scale": 3.5, "hp": 600.0, "speed": 3.8, "sprint": 6.0,
		"sight": 30.0, "fov": 120.0, "attack_range": 2.4, "damage": 45.0, "attack_cd": 1.8,
		"eye": Color(1.0, 0.1, 0.05), "growl": 0.35, "alpha": true,
	},
}
