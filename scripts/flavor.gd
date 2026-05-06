# flavor.gd — Flavor enum and helper data
class_name FlavorHelper
extends Node

enum Flavor {
	TEEKHA,
	MEETHA,
	HING,
	LEHSUN,
	JALJEERA,
}

const FLAVOR_DATA: Dictionary = {
	Flavor.TEEKHA: {
		"name": "TEEKHA",
		"display_name": "Teekha (Spicy Mint)",
		"color": Color("#2ecc71"),
		"jug_sprite": "res://assets/sprites/jug_teekha.svg",
	},
	Flavor.MEETHA: {
		"name": "MEETHA",
		"display_name": "Meetha (Sweet Tamarind)",
		"color": Color("#6e3b1f"),
		"jug_sprite": "res://assets/sprites/jug_meetha.svg",
	},
	Flavor.HING: {
		"name": "HING",
		"display_name": "Hing (Asafoetida)",
		"color": Color("#f4d35e"),
		"jug_sprite": "res://assets/sprites/jug_hing.svg",
	},
	Flavor.LEHSUN: {
		"name": "LEHSUN",
		"display_name": "Lehsun (Garlic)",
		"color": Color("#6b8e5a"),
		"jug_sprite": "res://assets/sprites/jug_lehsun.svg",
	},
	Flavor.JALJEERA: {
		"name": "JALJEERA",
		"display_name": "Jaljeera (Cumin Cooler)",
		"color": Color("#d4e157"),
		"jug_sprite": "res://assets/sprites/jug_jaljeera.svg",
	},
}

static func get_color(flavor: int) -> Color:
	if flavor not in FLAVOR_DATA:
		return Color.WHITE
	return FLAVOR_DATA[flavor]["color"]

static func get_display_name(flavor: int) -> String:
	if flavor not in FLAVOR_DATA:
		return "Unknown"
	return FLAVOR_DATA[flavor]["display_name"]

static func get_jug_sprite(flavor: int) -> String:
	if flavor not in FLAVOR_DATA:
		return ""
	return FLAVOR_DATA[flavor]["jug_sprite"]

static func from_string(s: String) -> int:
	for key in FLAVOR_DATA:
		if FLAVOR_DATA[key]["name"] == s:
			return key
	return -1
